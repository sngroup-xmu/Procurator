from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Dict, List, Optional, Sequence, Tuple

from lark import Tree

from ..speclang.model import HostDecl, LinkDecl, NodeDecl, SpecModel
from .boogie_common import dsl_is_simple_local_name, dsl_type_to_boogie, is_on_wire_packet_var
from .boogie_dsl import collect_dotted_vars
from .boogie_errors import BoogieBackendError
from .boogie_pipeline import PipelineStages


_dsl_is_simple_local_name = dsl_is_simple_local_name
_dsl_type_to_boogie = dsl_type_to_boogie
_collect_dotted_vars = collect_dotted_vars
_is_on_wire_packet_var = is_on_wire_packet_var
_PipelineStages = PipelineStages


@dataclass(frozen=True)
class _RwKey:
    obj: str
    key: Optional[str] = None


class BoogieHarnessEmitter:
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

    def _collect_expr_reads(self, expr: Tree, *, current_node: str) -> set[_RwKey]:
        reads: set[_RwKey] = set()
        for dv in expr.find_data("dotted_var"):
            if not isinstance(dv, Tree):
                continue
            name = self._dotted_var_to_boogie(dv, current_node=current_node)
            if name:
                reads.add(_RwKey(obj=name))
        return reads

    def _infer_tofino_recirculate_ports(self) -> List[int]:
        ports: set[int] = set()
        for imp in self._spec.imports.values():
            path = imp.path.lower()
            if path.endswith(".json") or "tofino" in path or "/gecko/" in path:
                ports.update({68, 196})
                break
        return sorted(ports)

    def _parse_stateful_rw(self, node: str) -> tuple[set[_RwKey], set[_RwKey]]:
        meta = self._node_meta.get(node)
        if not isinstance(meta, dict):
            return set(), set()
        rw = meta.get("rw")
        if not isinstance(rw, dict):
            return set(), set()
        stateful = {str(x) for x in rw.get("stateful", [])}
        reads_raw = rw.get("reads", []) if isinstance(rw.get("reads"), list) else []
        writes_raw = rw.get("writes", []) if isinstance(rw.get("writes"), list) else []

        def parse_key(s: str) -> Optional[_RwKey]:
            if not s:
                return None
            parts = s.split(".")
            base = parts[0]
            if base not in stateful:
                return None
            key: Optional[str] = None
            if len(parts) > 1:
                tail = parts[1]
                m = re.match(r"^([0-9]+)(?:bv[0-9]+)?$", tail)
                if m:
                    key = m.group(1)
            obj = f"{node}_{base}"
            return _RwKey(obj=obj, key=key)

        reads: set[_RwKey] = set()
        writes: set[_RwKey] = set()
        for item in reads_raw:
            k = parse_key(str(item))
            if k is not None:
                reads.add(k)
        for item in writes_raw:
            k = parse_key(str(item))
            if k is not None:
                writes.add(k)
        return reads, writes

    @staticmethod
    def _rw_index(keys: set[_RwKey]) -> Dict[str, tuple[bool, set[str]]]:
        indexed: Dict[str, tuple[bool, set[str]]] = {}
        for k in keys:
            if k.obj not in indexed:
                indexed[k.obj] = (False, set())
            wild, vals = indexed[k.obj]
            if k.key is None:
                indexed[k.obj] = (True, vals)
            else:
                vals.add(k.key)
                indexed[k.obj] = (wild, vals)
        return indexed

    @classmethod
    def _rw_conflicts(cls, writes: set[_RwKey], reads: set[_RwKey]) -> bool:
        widx = cls._rw_index(writes)
        ridx = cls._rw_index(reads)
        for obj, (wwild, wkeys) in widx.items():
            if obj not in ridx:
                continue
            rwild, rkeys = ridx[obj]
            if wwild or rwild:
                return True
            if wkeys.intersection(rkeys):
                return True
        return False

    def _build_node_rw(self, node: str) -> tuple[set[_RwKey], set[_RwKey]]:
        reads: set[_RwKey] = set()
        writes: set[_RwKey] = set()

        reads.add(_RwKey(obj=f"{node}_inbox_count"))
        writes.add(_RwKey(obj=f"{node}_inbox_count"))
        writes.add(_RwKey(obj=f"{node}_pkt_external"))

        for v in self._node_input_vars.get(node, []):
            reads.add(_RwKey(obj=f"{node}_{v}"))
            writes.add(_RwKey(obj=f"{node}_{v}"))

        meta_reads, meta_writes = self._parse_stateful_rw(node)
        reads.update(meta_reads)
        writes.update(meta_writes)

        nd = self._spec.nodes.get(node)
        if nd:
            for expr in list(nd.assume_exprs) + list(nd.assert_exprs):
                reads.update(self._collect_expr_reads(expr, current_node=node))
        for expr in list(self._spec.global_decl.assume_exprs) + list(self._spec.global_decl.assert_exprs):
            reads.update(self._collect_expr_reads(expr, current_node=node))

        for name in self._dsl_global_vars.keys():
            key = _RwKey(obj=f"dsl_{name}")
            reads.add(key)
            writes.add(key)

        for l in self._spec.links:
            if l.src != node:
                continue
            dst = l.dst
            writes.add(_RwKey(obj=f"{dst}_inbox_count"))
            writes.add(_RwKey(obj=f"{dst}_pkt_external"))
            src_decl = self._node_declared_vars.get(node, set())
            dst_decl = self._get_declared_vars(dst)
            for v in self._node_input_vars.get(node, []):
                if v in src_decl and v in dst_decl:
                    writes.add(_RwKey(obj=f"{dst}_{v}"))

        return reads, writes

    def _compute_por_guards(self, node_aliases: List[str]) -> Dict[str, List[str]]:
        guards: Dict[str, List[str]] = {n: [] for n in node_aliases}
        if len(node_aliases) < 2:
            return guards
        rw: Dict[str, tuple[set[_RwKey], set[_RwKey]]] = {}
        for n in node_aliases:
            rw[n] = self._build_node_rw(n)
        for i, node in enumerate(node_aliases):
            for j in range(i):
                other = node_aliases[j]
                r1, w1 = rw[node]
                r2, w2 = rw[other]
                conflict = self._rw_conflicts(w1, r2 | w2) or self._rw_conflicts(w2, r1 | w1)
                if not conflict:
                    guards[node].append(other)
        return guards

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

        node_aliases = list(self._spec.imports.keys())
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

            # DSL locals as globals
            if (
                self._dsl_global_vars
                or any(self._dsl_node_vars.get(a) for a in node_aliases)
                or any(self._dsl_host_vars.get(h) for h in host_aliases)
            ):
                lines.append("// DSL state variables (modeled as Boogie globals)\n")
                for name, typ in sorted(self._dsl_global_vars.items()):
                    lines.append(f"var dsl_{name}: {typ};\n")
                for n in node_aliases:
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

            # Single-slot mailbox classification: whether the currently-stored packet fields originated from Env injection.
            # This lets us avoid havoc'ing forwarded packets (otherwise forwarding copy is immediately overwritten).
            for a in node_aliases + host_aliases:
                lines.append(f"var {a}_pkt_external: bool;\n")
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

        # Note: we intentionally keep the sequential harness unbounded (Ultimate can reason about loops).
        # global.max_steps is ignored here; use it only in bounded/BMC workflows outside this backend.
        lines.append("var procurator_step: int;\n")
        if self._spec.global_decl.deterministic_scheduler is True:
            # Avoid integer modulo in the scheduler encoding (helps Ultimate on deep loops).
            lines.append("var procurator_phase: int;\n")
        lines.append("\n")

        # DSL locals as globals
        if (
            self._dsl_global_vars
            or any(self._dsl_node_vars.get(a) for a in node_aliases)
            or any(self._dsl_host_vars.get(h) for h in host_aliases)
        ):
            lines.append("// DSL state variables (modeled as Boogie globals)\n")
            for name, typ in sorted(self._dsl_global_vars.items()):
                lines.append(f"var dsl_{name}: {typ};\n")
            for n in node_aliases:
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

        # Single-slot mailbox classification: whether the currently-stored packet fields originated from Env injection.
        for a in node_aliases + host_aliases:
            lines.append(f"var {a}_pkt_external: bool;\n")
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

    def _emit_forward_proc(self, src: str, k: int) -> str:
        port_map: Dict[str, str] = {}
        wildcard_dst: Optional[str] = None
        for l in self._spec.links:
            if l.src != src:
                continue
            if l.port == "ALL":
                if wildcard_dst is not None and wildcard_dst != l.dst:
                    raise BoogieBackendError(f"Multiple ALL links for src={src}: {wildcard_dst} vs {l.dst}")
                wildcard_dst = l.dst
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
        dsts = sorted(set(port_map.values()) | ({wildcard_dst} if wildcard_dst else set()))
        modifies: List[str] = []
        emit_trace = self._emit_trace and self._harness_mode == "sequential"
        trace_types = self._trace_field_types(src) if emit_trace else {}
        for dst in dsts:
            modifies.append(f"{dst}_inbox_count")
            modifies.append(f"{dst}_pkt_external")
            # Enqueue preserves on-wire packet fields (headers only).
            src_decl = self._node_declared_vars.get(src, set())
            dst_decl = self._get_declared_vars(dst)
            for v in self._node_input_vars.get(src, []):
                if _is_on_wire_packet_var(v) and v in src_decl and v in dst_decl:
                    modifies.append(f"{dst}_{v}")
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

        if wildcard_dst is not None:
            out.append(f"  // wildcard forwarding (ALL)\n")
            out.append(f"  call {src}__enqueue_{wildcard_dst}();\n")
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

        out: List[str] = []
        out.append(f"procedure {src}__enqueue_{dst}() returns()\n")
        mod: List[str] = [f"{dst}_inbox_count", f"{dst}_pkt_external"]
        mod.extend(f"{dst}_{v}" for v in copy_vars)
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
        out.append(f"  assume {dst}_inbox_count < {k};\n")
        # Store the packet fields (single slot) and mark as forwarded
        for v in copy_vars:
            out.append(f"  {dst}_{v} := {src}_{v};\n")
        out.append(f"  {dst}_pkt_external := false;\n")
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
        return node in self._two_stage_nodes

    def _ingress_proc_name(self, node: str) -> str:
        return f"{node}__procurator_ingress"

    def _egress_proc_name(self, node: str) -> str:
        return f"{node}__procurator_egress"

    def _emit_env_thread(self, k: int) -> str:
        # Determine which nodes can receive external inputs.
        nodes = list(self._spec.imports.keys())
        marked = [n for n in nodes if self._spec.nodes.get(n, NodeDecl(name=n)).external_input is True]
        inject_targets = marked if marked else nodes  # compatibility fallback

        out: List[str] = []
        out.append("procedure EnvThread() returns()\n")
        env_modifies: set[str] = {f"{n}_inbox_count" for n in inject_targets} | {f"{n}_pkt_external" for n in inject_targets}
        # External injection havocs input vars.
        for n in inject_targets:
            for v in self._node_input_vars.get(n, []):
                env_modifies.add(f"{n}_{v}")
        env_modifies.add("procurator_lock")
        out.append(
            "  modifies "
            + ", ".join(sorted(env_modifies))
            + ";\n"
        )
        out.append("{\n")
        out.append("  while (true) {\n")
        out.append("    // Nondeterministically inject an external packet into one ingress node\n")
        for n in inject_targets:
            out.append("      if (*) {\n")
            out.append("        atomic {\n")
            out.append("          assume procurator_lock == 0;\n")
            out.append("          procurator_lock := 1;\n")
            out.append("        }\n")
            out.append(self._emit_external_enqueue_stmt(n, k, indent="        ", deterministic=False))
            out.append("        atomic {\n")
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
        out.append(f"{indent}// Schedule egress for the original packet.\n")
        out.append(f"{indent}assume {node}_egress_count < {k};\n")
        out.append(f"{indent}{node}_egress_count := {node}_egress_count + 1;\n")
        if "p4b_clone_i2e" in clone_flags:
            out.append(f"{indent}if ({node}_p4b_clone_i2e) {{\n")
            out.append(f"{indent}  assume {node}_egress_count < {k};\n")
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
        out.append(f"{indent}call {self._egress_proc_name(node)}();\n")
        if "p4b_clone_e2e" in clone_flags:
            out.append(f"{indent}if ({node}_p4b_clone_e2e) {{\n")
            out.append(f"{indent}  assume {node}_egress_count < {k};\n")
            out.append(f"{indent}  {node}_egress_count := {node}_egress_count + 1;\n")
            out.append(f"{indent}}}\n")
        if "p4b_recirculate" in clone_flags:
            out.append(f"{indent}if ({node}_p4b_recirculate) {{\n")
            out.append(self._emit_internal_enqueue_stmt(node, k, indent=indent + "  "))
            out.append(f"{indent}}}\n")
        if clone_flags:
            out.append(f"{indent}// Clear clone/recirculate flags after egress.\n")
            for flag in clone_flags:
                out.append(f"{indent}{node}_{flag} := false;\n")
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
        modifies_set.add(f"{node}_inbox_count")
        modifies_set.add(f"{node}_pkt_external")
        modifies_set.update(self._node_mainprocedure_modifies.get(node, set()))
        # Havoc writes to these globals, so they must be listed in modifies.
        modifies_set.update(f"{node}_{v}" for v in input_vars)
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
        for l in self._spec.links:
            if l.src == node:
                modifies_set.add(f"{l.dst}_inbox_count")
                modifies_set.add(f"{l.dst}_pkt_external")
                # enqueue copies packet fields
                dst_decl = self._get_declared_vars(l.dst)
                for v in self._node_input_vars.get(node, []):
                    if v in self._node_declared_vars.get(node, set()) and v in dst_decl:
                        modifies_set.add(f"{l.dst}_{v}")

        out: List[str] = []
        out.append(f"procedure {node}Thread() returns()\n")
        out.append("  modifies " + ", ".join(sorted(modifies_set)) + ";\n")
        out.append("{\n")
        out.append("  while (true) {\n")
        if not two_stage:
            out.append("    if (*) {\n")
            out.append("      atomic {\n")
            out.append("        assume procurator_lock == 0;\n")
            out.append(f"        assume {node}_inbox_count > 0;\n")
            if self._por_enabled and self._por_guard_enabled:
                guards = self._por_guards.get(node, [])
                if guards:
                    out.append("        // POR: prefer lower-id commuting nodes when they are ready.\n")
                    for other in guards:
                        out.append(f"        assume {other}_inbox_count == 0;\n")
            out.append("        procurator_lock := 1;\n")
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
            out.append("        procurator_lock := 0;\n")
            out.append("      }\n")
            out.append("    }\n")
        else:
            # Ingress stage
            out.append("    if (*) {\n")
            out.append("      atomic {\n")
            out.append("        assume procurator_lock == 0;\n")
            out.append(f"        assume {node}_inbox_count > 0;\n")
            if self._por_enabled and self._por_guard_enabled:
                guards = self._por_guards.get(node, [])
                if guards:
                    out.append("        // POR: prefer lower-id commuting nodes when they are ready.\n")
                    for other in guards:
                        out.append(f"        assume {other}_inbox_count == 0;\n")
            out.append("        procurator_lock := 1;\n")
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
            out.append("        procurator_lock := 0;\n")
            out.append("      }\n")
            out.append("    }\n")
            # Egress stage
            out.append("    if (*) {\n")
            out.append("      atomic {\n")
            out.append("        assume procurator_lock == 0;\n")
            out.append(f"        assume {node}_egress_count > 0;\n")
            out.append("        procurator_lock := 1;\n")
            out.append("      }\n")
            out.append(f"      {node}_egress_count := {node}_egress_count - 1;\n")
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
        start_modifies.update(f"{a}_inbox_count" for a in node_aliases + host_aliases)
        start_modifies.update(f"{a}_pkt_external" for a in node_aliases + host_aliases)
        for a in node_aliases:
            if self._is_two_stage_node(a):
                start_modifies.add(f"{a}_egress_count")
        # DSL locals are globals and may be initialized here.
        start_modifies.update(f"dsl_{name}" for name in self._dsl_global_vars.keys())
        for a in node_aliases:
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
        for h in host_aliases:
            start_modifies.update(f"{h}_{v}" for v in self._host_input_vars.get(h, []))
        for l in self._spec.links:
            # forwarding updates inbox counters
            start_modifies.add(f"{l.dst}_inbox_count")
            start_modifies.add(f"{l.dst}_pkt_external")
            # enqueue copies packet fields
            dst_decl = self._get_declared_vars(l.dst)
            for v in self._node_input_vars.get(l.src, []):
                if v in self._node_declared_vars.get(l.src, set()) and v in dst_decl:
                    start_modifies.add(f"{l.dst}_{v}")
        out.append("  modifies " + ", ".join(sorted(start_modifies)) + ";\n")
        out.append("{\n")
        out.append("  procurator_lock := 0;\n")
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
        for a in node_aliases:
            if self._is_two_stage_node(a):
                mods.add(f"{a}_egress_count")

        mods.update(f"dsl_{name}" for name in self._dsl_global_vars.keys())
        for a in node_aliases:
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
            mods.add(f"{l.dst}_inbox_count")
            mods.add(f"{l.dst}_pkt_external")
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

    @staticmethod
    def _register_debug_var_name(reg_name: str) -> str:
        return f"{reg_name}__dbg0"

    @staticmethod
    def _register_last_index_name(reg_name: str) -> str:
        return f"{reg_name}__last_index"

    @staticmethod
    def _register_last_value_name(reg_name: str) -> str:
        return f"{reg_name}__last_value"

    @staticmethod
    def _register_wrote_any_name(reg_name: str) -> str:
        return f"{reg_name}__wrote_any"

    @staticmethod
    def _register_wrote_index0_name(reg_name: str) -> str:
        return f"{reg_name}__wrote_index0"

    @staticmethod
    def _register_last0_value_name(reg_name: str) -> str:
        return f"{reg_name}__last0_value"

    @staticmethod
    def _register_last_index_dbg_name(reg_name: str) -> str:
        return f"{reg_name}__last_index__dbg"

    @staticmethod
    def _register_last_value_dbg_name(reg_name: str) -> str:
        return f"{reg_name}__last_value__dbg"

    @staticmethod
    def _register_wrote_any_dbg_name(reg_name: str) -> str:
        return f"{reg_name}__wrote_any__dbg"

    @staticmethod
    def _register_wrote_index0_dbg_name(reg_name: str) -> str:
        return f"{reg_name}__wrote_index0__dbg"

    @staticmethod
    def _register_last0_value_dbg_name(reg_name: str) -> str:
        return f"{reg_name}__last0_value__dbg"

    @staticmethod
    def _trace_node_exec_name(node: str) -> str:
        return f"trace_{node}_exec"

    @staticmethod
    def _trace_node_seq_name(node: str) -> str:
        return f"trace_{node}_seq"

    @staticmethod
    def _trace_node_op_name(node: str) -> str:
        return f"trace_{node}_op"

    @staticmethod
    def _trace_node_key_name(node: str) -> str:
        return f"trace_{node}_key"

    @staticmethod
    def _trace_reg_dbg0_name(reg_name: str) -> str:
        return f"trace_{reg_name}__dbg0"

    @staticmethod
    def _trace_reg_wrote_any_name(reg_name: str) -> str:
        return f"trace_{reg_name}__wrote_any"

    @staticmethod
    def _trace_reg_wrote_index0_name(reg_name: str) -> str:
        return f"trace_{reg_name}__wrote_index0"

    @staticmethod
    def _trace_reg_last0_value_name(reg_name: str) -> str:
        return f"trace_{reg_name}__last0_value"

    @staticmethod
    def _trace_enqueue_exec_name(src: str, dst: str) -> str:
        return f"trace_enq_{src}_{dst}_exec"

    @staticmethod
    def _trace_enqueue_seq_name(src: str, dst: str) -> str:
        return f"trace_enq_{src}_{dst}_seq"

    @staticmethod
    def _trace_enqueue_op_name(src: str, dst: str) -> str:
        return f"trace_enq_{src}_{dst}_op"

    @staticmethod
    def _trace_enqueue_key_name(src: str, dst: str) -> str:
        return f"trace_enq_{src}_{dst}_key"

    def _trace_field_types(self, node: str) -> Dict[str, str]:
        fields = {
            "seq": "hdr.nc_hdr.seq",
            "op": "hdr.nc_hdr.op",
            "key": "hdr.nc_hdr.key",
        }
        out: Dict[str, str] = {}
        for label, base in fields.items():
            width = self._infer_bv_width_for_node(node, base)
            if width is None:
                continue
            out[label] = f"bv{width}"
        return out

    def _emit_trace_decls(self, node_aliases: List[str]) -> str:
        out: List[str] = []
        if not self._emit_trace or not node_aliases:
            return ""
        out.append("var trace_node_id: [int]int;\n")
        out.append("var trace_stage: [int]int;\n")
        for node in node_aliases:
            out.append(f"var {self._trace_node_exec_name(node)}: [int]bool;\n")
            types = self._trace_field_types(node)
            if "seq" in types:
                out.append(f"var {self._trace_node_seq_name(node)}: [int]{types['seq']};\n")
            if "op" in types:
                out.append(f"var {self._trace_node_op_name(node)}: [int]{types['op']};\n")
            if "key" in types:
                out.append(f"var {self._trace_node_key_name(node)}: [int]{types['key']};\n")
        for regs in self._node_register_arrays.values():
            for name, (_, elem_type) in sorted(regs.items()):
                out.append(f"var {self._trace_reg_dbg0_name(name)}: [int]{elem_type};\n")
                out.append(f"var {self._trace_reg_wrote_any_name(name)}: [int]bool;\n")
                out.append(f"var {self._trace_reg_wrote_index0_name(name)}: [int]bool;\n")
                out.append(f"var {self._trace_reg_last0_value_name(name)}: [int]{elem_type};\n")
        for link in self._spec.links:
            types = self._trace_field_types(link.src)
            out.append(f"var {self._trace_enqueue_exec_name(link.src, link.dst)}: [int]bool;\n")
            if "seq" in types:
                out.append(f"var {self._trace_enqueue_seq_name(link.src, link.dst)}: [int]{types['seq']};\n")
            if "op" in types:
                out.append(f"var {self._trace_enqueue_op_name(link.src, link.dst)}: [int]{types['op']};\n")
            if "key" in types:
                out.append(f"var {self._trace_enqueue_key_name(link.src, link.dst)}: [int]{types['key']};\n")
        return "".join(out)

    def _emit_trace_step_reset(self, node_aliases: List[str], *, indent: str) -> str:
        if not self._emit_trace or not node_aliases:
            return ""
        out: List[str] = []
        out.append(f"{indent}trace_node_id[procurator_step] := 0;\n")
        out.append(f"{indent}trace_stage[procurator_step] := 0;\n")
        for node in node_aliases:
            out.append(f"{indent}{self._trace_node_exec_name(node)}[procurator_step] := false;\n")
        for link in self._spec.links:
            out.append(
                f"{indent}{self._trace_enqueue_exec_name(link.src, link.dst)}[procurator_step] := false;\n"
            )
        return "".join(out)

    def _emit_trace_assignments(self, node: str, *, indent: str, stage_id: int) -> str:
        if not self._emit_trace or self._harness_mode != "sequential":
            return ""
        if not node:
            return ""
        out: List[str] = []
        node_id = getattr(self, "_trace_node_ids", {}).get(node, 0)
        out.append(f"{indent}trace_node_id[procurator_step] := {node_id};\n")
        out.append(f"{indent}trace_stage[procurator_step] := {stage_id};\n")
        out.append(f"{indent}{self._trace_node_exec_name(node)}[procurator_step] := true;\n")
        types = self._trace_field_types(node)
        if "seq" in types:
            out.append(f"{indent}{self._trace_node_seq_name(node)}[procurator_step] := {node}_hdr.nc_hdr.seq;\n")
        if "op" in types:
            out.append(f"{indent}{self._trace_node_op_name(node)}[procurator_step] := {node}_hdr.nc_hdr.op;\n")
        if "key" in types:
            out.append(f"{indent}{self._trace_node_key_name(node)}[procurator_step] := {node}_hdr.nc_hdr.key;\n")
        regs = self._node_register_arrays.get(node, {})
        for name in sorted(regs.keys()):
            out.append(
                f"{indent}{self._trace_reg_dbg0_name(name)}[procurator_step] := {self._register_debug_var_name(name)};\n"
            )
            out.append(
                f"{indent}{self._trace_reg_wrote_any_name(name)}[procurator_step] := {self._register_wrote_any_name(name)};\n"
            )
            out.append(
                f"{indent}{self._trace_reg_wrote_index0_name(name)}[procurator_step] := {self._register_wrote_index0_name(name)};\n"
            )
            out.append(
                f"{indent}{self._trace_reg_last0_value_name(name)}[procurator_step] := {self._register_last0_value_name(name)};\n"
            )
        return "".join(out)

    def _render_index_zero(self, idx_type: str) -> str:
        idx_type = idx_type.strip()
        if idx_type.startswith("bv") and idx_type[2:].isdigit():
            return f"0{idx_type}"
        return "0"

    def _render_value_zero(self, elem_type: str) -> str:
        elem_type = elem_type.strip()
        if elem_type == "bool":
            return "false"
        if elem_type.startswith("bv") and elem_type[2:].isdigit():
            return f"0{elem_type}"
        return "0"

    def _render_typed_int(self, typ: str, value: int) -> str:
        typ = typ.strip()
        if typ == "bool":
            return "false" if int(value) == 0 else "true"
        if typ.startswith("bv") and typ[2:].isdigit():
            width = int(typ[2:])
            if width > 0:
                value = int(value) % (1 << width)
            return f"{int(value)}{typ}"
        return str(int(value))

    def _render_typed_literal_from_str(self, typ: str, raw: str) -> Optional[str]:
        raw = str(raw).strip()
        if raw == "":
            return None
        if typ.strip() == "bool":
            low = raw.lower()
            if low in {"false", "0"}:
                return "false"
            if low in {"true", "1"}:
                return "true"
            try:
                return "false" if int(raw) == 0 else "true"
            except Exception:
                return None
        try:
            return self._render_typed_int(typ, int(raw))
        except Exception:
            return None

    def _emit_register_debug_decls(self, node_aliases: List[str]) -> str:
        out: List[str] = []
        for node in node_aliases:
            regs = self._node_register_arrays.get(node, {})
            for name, (idx_type, elem_type) in sorted(regs.items()):
                if elem_type == "Ref" or elem_type.endswith("Ref"):
                    continue
                dbg = self._register_debug_var_name(name)
                out.append(f"var {dbg}: {elem_type};\n")
                out.append(f"var {self._register_last_index_dbg_name(name)}: {idx_type};\n")
                out.append(f"var {self._register_last_value_dbg_name(name)}: {elem_type};\n")
                out.append(f"var {self._register_wrote_any_dbg_name(name)}: bool;\n")
                out.append(f"var {self._register_wrote_index0_dbg_name(name)}: bool;\n")
                out.append(f"var {self._register_last0_value_dbg_name(name)}: {elem_type};\n")
        return "".join(out)

    def _emit_register_debug_assignments(self, *, indent: str) -> str:
        out: List[str] = []
        for regs in self._node_register_arrays.values():
            for name, (idx_type, elem_type) in sorted(regs.items()):
                if elem_type == "Ref" or elem_type.endswith("Ref"):
                    continue
                dbg = self._register_debug_var_name(name)
                idx_zero = self._render_index_zero(idx_type)
                out.append(f"{indent}{dbg} := {name}[{idx_zero}];\n")
                out.append(f"{indent}{self._register_last_index_dbg_name(name)} := {self._register_last_index_name(name)};\n")
                out.append(f"{indent}{self._register_last_value_dbg_name(name)} := {self._register_last_value_name(name)};\n")
                out.append(f"{indent}{self._register_wrote_any_dbg_name(name)} := {self._register_wrote_any_name(name)};\n")
                out.append(f"{indent}{self._register_wrote_index0_dbg_name(name)} := {self._register_wrote_index0_name(name)};\n")
                out.append(f"{indent}{self._register_last0_value_dbg_name(name)} := {self._register_last0_value_name(name)};\n")
        return "".join(out)

    def _emit_register_write_debug_init(self, node_aliases: List[str]) -> str:
        out: List[str] = []
        for node in node_aliases:
            regs = self._node_register_arrays.get(node, {})
            for name, (idx_type, elem_type) in sorted(regs.items()):
                idx_zero = self._render_index_zero(idx_type)
                val_zero = self._render_value_zero(elem_type)
                out.append(f"  {self._register_last_index_name(name)} := {idx_zero};\n")
                out.append(f"  {self._register_last_value_name(name)} := {val_zero};\n")
                out.append(f"  {self._register_wrote_any_name(name)} := false;\n")
                out.append(f"  {self._register_wrote_index0_name(name)} := false;\n")
                out.append(f"  {self._register_last0_value_name(name)} := {val_zero};\n")
        return "".join(out)

    def _emit_assert_lines(self, exprs: Sequence[Tree], *, indent: str, current_node: str) -> str:
        out: List[str] = []
        for expr in exprs:
            bpl = self._expr_to_boogie(expr, current_node=current_node, prefer_reg_dbg=True)
            out.append(f"{indent}assert {bpl};\n")
        return "".join(out)

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
        mods = self._compute_harness_modifies(node_aliases, host_aliases, include_lock=False)
        mods.add("procurator_step")
        if deterministic:
            mods.add("procurator_phase")

        actions: List[tuple[str, str]] = []
        if env_thread_enabled:
            nodes = list(self._spec.imports.keys())
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

        out.append("procedure main() returns()\n")
        if mods:
            out.append("  modifies " + ", ".join(sorted(mods)) + ";\n")
        out.append("{\n")
        out.append("  // One scheduler step: pick exactly one action.\n")
        if self._spec.global_decl.deterministic_scheduler is True:
            out.append("  // Scheduler: deterministic round-robin over the action list.\n")

        indent = "    "
        trace_reset = self._emit_trace_step_reset(node_aliases, indent=indent)
        if trace_reset:
            out.append(f"{indent}// Reset trace flags for this step.\n")
            out.append(trace_reset)

        period = len(actions) if actions else 0
        for i, (kind, name) in enumerate(actions):
            if deterministic:
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
                out.append(self._emit_sequential_host_send_step(name, k=k, indent=indent, deterministic=deterministic))
            elif kind == "host_recv":
                out.append(f"{indent}// host recv -> {name}\n")
                out.append(self._emit_sequential_host_recv_step(name, indent=indent, deterministic=deterministic))
            elif kind == "node_pass":
                out.append(f"{indent}// node pass -> {name}\n")
                out.append(self._emit_sequential_node_pass_step(name, k=k, indent=indent, deterministic=deterministic))
            elif kind == "node_ingress":
                out.append(f"{indent}// node ingress -> {name}\n")
                out.append(self._emit_sequential_node_ingress_step(name, k=k, indent=indent, deterministic=deterministic))
            elif kind == "node_egress":
                out.append(f"{indent}// node egress -> {name}\n")
                out.append(self._emit_sequential_node_egress_step(name, k=k, indent=indent, deterministic=deterministic))
            else:
                raise AssertionError(f"unhandled sequential action: {kind}")

        if actions:
            out.append("  } else {\n")
            if deterministic:
                out.append(f"{indent}assume false;\n")
            else:
                out.append(f"{indent}// idle\n")
            out.append("  }\n")

        if deterministic:
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
        if deterministic:
            out.append("  procurator_phase := 0;\n")
        out.append("  while (true) {\n")
        out.append("    call main();\n")
        out.append("    procurator_step := procurator_step + 1;\n")
        out.append("  }\n")
        out.append("}\n")

        return "".join(out)

    def _emit_sequential_start(
        self,
        node_aliases: List[str],
        host_aliases: List[str],
    ) -> str:
        # Keep ULTIMATE.start as entry for existing scripts/toolchains; the real init happens in mainProcedure.
        mods = self._compute_harness_modifies(node_aliases, host_aliases, include_lock=False)
        mods.add("procurator_step")
        if self._spec.global_decl.deterministic_scheduler is True:
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
        target = self._host_to_node.get(host)
        if not target:
            return f"{indent}assume false;\n"

        host_vars = self._host_input_vars.get(host, [])
        host_decl = self._host_declared_vars.get(host, set())
        target_decl = self._node_declared_vars.get(target, set())
        copy_vars: List[str] = [v for v in host_vars if v in host_decl and v in target_decl]

        out: List[str] = []
        if deterministic:
            inner = indent + "  "
            out.append(f"{indent}if ({target}_inbox_count < {k}) {{\n")
            # Create a fresh packet for this host send.
            for v in host_vars:
                out.append(f"{inner}havoc {host}_{v};\n")
            if not self._max_env_inputs:
                env_lines = self._emit_host_env_inject_statements(host, indent=inner)
                if env_lines:
                    out.append(env_lines)
                hd = self._spec.hosts.get(host, HostDecl(name=host))
                for expr in hd.assume_exprs:
                    out.append(f"{inner}assume {self._expr_to_boogie(expr, current_node=host)};\n")
                for expr in self._spec.global_decl.assume_exprs:
                    out.append(f"{inner}assume {self._expr_to_boogie(expr, current_node=host)};\n")
            for v in copy_vars:
                out.append(f"{inner}{target}_{v} := {host}_{v};\n")
            out.append(f"{inner}{target}_pkt_external := true;\n")
            out.append(f"{inner}{target}_inbox_count := {target}_inbox_count + 1;\n")
            out.append(f"{indent}}}\n")
            return "".join(out)

        out.append(f"{indent}assume {target}_inbox_count < {k};\n")
        # Create a fresh packet for this host send.
        for v in host_vars:
            out.append(f"{indent}havoc {host}_{v};\n")
        if not self._max_env_inputs:
            env_lines = self._emit_host_env_inject_statements(host, indent=indent)
            if env_lines:
                out.append(env_lines)
            hd = self._spec.hosts.get(host, HostDecl(name=host))
            for expr in hd.assume_exprs:
                out.append(f"{indent}assume {self._expr_to_boogie(expr, current_node=host)};\n")
            for expr in self._spec.global_decl.assume_exprs:
                out.append(f"{indent}assume {self._expr_to_boogie(expr, current_node=host)};\n")
        for v in copy_vars:
            out.append(f"{indent}{target}_{v} := {host}_{v};\n")
        out.append(f"{indent}{target}_pkt_external := true;\n")
        out.append(f"{indent}{target}_inbox_count := {target}_inbox_count + 1;\n")
        return "".join(out)

    def _emit_sequential_host_recv_step(self, host: str, *, indent: str, deterministic: bool) -> str:
        out: List[str] = []
        hd = self._spec.hosts.get(host, HostDecl(name=host))
        if deterministic:
            inner = indent + "  "
            out.append(f"{indent}if ({host}_inbox_count > 0) {{\n")
            out.append(self._emit_assert_lines(hd.assert_exprs, indent=inner, current_node=host))
            out.append(f"{inner}{host}_inbox_count := {host}_inbox_count - 1;\n")
            out.append(f"{indent}}}\n")
            return "".join(out)

        out.append(f"{indent}assume {host}_inbox_count > 0;\n")
        out.append(self._emit_assert_lines(hd.assert_exprs, indent=indent, current_node=host))
        out.append(f"{indent}{host}_inbox_count := {host}_inbox_count - 1;\n")
        return "".join(out)

    def _emit_sequential_node_pass_step(self, node: str, *, k: int, indent: str, deterministic: bool) -> str:
        input_vars = self._node_input_vars.get(node, [])

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

        dsl_stmt_lines = self._emit_node_pass_statements(node, indent=indent)

        declared = self._node_declared_vars.get(node, set())
        clone_flags = []
        for flag in ("p4b_clone_i2e", "p4b_clone_e2e", "p4b_clone_i2i", "p4b_recirculate"):
            if flag in declared:
                clone_flags.append(flag)

        out: List[str] = []
        if deterministic:
            out.append(f"{indent}if ({node}_inbox_count > 0) {{\n")
        out.append(f"{indent}assume {node}_inbox_count > 0;\n")
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
        if clone_flags:
            out.append(f"{indent}// Handle clone/recirculate flags emitted by P4B extern modeling.\n")
            if "p4b_clone_i2e" in clone_flags:
                out.append(f"{indent}if ({node}_p4b_clone_i2e) {{\n")
                out.append(f"{indent}  call {node}_Forward();\n")
                out.append(f"{indent}}}\n")
            if "p4b_clone_e2e" in clone_flags:
                out.append(f"{indent}if ({node}_p4b_clone_e2e) {{\n")
                out.append(f"{indent}  call {node}_Forward();\n")
                out.append(f"{indent}}}\n")
            if "p4b_clone_i2i" in clone_flags:
                out.append(f"{indent}if ({node}_p4b_clone_i2i) {{\n")
                out.append(self._emit_internal_enqueue_stmt(node, k, indent=indent + "  "))
                out.append(f"{indent}}}\n")
            if "p4b_recirculate" in clone_flags:
                out.append(f"{indent}if ({node}_p4b_recirculate) {{\n")
                out.append(self._emit_internal_enqueue_stmt(node, k, indent=indent + "  "))
                out.append(f"{indent}}}\n")
            for flag in clone_flags:
                out.append(f"{indent}{node}_{flag} := false;\n")
        out.append(f"{indent}call {node}_Forward();\n")
        trace_lines = self._emit_trace_assignments(node, indent=indent, stage_id=3)
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
        if deterministic:
            out.append(f"{indent}}}\n")
        return "".join(out)

    def _emit_sequential_node_ingress_step(self, node: str, *, k: int, indent: str, deterministic: bool) -> str:
        dsl_stmt_lines = self._emit_node_pass_statements(node, indent=indent)
        declared = self._node_declared_vars.get(node, set())
        clone_flags = [f for f in ("p4b_clone_i2e", "p4b_clone_e2e", "p4b_clone_i2i", "p4b_recirculate") if f in declared]

        out: List[str] = []
        if deterministic:
            out.append(f"{indent}if ({node}_inbox_count > 0) {{\n")
        out.append(f"{indent}assume {node}_inbox_count > 0;\n")
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
        clone_flags = [f for f in ("p4b_clone_i2e", "p4b_clone_e2e", "p4b_clone_i2i", "p4b_recirculate") if f in declared]

        out: List[str] = []
        if deterministic:
            out.append(f"{indent}if ({node}_egress_count > 0) {{\n")
        out.append(f"{indent}assume {node}_egress_count > 0;\n")
        out.append(f"{indent}{node}_egress_count := {node}_egress_count - 1;\n")
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
        out.append(f"{indent}{dst}_inbox_count := {dst}_inbox_count + 1;\n")
        if deterministic:
            out.append(f"{indent}}}\n")
        return "".join(out)

    def _emit_internal_enqueue_stmt(self, dst: str, k: int, indent: str) -> str:
        out: List[str] = []
        # Internal enqueue (recirculate/i2i): keep current packet fields intact.
        out.append(f"{indent}assume {dst}_inbox_count < {k};\n")
        out.append(f"{indent}{dst}_pkt_external := false;\n")
        out.append(f"{indent}{dst}_inbox_count := {dst}_inbox_count + 1;\n")
        return "".join(out)

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
        if "[" not in name or not name.endswith("]"):
            return None
        base, idx = name.split("[", 1)
        idx = idx.rstrip("]")
        idx_norm = idx.strip()
        if idx_norm not in {"0", "0bv32", "0bv16"}:
            return None
        for regs in self._node_register_arrays.values():
            for reg_name in regs.keys():
                if base == reg_name:
                    return self._register_debug_var_name(reg_name)
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

        # per-node: initialize node DSL locals from var_decl only (assignments are per-pass)
        for node in node_aliases:
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
        declared_raw = self._node_declared_vars.get(node, set())

        def _normalize_ref(name: str) -> str:
            if name.startswith(f"{node}_"):
                return name[len(node) + 1 :]
            return name

        def _ref_is_available(name: str) -> bool:
            if _dsl_is_simple_local_name(name) and name in self._dsl_node_vars.get(node, {}):
                return True
            if _dsl_is_simple_local_name(name) and name in self._dsl_global_vars:
                return True
            raw = _normalize_ref(name)
            return raw in declared_raw

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
        declared_raw = self._host_declared_vars.get(host, set())
        target = self._host_to_node.get(host, "")

        def _normalize_ref(name: str) -> str:
            if target and name.startswith(f"{target}_"):
                return name[len(target) + 1 :]
            return name

        def _ref_is_available(name: str) -> bool:
            if _dsl_is_simple_local_name(name) and name in self._dsl_host_vars.get(host, {}):
                return True
            if _dsl_is_simple_local_name(name) and name in self._dsl_global_vars:
                return True
            raw = _normalize_ref(name)
            return raw in declared_raw

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
            # Array types like "[bv32]bv16" (register arrays)
            m = re.fullmatch(r"\[bv\d+\]bv(\d+)", vt)
            if m:
                try:
                    return int(m.group(1))
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
        return None


__all__ = ['BoogieHarnessEmitter']
