from __future__ import annotations

import re
from typing import Dict, List, Optional, Sequence, Tuple

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
    _RE_ASSUME_FORALL_BV32_INIT_EXCEPT,
    _RE_BVULE_BV32_CALL,
    _RE_STEP_INC,
    _closure_index_alias_name,
    _sanitize_local,
)


def _target_index_expr(target: WraparoundTarget, *, closure_alias: bool = False) -> str:
    if closure_alias:
        return _closure_index_alias_name(target) or target.index_expr
    return target.index_expr


def _closure_index_alias_targets(cfg: WraparoundConfig) -> List[Tuple[str, WraparoundTarget]]:
    out: List[Tuple[str, WraparoundTarget]] = []
    seen: set[str] = set()
    for target in cfg.accel_targets:
        alias = _closure_index_alias_name(target)
        if not alias or alias in seen:
            continue
        seen.add(alias)
        out.append((alias, target))
    return out


def _with_closure_index_aliases(expr: str, cfg: WraparoundConfig) -> str:
    out = str(expr)
    for alias, target in _closure_index_alias_targets(cfg):
        out = out.replace(target.index_expr, alias)
    return out


def _normalized_cutpoint_term(expr: str) -> str:
    text = str(expr or "").strip()
    while text.startswith("(") and text.endswith(")"):
        depth = 0
        wraps = True
        for idx, ch in enumerate(text):
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0 and idx != len(text) - 1:
                    wraps = False
                    break
        if not wraps or depth != 0:
            break
        text = text[1:-1].strip()
    return re.sub(r"\s+", "", text)


def _split_top_level_conjuncts(expr: str) -> List[str]:
    parts: List[str] = []
    cur: List[str] = []
    depth = 0
    i = 0
    text = str(expr or "").strip()
    while i < len(text):
        ch = text[i]
        if ch == "(":
            depth += 1
            cur.append(ch)
            i += 1
            continue
        if ch == ")":
            depth = max(0, depth - 1)
            cur.append(ch)
            i += 1
            continue
        if depth == 0 and text.startswith("&&", i):
            part = "".join(cur).strip()
            if part:
                parts.append(part)
            cur = []
            i += 2
            continue
        cur.append(ch)
        i += 1
    part = "".join(cur).strip()
    if part:
        parts.append(part)
    return parts or ([text] if text else [])


def _closure_cutpoint_terms(cfg: WraparoundConfig) -> List[str]:
    """
    Return the residual final cutpoint obligations not already covered by
    projection-predicate stability.

    Closure setup assumes the cutpoint and snapshots each projection predicate.
    If a top-level cutpoint conjunct is exactly one of those predicates, final
    equality to the snapshot already implies that conjunct.  Keeping both copies
    only makes SMT interpolation heavier.
    """

    predicate_terms = {
        _normalized_cutpoint_term(_with_closure_index_aliases(pred, cfg)) for pred in cfg.proj_predicates
    }
    out: List[str] = []
    for raw in _split_top_level_conjuncts(_with_closure_index_aliases(cfg.cutpoint_cond, cfg)):
        if _normalized_cutpoint_term(raw) in predicate_terms:
            continue
        out.append(raw)
    return out


def _emit_inline_reg_write(
    var_types: Dict[str, str],
    t: WraparoundTarget,
    *,
    value_expr: str,
    closure_alias: bool = False,
) -> str:
    """
    Inline a `call <reg>.write(<idx>, <value>);` to avoid Ultimate issues with
    procedure-parameter variables in some proof tasks (notably closure_check).

    We also keep our register write-tracking mirrors consistent when present
    (`__last_index/__last_value/__wrote_any/__wrote_index0/__last0_value`).
    """

    idx = _target_index_expr(t, closure_alias=closure_alias)
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


def _emit_target_slot_assumes(
    var_types: Dict[str, str],
    cfg: WraparoundConfig,
    *,
    zero_init_regs: Sequence[str],
) -> str:
    """
    Materialize point facts for dynamic wraparound indices.

    System harnesses initialize registers with quantified defaults.  For dynamic
    indices like `hash(constants...)`, the existential near-wrap stage can spend
    most of its time rediscovering that the non-target registers are zero at the
    same slot.  These assumptions are redundant with the initialization, so they
    do not change the set of executions; they only give the solver local facts at
    the slot we are about to fast-forward.
    """

    target_by_reg = {t.reg_var for t in cfg.accel_targets}
    idx = _target_index_expr(cfg.pump_target)
    lines: List[str] = []
    for name in sorted(set(zero_init_regs)):
        if name in target_by_reg:
            continue
        typ = var_types.get(name)
        if not typ:
            continue
        m = re.match(r"^\s*\[\s*bv(?P<idx_w>\d+)\s*\]\s*bv(?P<elem_w>\d+)\s*$", typ)
        if not m:
            continue
        if int(m.group("idx_w")) != cfg.pump_target.index_width:
            continue
        lines.append(f"  assume {name}[{idx}] == 0bv{m.group('elem_w')};\n")
    if not lines:
        return ""
    return "  // wraparound dynamic-index slot defaults (generated)\n" + "".join(lines) + "\n"


