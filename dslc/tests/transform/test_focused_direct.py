from __future__ import annotations

import unittest

from dslc.transform.focused_direct import find_focused_direct_assert_lines, focus_dynamic_index0_register_assert


class TestFocusedDirectTransform(unittest.TestCase):
    def test_dynamic_index0_register_assert_is_scalarized(self) -> None:
        bpl = """\
var s_reg:[bv16]bv32;
var s_reg__last_index:bv16;
var s_reg__last_value:bv32;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv32;
var s_time:[bv16]bv32;
var s_time__last_index:bv16;
var s_time__last_value:bv32;
var s_time__wrote_any:bool;
var s_time__wrote_index0:bool;
var s_time__last0_value:bv32;
var s_meta.register_index:bv16;
var s_tmp:bv32;

procedure {:inline 1} s_get_register_index()
  modifies s_meta.register_index;
{
  s_meta.register_index := s_idx_calc.get$bv32();
}

function {:inline true}s_time.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }
procedure {:inline 1} s_time.write(i:bv16, v:bv32)
  modifies s_time, s_time__last_index, s_time__last_value, s_time__wrote_any, s_time__wrote_index0, s_time__last0_value;
{
  s_time[i] := v;
  s_time__last_index := i;
  s_time__last_value := v;
  s_time__wrote_any := true;
  if (i == 0bv16) { s_time__wrote_index0 := true; s_time__last0_value := v; }
}

function {:inline true}s_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }
procedure {:inline 1} s_reg.write(i:bv16, v:bv32)
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
           s_time, s_time__last_index, s_time__last_value, s_time__wrote_any, s_time__wrote_index0, s_time__last0_value,
           s_meta.register_index, s_tmp;
{
  call s_get_register_index();
  s_tmp := s_time.read(s_time, s_meta.register_index);
  call s_time.write(s_meta.register_index, s_tmp);
  s_tmp := s_reg.read(s_reg, s_meta.register_index);
  call s_reg.write(s_meta.register_index, s_tmp);
  assert !((s_reg__wrote_any && (s_reg__last_value == 0bv32)));
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertTrue(res.changed)
        self.assertIn("focused s_reg at s_meta.register_index == 0bv16", res.reason)
        self.assertIn("assume s_meta.register_index == 0bv16;", res.text)
        self.assertIn("s_tmp := s_time[0bv16];", res.text)
        self.assertIn("s_tmp := s_reg[0bv16];", res.text)
        self.assertIn("s_reg[0bv16] := s_tmp;", res.text)
        self.assertIn("s_reg__last_index := 0bv16;", res.text)
        self.assertIn("s_reg__last0_value := s_tmp;", res.text)
        self.assertEqual(res.target_reg, "s_reg")
        self.assertEqual(res.idx_var, "s_meta.register_index")
        self.assertEqual(res.zero, "0bv16")
        self.assertEqual(res.target_value, "0bv32")
        self.assertIsNotNone(res.assert_line)
        self.assertEqual(res.assert_lines, (res.assert_line,))
        self.assertGreater(res.text.count("assume s_meta.register_index == 0bv16;"), 1)
        self.assertNotIn("call s_reg.write(s_meta.register_index, s_tmp);", res.text)
        self.assertNotIn("s_tmp := s_reg.read(s_reg, s_meta.register_index);", res.text)

    def test_repeated_same_target_assertions_are_scalarized(self) -> None:
        bpl = """\
var s_reg:[bv16]bv32;
var s_reg__last_index:bv16;
var s_reg__last_value:bv32;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv32;
var s_meta.register_index:bv16;
var s_tmp:bv32;

procedure {:inline 1} s_get_register_index()
  modifies s_meta.register_index;
{
  s_meta.register_index := s_idx_calc.get$bv32();
}

