from __future__ import annotations

import re
from typing import Dict, List, Optional, Sequence, Tuple

from .wraparound_common import (
    WraparoundConfig,
    WraparoundStage,
    WraparoundTarget,
    WraparoundTransformError,
    _CLOSURE_UNROLL_MARKER_PREFIX,
    _RE_CALL_MAIN,
    _RE_GLOBAL_VAR,
    _RE_PHASE_RESET,
    _RE_PHASE_WRAP,
    _RE_PROC_MAIN,
    _RE_PROC_SCHED,
    _RE_PROC_ULTIMATE_START,
    _RE_STEP_INC,
    _RE_WHILE_STEP_BOUND,
    _RE_WHILE_TRUE,
)


_RE_TYPE_DEF = re.compile(r"^type\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?P<rhs>[^;]+);\s*$")
_RE_ARRAY_TYPE = re.compile(r"^\[\s*(?P<idx>[^\]]+)\s*\]\s*(?P<elem>\S+)\s*$")
_RE_BV_TYPE = re.compile(r"^bv(?P<w>\d+)$")


def _parse_global_var_types(lines: Sequence[str]) -> Dict[str, str]:
    types: Dict[str, str] = {}
    for line in lines:
        m = _RE_GLOBAL_VAR.match(line.strip())
        if not m:
            continue
        types[m.group("name")] = m.group("type").strip()
    return types


def _collect_type_aliases(lines: Sequence[str]) -> Dict[str, str]:
    aliases: Dict[str, str] = {}
    for line in lines:
        m = _RE_TYPE_DEF.match(line.strip())
        if not m:
            continue
        aliases[m.group("name")] = m.group("rhs").strip()
    return aliases


def _resolve_bv_width(type_name: str, aliases: Dict[str, str]) -> Optional[int]:
    cur = type_name.strip()
    seen: set[str] = set()
    while True:
        m = _RE_BV_TYPE.match(cur)
        if m:
            return int(m.group("w"))
        if cur in seen:
            return None
        seen.add(cur)
        nxt = aliases.get(cur)
        if nxt is None:
            return None
        cur = nxt.strip()


def _find_reg_decl(
    var_types: Dict[str, str], type_aliases: Dict[str, str], reg_var: str
) -> Optional[Tuple[int, int]]:
    """Return (index_width, elem_width) for a Boogie register array variable.

    Supports both the canonical `[bv32]bv16` form and typedef'd aliases such as:
      type sw_lid_t = bv32;
      var notification_cnt:[sw_lid_t]bv8;
    """

    typ = var_types.get(reg_var)
    if typ is None:
        return None

    m = _RE_ARRAY_TYPE.match(typ)
    if not m:
        return None

    idx_type = m.group("idx").strip()
    elem_type = m.group("elem").strip()
    idx_w = _resolve_bv_width(idx_type, type_aliases)
    elem_w = _resolve_bv_width(elem_type, type_aliases)
    if idx_w is None or elem_w is None:
        raise WraparoundTransformError(f"unsupported register type for {reg_var}: {typ}")
    return idx_w, elem_w


_RE_BV_LIT = re.compile(r"^(?P<val>\d+)bv(?P<w>\d+)$")
_RE_SIMPLE_VAR = re.compile(r"^[A-Za-z_][A-Za-z0-9_.]*$")


def _coerce_bv_expr_to_width(var_types: Dict[str, str], expr: str, *, target_w: int) -> str:
    """Best-effort coerce a Boogie expression to bv<target_w> by zero-extension.

    Wraparound candidates from meta often reference P4 metadata fields (e.g.,
    `meta.spineswitchidx`) whose bitwidth is smaller than the register index
    width emitted by P4B (typically bv32). The original program uses explicit
    zero-extension (e.g., `0bv16++meta.spineswitchidx`). For wraparound stages
    we need the index expression to typecheck against the register array type.

    We only handle the common/simple cases here:
      - plain variables that appear in `var_types` as `bvN`
      - bitvector literals like `7bv16`

    For complex expressions, we return `expr` unchanged and let Boogie/U.
    typecheck catch mismatches (with a clear error).
    """

    e = expr.strip()
    if not e:
        return e

    # bv literal (e.g., 7bv16)
    m = _RE_BV_LIT.match(e)
    if m:
        src_w = int(m.group("w"))
        if src_w == target_w:
            return e
        if src_w < target_w:
            return f"0bv{target_w - src_w}++{e}"
        raise WraparoundTransformError(f"index expr width bv{src_w} > bv{target_w}: {expr}")

    # plain var (e.g., clientTrack_meta.spineswitchidx)
    if _RE_SIMPLE_VAR.match(e):
        t = var_types.get(e)
        if t:
            mt = _RE_BV_TYPE.match(t)
            if mt:
                src_w = int(mt.group("w"))
                if src_w == target_w:
                    return e
                if src_w < target_w:
                    return f"0bv{target_w - src_w}++{e}"
                raise WraparoundTransformError(f"index expr width bv{src_w} > bv{target_w}: {expr}")

    return e


