from __future__ import annotations

import unittest

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.analysis.wraparound_projection import extract_dependency_projection
from dslc.analysis.wraparound_projection_bool import constant_bool_expr


class WraparoundProjectionTableApplyTests(unittest.TestCase):
    def test_fixed_noaction_table_preserves_register_readback_guard(self) -> None:
        bpl = """\
var procurator_phase: int;
var s_inbox_count: int;
var idx: bv16;
var s_meta.result: bv8;
var s_tmp_result: bv8;
var s_result_reg: [bv16]bv8;
var s_result_reg__last_index: bv16;
var s_result_reg__last_value: bv8;
var s_target_reg: [bv16]bv8;
var s_target_reg__last_index: bv16;
var s_target_reg__last_value: bv8;
type s_flow_result.action;
const unique s_flow_result.action.set_result : s_flow_result.action;
const unique s_flow_result.action.noaction : s_flow_result.action;
var s_flow_result.action_run: s_flow_result.action;
var s_flow_result.hit: bool;
var s_flow_result.set_result.param: bv8;

function {:inline true} s_result_reg.read(r:[bv16]bv8, i:bv16) returns (bv8) { r[i] }

procedure {:inline 1} s_read_result() returns()
  modifies s_meta.result, s_tmp_result;
{
  s_tmp_result := s_result_reg.read(s_result_reg, idx);
  s_meta.result := s_tmp_result;
}

procedure {:inline 1} s_set_result(p:bv8) returns()
  modifies s_meta.result;
{
  s_meta.result := p;
}

procedure {:inline 1} s_noaction() returns()
{
}

procedure {:inline 1} s_flow_result.apply() returns()
  modifies s_flow_result.hit, s_meta.result;
{
  s_flow_result.hit := false;
  goto s_action_set, s_action_noaction;

  s_action_set:
  assume s_flow_result.action_run == s_flow_result.action.set_result;
  call s_set_result(s_flow_result.set_result.param);
  goto s_Exit;

  s_action_noaction:
  assume s_flow_result.action_run == s_flow_result.action.noaction;
  call s_noaction();
  goto s_Exit;

  s_Exit:
}

procedure {:inline 1} s_update() returns()
  modifies s_meta.result, s_tmp_result, s_flow_result.hit, s_target_reg,
           s_target_reg__last_index, s_target_reg__last_value;
{
  call s_read_result();
  call s_flow_result.apply();
  if (bult.bv8(s_meta.result, 50bv8)) {
    s_target_reg[idx] := add.bv8(s_target_reg[idx], 1bv8);
    s_target_reg__last_index := idx;
    s_target_reg__last_value := s_target_reg[idx];
  }
}

procedure {:inline 1} s_main() returns()
  modifies s_meta.result, s_tmp_result, s_flow_result.hit, s_target_reg,
           s_target_reg__last_index, s_target_reg__last_value;
{
  call s_update();
}

procedure main() returns()
  modifies procurator_phase, s_inbox_count, s_flow_result.action_run,
           s_meta.result, s_tmp_result, s_flow_result.hit, s_target_reg,
           s_target_reg__last_index, s_target_reg__last_value;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    assume (s_flow_result.action_run == s_flow_result.action.noaction);
    s_inbox_count := 1;
  } else if (procurator_phase == 1) {
    if (s_inbox_count > 0) {
      s_inbox_count := s_inbox_count - 1;
      call s_main();
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
  modifies procurator_phase, s_inbox_count, s_flow_result.action_run,
           s_meta.result, s_tmp_result, s_flow_result.hit, s_target_reg,
           s_target_reg__last_index, s_target_reg__last_value;
{
  s_inbox_count := 0;
  procurator_phase := 0;
  while (true) {
    call main();
  }
}
"""
        dep = extract_dependency_projection(
            bpl_text=bpl,
            candidate=WraparoundCandidate(
                pump_reg="s_target_reg",
                accel_regs=("s_target_reg",),
                index_value=None,
                index_expr="idx",
                proj_vars=("procurator_phase",),
                cutpoint_cond="(procurator_phase == 0)",
                reason="test",
                step_op="add",
                step_delta=1,
            ),
        )

        self.assertTrue(dep.complete, dep.notes)
        pred_text = ",".join(dep.cutpoint_predicates)
        self.assertIn("bult.bv8(s_result_reg[idx], 50bv8)", pred_text)
        self.assertNotIn("s_flow_result.set_result.param", pred_text)
        self.assertNotIn("s_meta.result", pred_text)

    def test_constant_bool_expr_folds_literal_bv_comparators(self) -> None:
        self.assertFalse(constant_bool_expr("bugt.bv8((0bv8), 50bv8)"))
        self.assertTrue(constant_bool_expr("bult.bv8((1bv8), 50bv8)"))


if __name__ == "__main__":
    unittest.main()
