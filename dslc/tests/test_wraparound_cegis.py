from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.workflows.wraparound_cegis import StageRunResult, _run_cegis_loop


class _FakeRunner:
    def __init__(self) -> None:
        self.calls: list[tuple[str, str]] = []

    def run(
        self,
        *,
        stage: str,
        input_bpl: Path,
        log_path: Path,
        ultimate_home: Path,
        toolchain: Path,
        settings: Path,
        timeout_seconds: int,
        resource_limits: bool,
    ) -> StageRunResult:
        self.calls.append((stage, input_bpl.name))

        # The loop should always require entry_check UNSAFE (reachability).
        if stage == "entry_check":
            return StageRunResult(
                stage=stage,
                returncode=0,
                wall_time_s=0.01,
                result_line="RESULT: Ultimate proved your program to be incorrect!",
            )

        # For the legacy ordering (ENTRY -> CLOSURE -> CONFIRM), we do not refine on
        # CLOSURE UNKNOWN/timeout because we have no concrete CONFIRM witness to seed
        # refinement. Therefore, this fake runner keeps CLOSURE SAFE so CONFIRM runs.
        if stage == "closure_check":
            return StageRunResult(
                stage=stage,
                returncode=0,
                wall_time_s=0.01,
                result_line="RESULT: Ultimate proved your program to be correct!",
            )

        if stage == "confirm":
            return StageRunResult(
                stage=stage,
                returncode=0,
                wall_time_s=0.01,
                result_line="RESULT: Ultimate proved your program to be incorrect!",
            )

        raise AssertionError(f"unexpected stage: {stage}")


class TestWraparoundCegis(unittest.TestCase):
    def test_stage_run_result_timeout_detects_result_line(self) -> None:
        r = StageRunResult(stage="closure_check", returncode=0, wall_time_s=1.0, result_line="RESULT: ... Timeout")
        self.assertTrue(r.timed_out)

    def test_confirm_retry_with_noz3timeout_settings_on_timeout(self) -> None:
        """
        If CONFIRM returns UNKNOWN due to an external timeout (rc=124), CEGIS should
        retry once with a "no z3 timeout" settings profile when provided.
        """

        class _Runner:
            def __init__(self) -> None:
                self.calls: list[tuple[str, str, str]] = []

            def run(
                self,
                *,
                stage: str,
                input_bpl: Path,
                log_path: Path,
                ultimate_home: Path,
                toolchain: Path,
                settings: Path,
                timeout_seconds: int,
                resource_limits: bool,
            ) -> StageRunResult:
                self.calls.append((stage, input_bpl.name, settings.name))
                if stage == "entry_check":
                    return StageRunResult(
                        stage=stage,
                        returncode=0,
                        wall_time_s=0.01,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    )
                if stage == "confirm":
                    if settings.name == "st.epf":
                        # Simulate an external timeout wrapper.
                        return StageRunResult(
                            stage=stage,
                            returncode=124,
                            wall_time_s=0.01,
                            result_line="RESULT: Ultimate could not prove your program: Timeout",
                        )
                    return StageRunResult(
                        stage=stage,
                        returncode=0,
                        wall_time_s=0.01,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    )
                if stage.startswith("confirm.witness"):
                    # Witness-seeding run after CONFIRM becomes UNSAFE.
                    return StageRunResult(
                        stage=stage,
                        returncode=0,
                        wall_time_s=0.01,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    )
                if stage == "closure_check":
                    return StageRunResult(
                        stage=stage,
                        returncode=0,
                        wall_time_s=0.01,
                        result_line="RESULT: Ultimate proved your program to be correct!",
                    )
                raise AssertionError(f"unexpected stage: {stage}")

        base_text = """
var procurator_step: int;
var procurator_phase: int;
var s1_sequence_reg:[bv32]bv16;

procedure main() returns()
  modifies procurator_phase, s1_sequence_reg;
{
  if (procurator_phase == 0) {
    s1_sequence_reg[0bv32] := add.bv16(s1_sequence_reg[0bv32], 1bv16);
  }
  if (procurator_phase == 4) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, procurator_step, s1_sequence_reg;
{
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""

        cand = WraparoundCandidate(
            pump_reg="s1_sequence_reg",
            accel_regs=("s1_sequence_reg",),
            index_value=0,
            index_expr=None,
            proj_vars=("procurator_phase",),
            cutpoint_cond="(procurator_phase == 0)",
            reason="test",
            step_op="add",
            step_delta=1,
        )

        runner = _Runner()
        with tempfile.TemporaryDirectory(prefix="procurator-cegis-test-") as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(base_text, encoding="utf-8")

            manifest_path = _run_cegis_loop(
                spec_path=Path("dummy.prop"),
                spec_text="",
                base_bpl=base_bpl,
                base_text=base_text,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=cand,
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=3,
                max_confirm_unroll=3,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=out_dir / "tc.xml",
                toolchain_witness=out_dir / "tc_w.xml",
                witness_settings=out_dir / "st_w.epf",
                closure_toolchain=out_dir / "tc_cl.xml",
                settings=out_dir / "st.epf",
                closure_settings=out_dir / "st_cl.epf",
                confirm_settings_fallback=out_dir / "st_noz3.epf",
                stage_order="entry_confirm_closure",
            )
            self.assertTrue(manifest_path.exists())

            # We should see two confirm calls: first with st.epf, then with st_noz3.epf.
            confirms = [c for c in runner.calls if c[0] == "confirm"]
            self.assertGreaterEqual(len(confirms), 2)
            self.assertEqual(confirms[0][2], "st.epf")
            self.assertEqual(confirms[1][2], "st_noz3.epf")

    def test_cegis_iterates_until_closure_safe_then_runs_confirm(self) -> None:
        base_text = """
