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
        _rewrite_forall_bv32_array_inits(lines, use_assume_bounds=True)
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
        _rewrite_forall_bv32_array_inits(lines, use_assume_bounds=True)
        out = "".join(lines)
        self.assertIn("assume (forall i:bv32 :: reg[i] == 0bv32);", out)

    def test_default_rewrite_does_not_use_path_local_assume_bound(self) -> None:
        lines = [
            "assume (forall i:bv11 :: reg[i] == 0bv16);\n",
            "procedure bounded_path() returns()\n",
            "{\n",
            "  assume meta.idx == 0bv11;\n",
            "  x := reg.read(reg, meta.idx);\n",
            "}\n",
            "procedure unbounded_path() returns()\n",
            "{\n",
            "  y := reg.read(reg, meta.idx);\n",
            "}\n",
        ]
        _rewrite_forall_bv32_array_inits(lines)
        out = "".join(lines)
        self.assertIn("assume (forall i:bv11 :: reg[i] == 0bv16);", out)

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
        _rewrite_forall_bv32_array_inits(lines, use_assume_bounds=True)
        out = "".join(lines)
        self.assertNotIn("forall i:bv32", out)
        # The rewrite should add explicit init for indices 1..6, but not index 7.
        for k in range(1, 7):
            self.assertIn(f"assume reg[{k}bv32] == 0bv1;", out)
        self.assertIn("assume reg[0bv32] == 0bv1;", out)
        self.assertIn("assume reg[7bv32] == 1bv1;", out)

    def test_keeps_size_only_forall_init_when_dynamic_access_is_unbounded(self) -> None:
        lines = [
            "const reg.size:bv32;\n",
            "axiom reg.size == 20bv32;\n",
            "assume (forall i:bv32 :: ((i != 0bv32) && (i != 1bv32) && (i != 2bv32)) ==> reg[i] == 0bv16);\n",
            "assume reg[0bv32] == 65535bv16;\n",
            "assume reg[1bv32] == 65535bv16;\n",
            "assume reg[2bv32] == 65535bv16;\n",
            "procedure foo() returns()\n",
            "{\n",
            "  x := reg.read(reg, idx);\n",
            "}\n",
        ]
        _rewrite_forall_bv32_array_inits(lines)
        out = "".join(lines)
        self.assertIn(
            "assume (forall i:bv32 :: ((i != 0bv32) && (i != 1bv32) && (i != 2bv32)) ==> reg[i] == 0bv16);",
            out,
        )
        self.assertNotIn("assume reg[19bv32] == 0bv16;", out)
        self.assertIn("assume reg[0bv32] == 65535bv16;", out)
        self.assertIn("assume reg[2bv32] == 65535bv16;", out)

    def test_eliminates_forall_init_with_bv11_constant_accesses(self) -> None:
        lines = [
            "assume (forall i:bv11 :: reg[i] == 0bv16);\n",
            "assume reg[0bv11] == 0bv16;\n",
            "procedure foo() returns()\n",
            "{\n",
            "  x := reg[0bv11];\n",
            "  reg[0bv11] := y;\n",
            "}\n",
        ]
        _rewrite_forall_bv32_array_inits(lines)
        out = "".join(lines)
        self.assertNotIn("forall i:bv11", out)
        self.assertIn("assume reg[0bv11] == 0bv16;", out)

    def test_keeps_bv11_forall_when_dynamic_index_unbounded(self) -> None:
        lines = [
            "assume (forall i:bv11 :: reg[i] == 0bv16);\n",
            "assume reg[0bv11] == 0bv16;\n",
            "procedure foo() returns()\n",
            "{\n",
            "  x := reg.read(reg, meta.idx);\n",
            "}\n",
        ]
        _rewrite_forall_bv32_array_inits(lines)
        out = "".join(lines)
        self.assertIn("assume (forall i:bv11 :: reg[i] == 0bv16);", out)

    def test_keeps_bv11_forall_when_any_access_is_unbounded(self) -> None:
        lines = [
            "assume (forall i:bv11 :: reg[i] == 0bv16);\n",
            "assume reg[0bv11] == 0bv16;\n",
            "procedure foo() returns()\n",
            "{\n",
            "  x := reg[0bv11];\n",
            "  y := reg.read(reg, meta.idx);\n",
            "}\n",
        ]
        _rewrite_forall_bv32_array_inits(lines)
        out = "".join(lines)
        self.assertIn("assume (forall i:bv11 :: reg[i] == 0bv16);", out)

    def test_eliminates_bv11_forall_from_focused_slot0_shape(self) -> None:
        lines = [
            "assume (forall i:bv11 :: reg_flow_ID[i] == 0bv32);\n",
            "assume reg_flow_ID[0bv11] == 0bv32;\n",
            "assume (forall i:bv11 :: reg_pkt_len_total[i] == 0bv16);\n",
            "assume reg_pkt_len_total[0bv11] == 0bv16;\n",
            "procedure foo() returns()\n",
            "{\n",
            "  assume meta.register_index == 0bv11;\n",
            "  reg_flow_ID[0bv11] := flow;\n",
            "  reg_pkt_len_total[0bv11] := len;\n",
            "}\n",
        ]
        _rewrite_forall_bv32_array_inits(lines)
        out = "".join(lines)
        self.assertNotIn("forall i:bv11", out)
        self.assertIn("assume reg_flow_ID[0bv11] == 0bv32;", out)
        self.assertIn("assume reg_pkt_len_total[0bv11] == 0bv16;", out)

    def test_ignores_unused_inline_register_extern_body_when_inferring_domain(self) -> None:
        lines = [
            "function {:inline true}reg.read(reg_arg:[bv11]bv16, idx:bv11)returns (bv16) {reg_arg[idx]}\n",
            "procedure {:inline 1} reg.write(idx:bv11, value:bv16)\n",
            "  modifies reg;\n",
            "{\n",
            "  reg[idx] := value;\n",
            "}\n",
            "assume (forall i:bv11 :: reg[i] == 0bv16);\n",
            "assume reg[0bv11] == 0bv16;\n",
            "procedure foo() returns()\n",
            "{\n",
            "  reg[0bv11] := y;\n",
            "}\n",
        ]
        _rewrite_forall_bv32_array_inits(lines)
        out = "".join(lines)
        self.assertNotIn("forall i:bv11", out)
        self.assertIn("procedure {:inline 1} reg.write", out)
        self.assertIn("reg[idx] := value;", out)

    def test_uses_register_extern_call_indices_not_formal_body_index(self) -> None:
        lines = [
            "function {:inline true}reg.read(reg_arg:[bv11]bv16, idx:bv11)returns (bv16) {reg_arg[idx]}\n",
            "procedure {:inline 1} reg.write(idx:bv11, value:bv16)\n",
            "  modifies reg;\n",
            "{\n",
            "  reg[idx] := value;\n",
            "}\n",
            "assume (forall i:bv11 :: reg[i] == 0bv16);\n",
            "assume reg[0bv11] == 0bv16;\n",
            "procedure foo() returns()\n",
            "{\n",
            "  x := reg.read(reg, 0bv11);\n",
            "  call reg.write(0bv11, y);\n",
            "}\n",
        ]
        _rewrite_forall_bv32_array_inits(lines)
        out = "".join(lines)
        self.assertNotIn("forall i:bv11", out)
        self.assertIn("x := reg.read(reg, 0bv11);", out)
        self.assertIn("call reg.write(0bv11, y);", out)

    def test_keeps_forall_when_register_extern_call_index_is_unbounded(self) -> None:
        lines = [
            "function {:inline true}reg.read(reg_arg:[bv11]bv16, idx:bv11)returns (bv16) {reg_arg[idx]}\n",
            "assume (forall i:bv11 :: reg[i] == 0bv16);\n",
            "assume reg[0bv11] == 0bv16;\n",
            "procedure foo() returns()\n",
            "{\n",
            "  x := reg.read(reg, meta.idx);\n",
            "}\n",
        ]
        _rewrite_forall_bv32_array_inits(lines)
        out = "".join(lines)
        self.assertIn("assume (forall i:bv11 :: reg[i] == 0bv16);", out)

    def test_register_extern_body_skip_uses_exact_declared_name(self) -> None:
        lines = [
            "function {:inline true}other_reg.read(reg_arg:[bv11]bv16, idx:bv11)returns (bv16) {reg_arg[idx]}\n",
            "procedure {:inline 1} other_reg.write(idx:bv11, value:bv16)\n",
            "  modifies other_reg;\n",
            "{\n",
            "  other_reg[idx] := value;\n",
            "}\n",
            "assume (forall i:bv11 :: reg[i] == 0bv16);\n",
            "assume reg[0bv11] == 0bv16;\n",
            "procedure foo() returns()\n",
            "{\n",
            "  reg[0bv11] := y;\n",
            "}\n",
        ]
        _rewrite_forall_bv32_array_inits(lines)
        out = "".join(lines)
        self.assertNotIn("forall i:bv11", out)
        self.assertIn("other_reg[idx] := value;", out)

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
