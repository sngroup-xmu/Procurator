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

    def test_spec_max_steps_is_ignored_by_default(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{ external_input = true; }}
global {{ queue_capacity = 1; max_steps = 3; assert {{ true; }}; }}
"""
        text = self._compile(spec, boogie_harness="sequential")
        self.assertIn("var procurator_step: int;", text)
        self.assertRegex(text, r"while\s*\(true\)\s*\{")
        self.assertNotIn("while (procurator_step < 3)", text)

    def test_spec_max_steps_is_explicit_benchmark_knob(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{ external_input = true; }}
global {{ queue_capacity = 1; max_steps = 3; assert {{ true; }}; }}
"""
        text = self._compile(spec, boogie_harness="sequential", honor_spec_max_steps=True)
        self.assertIn("var procurator_step: int;", text)
        self.assertNotRegex(text, r"while\s*\(true\)\s*\{")
        if "while (procurator_step < 3)" not in text:
            self.assertEqual(text.count("call main();"), 3)

    def test_sequential_harness_honors_cli_max_steps(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{ external_input = true; }}
global {{ queue_capacity = 1; assert {{ true; }}; }}
"""
        text = self._compile(spec, boogie_harness="sequential", max_steps=3)
        self.assertIn("var procurator_step: int;", text)
        # For small bounds, the sequential harness may unroll `call main();` for faster bug-finding.
        if "while (procurator_step < 3)" not in text:
            self.assertEqual(text.count("call main();"), 3)

    def test_concurrent_harness_honors_cli_max_steps(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{ external_input = true; }}
global {{ queue_capacity = 1; assert {{ true; }}; }}
"""
        text = self._compile(spec, boogie_harness="concurrent", max_steps=3)
        self.assertIn("fork", text)
        self.assertIn("var procurator_lock: int;", text)
        self.assertIn("var procurator_step: int;", text)
        self.assertRegex(text, r"while\s*\(procurator_step\s*<\s*3\)\s*\{")
        self.assertIn("procurator_step := procurator_step + 1;", text)


if __name__ == "__main__":
    unittest.main()
