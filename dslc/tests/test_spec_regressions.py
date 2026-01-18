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


if __name__ == "__main__":
    unittest.main()

