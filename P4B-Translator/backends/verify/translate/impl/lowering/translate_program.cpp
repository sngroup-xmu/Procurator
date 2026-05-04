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

const IR::Type* specializedTypeArgForRegister(const IR::Type* type, size_t idx) {
    if (type == nullptr) {
        return nullptr;
    }
    if (auto typeSpec = type->to<IR::Type_Specialized>()) {
        if (typeSpec->arguments != nullptr && typeSpec->arguments->size() > idx) {
            return (*typeSpec->arguments)[idx];
        }
    }
    if (auto typeSpec = type->to<IR::Type_SpecializedCanonical>()) {
        if (typeSpec->arguments != nullptr && typeSpec->arguments->size() > idx) {
            return (*typeSpec->arguments)[idx];
        }
    }
    return nullptr;
}

bool constantValueFromExpr(const IR::Expression* expr, big_int* value) {
    if (expr == nullptr || value == nullptr) {
        return false;
    }
    if (auto constant = expr->to<IR::Constant>()) {
        *value = constant->value;
        return true;
    }
    if (auto cast = expr->to<IR::Cast>()) {
        return constantValueFromExpr(cast->expr, value);
    }
    return false;
}

}  // namespace

cstring Translator::renderBoogieZeroLiteral(const cstring& typeName) {
    if (typeName == "bool") {
        return "false";
    }
    if (typeName.startsWith("bv")) {
        return "0" + typeName;
    }
    auto it = typeDefs.find(typeName);
    if (it != typeDefs.end()) {
        return "0bv" + cstring(std::to_string(it->second));
    }
    return "0";
}

cstring Translator::renderBoogieOneLiteral(const cstring& typeName) {
    if (typeName == "bool") {
        return "true";
    }
    if (typeName.startsWith("bv")) {
        return "1" + typeName;
    }
    auto it = typeDefs.find(typeName);
    if (it != typeDefs.end()) {
        return "1bv" + cstring(std::to_string(it->second));
    }
    return "1";
}

void Translator::translate(const IR::P4Program *program){
    analyzeProgram(program);
    const bool debugObjects = std::getenv("P4VERIFY_DEBUG_TRANSLATE_OBJECTS") != nullptr;
    
    for(auto obj:program->objects){
        if (debugObjects) {
            std::cerr << "[p4verify-obj] " << obj->node_type_name()
                      << " " << obj << std::endl;
        }
        translate(obj);
    }
    addFunction("sub", "bvsub", "bv17", "bv17");
    addFunction("sub", "bvsub", "bv33", "bv33");
    if(options.addForwardingAssertion){
        mainProcedure.addStatement("    assert(forward || drop);\n");
    }
}

void Translator::translate(const IR::Type_Error *typeError){
    (void)typeError;
}

void Translator::translate(const IR::Type_Extern *typeExtern){
    (void)typeExtern;
}

void Translator::translate(const IR::Type_Enum *typeEnum){
    (void)typeEnum;
}

