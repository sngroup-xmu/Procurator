from __future__ import annotations

import re
from pathlib import Path
from typing import Optional, Sequence

from .wraparound_analyze import (
    WraparoundConfig,
    WraparoundStage,
    WraparoundTransformError,
    _find_procedure_block,
    _infer_deterministic_scheduler_period,
    _inline_deterministic_round_into_mainprocedure,
    _is_mainprocedure_loop_header,
    _parse_global_var_types,
    analyze_bpl_for_wraparound,
)
from .wraparound_common import (
    _CLOSURE_UNROLL_MARKER_PREFIX,
    _ENTRY_ERROR_PROC,
    _RE_PROC_MAIN,
    _RE_PROC_ULTIMATE_START,
)
from .wraparound_stages import (
    _emit_assert_wrapper_proc,
    _emit_closure_asserts,
    _emit_closure_local_decls,
    _emit_closure_setup,
    _emit_confirm_init,
    _emit_entry_error_proc,
    _emit_init_snapshot,
    _emit_local_decls,
    _emit_pump_error_proc,
    _emit_step_block,
    _emit_gated_assert_wrapper_proc,
    _rewrite_asserts_as_calls,
    _rewrite_forall_bv32_array_inits,
    _strip_debug_snapshot_for_pump,
    _strip_other_asserts_for_pump,
    _strip_step_increments,
)
from .wraparound_unroll import unroll_mainprocedure_loop_text

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
        _rewrite_forall_bv32_array_inits(lines)

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
        _rewrite_forall_bv32_array_inits(lines)
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
        lines[marker_idx:marker_idx] = _emit_closure_setup(var_types, cfg).splitlines(keepends=True)
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

        confirm_block = _emit_confirm_init(var_types, cfg)

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
    step_block = _emit_step_block(var_types, cfg)
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

