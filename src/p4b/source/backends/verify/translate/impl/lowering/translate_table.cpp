#include "translate.h"

#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <vector>

namespace {

bool isNoActionName(const cstring& actionName) {
    if (actionName == nullptr) {
        return false;
    }
    std::string s(actionName.c_str());
    return s == "NoAction" || s.rfind("NoAction_", 0) == 0;
}

}  // namespace

void Translator::translate(const IR::P4Table *p4Table){
    cstring name = translate(p4Table->name);
    cstring tableName = name+".apply";

    if (options.slicingEnabled && options.slicingFilterTables &&
        options.slicingKeepTables.count(name) == 0) {
        return;
    }
    BoogieProcedure table = BoogieProcedure(tableName);
    bool hasIfChain = false;
    table.addDeclaration("\n// Table "+name+"\n");
    table.addDeclaration("procedure {:inline 1} "+tableName+"()\n");
    table.setImplemented();
    addDeclaration("\n// Table "+name+" Actionlist Declaration\n");
    addDeclaration("type "+name+".action;\n");
    incIndent();
    // Consider keys
    // Keys are not changed and this is only for key access validity checking
    if(!options.ultimateAutomizer){
        for(auto property:p4Table->properties->properties){
            if (auto key = property->value->to<IR::Key>()) {
                for(auto keyElement:key->keyElements){
                    cstring expr = translate(keyElement->expression);
                    if(expr!=nullptr && expr.find("[")==nullptr && expr.find("(")==nullptr) {
                        std::string stmt(getIndent());
                        stmt += expr;
                        stmt += " := ";
                        stmt += expr;
                        stmt += ";\n";
                        table.addStatement(stmt);
                        table.addModifiedGlobalVariables(expr);
                    }
                }
            }
        }
    }
    else {
        for(auto property:p4Table->properties->properties){
            if (auto key = property->value->to<IR::Key>()) {
                for(auto keyElement:key->keyElements){
                    cstring expr = translate(keyElement->expression);

                    cstring tableKeySpec = "Key("+name+","+expr+")";
                    bool existInSpec = false;
                    for(cstring str:P4LTL_KEYS){
                        if(options.CpiIfElse && str == P4LTL_KEYS_CPI_MODEL)
                            continue;
                        if(p4ltlSpec.find(str) != p4ltlSpec.end()){
                            for(auto spec:p4ltlSpec[str]){
                                cstring cont = spec->toString();
                                if(cont.find(tableKeySpec) != nullptr){
                                    existInSpec = true;
                                    break;
                                }
                            }
                        }
                        if(existInSpec) break;
                    }
                    if(!existInSpec) continue;
                    if(expr!=nullptr && expr.find("[")==nullptr && expr.find("(")==nullptr) {
                        cstring tableKey = name+"."+expr;
                        cstring declInt = expr+":int";
                        cstring declBool = expr+":bool";
                        if(declaration.find(declInt) != nullptr){
                            addDeclaration("var "+tableKey+":int;\n");
                        }
                        else if(declaration.find(declBool) != nullptr){
                            addDeclaration("var "+tableKey+":bool;\n");
                        }
                        addGlobalVariables(tableKey);
                        table.addModifiedGlobalVariables(tableKey);
                        table.addStatement(getIndent()+tableKey+" := "+expr+";\n");           
                    }
                }
            }
        }
    }

    bool ruleExist = false;
    if(options.CpiIfElse){
        bool firstRule = true;
        if(p4ltlSpec.find(P4LTL_KEYS_CPI_MODEL) != p4ltlSpec.end()){
            for(auto spec:p4ltlSpec[P4LTL_KEYS_CPI_MODEL]){
                CPIRule* rule = ltlTranslator->analyzeRule(spec);
                if(rule != nullptr){
                    if(rule->getTable() == name){
                        ruleExist = true;
                        cstring condition = "if(";
                        if(firstRule) firstRule = false;
                        else condition = "else "+condition;
                        condition = getIndent()+condition;
                        bool first = true;
                        for(auto item:rule->getKeys()){
                            if(first) first = false;
                            else condition += " && ";
                            condition += item.first+item.second;
                        }
                        condition += "){\n";
                        table.addStatement(condition);
                        incIndent();
                        cstring params = "";
                        bool firstParam = true;
                        for(auto item:rule->getParams()){
                            if(firstParam) firstParam = false;
                            else params += ", ";
                            params += item;
                        }
                        table.addStatement(getIndent()+"call "+rule->getAction()+"("+params+");\n");
                        table.addSucc(rule->getAction());
                        addPred(rule->getAction(), tableName);
                        decIndent();
                        table.addStatement(getIndent()+"}\n");
                    }
                }
            }
        } 
    }

    bool existInSpec = false;
    cstring tableApplySpec = "Apply("+name;
    for(cstring str:P4LTL_KEYS){
        if(options.CpiIfElse && str == P4LTL_KEYS_CPI_MODEL)
                continue;
        if(p4ltlSpec.find(str) != p4ltlSpec.end()){
            for(auto spec:p4ltlSpec[str]){
                cstring cont = spec->toString();
                if(cont.find(tableApplySpec) != nullptr){
                    existInSpec = true;
                    break;
                }
            }
        }
        if(existInSpec) break;
    }
    if(existInSpec){
        cstring tableIsApplied = name+".isApplied";
        addDeclaration("var "+tableIsApplied+":bool;\n");
        addGlobalVariables(tableIsApplied);
        table.addStatement("\n    "+tableIsApplied+" := true;\n");
        table.addModifiedGlobalVariables(tableIsApplied);
        havocProcedure.addStatement("    "+tableIsApplied+" := false;\n");
        havocProcedure.addModifiedGlobalVariables(tableIsApplied);
    }

    if(!ruleExist) {
        cstring gotoStmt = getIndent()+"goto ";

        for(auto property:p4Table->properties->properties){
            if (auto actionList = property->value->to<IR::ActionList>()) {
                // add local variables
                for(auto actionElement:actionList->actionList){
                    if(auto actionCallExpr = actionElement->expression->to<IR::MethodCallExpression>()){
                        cstring actionName = translate(actionCallExpr->method);
                        if (isNoActionName(actionName)) {
                            continue;
                        }
                        auto actionIt = actions.find(actionName);
                        if (actionIt == actions.end() || actionIt->second == nullptr) {
                            continue;
                        }
                        const IR::P4Action* action = actionIt->second;
                        for(auto parameter:action->parameters->parameters){
                            if(options.ultimateAutomizer && options.bitBlasting &&
                                parameter->type->to<IR::Type_Bits>()){
                                auto typeBits = parameter->type->to<IR::Type_Bits>();
                                cstring parameterName = actionName+"."+translate(parameter->name);
                                for(int i = 0; i < typeBits->size; i++){
                                    table.addFrontStatement("    var "+connect(parameterName, i)+":bool;\n");
                                }
                            }
                            else{
                                cstring parameterName = name+"."+actionName+"."+translate(parameter->name);
                                // table.addFrontStatement("    var "+actionName+"."+translate(parameter)+";\n");
                                addDeclaration("var "+name+"."+actionName+"."+translate(parameter)+";\n");
                                addGlobalVariables(parameterName);
                                havocProcedure.addModifiedGlobalVariables(parameterName);
                                havocProcedure.addStatement("    havoc "+parameterName+";\n");
                            }
                        }
                    }
                }

                // const entries (static table entries)
                //
                // P4 tables may define `const entries = { ... }`, which are matched in program
                // order at runtime. When these are present, we must translate them into
                // key-dependent conditionals (instead of an unconstrained action choice).
                auto entriesList = p4Table->getEntries();
                if (entriesList != nullptr && !entriesList->entries.empty()) {
                    std::vector<cstring> keyExprs;
                    std::vector<int> keyWidths;
                    if (auto key = p4Table->getKey()) {
                        for (auto keyElement : key->keyElements) {
                            cstring expr = translate(keyElement->expression);
                            keyExprs.push_back(expr);
                            int width = -1;
                            if (auto typeBits = keyElement->expression->type->to<IR::Type_Bits>()) {
                                width = typeBits->size;
                            } else if (keyElement->expression->type->is<IR::Type_Boolean>()) {
                                width = 1;
                            } else if (auto typeName = keyElement->expression->type->to<IR::Type_Name>()) {
                                cstring typeAlias = translate(typeName->path);
                                if (typeDefs.find(typeAlias) != typeDefs.end()) {
                                    width = typeDefs[typeAlias];
                                }
                            }
                            keyWidths.push_back(width);
                        }
                    }

                    auto getDefaultActionNoArgs = [&]() -> cstring {
                        cstring defaultActionName = nullptr;
                        for (auto prop : p4Table->properties->properties) {
                            if (prop->getName() != "default_action") {
                                continue;
                            }
                            if (auto ev = prop->value->to<IR::ExpressionValue>()) {
                                const IR::Expression* expr = ev->expression;
                                if (auto mce = expr->to<IR::MethodCallExpression>()) {
                                    if (mce->arguments == nullptr || mce->arguments->size() == 0) {
                                        defaultActionName = translate(mce->method);
                                    }
                                } else if (auto pe = expr->to<IR::PathExpression>()) {
                                    defaultActionName = translate(pe);
                                }
                            }
                            break;
                        }
                        return defaultActionName;
                    };

                    bool firstEntry = true;
                    hasIfChain = true;
                    table.addStatement(getIndent()+name+".hit := false;\n");
                    table.addModifiedGlobalVariables(name+".hit");

                    for (auto entry : entriesList->entries) {
                        if (entry == nullptr) {
                            continue;
                        }

                        cstring actionName = nullptr;
                        const IR::MethodCallExpression* actionCall = nullptr;
                        if (auto actionExpr = entry->getAction()) {
                            if (auto mce = actionExpr->to<IR::MethodCallExpression>()) {
                                actionCall = mce;
                                actionName = translate(mce->method);
                            } else if (auto pe = actionExpr->to<IR::PathExpression>()) {
                                actionName = translate(pe);
                            }
                        }
                        if (actionName == nullptr || actions.find(actionName) == actions.end()) {
                            continue;
                        }

                        // Build a key-based match condition for this entry.
                        cstring condition = "";
                        if (auto keyset = entry->getKeys()) {
                            bool firstKey = true;
                            int idx = 0;
                            for (auto k : keyset->components) {
                                if (idx >= static_cast<int>(keyExprs.size())) {
                                    break;
                                }
                                cstring lhs = keyExprs[idx];
                                int w = 32;
                                if (idx < static_cast<int>(keyWidths.size())) {
                                    w = keyWidths[idx];
                                }
                                if (w <= 0) {
                                    w = 32;
                                }

                                cstring piece = "true";
                                if (lhs == nullptr || k == nullptr || k->is<IR::DefaultExpression>()) {
                                    piece = "true";
                                } else if (auto km = k->to<IR::Mask>()) {
                                    cstring val = translate(km->left);
                                    cstring mask = translate(km->right);
                                    cstring bv = "bv" + cstring::to_cstring(w);
                                    addFunction("band", "bvand", bv, bv);
                                    cstring band = "band." + bv;
                                    piece = band + "(" + lhs + ", " + mask + ") == " + band + "(" + val + ", " + mask + ")";
                                } else if (auto kr = k->to<IR::Range>()) {
                                    cstring lo = translate(kr->left);
                                    cstring hi = translate(kr->right);
                                    cstring bv = "bv" + cstring::to_cstring(w);
                                    addFunction("buge", "bvuge", bv, "bool");
                                    addFunction("bule", "bvule", bv, "bool");
                                    cstring buge = "buge." + bv;
                                    cstring bule = "bule." + bv;
                                    piece = "(" + buge + "(" + lhs + ", " + lo + ") && " + bule + "(" + lhs + ", " + hi + "))";
                                } else {
                                    cstring rhs = translate(k);
                                    piece = lhs + " == " + rhs;
                                }

                                if (!firstKey) {
                                    condition += " && ";
                                } else {
                                    firstKey = false;
                                }
                                condition += piece;
                                idx++;
                            }
                        }
                        if (condition == "") {
                            condition = "true";
                        }

                        if (firstEntry) {
                            table.addStatement(getIndent()+"if("+condition+"){\n");
                            firstEntry = false;
                        } else {
                            table.addStatement(getIndent()+"else if("+condition+"){\n");
                        }
                        incIndent();

                        table.addStatement(getIndent()+name+".hit := true;\n");
                        table.addModifiedGlobalVariables(name+".hit");
                        table.addStatement(getIndent()+name+".action_run := "+
                            name+".action."+actionName+";\n");
                        table.addModifiedGlobalVariables(name+".action_run");

                        // Assign action parameters (const entries require compile-time constant args).
                        const IR::P4Action* action = actions[actionName];
                        if (actionCall != nullptr && actionCall->arguments != nullptr) {
                            int argCount = actionCall->arguments->size();
                            int paramIndex = 0;
                            for (auto parameter : action->parameters->parameters) {
                                if (paramIndex >= argCount) {
                                    break;
                                }
                                const IR::Argument* arg = actionCall->arguments->at(paramIndex);
                                const IR::Expression* argExpr = (arg == nullptr) ? nullptr : arg->expression;
                                if (argExpr == nullptr) {
                                    paramIndex++;
                                    continue;
                                }

                                if (options.ultimateAutomizer && options.bitBlasting &&
                                    parameter->type->to<IR::Type_Bits>()) {
                                    auto typeBits = parameter->type->to<IR::Type_Bits>();
                                    if (auto c = argExpr->to<IR::Constant>()) {
                                        if (typeBits->size <= 64) {
                                            uint64_t value = static_cast<uint64_t>(c->value);
                                            for (int i = 0; i < typeBits->size; i++) {
                                                cstring bitVar = connect(actionName+"."+translate(parameter->name), i);
                                                cstring bitVal = ((value >> i) & 1ULL) ? "true" : "false";
                                                table.addStatement(getIndent()+bitVar+" := "+bitVal+";\n");
                                            }
                                        }
                                    }
                                } else {
                                    cstring parameterName = name+"."+actionName+"."+translate(parameter->name);
                                    cstring value = translate(argExpr);
                                    if (parameter->type->is<IR::Type_Boolean>()) {
                                        if (value == "0" || value == "0bv1") {
                                            value = "false";
                                        } else if (value == "1" || value == "1bv1") {
                                            value = "true";
                                        }
                                    }
                                    table.addStatement(getIndent()+parameterName+" := "+value+";\n");
                                    table.addModifiedGlobalVariables(parameterName);
                                }
                                paramIndex++;
                            }
                        }

                        std::vector<cstring> inArgs;
                        std::vector<cstring> outArgs;
                        for (auto parameter : action->parameters->parameters) {
                            std::vector<cstring> vars;
                            if (options.ultimateAutomizer && options.bitBlasting &&
                                parameter->type->to<IR::Type_Bits>()) {
                                auto typeBits = parameter->type->to<IR::Type_Bits>();
                                for (int i = 0; i < typeBits->size; i++) {
                                    vars.push_back(connect(actionName+"."+translate(parameter->name), i));
                                }
                            } else {
                                vars.push_back(name+"."+actionName+"."+translate(parameter->name));
                            }

                            if (parameter->direction == IR::Direction::Out) {
                                outArgs.insert(outArgs.end(), vars.begin(), vars.end());
                            } else if (parameter->direction == IR::Direction::InOut) {
                                inArgs.insert(inArgs.end(), vars.begin(), vars.end());
                                outArgs.insert(outArgs.end(), vars.begin(), vars.end());
                            } else {
                                inArgs.insert(inArgs.end(), vars.begin(), vars.end());
                            }
                        }

                        cstring callStmt = getIndent()+"call ";
                        if (!outArgs.empty()) {
                            for (size_t i = 0; i < outArgs.size(); ++i) {
                                if (i != 0) {
                                    callStmt += ", ";
                                }
                                callStmt += outArgs[i];
                                if (isGlobalVariable(outArgs[i])) {
                                    table.addModifiedGlobalVariables(outArgs[i]);
                                }
                            }
                            callStmt += " := ";
                        }
                        callStmt += actionName+"(";
                        for (size_t i = 0; i < inArgs.size(); ++i) {
                            if (i != 0) {
                                callStmt += ", ";
                            }
                            callStmt += inArgs[i];
                        }
                        callStmt += ");\n";
                        table.addStatement(callStmt);
                        table.addSucc(actionName);
                        addPred(actionName, tableName);
                        if (options.gotoOrIf) {
                            table.addStatement(getIndent()+"goto Exit;\n");
                        }
                        decIndent();
                        table.addStatement(getIndent()+"}\n");
                    }

                    // If no static entry matches, execute the P4-program default action (if any).
                    if (options.gotoOrIf) {
                        cstring defaultActionName = getDefaultActionNoArgs();
                        if (defaultActionName != nullptr &&
                            actions.find(defaultActionName) != actions.end()) {
                            table.addStatement(getIndent()+"if(!"+name+".hit){\n");
                            incIndent();
                            table.addStatement(getIndent()+name+".action_run := "+
                                name+".action."+defaultActionName+";\n");
                            table.addModifiedGlobalVariables(name+".action_run");
                            table.addStatement(getIndent()+"call "+defaultActionName+"();\n");
                            table.addSucc(defaultActionName);
                            addPred(defaultActionName, tableName);
                            table.addStatement(getIndent()+"goto Exit;\n");
                            decIndent();
                            table.addStatement(getIndent()+"}\n");
                        }
                    }

                    // add action declaration
                    translate(actionList, name+".action");
                }
                // no table rules
                else if(bMV2CmdsAnalyzer== nullptr || !bMV2CmdsAnalyzer->hasTableAddCmds(name)){
                    // P4 table semantics: a lookup miss always returns hit=false,
                    // even when the default action is executed.
                    //
                    // In this branch there are no concrete table_add rules from
                    // control-plane commands, so any execution is a miss path.
                    // Keep `.hit` deterministic to avoid spurious branches in
                    // callers that use `table.apply().hit`.
                    if(options.gotoOrIf){
                        table.addStatement(getIndent()+name+".hit := false;\n");
                        table.addModifiedGlobalVariables(name+".hit");
                    }

                    bool handledDefault = false;
                    TableSetDefault* defaultCmd = nullptr;
                    if(bMV2CmdsAnalyzer != nullptr){
                        defaultCmd = bMV2CmdsAnalyzer->getTableSetDefaultCmd(name);
                    }
                    if(defaultCmd != nullptr){
                        cstring actionName = defaultCmd->action;
                        cstring resolvedAction = nullptr;
                        for(auto actionElement:actionList->actionList){
                            if(auto actionCallExpr = actionElement->expression->to<IR::MethodCallExpression>()){
                                cstring candidate = translate(actionCallExpr->method);
                                if(isSame(candidate, actionName)){
                                    resolvedAction = candidate;
                                    break;
                                }
                            }
                        }
                        if(resolvedAction != nullptr && actions.find(resolvedAction) != actions.end()){
                            actionName = resolvedAction;
                            if(options.gotoOrIf){
                                table.addStatement(getIndent()+name+".action_run := "+
                                    name+".action."+actionName+";\n");
                                table.addModifiedGlobalVariables(name+".action_run");
                            }
                            const IR::P4Action* action = actions[actionName];
                            int ruleParamCount = defaultCmd->parameters.size();
                            int paramIndex = 0;
                            for(auto parameter:action->parameters->parameters){
                                if(paramIndex >= ruleParamCount){
                                    paramIndex++;
                                    continue;
                                }
                                cstring raw = defaultCmd->parameters[paramIndex];
                                if(options.ultimateAutomizer && options.bitBlasting &&
                                    parameter->type->to<IR::Type_Bits>()){
                                    auto typeBits = parameter->type->to<IR::Type_Bits>();
                                    cstring num = str2num(raw);
                                    uint64_t value = strtoull(num.c_str(), nullptr, 10);
                                    if(typeBits->size <= 64){
                                        for(int i = 0; i < typeBits->size; i++){
                                            cstring bitVar = connect(actionName+"."+translate(parameter->name), i);
                                            cstring bitVal = ((value >> i) & 1ULL) ? "true" : "false";
                                            table.addStatement(getIndent()+bitVar+" := "+bitVal+";\n");
                                        }
                                    }
                                }
                                else{
                                    cstring parameterName = name+"."+actionName+"."+translate(parameter->name);
                                    cstring value = str2num(raw);
                                    if(auto typeBits = parameter->type->to<IR::Type_Bits>()){
                                        value = value + "bv" + cstring::to_cstring(typeBits->size);
                                    }
                                    else if(auto typeName = parameter->type->to<IR::Type_Name>()){
                                        cstring typeAlias = translate(typeName->path);
                                        if(typeDefs.find(typeAlias) != typeDefs.end()){
                                            value = value + "bv" + cstring::to_cstring(typeDefs[typeAlias]);
                                        }
                                    }
                                    else if(parameter->type->is<IR::Type_Boolean>()){
                                        std::string s = value.c_str();
                                        if(s == "0") value = "false";
                                        else if(s == "1") value = "true";
                                    }
                                    table.addStatement(getIndent()+parameterName+" := "+value+";\n");
                                    table.addModifiedGlobalVariables(parameterName);
                                }
                                paramIndex++;
                            }

	                            std::vector<cstring> inArgs;
	                            std::vector<cstring> outArgs;
	                            for (auto parameter : action->parameters->parameters) {
	                                std::vector<cstring> vars;
	                                if (options.ultimateAutomizer && options.bitBlasting &&
	                                    parameter->type->to<IR::Type_Bits>()) {
	                                    auto typeBits = parameter->type->to<IR::Type_Bits>();
	                                    for (int i = 0; i < typeBits->size; i++) {
	                                        vars.push_back(connect(actionName+"."+translate(parameter->name), i));
	                                    }
	                                } else {
	                                    vars.push_back(name+"."+actionName+"."+translate(parameter->name));
	                                }

	                                if (parameter->direction == IR::Direction::Out) {
	                                    outArgs.insert(outArgs.end(), vars.begin(), vars.end());
	                                } else if (parameter->direction == IR::Direction::InOut) {
	                                    inArgs.insert(inArgs.end(), vars.begin(), vars.end());
	                                    outArgs.insert(outArgs.end(), vars.begin(), vars.end());
	                                } else {
	                                    inArgs.insert(inArgs.end(), vars.begin(), vars.end());
	                                }
	                            }

	                            cstring callStmt = getIndent()+"call ";
	                            if (!outArgs.empty()) {
	                                for (size_t i = 0; i < outArgs.size(); ++i) {
	                                    if (i != 0) {
	                                        callStmt += ", ";
	                                    }
	                                    callStmt += outArgs[i];
	                                    if (isGlobalVariable(outArgs[i])) {
	                                        table.addModifiedGlobalVariables(outArgs[i]);
	                                    }
	                                }
	                                callStmt += " := ";
	                            }
	                            callStmt += actionName+"(";
	                            for (size_t i = 0; i < inArgs.size(); ++i) {
	                                if (i != 0) {
	                                    callStmt += ", ";
	                                }
	                                callStmt += inArgs[i];
	                            }
	                            callStmt += ");\n";
	                            table.addStatement(callStmt);
	                            table.addSucc(actionName);
	                            addPred(actionName, tableName);
                            if(options.gotoOrIf){
                                table.addStatement(getIndent()+"goto Exit;\n");
                            }
                            handledDefault = true;
                        }
	                    }

	                    if(!handledDefault){
	                        // In BMv2, if no table rules are configured (and control-plane does not override the
	                        // default), the table deterministically executes the P4-program default action.
	                        if (options.gotoOrIf && bMV2CmdsAnalyzer != nullptr) {
	                            cstring defaultActionName = nullptr;
	                            for (auto prop : p4Table->properties->properties) {
	                                if (prop->getName() != "default_action") {
	                                    continue;
	                                }
	                                if (auto ev = prop->value->to<IR::ExpressionValue>()) {
	                                    const IR::Expression* expr = ev->expression;
	                                    if (auto mce = expr->to<IR::MethodCallExpression>()) {
	                                        if (mce->arguments == nullptr || mce->arguments->size() == 0) {
	                                            defaultActionName = translate(mce->method);
	                                        }
	                                    } else if (auto pe = expr->to<IR::PathExpression>()) {
	                                        defaultActionName = translate(pe);
	                                    }
	                                }
	                                break;
	                            }

	                            if (defaultActionName != nullptr && actions.find(defaultActionName) != actions.end()) {
	                                table.addStatement(getIndent()+name+".action_run := "+
	                                    name+".action."+defaultActionName+";\n");
	                                table.addModifiedGlobalVariables(name+".action_run");
	                                table.addStatement(getIndent()+"call "+defaultActionName+"();\n");
	                                table.addSucc(defaultActionName);
	                                addPred(defaultActionName, tableName);
	                                table.addStatement(getIndent()+"goto Exit;\n");
	                                handledDefault = true;
	                            }
	                        }

	                        // Fallback: nondeterministically choose one of the table's actions (excluding NoAction).
	                        // This is used when no control-plane config is available.
	                        if (!handledDefault && options.gotoOrIf){
	                            bool firstAction = true;
	                            for(auto actionElement:actionList->actionList){
	                                cstring actionName = nullptr;
	                                if(auto actionCallExpr = actionElement->expression->to<IR::MethodCallExpression>()){
	                                    actionName = translate(actionCallExpr->method);
	                                } else if (auto pe = actionElement->expression->to<IR::PathExpression>()) {
	                                    actionName = translate(pe);
	                                }
	                                if (actionName == nullptr || isNoActionName(actionName)) {
	                                    continue;
	                                }
	                                if(!firstAction) gotoStmt += ", ";
	                                else firstAction = false;
	                                gotoStmt += "action_"; gotoStmt += actionName;
	                            }
	                            if(!firstAction){
	                                gotoStmt += ";\n";
	                                table.addStatement(gotoStmt);
	                            } else {
	                                table.addStatement(getIndent()+"goto Exit;\n");
	                            }
	                        }

	                        bool firstAction = true;
	                        for(auto actionElement:actionList->actionList){
	                            cstring actionName = nullptr;
	                            if(auto actionCallExpr = actionElement->expression->to<IR::MethodCallExpression>()){
	                                actionName = translate(actionCallExpr->method);
	                            } else if (auto pe = actionElement->expression->to<IR::PathExpression>()) {
	                                actionName = translate(pe);
	                            }
	                            if (actionName == nullptr || isNoActionName(actionName)) {
	                                continue;
	                            }
	                            std::string label("\n"+getIndent());
	                            label += "action_"; label += actionName; label += ":\n";
	                            if(options.gotoOrIf){
	                                table.addStatement(label);
	                            }

	                            if(options.gotoOrIf){
	                                table.addStatement(getIndent()+"assume "+name+".action_run == "+
	                                    name+".action."+actionName+";\n");
	                                table.addModifiedGlobalVariables(name+".action_run");
	                            }
	                            else{
	                                if(firstAction){
	                                    hasIfChain = true;
	                                    table.addStatement(getIndent()+"if("+name+".action_run == "+
	                                        name+".action."+actionName+"){\n");
	                                    firstAction = false;
	                                }
	                                else{
	                                    table.addStatement(getIndent()+"else if("+name+".action_run == "+
	                                        name+".action."+actionName+"){\n");
	                                }
	                                incIndent();
	                            }

	                            const IR::P4Action* action = actions[actionName];
	                            std::vector<cstring> inArgs;
	                            std::vector<cstring> outArgs;
	                            for (auto parameter : action->parameters->parameters) {
	                                std::vector<cstring> vars;
	                                if (options.ultimateAutomizer && options.bitBlasting &&
	                                    parameter->type->to<IR::Type_Bits>()) {
	                                    auto typeBits = parameter->type->to<IR::Type_Bits>();
	                                    for (int i = 0; i < typeBits->size; i++) {
	                                        vars.push_back(connect(actionName+"."+translate(parameter->name), i));
	                                    }
	                                } else {
	                                    vars.push_back(name+"."+actionName+"."+translate(parameter->name));
	                                }

	                                if (parameter->direction == IR::Direction::Out) {
	                                    outArgs.insert(outArgs.end(), vars.begin(), vars.end());
	                                } else if (parameter->direction == IR::Direction::InOut) {
	                                    inArgs.insert(inArgs.end(), vars.begin(), vars.end());
	                                    outArgs.insert(outArgs.end(), vars.begin(), vars.end());
	                                } else {
	                                    inArgs.insert(inArgs.end(), vars.begin(), vars.end());
	                                }
	                            }

	                            cstring callStmt = getIndent()+"call ";
	                            if (!outArgs.empty()) {
	                                for (size_t i = 0; i < outArgs.size(); ++i) {
	                                    if (i != 0) {
	                                        callStmt += ", ";
	                                    }
	                                    callStmt += outArgs[i];
	                                    if (isGlobalVariable(outArgs[i])) {
	                                        table.addModifiedGlobalVariables(outArgs[i]);
	                                    }
	                                }
	                                callStmt += " := ";
	                            }
	                            callStmt += actionName+"(";
	                            for (size_t i = 0; i < inArgs.size(); ++i) {
	                                if (i != 0) {
	                                    callStmt += ", ";
	                                }
	                                callStmt += inArgs[i];
	                            }
	                            callStmt += ");\n";
	                            table.addStatement(callStmt);
	                            table.addSucc(actionName);
	                            addPred(actionName, tableName);
	                            if(options.gotoOrIf){
	                                table.addStatement(getIndent()+"goto Exit;\n");
	                            }
	                            else{
	                                decIndent();
	                                table.addStatement(getIndent()+"}\n");
	                            }
	                        }
	                    }
	                    // add action declaration
                    translate(actionList, name+".action");
                }
                /* handle table add commands, i.e., table rules
                    1. find the rules of the current table (from BMV2CmdsAnalyzer)
                    2. add condition statements (according to keys and priority)
                    3. assign parameters
                    4. call the corresponding actions
                    5. if no matching rules, consider the default action
                */
                else{
                    std::vector<TableAdd*> rules = bMV2CmdsAnalyzer->getTableAddCmds(name);
                    std::vector<cstring> keyExprs;
                    std::vector<int> keyWidths;
                    for(auto property:p4Table->properties->properties){
                        if (auto key = property->value->to<IR::Key>()) {
                            for(auto keyElement:key->keyElements){
                                cstring expr = translate(keyElement->expression);
                                if(expr == nullptr){
                                    continue;
                                }
                                keyExprs.push_back(expr);
                                int width = -1;
                                if(auto typeBits = keyElement->expression->type->to<IR::Type_Bits>()){
                                    width = typeBits->size;
                                } else if (keyElement->expression->type->is<IR::Type_Boolean>()){
                                    width = 1;
                                } else if (auto typeName = keyElement->expression->type->to<IR::Type_Name>()){
                                    cstring typeAlias = translate(typeName->path);
                                    if(typeDefs.find(typeAlias) != typeDefs.end()){
                                        width = typeDefs[typeAlias];
                                    }
                                }
                                keyWidths.push_back(width);
                            }
                        }
                    }

                    bool firstRule = true;
                    if(!rules.empty()){
                        hasIfChain = true;
                        table.addStatement(getIndent()+name+".hit := false;\n");
                        table.addModifiedGlobalVariables(name+".hit");
                    }

	                    for(auto rule:rules){
	                        cstring actionName = rule->action;
	                        cstring resolvedAction = nullptr;
                        for(auto actionElement:actionList->actionList){
                            if(auto actionCallExpr = actionElement->expression->to<IR::MethodCallExpression>()){
                                cstring candidate = translate(actionCallExpr->method);
                                if(isSame(candidate, actionName)){
                                    resolvedAction = candidate;
                                    break;
                                }
                            }
                        }
                        if(resolvedAction == nullptr){
                            continue;
                        }
                        actionName = resolvedAction;
	                        if(actions.find(actionName) == actions.end()){
	                            continue;
	                        }
	                        // bmv2 match expressions may require bitvector helpers (Ultimate Boogie parser
	                        // does not accept the infix `&` operator, and comparison operators like <=/>=
	                        // are not defined for bitvectors).
	                        for (size_t fi = 0; fi < rule->fields.size(); ++fi) {
	                            std::string field_str = rule->fields[fi].c_str();
	                            const bool usesAnd =
	                                field_str.find("/") != std::string::npos ||
	                                field_str.find("&&&") != std::string::npos;
	                            const bool usesRange =
	                                field_str.find("->") != std::string::npos;
	                            if (!usesAnd && !usesRange) {
	                                continue;
	                            }
	                            int w = 32;
	                            if (fi < keyWidths.size()) {
	                                w = keyWidths[fi];
	                            }
	                            if (w <= 0) {
	                                w = 32;
	                            }
	                            cstring bv = "bv" + cstring::to_cstring(w);
	                            if (usesAnd) {
	                                addFunction("band", "bvand", bv, bv);
	                            }
	                            if (usesRange) {
	                                addFunction("buge", "bvuge", bv, "bool");
	                                addFunction("bule", "bvule", bv, "bool");
	                            }
	                        }
	                        cstring condition = rule->getCondition(keyExprs, keyWidths);
	                        if(condition == ""){
	                            continue;
	                        }
                        if(firstRule){
                            table.addStatement(getIndent()+"if("+condition+"){\n");
                            firstRule = false;
                        }
                        else{
                            table.addStatement(getIndent()+"else if("+condition+"){\n");
                        }
                        incIndent();

                        table.addStatement(getIndent()+name+".hit := true;\n");
                        table.addModifiedGlobalVariables(name+".hit");
                        table.addStatement(getIndent()+name+".action_run := "+
                            name+".action."+actionName+";\n");
                        table.addModifiedGlobalVariables(name+".action_run");

                        const IR::P4Action* action = actions[actionName];
                        int ruleParamCount = rule->parameters.size();
                        int paramIndex = 0;
                        for(auto parameter:action->parameters->parameters){
                            if(paramIndex >= ruleParamCount){
                                paramIndex++;
                                continue;
                            }
                            cstring raw = rule->parameters[paramIndex];
                            if(options.ultimateAutomizer && options.bitBlasting &&
                                parameter->type->to<IR::Type_Bits>()){
                                auto typeBits = parameter->type->to<IR::Type_Bits>();
                                cstring num = str2num(raw);
                                uint64_t value = strtoull(num.c_str(), nullptr, 10);
                                if(typeBits->size <= 64){
                                    for(int i = 0; i < typeBits->size; i++){
                                        cstring bitVar = connect(actionName+"."+translate(parameter->name), i);
                                        cstring bitVal = ((value >> i) & 1ULL) ? "true" : "false";
                                        table.addStatement(getIndent()+bitVar+" := "+bitVal+";\n");
                                    }
                                }
                            }
                            else{
                                cstring parameterName = name+"."+actionName+"."+translate(parameter->name);
                                cstring value = str2num(raw);
                                if(auto typeBits = parameter->type->to<IR::Type_Bits>()){
                                    value = value + "bv" + cstring::to_cstring(typeBits->size);
                                }
                                else if(auto typeName = parameter->type->to<IR::Type_Name>()){
                                    cstring typeAlias = translate(typeName->path);
                                    if(typeDefs.find(typeAlias) != typeDefs.end()){
                                        value = value + "bv" + cstring::to_cstring(typeDefs[typeAlias]);
                                    }
                                }
                                else if(parameter->type->is<IR::Type_Boolean>()){
                                    std::string s = value.c_str();
                                    if(s == "0") value = "false";
                                    else if(s == "1") value = "true";
                                }
                                table.addStatement(getIndent()+parameterName+" := "+value+";\n");
                                table.addModifiedGlobalVariables(parameterName);
                            }
                            paramIndex++;
                        }

                        std::vector<cstring> inArgs;
                        std::vector<cstring> outArgs;
                        for (auto parameter : action->parameters->parameters) {
                            std::vector<cstring> vars;
                            if (options.ultimateAutomizer && options.bitBlasting &&
                                parameter->type->to<IR::Type_Bits>()) {
                                auto typeBits = parameter->type->to<IR::Type_Bits>();
                                for (int i = 0; i < typeBits->size; i++) {
                                    vars.push_back(connect(actionName+"."+translate(parameter->name), i));
                                }
                            } else {
                                vars.push_back(name+"."+actionName+"."+translate(parameter->name));
                            }

                            if (parameter->direction == IR::Direction::Out) {
                                outArgs.insert(outArgs.end(), vars.begin(), vars.end());
                            } else if (parameter->direction == IR::Direction::InOut) {
                                inArgs.insert(inArgs.end(), vars.begin(), vars.end());
                                outArgs.insert(outArgs.end(), vars.begin(), vars.end());
                            } else {
                                inArgs.insert(inArgs.end(), vars.begin(), vars.end());
                            }
                        }

                        cstring callStmt = getIndent()+"call ";
                        if (!outArgs.empty()) {
                            for (size_t i = 0; i < outArgs.size(); ++i) {
                                if (i != 0) {
                                    callStmt += ", ";
                                }
                                callStmt += outArgs[i];
                                if (isGlobalVariable(outArgs[i])) {
                                    table.addModifiedGlobalVariables(outArgs[i]);
                                }
                            }
                            callStmt += " := ";
                        }
                        callStmt += actionName+"(";
                        for (size_t i = 0; i < inArgs.size(); ++i) {
                            if (i != 0) {
                                callStmt += ", ";
                            }
                            callStmt += inArgs[i];
                        }
                        callStmt += ");\n";
                        table.addStatement(callStmt);
                        table.addSucc(actionName);
                        addPred(actionName, tableName);
                        if(options.gotoOrIf){
                            table.addStatement(getIndent()+"goto Exit;\n");
                        }
                        decIndent();
                        table.addStatement(getIndent()+"}\n");
                    }

                    // If no rule matches, execute the P4-program default action (if any).
                    if (options.gotoOrIf) {
                        cstring defaultActionName = nullptr;
                        for (auto prop : p4Table->properties->properties) {
                            if (prop->getName() != "default_action") {
                                continue;
                            }
                            if (auto ev = prop->value->to<IR::ExpressionValue>()) {
                                const IR::Expression* expr = ev->expression;
                                if (auto mce = expr->to<IR::MethodCallExpression>()) {
                                    if (mce->arguments == nullptr || mce->arguments->size() == 0) {
                                        defaultActionName = translate(mce->method);
                                    }
                                } else if (auto pe = expr->to<IR::PathExpression>()) {
                                    defaultActionName = translate(pe);
                                }
                            }
                            break;
                        }
                        if (defaultActionName != nullptr &&
                            actions.find(defaultActionName) != actions.end()) {
                            table.addStatement(getIndent()+"if(!"+name+".hit){\n");
                            incIndent();
                            table.addStatement(getIndent()+name+".action_run := "+
                                name+".action."+defaultActionName+";\n");
                            table.addModifiedGlobalVariables(name+".action_run");
                            table.addStatement(getIndent()+"call "+defaultActionName+"();\n");
                            table.addSucc(defaultActionName);
                            addPred(defaultActionName, tableName);
                            table.addStatement(getIndent()+"goto Exit;\n");
                            decIndent();
                            table.addStatement(getIndent()+"}\n");
                        }
                    }

                    // add action declaration
                    translate(actionList, name+".action");
                }
            }
        }

        if(options.gotoOrIf){
            table.addStatement("\n    Exit:\n");
            // table.addStatement("        call "+tableName+"_table_exit();\n");
        }
        addDeclaration("var "+name+".action_run : "+name+".action;\n");
        addGlobalVariables(name+".action_run");
        havocProcedure.addStatement("    havoc "+name+".action_run;\n");
        havocProcedure.addModifiedGlobalVariables(name+".action_run");
        addDeclaration("var "+name+".hit : bool;\n");
        addGlobalVariables(name+".hit");
    }

    // default action
    for(auto property:p4Table->properties->properties){
        if (auto value = property->value->to<IR::ExpressionValue>()){
            if(property->getName() == "default_action"){
                if(!options.gotoOrIf){
                    cstring default_action = translate(value->expression);
                    if (hasIfChain) {
                        table.addStatement(getIndent()+"else {\n");
                        incIndent();
                        table.addStatement(getIndent()+"call "+default_action+";\n");
                        decIndent();
                        table.addStatement(getIndent()+"}\n");
                    } else {
                        // Avoid dangling else: if no action branches were emitted, execute default directly.
                        table.addStatement(getIndent()+"call "+default_action+";\n");
                    }
                    table.addSucc(default_action);
                    addPred(default_action, tableName);
                }
            }
        }
    }

    if(bMV2CmdsAnalyzer != nullptr && bMV2CmdsAnalyzer->hasTableAddCmds(name)){
        table.addModifiedGlobalVariables(name+".hit");
    }

    decIndent();
    addProcedure(table);
    if(bMV2CmdsAnalyzer != nullptr && bMV2CmdsAnalyzer->hasTableAddCmds(name)){
        procedures[tableName].addModifiedGlobalVariables(name+".hit");
    }
}

