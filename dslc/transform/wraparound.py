from __future__ import annotations

import re
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple


class WraparoundStage(str, Enum):
    PUMP = "pump"
    ACCEL = "accel"
    ACCEL_PROBE = "accel_probe"
    CONFIRM = "confirm"
    CLOSURE_CHECK = "closure_check"
    ENTRY_CHECK = "entry_check"


@dataclass(frozen=True)
class WraparoundTarget:
    reg_var: str
    """Boogie global register array variable (e.g., `s1_sequence_reg`)."""

    elem_width: int
    """Element bitwidth (e.g., 16 for `bv16`)."""

    index_width: int
    """Index bitwidth (e.g., 32 for `[bv32]...`)."""

    index_value: Optional[int] = 0
    """Target index (v0-1 supports constant indices; v1 may leave this as None when using `index_expr_override`)."""

    index_expr_override: Optional[str] = None
    """Optional Boogie expression for the index (must have type `bv<index_width>`)."""

    use_last0_value: bool = False
    """Prefer scalar `<reg>__last0_value` over array select when available (dramatically reduces solver load)."""

    @property
    def index_expr(self) -> str:
        if self.index_expr_override is not None:
            return self.index_expr_override
        if self.index_value is None:
            raise ValueError("WraparoundTarget.index_value is None and no index_expr_override was provided")
        return f"{self.index_value}bv{self.index_width}"

    @property
    def max_elem_expr(self) -> str:
        return f"{(1 << self.elem_width) - 1}bv{self.elem_width}"

    @property
    def last0_value_var(self) -> str:
        return f"{self.reg_var}__last0_value"

    @property
    def write_proc(self) -> str:
        return f"{self.reg_var}.write"


@dataclass(frozen=True)
class WraparoundConfig:
    stage: WraparoundStage
    pump_target: WraparoundTarget
    accel_targets: Tuple[WraparoundTarget, ...]
    proj_vars: Tuple[str, ...]
    cutpoint_cond: str
    step_op: str
    step_delta_bv: str


class WraparoundTransformError(RuntimeError):
    pass


_RE_GLOBAL_VAR = re.compile(r"^var\s+(?P<name>\S+)\s*:\s*(?P<type>[^;]+);\s*$")
_RE_REG_DECL = re.compile(r"^var\s+(?P<name>\S+)\s*:\s*\[bv(?P<idx>\d+)\]\s*bv(?P<elem>\d+);\s*$")
_RE_PROC_MAIN = re.compile(r"^procedure\s+mainProcedure\(\)\s+returns\(\)\s*$")
_RE_PROC_SCHED = re.compile(r"^procedure\s+main\(\)\s+returns\(\)\s*$")
_RE_PROC_ULTIMATE_START = re.compile(r"^procedure\s+ULTIMATE\.start\(\)\s+returns\(\)\s*$")
_RE_WHILE_TRUE = re.compile(r"^\s*while\s*\(\s*true\s*\)\s*(\{\s*)?$")
_RE_WHILE_STEP_BOUND = re.compile(r"^\s*while\s*\(\s*procurator_step\s*<[^)]*\)\s*(\{\s*)?$")
_RE_ASSERT_STMT = re.compile(r"^(?P<indent>\s*)assert\b")
_RE_ASSIGN_STMT = re.compile(r"^(?P<indent>\s*)(?P<lhs>[A-Za-z0-9_.]+)\s*:=\s*")
_RE_PHASE_WRAP = re.compile(r"\bif\s*\(\s*procurator_phase\s*==\s*(?P<n>\d+)\s*\)\s*\{")
_RE_PHASE_RESET = re.compile(r"\bprocurator_phase\s*:=\s*0\s*;")
_RE_STEP_INC = re.compile(r"^\s*procurator_step\s*:=\s*procurator_step\s*\+\s*1\s*;\s*$")
_RE_CALL_MAIN = re.compile(r"^\s*call\s+main\(\)\s*;\s*$")

_PUMP_ERROR_PROC = "__wraparound_pump_error"
_PUMP_ASSERT_MARKER = "WRAPAROUND_PUMP_ASSERT"
_ENTRY_ERROR_PROC = "__wraparound_entry_error"
_ENTRY_ASSERT_MARKER = "WRAPAROUND_ENTRY_ASSERT"
_ASSERT_WRAPPER_PROC = "__wraparound_assert"
_CLOSURE_UNROLL_MARKER_PREFIX = "// UNROLLED"


