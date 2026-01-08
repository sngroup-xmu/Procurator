//
// Created by smy on 2024/12/31.
//

#ifndef STRUCTURES_H
#define STRUCTURES_H
#include <ir/node.h>
#include <lib/cstring.h>

#endif //STRUCTURES_H
// Enum for node types in the control flow graph
enum class NodeType {
    IF,
    BLOCK,
    CONTROL,
    PARSER,
    PARSE_STATE,
    SWITCH,
    ENTRY,
    EXIT,
    MERGE,
    STATEMENT,
    CONDITION,
    TABLE,
    ACTION,
    DECLARATION
};

// Struct representing a node in the control flow graph
struct CFGNode {
    int id;                        // Unique identifier for the node
    cstring name;                  // Name of the node
    NodeType type;                 // Type of the node
    const IR::Node* irNode;        // Corresponding IR node
    cstring code;                  // Detailed code or statement
    std::set<cstring> genVars;     // Variables defined at this node
    std::set<cstring> useVars;     // Variables used at this node
};

// Struct representing an edge in the control flow graph
struct CFGEdge {
    int fromNodeId;    // Source node ID
    int toNodeId;      // Destination node ID
    cstring type;
    cstring label;     // Label for the edge (e.g., condition)
};

// 为了能放进unordered_set，需要定义 hash / eq
struct CFGEdgeHash {
    std::size_t operator()(const CFGEdge &e) const {
        // 一个简易hash，可按需改进
        // 这里仅演示
        std::hash<int> hi;
        std::hash<std::string> hs;
        auto h1 = hi(e.fromNodeId);
        auto h2 = hi(e.toNodeId);
        auto h3 = hs(e.type.c_str());
        auto h4 = hs(e.label.c_str());
        // 组合
        return (((h1 ^ (h2 << 1)) >> 1) ^ (h3 << 1)) ^ h4;
    }
};
struct CFGEdgeEq {
    bool operator()(const CFGEdge &a, const CFGEdge &b) const {
        return (a.fromNodeId == b.fromNodeId) &&
               (a.toNodeId   == b.toNodeId) &&
               (a.type       == b.type) &&
               (a.label      == b.label);
    }
};
// 到达定义时，我们需要记录 “这个定义来自哪个节点、定义了什么变量”
struct Definition {
    int defNodeId;        // 哪个节点
    std::string varName;  // 定义的变量
    // 使之可比较
    bool operator==(const Definition &rhs) const {
        return (defNodeId == rhs.defNodeId && varName == rhs.varName);
    }
};

// 定义一个hash
struct DefinitionHash {
    size_t operator()(const Definition &d) const {
        std::hash<int> hi;
        std::hash<std::string> hs;
        return (hi(d.defNodeId) ^ (hs(d.varName) << 1));
    }
};
struct DefinitionEq {
    bool operator()(const Definition &a, const Definition &b) const {
        return (a.defNodeId == b.defNodeId && a.varName == b.varName);
    }
};
// 定义用于存储 Struct 字段信息的结构体
struct StructFieldInfo {
    std::string name; // 字段名
    std::string type; // 字段类型
};

// 定义用于存储 Struct 变量信息的结构体
struct StructVariableInfo {
    std::string variableName;       // 变量名
    std::string structTypeName;     // Struct 类型名
    std::vector<StructFieldInfo> fields; // Struct 的字段信息
};

// 定义用于存储 TypeHeader 字段信息的结构体
struct TypeHeaderFieldInfo {
    std::string name; // 字段名
    std::string type; // 字段类型
};

// 定义用于存储 TypeHeader 变量信息的结构体
struct TypeHeaderInfo {
    std::string headerName;            // Header 名称
    std::string typeName;              // TypeHeader 类型名
    std::vector<TypeHeaderFieldInfo> fields; // TypeHeader 的字段信息
};

// 定义用于存储 Register 信息的结构体
struct RegisterInfo {
    std::string name;        // 寄存器名称
    std::string size;        // 寄存器大小
    std::string valueType;   // 寄存器值类型
    std::string indexType;   // 寄存器索引类型
};

struct ParserInfo {
    int parserNodeId;          // parser本身对应的cfg节点id
    std::string parserName;
    // stateName -> cfgNodeId
    std::unordered_map<std::string, int> stateNodeMap;
    std::unordered_map<std::string, int> stateNodeTailMap;

    // 后续若需要存储 transitions 也可放这
};

struct ParserTransition {
    cstring fromState;
    cstring label;      // 用于 CFG边上显示的case label
    cstring toState;    // 目标状态名 (可能是"accept"/"reject"或者普通 state名)
    int fromCaseNodeId;
};

struct ParserStateInfo {
    int startNodeId; // state入口
    int exitNodeId;  // state出口(Condition node), 如果无selectExpr则可以等于 lastStatementNode
};

struct RegisterActionInfo {
    const IR::P4Action* fakeAction;
    cstring registerName;
};

// 存放 pipeline 的子组件信息
struct PipelineComponent {
    cstring instanceName;     // e.g. "IngressParser"
    cstring expressionString; // IR表达式转的字符串
    // 你还可以加 “type”为 "parser" / "control" / "deparser" 等信息
};

// 存放 pipeline 自身的信息
struct PipelineInfo {
    cstring pipelineName;                          // e.g. "pipe"
    const IR::Declaration_Instance* declInstance;  // 指向 pipeline 的 IR 声明(可选)
    std::vector<PipelineComponent> components;     // 按出现顺序存子组件
};

struct pair_hash
{
    template <class T1, class T2>
    std::size_t operator() (const std::pair<T1, T2> &pair) const
    {
        return std::hash<T1>()(pair.first) ^ std::hash<T2>()(pair.second);
    }
};
