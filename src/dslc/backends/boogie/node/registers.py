from __future__ import annotations

import re
from typing import Dict, Optional


# Compatibility helpers for register mirrors.
#
# P4B is now responsible for emitting register write mirrors natively. The
# backfill pass below is intentionally a legacy safety net for old/imported BPL
# that still has register arrays but lacks the mirror declarations or write-body
# updates expected by the distributed harness and wraparound certificates.


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
    return _collect_register_arrays_for_names(prefixed_bpl, reg_names)


def find_unmarked_register_arrays(
    prefixed_bpl: str,
    marked_reg_types: Dict[str, tuple[str, str]],
) -> list[str]:
    """
    Find register-looking arrays that were not advertised by P4B register markers.

    DSLC primarily trusts P4B's `// <alias>_Register <name>` marker so the
    distributed harness can distinguish stateful registers from arbitrary Boogie
    maps.  On P4B-generated units, however, a register array with a `<reg>.write`
    helper but no marker is almost certainly a translator contract bug.  Failing
    fast here prevents the harness from silently treating the model as if it had
    no registers at all.
    """
    marked = set(marked_reg_types.keys())
    by_write_proc = _collect_register_arrays_from_write_procs(prefixed_bpl)
    return sorted(name for name in by_write_proc.keys() if name not in marked)


def backfill_legacy_register_write_mirrors(
    prefixed_bpl: str,
    reg_types: Dict[str, tuple[str, str]],
) -> str:
    """
    Add register mirror declarations/body updates only when a BPL unit lacks them.

    New P4B output should already contain these mirrors.  This function keeps
    legacy hand-written/generated Boogie imports usable without making Python the
    semantic owner of register writes again.
    """
    if not reg_types:
        return prefixed_bpl

    type_aliases = _collect_type_aliases(prefixed_bpl)
    existing_var_names = _collect_var_names(prefixed_bpl)
    reg_types_to_instrument = {
        reg_name: types
        for reg_name, types in reg_types.items()
        if not _has_complete_register_mirrors(prefixed_bpl, reg_name, existing_var_names)
    }
    if not reg_types_to_instrument:
        return prefixed_bpl

    def register_aux_decls(reg_name: str, idx_type: str, elem_type: str, indent: str) -> str:
        decls = [
            (f"{reg_name}__last_index", idx_type),
            (f"{reg_name}__last_value", elem_type),
            (f"{reg_name}__last_old_value", elem_type),
            (f"{reg_name}__wrote_any", "bool"),
            (f"{reg_name}__wrote_index0", "bool"),
            (f"{reg_name}__last0_old_value", elem_type),
            (f"{reg_name}__last0_value", elem_type),
            (f"{reg_name}__next_write_site", "int"),
            (f"{reg_name}__last_write_site", "int"),
        ]
        return "".join(f"{indent}var {name}: {typ};\n" for name, typ in decls if name not in existing_var_names)

    out = prefixed_bpl

    # Inject auxiliary register-tracking globals next to each register array.
    for reg_name, (idx_type, elem_type) in reg_types_to_instrument.items():
        var_re = re.compile(
            rf"^(\s*var\s+{re.escape(reg_name)}\s*:\s*\[[^\]]+\]\s*[^;]+;\s*)$",
            re.MULTILINE,
        )

        def _var_repl(m: re.Match[str]) -> str:
            indent = re.match(r"^(\s*)", m.group(1)).group(1)
            aux = register_aux_decls(reg_name, idx_type, elem_type, indent)
            return m.group(1) if not aux else m.group(1) + "\n" + aux

        out, _ = var_re.subn(_var_repl, out, count=1)

    # Extend modifies clauses that already mention the register array.
    mod_re = re.compile(r"^(\s*)modifies\s+([^;]+);", re.MULTILINE)

    def _mod_repl(m: re.Match[str]) -> str:
        indent = m.group(1)
        clause = m.group(2)
        items = [x.strip() for x in clause.split(",") if x.strip()]
        items_set = set(items)
        for reg_name in reg_types_to_instrument.keys():
            if reg_name in items_set:
                extras = [
                    f"{reg_name}__last_index",
                    f"{reg_name}__last_value",
                    f"{reg_name}__last_old_value",
                    f"{reg_name}__wrote_any",
                    f"{reg_name}__wrote_index0",
                    f"{reg_name}__last0_old_value",
                    f"{reg_name}__last0_value",
                    f"{reg_name}__last_write_site",
                ]
                for extra in extras:
                    if extra not in items_set:
                        items.append(extra)
                        items_set.add(extra)
        return f"{indent}modifies {', '.join(items)};"

    out = mod_re.sub(_mod_repl, out)

    # Instrument each register.write procedure to record last write + index-0 writes.
    for reg_name, (idx_type, _) in reg_types_to_instrument.items():
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
        idx_zero = _render_zero_literal(idx_type, type_aliases=type_aliases)
        extra_lines: list[str] = []
        if re.search(rf"\b{re.escape(reg_name)}__last_old_value\s*:=", body) is None:
            extra_lines.append(f"{indent}{reg_name}__last_old_value := {reg_name}[{idx_expr}];")
        if re.search(rf"\b{re.escape(reg_name)}__last_index\s*:=", body) is None:
            extra_lines.append(f"{indent}{reg_name}__last_index := {idx_expr};")
        if re.search(rf"\b{re.escape(reg_name)}__last_value\s*:=", body) is None:
            extra_lines.append(f"{indent}{reg_name}__last_value := {val_expr};")
        if re.search(rf"\b{re.escape(reg_name)}__last_write_site\s*:=", body) is None:
            extra_lines.append(f"{indent}{reg_name}__last_write_site := {reg_name}__next_write_site;")
        if re.search(rf"\b{re.escape(reg_name)}__wrote_any\s*:=\s*true\s*;", body) is None:
            extra_lines.append(f"{indent}{reg_name}__wrote_any := true;")

        index0_lines: list[str] = []
        if re.search(rf"\b{re.escape(reg_name)}__wrote_index0\s*:=\s*true\s*;", body) is None:
            index0_lines.append(f"{indent}  {reg_name}__wrote_index0 := true;")
        if re.search(rf"\b{re.escape(reg_name)}__last0_old_value\s*:=", body) is None:
            index0_lines.append(f"{indent}  {reg_name}__last0_old_value := {reg_name}__last_old_value;")
        if re.search(rf"\b{re.escape(reg_name)}__last0_value\s*:=", body) is None:
            index0_lines.append(f"{indent}  {reg_name}__last0_value := {val_expr};")
        if index0_lines:
            extra_lines.append(f"{indent}if ({idx_expr} == {idx_zero}) {{")
            extra_lines.extend(index0_lines)
            extra_lines.append(f"{indent}}}")
        if not extra_lines:
            continue
        replacement = line + "\n" + "\n".join(extra_lines)
        new_body = body[: m.start()] + replacement + body[m.end() :]
        out = out[:body_start] + new_body + out[body_end:]

    return out