void Translator::translate(const IR::Declaration_Instance *instance, cstring instanceName){
    cstring typeName = translate(instance->type);
    cstring name = translate(instance->getName());

    if(instanceName != "") name = instanceName;
    recordHashExtern(instance, name);
    recordRandomExtern(instance, name);
    recordCounterExtern(instance, name);

    if (std::getenv("P4VERIFY_DEBUG_TRANSLATE_INSTANCES") != nullptr) {
        std::cerr << "[p4verify-instance] " << typeName << " " << name << std::endl;
        std::cerr << "[p4verify-instance] " << instance->toString() << std::endl;
    }

    if(typeName == "Pipeline"){
        BoogieProcedure pipe = BoogieProcedure(name);
        pipe.addDeclaration("procedure {:inline 1} "+name+"()\n");
        incIndent();

        for(auto argument:*instance->arguments){
            cstring procName = translate(argument->expression);
            pipe.addStatement(getIndent()+"call "+procName+"();\n");
            pipe.addSucc(procName);
            addPred(procName, name);
        }

        decIndent();
        addProcedure(pipe);
    }

    if(typeName == "Switch"){
        BoogieProcedure main = BoogieProcedure(name);
        main.addDeclaration("procedure {:inline 1} "+name+"()\n");
        incIndent();

        if(options.whileLoop) {
            main.addStatement(getIndent()+"call havocProcedure();\n");
            main.addSucc(havocProcedure.getName());
            addPred(havocProcedure.getName(), name);
        }

        for(auto argument:*instance->arguments){
            cstring procName = translate(argument->expression);
            main.addStatement(getIndent()+"call "+procName+"();\n");
            main.addSucc(procName);
            addPred(procName, name);
        }

        main.addStatement(getIndent()+"if(forward == false){\n");
        incIndent();
        main.addStatement(getIndent()+"drop := true;\n");
        decIndent();
        main.addStatement(getIndent()+"}\n");

        decIndent();
        addProcedure(main);

        if(options.whileLoop){
            mainProcedure.addStatement("    while(true){\n");
            mainProcedure.addStatement("        call "+name+"();\n");
            mainProcedure.addStatement("    }\n");
        }
        else
            mainProcedure.addStatement("    call "+name+"();\n");
        mainProcedure.addSucc(name);
        addPred(name, mainProcedure.getName());
    }

    if (counterExterns.find(name) != counterExterns.end()) {
        const CounterExternInfo &info = counterExterns[name];
        if (emittedVarDecls.find(name) != emittedVarDecls.end()) {
            return;
        }
        addDeclaration("\n// Counter "+name+"\n");
        addDeclaration("var "+name+"__counter:["+info.indexType+"]"+info.valueType+";\n");
        addDeclaration("var "+name+"__last_index:"+info.indexType+";\n");
        addDeclaration("var "+name+"__last_value:"+info.valueType+";\n");
        addDeclaration("var "+name+"__wrote_any:bool;\n");
        addDeclaration("var "+name+"__wrote_index0:bool;\n");
        addDeclaration("var "+name+"__last0_value:"+info.valueType+";\n");
        addGlobalVariables(name+"__counter");
        addGlobalVariables(name+"__last_index");
        addGlobalVariables(name+"__last_value");
        addGlobalVariables(name+"__wrote_any");
        addGlobalVariables(name+"__wrote_index0");
        addGlobalVariables(name+"__last0_value");
        emittedVarDecls.insert(name);

        cstring zeroIndex = renderBoogieZeroLiteral(info.indexType);
        cstring oneValue = renderBoogieOneLiteral(info.valueType);
        addFunction("add", "bvadd", info.valueType, info.valueType);

        BoogieProcedure count = BoogieProcedure(name+".count");
        count.addDeclaration("procedure {:inline 1} "+name+".count(index:"+info.indexType+")\n");
        incIndent();
        count.addStatement(getIndent()+"call "+name+".add(index, "+oneValue+");\n");
        decIndent();
        count.addModifiedGlobalVariables(name+"__counter");
        count.addModifiedGlobalVariables(name+"__last_index");
        count.addModifiedGlobalVariables(name+"__last_value");
        count.addModifiedGlobalVariables(name+"__wrote_any");
        count.addModifiedGlobalVariables(name+"__wrote_index0");
        count.addModifiedGlobalVariables(name+"__last0_value");
        addProcedure(count);

        BoogieProcedure increment = BoogieProcedure(name+".increment");
        increment.addDeclaration("procedure {:inline 1} "+name+".increment(index:"+info.indexType+")\n");
        incIndent();
        increment.addStatement(getIndent()+"call "+name+".add(index, "+oneValue+");\n");
        decIndent();
        increment.addModifiedGlobalVariables(name+"__counter");
        increment.addModifiedGlobalVariables(name+"__last_index");
        increment.addModifiedGlobalVariables(name+"__last_value");
        increment.addModifiedGlobalVariables(name+"__wrote_any");
        increment.addModifiedGlobalVariables(name+"__wrote_index0");
        increment.addModifiedGlobalVariables(name+"__last0_value");
        addProcedure(increment);

        BoogieProcedure add = BoogieProcedure(name+".add");
        add.addDeclaration("procedure {:inline 1} "+name+".add(index:"+info.indexType+", value:"+info.valueType+")\n");
        incIndent();
        cstring rhs;
        if (info.valueType.startsWith("bv")) {
            rhs = "add."+info.valueType+"("+name+"__counter[index], value)";
        } else {
            rhs = name+"__counter[index] + value";
        }
        add.addStatement(getIndent()+name+"__counter[index] := "+rhs+";\n");
        add.addStatement(getIndent()+name+"__last_index := index;\n");
        add.addStatement(getIndent()+name+"__last_value := "+name+"__counter[index];\n");
        add.addStatement(getIndent()+name+"__wrote_any := true;\n");
        add.addStatement(getIndent()+"if (index == "+zeroIndex+") {\n");
        incIndent();
        add.addStatement(getIndent()+name+"__wrote_index0 := true;\n");
        add.addStatement(getIndent()+name+"__last0_value := "+name+"__counter[index];\n");
        decIndent();
        add.addStatement(getIndent()+"}\n");
        decIndent();
        add.addModifiedGlobalVariables(name+"__counter");
        add.addModifiedGlobalVariables(name+"__last_index");
        add.addModifiedGlobalVariables(name+"__last_value");
        add.addModifiedGlobalVariables(name+"__wrote_any");
        add.addModifiedGlobalVariables(name+"__wrote_index0");
        add.addModifiedGlobalVariables(name+"__last0_value");
        addProcedure(add);
    }

    if (meterExterns.find(name) != meterExterns.end()) {
        const MeterExternInfo &info = meterExterns[name];
        if (emittedVarDecls.find(name) != emittedVarDecls.end()) {
            return;
        }
        addDeclaration("\n// Meter "+name+"\n");
        addDeclaration("var "+name+"__meter:["+info.indexType+"]"+info.colorType+";\n");
        addDeclaration("var "+name+"__last_index:"+info.indexType+";\n");
        addDeclaration("var "+name+"__last_color:"+info.colorType+";\n");
        addDeclaration("var "+name+"__executed_any:bool;\n");
        addDeclaration("var "+name+"__executed_index0:bool;\n");
        addDeclaration("var "+name+"__last0_color:"+info.colorType+";\n");
        addGlobalVariables(name+"__meter");
        addGlobalVariables(name+"__last_index");
        addGlobalVariables(name+"__last_color");
        addGlobalVariables(name+"__executed_any");
        addGlobalVariables(name+"__executed_index0");
        addGlobalVariables(name+"__last0_color");
        emittedVarDecls.insert(name);

        cstring zeroIndex = renderBoogieZeroLiteral(info.indexType);
        BoogieProcedure execute = BoogieProcedure(name+".execute");
        execute.addDeclaration("procedure {:inline 1} "+name+".execute(index:"+info.indexType+") returns (color:"+info.colorType+")\n");
        incIndent();
        execute.addStatement(getIndent()+"havoc color;\n");
        execute.addStatement(getIndent()+name+"__meter[index] := color;\n");
        execute.addStatement(getIndent()+name+"__last_index := index;\n");
        execute.addStatement(getIndent()+name+"__last_color := color;\n");
        execute.addStatement(getIndent()+name+"__executed_any := true;\n");
        execute.addStatement(getIndent()+"if (index == "+zeroIndex+") {\n");
        incIndent();
        execute.addStatement(getIndent()+name+"__executed_index0 := true;\n");
        execute.addStatement(getIndent()+name+"__last0_color := color;\n");
        decIndent();
        execute.addStatement(getIndent()+"}\n");
        decIndent();
        execute.addModifiedGlobalVariables(name+"__meter");
        execute.addModifiedGlobalVariables(name+"__last_index");
        execute.addModifiedGlobalVariables(name+"__last_color");
        execute.addModifiedGlobalVariables(name+"__executed_any");
        execute.addModifiedGlobalVariables(name+"__executed_index0");
        execute.addModifiedGlobalVariables(name+"__last0_color");
        addProcedure(execute);

        BoogieProcedure executeColored = BoogieProcedure(name+".execute_colored");
        executeColored.addDeclaration("procedure {:inline 1} "+name+".execute_colored(index:"+info.indexType+
                                      ", prior:"+info.colorType+") returns (color:"+info.colorType+")\n");
        incIndent();
        executeColored.addStatement(getIndent()+"call color := "+name+".execute(index);\n");
        decIndent();
        executeColored.addModifiedGlobalVariables(name+"__meter");
        executeColored.addModifiedGlobalVariables(name+"__last_index");
        executeColored.addModifiedGlobalVariables(name+"__last_color");
        executeColored.addModifiedGlobalVariables(name+"__executed_any");
        executeColored.addModifiedGlobalVariables(name+"__executed_index0");
        executeColored.addModifiedGlobalVariables(name+"__last0_color");
        addProcedure(executeColored);
    }

    if(typeName=="V1Switch" || typeName=="PNA_NIC"){
        BoogieProcedure main = BoogieProcedure(name);
        main.addDeclaration("procedure {:inline 1} "+name+"()\n");
        incIndent();

        if(options.whileLoop) {
            main.addStatement(getIndent()+"call havocProcedure();\n");
            main.addSucc(havocProcedure.getName());
            addPred(havocProcedure.getName(), name);
        }

        int argumentCount = instance->arguments->size();
        int argumentIndex = 0;
        for(auto argument:*instance->arguments){
            argumentIndex++;
            cstring procName = translate(argument->expression);
            if (typeName == "V1Switch" && argumentIndex == argumentCount) {
                deparser = procName;
                continue;
            }
            if(options.ultimateAutomizer){
                if(argument->expression->type->is<IR::Type_Parser>()){
                    procName = "_parser_"+procName;
                }
            }
            main.addStatement(getIndent()+"call "+procName+"();\n");
            main.addSucc(procName);
            addPred(procName, name);
        }
        main.addStatement(getIndent()+"if(forward == false){\n");
        incIndent();
        main.addStatement(getIndent()+"drop := true;\n");
        decIndent();
        main.addStatement(getIndent()+"}\n");

        decIndent();

        // add children
        addProcedure(main);
        if(options.whileLoop){
            mainProcedure.addStatement("    while(true){\n");
            mainProcedure.addStatement("        call "+name+"();\n");
            mainProcedure.addStatement("    }\n");
        }
        else
            mainProcedure.addStatement("    call "+name+"();\n");
        mainProcedure.addSucc(name);
        addPred(name, mainProcedure.getName());
    }

    if(typeName=="register" || typeName=="Register"){
        if (emittedVarDecls.find(name) != emittedVarDecls.end()) {
            return;
        }
        if (options.slicingEnabled && !options.slicingKeepVars.empty() &&
            !shouldKeepVar(name.c_str())) {
            return;
        }
        const bool debugRegisterLowering = std::getenv("P4VERIFY_DEBUG_REGISTER_LOWERING") != nullptr;
        auto regDebug = [&](const char* msg) {
            if (debugRegisterLowering) {
                std::cerr << "[p4verify-reg] " << name << ": " << msg << std::endl;
            }
        };
        regDebug("begin");

        // size
        big_int registerSize = 0;
        if (instance->arguments == nullptr || instance->arguments->empty() ||
            !constantValueFromExpr((*instance->arguments)[0]->expression, &registerSize)) {
            std::cerr << "[p4verify] unsupported register size expression for "
                      << name << ": " << instance << std::endl;
            return;
        }
        cstring size = toString(registerSize);
        int effectiveSize = -1;
        if (registerSize >= 0 && registerSize <= std::numeric_limits<int>::max()) {
            effectiveSize = static_cast<int>(registerSize);
        }
        regDebug("size");

        // value type
        const IR::Type* registerValueType = specializedTypeArgForRegister(instance->type, 0);
        if (registerValueType == nullptr) {
            std::cerr << "[p4verify] unsupported register value type for "
                      << name << ": " << instance->type << std::endl;
            return;
        }
        cstring valueTypeName = translate(registerValueType);

        if(options.ultimateAutomizer && registerValueType->to<IR::Type_Bits>()){
            valueTypeName = "int";
        }
        regDebug("value type");

        // index type
        cstring sizeTypeName;
        if(const IR::Type* registerIndexType = specializedTypeArgForRegister(instance->type, 1)){
            sizeTypeName = translate(registerIndexType);
        } else {
            sizeTypeName = options.ultimateAutomizer ? "int" : kDefaultBv32Type;
        }
        if(options.ultimateAutomizer){
            sizeTypeName = "int";
        }
        regDebug("index type");

        if (!options.loadIRFromJson &&
            options.slicingEnabled && options.slicingRegPrune &&
            !options.slicingRegMaxIndex.empty() &&
            !options.slicingKeepVars.empty() &&
            shouldKeepVar(name.c_str())) {
            auto it = options.slicingRegMaxIndex.find(name);
            if (it == options.slicingRegMaxIndex.end()) {
                std::string withSuffix = name.c_str();
                withSuffix += "_0";
                it = options.slicingRegMaxIndex.find(cstring(withSuffix.c_str()));
            }
            std::string nameStr = name.c_str();
            bool hasNonConst = options.slicingRegHasNonConst.count(name) > 0 ||
                options.slicingRegHasNonConst.count(cstring((nameStr + "_0").c_str())) > 0;
            if (it != options.slicingRegMaxIndex.end() && !hasNonConst) {
                int originalSize = -1;
                if (registerSize >= 0 && registerSize <= std::numeric_limits<int>::max()) {
                    originalSize = static_cast<int>(registerSize);
                }
                int maxIndex = it->second;
                if (originalSize > 0 && maxIndex >= 0 && maxIndex + 1 < originalSize) {
                    size = toString(maxIndex + 1);
                    effectiveSize = maxIndex + 1;
                }
            }
        }
        regDebug("prune");

        addDeclaration("\n// Register "+name+"\n");
        addDeclaration("var "+name+":["+sizeTypeName+"]"+valueTypeName+";\n");
        regDebug("var decl");
        if (effectiveSize >= 0) {
            registerDomainSizes[name] = effectiveSize;
        }
        addDeclaration("var "+name+"__last_index:"+sizeTypeName+";\n");
        addDeclaration("var "+name+"__last_value:"+valueTypeName+";\n");
        addDeclaration("var "+name+"__wrote_any:bool;\n");
        addDeclaration("var "+name+"__wrote_index0:bool;\n");
        addDeclaration("var "+name+"__last0_value:"+valueTypeName+";\n");
        regDebug("mirror decls");

        cstring sizeConstType = sizeTypeName;
        int sizeWidth = -1;
        if (sizeTypeName.startsWith("bv")) {
            std::string s = sizeTypeName.c_str();
            std::stringstream ss(s.substr(2));
            ss >> sizeWidth;
        } else {
            auto itSz = typeDefs.find(sizeTypeName);
            if (itSz != typeDefs.end()) {
                sizeWidth = itSz->second;
            }
        }
        if (sizeTypeName != "int" && sizeWidth > 0) {
            big_int maxVal = (big_int(1) << sizeWidth) - 1;
            if (registerSize > maxVal) {
                sizeConstType = "int";
            }
        }

        addDeclaration("const "+name+".size:"+sizeConstType+";\n");
        if (sizeConstType == "int") {
            addDeclaration("axiom "+name+".size == "+size+";\n");
        } else {
            cstring litSuffix = sizeConstType;
            auto itSz = typeDefs.find(sizeConstType);
            if (itSz != typeDefs.end()) {
                litSuffix = "bv" + toString(itSz->second);
            }
            addDeclaration("axiom "+name+".size == "+size+litSuffix+";\n");
        }
        regDebug("size const");
        
        addGlobalVariables(name);
        addGlobalVariables(name+"__last_index");
        addGlobalVariables(name+"__last_value");
        addGlobalVariables(name+"__wrote_any");
        addGlobalVariables(name+"__wrote_index0");
        addGlobalVariables(name+"__last0_value");
        regDebug("globals");

        /* read and write functions 
           may be related to renaming
        */
        // read function
        BoogieProcedure read = BoogieProcedure(name+".read");
        // one parameter, return reg[index]
        read.addDeclaration("function {:inline true}"+read.getName()+"(reg:["+sizeTypeName+"]"+valueTypeName
            +", index:"+sizeTypeName+")"+"returns ("+valueTypeName+") {reg[index]}\n");
        addProcedure(read);
        regDebug("read proc");

        // write function
        BoogieProcedure write = BoogieProcedure(name+".write");
        // two parameters, reg[index] := value
        write.addDeclaration("procedure {:inline 1} "+write.getName()+"(index:"+sizeTypeName+", value:"
            +valueTypeName+")\n");
        cstring indexZero = renderBoogieZeroLiteral(sizeTypeName);
        incIndent();
        write.addStatement(getIndent()+name+"[index] := value;\n");
        write.addStatement(getIndent()+name+"__last_index := index;\n");
        write.addStatement(getIndent()+name+"__last_value := value;\n");
        write.addStatement(getIndent()+name+"__wrote_any := true;\n");
        for (const auto& ff : options.fail_fast_register_asserts) {
            if (ff.reg_boogie == name && ff.mode == "any") {
                std::string ffConstant = ff.constant.c_str();
                if (valueTypeName.startsWith("bv") &&
                    ffConstant.find("bv") == std::string::npos) {
                    ffConstant += valueTypeName.c_str();
                }
                std::string bad = name+"__wrote_any && "+name+"__last_value == "+ffConstant;
                write.addStatement(getIndent()+"if ("+bad+") {\n");
                incIndent();
                write.addStatement(getIndent()+"assert false;\n");
                write.addStatement(getIndent()+"assume false;\n");
                decIndent();
                write.addStatement(getIndent()+"}\n");
            }
        }
        write.addStatement(getIndent()+"if (index == "+indexZero+") {\n");
        incIndent();
        write.addStatement(getIndent()+name+"__wrote_index0 := true;\n");
        write.addStatement(getIndent()+name+"__last0_value := value;\n");
        for (const auto& ff : options.fail_fast_register_asserts) {
            if (ff.reg_boogie == name && ff.mode == "slot0") {
                std::string ffConstant = ff.constant.c_str();
                if (valueTypeName.startsWith("bv") &&
                    ffConstant.find("bv") == std::string::npos) {
                    ffConstant += valueTypeName.c_str();
                }
                std::string bad = name+"__wrote_index0 && "+name+"__last0_value == "+ffConstant;
                write.addStatement(getIndent()+"if ("+bad+") {\n");
                incIndent();
                write.addStatement(getIndent()+"assert false;\n");
                write.addStatement(getIndent()+"assume false;\n");
                decIndent();
                write.addStatement(getIndent()+"}\n");
            }
        }
        decIndent();
        write.addStatement(getIndent()+"}\n");
        decIndent();
        write.addModifiedGlobalVariables(name);
        write.addModifiedGlobalVariables(name+"__last_index");
        write.addModifiedGlobalVariables(name+"__last_value");
        write.addModifiedGlobalVariables(name+"__wrote_any");
        write.addModifiedGlobalVariables(name+"__wrote_index0");
        write.addModifiedGlobalVariables(name+"__last0_value");
        addProcedure(write);
        regDebug("write proc");
    }

    std::string typeNameStr = typeName.c_str();
    if (typeNameStr.find("RegisterAction") != std::string::npos ||
        typeNameStr.find("DirectRegisterAction") != std::string::npos) {
        const bool isDirect = (typeNameStr.find("DirectRegisterAction") != std::string::npos);
        RegisterActionInfo info;
        info.direct = isDirect;
        if (!instance->arguments->empty()) {
            info.regName = translate((*instance->arguments)[0]);
        }
        if (auto typeSpec = instance->type->to<IR::Type_Specialized>()) {
            if (typeSpec->arguments->size() >= 1) {
                info.valueType = translate((*typeSpec->arguments)[0]);
            }
            if (typeSpec->arguments->size() >= 2) {
                info.indexType = translate((*typeSpec->arguments)[1]);
            }
            if (typeSpec->arguments->size() >= 3) {
                info.retType = translate((*typeSpec->arguments)[2]);
            }
        }
        if (info.valueType == "") {
            info.valueType = kDefaultBv32Type;
        }
        if (info.indexType == "") {
            info.indexType = kDefaultBv32Type;
        }
        if (info.retType == "") {
            info.retType = info.valueType;
        }

        cstring applyName = name + ".apply";
        const IR::Function* applyFunc = findRegisterActionApply(instance);
        if (applyFunc != nullptr) {
            translateRegisterActionApply(applyFunc, applyName);
            info.applyName = applyName;
            info.applyParamCount = applyFunc->type->parameters->parameters.size();
            if (applyFunc->type->returnType != nullptr &&
                !applyFunc->type->returnType->is<IR::Type_Void>() &&
                info.applyParamCount <= 1) {
                info.hasReturn = true;
                info.retType = translate(applyFunc->type->returnType);
            } else if (info.applyParamCount >= 2) {
                auto param1 = applyFunc->type->parameters->parameters.at(1);
                info.retType = translate(param1->type);
            } else {
                info.retType = info.valueType;
            }
            registerActions[name] = info;
        }
    }
}

