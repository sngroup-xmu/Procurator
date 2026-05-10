from __future__ import annotations

import re
from typing import Dict, Iterable, Sequence, Set, Tuple

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.analysis.wraparound_projection_exprs import (
    _is_stateful_register_array,
    array_selects_in_expr,
    is_stable_cutpoint_var,
    manifest_array_selects_are_stable,
    normalize_expr,
    unique,
)
from dslc.analysis.wraparound_projection_support.state import is_snapshot_scalar


_RE_IDENT = re.compile(r"\b[A-Za-z_][A-Za-z0-9_.]*\b")
_RE_BRACKET_INDEX = re.compile(r"\[([^\[\]]+)\]")


def predicate_mentions_target_slots(expr: str, *, candidate: WraparoundCandidate) -> bool:
    target_arrays = set(unique([candidate.pump_reg, *candidate.accel_regs]))
    if not target_arrays:
        return False
    for sel in array_selects_in_expr(normalize_expr(str(expr))):
        if sel.array in target_arrays:
            return True
    return False


def is_cutpoint_shape_predicate(
    expr: str,
    *,
    var_types: Dict[str, str],
    default_state: Set[str],
    excluded: Set[str],
    target_arrays: Set[str],
    stable_indices: Iterable[str] = (),
) -> bool:
    normalized_expr = normalize_expr(expr)
    stable_index_set = {normalize_expr(v) for v in stable_indices if str(v).strip()}
    manifest_stable_arrays = manifest_array_selects_are_stable(normalized_expr, ignored=("true", "false", "old"))
    allowed_array_selects: Set[str] = set()
    array_index_tokens: Set[str] = set()
    for sel in array_selects_in_expr(normalized_expr):
        if sel.array in excluded and sel.array not in target_arrays:
            return False
        if stable_index_set and normalize_expr(sel.index) not in stable_index_set:
            continue
        allowed_array_selects.add(sel.array)
        array_index_tokens.update(_RE_IDENT.findall(sel.index))
    for m in _RE_BRACKET_INDEX.finditer(normalized_expr):
        array_index_tokens.update(_RE_IDENT.findall(m.group(1)))
    state_vars = {tok for tok in _RE_IDENT.findall(expr) if tok in var_types}
    if not state_vars:
        return False
    for v in state_vars:
        if v in excluded and v not in target_arrays:
            return False
        if v in array_index_tokens:
            continue
        typ = var_types.get(v, "")
        if "[" in typ or "]" in typ:
            if v in target_arrays:
                if not stable_index_set or v in allowed_array_selects:
                    continue
                return False
            if manifest_stable_arrays and v in allowed_array_selects:
                continue
            if _is_stateful_register_array(v, var_types):
                continue
            return False
        if v in default_state:
            continue
        if is_stable_cutpoint_var(v):
            continue
        return False
    return True


def is_stable_projection_predicate(
    expr: str,
    *,
    var_types: Dict[str, str],
    default_state: Set[str],
    excluded: Set[str],
) -> bool:
    state_vars = {tok for tok in _RE_IDENT.findall(expr) if tok in var_types}
    if not state_vars:
        return False
    for v in state_vars:
        if v in excluded:
            return False
        if not is_snapshot_scalar(v, var_types):
            return False
        if v in default_state:
            continue
        if not is_stable_cutpoint_var(v):
            return False
    return True


def stable_assumption_predicates(
    records: Sequence[object],
    *,
    stable_substitutions: Iterable[Tuple[str, str]] = (),
    stable_consts: Dict[str, str],
) -> Set[str]:
    subst = dict(stable_substitutions or ())
    subst.update(stable_consts)
    stable_tokens = {tok for tok in subst if str(tok).strip()}
    out: Set[str] = set()
    for rec in records:
        if int(getattr(rec, "depth", 0)) != 0:
            continue
        rec_deps = {str(dep).strip() for dep in getattr(rec, "deps", ()) if str(dep).strip()}
        if rec_deps and not rec_deps.issubset(stable_tokens):
            # Only treat unguarded assumptions over stable substitutions/constants
            # as globally stable predicates.
            continue
        expr = normalize_expr(_substitute_tokens(str(getattr(rec, "expr", "")), subst))
        if expr and expr != "true":
            out.add(expr)
    return out


def stable_predicate_bool(expr: str, stable_predicates: Set[str]) -> bool | None:
    cur = normalize_expr(expr)
    true_evidence = False
    false_evidence = False

    if cur in stable_predicates:
        true_evidence = True
    complement = _predicate_complement(cur)
    if complement and complement in stable_predicates:
        false_evidence = True

    neg_inner = _negated_inner(cur)
    if neg_inner:
        if neg_inner in stable_predicates:
            false_evidence = True
        complement = _predicate_complement(neg_inner)
        if complement and complement in stable_predicates:
            true_evidence = True

    if true_evidence and false_evidence:
        return None
    if true_evidence:
        return True
    if false_evidence:
        return False
    return None


def _predicate_complement(expr: str) -> str:
    m = re.match(r"^(?P<lhs>.+?)\s*==\s*(?P<rhs>.+)$", expr)
    if m:
        return normalize_expr(f"{m.group('lhs').strip()} != {m.group('rhs').strip()}")
    m = re.match(r"^(?P<lhs>.+?)\s*!=\s*(?P<rhs>.+)$", expr)
    if m:
        return normalize_expr(f"{m.group('lhs').strip()} == {m.group('rhs').strip()}")
    return ""


def _negated_inner(expr: str) -> str:
    s = expr.strip()
    if not s.startswith("!"):
        return ""
    return normalize_expr(s[1:].strip())


def _substitute_tokens(expr: str, mapping: Dict[str, str]) -> str:
    if not mapping:
        return expr

    def repl(m: re.Match[str]) -> str:
        tok = m.group(0)
        return mapping.get(tok, tok)

    return _RE_IDENT.sub(repl, expr)
