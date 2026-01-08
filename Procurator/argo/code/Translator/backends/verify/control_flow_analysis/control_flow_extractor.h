// ControlFlowExtractor.h
#ifndef CONTROL_FLOW_EXTRACTOR_H
#define CONTROL_FLOW_EXTRACTOR_H

#include <fstream>
#include <stack>
#include <vector>
#include <set>
#include <unordered_map>

#include "lib/cstring.h"
#include "common/resolveReferences/referenceMap.h"
#include "p4/typeMap.h"
#include "verify/translate/bmv2.h"
#include "verify/translate/options.h"

// 自己的结构体 or 枚举
#include "verify/control_flow_analysis/structures.h"

// 这里需要用 IrIdCollector 里的类 => 包含其头即可
#include "verify/control_flow_analysis/ir_id_collector.h"

// Forward declarations
namespace P4 {
    class ReferenceMap;
    class TypeMap;
}

namespace Utils {
    // Utility functions and classes
    cstring translateExpression(const IR::Expression* expr);
    cstring getFullVariableName(const IR::Expression* expr);
    void extractUsedVariables(const IR::Expression* expr, std::set<cstring>& useVars);
    bool isLiteralConstant(const cstring &str);
    bool isKeyword(const cstring& str);
    bool isConstant(const cstring& str);
    bool isVariable(const cstring& str);
    void extractUsedVariablesFromString(const cstring& exprStr, std::set<cstring>& useVars);
    bool isRegisterMethod(const cstring& methodName);
    bool isRegisterRead(const IR::MethodCallExpression* methodCall);
    bool isRegisterWrite(const IR::MethodCallExpression* methodCall);
    cstring getMethodName(const IR::MethodCallExpression* methodCall);
    cstring translateMethodCall(const IR::MethodCallExpression* methodCall);
}

struct ActionInstance {
    const IR::P4Action* actionDef;     // 动作定义
    std::vector<cstring> parameters;   // 动作参数

    // 重载相等运算符，用于在 unordered_map 中作为键
    bool operator==(const ActionInstance& other) const {
        if (actionDef != other.actionDef) return false;
        if (parameters.size() != other.parameters.size()) return false;
        for (size_t i = 0; i < parameters.size(); ++i) {
            if (parameters[i] != other.parameters[i]) return false;
        }
        return true;
    }
};

template<>
struct std::hash<ActionInstance> {
    std::size_t operator()(const ActionInstance& ai) const noexcept {
        std::size_t h1 = std::hash<const IR::P4Action*>()(ai.actionDef);
        std::size_t h2 = 0;
        for (const auto& param : ai.parameters) {
            h2 ^= std::hash<std::string>()(param.c_str());
        }
        return h1 ^ h2;
    }
};

class ControlFlowExtractor : public Inspector {
public:
    bool switchFuncPosiLog = true;
    std::unordered_map<int, CFGNode> nodes;              // Map of nodes in the CFG
    std::vector<CFGEdge> edges;                // Control flow edges
    int programExitNodeId;                     // Exit node ID
    // 存放构造出来的 dataEdges
    std::unordered_set<CFGEdge, CFGEdgeHash, CFGEdgeEq> dataEdges;
    // Constructor
    ControlFlowExtractor(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                         P4VerifyOptions& options, BMV2CmdsAnalyzer* bMV2CmdsAnalyzer);

    bool preorder(const IR::P4Program *program) override;

    bool preorder(const IR::P4Parser *parser) override;

    bool preorder(const IR::ParserState *state) override;

    bool isPersistentVar(const cstring &varName) const;

    void buildDataDependenciesSingleRound(bool withExitToEntry);

    void computeReachingDefinitions(bool withExitToEntry,
                                    std::unordered_map<int, std::unordered_set<Definition, DefinitionHash, DefinitionEq>
                                    > &
                                    RDin, std::unordered_map<int, std::unordered_set<Definition, DefinitionHash,
                                    DefinitionEq>> &RDout);

    bool isExitToEntryEdge(const CFGEdge &e);

    void generateDataEdgesFromRD(
        const std::unordered_map<int, std::unordered_set<Definition, DefinitionHash, DefinitionEq>> &RDin, bool withExitToEntry);

    // Main method to build data dependencies after traversal
    void buildDataDependencies();

    // Methods to output the control flow graph
    void outputCFGAsJson(const cstring& filename);
    void outputCFGAsDot(const cstring& filename);

    void handleDefaultAction(const IR::P4Table *table, const cstring &tableName, const std::vector<cstring> &keys, int matchNodeId, bool ruleExist, size_t
                             actionListSize, bool noKey, std::vector<int> &ruleExitNodeIds);

    // Overridden methods from the Inspector class
    bool preorder(const IR::P4Control* control) override;
    bool preorder(const IR::BlockStatement* block) override;

    // bool preorder(const IR::Declaration *decl) override;

    bool preorder(const IR::IfStatement* statement) override;
    bool preorder(const IR::SwitchStatement* statement) override;


    bool preorder(const IR::MethodCallStatement* statement) override;

