from __future__ import annotations

import hashlib
import json
import re
from dataclasses import asdict, dataclass
from typing import Iterable, Mapping, Optional, Sequence

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.transform.wraparound_analyze import (
    _extract_main_phase_bodies,
    _infer_deterministic_scheduler_period,
    analyze_bpl_for_wraparound,
)
from dslc.transform.wraparound_common import WraparoundStage


@dataclass(frozen=True)
class ProjectionPredicate:
    lhs: str
    rhs: str
    kind: str
    source: str


@dataclass(frozen=True)
class ActorSchedule:
    schedule_id: str
    candidate_id: str
    actors: tuple[str, ...]
    phases: tuple[int, ...]
    reactions: tuple[str, ...]
    target_regs: tuple[str, ...]
    index_value: int
    step_delta: int
    bitwidth: int
    projection: tuple[ProjectionPredicate, ...]
    entry_witness: str
    base_bpl_sha256: str
    conditions: tuple[ProjectionPredicate, ...] = ()
    encoding: str = "deterministic_phase_actor_array"
    coverage: str = "deterministic sequential full-round schedule; residual choices discharged by closure"

    def to_manifest(self) -> dict:
        # Certified schedule data is intentionally actor-order only.  Keep
        # `phases`/`reactions` as local audit/debug metadata but do not serialize
        # them as part of the schedule certificate.
        data = asdict(self)
        data.pop("phases", None)
        data.pop("reactions", None)
        return data

    def with_projection_predicates(self, predicates: Sequence[ProjectionPredicate]) -> "ActorSchedule":
        projection = _merge_projection(self.projection, tuple(predicates))
        return self._replace(projection=projection, conditions=self.conditions)

    def with_projection_vars(
        self,
        proj_vars: Sequence[str],
        *,
        proj_predicates: Sequence[str] = (),
        proj_exprs: Sequence[str] = (),
        conditions: Sequence[ProjectionPredicate] = (),
        source: str = "candidate_projection",
    ) -> "ActorSchedule":
        projection_vars = tuple(
            ProjectionPredicate(lhs=v, rhs="entry_snapshot", kind=_projection_kind(v), source=source)
            for v in proj_vars
        )
        projection_preds = tuple(
            ProjectionPredicate(
                lhs=f"predicate:{i}",
                rhs=str(expr).strip(),
                kind="predicate",
                source=source,
            )
            for i, expr in enumerate(proj_predicates)
            if str(expr).strip()
        )
        projection_exprs = tuple(
            ProjectionPredicate(
                lhs=f"expr:{i}",
                rhs=str(expr).strip(),
                kind="expr",
                source=source,
            )
            for i, expr in enumerate(proj_exprs)
            if str(expr).strip()
        )
        projection = projection_vars + projection_preds + projection_exprs
        return self._replace(projection=projection, conditions=tuple(conditions))

    def _replace(
        self,
        *,
        projection: Sequence[ProjectionPredicate],
        conditions: Sequence[ProjectionPredicate],
    ) -> "ActorSchedule":
        projection = tuple(projection)
        conditions = tuple(conditions)
        schedule_id = compute_actor_schedule_id(
            candidate_id=self.candidate_id,
            target_regs=self.target_regs,
            index_value=self.index_value,
            step_delta=self.step_delta,
            actors=self.actors,
            projection=projection,
            base_bpl_sha256=self.base_bpl_sha256,
        )
        return ActorSchedule(
            schedule_id=schedule_id,
            candidate_id=self.candidate_id,
            actors=self.actors,
            phases=self.phases,
            reactions=self.reactions,
            target_regs=self.target_regs,
            index_value=self.index_value,
            step_delta=self.step_delta,
            bitwidth=self.bitwidth,
            projection=projection,
            conditions=conditions,
            entry_witness=self.entry_witness,
            base_bpl_sha256=self.base_bpl_sha256,
            encoding=self.encoding,
            coverage=self.coverage,
        )


@dataclass(frozen=True)
class ScheduleBlocker:
    blocker_id: str
    schedule_id: str
    reason: str
    expr: str
    actors: tuple[str, ...]
    projection: tuple[ProjectionPredicate, ...]

    def to_manifest(self) -> dict:
        return asdict(self)


_RE_ACTION_COMMENT = re.compile(
    r"//\s*(?P<kind>env inject|host send|host recv|node pass|node ingress|node egress)\s*->\s*(?P<name>[A-Za-z_][A-Za-z0-9_.-]*)"
)


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8", errors="replace")).hexdigest()


