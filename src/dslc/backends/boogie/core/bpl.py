from __future__ import annotations

import re
from typing import Dict, List, Optional, Sequence, Tuple

from .common import is_packet_var, is_skipped_input_var


def looks_like_bpl(text: str) -> bool:
    # Very cheap heuristic to detect "definitely not Boogie".
    if re.search(r"\bproctype\b", text):
        return False
    if re.search(r"^\s*procedure\b", text, re.MULTILINE):
        return True
    if re.search(r"^\s*var\b", text, re.MULTILINE):
        return True
    return False


_BPL_TYPE_DECL_RE = re.compile(
    r"^\s*type(?:\s*\{:[^}]+\}\s*)*\s+([A-Za-z0-9_\.\$]+)\s*(?:=\s*[^;]+)?;\s*$",
    re.MULTILINE,
)
_BPL_VAR_DECL_RE = re.compile(r"^\s*var\s+([A-Za-z0-9_\.\$]+)\s*:\s*([^;]+);\s*$", re.MULTILINE)
_BPL_CONST_DECL_RE = re.compile(
    r"^\s*const(?:\s+unique)?\s+([A-Za-z0-9_\.\$]+)\s*:\s*([^;]+);\s*$",
    re.MULTILINE,
)
_BPL_FUNC_DECL_RE = re.compile(r"^\s*function\b[^;]*;\s*$", re.MULTILINE)
_BPL_PROC_DECL_RE = re.compile(
    r"^\s*procedure(?:\s*\{:[^}]+\}\s*)*\s+[A-Za-z0-9_\.\$]+\s*\([^)]*\)"
    r"(?:\s*returns\s*\([^)]*\))?\s*",
    re.MULTILINE,
)
_BPL_TYPED_BINDING_RE = re.compile(r"\b[A-Za-z_][A-Za-z0-9_\.\$]*\s*:\s*([A-Za-z_][A-Za-z0-9_\.\$]*)")
_BPL_RETURNS_RE = re.compile(r"\breturns\s*\(([^)]*)\)")
_BPL_TYPE_TOKEN_RE = re.compile(r"\b[A-Za-z_][A-Za-z0-9_\.\$]*\b")
_BPL_BV_TYPE_RE = re.compile(r"^bv\d+$")


def _is_builtin_type_ident(t: str) -> bool:
    if t in {"bool", "int", "real"}:
        return True
    if _BPL_BV_TYPE_RE.match(t):
        return True
    return False


def find_missing_type_decls(raw_bpl: str) -> List[str]:
    """
    Find Boogie types that are *used* in declarations but never declared.

    Some P4->Boogie outputs emit `// Struct <T>` comments but forget to declare
    `type <T>;`, which causes Ultimate to reject the Boogie program as ill-typed
    (even though the type is intended to be opaque).
    """

    declared = {m.group(1) for m in _BPL_TYPE_DECL_RE.finditer(raw_bpl)}
    used: set[str] = set()

    def add_return_types(ret: str) -> None:
        if ":" in ret:
            used.update(_BPL_TYPED_BINDING_RE.findall(ret))
        else:
            used.update(_BPL_TYPE_TOKEN_RE.findall(ret))

    for m in _BPL_VAR_DECL_RE.finditer(raw_bpl):
        used.update(_BPL_TYPE_TOKEN_RE.findall(m.group(2)))
    for m in _BPL_CONST_DECL_RE.finditer(raw_bpl):
        used.update(_BPL_TYPE_TOKEN_RE.findall(m.group(2)))
    for m in _BPL_FUNC_DECL_RE.finditer(raw_bpl):
        decl = m.group(0)
        used.update(_BPL_TYPED_BINDING_RE.findall(decl))
        for ret in _BPL_RETURNS_RE.findall(decl):
            add_return_types(ret)
    for m in _BPL_PROC_DECL_RE.finditer(raw_bpl):
        decl = m.group(0)
        used.update(_BPL_TYPED_BINDING_RE.findall(decl))
        for ret in _BPL_RETURNS_RE.findall(decl):
            add_return_types(ret)

    missing = sorted(t for t in used if (t not in declared) and (not _is_builtin_type_ident(t)))
    return missing


def assert_no_missing_type_decls(raw_bpl: str) -> None:
    """
    Correctness check: fail fast if Boogie declarations reference missing types.

    This usually indicates a P4->Boogie translator bug (e.g., emitting `var x:T;`
    without any `type T;` or `type T = ...;`).
    """

    missing = find_missing_type_decls(raw_bpl)
    if missing:
        raise ValueError(
            "missing Boogie type declarations for referenced types (translator bug):\n"
            + "\n".join(f"  - {t}" for t in missing[:80])
            + ("\n  - ..." if len(missing) > 80 else "")
        )


