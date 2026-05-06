#include "translate.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <functional>
#include <iostream>
#include <limits>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

// Expression
cstring Translator::translate(const IR::Expression *expression){
    if (auto methodCall = expression->to<IR::MethodCallStatement>()){
        return translate(methodCall);
    }
    else if (auto member = expression->to<IR::Member>()){
        return translate(member);
    }
    else if (auto pathExpression = expression->to<IR::PathExpression>()){
        return translate(pathExpression);
    }
    else if (auto methodCallExpression = expression->to<IR::MethodCallExpression>()){
        return translate(methodCallExpression);
    }
    else if (auto opBinary = expression->to<IR::Operation_Binary>()){
        return translate(opBinary);
    }
    else if (auto constant = expression->to<IR::Constant>()){
        return translate(constant);
    }
    else if (auto boolLiteral = expression->to<IR::BoolLiteral>()){
        return translate(boolLiteral);
    }
    else if (auto constructorCallExpression = expression->to<IR::ConstructorCallExpression>()){
        return translate(constructorCallExpression);
    }
    else if (auto slice = expression->to<IR::Slice>()){
        return translate(slice);
    }
    else if (auto opUnary = expression->to<IR::Operation_Unary>()){
        return translate(opUnary);
    }
    else if (auto typeNameExpression = expression->to<IR::TypeNameExpression>()){
        return translate(typeNameExpression->typeName);
    }
    else if (expression->is<IR::DefaultExpression>()){
        return "default";
    }
    return "";
}

// Method/extern lowering lives in translate_method.cpp.


cstring Translator::translate(const IR::Member *member){
    if(member->member.toString()=="extract")
        return "packet_in.extract";
    if(member->member.toString()=="lookahead")
        return "lookahead";
    if(member->member.toString()=="setValid")
        return "setValid("+translate(member->expr)+")";
    if(member->member.toString()=="setInvalid")
        return "setInvalid("+translate(member->expr)+")";
    if(member->member.toString()=="hit"){
        cstring expr = translate(member->expr);
        std::string s = expr.c_str();
        std::string::size_type idx = s.find(".apply()");
        if(idx != std::string::npos){
            cstring tableName = s.substr(0, idx);
            currentProcedure->addStatement(getIndent()+"call "+tableName+".apply();\n");
            currentProcedure->addSucc(tableName+".apply");
            return tableName+".hit";
        }
    }

    if (member->expr != nullptr && member->expr->is<IR::TypeNameExpression>()) {
        cstring enumName = translate(member->expr);
        auto typeIt = enumLiteralValues.find(enumName);
        if (typeIt != enumLiteralValues.end()) {
            auto memberIt = typeIt->second.find(member->member.name);
            if (memberIt != typeIt->second.end()) {
                return memberIt->second;
            }
        }
    }

    // For header stack
    if(auto arrayIndex = member->expr->to<IR::ArrayIndex>()){
        if(options.addBoundAssertion){
            if(auto typeStack = P4VerifyCompat::asHeaderStackType(arrayIndex->left->type)){
                currentProcedure->addStatement(getIndent()+"assert ("
                                                +translate(arrayIndex->right)+ "<" +
                                                translate(typeStack->size)+");\n");
                }
        }
        return translate(arrayIndex->left)+"."+translate(arrayIndex->right)+"."+member->member.toString();
    }

    int totalBits = 0;
    int hi = 0;
    int lo = 0;
    cstring baseName = nullptr;
    if (getStructFieldRange(member->expr, member->member.toString(), totalBits, hi, lo, baseName)) {
        std::stringstream ss;
        ss << baseName << "[" << (hi + 1) << ":" << lo << "]";
        return ss.str();
    }
    if (auto pathExpr = member->expr->to<IR::PathExpression>()) {
        cstring structName = nullptr;
        cstring paramName = translate(pathExpr->path);
        if (getParamStructName(paramName, structName)) {
            if (getStructFieldRangeByName(paramName, structName, member->member.toString(),
                                          totalBits, hi, lo)) {
                std::stringstream ss;
                ss << paramName << "[" << (hi + 1) << ":" << lo << "]";
                return ss.str();
            }
        }
    }

    if(member->type->is<IR::Type_Header>()){
        cstring hdr = translate(member->expr)+"."+member->member.toString();
        cstring stmt = getIndent()+"assert("+hdr+".valid);\n";
        if(options.addValidityAssertion){
            if(hdr.find(".next") == nullptr && hdr.find(".last") == nullptr){
                if(currentProcedure->lastStatement() == "" || 
                    (currentProcedure->lastStatement() != stmt 
                        && stmt.find(currentProcedure->lastStatement().c_str()) == nullptr)){
                    if(isIfStatement) storeAssertionStatement(stmt);
                    else currentProcedure->addStatement(stmt);
                }
            }
        }
        return hdr;
    }
    {
        cstring baseName = translate(member->expr);
        if (baseName.find("ig_intr_") != nullptr) {
            cstring fieldName = baseName+"."+member->member.toString();
            if (!isGlobalVariable(fieldName)) {
                forcedKeepVars.insert(fieldName);
                cstring fieldType = member->type ? translate(member->type) : "bv48";
                addDeclaration("var "+fieldName+":"+fieldType+";\n");
                addGlobalVariables(fieldName);
            }
        }
    }
    return translate(member->expr)+"."+member->member.toString();
}

