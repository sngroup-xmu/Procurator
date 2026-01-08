// test_slicing.cpp

#include <iostream>
#include "test_slicing.h"
// #include "sclicing_engine.h"

#include <fstream>
#include <nlohmann/json.hpp>

/**
 * 将切片后的子图写到 JSON 文件：包括 subNodes/subEdges 以及对应的 IR Node IDs
 */
static void writeSlicedGraphToJson(const std::map<int, CFGNode>& subNodes,
                                   const std::vector<CFGEdge>& subEdges,
                                   const std::unordered_map<int, std::set<int>>& irNodeIdsMap,
                                   const std::string& outputFile)
{
    nlohmann::json outputJson;

    // (1) 输出节点
    for (auto &kv : subNodes) {
        const auto &nd = kv.second;
        nlohmann::json jn;
        jn["id"]   = nd.id;
        jn["name"] = std::string(nd.name.c_str());
        jn["type"] = ControlFlowExtractor::nodeTypeToString(nd.type);
        jn["code"] = std::string(nd.code.c_str());

        // 定义的变量
        {
            nlohmann::json arr = nlohmann::json::array();
            for (auto &dv : nd.genVars) {
                arr.push_back(std::string(dv.c_str()));
            }
            jn["defines"] = arr;
        }
        // 使用的变量
        {
            nlohmann::json arr = nlohmann::json::array();
            for (auto &uv : nd.useVars) {
                arr.push_back(std::string(uv.c_str()));
            }
            jn["uses"] = arr;
        }

        // (2) 该 CFG 节点对应的 IR Node IDs
        {
            nlohmann::json idArr = nlohmann::json::array();
            // 如果该 cfgId 在 irNodeIdsMap 里
            auto it = irNodeIdsMap.find(nd.id);
            if (it != irNodeIdsMap.end()) {
                for (auto oneIrId : it->second) {
                    idArr.push_back(oneIrId);
                }
            }
            jn["ir_ids"] = idArr;
        }

        outputJson["nodes"].push_back(jn);
    }

    // (3) 输出边
    for (auto &e : subEdges) {
        nlohmann::json je;
        je["from"]  = e.fromNodeId;
        je["to"]    = e.toNodeId;
        je["label"] = std::string(e.label.c_str());
        je["type"]  = e.type;
        outputJson["edges"].push_back(je);
    }

    // 写入 JSON 文件
    std::ofstream ofs(outputFile);
    if (!ofs.is_open()) {
        std::cerr << "Cannot open file: " << outputFile << std::endl;
        return;
    }
    ofs << outputJson.dump(2) << std::endl;
    ofs.close();

    std::cout << "Sliced result wrote into " << outputFile << std::endl;
}

/**
 * 辅助函数：收集subNodes对应的 IR node id 并返回
 */
std::unordered_set<int> SlicingTest::collectIrIdsFromSubNodes(
    const std::map<int, CFGNode> &subNodes) const
{
    std::unordered_set<int> result;
    // 遍历 subNodes
    for (auto &pair : subNodes) {
        int cfgId = pair.first;  // or pair.second.id
        // 在 irNodeIdsMap 中找
        auto it = irNodeIdsMap.find(cfgId);
        if (it != irNodeIdsMap.end()) {
            // it->second 是 std::set<int>
            for (auto irid : it->second) {
                result.insert(irid);
            }
        }
    }
    return result;
}

