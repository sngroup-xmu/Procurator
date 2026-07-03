from __future__ import annotations

import json
import hashlib
import os
import tempfile
import unittest
from pathlib import Path
from typing import Any
from unittest import mock

from dslc.toolchain.ultimate_runner import UltimateRunResult
from dslc.transform.focused_direct import find_focused_direct_assert_lines
from dslc.workflows.focused_direct import (
    bounded_dsl_replay_marker_for_bpl,
    run_bounded_dsl_replay_prepass,
    focused_unsafe_marker_for_bpl,
    run_focused_direct_prepass,
)


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
  assume (forall i:bv16 :: s_reg[i] == 0bv8);
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


def _bounded_dsl_guard_bpl(*, unknown_side_effect: bool = False) -> str:
    unknown = "  call unknown_side_effect();\n" if unknown_side_effect else ""
    return f"""\
var procurator_bad:bool;
var idx:bv32;
var counter:[bv32]bv32;
var counter__last0_value:bv32;
var tmp:bv32;

function {{:inline true}}counter.read(r:[bv32]bv32, i:bv32) returns (bv32) {{ r[i] }}
procedure {{:inline 1}} counter.write(i:bv32, v:bv32)
  modifies counter, counter__last0_value;
{{
  counter[i] := v;
  if (i == 0bv32) {{ counter__last0_value := v; }}
}}

procedure p4_node() returns()
  modifies idx, tmp, counter, counter__last0_value;
{{
  assume idx == 0bv32;
  tmp := counter.read(counter, idx);
{unknown}  tmp := add.bv32(tmp, 1bv32);
  call counter.write(idx, tmp);
}}

procedure mainProcedure() returns()
  modifies procurator_bad, idx, tmp, counter, counter__last0_value;
{{
  procurator_bad := false;
  assume counter[0bv32] == 1bv32;
  counter__last0_value := 0bv32;
  call p4_node();
  if (!(bvule.bv32$builtin(counter__last0_value, 1bv32))) {{ procurator_bad := true; }}
  assert !procurator_bad;
}}

procedure ULTIMATE.start() returns()
  modifies procurator_bad, idx, tmp, counter, counter__last0_value;
{{
  call mainProcedure();
}}
"""


def _bounded_dsl_guard_with_unknown_register_write_bpl(*, touches_guard_reg: bool) -> str:
    unknown_reg = "counter" if touches_guard_reg else "noise"
    return f"""\
var procurator_bad:bool;
var counter:[bv32]bv32;
var counter__last0_value:bv32;
var noise:[bv32]bv32;
var noise__last0_value:bv32;
var idx:bv32;
var unknown:bv32;

function {{:inline true}}counter.read(r:[bv32]bv32, i:bv32) returns (bv32) {{ r[i] }}
procedure {{:inline 1}} counter.write(i:bv32, v:bv32)
  modifies counter, counter__last0_value;
{{
  counter[i] := v;
  if (i == 0bv32) {{ counter__last0_value := v; }}
}}

function {{:inline true}}noise.read(r:[bv32]bv32, i:bv32) returns (bv32) {{ r[i] }}
procedure {{:inline 1}} noise.write(i:bv32, v:bv32)
  modifies noise, noise__last0_value;
{{
  noise[i] := v;
  if (i == 0bv32) {{ noise__last0_value := v; }}
}}

procedure mainProcedure() returns()
  modifies procurator_bad, counter, counter__last0_value, noise, noise__last0_value, idx, unknown;
{{
  procurator_bad := false;
  assume counter[0bv32] == 1bv32;
  idx := 0bv32;
  call counter.write(idx, 2bv32);
  havoc unknown;
  call {unknown_reg}.write(idx, unknown);
  if (!(bvule.bv32$builtin(counter__last0_value, 1bv32))) {{ procurator_bad := true; }}
  assert !procurator_bad;
}}

procedure ULTIMATE.start() returns()
  modifies procurator_bad, counter, counter__last0_value, noise, noise__last0_value, idx, unknown;
{{
  call mainProcedure();
}}
"""


