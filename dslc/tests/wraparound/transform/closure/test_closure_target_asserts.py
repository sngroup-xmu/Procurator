import unittest

from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text


class TestClosureTargetAsserts(unittest.TestCase):
    def test_closure_aliases_complex_dynamic_index_expr(self) -> None:
        src = """
var procurator_phase: int;
var inbox_count: int;
var r:[bv16]bv8;
function hash_idx(x:bv32) returns (bv16);
function {:inline true} add.bv8(x:bv8, y:bv8) returns (bv8);

procedure main() returns()
  modifies procurator_phase, inbox_count, r;
{
  if (procurator_phase == 1) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, inbox_count, r;
{
  procurator_phase := 0;
  while (true) {
    call main();
  }
}
"""
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="r",
            accel_regs=["r"],
            index_expr="hash_idx(1bv32)",
            proj_vars=["procurator_phase"],
            cutpoint_cond="(procurator_phase == 0) && (r[hash_idx(1bv32)] != 7bv8)",
            proj_predicates=["r[hash_idx(1bv32)] != 7bv8"],
        )

        self.assertIn("var wrap_closure_idx_r: bv16;", out)
        self.assertIn("wrap_closure_idx_r := hash_idx(1bv32);", out)
        self.assertIn("r[wrap_closure_idx_r] := wrap_closure_seq0;", out)
        closure_part = out.split("// wraparound closure_check setup", 1)[1]
        self.assertNotIn("r[hash_idx(1bv32)]", closure_part)
        self.assertIn("r[wrap_closure_idx_r] != 7bv8", closure_part)

    def test_closure_assert_deduplicates_predicate_covered_cutpoint_terms(self) -> None:
        src = """
var procurator_phase: int;
var inbox_count: int;
var r:[bv16]bv8;
var guard: bool;
function hash_idx(x:bv32) returns (bv16);
function {:inline true} add.bv8(x:bv8, y:bv8) returns (bv8);

procedure main() returns()
  modifies procurator_phase, r;
{
  if (procurator_phase == 0) {
    r[hash_idx(1bv32)] := add.bv8(r[hash_idx(1bv32)], 1bv8);
    procurator_phase := 1;
  } else {
    procurator_phase := 0;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, r;
{
  procurator_phase := 0;
  while (true) {
    call main();
  }
}
"""
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="r",
            accel_regs=["r"],
            index_expr="hash_idx(1bv32)",
            proj_vars=["procurator_phase"],
            cutpoint_cond="(guard) && (r[hash_idx(1bv32)] != 7bv8)",
            proj_predicates=["r[hash_idx(1bv32)] != 7bv8"],
        )

        closure_call = out.split("call __wraparound_closure_assert_all(", 1)[1].split(");", 1)[0]
        self.assertIn("((r[wrap_closure_idx_r] != 7bv8) == wrap_closure_pred_0)", closure_call)
        self.assertIn("(guard)", closure_call)
        self.assertNotIn("&& (r[wrap_closure_idx_r] != 7bv8)", closure_call)

    def test_closure_target_uses_last_write_mirror_when_available(self) -> None:
        src = """
var procurator_phase: int;
var r:[bv16]bv8;
var r__last_index:bv16;
var r__last_value:bv8;
var r__wrote_any:bool;
function hash_idx(x:bv32) returns (bv16);
function {:inline true} add.bv8(x:bv8, y:bv8) returns (bv8);

procedure main() returns()
  modifies procurator_phase, r, r__last_index, r__last_value, r__wrote_any;
{
  if (procurator_phase == 0) {
    r[hash_idx(1bv32)] := add.bv8(r[hash_idx(1bv32)], 1bv8);
    r__last_index := hash_idx(1bv32);
    r__last_value := r[hash_idx(1bv32)];
    r__wrote_any := true;
  }
  if (procurator_phase == 0) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, r, r__last_index, r__last_value, r__wrote_any;
{
  procurator_phase := 0;
  while (true) {
    call main();
  }
}
"""
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="r",
            accel_regs=["r"],
            index_expr="hash_idx(1bv32)",
            proj_vars=["procurator_phase"],
            cutpoint_cond="procurator_phase == 0",
        )

        closure_part = out.split("// wraparound closure_check asserts", 1)[1]
        self.assertIn("wrap_closure_after_r := r__last_value;", closure_part)
        self.assertIn("(r__wrote_any)", closure_part)
        self.assertIn("(r__last_index == wrap_closure_idx_r)", closure_part)
        self.assertNotIn("wrap_closure_after_r := r[wrap_closure_idx_r];", closure_part)

    def test_closure_target_falls_back_to_array_read_when_last_write_mirror_incomplete(self) -> None:
        src = """
var procurator_phase: int;
var r:[bv16]bv8;
var r__last_value:bv8;
function hash_idx(x:bv32) returns (bv16);
function {:inline true} add.bv8(x:bv8, y:bv8) returns (bv8);

procedure main() returns()
  modifies procurator_phase, r, r__last_value;
{
  if (procurator_phase == 0) {
    r[hash_idx(1bv32)] := add.bv8(r[hash_idx(1bv32)], 1bv8);
    r__last_value := r[hash_idx(1bv32)];
  }
  if (procurator_phase == 0) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, r, r__last_value;
{
  procurator_phase := 0;
  while (true) {
    call main();
  }
}
"""
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="r",
            accel_regs=["r"],
            index_expr="hash_idx(1bv32)",
            proj_vars=["procurator_phase"],
            cutpoint_cond="procurator_phase == 0",
        )

        closure_part = out.split("// wraparound closure_check asserts", 1)[1]
        self.assertIn("wrap_closure_after_r := r[wrap_closure_idx_r];", closure_part)
        self.assertNotIn("wrap_closure_after_r := r__last_value;", closure_part)
        self.assertNotIn("r__last_index == wrap_closure_idx_r", closure_part)


if __name__ == "__main__":
    unittest.main()
