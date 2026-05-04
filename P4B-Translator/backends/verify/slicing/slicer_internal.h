// Private helper implementation for slicer.cpp and slicer_apply.cpp.
#ifndef BACKENDS_VERIFY_SLICING_SLICER_INTERNAL_H_
#define BACKENDS_VERIFY_SLICING_SLICER_INTERNAL_H_

#include <algorithm>
#include <cctype>
#include <deque>
#include <fstream>
#include <iostream>
#include <limits>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <sys/stat.h>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

#include "backends/verify/slicing/collectors/register_decl.h"
#include "backends/verify/translate/bmv2.h"
#include "backends/verify/translate/utils.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "ir/ir.h"
#include "ir/visitor.h"
#include "lib/cstring.h"
#include "lib/log.h"
#include "lib/stringify.h"

namespace P4Verify {

namespace slicing_internal {

struct VarKey {
    std::string base;
    std::vector<std::string> segs;
    bool operator==(const VarKey& other) const {
        return base == other.base && segs == other.segs;
    }
    bool operator<(const VarKey& other) const {
        if (base != other.base) {
            return base < other.base;
        }
        return segs < other.segs;
    }
};

struct VarKeyLess {
    bool operator()(const VarKey& a, const VarKey& b) const {
        return a < b;
    }
};

static bool isIndexSegment(const std::string& s) {
    if (s == "last") {
        return true;
    }
    if (s.empty()) {
        return false;
    }
    for (char c : s) {
        if (c < '0' || c > '9') {
            return false;
        }
    }
    return true;
}

static std::string varKeyToString(const VarKey& key) {
    std::string out = key.base;
    for (const auto& seg : key.segs) {
        out.push_back('.');
        out += seg;
    }
    return out;
}

struct NodeInfo {
    const IR::Statement* stmt = nullptr;
    std::set<VarKey, VarKeyLess> uses;
    std::set<VarKey, VarKeyLess> defs;
    std::vector<int> succs;
    std::vector<int> preds;
    std::vector<int> ctrlSuccs;
    std::vector<int> ctrlPreds;
};

struct CFGFragment {
    int entry = -1;
    int exit = -1;
    std::vector<int> nodes;
};

struct UsesDefs {
    std::set<VarKey, VarKeyLess> uses;
    std::set<VarKey, VarKeyLess> defs;
};

static void insertVarKey(std::set<VarKey, VarKeyLess>& dst, const VarKey& key) {
    if (key.base.empty()) {
        return;
    }
    dst.insert(key);
}

static void addVarKey(std::set<VarKey, VarKeyLess>& dst, VarKey key) {
    if (key.base.empty()) {
        return;
    }
    dst.insert(key);
    // If validity is tracked as a separate field key, also keep the underlying
    // header Ref key. This is required because the Boogie encoding indexes
    // `isValid : [Ref]bool` by the Ref itself (e.g., `isValid[hdr.overlay.7]`),
    // so dropping `hdr.overlay.7` while keeping `hdr.overlay.7.valid` makes the
    // sliced program ill-typed.
    if (key.base == "hdr" && !key.segs.empty() && key.segs.back() == "valid") {
        VarKey refKey = key;
        refKey.segs.pop_back();
        if (!refKey.segs.empty()) {
            dst.insert(refKey);
        }
    }
    // Header stacks need a coarse-grained base key to preserve stack operations
    // (e.g., pop_front) during slicing. Otherwise, dependencies like
    //   hdr.overlay.pop_front(1)  ->  hdr.overlay[0].swip
    // are missed because the method call does not mention per-index fields.
    if (key.base == "hdr" && key.segs.size() >= 2 && isIndexSegment(key.segs[1])) {
        VarKey stackBase = key;
        stackBase.segs.resize(1);
        dst.insert(stackBase);
    }
    // Keep header fields field-sensitive: adding parent keys like `hdr.nc_hdr`
    // for every field access (e.g., `hdr.nc_hdr.seq`) creates spurious
    // dependencies across unrelated fields and prevents slicing from pruning
    // independent state (e.g., Netchain's `value_reg` when slicing for
    // `sequence_reg` only).
    //
    // For non-header bases, keeping the immediate parent is still useful to
    // conservatively approximate struct assignments.
    if (key.segs.size() > 1 && key.base != "hdr") {
        VarKey parent = key;
        parent.segs.pop_back();
        dst.insert(parent);
    }
    if (key.segs.size() == 1) {
        const auto& only = key.segs.back();
        auto isDigits = [](const std::string& s) {
            return !s.empty() &&
                   std::all_of(s.begin(), s.end(),
                               [](unsigned char c) { return std::isdigit(c); });
        };
        bool isIndex = isDigits(only);
        if (!isIndex) {
            auto bv = only.find("bv");
            if (bv != std::string::npos) {
                std::string num = only.substr(0, bv);
                std::string width = only.substr(bv + 2);
                if (isDigits(num) && isDigits(width)) {
                    isIndex = true;
                }
            }
        }
        if (isIndex) {
            VarKey base = key;
            base.segs.clear();
            dst.insert(base);
        }
    }
    if (!key.segs.empty()) {
        const auto& last = key.segs.back();
        if (last == "read" || last == "write") {
            VarKey base = key;
            base.segs.pop_back();
            dst.insert(base);
        }
    }
}

static bool buildVarKey(const IR::Expression* expr, VarKey& outKey);

static void addHeaderValidKey(std::set<VarKey, VarKeyLess>& dst, const IR::Expression* expr) {
    if (!expr) {
        return;
    }
    VarKey base;
    if (!buildVarKey(expr, base) || base.base.empty()) {
        return;
    }
    if (!base.segs.empty()) {
        // In the Boogie encoding, header validity is modeled via the global
        // map `isValid : [Ref]bool` indexed by the header Ref (e.g.,
        // `isValid[hdr.overlay.7]`). If we keep/seed `.valid` we must also
        // keep the corresponding Ref key itself; otherwise slicing may drop
        // the `var hdr.overlay.7 : Ref;` declaration while still emitting
        // `isValid[hdr.overlay.7]` uses, leading to ill-typed Boogie.
        insertVarKey(dst, base);
        VarKey valid = base;
        valid.segs.push_back("valid");
        insertVarKey(dst, valid);
    }
}

static void addSeedVarKey(std::set<VarKey, VarKeyLess>& dst, const VarKey& key) {
    if (key.base.empty()) {
        return;
    }
    if (key.base == "hdr" && key.segs.size() == 1 && !isIndexSegment(key.segs[0])) {
        // Seeding a header name (e.g., `hdr.ipv4`) should keep both the header
        // Ref and its validity bit.
        insertVarKey(dst, key);
        VarKey valid = key;
        valid.segs.push_back("valid");
        insertVarKey(dst, valid);
        return;
    }
    insertVarKey(dst, key);
    if (key.segs.size() == 1 && isIndexSegment(key.segs[0])) {
        VarKey base = key;
        base.segs.clear();
        insertVarKey(dst, base);
    }
    if (key.base == "hdr" && !key.segs.empty()) {
        VarKey header = key;
        bool isStack = header.segs.size() >= 2 && isIndexSegment(header.segs[1]);
        if (isStack) {
            VarKey stackBase = header;
            stackBase.segs.resize(1);
            insertVarKey(dst, stackBase);
            header.segs.resize(2);
        } else {
            header.segs.resize(1);
        }
        // Keep both the header Ref key and its validity bit.
        VarKey headerRef = header;
        insertVarKey(dst, headerRef);
        header.segs.push_back("valid");
        insertVarKey(dst, header);
    }
}

static const IR::Type* resolveType(const IR::Type* type, P4::ReferenceMap* refMap) {
    if (!type || !refMap) {
        return type;
    }
    if (auto name = type->to<IR::Type_Name>()) {
        if (auto decl = refMap->getDeclaration(name->path, true)) {
            if (auto declType = decl->to<IR::Type>()) {
                return resolveType(declType, refMap);
            }
        }
    }
    if (auto spec = type->to<IR::Type_Specialized>()) {
        return resolveType(spec->baseType, refMap);
    }
    return type;
}

static bool isPacketCarriedType(const IR::Type* type) {
    if (!type) {
        return false;
    }
    if (type->is<IR::Type_Header>() || P4VerifyCompat::isHeaderStackType(type)) {
        return true;
    }
    if (type->is<IR::Type_Struct>()) {
        return true;
    }
    if (type->is<IR::Type_StructLike>()) {
        return true;
    }
    return false;
}

static std::set<std::string> collectPacketCarriedBases(const IR::P4Program* program,
                                                       P4::ReferenceMap* refMap) {
    std::set<std::string> bases;
    for (auto obj : program->objects) {
        const IR::ParameterList* params = nullptr;
        if (auto control = obj->to<IR::P4Control>()) {
            if (control->type) {
                params = control->type->getApplyParameters();
            }
        } else if (auto parser = obj->to<IR::P4Parser>()) {
            if (parser->type) {
                params = parser->type->getApplyParameters();
            }
        }
        if (!params) {
            continue;
        }
        for (auto p : params->parameters) {
            if (!p || !p->type) {
                continue;
            }
            const IR::Type* t = resolveType(p->type, refMap);
            if (isPacketCarriedType(t)) {
                bases.insert(p->name.name.c_str());
            }
        }
    }
    return bases;
}

static bool buildVarKey(const IR::Expression* expr, VarKey& outKey) {
    if (!expr) {
        return false;
    }
    if (auto cast = expr->to<IR::Cast>()) {
        return buildVarKey(cast->expr, outKey);
    }
    if (auto path = expr->to<IR::PathExpression>()) {
        outKey.base = path->path->toString();
        return true;
    }
    if (auto mem = expr->to<IR::Member>()) {
        VarKey base;
        if (buildVarKey(mem->expr, base)) {
            base.segs.push_back(std::string(mem->member.toString().c_str()));
            outKey = std::move(base);
            return true;
        }
    }
    if (auto arr = expr->to<IR::ArrayIndex>()) {
        VarKey base;
        if (buildVarKey(arr->left, base)) {
            if (auto c = arr->right->to<IR::Constant>()) {
                base.segs.push_back(std::string(Util::toString(c->value, 0, false).c_str()));
                outKey = std::move(base);
                return true;
            }
        }
    }
    return false;
}

static cstring resolvePathName(const IR::PathExpression* pe, P4::ReferenceMap* refMap) {
    if (!pe || !pe->path) {
        return nullptr;
    }
    if (refMap) {
        if (auto decl = refMap->getDeclaration(pe->path, false)) {
            return decl->getName().name;
        }
    }
    return pe->path->name;
}

static bool regActionCallName(const IR::MethodCallExpression* mce,
                              cstring& outName,
                              P4::ReferenceMap* refMap) {
    if (!mce || !mce->method) {
        return false;
    }
    auto member = mce->method->to<IR::Member>();
    if (!member) {
        return false;
    }
    if (member->member != "apply" && member->member != "execute") {
        return false;
    }
    auto base = member->expr->to<IR::PathExpression>();
    if (!base) {
        return false;
    }
    outName = resolvePathName(base, refMap);
    return true;
}

static bool methodCallExprName(const IR::Expression* expr,
                               cstring& outName,
                               std::string& outMethod,
                               P4::ReferenceMap* refMap) {
    auto mce = expr ? expr->to<IR::MethodCallExpression>() : nullptr;
    if (!mce || !mce->method) {
        return false;
    }
    auto member = mce->method->to<IR::Member>();
    if (member) {
        outMethod = member->member.toString().c_str();
        if (auto base = member->expr->to<IR::PathExpression>()) {
            outName = resolvePathName(base, refMap);
            return true;
        }
        return false;
    }
    if (auto pe = mce->method->to<IR::PathExpression>()) {
        outMethod = pe->path->name.toString().c_str();
        outName = resolvePathName(pe, refMap);
        return true;
    }
    return false;
}

static void collectExprKeys(const IR::Expression* expr,
                            std::set<VarKey, VarKeyLess>& out,
                            P4::TypeMap* typeMap);

static void collectLValueUseKeys(const IR::Expression* expr,
                                 std::set<VarKey, VarKeyLess>& out,
                                 P4::TypeMap* typeMap) {
    if (!expr) {
        return;
    }
    if (auto cast = expr->to<IR::Cast>()) {
        collectLValueUseKeys(cast->expr, out, typeMap);
        return;
    }
    if (auto member = expr->to<IR::Member>()) {
        collectLValueUseKeys(member->expr, out, typeMap);
        return;
    }
    if (auto arr = expr->to<IR::ArrayIndex>()) {
        collectLValueUseKeys(arr->left, out, typeMap);
        collectExprKeys(arr->right, out, typeMap);
        return;
    }
    if (auto slice = expr->to<IR::Slice>()) {
        collectLValueUseKeys(slice->e0, out, typeMap);
        return;
    }
    if (auto list = expr->to<IR::ListExpression>()) {
        for (auto comp : list->components) {
            collectLValueUseKeys(comp, out, typeMap);
        }
        return;
    }
    if (auto str = expr->to<IR::StructExpression>()) {
        for (auto comp : str->components) {
            if (comp && comp->expression) {
                collectLValueUseKeys(comp->expression, out, typeMap);
            }
        }
    }
}

static void collectRegActionCallArgs(const IR::Vector<IR::Argument>* args,
                                     std::set<VarKey, VarKeyLess>& uses,
                                     std::set<VarKey, VarKeyLess>& defs,
                                     P4::TypeMap* typeMap) {
    if (!args) {
        return;
    }
    int idx = 0;
    for (auto arg : *args) {
        if (arg && arg->expression) {
            // Conservatively treat the first argument as the register index (use-only).
            // Subsequent args may be in/out/inout; treat as both use+def to avoid unsound slicing.
            if (idx == 0) {
                collectExprKeys(arg->expression, uses, typeMap);
            } else {
                collectExprKeys(arg->expression, uses, typeMap);
                collectExprKeys(arg->expression, defs, typeMap);
            }
        }
        idx++;
    }
}

static void collectExprKeys(const IR::Expression* expr,
                            std::set<VarKey, VarKeyLess>& out,
                            P4::TypeMap* typeMap) {
    if (!expr) {
        return;
    }
    if (auto cast = expr->to<IR::Cast>()) {
        collectExprKeys(cast->expr, out, typeMap);
        return;
    }
    if (auto path = expr->to<IR::PathExpression>()) {
        VarKey key;
        key.base = path->path->toString();
        addVarKey(out, key);
        return;
    }
    if (auto member = expr->to<IR::Member>()) {
        VarKey full;
        if (buildVarKey(member, full)) {
            addVarKey(out, full);
            return;
        }
        if (auto arr = member->expr->to<IR::ArrayIndex>()) {
            VarKey base;
            if (buildVarKey(arr->left, base)) {
                if (auto c = arr->right->to<IR::Constant>()) {
                    VarKey key = base;
                    key.segs.push_back(std::string(Util::toString(c->value, 0, false).c_str()));
                    key.segs.push_back(std::string(member->member.toString().c_str()));
                    addVarKey(out, key);
                    return;
                }
                const IR::Type* t = typeMap ? typeMap->getType(arr->left) : nullptr;
                auto stack = P4VerifyCompat::asHeaderStackType(t);
                if (stack && stack->sizeKnown()) {
                    unsigned sz = stack->getSize();
                    for (unsigned i = 0; i < sz; ++i) {
                        VarKey key = base;
                        key.segs.push_back(std::to_string(i));
                        key.segs.push_back(std::string(member->member.toString().c_str()));
                        addVarKey(out, key);
                    }
                    VarKey last = base;
                    last.segs.push_back("last");
                    last.segs.push_back(std::string(member->member.toString().c_str()));
                    addVarKey(out, last);
                    return;
                }
            }
        }
        collectExprKeys(member->expr, out, typeMap);
        return;
    }
    if (auto arr = expr->to<IR::ArrayIndex>()) {
        VarKey base;
        if (buildVarKey(arr->left, base)) {
            if (auto c = arr->right->to<IR::Constant>()) {
                base.segs.push_back(std::string(Util::toString(c->value, 0, false).c_str()));
                addVarKey(out, base);
            } else {
                const IR::Type* t = typeMap ? typeMap->getType(arr->left) : nullptr;
                auto stack = P4VerifyCompat::asHeaderStackType(t);
                if (stack && stack->sizeKnown()) {
                    unsigned sz = stack->getSize();
                    for (unsigned i = 0; i < sz; ++i) {
                        VarKey k = base;
                        k.segs.push_back(std::to_string(i));
                        addVarKey(out, k);
                    }
                    VarKey last = base;
                    last.segs.push_back("last");
                    addVarKey(out, last);
                } else {
                    addVarKey(out, base);
                }
            }
        }
        if (arr->right) {
            collectExprKeys(arr->right, out, typeMap);
        }
        return;
    }
    if (auto slice = expr->to<IR::Slice>()) {
        collectExprKeys(slice->e0, out, typeMap);
        if (slice->e1) {
            collectExprKeys(slice->e1, out, typeMap);
        }
        if (slice->e2) {
            collectExprKeys(slice->e2, out, typeMap);
        }
        return;
    }
    if (auto unary = expr->to<IR::Operation_Unary>()) {
        collectExprKeys(unary->expr, out, typeMap);
        return;
    }
    if (auto bin = expr->to<IR::Operation_Binary>()) {
        collectExprKeys(bin->left, out, typeMap);
        collectExprKeys(bin->right, out, typeMap);
        return;
    }
    if (auto list = expr->to<IR::ListExpression>()) {
        for (auto comp : list->components) {
            collectExprKeys(comp, out, typeMap);
        }
        return;
    }
    if (auto str = expr->to<IR::StructExpression>()) {
        for (auto comp : str->components) {
            if (comp && comp->expression) {
                collectExprKeys(comp->expression, out, typeMap);
            }
        }
        return;
    }
    if (auto ternary = expr->to<IR::Operation_Ternary>()) {
        collectExprKeys(ternary->e0, out, typeMap);
        collectExprKeys(ternary->e1, out, typeMap);
        collectExprKeys(ternary->e2, out, typeMap);
        return;
    }
    if (auto mce = expr->to<IR::MethodCallExpression>()) {
        if (auto member = mce->method ? mce->method->to<IR::Member>() : nullptr) {
            if (member->member == "isValid") {
                addHeaderValidKey(out, member->expr);
                return;
            }
        }
        if (mce->method) {
            collectExprKeys(mce->method, out, typeMap);
        }
        if (mce->arguments) {
            for (auto arg : *mce->arguments) {
                if (arg && arg->expression) {
                    collectExprKeys(arg->expression, out, typeMap);
                }
            }
        }
        return;
    }
}

// Header-stack pop_front shifts element fields and validity across all indices.
// If we slice without modeling these implicit reads/writes, the pruned program can
// still translate into Boogie that references stack elements/fields whose declarations
// were filtered out, leading to ill-typed Boogie.
static bool collectHeaderStackPopFrontKeys(const IR::Expression* receiver,
                                           std::set<VarKey, VarKeyLess>& uses,
                                           std::set<VarKey, VarKeyLess>& defs,
                                           P4::TypeMap* typeMap) {
    if (!receiver || !typeMap) {
        return false;
    }
    const IR::Type* recvType = typeMap->getType(receiver);
    auto stack = P4VerifyCompat::asHeaderStackType(recvType);
    if (!stack || !stack->sizeKnown()) {
        return false;
    }
    VarKey base;
    if (!buildVarKey(receiver, base) || base.base.empty() || base.segs.empty()) {
        return false;
    }

    const IR::Type* elemType = nullptr;
    if (stack->elementType) {
        elemType = typeMap->getTypeType(stack->elementType, true);
    }
    const IR::Type_Header* elemHeader = elemType ? elemType->to<IR::Type_Header>() : nullptr;

    std::vector<std::string> fieldNames;
    if (elemHeader) {
        fieldNames.reserve(elemHeader->fields.size());
        for (const auto* f : elemHeader->fields) {
            if (f) {
                fieldNames.push_back(f->name.name.c_str());
            }
        }
    }

    // pop_front mutates the entire stack; conservatively treat all elements and their
    // fields/validity as both read and written.
    const unsigned sz = stack->getSize();
    for (unsigned i = 0; i < sz; ++i) {
        VarKey elem = base;
        elem.segs.push_back(std::to_string(i));
        addVarKey(uses, elem);
        addVarKey(defs, elem);

        VarKey valid = elem;
        valid.segs.push_back("valid");
        addVarKey(uses, valid);
        addVarKey(defs, valid);

        for (const auto& fname : fieldNames) {
            VarKey field = elem;
            field.segs.push_back(fname);
            addVarKey(uses, field);
            addVarKey(defs, field);
        }
    }
    return true;
}

static void mergeSets(std::set<VarKey, VarKeyLess>& dst,
                      const std::set<VarKey, VarKeyLess>& src) {
    dst.insert(src.begin(), src.end());
}

static void collectApplyCalleesFromExpr(const IR::Expression* expr,
                                        std::unordered_set<cstring>& out,
                                        P4::ReferenceMap* refMap) {
    if (!expr) {
        return;
    }
    if (auto cast = expr->to<IR::Cast>()) {
        collectApplyCalleesFromExpr(cast->expr, out, refMap);
        return;
    }
    if (auto member = expr->to<IR::Member>()) {
        collectApplyCalleesFromExpr(member->expr, out, refMap);
        return;
    }
    if (auto arr = expr->to<IR::ArrayIndex>()) {
        collectApplyCalleesFromExpr(arr->left, out, refMap);
        if (arr->right) {
            collectApplyCalleesFromExpr(arr->right, out, refMap);
        }
        return;
    }
    if (auto slice = expr->to<IR::Slice>()) {
        collectApplyCalleesFromExpr(slice->e0, out, refMap);
        if (slice->e1) {
            collectApplyCalleesFromExpr(slice->e1, out, refMap);
        }
        if (slice->e2) {
            collectApplyCalleesFromExpr(slice->e2, out, refMap);
        }
        return;
    }
    if (auto unary = expr->to<IR::Operation_Unary>()) {
        collectApplyCalleesFromExpr(unary->expr, out, refMap);
        return;
    }
    if (auto bin = expr->to<IR::Operation_Binary>()) {
        collectApplyCalleesFromExpr(bin->left, out, refMap);
        collectApplyCalleesFromExpr(bin->right, out, refMap);
        return;
    }
    if (auto list = expr->to<IR::ListExpression>()) {
        for (auto comp : list->components) {
            collectApplyCalleesFromExpr(comp, out, refMap);
        }
        return;
    }
    if (auto str = expr->to<IR::StructExpression>()) {
        for (auto comp : str->components) {
            if (comp && comp->expression) {
                collectApplyCalleesFromExpr(comp->expression, out, refMap);
            }
        }
        return;
    }
    if (auto ternary = expr->to<IR::Operation_Ternary>()) {
        collectApplyCalleesFromExpr(ternary->e0, out, refMap);
        collectApplyCalleesFromExpr(ternary->e1, out, refMap);
        collectApplyCalleesFromExpr(ternary->e2, out, refMap);
        return;
    }
    if (auto mce = expr->to<IR::MethodCallExpression>()) {
        cstring name;
        if (regActionCallName(mce, name, refMap)) {
            out.insert(name);
        }
        if (mce->method) {
            collectApplyCalleesFromExpr(mce->method, out, refMap);
        }
        if (mce->arguments) {
            for (auto arg : *mce->arguments) {
                if (arg && arg->expression) {
                    collectApplyCalleesFromExpr(arg->expression, out, refMap);
                }
            }
        }
        return;
    }
}

static void collectApplyUsesDefsFromExpr(const IR::Expression* expr,
                                        std::set<VarKey, VarKeyLess>& uses,
                                        std::set<VarKey, VarKeyLess>& defs,
                                        P4::TypeMap* typeMap,
                                        const std::unordered_map<cstring, UsesDefs>& tableUsesDefs,
                                        const std::unordered_map<cstring, UsesDefs>& regActionUsesDefs,
                                        P4::ReferenceMap* refMap) {
    if (!expr) {
        return;
    }
    if (auto cast = expr->to<IR::Cast>()) {
        collectApplyUsesDefsFromExpr(
            cast->expr, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        return;
    }
    if (auto member = expr->to<IR::Member>()) {
        collectApplyUsesDefsFromExpr(
            member->expr, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        return;
    }
    if (auto arr = expr->to<IR::ArrayIndex>()) {
        collectApplyUsesDefsFromExpr(
            arr->left, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        if (arr->right) {
            collectApplyUsesDefsFromExpr(
                arr->right, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        }
        return;
    }
    if (auto slice = expr->to<IR::Slice>()) {
        collectApplyUsesDefsFromExpr(
            slice->e0, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        if (slice->e1) {
            collectApplyUsesDefsFromExpr(
                slice->e1, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        }
        if (slice->e2) {
            collectApplyUsesDefsFromExpr(
                slice->e2, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        }
        return;
    }
    if (auto unary = expr->to<IR::Operation_Unary>()) {
        collectApplyUsesDefsFromExpr(
            unary->expr, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        return;
    }
    if (auto bin = expr->to<IR::Operation_Binary>()) {
        collectApplyUsesDefsFromExpr(
            bin->left, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        collectApplyUsesDefsFromExpr(
            bin->right, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        return;
    }
    if (auto list = expr->to<IR::ListExpression>()) {
        for (auto comp : list->components) {
            collectApplyUsesDefsFromExpr(
                comp, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        }
        return;
    }
    if (auto str = expr->to<IR::StructExpression>()) {
        for (auto comp : str->components) {
            if (comp && comp->expression) {
                collectApplyUsesDefsFromExpr(
                    comp->expression, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
            }
        }
        return;
    }
    if (auto ternary = expr->to<IR::Operation_Ternary>()) {
        collectApplyUsesDefsFromExpr(
            ternary->e0, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        collectApplyUsesDefsFromExpr(
            ternary->e1, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        collectApplyUsesDefsFromExpr(
            ternary->e2, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        return;
    }
    if (auto mce = expr->to<IR::MethodCallExpression>()) {
        cstring name;
        if (regActionCallName(mce, name, refMap)) {
            auto tit = tableUsesDefs.find(name);
            if (tit != tableUsesDefs.end()) {
                mergeSets(uses, tit->second.uses);
                mergeSets(defs, tit->second.defs);
            } else {
                auto rit = regActionUsesDefs.find(name);
                if (rit != regActionUsesDefs.end()) {
                    mergeSets(uses, rit->second.uses);
                    mergeSets(defs, rit->second.defs);
                    collectRegActionCallArgs(mce->arguments, uses, defs, typeMap);
                }
            }
        }
        if (mce->method) {
            collectApplyUsesDefsFromExpr(
                mce->method, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        }
        if (mce->arguments) {
            for (auto arg : *mce->arguments) {
                if (arg && arg->expression) {
                    collectApplyUsesDefsFromExpr(
                        arg->expression, uses, defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
                }
            }
        }
        return;
    }
}

static void collectStmtIds(const IR::Statement* stmt, std::unordered_set<int>& out) {
    if (!stmt) {
        return;
    }
    out.insert(stmt->id);
    if (auto block = stmt->to<IR::BlockStatement>()) {
        for (auto comp : block->components) {
            if (auto compStmt = comp->to<IR::Statement>()) {
                collectStmtIds(compStmt, out);
            }
        }
        return;
    }
    if (auto ifs = stmt->to<IR::IfStatement>()) {
        collectStmtIds(ifs->ifTrue, out);
        collectStmtIds(ifs->ifFalse, out);
        return;
    }
    if (auto sw = stmt->to<IR::SwitchStatement>()) {
        for (auto c : sw->cases) {
            if (c && c->statement) {
                collectStmtIds(c->statement, out);
            }
        }
        return;
    }
}

static const IR::Function* findRegisterActionApply(const IR::Declaration_Instance* instance) {
    if (instance == nullptr || instance->initializer == nullptr) {
        return nullptr;
    }
    if (auto block = instance->initializer->to<IR::BlockStatement>()) {
        for (auto comp : block->components) {
            if (auto func = comp->to<IR::Function>()) {
                if (func->name == "apply") {
                    return func;
                }
            }
        }
    }
    return nullptr;
}

static void collectStmtUsesDefs(const IR::Statement* stmt,
                                UsesDefs& out,
                                P4::TypeMap* typeMap,
                                const std::unordered_map<cstring, UsesDefs>* regActionUsesDefs = nullptr,
                                P4::ReferenceMap* refMap = nullptr) {
    if (!stmt) {
        return;
    }
    if (auto block = stmt->to<IR::BlockStatement>()) {
        for (auto comp : block->components) {
            if (auto compStmt = comp->to<IR::Statement>()) {
                collectStmtUsesDefs(compStmt, out, typeMap, regActionUsesDefs, refMap);
            }
        }
        return;
    }
    if (auto as = stmt->to<IR::AssignmentStatement>()) {
        collectExprKeys(as->left, out.defs, typeMap);
        collectExprKeys(as->right, out.uses, typeMap);
        collectLValueUseKeys(as->left, out.uses, typeMap);
        if (regActionUsesDefs) {
            static const std::unordered_map<cstring, UsesDefs> kEmptyTableUsesDefs;
            collectApplyUsesDefsFromExpr(as->right, out.uses, out.defs, typeMap,
                                         kEmptyTableUsesDefs, *regActionUsesDefs, refMap);
        }
        return;
    }
    if (auto mcs = stmt->to<IR::MethodCallStatement>()) {
        auto mce = mcs->methodCall;
        if (!mce) {
            return;
        }
        bool handled = false;
        const IR::Expression* receiver = nullptr;
        std::string methodName;
        if (auto member = mce->method->to<IR::Member>()) {
            receiver = member->expr;
            methodName = member->member.toString().c_str();
        } else if (auto pe = mce->method->to<IR::PathExpression>()) {
            // Some v1model built-ins (e.g., mark_to_drop(standard_metadata)) are direct calls
            // and appear as PathExpression in the IR.
            methodName = pe->path->name.name.c_str();
        }
        if (methodName == "apply" || methodName == "execute") {
            if (regActionUsesDefs) {
                if (auto member = mce->method->to<IR::Member>()) {
                    if (auto base = member->expr->to<IR::PathExpression>()) {
                        cstring baseName = resolvePathName(base, refMap);
                        auto it = regActionUsesDefs->find(baseName);
                        if (it != regActionUsesDefs->end()) {
                            mergeSets(out.uses, it->second.uses);
                            mergeSets(out.defs, it->second.defs);
                            collectRegActionCallArgs(mce->arguments, out.uses, out.defs, typeMap);
                            handled = true;
                        }
                    }
                }
            }
        } else if (methodName == "extract") {
            if (mce->arguments) {
                for (auto arg : *mce->arguments) {
                    if (arg && arg->expression) {
                        collectExprKeys(arg->expression, out.defs, typeMap);
                        addHeaderValidKey(out.defs, arg->expression);
                    }
                }
            }
            handled = true;
        } else if (methodName == "emit") {
            if (mce->arguments) {
                for (auto arg : *mce->arguments) {
                    if (arg && arg->expression) {
                        collectExprKeys(arg->expression, out.uses, typeMap);
                    }
                }
            }
            handled = true;
        } else if (methodName == "setValid" || methodName == "setInvalid") {
            addHeaderValidKey(out.defs, receiver);
            handled = true;
        } else if (methodName == "update_checksum" ||
                   methodName == "update_checksum_with_payload") {
            std::set<VarKey, VarKeyLess> checksumTargets;
            if (mce->arguments) {
                int idx = 0;
                for (auto arg : *mce->arguments) {
                    if (arg && arg->expression) {
                        if (idx == 2) {
                            VarKey def;
                            if (buildVarKey(arg->expression, def)) {
                                checksumTargets.insert(def);
                            } else {
                                collectExprKeys(arg->expression, checksumTargets, typeMap);
                            }
                        } else {
                            collectExprKeys(arg->expression, out.uses, typeMap);
                        }
                    }
                    idx++;
                }
            }
            for (const auto& def : checksumTargets) {
                out.defs.insert(def);
            }
            handled = true;
        } else if (methodName == "mark_to_drop") {
            VarKey dropKey;
            dropKey.base = "drop";
            addVarKey(out.defs, dropKey);
            handled = true;
        } else if (methodName == "hash") {
            // v1model hash(out, algorithm, base, data, max): the first
            // argument is the produced index, while the range/data arguments
            // determine that index. Treating all arguments as both uses and
            // defs lets slicing drop the producer action body for dynamic
            // register indices.
            if (mce->arguments) {
                int argIdx = 0;
                for (auto arg : *mce->arguments) {
                    if (!arg || !arg->expression) {
                        argIdx++;
                        continue;
                    }
                    if (argIdx == 0) {
                        collectExprKeys(arg->expression, out.defs, typeMap);
                    } else {
                        collectExprKeys(arg->expression, out.uses, typeMap);
                    }
                    argIdx++;
                }
            }
            handled = true;
        } else if (methodName == "write") {
            if (receiver) {
                collectExprKeys(receiver, out.defs, typeMap);
            }
            if (mce->arguments) {
                for (auto arg : *mce->arguments) {
                    if (arg && arg->expression) {
                        collectExprKeys(arg->expression, out.uses, typeMap);
                    }
                }
            }
            handled = true;
        } else if (methodName == "read") {
            // Model register-like read(outVar, idx):
            // - receiver is read (use)
            // - first argument is written (def)
            // - remaining arguments are read (use)
            if (receiver) {
                collectExprKeys(receiver, out.uses, typeMap);
            }
            if (mce->arguments) {
                int argIdx = 0;
                for (auto arg : *mce->arguments) {
                    if (!arg || !arg->expression) {
                        argIdx++;
                        continue;
                    }
                    if (argIdx == 0) {
                        collectExprKeys(arg->expression, out.defs, typeMap);
                    } else {
                        collectExprKeys(arg->expression, out.uses, typeMap);
                    }
                    argIdx++;
                }
            }
            handled = true;
        } else if (methodName == "pop_front") {
            if (receiver) {
                if (!collectHeaderStackPopFrontKeys(receiver, out.uses, out.defs, typeMap)) {
                    // Fallback: treat it as a read+write to the receiver.
                    collectExprKeys(receiver, out.uses, typeMap);
                    collectExprKeys(receiver, out.defs, typeMap);
                }
            }
            if (mce->arguments) {
                for (auto arg : *mce->arguments) {
                    if (arg && arg->expression) {
                        collectExprKeys(arg->expression, out.uses, typeMap);
                    }
                }
            }
            handled = true;
        }
        if (!handled) {
            collectExprKeys(mce, out.uses, typeMap);
            mergeSets(out.defs, out.uses);
        }
        return;
    }
    if (auto ifs = stmt->to<IR::IfStatement>()) {
        collectExprKeys(ifs->condition, out.uses, typeMap);
        collectStmtUsesDefs(ifs->ifTrue, out, typeMap, regActionUsesDefs, refMap);
        collectStmtUsesDefs(ifs->ifFalse, out, typeMap, regActionUsesDefs, refMap);
        return;
    }
    if (auto sw = stmt->to<IR::SwitchStatement>()) {
        collectExprKeys(sw->expression, out.uses, typeMap);
        for (auto c : sw->cases) {
            if (c && c->statement) {
                collectStmtUsesDefs(c->statement, out, typeMap, regActionUsesDefs, refMap);
            }
        }
        return;
    }
}

static bool usesDefsIntersect(const UsesDefs& ud, const std::set<VarKey, VarKeyLess>& vars) {
    for (const auto& d : ud.defs) {
        if (vars.count(d)) {
            return true;
        }
    }
    return false;
}

static bool usesIntersect(const UsesDefs& ud, const std::set<VarKey, VarKeyLess>& vars) {
    for (const auto& u : ud.uses) {
        if (vars.count(u)) {
            return true;
        }
    }
    return false;
}

static bool isWriteMethodCallStatement(const IR::Statement* stmt) {
    auto mcs = stmt ? stmt->to<IR::MethodCallStatement>() : nullptr;
    if (!mcs || !mcs->methodCall || !mcs->methodCall->method) {
        return false;
    }
    auto member = mcs->methodCall->method->to<IR::Member>();
    if (!member) {
        return false;
    }
    return member->member == "write";
}

static bool isStatefulWriteMethodCallStatement(
    const IR::Statement* stmt,
    const std::unordered_map<cstring, UsesDefs>* regActionUsesDefs,
    P4::ReferenceMap* refMap) {
    if (isWriteMethodCallStatement(stmt)) {
        return true;
    }
    auto mcs = stmt ? stmt->to<IR::MethodCallStatement>() : nullptr;
    if (!mcs || !mcs->methodCall || !mcs->methodCall->method) {
        return false;
    }
    auto member = mcs->methodCall->method->to<IR::Member>();
    if (!member || member->member != "execute") {
        return false;
    }
    auto base = member->expr->to<IR::PathExpression>();
    if (!base || regActionUsesDefs == nullptr) {
        return false;
    }
    return regActionUsesDefs->find(resolvePathName(base, refMap)) != regActionUsesDefs->end();
}

static void fillNodeUsesDefs(NodeInfo& node,
                             P4::TypeMap* typeMap,
                             const std::unordered_map<cstring, UsesDefs>& tableUsesDefs,
                             const std::unordered_map<cstring, UsesDefs>& actionUsesDefs,
                             const std::unordered_map<cstring, UsesDefs>& regActionUsesDefs,
                             bool* hasRecirculation,
                             bool debug,
                             const std::unordered_map<std::string, std::vector<VarKey>>* extractSeedFields = nullptr,
                             const std::set<VarKey, VarKeyLess>* seedVars = nullptr,
                             P4::ReferenceMap* refMap = nullptr) {
    if (!node.stmt) {
        return;
    }
    if (debug) {
        std::cerr << "[slicer] node type=" << node.stmt->node_type_name() << "\n";
    }
    if (auto as = node.stmt->to<IR::AssignmentStatement>()) {
        if (debug) {
            std::cerr << "[slicer]  assignment lhs/rhs\n";
        }
        collectExprKeys(as->left, node.defs, typeMap);
        collectExprKeys(as->right, node.uses, typeMap);
        collectLValueUseKeys(as->left, node.uses, typeMap);
        collectApplyUsesDefsFromExpr(
            as->right, node.uses, node.defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        if (auto mce = as->right->to<IR::MethodCallExpression>()) {
            cstring name;
            if (regActionCallName(mce, name, refMap)) {
                auto it = regActionUsesDefs.find(name);
                if (it != regActionUsesDefs.end()) {
                    mergeSets(node.uses, it->second.uses);
                    mergeSets(node.defs, it->second.defs);
                    collectRegActionCallArgs(mce->arguments, node.uses, node.defs, typeMap);
                }
            }
        }
        return;
    }
    if (auto mcs = node.stmt->to<IR::MethodCallStatement>()) {
        auto expr = mcs->methodCall;
        if (debug) {
            std::cerr << "[slicer]  method call\n";
        }
        bool handled = false;
        const IR::Expression* receiver = nullptr;
        std::string methodName;
        if (expr && expr->method) {
            if (auto member = expr->method->to<IR::Member>()) {
                receiver = member->expr;
                methodName = member->member.toString().c_str();
                if (member->member == "apply" || member->member == "execute") {
                    if (auto base = member->expr->to<IR::PathExpression>()) {
                        cstring baseName = resolvePathName(base, refMap);
                        auto it = tableUsesDefs.find(baseName);
                        if (it != tableUsesDefs.end()) {
                            mergeSets(node.uses, it->second.uses);
                            mergeSets(node.defs, it->second.defs);
                            handled = true;
                        } else {
                            auto rit = regActionUsesDefs.find(baseName);
                            if (rit != regActionUsesDefs.end()) {
                                mergeSets(node.uses, rit->second.uses);
                                mergeSets(node.defs, rit->second.defs);
                                collectRegActionCallArgs(expr ? expr->arguments : nullptr,
                                                        node.uses,
                                                        node.defs,
                                                        typeMap);
                                handled = true;
                            }
                        }
                    }
                }
            } else if (auto pe = expr->method->to<IR::PathExpression>()) {
                methodName = pe->path->name.name.c_str();
                cstring actName = resolvePathName(pe, refMap);
                auto it = actionUsesDefs.find(actName);
                if (it != actionUsesDefs.end()) {
                    mergeSets(node.uses, it->second.uses);
                    mergeSets(node.defs, it->second.defs);
                    handled = true;
                }
            }
        }
            if (!handled) {
                if (methodName == "extract") {
                    if (expr && expr->arguments) {
                        for (auto arg : *expr->arguments) {
                            if (arg && arg->expression) {
                                collectExprKeys(arg->expression, node.defs, typeMap);
                                addHeaderValidKey(node.defs, arg->expression);
                                if (extractSeedFields) {
                                    VarKey hdrKey;
                                    if (buildVarKey(arg->expression, hdrKey)) {
                                        auto it = extractSeedFields->find(varKeyToString(hdrKey));
                                        if (it != extractSeedFields->end()) {
                                            for (const auto& v : it->second) {
                                                addVarKey(node.defs, v);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    handled = true;
                } else if (methodName == "emit") {
                    if (expr && expr->arguments) {
                        for (auto arg : *expr->arguments) {
                            if (arg && arg->expression) {
                                collectExprKeys(arg->expression, node.uses, typeMap);
                            }
                        }
                    }
                    handled = true;
                } else if (methodName == "update_checksum" ||
                           methodName == "update_checksum_with_payload") {
                    std::set<VarKey, VarKeyLess> checksumTargets;
                    if (expr && expr->arguments) {
                        int idx = 0;
                        for (auto arg : *expr->arguments) {
                            if (arg && arg->expression) {
                                if (idx == 2) {
                                    VarKey def;
                                    if (buildVarKey(arg->expression, def)) {
                                        checksumTargets.insert(def);
                                    } else {
                                        collectExprKeys(arg->expression, checksumTargets, typeMap);
                                    }
                                } else {
                                    collectExprKeys(arg->expression, node.uses, typeMap);
                                }
                            }
                            idx++;
                        }
                    }
                    if (seedVars) {
                        bool needed = false;
                        for (const auto& def : checksumTargets) {
                            if (seedVars->count(def)) {
                                needed = true;
                                break;
                            }
                        }
                        if (!needed) {
                            handled = true;
                            return;
                        }
                    }
                    for (const auto& def : checksumTargets) {
                        node.defs.insert(def);
                    }
                    handled = true;
                } else if (methodName == "setValid" || methodName == "setInvalid") {
                    addHeaderValidKey(node.defs, receiver);
                    handled = true;
            } else if (methodName == "mark_to_drop") {
                VarKey dropKey;
                dropKey.base = "drop";
                addVarKey(node.defs, dropKey);
                handled = true;
            } else if (methodName == "hash") {
                if (expr && expr->arguments) {
                    int argIdx = 0;
                    for (auto arg : *expr->arguments) {
                        if (!arg || !arg->expression) {
                            argIdx++;
                            continue;
                        }
                        if (argIdx == 0) {
                            collectExprKeys(arg->expression, node.defs, typeMap);
                        } else {
                            collectExprKeys(arg->expression, node.uses, typeMap);
                        }
                        argIdx++;
                    }
                }
                handled = true;
            } else if (methodName == "write") {
                if (receiver) {
                    collectExprKeys(receiver, node.defs, typeMap);
                }
                if (expr && expr->arguments) {
                    for (auto arg : *expr->arguments) {
                        if (arg && arg->expression) {
                            collectExprKeys(arg->expression, node.uses, typeMap);
                        }
                    }
                }
                handled = true;
            } else if (methodName == "read") {
                // Model register-like read(outVar, idx):
                // - receiver is read (use)
                // - first argument is written (def)
                // - remaining arguments are read (use)
                if (receiver) {
                    collectExprKeys(receiver, node.uses, typeMap);
                }
                if (expr && expr->arguments) {
                    int argIdx = 0;
                    for (auto arg : *expr->arguments) {
                        if (!arg || !arg->expression) {
                            argIdx++;
                            continue;
                        }
                        if (argIdx == 0) {
                            collectExprKeys(arg->expression, node.defs, typeMap);
                        } else {
                            collectExprKeys(arg->expression, node.uses, typeMap);
                        }
                        argIdx++;
                    }
                }
                handled = true;
            } else if (methodName == "pop_front") {
                if (receiver) {
                    if (!collectHeaderStackPopFrontKeys(receiver, node.uses, node.defs, typeMap)) {
                        collectExprKeys(receiver, node.uses, typeMap);
                        collectExprKeys(receiver, node.defs, typeMap);
                    }
                }
                if (expr && expr->arguments) {
                    for (auto arg : *expr->arguments) {
                        if (arg && arg->expression) {
                            collectExprKeys(arg->expression, node.uses, typeMap);
                        }
                    }
                }
                handled = true;
            }
        }
        if (!handled) {
            collectExprKeys(expr, node.uses, typeMap);
            mergeSets(node.defs, node.uses);
        }
        if (expr && expr->method) {
            if (debug) {
                std::cerr << "[slicer]   method name\n";
            }
            auto mname = expr->method->toString();
            std::string lower;
            lower.reserve(mname.size());
            for (char c : mname) {
                lower.push_back(static_cast<char>(::tolower(c)));
            }
            const bool isRecirculateExtern =
                lower.find("recirculate") != std::string::npos ||
                lower.find("resubmit") != std::string::npos;
            const bool isCloneMirrorExtern =
                lower.find("mirror") != std::string::npos ||
                lower.find("clone") != std::string::npos;
            if (hasRecirculation && (isRecirculateExtern || isCloneMirrorExtern)) {
                *hasRecirculation = true;
            }
            // Preserve the semantic effect of clone/recirc/resubmit for slicing.
            //
            // These externs do not necessarily read/write any seed-relevant P4 state directly,
            // but they *do* change the control/communication behavior of the program. We model
            // them as writes to the synthetic control flags that the Boogie backend relies on
            // (`p4b_*`). This allows `--slicing-vars` / control-seed selection to keep the
            // relevant calls and their control dependencies.
            if (isRecirculateExtern) {
                VarKey key;
                key.base = "p4b_recirculate";
                addVarKey(node.defs, key);
            }
            if (isCloneMirrorExtern) {
                VarKey i2e;
                i2e.base = "p4b_clone_i2e";
                addVarKey(node.defs, i2e);
                // Be conservative: some targets/externs may map to other clone directions.
                VarKey e2e;
                e2e.base = "p4b_clone_e2e";
                addVarKey(node.defs, e2e);
                VarKey i2i;
                i2i.base = "p4b_clone_i2i";
                addVarKey(node.defs, i2i);
            }
            if (lower.find("mark_to_drop") != std::string::npos) {
                VarKey dropKey;
                dropKey.base = "drop";
                addVarKey(node.defs, dropKey);
            }
        }
        return;
    }
    if (auto ifs = node.stmt->to<IR::IfStatement>()) {
        if (debug) {
            std::cerr << "[slicer]  if condition\n";
        }
        collectExprKeys(ifs->condition, node.uses, typeMap);
        collectApplyUsesDefsFromExpr(
            ifs->condition, node.uses, node.defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        return;
    }
    if (auto sw = node.stmt->to<IR::SwitchStatement>()) {
        if (debug) {
            std::cerr << "[slicer]  switch expression\n";
        }
        collectExprKeys(sw->expression, node.uses, typeMap);
        collectApplyUsesDefsFromExpr(
            sw->expression, node.uses, node.defs, typeMap, tableUsesDefs, regActionUsesDefs, refMap);
        return;
    }
}

static void mergeVarSets(std::set<VarKey, VarKeyLess>& dst, const std::set<VarKey, VarKeyLess>& src) {
    for (const auto& v : src) {
        insertVarKey(dst, v);
    }
}

static bool sliceActionStmt(const IR::Statement* stmt,
                            std::set<VarKey, VarKeyLess>& needed,
                            std::unordered_set<int>& keepIds,
                            P4::TypeMap* typeMap,
                            const std::unordered_map<cstring, UsesDefs>* regActionUsesDefs,
                            P4::ReferenceMap* refMap = nullptr) {
    if (!stmt) {
        return false;
    }
    if (auto block = stmt->to<IR::BlockStatement>()) {
        bool anyKept = false;
        for (auto it = block->components.rbegin(); it != block->components.rend(); ++it) {
            if (auto compStmt = (*it)->to<IR::Statement>()) {
                anyKept = sliceActionStmt(compStmt, needed, keepIds, typeMap, regActionUsesDefs, refMap) || anyKept;
            }
        }
        return anyKept;
    }
    if (auto ifs = stmt->to<IR::IfStatement>()) {
        std::set<VarKey, VarKeyLess> neededTrue = needed;
        std::set<VarKey, VarKeyLess> neededFalse = needed;
        std::unordered_set<int> keepTrue;
        std::unordered_set<int> keepFalse;
        bool keepT = sliceActionStmt(ifs->ifTrue, neededTrue, keepTrue, typeMap, regActionUsesDefs, refMap);
        bool keepF = sliceActionStmt(ifs->ifFalse, neededFalse, keepFalse, typeMap, regActionUsesDefs, refMap);
        if (!keepT && !keepF) {
            mergeVarSets(neededTrue, neededFalse);
            needed = std::move(neededTrue);
            return false;
        }
        keepIds.insert(ifs->id);
        keepIds.insert(keepTrue.begin(), keepTrue.end());
        keepIds.insert(keepFalse.begin(), keepFalse.end());
        std::set<VarKey, VarKeyLess> condUses;
        collectExprKeys(ifs->condition, condUses, typeMap);
        mergeVarSets(neededTrue, neededFalse);
        mergeVarSets(neededTrue, condUses);
        needed = std::move(neededTrue);
        return true;
    }
    if (auto sw = stmt->to<IR::SwitchStatement>()) {
        bool keepSw = false;
        std::set<VarKey, VarKeyLess> mergedNeeded = needed;
        std::unordered_set<int> keepCases;
        for (auto c : sw->cases) {
            if (!c || !c->statement) {
                continue;
            }
            std::set<VarKey, VarKeyLess> caseNeeded = needed;
            std::unordered_set<int> caseKeep;
            bool caseKept = sliceActionStmt(c->statement, caseNeeded, caseKeep, typeMap, regActionUsesDefs, refMap);
            if (!caseKept) {
                continue;
            }
            keepSw = true;
            keepCases.insert(caseKeep.begin(), caseKeep.end());
            mergeVarSets(mergedNeeded, caseNeeded);
        }
        if (!keepSw) {
            needed = std::move(mergedNeeded);
            return false;
        }
        keepIds.insert(sw->id);
        keepIds.insert(keepCases.begin(), keepCases.end());
        std::set<VarKey, VarKeyLess> exprUses;
        collectExprKeys(sw->expression, exprUses, typeMap);
        mergeVarSets(mergedNeeded, exprUses);
        needed = std::move(mergedNeeded);
        return true;
    }
    UsesDefs ud;
    collectStmtUsesDefs(stmt, ud, typeMap, regActionUsesDefs, refMap);
    bool keep = usesDefsIntersect(ud, needed);
    const bool statefulWriteDependsOnNeeded =
        (!keep && isStatefulWriteMethodCallStatement(stmt, regActionUsesDefs, refMap) &&
         (usesIntersect(ud, needed) || usesDefsIntersect(ud, needed)));
    if (!keep && !statefulWriteDependsOnNeeded) {
        return false;
    }
    keepIds.insert(stmt->id);
    mergeVarSets(needed, ud.uses);
    if (statefulWriteDependsOnNeeded) {
        // Important for stateful programs: writes that store seed-relevant values may only
        // matter across packet-processing iterations. Conservatively treat the written
        // stateful object itself as needed so we keep its other writes too.
        mergeVarSets(needed, ud.defs);
    }
    return true;
}

static bool varKeyIsPrefix(const VarKey& pref, const VarKey& full) {
    if (pref.base != full.base) {
        return false;
    }
    if (pref.segs.size() > full.segs.size()) {
        return false;
    }
    for (size_t i = 0; i < pref.segs.size(); ++i) {
        if (pref.segs[i] != full.segs[i]) {
            return false;
        }
    }
    return true;
}

std::string dotSafeName(const std::string& s);

void writeDotGraph(const std::string& path,
                   const std::unordered_map<int, NodeInfo>& nodes,
                   const std::unordered_map<int, std::vector<int>>& edges,
                   const std::unordered_set<int>* keep,
                   const char* graphName);

static std::unordered_map<int, std::vector<int>> buildDataPredsNoRecirc(
    const std::unordered_map<int, NodeInfo>& nodes) {
    std::unordered_map<int, std::vector<int>> dataPreds;
    std::map<VarKey, std::set<std::pair<int, VarKey>>, VarKeyLess> allDefs;
    for (const auto& kv : nodes) {
        for (const auto& v : kv.second.defs) {
            allDefs[v].insert({kv.first, v});
        }
    }
    std::unordered_map<int, std::set<std::pair<int, VarKey>>> in, out;
    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto& kv : nodes) {
            int id = kv.first;
            std::set<std::pair<int, VarKey>> inSet;
            for (int pred : kv.second.preds) {
                const auto& outSet = out[pred];
                inSet.insert(outSet.begin(), outSet.end());
            }
            std::set<std::pair<int, VarKey>> outSet = inSet;
            for (const auto& d : kv.second.defs) {
                auto defIt = allDefs.find(d);
                if (defIt != allDefs.end()) {
                    for (const auto& def : defIt->second) {
                        outSet.erase(def);
                    }
                }
            }
            for (const auto& d : kv.second.defs) {
                outSet.insert({id, d});
            }
            if (in[id] != inSet || out[id] != outSet) {
                in[id] = std::move(inSet);
                out[id] = std::move(outSet);
                changed = true;
            }
        }
    }
    for (const auto& kv : nodes) {
        int id = kv.first;
        const auto& node = kv.second;
        for (const auto& use : node.uses) {
            auto it = in.find(id);
            if (it == in.end()) {
                continue;
            }
            for (const auto& def : it->second) {
                if (def.second == use) {
                    dataPreds[id].push_back(def.first);
                }
            }
        }
    }
    return dataPreds;
}

class KeepVarCollector : public Inspector {
 public:
    const std::unordered_set<int>& keepStmtIds;
    std::set<VarKey, VarKeyLess> vars;
    P4::TypeMap* typeMap;

    KeepVarCollector(const std::unordered_set<int>& ids, P4::TypeMap* typeMap)
        : keepStmtIds(ids), typeMap(typeMap) {}

    bool preorder(const IR::Statement* stmt) override {
        if (!stmt) {
            return false;
        }
        if (!keepStmtIds.count(stmt->id)) {
            return false;
        }
        UsesDefs ud;
        collectStmtUsesDefs(stmt, ud, typeMap);
        for (const auto& v : ud.uses) {
            addVarKey(vars, v);
        }
        for (const auto& v : ud.defs) {
            addVarKey(vars, v);
        }
        return false;
    }
};

class AllVarCollector : public Inspector {
 public:
    std::set<VarKey, VarKeyLess> vars;
    P4::TypeMap* typeMap;

    explicit AllVarCollector(P4::TypeMap* typeMap) : typeMap(typeMap) {}

    bool preorder(const IR::Statement* stmt) override {
        if (!stmt) {
            return false;
        }
        UsesDefs ud;
        collectStmtUsesDefs(stmt, ud, typeMap);
        for (const auto& v : ud.uses) {
            addVarKey(vars, v);
        }
        for (const auto& v : ud.defs) {
            addVarKey(vars, v);
        }
        return false;
    }
};

class RegisterIndexCollector : public Inspector {
 public:
    const std::unordered_set<int>& keepStmtIds;
    std::map<std::string, int> maxIndex;
    std::set<std::string> hasNonConst;
    std::set<std::string> hasUnkeyedNonConst;
    std::map<std::string, std::set<std::string>> indexExprKeys;
    const std::set<std::string>* regNames;
    const std::unordered_map<cstring, cstring>* regActionRegs;
    P4::ReferenceMap* refMap;

    RegisterIndexCollector(const std::unordered_set<int>& ids,
                           const std::set<std::string>* regNames,
                           const std::unordered_map<cstring, cstring>* regActionRegs,
                           P4::ReferenceMap* refMap)
        : keepStmtIds(ids), regNames(regNames), regActionRegs(regActionRegs), refMap(refMap) {}

    bool preorder(const IR::Statement* stmt) override {
        if (!stmt) {
            return false;
        }
        if (stmt->is<IR::BlockStatement>() || stmt->is<IR::IfStatement>() ||
            stmt->is<IR::SwitchStatement>()) {
            return true;
        }
        if (!keepStmtIds.count(stmt->id)) {
            return false;
        }
        return true;
    }

	    bool preorder(const IR::MethodCallExpression* mce) override {
	        if (!mce || !mce->method) {
	            return false;
	        }
        auto member = mce->method->to<IR::Member>();
        if (!member) {
            return false;
        }
        auto base = member->expr->to<IR::PathExpression>();
        if (!base) {
            return false;
        }
        auto name = member->member.toString();
	        if (name != "read" && name != "write") {
            if (name != "execute") {
                return false;
            }
            if (!regActionRegs) {
                return false;
            }
            cstring actionName = resolvePathName(base, refMap);
            auto actionIt = regActionRegs->find(actionName);
            if (actionIt == regActionRegs->end()) {
                return false;
            }
            if (!mce->arguments || mce->arguments->empty()) {
                return false;
            }
            recordIndex(actionIt->second.c_str(), (*mce->arguments)[0]->expression);
            return false;
	        }
	        if (!mce->arguments || mce->arguments->empty()) {
	            return false;
	        }
        std::string regName = base->path->name.toString().c_str();
        if (regNames && !regNames->empty()) {
            std::string norm;
            if (regNames->count(regName)) {
                norm = regName;
            } else if (regNames->count(regName + "_0")) {
                norm = regName + "_0";
            }
            if (norm.empty()) {
                return false;
            }
	            regName = norm;
	        }
	        const IR::Expression* idxExpr = nullptr;
	        if (name == "write") {
	            idxExpr = (*mce->arguments)[0]->expression;
	        } else {
	            // P4_16 register signature: read(out value, index)
	            // P4_14/bmv2 register signature: read(index) returns value
	            if (mce->arguments->size() >= 2) {
	                idxExpr = (*mce->arguments)[1]->expression;
	            } else {
	                idxExpr = (*mce->arguments)[0]->expression;
	            }
	        }
	        if (!idxExpr) {
	            return false;
	        }
        recordIndex(regName, idxExpr);
        return false;
    }

 private:
    void recordIndex(std::string regName, const IR::Expression* idxExpr) {
        if (regName.empty() || !idxExpr) {
            return;
        }
        if (regNames && !regNames->empty()) {
            std::string norm;
            if (regNames->count(regName)) {
                norm = regName;
            } else if (regNames->count(regName + "_0")) {
                norm = regName + "_0";
            }
            if (norm.empty()) {
                return;
            }
            regName = norm;
        }
	        int idx = -1;
	        if (extractConstIndex(idxExpr, idx, refMap)) {
	            auto it = maxIndex.find(regName);
	            if (it == maxIndex.end() || idx > it->second) {
                maxIndex[regName] = idx;
            }
        } else {
            hasNonConst.insert(regName);
            std::string key;
            if (buildIndexExprKey(idxExpr, key)) {
                indexExprKeys[regName].insert(key);
            } else {
                hasUnkeyedNonConst.insert(regName);
            }
        }
    }

    static const IR::Expression* stripCasts(const IR::Expression* expr) {
        while (expr) {
            if (auto cast = expr->to<IR::Cast>()) {
                expr = cast->expr;
                continue;
            }
            break;
        }
        return expr;
    }

    static bool extractConstIndex(const IR::Expression* expr, int& out,
                                  P4::ReferenceMap* refMap) {
        expr = stripCasts(expr);
        if (!expr) {
            return false;
        }
        if (auto c = expr->to<IR::Constant>()) {
            if (c->value < 0) {
                return false;
            }
            if (c->value > std::numeric_limits<int>::max()) {
                return false;
            }
            out = static_cast<int>(c->value);
            return true;
        }
        if (auto pe = expr->to<IR::PathExpression>()) {
            if (refMap) {
                if (auto decl = refMap->getDeclaration(pe->path, true)) {
                    if (auto cdecl = decl->to<IR::Declaration_Constant>()) {
                        if (auto c = cdecl->initializer->to<IR::Constant>()) {
                            if (c->value < 0) {
                                return false;
                            }
                            if (c->value > std::numeric_limits<int>::max()) {
                                return false;
                            }
                            out = static_cast<int>(c->value);
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    static bool buildIndexExprKey(const IR::Expression* expr, std::string& out) {
        expr = stripCasts(expr);
        VarKey key;
        if (!buildVarKey(expr, key) || key.base.empty()) {
            return false;
        }
        out = varKeyToString(key);
        return !out.empty();
    }
};

class RegisterUseCollector : public Inspector {
 public:
    explicit RegisterUseCollector(P4::ReferenceMap* refMap) : refMap(refMap) {}

    P4::ReferenceMap* refMap;
    std::set<std::string> regs;

    bool preorder(const IR::MethodCallExpression* mce) override {
        if (!mce || !mce->method) {
            return false;
        }
        auto member = mce->method->to<IR::Member>();
        if (!member) {
            return false;
        }
        auto base = member->expr->to<IR::PathExpression>();
        if (!base) {
            return false;
        }
        auto name = member->member.toString();
        if (name != "read" && name != "write") {
            return false;
        }
        std::string regName;
        if (refMap && base->path) {
            if (auto decl = refMap->getDeclaration(base->path, false)) {
                regName = decl->getName().name.c_str();
            }
        }
        if (regName.empty()) {
            regName = base->path->name.toString().c_str();
        }
        regs.insert(regName);
        return false;
    }
};

class StatefulDeclCollector : public Inspector {
 public:
    std::set<std::string> objects;

    bool preorder(const IR::Declaration_Instance* inst) override {
        if (!inst || !inst->type) {
            return false;
        }
        std::string extName;
        if (!lookupExternName(inst->type, extName)) {
            return false;
        }
        std::string extLower;
        extLower.reserve(extName.size());
        for (char c : extName) {
            if (c >= 'A' && c <= 'Z') {
                extLower.push_back(static_cast<char>(c - 'A' + 'a'));
            } else {
                extLower.push_back(c);
            }
        }
        if (extLower.find("register") != std::string::npos ||
            extLower.find("counter") != std::string::npos ||
            extLower.find("meter") != std::string::npos) {
            objects.insert(inst->name.name.c_str());
        }
        return false;
    }

 private:
    static bool lookupExternName(const IR::Type* type, std::string& out) {
        if (!type) {
            return false;
        }
        if (auto ext = type->to<IR::Type_Extern>()) {
            out = ext->name.name.c_str();
            return true;
        }
        if (auto spec = type->to<IR::Type_Specialized>()) {
            return lookupExternName(spec->baseType, out);
        }
        if (auto name = type->to<IR::Type_Name>()) {
            if (name->path) {
                out = name->path->name.name.c_str();
                return true;
            }
        }
        return false;
    }
};

// Read/write analysis is deliberately conservative and string-based here.

class CFGBuilder {
 public:
    explicit CFGBuilder(P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
        : refMap(refMap), typeMap(typeMap) {}

    void build(const IR::P4Program* program) {
        // Build CFG fragments for all controls first.
        // We'll then connect fragments based on the pipeline "main" instance to
        // model cross-stage dataflow (e.g., Ingress writes -> Egress reads).
        std::unordered_map<std::string, CFGFragment> controlFrags;
        for (auto obj : program->objects) {
            if (auto control = obj->to<IR::P4Control>()) {
                CFGFragment frag = buildForStatement(control->body);
                if (frag.entry != -1) {
                    controlFrags.emplace(control->name.name.c_str(), frag);
                }
            }
        }

        const IR::Declaration_Instance* mainInst = nullptr;
        for (auto obj : program->objects) {
            if (auto inst = obj->to<IR::Declaration_Instance>()) {
                if (inst->name.name == "main") {
                    mainInst = inst;
                    break;
                }
            }
        }

        // If we can extract a sequential control order from the main instance,
        // connect the control fragments in that order and expose a single
        // root/exit pair that matches a full packet "pass".
        if (mainInst && refMap) {
            std::vector<const IR::P4Control*> order;
            std::unordered_set<const IR::Declaration_Instance*> visited;
            collectControlsFromInstance(mainInst, order, visited);
            int entry = -1;
            int exit = -1;
            int prevExit = -1;
            for (const auto* ctrl : order) {
                if (!ctrl) {
                    continue;
                }
                auto it = controlFrags.find(ctrl->name.name.c_str());
                if (it == controlFrags.end()) {
                    continue;
                }
                const CFGFragment& frag = it->second;
                if (frag.entry == -1 || frag.exit == -1) {
                    continue;
                }
                if (entry == -1) {
                    entry = frag.entry;
                }
                if (prevExit != -1) {
                    nodes[prevExit].succs.push_back(frag.entry);
                    nodes[frag.entry].preds.push_back(prevExit);
                }
                prevExit = frag.exit;
                exit = frag.exit;
            }
            if (entry != -1 && exit != -1) {
                roots.push_back(entry);
                exits.push_back(exit);
                return;
            }
        }

        // Fallback: treat each control as its own root/exit fragment (legacy).
        // This is less precise for multi-stage programs, but preserves behavior
        // for IRs where we cannot identify the pipeline structure.
        for (const auto& kv : controlFrags) {
            const CFGFragment& frag = kv.second;
            roots.push_back(frag.entry);
            exits.push_back(frag.exit);
        }
    }

    CFGFragment buildStatement(const IR::Statement* stmt) {
        return buildForStatement(stmt);
    }

    std::unordered_map<int, NodeInfo> nodes;
    std::vector<int> roots;
    std::vector<int> exits;

 private:
    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
    int nextId = 1;

    static bool lookupTypeName(const IR::Type* type, std::string& out) {
        if (!type) {
            return false;
        }
        if (auto name = type->to<IR::Type_Name>()) {
            if (name->path) {
                out = name->path->name.name.c_str();
                return true;
            }
        }
        if (auto spec = type->to<IR::Type_Specialized>()) {
            return lookupTypeName(spec->baseType, out);
        }
        return false;
    }

    void collectControlsFromExpr(const IR::Expression* expr,
                                 std::vector<const IR::P4Control*>& out,
                                 std::unordered_set<const IR::Declaration_Instance*>& visited) {
        if (!expr || !refMap) {
            return;
        }
        if (auto cce = expr->to<IR::ConstructorCallExpression>()) {
            const IR::Type* ctorType = cce->constructedType;
            if (auto tname = ctorType ? ctorType->to<IR::Type_Name>() : nullptr) {
                if (tname->path) {
                    if (auto decl = refMap->getDeclaration(tname->path, true)) {
                        if (auto ctrl = decl->to<IR::P4Control>()) {
                            out.push_back(ctrl);
                            return;
                        }
                        if (auto inst = decl->to<IR::Declaration_Instance>()) {
                            collectControlsFromInstance(inst, out, visited);
                            return;
                        }
                    }
                }
            }
            return;
        }
        if (auto pe = expr->to<IR::PathExpression>()) {
            if (auto decl = refMap->getDeclaration(pe->path, true)) {
                if (auto ctrl = decl->to<IR::P4Control>()) {
                    out.push_back(ctrl);
                    return;
                }
                if (auto inst = decl->to<IR::Declaration_Instance>()) {
                    collectControlsFromInstance(inst, out, visited);
                    return;
                }
            }
        }
    }

    void collectControlsFromInstance(const IR::Declaration_Instance* inst,
                                     std::vector<const IR::P4Control*>& out,
                                     std::unordered_set<const IR::Declaration_Instance*>& visited) {
        if (!inst || !inst->arguments || !refMap) {
            return;
        }
        if (visited.count(inst)) {
            return;
        }
        visited.insert(inst);

        std::string typeName;
        if (!lookupTypeName(inst->type, typeName)) {
            return;
        }

        // Mirror the translator's sequential composition for common architectures.
        // We only need a conservative order here to propagate defs/uses across stages.
        const bool isV1Switch = typeName == "V1Switch";
        const bool isSwitch = typeName == "Switch";
        const bool isPipeline = typeName == "Pipeline";
        if (!(isV1Switch || isSwitch || isPipeline)) {
            return;
        }

        const int argc = static_cast<int>(inst->arguments->size());
        int limit = argc;
        // In the Boogie translator, V1Switch treats the last argument as the
        // deparser and does not call it. Keep the same order here.
        if (isV1Switch && argc > 0) {
            limit = argc - 1;
        }

        int idx = 0;
        for (auto arg : *inst->arguments) {
            if (idx >= limit) {
                break;
            }
            if (!arg) {
                idx++;
                continue;
            }
            collectControlsFromExpr(arg->expression, out, visited);
            idx++;
        }
    }

    int newNode(const IR::Statement* stmt) {
        int id = nextId++;
        NodeInfo info;
        info.stmt = stmt;
        nodes.emplace(id, info);
        return id;
    }

    CFGFragment buildForStatement(const IR::Statement* stmt) {
        CFGFragment frag;
        if (auto block = stmt->to<IR::BlockStatement>()) {
            CFGFragment chain;
            for (auto comp : block->components) {
                auto compStmt = comp->to<IR::Statement>();
                if (!compStmt) {
                    continue;
                }
                auto part = buildForStatement(compStmt);
                if (part.entry == -1) {
                    continue;
                }
                if (chain.entry == -1) {
                    chain.entry = part.entry;
                } else {
                    nodes[chain.exit].succs.push_back(part.entry);
                    nodes[part.entry].preds.push_back(chain.exit);
                }
                chain.exit = part.exit;
                chain.nodes.insert(chain.nodes.end(), part.nodes.begin(), part.nodes.end());
            }
            frag = chain;
            return frag;
        }
        if (auto ifs = stmt->to<IR::IfStatement>()) {
            int condId = newNode(stmt);
            CFGFragment tfrag = buildForStatement(ifs->ifTrue);
            CFGFragment ffrag;
            if (ifs->ifFalse) {
                ffrag = buildForStatement(ifs->ifFalse);
            }
            if (tfrag.entry != -1) {
                nodes[condId].succs.push_back(tfrag.entry);
                nodes[tfrag.entry].preds.push_back(condId);
            }
            if (ffrag.entry != -1) {
                nodes[condId].succs.push_back(ffrag.entry);
                nodes[ffrag.entry].preds.push_back(condId);
            }
            int mergeId = newNode(nullptr);
            if (tfrag.exit != -1) {
                nodes[tfrag.exit].succs.push_back(mergeId);
                nodes[mergeId].preds.push_back(tfrag.exit);
            }
            if (ffrag.exit != -1) {
                nodes[ffrag.exit].succs.push_back(mergeId);
                nodes[mergeId].preds.push_back(ffrag.exit);
            }
            if (tfrag.entry != -1) {
                for (int n : tfrag.nodes) {
                    nodes[condId].ctrlSuccs.push_back(n);
                    nodes[n].ctrlPreds.push_back(condId);
                }
            }
            if (ffrag.entry != -1) {
                for (int n : ffrag.nodes) {
                    nodes[condId].ctrlSuccs.push_back(n);
                    nodes[n].ctrlPreds.push_back(condId);
                }
            }
            frag.entry = condId;
            frag.exit = mergeId;
            frag.nodes.push_back(condId);
            frag.nodes.insert(frag.nodes.end(), tfrag.nodes.begin(), tfrag.nodes.end());
            frag.nodes.insert(frag.nodes.end(), ffrag.nodes.begin(), ffrag.nodes.end());
            frag.nodes.push_back(mergeId);
            return frag;
        }
        if (auto sw = stmt->to<IR::SwitchStatement>()) {
            int condId = newNode(stmt);
            int mergeId = newNode(nullptr);
            for (auto c : sw->cases) {
                if (!c->statement) {
                    continue;
                }
                CFGFragment cfrag = buildForStatement(c->statement);
                if (cfrag.entry == -1) {
                    continue;
                }
                nodes[condId].succs.push_back(cfrag.entry);
                nodes[cfrag.entry].preds.push_back(condId);
                nodes[cfrag.exit].succs.push_back(mergeId);
                nodes[mergeId].preds.push_back(cfrag.exit);
                for (int n : cfrag.nodes) {
                    nodes[condId].ctrlSuccs.push_back(n);
                    nodes[n].ctrlPreds.push_back(condId);
                }
                frag.nodes.insert(frag.nodes.end(), cfrag.nodes.begin(), cfrag.nodes.end());
            }
            frag.entry = condId;
            frag.exit = mergeId;
            frag.nodes.push_back(condId);
            frag.nodes.push_back(mergeId);
            return frag;
        }
        if (stmt->is<IR::EmptyStatement>()) {
            frag.entry = -1;
            frag.exit = -1;
            return frag;
        }
        int id = newNode(stmt);
        frag.entry = id;
        frag.exit = id;
        frag.nodes.push_back(id);
        return frag;
    }
};

static bool extractSeedIndex(const std::string& seed, std::string& base, int& idx) {
    auto lbr = seed.find('[');
    auto rbr = seed.find(']');
    if (lbr == std::string::npos || rbr == std::string::npos || rbr <= lbr + 1) {
        return false;
    }
    base = seed.substr(0, lbr);
    std::string inside = seed.substr(lbr + 1, rbr - lbr - 1);
    auto bv = inside.find("bv");
    std::string num = (bv == std::string::npos) ? inside : inside.substr(0, bv);
    if (num.empty()) {
        return false;
    }
    for (char c : num) {
        if (c < '0' || c > '9') {
            return false;
        }
    }
    try {
        idx = std::stoi(num);
    } catch (...) {
        return false;
    }
    return idx >= 0;
}

static bool parseVarKeyFromString(const std::string& name, VarKey& out) {
    if (name.empty()) {
        return false;
    }
    std::vector<std::string> segs;
    std::string cur;
    for (size_t i = 0; i < name.size(); ++i) {
        char c = name[i];
        if (c == '.') {
            if (!cur.empty()) {
                segs.push_back(cur);
                cur.clear();
            }
            continue;
        }
        if (c == '[') {
            if (!cur.empty()) {
                segs.push_back(cur);
                cur.clear();
            }
            std::string idx;
            size_t j = i + 1;
            while (j < name.size() && name[j] != ']') {
                idx.push_back(name[j]);
                ++j;
            }
            if (!idx.empty()) {
                segs.push_back(idx);
            }
            i = j;
            continue;
        }
        cur.push_back(c);
    }
    if (!cur.empty()) {
        segs.push_back(cur);
    }
    if (segs.empty()) {
        return false;
    }
    out.base = segs[0];
    out.segs.assign(segs.begin() + 1, segs.end());
    return true;
}

static std::set<VarKey, VarKeyLess> normalizeSeeds(const std::vector<cstring>& seeds,
                                                   const std::set<std::string>* regDecls,
                                                   const std::unordered_map<std::string, std::string>* regControlMap) {
    auto normalizeRegSeedBase = [&](const std::string& base) -> std::string {
        if (!regDecls || regDecls->empty()) {
            return base;
        }
        if (regDecls->count(base)) {
            return base;
        }
        if (regControlMap) {
            auto it = regControlMap->find(base);
            if (it != regControlMap->end() && !it->second.empty() && regDecls->count(it->second)) {
                return it->second;
            }
            if (base.size() > 2 && base.rfind("_0") == base.size() - 2) {
                std::string stripped = base.substr(0, base.size() - 2);
                it = regControlMap->find(stripped);
                if (it != regControlMap->end() && !it->second.empty() && regDecls->count(it->second)) {
                    return it->second;
                }
            }
        }
        if (base.size() > 2 && base.rfind("_0") == base.size() - 2) {
            std::string stripped = base.substr(0, base.size() - 2);
            if (regDecls->count(stripped)) {
                return stripped;
            }
        }
        // Best-effort: allow unqualified control-plane names (e.g., `latest_reg`) to match
        // compiler-renamed register declarations (e.g., `netcacheEgress_latest_reg`).
        {
            const std::string suffix = "_" + base;
            std::string match;
            for (const auto& r : *regDecls) {
                if (r.size() > suffix.size() && r.rfind(suffix) == r.size() - suffix.size()) {
                    if (!match.empty()) {
                        // Ambiguous suffix match: keep the original base.
                        match.clear();
                        break;
                    }
                    match = r;
                }
            }
            if (!match.empty()) {
                return match;
            }
        }
        std::string withSuffix = base + "_0";
        if (regDecls->count(withSuffix)) {
            return withSuffix;
        }
        return base;
    };
    std::set<VarKey, VarKeyLess> out;
    for (auto s : seeds) {
        VarKey key;
        if (parseVarKeyFromString(s.c_str(), key)) {
            key.base = normalizeRegSeedBase(key.base);
            addSeedVarKey(out, key);
            if (key.base.size() > 2 && key.base.rfind("_0") == key.base.size() - 2) {
                VarKey alias = key;
                alias.base = key.base.substr(0, key.base.size() - 2);
                addSeedVarKey(out, alias);
            } else if (regDecls) {
                std::string withSuffix = key.base + "_0";
                if (regDecls->count(withSuffix)) {
                    VarKey alias = key;
                    alias.base = withSuffix;
                    addSeedVarKey(out, alias);
                }
            }
        }
    }
    return out;
}

class ActionTableCollector : public Inspector {
 public:
    std::unordered_map<cstring, const IR::P4Action*> actions;
    std::unordered_map<cstring, const IR::P4Table*> tables;
    std::unordered_map<cstring, const IR::Declaration_Instance*> regActions;

    bool preorder(const IR::P4Action* a) override {
        actions.emplace(a->name.name, a);
        return false;
    }

    bool preorder(const IR::P4Table* t) override {
        tables.emplace(t->name.name, t);
        return false;
    }

    bool preorder(const IR::Declaration_Instance* inst) override {
        if (!inst || !inst->type) {
            return false;
        }
        auto typeSpec = inst->type->to<IR::Type_Specialized>();
        if (!typeSpec || !typeSpec->baseType) {
            return false;
        }
        std::string baseName = typeSpec->baseType->toString().c_str();
        if (baseName.find("RegisterAction") == std::string::npos &&
            baseName.find("DirectRegisterAction") == std::string::npos) {
            return false;
        }
        regActions.emplace(inst->name.name, inst);
        return false;
    }
};

}  // namespace slicing_internal

}  // namespace P4Verify

#endif  // BACKENDS_VERIFY_SLICING_SLICER_INTERNAL_H_
