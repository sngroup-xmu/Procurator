from __future__ import annotations

import os
import re
import json
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

from lark import Tree

from ..speclang.model import HostDecl, LinkDecl, NodeDecl, SpecModel


class BoogieBackendError(RuntimeError):
    pass


class P4BTranslatorError(RuntimeError):
    pass


class P4BTranslator:
    """
    Wrapper for a P4->Boogie translator (e.g., external P4B-Translator).

    IMPORTANT: The translator invoked here MUST output Boogie (.bpl), not Promela (.pml).
    """

    def __init__(self, p4b_bin: str, *, include_paths: Optional[Sequence[str]] = None):
        self._p4b_bin = p4b_bin
        self._include_paths = _default_p4c_include_paths(p4b_bin) if include_paths is None else list(include_paths)

    def compile_to_bpl(
        self,
        p4_path: str,
        out_bpl: str,
        entries_path: Optional[str],
        out_meta: Optional[str] = None,
        slicing_vars: Optional[Sequence[str]] = None,
        disable_slicing: bool = False,
    ) -> None:
        def run(cmd: List[str]) -> None:
            try:
                subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            except FileNotFoundError as e:
                raise P4BTranslatorError(f"translator binary not found: {self._p4b_bin}") from e
            except subprocess.CalledProcessError as e:
                raise P4BTranslatorError(
                    "translation failed:\n"
                    f"cmd: {' '.join(cmd)}\n"
                    f"exit: {e.returncode}\n"
                    f"out:\n{e.stdout}"
                ) from e

        def build_cmd(*, use_goto: bool) -> List[str]:
            # NOTE: p4c-style compilers require -I paths to appear before the input file.
            cmd: List[str] = [self._p4b_bin]
            for inc in self._include_paths:
                cmd.extend(["-I", inc])
            # Prefer goto-based control flow (avoids if/else chains that interact poorly with Ultimate's atomic analysis).
            if use_goto:
                cmd.extend(["--goto"])
            if disable_slicing:
                cmd.append("--no-slicing")
            if p4_path.endswith(".json"):
                cmd.extend(["--fromJSON", p4_path])
            else:
                cmd.append(p4_path)
            cmd.extend(["-o", out_bpl])
            if out_meta:
                cmd.extend(["--meta-out", out_meta])
            if entries_path:
                cmd.extend(["--bmv2cmds", entries_path])
            if slicing_vars and not disable_slicing:
                cmd.append("--slicing-vars=" + ",".join(slicing_vars))
            return cmd

        cmd = build_cmd(use_goto=True)
        run(cmd)


def _default_p4c_include_paths(p4b_bin: str) -> List[str]:
    """
    Determine a best-effort list of include directories for p4c-style preprocessors.

    Why this exists:
      - A repo-local (build-host) `p4c-translator` does not have a baked-in include search path,
        so `#include <core.p4>` / `<v1model.p4>` fails unless `-I <...>/p4include` is provided.
      - The docker wrapper has /mnt mounted, so using the repo's p4include also works there.

    Sources (in priority order):
      1) $P4C_INCLUDE_PATH (split by os.pathsep)
      2) Auto-detect a `p4include/` directory by walking up from the p4b_bin path.
    """
    out: List[str] = []

    env = os.getenv("P4C_INCLUDE_PATH", "")
    if env:
        for p in env.split(os.pathsep):
            p = p.strip()
            if not p:
                continue
            if Path(p).is_dir():
                out.append(str(Path(p)))

    # Auto-detect <repo>/p4include when p4b_bin points into a P4B-Translator checkout.
    bin_path = Path(p4b_bin).expanduser().resolve()
    for parent in [bin_path.parent, *bin_path.parents]:
        cand = parent / "p4include"
        if cand.is_dir():
            out.append(str(cand))
            break

    # De-dup, stable order
    seen = set()
    dedup: List[str] = []
    for p in out:
        if p not in seen:
            seen.add(p)
            dedup.append(p)
    return dedup


