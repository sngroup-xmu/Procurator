//
// Created by smy on 2024/12/31.
//

#ifndef SCLICING_ENGINE_H
#define SCLICING_ENGINE_H
#include <vector>

// 需要使用 ControlFlowExtractor => 包含其头
#include <queue>

#include "backends/verify/control_flow_analysis/control_flow_extractor.h"

#include "lib/cstring.h"

class SliceEngine {
public:
    /// \param nodeMap   整个程序的节点 (id -> CFGNode)
    /// \param edgeVec   包含控制流边和数据流边
    explicit SliceEngine(const std::unordered_map<int, CFGNode> &nodeMap,
                         const std::vector<CFGEdge> &edgeVec);

    enum VisitStatus {
        MustKeep,
        NotVisited,
        SkipButContinue
    };    /// 设置切片目标变量
    void setSlicingCriteria(const std::set<cstring>& vars);

    /// 执行正向切片(Forward Slice)
    // void performForwardSlice();

    /// 执行逆向切片(Backward Slice)
    // void performBackwardSlice();

    /// 返回切片后保留的节点集合(节点id)
    std::set<int> getSlicedNodes() const;

    /// 构建切片后的子图
    /// first : nodeMap
    /// second: edgeVec
    std::pair<std::map<int, CFGNode>, std::vector<CFGEdge>> buildSlicedGraph() const;

    void buildGraphStructures();

    void retainControlDependencies(int nodeId, bool backward, std::queue<int> &worklist);

    bool isRelevantToSliceVars(const CFGNode &node) const;

    static bool isControlNode(const CFGNode &node);

    bool shouldKeepControlNode(int parentId, int childId, bool isForward);

    std::vector<int> getAdjacentNodes(int nodeId, bool backward) const;

    bool shouldKeepNode(int childId, int parentId) const;

    std::vector<int> getParents(int nodeId);

    // std::vector<int> getParents(int nodeId) const;

    // void doSlice(bool backward);

    void doBackwardSlice();

    // void doSlice();

    // void doBackwardSlice();

    std::set<std::string> getUsedVariables() const;

private:
    // 节点
    std::unordered_map<int, CFGNode> nodes;
    const std::vector<CFGEdge>& edges;
    // 多状态
    std::unordered_map<int, VisitStatus> visited_;
    // 切片时关注的变量
    std::set<cstring> sliceVars;

    // 切片结果
    std::set<int> slicedNodes;  // 需要保留的节点

    // 反向边(控制 + 数据)
    // 亦可区分: reverseControlEdges, reverseDataEdges
    // adjacency for data, sequential, control (reversed)
    std::multimap<int,int> reverseDataAdj;
    std::multimap<int,int> reverseSeqAdj;
    std::multimap<int,int> reverseCtrlAdj;

    // 正向边(控制 + 数据)
    // 用于 forward slice
    std::multimap<int, int> forwardCtrlAdj;
    std::multimap<int, int> forwardDataAdj;

};

#endif //SCLICING_ENGINE_H
