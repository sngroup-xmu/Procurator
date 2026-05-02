from __future__ import annotations

from typing import List, Set

from lark import Tree


def dotted_var_to_str(node: Tree) -> str:
    """
    Best-effort reconstruction of DSL `dotted_var` as a string.

    Index segments (e.g., `x[0]`) are rendered as Boogie-style bitvector indices:
      `x[0bv32]`
    """
    if not isinstance(node, Tree):
        return str(node)
    if str(node.data) != "dotted_var":
        if node.children and isinstance(node.children[0], Tree):
            return dotted_var_to_str(node.children[0])
        return ".".join(str(c) for c in node.children)

    cur = ""
    for item in node.children:
        if hasattr(item, "type"):
            if item.type == "NAME":
                cur += str(item) + "."
            elif item.type == "INTSEG":
                cur += str(item) + "."
            elif item.type == "INT":
                cur = cur.rstrip(".")
                cur += f"[{item}bv32]."
    return cur.rstrip(".")


def collect_dotted_vars(expr: Tree) -> Set[str]:
    out: Set[str] = set()
    for dv in expr.find_data("dotted_var"):
        if isinstance(dv, Tree):
            out.add(dotted_var_to_str(dv))
    return out