def _sanitize_local(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", name)


def _parse_global_var_types(lines: Sequence[str]) -> Dict[str, str]:
    types: Dict[str, str] = {}
    for line in lines:
        m = _RE_GLOBAL_VAR.match(line.strip())
        if not m:
            continue
        types[m.group("name")] = m.group("type").strip()
    return types


def _find_reg_decl(lines: Sequence[str], reg_var: str) -> Optional[Tuple[int, int]]:
    for line in lines:
        m = _RE_REG_DECL.match(line.strip())
        if not m:
            continue
        if m.group("name") == reg_var:
            return int(m.group("idx")), int(m.group("elem"))
    return None


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


def _inline_deterministic_round_into_mainprocedure(lines: List[str], period: int) -> None:
    """
    For closure_check, replace the `call main();` unrolled scheduler steps with a
    phase-specialized, loop-free round.
    """

    phase_bodies = _extract_main_phase_bodies(lines, period)

    no_nl_lines = [ln.rstrip("\n") for ln in lines]
    _, body_open_idx, body_close_idx = _find_procedure_block(no_nl_lines, _RE_PROC_MAIN)
    marker = f"{_CLOSURE_UNROLL_MARKER_PREFIX} {period} steps (wraparound)"

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
            if len(call_idxs) == period:
                break

    if len(call_idxs) != period:
        raise WraparoundTransformError(
            f"expected {period} `call main();` occurrences after UNROLLED marker, got {len(call_idxs)}"
        )

    # Replace bottom-to-top to keep indices stable.
    for phase, idx in reversed(list(enumerate(call_idxs))):
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
    cutpoint_cond: Optional[str] = None,
    step_op: str = "add",
    step_delta: int = 1,
    stage: WraparoundStage,
) -> WraparoundConfig:
    lines = bpl_text.splitlines(keepends=False)
    var_types = _parse_global_var_types(lines)

    decl = _find_reg_decl(lines, pump_reg)
    if decl is None:
        raise WraparoundTransformError(f"register not found: {pump_reg}")
    index_w, elem_w = decl
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
        d = _find_reg_decl(lines, r)
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
        cutpoint_cond=cond,
        step_op=step_op,
        step_delta_bv=delta_bv,
    )


def _step_update_expr(cfg: WraparoundConfig, x_expr: str) -> str:
    p = cfg.pump_target
    if cfg.step_op == "add":
        return f"add.bv{p.elem_width}({x_expr}, {cfg.step_delta_bv})"
    if cfg.step_op == "sub":
        return f"sub.bv{p.elem_width}({x_expr}, {cfg.step_delta_bv})"
    raise WraparoundTransformError(f"unsupported step_op: {cfg.step_op}")


def _emit_closure_local_decls(var_types: Dict[str, str], cfg: WraparoundConfig) -> str:
    p = cfg.pump_target
    lines: List[str] = []
    lines.append("  // wraparound closure_check instrumentation (generated)\n")
    lines.append(f"  var wrap_closure_seq0: bv{p.elem_width};\n")
    for t in cfg.accel_targets:
        local = f"wrap_closure_after_{_sanitize_local(t.reg_var)}"
        lines.append(f"  var {local}: bv{t.elem_width};\n")
    for v in cfg.proj_vars:
        t = var_types.get(v)
        if not t:
            continue
        local = f"wrap_closure_snap_{_sanitize_local(v)}"
        lines.append(f"  var {local}: {t};\n")
    lines.append("\n")
    return "".join(lines)


def _emit_closure_setup(cfg: WraparoundConfig) -> str:
    p = cfg.pump_target
    lines: List[str] = []
    lines.append("  // wraparound closure_check setup (generated)\n")
    lines.append("  havoc wrap_closure_seq0;\n")
    # We want a *pre-wrap* closure/pump summary (reach `MAX`, then let confirm
    # handle the wrap-around suffix). For wrap-around counterexamples (like
    # Netchain), the "backup updates to seq+1" step is expected to fail exactly
    # at `seq==MAX`, so exclude that boundary here.
    lines.append(f"  assume wrap_closure_seq0 != {p.max_elem_expr};\n")
    # Use the register write wrapper so that any tracked scalar mirrors (`__last0_value`, etc.)
    # remain consistent with the array contents.
    for t in cfg.accel_targets:
        lines.append(f"  call {t.write_proc}({t.index_expr}, wrap_closure_seq0);\n")
    for v in cfg.proj_vars:
        local = f"wrap_closure_snap_{_sanitize_local(v)}"
        lines.append(f"  {local} := {v};\n")
    lines.append("\n")
    return "".join(lines)


