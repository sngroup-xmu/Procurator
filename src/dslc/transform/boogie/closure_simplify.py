from __future__ import annotations

import re
from typing import Dict, List, Optional, Sequence, Tuple

from dslc.analysis.wraparound_projection_exprs import normalize_expr, strip_wrapping_parens

_RE_PROC_HEADER = re.compile(
    r"^\s*procedure(?:\s+\{[^}]*\})?\s+(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\("
)
_RE_PROC_SIG = re.compile(
    r"^\s*procedure(?:\s+\{[^}]*\})?\s+(?P<name>[A-Za-z_][A-Za-z0-9_.]*)"
    r"\((?P<params>[^)]*)\)(?:\s+returns\s*\((?P<returns>[^)]*)\))?"
)
_RE_GOTO = re.compile(r"^\s*goto\s+(?P<labels>[^;]+)\s*;\s*$")
_RE_LABEL = re.compile(r"^\s*(?P<label>[A-Za-z_][A-Za-z0-9_.$]*)\s*:\s*$")
_RE_ASSUME_EQ = re.compile(
    r"^\s*assume\s+\(?\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*==\s*(?P<rhs>[^;)]+)\s*\)?\s*;\s*$"
)
_RE_ASSIGN = re.compile(r"^\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*(?P<rhs>.*)\s*;\s*$")
_RE_READ_ASSIGN = re.compile(
    r"^\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*"
    r"(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)\.read\(\s*(?P=reg)\s*,\s*(?P<idx>.+?)\s*\)\s*;\s*$"
)
_RE_CALL_ASSIGN = re.compile(
    r"^\s*call\s+(?P<lhs>[^:;]+?)\s*:=\s*(?P<proc>[A-Za-z_][A-Za-z0-9_.]*)"
    r"\((?P<args>.*)\)\s*;\s*$"
)
_RE_CALL_PROC = re.compile(
    r"^\s*call\s+(?:(?P<lhs>[^:;]+?)\s*:=\s*)?(?P<proc>[A-Za-z_][A-Za-z0-9_.]*)"
    r"\((?P<args>.*)\)\s*;\s*$"
)
_RE_WRITE_CALL = re.compile(
    r"^(?P<indent>\s*)call\s+(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)\.write"
    r"\(\s*(?P<idx>.+?)\s*,\s*(?P<value>.+?)\s*\)\s*;\s*$"
)
_RE_REG_TYPE = re.compile(r"^\s*\[\s*bv(?P<idx>\d+)\s*\]\s*bv(?P<elem>\d+)\s*$")
_RE_IF_HEADER = re.compile(r"^\s*if\s*\((?P<cond>.*)\)\s*\{\s*$")
_RE_INT_LIT_ASSIGN = re.compile(r"^\s*(?P<var>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*(?P<value>-?\d+)\s*;\s*$")
_RE_BOOL_LIT_ASSIGN = re.compile(
    r"^\s*(?P<var>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*(?P<value>true|false)\s*;\s*$"
)
_RE_INT_INC_ASSIGN = re.compile(
    r"^\s*(?P<var>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*(?P=var)\s*(?P<op>[+-])\s*(?P<delta>\d+)\s*;\s*$"
)
_RE_INT_ASSUME_EQ = re.compile(r"^\s*assume\s+\(?\s*(?P<var>[A-Za-z_][A-Za-z0-9_.]*)\s*==\s*(?P<value>-?\d+)\s*\)?\s*;\s*$")
_RE_BOOL_ASSUME_EQ = re.compile(
    r"^\s*assume\s+\(?\s*(?P<var>[A-Za-z_][A-Za-z0-9_.]*)\s*==\s*(?P<value>true|false)\s*\)?\s*;\s*$"
)
_RE_INT_COND = re.compile(
    r"^\s*(?P<var>[A-Za-z_][A-Za-z0-9_.]*)\s*(?P<op><=|>=|==|!=|<|>)\s*(?P<value>-?\d+)\s*$"
)
_EVENT_FLAG_SUFFIXES = (
    "_p4b_clone_i2e",
    "_p4b_clone_e2e",
    "_p4b_clone_i2i",
    "_p4b_recirculate",
)
_CONTROL_FLOW_PREFIXES = ("if", "while", "goto", "return")


