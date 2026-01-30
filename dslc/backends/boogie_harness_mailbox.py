from __future__ import annotations

from typing import List, Sequence

from lark import Tree

from ..speclang.model import NodeDecl
from .boogie_common import is_on_wire_packet_var


class BoogieHarnessMailboxMixin:
    """
    Mailbox/queue modeling helpers for the Boogie harness.

    Responsibilities:
      - Emit enqueue statements for external/internal injections.
      - Provide the two-slot mailbox model used when queue_capacity == 2.

    Notes:
      - This mixin expects the main emitter to provide:
          * self._spec, self._node_input_vars, self._node_declared_vars
          * self._max_env_inputs
          * self._emit_env_inject_statements(), self._expr_to_boogie()
          * self._two_stage_snapshot_var_bases()
    """

    def _emit_assert_lines(self, exprs: Sequence[Tree], *, indent: str, current_node: str) -> str:
        out: List[str] = []
        for expr in exprs:
            bpl = self._expr_to_boogie(expr, current_node=current_node, prefer_reg_dbg=True)
            out.append(f"{indent}assert {bpl};\n")
        return "".join(out)

    def _emit_external_enqueue_stmt(self, dst: str, k: int, indent: str, deterministic: bool) -> str:
        out: List[str] = []
        if deterministic:
            out.append(f"{indent}if ({dst}_inbox_count < {k}) {{\n")
        # Enqueue an external packet: havoc its fields + apply DSL env constraints at injection time.
        out.append(f"{indent}assume {dst}_inbox_count < {k};\n")
        out.append(f"{indent}{dst}_pkt_external := true;\n")
        for v in self._node_input_vars.get(dst, []):
            out.append(f"{indent}havoc {dst}_{v};\n")
        if not self._max_env_inputs:
            env_lines = self._emit_env_inject_statements(dst, indent=indent)
            if env_lines:
                out.append(env_lines)
            for expr in self._spec.nodes.get(dst, NodeDecl(name=dst)).assume_exprs:
                out.append(f"{indent}assume {self._expr_to_boogie(expr, current_node=dst)};\n")
            for expr in self._spec.global_decl.assume_exprs:
                out.append(f"{indent}assume {self._expr_to_boogie(expr, current_node=dst)};\n")
        if self._two_slot_inbox_enabled(k):
            out.append(self._emit_inbox_store_from_active(dst, slot_expr=f"{dst}_inbox_count", indent=indent))
        out.append(f"{indent}{dst}_inbox_count := {dst}_inbox_count + 1;\n")
        if deterministic:
            out.append(f"{indent}}}\n")
        return "".join(out)

    def _emit_internal_enqueue_stmt(self, dst: str, k: int, indent: str) -> str:
        out: List[str] = []
        # Internal enqueue (recirculate/i2i): keep current packet fields intact.
        out.append(f"{indent}assume {dst}_inbox_count < {k};\n")
        if self._two_slot_inbox_enabled(k):
            out.append(self._emit_inbox_store_from_active(dst, slot_expr=f"{dst}_inbox_count", indent=indent))
        out.append(f"{indent}{dst}_pkt_external := false;\n")
        out.append(f"{indent}{dst}_inbox_count := {dst}_inbox_count + 1;\n")
        return "".join(out)

    def _two_slot_inbox_enabled(self, k: int) -> bool:
        """
        Enable a two-slot mailbox model when `queue_capacity == 2`.

        Rationale: the default single-slot mailbox is an aggressive abstraction
        that cannot faithfully represent two distinct pending packets at a node.
        Many concurrency bugs (e.g., overlapping recirculations) require at least
        two buffered packets. We keep this path gated to `k==2` to avoid impacting
        existing benchmarks that rely on the legacy behavior for k!=2.
        """

        return int(k) == 2

    def _two_slot_egress_enabled(self, k: int) -> bool:
        """
        Enable a two-slot mailbox model for the two-stage egress queue when `queue_capacity == 2`.

        Rationale: the two-stage pipeline can have multiple pending "egress events" per node
        (e.g., two packets between ingress and egress, or a packet plus a clone). If we only keep
        a single egress snapshot and a counter, the later event overwrites the earlier snapshot,
        which under-approximates packet-level behavior and may hide ordering bugs.
        """

        return self._two_slot_inbox_enabled(k)

    def _inbox_on_wire_vars(self, node: str) -> List[str]:
        declared = self._node_declared_vars.get(node, set())
        out: List[str] = []
        for v in self._node_input_vars.get(node, []):
            if not is_on_wire_packet_var(v):
                continue
            if v not in declared:
                continue
            out.append(v)
        return out

    def _inbox_slot_var(self, node: str, slot: int, base: str) -> str:
        return f"{node}_mb{slot}_{base}"

    def _egress_slot_var(self, node: str, slot: int, base: str) -> str:
        return f"{node}__eg_mb{slot}_{base}"

    def _emit_egress_store_from_active(self, node: str, *, slot_expr: str, indent: str) -> str:
        """
        Store the current active packet snapshot (`{node}_*`) into the two-slot egress mailbox
        slot selected by `slot_expr` (expected 0 or 1).
        """

        snap = self._two_stage_snapshot_var_bases(node)
        if not snap:
            return ""
        out: List[str] = []
        out.append(f"{indent}if ({slot_expr} == 0) {{\n")
        for v in snap:
            out.append(f"{indent}  {self._egress_slot_var(node, 0, v)} := {node}_{v};\n")
        out.append(f"{indent}}} else {{\n")
        for v in snap:
            out.append(f"{indent}  {self._egress_slot_var(node, 1, v)} := {node}_{v};\n")
        out.append(f"{indent}}}\n")
        return "".join(out)

    def _emit_egress_load_to_active(self, node: str, *, slot: int, indent: str) -> str:
        """
        Load two-slot egress mailbox slot `slot` into the active packet variables (`{node}_*`).
        """

        snap = self._two_stage_snapshot_var_bases(node)
        if not snap:
            return ""
        out: List[str] = []
        for v in snap:
            out.append(f"{indent}{node}_{v} := {self._egress_slot_var(node, slot, v)};\n")
        return "".join(out)

    def _emit_egress_shift_slot1_to_slot0(self, node: str, *, indent: str) -> str:
        """
        Shift egress slot1 -> slot0 after consuming slot0 (two-slot egress model).
        """

        snap = self._two_stage_snapshot_var_bases(node)
        if not snap:
            return ""
        out: List[str] = []
        for v in snap:
            out.append(f"{indent}{self._egress_slot_var(node, 0, v)} := {self._egress_slot_var(node, 1, v)};\n")
        return "".join(out)

    def _emit_inbox_store_from_active(self, node: str, *, slot_expr: str, indent: str) -> str:
        """
        Store the current active packet fields (`{node}_{hdr.*}`) into the inbox mailbox
        slot selected by `slot_expr` (expected 0 or 1).
        """

        vars_ = self._inbox_on_wire_vars(node)
        if not vars_:
            return ""
        out: List[str] = []
        out.append(f"{indent}if ({slot_expr} == 0) {{\n")
        for v in vars_:
            out.append(f"{indent}  {self._inbox_slot_var(node, 0, v)} := {node}_{v};\n")
        out.append(f"{indent}}} else {{\n")
        for v in vars_:
            out.append(f"{indent}  {self._inbox_slot_var(node, 1, v)} := {node}_{v};\n")
        out.append(f"{indent}}}\n")
        return "".join(out)

    def _emit_inbox_load_to_active(self, node: str, *, slot: int, indent: str) -> str:
        """
        Load inbox mailbox slot `slot` into the active packet variables (`{node}_{hdr.*}`).
        """

        vars_ = self._inbox_on_wire_vars(node)
        if not vars_:
            return ""
        out: List[str] = []
        for v in vars_:
            out.append(f"{indent}{node}_{v} := {self._inbox_slot_var(node, slot, v)};\n")
        return "".join(out)

    def _emit_inbox_shift_slot1_to_slot0(self, node: str, *, indent: str) -> str:
        """
        Shift slot1 -> slot0 after consuming slot0 (two-slot inbox model).
        """

        vars_ = self._inbox_on_wire_vars(node)
        if not vars_:
            return ""
        out: List[str] = []
        for v in vars_:
            out.append(f"{indent}{self._inbox_slot_var(node, 0, v)} := {self._inbox_slot_var(node, 1, v)};\n")
        return "".join(out)

