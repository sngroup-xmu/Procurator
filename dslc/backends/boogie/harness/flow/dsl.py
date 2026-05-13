from __future__ import annotations

import re
from typing import Dict, List, Optional, Sequence

from lark import Tree

from .....speclang.model import HostDecl, NodeDecl
from ...core.common import dsl_is_simple_local_name, is_on_wire_packet_var, is_packet_var
from ...core.dsl import collect_dotted_vars
from ...core.errors import BoogieBackendError

_collect_dotted_vars = collect_dotted_vars
_dsl_is_simple_local_name = dsl_is_simple_local_name
_is_on_wire_packet_var = is_on_wire_packet_var
_is_packet_var = is_packet_var


class BoogieHarnessDslMixin:
    _TOPLEVEL_ASSIGN_RE = re.compile(r"^([A-Za-z0-9_\.\$\[\]]+)\s*:=\s*(.+);\s*$")
    _ASSIGN_TOKEN_RE = re.compile(r"[A-Za-z0-9_\.\$\[\]]+")

    def _boogie_port_const(self, port: str, egress_type: str) -> str:
        # If type is a bitvector like bv9, render as "123bv9"; otherwise as int literal.
        m = re.fullmatch(r"bv(\d+)", egress_type.strip())
        if m:
            return f"{port}bv{m.group(1)}"
        return port

    def _expr_to_boogie(self, expr: Tree, current_node: str, *, prefer_reg_dbg: bool = False) -> str:
        """
        Translate a DSL boolean/arithmetic expression Tree to Boogie.
        This is intentionally minimal (enough for assume/assert constraints).
        """
        t = str(expr.data)
        ch = expr.children

        if t == "number":
            return str(ch[0])
        if t == "true":
            return "true"
        if t == "false":
            return "false"
        if t == "var":
            return self._expr_to_boogie(ch[0], current_node=current_node, prefer_reg_dbg=prefer_reg_dbg)
        if t == "dotted_var":
            name = self._dotted_var_to_boogie(expr, current_node=current_node)
            if prefer_reg_dbg:
                mapped = self._map_register_zero_to_dbg(name)
                if mapped is not None:
                    return mapped
            return name
        if t == "bit_slice" and len(ch) == 3:
            base = self._expr_to_boogie(ch[0], current_node=current_node, prefer_reg_dbg=prefer_reg_dbg)
            return f"{base}[{ch[1]}:{ch[2]}]"
        if t == "bit_slice" and len(ch) == 2:
            base = self._expr_to_boogie(ch[0], current_node=current_node, prefer_reg_dbg=prefer_reg_dbg)
            return f"{base}{ch[1]}"

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
            "and_op": "&&",
            "or_op": "||",
        }
        if t in op_map:
            # Lark may include operator tokens; ignore non-Tree children.
            expr_children = [c for c in ch if isinstance(c, Tree)]
            if t in {"and_op", "or_op"} and len(expr_children) >= 2:
                rendered = [self._expr_to_boogie(e, current_node, prefer_reg_dbg=prefer_reg_dbg) for e in expr_children]
                joiner = f" {op_map[t]} "
                return f"({joiner.join(rendered)})"
            if len(expr_children) == 2:
                # Type-aware constant rendering for common P4 header fields (bvN in Boogie).
                lhs, rhs = expr_children[0], expr_children[1]

                def unwrap_var(n: Tree) -> Tree:
                    # In our grammar, dotted_var appears as factor -> var(dotted_var)
                    if isinstance(n, Tree) and str(n.data) == "var" and n.children and isinstance(n.children[0], Tree):
                        return n.children[0]
                    return n

                ul = unwrap_var(lhs) if isinstance(lhs, Tree) else lhs
                ur = unwrap_var(rhs) if isinstance(rhs, Tree) else rhs
                lhs_render = self._expr_to_boogie(lhs, current_node, prefer_reg_dbg=prefer_reg_dbg)
                rhs_render = self._expr_to_boogie(rhs, current_node, prefer_reg_dbg=prefer_reg_dbg)
                if t in {"eq", "neq", "less", "less_eq", "greater", "greater_eq"}:
                    if (
                        isinstance(ul, Tree)
                        and str(ul.data) == "dotted_var"
                        and isinstance(ur, Tree)
                        and str(ur.data) == "number"
                        and self._dotted_var_to_str(ul).endswith("__last_write_site")
                    ):
                        return f"({lhs_render} {op_map[t]} {rhs_render})"
                    if (
                        isinstance(ur, Tree)
                        and str(ur.data) == "dotted_var"
                        and isinstance(ul, Tree)
                        and str(ul.data) == "number"
                        and self._dotted_var_to_str(ur).endswith("__last_write_site")
                    ):
                        return f"({lhs_render} {op_map[t]} {rhs_render})"
                    if (
                        isinstance(ul, Tree)
                        and str(ul.data) == "bit_slice"
                        and isinstance(ur, Tree)
                        and str(ur.data) == "number"
                    ):
                        w = self._slice_width_bits(ul)
                        if w is not None:
                            rhs_render = f"{ur.children[0]}bv{w}"
                    if (
                        isinstance(ur, Tree)
                        and str(ur.data) == "bit_slice"
                        and isinstance(ul, Tree)
                        and str(ul.data) == "number"
                    ):
                        w = self._slice_width_bits(ur)
                        if w is not None:
                            lhs_render = f"{ul.children[0]}bv{w}"
                    if (
                        isinstance(ul, Tree)
                        and str(ul.data) == "dotted_var"
                        and isinstance(ur, Tree)
                        and str(ur.data) == "number"
                    ):
                        # Resolve width via meta using the correct node context.
                        base = self._dotted_var_to_str(ul)
                        node = current_node
                        raw = base
                        for a in self._spec.imports.keys():
                            if base.startswith(f"{a}_"):
                                node = a
                                raw = base[len(a) + 1 :]
                                break
                        w = self._infer_bv_width_for_node(node, raw)
                        if w is not None:
                            rhs_render = f"{ur.children[0]}bv{w}"
                    if (
                        isinstance(ur, Tree)
                        and str(ur.data) == "dotted_var"
                        and isinstance(ul, Tree)
                        and str(ul.data) == "number"
                    ):
                        base = self._dotted_var_to_str(ur)
                        node = current_node
                        raw = base
                        for a in self._spec.imports.keys():
                            if base.startswith(f"{a}_"):
                                node = a
                                raw = base[len(a) + 1 :]
                                break
                        w = self._infer_bv_width_for_node(node, raw)
                        if w is not None:
                            lhs_render = f"{ul.children[0]}bv{w}"
                # Special-case bv16/bv32 ordering: rewrite to our helper (unsigned compare).
                if t in {"greater", "greater_eq", "less", "less_eq"}:
                    wl = self._infer_expr_width_bits(lhs)
                    wr = self._infer_expr_width_bits(rhs)
                    if wl is None and wr is not None:
                        wl = wr
                    if wr is None and wl is not None:
                        wr = wl
                    if (wl, wr) in {(16, 16), (32, 32)}:
                        a = lhs_render
                        b = rhs_render
                        le_fn = f"bvule.bv{wl}$builtin"
                        if t == "greater_eq":
                            return f"{le_fn}({b}, {a})"
                        if t == "greater":
                            return f"({le_fn}({b}, {a}) && ({a} != {b}))"
                        if t == "less_eq":
                            return f"{le_fn}({a}, {b})"
                        if t == "less":
                            return f"({le_fn}({a}, {b}) && ({a} != {b}))"

                return f"({lhs_render} {op_map[t]} {rhs_render})"
        if t == "not_op":
            expr_children = [c for c in ch if isinstance(c, Tree)]
            if len(expr_children) == 1:
                return f"!({self._expr_to_boogie(expr_children[0], current_node, prefer_reg_dbg=prefer_reg_dbg)})"

        # LTL unary ops may appear in assume/assert blocks in some specs; keep best-effort
        if t in {"always_op", "eventually_op"} and len(ch) >= 1:
            return self._expr_to_boogie(ch[-1], current_node=current_node, prefer_reg_dbg=prefer_reg_dbg)

        return "true"

    def _dotted_var_to_boogie(self, node: Tree, current_node: str) -> str:
        # Render dotted_var into a Boogie identifier; for node-local names, assume they refer to this node.
        # NOTE: Use a single reconstruction routine to avoid inconsistencies across Lark versions.
        cur = self._dotted_var_to_str(node)
        # DSL locals (simple names) are rewritten to dedicated globals.
        if _dsl_is_simple_local_name(cur):
            # Node-local DSL var takes priority.
            if cur in self._dsl_node_vars.get(current_node, {}):
                return f"{current_node}_dsl_{cur}"
            if cur in self._dsl_host_vars.get(current_node, {}):
                return f"{current_node}_dsl_{cur}"
            if cur in self._dsl_global_vars:
                return f"dsl_{cur}"

        def resolve_declared(node_name: str, base: str) -> str:
            decl = self._get_declared_vars(node_name)
            base_name = base
            suffix = ""
            if "[" in base:
                base_name, rest = base.split("[", 1)
                suffix = "[" + rest
            if base_name in decl:
                return base_name + suffix
            if base_name.endswith("_0") and base_name[:-2] in decl:
                return base_name[:-2] + suffix
            if f"{base_name}_0" in decl:
                return f"{base_name}_0" + suffix
            return base

        node_name = current_node
        base = cur
        for a in list(self._spec.imports.keys()) + list(self._host_to_node.keys()):
            if cur.startswith(f"{a}_"):
                node_name = a
                base = cur[len(a) + 1 :]
                break

        base = resolve_declared(node_name, base)
        return f"{node_name}_{base}" if not cur.startswith(f"{node_name}_") else f"{node_name}_{base}"

    def _map_register_zero_to_dbg(self, name: str) -> Optional[str]:
        """
        If the expression refers to a register array element at index 0, map it to the
        debug snapshot variable to avoid heavy array reasoning in assertions.
        """
        emit_reg_dbg = getattr(self, "_emit_reg_debug", True)
        if "[" not in name or not name.endswith("]"):
            return None
        base, idx = name.split("[", 1)
        idx = idx.rstrip("]")
        idx_norm = idx.strip()
        if idx_norm not in {"0", "0bv32", "0bv16"}:
            return None
        for regs in self._node_register_arrays.values():
            for reg_name, (_idx_type, elem_type) in regs.items():
                if base == reg_name:
                    # Prefer the per-pass debug snapshot when enabled; otherwise fall back to the
                    # scalar mirror that tracks the last value written at index 0.
                    if emit_reg_dbg and self._register_debug_enabled_for_type(elem_type):
                        return self._register_debug_var_name(reg_name)
                    return self._register_last0_value_name(reg_name)
        return None

    def _emit_global_init_statements(self, node_aliases: List[str]) -> str:
        """
        Emit one-time initialization for DSL state vars based on `var_decl` and `assignment` statements.
        """
        out: List[str] = []

        # global: var_decl and assignments to DSL globals
        for stmt in self._spec.global_decl.statements:
            if not isinstance(stmt, Tree):
                continue
            st = str(stmt.data)
            if st == "var_decl":
                var_name = self._dotted_var_to_str(stmt.children[1])
                if not _dsl_is_simple_local_name(var_name):
                    continue
                rhs = self._expr_to_boogie(stmt.children[3], current_node=node_aliases[0] if node_aliases else "global")
                out.append(f"  dsl_{var_name} := {rhs};\n")
                continue
            if st == "assignment":
                var_name = self._dotted_var_to_str(stmt.children[0])
                if not _dsl_is_simple_local_name(var_name):
                    continue
                op = str(stmt.children[1].data)
                rhs = self._expr_to_boogie(stmt.children[2], current_node=node_aliases[0] if node_aliases else "global")
                if op == "assign":
                    out.append(f"  dsl_{var_name} := {rhs};\n")
                elif op == "addeq":
                    out.append(f"  dsl_{var_name} := dsl_{var_name} + {rhs};\n")
                continue

        # per-node: initialize node DSL locals from var_decl only (assignments are per-pass).
        # NOTE: include sink/observer nodes as well since their DSL statements may run at enqueue-time.
        for node in self._spec.imports.keys():
            nd = self._spec.nodes.get(node, NodeDecl(name=node))
            for stmt in nd.statements:
                if not isinstance(stmt, Tree) or str(stmt.data) != "var_decl":
                    continue
                var_name = self._dotted_var_to_str(stmt.children[1])
                if not _dsl_is_simple_local_name(var_name):
                    continue
                rhs = self._expr_to_boogie(stmt.children[3], current_node=node)
                out.append(f"  {node}_dsl_{var_name} := {rhs};\n")

        # per-host: initialize host DSL locals
        for host, hd in self._spec.hosts.items():
            for stmt in hd.statements:
                if not isinstance(stmt, Tree) or str(stmt.data) != "var_decl":
                    continue
                var_name = self._dotted_var_to_str(stmt.children[1])
                if not _dsl_is_simple_local_name(var_name):
                    continue
                rhs = self._expr_to_boogie(stmt.children[3], current_node=host)
                out.append(f"  {host}_dsl_{var_name} := {rhs};\n")

        return "".join(out)

    def _emit_node_pass_statements(self, node: str, indent: str) -> str:
        """
        Emit per-pass DSL imperative statements for a node.

        Policy:
        - `var_decl`: treated as one-time init (handled in ULTIMATE.start), not re-run each pass.
        - `assignment`: emitted per pass (before calling P4 mainProcedure).
        - `if`: emitted as Boogie if/else with nested statements.
        """
        nd = self._spec.nodes.get(node, NodeDecl(name=node))
        out: List[str] = []

        def emit_stmt(stmt: Tree, cur_indent: str) -> None:
            st = str(stmt.data)
            if st == "var_decl":
                return
            if st == "assignment":
                lhs_tree = stmt.children[0]
                op = str(stmt.children[1].data)  # assign|addeq
                rhs_tree = stmt.children[2]

                lhs_name = self._dotted_var_to_str(lhs_tree)
                if _dsl_is_simple_local_name(lhs_name) and lhs_name in self._dsl_node_vars.get(node, {}):
                    lhs = f"{node}_dsl_{lhs_name}"
                elif _dsl_is_simple_local_name(lhs_name) and lhs_name in self._dsl_global_vars:
                    lhs = f"dsl_{lhs_name}"
                else:
                    lhs = self._dotted_var_to_boogie(lhs_tree, current_node=node)

                rhs = self._render_assignment_rhs(lhs_tree, rhs_tree, node)
                if op == "assign":
                    out.append(f"{cur_indent}{lhs} := {rhs};\n")
                elif op == "addeq":
                    out.append(f"{cur_indent}{lhs} := {lhs} + {rhs};\n")
                return
            if st == "if_statement":
                cond = stmt.children[0]
                cond_str = self._expr_to_boogie(cond, current_node=node)
                out.append(f"{cur_indent}if ({cond_str}) {{\n")
                else_block = None
                for child in stmt.children[1:]:
                    if isinstance(child, Tree) and str(child.data) == "else_block":
                        else_block = child
                        break
                    if isinstance(child, Tree):
                        emit_stmt(child, cur_indent + "  ")
                if else_block is not None:
                    out.append(f"{cur_indent}}} else {{\n")
                    for child in else_block.children:
                        if isinstance(child, Tree):
                            emit_stmt(child, cur_indent + "  ")
                out.append(f"{cur_indent}}}\n")
                return
            # ignore other statement types (assume/assert/ltl handled elsewhere)

        for stmt in nd.statements:
            if isinstance(stmt, Tree):
                emit_stmt(stmt, indent)

        return "".join(out)

    def _collect_dsl_modified_boogie_vars(self, node: str) -> set[str]:
        """
        Collect Boogie globals that may be modified by per-pass DSL statements in `node`.

        This is used to conservatively populate `modifies` clauses for node threads, so
        Ultimate's Boogie type checker accepts cross-node instrumentation like:
          node s1 { if (...) { s2_sequence_reg_0[0] = 65535; } }
        """
        nd = self._spec.nodes.get(node, NodeDecl(name=node))
        out: set[str] = set()

        def add_lhs(lhs_tree: Tree) -> None:
            lhs_name = self._dotted_var_to_str(lhs_tree)
            if _dsl_is_simple_local_name(lhs_name) and lhs_name in self._dsl_node_vars.get(node, {}):
                out.add(f"{node}_dsl_{lhs_name}")
                return
            if _dsl_is_simple_local_name(lhs_name) and lhs_name in self._dsl_global_vars:
                out.add(f"dsl_{lhs_name}")
                return
            lhs = self._dotted_var_to_boogie(lhs_tree, current_node=node)
            base = lhs.split("[", 1)[0] if "[" in lhs else lhs
            out.add(base)

        def visit(stmt: Tree) -> None:
            st = str(stmt.data)
            if st == "var_decl":
                return
            if st == "assignment":
                lhs_tree = stmt.children[0]
                if isinstance(lhs_tree, Tree):
                    add_lhs(lhs_tree)
                return
            if st == "if_statement":
                for child in stmt.children[1:]:
                    if not isinstance(child, Tree):
                        continue
                    if str(child.data) == "else_block":
                        for nested in child.children:
                            if isinstance(nested, Tree):
                                visit(nested)
                    else:
                        visit(child)
                return

        for stmt in nd.statements:
            if isinstance(stmt, Tree):
                visit(stmt)

        return out

    def _collect_env_modified_boogie_vars(self, owner: str) -> set[str]:
        """
        Collect Boogie globals that may be assigned by an env block.

        Env blocks are emitted in EnvThread or host-send scheduler steps, not inside
        the P4 procedure they are preparing.  Their LHS variables therefore need to
        appear in the surrounding harness procedure's `modifies` clause.  This is
        especially important when a host script intentionally drives P4 table-action
        selectors or action parameters such as `sw_table.action_run`.
        """

        if owner in self._spec.hosts:
            env_statements = self._spec.hosts[owner].env_statements
            local_dsl_vars = self._dsl_host_vars.get(owner, {})
        else:
            env_statements = self._spec.nodes.get(owner, NodeDecl(name=owner)).env_statements
            local_dsl_vars = self._dsl_node_vars.get(owner, {})

        out: set[str] = set()

        def declared_boogie_global(name: str) -> bool:
            base = name.split("[", 1)[0] if "[" in name else name
            for alias in self._spec.imports.keys():
                prefix = f"{alias}_"
                if not base.startswith(prefix):
                    continue
                return base[len(prefix) :] in self._node_declared_vars.get(alias, set())
            for host in self._spec.hosts.keys():
                prefix = f"{host}_"
                if not base.startswith(prefix):
                    continue
                return base[len(prefix) :] in self._host_declared_vars.get(host, set())
            return base.startswith("dsl_") or "_dsl_" in base

        def add_lhs(lhs_tree: Tree) -> None:
            lhs_name = self._dotted_var_to_str(lhs_tree)
            if _dsl_is_simple_local_name(lhs_name) and lhs_name in local_dsl_vars:
                out.add(f"{owner}_dsl_{lhs_name}")
                return
            if _dsl_is_simple_local_name(lhs_name) and lhs_name in self._dsl_global_vars:
                out.add(f"dsl_{lhs_name}")
                return

            lhs = self._dotted_var_to_boogie(lhs_tree, current_node=owner)
            base = lhs.split("[", 1)[0] if "[" in lhs else lhs
            if declared_boogie_global(base):
                out.add(base)

        def visit(stmt: Tree) -> None:
            st = str(stmt.data)
            if st == "var_decl":
                return
            if st == "assignment":
                lhs_tree = stmt.children[0]
                if isinstance(lhs_tree, Tree):
                    add_lhs(lhs_tree)
                return
            if st == "if_statement":
                for child in stmt.children[1:]:
                    if not isinstance(child, Tree):
                        continue
                    if str(child.data) == "else_block":
                        for nested in child.children:
                            if isinstance(nested, Tree):
                                visit(nested)
                    else:
                        visit(child)
                return
            if st == "env_block":
                for child in stmt.children:
                    if isinstance(child, Tree):
                        visit(child)

        for stmt in env_statements:
            if isinstance(stmt, Tree):
                visit(stmt)

        return out

    def _collect_top_level_constant_assign_targets(self, rendered_block: str, *, indent: str) -> set[str]:
        """
        Collect top-level assignment LHS names that are unconditionally overwritten.

        We use this to skip redundant `havoc` for fields that are deterministically
        overwritten by env injection code on every packet construction.

        Soundness guard:
        - Only top-level statements (exact indentation match) are considered.
        - Assignments must be plain `lhs := rhs` and non-self-referential on RHS.
          (e.g., `x := x + 1` is excluded because old `x` matters).
        - Assignments inside `if` branches are ignored.
        """

        out: set[str] = set()
        for raw in rendered_block.splitlines():
            if not raw.startswith(indent):
                continue
            tail = raw[len(indent) :]
            # Ignore nested statements under `if` / `else`.
            if tail.startswith(" ") or tail.startswith("\t"):
                continue
            m = self._TOPLEVEL_ASSIGN_RE.match(tail)
            if not m:
                continue
            lhs = m.group(1).strip()
            rhs = m.group(2).strip()
            if not lhs:
                continue

            # Exclude any self-reference in RHS.
            # For indexed lhs (e.g., arr[0]), also exclude references to the base (`arr`).
            tokens = set(self._ASSIGN_TOKEN_RE.findall(rhs))
            if lhs in tokens:
                continue
            base = lhs.split("[", 1)[0]
            if base and base in tokens:
                continue

            out.add(lhs)
        return out

    def _emit_env_inject_statements(self, node: str, indent: str) -> str:
        """
        Emit DSL env-block statements for external packet injection.

        Policy:
        - `var_decl`: ignored here (handled in ULTIMATE.start).
        - `assignment`/`if`: emitted in EnvThread before enqueue.
        - `assume`/`assert`: treated as assume (environment restriction).
        """
        nd = self._spec.nodes.get(node, NodeDecl(name=node))
        out: List[str] = []

        def _ref_is_available(name: str) -> bool:
            if _dsl_is_simple_local_name(name) and name in self._dsl_node_vars.get(node, {}):
                return True
            if _dsl_is_simple_local_name(name) and name in self._dsl_global_vars:
                return True
            # Match `_dotted_var_to_boogie`'s node-prefix splitting and declaration resolution
            # so that specs can refer to either `hdr.x` or `hdr.x_0` depending on P4B output.
            target = node
            raw = name
            for a in list(self._spec.imports.keys()) + list(self._host_to_node.keys()):
                if raw.startswith(f"{a}_"):
                    target = a
                    raw = raw[len(a) + 1 :]
                    break

            decl = self._get_declared_vars(target)
            base = raw
            if "[" in raw:
                base = raw.split("[", 1)[0]
            if base in decl:
                return True
            if base.endswith("_0") and base[:-2] in decl:
                return True
            if f"{base}_0" in decl:
                return True
            return False

        def _stmt_refs_available(stmt: Tree) -> bool:
            for v in _collect_dotted_vars(stmt):
                if not _ref_is_available(v):
                    return False
            return True

        def emit_bool_block(stmt: Tree, cur_indent: str) -> None:
            for expr in self._extract_bool_exprs(stmt):
                if not _stmt_refs_available(expr):
                    continue
                out.append(f"{cur_indent}assume {self._expr_to_boogie(expr, current_node=node)};\n")

        def emit_stmt(stmt: Tree, cur_indent: str) -> None:
            st = str(stmt.data)
            if st == "var_decl":
                return
            if st == "assignment":
                if not _stmt_refs_available(stmt):
                    return
                lhs_tree = stmt.children[0]
                op = str(stmt.children[1].data)  # assign|addeq
                rhs_tree = stmt.children[2]

                lhs_name = self._dotted_var_to_str(lhs_tree)
                if _dsl_is_simple_local_name(lhs_name) and lhs_name in self._dsl_node_vars.get(node, {}):
                    lhs = f"{node}_dsl_{lhs_name}"
                elif _dsl_is_simple_local_name(lhs_name) and lhs_name in self._dsl_global_vars:
                    lhs = f"dsl_{lhs_name}"
                else:
                    lhs = self._dotted_var_to_boogie(lhs_tree, current_node=node)

                rhs = self._render_assignment_rhs(lhs_tree, rhs_tree, node)
                if op == "assign":
                    out.append(f"{cur_indent}{lhs} := {rhs};\n")
                elif op == "addeq":
                    out.append(f"{cur_indent}{lhs} := {lhs} + {rhs};\n")
                return
            if st == "if_statement":
                cond = stmt.children[0]
                if isinstance(cond, Tree) and not _stmt_refs_available(cond):
                    return
                cond_str = self._expr_to_boogie(cond, current_node=node)
                out.append(f"{cur_indent}if ({cond_str}) {{\n")
                else_block = None
                for child in stmt.children[1:]:
                    if isinstance(child, Tree) and str(child.data) == "else_block":
                        else_block = child
                        break
                    if isinstance(child, Tree):
                        emit_stmt(child, cur_indent + "  ")
                if else_block is not None:
                    out.append(f"{cur_indent}}} else {{\n")
                    for child in else_block.children:
                        if isinstance(child, Tree):
                            emit_stmt(child, cur_indent + "  ")
                out.append(f"{cur_indent}}}\n")
                return
            if st in {"assume_statement", "assert_statement"}:
                emit_bool_block(stmt, cur_indent)
                return
            if st == "env_block":
                for child in stmt.children:
                    if isinstance(child, Tree):
                        emit_stmt(child, cur_indent)
                return

        for stmt in nd.env_statements:
            if isinstance(stmt, Tree):
                emit_stmt(stmt, indent)

        return "".join(out)

    def _emit_host_env_inject_statements(self, host: str, indent: str) -> str:
        """
        Emit DSL env-block statements for host injection.
        """
        hd = self._spec.hosts.get(host, HostDecl(name=host))
        out: List[str] = []
        target = self._host_to_node.get(host, "")

        def _ref_is_available(name: str) -> bool:
            if _dsl_is_simple_local_name(name) and name in self._dsl_host_vars.get(host, {}):
                return True
            if _dsl_is_simple_local_name(name) and name in self._dsl_global_vars:
                return True
            # Match `_dotted_var_to_boogie`'s node-prefix splitting and declaration resolution
            # so that specs can refer to either `hdr.x` or `hdr.x_0` depending on P4B output.
            default = target or host
            target_name = default
            raw = name
            for a in list(self._spec.imports.keys()) + list(self._host_to_node.keys()):
                if raw.startswith(f"{a}_"):
                    target_name = a
                    raw = raw[len(a) + 1 :]
                    break

            decl = self._get_declared_vars(target_name)
            base = raw
            if "[" in raw:
                base = raw.split("[", 1)[0]
            if base in decl:
                return True
            if base.endswith("_0") and base[:-2] in decl:
                return True
            if f"{base}_0" in decl:
                return True
            return False

        def _stmt_refs_available(stmt: Tree) -> bool:
            for v in _collect_dotted_vars(stmt):
                if not _ref_is_available(v):
                    return False
            return True

        def emit_bool_block(stmt: Tree, cur_indent: str) -> None:
            for expr in self._extract_bool_exprs(stmt):
                if not _stmt_refs_available(expr):
                    continue
                out.append(f"{cur_indent}assume {self._expr_to_boogie(expr, current_node=host)};\n")

        def emit_stmt(stmt: Tree, cur_indent: str) -> None:
            st = str(stmt.data)
            if st == "var_decl":
                return
            if st == "assignment":
                if not _stmt_refs_available(stmt):
                    return
                lhs_tree = stmt.children[0]
                op = str(stmt.children[1].data)  # assign|addeq
                rhs_tree = stmt.children[2]

                lhs_name = self._dotted_var_to_str(lhs_tree)
                if _dsl_is_simple_local_name(lhs_name) and lhs_name in self._dsl_host_vars.get(host, {}):
                    lhs = f"{host}_dsl_{lhs_name}"
                elif _dsl_is_simple_local_name(lhs_name) and lhs_name in self._dsl_global_vars:
                    lhs = f"dsl_{lhs_name}"
                else:
                    lhs = self._dotted_var_to_boogie(lhs_tree, current_node=host)

                rhs = self._render_assignment_rhs(lhs_tree, rhs_tree, host)
                if op == "assign":
                    out.append(f"{cur_indent}{lhs} := {rhs};\n")
                elif op == "addeq":
                    out.append(f"{cur_indent}{lhs} := {lhs} + {rhs};\n")
                return
            if st == "if_statement":
                cond = stmt.children[0]
                if isinstance(cond, Tree) and not _stmt_refs_available(cond):
                    return
                cond_str = self._expr_to_boogie(cond, current_node=host)
                out.append(f"{cur_indent}if ({cond_str}) {{\n")
                else_block = None
                for child in stmt.children[1:]:
                    if isinstance(child, Tree) and str(child.data) == "else_block":
                        else_block = child
                        break
                    if isinstance(child, Tree):
                        emit_stmt(child, cur_indent + "  ")
                if else_block is not None:
                    out.append(f"{cur_indent}}} else {{\n")
                    for child in else_block.children:
                        if isinstance(child, Tree):
                            emit_stmt(child, cur_indent + "  ")
                out.append(f"{cur_indent}}}\n")
                return
            if st in {"assume_statement", "assert_statement"}:
                emit_bool_block(stmt, cur_indent)
                return
            if st == "env_block":
                for child in stmt.children:
                    if isinstance(child, Tree):
                        emit_stmt(child, cur_indent)
                return

        for stmt in hd.env_statements:
            if isinstance(stmt, Tree):
                emit_stmt(stmt, indent)

        return "".join(out)

    def _render_assignment_rhs(self, lhs_tree: Tree, rhs_tree: Tree, node: str) -> str:
        """
        Render RHS with a bv literal when assigning a numeric constant to a bitvector field.
        """
        if not isinstance(rhs_tree, Tree):
            return self._expr_to_boogie(rhs_tree, current_node=node)
        if str(rhs_tree.data) != "number":
            return self._expr_to_boogie(rhs_tree, current_node=node)
        if not isinstance(lhs_tree, Tree) or str(lhs_tree.data) != "dotted_var":
            return self._expr_to_boogie(rhs_tree, current_node=node)

        lhs_name = self._dotted_var_to_str(lhs_tree)
        if _dsl_is_simple_local_name(lhs_name):
            return self._expr_to_boogie(rhs_tree, current_node=node)

        raw = lhs_name
        node_ctx = node
        for a in self._spec.imports.keys():
            if lhs_name.startswith(f"{a}_"):
                node_ctx = a
                raw = lhs_name[len(a) + 1 :]
                break
        width = self._infer_bv_width_for_node(node_ctx, raw)
        if width is not None:
            return f"{rhs_tree.children[0]}bv{width}"
        return self._expr_to_boogie(rhs_tree, current_node=node)

    def _extract_bool_exprs(self, assert_or_assume_stmt: Tree) -> List[Tree]:
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

    def _dotted_var_to_str(self, node: Tree) -> str:
        # Similar to frontend parse: best-effort reconstruction of dotted_var.
        if not isinstance(node, Tree):
            return str(node)
        if str(node.data) != "dotted_var":
            if node.children and isinstance(node.children[0], Tree):
                return self._dotted_var_to_str(node.children[0])
            return ".".join(str(c) for c in node.children)

        parts: List[str] = []
        cur = ""
        for item in node.children:
            if hasattr(item, "type"):
                if item.type == "NAME":
                    cur += str(item) + "."
                elif item.type == "INTSEG":
                    cur += str(item) + "."
                elif item.type == "INT":
                    cur = cur.rstrip(".")
                    # Emit bv32 literal indices for Boogie arrays.
                    cur += f"[{item}bv32]."
        cur = cur.rstrip(".")
        return cur

    @staticmethod
    def _dotted_var_to_str_static(node: Tree) -> str:
        if not isinstance(node, Tree):
            return str(node)
        if str(node.data) != "dotted_var":
            if node.children and isinstance(node.children[0], Tree):
                return BoogieBackend._dotted_var_to_str_static(node.children[0])
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

    def _infer_bv_width(self, dotted_var: Tree) -> Optional[int]:
        """
        Meta-driven inference for bitvector width.

        We first consult P4B meta (var_types / sizes) for the relevant node, and only fall back to None.
        """
        name = self._dotted_var_to_str(dotted_var)

        # Determine which node this refers to (supports cross-node refs like s2_hdr...).
        node = None
        base = name
        for a in self._spec.imports.keys():
            if name.startswith(f"{a}_"):
                node = a
                base = name[len(a) + 1 :]
                break
        if node is None:
            # Unknown node at this layer; let wrapper resolve (we keep this function for convenience).
            return None

        return self._infer_bv_width_for_node(node, base)

    def _infer_bv_width_for_node(self, node: str, base: str) -> Optional[int]:
        if node in self._host_to_node:
            node = self._host_to_node[node]
        # Array element access: meta stores the array variable type (e.g., sequence_reg_0:[bv32]bv16)
        # under the base name without indices.
        if "[" in base:
            base = base.split("[", 1)[0]
        candidates = [base]
        if base.endswith("_0"):
            candidates.append(base[:-2])
        else:
            candidates.append(base + "_0")

        # Prefer var_types, e.g., "bv32"
        vt = None
        for c in candidates:
            vt = self._meta_var_types.get(node, {}).get(c)
            if vt is not None:
                break
        if isinstance(vt, str):
            if vt.startswith("bv") and vt[2:].isdigit():
                try:
                    return int(vt[2:])
                except Exception:
                    pass
            # Array types like "[bv32]bv16" (register arrays). Some P4 programs use typedefs
            # for the index type (e.g., `type sw_lid_t = bv32;`), so accept any index type
            # here and only parse the element width.
            m = re.fullmatch(r"\[[^\]]+\]bv(\d+)", vt)
            if m:
                try:
                    return int(m.group(1))
                except Exception:
                    pass
            # Array types like "[bv32]sw_pair" where sw_pair is a Boogie type alias to bvN.
            # Same as above: accept non-bv index aliases.
            m = re.fullmatch(r"\[[^\]]+\]([A-Za-z0-9_\.\$]+)", vt)
            if m:
                elem = m.group(1)
                if elem.startswith("bv") and elem[2:].isdigit():
                    try:
                        return int(elem[2:])
                    except Exception:
                        pass
                alias = self._node_type_defs.get(node, {}).get(elem)
                if isinstance(alias, str) and alias.startswith("bv") and alias[2:].isdigit():
                    try:
                        return int(alias[2:])
                    except Exception:
                        pass

        # Fall back to sizes map if present.
        sz = None
        for c in candidates:
            sz = self._meta_sizes.get(node, {}).get(c)
            if sz is not None:
                break
        if isinstance(sz, int) and sz > 0:
            return sz
        # Last resort: use Boogie var types from the generated .bpl.
        vt2 = None
        for c in candidates:
            vt2 = self._node_var_types.get(node, {}).get(c)
            if vt2 is not None:
                break
        if isinstance(vt2, str):
            if vt2.startswith("bv") and vt2[2:].isdigit():
                try:
                    return int(vt2[2:])
                except Exception:
                    return None
            # Array types like "[bv32]bv16" or "[bv32]sw_pair" in the generated .bpl.
            # Accept non-bv index aliases as well (e.g., "[sw_lid_t]bv8").
            m = re.fullmatch(r"\[[^\]]+\]([A-Za-z0-9_\.\$]+)", vt2)
            if m:
                elem = m.group(1)
                if elem.startswith("bv") and elem[2:].isdigit():
                    try:
                        return int(elem[2:])
                    except Exception:
                        return None
                alias = self._node_type_defs.get(node, {}).get(elem)
                if isinstance(alias, str) and alias.startswith("bv") and alias[2:].isdigit():
                    try:
                        return int(alias[2:])
                    except Exception:
                        return None
            alias = self._node_type_defs.get(node, {}).get(vt2)
            if isinstance(alias, str) and alias.startswith("bv") and alias[2:].isdigit():
                try:
                    return int(alias[2:])
                except Exception:
                    return None
        return None

    def _infer_expr_width_bits(self, expr: Tree) -> Optional[int]:
        """
        Best-effort bitwidth inference for comparisons.
        """
        if not isinstance(expr, Tree):
            return None
        t = str(expr.data)
        if t == "var" and expr.children and isinstance(expr.children[0], Tree):
            return self._infer_expr_width_bits(expr.children[0])
        if t == "dotted_var":
            return self._infer_bv_width(expr)
        if t == "bit_slice":
            return self._slice_width_bits(expr)
        return None

    @staticmethod
    def _slice_width_bits(expr: Tree) -> Optional[int]:
        if not isinstance(expr, Tree) or str(expr.data) != "bit_slice":
            return None
        try:
            if len(expr.children) == 3:
                hi = int(str(expr.children[1]))
                lo = int(str(expr.children[2]))
            elif len(expr.children) == 2:
                bounds = str(expr.children[1]).strip("[]")
                hi_s, lo_s = bounds.split(":", 1)
                hi = int(hi_s)
                lo = int(lo_s)
            else:
                return None
        except Exception:
            return None
        if hi <= lo:
            return None
        return hi - lo


__all__ = ['BoogieHarnessEmitter']
