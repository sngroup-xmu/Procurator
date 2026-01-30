from __future__ import annotations

from typing import List

from ..speclang.model import HostDecl, NodeDecl
from .boogie_errors import BoogieBackendError


class BoogieHarnessThreadsMixin:
    """
    Thread-level harness construction for the Boogie backend.

    Responsibilities:
      - EnvThread: external input injection
      - Node threads: node pass execution (single-stage or inferred two-stage)
      - Host threads: explicit host actor modeling
      - Two-stage helper bodies: ingress/egress wrapper bodies and wrapper procs

    Notes:
      - This mixin assumes the main emitter provides a number of helpers and
        shared state (node vars, DSL emitter, POR guards, etc.). It is intentionally
        a thin refactor layer (code moved out of the monolithic `boogie_harness.py`)
        to keep behavior stable while improving maintainability.
    """

    def _emit_env_thread(self, k: int) -> str:
        # Determine which nodes can receive external inputs.
        nodes = [n for n in self._spec.imports.keys() if not self._is_sink_node(n)]
        if not nodes:
            raise BoogieBackendError("EnvThread requires at least one non-sink node")
        marked = [n for n in nodes if self._spec.nodes.get(n, NodeDecl(name=n)).external_input is True]
        inject_targets = marked if marked else nodes  # compatibility fallback

        out: List[str] = []
        out.append("procedure EnvThread() returns()\n")
        env_modifies: set[str] = {f"{n}_inbox_count" for n in inject_targets} | {f"{n}_pkt_external" for n in inject_targets}
        # External injection havocs input vars.
        for n in inject_targets:
            for v in self._node_input_vars.get(n, []):
                env_modifies.add(f"{n}_{v}")
        # Env blocks may update DSL state (global or node-local).
        env_modifies.update(f"dsl_{name}" for name in self._dsl_global_vars.keys())
        for n in inject_targets:
            env_modifies.update(f"{n}_dsl_{name}" for name in self._dsl_node_vars.get(n, {}).keys())
        if self._two_slot_inbox_enabled(k):
            for n in inject_targets:
                for v in self._inbox_on_wire_vars(n):
                    env_modifies.add(self._inbox_slot_var(n, 0, v))
                    env_modifies.add(self._inbox_slot_var(n, 1, v))
        env_modifies.add("procurator_lock")
        if self._max_steps is not None:
            env_modifies.add("procurator_step")
        out.append(
            "  modifies "
            + ", ".join(sorted(env_modifies))
            + ";\n"
        )
        out.append("{\n")
        if self._max_steps is None:
            out.append("  while (true) {\n")
        else:
            out.append(f"  while (procurator_step < {self._max_steps}) {{\n")
        out.append("    // Nondeterministically inject an external packet into one ingress node\n")
        # Important: avoid a stuttering EnvThread iteration that neither injects
        # nor increments procurator_step. Otherwise, even with max_steps, the
        # overall system remains unbounded and TraceAbstraction may diverge.
        if len(inject_targets) == 1:
            n = inject_targets[0]
            out.append("      atomic {\n")
            out.append("        assume procurator_lock == 0;\n")
            if self._max_steps is not None:
                out.append(f"        assume procurator_step < {self._max_steps};\n")
            out.append("        procurator_lock := 1;\n")
            out.append("      }\n")
            out.append(self._emit_external_enqueue_stmt(n, k, indent="      ", deterministic=False))
            out.append("      atomic {\n")
            if self._max_steps is not None:
                out.append("        procurator_step := procurator_step + 1;\n")
            out.append("        procurator_lock := 0;\n")
            out.append("      }\n")
        else:
            for i, n in enumerate(inject_targets):
                if i == 0:
                    out.append("      if (*) {\n")
                elif i == len(inject_targets) - 1:
                    out.append("      } else {\n")
                else:
                    out.append("      } else if (*) {\n")
                out.append("        atomic {\n")
                out.append("          assume procurator_lock == 0;\n")
                if self._max_steps is not None:
                    out.append(f"          assume procurator_step < {self._max_steps};\n")
                out.append("          procurator_lock := 1;\n")
                out.append("        }\n")
                out.append(self._emit_external_enqueue_stmt(n, k, indent="        ", deterministic=False))
                out.append("        atomic {\n")
                if self._max_steps is not None:
                    out.append("          procurator_step := procurator_step + 1;\n")
                out.append("          procurator_lock := 0;\n")
                out.append("        }\n")
            out.append("      }\n")
        out.append("  }\n")
        out.append("}\n")
        return "".join(out)

    def _emit_pipeline_stage_procs(self) -> str:
        if not self._two_stage_nodes:
            return ""
        out: List[str] = []
        out.append("// Two-stage pipeline wrappers (split ingress/egress)\n")
        for node in sorted(self._two_stage_nodes):
            if self._is_sink_node(node):
                continue
            stages = self._node_pipeline_stages.get(node)
            if not stages:
                continue
            mod = ", ".join(sorted(self._node_mainprocedure_modifies.get(node, set())))
            ingress_name = self._ingress_proc_name(node)
            egress_name = self._egress_proc_name(node)
            out.append(f"procedure {ingress_name}() returns()\n")
            if mod:
                out.append(f"  modifies {mod};\n")
            out.append("{\n")
            for line in stages.ingress_lines:
                out.append(f"  {line}\n")
            out.append("}\n\n")
            out.append(f"procedure {egress_name}() returns()\n")
            if mod:
                out.append(f"  modifies {mod};\n")
            out.append("{\n")
            for line in stages.egress_lines:
                out.append(f"  {line}\n")
            out.append("}\n\n")
        return "".join(out)

    def _emit_ingress_stage_body(
        self,
        node: str,
        k: int,
        *,
        indent: str,
        dsl_stmt_lines: str,
        clone_flags: List[str],
    ) -> str:
        out: List[str] = []
        if clone_flags:
            out.append(f"{indent}// Reset clone/recirculate flags for this ingress pass.\n")
            for flag in clone_flags:
                out.append(f"{indent}{node}_{flag} := false;\n")
        if dsl_stmt_lines:
            out.append(f"{indent}// DSL statements (per-pass instrumentation)\n")
            out.append(dsl_stmt_lines)
        out.append(f"{indent}call {self._ingress_proc_name(node)}();\n")
        snap = self._two_stage_snapshot_var_bases(node)
        out.append(f"{indent}// Schedule egress for the original packet.\n")
        out.append(f"{indent}assume {node}_egress_count < {k};\n")
        if snap:
            out.append(f"{indent}// Snapshot per-packet state for deferred egress.\n")
            if self._two_slot_egress_enabled(k):
                out.append(self._emit_egress_store_from_active(node, slot_expr=f"{node}_egress_count", indent=indent))
            else:
                for v in snap:
                    out.append(f"{indent}{self._egress_mailbox_var(node, v)} := {node}_{v};\n")
        out.append(f"{indent}{node}_egress_count := {node}_egress_count + 1;\n")
        if "p4b_clone_i2e" in clone_flags:
            out.append(f"{indent}if ({node}_p4b_clone_i2e) {{\n")
            out.append(f"{indent}  assume {node}_egress_count < {k};\n")
            if snap and self._two_slot_egress_enabled(k):
                out.append(
                    self._emit_egress_store_from_active(node, slot_expr=f"{node}_egress_count", indent=indent + "  ")
                )
            out.append(f"{indent}  {node}_egress_count := {node}_egress_count + 1;\n")
            out.append(f"{indent}}}\n")
        if "p4b_clone_i2i" in clone_flags:
            out.append(f"{indent}if ({node}_p4b_clone_i2i) {{\n")
            out.append(self._emit_internal_enqueue_stmt(node, k, indent=indent + "  "))
            out.append(f"{indent}}}\n")
        for flag in ("p4b_clone_i2e", "p4b_clone_i2i"):
            if flag in clone_flags:
                out.append(f"{indent}{node}_{flag} := false;\n")
        return "".join(out)

    def _emit_egress_stage_body(
        self,
        node: str,
        k: int,
        *,
        indent: str,
        assert_lines: str,
        clone_flags: List[str],
    ) -> str:
        out: List[str] = []
        snap = self._two_stage_snapshot_var_bases(node)
        if snap:
            out.append(f"{indent}// Two-stage: swap in one pending egress packet snapshot.\n")
            for v in snap:
                out.append(f"{indent}{self._ingress_saved_var(node, v)} := {node}_{v};\n")
            if self._two_slot_egress_enabled(k):
                out.append(f"{indent}// Two-slot egress queue: pick a pending snapshot (Bag semantics)\n")
                out.append(f"{indent}if ({node}_egress_count == 1) {{\n")
                out.append(self._emit_egress_load_to_active(node, slot=0, indent=indent + "  "))
                out.append(f"{indent}}} else {{\n")
                out.append(f"{indent}  if (*) {{\n")
                out.append(self._emit_egress_load_to_active(node, slot=0, indent=indent + "    "))
                out.append(self._emit_egress_shift_slot1_to_slot0(node, indent=indent + "    "))
                out.append(f"{indent}  }} else {{\n")
                out.append(self._emit_egress_load_to_active(node, slot=1, indent=indent + "    "))
                out.append(f"{indent}  }}\n")
                out.append(f"{indent}}}\n")
            else:
                for v in snap:
                    out.append(f"{indent}{node}_{v} := {self._egress_mailbox_var(node, v)};\n")
        out.append(f"{indent}{node}_egress_count := {node}_egress_count - 1;\n")

        out.append(f"{indent}call {self._egress_proc_name(node)}();\n")
        if "p4b_clone_e2e" in clone_flags:
            out.append(f"{indent}if ({node}_p4b_clone_e2e) {{\n")
            out.append(f"{indent}  assume {node}_egress_count < {k};\n")
            if snap:
                out.append(f"{indent}  // Snapshot the cloned packet for the next egress pass.\n")
                if self._two_slot_egress_enabled(k):
                    out.append(
                        self._emit_egress_store_from_active(
                            node, slot_expr=f"{node}_egress_count", indent=indent + "  "
                        )
                    )
                else:
                    for v in snap:
                        out.append(f"{indent}  {self._egress_mailbox_var(node, v)} := {node}_{v};\n")
            out.append(f"{indent}  {node}_egress_count := {node}_egress_count + 1;\n")
            out.append(f"{indent}}}\n")
        if "p4b_recirculate" in clone_flags:
            out.append(f"{indent}if ({node}_p4b_recirculate) {{\n")
            out.append(self._emit_internal_enqueue_stmt(node, k, indent=indent + "  "))
            out.append(f"{indent}}}\n")
        out.append(f"{indent}call {node}_Forward();\n")
        trace_lines = self._emit_trace_assignments(node, indent=indent, stage_id=2)
        dbg_needed = bool(assert_lines or trace_lines)
        if dbg_needed:
            dbg = self._emit_register_debug_assignments(indent=indent)
            if dbg:
                out.append(f"{indent}// Register debug snapshot\n")
                out.append(dbg)
        if trace_lines:
            out.append(f"{indent}// Trace snapshot\n")
            out.append(trace_lines)
        if assert_lines:
            out.append(f"{indent}// DSL assertions\n")
            out.append(assert_lines)

        # Restore ingress mailbox state. In the legacy single-slot model, we skip the restore
        # when `p4b_recirculate` is set because self-enqueue "keeps" the packet by overwriting
        # the mailbox. In the two-slot inbox model (k==2), the recirculated packet is stored
        # in a dedicated slot, so restoring is always safe and preserves other pending packets.
        if snap:
            if "p4b_recirculate" in clone_flags and not self._two_slot_inbox_enabled(k):
                out.append(f"{indent}if (!{node}_p4b_recirculate) {{\n")
                for v in snap:
                    out.append(f"{indent}  {node}_{v} := {self._ingress_saved_var(node, v)};\n")
                out.append(f"{indent}}}\n")
            else:
                for v in snap:
                    out.append(f"{indent}{node}_{v} := {self._ingress_saved_var(node, v)};\n")

        if clone_flags:
            out.append(f"{indent}// Clear clone/recirculate flags after egress.\n")
            for flag in clone_flags:
                out.append(f"{indent}{node}_{flag} := false;\n")
        return "".join(out)

    def _emit_node_thread(self, node: str, k: int) -> str:
        input_vars = self._node_input_vars.get(node, [])

        assert_lines = "".join(
            [
                self._emit_assert_lines(
                    self._spec.nodes.get(node, NodeDecl(name=node)).assert_exprs,
                    indent="      ",
                    current_node=node,
                ),
                self._emit_assert_lines(
                    self._spec.global_decl.assert_exprs,
                    indent="      ",
                    current_node=node,
                ),
            ]
        )

        dsl_stmt_lines = self._emit_node_pass_statements(node, indent="      ")

        modifies_set = set()
        modifies_set.add("procurator_lock")
        if self._max_steps is not None:
            modifies_set.add("procurator_step")
        modifies_set.add(f"{node}_inbox_count")
        modifies_set.add(f"{node}_pkt_external")
        modifies_set.update(self._node_mainprocedure_modifies.get(node, set()))
        # Havoc writes to these globals, so they must be listed in modifies.
        modifies_set.update(f"{node}_{v}" for v in input_vars)
        if self._two_slot_inbox_enabled(k):
            for v in self._inbox_on_wire_vars(node):
                modifies_set.add(self._inbox_slot_var(node, 0, v))
                modifies_set.add(self._inbox_slot_var(node, 1, v))
        # DSL locals are modeled as globals and may be modified by node statements.
        modifies_set.update(f"{node}_dsl_{name}" for name in self._dsl_node_vars.get(node, {}).keys())
        modifies_set.update(f"dsl_{name}" for name in self._dsl_global_vars.keys())
        modifies_set.update(self._collect_dsl_modified_boogie_vars(node))
        for regs in self._node_register_arrays.values():
            for name, (_idx_type, elem_type) in regs.items():
                if elem_type == "Ref" or elem_type.endswith("Ref"):
                    continue
                modifies_set.add(self._register_debug_var_name(name))
                modifies_set.add(self._register_last_index_dbg_name(name))
                modifies_set.add(self._register_last_value_dbg_name(name))
                modifies_set.add(self._register_wrote_any_dbg_name(name))
                modifies_set.add(self._register_wrote_index0_dbg_name(name))
                modifies_set.add(self._register_last0_value_dbg_name(name))
        declared = self._node_declared_vars.get(node, set())
        clone_flags = []
        for flag in ("p4b_clone_i2e", "p4b_clone_e2e", "p4b_clone_i2i", "p4b_recirculate"):
            if flag in declared:
                clone_flags.append(flag)
                modifies_set.add(f"{node}_{flag}")
        two_stage = self._is_two_stage_node(node)
        if two_stage:
            modifies_set.add(f"{node}_egress_count")
            for v in self._two_stage_snapshot_var_bases(node):
                # Two-stage pipeline: egress step swaps/restores the active packet globals.
                modifies_set.add(f"{node}_{v}")
                if self._two_slot_egress_enabled(k):
                    modifies_set.add(self._egress_slot_var(node, 0, v))
                    modifies_set.add(self._egress_slot_var(node, 1, v))
                else:
                    modifies_set.add(self._egress_mailbox_var(node, v))
                modifies_set.add(self._ingress_saved_var(node, v))
        for l in self._spec.links:
            if l.src == node:
                if not self._is_sink_node(l.dst):
                    modifies_set.add(f"{l.dst}_inbox_count")
                    modifies_set.add(f"{l.dst}_pkt_external")
                else:
                    # Sink/observer nodes execute DSL instrumentation at enqueue-time, so the
                    # sender thread must account for those side effects as well.
                    modifies_set.update(self._collect_dsl_modified_boogie_vars(l.dst))
                # enqueue copies packet fields
                dst_decl = self._get_declared_vars(l.dst)
                for v in self._node_input_vars.get(node, []):
                    if v in self._node_declared_vars.get(node, set()) and v in dst_decl:
                        modifies_set.add(f"{l.dst}_{v}")
                if not self._is_sink_node(l.dst) and self._two_slot_inbox_enabled(k) and l.dst in self._spec.imports:
                    for v in self._inbox_on_wire_vars(l.dst):
                        modifies_set.add(self._inbox_slot_var(l.dst, 0, v))
                        modifies_set.add(self._inbox_slot_var(l.dst, 1, v))

        out: List[str] = []
        out.append(f"procedure {node}Thread() returns()\n")
        out.append("  modifies " + ", ".join(sorted(modifies_set)) + ";\n")
        out.append("{\n")
        if self._max_steps is None:
            out.append("  while (true) {\n")
        else:
            out.append(f"  while (procurator_step < {self._max_steps}) {{\n")
        if not two_stage:
            out.append("      atomic {\n")
            out.append("        assume procurator_lock == 0;\n")
            if self._max_steps is not None:
                out.append(f"        assume procurator_step < {self._max_steps};\n")
            out.append(f"        assume {node}_inbox_count > 0;\n")
            if self._por_enabled and self._por_guard_enabled:
                guards = self._por_guards.get(node, [])
                if guards:
                    out.append("        // POR: prefer lower-id commuting nodes when they are ready.\n")
                    for other in guards:
                        out.append(f"        assume {other}_inbox_count == 0;\n")
            out.append("        procurator_lock := 1;\n")
            out.append("      }\n")
            if self._two_slot_inbox_enabled(k):
                out.append("      // Two-slot inbox: pick a pending packet (Bag semantics)\n")
                out.append(f"      if ({node}_inbox_count == 1) {{\n")
                out.append(self._emit_inbox_load_to_active(node, slot=0, indent="        "))
                out.append("      } else {\n")
                out.append("        if (*) {\n")
                out.append(self._emit_inbox_load_to_active(node, slot=0, indent="          "))
                out.append(self._emit_inbox_shift_slot1_to_slot0(node, indent="          "))
                out.append("        } else {\n")
                out.append(self._emit_inbox_load_to_active(node, slot=1, indent="          "))
                out.append("        }\n")
                out.append("      }\n")
            out.append(f"      {node}_inbox_count := {node}_inbox_count - 1;\n")
            if dsl_stmt_lines:
                out.append("      // DSL statements (per-pass instrumentation)\n")
                out.append(dsl_stmt_lines)
            out.append(f"      call {node}_mainProcedure();\n")
            if clone_flags:
                out.append("      // Handle clone/recirculate flags emitted by P4B extern modeling.\n")
                if "p4b_clone_i2e" in clone_flags:
                    out.append(f"      if ({node}_p4b_clone_i2e) {{\n")
                    out.append(f"        call {node}_Forward();\n")
                    out.append("      }\n")
                if "p4b_clone_e2e" in clone_flags:
                    out.append(f"      if ({node}_p4b_clone_e2e) {{\n")
                    out.append(f"        call {node}_Forward();\n")
                    out.append("      }\n")
                if "p4b_clone_i2i" in clone_flags:
                    out.append(f"      if ({node}_p4b_clone_i2i) {{\n")
                    out.append(self._emit_internal_enqueue_stmt(node, k, indent="        "))
                    out.append("      }\n")
                if "p4b_recirculate" in clone_flags:
                    out.append(f"      if ({node}_p4b_recirculate) {{\n")
                    out.append(self._emit_internal_enqueue_stmt(node, k, indent="        "))
                    out.append("      }\n")
                for flag in clone_flags:
                    out.append(f"      {node}_{flag} := false;\n")
            out.append(f"      call {node}_Forward();\n")
            if assert_lines:
                dbg = self._emit_register_debug_assignments(indent="      ")
                if dbg:
                    out.append("      // Register debug snapshot\n")
                    out.append(dbg)
                out.append("      // DSL assertions\n")
                out.append(assert_lines)
            out.append("      atomic {\n")
            if self._max_steps is not None:
                out.append("        procurator_step := procurator_step + 1;\n")
            out.append("        procurator_lock := 0;\n")
            out.append("      }\n")
        else:
            # Ingress stage
            # Avoid stutter steps: the fork/interleaving semantics already model
            # nondeterministic scheduling. Explicit `if (*) { ... }` wrappers
            # introduce always-enabled self-loops that keep the system unbounded
            # even under max_steps.
            out.append("    if (*) {\n")
            out.append("      atomic {\n")
            out.append("        assume procurator_lock == 0;\n")
            if self._max_steps is not None:
                out.append(f"        assume procurator_step < {self._max_steps};\n")
            out.append(f"        assume {node}_inbox_count > 0;\n")
            if self._por_enabled and self._por_guard_enabled:
                guards = self._por_guards.get(node, [])
                if guards:
                    out.append("        // POR: prefer lower-id commuting nodes when they are ready.\n")
                    for other in guards:
                        out.append(f"        assume {other}_inbox_count == 0;\n")
            out.append("        procurator_lock := 1;\n")
            out.append("      }\n")
            if self._two_slot_inbox_enabled(k):
                out.append("      // Two-slot inbox: pick a pending packet (Bag semantics)\n")
                out.append(f"      if ({node}_inbox_count == 1) {{\n")
                out.append(self._emit_inbox_load_to_active(node, slot=0, indent="        "))
                out.append("      } else {\n")
                out.append("        if (*) {\n")
                out.append(self._emit_inbox_load_to_active(node, slot=0, indent="          "))
                out.append(self._emit_inbox_shift_slot1_to_slot0(node, indent="          "))
                out.append("        } else {\n")
                out.append(self._emit_inbox_load_to_active(node, slot=1, indent="          "))
                out.append("        }\n")
                out.append("      }\n")
            out.append(f"      {node}_inbox_count := {node}_inbox_count - 1;\n")
            out.append(
                self._emit_ingress_stage_body(
                    node,
                    k,
                    indent="      ",
                    dsl_stmt_lines=dsl_stmt_lines,
                    clone_flags=clone_flags,
                )
            )
            out.append("      atomic {\n")
            if self._max_steps is not None:
                out.append("        procurator_step := procurator_step + 1;\n")
            out.append("        procurator_lock := 0;\n")
            out.append("      }\n")
            out.append("    } else {\n")
            # Egress stage
            out.append("      atomic {\n")
            out.append("        assume procurator_lock == 0;\n")
            if self._max_steps is not None:
                out.append(f"        assume procurator_step < {self._max_steps};\n")
            out.append(f"        assume {node}_egress_count > 0;\n")
            out.append("        procurator_lock := 1;\n")
            out.append("      }\n")
            out.append(
                self._emit_egress_stage_body(
                    node,
                    k,
                    indent="      ",
                    assert_lines=assert_lines,
                    clone_flags=clone_flags,
                )
            )
            out.append("      atomic {\n")
            if self._max_steps is not None:
                out.append("        procurator_step := procurator_step + 1;\n")
            out.append("        procurator_lock := 0;\n")
            out.append("      }\n")
            out.append("    }\n")
        out.append("  }\n")
        out.append("}\n")
        return "".join(out)

    def _emit_host_thread(self, host: str, k: int) -> str:
        target = self._host_to_node.get(host)
        if not target:
            return f"procedure {host}Thread() returns()\n{{\n  while (true) {{ }}\n}}\n"

        host_eager = self._spec.global_decl.host_eager is True
        host_vars = self._host_input_vars.get(host, [])
        host_decl = self._host_declared_vars.get(host, set())
        target_decl = self._node_declared_vars.get(target, set())
        copy_vars: List[str] = []
        for v in host_vars:
            if v in host_decl and v in target_decl:
                copy_vars.append(v)

        modifies_set: set[str] = {
            f"{host}_inbox_count",
            f"{host}_pkt_external",
            f"{target}_inbox_count",
            f"{target}_pkt_external",
        }
        modifies_set.update(f"{host}_{v}" for v in host_vars)
        modifies_set.update(f"{target}_{v}" for v in copy_vars)
        if self._two_slot_inbox_enabled(k) and target in self._spec.imports:
            for v in self._inbox_on_wire_vars(target):
                modifies_set.add(self._inbox_slot_var(target, 0, v))
                modifies_set.add(self._inbox_slot_var(target, 1, v))
        modifies_set.update(f"{host}_dsl_{name}" for name in self._dsl_host_vars.get(host, {}).keys())
        modifies_set.update(f"dsl_{name}" for name in self._dsl_global_vars.keys())

        out: List[str] = []
        out.append(f"procedure {host}Thread() returns()\n")
        out.append("  modifies " + ", ".join(sorted(modifies_set)) + ";\n")
        out.append("{\n")
        out.append("  while (true) {\n")
        out.append(f"    if ({'true' if host_eager else '*'}) {{\n")
        out.append(f"      if ({target}_inbox_count < {k}) {{\n")
        # Create a fresh packet for this host send.
        for v in host_vars:
            out.append(f"        havoc {host}_{v};\n")
        if not self._max_env_inputs:
            env_lines = self._emit_host_env_inject_statements(host, indent="        ")
            if env_lines:
                out.append(env_lines)
            hd = self._spec.hosts.get(host, HostDecl(name=host))
            for expr in hd.assume_exprs:
                out.append(f"        assume {self._expr_to_boogie(expr, current_node=host)};\n")
            for expr in self._spec.global_decl.assume_exprs:
                out.append(f"        assume {self._expr_to_boogie(expr, current_node=host)};\n")
        for v in copy_vars:
            out.append(f"        {target}_{v} := {host}_{v};\n")
        out.append(f"        {target}_pkt_external := true;\n")
        if self._two_slot_inbox_enabled(k) and target in self._spec.imports:
            out.append(self._emit_inbox_store_from_active(target, slot_expr=f"{target}_inbox_count", indent="        "))
        out.append(f"        {target}_inbox_count := {target}_inbox_count + 1;\n")
        out.append("      }\n")
        out.append("    }\n")

        # Receive path (host as sink).
        out.append("    if (*) {\n")
        out.append(f"      if ({host}_inbox_count > 0) {{\n")
        hd = self._spec.hosts.get(host, HostDecl(name=host))
        out.append(
            self._emit_assert_lines(hd.assert_exprs, indent="        ", current_node=host)
        )
        out.append(f"        {host}_inbox_count := {host}_inbox_count - 1;\n")
        out.append("      }\n")
        out.append("    }\n")

        out.append("  }\n")
        out.append("}\n")
        return "".join(out)

