from __future__ import annotations

import unittest

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.analysis.wraparound_projection import extract_dependency_projection

from dslc.tests.wraparound.schedule.fixtures import _candidate


class WraparoundProjectionTests(unittest.TestCase):
    def test_dependency_projection_uses_mailbox_counts_not_stale_pkt_tags(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var s1_pkt_external: bool;
var r: [bv32]bv8;
var r__last0_value: bv8;

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, s1_pkt_external, r, r__last0_value;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    // host send -> s1
    if (s1_inbox_count < 1) {
      assume s1_inbox_count < 1;
      s1_pkt_external := true;
      s1_inbox_count := s1_inbox_count + 1;
    }
    procurator_phase := 1;
  } else if (procurator_phase == 1) {
    // node pass -> s1
    if (s1_inbox_count > 0) {
      assume s1_inbox_count > 0;
      s1_inbox_count := s1_inbox_count - 1;
      r[0bv32] := add.bv8(r[0bv32], 1bv8);
      r__last0_value := r[0bv32];
    }
    procurator_phase := 0;
  } else {
    assume false;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, s1_inbox_count, s1_pkt_external, r, r__last0_value;
{
  s1_inbox_count := 0;
  s1_pkt_external := false;
  procurator_phase := 0;
  r__last0_value := 0bv8;
  while (true) {
    call main();
  }
}
"""
        dep = extract_dependency_projection(bpl_text=bpl, candidate=_candidate())
        self.assertTrue(dep.complete)
        self.assertIn("s1_inbox_count", dep.proj_vars)
        self.assertNotIn("s1_pkt_external", dep.proj_vars)

    def test_dependency_projection_incomplete_for_unknown_side_effect_call(self) -> None:
        bpl = """\
var procurator_phase: int;
var r: [bv32]bv8;
var r__last0_value: bv8;

procedure foo() returns (x: bv8)
{
  x := 1bv8;
}

procedure main() returns()
  modifies procurator_phase, r, r__last0_value;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    // env inject -> s1
  } else if (procurator_phase == 1) {
    // node pass -> s1
    call r__last0_value := foo();
    r[0bv32] := add.bv8(r[0bv32], 1bv8);
  } else {
    assume false;
  }
  if (procurator_phase == 1) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, r, r__last0_value;
{
  procurator_phase := 0;
  r__last0_value := 0bv8;
  while (true) {
    call main();
  }
}
"""
        dep = extract_dependency_projection(bpl_text=bpl, candidate=_candidate())
        self.assertFalse(dep.complete)
        self.assertEqual(dep.unresolved_calls, ("foo->assigned_call",))

    def test_dependency_projection_inlines_p4b_assigned_helper_call(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var s1_hdr.nc_hdr.seq: bv8;
var r: [bv32]bv8;
var r__last0_value: bv8;
var ra_val: bv8;

procedure {:inline 1} add_one(v_in: bv8) returns (v_out: bv8)
{
  var tmp: bv8;
  tmp := v_in;
  tmp := add.bv8(tmp, 1bv8);
  v_out := tmp;
}

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, s1_hdr.nc_hdr.seq, r, r__last0_value, ra_val;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    // env inject -> s1
    assume s1_hdr.nc_hdr.seq == 3bv8;
    s1_inbox_count := 1;
  } else if (procurator_phase == 1) {
    // node pass -> s1
    if (s1_inbox_count > 0) {
      s1_inbox_count := s1_inbox_count - 1;
      ra_val := s1_hdr.nc_hdr.seq;
      call ra_val := add_one(ra_val);
      r[0bv32] := ra_val;
      r__last0_value := ra_val;
    }
  } else {
    assume false;
  }
  if (procurator_phase == 1) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, s1_inbox_count, s1_hdr.nc_hdr.seq, r, r__last0_value, ra_val;
{
  s1_inbox_count := 0;
  procurator_phase := 0;
  r__last0_value := 0bv8;
  while (true) {
    call main();
  }
}
"""
        dep = extract_dependency_projection(bpl_text=bpl, candidate=_candidate())
        self.assertTrue(dep.complete)
        self.assertEqual(dep.unresolved_calls, ())
        self.assertIn("s1_hdr.nc_hdr.seq", dep.live_deps)
        self.assertNotIn("v_out", dep.live_deps)
        self.assertNotIn("tmp", dep.live_deps)
        self.assertNotIn("s1_hdr.nc_hdr.seq == 3bv8", dep.proj_predicates)

    def test_dependency_projection_promotes_live_register_slot_mirror(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var guard_reg: [bv32]bv8;
var guard_reg__last0_value: bv8;
var r: [bv32]bv8;
var r__last0_value: bv8;

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, guard_reg, guard_reg__last0_value, r, r__last0_value;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    // env inject -> s1
    s1_inbox_count := 1;
  } else if (procurator_phase == 1) {
    // node pass -> s1
    if (s1_inbox_count > 0) {
      s1_inbox_count := s1_inbox_count - 1;
      if (guard_reg[0bv32] == 1bv8) {
        r[0bv32] := add.bv8(r[0bv32], 1bv8);
        r__last0_value := r[0bv32];
      }
    }
  } else {
    assume false;
  }
  if (procurator_phase == 1) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, s1_inbox_count, guard_reg, guard_reg__last0_value, r, r__last0_value;
{
  s1_inbox_count := 0;
  guard_reg__last0_value := 1bv8;
  r__last0_value := 0bv8;
  while (true) {
    call main();
  }
}
"""
        dep = extract_dependency_projection(bpl_text=bpl, candidate=_candidate())
        self.assertTrue(dep.complete)
        self.assertIn("guard_reg", dep.live_deps)
        self.assertIn("guard_reg__last0_value", dep.proj_vars)
        self.assertNotIn("r__last0_value", dep.proj_vars)

    def test_dependency_projection_tracks_else_guard_to_target_write(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var flow_id_reg: [bv32]bv32;
var flow_id_reg__last0_value: bv32;
var target_reg: [bv32]bv8;
var target_reg__last0_value: bv8;
var meta.flow_id: bv32;
var tmp_flow_id: bv32;

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, flow_id_reg, flow_id_reg__last0_value,
           target_reg, target_reg__last0_value, meta.flow_id, tmp_flow_id;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    // env inject -> s1
    s1_inbox_count := 1;
  } else if (procurator_phase == 1) {
    // node pass -> s1
    if (s1_inbox_count > 0) {
      s1_inbox_count := s1_inbox_count - 1;
      tmp_flow_id := flow_id_reg[0bv32];
      if (meta.flow_id != tmp_flow_id) {
        s1_inbox_count := s1_inbox_count;
      }
      else{
        target_reg[0bv32] := add.bv8(target_reg[0bv32], 1bv8);
        target_reg__last0_value := target_reg[0bv32];
      }
    }
  } else {
    assume false;
  }
  if (procurator_phase == 1) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, s1_inbox_count, flow_id_reg, flow_id_reg__last0_value,
           target_reg, target_reg__last0_value, meta.flow_id, tmp_flow_id;
{
  s1_inbox_count := 0;
  flow_id_reg__last0_value := 7bv32;
  target_reg__last0_value := 0bv8;
  procurator_phase := 0;
  while (true) {
    call main();
  }
}
"""
        dep = extract_dependency_projection(
            bpl_text=bpl,
            candidate=WraparoundCandidate(
                pump_reg="target_reg",
                accel_regs=("target_reg",),
                index_value=0,
                index_expr=None,
                proj_vars=("procurator_phase",),
                cutpoint_cond="(procurator_phase == 0)",
                reason="test",
                step_op="add",
                step_delta=1,
            ),
        )
        self.assertTrue(dep.complete)
        self.assertIn("flow_id_reg", dep.live_deps)
        self.assertIn("flow_id_reg__last0_value", dep.proj_vars)
        self.assertIn("meta.flow_id", dep.live_deps)

    def test_dependency_projection_filters_transient_control_predicates(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var dsl_pump_mode: bool;
var s1_meta.location.index: bv16;
var s1_ig_intr_md.resubmit_flag: bv1;
var s1_find_index.hit: bool;
var s1_table.action_run: bv8;
var r: [bv32]bv8;
var r__last0_value: bv8;

procedure act() returns()
  modifies r, r__last0_value;
{
  assume (s1_meta.location.index == 0bv16);
  assume (s1_ig_intr_md.resubmit_flag == 1bv1);
  assume (s1_find_index.hit == true);
  assume (s1_table.action_run == 2bv8);
  r[0bv32] := add.bv8(r[0bv32], 1bv8);
  r__last0_value := r[0bv32];
}

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, dsl_pump_mode, s1_meta.location.index, s1_ig_intr_md.resubmit_flag, s1_find_index.hit, s1_table.action_run, r, r__last0_value;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    // env inject -> s1
    assume (s1_meta.location.index == 0bv16);
    assume (dsl_pump_mode == true);
    s1_inbox_count := 1;
  } else if (procurator_phase == 1) {
    // node pass -> s1
    if (s1_inbox_count > 0) {
      s1_inbox_count := s1_inbox_count - 1;
      if (dsl_pump_mode) {
        call act();
      }
    }
  } else {
    assume false;
  }
  if (procurator_phase == 1) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, s1_inbox_count, dsl_pump_mode, s1_meta.location.index, s1_ig_intr_md.resubmit_flag, s1_find_index.hit, s1_table.action_run, r, r__last0_value;
{
  s1_inbox_count := 0;
  dsl_pump_mode := true;
  procurator_phase := 0;
  r__last0_value := 0bv8;
  while (true) {
    call main();
  }
}
"""
        dep = extract_dependency_projection(bpl_text=bpl, candidate=_candidate())
        self.assertTrue(dep.complete)
        self.assertIn("dsl_pump_mode == true", dep.proj_predicates)
        self.assertNotIn("s1_meta.location.index == 0bv16", dep.proj_predicates)
        self.assertNotIn("s1_ig_intr_md.resubmit_flag == 1bv1", dep.proj_predicates)
        self.assertNotIn("s1_find_index.hit == true", dep.proj_predicates)
        self.assertNotIn("s1_table.action_run == 2bv8", dep.proj_predicates)


if __name__ == "__main__":
    unittest.main()
