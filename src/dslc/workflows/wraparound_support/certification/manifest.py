from __future__ import annotations

from dslc.analysis.wraparound_projection import is_stable_projection_predicate_text
from dslc.workflows.wraparound_schedule import (
    compute_actor_schedule_id,
    compute_wraparound_candidate_id,
    dependency_projection_has_hard_certification_gap,
)


PAPER_STAGE_NAMES = {
    "stage1": "ENTRY_CHECK",
    "stage2": "NEAR_WRAP",
    "stage3": "CLOSURE_CHECK",
}


def paper_stage_names() -> dict[str, str]:
    return dict(PAPER_STAGE_NAMES)


def _stage_result_is(res: object, what: str) -> bool:
    if not isinstance(res, dict):
        return False
    s = str(res.get("result_line") or "").lower()
    if what == "unsafe":
        return ("result: unsafe" in s) or ("proved your program to be incorrect" in s)
    if what == "safe":
        return ("result: safe" in s) or ("proved your program to be correct" in s)
    return what.lower() in s


def _is_empty_sequence(value: object) -> bool:
    return isinstance(value, (list, tuple)) and len(value) == 0


def manifest_certified_unsafe_data(data: dict) -> bool:
    attempts = data.get("attempts") or []
    if not isinstance(attempts, list):
        return False

    mode = str(data.get("cegar_mode") or "legacy_closure_assumes")
    if mode == "schedule_replay":
        return _schedule_replay_manifest_certified(data, attempts)

    for attempt in attempts:
        if not isinstance(attempt, dict):
            continue
        if (
            _stage_result_is(attempt.get("entry"), "unsafe")
            and _stage_result_is(attempt.get("confirm"), "unsafe")
            and _stage_result_is(attempt.get("closure"), "safe")
        ):
            return True
    return False


def _schedule_replay_manifest_certified(data: dict, attempts: list[object]) -> bool:
    base_hash = str(data.get("base_bpl_sha256") or "")
    if not base_hash:
        return False
    manifest_cand = data.get("candidate")
    manifest_index_value = manifest_cand.get("index_value") if isinstance(manifest_cand, dict) else None
    manifest_index_expr = manifest_cand.get("index_expr") if isinstance(manifest_cand, dict) else None
    for attempt in attempts:
        if not isinstance(attempt, dict):
            continue
        sched = attempt.get("schedule")
        if not isinstance(sched, dict):
            continue
        schedule_id = str(sched.get("schedule_id") or "")
        if not schedule_id:
            return False
        if str(sched.get("base_bpl_sha256") or "") != base_hash:
            continue
        actors = sched.get("actors")
        if not isinstance(actors, (list, tuple)) or not actors:
            continue
        if "phases" in sched or "reactions" in sched:
            continue
        if not _is_empty_sequence(sched.get("conditions")):
            continue
        cfg = attempt.get("cfg")
        if not isinstance(cfg, dict):
            continue
        if not _is_empty_sequence(cfg.get("closure_assumes")):
            continue
        if not _env_shape_assumes_are_certifiable(
            cfg_env_shape=cfg.get("env_shape_assumes"),
            manifest_cand=manifest_cand,
        ):
            continue
        if cfg.get("projection_complete") is not True:
            continue
        cfg_notes = cfg.get("notes") or []
        if not isinstance(cfg_notes, (list, tuple)):
            continue
        if dependency_projection_has_hard_certification_gap(notes=[str(n) for n in cfg_notes]):
            continue
        cfg_proj = cfg.get("proj_vars")
        if not isinstance(cfg_proj, (list, tuple)):
            continue
        cfg_pred = cfg.get("proj_predicates")
        if cfg_pred is None:
            cfg_pred = []
        if not isinstance(cfg_pred, (list, tuple)):
            continue
        cfg_pred_sources = cfg.get("proj_predicate_sources")
        if cfg_pred_sources is None:
            cfg_pred_sources = ["dependency_projection"] * len(cfg_pred)
        if not isinstance(cfg_pred_sources, (list, tuple)) or len(cfg_pred_sources) != len(cfg_pred):
            continue
        if not _projection_predicate_sources_are_certifiable(cfg_pred, cfg_pred_sources):
            continue
        cfg_expr = cfg.get("proj_exprs")
        if cfg_expr is None:
            cfg_expr = []
        if not isinstance(cfg_expr, (list, tuple)):
            continue
        sched_target_regs = sched.get("target_regs") or []
        if not isinstance(sched_target_regs, (list, tuple)) or not sched_target_regs:
            continue
        sched_proj = sched.get("projection") or []
        if not isinstance(sched_proj, (list, tuple)):
            continue
        if len(sched_proj) != len(cfg_proj) + len(cfg_pred) + len(cfg_expr):
            continue
        try:
            expected_candidate_id = _expected_candidate_id(
                cfg=cfg,
                manifest_cand=manifest_cand,
                manifest_index_value=manifest_index_value,
                manifest_index_expr=manifest_index_expr,
            )
            if str(sched.get("candidate_id") or "") != expected_candidate_id:
                continue
            if not _schedule_scalar_fields_match(sched, cfg, sched_target_regs):
                continue
            recomputed_schedule_id = compute_actor_schedule_id(
                candidate_id=expected_candidate_id,
                target_regs=[str(v) for v in sched_target_regs],
                index_value=int(sched.get("index_value")),
                step_delta=int(sched.get("step_delta")),
                actors=[str(v) for v in actors],
                projection=list(sched_proj),
                base_bpl_sha256=base_hash,
            )
        except (TypeError, ValueError):
            continue
        if recomputed_schedule_id != schedule_id:
            continue
        if not _schedule_projection_matches_cfg(sched_proj, cfg_proj, cfg_pred, cfg_pred_sources, cfg_expr):
            continue
        if (
            attempt.get("certified") is True
            and _stage_result_is(attempt.get("entry"), "unsafe")
            and _stage_result_is(attempt.get("near_wrap"), "unsafe")
            and _stage_result_is(attempt.get("closure"), "safe")
        ):
            return True
    return False