function {:inline true}s_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }
procedure {:inline 1} s_reg.write(i:bv16, v:bv32)
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
  assert !((s_reg__wrote_any && (s_reg__last_value == 0bv32)));
  assert !((s_reg__wrote_any && (s_reg__last_value == 0bv32)));
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertTrue(res.changed)
        self.assertEqual(res.target_reg, "s_reg")
        self.assertEqual(len(res.assert_lines), 2)
        self.assertEqual(res.assert_line, res.assert_lines[0])
        self.assertIn("s_reg[0bv16] := s_tmp;", res.text)

    def test_assert_lines_can_be_refreshed_after_bpl_post_optimization(self) -> None:
        bpl = """\
var s_reg:[bv16]bv32;
var s_reg__last_index:bv16;
var s_reg__last_value:bv32;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv32;
var s_meta.register_index:bv16;
var s_tmp:bv32;

procedure {:inline 1} s_get_register_index()
  modifies s_meta.register_index;
{
  s_meta.register_index := s_idx_calc.get$bv32();
}

function {:inline true}s_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }
procedure {:inline 1} s_reg.write(i:bv16, v:bv32)
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
  assume (forall i:bv16 :: s_reg[i] == 0bv32);
  assume (forall i:bv16 :: s_other[i] == 0bv32);
  if (guard) {
    assert !((s_reg__wrote_any && (s_reg__last_value == 0bv32)));
  }
}
"""

        res = focus_dynamic_index0_register_assert(bpl)
        self.assertTrue(res.changed)
        optimized_text = "\n".join(
            line for line in res.text.splitlines() if "forall i:bv16" not in line
        )
        refreshed = find_focused_direct_assert_lines(optimized_text, "s_reg", "0bv32")

        self.assertNotEqual(refreshed, res.assert_lines)
        self.assertEqual(len(refreshed), 1)
        self.assertIn("assert !((s_reg__wrote_index0", optimized_text.splitlines()[refreshed[0] - 1])

    def test_havoced_index_is_reconstrained_before_each_scalarized_access(self) -> None:
        bpl = """\
var s_reg:[bv16]bv32;
var s_reg__last_index:bv16;
var s_reg__last_value:bv32;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv32;
var s_meta.register_index:bv16;
var s_tmp:bv32;

procedure {:inline 1} s_get_register_index()
  modifies s_meta.register_index;
{
  s_meta.register_index := s_idx_calc.get$bv32();
}

function {:inline true}s_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }
procedure {:inline 1} s_reg.write(i:bv16, v:bv32)
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
  havoc s_meta.register_index;
  s_tmp := s_reg.read(s_reg, s_meta.register_index);
  havoc s_meta.register_index;
  call s_reg.write(s_meta.register_index, s_tmp);
  assert !((s_reg__wrote_any && (s_reg__last_value == 0bv32)));
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertTrue(res.changed)
        self.assertGreaterEqual(res.text.count("assume s_meta.register_index == 0bv16;"), 3)
        self.assertIn("havoc s_meta.register_index;\n  assume s_meta.register_index == 0bv16;\n  s_tmp := s_reg[0bv16];", res.text)
        self.assertIn("havoc s_meta.register_index;\n  assume s_meta.register_index == 0bv16;\n  s_reg[0bv16] := s_tmp;", res.text)

    def test_focused_reads_use_array_slot_not_last_write_mirror(self) -> None:
        bpl = """\
var s_reg:[bv16]bv32;
var s_reg__last_index:bv16;
var s_reg__last_value:bv32;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv32;
var s_meta.register_index:bv16;
var s_tmp:bv32;

procedure {:inline 1} s_get_register_index()
  modifies s_meta.register_index;
{
  s_meta.register_index := s_idx_calc.get$bv32();
}