def _stable_hash(payload: object) -> str:
    data = json.dumps(payload, sort_keys=True, separators=(",", ":"), default=str)
    return hashlib.sha256(data.encode("utf-8")).hexdigest()[:24]


def _projection_payload(projection: Sequence[object]) -> list[object]:
    out: list[object] = []
    for pred in projection:
        if isinstance(pred, ProjectionPredicate):
            out.append(asdict(pred))
        elif isinstance(pred, Mapping):
            out.append(dict(pred))
        else:
            out.append(pred)
    return out


def actor_schedule_identity_payload(
    *,
    candidate_id: str,
    target_regs: Sequence[str],
    index_value: int,
    step_delta: int,
    actors: Sequence[str],
    projection: Sequence[object],
    base_bpl_sha256: str,
) -> dict:
    return {
        "candidate_id": str(candidate_id),
        "target_regs": list(target_regs),
        "index_value": int(index_value),
        "step_delta": int(step_delta),
        "actors": list(actors),
        "projection": _projection_payload(projection),
        "base_bpl_sha256": str(base_bpl_sha256),
    }


def compute_actor_schedule_id(
    *,
    candidate_id: str,
    target_regs: Sequence[str],
    index_value: int,
    step_delta: int,
    actors: Sequence[str],
    projection: Sequence[object],
    base_bpl_sha256: str,
) -> str:
    return _stable_hash(
        actor_schedule_identity_payload(
            candidate_id=candidate_id,
            target_regs=target_regs,
            index_value=index_value,
            step_delta=step_delta,
            actors=actors,
            projection=projection,
            base_bpl_sha256=base_bpl_sha256,
        )
    )


def compute_wraparound_candidate_id(
    *,
    pump_reg: str,
    accel_regs: Sequence[str],
    index_value: object,
    index_expr: object,
    step_op: str,
    step_delta: int,
    cutpoint_cond: object = None,
) -> str:
    return _stable_hash(
        {
            "pump_reg": str(pump_reg),
            "accel_regs": list(accel_regs),
            "index_value": index_value,
            "index_expr": index_expr,
            "cutpoint_cond": cutpoint_cond,
            "step_op": str(step_op),
            "step_delta": int(step_delta),
        }
    )


def _unique_in_order(values: Iterable[str]) -> tuple[str, ...]:
    seen: set[str] = set()
    out: list[str] = []
    for v in values:
        if v in seen:
            continue
        seen.add(v)
        out.append(v)
    return tuple(out)


def _merge_projection(
    base: Sequence[ProjectionPredicate],
    extra: Sequence[ProjectionPredicate],
) -> tuple[ProjectionPredicate, ...]:
    out: list[ProjectionPredicate] = []
    seen: set[tuple[str, str, str]] = set()
    for pred in (*base, *extra):
        key = (pred.lhs, pred.rhs, pred.kind)
        if key in seen:
            continue
        seen.add(key)
        out.append(pred)
    return tuple(out)


def _actor_from_reaction(kind: str, name: str) -> str:
    if kind == "env inject":
        return "env"
    return name


def _reaction_token(kind: str, name: str) -> str:
    return f"{kind.replace(' ', '_')}:{name}"


