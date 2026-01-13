import tempfile
import unittest
from pathlib import Path

from dslc.compiler import compile_spec_text


class TestBoogieBackendSequentialHarness(unittest.TestCase):
    def _compile(self, spec: str, **kwargs: object) -> str:
        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            outp = compile_spec_text(spec_text=spec, backend="boogie", out=out_bpl, **kwargs)
            return outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

    def test_sequential_harness_is_unbounded_and_no_step_trace(self) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{ external_input = true; }}
global {{ queue_capacity = 1; assert {{ true; }}; }}
"""
        text = self._compile(spec, boogie_harness="sequential")

        self.assertIn("procedure ULTIMATE.start()", text)
        self.assertIn("procedure mainProcedure()", text)
        self.assertRegex(text, r"while\s*\(true\)\s*\{")
        self.assertNotIn("procurator_max_steps", text)
        self.assertNotIn("trace_node_id", text)

    def test_concurrent_harness_smoke_no_trace_refinement(self) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{ external_input = true; }}
global {{ queue_capacity = 1; assert {{ true; }}; }}
"""
        text = self._compile(spec, boogie_harness="concurrent")
        self.assertIn("procedure ULTIMATE.start()", text)
        self.assertIn("fork", text)
        self.assertIn("atomic", text)
        self.assertNotIn("trace_node_id", text)
        self.assertNotIn("refine_force_node", text)


if __name__ == "__main__":
    unittest.main()
