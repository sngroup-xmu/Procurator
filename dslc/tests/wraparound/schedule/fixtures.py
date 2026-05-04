from __future__ import annotations

from pathlib import Path

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.workflows.wraparound_cegis import StageRunResult
from dslc.workflows.wraparound_schedule import infer_static_deterministic_schedule, sha256_text


_MIN_BPL = """\
var procurator_phase: int;
var procurator_step: int;
var s1_hdr.nc_hdr.op: bv8;
var r: [bv32]bv8;
var r__last0_value: bv8;

procedure main() returns()
  modifies procurator_phase, r, r__last0_value;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    // env inject -> s1
  } else if (procurator_phase == 1) {
    // node pass -> s1
    r[0bv32] := add.bv8(r[0bv32], 1bv8);
    r__last0_value := r[0bv32];
  } else {
    assume false;
  }
  if (procurator_phase == 1) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, procurator_step, r, r__last0_value;
{
  procurator_step := 0;
  procurator_phase := 0;
  r__last0_value := 0bv8;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""


_BRANCH_GUARD_BPL = """\
var procurator_phase: int;
var procurator_step: int;
var time_reg: [bv32]bv32;
var flow_reg: [bv32]bv32;
var r: [bv32]bv8;
var r__last_index: bv32;
var r__last_value: bv8;

procedure main() returns()
  modifies procurator_phase, procurator_step, time_reg, flow_reg, r, r__last_index, r__last_value;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    // env inject -> s1
  } else if (procurator_phase == 1) {
    // node pass -> s1
    if (time_reg[0bv32] == 0bv32) {
      r[0bv32] := add.bv8(r[0bv32], 1bv8);
      r__last_index := 0bv32;
      r__last_value := r[0bv32];
    } else {
      if (flow_reg[0bv32] == 7bv32) {
        r[0bv32] := add.bv8(r[0bv32], 1bv8);
        r__last_index := 0bv32;
        r__last_value := r[0bv32];
      }
    }
  } else {
    assume false;
  }
  if (procurator_phase == 1) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, procurator_step, time_reg, flow_reg, r, r__last_index, r__last_value;
{
  procurator_step := 0;
  procurator_phase := 0;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""


def _candidate() -> WraparoundCandidate:
    return WraparoundCandidate(
        pump_reg="r",
        accel_regs=("r",),
        index_value=0,
        index_expr=None,
        proj_vars=("procurator_phase",),
        cutpoint_cond="(procurator_phase == 0)",
        reason="test",
        step_op="add",
        step_delta=1,
    )


def _branch_guard_candidate() -> WraparoundCandidate:
    return WraparoundCandidate(
        pump_reg="r",
        accel_regs=("r",),
        index_value=0,
        index_expr=None,
        proj_vars=("procurator_phase",),
        cutpoint_cond="(procurator_phase == 0)",
        reason="branch_guard_test",
        step_op="add",
        step_delta=1,
    )


def _candidate_with_mailbox_projection() -> WraparoundCandidate:
    return WraparoundCandidate(
        pump_reg="r",
        accel_regs=("r",),
        index_value=0,
        index_expr=None,
        proj_vars=("s1_inbox_count", "procurator_phase"),
        cutpoint_cond="(procurator_phase == 0)",
        reason="test",
        step_op="add",
        step_delta=1,
    )


def _candidate_with_unavailable_projection() -> WraparoundCandidate:
    return WraparoundCandidate(
        pump_reg="r",
        accel_regs=("r",),
        index_value=0,
        index_expr=None,
        proj_vars=("procurator_phase", "missing_projection", "r"),
        cutpoint_cond="(procurator_phase == 0)",
        reason="test",
        step_op="add",
        step_delta=1,
    )


def _dependency_schedule_manifest(base_bpl_text: str = _MIN_BPL) -> dict:
    sched = infer_static_deterministic_schedule(
        base_bpl_text=base_bpl_text,
        candidate=_candidate(),
        base_bpl_sha256=sha256_text(base_bpl_text),
    )
    assert sched is not None
    dep_sched = sched.with_projection_vars(("procurator_phase",), source="dependency_projection")
    return dep_sched.to_manifest()


def _dependency_schedule_manifest_with_predicate(base_bpl_text: str = _MIN_BPL) -> dict:
    sched = infer_static_deterministic_schedule(
        base_bpl_text=base_bpl_text,
        candidate=_candidate(),
        base_bpl_sha256=sha256_text(base_bpl_text),
    )
    assert sched is not None
    dep_sched = sched.with_projection_vars(
        ("procurator_phase",),
        proj_predicates=("procurator_phase == 0",),
        source="dependency_projection",
    )
    return dep_sched.to_manifest()


def _schedule_cfg(*, proj_predicates: tuple[str, ...] = ()) -> dict:
    return {
        "pump_reg": "r",
        "accel_regs": ["r"],
        "index_value": 0,
        "index_expr": None,
        "cutpoint_cond": "(procurator_phase == 0)",
        "step_op": "add",
        "step_delta": 1,
        "proj_vars": ["procurator_phase"],
        "proj_predicates": list(proj_predicates),
        "projection_complete": True,
        "closure_assumes": [],
    }


class _SequenceRunner:
    def __init__(self, closure_results: list[str]) -> None:
        self.closure_results = list(closure_results)
        self.calls: list[str] = []
        self.snapshots: list[tuple[str, str]] = []

    def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
        self.calls.append(stage)
        log_path = kwargs.get("log_path")
        input_bpl = kwargs.get("input_bpl")
        text = Path(input_bpl).read_text(encoding="utf-8") if input_bpl is not None else ""
        self.snapshots.append((stage, text))
        if stage == "entry_check":
            if "assume(false);" in text:
                result_line = "RESULT: SAFE"
            else:
                result_line = "RESULT: UNSAFE"
            if log_path is not None:
                Path(log_path).write_text(f"{Path(input_bpl).name if input_bpl is not None else ''}\n{result_line}\n", encoding="utf-8")
            return StageRunResult(stage=stage, returncode=0, wall_time_s=0.0, result_line=result_line)
        if stage == "near_wrap":
            result_line = "RESULT: UNSAFE"
            if log_path is not None:
                Path(log_path).write_text(f"{Path(input_bpl).name if input_bpl is not None else ''}\n{result_line}\n", encoding="utf-8")
            return StageRunResult(stage=stage, returncode=0, wall_time_s=0.0, result_line=result_line)
        if stage.startswith("confirm.witness."):
            result_line = "RESULT: UNSAFE"
            if log_path is not None:
                Path(log_path).write_text(f"{Path(input_bpl).name if input_bpl is not None else ''}\n{result_line}\n", encoding="utf-8")
            return StageRunResult(stage=stage, returncode=0, wall_time_s=0.0, result_line=result_line)
        if stage == "closure_check":
            result = self.closure_results.pop(0)
            result_line = f"RESULT: {result}"
            if log_path is not None:
                Path(log_path).write_text(f"{Path(input_bpl).name if input_bpl is not None else ''}\n{result_line}\n", encoding="utf-8")
            return StageRunResult(stage=stage, returncode=0, wall_time_s=0.0, result_line=result_line)
        raise AssertionError(stage)


class _TimeoutRecordingRunner(_SequenceRunner):
    def __init__(self, closure_results: list[str]) -> None:
        super().__init__(closure_results)
        self.timeouts: list[tuple[str, int]] = []

    def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
        self.timeouts.append((stage, int(kwargs.get("timeout_seconds", 0))))
        return super().run(stage=stage, **kwargs)