var procurator_step: int;
var procurator_phase: int;
var s1_inbox_count: int;
var s2_inbox_count: int;
var s1_sequence_reg:[bv32]bv16;
var s2_sequence_reg:[bv32]bv16;

procedure {:inline 1} s1_sequence_reg.write(i:bv32, v:bv16)
  modifies s1_sequence_reg;
{
  s1_sequence_reg[i] := v;
}

procedure {:inline 1} s2_sequence_reg.write(i:bv32, v:bv16)
  modifies s2_sequence_reg;
{
  s2_sequence_reg[i] := v;
}

procedure main() returns()
  modifies procurator_phase, s1_sequence_reg, s2_sequence_reg;
{
  if (procurator_phase == 0) {
    call s1_sequence_reg.write(0bv32, add.bv16(s1_sequence_reg[0bv32], 1bv16));
    call s2_sequence_reg.write(0bv32, add.bv16(s2_sequence_reg[0bv32], 1bv16));
  }
  if (procurator_phase == 4) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, procurator_step, s1_sequence_reg, s2_sequence_reg, s1_inbox_count, s2_inbox_count;
{
  s1_inbox_count := 0;
  s2_inbox_count := 0;
  procurator_step := 0;
  procurator_phase := 0;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""

        cand = WraparoundCandidate(
            pump_reg="s1_sequence_reg",
            accel_regs=("s1_sequence_reg", "s2_sequence_reg"),
            index_value=0,
            index_expr=None,
            proj_vars=("procurator_phase", "s1_inbox_count", "s2_inbox_count"),
            cutpoint_cond="(procurator_phase == 0)",
            reason="test",
            step_op="add",
            step_delta=1,
        )

        runner = _FakeRunner()
        with tempfile.TemporaryDirectory(prefix="procurator-cegis-test-") as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(base_text, encoding="utf-8")

            manifest_path = _run_cegis_loop(
                spec_path=Path("dummy.prop"),
                spec_text="",
                base_bpl=base_bpl,
                base_text=base_text,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=cand,
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=3,
                max_confirm_unroll=3,
                max_iters=3,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=out_dir / "tc.xml",
                toolchain_witness=out_dir / "tc_w.xml",
                witness_settings=out_dir / "st_w.epf",
                closure_toolchain=out_dir / "tc_cl.xml",
                settings=out_dir / "st.epf",
                closure_settings=out_dir / "st_cl.epf",
                stage_order="entry_closure_confirm",
            )

            self.assertTrue(manifest_path.exists())
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(manifest["spec"], "dummy.prop")
            # Candidate details are written for reproducibility (paper plots / reruns).
            self.assertIn("candidate", manifest)
            self.assertEqual(manifest["candidate"]["pump_reg"], "s1_sequence_reg")
            self.assertGreaterEqual(len(manifest["attempts"]), 1)

            # Confirm is run only after closure becomes SAFE.
            stages = [c[0] for c in runner.calls]
            self.assertIn("confirm", stages)
            # Legacy ordering does not iterate/refine; it runs a single closure attempt.
            self.assertEqual(stages.count("entry_check"), 1)
            self.assertEqual(stages.count("closure_check"), 1)

    def test_cegis_stops_on_closure_unknown_instead_of_refining(self) -> None:
        """
        Regression test:

        We do not refine on CLOSURE UNKNOWN/timeout because there is no counterexample
        evidence to guide synthesis. In particular, we must NOT keep looping and
        heuristically shrink the projection; instead, stop early and let the caller
        increase timeouts or optimize encodings case-by-case.
        """

        base_text = """
var procurator_step: int;
var procurator_phase: int;
var h1_inbox_count: int;
var s1_inbox_count: int;
var s2_inbox_count: int;
var s1_sequence_reg:[bv32]bv16;
var s2_sequence_reg:[bv32]bv16;

procedure main() returns()
  modifies procurator_phase, s1_sequence_reg, s2_sequence_reg;
{
  if (procurator_phase == 0) {
    // Monotone step (dummy)
    s1_sequence_reg[0bv32] := add.bv16(s1_sequence_reg[0bv32], 1bv16);
    s2_sequence_reg[0bv32] := add.bv16(s2_sequence_reg[0bv32], 1bv16);
  }
  // Make the phase update pattern look like the deterministic scheduler harness.
  if (procurator_phase == 4) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, procurator_step, s1_sequence_reg, s2_sequence_reg, h1_inbox_count, s1_inbox_count, s2_inbox_count;
{
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""

        cand = WraparoundCandidate(
            pump_reg="s1_sequence_reg",
            accel_regs=("s1_sequence_reg", "s2_sequence_reg"),
            index_value=0,
            index_expr=None,
            proj_vars=("h1_inbox_count", "procurator_phase", "s1_inbox_count", "s2_inbox_count"),
            cutpoint_cond=None,
            reason="test",
            step_op="add",
            step_delta=1,
        )

        class Runner:
            def __init__(self) -> None:
                self.calls: list[tuple[str, str]] = []

            def run(
                self,
                *,
                stage: str,
                input_bpl: Path,
                log_path: Path,
                ultimate_home: Path,
                toolchain: Path,
                settings: Path,
                timeout_seconds: int,
                resource_limits: bool,
            ) -> StageRunResult:
                self.calls.append((stage, input_bpl.name))

                if stage == "entry_check":
                    return StageRunResult(
                        stage=stage,
                        returncode=0,
                        wall_time_s=0.01,
                        result_line="RESULT: UNSAFE",
                    )

                if stage == "confirm":
                    return StageRunResult(
                        stage=stage,
                        returncode=0,
                        wall_time_s=0.01,
                        result_line="RESULT: UNSAFE",
                    )

                if stage.startswith("confirm.witness."):
                    return StageRunResult(
                        stage=stage,
                        returncode=0,
                        wall_time_s=0.01,
                        result_line="RESULT: UNSAFE",
                    )

                if stage == "closure_check":
                    if ".cegis.00." in input_bpl.name:
                        return StageRunResult(
                            stage=stage,
                            returncode=0,
                            wall_time_s=0.01,
                            result_line="RESULT: UNKNOWN",
                        )
                    return StageRunResult(
                        stage=stage,
                        returncode=0,
                        wall_time_s=0.01,
                        result_line="RESULT: SAFE",
                    )

                raise AssertionError(f"unexpected stage: {stage}")

        runner = Runner()
        with tempfile.TemporaryDirectory(prefix="procurator-cegis-test-") as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(base_text, encoding="utf-8")

            dummy_graphml = out_dir / "dummy.graphml"
            dummy_graphml.write_text("<graphml></graphml>", encoding="utf-8")

            with mock.patch("dslc.workflows.wraparound_cegis.find_latest_graphml_witness", return_value=dummy_graphml), mock.patch(
                "dslc.workflows.wraparound_cegis.extract_assumptions_from_graphml", return_value=[]
            ), mock.patch(
                "dslc.workflows.wraparound_cegis.synthesize_boogie_assumes", return_value=["(h1_inbox_count == 0)"]
            ):
                manifest_path = _run_cegis_loop(
                    spec_path=Path("dummy.prop"),
                    spec_text="",
                    base_bpl=base_bpl,
                    base_text=base_text,
                    out_dir=out_dir,
                    work_dir=out_dir / "work",
                    candidate=cand,
                    partition_ports={},
                    timeout_seconds=1,
                    closure_timeout_cap_seconds=1,
                    resource_limits=False,
                    confirm_unroll=3,
                    max_confirm_unroll=3,
                    max_iters=3,
                    enable_env_completion_refinement=False,
                    runner=runner,
                    toolchain_nowitness=out_dir / "tc.xml",
                    toolchain_witness=out_dir / "tc_w.xml",
                    witness_settings=out_dir / "st_w.epf",
                    closure_toolchain=out_dir / "tc_cl.xml",
                    settings=out_dir / "st.epf",
                    closure_settings=out_dir / "st_cl.epf",
                    stage_order="entry_confirm_closure",
                )

            self.assertTrue(manifest_path.exists())

            # We stop on UNKNOWN: no second closure attempt is produced.
            closure_1 = out_dir / "dummy.cegis.01.closure_check.bpl"
            self.assertFalse(closure_1.exists())
