from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Dict, Optional, Tuple


@dataclass(frozen=True)
class FocusedDirectResult:
    changed: bool
    text: str
    reason: str
    target_reg: Optional[str] = None
    idx_var: Optional[str] = None
    zero: Optional[str] = None
    target_value: Optional[str] = None
    assert_line: Optional[int] = None
    assert_lines: Tuple[int, ...] = ()


_RE_VAR_DECL = re.compile(r"^\s*var\s+(?P<name>\S+)\s*:\s*(?P<type>[^;]+);\s*$")
_RE_REG_ARRAY_TYPE = re.compile(r"^\[(?P<idx>bv\d+)\](?P<val>bv\d+)$")
_RE_READ = re.compile(
    r"^(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*"
    r"(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)\.read\("
    r"(?P=reg),\s*(?P<idx>[A-Za-z_][A-Za-z0-9_.]*)\);$"
)
_RE_WRITE = re.compile(
    r"^call\s+(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)\.write\("
    r"(?P<idx>[A-Za-z_][A-Za-z0-9_.]*),\s*(?P<value>[A-Za-z_][A-Za-z0-9_.]*)\);$"
)
_RE_ASSERT_TARGET = re.compile(
    r"assert\s+!\(\((?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"\((?P=reg)__last_value\s*==\s*(?P<value>\d+bv\d+)\)\)\);"
)
_RE_ASSERT_TARGET_INDEX0 = re.compile(
    r"assert\s+!\(\((?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_index0\s*&&\s*"
    r"\((?P=reg)__last0_value\s*==\s*(?P<value>\d+bv\d+)\)\)\);"
)
_RE_FAIL_FAST_IF = re.compile(
    r"if\s*\(\s*(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"(?P=reg)__last_value\s*==\s*(?P<value>\d+bv\d+)\s*\)\s*\{"
)
_RE_FAIL_FAST_INDEX0_IF = re.compile(
    r"if\s*\(\s*(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_index0\s*&&\s*"
    r"(?P=reg)__last0_value\s*==\s*(?P<value>\d+bv\d+)\s*\)\s*\{"
)
_RE_TRACK_TARGET = re.compile(
    r"^(?P<indent>\s*)if\s*\(\s*!\s*\(\s*!\s*\(\(\s*"
    r"(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)__wrote_any\s*&&\s*"
    r"\((?P=reg)__last_value\s*==\s*(?P<value>\d+bv\d+)\)\s*"
    r"\)\)\s*\)\s*\)\s*\{\s*procurator_bad\s*:=\s*true\s*;\s*\}\s*$"
)
_RE_ASSERT_FALSE = re.compile(r"^\s*assert\s+false\s*;\s*$")
_RE_PROC_START = re.compile(r"^\s*procedure(?:\s*\{[^}]*\}\s*)?\s+(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\s*\(")
_RE_GET_REGISTER_INDEX_CALL = re.compile(
    r"^\s*call\s+(?P<proc>[A-Za-z_][A-Za-z0-9_.]*get_register_index)\([^;]*\);\s*$"
)
_RE_META_INDEX_ASSIGN = re.compile(
    r"^\s*(?P<idx>[A-Za-z_][A-Za-z0-9_.]*register_index)\s*:=\s*"
    r"(?P<callee>[A-Za-z_][A-Za-z0-9_.$]*idx[A-Za-z0-9_.$]*\.get[^;]*);$"
)
_RE_SIMPLE_ASSIGN = re.compile(r"^(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*(?P<rhs>.*);$")


def _parse_var_types(text: str) -> Dict[str, str]:
    out: Dict[str, str] = {}
    for line in text.splitlines():
        m = _RE_VAR_DECL.match(line)
        if m:
            out[m.group("name")] = m.group("type").strip()
    return out


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


def _find_fail_fast_targets(text: str) -> list[Tuple[str, str, int]]:
    out: list[Tuple[str, str, int]] = []
    pending: Optional[Tuple[str, str]] = None

    for line_no, raw in enumerate(text.splitlines(), start=1):
        stripped = raw.strip()
        m_if = _RE_FAIL_FAST_IF.match(stripped)
        if m_if:
            pending = (m_if.group("reg"), m_if.group("value"))
        elif pending is not None and _RE_ASSERT_FALSE.match(stripped):
            out.append((pending[0], pending[1], line_no))
            pending = None
    return out


def _find_index0_fail_fast_targets(text: str) -> list[Tuple[str, str, int]]:
    out: list[Tuple[str, str, int]] = []
    pending: Optional[Tuple[str, str]] = None

    for line_no, raw in enumerate(text.splitlines(), start=1):
        stripped = raw.strip()
        m_if = _RE_FAIL_FAST_INDEX0_IF.match(stripped)
        if m_if:
            pending = (m_if.group("reg"), m_if.group("value"))
        elif pending is not None and _RE_ASSERT_FALSE.match(stripped):
            out.append((pending[0], pending[1], line_no))
            pending = None
    return out


def _find_assert_lines(text: str, target_reg: str, target_value: str) -> Tuple[int, ...]:
    lines = text.splitlines()
    out: list[int] = []
    for i, line in enumerate(lines, start=1):
        m_index0 = _RE_ASSERT_TARGET_INDEX0.search(line)
        if m_index0 and m_index0.group("reg") == target_reg and m_index0.group("value") == target_value:
            out.append(i)
    for reg, value, line_no in _find_index0_fail_fast_targets(text):
        if reg == target_reg and value == target_value:
            out.append(line_no)
    return tuple(out)


def find_focused_direct_assert_lines(text: str, target_reg: str, target_value: str) -> Tuple[int, ...]:
    """Return slot-0 focused assertion lines in the exact Boogie text given."""

    return _find_assert_lines(text, target_reg, target_value)


