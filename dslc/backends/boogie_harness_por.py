from __future__ import annotations

import re
from typing import Dict, List, Optional

from lark import Tree

from .boogie_harness_types import _RwKey


class BoogieHarnessPorMixin:
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
            if not self._is_sink_node(dst):
                writes.add(_RwKey(obj=f"{dst}_inbox_count"))
                writes.add(_RwKey(obj=f"{dst}_pkt_external"))
            else:
                for v in self._collect_dsl_modified_boogie_vars(dst):
                    writes.add(_RwKey(obj=v))
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
