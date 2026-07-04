from __future__ import annotations

import unittest

from dslc.cli.smoke import _structural_smoke_check


class TestSmokeStructuralCheck(unittest.TestCase):
    def test_concurrent_harness_does_not_require_global_main_procedure(self) -> None:
        bpl = """
procedure ULTIMATE.start() returns()
{
  atomic {
    call init();
  }
  fork 0 EnvThread();
  fork 1 s1Thread();
}

procedure s1_mainProcedure()
{
}
"""

        self.assertEqual(_structural_smoke_check(bpl_text=bpl, harness="concurrent"), [])

    def test_sequential_harness_requires_main_procedure(self) -> None:
        bpl = """
procedure ULTIMATE.start() returns()
{
  call mainProcedure();
}
"""

        self.assertIn(
            "missing procedure mainProcedure()",
            _structural_smoke_check(bpl_text=bpl, harness="sequential"),
        )

    def test_sequential_harness_accepts_main_procedure(self) -> None:
        bpl = """
procedure ULTIMATE.start() returns()
{
  call mainProcedure();
}

procedure mainProcedure() returns()
{
}
"""

        self.assertEqual(_structural_smoke_check(bpl_text=bpl, harness="sequential"), [])


if __name__ == "__main__":
    unittest.main()
