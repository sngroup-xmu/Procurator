from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Dict, Iterable, List, Optional, Sequence, Set

from lark import Tree

from .boogie_common import dsl_is_simple_local_name, is_on_wire_packet_var, is_packet_var, is_skipped_input_var
from .boogie_dsl import collect_dotted_vars, dotted_var_to_str
from ..speclang.model import SpecModel


_DBG_IDX0_SUFFIXES = {
    "__dbg0",
    "__wrote_index0",
    "__wrote_index0__dbg",
    "__last0_value",
    "__last0_value__dbg",
}
_DBG_ANY_SUFFIXES = {
    "__last_index",
    "__last_value",
    "__wrote_any",
    "__last_index__dbg",
    "__last_value__dbg",
    "__wrote_any__dbg",
}


@dataclass(frozen=True)
class SlicingPlan:
    """
    Data that dslc needs to drive per-node P4B slicing and env pruning.
    """

    # Per-node seeds passed to P4B (`--slicing-vars=...`).
    slicing_vars: Dict[str, List[str]]
    # Packet vars referenced in DSL/spec (for patching missing Boogie decls in raw .bpl).
    required_packet_vars: Dict[str, List[str]]
    # Packet vars that must stay in the per-pass havoc list (env pruning force-keep).
    forced_packet_inputs: Dict[str, List[str]]


def collect_dsl_local_names(spec: SpecModel) -> Set[str]:
    """
    Collect DSL-declared locals so we don't accidentally treat them as P4 slicing seeds.
    """
    out: Set[str] = set()

    def add_from_statements(stmts: Sequence[object]) -> None:
        for stmt in stmts:
            if not isinstance(stmt, Tree) or str(stmt.data) != "var_decl":
                continue
            if len(stmt.children) < 2 or not isinstance(stmt.children[1], Tree):
                continue
            out.add(dotted_var_to_str(stmt.children[1]))

    add_from_statements(spec.global_decl.statements)
    for nd in spec.nodes.values():
        add_from_statements(nd.statements)
    for hd in spec.hosts.values():
        add_from_statements(hd.statements)

    return out


