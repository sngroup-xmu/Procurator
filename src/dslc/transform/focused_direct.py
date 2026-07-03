from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Dict, Optional, Tuple

from dslc.analysis.boogie_bv_eval import bv_width, eval_bv_expr


@dataclass(frozen=True)
class FocusedDirectResult:
    changed: bool
    text: str
    reason: str
    target_reg: Optional[str] = None
    idx_var: Optional[str] = None
    zero: Optional[str] = None
    target_value: Optional[str] = None
    target_old_value: Optional[str] = None
    target_slice: Optional[Tuple[int, int]] = None
    assert_line: Optional[int] = None
    assert_lines: Tuple[int, ...] = ()


_RE_TYPE_ALIAS = re.compile(r"^\s*type\s+(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\s*=\s*(?P<rhs>[^;]+);\s*$")
_RE_VAR_DECL = re.compile(r"^\s*var\s+(?P<name>\S+)\s*:\s*(?P<type>[^;]+);\s*$")
_RE_REG_ARRAY_TYPE = re.compile(r"^\[(?P<idx>bv\d+)\](?P<val>bv\d+)$")
_RE_READ = re.compile(
    r"^(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*"
    r"(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)\.read\("
    r"(?P=reg),\s*(?P<idx>[A-Za-z_][A-Za-z0-9_.]*)\);$"
)
_RE_WRITE = re.compile(
    r"^call\s+(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)\.write\("
    r"(?P<idx>[A-Za-z_][A-Za-z0-9_.]*),\s*(?P<value>.+)\);$"
)
_RE_ASSERT_TARGET = re.compile(
    r"assert\s+!\(\((?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"\((?P=reg)__last_value\s*==\s*(?P<value>\d+bv\d+)\)\)\);"
)
_RE_ASSERT_TARGET_SLICE = re.compile(
    r"assert\s+!\(\((?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"\((?P=reg)__last_value\[(?P<hi>\d+):(?P<lo>\d+)\]\s*==\s*(?P<value>\d+bv\d+)\)\)\);"
)
_RE_ASSERT_TARGET_OLDNEW = re.compile(
    r"assert\s+!\(\((?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"\((?P=reg)__last_old_value\s*==\s*(?P<old>\d+bv\d+)\)\s*&&\s*"
    r"\((?P=reg)__last_value\s*==\s*(?P<value>\d+bv\d+)\)\)\);"
)
_RE_ACTION_RUN_IF = re.compile(
    r"^if\s*\(\s*\(?\s*(?P<table>[A-Za-z_][A-Za-z0-9_.]*)\.action_run\s*==\s*"
    r"(?P=table)\.action\.(?P<action>[A-Za-z_][A-Za-z0-9_.]*)\s*\)?\s*\)\s*\{\s*$"
)
_RE_ASSERT_TARGET_INDEX0 = re.compile(
    r"assert\s+!\(\((?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_index0\s*&&\s*"
    r"\((?P=reg)__last0_value\s*==\s*(?P<value>\d+bv\d+)\)\)\);"
)
_RE_ASSERT_TARGET_INDEX0_SLICE = re.compile(
    r"assert\s+!\(\((?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_index0\s*&&\s*"
    r"\((?P=reg)__last0_value\[(?P<hi>\d+):(?P<lo>\d+)\]\s*==\s*(?P<value>\d+bv\d+)\)\)\);"
)
_RE_ASSERT_TARGET_INDEX0_OLDNEW = re.compile(
    r"assert\s+!\(\((?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_index0\s*&&\s*"
    r"\((?P=reg)__last0_old_value\s*==\s*(?P<old>\d+bv\d+)\)\s*&&\s*"
    r"\((?P=reg)__last0_value\s*==\s*(?P<value>\d+bv\d+)\)\)\);"
)
_RE_ASSERT_TARGET_SLOT = re.compile(
    r"assert\s+!\(\((?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"\((?P=reg)__last_index\s*==\s*(?P<slot>\d+bv\d+)\)\s*&&\s*"
    r"\((?P=reg)__last_value\s*==\s*(?P<value>\d+bv\d+)\)\)\);"
)
_RE_ASSERT_TARGET_SLOT_SLICE = re.compile(
    r"assert\s+!\(\((?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"\((?P=reg)__last_index\s*==\s*(?P<slot>\d+bv\d+)\)\s*&&\s*"
    r"\((?P=reg)__last_value\[(?P<hi>\d+):(?P<lo>\d+)\]\s*==\s*(?P<value>\d+bv\d+)\)\)\);"
)
_RE_ASSERT_TARGET_SLOT_OLDNEW = re.compile(
    r"assert\s+!\(\((?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"\((?P=reg)__last_index\s*==\s*(?P<slot>\d+bv\d+)\)\s*&&\s*"
    r"\((?P=reg)__last_old_value\s*==\s*(?P<old>\d+bv\d+)\)\s*&&\s*"
    r"\((?P=reg)__last_value\s*==\s*(?P<value>\d+bv\d+)\)\)\);"
)
_RE_FAIL_FAST_IF = re.compile(
    r"if\s*\(\s*(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"(?P=reg)__last_value\s*==\s*(?P<value>\d+bv\d+)\s*\)\s*\{"
)
_RE_FAIL_FAST_OLDNEW_IF = re.compile(
    r"if\s*\(\s*(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"(?P=reg)__last_old_value\s*==\s*(?P<old>\d+bv\d+)\s*&&\s*"
    r"(?P=reg)__last_value\s*==\s*(?P<value>\d+bv\d+)\s*\)\s*\{"
)
_RE_FAIL_FAST_INDEX0_IF = re.compile(
    r"if\s*\(\s*(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_index0\s*&&\s*"
    r"(?P=reg)__last0_value\s*==\s*(?P<value>\d+bv\d+)\s*\)\s*\{"
)
_RE_FAIL_FAST_INDEX0_OLDNEW_IF = re.compile(
    r"if\s*\(\s*(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_index0\s*&&\s*"
    r"(?P=reg)__last0_old_value\s*==\s*(?P<old>\d+bv\d+)\s*&&\s*"
    r"(?P=reg)__last0_value\s*==\s*(?P<value>\d+bv\d+)\s*\)\s*\{"
)
_RE_FAIL_FAST_INDEX0_SLICE_IF = re.compile(
    r"if\s*\(\s*(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_index0\s*&&\s*"
    r"(?P=reg)__last0_value\[(?P<hi>\d+):(?P<lo>\d+)\]\s*==\s*(?P<value>\d+bv\d+)\s*\)\s*\{"
)
_RE_FAIL_FAST_SLOT_IF = re.compile(
    r"if\s*\(\s*(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"(?P=reg)__last_index\s*==\s*(?P<slot>\d+bv\d+)\s*&&\s*"
    r"(?P=reg)__last_value\s*==\s*(?P<value>\d+bv\d+)\s*\)\s*\{"
)
_RE_FAIL_FAST_SLOT_SLICE_IF = re.compile(
    r"if\s*\(\s*(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"(?P=reg)__last_index\s*==\s*(?P<slot>\d+bv\d+)\s*&&\s*"
    r"(?P=reg)__last_value\[(?P<hi>\d+):(?P<lo>\d+)\]\s*==\s*(?P<value>\d+bv\d+)\s*\)\s*\{"
)
_RE_FAIL_FAST_SLOT_OLDNEW_IF = re.compile(
    r"if\s*\(\s*(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"(?P=reg)__last_index\s*==\s*(?P<slot>\d+bv\d+)\s*&&\s*"
    r"(?P=reg)__last_old_value\s*==\s*(?P<old>\d+bv\d+)\s*&&\s*"
    r"(?P=reg)__last_value\s*==\s*(?P<value>\d+bv\d+)\s*\)\s*\{"
)
_RE_TRACK_TARGET = re.compile(
    r"^(?P<indent>\s*)if\s*\(\s*!\s*\(\s*!\s*\(\(\s*"
    r"(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"\((?P=reg)__last_value\s*==\s*(?P<value>\d+bv\d+)\)\s*"
    r"\)\)\s*\)\s*\)\s*\{\s*procurator_bad\s*:=\s*true\s*;\s*\}\s*$"
)
_RE_TRACK_TARGET_OLDNEW = re.compile(
    r"^(?P<indent>\s*)if\s*\(\s*!\s*\(\s*!\s*\(\(\s*"
    r"(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"\((?P=reg)__last_old_value\s*==\s*(?P<old>\d+bv\d+)\)\s*&&\s*"
    r"\((?P=reg)__last_value\s*==\s*(?P<value>\d+bv\d+)\)\s*"
    r"\)\)\s*\)\s*\)\s*\{\s*procurator_bad\s*:=\s*true\s*;\s*\}\s*$"
)
_RE_ASSERT_FALSE = re.compile(r"^\s*assert\s+false\s*;\s*$")
_RE_PROC_START = re.compile(r"^\s*procedure(?:\s*\{:[^}]*\}\s*)?\s+(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\s*\(")
_RE_ATTR = re.compile(r"\{:[^}]*\}")
_RE_GET_REGISTER_INDEX_CALL = re.compile(
    r"^\s*call\s+(?P<proc>[A-Za-z_][A-Za-z0-9_.]*get_register_index)\([^;]*\);\s*$"
)
_RE_META_INDEX_ASSIGN = re.compile(
    r"^\s*(?P<idx>[A-Za-z_][A-Za-z0-9_.]*register_index)\s*:=\s*"
    r"(?P<callee>[A-Za-z_][A-Za-z0-9_.$]*idx[A-Za-z0-9_.$]*\.get[^;]*);$"
)
_RE_SIMPLE_ASSIGN = re.compile(r"^(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*(?P<rhs>.*);$")
_RE_CALL_PROC = re.compile(r"^\s*call\s+(?P<proc>[A-Za-z_][A-Za-z0-9_.]*)\s*\([^;]*\)\s*;\s*$")