cstring Translator::translate(const IR::PathExpression *pathExpression){
    cstring name = nullptr;
    if (refMap && pathExpression && pathExpression->path) {
        if (auto decl = refMap->getDeclaration(pathExpression->path, false)) {
            name = translate(decl->getName());
        }
    }
    if (name.isNullOrEmpty()) {
        name = translate(pathExpression->path);
    }
    if (name.find("ig_intr_") != nullptr && name.find(".") != nullptr) {
        if (!isGlobalVariable(name)) {
            forcedKeepVars.insert(name);
            cstring fieldType = pathExpression->type ? translate(pathExpression->type) : "bv48";
            addDeclaration("var "+name+":"+fieldType+";\n");
            addGlobalVariables(name);
        }
    }
    if (inParser && name.find(".") == nullptr && pathExpression->type != nullptr &&
        !pathExpression->type->is<IR::Type_Method>() &&
        emittedVarDecls.find(name) == emittedVarDecls.end()) {
        const IR::Type *type = pathExpression->type;
        if (type == nullptr || type->is<IR::Type_Unknown>() || type->is<IR::Type_InfInt>()) {
            auto it = declVarTypes.find(name);
            if (it != declVarTypes.end()) {
                type = it->second;
            }
        }
        if (type != nullptr) {
            if (auto typeBits = type->to<IR::Type_Bits>()) {
                if (options.ultimateAutomizer) {
                    addDeclaration("var "+name+":int;\n");
                } else {
                    addDeclaration("var "+name+":"+translate(type)+";\n");
                }
                updateVariableSize(name, typeBits->size);
                updateMaxBitvectorSize(typeBits);
            } else if (auto typeBoolean = type->to<IR::Type_Boolean>()) {
                (void)typeBoolean;
                addDeclaration("var "+name+":bool;\n");
            } else if (type->is<IR::Type_Extern>() || type->is<IR::Type_Parser>()
                       || type->is<IR::Type_Control>() || type->is<IR::Type_Package>()) {
                addDeclaration("var "+name+":Ref;\n");
            } else if (auto typeName = type->to<IR::Type_Name>()) {
                cstring typeId = translate(typeName->path);
                if (headers.find(typeId) != headers.end()) {
                    translate(headers[typeId], name);
                } else if (structs.find(typeId) != structs.end()) {
                    translate(structs[typeId], name);
                } else {
                    addDeclaration("var "+name+":"+translate(type)+";\n");
                    if (typeDefs.find(typeId) != typeDefs.end()) {
                        updateVariableSize(name, typeDefs[typeId]);
                    }
                }
            } else {
                cstring typeStr = translate(type);
                if (typeStr == "") {
                    addDeclaration("var "+name+":Ref;\n");
                } else {
                    addDeclaration("var "+name+":"+typeStr+";\n");
                }
            }
        } else {
            addDeclaration("var "+name+":Ref;\n");
        }
        addGlobalVariables(name);
    }
    return name;
}

cstring Translator::translate(const IR::Path *path){
    return translate(path->name);
}