def find_incomplete_register_write_mirrors(
    prefixed_bpl: str,
    reg_types: Dict[str, tuple[str, str]],
) -> list[str]:
    """
    Return register arrays whose P4B write mirrors are missing or incomplete.

    This is the non-mutating counterpart to the legacy backfill pass.  DSLC uses
    it on P4B-generated nodes to enforce the ownership boundary: P4-local
    register semantics must be emitted by P4B, while DSLC may only consume them.
    """
    if not reg_types:
        return []
    existing_var_names = _collect_var_names(prefixed_bpl)
    return [
        reg_name
        for reg_name in sorted(reg_types.keys())
        if not _has_complete_register_mirrors(prefixed_bpl, reg_name, existing_var_names)
    ]


def assert_complete_register_write_mirrors(
    prefixed_bpl: str,
    reg_types: Dict[str, tuple[str, str]],
) -> None:
    """
    Fail if a P4B-generated node lacks complete register write mirrors.

    The exception is deliberately a ValueError so callers can wrap it in their
    own domain-specific error type without importing backend orchestration code
    into this node-local helper module.
    """
    missing = find_incomplete_register_write_mirrors(prefixed_bpl, reg_types)
    if missing:
        raise ValueError(
            "P4B output is missing complete register write mirrors for: "
            + ", ".join(missing)
            + ". Register mirror semantics belong in P4B; DSLC only applies "
            + "legacy backfill to imported .bpl files."
        )


def instrument_register_writes(prefixed_bpl: str, reg_types: Dict[str, tuple[str, str]]) -> str:
    """Backward-compatible name for the legacy register mirror backfill pass."""

    return backfill_legacy_register_write_mirrors(prefixed_bpl, reg_types)


def _collect_var_names(bpl: str) -> set[str]:
    names: set[str] = set()
    for m in re.finditer(r"^\s*var\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*:", bpl, flags=re.MULTILINE):
        names.add(m.group("name"))
    return names


