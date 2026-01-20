from __future__ import annotations

from typing import Any, List, Optional

from lark import Lark, Tree, Token

from .grammar import GRAMMAR
from .model import GlobalDecl, HostDecl, ImportDecl, LinkDecl, NodeDecl, SpecModel


class SpecParseError(ValueError):
    pass


_DSL_CONFIG_DIRECTIVES = {
    "external_input",
    "sink",
    "queue_capacity",
    "max_steps",
    "deterministic_scheduler",
    "env_thread",
    "host_eager",
}


def parse_tree(spec_text: str) -> Tree:
    parser = Lark(GRAMMAR, start="start", parser="lalr")
    return parser.parse(spec_text)


def parse_model(spec_text: str) -> SpecModel:
    tree = parse_tree(spec_text)
    model = SpecModel()

    def ensure_node(name: str) -> NodeDecl:
        return model.ensure_node(name)

    def ensure_host(name: str) -> HostDecl:
        return model.ensure_host(name)

    for section in tree.children:
        if not isinstance(section, Tree):
            continue
        st = str(section.data)

        if st == "import_section":
            for imp in section.children:
                if not isinstance(imp, Tree) or str(imp.data) != "import_stmt":
                    continue
                alias = str(imp.children[0])
                path = str(imp.children[1]).strip('"')
                entries_path = None
                if (
                    len(imp.children) >= 3
                    and isinstance(imp.children[2], Tree)
                    and str(imp.children[2].data) == "entries_clause"
                ):
                    entries_path = str(imp.children[2].children[0]).strip('"')
                model.imports[alias] = ImportDecl(alias=alias, path=path, entries_path=entries_path)
                ensure_node(alias)
            continue

        if st == "topology_section":
            for link in section.children:
                if not isinstance(link, Tree) or str(link.data) != "link":
                    continue
                src = str(link.children[0])
                dst = str(link.children[1])
                port = "ALL"
                if len(link.children) >= 3:
                    port_node = link.children[2]
                    if isinstance(port_node, Tree) and port_node.children:
                        port = str(port_node.children[0])
                    elif isinstance(port_node, Token):
                        port = str(port_node)
                model.links.append(LinkDecl(src=src, dst=dst, port=port))
            continue

        if st == "node_section":
            node_name = str(section.children[0])
            nd = ensure_node(node_name)
            for stmt in section.children[1:]:
                if not isinstance(stmt, Tree):
                    continue
                tt = str(stmt.data)

                if tt == "env_block":
                    for env_stmt in stmt.children:
                        if not isinstance(env_stmt, Tree):
                            continue
                        et = str(env_stmt.data)
                        if et == "var_decl":
                            nd.statements.append(env_stmt)
                        nd.env_statements.append(env_stmt)
                    continue

                if tt in {"assignment", "var_decl"}:
                    var_tree = stmt.children[0] if tt == "assignment" else stmt.children[1]
                    rhs_tree = stmt.children[2] if tt == "assignment" else stmt.children[3]
                    var_name = _dotted_var_to_str(var_tree)
                    if var_name == "external_input":
                        rhs_val = _bool_literal(rhs_tree)
                        if rhs_val is None:
                            raise SpecParseError("external_input must be true/false")
                        nd.external_input = rhs_val
                        continue
                    if var_name == "sink":
                        rhs_val = _bool_literal(rhs_tree)
                        if rhs_val is None:
                            raise SpecParseError("sink must be true/false")
                        nd.sink = rhs_val
                        continue

                if tt == "assume_statement":
                    nd.assume_exprs.extend(_extract_bool_exprs(stmt))
                if tt == "assert_statement":
                    nd.assert_exprs.extend(_extract_bool_exprs(stmt))

                nd.statements.append(stmt)
            continue

        if st == "host_section":
            host_name = str(section.children[0])
            hd = ensure_host(host_name)
            for stmt in section.children[1:]:
                if not isinstance(stmt, Tree):
                    continue
                tt = str(stmt.data)
                if tt == "host_stmt":
                    if not stmt.children:
                        continue
                    stmt = stmt.children[0]
                    if not isinstance(stmt, Tree):
                        continue
                    tt = str(stmt.data)

                if tt == "connect_stmt":
                    if stmt.children:
                        hd.connect_to = str(stmt.children[0])
                    continue

                if tt == "env_block":
                    for env_stmt in stmt.children:
                        if not isinstance(env_stmt, Tree):
                            continue
                        et = str(env_stmt.data)
                        if et == "var_decl":
                            hd.statements.append(env_stmt)
                        hd.env_statements.append(env_stmt)
                    continue

                if tt in {"assignment", "var_decl"}:
                    var_tree = stmt.children[0] if tt == "assignment" else stmt.children[1]
                    rhs_tree = stmt.children[2] if tt == "assignment" else stmt.children[3]
                    var_name = _dotted_var_to_str(var_tree)
                    if var_name == "external_input":
                        rhs_val = _bool_literal(rhs_tree)
                        if rhs_val is None:
                            raise SpecParseError("external_input must be true/false")
                        # Ignore on hosts.
                        continue
                    if var_name == "sink":
                        rhs_val = _bool_literal(rhs_tree)
                        if rhs_val is None:
                            raise SpecParseError("sink must be true/false")
                        # Ignore on hosts.
                        continue

                if tt == "assume_statement":
                    hd.assume_exprs.extend(_extract_bool_exprs(stmt))
                if tt == "assert_statement":
                    hd.assert_exprs.extend(_extract_bool_exprs(stmt))

                hd.statements.append(stmt)
            continue

        if st == "global_section":
            gd: GlobalDecl = model.global_decl
            for stmt in section.children:
                if not isinstance(stmt, Tree):
                    continue
                tt = str(stmt.data)

                if tt in {"assignment", "var_decl"}:
                    var_tree = stmt.children[0] if tt == "assignment" else stmt.children[1]
                    rhs_tree = stmt.children[2] if tt == "assignment" else stmt.children[3]
                    var_name = _dotted_var_to_str(var_tree)
                    if var_name == "queue_capacity":
                        rhs_num = _int_literal(rhs_tree)
                        if rhs_num is None:
                            raise SpecParseError("queue_capacity must be an integer literal")
                        gd.queue_capacity = rhs_num
                        continue
                    if var_name == "max_steps":
                        rhs_num = _int_literal(rhs_tree)
                        if rhs_num is None:
                            raise SpecParseError("max_steps must be an integer literal")
                        gd.max_steps = rhs_num
                        continue
                    if var_name == "deterministic_scheduler":
                        rhs_val = _bool_literal(rhs_tree)
                        if rhs_val is None:
                            raise SpecParseError("deterministic_scheduler must be true/false")
                        gd.deterministic_scheduler = rhs_val
                        continue
                    if var_name == "env_thread":
                        rhs_val = _bool_literal(rhs_tree)
                        if rhs_val is None:
                            raise SpecParseError("env_thread must be true/false")
                        gd.env_thread = rhs_val
                        continue
                    if var_name == "host_eager":
                        rhs_val = _bool_literal(rhs_tree)
                        if rhs_val is None:
                            raise SpecParseError("host_eager must be true/false")
                        gd.host_eager = rhs_val
                        continue

                if tt == "reachability_stmt":
                    pair = _parse_two_nodes_from_node_list(stmt)
                    gd.reachability.append(pair)
                    continue
                if tt == "runtime_reachability_stmt":
                    pair = _parse_two_nodes_from_node_list(stmt)
                    gd.runtime_reachability.append(pair)
                    continue
                if tt == "symmetry_stmt":
                    group = _parse_node_list(stmt)
                    if group:
                        gd.symmetry_groups.append(group)
                    continue

                if tt == "assume_statement":
                    gd.assume_exprs.extend(_extract_bool_exprs(stmt))
                if tt == "assert_statement":
                    gd.assert_exprs.extend(_extract_bool_exprs(stmt))

                gd.statements.append(stmt)
            continue

    return model


