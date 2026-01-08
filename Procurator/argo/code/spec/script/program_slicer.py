# 文件: program_slicer.py

import json
from collections import defaultdict, deque
# 假设 dependency_analyzer.py 中定义了 DependencyAnalyzer

class ProgramSlicer:
    def __init__(self, cfg_data, dependency_analyzer):
        self.cfg_data = cfg_data
        self.analyzer = dependency_analyzer

        # 构造 node map
        self.nodes = {}
        for nd in cfg_data.get("nodes", []):
            self.nodes[nd["id"]] = nd

        # 拆分 edges
        self.edges = cfg_data.get("edges", [])
        self.control_edges = [e for e in self.edges if e.get("type","control")=="control"]

        # 建立控制流邻接(如需后面判断 condition 是否通向保留节点)
        self.ctrl_forward = defaultdict(list)
        for e in self.control_edges:
            fr = e["from"]
            to = e["to"]
            lb = e.get("label","")
            self.ctrl_forward[fr].append((to, lb))

    def slice_for_variables(self, varList):
        """
        对一组目标变量 varList 做 backward slicing.
        返回 {"nodes": [...], "edges": [...]} 仅保留相关的节点.
        """
        # 1) 得到能影响这些变量的所有变量
        all_influencing_vars = self.analyzer.run_analysis_for_vars(varList)

        # 2) 找到所有"相关"节点 => 定义/使用中跟 all_influencing_vars 有交集
        relevant_node_ids = set()
        for nid, node in self.nodes.items():
            defines = node.get("defines", [])
            uses = node.get("uses", [])
            if (set(defines) & all_influencing_vars) or (set(uses) & all_influencing_vars):
                relevant_node_ids.add(nid)

        # 3) 如果 node是 CONDITION/TABLE, 只要它后继有节点在 relevant_node_ids，也要保留
        for nid, node in self.nodes.items():
            ntype = node.get("type","")
            if ntype in ["CONDITION","TABLE"]:
                succs = self.ctrl_forward[nid]  # list of (childId, label)
                keep_it = False
                for (childId, lb) in succs:
                    if childId in relevant_node_ids:
                        keep_it = True
                        break
                if keep_it:
                    relevant_node_ids.add(nid)

        # 4) 可选：保留 ENTRY(如果id=0在你的CFG里)
        if 0 in self.nodes:
            relevant_node_ids.add(0)

        # 5) 构建新的 nodes & edges
        sliced_nodes = []
        for nid in relevant_node_ids:
            if nid in self.nodes:
                sliced_nodes.append(self.nodes[nid])

        sliced_edges = []
        for e in self.edges:
            fr = e["from"]
            to = e["to"]
            if (fr in relevant_node_ids) and (to in relevant_node_ids):
                sliced_edges.append(e)

        return {
            "nodes": sliced_nodes,
            "edges": sliced_edges
        }

    def export_slice(self, slice_data, out_path):
        """
        导出切片结果到 JSON
        """
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(slice_data, f, indent=4, ensure_ascii=False)
        print(f"Sliced CFG written to {out_path}")


def demo_slicing():
    # 1) 准备示例 CFG
    cfg_data = {
        "nodes": [
            {"id":0, "type":"ENTRY", "defines":[], "uses":[]},
            {"id":1, "type":"STATEMENT","defines":["a"], "uses":["x","y"]},
            {"id":2, "type":"STATEMENT","defines":["b"], "uses":["a"]},
            {"id":3, "type":"CONDITION","defines":[], "uses":["b"]},
            {"id":4, "type":"STATEMENT","defines":["z"], "uses":["c"]},
            {"id":5, "type":"STATEMENT","defines":["m"], "uses":["n","z"]}
        ],
        "edges": [
            {"from":0,"to":1,"type":"control"},
            {"from":1,"to":2,"type":"control"},
            {"from":2,"to":3,"type":"control","label":"if(b>0)"},
            {"from":2,"to":4,"type":"control","label":"else"},
            {"from":4,"to":5,"type":"control"}
        ]
    }

    # 2) 创建 DependencyAnalyzer (支持多变量)
    from dependency_analyzer import DependencyAnalyzer
    analyzer = DependencyAnalyzer(cfg_data)

    # 3) 创建 ProgramSlicer
    slicer = ProgramSlicer(cfg_data, analyzer)

    # 4) 指定多个变量
    var_list = ["b","z"]

    # 5) 生成切片
    slice_result = slicer.slice_for_variables(var_list)

    # 6) 输出
    slicer.export_slice(slice_result, "multi_var_slice.json")


if __name__=="__main__":
    demo_slicing()
