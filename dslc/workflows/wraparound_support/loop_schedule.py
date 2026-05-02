from __future__ import annotations

import time
from dataclasses import replace
from pathlib import Path
from typing import Dict, List, Optional

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.analysis.wraparound_projection import extract_dependency_projection
from dslc.speclang.parse import parse_model
from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text
from dslc.workflows.wraparound_cegis import (
    CegisAttemptArtifacts,
    CegisAttemptConfig,
    CegisAttemptRecord,
    StageRunner,
    WraparoundCegarMode,
    WraparoundStopAfter,
    _confirm_unroll_schedule,
    _dynamic_index_fallback_diagnostic,
    _effective_scalar_projection_vars,
    _index_expr_global_deps,
    _index_expr_unresolved_value_deps,
    _refine_proj_vars_greedy,
    _unresolved_index_fallback_diagnostic,
    _write_manifest,
    normalize_wraparound_stop_after,
)
from dslc.workflows.wraparound_support.refinement import (
    _find_latest_graphml_witness_since,
    _synthesize_refinement_assumes_from_witness,
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
    if index_deps:
        diagnostic = _dynamic_index_fallback_diagnostic(index_deps)
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
    unresolved_index_deps = _index_expr_unresolved_value_deps(index_expr=cand.index_expr, base_text=base_text)
    if unresolved_index_deps:
        diagnostic = _unresolved_index_fallback_diagnostic(unresolved_index_deps)
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
    closure_assumes: List[str] = []
    witness_profile_done = False
    dep_projection = extract_dependency_projection(bpl_text=base_text, candidate=cand)
    requested_proj_vars = list(dep_projection.proj_vars)
    proj_predicates = list(dep_projection.proj_predicates)
    proj_vars = _effective_scalar_projection_vars(base_text, requested_proj_vars)
    base_proj_set = set(proj_vars)
    filtered_initial_proj = [v for v in requested_proj_vars if v not in base_proj_set]
    seeded_entry_res: Optional[StageRunResult] = None
    seeded_entry_bpl: Optional[Path] = None
    seeded_entry_log: Optional[Path] = None
    seeded_near_res: Optional[StageRunResult] = None
    seeded_confirm_bpl: Optional[Path] = None
    seeded_confirm_log: Optional[Path] = None
    seeded_unroll: Optional[int] = None

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
            conditions=condition_preds,
            source=dep_projection.source,
        )

    def _cutpoint_assumes() -> tuple[str, ...]:
        cond = str(cand.cutpoint_cond or "").strip()
        if not cond or cond == "true":
            return ()
        return (cond,)

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

    static_schedule = infer_static_deterministic_schedule(
        base_bpl_text=base_text,
        candidate=cand,
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

    if not dep_projection.complete:
        diagnostic = "dependency projection incomplete; falling back to direct verification"
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
        notes.extend(dep_projection.notes)
        if proj_predicates:
            notes.append("proj_predicates=" + ";".join(proj_predicates))
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
            cutpoint_cond=cand.cutpoint_cond,
            step_op=cand.step_op,
            step_delta=step_delta,
            proj_predicates=tuple(proj_predicates),
            projection_complete=bool(dep_projection.complete),
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
            cutpoint_cond=cand.cutpoint_cond,
            step_op=cand.step_op,
            step_delta=step_delta,
            extra_assumes=(*_cutpoint_assumes(), *blocker_exprs(blockers)),
        )
        entry_bpl.write_text(entry_txt, encoding="utf-8")

        confirm_txt = instrument_bpl_text(
            bpl_text=base_text,
            stage=WraparoundStage.CONFIRM,
            pump_reg=cand.pump_reg,
            accel_regs=list(cand.accel_regs),
            index_value=int(index_value),
            index_expr=cand.index_expr,
            proj_vars=list(proj_vars),
            proj_predicates=proj_predicates,
            cutpoint_cond=cand.cutpoint_cond,
            step_op=cand.step_op,
            step_delta=step_delta,
            extra_assumes=_cutpoint_assumes(),
        )
        confirm_txt, _confirm_steps = _unroll_confirm_like_mainprocedure(
            bpl_text=confirm_txt,
            requested_steps=confirm_unroll,
            deterministic_period=det_period,
        )
        confirm_bpl.write_text(confirm_txt, encoding="utf-8")

        closure_txt = instrument_bpl_text(
            bpl_text=base_text,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg=cand.pump_reg,
            accel_regs=list(cand.accel_regs),
            index_value=int(index_value),
            index_expr=cand.index_expr,
            proj_vars=list(proj_vars),
            proj_predicates=proj_predicates,
            cutpoint_cond=cand.cutpoint_cond,
            step_op=cand.step_op,
            step_delta=step_delta,
            extra_assumes=closure_assumes,
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
        if not entry_res.is_unsafe:
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
            for unroll in _confirm_unroll_schedule(
                base=confirm_unroll,
                max_unroll=max_confirm_unroll if max_confirm_unroll > 0 else confirm_unroll,
            ):
                if unroll != confirm_unroll:
                    confirm_bpl = out_dir / f"{stem}.near_wrap.unroll{unroll}.bpl"
                    confirm_log = out_dir / f"{stem}.near_wrap.unroll{unroll}.log"
                    confirm_txt = instrument_bpl_text(
                        bpl_text=base_text,
                        stage=WraparoundStage.CONFIRM,
                        pump_reg=cand.pump_reg,
                        accel_regs=list(cand.accel_regs),
                        index_value=int(index_value),
                        index_expr=cand.index_expr,
                        proj_vars=list(proj_vars),
                        cutpoint_cond=cand.cutpoint_cond,
                        step_op=cand.step_op,
                        step_delta=step_delta,
                        extra_assumes=_cutpoint_assumes(),
                    )
                    confirm_txt, _confirm_steps = _unroll_confirm_like_mainprocedure(
                        bpl_text=confirm_txt,
                        requested_steps=unroll,
                        deterministic_period=det_period,
                    )
                    confirm_bpl.write_text(confirm_txt, encoding="utf-8")
                    artifacts = CegisAttemptArtifacts(
                        entry_bpl=str(entry_bpl),
                        closure_bpl=str(closure_bpl),
                        confirm_bpl=str(confirm_bpl),
                        entry_log=str(entry_log),
                        closure_log=str(closure_log),
                        confirm_log=str(confirm_log),
                    )

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
                if near_res.is_unsafe or near_res.is_unknown:
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

        certified = bool(closure_res.is_safe and not closure_assumes)
        if closure_res.is_safe:
            if closure_assumes:
                diagnostic = "closure safe under witness replay conditions only; falling back"
            else:
                diagnostic = "certified schedule-replay wraparound bug"
        elif closure_res.is_unknown:
            diagnostic = "closure unknown/timeout; falling back"
        else:
            diagnostic = "closure counterexample; blocking schedule"
        attempts[attempt_index] = replace(
            attempts[attempt_index],
            artifacts=artifacts,
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
