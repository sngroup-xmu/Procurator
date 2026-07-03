import tempfile
import unittest
from pathlib import Path

from dslc.compiler import compile_spec_file


class TestBoogieTwoStageSnapshotSmoke(unittest.TestCase):
    _MIN_EVENTFUL_BPL = """
type Ref;

var hdr: Ref;
var hdr.ipv4: Ref;
var hdr.ipv4.protocol: bv8;

var standard_metadata.egress_port: bv9;
var standard_metadata.egress_spec: bv9;

var p4b_recirculate: bool;
var p4b_clone_i2e: bool;
var p4b_clone_e2e: bool;
var p4b_clone_i2i: bool;

procedure MyParser() { }
procedure MyVerifyChecksum() { }
procedure MyIngress() { }
procedure MyEgress() modifies p4b_recirculate; { p4b_recirculate := true; }
procedure MyComputeChecksum() { }

procedure main()
  modifies hdr.ipv4.protocol, standard_metadata.egress_port, standard_metadata.egress_spec, p4b_recirculate;
{
  call MyParser();
  call MyVerifyChecksum();
  call MyIngress();
  call MyEgress();
  call MyComputeChecksum();
}

procedure mainProcedure()
  modifies hdr.ipv4.protocol, standard_metadata.egress_port, standard_metadata.egress_spec, p4b_recirculate, p4b_clone_i2e,
    p4b_clone_e2e, p4b_clone_i2i;
{
  p4b_recirculate := false;
  p4b_clone_i2i := false;
  p4b_clone_e2e := false;
  p4b_clone_i2e := false;
  call main();
}
""".lstrip()

    def test_two_stage_snapshot_extends_modifies(self) -> None:
        """
        Regression test for the two-stage ingress/egress scheduling mode:

        When ingress/egress are executed as separate steps, the harness swaps packet
        globals from a per-node "egress mailbox". That swap/restore writes packet
        globals that may *not* appear in P4B's mainProcedure modifies list (and may
        be pruned out of env inputs). The harness must still include them in the
        thread/main modifies sets, otherwise Ultimate reports TypeErrorResult.
        """

        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            router_bpl = tmp / "eventful.bpl"
            router_bpl.write_text(self._MIN_EVENTFUL_BPL, encoding="utf-8")
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
            self.assertIn("Two-stage: swap in one pending egress packet snapshot.", text)

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

    def test_two_stage_egress_queue_capacity_2_is_two_slot(self) -> None:
        """
        Regression test: when queue_capacity==2, the two-stage egress queue must
        preserve *two distinct* pending egress snapshots (bag semantics), rather
        than a single snapshot + counter.
        """

        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            router_bpl = tmp / "eventful.bpl"
            router_bpl.write_text(self._MIN_EVENTFUL_BPL, encoding="utf-8")
            spec_path = tmp / "two_stage_k2.prop"
            out_bpl = tmp / "two_stage_k2.bpl"
            work_dir = tmp / "two_stage_k2.work"

            spec_path.write_text(
                f"""
import s1 from "{router_bpl}";

topology {{}}

node s1 {{
  external_input = true;
}}

global {{
  queue_capacity = 2;
  assert {{ true; }};
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

            # Two-slot egress mailboxes are declared.
            self.assertRegex(text, r"(?m)^\s*var s1__eg_mb0_hdr\.ipv4\.protocol\s*:\s*bv8\s*;")
            self.assertRegex(text, r"(?m)^\s*var s1__eg_mb1_hdr\.ipv4\.protocol\s*:\s*bv8\s*;")
            self.assertRegex(text, r"(?m)^\s*var s1__ig_saved_hdr\.ipv4\.protocol\s*:\s*bv8\s*;")
            self.assertIn("Two-slot egress queue: pick a pending snapshot", text)

            # The thread modifies list must include the slot vars (fork behaves like call).
            lines = text.splitlines()
            for i, line in enumerate(lines):
                if line.strip() == "procedure s1Thread() returns()":
                    modifies_line = lines[i + 1]
                    self.assertIn("s1__eg_mb0_hdr.ipv4.protocol", modifies_line)
                    self.assertIn("s1__eg_mb1_hdr.ipv4.protocol", modifies_line)
                    break
            else:
                self.fail("missing procedure s1Thread() in generated Boogie")


if __name__ == "__main__":
    unittest.main()
