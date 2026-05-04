from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Dict, Iterable, List, Optional, Sequence, Set


_RE_IDENT = re.compile(r"\b[A-Za-z_][A-Za-z0-9_.]*\b")


@dataclass(frozen=True)
class ArraySelect:
    array: str
    index: str


def normalize_expr(expr: Optional[str]) -> str:
    text = str(expr or "").strip()
    if not text:
        return ""
    text = re.sub(r"\s+", " ", text)
    text = canonicalize_p4b_register_reads(text)
    text = strip_redundant_array_select_parens(text)
    return strip_wrapping_parens(text)


def canonicalize_p4b_register_reads(expr: str) -> str:
    """Rewrite P4B register read functions to Boogie array-slot syntax."""

    out: List[str] = []
    i = 0
    n = len(expr)
    while i < n:
        m = re.search(r"\b([A-Za-z_][A-Za-z0-9_.]*)\.read\s*\(", expr[i:])
        if not m:
            out.append(expr[i:])
            break
        start = i + m.start()
        call_open = i + m.end() - 1
        reg = m.group(1)
        close = matching_paren(expr, call_open)
        if close is None:
            out.append(expr[i:])
            break
        out.append(expr[i:start])
        args = split_args(expr[call_open + 1 : close])
        if len(args) == 2 and args[0].strip() == reg:
            index = canonicalize_p4b_register_reads(args[1].strip())
            out.append(f"{reg}[{index}]")
        else:
            out.append(expr[start : close + 1])
        i = close + 1
    return "".join(out)


