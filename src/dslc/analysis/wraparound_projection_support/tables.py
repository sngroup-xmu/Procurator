from __future__ import annotations

import re
from typing import Dict, Optional, Sequence, Tuple

from dslc.analysis.wraparound_projection_exprs import normalize_expr, strip_wrapping_parens


_RE_GOTO = re.compile(r"^\s*goto\s+(?P<labels>[^;]+)\s*;\s*$")
_RE_LABEL = re.compile(r"^\s*(?P<label>[A-Za-z_][A-Za-z0-9_.$]*)\s*:\s*$")
_RE_ASSUME_EQ = re.compile(
    r"^\s*assume\s+\(?\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*==\s*(?P<rhs>[^;)]+)\s*\)?\s*;\s*$"
)


def select_p4b_table_apply_body(
    *,
    proc_name: str,
    body: Sequence[str],
    stable_exprs: Dict[str, str],
    current_exprs: Dict[str, str],
) -> Optional[Tuple[str, ...]]:
    """Return the feasible P4B table-action branch when action_run is fixed."""

    if not proc_name.endswith(".apply"):
        return None
    table = proc_name[: -len(".apply")]
    action_var = f"{table}.action_run"
    selected = _stable_value(action_var, stable_exprs=stable_exprs, current_exprs=current_exprs)
    if not selected:
        return None

    goto_idx = _first_multitarget_goto(body)
    if goto_idx is None:
        return None
    branch = _branch_for_action(body, action_var=action_var, selected=selected)
    if branch is None:
        return None

    prefix = [ln for ln in body[:goto_idx] if not _RE_GOTO.match(ln.strip())]
    return tuple([*prefix, *branch])


def _stable_value(name: str, *, stable_exprs: Dict[str, str], current_exprs: Dict[str, str]) -> str:
    raw = stable_exprs.get(name) or current_exprs.get(name) or ""
    value = _clean(raw)
    return "" if not value or value == name else value


def _first_multitarget_goto(body: Sequence[str]) -> Optional[int]:
    for idx, line in enumerate(body):
        m = _RE_GOTO.match(line.strip())
        if not m:
            continue
        labels = [part.strip() for part in m.group("labels").split(",") if part.strip()]
        if len(labels) > 1:
            return idx
    return None


def _branch_for_action(body: Sequence[str], *, action_var: str, selected: str) -> Optional[Tuple[str, ...]]:
    labels = [idx for idx, line in enumerate(body) if _RE_LABEL.match(line.strip())]
    labels.append(len(body))
    for pos, start in enumerate(labels[:-1]):
        end = labels[pos + 1]
        branch = body[start + 1 : end]
        if not _branch_matches(branch, action_var=action_var, selected=selected):
            continue
        out = []
        for line in branch:
            s = line.strip()
            if _RE_GOTO.match(s):
                break
            if _is_action_assume(s, action_var=action_var):
                continue
            out.append(line)
        return tuple(out)
    return None


def _branch_matches(branch: Sequence[str], *, action_var: str, selected: str) -> bool:
    for line in branch:
        m = _RE_ASSUME_EQ.match(line.strip())
        if not m or m.group("lhs").strip() != action_var:
            continue
        return _same_expr(m.group("rhs"), selected)
    return False


def _is_action_assume(stmt: str, *, action_var: str) -> bool:
    m = _RE_ASSUME_EQ.match(stmt)
    return bool(m and m.group("lhs").strip() == action_var)


def _same_expr(left: str, right: str) -> bool:
    return _clean(left) == _clean(right)


def _clean(expr: str) -> str:
    return strip_wrapping_parens(normalize_expr(str(expr or "").strip()))
