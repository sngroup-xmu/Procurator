import re
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from dslc.backends.boogie.core.errors import BoogieBackendError
from dslc.compiler import compile_spec_text


def _native_register_bpl(*, include_marker: bool = True, include_mirror_modifies: bool = True) -> str:
    marker = "// Register my_reg\n" if include_marker else ""
    modifies = "my_reg"
    if include_mirror_modifies:
        modifies += (
            ", my_reg__last_index, my_reg__last_value, my_reg__last_old_value, "
            "my_reg__wrote_any, my_reg__wrote_index0, my_reg__last0_old_value, "
            "my_reg__last0_value, my_reg__last_write_site"
        )
    return f"""\
type Ref;
var standard_metadata.egress_port:bv9;
var hdr.ipv4:Ref;
var hdr.ipv4.dstAddr:bv32;
var isValid:[Ref]bool;

{marker}var my_reg:[bv32]bv32;
var my_reg__last_index:bv32;
var my_reg__last_value:bv32;
var my_reg__last_old_value:bv32;
var my_reg__wrote_any:bool;
var my_reg__wrote_index0:bool;
var my_reg__last0_old_value:bv32;
var my_reg__last0_value:bv32;
var my_reg__next_write_site:int;
var my_reg__last_write_site:int;

procedure {{:inline 1}} my_reg.write(index:bv32, value:bv32)
  modifies {modifies};
{{
  my_reg__last_old_value := my_reg[index];
  my_reg[index] := value;
  my_reg__last_index := index;
  my_reg__last_value := value;
  my_reg__last_write_site := my_reg__next_write_site;
  my_reg__wrote_any := true;
  if (index == 0bv32) {{
    my_reg__wrote_index0 := true;
    my_reg__last0_old_value := my_reg__last_old_value;
    my_reg__last0_value := value;
  }}
}}

procedure mainProcedure() returns()
{{
}}
"""


def _compile_single_node_bpl(raw_bpl: Path) -> str:
    spec = f"""
import s1 from "{raw_bpl.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
}}
global {{
  queue_capacity = 1;
  assert {{ true; }};
}}
"""
    outp = compile_spec_text(
        spec_text=spec,
        backend="boogie",
        out=raw_bpl.parent / "out.bpl",
        boogie_harness="sequential",
        pipeline_two_stage=False,
        emit_reg_debug=False,
    )
    return outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")