    //bool preorder(const IR::MethodCallExpression *expr);

    bool preorder(const IR::AssignmentStatement* statement) override;


    bool preorder(const IR::P4Table* table) override;

    bool preorder(const IR::Expression *expr) override;

    int processActionInstance(const ActionInstance &actionInstance, std::vector<std::string> actualParams);

    void visitActionBodyWithParameters(const IR::BlockStatement *body,
                                       const std::unordered_map<cstring, cstring> &paramBindings);

    void visitStatementWithParams(const IR::Statement* stmt,
                                  const std::unordered_map<cstring, cstring> &parameterBindings);


    bool preorder(const IR::P4Action* action) override;

    bool preorder(const IR::ExitStatement* statement) override;

    bool preorder(const IR::ReturnStatement* statement) override;

    // Static utility methods
    static const char* nodeTypeToString(NodeType type);

    std::unordered_map<int, std::set<int>> irNodeIds;

    void buildPipelineInternals(const IR::P4Program* program);


private:
    // Data members
    P4VerifyOptions& options;                  // Options for verification
    P4::ReferenceMap* refMap;                  // Reference map
    P4::TypeMap* typeMap;                      // Type map
    BMV2CmdsAnalyzer* bMV2CmdsAnalyzer;        // BMv2 commands analyzer
    const IR::P4Control* currentControl;       // Current control block
    std::vector<PipelineInfo> pipelineInfos;
    // 记录 parser state 名 -> 节点ID
    // std::unordered_map<std::string, int> parserStateNodeMap;
    // accept、reject 两个专门节点ID
    int acceptNodeId{};
    int rejectNodeId{};
    std::unordered_map<std::string ,int> pipelineNodeMap;
    std::unordered_map<cstring, RegisterActionInfo> registerActionMap;
    std::unordered_map<std::string, ParserStateInfo> parserStateInfoMap;

    int nextNodeId;                            // Next node ID to assign
    int currentNodeId;                         // Current node ID
    bool isFirstParseState = true;             // 是否是第一个 parser state
    std::stack<int> nodeStack;                 // Stack to manage current nodes
    bool isRecirculate = false;
    bool isMirror = false;
    bool isResubmit = false;
    bool needParserInfo = false;
    ParserInfo currentParserInfo;
    std::vector<ParserTransition> currentParserTransitions;
    // 存储提取的 Struct 变量信息
    std::vector<StructVariableInfo> structVariables;

    // 存储已处理的 Struct 名称，防止重复处理
    std::unordered_set<std::string> processedStructs;

    // 存储 Struct 名称到其定义的映射
    std::unordered_map<std::string, const IR::Type_Struct*> structDefinitions;

    // 存储提取的 TypeHeader 信息
    std::vector<TypeHeaderInfo> typeHeaders;

    // 存储已处理的 TypeHeader 名称，防止重复处理
    std::unordered_set<std::string> processedTypeHeaders;

    // 存储 TypeHeader 名称到其定义的映射
    std::unordered_map<std::string, const IR::Type_Header*> typeHeaderDefinitions;

    // 存储提取的 Register 信息
    std::vector<RegisterInfo> registers;

    // 存储已处理的 Register 名称，防止重复处理
    std::unordered_set<std::string> processedRegisters;

    // Data dependency edges
    // 动作定义映射
    std::unordered_map<cstring, IR::P4Action*> actionMap;

    // 已访问的动作
    std::unordered_set<cstring> visitedActions;

    // 添加一个成员变量，用于维护当前的参数绑定
    std::unordered_map<cstring, cstring> parameterBindings;

    // Mappings to track action instances and their entry/exit nodes
    std::unordered_map<cstring, std::pair<int, int>> actionEntryExitNodes;

    std::unordered_map<ActionInstance, std::pair<int, int>> actionInstanceEntryExitNodes;

    // Helper methods
    int addNode(cstring name, NodeType type, const IR::Node* irNode, cstring code = "");

    void addEdge(int fromNodeId, int toNodeId, cstring label, cstring type = "control");

    void addControlEdge(int fromNodeId, int toNodeId, cstring label, cstring type);

    void pushCurrentNode(int nodeId);

    void popCurrentNode();

    const IR::P4Action* findActionDefinition(cstring actionName) const;

    // Utility functions for expressions
    static const IR::Expression* replaceParameters(const IR::Expression* expr,
                                                   const std::unordered_map<cstring, cstring>& parameterBindings);

    bool preorder(const IR::Type_Struct *typeStruct) override;

    bool preorder(const IR::Type_Header *typeHeader) override;

    void extractStructFields(const IR::Type_Struct *typeStruct, StructVariableInfo &svi);

    void extractTypeHeaderFields(const IR::Type_Header *typeHeader, TypeHeaderInfo &thi);

    bool preorder(const IR::Declaration_Instance *decl) override;

    bool preorder(const IR::Declaration_Variable *declVar) override;

    void addAllDescendants(int cfgNodeId, const IR::Node *top);

    bool preorder(const IR::Node *node) override;
};

#endif // CONTROL_FLOW_EXTRACTOR_H