def _collect_queue_like_vars(var_types: Dict[str, str]) -> List[str]:
    out: List[str] = []
    for name, typ in var_types.items():
        if typ != "int":
            continue
        if name.endswith("_inbox_count") or name.endswith("_egress_count"):
            out.append(name)
    return sorted(out)


def _has_global_var(var_types: Dict[str, str], name: str) -> bool:
    return name in var_types


def _default_cutpoint_cond(var_types: Dict[str, str]) -> str:
    conds: List[str] = []
    if _has_global_var(var_types, "procurator_phase"):
        conds.append("(procurator_phase == 0)")
    if not conds:
        return "true"
    return " && ".join(conds)


def _default_proj_vars(var_types: Dict[str, str]) -> List[str]:
    proj: List[str] = []
    if _has_global_var(var_types, "procurator_phase"):
        proj.append("procurator_phase")
    proj.extend(_collect_queue_like_vars(var_types))
    return proj


def _infer_deterministic_scheduler_period(lines: Sequence[str]) -> Optional[int]:
    """
    Infer the period of the deterministic round-robin scheduler.

    In the sequential harness we emit:
      if (procurator_phase == period-1) { procurator_phase := 0; } else { ... }
    """

    candidates: List[int] = []
    for i, line in enumerate(lines):
        m = _RE_PHASE_WRAP.search(line)
        if not m:
            continue

        n = int(m.group("n"))
        depth = 0
        saw_open = False
        found_reset = False

        # Only accept a phase guard if the corresponding `if`-block contains a
        # `procurator_phase := 0;` reset. This prevents accidentally matching
        # other `if (procurator_phase == 0) { ... }` dispatch code that may
        # appear before the actual wrap-around reset.
        for j in range(i, len(lines)):
            cur = lines[j]
            if _RE_PHASE_RESET.search(cur):
                found_reset = True
            for ch in cur:
                if ch == "{":
                    depth += 1
                    saw_open = True
                elif ch == "}":
                    depth -= 1
            if saw_open and depth == 0:
                break

        if found_reset and saw_open:
            candidates.append(n + 1)

    return max(candidates) if candidates else None


def _find_procedure_block(no_nl_lines: Sequence[str], proc_re: re.Pattern[str]) -> Tuple[int, int, int]:
    proc_idx = None
    for i, ln in enumerate(no_nl_lines):
        if proc_re.match(ln.strip()):
            proc_idx = i
            break
    if proc_idx is None:
        raise WraparoundTransformError(f"procedure not found: {proc_re.pattern}")

    body_open_idx = None
    for i in range(proc_idx, len(no_nl_lines)):
        if "{" in no_nl_lines[i]:
            body_open_idx = i
            break
    if body_open_idx is None:
        raise WraparoundTransformError(f"procedure body not found: {proc_re.pattern}")

    depth = 0
    saw_open = False
    body_close_idx = None
    for i in range(body_open_idx, len(no_nl_lines)):
        for ch in no_nl_lines[i]:
            if ch == "{":
                depth += 1
                saw_open = True
            elif ch == "}":
                depth -= 1
                if saw_open and depth == 0:
                    body_close_idx = i
                    break
        if body_close_idx is not None:
            break
    if body_close_idx is None:
        raise WraparoundTransformError(f"procedure body end not found: {proc_re.pattern}")
    return proc_idx, body_open_idx, body_close_idx