def _parse_two_nodes_from_node_list(reach_stmt: Tree) -> tuple[str, str]:
    # reachability_stmt: "reachability" "(" node_list ")" ";"
    # node_list: NAME ("," NAME)*
    node_list_tree = reach_stmt.children[0] if reach_stmt.children else None
    if not isinstance(node_list_tree, Tree) or str(node_list_tree.data) != "node_list":
        raise SpecParseError("malformed reachability statement: expected node_list")
    nodes = [str(c) for c in node_list_tree.children]
    if len(nodes) != 2:
        raise SpecParseError(f"reachability expects exactly 2 nodes, got {len(nodes)}: {nodes}")
    return nodes[0], nodes[1]


def _parse_node_list(stmt: Tree) -> List[str]:
    node_list_tree = stmt.children[0] if stmt.children else None
    if not isinstance(node_list_tree, Tree) or str(node_list_tree.data) != "node_list":
        raise SpecParseError("malformed statement: expected node_list")
    return [str(c) for c in node_list_tree.children]


def _extract_bool_exprs(assert_or_assume_stmt: Tree) -> List[Tree]:
    # bool_expr_list: (bool_expr ";")*
    exprs: List[Tree] = []
    for bel in assert_or_assume_stmt.find_data("bool_expr_list"):
        for child in bel.children:
            if isinstance(child, Tree):
                exprs.append(child)
    if exprs:
        return exprs
    for be in assert_or_assume_stmt.find_data("bool_expr"):
        if be.children and isinstance(be.children[0], Tree):
            exprs.append(be.children[0])
    return exprs


def _bool_literal(node: Any) -> Optional[bool]:
    if isinstance(node, Tree):
        if str(node.data) == "true":
            return True
        if str(node.data) == "false":
            return False
    return None


def _int_literal(node: Any) -> Optional[int]:
    if isinstance(node, Tree) and str(node.data) == "number" and node.children:
        try:
            return int(str(node.children[0]))
        except ValueError:
            return None
    if isinstance(node, Token) and node.type == "NUMBER":
        try:
            return int(str(node))
        except ValueError:
            return None
    return None


def _dotted_var_to_str(node: Any) -> str:
    if isinstance(node, Token):
        return str(node)
    if not isinstance(node, Tree):
        return str(node)
    if str(node.data) != "dotted_var":
        if len(node.children) == 1:
            return _dotted_var_to_str(node.children[0])
        return ".".join(str(c) for c in node.children)

    cur = ""
    for item in node.children:
        if isinstance(item, Token):
            if item.type == "NAME":
                cur += str(item) + "."
            elif item.type == "NUMBER":
                cur = cur.rstrip(".")
                cur += f"[{item}]."
    return cur.rstrip(".")
