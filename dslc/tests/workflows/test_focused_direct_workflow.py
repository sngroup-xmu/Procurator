from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path
from typing import Any

from dslc.toolchain.ultimate_runner import UltimateRunResult
from dslc.transform.focused_direct import find_focused_direct_assert_lines
from dslc.workflows.focused_direct import focused_unsafe_marker_for_bpl, run_focused_direct_prepass


def _dynamic_direct_bpl(*, extra_assert_prefix: str = "") -> str:
    return f"""\
var s_reg:[bv16]bv32;
var s_reg__last_index:bv16;
var s_reg__last_value:bv32;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv32;
var s_meta.register_index:bv16;
var s_tmp:bv32;

procedure {{:inline 1}} s_get_register_index()
  modifies s_meta.register_index;
{{
  s_meta.register_index := s_idx_calc.get$bv32();
}}

function {{:inline true}}s_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) {{ r[i] }}
procedure {{:inline 1}} s_reg.write(i:bv16, v:bv32)
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value;
{{
  s_reg[i] := v;
  s_reg__last_index := i;
  s_reg__last_value := v;
  s_reg__wrote_any := true;
  if (i == 0bv16) {{ s_reg__wrote_index0 := true; s_reg__last0_value := v; }}
}}

procedure {{:inline 1}} s_Ingress()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{{
  call s_get_register_index();
  s_tmp := s_reg.read(s_reg, s_meta.register_index);
  call s_reg.write(s_meta.register_index, s_tmp);
{extra_assert_prefix}  assert !((s_reg__wrote_any && (s_reg__last_value == 0bv32)));
}}
"""


def _run_prepass(
    tmp: Path,
    *,
    result_line: str,
    hit: str,
    optimize_bpl=None,
    ultimate_timeout_seconds: int = 10,
    calls: list[dict[str, Any]] | None = None,
) -> int:
    bpl = tmp / "case.bpl"
    bpl.write_text(_dynamic_direct_bpl(), encoding="utf-8")

    def fake_runner(**kwargs: Any) -> UltimateRunResult:
        if calls is not None:
            calls.append(dict(kwargs))
        input_bpl = Path(kwargs["input_bpl"])
        log_path = Path(kwargs["log_path"])
        lines = find_focused_direct_assert_lines(input_bpl.read_text(encoding="utf-8"), "s_reg", "0bv32")
        if hit == "none":
            log_path.write_text("no counterexample line\n", encoding="utf-8")
        elif hit == "focused" and lines:
            log_path.write_text(f"CounterExampleResult [Line: {lines[0]}]\n", encoding="utf-8")
        elif hit == "wrong":
            wrong = 1
            if lines and lines[0] == wrong:
                wrong = lines[0] + 1
            log_path.write_text(f"CounterExampleResult [Line: {wrong}]\n", encoding="utf-8")
        else:
            log_path.write_text("no counterexample line\n", encoding="utf-8")
        return UltimateRunResult(returncode=0, log_path=log_path, result_line=result_line)

    return run_focused_direct_prepass(
        bpl_path=bpl,
        log_dir=tmp,
        ultimate=tmp / "Ultimate",
        toolchain=tmp / "ReachSafety.xml",
        settings=tmp / "settings.epf",
        ultimate_home=tmp / "ultimate-home",
        ultimate_timeout_seconds=ultimate_timeout_seconds,
        resource_limits=False,
        ultimate_xmx_gb=1,
        optimize_bpl=optimize_bpl,
        ultimate_runner=fake_runner,
        emit=lambda _msg: None,
    )


