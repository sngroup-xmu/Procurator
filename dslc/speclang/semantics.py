from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Set

from lark import Tree, Token


_DSL_CONFIG_DIRECTIVES: Set[str] = {
    # Per-node directive
    "external_input",
    "sink",
    # Global directive
    "queue_capacity",
    "max_steps",
    "deterministic_scheduler",
    "env_thread",
    "host_eager",
}


class SemanticError(ValueError):
    pass


@dataclass(frozen=True)
class P4VarInfo:
    name: str
    typ: str
    scope: str


class SemanticAnalyzer:
    """
    A conservative semantic checker for the DSL parse tree.

    Goals (industrial DSL behavior):
    - Catch obvious user errors in DSL-defined locals (double-decl, use-before-decl, int/bool mismatch).
    - Validate boolean contexts for assert/assume when the type is known.
    - Do NOT block on P4 variable resolution yet (we may not have a complete P4 symbol table).

    Notes:
    - P4 variables can be optionally provided via `p4_variable_tables` and will be treated as pre-declared.
    - Unknown (likely-P4) variables are allowed; this keeps the checker usable while toolchain integration
      is still evolving.
    """

    def __init__(self, p4_variable_tables: Optional[List[List[Dict[str, Any]]]] = None):
        self.p4_variable_tables = p4_variable_tables or []
        self.current_scope = "global"
        self.scopes: Dict[str, Dict[str, str]] = {"global": {}}
        self.errors: List[str] = []
        self._load_p4_variables()

    def analyze(self, parsed_tree: Tree) -> None:
        self._process_node(parsed_tree)
        if self.errors:
            raise SemanticError("Semantic analysis failed:\n" + "\n".join(self.errors))

    def _load_p4_variables(self) -> None:
        for var_table in self.p4_variable_tables:
            for var in var_table:
                try:
                    info = P4VarInfo(name=var["Name"], typ=var["Type"], scope=var["Scope"])
                except KeyError:
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

        if node_type == "host_section":
            host_name = str(node.children[0])
            prev_scope = self.current_scope
            self.current_scope = host_name
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

        if node_type == "if_statement":
            self._process_if_statement(node)
            return

        if node_type == "env_block":
            for stmt in node.children:
                self._process_node(stmt)
            return

        if node_type == "connect_stmt":
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
            # Heuristic: DSL locals are typically CamelCase / start with uppercase;
            # P4 vars are typically lowercase / dotted / indexed.
            if self._looks_like_dsl_local(var_name):
                self.errors.append(
                    f"Error: variable '{var_name}' assigned before declaration in scope '{self.current_scope}'"
                )
            # else: allow unknown (treat as external/P4 variable)
            return

        expr_type = self._get_expression_type(node.children[2])
        if expr_type is not None and expr_type != var_type:
            self.errors.append(
                f"Type Error: cannot assign '{expr_type}' to '{var_name}' (declared as '{var_type}') in scope '{self.current_scope}'"
            )

    def _process_bool_block(self, node: Tree) -> None:
        # assert_statement / assume_statement wrap a bool_expr_list.
        #
        # NOTE: In our grammar `?bool_expr` is inlined, so we typically won't see
        # an explicit `bool_expr` node. Prefer reading the `bool_expr_list` directly.
        for bel in node.find_data("bool_expr_list"):
            for child in bel.children:
                if not isinstance(child, Tree):
                    continue
                expr_type = self._get_expression_type(child)
                if expr_type is not None and expr_type != "bool":
                    self.errors.append(
                        f"Type Error: expected bool in {node.data} but got '{expr_type}' in scope '{self.current_scope}'"
                    )

        # Fallback for older grammar variants where bool_expr might not be inlined.
        for expr in node.find_data("bool_expr"):
            expr_type = self._get_expression_type(expr.children[0]) if expr.children else None
            if expr_type is not None and expr_type != "bool":
                self.errors.append(
                    f"Type Error: expected bool in {node.data} but got '{expr_type}' in scope '{self.current_scope}'"
                )

    def _process_if_statement(self, node: Tree) -> None:
        # if_statement: "if" "(" bool_expr ")" "{" statement* "}" ("else" "{" statement* "}")?
        # First child is the condition.
        if not node.children:
            return
        cond = node.children[0]
        cond_type = self._get_expression_type(cond) if isinstance(cond, Tree) else None
        if cond_type is not None and cond_type != "bool":
            self.errors.append(
                f"Type Error: expected bool in if condition but got '{cond_type}' in scope '{self.current_scope}'"
            )
        # Remaining children are statement blocks (then, else).
        for child in node.children[1:]:
            if not isinstance(child, Tree):
                continue
            if str(child.data) == "else_block":
                for stmt in child.children:
                    if isinstance(stmt, Tree):
                        self._process_node(stmt)
                continue
            self._process_node(child)

    def _looks_like_dsl_local(self, var_name: str) -> bool:
        if not var_name:
            return False
        if "." in var_name or "[" in var_name:
            return False
        return var_name[0].isupper()

    def _get_variable_type(self, var_name: str) -> Optional[str]:
        # local scope first
        if var_name in self.scopes.get(self.current_scope, {}):
            return self.scopes[self.current_scope][var_name]
        # global scope
        if var_name in self.scopes.get("global", {}):
            return self.scopes["global"][var_name]
        # p4 scopes (best-effort)
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
        if isinstance(node, Token):
            return str(node)
        if not isinstance(node, Tree):
            return str(node)
        if str(node.data) != "dotted_var":
            if len(node.children) == 1:
                return self._dotted_var_to_str(node.children[0])
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
