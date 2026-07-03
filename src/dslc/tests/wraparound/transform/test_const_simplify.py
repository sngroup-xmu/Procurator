from __future__ import annotations

import unittest

from dslc.transform.boogie.const_simplify import simplify_bv_constant_assignments


class TestConstSimplify(unittest.TestCase):
    def test_does_not_carry_constants_across_procedure_boundaries(self) -> None:
        lines = [
            "var x:bv16;\n",
            "procedure first()\n",
            "{\n",
            "  x := 512bv16;\n",
            "}\n",
            "procedure second()\n",
            "{\n",
            "  x := x;\n",
            "}\n",
        ]

        simplify_bv_constant_assignments(lines, var_types={"x": "bv16"})

        self.assertIn("  x := x;\n", lines)

    def test_does_not_carry_constants_across_branch_boundaries(self) -> None:
        lines = [
            "var x:bv16;\n",
            "procedure main()\n",
            "{\n",
            "  x := 5bv16;\n",
            "  if (x == 5bv16) {\n",
            "    x := 6bv16;\n",
            "  }\n",
            "  x := x;\n",
            "}\n",
        ]

        simplify_bv_constant_assignments(lines, var_types={"x": "bv16"})

        self.assertIn("  x := x;\n", lines)


if __name__ == "__main__":
    unittest.main()
