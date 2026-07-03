import unittest

from dslc.transform.wraparound_analyze import analyze_bpl_for_wraparound
from dslc.transform.wraparound_common import WraparoundStage


class TestWraparoundAnalyzeRegisterTypedefs(unittest.TestCase):
    def test_analyze_accepts_typedef_index_type(self) -> None:
        bpl = "\n".join(
            [
                "type idx_t = bv32;",
                "var reg:[idx_t]bv8;",
                "",
            ]
        )
        cfg = analyze_bpl_for_wraparound(
            bpl_text=bpl,
            pump_reg="reg",
            accel_regs=[],
            stage=WraparoundStage.CONFIRM,
        )
        self.assertEqual(cfg.pump_target.index_width, 32)
        self.assertEqual(cfg.pump_target.elem_width, 8)

    def test_analyze_accepts_typedef_index_and_elem_types(self) -> None:
        bpl = "\n".join(
            [
                "type idx_t = bv32;",
                "type elem_t = bv16;",
                "var reg:[idx_t]elem_t;",
                "",
            ]
        )
        cfg = analyze_bpl_for_wraparound(
            bpl_text=bpl,
            pump_reg="reg",
            accel_regs=[],
            stage=WraparoundStage.CONFIRM,
        )
        self.assertEqual(cfg.pump_target.index_width, 32)
        self.assertEqual(cfg.pump_target.elem_width, 16)
