//
// Created by smy on 2025/1/17.
//

#include "pdg_compute.h"

#include <queue>
#include <nlohmann/json.hpp>

std::set<int> PDGCompute::slice(std::vector<cstring> &varNames, bool forward) {
    // 0) 如果 varNames 为空，可能返回空集或所有节点(视需求)；这里假设返回空集
    if (varNames.empty()) {
        return {};
    }
    for (auto &v : varNames) {
        std::cout << "Slice for variable: " << v << std::endl;
    }
    // 1) 找到"种子节点"(seed nodes)
    //    规则: 只要 useVars 或 defVars 里包含了 varNames 中的任意一个，则是seed
    std::set<int> seedNodes;
    for (auto &kv : allNodes) {
        int nodeId = kv.first;
        const CFGNode &nd = kv.second;

        // (a) 如果 nd.useVars 有和 varNames 交集, matched = true
        for (auto &v : varNames) {
            // if (nd.useVars.count(v) > 0) {
            //     seedNodes.insert(nodeId);
            // }
            if (nd.genVars.count(v) > 0) {
                seedNodes.insert(nodeId);
            }
        }
    }

    for (auto &id : seedNodes) {
        std::cout << "Seed Node: " << id << " => " << allNodes.at(id).code << std::endl;
    }

    // 2) 依据 forward 与否, 做遍历(DFS or BFS)
    std::set<int> visited; // 记录切片内所有节点
    std::stack<int> stack; // DFS栈

    // 把 seedNodes 放入栈
    for (int sid : seedNodes) {
        stack.push(sid);
        visited.insert(sid);
    }

    // 3) 开始遍历
    while (!stack.empty()) {
        int cur = stack.top();
        stack.pop();

        if (!forward) {
            // 后向切片 => 使用 PDG_inEdges
            auto it = PDG_inEdges.find(cur);
            if (it != PDG_inEdges.end()) {
                for (int pred : it->second) {
                    if (visited.find(pred) == visited.end()) {
                        // 1) 将 pred 加入切片
                        visited.insert(pred);
                        stack.push(pred);

                        // 2) 打印调试信息(后向：pred -> cur)
                        //    首先获取 predNode / curNode 信息
                        auto predNodeIt = allNodes.find(pred);
                        auto curNodeIt  = allNodes.find(cur);
                        if (predNodeIt != allNodes.end() && curNodeIt != allNodes.end()) {
                            const CFGNode &predNd = predNodeIt->second;
                            const CFGNode &curNd  = curNodeIt->second;

                            // （示例）找是否有 dataEdges: pred->cur
                            bool isDataEdge = false;
                            for (auto &e : dataEdges) {
                                if (e.fromNodeId == pred && e.toNodeId == cur) {
                                    isDataEdge = true;
                                    break;
                                }
                            }
                            // （示例）找是否有 ctrlEdges: pred->cur
                            bool isCtrlEdge = false;
                            if (!isDataEdge) { // 若优先判断data
                                for (auto &e : ctrlEdges) {
                                    if (e.fromNodeId == pred && e.toNodeId == cur) {
                                        isCtrlEdge = true;
                                        break;
                                    }
                                }
                            }

                            // 如果是数据依赖
                            if (isDataEdge) {
                                // 找出 predNd.genVars ∩ curNd.useVars
                                std::set<cstring> intersection;
                                for (auto &gv : predNd.genVars) {
                                    if (curNd.useVars.count(gv) > 0) {
                                        intersection.insert(gv);
                                    }
                                }
                                std::cout << "[BackwardSlice] Add predNode: ("
                                          << pred << ") \"" << predNd.name << "\""
                                          << " => curNode: (" << cur << ") \""
                                          << curNd.name << "\" "
                                          << "[DATA edge], sharedVars={";
                                for (auto &v : intersection) {
                                    std::cout << v << " ";
                                }
                                std::cout << "}\n";
                            }
                            // 如果是控制依赖
                            else if (isCtrlEdge) {
                                std::cout << "[BackwardSlice] Add predNode: ("
                                          << pred << ") \"" << predNd.name << "\""
                                          << " => curNode: (" << cur << ") \""
                                          << curNd.name << "\" "
                                          << "[CONTROL edge]\n";
                            } else {
                                // 可能既不在 dataEdges 也不在 ctrlEdges（视你的实现）
                                std::cout << "[BackwardSlice] Add predNode: ("
                                          << pred << ") \"" << predNd.name << "\""
                                          << " => curNode: (" << cur << ") \""
                                          << curNd.name << "\" "
                                          << "[UNKNOWN edge]\n";
                            }
                        }
                    }
                }
            }
        } else {
            // 前向切片 => 使用 PDG_outEdges
            auto it = PDG_outEdges.find(cur);
            if (it != PDG_outEdges.end()) {
                for (int succ : it->second) {
                    if (visited.find(succ) == visited.end()) {
                        // 1) 将 succ 加入切片
                        visited.insert(succ);
                        stack.push(succ);

                        // 2) 打印调试信息(前向：cur -> succ)
                        auto curNodeIt  = allNodes.find(cur);
                        auto succNodeIt = allNodes.find(succ);
                        if (curNodeIt != allNodes.end() && succNodeIt != allNodes.end()) {
                            const CFGNode &curNd  = curNodeIt->second;
                            const CFGNode &succNd = succNodeIt->second;

                            // 判断 dataEdges / ctrlEdges
                            bool isDataEdge = false;
                            for (auto &e : dataEdges) {
                                if (e.fromNodeId == cur && e.toNodeId == succ) {
                                    isDataEdge = true;
                                    break;
                                }
                            }
                            bool isCtrlEdge = false;
                            if (!isDataEdge) {
                                for (auto &e : ctrlEdges) {
                                    if (e.fromNodeId == cur && e.toNodeId == succ) {
                                        isCtrlEdge = true;
                                        break;
                                    }
                                }
                            }

                            if (isDataEdge) {
                                // 前向：curNd.genVars ∩ succNd.useVars
                                std::set<cstring> intersection;
                                for (auto &gv : curNd.genVars) {
                                    if (succNd.useVars.count(gv) > 0) {
                                        intersection.insert(gv);
                                    }
                                }
                                std::cout << "[ForwardSlice] Add curNode: ("
                                          << cur << ") \"" << curNd.name << "\""
                                          << " => succNode: (" << succ << ") \""
                                          << succNd.name << "\" "
                                          << "[DATA edge], sharedVars={";
                                for (auto &v : intersection) {
                                    std::cout << v << " ";
                                }
                                std::cout << "}\n";
                            } else if (isCtrlEdge) {
                                std::cout << "[ForwardSlice] Add curNode: ("
                                          << cur << ") \"" << curNd.name << "\""
                                          << " => succNode: (" << succ << ") \""
                                          << succNd.name << "\" "
                                          << "[CONTROL edge]\n";
                            } else {
                                std::cout << "[ForwardSlice] Add curNode: ("
                                          << cur << ") \"" << curNd.name << "\""
                                          << " => succNode: (" << succ << ") \""
                                          << succNd.name << "\" "
                                          << "[UNKNOWN edge]\n";
                            }
                        }
                    }
                }
            }
        }
    }

    // 4) visited 就是本次与 varNames 相关的切片节点集合
    return visited;
}



