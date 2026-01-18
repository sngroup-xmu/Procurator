from __future__ import annotations

import re
from typing import Dict, List, Optional, Sequence, Tuple

from .boogie_common import is_packet_var, is_skipped_input_var


def looks_like_bpl(text: str) -> bool:
    # Very cheap heuristic to detect "definitely not Boogie".
    if re.search(r"\bproctype\b", text):
        return False
    if re.search(r"^\s*procedure\b", text, re.MULTILINE):
        return True
    if re.search(r"^\s*var\b", text, re.MULTILINE):
        return True
    return False


def collect_input_vars_and_egress_type(
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
            if is_skipped_input_var(name):
                continue
            input_vars.append(name)

    seen = set()
    dedup: List[str] = []
    for v in input_vars:
        if v not in seen:
            seen.add(v)
            dedup.append(v)
    return dedup, egress_type, declared_vars, var_types, egress_var, type_defs


def filter_input_vars_by_usage(
    raw_bpl: str,
    input_vars: Sequence[str],
    *,
    force_keep: Optional[Sequence[str]] = None,
) -> List[str]:
    # Drop vars that only appear in declarations; this keeps env inputs aligned with the sliced program.
    stripped = re.sub(r"^\s*var\s+[^;]+;\s*$", "", raw_bpl, flags=re.MULTILINE)
    kept: List[str] = []
    force = set(force_keep or [])
    for v in input_vars:
        pat = r"\b" + re.escape(v) + r"\b"
        if v in force or re.search(pat, stripped):
            kept.append(v)
    for v in force:
        if v not in kept:
            kept.append(v)
    return kept


_P4_VAR_REF_RE = re.compile(
    r"\b(?:hdr|hdr_eg|meta|standard_metadata|[A-Za-z0-9_]+_md)\.[A-Za-z0-9_\.\$]+\b"
)


def _infer_missing_var_type(name: str, raw_bpl: str, meta: Optional[dict]) -> str:
    if isinstance(meta, dict):
        vt = meta.get("var_types")
        if isinstance(vt, dict):
            t = vt.get(name)
            if isinstance(t, str) and t.strip():
                return t.strip()
        sizes = meta.get("sizes")
        if isinstance(sizes, dict) and name in sizes:
            try:
                sz = int(sizes[name])
                if sz == 0:
                    return "bool"
                return f"bv{sz}"
            except Exception:
                pass
    m = re.search(re.escape(name) + r"[^\n]*?\bbv(\d+)\b", raw_bpl)
    if m:
        return f"bv{m.group(1)}"
    return "bv32"


def patch_missing_var_decls(
    raw_bpl: str,
    *,
    meta: Optional[dict],
    required_vars: Optional[Sequence[str]] = None,
) -> str:
    var_decl_re = re.compile(r"^\s*var\s+([A-Za-z0-9_\.\$]+)\s*:\s*([^;]+);\s*$", re.MULTILINE)
    const_decl_re = re.compile(
        r"^\s*const(?:\s+unique)?\s+([A-Za-z0-9_\.\$]+)\s*:\s*([^;]+);\s*$",
        re.MULTILINE,
    )
    declared = {m.group(1) for m in var_decl_re.finditer(raw_bpl)}
    declared.update(m.group(1) for m in const_decl_re.finditer(raw_bpl))
    referenced = {m.group(0) for m in _P4_VAR_REF_RE.finditer(raw_bpl)}
    required = {v for v in (required_vars or []) if is_packet_var(v) and not is_skipped_input_var(v)}
    missing = sorted((referenced | required) - declared)
    if not missing:
        return raw_bpl
    decls: List[str] = []
    for name in missing:
        typ = _infer_missing_var_type(name, raw_bpl, meta)
        if not typ:
            continue
        decls.append(f"var {name}: {typ};\n")
    if not decls:
        return raw_bpl
    insert = re.search(r"^\s*procedure\b", raw_bpl, re.MULTILINE)
    block = "".join(decls)
    if insert:
        return raw_bpl[: insert.start()] + block + raw_bpl[insert.start() :]
    return raw_bpl + "\n" + block

