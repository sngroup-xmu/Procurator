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


if __name__ == "__main__":
    unittest.main()