def _parse_var_types(text: str) -> Dict[str, str]:
    aliases = _parse_type_aliases(text)
    out: Dict[str, str] = {}
    for line in text.splitlines():
        m = _RE_VAR_DECL.match(line)
        if m:
            out[m.group("name")] = _resolve_type_alias(m.group("type").strip(), aliases)
    return out


def _parse_type_aliases(text: str) -> Dict[str, str]:
    aliases: Dict[str, str] = {}
    for line in text.splitlines():
        m = _RE_TYPE_ALIAS.match(line)
        if m:
            aliases[m.group("name")] = m.group("rhs").strip()
    changed = True
    while changed:
        changed = False
        for name, rhs in list(aliases.items()):
            cur = aliases.get(rhs, rhs)
            if cur != rhs:
                aliases[name] = cur
                changed = True
    return aliases


def _resolve_type_alias(typ: str, aliases: Dict[str, str]) -> str:
    cur = typ.strip()
    m = re.match(r"^\[(?P<idx>[^\]]+)\](?P<val>.+)$", cur)
    if m:
        idx = aliases.get(m.group("idx").strip(), m.group("idx").strip())
        val = aliases.get(m.group("val").strip(), m.group("val").strip())
        return f"[{idx}]{val}"
    seen: set[str] = set()
    while cur in aliases and cur not in seen:
        seen.add(cur)
        cur = aliases[cur]
    return cur


def _register_type(var_types: Dict[str, str], reg: str) -> Optional[Tuple[str, str]]:
    m = _RE_REG_ARRAY_TYPE.match(var_types.get(reg, ""))
    if not m:
        return None
    return m.group("idx"), m.group("val")


