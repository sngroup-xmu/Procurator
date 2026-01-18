from __future__ import annotations

import re
from typing import Dict, Optional


def collect_register_arrays(prefixed_bpl: str, alias: str) -> Dict[str, tuple[str, str]]:
    """
    Collect register arrays from prefixed Boogie text.

    We identify P4 registers via P4B's emitted comment marker:
      // <alias>_Register <name>
    and then locate the corresponding array declaration:
      var <name>:[<idx>] <elem>;
    """
    reg_names: list[str] = []
    comment_re = re.compile(
        rf"^\s*//\s*{re.escape(alias)}_Register\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*$",
        re.MULTILINE,
    )
    for m in comment_re.finditer(prefixed_bpl):
        reg_names.append(m.group("name"))
    if not reg_names:
        return {}
    reg_types: Dict[str, tuple[str, str]] = {}
    for name in reg_names:
        var_re = re.compile(
            rf"^\s*var\s+{re.escape(name)}\s*:\s*\[(?P<idx>[^\]]+)\]\s*(?P<elem>[A-Za-z0-9_\.\$]+)\s*;",
            re.MULTILINE,
        )
        m = var_re.search(prefixed_bpl)
        if not m:
            continue
        idx = m.group("idx").strip()
        elem = m.group("elem").strip()
        reg_types[name] = (idx, elem)
    return reg_types


def instrument_register_writes(prefixed_bpl: str, reg_types: Dict[str, tuple[str, str]]) -> str:
    if not reg_types:
        return prefixed_bpl

    def register_aux_decls(reg_name: str, idx_type: str, elem_type: str, indent: str) -> str:
        return (
            f"{indent}var {reg_name}__last_index: {idx_type};\n"
            f"{indent}var {reg_name}__last_value: {elem_type};\n"
            f"{indent}var {reg_name}__wrote_any: bool;\n"
            f"{indent}var {reg_name}__wrote_index0: bool;\n"
            f"{indent}var {reg_name}__last0_value: {elem_type};\n"
        )

    out = prefixed_bpl

    # Inject auxiliary register-tracking globals next to each register array.
    for reg_name, (idx_type, elem_type) in reg_types.items():
        var_re = re.compile(
            rf"^(\s*var\s+{re.escape(reg_name)}\s*:\s*\[[^\]]+\]\s*[^;]+;\s*)$",
            re.MULTILINE,
        )

        def _var_repl(m: re.Match[str]) -> str:
            indent = re.match(r"^(\s*)", m.group(1)).group(1)
            return m.group(1) + "\n" + register_aux_decls(reg_name, idx_type, elem_type, indent)

        out, _ = var_re.subn(_var_repl, out, count=1)

    # Extend modifies clauses that already mention the register array.
    mod_re = re.compile(r"^(\s*)modifies\s+([^;]+);", re.MULTILINE)

    def _mod_repl(m: re.Match[str]) -> str:
        indent = m.group(1)
        clause = m.group(2)
        items = [x.strip() for x in clause.split(",") if x.strip()]
        items_set = set(items)
        for reg_name in reg_types.keys():
            if reg_name in items_set:
                extras = [
                    f"{reg_name}__last_index",
                    f"{reg_name}__last_value",
                    f"{reg_name}__wrote_any",
                    f"{reg_name}__wrote_index0",
                    f"{reg_name}__last0_value",
                ]
                for extra in extras:
                    if extra not in items_set:
                        items.append(extra)
                        items_set.add(extra)
        return f"{indent}modifies {', '.join(items)};"

    out = mod_re.sub(_mod_repl, out)

    # Instrument each register.write procedure to record last write + index-0 writes.
    for reg_name, (idx_type, _) in reg_types.items():
        proc_name = f"{reg_name}.write"
        span = _find_procedure_body_span(out, proc_name)
        if not span:
            continue
        body_start, body_end = span
        body = out[body_start:body_end]
        assign_re = re.compile(
            rf"^\s*{re.escape(reg_name)}\s*\[(?P<idx>[^\]]+)\]\s*:=\s*(?P<val>[^;]+);",
            re.MULTILINE,
        )
        m = assign_re.search(body)
        if not m:
            continue
        line = m.group(0)
        indent = re.match(r"^(\s*)", line).group(1)
        idx_expr = m.group("idx").strip()
        val_expr = m.group("val").strip()
        idx_zero = _render_zero_literal(idx_type)
        extra = "\n".join(
            [
                f"{indent}{reg_name}__last_index := {idx_expr};",
                f"{indent}{reg_name}__last_value := {val_expr};",
                f"{indent}{reg_name}__wrote_any := true;",
                f"{indent}if ({idx_expr} == {idx_zero}) {{",
                f"{indent}  {reg_name}__wrote_index0 := true;",
                f"{indent}  {reg_name}__last0_value := {val_expr};",
                f"{indent}}}",
            ]
        )
        replacement = line + "\n" + extra
        new_body = body[: m.start()] + replacement + body[m.end() :]
        out = out[:body_start] + new_body + out[body_end:]

    return out


def _render_zero_literal(var_type: str) -> str:
    var_type = var_type.strip()
    if var_type == "bool":
        return "false"
    if var_type.startswith("bv") and var_type[2:].isdigit():
        return f"0{var_type}"
    return "0"


def _find_procedure_body_span(bpl: str, proc_name: str) -> Optional[tuple[int, int]]:
    proc_re = re.compile(
        rf"^\s*procedure(?:\s*\{{:[^}}]+\}}\s*)*\s+{re.escape(proc_name)}\b",
        re.MULTILINE,
    )
    m = proc_re.search(bpl)
    if not m:
        return None
    brace_start = bpl.find("{", m.end())
    if brace_start == -1:
        return None
    depth = 0
    body_start = None
    body_end = None
    for idx in range(brace_start, len(bpl)):
        ch = bpl[idx]
        if ch == "{":
            depth += 1
            if depth == 1:
                body_start = idx + 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                body_end = idx
                break
    if body_start is None or body_end is None:
        return None
    return body_start, body_end

