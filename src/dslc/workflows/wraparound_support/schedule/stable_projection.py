from __future__ import annotations

import re
from typing import Iterable, List, Sequence, Tuple

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.analysis.wraparound_projection_exprs import normalize_expr

_RE_IDENT = re.compile(r"\b[A-Za-z_][A-Za-z0-9_.]*\b")
_RE_BV_LIT = re.compile(r"^\d+bv\d+$")
_RE_FUNC_CALL = re.compile(r"\b([A-Za-z_][A-Za-z0-9_.$]*)\s*\(")


def stable_substitution_env_shape_assumes(
    *,
    candidate: WraparoundCandidate,
    live_deps: Sequence[str] = (),
    cutpoint_predicates: Sequence[str] = (),
) -> Tuple[str, ...]:
    """
    Build replay-time env-shape assumptions from candidate stable substitutions.

    P4B/candidate recovery may know that a dynamic update path is tied to a
    fixed packet or metadata shape, for example `hdr.int.dscp == 32bv6`.  Such a
    fact constrains replay inputs, not closure projection equality.  We therefore
    apply it as a stage assumption (ENTRY/NEAR_WRAP/CLOSURE), and keep it out of:
    1) projection predicates (closure-stable invariants)
    2) witness-only `closure_assumes`.
    """

    del live_deps, cutpoint_predicates
    substitutions = tuple(getattr(candidate, "stable_substitutions", ()) or ())
    if not substitutions:
        return ()

    out: List[str] = []
    # Keep env-shape assumptions lightweight and solver-friendly:
    # - preserve literal/equality pins,
    # - skip call-heavy equalities (e.g. hash/get$...) that are already reflected
    #   by concrete constant substitutions in modern candidates and can make
    #   prefix ENTRY much harder without adding useful pruning.
    has_concrete_pin = any(_looks_like_concrete_pin(rhs) for _lhs, rhs in substitutions)
    for lhs, rhs in substitutions:
        lhs = str(lhs or "").strip()
        rhs = normalize_expr(str(rhs or "").strip())
        if not lhs or not rhs:
            continue
        if has_concrete_pin and _expr_has_call(rhs):
            continue
        out.append(f"{lhs} == {rhs}")
    return tuple(_unique(out))


def stable_substitution_projection_predicates(
    *,
    candidate: WraparoundCandidate,
    live_deps: Sequence[str] = (),
    cutpoint_predicates: Sequence[str] = (),
) -> Tuple[str, ...]:
    """
    Backward-compatible alias.

    Historically, callers treated these substitutions as projection predicates.
    The schedule-replay certified path now interprets them as env-shape assumes.
    """

    return stable_substitution_env_shape_assumes(
        candidate=candidate,
        live_deps=live_deps,
        cutpoint_predicates=cutpoint_predicates,
    )


def _vars_in_expr(expr: str) -> set[str]:
    functions = set(_RE_FUNC_CALL.findall(expr))
    function_prefixes = {fn.split("$", 1)[0] for fn in functions}
    out: set[str] = set()
    for tok in _RE_IDENT.findall(expr):
        if tok in functions or tok in function_prefixes:
            continue
        if tok in {"true", "false", "old"}:
            continue
        if tok.startswith("bv") or _RE_BV_LIT.match(tok):
            continue
        out.add(tok)
    return out


def _expr_has_call(expr: str) -> bool:
    return bool(_RE_FUNC_CALL.search(str(expr or "")))


def _looks_like_concrete_pin(expr: str) -> bool:
    s = normalize_expr(str(expr or "").strip())
    if not s:
        return False
    if _RE_BV_LIT.match(s):
        return True
    if s in {"true", "false"}:
        return True
    return False


def _unique(values: Iterable[str]) -> List[str]:
    seen: set[str] = set()
    out: List[str] = []
    for raw in values:
        value = str(raw or "").strip()
        if not value or value in seen:
            continue
        seen.add(value)
        out.append(value)
    return out