void Translator::translate(const IR::Type_Struct *typeStruct){
    cstring structName = typeStruct->name.toString();
    addDeclaration("\n// Struct "+structName+"\n");
    if(structName=="headers"){
        if(!isGlobalVariable("hdr")){
            addDeclaration("var hdr:Ref;\n");
            addGlobalVariables("hdr");
        }
        for(const IR::StructField* field:typeStruct->fields){
            translate(field, "hdr");
        }
    }
    else if(structName=="metadata"){
        for(const IR::StructField* field:typeStruct->fields){
            translate(field, "meta");
        }
    }
    else if(structName=="standard_metadata_t"){
        for(const IR::StructField* field:typeStruct->fields){
            translate(field, "standard_metadata");
        }
    }
    else{
        ensureStructLayout(typeStruct);
        if (emittedTypeDecls.find(structName) == emittedTypeDecls.end()) {
            auto it = structBitwidths.find(structName);
            if (it != structBitwidths.end()) {
                if (typeDefs.find(structName) == typeDefs.end()) {
                    typeDefs[structName] = it->second;
                    addDeclaration("type "+structName+" = bv"+toString(it->second)+";\n");
                }
            } else {
                // Some structs are used as opaque locals (e.g., temporary metadata structs)
                // without being bit-blasted to a fixed-width bitvector. Emit an uninterpreted
                // Boogie type so the output is well-typed for Ultimate.
                addDeclaration("type "+structName+";\n");
            }
            emittedTypeDecls.insert(structName);
        }
    }
}

