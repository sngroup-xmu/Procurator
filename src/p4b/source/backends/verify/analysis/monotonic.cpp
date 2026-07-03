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
#include <functional>
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
    return base == "register";
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

struct RegisterActionSummary {
    std::string reg_name;
    std::string action_boogie_name;
    UpdateInfo update;
    int value_width = -1;
    int index_width = 32;
    bool direct = false;
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

static void collectAffineRegisterWrites(const IR::Statement* body,
                                        const std::string& context,
                                        const std::unordered_map<std::string, RegInfo>& regs,
                                        P4VerifyOptions* options) {
    if (body == nullptr || options == nullptr) {
        return;
    }

    std::unordered_map<std::string, int> registerWriteCounts;

    std::function<void(const IR::Statement*)> countRegisterWrites = [&](const IR::Statement* stmt) {
        if (stmt == nullptr) {
            return;
        }
        if (auto block = stmt->to<IR::BlockStatement>()) {
            for (auto comp : block->components) {
                if (auto s = comp->to<IR::Statement>()) {
                    countRegisterWrites(s);
                }
            }
            return;
        }
        if (auto ifs = stmt->to<IR::IfStatement>()) {
            countRegisterWrites(ifs->ifTrue);
            countRegisterWrites(ifs->ifFalse);
            return;
        }
        if (auto sw = stmt->to<IR::SwitchStatement>()) {
            for (auto c : sw->cases) {
                if (c && c->statement) {
                    countRegisterWrites(c->statement);
                }
            }
            return;
        }
        auto mcs = stmt->to<IR::MethodCallStatement>();
        if (mcs == nullptr || mcs->methodCall == nullptr || mcs->methodCall->method == nullptr) {
            return;
        }
        auto member = mcs->methodCall->method->to<IR::Member>();
        if (member == nullptr || member->member != "write") {
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
        registerWriteCounts[itReg->second.boogie_name]++;
    };
    countRegisterWrites(body);

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
            UpdateInfo u;
            bool haveUpdate = false;

            // Preferred pattern (v0): a temp var is updated in-place and then written back:
            //   x := x + k;
            //   reg.write(idx, x);
            if (extractVarPath(valExpr, valVar)) {
                auto itUp = varUpdates.find(valVar);
                if (itUp != varUpdates.end()) {
                    u = itUp->second;
                    haveUpdate = true;
                }
            }

            // Also accept direct affine writes without an intermediate assignment:
            //   reg.write(idx, x + k);
            // This occurs in some DistCache components (e.g., cache_frequency).
            if (!haveUpdate) {
                const IR::Expression* ve = stripCasts(valExpr);
                const IR::Expression* delta = nullptr;
                const IR::Expression* base = nullptr;
                const char* op = nullptr;

                if (auto add = ve ? ve->to<IR::Add>() : nullptr) {
                    const IR::Expression* a = stripCasts(add->left);
                    const IR::Expression* b = stripCasts(add->right);
                    if (a && b) {
                        // Identify (var + const) or (const + var).
                        if (a->to<IR::Constant>() && extractVarPath(b, valVar)) {
                            base = b;
                            delta = a;
                            op = "add";
                        } else if (b->to<IR::Constant>() && extractVarPath(a, valVar)) {
                            base = a;
                            delta = b;
                            op = "add";
                        }
                    }
                } else if (auto sub = ve ? ve->to<IR::Sub>() : nullptr) {
                    const IR::Expression* a = stripCasts(sub->left);
                    const IR::Expression* b = stripCasts(sub->right);
                    // Identify (var - const).
                    if (a && b && b->to<IR::Constant>() && extractVarPath(a, valVar)) {
                        base = a;
                        delta = b;
                        op = "sub";
                    }
                }

                if (base && delta && op) {
                    UpdateInfo ui;
                    ui.op = op;
                    ui.delta_is_const = false;
                    ui.delta_const_dec.clear();
                    ui.delta_is_odd = false;
                    if (auto c = stripCasts(delta)->to<IR::Constant>()) {
                        ui.delta_is_const = true;
                        std::stringstream ss;
                        ss << c->value;
                        ui.delta_const_dec = ss.str();
                        ui.delta_is_odd = ((c->value & 1) != 0);
                    }
                    if (ui.delta_is_const) {
                        u = ui;
                        haveUpdate = true;
                    }
                }
            }

            if (!haveUpdate) {
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
            auto countIt = registerWriteCounts.find(regInfo.boogie_name);
            if (countIt == registerWriteCounts.end() || countIt->second != 1) {
                // Multiple writes in the same action/control may reset or overwrite the
                // affine update, so the block is not a steady one-step pump.
                return;
            }

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
            upd.context = cstring(context);
            options->wraparound_updates.push_back(upd);
            return;
        }
    };

    visitStmt(body);
}

static void collectActionUpdates(const IR::P4Action* action,
                                 const std::unordered_map<std::string, RegInfo>& regs,
                                 P4VerifyOptions* options) {
    if (action == nullptr || action->body == nullptr || options == nullptr) {
        return;
    }
    collectAffineRegisterWrites(action->body, std::string(action->name.toString().c_str()), regs, options);
}

static const IR::Function* findMonotonicRegisterActionApply(const IR::Declaration_Instance* inst) {
    if (inst == nullptr || inst->initializer == nullptr) {
        return nullptr;
    }
    if (auto block = inst->initializer->to<IR::BlockStatement>()) {
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

static bool isRegisterActionInstance(const IR::Declaration_Instance* inst, bool& direct) {
    direct = false;
    if (inst == nullptr || inst->type == nullptr) {
        return false;
    }
    std::string base = baseTypeName(inst->type);
    if (base == "DirectRegisterAction") {
        direct = true;
        return true;
    }
    if (base == "RegisterAction") {
        return true;
    }
    return false;
}

static bool summarizeRegisterAction(const IR::Declaration_Instance* inst,
                                    RegisterActionSummary& out) {
    bool direct = false;
    if (!isRegisterActionInstance(inst, direct)) {
        return false;
    }
    if (inst->arguments == nullptr || inst->arguments->empty()) {
        return false;
    }
    const IR::Expression* regExpr = (*inst->arguments)[0]->expression;
    if (!extractVarPath(regExpr, out.reg_name) || out.reg_name.empty()) {
        return false;
    }
    const auto dot = out.reg_name.find_last_of('.');
    if (dot != std::string::npos) {
        out.reg_name = out.reg_name.substr(dot + 1);
    }

    out.direct = direct;
    if (auto typeSpec = inst->type->to<IR::Type_Specialized>()) {
        if (typeSpec->arguments != nullptr) {
            if (typeSpec->arguments->size() >= 1) {
                out.value_width = typeBitWidth((*typeSpec->arguments)[0]);
            }
            if (typeSpec->arguments->size() >= 2) {
                int w = typeBitWidth((*typeSpec->arguments)[1]);
                if (w > 0) {
                    out.index_width = w;
                }
            }
        }
    }

    const IR::Function* apply = findMonotonicRegisterActionApply(inst);
    if (apply == nullptr || apply->type == nullptr || apply->type->parameters == nullptr ||
        apply->body == nullptr || apply->type->parameters->parameters.empty()) {
        return false;
    }
    const auto* valueParam = apply->type->parameters->parameters.at(0);
    if (valueParam == nullptr) {
        return false;
    }
    const std::string valueParamName = valueParam->name.name.c_str();
    if (valueParamName.empty()) {
        return false;
    }

    bool found = false;
    int valueParamAssignments = 0;
    int affineAssignments = 0;
    int nonAffineSelfDependentAssignments = 0;
    bool sawAffineBeforeNonAffine = false;
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
            if (!extractVarPath(as->left, lhsVar) || lhsVar != valueParamName) {
                return;
            }
            valueParamAssignments++;
            UpdateInfo ui;
            if (matchAffineSelfUpdate(as->left, as->right, ui)) {
                affineAssignments++;
                out.update = ui;
                found = true;
                return;
            }
            if (containsVarPath(as->right, as->left)) {
                nonAffineSelfDependentAssignments++;
                return;
            }
            if (found) {
                sawAffineBeforeNonAffine = true;
            }
        }
    };
    visitStmt(apply->body);
    if (!found || affineAssignments != 1) {
        return false;
    }
    if (nonAffineSelfDependentAssignments != 0) {
        return false;
    }
    if (sawAffineBeforeNonAffine) {
        return false;
    }
    return valueParamAssignments >= 1;
}

static void addRegisterActionSummaryAliases(
    std::unordered_map<std::string, RegisterActionSummary>& summaries,
    const IR::Declaration_Instance* inst,
    const RegisterActionSummary& summary) {
    if (inst == nullptr) {
        return;
    }
    RegisterActionSummary canonical = summary;
    std::string cp = controlPlaneNameOrEmpty(inst);
    if (!cp.empty()) {
        canonical.action_boogie_name = sanitizeDeclName(cp);
    }
    if (canonical.action_boogie_name.empty()) {
        canonical.action_boogie_name = inst->name.name.c_str();
    }

    auto add = [&](const std::string& name) {
        if (!name.empty()) {
            summaries[name] = canonical;
            if (name.size() > 2 && name.rfind("_0") == name.size() - 2) {
                summaries[name.substr(0, name.size() - 2)] = canonical;
            }
        }
    };

    add(inst->name.name.c_str());

    if (!cp.empty()) {
        std::string sanitized = sanitizeDeclName(cp);
        add(sanitized);
        const auto dot = cp.find_last_of('.');
        if (dot != std::string::npos && dot + 1 < cp.size()) {
            add(cp.substr(dot + 1));
        }
        const auto us = sanitized.find_last_of('_');
        if (us != std::string::npos && us + 1 < sanitized.size()) {
            add(sanitized.substr(us + 1));
        }
    }
}

static void emitRegisterActionExecuteUpdates(
    const IR::P4Control* control,
    const std::unordered_map<std::string, RegInfo>& regs,
    const std::unordered_map<std::string, RegisterActionSummary>& summaries,
    P4VerifyOptions* options) {
    if (control == nullptr || options == nullptr || summaries.empty()) {
        return;
    }

    std::unordered_set<std::string> emitted;

    class ExecuteCollector : public Inspector {
     public:
        const std::unordered_map<std::string, RegInfo>* regs;
        const std::unordered_map<std::string, RegisterActionSummary>* summaries;
        P4VerifyOptions* options;
        std::unordered_set<std::string>* emitted;
        explicit ExecuteCollector(const std::unordered_map<std::string, RegInfo>* r,
                                  const std::unordered_map<std::string, RegisterActionSummary>* s,
                                  P4VerifyOptions* opt,
                                  std::unordered_set<std::string>* e)
            : regs(r), summaries(s), options(opt), emitted(e) {}

        bool preorder(const IR::MethodCallExpression* mce) override {
            if (mce == nullptr || mce->method == nullptr || regs == nullptr ||
                summaries == nullptr || options == nullptr || emitted == nullptr) {
                return false;
            }
            auto member = mce->method->to<IR::Member>();
            if (member == nullptr || (member->member != "execute" && member->member != "execute_log")) {
                return true;
            }
            std::string actionName;
            if (!extractVarPath(member->expr, actionName) || actionName.empty()) {
                return true;
            }
            const auto dot = actionName.find_last_of('.');
            if (dot != std::string::npos) {
                actionName = actionName.substr(dot + 1);
            }
            auto itSummary = summaries->find(actionName);
            if (itSummary == summaries->end() && actionName.size() > 2 &&
                actionName.rfind("_0") == actionName.size() - 2) {
                itSummary = summaries->find(actionName.substr(0, actionName.size() - 2));
            }
            if (itSummary == summaries->end()) {
                return true;
            }
            const RegisterActionSummary& summary = itSummary->second;
            auto itReg = regs->find(summary.reg_name);
            if (itReg == regs->end()) {
                return true;
            }

            const IR::Expression* idxExpr = nullptr;
            if (!summary.direct) {
                if (mce->arguments == nullptr || mce->arguments->empty()) {
                    return true;
                }
                idxExpr = (*mce->arguments)[0]->expression;
            }
            if (idxExpr == nullptr) {
                return true;
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
            std::string valueBase = summary.action_boogie_name.empty() ? actionName : summary.action_boogie_name;
            std::string valueVar = "__ra_ret_" + valueBase;
            std::string key = regInfo.boogie_name + "|" + actionName + "|" + idxExprStr +
                "|" + summary.update.op + "|" + summary.update.delta_const_dec;
            if (emitted->count(key) > 0) {
                return true;
            }
            emitted->insert(key);

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
            upd.value_var = cstring(valueVar);
            upd.op = cstring(summary.update.op);
            upd.delta_is_const = summary.update.delta_is_const;
            if (summary.update.delta_is_const) {
                upd.delta_const = cstring(summary.update.delta_const_dec);
                upd.delta_is_odd = summary.update.delta_is_odd;
            }
            upd.value_width = regInfo.value_width > 0 ? regInfo.value_width : summary.value_width;
            upd.index_width = regInfo.index_width > 0 ? regInfo.index_width : summary.index_width;
            upd.context = cstring(actionName);
            options->wraparound_updates.push_back(upd);
            return true;
        }
    };

    ExecuteCollector collector(&regs, &summaries, options, &emitted);
    control->apply(collector);
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

    // 2) Summarize TNA RegisterAction bodies, then scan controls for execute(index).
    // This covers programs like Flowrest/ETC where the read-modify-write is encoded
    // as `RegisterAction(reg).apply(inout x) { x = x + k; ... }` plus `ra.execute(idx)`.
    std::unordered_map<std::string, RegisterActionSummary> registerActionSummaries;
    class RegisterActionCollector : public Inspector {
     public:
        std::unordered_map<std::string, RegisterActionSummary>* summaries;
        explicit RegisterActionCollector(std::unordered_map<std::string, RegisterActionSummary>* s)
            : summaries(s) {}
        bool preorder(const IR::Declaration_Instance* inst) override {
            if (summaries == nullptr) {
                return false;
            }
            RegisterActionSummary summary;
            if (!summarizeRegisterAction(inst, summary)) {
                return false;
            }
            addRegisterActionSummaryAliases(*summaries, inst, summary);
            return false;
        }
    };

    RegisterActionCollector rac(&registerActionSummaries);
    program->apply(rac);

    class ControlCollector : public Inspector {
     public:
        const std::unordered_map<std::string, RegInfo>* regs;
        const std::unordered_map<std::string, RegisterActionSummary>* summaries;
        P4VerifyOptions* options;
        explicit ControlCollector(const std::unordered_map<std::string, RegInfo>* r,
                                  const std::unordered_map<std::string, RegisterActionSummary>* s,
                                  P4VerifyOptions* opt)
            : regs(r), summaries(s), options(opt) {}
        bool preorder(const IR::P4Control* control) override {
            if (regs && summaries && options) {
                emitRegisterActionExecuteUpdates(control, *regs, *summaries, options);
            }
            return true;
        }
    };

    ControlCollector cc(&regs, &registerActionSummaries, options);
    program->apply(cc);

    // 3) Scan ordinary actions and control apply blocks for affine self-updates that are
    // written back to registers.  Some v1model programs perform read-modify-write
    // directly in `apply` instead of wrapping it in an action.
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

    class ControlApplyCollector : public Inspector {
     public:
        const std::unordered_map<std::string, RegInfo>* regs;
        P4VerifyOptions* options;
        explicit ControlApplyCollector(const std::unordered_map<std::string, RegInfo>* r,
                                       P4VerifyOptions* opt)
            : regs(r), options(opt) {}
        bool preorder(const IR::P4Control* control) override {
            if (regs && options && control != nullptr && control->body != nullptr) {
                collectAffineRegisterWrites(control->body, std::string(control->name.toString().c_str()), *regs, options);
            }
            return true;
        }
    };

    ControlApplyCollector cac(&regs, options);
    program->apply(cac);
}

}  // namespace P4Verify
