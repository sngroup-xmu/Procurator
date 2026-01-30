from __future__ import annotations

import re
from typing import Dict, List, Optional, Sequence

from lark import Tree

from ..speclang.model import HostDecl, LinkDecl, NodeDecl, SpecModel
from .boogie_common import dsl_is_simple_local_name, dsl_type_to_boogie, is_on_wire_packet_var, is_packet_var
from .boogie_dsl import collect_dotted_vars
from .boogie_errors import BoogieBackendError
from .boogie_harness_por import BoogieHarnessPorMixin
from .boogie_harness_render import BoogieHarnessRenderMixin
from .boogie_harness_sequential import BoogieHarnessSequentialMixin
from .boogie_harness_trace import BoogieHarnessTraceMixin
from .boogie_harness_links import BoogieHarnessLinksMixin
from .boogie_harness_mailbox import BoogieHarnessMailboxMixin
from .boogie_harness_start import BoogieHarnessStartMixin
from .boogie_harness_threads import BoogieHarnessThreadsMixin
from .boogie_harness_dsl import BoogieHarnessDslMixin
from .boogie_pipeline import PipelineStages


_dsl_is_simple_local_name = dsl_is_simple_local_name
_dsl_type_to_boogie = dsl_type_to_boogie
_collect_dotted_vars = collect_dotted_vars
_is_on_wire_packet_var = is_on_wire_packet_var
_is_packet_var = is_packet_var
_PipelineStages = PipelineStages


