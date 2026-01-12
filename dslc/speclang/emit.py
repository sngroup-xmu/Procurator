from __future__ import annotations

from typing import Iterable, List

from lark import Tree

from .model import GlobalDecl, NodeDecl, SpecModel


class DSLExprPrinter:
    def expr_to_str(self, expr_node) -> str:
        if isinstance(expr_node, Tree):
            expr_type = str(expr_node.data)
            ch = expr_node.children

            if expr_type == "var":
                return self.expr_to_str(ch[0])
            if expr_type == "dotted_var":
                return self._dotted_var(ch)
            if expr_type == "number":
                return str(ch[0])
            if expr_type == "true":
                return "true"
            if expr_type == "false":
                return "false"

            if expr_type in {"add", "sub", "mul", "div", "less", "less_eq", "greater", "greater_eq", "eq", "neq"}:
                op_map = {
                    "add": "+",
                    "sub": "-",
                    "mul": "*",
                    "div": "/",
                    "less": "<",
                    "less_eq": "<=",
                    "greater": ">",
                    "greater_eq": ">=",
                    "eq": "==",
                    "neq": "!=",
                }
                return f"({self.expr_to_str(ch[0])} {op_map[expr_type]} {self.expr_to_str(ch[1])})"

            if expr_type in {"or_op", "and_op"}:
                op_map = {"or_op": "||", "and_op": "&&"}
                expr_children = [c for c in ch if isinstance(c, Tree)]
                if len(expr_children) == 2:
                    return f"({self.expr_to_str(expr_children[0])} {op_map[expr_type]} {self.expr_to_str(expr_children[1])})"
                if len(expr_children) >= 1:
                    acc = self.expr_to_str(expr_children[0])
                    for rest in expr_children[1:]:
                        acc = f"({acc} {op_map[expr_type]} {self.expr_to_str(rest)})"
                    return acc

            if expr_type == "not_op":
                expr_children = [c for c in ch if isinstance(c, Tree)]
                if len(expr_children) == 1:
                    return f"!({self.expr_to_str(expr_children[0])})"
                return "!(true)"

            if expr_type in {"always_op", "eventually_op"}:
                op_map = {"always_op": "[]", "eventually_op": "<>"}
                operand = ch[-1]
                return f"{op_map[expr_type]}({self.expr_to_str(operand)})"

            return ""

        return str(expr_node)

    def _dotted_var(self, children) -> str:
        var_name = ""
        for item in children:
            if hasattr(item, "type"):
                if item.type == "NAME":
                    var_name += (str(item) + ".")
                elif item.type in {"NUMBER", "INT"}:
                    var_name = var_name.rstrip(".")
                    var_name += ("[" + str(item) + "].")
                elif item.type == "INTSEG":
                    var_name += (str(item) + ".")
        return var_name.rstrip(".")


def emit_spec_text(
    spec: SpecModel,
    *,
    global_asserts: Iterable[Tree] | None = None,
    global_assumes: Iterable[Tree] | None = None,
) -> str:
    printer = DSLExprPrinter()
    lines: List[str] = []

    for alias, imp in spec.imports.items():
        line = f'import {alias} from "{imp.path}"'
        if imp.entries_path:
            line += f' entries "{imp.entries_path}"'
        line += ";"
        lines.append(line)
    lines.append("")

    lines.append("topology {")
    for link in spec.links:
        if link.port:
            lines.append(f"  link {link.src} -> {link.dst} {link.port};")
        else:
            lines.append(f"  link {link.src} -> {link.dst};")
    lines.append("}")
    lines.append("")

    for name, node in spec.nodes.items():
        lines.append(f"node {name} {{")
        if node.external_input is True:
            lines.append("  external_input = true;")
        elif node.external_input is False:
            lines.append("  external_input = false;")

        for expr in node.assume_exprs:
            lines.append("  assume {")
            lines.append(f"    {printer.expr_to_str(expr)};")
            lines.append("  };")

        for expr in node.assert_exprs:
            lines.append("  assert {")
            lines.append(f"    {printer.expr_to_str(expr)};")
            lines.append("  };")

        lines.append("}")
        lines.append("")

    lines.append("global {")
    if spec.global_decl.queue_capacity is not None:
        lines.append(f"  queue_capacity = {spec.global_decl.queue_capacity};")
    if spec.global_decl.max_steps is not None:
        lines.append(f"  max_steps = {spec.global_decl.max_steps};")
    if spec.global_decl.deterministic_scheduler is not None:
        lines.append(
            f"  deterministic_scheduler = {'true' if spec.global_decl.deterministic_scheduler else 'false'};"
        )
    if spec.global_decl.env_thread is not None:
        lines.append(f"  env_thread = {'true' if spec.global_decl.env_thread else 'false'};")
    if spec.global_decl.host_eager is not None:
        lines.append(f"  host_eager = {'true' if spec.global_decl.host_eager else 'false'};")

    for group in spec.global_decl.symmetry_groups:
        if group:
            lines.append(f"  symmetry({', '.join(group)});")

    assumes = list(global_assumes) if global_assumes is not None else list(spec.global_decl.assume_exprs)
    if assumes:
        lines.append("  assume {")
        for expr in assumes:
            lines.append(f"    {printer.expr_to_str(expr)};")
        lines.append("  };")

    asserts = list(global_asserts) if global_asserts is not None else list(spec.global_decl.assert_exprs)
    if asserts:
        lines.append("  assert {")
        for expr in asserts:
            lines.append(f"    {printer.expr_to_str(expr)};")
        lines.append("  };")
    lines.append("}")
    lines.append("")

    return "\n".join(lines)
