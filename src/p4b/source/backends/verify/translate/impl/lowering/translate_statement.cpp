#include "translate.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <limits>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace {

const IR::Expression* methodCallArgument(const IR::MethodCallStatement* stmt, size_t index) {
    if (stmt == nullptr || stmt->methodCall == nullptr || stmt->methodCall->arguments == nullptr ||
        stmt->methodCall->arguments->size() <= index) {
        return nullptr;
    }
    const IR::Argument* arg = (*stmt->methodCall->arguments)[index];
    return arg != nullptr ? arg->expression : nullptr;
}

}  // namespace

static std::string getExternBaseName(const IR::Expression* expr) {
    if (expr == nullptr || expr->type == nullptr) {
        return "";
    }
    if (auto typeName = expr->type->to<IR::Type_Name>()) {
        return typeName->path->name.toString().c_str();
    }
    if (auto typeSpec = expr->type->to<IR::Type_Specialized>()) {
        if (auto baseName = typeSpec->baseType->to<IR::Type_Name>()) {
            return baseName->path->name.toString().c_str();
        }
    }
    if (auto typeSpec = expr->type->to<IR::Type_SpecializedCanonical>()) {
        if (auto baseName = typeSpec->baseType->to<IR::Type_Name>()) {
            return baseName->path->name.toString().c_str();
        }
    }
    if (auto typeExtern = expr->type->to<IR::Type_Extern>()) {
        return typeExtern->name.toString().c_str();
    }
    return "";
}

static std::string getControlBaseName(const IR::Expression* expr) {
    if (expr == nullptr || expr->type == nullptr) {
        return "";
    }
    if (auto typeName = expr->type->to<IR::Type_Name>()) {
        return typeName->path->name.toString().c_str();
    }
    return "";
}

void Translator::translate(const IR::Node *node){
    if (auto typeStruct = node->to<IR::Type_Struct>()) {
        translate(typeStruct);
    }
    else if (auto typeError = node->to<IR::Type_Error>()) {
        translate(typeError);
    }
    else if (auto typeExtern = node->to<IR::Type_Extern>()) {
        translate(typeExtern);
    }
    else if (auto typeEnum = node->to<IR::Type_Enum>()) {
        translate(typeEnum);
    }
    else if (auto typeSerEnum = node->to<IR::Type_SerEnum>()) {
        translate(typeSerEnum);
    }
    else if (auto typeParser = node->to<IR::Type_Parser>()) {
        translate(typeParser);
    }
    else if (auto typeControl = node->to<IR::Type_Control>()) {
        translate(typeControl);
    }
    else if (auto typePackage = node->to<IR::Type_Package>()) {
        translate(typePackage);
    }
    else if (auto typeHeader = node->to<IR::Type_Header>()) {
        translate(typeHeader);
    }
    else if (auto p4Parser = node->to<IR::P4Parser>()) {
        translate(p4Parser);
    }
    else if (auto p4Control = node->to<IR::P4Control>()) {
        translate(p4Control);
    }
    else if (auto method = node->to<IR::Method>()) {
        translate(method);
    }
    else if (auto instance = node->to<IR::Declaration_Instance>()) {
        translate(instance);
    }
    else if (auto typeTypedef = node->to<IR::Type_Typedef>()) {
        translate(typeTypedef);
    }
}

void Translator::translate(const IR::Node *node, cstring arg){
    (void)node;
    (void)arg;
}

cstring Translator::translate(const IR::StatOrDecl *statOrDecl){
    if (auto stat = statOrDecl->to<IR::Statement>()) {
        return translate(stat);
    }
    else if (auto decl = statOrDecl->to<IR::Declaration>()) {
        return translate(decl);
    }
    return "";
}

cstring Translator::translate(const IR::Statement *stat){
    if (auto methodCall = stat->to<IR::MethodCallStatement>()){
        return translate(methodCall);
    }
    else if (auto ifStatement = stat->to<IR::IfStatement>()){
        return translate(ifStatement);
    }
    else if (auto blockStatement = stat->to<IR::BlockStatement>()){
        return translate(blockStatement);
    }
    else if (auto assignmentStatement = stat->to<IR::AssignmentStatement>()){
        return translate(assignmentStatement);
    }
    else if (auto switchStatement = stat->to<IR::SwitchStatement>()){
        return translate(switchStatement);
    }
    return "";
}

cstring Translator::translate(const IR::ExitStatement *exitStatement){
    (void)exitStatement;
    return "";
}
cstring Translator::translate(const IR::ReturnStatement *returnStatement){
    if (currentReturnVar == nullptr || currentReturnVar == "") {
        return "";
    }
    if (returnStatement == nullptr || returnStatement->expression == nullptr) {
        return getIndent()+"return;\n";
    }
    cstring expr = translate(returnStatement->expression);
    return getIndent()+currentReturnVar+" := "+expr+";\n"+getIndent()+"return;\n";
}
cstring Translator::translate(const IR::EmptyStatement *emptyStatement){
    (void)emptyStatement;
    return "";
}