function {:inline true}s_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }
procedure {:inline 1} s_reg.write(i:bv16, v:bv32)
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
  assert !((s_reg__wrote_any && (s_reg__last_value == 0bv32)));
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertTrue(res.changed)
        self.assertIn("s_tmp := s_reg[0bv16];", res.text)
        self.assertNotIn("s_tmp := s_reg__last0_value;", res.text)

    def test_fail_fast_target_write_is_constrained_not_scalarized(self) -> None:
        bpl = """\
var s_reg:[bv16]bv32;
var s_reg__last_index:bv16;
var s_reg__last_value:bv32;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv32;
var s_meta.register_index:bv16;
var s_tmp:bv32;

procedure {:inline 1} s_get_register_index()
  modifies s_meta.register_index;
{
  s_meta.register_index := s_idx_calc.get$bv32();
}

function {:inline true}s_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }
procedure {:inline 1} s_reg.write(i:bv16, v:bv32)
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value;
{
  s_reg[i] := v;
  s_reg__last_index := i;
  s_reg__last_value := v;
  s_reg__wrote_any := true;
  if (s_reg__wrote_any && s_reg__last_value == 0bv32) {
    assert false;
    assume false;
  }
  if (i == 0bv16) { s_reg__wrote_index0 := true; s_reg__last0_value := v; }
}

procedure {:inline 1} s_Ingress()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  call s_get_register_index();
  s_tmp := s_reg.read(s_reg, s_meta.register_index);
  call s_reg.write(s_meta.register_index, s_tmp);
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertTrue(res.changed)
        self.assertIn("assume s_meta.register_index == 0bv16;\n  s_reg[0bv16] := s_tmp;", res.text)
        self.assertNotIn("call s_reg.write(s_meta.register_index, s_tmp);", res.text)
        self.assertIn("if (s_reg__wrote_index0 && s_reg__last0_value == 0bv32)", res.text)
        self.assertGreaterEqual(len(res.assert_lines), 1)
        self.assertTrue(
            any("assert false;" in res.text.splitlines()[line_no - 1] for line_no in res.assert_lines)
        )

    def test_target_global_assertion_is_rewritten_to_index0(self) -> None:
        bpl = """\
var s_reg:[bv16]bv32;
var s_reg__last_index:bv16;
var s_reg__last_value:bv32;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv32;
var s_meta.register_index:bv16;
var s_tmp:bv32;
var procurator_bad: bool;

procedure {:inline 1} s_get_register_index()
  modifies s_meta.register_index;
{
  s_meta.register_index := s_idx_calc.get$bv32();
}

