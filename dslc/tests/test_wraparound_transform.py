import unittest

from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text, unroll_mainprocedure_loop_text


class TestWraparoundTransform(unittest.TestCase):
    def test_index_expr_is_zero_extended_to_reg_index_width(self) -> None:
        # Regression: meta-derived wraparound candidates often use bv16 switch indices
        # (e.g., `meta.spineswitchidx`) while P4B emits register arrays indexed by bv32.
        # Wraparound stages must coerce the index expression to bv32 (e.g., `0bv16++idx16`)
        # or the generated Boogie becomes ill-typed.
        src = """
var procurator_step: int;
var idx16: bv16;
var r:[bv32]bv32;

procedure main() returns()
  modifies idx16, r;
{
}

procedure mainProcedure() returns()
  modifies procurator_step, idx16, r;
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
            stage=WraparoundStage.PUMP,
            pump_reg="r",
            accel_regs=[],
            index_expr="idx16",
        )
        self.assertIn("0bv16++idx16", out)
        self.assertNotIn("r[idx16]", out)

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
  assert true;
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
        self.assertIn("s1_sequence_reg[0bv32] := 65535bv16;", out)
        self.assertLess(out.index("s1_sequence_reg[0bv32] := 65535bv16;"), out.index("while (true)"))
        self.assertNotIn("wrap_snap_taken", out)
        self.assertIn("call __wraparound_assert(true);", out)
        self.assertIn("if ((s1_sequence_reg[0bv32] != 65535bv16))", out)

    def test_confirm_inserts_fast_forward_with_bounded_loop(self) -> None:
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
  assert true;
}

procedure mainProcedure() returns()
  modifies procurator_step, s1_sequence_reg;
{
  procurator_step := 0;
  while (procurator_step < 10) {
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
        self.assertIn("s1_sequence_reg[0bv32] := 65535bv16;", out)
        self.assertLess(out.index("s1_sequence_reg[0bv32] := 65535bv16;"), out.index("while (procurator_step < 10)"))
        self.assertIn("call __wraparound_assert(true);", out)
        self.assertIn("if ((s1_sequence_reg[0bv32] != 65535bv16))", out)

    def test_enable_check_inserts_goal_call(self) -> None:
        src = """
var procurator_step: int;
var s1_sequence_reg:[bv32]bv16;

procedure main() returns()
  modifies procurator_step, s1_sequence_reg;
{
  // No property asserts here; enable_check should still inject its own goal.
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
            stage=WraparoundStage.ENABLE_CHECK,
            pump_reg="s1_sequence_reg",
            accel_regs=["s1_sequence_reg"],
        )
        # Fast-forward to MAX must be present (same as confirm).
        self.assertIn("s1_sequence_reg[0bv32] := 65535bv16;", out)
        # ENABLE_CHECK is encoded as a satisfiability query:
        #   assume target != MAX; assert false;
        self.assertIn("assume (s1_sequence_reg[0bv32] != 65535bv16);", out)
        self.assertIn("assert false;", out)

    def test_confirm_reasserts_const_after_havoc(self) -> None:
        # Regression: no-slicing harnesses may `havoc` host/meta variables that
        # wraparound CEGIS pins to stabilize the pumped index (e.g., io_meta.leafswitchidx).
        # The constraint must be re-asserted after the havoc, otherwise the
        # solver can pump a different register cell than the one fast-forwarded.
        src = """
var procurator_step: int;
var io_meta.leafswitchidx: bv16;
var r:[bv32]bv32;

procedure main() returns()
  modifies r;
{
  assert true;
}

procedure mainProcedure() returns()
  modifies procurator_step, io_meta.leafswitchidx, r;
{
  procurator_step := 0;
  while (true) {
    havoc io_meta.leafswitchidx;
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.CONFIRM,
            pump_reg="r",
            accel_regs=["r"],
            extra_assumes=["io_meta.leafswitchidx == 2bv16"],
        )
        self.assertIn("havoc io_meta.leafswitchidx;", out)
        # There is an assume at the top (extra_assumes) *and* one re-inserted after havoc.
        tail = out.split("havoc io_meta.leafswitchidx;", 1)[1]
        self.assertIn("assume(io_meta.leafswitchidx == 2bv16);", tail)

    def test_confirm_inserts_two_phase_pump_mode_guard_even_with_havoc_reassert(self) -> None:
        # Regression: confirm should drive a two-phase env script using `dsl_pump_mode`.
        #
        # Extra assumes may trigger "reassert after havoc" insertions *earlier* in the file,
        # shifting mainProcedure indices. The pump-mode guard insertion must remain robust.
        src = """
var procurator_step: int;
var procurator_phase: int;
var dsl_pump_mode: bool;
var io_meta.leafswitchidx: bv16;
var reg:[bv32]bv32;
var reg__last0_value: bv32;
var reg__wrote_any: bool;
var reg__wrote_index0: bool;
var reg__last_index: bv32;
var reg__last_value: bv32;

procedure main() returns()
  modifies io_meta.leafswitchidx, procurator_phase, dsl_pump_mode;
{
  if (procurator_phase == 0) {
    havoc io_meta.leafswitchidx;
  }
}

