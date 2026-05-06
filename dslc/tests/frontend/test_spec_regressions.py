import unittest
from pathlib import Path

from dslc.speclang.emit import DSLExprPrinter
from dslc.speclang.parse import parse_tree
from dslc.speclang.semantics import SemanticAnalyzer, SemanticError


class TestSpecRegressions(unittest.TestCase):
    def test_p4xos_majority_quorum_spec_avoids_else_if_and_parses(self) -> None:
        """
        Regression: our DSL grammar does not support `else if`. This benchmark
        must use nested `if` so it keeps working as a reference NSDI-style bug.
        """

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        spec_path = repo_root / "Procurator" / "argo" / "code" / "spec" / "bench" / "p4xos_majority_quorum_bug.prop"
        text = spec_path.read_text(encoding="utf-8", errors="replace")

        # Ignore comments when checking "else if" usage.
        code_only = "\n".join([ln for ln in text.splitlines() if not ln.lstrip().startswith("//")])
        self.assertNotIn("else if", code_only)

        # Parse smoke.
        from dslc.speclang.parse import parse_tree

        _ = parse_tree(text)

    def test_distcache_p2c_spec_guards_table_execution(self) -> None:
        """
        Regression: DistCache P2C consistency property must be guarded so it is
        only checked when the P2C logic actually executes (parser reaches parse_op
        + poweroftwochoice_tbl selects poweroftwochoice).
        """

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        spec_path = repo_root / "Procurator" / "argo" / "code" / "spec" / "bench" / "distcache_bug.prop"
        text = spec_path.read_text(encoding="utf-8", errors="replace")

        self.assertIn("hdr.udp_hdr.dstPort == 5008", text)
        self.assertIn("hdr.op_hdr.optype == 48", text)

    def test_distcache_cm34_write_bug_uses_node_prefixed_instrumentation_flags(self) -> None:
        """
        Regression: DistCache CM3/CM4 wiring bug property relies on Boogie-level
        register write instrumentation flags (`<node>_<reg>__wrote_any`). If the
        node prefix is missing, the property becomes ill-formed / vacuous.
        """

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        spec_path = repo_root / "Procurator" / "argo" / "code" / "spec" / "bench" / "distcache_cm34_write_bug.prop"
        text = spec_path.read_text(encoding="utf-8", errors="replace")

        self.assertIn("leaf_netcacheEgress_cm3_reg__wrote_any", text)
        self.assertIn("leaf_netcacheEgress_cm4_reg__wrote_any", text)

    def test_distcache_cache_frequency_wraparound_spec_is_functional_two_phase(self) -> None:
        """
        Regression: cache_frequency wraparound benchmark must be expressed as a
        two-phase functional property (pump -> query), not as a bare `reg != 0`.
        """

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        spec_path = repo_root / "Procurator" / "argo" / "code" / "spec" / "bench" / "distcache_leaf_cache_frequency_wraparound.prop"
        text = spec_path.read_text(encoding="utf-8", errors="replace")

        # Two-phase script knob used by wraparound confirm stage.
        self.assertIn("bool pump_mode = true", text)
        self.assertIn("if (pump_mode)", text)
        # Pump packet and query packet optypes.
        self.assertIn("hdr.op_hdr.optype = 4", text)
        self.assertIn("hdr.op_hdr.optype = 36", text)
        # Functional check must NOT be guarded by the post-egress optype (which can be rewritten).
        # Instead, it should be guarded by the DSL script mode (pump_mode).
        self.assertIn("pump_mode", text)
        self.assertIn("leaf_hdr_eg.frequency_hdr.frequency != 0", text)
        self.assertNotIn("leaf_hdr.op_hdr.optype != 36", text)

    def test_bit_slice_expression_parses_and_round_trips(self) -> None:
        """
        Regression: packed TNA register structs are translated as bvN scalars.
        Specs must be able to talk about a field slice without treating it as
        an array index.
        """

        text = """
import sw from "dummy.p4";
topology { }
node sw { external_input = true; }
global {
  assert {
    !(sw_Ingress_value00_values__wrote_any
      && sw_Ingress_value00_values__last_value[64:32] == 0);
  };
}
"""
        tree = parse_tree(text)
        slices = list(tree.find_data("bit_slice"))
        self.assertEqual(len(slices), 1)
        self.assertEqual(DSLExprPrinter().expr_to_str(slices[0]), "sw_Ingress_value00_values__last_value[64:32]")

    def test_bit_slice_expression_rejects_empty_range(self) -> None:
        text = """
import sw from "dummy.p4";
topology { }
node sw { external_input = true; }
global {
  assert { sw_reg__last_value[31:32] == 0; };
}
"""
        tree = parse_tree(text)
        with self.assertRaises(SemanticError):
            SemanticAnalyzer().analyze(tree)

    def test_single_bit_slice_expression_is_valid(self) -> None:
        text = """
import sw from "dummy.p4";
topology { }
node sw { external_input = true; }
global {
  assert { sw_ig_dprsr_md.drop_ctl[0:0] == 1; };
}
"""
        tree = parse_tree(text)
        SemanticAnalyzer().analyze(tree)


if __name__ == "__main__":
    unittest.main()