def _emit_closure_asserts(cfg: WraparoundConfig) -> str:
    lines: List[str] = []
    lines.append("  // wraparound closure_check asserts (generated)\n")
    for v in cfg.proj_vars:
        local = f"wrap_closure_snap_{_sanitize_local(v)}"
        lines.append(f"  assert {v} == {local};\n")
    for t in cfg.accel_targets:
        target_read = t.last0_value_var if t.use_last0_value else f"{t.reg_var}[{t.index_expr}]"
        local = f"wrap_closure_after_{_sanitize_local(t.reg_var)}"
        lines.append(f"  {local} := {target_read};\n")
        lines.append(f"  assert {local} == {_step_update_expr(cfg, 'wrap_closure_seq0')};\n")
    # Ensure we end a full round at the intended cutpoint.
    lines.append(f"  assert ({cfg.cutpoint_cond});\n")
    lines.append("\n")
    return "".join(lines)


def _emit_local_decls(var_types: Dict[str, str], cfg: WraparoundConfig) -> str:
    p = cfg.pump_target
    lines: List[str] = []
    lines.append("  // wraparound v0-1 instrumentation (generated)\n")
    lines.append("  var wrap_snap_taken: bool;\n")
    lines.append("  var wrap_snap_step: int;\n")
    lines.append("  var wrap_loop_len: int;\n")
    lines.append("  var wrap_proj_ok: bool;\n")
    lines.append(f"  var wrap_target_old: bv{p.elem_width};\n")
    lines.append(f"  var wrap_target_new: bv{p.elem_width};\n")
    lines.append(f"  var wrap_target_snap: bv{p.elem_width};\n")
    if cfg.stage in {WraparoundStage.ACCEL, WraparoundStage.ACCEL_PROBE}:
        lines.append("  var wrap_accel_done: bool;\n")

    for v in cfg.proj_vars:
        t = var_types.get(v)
        if not t:
            continue
        local = f"wrap_snap_{_sanitize_local(v)}"
        lines.append(f"  var {local}: {t};\n")

    lines.append("\n")
    lines.append("  wrap_snap_taken := false;\n")
    lines.append("  wrap_snap_step := 0;\n")
    lines.append("  wrap_loop_len := 0;\n")
    if cfg.stage in {WraparoundStage.ACCEL, WraparoundStage.ACCEL_PROBE}:
        lines.append("  wrap_accel_done := false;\n")
    lines.append("\n")
    return "".join(lines)