class TestFocusedDirectWorkflow(unittest.TestCase):
    def test_unsafe_focused_line_writes_marker_and_short_circuits(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            rc = _run_prepass(tmp, result_line="RESULT: UNSAFE", hit="focused")

            self.assertEqual(rc, 1)
            marker = focused_unsafe_marker_for_bpl(out_dir=tmp, bpl_path=tmp / "case.bpl")
            self.assertIsNotNone(marker)
            data = json.loads(marker.read_text(encoding="utf-8"))  # type: ignore[union-attr]
            self.assertEqual(data["kind"], "focused_under_approx")
            self.assertIn("source_bpl_sha256", data)
            self.assertIn("focused_bpl_sha256", data)
            self.assertGreaterEqual(len(data["assert_lines"]), 1)
            self.assertEqual(data["target_reg"], "s_reg")

    def test_unsafe_wrong_line_falls_back(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            rc = _run_prepass(tmp, result_line="RESULT: UNSAFE", hit="wrong")

            self.assertEqual(rc, 0)
            self.assertIsNone(focused_unsafe_marker_for_bpl(out_dir=tmp, bpl_path=tmp / "case.bpl"))

    def test_explicit_short_timeout_is_respected(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            calls: list[dict[str, Any]] = []
            rc = _run_prepass(
                tmp,
                result_line="RESULT: SAFE",
                hit="focused",
                ultimate_timeout_seconds=7,
                calls=calls,
            )

            self.assertEqual(rc, 0)
            self.assertEqual(len(calls), 1)
            self.assertEqual(calls[0]["toolchain_timeout_seconds"], 7)

    def test_unbounded_timeout_uses_default_focus_budget(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            calls: list[dict[str, Any]] = []
            rc = _run_prepass(
                tmp,
                result_line="RESULT: SAFE",
                hit="focused",
                ultimate_timeout_seconds=0,
                calls=calls,
            )

            self.assertEqual(rc, 0)
            self.assertEqual(len(calls), 1)
            self.assertEqual(calls[0]["toolchain_timeout_seconds"], 120)

    def test_stale_marker_with_wrong_source_hash_is_ignored(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            rc = _run_prepass(tmp, result_line="RESULT: UNSAFE", hit="focused")
            self.assertEqual(rc, 1)
            marker = focused_unsafe_marker_for_bpl(out_dir=tmp, bpl_path=tmp / "case.bpl")
            self.assertIsNotNone(marker)

            bpl = tmp / "case.bpl"
            bpl.write_text(bpl.read_text(encoding="utf-8") + "\n// changed\n", encoding="utf-8")

            self.assertIsNone(focused_unsafe_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_stale_marker_with_wrong_focused_hash_is_ignored(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            rc = _run_prepass(tmp, result_line="RESULT: UNSAFE", hit="focused")
            self.assertEqual(rc, 1)
            marker = focused_unsafe_marker_for_bpl(out_dir=tmp, bpl_path=tmp / "case.bpl")
            self.assertIsNotNone(marker)

            focused = tmp / "case.focused-index0.bpl"
            focused.write_text(focused.read_text(encoding="utf-8") + "\n// changed\n", encoding="utf-8")

            self.assertIsNone(focused_unsafe_marker_for_bpl(out_dir=tmp, bpl_path=tmp / "case.bpl"))

    def test_safe_or_unknown_falls_back(self) -> None:
        for result_line in ("RESULT: SAFE", "RESULT: UNKNOWN", "RESULT: TIMEOUT"):
            with self.subTest(result_line=result_line):
                with tempfile.TemporaryDirectory() as td:
                    tmp = Path(td)
                    rc = _run_prepass(tmp, result_line=result_line, hit="focused")

                    self.assertEqual(rc, 0)
                    self.assertIsNone(focused_unsafe_marker_for_bpl(out_dir=tmp, bpl_path=tmp / "case.bpl"))

    def test_post_optimization_refresh_empty_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)

            def drop_focused_asserts(path: Path) -> None:
                text = path.read_text(encoding="utf-8")
                path.write_text(
                    "\n".join(line for line in text.splitlines() if "s_reg__wrote_index0" not in line) + "\n",
                    encoding="utf-8",
                )

            rc = _run_prepass(
                tmp,
                result_line="RESULT: UNSAFE",
                hit="none",
                optimize_bpl=drop_focused_asserts,
            )

            self.assertEqual(rc, 0)
            self.assertIsNone(focused_unsafe_marker_for_bpl(out_dir=tmp, bpl_path=tmp / "case.bpl"))


if __name__ == "__main__":
    unittest.main()
