import tempfile
import unittest
from pathlib import Path

from dslc.compiler import compile_spec_file


class TestBoogieTwoStageSnapshotSmoke(unittest.TestCase):
    def test_two_stage_snapshot_extends_modifies(self) -> None:
        """
        Regression test for the two-stage ingress/egress scheduling mode:

        When ingress/egress are executed as separate steps, the harness swaps packet
        globals from a per-node "egress mailbox". That swap/restore writes packet
        globals that may *not* appear in P4B's mainProcedure modifies list (and may
        be pruned out of env inputs). The harness must still include them in the
        thread/main modifies sets, otherwise Ultimate reports TypeErrorResult.
        """

        repo_root = Path(__file__).resolve().parents[2]
        router_bpl = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "Translator"
            / "feature-testcases"
            / "pathCondition"
            / "simple-router.bpl"
        )
        if not router_bpl.exists():
            self.skipTest("missing simple-router.bpl testcase")

        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            spec_path = tmp / "two_stage.prop"
            out_bpl = tmp / "two_stage.bpl"
            work_dir = tmp / "two_stage.work"

            spec_path.write_text(
                f"""
import s1 from "{router_bpl}";

topology {{}}

node s1 {{
  external_input = true;
}}

global {{
  queue_capacity = 1;
  assert {{
    // trivial property; this test only checks harness well-formedness
    s1_drop == s1_drop;
  }};
}}
""".lstrip(),
                encoding="utf-8",
            )

            compile_spec_file(
                spec_path=spec_path,
                backend="boogie",
                out=out_bpl,
                p4b_bin=None,  # importing .bpl does not need P4B
                work_dir=work_dir,
                enable_slicing=True,
                prune_env_inputs=True,
                boogie_harness="concurrent",
                pipeline_two_stage=True,
            )

            text = out_bpl.read_text(encoding="utf-8", errors="replace")

            # Two-stage mailboxes are declared.
            self.assertRegex(text, r"(?m)^\s*var s1__eg_hdr\.ipv4\.protocol\s*:\s*bv8\s*;")
            self.assertRegex(text, r"(?m)^\s*var s1__ig_saved_hdr\.ipv4\.protocol\s*:\s*bv8\s*;")
            self.assertIn("Two-stage: swap in the pending egress packet snapshot.", text)

            # Key regression check: swap/restore writes `s1_hdr.ipv4.protocol`, so it must
            # appear in the thread modifies even if the original program does not modify it.
            lines = text.splitlines()
            for i, line in enumerate(lines):
                if line.strip() == "procedure s1Thread() returns()":
                    modifies_line = lines[i + 1]
                    self.assertIn("s1_hdr.ipv4.protocol", modifies_line)
                    break
            else:
                self.fail("missing procedure s1Thread() in generated Boogie")


if __name__ == "__main__":
    unittest.main()