def _step_update_expr(cfg: WraparoundConfig, x_expr: str) -> str:
    p = cfg.pump_target
    if cfg.step_op == "add":
        return f"add.bv{p.elem_width}({x_expr}, {cfg.step_delta_bv})"
    if cfg.step_op == "sub":
        return f"sub.bv{p.elem_width}({x_expr}, {cfg.step_delta_bv})"
    raise WraparoundTransformError(f"unsupported step_op: {cfg.step_op}")


def _near_wrap_value_expr(cfg: WraparoundConfig, target: WraparoundTarget) -> str:
    """
    Return a concrete boundary value that crosses the wrap point in one step.

    For +1 this is MAX, matching the original implementation.  For larger
    additive deltas, the one-step predecessor of 0 is `2^w - delta`; for
    subtractive deltas, the one-step predecessor of MAX is `delta - 1`.
    """

    modulus = 1 << target.elem_width
    try:
        delta_mod = int(cfg.step_delta_int) % modulus
    except Exception as e:
        raise WraparoundTransformError(f"invalid step_delta: {cfg.step_delta_int}") from e
    if delta_mod == 0:
        raise WraparoundTransformError(
            f"unsupported wraparound step_delta={cfg.step_delta_int} for bv{target.elem_width}"
        )
    if cfg.step_op == "add":
        near = (modulus - delta_mod) % modulus
    elif cfg.step_op == "sub":
        near = (delta_mod - 1) % modulus
    else:
        raise WraparoundTransformError(f"unsupported step_op: {cfg.step_op}")
    return f"{near}bv{target.elem_width}"


def _ensure_bvule_helper_decl(lines: List[str], width: int) -> None:
    """
    Closure no-wrap obligations may need unsigned <= at the register element
    width.  The system harness historically emitted bvule helpers only for a
    small fixed set (notably bv16/bv32), while TNA/FissLock counters can be bv8.
    """

    fn = f"bvule.bv{width}"
    decl_re = re.compile(rf"^\s*function\s+(?:\{{[^}}]*\}}\s+)?{re.escape(fn)}\(")
    if any(decl_re.match(ln) for ln in lines):
        return

    helper = [
        f"function {fn}(left:bv{width}, right:bv{width}) returns(bool);\n",
        f"function {{:builtin \"bvule\"}} {fn}$builtin(left:bv{width}, right:bv{width}) returns(bool);\n",
        f"axiom (forall left:bv{width}, right:bv{width} :: {fn}(left, right) <==> {fn}$builtin(left, right));\n",
    ]

    insert_at = 0
    while insert_at < len(lines) and not lines[insert_at].strip():
        insert_at += 1
    lines[insert_at:insert_at] = helper


def _emit_closure_local_decls(var_types: Dict[str, str], cfg: WraparoundConfig) -> str:
    p = cfg.pump_target
    lines: List[str] = []
    lines.append("  // wraparound closure_check instrumentation (generated)\n")
    for alias, target in _closure_index_alias_targets(cfg):
        lines.append(f"  var {alias}: bv{target.index_width};\n")
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
    for i, _pred in enumerate(cfg.proj_predicates):
        lines.append(f"  var wrap_closure_pred_{i}: bool;\n")
    for i, expr in enumerate(cfg.proj_exprs):
        typ = _infer_projection_expr_type(expr, var_types)
        if not typ:
            continue
        lines.append(f"  var wrap_closure_expr_{i}: {typ};\n")
    lines.append("\n")
    return "".join(lines)


