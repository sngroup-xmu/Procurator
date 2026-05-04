from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.workflows.wraparound_cegis import StageRunResult, _confirm_unroll_schedule, _run_cegis_loop


class _FakeRunner:
    def __init__(self, results: dict[str, StageRunResult]) -> None:
        self._results = results
        self.calls: list[str] = []

    def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
        self.calls.append(stage)
        return self._results[stage]


class TestWraparoundConfirmUnrollSchedule(unittest.TestCase):
    def test_confirm_unroll_schedule_starts_from_minimal_suffix(self) -> None:
        # Regression: ETC/TNA near-wrap becomes harder with an unnecessary
        # second suffix packet.  Try the shortest confirm suffix before growing.
        self.assertEqual(_confirm_unroll_schedule(base=3, max_unroll=5), [1, 2, 3, 4, 5])
        self.assertEqual(_confirm_unroll_schedule(base=3, max_unroll=12), [1, 2, 3, 4, 5, 7, 12])
        self.assertEqual(_confirm_unroll_schedule(base=2, max_unroll=2), [1, 2])


_MIN_BPL = """\
var procurator_phase: int;
var procurator_step: int;
var r: [bv32]bv8;
var r__last0_value: bv8;

procedure main() returns()
{
  // Deterministic scheduler pattern: period = 1
  if (procurator_phase == 0) {
    procurator_phase := 0;
  }
  return;
}

procedure mainProcedure() returns()
{
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""


class WraparoundCegisOrderTests(unittest.TestCase):
    def test_entry_confirm_closure_skips_closure_if_confirm_not_unsafe(self) -> None:
        cand = WraparoundCandidate(
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

        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            runner = _FakeRunner(
                results={
                    "entry_check": StageRunResult(
                        stage="entry_check",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    ),
                    "confirm": StageRunResult(
                        stage="confirm",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be correct!",
                    ),
                }
            )

            _run_cegis_loop(
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
                stage_order="entry_confirm_closure",
            )

            self.assertEqual(runner.calls, ["entry_check", "confirm"])

            mf = json.loads((out_dir / "wraparound.cegis.manifest.json").read_text(encoding="utf-8"))
            # We may write incremental attempts (e.g., an ENTRY-only record for reproducibility).
            self.assertTrue(
                any(
                    (a.get("confirm") is not None)
                    and (a.get("closure") is None)
                    and ("proved your program to be correct" in str(a["confirm"].get("result_line", "")).lower())
                    for a in mf["attempts"]
                )
            )

    def test_entry_closure_confirm_runs_confirm_only_after_safe_closure(self) -> None:
        cand = WraparoundCandidate(
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

        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            runner = _FakeRunner(
                results={
                    "entry_check": StageRunResult(
                        stage="entry_check",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    ),
                    "closure_check": StageRunResult(
                        stage="closure_check",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be correct!",
                    ),
                    "confirm": StageRunResult(
                        stage="confirm",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    ),
                }
            )

            _run_cegis_loop(
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
                stage_order="entry_closure_confirm",
            )

            self.assertEqual(runner.calls, ["entry_check", "closure_check", "confirm"])

            mf = json.loads((out_dir / "wraparound.cegis.manifest.json").read_text(encoding="utf-8"))
            self.assertTrue(
                any(
                    (a.get("confirm") is not None)
                    and (a.get("closure") is not None)
                    and ("proved your program to be correct" in str(a["closure"].get("result_line", "")).lower())
                    for a in mf["attempts"]
                )
            )

    def test_entry_confirm_closure_records_confirm_before_closure(self) -> None:
        """
        Regression: if CONFIRM is UNSAFE and CLOSURE is slow/timeout, we should still
        record the CONFIRM UNSAFE outcome in the manifest before running CLOSURE.
        """

        cand = WraparoundCandidate(
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

        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            runner = _FakeRunner(
                results={
                    "entry_check": StageRunResult(
                        stage="entry_check",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    ),
                    "confirm": StageRunResult(
                        stage="confirm",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    ),
                    # After CONFIRM is UNSAFE we re-run it once with witness printing to seed closure.
                    "confirm.witness.unroll1": StageRunResult(
                        stage="confirm.witness.unroll1",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    ),
                    "closure_check": StageRunResult(
                        stage="closure_check",
                        returncode=124,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate could not prove your program: Timeout",
                    ),
                }
            )

            _run_cegis_loop(
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
                stage_order="entry_confirm_closure",
            )

            # CONFIRM is existential; we do not run witnessprinter unless the closure proof
            # succeeded (to emit a final witness) or closure produced evidence for refinement.
            self.assertEqual(runner.calls, ["entry_check", "confirm", "closure_check"])

            mf = json.loads((out_dir / "wraparound.cegis.manifest.json").read_text(encoding="utf-8"))
            self.assertTrue(
                any(
                    (a.get("confirm") is not None)
                    and (a.get("closure") is None)
                    and ("proved your program to be incorrect" in str(a["confirm"].get("result_line", "")).lower())
                    for a in mf["attempts"]
                )
            )

    def test_entry_confirm_closure_tries_increasing_unroll(self) -> None:
        cand = WraparoundCandidate(
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

        class _AdaptiveRunner:
            def __init__(self) -> None:
                self.calls: list[str] = []

            def run(self, *, stage: str, input_bpl: Path, **kwargs):  # type: ignore[no-untyped-def]
                self.calls.append(f"{stage}:{input_bpl.name}")
                if stage == "entry_check":
                    return StageRunResult(
                        stage="entry_check",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    )
                if stage == "confirm":
                    # Pretend the bug needs unroll>=3.
                    if "unroll3" in input_bpl.name or "unroll4" in input_bpl.name:
                        return StageRunResult(
                            stage="confirm",
                            returncode=0,
                            wall_time_s=0.0,
                            result_line="RESULT: Ultimate proved your program to be incorrect!",
                        )
                    return StageRunResult(
                        stage="confirm",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be correct!",
                    )
                if stage.startswith("confirm.witness"):
                    # No-op witness stage for seeding closure. The unit test does not
                    # depend on actual witness contents.
                    return StageRunResult(
                        stage=stage,
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    )
                if stage == "closure_check":
                    return StageRunResult(
                        stage="closure_check",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be correct!",
                    )
                raise AssertionError(stage)

        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            runner = _AdaptiveRunner()
            _run_cegis_loop(
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
                max_confirm_unroll=4,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stage_order="entry_confirm_closure",
            )

            # Should attempt unroll1, then unroll2, then succeed at unroll3 and run closure.
            self.assertIn("confirm:x.cegis.00.confirm.unroll1.bpl".replace("x.", "x."), runner.calls[1])
            self.assertTrue(any("confirm.unroll2" in c for c in runner.calls))
            self.assertTrue(any("confirm.unroll3" in c for c in runner.calls))
            self.assertTrue(any(c.startswith("closure_check:") for c in runner.calls))

    def test_cegis_adds_extra_assumes_from_witness_when_closure_fails(self) -> None:
        cand = WraparoundCandidate(
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

        class _AssumeSensitiveRunner:
            def __init__(self) -> None:
                self.calls: list[str] = []

            def run(self, *, stage: str, input_bpl: Path, log_path: Path, **kwargs):  # type: ignore[no-untyped-def]
                self.calls.append(f"{stage}:{input_bpl.name}")
                if stage == "entry_check":
                    return StageRunResult(
                        stage="entry_check",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    )
                if stage == "confirm" or stage.startswith("confirm.witness"):
                    # Always find a bug so that closure is attempted.
                    # Also, create a minimal witness graphml in the default witness dir.
                    wdir = log_path.parent / "witness"
                    wdir.mkdir(parents=True, exist_ok=True)
                    (wdir / "witness.graphml").write_text(
                        """<?xml version="1.0" encoding="UTF-8"?>\n"
                        "<graphml xmlns='http://graphml.graphdrawing.org/xmlns'>\n"
                        "  <graph edgedefault='directed'>\n"
                        "    <node id='N0'>\n"
                        "      <data key='assumption'>dsl_pump_mode = true</data>\n"
                        "    </node>\n"
                        "  </graph>\n"
                        "</graphml>\n""",
                        encoding="utf-8",
                    )
                    return StageRunResult(
                        stage="confirm",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    )
                if stage.startswith("closure_check.witness"):
                    # Provide a closure counterexample witness so diff-based refinement can run.
                    wdir = log_path.parent / "witness"
                    wdir.mkdir(parents=True, exist_ok=True)
                    (wdir / "witness.graphml").write_text(
                        """<?xml version="1.0" encoding="UTF-8"?>\n"
                        "<graphml xmlns='http://graphml.graphdrawing.org/xmlns'>\n"
                        "  <graph edgedefault='directed'>\n"
                        "    <node id='N0'>\n"
                        "      <data key='assumption'>dsl_pump_mode = false</data>\n"
                        "    </node>\n"
                        "  </graph>\n"
                        "</graphml>\n""",
                        encoding="utf-8",
                    )
                    return StageRunResult(
                        stage=stage,
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    )
                if stage == "closure_check":
                    txt = input_bpl.read_text(encoding="utf-8", errors="replace")
                    # Becomes SAFE only after CEGIS injected the witness-derived assume.
                    if "dsl_pump_mode" in txt and "assume(" in txt:
                        return StageRunResult(
                            stage="closure_check",
                            returncode=0,
                            wall_time_s=0.0,
                            result_line="RESULT: Ultimate proved your program to be correct!",
                        )
                    return StageRunResult(
                        stage="closure_check",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    )
                raise AssertionError(stage)

        min_bpl = _MIN_BPL + "var dsl_pump_mode: bool;\n"

        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(min_bpl, encoding="utf-8")

            runner = _AssumeSensitiveRunner()
            _run_cegis_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=min_bpl,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=cand,
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
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stage_order="entry_confirm_closure",
            )

            # Closure should be attempted twice: first UNSAFE, then SAFE after assume injection.
            self.assertTrue(any(c.startswith("closure_check:") for c in runner.calls))
            mf = json.loads((out_dir / "wraparound.cegis.manifest.json").read_text(encoding="utf-8"))
            self.assertGreaterEqual(len(mf["attempts"]), 2)

    def test_entry_confirm_closure_does_not_rerun_confirm_after_refinement(self) -> None:
        """
        Regression: once CONFIRM is UNSAFE, refinement should only re-run CLOSURE.

        CONFIRM is existential bug finding; CEGIS refinement is for the CLOSURE proof.
        """

        cand = WraparoundCandidate(
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

        class _NoRerunConfirmRunner:
            def __init__(self) -> None:
                self.calls: list[str] = []
                self.entry_calls = 0
                self.confirm_calls = 0

            def run(self, *, stage: str, input_bpl: Path, log_path: Path, **kwargs):  # type: ignore[no-untyped-def]
                self.calls.append(stage)
                if stage == "entry_check":
                    self.entry_calls += 1
                    return StageRunResult(
                        stage="entry_check",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    )
                if stage == "confirm":
                    self.confirm_calls += 1
                    return StageRunResult(
                        stage="confirm",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    )
                if stage.startswith("confirm.witness"):
                    # Provide a witness that pins dsl_pump_mode so closure can be certified.
                    wdir = log_path.parent / "witness"
                    wdir.mkdir(parents=True, exist_ok=True)
                    (wdir / "witness.graphml").write_text(
                        """<?xml version="1.0" encoding="UTF-8"?>\n"
                        "<graphml xmlns='http://graphml.graphdrawing.org/xmlns'>\n"
                        "  <graph edgedefault='directed'>\n"
                        "    <node id='N0'>\n"
                        "      <data key='assumption'>dsl_pump_mode = true</data>\n"
                        "    </node>\n"
                        "  </graph>\n"
                        "</graphml>\n""",
                        encoding="utf-8",
                    )
                    return StageRunResult(
                        stage=stage,
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    )
                if stage.startswith("closure_check.witness"):
                    wdir = log_path.parent / "witness"
                    wdir.mkdir(parents=True, exist_ok=True)
                    (wdir / "witness.graphml").write_text(
                        """<?xml version="1.0" encoding="UTF-8"?>\n"
                        "<graphml xmlns='http://graphml.graphdrawing.org/xmlns'>\n"
                        "  <graph edgedefault='directed'>\n"
                        "    <node id='N0'>\n"
                        "      <data key='assumption'>dsl_pump_mode = false</data>\n"
                        "    </node>\n"
                        "  </graph>\n"
                        "</graphml>\n""",
                        encoding="utf-8",
                    )
                    return StageRunResult(
                        stage=stage,
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    )
                if stage == "closure_check":
                    txt = input_bpl.read_text(encoding="utf-8", errors="replace")
                    if "dsl_pump_mode" in txt and "assume(" in txt:
                        return StageRunResult(
                            stage="closure_check",
                            returncode=0,
                            wall_time_s=0.0,
                            result_line="RESULT: Ultimate proved your program to be correct!",
                        )
                    return StageRunResult(
                        stage="closure_check",
                        returncode=0,
                        wall_time_s=0.0,
                        result_line="RESULT: Ultimate proved your program to be incorrect!",
                    )
                raise AssertionError(stage)

        min_bpl = _MIN_BPL + "var dsl_pump_mode: bool;\n"

        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(min_bpl, encoding="utf-8")

            runner = _NoRerunConfirmRunner()
            _run_cegis_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=min_bpl,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=cand,
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
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stage_order="entry_confirm_closure",
            )

            self.assertEqual(runner.confirm_calls, 1)
            self.assertEqual(runner.entry_calls, 1)


if __name__ == "__main__":
    unittest.main()
