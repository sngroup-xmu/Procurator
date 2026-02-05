import unittest

from dslc.analysis.wraparound_candidates import infer_wraparound_candidates


class TestWraparoundCandidateGating(unittest.TestCase):
    def test_require_meta_step_filters_global_assert_candidates(self) -> None:
        # Minimal spec: global assert references a reg slot, so the "global_asserts" inference triggers.
        spec_text = """
import s1 from "x.p4";
topology {}
global {
  assert { s1_sequence_reg_0[0] >= s1_sequence_reg_0[0]; };
}
"""

        # Minimal Boogie text: types are only used when inferring from meta updates; keep empty here.
        bpl_text = ""

        # Empty meta: no monotone step info available.
        cands = infer_wraparound_candidates(
            spec_text=spec_text,
            bpl_text=bpl_text,
            meta_by_node={},
            require_meta_step_for_global_asserts=True,
        )
        self.assertEqual(cands, [])

        # If we do not require meta, we accept the "global_asserts" candidate (legacy/force mode).
        cands2 = infer_wraparound_candidates(
            spec_text=spec_text,
            bpl_text=bpl_text,
            meta_by_node={},
            require_meta_step_for_global_asserts=False,
        )
        self.assertEqual(len(cands2), 1)
        self.assertEqual(cands2[0].reason, "global_asserts")

    def test_meta_candidates_selected_via_driver_dependency(self) -> None:
        """
        Regression: functional wraparound specs may not mention the counter register
        in the global assertion (it is a driver). We should still infer candidates
        when the counter influences an observed variable in Boogie.
        """

        spec_text = """
import leaf from "dummy.p4";
topology {}
global {
  assert { leaf_hdr_eg.frequency_hdr.frequency != 0; };
}
"""

        # Minimal Boogie program: observed var depends on the counter reg via a read.
        bpl_text = "\n".join(
            [
                "var leaf_hdr_eg.frequency_hdr.frequency: bv32;",
                "var leaf_cache_frequency_reg: [bv32]bv32;",
                "procedure LeafIngress() {",
                "  leaf_hdr_eg.frequency_hdr.frequency := leaf_cache_frequency_reg[0bv32];",
                "}",
            ]
        )

        meta_by_node = {
            "leaf": {
                "wraparound": {
                    "updates": [
                        {
                            "reg": "cache_frequency_reg",
                            "value_var": "cache_frequency_md.frequency",
                            "op": "add",
                            "delta_is_const": True,
                            "delta_const": 1,
                            "idx_const": 7,
                        }
                    ]
                }
            }
        }

        cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=bpl_text, meta_by_node=meta_by_node)
        self.assertTrue(cands, "should infer a wraparound candidate from meta updates")
        self.assertEqual(cands[0].pump_reg, "leaf_cache_frequency_reg")
