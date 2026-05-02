import tempfile
import unittest
from pathlib import Path

from dslc.toolchain.ultimate_runner import write_launcher_ini


class TestUltimateLauncherIni(unittest.TestCase):
    def test_rewrites_xmx_xms_in_existing_ini(self) -> None:
        with tempfile.TemporaryDirectory(prefix="procurator-ultimate-ini-") as td:
            d = Path(td)
            ultimate = d / "Ultimate"
            ultimate.touch()
            (d / "Ultimate.ini").write_text(
                "\n".join(
                    [
                        "--launcher.suppressErrors",
                        "-nosplash",
                        "-vmargs",
                        "-Xmx12G",
                        "-Xms512M",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            out_ini = d / "Ultimate.launcher.ini"
            write_launcher_ini(ultimate=ultimate, out_ini=out_ini, xmx_gb=4, xms_mb=256)
            txt = out_ini.read_text(encoding="utf-8")

            self.assertIn("-Xmx4G", txt)
            self.assertIn("-Xms256M", txt)
            self.assertNotIn("-Xmx12G", txt)

    def test_inserts_vmargs_and_heap_flags_when_missing(self) -> None:
        with tempfile.TemporaryDirectory(prefix="procurator-ultimate-ini-") as td:
            d = Path(td)
            ultimate = d / "Ultimate"
            ultimate.touch()
            # No -vmargs / -Xmx / -Xms in the source ini.
            (d / "Ultimate.ini").write_text("--launcher.suppressErrors\n", encoding="utf-8")

            out_ini = d / "Ultimate.launcher.ini"
            write_launcher_ini(ultimate=ultimate, out_ini=out_ini, xmx_gb=3)
            txt = out_ini.read_text(encoding="utf-8")

            self.assertIn("-vmargs", txt)
            self.assertIn("-Xmx3G", txt)
            self.assertIn("-Xms512M", txt)


if __name__ == "__main__":
    unittest.main()

