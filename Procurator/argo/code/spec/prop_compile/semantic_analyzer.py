from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Set

from lark import Tree, Token


_DSL_CONFIG_DIRECTIVES: Set[str] = {
    # Per-node directive: whether this node can receive external inputs from Env/NondetActor
    "external_input",
    # Global directive: queue capacity (K) for message abstraction (Bag/FIFO/mailbox)
    "queue_capacity",
}


@dataclass(frozen=True)
class P4VarInfo:
    name: str
    typ: str
    scope: str


class SemanticAnalyzer:
    """
    Lightweight semantic checks for the DSL parse tree.

    Notes:
    - This analyzer is intentionally conservative and only checks basic issues
      (undeclared local vars, type mismatches for int/bool DSL locals).
    - P4 variables are expected to be provided via `p4_variable_tables` and are treated as pre-declared.
    - DSL config directives (external_input / queue_capacity) are ignored by semantic checks.
    """

    def __init__(self, p4_variable_tables: List[List[Dict[str, Any]]]):
        self.p4_variable_tables = p4_variable_tables
        self.current_scope = "global"
        self.scopes: Dict[str, Dict[str, str]] = {"global": {}}
        self.errors: List[str] = []
        self._load_p4_variables()

    def analyze(self, parsed_tree: Tree) -> None:
        self._process_node(parsed_tree)
        if self.errors:
            raise ValueError("Semantic analysis failed:\n" + "\n".join(self.errors))

    def _load_p4_variables(self) -> None:
        for var_table in self.p4_variable_tables or []:
            for var in var_table:
                try:
                    info = P4VarInfo(name=var["Name"], typ=var["Type"], scope=var["Scope"])
                except KeyError:
                    # best-effort: ignore malformed entries
                    continue
                self.scopes.setdefault(info.scope, {})
                self.scopes[info.scope].setdefault(info.name, info.typ)

    def _process_node(self, node: Any) -> None:
        if not isinstance(node, Tree):
            return

        node_type = str(node.data)

        if node_type == "start":
            for section in node.children:
                self._process_node(section)
            return

        if node_type == "node_section":
            node_name = str(node.children[0])
            prev_scope = self.current_scope
            self.current_scope = node_name
            self.scopes.setdefault(self.current_scope, {})
            for stmt in node.children[1:]:
                self._process_node(stmt)
            self.current_scope = prev_scope
            return

        if node_type == "global_section":
            prev_scope = self.current_scope
            self.current_scope = "global"
            for stmt in node.children:
                self._process_node(stmt)
            self.current_scope = prev_scope
            return

        if node_type == "var_decl":
            self._process_var_decl(node)
            return

        if node_type == "assignment":
            self._process_assignment(node)
            return

        if node_type in {"assert_statement", "assume_statement"}:
            self._process_bool_block(node)
            return

        # ignore: imports/topology/ltl/reachability/... for now

    def _process_var_decl(self, node: Tree) -> None:
        # var_decl: type dotted_var assign_op expression
        var_type = str(node.children[0].data)  # int|bool
        var_name = self._dotted_var_to_str(node.children[1])
        if var_name in _DSL_CONFIG_DIRECTIVES:
            return

        # declare in current scope
        if var_name in self.scopes.get(self.current_scope, {}):
            self.errors.append(
                f"Error: variable '{var_name}' already declared in scope '{self.current_scope}'"
            )
        else:
            self.scopes[self.current_scope][var_name] = var_type

        expr_type = self._get_expression_type(node.children[3])
        if expr_type is not None and expr_type != var_type:
            self.errors.append(
                f"Type Error: cannot assign '{expr_type}' to '{var_name}' (declared as '{var_type}') in scope '{self.current_scope}'"
            )

    def _process_assignment(self, node: Tree) -> None:
        # assignment: dotted_var assign_op expression
        var_name = self._dotted_var_to_str(node.children[0])
        if var_name in _DSL_CONFIG_DIRECTIVES:
            return

        var_type = self._get_variable_type(var_name)
        if var_type is None:
            self.errors.append(
                f"Error: variable '{var_name}' assigned before declaration in scope '{self.current_scope}'"
            )
            return

        expr_type = self._get_expression_type(node.children[2])
        if expr_type is not None and expr_type != var_type:
            self.errors.append(
                f"Type Error: cannot assign '{expr_type}' to '{var_name}' (declared as '{var_type}') in scope '{self.current_scope}'"
            )

    def _process_bool_block(self, node: Tree) -> None:
        # assert_statement / assume_statement wrap a bool_expr_list
        # bool_expr_list: (bool_expr ";")*
        for expr in node.find_data("bool_expr"):
            # just type-check
            expr_type = self._get_expression_type(expr.children[0]) if expr.children else None
            if expr_type is not None and expr_type != "bool":
                self.errors.append(
                    f"Type Error: expected bool in {node.data} but got '{expr_type}' in scope '{self.current_scope}'"
                )

    def _get_variable_type(self, var_name: str) -> Optional[str]:
        # local scope first
        if var_name in self.scopes.get(self.current_scope, {}):
            return self.scopes[self.current_scope][var_name]
        # global scope
        if var_name in self.scopes.get("global", {}):
            return self.scopes["global"][var_name]
        # p4 scopes
        for scope_vars in self.scopes.values():
            if var_name in scope_vars:
                return scope_vars[var_name]
        return None

    def _get_expression_type(self, expr_node: Any) -> Optional[str]:
        if not isinstance(expr_node, Tree):
            return None

        t = str(expr_node.data)
        if t == "number":
            return "int"
        if t in {"true", "false"}:
            return "bool"
        if t == "var":
            # var: dotted_var
            vname = self._dotted_var_to_str(expr_node.children[0])
            return self._get_variable_type(vname)
        if t == "dotted_var":
            vname = self._dotted_var_to_str(expr_node)
            return self._get_variable_type(vname)
        if t in {"add", "sub", "mul", "div"}:
            lt = self._get_expression_type(expr_node.children[0])
            rt = self._get_expression_type(expr_node.children[1])
            if lt == "int" and rt == "int":
                return "int"
            return None
        if t in {"less", "less_eq", "greater", "greater_eq", "eq", "neq", "and_op", "or_op", "not_op"}:
            return "bool"
        return None

    def _dotted_var_to_str(self, node: Any) -> str:
        """
        Convert a `dotted_var` Tree into its textual representation, e.g.:
          hdr.ipv4.dstAddr[0]
        """
        if isinstance(node, Token):
            return str(node)
        if not isinstance(node, Tree):
            return str(node)
        if str(node.data) != "dotted_var":
            # For convenience, allow passing `var` nodes, etc.
            if len(node.children) == 1:
                return self._dotted_var_to_str(node.children[0])
            return ".".join(str(c) for c in node.children)

        parts: List[str] = []
        cur = ""
        for item in node.children:
            if isinstance(item, Token):
                if item.type == "NAME":
                    cur += str(item) + "."
                elif item.type == "NUMBER":
                    cur = cur.rstrip(".")
                    cur += f"[{item}]."
        cur = cur.rstrip(".")
        parts.append(cur)
        return "".join(parts)
