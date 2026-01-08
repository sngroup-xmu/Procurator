// ControlFlowExtractor.cpp

#include "control_flow_extractor.h"
#include "nlohmann/json.hpp"
#include <p4/methodInstance.h>
#include <algorithm>
#include <queue>
#include <regex>


namespace Utils {
    cstring translateExpression(const IR::Argument *argument) {
        return translateExpression(argument->expression);
    }

    // 将 IR 表达式转换为字符串表示形式
    cstring translateExpression(const IR::Expression* expr) {
        if (expr == nullptr) return "";
        // 处理各种表达式类型
        if (auto literal = expr->to<IR::Literal>()) {
            std::string str{literal->toString()};
            // 匹配类似 "8w17" 的模式
            std::regex r("(\\d+)w(\\d+)");
            std::smatch match;
            if (std::regex_match(str, match, r)) {
                // match[2] 为数值部分
                return match[2].str().c_str();
            }
            return str.c_str();
        }

        if (auto pathExpr = expr->to<IR::PathExpression>()) {
            std::string val{expr->toString()};
            std::regex mac_regex("^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$");
            if (std::regex_match(val, mac_regex)) {
                // 将MAC地址转为0xAABBCCDDEEFF形式
                for (auto &c : val) c = (char)toupper((unsigned char)c);
                std::string hexStr = "0x";
                // 去掉冒号
                for (char c : val) {
                    if (c != ':') hexStr.push_back(c);
                }
                return hexStr.c_str();
            }
            return pathExpr->path->toString();
        }

        if (auto member = expr->to<IR::Member>()) {
            // 特殊处理特定成员函数
            if (member->member.toString() == "extract")
                return "packet_in.extract";
            if (member->member.toString() == "lookahead")
                return "lookahead";
            if (member->member.toString() == "setValid")
                return "setValid(" + translateExpression(member->expr) + ")";
            if (member->member.toString() == "setInvalid")
                return "setInvalid(" + translateExpression(member->expr) + ")";

            // 默认情况：路径.成员
            auto result = translateExpression(member->expr) + "." + member->member.toString();
            return result;
        }
        if (auto binaryExpr = expr->to<IR::Operation_Binary>()) {
            cstring op;
            if (expr->is<IR::Add>()) op = " + ";
            else if (expr->is<IR::Sub>()) op = " - ";
            else if (expr->is<IR::Mul>()) op = " * ";
            else if (expr->is<IR::Div>()) op = " / ";
            else if (expr->is<IR::Equ>()) op = " == ";
            else if (expr->is<IR::Neq>()) op = " != ";
            else if (expr->is<IR::Lss>()) op = " < ";
            else if (expr->is<IR::Leq>()) op = " <= ";
            else if (expr->is<IR::Grt>()) op = " > ";
            else if (expr->is<IR::Geq>()) op = " >= ";
            else if (expr->is<IR::LAnd>()) op = " && ";
            else if (expr->is<IR::LOr>()) op = " || ";
            else if (expr->is<IR::BAnd>()) op = " & ";
            else if (expr->is<IR::BOr>()) op = " | ";
            else if (expr->is<IR::BXor>()) op = " ^ ";
            else {
                // 如果遇到未知的操作符，不使用 "?" 替代，直接报错或原样返回
                ::warning("Unknown binary operation encountered, returning original toString()");
                return expr->toString();
            }
            return "(" + translateExpression(binaryExpr->left) + op + translateExpression(binaryExpr->right) + ")";
        }
        if (auto unaryExpr = expr->to<IR::Operation_Unary>()) {
            cstring op;
            if (expr->is<IR::Neg>()) op = "-";
            else if (expr->is<IR::LNot>()) op = "!";
            else return translateExpression(unaryExpr->expr);
            return op + translateExpression(unaryExpr->expr);
        }
        if (auto methodCall = expr->to<IR::MethodCallExpression>()) {
            cstring method = translateExpression(methodCall->method);

            std::cout << "method: " << method << std::endl;
            bool isRead = method.find(".read");
            bool isWrite = method.find(".write");

            if (isRead) {
                if (methodCall->arguments->size() != 2) {
                    ::error("寄存器read调用参数不正确");
                    return "";
                }

                // 从method中提取寄存器名
                std::string methodStr = method.c_str();
                std::size_t pos = methodStr.find(".read");
                cstring regName = methodStr.substr(0, pos).c_str(); // 提取出形如"sequence_reg"

                cstring destVar = getFullVariableName(methodCall->arguments->at(0)->expression);
                cstring idxVar = getFullVariableName(methodCall->arguments->at(1)->expression);

                // std::cout << "translate Reg Expression =======================================" << std::endl;
                std::stringstream ss;
                ss << destVar << " = " << regName << "["  << "];";
                return ss.str();
            }

            if (isWrite) {
                if (methodCall->arguments->size() != 2) {
                    ::error("寄存器write调用参数不正确");
                    return "";
                }

                std::string methodStr = method.c_str();
                std::size_t pos = methodStr.find(".write");
                cstring regName = methodStr.substr(0, pos).c_str(); // 提取出形如"sequence_reg"

                cstring idxVar = getFullVariableName(methodCall->arguments->at(0)->expression);
                cstring valVar = getFullVariableName(methodCall->arguments->at(1)->expression);
                // std::cout << "translate Reg Expression =======================================" << std::endl;

                std::stringstream ss;
                ss << regName << "[" << idxVar << "] = " << valVar << ";";
                return ss.str();
            }

            // 如果不是read/write寄存器操作，则当作普通方法调用处理
            std::stringstream ss;
            ss << method << "(";
            bool first = true;
            for (auto arg : *methodCall->arguments) {
                if (!first) ss << ", ";
                ss << translateExpression(arg->expression);
                first = false;
            }
            ss << ");";
            return ss.str();
        }

        if (auto cast = expr->to<IR::Cast>()) {
            return "(" + cast->type->toString() + ") " + translateExpression(cast->expr);
        }
        if (auto arrayIndex = expr->to<IR::ArrayIndex>()) {
            return translateExpression(arrayIndex->left) + "[" + translateExpression(arrayIndex->right) + "]";
        }
        if (auto slice = expr->to<IR::Slice>()) {
            return translateExpression(slice->e0) + "[" + translateExpression(slice->e1) + ":" + translateExpression(slice->e2) + "]";
        }
        if (auto listExpr = expr->to<IR::ListExpression>()) {
            std::stringstream ss;
            ss << "{";
            bool first = true;
            for (const auto& component : listExpr->components) {
                if (!first) ss << ", ";
                ss << translateExpression(component);
                first = false;
            }
            ss << "}";
            return ss.str();
        }

        // 默认情况下，直接调用 toString()
        return expr->toString();
    }

    cstring translateType(const IR::Type* type) {
        if (auto typeBits = type->to<IR::Type_Bits>()) {
            return "bit<" + std::to_string(typeBits->size) + ">";
        }
        if (auto typeVarbits = type->to<IR::Type_Varbits>()) {
            return "bit<" + std::to_string(typeVarbits->size) + ">";
        }
        if (auto typeName = type->to<IR::Type_Name>()) {
            return typeName->path->name.name;
        }
        if (auto typeList = type->to<IR::Type_List>()) {
            return "array<" + translateType(typeList->getP4Type()) + ", " + typeList->size() + ">";
        }
        if (auto typeSpecialized = type->to<IR::Type_Specialized>()) {
            // 处理特殊类型，如 register
            std::string baseType{translateType(typeSpecialized->baseType)};
            std::string args = "";
            for(auto arg : *typeSpecialized->arguments) {
                if(!args.empty()) args += ", ";
                args += translateType(arg);
            }
            return baseType + "<" + args + ">";
        }
        // 其他类型的处理... todo

        // 默认返回类型的字符串表示
        return type->toString();
    }

    // 翻译其他方法调用（非寄存器）
    cstring translateMethodCall(const IR::MethodCallExpression* methodCall) {
        std::stringstream ss;
        ss << translateExpression(methodCall->method) << "(";

        bool first = true;
        for (const auto& arg : *methodCall->arguments) {
            if (!first) ss << ", ";
            ss << translateExpression(arg->expression);
            first = false;
        }
        ss << ")";
        return ss.str();
    }

    cstring getMethodName(const IR::MethodCallExpression* methodCall) {
        if (auto member = methodCall->method->to<IR::Member>()) {
            return member->member.toString();
        }
        if (auto path = methodCall->method->to<IR::PathExpression>()) {
            return path->path->name.name;
        }
        return "";
    }

    // 获取表达式中的完整变量名
    cstring getFullVariableName(const IR::Expression* expr) {
        if (expr == nullptr) return "";

        if (auto pathExpr = expr->to<IR::PathExpression>()) {
            return pathExpr->path->name.name;
        }
        if (auto member = expr->to<IR::Member>()) {
            cstring fieldName = member->member.name;
            bool isPopFront   = std::string{fieldName}.find("pop_front") != std::string::npos;
            bool isIsValid    = std::string{fieldName}.find("isValid")   != std::string::npos;
            bool isSetValid   = std::string{fieldName}.find("setValid")  != std::string::npos;
            bool isSetInvalid = std::string{fieldName}.find("setInvalid") != std::string::npos;

            if (isIsValid || isSetValid || isSetInvalid) {
                // 对于这些内建函数的调用，可能不希望把它当做一个“变量”。
                // 那么就只返回它的“前缀表达式”
                return getFullVariableName(member->expr) + ".valid";
            }
            if (isPopFront) {
                return getFullVariableName(member->expr);
            }
        }
        if (auto arrayIndex = expr->to<IR::ArrayIndex>()) {
            cstring leftName = getFullVariableName(arrayIndex->left);

            cstring rightName;
            const IR::Expression* right = arrayIndex->right;
            if (auto p = right->to<IR::PathExpression>()) {
                rightName = getFullVariableName(p);
            } else if (auto lit = right->to<IR::Literal>()) {
                rightName = lit->toString();
            } else if (auto cst = right->to<IR::Cast>()) {
                // 忽略cast，直接对cst->expr递归
                rightName = getFullVariableName(cst->expr);
            } else if (auto mem = right->to<IR::Member>()) {
                rightName = getFullVariableName(mem);
            } else if (auto binExpr = right->to<IR::Operation_Binary>()) {
                // 如有必要，对二元表达式尝试获取名称(通常不应当出现在变量名中)
                // 简单处理：使用toString()或进行更深分析
                // 为简化，这里直接toString()，如果不期望如此，则需额外逻辑
                rightName = binExpr->toString();
            } else {
                // fallback: 避免translateExpression，尽可能直接使用toString()
                rightName = right->toString();
            }

            return leftName + "[" + rightName + "]";
        }
        if (auto slice = expr->to<IR::Slice>()) {
            // 同arrayIndex类似处理
            cstring baseName = getFullVariableName(slice->e0);
            cstring startName = getFullVariableName(slice->e1);
            cstring endName = getFullVariableName(slice->e2);
            return baseName + "[" + startName + ":" + endName + "]";
        }
        if (auto cast = expr->to<IR::Cast>()) {
            // 忽略类型信息，对cast->expr递归获取名称
            return getFullVariableName(cast->expr);
        }

        // 对于其他情况(如Literal、MethodCall、ListExpression等)，
        // Literal如果是纯数字可直接使用toString(), 不是纯数字则可返回本身或空字符串
        // MethodCall在变量名中不太合理出现，通常不会作为纯变量
        if (auto lit = expr->to<IR::Literal>()) {
            return lit->toString();
        }
        // fallback:
        return expr->toString();
    }

    void extractUsedVariables(const IR::Expression* expr, std::set<cstring>& useVars) {
        if (expr == nullptr) return;

        // 若 expr 是 PathExpression
        if (auto pathExpr = expr->to<IR::PathExpression>()) {
            cstring varName = getFullVariableName(pathExpr);
            // 如果是常量或关键字，不加入 useVars
            if (!isConstant(varName) && !isKeyword(varName) && !isLiteralConstant(varName)) {
                useVars.insert(varName);
            }
        }
        // 若 expr 是 Member
        else if (auto member = expr->to<IR::Member>()) {
            cstring fullName = getFullVariableName(member);
            if (!isConstant(fullName) && !isKeyword(fullName) && !isLiteralConstant(fullName)) {
                useVars.insert(fullName);
            }
            // 不再递归检查 member->expr，因为 getFullVariableName 已处理
        }
        // 若 expr 是 ArrayIndex
        else if (auto arrayIndex = expr->to<IR::ArrayIndex>()) {
            // 1) 将完整 "sequence_reg[meta.location.index]" 插入 useVars
            cstring fullName = getFullVariableName(arrayIndex);
            useVars.insert(fullName);

            // 2) 继续递归 index(右边) 以获取 "meta.location.index" 的潜在成员
            //    同理左边也可以递归, 如果您希望把 baseName 也拆分的话
            extractUsedVariables(arrayIndex->left, useVars);
            extractUsedVariables(arrayIndex->right, useVars);
        }
        else if (auto slice = expr->to<IR::Slice>()) {
            cstring fullName = getFullVariableName(slice);
            if (!isConstant(fullName) && !isKeyword(fullName) && !isLiteralConstant(fullName)) {
                useVars.insert(fullName);
            }
        }
        else if (auto binaryExpr = expr->to<IR::Operation_Binary>()) {
            extractUsedVariables(binaryExpr->left, useVars);
            extractUsedVariables(binaryExpr->right, useVars);
        }
        else if (auto unaryExpr = expr->to<IR::Operation_Unary>()) {
            extractUsedVariables(unaryExpr->expr, useVars);
        }
        else if (auto methodCall = expr->to<IR::MethodCallExpression>()) {
            // 先提取 method
            extractUsedVariables(methodCall->method, useVars);
            // 再提取参数
            for (const auto& arg : *methodCall->arguments) {
                extractUsedVariables(arg->expression, useVars);
            }
        }
        else if (auto cast = expr->to<IR::Cast>()) {
            extractUsedVariables(cast->expr, useVars);
        }
        else if (auto listExpr = expr->to<IR::ListExpression>()) {
            for (const auto& component : listExpr->components) {
                extractUsedVariables(component, useVars);
            }
        }
        else if (auto namedExp = expr->to<IR::NamedExpression>()) {
            extractUsedVariables(namedExp->expression, useVars);
        }
    }

    bool isLiteralConstant(const cstring &str) {
        // MAC 形如 0xAABBCCDDEEFF
        std::regex mac_hex_regex("^0x[0-9A-Fa-f]+$");
        // IPv4 形如 "10.0.100.2"
        std::regex ip_dot_regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$");

        if (std::regex_match((const char*)str, mac_hex_regex)) {
            return true;
        }
        if (std::regex_match((const char*)str, ip_dot_regex)) {
            return true;
        }
        // 如果只是纯数字
        if (isConstant(str)) {
            return true;
        }
        return false;
    }

    // 检查字符串是否为关键字
    bool isKeyword(const cstring& str) {
        static std::set<cstring> keywords = {"if", "else", "return", "exit", "switch", "case", "default"};
        return keywords.find(str) != keywords.end();
    }

    // 检查字符串是否为常量（仅由数字组成）
    bool isConstant(const cstring& str) {
        return std::all_of(str.begin(), str.end(), ::isdigit);
    }

    // 检查字符串是否为变量
    bool isVariable(const cstring& str) {
        return !isConstant(str) && !isKeyword(str);
    }

    // 从字符串表达式中提取使用的变量
    void extractUsedVariablesFromString(const cstring& exprStr, std::set<cstring>& useVars) {
        std::string exprStdStr = exprStr.c_str();
        // 修改后的正则，允许'.'出现在变量名中
        std::regex varRegex("[a-zA-Z_][a-zA-Z0-9_\\.]*");
        auto wordsBegin = std::sregex_iterator(exprStdStr.begin(), exprStdStr.end(), varRegex);
        auto wordsEnd = std::sregex_iterator();

        for (auto it = wordsBegin; it != wordsEnd; ++it) {
            std::string varNameStr = it->str();
            cstring varName = varNameStr.c_str();
            if (isVariable(varName)) {
                // 如果 varName 全是数字则跳过
                if (!isConstant(varName) && !isKeyword(varName)) {
                    useVars.insert(varName);
                }
            }
        }
    }
}

// 构造函数
ControlFlowExtractor::ControlFlowExtractor(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                                           P4VerifyOptions& options, BMV2CmdsAnalyzer* bMV2CmdsAnalyzer)
    : dataEdges(), options(options), refMap(refMap), typeMap(typeMap), bMV2CmdsAnalyzer(bMV2CmdsAnalyzer),
      currentControl(nullptr), nextNodeId(0), currentNodeId(-1) {
    this->visitDagOnce = false;

    int entryNodeId = addNode("ENTER", NodeType::ENTRY, nullptr);
    pushCurrentNode(entryNodeId);
    currentNodeId = entryNodeId;
}

bool ControlFlowExtractor::preorder(const IR::P4Program* program) {
    if (switchFuncPosiLog)
        std::cout << "ControlFlowExtractor::preorder(const IR::P4Program* program)" << std::endl;
    for (auto obj : program->objects) {
        if (auto declInstance = obj->to<IR::Declaration_Instance>()) {
            visit(declInstance);  // 调用到下面的 `preorder(const IR::Declaration_Instance*)`
        }
    }
    buildPipelineInternals(program);
    int exitNodeId = addNode("EXIT Program", NodeType::EXIT, nullptr);
    addEdge(currentNodeId, exitNodeId, "Program Exit", "sequential");
    currentNodeId = exitNodeId;
    programExitNodeId = exitNodeId;
    if (isRecirculate || isMirror || isResubmit) {
        addEdge(currentNodeId, 0, "Program fallback",  "sequential");
    }
    addEdge(currentNodeId, 0, "Program fallback",  "sequential");


    return false;
}