def specialize_fixed_table_branches(
    lines: List[str],
    *,
    assumptions: Sequence[str],
    var_types: Dict[str, str],
) -> None:
    """
    Prune P4B table-action branches when closure assumptions fix action_run.

    P4B's goto lowering emits a table prefix followed by a multi-target goto and
    one label per action.  Under a closure profile that already assumes
    `<table>.action_run == <table>.action.X`, all non-X branches are infeasible.
    This pass preserves the prefix and selected action side effects, while
    deleting only the infeasible goto/labels inside the proof task.
    """

    stable_values = _stable_values(assumptions, var_types=var_types)
    for name, value in _mainprocedure_stable_action_values(lines, var_types=var_types).items():
        stable_values.setdefault(name, value)
    if not stable_values:
        return

    i = 0
    while i < len(lines):
        m = _RE_PROC_HEADER.match(lines[i])
        if not m:
            i += 1
            continue
        proc_name = m.group("name")
        block = _procedure_block(lines, i)
        if block is None:
            i += 1
            continue
        start, open_idx, close_idx = block
        body_start = open_idx + 1
        body_end = close_idx
        body = lines[body_start:body_end]
        replacement = _specialized_table_body(proc_name, body, stable_values=stable_values)
        if replacement is None:
            i = close_idx + 1
            continue
        lines[body_start:body_end] = replacement
        i = body_start + len(replacement) + 1


def eliminate_identity_register_writebacks(lines: List[str], *, var_types: Dict[str, str]) -> None:
    """
    Replace same-value RegisterAction writebacks with mirror-only event updates.

    TNA-style RegisterAction lowering writes the first return value back to the
    register even for read-only actions.  When the apply procedure preserves that
    first value, `store(A, i, A[i])` is array-equivalent to `A`; we can remove the
    array store while keeping write-site mirrors exactly as the write procedure
    would have updated them.
    """

    identity_apply = _identity_first_return_apply_procs(lines)
    if not identity_apply:
        return

    i = 0
    while i < len(lines):
        line = lines[i]
        mcall = _RE_CALL_ASSIGN.match(line.strip())
        if not mcall or mcall.group("proc") not in identity_apply:
            i += 1
            continue
        lhs_parts = _split_csv(mcall.group("lhs"))
        args = _split_csv(mcall.group("args"))
        if not lhs_parts or not args:
            i += 1
            continue
        value_var = lhs_parts[0]
        input_value = args[0]
        if _clean(value_var) != _clean(input_value):
            i += 1
            continue

        read_idx = _previous_statement_index(lines, i)
        if read_idx is None:
            i += 1
            continue
        mread = _RE_READ_ASSIGN.match(lines[read_idx].strip())
        if not mread or _clean(mread.group("lhs")) != _clean(input_value):
            i += 1
            continue
        reg = mread.group("reg")
        idx_expr = mread.group("idx").strip()

        write_idx = _next_statement_index(lines, i)
        if write_idx is None:
            i += 1
            continue
        if _is_next_write_site_assignment(lines[write_idx].strip(), reg):
            write_idx = _next_statement_index(lines, write_idx)
            if write_idx is None:
                i += 1
                continue
        mwrite = _RE_WRITE_CALL.match(lines[write_idx])
        if not mwrite:
            i += 1
            continue
        if mwrite.group("reg") != reg:
            i += 1
            continue
        if _clean(mwrite.group("idx")) != _clean(idx_expr):
            i += 1
            continue
        if _clean(mwrite.group("value")) != _clean(value_var):
            i += 1
            continue

        replacement = _mirror_only_writeback_lines(
            reg=reg,
            idx_expr=idx_expr,
            value_expr=value_var,
            indent=mwrite.group("indent"),
            var_types=var_types,
        )
        if replacement:
            lines[write_idx : write_idx + 1] = replacement
            i = write_idx + len(replacement)
            continue
        i += 1