def _has_index0_mirrors(var_types: Dict[str, str], reg: str, idx_type: str, val_type: str) -> bool:
    return (
        var_types.get(f"{reg}__last_index") == idx_type
        and var_types.get(f"{reg}__last_value") == val_type
        and var_types.get(f"{reg}__wrote_any") == "bool"
        and var_types.get(f"{reg}__wrote_index0") == "bool"
        and var_types.get(f"{reg}__last0_value") == val_type
    )


def _has_old_value_mirrors(var_types: Dict[str, str], reg: str, val_type: str) -> bool:
    return (
        var_types.get(f"{reg}__last_old_value") == val_type
        and var_types.get(f"{reg}__last0_old_value") == val_type
    )


def _find_fail_fast_targets(text: str) -> list[Tuple[str, Optional[str], str, int]]:
    out: list[Tuple[str, Optional[str], str, int]] = []
    pending: Optional[Tuple[str, Optional[str], str]] = None

    for line_no, raw in enumerate(text.splitlines(), start=1):
        stripped = raw.strip()
        m_oldnew = _RE_FAIL_FAST_OLDNEW_IF.match(stripped)
        if m_oldnew:
            pending = (m_oldnew.group("reg"), m_oldnew.group("old"), m_oldnew.group("value"))
            continue
        m_if = _RE_FAIL_FAST_IF.match(stripped)
        if m_if:
            pending = (m_if.group("reg"), None, m_if.group("value"))
        elif pending is not None and _RE_ASSERT_FALSE.match(stripped):
            out.append((pending[0], pending[1], pending[2], line_no))
            pending = None
    return out


def _find_index0_fail_fast_targets(text: str) -> list[Tuple[str, Optional[str], str, Optional[Tuple[int, int]], int]]:
    out: list[Tuple[str, Optional[str], str, Optional[Tuple[int, int]], int]] = []
    pending: Optional[Tuple[str, Optional[str], str, Optional[Tuple[int, int]]]] = None

    for line_no, raw in enumerate(text.splitlines(), start=1):
        stripped = raw.strip()
        m_oldnew = _RE_FAIL_FAST_INDEX0_OLDNEW_IF.match(stripped)
        if m_oldnew:
            pending = (m_oldnew.group("reg"), m_oldnew.group("old"), m_oldnew.group("value"), None)
            continue
        m_if = _RE_FAIL_FAST_INDEX0_IF.match(stripped)
        if m_if:
            pending = (m_if.group("reg"), None, m_if.group("value"), None)
            continue
        if pending is None:
            m_slice = _RE_FAIL_FAST_INDEX0_SLICE_IF.match(stripped)
            if m_slice:
                pending = (
                    m_slice.group("reg"),
                    None,
                    m_slice.group("value"),
                    (int(m_slice.group("hi")), int(m_slice.group("lo"))),
                )
                continue
        if pending is not None and _RE_ASSERT_FALSE.match(stripped):
            out.append((pending[0], pending[1], pending[2], pending[3], line_no))
            pending = None
    return out


def _find_slot_fail_fast_targets(
    text: str,
    *,
    slot_literal: str,
) -> list[Tuple[str, str, Optional[Tuple[int, int]], int]]:
    out: list[Tuple[str, Optional[str], str, Optional[Tuple[int, int]], int]] = []
    pending: Optional[Tuple[str, Optional[str], str, Optional[Tuple[int, int]]]] = None

    for line_no, raw in enumerate(text.splitlines(), start=1):
        stripped = raw.strip()
        m_oldnew = _RE_FAIL_FAST_SLOT_OLDNEW_IF.match(stripped)
        if m_oldnew and m_oldnew.group("slot") == slot_literal:
            pending = (m_oldnew.group("reg"), m_oldnew.group("old"), m_oldnew.group("value"), None)
            continue
        m_if = _RE_FAIL_FAST_SLOT_IF.match(stripped)
        if m_if and m_if.group("slot") == slot_literal:
            pending = (m_if.group("reg"), None, m_if.group("value"), None)
            continue
        if pending is None:
            m_slice = _RE_FAIL_FAST_SLOT_SLICE_IF.match(stripped)
            if m_slice and m_slice.group("slot") == slot_literal:
                pending = (
                    m_slice.group("reg"),
                    None,
                    m_slice.group("value"),
                    (int(m_slice.group("hi")), int(m_slice.group("lo"))),
                )
                continue
        if pending is not None and _RE_ASSERT_FALSE.match(stripped):
            out.append((pending[0], pending[1], pending[2], pending[3], line_no))
            pending = None
    return out


def _collect_procedure_names(text: str) -> set[str]:
    return {m.group("name") for m in _RE_PROC_START.finditer(text)}


def _find_procedure_body_lines(text: str, proc_name: str) -> Optional[list[str]]:
    lines = text.splitlines()
    start: Optional[int] = None
    for i, raw in enumerate(lines):
        m = _RE_PROC_START.match(raw)
        if m and m.group("name") == proc_name:
            start = i
            break
    if start is None:
        return None

    body_open: Optional[int] = None
    for i in range(start, len(lines)):
        if "{" in _RE_ATTR.sub("", lines[i]):
            body_open = i
            break
        if i > start and _RE_PROC_START.match(lines[i]):
            return None
    if body_open is None:
        return None

    depth = 0
    body_close: Optional[int] = None
    for i in range(body_open, len(lines)):
        for ch in _RE_ATTR.sub("", lines[i]):
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    body_close = i
                    break
        if body_close is not None:
            break
    if body_close is None:
        return None
    return lines[body_open + 1 : body_close]


