import unittest

from dslc.workflows.wraparound_cegis import _unroll_confirm_like_mainprocedure


class TestWraparoundCegisUnrollKeepsForallInits(unittest.TestCase):
    def test_confirm_like_unroll_does_not_eliminate_forall_register_init(self) -> None:
        # This is a regression test: eliminating `forall i :: reg[i] == 0` can make
        # confirm/enable_check vacuously SAFE or introduce spurious behaviors when
        # non-zero indices are accessed.
        src = """\
var procurator_step: int;
var reg: [bv32]bv32;

procedure main() returns() { }

procedure mainProcedure() returns()
  modifies procurator_step;
{
  // initialize P4 registers (default 0)
  assume (forall i:bv32 :: reg[i] == 0bv32);
  procurator_step := 0;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""
        out, _steps = _unroll_confirm_like_mainprocedure(bpl_text=src, requested_steps=1, deterministic_period=None)
        self.assertIn("forall i:bv32 :: reg[i] == 0bv32", out)


if __name__ == "__main__":
    unittest.main()