function {:inline true}s_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }
procedure {:inline 1} s_reg.write(i:bv16, v:bv32)
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
           s_meta.register_index, s_tmp, procurator_bad;
{
  call s_get_register_index();
  s_tmp := s_reg.read(s_reg, s_meta.register_index);
  call s_reg.write(s_meta.register_index, s_tmp);
  assert !((s_reg__wrote_any && (s_reg__last_value == 0bv32)));
  if (!(!((s_reg__wrote_any && (s_reg__last_value == 0bv32))))) { procurator_bad := true; }
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertTrue(res.changed)
        self.assertIn("assert !((s_reg__wrote_index0 && (s_reg__last0_value == 0bv32)));", res.text)
        self.assertIn("if (s_reg__wrote_index0 && s_reg__last0_value == 0bv32)", res.text)
        self.assertIn("assert false;", res.text)
        self.assertNotIn("if (!(!((s_reg__wrote_any && (s_reg__last_value == 0bv32)))))", res.text)
        self.assertNotIn("procurator_bad := true;", res.text)
        self.assertNotIn("assert !procurator_bad;", res.text)
        self.assertEqual(len(res.assert_lines), 2)

    def test_action_guarded_assert_uses_guarded_writer_site_only(self) -> None:
        bpl = """\
var s_reg:[bv16]bv8;
var s_reg__last_index:bv16;
var s_reg__last_value:bv8;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv8;
var s_meta.register_index:bv16;
var s_tmp:bv8;
var s_pkt_bin2.action_run:int;
const s_pkt_bin2.action.SwitchIngress_Update_bin2:int;
const s_pkt_bin2.action.SwitchIngress_Init0_bin2:int;

procedure {:inline 1} s_get_register_index()
  modifies s_meta.register_index;
{
  s_meta.register_index := s_idx_calc.get$bv32();
}

procedure {:inline 1} s_SwitchIngress_Init0_bin2()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index;
{
  assume s_meta.register_index == 0bv16;
  s_reg[0bv16] := 0bv8;
  s_reg__last_index := 0bv16;
  s_reg__last_value := 0bv8;
  s_reg__wrote_any := true;
  s_reg__wrote_index0 := true;
  s_reg__last0_value := 0bv8;
}

procedure {:inline 1} s_SwitchIngress_Update_bin2()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  call s_get_register_index();
  s_tmp := s_reg.read(s_reg, s_meta.register_index);
  call s_reg.write(s_meta.register_index, add.bv8(s_tmp, 1bv8));
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

procedure {:inline 1} s_pkt_bin2.apply()
  modifies s_pkt_bin2.action_run, s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  goto s_action_update, s_action_init0;

  s_action_update:
  assume s_pkt_bin2.action_run == s_pkt_bin2.action.SwitchIngress_Update_bin2;
  call s_SwitchIngress_Update_bin2();
  goto s_exit;

  s_action_init0:
  assume s_pkt_bin2.action_run == s_pkt_bin2.action.SwitchIngress_Init0_bin2;
  call s_SwitchIngress_Init0_bin2();
  goto s_exit;

  s_exit:
}

procedure mainProcedure()
  modifies s_pkt_bin2.action_run, s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  call s_pkt_bin2.apply();
  if (s_pkt_bin2.action_run == s_pkt_bin2.action.SwitchIngress_Update_bin2) {
    assert !((s_reg__wrote_any && (s_reg__last_value == 0bv8)));
  }
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertTrue(res.changed)
        self.assertNotIn("assert !((s_reg__wrote_index0 && (s_reg__last0_value == 0bv8)));", res.text)
        self.assertEqual(len(res.assert_lines), 1)
        assert_line = res.assert_lines[0]
        text_lines = res.text.splitlines()
        self.assertIn("assert false;", text_lines[assert_line - 1])
        self.assertIn(
            "s_reg[0bv16] := add.bv8(s_tmp, 1bv8);",
            "\n".join(text_lines[max(0, assert_line - 8) : assert_line + 2]),
        )
        init0_body = res.text.split("procedure {:inline 1} s_SwitchIngress_Init0_bin2()", 1)[1].split(
            "procedure {:inline 1} s_SwitchIngress_Update_bin2()", 1
        )[0]
        self.assertNotIn("assert false;", init0_body)

    def test_packed_register_slice_assert_is_scalarized(self) -> None:
        bpl = """\
var s_reg:[bv15]bv64;
var s_reg__last_index:bv15;
var s_reg__last_value:bv64;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv64;
var s_meta.pool_index:bv15;
var s_tmp:bv64;

procedure {:inline 1} s_get_pool_index()
  modifies s_meta.pool_index;
{
  s_meta.pool_index := s_idx_calc.get$bv32();
}

function {:inline true}s_reg.read(r:[bv15]bv64, i:bv15) returns (bv64) { r[i] }
procedure {:inline 1} s_reg.write(i:bv15, v:bv64)
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value;
{
  s_reg[i] := v;
  s_reg__last_index := i;
  s_reg__last_value := v;
  s_reg__wrote_any := true;
  if (i == 0bv15) { s_reg__wrote_index0 := true; s_reg__last0_value := v; }
}

procedure {:inline 1} s_UpdatePacked()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.pool_index, s_tmp;
{
  call s_get_pool_index();
  s_tmp := s_reg.read(s_reg, s_meta.pool_index);
  call s_reg.write(s_meta.pool_index, add.bv32(s_tmp[64:32], 1bv32)++s_tmp[32:0]);
  assert !((s_reg__wrote_any && (s_reg__last_value[64:32] == 0bv32)));
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertTrue(res.changed)
        self.assertEqual(res.target_reg, "s_reg")
        self.assertEqual(res.idx_var, "s_meta.pool_index")
        self.assertEqual(res.target_value, "0bv32")
        self.assertEqual(res.target_slice, (64, 32))
        self.assertIn("s_tmp := s_reg[0bv15];", res.text)
        self.assertIn("s_reg[0bv15] := add.bv32(s_tmp[64:32], 1bv32)++s_tmp[32:0];", res.text)
        self.assertIn("assert !((s_reg__wrote_index0 && (s_reg__last0_value[64:32] == 0bv32)));", res.text)
        refreshed = find_focused_direct_assert_lines(res.text, "s_reg", "0bv32", (64, 32))
        self.assertEqual(refreshed, res.assert_lines)

    def test_ambiguous_index_definition_still_constrains_target_accesses(self) -> None:
        bpl = """\
var s_reg:[bv15]bv64;
var s_reg__last_index:bv15;
var s_reg__last_value:bv64;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv64;
var s_meta.pool_index:bv15;
var s_tmp:bv64;

procedure {:inline 1} s_udp_path()
  modifies s_meta.pool_index;
{
  s_meta.pool_index := 1bv15;
}

procedure {:inline 1} s_rdma_path()
  modifies s_meta.pool_index;
{
  s_meta.pool_index := 2bv15;
}

function {:inline true}s_reg.read(r:[bv15]bv64, i:bv15) returns (bv64) { r[i] }
procedure {:inline 1} s_reg.write(i:bv15, v:bv64)
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value;
{
  s_reg[i] := v;
  s_reg__last_index := i;
  s_reg__last_value := v;
  s_reg__wrote_any := true;
  if (i == 0bv15) { s_reg__wrote_index0 := true; s_reg__last0_value := v; }
}

procedure {:inline 1} s_UpdatePacked()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.pool_index, s_tmp;
{
  call s_udp_path();
  call s_rdma_path();
  s_tmp := s_reg.read(s_reg, s_meta.pool_index);
  call s_reg.write(s_meta.pool_index, s_tmp);
  assert !((s_reg__wrote_any && (s_reg__last_value[64:32] == 0bv32)));
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertTrue(res.changed)
        self.assertIn("assume s_meta.pool_index == 0bv15;", res.text)
        self.assertIn("s_tmp := s_reg[0bv15];", res.text)
        self.assertIn("s_reg[0bv15] := s_tmp;", res.text)

    def test_old_broad_fail_fast_is_not_an_accepted_focused_line(self) -> None:
        bpl = """\
var s_reg:[bv16]bv32;
var s_reg__last_index:bv16;
var s_reg__last_value:bv32;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv32;
var s_meta.register_index:bv16;
var s_tmp:bv32;

procedure {:inline 1} s_get_register_index()
  modifies s_meta.register_index;
{
  s_meta.register_index := s_idx_calc.get$bv32();
}

function {:inline true}s_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }
procedure {:inline 1} s_reg.write(i:bv16, v:bv32)
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value;
{
  s_reg[i] := v;
  s_reg__last_index := i;
  s_reg__last_value := v;
  s_reg__wrote_any := true;
  if (s_reg__wrote_any && s_reg__last_value == 0bv32) {
    assert false;
    assume false;
  }
  if (i == 0bv16) { s_reg__wrote_index0 := true; s_reg__last0_value := v; }
}

procedure {:inline 1} s_Ingress()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  call s_get_register_index();
  s_tmp := s_reg.read(s_reg, s_meta.register_index);
  call s_reg.write(s_meta.register_index, s_tmp);
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertTrue(res.changed)
        self.assertNotIn("if (s_reg__wrote_any && s_reg__last_value == 0bv32)", res.text)
        self.assertEqual(len(res.assert_lines), 1)
        assert_line = res.assert_lines[0]
        self.assertIn("assert false;", res.text.splitlines()[assert_line - 1])
        self.assertIn("s_reg__wrote_index0 && s_reg__last0_value == 0bv32", res.text.splitlines()[assert_line - 2])

    def test_no_unique_direct_assertion_is_left_unchanged(self) -> None:
        bpl = """\
var s_reg:[bv16]bv32;
var s_reg__last_index:bv16;
var s_reg__last_value:bv32;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv32;
var s_meta.register_index:bv16;

procedure {:inline 1} s_Ingress()
{
  assert true;
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertFalse(res.changed)
        self.assertEqual(res.text, bpl)

    def test_scalarization_requires_index_pin_call(self) -> None:
        bpl = """\
var s_reg:[bv16]bv32;
var s_reg__last_index:bv16;
var s_reg__last_value:bv32;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv32;
var s_meta.register_index:bv16;
var s_tmp:bv32;

procedure {:inline 1} s_get_register_index()
  modifies s_meta.register_index;
{
  s_meta.register_index := s_idx_calc.get$bv32();
}

function {:inline true}s_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }
procedure {:inline 1} s_reg.write(i:bv16, v:bv32)
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
  s_tmp := s_reg.read(s_reg, s_meta.register_index);
  call s_reg.write(s_meta.register_index, s_tmp);
  assert !((s_reg__wrote_any && (s_reg__last_value == 0bv32)));
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertFalse(res.changed)
        self.assertEqual(res.reason, "index variable was not pinned at its definition call")

    def test_index_reassignment_stops_scalarization_region(self) -> None:
        bpl = """\
var s_reg:[bv16]bv32;
var s_reg__last_index:bv16;
var s_reg__last_value:bv32;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv32;
var s_meta.register_index:bv16;
var s_tmp:bv32;

procedure {:inline 1} s_get_register_index()
  modifies s_meta.register_index;
{
  s_meta.register_index := s_idx_calc.get$bv32();
}

function {:inline true}s_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }
procedure {:inline 1} s_reg.write(i:bv16, v:bv32)
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
  s_meta.register_index := 1bv16;
  call s_reg.write(s_meta.register_index, s_tmp);
  assert !((s_reg__wrote_any && (s_reg__last_value == 0bv32)));
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertTrue(res.changed)
        self.assertIn("s_tmp := s_reg[0bv16];", res.text)
        self.assertIn("s_reg[0bv16] := s_tmp;", res.text)
        self.assertNotIn("call s_reg.write(s_meta.register_index, s_tmp);", res.text)

    def test_generic_call_helper_uses_nonzero_constant_hash_slot(self) -> None:
        bpl = """\