void Translator::translate(const IR::Type_Struct *typeStruct, cstring arg){
    if(typeStruct->name.toString()=="headers"){
        if(emittedVarDecls.find(arg) == emittedVarDecls.end()){
            addDeclaration("var "+arg+":Ref;\n");
            addGlobalVariables(arg);
        }
    }
    for(const IR::StructField* field:typeStruct->fields){
        translate(field, arg);
    }
}

void Translator::translate(const IR::StructField *field){
    (void)field;
}

void Translator::translate(const IR::StructField *field, cstring arg){
    if(field->type->node_type_name() == "Type_Name"){
        cstring fieldName = field->type->toString();
        std::map<cstring, const IR::Type_Header*>::iterator iter1 = headers.find(fieldName);
        std::map<cstring, const IR::Type_Struct*>::iterator iter2 = structs.find(fieldName);
        if(iter1!=headers.end()){
            translate(iter1->second, arg+"."+field->name);
        }
        else if(iter2!=structs.end()){
            translate(iter2->second, arg+"."+field->name);
        }
        // else: typeDef
        else{
            auto typeName = field->type->to<IR::Type_Name>();
            cstring name = translate(typeName->path);
            cstring fieldName = arg+"."+field->name;
            if(isGlobalVariable(fieldName)) return;
            addDeclaration("var "+fieldName+":"+name+";\n");
            addGlobalVariables(fieldName);

            if(fieldName.startsWith("standard_metadata.")){
                std::set<cstring> havocSet = {"ingress_port", "instance_type", "packet_length", 
                                              "enq_timestamp", "deq_timedelta", "deq_qdepth",
                                              "ingress_global_timestamp", "egress_global_timestamp"
                                             };
                if(havocSet.find(field->name) != havocSet.end()){
                    havocProcedure.addStatement("    havoc "+fieldName+";\n");
                    if(typeDefs.find(name) != typeDefs.end()){
                        havocProcedure.addStatement("    assume(0 <= "+fieldName+" && "+
                            fieldName + " < power_2_" +toString(typeDefs[name]) +"() );\n");
                    }
                }
                else{
                    havocProcedure.addStatement("    "+fieldName+" := 0;\n");
                }
                havocProcedure.addModifiedGlobalVariables(fieldName);
            }
        }

    }
    else if(field->type->node_type_name() == "Type_Boolean"){
        cstring fieldName = arg+"."+field->name;
        if(isGlobalVariable(fieldName)) return;
        addDeclaration("var "+fieldName+":bool;\n");
        addGlobalVariables(fieldName);
        updateVariableSize(fieldName, 0);
        if(fieldName.startsWith("meta.") || fieldName.startsWith("standard_metadata.")){
            std::set<cstring> havocSet = {"ingress_port", "instance_type", "packet_length", 
                                          "enq_timestamp", "deq_timedelta", "deq_qdepth",
                                          "ingress_global_timestamp", "egress_global_timestamp"
                                         };
            if(havocSet.find(field->name) != havocSet.end()){
                havocProcedure.addStatement("    havoc "+fieldName+";\n");
            }
            else{
                havocProcedure.addStatement("    "+fieldName+" := false;\n");
            }
            havocProcedure.addModifiedGlobalVariables(fieldName);
        }
    }
    else if(field->type->node_type_name() == "Type_Bits"){
        auto typeBits = field->type->to<IR::Type_Bits>();
        updateMaxBitvectorSize(typeBits);
        cstring fieldName = arg+"."+field->name;
        if(isGlobalVariable(fieldName)) return;
        if(options.bitBlasting){
            bitBlastingTempDecl(fieldName, typeBits->size);
        }
        else if(options.ultimateAutomizer){
            addDeclaration("var "+fieldName+":int;\n");
        }
        else
            addDeclaration("var "+fieldName+":bv"+std::to_string(typeBits->size)+";\n");
        addGlobalVariables(fieldName);
        updateVariableSize(fieldName, typeBits->size);
        if(fieldName.startsWith("meta.") || fieldName.startsWith("standard_metadata.")){
            std::set<cstring> havocSet = {"ingress_port", "instance_type", "packet_length", 
                                          "enq_timestamp", "deq_timedelta", "deq_qdepth",
                                          "ingress_global_timestamp", "egress_global_timestamp"
                                         };
            if(havocSet.find(field->name) != havocSet.end()){
                havocProcedure.addStatement("    havoc "+fieldName+";\n");
                havocProcedure.addStatement("    assume(0 <= "+fieldName+" && "+
                        fieldName + " < power_2_" +toString(typeBits->size) +"() );\n");
            }
            else{
                havocProcedure.addStatement("    "+fieldName+" := 0;\n");
            }
            havocProcedure.addModifiedGlobalVariables(fieldName);
        }
    }
    else if(field->type->node_type_name() == "Type_Varbits"){
        auto typeVarbits = field->type->to<IR::Type_Varbits>();
        cstring fieldName = arg+"."+field->name;
        if(isGlobalVariable(fieldName)) return;
        if(options.bitBlasting){
            bitBlastingTempDecl(fieldName, typeVarbits->size);
        }
        else if(options.ultimateAutomizer){
            addDeclaration("var "+fieldName+":int;\n");
        }
        else
            addDeclaration("var "+fieldName+":bv"+std::to_string(typeVarbits->size)+";\n");
        addGlobalVariables(fieldName);
    }
    else if(P4VerifyCompat::isHeaderStackType(field->type)){
        cstring fieldName = arg+"."+field->name;
        if(isGlobalVariable(fieldName)) return;
        addDeclaration("const "+fieldName+":HeaderStack;\n");
        addGlobalVariables(fieldName);
        if (auto typeStack = P4VerifyCompat::asHeaderStackType(field->type)){
            translate(typeStack, fieldName);
        }
    }
    else if(field->type->node_type_name() == "Type_Typedef"){
        auto typeTypedef = field->type->to<IR::Type_Typedef>();
        cstring fieldName = arg+"."+field->name;
        if(isGlobalVariable(fieldName)) return;
        addDeclaration("var "+fieldName+":"+translate(typeTypedef->name)+";\n");
        addGlobalVariables(fieldName);
    }
}

