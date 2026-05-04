import os
import tempfile
import unittest
from pathlib import Path

from dslc.backends.boogie_errors import P4BTranslatorError
from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines


class TestP4BTofinoCppDefines(unittest.TestCase):
    def test_no_tna_include_no_define(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "a.p4"
            p.write_text("#include <core.p4>\n", encoding="utf-8")
            self.assertEqual(_maybe_tofino_cpp_defines(str(p)), [])

    def test_tna_include_adds_default_define(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "a.p4"
            p.write_text("#include <core.p4>\n#include <tna.p4>\n", encoding="utf-8")
            old = os.environ.pop("P4B_TARGET_TOFINO", None)
            try:
                args = _maybe_tofino_cpp_defines(str(p))
                self.assertEqual(args[0], "-D__TARGET_TOFINO__=1")
            finally:
                if old is not None:
                    os.environ["P4B_TARGET_TOFINO"] = old

    def test_tna_include_respects_env_override(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "a.p4"
            p.write_text("#include <tna.p4>\n", encoding="utf-8")
            old = os.environ.get("P4B_TARGET_TOFINO")
            os.environ["P4B_TARGET_TOFINO"] = "2"
            try:
                args = _maybe_tofino_cpp_defines(str(p))
                self.assertEqual(args[0], "-D__TARGET_TOFINO__=2")
            finally:
                if old is None:
                    os.environ.pop("P4B_TARGET_TOFINO", None)
                else:
                    os.environ["P4B_TARGET_TOFINO"] = old

    def test_tna_include_path_can_be_overridden(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            inc = root / "tofino-include"
            inc.mkdir()
            (inc / "tna.p4").write_text("", encoding="utf-8")
            p = root / "a.p4"
            p.write_text("#include <tna.p4>\n", encoding="utf-8")

            old = os.environ.get("P4B_TOFINO_INCLUDE_PATH")
            os.environ["P4B_TOFINO_INCLUDE_PATH"] = str(inc)
            try:
                args = _maybe_tofino_cpp_defines(str(p))
                self.assertEqual(args, ["-D__TARGET_TOFINO__=1", "-I", str(inc)])
            finally:
                if old is None:
                    os.environ.pop("P4B_TOFINO_INCLUDE_PATH", None)
                else:
                    os.environ["P4B_TOFINO_INCLUDE_PATH"] = old

    def test_invalid_env_raises(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "a.p4"
            p.write_text("#include <tna.p4>\n", encoding="utf-8")
            old = os.environ.get("P4B_TARGET_TOFINO")
            os.environ["P4B_TARGET_TOFINO"] = "bogus"
            try:
                with self.assertRaises(P4BTranslatorError):
                    _maybe_tofino_cpp_defines(str(p))
            finally:
                if old is None:
                    os.environ.pop("P4B_TARGET_TOFINO", None)
                else:
                    os.environ["P4B_TARGET_TOFINO"] = old


if __name__ == "__main__":
    unittest.main()