def _infer_table_action_proc(text: str, table: str, action: str) -> Optional[str]:
    table_body = _find_procedure_body_lines(text, f"{table}.apply")
    if table_body is not None:
        assume_re = re.compile(
            rf"\bassume\s+{re.escape(table)}\.action_run\s*==\s*"
            rf"{re.escape(table)}\.action\.{re.escape(action)}\s*;"
        )
        for i, raw in enumerate(table_body):
            if not assume_re.search(raw.strip()):
                continue
            callees: list[str] = []
            for lookahead in table_body[i + 1 : i + 8]:
                m_call = _RE_CALL_PROC.match(lookahead.strip())
                if m_call:
                    callees.append(m_call.group("proc"))
                    break
            if len(callees) == 1:
                return callees[0]

    proc_names = _collect_procedure_names(text)
    candidates: list[str] = [action]
    if "_" in table:
        alias = table.split("_", 1)[0]
        candidates.append(f"{alias}_{action}")
    table_parts = table.split("_")
    for n in range(1, min(len(table_parts), 4)):
        candidates.append("_".join(table_parts[:n] + [action]))

    for cand in candidates:
        if cand in proc_names:
            return cand
    return None


def _guard_action_proc_for_assert_line(text: str, line_no: int) -> Optional[str]:
    lines = text.splitlines()
    idx = line_no - 2
    while idx >= 0:
        stripped = lines[idx].strip()
        if not stripped or stripped.startswith("//"):
            idx -= 1
            continue
        m = _RE_ACTION_RUN_IF.match(stripped)
        if not m:
            return None
        return _infer_table_action_proc(text, m.group("table"), m.group("action"))
    return None


def _slice_expr(reg: str, target_slice: Optional[Tuple[int, int]], *, use_index0: bool = True) -> str:
    base = f"{reg}__last0_value" if use_index0 else f"{reg}__last_value"
    if target_slice is None:
        return base
    hi, lo = target_slice
    return f"{base}[{hi}:{lo}]"


def _target_bad_expr(
    reg: str,
    target_value: str,
    target_slice: Optional[Tuple[int, int]],
    *,
    use_index0: bool,
    slot_literal: Optional[str] = None,
    target_old_value: Optional[str] = None,
    parenthesize_eq: bool = False,
) -> str:
    def eq(lhs: str, rhs: str) -> str:
        expr = f"{lhs} == {rhs}"
        return f"({expr})" if parenthesize_eq else expr

    parts: list[str] = []
    if use_index0:
        parts.append(f"{reg}__wrote_index0")
        if target_old_value is not None:
            parts.append(eq(f"{reg}__last0_old_value", target_old_value))
        parts.append(eq(_slice_expr(reg, target_slice), target_value))
    else:
        parts.append(f"{reg}__wrote_any")
        if slot_literal is not None:
            parts.append(eq(f"{reg}__last_index", slot_literal))
        if target_old_value is not None:
            parts.append(eq(f"{reg}__last_old_value", target_old_value))
        parts.append(eq(_slice_expr(reg, target_slice, use_index0=False), target_value))
    return " && ".join(parts)


def _is_zero_literal(lit: str) -> bool:
    m = re.match(r"^(?P<val>\d+)bv\d+$", lit.strip())
    return bool(m and int(m.group("val")) == 0)


def _find_assert_lines(
    text: str,
    target_reg: str,
    target_value: str,
    target_slice: Optional[Tuple[int, int]] = None,
    slot_literal: Optional[str] = None,
    target_old_value: Optional[str] = None,
) -> Tuple[int, ...]:
    lines = text.splitlines()
    out: list[int] = []
    use_index0 = slot_literal is None or _is_zero_literal(slot_literal)
    for i, line in enumerate(lines, start=1):
        if use_index0:
            m_oldnew = _RE_ASSERT_TARGET_INDEX0_OLDNEW.search(line)
            if (
                target_old_value is not None
                and target_slice is None
                and m_oldnew
                and m_oldnew.group("reg") == target_reg
                and m_oldnew.group("old") == target_old_value
                and m_oldnew.group("value") == target_value
            ):
                out.append(i)
            m_index0 = _RE_ASSERT_TARGET_INDEX0.search(line)
            if (
                target_old_value is None
                and
                target_slice is None
                and m_index0
                and m_index0.group("reg") == target_reg
                and m_index0.group("value") == target_value
            ):
                out.append(i)
            m_slice = _RE_ASSERT_TARGET_INDEX0_SLICE.search(line)
            if (
                target_old_value is None
                and
                target_slice is not None
                and m_slice
                and m_slice.group("reg") == target_reg
                and m_slice.group("value") == target_value
                and (int(m_slice.group("hi")), int(m_slice.group("lo"))) == target_slice
            ):
                out.append(i)
        elif slot_literal is not None:
            m_oldnew = _RE_ASSERT_TARGET_SLOT_OLDNEW.search(line)
            if (
                target_old_value is not None
                and target_slice is None
                and m_oldnew
                and m_oldnew.group("reg") == target_reg
                and m_oldnew.group("slot") == slot_literal
                and m_oldnew.group("old") == target_old_value
                and m_oldnew.group("value") == target_value
            ):
                out.append(i)
            m_slot = _RE_ASSERT_TARGET_SLOT.search(line)
            if (
                target_old_value is None
                and
                target_slice is None
                and m_slot
                and m_slot.group("reg") == target_reg
                and m_slot.group("slot") == slot_literal
                and m_slot.group("value") == target_value
            ):
                out.append(i)
            m_slot_slice = _RE_ASSERT_TARGET_SLOT_SLICE.search(line)
            if (
                target_old_value is None
                and
                target_slice is not None
                and m_slot_slice
                and m_slot_slice.group("reg") == target_reg
                and m_slot_slice.group("slot") == slot_literal
                and m_slot_slice.group("value") == target_value
                and (int(m_slot_slice.group("hi")), int(m_slot_slice.group("lo"))) == target_slice
            ):
                out.append(i)
    if use_index0:
        for reg, old, value, found_slice, line_no in _find_index0_fail_fast_targets(text):
            if (
                reg == target_reg
                and old == target_old_value
                and value == target_value
                and found_slice == target_slice
            ):
                out.append(line_no)
    elif slot_literal is not None:
        for reg, old, value, found_slice, line_no in _find_slot_fail_fast_targets(text, slot_literal=slot_literal):
            if (
                reg == target_reg
                and old == target_old_value
                and value == target_value
                and found_slice == target_slice
            ):
                out.append(line_no)
    return tuple(out)