bool ControlFlowExtractor::preorder(const IR::P4Control* control) {
    if (switchFuncPosiLog)
        std::cout << "ControlFlowExtractor::preorder(const IR::P4Control* control)" << std::endl;
    // 创建 “control MyControl”的节点
    cstring controlName = control->name.name;
    int controlNodeId = addNode("control " + controlName,
                                NodeType::CONTROL,  // 或者你自己定义 NodeType::CONTROL
                                control,
                                "control " + controlName);

    // 让当前图上的节点连到这个 control 节点
    addEdge(currentNodeId, controlNodeId, "", "sequential");
    addControlEdge(nodeStack.top(), controlNodeId, controlName, "control");;
    pushCurrentNode(controlNodeId);
    currentNodeId = controlNodeId;

    irNodeIds[currentNodeId].insert(control->id);

    // 然后遍历control里面的内容。例如control->body
    // 在 p4c 中, IR::P4Control的主体是 control->body (一个 IR::BlockStatement)
    for (auto obj : *control->getDeclarations()) {
        if (auto decl = obj->to<IR::Declaration_Instance>()) {
            visit(decl);
        }
        if (auto decl = obj->to<IR::Declaration_Variable>()) {
            visit(decl);
        }
    }

    if (control->body != nullptr) {
        visit(control->body);  // 这里就会调用写好的 "preorder(const IR::BlockStatement*)" 等
    }

    popCurrentNode();
    int controlExitNodeId = addNode("control exit " + controlName,
                                NodeType::EXIT,  // 或者你自己定义 NodeType::CONTROL
                                control,
                                "control " + controlName);
    addEdge(currentNodeId,controlExitNodeId,"control " + controlName + " exit", "sequential");
    currentNodeId = controlExitNodeId;

    return false;
}

bool ControlFlowExtractor::preorder(const IR::P4Parser* parser) {
    cstring parserName = parser->name.name;

    // === 修复点 A：为parser节点入栈，并把它设为当前节点 ===
    int parserNodeId = addNode(
        "parser " + parserName,
        NodeType::PARSER,
        parser,
        "parser " + parserName);

    addEdge(currentNodeId, parserNodeId, "", "sequential");
    addControlEdge(nodeStack.top(), parserNodeId, parserName, "control");

    pushCurrentNode(parserNodeId);
    currentNodeId = parserNodeId;
    irNodeIds[currentNodeId].insert(parser->id);

    // 清空临时信息
    parserStateInfoMap.clear();
    currentParserTransitions.clear();
    acceptNodeId = -1;
    rejectNodeId = -1;

    // === 1) 访问所有 states（包含 "start", "parse_ethernet", "parse_ipv4", etc.）===
    for (auto st : parser->states) {
        visit(st);
    }

    // === 2) 访问 parser->parserLocals（如果有）===
    for (auto decl : parser->parserLocals) {
        visit(decl);
    }

    // === 3) 在此阶段，把 parserNodeId -> "start" 连接起来 ===
    // 确保只有在所有 parserState 都创建并存放在 parserStateInfoMap 后，才做此连接
    {
        auto itStart = parserStateInfoMap.find("start");
        if (itStart == parserStateInfoMap.end()) {
            ::warning("No 'start' state found in parser '%1%'", parserName);
        } else {
            int startNodeId = itStart->second.startNodeId;
            addEdge(parserNodeId, startNodeId, "parse state start", "sequential");
            addControlEdge(parserNodeId, startNodeId, "start", "control");
        }
    }

    // === 4) 构建 transitions (fromState -> toState)===
    for (auto &tr : currentParserTransitions) {
        auto fit = parserStateInfoMap.find((std::string)tr.fromState);
        if (fit == parserStateInfoMap.end()) {
            ::warning("fromState %1% not found", tr.fromState);
            continue;
        }
        int fromExit = fit->second.exitNodeId;
        // 如果有 condNodeId，则用它，否则用 fromExit
        int realFrom = (tr.fromCaseNodeId >= 0) ? tr.fromCaseNodeId : fromExit;

        // 分情况连接到 accept/reject 或其他状态
        if (tr.toState == "accept") {
            if (acceptNodeId >= 0) {
                addEdge(realFrom, acceptNodeId, tr.label, "sequential");
                addControlEdge(realFrom, acceptNodeId, tr.label, "control");
            }
        } else if (tr.toState == "reject") {
            if (rejectNodeId >= 0) {
                addEdge(realFrom, rejectNodeId, tr.label, "sequential");
                addControlEdge(realFrom, rejectNodeId, tr.label, "control");
            }
        } else {
            // 普通状态
            auto tit = parserStateInfoMap.find((std::string)tr.toState);
            if (tit == parserStateInfoMap.end()) {
                ::warning("toState %1% not found", tr.toState);
                continue;
            }
            int toStart = tit->second.startNodeId;
            addEdge(realFrom, toStart, tr.label, "sequential");
            addControlEdge(realFrom, toStart, tr.label, "control");
            std::cout << "from: " << nodes[realFrom].name << ", to: " << nodes[toStart].name << std::endl;
        }
    }

    // === 5) 为 parser 创建出口节点，并连接 accept/reject ===
    int parserExitNodeId = addNode(
        "parser exit " + parserName,
        NodeType::EXIT,
        parser,
        "parser exit");
    if (acceptNodeId >= 0) {
        addEdge(acceptNodeId, parserExitNodeId, "parseExit", "sequential");
    }
    if (rejectNodeId >= 0) {
        addEdge(rejectNodeId, parserExitNodeId, "parseReject", "sequential");
    }

    // === 出栈，返回新的 currentNode ===
    popCurrentNode();
    currentNodeId = parserExitNodeId;
    return false;
}

bool ControlFlowExtractor::preorder(const IR::ParserState* state) {
    cstring sName = state->name.name;

    // 1) 创建当前解析状态的节点
    int startNodeId = addNode(
        "ParserState " + sName,
        NodeType::PARSE_STATE,
        state,
        "State " + sName + " enter");

    currentNodeId = startNodeId;
    irNodeIds[startNodeId].insert(state->id);
    addControlEdge(nodeStack.top(), startNodeId, sName, "control");
    pushCurrentNode(startNodeId);

    // 如果是 accept/reject，记录ID即可
    if (sName == "accept") {
        acceptNodeId = startNodeId;
        parserStateInfoMap[std::string{sName}] = {startNodeId, startNodeId};
        currentNodeId = startNodeId;
        return false;
    }
    if (sName == "reject") {
        rejectNodeId = startNodeId;
        parserStateInfoMap[std::string{sName}] = {startNodeId, startNodeId};
        currentNodeId = startNodeId;
        return false;
    }

    // 2) 处理 state->components
    int lastStmtNodeId = startNodeId;
    for (auto stmt : state->components) {
        visit(stmt);
        lastStmtNodeId = currentNodeId;
    }

    // 默认 exitNodeId
    int exitNodeId = lastStmtNodeId;

    // 3) 处理 selectExpression
    const IR::Expression* selExpr = state->selectExpression;
    if (selExpr) {
        std::cout << "sName: " << sName << std::endl;
        if (auto pathExpr = selExpr->to<IR::PathExpression>()) {
            std::cout << "pathExpr->path->name.name: " << pathExpr->path->name.name << std::endl;
            // 无条件跳转
            ParserTransition tr{sName, /*label=*/"", pathExpr->path->name.name, lastStmtNodeId};
            currentParserTransitions.push_back(tr);
        } else if (auto selectExpr = selExpr->to<IR::SelectExpression>()) {
            // 多分支
            std::set<cstring> matchVars;
            Utils::extractUsedVariables(selectExpr->select, matchVars);

            for (auto sc : selectExpr->selectCases) {
                cstring caseLabel = Utils::translateExpression(sc->keyset);

                int condNodeId = addNode(
                    "Case: " + caseLabel,
                    NodeType::CONDITION,
                    sc->keyset,
                    "Case " + caseLabel);

                // 绑定用到的变量
                for (auto &v : matchVars) {
                    nodes[condNodeId].useVars.insert(v);
                }
                Utils::extractUsedVariables(sc->keyset, nodes[condNodeId].useVars);

                // lastStmtNodeId -> condNodeId
                addEdge(lastStmtNodeId, condNodeId, caseLabel, "sequential");
                addControlEdge(lastStmtNodeId, condNodeId, caseLabel, "control");

                cstring toStateName;
                if (auto pathNext = sc->state->to<IR::PathExpression>()) {
                    toStateName = pathNext->path->name.name;
                } else {
                    ::warning("selectCase->state not PathExpression in state %1%", sName);
                }

                // 记录转换
                ParserTransition t{sName, caseLabel, toStateName, condNodeId};
                currentParserTransitions.push_back(t);
            }
        }
    }
    // 4) 记录 startNodeId, exitNodeId
    parserStateInfoMap[std::string{sName}] = {startNodeId, exitNodeId};
    popCurrentNode();
    // 更新 currentNodeId
    currentNodeId = exitNodeId;
    return false;
}


// 添加节点到控制流图
int ControlFlowExtractor::addNode(cstring name, NodeType type, const IR::Node* irNode, cstring code) {
    int nodeId = nextNodeId++;
    CFGNode node = {nodeId, name, type, irNode, code};
    nodes[nodeId] = node;
    // std::cout << "添加节点: " << name << "，ID: " << nodeId << std::endl;
    return nodeId;
}

// 添加边到控制流图
void ControlFlowExtractor::addEdge(int fromNodeId, int toNodeId, cstring label, cstring type) {
    CFGEdge edge = {fromNodeId, toNodeId, "sequential", label};
    edges.push_back(edge);
    // std::cout << "添加边，从 " << fromNodeId << " 到 " << toNodeId << "，标签: " << label << std::endl;
}

void ControlFlowExtractor::addControlEdge(int fromNodeId, int toNodeId, cstring label, cstring type) {
    CFGEdge edge = {fromNodeId, toNodeId, "control", label};
    edges.push_back(edge);
    // std::cout << "添加边，从 " << fromNodeId << " 到 " << toNodeId << "，标签: " << label << std::endl;
}

// 压入当前节点到堆栈并更新 currentNodeId
void ControlFlowExtractor::pushCurrentNode(int nodeId) {
    nodeStack.push(nodeId);
}

// 从堆栈弹出当前节点并恢复 currentNodeId
void ControlFlowExtractor::popCurrentNode() {
    if (!nodeStack.empty()) {
        nodeStack.pop();
    } else {
        ::error("节点堆栈下溢：在没有匹配的推送操作时调用了 popCurrentNode。");
    }
}


bool ControlFlowExtractor::isPersistentVar(const cstring &varName) const {
    // 1) 判断是否以 "hdr." 开头
    if (varName.size() >= 4 && std::string{varName}.compare(0, 4, "hdr.") == 0) {
        return true;
    }

    // 2) 判断是否引用了某个寄存器
    // 假设 registerInfo.name 就是类似 "sequence_reg_0", "value_reg_0" 之类
    for (auto &reg : registers) {
        // 如果 varName 字串中含有 reg.name，就认为它是寄存器相关
        // 也可以更严谨一些，如一定要匹配 `reg.name + "["` 或 `reg.name + "."` 等
        if (varName.find(reg.name.c_str())) {
            return true;
        }
    }

    return false;
}

void ControlFlowExtractor::buildDataDependenciesSingleRound(bool withExitToEntry) {
    // 准备 RDin / RDout
    std::unordered_map<int, std::unordered_set<Definition, DefinitionHash, DefinitionEq>> RDin, RDout;
    // 初始化
    for (auto &kv : nodes) {
        RDin[kv.first].clear();
        RDout[kv.first].clear();
    }

    // 做一次 RD 分析
    computeReachingDefinitions(withExitToEntry, RDin, RDout);

    // 根据 RDin + “最前面”规则，生成 dataEdges
    generateDataEdgesFromRD(RDin, withExitToEntry);
}

void ControlFlowExtractor::computeReachingDefinitions(
    bool withExitToEntry,
    std::unordered_map<int, std::unordered_set<Definition, DefinitionHash, DefinitionEq>> &RDin,
    std::unordered_map<int, std::unordered_set<Definition, DefinitionHash, DefinitionEq>> &RDout
) {
    // 构建 pred[] adjacency
    std::unordered_map<int, std::vector<int>> pred;
    for (auto &e : edges) {
        if ((e.type == "sequential")) {
            // 若不包含 exit->entry，则跳过之
            if (!withExitToEntry && isExitToEntryEdge(e)) {
                continue;
            }
            pred[e.toNodeId].push_back(e.fromNodeId);
        }
    }

    // 迭代到固定点
    bool changed = true;
    while (changed) {
        changed = false;
        // 遍历所有节点
        for (auto &kv : nodes) {
            int nId = kv.first;
            auto &nObj = kv.second;

            // 1) RDin[n] = union of RDout[p] for all p in pred[n]
            std::unordered_set<Definition, DefinitionHash, DefinitionEq> newRDin;
            if (pred.find(nId) != pred.end()) {
                for (int p : pred[nId]) {
                    for (auto &d : RDout[p]) {
                        newRDin.insert(d);
                    }
                }
            }

            // 2) RDout[n] = (newRDin - kill[n]) union gen[n]
            // 先 copy newRDin
            auto newRDout = newRDin;

            // kill: 对所有本节点 genVars 里的变量 v，要杀死 newRDout 里 (x, v)
            for (auto &v : nObj.genVars) {
                // 收集要删除的
                std::vector<Definition> toRemove;
                for (auto &d : newRDout) {
                    if (d.varName == v) {
                        toRemove.push_back(d);
                    }
                }
                for (auto &del : toRemove) {
                    newRDout.erase(del);
                }
            }

            // gen: 对本节点 genVars 中的每个变量 v，产生 Definition{nId, v}
            for (auto &v : nObj.genVars) {
                Definition df;
                df.defNodeId = nId;
                df.varName   = v;
                newRDout.insert(df);
            }

            // 检查是否变化
            if (newRDin.size() != RDin[nId].size()) {
                changed = true;
            } else {
                // 也可更细粒度检查
                for (auto &dd : newRDin) {
                    if (!RDin[nId].count(dd)) {
                        changed = true; break;
                    }
                }
            }
            if (newRDout.size() != RDout[nId].size()) {
                changed = true;
            } else {
                for (auto &dd : newRDout) {
                    if (!RDout[nId].count(dd)) {
                        changed = true; break;
                    }
                }
            }

            // 更新
            RDin[nId]  = std::move(newRDin);
            RDout[nId] = std::move(newRDout);
        }
    } // while(changed)
}

bool ControlFlowExtractor::isExitToEntryEdge(const CFGEdge &e) {
    auto itFrom = nodes.find(e.fromNodeId);
    auto itTo   = nodes.find(e.toNodeId);
    if (itFrom == nodes.end() || itTo == nodes.end()) return false;

    // 简单示例：如果 fromNode是EXIT && toNode是ENTRY，则视为 exit->entry
    const auto &fromN = itFrom->second;
    const auto &toN   = itTo->second;
    if (fromN.type == NodeType::EXIT && toN.type == NodeType::ENTRY) {
        return true;
    }
    return false;
}

// 根据 RDin，找出 def->use
// 并应用 “id 最大 & IR集合相同” 的筛选
void ControlFlowExtractor::generateDataEdgesFromRD(
    const std::unordered_map<int, std::unordered_set<Definition, DefinitionHash, DefinitionEq>> &RDin,
    bool withExitToEntry  // 新增：标识当前是不是第二轮
) {
    for (auto &kv : nodes) {
        int useId = kv.first;
        const auto &useNode = kv.second;

        const auto &rdinSet = RDin.at(useId);

        for (auto &useVar : useNode.useVars) {
            // 收集所有 defIds
            std::vector<int> defIds;
            for (auto &d : rdinSet) {
                if (d.varName.find(std::string{useVar}) != std::string::npos || useVar.find(d.varName.c_str())) {
                    defIds.push_back(d.defNodeId);
                }
            }
            if (defIds.empty()) {
                continue;
            }

            // 1) 找 id 最大
            int maxId = *std::max_element(defIds.begin(), defIds.end());

            // 2) 取 maxId 的 IR 集合
            const auto &maxIrSet = (irNodeIds.count(maxId) ? irNodeIds.at(maxId) : std::set<int>{});

            // 3) 找 IR 集合相同的
            std::vector<int> frontDefs;
            frontDefs.reserve(defIds.size());
            for (auto did : defIds) {
                const auto &defIrSet = (irNodeIds.count(did) ? irNodeIds.at(did) : std::set<int>{});
                if (defIrSet == maxIrSet) {
                    frontDefs.push_back(did);
                }
            }

            // 4) 依次产出 dataEdges
            for (auto did : frontDefs) {
                if (did == useId) {
                    continue;
                }
                // 如果是第二轮（withExitToEntry = true），并且 (did > useId) => "跨轮"
                //   就只保留 persistent 变量
                bool skipEdge = false;
                if (withExitToEntry && (did > useId)) {
                    // 说明 defId > useId, 可能是 exit->entry 路径 => 跨轮
                    if (!isPersistentVar(useVar)) {
                        // 不是 hdr 或 register => 跳过
                        skipEdge = true;
                    }
                }

                if (!skipEdge) {
                    CFGEdge e;
                    e.fromNodeId = did;
                    e.toNodeId   = useId;
                    e.type       = "data";
                    e.label      = useVar;
                    dataEdges.insert(e);
                }
            }
        }
    }
    if (withExitToEntry) {
        for (int i = 0; i < edges.size(); i++) {
            if (isExitToEntryEdge(edges[i])) {
                std::swap(edges[i], edges[edges.size() - 1]);
                edges.pop_back();
                break;
            }
        }
    }
}


