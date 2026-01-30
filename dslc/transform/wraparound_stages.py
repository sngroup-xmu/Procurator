from __future__ import annotations

import re
from typing import Dict, List, Optional, Sequence

from .wraparound_common import (
    WraparoundConfig,
    WraparoundStage,
    WraparoundTarget,
    WraparoundTransformError,
    _ASSERT_WRAPPER_PROC,
    _CLOSURE_UNROLL_MARKER_PREFIX,
    _ENTRY_ASSERT_MARKER,
    _ENTRY_ERROR_PROC,
    _MAX_FORALL_INIT_EXPANSION,
    _PUMP_ASSERT_MARKER,
    _PUMP_ERROR_PROC,
    _RE_ASSERT_STMT,
    _RE_ASSIGN_STMT,
    _RE_ASSUME_BV32_INDEX_INIT,
    _RE_ASSUME_FORALL_BV32_INIT,
    _RE_BVULE_BV32_CALL,
    _RE_STEP_INC,
    _sanitize_local,
)

def _emit_inline_reg_write(var_types: Dict[str, str], t: WraparoundTarget, *, value_expr: str) -> str:
    """
    Inline a `call <reg>.write(<idx>, <value>);` to avoid Ultimate issues with
    procedure-parameter variables in some proof tasks (notably closure_check).

    We also keep our register write-tracking mirrors consistent when present
    (`__last_index/__last_value/__wrote_any/__wrote_index0/__last0_value`).
    """

    idx = t.index_expr
    reg = t.reg_var
    lines: List[str] = []

    lines.append(f"  {reg}[{idx}] := {value_expr};\n\n")

    # These mirrors are inserted by `dslc/backends/boogie_registers.py`.
    last_index = f"{reg}__last_index"
    last_value = f"{reg}__last_value"
    wrote_any = f"{reg}__wrote_any"
    wrote_index0 = f"{reg}__wrote_index0"
    last0_value = f"{reg}__last0_value"

    if last_index in var_types:
        lines.append(f"  {last_index} := {idx};\n\n")
    if last_value in var_types:
        lines.append(f"  {last_value} := {value_expr};\n\n")
    if wrote_any in var_types:
        lines.append(f"  {wrote_any} := true;\n\n")

    if (wrote_index0 in var_types) or (last0_value in var_types):
        # Mirror the `.write` procedure body: only update index0 mirrors when idx==0.
        lines.append(f"  if ({idx} == 0bv{t.index_width}) {{\n\n")
        if wrote_index0 in var_types:
            lines.append(f"    {wrote_index0} := true;\n\n")
        if last0_value in var_types:
            lines.append(f"    {last0_value} := {value_expr};\n\n")
        lines.append("  }\n")

    return "".join(lines)

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


def _emit_closure_setup(var_types: Dict[str, str], cfg: WraparoundConfig) -> str:
    p = cfg.pump_target
    lines: List[str] = []
    lines.append("  // wraparound closure_check setup (generated)\n")
    lines.append("  havoc wrap_closure_seq0;\n")
    # We want a *pre-wrap* closure/pump summary (reach `MAX`, then let confirm
    # handle the wrap-around suffix). For wrap-around counterexamples (like
    # Netchain), the "backup updates to seq+1" step is expected to fail exactly
    # at `seq==MAX`, so exclude that boundary here.
    lines.append(f"  assume wrap_closure_seq0 != {p.max_elem_expr};\n")
    # Avoid `call <reg>.write(...)` here: Ultimate may introduce auxiliary
    # procedure-parameter variables like `<reg>.write_<param>` that can crash
    # some proof tasks (FloydHoare permissible-variable check).
    for t in cfg.accel_targets:
        lines.append(_emit_inline_reg_write(var_types, t, value_expr="wrap_closure_seq0"))
    # Many specs use `dsl_pump_mode` to separate a pumping prefix from a functional suffix
    # (e.g., DistCache wraparound bugs). For closure_check we always want the pumping shape.
    if var_types.get("dsl_pump_mode") == "bool":
        lines.append("  dsl_pump_mode := true;\n")
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
    # `procurator_phase` is updated inside `main()` (scheduler), so we must snapshot it
    # before calling `main()` if we want cutpoints like `(procurator_phase == 0)` to
    # refer to the *current* step (not the next one).
    lines.append("  var wrap_phase_before: int;\n")
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
        # For PUMP/ACCEL we compare projection variables at the cutpoint *before* calling `main()`,
        # because the selected action can mutate these variables (e.g., host_send bumps inbox_count).
        if v != "procurator_phase":
            pre = f"wrap_pre_{_sanitize_local(v)}"
            lines.append(f"  var {pre}: {t};\n")

    lines.append("\n")
    lines.append("  wrap_snap_taken := false;\n")
    lines.append("  wrap_snap_step := 0;\n")
    lines.append("  wrap_loop_len := 0;\n")
    if cfg.stage in {WraparoundStage.ACCEL, WraparoundStage.ACCEL_PROBE}:
        lines.append("  wrap_accel_done := false;\n")
    lines.append("\n")
    return "".join(lines)


