import unittest

from dslc.backends.boogie_registers import (
    assert_complete_register_write_mirrors,
    collect_register_arrays,
    find_incomplete_register_write_mirrors,
    instrument_register_writes,
)


class TestBoogieRegistersTypedefIndex0(unittest.TestCase):
    def test_register_write_mirror_uses_typed_zero_for_index_alias(self) -> None:
        bpl = "\n".join(
            [
                "type sw_lid_t = bv32;",
                "// sw_Register reg",
                "var reg:[sw_lid_t]bv8;",
                "",
                "procedure {:inline 1} reg.write(sw_index:sw_lid_t, sw_value:bv8)",
                "  modifies reg;",
                "{",
                "  reg[sw_index] := sw_value;",
                "}",
                "",
            ]
        )

        reg_types = collect_register_arrays(bpl, alias="sw")
        out = instrument_register_writes(bpl, reg_types)
        self.assertIn("if (sw_index == 0bv32)", out)

    def test_existing_p4b_register_mirrors_are_not_double_instrumented(self) -> None:
        bpl = "\n".join(
            [
                "type sw_lid_t = bv32;",
                "// sw_Register reg",
                "var reg:[sw_lid_t]bv8;",
                "var reg__last_index: sw_lid_t;",
                "var reg__last_value: bv8;",
                "var reg__wrote_any: bool;",
                "var reg__wrote_index0: bool;",
                "var reg__last0_value: bv8;",
                "",
                "procedure {:inline 1} reg.write(index:sw_lid_t, value:bv8)",
                "  modifies reg, reg__last_index, reg__last_value, reg__wrote_any, reg__wrote_index0, reg__last0_value;",
                "{",
                "  reg[index] := value;",
                "  reg__last_index := index;",
                "  reg__last_value := value;",
                "  reg__wrote_any := true;",
                "  if (index == 0bv32) {",
                "    reg__wrote_index0 := true;",
                "    reg__last0_value := value;",
                "  }",
                "}",
                "",
            ]
        )

        reg_types = collect_register_arrays(bpl, alias="sw")
        out = instrument_register_writes(bpl, reg_types)
        self.assertEqual(out, bpl)

    def test_existing_mirror_decls_without_body_updates_are_instrumented(self) -> None:
        bpl = "\n".join(
            [
                "type sw_lid_t = bv32;",
                "// sw_Register reg",
                "var reg:[sw_lid_t]bv8;",
                "var reg__last_index: sw_lid_t;",
                "var reg__last_value: bv8;",
                "var reg__wrote_any: bool;",
                "var reg__wrote_index0: bool;",
                "var reg__last0_value: bv8;",
                "",
                "procedure {:inline 1} reg.write(sw_index:sw_lid_t, sw_value:bv8)",
                "  modifies reg;",
                "{",
                "  reg[sw_index] := sw_value;",
                "}",
                "",
            ]
        )

        reg_types = collect_register_arrays(bpl, alias="sw")
        out = instrument_register_writes(bpl, reg_types)
        self.assertEqual(out.count("var reg__last_index"), 1)
        self.assertIn("reg__last_index := sw_index;", out)
        self.assertIn("reg__last0_value := sw_value;", out)
        self.assertIn(
            "modifies reg, reg__last_index, reg__last_value, reg__wrote_any, reg__wrote_index0, reg__last0_value;",
            out,
        )

    def test_existing_body_updates_without_modifies_are_repaired_without_duplication(self) -> None:
        bpl = "\n".join(
            [
                "type sw_lid_t = bv32;",
                "// sw_Register reg",
                "var reg:[sw_lid_t]bv8;",
                "var reg__last_index: sw_lid_t;",
                "var reg__last_value: bv8;",
                "var reg__wrote_any: bool;",
                "var reg__wrote_index0: bool;",
                "var reg__last0_value: bv8;",
                "",
                "procedure {:inline 1} reg.write(index:sw_lid_t, value:bv8)",
                "  modifies reg;",
                "{",
                "  reg[index] := value;",
                "  reg__last_index := index;",
                "  reg__last_value := value;",
                "  reg__wrote_any := true;",
                "  if (index == 0bv32) {",
                "    reg__wrote_index0 := true;",
                "    reg__last0_value := value;",
                "  }",
                "}",
                "",
            ]
        )

        reg_types = collect_register_arrays(bpl, alias="sw")
        out = instrument_register_writes(bpl, reg_types)
        self.assertIn(
            "modifies reg, reg__last_index, reg__last_value, reg__wrote_any, reg__wrote_index0, reg__last0_value;",
            out,
        )
        self.assertEqual(out.count("reg__last_index := index;"), 1)
        self.assertEqual(out.count("reg__last0_value := value;"), 1)

    def test_mirror_checker_reports_incomplete_registers_without_patching(self) -> None:
        bpl = "\n".join(
            [
                "type sw_lid_t = bv32;",
                "// sw_Register reg",
                "var reg:[sw_lid_t]bv8;",
                "",
                "procedure {:inline 1} reg.write(sw_index:sw_lid_t, sw_value:bv8)",
                "  modifies reg;",
                "{",
                "  reg[sw_index] := sw_value;",
                "}",
                "",
            ]
        )

        reg_types = collect_register_arrays(bpl, alias="sw")
        self.assertEqual(find_incomplete_register_write_mirrors(bpl, reg_types), ["reg"])
        with self.assertRaisesRegex(ValueError, "Register mirror semantics belong in P4B"):
            assert_complete_register_write_mirrors(bpl, reg_types)