var flowdos_reg:[bv32]bv8;
var flowdos_reg__last_index:bv32;
var flowdos_reg__last_value:bv8;
var flowdos_reg__wrote_any:bool;
var flowdos_reg__wrote_index0:bool;
var flowdos_reg__last0_value:bv8;
var flowdos_counter_pos:bv32;
var flowdos_counter_val:bv8;
var flowdos_src:bv32;

function {:inline true} flowdos___p4b_crc16_bmv2_bit(flowdos_crc:bv16) returns(bv16) { (if (flowdos_crc)[1:0] == 1bv1 then bxor.bv16(shr.bv16(flowdos_crc, 1bv16), 40961bv16) else shr.bv16(flowdos_crc, 1bv16)) }
function {:inline true} flowdos___p4b_crc16_bmv2_byte(flowdos_crc:bv16, flowdos_byte:bv8) returns(bv16) { flowdos___p4b_crc16_bmv2_bit(flowdos___p4b_crc16_bmv2_bit(flowdos___p4b_crc16_bmv2_bit(flowdos___p4b_crc16_bmv2_bit(flowdos___p4b_crc16_bmv2_bit(flowdos___p4b_crc16_bmv2_bit(flowdos___p4b_crc16_bmv2_bit(flowdos___p4b_crc16_bmv2_bit(bxor.bv16(flowdos_crc, 0bv8++(flowdos_byte)))))))))) }

