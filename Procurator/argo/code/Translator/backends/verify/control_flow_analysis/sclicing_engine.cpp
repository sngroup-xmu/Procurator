//
// Created by smy on 2024/12/31.
//

#include "sclicing_engine.h"

#include <queue>
#include <lib/cstring.h>
// =============== 类实现 =======================
// 构造函数
SliceEngine::SliceEngine(const std::unordered_map<int, CFGNode>& allNodes,
                         const std::vector<CFGEdge>& allEdges)
    : nodes(allNodes), edges(allEdges)
{
    buildGraphStructures(); // 构造前向、后向邻接表
}

// 设置目标变量
void SliceEngine::setSlicingCriteria(const std::set<cstring>& vars) {
    sliceVars = vars;
    slicedNodes.clear();
}


std::set<int> SliceEngine::getSlicedNodes() const {
    return slicedNodes;
}

std::pair<std::map<int, CFGNode>, std::vector<CFGEdge>>
SliceEngine::buildSlicedGraph() const
{
    // 过滤节点
    std::map<int, CFGNode> subNodes;
    for (auto id : slicedNodes) {
        subNodes[id] = nodes.at(id);
    }
    // 过滤边
    std::vector<CFGEdge> subEdges;
    for (auto &edge : edges) {
        if (slicedNodes.count(edge.fromNodeId) &&
            slicedNodes.count(edge.toNodeId)) {
            subEdges.push_back(edge);
        }
    }
    return { subNodes, subEdges };
}

void SliceEngine::buildGraphStructures() {
    // 清空
    reverseCtrlAdj.clear();
    reverseDataAdj.clear();
    forwardCtrlAdj.clear();
    forwardDataAdj.clear();

    for (auto &e : edges) {
        int from = e.fromNodeId;
        int to   = e.toNodeId;

        // 这里 e.edgeType 要么是 "control" 要么是 "data"
        // 你可以在 ControlFlowExtractor::addEdge(...) 就给 e 设置好
        if (e.type.find("control")) {
            forwardCtrlAdj.insert({ from, to });
            reverseCtrlAdj.insert({ to, from });
        } else if (e.type.find("data")) {
            forwardDataAdj.insert({ from, to });
            reverseDataAdj.insert({ to, from });
        } else {
            // unknown, do nothing
        }
    }
}


/// 判断节点是否与 sliceVars 有交集(定义/使用)
bool SliceEngine::isRelevantToSliceVars(const CFGNode& node) const {
    // 1) 先判断 genVars
    for (auto &g : node.genVars) {
        // 让 g, sliceVars 中任意一个 var 只要出现“子串”关系，即可认为是相关
        // 注意：g, var 都是 cstring -> 转成 std::string 做 find
        std::string gg{g};
        for (auto &sv : sliceVars) {
            std::string ssv{sv};
            if (gg.find(ssv) != std::string::npos) {
                return true;
            }
        }
    }
    // 2) 再判断 useVars
    for (auto &u : node.useVars) {
        std::string uu{u};
        for (auto &sv : sliceVars) {
            std::string ssv{sv};
            if (uu.find(ssv) != std::string::npos) {
                return true;
            }
        }
    }
    return false;
}

bool SliceEngine::isControlNode(const CFGNode& node) {
    return node.type == NodeType::CONDITION ||
                node.type == NodeType::TABLE      ||
                node.type == NodeType::ACTION     ||
                node.type == NodeType::DECLARATION ||
                node.type == NodeType::EXIT ||
                node.type == NodeType::PARSER ||
                node.type == NodeType::CONTROL ||
                node.type == NodeType::PARSE_STATE ||
                node.type == NodeType::SWITCH;
}

/// 当在切片时, 对于控制节点( e.g. if(...) ) 是否应保留
/// 例如: backward 切片时, child 要保留, 父是 condition -> 父也应该保留(控制依赖)
///       forward 切片时, parent 要保留, child 也是 condition -> child 也应该保留
bool SliceEngine::shouldKeepControlNode(int parentId, int childId, bool isForward) {
    // 检查 parent 和 child 节点是否存在
    auto pIt = nodes.find(parentId);
    auto cIt = nodes.find(childId);
    if (pIt == nodes.end() || cIt == nodes.end()) {
        return false;
    }
    const CFGNode &parentNode = pIt->second;
    const CFGNode &childNode  = cIt->second;

    if (!isForward) {
        // 后向切片：子节点在切片中，且父节点是控制节点，则保留父节点
        if (slicedNodes.count(childId) && isControlNode(parentNode)) {
            return true;
        }
    } else {
        // 前向切片：父节点在切片中，且子节点是控制节点，则保留子节点
        if (slicedNodes.count(parentId) && isControlNode(childNode)) {
            return true;
        }
    }

    // 新增逻辑：递归保留控制依赖链
    // 后向切片时，保留父控制节点的父控制节点
    // 递归保留控制依赖链
    if (!isForward && isControlNode(parentNode)) {
        // 递归检查父控制节点
        for (auto it = reverseCtrlAdj.equal_range(parentId).first;
             it != reverseCtrlAdj.equal_range(parentId).second; ++it) {
            int grandParentId = it->second;
            if (!slicedNodes.count(grandParentId)) {
                slicedNodes.insert(grandParentId);
                // 可以选择将祖父节点加入工作列表，继续处理
                return true;
            }
        }
    }
    return false;
}

