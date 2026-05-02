import unittest

from dslc.cli.wraparound import _resolve_cegis_toolchain_settings, _resolve_default_toolchains
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

    def test_schedule_replay_cegis_defaults_use_nowitness_front_stages(self) -> None:
        root = repo_root()
        toolchain, closure_toolchain, settings, closure_settings = _resolve_cegis_toolchain_settings(
            root=root,
            toolchain_arg="",
            closure_toolchain_arg="",
            settings_arg="",
            closure_settings_arg="",
            cegar_mode="schedule_replay",
        )
        self.assertTrue(toolchain.name.endswith("ReachSafety.xml"), toolchain)
        self.assertTrue(settings.name.endswith("ReachSafety-32bit-GemCutter-ALL.epf"), settings)
        self.assertTrue(closure_toolchain.name.endswith("ClosureCheck-ReachSafety.xml"), closure_toolchain)
        self.assertTrue(closure_settings.name.endswith(".epf"), closure_settings)

    def test_schedule_replay_high_memory_defaults_use_allinline_settings(self) -> None:
        root = repo_root()
        toolchain, closure_toolchain, settings, closure_settings = _resolve_cegis_toolchain_settings(
            root=root,
            toolchain_arg="",
            closure_toolchain_arg="",
            settings_arg="",
            closure_settings_arg="",
            cegar_mode="schedule_replay",
            ultimate_xmx_gb=8,
        )
        self.assertTrue(toolchain.name.endswith("ReachSafety.xml"), toolchain)
        self.assertTrue(closure_toolchain.name.endswith("ClosureCheck-ReachSafety.xml"), closure_toolchain)
        self.assertTrue(settings.name.endswith("ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf"), settings)
        self.assertEqual(settings, closure_settings)

    def test_legacy_cegis_defaults_keep_witness_front_stages(self) -> None:
        root = repo_root()
        toolchain, _closure_toolchain, settings, _closure_settings = _resolve_cegis_toolchain_settings(
            root=root,
            toolchain_arg="",
            closure_toolchain_arg="",
            settings_arg="",
            closure_settings_arg="",
            cegar_mode="legacy_closure_assumes",
        )
        self.assertTrue(toolchain.name.endswith("ReachSafety-Witness.xml"), toolchain)
        self.assertTrue(settings.name.endswith("ReachSafety-32bit-GemCutter-ALL-witness.epf"), settings)