def build_slicing_plan(
    spec: SpecModel,
    *,
    enable_slicing: bool,
    keep_control_seeds: bool = True,
) -> SlicingPlan:
    """
    Heuristic slicing plan for distributed P4 verification.

    Core rule of thumb:
      - Slice seeds should come from variables that affect the property (asserts)
        and variables that affect forwarding semantics (egress_port / clone / recirc),
        not from arbitrary environment assumptions.
    """
    dsl_locals = collect_dsl_local_names(spec)

    def add_seed(seeds: Dict[str, Set[str]], node: str, name: str) -> None:
        if node not in seeds:
            return
        if name in dsl_locals and "." not in name and "[" not in name:
            return

        for rewritten in _rewrite_seed_names(name):
            if not rewritten:
                continue
            seeds[node].add(rewritten)

            # Add the base without any `[idx]` suffix so the slicer can keep the underlying variable,
            # while preserving indexed forms so P4B can infer register max-index bounds.
            base = rewritten
            idx_suffix = ""
            if "[" in rewritten:
                base = rewritten.split("[", 1)[0]
                idx_suffix = rewritten[len(base) :]
                seeds[node].add(base)

            # P4B sometimes appends `_0` suffixes for pipeline instances; keep both forms.
            if base.endswith("_0"):
                stripped = base[:-2]
                seeds[node].add(stripped)
                if idx_suffix:
                    seeds[node].add(stripped + idx_suffix)
            else:
                with_suffix = base + "_0"
                seeds[node].add(with_suffix)
                if idx_suffix:
                    seeds[node].add(with_suffix + idx_suffix)

    def is_other_node_ref(current_node: str, name: str) -> bool:
        for other in spec.imports.keys():
            if other != current_node and name.startswith(f"{other}_"):
                return True
        return False

    seeds: Dict[str, Set[str]] = {a: set() for a in spec.imports.keys()}
    required_packet: Dict[str, Set[str]] = {a: set() for a in spec.imports.keys()}

    def note_required_packet(node: str, name: str) -> None:
        if node not in required_packet:
            return
        if is_packet_var(name):
            required_packet[node].add(name)

    def scan_exprs(
        *,
        node: str,
        exprs: Iterable[Tree],
        include_as_seed: bool,
    ) -> None:
        for expr in exprs:
            for v in collect_dotted_vars(expr):
                if v.startswith(f"{node}_"):
                    raw = v[len(node) + 1 :]
                elif is_other_node_ref(node, v):
                    continue
                else:
                    raw = v
                note_required_packet(node, raw)
                if include_as_seed:
                    add_seed(seeds, node, raw)

    def scan_statements(*, node: str, stmts: Iterable[Tree]) -> None:
        for stmt in stmts:
            # Assumptions constrain the environment/state space but are not slice criteria.
            if isinstance(stmt, Tree) and str(stmt.data) == "assume_statement":
                for v in collect_dotted_vars(stmt):
                    if v.startswith(f"{node}_"):
                        raw = v[len(node) + 1 :]
                    elif is_other_node_ref(node, v):
                        continue
                    else:
                        raw = v
                    note_required_packet(node, raw)
                continue

            for v in collect_dotted_vars(stmt):
                if v.startswith(f"{node}_"):
                    raw = v[len(node) + 1 :]
                elif is_other_node_ref(node, v):
                    continue
                else:
                    raw = v
                note_required_packet(node, raw)
                add_seed(seeds, node, raw)

    def scan_required_only_stmts(*, node: str, stmts: Iterable[Tree]) -> None:
        for stmt in stmts:
            for v in collect_dotted_vars(stmt):
                if v.startswith(f"{node}_"):
                    raw = v[len(node) + 1 :]
                elif is_other_node_ref(node, v):
                    continue
                else:
                    raw = v
                note_required_packet(node, raw)

    # Node-local: seeds from assertions + DSL statements; assumptions are NOT slice criteria.
    for node, nd in spec.nodes.items():
        scan_exprs(node=node, exprs=nd.assert_exprs, include_as_seed=True)
        scan_statements(node=node, stmts=nd.statements)
        # Assumptions may still reference packet vars; keep them as required decls only.
        scan_exprs(node=node, exprs=nd.assume_exprs, include_as_seed=False)
        # Env blocks are packet generation constraints; never slice on them, but keep decls.
        scan_required_only_stmts(node=node, stmts=nd.env_statements)

    # Global asserts: map to node prefixes if present, otherwise conservatively apply to all nodes.
    for expr in spec.global_decl.assert_exprs:
        vars_ = list(collect_dotted_vars(expr))
        for v in vars_:
            matched = False
            for node in spec.imports.keys():
                if v.startswith(f"{node}_"):
                    raw = v[len(node) + 1 :]
                    note_required_packet(node, raw)
                    add_seed(seeds, node, raw)
                    matched = True
                    break
            if not matched:
                for node in spec.imports.keys():
                    note_required_packet(node, v)
                    add_seed(seeds, node, v)

    # Global assumes: required decls only.
    for expr in spec.global_decl.assume_exprs:
        vars_ = list(collect_dotted_vars(expr))
        for v in vars_:
            matched = False
            for node in spec.imports.keys():
                if v.startswith(f"{node}_"):
                    raw = v[len(node) + 1 :]
                    note_required_packet(node, raw)
                    matched = True
                    break
            if not matched:
                for node in spec.imports.keys():
                    note_required_packet(node, v)

    # Host scope: treat as constraints/seeds for the connected node.
    for host, hd in spec.hosts.items():
        target = hd.connect_to
        if not target or target not in seeds:
            continue
        scan_exprs(node=target, exprs=hd.assert_exprs, include_as_seed=True)
        scan_statements(node=target, stmts=hd.statements)
        scan_exprs(node=target, exprs=hd.assume_exprs, include_as_seed=False)
        scan_required_only_stmts(node=target, stmts=hd.env_statements)

    if enable_slicing:
        # System-level communication seeds:
        # P4B slicing runs per-node and does not see our harness/topology semantics, so we must
        # conservatively keep control variables that affect cross-node communication.
        if keep_control_seeds:
            control_seeds_distributed = {
                # forwarding / routing
                "standard_metadata.egress_port",
                "standard_metadata.egress_spec",
                "ig_intr_tm_md.ucast_egress_port",
                "ig_tm_md.ucast_egress_port",
                "eg_intr_md.egress_port",
                "forward",
                "drop",
                # clone / recirculation flags
                "p4b_clone_i2e",
                "p4b_clone_e2e",
                "p4b_clone_i2i",
                "p4b_recirculate",
            }
            control_seeds_single_node = {
                "p4b_clone_i2i",
                "p4b_recirculate",
            }
            extra = control_seeds_distributed if spec.links else control_seeds_single_node
            for node in list(seeds.keys()):
                for v in extra:
                    add_seed(seeds, node, v)
                    # NOTE: These are system-level "keep if present" control seeds. They are not
                    # spec-authored references, and may not exist in all architectures/translated
                    # Boogie units (e.g., v1model uses `standard_metadata.egress_port`, Tofino uses
                    # `eg_intr_md.egress_port`). Keep them as slicing seeds, but don't require them.

    slicing_vars: Dict[str, List[str]] = {k: sorted(v) for k, v in seeds.items()}
    if enable_slicing and spec.links:
        slicing_vars = propagate_packet_seeds(spec, slicing_vars)

    forced_packet_inputs: Dict[str, List[str]] = {}
    for node, vars_ in slicing_vars.items():
        forced_packet_inputs[node] = sorted(v for v in vars_ if is_packet_var(v) and not is_skipped_input_var(v))

    required_packet_vars: Dict[str, List[str]] = {k: sorted(v) for k, v in required_packet.items()}
    return SlicingPlan(
        slicing_vars=slicing_vars if enable_slicing else {},
        required_packet_vars=required_packet_vars,
        forced_packet_inputs=forced_packet_inputs,
    )


def propagate_packet_seeds(spec: SpecModel, seeds: Dict[str, List[str]]) -> Dict[str, List[str]]:
    """
    Propagate on-wire packet-carried vars backward along topology so upstream nodes keep needed headers.

    Only `hdr.*` is on-wire and can be copied along links; meta/standard_metadata are node-local.
    """
    work: Dict[str, Set[str]] = {n: set(vs) for n, vs in seeds.items()}
    packet_only: Dict[str, Set[str]] = {n: {v for v in vs if is_on_wire_packet_var(v)} for n, vs in work.items()}
    changed = True
    while changed:
        changed = False
        for link in spec.links:
            dst_vars = packet_only.get(link.dst, set())
            src_vars = packet_only.setdefault(link.src, set())
            new = dst_vars - src_vars
            if new:
                src_vars.update(new)
                work.setdefault(link.src, set()).update(new)
                changed = True
    return {k: sorted(v) for k, v in work.items()}


def _rewrite_seed_names(raw: str) -> List[str]:
    # Boogie-only trace/debug variables should not be passed to P4B's slicer.
    if raw.startswith("trace_"):
        return []

    for s in sorted(_DBG_IDX0_SUFFIXES, key=len, reverse=True):
        if raw.endswith(s):
            return [raw[: -len(s)] + "[0]"]
    for s in sorted(_DBG_ANY_SUFFIXES, key=len, reverse=True):
        if raw.endswith(s):
            return [raw[: -len(s)]]
    return [raw]