def _emit_closure_setup(var_types: Dict[str, str], cfg: WraparoundConfig) -> str:
    p = cfg.pump_target
    lines: List[str] = []
    lines.append("  // wraparound closure_check setup (generated)\n")
    for alias, target in _closure_index_alias_targets(cfg):
        lines.append(f"  {alias} := {target.index_expr};\n")
    lines.append("  havoc wrap_closure_seq0;\n")
    d = int(cfg.step_delta_int)
    modulus = 1 << p.elem_width
    if d == 0 or abs(d) >= modulus:
        raise WraparoundTransformError(f"unsupported wraparound step_delta={d} for bv{p.elem_width}")
    # Precise NoWrap_d obligation for the mathematical signed delta.  The old
    # `seq0 != MAX` shortcut is sound only for +1; schedule certificates need
    # the stronger condition for larger positive steps and negative steps.
    if d > 0:
        upper = modulus - 1 - d
        lines.append(f"  assume bvule.bv{p.elem_width}(wrap_closure_seq0, {upper}bv{p.elem_width});\n")
    else:
        lower = -d
        lines.append(f"  assume bvule.bv{p.elem_width}({lower}bv{p.elem_width}, wrap_closure_seq0);\n")
    # Avoid `call <reg>.write(...)` here: Ultimate may introduce auxiliary
    # procedure-parameter variables like `<reg>.write_<param>` that can crash
    # some proof tasks (FloydHoare permissible-variable check).
    for t in cfg.accel_targets:
        lines.append(_emit_inline_reg_write(var_types, t, value_expr="wrap_closure_seq0", closure_alias=True))
    # Many specs use `dsl_pump_mode` to separate a pumping prefix from a functional suffix
    # (e.g., DistCache wraparound bugs). For closure_check we always want the pumping shape.
    if var_types.get("dsl_pump_mode") == "bool":
        lines.append("  dsl_pump_mode := true;\n")
    lines.append(f"  assume({_with_closure_index_aliases(cfg.cutpoint_cond, cfg)});\n")
    for v in cfg.proj_vars:
        local = f"wrap_closure_snap_{_sanitize_local(v)}"
        lines.append(f"  {local} := {v};\n")
    for i, pred in enumerate(cfg.proj_predicates):
        lines.append(f"  wrap_closure_pred_{i} := ({_with_closure_index_aliases(pred, cfg)});\n")
    for i, expr in enumerate(cfg.proj_exprs):
        if not _infer_projection_expr_type(expr, var_types):
            continue
        lines.append(f"  wrap_closure_expr_{i} := {_with_closure_index_aliases(expr, cfg)};\n")
    lines.append("\n")
    return "".join(lines)


def _closure_target_read_and_guards(
    var_types: Dict[str, str],
    target: WraparoundTarget,
) -> Tuple[str, List[str]]:
    if target.use_last0_value:
        return target.last0_value_var, []

    reg = target.reg_var
    last_index = f"{reg}__last_index"
    last_value = f"{reg}__last_value"
    wrote_any = f"{reg}__wrote_any"
    if (
        var_types.get(last_index) == f"bv{target.index_width}"
        and var_types.get(last_value) == f"bv{target.elem_width}"
        and var_types.get(wrote_any) == "bool"
    ):
        idx = _target_index_expr(target, closure_alias=True)
        return last_value, [f"({wrote_any})", f"({last_index} == {idx})"]

    return f"{reg}[{_target_index_expr(target, closure_alias=True)}]", []


def _emit_closure_asserts(var_types: Dict[str, str], cfg: WraparoundConfig) -> str:
    lines: List[str] = []
    lines.append("  // wraparound closure_check asserts (generated)\n")
    # Emit a *single* named assertion target for closure_check.
    #
    # Rationale: emitting one wrapper per condition creates many error locations
    # which can cause Ultimate/GemCutter to spend most time in CEGAR choosing
    # and refining among locations (observed to timeout on NetChain closure).
    #
    # If we later want pinpointing again, we can re-introduce it as an optional
    # "debug" mode, but the default should be "one error location".
    cond_terms: List[str] = []
    for v in cfg.proj_vars:
        local = f"wrap_closure_snap_{_sanitize_local(v)}"
        cond_terms.append(f"({v} == {local})")
    for i, pred in enumerate(cfg.proj_predicates):
        cond_terms.append(f"(({_with_closure_index_aliases(pred, cfg)}) == wrap_closure_pred_{i})")
    for i, expr in enumerate(cfg.proj_exprs):
        cond_terms.append(f"({_with_closure_index_aliases(expr, cfg)} == wrap_closure_expr_{i})")
    for t in cfg.accel_targets:
        target_read, target_guards = _closure_target_read_and_guards(var_types, t)
        local = f"wrap_closure_after_{_sanitize_local(t.reg_var)}"
        lines.append(f"  {local} := {target_read};\n")
        cond_terms.extend(target_guards)
        cond_terms.append(f"({local} == {_step_update_expr(cfg, 'wrap_closure_seq0')})")
    # Ensure we end a full round at the intended cutpoint.  Terms already
    # covered by projection-predicate equality are omitted here.
    for term in _closure_cutpoint_terms(cfg):
        cond_terms.append(f"({term})")
    cond_expr = "true" if not cond_terms else " && ".join(cond_terms)
    lines.append(f"  call __wraparound_closure_assert_all({cond_expr});\n")
    lines.append("\n")
    return "".join(lines)