// 构建数据依赖关系
void ControlFlowExtractor::buildDataDependencies() {
    dataEdges.clear(); // 先清空

    // 第1轮：不含 exit->entry
    buildDataDependenciesSingleRound(/*withExitToEntry=*/false);

    // 第2轮：含 exit->entry
    if (isRecirculate || isMirror || isResubmit) {
        buildDataDependenciesSingleRound(/*withExitToEntry=*/true);
    }
    buildDataDependenciesSingleRound(/*withExitToEntry=*/true);

    // dataEdges 里就包含 两轮 综合的结果
    // - 第一轮记录了 单轮 CFG 下的依赖
    // - 第二轮可能多出来一些“跨轮” (exit->entry) 导致的新依赖
}

// 查找动作定义
const IR::P4Action* ControlFlowExtractor::findActionDefinition(cstring actionName) const {
    // 在当前控制块中查找
    if (currentControl != nullptr) {
        for (auto decl : currentControl->controlLocals) {
            if (auto action = decl->to<IR::P4Action>()) {
                if (action->name.name == actionName) {
                    // std::cout << "找到动作定义：" << actionName << std::endl;
                    return action;
                }
            }
        }
    }

    // 在全局作用域中查找
    const IR::P4Program* program = findContext<IR::P4Program>();
    if (program != nullptr) {
        for (auto decl : program->objects) {
            if (auto action = decl->to<IR::P4Action>()) {
                if (action->name.name == actionName) {
                    // std::cout << "找到动作定义：" << actionName << std::endl;
                    return action;
                }
            } else if (auto control = decl->to<IR::P4Control>()) {
                for (auto ctrlDecl : control->controlLocals) {
                    if (auto action = ctrlDecl->to<IR::P4Action>()) {
                        if (action->name.name == actionName) {
                            // std::cout << "找到动作定义：" << actionName << std::endl;
                            return action;
                        }
                    }
                }
            }
        }
    }
    // std::cout << "未找到动作定义：" << actionName << std::endl;
    // 未找到
    return nullptr;
}

void ControlFlowExtractor::outputCFGAsJson(const cstring &basePath) {
    //-------------------------------------------------------
    // 首先，我们收集所有节点到一个通用的 JSON 数组 "nodes"
    //-------------------------------------------------------
    nlohmann::json nodesJson = nlohmann::json::array();
    for (const auto& kv : nodes) {
        const auto& node = kv.second;
        nlohmann::json jNode;
        jNode["id"]   = node.id;
        jNode["name"] = node.name;
        jNode["type"] = nodeTypeToString(node.type);
        jNode["code"] = node.code;

        // genVars
        {
            nlohmann::json arr = nlohmann::json::array();
            for (auto &g : node.genVars) {
                arr.push_back(g);
            }
            jNode["defines"] = arr;
        }
        // uses
        {
            nlohmann::json arr = nlohmann::json::array();
            for (auto &u : node.useVars) {
                arr.push_back(u);
            }
            jNode["uses"] = arr;
        }
        // IR ids
        {
            nlohmann::json arr = nlohmann::json::array();
            if (irNodeIds.find(node.id) != irNodeIds.end()) {
                for (auto &idv : irNodeIds[node.id]) {
                    arr.push_back(idv);
                }
            }
            jNode["ir_ids"] = arr;
        }
        nodesJson.push_back(jNode);
    }

    //-------------------------------------------------------
    // 分别收集三类边：sequential, control, data
    //-------------------------------------------------------
    // 1) sequential
    nlohmann::json edgesSeq = nlohmann::json::array();
    // 2) control
    nlohmann::json edgesCtrl = nlohmann::json::array();
    // 3) data
    nlohmann::json edgesData = nlohmann::json::array();

    // (a) 遍历 edges
    for (const auto & e : edges) {
        // e.type 通常是 "sequential" 或 "control" (你在 addEdge(...) 里定义)
        nlohmann::json je;
        je["from"]  = e.fromNodeId;
        je["to"]    = e.toNodeId;
        je["label"] = e.label;
        je["type"]  = e.type;
        if (e.type == "sequential") {
            edgesSeq.push_back(je);
        } else if (e.type == "control") {
            edgesCtrl.push_back(je);
        } else {
            // 其他type(如 "switch"?), 你也可归类到 control
            // 这里为了示例，暂时扔进 edgesCtrl
            edgesCtrl.push_back(je);
        }
    }

    // (b) 遍历 dataEdges
    for (const auto & de : dataEdges) {
        nlohmann::json je;
        je["from"]  = de.fromNodeId;
        je["to"]    = de.toNodeId;
        je["label"] = de.label;
        je["type"]  = de.type; // "data" or "data_dep"
        edgesData.push_back(je);
    }

    //-------------------------------------------------------
    // 准备把 struct / type_headers / registers 也做成 JSON
    // 若每个文件都想包含这些信息，你就都写；若只写一次(比如在_seq.json里)也行
    //-------------------------------------------------------
    nlohmann::json structsArr = nlohmann::json::array();
    for (const auto &svi : structVariables) {
        nlohmann::json jS;
        jS["variable_name"] = svi.variableName;
        jS["struct_type"]   = svi.structTypeName;
        nlohmann::json fieldArr = nlohmann::json::array();
        for (auto &fld : svi.fields) {
            nlohmann::json jf;
            jf["name"] = fld.name;
            jf["type"] = fld.type;
            fieldArr.push_back(jf);
        }
        jS["fields"] = fieldArr;
        structsArr.push_back(jS);
    }
    nlohmann::json typeHeadersArr = nlohmann::json::array();
    for (auto &thi : typeHeaders) {
        nlohmann::json jH;
        jH["header_name"] = thi.headerName;
        jH["type_name"]   = thi.typeName;
        nlohmann::json fArr = nlohmann::json::array();
        for (auto &f : thi.fields) {
            nlohmann::json jF;
            jF["name"] = f.name;
            jF["type"] = f.type;
            fArr.push_back(jF);
        }
        jH["fields"] = fArr;
        typeHeadersArr.push_back(jH);
    }
    nlohmann::json registersArr = nlohmann::json::array();
    for (auto &ri : registers) {
        nlohmann::json jR;
        jR["name"]        = ri.name;
        jR["size"]        = ri.size;
        jR["value_type"]  = ri.valueType;
        jR["index_type"]  = ri.indexType;
        registersArr.push_back(jR);
    }

    // 现在我们要输出三份 JSON 文件
    //   1) basePath+"_seq.json"
    //   2) basePath+"_ctrl.json"
    //   3) basePath+"_data.json"
    // 其中 nodes 相同，但 edges 不同
    // (也可把 struct / type_headers / registers 都写在三个文件里)

    {
        // (1) 顺序图
        nlohmann::json outSeq;
        outSeq["nodes"]           = nodesJson;
        outSeq["edges"]           = edgesSeq; // 只包含 sequential
        outSeq["structs"]         = structsArr;
        outSeq["type_headers"]    = typeHeadersArr;
        outSeq["registers"]       = registersArr;

        cstring seqFile = basePath + "_seq.json";
        std::ofstream fs(seqFile);
        if (fs.is_open()) {
            fs << outSeq.dump(4);
            fs.close();
            std::cout << "顺序流JSON输出到: " << seqFile << std::endl;
        } else {
            std::cerr << "无法写入 " << seqFile << std::endl;
        }
    }

    {
        // (2) 控制图
        nlohmann::json outCtrl;
        outCtrl["nodes"]         = nodesJson;
        outCtrl["edges"]         = edgesCtrl; // 只包含 control
        outCtrl["structs"]       = structsArr;
        outCtrl["type_headers"]  = typeHeadersArr;
        outCtrl["registers"]     = registersArr;

        cstring ctrlFile = basePath + "_ctrl.json";
        std::ofstream fc(ctrlFile);
        if (fc.is_open()) {
            fc << outCtrl.dump(4);
            fc.close();
            std::cout << "控制图JSON输出到: " << ctrlFile << std::endl;
        } else {
            std::cerr << "无法写入 " << ctrlFile << std::endl;
        }
    }

    {
        // (3) 数据依赖图
        nlohmann::json outData;
        outData["nodes"]         = nodesJson;
        outData["edges"]         = edgesData; // 只包含 data
        outData["structs"]       = structsArr;
        outData["type_headers"]  = typeHeadersArr;
        outData["registers"]     = registersArr;

        cstring dataFile = basePath + "_data.json";
        std::ofstream fd(dataFile);
        if (fd.is_open()) {
            fd << outData.dump(4);
            fd.close();
            std::cout << "数据依赖JSON输出到: " << dataFile << std::endl;
        } else {
            std::cerr << "无法写入 " << dataFile << std::endl;
        }
    }
}

void ControlFlowExtractor::outputCFGAsDot(const cstring& basePath) {
    //-------------------------------------------------------
    // 事先收集三类边 (你已有的)
    //-------------------------------------------------------
    std::vector<CFGEdge> seqEdges;
    std::vector<CFGEdge> ctrlEdges;
    // dataEdges 已经是一个成员或全局容器，里头专门装数据依赖边
    for (auto & e : edges) {
        if (e.type == "sequential") {
            seqEdges.push_back(e);
        } else if (e.type == "control") {
            ctrlEdges.push_back(e);
        } else {
            // 其它类型，如果也想视作控制边，可以加到ctrlEdges
            ctrlEdges.push_back(e);
        }
    }

    //-------------------------------------------------------
    // 1) 输出顺序图  => basePath+"_seq_b.dot"
    //-------------------------------------------------------
    {
        cstring seqDotFile = basePath + "_seq_b.dot";
        std::ofstream outF(seqDotFile);
        if (!outF.is_open()) {
            std::cerr << "无法打开文件 " << seqDotFile << " 写入DOT" << std::endl;
        } else {
            outF << "digraph CFG_Sequential {\n";
            outF << "  node [shape=box];\n";
            // 打印节点
            for (auto &kv : nodes) {
                const auto &nd = kv.second;
                outF << "  node" << nd.id << " [label=\""
                     << nd.name << "\\n("
                     << nodeTypeToString(nd.type) << ")\"];\n";
            }
            // 打印顺序边(黑色)
            for (auto &ed : seqEdges) {
                outF << "  node" << ed.fromNodeId << " -> node" << ed.toNodeId
                     << " [color=black";
                if (!ed.label.isNullOrEmpty()) {
                    outF << ", label=\"" << ed.label << "\"";
                }
                outF << "];\n";
            }
            outF << "}\n";
            outF.close();
            std::cout << "顺序流DOT输出到 " << seqDotFile << std::endl;
        }
    }

    //-------------------------------------------------------
    // 2) 输出控制图 => basePath+"_ctrl.dot"
    //-------------------------------------------------------
    {
        cstring ctrlDotFile = basePath + "_ctrl.dot";
        std::ofstream outF(ctrlDotFile);
        if (!outF.is_open()) {
            std::cerr << "无法打开文件 " << ctrlDotFile << " 写入DOT" << std::endl;
        } else {
            outF << "digraph CFG_Control {\n";
            outF << "  node [shape=box];\n";
            // 打印节点
            for (auto &kv : nodes) {
                const auto &nd = kv.second;
                outF << "  node" << nd.id << " [label=\""
                     << nd.name << "\\n("
                     << nodeTypeToString(nd.type) << ")\"];\n";
            }
            // 打印控制边(红色)
            for (auto &ed : ctrlEdges) {
                outF << "  node" << ed.fromNodeId << " -> node" << ed.toNodeId
                     << " [color=red, style=bold";
                if (!ed.label.isNullOrEmpty()) {
                    outF << ", label=\"" << ed.label << "\"";
                }
                outF << "];\n";
            }
            outF << "}\n";
            outF.close();
            std::cout << "控制流DOT输出到 " << ctrlDotFile << std::endl;
        }
    }

    //-------------------------------------------------------
    // 3) 输出数据依赖图 => basePath+"_data.dot"
    //-------------------------------------------------------
    {
        cstring dataDotFile = basePath + "_data.dot";
        std::ofstream outF(dataDotFile);
        if (!outF.is_open()) {
            std::cerr << "无法打开文件 " << dataDotFile << " 写入DOT" << std::endl;
        } else {
            outF << "digraph CFG_Data {\n";
            outF << "  node [shape=box];\n";
            // 打印节点
            for (auto &kv : nodes) {
                const auto &nd = kv.second;
                outF << "  node" << nd.id << " [label=\""
                     << nd.name << "\\n("
                     << nodeTypeToString(nd.type) << ")\"];\n";
            }
            // 数据依赖(蓝色虚线)
            for (auto &ed : dataEdges) {
                outF << "  node" << ed.fromNodeId << " -> node" << ed.toNodeId
                     << " [color=blue, style=dashed";
                if (!ed.label.isNullOrEmpty()) {
                    outF << ", label=\"" << ed.label << "\"";
                }
                outF << "];\n";
            }
            outF << "}\n";
            outF.close();
            std::cout << "数据依赖DOT输出到 " << dataDotFile << std::endl;
        }
    }

    //-------------------------------------------------------
    // 4) 新增：输出“控制+数据依赖” => basePath+"_ctrl_data.dot"
    //    或者你可以称之为 "_pdg.dot"
    //-------------------------------------------------------
    {
        cstring ctrlDataDotFile = basePath + "_ctrl_data.dot";
        std::ofstream outF(ctrlDataDotFile);
        if (!outF.is_open()) {
            std::cerr << "无法打开文件 " << ctrlDataDotFile << " 写入DOT" << std::endl;
        } else {
            outF << "digraph PDG {\n";
            outF << "  node [shape=box];\n";
            // 1) 打印所有节点
            for (auto &kv : nodes) {
                const auto &nd = kv.second;
                outF << "  node" << nd.id << " [label=\""
                     << nd.name << "\\n("
                     << nodeTypeToString(nd.type) << ")\"];\n";
            }
            // 2) 打印控制依赖 (红色，style=bold)
            for (auto &ed : ctrlEdges) {
                outF << "  node" << ed.fromNodeId << " -> node" << ed.toNodeId
                     << " [color=red, style=bold";
                if (!ed.label.isNullOrEmpty()) {
                    outF << ", label=\"" << ed.label << "\"";
                }
                outF << "];\n";
            }
            // 3) 打印数据依赖 (蓝色，虚线)
            for (auto &ed : dataEdges) {
                outF << "  node" << ed.fromNodeId << " -> node" << ed.toNodeId
                     << " [color=blue, style=dashed";
                if (!ed.label.isNullOrEmpty()) {
                    outF << ", label=\"" << ed.label << "\"";
                }
                outF << "];\n";
            }

            outF << "}\n";
            outF.close();
            std::cout << "控制+数据依赖DOT输出到 " << ctrlDataDotFile << std::endl;
        }
    }
}