cstring Translator::translate(const IR::Declaration *decl){
    if (auto p4Action = decl->to<IR::P4Action>()){
        translate(p4Action);
    }
    else if (auto p4Table = decl->to<IR::P4Table>()){
        translate(p4Table);
    }
    else if (auto declVar = decl->to<IR::Declaration_Variable>()){
        return translate(declVar);
    }
    else if (auto instance = decl->to<IR::Declaration_Instance>()){
        translate(instance);
    }
    return "";
}

cstring Translator::translate(const IR::Declaration_Variable *declVar){ 
    // Should be declared as global variables
    // Variables have been renamed by p4c

    cstring res = "";
    cstring varName = translate(declVar->name);
    declVarTypes[varName] = declVar->type;
    bool isNamedHeaderOrStruct = false;
    if (auto typeName = declVar->type->to<IR::Type_Name>()) {
        cstring typeId = translate(typeName->path);
        isNamedHeaderOrStruct =
            headers.find(typeId) != headers.end() || structs.find(typeId) != structs.end();
    }
    auto boogieType = [&](const IR::Type* type) -> cstring {
        if (type == nullptr) {
            return "";
        }
        if (auto typeBits = type->to<IR::Type_Bits>()) {
            updateMaxBitvectorSize(typeBits);
            return options.ultimateAutomizer ? "int" : translate(type);
        }
        if (type->is<IR::Type_Boolean>()) {
            return "bool";
        }
        if (auto typeName = type->to<IR::Type_Name>()) {
            cstring name = translate(typeName->path);
            if (typeDefs.find(name) != typeDefs.end() || structs.find(name) != structs.end()) {
                return translate(type);
            }
        }
        return translate(type);
    };
    auto recordLocalWidth = [&](const IR::Type* type) {
        if (currentProcedure == nullptr || type == nullptr) {
            return;
        }
        if (auto typeBits = type->to<IR::Type_Bits>()) {
            updateMaxBitvectorSize(typeBits);
            currentProcedure->declarationVariables[varName] = typeBits->size;
        } else if (type->is<IR::Type_Boolean>()) {
            currentProcedure->declarationVariables[varName] = 0;
        } else if (auto typeName = type->to<IR::Type_Name>()) {
            cstring name = translate(typeName);
            if (typeDefs.find(name) != typeDefs.end()) {
                currentProcedure->declarationVariables[varName] = typeDefs[name];
            }
        }
    };
    if (currentProcedure != nullptr && !inParser &&
        !declVar->type->is<IR::Type_Extern>() && !declVar->type->is<IR::Type_Parser>() &&
        !declVar->type->is<IR::Type_Control>() && !declVar->type->is<IR::Type_Package>() &&
        declVar->type->to<IR::Type_Header>() == nullptr &&
        declVar->type->to<IR::Type_Struct>() == nullptr &&
        !isNamedHeaderOrStruct) {
        cstring localType = boogieType(declVar->type);
        if (localType != "") {
            if (isGlobalVariable(varName)) {
                if (options.slicingEnabled && !options.slicingKeepVars.empty() &&
                    !shouldKeepVar(varName.c_str())) {
                    recordLocalWidth(declVar->type);
                    return res;
                }
                currentProcedure->addModifiedGlobalVariables(varName);
                currentProcedure->addStatement(BoogieStatement(getIndent()+"havoc "+varName+";\n"));
                recordLocalWidth(declVar->type);
                if (declVar->initializer != nullptr) {
                    currentProcedure->addStatement(
                        BoogieStatement(getIndent()+varName+" := "+translate(declVar->initializer)+";\n"));
                }
                return res;
            }
            currentProcedure->addVariableDeclaration(getIndent()+"var "+varName+":"+localType+";\n");
            currentProcedure->addLocalVariables(varName);
            recordLocalWidth(declVar->type);
            if (declVar->initializer != nullptr) {
                currentProcedure->addStatement(
                    BoogieStatement(getIndent()+varName+" := "+translate(declVar->initializer)+";\n"));
            }
            return res;
        }
    }
    if (currentProcedure != nullptr && currentProcedure->hasLocalVariables(varName)) {
        recordLocalWidth(declVar->type);
        if (declVar->initializer != nullptr) {
            currentProcedure->addStatement(
                BoogieStatement(getIndent()+varName+" := "+translate(declVar->initializer)+";\n"));
        }
        return res;
    }
    if (declVar->type->is<IR::Type_Extern>() || declVar->type->is<IR::Type_Parser>()
        || declVar->type->is<IR::Type_Control>() || declVar->type->is<IR::Type_Package>()) {
        return res;
    }
    if (auto typeHeader = declVar->type->to<IR::Type_Header>()) {
        addGlobalVariables(varName);
        translate(typeHeader, varName);
        return res;
    }
    if (auto typeStruct = declVar->type->to<IR::Type_Struct>()) {
        addGlobalVariables(varName);
        translate(typeStruct, varName);
        return res;
    }
    cstring declType = translate(declVar->type);
    if (declType == "") {
        return res;
    }
    addGlobalVariables(varName);
    
    if(auto typeBits = declVar->type->to<IR::Type_Bits>()){
        if(options.ultimateAutomizer){
            addDeclaration("var "+varName+":int;\n");
            updateVariableSize(varName, typeBits->size);
        }
        else {
            addDeclaration("var "+varName+":"+declType+";\n");
            updateVariableSize(varName, typeBits->size);
        }
    }
    else if(auto typeName = declVar->type->to<IR::Type_Name>()){
        if(headers.find(translate(typeName)) != headers.end()){
            translate(headers[translate(typeName)], varName);
        }
        else if(structs.find(translate(typeName)) != structs.end()){
            translate(structs[translate(typeName)], varName);
        }
        else {
            cstring name = translate(typeName);
            addDeclaration("var "+varName+":"+declType+";\n");
            if(typeDefs.find(name) != typeDefs.end()){
                updateVariableSize(varName, typeDefs[name]);
            }
        }
    }
    else
        addDeclaration("var "+varName+":"+declType+";\n");
    
    if(declVar->initializer == nullptr){
        if(currentProcedure != nullptr){
            // For Type_Unknown
            // Record the types of local variables
            if(auto typeBits = declVar->type->to<IR::Type_Bits>()){
                updateMaxBitvectorSize(typeBits);
                currentProcedure->declarationVariables[translate(declVar->name)] = typeBits->size;
            }
        }
    }
    else{
        if(currentProcedure != nullptr){
            cstring name = translate(declVar->name);
            currentProcedure->addStatement(BoogieStatement(getIndent()+name+" := "+translate(declVar->initializer)+";\n"));
            currentProcedure->addModifiedGlobalVariables(name);
            if(auto typeBits = declVar->type->to<IR::Type_Bits>()){
                updateMaxBitvectorSize(typeBits);
                currentProcedure->declarationVariables[name] = typeBits->size;
            }
        }
    }
    return res;
}


