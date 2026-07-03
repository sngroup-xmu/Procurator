import unittest
from pathlib import Path


class TestUltimatePaths(unittest.TestCase):
    def test_legacy_flat_toolchain_path_resolves_to_organized_asset(self) -> None:
        from dslc.toolchain.ultimate_paths import resolve_ultimate_asset_path

        old_path = Path("src/dslc/toolchain/ultimate/ReachSafety.xml")
        resolved = resolve_ultimate_asset_path(old_path)
        self.assertTrue(resolved.exists(), resolved)
        self.assertEqual(resolved.name, "ReachSafety.xml")
        self.assertIn("toolchains", resolved.parts)

    def test_legacy_flat_settings_path_resolves_to_organized_asset(self) -> None:
        from dslc.toolchain.ultimate_paths import resolve_ultimate_asset_path

        old_path = Path("src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL.epf")
        resolved = resolve_ultimate_asset_path(old_path)
        self.assertTrue(resolved.exists(), resolved)
        self.assertEqual(resolved.name, "ReachSafety-32bit-GemCutter-ALL.epf")
        self.assertIn("settings", resolved.parts)


if __name__ == "__main__":
    unittest.main()