def simplify_deterministic_closure_blocks(lines: List[str], *, var_types: Dict[str, str]) -> None:
    """Fold straight-line deterministic harness branches inside mainProcedure."""

    block = _find_procedure_by_name(lines, "mainProcedure")
    if block is None:
        return
    false_only_flags = _false_only_event_flags(lines, var_types=var_types)
    proc_modifies = _procedure_modifies(lines)
    proc_post_false = _procedure_post_false_event_flags(
        lines,
        var_types=var_types,
        event_flags=false_only_flags,
        proc_modifies=proc_modifies,
    )
    _fold_block(
        lines,
        start=block[1] + 1,
        end=block[2],
        var_types=var_types,
        false_only_flags=false_only_flags,
        proc_modifies=proc_modifies,
        proc_post_false=proc_post_false,
    )


def _fold_block(
    lines: List[str],
    *,
    start: int,
    end: int,
    var_types: Dict[str, str],
    false_only_flags: set[str],
    proc_modifies: Dict[str, set[str]],
    proc_post_false: Dict[str, set[str]],
) -> None:
    constants: Dict[str, object] = {}
    i = start
    while i < end and i < len(lines):
        stripped = lines[i].strip()
        m_if = _RE_IF_HEADER.match(stripped)
        if m_if:
            block_end = _find_plain_if_end(lines, i)
            if block_end is None or block_end >= end:
                i += 1
                continue
            value = _eval_condition(m_if.group("cond"), constants)
            if value is True:
                body = lines[i + 1 : block_end]
                lines[i : block_end + 1] = body
                end -= 2
                continue
            if value is False:
                del lines[i : block_end + 1]
                end -= block_end - i + 1
                continue
            i += 1
            continue

        _update_constants(
            stripped,
            constants,
            var_types=var_types,
            false_only_flags=false_only_flags,
            proc_modifies=proc_modifies,
            proc_post_false=proc_post_false,
        )
        i += 1


def _eval_condition(cond: str, constants: Dict[str, object]) -> Optional[bool]:
    text = strip_wrapping_parens(cond.strip())
    if text in constants and isinstance(constants[text], bool):
        return bool(constants[text])
    if text.startswith("!") and text[1:].strip() in constants and isinstance(constants[text[1:].strip()], bool):
        return not bool(constants[text[1:].strip()])
    m = _RE_INT_COND.match(text)
    if not m:
        return None
    value = constants.get(m.group("var"))
    if not isinstance(value, int):
        return None
    rhs = int(m.group("value"))
    op = m.group("op")
    if op == "<":
        return value < rhs
    if op == "<=":
        return value <= rhs
    if op == ">":
        return value > rhs
    if op == ">=":
        return value >= rhs
    if op == "==":
        return value == rhs
    if op == "!=":
        return value != rhs
    return None


def _update_constants(
    stmt: str,
    constants: Dict[str, object],
    *,
    var_types: Dict[str, str],
    false_only_flags: set[str],
    proc_modifies: Dict[str, set[str]],
    proc_post_false: Dict[str, set[str]],
) -> None:
    mh = re.match(r"^\s*havoc\s+(?P<vars>[^;]+)\s*;\s*$", stmt)
    if mh:
        for raw in mh.group("vars").split(","):
            constants.pop(raw.strip(), None)
        return

    mi = _RE_INT_LIT_ASSIGN.match(stmt)
    if mi and var_types.get(mi.group("var")) == "int":
        constants[mi.group("var")] = int(mi.group("value"))
        return

    mb = _RE_BOOL_LIT_ASSIGN.match(stmt)
    if mb and var_types.get(mb.group("var")) == "bool":
        constants[mb.group("var")] = mb.group("value") == "true"
        return

    minc = _RE_INT_INC_ASSIGN.match(stmt)
    if minc and isinstance(constants.get(minc.group("var")), int):
        delta = int(minc.group("delta"))
        constants[minc.group("var")] = int(constants[minc.group("var")]) + (delta if minc.group("op") == "+" else -delta)
        return

    mai = _RE_INT_ASSUME_EQ.match(stmt)
    if mai and var_types.get(mai.group("var")) == "int":
        constants[mai.group("var")] = int(mai.group("value"))
        return

    mab = _RE_BOOL_ASSUME_EQ.match(stmt)
    if mab and var_types.get(mab.group("var")) == "bool":
        constants[mab.group("var")] = mab.group("value") == "true"
        return

    mcall = _RE_CALL_PROC.match(stmt)
    if mcall:
        proc = mcall.group("proc")
        modified = proc_modifies.get(proc)
        if modified is None:
            constants.clear()
            return
        for name in list(constants):
            if name in modified:
                constants.pop(name, None)
        for name in proc_post_false.get(proc, set()):
            constants[name] = False
        return

    for name in _written_globals(stmt, var_types=var_types):
        if name not in constants:
            continue
        if name in false_only_flags and constants[name] is False:
            continue
        constants.pop(name, None)


