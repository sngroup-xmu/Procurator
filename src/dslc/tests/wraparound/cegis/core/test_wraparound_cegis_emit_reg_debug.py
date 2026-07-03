import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from dslc.workflows import wraparound_cegis as wc


class _StopAfterCompile(RuntimeError):
    pass


class TestWraparoundCegisEmitRegDebug(unittest.TestCase):
    def _mk_paths(self) -> tuple[Path, Path, Path]:
        td = tempfile.TemporaryDirectory()
        self.addCleanup(td.cleanup)
        root = Path(td.name)
        spec = root / "spec.prop"
        out = root / "out"
        ultimate = root / "Ultimate"
        spec.write_text("topology {}", encoding="utf-8")
        ultimate.write_text("", encoding="utf-8")
        return spec, out, ultimate

    def test_single_target_propagates_emit_reg_debug(self) -> None:
        spec, out, ultimate = self._mk_paths()
        captured: dict = {}

        def _fake_compile_spec_file(*args, **kwargs):
            captured.update(kwargs)
            raise _StopAfterCompile("stop after compile args capture")

        with patch.object(wc, "compile_spec_file", side_effect=_fake_compile_spec_file):
            with self.assertRaises(_StopAfterCompile):
                wc.run_wraparound_cegis(
                    spec_path=spec,
                    out_dir=out,
                    p4b_bin=None,
                    ultimate=ultimate,
                    emit_reg_debug=False,
                    timeout_seconds=1,
                    max_iters=1,
                )

        self.assertIn("emit_reg_debug", captured)
        self.assertFalse(captured["emit_reg_debug"])

    def test_multi_target_propagates_emit_reg_debug(self) -> None:
        spec, out, ultimate = self._mk_paths()
        captured: dict = {}

        def _fake_compile_spec_file(*args, **kwargs):
            captured.update(kwargs)
            raise _StopAfterCompile("stop after compile args capture")

        with patch.object(wc, "compile_spec_file", side_effect=_fake_compile_spec_file):
            with self.assertRaises(_StopAfterCompile):
                wc.run_wraparound_cegis_multi(
                    spec_path=spec,
                    out_dir=out,
                    p4b_bin=None,
                    ultimate=ultimate,
                    emit_reg_debug=False,
                    timeout_seconds=1,
                    max_iters=1,
                    max_targets=1,
                )

        self.assertIn("emit_reg_debug", captured)
        self.assertFalse(captured["emit_reg_debug"])