procedure {:inline 1} flowdos_compute_hash()
  modifies flowdos_counter_pos, flowdos_src;
{
  flowdos_src := 167772161bv32;
  flowdos_counter_pos := (if 4096bv32 == 0bv32 then 0bv32 else add.bv32(0bv32, urem.bv32(0bv16++(flowdos___p4b_crc16_bmv2_byte(flowdos___p4b_crc16_bmv2_byte(flowdos___p4b_crc16_bmv2_byte(flowdos___p4b_crc16_bmv2_byte(0bv16, (flowdos_src)[32:24]), (flowdos_src)[24:16]), (flowdos_src)[16:8]), (flowdos_src)[8:0])), 4096bv32)));
}

function {:inline true}flowdos_reg.read(r:[bv32]bv8, i:bv32) returns (bv8) { r[i] }
procedure {:inline 1} flowdos_reg.write(i:bv32, v:bv8)
  modifies flowdos_reg, flowdos_reg__last_index, flowdos_reg__last_value, flowdos_reg__wrote_any, flowdos_reg__wrote_index0, flowdos_reg__last0_value;
{
  flowdos_reg[i] := v;
  flowdos_reg__last_index := i;
  flowdos_reg__last_value := v;
  flowdos_reg__wrote_any := true;
  if (i == 0bv32) { flowdos_reg__wrote_index0 := true; flowdos_reg__last0_value := v; }
}