def _false_only_event_flags(lines: Sequence[str], *, var_types: Dict[str, str]) -> set[str]:
    candidates = {
        name
        for name, typ in var_types.items()
        if typ == "bool" and any(name.endswith(suffix) for suffix in _EVENT_FLAG_SUFFIXES)
    }
    if not candidates:
        return set()
    unsafe = set()
    for line in lines:
        stmt = line.strip()
        mh = re.match(r"^\s*havoc\s+(?P<vars>[^;]+)\s*;\s*$", stmt)
        if mh:
            unsafe.update(name for name in (part.strip() for part in mh.group("vars").split(",")) if name in candidates)
        ma = re.match(r"^\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*(?P<rhs>.*?)\s*;\s*$", stmt)
        if ma and ma.group("lhs") in candidates and ma.group("rhs") != "false":
            unsafe.add(ma.group("lhs"))
    return candidates - unsafe


def _procedure_modifies(lines: Sequence[str]) -> Dict[str, set[str]]:
    out: Dict[str, set[str]] = {}
    i = 0
    while i < len(lines):
        m = _RE_PROC_HEADER.match(lines[i])
        if not m:
            i += 1
            continue
        proc_name = m.group("name")
        block = _procedure_block(lines, i)
        if block is None:
            i += 1
            continue
        _proc_idx, open_idx, close_idx = block
        header = " ".join(lines[i:open_idx])
        mods = re.search(r"\bmodifies\s+(?P<vars>.*?);", header)
        if mods:
            out[proc_name] = {part.strip() for part in mods.group("vars").split(",") if part.strip()}
        else:
            out[proc_name] = set()
        i = close_idx + 1
    return out


def _procedure_post_false_event_flags(
    lines: Sequence[str],
    *,
    var_types: Dict[str, str],
    event_flags: set[str],
    proc_modifies: Dict[str, set[str]],
) -> Dict[str, set[str]]:
    """
    Summarize event flags that are definitely false after a procedure returns.

    The summary is intentionally narrow: it only reasons over straight-line
    procedure bodies and through calls whose modifies set/post-false summary is
    known.  This is enough for P4B mainProcedure wrappers that reset clone and
    recirculation flags before calling a pipeline that does not modify them.
    """

    if not event_flags:
        return {}

    proc_blocks: Dict[str, Tuple[int, int, int]] = {}
    i = 0
    while i < len(lines):
        m = _RE_PROC_HEADER.match(lines[i])
        if not m:
            i += 1
            continue
        block = _procedure_block(lines, i)
        if block is None:
            i += 1
            continue
        proc_blocks[m.group("name")] = block
        i = block[2] + 1

    summaries: Dict[str, set[str]] = {name: set() for name in proc_blocks}
    changed = True
    for _ in range(len(proc_blocks) + 1):
        if not changed:
            break
        changed = False
        for proc_name, (_proc_idx, open_idx, close_idx) in proc_blocks.items():
            summary = _straightline_post_false_flags(
                lines[open_idx + 1 : close_idx],
                event_flags=event_flags,
                proc_modifies=proc_modifies,
                proc_post_false=summaries,
            )
            if summary != summaries.get(proc_name, set()):
                summaries[proc_name] = summary
                changed = True
    return {name: flags for name, flags in summaries.items() if flags}


