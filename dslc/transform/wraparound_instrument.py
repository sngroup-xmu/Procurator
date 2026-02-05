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
    _RE_CALL_MAIN,
    _RE_PROC_MAIN,
    _RE_PROC_SCHED,
    _RE_PROC_ULTIMATE_START,
)
from .wraparound_stages import (
    _emit_assert_wrapper_proc,
    _emit_closure_asserts,
    _emit_closure_assert_wrapper_procs,
    _emit_closure_local_decls,
    _emit_closure_setup,
    _emit_confirm_init,
    _emit_entry_error_proc,
    _emit_init_snapshot,
    _emit_local_decls,
    _emit_pump_error_proc,
    _emit_step_block,
    _emit_gated_assert_wrapper_proc,
    _rewrite_forall_bv32_array_inits,
    _rewrite_asserts_as_calls,
    _strip_debug_snapshot_for_pump,
    _strip_other_asserts_for_pump,
    _strip_step_increments,
)
from .wraparound_unroll import unroll_mainprocedure_loop_text


def _find_two_phase_pump_mode_var(var_types: dict[str, str]) -> Optional[str]:
    """
    Find the DSL boolean that drives a two-phase env script for wraparound confirm.

    Historically, DSL globals are emitted as `dsl_<name>` and then may be prefixed
    again by the multi-node Boogie prefixer, resulting in names like
    `dsl_dsl_pump_mode`. We therefore match by suffix to make this robust.
    """

    if var_types.get("dsl_pump_mode") == "bool":
        return "dsl_pump_mode"
    if var_types.get("dsl_dsl_pump_mode") == "bool":
        return "dsl_dsl_pump_mode"

    hits = [n for n, t in var_types.items() if t == "bool" and n.endswith("dsl_pump_mode")]
    if len(hits) == 1:
        return hits[0]
    return None


def _drive_two_phase_pump_mode_in_mainprocedure(
    lines: list[str],
    *,
    pump_mode_var: str,
    target_read: str,
    max_expr: str,
) -> None:
    """
    Drive a two-phase host env script (dsl_pump_mode) for harnesses that do not
    have a `procedure main()` scheduler.

    Some sequential harness encodings inline a deterministic schedule into
    `mainProcedure()` (e.g., `global.deterministic_scheduler=true`). In those
    cases, the file contains host injection blocks like:
      if (dsl_pump_mode) { ... } else { ... }
    but there is no `procedure main()` and no `procurator_phase`.

    We need to update `dsl_pump_mode` right before each host injection decides
    the packet type, otherwise CONFIRM will never switch to the functional
    suffix after wraparound.
    """

    try:
        _, proc_open, proc_close = _find_procedure_block([ln.rstrip("\n") for ln in lines], _RE_PROC_MAIN)
    except WraparoundTransformError:
        return

    pat = re.compile(r"\bif\s*\(\s*" + re.escape(pump_mode_var) + r"\s*\)\s*\{")
    assign_stmt = f"{pump_mode_var} := ({target_read} == {max_expr});"

    for i in range(proc_close - 1, proc_open, -1):
        if not pat.search(lines[i]):
            continue
        indent = re.match(r"^(\s*)", lines[i]).group(1)  # type: ignore[union-attr]
        prev = lines[i - 1].strip() if i - 1 >= 0 else ""
        if prev == assign_stmt:
            continue
        lines.insert(i, f"{indent}{assign_stmt}\n")


def _emit_extra_assumes(extra_assumes: Sequence[str], *, indent: str) -> list[str]:
    out: list[str] = []
    for a in extra_assumes:
        s = str(a).strip()
        if not s:
            continue
        # Accept either raw expressions or pre-wrapped `assume(...)` lines.
        if s.startswith("assume(") or s.startswith("assume "):
            if not s.endswith(";"):
                s += ";"
            out.append(f"{indent}{s}\n")
        else:
            if s.endswith(";"):
                s = s[:-1].strip()
            out.append(f"{indent}assume({s});\n")
    return out


