from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.speclang.parse import parse_model
from dslc.workflows.wraparound_cegis import StageRunResult, _run_cegis_loop, _synthesize_env_completion_assumes


class _TimeoutThenUnsafeRunner:
    def __init__(self) -> None:
        self.confirm_calls = 0

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
            return StageRunResult(
                stage=stage,
                returncode=0,
                wall_time_s=0.01,
                result_line="RESULT: Ultimate proved your program to be incorrect!",
            )

        if stage == "confirm":
            self.confirm_calls += 1
            # Simulate a timeout (unknown). With closure-only refinement, we should stop here.
            return StageRunResult(stage=stage, returncode=124, wall_time_s=timeout_seconds, result_line=None)

        if stage == "closure_check":
            raise AssertionError("closure_check should not run if CONFIRM is UNKNOWN")

        if stage.startswith("entry_check.witness.") or stage.startswith("enable_check"):
            raise AssertionError("no pre-confirm refinement stages expected")

        raise AssertionError(f"unexpected stage: {stage}")


class TestEnvCompletionRefinement(unittest.TestCase):
    def test_confirm_timeout_does_not_trigger_env_completion_refinement(self) -> None:
        # Minimal spec with a host env that assigns only one field.
        spec_text = """
import s from "dummy.p4";
topology {}
host io {
  connect s;
  env {
    hdr.ipv4_hdr.valid = true;
  }
}
global { max_steps = 4; }
"""

        # Minimal Boogie:
        # - includes the deterministic scheduler pattern expected by closure_check
        # - declares a havoced host field NOT assigned by the env block
        base_text = """
var procurator_phase: int;
var procurator_step: int;
var r: [bv32]bv8;
var r__last0_value: bv8;

var io_hdr.ipv4_hdr.valid: bool;
var io_hdr.udp_hdr.srcPort: bv16;

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
    havoc io_hdr.ipv4_hdr.valid;
    havoc io_hdr.udp_hdr.srcPort;
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

        runner = _TimeoutThenUnsafeRunner()
        with tempfile.TemporaryDirectory(prefix="procurator-cegis-envrefine-") as td:
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
                enable_env_completion_refinement=True,
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
            # CONFIRM is UNKNOWN => no closure run and no env-completion under-approx.
            self.assertEqual(runner.confirm_calls, 1)
            last = mf["attempts"][-1]
            self.assertIsNotNone(last.get("confirm"))
            self.assertIsNone(last.get("closure"))
            self.assertTrue(
                all("io_hdr.udp_hdr.srcPort" not in a for a in last["cfg"]["closure_assumes"]),
                last["cfg"]["closure_assumes"],
            )

    def test_env_completion_does_not_pin_conditionally_assigned_fields(self) -> None:
        # Regression: env-completion under-approx must recognize assignments nested
        # under control flow (e.g., `if (pump_mode) { ... }`) and avoid pinning them to 0.
        spec_text = """
import s from "dummy.p4";
topology {}
host io {
  connect s;
  env {
    if (pump_mode) {
      hdr.op_hdr.optype = 4;
    } else {
      hdr.op_hdr.optype = 36;
    }
  }
}
global { bool pump_mode = true; }
"""
        model = parse_model(spec_text)
        base_text = """
var io_hdr.op_hdr.optype: bv16;
procedure mainProcedure() returns()
{
  havoc io_hdr.op_hdr.optype;
  return;
}
"""
        assumes = _synthesize_env_completion_assumes(model=model, base_text=base_text)
        self.assertFalse(any("io_hdr.op_hdr.optype" in a for a in assumes), assumes)


if __name__ == "__main__":
    unittest.main()
