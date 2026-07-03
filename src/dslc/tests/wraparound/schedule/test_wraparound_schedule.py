from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import dslc.workflows.wraparound_cegis as wraparound_cegis
from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.bench.validate_counterexample import validate_wraparound_manifest
from dslc.workflows.wraparound_cegis import (
    StageRunResult,
    WraparoundCegarMode,
    _manifest_certified_unsafe_data,
    _run_schedule_replay_cegar_loop,
)
from dslc.workflows.wraparound_schedule import (
    infer_static_deterministic_schedule,
    projection_predicates_from_assumes,
    sha256_text,
)

from dslc.tests.wraparound.schedule.fixtures import (
    _MIN_BPL,
    _SequenceRunner,
    _candidate,
    _candidate_with_mailbox_projection,
    _candidate_with_unavailable_projection,
)


class WraparoundScheduleTests(unittest.TestCase):
    def test_static_schedule_extracts_phase_actor_array(self) -> None:
        sched = infer_static_deterministic_schedule(
            base_bpl_text=_MIN_BPL,
            candidate=_candidate(),
            base_bpl_sha256=sha256_text(_MIN_BPL),
        )
        self.assertIsNotNone(sched)
        assert sched is not None
        self.assertEqual(sched.actors, ("env", "s1"))
        self.assertEqual(sched.phases, (0, 1))
        self.assertEqual(sched.reactions, ("env_inject:s1", "node_pass:s1"))
        self.assertNotIn("reactions", sched.to_manifest())
        self.assertNotIn("phases", sched.to_manifest())
        self.assertEqual(sched.step_delta, 1)
        self.assertEqual(sched.bitwidth, 8)
        self.assertTrue(sched.schedule_id)

    def test_schedule_identity_ignores_phase_metadata(self) -> None:
        sched = infer_static_deterministic_schedule(
            base_bpl_text=_MIN_BPL,
            candidate=_candidate(),
            base_bpl_sha256=sha256_text(_MIN_BPL),
        )
        self.assertIsNotNone(sched)
        assert sched is not None
        mutated = sched.__class__(
            schedule_id=sched.schedule_id,
            candidate_id=sched.candidate_id,
            actors=sched.actors,
            phases=(10, 20),
            reactions=sched.reactions,
            target_regs=sched.target_regs,
            index_value=sched.index_value,
            step_delta=sched.step_delta,
            bitwidth=sched.bitwidth,
            projection=sched.projection,
            entry_witness=sched.entry_witness,
            base_bpl_sha256=sched.base_bpl_sha256,
            conditions=sched.conditions,
            encoding=sched.encoding,
            coverage=sched.coverage,
        )
        self.assertEqual(mutated.with_projection_vars(("procurator_phase",)).schedule_id, sched.schedule_id)

    def test_schedule_replay_certifies_when_closure_is_safe(self) -> None:
        runner = _SequenceRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=2,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(manifest["cegar_mode"], "schedule_replay")
            self.assertTrue(manifest["certified"])
            self.assertEqual(runner.calls, ["entry_check", "near_wrap", "closure_check"])
            entry_text = next(text for stage, text in runner.snapshots if stage == "entry_check")
            self.assertIn("call __wraparound_entry_error();", entry_text)
            self.assertIn("assume((procurator_phase == 0));", entry_text)
            self.assertIn("WRAPAROUND_ENTRY_ASSERT", entry_text)
            self.assertNotIn("__wraparound_pump_error", entry_text)
            self.assertNotIn("var wrap_target_old", entry_text)
            near_text = next(text for stage, text in runner.snapshots if stage == "near_wrap")
            self.assertIn("assume((procurator_phase == 0));", near_text)
            self.assertEqual(manifest["blockers"], [])
            self.assertEqual(len(manifest["attempts"]), 1)
            self.assertTrue(_manifest_certified_unsafe_data(manifest))
            ok, msg = validate_wraparound_manifest(manifest_path)
            self.assertTrue(ok, msg)

    def test_schedule_replay_blocks_failed_schedule_and_reruns_entry(self) -> None:
        runner = _SequenceRunner(["UNSAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=2,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(manifest["cegar_mode"], "schedule_replay")
            self.assertFalse(manifest["certified"])
            # The first closure counterexample creates a blocker. Since this MVP
            # has only one static deterministic schedule, blocking it makes the
            # next ENTRY query unreachable and triggers ordinary fallback.
            self.assertEqual(runner.calls, ["entry_check", "near_wrap", "closure_check", "entry_check"])
            self.assertEqual(len(manifest["blockers"]), 1)
            self.assertEqual(len(manifest["attempts"]), 2)
            second_entry_text = runner.snapshots[-1][1]
            self.assertIn("assume(false);", second_entry_text)
            self.assertIn("entry unreachable or blocked", manifest["diagnostic"])
            self.assertFalse(_manifest_certified_unsafe_data(manifest))

    def test_schedule_replay_writes_manifest_after_entry(self) -> None:
        class StopAfterEntryRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                res = super().run(stage=stage, **kwargs)
                if stage == "near_wrap":
                    raise RuntimeError("stop after entry manifest")
                return res

        runner = StopAfterEntryRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            with self.assertRaisesRegex(RuntimeError, "stop after entry"):
                _run_schedule_replay_cegar_loop(
                    spec_path=out_dir / "x.prop",
                    spec_text="",
                    base_bpl=base_bpl,
                    base_text=_MIN_BPL,
                    out_dir=out_dir,
                    work_dir=out_dir / "work",
                    candidate=_candidate(),
                    partition_ports={},
                    timeout_seconds=1,
                    closure_timeout_cap_seconds=1,
                    resource_limits=False,
                    confirm_unroll=1,
                    max_confirm_unroll=1,
                    max_iters=1,
                    enable_env_completion_refinement=False,
                    runner=runner,
                    toolchain_nowitness=Path("tc.xml"),
                    toolchain_witness=Path("tc_w.xml"),
                    witness_settings=Path("s_w.epf"),
                    closure_toolchain=Path("tc_cl.xml"),
                    settings=Path("s.epf"),
                    closure_settings=Path("s_cl.epf"),
                )

            manifest_path = out_dir / "wraparound.cegis.manifest.json"
            self.assertTrue(manifest_path.exists())
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(manifest["diagnostic"], "entry reached; running near-wrap check")
            self.assertEqual(len(manifest["attempts"]), 1)
            self.assertEqual(manifest["attempts"][0]["entry"]["result_line"], "RESULT: UNSAFE")
            self.assertIsNone(manifest["attempts"][0]["near_wrap"])

    def test_schedule_replay_stop_after_entry(self) -> None:
        runner = _SequenceRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=2,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stop_after="entry",
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(runner.calls, ["entry_check"])
            self.assertEqual(manifest["diagnostic"], "stopped after entry by request")
            self.assertEqual(manifest["attempts"][0]["diagnostic"], "stopped after entry by request")
            self.assertIsNone(manifest["attempts"][0]["near_wrap"])
            self.assertIsNone(manifest["attempts"][0]["closure"])

    def test_schedule_replay_stop_after_near_wrap(self) -> None:
        runner = _SequenceRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=2,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stop_after="near_wrap",
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(runner.calls, ["entry_check", "near_wrap"])
            self.assertEqual(manifest["diagnostic"], "stopped after near_wrap by request")
            self.assertEqual(manifest["attempts"][0]["near_wrap"]["result_line"], "RESULT: UNSAFE")
            self.assertIsNone(manifest["attempts"][0]["closure"])

    def test_schedule_replay_does_not_prefix_retry_plain_entry_safe(self) -> None:
        class InitialSafeRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                if stage == "entry_check":
                    self.calls.append(stage)
                    input_bpl = Path(kwargs["input_bpl"])
                    log_path = kwargs.get("log_path")
                    text = input_bpl.read_text(encoding="utf-8")
                    self.snapshots.append((stage, text))
                    if log_path is not None:
                        Path(log_path).write_text(f"{input_bpl.name}\nRESULT: SAFE\n", encoding="utf-8")
                    return StageRunResult(stage=stage, returncode=0, wall_time_s=0.0, result_line="RESULT: SAFE")
                if stage.startswith("entry_check.prefix."):
                    raise AssertionError("plain cutpoints should not run prefix entry")
                return super().run(stage=stage, **kwargs)

        runner = InitialSafeRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(runner.calls, ["entry_check"])
            self.assertEqual(manifest["diagnostic"], "entry unreachable or blocked; falling back")
            self.assertFalse(manifest["certified"])

    def test_schedule_replay_hard_incomplete_projection_still_runs_near_but_not_closure(self) -> None:
        bpl = """\
var procurator_phase: int;
var procurator_step: int;
var idx: bv32;
var guard_reg: [bv32]bv8;
var guard_reg__last0_value: bv8;
var r: [bv32]bv8;
var r__last_index: bv32;
var r__last_value: bv8;
var r__wrote_any: bool;

procedure main() returns()
  modifies procurator_phase, procurator_step, idx, guard_reg, guard_reg__last0_value,
           r, r__last_index, r__last_value, r__wrote_any;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    // env inject -> s1
  } else if (procurator_phase == 1) {
    // node pass -> s1
    if (guard_reg[idx] == 1bv8) {
      r[idx] := add.bv8(r[idx], 1bv8);
      r__last_index := idx;
      r__last_value := r[idx];
      r__wrote_any := true;
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
  modifies procurator_phase, procurator_step, idx, guard_reg, guard_reg__last0_value,
           r, r__last_index, r__last_value, r__wrote_any;
{
  procurator_step := 0;
  procurator_phase := 0;
  guard_reg__last0_value := 1bv8;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""
        runner = _SequenceRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(bpl, encoding="utf-8")
            cand = WraparoundCandidate(
                pump_reg="r",
                accel_regs=("r",),
                index_value=None,
                index_expr="idx",
                proj_vars=("procurator_phase",),
                cutpoint_cond="(procurator_phase == 0)",
                reason="test",
                step_op="add",
                step_delta=1,
            )

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=bpl,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=cand,
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=2,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(runner.calls, ["entry_check", "near_wrap"])
            attempt = manifest["attempts"][0]
            self.assertFalse(attempt["cfg"]["projection_complete"])
            self.assertIsNone(attempt.get("closure"))
            self.assertFalse(manifest["certified"])
            self.assertFalse(_manifest_certified_unsafe_data(manifest))
            self.assertEqual(
                manifest["diagnostic"],
                "near-wrap bug found but hard dependency projection gap remains; falling back to direct verification",
            )

    def test_schedule_replay_soft_cutpoint_guard_noise_can_certify_after_closure(self) -> None:
        bpl = """\
type Ref;
var procurator_phase: int;
var procurator_step: int;
var s1_inbox_count: int;
var isValid: [Ref]bool;
var s1_hdr.nc_hdr: Ref;
var r: [bv32]bv8;
var r__last0_value: bv8;

procedure main() returns()
  modifies procurator_phase, procurator_step, s1_inbox_count, isValid, s1_hdr.nc_hdr, r, r__last0_value;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    // env inject -> s1
    s1_inbox_count := 1;
  } else if (procurator_phase == 1) {
    // node pass -> s1
    if (s1_inbox_count > 0) {
      s1_inbox_count := s1_inbox_count - 1;
      if (isValid[s1_hdr.nc_hdr]) {
        r[0bv32] := add.bv8(r[0bv32], 1bv8);
        r__last0_value := r[0bv32];
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
  modifies procurator_phase, procurator_step, s1_inbox_count, isValid, s1_hdr.nc_hdr, r, r__last0_value;
{
  procurator_step := 0;
  procurator_phase := 0;
  s1_inbox_count := 0;
  r__last0_value := 0bv8;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""
        runner = _SequenceRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(bpl, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=bpl,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate_with_mailbox_projection(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(runner.calls, ["entry_check", "near_wrap", "closure_check"])
            attempt = manifest["attempts"][0]
            self.assertTrue(attempt["cfg"]["projection_complete"])
            self.assertIn("dependency_projection_unstable_cutpoint_guards=1", attempt["cfg"]["notes"])
            self.assertTrue(attempt["certified"])
            self.assertTrue(manifest["certified"])
            self.assertTrue(_manifest_certified_unsafe_data(manifest))

    def test_schedule_replay_never_certifies_incomplete_projection_even_if_closure_runs(self) -> None:
        # Defensive regression for future branch-splitting changes: certification
        # must depend on `cfg.projection_complete`, not only on a SAFE closure.
        runner = _SequenceRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            cand = WraparoundCandidate(
                pump_reg="r",
                accel_regs=("r",),
                index_value=None,
                index_expr="idx",
                proj_vars=("procurator_phase",),
                cutpoint_cond="(procurator_phase == 0)",
                reason="test",
                step_op="add",
                step_delta=1,
            )

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=cand,
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stop_after="closure",
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertFalse(manifest["attempts"][0]["cfg"]["projection_complete"])
            self.assertFalse(manifest["attempts"][0]["certified"])
            self.assertFalse(manifest["certified"])
            self.assertFalse(_manifest_certified_unsafe_data(manifest))

    def test_schedule_replay_grows_to_distinct_near_wrap_bpl(self) -> None:
        class _NearGrowRunner(_SequenceRunner):
            def __init__(self) -> None:
                super().__init__(["SAFE"])
                self.near_inputs: list[str] = []

            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                if stage == "near_wrap":
                    input_bpl = Path(kwargs["input_bpl"])
                    self.calls.append(stage)
                    self.near_inputs.append(input_bpl.name)
                    result = "UNSAFE" if "unroll2" in input_bpl.name else "SAFE"
                    log_path = kwargs.get("log_path")
                    if log_path is not None:
                        Path(log_path).write_text(f"{input_bpl.name}\nRESULT: {result}\n", encoding="utf-8")
                    return StageRunResult(
                        stage=stage,
                        returncode=0,
                        wall_time_s=0.0,
                        result_line=f"RESULT: {result}",
                    )
                return super().run(stage=stage, **kwargs)

        runner = _NearGrowRunner()
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=2,
                max_confirm_unroll=2,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stop_after="near_wrap",
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(
                runner.near_inputs,
                ["x.schedule.00.near_wrap.unroll1.bpl", "x.schedule.00.near_wrap.unroll2.bpl"],
            )
            self.assertEqual(manifest["attempts"][0]["near_wrap"]["result_line"], "RESULT: UNSAFE")
            self.assertTrue(manifest["attempts"][0]["artifacts"]["confirm_bpl"].endswith("unroll2.bpl"))

    def test_schedule_replay_stops_after_short_unknown(self) -> None:
        class _NearUnknownThenUnsafeRunner(_SequenceRunner):
            def __init__(self) -> None:
                super().__init__(["SAFE"])
                self.near_inputs: list[str] = []

            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                if stage == "near_wrap":
                    input_bpl = Path(kwargs["input_bpl"])
                    self.calls.append(stage)
                    self.near_inputs.append(input_bpl.name)
                    result = "UNSAFE" if "unroll3" in input_bpl.name else "Timeout"
                    log_path = kwargs.get("log_path")
                    if log_path is not None:
                        Path(log_path).write_text(f"{input_bpl.name}\nRESULT: {result}\n", encoding="utf-8")
                    return StageRunResult(
                        stage=stage,
                        returncode=0,
                        wall_time_s=0.0,
                        result_line=f"RESULT: {result}",
                    )
                return super().run(stage=stage, **kwargs)

        runner = _NearUnknownThenUnsafeRunner()
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=3,
                max_confirm_unroll=3,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stop_after="near_wrap",
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(
                runner.near_inputs,
                ["x.schedule.00.near_wrap.unroll1.bpl"],
            )
            self.assertEqual(manifest["attempts"][0]["near_wrap"]["result_line"], "RESULT: Timeout")
            self.assertFalse(manifest["certified"])
            self.assertIn("falling back", manifest["diagnostic"])

    def test_multi_schedule_replay_uses_nowitness_fast_path(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            spec = root / "x.prop"
            out_dir = root / "out"
            spec.write_text("global { assert { true; }; }\n", encoding="utf-8")

            tc_nowit = root / "ReachSafety.xml"
            tc_wit = root / "ReachSafety-Witness.xml"
            tc_closure = root / "ClosureCheck.xml"
            st_nowit = root / "nowitness.epf"
            st_wit = root / "witness.epf"
            st_closure = root / "closure.epf"

            captured: dict[str, object] = {}
            old_compile = wraparound_cegis.compile_spec_file
            old_infer = wraparound_cegis.infer_wraparound_candidates
            old_defaults = wraparound_cegis._default_toolchain_paths
            old_schedule_loop = wraparound_cegis._run_schedule_replay_cegar_loop
            try:
                def fake_compile_spec_file(**kwargs):  # type: ignore[no-untyped-def]
                    Path(kwargs["out"]).write_text(_MIN_BPL, encoding="utf-8")
                    Path(kwargs["work_dir"]).mkdir(parents=True, exist_ok=True)

                def fake_loop(**kwargs):  # type: ignore[no-untyped-def]
                    captured.update(kwargs)
                    mpath = Path(kwargs["out_dir"]) / "wraparound.cegis.manifest.json"
                    mpath.write_text('{"attempts": []}', encoding="utf-8")
                    return mpath

                wraparound_cegis.compile_spec_file = fake_compile_spec_file  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = lambda **_kwargs: [_candidate()]  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = lambda **_kwargs: (  # type: ignore[assignment]
                    tc_nowit,
                    tc_wit,
                    tc_closure,
                    st_nowit,
                    st_wit,
                    st_closure,
                )
                wraparound_cegis._run_schedule_replay_cegar_loop = fake_loop  # type: ignore[assignment]

                manifests = wraparound_cegis.run_wraparound_cegis_multi(
                    spec_path=spec,
                    out_dir=out_dir,
                    p4b_bin=None,
                    ultimate=root / "Ultimate.py",
                    cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
                    max_targets=1,
                    max_iters=1,
                )
            finally:
                wraparound_cegis.compile_spec_file = old_compile  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = old_infer  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = old_defaults  # type: ignore[assignment]
                wraparound_cegis._run_schedule_replay_cegar_loop = old_schedule_loop  # type: ignore[assignment]

            self.assertEqual(len(manifests), 1)
            self.assertEqual(captured["toolchain_nowitness"], tc_nowit)
            self.assertEqual(captured["settings"], st_nowit)
            self.assertEqual(captured["toolchain_witness"], tc_wit)
            self.assertEqual(captured["witness_settings"], st_wit)

    def test_multi_schedule_replay_uses_allinline_stage_settings_with_high_memory(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            spec = root / "x.prop"
            out_dir = root / "out"
            toolchain_dir = root / "dslc" / "toolchain" / "ultimate"
            toolchain_dir.mkdir(parents=True)
            spec.write_text("global { assert { true; }; }\n", encoding="utf-8")

            tc_nowit = root / "ReachSafety.xml"
            tc_wit = root / "ReachSafety-Witness.xml"
            tc_closure = root / "ClosureCheck.xml"
            st_nowit = root / "nowitness.epf"
            st_wit = root / "witness.epf"
            st_closure = toolchain_dir / "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf"
            st_closure.write_text("# allinline\n", encoding="utf-8")

            captured: dict[str, object] = {}
            old_repo_root = wraparound_cegis.repo_root
            old_compile = wraparound_cegis.compile_spec_file
            old_infer = wraparound_cegis.infer_wraparound_candidates
            old_defaults = wraparound_cegis._default_toolchain_paths
            old_schedule_loop = wraparound_cegis._run_schedule_replay_cegar_loop
            try:
                def fake_compile_spec_file(**kwargs):  # type: ignore[no-untyped-def]
                    Path(kwargs["out"]).write_text(_MIN_BPL, encoding="utf-8")
                    Path(kwargs["work_dir"]).mkdir(parents=True, exist_ok=True)

                def fake_loop(**kwargs):  # type: ignore[no-untyped-def]
                    captured.update(kwargs)
                    mpath = Path(kwargs["out_dir"]) / "wraparound.cegis.manifest.json"
                    mpath.write_text('{"attempts": []}', encoding="utf-8")
                    return mpath

                wraparound_cegis.repo_root = lambda: root  # type: ignore[assignment]
                wraparound_cegis.compile_spec_file = fake_compile_spec_file  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = lambda **_kwargs: [_candidate()]  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = lambda **_kwargs: (  # type: ignore[assignment]
                    tc_nowit,
                    tc_wit,
                    tc_closure,
                    st_nowit,
                    st_wit,
                    st_closure,
                )
                wraparound_cegis._run_schedule_replay_cegar_loop = fake_loop  # type: ignore[assignment]

                manifests = wraparound_cegis.run_wraparound_cegis_multi(
                    spec_path=spec,
                    out_dir=out_dir,
                    p4b_bin=None,
                    ultimate=root / "Ultimate.py",
                    ultimate_xmx_gb=8,
                    cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
                    max_targets=1,
                    max_iters=1,
                )
            finally:
                wraparound_cegis.repo_root = old_repo_root  # type: ignore[assignment]
                wraparound_cegis.compile_spec_file = old_compile  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = old_infer  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = old_defaults  # type: ignore[assignment]
                wraparound_cegis._run_schedule_replay_cegar_loop = old_schedule_loop  # type: ignore[assignment]

            self.assertEqual(len(manifests), 1)
            self.assertEqual(captured["toolchain_nowitness"], tc_nowit)
            self.assertEqual(captured["settings"], st_closure)
            self.assertEqual(captured["closure_settings"], st_closure)
            self.assertEqual(captured["toolchain_witness"], tc_wit)
            self.assertEqual(captured["witness_settings"], st_wit)

    def test_multi_schedule_replay_high_memory_prefers_allinline_over_closure_specific_epf(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            spec = root / "x.prop"
            out_dir = root / "out"
            toolchain_dir = root / "dslc" / "toolchain" / "ultimate"
            toolchain_dir.mkdir(parents=True)
            spec.write_text("global { assert { true; }; }\n", encoding="utf-8")

            allinline = toolchain_dir / "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf"
            allinline.write_text("# allinline\n", encoding="utf-8")

            tc_nowit = root / "ReachSafety.xml"
            tc_wit = root / "ReachSafety-Witness.xml"
            tc_closure = root / "ClosureCheck.xml"
            st_nowit = root / "nowitness.epf"
            st_wit = root / "witness.epf"
            # Simulates a restored ClosureCheck-32bit-GemCutter-ALL-witness.epf:
            # high-memory schedule replay must still pick the all-inline profile.
            st_closure_specific = root / "ClosureCheck-32bit-GemCutter-ALL-witness.epf"

            captured: dict[str, object] = {}
            old_repo_root = wraparound_cegis.repo_root
            old_compile = wraparound_cegis.compile_spec_file
            old_infer = wraparound_cegis.infer_wraparound_candidates
            old_defaults = wraparound_cegis._default_toolchain_paths
            old_schedule_loop = wraparound_cegis._run_schedule_replay_cegar_loop
            try:
                def fake_compile_spec_file(**kwargs):  # type: ignore[no-untyped-def]
                    Path(kwargs["out"]).write_text(_MIN_BPL, encoding="utf-8")
                    Path(kwargs["work_dir"]).mkdir(parents=True, exist_ok=True)

                def fake_loop(**kwargs):  # type: ignore[no-untyped-def]
                    captured.update(kwargs)
                    mpath = Path(kwargs["out_dir"]) / "wraparound.cegis.manifest.json"
                    mpath.write_text('{"attempts": []}', encoding="utf-8")
                    return mpath

                wraparound_cegis.repo_root = lambda: root  # type: ignore[assignment]
                wraparound_cegis.compile_spec_file = fake_compile_spec_file  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = lambda **_kwargs: [_candidate()]  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = lambda **_kwargs: (  # type: ignore[assignment]
                    tc_nowit,
                    tc_wit,
                    tc_closure,
                    st_nowit,
                    st_wit,
                    st_closure_specific,
                )
                wraparound_cegis._run_schedule_replay_cegar_loop = fake_loop  # type: ignore[assignment]

                manifests = wraparound_cegis.run_wraparound_cegis_multi(
                    spec_path=spec,
                    out_dir=out_dir,
                    p4b_bin=None,
                    ultimate=root / "Ultimate.py",
                    ultimate_xmx_gb=8,
                    cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
                    max_targets=1,
                    max_iters=1,
                )
            finally:
                wraparound_cegis.repo_root = old_repo_root  # type: ignore[assignment]
                wraparound_cegis.compile_spec_file = old_compile  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = old_infer  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = old_defaults  # type: ignore[assignment]
                wraparound_cegis._run_schedule_replay_cegar_loop = old_schedule_loop  # type: ignore[assignment]

            self.assertEqual(len(manifests), 1)
            self.assertEqual(captured["settings"], allinline.resolve())
            self.assertEqual(captured["closure_settings"], allinline.resolve())

    def test_multi_legacy_uses_nowitness_stage_toolchain(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            spec = root / "x.prop"
            out_dir = root / "out"
            spec.write_text("global { assert { true; }; }\n", encoding="utf-8")

            tc_nowit = root / "ReachSafety.xml"
            tc_wit = root / "ReachSafety-Witness.xml"
            tc_closure = root / "ClosureCheck.xml"
            st_nowit = root / "nowitness.epf"
            st_wit = root / "witness.epf"
            st_closure = root / "closure.epf"

            captured: dict[str, object] = {}
            old_compile = wraparound_cegis.compile_spec_file
            old_infer = wraparound_cegis.infer_wraparound_candidates
            old_defaults = wraparound_cegis._default_toolchain_paths
            old_legacy_loop = wraparound_cegis._run_cegis_loop
            try:
                def fake_compile_spec_file(**kwargs):  # type: ignore[no-untyped-def]
                    Path(kwargs["out"]).write_text(_MIN_BPL, encoding="utf-8")
                    Path(kwargs["work_dir"]).mkdir(parents=True, exist_ok=True)

                def fake_loop(**kwargs):  # type: ignore[no-untyped-def]
                    captured.update(kwargs)
                    mpath = Path(kwargs["out_dir"]) / "wraparound.cegis.manifest.json"
                    mpath.write_text('{"attempts": []}', encoding="utf-8")
                    return mpath

                wraparound_cegis.compile_spec_file = fake_compile_spec_file  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = lambda **_kwargs: [_candidate()]  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = lambda **_kwargs: (  # type: ignore[assignment]
                    tc_nowit,
                    tc_wit,
                    tc_closure,
                    st_nowit,
                    st_wit,
                    st_closure,
                )
                wraparound_cegis._run_cegis_loop = fake_loop  # type: ignore[assignment]

                manifests = wraparound_cegis.run_wraparound_cegis_multi(
                    spec_path=spec,
                    out_dir=out_dir,
                    p4b_bin=None,
                    ultimate=root / "Ultimate.py",
                    cegar_mode=WraparoundCegarMode.LEGACY_CLOSURE_ASSUMES.value,
                    max_targets=1,
                    max_iters=1,
                )
            finally:
                wraparound_cegis.compile_spec_file = old_compile  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = old_infer  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = old_defaults  # type: ignore[assignment]
                wraparound_cegis._run_cegis_loop = old_legacy_loop  # type: ignore[assignment]

            self.assertEqual(len(manifests), 1)
            self.assertEqual(captured["toolchain_nowitness"], tc_nowit)
            self.assertEqual(captured["settings"], st_nowit)
            self.assertEqual(captured["toolchain_witness"], tc_wit)
            self.assertEqual(captured["witness_settings"], st_wit)

    def test_schedule_replay_seeds_closure_assumes_from_near_wrap_witness(self) -> None:
        class WitnessRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                if stage.startswith("confirm.witness."):
                    input_bpl = Path(kwargs["input_bpl"])
                    witness = input_bpl.parent / f"{input_bpl.name}-witness.graphml"
                    witness.write_text(
                        """<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <graph edgedefault="directed">
    <node id="N0">
      <data key="assumption">s1_hdr.nc_hdr.op == 12</data>
    </node>
  </graph>
</graphml>
""",
                        encoding="utf-8",
                    )
                return super().run(stage=stage, **kwargs)

        runner = WitnessRunner(["Timeout", "SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")
            witness_toolchain = out_dir / "tc_w.xml"
            witness_toolchain.write_text("<toolchain>ultimate.witnessprinter</toolchain>", encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=2,
                enable_env_completion_refinement=True,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=witness_toolchain,
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(
                runner.calls,
                ["entry_check", "near_wrap", "closure_check", "confirm.witness.unroll1", "closure_check"],
            )
            first, attempt = manifest["attempts"]
            self.assertEqual(first["diagnostic"], "closure unknown; seeded witness replay conditions for next closure")
            self.assertIn("s1_hdr.nc_hdr.op == 12bv8", attempt["cfg"]["closure_assumes"])
            self.assertTrue(any(n == "closure_seed_assumes=1" for n in attempt["cfg"]["notes"]))
            projection = attempt["schedule"]["projection"]
            self.assertFalse(
                any(
                    p["lhs"] == "s1_hdr.nc_hdr.op"
                    for p in projection
                )
            )
            conditions = attempt["schedule"]["conditions"]
            self.assertTrue(
                any(
                    p["lhs"] == "s1_hdr.nc_hdr.op"
                    and p["rhs"] == "12bv8"
                    and p["source"] == "near_wrap_witness"
                    for p in conditions
                )
            )
            self.assertEqual(attempt["schedule"]["actors"], ["env", "s1"])
            closure_text = [text for stage, text in runner.snapshots if stage == "closure_check"][-1]
            self.assertIn("assume(s1_hdr.nc_hdr.op == 12bv8);", closure_text)
            closure_call = closure_text.split("call __wraparound_closure_assert_all(", 1)[1]
            self.assertNotIn("s1_hdr.nc_hdr.op == 12bv8", closure_call)
            near_text = next(text for stage, text in runner.snapshots if stage == "near_wrap")
            self.assertNotIn("assume(s1_hdr.nc_hdr.op == 12bv8);", near_text)
            self.assertFalse(manifest["certified"])
            self.assertFalse(_manifest_certified_unsafe_data(manifest))
            self.assertEqual(attempt["diagnostic"], "closure safe under witness replay conditions only; falling back")

    def test_schedule_replay_skips_diagnostic_witness_when_refinement_disabled(self) -> None:
        class WitnessRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                if stage.startswith("confirm.witness."):
                    raise AssertionError("diagnostic witness should be skipped")
                return super().run(stage=stage, **kwargs)

        runner = WitnessRunner(["Timeout"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")
            witness_toolchain = out_dir / "tc_w.xml"
            witness_toolchain.write_text("<toolchain>ultimate.witnessprinter</toolchain>", encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=3,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=witness_toolchain,
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(runner.calls, ["entry_check", "near_wrap", "closure_check"])
            self.assertEqual(len(manifest["attempts"]), 1)
            self.assertEqual(manifest["diagnostic"], "closure unknown/timeout; falling back")
            self.assertEqual(manifest["attempts"][0]["schedule"]["conditions"], [])
            self.assertFalse(_manifest_certified_unsafe_data(manifest))

    def test_schedule_replay_does_not_reuse_stale_near_wrap_witness(self) -> None:
        class NoWitnessRunner(_SequenceRunner):
            pass

        runner = NoWitnessRunner(["Timeout"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")
            witness_toolchain = out_dir / "tc_w.xml"
            witness_toolchain.write_text("<toolchain>ultimate.witnessprinter</toolchain>", encoding="utf-8")

            stale = out_dir / "stale.bpl-witness.graphml"
            stale.write_text(
                """<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <graph edgedefault="directed">
    <node id="N0">
      <data key="assumption">s1_hdr.nc_hdr.op == 12</data>
    </node>
  </graph>
</graphml>
""",
                encoding="utf-8",
            )

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=2,
                enable_env_completion_refinement=True,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=witness_toolchain,
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(runner.calls, ["entry_check", "near_wrap", "closure_check", "confirm.witness.unroll1"])
            self.assertEqual(len(manifest["attempts"]), 1)
            self.assertEqual(manifest["diagnostic"], "closure unknown/timeout; falling back")
            self.assertEqual(manifest["attempts"][0]["cfg"]["closure_assumes"], [])
            self.assertEqual(manifest["attempts"][0]["schedule"]["conditions"], [])
            self.assertFalse(_manifest_certified_unsafe_data(manifest))

    def test_schedule_manifest_projection_matches_closure_snapshot_vars(self) -> None:
        runner = _SequenceRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate_with_unavailable_projection(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            projection_lhs = [p["lhs"] for p in manifest["attempts"][0]["schedule"]["projection"]]
            self.assertEqual(projection_lhs, ["procurator_phase"])
            self.assertTrue(
                any(
                    n.startswith("dependency_projection_live_deps=")
                    for n in manifest["attempts"][0]["cfg"]["notes"]
                )
            )
            closure_text = next(text for stage, text in runner.snapshots if stage == "closure_check")
            self.assertIn("var wrap_closure_snap_procurator_phase: int;", closure_text)
            self.assertNotIn("wrap_closure_snap_missing_projection", closure_text)
            self.assertNotIn("wrap_closure_snap_r", closure_text)

    def test_projection_conditions_parse_numeric_dotted_fields(self) -> None:
        preds = projection_predicates_from_assumes(
            ["h1_hdr.overlay.5.valid == false", "assume(s1_find_index.hit == true);"],
            source="near_wrap_witness",
        )
        self.assertEqual([p.lhs for p in preds], ["h1_hdr.overlay.5.valid", "s1_find_index.hit"])

    def test_static_schedule_rejects_unmapped_phase_actor(self) -> None:
        bpl = _MIN_BPL.replace("// env inject -> s1", "// missing actor comment")
        sched = infer_static_deterministic_schedule(
            base_bpl_text=bpl,
            candidate=_candidate(),
            base_bpl_sha256=sha256_text(bpl),
        )
        self.assertIsNone(sched)

if __name__ == "__main__":
    unittest.main()