void Translator::translate(const IR::Type_Header *typeHeader){
    (void)typeHeader;
}

void Translator::translate(const IR::Type_Header *typeHeader, cstring arg){
    if(emittedVarDecls.find(arg) != emittedVarDecls.end()) return;
    addDeclaration("\n// Header "+typeHeader->name.toString()+"\n");
    addDeclaration("var "+arg+":Ref;\n");
    addGlobalVariables(arg);
    addDeclaration("var "+arg+".valid:bool;\n");
    addGlobalVariables(arg+".valid");
    updateVariableSize(arg+".valid", 0);

    havocProcedure.addStatement("    "+arg+".valid := false;\n");
    havocProcedure.addModifiedGlobalVariables(arg+".valid");
    // havocProcedure.addStatement("    isValid["+arg+"] := false;\n");
    // havocProcedure.addModifiedGlobalVariables("isValid");
    if(currentProcedure==nullptr || currentProcedure->getName().find("_parser_") == nullptr){
        havocProcedure.addStatement("    emit["+arg+"] := false;\n");
        havocProcedure.addModifiedGlobalVariables("emit");
    }
    for(const IR::StructField* field:typeHeader->fields){
        translate(field, arg);
        cstring fieldName = arg + "." + field->name;

        cstring oldFieldName = "_old_"+fieldName;
        if(options.p4ltlSpec){
            for(auto item:p4ltlSpec){
                for(auto spec:item.second){
                    std::set<cstring> oldExprs = ltlTranslator->getOldExprs(spec);
                    if(oldExprs.find(fieldName) != oldExprs.end()){
                        translate(field, "_old_"+arg);
                        break;
                    }
                }
            }
        }
        else{
            // translate(field, "_old_"+arg);
        }

        if(options.bitBlasting){
            if(auto typeBits = field->type->to<IR::Type_Bits>()){
                for(int i = 0; i < typeBits->size; i++){
                    havocProcedure.addStatement("    havoc "+connect(fieldName, i)+";\n");
                    havocProcedure.addModifiedGlobalVariables(connect(fieldName, i));
                }
                for(int i = 0; i < typeBits->size; i++){
                    havocProcedure.addStatement("    "+connect(oldFieldName, i)+" := "+
                        connect(fieldName, i) +";\n");
                    havocProcedure.addModifiedGlobalVariables(connect(oldFieldName, i));
                }
            }
        }
        else{
            if(currentProcedure==nullptr || currentProcedure->getName().find("_parser_") == nullptr){
                havocProcedure.addStatement("    havoc "+fieldName+";\n");
                if(auto typeBits = field->type->to<IR::Type_Bits>()){
                    havocProcedure.addStatement("    assume(0 <= "+fieldName+" && "+
                        fieldName + " < power_2_" +toString(typeBits->size) +"() );\n");
                }
                havocProcedure.addModifiedGlobalVariables(fieldName);
            }

            if(options.p4ltlSpec){
                for(auto item:p4ltlSpec){
                    for(auto spec:item.second){
                        std::set<cstring> oldExprs = ltlTranslator->getOldExprs(spec);
                        if(oldExprs.find(fieldName) != oldExprs.end()){
                            havocProcedure.addStatement("    "+oldFieldName+" := "+
                               fieldName +";\n");
                            havocProcedure.addModifiedGlobalVariables(oldFieldName);
                            break;
                        }
                    }
                }
            }
            else{
            }
        }
    }
}

void Translator::translate(const IR::Type_Parser *typeParser){
    (void)typeParser;
}

void Translator::translate(const IR::Type_Control *typeControl){
    (void)typeControl;
}

void Translator::translate(const IR::Type_Package *typePackage){
    (void)typePackage;
}

