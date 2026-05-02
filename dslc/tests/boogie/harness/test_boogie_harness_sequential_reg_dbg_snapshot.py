import tempfile
import unittest
from pathlib import Path

from dslc.backends.boogie_harness import BoogieHarnessEmitter
from dslc.compiler import compile_spec_file
from dslc.speclang.model import GlobalDecl, ImportDecl, NodeDecl, SpecModel


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

    _MIN_REF_REG_BPL = r"""
type Ref;
var standard_metadata.egress_port: bv9;
var standard_metadata.egress_spec: bv9;

// Register ref_reg
var ref_reg: [bv32]Ref;

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

    def _compile_ref_register_spec(self, *, tmp: Path, boogie_harness: str) -> str:
        bpl = tmp / f"min_ref_reg_{boogie_harness}.bpl"
        bpl.write_text(self._MIN_REF_REG_BPL, encoding="utf-8")

        spec = tmp / f"ref_dbg_snapshot_{boogie_harness}.prop"
        out_bpl = tmp / f"ref_dbg_snapshot_{boogie_harness}.bpl"
        work_dir = tmp / f"ref_dbg_snapshot_{boogie_harness}.work"

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
    ref_reg[0] == ref_reg[0];
  }};
}}
""".lstrip(),
            encoding="utf-8",
        )

        compile_spec_file(
            spec_path=spec,
            backend="boogie",
            out=out_bpl,
            p4b_bin=None,
            work_dir=work_dir,
            enable_slicing=True,
            prune_env_inputs=True,
            boogie_harness=boogie_harness,
            pipeline_two_stage=False,
            max_steps=3,
        )

        return out_bpl.read_text(encoding="utf-8", errors="replace")

    def test_ref_register_does_not_emit_undeclared_debug_snapshot_vars_sequential(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            text = self._compile_ref_register_spec(tmp=Path(td), boogie_harness="sequential")

        self.assertIn("s1_ref_reg__last0_value", text)
        self.assertNotIn("s1_ref_reg__dbg0", text)
        self.assertNotIn("s1_ref_reg__last_value__dbg", text)
        self.assertNotIn("s1_ref_reg__last0_value__dbg", text)
        self.assertIn("s1_ref_reg__last0_value == s1_ref_reg__last0_value", text)
        self.assertNotIn("s1_ref_reg[i] == 0", text)
        self.assertNotIn("s1_ref_reg[0bv32] == 0", text)
        self.assertIn("assume s1_ref_reg__last0_value == s1_ref_reg[0bv32];", text)

    def test_ref_register_does_not_emit_undeclared_debug_snapshot_vars_concurrent(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            text = self._compile_ref_register_spec(tmp=Path(td), boogie_harness="concurrent")

        self.assertIn("s1_ref_reg__last0_value", text)
        self.assertNotIn("s1_ref_reg__dbg0", text)
        self.assertNotIn("s1_ref_reg__last_value__dbg", text)
        self.assertNotIn("s1_ref_reg__last0_value__dbg", text)
        self.assertNotIn("s1_ref_reg[i] == 0", text)
        self.assertNotIn("s1_ref_reg[0bv32] == 0", text)
        self.assertIn("assume s1_ref_reg__last0_value == s1_ref_reg[0bv32];", text)

    def test_ref_register_trace_uses_array_read_not_undeclared_debug_var(self) -> None:
        spec = SpecModel(
            imports={"s1": ImportDecl(alias="s1", path="dummy.bpl")},
            nodes={"s1": NodeDecl(name="s1", external_input=False)},
            global_decl=GlobalDecl(queue_capacity=1),
        )
        emitter = BoogieHarnessEmitter(
            spec,
            node_input_vars={"s1": []},
            node_egress_port_type={"s1": "bv9"},
            node_egress_port_var={"s1": "standard_metadata.egress_spec"},
            node_declared_vars={"s1": set()},
            node_mainprocedure_modifies={"s1": set()},
            node_register_arrays={"s1": {"s1_ref_reg": ("bv32", "Ref")}},
            node_pipeline_stages={},
            node_var_types={"s1": {}},
            node_type_defs={"s1": {}},
            node_meta={"s1": None},
            host_to_node={},
            host_input_vars={},
            host_var_types={},
            harness_mode="sequential",
            pipeline_two_stage=False,
            max_steps=1,
        )
        emitter._emit_trace = True

        text = emitter.emit(emit_helpers=False)

        self.assertIn("var trace_s1_ref_reg__dbg0: [int]Ref;", text)
        self.assertIn("var trace_s1_ref_reg__last0_value: [int]Ref;", text)
        self.assertIn("trace_s1_ref_reg__dbg0[procurator_step] := s1_ref_reg[0bv32];", text)
        self.assertIn(
            "trace_s1_ref_reg__last0_value[procurator_step] := s1_ref_reg__last0_value;",
            text,
        )
        self.assertNotIn("trace_s1_ref_reg__dbg0[procurator_step] := s1_ref_reg__dbg0;", text)
        self.assertNotIn("var s1_ref_reg__dbg0", text)


if __name__ == "__main__":
    unittest.main()
