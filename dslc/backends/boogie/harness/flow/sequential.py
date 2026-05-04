from __future__ import annotations

from typing import List, NamedTuple, Optional, Tuple

from .....speclang.model import NodeDecl
from ...core.errors import BoogieBackendError


class _BoundedDirectRender(NamedTuple):
    text: str
    handled: bool


class BoogieHarnessSequentialMixin:
    def _needs_deterministic_phase_var(self) -> bool:
        """
        Whether the sequential harness needs a runtime scheduler phase variable.

        When `max_steps` is small (<= 1000), we unroll `mainProcedure` for fast bug finding.
        In that case, we can emit the deterministic round-robin schedule directly in `mainProcedure`
        and avoid introducing a phase variable (which otherwise creates many spurious paths for
        Ultimate's TraceAbstraction).
        """

        if self._spec.global_decl.deterministic_scheduler is not True:
            return False
        if self._max_steps is not None and self._max_steps <= 1000:
            return False
        return True

    def _accumulate_global_assertions(self) -> bool:
        """
        Whether to convert per-step global assertions into a single end-of-run assertion.

        TraceAbstraction can struggle when the same global assertion is checked at many locations
        (e.g., once per node pass) in a bounded, unrolled harness. In bounded bug-finding mode, we
        accumulate all global assertion violations in a boolean flag and assert it at the end.

        This is semantics-preserving for safety: a violation at any step sets the flag permanently.
        """

        return (
            self._harness_mode == "sequential"
            and self._max_steps is not None
            and self._max_steps <= 1000
            and bool(self._accumulated_global_assert_exprs())
        )

    def _active_global_assert_exprs(self):
        return [
            expr
            for idx, expr in enumerate(self._spec.global_decl.assert_exprs)
            if idx not in self._p4b_fail_fast_global_assert_indices
        ]

    def _accumulated_global_assert_exprs(self):
        return [
            expr
            for expr in self._active_global_assert_exprs()
            if not self._has_bounded_direct_global_assert(expr)
        ]

    def _has_bounded_direct_global_assert(self, expr) -> bool:
        # Deliberately broader than P4B fail-fast matching: P4B only owns
        # pure write-site checks like `!(reg__wrote_any && reg__last_value==C)`.
        # This DSLC matcher accepts the harness-level guarded form because the
        # guard can mention DSL scheduler/protocol state such as `dsl_phase`.
        return self._bounded_direct_global_assert_parts(expr) is not None

    def _emit_bounded_direct_global_assertions(self) -> bool:
        return (
            self._harness_mode == "sequential"
            and self._max_steps is not None
            and self._max_steps <= 1000
            and any(self._has_bounded_direct_global_assert(expr) for expr in self._active_global_assert_exprs())
        )

    def _render_bounded_direct_global_assert(
        self,
        expr,
        *,
        current_node: str,
        indent: str,
        dsl_bounds: Optional[dict[str, int]] = None,
    ) -> _BoundedDirectRender:
        """
        Emit an extra same-step assertion for guarded register-write violations.

        Bounded sequential mode normally accumulates global assertion failures in
        `procurator_bad` and asserts once at the end. That keeps repeated global
        checks small for TraceAbstraction, but it can hide a narrow P4 write-site
        violation behind a long final proof obligation. For assertions shaped like
        `guard || !(reg__wrote_* && reg__last_* == C)`, a direct assertion at the
        pass boundary is the same property at the same check point. Assertions are
        excluded from the accumulated fallback only when this renderer either emits
        that direct check or statically discharges the guard for the current step.
        """

        if not self._emit_bounded_direct_global_assertions():
            return _BoundedDirectRender("", False)
        parts = self._bounded_direct_global_assert_parts(expr)
        if parts is None:
            return _BoundedDirectRender("", False)

        mode, guards, check = parts
        guard_parts = [self._expr_to_boogie(g, current_node=current_node, prefer_reg_dbg=True) for g in guards]
        if mode == "or_guard":
            if any(self._guard_proven_true_by_dsl_bounds(g, dsl_bounds) for g in guards):
                return _BoundedDirectRender("", True)
            guard = guard_parts[0] if len(guard_parts) == 1 else f"({' || '.join(guard_parts)})"
            check_bpl = self._expr_to_boogie(check, current_node=current_node, prefer_reg_dbg=True)
            return _BoundedDirectRender(
                f"{indent}if (!({guard})) {{\n{indent}  assert {check_bpl};\n{indent}}}\n",
                True,
            )

        guard = guard_parts[0] if len(guard_parts) == 1 else f"({' && '.join(guard_parts)})"
        check_bpl = self._direct_check_to_boogie(check, current_node=current_node)
        return _BoundedDirectRender(
            f"{indent}if ({guard}) {{\n{indent}  assert !({check_bpl});\n{indent}}}\n",
            True,
        )

    def _bounded_direct_global_assert_parts(self, expr) -> Optional[Tuple[str, list, object]]:
        if not hasattr(expr, "data"):
            return None
        terms = [c for c in getattr(expr, "children", []) if hasattr(c, "data")]
        if str(expr.data) == "or_op" and len(terms) >= 2:
            checks = [t for t in terms if self._is_negated_register_write_check(t)]
            if len(checks) == 1:
                guards = [t for t in terms if t is not checks[0]]
                if guards:
                    return "or_guard", guards, checks[0]
            return None

        if str(expr.data) != "not_op" or len(terms) != 1:
            return None
        inner = terms[0]
        if str(getattr(inner, "data", "")) != "and_op":
            return None
        inner_terms = [c for c in getattr(inner, "children", []) if hasattr(c, "data")]
        if len(inner_terms) < 3:
            return None
        check = self._register_write_check_terms(inner_terms)
        if check is None:
            return None
        guards = [t for t in inner_terms if all(t is not c for c in check)]
        if not guards:
            return None
        return "and_guard", guards, check

    def _direct_check_to_boogie(self, check, *, current_node: str) -> str:
        if isinstance(check, tuple):
            parts = [
                self._expr_to_boogie(c, current_node=current_node, prefer_reg_dbg=True) for c in check
            ]
            return f"({' && '.join(parts)})"
        return self._expr_to_boogie(check, current_node=current_node, prefer_reg_dbg=True)

    def _is_negated_register_write_check(self, expr) -> bool:
        if str(getattr(expr, "data", "")) != "not_op":
            return False
        children = [c for c in getattr(expr, "children", []) if hasattr(c, "data")]
        return len(children) == 1 and self._is_register_write_check(children[0])

    def _is_register_write_check(self, expr) -> bool:
        if str(getattr(expr, "data", "")) != "and_op":
            return False
        terms = [c for c in getattr(expr, "children", []) if hasattr(c, "data")]
        if len(terms) != 2:
            return False
        return self._register_write_check_terms(terms) is not None

    def _register_write_check_terms(self, terms) -> Optional[Tuple[object, object]]:
        candidates: list[Tuple[object, object]] = []
        for i, left in enumerate(terms):
            for right in terms[i + 1 :]:
                if self._is_register_write_check_pair(left, right):
                    candidates.append((left, right))
        if len(candidates) != 1:
            return None
        return candidates[0]

    def _is_register_write_check_pair(self, left, right) -> bool:
        for flag_expr, eq_expr in ((left, right), (right, left)):
            flag_var = self._expr_dotted_var_name(flag_expr)
            eq_info = self._expr_eq_var_number(eq_expr)
            if flag_var is None or eq_info is None:
                continue
            value_var, _const_value = eq_info
            if flag_var.endswith("__wrote_any") and value_var.endswith("__last_value"):
                return flag_var[: -len("__wrote_any")] == value_var[: -len("__last_value")]
            if flag_var.endswith("__wrote_index0") and value_var.endswith("__last0_value"):
                return flag_var[: -len("__wrote_index0")] == value_var[: -len("__last0_value")]
        return False

    def _expr_dotted_var_name(self, expr) -> Optional[str]:
        if not hasattr(expr, "data"):
            return None
        if str(expr.data) == "var":
            children = [c for c in getattr(expr, "children", []) if hasattr(c, "data")]
            if len(children) == 1:
                return self._expr_dotted_var_name(children[0])
            return None
        if str(expr.data) != "dotted_var":
            return None
        return self._dotted_var_to_str(expr)

    def _expr_eq_var_number(self, expr) -> Optional[tuple[str, str]]:
        if str(getattr(expr, "data", "")) != "eq":
            return None
        terms = [c for c in getattr(expr, "children", []) if hasattr(c, "data")]
        if len(terms) != 2:
            return None

        left_var = self._expr_dotted_var_name(terms[0])
        right_num = self._expr_number_literal(terms[1])
        if left_var is not None and right_num is not None:
            return left_var, right_num

        right_var = self._expr_dotted_var_name(terms[1])
        left_num = self._expr_number_literal(terms[0])
        if right_var is not None and left_num is not None:
            return right_var, left_num
        return None

    def _expr_number_literal(self, expr) -> Optional[str]:
        if str(getattr(expr, "data", "")) == "number" and getattr(expr, "children", None):
            return str(expr.children[0])
        return None

    def _initial_dsl_int_upper_bounds(self) -> dict[str, int]:
        bounds: dict[str, int] = {}
        node = next(iter(self._spec.imports.keys()), "global")
        for stmt in self._spec.global_decl.statements:
            if not hasattr(stmt, "data"):
                continue
            st = str(stmt.data)
            if st == "var_decl":
                name = self._dotted_var_to_str(stmt.children[1])
                if name not in self._dsl_global_vars or self._dsl_global_vars.get(name) != "int":
                    continue
                literal = self._expr_number_literal(stmt.children[3])
                if literal is not None:
                    bounds[f"dsl_{name}"] = int(literal)
                else:
                    bounds.pop(f"dsl_{name}", None)
                continue
            if st == "assignment":
                self._update_dsl_int_upper_bound_from_assignment(stmt, bounds, current_node=node, conditional=False)
        return bounds

    def _update_dsl_int_upper_bounds_from_env(self, owner: str, bounds: dict[str, int]) -> None:
        env_statements = []
        if owner in self._spec.hosts:
            env_statements = list(self._spec.hosts[owner].env_statements)
        elif owner in self._spec.nodes:
            env_statements = list(self._spec.nodes[owner].env_statements)

        for stmt in env_statements:
            if not hasattr(stmt, "data"):
                continue
            if str(stmt.data) == "assignment":
                self._update_dsl_int_upper_bound_from_assignment(stmt, bounds, current_node=owner, conditional=True)
                continue
            # Nested conditionals and unknown statements may update DSL globals on only
            # some paths. Drop affected bounds so assertion pruning stays conservative.
            for name in self._assigned_dsl_global_ints(stmt):
                bounds.pop(f"dsl_{name}", None)

    def _update_dsl_int_upper_bounds_from_node_pass(self, node: str, bounds: dict[str, int]) -> None:
        nd = self._spec.nodes.get(node, NodeDecl(name=node))
        for stmt in nd.statements:
            if not hasattr(stmt, "data"):
                continue
            if str(stmt.data) == "assignment":
                self._update_dsl_int_upper_bound_from_assignment(
                    stmt, bounds, current_node=node, conditional=False
                )
                continue
            if str(stmt.data) == "var_decl":
                continue
            for name in self._assigned_dsl_global_ints(stmt):
                bounds.pop(f"dsl_{name}", None)

    def _update_dsl_int_upper_bound_from_assignment(
        self,
        stmt,
        bounds: dict[str, int],
        *,
        current_node: str,
        conditional: bool,
    ) -> None:
        lhs_tree = stmt.children[0]
        lhs_name = self._dotted_var_to_str(lhs_tree)
        if lhs_name not in self._dsl_global_vars or self._dsl_global_vars.get(lhs_name) != "int":
            return
        key = f"dsl_{lhs_name}"
        op = str(stmt.children[1].data)
        rhs_literal = self._expr_number_literal(stmt.children[2])
        if rhs_literal is None:
            bounds.pop(key, None)
            return

        rhs = int(rhs_literal)
        if op == "assign":
            if conditional and key in bounds:
                bounds[key] = max(bounds[key], rhs)
            elif not conditional:
                bounds[key] = rhs
            else:
                bounds.pop(key, None)
            return
        if op == "addeq":
            if key not in bounds:
                return
            # We only use upper bounds to prove guards true. For negative increments,
            # keeping the old upper bound is conservative; for positive increments,
            # the possible maximum increases by that amount.
            if rhs > 0:
                bounds[key] += rhs
            return
        bounds.pop(key, None)

    def _assigned_dsl_global_ints(self, stmt) -> set[str]:
        out: set[str] = set()
        if not hasattr(stmt, "data"):
            return out
        if str(stmt.data) == "assignment":
            lhs = self._dotted_var_to_str(stmt.children[0])
            if lhs in self._dsl_global_vars and self._dsl_global_vars.get(lhs) == "int":
                out.add(lhs)
            return out
        for child in getattr(stmt, "children", []):
            if hasattr(child, "data"):
                out.update(self._assigned_dsl_global_ints(child))
        return out

    def _guard_proven_true_by_dsl_bounds(self, expr, bounds: Optional[dict[str, int]]) -> bool:
        if not bounds:
            return False
        if not hasattr(expr, "data"):
            return False
        t = str(expr.data)
        terms = [c for c in getattr(expr, "children", []) if hasattr(c, "data")]
        if t == "or_op":
            return any(self._guard_proven_true_by_dsl_bounds(term, bounds) for term in terms)
        if t not in {"less", "less_eq", "greater", "greater_eq"} or len(terms) != 2:
            return False

        left_var = self._dsl_bound_key_for_expr(terms[0])
        right_num = self._expr_number_literal(terms[1])
        if left_var is not None and right_num is not None and left_var in bounds:
            upper = bounds[left_var]
            threshold = int(right_num)
            if t == "less":
                return upper < threshold
            if t == "less_eq":
                return upper <= threshold

        right_var = self._dsl_bound_key_for_expr(terms[1])
        left_num = self._expr_number_literal(terms[0])
        if right_var is not None and left_num is not None and right_var in bounds:
            upper = bounds[right_var]
            threshold = int(left_num)
            if t == "greater":
                return upper < threshold
            if t == "greater_eq":
                return upper <= threshold
        return False

    def _dsl_bound_key_for_expr(self, expr) -> Optional[str]:
        name = self._expr_dotted_var_name(expr)
        if name is None:
            return None
        if name in self._dsl_global_vars:
            return f"dsl_{name}"
        if name.startswith("dsl_") and name[4:] in self._dsl_global_vars:
            return name
        return None

    def _emit_sequential_main(
        self,
        node_aliases: List[str],
        host_aliases: List[str],
        *,
        k: int,
        env_thread_enabled: bool,
    ) -> str:
        """
        Emit a single-thread scheduler as:
          - `main()` performs exactly one atomic step (one env injection / one node pass / one host action / idle).
          - `mainProcedure()` initializes state once, then loops forever calling `main()`.

        This is intended to be compatible with sequential Ultimate toolchains (no fork/atomic).
        """
        self._trace_node_ids = {n: i + 1 for i, n in enumerate(node_aliases)}
        deterministic = self._spec.global_decl.deterministic_scheduler is True
        needs_phase = self._needs_deterministic_phase_var()
        deterministic_unroll = deterministic and not needs_phase and self._max_steps is not None and self._max_steps <= 1000
        mods = self._compute_harness_modifies(node_aliases, host_aliases, include_lock=False)
        mods.add("procurator_step")
        if self._accumulate_global_assertions():
            mods.add("procurator_bad")
        if needs_phase:
            mods.add("procurator_phase")

        actions: List[tuple[str, str]] = []
        if env_thread_enabled:
            nodes = [n for n in self._spec.imports.keys() if not self._is_sink_node(n)]
            if not nodes:
                raise BoogieBackendError("env_thread requires at least one non-sink node")
            marked = [n for n in nodes if self._spec.nodes.get(n, NodeDecl(name=n)).external_input is True]
            inject_targets = marked if marked else nodes  # compatibility fallback
            for n in inject_targets:
                actions.append(("env_inject", n))
        for h in host_aliases:
            actions.append(("host_send", h))
        for h in host_aliases:
            actions.append(("host_recv", h))
        for n in node_aliases:
            if self._is_two_stage_node(n):
                actions.append(("node_ingress", n))
                actions.append(("node_egress", n))
            else:
                actions.append(("node_pass", n))

        out: List[str] = []

        if not deterministic_unroll:
            out.append("procedure main() returns()\n")
            if mods:
                out.append("  modifies " + ", ".join(sorted(mods)) + ";\n")
            out.append("{\n")
            out.append("  // One scheduler step: pick exactly one action.\n")
            if needs_phase:
                out.append("  // Scheduler: deterministic round-robin over the action list.\n")

            indent = "    "
            trace_reset = self._emit_trace_step_reset(node_aliases, indent=indent)
            if trace_reset:
                out.append(f"{indent}// Reset trace flags for this step.\n")
                out.append(trace_reset)

            period = len(actions) if actions else 0
            for i, (kind, name) in enumerate(actions):
                if needs_phase:
                    cond = f"(procurator_phase == {i})"
                    head = f"if {cond}" if i == 0 else f"}} else if {cond}"
                else:
                    head = "if (*)" if i == 0 else "} else if (*)"
                out.append("  " + head + " {\n")
                if kind == "env_inject":
                    out.append(f"{indent}// env inject -> {name}\n")
                    out.append(self._emit_external_enqueue_stmt(name, k, indent=indent, deterministic=deterministic))
                elif kind == "host_send":
                    out.append(f"{indent}// host send -> {name}\n")
                    out.append(
                        self._emit_sequential_host_send_step(name, k=k, indent=indent, deterministic=deterministic)
                    )
                elif kind == "host_recv":
                    out.append(f"{indent}// host recv -> {name}\n")
                    out.append(self._emit_sequential_host_recv_step(name, indent=indent, deterministic=deterministic))
                elif kind == "node_pass":
                    out.append(f"{indent}// node pass -> {name}\n")
                    out.append(self._emit_sequential_node_pass_step(name, k=k, indent=indent, deterministic=deterministic))
                elif kind == "node_ingress":
                    out.append(f"{indent}// node ingress -> {name}\n")
                    out.append(
                        self._emit_sequential_node_ingress_step(name, k=k, indent=indent, deterministic=deterministic)
                    )
                elif kind == "node_egress":
                    out.append(f"{indent}// node egress -> {name}\n")
                    out.append(
                        self._emit_sequential_node_egress_step(name, k=k, indent=indent, deterministic=deterministic)
                    )
                else:
                    raise AssertionError(f"unhandled sequential action: {kind}")

            if actions:
                out.append("  } else {\n")
                if needs_phase:
                    out.append(f"{indent}assume false;\n")
                else:
                    out.append(f"{indent}// idle\n")
                out.append("  }\n")

            if needs_phase:
                # Next action in the fixed round-robin schedule.
                out.append(f"{indent}if (procurator_phase == {period - 1}) {{\n")
                out.append(f"{indent}  procurator_phase := 0;\n")
                out.append(f"{indent}}} else {{\n")
                out.append(f"{indent}  procurator_phase := procurator_phase + 1;\n")
                out.append(f"{indent}}}\n")

            out.append("}\n")
            out.append("\n")

        # mainProcedure: one-time init + infinite loop
        out.append("procedure mainProcedure() returns()\n")
        if mods:
            out.append("  modifies " + ", ".join(sorted(mods)) + ";\n")
        out.append("{\n")
        out.append("  // initialize inboxes\n")
        for a in node_aliases + host_aliases:
            out.append(f"  {a}_inbox_count := 0;\n")
            out.append(f"  {a}_pkt_external := false;\n")
        out.append("  // initialize P4B event flags (clone/recirculate)\n")
        for n in node_aliases:
            declared = self._node_declared_vars.get(n, set())
            for f in ("p4b_clone_i2e", "p4b_clone_e2e", "p4b_clone_i2i", "p4b_recirculate"):
                if f in declared:
                    out.append(f"  {n}_{f} := false;\n")
        if self._two_stage_nodes:
            out.append("  // initialize pending egress counters\n")
            for a in node_aliases:
                if self._is_two_stage_node(a):
                    out.append(f"  {a}_egress_count := 0;\n")
        if self._spec.global_decl.symmetry_groups:
            out.append("\n")
            out.append("  // Symmetry breaking: ordered inbox counts for equivalent nodes.\n")
            for group in self._spec.global_decl.symmetry_groups:
                if len(group) < 2:
                    continue
                for left, right in zip(group, group[1:]):
                    out.append(f"  assume {left}_inbox_count <= {right}_inbox_count;\n")
        out.append("\n")

        init_lines = self._emit_global_init_statements(node_aliases)
        if init_lines:
            out.append("  // initialize DSL state\n")
            out.append(init_lines)
        reg_init = self._emit_register_init_assumes(node_aliases)
        if reg_init:
            out.append("  // initialize P4 registers (default 0)\n")
            out.append(reg_init)
        reg_dbg_init = self._emit_register_write_debug_init(node_aliases)
        if reg_dbg_init:
            out.append("  // initialize register write tracking (debug)\n")
            out.append(reg_dbg_init)
        out.append("\n")

        out.append("  procurator_step := 0;\n")
        if self._accumulate_global_assertions():
            out.append("  procurator_bad := false;\n")
        if needs_phase:
            out.append("  procurator_phase := 0;\n")
        # For bug-finding we prefer bounded *unrolling* when max_steps is small. This avoids
        # loop reasoning overhead in TraceAbstraction and typically finds shallow counterexamples
        # much faster than a bounded while-loop.
        if deterministic_unroll:
            trace_reset = self._emit_trace_step_reset(node_aliases, indent="  ")
            period = len(actions) if actions else 0
            dsl_bounds: Optional[dict[str, int]] = self._initial_dsl_int_upper_bounds()
            for step in range(self._max_steps or 0):
                if trace_reset:
                    out.append("  // Reset trace flags for this step.\n")
                    out.append(trace_reset)
                if period:
                    kind, name = actions[step % period]
                    out.append(f"  // step {step}: {kind} -> {name}\n")
                    if kind == "env_inject":
                        out.append(self._emit_external_enqueue_stmt(name, k, indent="  ", deterministic=True))
                        if dsl_bounds is not None:
                            self._update_dsl_int_upper_bounds_from_env(name, dsl_bounds)
                    elif kind == "host_send":
                        out.append(self._emit_sequential_host_send_step(name, k=k, indent="  ", deterministic=True))
                        if dsl_bounds is not None:
                            self._update_dsl_int_upper_bounds_from_env(name, dsl_bounds)
                    elif kind == "host_recv":
                        out.append(self._emit_sequential_host_recv_step(name, indent="  ", deterministic=True))
                    elif kind == "node_pass":
                        out.append(
                            self._emit_sequential_node_pass_step(
                                name,
                                k=k,
                                indent="  ",
                                deterministic=True,
                                dsl_bounds=dsl_bounds,
                            )
                        )
                    elif kind == "node_ingress":
                        out.append(self._emit_sequential_node_ingress_step(name, k=k, indent="  ", deterministic=True))
                    elif kind == "node_egress":
                        out.append(self._emit_sequential_node_egress_step(name, k=k, indent="  ", deterministic=True))
                    else:
                        raise AssertionError(f"unhandled sequential action: {kind}")
                out.append("  procurator_step := procurator_step + 1;\n")
            if self._accumulate_global_assertions():
                out.append("  assert !procurator_bad;\n")
        else:
            if self._max_steps is not None:
                out.append(f"  while (procurator_step < {int(self._max_steps)}) {{\n")
            else:
                out.append("  while (true) {\n")
            out.append("    call main();\n")
            out.append("    procurator_step := procurator_step + 1;\n")
            out.append("  }\n")
            if self._accumulate_global_assertions():
                out.append("  assert !procurator_bad;\n")
        out.append("}\n")
        out.append("\n")
        return "".join(out)

    def _emit_sequential_start(self, node_aliases: List[str], host_aliases: List[str]) -> str:
        """
        Ultimate entrypoint for sequential harness.

        We expose a `ULTIMATE.start` procedure that initializes the global lock and then
        calls `mainProcedure()`. (The lock is unused in sequential mode, but some EPFs
        assume it exists.)
        """
        mods = self._compute_harness_modifies(node_aliases, host_aliases, include_lock=False)
        mods.add("procurator_step")
        if self._accumulate_global_assertions():
            mods.add("procurator_bad")
        if self._needs_deterministic_phase_var():
            mods.add("procurator_phase")
        out: List[str] = []
        out.append("procedure ULTIMATE.start() returns()\n")
        if mods:
            out.append("  modifies " + ", ".join(sorted(mods)) + ";\n")
        out.append("{\n")
        out.append("  call mainProcedure();\n")
        out.append("}\n")
        return "".join(out)

    def _emit_sequential_host_send_step(self, host: str, *, k: int, indent: str, deterministic: bool) -> str:
        node = self._host_to_node.get(host)
        if not node:
            raise BoogieBackendError(f"host '{host}' missing connect target")
        host_eager = self._spec.global_decl.host_eager is True
        host_vars = self._host_input_vars.get(host, [])
        host_decl = self._host_declared_vars.get(host, set())
        target_decl = self._node_declared_vars.get(node, set())
        copy_vars: List[str] = []
        for v in host_vars:
            if v in host_decl and v in target_decl:
                copy_vars.append(v)

        out: List[str] = []
        # In deterministic schedule mode, the scheduler already fixes *when* the host-send action
        # happens. When host_eager=true we model that the injection happens whenever this action
        # is selected; otherwise, we keep the original nondet "may send" semantics.
        if deterministic and not host_eager:
            out.append(f"{indent}if (*) {{\n")
            indent = indent + "  "

        out.append(f"{indent}// inject packet into connected node (host -> node)\n")
        if deterministic:
            out.append(f"{indent}if ({node}_inbox_count < {k}) {{\n")
            indent2 = indent + "  "
        else:
            indent2 = indent

        out.append(f"{indent2}assume {node}_inbox_count < {k};\n")

        # Construct a fresh host packet, then copy it into the node mailbox. This keeps
        # host.env { ... } semantics consistent across concurrent vs sequential harnesses.
        env_lines = ""
        top_level_const_writes: set[str] = set()
        if not self._max_env_inputs:
            env_lines = self._emit_host_env_inject_statements(host, indent=indent2)
            if env_lines:
                top_level_const_writes = self._collect_top_level_constant_assign_targets(
                    env_lines, indent=indent2
                )
        for v in host_vars:
            target = f"{host}_{v}"
            if target in top_level_const_writes:
                continue
            out.append(f"{indent2}havoc {target};\n")
        if not self._max_env_inputs:
            if env_lines:
                out.append(env_lines)
            hd = self._spec.hosts.get(host)
            if hd:
                for expr in hd.assume_exprs:
                    out.append(f"{indent2}assume {self._expr_to_boogie(expr, current_node=host)};\n")
            for expr in self._spec.global_decl.assume_exprs:
                out.append(f"{indent2}assume {self._expr_to_boogie(expr, current_node=host)};\n")

        for v in copy_vars:
            out.append(f"{indent2}{node}_{v} := {host}_{v};\n")
        out.append(f"{indent2}{node}_pkt_external := true;\n")
        if self._two_slot_inbox_enabled(k):
            out.append(self._emit_inbox_store_from_active(node, slot_expr=f"{node}_inbox_count", indent=indent2))
        out.append(f"{indent2}{node}_inbox_count := {node}_inbox_count + 1;\n")

        if deterministic:
            out.append(f"{indent}}}\n")

        if deterministic and not host_eager:
            out.append(f"{indent[:-2]}}}\n")
        return "".join(out)

    def _emit_sequential_host_recv_step(self, host: str, *, indent: str, deterministic: bool) -> str:
        if deterministic:
            return ""
        out: List[str] = []
        out.append(f"{indent}// host recv is currently a no-op in the Boogie backend\n")
        return "".join(out)

    def _emit_sequential_node_pass_step(
        self,
        node: str,
        *,
        k: int,
        indent: str,
        deterministic: bool,
        dsl_bounds: Optional[dict[str, int]] = None,
    ) -> str:
        dsl_stmt_lines = self._emit_node_pass_statements(node, indent=indent)
        node_assert_lines = self._emit_assert_lines(
            self._spec.nodes.get(node, NodeDecl(name=node)).assert_exprs,
            indent=indent,
            current_node=node,
        )
        global_track_lines = ""
        global_direct_assert_lines = ""
        global_assert_lines = ""
        active_global_asserts = self._active_global_assert_exprs()
        direct_handled: set[int] = set()
        if self._emit_bounded_direct_global_assertions():
            for idx, expr in enumerate(active_global_asserts):
                rendered = self._render_bounded_direct_global_assert(
                    expr, current_node=node, indent=indent, dsl_bounds=dsl_bounds
                )
                if rendered.handled:
                    direct_handled.add(idx)
                global_direct_assert_lines += rendered.text
        if self._accumulate_global_assertions():
            for idx, expr in enumerate(active_global_asserts):
                if idx in direct_handled:
                    continue
                bpl = self._expr_to_boogie(expr, current_node=node, prefer_reg_dbg=True)
                global_track_lines += f"{indent}if (!({bpl})) {{ procurator_bad := true; }}\n"
        else:
            fallback_global_asserts = (
                [
                    expr
                    for idx, expr in enumerate(active_global_asserts)
                    if idx not in direct_handled
                ]
                if self._emit_bounded_direct_global_assertions()
                else active_global_asserts
            )
            global_assert_lines = self._emit_assert_lines(
                fallback_global_asserts,
                indent=indent,
                current_node=node,
            )

        declared = self._node_declared_vars.get(node, set())
        clone_flags = [
            f
            for f in ("p4b_clone_i2e", "p4b_clone_e2e", "p4b_clone_i2i", "p4b_recirculate")
            if f in declared
        ]
        out: List[str] = []
        if deterministic:
            out.append(f"{indent}if ({node}_inbox_count > 0) {{\n")
        out.append(f"{indent}assume {node}_inbox_count > 0;\n")
        if self._two_slot_inbox_enabled(k):
            out.append(f"{indent}// Two-slot inbox: pick a pending packet (Bag semantics)\n")
            out.append(f"{indent}if ({node}_inbox_count == 1) {{\n")
            out.append(self._emit_inbox_load_to_active(node, slot=0, indent=indent + "  "))
            out.append(f"{indent}}} else {{\n")
            out.append(f"{indent}  if (*) {{\n")
            out.append(self._emit_inbox_load_to_active(node, slot=0, indent=indent + "    "))
            out.append(self._emit_inbox_shift_slot1_to_slot0(node, indent=indent + "    "))
            out.append(f"{indent}  }} else {{\n")
            out.append(self._emit_inbox_load_to_active(node, slot=1, indent=indent + "    "))
            out.append(f"{indent}  }}\n")
            out.append(f"{indent}}}\n")
        if self._por_enabled and self._por_guard_enabled:
            guards = self._por_guards.get(node, [])
            if guards:
                out.append(f"{indent}// POR: prefer lower-id commuting nodes when they are ready.\n")
                for other in guards:
                    out.append(f"{indent}assume {other}_inbox_count == 0;\n")
        out.append(f"{indent}{node}_inbox_count := {node}_inbox_count - 1;\n")
        if dsl_stmt_lines:
            out.append(f"{indent}// DSL statements (per-pass instrumentation)\n")
            out.append(dsl_stmt_lines)
        out.append(f"{indent}call {node}_mainProcedure();\n")
        # If the P4 program signals a derived event, enqueue it now.
        for flag in clone_flags:
            out.append(f"{indent}if ({node}_{flag}) {{\n")
            out.append(self._emit_internal_enqueue_stmt(node, k, indent=indent + "  "))
            out.append(f"{indent}}}\n")
            out.append(f"{indent}{node}_{flag} := false;\n")
        out.append(f"{indent}call {node}_Forward();\n")
        trace_lines = self._emit_trace_assignments(node, indent=indent, stage_id=3)
        dbg_needed = bool(
            node_assert_lines or global_assert_lines or global_direct_assert_lines or global_track_lines or trace_lines
        )
        if dbg_needed:
            dbg = self._emit_register_debug_assignments(indent=indent)
            if dbg:
                out.append(f"{indent}// Register debug snapshot\n")
                out.append(dbg)
        if trace_lines:
            out.append(f"{indent}// Trace snapshot\n")
            out.append(trace_lines)
        if node_assert_lines:
            out.append(f"{indent}// DSL assertions (node-local)\n")
            out.append(node_assert_lines)
        if global_direct_assert_lines:
            out.append(f"{indent}// Global assertions (direct guarded checks)\n")
            out.append(global_direct_assert_lines)
        if global_track_lines:
            out.append(f"{indent}// Global assertions (accumulated into procurator_bad)\n")
            out.append(global_track_lines)
        if global_assert_lines:
            out.append(f"{indent}// Global assertions\n")
            out.append(global_assert_lines)
        if deterministic:
            out.append(f"{indent}}}\n")
        if dsl_bounds is not None:
            self._update_dsl_int_upper_bounds_from_node_pass(node, dsl_bounds)
        return "".join(out)

    def _emit_sequential_node_ingress_step(self, node: str, *, k: int, indent: str, deterministic: bool) -> str:
        dsl_stmt_lines = self._emit_node_pass_statements(node, indent=indent)
        declared = self._node_declared_vars.get(node, set())
        clone_flags = [
            f
            for f in ("p4b_clone_i2e", "p4b_clone_e2e", "p4b_clone_i2i", "p4b_recirculate")
            if f in declared
        ]

        out: List[str] = []
        if deterministic:
            out.append(f"{indent}if ({node}_inbox_count > 0) {{\n")
        out.append(f"{indent}assume {node}_inbox_count > 0;\n")
        if self._two_slot_inbox_enabled(k):
            out.append(f"{indent}// Two-slot inbox: pick a pending packet (Bag semantics)\n")
            out.append(f"{indent}if ({node}_inbox_count == 1) {{\n")
            out.append(self._emit_inbox_load_to_active(node, slot=0, indent=indent + "  "))
            out.append(f"{indent}}} else {{\n")
            out.append(f"{indent}  if (*) {{\n")
            out.append(self._emit_inbox_load_to_active(node, slot=0, indent=indent + "    "))
            out.append(self._emit_inbox_shift_slot1_to_slot0(node, indent=indent + "    "))
            out.append(f"{indent}  }} else {{\n")
            out.append(self._emit_inbox_load_to_active(node, slot=1, indent=indent + "    "))
            out.append(f"{indent}  }}\n")
            out.append(f"{indent}}}\n")
        if self._por_enabled and self._por_guard_enabled:
            guards = self._por_guards.get(node, [])
            if guards:
                out.append(f"{indent}// POR: prefer lower-id commuting nodes when they are ready.\n")
                for other in guards:
                    out.append(f"{indent}assume {other}_inbox_count == 0;\n")
        out.append(f"{indent}{node}_inbox_count := {node}_inbox_count - 1;\n")
        out.append(
            self._emit_ingress_stage_body(
                node,
                k,
                indent=indent,
                dsl_stmt_lines=dsl_stmt_lines,
                clone_flags=clone_flags,
            )
        )
        trace_lines = self._emit_trace_assignments(node, indent=indent, stage_id=1)
        dbg_needed = bool(trace_lines)
        if dbg_needed:
            dbg = self._emit_register_debug_assignments(indent=indent)
            if dbg:
                out.append(f"{indent}// Register debug snapshot\n")
                out.append(dbg)
        if trace_lines:
            out.append(f"{indent}// Trace snapshot\n")
            out.append(trace_lines)
        if deterministic:
            out.append(f"{indent}}}\n")
        return "".join(out)

    def _emit_sequential_node_egress_step(self, node: str, *, k: int, indent: str, deterministic: bool) -> str:
        assert_lines = "".join(
            [
                self._emit_assert_lines(
                    self._spec.nodes.get(node, NodeDecl(name=node)).assert_exprs,
                    indent=indent,
                    current_node=node,
                ),
                self._emit_assert_lines(
                    self._spec.global_decl.assert_exprs,
                    indent=indent,
                    current_node=node,
                ),
            ]
        )
        declared = self._node_declared_vars.get(node, set())
        clone_flags = [
            f
            for f in ("p4b_clone_i2e", "p4b_clone_e2e", "p4b_clone_i2i", "p4b_recirculate")
            if f in declared
        ]

        out: List[str] = []
        if deterministic:
            out.append(f"{indent}if ({node}_egress_count > 0) {{\n")
        out.append(f"{indent}assume {node}_egress_count > 0;\n")
        out.append(
            self._emit_egress_stage_body(
                node,
                k,
                indent=indent,
                assert_lines=assert_lines,
                clone_flags=clone_flags,
            )
        )
        if deterministic:
            out.append(f"{indent}}}\n")
        return "".join(out)