std::vector<int> SliceEngine::getAdjacentNodes(int nodeId, bool backward) const {
    std::vector<int> adjacents;
    if (backward) {
        // 后向切片：获取父节点
        auto rangeCtrl = reverseCtrlAdj.equal_range(nodeId);
        for (auto it = rangeCtrl.first; it != rangeCtrl.second; ++it) {
            adjacents.push_back(it->second);
        }
        auto rangeData = reverseDataAdj.equal_range(nodeId);
        for (auto it = rangeData.first; it != rangeData.second; ++it) {
            adjacents.push_back(it->second);
        }
    }
    else {
        // 前向切片：获取子节点
        auto rangeCtrl = forwardCtrlAdj.equal_range(nodeId);
        for (auto it = rangeCtrl.first; it != rangeCtrl.second; ++it) {
            adjacents.push_back(it->second);
        }
        auto rangeData = forwardDataAdj.equal_range(nodeId);
        for (auto it = rangeData.first; it != rangeData.second; ++it) {
            adjacents.push_back(it->second);
        }
    }
    return adjacents;
}

// 判断是否应保留某个 adj
bool SliceEngine::shouldKeepNode(int childId, int parentId) const {
    // child 在后向切片中是“使用者”或“后续语句”；
    // parent 是 child 的上游节点（可能是定义者、控制节点、或顺序前驱）。

    const CFGNode &parentNode = nodes.at(parentId);
    const CFGNode &childNode  = nodes.at(childId);

    // 1) 如果 parentNode 与切片变量直接相关 => 保留
    if (isRelevantToSliceVars(parentNode)) {
        return true;
    }

    // 2) 如果 parentNode 是控制节点（例如 if/switch/table/parser...） => 保留
    //    这样可以把高层控制结构也带进切片
    if (isControlNode(parentNode)) {
        return true;
    }

    // 3) 若 parentNode 的 genVars 与 childNode 的 useVars 有交集 => 保留
    //    这代表：child 用到了 parent 定义的变量
    //    后向切片时: child.useVars ∩ parent.genVars != ∅
    for (auto &useVar : childNode.useVars) {
        if (parentNode.genVars.find(useVar) != parentNode.genVars.end()) {
            return true;
        }
    }

    // 4) 其它情况 => 不保留
    //    可能是顺序前驱语句，但既不控制 child，也不定义 child 用到的变量，也不相关于切片变量
    return false;
}


std::vector<int> SliceEngine::getParents(int nodeId) {
    std::vector<int> result;

    // data
    auto rangeData = reverseDataAdj.equal_range(nodeId);
    for (auto it = rangeData.first; it != rangeData.second; ++it) {
        result.push_back(it->second);
    }
    // sequential
    auto rangeSeq = reverseSeqAdj.equal_range(nodeId);
    for (auto it = rangeSeq.first; it != rangeSeq.second; ++it) {
        result.push_back(it->second);
    }
    // control
    auto rangeCtrl = reverseCtrlAdj.equal_range(nodeId);
    for (auto it = rangeCtrl.first; it != rangeCtrl.second; ++it) {
        result.push_back(it->second);
    }

    return result;
}


