import unittest
from pathlib import Path


class TestCliToolchainWitnessRerun(unittest.TestCase):
    def test_toolchain_includes_witnessprinter(self) -> None:
        from dslc.cli.gemcutter import _toolchain_includes_witnessprinter

        repo_root = Path(__file__).resolve().parents[2]
        witness_tc = repo_root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-Witness.xml"
        nowitness_tc = repo_root / "dslc" / "toolchain" / "ultimate" / "ReachSafety.xml"

        self.assertTrue(_toolchain_includes_witnessprinter(witness_tc))
        self.assertFalse(_toolchain_includes_witnessprinter(nowitness_tc))