cstring Translator::translate(const IR::SelectExpression *selectExpression, cstring parserName, cstring stateName, cstring localDeclArg){
    cstring res = "";
    auto renderSelectKeyCondition = [&](const IR::Expression* expr,
                                        const IR::Expression* keyset) -> cstring {
        if (expr == nullptr || keyset == nullptr) {
            return "";
        }
        if (keyset->is<IR::Dots>()) {
            return "true";
        }
        if (auto mask = keyset->to<IR::Mask>()) {
            cstring functionName = translate(mask);
            if (functionName == "") {
                return "";
            }
            return functionName+"("+translate(expr)+", "+translate(mask->right)+") == "
                +functionName+"("+translate(mask->left)+", "+translate(mask->right)+")";
        }
        cstring rhs = translate(keyset);
        if (rhs == "") {
            return "";
        }
        return translate(expr)+" == "+rhs;
    };
    auto renderSelectCaseCondition = [&](const IR::SelectCase* selectCase) -> cstring {
        if (selectCase == nullptr || selectCase->keyset == nullptr) {
            return "";
        }
        if (selectCase->keyset->is<IR::DefaultExpression>()) {
            return "true";
        }

        const int sz = selectExpression->select->components.size();
        cstring condition = "";
        for (int cnt2 = 0; cnt2 < sz; cnt2++) {
            const IR::Expression* expr = selectExpression->select->components.at(cnt2);
            const IR::Expression* key = selectCase->keyset;
            if (auto listExpression = selectCase->keyset->to<IR::ListExpression>()) {
                if (cnt2 >= static_cast<int>(listExpression->components.size())) {
                    return "";
                }
                key = listExpression->components.at(cnt2);
            }
            cstring part = renderSelectKeyCondition(expr, key);
            if (part == "") {
                return "";
            }
            if (cnt2 > 0) {
                condition += " && ";
            }
            condition += part;
        }
        if (condition == "") {
            return "true";
        }
        return condition;
    };
    // goto Statement
    if(options.gotoOrIf){

        cstring gotoStmt = getIndent()+"goto ";
        bool flag = false;  // avoid multiple default cases

        cstring defaultLabel = "State$"+stateName+"$"+"DEFAULT";
        cstring defaultBlock = "";
        cstring defaultCondition = "";

        int cnt = selectExpression->selectCases.size();
        for(auto selectCase:selectExpression->selectCases){
            std::stringstream ss_cnt;
            ss_cnt << cnt;
            if (selectCase->keyset->is<IR::DefaultExpression>()){
                if(flag)
                    continue;
                flag = true;
                cstring nextState = nullptr;
                if (auto pathExpr = selectCase->state->to<IR::PathExpression>()) {
                    nextState = translate(pathExpr->path);
                    defaultBlock += getIndent() + "goto " + parserTransitionLabel(pathExpr, parserName) + ";\n";
                } else {
                    nextState = translate(selectCase->state);
                    cstring nextStateLabel = (nextState == "accept" || nextState == "reject")
                                                 ? ("State$" + nextState)
                                                 : ("State$" + parserName + "$" + nextState);
                    defaultBlock += getIndent() + "goto " + nextStateLabel + ";\n";
                }
                // defaultBlock += getIndent()+"call "+nextState+"("+localDeclArg+");\n";
                currentProcedure->addSucc(nextState);
                addPred(nextState, currentProcedure->getName());
            }
            else{
                cstring nextState = nullptr;
                if (auto pathExpr = selectCase->state->to<IR::PathExpression>()) {
                    nextState = translate(pathExpr->path);
                } else {
                    nextState = translate(selectCase->state);
                }

                // Goto label for next state
                cstring gotoLabel = "State$"+stateName+"$"+nextState+"_"+ss_cnt.str();
                gotoStmt += gotoLabel+", ";

                res += getIndent()+"\n"+gotoLabel+":\n";
                res += getIndent()+"assume (";

                cstring condition = renderSelectCaseCondition(selectCase);
                if (condition == "") {
                    condition = "false";
                }
                if(defaultCondition.size()>0)
                    defaultCondition += "&&";
                defaultCondition += "!("+condition+")";

                res += condition;
                res += ");\n";
                cstring nextStateLabel = (nextState == "accept" || nextState == "reject")
                                             ? ("State$" + nextState)
                                             : ("State$" + parserName + "$" + nextState);
                res += getIndent() + "goto " + nextStateLabel + ";\n";
                // res += getIndent()+"call "+nextState+"("+localDeclArg+");\n";
                // res += getIndent()+"goto Exit;\n";
                currentProcedure->addSucc(nextState);
                addPred(nextState, currentProcedure->getName());
            }
            cnt--;
        }
        gotoStmt += defaultLabel+";\n";
        res = gotoStmt+res;

        res += "\n"+getIndent()+defaultLabel+":\n";
        if (defaultCondition.size() == 0)
            defaultCondition = "true";
        defaultBlock = getIndent()+"assume("+defaultCondition+");\n"+defaultBlock;
        if(!flag)
            defaultBlock = defaultBlock+"goto State$reject;\n";
        res += defaultBlock;

        // res += "State$"+stateName+"$"+"Exit:\n";
    }
    else{
        cstring defaultBlock = "";
        bool flag = false;  // avoid multiple default cases
        int cnt = 0;
        for(auto selectCase:selectExpression->selectCases){
            if (selectCase->keyset->is<IR::DefaultExpression>()){
                if(flag)
                    continue;
                flag = true;
                cstring nextState = translate(selectCase->state);
                nextState = parserName + "$" + nextState;
                defaultBlock += "call "+nextState+"("+localDeclArg+");\n";
                currentProcedure->addSucc(nextState);
                addPred(nextState, currentProcedure->getName());
            }
            else{
                if(options.addValidityAssertion) isIfStatement = true;
                cstring nextState = translate(selectCase->state);
                cstring condition = renderSelectCaseCondition(selectCase);
                if (condition == "") {
                    condition = "false";
                }
                if(cnt == 0)
                    currentProcedure->addStatement(getIndent() + "if(" + condition + "){\n");
                else 
                    currentProcedure->addStatement(getIndent() + "else if(" + condition + "){\n");
                incIndent();
                if(options.addValidityAssertion) isIfStatement = false;
                if(options.addValidityAssertion) addAssertionStatements();
                nextState = parserName + "$" + nextState;
                currentProcedure->addStatement(getIndent()+"call "+nextState+"("+localDeclArg+");\n");
                decIndent();
                cnt++;
                currentProcedure->addStatement(getIndent()+"}\n");
                currentProcedure->addSucc(nextState);
                addPred(nextState, currentProcedure->getName());
            }            
        }
        int casesSize = selectExpression->selectCases.size();
        // if default case exists
        if(flag){
            if(casesSize == 1){
                currentProcedure->addStatement(getIndent()+defaultBlock);
            }
            else{
                currentProcedure->addStatement(getIndent()+"else{\n");
                incIndent();
                currentProcedure->addStatement(getIndent()+defaultBlock);
                decIndent();
                currentProcedure->addStatement(getIndent()+"}\n");
            }
        }
    }
    return res;
}