def _infer_projection_expr_type(expr: str, var_types: Dict[str, str]) -> Optional[str]:
    m = re.match(r"^\s*(?P<array>[A-Za-z_][A-Za-z0-9_.]*)\s*\[.+\]\s*$", expr or "")
    if not m:
        return None
    typ = var_types.get(m.group("array"))
    if not typ:
        return None
    mt = re.match(r"^\s*\[\s*bv\d+\s*\]\s*(?P<elem>.+?)\s*$", typ)
    if not mt:
        return None
    elem = mt.group("elem").strip()
    return elem or None


def _emit_closure_assert_wrapper_procs(cfg: WraparoundConfig) -> str:
    lines: List[str] = []
    lines.append(
        "procedure {:inline 1} __wraparound_closure_assert_all(cond: bool) returns()\n"
        "{\n"
        "  assert cond;\n"
        "}\n\n"
    )
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
    target_read = p.last0_value_var if p.use_last0_value else f"{p.reg_var}[{_target_index_expr(p)}]"
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


def _infer_reg_bv32_index_upper_bound(
    lines: Sequence[str],
    reg_var: str,
    index_width: int = 32,
    *,
    use_assume_bounds: bool = False,
) -> Optional[int]:
    write_pat = re.compile(rf"\bcall\s+{re.escape(reg_var)}\.write\(\s*(?P<idx>[^,]+?)\s*,")
    read_pat = re.compile(rf"\b{re.escape(reg_var)}\.read\(\s*{re.escape(reg_var)}\s*,\s*(?P<idx>[^)]+?)\s*\)")
    array_access_pat = re.compile(rf"\b{re.escape(reg_var)}\[\s*(?P<idx>[^\]]+?)\s*\]")

    read_callee = f"{reg_var}.read"
    write_callee = f"{reg_var}.write"
    reg_externs = (read_callee, write_callee)

    def _declared_proc_or_function_name(raw: str) -> Optional[str]:
        stripped = raw.strip()
        m = re.match(
            r"^(?:procedure|function)(?:\s+\{:[^}]*\})*\s*(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\s*\(",
            stripped,
        )
        if not m:
            return None
        return m.group("name")

    def _starts_reg_extern_body(raw: str) -> bool:
        return _declared_proc_or_function_name(raw) in reg_externs

    def _body_brace_delta(raw: str) -> Tuple[int, bool]:
        without_attrs = re.sub(r"\{:[^}]*\}", "", raw)
        return without_attrs.count("{") - without_attrs.count("}"), ("{" in without_attrs)

    idx_exprs: set[str] = set()
    skipping_unused_body = False
    skip_depth = 0
    skip_seen_open = False
    for ln in lines:
        stripped = ln.strip()
        if skipping_unused_body:
            delta, has_open = _body_brace_delta(ln)
            skip_depth += delta
            skip_seen_open = skip_seen_open or has_open
            if skip_seen_open and skip_depth <= 0:
                skipping_unused_body = False
                skip_seen_open = False
            continue
        if _starts_reg_extern_body(ln):
            skipping_unused_body = True
            skip_depth, skip_seen_open = _body_brace_delta(ln)
            if skip_seen_open and skip_depth <= 0:
                skipping_unused_body = False
                skip_seen_open = False
            continue
        if _RE_ASSUME_FORALL_BV32_INIT.match(stripped) or _RE_ASSUME_FORALL_BV32_INIT_EXCEPT.match(stripped):
            continue
        m = write_pat.search(ln)
        if m:
            idx_exprs.add(m.group("idx").strip())
        for m in read_pat.finditer(ln):
            idx_exprs.add(m.group("idx").strip())
        for m in array_access_pat.finditer(ln):
            idx_exprs.add(m.group("idx").strip())

    if not idx_exprs:
        return None

    # Optionally collect candidate index upper bounds from *assumptions*.
    #
    # Correctness note: this is disabled by default because a textual `assume`
    # may be path-local or procedure-local and not dominate every register
    # access. Existential stages (direct, ENTRY, CONFIRM, focused) must not use
    # such bounds, or quantified-init elimination could introduce spurious
    # UNSAFE witnesses. CLOSURE_CHECK may opt in because dropping initialization
    # facts over-approximates the closure state and SAFE remains conservative.

    def _strip_wrapping_parens(expr: str) -> str:
        s = expr.strip()
        while s.startswith("(") and s.endswith(")"):
            depth = 0
            wraps_entire = True
            for i, ch in enumerate(s):
                if ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
                    if depth == 0 and i != len(s) - 1:
                        wraps_entire = False
                        break
            if wraps_entire and depth == 0:
                s = s[1:-1].strip()
                continue
            break
        return s

    def _parse_bv_lit(expr: str) -> Optional[Tuple[int, int]]:
        m = re.match(r"^(?P<n>\d+)bv(?P<w>\d+)$", expr.strip())
        if not m:
            return None
        try:
            return int(m.group("n")), int(m.group("w"))
        except Exception:
            return None

    # Maps bitvector width -> normalized expression -> numeric upper bound.
    bounds_by_width: Dict[int, Dict[str, int]] = {}

    def _add_bound(width: int, expr: str, bound: int) -> None:
        dst = bounds_by_width.setdefault(int(width), {})
        key = _normalize_boogie_expr(expr)
        prev = dst.get(key)
        if prev is None or bound > prev:
            dst[key] = int(bound)

    bule_pat = re.compile(
        r"\b(?:bvule|bule)\.bv(?P<width>\d+)(?:\$builtin)?\(\s*(?P<a>[^,]+?)\s*,\s*"
        r"(?P<b>\d+)bv(?P<lit_w>\d+)\s*\)"
    )

    if use_assume_bounds:
        for ln in lines:
            s = ln.strip()
            if not s.startswith("assume"):
                continue
            # Normalize to the inside of the assume.
            s = s[len("assume") :].strip()
            if s.endswith(";"):
                s = s[:-1].strip()
            s = _strip_wrapping_parens(s)
            if not s or s.startswith("forall"):
                continue
            # Skip non-conjunctive assume forms (implications/disjunctions).
            compact = _normalize_boogie_expr(s)
            if ("||" in compact) or ("==>" in compact) or ("<==" in compact):
                continue

            for m in bule_pat.finditer(s):
                if int(m.group("lit_w")) != int(m.group("width")):
                    continue
                _add_bound(int(m.group("width")), m.group("a"), int(m.group("b")))

            # Simple equality `assume(lhs == <n>bvW);` is also a usable upper bound.
            if ("&&" not in compact) and (compact.count("==") == 1):
                lhs, rhs = compact.split("==", 1)
                rhs_lit = _parse_bv_lit(rhs)
                if rhs_lit is not None:
                    n, w = rhs_lit
                    lhs_norm = _normalize_boogie_expr(_strip_wrapping_parens(lhs))
                    _add_bound(w, lhs_norm, n)

    def _infer_bound_from_expr(expr: str) -> Optional[int]:
        e0 = _strip_wrapping_parens(expr)
        lit = _parse_bv_lit(e0)
        if lit is not None and lit[1] == int(index_width):
            return lit[0]

        e = _normalize_boogie_expr(e0)
        direct = bounds_by_width.get(int(index_width), {}).get(e)
        if direct is not None:
            return int(direct)

        # Common P4B pattern: bv32 index is a concat of a zero high half with a bv16 index.
        #
        # Example: `0bv16++leaf_hdr_eg.inswitch_hdr.idx`
        m = re.match(r"^(?P<hi>\d+)bv(?P<hi_w>\d+)\+\+(?P<lo>.+)$", e)
        if m:
            try:
                hi = int(m.group("hi"))
            except Exception:
                hi = 0
            hi_w = int(m.group("hi_w"))
            if hi_w >= int(index_width):
                return None
            lo_w = int(index_width) - hi_w
            lo = _strip_wrapping_parens(m.group("lo"))
            lo_norm = _normalize_boogie_expr(lo)
            lo_lit = _parse_bv_lit(lo_norm)
            if lo_lit is not None and lo_lit[1] == lo_w:
                lo_bound = lo_lit[0]
            else:
                lo_bound = bounds_by_width.get(lo_w, {}).get(lo_norm)
            if lo_bound is not None:
                return (hi << lo_w) + int(lo_bound)

        return None

    bounds: List[int] = []
    for idx in idx_exprs:
        b = _infer_bound_from_expr(idx)
        if b is None:
            return None
        bounds.append(int(b))
    return max(bounds) if bounds else None


