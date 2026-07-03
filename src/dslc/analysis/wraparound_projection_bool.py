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
    m = re.match(r"^(?P<op>b(?:ult|ule|ugt|uge|slt|sle|sgt|sge))\.bv(?P<w>\d+)\((?P<args>.*)\)$", s)
    if m:
        args = [literal(part) for part in split_top_level_args(m.group("args"))]
        if len(args) != 2 or args[0] is None or args[1] is None:
            return None
        return _eval_bv_cmp(m.group("op"), int(args[0].split("bv", 1)[0]), int(args[1].split("bv", 1)[0]), int(m.group("w")))
    return None


def split_top_level_args(expr: str) -> List[str]:
    parts: List[str] = []
    depth = 0
    start = 0
    for i, ch in enumerate(expr):
        if ch in "([{":
            depth += 1
        elif ch in ")]}" and depth > 0:
            depth -= 1
        elif ch == "," and depth == 0:
            parts.append(expr[start:i].strip())
            start = i + 1
    tail = expr[start:].strip()
    if tail:
        parts.append(tail)
    return parts


def _eval_bv_cmp(op: str, left: int, right: int, width: int) -> bool:
    mask = (1 << width) - 1
    left &= mask
    right &= mask
    if op in {"bult", "bslt"}:
        return left < right
    if op in {"bule", "bsle"}:
        return left <= right
    if op in {"bugt", "bsgt"}:
        return left > right
    if op in {"buge", "bsge"}:
        return left >= right
    return False


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