class BoogieHarnessEmitter(
    BoogieHarnessPorMixin,
    BoogieHarnessDslMixin,
    BoogieHarnessMailboxMixin,
    BoogieHarnessThreadsMixin,
    BoogieHarnessLinksMixin,
    BoogieHarnessStartMixin,
    BoogieHarnessRenderMixin,
    BoogieHarnessSequentialMixin,
    BoogieHarnessTraceMixin,
):
    """
    Emit a concurrent Boogie harness for Ultimate/GemCutter based on:
      - pass-atomic semantics (or two-stage ingress/egress when inferred)
      - bag(K) queue abstraction using inbox_count per node
      - environment thread injecting external inputs into nodes with external_input=true
    """

    def __init__(
        self,
        spec: SpecModel,
        node_input_vars: Dict[str, List[str]],
        node_egress_port_type: Dict[str, str],
        node_egress_port_var: Dict[str, str],
        node_declared_vars: Dict[str, set[str]],
        node_mainprocedure_modifies: Dict[str, set[str]],
        node_register_arrays: Optional[Dict[str, Dict[str, tuple[str, str]]]] = None,
        node_pipeline_stages: Optional[Dict[str, _PipelineStages]] = None,
        node_var_types: Optional[Dict[str, Dict[str, str]]] = None,
        node_type_defs: Optional[Dict[str, Dict[str, str]]] = None,
        node_meta: Optional[Dict[str, Optional[dict]]] = None,
        host_to_node: Optional[Dict[str, str]] = None,
        host_input_vars: Optional[Dict[str, List[str]]] = None,
        host_var_types: Optional[Dict[str, Dict[str, str]]] = None,
        *,
        max_env_inputs: bool = False,
        por_enabled: bool = False,
        por_guard_enabled: bool = True,
        harness_mode: str = "concurrent",
        pipeline_two_stage: bool = True,
        max_steps: Optional[int] = None,
        honor_spec_max_steps: bool = False,
    ):
        self._spec = spec
        self._node_input_vars = node_input_vars  # alias -> raw var names (no prefix)
        self._node_egress_port_type = node_egress_port_type  # alias -> raw type string
        self._node_egress_port_var = node_egress_port_var  # alias -> raw var name
        self._node_declared_vars = node_declared_vars  # alias -> set(raw var name)
        self._node_mainprocedure_modifies = node_mainprocedure_modifies  # alias -> set(prefixed var name)
        self._node_register_arrays = node_register_arrays or {}
        self._node_pipeline_stages = node_pipeline_stages or {}
        self._node_meta = node_meta or {}
        self._node_var_types = node_var_types or {}
        self._node_type_defs = node_type_defs or {}
        self._host_to_node = host_to_node or {}
        self._host_input_vars = host_input_vars or {}
        self._host_var_types = host_var_types or {}
        self._host_declared_vars: Dict[str, set[str]] = {
            h: set(self._host_input_vars.get(h, [])) for h in self._host_to_node.keys()
        }
        self._max_env_inputs = max_env_inputs
        # NOTE: `max_steps` is a *bounded bug-finding* knob (BMC-style). It is sound for UNSAFE
        # witnesses (the returned counterexample is concrete), but SAFE results are only within
        # the bound.
        #
        # To avoid silently changing semantics across the repository, we do NOT honor
        # `global.max_steps` from the DSL spec by default; it is only used when
        # `honor_spec_max_steps` is explicitly enabled.
        self._spec_max_steps: Optional[int] = (
            int(spec.global_decl.max_steps) if spec.global_decl.max_steps is not None else None
        )
        eff_max_steps: Optional[int]
        if max_steps is not None:
            eff_max_steps = int(max_steps)
        elif honor_spec_max_steps:
            eff_max_steps = self._spec_max_steps
        else:
            eff_max_steps = None
        if eff_max_steps is not None and eff_max_steps <= 0:
            raise ValueError(f"max_steps must be > 0, got {eff_max_steps}")
        self._max_steps = eff_max_steps
        # Step-indexed trace maps are intentionally disabled by default since they make loop proofs harder.
        self._emit_trace = False
        self._por_enabled = por_enabled
        self._por_guard_enabled = por_guard_enabled
        harness_mode = harness_mode.lower().strip()
        if harness_mode not in {"concurrent", "sequential"}:
            raise ValueError(f"unsupported harness_mode: {harness_mode}")
        self._harness_mode = harness_mode
        self._pipeline_two_stage = pipeline_two_stage
        self._node_ids: Dict[str, int] = {n: i + 1 for i, n in enumerate(spec.imports.keys())}
        self._two_stage_nodes = (
            set(self._node_pipeline_stages.keys()) if self._pipeline_two_stage else set()
        )
        self._por_guards: Dict[str, List[str]] = {}
        # Two-stage pipeline: preserve packet state across ingress->egress.
        self._two_stage_snapshot_vars: Dict[str, List[str]] = {}
        self._dsl_global_vars: Dict[str, str] = {}  # name -> boogie type
        self._dsl_node_vars: Dict[str, Dict[str, str]] = {}  # node -> (name -> boogie type)
        self._dsl_host_vars: Dict[str, Dict[str, str]] = {}  # host -> (name -> boogie type)
        self._analyze_dsl_state_vars()

        # meta schema: {"format":"p4bmeta-v1","var_types":{name:type},"sizes":{name:int},...}
        self._meta_var_types: Dict[str, Dict[str, str]] = {}
        self._meta_sizes: Dict[str, Dict[str, int]] = {}
        for n, m in self._node_meta.items():
            if not isinstance(m, dict):
                continue
            vt = m.get("var_types")
            sz = m.get("sizes")
            if isinstance(vt, dict):
                self._meta_var_types[n] = {str(k): str(v) for k, v in vt.items()}
            if isinstance(sz, dict):
                out_sz: Dict[str, int] = {}
                for k, v in sz.items():
                    try:
                        out_sz[str(k)] = int(v)
                    except Exception:
                        continue
                self._meta_sizes[n] = out_sz
        self._meta_register_inits: Dict[str, Dict[str, Dict[str, str]]] = {}
        for n, m in self._node_meta.items():
            if not isinstance(m, dict):
                continue
            ri = m.get("register_inits")
            if not isinstance(ri, dict):
                continue
            parsed: Dict[str, Dict[str, str]] = {}
            for reg, init_map in ri.items():
                if not isinstance(init_map, dict):
                    continue
                parsed[str(reg)] = {str(k): str(v) for k, v in init_map.items()}
            if parsed:
                self._meta_register_inits[n] = parsed
        self._tofino_recirculate_ports = self._infer_tofino_recirculate_ports()

    def _analyze_dsl_state_vars(self) -> None:
        """
        Collect DSL-declared local state variables from `var_decl` statements.

        Design choice:
        - DSL locals become Boogie globals (per-node namespaced), so they persist across loop iterations.
        - Initialization is emitted once in `ULTIMATE.start`.
        """
        self._dsl_global_vars = {}
        self._dsl_node_vars = {a: {} for a in self._spec.imports.keys()}
        self._dsl_host_vars = {h: {} for h in self._spec.hosts.keys()}

        # global { int X = 0; ... }
        for stmt in self._spec.global_decl.statements:
            if not isinstance(stmt, Tree) or str(stmt.data) != "var_decl":
                continue
            # var_decl: type dotted_var assign_op expression
            typ = str(stmt.children[0].data)  # int|bool
            var_name = self._dotted_var_to_str(stmt.children[1])
            if not _dsl_is_simple_local_name(var_name):
                continue
            self._dsl_global_vars[var_name] = _dsl_type_to_boogie(typ)

        # node { int Counter = 0; ... }
        for node, nd in self._spec.nodes.items():
            self._dsl_node_vars.setdefault(node, {})
            for stmt in nd.statements:
                if not isinstance(stmt, Tree) or str(stmt.data) != "var_decl":
                    continue
                typ = str(stmt.children[0].data)  # int|bool
                var_name = self._dotted_var_to_str(stmt.children[1])
                if not _dsl_is_simple_local_name(var_name):
                    continue
                self._dsl_node_vars[node][var_name] = _dsl_type_to_boogie(typ)

        for host, hd in self._spec.hosts.items():
            self._dsl_host_vars.setdefault(host, {})
            for stmt in hd.statements:
                if not isinstance(stmt, Tree) or str(stmt.data) != "var_decl":
                    continue
                typ = str(stmt.children[0].data)  # int|bool
                var_name = self._dotted_var_to_str(stmt.children[1])
                if not _dsl_is_simple_local_name(var_name):
                    continue
                self._dsl_host_vars[host][var_name] = _dsl_type_to_boogie(typ)

    def _validate_sink_nodes(self, sink_nodes: Sequence[str]) -> None:
        if not sink_nodes:
            return
        outgoing = {l.src for l in self._spec.links}
        for n in sink_nodes:
            nd = self._spec.nodes.get(n, NodeDecl(name=n))
            if nd.external_input is True:
                raise BoogieBackendError(f"node '{n}' is marked sink=true but also external_input=true")
            if nd.env_statements:
                raise BoogieBackendError(f"node '{n}' is marked sink=true but defines an env{{...}} block")
            if n in outgoing:
                raise BoogieBackendError(f"node '{n}' is marked sink=true but has outgoing topology links")

    def _emit_bitvector_helpers(self) -> str:
        return (
            "function bvule.bv16(left:bv16, right:bv16) returns(bool);\n"
            "function {:bvbuiltin \"bvule\"} bvule.bv16$builtin(left:bv16, right:bv16) returns(bool);\n"
            "axiom (forall left:bv16, right:bv16 :: bvule.bv16(left, right) <==> bvule.bv16$builtin(left, right));\n"
            "function bvule.bv32(left:bv32, right:bv32) returns(bool);\n"
            "function {:bvbuiltin \"bvule\"} bvule.bv32$builtin(left:bv32, right:bv32) returns(bool);\n"
            "axiom (forall left:bv32, right:bv32 :: bvule.bv32(left, right) <==> bvule.bv32$builtin(left, right));\n"
        )

    def emit_helpers(self) -> str:
        return self._emit_bitvector_helpers()

    def emit(self, *, emit_helpers: bool = True) -> str:
        k = self._spec.global_decl.queue_capacity if self._spec.global_decl.queue_capacity is not None else 5
        if k <= 0:
            raise ValueError(f"queue_capacity must be > 0, got {k}")

        all_node_aliases = list(self._spec.imports.keys())
        sink_nodes = [n for n in all_node_aliases if self._is_sink_node(n)]
        self._validate_sink_nodes(sink_nodes)
        # Scheduled nodes are the ones that actually execute P4 passes (threads / scheduler actions).
        node_aliases = [n for n in all_node_aliases if n not in sink_nodes]
        host_aliases = list(self._spec.hosts.keys())
        if self._por_enabled and self._por_guard_enabled:
            self._por_guards = self._compute_por_guards(node_aliases)
        else:
            self._por_guards = {}

        if self._harness_mode == "concurrent":
            lines: List[str] = []
            lines.append("// Auto-generated by Procurator (DSL -> Boogie harness for GemCutter)\n")
            if self._por_enabled and self._por_guard_enabled:
                lines.append("// POR enabled: commutativity-based guards\n")
            lines.append(
                f"// Message abstraction: Bag(K={k}) using inbox_count per node; single-slot mailbox for packet fields\n\n"
            )

            if emit_helpers:
                lines.append(self._emit_bitvector_helpers())

            # A global lock to realize pass-atomic semantics without large atomic blocks.
            # We keep atomic blocks minimal (lock acquire/release only), to avoid Ultimate's atomic composition issues.
            lines.append("var procurator_lock: int;\n\n")
            if self._max_steps is not None:
                lines.append("var procurator_step: int;\n\n")

            # DSL locals as globals
            if (
                self._dsl_global_vars
                or any(self._dsl_node_vars.get(a) for a in all_node_aliases)
                or any(self._dsl_host_vars.get(h) for h in host_aliases)
            ):
                lines.append("// DSL state variables (modeled as Boogie globals)\n")
                for name, typ in sorted(self._dsl_global_vars.items()):
                    lines.append(f"var dsl_{name}: {typ};\n")
                for n in all_node_aliases:
                    for name, typ in sorted(self._dsl_node_vars.get(n, {}).items()):
                        lines.append(f"var {n}_dsl_{name}: {typ};\n")
                for h in host_aliases:
                    for name, typ in sorted(self._dsl_host_vars.get(h, {}).items()):
                        lines.append(f"var {h}_dsl_{name}: {typ};\n")
                lines.append("\n")

            reg_debug_decls = self._emit_register_debug_decls(node_aliases)
            if reg_debug_decls:
                lines.append("// Register debug snapshots (for trace inspection)\n")
                lines.append(reg_debug_decls)
                lines.append("\n")

            # Inbox counters
            for a in node_aliases + host_aliases:
                lines.append(f"var {a}_inbox_count: int;\n")
            lines.append("\n")

            if self._two_stage_nodes:
                lines.append("// Two-stage pipeline: pending egress events per node\n")
                for a in node_aliases:
                    if self._is_two_stage_node(a):
                        lines.append(f"var {a}_egress_count: int;\n")
                lines.append("\n")
                lines.append("// Two-stage pipeline: egress mailbox snapshots (preserve packet state across stages)\n")
                for a in node_aliases:
                    if not self._is_two_stage_node(a):
                        continue
                    for v in self._two_stage_snapshot_var_bases(a):
                        vt = self._node_var_types.get(a, {}).get(v)
                        if not isinstance(vt, str) or not vt.strip():
                            continue
                        typ = self._prefix_node_type(a, vt)
                        if self._two_slot_egress_enabled(k):
                            lines.append(f"var {self._egress_slot_var(a, 0, v)}: {typ};\n")
                            lines.append(f"var {self._egress_slot_var(a, 1, v)}: {typ};\n")
                        else:
                            lines.append(f"var {self._egress_mailbox_var(a, v)}: {typ};\n")
                        lines.append(f"var {self._ingress_saved_var(a, v)}: {typ};\n")
                lines.append("\n")

            # Single-slot mailbox classification: whether the currently-stored packet fields originated from Env injection.
            # This lets us avoid havoc'ing forwarded packets (otherwise forwarding copy is immediately overwritten).
            for a in node_aliases + host_aliases:
                lines.append(f"var {a}_pkt_external: bool;\n")
            lines.append("\n")

            if self._two_slot_inbox_enabled(k):
                lines.append("// Two-slot inbox mailbox (on-wire packet vars only)\n")
                for a in node_aliases:
                    for v in self._inbox_on_wire_vars(a):
                        vt = self._node_var_types.get(a, {}).get(v, "")
                        if vt == "Ref" or vt.endswith("Ref"):
                            continue
                        typ = self._prefix_node_type(a, vt)
                        lines.append(f"var {self._inbox_slot_var(a, 0, v)}: {typ};\n")
                        lines.append(f"var {self._inbox_slot_var(a, 1, v)}: {typ};\n")
                lines.append("\n")

            # Host packet fields (mirror the connected node's packet/metadata vars).
            if host_aliases:
                lines.append("// Host packet fields (mirrors connected node symbols)\n")
                seen: set[str] = set()
                for h in host_aliases:
                    for v in self._host_input_vars.get(h, []):
                        name = f"{h}_{v}"
                        if name in seen:
                            continue
                        seen.add(name)
                        typ = self._host_var_types.get(h, {}).get(v, "bv32")
                        if typ == "Ref" or typ.endswith("Ref"):
                            continue
                        lines.append(f"var {name}: {typ};\n")
                lines.append("\n")

            # Forward procedures
            lines.append("// Forwarding (derived from DSL topology)\n")
            for src in node_aliases:
                lines.append(self._emit_forward_proc(src, k))
                lines.append("\n")

            # Two-stage wrappers (if enabled)
            stage_procs = self._emit_pipeline_stage_procs()
            if stage_procs:
                lines.append(stage_procs)

            # Env thread (optional)
            env_thread_enabled = self._spec.global_decl.env_thread is not False
            if env_thread_enabled:
                lines.append(self._emit_env_thread(k))
                lines.append("\n")

            # Node threads
            for a in node_aliases:
                lines.append(self._emit_node_thread(a, k))
                lines.append("\n")

            # Host threads
            for h in host_aliases:
                lines.append(self._emit_host_thread(h, k))
                lines.append("\n")

            # ULTIMATE.start
            lines.append(self._emit_ultimate_start(node_aliases, host_aliases, env_thread_enabled=env_thread_enabled))
            lines.append("\n")

            return "".join(lines)

        # Sequential harness: single-thread scheduler (no fork/atomic).
        lines = []
        lines.append("// Auto-generated by Procurator (DSL -> Boogie harness: sequential scheduler)\n")
        if self._por_enabled and self._por_guard_enabled:
            lines.append("// POR enabled: commutativity-based guards\n")
        lines.append(
            f"// Message abstraction: Bag(K={k}) using inbox_count per node; single-slot mailbox for packet fields\n\n"
        )

        if emit_helpers:
            lines.append(self._emit_bitvector_helpers())

        # Sequential harness is unbounded by default. A bounded run can be enabled via `max_steps`.
        lines.append("var procurator_step: int;\n")
        if self._accumulate_global_assertions():
            lines.append("var procurator_bad: bool;\n")
        if self._needs_deterministic_phase_var():
            # Avoid integer modulo in the scheduler encoding (helps Ultimate on deep loops).
            lines.append("var procurator_phase: int;\n")
        lines.append("\n")

        # DSL locals as globals
        if (
            self._dsl_global_vars
            or any(self._dsl_node_vars.get(a) for a in all_node_aliases)
            or any(self._dsl_host_vars.get(h) for h in host_aliases)
        ):
            lines.append("// DSL state variables (modeled as Boogie globals)\n")
            for name, typ in sorted(self._dsl_global_vars.items()):
                lines.append(f"var dsl_{name}: {typ};\n")
            for n in all_node_aliases:
                for name, typ in sorted(self._dsl_node_vars.get(n, {}).items()):
                    lines.append(f"var {n}_dsl_{name}: {typ};\n")
            for h in host_aliases:
                for name, typ in sorted(self._dsl_host_vars.get(h, {}).items()):
                    lines.append(f"var {h}_dsl_{name}: {typ};\n")
            lines.append("\n")

        reg_debug_decls = self._emit_register_debug_decls(node_aliases)
        if reg_debug_decls:
            lines.append("// Register debug snapshots (for trace inspection)\n")
            lines.append(reg_debug_decls)
            lines.append("\n")

        trace_decls = self._emit_trace_decls(node_aliases)
        if trace_decls:
            lines.append("// Trace arrays (indexed by procurator_step)\n")
            lines.append(trace_decls)
            lines.append("\n")

        # Inbox counters
        for a in node_aliases + host_aliases:
            lines.append(f"var {a}_inbox_count: int;\n")
        lines.append("\n")

        if self._two_stage_nodes:
            lines.append("// Two-stage pipeline: pending egress events per node\n")
            for a in node_aliases:
                if self._is_two_stage_node(a):
                    lines.append(f"var {a}_egress_count: int;\n")
            lines.append("\n")
            lines.append("// Two-stage pipeline: egress mailbox snapshots (preserve packet state across stages)\n")
            for a in node_aliases:
                if not self._is_two_stage_node(a):
                    continue
                for v in self._two_stage_snapshot_var_bases(a):
                    vt = self._node_var_types.get(a, {}).get(v)
                    if not isinstance(vt, str) or not vt.strip():
                        continue
                    typ = self._prefix_node_type(a, vt)
                    if self._two_slot_egress_enabled(k):
                        lines.append(f"var {self._egress_slot_var(a, 0, v)}: {typ};\n")
                        lines.append(f"var {self._egress_slot_var(a, 1, v)}: {typ};\n")
                    else:
                        lines.append(f"var {self._egress_mailbox_var(a, v)}: {typ};\n")
                    lines.append(f"var {self._ingress_saved_var(a, v)}: {typ};\n")
            lines.append("\n")

        # Single-slot mailbox classification: whether the currently-stored packet fields originated from Env injection.
        for a in node_aliases + host_aliases:
            lines.append(f"var {a}_pkt_external: bool;\n")
        lines.append("\n")

        if self._two_slot_inbox_enabled(k):
            lines.append("// Two-slot inbox mailbox (on-wire packet vars only)\n")
            for a in node_aliases:
                for v in self._inbox_on_wire_vars(a):
                    vt = self._node_var_types.get(a, {}).get(v, "")
                    if vt == "Ref" or vt.endswith("Ref"):
                        continue
                    typ = self._prefix_node_type(a, vt)
                    lines.append(f"var {self._inbox_slot_var(a, 0, v)}: {typ};\n")
                    lines.append(f"var {self._inbox_slot_var(a, 1, v)}: {typ};\n")
            lines.append("\n")

        # Host packet fields (mirror the connected node's packet/metadata vars).
        if host_aliases:
            lines.append("// Host packet fields (mirrors connected node symbols)\n")
            seen = set()
            for h in host_aliases:
                for v in self._host_input_vars.get(h, []):
                    name = f"{h}_{v}"
                    if name in seen:
                        continue
                    seen.add(name)
                    typ = self._host_var_types.get(h, {}).get(v, "bv32")
                    if typ == "Ref" or typ.endswith("Ref"):
                        continue
                    lines.append(f"var {name}: {typ};\n")
            lines.append("\n")

        # Forward procedures
        lines.append("// Forwarding (derived from DSL topology)\n")
        for src in node_aliases:
            lines.append(self._emit_forward_proc(src, k))
            lines.append("\n")

        # Two-stage wrappers (if enabled)
        stage_procs = self._emit_pipeline_stage_procs()
        if stage_procs:
            lines.append(stage_procs)

        env_thread_enabled = self._spec.global_decl.env_thread is not False
        lines.append(self._emit_sequential_main(node_aliases, host_aliases, k=k, env_thread_enabled=env_thread_enabled))
        lines.append("\n")
        lines.append(self._emit_sequential_start(node_aliases, host_aliases))
        lines.append("\n")

        return "".join(lines)
