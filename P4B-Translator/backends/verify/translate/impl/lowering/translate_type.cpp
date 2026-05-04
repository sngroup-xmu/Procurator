#include "translate.h"

#include <sstream>
#include <string>

// Type
cstring Translator::translate(const IR::Type *type){
    if (auto typeBits = type->to<IR::Type_Bits>()){
        return translate(typeBits);
    }
    else if (auto typeBoolean = type->to<IR::Type_Boolean>()){
        return translate(typeBoolean);
    }
    else if (auto typeSpecialized = type->to<IR::Type_Specialized>()){
        return translate(typeSpecialized);
    }
    else if (auto typeName = type->to<IR::Type_Name>()){
        return translate(typeName);
    }
    else if (auto typeTypedef = type->to<IR::Type_Typedef>()){
        return translate(typeTypedef);
    }
    return "";
}

cstring Translator::translate(const IR::Type_Bits *typeBits){
    updateMaxBitvectorSize(typeBits);
    std::stringstream ss;
    ss << "bv" << typeBits->size;
    return ss.str();
}

cstring Translator::translate(const IR::Type_Boolean *typeBoolean){
    (void)typeBoolean;
    return "bool";
}

cstring Translator::translate(const IR::Type_Specialized *typeSpecialized){
    return typeSpecialized->baseType->toString();
}

cstring Translator::translate(const IR::Type_Name *typeName){
    return translate(typeName->path);
}

cstring Translator::translate(const IR::Type_Array *typeStack, cstring arg){
    const IR::Type_Header* typeHeader = resolveHeaderType(typeStack->elementType);
    if(typeHeader!=nullptr && stacks.find(arg)==stacks.end()){
        stacks.insert(arg);
        translate(typeHeader, arg+".last");
        if (auto constant = typeStack->size->to<IR::Constant>()) {
            int size = 0;
            std::stringstream ss;
            ss << constant->value;
            ss >> size;
            for(int i = 0; i < size; i++){
                translate(typeHeader, arg+"."+std::to_string(i));
            }
        }
        cstring procName = "packet_in.extract.headers.";
        procName += arg.substr(4)+".next";
        if(procedures.find(procName)==procedures.end()){
            BoogieProcedure extractStack = BoogieProcedure(procName);
            extractStack.addDeclaration("procedure {:inline 1} "+procName+"(stack:HeaderStack);\n");
            extractStack.addModifiedGlobalVariables("stack.index");
            extractStack.addModifiedGlobalVariables("isValid");
            extractStack.addDeclaration("ensures(isValid[stack[stack.index[stack]]]==true && stack.index[stack]==old(stack.index[stack])+1);\n");

            addProcedure(extractStack);
        }
    }
    return "";
}

cstring Translator::translate(const IR::Type_Typedef *typeTypedef){
    cstring name = translate(typeTypedef->name);
    if(auto typeBits = typeTypedef->type->to<IR::Type_Bits>()){
        typeDefs[name] = typeBits->size;
    }
    if(options.ultimateAutomizer){
        if(auto typeBits = typeTypedef->type->to<IR::Type_Bits>()){
            typeDefs[name] = typeBits->size;
            addDeclaration("type "+name+" = int;\n");
        }
        else addDeclaration("type "+name+" = "+translate(typeTypedef->type)+";\n");
    }
    else
        addDeclaration("type "+name+" = "+translate(typeTypedef->type)+";\n");
    return "";
}