def _emit_step_block(var_types: Dict[str, str], cfg: WraparoundConfig) -> str:
    p = cfg.pump_target

    proj_snap_assigns: List[str] = []
    proj_eq_checks: List[str] = []
    for v in cfg.proj_vars:
        local = f"wrap_snap_{_sanitize_local(v)}"
        # We compare/snapshot projection vars at the *beginning* of the step, before calling `main()`.
        # Special-case `procurator_phase` (already captured as wrap_phase_before). For other vars, we
        # capture their pre-values into `wrap_pre_*` locals.
        pre_expr = "wrap_phase_before" if v == "procurator_phase" else f"wrap_pre_{_sanitize_local(v)}"
        proj_snap_assigns.append(f"          {local} := {pre_expr};\n")
        proj_eq_checks.append(f"        wrap_proj_ok := wrap_proj_ok && ({pre_expr} == {local});\n")

    lines: List[str] = []
    target_read = p.last0_value_var if p.use_last0_value else f"{p.reg_var}[{p.index_expr}]"
    lines.append("    wrap_phase_before := procurator_phase;\n")
    lines.append(f"    wrap_target_old := {target_read};\n")
    for v in cfg.proj_vars:
        if v == "procurator_phase":
            continue
        if v not in var_types:
            continue
        pre = f"wrap_pre_{_sanitize_local(v)}"
        lines.append(f"    {pre} := {v};\n")
    lines.append("    call main();\n")
    lines.append(f"    wrap_target_new := {target_read};\n")
    # Evaluate cutpoints in terms of the phase at the beginning of the step.
    cut_cond = cfg.cutpoint_cond
    cut_cond = re.sub(r"\bprocurator_phase\b", "wrap_phase_before", cut_cond)
    lines.append(f"    if ({cut_cond}) {{\n")
    lines.append("      if (!wrap_snap_taken) {\n")
    lines.append("        wrap_snap_taken := true;\n")
    lines.append("        wrap_snap_step := procurator_step;\n")
    # Snapshot the target and projection at the cutpoint *before* executing the step.
    lines.append("        wrap_target_snap := wrap_target_old;\n")
    for a in proj_snap_assigns:
        lines.append(a)
    lines.append("      }\n")

    if cfg.stage == WraparoundStage.PUMP:
        lines.append("      if (wrap_snap_taken && (procurator_step > wrap_snap_step)) {\n")
        lines.append("        wrap_proj_ok := true;\n")
        for chk in proj_eq_checks:
            lines.append(chk)
        lines.append(
            f"        if (wrap_proj_ok && (wrap_target_old == {_step_update_expr(cfg, 'wrap_target_snap')})) {{\n"
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
            f"        if (wrap_proj_ok && (wrap_target_old == {_step_update_expr(cfg, 'wrap_target_snap')})) {{\n"
        )
        lines.append("          wrap_accel_done := true;\n")
        for t in cfg.accel_targets:
            lines.append(_emit_inline_reg_write(var_types, t, value_expr=t.max_elem_expr))
        lines.append("        }\n")
        lines.append("      }\n")
    elif cfg.stage == WraparoundStage.ACCEL_PROBE:
        lines.append("      if (!wrap_accel_done && wrap_snap_taken && (procurator_step > wrap_snap_step)) {\n")
        lines.append("        wrap_proj_ok := true;\n")
        for chk in proj_eq_checks:
            lines.append(chk)
        lines.append(
            f"        if (wrap_proj_ok && (wrap_target_old == {_step_update_expr(cfg, 'wrap_target_snap')})) {{\n"
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


def _normalize_boogie_expr(expr: str) -> str:
    return re.sub(r"\s+", "", expr)


def _infer_reg_bv32_index_upper_bound(lines: Sequence[str], reg_var: str) -> Optional[int]:
    write_pat = re.compile(rf"\bcall\s+{re.escape(reg_var)}\.write\(\s*(?P<idx>[^,]+?)\s*,")
    read_pat = re.compile(rf"\b{re.escape(reg_var)}\.read\(\s*{re.escape(reg_var)}\s*,\s*(?P<idx>[^)]+?)\s*\)")

    idx_exprs: set[str] = set()
    for ln in lines:
        m = write_pat.search(ln)
        if m:
            idx_exprs.add(m.group("idx").strip())
        for m in read_pat.finditer(ln):
            idx_exprs.add(m.group("idx").strip())

    if not idx_exprs:
        return None

    expr_to_bound: Dict[str, int] = {}
    for ln in lines:
        for m in _RE_BVULE_BV32_CALL.finditer(ln):
            a_norm = _normalize_boogie_expr(m.group("a"))
            b = int(m.group("b"))
            prev = expr_to_bound.get(a_norm)
            if prev is None or b > prev:
                expr_to_bound[a_norm] = b

    bounds: List[int] = []
    for idx in idx_exprs:
        b = expr_to_bound.get(_normalize_boogie_expr(idx))
        if b is not None:
            bounds.append(b)
    return max(bounds) if bounds else None


def _rewrite_forall_bv32_array_inits(lines: List[str]) -> None:
    """
    Replace quantified `[bv32]` array initializations with finite instantiations.

    Some backends emit register initialization as:
      assume (forall i:bv32 :: reg[i] == 0bvW);
    These quantifiers can make the entry/closure checks in wraparound time out
    or return UNKNOWN. For wraparound stages we only need initial values for the
    indices that can be accessed, which are typically bounded to a small range
    by prior slicing/register-index analysis.
    """

    explicit: Dict[Tuple[str, str], set[int]] = {}
    for ln in lines:
        m = _RE_ASSUME_BV32_INDEX_INIT.match(ln.strip())
        if not m:
            continue
        key = (m.group("array"), _normalize_boogie_expr(m.group("value")))
        explicit.setdefault(key, set()).add(int(m.group("idx")))

    i = 0
    while i < len(lines):
        m = _RE_ASSUME_FORALL_BV32_INIT.match(lines[i].strip())
        if not m:
            i += 1
            continue

        indent = m.group("indent")
        reg = m.group("array")
        value = m.group("value").strip()
        value_norm = _normalize_boogie_expr(value)
        key = (reg, value_norm)

        inferred_bound = _infer_reg_bv32_index_upper_bound(lines, reg)
        inferred_indices: set[int] = set()
        if inferred_bound is not None:
            if inferred_bound >= _MAX_FORALL_INIT_EXPANSION:
                raise WraparoundTransformError(
                    f"cannot eliminate quantified init for {reg}: inferred index upper bound {inferred_bound} "
                    f">= {_MAX_FORALL_INIT_EXPANSION} (increase pruning or lower the bound)"
                )
            inferred_indices = set(range(inferred_bound + 1))

        already = explicit.get(key, set())
        if inferred_bound is None and not already:
            # We cannot infer a finite index domain and there is no existing
            # finite instantiation to rely on. Keep the quantified init to
            # preserve semantics (even if this makes the check harder).
            i += 1
            continue

        missing = sorted(inferred_indices - already)

        if not missing:
            # Either (1) we already have per-index init assumptions for all
            # indices that can be accessed, or (2) we inferred an empty/covered
            # domain. In either case, the quantified init is unnecessary for
            # wraparound stages and can be dropped to avoid solver UNKNOWN/timeouts.
            del lines[i]
            continue

        repl: List[str] = [f"{indent}assume {reg}[{k}bv32] == {value};\n" for k in missing]
        lines[i : i + 1] = repl
        explicit[key] = already.union(inferred_indices)
        i += len(repl)


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


def _emit_confirm_init(var_types: Dict[str, str], cfg: WraparoundConfig) -> str:
    lines: List[str] = []
    lines.append("  // wraparound confirm fast-forward (generated)\n")
    for t in cfg.accel_targets:
        # Avoid `call <reg>.write(...)` for the same reasons as closure_check.
        # In confirm we want the target(s) to start at MAX before exploring the suffix.
        lines.append(_emit_inline_reg_write(var_types, t, value_expr=t.max_elem_expr))
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