/*
    translate action_run (discarded)
*/
cstring Translator::translate(const IR::P4Table *p4Table, std::map<cstring, cstring> switchCases){
    cstring res = "";
    cstring name = translate(p4Table->name);
    for(auto property:p4Table->properties->properties){
        if (auto key = property->value->to<IR::Key>()) {
            for(auto keyElement:key->keyElements){
                cstring expr = translate(keyElement->expression);
                if(expr.find("[")==nullptr&&expr.find("(")==nullptr) {
                    res += getIndent()+expr+" := "+expr+";\n";
                    updateModifiedVariables(expr);
                }
            }
        }
    }
    for(auto property:p4Table->properties->properties){
        if (auto actionList = property->value->to<IR::ActionList>()) {
            // add local variables
            for(auto actionElement:actionList->actionList){
                if(auto actionCallExpr = actionElement->expression->to<IR::MethodCallExpression>()){
                    cstring actionName = translate(actionCallExpr->method);
                    const IR::P4Action* action = actions[actionName];
                    for(auto parameter:action->parameters->parameters){
                        currentProcedure->addFrontStatement("    var "+actionName+"."+translate(parameter)+";\n");
                    }
                }
            }
            // add action call statements
            int cnt = actionList->actionList.size();
            for(auto actionElement:actionList->actionList){
                if(actionList->actionList.size()!=2){
                    if(cnt == actionList->actionList.size())
                        res += getIndent()+"if(";
                    else if(cnt != 1)
                        res += getIndent()+"else if(";
                }
                cnt--;
                if(cnt == 0)
                    break;
                if(auto actionCallExpr = actionElement->expression->to<IR::MethodCallExpression>()){
                    cstring actionName = translate(actionCallExpr->method);
                    if(actionList->actionList.size()!=2)
                        res += name+".action_run == "+name+".action."+actionName+"){\n";
                    incIndent();
                    const IR::P4Action* action = actions[actionName];
                    if(switchCases[name+".action."+actionName] != nullptr)
                        res += switchCases[name+".action."+actionName];
                    std::vector<cstring> inVars;
                    std::vector<cstring> outVars;
                    for (auto parameter : action->parameters->parameters) {
                        cstring var = actionName+"."+translate(parameter->name);
                        if (parameter->direction == IR::Direction::Out) {
                            outVars.push_back(var);
                        } else if (parameter->direction == IR::Direction::InOut) {
                            inVars.push_back(var);
                            outVars.push_back(var);
                        } else {
                            inVars.push_back(var);
                        }
                    }

                    res += getIndent()+"call ";
                    currentProcedure->addSucc(actionName);
                    addPred(actionName, currentProcedure->getName());
                    if (!outVars.empty()) {
                        for (size_t i = 0; i < outVars.size(); ++i) {
                            if (i != 0) {
                                res += ", ";
                            }
                            res += outVars[i];
                        }
                        res += " := ";
                    }
                    res += actionName+"(";
                    for (size_t i = 0; i < inVars.size(); ++i) {
                        if (i != 0) {
                            res += ", ";
                        }
                        res += inVars[i];
                    }
                    res += ");\n";
                    decIndent();
                }
                if(actionList->actionList.size()!=2)
                    res += getIndent()+"}\n";
            }
        }
    }
    // decIndent();
    return res;
}

void Translator::translate(const IR::ActionList *actionList, cstring arg){
    cstring limitName = arg+"_run.limit";
    BoogieProcedure limit = BoogieProcedure(limitName);
    limit.addModifiedGlobalVariables(arg+"_run");
    limit.addDeclaration("\nprocedure "+limitName+"();\n");
    limit.addDeclaration("    ensures(");
    int cnt = actionList->actionList.size();
    if(cnt == 0 || cnt == 1) limit.addDeclaration("true");
    for(auto actionElement:actionList->actionList){
        cnt--;
        if(auto actionCallExpr = actionElement->expression->to<IR::MethodCallExpression>()){
            cstring actionName = translate(actionCallExpr->method);
            addDeclaration("const unique "+arg+"."+actionName+" : "+arg+";\n");
            limit.addDeclaration(arg+"_run=="+arg+"."+actionName);
        }
        // NoAction should not be considered
        if(cnt > 1){
            limit.addDeclaration(" || ");
        }
    }
    limit.addDeclaration(");\n");
}
