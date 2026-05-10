from __future__ import annotations

import unittest

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.analysis.wraparound_projection import extract_dependency_projection

from dslc.tests.wraparound.schedule.fixtures import _candidate


class WraparoundProjectionTests(unittest.TestCase):
    def test_dependency_projection_folds_constant_bool_guard_disjuncts(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var hdr.valid: bool;
var r: [bv32]bv8;
var r__last0_value: bv8;

function unknown_guard(x:bv8, y:bv8) returns (bool);

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, hdr.valid, r, r__last0_value;
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
      if (hdr.valid) {
        if (((100bv16) == 100bv16) || unknown_guard(1bv8, 2bv8)) {
          r[0bv32] := add.bv8(r[0bv32], 1bv8);
          r__last0_value := r[0bv32];
        }
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
  modifies procurator_phase, s1_inbox_count, hdr.valid, r, r__last0_value;
{
  s1_inbox_count := 0;
  hdr.valid := true;
  procurator_phase := 0;
  r__last0_value := 0bv8;
  while (true) {
    call main();
  }
}
"""
        dep = extract_dependency_projection(bpl_text=bpl, candidate=_candidate())
        self.assertFalse(dep.complete)
        self.assertIn("dependency_projection_unstable_cutpoint_guards=1", dep.notes)

    def test_dependency_projection_incomplete_without_global_vars(self) -> None:
        dep = extract_dependency_projection(
            bpl_text="procedure mainProcedure() returns() {}\n",
            candidate=_candidate(),
        )
        self.assertFalse(dep.complete)
        self.assertIn("no_global_vars", dep.notes)

    def test_dependency_projection_incomplete_without_scheduler_period(self) -> None:
        bpl = """\
var procurator_phase: int;
var r: [bv32]bv8;
var r__last0_value: bv8;

procedure mainProcedure() returns()
{
}
"""
        dep = extract_dependency_projection(bpl_text=bpl, candidate=_candidate())
        self.assertFalse(dep.complete)
        self.assertIn("missing_deterministic_scheduler", dep.notes)

    def test_dependency_projection_conflicting_stable_assumes_keep_cutpoint_branch_ambiguity(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var dsl_pump_mode: bool;
var guard_reg: [bv32]bv8;
var guard_reg__last0_value: bv8;
var target_reg: [bv32]bv8;
var target_reg__last0_value: bv8;

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, dsl_pump_mode, guard_reg, guard_reg__last0_value, target_reg, target_reg__last0_value;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    assume(dsl_pump_mode == true);
    assume(dsl_pump_mode == false);
    s1_inbox_count := 1;
  } else if (procurator_phase == 1) {
    if (s1_inbox_count > 0) {
      s1_inbox_count := s1_inbox_count - 1;
      if (dsl_pump_mode == true) {
        target_reg[0bv32] := add.bv8(target_reg[0bv32], 1bv8);
        target_reg__last0_value := target_reg[0bv32];
      } else {
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
  modifies procurator_phase, s1_inbox_count, dsl_pump_mode, guard_reg, guard_reg__last0_value, target_reg, target_reg__last0_value;
{
  s1_inbox_count := 0;
  guard_reg__last0_value := 1bv8;
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
                stable_substitutions=(("dsl_pump_mode", "dsl_pump_mode"),),
            ),
        )
        self.assertFalse(dep.complete)
        pred_text = ",".join(dep.cutpoint_predicates)
        self.assertIn("dsl_pump_mode", pred_text)
        self.assertIn("== true", pred_text)
        self.assertIn("!(", pred_text)
        alts_text = "\n".join(",".join(alt) for alt in dep.cutpoint_guard_alternatives)
        self.assertIn("dsl_pump_mode", alts_text)
        self.assertIn("== true", alts_text)

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
        self.assertFalse(dep.complete)
        self.assertIn("flow_id_reg", dep.live_deps)
        self.assertIn("flow_id_reg__last0_value", dep.proj_vars)
        self.assertIn("meta.flow_id", dep.live_deps)
        self.assertIn("dependency_projection_unstable_cutpoint_guards=1", dep.notes)
        self.assertIn("dependency_projection_incomplete", dep.notes)

    def test_dependency_projection_snapshots_dynamic_index_deps_as_exprs(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var idx: bv32;
var flow_id_reg: [bv32]bv32;
var flow_id_reg__last0_value: bv32;
var target_reg: [bv32]bv8;
var target_reg__last_index: bv32;
var target_reg__last_value: bv8;
var meta.flow_id: bv32;
var tmp_flow_id: bv32;

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, flow_id_reg, flow_id_reg__last0_value,
           target_reg, target_reg__last_index, target_reg__last_value, meta.flow_id, tmp_flow_id;
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
      tmp_flow_id := flow_id_reg[idx];
      if (meta.flow_id != tmp_flow_id) {
        s1_inbox_count := s1_inbox_count;
      }
      else{
        target_reg[idx] := add.bv8(target_reg[idx], 1bv8);
        target_reg__last_index := idx;
        target_reg__last_value := target_reg[idx];
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
  modifies procurator_phase, s1_inbox_count, idx, flow_id_reg, flow_id_reg__last0_value,
           target_reg, target_reg__last_index, target_reg__last_value, meta.flow_id, tmp_flow_id;
{
  s1_inbox_count := 0;
  flow_id_reg__last0_value := 7bv32;
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
                index_value=None,
                index_expr="idx",
                proj_vars=("procurator_phase",),
                cutpoint_cond="(procurator_phase == 0)",
                reason="test",
                step_op="add",
                step_delta=1,
            ),
        )
        self.assertFalse(dep.complete)
        self.assertIn("flow_id_reg", dep.live_deps)
        self.assertNotIn("flow_id_reg__last0_value", dep.proj_vars)
        self.assertEqual(dep.proj_exprs, ("flow_id_reg[idx]",))
        self.assertTrue(any(n == "dependency_projection_dynamic_slot_exprs=flow_id_reg[idx]" for n in dep.notes))
        self.assertTrue(any(n == "dependency_projection_unstable_cutpoint_guards=1" for n in dep.notes))
        self.assertTrue(any(n == "dependency_projection_incomplete" for n in dep.notes))

    def test_dependency_projection_promotes_dynamic_slot_guards_to_predicates(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var idx: bv16;
var time_reg: [bv16]bv32;
var time_reg__last_index: bv16;
var time_reg__last_value: bv32;
var flow_id_reg: [bv16]bv32;
var flow_id_reg__last_index: bv16;
var flow_id_reg__last_value: bv32;
var target_reg: [bv16]bv8;
var target_reg__last_index: bv16;
var target_reg__last_value: bv8;
var meta.flow_id: bv32;
var tmp_time: bv32;
var tmp_flow: bv32;

function {:inline true} time_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }
function {:inline true} flow_id_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, time_reg, time_reg__last_index, time_reg__last_value, flow_id_reg,
           flow_id_reg__last_index, flow_id_reg__last_value,
           target_reg, target_reg__last_index, target_reg__last_value,
           meta.flow_id, tmp_time, tmp_flow;
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
      tmp_time := time_reg.read(time_reg, idx);
      time_reg[idx] := 9bv32;
      if (tmp_time == 0bv32) {
        s1_inbox_count := s1_inbox_count;
      }
      else {
        tmp_flow := flow_id_reg.read(flow_id_reg, idx);
        if (meta.flow_id != tmp_flow) {
          s1_inbox_count := s1_inbox_count;
        }
        else {
          target_reg[idx] := add.bv8(target_reg[idx], 1bv8);
          target_reg__last_index := idx;
          target_reg__last_value := target_reg[idx];
        }
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
  modifies procurator_phase, s1_inbox_count, idx, time_reg, time_reg__last_index, time_reg__last_value, flow_id_reg,
           flow_id_reg__last_index, flow_id_reg__last_value,
           target_reg, target_reg__last_index, target_reg__last_value,
           meta.flow_id, tmp_time, tmp_flow;
{
  s1_inbox_count := 0;
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
                index_value=None,
                index_expr="5bv16",
                proj_vars=("procurator_phase",),
                cutpoint_cond="(procurator_phase == 0)",
                reason="test",
                step_op="add",
                step_delta=1,
            ),
        )
        self.assertFalse(dep.complete)
        self.assertIn("!(time_reg[5bv16] == 0bv32)", dep.proj_predicates)
        self.assertNotIn("time_reg[5bv16]", dep.proj_exprs)
        self.assertNotIn("flow_id_reg[5bv16]", dep.proj_exprs)
        self.assertTrue(any(n == "dependency_projection_dynamic_slot_index_mismatch=flow_id_reg" for n in dep.notes))
        self.assertTrue(any(n == "dependency_projection_unstable_cutpoint_guards=1" for n in dep.notes))
        self.assertTrue(any(n == "dependency_projection_incomplete" for n in dep.notes))

    def test_dependency_projection_rewrites_deterministic_flow_id_readback_guard(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var idx: bv16;
var flow_id_reg: [bv16]bv32;
var flow_id_reg__last_index: bv16;
var flow_id_reg__last_value: bv32;
var target_reg: [bv16]bv8;
var target_reg__last_index: bv16;
var target_reg__last_value: bv8;
var meta.flow_ID: bv32;
var tmp_flow_ID: bv32;

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, flow_id_reg, flow_id_reg__last_index, flow_id_reg__last_value,
           target_reg, target_reg__last_index, target_reg__last_value, meta.flow_ID, tmp_flow_ID;
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
      tmp_flow_ID := flow_id_reg.read(flow_id_reg, idx);
      if (meta.flow_ID != tmp_flow_ID) {
        s1_inbox_count := s1_inbox_count;
      }
      else {
        target_reg[idx] := add.bv8(target_reg[idx], 1bv8);
        target_reg__last_index := idx;
        target_reg__last_value := target_reg[idx];
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
  modifies procurator_phase, s1_inbox_count, idx, flow_id_reg, flow_id_reg__last_index, flow_id_reg__last_value,
           target_reg, target_reg__last_index, target_reg__last_value, meta.flow_ID, tmp_flow_ID;
{
  s1_inbox_count := 0;
  procurator_phase := 0;
  while (true) {
    call main();
  }
}
"""
        flow_id = "flow_id_calc(1bv32, 2bv32, 1234bv16, 443bv16, 6bv8)"
        dep = extract_dependency_projection(
            bpl_text=bpl,
            candidate=WraparoundCandidate(
                pump_reg="target_reg",
                accel_regs=("target_reg",),
                index_value=None,
                index_expr="idx",
                proj_vars=("procurator_phase",),
                cutpoint_cond="(procurator_phase == 0)",
                reason="test",
                step_op="add",
                step_delta=1,
                stable_substitutions=(("meta.flow_ID", flow_id),),
            ),
        )
        self.assertTrue(dep.complete, dep.notes)
        pred_text = ",".join(dep.proj_predicates)
        self.assertIn(f"{flow_id}) != flow_id_reg[idx]", pred_text)
        self.assertNotIn("flow_id_reg[idx]", dep.proj_exprs)
        self.assertNotIn("meta.flow_ID", ",".join(dep.proj_predicates))

    def test_dependency_projection_accepts_target_guard_function_predicate(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var idx: bv16;
var counter_filter: [bv16]bv8;
var counter_filter__last_index: bv16;
var counter_filter__last_value: bv8;

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, counter_filter, counter_filter__last_index, counter_filter__last_value;
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
      counter_filter[idx] := add.bv8(counter_filter[idx], 1bv8);
      counter_filter__last_index := idx;
      counter_filter__last_value := counter_filter[idx];
      if (buge.bv8(counter_filter[idx], 128bv8)) {
        counter_filter[idx] := 0bv8;
        counter_filter__last_index := idx;
        counter_filter__last_value := 0bv8;
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
  modifies procurator_phase, s1_inbox_count, idx, counter_filter, counter_filter__last_index, counter_filter__last_value;
{
  s1_inbox_count := 0;
  procurator_phase := 0;
  while (true) {
    call main();
  }
}
"""
        dep = extract_dependency_projection(
            bpl_text=bpl,
            candidate=WraparoundCandidate(
                pump_reg="counter_filter",
                accel_regs=("counter_filter",),
                index_value=None,
                index_expr="5bv16",
                proj_vars=("procurator_phase",),
                cutpoint_cond="(procurator_phase == 0)",
                reason="test",
                step_op="add",
                step_delta=1,
            ),
        )
        pred_text = ",".join(dep.cutpoint_predicates)
        self.assertIn("counter_filter[5bv16]", pred_text)
        self.assertIn("128bv8", pred_text)
        self.assertIn("buge.bv8", pred_text)
        self.assertTrue(all("dependency_projection_unstable_cutpoint_guards=" not in n for n in dep.notes), dep.notes)
        # Target-slot guard predicates are cutpoint branch metadata, not closure
        # equality projection invariants.  They must stay in cutpoint predicates
        # but not be copied into proj_predicates.
        self.assertEqual(dep.proj_predicates, ())

    def test_dependency_projection_marks_ambiguous_dynamic_slot_shape_incomplete(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var idx: bv16;
var time_reg: [bv16]bv32;
var time_reg__last_index: bv16;
var time_reg__last_value: bv32;
var target_reg: [bv16]bv8;
var target_reg__last_index: bv16;
var target_reg__last_value: bv8;
var tmp_time: bv32;

function {:inline true} time_reg.read(r:[bv16]bv32, i:bv16) returns (bv32) { r[i] }

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, time_reg, time_reg__last_index, time_reg__last_value, target_reg,
           target_reg__last_index, target_reg__last_value, tmp_time;
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
      tmp_time := time_reg.read(time_reg, idx);
      if (tmp_time == 0bv32) {
        target_reg[idx] := add.bv8(target_reg[idx], 1bv8);
        target_reg__last_index := idx;
        target_reg__last_value := target_reg[idx];
      }
      else {
        target_reg[idx] := add.bv8(target_reg[idx], 1bv8);
        target_reg__last_index := idx;
        target_reg__last_value := target_reg[idx];
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
  modifies procurator_phase, s1_inbox_count, idx, time_reg, time_reg__last_index, time_reg__last_value, target_reg,
           target_reg__last_index, target_reg__last_value, tmp_time;
{
  s1_inbox_count := 0;
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
                index_value=None,
                index_expr="5bv16",
                proj_vars=("procurator_phase",),
                cutpoint_cond="(procurator_phase == 0)",
                reason="test",
                step_op="add",
                step_delta=1,
            ),
        )
        self.assertFalse(dep.complete)
        self.assertIn("time_reg[5bv16] == 0bv32", dep.proj_predicates)
        self.assertIn("!(time_reg[5bv16] == 0bv32)", dep.proj_predicates)
        self.assertIn(("time_reg[5bv16] == 0bv32",), dep.cutpoint_guard_alternatives)
        self.assertIn(("!(time_reg[5bv16] == 0bv32)",), dep.cutpoint_guard_alternatives)
        self.assertTrue(any(n.startswith("dependency_projection_ambiguous_cutpoint_predicates=") for n in dep.notes))
        self.assertTrue(any(n == "dependency_projection_cutpoint_guard_alternatives=2" for n in dep.notes))

    def test_dependency_projection_incomplete_for_dynamic_index_width_mismatch(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var idx: bv32;
var flow_id_reg: [bv16]bv32;
var flow_id_reg__last0_value: bv32;
var target_reg: [bv32]bv8;
var target_reg__last_index: bv32;
var target_reg__last_value: bv8;
var meta.flow_id: bv32;
var tmp_flow_id: bv32;

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, flow_id_reg, flow_id_reg__last0_value,
           target_reg, target_reg__last_index, target_reg__last_value, meta.flow_id, tmp_flow_id;
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
      tmp_flow_id := flow_id_reg[0bv16];
      if (meta.flow_id != tmp_flow_id) {
        s1_inbox_count := s1_inbox_count;
      }
      else{
        target_reg[idx] := add.bv8(target_reg[idx], 1bv8);
        target_reg__last_index := idx;
        target_reg__last_value := target_reg[idx];
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
  modifies procurator_phase, s1_inbox_count, idx, flow_id_reg, flow_id_reg__last0_value,
           target_reg, target_reg__last_index, target_reg__last_value, meta.flow_id, tmp_flow_id;
{
  s1_inbox_count := 0;
  flow_id_reg__last0_value := 7bv32;
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
                index_value=None,
                index_expr="idx",
                proj_vars=("procurator_phase",),
                cutpoint_cond="(procurator_phase == 0)",
                reason="test",
                step_op="add",
                step_delta=1,
            ),
        )
        self.assertFalse(dep.complete)
        self.assertEqual(dep.proj_exprs, ())
        self.assertTrue(
            any(
                n in {
                    "dependency_projection_dynamic_slot_deps=flow_id_reg",
                    "dependency_projection_dynamic_slot_index_mismatch=flow_id_reg",
                }
                for n in dep.notes
            ),
            dep.notes,
        )

    def test_dependency_projection_incomplete_for_wrong_dynamic_slot_index(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var idx: bv16;
var other_idx: bv16;
var flow_id_reg: [bv16]bv32;
var flow_id_reg__last0_value: bv32;
var target_reg: [bv16]bv8;
var target_reg__last_index: bv16;
var target_reg__last_value: bv8;
var meta.flow_id: bv32;
var tmp_flow_id: bv32;

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, flow_id_reg, flow_id_reg__last0_value, target_reg,
           target_reg__last_index, target_reg__last_value, meta.flow_id, tmp_flow_id;
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
      tmp_flow_id := flow_id_reg[other_idx];
      if (meta.flow_id == tmp_flow_id) {
        target_reg[idx] := add.bv8(target_reg[idx], 1bv8);
        target_reg__last_index := idx;
        target_reg__last_value := target_reg[idx];
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
  modifies procurator_phase, s1_inbox_count, idx, other_idx, flow_id_reg, flow_id_reg__last0_value,
           target_reg, target_reg__last_index, target_reg__last_value, meta.flow_id, tmp_flow_id;
{
  s1_inbox_count := 0;
  flow_id_reg__last0_value := 0bv32;
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
                index_value=None,
                index_expr="idx",
                proj_vars=("procurator_phase",),
                cutpoint_cond="(procurator_phase == 0)",
                reason="test",
                step_op="add",
                step_delta=1,
            ),
        )
        self.assertFalse(dep.complete)
        self.assertIn("flow_id_reg", dep.live_deps)
        self.assertNotIn("flow_id_reg[idx]", dep.proj_exprs)
        self.assertTrue(
            any(n == "dependency_projection_dynamic_slot_index_mismatch=flow_id_reg" for n in dep.notes),
            dep.notes,
        )

    def test_dependency_projection_ignores_header_valid_map_for_dynamic_slots(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var idx: bv32;
var isValid: [Ref]bool;
var hdr.ipv4: Ref;
var target_reg: [bv32]bv8;
var target_reg__last_index: bv32;
var target_reg__last_value: bv8;
var target_reg__wrote_any: bool;

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, idx, isValid, target_reg,
           target_reg__last_index, target_reg__last_value, target_reg__wrote_any;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    // env inject -> s1
    assume isValid[hdr.ipv4] == true;
    s1_inbox_count := 1;
  } else if (procurator_phase == 1) {
    // node pass -> s1
    if (s1_inbox_count > 0) {
      s1_inbox_count := s1_inbox_count - 1;
      if (isValid[hdr.ipv4]) {
        target_reg[idx] := add.bv8(target_reg[idx], 1bv8);
        target_reg__last_index := idx;
        target_reg__last_value := target_reg[idx];
        target_reg__wrote_any := true;
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
  modifies procurator_phase, s1_inbox_count, idx, isValid, target_reg,
           target_reg__last_index, target_reg__last_value, target_reg__wrote_any;
{
  s1_inbox_count := 0;
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
                index_value=None,
                index_expr="idx",
                proj_vars=("procurator_phase",),
                cutpoint_cond="(procurator_phase == 0)",
                reason="test",
                step_op="add",
                step_delta=1,
            ),
        )
        self.assertTrue(
            all("dynamic_slot_index_mismatch=isValid" not in n for n in dep.notes),
            dep.notes,
        )
        self.assertFalse(dep.complete)
        self.assertIn("dependency_projection_unstable_cutpoint_guards=1", dep.notes)
        self.assertIn("dependency_projection_incomplete", dep.notes)

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

    def test_dependency_projection_substitutes_control_plane_constants_for_constant_slot(self) -> None:
        bpl = """\
var procurator_phase: int;
var s1_inbox_count: int;
var s1_table.param: bv8;
var s1_status: [bv16]bv1;
var s1_r: [bv16]bv8;
var s1_r__last0_value: bv8;

procedure update() returns()
  modifies s1_r, s1_r__last0_value;
{
  if (s1_table.param == 0bv8) {
    if (s1_status[0bv16] == 0bv1) {
      s1_r[0bv16] := 1bv8;
      s1_r__last0_value := 1bv8;
    } else {
      s1_r[0bv16] := 2bv8;
      s1_r__last0_value := 2bv8;
    }
  }
}

procedure s1_mainProcedure() returns()
  modifies s1_table.param, s1_status, s1_r, s1_r__last0_value;
{
  call update();
}

procedure main() returns()
  modifies procurator_phase, s1_inbox_count, s1_table.param, s1_status, s1_r, s1_r__last0_value;
{
  if (procurator_phase == 0) {
    assume (s1_table.param == 0bv8);
    s1_inbox_count := 1;
  } else if (procurator_phase == 1) {
    if (s1_inbox_count > 0) {
      s1_inbox_count := s1_inbox_count - 1;
      call s1_mainProcedure();
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
  modifies procurator_phase, s1_inbox_count, s1_table.param, s1_status, s1_r, s1_r__last0_value;
{
  s1_inbox_count := 0;
  procurator_phase := 0;
  s1_r__last0_value := 0bv8;
  while (true) {
    call main();
  }
}
"""
        dep = extract_dependency_projection(
            bpl_text=bpl,
            candidate=WraparoundCandidate(
                pump_reg="s1_r",
                accel_regs=("s1_r",),
                index_value=0,
                index_expr=None,
                proj_vars=("procurator_phase",),
                cutpoint_cond="(procurator_phase == 0)",
                reason="test",
                step_op="add",
                step_delta=1,
            ),
        )

        self.assertTrue(all("unstable_cutpoint_guards" not in n for n in dep.notes), dep.notes)
        self.assertIn("s1_status[0bv16] == 0bv1", dep.proj_predicates)
        self.assertIn("!(s1_status[0bv16] == 0bv1)", dep.proj_predicates)
        self.assertNotIn("s1_table.param == 0bv8", dep.proj_predicates)


if __name__ == "__main__":
    unittest.main()
