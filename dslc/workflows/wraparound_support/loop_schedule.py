from __future__ import annotations

import time
from dataclasses import replace
from pathlib import Path
from typing import Dict, List, Optional

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.analysis.wraparound_projection import extract_dependency_projection
from dslc.speclang.parse import parse_model
from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text
from dslc.transform.wraparound_analyze import _parse_global_var_types
from dslc.workflows.wraparound_cegis import (
    CegisAttemptArtifacts,
    CegisAttemptConfig,
    CegisAttemptRecord,
    StageRunner,
    WraparoundCegarMode,
    WraparoundStopAfter,
    _confirm_unroll_schedule,
    _effective_scalar_projection_vars,
    _index_expr_global_deps,
    _index_expr_unresolved_value_deps,
    _refine_proj_vars_greedy,
    _write_manifest,
    normalize_wraparound_stop_after,
)
from dslc.workflows.wraparound_support.schedule.prefix_cutpoint import (
    branch_projection_resolves_only_ambiguity as _branch_projection_resolves_only_ambiguity,
    conjoin_cutpoint as _conjoin_cutpoint,
    entry_prefix_mirror_assumes as _entry_prefix_mirror_assumes,
    focused_near_wrap_text as _focused_near_wrap_text,
    insert_confirm_prefix_marker as _insert_confirm_prefix_marker,
    select_cutpoint_guard_branch as _select_cutpoint_guard_branch,
    unique_exprs as _unique_exprs,
)
from dslc.workflows.wraparound_support.schedule.certification import (
    projection_complete_for_certification as _projection_complete_for_certification,
    projection_has_mailbox_state as _projection_has_mailbox_state,
)
from dslc.workflows.wraparound_support.schedule.closure_prefix import (
    write_prefix_closure_bpl as _write_prefix_closure_bpl,
)
from dslc.workflows.wraparound_support.refinement import (
    _find_latest_graphml_witness_since,
    _synthesize_refinement_assumes_from_witness,
)
from dslc.workflows.wraparound_support.schedule.stable_projection import (
    stable_substitution_env_shape_assumes as _stable_substitution_env_shape_assumes,
)
from dslc.workflows.wraparound_schedule import (
    blocker_exprs,
    infer_static_deterministic_schedule,
    make_schedule_blocker,
    projection_predicates_from_assumes,
    sha256_text,
)
from dslc.workflows.wraparound_support.stage_text import _unroll_confirm_like_mainprocedure


