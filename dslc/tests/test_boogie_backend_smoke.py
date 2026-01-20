import re
import tempfile
import unittest
from pathlib import Path

from dslc.compiler import compile_spec_text


class TestBoogieBackendSmoke(unittest.TestCase):
    def test_boogie_harness_smoke(self) -> None:
        # Use a repo-shipped .bpl as input to avoid depending on building a translator here.
        repo_root = Path(__file__).resolve().parents[2]
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
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

    def test_concurrent_harness_is_stutter_free(self) -> None:
        # Regression/performance: avoid encoding explicit “do nothing” steps with
        # `if (*) { ... }` wrappers inside thread loops. These stuttering steps
        # introduce always-enabled self-loops that can make TraceAbstraction
        # diverge (even when the system is logically bounded via max_steps).
        repo_root = Path(__file__).resolve().parents[2]
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
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

        # With a single inject target and k==1, there should be no `if (*)` in either thread.
        env_start = text.find("procedure EnvThread()")
        self.assertNotEqual(env_start, -1)
        env_end = text.find("procedure s1Thread()", env_start)
        self.assertNotEqual(env_end, -1)
        env_body = text[env_start:env_end]
        self.assertNotIn("if (*)", env_body)

        thr_start = env_end
        thr_end = text.find("procedure ULTIMATE.start()", thr_start)
        self.assertNotEqual(thr_end, -1)
        thr_body = text[thr_start:thr_end]
        self.assertNotIn("if (*)", thr_body)

    def test_concurrent_harness_two_slot_inbox_k2(self) -> None:
        # Regression: for queue_capacity==2 we must materialize two inbox mailboxes and
        # actually load/dequeue them in the node thread (otherwise bugs that need two
        # pending packets become unreachable).
        repo_root = Path(__file__).resolve().parents[2]
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
  env {{
    // Ensure DSL globals can be modified in EnvThread without Boogie type errors.
    phase = phase + 1;
  }}
}}
global {{
  queue_capacity = 2;
  int phase = 0;
  assert {{ phase >= 0; }};
}}
"""
        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            outp = compile_spec_text(spec_text=spec, backend="boogie", out=out_bpl, boogie_harness="concurrent")
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        # Two-slot inbox mailboxes are declared for on-wire vars.
        self.assertRegex(text, r"\bvar\s+s1_mb0_hdr\.ipv4\.dstAddr\b")
        self.assertRegex(text, r"\bvar\s+s1_mb1_hdr\.ipv4\.dstAddr\b")

        # EnvThread must list DSL globals it modifies.
        self.assertRegex(text, r"(?s)procedure EnvThread\(\) returns\(\)\s*modifies\b.*\bdsl_phase\b")
        # ULTIMATE.start must also cover vars modified by forked procedures.
        self.assertRegex(text, r"(?s)procedure ULTIMATE\.start\(\) returns\(\)\s*modifies\b.*\bdsl_phase\b")

        # Node thread must load and shift a mailbox slot when dequeueing.
        self.assertRegex(
            text,
            r"(?s)procedure s1Thread\(\) returns\(\).*?s1_hdr\.ipv4\.dstAddr := s1_mb0_hdr\.ipv4\.dstAddr;",
        )
        self.assertRegex(
            text,
            r"(?s)procedure s1Thread\(\) returns\(\).*?s1_mb0_hdr\.ipv4\.dstAddr := s1_mb1_hdr\.ipv4\.dstAddr;",
        )


if __name__ == "__main__":
    unittest.main()