void PDGCompute::buildPDG() {
    // 先清空/初始化
    PDG_inEdges.clear();
    PDG_outEdges.clear();

    // 1) 对所有 nodeId，先给 PDG_inEdges[nodeId] / PDG_outEdges[nodeId] 初始化空
    for (auto &kv : allNodes) {
        int nid = kv.first;
        PDG_inEdges[nid] = {};
        PDG_outEdges[nid] = {};
    }

    // (a) 控制边
    for (auto &e : ctrlEdges) {
        int from = e.fromNodeId;
        int to   = e.toNodeId;
        PDG_inEdges[to].push_back(from);
        PDG_outEdges[from].push_back(to);
    }

    // (b) 数据边
    for (auto &e : dataEdges) {
        int from = e.fromNodeId;
        int to   = e.toNodeId;
        PDG_inEdges[to].push_back(from);
        PDG_outEdges[from].push_back(to);
    }
    // 至此, PDG_inEdges 就构建完毕:
    // PDG_inEdges[x] = 所有 "x" 依赖的节点(无论是控制依赖还是数据依赖).
}

void PDGCompute::exportSliceToDot(const std::set<int> &sliceNodes,
                                  const std::string &dotFile) const {
    std::ofstream outF(dotFile);
    if (!outF.is_open()) {
        std::cerr << "无法打开 " << dotFile << " 写入DOT" << std::endl;
        return;
    }
    outF << "digraph slice {\n";
    outF << "  node [shape=box];\n";

    // 1) 输出节点
    for (int nid : sliceNodes) {
        auto ndIt = allNodes.find(nid);
        if (ndIt == allNodes.end()) continue;
        const auto &nd = ndIt->second;
        outF << "  node" << nd.id << " [label=\"" << nd.name << "\"];\n";
    }

    // 2) 输出在 sliceNodes 内部的依赖边
    //    不区分 ctrlEdges / dataEdges，这里都输出
    for (auto &e : ctrlEdges) {
        if (sliceNodes.count(e.fromNodeId) && sliceNodes.count(e.toNodeId)) {
            outF << "  node" << e.fromNodeId << " -> node" << e.toNodeId
                 << " [color=red, style=bold];\n";
        }
    }
    for (auto &e : dataEdges) {
        if (sliceNodes.count(e.fromNodeId) && sliceNodes.count(e.toNodeId)) {
            outF << "  node" << e.fromNodeId << " -> node" << e.toNodeId
                 << " [color=blue, style=dashed];\n";
        }
    }

    outF << "}\n";
    outF.close();
}


void PDGCompute::runAllPDGTests() {
    std::cout << "===== Running All Slicing (LT-based) Tests =====\n";


    std::cout << "===== All PDG Slicing Tests Finished =====\n";
}