def _bounded_dsl_guard_with_infeasible_goto_branch_bpl() -> str:
    return """\
var procurator_bad:bool;
var tag:bv16;
var counter:[bv32]bv32;
var counter__last0_value:bv32;

function {:inline true}counter.read(r:[bv32]bv32, i:bv32) returns (bv32) { r[i] }
procedure {:inline 1} counter.write(i:bv32, v:bv32)
  modifies counter, counter__last0_value;
{
  counter[i] := v;
  if (i == 0bv32) { counter__last0_value := v; }
}

procedure choose_path() returns()
  modifies tag, counter, counter__last0_value;
{
  goto wrong, right;

wrong:
  assume (tag == 1bv16);
  call counter.write(0bv32, 0bv32);

right:
  assume (tag == 2bv16);
  call counter.write(0bv32, 2bv32);
}

procedure mainProcedure() returns()
  modifies procurator_bad, tag, counter, counter__last0_value;
{
  procurator_bad := false;
  tag := 2bv16;
  call choose_path();
  if (!(bvule.bv32$builtin(counter__last0_value, 1bv32))) { procurator_bad := true; }
  assert !procurator_bad;
}

procedure ULTIMATE.start() returns()
  modifies procurator_bad, tag, counter, counter__last0_value;
{
  call mainProcedure();
}
"""


def _bounded_dsl_guard_with_unknown_tail_after_guard_state_bpl(*, guard_value_known: bool) -> str:
    initial_value = "2bv32" if guard_value_known else "unknown"
    return f"""\
var procurator_bad:bool;
var counter:[bv32]bv32;
var counter__last0_value:bv32;
var unknown:bv32;

function {{:inline true}}counter.read(r:[bv32]bv32, i:bv32) returns (bv32) {{ r[i] }}
procedure {{:inline 1}} counter.write(i:bv32, v:bv32)
  modifies counter, counter__last0_value;
{{
  counter[i] := v;
  if (i == 0bv32) {{ counter__last0_value := v; }}
}}

procedure p4_tail() returns()
  modifies unknown;
{{
  if (bugt.bv32(unknown, 0bv32)) {{
    unknown := 1bv32;
  }}
}}

procedure mainProcedure() returns()
  modifies procurator_bad, counter, counter__last0_value, unknown;
{{
  procurator_bad := false;
  havoc unknown;
  call counter.write(0bv32, {initial_value});
  call p4_tail();
  if (!(bvule.bv32$builtin(counter__last0_value, 1bv32))) {{ procurator_bad := true; }}
  assert !procurator_bad;
}}

procedure ULTIMATE.start() returns()
  modifies procurator_bad, counter, counter__last0_value, unknown;
{{
  call mainProcedure();
}}
"""


def _bounded_dsl_guard_with_direct_array_read_before_unknown_tail_bpl(*, known_default: bool = True) -> str:
    default_assume = "  assume (forall i:bv32 :: counter[i] == 0bv32);\n" if known_default else ""
    return """\
var procurator_bad:bool;
var cached:bv1;
var src:bv32;
var counter:[bv32]bv32;

procedure p4_tail() returns()
  modifies src;
{
  if (src == 1bv32) {
    src := 2bv32;
  }
}

procedure mainProcedure() returns()
  modifies procurator_bad, cached, src, counter;
{
  procurator_bad := false;
  cached := 1bv1;
""" + default_assume + """  call p4_tail();
  if (!((cached == 0bv1) || (counter[7bv32] != 0bv32))) { procurator_bad := true; }
  assert !procurator_bad;
}

procedure ULTIMATE.start() returns()
  modifies procurator_bad, cached, src, counter;
{
  call mainProcedure();
}
"""


def _bounded_dsl_guard_with_typedef_debug_snapshot_bpl() -> str:
    return """\
type pair = bv64;
var procurator_bad:bool;
var phase:int;
var counter:[bv32]pair;
var counter__dbg0:pair;

procedure mainProcedure() returns()
  modifies procurator_bad, phase, counter, counter__dbg0;
{
  procurator_bad := false;
  phase := 1;
  assume counter[0bv32] == 2bv64;
  counter__dbg0 := counter[0bv32];
  if (!(((phase != 1) || (counter__dbg0 == 0bv64)))) { procurator_bad := true; }
  assert !procurator_bad;
}

procedure ULTIMATE.start() returns()
  modifies procurator_bad, phase, counter, counter__dbg0;
{
  call mainProcedure();
}
"""