def find_focused_direct_assert_lines(
    text: str,
    target_reg: str,
    target_value: str,
    target_slice: Optional[Tuple[int, int]] = None,
    slot_literal: Optional[str] = None,
    target_old_value: Optional[str] = None,
) -> Tuple[int, ...]:
    """Return focused assertion lines in the exact Boogie text given."""

    return _find_assert_lines(text, target_reg, target_value, target_slice, slot_literal, target_old_value)


def _find_assert_target(
    text: str,
    var_types: Dict[str, str],
) -> Optional[Tuple[str, str, str, Optional[str], str, Optional[Tuple[int, int]], Tuple[int, ...], bool, Optional[str]]]:
    direct_matches = [
        (
            m.group("reg"),
            None,
            m.group("value"),
            None,
            text.count("\n", 0, m.start()) + 1,
            False,
            _guard_action_proc_for_assert_line(text, text.count("\n", 0, m.start()) + 1),
        )
        for m in _RE_ASSERT_TARGET.finditer(text)
    ]
    direct_matches.extend(
        (
            m.group("reg"),
            m.group("old"),
            m.group("value"),
            None,
            text.count("\n", 0, m.start()) + 1,
            False,
            _guard_action_proc_for_assert_line(text, text.count("\n", 0, m.start()) + 1),
        )
        for m in _RE_ASSERT_TARGET_OLDNEW.finditer(text)
    )
    direct_matches.extend(
        (
            m.group("reg"),
            None,
            m.group("value"),
            (int(m.group("hi")), int(m.group("lo"))),
            text.count("\n", 0, m.start()) + 1,
            False,
            _guard_action_proc_for_assert_line(text, text.count("\n", 0, m.start()) + 1),
        )
        for m in _RE_ASSERT_TARGET_SLICE.finditer(text)
    )
    fail_fast_matches = [
        (reg, old, value, None, line_no, True, None)
        for reg, old, value, line_no in _find_fail_fast_targets(text)
    ]
    matches = direct_matches + fail_fast_matches
    if not matches:
        return None
    regs = {m[0] for m in matches}
    old_values = {m[1] for m in matches}
    values = {m[2] for m in matches}
    slices = {m[3] for m in matches}
    if len(regs) != 1 or len(old_values) != 1 or len(values) != 1 or len(slices) != 1:
        return None
    reg = next(iter(regs))
    old_value = next(iter(old_values))
    value = next(iter(values))
    target_slice = next(iter(slices))
    decl = _register_type(var_types, reg)
    if not decl:
        return None
    idx_type, val_type = decl
    if not _has_index0_mirrors(var_types, reg, idx_type, val_type):
        return None
    if old_value is not None and not _has_old_value_mirrors(var_types, reg, val_type):
        return None
    line_nos = tuple(m[4] for m in matches)
    has_fail_fast = any(m[5] for m in matches)
    direct_guard_procs = {m[6] for m in direct_matches if m[6] is not None}
    has_unguarded_direct = any(m[6] is None for m in direct_matches)
    guarded_action_proc: Optional[str] = None
    if direct_matches and not fail_fast_matches and not has_unguarded_direct and len(direct_guard_procs) == 1:
        guarded_action_proc = next(iter(direct_guard_procs))
    return reg, idx_type, val_type, old_value, value, target_slice, line_nos, has_fail_fast, guarded_action_proc


def _infer_index_var(text: str, target_reg: str) -> Optional[str]:
    idx_vars: set[str] = set()
    for raw in text.splitlines():
        line = raw.strip()
        m_read = _RE_READ.match(line)
        if m_read and m_read.group("reg") == target_reg:
            idx_vars.add(m_read.group("idx"))
        m_write = _RE_WRITE.match(line)
        if m_write and m_write.group("reg") == target_reg:
            idx_vars.add(m_write.group("idx"))
    if len(idx_vars) != 1:
        return None
    return next(iter(idx_vars))


def _infer_index_definition_proc(text: str, idx_var: str) -> Optional[str]:
    current_proc: Optional[str] = None
    brace_depth = 0
    candidates: set[str] = set()

    for raw in text.splitlines():
        line = raw.strip()
        m_proc = _RE_PROC_START.match(raw)
        if m_proc:
            current_proc = m_proc.group("name")
            brace_depth = 0

        if current_proc is not None and brace_depth > 0:
            m = _RE_META_INDEX_ASSIGN.match(line)
            if m and m.group("idx") == idx_var:
                candidates.add(current_proc)

        brace_depth += raw.count("{") - raw.count("}")
        if current_proc is not None and brace_depth <= 0 and line == "}":
            current_proc = None

    if len(candidates) == 1:
        return next(iter(candidates))

    # Fallback: support helper procedures that compute dynamic indices via
    # generic assignments (e.g., hash-based slot selection), not only
    # `*register_index := *idx*.get...` patterns.
    current_proc = None
    brace_depth = 0
    candidates = set()
    for raw in text.splitlines():
        line = raw.strip()
        m_proc = _RE_PROC_START.match(raw)
        if m_proc:
            current_proc = m_proc.group("name")
            brace_depth = 0

        if current_proc is not None and brace_depth > 0:
            m = _RE_SIMPLE_ASSIGN.match(line)
            if m and m.group("lhs") == idx_var:
                rhs = m.group("rhs")
                # Skip trivial self-assignments; prefer meaningful index
                # computation helpers (hash/get/casts/arithmetic).
                if rhs.strip() != idx_var:
                    candidates.add(current_proc)

        brace_depth += raw.count("{") - raw.count("}")
        if current_proc is not None and brace_depth <= 0 and line == "}":
            current_proc = None

    if len(candidates) == 1:
        return next(iter(candidates))
    return None


