import unittest

from dslc.transform.wraparound_stages import _rewrite_forall_bv32_array_inits


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