def matching_paren(text: str, open_idx: int) -> Optional[int]:
    if open_idx < 0 or open_idx >= len(text) or text[open_idx] != "(":
        return None
    depth = 0
    for i in range(open_idx, len(text)):
        ch = text[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i
    return None


def strip_redundant_array_select_parens(expr: str) -> str:
    array_select = r"[A-Za-z_][A-Za-z0-9_.]*\[[^\[\]]+\]"
    prev = None
    text = expr
    while prev != text:
        prev = text
        text = re.sub(rf"\(({array_select})\)", r"\1", text)
    return text


def strip_wrapping_parens(expr: str) -> str:
    s = expr.strip()
    while s.startswith("(") and s.endswith(")"):
        depth = 0
        wraps = True
        for i, ch in enumerate(s):
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0 and i != len(s) - 1:
                    wraps = False
                    break
        if not wraps:
            break
        s = s[1:-1].strip()
    return s


def replace_array_select_index(expr: str, array: str, replacement_index: str) -> str:
    out: List[str] = []
    i = 0
    n = len(expr)
    needle = f"{array}["
    while i < n:
        pos = expr.find(needle, i)
        if pos < 0:
            out.append(expr[i:])
            break
        open_idx = pos + len(array)
        close = matching_bracket(expr, open_idx)
        if close is None:
            out.append(expr[i:])
            break
        out.append(expr[i:pos])
        out.append(f"{array}[{replacement_index}]")
        i = close + 1
    return "".join(out)


def array_selects_in_expr(expr: str) -> List[ArraySelect]:
    out: List[ArraySelect] = []
    i = 0
    n = len(expr)
    while i < n:
        m = re.search(r"\b([A-Za-z_][A-Za-z0-9_.]*)\s*\[", expr[i:])
        if not m:
            break
        start = i + m.start()
        open_idx = i + m.end() - 1
        close = matching_bracket(expr, open_idx)
        if close is None:
            i = open_idx + 1
            continue
        out.append(ArraySelect(array=m.group(1), index=expr[open_idx + 1 : close].strip()))
        i = close + 1
    return out


def array_assignment_index_expr(lhs: str) -> Optional[str]:
    selects = array_selects_in_expr(lhs)
    if len(selects) != 1:
        return None
    if lhs.strip().split("[", 1)[0].strip("() ") != selects[0].array:
        return None
    return normalize_expr(selects[0].index)


def record_array_select_indices(expr: str, *, array_indices: Dict[str, Set[str]], var_types: Dict[str, str]) -> None:
    for sel in array_selects_in_expr(normalize_expr(expr)):
        typ = var_types.get(sel.array)
        if sel.array in var_types and (not typ or "[" in typ):
            array_indices.setdefault(sel.array, set()).add(normalize_expr(sel.index))


def dynamic_slot_indices(array_indices: Dict[str, Set[str]], dep: str) -> Set[str]:
    return {normalize_expr(idx) for idx in array_indices.get(dep, set()) if idx}


def stable_register_slot_projection_vars(
    *,
    live_deps: Set[str],
    var_types: Dict[str, str],
    excluded: Set[str],
    dynamic_index: bool = False,
) -> List[str]:
    if dynamic_index:
        return []
    out: List[str] = []
    for dep in sorted(live_deps):
        typ = var_types.get(dep)
        if not typ or "[" not in typ or dep in excluded:
            continue
        mirror = f"{dep}__last0_value"
        if mirror in var_types and mirror not in excluded:
            out.append(mirror)
    return unique(out)


def dynamic_slot_deps(
    *,
    live_deps: Set[str],
    var_types: Dict[str, str],
    excluded: Set[str],
    dynamic_index: bool,
    predicate_vars: Set[str] = frozenset(),
) -> List[str]:
    if not dynamic_index:
        return []
    out: List[str] = []
    for dep in sorted(live_deps):
        typ = var_types.get(dep)
        if not typ or "[" not in typ or dep in excluded:
            continue
        if not _is_stateful_register_array(dep, var_types):
            continue
        if dep in predicate_vars:
            continue
        out.append(dep)
    return unique(out)


def dynamic_slot_projection_exprs(
    dynamic_slot_deps: Sequence[str],
    *,
    pump_reg: str,
    index_expr: Optional[str],
    var_types: Dict[str, str],
    array_indices: Dict[str, Set[str]],
    stable_substitutions: Iterable[tuple[str, str]] = (),
) -> Dict[str, str]:
    if not dynamic_slot_deps or not index_expr:
        return {}
    target_index_width = array_index_width(var_types.get(pump_reg, ""))
    if target_index_width is None:
        return {}
    subst = dict(stable_substitutions or ())
    out: Dict[str, str] = {}
    for dep in dynamic_slot_deps:
        dep_index_width = array_index_width(var_types.get(dep, ""))
        if dep_index_width is None or dep_index_width != target_index_width:
            continue
        seen_indices = {
            normalize_expr(_substitute_tokens(idx, subst))
            for idx in dynamic_slot_indices(array_indices, dep)
        }
        if seen_indices and index_expr not in seen_indices:
            continue
        out[dep] = f"{dep}[{index_expr}]"
    return out


def _is_stateful_register_array(name: str, var_types: Dict[str, str]) -> bool:
    if "[" not in var_types.get(name, ""):
        return False
    return any(
        f"{name}{suffix}" in var_types
        for suffix in (
            "__last_index",
            "__last_value",
            "__wrote_any",
            "__wrote_index0",
            "__last0_value",
        )
    )


def matching_bracket(text: str, open_idx: int) -> Optional[int]:
    if open_idx < 0 or open_idx >= len(text) or text[open_idx] != "[":
        return None
    depth = 0
    for i in range(open_idx, len(text)):
        ch = text[i]
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0:
                return i
    return None


def deps_in_expr(expr: Optional[str], *, var_types: Dict[str, str], deps: Dict[str, Set[str]]) -> Set[str]:
    if not expr:
        return set()
    out: Set[str] = set()
    for tok in _RE_IDENT.findall(expr):
        if tok in deps:
            out.update(deps[tok])
        elif tok in var_types:
            out.add(tok)
    return out


def vars_in_expr(expr: str, *, var_types: Dict[str, str], deps: Dict[str, Set[str]]) -> Set[str]:
    return deps_in_expr(expr, var_types=var_types, deps=deps)


def extract_cond_text(line: str) -> str:
    i = line.find("(")
    j = line.rfind(")")
    if i < 0 or j <= i:
        return ""
    return line[i + 1 : j].strip()


def split_args(args: str) -> List[str]:
    out: List[str] = []
    cur: List[str] = []
    depth = 0
    for ch in args:
        if ch == "," and depth == 0:
            out.append("".join(cur).strip())
            cur = []
            continue
        cur.append(ch)
        if ch in "([{":
            depth += 1
        elif ch in ")]}" and depth > 0:
            depth -= 1
    tail = "".join(cur).strip()
    if tail:
        out.append(tail)
    return out


def vars_in_predicates(predicates: Sequence[str], var_types: Dict[str, str]) -> Set[str]:
    out: Set[str] = set()
    for expr in predicates:
        for tok in _RE_IDENT.findall(expr):
            if tok in var_types:
                out.add(tok)
    return out


def array_index_width(typ: str) -> Optional[int]:
    m = re.match(r"^\s*\[\s*bv(?P<w>\d+)\s*\]", typ or "")
    if not m:
        return None
    return int(m.group("w"))


def looks_like_array_slot_predicate(expr: str) -> bool:
    return "[" in expr and "]" in expr


def manifest_array_selects_are_stable(expr: str, *, ignored: Iterable[str] = ()) -> bool:
    ignored_set = set(ignored)
    for sel in array_selects_in_expr(expr):
        if not _is_manifest_stable_array_name(sel.array):
            return False
        function_names = set(re.findall(r"\b([A-Za-z_][A-Za-z0-9_.$]*)\s*\(", sel.index))
        function_prefixes = {fn.split("$", 1)[0] for fn in function_names}
        for tok in _RE_IDENT.findall(sel.index):
            if tok in ignored_set:
                continue
            if tok in function_names or tok in function_prefixes or re.fullmatch(r"bv\d+", tok):
                continue
            if not _is_manifest_stable_index_token(tok):
                return False
    return True


def _is_manifest_stable_array_name(name: str) -> bool:
    if not name or is_packet_slot_var(name):
        return False
    if name.startswith(("meta.", "hdr.", "standard_metadata")):
        return False
    if "_meta." in name or "_hdr." in name or "_standard_metadata" in name:
        return False
    if name.startswith("tmp") or "_tmp" in name:
        return False
    return True


def _is_manifest_stable_index_token(tok: str) -> bool:
    if re.fullmatch(r"\d+bv\d+", tok):
        return True
    return is_stable_cutpoint_var(tok)


def is_stable_cutpoint_var(name: str) -> bool:
    if name == "procurator_phase" or name.startswith("procurator_"):
        return True
    if name.endswith("_inbox_count") or name.endswith("_egress_count"):
        return True
    if name.startswith("dsl_") or name.endswith("dsl_pump_mode"):
        return True
    if name.endswith("__last0_value"):
        return True
    return False


def is_packet_slot_var(name: str) -> bool:
    return "_hdr." in name or name.endswith("_pkt_external")


def is_stable_projection_predicate_text(
    expr: str,
    *,
    var_types: Optional[Dict[str, str]] = None,
    default_state: Iterable[str] = (),
    excluded: Iterable[str] = (),
) -> bool:
    """
    Conservative manifest-facing stability check for certified projection predicates.

    In syntax-only mode, array predicates must use stable-looking arrays and
    literal/stable cutpoint indices.  Deterministic P4B helper calls with
    constant arguments are treated as stable expression syntax, not state.
    """

    default = set(default_state)
    banned = set(excluded)
    ignored = {"true", "false", "old"}
    toks = [tok for tok in _RE_IDENT.findall(expr) if tok not in ignored]

    if var_types is not None:
        state_vars = {tok for tok in toks if tok in var_types}
    else:
        function_names = set(re.findall(r"\b([A-Za-z_][A-Za-z0-9_.$]*)\s*\(", expr))
        function_prefixes = {fn.split("$", 1)[0] for fn in function_names}
        state_vars = {
            tok
            for tok in toks
            if tok not in function_names and tok not in function_prefixes and not re.fullmatch(r"bv\d+", tok)
        }

    if not state_vars:
        return False

    array_selects = array_selects_in_expr(expr)
    array_names = {sel.array for sel in array_selects}
    if var_types is None and array_selects:
        if not manifest_array_selects_are_stable(expr, ignored=ignored):
            return False

    for v in state_vars:
        if v in banned:
            return False
        if var_types is not None:
            typ = var_types.get(v, "")
            if "[" not in typ and "]" not in typ and not _is_snapshot_scalar_type(typ):
                return False
        if v in default:
            continue
        if var_types is not None:
            typ = var_types.get(v, "")
            if "[" in typ or "]" in typ:
                continue
        elif v in array_names:
            continue
        if not is_stable_cutpoint_var(v):
            return False
    return True


def _is_snapshot_scalar_type(typ: str) -> bool:
    text = str(typ or "").strip()
    if not text or "[" in text or "]" in text:
        return False
    return text == "int" or text == "bool" or re.match(r"^bv\d+$", text) is not None


def unique(values: Iterable[str]) -> List[str]:
    seen: Set[str] = set()
    out: List[str] = []
    for v in values:
        if v in seen:
            continue
        seen.add(v)
        out.append(v)
    return out


def specialize_dynamic_slot_guard(
    expr: str,
    *,
    index_expr: Optional[str],
    pump_reg: str,
    live_deps: Set[str],
    excluded: Set[str],
    var_types: Dict[str, str],
    stable_substitutions: Iterable[tuple[str, str]] = (),
    stable_consts: Optional[Dict[str, str]] = None,
) -> str:
    subst = dict(stable_substitutions or ())
    subst.update(stable_consts or {})
    text = normalize_expr(_substitute_tokens(expr, subst))
    if not index_expr:
        return text

    target_index_width = array_index_width(var_types.get(pump_reg, ""))
    if target_index_width is None:
        return text

    for dep in sorted(live_deps):
        if dep in excluded:
            continue
        typ = var_types.get(dep, "")
        if "[" not in typ or "]" not in typ:
            continue
        if not _is_stateful_register_array(dep, var_types):
            continue
        if array_index_width(typ) != target_index_width:
            continue
        text = replace_array_select_index(text, dep, index_expr)
    text = replace_equalities_with_register_readback(text, var_types=var_types, index_expr=index_expr)
    return normalize_expr(text)


def replace_equalities_with_register_readback(
    expr: str,
    *,
    var_types: Dict[str, str],
    index_expr: str,
) -> str:
    cur = normalize_expr(expr)
    negated = False
    inner = negated_predicate_inner(cur)
    if inner:
        cur = inner
        negated = True

    op = "!=" if "!=" in cur else "==" if "==" in cur else ""
    if not op:
        return expr
    parts = cur.split(op, 1)
    if len(parts) != 2:
        return expr
    left = strip_wrapping_parens(parts[0].strip())
    right = strip_wrapping_parens(parts[1].strip())
    slot_left = register_slot_expr_for_readback_temp(left, var_types=var_types, index_expr=index_expr)
    slot_right = register_slot_expr_for_readback_temp(right, var_types=var_types, index_expr=index_expr)
    if slot_left and not slot_right:
        new_inner = f"{right} {op} {slot_left}"
    elif slot_right and not slot_left:
        new_inner = f"{left} {op} {slot_right}"
    else:
        return expr
    return f"!({new_inner})" if negated else new_inner


def negated_predicate_inner(expr: str) -> Optional[str]:
    s = expr.strip()
    if not s.startswith("!"):
        return None
    inner = s[1:].strip()
    if not inner:
        return None
    return strip_wrapping_parens(inner)


def register_slot_expr_for_readback_temp(
    name: str,
    *,
    var_types: Dict[str, str],
    index_expr: str,
) -> Optional[str]:
    if name not in var_types:
        return None
    if not (name.startswith("tmp_") or "_tmp_" in name or "tmp_" in name):
        return None
    prefixes: List[str] = []
    if "_tmp_" in name:
        prefixes.append(name.split("_tmp_", 1)[0])
    if name.startswith("tmp_"):
        prefixes.append("")
    if "_" in name:
        prefixes.append(name.split("_", 1)[0])
    suffix = name.rsplit("_", 1)[0]
    suffix = suffix.replace("_tmp_", "_")
    if suffix and suffix != name:
        prefixes.append(suffix)
    prefixes = unique([p for p in prefixes if p is not None])
    register_arrays = [
        v
        for v, typ in var_types.items()
        if "[" in typ and "]" in typ and _is_stateful_register_array(v, var_types)
    ]
    if not register_arrays:
        register_arrays = [v for v, typ in var_types.items() if "[" in typ and "]" in typ]
    matches: List[str] = []
    compact_name = name.replace("_tmp_", "_")
    for arr in register_arrays:
        if array_index_width(var_types.get(arr, "")) is None:
            continue
        if arr in compact_name or compact_name in arr:
            matches.append(arr)
            continue
        arr_tail = arr.rsplit("_", 1)[-1]
        compact_tail = compact_name.rsplit("_", 1)[-1]
        if arr_tail and compact_tail and arr_tail.lower() == compact_tail.lower():
            matches.append(arr)
            continue
        if arr_tail and compact_name.lower().endswith("_" + arr_tail.lower()):
            matches.append(arr)
            continue
        if any(arr.startswith(p + "_") for p in prefixes if p):
            tail = arr.rsplit("_", 1)[-1]
            if tail and tail in compact_name:
                matches.append(arr)
    matches = unique(matches)
    if len(matches) == 1:
        return f"{matches[0]}[{index_expr}]"
    return None


def _substitute_tokens(expr: str, mapping: Dict[str, str]) -> str:
    if not mapping:
        return expr

    def repl(m: re.Match[str]) -> str:
        tok = m.group(0)
        return mapping.get(tok, tok)

    return _RE_IDENT.sub(repl, expr)
