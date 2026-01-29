import unittest

from dslc.cli.wraparound import _resolve_default_toolchains
from dslc.utils.repo import repo_root


class TestWraparoundCliToolchains(unittest.TestCase):
    def test_defaults_use_closure_toolchain_when_present(self) -> None:
        root = repo_root()
        toolchain, closure_toolchain = _resolve_default_toolchains(
            root=root,
            toolchain_arg="",
            closure_toolchain_arg="",
        )
        self.assertTrue(toolchain.name.endswith("ReachSafety-Witness.xml"), toolchain)
        # The closure toolchain intentionally omits the witness printer plugin.
        self.assertTrue(closure_toolchain.name.endswith("ClosureCheck-ReachSafety.xml"), closure_toolchain)

