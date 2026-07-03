import unittest
from pathlib import Path
from dslc.tests.helpers import repo_root_from_test


class TestCliToolchainWitnessRerun(unittest.TestCase):
    def test_toolchain_includes_witnessprinter(self) -> None:
        from dslc.cli.gemcutter import _toolchain_includes_witnessprinter

        repo_root = repo_root_from_test(Path(__file__))
        witness_tc = repo_root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-Witness.xml"
        nowitness_tc = repo_root / "dslc" / "toolchain" / "ultimate" / "ReachSafety.xml"

        self.assertTrue(_toolchain_includes_witnessprinter(witness_tc))
        self.assertFalse(_toolchain_includes_witnessprinter(nowitness_tc))