def _straightline_post_false_flags(
    body: Sequence[str],
    *,
    event_flags: set[str],
    proc_modifies: Dict[str, set[str]],
    proc_post_false: Dict[str, set[str]],
) -> set[str]:
    known_false: set[str] = set()
    for line in body:
        stmt = line.strip()
        if not stmt or stmt.startswith("//"):
            continue
        if _RE_LABEL.match(stmt):
            return set()
        if any(stmt.startswith(prefix) for prefix in _CONTROL_FLOW_PREFIXES):
            return set()

        mh = re.match(r"^\s*havoc\s+(?P<vars>[^;]+)\s*;\s*$", stmt)
        if mh:
            for raw in mh.group("vars").split(","):
                known_false.discard(raw.strip())
            continue

        mcall = _RE_CALL_PROC.match(stmt)
        if mcall:
            proc = mcall.group("proc")
            modified = proc_modifies.get(proc)
            if modified is None:
                known_false.clear()
                continue
            known_false.difference_update(modified)
            known_false.update(proc_post_false.get(proc, set()))
            continue

        mb = _RE_BOOL_LIT_ASSIGN.match(stmt)
        if mb and mb.group("var") in event_flags:
            if mb.group("value") == "false":
                known_false.add(mb.group("var"))
            else:
                known_false.discard(mb.group("var"))
            continue

        for name in _written_globals(stmt, var_types={flag: "bool" for flag in event_flags}):
            known_false.discard(name)
    return set(known_false)


def _find_plain_if_end(lines: Sequence[str], if_idx: int) -> Optional[int]:
    depth = 0
    saw_open = False
    for i in range(if_idx, len(lines)):
        for ch in _strip_attrs(lines[i]):
            if ch == "{":
                depth += 1
                saw_open = True
            elif ch == "}":
                depth -= 1
                if saw_open and depth == 0:
                    if i + 1 < len(lines) and lines[i + 1].lstrip().startswith("else"):
                        return None
                    return i
    return None


def _stable_values(assumptions: Sequence[str], *, var_types: Dict[str, str]) -> Dict[str, str]:
    out: Dict[str, str] = {}
    for raw in assumptions:
        expr = _unwrap_assume(raw)
        if not expr:
            continue
        m = re.match(r"^(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*==\s*(?P<rhs>.+)$", expr)
        if not m:
            continue
        lhs = m.group("lhs").strip()
        if lhs not in var_types:
            continue
        out[lhs] = _clean(m.group("rhs"))
    return out


def _identity_first_return_apply_procs(lines: Sequence[str]) -> set[str]:
    out: set[str] = set()
    for i, line in enumerate(lines):
        msig = _RE_PROC_SIG.match(line)
        if not msig:
            continue
        name = msig.group("name")
        if not name.endswith(".apply"):
            continue
        params = _parse_typed_names(msig.group("params") or "")
        returns = _parse_typed_names(msig.group("returns") or "")
        if not params or not returns or params[0][1] != returns[0][1]:
            continue
        block = _procedure_block(lines, i)
        if block is None:
            continue
        _proc_idx, open_idx, close_idx = block
        if _first_return_preserves_first_input(
            lines[open_idx + 1 : close_idx],
            first_input=params[0][0],
            first_return=returns[0][0],
        ):
            out.add(name)
    return out


def _first_return_preserves_first_input(
    body: Sequence[str],
    *,
    first_input: str,
    first_return: str,
) -> bool:
    aliases = {first_input}
    for line in body:
        m = _RE_ASSIGN.match(line.strip())
        if not m:
            continue
        lhs = m.group("lhs").strip()
        rhs = _clean(m.group("rhs"))
        rhs_is_alias = rhs in aliases
        if rhs_is_alias:
            aliases.add(lhs)
        elif lhs != first_input:
            aliases.discard(lhs)
    return first_return in aliases


def _parse_typed_names(raw: str) -> List[Tuple[str, str]]:
    out: List[Tuple[str, str]] = []
    for part in _split_csv(raw):
        if ":" not in part:
            continue
        name, typ = part.split(":", 1)
        name = name.strip()
        typ = typ.strip()
        if name and typ:
            out.append((name, typ))
    return out


