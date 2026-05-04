from __future__ import annotations

import re
from typing import List, Optional

from dslc.analysis.wraparound_projection_exprs import normalize_expr as _normalize_expr
from dslc.analysis.wraparound_projection_exprs import strip_wrapping_parens as _strip_wrapping_parens


_RE_BV_LIT = re.compile(r"^(?P<val>\d+)bv(?P<w>\d+)$")


def constant_bool_expr(expr: str) -> Optional[bool]:
    s = _strip_wrapping_parens(_normalize_expr(expr))
    if "[" in s or "]" in s:
        if "&&" not in s and "||" not in s:
            return None
    if "=>" in s or "<" in s or ">" in s:
        return None
    parts = split_top_level_bool(s, "||")
    if len(parts) > 1:
        saw_unknown = False
        for part in parts:
            val = constant_bool_expr(part)
            if val is True:
                return True
            if val is None:
                saw_unknown = True
        return None if saw_unknown else False
    parts = split_top_level_bool(s, "&&")
    if len(parts) > 1:
        saw_unknown = False
        for part in parts:
            val = constant_bool_expr(part)
            if val is False:
                return False
            if val is None:
                saw_unknown = True
        return None if saw_unknown else True
    if s == "true":
        return True
    if s == "false":
        return False
    if s.startswith("!"):
        inner = constant_bool_expr(s[1:].strip())
        return None if inner is None else not inner

    def literal(raw: str) -> Optional[str]:
        cur = _strip_wrapping_parens(raw.strip())
        if cur in {"true", "false"}:
            return cur
        if re.match(r"^-?\d+$", cur):
            return cur
        if _RE_BV_LIT.match(cur):
            return cur
        return None

    m = re.match(r"^(?P<lhs>.+?)\s*==\s*(?P<rhs>.+)$", s)
    if m:
        lhs = literal(m.group("lhs"))
        rhs = literal(m.group("rhs"))
        return None if lhs is None or rhs is None else lhs == rhs
    m = re.match(r"^(?P<lhs>.+?)\s*!=\s*(?P<rhs>.+)$", s)
    if m:
        lhs = literal(m.group("lhs"))
        rhs = literal(m.group("rhs"))
        return None if lhs is None or rhs is None else lhs != rhs
    return None


def split_top_level_bool(expr: str, op: str) -> List[str]:
    parts: List[str] = []
    depth = 0
    start = 0
    i = 0
    n = len(expr)
    while i < n:
        ch = expr[i]
        if ch == "(":
            depth += 1
            i += 1
            continue
        if ch == ")":
            depth -= 1
            i += 1
            continue
        if depth == 0 and expr.startswith(op, i):
            parts.append(expr[start:i].strip())
            i += len(op)
            start = i
            continue
        i += 1
    if parts:
        parts.append(expr[start:].strip())
    return [p for p in parts if p]