procedure {:inline 1} flowdos_ingress()
  modifies flowdos_reg, flowdos_reg__last_index, flowdos_reg__last_value, flowdos_reg__wrote_any, flowdos_reg__wrote_index0, flowdos_reg__last0_value,
           flowdos_counter_pos, flowdos_counter_val, flowdos_src;
{
  call flowdos_compute_hash();
  flowdos_counter_val := flowdos_reg.read(flowdos_reg, flowdos_counter_pos);
  call flowdos_reg.write(flowdos_counter_pos, flowdos_counter_val);
  assert !((flowdos_reg__wrote_any && (flowdos_reg__last_value == 0bv8)));
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertTrue(res.changed)
        self.assertEqual(res.idx_var, "flowdos_counter_pos")
        self.assertEqual(res.zero, "2242bv32")
        self.assertIn("assume flowdos_counter_pos == 2242bv32;", res.text)
        self.assertIn("flowdos_counter_val := flowdos_reg[2242bv32];", res.text)
        self.assertIn("flowdos_reg[2242bv32] := flowdos_counter_val;", res.text)
        self.assertIn("flowdos_reg__last_index := 2242bv32;", res.text)
        ingress_body = res.text.split("procedure {:inline 1} flowdos_ingress()", 1)[1]
        self.assertNotIn("flowdos_reg__wrote_index0 := true;", ingress_body)
        self.assertNotIn("call flowdos_reg.write(flowdos_counter_pos, flowdos_counter_val);", res.text)

    def test_oldnew_fail_fast_uses_focused_slot_and_old_value_mirror(self) -> None:
        bpl = """\
var flowdos_reg:[bv32]bv8;
var flowdos_reg__last_index:bv32;
var flowdos_reg__last_value:bv8;
var flowdos_reg__last_old_value:bv8;
var flowdos_reg__wrote_any:bool;
var flowdos_reg__wrote_index0:bool;
var flowdos_reg__last0_old_value:bv8;
var flowdos_reg__last0_value:bv8;
var flowdos_counter_pos:bv32;
var flowdos_counter_val:bv8;
var flowdos_src:bv32;

procedure {:inline 1} flowdos_compute_hash()
  modifies flowdos_counter_pos, flowdos_src;
{
  flowdos_src := 167772161bv32;
  flowdos_counter_pos := 2242bv32;
}

function {:inline true}flowdos_reg.read(r:[bv32]bv8, i:bv32) returns (bv8) { r[i] }
procedure {:inline 1} flowdos_reg.write(i:bv32, v:bv8)
  modifies flowdos_reg, flowdos_reg__last_index, flowdos_reg__last_value, flowdos_reg__last_old_value,
           flowdos_reg__wrote_any, flowdos_reg__wrote_index0, flowdos_reg__last0_old_value, flowdos_reg__last0_value;
{
  flowdos_reg__last_old_value := flowdos_reg[i];
  flowdos_reg[i] := v;
  flowdos_reg__last_index := i;
  flowdos_reg__last_value := v;
  flowdos_reg__wrote_any := true;
  if (flowdos_reg__wrote_any && flowdos_reg__last_old_value == 255bv8 && flowdos_reg__last_value == 0bv8) {
    assert false;
    assume false;
  }
  if (i == 0bv32) {
    flowdos_reg__wrote_index0 := true;
    flowdos_reg__last0_old_value := flowdos_reg__last_old_value;
    flowdos_reg__last0_value := v;
  }
}

procedure {:inline 1} flowdos_ingress()
  modifies flowdos_reg, flowdos_reg__last_index, flowdos_reg__last_value, flowdos_reg__last_old_value,
           flowdos_reg__wrote_any, flowdos_reg__wrote_index0, flowdos_reg__last0_old_value, flowdos_reg__last0_value,
           flowdos_counter_pos, flowdos_counter_val, flowdos_src;
{
  call flowdos_compute_hash();
  flowdos_counter_val := flowdos_reg.read(flowdos_reg, flowdos_counter_pos);
  call flowdos_reg.write(flowdos_counter_pos, add.bv8(flowdos_counter_val, 1bv8));
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertTrue(res.changed)
        self.assertEqual(res.zero, "2242bv32")
        self.assertEqual(res.target_old_value, "255bv8")
        self.assertEqual(res.target_value, "0bv8")
        self.assertIn("flowdos_reg__last_old_value := flowdos_reg[2242bv32];", res.text)
        self.assertIn("flowdos_reg[2242bv32] := add.bv8(flowdos_counter_val, 1bv8);", res.text)
        self.assertIn(
            "if (flowdos_reg__wrote_any && flowdos_reg__last_index == 2242bv32 && flowdos_reg__last_old_value == 255bv8 && flowdos_reg__last_value == 0bv8)",
            res.text,
        )
        self.assertNotIn("call flowdos_reg.write(flowdos_counter_pos, add.bv8(flowdos_counter_val, 1bv8));", res.text)

    def test_write_with_expression_value_is_scalarized(self) -> None:
        bpl = """\
var s_reg:[bv16]bv32;
var s_reg__last_index:bv16;
var s_reg__last_value:bv32;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv32;
var s_meta.register_index:bv16;
var s_tmp:bv32;

procedure {:inline 1} s_get_register_index()
  modifies s_meta.register_index;
{
  s_meta.register_index := s_idx_calc.get$bv32();
}

function {:inline true}s_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }
procedure {:inline 1} s_reg.write(i:bv16, v:bv32)
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
  call s_reg.write(s_meta.register_index, add.bv32(s_tmp, 1bv32));
  assert !((s_reg__wrote_any && (s_reg__last_value == 0bv32)));
}
"""

        res = focus_dynamic_index0_register_assert(bpl)

        self.assertTrue(res.changed)
        self.assertIn("s_reg[0bv16] := add.bv32(s_tmp, 1bv32);", res.text)
        self.assertNotIn("call s_reg.write(s_meta.register_index, add.bv32(s_tmp, 1bv32));", res.text)

    def test_target_value_write_keeps_focused_fail_fast(self) -> None:
        bpl = """\