def _reassert_simple_equalities_after_havoc(
    lines: list[str],
    *,
    extra_assumes: Sequence[str],
) -> None:
    """
    Re-assert `x == c` constraints after any `havoc x;` statement.

    Motivation:
      - In no-slicing builds, harness code may `havoc` many host/meta variables
        (e.g., `io_meta.leafswitchidx`) before applying DSL constraints.
      - Wraparound CEGIS often pins such variables to stabilize the pumped index.
      - A plain `assume(x == c)` at the top of mainProcedure is *not* enough
        because `havoc x;` later in the trace destroys the constraint.

    This helper is conservative and only re-injects very simple equalities of
    the form `lhs == rhs` where `lhs` is a single Boogie variable or a field
    access like `io_meta.leafswitchidx`.
    """

    # Extract "lhs == rhs" from extra_assumes (accept both raw exprs and assume(...) wrappers).
    eq_exprs: dict[str, str] = {}
    for a in extra_assumes:
        s = str(a).strip()
        if not s:
            continue
        if s.startswith("assume(") and s.endswith(")"):
            s = s[len("assume(") : -1].strip()
        if s.startswith("assume "):
            s = s[len("assume ") :].strip()
        if s.endswith(";"):
            s = s[:-1].strip()

        # Many callers pass `(... == ...)` style strings (e.g., from DSL/env completion).
        # Strip a single layer of wrapping parentheses so the simple `lhs == rhs` regex works.
        while s.startswith("(") and s.endswith(")"):
            depth = 0
            wraps_entire = True
            for i, ch in enumerate(s):
                if ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
                    # If we close the outermost paren before the end, outer parens do not
                    # wrap the entire string (e.g., `(a==b) && (c==d)`), so stop stripping.
                    if depth == 0 and i != len(s) - 1:
                        wraps_entire = False
                        break
            if wraps_entire and depth == 0:
                s = s[1:-1].strip()
                continue
            break

        # Only handle a single top-level equality.
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*)\s*==\s*(.+)$", s)
        if not m:
            continue
        lhs = m.group(1).strip()
        rhs = m.group(2).strip()
        eq_exprs[lhs] = f"{lhs} == {rhs}"

    if not eq_exprs:
        return

    i = 0
    while i < len(lines):
        ln = lines[i]
        m = re.match(r"^(\s*)havoc\s+([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*);\s*$", ln)
        if m:
            indent = m.group(1)
            var = m.group(2)
            expr = eq_exprs.get(var)
            if expr:
                # Insert immediately after the havoc so the constraint holds for subsequent statements.
                lines.insert(i + 1, f"{indent}assume({expr});\n")
                i += 1
        i += 1


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
    extra_assumes: Optional[Sequence[str]] = None,
    closure_unroll_steps: Optional[int] = None,
) -> str:
    lines = bpl_text.splitlines(keepends=True)
    no_nl_lines = [ln.rstrip("\n") for ln in lines]
    var_types = _parse_global_var_types([ln.rstrip("\n") for ln in lines])

    if stage == WraparoundStage.ENTRY_CHECK:
        # ENTRY_CHECK is a *satisfiability* gate: it should be UNSAFE iff the
        # spec/environment constraints admit at least one execution from the
        # initial state.
        #
        # Important: Do NOT unroll/inline the scheduler here. Doing so makes
        # the entry task unnecessarily large and brittle (and can time out on
        # no-slicing builds). By placing the failing assertion immediately at
        # the beginning of mainProcedure, we turn ENTRY_CHECK into a cheap SAT
        # query: if initial constraints are consistent, the error is reachable.
        #
        # Closure/confirm still require deterministic scheduling; ENTRY_CHECK
        # intentionally does not.
        _strip_other_asserts_for_pump(lines)
        _strip_debug_snapshot_for_pump(lines)
        # Locate mainProcedure opening brace and inject extra assumes + entry error call.
        _, mp_open, _mp_close = _find_procedure_block([ln.rstrip("\n") for ln in lines], _RE_PROC_MAIN)
        insert_at = mp_open + 1
        indent = re.match(r"^(\s*)", lines[insert_at]).group(1) if insert_at < len(lines) else "  "  # type: ignore[union-attr]
        if extra_assumes:
            lines[insert_at:insert_at] = _emit_extra_assumes(extra_assumes, indent=indent)
            insert_at += len(extra_assumes)
            _reassert_simple_equalities_after_havoc(lines, extra_assumes=extra_assumes)

        lines[insert_at:insert_at] = [f"{indent}call {_ENTRY_ERROR_PROC}();\n"]
        # Performance: eliminate heavy quantified register initializations when safe.
        #
        # ENTRY_CHECK is a satisfiability gate; keeping large quantified inits can make
        # it unnecessarily slow (especially for DistCache-style large registers).
        _rewrite_forall_bv32_array_inits(lines)
        lines.append(_emit_entry_error_proc())
        return "".join(lines)

    if stage == WraparoundStage.CLOSURE_CHECK:
        period = _infer_deterministic_scheduler_period(no_nl_lines)
        if period is None:
            raise WraparoundTransformError("closure_check requires deterministic scheduler (procurator_phase)")

        # closure_check should summarize *one* deterministic scheduler round by default.
        # A caller may override this to experiment with different unroll lengths, but
        # we do NOT auto-scale the expected delta here (CEGIS should decide what delta
        # it is trying to validate).
        steps = period if closure_unroll_steps is None else max(period, int(closure_unroll_steps))

        unrolled = unroll_mainprocedure_loop_text(bpl_text=bpl_text, steps=steps)
        lines = unrolled.splitlines(keepends=True)
        no_nl_lines = [ln.rstrip("\n") for ln in lines]
        var_types = _parse_global_var_types([ln.rstrip("\n") for ln in lines])

        # Strip pre-existing assertions/debug snapshots to keep the proof task focused.
        _strip_other_asserts_for_pump(lines)
        _strip_debug_snapshot_for_pump(lines)
        _strip_step_increments(lines)
        _inline_deterministic_round_into_mainprocedure(lines, period=period, steps=steps)
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
        marker = f"{_CLOSURE_UNROLL_MARKER_PREFIX} {steps} steps (wraparound)"
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

        local_decl_lines = _emit_closure_local_decls(var_types, cfg).splitlines(keepends=True)
        lines[insert_locals_at:insert_locals_at] = local_decl_lines
        if extra_assumes:
            # Constrain closure to the synthesized existence profile (conditional certificate).
            indent = re.match(r"^(\s*)", local_decl_lines[0]).group(1) if local_decl_lines else "  "  # type: ignore[union-attr]
            insert_at = insert_locals_at + len(local_decl_lines)
            lines[insert_at:insert_at] = _emit_extra_assumes(extra_assumes, indent=indent)
            _reassert_simple_equalities_after_havoc(lines, extra_assumes=extra_assumes)
        # Performance: eliminate heavy quantified register initializations when safe.
        _rewrite_forall_bv32_array_inits(lines)
        _rewrite_asserts_as_calls(lines)
        lines.append(_emit_assert_wrapper_proc())
        lines.append(_emit_closure_assert_wrapper_procs(cfg))
        return "".join(lines)

    if stage == WraparoundStage.ENABLE_CHECK:
        """
        ENABLE_CHECK is a *satisfiability* query used by wraparound CEGIS:

          - We fast-forward the target register(s) to MAX (same as CONFIRM).
          - We then try to find an execution where the target *leaves* MAX within the
            given step bound (i.e., the increment/decrement path is enabled under some
            input sequence).

        We encode this by injecting a call to the gated assert wrapper with condition
        `target == MAX`. Since the wrapper only checks assertions when `target != MAX`,
        this becomes UNSAFE iff we can reach a state where `target != MAX`.

        This stage does NOT check the user's functional property; it is only used to
        synthesize a witness-driven environment profile that enables the pump update.
        """

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

        enable_init = _emit_confirm_init(var_types, cfg)
        target_read = (
            cfg.pump_target.last0_value_var
            if cfg.pump_target.use_last0_value
            else f"{cfg.pump_target.reg_var}[{cfg.pump_target.index_expr}]"
        )

        # Keep the task focused: strip property/debug assertions before injecting our own goal.
        _strip_other_asserts_for_pump(lines)
        _strip_debug_snapshot_for_pump(lines)

        # Only supported for sequential harnesses (mainProcedure loop).
        _, body_open_idx, body_close_idx = _find_procedure_block([ln.rstrip("\n") for ln in lines], _RE_PROC_MAIN)
        while_idx = None
        for i in range(body_open_idx + 1, body_close_idx + 1):
            if _is_mainprocedure_loop_header(lines[i]):
                while_idx = i
                break
        if while_idx is None:
            raise WraparoundTransformError(
                "mainProcedure loop not found (expected while(true) or while (procurator_step < ...))"
            )

        # ENABLE_CHECK is a *satisfiability* query: we want to know whether the
        # accelerated counter can ever leave MAX within the given unroll bound.
        #
        # For bug-finding performance, encode this with a single error location
        # and a final-state filter:
        #
        #   assume target != MAX;
        #   assert false;
        #
        # This is UNSAFE iff there exists a bounded execution that makes the
        # target register differ from MAX at the end of the unrolled prefix.
        #
        # IMPORTANT (correctness): insert the goal before injecting `enable_init`
        # / extra assumes, so we do not rely on indices that can shift.
        indent_proc = re.match(r"^(\s*)", lines[body_open_idx]).group(1)  # type: ignore[union-attr]
        final_goal = "".join(
            [
                f"{indent_proc}  assume ({target_read} != {cfg.pump_target.max_elem_expr});\n",
                f"{indent_proc}  assert false;\n",
            ]
        )
        lines.insert(body_close_idx, final_goal)
        body_close_idx += 1

        if extra_assumes:
            indent = re.match(r"^(\s*)", lines[while_idx]).group(1) if while_idx < len(lines) else "  "  # type: ignore[union-attr]
            assume_lines = _emit_extra_assumes(extra_assumes, indent=indent)
            lines[while_idx:while_idx] = assume_lines
            while_idx += len(assume_lines)
            _reassert_simple_equalities_after_havoc(lines, extra_assumes=extra_assumes)

        # Fast-forward to MAX before executing any steps.
        lines.insert(while_idx, enable_init)

        # If the spec uses two-phase injection, keep injecting the pump packet while target==MAX.
        pump_mode_var = _find_two_phase_pump_mode_var(var_types)
        if pump_mode_var:
            _, sched_open, sched_close = _find_procedure_block([ln.rstrip("\n") for ln in lines], _RE_PROC_SCHED)
            if_open = None
            for i in range(sched_open + 1, sched_close + 1):
                compact = re.sub(r"\s+", "", lines[i])
                if compact.startswith("if(procurator_phase==0") or "if(procurator_phase==0)" in compact:
                    if_open = i
                    break
            if if_open is not None:
                brace_idx = None
                if "{" in lines[if_open]:
                    brace_idx = if_open
                else:
                    for j in range(if_open + 1, sched_close + 1):
                        if "{" in lines[j]:
                            brace_idx = j
                            break
                if brace_idx is not None:
                    indent = re.match(r"^(\s*)", lines[brace_idx]).group(1)  # type: ignore[union-attr]
                    max_expr = cfg.pump_target.max_elem_expr
                    lines.insert(brace_idx + 1, f"{indent}  {pump_mode_var} := ({target_read} == {max_expr});\n")
        # Performance: eliminate heavy quantified register initializations when safe.
        _rewrite_forall_bv32_array_inits(lines)
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
        target_read = (
            cfg.pump_target.last0_value_var
            if cfg.pump_target.use_last0_value
            else f"{cfg.pump_target.reg_var}[{cfg.pump_target.index_expr}]"
        )

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
            # Inject existence constraints before the confirm stage so they apply to the
            # whole loop execution.
            if extra_assumes:
                indent = re.match(r"^(\s*)", lines[while_idx]).group(1) if while_idx < len(lines) else "  "  # type: ignore[union-attr]
                assume_lines = _emit_extra_assumes(extra_assumes, indent=indent)
                lines[while_idx:while_idx] = assume_lines
                while_idx += len(assume_lines)
                _reassert_simple_equalities_after_havoc(lines, extra_assumes=extra_assumes)

            lines.insert(while_idx, confirm_block)

            # If the spec uses a two-phase env script (`dsl_pump_mode`), drive it from the
            # current value of the pumped register:
            #   - while reg==MAX, keep injecting the +1 update packet (to trigger MAX->0);
            #   - once reg!=MAX, switch to the functional suffix packets (e.g., P2C query).
            pump_mode_var = _find_two_phase_pump_mode_var(var_types)
            if pump_mode_var:
                # IMPORTANT: The scheduler's `main()` often advances through multiple phases
                # (host inject, switch step, bookkeeping, ...). We only want to switch the
                # injected packet type on the *injection* phase, not on every scheduler call.
                #
                # We therefore set `dsl_pump_mode` inside `main()` for phase 0. This makes
                # the confirm stage robust under both bounded-loop and unrolled-loop encodings.
                _, sched_open, sched_close = _find_procedure_block([ln.rstrip("\n") for ln in lines], _RE_PROC_SCHED)
                if_open = None
                for i in range(sched_open + 1, sched_close + 1):
                    compact = re.sub(r"\s+", "", lines[i])
                    if compact.startswith("if(procurator_phase==0") or "if(procurator_phase==0)" in compact:
                        if_open = i
                        break
                # Heuristic fallback: if we can't find the phase-0 branch, do nothing.
                if if_open is not None:
                    brace_idx = None
                    if "{" in lines[if_open]:
                        brace_idx = if_open
                    else:
                        for j in range(if_open + 1, sched_close + 1):
                            if "{" in lines[j]:
                                brace_idx = j
                                break
                    if brace_idx is not None:
                        indent = re.match(r"^(\s*)", lines[brace_idx]).group(1)  # type: ignore[union-attr]
                        max_expr = cfg.pump_target.max_elem_expr
                        lines.insert(brace_idx + 1, f"{indent}  {pump_mode_var} := ({target_read} == {max_expr});\n")

            # Performance: eliminate heavy quantified register initializations when safe.
            _rewrite_forall_bv32_array_inits(lines)
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
            # Some sequential harnesses still use `ULTIMATE.start()` but do not spawn
            # threads (e.g., deterministic scheduler inlined into mainProcedure).
            # In that case, inject confirm right after '{' so it runs before the
            # harness executes.
            insert_idx = body_open_idx + 1

        if extra_assumes:
            indent = re.match(r"^(\s*)", lines[insert_idx]).group(1) if insert_idx < len(lines) else "  "  # type: ignore[union-attr]
            assume_lines = _emit_extra_assumes(extra_assumes, indent=indent)
            lines[insert_idx:insert_idx] = assume_lines
            insert_idx += len(assume_lines)
            _reassert_simple_equalities_after_havoc(lines, extra_assumes=extra_assumes)

        lines.insert(insert_idx, confirm_block)

        # Two-phase env script (`dsl_pump_mode`) support for deterministic-scheduler
        # harnesses that inline everything into mainProcedure (no `procedure main()`).
        pump_mode_var = _find_two_phase_pump_mode_var(var_types)
        if pump_mode_var:
            _drive_two_phase_pump_mode_in_mainprocedure(
                lines,
                pump_mode_var=pump_mode_var,
                target_read=target_read,
                max_expr=cfg.pump_target.max_elem_expr,
            )

        # Performance: eliminate heavy quantified register initializations when safe.
        _rewrite_forall_bv32_array_inits(lines)
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