def _collect_register_arrays_for_names(
    bpl: str,
    reg_names: list[str],
) -> Dict[str, tuple[str, str]]:
    reg_types: Dict[str, tuple[str, str]] = {}
    for name in reg_names:
        var_re = re.compile(
            rf"^\s*var\s+{re.escape(name)}\s*:\s*\[(?P<idx>[^\]]+)\]\s*(?P<elem>[A-Za-z0-9_\.\$]+)\s*;",
            re.MULTILINE,
        )
        m = var_re.search(bpl)
        if not m:
            continue
        idx = m.group("idx").strip()
        elem = m.group("elem").strip()
        reg_types[name] = (idx, elem)
    return reg_types


def _collect_register_arrays_from_write_procs(bpl: str) -> Dict[str, tuple[str, str]]:
    names = [
        m.group("name")
        for m in re.finditer(
            r"^\s*procedure(?:\s*\{:[^}]+\}\s*)*\s+(?P<name>[A-Za-z0-9_\.\$]+)\.write\b",
            bpl,
            flags=re.MULTILINE,
        )
    ]
    return _collect_register_arrays_for_names(bpl, names)


def _has_complete_register_mirrors(bpl: str, reg_name: str, var_names: set[str]) -> bool:
    required = {
        f"{reg_name}__last_index",
        f"{reg_name}__last_value",
        f"{reg_name}__last_old_value",
        f"{reg_name}__wrote_any",
        f"{reg_name}__wrote_index0",
        f"{reg_name}__last0_old_value",
        f"{reg_name}__last0_value",
        f"{reg_name}__next_write_site",
        f"{reg_name}__last_write_site",
    }
    if not required.issubset(var_names):
        return False

    write_modifies = set(required)
    # The write helper reads `__next_write_site`, but each callsite sets it.
    write_modifies.discard(f"{reg_name}__next_write_site")
    if not _procedure_modifies_all(bpl, f"{reg_name}.write", write_modifies):
        return False

    span = _find_procedure_body_span(bpl, f"{reg_name}.write")
    if not span:
        return False
    body = bpl[span[0] : span[1]]
    required_updates = [
        rf"\b{re.escape(reg_name)}__last_index\s*:=",
        rf"\b{re.escape(reg_name)}__last_value\s*:=",
        rf"\b{re.escape(reg_name)}__last_old_value\s*:=",
        rf"\b{re.escape(reg_name)}__last_write_site\s*:=",
        rf"\b{re.escape(reg_name)}__wrote_any\s*:=\s*true\s*;",
        rf"\b{re.escape(reg_name)}__wrote_index0\s*:=\s*true\s*;",
        rf"\b{re.escape(reg_name)}__last0_old_value\s*:=",
        rf"\b{re.escape(reg_name)}__last0_value\s*:=",
    ]
    return all(re.search(pattern, body) is not None for pattern in required_updates)


def _procedure_modifies_all(bpl: str, proc_name: str, required: set[str]) -> bool:
    proc_re = re.compile(
        rf"^\s*procedure(?:\s*\{{:[^}}]+\}}\s*)*\s+{re.escape(proc_name)}\b",
        re.MULTILINE,
    )
    m = proc_re.search(bpl)
    if not m:
        return False
    brace_start = bpl.find("{", m.end())
    if brace_start == -1:
        return False
    header = bpl[m.start() : brace_start]
    mod_re = re.search(r"\bmodifies\s+([^;]+);", header, flags=re.DOTALL)
    if not mod_re:
        return False
    mods = {x.strip() for x in mod_re.group(1).split(",") if x.strip()}
    return required.issubset(mods)


def _collect_type_aliases(bpl: str) -> Dict[str, str]:
    """
    Collect simple Boogie type aliases of the form:
      type <name> = <rhs>;

    We use this to type-check index-0 comparisons for register mirrors when the
    index type is an alias (e.g., `sw_lid_t = bv32`).
    """

    out: Dict[str, str] = {}
    for m in re.finditer(
        r"^\s*type\s+(?P<name>[A-Za-z_][A-Za-z0-9_\.\$]*)\s*=\s*(?P<rhs>[^;]+)\s*;\s*$",
        bpl,
        flags=re.MULTILINE,
    ):
        name = m.group("name").strip()
        rhs = m.group("rhs").strip()
        if name and rhs:
            out[name] = rhs
    return out


def _render_zero_literal(var_type: str, *, type_aliases: Optional[Dict[str, str]] = None) -> str:
    var_type = var_type.strip()
    if type_aliases:
        seen: set[str] = set()
        cur = var_type
        for _ in range(16):
            if cur in seen:
                break
            seen.add(cur)
            nxt = type_aliases.get(cur)
            if not nxt:
                break
            cur = nxt.strip()
        var_type = cur
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
