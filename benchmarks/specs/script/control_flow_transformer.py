import json
from collections import defaultdict


def export_tree_json(tree_obj, output_path):
    """
    将 build_condition_tree(...) 构建的树对象写到文件.
    """
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(tree_obj, f, indent=4, ensure_ascii=False)
    print(f"[export_tree_json] 输出树结构到 {output_path}")


class ControlFlowTransformer:
    def __init__(self, json_data, output_path):
        """
        期望的 json_data 结构:
        {
            "nodes": [...],
            "edges": [...]
        }
        nodes 中: { "id": int, "type": str, "code": str, ... }
        edges 中: { "from": int, "to": int, "type": "control" or "data", "label": ... }
        """
        self.json_data = json_data
        self.output_path = output_path
        # 1) 构造节点字典: id -> node
        self.nodes = {}
        for nd in self.json_data.get("nodes", []):
            self.nodes[nd["id"]] = nd

        # 2) 边列表
        self.edges = self.json_data.get("edges", [])

        # 3) 在后面，我们会用到的字段
        self.adj_forward = defaultdict(list)   # node -> list of (succ_id, label)
        self.adj_reverse = defaultdict(list)   # node -> list of (pred_id, label)

        # 我们先建立控制流邻接表(只看 type="control" 的边)
        for e in self.edges:
            if e.get("type","control") == "control":
                f = e["from"]
                t = e["to"]
                lb = e.get("label","")
                self.adj_forward[f].append((t, lb))
                self.adj_reverse[t].append((f, lb))

        self.run_all()

    def merge_consecutive_statements(self):
        """
        1) 将图中连续的STATEMENT节点进行合并，形成STATEMENT_BLOCK.
        2) 更新 self.nodes, self.edges 结构以反映这一变化.
        """
        import copy

        original_nodes = list(self.nodes.values())
        original_edges = copy.deepcopy(self.edges)

        # 建立前向/后向索引(仅control边)
        adj_forward = defaultdict(list)
        adj_reverse = defaultdict(list)
        for e in original_edges:
            if e.get("type", "control") == "control":
                f = e["from"]
                t = e["to"]
                lb = e.get("label","")
                adj_forward[f].append((t, lb))
                adj_reverse[t].append((f, lb))

        # 用 set 存储 edges，便于增删
        edge_set = set()
        for e in original_edges:
            fr = e["from"]
            to = e["to"]
            lb = e.get("label","")
            et = e.get("type","control")
            edge_set.add((fr,to,lb,et))

        def remove_edge(fr, to, lb="", et="control"):
            if (fr,to,lb,et) in edge_set:
                edge_set.remove((fr,to,lb,et))

        def add_edge(fr, to, lb="", et="control"):
            edge_set.add((fr,to,lb,et))

        removed = set()
        new_nodes = copy.deepcopy(original_nodes)
        node_map = {n["id"]: n for n in new_nodes}

        def new_node_id(current_nodes):
            if not current_nodes:
                return 0
            return max(nd["id"] for nd in current_nodes) + 1

        for n in new_nodes:
            nid = n["id"]
            ntype = n["type"]
            if ntype != "STATEMENT":
                continue
            if nid in removed:
                continue

            # 从nid开始向后合并
            chain = [nid]
            cur = nid
            while True:
                succs = adj_forward[cur]
                # 必须有且仅有一个后继 & 该后继还是STATEMENT & 未被移除
                if len(succs) == 1:
                    (nx, lb) = succs[0]
                    if nx not in removed:
                        node_next = node_map[nx]
                        if node_next["type"] == "STATEMENT":
                            chain.append(nx)
                            cur = nx
                            continue
                break

            # 如果chain里有多个节点 => 合并
            if len(chain) > 1:
                block_id = new_node_id(new_nodes)
                block_name = f"stmt_block_{block_id}"
                # 拼接 code
                lines = []
                for cid in chain:
                    ccode = node_map[cid].get("code","").strip()
                    if ccode:
                        lines.append(ccode)
                block_code = "\n".join(lines)

                block_node = {
                    "id": block_id,
                    "name": block_name,
                    "type": "STATEMENT_BLOCK",
                    "code": block_code,
                    "defines": [],
                    "uses": []
                }
                new_nodes.append(block_node)

                chain_start = chain[0]
                chain_end   = chain[-1]

                # 找到前驱 & 后继
                preds = adj_reverse[chain_start]
                endsucc = adj_forward[chain_end]

                # 移除 chain内部边
                for i in range(len(chain)-1):
                    f1 = chain[i]
                    t1 = chain[i+1]
                    remove_edge(f1,t1,"","control")

                # 移除 chain_end->后继
                for (sid,lb) in endsucc:
                    remove_edge(chain_end, sid, lb,"control")

                # 移除 preds->chain_start
                for (pid,plb) in preds:
                    remove_edge(pid,chain_start,plb,"control")

                # 新增 preds->block_node
                for (pid,plb) in preds:
                    add_edge(pid,block_id,plb,"control")

                # 新增 block_node->endSucc
                for (sid,lb) in endsucc:
                    add_edge(block_id, sid, lb,"control")

                # 标记被合并的
                for c2 in chain:
                    removed.add(c2)

        # 重构 self.nodes, self.edges
        final_nodes = []
        removed_set = set(removed)
        for nd in new_nodes:
            if nd["id"] not in removed_set:
                final_nodes.append(nd)

        new_edges = []
        for (fr,to,lb,et) in edge_set:
            e_dict = {
                "from": fr,
                "to": to,
                "type": et
            }
            if lb:
                e_dict["label"] = lb
            new_edges.append(e_dict)

        # 覆盖
        self.nodes.clear()
        for nd in final_nodes:
            self.nodes[nd["id"]] = nd
        self.edges = new_edges

        print(f"[merge_consecutive_statements] done. Merged {len(removed)} old STATEMENT nodes.")

        # 刷新 adj_forward / adj_reverse
        self._rebuild_adjacency()

    def _rebuild_adjacency(self):
        """
        内部函数，用来在 nodes/edges 更新后，重建 adj_forward, adj_reverse
        """
        self.adj_forward.clear()
        self.adj_reverse.clear()
        for e in self.edges:
            if e.get("type","control")=="control":
                f = e["from"]
                t = e["to"]
                lb = e.get("label","")
                self.adj_forward[f].append((t, lb))
                self.adj_reverse[t].append((f, lb))

    def build_condition_tree(self, root_id=0):
        """
        从 root_id 出发，递归构建一个"树状结构"（无公共后继）。
        该函数不做合并节点的操作，因为你说没有公共后继点。
        多个分支 => 同层兄弟，互不交叉。

        返回的树结构示例:
        {
          "type": "...",        # e.g. "CONDITION" / "STATEMENT_BLOCK" / ...
          "id": <node_id>,
          "code": "xxx",        # 该节点的code
          "branches": [         # 仅在type=CONDITION或TABLE时可能出现
            {
              "label": "xx",
              "child": <subtree dict>
            },
            ...
          ],
          "children": [         # 顺序上的后续
            <subtree>, <subtree> ...
          ]
        }
        这里 "children" 代表同一层中的后续顺序节点,
        而 "branches" 只在 condition/table 下存储分支.
        """
        visited = set()  # 防止环
        return self._build_subtree(root_id, visited)

    def _build_subtree(self, node_id, visited):
        if node_id in visited:
            # 如果是树结构，本不应出现环，但这里以防万一
            return None
        visited.add(node_id)

        node = self.nodes.get(node_id, None)
        if not node:
            return None

        ntype = node["type"]
        ncode = node.get("code","")

        # 获取控制流后继
        succs = self.adj_forward[node_id]

        # 如果是 CONDITION / TABLE，有多分支 => 我们把分支当做 branches
        # 在这种树结构里，每个分支不会再合流
        if ntype in ["CONDITION", "TABLE"]:
            # gather branches
            # each successor is (sid, label)
            # 这里无公共后继，所以每个分支都通向不同子树
            branches_data = []
            for (sid, slb) in succs:
                child_subtree = self._build_subtree(sid, visited)
                if child_subtree:
                    branches_data.append({
                        "label": slb,
                        "child": child_subtree
                    })
            # Condition可能仍有“同层后继”吗？
            # 在典型树中, Condition本身就分支走向, 不再有多余顺序后继.
            # 视具体p4c产出的CFG结构而定. 如果你要把 Condition 后面再跟节点当 siblings,
            # 可以再单独处理. 这里假设 Condition所有后继都是分支.
            return {
                "type": ntype,
                "id": node_id,
                "code": ncode,
                "branches": branches_data
            }
        else:
            # 如果是 STATEMENT_BLOCK / ACTION / DECLARATION / MERGE(如果有) ...
            # 可能有若干后继, 但在你的描述(树结构)里, 只有**一个**后续, 或0个。
            # 或者可能有多个顺序兄弟(同一层)?
            # 你可以决定 "children" 是否需要.
            # 这里演示: 把所有后继当做 "children" 依序放进去。
            # 这会得到一种深度遍历的树结构.

            children_list = []
            for (sid, slb) in succs:
                # 如果想保留label信息, 也可将slb写入.
                # 不过大多情况下, 对同层顺序的 label可能没有意义.
                sub = self._build_subtree(sid, visited)
                if sub:
                    children_list.append(sub)

            return {
                "type": ntype,
                "id": node_id,
                "code": ncode,
                "children": children_list
            }

    def run_all(self, root_id=0):
        """
        对外接口:
          1) merge_consecutive_statements
          2) build_condition_tree
          3) export_tree_json
        """
        output_tree_path = self.output_path
        # 先合并 statement
        self.merge_consecutive_statements()
        # 然后从root_id开始构造树
        tree_obj = self.build_condition_tree(root_id)
        # 导出
        export_tree_json(tree_obj, output_tree_path)
