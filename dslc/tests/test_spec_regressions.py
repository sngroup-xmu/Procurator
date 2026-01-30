import unittest
from pathlib import Path


class TestSpecRegressions(unittest.TestCase):
    def test_distcache_p2c_spec_guards_table_execution(self) -> None:
        """
        Regression: DistCache P2C consistency property must be guarded so it is
        only checked when the P2C logic actually executes (parser reaches parse_op
        + poweroftwochoice_tbl selects poweroftwochoice).
        """

        repo_root = Path(__file__).resolve().parents[2]
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

        repo_root = Path(__file__).resolve().parents[2]
        spec_path = repo_root / "Procurator" / "argo" / "code" / "spec" / "bench" / "distcache_cm34_write_bug.prop"
        text = spec_path.read_text(encoding="utf-8", errors="replace")

        self.assertIn("leaf_netcacheEgress_cm3_reg__wrote_any", text)
        self.assertIn("leaf_netcacheEgress_cm4_reg__wrote_any", text)


if __name__ == "__main__":
    unittest.main()
