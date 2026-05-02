#include "slicer_internal.h"

#include <cctype>
#include <fstream>

namespace P4Verify {
namespace slicing_internal {

namespace {

std::string dotEscape(const std::string& s) {
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

std::string joinParts(const std::vector<std::string>& parts, const std::string& sep) {
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

std::string exprLabel(const IR::Expression* expr) {
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

std::string stmtLabel(const IR::Statement* stmt) {
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

}  // namespace

std::string dotSafeName(const std::string& s) {
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

void writeDotGraph(const std::string& path,
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

}  // namespace slicing_internal
}  // namespace P4Verify