cstring Translator::translate(const IR::AssignmentStatement *assignmentStatement){
    struct MirrorFlagInfo {
        cstring flag;
        int width;
        bool isBool;
    };
    auto getMirrorFlagInfo = [&](const IR::Expression *leftExpr) -> MirrorFlagInfo {
        MirrorFlagInfo info{nullptr, -1, false};
        auto member = leftExpr->to<IR::Member>();
        if (member == nullptr) {
            return info;
        }
        if (member->member == "mirror_type") {
            cstring base = translate(member->expr);
            if (base.find("ig_") != nullptr || base.find("ingress") != nullptr) {
                info.flag = "p4b_clone_i2e";
            } else if (base.find("eg_") != nullptr || base.find("egress") != nullptr) {
                info.flag = "p4b_clone_e2e";
            }
        } else if (member->member == "resubmit_type") {
            info.flag = "p4b_recirculate";
        } else {
            return info;
        }
        if (auto leftBits = leftExpr->type->to<IR::Type_Bits>()) {
            info.width = leftBits->size;
        } else if (auto leftName = leftExpr->type->to<IR::Type_Name>()) {
            cstring name = translate(leftName);
            if (typeDefs.find(name) != typeDefs.end()) {
                info.width = typeDefs[name];
            }
        } else if (leftExpr->type->to<IR::Type_Boolean>()) {
            info.isBool = true;
        }
        return info;
    };
    auto emitMirrorFlag = [&](const MirrorFlagInfo &info, const cstring &rightExpr) {
        if (info.flag == nullptr || currentProcedure == nullptr || rightExpr == "") {
            return;
        }
        if (rightExpr == "havoc") {
            currentProcedure->addStatement(getIndent()+"havoc "+info.flag+";\n");
        } else if (info.isBool) {
            currentProcedure->addStatement(getIndent()+info.flag+" := "+info.flag+" || "+rightExpr+";\n");
        } else {
            cstring zero = info.width > 0 ? ("0bv" + toString(info.width)) : "0";
            currentProcedure->addStatement(getIndent()+info.flag+" := "+info.flag+" || ("+rightExpr+" != "+zero+");\n");
        }
        currentProcedure->addModifiedGlobalVariables(info.flag);
    };
    MirrorFlagInfo mirrorInfo = getMirrorFlagInfo(assignmentStatement->left);

    if (auto member = assignmentStatement->left->to<IR::Member>()) {
        int totalBits = 0;
        int hi = 0;
        int lo = 0;
        cstring baseName = nullptr;
        if (getStructFieldRange(member->expr, member->member.toString(), totalBits, hi, lo, baseName)) {
            cstring right = translate(assignmentStatement->right);
            emitMirrorFlag(mirrorInfo, right);
            updateModifiedVariables(baseName);
            cstring res = getIndent()+baseName+" := ";
            if (options.ultimateAutomizer) {
                int l = hi + 1;
                int r = lo;
                res += baseName + "-" + baseName + "%power_2_" + toString(l) + "() + "
                       + right + " * power_2_" + toString(r) + "() + "
                       + baseName + " % power_2_" + toString(r) + "()";
            } else {
                if (hi + 1 < totalBits) {
                    res += baseName+"["+toString(totalBits)+":"+toString(hi+1)+"]++";
                }
                res += right;
                if (lo > 0) {
                    res += "++"+baseName+"["+toString(lo)+":0]";
                }
            }
            res += ";\n";
            currentProcedure->addStatement(res);
            return "";
        }
        if (auto pathExpr = member->expr->to<IR::PathExpression>()) {
            cstring structName = nullptr;
            cstring paramName = translate(pathExpr->path);
            if (getParamStructName(paramName, structName)) {
                if (getStructFieldRangeByName(paramName, structName, member->member.toString(),
                                              totalBits, hi, lo)) {
                    cstring right = translate(assignmentStatement->right);
                    emitMirrorFlag(mirrorInfo, right);
                    updateModifiedVariables(paramName);
                    cstring res = getIndent()+paramName+" := ";
                    if (options.ultimateAutomizer) {
                        int l = hi + 1;
                        int r = lo;
                        res += paramName + "-" + paramName + "%power_2_" + toString(l) + "() + "
                               + right + " * power_2_" + toString(r) + "() + "
                               + paramName + " % power_2_" + toString(r) + "()";
                    } else {
                        if (hi + 1 < totalBits) {
                            res += paramName+"["+toString(totalBits)+":"+toString(hi+1)+"]++";
                        }
                        res += right;
                        if (lo > 0) {
                            res += "++"+paramName+"["+toString(lo)+":0]";
                        }
                    }
                    res += ";\n";
                    currentProcedure->addStatement(res);
                    return "";
                }
            }
        }
    }

    if(auto slice = assignmentStatement->left->to<IR::Slice>()){
        cstring res = "";
        cstring left = translate(slice->e0);
        updateModifiedVariables(left);
        res += getIndent()+left + " := ";
        if(auto typeBits = slice->e0->type->to<IR::Type_Bits>()){
            updateMaxBitvectorSize(typeBits);

            int size, l, r;
            size = typeBits->size;
            std::stringstream ss;
            ss << translate(slice->e1);
            ss >> l;
            std::stringstream ss2;
            ss2 << translate(slice->e2);
            ss2 >> r;
            l++;
            if(options.ultimateAutomizer){
                // P4: left[e1:e2] = right
                // Boogie: left = left[size:e1+1]++right++left[e2:0]
                // UA: left = (left - left % power_2_e1+1()) + right * power_2_e2() 
                //            + left % power_2_e2()
                res += left + "-" + left + "%power_2_" + toString(l) + "() + "
                        + translate(assignmentStatement->right) + " * power_2_" + toString(r) + "() + "
                        + left + " % power_2_" + toString(r) + "()";
            }
            else{
                if(l < size)
                    res += left+"["+std::to_string(size)+":"+std::to_string(l)+"]++";
                res += translate(assignmentStatement->right);
                if(r > 0)
                    res += "++"+left+"["+std::to_string(r)+":0]";
            }
            res += ";\n";
            currentProcedure->addStatement(res);
            return "";
        }
        return "";
    }
    cstring res = "";
    cstring left = translate(assignmentStatement->left);
    cstring right = translate(assignmentStatement->right);
    auto ensureScalarTempDeclared = [&](const IR::Expression *leftExpr, const IR::Expression *rightExpr,
                                        const cstring &leftName) {
        if (leftExpr == nullptr || currentProcedure == nullptr || leftName == "") {
            return;
        }
        if (leftName.find(".") != nullptr || leftName.find("[") != nullptr) {
            return;
        }
        if (emittedVarDecls.find(leftName) != emittedVarDecls.end()) {
            return;
        }
        if (parserLocalVars.find(leftName) != parserLocalVars.end()) {
            return;
        }
        if (currentProcedure->parameters.find(leftName) != currentProcedure->parameters.end()) {
            return;
        }
        if (currentProcedure->declarationVariables.find(leftName) != currentProcedure->declarationVariables.end() ||
            currentProcedure->hasLocalVariables(leftName)) {
            return;
        }

        const IR::Type *type = leftExpr->type;
        if (type == nullptr || type->is<IR::Type_Unknown>() || type->is<IR::Type_InfInt>()) {
            auto it = declVarTypes.find(leftName);
            if (it != declVarTypes.end()) {
                type = it->second;
            }
        }
        if ((type == nullptr || type->is<IR::Type_Unknown>() || type->is<IR::Type_InfInt>())
            && rightExpr != nullptr && rightExpr->type != nullptr
            && !rightExpr->type->is<IR::Type_Unknown>() && !rightExpr->type->is<IR::Type_InfInt>()) {
            type = rightExpr->type;
        }
        if ((type == nullptr || type->is<IR::Type_Unknown>() || type->is<IR::Type_InfInt>())
            && leftName.find("hasReturned") != nullptr) {
            addDeclaration("var "+leftName+":bool;\n");
            updateVariableSize(leftName, 0);
            addGlobalVariables(leftName);
            return;
        }
        if (type == nullptr) {
            return;
        }

        if (auto typeBits = type->to<IR::Type_Bits>()) {
            if (options.ultimateAutomizer) {
                addDeclaration("var "+leftName+":int;\n");
            } else {
                addDeclaration("var "+leftName+":"+translate(type)+";\n");
            }
            updateVariableSize(leftName, typeBits->size);
            updateMaxBitvectorSize(typeBits);
            addGlobalVariables(leftName);
        } else if (type->is<IR::Type_Boolean>()) {
            addDeclaration("var "+leftName+":bool;\n");
            updateVariableSize(leftName, 0);
            addGlobalVariables(leftName);
        } else if (auto typeName = type->to<IR::Type_Name>()) {
            cstring typeId = translate(typeName->path);
            if (typeDefs.find(typeId) != typeDefs.end()) {
                addDeclaration("var "+leftName+":"+translate(type)+";\n");
                updateVariableSize(leftName, typeDefs[typeId]);
                addGlobalVariables(leftName);
            }
        }
    };
    ensureScalarTempDeclared(assignmentStatement->left, assignmentStatement->right, left);
    // Some P4 frontends/targets (notably Tofino/TNA) can lower complex payload
    // construction as struct/list literals that we currently do not translate to
    // a Boogie expression. In that case `translate(rhs)` returns the empty
    // string, and emitting `lhs := ;` makes the generated Boogie program
    // syntactically invalid.
    //
    // Conservatively model such assignments as nondeterministic updates.
    if (right == "") {
        right = "havoc";
    }
    if(right=="havoc"){
        emitMirrorFlag(mirrorInfo, right);
        updateModifiedVariables(left);
        currentProcedure->addStatement(getIndent()+"havoc "+left+";\n");
        return "";
    }
    if(options.bitBlasting && assignmentStatement->left->type->to<IR::Type_Bits>()){
        auto typeBits = assignmentStatement->left->type->to<IR::Type_Bits>();
        int size = typeBits->size;
        for(int i = 0; i < size; i++){
            updateModifiedVariables(connect(left, i));
            currentProcedure->addStatement(getIndent()+connect(left, i)+" := "+
                connect(right, i)+";\n");
        }
        emitMirrorFlag(mirrorInfo, right);
        if(left=="standard_metadata.egress_spec"){
            for(int i = 0; i < EGRESS_SPEC_SIZE; i++){
                currentProcedure->addStatement(getIndent()+connect("standard_metadata.egress_port", i)+
                    " := "+connect(right, i)+";\n");
                currentProcedure->addModifiedGlobalVariables(connect("standard_metadata.egress_port", i));
            }
            res += getIndent()+"forward := true;\n";
            currentProcedure->addModifiedGlobalVariables("forward");
        }
    }
    else{
        if(!options.ultimateAutomizer){
            int leftSize = -1;
            int rightSize = -1;
            if(auto leftBits = assignmentStatement->left->type->to<IR::Type_Bits>()){
                leftSize = leftBits->size;
            }
            else if(auto leftName = assignmentStatement->left->type->to<IR::Type_Name>()){
                cstring name = translate(leftName);
                if(typeDefs.find(name) != typeDefs.end()) leftSize = typeDefs[name];
            }
            if(auto rightBits = assignmentStatement->right->type->to<IR::Type_Bits>()){
                rightSize = rightBits->size;
            }
            else if(auto rightName = assignmentStatement->right->type->to<IR::Type_Name>()){
                cstring name = translate(rightName);
                if(typeDefs.find(name) != typeDefs.end()) rightSize = typeDefs[name];
            }
            if(rightSize < 0){
                int sz = getSize(right);
                if(sz > 0) rightSize = sz;
            }
            if(leftSize > 0 && rightSize > 0 && leftSize != rightSize){
                if(rightSize < leftSize){
                    right = "0bv" + toString(leftSize - rightSize) + " ++ " + right;
                } else {
                    right = right + "[" + toString(leftSize) + ":0]";
                }
            }
        }
        updateModifiedVariables(left);
        res = getIndent()+left+" := "
            +right+";\n";
        if(left=="standard_metadata.egress_spec"){
            res += getIndent()+"standard_metadata.egress_port := " + right+";\n";
            res += getIndent()+"forward := true;\n";
            currentProcedure->addModifiedGlobalVariables("standard_metadata.egress_port");
            currentProcedure->addModifiedGlobalVariables("forward");
        }
        currentProcedure->addStatement(res);
        emitMirrorFlag(mirrorInfo, right);
    }
    return "";
}