void ControlFlowExtractor::handleDefaultAction(
    const IR::P4Table* table,
    const cstring& tableName,
    const std::vector<cstring>& keys,
    int matchNodeId,
    bool ruleExist,
    size_t actionListSize,
    bool noKey,
    std::vector<int>& ruleExitNodeIds) {

    const IR::Expression* defaultAction = table->getDefaultAction();
    bool hasExplicitDefault = false;

    cstring defaultActionName;
    std::vector<cstring> defaultActionParams;
    // int cNodeId = addNode(tableName + " default", NodeType::CONDITION, nullptr, tableName + " default");
    // addEdge(currentNodeId, cNodeId, "default");
    // currentNodeId = cNodeId;

    if (defaultAction != nullptr) {
        hasExplicitDefault = true;
        // irNodeIds.insert(currentNodeId, defaultAction->id);
        // 为了记录 defaultAction 的使用，将其插入到 irNodeIds
        // irNodeIds[currentNodeId].insert(defaultAction->id);

        if (auto methodCall = defaultAction->to<IR::MethodCallExpression>()) {
            defaultActionName = Utils::getMethodName(methodCall);
            for (const auto& arg : *methodCall->arguments) {
                // irNodeIds[currentNodeId].insert(arg->id);
                Utils::extractUsedVariables(arg->expression, nodes[currentNodeId].useVars);
                // irNodeIds.insert(currentNodeId, arg->id);
                defaultActionParams.push_back(Utils::translateExpression(arg->expression));
            }
        } else if (auto pathExpr = defaultAction->to<IR::PathExpression>()) {
            Utils::extractUsedVariables(pathExpr, nodes[currentNodeId].useVars);

            defaultActionName = pathExpr->path->name.name;
        } else {
            ::error("在表 %1% 的默认动作中遇到不支持的表达式类型：%2%", tableName, defaultAction->node_type_name());
        }
    }
    // ---- 新增：如果 IR 里没有任何参数，但 BMV2CmdsAnalyzer 里存在 table_set_default 的命令
    //            就从 BMV2CmdsAnalyzer 获取 “默认动作 + 参数”
    if (bMV2CmdsAnalyzer != nullptr && bMV2CmdsAnalyzer->hasTableSetDefaultCmd(tableName)) {
        TableSetDefault* defCmd = bMV2CmdsAnalyzer->getTableSetCmd(tableName);
        // e.g. defCmd->action = "get_my_address_act"
        //      defCmd->parameters = {"10.0.100.1", "100"}

        // 如果 IR 里 defaultActionName 为空 或者是 "NoAction"，
        // 或者你干脆想让 "BMv2命令" 覆盖 IR 里的默认动作 —— 看你需求，这里给示例
        if (defaultActionName.isNullOrEmpty() || defaultActionName == "NoAction") {
            defaultActionName = defCmd->action;
            defaultActionParams = defCmd->parameters;
            hasExplicitDefault = true;
        } else {
            // 如果 IR 里有 defaultActionName，但 BMv2命令行也有，要看是否要覆盖
            // 这里优先使用命令行（动态配置）
            defaultActionName = defCmd->action;
            defaultActionParams = defCmd->parameters;
            const IR::P4Action * actionDefault = findActionDefinition(defaultActionName);
            // int aNodeId = addNode(defaultActionName + " default PLACEHOLDER", NodeType::ACTION, actionDefault, defaultActionName + "()");
            // addControlEdge(nodeStack.top(), aNodeId, "defaultActionName", "control");
            // pushCurrentNode(aNodeId);
            // addEdge(currentNodeId, aNodeId, "default");
            // currentNodeId = aNodeId;
            // irNodeIds[currentNodeId].insert(actionDefault->id);
            for (auto param: actionDefault->parameters->parameters) {
                Utils::extractUsedVariables(param->defaultValue, nodes[currentNodeId].useVars);
            }

            hasExplicitDefault = true;
        }
    }
    // 检查 defaultAction 是否为 NoAction
    bool defaultActionIsNoAction = (!defaultActionName.isNullOrEmpty() &&
        std::string{defaultActionName}.find("NoAction") != std::string::npos);

    // 如果 defaultAction 是 NoAction，且 actionListSize == 2，且 noKey == true
    if (defaultActionIsNoAction && actionListSize == 2 && noKey) {
        // 说明 NoAction 不是实际的默认动作，需要继续解析其他动作
        // 在动作列表中查找不是 NoAction 的动作作为默认动作
        auto actionListProperty = table->properties->getProperty("actions");
        if (actionListProperty != nullptr) {
            if (auto actionList = actionListProperty->value->to<IR::ActionList>()) {
                // irNodeIds.insert(currentNodeId, actionList->id);
                // 为了记录 actionList 的使用，将其插入到 irNodeIds
                // irNodeIds[currentNodeId].insert(actionList->id);

                for (auto actionElement : actionList->actionList) {
                    // irNodeIds记录
                    // irNodeIds[currentNodeId].insert(actionElement->id);

                    cstring actionName;
                    std::vector<cstring> actionParams;

                    if (auto pathExpr = actionElement->expression->to<IR::PathExpression>()) {
                        // irNodeIds[currentNodeId].insert(pathExpr->id);
                        actionName = pathExpr->path->name.name;

                    } else if (auto methodCallExpr = actionElement->expression->to<IR::MethodCallExpression>()) {
                        actionName = Utils::getMethodName(methodCallExpr);
                        for (const auto& arg : *methodCallExpr->arguments) {
                            actionParams.push_back(Utils::translateExpression(arg->expression));
                            Utils::extractUsedVariables(arg->expression, nodes[currentNodeId].useVars);
                        }
                    }

                    // 跳过 NoAction
                    if (actionName == "NoAction") {
                        continue;
                    }

                    // 找到实际的默认动作
                    defaultActionName = actionName;
                    defaultActionParams = actionParams;
                    hasExplicitDefault = true; // 将标志设置为 true，表示我们找到了默认动作
                    break;
                }
            }
        }
    }

    if (!defaultActionName.isNullOrEmpty()) {
        // 构建默认动作调用
        std::stringstream defaultActionCallStream;
        defaultActionCallStream << defaultActionName << "(";
        for (size_t i = 0; i < defaultActionParams.size(); ++i) {
            defaultActionCallStream << defaultActionParams[i];
            if (i != defaultActionParams.size() - 1) {
                defaultActionCallStream << ", ";
            }
        }
        defaultActionCallStream << ");";
        cstring defaultActionCall = defaultActionCallStream.str();

        // 获取默认动作定义并处理
        const IR::P4Action* defaultActionDef = findActionDefinition(defaultActionName);
        if (!nodes[currentNodeId].name.find("default PLACEHOLDER")) {
            // 添加默认动作节点
            int defaultActionNodeId = addNode(defaultActionCall, NodeType::ACTION, nullptr, defaultActionCall);
            addControlEdge(nodeStack.top(), defaultActionNodeId, defaultActionCall, "control");
            pushCurrentNode(defaultActionNodeId);
            addEdge(matchNodeId, defaultActionNodeId, "default", "sequential");;
            currentNodeId = defaultActionNodeId;
            irNodeIds[currentNodeId].insert(defaultActionDef->id);

        }
        if (defaultActionDef == nullptr) {
            ::error("无法找到默认动作定义 %1%", defaultActionName);
            return;
        }

        // 创建动作实例
        ActionInstance defaultActionInstance = {defaultActionDef, defaultActionParams};
        std::vector<std::string> strs;
        for (auto &param: defaultActionParams) {
            strs.push_back(std::string{param});
        }
        // 处理默认动作实例
        int defaultActionExitNodeId = processActionInstance(defaultActionInstance, strs);
        ruleExitNodeIds.push_back(defaultActionExitNodeId);
        popCurrentNode();

    } else {
        // 如果没有规则和默认动作，或者默认动作仍然是 NoAction，添加一个跳过节点
        cstring skipActionName = "NoAction";
        std::stringstream skipActionStream;
        skipActionStream << skipActionName << "();";
        cstring skipActionCall = skipActionStream.str();

        // 检查是否已经存在一个 `NoAction` 节点以避免重复创建
        for (const auto& nodePair : nodes) {
            if (nodePair.second.name.find(skipActionCall)) {
                addEdge(matchNodeId, nodePair.first, "default", "sequential");
                currentNodeId = nodePair.first;
                ruleExitNodeIds.push_back(nodePair.first);
                break;
            }
        }

        // 添加跳过节点
        int skipActionNodeId = addNode(skipActionCall, NodeType::ACTION, nullptr, skipActionCall);
        addControlEdge(nodeStack.top(), skipActionNodeId, skipActionCall, "control");
        pushCurrentNode(skipActionNodeId);

        addEdge(matchNodeId, skipActionNodeId, "default", "sequential");
        currentNodeId = skipActionNodeId;
        popCurrentNode();
        ruleExitNodeIds.push_back(skipActionNodeId);
    }
}

// 将 NodeType 转换为字符串
const char* ControlFlowExtractor::nodeTypeToString(NodeType type) {
    switch (type) {
        case NodeType::BLOCK: return "BLOCK";
        case NodeType::MERGE: return "MERGE";
        case NodeType::SWITCH: return "SWITCH";
        case NodeType::ENTRY: return "ENTRY";
        case NodeType::EXIT: return "EXIT";
        case NodeType::STATEMENT: return "STATEMENT";
        case NodeType::CONDITION: return "CONDITION";
        case NodeType::TABLE: return "TABLE";
        case NodeType::ACTION: return "ACTION";
        case NodeType::DECLARATION: return "DECLARATION";
        case NodeType::PARSER: return "PARSER";
        case NodeType::PARSE_STATE: return "PARSE_STATE";
        case NodeType::CONTROL: return "CONTROL";
        default: return "UNKNOWN";
    }
}

bool ControlFlowExtractor::preorder(const IR::Node *node){
    if (switchFuncPosiLog)
        std::cout << "ControlFlowExtractor::preorder(const IR::Node *node)" << std::endl;

    if (auto instance = node->to<IR::Declaration_Instance>()) {
        std::cout << "Declaration_Instance: " << instance->name.name << std::endl;
        visit(instance);
    }
    else{
        // std::cout << node->node_type_name() << std::endl;
        // translate(obj);
    }
    return false;
}

bool ControlFlowExtractor::preorder(const IR::BlockStatement* block) {
    if (switchFuncPosiLog)
        std::cout << "ControlFlowExtractor::preorder(const IR::BlockStatement* block)" << std::endl;

    if (block == nullptr) {
        return false;
    }
    int blockEnterId = addNode("BlockEnter", NodeType::BLOCK, block, "BlockEnter");
    addControlEdge(nodeStack.top(), blockEnterId, "block-enter", "control");
    pushCurrentNode(blockEnterId);
    addEdge(currentNodeId, blockEnterId, "block-enter", "sequential");
    currentNodeId = blockEnterId;

    // 遍历 block 中的每条语句
    for (auto stmt : block->components) {
        visit(stmt);
    }

    // 最后，给本 block 添加一个 EXIT 节点
    int blockExitId = addNode("BlockExit", NodeType::EXIT, block, "BlockExit");

    addEdge(currentNodeId, blockExitId, "block-exit", "sequential");
    irNodeIds[currentNodeId].insert(block->id);
    popCurrentNode();
    // 更新 currentNodeId 为 blockExitId，方便后续语句接着连
    currentNodeId = blockExitId;
    return false;
}

bool ControlFlowExtractor::preorder(const IR::IfStatement* statement) {
    // 处理条件节点
    if (switchFuncPosiLog)
        std::cout << "ControlFlowExtractor::preorder(const IR::IfStatement* statement)" << std::endl;

    cstring conditionExpr = Utils::translateExpression(statement->condition);
    // irNodeIds.insert(currentNodeId, statement->id);

    cstring conditionStr = "if (" + conditionExpr + ")";
    int conditionNodeId = addNode(conditionStr, NodeType::IF, statement->condition, conditionStr);

    addControlEdge(nodeStack.top(), conditionNodeId, conditionStr, "control");
    pushCurrentNode(conditionNodeId);

    CFGNode& node = nodes[conditionNodeId];
    Utils::extractUsedVariables(statement->condition, node.useVars);

    // 让当前节点 -> conditionNodeId
    addEdge(currentNodeId, conditionNodeId, "");
    // irNodeIds[conditionNodeId].insert(statement->condition->id);
    currentNodeId = conditionNodeId;
    irNodeIds[currentNodeId].insert(statement->id);

    // irNodeIds.insert(currentNodeId, statement->condition->id);

    // 建一个 ifExit 节点，用来汇合
    int ifExitNodeId = addNode("IfExit", NodeType::MERGE, statement, "IfExit");

    // 处理 then 分支

    int trueId = addNode("if true", NodeType::CONDITION, statement->ifFalse, conditionStr + "if true");

    addControlEdge(nodeStack.top(), trueId, conditionStr + "if true", "control");
    pushCurrentNode(trueId);

    addEdge(currentNodeId, trueId, "if true");
    currentNodeId = trueId;

    irNodeIds[currentNodeId].insert(statement->ifTrue->id);

    visit(statement->ifTrue);
    // irNodeIds.insert(currentNodeId, statement->ifTrue->id);

    popCurrentNode();
    int thenLastNode = currentNodeId;  // then 分支最后语句的节点
    // 加一条边 (thenLastNode -> ifExit)
    addEdge(thenLastNode, ifExitNodeId, "then-exit");

    currentNodeId = conditionNodeId;

    // 处理 else 分支
    if (statement->ifFalse != nullptr) {
        // irNodeIds.insert(currentNodeId, statement->ifFalse->id);
        int falseId = addNode("else", NodeType::CONDITION, statement->ifFalse, conditionStr + "->else");

        addControlEdge(nodeStack.top(), falseId, conditionStr + "if true", "control");
        pushCurrentNode(falseId);

        addEdge(currentNodeId, falseId, "else");
        currentNodeId = falseId;
        irNodeIds[currentNodeId].insert(statement->ifFalse->id);

        visit(statement->ifFalse);

        int elseLastNode = currentNodeId;
        // 加一条边 (elseLastNode -> ifExit)
        addEdge(elseLastNode, ifExitNodeId, "else-exit");
        popCurrentNode();
        currentNodeId = conditionNodeId;
    } else {
        int falseId = addNode("else", NodeType::CONDITION, nullptr, conditionStr + "->else");
        addControlEdge(nodeStack.top(), falseId, conditionExpr, "control");
        pushCurrentNode(falseId);
        addEdge(currentNodeId, falseId, "else");
        addEdge(falseId, ifExitNodeId, "else-exit");
        popCurrentNode();
    }
    popCurrentNode();
    // 最后把 currentNodeId 设为 ifExitNodeId，让后续语句跟 ifExit 连
    currentNodeId = ifExitNodeId;

    return false;
}


bool ControlFlowExtractor::preorder(const IR::SwitchStatement* statement) {
    // 处理 switch 表达式
    if (switchFuncPosiLog)
        std::cout << "ControlFlowExtractor::preorder(const IR::SwitchStatement* statement)" << std::endl;

    cstring switchExpr = Utils::translateExpression(statement->expression);
    cstring switchStr = "switch (" + switchExpr + ")";
    int switchNodeId = addNode(switchStr, NodeType::SWITCH, statement->expression, switchStr);
    addEdge(currentNodeId, switchNodeId, "");

    addControlEdge(nodeStack.top(),switchNodeId,switchStr,"control");
    pushCurrentNode(switchNodeId);

    currentNodeId = switchNodeId;
    // irNodeIds.insert(currentNodeId, statement->id);
    irNodeIds[currentNodeId].insert(statement->id);

    // 处理各个 case
    // currentNodeId = switchNodeId;
    std::vector<int> caseEndNodeIds;
    for (auto scase : statement->cases) {

        cstring caseLabel = Utils::translateExpression(scase->label);
        visit(scase->statement);
        int caseNodeId = currentNodeId;
        // irNodeIds.insert(currentNodeId, scase->id);
        // irNodeIds[currentNodeId].insert(scase->id);

        addEdge(switchNodeId, caseNodeId, caseLabel);
        caseEndNodeIds.push_back(caseNodeId);
    }
    popCurrentNode();
    currentNodeId = switchNodeId;

    // 添加合并节点
    int mergeNodeId = addNode("Merge after switch", NodeType::MERGE, nullptr, "");
    for (auto nodeId : caseEndNodeIds) {
        addEdge(nodeId, mergeNodeId, "");
    }
    currentNodeId = mergeNodeId;

    return false;
}