def _bounded_dsl_guard_with_return_call_register_action_bpl(
    *,
    with_advance: bool = False,
    with_emit: bool = False,
    with_forward_drop_guard: bool = False,
    with_forward_procedure: bool = False,
    with_ipv4_route_tail: bool = False,
) -> str:
    advance_decl = "procedure pkt.advance(n:bv32);\n" if with_advance else ""
    advance_call = "  call pkt.advance(64bv32);\n" if with_advance else ""
    emit_decl = "procedure pkt.emit(h:pair);\n" if with_emit else ""
    emit_call = "  call pkt.emit(tmp);\n" if with_emit else ""
    forward_drop_decl = "var sw_forward:bool;\nvar sw_drop:bool;\n" if with_forward_drop_guard else ""
    forward_drop_guard = "  if (sw_forward == false) { sw_drop := true; }\n" if with_forward_drop_guard else ""
    forward_proc_decl = "var sw_eg_intr_md.egress_port:bv9;\n" if with_forward_procedure else ""
    forward_proc = (
        """\
procedure sw_Forward() returns()
{
  if (sw_eg_intr_md.egress_port == 0bv9) {
    return;
  }
  return;
}

"""
        if with_forward_procedure
        else ""
    )
    forward_proc_call = "  call sw_Forward();\n" if with_forward_procedure else ""
    ipv4_route_decl = (
        """\
type header_ref;
var sw_isValid:[header_ref]bool;
var sw_hdr.nlk_hdr:header_ref;
var sw_ig_md.routed:bv1;
var sw_ig_md.recirced:bv2;
"""
        if with_ipv4_route_tail
        else ""
    )
    ipv4_route_proc = (
        """\
procedure sw_SwitchIngress_ipv4_route_table.apply() returns()
  modifies sw_ig_md.routed;
{
  sw_ig_md.routed := 1bv1;
}

"""
        if with_ipv4_route_tail
        else ""
    )
    ipv4_route_tail = (
        """\
  if (((sw_isValid[sw_hdr.nlk_hdr]) && ((sw_ig_md.routed == 0bv1))) && ((sw_ig_md.recirced == 0bv2))) {
    call sw_SwitchIngress_ipv4_route_table.apply();
  }
"""
        if with_ipv4_route_tail
        else ""
    )
    main_modifies = "procurator_bad, phase, counter, counter__dbg0, tmp"
    if with_forward_drop_guard:
        main_modifies += ", sw_drop"
    return """\
type pair = bv64;
var procurator_bad:bool;
var phase:int;
var counter:[bv32]pair;
var counter__dbg0:pair;
var tmp:pair;
""" + forward_drop_decl + forward_proc_decl + ipv4_route_decl + """\

function {:inline true}counter.read(r:[bv32]pair, i:bv32) returns (pair) { r[i] }
procedure {:inline 1} counter.write(i:bv32, v:pair)
  modifies counter;
{
  counter[i] := v;
}

procedure {:inline 1} dec_exclusive(v_in:pair) returns (v_out:pair)
{
  var v:pair;
  v := v_in;
  v := add.bv32(v[64:32], 4294967295bv32)++v[32:0];
  v_out := v;
}

""" + advance_decl + emit_decl + forward_proc + ipv4_route_proc + """\
procedure p4_node() returns()
  modifies counter, tmp;
{
""" + advance_call + """\
  tmp := counter.read(counter, 0bv32);
  call tmp := dec_exclusive(tmp);
  call counter.write(0bv32, tmp);
""" + emit_call + """\
}

procedure mainProcedure() returns()
  modifies """ + main_modifies + """;
{
  procurator_bad := false;
  phase := 1;
  assume counter[0bv32] == 0bv64;
  call p4_node();
""" + forward_drop_guard + """\
""" + forward_proc_call + """\
""" + ipv4_route_tail + """\
  counter__dbg0 := counter[0bv32];
  if (!(((phase != 1) || (counter__dbg0 == 0bv64)))) { procurator_bad := true; }
  assert !procurator_bad;
}

procedure ULTIMATE.start() returns()
  modifies procurator_bad, phase, counter, counter__dbg0, tmp;
{
  call mainProcedure();
}
"""


