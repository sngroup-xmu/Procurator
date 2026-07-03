import unittest

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
