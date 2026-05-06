from __future__ import annotations

import json
import hashlib
import tempfile
import unittest
from pathlib import Path
from typing import Any
from unittest import mock

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


def _dynamic_direct_bpl_with_mainprocedure() -> str:
    return _dynamic_direct_bpl() + """\

procedure main() returns()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  call s_Ingress();
}

procedure mainProcedure() returns()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  s_reg__last_index := 0bv16;
  s_reg__last_value := 0bv32;
  s_reg__wrote_any := false;
  s_reg__wrote_index0 := false;
  s_reg__last0_value := 0bv32;
  while (true) {
    call main();
  }
}

procedure ULTIMATE.start() returns()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  call mainProcedure();
}
"""


def _dynamic_direct_bpl_with_mainprocedure_bv8() -> str:
    return """\
var s_reg:[bv16]bv8;
var s_reg__last_index:bv16;
var s_reg__last_value:bv8;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv8;
var s_meta.register_index:bv16;
var s_tmp:bv8;

procedure {:inline 1} s_get_register_index()
  modifies s_meta.register_index;
{
  s_meta.register_index := s_idx_calc.get$bv32();
}

function {:inline true}s_reg.read(r:[bv16]bv8, i:bv16) returns (bv8) { r[i] }
procedure {:inline 1} s_reg.write(i:bv16, v:bv8)
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value;
{
  s_reg[i] := v;
  s_reg__last_index := i;
  s_reg__last_value := v;
  s_reg__wrote_any := true;
  if (i == 0bv16) { s_reg__wrote_index0 := true; s_reg__last0_value := v; }
}

procedure {:inline 1} s_Ingress()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  call s_get_register_index();
  s_tmp := s_reg.read(s_reg, s_meta.register_index);
  call s_reg.write(s_meta.register_index, s_tmp);
  assert !((s_reg__wrote_any && (s_reg__last_value == 0bv8)));
}

procedure main() returns()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  call s_Ingress();
}

procedure mainProcedure() returns()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  s_reg__last_index := 0bv16;
  s_reg__last_value := 0bv8;
  s_reg__wrote_any := false;
  s_reg__wrote_index0 := false;
  s_reg__last0_value := 0bv8;
  while (true) {
    call main();
  }
}

procedure ULTIMATE.start() returns()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  call mainProcedure();
}
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
    def test_replay_assumes_injected_after_havoc(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl_text = _dynamic_direct_bpl().replace(
                "  call s_get_register_index();\n",
                "  havoc s_meta.register_index;\n  havoc s_tmp;\n  call s_get_register_index();\n",
            )
            bpl.write_text(bpl_text, encoding="utf-8")

            captured_focused_bpl: dict[str, str] = {}

            def fake_runner(**kwargs: Any) -> UltimateRunResult:
                input_bpl = Path(kwargs["input_bpl"])
                if input_bpl.name.endswith(".focused-index0.bpl"):
                    captured_focused_bpl["text"] = input_bpl.read_text(encoding="utf-8")
                log_path = Path(kwargs["log_path"])
                log_path.write_text("no counterexample line\n", encoding="utf-8")
                return UltimateRunResult(
                    returncode=0,
                    log_path=log_path,
                    result_line="RESULT: SAFE",
                )

            replay_assumes = [
                "s_meta.register_index == 0bv16",
                "s_tmp == 7bv32",
            ]
            with mock.patch(
                "dslc.workflows.focused_direct._collect_replay_assumes_from_recent_manifests",
                return_value=(replay_assumes, tmp / "m.json"),
            ):
                rc = run_focused_direct_prepass(
                    bpl_path=bpl,
                    log_dir=tmp,
                    ultimate=tmp / "Ultimate",
                    toolchain=tmp / "ReachSafety.xml",
                    settings=tmp / "settings.epf",
                    ultimate_home=tmp / "ultimate-home",
                    ultimate_timeout_seconds=10,
                    resource_limits=False,
                    ultimate_xmx_gb=1,
                    optimize_bpl=None,
                    ultimate_runner=fake_runner,
                    emit=lambda _msg: None,
                )

            self.assertEqual(rc, 0)
            txt = captured_focused_bpl.get("text", "")
            self.assertTrue(txt)
            self.assertIn("havoc s_meta.register_index;", txt)
            self.assertIn("assume (s_meta.register_index == 0bv16);", txt)
            self.assertIn("havoc s_tmp;", txt)
            self.assertIn("assume (s_tmp == 7bv32);", txt)

    def test_replay_assumes_timeout_still_falls_back(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(_dynamic_direct_bpl(), encoding="utf-8")

            def fake_runner(**kwargs: Any) -> UltimateRunResult:
                log_path = Path(kwargs["log_path"])
                log_path.write_text("no counterexample line\n", encoding="utf-8")
                return UltimateRunResult(
                    returncode=0,
                    log_path=log_path,
                    result_line="RESULT: Ultimate could not prove your program: Timeout",
                )

            with mock.patch(
                "dslc.workflows.focused_direct._collect_replay_assumes_from_recent_manifests",
                return_value=(["s_meta.register_index == 0bv16"], tmp / "m.json"),
            ):
                rc = run_focused_direct_prepass(
                    bpl_path=bpl,
                    log_dir=tmp,
                    ultimate=tmp / "Ultimate",
                    toolchain=tmp / "ReachSafety.xml",
                    settings=tmp / "settings.epf",
                    ultimate_home=tmp / "ultimate-home",
                    ultimate_timeout_seconds=10,
                    resource_limits=False,
                    ultimate_xmx_gb=1,
                    optimize_bpl=None,
                    ultimate_runner=fake_runner,
                    emit=lambda _msg: None,
                )

            self.assertEqual(rc, 0)
            self.assertIsNone(focused_unsafe_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_timeout_on_bv8_target_includes_256_bounded_probe(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(_dynamic_direct_bpl_with_mainprocedure_bv8(), encoding="utf-8")
            seen: list[str] = []

            def fake_runner(**kwargs: Any) -> UltimateRunResult:
                input_bpl = Path(kwargs["input_bpl"])
                seen.append(input_bpl.name)
                log_path = Path(kwargs["log_path"])
                log_path.write_text("no counterexample line\n", encoding="utf-8")
                return UltimateRunResult(
                    returncode=0,
                    log_path=log_path,
                    result_line="RESULT: Ultimate could not prove your program: Timeout",
                )

            rc = run_focused_direct_prepass(
                bpl_path=bpl,
                log_dir=tmp,
                ultimate=tmp / "Ultimate",
                toolchain=tmp / "ReachSafety.xml",
                settings=tmp / "settings.epf",
                ultimate_home=tmp / "ultimate-home",
                ultimate_timeout_seconds=10,
                resource_limits=False,
                ultimate_xmx_gb=1,
                optimize_bpl=None,
                ultimate_runner=fake_runner,
                emit=lambda _msg: None,
            )

            self.assertEqual(rc, 0)
            self.assertTrue(any(name.endswith(".focused-index0.bounded256.bpl") for name in seen))

    def test_timeout_bounded_probe_adds_latch_to_modifies(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(_dynamic_direct_bpl_with_mainprocedure(), encoding="utf-8")
            captured_bounded_text: dict[str, str] = {}

            def fake_runner(**kwargs: Any) -> UltimateRunResult:
                input_bpl = Path(kwargs["input_bpl"])
                log_path = Path(kwargs["log_path"])
                name = input_bpl.name
                if ".bounded" not in name:
                    log_path.write_text("no counterexample line\n", encoding="utf-8")
                    return UltimateRunResult(
                        returncode=0,
                        log_path=log_path,
                        result_line="RESULT: Ultimate could not prove your program: Timeout",
                    )
                txt = input_bpl.read_text(encoding="utf-8")
                captured_bounded_text["text"] = txt
                log_path.write_text("no counterexample line\n", encoding="utf-8")
                return UltimateRunResult(returncode=0, log_path=log_path, result_line="RESULT: SAFE")

            rc = run_focused_direct_prepass(
                bpl_path=bpl,
                log_dir=tmp,
                ultimate=tmp / "Ultimate",
                toolchain=tmp / "ReachSafety.xml",
                settings=tmp / "settings.epf",
                ultimate_home=tmp / "ultimate-home",
                ultimate_timeout_seconds=10,
                resource_limits=False,
                ultimate_xmx_gb=1,
                optimize_bpl=None,
                ultimate_runner=fake_runner,
                emit=lambda _msg: None,
            )

            self.assertEqual(rc, 0)
            bounded = captured_bounded_text.get("text", "")
            self.assertTrue(bounded)
            self.assertIn(
                "procedure {:inline 1} s_Ingress()\n"
                "  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,\n"
                "           s_meta.register_index, s_tmp, procurator_focused_underapprox_hit;\n",
                bounded,
            )
            self.assertIn(
                "procedure mainProcedure() returns()\n"
                "  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,\n"
                "           s_meta.register_index, s_tmp, procurator_focused_underapprox_hit;\n",
                bounded,
            )
            self.assertIn(
                "procedure main() returns()\n"
                "  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,\n"
                "           s_meta.register_index, s_tmp, procurator_focused_underapprox_hit;\n",
                bounded,
            )
            self.assertIn(
                "procedure ULTIMATE.start() returns()\n"
                "  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,\n"
                "           s_meta.register_index, s_tmp, procurator_focused_underapprox_hit;\n",
                bounded,
            )

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

    def test_timeout_triggers_bounded_probe_and_accepts_latch_unsafe(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(_dynamic_direct_bpl_with_mainprocedure(), encoding="utf-8")
            calls: list[dict[str, Any]] = []

            def fake_runner(**kwargs: Any) -> UltimateRunResult:
                calls.append(dict(kwargs))
                input_bpl = Path(kwargs["input_bpl"])
                log_path = Path(kwargs["log_path"])
                name = input_bpl.name
                if ".bounded" not in name:
                    log_path.write_text("no counterexample line\n", encoding="utf-8")
                    return UltimateRunResult(
                        returncode=0,
                        log_path=log_path,
                        result_line="RESULT: Ultimate could not prove your program: Timeout",
                    )
                text = input_bpl.read_text(encoding="utf-8")
                latch_line = None
                for i, raw in enumerate(text.splitlines(), start=1):
                    if "assert !procurator_focused_underapprox_hit" in raw:
                        latch_line = i
                        break
                if latch_line is None:
                    log_path.write_text("no counterexample line\n", encoding="utf-8")
                    return UltimateRunResult(returncode=0, log_path=log_path, result_line="RESULT: SAFE")
                log_path.write_text(f"CounterExampleResult [Line: {latch_line}]\n", encoding="utf-8")
                return UltimateRunResult(returncode=0, log_path=log_path, result_line="RESULT: UNSAFE")

            rc = run_focused_direct_prepass(
                bpl_path=bpl,
                log_dir=tmp,
                ultimate=tmp / "Ultimate",
                toolchain=tmp / "ReachSafety.xml",
                settings=tmp / "settings.epf",
                ultimate_home=tmp / "ultimate-home",
                ultimate_timeout_seconds=10,
                resource_limits=False,
                ultimate_xmx_gb=1,
                optimize_bpl=None,
                ultimate_runner=fake_runner,
                emit=lambda _msg: None,
            )

            self.assertEqual(rc, 1)
            marker = focused_unsafe_marker_for_bpl(out_dir=tmp, bpl_path=bpl)
            self.assertIsNotNone(marker)
            data = json.loads(marker.read_text(encoding="utf-8"))  # type: ignore[union-attr]
            self.assertEqual(data["kind"], "focused_under_approx_bounded")
            self.assertIn(".bounded", data["bpl"])
            self.assertGreaterEqual(len(calls), 2)
            self.assertTrue(any(".bounded" in Path(c["input_bpl"]).name for c in calls))

    def test_timeout_triggers_bounded_probe_for_preunrolled_mainprocedure(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(
                _dynamic_direct_bpl()
                + """\

