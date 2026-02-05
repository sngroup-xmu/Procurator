import unittest

from dslc.backends.boogie_registers import collect_register_arrays, instrument_register_writes


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