def _rewrite_forall_bv32_array_inits(lines: List[str], *, use_assume_bounds: bool = False) -> None:
    """
    Replace quantified `[bvN]` array initializations with finite instantiations.

    Some backends emit register initialization as:
      assume (forall i:bvN :: reg[i] == 0bvW);
    These quantifiers can make the entry/closure checks in wraparound time out
    or return UNKNOWN. For wraparound stages we only need initial values for the
    indices that can be accessed, which are typically bounded to a small range
    by prior slicing/register-index analysis.
    """

    explicit: Dict[Tuple[str, int, str], set[int]] = {}
    for ln in lines:
        m = _RE_ASSUME_BV32_INDEX_INIT.match(ln.strip())
        if not m:
            continue
        key = (m.group("array"), int(m.group("idx_w")), _normalize_boogie_expr(m.group("value")))
        explicit.setdefault(key, set()).add(int(m.group("idx")))

    i = 0
    while i < len(lines):
        m = _RE_ASSUME_FORALL_BV32_INIT.match(lines[i].strip())
        exc_idx: Optional[int] = None
        if not m:
            m2 = _RE_ASSUME_FORALL_BV32_INIT_EXCEPT.match(lines[i].strip())
            if not m2:
                i += 1
                continue
            # Same capture names as unconditional regex, plus `exc`.
            m = m2
            try:
                if int(m2.group("exc_w")) != int(m2.group("idx_w")):
                    i += 1
                    continue
                exc_idx = int(m2.group("exc"))
            except Exception:
                exc_idx = None

        indent = m.group("indent")
        reg = m.group("array")
        idx_w = int(m.group("idx_w"))
        value = m.group("value").strip()
        value_norm = _normalize_boogie_expr(value)
        key = (reg, idx_w, value_norm)

        inferred_bound = _infer_reg_bv32_index_upper_bound(lines, reg, idx_w, use_assume_bounds=use_assume_bounds)
        inferred_indices: set[int] = set()
        if inferred_bound is not None and inferred_bound < _MAX_FORALL_INIT_EXPANSION:
            inferred_indices = set(range(inferred_bound + 1))

        already = explicit.get(key, set())
        if inferred_bound is None:
            # We cannot infer a finite index domain. Keep the quantified init
            # to preserve semantics (even if this makes the check harder).
            #
            # Soundness note: do NOT drop the quantifier just because some explicit
            # `reg[0] == 0` instantiation exists. That would relax the initial state
            # for potentially-accessed indices and can introduce spurious behaviors.
            i += 1
            continue
        if inferred_bound >= _MAX_FORALL_INIT_EXPANSION:
            # Too large to expand safely; keep the quantifier.
            i += 1
            continue

        missing_set = inferred_indices - already
        if exc_idx is not None:
            missing_set.discard(int(exc_idx))
        missing = sorted(missing_set)

        if not missing:
            # Either (1) we already have per-index init assumptions for all
            # indices that can be accessed, or (2) we inferred an empty/covered
            # domain. In either case, the quantified init is unnecessary for
            # wraparound stages and can be dropped to avoid solver UNKNOWN/timeouts.
            del lines[i]
            continue

        repl: List[str] = [f"{indent}assume {reg}[{k}bv{idx_w}] == {value};\n" for k in missing]
        lines[i : i + 1] = repl
        # Track that all in-domain indices (except the excluded one, if present) now
        # have explicit init assumptions.
        if exc_idx is not None:
            explicit[key] = already.union(inferred_indices - {int(exc_idx)})
        else:
            explicit[key] = already.union(inferred_indices)
        i += len(repl)