def _find_brace_block_end(no_nl_lines: Sequence[str], start_idx: int) -> int:
    """
    Find the line index where the block that starts at `start_idx` ends.

    The line at `start_idx` may be an `else if (...) {` line (i.e., it may
    contain a leading `}` from the previous branch); we ignore braces before the
    first `{` on the header line.
    """

    header = no_nl_lines[start_idx]
    brace_pos = header.find("{")
    if brace_pos < 0:
        raise WraparoundTransformError("expected '{' on block header line")

    depth = 1
    for ch in header[brace_pos + 1 :]:
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return start_idx

    for i in range(start_idx + 1, len(no_nl_lines)):
        for ch in no_nl_lines[i]:
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    return i
    raise WraparoundTransformError("failed to find end of block")


def _extract_main_phase_bodies(lines: Sequence[str], period: int) -> List[List[str]]:
    if period <= 0:
        raise WraparoundTransformError("invalid deterministic scheduler period")

    no_nl_lines = [ln.rstrip("\n") for ln in lines]
    _, body_open_idx, body_close_idx = _find_procedure_block(no_nl_lines, _RE_PROC_SCHED)

    phase_blocks: Dict[int, List[str]] = {}
    for i in range(body_open_idx, body_close_idx + 1):
        m = _RE_PHASE_WRAP.search(no_nl_lines[i])
        if not m:
            continue
        phase = int(m.group("n"))
        if phase < 0 or phase >= period:
            continue
        end_idx = _find_brace_block_end(no_nl_lines, i)
        if any(_RE_PHASE_RESET.search(no_nl_lines[j]) for j in range(i, end_idx + 1)):
            # This is the phase wrap-reset block (the one used to infer `period`).
            continue
        if phase in phase_blocks:
            continue
        phase_blocks[phase] = [str(ln) for ln in lines[i + 1 : end_idx]]

    return [phase_blocks.get(phase, []) for phase in range(period)]


def _min_leading_indent(block: Sequence[str]) -> str:
    min_spaces: Optional[int] = None
    for ln in block:
        if not ln.strip():
            continue
        spaces = len(re.match(r"^(\s*)", ln).group(1))  # type: ignore[union-attr]
        if min_spaces is None or spaces < min_spaces:
            min_spaces = spaces
    return " " * (min_spaces or 0)


def _reindent_block(block: Sequence[str], base_indent: str, new_indent: str) -> List[str]:
    out: List[str] = []
    for ln in block:
        if ln.startswith(base_indent):
            out.append(new_indent + ln[len(base_indent) :])
        else:
            out.append(ln)
    return out


def _inline_deterministic_round_into_mainprocedure(lines: List[str], *, period: int, steps: int) -> None:
    """
    For closure_check, replace the `call main();` unrolled scheduler steps with a
    phase-specialized, loop-free round.
    """

    if steps <= 0:
        return

    phase_bodies = _extract_main_phase_bodies(lines, period)

    no_nl_lines = [ln.rstrip("\n") for ln in lines]
    _, body_open_idx, body_close_idx = _find_procedure_block(no_nl_lines, _RE_PROC_MAIN)
    marker = f"{_CLOSURE_UNROLL_MARKER_PREFIX} {steps} steps (wraparound)"

    marker_idx = None
    for i in range(body_open_idx, body_close_idx + 1):
        if marker in no_nl_lines[i]:
            marker_idx = i
            break
    if marker_idx is None:
        return

    call_idxs: List[int] = []
    for i in range(marker_idx + 1, body_close_idx + 1):
        if _RE_CALL_MAIN.match(no_nl_lines[i].strip()):
            call_idxs.append(i)
            if len(call_idxs) == steps:
                break

    if len(call_idxs) != steps:
        raise WraparoundTransformError(
            f"expected {steps} `call main();` occurrences after UNROLLED marker, got {len(call_idxs)}"
        )

    # Replace bottom-to-top to keep indices stable.
    for step_idx, idx in reversed(list(enumerate(call_idxs))):
        phase = step_idx % period
        indent = re.match(r"^(\s*)", lines[idx]).group(1)  # type: ignore[union-attr]
        base = _min_leading_indent(phase_bodies[phase])
        body = _reindent_block(phase_bodies[phase], base, indent)
        next_phase = 0 if phase == period - 1 else phase + 1
        repl: List[str] = []
        repl.append(f"{indent}// wraparound inlined phase {phase} (generated)\n")
        repl.append(f"{indent}assume procurator_phase == {phase};\n")
        repl.extend(body)
        repl.append(f"{indent}procurator_phase := {next_phase};\n")
        lines[idx : idx + 1] = repl


