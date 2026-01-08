//
// Created by smy on 2024/10/10.
//
#include "variable_collector.h"


bool VariableCollector::preorder(const IR::P4Action* action) {
    // 进入新的作用域
    scopeStack.push_back("Action:" + action->name.name);

    // 处理参数
    for (auto param : *action->parameters) {
        visit(param);
    }

    // 继续遍历动作体
    visit(action->body);

    // 退出作用域
    scopeStack.pop_back();
    // 不再继续遍历该节点的子节点
    return false;
}

bool VariableCollector::preorder(const IR::P4Control* control) {
    // 进入新的作用域
    scopeStack.push_back("Control:" + control->name.name);

    // 处理参数
    for (auto param : *control->type->applyParams) {
        visit(param);
    }

    // 处理局部声明
    for (auto decl : control->controlLocals) {
        visit(decl);
    }

    // 继续遍历
    visit(control->body);

    // 退出作用域
    scopeStack.pop_back();
    return false;
}

bool VariableCollector::preorder(const IR::P4Parser* parser) {
    // 进入新的作用域
    scopeStack.push_back("Parser:" + parser->name.name);

    // 处理参数
    for (auto param : *parser->type->applyParams) {
        visit(param);
    }

    // 处理局部声明
    for (auto decl : parser->parserLocals) {
        visit(decl);
    }

    // 继续遍历 parser states
    for (auto state : parser->states) {
        visit(state);
    }

    // 退出作用域
    scopeStack.pop_back();
    return false;
}

bool VariableCollector::preorder(const IR::Function* function) {
    // 进入新的作用域
    scopeStack.push_back("Function:" + function->name.name);

    // 处理参数
    for (auto param : *function->type->parameters) {
        visit(param);
    }

    // 继续遍历函数体
    visit(function->body);

    // 退出作用域
    scopeStack.pop_back();
    return false;
}

bool VariableCollector::preorder(const IR::Parameter* param) {
    auto paramName = param->name.name;
    cstring typeName = param->type->toString();
    variableList.emplace_back(paramName, typeName, currentScope(), true, false);
    return false;
}

bool VariableCollector::preorder(const IR::Declaration_Variable* decl) {
    auto varName = decl->name.name;
    cstring typeName = decl->type->toString();
    bool isGlobal = (currentScope() == "global");
    variableList.emplace_back(varName, typeName, currentScope(), false, isGlobal);
    return false;
}

bool VariableCollector::preorder(const IR::Declaration_Constant* decl) {
    auto constName = decl->name.name;
    cstring typeName = decl->type->toString();
    bool isGlobal = (currentScope() == "global");
    variableList.emplace_back(constName, typeName, currentScope(), false, isGlobal);
    return false;
}

bool VariableCollector::preorder(const IR::Declaration_Instance* decl) {
    auto instanceName = decl->name.name;
    cstring typeName = decl->type->toString();
    bool isGlobal = (currentScope() == "global");

    // 检查实例是否为寄存器、计数器等 extern 对象
    if (auto typeSpecialized = decl->type->to<IR::Type_Specialized>()) {
        cstring baseType = typeSpecialized->baseType->toString();
        if (baseType == "register" || baseType == "counter" || baseType == "meter") {
            variableList.emplace_back(instanceName, baseType, currentScope(), false, isGlobal);
            return false;
        }
    }

    variableList.emplace_back(instanceName, typeName, currentScope(), false, isGlobal);
    return false;
}


bool VariableCollector::preorder(const IR::Type_Struct* typeStruct) {
    auto typeName = typeStruct->name.name;
    cstring scope = currentScope();
    // 将类型作为变量信息收集，您可以根据需要调整
    variableList.emplace_back(typeName, "struct", scope, false, true);

    // 处理结构体中的字段
    scopeStack.push_back("Struct:" + typeName);
    for (auto field : typeStruct->fields) {
        auto fieldName = field->name.name;
        cstring fieldType = field->type->toString();
        variableList.emplace_back(fieldName, fieldType, currentScope(), false, false);
    }
    scopeStack.pop_back();

    return false;
}

bool VariableCollector::preorder(const IR::Type_Header* typeHeader) {
    auto typeName = typeHeader->name.name;
    cstring scope = currentScope();
    variableList.emplace_back(typeName, "header", scope, false, true);

    // 处理头部中的字段
    scopeStack.push_back("Header:" + typeName);
    for (auto field : typeHeader->fields) {
        auto fieldName = field->name.name;
        cstring fieldType = field->type->toString();
        variableList.emplace_back(fieldName, fieldType, currentScope(), false, false);
    }
    scopeStack.pop_back();

    return false;
}

bool VariableCollector::preorder(const IR::Type_HeaderUnion* typeHeaderUnion) {
    auto typeName = typeHeaderUnion->name.name;
    cstring scope = currentScope();
    variableList.emplace_back(typeName, "header_union", scope, false, true);

    // 处理头部联合中的字段
    scopeStack.push_back("HeaderUnion:" + typeName);
    for (auto field : typeHeaderUnion->fields) {
        auto fieldName = field->name.name;
        cstring fieldType = field->type->toString();
        variableList.emplace_back(fieldName, fieldType, currentScope(), false, false);
    }
    scopeStack.pop_back();

    return false;
}

bool VariableCollector::preorder(const IR::Type_Typedef* typeTypedef) {
    auto typeName = typeTypedef->name.name;
    cstring actualType = typeTypedef->type->toString();
    cstring scope = currentScope();
    variableList.emplace_back(typeName, actualType, scope, false, true);
    return false;
}

bool VariableCollector::preorder(const IR::Type_Enum* typeEnum) {
    auto typeName = typeEnum->name.name;
    cstring scope = currentScope();
    variableList.emplace_back(typeName, "enum", scope, false, true);

    // 处理枚举成员
    scopeStack.push_back("Enum:" + typeName);
    for (auto member : typeEnum->members) {
        auto memberName = member->name.name;
        variableList.emplace_back(memberName, "enum_member", currentScope(), false, false);
    }
    scopeStack.pop_back();

    return false;
}

bool VariableCollector::preorder(const IR::Type_Error* typeError) {
    // 错误类型可以视为特殊的枚举
    cstring scope = currentScope();
    variableList.emplace_back("error", "error", scope, false, true);

    scopeStack.push_back("Error");
    for (auto member : typeError->members) {
        auto memberName = member->name.name;
        variableList.emplace_back(memberName, "error_member", currentScope(), false, false);
    }
    scopeStack.pop_back();

    return false;
}