void Translator::addAssertionStatements(){
    for(cstring stmt:assertionStatements){
        if(currentProcedure != nullptr)
            currentProcedure->addStatement(stmt);
    }
    assertionStatements.clear();
}

void Translator::storeAssertionStatement(cstring stmt){
    assertionStatements.insert(stmt);
}

cstring Translator::translate(const IR::IfStatement *ifStatement){
    cstring res = "";
    cstring condition = "";
    condition += getIndent()+"if(";
    if(options.addValidityAssertion) isIfStatement = true;
    condition += translate(ifStatement->condition);
    condition += "){\n";
    currentProcedure->addStatement(condition);
    res += condition;
    incIndent();
    
    if(options.addValidityAssertion) isIfStatement = false;
    if(options.addValidityAssertion) addAssertionStatements();
    
    res += translate(ifStatement->ifTrue);
    decIndent();
    currentProcedure->addStatement(getIndent()+"}\n");
    // res += getIndent()+"}\n";
    if(ifStatement->ifFalse!=nullptr){
        currentProcedure->addStatement(getIndent()+"else{\n");
        res += getIndent()+"else{\n";
        incIndent();
        res += translate(ifStatement->ifFalse);
        decIndent();
        currentProcedure->addStatement(getIndent()+"}\n");
        res += getIndent()+"}\n";
    }
    return "";
}

cstring Translator::translate(const IR::BlockStatement *blockStatement){
    cstring res = "";
    if (blockStatement != nullptr) {
        if (auto anno = blockStatement->getAnnotation("p4b_assert")) {
            if (anno->getExpr().size() == 1) {
                cstring cond = translate(anno->getExpr(0));
                currentProcedure->addStatement(getIndent() + "assert " + cond + ";\n");
            }
        }
        if (auto anno = blockStatement->getAnnotation("p4b_assume")) {
            if (anno->getExpr().size() == 1) {
                cstring cond = translate(anno->getExpr(0));
                currentProcedure->addStatement(getIndent() + "assume " + cond + ";\n");
            }
        }
    }
    for(auto statOrDecl:blockStatement->components){
        currentProcedure->addStatement(translate(statOrDecl));
        // res += translate(statOrDecl);
    }
    return res;
}

