import unittest

from dslc.transform.boogie.closure_simplify import simplify_deterministic_closure_blocks
from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text


class TestClosureHarnessSimplify(unittest.TestCase):
    def test_closure_folds_deterministic_mailbox_and_false_only_event_flags(self) -> None:
        out = instrument_bpl_text(
            bpl_text=_program(flag_true_write=False, callee_modifies_flag=False),
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="r",
            accel_regs=["r"],
            index_value=0,
        )
        main_body = _proc_body(out, "mainProcedure")

        self.assertNotIn("if (inbox_count < 1)", main_body)
        self.assertNotIn("if (inbox_count > 0)", main_body)
        self.assertNotIn("if (sw_p4b_clone_i2e)", main_body)
        self.assertIn("call sw_mainProcedure();", main_body)

    def test_closure_keeps_event_flag_branch_across_call_even_without_true_write(self) -> None:
        out = instrument_bpl_text(
            bpl_text=_program(flag_true_write=False, callee_modifies_flag=True),
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="r",
            accel_regs=["r"],
            index_value=0,
        )
        main_body = _proc_body(out, "mainProcedure")

        self.assertIn("if (sw_p4b_clone_i2e)", main_body)

    def test_closure_does_not_insert_asserts_inside_same_line_else_branch(self) -> None:
        out = instrument_bpl_text(
            bpl_text=_two_phase_env_program(),
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="r",
            accel_regs=["r"],
            index_value=0,
        )

        assert_idx = out.index("call __wraparound_closure_assert_all")
        update_idx = out.index("call sw_mainProcedure();")
        self.assertGreater(assert_idx, update_idx)

    def test_closure_simplify_preserves_same_line_else_block_structure(self) -> None:
        lines = _same_line_else_mainprocedure().splitlines(keepends=True)
        simplify_deterministic_closure_blocks(
            lines,
            var_types={
                "dsl_pump_mode": "bool",
                "dsl_suffix_sent": "bool",
                "packet_kind": "int",
            },
        )
        main_body = _proc_body("".join(lines), "mainProcedure")

        self.assertIn("call sw_mainProcedure();", main_body)
        self.assertEqual(main_body.count("{"), main_body.count("}"))


def _program(*, flag_true_write: bool, callee_modifies_flag: bool) -> str:
    maybe_true = "  sw_p4b_clone_i2e := true;\n" if flag_true_write else ""
    callee_modifies = "sw_p4b_clone_i2e, r" if callee_modifies_flag else "r"
    return (
        """
var procurator_phase: int;
var inbox_count: int;
var pkt_external: bool;
var sw_p4b_clone_i2e: bool;
var r:[bv32]bv8;

function add.bv8(x:bv8, y:bv8) returns (bv8);

procedure sw_mainProcedure()
  modifies __CALLEE_MODIFIES__;
{
__MAYBE_TRUE__  r[0bv32] := add.bv8(r[0bv32], 1bv8);
}

procedure main() returns()
  modifies procurator_phase, inbox_count, pkt_external, sw_p4b_clone_i2e, r;
{
  if (procurator_phase == 0) {
    if (inbox_count < 1) {
      assume inbox_count < 1;
      pkt_external := true;
      inbox_count := inbox_count + 1;
    }
  } else if (procurator_phase == 1) {
    if (inbox_count > 0) {
      assume inbox_count > 0;
      inbox_count := inbox_count - 1;
      call sw_mainProcedure();
      if (sw_p4b_clone_i2e) {
        assume inbox_count < 1;
        pkt_external := false;
        inbox_count := inbox_count + 1;
      }
      sw_p4b_clone_i2e := false;
    }
  }
  if (procurator_phase == 1) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, inbox_count, pkt_external, sw_p4b_clone_i2e, r;
{
  inbox_count := 0;
  pkt_external := false;
  sw_p4b_clone_i2e := false;
  procurator_phase := 0;
  while (true) {
    call main();
  }
}
"""
        .replace("__MAYBE_TRUE__", maybe_true)
        .replace("__CALLEE_MODIFIES__", callee_modifies)
    )


def _two_phase_env_program() -> str:
    return """
var procurator_phase: int;
var dsl_pump_mode: bool;
var dsl_suffix_sent: bool;
var packet_kind: int;
var r:[bv32]bv8;

function add.bv8(x:bv8, y:bv8) returns (bv8);

procedure sw_mainProcedure()
  modifies r;
{
  r[0bv32] := add.bv8(r[0bv32], 1bv8);
}

procedure main() returns()
  modifies procurator_phase, dsl_suffix_sent, packet_kind, r;
{
  if (procurator_phase == 0) {
    if (dsl_pump_mode) {
      packet_kind := 1;
    } else {
      if (!dsl_suffix_sent) {
        packet_kind := 2;
        dsl_suffix_sent := true;
      } else {
        packet_kind := 3;
      }
    }
    procurator_phase := 1;
  } else if (procurator_phase == 1) {
    call sw_mainProcedure();
    procurator_phase := 0;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, dsl_pump_mode, dsl_suffix_sent, packet_kind, r;
{
  dsl_pump_mode := true;
  dsl_suffix_sent := false;
  procurator_phase := 0;
  while (true) {
    call main();
  }
}
"""


def _same_line_else_mainprocedure() -> str:
    return """
var dsl_pump_mode: bool;
var dsl_suffix_sent: bool;
var packet_kind: int;

procedure sw_mainProcedure()
{
}

procedure mainProcedure() returns()
  modifies dsl_pump_mode, dsl_suffix_sent, packet_kind;
{
  dsl_pump_mode := true;
  dsl_suffix_sent := false;
  if (dsl_pump_mode) {
    packet_kind := 1;
  } else {
    if (!dsl_suffix_sent) {
      packet_kind := 2;
      dsl_suffix_sent := true;
    } else {
      packet_kind := 3;
    }
  }
  call sw_mainProcedure();
}
"""


def _proc_body(text: str, proc_name: str) -> str:
    marker = f"procedure {proc_name}()"
    start = text.index(marker)
    body_start = text.index("\n{", start) + 1
    depth = 0
    for idx in range(body_start, len(text)):
        if text[idx] == "{":
            depth += 1
        elif text[idx] == "}":
            depth -= 1
            if depth == 0:
                return text[body_start + 1 : idx]
    raise AssertionError(f"procedure body not found: {proc_name}")


if __name__ == "__main__":
    unittest.main()
