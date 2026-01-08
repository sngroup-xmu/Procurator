// test_slicing.h

#ifndef TEST_SLICING_H
#define TEST_SLICING_H


#include "verify/control_flow_analysis/sclicing_engine.h"
#include "lib/cstring.h"

/**
 * 进行多组 slicing 测试的类
 */
class SlicingTest {
private:
    // 已有
    std::unordered_map<int, CFGNode> netChainNodes;
    std::vector<CFGEdge> netChainEdges;
    cstring path;

    // 新增：保存 CFG -> IR 映射
    std::unordered_map<int, std::set<int>> irNodeIdsMap;
    std::unordered_set<int> unionAllRetainedIds;
    std::unordered_set<int> collectIrIdsFromSubNodes(const std::map<int, CFGNode>& subNodes) const;

public:
    SlicingTest(const std::unordered_map<int, CFGNode>& nodeMap,
                const std::vector<CFGEdge>& edgeVec,
                std::unordered_map<int, std::set<int>>& irNodeIds,  // <-- 新增
                cstring& path);

    const std::unordered_set<int>& getUnionAllRetainedIrIds() const {
        return unionAllRetainedIds;
    }
};

#endif // TEST_SLICING_H