var s_reg:[bv16]bv32;
var s_reg__last_index:bv16;
var s_reg__last_value:bv32;
var s_reg__wrote_any:bool;
var s_reg__wrote_index0:bool;
var s_reg__last0_value:bv32;
var s_meta.register_index:bv16;
var s_tmp:bv32;

procedure {:inline 1} s_get_register_index()
  modifies s_meta.register_index;
{
  s_meta.register_index := s_idx_calc.get$bv32();
}

function {:inline true}s_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }
procedure {:inline 1} s_reg.write(i:bv16, v:bv32)
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value;
{
  s_reg[i] := v;
  s_reg__last_index := i;
  s_reg__last_value := v;
  s_reg__wrote_any := true;
  if (s_reg__wrote_any && s_reg__last_value == 0bv32) {
    assert false;
    assume false;
  }
  if (i == 0bv16) { s_reg__wrote_index0 := true; s_reg__last0_value := v; }
}

procedure {:inline 1} s_Ingress()
  modifies s_reg, s_reg__last_index, s_reg__last_value, s_reg__wrote_any, s_reg__wrote_index0, s_reg__last0_value,
           s_meta.register_index, s_tmp;
{
  call s_get_register_index();
  s_tmp := s_reg.read(s_reg, s_meta.register_index);
  call s_reg.write(s_meta.register_index, add.bv32(s_tmp, 1bv32));
  if (s_tmp == 0bv32) {
    call s_reg.write(s_meta.register_index, 0bv32);
  }
}
"""

        res = focus_dynamic_index0_register_assert(bpl)
        self.assertTrue(res.changed)
        self.assertEqual(
            res.text.count(
                "if (s_reg__wrote_index0 && s_reg__last0_value == 0bv32) {"
            ),
            2,
        )
        self.assertIn("s_reg[0bv16] := 0bv32;", res.text)


if __name__ == "__main__":
    unittest.main()
