//
// Created by smy on 2024/10/10.
//

// VariableCollector.h

#ifndef _VARIABLE_COLLECTOR_H_
#define _VARIABLE_COLLECTOR_H_

// 在 main.cpp 的开头，添加必要的头文件
#include "ir/ir.h"

// 定义 VariableCollector 类
class VariableCollector : public Inspector {
public:
    // 变量信息结构体
    struct VariableInfo {
        cstring name;
        cstring type;
        cstring scope;
        bool isParameter;
        bool isGlobal;

        VariableInfo(cstring name, cstring type, cstring scope, bool isParameter, bool isGlobal)
            : name(name), type(type), scope(scope), isParameter(isParameter), isGlobal(isGlobal) {}
    };

    // 变量信息列表
    std::vector<VariableInfo> variableList;

private:
    // 用于跟踪当前作用域的栈
    std::vector<cstring> scopeStack;

public:
    VariableCollector() {
        // 初始化全局作用域
        scopeStack.push_back("global");
    }

    // 获取当前作用域
    cstring currentScope() const {
        return scopeStack.back();
    }

    // 访问各种节点的函数
    bool preorder(const IR::P4Action* action) override;
    bool preorder(const IR::P4Control* control) override;
    bool preorder(const IR::P4Parser* parser) override;
    bool preorder(const IR::Function* function) override;
    bool preorder(const IR::Declaration_Variable* decl) override;
    bool preorder(const IR::Declaration_Constant* decl) override;
    bool preorder(const IR::Declaration_Instance* decl) override;
    bool preorder(const IR::Parameter* param) override;
    bool preorder(const IR::Type_Struct* typeStruct) override;
    bool preorder(const IR::Type_Header* typeHeader) override;
    bool preorder(const IR::Type_HeaderUnion* typeHeaderUnion) override;
    bool preorder(const IR::Type_Typedef* typeTypedef) override;
    bool preorder(const IR::Type_Enum* typeEnum) override;
    bool preorder(const IR::Type_Error* typeError) override;

    // 根据需要添加更多的访问函数
};


#endif // _VARIABLE_COLLECTOR_H_

