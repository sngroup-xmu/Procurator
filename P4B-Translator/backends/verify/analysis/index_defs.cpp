// P4-local deterministic index definition analysis.
//
// This pass exports assignment summaries such as:
//   meta.register_index := Ingress_idx_calc.get$bv32$...(hdr.ipv4.src_addr, ...)
// into --meta-out.  The goal is to keep P4 semantics recovery inside P4B and
// let DSLC consume structured metadata instead of parsing Boogie procedure text.

#include "backends/verify/analysis/index_defs.h"

#include <algorithm>
#include <set>
#include <sstream>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "backends/verify/translate/options.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "ir/visitor.h"

namespace P4Verify {
namespace {

static std::string sanitizeHashSignaturePart(const std::string& raw) {
    std::string out;
    out.reserve(raw.size());
    for (char c : raw) {
        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
            (c >= '0' && c <= '9')) {
            out.push_back(c);
        } else {
            out.push_back('_');
        }
    }
    if (out.empty()) {
        return "unit";
    }
    if (out[0] >= '0' && out[0] <= '9') {
        out.insert(out.begin(), '_');
    }
    return out;
}

static const IR::Expression* idxDefStripCasts(const IR::Expression* expr) {
    while (expr) {
        if (auto cast = expr->to<IR::Cast>()) {
            expr = cast->expr;
            continue;
        }
        break;
    }
    return expr;
}

static int idxDefTypeBitWidth(const IR::Type* type, P4::ReferenceMap* refMap = nullptr) {
    if (type == nullptr) {
        return -1;
    }
    if (auto name = type->to<IR::Type_Name>()) {
        if (refMap != nullptr) {
            if (auto decl = refMap->getDeclaration(name->path, true)) {
                if (auto declType = decl->to<IR::Type>()) {
                    return idxDefTypeBitWidth(declType, refMap);
                }
                if (auto td = decl->to<IR::Type_Typedef>()) {
                    return idxDefTypeBitWidth(td->type, refMap);
                }
                if (auto nt = decl->to<IR::Type_Newtype>()) {
                    return idxDefTypeBitWidth(nt->type, refMap);
                }
            }
        }
    }
    if (auto bits = type->to<IR::Type_Bits>()) {
        return bits->size;
    }
    return -1;
}

static std::string boogieType(const IR::Type* type, P4::ReferenceMap* refMap = nullptr) {
    if (type == nullptr) {
        return "";
    }
    if (type->is<IR::Type_Boolean>()) {
        return "bool";
    }
    int width = idxDefTypeBitWidth(type, refMap);
    if (width > 0) {
        return "bv" + std::to_string(width);
    }
    if (type->is<IR::Type_InfInt>()) {
        return "int";
    }
    return "";
}

static std::string idxDefSanitizeDeclName(const std::string& raw) {
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

static bool idxDefExtractVarPath(const IR::Expression* expr,
                                 P4::ReferenceMap* refMap,
                                 const std::unordered_map<std::string, std::string>* renames,
                                 std::string& out) {
    expr = idxDefStripCasts(expr);
    if (expr == nullptr) {
        return false;
    }
    if (auto pe = expr->to<IR::PathExpression>()) {
        out = pe->path->name.toString().c_str();
        if (refMap != nullptr && pe->path != nullptr) {
            if (auto decl = refMap->getDeclaration(pe->path, false)) {
                out = decl->getName().name.c_str();
                cstring cp = decl->controlPlaneName();
                if (!cp.isNullOrEmpty()) {
                    std::string sanitized = idxDefSanitizeDeclName(cp.c_str());
                    if (!sanitized.empty()) {
                        out = sanitized;
                    }
                }
            }
        }
        if (renames != nullptr) {
            auto it = renames->find(out);
            if (it != renames->end()) {
                out = it->second;
            }
        }
        return true;
    }
    if (auto mem = expr->to<IR::Member>()) {
        std::string base;
        if (!idxDefExtractVarPath(mem->expr, refMap, renames, base)) {
            return false;
        }
        out = base;
        out.push_back('.');
        out += mem->member.toString().c_str();
        return true;
    }
    if (auto ai = expr->to<IR::ArrayIndex>()) {
        std::string base;
        if (!idxDefExtractVarPath(ai->left, refMap, renames, base)) {
            return false;
        }
        auto idx = idxDefStripCasts(ai->right);
        if (auto c = idx ? idx->to<IR::Constant>() : nullptr) {
            out = base;
            out.push_back('.');
            std::stringstream ss;
            ss << c->value;
            out += ss.str();
            return true;
        }
        return false;
    }
    return false;
}

static bool idxDefDirectMethodName(const IR::Expression* expr, std::string& out) {
    expr = idxDefStripCasts(expr);
    if (expr == nullptr) {
        return false;
    }
    if (auto pe = expr->to<IR::PathExpression>()) {
        out = pe->path->name.toString().c_str();
        if (out.empty() && pe->path != nullptr) {
            out = pe->path->toString().c_str();
        }
        return !out.empty();
    }
    if (auto mem = expr->to<IR::Member>()) {
        out = mem->member.toString().c_str();
        return !out.empty();
    }
    out = expr->toString().c_str();
    return !out.empty();
}

static std::string idxDefExprFallbackText(const IR::Expression* expr) {
    if (expr == nullptr) {
        return "";
    }
    return sanitizeHashSignaturePart(expr->toString().c_str());
}

static std::string normalizeV1ModelHashAlgorithm(std::string algorithm) {
    const std::string prefix = "HashAlgorithm";
    if (algorithm.rfind(prefix, 0) == 0) {
        algorithm.erase(0, prefix.size());
        while (!algorithm.empty() && (algorithm[0] == '_' || algorithm[0] == '.')) {
            algorithm.erase(algorithm.begin());
        }
        return "_" + algorithm;
    }
    return algorithm;
}

static void idxDefCollectVarPaths(const IR::Expression* expr,
                                  P4::ReferenceMap* refMap,
                                  const std::unordered_map<std::string, std::string>* renames,
                                  std::set<std::string>* out) {
    expr = idxDefStripCasts(expr);
    if (expr == nullptr || out == nullptr) {
        return;
    }
    std::string var;
    if (idxDefExtractVarPath(expr, refMap, renames, var)) {
        out->insert(var);
        return;
    }
    if (auto bin = expr->to<IR::Operation_Binary>()) {
        idxDefCollectVarPaths(bin->left, refMap, renames, out);
        idxDefCollectVarPaths(bin->right, refMap, renames, out);
        return;
    }
    if (auto un = expr->to<IR::Operation_Unary>()) {
        idxDefCollectVarPaths(un->expr, refMap, renames, out);
        return;
    }
    if (auto sl = expr->to<IR::Slice>()) {
        idxDefCollectVarPaths(sl->e0, refMap, renames, out);
        return;
    }
    if (auto mce = expr->to<IR::MethodCallExpression>()) {
        if (mce->arguments) {
            for (auto arg : *mce->arguments) {
                if (arg && arg->expression) {
                    idxDefCollectVarPaths(arg->expression, refMap, renames, out);
                }
            }
        }
        return;
    }
    if (auto list = expr->to<IR::ListExpression>()) {
        for (auto comp : list->components) {
            idxDefCollectVarPaths(comp, refMap, renames, out);
        }
        return;
    }
    if (auto st = expr->to<IR::StructExpression>()) {
        for (auto comp : st->components) {
            if (comp && comp->expression) {
                idxDefCollectVarPaths(comp->expression, refMap, renames, out);
            }
        }
        return;
    }
}

static bool renderExpr(const IR::Expression* expr,
                       P4::ReferenceMap* refMap,
                       const std::unordered_map<std::string, std::string>* renames,
                       std::string* out,
                       std::vector<std::string>* argTypes);

static bool renderHashData(const IR::Expression* expr,
                           const std::unordered_map<std::string, std::string>* renames,
                           P4::ReferenceMap* refMap,
                           std::vector<std::string>* args,
                           std::vector<std::string>* argTypes) {
    expr = idxDefStripCasts(expr);
    if (expr == nullptr || args == nullptr || argTypes == nullptr) {
        return false;
    }
    if (auto listExpr = expr->to<IR::ListExpression>()) {
        for (auto component : listExpr->components) {
            if (!renderHashData(component, renames, refMap, args, argTypes)) {
                return false;
            }
        }
        return true;
    }
    if (auto structExpr = expr->to<IR::StructExpression>()) {
        for (auto component : structExpr->components) {
            if (component == nullptr ||
                !renderHashData(component->expression, renames, refMap, args, argTypes)) {
                return false;
            }
        }
        return true;
    }
    std::string rendered;
    if (!renderExpr(expr, refMap, renames, &rendered, nullptr)) {
        return false;
    }
    std::string typ = boogieType(expr->type, refMap);
    if (typ.empty()) {
        typ = "int";
    }
    args->push_back(rendered);
    argTypes->push_back(typ);
    return true;
}

static bool renderExpr(const IR::Expression* expr,
                       P4::ReferenceMap* refMap,
                       const std::unordered_map<std::string, std::string>* renames,
                       std::string* out,
                       std::vector<std::string>* /*argTypes*/) {
    expr = idxDefStripCasts(expr);
    if (expr == nullptr || out == nullptr) {
        return false;
    }

    std::string var;
    if (idxDefExtractVarPath(expr, refMap, renames, var)) {
        *out = var;
        return true;
    }
    if (auto c = expr->to<IR::Constant>()) {
        std::stringstream ss;
        ss << c->value;
        std::string typ = boogieType(c->type, refMap);
        *out = typ.rfind("bv", 0) == 0 ? ss.str() + typ : ss.str();
        return true;
    }
    if (auto b = expr->to<IR::BoolLiteral>()) {
        *out = b->value ? "true" : "false";
        return true;
    }
    if (auto bin = expr->to<IR::Operation_Binary>()) {
        std::string left;
        std::string right;
        if (!renderExpr(bin->left, refMap, renames, &left, nullptr) ||
            !renderExpr(bin->right, refMap, renames, &right, nullptr)) {
            return false;
        }
        const char* op = nullptr;
        if (expr->is<IR::Add>()) {
            op = " + ";
        } else if (expr->is<IR::Sub>()) {
            op = " - ";
        } else if (expr->is<IR::Mul>()) {
            op = " * ";
        } else if (expr->is<IR::Equ>()) {
            op = " == ";
        } else if (expr->is<IR::Neq>()) {
            op = " != ";
        } else if (expr->is<IR::LAnd>()) {
            op = " && ";
        } else if (expr->is<IR::LOr>()) {
            op = " || ";
        }
        if (op == nullptr) {
            return false;
        }
        *out = "(" + left + op + right + ")";
        return true;
    }
    if (auto un = expr->to<IR::Operation_Unary>()) {
        std::string inner;
        if (!renderExpr(un->expr, refMap, renames, &inner, nullptr)) {
            return false;
        }
        if (expr->is<IR::LNot>()) {
            *out = "!" + inner;
            return true;
        }
        return false;
    }
    if (auto sl = expr->to<IR::Slice>()) {
        std::string base;
        if (!renderExpr(sl->e0, refMap, renames, &base, nullptr)) {
            return false;
        }
        std::stringstream ss;
        ss << base << "[" << sl->getH() << ":" << sl->getL() << "]";
        *out = ss.str();
        return true;
    }
    if (auto mce = expr->to<IR::MethodCallExpression>()) {
        auto member = mce->method ? mce->method->to<IR::Member>() : nullptr;
        if (member == nullptr) {
            return false;
        }
        if (member->member != "get" && member->member != "get_hash") {
            return false;
        }
        std::string method;
        if (!idxDefExtractVarPath(mce->method, refMap, renames, method) || method.empty()) {
            return false;
        }
        std::vector<std::string> args;
        std::vector<std::string> types;
        if (mce->arguments == nullptr) {
            return false;
        }
        for (auto arg : *mce->arguments) {
            if (arg == nullptr ||
                !renderHashData(arg->expression, renames, refMap, &args, &types)) {
                return false;
            }
        }
        for (const auto& typ : types) {
            method += "$";
            method += sanitizeHashSignaturePart(typ);
        }
        std::string res = method + "(";
        for (size_t i = 0; i < args.size(); ++i) {
            if (i != 0) {
                res += ", ";
            }
            res += args[i];
        }
        res += ")";
        *out = res;
        return true;
    }
    return false;
}

static bool isIdentStart(char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
}

static bool isIdentBody(char c) {
    return isIdentStart(c) || (c >= '0' && c <= '9') || c == '.' || c == '$';
}

static std::string substituteIdentifierTokens(
    const std::string& expr,
    const std::unordered_map<std::string, std::string>& subst) {
    if (subst.empty()) {
        return expr;
    }
    std::string out;
    out.reserve(expr.size());
    for (size_t i = 0; i < expr.size();) {
        char c = expr[i];
        if (!isIdentStart(c)) {
            out.push_back(c);
            i++;
            continue;
        }
        size_t j = i + 1;
        while (j < expr.size() && isIdentBody(expr[j])) {
            j++;
        }
        std::string tok = expr.substr(i, j - i);
        auto it = subst.find(tok);
        out += (it == subst.end()) ? tok : it->second;
        i = j;
    }
    return out;
}

static bool isIndexDefinitionTarget(const std::string& lhs) {
    if (lhs.empty()) {
        return false;
    }
    if (lhs.find("index") != std::string::npos || lhs.find("idx") != std::string::npos ||
        lhs.find("pos") != std::string::npos) {
        return true;
    }
    return false;
}

struct DefinitionSummary {
    std::string target;
    std::string expr;
    std::set<std::string> deps;
    std::string context;
    std::unordered_map<std::string, std::string> paramTypes;
};

static std::string stripTrailingNumericSuffix(const std::string& name) {
    const size_t pos = name.rfind('_');
    if (pos == std::string::npos || pos + 1 >= name.size()) {
        return name;
    }
    for (size_t i = pos + 1; i < name.size(); ++i) {
        if (name[i] < '0' || name[i] > '9') {
            return name;
        }
    }
    return name.substr(0, pos);
}

static std::string rewriteHashSignatureTypes(
    const std::string& expr,
    const std::unordered_map<std::string, std::string>& substTypes) {
    if (substTypes.empty()) {
        return expr;
    }
    const size_t open = expr.find('(');
    if (open == std::string::npos) {
        return expr;
    }
    std::string callee = expr.substr(0, open);
    const size_t dollar = callee.find('$');
    if (dollar == std::string::npos) {
        return expr;
    }
    std::vector<std::string> args;
    std::string cur;
    int depth = 0;
    for (size_t i = open + 1; i < expr.size(); ++i) {
        char c = expr[i];
        if (c == '(' || c == '[' || c == '{') {
            depth++;
        } else if ((c == ')' || c == ']' || c == '}') && depth > 0) {
            depth--;
        }
        if (c == ',' && depth == 0) {
            args.push_back(cur);
            cur.clear();
            continue;
        }
        if (c == ')' && depth == 0) {
            args.push_back(cur);
            break;
        }
        cur.push_back(c);
    }
    std::vector<std::string> types;
    size_t start = dollar + 1;
    while (start <= callee.size()) {
        size_t next = callee.find('$', start);
        if (next == std::string::npos) {
            types.push_back(callee.substr(start));
            break;
        }
        types.push_back(callee.substr(start, next - start));
        start = next + 1;
    }
    if (args.size() != types.size()) {
        return expr;
    }
    for (size_t i = 0; i < args.size(); ++i) {
        std::string arg = args[i];
        arg.erase(0, arg.find_first_not_of(" \t"));
        arg.erase(arg.find_last_not_of(" \t") + 1);
        auto it = substTypes.find(arg);
        if (it != substTypes.end() && !it->second.empty()) {
            types[i] = sanitizeHashSignaturePart(it->second);
        }
    }
    std::string out = callee.substr(0, dollar);
    for (const auto& typ : types) {
        out += "$";
        out += typ;
    }
    out += expr.substr(open);
    return out;
}

static void appendDefinition(P4VerifyOptions* options,
                             const std::string& lhs,
                             const std::string& rhs,
                             const std::set<std::string>& deps,
                             const std::string& context) {
    if (options == nullptr || lhs.empty() || rhs.empty()) {
        return;
    }
    for (const auto& existing : options->index_definitions) {
        const std::string target = existing.target_var ? existing.target_var.c_str() : "";
        const std::string expr = existing.expr ? existing.expr.c_str() : "";
        const std::string ctx = existing.context ? existing.context.c_str() : "";
        if (target == lhs && expr == rhs && ctx == context) {
            return;
        }
    }
    P4VerifyOptions::IndexDefinition def;
    def.target_var = cstring(lhs);
    def.expr = cstring(rhs);
    for (const auto& dep : deps) {
        def.deps.push_back(cstring(dep));
    }
    def.context = cstring(context);
    options->index_definitions.push_back(def);
}

static std::string localIndexAlias(const std::string& name) {
    static const char* prefixes[] = {
        "MyIngress_",
        "MyEgress_",
        "SwitchIngress_",
        "SwitchEgress_",
    };
    for (const char* prefix : prefixes) {
        const std::string p(prefix);
        if (name.rfind(p, 0) == 0 && name.size() > p.size()) {
            return name.substr(p.size());
        }
    }
    return "";
}

static void appendDefinitionWithAliases(P4VerifyOptions* options,
                                        const std::string& lhs,
                                        const std::string& rhs,
                                        const std::set<std::string>& deps,
                                        const std::string& context) {
    appendDefinition(options, lhs, rhs, deps, context);
    const std::string alias = localIndexAlias(lhs);
    if (!alias.empty() && isIndexDefinitionTarget(alias)) {
        appendDefinition(options, alias, rhs, deps, context);
    }
}

static bool renderV1ModelHashDefinition(const IR::MethodCallExpression* mce,
                                        P4::ReferenceMap* refMap,
                                        const std::unordered_map<std::string, std::string>* renames,
                                        std::string* lhs,
                                        std::string* rhs,
                                        std::set<std::string>* deps) {
    if (mce == nullptr || mce->arguments == nullptr || mce->arguments->size() < 5 ||
        lhs == nullptr || rhs == nullptr || deps == nullptr) {
        return false;
    }

    std::string method;
    if (!idxDefDirectMethodName(mce->method, method)) {
        return false;
    }
    const size_t dot = method.rfind('.');
    const std::string methodBase = dot == std::string::npos ? method : method.substr(dot + 1);
    if (methodBase != "hash") {
        return false;
    }

    const IR::Expression* outExpr = (*mce->arguments)[0]->expression;
    if (!idxDefExtractVarPath(outExpr, refMap, renames, *lhs) || !isIndexDefinitionTarget(*lhs)) {
        return false;
    }

    std::string resultType = boogieType(outExpr ? outExpr->type : nullptr, refMap);
    if (resultType.empty()) {
        resultType = "bv32";
    }

    std::string algorithm;
    if (!renderExpr((*mce->arguments)[1]->expression, refMap, renames, &algorithm, nullptr)) {
        algorithm = idxDefExprFallbackText((*mce->arguments)[1]->expression);
        if (algorithm.empty()) {
            return false;
        }
    }
    algorithm = normalizeV1ModelHashAlgorithm(sanitizeHashSignaturePart(algorithm));

    std::vector<std::string> args;
    std::vector<std::string> argTypes;
    auto renderBoundArg = [&](const IR::Expression* expr) -> bool {
        std::string rendered;
        if (!renderExpr(expr, refMap, renames, &rendered, nullptr)) {
            return false;
        }
        if (auto c = idxDefStripCasts(expr)->to<IR::Constant>()) {
            std::stringstream ss;
            ss << c->value;
            if (resultType.rfind("bv", 0) == 0) {
                rendered = ss.str() + resultType;
            }
        }
        args.push_back(rendered);
        argTypes.push_back(resultType);
        return true;
    };

    if (!renderBoundArg((*mce->arguments)[2]->expression)) {
        return false;
    }
    if (!renderHashData((*mce->arguments)[3]->expression, renames, refMap, &args, &argTypes)) {
        return false;
    }
    if (!renderBoundArg((*mce->arguments)[4]->expression)) {
        return false;
    }

    std::string callee = "hash_" + algorithm;
    for (const auto& typ : argTypes) {
        callee += "$";
        callee += sanitizeHashSignaturePart(typ);
    }

    *rhs = callee + "(";
    for (size_t i = 0; i < args.size(); ++i) {
        if (i != 0) {
            *rhs += ", ";
        }
        *rhs += args[i];
    }
    *rhs += ")";

    idxDefCollectVarPaths((*mce->arguments)[2]->expression, refMap, renames, deps);
    idxDefCollectVarPaths((*mce->arguments)[3]->expression, refMap, renames, deps);
    idxDefCollectVarPaths((*mce->arguments)[4]->expression, refMap, renames, deps);
    return true;
}

class IndexDefCollector : public Inspector {
 public:
    P4VerifyOptions* options;
    P4::ReferenceMap* refMap;
    std::vector<std::string> contexts;
    std::vector<std::string> actionStack;
    std::unordered_map<std::string, std::string> renames;
    std::unordered_map<std::string, std::vector<std::string>> actionParams;
    std::unordered_map<std::string, std::unordered_map<std::string, std::string>> actionParamTypes;
    std::unordered_map<std::string, std::vector<DefinitionSummary>> actionDefinitions;

    explicit IndexDefCollector(P4VerifyOptions* opt, P4::ReferenceMap* refs)
        : options(opt), refMap(refs) {}

    void recordRename(const IR::IDeclaration* decl) {
        if (decl == nullptr) {
            return;
        }
        cstring cp = decl->controlPlaneName();
        if (cp.isNullOrEmpty()) {
            return;
        }
        std::string sanitized = idxDefSanitizeDeclName(cp.c_str());
        std::string orig = decl->getName().name.c_str();
        if (!sanitized.empty() && sanitized != orig) {
            renames[orig] = sanitized;
        }
    }

    bool preorder(const IR::Declaration_Instance* inst) override {
        recordRename(inst);
        return true;
    }

    bool preorder(const IR::P4Control* control) override {
        recordRename(control);
        if (control != nullptr) {
            for (auto local : control->controlLocals) {
                if (auto inst = local->to<IR::Declaration_Instance>()) {
                    recordRename(inst);
                } else if (auto action = local->to<IR::P4Action>()) {
                    recordRename(action);
                } else if (auto table = local->to<IR::P4Table>()) {
                    recordRename(table);
                }
            }
        }
        contexts.push_back(control ? control->name.toString().c_str() : "");
        return true;
    }

    void postorder(const IR::P4Control* /*control*/) override {
        if (!contexts.empty()) {
            contexts.pop_back();
        }
    }

    bool preorder(const IR::P4Action* action) override {
        recordRename(action);
        std::string actionName = action ? action->name.toString().c_str() : "";
        auto itRename = renames.find(actionName);
        if (itRename != renames.end()) {
            actionName = itRename->second;
        }
        contexts.push_back(actionName);
        actionStack.push_back(actionName);
        std::vector<std::string> params;
        if (action != nullptr && action->parameters != nullptr) {
            std::unordered_map<std::string, std::string> paramTypes;
            for (auto parameter : action->parameters->parameters) {
                if (parameter != nullptr) {
                    std::string name = parameter->name.name.c_str();
                    params.push_back(name);
                    std::string typ = boogieType(parameter->type, refMap);
                    paramTypes[name] = typ;
                    paramTypes[stripTrailingNumericSuffix(name)] = typ;
                }
            }
            actionParamTypes[actionName] = paramTypes;
        }
        actionParams[actionName] = params;
        return true;
    }

    void postorder(const IR::P4Action* /*action*/) override {
        if (!contexts.empty()) {
            contexts.pop_back();
        }
        if (!actionStack.empty()) {
            actionStack.pop_back();
        }
    }

    bool preorder(const IR::ParserState* state) override {
        contexts.push_back(state ? state->name.toString().c_str() : "");
        return true;
    }

    void postorder(const IR::ParserState* /*state*/) override {
        if (!contexts.empty()) {
            contexts.pop_back();
        }
    }

    bool preorder(const IR::AssignmentStatement* stmt) override {
        if (stmt == nullptr || options == nullptr) {
            return true;
        }
        std::string lhs;
        if (!idxDefExtractVarPath(stmt->left, refMap, &renames, lhs) ||
            !isIndexDefinitionTarget(lhs)) {
            return true;
        }
        std::string rhs;
        if (!renderExpr(stmt->right, refMap, &renames, &rhs, nullptr)) {
            return true;
        }
        std::set<std::string> deps;
        idxDefCollectVarPaths(stmt->right, refMap, &renames, &deps);
        const std::string ctx = contexts.empty() ? "" : contexts.back();
        appendDefinitionWithAliases(options, lhs, rhs, deps, ctx);
        if (!actionStack.empty()) {
            DefinitionSummary summary;
            summary.target = lhs;
            summary.expr = rhs;
            summary.deps = deps;
            summary.context = ctx;
            summary.paramTypes = actionParamTypes[actionStack.back()];
            actionDefinitions[actionStack.back()].push_back(summary);
        }
        return true;
    }

    bool preorder(const IR::MethodCallStatement* stmt) override {
        if (stmt == nullptr || stmt->methodCall == nullptr || options == nullptr) {
            return true;
        }
        std::string hashLhs;
        std::string hashRhs;
        std::set<std::string> hashDeps;
        if (renderV1ModelHashDefinition(
                stmt->methodCall, refMap, &renames, &hashLhs, &hashRhs, &hashDeps)) {
            const std::string ctx = contexts.empty() ? "" : contexts.back();
            appendDefinitionWithAliases(options, hashLhs, hashRhs, hashDeps, ctx);
            if (!actionStack.empty()) {
                DefinitionSummary summary;
                summary.target = hashLhs;
                summary.expr = hashRhs;
                summary.deps = hashDeps;
                summary.context = ctx;
                summary.paramTypes = actionParamTypes[actionStack.back()];
                actionDefinitions[actionStack.back()].push_back(summary);
            }
            return true;
        }
        if (!actionStack.empty()) {
            return true;
        }
        std::string actionName;
        if (!idxDefExtractVarPath(stmt->methodCall->method, refMap, &renames, actionName) ||
            actionName.empty()) {
            return true;
        }
        auto itDefs = actionDefinitions.find(actionName);
        if (itDefs == actionDefinitions.end() || itDefs->second.empty()) {
            return true;
        }
        if (stmt->methodCall->arguments == nullptr) {
            return true;
        }

        const auto itParam = actionParams.find(actionName);
        if (itParam == actionParams.end()) {
            return true;
        }
        std::vector<std::string> params = itParam->second;
        if (params.empty()) {
            return true;
        }

        std::unordered_map<std::string, std::string> subst;
        size_t n = std::min(params.size(), stmt->methodCall->arguments->size());
        for (size_t i = 0; i < n; ++i) {
            const IR::Argument* arg = stmt->methodCall->arguments->at(i);
            if (arg == nullptr || arg->expression == nullptr) {
                continue;
            }
            std::string rendered;
            if (renderExpr(arg->expression, refMap, &renames, &rendered, nullptr)) {
                subst[params[i]] = rendered;
                subst[stripTrailingNumericSuffix(params[i])] = rendered;
            }
        }
        if (subst.empty()) {
            return true;
        }
        const std::string callCtx = contexts.empty() ? "" : contexts.back();
        for (const auto& def : itDefs->second) {
            std::set<std::string> deps;
            for (const auto& dep : def.deps) {
                auto it = subst.find(dep);
                deps.insert(it == subst.end() ? dep : it->second);
            }
            std::string expr = substituteIdentifierTokens(def.expr, subst);
            std::unordered_map<std::string, std::string> substTypes;
            for (const auto& kv : subst) {
                auto itTyp = def.paramTypes.find(kv.first);
                if (itTyp != def.paramTypes.end() && !itTyp->second.empty()) {
                    substTypes[kv.second] = itTyp->second;
                }
            }
            expr = rewriteHashSignatureTypes(expr, substTypes);
            const std::string ctx = callCtx.empty() ? def.context : callCtx + "." + def.context;
            appendDefinitionWithAliases(options, def.target, expr, deps, ctx);
        }
        return true;
    }
};

}  // namespace

void analyzeIndexDefinitions(const IR::P4Program* program,
                             P4::ReferenceMap* refMap,
                             P4::TypeMap* /*typeMap*/,
                             P4VerifyOptions* options) {
    if (program == nullptr || options == nullptr) {
        return;
    }
    IndexDefCollector collector(options, refMap);
    program->apply(collector);
}

}  // namespace P4Verify