bool ControlFlowExtractor::preorder(const IR::MethodCallStatement* statement) {
    if (switchFuncPosiLog)
        std::cout << "ControlFlowExtractor::preorder(const IR::MethodCallStatement* statement)" << std::endl;

    // 获取方法名
    cstring methodName = Utils::translateExpression(statement->methodCall);

    auto mi = P4::MethodInstance::resolve(statement->methodCall, refMap, typeMap);
    if (auto applyMethod = mi->to<P4::ApplyMethod>()) {
        if (applyMethod->object->is<IR::P4Table>()) {
            auto table = applyMethod->object->to<IR::P4Table>();
            auto tbExpression = Utils::translateExpression(statement->methodCall);
            int tbCallNodeId = addNode(tbExpression, NodeType::ACTION, statement, tbExpression);
            addControlEdge(nodeStack.top(), tbCallNodeId, tbExpression, "control");
            addEdge(currentNodeId, tbCallNodeId, "tb_call", "sequential");
            currentNodeId = tbCallNodeId;
            irNodeIds[currentNodeId].insert(statement->id);
            irNodeIds[currentNodeId].insert(statement->methodCall->id);
            pushCurrentNode(tbCallNodeId);
            visit(table);
            popCurrentNode();
            return false;
        }
    } else if (auto actionCall = mi->to<P4::ActionCall>()) {
        auto action = actionCall->action;

        cstring actionName = action->name.name;

        // 构建动作调用字符串
        std::stringstream actionCallStream;
        actionCallStream << actionName << "(";
        bool first = true;
        for (const auto& arg : *statement->methodCall->arguments) {
            if (!first) actionCallStream << ", ";
            actionCallStream << Utils::translateExpression(arg->expression);
            first = false;
        }
        actionCallStream << ");";
        cstring actionCallStr = actionCallStream.str();

        // 添加动作节点
        int actionNodeId = addNode(actionCallStr, NodeType::ACTION, action, actionCallStr);
        addEdge(currentNodeId, actionNodeId, "", "sequential");
        addControlEdge(nodeStack.top(), actionNodeId, actionCallStr, "control");
        pushCurrentNode(actionNodeId);
        currentNodeId = actionNodeId;
        irNodeIds[currentNodeId].insert(actionCall->action->id);
        for (auto &arg: *statement->methodCall->arguments) {
            std::cout << "MethodCallStatement arg: " << arg->expression->toString() << std::endl;
            Utils::extractUsedVariables(arg->expression, nodes[currentNodeId].useVars);
        }
        // 处理动作主体
        if (action->body != nullptr) {
            visit(action->body);
        }
        popCurrentNode();
        return false;
    }
    if (std::string{statement->toString()}.find(".read") != std::string::npos) {
        std::cout << "MethodCallStatement .read methodName: " << methodName << std::endl;
        std::size_t pos = std::string{statement->toString()}.find(".read");
        cstring regName = statement->toString().substr(0, pos).c_str(); // 提取出形如"sequence_reg"
        // e.g. 2 args: read(dest, idx)
        cstring destVar = Utils::getFullVariableName(statement->methodCall->arguments->at(0)->expression);
        cstring idxVar  = Utils::getFullVariableName(statement->methodCall->arguments->at(1)->expression);

        // registerName = methodName.substr(0, pos)  e.g. "sequence_reg"
        cstring codeStr = destVar + " = " + regName + "[" + "];";

        int stmtNodeId = addNode(codeStr, NodeType::STATEMENT, statement, codeStr);
        addControlEdge(nodeStack.top(), stmtNodeId, codeStr, "control");
        pushCurrentNode(stmtNodeId);
        addEdge(currentNodeId, stmtNodeId, "", "sequential");
        currentNodeId = stmtNodeId;
        irNodeIds[currentNodeId].insert(statement->id);

        // ---- def/use ----
        CFGNode &node = nodes[currentNodeId];
        // def
        node.genVars.insert(destVar);
        // use
        node.useVars.insert(regName + "[" + "]");
        node.useVars.insert(idxVar);
        // (若要把 registerName 整体也放进 useVars，不一定)
        popCurrentNode();
        return false;
    }
    if (std::string{statement->toString()}.find(".write") != std::string::npos) {
        std::cout << "MethodCallStatement .read methodName: " << methodName << std::endl;

        std::size_t pos = std::string{statement->toString()}.find(".write");
        cstring regName = statement->toString().substr(0, pos).c_str(); // 提取出形如"sequence_reg"

        // e.g. 2 args: write(idx, val)
        cstring idxVar = Utils::getFullVariableName(statement->methodCall->arguments->at(0)->expression);
        cstring valVar = Utils::getFullVariableName(statement->methodCall->arguments->at(1)->expression);

        cstring codeStr = regName + "[" + "] = " + valVar + ";";

        int stmtNodeId = addNode(codeStr, NodeType::STATEMENT, statement, codeStr);
        addControlEdge(nodeStack.top(), stmtNodeId, codeStr, "control");
        pushCurrentNode(stmtNodeId);
        addEdge(currentNodeId, stmtNodeId, "", "sequential");
        currentNodeId = stmtNodeId;
        irNodeIds[currentNodeId].insert(statement->id);

        // ---- def/use ----
        CFGNode &node = nodes[currentNodeId];
        // def
        node.genVars.insert(regName + "[" + "]");
        // use
        node.useVars.insert(valVar);
        node.useVars.insert(idxVar);
        popCurrentNode();
        return false;
    }
    // case X: check if methodStr == "setValid(...)"
    if (methodName.find("setValid")) {
        // typical call: setValid(hdr.xxx)

        // 1) 提取第一个参数
        if (!statement->methodCall->arguments->empty()) {
            auto argExpr = statement->methodCall->arguments->at(0)->expression;
            cstring argName = Utils::getFullVariableName(argExpr);
            // e.g. argName = "hdr.mirror"

            // 2) 在 CFG 中添加一个节点
            //    生成形如 "setValid(hdr.mirror);" 的 code
            cstring codeStr = "setValid(" + argName + ");";
            int stmtNodeId = addNode(codeStr, NodeType::STATEMENT, statement, codeStr);
            addControlEdge(nodeStack.top(), stmtNodeId, codeStr, "control");
            pushCurrentNode(stmtNodeId);
            addEdge(currentNodeId, stmtNodeId, "", "sequential");
            currentNodeId = stmtNodeId;
            irNodeIds[currentNodeId].insert(statement->id);

            // 3) 在 genVars 里增加 "hdr.mirror.valid" => 说明这是一个“定义”
            //    同时，如果你也希望把 "hdr.mirror" 当作某种定义，可以一并添加
            CFGNode &node = nodes[stmtNodeId];

            // e.g. 生成 "hdr.mirror.valid"
            cstring validVar = argName + ".valid";
            node.genVars.insert(validVar);
            popCurrentNode();
            // 如果你希望表示“hdr.mirror.*”都被定义，也可插入 "hdr.mirror" itself:
            // node.genVars.insert(argName);
            // 这里没有 useVars，因为 setValid(...) 在逻辑上不读该字段，而是写/改变其有效位
        }
        // return false; // 结束对本 MethodCallStatement 的处理
        return false;
    }

    // 其他方法调用
    cstring methodCallStr = Utils::translateExpression(statement->methodCall);
    std::stringstream codeStream;
    codeStream << methodCallStr << ";";
    cstring codeStr = codeStream.str();
    // 添加方法调用节点
    int stmtNodeId = addNode(codeStr, NodeType::STATEMENT, statement, codeStr);
    addControlEdge(nodeStack.top(), stmtNodeId, codeStr, "control");
    pushCurrentNode(stmtNodeId);
    addEdge(currentNodeId, stmtNodeId, "", "sequential");
    CFGNode &node = nodes[currentNodeId];
    currentNodeId = stmtNodeId;

    if (methodName.find(".execute")) {
        int pos = std::string{methodName}.find(".execute");
        cstring raInstanceName = methodName.substr(0, pos); // e.g. "someAction"
        // 添加方法调用节点
        irNodeIds[currentNodeId].insert(statement->id);

        // 看看是不是RegisterAction
        auto it = registerActionMap.find(raInstanceName);
        if (it != registerActionMap.end()) {
            // 1) 先在 CFG 里做一个 statement 节点: "someAction.execute(...)"
            cstring code = Utils::translateExpression(statement->methodCall) + ";";
            auto &info = it->second;
            // 2) 准备 actionParams
            std::vector<cstring> actionParams;
            cstring idxVal = Utils::translateExpression(
                statement->methodCall->arguments->at(0)->expression);
            cstring inoutVal = info.registerName + "[" + "]";
            // 先解析 idx
            if (!statement->methodCall->arguments->empty()) {
                actionParams.push_back(inoutVal);
            }
            actionParams.push_back("PLACEHOLDER_REGISTERACTION_RESULT");
            // 对于“out param”这时没有左值 =>
            //   可能 IR 有 2个形参，但只传了1个 =>
            //   translator 里介绍了 "PLACEHOLDER_REGISTERACTION_RESULT"
            //   这里只是无左值场景 => 不关心 out param =>
            //   也可以给个 placeholder

            // 3) 把它当作“动作调用”
            //    registerActionMap[raInstanceName].fakeAction
            const IR::P4Action* fakAct = info.fakeAction;

            // 4) 构建 ActionInstance
            ActionInstance ai;
            ai.actionDef = fakAct;
            ai.parameters = actionParams;
            std::vector<std::string> strs;
            for (auto &param: actionParams) {
                strs.push_back(std::string{param});
            }
            // 5) 调用 processActionInstance
            int exitNodeId = processActionInstance(ai, strs);
            popCurrentNode();
            currentNodeId = exitNodeId;
            return false;
        }
    }

    // case 1: check if methodStr == "packet_in.extract"
    if (methodName.find(".extract")) {
        std::cout << "MethodCallStatement .extract methodName: " << methodName << std::endl;
        // typically 1 argument: e.g. extract(hdr.ethernet)
        if (!statement->methodCall->arguments->empty()) {
            auto argExpr = statement->methodCall->arguments->at(0)->expression;
            cstring argName = Utils::getFullVariableName(argExpr);
            if (argName.find(".next")) {
                argName = argName.substr(0, std::string{argName}.find(".next"));
            }
            // => genVars
            nodes[currentNodeId].genVars.insert(argName + ".valid");
            nodes[currentNodeId].useVars.insert(argName + ".valid");
            // irNodeIds[currentNodeId].insert(statement->id);
        }
    }
    // case 2: check if methodStr == "packet_out.emit"
    else if (methodName.find(".emit")) {
        std::cout << "MethodCallStatement .emit methodName: " << methodName << std::endl;
        // => useVars
        if (!statement->methodCall->arguments->empty()) {
            auto argExpr = statement->methodCall->arguments->at(0)->expression;
            cstring argName = Utils::getFullVariableName(argExpr);
            nodes[currentNodeId].useVars.insert(argName);
            irNodeIds[currentNodeId].insert(statement->id);
            Utils::extractUsedVariables(statement->methodCall->arguments->at(0)->expression, nodes[currentNodeId].useVars);
        }
    }
    else if (methodName.find(".isValid")) {
        std::cout << "MethodCallStatement .isValid methodName: " << methodName << std::endl;
        // => useVars
        if (!statement->methodCall->arguments->empty()) {
            auto argExpr = statement->methodCall->method;
            CFGNode& node = nodes[currentNodeId];
            cstring argName = Utils::getFullVariableName(argExpr);
            node.useVars.insert(argName + ".valid");
            nodes[currentNodeId].useVars.insert(argName);
            irNodeIds[currentNodeId].insert(statement->id);
            node.useVars.insert(argName + ".valid");
        }
    }
    else if (methodName.find(".pop_front")) {
        std::cout << "MethodCallStatement .pop_front methodName: " << methodName << std::endl;
        // => useVars
        std::string spiltName{methodName};
        std::size_t pos = spiltName.find(".pop_front");
        cstring argName = methodName.substr(0, pos).c_str();
        CFGNode& node = nodes[currentNodeId];
        node.useVars.insert(argName);
        node.genVars.insert(argName);
        irNodeIds[currentNodeId].insert(statement->id);
    }
    popCurrentNode();
    // if (auto applyMethod = mi->to<P4::ApplyMethod>()) {
    //     if (applyMethod->object->is<IR::P4Table>()) {
    //         auto table = applyMethod->object->to<IR::P4Table>();
    //         // irNodeIds.insert(currentNodeId, table->id);
    //         // irNodeIds[currentNodeId].insert(table->id);
    //
    //     }
    // }
    return false;
}

bool ControlFlowExtractor::preorder(const IR::AssignmentStatement* statement) {
    if (switchFuncPosiLog)
        std::cout << "ControlFlowExtractor::preorder(const IR::AssignmentStatement* statement)" << std::endl;

    cstring leftStr = Utils::translateExpression(statement->left);
    cstring rightStr = Utils::translateExpression(statement->right);

    // 构建赋值语句
    std::stringstream codeStream;
    codeStream << leftStr << " = " << rightStr << ";";
    cstring codeStr = codeStream.str();

    // 添加赋值节点
    int stmtNodeId = addNode(codeStr, NodeType::STATEMENT, statement, codeStr);
    addControlEdge(nodeStack.top(), stmtNodeId, codeStr, "control");

    // 更新 genVars 和 useVars
    CFGNode& node = nodes[stmtNodeId];
    cstring leftVar = Utils::getFullVariableName(statement->left);
    node.genVars.insert(leftVar);
    Utils::extractUsedVariables(statement->right, node.useVars);

    // 添加边
    addEdge(currentNodeId, stmtNodeId, "", "sequential");
    currentNodeId = stmtNodeId;
    // addAllDescendants(currentNodeId, statement);

    irNodeIds[currentNodeId].insert(statement->id);
    // irNodeIds.insert(currentNodeId, statement->left->id);
    // irNodeIds.insert(currentNodeId, statement->right->id);

    if (auto arrIdx = statement->left->to<IR::ArrayIndex>()) {
        cstring fullArrayElem = Utils::getFullVariableName(arrIdx);
        if (!fullArrayElem.isNullOrEmpty()) {
            node.genVars.insert(fullArrayElem); // e.g. "sequence_reg[meta.loc]"
        }
    }
    if (auto mce = statement->right->to<IR::MethodCallExpression>()) {
        cstring methodStr = Utils::translateExpression(mce->method);
        auto pos = std::string{methodStr}.find(".execute");
        if (pos != std::string::npos) {
            cstring raInstanceName = methodStr.substr(0, pos);

            auto it = registerActionMap.find(raInstanceName);
            if (it != registerActionMap.end()) {
                auto &info = it->second;

                // 1) 构建 actionParams
                //    第一个 param => idx
                std::vector<cstring> actionParams;
                cstring idxVal = Utils::translateExpression(mce->arguments->at(0)->expression);

                cstring inoutVal = info.registerName + "[" + "]";
                if (!mce->arguments->empty()) {
                    std::cout << "idxVal: " << idxVal << std::endl;
                    actionParams.push_back(inoutVal);
                }
                // 2) 这里**肯定**有左值 => 说明 out param 要传给 leftVar
                //    => action 形参若 =2, 那我们 param2 = leftVar
                auto fakAct = info.fakeAction;
                size_t paramCount = fakAct->parameters->parameters.size();
                if (paramCount == 2) {
                    // e.g. param2 => outVal
                    std::cout << "leftVar:" << leftVar << std::endl;
                    actionParams.push_back(leftVar);
                }
                // else if paramCount == 1 => 说明 registerAction自己不定义 out param
                //  但 translator 里你提到 “如果 paraCount==2 => inout + out”
                //  这里我们只处理 1 or 2
                //  (更多可根据情况处理)

                // 3) 这时**内联** registerAction
                ActionInstance ai;
                ai.actionDef = fakAct;  // 伪 action
                ai.parameters = actionParams;

                std::vector<std::string> strs;
                for (auto &param: actionParams) {
                    strs.push_back(std::string{param});
                }
                // 5) 调用 processActionInstance
                int exitNodeId = processActionInstance(ai, strs);
                // int exitNodeId = processActionInstance(ai, stmtNodeId);
                currentNodeId = exitNodeId;
            }
        }
        auto pos_hash = std::string{methodStr}.find(".get");
        if (pos_hash != std::string::npos) {
            auto arguments = (*mce->arguments)[0];
            auto expression = arguments->expression;
            for (auto exp : expression->to<IR::StructExpression>()->components) {
                if (auto ex = exp->to<IR::Expression>()) {
                    Utils::extractUsedVariables(ex, node.useVars);
                }
            }
        }

    } else {
        // 如果不是 arrayIndex, 则使用原逻辑
        const cstring var = Utils::getFullVariableName(statement->left);
        node.genVars.insert(var);
    }

    // 右值
    Utils::extractUsedVariables(statement->right, node.useVars);

    return false;
}

// 处理返回语句
bool ControlFlowExtractor::preorder(const IR::ReturnStatement* statement) {
    cstring codeStr = "return;";
    int stmtNodeId = addNode(codeStr, NodeType::STATEMENT, statement, codeStr);
    addControlEdge(nodeStack.top(), stmtNodeId, statement->toString(), "control");

    addEdge(currentNodeId, stmtNodeId, "");
    currentNodeId = stmtNodeId;
    // addAllDescendants(currentNodeId, statement);

    return false;
}

// 处理退出语句
bool ControlFlowExtractor::preorder(const IR::ExitStatement* statement) {
    cstring codeStr = "exit;";
    int stmtNodeId = addNode(codeStr, NodeType::STATEMENT, statement, codeStr);
    addControlEdge(nodeStack.top(), stmtNodeId, statement->toString(), "control");

    addEdge(currentNodeId, stmtNodeId, "", "sequential");
    currentNodeId = stmtNodeId;
    // addAllDescendants(currentNodeId, statement);

    return false;
}

// 处理 P4Action
bool ControlFlowExtractor::preorder(const IR::P4Action* action) {
    if (switchFuncPosiLog)
        std::cout << "ControlFlowExtractor::preorder(const IR::P4Action* action)" << std::endl;

    // 添加动作节点
    int actionNodeId = addNode(action->name.name, NodeType::ACTION, action, action->name.name);
    addControlEdge(nodeStack.top(), actionNodeId, action->name.name, "control");
    pushCurrentNode(actionNodeId);
    addEdge(currentNodeId, actionNodeId, "", "sequential");
    currentNodeId = actionNodeId;
    CFGNode &node = nodes[currentNodeId];
    // irNodeIds.insert(currentNodeId, action->id);
    irNodeIds[currentNodeId].insert(action->id);
    for (auto &param: action->parameters->parameters) {
        Utils::extractUsedVariables(param->defaultValue, node.useVars);
    }
    // 遍历动作主体
    if (action->body != nullptr) {
        visit(action->body);
    }
    popCurrentNode();
    return false;
}

