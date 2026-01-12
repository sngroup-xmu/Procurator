import re
import tempfile
import unittest
from pathlib import Path

from dslc.compiler import compile_spec_text


class TestBoogieBackendRefineTrace(unittest.TestCase):
    def _compile(self, spec: str, **kwargs: object) -> str:
        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            outp = compile_spec_text(spec_text=spec, backend="boogie", out=out_bpl, **kwargs)
            return outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

    def test_sequential_refine_trace_forces_consumption_and_guards_asserts(self) -> None:
        bpl = Path("/mnt/e/p4-verify/Procurator/argo/code/Translator/feature-testcases/bool/out.bpl")
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
import s2 from "{bpl.as_posix()}";

topology {{
  link s1 -> s2 ALL;
}}

node s1 {{
  external_input = true;
}}

node s2 {{
  assert {{ true; }};
}}

global {{
  queue_capacity = 1;
}}
"""
        text = self._compile(spec, boogie_harness="sequential", refine_trace=True)

        self.assertRegex(text, r"\bvar\s+refine_force_node\s*:\s*int;")
        self.assertRegex(text, r"\brefine_force_node\s*:=\s*0;")
        self.assertRegex(text, r"\bprocedure\s+s1__enqueue_s2\s*\(\)\s*returns\(\)")
        # Node ids are 1-based (s1=1, s2=2) in the sequential scheduler.
        self.assertRegex(text, r"\brefine_force_node\s*:=\s*2;")
        # The scheduler must clear the force flag when running the forced node ingress/pass.
        self.assertRegex(text, r"assume\s+refine_force_node\s*==\s*2;")
        self.assertRegex(text, r"\brefine_force_node\s*:=\s*0;")
        # Assertions are only checked once all forced enqueues have been consumed.
        self.assertRegex(text, r"assume\s+refine_force_node\s*==\s*0;")

    def test_concurrent_harness_does_not_emit_step_indexed_trace(self) -> None:
        # Concurrent harness intentionally omits per-step trace arrays; ensure no stale trace code sneaks in.
        bpl = Path("/mnt/e/p4-verify/Procurator/argo/code/Translator/feature-testcases/bool/out.bpl")
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
import s2 from "{bpl.as_posix()}";

topology {{
  link s1 -> s2 ALL;
}}

node s1 {{ external_input = true; }}
node s2 {{ }}

global {{ queue_capacity = 1; }}
"""
        text = self._compile(spec, boogie_harness="concurrent", refine_trace=True)

        self.assertRegex(text, r"\bprocedure\s+ULTIMATE\.start\s*\(")
        self.assertRegex(text, r"\bfork\b")
        self.assertNotRegex(text, r"\btrace_node_id\b")
        self.assertNotRegex(text, r"\bprocurator_step\b")
        self.assertRegex(text, r"\brefine_force_node\s*:=\s*0;")

        # Ensure we only initialize pending egress counters once (regression for a previous duplication).
        self.assertEqual(len(re.findall(r"\bs1_egress_count\s*:=\s*0;", text)), 1)


if __name__ == "__main__":
    unittest.main()