def _collect_zero_initialized_register_arrays(lines: Sequence[str]) -> List[str]:
    """
    Collect arrays with an explicit quantified zero initialization.

    Confirm/near-wrap uses this only to add redundant point facts at a dynamic
    target index.  Collecting from existing init assumptions keeps the
    existential stage from strengthening the model by accident.
    """

    init_re = re.compile(
        r"^\s*assume\s*\(\s*forall\s+[A-Za-z_][A-Za-z0-9_]*\s*:\s*bv\d+\s*::\s*"
        r"(?P<array>[A-Za-z_][A-Za-z0-9_]*)\s*\[\s*[A-Za-z_][A-Za-z0-9_]*\s*\]\s*==\s*0bv\d+\s*\)\s*;\s*$"
    )
    out: List[str] = []
    for line in lines:
        m = init_re.match(line.strip())
        if m:
            out.append(m.group("array"))
    return out


def _drop_remaining_forall_array_inits_for_closure(lines: List[str]) -> None:
    """
    Drop residual quantified array initializations in CLOSURE_CHECK only.

    This deliberately over-approximates the closure initial state.  Therefore a
    SAFE closure result remains sound for the original program, while
    UNSAFE/UNKNOWN merely falls back and is not certified.  Do not use this for
    existential stages such as ENTRY/CONFIRM, where over-approximating the
    initial state could create a spurious witness.
    """

    init_re = re.compile(
        r"^\s*assume\s*\(\s*forall\s+[A-Za-z_][A-Za-z0-9_]*\s*:\s*[A-Za-z_][A-Za-z0-9_]*\s*::\s*"
        r"(?:\(+\s*[A-Za-z_][A-Za-z0-9_]*\s*!=\s*\d+bv\d+\s*\)+\s*==>\s*)?"
        r"[A-Za-z_][A-Za-z0-9_]*\[\s*[A-Za-z_][A-Za-z0-9_]*\s*\]\s*==\s*[^)]+?\)\s*;\s*$"
    )
    for i, line in enumerate(lines):
        if init_re.match(line.strip()):
            lines[i] = ""


