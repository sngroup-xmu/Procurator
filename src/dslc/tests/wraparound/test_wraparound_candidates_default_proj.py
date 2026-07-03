import unittest


from dslc.analysis.wraparound_candidates import infer_wraparound_candidates


class TestWraparoundCandidatesDefaultProj(unittest.TestCase):
    def test_global_asserts_candidate_has_default_proj_vars(self) -> None:
        # Minimal Boogie prelude with the vars the analyzer looks for.
        bpl = "\n".join(
            [
                "var procurator_phase: int;",
                "var s1_inbox_count: int;",
                "var s2_inbox_count: int;",
                "var s1_sequence_reg: [bv32]bv16;",
                "var s2_sequence_reg: [bv32]bv16;",
            ]
        )

        spec = """
import s1 from "dummy.p4";
import s2 from "dummy.p4";

topology { link s1 -> s2 ALL; }

global {
  assert { s1_sequence_reg_0[0] >= s2_sequence_reg_0[0]; };
}
""".strip()

        cands = infer_wraparound_candidates(spec_text=spec, bpl_text=bpl, meta_by_node=None)
        self.assertEqual(len(cands), 1)
        cand = cands[0]

        # Conservative defaults: keep scheduler bookkeeping stable across pump rounds.
        self.assertIn("procurator_phase", cand.proj_vars)
        self.assertIn("s1_inbox_count", cand.proj_vars)
        self.assertIn("s2_inbox_count", cand.proj_vars)


if __name__ == "__main__":
    unittest.main()
