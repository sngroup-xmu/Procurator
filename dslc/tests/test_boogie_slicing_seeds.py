import unittest
from pathlib import Path

from dslc.backends.boogie_seeds import build_slicing_plan
from dslc.speclang.parse import parse_model


class TestBoogieSlicingSeeds(unittest.TestCase):
    def test_seed_policy_and_propagation(self) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec_text = f'''
import s1 from "{bpl.as_posix()}";
import s2 from "{bpl.as_posix()}";

topology {{
  link s1 -> s2;
}}

node s1 {{
  external_input = true;
  // Assume-only packet field: should be tracked as required packet var, but
  // should not become a slicing seed (avoid over-retaining unrelated logic).
  assume {{ hdr.h.a == 1; }};
}}

node s2 {{
  external_input = false;
  // Property-relevant on-wire header: should seed s2 and propagate to s1.
  assert {{ hdr.h.b == hdr.h.b; }};
  // Node-local metadata: should NOT propagate backward.
  assert {{ meta.x == meta.x; }};
}}

global {{
}}
'''

        spec = parse_model(spec_text)
        plan = build_slicing_plan(spec, enable_slicing=True)

        s1_seeds = set(plan.slicing_vars.get("s1", []))
        s2_seeds = set(plan.slicing_vars.get("s2", []))

        self.assertIn("standard_metadata.egress_port", s1_seeds)
        self.assertIn("standard_metadata.egress_port", s2_seeds)

        self.assertIn("hdr.h.b", s2_seeds)
        self.assertIn("hdr.h.b", s1_seeds)  # propagated along s1 -> s2

        self.assertIn("meta.x", s2_seeds)
        self.assertNotIn("meta.x", s1_seeds)  # not on-wire

        self.assertNotIn("hdr.h.a", s1_seeds)  # assume-only; declaration tracked separately
        self.assertIn("hdr.h.a", set(plan.required_packet_vars.get("s1", [])))

    def test_disable_control_seeds_respected(self) -> None:
        spec_text = r'''
import s1 from "Procurator/argo/code/Translator/feature-testcases/bool/out.bpl";

topology {}

node s1 {
  assert { hdr.h.a == hdr.h.a; };
}

global {}
'''
        spec = parse_model(spec_text)

        with_control = build_slicing_plan(spec, enable_slicing=True, keep_control_seeds=True)
        without_control = build_slicing_plan(spec, enable_slicing=True, keep_control_seeds=False)

        seeds_with = set(with_control.slicing_vars.get("s1", []))
        seeds_without = set(without_control.slicing_vars.get("s1", []))

        self.assertIn("p4b_recirculate", seeds_with)
        self.assertIn("p4b_clone_i2i", seeds_with)
        self.assertNotIn("p4b_recirculate", seeds_without)
        self.assertNotIn("p4b_clone_i2i", seeds_without)
        self.assertIn("hdr.h.a", seeds_without)


if __name__ == "__main__":
    unittest.main()
