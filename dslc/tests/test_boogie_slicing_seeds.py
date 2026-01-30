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
  // Assume-only packet field: must remain declared (i.e., becomes a slicing seed),
  // otherwise the compiled harness would reference an undeclared packet var.
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

        self.assertIn("hdr.h.a", s1_seeds)  # assume-only, but required for well-typedness
        self.assertIn("hdr.h.a", set(plan.required_packet_vars.get("s1", [])))


if __name__ == "__main__":
    unittest.main()
