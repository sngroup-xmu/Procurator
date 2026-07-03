from __future__ import annotations

import re
from typing import Dict, Sequence

from dslc.analysis.boogie_bv_eval import BvValue, eval_bv_expr


_RE_ASSIGN = re.compile(r"^(?P<indent>\s*)(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*(?P<rhs>.*);\s*$")
_RE_ASSUME_EQ = re.compile(
    r"^\s*assume\s+\(?\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*==\s*(?P<rhs>\d+bv\d+)\s*\)?\s*;\s*$"
)
_RE_HAVOC = re.compile(r"^\s*havoc\s+(?P<vars>[^;]+)\s*;\s*$")
_RE_PROC_HEADER = re.compile(r"^\s*procedure(?:\s+\{[^}]*\})?\s+[A-Za-z_][A-Za-z0-9_.]*\(")
_RE_LABEL = re.compile(r"^\s*[A-Za-z_][A-Za-z0-9_.$]*\s*:\s*$")
_RE_CONTROL_BOUNDARY = re.compile(r"^\s*(?:if|else|while|goto|return|call|assert)\b")
_RE_BLOCK_BOUNDARY = re.compile(r"^\s*\}?\s*(?:else\s*)?\{?\s*$")


def simplify_bv_constant_assignments(lines: list[str], *, var_types: Dict[str, str]) -> None:
    """
    Fold Boogie bit-vector assignments whose RHS is concrete in local context.

    This is intentionally lightweight and local to a straight-line scan. It keeps
    only definite BV literals from `assume x == C`, simple assignments, and the
    precise CRC/BV expression evaluator.  Havoc kills facts, and non-BV writes
    are left untouched.
    """

    env: Dict[str, int] = {}
    for i, line in enumerate(lines):
        if _kills_straight_line_facts(line):
            env.clear()
            continue

        mh = _RE_HAVOC.match(line)
        if mh:
            for name in _split_vars(mh.group("vars")):
                env.pop(name, None)
            continue

        ma = _RE_ASSUME_EQ.match(line)
        if ma and _is_bv_var(ma.group("lhs"), var_types):
            lhs = ma.group("lhs")
            lit = _eval_literal(ma.group("rhs"), var_types.get(lhs, ""))
            if lit is not None:
                env[lhs] = lit.value
            continue

        m = _RE_ASSIGN.match(line)
        if not m:
            continue
        lhs = m.group("lhs")
        if not _is_bv_var(lhs, var_types):
            env.pop(lhs, None)
            continue

        rhs = m.group("rhs").strip()
        value = eval_bv_expr(rhs, const_eq=env, var_types=var_types)
        if value is None or value.width != _bv_width(var_types[lhs]):
            env.pop(lhs, None)
            continue
        env[lhs] = value.value
        folded = f"{value.value}bv{value.width}"
        if folded != rhs:
            lines[i] = f"{m.group('indent')}{lhs} := {folded};\n"


def rewrite_stable_bv_assignments(lines: list[str], *, assumptions: Sequence[str], var_types: Dict[str, str]) -> None:
    """Rewrite assignments to stable BV variables using literal stage assumptions."""

    literals = _literal_equalities(assumptions, var_types=var_types)
    if not literals:
        return
    for i, line in enumerate(lines):
        m = _RE_ASSIGN.match(line)
        if not m:
            continue
        lhs = m.group("lhs")
        literal = literals.get(lhs)
        if literal is None:
            continue
        lines[i] = f"{m.group('indent')}{lhs} := {literal};\n"


def _split_vars(raw: str) -> Sequence[str]:
    return [part.strip() for part in raw.split(",") if part.strip()]


def _kills_straight_line_facts(line: str) -> bool:
    stripped = line.strip()
    if not stripped or stripped.startswith("//"):
        return False
    if _RE_PROC_HEADER.match(line):
        return True
    if _RE_LABEL.match(line):
        return True
    if _RE_CONTROL_BOUNDARY.match(line):
        return True
    if _RE_BLOCK_BOUNDARY.match(line):
        return True
    return False


def _is_bv_var(name: str, var_types: Dict[str, str]) -> bool:
    return _bv_width(var_types.get(name, "")) is not None


def _bv_width(typ: str) -> int | None:
    m = re.match(r"^bv(?P<w>\d+)$", typ.strip())
    return int(m.group("w")) if m else None


def _eval_literal(expr: str, typ: str) -> BvValue | None:
    width = _bv_width(typ)
    if width is None:
        return None
    value = eval_bv_expr(expr, const_eq={}, var_types={})
    if value is None or value.width != width:
        return None
    return value


def _literal_equalities(assumptions: Sequence[str], *, var_types: Dict[str, str]) -> Dict[str, str]:
    out: Dict[str, str] = {}
    for raw in assumptions:
        text = str(raw or "").strip()
        if text.startswith("assume(") and text.endswith(")"):
            text = text[len("assume(") : -1].strip()
        if text.startswith("assume "):
            text = text[len("assume ") :].strip()
        if text.endswith(";"):
            text = text[:-1].strip()
        while text.startswith("(") and text.endswith(")"):
            text = text[1:-1].strip()
        m = re.match(r"^(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*==\s*(?P<rhs>\d+bv\d+)$", text)
        if not m:
            continue
        lhs = m.group("lhs")
        rhs = m.group("rhs")
        if _eval_literal(rhs, var_types.get(lhs, "")) is not None:
            out[lhs] = rhs
    return out