class BoogiePrefixer:
    """
    Prefix all declared Boogie symbols in a single .bpl unit with `prefix_...`.
    Pragmatic regex-based prefixer tailored for P4->Boogie outputs.
    """

    _IDENT_CHARS = r"A-Za-z0-9_\.\$"
    _IDENT_RE = re.compile(r"\b[A-Za-z_][A-Za-z0-9_\.\$]*\b")
    _BV_TYPE_RE = re.compile(r"^bv\d+$")
    _TYPE_RE = re.compile(r"^\s*type\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*(?:=|;)", re.MULTILINE)
    _VAR_RE = re.compile(r"^\s*var\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*:", re.MULTILINE)
    _CONST_RE = re.compile(r"^\s*const(?:\s+unique)?\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*:", re.MULTILINE)
    _PROC_RE = re.compile(
        r"^\s*procedure(?:\s*\{:[^}]+\}\s*)*\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*(?:\(|;)",
        re.MULTILINE,
    )
    _FUNC_RE = re.compile(
        r"^\s*function(?:\s*\{:[^}]+\}\s*)*\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*\(",
        re.MULTILINE,
    )

    def __init__(self, prefix: str):
        if not prefix or not re.fullmatch(r"[A-Za-z0-9_]+", prefix):
            raise ValueError(f"Invalid prefix '{prefix}'; expected [A-Za-z0-9_]+")
        self._prefix = prefix

    def prefix_content(self, bpl: str) -> str:
        names = self._collect_names(bpl)
        if not names:
            return bpl
        sorted_names = sorted(names, key=len, reverse=True)
        out = bpl
        for name in sorted_names:
            out = self._replace_ident(out, name, f"{self._prefix}_{name}")
        return _normalize_bvbuiltin_attrs(out, self._prefix)

    def _collect_names(self, bpl: str) -> List[str]:
        names: List[str] = []
        for rx in (self._TYPE_RE, self._VAR_RE, self._CONST_RE, self._PROC_RE):
            names.extend(m.group("name") for m in rx.finditer(bpl))
        for m in self._FUNC_RE.finditer(bpl):
            # Avoid prefixing Boogie bitvector builtins (keeps shared names like sub.bv32).
            decl = m.group(0)
            if "{:bvbuiltin" in decl:
                continue
            names.append(m.group("name"))
        names.extend(self._collect_referenced_names(bpl))
        seen = set()
        deduped: List[str] = []
        for n in names:
            if n not in seen:
                seen.add(n)
                deduped.append(n)
        return deduped

    def _collect_referenced_names(self, bpl: str) -> List[str]:
        bvbuiltins = {m.group("name") for m in _BVB_BUILTIN_DECL_RE.finditer(bpl)}
        names: List[str] = []
        for m in self._IDENT_RE.finditer(bpl):
            name = m.group(0)
            if name in _BOOGIE_KEYWORDS:
                continue
            if name in bvbuiltins:
                continue
            if self._BV_TYPE_RE.match(name):
                continue
            names.append(name)
        return names

    def _replace_ident(self, text: str, old: str, new: str) -> str:
        boundary = f"(?<![{self._IDENT_CHARS}]){re.escape(old)}(?![{self._IDENT_CHARS}])"
        return re.sub(boundary, new, text)


_BVB_BUILTIN_DECL_RE = re.compile(
    r'^\s*function\s*\{:\s*bvbuiltin\s+"[^"]+"\}\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*\([^;]*\);\s*$',
    re.MULTILINE,
)

_BVB_BUILTIN_ATTR_RE = re.compile(
    r'\{:\s*[A-Za-z0-9_]*bvbuiltin\s+"(?P<name>[A-Za-z0-9_]+)"\}'
)

_BOOGIE_KEYWORDS = {
    "assert",
    "assume",
    "axiom",
    "bool",
    "break",
    "call",
    "const",
    "else",
    "ensures",
    "exists",
    "false",
    "forall",
    "free",
    "function",
    "goto",
    "havoc",
    "if",
    "implementation",
    "int",
    "lambda",
    "modifies",
    "old",
    "par",
    "procedure",
    "returns",
    "return",
    "requires",
    "true",
    "type",
    "unique",
    "var",
    "while",
    "bvbuiltin",
}


def _normalize_bvbuiltin_attrs(bpl: str, prefix: str) -> str:
    """
    Undo accidental prefixing of {:bvbuiltin "..."} attributes.
    """
    def repl(match: re.Match[str]) -> str:
        name = match.group("name")
        if name.startswith(prefix + "_"):
            name = name[len(prefix) + 1 :]
        return f'{{:bvbuiltin "{name}"}}'
    return _BVB_BUILTIN_ATTR_RE.sub(repl, bpl)


