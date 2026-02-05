from __future__ import annotations

from typing import Dict, List, Optional

from lark import Tree

from ..speclang.model import NodeDecl
from .boogie_common import dsl_is_simple_local_name, is_on_wire_packet_var, is_packet_var
from .boogie_dsl import collect_dotted_vars
from .boogie_errors import BoogieBackendError

_dsl_is_simple_local_name = dsl_is_simple_local_name
_collect_dotted_vars = collect_dotted_vars
_is_on_wire_packet_var = is_on_wire_packet_var
_is_packet_var = is_packet_var


class BoogieHarnessLinksMixin:
    def _emit_forward_proc(self, src: str, k: int) -> str:
        port_map: Dict[str, str] = {}
        wildcard_dsts: List[str] = []
        for l in self._spec.links:
            if l.src != src:
                continue
            if l.port == "ALL":
                wildcard_dsts.append(l.dst)
            else:
                if l.port in port_map and port_map[l.port] != l.dst:
                    raise BoogieBackendError(
                        f"Duplicate port mapping for {src} port {l.port}: {port_map[l.port]} vs {l.dst}"
                    )
                port_map[l.port] = l.dst

        base_egress = self._node_egress_port_var.get(src, "standard_metadata.egress_port")
        egress_var = base_egress if base_egress.startswith(f"{src}_") else f"{src}_{base_egress}"
        egress_type = self._node_egress_port_type.get(src, "")
        alias = self._node_type_defs.get(src, {}).get(egress_type)
        if isinstance(alias, str):
            egress_type = alias
        zero = self._boogie_port_const("0", egress_type)

        # Forward calls enqueue procedures, so its modifies must cover enqueue side effects as well
        # (Ultimate checks modifies-transitivity for calls/fork).
        dsts = sorted(set(port_map.values()) | set(wildcard_dsts))
        modifies: List[str] = []
        emit_trace = self._emit_trace and self._harness_mode == "sequential"
        trace_types = self._trace_field_types(src) if emit_trace else {}
        for dst in dsts:
            if not self._is_sink_node(dst):
                modifies.append(f"{dst}_inbox_count")
                modifies.append(f"{dst}_pkt_external")
            else:
                # Sink/observer nodes execute DSL instrumentation at enqueue-time.
                modifies.extend(self._collect_dsl_modified_boogie_vars(dst))
            # Enqueue preserves on-wire packet fields (headers only).
            src_decl = self._node_declared_vars.get(src, set())
            dst_decl = self._get_declared_vars(dst)
            for v in self._node_input_vars.get(src, []):
                if _is_on_wire_packet_var(v) and v in src_decl and v in dst_decl:
                    modifies.append(f"{dst}_{v}")
            if not self._is_sink_node(dst) and self._two_slot_inbox_enabled(k) and dst in self._spec.imports:
                for v in self._inbox_on_wire_vars(dst):
                    modifies.append(self._inbox_slot_var(dst, 0, v))
                    modifies.append(self._inbox_slot_var(dst, 1, v))
            if emit_trace:
                modifies.append(self._trace_enqueue_exec_name(src, dst))
                if "seq" in trace_types:
                    modifies.append(self._trace_enqueue_seq_name(src, dst))
                if "op" in trace_types:
                    modifies.append(self._trace_enqueue_op_name(src, dst))
                if "key" in trace_types:
                    modifies.append(self._trace_enqueue_key_name(src, dst))
        if self._tofino_recirculate_ports:
            modifies.append(f"{src}_inbox_count")
            modifies.append(f"{src}_pkt_external")
        mod_clause = ""
        if modifies:
            mod_clause = "  modifies " + ", ".join(sorted(set(modifies))) + ";\n"

        out: List[str] = []
        # Avoid collisions with P4->Boogie outputs (e.g., P4 programs often have a `forward` variable).
        out.append(f"procedure {src}_Forward() returns()\n")
        out.append(mod_clause)
        out.append("{\n")
        out.append(f"  // If no forwarding decision was made, do nothing.\n")
        out.append(f"  if ({egress_var} == {zero}) {{\n")
        out.append("    return;\n")
        out.append("  }\n\n")
        if self._tofino_recirculate_ports:
            out.append("  // Tofino recirculate: magic egress ports map to self-enqueue.\n")
            for port in self._tofino_recirculate_ports:
                pconst = self._boogie_port_const(str(port), egress_type)
                out.append(f"  if ({egress_var} == {pconst}) {{\n")
                out.append(f"    assume {src}_inbox_count < {k};\n")
                out.append(f"    {src}_pkt_external := false;\n")
                out.append(f"    {src}_inbox_count := {src}_inbox_count + 1;\n")
                out.append("    return;\n")
                out.append("  }\n")
            out.append("\n")

        if wildcard_dsts:
            out.append(f"  // wildcard forwarding (ALL): broadcast to all configured downstream mailboxes.\n")
            for dst in sorted(set(wildcard_dsts)):
                out.append(f"  call {src}__enqueue_{dst}();\n")
            out.append("  return;\n")
            out.append("}\n")
            return "".join(out)

        out.append("  // port-specific forwarding\n")
        for port, dst in sorted(port_map.items(), key=lambda kv: kv[0]):
            pconst = self._boogie_port_const(port, egress_type)
            out.append(f"  if ({egress_var} == {pconst}) {{\n")
            out.append(f"    call {src}__enqueue_{dst}();\n")
            out.append("    return;\n")
            out.append("  }\n")
        out.append("  // unknown port -> drop\n")
        out.append("  return;\n")
        out.append("}\n")
        return "".join(out)

    def _emit_enqueue_proc(self, src: str, dst: str, k: int) -> str:
        # Copy packet fields from src to dst (single-slot mailbox).
        # We only copy on-wire packet vars (best-effort intersection on declared vars).
        src_decl = self._node_declared_vars.get(src, set())
        dst_decl = self._get_declared_vars(dst)
        copy_vars: List[str] = []
        for v in self._node_input_vars.get(src, []):
            if _is_on_wire_packet_var(v) and v in src_decl and v in dst_decl:
                copy_vars.append(v)

        dst_is_sink = self._is_sink_node(dst)
        out: List[str] = []
        out.append(f"procedure {src}__enqueue_{dst}() returns()\n")
        mod: List[str] = []
        if not dst_is_sink:
            mod.extend([f"{dst}_inbox_count", f"{dst}_pkt_external"])
        mod.extend(f"{dst}_{v}" for v in copy_vars)
        if dst_is_sink:
            mod.extend(self._collect_dsl_modified_boogie_vars(dst))
        if not dst_is_sink and self._two_slot_inbox_enabled(k) and dst in self._spec.imports:
            for v in self._inbox_on_wire_vars(dst):
                mod.append(self._inbox_slot_var(dst, 0, v))
                mod.append(self._inbox_slot_var(dst, 1, v))
        emit_trace = self._emit_trace and self._harness_mode == "sequential"
        trace_types = self._trace_field_types(src) if emit_trace else {}
        if emit_trace:
            mod.append(self._trace_enqueue_exec_name(src, dst))
            if "seq" in trace_types:
                mod.append(self._trace_enqueue_seq_name(src, dst))
            if "op" in trace_types:
                mod.append(self._trace_enqueue_op_name(src, dst))
            if "key" in trace_types:
                mod.append(self._trace_enqueue_key_name(src, dst))
        out.append("  modifies " + ", ".join(sorted(set(mod))) + ";\n")
        out.append("{\n")
        if not dst_is_sink:
            out.append(f"  assume {dst}_inbox_count < {k};\n")
        # Store the packet fields (single slot)
        for v in copy_vars:
            out.append(f"  {dst}_{v} := {src}_{v};\n")
        if dst_is_sink:
            dsl_stmt_lines = self._emit_node_pass_statements(dst, indent="  ")
            if dsl_stmt_lines:
                out.append("  // Sink/observer node: execute DSL instrumentation at enqueue-time\n")
                out.append(dsl_stmt_lines)
            assert_lines = self._emit_assert_lines(
                self._spec.nodes.get(dst, NodeDecl(name=dst)).assert_exprs,
                indent="  ",
                current_node=dst,
            )
            if assert_lines:
                out.append("  // Sink/observer node: local DSL assertions\n")
                out.append(assert_lines)
        else:
            out.append(f"  {dst}_pkt_external := false;\n")
            if self._two_slot_inbox_enabled(k) and dst in self._spec.imports:
                out.append(self._emit_inbox_store_from_active(dst, slot_expr=f"{dst}_inbox_count", indent="  "))
            out.append(f"  {dst}_inbox_count := {dst}_inbox_count + 1;\n")
        if emit_trace:
            out.append(f"  {self._trace_enqueue_exec_name(src, dst)}[procurator_step] := true;\n")
            if "seq" in trace_types:
                out.append(f"  {self._trace_enqueue_seq_name(src, dst)}[procurator_step] := {src}_hdr.nc_hdr.seq;\n")
            if "op" in trace_types:
                out.append(f"  {self._trace_enqueue_op_name(src, dst)}[procurator_step] := {src}_hdr.nc_hdr.op;\n")
            if "key" in trace_types:
                out.append(f"  {self._trace_enqueue_key_name(src, dst)}[procurator_step] := {src}_hdr.nc_hdr.key;\n")
        out.append("}\n")
        return "".join(out)

    def _get_declared_vars(self, name: str) -> set[str]:
        if name in self._host_declared_vars:
            return self._host_declared_vars.get(name, set())
        return self._node_declared_vars.get(name, set())

    def _is_two_stage_node(self, node: str) -> bool:
        # Sink/observer nodes are never scheduled to run P4, so the two-stage encoding
        # (ingress/egress split) is meaningless for them and should be disabled.
        return node in self._two_stage_nodes and not self._is_sink_node(node)

    def _is_sink_node(self, node: str) -> bool:
        nd = self._spec.nodes.get(node)
        return bool(nd is not None and nd.sink is True)

    def _ingress_proc_name(self, node: str) -> str:
        return f"{node}__procurator_ingress"

    def _egress_proc_name(self, node: str) -> str:
        return f"{node}__procurator_egress"

    def _prefix_node_type(self, node: str, typ: str) -> str:
        """
        P4B emits node-local type aliases (e.g., `error`, `egressSpec_t`).
        After prefixing, these become `<node>_<type>`. Harness-declared variables
        must use the prefixed name.
        """
        t = typ.strip()
        if not t:
            return t
        if t in {"int", "bool"}:
            return t
        if t.startswith("bv") and t[2:].isdigit():
            return t
        if t.startswith(f"{node}_"):
            return t
        return f"{node}_{t}"

    def _is_snapshot_scalar(self, node: str, base: str) -> bool:
        """
        Snapshot only scalar, non-Ref variables into the two-stage egress mailbox.

        We intentionally skip:
          - references (`Ref`) and reference-like types
          - map/array types like `[bv32]bv16` (stateful/register arrays)
        """
        vt = self._node_var_types.get(node, {}).get(base)
        if not isinstance(vt, str) or not vt.strip():
            return False
        t = vt.strip()
        if t == "Ref" or t.endswith("Ref"):
            return False
        if t.startswith("["):
            return False
        return True

    def _egress_mailbox_var(self, node: str, base: str) -> str:
        return f"{node}__eg_{base}"

    def _ingress_saved_var(self, node: str, base: str) -> str:
        return f"{node}__ig_saved_{base}"

    def _two_stage_snapshot_var_bases(self, node: str) -> List[str]:
        """
        Vars to preserve across ingress->egress for two-stage pipeline nodes.

        Rationale: when ingress and egress are scheduled as separate steps, other
        injections/passes may overwrite per-packet Boogie globals. Without an
        explicit snapshot, egress (and DSL asserts placed after egress) can observe
        a mix of states from different packets, yielding false counterexamples.
        """
        if not self._is_two_stage_node(node):
            return []
        cached = self._two_stage_snapshot_vars.get(node)
        if cached is not None:
            return cached

        declared = self._node_declared_vars.get(node, set())
        snapshot: set[str] = set()

        # Always keep scalar packet/meta vars; these are the main source of mixing.
        for v in declared:
            if _is_packet_var(v) and "[" not in v and self._is_snapshot_scalar(node, v):
                snapshot.add(v)

        # Keep key per-pass control flags if present.
        for v in ("drop", "forward"):
            if v in declared and self._is_snapshot_scalar(node, v):
                snapshot.add(v)

        # Keep any scalar vars referenced by DSL assertions (node-local + global).
        exprs: List[Tree] = []
        exprs.extend(self._spec.nodes.get(node, NodeDecl(name=node)).assert_exprs)
        exprs.extend(self._spec.global_decl.assert_exprs)
        for expr in exprs:
            for dv in _collect_dotted_vars(expr):
                # Ignore DSL locals (these are modeled as separate harness globals).
                if _dsl_is_simple_local_name(dv) and dv in self._dsl_node_vars.get(node, {}):
                    continue
                if _dsl_is_simple_local_name(dv) and dv in self._dsl_global_vars:
                    continue
                # Resolve `node_x` prefix if present; ignore other-node refs.
                raw = dv
                if dv.startswith(f"{node}_"):
                    raw = dv[len(node) + 1 :]
                else:
                    for other in self._spec.imports.keys():
                        if other != node and dv.startswith(f"{other}_"):
                            raw = ""
                            break
                if not raw or "[" in raw:
                    continue
                if raw in declared and self._is_snapshot_scalar(node, raw):
                    snapshot.add(raw)

        out = sorted(snapshot)
        self._two_stage_snapshot_vars[node] = out
        return out