def infer_static_deterministic_schedule(
    *,
    base_bpl_text: str,
    candidate: WraparoundCandidate,
    base_bpl_sha256: str,
    entry_witness: str = "",
) -> Optional[ActorSchedule]:
    """
    Build the MVP schedule certificate for deterministic sequential harnesses.

    In this harness shape, the one-round reaction schedule is statically encoded
    by `procurator_phase`. The compact `actors[]` representation is sound only as
    a phase-indexed encoding; the closure obligation still executes the original
    inlined phase bodies and must discharge all residual nondeterminism.
    """

    period = _infer_deterministic_scheduler_period(base_bpl_text.splitlines())
    if period is None or period <= 0:
        return None

    try:
        phase_bodies = _extract_main_phase_bodies(base_bpl_text.splitlines(keepends=True), period)
    except Exception:
        return None

    actors: list[str] = []
    reactions: list[str] = []
    for _phase, body in enumerate(phase_bodies):
        actor = ""
        reaction = ""
        for line in body:
            m = _RE_ACTION_COMMENT.search(line)
            if not m:
                continue
            kind = m.group("kind")
            name = m.group("name")
            actor = _actor_from_reaction(kind, name)
            reaction = _reaction_token(kind, name)
            break
        if not actor:
            return None
        actors.append(actor)
        reactions.append(reaction)

    try:
        cfg = analyze_bpl_for_wraparound(
            bpl_text=base_bpl_text,
            pump_reg=candidate.pump_reg,
            accel_regs=candidate.accel_regs,
            index_value=candidate.index_value if candidate.index_value is not None else 0,
            index_expr=candidate.index_expr,
            proj_vars=candidate.proj_vars,
            cutpoint_cond=candidate.cutpoint_cond,
            step_op=candidate.step_op,
            step_delta=int(candidate.step_delta or 1),
            stage=WraparoundStage.CLOSURE_CHECK,
        )
        bitwidth = int(cfg.pump_target.elem_width)
    except Exception:
        return None

    target_regs = _unique_in_order([candidate.pump_reg, *candidate.accel_regs])
    index_value = int(candidate.index_value) if candidate.index_value is not None else 0
    step_delta = int(candidate.step_delta or 1)
    proj_vars = tuple(candidate.proj_vars or ("procurator_phase",))
    projection = tuple(
        ProjectionPredicate(lhs=v, rhs="entry_snapshot", kind=_projection_kind(v), source="candidate_projection")
        for v in proj_vars
    )

    candidate_id = compute_wraparound_candidate_id(
        pump_reg=candidate.pump_reg,
        accel_regs=candidate.accel_regs,
        index_value=candidate.index_value,
        index_expr=candidate.index_expr,
        cutpoint_cond=candidate.cutpoint_cond,
        step_op=candidate.step_op,
        step_delta=step_delta,
    )
    return ActorSchedule(
        schedule_id=compute_actor_schedule_id(
            candidate_id=candidate_id,
            target_regs=target_regs,
            index_value=index_value,
            step_delta=step_delta,
            actors=actors,
            projection=projection,
            base_bpl_sha256=base_bpl_sha256,
        ),
        candidate_id=candidate_id,
        actors=tuple(actors),
        phases=tuple(range(period)),
        reactions=tuple(reactions),
        target_regs=target_regs,
        index_value=index_value,
        step_delta=step_delta,
        bitwidth=bitwidth,
        projection=projection,
        conditions=(),
        entry_witness=entry_witness,
        base_bpl_sha256=base_bpl_sha256,
    )


def _projection_kind(name: str) -> str:
    if name == "procurator_phase" or name.startswith("procurator_"):
        return "scheduler"
    if name.endswith("_inbox_count") or name.endswith("_egress_count"):
        return "mailbox"
    if name.startswith("dsl_") or name.endswith("dsl_pump_mode"):
        return "env"
    if "hash" in name or "idx" in name or "index" in name or "partition" in name:
        return "data_dep"
    return "control_dep"


_RE_ASSUME_EQ = re.compile(
    r"^\s*(?:assume\s*)?\(?\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z0-9_]+)*)\s*==\s*(?P<rhs>.+?)\s*\)?\s*;?\s*$"
)


def projection_predicates_from_assumes(
    assumes: Sequence[str],
    *,
    source: str = "witness_projection",
) -> tuple[ProjectionPredicate, ...]:
    out: list[ProjectionPredicate] = []
    for expr in assumes:
        m = _RE_ASSUME_EQ.match(str(expr).strip())
        if not m:
            continue
        lhs = m.group("lhs").strip()
        rhs = m.group("rhs").strip()
        out.append(ProjectionPredicate(lhs=lhs, rhs=rhs, kind=_projection_kind(lhs), source=source))
    return tuple(out)


def make_schedule_blocker(schedule: ActorSchedule, *, reason: str) -> ScheduleBlocker:
    blocker_id = _stable_hash({"schedule_id": schedule.schedule_id, "reason": reason})
    # The deterministic full-round MVP has no alternate schedule to enumerate once
    # this schedule is blocked. The expression intentionally blocks the next ENTRY
    # query in schedule mode only; ordinary GemCutter fallback remains untouched.
    return ScheduleBlocker(
        blocker_id=blocker_id,
        schedule_id=schedule.schedule_id,
        reason=reason,
        expr="false",
        actors=schedule.actors,
        projection=schedule.projection,
    )


def blocker_exprs(blockers: Sequence[ScheduleBlocker]) -> tuple[str, ...]:
    return tuple(b.expr for b in blockers if b.expr)
