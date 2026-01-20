import tempfile
import unittest
from pathlib import Path

from dslc.compiler import compile_spec_text


class TestBoogieHarnessSinkNodes(unittest.TestCase):
    def test_sink_node_runs_at_enqueue_time(self) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import t from "{bpl.as_posix()}";
import s1 from "{bpl.as_posix()}";

topology {{
  link t -> s1 1;
}}

node t {{
  external_input = true;
}}

node s1 {{
  sink = true;
  bool Seen = false;
  Seen = true;
}}

global {{
  queue_capacity = 1;
  assert {{ true; }};
}}
"""

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            outp = compile_spec_text(spec_text=spec, backend="boogie", out=out_bpl, boogie_harness="concurrent")
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        # Sink nodes should not be scheduled: no inbox_count var and no harness thread.
        self.assertNotIn("var s1_inbox_count", text)
        self.assertNotIn("procedure s1Thread()", text)

        # The sink node's DSL statements should appear in the enqueue procedure.
        self.assertIn("procedure t__enqueue_s1()", text)
        self.assertIn("Sink/observer node: execute DSL instrumentation at enqueue-time", text)
        self.assertIn("s1_dsl_Seen := true;", text)


if __name__ == "__main__":
    unittest.main()