def _mirror_only_writeback_lines(
    *,
    reg: str,
    idx_expr: str,
    value_expr: str,
    indent: str,
    var_types: Dict[str, str],
) -> List[str]:
    mtyp = _RE_REG_TYPE.match(var_types.get(reg, ""))
    if not mtyp:
        return []
    idx_width = int(mtyp.group("idx"))
    lines: List[str] = []

    def has(suffix: str) -> bool:
        return f"{reg}{suffix}" in var_types

    if has("__last_old_value"):
        lines.append(f"{indent}{reg}__last_old_value := {reg}[{idx_expr}];\n")
    if has("__last_index"):
        lines.append(f"{indent}{reg}__last_index := {idx_expr};\n")
    if has("__last_value"):
        lines.append(f"{indent}{reg}__last_value := {value_expr};\n")
    if has("__last_write_site") and has("__next_write_site"):
        lines.append(f"{indent}{reg}__last_write_site := {reg}__next_write_site;\n")
    if has("__wrote_any"):
        lines.append(f"{indent}{reg}__wrote_any := true;\n")
    if has("__wrote_index0") or has("__last0_old_value") or has("__last0_value"):
        lines.append(f"{indent}if ({idx_expr} == 0bv{idx_width}) {{\n")
        if has("__wrote_index0"):
            lines.append(f"{indent}    {reg}__wrote_index0 := true;\n")
        if has("__last0_old_value"):
            source = f"{reg}__last_old_value" if has("__last_old_value") else f"{reg}[{idx_expr}]"
            lines.append(f"{indent}    {reg}__last0_old_value := {source};\n")
        if has("__last0_value"):
            lines.append(f"{indent}    {reg}__last0_value := {value_expr};\n")
        lines.append(f"{indent}}}\n")
    return lines


def _previous_statement_index(lines: Sequence[str], start: int) -> Optional[int]:
    for i in range(start - 1, -1, -1):
        if lines[i].strip():
            return i
    return None


def _next_statement_index(lines: Sequence[str], start: int) -> Optional[int]:
    for i in range(start + 1, len(lines)):
        if lines[i].strip():
            return i
    return None


def _is_next_write_site_assignment(stmt: str, reg: str) -> bool:
    return re.match(rf"^\s*{re.escape(reg)}__next_write_site\s*:=", stmt) is not None


def _split_csv(raw: str) -> List[str]:
    out: List[str] = []
    cur: List[str] = []
    depth = 0
    for ch in raw:
        if ch == "," and depth == 0:
            text = "".join(cur).strip()
            if text:
                out.append(text)
            cur = []
            continue
        cur.append(ch)
        if ch in "([{":
            depth += 1
        elif ch in ")]}" and depth > 0:
            depth -= 1
    text = "".join(cur).strip()
    if text:
        out.append(text)
    return out


def _unwrap_assume(raw: object) -> str:
    text = str(raw or "").strip()
    if not text:
        return ""
    if text.endswith(";"):
        text = text[:-1].strip()
    if text.startswith("assume(") and text.endswith(")"):
        text = text[len("assume(") : -1].strip()
    elif text.startswith("assume "):
        text = text[len("assume ") :].strip()
    return strip_wrapping_parens(text)


def _specialized_table_body(
    proc_name: str,
    body: Sequence[str],
    *,
    stable_values: Dict[str, str],
) -> Optional[List[str]]:
    if not proc_name.endswith(".apply"):
        return None
    table = proc_name[: -len(".apply")]
    action_var = f"{table}.action_run"
    selected = stable_values.get(action_var)
    if not selected:
        return None

    goto_idx = _first_multitarget_goto(body)
    if goto_idx is None:
        return None
    if _prefix_writes_var(body[:goto_idx], action_var):
        return None
    branch = _branch_for_action(body, action_var=action_var, selected=selected)
    if branch is None:
        return None

    prefix = [ln for ln in body[:goto_idx] if not _RE_GOTO.match(ln.strip())]
    return [*prefix, *branch]


def _first_multitarget_goto(body: Sequence[str]) -> Optional[int]:
    for idx, line in enumerate(body):
        m = _RE_GOTO.match(line.strip())
        if not m:
            continue
        labels = [part.strip() for part in m.group("labels").split(",") if part.strip()]
        if len(labels) > 1:
            return idx
    return None