void Translator::translate(const IR::P4Parser *p4Parser){
    cstring parserName = p4Parser->name.toString();
    if(options.ultimateAutomizer){
        parserName = "_parser_" + parserName;
    }
    // Declare apply-parameter header/metadata instances (e.g., hdr_eg) as global fields.
    if (p4Parser->getApplyParameters() != nullptr) {
        for (auto param : p4Parser->getApplyParameters()->parameters) {
            if (auto typeName = param->type->to<IR::Type_Name>()) {
                cstring typeId = translate(typeName->path);
                cstring arg = translate(param->name);
                if (headers.find(typeId) != headers.end()) {
                    translate(headers[typeId], arg);
                } else if (structs.find(typeId) != structs.end()) {
                    translate(structs[typeId], arg);
                }
            }
        }
    }
    BoogieProcedure parser = BoogieProcedure(parserName);
    bool prevInParser = inParser;
    std::set<cstring> prevParserLocalVars = parserLocalVars;
    inParser = true;
    parserLocalVars.clear();
    currentProcedure = &parser;
    parser.addDeclaration("\n// Parser "+parserName+"\n");
    parser.addDeclaration("procedure {:inline 1} "+parserName+"()\n");
    incIndent();
    for(auto parserLocal:p4Parser->parserLocals){
        parser.addStatement(translate(parserLocal));
        if (auto declVar = parserLocal->to<IR::Declaration_Variable>()) {
            cstring name = translate(declVar->name);
            if (emittedVarDecls.find(name) == emittedVarDecls.end()) {
                const IR::Type *type = declVar->type;
                if (auto typeBits = type->to<IR::Type_Bits>()) {
                    if (options.ultimateAutomizer) {
                        addDeclaration("var "+name+":int;\n");
                    } else {
                        addDeclaration("var "+name+":"+translate(type)+";\n");
                    }
                    updateVariableSize(name, typeBits->size);
                    updateMaxBitvectorSize(typeBits);
                } else if (type->is<IR::Type_Boolean>()) {
                    addDeclaration("var "+name+":bool;\n");
                    updateVariableSize(name, 0);
                } else if (auto typeName = type->to<IR::Type_Name>()) {
                    cstring typeId = translate(typeName->path);
                    auto hit = headers.find(typeId);
                    if (hit != headers.end()) {
                        translate(hit->second, name);
                    } else {
                        auto sit = structs.find(typeId);
                        if (sit != structs.end()) {
                            translate(sit->second, name);
                        } else {
                            cstring typeStr = translate(type);
                            if (typeStr == "") {
                                addDeclaration("var "+name+":Ref;\n");
                            } else {
                                addDeclaration("var "+name+":"+typeStr+";\n");
                                if (typeDefs.find(typeId) != typeDefs.end()) {
                                    updateVariableSize(name, typeDefs[typeId]);
                                }
                            }
                        }
                    }
                } else if (type->is<IR::Type_Extern>() || type->is<IR::Type_Parser>()
                           || type->is<IR::Type_Control>() || type->is<IR::Type_Package>()) {
                    addDeclaration("var "+name+":Ref;\n");
                } else {
                    cstring typeStr = translate(type);
                    if (typeStr == "") {
                        addDeclaration("var "+name+":Ref;\n");
                    } else {
                        addDeclaration("var "+name+":"+typeStr+";\n");
                    }
                }
                addGlobalVariables(name);
            }
            parserLocalVars.insert(name);
            parser.addModifiedGlobalVariables(name);
        }
    }

    if(options.gotoOrIf){
        computeParserStateLabels(p4Parser);
        parser.addStatement(getIndent()+"goto State$"+parserName+"$start;\n");
        for(auto state:p4Parser->states){
            translate(state, parserName);
        }

        parser.addStatement("\n"+getIndent()+"State$accept:\n");
        parser.addStatement(getIndent()+"call accept();\n");
        parser.addStatement(getIndent()+"goto Exit;\n");

        parser.addStatement("\n"+getIndent()+"State$reject:\n");
        parser.addStatement(getIndent()+"call reject();\n");
        parser.addStatement(getIndent()+"goto Exit;\n");
        addPred("reject", parserName);
        parser.addSucc("reject");

        parser.addStatement("\n"+getIndent()+"Exit:\n");

        decIndent();
        addProcedure(parser);
    }
    else{
        cstring startState = parserName+"$start";
        parser.addStatement("    call "+startState+"();\n");
        parser.addSucc(startState);
        addPred(startState, parserName);

        // add accept & reject
        BoogieProcedure accept = BoogieProcedure(parserName+"$"+"accept");
        accept.addDeclaration("procedure {:inline 1} "+accept.getName()+"()\n");
        accept.setImplemented();
        addProcedure(accept);

        BoogieProcedure reject = BoogieProcedure(parserName+"$"+"reject");
        reject.addDeclaration("procedure  "+reject.getName()+"();\n");
        reject.addDeclaration("    ensures drop==true;\n");
        reject.addModifiedGlobalVariables("drop");
        addProcedure(reject);

        parser.addSucc(accept.getName());
        addPred(accept.getName(), parserName);

        parser.addSucc(reject.getName());
        addPred(reject.getName(), parserName);
        
        decIndent();
        addProcedure(parser);
        for(auto state:p4Parser->states){
            translate(state, parserName);
        }
    }
    parserLocalVars = prevParserLocalVars;
    inParser = prevInParser;
}

void Translator::computeParserStateLabels(const IR::P4Parser* p4Parser) {
    parserStateLabels.clear();
    parserStateLabelsUsed.clear();

    if (!options.gotoOrIf || p4Parser == nullptr) {
        return;
    }

    auto stripNumericSuffix = [](const std::string& value) -> std::string {
        const size_t pos = value.rfind('_');
        if (pos == std::string::npos || pos + 1 >= value.size()) {
            return value;
        }
        for (size_t i = pos + 1; i < value.size(); ++i) {
            if (value[i] < '0' || value[i] > '9') {
                return value;
            }
        }
        return value.substr(0, pos);
    };

    std::unordered_map<std::string, std::vector<const IR::ParserState*>> occurrences;
    for (auto st : p4Parser->states) {
        if (st == nullptr) {
            continue;
        }
        occurrences[st->name.toString().c_str()].push_back(st);
    }

    std::unordered_set<std::string> referenced;
    // The generated parser procedure always begins at the unqualified `start` state.
    referenced.insert("start");

    // Collect state names referenced by transitions/selects. We intentionally avoid calling
    // Translator::translate(expr) here to prevent side effects (e.g., emitting var decls).
    for (auto st : p4Parser->states) {
        if (st == nullptr || st->selectExpression == nullptr) {
            continue;
        }
        if (auto pe = st->selectExpression->to<IR::PathExpression>()) {
            if (pe->path != nullptr) {
                referenced.insert(translate(pe->path).c_str());
            }
        } else if (auto se = st->selectExpression->to<IR::SelectExpression>()) {
            for (auto sc : se->selectCases) {
                if (sc == nullptr || sc->state == nullptr) {
                    continue;
                }
                if (auto spe = sc->state->to<IR::PathExpression>()) {
                    if (spe->path != nullptr) {
                        referenced.insert(translate(spe->path).c_str());
                    }
                }
            }
        }
    }

    for (const auto& kv : occurrences) {
        const std::string& base = kv.first;
        const std::vector<const IR::ParserState*>& states = kv.second;

        const bool refUnqualified = referenced.find(base) != referenced.end();

        std::vector<std::string> qualifiedRefs;
        const std::string suffix = "_" + base;
        for (const auto& r : referenced) {
            if (r == base) {
                continue;
            }
            const std::string normalized = stripNumericSuffix(r);
            if (normalized == base ||
                (r.size() >= suffix.size()
                 && r.compare(r.size() - suffix.size(), suffix.size(), suffix) == 0) ||
                (normalized.size() >= suffix.size()
                 && normalized.compare(normalized.size() - suffix.size(), suffix.size(), suffix) == 0)) {
                qualifiedRefs.push_back(r);
            }
        }
        std::sort(qualifiedRefs.begin(), qualifiedRefs.end());

        std::vector<std::string> desired;
        if (refUnqualified) {
            desired.push_back(base);
        }
        for (const auto& q : qualifiedRefs) {
            desired.push_back(q);
        }
        if (desired.empty()) {
            desired.push_back(base);
        }

        for (size_t i = 0; i < states.size(); i++) {
            std::string label = (i < desired.size())
                                    ? desired[i]
                                    : base + "__p4b_" + std::to_string(i);
            cstring outLabel = label.c_str();
            cstring unique = outLabel;
            int dedup = 0;
            while (parserStateLabelsUsed.find(unique) != parserStateLabelsUsed.end()) {
                unique = outLabel + "__dup" + std::to_string(dedup++);
            }
            parserStateLabels[states[i]] = unique;
            parserStateLabelsUsed.insert(unique);
        }
    }
}

cstring Translator::parserTransitionLabel(const IR::PathExpression* pathExpression, cstring parserName) {
    if (pathExpression == nullptr) {
        return "";
    }
    cstring nextState = translate(pathExpression->path);
    if (refMap && pathExpression->path) {
        if (auto decl = refMap->getDeclaration(pathExpression->path, false)) {
            if (auto parserState = decl->to<IR::ParserState>()) {
                auto it = parserStateLabels.find(parserState);
                if (it != parserStateLabels.end()) {
                    nextState = it->second;
                } else {
                    nextState = translate(parserState->name);
                }
            }
        }
    }
    return (nextState == "accept" || nextState == "reject")
               ? ("State$" + nextState)
               : ("State$" + parserName + "$" + nextState);
}

