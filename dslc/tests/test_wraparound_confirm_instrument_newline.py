import unittest


class TestWraparoundConfirmInstrumentNewline(unittest.TestCase):
    def test_confirm_instrument_does_not_emit_literal_backslash_n(self) -> None:
        # Regression: the confirm-stage instrumentation used to inject a literal
        # "\\n" into the Boogie source, producing a parser error in Ultimate.
        from dslc.transform.wraparound_analyze import WraparoundStage
        from dslc.transform.wraparound_instrument import instrument_bpl_text

        bpl = """\
var dsl_pump_mode: bool;
var p_reg: [bv32]bv32;
var p_reg__last0_value: bv32;
var p_reg__wrote_index0: bool;
var procurator_step: int;
var procurator_phase: int;

procedure main();

procedure mainProcedure() returns()
  modifies p_reg, p_reg__last0_value, p_reg__wrote_index0, dsl_pump_mode, procurator_step, procurator_phase;
{
  dsl_pump_mode := true;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""

        out = instrument_bpl_text(
            bpl_text=bpl,
            stage=WraparoundStage.CONFIRM,
            pump_reg="p_reg",
            accel_regs=["p_reg"],
            index_value=0,
        )

        self.assertNotIn("\\n", out)


if __name__ == "__main__":
    unittest.main()