def _emit_step_block(cfg: WraparoundConfig) -> str:
    p = cfg.pump_target

    proj_snap_assigns: List[str] = []
    proj_eq_checks: List[str] = []
    for v in cfg.proj_vars:
        local = f"wrap_snap_{_sanitize_local(v)}"
        proj_snap_assigns.append(f"          {local} := {v};\n")
        proj_eq_checks.append(f"        wrap_proj_ok := wrap_proj_ok && ({v} == {local});\n")

    lines: List[str] = []
    target_read = p.last0_value_var if p.use_last0_value else f"{p.reg_var}[{p.index_expr}]"
    lines.append(f"    wrap_target_old := {target_read};\n")
    lines.append("    call main();\n")
    lines.append(f"    wrap_target_new := {target_read};\n")
    lines.append(f"    if ({cfg.cutpoint_cond}) {{\n")
    lines.append("      if (!wrap_snap_taken) {\n")
    lines.append("        wrap_snap_taken := true;\n")
    lines.append("        wrap_snap_step := procurator_step;\n")
    lines.append("        wrap_target_snap := wrap_target_new;\n")
    for a in proj_snap_assigns:
        lines.append(a)
    lines.append("      }\n")

    if cfg.stage == WraparoundStage.PUMP:
        lines.append("      if (wrap_snap_taken && (procurator_step > wrap_snap_step)) {\n")
        lines.append("        wrap_proj_ok := true;\n")
        for chk in proj_eq_checks:
            lines.append(chk)
        lines.append(
            f"        if (wrap_proj_ok && (wrap_target_new == {_step_update_expr(cfg, 'wrap_target_snap')})) {{\n"
        )
        lines.append("          wrap_loop_len := procurator_step - wrap_snap_step;\n")
        lines.append(f"          call {_PUMP_ERROR_PROC}();\n")
        lines.append("        }\n")
        lines.append("      }\n")
    elif cfg.stage == WraparoundStage.ACCEL:
        lines.append("      if (!wrap_accel_done && wrap_snap_taken && (procurator_step > wrap_snap_step)) {\n")
        lines.append("        wrap_proj_ok := true;\n")
        for chk in proj_eq_checks:
            lines.append(chk)
        lines.append(
            f"        if (wrap_proj_ok && (wrap_target_new == {_step_update_expr(cfg, 'wrap_target_snap')})) {{\n"
        )
        lines.append("          wrap_accel_done := true;\n")
        for t in cfg.accel_targets:
            lines.append(f"          call {t.write_proc}({t.index_expr}, {t.max_elem_expr});\n")
        lines.append("        }\n")
        lines.append("      }\n")
    elif cfg.stage == WraparoundStage.ACCEL_PROBE:
        lines.append("      if (!wrap_accel_done && wrap_snap_taken && (procurator_step > wrap_snap_step)) {\n")
        lines.append("        wrap_proj_ok := true;\n")
        for chk in proj_eq_checks:
            lines.append(chk)
        lines.append(
            f"        if (wrap_proj_ok && (wrap_target_new == {_step_update_expr(cfg, 'wrap_target_snap')})) {{\n"
        )
        lines.append("          wrap_accel_done := true;\n")
        lines.append(f"          call {_PUMP_ERROR_PROC}();\n")
        lines.append("        }\n")
        lines.append("      }\n")
    else:
        raise AssertionError(f"unexpected stage: {cfg.stage}")

    lines.append("    }\n")
    lines.append("    procurator_step := procurator_step + 1;\n")
    return "".join(lines)


def _emit_pump_error_proc() -> str:
    return (
        f"procedure {_PUMP_ERROR_PROC}() returns()\n"
        "{\n"
        f"  assert false; // {_PUMP_ASSERT_MARKER}\n"
        "}\n\n"
    )


def _emit_entry_error_proc() -> str:
    return (
        f"procedure {_ENTRY_ERROR_PROC}() returns()\n"
        "{\n"
        f"  assert false; // {_ENTRY_ASSERT_MARKER}\n"
        "}\n\n"
    )


def _strip_other_asserts_for_pump(lines: List[str]) -> None:
    for i, line in enumerate(lines):
        if _PUMP_ASSERT_MARKER in line:
            continue
        m = _RE_ASSERT_STMT.match(line)
        if not m:
            continue
        indent = m.group("indent")
        lines[i] = f"{indent}assume true; // stripped assert for wraparound pump\n"


def _strip_debug_snapshot_for_pump(lines: List[str]) -> None:
    """
    Remove debug-only snapshot statements inserted by the DSL backend.

    These assignments do not affect the modeled P4 semantics (they only copy
    state into `__dbg*` variables for trace readability), but they significantly
    increase the control-flow and formula size and slow down pump discovery.
    """

    for i, line in enumerate(lines):
        if "Register debug snapshot" in line or "DSL assertions" in line:
            lines[i] = ""
            continue
        m = _RE_ASSIGN_STMT.match(line)
        if not m:
            continue
        lhs = m.group("lhs")
        if "__dbg" in lhs:
            lines[i] = ""


def _strip_step_increments(lines: List[str]) -> None:
    """
    Remove `procurator_step := procurator_step + 1;` statements.

    The step counter is required for pump/accel loop-length reporting, but it is
    irrelevant in loop-free closure_check proofs and adds arithmetic noise.
    """

    for i, line in enumerate(lines):
        if _RE_STEP_INC.match(line.strip()):
            lines[i] = ""


def _emit_assert_wrapper_proc() -> str:
    return (
        f"procedure {{:inline 1}} {_ASSERT_WRAPPER_PROC}(cond: bool) returns()\n"
        "{\n"
        "  assert cond;\n"
        "}\n\n"
    )


