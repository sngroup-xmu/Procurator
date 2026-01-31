from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

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
            return StageRunResult(stage=stage, returncode=0, wall_time_s=0.01, result_line="RESULT: UNSAFE")

        # Simulate refinement: first closure attempt fails, second succeeds.
        if stage == "closure_check":
            if ".cegis.00." in input_bpl.name:
                return StageRunResult(stage=stage, returncode=0, wall_time_s=0.01, result_line="RESULT: UNKNOWN")
            return StageRunResult(stage=stage, returncode=0, wall_time_s=0.01, result_line="RESULT: SAFE")

        if stage == "confirm":
            return StageRunResult(stage=stage, returncode=0, wall_time_s=0.01, result_line="RESULT: UNSAFE")

        raise AssertionError(f"unexpected stage: {stage}")


class TestWraparoundCegis(unittest.TestCase):
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
                resource_limits=False,
                confirm_unroll=3,
                max_iters=3,
                runner=runner,
                toolchain=out_dir / "tc.xml",
                closure_toolchain=out_dir / "tc_cl.xml",
                settings=out_dir / "st.epf",
                closure_settings=out_dir / "st_cl.epf",
            )

            self.assertTrue(manifest_path.exists())
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(manifest["spec"], "dummy.prop")
            self.assertGreaterEqual(len(manifest["attempts"]), 2)

            # Confirm is run only after closure becomes SAFE (our fake runner makes this happen on iter 1).
            stages = [c[0] for c in runner.calls]
            self.assertIn("confirm", stages)
            # Entry and closure must have been called at least twice due to refinement.
            self.assertGreaterEqual(stages.count("entry_check"), 2)
            self.assertGreaterEqual(stages.count("closure_check"), 2)