procedure mainProcedure() returns()
  modifies procurator_step, procurator_phase, dsl_pump_mode, reg, reg__last0_value,
           reg__wrote_any, reg__wrote_index0, reg__last_index, reg__last_value;
{
  procurator_step := 0;
  procurator_phase := 0;
  dsl_pump_mode := true;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.CONFIRM,
            pump_reg="reg",
            accel_regs=["reg"],
            index_value=0,
            index_expr=None,
            proj_vars=["procurator_phase"],
            cutpoint_cond=None,
            step_op="add",
            step_delta=1,
            extra_assumes=["io_meta.leafswitchidx == 2bv16"],
        )
        # The guard should be placed in the phase-0 branch of `main()`.
        frag = out.split("if (procurator_phase == 0)", 1)[1]
        self.assertIn("dsl_pump_mode := (reg__last0_value == 4294967295bv32);", frag)

    def test_confirm_drives_two_phase_pump_mode_in_inlined_deterministic_schedule(self) -> None:
        # Regression: when the deterministic scheduler is inlined into mainProcedure
        # (no `procedure main()` / no procurator_phase), CONFIRM must still drive
        # the two-phase host env script (`dsl_pump_mode`) by re-assigning it before
        # each injection that branches on it.
        src = """
var dsl_pump_mode: bool;
var reg:[bv32]bv32;
var reg__last0_value: bv32;

procedure mainProcedure() returns()
  modifies dsl_pump_mode, reg, reg__last0_value;
{
  dsl_pump_mode := true;
  // Inlined host injection: the packet type depends on dsl_pump_mode.
  if (true) {
    if (dsl_pump_mode) {
      assert true;
    } else {
      assert true;
    }
  }
}

procedure ULTIMATE.start() returns()
  modifies dsl_pump_mode, reg, reg__last0_value;
{
  call mainProcedure();
}
"""
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.CONFIRM,
            pump_reg="reg",
            accel_regs=["reg"],
        )
        # The assignment should be injected right before the `if (dsl_pump_mode)` that
        # controls the host injection.
        frag = out.split("if (dsl_pump_mode)", 1)[0]
        self.assertIn("dsl_pump_mode := (reg__last0_value == 4294967295bv32);", frag)

    def test_confirm_inserts_fast_forward_in_concurrent_harness(self) -> None:
        src = """
var s1_sequence_reg:[bv32]bv16;
var s1_sequence_reg__last0_value: bv16;

procedure {:inline 1} s1_sequence_reg.write(i:bv32, v:bv16)
  modifies s1_sequence_reg, s1_sequence_reg__last0_value;
{
  s1_sequence_reg[i] := v;
  if (i == 0bv32) {
    s1_sequence_reg__last0_value := v;
  }
}

procedure EnvThread() returns() { }

procedure s1Thread() returns()
  modifies s1_sequence_reg, s1_sequence_reg__last0_value;
{
  assert true;
}

procedure ULTIMATE.start() returns()
  modifies s1_sequence_reg, s1_sequence_reg__last0_value;
{
  // initialize P4 registers (default 0)
  assume (forall i:bv32 :: s1_sequence_reg[i] == 0bv16);
  s1_sequence_reg__last0_value := 0bv16;
  // spawn threads
  fork 0 EnvThread();
  fork 1 s1Thread();
}
"""
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.CONFIRM,
            pump_reg="s1_sequence_reg",
            accel_regs=["s1_sequence_reg"],
        )
        self.assertIn("s1_sequence_reg[0bv32] := 65535bv16;", out)
        # Keep scalar mirrors consistent when they exist.
        self.assertIn("s1_sequence_reg__last0_value := 65535bv16;", out)
        self.assertLess(out.index("s1_sequence_reg[0bv32] := 65535bv16;"), out.index("fork 0 EnvThread();"))
        self.assertIn("call __wraparound_assert(true);", out)
        self.assertIn("if ((s1_sequence_reg__last0_value != 65535bv16))", out)

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

    def test_unroll_replaces_bounded_while_loop(self) -> None:
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
  while (procurator_step < 5) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""
        out = unroll_mainprocedure_loop_text(bpl_text=src, steps=3)
        self.assertIn("// UNROLLED 3 steps", out)
        self.assertNotIn("while (procurator_step < 5)", out)
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

    def test_entry_check_inserts_reachability_error(self) -> None:
        src = """
var procurator_step: int;
var procurator_phase: int;

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
  modifies procurator_phase, procurator_step;
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
        # ENTRY_CHECK is a cheap satisfiability gate: it should not unroll the scheduler.
        self.assertIn("while (true)", out)
        self.assertIn("procurator_step := procurator_step + 1;", out)
        self.assertIn("call __wraparound_entry_error();", out)
        self.assertIn("WRAPAROUND_ENTRY_ASSERT", out)

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
        self.assertIn("s1_sequence_reg[0bv32] := wrap_closure_seq0;", out)
        self.assertIn("s2_sequence_reg[0bv32] := wrap_closure_seq0;", out)
        self.assertLess(out.index("var wrap_closure_seq0"), out.index("havoc wrap_closure_seq0"))

        # Closure: +1 for all accelerated regs, and return to the cutpoint.
        self.assertIn("call __wraparound_closure_assert_all(", out)
        self.assertIn("wrap_closure_after_s1_sequence_reg == add.bv16(wrap_closure_seq0, 1bv16)", out)
        self.assertIn("wrap_closure_after_s2_sequence_reg == add.bv16(wrap_closure_seq0, 1bv16)", out)
        self.assertIn("(procurator_phase == 0)", out)

        # Assertion wrappers (for CEGIS refinement / stable Ultimate targets).
        self.assertIn("procedure {:inline 1} __wraparound_assert", out)
        self.assertIn("procedure {:inline 1} __wraparound_closure_assert_all", out)

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