cstring Translator::translate(const IR::MethodCallStatement *methodCallStatement){
    cstring expr = translate(methodCallStatement->methodCall->method);
    if (expr == "p4b_assert" || expr == "p4b_assume") {
        if (methodCallStatement->methodCall->arguments != nullptr &&
            methodCallStatement->methodCall->arguments->size() == 1) {
            auto condExpr = (*methodCallStatement->methodCall->arguments)[0]->expression;
            cstring cond = translate(condExpr);
            if (expr == "p4b_assert") {
                currentProcedure->addStatement(getIndent() + "assert " + cond + ";\n");
            } else {
                currentProcedure->addStatement(getIndent() + "assume " + cond + ";\n");
            }
        }
        return "";
    }
    if (auto member = methodCallStatement->methodCall->method->to<IR::Member>()) {
        if (member->member == "apply") {
            cstring receiverName = translate(member->expr);
            auto controlIt = controlInstanceTypes.find(receiverName);
            std::string controlName;
            if (controlIt != controlInstanceTypes.end()) {
                controlName = controlIt->second.c_str();
            } else {
                controlName = getControlBaseName(member->expr);
            }
            if (std::getenv("P4VERIFY_DEBUG_CONTROL_APPLY") != nullptr) {
                std::cerr << "[p4verify-control-apply] receiver="
                          << (member->expr ? member->expr->toString() : "<null>")
                          << " type="
                          << ((member->expr && member->expr->type) ? member->expr->type->toString() : "<null>")
                          << " rendered=" << receiverName
                          << " control=" << controlName << std::endl;
            }
            if (!controlName.empty()) {
                cstring controlProc = cstring(controlName);
                if (procedures.find(controlProc) != procedures.end()) {
                    currentProcedure->addStatement(getIndent()+"call "+controlProc+"();\n");
                    currentProcedure->addSucc(controlProc);
                    addPred(controlProc, currentProcedure->getName());
                    return "";
                }
            }
        }
        if (member->member == "execute" || member->member == "execute_log") {
            cstring base = translate(member->expr);
            if (registerActions.find(base) != registerActions.end()) {
                translate(methodCallStatement->methodCall);
                return "";
            }
            if (meterExterns.find(base) != meterExterns.end()) {
                translate(methodCallStatement->methodCall);
                return "";
            }
        }
        if (member->member == "pack") {
            std::string externName = getExternBaseName(member->expr);
            cstring baseExpr = translate(member->expr);
            const bool looksLikeDigest =
                (externName == "Digest") || (externName.find("Digest") != std::string::npos) ||
                (externName.empty() && (baseExpr.find("digest") != nullptr || baseExpr.find("Digest") != nullptr));
            if (looksLikeDigest) {
                // Digest delivery is modeled as an architecture event flag.  The
                // control-plane payload is outside a single-switch P4 step, but the
                // verifier must still observe that this packet emitted a digest.
                currentProcedure->addStatement(getIndent()+"p4b_digest := true;\n");
                currentProcedure->addModifiedGlobalVariables("p4b_digest");
                return "";
            }
        }
        if (member->member == "add") {
            std::string externName = getExternBaseName(member->expr);
            cstring baseExpr = translate(member->expr);
            const bool looksLikeChecksum =
                (externName == "Checksum") || (externName.find("Checksum") != std::string::npos) ||
                (baseExpr.find("checksum") != nullptr) || (baseExpr.find("Checksum") != nullptr);
            if (looksLikeChecksum) {
                std::vector<cstring> renderedArgs;
                std::vector<cstring> renderedArgTypes;
                if (methodCallStatement->methodCall->arguments != nullptr) {
                    for (auto arg : *methodCallStatement->methodCall->arguments) {
                        cstring rendered = translate(arg);
                        if (rendered == "") {
                            continue;
                        }
                        renderedArgs.push_back(rendered);
                        cstring argType = inferBoogieType(arg->expression->type, rendered);
                        if (argType == "") {
                            argType = "Ref";
                        }
                        renderedArgTypes.push_back(argType);
                    }
                }
                cstring declName = baseExpr+"."+member->member.toString();
                if (procedures.find(declName) == procedures.end()) {
                    BoogieProcedure extProc = BoogieProcedure(declName);
                    cstring decl = "procedure "+declName+"(";
                    for (size_t i = 0; i < renderedArgTypes.size(); ++i) {
                        if (i != 0) {
                            decl += ", ";
                        }
                        decl += "arg"+toString(static_cast<int>(i))+":"+renderedArgTypes[i];
                    }
                    decl += ");\n";
                    extProc.addDeclaration(decl);
                    addProcedure(extProc);
                }
                cstring stmt = getIndent()+"call "+declName+"(";
                for (size_t i = 0; i < renderedArgs.size(); ++i) {
                    if (i != 0) {
                        stmt += ", ";
                    }
                    stmt += renderedArgs[i];
                }
                stmt += ");\n";
                currentProcedure->addStatement(stmt);
                currentProcedure->addSucc(declName);
                addPred(declName, currentProcedure->getName());
                return "";
            }
        }
        if (member->member == "emit") {
            std::string externName = getExternBaseName(member->expr);
            // Tofino/TNA externs sometimes lose precise type info across compiler
            // passes; fall back to a name-based heuristic to avoid generating
            // malformed Boogie for `mirror.emit<...>(..., {...})`.
            //
            // Without this, we may translate the call as a generic extern method
            // invocation and end up emitting an empty record assignment `tmp := ;`,
            // which causes Ultimate to reject the program with a syntax error.
            cstring baseExpr = translate(member->expr);
            const bool looksLikeMirror =
                (externName == "Mirror") || (externName.find("Mirror") != std::string::npos) ||
                (externName.empty() && baseExpr.find("mirror") != nullptr);
            const bool looksLikeResubmit =
                (externName == "Resubmit") || (externName.find("Resubmit") != std::string::npos) ||
                (externName.empty() && baseExpr.find("resubmit") != nullptr);
            const bool looksLikePacketOut =
                (externName == "packet_out") || (externName == "PacketOut") ||
                (externName.find("packet_out") != std::string::npos) ||
                (externName.find("PacketOut") != std::string::npos) ||
                (!looksLikeMirror && !looksLikeResubmit && baseExpr.find("pkt") != nullptr);

            if (looksLikeMirror) {
                // If the frontend produced a list/struct literal (e.g., `{...}`) for the mirror
                // payload and our expression translator couldn't lower it, we might already have
                // emitted a placeholder assignment `tmp := ;` before reaching this handler.
                //
                // This breaks Boogie parsing; remove the placeholder and model the effect via
                // the clone flag only.
                if (currentProcedure != nullptr) {
                    cstring last = currentProcedure->lastStatement();
                    if (last.find(":= ;") != nullptr) {
                        currentProcedure->removeLastStatement();
                    }
                }
                // TNA model: actual mirroring is gated by the intrinsic `mirror_type` metadata.
                // NetLock (and other Tofino pipelines) may call `mirror.emit(...)` unconditionally
                // but only set `ig_intr_dprsr_md.mirror_type` when they want to generate a clone.
                //
                // If we set `p4b_clone_i2e := true` unconditionally here, every packet generates a
                // derived event and can block host injection in bounded specs (queue_capacity=1),
                // making multi-step functional checks unreachable.
                //
                // Prefer a best-effort guard when the variable is present; fall back to the old
                // over-approximation when we can't identify the intrinsic field.
                const bool hasIngressMirrorType =
                    (globalVariables.find("ig_intr_dprsr_md.mirror_type") != globalVariables.end());
                if (hasIngressMirrorType) {
                    currentProcedure->addStatement(
                        getIndent()+"p4b_clone_i2e := p4b_clone_i2e || (ig_intr_dprsr_md.mirror_type == 1bv3);\n");
                } else {
                    currentProcedure->addStatement(getIndent()+"p4b_clone_i2e := true;\n");
                }
                currentProcedure->addModifiedGlobalVariables("p4b_clone_i2e");
                return "";
            }
            if (looksLikeResubmit) {
                currentProcedure->addStatement(getIndent()+"p4b_recirculate := true;\n");
                currentProcedure->addModifiedGlobalVariables("p4b_recirculate");
                return "";
            }
            if (looksLikePacketOut) {
                std::vector<cstring> renderedArgs;
                std::vector<cstring> renderedArgTypes;
                if (methodCallStatement->methodCall->arguments != nullptr) {
                    for (auto arg : *methodCallStatement->methodCall->arguments) {
                        cstring rendered = translate(arg);
                        if (rendered == "") {
                            continue;
                        }
                        renderedArgs.push_back(rendered);
                        cstring argType = inferBoogieType(arg->expression->type, rendered);
                        if (argType == "" || argType == "headers") {
                            argType = "Ref";
                        }
                        renderedArgTypes.push_back(argType);
                    }
                }

                cstring declName = baseExpr+"."+member->member.toString();
                if (procedures.find(declName) == procedures.end()) {
                    BoogieProcedure emitProc = BoogieProcedure(declName);
                    cstring decl = "procedure "+declName+"(";
                    for (size_t i = 0; i < renderedArgTypes.size(); ++i) {
                        if (i != 0) {
                            decl += ", ";
                        }
                        decl += "arg"+toString(static_cast<int>(i))+":"+renderedArgTypes[i];
                    }
                    decl += ");\n";
                    emitProc.addDeclaration(decl);
                    addProcedure(emitProc);
                }
                cstring stmt = getIndent()+"call "+declName+"(";
                for (size_t i = 0; i < renderedArgs.size(); ++i) {
                    if (i != 0) {
                        stmt += ", ";
                    }
                    stmt += renderedArgs[i];
                }
                stmt += ");\n";
                currentProcedure->addStatement(stmt);
                currentProcedure->addSucc(declName);
                addPred(declName, currentProcedure->getName());
                return "";
            }
        }
        if (member->member == IR::Type_Array::pop_front) {
            auto typeStack = P4VerifyCompat::asHeaderStackType(member->expr->type);
            if (typeStack == nullptr) {
                return getIndent()+"// pop_front (unsupported type)\n";
            }
            int popCount = 1;
            if (methodCallStatement->methodCall->arguments->size() > 0) {
                auto argExpr = (*methodCallStatement->methodCall->arguments)[0]->expression;
                if (auto constant = argExpr->to<IR::Constant>()) {
                    std::stringstream ss;
                    ss << constant->value;
                    ss >> popCount;
                } else {
                    return getIndent()+"// pop_front (non-constant)\n";
                }
            }
            if (popCount <= 0) {
                return getIndent()+"// pop_front (noop)\n";
            }
            int stackSize = 0;
            if (auto constant = typeStack->size->to<IR::Constant>()) {
                std::stringstream ss;
                ss << constant->value;
                ss >> stackSize;
            } else {
                return getIndent()+"// pop_front (unknown stack size)\n";
            }
            if (stackSize <= 0) {
                return getIndent()+"// pop_front (empty stack)\n";
            }
            const IR::Type_Header* typeHeader = resolveHeaderType(typeStack->elementType);
            if (typeHeader == nullptr) {
                return getIndent()+"// pop_front (unknown element type)\n";
            }
            cstring base = translate(member->expr);
            currentProcedure->addStatement(getIndent()+"// pop_front\n");
            for (int i = 0; i < stackSize; i++) {
                int srcIndex = i + popCount;
                cstring dstRef = base + "." + cstring::to_cstring(i);
                if (srcIndex < stackSize) {
                    cstring srcRef = base + "." + cstring::to_cstring(srcIndex);
                    for (const IR::StructField* field : typeHeader->fields) {
                        cstring dstField = dstRef + "." + field->name;
                        cstring srcField = srcRef + "." + field->name;
                        currentProcedure->addStatement(getIndent()+dstField+" := "+srcField+";\n");
                        currentProcedure->addModifiedGlobalVariables(dstField);
                    }
                    currentProcedure->addStatement(getIndent()+dstRef+".valid := "+srcRef+".valid;\n");
                    currentProcedure->addModifiedGlobalVariables(dstRef+".valid");
                    currentProcedure->addStatement(getIndent()+"isValid["+dstRef+"] := isValid["+srcRef+"];\n");
                    currentProcedure->addModifiedGlobalVariables("isValid");
                } else {
                    currentProcedure->addStatement(getIndent()+dstRef+".valid := false;\n");
                    currentProcedure->addModifiedGlobalVariables(dstRef+".valid");
                    currentProcedure->addStatement(getIndent()+"isValid["+dstRef+"] := false;\n");
                    currentProcedure->addModifiedGlobalVariables("isValid");
                }
            }
            return "";
        }
    }
    if(expr.find("verify_checksum") != nullptr){
        const IR::Expression* conditionExpr = methodCallArgument(methodCallStatement, 0);
        cstring condition = conditionExpr != nullptr ? translate(conditionExpr) : "true";
        currentProcedure->addStatement(getIndent()+"if ("+condition+") {\n");
        incIndent();
        currentProcedure->addStatement(getIndent()+"p4b_checksum_verified := true;\n");
        currentProcedure->addStatement(getIndent()+"havoc p4b_checksum_error;\n");
        currentProcedure->addModifiedGlobalVariables("p4b_checksum_verified");
        currentProcedure->addModifiedGlobalVariables("p4b_checksum_error");
        decIndent();
        currentProcedure->addStatement(getIndent()+"}\n");
        return "";
    }
    else if(expr.find("update_checksum") != nullptr){
        const IR::Expression* conditionExpr = methodCallArgument(methodCallStatement, 0);
        const IR::Expression* checksumExpr = methodCallArgument(methodCallStatement, 2);
        cstring condition = conditionExpr != nullptr ? translate(conditionExpr) : "true";
        cstring checksum = checksumExpr != nullptr ? translate(checksumExpr) : "";
        currentProcedure->addStatement(getIndent()+"if ("+condition+") {\n");
        incIndent();
        currentProcedure->addStatement(getIndent()+"p4b_checksum_updated := true;\n");
        currentProcedure->addModifiedGlobalVariables("p4b_checksum_updated");
        if (checksum != "") {
            currentProcedure->addStatement(getIndent()+"havoc "+checksum+";\n");
            updateModifiedVariables(checksum);
        }
        decIndent();
        currentProcedure->addStatement(getIndent()+"}\n");
        return "";
    }
    else if(expr == "clone" || expr == "clone3" || expr == "clone_preserving_field_list"){
        std::string flag = "p4b_clone_i2e";
        if (methodCallStatement->methodCall->arguments != nullptr &&
            methodCallStatement->methodCall->arguments->size() >= 1) {
            cstring cloneType = translate((*methodCallStatement->methodCall->arguments)[0]);
            if (cloneType.find("E2E") != nullptr) {
                flag = "p4b_clone_e2e";
            } else if (cloneType.find("I2I") != nullptr) {
                flag = "p4b_clone_i2i";
            }
        }
        currentProcedure->addStatement(getIndent()+flag+" := true;\n");
        currentProcedure->addModifiedGlobalVariables(flag.c_str());
        return "";
    }
    // else if(expr.find("hash") != nullptr){
    else if(expr=="hash"){
        cstring expr2 = translate(methodCallStatement->methodCall);
        if (expr2 != "") {
            currentProcedure->addStatement(getIndent()+expr2);
        } else {
            currentProcedure->addStatement(getIndent()+"// hash\n");
        }
        return "";
    }
    else if(expr.find("digest") != nullptr){
        currentProcedure->addStatement(getIndent()+"p4b_digest := true;\n");
        currentProcedure->addModifiedGlobalVariables("p4b_digest");
        return "";
    }
    else if(expr.find(".count") != nullptr || expr.find(".increment") != nullptr || expr.find(".add") != nullptr){
        bool isCounterExternCall = false;
        if (auto member = methodCallStatement->methodCall->method->to<IR::Member>()) {
            if (member->member == "count" || member->member == "increment" || member->member == "add") {
                cstring base = translate(member->expr);
                isCounterExternCall = counterExterns.find(base) != counterExterns.end();
            }
        }
        if (isCounterExternCall) {
            cstring expr2 = translate(methodCallStatement->methodCall);
            if(expr2.find(".count(") != nullptr || expr2.find(".increment(") != nullptr ||
               expr2.find(".add(") != nullptr){
                currentProcedure->addStatement(getIndent()+"call "+expr2+";\n");
                return "";
            }
        }
    }
    else if(expr.find(".write") != nullptr){
        currentProcedure->addStatement(getIndent()+"// write\n");
        cstring expr2 = translate(methodCallStatement->methodCall);
        currentProcedure->addStatement(getIndent()+"call "+expr2+";\n");
        return "";
    }
    else if(expr.find(".read") != nullptr){
        cstring expr2 = translate(methodCallStatement->methodCall);
        if(expr2 != ""){
            currentProcedure->addStatement(getIndent()+"// read\n");
            currentProcedure->addStatement(getIndent()+expr2+";\n");
        }
        return "";
    }
    else if(expr.find("random") != nullptr){
        return getIndent()+"// random\n";
    }
    else if(expr.find(".push_front") != nullptr){
        return getIndent()+"// push_front\n";
    }
    else if(expr.find(".pop_front") != nullptr){
        return getIndent()+"// pop_front\n";
    }
    else if(expr.find(".execute_meter") != nullptr){
        return getIndent()+"// execute_meter\n";
    }
    else if(expr.find("resubmit") != nullptr){
        currentProcedure->addStatement(getIndent()+"p4b_recirculate := true;\n");
        currentProcedure->addModifiedGlobalVariables("p4b_recirculate");
        return "";
    }
    else if(expr.find("truncate") != nullptr){
        return getIndent()+"// truncate\n";
    }
    else if(expr.find("recirculate") != nullptr){
        currentProcedure->addStatement(getIndent()+"p4b_recirculate := true;\n");
        currentProcedure->addModifiedGlobalVariables("p4b_recirculate");
        return "";
    }
    else if(expr == "verify"){
        currentProcedure->addStatement(getIndent()+"// verify\n");
        cstring expr2 = translate(methodCallStatement->methodCall);
        currentProcedure->addStatement(getIndent()+expr2+";\n");
        return "";
    }

    // Actions with out/inout parameters must be translated into Boogie calls with returns.
    auto actionIt = actions.find(expr);
    if (actionIt != actions.end()) {
        const IR::P4Action* action = actionIt->second;
        const std::vector<IR::Direction>* effDirs = nullptr;
        auto dirIt = actionParamDirections.find(expr);
        if (dirIt != actionParamDirections.end() &&
            action != nullptr && action->parameters != nullptr &&
            dirIt->second.size() == action->parameters->parameters.size()) {
            effDirs = &dirIt->second;
        }

        bool needsReturns = false;
        size_t paramIdx = 0;
        for (auto parameter : action->parameters->parameters) {
            const IR::Direction dir = (effDirs != nullptr) ? (*effDirs)[paramIdx] : parameter->direction;
            if (dir == IR::Direction::Out || dir == IR::Direction::InOut) {
                needsReturns = true;
                break;
            }
            paramIdx++;
        }
        if (needsReturns) {
            std::vector<cstring> inArgs;
            std::vector<cstring> outArgs;
            if (methodCallStatement->methodCall->arguments != nullptr) {
                int argIdx = 0;
                int argCount = methodCallStatement->methodCall->arguments->size();
                paramIdx = 0;
                for (auto parameter : action->parameters->parameters) {
                    if (argIdx >= argCount) {
                        break;
                    }
                    const IR::Argument* arg = methodCallStatement->methodCall->arguments->at(argIdx);
                    cstring rendered = "";
                    if (arg && arg->expression) {
                        rendered = translate(arg->expression);
                    }
                    const IR::Direction dir = (effDirs != nullptr) ? (*effDirs)[paramIdx] : parameter->direction;
                    if (dir == IR::Direction::Out) {
                        if (rendered != "") {
                            outArgs.push_back(rendered);
                        }
                    } else if (dir == IR::Direction::InOut) {
                        if (rendered != "") {
                            inArgs.push_back(rendered);
                            outArgs.push_back(rendered);
                        }
                    } else {
                        if (rendered != "") {
                            inArgs.push_back(rendered);
                        }
                    }
                    argIdx++;
                    paramIdx++;
                }
            }

            cstring stmt = getIndent()+"call ";
            if (!outArgs.empty()) {
                for (size_t i = 0; i < outArgs.size(); ++i) {
                    if (i != 0) {
                        stmt += ", ";
                    }
                    stmt += outArgs[i];
                    if (isGlobalVariable(outArgs[i])) {
                        updateModifiedVariables(outArgs[i]);
                    }
                }
                stmt += " := ";
            }
            stmt += expr+"(";
            for (size_t i = 0; i < inArgs.size(); ++i) {
                if (i != 0) {
                    stmt += ", ";
                }
                stmt += inArgs[i];
            }
            stmt += ");\n";
            currentProcedure->addStatement(stmt);
            currentProcedure->addSucc(expr);
            addPred(expr, currentProcedure->getName());
            return "";
        }
    }

    cstring expr2 = translate(methodCallStatement->methodCall);
    if(expr2.find(";\n")){
        currentProcedure->addStatement(getIndent()+expr2);
    }
    else if(expr2 != ""){
        if (expr2.find(" := ") != nullptr) {
            currentProcedure->addStatement(getIndent()+expr2+";\n");
            return "";
        }
        cstring retType = inferBoogieType(methodCallStatement->methodCall->type, "");
        if (retType != "") {
            cstring sink = getOrCreateUnusedVar(retType);
            currentProcedure->addStatement(getIndent()+sink+" := "+expr2+";\n");
            currentProcedure->addModifiedGlobalVariables(sink);
            return "";
        }

        std::vector<cstring> renderedArgTypes;
        for (auto arg : *methodCallStatement->methodCall->arguments) {
            cstring rendered = translate(arg);
            if (rendered != "") {
                cstring argType = inferBoogieType(arg->expression->type, rendered);
                if (argType == "") {
                    argType = "int";
                }
                renderedArgTypes.push_back(argType);
            }
            if (expr2.find("extract") != nullptr) {
                break;
            }
        }
        cstring method = translate(methodCallStatement->methodCall->method);
        std::string methodStr = method.c_str();
        std::string::size_type paren = methodStr.find('(');
        cstring declName = method;
        if (paren != std::string::npos) {
            declName = methodStr.substr(0, paren);
        }
        if (procedures.find(declName) == procedures.end()) {
            BoogieProcedure extProc = BoogieProcedure(declName);
            cstring decl = "procedure "+declName+"(";
            for (size_t i = 0; i < renderedArgTypes.size(); ++i) {
                if (i != 0) {
                    decl += ", ";
                }
                decl += "arg"+toString(static_cast<int>(i))+":"+renderedArgTypes[i];
            }
            decl += ");\n";
            extProc.addDeclaration(decl);
            addProcedure(extProc);
        }
        currentProcedure->addStatement(getIndent()+"call "+expr2+";\n");
    }
    return "";
}