def _zero_literal(idx_type: str) -> Optional[str]:
    if not idx_type.startswith("bv"):
        return None
    try:
        width = int(idx_type[2:])
    except ValueError:
        return None
    return f"0bv{width}"


def _bv_literal(value: int, idx_type: str) -> Optional[str]:
    width = bv_width(idx_type)
    if width is None:
        return None
    return f"{int(value) & ((1 << width) - 1)}bv{width}"


def _line_indent(raw: str) -> str:
    return raw[: len(raw) - len(raw.lstrip())]


def _literal_int_for_bv(expr: str, typ: str) -> Optional[int]:
    width = bv_width(typ)
    if width is None:
        return None
    value = eval_bv_expr(expr.strip(), const_eq={}, var_types={})
    if value is None or value.width != width:
        return None
    return value.value


def _extract_unique_bv_literal_assumes(text: str, *, var_types: Dict[str, str]) -> Dict[str, int]:
    out: Dict[str, int] = {}
    seen: Dict[str, set[int]] = {}
    assume_eq = re.compile(
        r"^\s*assume\s*\(?\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*==\s*(?P<rhs>\d+bv\d+)\s*\)?\s*;\s*$"
    )
    for raw in text.splitlines():
        m = assume_eq.match(raw)
        if not m:
            continue
        lhs = m.group("lhs")
        if lhs not in var_types:
            continue
        value = _literal_int_for_bv(m.group("rhs"), var_types.get(lhs, ""))
        if value is None:
            continue
        seen.setdefault(lhs, set()).add(value)
    for lhs, values in seen.items():
        if len(values) == 1:
            out[lhs] = next(iter(values))
    return out


def _derive_proc_bv_constants(
    text: str,
    *,
    proc_name: str,
    initial_consts: Dict[str, int],
    var_types: Dict[str, str],
) -> Dict[str, int]:
    body = _find_procedure_body_lines(text, proc_name)
    if body is None:
        return {}
    env = dict(initial_consts)
    for raw in body:
        stripped = raw.strip()
        m_havoc = re.match(r"^havoc\s+(?P<vars>[^;]+)\s*;\s*$", stripped)
        if m_havoc:
            for name in [p.strip() for p in m_havoc.group("vars").split(",")]:
                env.pop(name, None)
            continue
        m_assign = _RE_SIMPLE_ASSIGN.match(stripped)
        if not m_assign:
            continue
        lhs = m_assign.group("lhs")
        if bv_width(var_types.get(lhs)) is None:
            env.pop(lhs, None)
            continue
        value = eval_bv_expr(m_assign.group("rhs").strip(), const_eq=env, var_types=var_types)
        if value is None or value.width != bv_width(var_types.get(lhs)):
            env.pop(lhs, None)
            continue
        env[lhs] = value.value
    return env


def _infer_constant_focus_slot(
    text: str,
    *,
    idx_var: str,
    idx_type: str,
    index_proc: Optional[str],
    var_types: Dict[str, str],
) -> Optional[str]:
    if index_proc is None:
        return None
    initial_consts = _extract_unique_bv_literal_assumes(text, var_types=var_types)
    proc_consts = _derive_proc_bv_constants(
        text,
        proc_name=index_proc,
        initial_consts=initial_consts,
        var_types=var_types,
    )
    if idx_var not in proc_consts:
        return None
    return _bv_literal(proc_consts[idx_var], idx_type)


