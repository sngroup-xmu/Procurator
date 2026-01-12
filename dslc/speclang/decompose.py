from __future__ import annotations

from collections import deque
from dataclasses import replace
from typing import Iterable, List, Optional, Set, Tuple

from lark import Tree

from .model import GlobalDecl, LinkDecl, NodeDecl, SpecModel


def decompose_global_asserts(
    spec: SpecModel,
    *,
    max_nodes: int = 2,
    local_inputs: bool = False,
) -> List[Tuple[str, SpecModel]]:
    """
    Decompose a spec into sub-specs by splitting top-level conjunctions in global asserts.

    Returns a list of (suffix, spec) pairs. If no safe decomposition is possible, returns [("full", spec)].
    """
    if not spec.global_decl.assert_exprs:
        return [("full", spec)]

    conjuncts: List[Tree] = []
    for expr in spec.global_decl.assert_exprs:
        conjuncts.extend(_flatten_and(expr))

    if len(conjuncts) <= 1:
        return [("full", spec)]

    aliases = list(spec.imports.keys())
    parts: List[Tuple[str, SpecModel]] = []
    for idx, expr in enumerate(conjuncts, start=1):
        nodes, implicit = _expr_nodes(expr, aliases)
        if implicit or not nodes or len(nodes) > max_nodes:
            return [("full", spec)]
        if local_inputs and len(nodes) == 1:
            keep_nodes = set(nodes)
        else:
            keep_nodes = _closure_nodes(spec, nodes)
        sub = _sub_spec(spec, keep_nodes, [expr])
        if local_inputs and len(nodes) == 1:
            _force_local_input(sub, next(iter(nodes)))
        parts.append((f"part{idx}", sub))

    return parts


def _flatten_and(expr: Tree) -> List[Tree]:
    if isinstance(expr, Tree) and str(expr.data) == "and_op":
        out: List[Tree] = []
        for ch in expr.children:
            if isinstance(ch, Tree) and str(ch.data) == "and_op":
                out.extend(_flatten_and(ch))
            elif isinstance(ch, Tree):
                out.append(ch)
        return out
    return [expr]


def _expr_nodes(expr: Tree, aliases: Iterable[str]) -> Tuple[Set[str], bool]:
    nodes: Set[str] = set()
    implicit = False
    for dv in expr.find_data("dotted_var"):
        name = _dotted_var_to_str_static(dv)
        node = _extract_node_prefix(name, aliases)
        if node:
            nodes.add(node)
        else:
            implicit = True
    return nodes, implicit


def _extract_node_prefix(name: str, aliases: Iterable[str]) -> Optional[str]:
    for a in aliases:
        if name.startswith(f"{a}_") or name.startswith(f"{a}."):
            return a
    return None


def _dotted_var_to_str_static(node: Tree) -> str:
    if not isinstance(node, Tree):
        return str(node)
    if str(node.data) != "dotted_var":
        if node.children and isinstance(node.children[0], Tree):
            return _dotted_var_to_str_static(node.children[0])
        return ".".join(str(c) for c in node.children)
    cur = ""
    for item in node.children:
        if hasattr(item, "type"):
            if item.type == "NAME":
                cur += str(item) + "."
            elif item.type in {"NUMBER", "INT"}:
                cur = cur.rstrip(".")
                cur += f"[{item}]."
            elif item.type == "INTSEG":
                cur += str(item) + "."
    return cur.rstrip(".")


def _closure_nodes(spec: SpecModel, base_nodes: Set[str]) -> Set[str]:
    # include nodes on any path between base nodes
    nodes = set(base_nodes)
    adj = _adjacency(spec.links)
    rev = _adjacency(spec.links, reverse=True)

    for src in base_nodes:
        reach_from = _reachable(adj, src)
        for dst in base_nodes:
            if src == dst:
                continue
            reach_to = _reachable(rev, dst)
            nodes.update(reach_from & reach_to)

    # include any node that can reach a base node
    for dst in base_nodes:
        nodes.update(_reachable(rev, dst))

    # include external_input nodes that can reach any base node
    ext_nodes = {n for n, nd in spec.nodes.items() if nd.external_input}
    for ext in ext_nodes:
        reach = _reachable(adj, ext)
        if reach & nodes:
            nodes.add(ext)
    return nodes


def _adjacency(links: Iterable[LinkDecl], reverse: bool = False) -> dict[str, Set[str]]:
    adj: dict[str, Set[str]] = {}
    for l in links:
        src = l.dst if reverse else l.src
        dst = l.src if reverse else l.dst
        adj.setdefault(src, set()).add(dst)
    return adj


def _reachable(adj: dict[str, Set[str]], start: str) -> Set[str]:
    seen: Set[str] = set()
    dq = deque([start])
    while dq:
        cur = dq.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in adj.get(cur, set()):
            if nxt not in seen:
                dq.append(nxt)
    return seen


def _sub_spec(spec: SpecModel, keep_nodes: Set[str], asserts: List[Tree]) -> SpecModel:
    imports = {k: v for k, v in spec.imports.items() if k in keep_nodes}
    nodes = {k: v for k, v in spec.nodes.items() if k in keep_nodes}
    links = [l for l in spec.links if l.src in keep_nodes and l.dst in keep_nodes]

    assumes = _filter_global_exprs(spec, keep_nodes, spec.global_decl.assume_exprs)
    symmetry = []
    for group in spec.global_decl.symmetry_groups:
        g = [n for n in group if n in keep_nodes]
        if len(g) >= 2:
            symmetry.append(g)

    g = GlobalDecl(
        queue_capacity=spec.global_decl.queue_capacity,
        max_steps=spec.global_decl.max_steps,
        deterministic_scheduler=spec.global_decl.deterministic_scheduler,
        env_thread=spec.global_decl.env_thread,
        host_eager=spec.global_decl.host_eager,
        assume_exprs=assumes,
        assert_exprs=asserts,
        symmetry_groups=symmetry,
    )
    return SpecModel(imports=imports, links=links, nodes=nodes, global_decl=g)


def _force_local_input(spec: SpecModel, node: str) -> None:
    # Over-approximate environment by allowing direct external input to the local node.
    if node in spec.nodes:
        spec.nodes[node] = replace(spec.nodes[node], external_input=True)
    # With a single node, drop topology to avoid irrelevant forwarding.
    if len(spec.nodes) <= 1:
        spec.links = []


def _filter_global_exprs(spec: SpecModel, keep_nodes: Set[str], exprs: List[Tree]) -> List[Tree]:
    aliases = list(spec.imports.keys())
    out: List[Tree] = []
    for expr in exprs:
        nodes, implicit = _expr_nodes(expr, aliases)
        if implicit:
            continue
        if nodes.issubset(keep_nodes):
            out.append(expr)
    return out
