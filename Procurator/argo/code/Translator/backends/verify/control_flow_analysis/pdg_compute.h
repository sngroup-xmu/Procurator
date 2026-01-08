//
// Created by smy on 2025/1/17.
//

#ifndef PDG_COMPUTE_H
#define PDG_COMPUTE_H
#include <unordered_map>
#include <unordered_set>

#include "control_flow_extractor.h"

class PDGCompute {
public:
    PDGCompute(const std::unordered_map<int, CFGNode> &nodes,
               const std::vector<CFGEdge> &dataE,
               const std::vector<CFGEdge> &ctrlE)
        : allNodes(nodes), dataEdges(dataE), ctrlEdges(ctrlE)
    {}

    // 1) build PDG
    void buildPDG();

    void exportSliceToDot(const std::set<int> &sliceNodes, const std::string &dotFile) const;

    // 2) slice
    //    给定一个 varName，返回相关节点id的集合
    std::set<int> slice(std::vector<cstring> &varNames, bool forward = false);
    static void runAllPDGTests();


private:
    const std::unordered_map<int, CFGNode> & allNodes;    // 所有节点
    const std::vector<CFGEdge>    & dataEdges;   // 数据依赖边
    const std::vector<CFGEdge>    & ctrlEdges;   // 控制依赖边
    std::unordered_map<int, std::vector<int>> PDG_inEdges;   // PDG反向邻接
    std::unordered_map<int, std::vector<int>> PDG_outEdges;
};


#endif //PDG_COMPUTE_H