def _emit_gated_assert_wrapper_proc(cfg: WraparoundConfig) -> str:
    """
    Emit a gated assert wrapper for confirm.

    We only start checking DSL assertions once the pump target has *left* the
    MAX boundary. This prevents "UNSAFE before flip" pseudo counterexamples
    when we fast-forward the target to MAX at initialization.

    Important: the guard is evaluated at the assertion site (inside `main()`),
    so it becomes active even if the MAX->0 update occurs in the same step as
    the assertion evaluation.
    """

    p = cfg.pump_target
    target_read = p.last0_value_var if p.use_last0_value else f"{p.reg_var}[{p.index_expr}]"
    return (
        f"procedure {{:inline 1}} {_ASSERT_WRAPPER_PROC}(cond: bool) returns()\n"
        "{\n"
        f"  if ({target_read} != {p.max_elem_expr}) {{\n"
        "    assert cond;\n"
        "  } else {\n"
        "    assume true;\n"
        "  }\n"
        "}\n\n"
    )


def _rewrite_asserts_as_calls(lines: List[str]) -> None:
    """
    Replace `assert <expr>;` with `call __wraparound_assert(<expr>);`.

    This keeps semantics but collapses multiple assertion sites into a single
    assertion location inside `__wraparound_assert`, which often helps Ultimate
    (fewer error locations, fewer CEGAR targets).
    """

    for i, line in enumerate(lines):
        m = _RE_ASSERT_STMT.match(line)
        if not m:
            continue
        if _PUMP_ASSERT_MARKER in line:
            continue
        stripped = line.strip()
        if not stripped.endswith(";"):
            continue
        expr = stripped[len("assert") :].strip()
        if expr.endswith(";"):
            expr = expr[:-1].strip()
        indent = m.group("indent")
        lines[i] = f"{indent}call {_ASSERT_WRAPPER_PROC}({expr});\n"


def _emit_confirm_init(cfg: WraparoundConfig) -> str:
    lines: List[str] = []
    lines.append("  // wraparound confirm fast-forward (generated)\n")
    for t in cfg.accel_targets:
        lines.append(f"  call {t.write_proc}({t.index_expr}, {t.max_elem_expr});\n")
    lines.append("\n")
    return "".join(lines)


def _emit_init_snapshot(cfg: WraparoundConfig) -> str:
    p = cfg.pump_target
    target_read = p.last0_value_var if p.use_last0_value else f"{p.reg_var}[{p.index_expr}]"

    lines: List[str] = []
    lines.append("  // wraparound init snapshot (generated)\n")
    lines.append("  wrap_snap_taken := true;\n")
    lines.append("  wrap_snap_step := procurator_step;\n")
    lines.append(f"  wrap_target_snap := {target_read};\n")
    for v in cfg.proj_vars:
        local = f"wrap_snap_{_sanitize_local(v)}"
        lines.append(f"  {local} := {v};\n")
    lines.append("\n")
    return "".join(lines)


