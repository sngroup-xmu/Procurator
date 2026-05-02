import re
import tempfile
import unittest
from pathlib import Path

from dslc.compiler import compile_spec_text


class TestBoogieHarnessSequentialDslStatements(unittest.TestCase):
    def test_sequential_harness_emits_node_pass_dsl_statements(self) -> None:
        # Regression: sequential harness must execute per-pass DSL statements for single-stage nodes.
        # Otherwise, specs that instrument progress via DSL locals/globals (e.g., timer/pending bugs)
        # become unreachable and may be incorrectly proved SAFE.
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
host h {{
  connect s1;
  env {{
    hdr.ipv4.dstAddr = 0;
  }}
}}
node s1 {{
  external_input = false;
  int Counter = 0;
  Counter += 1;
}}
global {{
  env_thread = false;
  host_eager = true;
  queue_capacity = 1;
  max_steps = 4;
  assert {{ true; }};
}}
"""
        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            outp = compile_spec_text(
                spec_text=spec,
                backend="boogie",
                out=out_bpl,
                boogie_harness="sequential",
                pipeline_two_stage=False,  # force single-stage node-pass steps
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        # The per-pass assignment must be inside the node-pass step (single-stage), before calling s1_mainProcedure.
        # We don't anchor on exact indentation, just enforce ordering.
        i = text.find("procedure main()")
        self.assertNotEqual(i, -1)
        main_body = text[i:]
        # Find the node_pass block.
        # Use [\s\S] to match across newlines without relying on DOTALL flags.
        m = re.search(r"// node pass -> s1[\s\S]*?call s1_mainProcedure\(\);", main_body)
        self.assertIsNotNone(m)
        block = m.group(0)
        self.assertIn("s1_dsl_Counter := s1_dsl_Counter + 1;", block)
