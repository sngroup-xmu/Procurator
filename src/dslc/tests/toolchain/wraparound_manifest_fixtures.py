from __future__ import annotations

from pathlib import Path


def _stage_bpl_text(stage: str, base_text: str) -> str:
    if stage == "entry":
        return base_text + "\ncall __wraparound_entry_error();\nassert false; // WRAPAROUND_ENTRY_ASSERT\n"
    if stage == "near":
        return (
            base_text
            + "\n// wraparound confirm fast-forward (generated)\n"
            + "// UNROLLED 2 steps (wraparound)\n"
            + "call __wraparound_assert(false);\n"
            + "procedure {:inline 1} __wraparound_assert(cond: bool) returns() { assert cond; }\n"
        )
    if stage == "closure":
        return (
            base_text
            + "\n// wraparound closure_check setup (generated)\n"
            + "// wraparound closure_check asserts (generated)\n"
            + "call __wraparound_closure_assert_all(true);\n"
            + "procedure __wraparound_closure_assert_all(cond: bool) returns() { assert cond; }\n"
        )
    raise AssertionError(stage)


def _closure_binding_text(
    *,
    proj_vars: tuple[str, ...] = (),
    proj_predicates: tuple[str, ...] = (),
    proj_exprs: tuple[str, ...] = (),
    proj_predicate_count: int = 0,
) -> str:
    lines = []
    for var in proj_vars:
        lines.append(f"var wrap_closure_snap_{var}: int;")
        lines.append(f"wrap_closure_snap_{var} := {var};")
        lines.append(f"call __wraparound_closure_assert_all(({var} == wrap_closure_snap_{var}));")
    for idx, pred in enumerate(proj_predicates):
        lines.append(f"var wrap_closure_pred_{idx}: bool;")
        lines.append(f"wrap_closure_pred_{idx} := ({pred});")
        lines.append(f"call __wraparound_closure_assert_all((({pred}) == wrap_closure_pred_{idx}));")
    for idx in range(len(proj_predicates), proj_predicate_count):
        lines.append(f"var wrap_closure_pred_{idx}: bool;")
        lines.append(f"wrap_closure_pred_{idx} := true;")
    for idx, expr in enumerate(proj_exprs):
        lines.append(f"var wrap_closure_expr_{idx}: bv8;")
        lines.append(f"wrap_closure_expr_{idx} := {expr};")
        lines.append(f"call __wraparound_closure_assert_all(({expr} == wrap_closure_expr_{idx}));")
    return "\n" + "\n".join(lines) + ("\n" if lines else "")


def _stage_log_text(stage: str, bpl: Path, result: str, *, final_result: str | None = None) -> str:
    marker = final_result or result
    return (
        f"[RUN] Ultimate -i {bpl.as_posix()}\n"
        f"[x INFO y]: Registering result {result.split(': ', 1)[1]} "
        "for location ULTIMATE.startErr0ASSERT_VIOLATIONASSERT (0 of 1 remaining)\n"
        f"{marker}\n"
    )


def _write_stage_artifacts(
    root: Path,
    base_text: str,
    *,
    raw_bpl: bool = False,
    entry_final: str | None = None,
    near_final: str | None = None,
    closure_final: str | None = None,
    extra_bpl_text: str = "",
    closure_binding_text: str = "",
    log_bpl_suffix: str = "",
) -> dict:
    artifacts = {}
    for stage, result in [
        ("entry", "RESULT: UNSAFE"),
        ("near", "RESULT: UNSAFE"),
        ("closure", "RESULT: SAFE"),
    ]:
        bpl = root / f"{stage}.bpl"
        log = root / f"{stage}.log"
        stage_text = base_text if raw_bpl else _stage_bpl_text(stage, base_text)
        if stage == "closure":
            stage_text += closure_binding_text
        bpl.write_text(stage_text + extra_bpl_text, encoding="utf-8")
        final_result = None
        if stage == "entry":
            final_result = entry_final
        elif stage == "near":
            final_result = near_final
        elif stage == "closure":
            final_result = closure_final
        logged_bpl = Path(str(bpl) + log_bpl_suffix) if log_bpl_suffix else bpl
        log.write_text(
            _stage_log_text(
                stage,
                logged_bpl,
                result,
                final_result=final_result,
            ),
            encoding="utf-8",
        )
        artifacts[f"{'confirm' if stage == 'near' else stage}_bpl"] = str(bpl)
        artifacts[f"{'confirm' if stage == 'near' else stage}_log"] = str(log)
    return artifacts