def _dedup_bvbuiltin_decls(bpl: str, seen: set[str]) -> str:
    """
    Remove duplicate {:bvbuiltin} function declarations across merged nodes.
    """
    out: List[str] = []
    for line in bpl.splitlines(True):
        m = _BVB_BUILTIN_DECL_RE.match(line)
        if m:
            name = m.group("name")
            if name in seen:
                continue
            seen.add(name)
        out.append(line)
    return "".join(out)

@dataclass(frozen=True)
class _BoogieNodeInfo:
    raw_bpl: str
    input_vars: List[str]
    egress_port_type: str
    egress_port_var: str
    declared_vars: set[str]
    var_types: Dict[str, str]
    type_defs: Dict[str, str]
    meta: Optional[dict]


def _looks_like_bpl(text: str) -> bool:
    # Very cheap heuristic to detect "definitely not Boogie".
    if re.search(r"\bproctype\b", text):
        return False
    if re.search(r"^\s*procedure\b", text, re.MULTILINE):
        return True
    if re.search(r"^\s*var\b", text, re.MULTILINE):
        return True
    return False




def _collect_input_vars_and_egress_type(
    raw_bpl: str,
) -> Tuple[List[str], str, set[str], Dict[str, str], str, Dict[str, str]]:
    """
    Extract:
      (a) a conservative list of input packet/metadata vars to havoc each pass,
      (b) the type of standard_metadata.egress_port for forwarding decisions,
      (c) declared variables (raw names, for best-effort checks).
    """
    input_vars: List[str] = []
    egress_type: str = ""
    egress_var: str = ""
    declared_vars: set[str] = set()
    var_types: Dict[str, str] = {}
    type_defs: Dict[str, str] = {}

    type_def_re = re.compile(r"^\s*type\s+([A-Za-z0-9_\.\$]+)\s*=\s*([^;]+);\s*$", re.MULTILINE)
    for m in type_def_re.finditer(raw_bpl):
        type_defs[m.group(1)] = m.group(2).strip()

    var_decl_re = re.compile(r"^\s*var\s+([A-Za-z0-9_\.\$]+)\s*:\s*([^;]+);\s*$", re.MULTILINE)
    skip_inputs = {
        "standard_metadata.egress_port",
        "ig_intr_tm_md.ucast_egress_port",
        "ig_tm_md.ucast_egress_port",
        "eg_intr_md.egress_port",
    }
    for m in var_decl_re.finditer(raw_bpl):
        name = m.group(1)
        typ = m.group(2).strip()
        declared_vars.add(name)
        var_types[name] = typ
        if name == "standard_metadata.egress_port":
            egress_type = typ
            egress_var = name
        if not egress_var and (name.endswith(".ucast_egress_port") or name.endswith(".egress_port")):
            egress_type = typ
            egress_var = name
        if name.startswith(("hdr.", "meta.", "standard_metadata.")) or "_md." in name:
            if typ == "Ref" or typ.endswith("Ref"):
                continue
            if name in skip_inputs or name.endswith(".ucast_egress_port") or name.endswith(".egress_port"):
                continue
            input_vars.append(name)

    seen = set()
    dedup: List[str] = []
    for v in input_vars:
        if v not in seen:
            seen.add(v)
            dedup.append(v)
    return dedup, egress_type, declared_vars, var_types, egress_var, type_defs


def _is_packet_var(name: str) -> bool:
    return name.startswith(("hdr.", "meta.", "standard_metadata.")) or "_md." in name


def _filter_input_vars_by_usage(raw_bpl: str, input_vars: Sequence[str]) -> List[str]:
    # Drop vars that only appear in declarations; this keeps env inputs aligned with the sliced program.
    stripped = re.sub(r"^\s*var\s+[^;]+;\s*$", "", raw_bpl, flags=re.MULTILINE)
    kept: List[str] = []
    for v in input_vars:
        pat = r"\b" + re.escape(v) + r"\b"
        if re.search(pat, stripped):
            kept.append(v)
    return kept


def _extract_mainprocedure_modifies(prefixed_bpl: str, alias: str) -> set[str]:
    proc_name = f"{alias}_mainProcedure"
    rx = re.compile(
        rf"procedure(?:\s*\{{:[^}}]+\}}\s*)*\s+{re.escape(proc_name)}\s*\([^)]*\)\s*(?:returns\s*\([^)]*\))?\s*"
        rf"(?:\n|\r\n)\s*modifies\s+([^;]+);",
        re.MULTILINE,
    )
    m = rx.search(prefixed_bpl)
    if not m:
        return set()
    clause = m.group(1)
    items = [x.strip() for x in clause.split(",")]
    return {x for x in items if x}