def _bounded_dsl_guard_with_reused_procedure_local_names_bpl() -> str:
    return """\
type pair = bv64;
var procurator_bad:bool;
var out32:bv32;

procedure wide(sw_value_in:pair) returns (sw_value_out:pair)
{
  var sw_value:pair;
  sw_value := sw_value_in;
  sw_value_out := sw_value;
}

procedure narrow(sw_value_in:bv32, sw_result_in:bv32) returns (sw_value_out:bv32, sw_result_out:bv32)
{
  var sw_value:bv32;
  var sw_result:bv32;
  sw_value := sw_value_in;
  sw_result := sw_value;
  sw_value_out := sw_value;
  sw_result_out := sw_result;
}

procedure mainProcedure() returns()
  modifies procurator_bad, out32;
{
  procurator_bad := false;
  call out32, out32 := narrow(7bv32, out32);
  if (!((out32 == 8bv32))) { procurator_bad := true; }
  assert !procurator_bad;
}

procedure ULTIMATE.start() returns()
  modifies procurator_bad, out32;
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
    def test_bounded_dsl_replay_writes_marker_for_deterministic_guard_violation(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(_bounded_dsl_guard_bpl(), encoding="utf-8")

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 1)
            marker = bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl)
            self.assertIsNotNone(marker)
            data = json.loads(marker.read_text(encoding="utf-8"))  # type: ignore[union-attr]
            self.assertEqual(data["kind"], "bounded_dsl_replay_under_approx")
            self.assertEqual(data["result_line"], "RESULT: UNSAFE")
            self.assertIn("assert_line", data)

    def test_bounded_dsl_replay_marker_points_to_synthetic_log(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(_bounded_dsl_guard_bpl(), encoding="utf-8")

            self.assertEqual(run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None), 1)
            marker = bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl)
            self.assertIsNotNone(marker)
            data = json.loads(marker.read_text(encoding="utf-8"))  # type: ignore[union-attr]

            self.assertTrue(Path(data["log"]).name.endswith(".bounded-dsl-replay.textual.log"))
            self.assertIn("RESULT: UNSAFE", Path(data["log"]).read_text(encoding="utf-8"))

    def test_bounded_dsl_replay_rejects_unknown_side_effect(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(_bounded_dsl_guard_bpl(unknown_side_effect=True), encoding="utf-8")

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 0)
            self.assertIsNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_forgets_unrelated_unknown_register_write(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(
                _bounded_dsl_guard_with_unknown_register_write_bpl(touches_guard_reg=False),
                encoding="utf-8",
            )

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 1)
            self.assertIsNotNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_rejects_unknown_write_to_guard_register(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(
                _bounded_dsl_guard_with_unknown_register_write_bpl(touches_guard_reg=True),
                encoding="utf-8",
            )

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 0)
            self.assertIsNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_skips_infeasible_goto_branch(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(_bounded_dsl_guard_with_infeasible_goto_branch_bpl(), encoding="utf-8")

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 1)
            self.assertIsNotNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_accepts_final_guard_before_unknown_tail(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(
                _bounded_dsl_guard_with_unknown_tail_after_guard_state_bpl(guard_value_known=True),
                encoding="utf-8",
            )

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 1)
            self.assertIsNotNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_accepts_direct_array_guard_before_unknown_tail(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(
                _bounded_dsl_guard_with_direct_array_read_before_unknown_tail_bpl(),
                encoding="utf-8",
            )

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 1)
            self.assertIsNotNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_accepts_typedef_register_debug_snapshot(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(_bounded_dsl_guard_with_typedef_debug_snapshot_bpl(), encoding="utf-8")

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 1)
            self.assertIsNotNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_executes_return_call_register_action(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(_bounded_dsl_guard_with_return_call_register_action_bpl(), encoding="utf-8")

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 1)
            self.assertIsNotNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_treats_packet_advance_as_noop(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(
                _bounded_dsl_guard_with_return_call_register_action_bpl(with_advance=True),
                encoding="utf-8",
            )

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 1)
            self.assertIsNotNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_treats_packet_emit_as_noop(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(
                _bounded_dsl_guard_with_return_call_register_action_bpl(with_emit=True),
                encoding="utf-8",
            )

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 1)
            self.assertIsNotNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_skips_unknown_forward_drop_guard(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(
                _bounded_dsl_guard_with_return_call_register_action_bpl(with_forward_drop_guard=True),
                encoding="utf-8",
            )

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 1)
            self.assertIsNotNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_skips_forward_return_guard(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(
                _bounded_dsl_guard_with_return_call_register_action_bpl(with_forward_procedure=True),
                encoding="utf-8",
            )

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 1)
            self.assertIsNotNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_skips_unknown_ipv4_route_tail(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(
                _bounded_dsl_guard_with_return_call_register_action_bpl(with_ipv4_route_tail=True),
                encoding="utf-8",
            )

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 1)
            self.assertIsNotNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_uses_procedure_local_types_for_reused_names(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(_bounded_dsl_guard_with_reused_procedure_local_names_bpl(), encoding="utf-8")

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 1)
            self.assertIsNotNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_rejects_direct_array_guard_with_unknown_slot(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(
                _bounded_dsl_guard_with_direct_array_read_before_unknown_tail_bpl(known_default=False),
                encoding="utf-8",
            )

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 0)
            self.assertIsNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_rejects_unknown_tail_when_final_guard_is_unknown(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(
                _bounded_dsl_guard_with_unknown_tail_after_guard_state_bpl(guard_value_known=False),
                encoding="utf-8",
            )

            rc = run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None)

            self.assertEqual(rc, 0)
            self.assertIsNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_marker_rejects_stale_source(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(_bounded_dsl_guard_bpl(), encoding="utf-8")
            self.assertEqual(run_bounded_dsl_replay_prepass(bpl_path=bpl, log_dir=tmp, emit=lambda _msg: None), 1)
            self.assertIsNotNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

            bpl.write_text(bpl.read_text(encoding="utf-8") + "\n// changed\n", encoding="utf-8")

            self.assertIsNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=bpl))

    def test_bounded_dsl_replay_marker_accepts_cwd_relative_bpl_path(self) -> None:
        with tempfile.TemporaryDirectory(dir=Path.cwd()) as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(_bounded_dsl_guard_bpl(), encoding="utf-8")
            rel_bpl = bpl.relative_to(Path.cwd())

            self.assertEqual(run_bounded_dsl_replay_prepass(bpl_path=rel_bpl, log_dir=tmp, emit=lambda _msg: None), 1)

            self.assertIsNotNone(bounded_dsl_replay_marker_for_bpl(out_dir=tmp, bpl_path=rel_bpl))

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
            # Keep the slot value opaque so this test exercises the solver-backed
            # bounded-probe schedule rather than the deterministic textual replay
            # shortcut.
            bpl.write_text(
                _dynamic_direct_bpl_with_mainprocedure_bv8().replace(
                    "  assume (forall i:bv16 :: s_reg[i] == 0bv8);\n",
                    "",
                ),
                encoding="utf-8",
            )
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

    def test_textual_bounded_latch_witness_short_circuits_solver(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(
                _dynamic_direct_bpl_with_mainprocedure_bv8().replace(
                    "  call s_reg.write(s_meta.register_index, s_tmp);\n",
                    "  call s_reg.write(s_meta.register_index, add.bv8(s_tmp, 1bv8));\n",
                ),
                encoding="utf-8",
            )
            calls: list[dict[str, Any]] = []

            def fake_runner(**kwargs: Any) -> UltimateRunResult:
                calls.append(dict(kwargs))
                log_path = Path(kwargs["log_path"])
                log_path.write_text("no counterexample line\n", encoding="utf-8")
                return UltimateRunResult(
                    returncode=124,
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

            self.assertEqual(rc, 1)
            self.assertEqual(len(calls), 1)
            marker = focused_unsafe_marker_for_bpl(out_dir=tmp, bpl_path=bpl)
            self.assertIsNotNone(marker)
            data = json.loads(marker.read_text(encoding="utf-8"))  # type: ignore[union-attr]
            self.assertEqual(data["kind"], "focused_under_approx_bounded")
            self.assertIn("textual latch replay", data["note"])
            self.assertTrue(Path(data["log"]).name.endswith(".textual.log"))

    def test_textual_bounded_latch_rejects_oldnew_guarded_reset(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            guarded = _dynamic_direct_bpl_with_mainprocedure_bv8().replace(
                "var s_reg__last_value:bv8;\n",
                "var s_reg__last_value:bv8;\nvar s_reg__last_old_value:bv8;\n",
            ).replace(
                "var s_reg__last0_value:bv8;\n",
                "var s_reg__last0_value:bv8;\nvar s_reg__last0_old_value:bv8;\n",
            ).replace(
                "  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value;\n",
                "  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__last_old_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value, s_reg__last0_old_value;\n",
            ).replace(
                "  s_reg[i] := v;\n",
                "  s_reg__last_old_value := s_reg[i];\n  s_reg[i] := v;\n",
            ).replace(
                "  if (i == 0bv16) { s_reg__wrote_index0 := true; s_reg__last0_value := v; }\n",
                "  if (i == 0bv16) { s_reg__wrote_index0 := true; s_reg__last0_old_value := s_reg__last_old_value; s_reg__last0_value := v; }\n",
            ).replace(
                "  assert !((s_reg__wrote_any && (s_reg__last_value == 0bv8)));\n",
                "  assert !((s_reg__wrote_any && (s_reg__last_old_value == 255bv8) && (s_reg__last_value == 0bv8)));\n",
            ).replace(
                "  s_reg__last_value := 0bv8;\n",
                "  s_reg__last_value := 0bv8;\n  s_reg__last_old_value := 0bv8;\n",
            ).replace(
                "  s_reg__last0_value := 0bv8;\n",
                "  s_reg__last0_value := 0bv8;\n  s_reg__last0_old_value := 0bv8;\n",
            ).replace(
                "  call s_reg.write(s_meta.register_index, s_tmp);\n",
                "  call s_reg.write(s_meta.register_index, add.bv8(s_tmp, 1bv8));\n"
                "  if (buge.bv8(s_tmp, 128bv8)) {\n"
                "    call s_reg.write(s_meta.register_index, 0bv8);\n"
                "  }\n",
            )
            bpl.write_text(guarded, encoding="utf-8")
            calls: list[dict[str, Any]] = []

            def fake_runner(**kwargs: Any) -> UltimateRunResult:
                calls.append(dict(kwargs))
                log_path = Path(kwargs["log_path"])
                log_path.write_text("no counterexample line\n", encoding="utf-8")
                return UltimateRunResult(
                    returncode=124,
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
            self.assertIsNone(focused_unsafe_marker_for_bpl(out_dir=tmp, bpl_path=bpl))
            self.assertTrue(any(".bounded" in Path(c["input_bpl"]).name for c in calls))

    def test_textual_bounded_latch_rejects_unknown_call_side_effect(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(
                _dynamic_direct_bpl_with_mainprocedure_bv8().replace(
                    "  call s_reg.write(s_meta.register_index, s_tmp);\n",
                    "  call unknown_side_effect();\n"
                    "  call s_reg.write(s_meta.register_index, add.bv8(s_tmp, 1bv8));\n",
                ),
                encoding="utf-8",
            )
            calls: list[dict[str, Any]] = []

            def fake_runner(**kwargs: Any) -> UltimateRunResult:
                calls.append(dict(kwargs))
                log_path = Path(kwargs["log_path"])
                log_path.write_text("no counterexample line\n", encoding="utf-8")
                return UltimateRunResult(
                    returncode=124,
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
            self.assertIsNone(focused_unsafe_marker_for_bpl(out_dir=tmp, bpl_path=bpl))
            self.assertTrue(any(".bounded" in Path(c["input_bpl"]).name for c in calls))

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

    def test_explicit_short_timeout_is_respected_for_prepass(self) -> None:
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
            self.assertEqual(calls[0]["os_timeout_seconds"], 67)

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
            self.assertEqual(calls[0]["toolchain_timeout_seconds"], 60)
            self.assertEqual(calls[0]["os_timeout_seconds"], 120)

    def test_large_direct_timeout_is_capped_for_prepass(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            calls: list[dict[str, Any]] = []
            rc = _run_prepass(
                tmp,
                result_line="RESULT: SAFE",
                hit="focused",
                ultimate_timeout_seconds=180,
                calls=calls,
            )

            self.assertEqual(rc, 0)
            self.assertEqual(len(calls), 1)
            self.assertEqual(calls[0]["toolchain_timeout_seconds"], 60)
            self.assertEqual(calls[0]["os_timeout_seconds"], 120)

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

    def test_missing_result_with_nonzero_returncode_triggers_bounded_probe(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            bpl = tmp / "case.bpl"
            bpl.write_text(_dynamic_direct_bpl_with_mainprocedure(), encoding="utf-8")
            calls: list[dict[str, Any]] = []

            def fake_runner(**kwargs: Any) -> UltimateRunResult:
                calls.append(dict(kwargs))
                input_bpl = Path(kwargs["input_bpl"])
                log_path = Path(kwargs["log_path"])
                if ".bounded" not in input_bpl.name:
                    log_path.write_text("Received shutdown request...\n", encoding="utf-8")
                    return UltimateRunResult(returncode=124, log_path=log_path, result_line=None)
                text = input_bpl.read_text(encoding="utf-8")
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