def _find_assert_target(text: str, var_types: Dict[str, str]) -> Optional[Tuple[str, str, str, str, Tuple[int, ...], bool]]:
    direct_matches = [
        (m.group("reg"), m.group("value"), text.count("\n", 0, m.start()) + 1, False)
        for m in _RE_ASSERT_TARGET.finditer(text)
    ]
    fail_fast_matches = [(reg, value, line_no, True) for reg, value, line_no in _find_fail_fast_targets(text)]
    matches = direct_matches + fail_fast_matches
    if not matches:
        return None
    regs = {m[0] for m in matches}
    values = {m[1] for m in matches}
    if len(regs) != 1 or len(values) != 1:
        return None
    reg = next(iter(regs))
    value = next(iter(values))
    decl = _register_type(var_types, reg)
    if not decl:
        return None
    idx_type, val_type = decl
    if not _has_index0_mirrors(var_types, reg, idx_type, val_type):
        return None
    line_nos = tuple(m[2] for m in matches)
    has_fail_fast = any(m[3] for m in matches)
    return reg, idx_type, val_type, value, line_nos, has_fail_fast


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
    return None


def _zero_literal(idx_type: str) -> Optional[str]:
    if not idx_type.startswith("bv"):
        return None
    try:
        width = int(idx_type[2:])
    except ValueError:
        return None
    return f"0bv{width}"


def _line_indent(raw: str) -> str:
    return raw[: len(raw) - len(raw.lstrip())]


def _rewrite_target_assertions_to_index0(
    text: str,
    target_reg: str,
    target_value: str,
    *,
    drop_global_checks: bool,
) -> str:
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
            out.append(
                f"{indent}assert !(({target_reg}__wrote_index0 && "
                f"({target_reg}__last0_value == {target_value})));{newline}"
            )
            continue

        m_track = _RE_TRACK_TARGET.match(line)
        if m_track and m_track.group("reg") == target_reg and m_track.group("value") == target_value:
            if drop_global_checks:
                continue
            out.append(f"{indent}if ({target_reg}__wrote_index0 && {target_reg}__last0_value == {target_value}) {{\n")
            out.append(f"{indent}  assert false;\n")
            out.append(f"{indent}  assume false;\n")
            out.append(f"{indent}}}{newline}")
            continue

        out.append(raw)
    return "".join(out)


def _remove_unused_target_broad_fail_fast(text: str, target_reg: str, target_value: str) -> str:
    if f"call {target_reg}.write(" in text:
        return text

    lines = text.splitlines(keepends=True)
    out: list[str] = []
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        m_if = _RE_FAIL_FAST_IF.match(stripped)
        if (
            m_if
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
      - It pins the target's dynamic register index to slot 0.
      - It replaces standard P4B register.read/write calls on that same index
        with the already-maintained index0 scalar mirrors.

    The result may be used to prove UNSAFE only.  SAFE/UNKNOWN/TIMEOUT on the
    focused program says nothing about the original program, so callers must
    fall back to the unmodified BPL unless the focused run is UNSAFE.
    """

    var_types = _parse_var_types(text)
    target = _find_assert_target(text, var_types)
    if target is None:
        return FocusedDirectResult(False, text, "no unique direct register-mirror assertion")
    target_reg, idx_type, _val_type, target_value, _assert_lines, inject_target_fail_fast = target
    idx_var = _infer_index_var(text, target_reg)
    if idx_var is None:
        return FocusedDirectResult(False, text, "target register does not use one dynamic index variable")
    zero = _zero_literal(idx_type)
    if zero is None:
        return FocusedDirectResult(False, text, f"unsupported target index type {idx_type}")
    index_proc = _infer_index_definition_proc(text, idx_var)
    if index_proc is None:
        return FocusedDirectResult(False, text, "could not identify unique index-definition procedure")

    changed = False
    pinned_index = False
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
            if m_index_call and m_index_call.group("proc") == index_proc:
                out.append(raw)
                out.append(f"{_line_indent(line)}assume {idx_var} == {zero};\n")
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
                    out.append(f"{_line_indent(line)}assume {idx_var} == {zero};\n")
                    out.append(
                        f"{_line_indent(line)}{m_read.group('lhs')} := {reg}[{zero}];\n"
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
                    out.append(f"{indent}assume {idx_var} == {zero};\n")
                    out.append(f"{indent}{reg}[{zero}] := {value};\n")
                    out.append(f"{indent}{reg}__last_index := {zero};\n")
                    out.append(f"{indent}{reg}__last_value := {value};\n")
                    out.append(f"{indent}{reg}__wrote_any := true;\n")
                    out.append(f"{indent}{reg}__wrote_index0 := true;\n")
                    out.append(f"{indent}{reg}__last0_value := {value};\n")
                    if inject_target_fail_fast and reg == target_reg:
                        out.append(
                            f"{indent}if ({reg}__wrote_index0 && {reg}__last0_value == {target_value}) {{\n"
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
        drop_global_checks=inject_target_fail_fast,
    )
    final_text = _remove_unused_target_broad_fail_fast(final_text, target_reg, target_value)
    final_text = _drop_vacuous_procurator_bad_asserts(final_text)
    assert_lines = _find_assert_lines(final_text, target_reg, target_value)
    if not assert_lines:
        return FocusedDirectResult(False, text, "focused assertion line could not be identified")
    return FocusedDirectResult(
        True,
        final_text,
        f"focused {target_reg} at {idx_var} == {zero}",
        target_reg=target_reg,
        idx_var=idx_var,
        zero=zero,
        target_value=target_value,
        assert_line=assert_lines[0],
        assert_lines=assert_lines,
    )