SlicingTest::SlicingTest(const std::unordered_map<int, CFGNode> &nodeMap,
                         const std::vector<CFGEdge> &edgeVec,
                         std::unordered_map<int, std::set<int>>& irNodeIds, // <-- 新增
                         cstring &path)
    : netChainNodes(nodeMap)
    , netChainEdges(edgeVec)
    , irNodeIdsMap(irNodeIds)    // 保存引用
    , path(path)
{
    // -------------------------
    // 0. 构造 slicingEngine
    // -------------------------
    SliceEngine sliceEngine(netChainNodes, netChainEdges);

    // // (A) 例1: 关注 hdr.ipv4.dstAddr
    // {
    //     std::set<cstring> varNames = {"hdr.ipv4.dstAddr","standard_metadata.egress_spec"};
    //     sliceEngine.setSlicingCriteria(varNames);
    //
    //     // forward
    //     sliceEngine.performForwardSlice();
    //     auto [subNodesF, subEdgesF] = sliceEngine.buildSlicedGraph();
    //     writeSlicedGraphToJson(subNodesF, subEdgesF, irNodeIdsMap,
    //                            this->path + "/slice_forward_dstAddr.json");
    //
    //     // backward
    //     sliceEngine.performBackwardSlice();
    //     auto [subNodesB, subEdgesB] = sliceEngine.buildSlicedGraph();
    //     writeSlicedGraphToJson(subNodesB, subEdgesB, irNodeIdsMap,
    //                            this->path + "/slice_backward_dstAddr.json");
    //     // 收集 IR ids
    //     auto subIrIds = collectIrIdsFromSubNodes(subNodesB);
    //     // 可以把它并入 unionAllRetainedIds
    //     for (auto id : subIrIds) {
    //         unionAllRetainedIds.insert(id);
    //     }
    // }
    //
    // // (B) 例2: meta.location.index, hdr.nc_hdr.value
    // {
    //     std::set<cstring> varNames = {"meta.location.index", "hdr.nc_hdr.value", "standard_metadata.egress_spec"};
    //     sliceEngine.setSlicingCriteria(varNames);
    //
    //     sliceEngine.performForwardSlice();
    //     auto [subNodesF, subEdgesF] = sliceEngine.buildSlicedGraph();
    //     writeSlicedGraphToJson(subNodesF, subEdgesF, irNodeIdsMap,
    //                            this->path + "/slice_forward_locAndVal.json");
    //
    //     sliceEngine.performBackwardSlice();
    //     auto [subNodesB, subEdgesB] = sliceEngine.buildSlicedGraph();
    //     writeSlicedGraphToJson(subNodesB, subEdgesB, irNodeIdsMap,
    //                            this->path + "/slice_backward_locAndVal.json");
    //
    // }
    //
    // // (C) 例3: sequence_reg
    // {
    //     std::set<cstring> varNames = {"sequence_reg", "standard_metadata.egress_spec"};
    //     sliceEngine.setSlicingCriteria(varNames);
    //
    //     sliceEngine.performForwardSlice();
    //     auto [subNodesF, subEdgesF] = sliceEngine.buildSlicedGraph();
    //     writeSlicedGraphToJson(subNodesF, subEdgesF, irNodeIdsMap,
    //                            this->path + "/slice_forward_sequence_reg.json");
    //
    //     sliceEngine.performBackwardSlice();
    //     auto [subNodesB, subEdgesB] = sliceEngine.buildSlicedGraph();
    //     writeSlicedGraphToJson(subNodesB, subEdgesB, irNodeIdsMap,
    //                            this->path + "/slice_backward_sequence_reg.json");
    // }
    // -------------------------
    // (D) 例4: 关注 hdr.switchv2p.type 和 hdr.switchv2p.key
    // -------------------------
    {
        std::set<cstring> varNames = {"sequence_reg[]"};
        sliceEngine.setSlicingCriteria(varNames);

        // forward
        // sliceEngine.doBackwardSlice();
        // auto [subNodesF, subEdgesF] = sliceEngine.buildSlicedGraph();
        // writeSlicedGraphToJson(subNodesF, subEdgesF, irNodeIdsMap,
        //                        this->path + "/slice_forward_sequence_reg.json");

        // backward
        sliceEngine.doBackwardSlice();
        auto [subNodesB, subEdgesB] = sliceEngine.buildSlicedGraph();
        writeSlicedGraphToJson(subNodesB, subEdgesB, irNodeIdsMap,
                               this->path + "/slice_backward_sequence_reg.json");
    }

    // -------------------------
    // (E) 例5: 关注 ig_md.switchv2p_md.misdelivered 和 ig_md.switchv2p_md.to_gw
    // -------------------------
    {
        std::set<cstring> varNames = {"ig_md.switchv2p_md.misdelivered", "ig_md.switchv2p_md.to_gw"};
        sliceEngine.setSlicingCriteria(varNames);

        // // forward
        // sliceEngine.performForwardSlice();
        // auto [subNodesF, subEdgesF] = sliceEngine.buildSlicedGraph();
        // writeSlicedGraphToJson(subNodesF, subEdgesF, irNodeIdsMap,
        //                        this->path + "/slice_forward_misdelivered_to_gw.json");

        // backward
        sliceEngine.doBackwardSlice();
        auto [subNodesB, subEdgesB] = sliceEngine.buildSlicedGraph();
        writeSlicedGraphToJson(subNodesB, subEdgesB, irNodeIdsMap,
                               this->path + "/slice_backward_misdelivered_to_gw.json");
    }

    // -------------------------
    // (F) 例6: 关注 hdr.ipv4_outter.dst_addr 和 hdr.ipv4_outter.src_addr
    // -------------------------
    {
        std::set<cstring> varNames = {"hdr.ipv4_outter.dst_addr", "hdr.ipv4_outter.src_addr"};
        sliceEngine.setSlicingCriteria(varNames);

        // forward
        // sliceEngine.performForwardSlice();
        // auto [subNodesF, subEdgesF] = sliceEngine.buildSlicedGraph();
        // writeSlicedGraphToJson(subNodesF, subEdgesF, irNodeIdsMap,
        //                        this->path + "/slice_forward_ipv4_outter_dst_src.json");

        // backward
        sliceEngine.doBackwardSlice();
        auto [subNodesB, subEdgesB] = sliceEngine.buildSlicedGraph();
        writeSlicedGraphToJson(subNodesB, subEdgesB, irNodeIdsMap,
                               this->path + "/slice_backward_ipv4_outter_dst_src.json");
    }

    // -------------------------
    // (G) 例7: 关注 hdr.switchv2p.type 和 hdr.switchv2p.key
    // -------------------------
    {
        std::set<cstring> varNames = {"hdr.switchv2p.type", "hdr.switchv2p.key"};
        sliceEngine.setSlicingCriteria(varNames);

        // // forward
        // sliceEngine.performForwardSlice();
        // auto [subNodesF, subEdgesF] = sliceEngine.buildSlicedGraph();
        // writeSlicedGraphToJson(subNodesF, subEdgesF, irNodeIdsMap,
        //                        this->path + "/slice_forward_switchv2p_type_key.json");

        // backward
        sliceEngine.doBackwardSlice();
        auto [subNodesB, subEdgesB] = sliceEngine.buildSlicedGraph();
        writeSlicedGraphToJson(subNodesB, subEdgesB, irNodeIdsMap,
                               this->path + "/slice_backward_switchv2p_type_key.json");
    }

    // -------------------------
    // (H) 例8: 关注 ig_md.switchv2p_md.switch_type 和 ig_md.switchv2p_md.switch_id
    // -------------------------
    {
        std::set<cstring> varNames = {"ig_md.switchv2p_md.switch_type", "ig_md.switchv2p_md.switch_id"};
        sliceEngine.setSlicingCriteria(varNames);

        // forward
        // sliceEngine.performForwardSlice();
        // auto [subNodesF, subEdgesF] = sliceEngine.buildSlicedGraph();
        // writeSlicedGraphToJson(subNodesF, subEdgesF, irNodeIdsMap,
        //                        this->path + "/slice_forward_switch_type_id.json");

        // backward
        sliceEngine.doBackwardSlice();
        auto [subNodesB, subEdgesB] = sliceEngine.buildSlicedGraph();
        writeSlicedGraphToJson(subNodesB, subEdgesB, irNodeIdsMap,
                               this->path + "/slice_backward_switch_type_id.json");
    }
    std::cout << "All slicing tasks done. Please check the output JSON files.\n";
}