def instrument_bpl_text(
    *,
    bpl_text: str,
    stage: WraparoundStage,
    pump_reg: str,
    accel_regs: Sequence[str],
    index_value: int = 0,
    index_expr: Optional[str] = None,
    proj_vars: Optional[Sequence[str]] = None,
    cutpoint_cond: Optional[str] = None,
    step_op: str = "add",
    step_delta: int = 1,
) -> str:
    lines = bpl_text.splitlines(keepends=True)
    no_nl_lines = [ln.rstrip("\n") for ln in lines]
    var_types = _parse_global_var_types([ln.rstrip("\n") for ln in lines])

    if stage == WraparoundStage.ENTRY_CHECK:
        period = _infer_deterministic_scheduler_period(no_nl_lines)
        if period is None:
            raise WraparoundTransformError("entry_check requires deterministic scheduler (procurator_phase)")

        unrolled = unroll_mainprocedure_loop_text(bpl_text=bpl_text, steps=period)
        lines = unrolled.splitlines(keepends=True)
        no_nl_lines = [ln.rstrip("\n") for ln in lines]

        _strip_other_asserts_for_pump(lines)
        _strip_debug_snapshot_for_pump(lines)
        _strip_step_increments(lines)
        _inline_deterministic_round_into_mainprocedure(lines, period)

        no_nl_lines = [ln.rstrip("\n") for ln in lines]
        _, _, body_close_idx = _find_procedure_block(no_nl_lines, _RE_PROC_MAIN)
        close_indent = re.match(r"^(\s*)", lines[body_close_idx]).group(1)  # type: ignore[union-attr]
        call_indent = close_indent + "  "
        lines[body_close_idx:body_close_idx] = [f"{call_indent}call {_ENTRY_ERROR_PROC}();\n"]
        lines.append(_emit_entry_error_proc())
        return "".join(lines)

    if stage == WraparoundStage.CLOSURE_CHECK:
        period = _infer_deterministic_scheduler_period(no_nl_lines)
        if period is None:
            raise WraparoundTransformError("closure_check requires deterministic scheduler (procurator_phase)")

        unrolled = unroll_mainprocedure_loop_text(bpl_text=bpl_text, steps=period)
        lines = unrolled.splitlines(keepends=True)
        no_nl_lines = [ln.rstrip("\n") for ln in lines]
        var_types = _parse_global_var_types([ln.rstrip("\n") for ln in lines])

        # Strip pre-existing assertions/debug snapshots to keep the proof task focused.
        _strip_other_asserts_for_pump(lines)
        _strip_debug_snapshot_for_pump(lines)
        _strip_step_increments(lines)
        _inline_deterministic_round_into_mainprocedure(lines, period)
        unrolled = "".join(lines)
        no_nl_lines = [ln.rstrip("\n") for ln in lines]
        var_types = _parse_global_var_types([ln.rstrip("\n") for ln in lines])

        cfg = analyze_bpl_for_wraparound(
            bpl_text=unrolled,
            pump_reg=pump_reg,
            accel_regs=accel_regs,
            index_value=index_value,
            index_expr=index_expr,
            proj_vars=proj_vars,
            cutpoint_cond=cutpoint_cond,
            step_op=step_op,
            step_delta=step_delta,
            stage=stage,
        )

        # Locate mainProcedure block.
        proc_idx = None
        for i, ln in enumerate(no_nl_lines):
            if _RE_PROC_MAIN.match(ln.strip()):
                proc_idx = i
                break
        if proc_idx is None:
            raise WraparoundTransformError("mainProcedure not found for closure_check")

        body_open_idx = None
        for i in range(proc_idx, len(no_nl_lines)):
            if "{" in no_nl_lines[i]:
                body_open_idx = i
                break
        if body_open_idx is None:
            raise WraparoundTransformError("mainProcedure body not found for closure_check")

        # Find the corresponding closing brace of mainProcedure.
        depth = 0
        body_close_idx = None
        for i in range(body_open_idx, len(no_nl_lines)):
            for ch in no_nl_lines[i]:
                if ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        body_close_idx = i
                        break
            if body_close_idx is not None:
                break
        if body_close_idx is None:
            raise WraparoundTransformError("mainProcedure body end not found for closure_check")

        insert_locals_at = body_open_idx + 1

        # Find the unrolled-step marker (where the old while-loop was).
        marker = f"{_CLOSURE_UNROLL_MARKER_PREFIX} {period} steps (wraparound)"
        marker_idx = None
        for i in range(body_open_idx, body_close_idx + 1):
            if marker in no_nl_lines[i]:
                marker_idx = i
                break
        if marker_idx is None:
            # Fall back to any unroll marker (should not happen).
            for i in range(body_open_idx, body_close_idx + 1):
                if _CLOSURE_UNROLL_MARKER_PREFIX in no_nl_lines[i]:
                    marker_idx = i
                    break
        if marker_idx is None:
            raise WraparoundTransformError("failed to locate UNROLLED marker in mainProcedure for closure_check")

        # Perform insertions from bottom to top to keep indices stable.
        lines[body_close_idx:body_close_idx] = _emit_closure_asserts(cfg).splitlines(keepends=True)
        lines[marker_idx:marker_idx] = _emit_closure_setup(cfg).splitlines(keepends=True)
        lines[insert_locals_at:insert_locals_at] = _emit_closure_local_decls(var_types, cfg).splitlines(keepends=True)
        _rewrite_asserts_as_calls(lines)
        lines.append(_emit_assert_wrapper_proc())
        return "".join(lines)

    if stage == WraparoundStage.CONFIRM:
        cfg = analyze_bpl_for_wraparound(
            bpl_text=bpl_text,
            pump_reg=pump_reg,
            accel_regs=accel_regs,
            index_value=index_value,
            index_expr=index_expr,
            proj_vars=proj_vars,
            cutpoint_cond=cutpoint_cond,
            step_op=step_op,
            step_delta=step_delta,
            stage=stage,
        )

        confirm_block = _emit_confirm_init(cfg)

        # Try sequential harness first (mainProcedure + while(true)).
        try:
            _, body_open_idx, body_close_idx = _find_procedure_block(
                [ln.rstrip("\n") for ln in lines], _RE_PROC_MAIN
            )
            while_idx = None
            for i in range(body_open_idx + 1, body_close_idx + 1):
                if _is_mainprocedure_loop_header(lines[i]):
                    while_idx = i
                    break
            if while_idx is None:
                raise WraparoundTransformError(
                    "mainProcedure loop not found (expected while(true) or while (procurator_step < ...))"
                )
            lines.insert(while_idx, confirm_block)
            _rewrite_asserts_as_calls(lines)
            lines.append(_emit_gated_assert_wrapper_proc(cfg))
            return "".join(lines)
        except WraparoundTransformError:
            # Fall back to concurrent harness patching.
            pass

        # Concurrent harness: patch ULTIMATE.start before spawning threads.
        _, body_open_idx, body_close_idx = _find_procedure_block([ln.rstrip("\n") for ln in lines], _RE_PROC_ULTIMATE_START)

        insert_idx = None
        for i in range(body_open_idx + 1, body_close_idx + 1):
            if "// spawn threads" in lines[i]:
                insert_idx = i
                break
        if insert_idx is None:
            for i in range(body_open_idx + 1, body_close_idx + 1):
                if lines[i].lstrip().startswith("fork "):
                    insert_idx = i
                    break
        if insert_idx is None:
            raise WraparoundTransformError("failed to locate thread spawn section in ULTIMATE.start for confirm")

        lines.insert(insert_idx, confirm_block)
        _rewrite_asserts_as_calls(lines)
        lines.append(_emit_gated_assert_wrapper_proc(cfg))
        return "".join(lines)

    cfg = analyze_bpl_for_wraparound(
        bpl_text=bpl_text,
        pump_reg=pump_reg,
        accel_regs=accel_regs,
        index_value=index_value,
        index_expr=index_expr,
        proj_vars=proj_vars,
        cutpoint_cond=cutpoint_cond,
        step_op=step_op,
        step_delta=step_delta,
        stage=stage,
    )

    # Locate mainProcedure block.
    proc_idx = None
    for i, ln in enumerate(no_nl_lines):
        if _RE_PROC_MAIN.match(ln.strip()):
            proc_idx = i
            break
    if proc_idx is None:
        raise WraparoundTransformError("mainProcedure not found (expected sequential harness)")

    body_open_idx = None
    for i in range(proc_idx, len(no_nl_lines)):
        if "{" in no_nl_lines[i]:
            body_open_idx = i
            break
    if body_open_idx is None:
        raise WraparoundTransformError("mainProcedure body not found")

    # Insert local decls immediately after '{'.
    insert_locals_at = body_open_idx + 1
    locals_block = _emit_local_decls(var_types, cfg)
    lines.insert(insert_locals_at, locals_block)

    # For the default cutpoint condition, we can snapshot the initial cutpoint
    # just before entering the mainProcedure loop. This avoids searching for an
    # initial cutpoint in the pump stage.
    if (
        stage in {WraparoundStage.PUMP, WraparoundStage.ACCEL, WraparoundStage.ACCEL_PROBE}
        and cfg.cutpoint_cond.strip() == "(procurator_phase == 0)"
    ):
        while_idx = None
        for i in range(insert_locals_at, len(lines)):
            if _is_mainprocedure_loop_header(lines[i]):
                while_idx = i
                break
        if while_idx is not None:
            lines.insert(while_idx, _emit_init_snapshot(cfg))

    # Find `call main();` and `procurator_step := procurator_step + 1;` inside mainProcedure while-loop.
    call_idx = None
    step_idx = None
    for i in range(insert_locals_at, len(lines)):
        if call_idx is None and lines[i].lstrip().startswith("call main();"):
            call_idx = i
            continue
        if call_idx is not None and lines[i].lstrip().startswith("procurator_step := procurator_step + 1;"):
            step_idx = i
            break
    if call_idx is None or step_idx is None:
        raise WraparoundTransformError("failed to locate mainProcedure while-loop body (call main / step++)")

    # Replace the two-line block with the instrumented step block.
    step_block = _emit_step_block(cfg)
    lines[call_idx : step_idx + 1] = [step_block]

    if stage == WraparoundStage.PUMP:
        # The pump stage should search only for the synthetic pump witness. Strip
        # any pre-existing assertions (e.g., DSL property assertions) to avoid
        # multiple error locations and deep refinements. We keep the single
        # WRAPAROUND_PUMP_ASSERT marker as the witness target.
        lines.append(_emit_pump_error_proc())
        _strip_other_asserts_for_pump(lines)
        _strip_debug_snapshot_for_pump(lines)
    elif stage == WraparoundStage.ACCEL_PROBE:
        lines.append(_emit_pump_error_proc())
        _strip_other_asserts_for_pump(lines)
        _strip_debug_snapshot_for_pump(lines)
    elif stage == WraparoundStage.ACCEL:
        _rewrite_asserts_as_calls(lines)
        lines.append(_emit_assert_wrapper_proc())
    return "".join(lines)


