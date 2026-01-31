from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.workflows.wraparound_cegis import StageRunResult, _run_cegis_loop


class _FakeRunner:
    def __init__(self, results: dict[str, StageRunResult]) -> None:
        self._results = results
        self.calls: list[str] = []

    def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
        self.calls.append(stage)
        return self._results[stage]


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
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=1,
                runner=runner,
                toolchain=Path("tc.xml"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stage_order="entry_confirm_closure",
            )

            self.assertEqual(runner.calls, ["entry_check", "confirm"])

            mf = json.loads((out_dir / "wraparound.cegis.manifest.json").read_text(encoding="utf-8"))
            self.assertEqual(len(mf["attempts"]), 1)
            self.assertIsNone(mf["attempts"][0]["closure"])
            self.assertIsNotNone(mf["attempts"][0]["confirm"])

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
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=1,
                runner=runner,
                toolchain=Path("tc.xml"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stage_order="entry_closure_confirm",
            )

            self.assertEqual(runner.calls, ["entry_check", "closure_check", "confirm"])

            mf = json.loads((out_dir / "wraparound.cegis.manifest.json").read_text(encoding="utf-8"))
            self.assertEqual(len(mf["attempts"]), 1)
            self.assertIsNotNone(mf["attempts"][0]["closure"])
            self.assertIsNotNone(mf["attempts"][0]["confirm"])

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
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=4,
                max_iters=1,
                runner=runner,
                toolchain=Path("tc.xml"),
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


if __name__ == "__main__":
    unittest.main()