// void SliceEngine::doSlice(bool backward) {
//     visited_.clear();
//
//     // 1) 初始化
//     for (auto &kv : nodes) {
//         int nodeId = kv.first;
//         if (isRelevantToSliceVars(kv.second)) {
//             visited_[nodeId] = VisitStatus::MustKeep;
//             slicedNodes.insert(nodeId);
//         } else {
//             visited_[nodeId] = VisitStatus::NotVisited;
//         }
//     }
//
//     // 2) 初始化队列
//     std::queue<int> worklist;
//     for (auto &kv : visited_) {
//         if (kv.second == VisitStatus::MustKeep) {
//             worklist.push(kv.first);
//         }
//     }
//
//     // 3) BFS/DFS
//     while (!worklist.empty()) {
//         int current = worklist.front();
//         worklist.pop();
//
//         // 后向 => 父节点; 前向 => 子节点
//         std::vector<int> adjNodes = (backward ? getParents(current)
//                                               : getAdjacentNodes(current, /*backward=*/false));
//
//         for (int adj : adjNodes) {
//             auto st = visited_.find(adj);
//             if (st == visited_.end()) {
//                 // 如果没在 visited_ 里, 初始化
//                 visited_[adj] = VisitStatus::NotVisited;
//             }
//
//             // 当前是 mustKeep => 如果 shouldKeepNode(current, adj) => adj mustKeep
//             // 否则 skipButContinue
//             if (visited_[adj] == VisitStatus::NotVisited) {
//                 if (shouldKeepNode(current, adj, backward)) {
//                     visited_[adj] = VisitStatus::MustKeep;
//                     slicedNodes.insert(adj);
//                     worklist.push(adj);
//                 } else {
//                     visited_[adj] = VisitStatus::SkipButContinue;
//                     worklist.push(adj);
//                 }
//             } else if (visited_[adj] == VisitStatus::SkipButContinue) {
//                 // 若发现 now we should keep => do it
//                 if (shouldKeepNode(current, adj, backward)) {
//                     visited_[adj] = VisitStatus::MustKeep;
//                     slicedNodes.insert(adj);
//                     worklist.push(adj);
//                 } else {
//                     // 仍然 skipButContinue, 但要继续往上/下遍历
//                     worklist.push(adj);
//                 }
//             } else if (visited_[adj] == VisitStatus::MustKeep) {
//                 // do nothing
//             }
//         }
//     }
// }

void SliceEngine::doBackwardSlice() {
    visited_.clear();
    // 1) 初始化
    for (auto &kv : nodes) {
        int nodeId = kv.first;
        if (isRelevantToSliceVars(kv.second)) {
            visited_[nodeId] = VisitStatus::MustKeep;
            slicedNodes.insert(nodeId);
        } else {
            visited_[nodeId] = VisitStatus::NotVisited;
        }
    }
    // 2) init queue
    std::queue<int> q;
    for (auto &kv : visited_) {
        if (kv.second == VisitStatus::MustKeep) {
            q.push(kv.first);
        }
    }
    // 3) BFS
    while (!q.empty()) {
        int current = q.front(); q.pop();

        // gather parents from reverseDataAdj, reverseSeqAdj, reverseCtrlAdj
        std::vector<int> parents;
        {
            auto range = reverseDataAdj.equal_range(current);
            for (auto it=range.first; it!=range.second; ++it) {
                parents.push_back(it->second);
            }
        }
        {
            auto range = reverseSeqAdj.equal_range(current);
            for (auto it=range.first; it!=range.second; ++it) {
                parents.push_back(it->second);
            }
        }
        {
            auto range = reverseCtrlAdj.equal_range(current);
            for (auto it=range.first; it!=range.second; ++it) {
                parents.push_back(it->second);
            }
        }

        for (auto p : parents) {
            if (visited_[p] == VisitStatus::NotVisited) {
                if (shouldKeepNode(current, p)) {
                    visited_[p] = VisitStatus::MustKeep;
                    slicedNodes.insert(p);
                    q.push(p);
                } else {
                    visited_[p] = VisitStatus::SkipButContinue;
                    q.push(p);
                }
            }
            else if (visited_[p] == VisitStatus::SkipButContinue) {
                // see if we now want to upgrade it to MustKeep
                if (shouldKeepNode(current, p)) {
                    visited_[p] = VisitStatus::MustKeep;
                    slicedNodes.insert(p);
                    q.push(p);
                } else {
                    q.push(p);  // keep exploring
                }
            }
            // if MustKeep => do nothing
        }
    }
}

// 获取切片后使用到的所有变量
std::set<std::string> SliceEngine::getUsedVariables() const {
    std::set<std::string> usedVars;
    for (const auto& nodeId : slicedNodes) {
        auto it = nodes.find(nodeId);
        if (it != nodes.end()) {
            const CFGNode& node = it->second;
            // 收集 useVars
            for (const auto& var : node.useVars) {
                usedVars.insert(std::string{var});
            }
            // 收集 genVars
            for (const auto& var : node.genVars) {
                usedVars.insert(std::string{var});
            }
        }
    }
    return usedVars;
}