class TestBoogieRegisterMirrorOwnership(unittest.TestCase):
    def test_legacy_bpl_native_register_mirrors_are_not_reinstrumented_after_prefixing(self) -> None:
        bpl_text = _native_register_bpl()

        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            raw_bpl = td_path / "prog.bpl"
            raw_bpl.write_text(bpl_text, encoding="utf-8")

            spec = f"""
import s1 from "{raw_bpl.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
}}
global {{
  queue_capacity = 1;
  assert {{ true; }};
}}
"""

            out_bpl = td_path / "out.bpl"
            outp = compile_spec_text(
                spec_text=spec,
                backend="boogie",
                out=out_bpl,
                boogie_harness="sequential",
                pipeline_two_stage=False,
                emit_reg_debug=False,
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        for name in [
            "s1_my_reg__last_index",
            "s1_my_reg__last_value",
            "s1_my_reg__last_old_value",
            "s1_my_reg__wrote_any",
            "s1_my_reg__wrote_index0",
            "s1_my_reg__last0_old_value",
            "s1_my_reg__last0_value",
            "s1_my_reg__next_write_site",
            "s1_my_reg__last_write_site",
        ]:
            self.assertEqual(len(re.findall(rf"^var\s+{re.escape(name)}\b", text, flags=re.MULTILINE)), 1)

        self.assertEqual(len(re.findall(r"\bs1_my_reg__last_old_value\s*:=\s*s1_my_reg\[s1_index\];", text)), 1)
        self.assertEqual(len(re.findall(r"\bs1_my_reg__last_index\s*:=\s*s1_index;", text)), 1)
        self.assertEqual(len(re.findall(r"\bs1_my_reg__last_value\s*:=\s*s1_value;", text)), 1)
        self.assertEqual(
            len(re.findall(r"\bs1_my_reg__last_write_site\s*:=\s*s1_my_reg__next_write_site;", text)),
            1,
        )
        self.assertEqual(len(re.findall(r"\bs1_my_reg__wrote_any\s*:=\s*true;", text)), 1)
        self.assertEqual(len(re.findall(r"\bs1_my_reg__wrote_index0\s*:=\s*true;", text)), 1)
        self.assertEqual(len(re.findall(r"\bs1_my_reg__last0_old_value\s*:=\s*s1_my_reg__last_old_value;", text)), 1)
        self.assertEqual(len(re.findall(r"\bs1_my_reg__last0_value\s*:=\s*s1_value;", text)), 1)

    def test_legacy_bpl_backfill_repairs_write_body_and_modifies(self) -> None:
        bpl_text = """\
type Ref;
var standard_metadata.egress_port:bv9;
var hdr.ipv4:Ref;
var hdr.ipv4.dstAddr:bv32;
var isValid:[Ref]bool;

// Register my_reg
var my_reg:[bv32]bv32;

procedure {:inline 1} my_reg.write(index:bv32, value:bv32)
  modifies my_reg;
{
  my_reg[index] := value;
}

procedure mainProcedure() returns()
{
}
"""

        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            raw_bpl = td_path / "prog.bpl"
            raw_bpl.write_text(bpl_text, encoding="utf-8")
            text = _compile_single_node_bpl(raw_bpl)

        self.assertIn(
            "modifies s1_my_reg, s1_my_reg__last_index, s1_my_reg__last_value, "
            "s1_my_reg__last_old_value, s1_my_reg__wrote_any, s1_my_reg__wrote_index0, "
            "s1_my_reg__last0_old_value, s1_my_reg__last0_value, "
            "s1_my_reg__last_write_site;",
            text,
        )
        self.assertIn("s1_my_reg__last_old_value := s1_my_reg[s1_index];", text)
        self.assertIn("s1_my_reg__last_index := s1_index;", text)
        self.assertIn("s1_my_reg__last_value := s1_value;", text)
        self.assertIn("s1_my_reg__last_write_site := s1_my_reg__next_write_site;", text)
        self.assertIn("s1_my_reg__wrote_any := true;", text)
        self.assertIn("s1_my_reg__wrote_index0 := true;", text)
        self.assertIn("s1_my_reg__last0_old_value := s1_my_reg__last_old_value;", text)
        self.assertIn("s1_my_reg__last0_value := s1_value;", text)

    def test_p4b_generated_nodes_must_emit_register_mirrors(self) -> None:
        raw_bpl_without_mirrors = """\
type Ref;
var standard_metadata.egress_port:bv9;
var hdr.ipv4:Ref;
var hdr.ipv4.dstAddr:bv32;
var isValid:[Ref]bool;

// Register my_reg
var my_reg:[bv32]bv32;

procedure {:inline 1} my_reg.write(index:bv32, value:bv32)
  modifies my_reg;
{
  my_reg[index] := value;
}

procedure mainProcedure() returns()
{
}
"""

        class FakeP4BTranslator:
            def __init__(self, _p4b_bin: str):
                pass

            def compile_to_bpl(
                self,
                _p4_path: str,
                out_bpl: str,
                _entries_path: str | None,
                out_meta: str | None = None,
                **_kwargs: object,
            ) -> None:
                Path(out_bpl).write_text(raw_bpl_without_mirrors, encoding="utf-8")
                if out_meta:
                    Path(out_meta).write_text("{}", encoding="utf-8")

        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            p4 = td_path / "prog.p4"
            p4.write_text("#include <core.p4>\n", encoding="utf-8")

            spec = f"""
import s1 from "{p4.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
}}
global {{
  queue_capacity = 1;
  assert {{ true; }};
}}
"""
            with mock.patch("dslc.backends.boogie.compiler.P4BTranslator", FakeP4BTranslator):
                with self.assertRaisesRegex(BoogieBackendError, "register write mirrors"):
                    compile_spec_text(
                        spec_text=spec,
                        backend="boogie",
                        out=td_path / "out.bpl",
                        p4b_bin=Path("/fake/p4c-translator"),
                        boogie_harness="sequential",
                        pipeline_two_stage=False,
                    )

    def test_p4b_generated_nodes_must_mark_register_arrays(self) -> None:
        raw_bpl_without_marker = _native_register_bpl(include_marker=False)

        class FakeP4BTranslator:
            def __init__(self, _p4b_bin: str):
                pass

            def compile_to_bpl(
                self,
                _p4_path: str,
                out_bpl: str,
                _entries_path: str | None,
                out_meta: str | None = None,
                **_kwargs: object,
            ) -> None:
                Path(out_bpl).write_text(raw_bpl_without_marker, encoding="utf-8")
                if out_meta:
                    Path(out_meta).write_text("{}", encoding="utf-8")

        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            p4 = td_path / "prog.p4"
            p4.write_text("#include <core.p4>\n", encoding="utf-8")

            spec = f"""
import s1 from "{p4.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
}}
global {{
  queue_capacity = 1;
  assert {{ true; }};
}}
"""
            with mock.patch("dslc.backends.boogie.compiler.P4BTranslator", FakeP4BTranslator):
                with self.assertRaisesRegex(BoogieBackendError, "register markers"):
                    compile_spec_text(
                        spec_text=spec,
                        backend="boogie",
                        out=td_path / "out.bpl",
                        p4b_bin=Path("/fake/p4c-translator"),
                        boogie_harness="sequential",
                        pipeline_two_stage=False,
                    )

    def test_p4b_generated_nodes_accept_complete_native_register_mirrors(self) -> None:
        raw_bpl_with_mirrors = _native_register_bpl()

        class FakeP4BTranslator:
            def __init__(self, _p4b_bin: str):
                pass

            def compile_to_bpl(
                self,
                _p4_path: str,
                out_bpl: str,
                _entries_path: str | None,
                out_meta: str | None = None,
                **_kwargs: object,
            ) -> None:
                Path(out_bpl).write_text(raw_bpl_with_mirrors, encoding="utf-8")
                if out_meta:
                    Path(out_meta).write_text("{}", encoding="utf-8")

        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            p4 = td_path / "prog.p4"
            p4.write_text("#include <core.p4>\n", encoding="utf-8")

            spec = f"""
import s1 from "{p4.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
}}
global {{
  queue_capacity = 1;
  assert {{ true; }};
}}
"""
            with mock.patch("dslc.backends.boogie.compiler.P4BTranslator", FakeP4BTranslator):
                outp = compile_spec_text(
                    spec_text=spec,
                    backend="boogie",
                    out=td_path / "out.bpl",
                    p4b_bin=Path("/fake/p4c-translator"),
                    boogie_harness="sequential",
                    pipeline_two_stage=False,
                    emit_reg_debug=False,
                )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        self.assertEqual(len(re.findall(r"^var\s+s1_my_reg__last_index\b", text, flags=re.MULTILINE)), 1)
        self.assertEqual(len(re.findall(r"\bs1_my_reg__last_index\s*:=\s*s1_index;", text)), 1)
        self.assertEqual(
            len(re.findall(r"\bs1_my_reg__last_write_site\s*:=\s*s1_my_reg__next_write_site;", text)),
            1,
        )
        self.assertEqual(len(re.findall(r"\bs1_my_reg__last0_value\s*:=\s*s1_value;", text)), 1)

    def test_p4b_generated_nodes_reject_incomplete_mirror_modifies(self) -> None:
        raw_bpl_without_modifies = _native_register_bpl(include_mirror_modifies=False)

        class FakeP4BTranslator:
            def __init__(self, _p4b_bin: str):
                pass

            def compile_to_bpl(
                self,
                _p4_path: str,
                out_bpl: str,
                _entries_path: str | None,
                out_meta: str | None = None,
                **_kwargs: object,
            ) -> None:
                Path(out_bpl).write_text(raw_bpl_without_modifies, encoding="utf-8")
                if out_meta:
                    Path(out_meta).write_text("{}", encoding="utf-8")

        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            p4 = td_path / "prog.p4"
            p4.write_text("#include <core.p4>\n", encoding="utf-8")

            spec = f"""
import s1 from "{p4.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
}}
global {{
  queue_capacity = 1;
  assert {{ true; }};
}}
"""
            with mock.patch("dslc.backends.boogie.compiler.P4BTranslator", FakeP4BTranslator):
                with self.assertRaisesRegex(BoogieBackendError, "register write mirrors"):
                    compile_spec_text(
                        spec_text=spec,
                        backend="boogie",
                        out=td_path / "out.bpl",
                        p4b_bin=Path("/fake/p4c-translator"),
                        boogie_harness="sequential",
                        pipeline_two_stage=False,
                    )


if __name__ == "__main__":
    unittest.main()