def _emit_assert_wrapper_proc() -> str:
    return (
        f"procedure {{:inline 1}} {_ASSERT_WRAPPER_PROC}(cond: bool) returns()\n"
        "{\n"
        "  assert cond;\n"
        "}\n\n"
    )


def _emit_gated_assert_wrapper_proc(
    var_types: Dict[str, str],
    cfg: WraparoundConfig,
    *,
    active_var: Optional[str] = None,
) -> str:
    """
    Emit a gated assert wrapper for confirm.

    We only start checking DSL assertions once the pump target has *left* the
    MAX boundary. This prevents "UNSAFE before flip" pseudo counterexamples
    when we fast-forward the target to MAX at initialization.

    Important: the guard is evaluated at the assertion site (inside `main()`),
    so it becomes active even if the MAX->0 update occurs in the same step as
    the assertion evaluation.
    """

    # The gating must cover *all accelerated registers*, not only the pump target.
    #
    # Otherwise, when we fast-forward multiple regs to the near-wrap boundary
    # (MAX for +1, a lower predecessor for larger deltas; e.g., NetChain
    # sequence regs across replicas), the property could become UNSAFE already
    # at that boundary (pre-flip) due to the interaction between the regs
    # (e.g., s2 > s1).
    #
    # In that case, the reported counterexample is a "pseudo" wraparound bug:
    # it is not showing a flip-induced violation, just a violation in the
    # fast-forwarded initial state. We want confirm to validate the *flip
    # suffix*, so we only enable assertions after at least one accelerated
    # register has left its near-wrap boundary.
    accel_reads: List[str] = []
    for t in cfg.accel_targets:
        r = t.last0_value_var if t.use_last0_value else f"{t.reg_var}[{_target_index_expr(t)}]"
        accel_reads.append(r)
    if not accel_reads:
        accel_reads = [
            cfg.pump_target.last0_value_var
            if cfg.pump_target.use_last0_value
            else f"{cfg.pump_target.reg_var}[{_target_index_expr(cfg.pump_target)}]"
        ]
    # Per-reg max constants (width may differ across targets in general).
    gate_terms: List[str] = []
    for t in cfg.accel_targets:
        r = t.last0_value_var if t.use_last0_value else f"{t.reg_var}[{_target_index_expr(t)}]"
        near = _near_wrap_value_expr(cfg, t)
        term = f"({r} != {near})"
        if (
            not t.use_last0_value
            and f"{t.reg_var}__wrote_any" in var_types
            and f"{t.reg_var}__last_index" in var_types
            and f"{t.reg_var}__last_value" in var_types
        ):
            term = (
                f"({term} || "
                f"({t.reg_var}__wrote_any && {t.reg_var}__last_index == {_target_index_expr(t)} "
                f"&& {t.reg_var}__last_value != {near}))"
            )
        gate_terms.append(term)
    if not gate_terms:
        p = cfg.pump_target
        r = p.last0_value_var if p.use_last0_value else f"{p.reg_var}[{_target_index_expr(p)}]"
        near = _near_wrap_value_expr(cfg, p)
        term = f"({r} != {near})"
        if (
            not p.use_last0_value
            and f"{p.reg_var}__wrote_any" in var_types
            and f"{p.reg_var}__last_index" in var_types
            and f"{p.reg_var}__last_value" in var_types
        ):
            term = (
                f"({term} || "
                f"({p.reg_var}__wrote_any && {p.reg_var}__last_index == {_target_index_expr(p)} "
                f"&& {p.reg_var}__last_value != {near}))"
            )
        gate_terms.append(term)
    gate_cond = " || ".join(gate_terms)
    if active_var:
        gate_cond = f"({active_var} && ({gate_cond}))"
    return (
        f"procedure {{:inline 1}} {_ASSERT_WRAPPER_PROC}(cond: bool) returns()\n"
        "{\n"
        f"  if ({gate_cond}) {{\n"
        "    assert cond;\n"
        "  } else {\n"
        "    assume true;\n"
        "  }\n"
        "}\n\n"
    )