cstring Translator::translate(const IR::Argument *argument){
    return translate(argument->expression);
}

cstring Translator::translate(const IR::Constant *constant){
    if(options.ultimateAutomizer){
        std::stringstream ss;
        ss << constant->value;
        if(constant->type->is<IR::Type_Bits>()) return ss.str();
        return ss.str()+translate(constant->type);
    }

    // Boogie bitvector literals must be non-negative. Normalize negative (and oversized)
    // P4 constants into their modular representation before appending the `bvN` suffix.
    if (auto typeBits = constant->type->to<IR::Type_Bits>()) {
        const int width = typeBits->size;
        if (width > 0) {
            const big_int mod = big_int(1) << width;
            big_int v = constant->value % mod;
            if (v < 0) {
                v += mod;
            }
            std::stringstream ss;
            ss << v;
            return ss.str()+translate(constant->type);
        }
    }

    std::stringstream ss;
    ss << constant->value;
    return ss.str()+translate(constant->type);
}

cstring Translator::translate(const IR::ConstructorCallExpression *constructorCallExpression){
    return translate(constructorCallExpression->constructedType);
}

cstring Translator::translate(const IR::Cast *cast){
    if (cast->destType != nullptr && cast->destType->is<IR::Type_Boolean>()) {
        cstring expr = translate(cast->expr);
        if (expr == "") {
            return "";
        }
        int srcSize = -1;
        if (cast->expr != nullptr && cast->expr->type != nullptr) {
            srcSize = getTypeBitwidth(cast->expr->type);
        }
        if (srcSize <= 0) {
            int inferred = getSize(expr);
            if (inferred > 0) {
                srcSize = inferred;
            }
        }
        return renderBitvectorToBool(expr, srcSize);
    }
    if (cast->destType->to<IR::Type_Bits>() || cast->destType->to<IR::Type_Name>()){
        int dstSize = -1, srcSize = -1;
        if(auto destType = cast->destType->to<IR::Type_Bits>()){
            dstSize = destType->size;
            updateMaxBitvectorSize(destType);
        }
        else if(auto destType = cast->destType->to<IR::Type_Name>()){
            cstring name = translate(destType);
            if(typeDefs.find(name) != typeDefs.end())
                dstSize = typeDefs[name];
            else return "";
        }

        cstring expr = translate(cast->expr);

        if (cast->expr->type != nullptr && cast->expr->type->is<IR::Type_Boolean>()) {
            return renderBoolToBitvector(expr, dstSize);
        }

        if(auto srcType = cast->expr->type->to<IR::Type_Bits>()){
            updateMaxBitvectorSize(srcType);
            srcSize = srcType->size;
        }
        else if(cast->expr->type->is<IR::Type_Unknown>()){
            if(currentProcedure->parameters.find(expr)!=
                currentProcedure->parameters.end()){
                srcSize = currentProcedure->parameters[expr];
            }
            else if(currentProcedure->declarationVariables.find(expr)!=
                currentProcedure->declarationVariables.end()){
                srcSize = currentProcedure->declarationVariables[expr];
            }
        }
        else if (auto srcType = cast->expr->type->to<IR::Type_Name>()) {
            cstring name = translate(srcType);
            if (typeDefs.find(name) != typeDefs.end()) {
                srcSize = typeDefs[name];
            }
        }

        if (srcSize == -1) {
            int inferred = getSize(expr);
            if (inferred > 0) {
                srcSize = inferred;
            }
        }

        if(srcSize!=-1){
            if(dstSize < srcSize) {
                if(options.ultimateAutomizer)
                    return "("+expr+"%"+"power_2_"+toString(dstSize)+"())";
                else
                    return expr+"["+std::to_string(dstSize)+":0]";
            }
            else if(dstSize > srcSize){
                if(options.ultimateAutomizer)
                    return expr;
                else
                    return "0bv"+std::to_string(dstSize-srcSize)+"++"+expr;
            }
            else{
                return expr;
            }
        }
        else{
            return expr;
        }

    }
    return "";
}