void Translator::translate(const IR::ParserState *parserState, cstring parserName, cstring localDeclArg){
    if(options.gotoOrIf){
        cstring rawStateName = parserState->name.toString();
        if (rawStateName == "accept" || rawStateName == "reject") {
            return;
        }

        cstring shortStateName = rawStateName;
        auto it = parserStateLabels.find(parserState);
        if (it != parserStateLabels.end()) {
            shortStateName = it->second;
        }

        cstring stateName = parserName + "$" + shortStateName;
        cstring stateLabel = getIndent(); stateLabel += "    State$"; stateLabel += stateName;
        currentProcedure->addStatement("\n"+stateLabel+":\n");
        for(auto statOrDecl:parserState->components){
            currentProcedure->addStatement(translate(statOrDecl));
        }
        if(parserState->selectExpression!=nullptr){
            if (auto pathExpression = parserState->selectExpression->to<IR::PathExpression>()){
                cstring nextStateLabel = parserTransitionLabel(pathExpression, parserName);
                currentProcedure->addStatement(getIndent()+"goto "+nextStateLabel+";\n");
            }
            else if(auto selectExpression = parserState->selectExpression->to<IR::SelectExpression>()){
                currentProcedure->addStatement(translate(selectExpression, parserName, stateName, localDeclArg));
            }
        }
        // Goto-mode parser states are labels inside one procedure; call-graph succ/pred
        // edges are only emitted in procedure-mode parser lowering.
    }
    else{
        cstring stateName = parserState->name.toString();

        if(stateName=="accept" || stateName=="reject")
            return;

        stateName = parserName + "$" +stateName;

        BoogieProcedure state = BoogieProcedure(stateName);
        state.isParserState = true;
        currentProcedure = &state;
        state.addDeclaration("\n//Parser State "+stateName+"\n");
        state.addDeclaration("procedure {:inline 1} "+stateName+"()\n");
        incIndent();
        for(auto statOrDecl:parserState->components){
            currentProcedure->addStatement(translate(statOrDecl));
        }
        if(parserState->selectExpression!=nullptr){
            if (auto pathExpression = parserState->selectExpression->to<IR::PathExpression>()){
                cstring nextState = parserName+"$"+translate(pathExpression);
                state.addStatement(getIndent()+"call "+nextState+"();\n");
                state.addSucc(nextState);
                addPred(nextState, stateName);
            }
            else if(auto selectExpression = parserState->selectExpression->to<IR::SelectExpression>()){
                currentProcedure->addStatement(translate(selectExpression, parserName, stateName, localDeclArg));
            }
        }
        decIndent();
        addProcedure(state);
    }
}

void Translator::translate(const IR::P4Control *p4Control){
    cstring controlName = p4Control->name.toString();
    const bool debugObjects = std::getenv("P4VERIFY_DEBUG_TRANSLATE_OBJECTS") != nullptr;
    // Declare apply-parameter header/metadata instances (e.g., hdr_eg) as global fields.
    if (p4Control->getApplyParameters() != nullptr) {
        for (auto param : p4Control->getApplyParameters()->parameters) {
            if (auto typeName = param->type->to<IR::Type_Name>()) {
                cstring typeId = translate(typeName->path);
                cstring arg = translate(param->name);
                if (headers.find(typeId) != headers.end()) {
                    translate(headers[typeId], arg);
                } else if (structs.find(typeId) != structs.end()) {
                    translate(structs[typeId], arg);
                }
            }
        }
    }
    BoogieProcedure control = BoogieProcedure(controlName);
    control.setImplemented();
    addProcedure(control);

    std::vector<cstring> declarations;
    for(auto declaration:*p4Control->getDeclarations()){
        if(declaration->to<IR::Declaration_Instance>())
            declarations.push_back(translate(declaration->getName()));
    }
    currentProcedure = &procedures[controlName];

    for (auto controlLocal : p4Control->controlLocals) {
        auto declVar = controlLocal->to<IR::Declaration_Variable>();
        if (declVar == nullptr || declVar->type == nullptr) {
            continue;
        }
        if (declVar->type->is<IR::Type_Extern>() || declVar->type->is<IR::Type_Parser>() ||
            declVar->type->is<IR::Type_Control>() || declVar->type->is<IR::Type_Package>() ||
            declVar->type->to<IR::Type_Header>() != nullptr ||
            declVar->type->to<IR::Type_Struct>() != nullptr) {
            continue;
        }
        cstring varName = translate(declVar->name);
        cstring typ = translate(declVar->type);
        if (auto typeName = declVar->type->to<IR::Type_Name>()) {
            cstring typeAlias = translate(typeName);
            auto it = typeDefs.find(typeAlias);
            if (it != typeDefs.end()) {
                typ = "bv" + toString(it->second);
            }
        }
        if (typ == "") {
            continue;
        }
        if (!isGlobalVariable(varName)) {
            addDeclaration("var "+varName+":"+typ+";\n");
            addGlobalVariables(varName);
        }
        varTypes[varName] = typ;
        if (typ == "bool") {
            updateVariableSize(varName, 0);
        } else if (typ.startsWith("bv")) {
            std::string s = typ.c_str();
            int width = 0;
            std::stringstream ss(s.substr(2));
            ss >> width;
            if (width > 0) {
                updateVariableSize(varName, width);
            }
        } else if (auto typeBits = declVar->type->to<IR::Type_Bits>()) {
            updateVariableSize(varName, typeBits->size);
            updateMaxBitvectorSize(typeBits);
        } else if (auto typeName = declVar->type->to<IR::Type_Name>()) {
            cstring typeAlias = translate(typeName);
            auto it = typeDefs.find(typeAlias);
            if (it != typeDefs.end()) {
                updateVariableSize(varName, it->second);
            }
        }
    }

    for(auto controlLocal:p4Control->controlLocals){
        currentProcedure = &procedures[controlName];
        if (debugObjects) {
            std::cerr << "[p4verify-local] " << controlName << " "
                      << controlLocal->node_type_name() << " "
                      << controlLocal << std::endl;
        }
        if(auto instance = controlLocal->to<IR::Declaration_Instance>()){
            cstring instanceName = translate(instance->getName());
            cstring renamedInstance = "";
            for(cstring declaration:declarations){
                if(!declaration.startsWith(instanceName)) {
                    continue;
                }
                size_t base = instanceName.size();
                if(declaration.size() <= base + 1 || declaration.c_str()[base] != '_') {
                    continue;
                }
                if(declaration.size()>renamedInstance.size()){
                    size_t idx = base + 1;
                    bool digit = true;
                    for(size_t i = idx; i < declaration.size(); i++){
                        if(!(declaration.c_str()[i] >= '0' && declaration.c_str()[i] <= '9')){
                            digit = false;
                        }   
                    }
                    if(digit)
                        renamedInstance = declaration;
                }
            }
            translate(instance, renamedInstance);
        }
        else{
            // can be declared as global variables
            // p4c has finished renaming
            translate(controlLocal);
        }
    }

    currentProcedure = &procedures[controlName];
    currentProcedure->addDeclaration("\n// Control "+controlName+"\n");
    currentProcedure->addDeclaration("procedure {:inline 1} "+controlName+"()\n");
    incIndent();
    for(auto statOrDecl:p4Control->body->components){
        currentProcedure->addStatement(translate(statOrDecl));
    }
    decIndent();
}

void Translator::translate(const IR::Method *method){
    (void)method;
}