procedure main() returns()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  call s_Ingress();
}

procedure mainProcedure() returns()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  s_reg__last_index := 0bv16;
  s_reg__last_value := 0bv32;
  s_reg__wrote_any := false;
  s_reg__wrote_index0 := false;
  s_reg__last0_value := 0bv32;
  // UNROLLED 2 steps (bounded)
  call main();
  call main();
}

procedure ULTIMATE.start() returns()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  call mainProcedure();
}
""",
                encoding="utf-8",
            )
            calls: list[dict[str, Any]] = []

            def fake_runner(**kwargs: Any) -> UltimateRunResult:
                calls.append(dict(kwargs))
                input_bpl = Path(kwargs["input_bpl"])
                log_path = Path(kwargs["log_path"])
                if ".bounded" not in input_bpl.name:
                    log_path.write_text("no counterexample line\n", encoding="utf-8")
                    return UltimateRunResult(
                        returncode=0,
                        log_path=log_path,
                        result_line="RESULT: Ultimate could not prove your program: Timeout",
                    )
                text = input_bpl.read_text(encoding="utf-8")
                self.assertIn("assert !procurator_focused_underapprox_hit", text)
                self.assertIn("// UNROLLED 2 steps (bounded)", text)
                latch_line = next(
                    i
                    for i, raw in enumerate(text.splitlines(), start=1)
                    if "assert !procurator_focused_underapprox_hit" in raw
                )
                log_path.write_text(f"CounterExampleResult [Line: {latch_line}]\n", encoding="utf-8")
                return UltimateRunResult(returncode=0, log_path=log_path, result_line="RESULT: UNSAFE")

            rc = run_focused_direct_prepass(
                bpl_path=bpl,
                log_dir=tmp,
                ultimate=tmp / "Ultimate",
                toolchain=tmp / "ReachSafety.xml",
                settings=tmp / "settings.epf",
                ultimate_home=tmp / "ultimate-home",
                ultimate_timeout_seconds=10,
                resource_limits=False,
                ultimate_xmx_gb=1,
                optimize_bpl=None,
                ultimate_runner=fake_runner,
                emit=lambda _msg: None,
            )

            self.assertEqual(rc, 1)
            self.assertTrue(any(".bounded" in Path(c["input_bpl"]).name for c in calls))

    def test_bounded_marker_is_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(_dynamic_direct_bpl(), encoding="utf-8")
            bounded_bpl = tmp / "case.focused-index0.bounded64.bpl"
            bounded_bpl.write_text("procedure ULTIMATE.start() returns() {}\n", encoding="utf-8")
            marker = tmp / "case.focused-index0.unsafe.json"
            marker.write_text(
                json.dumps(
                    {
                        "kind": "focused_under_approx_bounded",
                        "bpl": str(bounded_bpl),
                        "source_bpl": str(bpl),
                        "source_bpl_sha256": hashlib.sha256(bpl.read_bytes()).hexdigest(),
                        "focused_bpl_sha256": hashlib.sha256(bounded_bpl.read_bytes()).hexdigest(),
                    }
                )
                + "\n",
                encoding="utf-8",
            )
            self.assertEqual(focused_unsafe_marker_for_bpl(out_dir=tmp, bpl_path=bpl), marker)


if __name__ == "__main__":
    unittest.main()
