import tempfile
import unittest
from pathlib import Path

from dslc.compiler import compile_spec_text


class TestBoogieHarnessMaxSteps(unittest.TestCase):
    def _compile(self, spec: str, **kwargs: object) -> str:
        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            outp = compile_spec_text(spec_text=spec, backend="boogie", out=out_bpl, **kwargs)
            return outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

    def test_sequential_harness_honors_max_steps(self) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{ external_input = true; }}
global {{ queue_capacity = 1; max_steps = 3; assert {{ true; }}; }}
"""
        text = self._compile(spec, boogie_harness="sequential")
        # Small max_steps should be unrolled (no scheduler loop).
        self.assertNotRegex(text, r"while\s*\(procurator_step\s*<\s*3\)\s*\{")
        self.assertEqual(text.count("call main();"), 3)

    def test_concurrent_harness_honors_max_steps(self) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{ external_input = true; }}
global {{ queue_capacity = 1; max_steps = 3; assert {{ true; }}; }}
"""
        text = self._compile(spec, boogie_harness="concurrent")
        self.assertIn("fork", text)
        self.assertIn("var procurator_lock: int;", text)
        self.assertIn("var procurator_step: int;", text)
        self.assertIn("procurator_step := 0;", text)
        self.assertRegex(text, r"while\s*\(procurator_step\s*<\s*3\)\s*\{")
        self.assertIn("procurator_step := procurator_step + 1;", text)


if __name__ == "__main__":
    unittest.main()
