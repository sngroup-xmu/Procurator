from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.workflows.wraparound_cegis import StageRunResult, _run_cegis_loop


class _EntryWitnessRefineRunner:
    def __init__(self) -> None:
        self.confirm_calls = 0
        self.entry_witness_calls = 0

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
        if stage == "entry_check":
            # ENTRY is reachable (UNSAFE).
            return StageRunResult(
                stage=stage,
                returncode=0,
                wall_time_s=0.01,
                result_line="RESULT: Ultimate proved your program to be incorrect!",
            )

        if stage.startswith("entry_check.witness.") or stage.startswith("enable_check"):
            raise AssertionError("ENTRY/CONFIRM are existential: no pre-confirm refinement stages expected")

        if stage == "confirm":
            self.confirm_calls += 1
            # Simulate a timeout (UNKNOWN). With closure-only refinement, we should stop here.
            return StageRunResult(stage=stage, returncode=124, wall_time_s=timeout_seconds, result_line=None)

        if stage == "closure_check":
            raise AssertionError("closure_check should not run if CONFIRM is UNKNOWN")

        raise AssertionError(f"unexpected stage: {stage}")


class TestEntryWitnessRefinement(unittest.TestCase):
    def test_confirm_timeout_does_not_trigger_preconfirm_refinement(self) -> None:
        spec_text = """
import s from "dummy.p4";
topology {}
host io { connect s; env { hdr.inswitch_hdr.idx = 7; } }
global { max_steps = 4; }
"""

        # Minimal Boogie program that declares the witness-constrained variable.
        base_text = """
var procurator_phase: int;
var procurator_step: int;
var r: [bv32]bv8;
var r__last0_value: bv8;
var io_hdr_eg.inswitch_hdr.idx: bv16;

procedure main() returns()
{
  if (procurator_phase == 0) {
    procurator_phase := 0;
  }
  return;
}

procedure mainProcedure() returns()
{
  while (true) {
    havoc io_hdr_eg.inswitch_hdr.idx;
    call main();
    procurator_step := procurator_step + 1;
  }
}
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

        runner = _EntryWitnessRefineRunner()
        with tempfile.TemporaryDirectory(prefix="procurator-cegis-entrywrefine-") as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(base_text, encoding="utf-8")

            mf_path = _run_cegis_loop(
                spec_path=out_dir / "x.prop",
                spec_text=spec_text,
                base_bpl=base_bpl,
                base_text=base_text,
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
                stage_order="entry_confirm_closure",
            )

            mf = json.loads(mf_path.read_text(encoding="utf-8"))
            self.assertEqual(runner.confirm_calls, 1)
            self.assertEqual(runner.entry_witness_calls, 0)

            # Confirm is UNKNOWN => no closure run and no witness-derived shape assumptions.
            last = mf["attempts"][-1]
            self.assertIsNotNone(last.get("confirm"))
            self.assertIsNone(last.get("closure"))
            last_cfg = last["cfg"]
            self.assertTrue(
                all("io_hdr_eg.inswitch_hdr.idx" not in a for a in last_cfg["closure_assumes"]),
                last_cfg["closure_assumes"],
            )


if __name__ == "__main__":
    unittest.main()