class BoogieHarnessEmitter:
    """
    Emit a concurrent Boogie harness for Ultimate/GemCutter based on:
      - pass-atomic semantics
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
        node_var_types: Optional[Dict[str, Dict[str, str]]] = None,
        node_type_defs: Optional[Dict[str, Dict[str, str]]] = None,
        node_meta: Optional[Dict[str, Optional[dict]]] = None,
        host_to_node: Optional[Dict[str, str]] = None,
        host_input_vars: Optional[Dict[str, List[str]]] = None,
        host_var_types: Optional[Dict[str, Dict[str, str]]] = None,
        *,
        max_env_inputs: bool = False,
    ):
        self._spec = spec
        self._node_input_vars = node_input_vars  # alias -> raw var names (no prefix)
        self._node_egress_port_type = node_egress_port_type  # alias -> raw type string
        self._node_egress_port_var = node_egress_port_var  # alias -> raw var name
        self._node_declared_vars = node_declared_vars  # alias -> set(raw var name)
        self._node_mainprocedure_modifies = node_mainprocedure_modifies  # alias -> set(prefixed var name)
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
        self._tofino_recirculate_ports = self._infer_tofino_recirculate_ports()

    def _infer_tofino_recirculate_ports(self) -> List[int]:
        ports: set[int] = set()
        for imp in self._spec.imports.values():
            path = imp.path.lower()
            if path.endswith(".json") or "tofino" in path or "/gecko/" in path:
                ports.update({68, 196})
                break
        return sorted(ports)

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
        lines: List[str] = []
        lines.append("// Auto-generated by Procurator (DSL -> Boogie harness for GemCutter)\n")
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

        # Inbox counters
        for a in node_aliases + host_aliases:
            lines.append(f"var {a}_inbox_count: int;\n")
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
        for dst in dsts:
            modifies.append(f"{dst}_inbox_count")
            modifies.append(f"{dst}_pkt_external")
            # enqueue copies packet fields (best-effort intersection on declared vars)
            src_decl = self._node_declared_vars.get(src, set())
            dst_decl = self._get_declared_vars(dst)
            for v in self._node_input_vars.get(src, []):
                if v in src_decl and v in dst_decl:
                    modifies.append(f"{dst}_{v}")
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
        # We only copy variables that are declared in both nodes (best-effort).
        src_decl = self._node_declared_vars.get(src, set())
        dst_decl = self._get_declared_vars(dst)
        copy_vars: List[str] = []
        for v in self._node_input_vars.get(src, []):
            if v in src_decl and v in dst_decl:
                copy_vars.append(v)

        out: List[str] = []
        out.append(f"procedure {src}__enqueue_{dst}() returns()\n")
        mod: List[str] = [f"{dst}_inbox_count", f"{dst}_pkt_external"]
        mod.extend(f"{dst}_{v}" for v in copy_vars)
        out.append("  modifies " + ", ".join(sorted(set(mod))) + ";\n")
        out.append("{\n")
        out.append(f"  assume {dst}_inbox_count < {k};\n")
        # Store the packet fields (single slot) and mark as forwarded
        for v in copy_vars:
            out.append(f"  {dst}_{v} := {src}_{v};\n")
        out.append(f"  {dst}_pkt_external := false;\n")
        out.append(f"  {dst}_inbox_count := {dst}_inbox_count + 1;\n")
        out.append("}\n")
        return "".join(out)

    def _get_declared_vars(self, name: str) -> set[str]:
        if name in self._host_declared_vars:
            return self._host_declared_vars.get(name, set())
        return self._node_declared_vars.get(name, set())

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
            out.append(self._emit_external_enqueue_stmt(n, k, indent="        "))
            out.append("        atomic {\n")
            out.append("          procurator_lock := 0;\n")
            out.append("        }\n")
            out.append("      }\n")
        out.append("  }\n")
        out.append("}\n")
        return "".join(out)

    def _emit_node_thread(self, node: str, k: int) -> str:
        input_vars = self._node_input_vars.get(node, [])

        assert_lines = "".join(
            f"      assert {self._expr_to_boogie(expr, current_node=node)};\n"
            for expr in self._spec.nodes.get(node, NodeDecl(name=node)).assert_exprs
        )
        assert_lines += "".join(
            f"      assert {self._expr_to_boogie(expr, current_node=node)};\n" for expr in self._spec.global_decl.assert_exprs
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
        declared = self._node_declared_vars.get(node, set())
        clone_flags = []
        for flag in ("p4b_clone_i2e", "p4b_clone_e2e", "p4b_clone_i2i", "p4b_recirculate"):
            if flag in declared:
                clone_flags.append(flag)
                modifies_set.add(f"{node}_{flag}")
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
        out.append("    if (*) {\n")
        out.append("      atomic {\n")
        out.append("        assume procurator_lock == 0;\n")
        out.append(f"        assume {node}_inbox_count > 0;\n")
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
            out.append("      // DSL assertions\n")
            out.append(assert_lines)
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
        for expr in hd.assert_exprs:
            out.append(f"        assert {self._expr_to_boogie(expr, current_node=host)};\n")
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
        # DSL locals are globals and may be initialized here.
        start_modifies.update(f"dsl_{name}" for name in self._dsl_global_vars.keys())
        for a in node_aliases:
            start_modifies.update(f"{a}_dsl_{name}" for name in self._dsl_node_vars.get(a, {}).keys())
        for h in host_aliases:
            start_modifies.update(f"{h}_dsl_{name}" for name in self._dsl_host_vars.get(h, {}).keys())
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

    def _emit_external_enqueue_stmt(self, dst: str, k: int, indent: str) -> str:
        out: List[str] = []
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

    def _expr_to_boogie(self, expr: Tree, current_node: str) -> str:
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
            return self._expr_to_boogie(ch[0], current_node=current_node)
        if t == "dotted_var":
            return self._dotted_var_to_boogie(expr, current_node=current_node)

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
                rendered = [self._expr_to_boogie(e, current_node) for e in expr_children]
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
                lhs_render = self._expr_to_boogie(lhs, current_node)
                rhs_render = self._expr_to_boogie(rhs, current_node)
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
                        le_fn = f"bvule.bv{wl}"
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
                return f"!({self._expr_to_boogie(expr_children[0], current_node)})"

        # LTL unary ops may appear in assume/assert blocks in some specs; keep best-effort
        if t in {"always_op", "eventually_op"} and len(ch) >= 1:
            return self._expr_to_boogie(ch[-1], current_node=current_node)

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

        def emit_bool_block(stmt: Tree, cur_indent: str) -> None:
            for expr in self._extract_bool_exprs(stmt):
                out.append(f"{cur_indent}assume {self._expr_to_boogie(expr, current_node=node)};\n")

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

        def emit_bool_block(stmt: Tree, cur_indent: str) -> None:
            for expr in self._extract_bool_exprs(stmt):
                out.append(f"{cur_indent}assume {self._expr_to_boogie(expr, current_node=host)};\n")

        def emit_stmt(stmt: Tree, cur_indent: str) -> None:
            st = str(stmt.data)
            if st == "var_decl":
                return
            if st == "assignment":
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


def _dsl_is_simple_local_name(name: str) -> bool:
    # No dotted/indexed names: those are assumed to be P4/Boogie vars.
    return bool(name) and ("." not in name) and ("[" not in name) and re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name)


def _dsl_type_to_boogie(dsl_typ: str) -> str:
    if dsl_typ == "int":
        return "int"
    if dsl_typ == "bool":
        return "bool"
    # Defensive fallback
    return "int"


def _collect_dotted_vars(expr: Tree) -> set[str]:
    out: set[str] = set()
    for dv in expr.find_data("dotted_var"):
        if isinstance(dv, Tree):
            out.add(BoogieHarnessEmitter._dotted_var_to_str_static(dv))
    return out


class BoogieBackend:
    def __init__(self, p4b_bin: Optional[str] = None):
        self._p4b_bin = p4b_bin

    def compile(
        self,
        spec: SpecModel,
        out_bpl: Path,
        work_dir: Optional[Path] = None,
        *,
        max_env_inputs: bool = False,
        enable_slicing: bool = True,
    ) -> Path:
        work_dir = work_dir or Path(str(out_bpl) + ".work")
        work_dir.mkdir(parents=True, exist_ok=True)

        node_info: Dict[str, _BoogieNodeInfo] = {}

        # 1) Load or compile each imported unit into raw Boogie
        def collect_slice_seeds() -> Dict[str, List[str]]:
            seeds: Dict[str, set[str]] = {a: set() for a in spec.imports.keys()}

            def add_seed(node: str, name: str) -> None:
                if node in seeds:
                    seeds[node].add(name)

            # Node-local assumes/asserts and DSL statements (including env blocks).
            for node, nd in spec.nodes.items():
                for expr in list(nd.assume_exprs) + list(nd.assert_exprs):
                    for v in _collect_dotted_vars(expr):
                        if v.startswith(f"{node}_"):
                            add_seed(node, v[len(node) + 1 :])
                        else:
                            add_seed(node, v)
                for stmt in list(nd.statements) + list(getattr(nd, "env_statements", [])):
                    for v in _collect_dotted_vars(stmt):
                        if v.startswith(f"{node}_"):
                            add_seed(node, v[len(node) + 1 :])
                        else:
                            add_seed(node, v)

            # Global assumes/asserts
            for expr in list(spec.global_decl.assume_exprs) + list(spec.global_decl.assert_exprs):
                for v in _collect_dotted_vars(expr):
                    matched = False
                    for node in spec.imports.keys():
                        if v.startswith(f"{node}_"):
                            add_seed(node, v[len(node) + 1 :])
                            matched = True
                            break
                    if not matched:
                        for node in spec.imports.keys():
                            add_seed(node, v)

            # Host env/assume/asserts are treated as seeds for their connected node.
            for host, hd in spec.hosts.items():
                target = hd.connect_to
                if not target or target not in seeds:
                    continue
                for expr in list(hd.assume_exprs) + list(hd.assert_exprs):
                    for v in _collect_dotted_vars(expr):
                        if v.startswith(f"{target}_"):
                            add_seed(target, v[len(target) + 1 :])
                        else:
                            add_seed(target, v)
                for stmt in list(hd.statements) + list(getattr(hd, "env_statements", [])):
                    for v in _collect_dotted_vars(stmt):
                        if v.startswith(f"{target}_"):
                            add_seed(target, v[len(target) + 1 :])
                        else:
                            add_seed(target, v)

            return {k: sorted(v) for k, v in seeds.items()}

        def propagate_packet_seeds(seeds: Dict[str, List[str]]) -> Dict[str, List[str]]:
            # Propagate packet-carried vars backward along topology so upstream nodes keep needed headers.
            work: Dict[str, set[str]] = {n: set(vs) for n, vs in seeds.items()}
            packet_only: Dict[str, set[str]] = {
                n: {v for v in vs if _is_packet_var(v)} for n, vs in work.items()
            }
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

        node_seed_vars = collect_slice_seeds() if enable_slicing else {}
        if enable_slicing and spec.links:
            node_seed_vars = propagate_packet_seeds(node_seed_vars)
        for alias, imp in spec.imports.items():
            src_path = imp.path
            if src_path.endswith(".bpl"):
                raw_text = Path(src_path).read_text(encoding="utf-8", errors="replace")
                meta_obj: Optional[dict] = None
            else:
                if not self._p4b_bin:
                    raise BoogieBackendError(
                        f"import {alias} from '{src_path}': not a .bpl file; "
                        f"provide p4b_bin to compile P4/JSON to Boogie"
                    )
                raw_path = work_dir / f"{alias}.raw.bpl"
                meta_path = work_dir / f"{alias}.meta.json"
                p4b = P4BTranslator(self._p4b_bin)
                p4b.compile_to_bpl(
                    src_path,
                    str(raw_path),
                    imp.entries_path,
                    out_meta=str(meta_path),
                    slicing_vars=node_seed_vars.get(alias),
                    disable_slicing=not enable_slicing,
                )
                raw_text = raw_path.read_text(encoding="utf-8", errors="replace")
                try:
                    meta_obj = json.loads(meta_path.read_text(encoding="utf-8"))
                except Exception:
                    meta_obj = None

            # Generated Boogie should be valid as-is; P4B-Translator handles sanitization.

            if not _looks_like_bpl(raw_text):
                raise BoogieBackendError(
                    f"Input for node '{alias}' does not look like Boogie (.bpl). "
                    f"If you passed a Promela translator, please pass a P4->Boogie translator instead."
                )

            input_vars, egress_t, declared, var_types, egress_var, type_defs = _collect_input_vars_and_egress_type(
                raw_text
            )
            if enable_slicing:
                input_vars = _filter_input_vars_by_usage(raw_text, input_vars)
            node_info[alias] = _BoogieNodeInfo(
                raw_bpl=raw_text,
                input_vars=input_vars,
                egress_port_type=egress_t,
                egress_port_var=egress_var,
                declared_vars=declared,
                var_types=var_types,
                type_defs=type_defs,
                meta=meta_obj,
            )

        # 2) Prefix each Boogie unit to avoid collisions
        node_prefixed: Dict[str, str] = {}
        node_main_modifies: Dict[str, set[str]] = {}
        for alias, info in node_info.items():
            prefixed = BoogiePrefixer(alias).prefix_content(info.raw_bpl)
            node_prefixed[alias] = prefixed
            node_main_modifies[alias] = _extract_mainprocedure_modifies(prefixed, alias)

        host_to_node: Dict[str, str] = {}
        host_input_vars: Dict[str, List[str]] = {}
        host_var_types: Dict[str, Dict[str, str]] = {}
        def _prefix_host_type(node: str, typ: str) -> str:
            if not typ:
                return typ
            if typ in {"int", "bool"}:
                return typ
            if typ.startswith("bv") and typ[2:].isdigit():
                return typ
            if typ.startswith(f"{node}_"):
                return typ
            return f"{node}_{typ}"
        for host, hd in spec.hosts.items():
            if not hd.connect_to:
                raise BoogieBackendError(f"host '{host}' missing connect target")
            if hd.connect_to not in node_info:
                raise BoogieBackendError(
                    f"host '{host}' connect target '{hd.connect_to}' not found among imports"
                )
            host_to_node[host] = hd.connect_to
            host_input_vars[host] = list(node_info[hd.connect_to].input_vars)
            host_var_types[host] = {
                k: _prefix_host_type(hd.connect_to, v) for k, v in node_info[hd.connect_to].var_types.items()
            }

        # 3) Emit concurrent harness
        emitter = BoogieHarnessEmitter(
            spec,
            node_input_vars={a: info.input_vars for a, info in node_info.items()},
            node_egress_port_type={a: info.egress_port_type for a, info in node_info.items()},
            node_egress_port_var={a: info.egress_port_var for a, info in node_info.items()},
            node_declared_vars={a: info.declared_vars for a, info in node_info.items()},
            node_mainprocedure_modifies=node_main_modifies,
            node_var_types={a: info.var_types for a, info in node_info.items()},
            node_type_defs={a: info.type_defs for a, info in node_info.items()},
            node_meta={a: info.meta for a, info in node_info.items()},
            host_to_node=host_to_node,
            host_input_vars=host_input_vars,
            host_var_types=host_var_types,
            max_env_inputs=max_env_inputs,
        )
        helpers = emitter.emit_helpers()
        harness = emitter.emit(emit_helpers=False)

        # 4) Concatenate into a single .bpl
        merged: List[str] = []
        if helpers:
            merged.append("// ===== BEGIN PREAMBLE =====\n")
            merged.append(helpers)
            if not helpers.endswith("\n"):
                merged.append("\n")
            merged.append("// ===== END PREAMBLE =====\n\n")
        seen_bvbuiltins: set[str] = set()
        for alias in sorted(node_prefixed.keys()):
            merged.append(f"// ===== BEGIN NODE {alias} (prefixed) =====\n")
            node_body = _dedup_bvbuiltin_decls(node_prefixed[alias], seen_bvbuiltins)
            merged.append(node_body)
            if not node_body.endswith("\n"):
                merged.append("\n")
            merged.append(f"// ===== END NODE {alias} =====\n\n")

        # enqueue procs (need them after node vars)
        merged.append("// ===== BEGIN ENQUEUE PROCEDURES =====\n")
        k = spec.global_decl.queue_capacity if spec.global_decl.queue_capacity is not None else 5
        for l in spec.links:
            merged.append(emitter._emit_enqueue_proc(l.src, l.dst, k))  # noqa: SLF001
            merged.append("\n")
        merged.append("// ===== END ENQUEUE PROCEDURES =====\n\n")

        merged.append("// ===== BEGIN HARNESS =====\n")
        merged.append(harness)
        merged.append("// ===== END HARNESS =====\n")

        out_bpl.write_text("".join(merged), encoding="utf-8")
        return out_bpl