def _rewrite_target_assertions_to_index0(
    text: str,
    target_reg: str,
    target_value: str,
    target_slice: Optional[Tuple[int, int]],
    slot_literal: str,
    *,
    target_old_value: Optional[str],
    drop_global_checks: bool,
) -> str:
    use_index0 = _is_zero_literal(slot_literal)
    out: list[str] = []
    for raw in text.splitlines(keepends=True):
        line = raw.rstrip("\n")
        newline = "\n" if raw.endswith("\n") else ""
        stripped = line.strip()
        indent = _line_indent(line)

        m_assert = _RE_ASSERT_TARGET.fullmatch(stripped)
        if m_assert and m_assert.group("reg") == target_reg and m_assert.group("value") == target_value:
            if drop_global_checks:
                continue
            if use_index0:
                out.append(
                    f"{indent}assert !(({_target_bad_expr(target_reg, target_value, target_slice, use_index0=True, target_old_value=target_old_value, parenthesize_eq=True)}));{newline}"
                )
            else:
                out.append(
                    f"{indent}assert !(({_target_bad_expr(target_reg, target_value, target_slice, use_index0=False, slot_literal=slot_literal, target_old_value=target_old_value, parenthesize_eq=True)}));{newline}"
                )
            continue
        m_oldnew = _RE_ASSERT_TARGET_OLDNEW.fullmatch(stripped)
        if (
            m_oldnew
            and m_oldnew.group("reg") == target_reg
            and m_oldnew.group("old") == target_old_value
            and m_oldnew.group("value") == target_value
            and target_slice is None
        ):
            if drop_global_checks:
                continue
            out.append(
                f"{indent}assert !(({_target_bad_expr(target_reg, target_value, None, use_index0=use_index0, slot_literal=None if use_index0 else slot_literal, target_old_value=target_old_value, parenthesize_eq=True)}));{newline}"
            )
            continue
        m_slice = _RE_ASSERT_TARGET_SLICE.fullmatch(stripped)
        if (
            m_slice
            and m_slice.group("reg") == target_reg
            and m_slice.group("value") == target_value
            and target_slice == (int(m_slice.group("hi")), int(m_slice.group("lo")))
            and target_old_value is None
        ):
            if drop_global_checks:
                continue
            if use_index0:
                out.append(
                    f"{indent}assert !(({_target_bad_expr(target_reg, target_value, target_slice, use_index0=True, parenthesize_eq=True)}));{newline}"
                )
            else:
                out.append(
                    f"{indent}assert !(({_target_bad_expr(target_reg, target_value, target_slice, use_index0=False, slot_literal=slot_literal, parenthesize_eq=True)}));{newline}"
                )
            continue

        m_track = _RE_TRACK_TARGET.match(line)
        if (
            target_old_value is None
            and
            target_slice is None
            and m_track
            and m_track.group("reg") == target_reg
            and m_track.group("value") == target_value
        ):
            if drop_global_checks:
                continue
            out.append(
                f"{indent}if ({_target_bad_expr(target_reg, target_value, None, use_index0=use_index0, slot_literal=None if use_index0 else slot_literal, target_old_value=target_old_value)}) {{\n"
            )
            out.append(f"{indent}  assert false;\n")
            out.append(f"{indent}  assume false;\n")
            out.append(f"{indent}}}{newline}")
            continue
        m_track_oldnew = _RE_TRACK_TARGET_OLDNEW.match(line)
        if (
            target_old_value is not None
            and target_slice is None
            and m_track_oldnew
            and m_track_oldnew.group("reg") == target_reg
            and m_track_oldnew.group("old") == target_old_value
            and m_track_oldnew.group("value") == target_value
        ):
            if drop_global_checks:
                continue
            out.append(
                f"{indent}if ({_target_bad_expr(target_reg, target_value, None, use_index0=use_index0, slot_literal=None if use_index0 else slot_literal, target_old_value=target_old_value)}) {{\n"
            )
            out.append(f"{indent}  assert false;\n")
            out.append(f"{indent}  assume false;\n")
            out.append(f"{indent}}}{newline}")
            continue

        out.append(raw)
    return "".join(out)


def _remove_unused_target_broad_fail_fast(
    text: str,
    target_reg: str,
    target_value: str,
    *,
    target_old_value: Optional[str],
) -> str:
    if f"call {target_reg}.write(" in text:
        return text

    lines = text.splitlines(keepends=True)
    out: list[str] = []
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        m_oldnew = _RE_FAIL_FAST_OLDNEW_IF.match(stripped)
        if (
            m_oldnew
            and m_oldnew.group("reg") == target_reg
            and m_oldnew.group("old") == target_old_value
            and m_oldnew.group("value") == target_value
            and i + 3 < len(lines)
            and _RE_ASSERT_FALSE.match(lines[i + 1].strip())
            and lines[i + 2].strip() == "assume false;"
            and lines[i + 3].strip() == "}"
        ):
            i += 4
            continue
        m_if = _RE_FAIL_FAST_IF.match(stripped)
        if (
            m_if
            and target_old_value is None
            and m_if.group("reg") == target_reg
            and m_if.group("value") == target_value
            and i + 3 < len(lines)
            and _RE_ASSERT_FALSE.match(lines[i + 1].strip())
            and lines[i + 2].strip() == "assume false;"
            and lines[i + 3].strip() == "}"
        ):
            i += 4
            continue
        out.append(lines[i])
        i += 1
    return "".join(out)


def _drop_vacuous_procurator_bad_asserts(text: str) -> str:
    if "procurator_bad := true" in text:
        return text
    out: list[str] = []
    for raw in text.splitlines(keepends=True):
        if raw.strip() == "assert !procurator_bad;":
            continue
        out.append(raw)
    return "".join(out)


