// Semantic-aware slicing for P4 IR.
#include "slicer.h"

#include <algorithm>
#include <cctype>
#include <fstream>
#include <limits>
#include <sys/stat.h>

#include "backends/verify/translate/bmv2.h"
#include "backends/verify/translate/utils.h"
#include "ir/ir.h"
#include "ir/visitor.h"
#include "lib/cstring.h"
#include "lib/log.h"
#include "lib/stringify.h"

namespace P4Verify {

namespace {

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
    if (type->is<IR::Type_Header>() || type->is<IR::Type_Stack>()) {
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

static bool regActionCallName(const IR::MethodCallExpression* mce, cstring& outName) {
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
    outName = base->path->name;
    return true;
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
                auto stack = t ? t->to<IR::Type_Stack>() : nullptr;
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
                auto stack = t ? t->to<IR::Type_Stack>() : nullptr;
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
    auto stack = recvType ? recvType->to<IR::Type_Stack>() : nullptr;
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
                                const std::unordered_map<cstring, UsesDefs>* regActionUsesDefs = nullptr) {
    if (!stmt) {
        return;
    }
    if (auto block = stmt->to<IR::BlockStatement>()) {
        for (auto comp : block->components) {
            if (auto compStmt = comp->to<IR::Statement>()) {
                collectStmtUsesDefs(compStmt, out, typeMap, regActionUsesDefs);
            }
        }
        return;
    }
    if (auto as = stmt->to<IR::AssignmentStatement>()) {
        collectExprKeys(as->left, out.defs, typeMap);
        collectExprKeys(as->right, out.uses, typeMap);
        collectExprKeys(as->left, out.uses, typeMap);
        if (regActionUsesDefs) {
            if (auto mce = as->right->to<IR::MethodCallExpression>()) {
                cstring name;
                if (regActionCallName(mce, name)) {
                    auto it = regActionUsesDefs->find(name);
                    if (it != regActionUsesDefs->end()) {
                        mergeSets(out.uses, it->second.uses);
                        mergeSets(out.defs, it->second.defs);
                    }
                }
            }
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
                        auto it = regActionUsesDefs->find(base->path->name);
                        if (it != regActionUsesDefs->end()) {
                            mergeSets(out.uses, it->second.uses);
                            mergeSets(out.defs, it->second.defs);
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
        collectStmtUsesDefs(ifs->ifTrue, out, typeMap, regActionUsesDefs);
        collectStmtUsesDefs(ifs->ifFalse, out, typeMap, regActionUsesDefs);
        return;
    }
    if (auto sw = stmt->to<IR::SwitchStatement>()) {
        collectExprKeys(sw->expression, out.uses, typeMap);
        for (auto c : sw->cases) {
            if (c && c->statement) {
                collectStmtUsesDefs(c->statement, out, typeMap, regActionUsesDefs);
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

static void fillNodeUsesDefs(NodeInfo& node,
                             P4::TypeMap* typeMap,
                             const std::unordered_map<cstring, UsesDefs>& tableUsesDefs,
                             const std::unordered_map<cstring, UsesDefs>& actionUsesDefs,
                             const std::unordered_map<cstring, UsesDefs>& regActionUsesDefs,
                             bool* hasRecirculation,
                             bool debug,
                             const std::unordered_map<std::string, std::vector<VarKey>>* extractSeedFields = nullptr,
                             const std::set<VarKey, VarKeyLess>* seedVars = nullptr) {
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
        collectExprKeys(as->left, node.uses, typeMap);
        if (auto mce = as->right->to<IR::MethodCallExpression>()) {
            cstring name;
            if (regActionCallName(mce, name)) {
                auto it = regActionUsesDefs.find(name);
                if (it != regActionUsesDefs.end()) {
                    mergeSets(node.uses, it->second.uses);
                    mergeSets(node.defs, it->second.defs);
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
                        auto it = tableUsesDefs.find(base->path->name);
                        if (it != tableUsesDefs.end()) {
                            mergeSets(node.uses, it->second.uses);
                            mergeSets(node.defs, it->second.defs);
                            handled = true;
                        } else {
                            auto rit = regActionUsesDefs.find(base->path->name);
                            if (rit != regActionUsesDefs.end()) {
                                mergeSets(node.uses, rit->second.uses);
                                mergeSets(node.defs, rit->second.defs);
                                handled = true;
                            }
                        }
                    }
                }
            } else if (auto pe = expr->method->to<IR::PathExpression>()) {
                methodName = pe->path->name.name.c_str();
                auto it = actionUsesDefs.find(pe->path->name);
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
            if (hasRecirculation &&
                (lower.find("recirc") != std::string::npos ||
                 lower.find("resubmit") != std::string::npos ||
                 lower.find("mirror") != std::string::npos ||
                 lower.find("clone") != std::string::npos)) {
                *hasRecirculation = true;
            }
            // Preserve the semantic effect of clone/recirc/resubmit for slicing.
            //
            // These externs do not necessarily read/write any seed-relevant P4 state directly,
            // but they *do* change the control/communication behavior of the program. We model
            // them as writes to the synthetic control flags that the Boogie backend relies on
            // (`p4b_*`). This allows `--slicing-vars` / control-seed selection to keep the
            // relevant calls and their control dependencies.
            if (lower.find("recirc") != std::string::npos || lower.find("resubmit") != std::string::npos) {
                VarKey key;
                key.base = "p4b_recirculate";
                addVarKey(node.defs, key);
            }
            if (lower.find("mirror") != std::string::npos || lower.find("clone") != std::string::npos) {
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
        return;
    }
    if (auto sw = node.stmt->to<IR::SwitchStatement>()) {
        if (debug) {
            std::cerr << "[slicer]  switch expression\n";
        }
        collectExprKeys(sw->expression, node.uses, typeMap);
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
                            const std::unordered_map<cstring, UsesDefs>* regActionUsesDefs) {
    if (!stmt) {
        return false;
    }
    if (auto block = stmt->to<IR::BlockStatement>()) {
        bool anyKept = false;
        for (auto it = block->components.rbegin(); it != block->components.rend(); ++it) {
            if (auto compStmt = (*it)->to<IR::Statement>()) {
                anyKept = sliceActionStmt(compStmt, needed, keepIds, typeMap, regActionUsesDefs) || anyKept;
            }
        }
        return anyKept;
    }
    if (auto ifs = stmt->to<IR::IfStatement>()) {
        std::set<VarKey, VarKeyLess> neededTrue = needed;
        std::set<VarKey, VarKeyLess> neededFalse = needed;
        std::unordered_set<int> keepTrue;
        std::unordered_set<int> keepFalse;
        bool keepT = sliceActionStmt(ifs->ifTrue, neededTrue, keepTrue, typeMap, regActionUsesDefs);
        bool keepF = sliceActionStmt(ifs->ifFalse, neededFalse, keepFalse, typeMap, regActionUsesDefs);
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
            bool caseKept = sliceActionStmt(c->statement, caseNeeded, caseKeep, typeMap, regActionUsesDefs);
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
    collectStmtUsesDefs(stmt, ud, typeMap, regActionUsesDefs);
    if (!usesDefsIntersect(ud, needed)) {
        return false;
    }
    keepIds.insert(stmt->id);
    mergeVarSets(needed, ud.uses);
    return true;
}

static std::string dotEscape(const std::string& s) {
    std::string out;
    out.reserve(s.size());
    for (char c : s) {
        if (c == '"') {
            out += "\\\"";
            continue;
        }
        if (c == '\n' || c == '\r') {
            out += "\\n";
            continue;
        }
        out.push_back(c);
    }
    return out;
}

static std::string dotSafeName(const std::string& s) {
    std::string out;
    out.reserve(s.size());
    for (unsigned char c : s) {
        if (std::isalnum(c) || c == '_' || c == '-') {
            out.push_back(static_cast<char>(c));
        } else {
            out.push_back('_');
        }
    }
    if (out.empty()) {
        return "anon";
    }
    return out;
}

static std::string joinParts(const std::vector<std::string>& parts, const std::string& sep) {
    if (parts.empty()) {
        return "";
    }
    std::string out = parts[0];
    for (size_t i = 1; i < parts.size(); ++i) {
        out += sep;
        out += parts[i];
    }
    return out;
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

static std::string exprLabel(const IR::Expression* expr) {
    if (!expr) {
        return "";
    }
    if (auto pe = expr->to<IR::PathExpression>()) {
        return pe->path ? pe->path->name.toString().c_str() : "";
    }
    if (auto member = expr->to<IR::Member>()) {
        std::string base = exprLabel(member->expr);
        if (base.empty()) {
            return member->member.toString().c_str();
        }
        return base + "." + member->member.toString().c_str();
    }
    if (auto c = expr->to<IR::Constant>()) {
        unsigned width = 0;
        bool isSigned = false;
        if (auto bits = c->type->to<IR::Type_Bits>()) {
            width = bits->width_bits();
            isSigned = bits->isSigned;
        }
        return Util::toString(c->value, width, isSigned).c_str();
    }
    if (auto b = expr->to<IR::BoolLiteral>()) {
        return b->value ? "true" : "false";
    }
    if (auto s = expr->to<IR::StringLiteral>()) {
        return "\"" + std::string(s->value.c_str()) + "\"";
    }
    if (auto aidx = expr->to<IR::ArrayIndex>()) {
        return exprLabel(aidx->left) + "[" + exprLabel(aidx->right) + "]";
    }
    if (auto slice = expr->to<IR::Slice>()) {
        return exprLabel(slice->e0) + "[" + exprLabel(slice->e1) + ":" + exprLabel(slice->e2) + "]";
    }
    if (auto cast = expr->to<IR::Cast>()) {
        std::string ty = cast->type ? cast->type->toString().c_str() : "";
        return "(" + ty + ")" + exprLabel(cast->expr);
    }
    if (auto mux = expr->to<IR::Mux>()) {
        return exprLabel(mux->e0) + " ? " + exprLabel(mux->e1) + " : " + exprLabel(mux->e2);
    }
    if (auto un = expr->to<IR::Operation_Unary>()) {
        return std::string(un->getStringOp().c_str()) + exprLabel(un->expr);
    }
    if (auto bin = expr->to<IR::Operation_Binary>()) {
        return exprLabel(bin->left) + " " + bin->getStringOp().c_str() + " " + exprLabel(bin->right);
    }
    if (auto ter = expr->to<IR::Operation_Ternary>()) {
        std::string op = ter->getStringOp().c_str();
        return op + "(" + exprLabel(ter->e0) + ", " + exprLabel(ter->e1) + ", " +
               exprLabel(ter->e2) + ")";
    }
    if (auto concat = expr->to<IR::Concat>()) {
        return exprLabel(concat->left) + " ++ " + exprLabel(concat->right);
    }
    if (auto list = expr->to<IR::ListExpression>()) {
        std::vector<std::string> items;
        for (auto comp : list->components) {
            if (auto e = comp->to<IR::Expression>()) {
                items.push_back(exprLabel(e));
            }
        }
        return "{" + joinParts(items, ", ") + "}";
    }
    if (auto mc = expr->to<IR::MethodCallExpression>()) {
        std::string method = exprLabel(mc->method);
        std::vector<std::string> args;
        if (mc->arguments) {
            for (auto arg : *mc->arguments) {
                if (arg && arg->expression) {
                    args.push_back(exprLabel(arg->expression));
                }
            }
        }
        return method + "(" + joinParts(args, ", ") + ")";
    }
    return expr->node_type_name().c_str();
}

static std::string stmtLabel(const IR::Statement* stmt) {
    if (!stmt) {
        return "null";
    }
    std::string label;
    if (auto as = stmt->to<IR::AssignmentStatement>()) {
        std::string lhs = exprLabel(as->left);
        std::string rhs = exprLabel(as->right);
        label = "assign " + lhs + " := " + rhs;
    } else if (auto mcs = stmt->to<IR::MethodCallStatement>()) {
        if (mcs->methodCall) {
            label = "call " + exprLabel(mcs->methodCall);
        } else {
            label = "call";
        }
    } else if (auto ifs = stmt->to<IR::IfStatement>()) {
        std::string cond = exprLabel(ifs->condition);
        label = "if (" + cond + ")";
    } else if (auto sw = stmt->to<IR::SwitchStatement>()) {
        std::string expr = exprLabel(sw->expression);
        label = "switch (" + expr + ")";
    } else {
        label = stmt->node_type_name().c_str();
        std::string detail = stmt->toString().c_str();
        if (!detail.empty()) {
            label += " ";
            label += detail;
        }
    }
    return dotEscape(label);
}

static void writeDotGraph(const std::string& path,
                          const std::unordered_map<int, NodeInfo>& nodes,
                          const std::unordered_map<int, std::vector<int>>& edges,
                          const std::unordered_set<int>* keep,
                          const char* graphName) {
    std::ofstream out(path);
    if (!out.good()) {
        std::cerr << "[slicer] failed to write dot: " << path << "\n";
        return;
    }
    out << "digraph " << graphName << " {\n";
    for (const auto& kv : nodes) {
        int id = kv.first;
        if (keep && !keep->count(id)) {
            continue;
        }
        const auto& node = kv.second;
        out << "  n" << id << " [label=\""
            << id << ": " << stmtLabel(node.stmt) << "\"];\n";
    }
    for (const auto& kv : edges) {
        int dst = kv.first;
        if (keep && !keep->count(dst)) {
            continue;
        }
        for (int src : kv.second) {
            if (keep && !keep->count(src)) {
                continue;
            }
            out << "  n" << src << " -> n" << dst << ";\n";
        }
    }
    out << "}\n";
}

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
    const std::set<std::string>* regNames;
    P4::ReferenceMap* refMap;

    RegisterIndexCollector(const std::unordered_set<int>& ids,
                           const std::set<std::string>* regNames,
                           P4::ReferenceMap* refMap)
        : keepStmtIds(ids), regNames(regNames), refMap(refMap) {}

    bool preorder(const IR::Statement* stmt) override {
        if (!stmt) {
            return false;
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
	        int idx = -1;
	        if (extractConstIndex(idxExpr, idx, refMap)) {
	            auto it = maxIndex.find(regName);
	            if (it == maxIndex.end() || idx > it->second) {
                maxIndex[regName] = idx;
            }
        } else {
            hasNonConst.insert(regName);
        }
        return false;
    }

 private:
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

class RegisterDeclCollector : public Inspector {
 public:
    std::set<std::string> regs;
    // Map from sanitized control-plane name (Boogie-level) to IR instance name.
    // Empty value means ambiguous (multiple instances share the same sanitized name).
    std::unordered_map<std::string, std::string> controlToInternal;
    // Inverse map: IR instance name -> sanitized control-plane name.
    std::unordered_map<std::string, std::string> internalToControl;

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
        if (extLower.find("register") != std::string::npos) {
            std::string internal = inst->name.name.c_str();
            regs.insert(internal);

            cstring cp = inst->controlPlaneName();
            if (!cp.isNullOrEmpty()) {
                std::string sanitized = sanitizeDeclName(cp.c_str());
                if (!sanitized.empty()) {
                    auto it = controlToInternal.find(sanitized);
                    if (it == controlToInternal.end()) {
                        controlToInternal.emplace(sanitized, internal);
                        internalToControl.emplace(internal, sanitized);
                    } else if (it->second != internal) {
                        // Ambiguous: keep no mapping.
                        if (!it->second.empty()) {
                            internalToControl.erase(it->second);
                        }
                        it->second.clear();
                    }
                }
            }
        }
        return false;
    }

 private:
    static std::string sanitizeDeclName(const std::string& raw) {
        std::string out;
        out.reserve(raw.size());
        for (char c : raw) {
            if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                (c >= '0' && c <= '9') || c == '_') {
                out.push_back(c);
            } else {
                out.push_back('_');
            }
        }
        if (!out.empty() && out[0] >= '0' && out[0] <= '9') {
            out.insert(out.begin(), '_');
        }
        return out;
    }

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
            int mergeId = newNode(stmt);
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
            int mergeId = newNode(stmt);
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

}  // namespace

Slicer::Slicer(const IR::P4Program* program, P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
    : program(program), refMap(refMap), typeMap(typeMap) {
    CHECK_NULL(program);
    CHECK_NULL(refMap);
    CHECK_NULL(typeMap);
}

SliceResult Slicer::run(const SliceOptions& opts) {
    SliceResult result;
    std::vector<cstring> seedInputs = opts.seedVars;
    if (opts.bmv2Analyzer) {
        for (const auto* rw : opts.bmv2Analyzer->getRegisterWriteCmds()) {
            if (!rw) {
                continue;
            }
            if (rw->reg != nullptr && rw->reg != "") {
                seedInputs.push_back(rw->reg);
            }
            if (rw->control != nullptr && rw->control != "" && rw->reg != nullptr && rw->reg != "") {
                std::string qualified = rw->control.c_str();
                qualified += "_";
                qualified += rw->reg.c_str();
                seedInputs.push_back(cstring(qualified.c_str()));
            }
        }
    }
    bool doSlicing = opts.enable && !seedInputs.empty();
    if (!doSlicing && !opts.collectRw) {
        return result;
    }

    if (opts.debug) {
        std::cerr << "[slicer] start\n";
    }

    ActionTableCollector collector;
    program->apply(collector);
    std::unordered_map<cstring, UsesDefs> actionUsesDefs;
    std::unordered_map<cstring, UsesDefs> tableUsesDefs;
    std::unordered_map<cstring, std::unordered_set<int>> actionStmtIds;
    std::unordered_map<cstring, UsesDefs> regActionUsesDefs;
    std::unordered_map<cstring, std::unordered_set<int>> regActionStmtIds;
    for (const auto& kv : collector.regActions) {
        const IR::Declaration_Instance* inst = kv.second;
        const IR::Function* applyFunc = findRegisterActionApply(inst);
        if (!applyFunc || !applyFunc->body) {
            continue;
        }
        UsesDefs ud;
        collectStmtUsesDefs(applyFunc->body, ud, typeMap);
        regActionUsesDefs.emplace(kv.first, std::move(ud));
        std::unordered_set<int> ids;
        collectStmtIds(applyFunc->body, ids);
        regActionStmtIds.emplace(kv.first, std::move(ids));
    }
    for (const auto& kv : collector.actions) {
        UsesDefs ud;
        collectStmtUsesDefs(kv.second->body, ud, typeMap, &regActionUsesDefs);
        actionUsesDefs.emplace(kv.first, std::move(ud));
        std::unordered_set<int> ids;
        collectStmtIds(kv.second->body, ids);
        actionStmtIds.emplace(kv.first, std::move(ids));
    }

    // Control-plane-aware table slicing: if we have bmv2 commands, restrict action choices for
    // tables that have explicit rules/defaults. This helps avoid slicing blowups caused by
    // conservatively treating all table actions and match keys as relevant.
    struct TableCpInfo {
        bool fixedDefault = false;  // fixed by table_set_default with no table_add rules
        bool hasRules = false;
        std::set<cstring> allowedActions;  // rules + (explicit default) + (P4 default fallback when needed)
    };
    std::unordered_map<cstring, TableCpInfo> tableCp;
    if (opts.bmv2Analyzer) {
        auto p4DefaultActionName = [](const IR::Expression* defAct) -> cstring {
            if (!defAct) {
                return nullptr;
            }
            if (auto pe = defAct->to<IR::PathExpression>()) {
                return pe->path->name;
            }
            if (auto mce = defAct->to<IR::MethodCallExpression>()) {
                if (auto m = mce->method->to<IR::PathExpression>()) {
                    return m->path->name;
                }
            }
            return nullptr;
        };
        for (const auto& kv : collector.tables) {
            const IR::P4Table* table = kv.second;
            if (!table) {
                continue;
            }
            TableCpInfo info;
            info.hasRules = opts.bmv2Analyzer->hasTableAddCmds(kv.first);
            TableSetDefault* defCmd = opts.bmv2Analyzer->getTableSetDefaultCmd(kv.first);
            if (defCmd != nullptr) {
                info.allowedActions.insert(defCmd->action);
                if (!info.hasRules) {
                    info.fixedDefault = true;
                }
            }
            if (info.hasRules) {
                for (auto rule : opts.bmv2Analyzer->getTableAddCmds(kv.first)) {
                    if (rule) {
                        info.allowedActions.insert(rule->action);
                    }
                }
                // If there are rules but no explicit default, bmv2 falls back to the P4 default action.
                if (defCmd == nullptr) {
                    if (auto p4def = p4DefaultActionName(table->getDefaultAction())) {
                        info.allowedActions.insert(p4def);
                    }
                }
            }
            tableCp.emplace(kv.first, std::move(info));
        }
    }

    auto actionAllowed = [&](cstring tableName, cstring actionName) -> bool {
        if (!opts.bmv2Analyzer) {
            return true;
        }
        auto it = tableCp.find(tableName);
        if (it == tableCp.end() || it->second.allowedActions.empty()) {
            return true;
        }
        for (const auto& allowed : it->second.allowedActions) {
            if (isSame(actionName, allowed)) {
                return true;
            }
        }
        return false;
    };
    auto buildTableUsesDefs =
        [&](const std::unordered_map<cstring, UsesDefs>& currentActionUsesDefs)
        -> std::unordered_map<cstring, UsesDefs> {
        std::unordered_map<cstring, UsesDefs> out;
        for (const auto& kv : collector.tables) {
            const IR::P4Table* table = kv.second;
            UsesDefs ud;
            bool fixedDefault = false;
            if (opts.bmv2Analyzer) {
                auto it = tableCp.find(kv.first);
                if (it != tableCp.end()) {
                    fixedDefault = it->second.fixedDefault;
                }
            }
            if (!fixedDefault) {
                // Table action selection is modeled via action_run.
                VarKey actionRun;
                actionRun.base = kv.first.c_str();
                actionRun.segs.push_back("action_run");
                addVarKey(ud.defs, actionRun);
                if (auto key = table->getKey()) {
                    for (auto ke : key->keyElements) {
                        if (ke && ke->expression) {
                            collectExprKeys(ke->expression, ud.uses, typeMap);
                        }
                    }
                }
            }
            if (auto al = table->getActionList()) {
                for (auto a : al->actionList) {
                    if (!a) {
                        continue;
                    }
                    auto path = a->getPath();
                    if (!path) {
                        continue;
                    }
                    if (!actionAllowed(kv.first, path->name)) {
                        continue;
                    }
                    auto it = currentActionUsesDefs.find(path->name);
                    if (it != currentActionUsesDefs.end()) {
                        mergeSets(ud.uses, it->second.uses);
                        mergeSets(ud.defs, it->second.defs);
                    }
                }
            }
            if (auto defAct = table->getDefaultAction()) {
                if (auto pe = defAct->to<IR::PathExpression>()) {
                    if (!actionAllowed(kv.first, pe->path->name)) {
                        // For rule-based tables without explicit defaults, we add P4's default to allowedActions above.
                        // Otherwise, treat non-allowed defaults as irrelevant for the configured control plane.
                        goto default_done;
                    }
                    auto it = currentActionUsesDefs.find(pe->path->name);
                    if (it != currentActionUsesDefs.end()) {
                        mergeSets(ud.uses, it->second.uses);
                        mergeSets(ud.defs, it->second.defs);
                    }
                } else if (auto mce = defAct->to<IR::MethodCallExpression>()) {
                    if (auto m = mce->method->to<IR::PathExpression>()) {
                        if (!actionAllowed(kv.first, m->path->name)) {
                            goto default_done;
                        }
                        auto it = currentActionUsesDefs.find(m->path->name);
                        if (it != currentActionUsesDefs.end()) {
                            mergeSets(ud.uses, it->second.uses);
                            mergeSets(ud.defs, it->second.defs);
                        }
                    }
                }
default_done:
                ;
            }
            out.emplace(kv.first, std::move(ud));
        }
        return out;
    };

    tableUsesDefs = buildTableUsesDefs(actionUsesDefs);

    StatefulDeclCollector statefulDeclCollector;
    program->apply(statefulDeclCollector);

    if (opts.collectRw) {
        UsesDefs rw;
        for (auto obj : program->objects) {
            if (auto control = obj->to<IR::P4Control>()) {
                collectStmtUsesDefs(control->body, rw, typeMap, &regActionUsesDefs);
            }
        }
        std::set<std::string> reads;
        std::set<std::string> writes;
        auto canonicalizeStateful = [&](const VarKey& v, VarKey& out) -> bool {
            out = v;
            if (statefulDeclCollector.objects.count(v.base)) {
                return true;
            }
            std::string base = v.base.c_str();
            std::string withSuffix = base + "_0";
            if (statefulDeclCollector.objects.count(withSuffix)) {
                out.base = withSuffix.c_str();
                return true;
            }
            if (base.size() > 2 && base.rfind("_0") == base.size() - 2) {
                std::string trimmed = base.substr(0, base.size() - 2);
                if (statefulDeclCollector.objects.count(trimmed)) {
                    out.base = trimmed.c_str();
                    return true;
                }
            }
            return false;
        };
        for (const auto& v : rw.uses) {
            VarKey canon;
            if (canonicalizeStateful(v, canon)) {
                reads.insert(varKeyToString(canon));
            }
        }
        for (const auto& v : rw.defs) {
            VarKey canon;
            if (canonicalizeStateful(v, canon)) {
                writes.insert(varKeyToString(canon));
            }
        }
        std::set<std::string> touchedObjs;
        auto markTouched = [&](const std::string& s) {
            auto pos = s.find('.');
            if (pos == std::string::npos) {
                touchedObjs.insert(s);
            } else {
                touchedObjs.insert(s.substr(0, pos));
            }
        };
        for (const auto& v : reads) {
            markTouched(v);
        }
        for (const auto& v : writes) {
            markTouched(v);
        }
        for (const auto& obj : statefulDeclCollector.objects) {
            std::string name = obj.c_str();
            if (!touchedObjs.count(name)) {
                reads.insert(name);
                writes.insert(name);
            }
        }
        for (const auto& v : reads) {
            result.rwReads.push_back(cstring(v.c_str()));
        }
        for (const auto& v : writes) {
            result.rwWrites.push_back(cstring(v.c_str()));
        }
        for (const auto& obj : statefulDeclCollector.objects) {
            result.rwStatefulObjects.push_back(cstring(obj.c_str()));
        }
    }

    if (!doSlicing) {
        return result;
    }

    CFGBuilder cfg(refMap, typeMap);
    cfg.build(program);
    if (opts.debug) {
        std::cerr << "[slicer] CFG built, nodes=" << cfg.nodes.size() << "\n";
    }

    RegisterDeclCollector regDeclCollector;
    program->apply(regDeclCollector);
    std::set<VarKey, VarKeyLess> seedVars =
        normalizeSeeds(seedInputs, &regDeclCollector.regs, &regDeclCollector.controlToInternal);
    auto tableDefinesSeed = [&](cstring tableName, const IR::P4Table* table) -> bool {
        if (!table) {
            return false;
        }
        auto hasSeedDef = [&](const cstring& actName) -> bool {
            auto it = actionUsesDefs.find(actName);
            if (it == actionUsesDefs.end()) {
                return false;
            }
            for (const auto& d : it->second.defs) {
                if (seedVars.count(d)) {
                    return true;
                }
            }
            return false;
        };
        if (auto al = table->getActionList()) {
            for (auto a : al->actionList) {
                if (!a) {
                    continue;
                }
                auto path = a->getPath();
                if (path && actionAllowed(tableName, path->name) && hasSeedDef(path->name)) {
                    return true;
                }
            }
        }
        if (auto defAct = table->getDefaultAction()) {
            if (auto pe = defAct->to<IR::PathExpression>()) {
                if (actionAllowed(tableName, pe->path->name) && hasSeedDef(pe->path->name)) {
                    return true;
                }
            } else if (auto mce = defAct->to<IR::MethodCallExpression>()) {
                if (auto pe = mce->method->to<IR::PathExpression>()) {
                    if (actionAllowed(tableName, pe->path->name) && hasSeedDef(pe->path->name)) {
                        return true;
                    }
                }
            }
        }
        return false;
    };
    // Seed action_run only for tables whose actions can define seed variables.
    for (const auto& kv : collector.tables) {
        bool fixedDefault = false;
        if (opts.bmv2Analyzer) {
            auto it = tableCp.find(kv.first);
            if (it != tableCp.end()) {
                fixedDefault = it->second.fixedDefault;
            }
        }
        if (fixedDefault) {
            continue;
        }
        if (!tableDefinesSeed(kv.first, kv.second)) {
            continue;
        }
        VarKey actionRun;
        actionRun.base = kv.first.c_str();
        actionRun.segs.push_back("action_run");
        addVarKey(seedVars, actionRun);
    }
    std::set<std::string> packetCarriedBases = collectPacketCarriedBases(program, refMap);
    // Optionally keep forwarding/drop/clone/recirc control variables as implicit seeds.
    // This is conservative (prevents slicing away control effects that can change
    // communication behavior), but may keep large parts of the pipeline for systems
    // where the property does not observe forwarding/egress behavior.
    if (opts.keepControlSeeds) {
        AllVarCollector allVars(typeMap);
        program->apply(allVars);
        const std::set<std::string> controlSegs = {
            "egress_port",
            "egress_spec",
            "ucast_egress_port",
            "forward",
            "drop",
            "p4b_clone_i2e",
            "p4b_clone_e2e",
            "p4b_clone_i2i",
            "p4b_recirculate"
        };
        for (const auto& v : allVars.vars) {
            if (controlSegs.count(v.base)) {
                seedVars.insert(v);
                continue;
            }
            if (!v.segs.empty() && controlSegs.count(v.segs.back())) {
                seedVars.insert(v);
            }
        }
        // `p4b_*` flags are synthetic (introduced by our semantic modeling of externs
        // like recirculate/clone) and may not appear as real IR variables. Seed them
        // explicitly so that control-effecting extern calls are not sliced away.
        for (const auto& base : {"p4b_recirculate", "p4b_clone_i2e", "p4b_clone_e2e", "p4b_clone_i2i"}) {
            VarKey key;
            key.base = base;
            seedVars.insert(key);
        }
    }
    // If a table's actions can define a seed-relevant variable, treat its match keys as seeds too.
    for (const auto& kv : collector.tables) {
        const IR::P4Table* table = kv.second;
        if (!table) {
            continue;
        }
        bool fixedDefault = false;
        if (opts.bmv2Analyzer) {
            auto it = tableCp.find(kv.first);
            if (it != tableCp.end()) {
                fixedDefault = it->second.fixedDefault;
            }
        }
        if (fixedDefault) {
            continue;
        }
        bool touchesSeed = false;
        if (auto al = table->getActionList()) {
            for (auto a : al->actionList) {
                if (!a) {
                    continue;
                }
                auto path = a->getPath();
                if (!path) {
                    continue;
                }
                if (!actionAllowed(kv.first, path->name)) {
                    continue;
                }
                auto it = actionUsesDefs.find(path->name);
                if (it == actionUsesDefs.end()) {
                    continue;
                }
                for (const auto& d : it->second.defs) {
                    if (seedVars.count(d)) {
                        touchesSeed = true;
                        break;
                    }
                }
                if (touchesSeed) {
                    break;
                }
            }
        }
        if (!touchesSeed) {
            if (auto defAct = table->getDefaultAction()) {
                if (auto pe = defAct->to<IR::PathExpression>()) {
                    if (!actionAllowed(kv.first, pe->path->name)) {
                        goto def_done;
                    }
                    auto it = actionUsesDefs.find(pe->path->name);
                    if (it != actionUsesDefs.end()) {
                        for (const auto& d : it->second.defs) {
                            if (seedVars.count(d)) {
                                touchesSeed = true;
                                break;
                            }
                        }
                    }
                } else if (auto mce = defAct->to<IR::MethodCallExpression>()) {
                    if (auto mpe = mce->method->to<IR::PathExpression>()) {
                        if (!actionAllowed(kv.first, mpe->path->name)) {
                            goto def_done;
                        }
                        auto it = actionUsesDefs.find(mpe->path->name);
                        if (it != actionUsesDefs.end()) {
                            for (const auto& d : it->second.defs) {
                                if (seedVars.count(d)) {
                                    touchesSeed = true;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
def_done:
        ;
        if (!touchesSeed) {
            continue;
        }
        if (auto key = table->getKey()) {
            for (auto ke : key->keyElements) {
                if (ke && ke->expression) {
                    std::set<VarKey, VarKeyLess> keyUses;
                    collectExprKeys(ke->expression, keyUses, typeMap);
                    for (const auto& u : keyUses) {
                        addSeedVarKey(seedVars, u);
                    }
                }
            }
        }
    }
    std::map<std::string, int> seedRegMaxIndex;
    for (auto s : seedInputs) {
        std::string base;
        int idx = -1;
        if (extractSeedIndex(s.c_str(), base, idx)) {
            auto it = seedRegMaxIndex.find(base);
            if (it == seedRegMaxIndex.end() || idx > it->second) {
                seedRegMaxIndex[base] = idx;
            }
        }
    }
    if (opts.debug) {
        std::cerr << "[slicer] seeds=" << seedVars.size() << "\n";
        for (const auto& v : seedVars) {
            std::cerr << "  [slicer] seed " << varKeyToString(v) << "\n";
        }
    }

    std::unordered_map<std::string, std::vector<VarKey>> extractSeedFields;
    auto isIndexLike = [](const std::string& s) {
        if (s == "next" || s == "last") {
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
    };
    for (const auto& v : seedVars) {
        if (v.segs.size() < 2) {
            continue;
        }
        VarKey hdr;
        hdr.base = v.base;
        hdr.segs.push_back(v.segs[0]);
        extractSeedFields[varKeyToString(hdr)].push_back(v);
        if (v.segs.size() >= 3 && isIndexLike(v.segs[1])) {
            VarKey hdrIdx = hdr;
            hdrIdx.segs.push_back(v.segs[1]);
            extractSeedFields[varKeyToString(hdrIdx)].push_back(v);
        }
    }

    constexpr int kFixpointMaxIterations = 3;
    std::unordered_set<int> prevKeepStmtIds;
    std::unordered_set<int> keepStmtIds;
    std::unordered_set<cstring> keepActions;
    std::unordered_set<cstring> keepTables;
    std::set<VarKey, VarKeyLess> parserVars;

    for (int iter = 0; iter < kFixpointMaxIterations; ++iter) {
        // Run a small fixpoint between CFG slicing and action-body slicing.
        // The first pass uses coarse action/table summaries, and later passes
        // refine those summaries based on the sliced action bodies.
        tableUsesDefs = buildTableUsesDefs(actionUsesDefs);

        keepStmtIds.clear();
        keepActions.clear();
        keepTables.clear();
        parserVars.clear();

        result.hasRecirculation = false;
        for (auto& kv : cfg.nodes) {
            kv.second.uses.clear();
            kv.second.defs.clear();
        }

        // Fill use/def sets.
        for (auto& kv : cfg.nodes) {
            int id = kv.first;
            NodeInfo& node = kv.second;
            if (!node.stmt) {
                continue;
            }
            if (opts.debug) {
                std::cerr << "[slicer] node " << id << " type=" << node.stmt->node_type_name() << "\n";
            }
            fillNodeUsesDefs(node,
                             typeMap,
                             tableUsesDefs,
                             actionUsesDefs,
                             regActionUsesDefs,
                             &result.hasRecirculation,
                             opts.debug,
                             &extractSeedFields,
                             &seedVars);
        }
        if (opts.debug) {
            std::cerr << "[slicer] use/def sets filled\n";
        }

    // Reaching definitions dataflow (two-pass to model cross-pass deps).
    auto buildAllDefs = [](const std::unordered_map<int, NodeInfo>& nodes) {
        std::map<VarKey, std::set<std::pair<int, VarKey>>, VarKeyLess> defs;
        for (const auto& kv : nodes) {
            for (const auto& v : kv.second.defs) {
                defs[v].insert({kv.first, v});
            }
        }
        return defs;
    };

    auto computeReaching =
        [&](const std::unordered_map<int, NodeInfo>& nodes,
            const std::map<VarKey, std::set<std::pair<int, VarKey>>, VarKeyLess>& allDefs,
            std::unordered_map<int, std::set<std::pair<int, VarKey>>>& in,
            std::unordered_map<int, std::set<std::pair<int, VarKey>>>& out) {
            bool changed = true;
            while (changed) {
                changed = false;
                for (const auto& kv : nodes) {
                    int id = kv.first;
                    const auto& node = kv.second;
                    std::set<std::pair<int, VarKey>> inSet;
                    for (int pred : node.preds) {
                        auto it = out.find(pred);
                        if (it != out.end()) {
                            inSet.insert(it->second.begin(), it->second.end());
                        }
                    }
                    std::set<std::pair<int, VarKey>> outSet = inSet;
                    for (const auto& d : node.defs) {
                        auto defIt = allDefs.find(d);
                        if (defIt != allDefs.end()) {
                            for (const auto& def : defIt->second) {
                                outSet.erase(def);
                            }
                        }
                    }
                    for (const auto& d : node.defs) {
                        outSet.insert({id, d});
                    }
                    if (in[id] != inSet || out[id] != outSet) {
                        in[id] = inSet;
                        out[id] = outSet;
                        changed = true;
                    }
                }
            }
        };

    std::unordered_map<int, std::set<std::pair<int, VarKey>>> in1, out1, in2, out2;
    auto allDefs1 = buildAllDefs(cfg.nodes);
    computeReaching(cfg.nodes, allDefs1, in1, out1);
    if (opts.debug) {
        std::cerr << "[slicer] reaching definitions done (pass 1)\n";
    }

    std::unordered_map<int, NodeInfo> nodes2 = cfg.nodes;
    if (result.hasRecirculation) {
        for (size_t i = 0; i < cfg.roots.size() && i < cfg.exits.size(); ++i) {
            int entry = cfg.roots[i];
            int exit = cfg.exits[i];
            if (entry != -1 && exit != -1) {
                nodes2[exit].succs.push_back(entry);
                nodes2[entry].preds.push_back(exit);
            }
        }
        if (opts.debug) {
            std::cerr << "[slicer] recirc edges done\n";
        }
        auto allDefs2 = buildAllDefs(nodes2);
        computeReaching(nodes2, allDefs2, in2, out2);
        if (opts.debug) {
            std::cerr << "[slicer] reaching definitions done (pass 2)\n";
        }
    }

    auto crossOk = [&](const VarKey& key) -> bool {
        if (packetCarriedBases.count(key.base)) {
            return true;
        }
        if (regDeclCollector.regs.count(key.base)) {
            return true;
        }
        std::string withSuffix = key.base + "_0";
        if (regDeclCollector.regs.count(withSuffix)) {
            return true;
        }
        return false;
    };

    // Build data edges (add cross-pass edges only for CROSSOK variables).
    std::unordered_map<int, std::vector<int>> dataPreds;
    for (const auto& kv : cfg.nodes) {
        int id = kv.first;
        const auto& node = kv.second;
        for (const auto& use : node.uses) {
            auto it1 = in1.find(id);
            if (it1 != in1.end()) {
                for (const auto& def : it1->second) {
                    if (def.second == use) {
                        dataPreds[id].push_back(def.first);
                    }
                }
            }
            if (result.hasRecirculation) {
                auto it2 = in2.find(id);
                if (it2 != in2.end()) {
                    for (const auto& def : it2->second) {
                        if (!(def.second == use)) {
                            continue;
                        }
                        bool inFirst = false;
                        if (it1 != in1.end()) {
                            inFirst = it1->second.count(def) > 0;
                        }
                        if (!inFirst && crossOk(use)) {
                            dataPreds[id].push_back(def.first);
                        }
                    }
                }
            }
        }
    }
    if (opts.debug) {
        std::cerr << "[slicer] data edges done\n";
    }
    if (!opts.dotDir.empty()) {
        std::unordered_map<int, std::vector<int>> cfgEdges;
        std::unordered_map<int, std::vector<int>> cdgEdges;
        for (const auto& kv : cfg.nodes) {
            cfgEdges.emplace(kv.first, kv.second.succs);
            cdgEdges.emplace(kv.first, kv.second.ctrlSuccs);
        }
        std::string base = opts.dotDir;
        if (!base.empty() && base.back() != '/') {
            base.push_back('/');
        }
        writeDotGraph(base + "cfg.before.dot", cfg.nodes, cfgEdges, nullptr, "CFG_BEFORE");
        writeDotGraph(base + "cdg.before.dot", cfg.nodes, cdgEdges, nullptr, "CDG_BEFORE");
        writeDotGraph(base + "ddg.before.dot", cfg.nodes, dataPreds, nullptr, "DDG_BEFORE");
    }

    // Backward slice.
    std::unordered_map<std::string, std::vector<VarKey>> seedsByBase;
    for (const auto& v : seedVars) {
        seedsByBase[v.base].push_back(v);
    }
    std::unordered_map<std::string, std::vector<VarKey>> defsByBase;
    for (const auto& kv : allDefs1) {
        defsByBase[kv.first.base].push_back(kv.first);
    }
    std::unordered_map<std::string, std::vector<VarKey>> seedsNoDefByBase;
    for (const auto& kv : seedsByBase) {
        const auto& base = kv.first;
        const auto& seeds = kv.second;
        const auto& defs = defsByBase[base];
        for (const auto& seed : seeds) {
            bool hasDef = false;
            for (const auto& def : defs) {
                if (varKeyIsPrefix(def, seed)) {
                    hasDef = true;
                    break;
                }
            }
            if (!hasDef) {
                seedsNoDefByBase[base].push_back(seed);
            }
        }
    }
    if (opts.debug) {
        std::cerr << "[slicer] seeds without defs=" << seedsNoDefByBase.size() << "\n";
        for (const auto& kv : seedsNoDefByBase) {
            for (const auto& seed : kv.second) {
                std::cerr << "  [slicer] seed_no_def " << varKeyToString(seed) << "\n";
            }
        }
    }

    std::unordered_set<int> work;
    for (auto& kv : cfg.nodes) {
        int id = kv.first;
        auto& node = kv.second;
        bool isSeed = false;
        for (auto& d : node.defs) {
            auto it = seedsByBase.find(d.base);
            if (it == seedsByBase.end()) {
                continue;
            }
            for (const auto& seed : it->second) {
                if (varKeyIsPrefix(d, seed)) {
                    isSeed = true;
                    break;
                }
            }
            if (isSeed) {
                break;
            }
        }
        if (!isSeed) {
            for (auto& u : node.uses) {
                auto it = seedsNoDefByBase.find(u.base);
                if (it == seedsNoDefByBase.end()) {
                    continue;
                }
                for (const auto& seed : it->second) {
                    if (u == seed) {
                        isSeed = true;
                        break;
                    }
                }
                if (isSeed) {
                    break;
                }
            }
        }
        if (isSeed) {
            work.insert(id);
        }
    }

    std::deque<int> dq;
    for (int id : work) {
        dq.push_back(id);
    }

    std::unordered_set<int> keepNodes = work;
    while (!dq.empty()) {
        int cur = dq.front();
        dq.pop_front();
        auto it = dataPreds.find(cur);
        if (it != dataPreds.end()) {
            for (int pred : it->second) {
                if (!keepNodes.count(pred)) {
                    keepNodes.insert(pred);
                    dq.push_back(pred);
                }
            }
        }
        for (int pred : cfg.nodes[cur].ctrlPreds) {
            if (!keepNodes.count(pred)) {
                keepNodes.insert(pred);
                dq.push_back(pred);
            }
        }
    }
    if (opts.debug) {
        std::cerr << "[slicer] backward slice done\n";
    }
    if (!opts.dotDir.empty()) {
        std::unordered_map<int, std::vector<int>> cfgEdges;
        std::unordered_map<int, std::vector<int>> cdgEdges;
        for (const auto& kv : cfg.nodes) {
            cfgEdges.emplace(kv.first, kv.second.succs);
            cdgEdges.emplace(kv.first, kv.second.ctrlSuccs);
        }
        std::string base = opts.dotDir;
        if (!base.empty() && base.back() != '/') {
            base.push_back('/');
        }
        writeDotGraph(base + "cfg.after.dot", cfg.nodes, cfgEdges, &keepNodes, "CFG_AFTER");
        writeDotGraph(base + "cdg.after.dot", cfg.nodes, cdgEdges, &keepNodes, "CDG_AFTER");
        writeDotGraph(base + "ddg.after.dot", cfg.nodes, dataPreds, &keepNodes, "DDG_AFTER");
    }

    // Keep action bodies referenced by kept calls.
    std::unordered_set<int> extraKeep;
    std::unordered_set<cstring> keepRegActions;
    for (auto& kv : cfg.nodes) {
        int id = kv.first;
        if (!keepNodes.count(id)) {
            continue;
        }
        auto* stmt = kv.second.stmt;
        if (!stmt) {
            continue;
        }
        if (auto mcs = stmt->to<IR::MethodCallStatement>()) {
            auto expr = mcs->methodCall;
            if (!expr || !expr->method) {
                continue;
            }
            if (auto member = expr->method->to<IR::Member>()) {
                if (member->member == "apply") {
                    if (auto base = member->expr->to<IR::PathExpression>()) {
                        auto tit = collector.tables.find(base->path->name);
                        if (tit != collector.tables.end()) {
                            cstring tableName = base->path->name;
                            keepTables.insert(tableName);
                            if (auto al = tit->second->getActionList()) {
                                for (auto a : al->actionList) {
                                    if (!a) {
                                        continue;
                                    }
                                    auto path = a->getPath();
                                    if (!path) {
                                        continue;
                                    }
                                    if (!actionAllowed(tableName, path->name)) {
                                        continue;
                                    }
                                    keepActions.insert(path->name);
                                }
                            }
                            if (auto defAct = tit->second->getDefaultAction()) {
                                if (auto pe = defAct->to<IR::PathExpression>()) {
                                    if (actionAllowed(tableName, pe->path->name)) {
                                        keepActions.insert(pe->path->name);
                                    }
                                } else if (auto mce = defAct->to<IR::MethodCallExpression>()) {
                                    if (auto mpe = mce->method->to<IR::PathExpression>()) {
                                        if (actionAllowed(tableName, mpe->path->name)) {
                                            keepActions.insert(mpe->path->name);
                                        }
                                    }
                                }
                            }
                        } else {
                            auto rit = regActionStmtIds.find(base->path->name);
                            if (rit != regActionStmtIds.end()) {
                                extraKeep.insert(rit->second.begin(), rit->second.end());
                                keepRegActions.insert(base->path->name);
                            }
                        }
                    }
                }
            } else if (auto pe = expr->method->to<IR::PathExpression>()) {
                keepActions.insert(pe->path->name);
            }
        }
    }

    std::unordered_map<cstring, std::unordered_set<int>> actionSliceStmtIds;
    std::unordered_set<cstring> slicedActions;
    // Slicing action bodies needs an inter-action fixpoint: action A may compute
    // a variable used by action B, and B may be the one that (transitively)
    // defines seed variables. A naive "union all uses of kept call-sites"
    // over-approximates and can keep unrelated stateful logic (e.g., Netchain's
    // value_reg even when slicing for seq_reg only).
    //
    // We seed action slicing with:
    // - user/property seeds, and
    // - uses from kept *non-call* control statements (conditions/assignments),
    // - match-key uses of kept tables (affects action selection).
    //
    // Then we close under "needed inputs for relevant action outputs" by
    // iterating sliceActionStmt until the relevant set stabilizes.
    std::set<VarKey, VarKeyLess> actionRelevant = seedVars;
    for (const auto& kv : cfg.nodes) {
        if (!keepNodes.count(kv.first)) {
            continue;
        }
        const auto* stmt = kv.second.stmt;
        if (stmt && stmt->is<IR::MethodCallStatement>()) {
            continue;
        }
        mergeVarSets(actionRelevant, kv.second.uses);
    }
    for (const auto& t : keepTables) {
        bool fixedDefault = false;
        if (opts.bmv2Analyzer) {
            auto it = tableCp.find(t);
            if (it != tableCp.end()) {
                fixedDefault = it->second.fixedDefault;
            }
        }
        if (fixedDefault) {
            continue;
        }
        auto tit = collector.tables.find(t);
        if (tit == collector.tables.end()) {
            continue;
        }
        if (auto key = tit->second->getKey()) {
            for (auto ke : key->keyElements) {
                if (ke && ke->expression) {
                    std::set<VarKey, VarKeyLess> keyUses;
                    collectExprKeys(ke->expression, keyUses, typeMap);
                    mergeVarSets(actionRelevant, keyUses);
                }
            }
        }
    }

    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto& act : keepActions) {
            auto ait = collector.actions.find(act);
            if (ait == collector.actions.end()) {
                continue;
            }
            auto uit = actionUsesDefs.find(act);
            if (uit == actionUsesDefs.end()) {
                continue;
            }
            std::set<VarKey, VarKeyLess> actionSeeds;
            for (const auto& v : uit->second.defs) {
                if (actionRelevant.count(v)) {
                    insertVarKey(actionSeeds, v);
                }
            }
            slicedActions.insert(act);
            std::unordered_set<int> keepIds;
            std::set<VarKey, VarKeyLess> needed = actionSeeds;
            sliceActionStmt(ait->second->body, needed, keepIds, typeMap, &regActionUsesDefs);
            actionSliceStmtIds[act] = std::move(keepIds);

            size_t before = actionRelevant.size();
            mergeVarSets(actionRelevant, needed);
            if (actionRelevant.size() != before) {
                changed = true;
            }
        }
    }
    for (const auto& act : keepActions) {
        auto sit = actionSliceStmtIds.find(act);
        if (sit != actionSliceStmtIds.end()) {
            extraKeep.insert(sit->second.begin(), sit->second.end());
            continue;
        }
        if (slicedActions.count(act)) {
            continue;
        }
        auto ait = actionStmtIds.find(act);
        if (ait != actionStmtIds.end()) {
            extraKeep.insert(ait->second.begin(), ait->second.end());
        }
    }

    if (!opts.dotDir.empty() && !keepActions.empty()) {
        std::string base = opts.dotDir;
        if (!base.empty() && base.back() != '/') {
            base.push_back('/');
        }
        std::string actionDir = base + "actions";
        mkdir(actionDir.c_str(), 0755);
        actionDir.push_back('/');
        for (const auto& act : keepActions) {
            auto ait = collector.actions.find(act);
            if (ait == collector.actions.end()) {
                continue;
            }
            CFGBuilder actCfg(refMap, typeMap);
            CFGFragment frag = actCfg.buildStatement(ait->second->body);
            if (frag.entry == -1) {
                continue;
            }
            actCfg.roots.push_back(frag.entry);
            actCfg.exits.push_back(frag.exit);
            for (auto& kv : actCfg.nodes) {
                fillNodeUsesDefs(kv.second,
                                 typeMap,
                                 tableUsesDefs,
                                 actionUsesDefs,
                                 regActionUsesDefs,
                                 nullptr,
                                 false);
            }
            auto dataPreds = buildDataPredsNoRecirc(actCfg.nodes);
            std::unordered_map<int, std::vector<int>> cfgEdges;
            std::unordered_map<int, std::vector<int>> cdgEdges;
            for (const auto& kv : actCfg.nodes) {
                cfgEdges.emplace(kv.first, kv.second.succs);
                cdgEdges.emplace(kv.first, kv.second.ctrlSuccs);
            }
            std::string actName = dotSafeName(act.c_str());
            std::string actPrefix = actionDir + actName;
            writeDotGraph(actPrefix + ".cfg.before.dot", actCfg.nodes, cfgEdges, nullptr, "CFG_BEFORE");
            writeDotGraph(actPrefix + ".cdg.before.dot", actCfg.nodes, cdgEdges, nullptr, "CDG_BEFORE");
            writeDotGraph(actPrefix + ".ddg.before.dot", actCfg.nodes, dataPreds, nullptr, "DDG_BEFORE");
            const std::unordered_set<int>* keep = nullptr;
            auto sit = actionSliceStmtIds.find(act);
            if (sit != actionSliceStmtIds.end()) {
                keep = &sit->second;
            }
            writeDotGraph(actPrefix + ".cfg.after.dot", actCfg.nodes, cfgEdges, keep, "CFG_AFTER");
            writeDotGraph(actPrefix + ".cdg.after.dot", actCfg.nodes, cdgEdges, keep, "CDG_AFTER");
            writeDotGraph(actPrefix + ".ddg.after.dot", actCfg.nodes, dataPreds, keep, "DDG_AFTER");
        }
    }

    if (!keepActions.empty() && !regActionStmtIds.empty()) {
        class RegActionCallCollector : public Inspector {
         public:
            const std::unordered_map<cstring, std::unordered_set<int>>& regActionStmtIds;
            std::unordered_set<cstring>& keepRegActions;
            std::unordered_set<int>& extraKeep;

            RegActionCallCollector(
                const std::unordered_map<cstring, std::unordered_set<int>>& regActionStmtIds,
                std::unordered_set<cstring>& keepRegActions,
                std::unordered_set<int>& extraKeep)
                : regActionStmtIds(regActionStmtIds),
                  keepRegActions(keepRegActions),
                  extraKeep(extraKeep) {}

            bool preorder(const IR::MethodCallExpression* mce) override {
                cstring name;
                if (!regActionCallName(mce, name)) {
                    return false;
                }
                auto it = regActionStmtIds.find(name);
                if (it == regActionStmtIds.end()) {
                    return false;
                }
                keepRegActions.insert(name);
                extraKeep.insert(it->second.begin(), it->second.end());
                return false;
            }
        };

        RegActionCallCollector regCollector(regActionStmtIds, keepRegActions, extraKeep);
        for (const auto& name : keepActions) {
            auto ait = collector.actions.find(name);
            if (ait == collector.actions.end()) {
                continue;
            }
            if (ait->second && ait->second->body) {
                ait->second->body->apply(regCollector);
            }
        }
    }
    keepStmtIds.insert(extraKeep.begin(), extraKeep.end());

    std::set<VarKey, VarKeyLess> parserSeedVars = seedVars;
    for (const auto& kv : cfg.nodes) {
        if (!keepNodes.count(kv.first)) {
            continue;
        }
        for (const auto& v : kv.second.uses) {
            addVarKey(parserSeedVars, v);
        }
        for (const auto& v : kv.second.defs) {
            addVarKey(parserSeedVars, v);
        }
    }
    for (const auto& t : keepTables) {
        auto tit = tableUsesDefs.find(t);
        if (tit == tableUsesDefs.end()) {
            continue;
        }
        for (const auto& v : tit->second.uses) {
            addVarKey(parserSeedVars, v);
        }
        for (const auto& v : tit->second.defs) {
            addVarKey(parserSeedVars, v);
        }
    }
    // Keep parser statements along paths that can reach seed-relevant headers.
    for (auto obj : program->objects) {
        auto parser = obj->to<IR::P4Parser>();
        if (!parser) {
            continue;
        }

        std::unordered_map<cstring, const IR::ParserState*> states;
        for (auto st : parser->states) {
            if (st) {
                states.emplace(st->name.name, st);
            }
        }
        if (states.empty()) {
            continue;
        }

        auto collectSelectUses = [&](const IR::Expression* sel, std::set<VarKey, VarKeyLess>& out) {
            if (!sel) {
                return;
            }
            if (auto pe = sel->to<IR::PathExpression>()) {
                VarKey key;
                key.base = pe->path->toString();
                addVarKey(out, key);
                return;
            }
            if (auto se = sel->to<IR::SelectExpression>()) {
                collectExprKeys(se->select, out, typeMap);
                return;
            }
            collectExprKeys(sel, out, typeMap);
        };

        std::unordered_map<cstring, std::vector<cstring>> succ;
        for (auto& kv : states) {
            auto st = kv.second;
            if (!st || !st->selectExpression) {
                continue;
            }
            if (auto pe = st->selectExpression->to<IR::PathExpression>()) {
                succ[kv.first].push_back(pe->path->name);
            } else if (auto se = st->selectExpression->to<IR::SelectExpression>()) {
                for (auto sc : se->selectCases) {
                    if (sc && sc->state) {
                        succ[kv.first].push_back(sc->state->path->name);
                    }
                }
            }
        }

        // Parser slicing is tricky: pruning only the parser statements (e.g., packet.extract)
        // while leaving the parser state machine structure intact can make header fields
        // unconstrained yet still used in select expressions, leading to ill-typed Boogie
        // and (worse) spurious behaviors. To keep the sliced model sound for bug-finding,
        // we conservatively keep all parser states that are reachable from the start state.
        std::unordered_set<cstring> keepStates;
        if (states.count("start")) {
            std::deque<cstring> todo;
            keepStates.insert("start");
            todo.push_back("start");
            while (!todo.empty()) {
                auto cur = todo.front();
                todo.pop_front();
                auto it = succ.find(cur);
                if (it == succ.end()) {
                    continue;
                }
                for (auto s : it->second) {
                    if (states.count(s) == 0) {
                        continue;
                    }
                    if (!keepStates.count(s)) {
                        keepStates.insert(s);
                        todo.push_back(s);
                    }
                }
            }
        } else {
            // Fallback: if no explicit start state exists, keep all parser states.
            for (const auto& kv : states) {
                keepStates.insert(kv.first);
            }
        }

        for (auto s : keepStates) {
            auto it = states.find(s);
            if (it == states.end()) {
                continue;
            }
            auto st = it->second;
            if (!st) {
                continue;
            }
            if (st->selectExpression) {
                collectSelectUses(st->selectExpression, parserVars);
            }
            for (auto comp : st->components) {
                auto stmt = comp->to<IR::Statement>();
                if (!stmt) {
                    continue;
                }
                collectStmtIds(stmt, keepStmtIds);
            }
        }
    }

    // Only keep real statements.
    for (auto& kv : cfg.nodes) {
        if (keepNodes.count(kv.first) && kv.second.stmt) {
            keepStmtIds.insert(kv.second.stmt->id);
        }
    }

    // Keep RegisterAction apply bodies only when referenced by kept calls.
    if (!keepRegActions.empty()) {
        for (const auto& name : keepRegActions) {
            auto it = regActionStmtIds.find(name);
            if (it != regActionStmtIds.end()) {
                keepStmtIds.insert(it->second.begin(), it->second.end());
            }
        }
    }
        if (iter > 0 && keepStmtIds == prevKeepStmtIds) {
            if (opts.debug) {
                std::cerr << "[slicer] fixpoint reached after " << (iter + 1) << " iterations\n";
            }
            break;
        }
        prevKeepStmtIds = keepStmtIds;

        if (iter + 1 < kFixpointMaxIterations) {
            // Recompute action summaries from the sliced IR to avoid summary pollution
            // (e.g., unrelated vars kept only because they appear in an unsliced action).
            const IR::P4Program* slicedForSummary = applySlice(program, keepStmtIds, refMap);
            ActionTableCollector summaryCollector;
            slicedForSummary->apply(summaryCollector);

            std::unordered_map<cstring, UsesDefs> nextRegActionUsesDefs;
            for (const auto& kv : summaryCollector.regActions) {
                const IR::Declaration_Instance* inst = kv.second;
                const IR::Function* applyFunc = findRegisterActionApply(inst);
                if (!applyFunc || !applyFunc->body) {
                    continue;
                }
                UsesDefs ud;
                collectStmtUsesDefs(applyFunc->body, ud, typeMap);
                nextRegActionUsesDefs.emplace(kv.first, std::move(ud));
            }

            std::unordered_map<cstring, UsesDefs> nextActionUsesDefs;
            for (const auto& kv : summaryCollector.actions) {
                UsesDefs ud;
                collectStmtUsesDefs(kv.second->body, ud, typeMap, &nextRegActionUsesDefs);
                nextActionUsesDefs.emplace(kv.first, std::move(ud));
            }

            regActionUsesDefs = std::move(nextRegActionUsesDefs);
            actionUsesDefs = std::move(nextActionUsesDefs);
        }
    }

    result.keepStatementIds.insert(keepStmtIds.begin(), keepStmtIds.end());

    if (keepTables.empty()) {
        for (const auto& kv : collector.tables) {
            keepTables.insert(kv.first);
        }
    }

    std::unordered_set<std::string> forcedKeepNames;
    // Collect kept variables from kept statements and seeds.
    const IR::P4Program* slicedForVars = applySlice(program, keepStmtIds, refMap);
    AllVarCollector varCollector(typeMap);
    slicedForVars->apply(varCollector);

    ActionTableCollector slicedCollector;
    slicedForVars->apply(slicedCollector);
    std::unordered_map<cstring, UsesDefs> slicedActionUsesDefs;
    std::unordered_map<cstring, UsesDefs> slicedTableUsesDefs;
    std::unordered_map<cstring, UsesDefs> slicedRegActionUsesDefs;
    for (const auto& kv : slicedCollector.regActions) {
        const IR::Declaration_Instance* inst = kv.second;
        const IR::Function* applyFunc = findRegisterActionApply(inst);
        if (!applyFunc || !applyFunc->body) {
            continue;
        }
        UsesDefs ud;
        collectStmtUsesDefs(applyFunc->body, ud, typeMap);
        slicedRegActionUsesDefs.emplace(kv.first, std::move(ud));
    }
    for (const auto& kv : slicedCollector.actions) {
        UsesDefs ud;
        collectStmtUsesDefs(kv.second->body, ud, typeMap, &slicedRegActionUsesDefs);
        slicedActionUsesDefs.emplace(kv.first, std::move(ud));
    }
    for (const auto& kv : slicedCollector.tables) {
        const IR::P4Table* table = kv.second;
        UsesDefs ud;
        VarKey actionRun;
        actionRun.base = kv.first.c_str();
        actionRun.segs.push_back("action_run");
        addVarKey(ud.defs, actionRun);
        if (auto key = table->getKey()) {
            for (auto ke : key->keyElements) {
                if (ke && ke->expression) {
                    collectExprKeys(ke->expression, ud.uses, typeMap);
                }
            }
        }
        if (auto al = table->getActionList()) {
            for (auto a : al->actionList) {
                if (!a) {
                    continue;
                }
                auto path = a->getPath();
                if (!path) {
                    continue;
                }
                auto it = slicedActionUsesDefs.find(path->name);
                if (it != slicedActionUsesDefs.end()) {
                    mergeSets(ud.uses, it->second.uses);
                    mergeSets(ud.defs, it->second.defs);
                }
            }
        }
        if (auto defAct = table->getDefaultAction()) {
            if (auto pe = defAct->to<IR::PathExpression>()) {
                auto it = slicedActionUsesDefs.find(pe->path->name);
                if (it != slicedActionUsesDefs.end()) {
                    mergeSets(ud.uses, it->second.uses);
                    mergeSets(ud.defs, it->second.defs);
                }
            } else if (auto mce = defAct->to<IR::MethodCallExpression>()) {
                if (auto m = mce->method->to<IR::PathExpression>()) {
                    auto it = slicedActionUsesDefs.find(m->path->name);
                    if (it != slicedActionUsesDefs.end()) {
                        mergeSets(ud.uses, it->second.uses);
                        mergeSets(ud.defs, it->second.defs);
                    }
                }
            }
        }
        slicedTableUsesDefs.emplace(kv.first, std::move(ud));
    }
    if (opts.debug) {
        std::cerr << "[slicer] register declarations=" << regDeclCollector.regs.size() << "\n";
        for (const auto& r : regDeclCollector.regs) {
            std::cerr << "  [slicer] decl " << r << "\n";
        }
    }
    auto normalizeRegName = [&](const std::string& name) -> std::string {
        if (regDeclCollector.regs.count(name)) {
            return name;
        }
        std::string withSuffix = name + "_0";
        if (regDeclCollector.regs.count(withSuffix)) {
            return withSuffix;
        }
        return name;
    };

    RegisterUseCollector regUseCollector(refMap);
    slicedForVars->apply(regUseCollector);
    if (opts.debug) {
        std::cerr << "[slicer] registers in kept slice=" << regUseCollector.regs.size() << "\n";
        for (const auto& r : regUseCollector.regs) {
            std::cerr << "  [slicer] reg " << r << "\n";
        }
    }
    for (const auto& r : regUseCollector.regs) {
        VarKey key;
        key.base = normalizeRegName(r);
        addVarKey(varCollector.vars, key);
    }
    for (const auto& v : seedVars) {
        addVarKey(varCollector.vars, v);
    }
    for (const auto& act : keepActions) {
        auto it = slicedActionUsesDefs.find(act);
        if (it == slicedActionUsesDefs.end()) {
            continue;
        }
        for (const auto& v : it->second.uses) {
            addVarKey(varCollector.vars, v);
        }
        for (const auto& v : it->second.defs) {
            addVarKey(varCollector.vars, v);
        }
    }
    for (const auto& tableName : keepTables) {
        auto tit = slicedCollector.tables.find(tableName);
        if (tit == slicedCollector.tables.end()) {
            continue;
        }
        VarKey actionRun;
        actionRun.base = tableName.c_str();
        actionRun.segs.push_back("action_run");
        addVarKey(varCollector.vars, actionRun);
        if (auto al = tit->second->getActionList()) {
            for (auto a : al->actionList) {
                if (!a) {
                    continue;
                }
                auto path = a->getPath();
                if (!path) {
                    continue;
                }
                auto ait = slicedCollector.actions.find(path->name);
                if (ait == slicedCollector.actions.end()) {
                    continue;
                }
                for (auto p : ait->second->parameters->parameters) {
                    if (!p) {
                        continue;
                    }
                    std::string name = tableName.c_str();
                    name += ".";
                    name += path->name.toString();
                    name += ".";
                    name += p->name.toString();
                    VarKey key;
                    if (parseVarKeyFromString(name, key)) {
                        addVarKey(varCollector.vars, key);
                    }
                    forcedKeepNames.insert(name);
                }
            }
        }
        if (auto defAct = tit->second->getDefaultAction()) {
            if (auto pe = defAct->to<IR::PathExpression>()) {
                auto ait = slicedCollector.actions.find(pe->path->name);
                if (ait != slicedCollector.actions.end()) {
                    for (auto p : ait->second->parameters->parameters) {
                        if (!p) {
                            continue;
                        }
                        std::string name = tableName.c_str();
                        name += ".";
                        name += pe->path->name.toString();
                        name += ".";
                        name += p->name.toString();
                        VarKey key;
                        if (parseVarKeyFromString(name, key)) {
                            addVarKey(varCollector.vars, key);
                        }
                    }
                }
            } else if (auto mce = defAct->to<IR::MethodCallExpression>()) {
                if (auto mpe = mce->method->to<IR::PathExpression>()) {
                    auto ait = slicedCollector.actions.find(mpe->path->name);
                    if (ait != slicedCollector.actions.end()) {
                        for (auto p : ait->second->parameters->parameters) {
                            if (!p) {
                                continue;
                            }
                            std::string name = tableName.c_str();
                            name += ".";
                            name += mpe->path->name.toString();
                            name += ".";
                            name += p->name.toString();
                            VarKey key;
                            if (parseVarKeyFromString(name, key)) {
                                addVarKey(varCollector.vars, key);
                            }
                            forcedKeepNames.insert(name);
                        }
                    }
                }
            }
        }
        auto uit = slicedTableUsesDefs.find(tableName);
        if (uit != slicedTableUsesDefs.end()) {
            for (const auto& v : uit->second.uses) {
                addVarKey(varCollector.vars, v);
            }
            for (const auto& v : uit->second.defs) {
                addVarKey(varCollector.vars, v);
            }
        }
    }
    for (const auto& v : varCollector.vars) {
        result.keepVarNames.insert(cstring(varKeyToString(v)));
    }
    for (const auto& v : parserVars) {
        result.keepVarNames.insert(cstring(varKeyToString(v)));
    }
    for (const auto& name : forcedKeepNames) {
        result.keepVarNames.insert(cstring(name));
    }
    // For registers, also keep the sanitized control-plane alias used by the Boogie translator.
    // This allows system-level tools (e.g., dslc) to seed slicing using Boogie-level names.
    for (const auto& kv : regDeclCollector.internalToControl) {
        if (result.keepVarNames.count(cstring(kv.first.c_str())) > 0) {
            result.keepVarNames.insert(cstring(kv.second.c_str()));
        }
    }
    for (const auto& t : keepTables) {
        result.keepTables.insert(t);
    }
    if (opts.debug) {
        std::cerr << "[slicer] keep vars=" << result.keepVarNames.size() << "\n";
        for (const auto& v : result.keepVarNames) {
            std::cerr << "  [slicer] var " << v << "\n";
        }
        std::cerr << "[slicer] keep tables=" << result.keepTables.size() << "\n";
        for (const auto& t : result.keepTables) {
            std::cerr << "  [slicer] table " << t << "\n";
        }
    }

    RegisterIndexCollector regCollector(result.keepStatementIds, &regDeclCollector.regs, refMap);
    program->apply(regCollector);
    for (const auto& kv : regCollector.maxIndex) {
        std::string norm = normalizeRegName(kv.first);
        result.regMaxIndex.emplace(cstring(norm), kv.second);
    }
    for (const auto& kv : seedRegMaxIndex) {
        std::string norm = normalizeRegName(kv.first);
        auto it = result.regMaxIndex.find(cstring(norm));
        if (it == result.regMaxIndex.end() || kv.second > it->second) {
            result.regMaxIndex[cstring(norm)] = kv.second;
        }
    }
    for (const auto& r : regCollector.hasNonConst) {
        std::string norm = normalizeRegName(r);
        result.regHasNonConst.insert(cstring(norm));
    }
    if (opts.debug) {
        std::cerr << "[slicer] keep statements=" << result.keepStatementIds.size() << "\n";
    }
    return result;
}

class SlicePruner : public Transform {
 public:
    explicit SlicePruner(const std::unordered_set<int>& keepIds) : keepIds(keepIds) {
        setName("SlicePruner");
    }

    const IR::Node* postorder(IR::AssignmentStatement* statement) override {
        if (!shouldKeep(getOriginal())) {
            return new IR::EmptyStatement();
        }
        return statement;
    }

    const IR::Node* postorder(IR::MethodCallStatement* statement) override {
        if (!shouldKeep(getOriginal())) {
            return new IR::EmptyStatement();
        }
        return statement;
    }

    const IR::Node* postorder(IR::IfStatement* statement) override {
        if (!shouldKeep(getOriginal())) {
            return new IR::EmptyStatement();
        }
        return statement;
    }

    const IR::Node* postorder(IR::SwitchStatement* statement) override {
        if (!shouldKeep(getOriginal())) {
            return new IR::EmptyStatement();
        }
        return statement;
    }

    const IR::Node* postorder(IR::BlockStatement* statement) override {
        return statement;
    }

 private:
    const std::unordered_set<int>& keepIds;

    bool shouldKeep(const IR::Node* original) const {
        if (!original) {
            return true;
        }
        return keepIds.count(original->id) > 0;
    }
};

class SliceRegisterDeclPruner : public Transform {
 public:
    SliceRegisterDeclPruner(const std::set<std::string>& allRegs,
                            const std::unordered_set<std::string>& keepRegs)
        : allRegs(allRegs), keepRegs(keepRegs) {
        setName("SliceRegisterDeclPruner");
    }

    const IR::Node* postorder(IR::Declaration_Instance* inst) override {
        if (!inst) {
            return inst;
        }
        std::string name = inst->name.name.c_str();
        if (allRegs.count(name) > 0 && keepRegs.count(name) == 0) {
            return nullptr;
        }
        return inst;
    }

 private:
    const std::set<std::string>& allRegs;
    const std::unordered_set<std::string>& keepRegs;
};

class SliceRegisterUseCollector : public Inspector {
 public:
    SliceRegisterUseCollector(const std::set<std::string>& regs, P4::ReferenceMap* refMap)
        : declRegs(regs), refMap(refMap) {}

    std::unordered_set<std::string> used;

    bool preorder(const IR::PathExpression* pe) override {
        if (!pe || !pe->path) {
            return false;
        }
        std::string name;
        if (refMap) {
            if (auto decl = refMap->getDeclaration(pe->path, false)) {
                name = decl->getName().name.c_str();
            }
        }
        if (name.empty()) {
            name = pe->path->name.toString().c_str();
        }
        if (declRegs.count(name) > 0) {
            used.insert(name);
            return false;
        }
        std::string withSuffix = name + "_0";
        if (declRegs.count(withSuffix) > 0) {
            used.insert(withSuffix);
            return false;
        }
        if (name.size() > 2 && name.rfind("_0") == name.size() - 2) {
            std::string trimmed = name.substr(0, name.size() - 2);
            if (declRegs.count(trimmed) > 0) {
                used.insert(trimmed);
            }
        }
        return false;
    }

 private:
    const std::set<std::string>& declRegs;
    P4::ReferenceMap* refMap;
};

const IR::P4Program* applySlice(const IR::P4Program* program,
                                const std::unordered_set<int>& keepStatementIds,
                                P4::ReferenceMap* refMap,
                                const std::unordered_set<cstring>* keepVarNames) {
    if (keepStatementIds.empty()) {
        return program;
    }
    SlicePruner pruner(keepStatementIds);
    const IR::P4Program* sliced = program->apply(pruner)->to<IR::P4Program>();
    if (!sliced) {
        return sliced;
    }

    // Slicing prunes statements by replacing them with EmptyStatement, but leaves
    // Register Declaration_Instance nodes intact. Those dead declarations lead to
    // large Boogie state spaces (vars + init axioms + helper procs).
    //
    // Conservatively prune register declarations that are no longer referenced by
    // any remaining method call on that register in the sliced IR.
    RegisterDeclCollector regDeclCollector;
    sliced->apply(regDeclCollector);
    if (regDeclCollector.regs.empty()) {
        return sliced;
    }

    SliceRegisterUseCollector regUseCollector(regDeclCollector.regs, refMap);
    sliced->apply(regUseCollector);

    std::unordered_set<std::string> keepRegs = std::move(regUseCollector.used);
    if (keepVarNames != nullptr) {
        for (const auto& v : *keepVarNames) {
            std::string name = v.c_str();
            if (regDeclCollector.regs.count(name) > 0) {
                keepRegs.insert(name);
                continue;
            }
            auto aliasIt = regDeclCollector.controlToInternal.find(name);
            if (aliasIt != regDeclCollector.controlToInternal.end() && !aliasIt->second.empty() &&
                regDeclCollector.regs.count(aliasIt->second) > 0) {
                keepRegs.insert(aliasIt->second);
                continue;
            }
            std::string withSuffix = name + "_0";
            if (regDeclCollector.regs.count(withSuffix) > 0) {
                keepRegs.insert(withSuffix);
                continue;
            }
            if (name.size() > 2 && name.rfind("_0") == name.size() - 2) {
                std::string trimmed = name.substr(0, name.size() - 2);
                if (regDeclCollector.regs.count(trimmed) > 0) {
                    keepRegs.insert(trimmed);
                }
            }
        }
    }
    if (keepRegs.size() >= regDeclCollector.regs.size()) {
        return sliced;
    }

    SliceRegisterDeclPruner declPruner(regDeclCollector.regs, keepRegs);
    return sliced->apply(declPruner)->to<IR::P4Program>();
}

}  // namespace P4Verify
