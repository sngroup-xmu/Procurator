# 文件: dependency_analyzer.py

import json
from collections import defaultdict, deque

class DependencyAnalyzer:
    def __init__(self, cfg_json):
        """
        cfg_json:
        {
          "nodes": [
             {"id":..., "type":..., "defines": [...], "uses": [...]},
             ...
          ],
          "edges": [
             {"from":..., "to":..., "type": "control"/"data", "label": ...},
             ...
          ]
        }
        """
        self.cfg_json = cfg_json

        # 1) 把节点存到 self.nodes
        self.nodes = {}
        for nd in self.cfg_json.get("nodes", []):
            self.nodes[nd["id"]] = nd

        # 2) 拆分控制流边 / 数据流边 （如果需要的话）
        self.control_edges = []
        self.data_edges = []
        for e in self.cfg_json.get("edges", []):
            et = e.get("type", "control")
            if et == "control":
                self.control_edges.append(e)
            else:
                self.data_edges.append(e)

        # 如果想要控制流可达性判断，可以建邻接表 self.ctrl_forward 等
        # 这里示例中可能不深入

    def find_nodes_defining_var(self, varName):
        """
        返回所有定义了 varName 的节点ID列表。
        这里假设节点里存储 "defines": [var1, var2, ...]。
        """
        result = []
        for nid, node in self.nodes.items():
            defines = node.get("defines", [])
            if varName in defines:
                result.append(nid)
        return result

    def run_analysis_for_vars(self, varList):
        """
        给定一组目标变量 varList (List[str])。
        做 backward-like 分析，找出所有能影响这些变量的变量集合。
        """
        visitedVars = set()
        queueVars = deque()

        # 初始化：把所有目标变量放入队列
        for v in varList:
            visitedVars.add(v)
            queueVars.append(v)

        # BFS/DFS
        while queueVars:
            currentVar = queueVars.popleft()
            # 找到所有定义 currentVar 的节点
            defNodes = self.find_nodes_defining_var(currentVar)

            # 对每个定义节点，看看它 uses 了哪些变量
            for dnid in defNodes:
                uses = self.nodes[dnid].get("uses", [])
                for uv in uses:
                    if uv not in visitedVars:
                        visitedVars.add(uv)
                        queueVars.append(uv)

        return visitedVars


def demo():
    """
    简单演示: 传入多个变量, 看最终能影响到这些变量的所有变量集合
    """
    cfg_data = {
        "nodes": [
            {"id":0, "defines":["a"], "uses":["x","y"]},
            {"id":1, "defines":["b"], "uses":["a","z"]},
            {"id":2, "defines":["c"], "uses":["b"]},
            {"id":3, "defines":["m"], "uses":["n","b"]},
        ],
        "edges": [
            {"from":0, "to":1, "type":"control"},
            {"from":1, "to":2, "type":"control"},
            {"from":2, "to":3, "type":"control"},
        ]
    }

    analyzer = DependencyAnalyzer(cfg_data)
    targetVars = ["c", "m"]  # 我想看谁影响 c 或 m
    influencing = analyzer.run_analysis_for_vars(targetVars)
    print(f"Vars that influence {targetVars}: {influencing}")

if __name__ == "__main__":
    demo()
