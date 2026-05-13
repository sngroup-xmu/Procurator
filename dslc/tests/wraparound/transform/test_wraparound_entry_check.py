import unittest

from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text


class TestWraparoundEntryCheckTransform(unittest.TestCase):
    def test_entry_check_inserts_reachability_error(self) -> None:
        src = """
var procurator_step: int;
var procurator_phase: int;
var unused_reg:[bv32]bv8;

procedure main() returns()
  modifies procurator_phase;
{
  if (procurator_phase == 0) {
  }
  if (procurator_phase == 4) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, procurator_step, unused_reg;
{
  procurator_step := 0;
  procurator_phase := 0;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.ENTRY_CHECK,
            pump_reg="unused_reg",
            accel_regs=["unused_reg"],
        )
        # ENTRY_CHECK is a pre-loop satisfiability gate; the scheduler suffix is irrelevant.
        self.assertNotIn("while (true)", out)
        self.assertNotIn("procurator_step := procurator_step + 1;", out)
        self.assertIn("call __wraparound_entry_error();", out)
        self.assertLess(out.index("procurator_phase := 0;"), out.index("call __wraparound_entry_error();"))
        self.assertLess(out.index("call __wraparound_entry_error();"), out.index("return;"))
        self.assertIn("WRAPAROUND_ENTRY_ASSERT", out)

    def test_entry_check_extra_assumes_precede_error_and_suffix_truncation(self) -> None:
        src = """
var procurator_step: int;
var procurator_phase: int;
var stable: bv8;

procedure main() returns()
  modifies procurator_phase, stable;
{
  havoc stable;
  if (procurator_phase == 0) {
  }
  if (procurator_phase == 1) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, procurator_step, stable;
{
  procurator_step := 0;
  procurator_phase := 0;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.ENTRY_CHECK,
            pump_reg="unused_reg",
            accel_regs=["unused_reg"],
            extra_assumes=["stable == 7bv8"],
        )

        self.assertNotIn("while (true)", out)
        self.assertNotIn("call main();", out)
        self.assertIn("assume(stable == 7bv8);", out)
        self.assertLess(out.index("assume(stable == 7bv8);"), out.index("call __wraparound_entry_error();"))
        self.assertLess(out.index("call __wraparound_entry_error();"), out.index("return;"))

    def test_tail_entry_check_truncates_after_prefix_error(self) -> None:
        src = """
var procurator_step: int;
var procurator_phase: int;
var unused_reg:[bv32]bv8;

procedure main() returns()
  modifies procurator_phase;
{
  if (procurator_phase == 0) {
    procurator_phase := 1;
  } else {
    procurator_phase := 0;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, procurator_step, unused_reg;
{
  procurator_step := 0;
  procurator_phase := 0;
  // UNROLLED 2 steps (wraparound)
  call main();
  call main();
}
"""
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.ENTRY_CHECK,
            pump_reg="unused_reg",
            accel_regs=["unused_reg"],
            entry_check_insertion="tail",
            extra_assumes=["procurator_phase == 0"],
        )

        self.assertLess(out.index("call main();"), out.index("assume(procurator_phase == 0);"))
        self.assertLess(out.index("assume(procurator_phase == 0);"), out.index("call __wraparound_entry_error();"))
        self.assertLess(out.index("call __wraparound_entry_error();"), out.index("return;"))
        suffix = out[out.index("call __wraparound_entry_error();") :]
        self.assertNotIn("call main();", suffix)


if __name__ == "__main__":
    unittest.main()