// 处理 P4Table
bool ControlFlowExtractor::preorder(const IR::P4Table* table) {
    if (switchFuncPosiLog)
        std::cout << "ControlFlowExtractor::preorder(const IR::P4Table* table)" << std::endl;

    cstring tableName = table->name.name;
    if (std::string{tableName}.find("table_dst_cs_3") != std::string::npos) {
        std::cout << "table_dst_cs_3" << std::endl;
    }
    int matchNodeId = INT32_MIN;
    // 创建表应用节点
    std::stringstream applyStream;
    applyStream << "Apply(" << tableName << ")";
    cstring applyStr = applyStream.str();
    int tableNodeId = addNode(applyStr, NodeType::TABLE, nullptr, applyStr);
    addControlEdge(nodeStack.top(), tableNodeId, applyStr, "control");

    pushCurrentNode(tableNodeId);
    addEdge(currentNodeId, tableNodeId, "");

    // 暂存
    int savedCurrentNodeId = currentNodeId;
    currentNodeId = tableNodeId;
    // irNodeIds.insert(currentNodeId, table->id);
    irNodeIds[currentNodeId].insert(table->id);
    CFGNode &node = nodes[currentNodeId];
    // 处理匹配键
    const IR::Key* key = table->getKey();
    std::vector<cstring> keys;
    std::vector<int> ruleExitNodeIds;
    size_t actionListSize = 0;

    // for (auto keyElement : key->keyElements) {
    //     Utils::extractUsedVariables(keyElement->expression, node.useVars);
    // }
    // 计算动作列表大小
    for (auto property : table->properties->properties) {
        if (auto actionList = property->value->to<IR::ActionList>()) {
            actionListSize += actionList->actionList.size();
        }
    }

    if (key != nullptr && !key->keyElements.empty()) {
        for (auto keyElement : key->keyElements) {
            Utils::extractUsedVariables(keyElement->expression, node.useVars);
            // addAllDescendants(currentNodeId, keyElement);
        }
        bool hasKeys = true;
        // 构建匹配条件节点
        std::stringstream conditionStream;
        conditionStream << "Match on ";
        bool first = true;
        // irNodeIds.insert(currentNodeId, key->id);
        // irNodeIds[currentNodeId].insert(key->id);

        for (auto keyElement : key->keyElements) {
            if (!first) {
                conditionStream << ", ";
            }
            // irNodeIds[currentNodeId].insert(key->id);
            cstring keyExpr = Utils::translateExpression(keyElement->expression);
            cstring matchType = keyElement->matchType->toString();
            conditionStream << keyExpr << " (" << matchType << ")";
            keys.push_back(keyExpr);
            first = false;
        }

        cstring conditionStr = conditionStream.str();
        matchNodeId = addNode(conditionStr, NodeType::CONDITION, nullptr, conditionStr);

        addControlEdge(nodeStack.top(), matchNodeId, conditionStr, "control");
        pushCurrentNode(matchNodeId);


        addEdge(currentNodeId, matchNodeId, "");

        currentNodeId = matchNodeId;

        CFGNode& matchNode = nodes[matchNodeId];
        for (auto keyElement : key->keyElements) {
            Utils::extractUsedVariables(keyElement->expression, matchNode.useVars);
            // addAllDescendants(currentNodeId, keyElement);
        }

        bool ruleExist = false;

        if (bMV2CmdsAnalyzer != nullptr && bMV2CmdsAnalyzer->hasTableAddCmds(tableName)) {
            ruleExist = true;
            std::vector<TableAdd*> rules = bMV2CmdsAnalyzer->getTableAddCmds(tableName);
            for (auto rule : rules) {
                currentNodeId = matchNodeId;

                cstring actionName = rule->action;
                std::vector<cstring> actionParams = rule->parameters;

                // 构建条件节点
                cstring condition = rule->getCondition(keys);
                std::stringstream conditionStmt;
                conditionStmt << "if (" << condition << ")";
                cstring conditionLabel = condition;

                // 添加规则条件节点
                int ruleConditionNodeId = addNode(conditionStmt.str(), NodeType::CONDITION, nullptr, conditionStmt.str());

                addControlEdge(nodeStack.top(), ruleConditionNodeId, condition, "control");
                pushCurrentNode(ruleConditionNodeId);

                addEdge(currentNodeId, ruleConditionNodeId, conditionLabel);
                currentNodeId = ruleConditionNodeId;
                CFGNode& ruleConditionNode = nodes[ruleConditionNodeId];
                Utils::extractUsedVariablesFromString(condition, ruleConditionNode.useVars);

                // 构建动作调用
                std::stringstream actionCallStream;
                actionCallStream << actionName << "(";
                for (size_t i = 0; i < actionParams.size(); ++i) {
                    actionCallStream << actionParams[i];
                    if (i != actionParams.size() - 1) {
                        actionCallStream << ", ";
                    }
                }
                actionCallStream << ");";
                cstring actionCall = actionCallStream.str();

                // 添加动作节点
                int actionNodeId = addNode(actionCall, NodeType::ACTION, nullptr, actionCall);

                addControlEdge(nodeStack.top(), actionNodeId, actionCall, "control");
                pushCurrentNode(actionNodeId);

                addEdge(currentNodeId, actionNodeId, actionName, "sequential");
                currentNodeId = actionNodeId;
                CFGNode& actionNode = nodes[actionNodeId];

                // 获取动作定义并处理
                const IR::P4Action* actionDef = findActionDefinition(actionName);
                // irNodeIds.insert(currentNodeId, actionDef->id);
                if (actionDef == nullptr || actionDef->body == nullptr) {
                    ::warning("无法在表 %1% 中找到动作定义 %2%", tableName, actionName);
                    continue; // 继续处理其他规则
                }

                irNodeIds[currentNodeId].insert(actionDef->id);

                // 创建动作实例
                ActionInstance actionInstance = {actionDef, actionParams};
                std::vector<std::string> strs;
                for (auto &param: actionParams) {
                    strs.push_back(std::string{param});
                }
                // 处理动作实例
                int actionExitNodeId = processActionInstance(actionInstance, strs);

                popCurrentNode();
                popCurrentNode();

                ruleExitNodeIds.push_back(actionExitNodeId);
            }
        }

        // 处理默认动作
        handleDefaultAction(table, tableName, keys, matchNodeId, ruleExist, actionListSize, false, ruleExitNodeIds);
    } else {
        // 表没有匹配键，但可能有默认动作
        // 直接处理默认动作
        handleDefaultAction(table, tableName, keys, tableNodeId, false, actionListSize, true, ruleExitNodeIds);
    }
    // 处理完全部 rule, defaultAction 之后:
    // Create a tableExit node
    int tableExitId = addNode("TableExit("+tableName+")", NodeType::MERGE, table, "TableExit");
    if (matchNodeId != INT32_MIN) {
        addEdge(matchNodeId, tableExitId, "");
        popCurrentNode();

    }
    popCurrentNode();
    // addEdge(tableNodeId, tableExitId, "table-exit", "sequential");
    for (auto exitNodeId : ruleExitNodeIds) {
        addEdge(exitNodeId, tableExitId, "table-exit");
    }

    // 让当前节点指向 tableExit
    currentNodeId = tableExitId;

    return false;
}

// 处理表达式节点（如果需要）
bool ControlFlowExtractor::preorder(const IR::Expression* expr) {
    if (switchFuncPosiLog)
        std::cout << "ControlFlowExtractor::preorder(const IR::Expression* expr)" << std::endl;

    // 根据需要实现表达式的处理逻辑
    // 这里暂时不处理，直接返回 true
    return false;
}

// 处理动作实例
int ControlFlowExtractor::processActionInstance(const ActionInstance& actionInstance, std::vector<std::string> actualParams) {
    const IR::P4Action* actionDef = actionInstance.actionDef;
    // 构建参数绑定表
    std::unordered_map<cstring, cstring> parameterBindings;
    size_t formalCount = actionDef->parameters->parameters.size();
    size_t actualCount = actualParams.size();

    if (actualCount != formalCount) {
        ::error("动作 %1% 的实参数量(%2%)与形参数量(%3%)不匹配。", actionDef->name, actualCount, formalCount);
    } else {
        for (size_t i = 0; i < formalCount; i++) {
            cstring formalName = actionDef->parameters->parameters.at(i)->name.name;
            const cstring actualVal = actualParams[i];
            if (!actualVal.find("PLACEHOLDER_REGISTERACTION_RESULT")) {
                parameterBindings[formalName] = actualVal;
            } else {
                parameterBindings[formalName] = "0";
            }
        }
    }

    // 使用一个专门的函数 visitActionBodyWithParameters 来处理
    if (actionDef->body != nullptr) {
        // 修改为使用 visitActionBodyWithParameters，而不是直接访问
        visitActionBodyWithParameters(actionDef->body, parameterBindings);
    }

    // 假设动作实例的退出节点为最后一个语句的节点
    return currentNodeId;
}

void ControlFlowExtractor::visitActionBodyWithParameters(
    const IR::BlockStatement* body,
    const std::unordered_map<cstring, cstring>& paramBindings)
{
    for (auto sOrDecl : body->components) {
        // irNodeIds[currentNodeId].insert(sOrDecl->id);
        // 1) 先判断是不是 IR::Statement
        if (auto subStmt = sOrDecl->to<IR::Statement>()) {
            // 让我们用 visitStatementWithParams 来处理具体的语句类型
            visitStatementWithParams(subStmt, paramBindings);
        }
        // 2) 若是 IR::Declaration
        else if (auto subDecl = sOrDecl->to<IR::Declaration>()) {
            // 这里可以做声明处理，或忽略
            // 如果你的 "RegisterAction body" 不会出现声明，也可以不处理
            // 如果要处理，可以参照你在 CFG 里对 Declaration_Variable 的处理
            // 例: handleDeclarationWithParams(subDecl, paramBindings);
        }
        // 3) 其他情况（很少见，比如注释/pragma?），可以忽略或做默认处理
    }
}

void ControlFlowExtractor::visitStatementWithParams(
    const IR::Statement* stmt,
    const std::unordered_map<cstring, cstring>& parameterBindings) {

    if (!stmt) return;

    // 1) IfStatement
    if (auto statement = stmt->to<IR::IfStatement>()) {
        cstring conditionExpr = Utils::translateExpression(statement->condition);
        // irNodeIds.insert(currentNodeId, statement->id);

        cstring conditionStr = "if (" + conditionExpr + ")";
        int conditionNodeId = addNode(conditionStr, NodeType::IF, statement->condition, conditionStr);

        addControlEdge(nodeStack.top(), conditionNodeId, conditionExpr, "control");
        pushCurrentNode(conditionNodeId);

        irNodeIds[conditionNodeId].insert(statement->id);

        CFGNode& node = nodes[conditionNodeId];
        Utils::extractUsedVariables(statement->condition, node.useVars);

        // 让当前节点 -> conditionNodeId
        addEdge(currentNodeId, conditionNodeId, "");
        irNodeIds[conditionNodeId].insert(statement->condition->id);
        currentNodeId = conditionNodeId;

        // 建一个 ifExit 节点，用来汇合
        int ifExitNodeId = addNode("IfExit", NodeType::MERGE, statement, "IfExit");

        // 处理 then 分支

        int trueId = addNode("if true", NodeType::CONDITION, statement->ifTrue, conditionStr + "if true");

        addControlEdge(nodeStack.top(), trueId, conditionExpr, "control");
        pushCurrentNode(trueId);

        addEdge(currentNodeId, trueId, "if true");
        currentNodeId = trueId;

        irNodeIds[currentNodeId].insert(statement->ifTrue->id);

        if (auto ifTrueStmt = statement->ifTrue->to<IR::BlockStatement>()) {
            visitStatementWithParams(ifTrueStmt, parameterBindings);
        }

        // visitStatementWithParams(ifStmt, parameterBindings);

        // irNodeIds.insert(currentNodeId, statement->ifTrue->id);
        popCurrentNode();
        int thenLastNode = currentNodeId;  // then 分支最后语句的节点
        // 加一条边 (thenLastNode -> ifExit)
        addEdge(thenLastNode, ifExitNodeId, "then-exit");

        currentNodeId = conditionNodeId;

        // 处理 else 分支
        if (statement->ifFalse != nullptr) {
            // irNodeIds.insert(currentNodeId, statement->ifFalse->id);
            int falseId = addNode("else", NodeType::CONDITION, statement->ifFalse, conditionStr + "->else");
            addControlEdge(nodeStack.top(), falseId, conditionExpr, "control");
            pushCurrentNode(falseId);
            addEdge(currentNodeId, falseId, "else");
            currentNodeId = falseId;
            irNodeIds[currentNodeId].insert(statement->ifFalse->id);

            if (auto ifFalseStmt = statement->ifFalse->to<IR::BlockStatement>()) {
                visitStatementWithParams(ifFalseStmt, parameterBindings);
            }

            int elseLastNode = currentNodeId;
            // 加一条边 (elseLastNode -> ifExit)
            addEdge(elseLastNode, ifExitNodeId, "else-exit");
            popCurrentNode();
            currentNodeId = conditionNodeId;
        } else {
            int falseId = addNode("else", NodeType::CONDITION, nullptr, conditionStr + "->else");
            addControlEdge(nodeStack.top(), falseId, conditionExpr, "control");
            pushCurrentNode(falseId);
            addEdge(currentNodeId, falseId, "else");
            addEdge(falseId, ifExitNodeId, "else-exit");
            popCurrentNode();
        }
        popCurrentNode();

        // 最后把 currentNodeId 设为 ifExitNodeId，让后续语句跟 ifExit 连
        currentNodeId = ifExitNodeId;
    }
    // 2) BlockStatement
    else if (auto block = stmt->to<IR::BlockStatement>()) {
        int blockEnterId = addNode("BlockEnter", NodeType::BLOCK, block, "BlockExit");
        addControlEdge(nodeStack.top(), blockEnterId, "block-enter", "control");
        pushCurrentNode(blockEnterId);
        addEdge(currentNodeId, blockEnterId, "block-exit", "sequential");
        // 同理：遍历 block->components
        for (auto sOrDecl : block->components) {
            if (auto subStmt = sOrDecl->to<IR::Statement>()) {
                visitStatementWithParams(subStmt, parameterBindings);
            } else if (auto subDecl = sOrDecl->to<IR::Declaration>()) {
                // handle or skip
            }
        }
        int blockExitId = addNode("BlockExit", NodeType::EXIT, block, "BlockExit");
        addEdge(currentNodeId, blockExitId, "block-exit", "sequential");
        popCurrentNode();
        currentNodeId = blockExitId;
    }
    // 3) AssignmentStatement
    else if (auto assignStmt = stmt->to<IR::AssignmentStatement>()) {
        const IR::Expression* leftExpr  = replaceParameters(assignStmt->left, parameterBindings);
        const IR::Expression* rightExpr = replaceParameters(assignStmt->right, parameterBindings);

        cstring leftStr  = Utils::translateExpression(leftExpr);
        cstring rightStr = Utils::translateExpression(rightExpr);

        cstring codeStr = leftStr + " = " + rightStr + ";";
        int stmtNodeId  = addNode(codeStr, NodeType::STATEMENT, assignStmt, codeStr);
        addControlEdge(nodeStack.top(), stmtNodeId, "block-enter", "control");
        pushCurrentNode(stmtNodeId);
        addEdge(currentNodeId, stmtNodeId, "", "sequential");
        currentNodeId = stmtNodeId;
        irNodeIds[currentNodeId].insert(assignStmt->id);
        CFGNode &node = nodes[stmtNodeId];
        cstring leftVar = Utils::getFullVariableName(leftExpr);
        node.genVars.insert(leftVar);
        Utils::extractUsedVariables(rightExpr, node.useVars);
        popCurrentNode();
    }
    // 4) MethodCallStatement
    else if (auto mcs = stmt->to<IR::MethodCallStatement>()) {
        // 获取方法名
        cstring methodName = Utils::translateExpression(mcs->methodCall);

        auto mi = P4::MethodInstance::resolve(mcs->methodCall, refMap, typeMap);
        if (auto applyMethod = mi->to<P4::ApplyMethod>()) {
            if (applyMethod->object->is<IR::P4Table>()) {
                auto table = applyMethod->object->to<IR::P4Table>();
                auto tbExpression = Utils::translateExpression(mcs->methodCall);
                int tbCallNodeId = addNode(tbExpression, NodeType::ACTION, statement, tbExpression);
                addEdge(currentNodeId, tbCallNodeId, "tb_call", "sequential");
                currentNodeId = tbCallNodeId;
                irNodeIds[currentNodeId].insert(mcs->id);
                pushCurrentNode(tbCallNodeId);
                visit(table);
                popCurrentNode();
                return ;
            }
        } else if (auto actionCall = mi->to<P4::ActionCall>()) {
            auto action = actionCall->action;

            cstring actionName = action->name.name;

            // 构建动作调用字符串
            std::stringstream actionCallStream;
            actionCallStream << actionName << "(";
            bool first = true;
            for (const auto& arg : *mcs->methodCall->arguments) {
                if (!first) actionCallStream << ", ";
                actionCallStream << Utils::translateExpression(arg->expression);
                first = false;
            }
            actionCallStream << ");";
            cstring actionCallStr = actionCallStream.str();

            // 添加动作节点
            int actionNodeId = addNode(actionCallStr, NodeType::ACTION, action, actionCallStr);
            addEdge(currentNodeId, actionNodeId, "", "sequential");
            addControlEdge(nodeStack.top(), actionNodeId, actionCallStr, "control");
            pushCurrentNode(actionNodeId);
            currentNodeId = actionNodeId;
            irNodeIds[currentNodeId].insert(actionCall->action->id);
            for (auto &arg: *mcs->methodCall->arguments) {
                std::cout << "MethodCallmcs arg: " << arg->expression->toString() << std::endl;
                Utils::extractUsedVariables(arg->expression, nodes[currentNodeId].useVars);
            }
            // 处理动作主体
            if (action->body != nullptr) {
                for (auto &stdc: action->body->components) {
                    if (auto st = stdc->to<IR::Statement>()) {
                        visitStatementWithParams(st, parameterBindings);
                    }
                }
            }
            popCurrentNode();
            return ;
        }
        if (std::string{mcs->toString()}.find(".read") != std::string::npos) {
            std::cout << "MethodCall mcs .read methodName: " << methodName << std::endl;
            std::size_t pos = std::string{mcs->toString()}.find(".read");
            cstring regName = mcs->toString().substr(0, pos).c_str(); // 提取出形如"sequence_reg"
            // e.g. 2 args: read(dest, idx)
            cstring destVar = Utils::getFullVariableName(mcs->methodCall->arguments->at(0)->expression);
            cstring idxVar  = Utils::getFullVariableName(mcs->methodCall->arguments->at(1)->expression);

            // registerName = methodName.substr(0, pos)  e.g. "sequence_reg"
            cstring codeStr = destVar + " = " + regName + "[" + "];";

            int stmtNodeId = addNode(codeStr, NodeType::STATEMENT, mcs, codeStr);
            addControlEdge(nodeStack.top(), stmtNodeId, codeStr, "control");
            pushCurrentNode(stmtNodeId);
            addEdge(currentNodeId, stmtNodeId, "", "sequential");
            currentNodeId = stmtNodeId;
            irNodeIds[currentNodeId].insert(mcs->id);

            // ---- def/use ----
            CFGNode &node = nodes[currentNodeId];
            // def
            node.genVars.insert(destVar);
            // use
            node.useVars.insert(regName + "[" + "]");
            node.useVars.insert(idxVar);
            // (若要把 registerName 整体也放进 useVars，不一定)
            popCurrentNode();
            return ;
        }
        if (std::string{mcs->toString()}.find(".write") != std::string::npos) {
            std::cout << "MethodCallmcs .read methodName: " << methodName << std::endl;

            std::size_t pos = std::string{mcs->toString()}.find(".write");
            cstring regName = mcs->toString().substr(0, pos).c_str(); // 提取出形如"sequence_reg"

            // e.g. 2 args: write(idx, val)
            cstring idxVar = Utils::getFullVariableName(mcs->methodCall->arguments->at(0)->expression);
            cstring valVar = Utils::getFullVariableName(mcs->methodCall->arguments->at(1)->expression);

            cstring codeStr = regName + "[" + "] = " + valVar + ";";

            int stmtNodeId = addNode(codeStr, NodeType::STATEMENT, mcs, codeStr);
            addControlEdge(nodeStack.top(), stmtNodeId, codeStr, "control");
            pushCurrentNode(stmtNodeId);
            addEdge(currentNodeId, stmtNodeId, "", "sequential");
            currentNodeId = stmtNodeId;
            irNodeIds[currentNodeId].insert(mcs->id);

            // ---- def/use ----
            CFGNode &node = nodes[currentNodeId];
            // def
            node.genVars.insert(regName + "[" + "]");
            // use
            node.useVars.insert(valVar);
            node.useVars.insert(idxVar);
            popCurrentNode();
            return ;
        }
        // case X: check if methodStr == "setValid(...)"
        if (methodName.find("setValid")) {
            // typical call: setValid(hdr.xxx)

            // 1) 提取第一个参数
            if (!mcs->methodCall->arguments->empty()) {
                auto argExpr = mcs->methodCall->arguments->at(0)->expression;
                cstring argName = Utils::getFullVariableName(argExpr);
                // e.g. argName = "hdr.mirror"

                // 2) 在 CFG 中添加一个节点
                //    生成形如 "setValid(hdr.mirror);" 的 code
                cstring codeStr = "setValid(" + argName + ");";
                int stmtNodeId = addNode(codeStr, NodeType::STATEMENT, mcs, codeStr);
                addControlEdge(nodeStack.top(), stmtNodeId, codeStr, "control");
                pushCurrentNode(stmtNodeId);
                addEdge(currentNodeId, stmtNodeId, "", "sequential");
                currentNodeId = stmtNodeId;
                irNodeIds[currentNodeId].insert(mcs->id);

                // 3) 在 genVars 里增加 "hdr.mirror.valid" => 说明这是一个“定义”
                //    同时，如果你也希望把 "hdr.mirror" 当作某种定义，可以一并添加
                CFGNode &node = nodes[stmtNodeId];

                // e.g. 生成 "hdr.mirror.valid"
                cstring validVar = argName + ".valid";
                node.genVars.insert(validVar);
                popCurrentNode();
            }
            return ;
        }

        // 其他方法调用
        cstring methodCallStr = Utils::translateExpression(mcs->methodCall);
        std::stringstream codeStream;
        codeStream << methodCallStr << ";";
        cstring codeStr = codeStream.str();
        // 添加方法调用节点
        int stmtNodeId = addNode(codeStr, NodeType::STATEMENT, mcs, codeStr);
        addControlEdge(nodeStack.top(), stmtNodeId, codeStr, "control");
        pushCurrentNode(stmtNodeId);
        addEdge(currentNodeId, stmtNodeId, "", "sequential");
        CFGNode &node = nodes[currentNodeId];
        currentNodeId = stmtNodeId;

        if (methodName.find(".execute")) {
            int pos = std::string{methodName}.find(".execute");
            cstring raInstanceName = methodName.substr(0, pos); // e.g. "someAction"
            // 添加方法调用节点
            irNodeIds[currentNodeId].insert(mcs->id);

            // 看看是不是RegisterAction
            auto it = registerActionMap.find(raInstanceName);
            if (it != registerActionMap.end()) {
                // 1) 先在 CFG 里做一个 mcs 节点: "someAction.execute(...)"
                cstring code = Utils::translateExpression(mcs->methodCall) + ";";
                auto &info = it->second;
                // 2) 准备 actionParams
                std::vector<cstring> actionParams;
                cstring idxVal = Utils::translateExpression(
                    mcs->methodCall->arguments->at(0)->expression);
                cstring inoutVal = info.registerName + "[" + "]";
                // 先解析 idx
                if (!mcs->methodCall->arguments->empty()) {
                    actionParams.push_back(inoutVal);
                }
                actionParams.push_back("PLACEHOLDER_REGISTERACTION_RESULT");

                // 3) 把它当作“动作调用”
                //    registerActionMap[raInstanceName].fakeAction
                const IR::P4Action* fakAct = info.fakeAction;

                // 4) 构建 ActionInstance
                ActionInstance ai;
                ai.actionDef = fakAct;
                ai.parameters = actionParams;
                std::vector<std::string> strs;
                for (auto &param: actionParams) {
                    strs.push_back(std::string{param});
                }
                // 5) 调用 processActionInstance
                int exitNodeId = processActionInstance(ai, strs);
                popCurrentNode();
                currentNodeId = exitNodeId;
                return ;
            }
        }

        // case 1: check if methodStr == "packet_in.extract"
        if (methodName.find(".extract")) {
            std::cout << "MethodCallmcs .extract methodName: " << methodName << std::endl;
            // typically 1 argument: e.g. extract(hdr.ethernet)
            if (!mcs->methodCall->arguments->empty()) {
                auto argExpr = mcs->methodCall->arguments->at(0)->expression;
                cstring argName = Utils::getFullVariableName(argExpr);
                // => genVars
                nodes[currentNodeId].genVars.insert(argName + ".valid");
                // irNodeIds[currentNodeId].insert(mcs->id);
                Utils::extractUsedVariables(mcs->methodCall->arguments->at(0)->expression, nodes[currentNodeId].useVars);
            }
        }
        // case 2: check if methodStr == "packet_out.emit"
        else if (methodName.find(".emit")) {
            std::cout << "MethodCallmcs .emit methodName: " << methodName << std::endl;
            // => useVars
            if (!mcs->methodCall->arguments->empty()) {
                auto argExpr = mcs->methodCall->arguments->at(0)->expression;
                cstring argName = Utils::getFullVariableName(argExpr);
                nodes[currentNodeId].useVars.insert(argName);
                irNodeIds[currentNodeId].insert(mcs->id);
                Utils::extractUsedVariables(mcs->methodCall->arguments->at(0)->expression, nodes[currentNodeId].useVars);
            }
        }
        else if (methodName.find(".isValid")) {
            std::cout << "MethodCallmcs .isValid methodName: " << methodName << std::endl;
            // => useVars
            if (!mcs->methodCall->arguments->empty()) {
                auto argExpr = mcs->methodCall->method;
                CFGNode& node = nodes[currentNodeId];
                cstring argName = Utils::getFullVariableName(argExpr);
                node.useVars.insert(argName + ".valid");
                nodes[currentNodeId].useVars.insert(argName);
                irNodeIds[currentNodeId].insert(mcs->id);
                node.useVars.insert(argName + ".valid");
            }
        }
        else if (methodName.find(".pop_front")) {
            std::cout << "MethodCallStatement .pop_front methodName: " << methodName << std::endl;
            // => useVars
            std::string spiltName{methodName};
            std::size_t pos = spiltName.find(".pop_front");
            cstring argName = methodName.substr(0, pos).c_str();
            CFGNode& n = nodes[currentNodeId];
            n.useVars.insert(argName);
            n.genVars.insert(argName);
            irNodeIds[currentNodeId].insert(mcs->id);
        }
        popCurrentNode();
    }
    else if (auto exitStmt = stmt->to<IR::ExitStatement>()) {
        // ...
        int exitNodeId = addNode("exit;", NodeType::STATEMENT, exitStmt, "exit;");
        addControlEdge(nodeStack.top(), exitNodeId, "block-enter", "control");

        addEdge(currentNodeId, exitNodeId, "", "sequential");
        currentNodeId = exitNodeId;
    }
    else {
        // 兜底处理
        cstring codeStr = stmt->toString().substr(0,128);
        int stmtNodeId  = addNode(codeStr, NodeType::STATEMENT, stmt, codeStr);
        addControlEdge(nodeStack.top(), stmtNodeId, "block-enter", "control");

        addEdge(currentNodeId, stmtNodeId, "", "sequential");
        currentNodeId = stmtNodeId;
    }
}

