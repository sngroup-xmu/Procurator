from __future__ import annotations

import unittest

from dslc.transform.wraparound_analyze import WraparoundStage
from dslc.transform.wraparound_instrument import instrument_bpl_text


class TestReassertAfterHavoc(unittest.TestCase):
    def test_reassert_handles_parenthesized_equalities(self) -> None:
        # Regression: extra_assumes often arrive as "(x == c)" strings (e.g., env completion).
        # We must re-assert those after `havoc x;`, otherwise the constraint is immediately lost.
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

        out = instrument_bpl_text(
            bpl_text=base_text,
            stage=WraparoundStage.CONFIRM,
            pump_reg="r",
            accel_regs=("r",),
            index_value=0,
            index_expr=None,
            proj_vars=("procurator_phase",),
            cutpoint_cond="(procurator_phase == 0)",
            step_op="add",
            step_delta=1,
            extra_assumes=["(io_hdr.udp_hdr.srcPort == 0bv16)"],
        )

        self.assertIn("havoc io_hdr.udp_hdr.srcPort;", out)
        self.assertIn("assume(io_hdr.udp_hdr.srcPort == 0bv16);", out)
        self.assertLess(out.index("havoc io_hdr.udp_hdr.srcPort;"), out.index("assume(io_hdr.udp_hdr.srcPort == 0bv16);"))


if __name__ == "__main__":
    unittest.main()

