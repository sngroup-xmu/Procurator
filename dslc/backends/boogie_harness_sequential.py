from __future__ import annotations

from typing import List

from ..speclang.model import NodeDecl
from .boogie_errors import BoogieBackendError


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
            and bool(self._spec.global_decl.assert_exprs)
        )

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
            for step in range(self._max_steps or 0):
                if trace_reset:
                    out.append("  // Reset trace flags for this step.\n")
                    out.append(trace_reset)
                if period:
                    kind, name = actions[step % period]
                    out.append(f"  // step {step}: {kind} -> {name}\n")
                    if kind == "env_inject":
                        out.append(self._emit_external_enqueue_stmt(name, k, indent="  ", deterministic=True))
                    elif kind == "host_send":
                        out.append(self._emit_sequential_host_send_step(name, k=k, indent="  ", deterministic=True))
                    elif kind == "host_recv":
                        out.append(self._emit_sequential_host_recv_step(name, indent="  ", deterministic=True))
                    elif kind == "node_pass":
                        out.append(self._emit_sequential_node_pass_step(name, k=k, indent="  ", deterministic=True))
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
        for v in host_vars:
            out.append(f"{indent2}havoc {host}_{v};\n")
        if not self._max_env_inputs:
            env_lines = self._emit_host_env_inject_statements(host, indent=indent2)
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

    def _emit_sequential_node_pass_step(self, node: str, *, k: int, indent: str, deterministic: bool) -> str:
        dsl_stmt_lines = self._emit_node_pass_statements(node, indent=indent)
        node_assert_lines = self._emit_assert_lines(
            self._spec.nodes.get(node, NodeDecl(name=node)).assert_exprs,
            indent=indent,
            current_node=node,
        )
        global_track_lines = ""
        global_assert_lines = ""
        if self._accumulate_global_assertions():
            for expr in self._spec.global_decl.assert_exprs:
                bpl = self._expr_to_boogie(expr, current_node=node, prefer_reg_dbg=True)
                global_track_lines += f"{indent}if (!({bpl})) {{ procurator_bad := true; }}\n"
        else:
            global_assert_lines = self._emit_assert_lines(
                self._spec.global_decl.assert_exprs,
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
        dbg_needed = bool(node_assert_lines or global_assert_lines or global_track_lines or trace_lines)
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
        if global_track_lines:
            out.append(f"{indent}// Global assertions (accumulated into procurator_bad)\n")
            out.append(global_track_lines)
        if global_assert_lines:
            out.append(f"{indent}// Global assertions\n")
            out.append(global_assert_lines)
        if deterministic:
            out.append(f"{indent}}}\n")
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