void Translator::translate(const IR::P4Action *p4Action){
    cstring actionName = translate(p4Action->name);
    BoogieProcedure action = BoogieProcedure(actionName);
    currentProcedure = &action;
    action.addDeclaration("\n// Action "+actionName+"\n");

    const std::vector<IR::Direction>* effDirs = nullptr;
    auto dirIt = actionParamDirections.find(actionName);
    if (dirIt != actionParamDirections.end() &&
        p4Action->parameters != nullptr &&
        dirIt->second.size() == p4Action->parameters->parameters.size()) {
        effDirs = &dirIt->second;
    }

    auto renderActionParamDecl = [&](const IR::Parameter* parameter, cstring nameOverride) -> cstring {
        cstring name = nameOverride;
        cstring type = translate(parameter->type);

        cstring structName = nullptr;
        if (auto typeStruct = parameter->type->to<IR::Type_Struct>()) {
            structName = typeStruct->name.toString();
        } else if (auto typeName = parameter->type->to<IR::Type_Name>()) {
            cstring typeAlias = translate(typeName->path);
            if (structs.find(typeAlias) != structs.end()) {
                structName = typeAlias;
            }
        }
        if (structName != nullptr && bitvectorStructs.count(structName) > 0 && currentProcedure != nullptr) {
            procParamStructTypes[currentProcedure->getName()][name] = structName;
        }

        if (auto typeBits = parameter->type->to<IR::Type_Bits>()) {
            updateMaxBitvectorSize(typeBits);
            if (currentProcedure != nullptr) {
                currentProcedure->parameters[name] = typeBits->size;
            }
            if (options.ultimateAutomizer && options.bitBlasting) {
                cstring res = "";
                for (int i = 0; i < typeBits->size; i++) {
                    res += connect(name, i) + ":bool";
                    if (i < typeBits->size-1) {
                        res += ", ";
                    }
                }
                return res;
            }
        } else if (auto typeName = parameter->type->to<IR::Type_Name>()) {
            cstring _name = translate(typeName);
            if (typeDefs.find(_name) != typeDefs.end() && currentProcedure != nullptr) {
                currentProcedure->parameters[name] = typeDefs[_name];
            }
        }
        if (options.ultimateAutomizer && parameter->type->to<IR::Type_Bits>()) {
            type = "int";
        }
        return name+":"+type;
    };

    bool hasReturns = false;
    size_t paramIdx = 0;
    for (auto parameter : p4Action->parameters->parameters) {
        const IR::Direction dir = (effDirs != nullptr) ? (*effDirs)[paramIdx] : parameter->direction;
        if (dir == IR::Direction::Out || dir == IR::Direction::InOut) {
            hasReturns = true;
            break;
        }
        paramIdx++;
    }

    action.addDeclaration("procedure {:inline 1} "+actionName+"(");
    bool firstIn = true;
    paramIdx = 0;
    for (auto parameter : p4Action->parameters->parameters) {
        const IR::Direction dir = (effDirs != nullptr) ? (*effDirs)[paramIdx] : parameter->direction;
        if (dir == IR::Direction::Out) {
            paramIdx++;
            continue;
        }
        cstring paramName = translate(parameter->name);
        if (dir == IR::Direction::InOut) {
            paramName = paramName + "__in";
        }
        if (!firstIn) {
            action.addDeclaration(", ");
        }
        action.addDeclaration(renderActionParamDecl(parameter, paramName));
        firstIn = false;
        paramIdx++;
    }
    action.addDeclaration(")");
    if (hasReturns) {
        action.addDeclaration(" returns (");
        bool firstOut = true;
        paramIdx = 0;
        for (auto parameter : p4Action->parameters->parameters) {
            const IR::Direction dir = (effDirs != nullptr) ? (*effDirs)[paramIdx] : parameter->direction;
            if (dir != IR::Direction::Out && dir != IR::Direction::InOut) {
                paramIdx++;
                continue;
            }
            cstring outName = translate(parameter->name);
            if (!firstOut) {
                action.addDeclaration(", ");
            }
            action.addDeclaration(renderActionParamDecl(parameter, outName));
            firstOut = false;
            paramIdx++;
        }
        action.addDeclaration(")");
    }
    action.addDeclaration("\n");
    incIndent();

    // Initialize inout parameters from their input copies.
    if (hasReturns) {
        paramIdx = 0;
        for (auto parameter : p4Action->parameters->parameters) {
            const IR::Direction dir = (effDirs != nullptr) ? (*effDirs)[paramIdx] : parameter->direction;
            if (dir != IR::Direction::InOut) {
                paramIdx++;
                continue;
            }
            cstring outName = translate(parameter->name);
            cstring inName = outName + "__in";
            if (options.ultimateAutomizer && options.bitBlasting &&
                parameter->type->to<IR::Type_Bits>()) {
                auto typeBits = parameter->type->to<IR::Type_Bits>();
                for (int i = 0; i < typeBits->size; i++) {
                    action.addStatement(getIndent()+connect(outName, i)+" := "+connect(inName, i)+";\n");
                }
            } else {
                action.addStatement(getIndent()+outName+" := "+inName+";\n");
            }
            paramIdx++;
        }
    }

    bool existInSpec = false;
    for(cstring str:P4LTL_KEYS){
        if(options.CpiIfElse && str == P4LTL_KEYS_CPI_MODEL)
            continue;
        if(p4ltlSpec.find(str) != p4ltlSpec.end()){
            for(auto spec:p4ltlSpec[str]){
                if(ltlTranslator->isActionApplied(spec, actionName)){
                    existInSpec = true;
                    break;
                }
            }
        }
        if(existInSpec) break;
    }
    if(existInSpec){
        cstring actionIsApplied = actionName+".isApplied";
        addDeclaration("var "+actionIsApplied+":bool;\n");
        addGlobalVariables(actionIsApplied);
        action.addStatement("\n    "+actionIsApplied+" := true;\n");
        action.addModifiedGlobalVariables(actionIsApplied);
        havocProcedure.addStatement("    "+actionIsApplied+" := false;\n");
        havocProcedure.addModifiedGlobalVariables(actionIsApplied);
    }

    action.addStatement(translate(p4Action->body));
    decIndent();
    addProcedure(action);
}

cstring Translator::translate(const IR::Parameter *parameter, cstring arg){
    cstring name = translate(parameter->name);
    cstring type = translate(parameter->type);
    if(arg == "action"){
        cstring structName = nullptr;
        if (auto typeStruct = parameter->type->to<IR::Type_Struct>()) {
            structName = typeStruct->name.toString();
        } else if (auto typeName = parameter->type->to<IR::Type_Name>()) {
            cstring typeAlias = translate(typeName->path);
            if (structs.find(typeAlias) != structs.end()) {
                structName = typeAlias;
            }
        }
        if (structName != nullptr && bitvectorStructs.count(structName) > 0 && currentProcedure != nullptr) {
            procParamStructTypes[currentProcedure->getName()][name] = structName;
        }
        if(auto typeBits = parameter->type->to<IR::Type_Bits>()){
            updateMaxBitvectorSize(typeBits);
            currentProcedure->parameters[name] = typeBits->size;
            if(options.ultimateAutomizer && options.bitBlasting){
                cstring res = "";
                for(int i = 0; i < typeBits->size; i++){
                    res += connect(name, i)+":bool";
                    if(i < typeBits->size-1) res += ", ";
                }
                return res;
            }
        }
        else if(auto typeName = parameter->type->to<IR::Type_Name>()){
            cstring _name = translate(typeName);
            if(typeDefs.find(_name) != typeDefs.end()){
                currentProcedure->parameters[name] = typeDefs[_name];
            }
        }
    }
    if(options.ultimateAutomizer && parameter->type->to<IR::Type_Bits>())
        type = "int";
    return name+":"+type;
}
