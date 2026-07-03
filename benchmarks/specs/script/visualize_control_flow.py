#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
visualize_cf_bfs.py

从 JSON 文件中读取控制流信息 (type="control")，使用 BFS 层次布局减少节点重叠，
并用 Matplotlib 直接输出高分辨率图片。可选生成 .dot 文件备用。

依赖：
  pip install networkx matplotlib pydot

用法示例：
  python visualize_cf_bfs.py -i cfg.json -o cfg.png --dot cfg.dot
"""

import json
import argparse
import os
import networkx as nx
import matplotlib.pyplot as plt

def sanitize_label(label: str) -> str:
    """清理标签中可能的换行和特殊字符，避免渲染混乱。"""
    label = label.replace("\n", " ")
    label = label.replace("\"", "\\\"")
    return label

def build_control_flow_graph(json_data):
    """
    读取 JSON 中的 nodes、edges，并构造一个 NetworkX DiGraph。
    只保留 'type' == 'control' 的边，节点属性包括简单的 label。
    """
    G = nx.DiGraph()
    nodes = json_data.get("nodes", [])
    edges = json_data.get("edges", [])

    # 添加节点
    for node in nodes:
        node_id = node["id"]
        node_type = node.get("type", "")
        node_name = node.get("name", "")
        node_code = node.get("code", "").strip()

        # label: 简短信息 (可根据需要裁剪 code)
        lines = [f"[{node_id}] {node_type}"]
        if node_name:
            lines.append(f"NAME: {node_name}")
        if node_code:
            short_code = node_code[:40] + ("..." if len(node_code)>40 else "")
            lines.append(f"CODE: {short_code}")
        label_str = "\\n".join(lines)
        label_str = sanitize_label(label_str)

        G.add_node(node_id, label=label_str)

    # 添加控制流边
    for edge in edges:
        if edge.get("type") == "control":
            from_id = edge["from"]
            to_id = edge["to"]
            elabel = edge.get("label", "")
            if from_id not in G.nodes or to_id not in G.nodes:
                continue
            G.add_edge(from_id, to_id, label=elabel)

    return G

def bfs_level_layout(G, start=0, layer_dist_x=4.0, layer_dist_y=3.0):
    """
    对有向图 G 从 start 节点做 BFS，返回一个 dict: {node: (x, y)} 作为节点坐标。
    - layer_dist_x: 同层节点之间的水平间隔
    - layer_dist_y: 不同层之间的垂直间隔
    使得节点按照层次在纵向(或横向)分布，以减少重叠。
    """
    from collections import deque

    if start not in G.nodes:
        # 如果 start 不在图中，则空布局
        return {}

    visited = set()
    queue = deque()
    queue.append((start, 0))  # (node, depth)
    visited.add(start)

    levels = {}  # node -> depth
    levels[start] = 0

    # BFS
    while queue:
        node, depth = queue.popleft()
        # 遍历后继
        for nxt in G.successors(node):
            if nxt not in visited:
                visited.add(nxt)
                levels[nxt] = depth + 1
                queue.append((nxt, depth + 1))

    # 根据 level 分组
    level_map = {}
    for n, lvl in levels.items():
        level_map.setdefault(lvl, []).append(n)

    # 计算每层节点坐标
    pos = {}
    # 这里让 y = -level * layer_dist_y (自上而下), x 不同节点分散
    # 也可反过来 x=level, y=some distribution
    for lvl, nodelist in level_map.items():
        # 同层节点排一行
        # x 起始可从 0 开始，逐个间隔 layer_dist_x
        for i, nd in enumerate(nodelist):
            x = i * layer_dist_x
            y = -lvl * layer_dist_y
            pos[nd] = (x, y)

    # 对于未在 BFS 中出现的节点(可能与 start 不连通)，放在更深层
    # 简单处理：找出剩余节点给个独立的层
    max_depth = max(levels.values()) if levels else 0
    leftover = [n for n in G.nodes if n not in levels]
    # 给这些节点层号 = max_depth + 1
    # 并依次排开
    if leftover:
        lvl = max_depth + 1
        for i, nd in enumerate(leftover):
            x = i * layer_dist_x
            y = -lvl * layer_dist_y
            pos[nd] = (x, y)

    return pos

def main():
    parser = argparse.ArgumentParser(description="使用 BFS 层次布局可视化控制流，并可输出dot文件以及高分辨率图像")
    parser.add_argument("-i", "--input", required=True, help="输入 JSON 文件路径")
    parser.add_argument("-o", "--output", required=True, help="输出图像文件路径，如 .png/.jpg")
    parser.add_argument("--dot", default="", help="可选，若指定则额外输出一个 .dot 文件")
    parser.add_argument("--dpi", type=int, default=300, help="图像分辨率，默认300")
    parser.add_argument("--width", type=float, default=16.0, help="图像宽度(英寸)，默认16")
    parser.add_argument("--height", type=float, default=10.0, help="图像高度(英寸)，默认10")
    parser.add_argument("--start", type=int, default=0, help="BFS 起始节点ID，默认0")
    parser.add_argument("--layer_dist_x", type=float, default=3.0, help="同层节点之间 X 间距")
    parser.add_argument("--layer_dist_y", type=float, default=3.0, help="层与层之间 Y 间距")
    args = parser.parse_args()

    if not os.path.isfile(args.input):
        print(f"错误: 输入文件 {args.input} 不存在。")
        return

    # 读取 JSON
    with open(args.input, "r", encoding="utf-8") as f:
        try:
            json_data = json.load(f)
        except json.JSONDecodeError as e:
            print(f"JSON 解码错误: {e}")
            return

    # 构建控制流图
    G = build_control_flow_graph(json_data)
    if G.number_of_nodes() == 0:
        print("警告: 图中无节点，可能输入为空。")

    # 如果需要导出 .dot 文件
    if args.dot:
        # 用 networkx 自带的 write_dot，需要 pydot
        try:
            from networkx.drawing.nx_pydot import write_dot
            write_dot(G, args.dot)
            print(f"已输出dot文件: {args.dot}")
        except ImportError:
            print("未安装pydot，无法输出dot文件。可执行: pip install pydot")
        except Exception as e:
            print(f"输出dot文件时出错: {e}")

    # 生成 BFS 层次布局坐标
    pos = bfs_level_layout(G, start=args.start,
                           layer_dist_x=args.layer_dist_x,
                           layer_dist_y=args.layer_dist_y)

    # 创建绘图
    fig, ax = plt.subplots(figsize=(args.width, args.height), dpi=args.dpi)

    # 准备节点标签
    node_labels = {n: G.nodes[n]["label"] for n in G.nodes()}

    # 绘制节点
    nx.draw_networkx_nodes(G, pos, ax=ax,
                           node_size=2000, node_color="#EEFFFF",
                           edgecolors="#000000", linewidths=1.0)
    # 绘制节点标签
    nx.draw_networkx_labels(G, pos, ax=ax,
                            labels=node_labels,
                            font_size=8)

    # 绘制有向边
    nx.draw_networkx_edges(G, pos, ax=ax,
                           arrows=True, arrowstyle="->", arrowsize=14,
                           edge_color="#888888")

    # 边标签
    edge_labels = {(u,v): G[u][v]["label"] for u,v in G.edges() if G[u][v]["label"]}
    nx.draw_networkx_edge_labels(G, pos, ax=ax,
                                 edge_labels=edge_labels,
                                 font_color="#AA0000",
                                 font_size=8,
                                 label_pos=0.5)

    ax.set_axis_off()
    plt.tight_layout()

    # 保存图片
    try:
        plt.savefig(args.output, bbox_inches="tight")
        print(f"已保存高分辨率控制流图: {args.output}")
    except Exception as e:
        print(f"保存图像出错: {e}")

    # 若要预览，可取消注释
    # plt.show()

if __name__ == "__main__":
    main()
