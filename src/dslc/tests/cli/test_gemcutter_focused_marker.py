from __future__ import annotations

import contextlib
import hashlib
import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from dslc.cli import gemcutter


class TestGemcutterFocusedMarkerBoundary(unittest.TestCase):
    def test_focused_marker_is_looked_up_in_log_directory(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            spec = tmp / "case.prop"
            spec.write_text("dummy", encoding="utf-8")
            out_bpl = tmp / "out" / "case.bpl"
            log_path = tmp / "logs" / "case.gemcutter.log"
            marker = log_path.parent / "case.focused-index0.unsafe.json"

            def fake_compile(**_kwargs):
                out_bpl.parent.mkdir(parents=True, exist_ok=True)
                out_bpl.write_text("procedure main() {}\n", encoding="utf-8")

            def fake_prepass(**kwargs):
                marker.parent.mkdir(parents=True, exist_ok=True)
                focus_bpl = marker.parent / "case.focused-index0.bpl"
                focus_bpl.write_text("procedure main() {}\n", encoding="utf-8")
                marker.write_text(
                    json.dumps(
                        {
                            "kind": "focused_under_approx",
                            "bpl": str(focus_bpl),
                            "source_bpl": str(out_bpl),
                            "source_bpl_sha256": hashlib.sha256(out_bpl.read_bytes()).hexdigest(),
                            "focused_bpl_sha256": hashlib.sha256(focus_bpl.read_bytes()).hexdigest(),
                        }
                    )
                    + "\n",
                    encoding="utf-8",
                )
                return 1

            with mock.patch.object(gemcutter, "compile_spec_file", side_effect=fake_compile), mock.patch.object(
                gemcutter, "find_default_ultimate", return_value=tmp / "Ultimate"
            ), mock.patch.object(gemcutter, "run_focused_direct_prepass", side_effect=fake_prepass), mock.patch.object(
                gemcutter, "_toolchain_includes_witnessprinter", return_value=True
            ):
                (tmp / "Ultimate").write_text("", encoding="utf-8")
                (tmp / "ReachSafety.xml").write_text("", encoding="utf-8")
                (tmp / "settings.epf").write_text("", encoding="utf-8")
                buf = io.StringIO()
                with contextlib.redirect_stdout(buf):
                    rc = gemcutter.main(
                        [
                            "--spec",
                            str(spec),
                            "--out",
                            str(out_bpl),
                            "--log",
                            str(log_path),
                            "--toolchain",
                            str(tmp / "ReachSafety.xml"),
                            "--settings",
                            str(tmp / "settings.epf"),
                            "--wraparound",
                            "off",
                            "--focused-direct",
                            "auto",
                            "--no-witness-rerun",
                        ]
                    )

            self.assertEqual(rc, 1)
            self.assertIn("[CEX] focused_under_approx:", buf.getvalue())
            self.assertIn(str(marker), buf.getvalue())


if __name__ == "__main__":
    unittest.main()