cstring Translator::translate(const IR::SwitchStatement *switchStatement){
    cstring res = "";
    cstring expr = translate(switchStatement->expression);
    if(switchStatement->expression->type->is<IR::Type_ActionEnum>()){
        /* 
            use goto statements
        */
        if(options.gotoOrIf){
            incSwitchStatementCount();
            cstring switchLabel = "Switch$"+getSwitchStatementCount()+"$";

            cstring tableName;
            std::string s = expr.c_str();
            std::string::size_type idx = s.find(".apply()");
            if(idx != std::string::npos){
                tableName = s.substr(0, idx);
            }
            // get the corresponding table
            const IR::P4Table* p4Table = tables[tableName];

            

            /* 
                - add goto statement
                - local variables
            */
            cstring gotoStmt = getIndent()+"goto ";
            bool firstAction = true;

            // Add local variables (action parameters) declaration
            for(auto property:p4Table->properties->properties){
                if (auto actionList = property->value->to<IR::ActionList>()) {
                    // add local variables
                    for(auto actionElement:actionList->actionList){
                        if(auto actionCallExpr = actionElement->expression->to<IR::MethodCallExpression>()){
                            cstring actionName = translate(actionCallExpr->method);
                            const IR::P4Action* action = actions[actionName];
                            for(auto parameter:action->parameters->parameters){
                                cstring parameter_str = actionName+"."+translate(parameter);
                                if(!currentProcedure->hasLocalVariables(parameter_str)){
                                    currentProcedure->addFrontStatement("    var "+parameter_str+";\n");
                                    currentProcedure->addLocalVariables(parameter_str);
                                }
                            }
                            // goto statement
                            if(!firstAction)
                                gotoStmt += ", ";
                            else
                                firstAction = false;
                            gotoStmt += switchLabel+tableName+"$"+actionName;
                        }
                    }
                }
            }
            // Add goto Statement only if there is at least one action target.
            if (!firstAction) {
                gotoStmt += ";\n";
                currentProcedure->addStatement(gotoStmt);
            }

            /* For default case 
                 Record actions that handled by other cases
                 Other actions are handled by the default case (if exists)
            */
            std::set<cstring> handledActions;
            for(auto switchCase:switchStatement->cases){
                if (!switchCase->label->is<IR::DefaultExpression>()){
                    // get the corresponding action
                    cstring actionName = translate(switchCase->label);
                    handledActions.insert(actionName);
                }
            }        

            int caseCnt = -1;
            for(auto switchCase:switchStatement->cases){
                caseCnt += 1;
                /*
                    Add parameters
                    Add table entry & exit
                    Add action invocation
                    Add table labels
                    case fall Through
                    without default? (the compiler always adds a default case)
                */

                // Fall Through
                int fallThrough = caseCnt;
                while(static_cast<size_t>(fallThrough) < switchStatement->cases.size() &&
                    switchStatement->cases[fallThrough]->statement == nullptr){
                    fallThrough++;
                }

                if (switchCase->label->is<IR::DefaultExpression>()){
                    // all alternative actions should be considered
                    for(auto property:p4Table->properties->properties){
                        if (auto actionList = property->value->to<IR::ActionList>()) {
                            for(auto actionElement:actionList->actionList){
                                if(auto actionCallExpr = actionElement->expression->to<IR::MethodCallExpression>()){
                                    cstring actionName = translate(actionCallExpr->method);
                                    if(handledActions.find(actionName)==handledActions.end()){
                                        const IR::P4Action* action = actions[actionName];

                                        // Add label for actions
                                        currentProcedure->addStatement("\n"+getIndent()+switchLabel
                                            +tableName+"$"+actionName+":\n");

                                        incIndent();

                                        // Table entry
                                        // currentProcedure->addStatement(getIndent()+"call "+tableName+".apply_table_entry();\n");
                                        // Specify action_run
                                        currentProcedure->addStatement(getIndent()+"assume "+tableName+
                                            ".action_run == "+tableName+".action."+actionName+";\n");
                                        // currentProcedure->addStatement(getIndent()+tableName+
                                        //     ".action_run := "+tableName+".action."+actionName+";\n");
                                        currentProcedure->addModifiedGlobalVariables(tableName+".action_run");
                                        // Add Parameters
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

                                        cstring actionCall = getIndent()+"call ";
                                        if (!outVars.empty()) {
                                            for (size_t i = 0; i < outVars.size(); ++i) {
                                                if (i != 0) {
                                                    actionCall += ", ";
                                                }
                                                actionCall += outVars[i];
                                            }
                                            actionCall += " := ";
                                        }
                                        actionCall += actionName+"(";
                                        currentProcedure->addSucc(actionName);
                                        addPred(actionName, currentProcedure->getName());
                                        for (size_t i = 0; i < inVars.size(); ++i) {
                                            if (i != 0) {
                                                actionCall += ", ";
                                            }
                                            actionCall += inVars[i];
                                        }
                                        actionCall += ");\n";

                                        currentProcedure->addStatement(actionCall);
                                        // Table exit
                                        // currentProcedure->addStatement(getIndent()+"call "+tableName+".apply_table_exit();\n");
                                        if(static_cast<size_t>(fallThrough) < switchStatement->cases.size())
                                            translate(switchStatement->cases[fallThrough]->statement);
                                        currentProcedure->addStatement(getIndent()+"goto "+switchLabel
                                            +tableName+"$Continue;\n");
                                        decIndent();
                                    }
                                }
                            }
                        }
                    }
                }
                else{
                    cstring actionName = translate(switchCase->label);
                    const IR::P4Action* action = actions[actionName];

                    // Add label for actions
                    currentProcedure->addStatement("\n"+getIndent()+switchLabel
                        +tableName+"$"+actionName+":\n");

                    incIndent();

                    // Table entry
                    // currentProcedure->addStatement(getIndent()+"call "+tableName+".apply_table_entry();\n");
                    // Specify action_run
                    currentProcedure->addStatement(getIndent()+"assume "+tableName+
                                            ".action_run == "+".action."+actionName+";\n");
                    currentProcedure->addModifiedGlobalVariables(tableName+".action_run");

                    // Add Parameters
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

                    cstring actionCall = getIndent()+"call ";
                    if (!outVars.empty()) {
                        for (size_t i = 0; i < outVars.size(); ++i) {
                            if (i != 0) {
                                actionCall += ", ";
                            }
                            actionCall += outVars[i];
                        }
                        actionCall += " := ";
                    }
                    actionCall += actionName+"(";
                    currentProcedure->addSucc(actionName);
                    addPred(actionName, currentProcedure->getName());
                    for (size_t i = 0; i < inVars.size(); ++i) {
                        if (i != 0) {
                            actionCall += ", ";
                        }
                        actionCall += inVars[i];
                    }
                    actionCall += ");\n";
                    currentProcedure->addStatement(actionCall);

                    // Table exit
                    // currentProcedure->addStatement(getIndent()+"call "+tableName+".apply_table_exit();\n");
                    
                    
                    if(static_cast<size_t>(fallThrough) < switchStatement->cases.size())
                        translate(switchStatement->cases[fallThrough]->statement);

                    currentProcedure->addStatement(getIndent()+"goto "+switchLabel
                        +tableName+"$Continue;\n");
                    decIndent();
                }
            }

            // Add continue label
            currentProcedure->addStatement("\n"+getIndent()+switchLabel
                +tableName+"$Continue:\n");
        }
        else{
            cstring tableName;
            std::string s = expr.c_str();
            std::string::size_type idx = s.find(".apply()");
            if(idx != std::string::npos){
                tableName = s.substr(0, idx);
            }
            currentProcedure->addStatement(getIndent()+"call "+tableName+".apply();\n");
            bool firstAction = true;

            bool fallThrough = false;
            int caseCnt = 0;
            for(auto switchCase:switchStatement->cases){
                caseCnt++;
                if (!switchCase->label->is<IR::DefaultExpression>()){
                    // no fall through
                    if(!fallThrough){
                        if(firstAction){
                            currentProcedure->addStatement(getIndent()+"if(");
                            firstAction = false;
                        }
                        else{
                            currentProcedure->addStatement(getIndent()+"else if(");
                        }
                    }
                    else
                        currentProcedure->addStatement(" || ");
                    
                    // get the corresponding action
                    cstring actionName = translate(switchCase->label);
                    currentProcedure->addStatement(tableName+".action_run == "+tableName+".action."+actionName);
                    if(switchCase->statement != nullptr){
                        fallThrough = false;
                        currentProcedure->addStatement("){\n");
                        incIndent();
                        currentProcedure->addStatement(translate(switchCase->statement));
                        decIndent();
                        currentProcedure->addStatement(getIndent()+"}\n");
                    }
                    else{
                        fallThrough = true;
                        if(static_cast<size_t>(caseCnt) == switchStatement->cases.size()){
                            currentProcedure->addStatement("){\n");
                            currentProcedure->addStatement(getIndent()+"}\n");
                        }
                    }
                }
            }
        }
    }

    // Ordinary value switches fall through to the current conditional-chain lowering.
    // P4C's switch-expression sample is the regression anchor for this path.
    currentProcedure->addStatement(res);
    return "";
}

