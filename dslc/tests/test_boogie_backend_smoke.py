import re
import tempfile
import unittest
from pathlib import Path

from dslc.compiler import compile_spec_text


class TestBoogieBackendSmoke(unittest.TestCase):
    def test_boogie_harness_smoke(self) -> None:
        # Use a repo-shipped .bpl as input to avoid depending on building a translator here.
        bpl = Path(
            "/mnt/e/p4-verify/Procurator/argo/code/Translator/feature-testcases/bool/out.bpl"
        )
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
  int Counter = 0;
  Counter += 1;
  assert {{ Counter >= 1; }};
}}
global {{
  queue_capacity = 2;
  int G = 41;
  G += 1;
  assert {{ G == 42; }};
}}
"""
        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            outp = compile_spec_text(spec_text=spec, backend="boogie", out=out_bpl)
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        self.assertRegex(text, r"\bprocedure\s+ULTIMATE\.start\s*\(")
        self.assertRegex(text, r"\bfork\b")
        self.assertRegex(text, r"\batomic\b")
        self.assertRegex(text, r"\bvar\s+s1_inbox_count\b")
        # DSL locals are modeled as Boogie globals
        self.assertRegex(text, r"\bvar\s+dsl_G\s*:\s*int;")
        self.assertRegex(text, r"\bvar\s+s1_dsl_Counter\s*:\s*int;")
        # Initialization should occur in ULTIMATE.start
        self.assertRegex(text, r"\bdsl_G\s*:=\s*41;")
        self.assertRegex(text, r"\bs1_dsl_Counter\s*:=\s*0;")
        # Per-pass assignment should be emitted in the node thread
        self.assertRegex(text, r"\bs1_dsl_Counter\s*:=\s*s1_dsl_Counter\s*\+\s*1;")


if __name__ == "__main__":
    unittest.main()