def _is_mainprocedure_loop_header(line: str) -> bool:
    stripped = line.strip()
    return _RE_WHILE_TRUE.match(stripped) is not None or _RE_WHILE_STEP_BOUND.match(stripped) is not None


def analyze_bpl_for_wraparound(
    *,
    bpl_text: str,
    pump_reg: str,
    accel_regs: Sequence[str],
    index_value: int = 0,
    index_expr: Optional[str] = None,
    proj_vars: Optional[Sequence[str]] = None,
    proj_predicates: Optional[Sequence[str]] = None,
    cutpoint_cond: Optional[str] = None,
    step_op: str = "add",
    step_delta: int = 1,
    stage: WraparoundStage,
) -> WraparoundConfig:
    lines = bpl_text.splitlines(keepends=False)
    var_types = _parse_global_var_types(lines)
    type_aliases = _collect_type_aliases(lines)

    decl = _find_reg_decl(var_types, type_aliases, pump_reg)
    if decl is None:
        raise WraparoundTransformError(f"register not found: {pump_reg}")
    index_w, elem_w = decl

    # If the caller passes an index expression (typically inferred from meta),
    # ensure it typechecks against the register index width.
    if index_expr is not None:
        index_expr = _coerce_bv_expr_to_width(var_types, index_expr, target_w=index_w)

    use_last0 = index_expr is None and index_value == 0 and f"{pump_reg}__last0_value" in var_types
    idx_value: Optional[int] = None if index_expr is not None else index_value
    pump_target = WraparoundTarget(
        reg_var=pump_reg,
        elem_width=elem_w,
        index_width=index_w,
        index_value=idx_value,
        index_expr_override=index_expr,
        use_last0_value=use_last0,
    )

    accel_targets: List[WraparoundTarget] = []
    for r in accel_regs:
        d = _find_reg_decl(var_types, type_aliases, r)
        if d is None:
            raise WraparoundTransformError(f"register not found: {r}")
        idx_w, el_w = d
        if idx_w != index_w or el_w != elem_w:
            raise WraparoundTransformError(
                f"register type mismatch for {r}: expected [bv{index_w}]bv{elem_w}, got [bv{idx_w}]bv{el_w}"
            )
        accel_targets.append(
            WraparoundTarget(
                reg_var=r,
                elem_width=el_w,
                index_width=idx_w,
                index_value=idx_value,
                index_expr_override=index_expr,
                use_last0_value=(index_expr is None and index_value == 0 and f"{r}__last0_value" in var_types),
            )
        )

    proj = tuple(proj_vars) if proj_vars is not None else tuple(_default_proj_vars(var_types))
    cond = cutpoint_cond if cutpoint_cond is not None else _default_cutpoint_cond(var_types)

    # Filter projection vars to scalars we can snapshot as locals.
    filtered: List[str] = []
    for v in proj:
        t = var_types.get(v)
        if t is None:
            continue
        if "[" in t or "]" in t:
            continue
        filtered.append(v)

    if step_op not in {"add", "sub"}:
        raise WraparoundTransformError(f"unsupported step_op: {step_op}")
    try:
        delta_int = int(step_delta)
    except Exception as e:
        raise WraparoundTransformError(f"invalid step_delta: {step_delta}") from e
    # Normalize to a bitvector literal consistent with the pump register element width.
    delta_mod = delta_int % (1 << elem_w)
    delta_bv = f"{delta_mod}bv{elem_w}"

    return WraparoundConfig(
        stage=stage,
        pump_target=pump_target,
        accel_targets=tuple(accel_targets),
        proj_vars=tuple(filtered),
        proj_predicates=tuple(str(p).strip() for p in (proj_predicates or ()) if str(p).strip()),
        cutpoint_cond=cond,
        step_op=step_op,
        step_delta_int=delta_int,
        step_delta_bv=delta_bv,
    )