def collect_input_vars_and_egress_type(
    raw_bpl: str,
) -> Tuple[List[str], str, set[str], Dict[str, str], str, Dict[str, str]]:
    """
    Extract:
      (a) a conservative list of input packet/metadata vars to havoc each pass,
      (b) the type of standard_metadata.egress_port for forwarding decisions,
      (c) declared value symbols (raw names, for consistency checks and DSL refs).
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
        if name.startswith(("hdr.", "hdr_eg.", "meta.", "standard_metadata.")) or "_md." in name:
            if typ == "Ref" or typ.endswith("Ref"):
                continue
            if is_skipped_input_var(name):
                continue
            input_vars.append(name)

    const_decl_re = re.compile(
        r"^\s*const(?:\s+unique)?\s+([A-Za-z0-9_\.\$]+)\s*:\s*([^;]+);\s*$",
        re.MULTILINE,
    )
    for m in const_decl_re.finditer(raw_bpl):
        # Constants are not packet inputs and should never be copied/havoced, but
        # DSL env/assert expressions may legitimately refer to table action enum
        # values such as `Ingress_tbl.action.Ingress_act`.
        declared_vars.add(m.group(1))

    seen = set()
    dedup: List[str] = []
    for v in input_vars:
        if v not in seen:
            seen.add(v)
            dedup.append(v)
    return dedup, egress_type, declared_vars, var_types, egress_var, type_defs


def collect_skipped_input_vars(raw_bpl: str) -> List[str]:
    skipped: List[str] = []
    for m in _BPL_VAR_DECL_RE.finditer(raw_bpl):
        name = m.group(1)
        if is_skipped_input_var(name):
            skipped.append(name)
    return sorted(set(skipped))


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
    r"(?<![A-Za-z0-9_\.\$])"
    r"(?:hdr|hdr_eg|meta|standard_metadata|[A-Za-z0-9_]+_md)\.[A-Za-z0-9_\.\$]+"
    r"(?![A-Za-z0-9_\.\$])"
)


def _required_var_resolves_declared(declared: set[str], name: str) -> bool:
    base_name = name
    suffix = ""
    if "[" in name:
        base_name, rest = name.split("[", 1)
        suffix = "[" + rest

    candidates = [base_name]
    if base_name.endswith("_0"):
        candidates.append(base_name[:-2])
    else:
        candidates.append(base_name + "_0")

    return any((cand + suffix) in declared for cand in candidates if cand)


def find_missing_var_decls(
    raw_bpl: str,
    *,
    required_vars: Optional[Sequence[str]] = None,
) -> List[str]:
    var_decl_re = re.compile(r"^\s*var\s+([A-Za-z0-9_\.\$]+)\s*:\s*([^;]+);\s*$", re.MULTILINE)
    const_decl_re = re.compile(
        r"^\s*const(?:\s+unique)?\s+([A-Za-z0-9_\.\$]+)\s*:\s*([^;]+);\s*$",
        re.MULTILINE,
    )
    declared = {m.group(1) for m in var_decl_re.finditer(raw_bpl)}
    declared.update(m.group(1) for m in const_decl_re.finditer(raw_bpl))
    referenced = {m.group(0) for m in _P4_VAR_REF_RE.finditer(raw_bpl)}
    required = {v for v in (required_vars or []) if is_packet_var(v) and not is_skipped_input_var(v)}
    missing_referenced = referenced - declared
    missing_required = {v for v in required if not _required_var_resolves_declared(declared, v)}
    missing = sorted(missing_referenced | missing_required)
    return missing


def assert_no_missing_var_decls(raw_bpl: str, *, required_vars: Optional[Sequence[str]] = None) -> None:
    """
    Correctness check: fail fast if Boogie references P4 packet/meta variables that were
    not declared in the file.

    We intentionally do NOT "best-effort patch" missing declarations, because that can
    silently change program semantics and mask translator/slicing bugs.
    """

    missing = find_missing_var_decls(raw_bpl, required_vars=required_vars)
    if missing:
        raise ValueError(
            "missing Boogie declarations for referenced P4 variables (translator/slicer bug):\n"
            + "\n".join(f"  - {m}" for m in missing[:80])
            + ("\n  - ..." if len(missing) > 80 else "")
        )