cstring Translator::translate(const IR::Slice *slice){
    if(options.ultimateAutomizer){
        cstring res = "";
        cstring expr = translate(slice->e0);
        int start = atoi(translate(slice->e1).c_str());
        int end = atoi(translate(slice->e2).c_str());
        // eg: n[3:0] = n2_n1_n0
        //            = ( (n-n%power_2_0())/power_2_0() %(power_2_3()) )
        res = "( ("+expr+"-"+expr+"%power_2_"+toString(end)+"())/power_2_"+toString(end)+"()"
            + "%(power_2_" + toString(start+1-end) + "()) )";
        return res;
    }

    cstring res = "";
    res += translate(slice->e0);
    int start;
    std::stringstream ss;
    ss << translate(slice->e1);
    ss >> start;
    res += "["+std::to_string(start+1);
    res += ":"+translate(slice->e2)+"]";
    return res;
}

cstring Translator::translate(const IR::LNot *lnot){
    return "!("+translate(lnot->expr)+")";
}

cstring Translator::translate(const IR::Mask *mask){
    cstring res = "";
    if (auto typeSet = mask->type->to<IR::Type_Set>()){
        if (auto typeBits = typeSet->elementType->to<IR::Type_Bits>()){
            updateMaxBitvectorSize(typeBits);
            cstring returnType = translate(typeBits);
            cstring functionName = "band."+returnType;

            if(options.ultimateAutomizer){
                cstring powerFunc = "";
                cstring function = "function {:inline true} "+functionName+"(left:int, right:int) : int{\n";
                
                for(int i = 0; i < typeBits->size; i++){
                    powerFunc = "power_2_"+toString(i)+"()";
                    
                    // eg: band( ((left-left%power_2_0())/power_2_0())%2, 
                    //           ((right-right%power_2_0())/power_2_0())%2 ) * power_2_0()
                    function += "    band( ((left-left%"+powerFunc+")/"+powerFunc+")%2, "+
                        "((right-right%"+powerFunc+")/"+powerFunc+")%2 ) * " + powerFunc;
                    
                    if(i < typeBits->size-1)
                        function += " +";
                    function += "\n";
                }
                function += "}\n";

                addFunction(functionName, function);
            }
            else
                addFunction("band", "bvand", returnType, returnType);
            return functionName;
        }
    }
    return res;
}

cstring Translator::translate(const IR::ArrayIndex *arrayIndex){
    cstring res = "";
    res += translate(arrayIndex->left);
    res += "."+translate(arrayIndex->right);
    // res += "["+translate(arrayIndex->right)+"]";
    return res;
}

cstring Translator::translate(const IR::BoolLiteral *boolLiteral){
    return boolLiteral->toString();
}

// Type lowering lives in translate_type.cpp.


// Operation lowering lives in translate_operator.cpp.
