import unittest

from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text
from dslc.transform.wraparound_stages import (
    _drop_remaining_forall_array_inits_for_closure,
    _rewrite_forall_bv32_array_inits,
)


class TestWraparoundForallInitElim(unittest.TestCase):
    def test_eliminates_forall_init_with_bv16_bound_on_concat_index(self) -> None:
        lines = [
            "assume (forall i:bv32 :: reg[i] == 0bv32);\n",
            "assume reg[0bv32] == 0bv32;\n",
            "procedure foo() returns()\n",
            "{\n",
            "  assume(hdr.idx == 7bv16);\n",
            "  x := reg.read(reg, 0bv16++hdr.idx);\n",
            "}\n",
        ]
        _rewrite_forall_bv32_array_inits(lines)
        out = "".join(lines)
        self.assertNotIn("forall i:bv32", out)
        # Index 0 is explicitly present; the rewrite should add the missing indices 1..7.
        for k in range(1, 8):
            self.assertIn(f"assume reg[{k}bv32] == 0bv32;", out)
        self.assertIn("assume reg[0bv32] == 0bv32;", out)

    def test_keeps_forall_init_when_no_finite_bound_is_inferred(self) -> None:
        lines = [
            "assume (forall i:bv32 :: reg[i] == 0bv32);\n",
            "assume reg[0bv32] == 0bv32;\n",
            "procedure foo() returns()\n",
            "{\n",
            "  // No assume bounds on hdr.idx => cannot infer accessed index domain.\n",
            "  x := reg.read(reg, 0bv16++hdr.idx);\n",
            "}\n",
        ]
        _rewrite_forall_bv32_array_inits(lines)
        out = "".join(lines)
        self.assertIn("assume (forall i:bv32 :: reg[i] == 0bv32);", out)

    def test_keeps_forall_init_when_bound_too_large(self) -> None:
        # Expansion cap in wraparound_common is 64; ensure we do not raise and
        # we keep the quantifier when the inferred bound is too large.
        lines = [
            "assume (forall i:bv32 :: reg[i] == 0bv32);\n",
            "assume reg[0bv32] == 0bv32;\n",
            "procedure foo() returns()\n",
            "{\n",
            "  assume(hdr.idx == 70bv16);\n",
            "  x := reg.read(reg, 0bv16++hdr.idx);\n",
            "}\n",
        ]
        _rewrite_forall_bv32_array_inits(lines)
        out = "".join(lines)
        self.assertIn("assume (forall i:bv32 :: reg[i] == 0bv32);", out)

    def test_eliminates_forall_init_except_one_index(self) -> None:
        lines = [
            "assume (forall i:bv32 :: ((i != 7bv32)) ==> reg[i] == 0bv1);\n",
            "assume reg[0bv32] == 0bv1;\n",
            "assume reg[7bv32] == 1bv1;\n",
            "procedure foo() returns()\n",
            "{\n",
            "  assume(hdr.idx == 7bv16);\n",
            "  x := reg.read(reg, 0bv16++hdr.idx);\n",
            "}\n",
        ]
        _rewrite_forall_bv32_array_inits(lines)
        out = "".join(lines)
        self.assertNotIn("forall i:bv32", out)
        # The rewrite should add explicit init for indices 1..6, but not index 7.
        for k in range(1, 7):
            self.assertIn(f"assume reg[{k}bv32] == 0bv1;", out)
        self.assertIn("assume reg[0bv32] == 0bv1;", out)
        self.assertIn("assume reg[7bv32] == 1bv1;", out)

    def test_closure_only_helper_drops_typedef_index_array_init(self) -> None:
        lines = [
            "type sw_lid_t = bv32;\n",
            "var reg:[sw_lid_t]bv8;\n",
            "  assume (forall i:sw_lid_t :: reg[i] == 0bv8);\n",
            "  assume reg[0bv32] == 0bv8;\n",
        ]
        _drop_remaining_forall_array_inits_for_closure(lines)
        out = "".join(lines)
        self.assertNotIn("forall i:sw_lid_t", out)
        self.assertIn("assume reg[0bv32] == 0bv8;", out)

    def test_closure_only_helper_drops_typedef_index_except_init(self) -> None:
        lines = [
            "type sw_lid_t = bv32;\n",
            "var reg:[sw_lid_t]bv8;\n",
            "  assume (forall i:sw_lid_t :: ((i != 0bv32)) ==> reg[i] == 0bv8);\n",
            "  assume reg[0bv32] == 1bv8;\n",
        ]
        _drop_remaining_forall_array_inits_for_closure(lines)
        out = "".join(lines)
        self.assertNotIn("forall i:sw_lid_t", out)
        self.assertIn("assume reg[0bv32] == 1bv8;", out)

    def test_closure_instrumentation_drops_typedef_index_array_init(self) -> None:
        src = """
type sw_lid_t = bv32;
var procurator_step: int;
var procurator_phase: int;
var reg:[sw_lid_t]bv8;
var reg__last0_value: bv8;

procedure main() returns()
  modifies procurator_phase, reg, reg__last0_value;
{
  if (procurator_phase == 0) {
    reg[0bv32] := add.bv8(reg[0bv32], 1bv8);
    reg__last0_value := reg[0bv32];
  }
  if (procurator_phase == 0) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, procurator_step, reg, reg__last0_value;
{
  assume (forall i:sw_lid_t :: reg[i] == 0bv8);
  assume reg[0bv32] == 0bv8;
  reg__last0_value := 0bv8;
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
            pump_reg="reg",
            accel_regs=["reg"],
            index_value=0,
        )
        self.assertNotIn("forall i:sw_lid_t :: reg[i] == 0bv8", out)
        self.assertIn("assume reg[0bv32] == 0bv8;", out)

    def test_entry_check_preserves_typedef_index_array_init(self) -> None:
        src = """
type sw_lid_t = bv32;
var procurator_step: int;
var procurator_phase: int;
var reg:[sw_lid_t]bv8;

procedure main() returns()
  modifies procurator_phase;
{
  procurator_phase := 0;
}

procedure mainProcedure() returns()
  modifies procurator_phase, procurator_step;
{
  assume (forall i:sw_lid_t :: reg[i] == 0bv8);
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
            pump_reg="reg",
            accel_regs=["reg"],
            index_value=0,
        )
        self.assertIn("assume (forall i:sw_lid_t :: reg[i] == 0bv8);", out)