def _run_schedule_replay_cegar_loop(
    *,
    spec_path: Path,
    spec_text: str,
    base_bpl: Path,
    base_text: str,
    out_dir: Path,
    work_dir: Path,
    candidate: WraparoundCandidate,
    partition_ports: Dict[str, int],
    timeout_seconds: int,
    closure_timeout_cap_seconds: int,
    resource_limits: bool,
    confirm_unroll: int,
    max_confirm_unroll: int,
    max_iters: int,
    enable_env_completion_refinement: bool,
    runner: StageRunner,
    toolchain_nowitness: Path,
    toolchain_witness: Path,
    witness_settings: Path,
    closure_toolchain: Path,
    settings: Path,
    closure_settings: Path,
    confirm_settings_fallback: Optional[Path] = None,
    stage_order: str = "entry_confirm_closure",
    stop_after: str = WraparoundStopAfter.NONE.value,
) -> Path:
    """
    Paper-aligned schedule-replay CEGAR loop.

    MVP scope: deterministic sequential harnesses where the full one-round
    reaction schedule is encoded by `procurator_phase`. The manifest records the
    compact actor/phase schedule; Closure still proves the original inlined phase
    bodies, so residual table/mailbox nondeterminism is discharged there.
    """

    del partition_ports, confirm_settings_fallback, stage_order

    cand = candidate
    stop_after = normalize_wraparound_stop_after(stop_after)
    allow_diagnostic_refinement = bool(enable_env_completion_refinement)
    attempts: List[CegisAttemptRecord] = []
    blockers: List[ScheduleBlocker] = []
    blocked_schedule_ids: set[str] = set()
    base_hash = sha256_text(base_text)
    diagnostic = ""
    index_deps = _index_expr_global_deps(index_expr=cand.index_expr, base_text=base_text)
    index_projection_notes: List[str] = []
    index_projection_complete = True
    if index_deps:
        index_projection_complete = False
        index_projection_notes.append("dynamic_index_preloop_globals=" + ",".join(index_deps))
        index_projection_notes.append("dependency_projection_incomplete")
    unresolved_index_deps = _index_expr_unresolved_value_deps(index_expr=cand.index_expr, base_text=base_text)
    if unresolved_index_deps:
        index_projection_complete = False
        index_projection_notes.append("dynamic_index_unresolved_values=" + ",".join(unresolved_index_deps))
        index_projection_notes.append("dependency_projection_incomplete")
    closure_assumes: List[str] = []
    witness_profile_done = False
    dep_projection = extract_dependency_projection(bpl_text=base_text, candidate=cand)
    requested_proj_vars = list(dep_projection.proj_vars)
    base_cutpoint_cond = str(cand.cutpoint_cond or "true")
    selected_branch, selected_branch_index, branch_notes = _select_cutpoint_guard_branch(dep_projection)
    branch_projection_complete = _branch_projection_resolves_only_ambiguity(dep_projection, selected_branch)
    env_shape_assumes = _stable_substitution_env_shape_assumes(
        candidate=cand,
        live_deps=getattr(dep_projection, "live_deps", ()) or (),
        cutpoint_predicates=getattr(dep_projection, "cutpoint_predicates", ()) or (),
    )
    if selected_branch and branch_projection_complete:
        selected_set = set(selected_branch)
        cutpoint_set = set(getattr(dep_projection, "cutpoint_predicates", ()) or ())
        non_branch_predicates = [p for p in dep_projection.proj_predicates if p not in cutpoint_set or p in selected_set]
        proj_predicates = _unique_exprs([*non_branch_predicates, *selected_branch])
        effective_cutpoint_cond = _conjoin_cutpoint(base_cutpoint_cond, selected_branch)
    else:
        proj_predicates = _unique_exprs([*dep_projection.proj_predicates])
        effective_cutpoint_cond = base_cutpoint_cond
    proj_predicate_sources = [dep_projection.source for _p in proj_predicates]
    projection_complete_base = _projection_complete_for_certification(
        dep_projection,
        selected_branch=selected_branch,
        branch_projection_complete=branch_projection_complete,
        index_projection_complete=index_projection_complete,
    )
    schedule_cand = replace(cand, cutpoint_cond=effective_cutpoint_cond)
    proj_exprs = list(dep_projection.proj_exprs)
    proj_vars = _effective_scalar_projection_vars(base_text, requested_proj_vars)
    has_mailbox_projection = _projection_has_mailbox_state(proj_vars)
    base_proj_set = set(proj_vars)
    filtered_initial_proj = [v for v in requested_proj_vars if v not in base_proj_set]
    seeded_entry_res: Optional[StageRunResult] = None
    seeded_entry_bpl: Optional[Path] = None
    seeded_entry_log: Optional[Path] = None
    seeded_near_res: Optional[StageRunResult] = None
    seeded_confirm_bpl: Optional[Path] = None
    seeded_confirm_log: Optional[Path] = None
    seeded_unroll: Optional[int] = None
    reached_entry_prefix_unroll: Optional[int] = None

    try:
        spec_model = parse_model(spec_text)
    except Exception:
        # Unit tests may call schedule mode with dummy/empty spec text.  The
        # witness refinement helpers tolerate an empty model and still allow
        # canonical multi-node packet/meta prefixes from the Boogie program.
        from dslc.speclang.model import SpecModel

        spec_model = SpecModel()

    def _add_closure_assume(expr: str) -> bool:
        expr = str(expr).strip()
        if not expr:
            return False
        if expr in closure_assumes:
            return False
        closure_assumes.append(expr)
        return True

    def _schedule_for_current_projection() -> ActorSchedule:
        condition_preds = projection_predicates_from_assumes(closure_assumes, source="near_wrap_witness")
        return static_schedule.with_projection_vars(
            proj_vars,
            proj_predicates=proj_predicates,
            proj_predicate_sources=proj_predicate_sources,
            proj_exprs=proj_exprs,
            conditions=condition_preds,
            source=dep_projection.source,
        )

    def _cutpoint_assumes() -> tuple[str, ...]:
        cond = str(effective_cutpoint_cond).strip()
        if not cond or cond == "true":
            return ()
        return (cond,)

    def _write_near_wrap_bpl(
        *,
        stem: str,
        unroll: int,
        prefix_unroll: Optional[int] = None,
        index_value: int,
        proj_vars: List[str],
        proj_predicates: List[str],
        proj_exprs: List[str],
        step_delta: int,
        det_period: Optional[int],
    ) -> tuple[Path, Path]:
        if prefix_unroll is not None:
            bpl = out_dir / f"{stem}.near_wrap.prefix{prefix_unroll}.unroll{unroll}.bpl"
        else:
            bpl = out_dir / f"{stem}.near_wrap.unroll{unroll}.bpl"
        log = out_dir / f"{stem}.near_wrap.unroll{unroll}.log"
        bpl_text_for_confirm = base_text
        insertion_marker = None
        if prefix_unroll is not None:
            total_unroll = max(1, int(prefix_unroll)) + max(1, int(unroll))
            bpl_text_for_confirm, prefix_steps = _unroll_confirm_like_mainprocedure(
                bpl_text=base_text,
                requested_steps=total_unroll,
                deterministic_period=det_period,
            )
            logical_prefix = max(1, int(prefix_unroll))
            prefix_step_count = logical_prefix * det_period if det_period else logical_prefix
            bpl_text_for_confirm, insertion_marker = _insert_confirm_prefix_marker(
                bpl_text_for_confirm,
                prefix_steps=prefix_step_count,
            )
        txt = instrument_bpl_text(
            bpl_text=bpl_text_for_confirm,
            stage=WraparoundStage.CONFIRM,
            pump_reg=cand.pump_reg,
            accel_regs=list(cand.accel_regs),
            index_value=int(index_value),
            index_expr=cand.index_expr,
            proj_vars=list(proj_vars),
            proj_predicates=proj_predicates,
            proj_exprs=proj_exprs,
            cutpoint_cond=effective_cutpoint_cond,
            step_op=cand.step_op,
            step_delta=step_delta,
            extra_assumes=(*_cutpoint_assumes(), *env_shape_assumes),
            confirm_insertion_marker=insertion_marker,
        )
        if prefix_unroll is None:
            txt, _confirm_steps = _unroll_confirm_like_mainprocedure(
                bpl_text=txt,
                requested_steps=unroll,
                deterministic_period=det_period,
            )
        bpl.write_text(txt, encoding="utf-8")
        return bpl, log

    def _write_focused_near_wrap_bpl(confirm_bpl: Path, confirm_log: Path) -> Optional[tuple[Path, Path]]:
        focused_text = _focused_near_wrap_text(
            confirm_bpl.read_text(encoding="utf-8"),
            candidate=cand,
        )
        if focused_text is None:
            return None
        focused_bpl = confirm_bpl.with_name(confirm_bpl.stem + ".focused.bpl")
        focused_log = confirm_log.with_name(confirm_log.stem + ".focused" + confirm_log.suffix)
        focused_bpl.write_text(focused_text, encoding="utf-8")
        return focused_bpl, focused_log

    def _write_prefix_entry_bpl(
        *,
        stem: str,
        unroll: int,
        index_value: int,
        proj_vars: List[str],
        proj_predicates: List[str],
        proj_exprs: List[str],
        step_delta: int,
        det_period: Optional[int],
    ) -> tuple[Path, Path, int]:
        bpl = out_dir / f"{stem}.entry_prefix.unroll{unroll}.bpl"
        log = out_dir / f"{stem}.entry_prefix.unroll{unroll}.log"
        txt, effective_steps = _unroll_confirm_like_mainprocedure(
            bpl_text=base_text,
            requested_steps=unroll,
            deterministic_period=det_period,
        )
        txt = instrument_bpl_text(
            bpl_text=txt,
            stage=WraparoundStage.ENTRY_CHECK,
            pump_reg=cand.pump_reg,
            accel_regs=list(cand.accel_regs),
            index_value=int(index_value),
            index_expr=cand.index_expr,
            proj_vars=list(proj_vars),
            proj_predicates=proj_predicates,
            proj_exprs=proj_exprs,
            cutpoint_cond=effective_cutpoint_cond,
            step_op=cand.step_op,
            step_delta=step_delta,
            extra_assumes=(*_cutpoint_assumes(), *entry_prefix_mirror_assumes, *env_shape_assumes, *blocker_exprs(blockers)),
            entry_check_insertion="tail",
        )
        bpl.write_text(txt, encoding="utf-8")
        return bpl, log, effective_steps

    def _seed_closure_assumes_from_near_witness(
        *,
        cfg: CegisAttemptConfig,
        confirm_bpl: Path,
        confirm_log: Path,
        unroll: int,
        stem: str,
    ) -> tuple[CegisAttemptConfig, int]:
        nonlocal witness_profile_done
        if witness_profile_done or not toolchain_witness.exists():
            return cfg, 0

        # Witness extraction is diagnostic refinement for UNKNOWN closure only.
        # Keep it off the certified fast path: if pure projection closure is SAFE
        # or UNSAFE, no witness/profile assumptions are needed.
        witness_timeout_s = min(max(300, int(timeout_seconds)), 600)
        witness_log = confirm_log.with_suffix(confirm_log.suffix + ".witness.log")
        expected_witness = confirm_bpl.parent / f"{confirm_bpl.name}-witness.graphml"
        witness_pre_stat = expected_witness.stat() if expected_witness.exists() else None
        t0 = time.time()
        _ = runner.run(
            stage=f"confirm.witness.unroll{unroll}",
            input_bpl=confirm_bpl,
            log_path=witness_log,
            ultimate_home=ultimate_home_root / stem / f"near_wrap.unroll{unroll}.witness",
            toolchain=toolchain_witness,
            settings=witness_settings,
            timeout_seconds=witness_timeout_s,
            resource_limits=resource_limits,
        )
        witness: Optional[Path] = None
        if expected_witness.exists():
            st = expected_witness.stat()
            changed = witness_pre_stat is None or (
                st.st_mtime != witness_pre_stat.st_mtime or st.st_size != witness_pre_stat.st_size
            )
            if changed or st.st_mtime >= t0:
                witness = expected_witness
        if witness is None:
            witness = _find_latest_graphml_witness_since(work_dir=out_dir, since_time=t0)
        if not witness:
            witness_profile_done = True
            return cfg, 0

        try:
            wtxt = witness.read_text(encoding="utf-8", errors="replace")
            seed_assumes = _synthesize_refinement_assumes_from_witness(
                witness_text=wtxt,
                base_bpl_text=base_text,
                candidate=cand,
                spec_model=spec_model,
            )
        except Exception:
            seed_assumes = []

        added = 0
        for aexpr in seed_assumes:
            if _add_closure_assume(aexpr):
                added += 1
        witness_profile_done = True
        if added <= 0:
            return cfg, 0

        notes = list(cfg.notes) + [f"closure_seed_assumes={added}"]
        return replace(cfg, closure_assumes=tuple(closure_assumes), notes=tuple(notes)), added

    def _stage_status(res: StageRunResult) -> str:
        if res.is_safe:
            return "SAFE"
        if res.is_unsafe:
            return "UNSAFE"
        if res.timed_out:
            return "TIMEOUT"
        return "UNKNOWN"

    static_schedule = infer_static_deterministic_schedule(
        base_bpl_text=base_text,
        candidate=schedule_cand,
        base_bpl_sha256=base_hash,
    )
    if static_schedule is None:
        diagnostic = "candidate missing deterministic schedule metadata; falling back to direct verification"
        return _write_manifest(
            out_dir=out_dir,
            spec_path=spec_path,
            base_bpl=base_bpl,
            work_dir=work_dir,
            cand=cand,
            attempts=attempts,
            cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
            base_bpl_sha256=base_hash,
            blockers=blockers,
            certified=False,
            diagnostic=diagnostic,
        )

    width_mod = 1 << int(static_schedule.bitwidth)
    step_delta = int(static_schedule.step_delta)
    if cand.step_op != "add":
        diagnostic = (
            f"unsupported schedule step op {cand.step_op}; "
            "schedule-replay certification currently supports additive steps only; falling back"
        )
        return _write_manifest(
            out_dir=out_dir,
            spec_path=spec_path,
            base_bpl=base_bpl,
            work_dir=work_dir,
            cand=cand,
            attempts=attempts,
            cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
            base_bpl_sha256=base_hash,
            blockers=blockers,
            certified=False,
            diagnostic=diagnostic,
        )
    if step_delta == 0 or abs(step_delta) >= width_mod:
        diagnostic = f"unsupported schedule step_delta={step_delta} for bv{static_schedule.bitwidth}; falling back"
        return _write_manifest(
            out_dir=out_dir,
            spec_path=spec_path,
            base_bpl=base_bpl,
            work_dir=work_dir,
            cand=cand,
            attempts=attempts,
            cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
            base_bpl_sha256=base_hash,
            blockers=blockers,
            certified=False,
            diagnostic=diagnostic,
        )

    det_period = len(static_schedule.phases)
    var_types = _parse_global_var_types(base_text.splitlines())
    entry_prefix_mirror_assumes = _entry_prefix_mirror_assumes(
        branch=selected_branch,
        var_types=var_types,
    )
    ultimate_home_root = out_dir / "ultimate-home"
    max_iters = max(1, int(max_iters))
    confirm_unroll = max(1, int(confirm_unroll))
    max_confirm_unroll = int(max_confirm_unroll)

    for it in range(max_iters):
        if closure_timeout_cap_seconds <= 0:
            closure_timeout_this_attempt = int(timeout_seconds)
        else:
            closure_timeout_this_attempt = min(int(timeout_seconds), max(1, int(closure_timeout_cap_seconds)))
            if it + 1 >= max_iters:
                closure_timeout_this_attempt = int(timeout_seconds)

        notes = [
            "cegar_mode=schedule_replay",
            f"schedule_encoding={static_schedule.encoding}",
            f"deterministic_scheduler_period={det_period}",
            f"closure_timeout={closure_timeout_this_attempt}",
        ]
        if blockers:
            notes.append(f"blockers_in={len(blockers)}")
        if filtered_initial_proj:
            notes.append("filtered_proj_vars=" + ",".join(filtered_initial_proj))
        notes.extend(index_projection_notes)
        notes.extend(dep_projection.notes)
        notes.extend(branch_notes)
        if reached_entry_prefix_unroll is not None:
            notes.append(f"entry_prefix_unroll={reached_entry_prefix_unroll}")
        if selected_branch and branch_projection_complete:
            notes.append("dependency_projection_branch_cutpoint=" + effective_cutpoint_cond)
        if env_shape_assumes:
            notes.append("candidate_stable_env_shape=" + str(len(env_shape_assumes)))
        if proj_predicates:
            notes.append("proj_predicates=" + ";".join(proj_predicates))
        if proj_exprs:
            notes.append("proj_exprs=" + ";".join(proj_exprs))
        if closure_assumes:
            notes.append(f"closure_seed_assumes={len(closure_assumes)}")
        dropped_proj = sorted(base_proj_set.difference(set(proj_vars)))
        if dropped_proj:
            notes.append("drop_proj_vars=" + ",".join(dropped_proj))

        index_value = cand.index_value if cand.index_value is not None else 0
        cfg = CegisAttemptConfig(
            attempt=it,
            pump_reg=cand.pump_reg,
            accel_regs=cand.accel_regs,
            index_value=int(index_value),
            index_expr=cand.index_expr,
            proj_vars=tuple(proj_vars),
            cutpoint_cond=effective_cutpoint_cond,
            step_op=cand.step_op,
            step_delta=step_delta,
            proj_predicates=tuple(proj_predicates),
            proj_predicate_sources=tuple(proj_predicate_sources),
            proj_exprs=tuple(proj_exprs),
            env_shape_assumes=tuple(env_shape_assumes),
            projection_complete=bool(projection_complete_base),
            closure_assumes=tuple(closure_assumes),
            notes=tuple(notes),
        )

        stem = f"{spec_path.stem}.schedule.{it:02d}"
        entry_bpl = out_dir / f"{stem}.entry_check.bpl"
        entry_log = out_dir / f"{stem}.entry_check.log"
        confirm_bpl = out_dir / f"{stem}.near_wrap.unroll{confirm_unroll}.bpl"
        confirm_log = out_dir / f"{stem}.near_wrap.unroll{confirm_unroll}.log"
        closure_bpl = out_dir / f"{stem}.closure_check.bpl"
        closure_log = out_dir / f"{stem}.closure_check.log"

        entry_txt = instrument_bpl_text(
            bpl_text=base_text,
            stage=WraparoundStage.ENTRY_CHECK,
            pump_reg=cand.pump_reg,
            accel_regs=list(cand.accel_regs),
            index_value=int(index_value),
            index_expr=cand.index_expr,
            proj_vars=list(proj_vars),
            proj_predicates=proj_predicates,
            proj_exprs=proj_exprs,
            cutpoint_cond=effective_cutpoint_cond,
            step_op=cand.step_op,
            step_delta=step_delta,
            extra_assumes=(*_cutpoint_assumes(), *env_shape_assumes, *blocker_exprs(blockers)),
        )
        entry_bpl.write_text(entry_txt, encoding="utf-8")

        confirm_bpl, confirm_log = _write_near_wrap_bpl(
            stem=stem,
            unroll=confirm_unroll,
            prefix_unroll=reached_entry_prefix_unroll,
            index_value=int(index_value),
            proj_vars=proj_vars,
            proj_predicates=proj_predicates,
            proj_exprs=proj_exprs,
            step_delta=step_delta,
            det_period=det_period,
        )

        closure_txt = instrument_bpl_text(
            bpl_text=base_text,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg=cand.pump_reg,
            accel_regs=list(cand.accel_regs),
            index_value=int(index_value),
            index_expr=cand.index_expr,
            proj_vars=list(proj_vars),
            proj_predicates=proj_predicates,
            proj_exprs=proj_exprs,
            cutpoint_cond=effective_cutpoint_cond,
            step_op=cand.step_op,
            step_delta=step_delta,
            extra_assumes=(*env_shape_assumes, *closure_assumes),
        )
        closure_bpl.write_text(closure_txt, encoding="utf-8")

        artifacts = CegisAttemptArtifacts(
            entry_bpl=str(entry_bpl),
            closure_bpl=str(closure_bpl),
            confirm_bpl=str(confirm_bpl),
            entry_log=str(entry_log),
            closure_log=str(closure_log),
            confirm_log=str(confirm_log),
        )

        if seeded_entry_res is None:
            entry_res = runner.run(
                stage="entry_check",
                input_bpl=entry_bpl,
                log_path=entry_log,
                ultimate_home=ultimate_home_root / stem / "entry",
                toolchain=toolchain_nowitness,
                settings=settings,
                timeout_seconds=timeout_seconds,
                resource_limits=resource_limits,
            )
        else:
            entry_res = seeded_entry_res
            if seeded_entry_bpl is not None:
                entry_bpl = seeded_entry_bpl
            if seeded_entry_log is not None:
                entry_log = seeded_entry_log
            artifacts = CegisAttemptArtifacts(
                entry_bpl=str(entry_bpl),
                closure_bpl=str(closure_bpl),
                confirm_bpl=str(confirm_bpl),
                entry_log=str(entry_log),
                closure_log=str(closure_log),
                confirm_log=str(confirm_log),
            )
        if (
            entry_res.is_safe
            and selected_branch
            and branch_projection_complete
        ):
            prefix_schedule = _confirm_unroll_schedule(
                base=confirm_unroll,
                max_unroll=max_confirm_unroll if max_confirm_unroll > 0 else confirm_unroll,
            )
            last_prefix_res: Optional[StageRunResult] = None
            last_prefix_bpl: Optional[Path] = None
            last_prefix_log: Optional[Path] = None
            for prefix_unroll in prefix_schedule:
                prefix_bpl, prefix_log, prefix_steps = _write_prefix_entry_bpl(
                    stem=stem,
                    unroll=prefix_unroll,
                    index_value=int(index_value),
                    proj_vars=proj_vars,
                    proj_predicates=proj_predicates,
                    proj_exprs=proj_exprs,
                    step_delta=step_delta,
                    det_period=det_period,
                )
                last_prefix_res = runner.run(
                    stage=f"entry_check.prefix.unroll{prefix_unroll}",
                    input_bpl=prefix_bpl,
                    log_path=prefix_log,
                    ultimate_home=ultimate_home_root / stem / f"entry_prefix.unroll{prefix_unroll}",
                    toolchain=toolchain_nowitness,
                    settings=settings,
                    timeout_seconds=timeout_seconds,
                    resource_limits=resource_limits,
                )
                last_prefix_bpl = prefix_bpl
                last_prefix_log = prefix_log
                if last_prefix_res.is_unsafe:
                    entry_res = last_prefix_res
                    entry_bpl = prefix_bpl
                    entry_log = prefix_log
                    reached_entry_prefix_unroll = int(prefix_unroll)
                    artifacts = CegisAttemptArtifacts(
                        entry_bpl=str(entry_bpl),
                        closure_bpl=str(closure_bpl),
                        confirm_bpl=str(confirm_bpl),
                        entry_log=str(entry_log),
                        closure_log=str(closure_log),
                        confirm_log=str(confirm_log),
                    )
                    cfg = replace(
                        cfg,
                        notes=tuple(
                            [
                                *cfg.notes,
                                "initial_entry_result=SAFE",
                                f"entry_prefix_unroll={prefix_unroll}",
                                f"entry_prefix_effective_steps={prefix_steps}",
                            ]
                        ),
                    )
                    break
                if last_prefix_res.is_unknown:
                    break
            if not entry_res.is_unsafe and last_prefix_res is not None:
                entry_res = last_prefix_res
                if last_prefix_bpl is not None and last_prefix_log is not None:
                    entry_bpl = last_prefix_bpl
                    entry_log = last_prefix_log
                    artifacts = CegisAttemptArtifacts(
                        entry_bpl=str(entry_bpl),
                        closure_bpl=str(closure_bpl),
                        confirm_bpl=str(confirm_bpl),
                        entry_log=str(entry_log),
                        closure_log=str(closure_log),
                        confirm_log=str(confirm_log),
                    )

        if not entry_res.is_unsafe:
            if entry_res.is_safe and selected_branch and branch_projection_complete:
                diagnostic = "bounded prefix entry did not reach selected cutpoint; falling back"
            elif entry_res.is_unknown:
                diagnostic = "entry unknown/timeout; falling back"
            else:
                diagnostic = "entry unreachable or blocked; falling back"
            attempts.append(
                CegisAttemptRecord(
                    cfg=cfg,
                    artifacts=artifacts,
                    entry=entry_res,
                    closure=None,
                    confirm=None,
                    schedule=_schedule_for_current_projection().to_manifest(),
                    diagnostic=diagnostic,
                )
            )
            _write_manifest(
                out_dir=out_dir,
                spec_path=spec_path,
                base_bpl=base_bpl,
                work_dir=work_dir,
                cand=cand,
                attempts=attempts,
                cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
                base_bpl_sha256=base_hash,
                blockers=blockers,
                certified=False,
                diagnostic=diagnostic,
            )
            break

        attempt_index = len(attempts)
        attempts.append(
            CegisAttemptRecord(
                cfg=cfg,
                artifacts=artifacts,
                entry=entry_res,
                closure=None,
                confirm=None,
                schedule=_schedule_for_current_projection().to_manifest(),
                diagnostic="entry reached; schedule metadata recorded",
            )
        )
        _write_manifest(
            out_dir=out_dir,
            spec_path=spec_path,
            base_bpl=base_bpl,
            work_dir=work_dir,
            cand=cand,
            attempts=attempts,
            cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
            base_bpl_sha256=base_hash,
            blockers=blockers,
            certified=False,
            diagnostic="entry reached; running near-wrap check",
        )
        if stop_after == WraparoundStopAfter.ENTRY.value:
            diagnostic = "stopped after entry by request"
            attempts[attempt_index] = replace(
                attempts[attempt_index],
                diagnostic=diagnostic,
            )
            _write_manifest(
                out_dir=out_dir,
                spec_path=spec_path,
                base_bpl=base_bpl,
                work_dir=work_dir,
                cand=cand,
                attempts=attempts,
                cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
                base_bpl_sha256=base_hash,
                blockers=blockers,
                certified=False,
                diagnostic=diagnostic,
            )
            break

        current_schedule = _schedule_for_current_projection()
        if current_schedule.schedule_id in blocked_schedule_ids:
            diagnostic = f"ineffective schedule blocker for {current_schedule.schedule_id}; falling back"
            attempts[attempt_index] = replace(
                attempts[attempt_index],
                diagnostic=diagnostic,
            )
            _write_manifest(
                out_dir=out_dir,
                spec_path=spec_path,
                base_bpl=base_bpl,
                work_dir=work_dir,
                cand=cand,
                attempts=attempts,
                cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
                base_bpl_sha256=base_hash,
                blockers=blockers,
                certified=False,
                diagnostic=diagnostic,
            )
            break

        near_res: Optional[StageRunResult] = None
        unroll = int(seeded_unroll or confirm_unroll)
        if seeded_near_res is not None and seeded_confirm_bpl is not None and seeded_confirm_log is not None:
            near_res = seeded_near_res
            confirm_bpl = seeded_confirm_bpl
            confirm_log = seeded_confirm_log
            artifacts = CegisAttemptArtifacts(
                entry_bpl=str(entry_bpl),
                closure_bpl=str(closure_bpl),
                confirm_bpl=str(confirm_bpl),
                entry_log=str(entry_log),
                closure_log=str(closure_log),
                confirm_log=str(confirm_log),
            )
        else:
            unroll_schedule = _confirm_unroll_schedule(
                base=confirm_unroll,
                max_unroll=max_confirm_unroll if max_confirm_unroll > 0 else confirm_unroll,
            )
            for pos, unroll in enumerate(unroll_schedule):
                if unroll != confirm_unroll:
                    confirm_bpl, confirm_log = _write_near_wrap_bpl(
                        stem=stem,
                        unroll=unroll,
                        prefix_unroll=reached_entry_prefix_unroll,
                        index_value=int(index_value),
                        proj_vars=proj_vars,
                        proj_predicates=proj_predicates,
                        proj_exprs=proj_exprs,
                        step_delta=step_delta,
                        det_period=det_period,
                    )
                else:
                    if reached_entry_prefix_unroll is not None:
                        confirm_bpl = out_dir / f"{stem}.near_wrap.prefix{reached_entry_prefix_unroll}.unroll{unroll}.bpl"
                        if not confirm_bpl.exists():
                            confirm_bpl, confirm_log = _write_near_wrap_bpl(
                                stem=stem,
                                unroll=unroll,
                                prefix_unroll=reached_entry_prefix_unroll,
                                index_value=int(index_value),
                                proj_vars=proj_vars,
                                proj_predicates=proj_predicates,
                                proj_exprs=proj_exprs,
                                step_delta=step_delta,
                                det_period=det_period,
                            )
                        else:
                            confirm_log = out_dir / f"{stem}.near_wrap.unroll{unroll}.log"
                    else:
                        confirm_bpl = out_dir / f"{stem}.near_wrap.unroll{unroll}.bpl"
                        confirm_log = out_dir / f"{stem}.near_wrap.unroll{unroll}.log"
                artifacts = CegisAttemptArtifacts(
                    entry_bpl=str(entry_bpl),
                    closure_bpl=str(closure_bpl),
                    confirm_bpl=str(confirm_bpl),
                    entry_log=str(entry_log),
                    closure_log=str(closure_log),
                    confirm_log=str(confirm_log),
                )

                focused_paths: Optional[tuple[Path, Path]] = None
                if reached_entry_prefix_unroll is not None:
                    focused_paths = _write_focused_near_wrap_bpl(confirm_bpl, confirm_log)
                if focused_paths is not None:
                    source_confirm_bpl = confirm_bpl
                    source_confirm_log = confirm_log
                    focused_bpl, focused_log = focused_paths
                    focused_res = runner.run(
                        stage="near_wrap.focused",
                        input_bpl=focused_bpl,
                        log_path=focused_log,
                        ultimate_home=ultimate_home_root / stem / f"near_wrap.unroll{unroll}.focused",
                        toolchain=toolchain_nowitness,
                        settings=settings,
                        timeout_seconds=timeout_seconds,
                        resource_limits=resource_limits,
                    )
                    if focused_res.is_unsafe:
                        confirm_bpl = focused_bpl
                        confirm_log = focused_log
                        near_res = focused_res
                        artifacts = CegisAttemptArtifacts(
                            entry_bpl=str(entry_bpl),
                            closure_bpl=str(closure_bpl),
                            confirm_bpl=str(confirm_bpl),
                            entry_log=str(entry_log),
                            closure_log=str(closure_log),
                            confirm_log=str(confirm_log),
                            source_confirm_bpl=str(source_confirm_bpl),
                            source_confirm_log=str(source_confirm_log),
                        )
                        break

                near_res = runner.run(
                    stage="near_wrap",
                    input_bpl=confirm_bpl,
                    log_path=confirm_log,
                    ultimate_home=ultimate_home_root / stem / f"near_wrap.unroll{unroll}",
                    toolchain=toolchain_nowitness,
                    settings=settings,
                    timeout_seconds=timeout_seconds,
                    resource_limits=resource_limits,
                )
                if near_res.is_unsafe:
                    break
                if near_res.is_unknown:
                    break

        if near_res is None or not near_res.is_unsafe:
            diagnostic = "near-wrap check did not find a bug for this schedule; falling back"
            attempts[attempt_index] = replace(
                attempts[attempt_index],
                artifacts=artifacts,
                confirm=near_res,
                near_wrap=near_res,
                diagnostic=diagnostic,
            )
            _write_manifest(
                out_dir=out_dir,
                spec_path=spec_path,
                base_bpl=base_bpl,
                work_dir=work_dir,
                cand=cand,
                attempts=attempts,
                cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
                base_bpl_sha256=base_hash,
                blockers=blockers,
                certified=False,
                diagnostic=diagnostic,
            )
            break

        attempts[attempt_index] = replace(
            attempts[attempt_index],
            artifacts=artifacts,
            confirm=near_res,
            near_wrap=near_res,
            diagnostic="near-wrap bug found; running closure proof",
        )
        if seeded_near_res is None:
            seeded_entry_res = entry_res
            seeded_entry_bpl = entry_bpl
            seeded_entry_log = entry_log
            seeded_near_res = near_res
            seeded_confirm_bpl = confirm_bpl
            seeded_confirm_log = confirm_log
            seeded_unroll = int(unroll)
        _write_manifest(
            out_dir=out_dir,
            spec_path=spec_path,
            base_bpl=base_bpl,
            work_dir=work_dir,
            cand=cand,
            attempts=attempts,
            cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
            base_bpl_sha256=base_hash,
            blockers=blockers,
            certified=False,
            diagnostic="near-wrap bug found; running closure proof",
        )
        if stop_after == WraparoundStopAfter.NEAR_WRAP.value:
            diagnostic = "stopped after near_wrap by request"
            attempts[attempt_index] = replace(
                attempts[attempt_index],
                diagnostic=diagnostic,
            )
            _write_manifest(
                out_dir=out_dir,
                spec_path=spec_path,
                base_bpl=base_bpl,
                work_dir=work_dir,
                cand=cand,
                attempts=attempts,
                cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
                base_bpl_sha256=base_hash,
                blockers=blockers,
                certified=False,
                diagnostic=diagnostic,
            )
            break

        if not cfg.projection_complete:
            diagnostic = "near-wrap bug found but hard dependency projection gap remains; falling back to direct verification"
            attempts[attempt_index] = replace(
                attempts[attempt_index],
                diagnostic=diagnostic,
            )
            _write_manifest(
                out_dir=out_dir,
                spec_path=spec_path,
                base_bpl=base_bpl,
                work_dir=work_dir,
                cand=cand,
                attempts=attempts,
                cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
                base_bpl_sha256=base_hash,
                blockers=blockers,
                certified=False,
                diagnostic=diagnostic,
            )
            break

        closure_res = runner.run(
            stage="closure_check",
            input_bpl=closure_bpl,
            log_path=closure_log,
            ultimate_home=ultimate_home_root / stem / "closure",
            toolchain=closure_toolchain,
            settings=closure_settings,
            timeout_seconds=closure_timeout_this_attempt,
            resource_limits=resource_limits,
        )

        certified = bool(cfg.projection_complete and closure_res.is_safe and not closure_assumes)
        if closure_res.is_safe:
            if closure_assumes:
                diagnostic = "closure safe under witness replay conditions only; falling back"
            elif not cfg.projection_complete:
                diagnostic = "closure safe but dependency projection incomplete; falling back"
            else:
                diagnostic = "certified schedule-replay wraparound bug"
        elif closure_res.is_unknown:
            diagnostic = "closure unknown/timeout; falling back"
        else:
            diagnostic = "closure counterexample; blocking schedule"

        prefix_probe_notes: List[str] = []
        tried_mailbox_prefix_probe = False
        if closure_res.is_unsafe and not closure_assumes and has_mailbox_projection:
            tried_mailbox_prefix_probe = True
            prefix_cap = max_confirm_unroll if max_confirm_unroll > 0 else confirm_unroll
            # Keep the user-provided bound when explicitly set (>0).
            # When max_confirm_unroll is left at 0 (default "no growth"), allow a
            # small mailbox-oriented closure-prefix sweep so closure probing does not
            # collapse to a single prefix and miss reachable replay cutpoints.
            if max_confirm_unroll <= 0:
                prefix_cap = max(prefix_cap, 3)
                prefix_probe_notes.append(f"closure_prefix_auto_cap={prefix_cap}")
            prefix_schedule = _confirm_unroll_schedule(
                base=confirm_unroll,
                max_unroll=prefix_cap,
            )
            closure_suffix_schedule = [1]
            suffix_cap = max_confirm_unroll if max_confirm_unroll > 0 else max(confirm_unroll, 3)
            for suffix_unroll in _confirm_unroll_schedule(base=confirm_unroll, max_unroll=max(3, suffix_cap)):
                if suffix_unroll not in closure_suffix_schedule:
                    closure_suffix_schedule.append(int(suffix_unroll))
            for prefix_unroll in prefix_schedule:
                prefix_entry_bpl, prefix_entry_log, prefix_entry_steps = _write_prefix_entry_bpl(
                    stem=stem,
                    unroll=prefix_unroll,
                    index_value=int(index_value),
                    proj_vars=proj_vars,
                    proj_predicates=proj_predicates,
                    proj_exprs=proj_exprs,
                    step_delta=step_delta,
                    det_period=det_period,
                )
                prefix_entry_res = runner.run(
                    stage=f"entry_check.closure_prefix.unroll{prefix_unroll}",
                    input_bpl=prefix_entry_bpl,
                    log_path=prefix_entry_log,
                    ultimate_home=ultimate_home_root / stem / f"closure_prefix.entry.unroll{prefix_unroll}",
                    toolchain=toolchain_nowitness,
                    settings=settings,
                    timeout_seconds=timeout_seconds,
                    resource_limits=resource_limits,
                )
                if not prefix_entry_res.is_unsafe:
                    prefix_probe_notes.append(
                        f"closure_prefix_entry_unroll{prefix_unroll}={_stage_status(prefix_entry_res)}"
                    )
                    if prefix_entry_res.is_unknown:
                        break
                    continue

                prefix_near_bpl, prefix_near_log = _write_near_wrap_bpl(
                    stem=stem,
                    unroll=unroll,
                    prefix_unroll=prefix_unroll,
                    index_value=int(index_value),
                    proj_vars=proj_vars,
                    proj_predicates=proj_predicates,
                    proj_exprs=proj_exprs,
                    step_delta=step_delta,
                    det_period=det_period,
                )
                prefix_near_res = runner.run(
                    stage=f"near_wrap.closure_prefix.unroll{prefix_unroll}",
                    input_bpl=prefix_near_bpl,
                    log_path=prefix_near_log,
                    ultimate_home=ultimate_home_root / stem / f"closure_prefix.near.unroll{prefix_unroll}",
                    toolchain=toolchain_nowitness,
                    settings=settings,
                    timeout_seconds=timeout_seconds,
                    resource_limits=resource_limits,
                )
                if not prefix_near_res.is_unsafe:
                    prefix_probe_notes.append(
                        f"closure_prefix_near_unroll{prefix_unroll}={_stage_status(prefix_near_res)}"
                    )
                    if prefix_near_res.is_unknown:
                        break
                    continue

                prefix_closure_bpl = out_dir / f"{stem}.closure_prefix.unroll{prefix_unroll}.bpl"
                prefix_closure_log = out_dir / f"{stem}.closure_prefix.unroll{prefix_unroll}.log"
                prefix_closure_steps = 0
                prefix_closure_res: Optional[StageRunResult] = None
                selected_suffix_unroll: Optional[int] = None
                stop_prefix = False
                for suffix_unroll in closure_suffix_schedule:
                    prefix_closure_bpl, prefix_closure_log, prefix_closure_steps = _write_prefix_closure_bpl(
                        out_dir=out_dir,
                        base_text=base_text,
                        stem=stem,
                        prefix_unroll=prefix_unroll,
                        suffix_unroll=int(suffix_unroll),
                        pump_reg=cand.pump_reg,
                        accel_regs=cand.accel_regs,
                        index_value=int(index_value),
                        index_expr=cand.index_expr,
                        proj_vars=proj_vars,
                        proj_predicates=proj_predicates,
                        proj_exprs=proj_exprs,
                        cutpoint_cond=effective_cutpoint_cond,
                        step_op=cand.step_op,
                        step_delta=step_delta,
                        closure_assumes=closure_assumes,
                        env_shape_assumes=env_shape_assumes,
                        det_period=det_period,
                    )
                    suffix_stage = (
                        f"closure_check.prefix.unroll{prefix_unroll}"
                        if int(suffix_unroll) == 1
                        else f"closure_check.prefix.unroll{prefix_unroll}.suffix{int(suffix_unroll)}"
                    )
                    prefix_closure_res = runner.run(
                        stage=suffix_stage,
                        input_bpl=prefix_closure_bpl,
                        log_path=prefix_closure_log,
                        ultimate_home=ultimate_home_root / stem / f"closure_prefix.closure.unroll{prefix_unroll}.suffix{int(suffix_unroll)}",
                        toolchain=closure_toolchain,
                        settings=closure_settings,
                        timeout_seconds=closure_timeout_this_attempt,
                        resource_limits=resource_limits,
                    )
                    prefix_probe_notes.append(
                        f"closure_prefix_unroll{prefix_unroll}_suffix{int(suffix_unroll)}={_stage_status(prefix_closure_res)}"
                    )
                    if prefix_closure_res.is_safe:
                        selected_suffix_unroll = int(suffix_unroll)
                        break
                    if prefix_closure_res.is_unknown:
                        stop_prefix = True
                        break
                if prefix_closure_res is None or not prefix_closure_res.is_safe:
                    if stop_prefix:
                        break
                    continue

                prefix_notes = tuple(
                    [
                        *cfg.notes,
                        f"closure_prefix_unroll={prefix_unroll}",
                        f"closure_suffix_unroll={selected_suffix_unroll or 1}",
                        f"closure_prefix_entry_effective_steps={prefix_entry_steps}",
                        f"closure_prefix_effective_steps={prefix_closure_steps}",
                    ]
                )
                cfg = replace(cfg, notes=prefix_notes)
                entry_res = prefix_entry_res
                entry_bpl = prefix_entry_bpl
                entry_log = prefix_entry_log
                near_res = prefix_near_res
                confirm_bpl = prefix_near_bpl
                confirm_log = prefix_near_log
                closure_res = prefix_closure_res
                closure_bpl = prefix_closure_bpl
                closure_log = prefix_closure_log
                artifacts = CegisAttemptArtifacts(
                    entry_bpl=str(entry_bpl),
                    closure_bpl=str(closure_bpl),
                    confirm_bpl=str(confirm_bpl),
                    entry_log=str(entry_log),
                    closure_log=str(closure_log),
                    confirm_log=str(confirm_log),
                    source_confirm_bpl=str(prefix_near_bpl),
                    source_confirm_log=str(prefix_near_log),
                )
                certified = bool(
                    cfg.projection_complete
                    and prefix_entry_res.is_unsafe
                    and prefix_near_res.is_unsafe
                    and prefix_closure_res.is_safe
                    and not closure_assumes
                )
                diagnostic = "certified schedule-replay wraparound bug via prefix closure"
                break
        if tried_mailbox_prefix_probe and prefix_probe_notes:
            cfg = replace(cfg, notes=tuple([*cfg.notes, *prefix_probe_notes]))

        attempts[attempt_index] = replace(
            attempts[attempt_index],
            cfg=cfg,
            artifacts=artifacts,
            entry=entry_res,
            closure=closure_res,
            confirm=near_res,
            near_wrap=near_res,
            schedule=_schedule_for_current_projection().to_manifest(),
            certified=certified,
            diagnostic=diagnostic,
        )
        _write_manifest(
            out_dir=out_dir,
            spec_path=spec_path,
            base_bpl=base_bpl,
            work_dir=work_dir,
            cand=cand,
            attempts=attempts,
            cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
            base_bpl_sha256=base_hash,
            blockers=blockers,
            certified=certified,
            diagnostic=diagnostic,
        )

        if stop_after == WraparoundStopAfter.CLOSURE.value:
            diagnostic = "stopped after closure by request"
            attempts[attempt_index] = replace(
                attempts[attempt_index],
                diagnostic=diagnostic,
            )
            _write_manifest(
                out_dir=out_dir,
                spec_path=spec_path,
                base_bpl=base_bpl,
                work_dir=work_dir,
                cand=cand,
                attempts=attempts,
                cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
                base_bpl_sha256=base_hash,
                blockers=blockers,
                certified=certified,
                diagnostic=diagnostic,
            )
            break
        if closure_res.is_safe:
            break
        if closure_res.is_unknown:
            if allow_diagnostic_refinement and not closure_assumes and (it + 1 < max_iters):
                next_cfg, added = _seed_closure_assumes_from_near_witness(
                    cfg=cfg,
                    confirm_bpl=confirm_bpl,
                    confirm_log=confirm_log,
                    unroll=unroll,
                    stem=stem,
                )
                if added > 0:
                    cfg = next_cfg
                    diagnostic = "closure unknown; seeded witness replay conditions for next closure"
                    attempts[attempt_index] = replace(
                        attempts[attempt_index],
                        diagnostic=diagnostic,
                    )
                    _write_manifest(
                        out_dir=out_dir,
                        spec_path=spec_path,
                        base_bpl=base_bpl,
                        work_dir=work_dir,
                        cand=cand,
                        attempts=attempts,
                        cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
                        base_bpl_sha256=base_hash,
                        blockers=blockers,
                        certified=False,
                        diagnostic=diagnostic,
                    )
                    continue
            refined_proj = _refine_proj_vars_greedy(
                list(proj_vars),
                mandatory=["procurator_phase"],
                max_drops=len(proj_vars),
            )
            if allow_diagnostic_refinement and closure_assumes and refined_proj != proj_vars and (it + 1 < max_iters):
                proj_vars = refined_proj
                diagnostic = "closure unknown; weakening projection with near-wrap witness predicates"
                attempts[attempt_index] = replace(
                    attempts[attempt_index],
                    diagnostic=diagnostic,
                )
                _write_manifest(
                    out_dir=out_dir,
                    spec_path=spec_path,
                    base_bpl=base_bpl,
                    work_dir=work_dir,
                    cand=cand,
                    attempts=attempts,
                    cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
                    base_bpl_sha256=base_hash,
                    blockers=blockers,
                    certified=False,
                    diagnostic=diagnostic,
                )
                continue
            break

        current_schedule = _schedule_for_current_projection()
        blocker = make_schedule_blocker(current_schedule, reason="closure_unsafe")
        if blocker.schedule_id in blocked_schedule_ids:
            diagnostic = f"duplicate schedule blocker for {blocker.schedule_id}; falling back"
            break
        blocked_schedule_ids.add(blocker.schedule_id)
        blockers.append(blocker)
        # ENTRY/NEAR_WRAP reuse is only valid for closure-only projection
        # weakening.  A blocker changes the ENTRY query itself, so the next
        # iteration must run ENTRY again with the blocker assumptions in place.
        seeded_entry_res = None
        seeded_entry_bpl = None
        seeded_entry_log = None
        seeded_near_res = None
        seeded_confirm_bpl = None
        seeded_confirm_log = None
        seeded_unroll = None
        reached_entry_prefix_unroll = None
        diagnostic = "closure counterexample blocked; rerunning entry"
        continue
    else:
        diagnostic = "max schedule CEGAR iterations exhausted; falling back"

    return _write_manifest(
        out_dir=out_dir,
        spec_path=spec_path,
        base_bpl=base_bpl,
        work_dir=work_dir,
        cand=cand,
        attempts=attempts,
        cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
        base_bpl_sha256=base_hash,
        blockers=blockers,
        certified=any(a.certified for a in attempts),
        diagnostic=diagnostic,
    )
