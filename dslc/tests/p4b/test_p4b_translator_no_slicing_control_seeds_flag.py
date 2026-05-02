import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from dslc.backends.boogie_p4b import P4BTranslator


class TestP4BTranslatorNoSlicingControlSeedsFlag(unittest.TestCase):
    def test_flag_added_when_disabled(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            p4 = td_path / "a.p4"
            p4.write_text("#include <core.p4>\n", encoding="utf-8")

            out_bpl = td_path / "out.bpl"
            out_meta = td_path / "out.meta.json"

            seen: dict[str, object] = {}

            def fake_run(cmd, **kwargs):
                seen["cmd"] = list(cmd)
                # Create minimal outputs expected by the wrapper.
                if "-o" in cmd:
                    out_idx = cmd.index("-o")
                    Path(cmd[out_idx + 1]).write_text("// dummy\n", encoding="utf-8")
                if "--meta-out" in cmd:
                    meta_idx = cmd.index("--meta-out")
                    Path(cmd[meta_idx + 1]).write_text("{}", encoding="utf-8")
                return subprocess.CompletedProcess(cmd, 0, stdout="")

            with mock.patch("dslc.backends.boogie_p4b.subprocess.run", side_effect=fake_run):
                t = P4BTranslator(p4b_bin="/bin/true", include_paths=[])
                t.compile_to_bpl(
                    str(p4),
                    str(out_bpl),
                    entries_path=None,
                    out_meta=str(out_meta),
                    slicing_vars=["hdr.ipv4.ttl"],
                    disable_slicing=False,
                    keep_control_seeds=False,
                )

            cmd = seen.get("cmd") or []
            self.assertIn("--no-slicing-control-seeds", cmd)

    def test_flag_not_added_by_default(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            p4 = td_path / "a.p4"
            p4.write_text("#include <core.p4>\n", encoding="utf-8")

            out_bpl = td_path / "out.bpl"
            out_meta = td_path / "out.meta.json"

            seen: dict[str, object] = {}

            def fake_run(cmd, **kwargs):
                seen["cmd"] = list(cmd)
                if "-o" in cmd:
                    out_idx = cmd.index("-o")
                    Path(cmd[out_idx + 1]).write_text("// dummy\n", encoding="utf-8")
                if "--meta-out" in cmd:
                    meta_idx = cmd.index("--meta-out")
                    Path(cmd[meta_idx + 1]).write_text("{}", encoding="utf-8")
                return subprocess.CompletedProcess(cmd, 0, stdout="")

            with mock.patch("dslc.backends.boogie_p4b.subprocess.run", side_effect=fake_run):
                t = P4BTranslator(p4b_bin="/bin/true", include_paths=[])
                t.compile_to_bpl(
                    str(p4),
                    str(out_bpl),
                    entries_path=None,
                    out_meta=str(out_meta),
                    slicing_vars=["hdr.ipv4.ttl"],
                    disable_slicing=False,
                    keep_control_seeds=True,
                )

            cmd = seen.get("cmd") or []
            self.assertNotIn("--no-slicing-control-seeds", cmd)


if __name__ == "__main__":
    unittest.main()