// 替换表达式中的参数
const IR::Expression* ControlFlowExtractor::replaceParameters(
    const IR::Expression* expr,
    const std::unordered_map<cstring, cstring>& parameterBindings
    ) {

    if (expr == nullptr) return nullptr;

    if (auto pathExpr = expr->to<IR::PathExpression>()) {
        cstring varName = pathExpr->path->name.name;
        auto it = parameterBindings.find(varName);
        if (it != parameterBindings.end()) {
            return new IR::PathExpression(IR::ID(it->second));
        }
        return expr;
    }
    if (auto path = expr->to<IR::Path>()) {
        cstring varName = path->name.name;
        auto it = parameterBindings.find(varName);
        if (it != parameterBindings.end()) {
            return new IR::PathExpression(IR::ID(it->second));
        }
        return expr;
    }
    if (auto member = expr->to<IR::Member>()) {
        const IR::Expression* newExpr = replaceParameters(member->expr, parameterBindings);
        return new IR::Member(newExpr, member->member);
    }
    if (auto methodCall = expr->to<IR::MethodCallExpression>()) {
        const IR::Expression* method = replaceParameters(methodCall->method, parameterBindings);
        auto newArguments = new IR::Vector<IR::Argument>();
        for (const auto& arg : *methodCall->arguments) {
            const IR::Expression* argExpr = replaceParameters(arg->expression, parameterBindings);
            newArguments->push_back(new IR::Argument(argExpr));
        }
        return new IR::MethodCallExpression(method, newArguments);
    }
    if (auto binaryExpr = expr->to<IR::Operation_Binary>()) {
        const IR::Expression* left = replaceParameters(binaryExpr->left, parameterBindings);
        const IR::Expression* right = replaceParameters(binaryExpr->right, parameterBindings);

        // 根据具体的二元操作类型创建新的表达式
        if (auto addExpr = binaryExpr->to<IR::Add>()) {
            return new IR::Add(addExpr->type, left, right);
        }
        if (auto subExpr = binaryExpr->to<IR::Sub>()) {
            return new IR::Sub(subExpr->type, left, right);
        }
        if (auto mulExpr = binaryExpr->to<IR::Mul>()) {
            return new IR::Mul(mulExpr->type, left, right);
        }
        if (auto divExpr = binaryExpr->to<IR::Div>()) {
            return new IR::Div(divExpr->type, left, right);
        }
        if (auto modExpr = binaryExpr->to<IR::Mod>()) {
            return new IR::Mod(modExpr->type, left, right);
        }
        if (auto equExpr = binaryExpr->to<IR::Equ>()) {
            return new IR::Equ(equExpr->type, left, right);
        }
        if (auto neqExpr = binaryExpr->to<IR::Neq>()) {
            return new IR::Neq(neqExpr->type, left, right);
        }
        if (auto lssExpr = binaryExpr->to<IR::Lss>()) {
            return new IR::Lss(lssExpr->type, left, right);
        }
        if (auto leqExpr = binaryExpr->to<IR::Leq>()) {
            return new IR::Leq(leqExpr->type, left, right);
        }
        if (auto grtExpr = binaryExpr->to<IR::Grt>()) {
            return new IR::Grt(grtExpr->type, left, right);
        }
        if (auto geqExpr = binaryExpr->to<IR::Geq>()) {
            return new IR::Geq(geqExpr->type, left, right);
        }
        if (auto landExpr = binaryExpr->to<IR::LAnd>()) {
            return new IR::LAnd(landExpr->type, left, right);
        }
        if (auto lorExpr = binaryExpr->to<IR::LOr>()) {
            return new IR::LOr(lorExpr->type, left, right);
        }
        if (auto bandExpr = binaryExpr->to<IR::BAnd>()) {
            return new IR::BAnd(bandExpr->type, left, right);
        }
        if (auto borExpr = binaryExpr->to<IR::BOr>()) {
            return new IR::BOr(borExpr->type, left, right);
        }
        if (auto bxorExpr = binaryExpr->to<IR::BXor>()) {
            return new IR::BXor(bxorExpr->type, left, right);
        }
        if (auto shlExpr = binaryExpr->to<IR::Shl>()) {
            return new IR::Shl(shlExpr->type, left, right);
        }
        if (auto shrExpr = binaryExpr->to<IR::Shr>()) {
            return new IR::Shr(shrExpr->type, left, right);
        }
        return expr;
    }
    if (auto unaryExpr = expr->to<IR::Operation_Unary>()) {
        const IR::Expression* operand = replaceParameters(unaryExpr->expr, parameterBindings);

        // 根据具体的一元操作类型创建新的表达式
        if (auto negExpr = unaryExpr->to<IR::Neg>()) {
            return new IR::Neg(negExpr->type, operand);
        }
        if (auto cplExpr = unaryExpr->to<IR::Cmpl>()) {
            return new IR::Cmpl(cplExpr->type, operand);
        }
        if (auto lnotExpr = unaryExpr->to<IR::LNot>()) {
            return new IR::LNot(lnotExpr->type, operand);
        }
        // 如果遇到未处理的一元操作类型，返回原始表达式
        return expr;
    }
    if (auto methodCall = expr->to<IR::MethodCallExpression>()) {
        const IR::Expression* method = replaceParameters(methodCall->method, parameterBindings);
        auto newArguments = new IR::Vector<IR::Argument>();
        for (const auto& arg : *methodCall->arguments) {
            const IR::Expression* argExpr = replaceParameters(arg->expression, parameterBindings);
            newArguments->push_back(new IR::Argument(argExpr));
        }
        return new IR::MethodCallExpression(method, newArguments);
    }
    if (auto castExpr = expr->to<IR::Cast>()) {
        const IR::Expression* newExpr = replaceParameters(castExpr->expr, parameterBindings);
        return new IR::Cast(castExpr->type, newExpr);
    }
    if (auto arrayIndexExpr = expr->to<IR::ArrayIndex>()) {
        const IR::Expression* left = replaceParameters(arrayIndexExpr->left, parameterBindings);
        const IR::Expression* right = replaceParameters(arrayIndexExpr->right, parameterBindings);
        return new IR::ArrayIndex(left, right);
    }
    if (auto sliceExpr = expr->to<IR::Slice>()) {
        const IR::Expression* e0 = replaceParameters(sliceExpr->e0, parameterBindings);
        const IR::Expression* e1 = replaceParameters(sliceExpr->e1, parameterBindings);
        const IR::Expression* e2 = replaceParameters(sliceExpr->e2, parameterBindings);
        return new IR::Slice(e0, e1, e2);
    }
    if (auto listExpr = expr->to<IR::ListExpression>()) {
        auto newComponents = new IR::Vector<IR::Expression>();
        for (const auto& component : listExpr->components) {
            const IR::Expression* newComponent = replaceParameters(component, parameterBindings);
            newComponents->push_back(newComponent);
        }
        return new IR::ListExpression(*newComponents);
    }
    // 对于其他类型的表达式，直接返回原始表达式
    return expr;
}


bool ControlFlowExtractor::preorder(const IR::Type_Struct* typeStruct) {
    if (switchFuncPosiLog)
        std::cout << "ControlFlowExtractor::preorder(const IR::Type_Struct* typeStruct)" << std::endl;

    std::string structName{typeStruct->name.name};

    // 检查是否已经处理过该 Struct，防止重复处理
    if (processedStructs.find(structName) != processedStructs.end()) {
        return false;
    }

    processedStructs.insert(structName);

    // 填充 structDefinitions 映射
    structDefinitions[structName] = typeStruct;

    StructVariableInfo svi;
    svi.structTypeName = structName;

    // 假设 struct 变量名与 struct 类型名相同
    svi.variableName = structName;

    // 提取 Struct 的字段信息
    extractStructFields(typeStruct, svi);

    // 将提取的信息添加到 structVariables
    structVariables.push_back(svi);

    // std::cout << "提取 Struct: " << structName << std::endl;

    return false; // 继续遍历
}

// 重写 preorder 方法，处理 IR::Type_Header 节点
bool ControlFlowExtractor::preorder(const IR::Type_Header* typeHeader) {
    if (switchFuncPosiLog)
        std::cout << "ControlFlowExtractor::preorder(const IR::Type_Header* typeHeader)" << std::endl;

    std::string headerName{typeHeader->name.name};

    // 检查是否已经处理过该 TypeHeader，防止重复处理
    if (processedTypeHeaders.find(headerName) != processedTypeHeaders.end()) {
        return false;
    }

    processedTypeHeaders.insert(headerName);

    // 填充 typeHeaderDefinitions 映射
    typeHeaderDefinitions[headerName] = typeHeader;

    TypeHeaderInfo thi;
    thi.headerName = headerName;
    thi.typeName = headerName; // 假设 header 名称即为类型名称

    // 提取 TypeHeader 的字段信息
    extractTypeHeaderFields(typeHeader, thi);

    // 将提取的信息添加到 typeHeaders
    typeHeaders.push_back(thi);

    // std::cout << "提取 TypeHeader: " << headerName << std::endl;

    return false; // 继续遍历
}