def instrument_bpl_file(
    *,
    in_path: Path,
    out_path: Path,
    stage: WraparoundStage,
    pump_reg: str,
    accel_regs: Sequence[str],
    index_value: int = 0,
    index_expr: Optional[str] = None,
    proj_vars: Optional[Sequence[str]] = None,
    cutpoint_cond: Optional[str] = None,
    step_op: str = "add",
    step_delta: int = 1,
) -> None:
    text = in_path.read_text(encoding="utf-8", errors="replace")
    out = instrument_bpl_text(
        bpl_text=text,
        stage=stage,
        pump_reg=pump_reg,
        accel_regs=accel_regs,
        index_value=index_value,
        index_expr=index_expr,
        proj_vars=proj_vars,
        cutpoint_cond=cutpoint_cond,
        step_op=step_op,
        step_delta=step_delta,
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    if out_path.exists():
        old = out_path.read_text(encoding="utf-8", errors="replace")
        if old == out:
            return
    out_path.write_text(out, encoding="utf-8")


def unroll_mainprocedure_loop_text(*, bpl_text: str, steps: int) -> str:
    if steps <= 0:
        return bpl_text

    lines = bpl_text.splitlines(keepends=True)
    no_nl_lines = [ln.rstrip("\n") for ln in lines]

    proc_idx = None
    for i, ln in enumerate(no_nl_lines):
        if _RE_PROC_MAIN.match(ln.strip()):
            proc_idx = i
            break
    if proc_idx is None:
        raise WraparoundTransformError("mainProcedure not found for unroll")

    body_open_idx = None
    for i in range(proc_idx, len(no_nl_lines)):
        if "{" in no_nl_lines[i]:
            body_open_idx = i
            break
    if body_open_idx is None:
        raise WraparoundTransformError("mainProcedure body not found for unroll")

    while_idx = None
    for i in range(body_open_idx + 1, len(no_nl_lines)):
        if _is_mainprocedure_loop_header(no_nl_lines[i]):
            while_idx = i
            break
    if while_idx is None:
        raise WraparoundTransformError(
            "mainProcedure loop not found for unroll (expected while(true) or while (procurator_step < ...))"
        )

    open_idx = None
    if "{" in no_nl_lines[while_idx]:
        open_idx = while_idx
    else:
        for i in range(while_idx + 1, len(no_nl_lines)):
            if "{" in no_nl_lines[i]:
                open_idx = i
                break
    if open_idx is None:
        raise WraparoundTransformError("failed to locate loop body start for unroll")

    depth = 0
    close_idx = None
    for i in range(open_idx, len(no_nl_lines)):
        for ch in no_nl_lines[i]:
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    close_idx = i
                    break
        if close_idx is not None:
            break
    if close_idx is None:
        raise WraparoundTransformError("failed to locate loop body end for unroll")

    body = lines[open_idx + 1 : close_idx]
    indent = re.match(r"^(\s*)", lines[while_idx]).group(1)  # type: ignore[union-attr]
    replacement: List[str] = [f"{indent}// UNROLLED {steps} steps (wraparound)\n"]
    replacement.extend(body * steps)

    lines[while_idx : close_idx + 1] = replacement
    return "".join(lines)


def unroll_mainprocedure_loop_file(*, in_path: Path, out_path: Path, steps: int) -> None:
    text = in_path.read_text(encoding="utf-8", errors="replace")
    out = unroll_mainprocedure_loop_text(bpl_text=text, steps=steps)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    if out_path.exists():
        old = out_path.read_text(encoding="utf-8", errors="replace")
        if old == out:
            return
    out_path.write_text(out, encoding="utf-8")
