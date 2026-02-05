import tempfile
import unittest
from pathlib import Path

from dslc.compiler import compile_spec_file


class TestBoogieHarnessSequentialRegDbgSnapshot(unittest.TestCase):
    _MIN_REG_BPL = r"""
var standard_metadata.egress_port: bv9;
var standard_metadata.egress_spec: bv9;

// Register my_reg
var my_reg: [bv32]bv32;

procedure mainProcedure()
{
  // no-op
}
""".lstrip()

    def test_sequential_global_assert_accumulation_emits_reg_dbg_snapshot(self) -> None:
        """
        Regression test:

        In sequential bounded mode (max_steps <= 1000), global assertions are accumulated
        into `procurator_bad` and rendered with `prefer_reg_dbg=True`. When a global
        assertion references `reg[0]`, it is rewritten to `reg__dbg0` and therefore
        requires a per-step "register debug snapshot" assignment to keep `reg__dbg0`
        up-to-date. Missing the snapshot can make the assertion use stale values and
        lead to pseudo SAFE/UNSAFE results.
        """

        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "min_reg.bpl"
            bpl.write_text(self._MIN_REG_BPL, encoding="utf-8")

            spec = tmp / "dbg_snapshot.prop"
            out_bpl = tmp / "dbg_snapshot.bpl"
            work_dir = tmp / "dbg_snapshot.work"

            spec.write_text(
                f"""
import s1 from "{bpl.as_posix()}";

topology {{}}

node s1 {{
  external_input = false;
}}

global {{
  queue_capacity = 1;
  assert {{
    // Trivial property that still forces prefer_reg_dbg mapping: my_reg[0] -> my_reg__dbg0
    my_reg[0] == my_reg[0];
  }};
}}
""".lstrip(),
                encoding="utf-8",
            )

            compile_spec_file(
                spec_path=spec,
                backend="boogie",
                out=out_bpl,
                p4b_bin=None,  # importing .bpl does not need P4B
                work_dir=work_dir,
                enable_slicing=True,
                prune_env_inputs=True,
                boogie_harness="sequential",
                pipeline_two_stage=False,  # force node-pass steps
                max_steps=3,  # triggers global-assert accumulation
            )

            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        # Sanity: global assertions are accumulated.
        self.assertIn("procurator_bad", text)
        self.assertIn("Global assertions (accumulated into procurator_bad)", text)
        self.assertIn("s1_my_reg__dbg0", text)

        # Key regression: the per-step register debug snapshot must be emitted
        # even when there are no node-local assertions and no trace.
        self.assertIn("// Register debug snapshot", text)
        self.assertIn("s1_my_reg__dbg0 := s1_my_reg[0bv32];", text)

        # Ordering: snapshot must happen before the global assertion checks.
        self.assertLess(
            text.index("// Register debug snapshot"),
            text.index("// Global assertions (accumulated into procurator_bad)"),
        )


if __name__ == "__main__":
    unittest.main()