void ControlFlowExtractor::extractStructFields(const IR::Type_Struct* typeStruct, StructVariableInfo& svi) {
    for (const auto* field : typeStruct->fields) {
        std::string fieldName{field->name.name};
        std::string fieldType{Utils::translateType(field->type)}; // 使用 Utils::translateType

        // 检查字段是否为 Struct 数组
        if (auto typeList = field->type->to<IR::Type_List>()) {
            // 这是一个数组类型
            std::string elementType{Utils::translateType(typeList)};
            unsigned long arraySizeChar = typeList->size();
            std::string arraySizeStr{(char)arraySizeChar};
            int arraySize = 0;

            try {
                arraySize = std::stoi(arraySizeStr);
            } catch (const std::invalid_argument& e) {
                std::cerr << "无法解析数组大小: " << arraySizeStr << " for field " << fieldName << std::endl;
                continue;
            }
            // std::cout << "Struct " << svi.structTypeName << " 的字段数组 " << fieldName << " 大小为 " << arraySize << std::endl;
            for (int i = 0; i < arraySize; ++i) {
                StructFieldInfo expandedField;
                expandedField.name = fieldName + "[" + std::to_string(i) + "]";
                expandedField.type = elementType;
                svi.fields.push_back(expandedField);

                // std::cout << "展开字段: " << expandedField.name << " 类型: " << expandedField.type << std::endl;

                // 如果元素类型也是 struct，递归提取其字段
                auto it = structDefinitions.find(elementType);
                if (it != structDefinitions.end()) {
                    const IR::Type_Struct* nestedStruct = it->second;
                    if (processedStructs.find(elementType) == processedStructs.end()) {
                        preorder(nestedStruct);
                    }
                }
            }
        }
        else if (field->type->is<IR::Type_Struct>() || field->type->is<IR::Type_StructLike>()) {
            // 如果字段类型是另一个 struct，递归提取其字段
            StructFieldInfo fieldInfo;
            fieldInfo.name = fieldName;
            fieldInfo.type = fieldType;
            svi.fields.push_back(fieldInfo);

            // std::cout << "字段: " << fieldInfo.name << " 类型: " << fieldInfo.type << std::endl;

            // 获取 Struct 定义
            std::string nestedStructName = fieldType;
            auto it = structDefinitions.find(nestedStructName);
            if (it != structDefinitions.end()) {
                const IR::Type_Struct* nestedStruct = it->second;
                if (processedStructs.find(nestedStructName) == processedStructs.end()) {
                    preorder(nestedStruct);
                }
            }
        }
        else {
            // 非数组、非嵌套 struct 字段
            StructFieldInfo fieldInfo;
            fieldInfo.name = fieldName;
            fieldInfo.type = fieldType;
            svi.fields.push_back(fieldInfo);

            // std::cout << "字段: " << fieldInfo.name << " 类型: " << fieldInfo.type << std::endl;
        }
    }
}



// 辅助函数：递归提取 TypeHeader 的字段信息
void ControlFlowExtractor::extractTypeHeaderFields(const IR::Type_Header* typeHeader, TypeHeaderInfo& thi) {
    for (const auto* field : typeHeader->fields) {
        std::string fieldName{field->name.name};
        std::string fieldType{Utils::translateType(field->type)}; // 使用 Utils::translateType

        // TypeHeader 中的字段通常不包含数组，但可以根据需要添加支持
        if (auto typeList = field->type->to<IR::Type_List>()) {
            // 这是一个数组类型
            std::string elementType{Utils::translateType(typeList)};
            std::string arraySizeStr{(char)typeList->size()};
            int arraySize = 0;

            try {
                arraySize = std::stoi(arraySizeStr);
            } catch (const std::invalid_argument& e) {
                std::cerr << "无法解析数组大小: " << arraySizeStr << " for field " << fieldName << std::endl;
                continue;
            }

            // std::cout << "TypeHeader " << thi.headerName << " 的字段数组 " << fieldName << " 大小为 " << arraySize << std::endl;

            for (int i = 0; i < arraySize; ++i) {
                TypeHeaderFieldInfo expandedField;
                expandedField.name = fieldName + "[" + std::to_string(i) + "]";
                expandedField.type = elementType;
                thi.fields.push_back(expandedField);

                // std::cout << "展开字段: " << expandedField.name << " 类型: " << expandedField.type << std::endl;

                // 如果元素类型也是 struct 或 header，递归提取其字段
                // 检查 Struct 定义
                if (structDefinitions.find(elementType) != structDefinitions.end()) {
                    const IR::Type_Struct* nestedStruct = structDefinitions[elementType];
                    if (processedStructs.find(elementType) == processedStructs.end()) {
                        // 递归处理嵌套 Struct
                        preorder(nestedStruct);
                    }
                }
                // 检查 TypeHeader 定义
                if (typeHeaderDefinitions.find(elementType) != typeHeaderDefinitions.end()) {
                    const IR::Type_Header* nestedHeader = typeHeaderDefinitions[elementType];
                    if (processedTypeHeaders.find(elementType) == processedTypeHeaders.end()) {
                        // 递归处理嵌套 TypeHeader
                        preorder(nestedHeader);
                    }
                }
            }
        }
        else if (field->type->is<IR::Type_Struct>() || field->type->is<IR::Type_StructLike>() ||
                 field->type->is<IR::Type_Header>() || field->type->is<IR::Type_HeaderUnion>()) {
            // 如果字段类型是另一个 struct 或 header，递归提取其字段
            TypeHeaderFieldInfo fieldInfo;
            fieldInfo.name = fieldName;
            fieldInfo.type = fieldType;
            thi.fields.push_back(fieldInfo);

            // std::cout << "字段: " << fieldInfo.name << " 类型: " << fieldInfo.type << std::endl;

            // 获取 Struct 定义
            if (structDefinitions.find(fieldType) != structDefinitions.end()) {
                const IR::Type_Struct* nestedStruct = structDefinitions[fieldType];
                if (processedStructs.find(fieldType) == processedStructs.end()) {
                    // 递归处理嵌套 Struct
                    preorder(nestedStruct);
                }
            }
            // 获取 TypeHeader 定义
            if (typeHeaderDefinitions.find(fieldType) != typeHeaderDefinitions.end()) {
                const IR::Type_Header* nestedHeader = typeHeaderDefinitions[fieldType];
                if (processedTypeHeaders.find(fieldType) == processedTypeHeaders.end()) {
                    // 递归处理嵌套 TypeHeader
                    preorder(nestedHeader);
                }
            }
        }
        else {
            // 非数组、非嵌套 struct/header 字段
            TypeHeaderFieldInfo fieldInfo;
            fieldInfo.name = fieldName;
            fieldInfo.type = fieldType;
            thi.fields.push_back(fieldInfo);

            // std::cout << "字段: " << fieldInfo.name << " 类型: " << fieldInfo.type << std::endl;
        }
    }
}

bool ControlFlowExtractor::preorder(const IR::Declaration_Instance* decl) {
    if (switchFuncPosiLog)
        std::cout << "ControlFlowExtractor::preorder(const IR::Declaration_Instance* decl)" << std::endl;
    /* debug code here
    {
        std::string dbgStr{decl->toString()};
        std::string typeStr{decl->node_type_name()};
        std::string dbgStr2{decl->type->toString()};
        std::cout << "[preorder(IR::Declaration_Instance)] -> "
                  << "node toString = " << dbgStr.substr(0, 80) << ","
                  << "node type = " << typeStr << ","
                  << "type toString = " << dbgStr2.substr(0, 80) << "...\n";
        if (dbgStr.find("register") != std::string::npos || typeStr.find("register") != std::string::npos || dbgStr2.find("register") != std::string::npos) {
            std::cout << "  >>> Found 'register' in IR::Declaration_Instance <<<\n";
        }
    }
    */
    // 1) 检查是不是寄存器类型
    //    判断方式之一：看看 decl->type 是否是 Type_Specialized，baseType 是否为 "register"
    cstring specializedType = Utils::translateType(decl->type);
    // 判断是不是 pipeline / V1Switch
    if (specializedType.find("Pipeline") ||
        specializedType.find("V1Switch")) {

        // 1) 在 CFG 里先加一个节点
        cstring pipelineNodeName = "decl_pipeline " + decl->name.name;
        int pipelineNodeId = addNode(pipelineNodeName,
                                     NodeType::DECLARATION,
                                     decl,
                                     specializedType);

        addEdge(currentNodeId, pipelineNodeId, "", "sequential");
        currentNodeId = pipelineNodeId;
        // irNodeIds[currentNodeId].insert(decl->id);

        // 2) 记录到 pipelineInfos
        PipelineInfo pinfo;
        pinfo.pipelineName = decl->name.name;      // e.g. "pipe"
        pinfo.declInstance = decl;

        // 3) 收集 pipeline arguments
        int idx = 0;
        for (auto argument : *decl->arguments) {
            idx++;
            // argument->expression 里通常是 "Ingress()", "IngressDeparser()", ...
            cstring exprStr = argument->expression->toString();
            // 或者你也可以再解析 PathExpression 取 name

            PipelineComponent comp;
            comp.instanceName = Utils::translateExpression(argument->expression);  // 先给个匿名
            comp.expressionString = exprStr;
            pinfo.components.push_back(comp);

            // 在 CFG 上，你也可以加个 "pipeline_EXIT_x" 节点，用来表示子组件位置
            int childNodeId = addNode(
                "pipeline_STAGE_" + std::to_string(idx),
                NodeType::CONTROL,  // or NodeType::CONTROL
                argument->expression,
                exprStr);
            pipelineNodeMap.insert(std::make_pair(exprStr, childNodeId));
        }

        // 把 pinfo 存起来，后面二次遍历用
        pipelineInfos.push_back(pinfo);

        return false;
        }
    if (specializedType.find("RegisterAction")) {
        cstring instanceName = decl->name.name;  // "myAction"
        cstring realRegName  = Utils::translateExpression((*decl->arguments)[0]->expression); // "myRealReg"
        auto function        = decl->initializer->components[0]->to<IR::Function>();

        irNodeIds[currentNodeId].insert(function->id);

        // 1) 根据 function->type->parameters，构造一个“伪 P4Action”
        //    这里演示思路，可用 IR builder 或一个自定义结构。
        // 把 function->parameters->parameters 复制到 fakeAction->parameters
        auto paramsVec = function->type->parameters->parameters;
        IR::ParameterList *params = new IR::ParameterList(paramsVec);
        auto fakeAction = new IR::P4Action(IR::ID(instanceName), params, function->body);

        // fakeAction->parameters = params;

        // 2) 记录到一个映射，方便后面 `.execute(...)` 找到
        RegisterActionInfo info;
        info.registerName  = realRegName;  // 底层寄存器
        info.fakeAction    = fakeAction;
        registerActionMap[instanceName] = info;

        // 3) 在 CFG 里加个声明节点
        int nodeId = addNode("decl_registerAction " + instanceName,
                             NodeType::DECLARATION, decl, specializedType);
        addControlEdge(nodeStack.top(), nodeId, decl->name.name, "control");
        pushCurrentNode(nodeId);
        addEdge(currentNodeId, nodeId, "", "sequential");
        currentNodeId = nodeId;
        irNodeIds[nodeId].insert(decl->id);
        popCurrentNode();
        return false;
    }

    if (specializedType.find("register") || specializedType.find("Register")) {
        // ---- 这是一个寄存器声明 ----
        // 提取寄存器名: decl->name.name
        ::warning("Found register declaration: %1%", decl->name);
        std::string regName{decl->name.name};  // e.g. "myReg"

        // 提取 size: 通常寄存器声明形如 register<bit<16>>(128)
        //   decl->arguments->[0] 通常给出寄存器大小
        //   decl->arguments->[1] 若有 可能是 indexType
        std::string sizeStr = "";
        if (!decl->arguments->empty()) {
            auto constant = (*decl->arguments)[0]->expression->to<IR::Constant>();
            sizeStr = constant->value.str();
        }
        // 提取寄存器的存储类型 (valueType)
        std::string valueTypeStr = "";
        if (specializedType) {
            // specializedType->arguments->front() 是 IR::Type_Bits / IR::Type_Something
            valueTypeStr = specializedType;
        }
        // 提取寄存器的 indexType
        //   如果 arguments->size() > 1，第二个就是 indexType
        std::string indexTypeStr = "int"; // default
        auto valueType = decl->type->to<IR::Type_Specialized>();

        if((*valueType->arguments).size() > 1){
            indexTypeStr = Utils::translateType((*valueType->arguments)[1]);
        }
        else{
            indexTypeStr = "int";
        }

        // ---- 保存到 RegisterInfo 并 push_back 到 registers ----
        RegisterInfo ri;
        ri.name       = regName;
        ri.size       = sizeStr;       // e.g. "128"
        ri.valueType  = valueTypeStr;  // e.g. "bit<16>"
        ri.indexType  = indexTypeStr;  // e.g. "int"
        registers.push_back(ri);

        // ---- 同时在 CFG 里也生成一个 DECLARATION 节点 ----
        int nodeId = addNode("decl_register " + regName,
                             NodeType::DECLARATION,
                             decl,
                             valueTypeStr + " " + regName + "[" + sizeStr + "]");
        addControlEdge(nodeStack.top(), nodeId, decl->name.name, "control");
        pushCurrentNode(nodeId);
        // 让当前图上的节点 -> 这个声明节点
        addEdge(currentNodeId, nodeId, "", "sequential");
        currentNodeId = nodeId;
        // addAllDescendants(currentNodeId, decl);
        irNodeIds[currentNodeId].insert(decl->id);
        popCurrentNode();
        // 不需要 update currentNodeId，因为声明可能只是一个语句
        return false;
    }

    return false;  // 继续遍历
}

bool ControlFlowExtractor::preorder(const IR::Declaration_Variable* declVar) {
    if (switchFuncPosiLog)
        std::cout << "ControlFlowExtractor::preorder(const IR::Declaration_Variable* declVar)" << std::endl;

    // 这是一个普通变量声明: e.g. "bit<32> myVar = 100;"
    /*
    {
        std::string dbgStr{declVar->toString()};
        std::cout << "[preorder(IR::Declaration_Instance)] -> "
                  << "node toString = " << dbgStr.substr(0, 80) << "...\n";
        if (dbgStr.find("register") != std::string::npos) {
            std::cout << "  >>> Found 'register' in IR::Declaration_Instance <<<\n";
        }
    }
    */
    // 1) 提取 name: declVar->name.name
    std::string varName{declVar->name.name};
    // 2) 提取 type: declVar->type
    std::string varType{Utils::translateType(declVar->type)};  // e.g. "bit<32>"

    // 3) 如果有 initializer，则可以 translateExpression(declVar->initializer) 取其值
    //    还可以抽取 useVars
    std::string initValStr = "";
    if (declVar->initializer != nullptr) {
        initValStr = Utils::translateExpression(declVar->initializer);
    }

    // 4) 在 CFG 里加个声明节点
    std::stringstream ss;
    ss << "decl_var " << varType << " " << varName;
    if (!initValStr.empty()) {
        ss << " = " << initValStr;
    }
    int declNodeId = addNode(ss.str(), NodeType::DECLARATION, declVar, ss.str());
    addControlEdge(nodeStack.top(), declNodeId, declVar->name.name, "control");
    pushCurrentNode(declNodeId);
    addEdge(currentNodeId, declNodeId, "", "sequential");
    currentNodeId = declNodeId;
    // irNodeIds.insert(currentNodeId, declVar->id);
    // addAllDescendants(currentNodeId, declVar);
    CFGNode &node = nodes[declNodeId];
    node.genVars.insert(varName);
    if (declVar->initializer != nullptr) {
        Utils::extractUsedVariables(declVar->initializer, node.useVars);
    }
    popCurrentNode();
    return false;
}

void ControlFlowExtractor::addAllDescendants(int cfgNodeId, const IR::Node* top) {
    if (!top) return;
    IrIdCollector collector;
    top->apply(collector);  // 递归遍历
    for (auto &nid : collector.getChildrenIds()) {
        irNodeIds[cfgNodeId].insert(nid);
    }
}

void ControlFlowExtractor::buildPipelineInternals(const IR::P4Program* program) {
    // 这里可以把 currentNodeId 暂存一下
    int savedCurrentNode = currentNodeId;

    // 遍历所有 pipelineInfos
    for (auto &pinfo : pipelineInfos) {
        auto &pcomps = pinfo.components;  // pipeline 中的所有子组件

        // 找到 pipeline 在 CFG 中的 "decl_pipeline X" 节点 ID
        // 可能要记录一下 pinfo <-> pipelineNodeId
        // 如果你在第一遍就存好了 pipelineNodeId，也可直接拿
        // 这里示例:我们只对子组件做后续遍历

        // 逐个子组件
        for (size_t i = 0; i < pcomps.size(); i++) {
            auto &comp = pcomps[i];
            // comp.expressionString 形如 "Ingress()" or "EgressParser()"
            // 先把 "()", ";" 等符号去掉，只保留 "IngressParser" 这个名字
            // 简单做法：取到第一个 "(" 为止
            std::string expr = comp.expressionString.c_str();
            size_t pos = expr.find("(");
            if (pos != std::string::npos) {
                expr = expr.substr(0, pos);
            }
            // 可能还有空格或别的修饰

            // 到 program->objects 里找同名的 P4Control / P4Parser
            const IR::Node* found = nullptr;
            for (auto obj : program->objects) {
                if (auto c = obj->to<IR::P4Control>()) {
                    if (c->name.name == expr) {
                        found = c;
                        break;
                    }
                } else if (auto p = obj->to<IR::P4Parser>()) {
                    if (p->name.name == expr) {
                        found = p;
                        break;
                    }
                }
            }

            if (!found || comp.instanceName.find("Deparser") || comp.instanceName.find("deparser") || comp.instanceName.find("De") || comp.instanceName.find("de")) {
                ::warning("No P4Control or P4Parser named %1% found in program!", expr.c_str());
                continue; // 下一个组件
            }

            // 把 currentNodeId 切换到 pipeline_STAGE_i
            int stageNodeId = pipelineNodeMap[std::string{comp.expressionString}];
            addControlEdge(nodeStack.top(), stageNodeId, comp.instanceName, "control");
            addEdge(currentNodeId, stageNodeId, comp.instanceName, "sequential");

            std::cout << "Switching to pipeline stage " << comp.expressionString << " at node " << stageNodeId << std::endl;
            if (stageNodeId >= 0) {
                currentNodeId = stageNodeId;
            }
            pushCurrentNode(stageNodeId);
            // 调用 visit()，让 CFGExtractor 递归到 control / parser 内部
            this->visit(found);
            popCurrentNode();
        }
    }
    // currentNodeId = savedCurrentNode; // 恢复
}
