// Post-slicing monotonic/wraparound analysis for stateful P4 registers.
//
// Goal (v0): Identify register updates that look like an affine step on some variable:
//   x := x + k
//   x := x - k
// and record when such a variable is written back to a register.
//
// This is intentionally conservative and syntactic (IR-level), but avoids brittle
// Boogie-text parsing in downstream tooling.

#include "backends/verify/analysis/monotonic.h"

#include <algorithm>
#include <cctype>
#include <sstream>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "backends/verify/translate/options.h"
#include "ir/visitor.h"

namespace P4Verify {

namespace {

static std::string toLower(std::string s) {
    for (auto& c : s) {
        c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    }
    return s;
}

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
    if (out.empty()) {
        return out;
    }
    if (out[0] >= '0' && out[0] <= '9') {
        out.insert(out.begin(), '_');
    }
    return out;
}

static std::string baseTypeName(const IR::Type* type) {
    if (type == nullptr) {
        return "";
    }
    if (auto typeName = type->to<IR::Type_Name>()) {
        return typeName->path->name.toString().c_str();
    }
    if (auto typeSpec = type->to<IR::Type_Specialized>()) {
        if (auto base = typeSpec->baseType->to<IR::Type_Name>()) {
            return base->path->name.toString().c_str();
        }
    }
    if (auto typeSpec = type->to<IR::Type_SpecializedCanonical>()) {
        if (auto base = typeSpec->baseType->to<IR::Type_Name>()) {
            return base->path->name.toString().c_str();
        }
    }
    if (auto typeExtern = type->to<IR::Type_Extern>()) {
        return typeExtern->name.toString().c_str();
    }
    return "";
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

static bool isConstIndex(const IR::Expression* expr, int& out) {
    expr = stripCasts(expr);
    if (expr == nullptr) {
        return false;
    }
    if (auto c = expr->to<IR::Constant>()) {
        if (c->value >= 0 && c->value <= std::numeric_limits<int>::max()) {
            out = static_cast<int>(c->value);
            return true;
        }
    }
    return false;
}

static bool extractVarPath(const IR::Expression* expr, std::string& out) {
    expr = stripCasts(expr);
    if (expr == nullptr) {
        return false;
    }
    if (auto pe = expr->to<IR::PathExpression>()) {
        out = pe->path->name.toString().c_str();
        return true;
    }
    if (auto mem = expr->to<IR::Member>()) {
        std::string base;
        if (!extractVarPath(mem->expr, base)) {
            return false;
        }
        out = base;
        out.push_back('.');
        out += mem->member.toString().c_str();
        return true;
    }
    if (auto ai = expr->to<IR::ArrayIndex>()) {
        std::string base;
        if (!extractVarPath(ai->left, base)) {
            return false;
        }
        int idx = -1;
        if (isConstIndex(ai->right, idx)) {
            out = base;
            out.push_back('.');
            out += std::to_string(idx);
            return true;
        }
        // Non-constant index: do not treat as a stable dotted var.
        return false;
    }
    return false;
}

static void collectVarPaths(const IR::Expression* expr, std::unordered_set<std::string>& out) {
    expr = stripCasts(expr);
    if (expr == nullptr) {
        return;
    }

    std::string var;
    if (extractVarPath(expr, var)) {
        out.insert(var);
        return;
    }

    if (auto bin = expr->to<IR::Operation_Binary>()) {
        collectVarPaths(bin->left, out);
        collectVarPaths(bin->right, out);
        return;
    }
    if (auto un = expr->to<IR::Operation_Unary>()) {
        collectVarPaths(un->expr, out);
        return;
    }
    if (auto sl = expr->to<IR::Slice>()) {
        collectVarPaths(sl->e0, out);
        return;
    }
    if (auto mce = expr->to<IR::MethodCallExpression>()) {
        if (mce->method) {
            collectVarPaths(mce->method, out);
        }
        if (mce->arguments) {
            for (auto arg : *mce->arguments) {
                if (arg && arg->expression) {
                    collectVarPaths(arg->expression, out);
                }
            }
        }
        return;
    }
    if (auto list = expr->to<IR::ListExpression>()) {
        for (auto comp : list->components) {
            collectVarPaths(comp, out);
        }
        return;
    }
    // Fallback: nothing to collect.
}

struct RegInfo {
    std::string internal_name;
    std::string boogie_name;
    int value_width = -1;
    int index_width = 32;
};

static int typeBitWidth(const IR::Type* type) {
    if (type == nullptr) {
        return -1;
    }
    if (auto bits = type->to<IR::Type_Bits>()) {
        return bits->size;
    }
    return -1;
}

static bool extractBvExprString(const IR::Expression* expr, std::string& out) {
    expr = stripCasts(expr);
    if (expr == nullptr) {
        return false;
    }
    std::string var;
    if (extractVarPath(expr, var)) {
        out = var;
        return true;
    }
    if (auto c = expr->to<IR::Constant>()) {
        const int w = typeBitWidth(c->type);
        if (w <= 0) {
            return false;
        }
        std::stringstream ss;
        ss << c->value;
        out = ss.str();
        out += "bv";
        out += std::to_string(w);
        return true;
    }
    if (auto concat = expr->to<IR::Concat>()) {
        std::string left;
        std::string right;
        if (!extractBvExprString(concat->left, left)) {
            return false;
        }
        if (!extractBvExprString(concat->right, right)) {
            return false;
        }
        out = left;
        out += "++";
        out += right;
        return true;
    }
    return false;
}

static int registerValueWidth(const IR::Declaration_Instance* inst) {
    if (inst == nullptr || inst->type == nullptr) {
        return -1;
    }
    auto typeSpec = inst->type->to<IR::Type_Specialized>();
    if (typeSpec == nullptr || typeSpec->arguments == nullptr || typeSpec->arguments->empty()) {
        return -1;
    }
    return typeBitWidth((*typeSpec->arguments)[0]);
}

static int registerIndexWidth(const IR::Declaration_Instance* inst) {
    if (inst == nullptr || inst->type == nullptr) {
        return 32;
    }
    auto typeSpec = inst->type->to<IR::Type_Specialized>();
    if (typeSpec == nullptr || typeSpec->arguments == nullptr) {
        return 32;
    }
    if (typeSpec->arguments->size() >= 2) {
        int w = typeBitWidth((*typeSpec->arguments)[1]);
        if (w > 0) {
            return w;
        }
    }
    return 32;
}

static bool isRegisterInstance(const IR::Declaration_Instance* inst) {
    if (inst == nullptr || inst->type == nullptr) {
        return false;
    }
    std::string base = toLower(baseTypeName(inst->type));
    return base.find("register") != std::string::npos;
}

static std::string controlPlaneNameOrEmpty(const IR::IDeclaration* decl) {
    if (decl == nullptr) {
        return "";
    }
    cstring cpn = decl->controlPlaneName();
    if (cpn.isNullOrEmpty()) {
        return "";
    }
    return cpn.c_str();
}

struct UpdateInfo {
    std::string op;  // "add" | "sub"
    bool delta_is_const = false;
    std::string delta_const_dec;
    bool delta_is_odd = false;
};

static bool containsVarPath(const IR::Expression* expr, const IR::Expression* needle) {
    if (expr == nullptr || needle == nullptr) {
        return false;
    }
    expr = stripCasts(expr);
    needle = stripCasts(needle);
    if (expr == nullptr || needle == nullptr) {
        return false;
    }
    if (expr->equiv(*needle)) {
        return true;
    }
    if (auto bin = expr->to<IR::Operation_Binary>()) {
        return containsVarPath(bin->left, needle) || containsVarPath(bin->right, needle);
    }
    if (auto un = expr->to<IR::Operation_Unary>()) {
        return containsVarPath(un->expr, needle);
    }
    if (auto sl = expr->to<IR::Slice>()) {
        return containsVarPath(sl->e0, needle);
    }
    if (auto mce = expr->to<IR::MethodCallExpression>()) {
        if (mce->arguments) {
            for (auto arg : *mce->arguments) {
                if (arg && containsVarPath(arg->expression, needle)) {
                    return true;
                }
            }
        }
        return false;
    }
    if (auto list = expr->to<IR::ListExpression>()) {
        for (auto comp : list->components) {
            if (containsVarPath(comp, needle)) {
                return true;
            }
        }
        return false;
    }
    return false;
}

static bool matchAffineSelfUpdate(const IR::Expression* lhs,
                                  const IR::Expression* rhs,
                                  UpdateInfo& out) {
    lhs = stripCasts(lhs);
    rhs = stripCasts(rhs);
    if (lhs == nullptr || rhs == nullptr) {
        return false;
    }

    const IR::Expression* delta = nullptr;
    const char* op = nullptr;

    if (auto add = rhs->to<IR::Add>()) {
        const IR::Expression* a = stripCasts(add->left);
        const IR::Expression* b = stripCasts(add->right);
        if (a && b) {
            if (a->equiv(*lhs)) {
                delta = b;
                op = "add";
            } else if (b->equiv(*lhs)) {
                delta = a;
                op = "add";
            }
        }
    } else if (auto sub = rhs->to<IR::Sub>()) {
        const IR::Expression* a = stripCasts(sub->left);
        const IR::Expression* b = stripCasts(sub->right);
        if (a && b && a->equiv(*lhs)) {
            delta = b;
            op = "sub";
        }
    }

    if (delta == nullptr || op == nullptr) {
        return false;
    }

    // Reject x := x + f(x) style updates (non-affine in x).
    if (containsVarPath(delta, lhs)) {
        return false;
    }

    out.op = op;
    out.delta_is_const = false;
    out.delta_const_dec.clear();
    out.delta_is_odd = false;

    if (auto c = stripCasts(delta)->to<IR::Constant>()) {
        out.delta_is_const = true;
        std::stringstream ss;
        ss << c->value;
        out.delta_const_dec = ss.str();
        out.delta_is_odd = ((c->value & 1) != 0);
    }
    return true;
}

static void dedupAndAppendRegisterInfo(P4VerifyOptions* options, const RegInfo& info) {
    if (options == nullptr) {
        return;
    }
    for (const auto& r : options->wraparound_registers) {
        if (r.internal_name && info.internal_name == r.internal_name.c_str()) {
            return;
        }
    }
    P4VerifyOptions::WraparoundRegisterInfo out;
    out.internal_name = cstring(info.internal_name);
    out.boogie_name = cstring(info.boogie_name);
    out.value_width = info.value_width;
    out.index_width = info.index_width;
    options->wraparound_registers.push_back(out);
}

static void collectActionUpdates(const IR::P4Action* action,
                                 const std::unordered_map<std::string, RegInfo>& regs,
                                 P4VerifyOptions* options) {
    if (action == nullptr || action->body == nullptr || options == nullptr) {
        return;
    }

    std::unordered_map<std::string, UpdateInfo> varUpdates;
    std::unordered_set<std::string> emitted;

    std::function<void(const IR::Statement*)> visitStmt = [&](const IR::Statement* stmt) {
        if (stmt == nullptr) {
            return;
        }
        if (auto block = stmt->to<IR::BlockStatement>()) {
            for (auto comp : block->components) {
                if (auto s = comp->to<IR::Statement>()) {
                    visitStmt(s);
                }
            }
            return;
        }
        if (auto ifs = stmt->to<IR::IfStatement>()) {
            visitStmt(ifs->ifTrue);
            visitStmt(ifs->ifFalse);
            return;
        }
        if (auto sw = stmt->to<IR::SwitchStatement>()) {
            for (auto c : sw->cases) {
                if (c && c->statement) {
                    visitStmt(c->statement);
                }
            }
            return;
        }
        if (auto as = stmt->to<IR::AssignmentStatement>()) {
            std::string lhsVar;
            if (!extractVarPath(as->left, lhsVar)) {
                return;
            }
            UpdateInfo ui;
            if (matchAffineSelfUpdate(as->left, as->right, ui)) {
                varUpdates[lhsVar] = ui;
            }
            return;
        }
        if (auto mcs = stmt->to<IR::MethodCallStatement>()) {
            auto mce = mcs->methodCall;
            if (!mce || !mce->method) {
                return;
            }
            auto member = mce->method->to<IR::Member>();
            if (!member) {
                return;
            }
            if (member->member != "write") {
                return;
            }
            std::string objVar;
            if (!extractVarPath(member->expr, objVar) || objVar.empty()) {
                return;
            }
            std::string regName = objVar;
            const auto dot = regName.find_last_of('.');
            if (dot != std::string::npos) {
                regName = regName.substr(dot + 1);
            }
            auto itReg = regs.find(regName);
            if (itReg == regs.end()) {
                return;
            }
            if (!mce->arguments || mce->arguments->size() < 2) {
                return;
            }
            const IR::Expression* idxExpr = (*mce->arguments)[0]->expression;
            const IR::Expression* valExpr = (*mce->arguments)[1]->expression;
            if (idxExpr == nullptr || valExpr == nullptr) {
                return;
            }

            std::string valVar;
            if (!extractVarPath(valExpr, valVar)) {
                return;
            }
            auto itUp = varUpdates.find(valVar);
            if (itUp == varUpdates.end()) {
                return;
            }

            std::unordered_set<std::string> idxVars;
            collectVarPaths(idxExpr, idxVars);
            std::vector<std::string> idxVarsSorted(idxVars.begin(), idxVars.end());
            std::sort(idxVarsSorted.begin(), idxVarsSorted.end());

            int idxConst = -1;
            (void)isConstIndex(idxExpr, idxConst);
            std::string idxExprStr;
            const bool hasIdxExpr = extractBvExprString(idxExpr, idxExprStr);

            const auto& regInfo = itReg->second;
            const auto& u = itUp->second;

            std::string key = regInfo.boogie_name + "|" + valVar + "|" + u.op + "|" + u.delta_const_dec;
            if (emitted.count(key)) {
                return;
            }
            emitted.insert(key);

            P4VerifyOptions::WraparoundUpdate upd;
            upd.reg_internal = cstring(regInfo.internal_name);
            upd.reg_boogie = cstring(regInfo.boogie_name);
            for (const auto& v : idxVarsSorted) {
                upd.idx_vars.push_back(cstring(v));
            }
            upd.idx_const = idxConst;
            if (hasIdxExpr) {
                upd.idx_expr = cstring(idxExprStr);
            }
            upd.value_var = cstring(valVar);
            upd.op = cstring(u.op);
            upd.delta_is_const = u.delta_is_const;
            if (u.delta_is_const) {
                upd.delta_const = cstring(u.delta_const_dec);
                upd.delta_is_odd = u.delta_is_odd;
            }
            upd.value_width = regInfo.value_width;
            upd.index_width = regInfo.index_width;
            upd.context = action->name.toString();
            options->wraparound_updates.push_back(upd);
            return;
        }
    };

    visitStmt(action->body);
}

}  // namespace

void analyzeWraparoundMonotonicity(const IR::P4Program* program,
                                   P4::ReferenceMap* /*refMap*/,
                                   P4::TypeMap* /*typeMap*/,
                                   P4VerifyOptions* options) {
    if (program == nullptr || options == nullptr) {
        return;
    }

    std::unordered_map<std::string, RegInfo> regs;
    std::unordered_set<std::string> usedTargets;

    // 1) Collect register instances and a stable (control-plane) name.
    class RegCollector : public Inspector {
     public:
        std::unordered_map<std::string, RegInfo>* regs;
        std::unordered_set<std::string>* usedTargets;
        P4VerifyOptions* options;
        explicit RegCollector(std::unordered_map<std::string, RegInfo>* r,
                              std::unordered_set<std::string>* used,
                              P4VerifyOptions* opt)
            : regs(r), usedTargets(used), options(opt) {}

        bool preorder(const IR::Declaration_Instance* inst) override {
            if (!isRegisterInstance(inst) || regs == nullptr) {
                return false;
            }
            std::string internal = inst->name.name.c_str();

            std::string cp = controlPlaneNameOrEmpty(inst);
            std::string boogie = internal;
            if (!cp.empty()) {
                std::string sanitized = sanitizeDeclName(cp);
                if (!sanitized.empty() && usedTargets->count(sanitized) == 0) {
                    boogie = sanitized;
                    usedTargets->insert(sanitized);
                }
            }

            RegInfo info;
            info.internal_name = internal;
            info.boogie_name = boogie;
            info.value_width = registerValueWidth(inst);
            info.index_width = registerIndexWidth(inst);
            (*regs)[internal] = info;
            if (internal.size() > 2 && internal.rfind("_0") == internal.size() - 2) {
                const std::string alt = internal.substr(0, internal.size() - 2);
                if (!alt.empty() && regs->count(alt) == 0) {
                    (*regs)[alt] = info;
                }
            }
            dedupAndAppendRegisterInfo(options, info);
            return false;
        }
    };

    RegCollector rc(&regs, &usedTargets, options);
    program->apply(rc);

    // 2) Scan actions for affine self-updates that are written back to registers.
    class ActionCollector : public Inspector {
     public:
        const std::unordered_map<std::string, RegInfo>* regs;
        P4VerifyOptions* options;
        explicit ActionCollector(const std::unordered_map<std::string, RegInfo>* r,
                                 P4VerifyOptions* opt)
            : regs(r), options(opt) {}
        bool preorder(const IR::P4Action* action) override {
            if (regs && options) {
                collectActionUpdates(action, *regs, options);
            }
            return false;
        }
    };

    ActionCollector ac(&regs, options);
    program->apply(ac);
}

}  // namespace P4Verify
