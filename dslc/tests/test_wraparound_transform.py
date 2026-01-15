import unittest

from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text, unroll_mainprocedure_loop_text


class TestWraparoundTransform(unittest.TestCase):
    def test_confirm_inserts_fast_forward(self) -> None:
        src = """
var procurator_step: int;
var s1_sequence_reg:[bv32]bv16;

procedure {:inline 1} s1_sequence_reg.write(i:bv32, v:bv16)
  modifies s1_sequence_reg;
{
  s1_sequence_reg[i] := v;
}

procedure main() returns()
  modifies procurator_step, s1_sequence_reg;
{
}

procedure mainProcedure() returns()
  modifies procurator_step, s1_sequence_reg;
{
  procurator_step := 0;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.CONFIRM,
            pump_reg="s1_sequence_reg",
            accel_regs=["s1_sequence_reg"],
        )
        self.assertIn("call s1_sequence_reg.write(0bv32, 65535bv16);", out)
        self.assertLess(out.index("call s1_sequence_reg.write"), out.index("while (true)"))
        self.assertNotIn("wrap_snap_taken", out)

    def test_unroll_replaces_while_loop(self) -> None:
        src = """
var procurator_step: int;
procedure main() returns()
  modifies procurator_step;
{
}

procedure mainProcedure() returns()
  modifies procurator_step;
{
  procurator_step := 0;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""
        out = unroll_mainprocedure_loop_text(bpl_text=src, steps=3)
        self.assertIn("// UNROLLED 3 steps", out)
        self.assertNotIn("while (true)", out)
        self.assertEqual(out.count("call main();"), 3)

    def test_pump_instruments_main_procedure(self) -> None:
        src = """
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
  modifies procurator_phase, s1_sequence_reg;
{
  if (procurator_phase == 0) {
    call s1_sequence_reg.write(0bv32, add.bv16(s1_sequence_reg[0bv32], 1bv16));
  }
  procurator_phase := 0;
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
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.PUMP,
            pump_reg="s1_sequence_reg",
            accel_regs=["s1_sequence_reg", "s2_sequence_reg"],
            index_value=0,
        )

        # Locals inserted.
        self.assertIn("var wrap_snap_taken: bool;", out)
        self.assertIn("var wrap_target_old: bv16;", out)
        self.assertIn("var wrap_target_new: bv16;", out)

        # Step block inserted and pump triggers reachability.
        self.assertIn("wrap_target_old := s1_sequence_reg[0bv32];", out)
        self.assertIn("wrap_target_new := s1_sequence_reg[0bv32];", out)
        self.assertIn("assert false;", out)

        # Snapshot is deterministic at the first cutpoint.
        self.assertIn("if (!wrap_snap_taken) {", out)
        self.assertRegex(out, r"if\s*\(wrap_snap_taken.*\)\s*\{")

    def test_closure_check_unrolls_one_round_and_proves_inc(self) -> None:
        src = """
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
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="s1_sequence_reg",
            accel_regs=["s1_sequence_reg", "s2_sequence_reg"],
            index_value=0,
        )

        # The while-loop is eliminated by a single-round unroll.
        self.assertIn("// UNROLLED 5 steps (wraparound)", out)
        self.assertNotIn("while (true)", out)
        self.assertEqual(out.count("wraparound inlined phase"), 5)

        # Decls + setup for all accelerated regs.
        self.assertIn("var wrap_closure_seq0: bv16;", out)
        self.assertIn("havoc wrap_closure_seq0;", out)
        self.assertIn("assume wrap_closure_seq0 != 65535bv16;", out)
        self.assertIn("call s1_sequence_reg.write(0bv32, wrap_closure_seq0);", out)
        self.assertIn("call s2_sequence_reg.write(0bv32, wrap_closure_seq0);", out)
        self.assertLess(out.index("var wrap_closure_seq0"), out.index("havoc wrap_closure_seq0"))

        # Closure: +1 for all accelerated regs, and return to the cutpoint.
        self.assertIn(
            "call __wraparound_assert(wrap_closure_after_s1_sequence_reg == add.bv16(wrap_closure_seq0, 1bv16));",
            out,
        )
        self.assertIn(
            "call __wraparound_assert(wrap_closure_after_s2_sequence_reg == add.bv16(wrap_closure_seq0, 1bv16));",
            out,
        )
        self.assertIn("call __wraparound_assert(((procurator_phase == 0)));", out)

        # Single assertion location via wrapper.
        self.assertIn("procedure {:inline 1} __wraparound_assert", out)

    def test_missing_main_procedure_errors(self) -> None:
        with self.assertRaises(Exception):
            instrument_bpl_text(
                bpl_text="procedure foo() returns() { }",
                stage=WraparoundStage.PUMP,
                pump_reg="s1_sequence_reg",
                accel_regs=["s1_sequence_reg"],
            )


if __name__ == "__main__":
    unittest.main()
