from __future__ import annotations

from typing import Dict, List, Optional, Sequence

from .boogie_errors import BoogieBackendError


class BoogieHarnessStartMixin:
    def _emit_ultimate_start(
        self, node_aliases: List[str], host_aliases: List[str], *, env_thread_enabled: bool
    ) -> str:
        out: List[str] = []
        out.append("procedure ULTIMATE.start() returns()\n")
        # In Ultimate's Boogie, modifies must account for:
        #  - direct assignments in this procedure (e.g., inbox initialization), and
        #  - variables that may be modified by forked procedures (fork behaves like a call wrt modifies checks).
        start_modifies: set[str] = set()
        start_modifies.add("procurator_lock")
        if self._max_steps is not None:
            start_modifies.add("procurator_step")
        start_modifies.update(f"{a}_inbox_count" for a in node_aliases + host_aliases)
        start_modifies.update(f"{a}_pkt_external" for a in node_aliases + host_aliases)
        k = self._spec.global_decl.queue_capacity if self._spec.global_decl.queue_capacity is not None else 5
        if self._two_slot_inbox_enabled(k):
            for a in node_aliases:
                for v in self._inbox_on_wire_vars(a):
                    start_modifies.add(self._inbox_slot_var(a, 0, v))
                    start_modifies.add(self._inbox_slot_var(a, 1, v))
        for a in node_aliases:
            if self._is_two_stage_node(a):
                start_modifies.add(f"{a}_egress_count")
                for v in self._two_stage_snapshot_var_bases(a):
                    start_modifies.add(f"{a}_{v}")
                    if self._two_slot_egress_enabled(k):
                        start_modifies.add(self._egress_slot_var(a, 0, v))
                        start_modifies.add(self._egress_slot_var(a, 1, v))
                    else:
                        start_modifies.add(self._egress_mailbox_var(a, v))
                    start_modifies.add(self._ingress_saved_var(a, v))
        # DSL locals are globals and may be initialized here.
        start_modifies.update(f"dsl_{name}" for name in self._dsl_global_vars.keys())
        for a in self._spec.imports.keys():
            start_modifies.update(f"{a}_dsl_{name}" for name in self._dsl_node_vars.get(a, {}).keys())
        for h in host_aliases:
            start_modifies.update(f"{h}_dsl_{name}" for name in self._dsl_host_vars.get(h, {}).keys())
        for a in node_aliases:
            regs = self._node_register_arrays.get(a, {})
            for name in regs.keys():
                start_modifies.add(self._register_debug_var_name(name))
                start_modifies.add(self._register_last_index_dbg_name(name))
                start_modifies.add(self._register_last_value_dbg_name(name))
                start_modifies.add(self._register_wrote_any_dbg_name(name))
                start_modifies.add(self._register_wrote_index0_dbg_name(name))
                start_modifies.add(self._register_last0_value_dbg_name(name))
                start_modifies.add(self._register_last_index_name(name))
                start_modifies.add(self._register_last_value_name(name))
                start_modifies.add(self._register_wrote_any_name(name))
                start_modifies.add(self._register_wrote_index0_name(name))
                start_modifies.add(self._register_last0_value_name(name))
        for a in node_aliases:
            start_modifies.update(self._node_mainprocedure_modifies.get(a, set()))
            start_modifies.update(f"{a}_{v}" for v in self._node_input_vars.get(a, []))
            # Per-pass DSL statements may modify additional globals (including cross-node
            # instrumentation). Since fork behaves like a call wrt modifies checks, ULTIMATE.start
            # must include them as well.
            start_modifies.update(self._collect_dsl_modified_boogie_vars(a))
        for h in host_aliases:
            start_modifies.update(f"{h}_{v}" for v in self._host_input_vars.get(h, []))
        for l in self._spec.links:
            if not self._is_sink_node(l.dst):
                # forwarding updates inbox counters
                start_modifies.add(f"{l.dst}_inbox_count")
                start_modifies.add(f"{l.dst}_pkt_external")
            else:
                # Sink/observer nodes execute DSL instrumentation at enqueue-time.
                start_modifies.update(self._collect_dsl_modified_boogie_vars(l.dst))
            # enqueue copies packet fields
            dst_decl = self._get_declared_vars(l.dst)
            for v in self._node_input_vars.get(l.src, []):
                if v in self._node_declared_vars.get(l.src, set()) and v in dst_decl:
                    start_modifies.add(f"{l.dst}_{v}")
        out.append("  modifies " + ", ".join(sorted(start_modifies)) + ";\n")
        out.append("{\n")
        out.append("  procurator_lock := 0;\n")
        if self._max_steps is not None:
            out.append("  procurator_step := 0;\n")
        out.append("  // initialize inboxes\n")
        for a in node_aliases + host_aliases:
            out.append(f"  {a}_inbox_count := 0;\n")
            out.append(f"  {a}_pkt_external := false;\n")
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
        out.append("  // spawn threads\n")
        # GemCutter's Boogie concurrency syntax requires an explicit thread id:
        #   fork <int> <procedure_call>;
        thread_id = 0
        if env_thread_enabled:
            out.append("  fork 0 EnvThread();\n")
            thread_id = 1
        for a in node_aliases:
            out.append(f"  fork {thread_id} {a}Thread();\n")
            thread_id += 1
        for h in host_aliases:
            out.append(f"  fork {thread_id} {h}Thread();\n")
            thread_id += 1
        out.append("}\n")
        return "".join(out)

    def _compute_harness_modifies(
        self,
        node_aliases: List[str],
        host_aliases: List[str],
        *,
        include_lock: bool,
    ) -> set[str]:
        mods: set[str] = set()
        if include_lock:
            mods.add("procurator_lock")
        mods.update(f"{a}_inbox_count" for a in node_aliases + host_aliases)
        mods.update(f"{a}_pkt_external" for a in node_aliases + host_aliases)
        k = self._spec.global_decl.queue_capacity if self._spec.global_decl.queue_capacity is not None else 5
        if self._two_slot_inbox_enabled(k):
            for a in node_aliases:
                for v in self._inbox_on_wire_vars(a):
                    mods.add(self._inbox_slot_var(a, 0, v))
                    mods.add(self._inbox_slot_var(a, 1, v))
        for a in node_aliases:
            if self._is_two_stage_node(a):
                mods.add(f"{a}_egress_count")
                for v in self._two_stage_snapshot_var_bases(a):
                    mods.add(f"{a}_{v}")
                    if self._two_slot_egress_enabled(k):
                        mods.add(self._egress_slot_var(a, 0, v))
                        mods.add(self._egress_slot_var(a, 1, v))
                    else:
                        mods.add(self._egress_mailbox_var(a, v))
                    mods.add(self._ingress_saved_var(a, v))

        mods.update(f"dsl_{name}" for name in self._dsl_global_vars.keys())
        for a in self._spec.imports.keys():
            mods.update(f"{a}_dsl_{name}" for name in self._dsl_node_vars.get(a, {}).keys())
        for h in host_aliases:
            mods.update(f"{h}_dsl_{name}" for name in self._dsl_host_vars.get(h, {}).keys())
        for a in node_aliases:
            regs = self._node_register_arrays.get(a, {})
            for name in regs.keys():
                mods.add(self._register_debug_var_name(name))
                mods.add(self._register_last_index_dbg_name(name))
                mods.add(self._register_last_value_dbg_name(name))
                mods.add(self._register_wrote_any_dbg_name(name))
                mods.add(self._register_wrote_index0_dbg_name(name))
                mods.add(self._register_last0_value_dbg_name(name))
                mods.add(self._register_last_index_name(name))
                mods.add(self._register_last_value_name(name))
                mods.add(self._register_wrote_any_name(name))
                mods.add(self._register_wrote_index0_name(name))
                mods.add(self._register_last0_value_name(name))

        if self._emit_trace and node_aliases:
            mods.add("trace_node_id")
            mods.add("trace_stage")
            for node in node_aliases:
                mods.add(self._trace_node_exec_name(node))
                types = self._trace_field_types(node)
                if "seq" in types:
                    mods.add(self._trace_node_seq_name(node))
                if "op" in types:
                    mods.add(self._trace_node_op_name(node))
                if "key" in types:
                    mods.add(self._trace_node_key_name(node))
            for regs in self._node_register_arrays.values():
                for name in regs.keys():
                    mods.add(self._trace_reg_dbg0_name(name))
                    mods.add(self._trace_reg_wrote_any_name(name))
                    mods.add(self._trace_reg_wrote_index0_name(name))
                    mods.add(self._trace_reg_last0_value_name(name))
            for link in self._spec.links:
                mods.add(self._trace_enqueue_exec_name(link.src, link.dst))
                types = self._trace_field_types(link.src)
                if "seq" in types:
                    mods.add(self._trace_enqueue_seq_name(link.src, link.dst))
                if "op" in types:
                    mods.add(self._trace_enqueue_op_name(link.src, link.dst))
                if "key" in types:
                    mods.add(self._trace_enqueue_key_name(link.src, link.dst))

        for a in node_aliases:
            mods.update(self._node_mainprocedure_modifies.get(a, set()))
            mods.update(f"{a}_{v}" for v in self._node_input_vars.get(a, []))
        for h in host_aliases:
            mods.update(f"{h}_{v}" for v in self._host_input_vars.get(h, []))

        for l in self._spec.links:
            if not self._is_sink_node(l.dst):
                mods.add(f"{l.dst}_inbox_count")
                mods.add(f"{l.dst}_pkt_external")
            else:
                mods.update(self._collect_dsl_modified_boogie_vars(l.dst))
            dst_decl = self._get_declared_vars(l.dst)
            for v in self._node_input_vars.get(l.src, []):
                if v in self._node_declared_vars.get(l.src, set()) and v in dst_decl:
                    mods.add(f"{l.dst}_{v}")

        return mods

    def _emit_register_init_assumes(self, node_aliases: List[str]) -> str:
        out: List[str] = []
        for node in node_aliases:
            regs = self._node_register_arrays.get(node, {})
            for name, (idx_type, elem_type) in sorted(regs.items()):
                raw = name[len(node) + 1 :] if name.startswith(f"{node}_") else name
                init_map = self._meta_register_inits.get(node, {}).get(raw, {})

                default_lit = self._render_value_zero(elem_type)
                if isinstance(init_map, dict) and "*" in init_map:
                    lit = self._render_typed_literal_from_str(elem_type, init_map.get("*", ""))
                    if lit is not None:
                        default_lit = lit

                cell_inits: Dict[int, str] = {}
                if isinstance(init_map, dict):
                    for k, v in init_map.items():
                        if str(k) == "*":
                            continue
                        try:
                            idx_int = int(str(k))
                        except Exception:
                            continue
                        lit = self._render_typed_literal_from_str(elem_type, str(v))
                        if lit is None:
                            continue
                        cell_inits[idx_int] = lit

                if cell_inits:
                    idx_lits = [self._render_typed_int(idx_type, i) for i in sorted(cell_inits.keys())]
                    guard = " && ".join(f"(i != {lit})" for lit in idx_lits)
                    out.append(f"  assume (forall i:{idx_type} :: ({guard}) ==> {name}[i] == {default_lit});\n")
                else:
                    out.append(f"  assume (forall i:{idx_type} :: {name}[i] == {default_lit});\n")

                idx_zero = self._render_index_zero(idx_type)
                out.append(f"  assume {name}[{idx_zero}] == {cell_inits.get(0, default_lit)};\n")

                for idx, val in sorted(cell_inits.items()):
                    out.append(f"  assume {name}[{self._render_typed_int(idx_type, idx)}] == {val};\n")
        return "".join(out)