def _looks_like_p4b_fail_fast_assert_cut(lines: List[str], assert_idx: int, assert_expr: str) -> bool:
    if assert_expr.strip() != "false":
        return False

    prev_idx = assert_idx - 1
    while prev_idx >= 0 and not lines[prev_idx].strip():
        prev_idx -= 1
    if prev_idx < 0:
        return False

    prev = lines[prev_idx].strip()
    if prev == "{":
        prev_idx -= 1
        while prev_idx >= 0 and not lines[prev_idx].strip():
            prev_idx -= 1
        if prev_idx < 0:
            return False
        prev = lines[prev_idx].strip()

    m = re.match(r"^if\s*\((?P<cond>.*)\)\s*\{?\s*$", prev)
    if not m:
        return False

    cond = m.group("cond")
    any_mode = "__wrote_any" in cond and "__last_value" in cond
    slot0_mode = "__wrote_index0" in cond and "__last0_value" in cond
    return any_mode or slot0_mode


def _rewrite_asserts_as_calls(lines: List[str]) -> None:
    """
    Replace `assert <expr>;` with `call __wraparound_assert(<expr>);`.

    This keeps semantics but collapses multiple assertion sites into a single
    assertion location inside `__wraparound_assert`, which often helps Ultimate
    (fewer error locations, fewer CEGAR targets).

    Do not cut the path after a rewritten DSL/global assertion.  Some
    wraparound bugs require a pump pass followed by a later functional suffix
    pass; inserting `assume false` after the first assertion can make NEAR_WRAP
    incorrectly prove SAFE by deleting that suffix.
    """

    rewritten_asserts: List[Tuple[int, str]] = []
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
        rewritten_asserts.append((i, expr))

    # P4B fail-fast register assertions are encoded as:
    #
    #   if (bad) {
    #     assert false;
    #     assume false;
    #   }
    #
    # After we rewrite the assert into the gated confirm/near-wrap wrapper, the
    # assertion may be intentionally disabled until the accelerated register has
    # left the near-wrap boundary.  Keeping the following `assume false` would
    # then delete the real suffix path and can make NEAR_WRAP incorrectly prove
    # SAFE.  The assume is only an error-after cut; once the assertion is routed
    # through the wrapper, the safety result does not rely on that cut.
    for i, expr in rewritten_asserts:
        if not _looks_like_p4b_fail_fast_assert_cut(lines, i, expr):
            continue
        j = i + 1
        while j < len(lines) and not lines[j].strip():
            j += 1
        if j < len(lines) and lines[j].strip() == "assume false;":
            indent = re.match(r"^(\s*)", lines[j]).group(1)  # type: ignore[union-attr]
            lines[j] = f"{indent}assume true; // removed after wraparound-gated assert\n"


def _emit_confirm_init(
    var_types: Dict[str, str],
    cfg: WraparoundConfig,
    *,
    zero_init_regs: Sequence[str] = (),
) -> str:
    lines: List[str] = []
    lines.append("  // wraparound confirm fast-forward (generated)\n")
    for t in cfg.accel_targets:
        # Avoid `call <reg>.write(...)` for the same reasons as closure_check.
        # In confirm we want each target to start at a one-step wrap boundary
        # before exploring the suffix.  For add-by-1 this is MAX; for larger
        # deltas it is the predecessor that crosses 0 in one update.
        lines.append(_emit_inline_reg_write(var_types, t, value_expr=_near_wrap_value_expr(cfg, t)))
    lines.append(_emit_target_slot_assumes(var_types, cfg, zero_init_regs=zero_init_regs))
    lines.append("\n")
    return "".join(lines)


def _emit_init_snapshot(cfg: WraparoundConfig) -> str:
    p = cfg.pump_target
    target_read = p.last0_value_var if p.use_last0_value else f"{p.reg_var}[{_target_index_expr(p)}]"

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