def _projection_predicate_sources_are_certifiable(cfg_pred: object, cfg_pred_sources: object) -> bool:
    for expr, source in zip(cfg_pred, cfg_pred_sources):
        if str(source) != "dependency_projection":
            return False
        if not is_stable_projection_predicate_text(str(expr)):
            return False
    return True


def _env_shape_assumes_are_certifiable(*, cfg_env_shape: object, manifest_cand: object) -> bool:
    if cfg_env_shape is None:
        cfg_env_shape = []
    if not isinstance(cfg_env_shape, (list, tuple)):
        return False
    cfg_values = [str(v).strip() for v in cfg_env_shape if str(v).strip()]

    cand_subs = ()
    if isinstance(manifest_cand, dict):
        cand_subs = tuple(manifest_cand.get("stable_substitutions") or ())
    allowed: list[str] = []
    for sub in cand_subs:
        if not isinstance(sub, (list, tuple)) or len(sub) != 2:
            return False
        lhs = str(sub[0]).strip()
        rhs = str(sub[1]).strip()
        if not lhs or not rhs:
            continue
        allowed.append(f"{lhs} == {rhs}")

    allowed_set = set(allowed)
    for expr in cfg_values:
        if expr not in allowed_set:
            return False
    return True


def _expected_candidate_id(
    *,
    cfg: dict,
    manifest_cand: object,
    manifest_index_value: object,
    manifest_index_expr: object,
) -> str:
    cfg_accel_regs = cfg.get("accel_regs") or []
    if not isinstance(cfg_accel_regs, (list, tuple)):
        raise ValueError("invalid accel regs")
    return compute_wraparound_candidate_id(
        pump_reg=str(cfg.get("pump_reg") or ""),
        accel_regs=[str(v) for v in cfg_accel_regs],
        index_value=manifest_index_value if isinstance(manifest_cand, dict) else cfg.get("index_value"),
        index_expr=manifest_index_expr if isinstance(manifest_cand, dict) else cfg.get("index_expr"),
        cutpoint_cond=cfg.get("cutpoint_cond"),
        step_op=str(cfg.get("step_op") or ""),
        step_delta=int(cfg.get("step_delta")),
    )


def _schedule_scalar_fields_match(sched: dict, cfg: dict, sched_target_regs: object) -> bool:
    cfg_accel_regs = cfg.get("accel_regs") or []
    if not isinstance(cfg_accel_regs, (list, tuple)):
        return False
    expected_target_regs: list[str] = []
    for reg in [str(cfg.get("pump_reg") or ""), *[str(v) for v in cfg_accel_regs]]:
        if reg and reg not in expected_target_regs:
            expected_target_regs.append(reg)
    if [str(v) for v in sched_target_regs] != expected_target_regs:
        return False
    return int(sched.get("index_value")) == int(cfg.get("index_value")) and int(sched.get("step_delta")) == int(
        cfg.get("step_delta")
    )


def _schedule_projection_matches_cfg(
    sched_proj: object,
    cfg_proj: object,
    cfg_pred: object,
    cfg_pred_sources: object,
    cfg_expr: object,
) -> bool:
    pred_start = len(cfg_proj)
    expr_start = pred_start + len(cfg_pred)
    for pred, cfg_lhs in zip(sched_proj[:pred_start], cfg_proj):
        if not _projection_entry_matches(pred, source="dependency_projection", kind=None, lhs=str(cfg_lhs), rhs="entry_snapshot"):
            return False
    for i, (pred, cfg_pred_expr) in enumerate(zip(sched_proj[pred_start:expr_start], cfg_pred)):
        if not _projection_entry_matches(
            pred,
            source=str(cfg_pred_sources[i]),
            kind="predicate",
            lhs=f"predicate:{i}",
            rhs=str(cfg_pred_expr),
        ):
            return False
    for i, (pred, cfg_proj_expr) in enumerate(zip(sched_proj[expr_start:], cfg_expr)):
        if not _projection_entry_matches(
            pred,
            source="dependency_projection",
            kind="expr",
            lhs=f"expr:{i}",
            rhs=str(cfg_proj_expr),
        ):
            return False
    return True


def _projection_entry_matches(pred: object, *, source: str, kind: str | None, lhs: str, rhs: str) -> bool:
    if not isinstance(pred, dict):
        return False
    if str(pred.get("source") or "") != source:
        return False
    if kind is not None and str(pred.get("kind") or "") != kind:
        return False
    if str(pred.get("lhs") or "") != lhs:
        return False
    return str(pred.get("rhs") or "") == rhs