def focus_dynamic_index0_register_assert(text: str) -> FocusedDirectResult:
    """
    Build a focused under-approximation for direct register-mirror bug finding.

    This transform is intentionally one-way:
      - It pins the target's dynamic register index to one concrete slot.
      - If that slot is 0, it also updates the already-maintained index0 scalar
        mirrors.  Nonzero focused slots use the generic last-write mirror.

    The result may be used to prove UNSAFE only.  SAFE/UNKNOWN/TIMEOUT on the
    focused program says nothing about the original program, so callers must
    fall back to the unmodified BPL unless the focused run is UNSAFE.
    """

    var_types = _parse_var_types(text)
    target = _find_assert_target(text, var_types)
    if target is None:
        return FocusedDirectResult(False, text, "no unique direct register-mirror assertion")
    (
        target_reg,
        idx_type,
        _val_type,
        target_old_value,
        target_value,
        target_slice,
        _assert_lines,
        inject_target_fail_fast,
        guarded_action_proc,
    ) = target
    idx_var = _infer_index_var(text, target_reg)
    if idx_var is None:
        return FocusedDirectResult(False, text, "target register does not use one dynamic index variable")
    zero = _zero_literal(idx_type)
    if zero is None:
        return FocusedDirectResult(False, text, f"unsupported target index type {idx_type}")
    index_proc = _infer_index_definition_proc(text, idx_var)
    focus_slot = _infer_constant_focus_slot(
        text,
        idx_var=idx_var,
        idx_type=idx_type,
        index_proc=index_proc,
        var_types=var_types,
    ) or zero
    use_index0 = _is_zero_literal(focus_slot)

    changed = False
    pinned_index = index_proc is None
    scalarized_access = False
    constrained_access = False
    focus_active = False
    current_proc: Optional[str] = None
    brace_depth = 0
    out: list[str] = []

    for raw in text.splitlines(keepends=True):
        line = raw.rstrip("\n")
        stripped = line.strip()
        m_proc = _RE_PROC_START.match(line)
        if m_proc:
            current_proc = m_proc.group("name")
            brace_depth = 0

        if current_proc is not None and brace_depth > 0:
            m_index_call = _RE_GET_REGISTER_INDEX_CALL.match(stripped)
            if index_proc is not None and m_index_call and m_index_call.group("proc") == index_proc:
                out.append(raw)
                out.append(f"{_line_indent(line)}assume {idx_var} == {focus_slot};\n")
                changed = True
                pinned_index = True
                focus_active = True
                brace_depth += raw.count("{") - raw.count("}")
                continue

            m_call = _RE_CALL_PROC.match(stripped)
            if index_proc is not None and m_call and m_call.group("proc") == index_proc:
                out.append(raw)
                out.append(f"{_line_indent(line)}assume {idx_var} == {focus_slot};\n")
                changed = True
                pinned_index = True
                focus_active = True
                brace_depth += raw.count("{") - raw.count("}")
                continue

            m_assign = _RE_SIMPLE_ASSIGN.match(stripped)
            if m_assign and m_assign.group("lhs") == idx_var:
                focus_active = False

            m_read = _RE_READ.match(stripped)
            if m_read and m_read.group("idx") == idx_var and (focus_active or m_read.group("reg") == target_reg):
                reg = m_read.group("reg")
                decl = _register_type(var_types, reg)
                if decl and _has_index0_mirrors(var_types, reg, decl[0], decl[1]):
                    out.append(f"{_line_indent(line)}assume {idx_var} == {focus_slot};\n")
                    out.append(
                        f"{_line_indent(line)}{m_read.group('lhs')} := {reg}[{focus_slot}];\n"
                    )
                    changed = True
                    scalarized_access = True
                    constrained_access = True
                    brace_depth += raw.count("{") - raw.count("}")
                    continue

            m_write = _RE_WRITE.match(stripped)
            if m_write and m_write.group("idx") == idx_var and (focus_active or m_write.group("reg") == target_reg):
                reg = m_write.group("reg")
                value = m_write.group("value")
                decl = _register_type(var_types, reg)
                if decl and _has_index0_mirrors(var_types, reg, decl[0], decl[1]):
                    indent = _line_indent(line)
                    has_old_mirrors = _has_old_value_mirrors(var_types, reg, decl[1])
                    out.append(f"{indent}assume {idx_var} == {focus_slot};\n")
                    if has_old_mirrors:
                        out.append(f"{indent}{reg}__last_old_value := {reg}[{focus_slot}];\n")
                    out.append(f"{indent}{reg}[{focus_slot}] := {value};\n")
                    out.append(f"{indent}{reg}__last_index := {focus_slot};\n")
                    out.append(f"{indent}{reg}__last_value := {value};\n")
                    out.append(f"{indent}{reg}__wrote_any := true;\n")
                    if use_index0:
                        out.append(f"{indent}{reg}__wrote_index0 := true;\n")
                        if has_old_mirrors:
                            out.append(f"{indent}{reg}__last0_old_value := {reg}__last_old_value;\n")
                        out.append(f"{indent}{reg}__last0_value := {value};\n")
                    # Keep focused prepasses compact: under-approx UNSAFE probing
                    # only needs the writer-site fail-fast inserted for the target
                    # register. Duplicating the same check at every write site
                    # causes many equivalent error locations and can explode CEGAR.
                    writer_is_guarded_target = (
                        guarded_action_proc is not None and current_proc == guarded_action_proc and reg == target_reg
                    )
                    writer_needs_fail_fast = (inject_target_fail_fast and reg == target_reg) or writer_is_guarded_target
                    if writer_needs_fail_fast:
                        out.append(
                            f"{indent}if ({_target_bad_expr(reg, target_value, target_slice, use_index0=use_index0, slot_literal=None if use_index0 else focus_slot, target_old_value=target_old_value)}) {{\n"
                        )
                        out.append(f"{indent}    assert false;\n")
                        out.append(f"{indent}    assume false;\n")
                        out.append(f"{indent}}}\n")
                    changed = True
                    scalarized_access = True
                    constrained_access = True
                    brace_depth += raw.count("{") - raw.count("}")
                    continue

        out.append(raw)
        brace_depth += raw.count("{") - raw.count("}")
        if current_proc is not None and brace_depth <= 0 and stripped == "}":
            current_proc = None
            focus_active = False

    if not pinned_index:
        return FocusedDirectResult(False, text, "index variable was not pinned at its definition call")
    if not changed:
        return FocusedDirectResult(False, text, "no standard dynamic-index register accesses rewritten")
    if not constrained_access:
        return FocusedDirectResult(False, text, "no dynamic-index register access was constrained")
    if not scalarized_access:
        return FocusedDirectResult(False, text, "no dynamic-index register access was scalarized")
    final_text = _rewrite_target_assertions_to_index0(
        "".join(out),
        target_reg,
        target_value,
        target_slice,
        focus_slot,
        target_old_value=target_old_value,
        drop_global_checks=inject_target_fail_fast or guarded_action_proc is not None,
    )
    final_text = _remove_unused_target_broad_fail_fast(
        final_text,
        target_reg,
        target_value,
        target_old_value=target_old_value,
    )
    final_text = _drop_vacuous_procurator_bad_asserts(final_text)
    assert_lines = _find_assert_lines(
        final_text,
        target_reg,
        target_value,
        target_slice,
        focus_slot,
        target_old_value,
    )
    if not assert_lines:
        return FocusedDirectResult(False, text, "focused assertion line could not be identified")
    return FocusedDirectResult(
        True,
        final_text,
        f"focused {target_reg} at {idx_var} == {focus_slot}",
        target_reg=target_reg,
        idx_var=idx_var,
        zero=focus_slot,
        target_value=target_value,
        target_old_value=target_old_value,
        target_slice=target_slice,
        assert_line=assert_lines[0],
        assert_lines=assert_lines,
    )