def _mainprocedure_stable_action_values(
    lines: Sequence[str],
    *,
    var_types: Dict[str, str],
) -> Dict[str, str]:
    block = _find_procedure_by_name(lines, "mainProcedure")
    if block is None:
        return {}
    _proc_idx, open_idx, close_idx = block
    body = lines[open_idx + 1 : close_idx]
    values: Dict[str, set[str]] = {}
    writes: set[str] = set()
    for line in body:
        stripped = line.strip()
        m = _RE_ASSUME_EQ.match(stripped)
        if m:
            lhs = m.group("lhs").strip()
            if lhs.endswith(".action_run") and lhs in var_types:
                values.setdefault(lhs, set()).add(_clean(m.group("rhs")))
            continue
        writes.update(_written_globals(stripped, var_types=var_types))
    return {
        lhs: next(iter(rhs_values))
        for lhs, rhs_values in values.items()
        if len(rhs_values) == 1 and lhs not in writes
    }


def _prefix_writes_var(lines: Sequence[str], name: str) -> bool:
    for line in lines:
        if name in _written_globals(line.strip(), var_types={name: ""}):
            return True
    return False


def _written_globals(stmt: str, *, var_types: Dict[str, str]) -> set[str]:
    out: set[str] = set()
    mh = re.match(r"^\s*havoc\s+(?P<vars>[^;]+)\s*;\s*$", stmt)
    if mh:
        for raw in mh.group("vars").split(","):
            name = raw.strip()
            if name in var_types:
                out.add(name)
        return out

    ma = re.match(r"^\s*(?P<lhs>[^:;]+?)\s*:=\s*.*;\s*$", stmt)
    if ma:
        for raw in ma.group("lhs").split(","):
            name = raw.strip()
            if name in var_types:
                out.add(name)
    return out


def _branch_for_action(body: Sequence[str], *, action_var: str, selected: str) -> Optional[List[str]]:
    label_positions = [idx for idx, line in enumerate(body) if _RE_LABEL.match(line.strip())]
    label_positions.append(len(body))
    for pos, start in enumerate(label_positions[:-1]):
        end = label_positions[pos + 1]
        branch = body[start + 1 : end]
        if not _branch_matches(branch, action_var=action_var, selected=selected):
            continue
        out: List[str] = []
        for line in branch:
            stripped = line.strip()
            if _RE_GOTO.match(stripped):
                break
            if _is_action_assume(stripped, action_var=action_var):
                continue
            out.append(line)
        return out
    return None


def _branch_matches(branch: Sequence[str], *, action_var: str, selected: str) -> bool:
    for line in branch:
        m = _RE_ASSUME_EQ.match(line.strip())
        if not m or m.group("lhs").strip() != action_var:
            continue
        return _clean(m.group("rhs")) == selected
    return False


def _is_action_assume(stmt: str, *, action_var: str) -> bool:
    m = _RE_ASSUME_EQ.match(stmt)
    return bool(m and m.group("lhs").strip() == action_var)


def _procedure_block(lines: Sequence[str], proc_idx: int) -> Optional[Tuple[int, int, int]]:
    open_idx: Optional[int] = None
    for i in range(proc_idx, len(lines)):
        if "{" in _strip_attrs(lines[i]):
            open_idx = i
            break
        if i > proc_idx and _RE_PROC_HEADER.match(lines[i]):
            return None
    if open_idx is None:
        return None

    depth = 0
    saw_open = False
    for i in range(open_idx, len(lines)):
        text = _strip_attrs(lines[i])
        for ch in text:
            if ch == "{":
                depth += 1
                saw_open = True
            elif ch == "}":
                depth -= 1
                if saw_open and depth == 0:
                    return proc_idx, open_idx, i
    return None


def _find_procedure_by_name(lines: Sequence[str], name: str) -> Optional[Tuple[int, int, int]]:
    for i, line in enumerate(lines):
        m = _RE_PROC_HEADER.match(line)
        if not m or m.group("name") != name:
            continue
        return _procedure_block(lines, i)
    return None


def _strip_attrs(line: str) -> str:
    return re.sub(r"\{:[^}]*\}", "", line)


def _clean(expr: str) -> str:
    return strip_wrapping_parens(normalize_expr(str(expr or "").strip()))
