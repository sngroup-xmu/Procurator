from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.workflows.wraparound_cegis import _run_cegis_loop, _run_schedule_replay_cegar_loop


class _NoRun:
    calls: list[str]

    def __init__(self) -> None:
        self.calls = []

    def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
        self.calls.append(stage)
        raise AssertionError("dynamic-index fallback should not run solver stages")


_BASE_BPL = """\
var procurator_phase: int;
var flowrest_meta.register_index: bv16;
var flowrest_Ingress_reg_pkt_count: [bv16]bv8;
function flowrest_Ingress_idx_calc.get$bv16(v:bv16) returns(bv16);
function {:inline true} __p4b_crc16_bmv2_byte(flowrest_crc:bv16, flowrest_byte:bv8) returns(bv16);
function {:builtin "bvadd"} add.bv32(left:bv32, right:bv32) returns(bv32);
function {:builtin "bvurem"} urem.bv32(left:bv32, right:bv32) returns(bv32);

procedure main() returns()
{
  if (procurator_phase == 0) {
    procurator_phase := 0;
  }
  return;
}

procedure mainProcedure() returns()
{
  while (true) {
    call main();
  }
}
"""


def _candidate() -> WraparoundCandidate:
    return WraparoundCandidate(
        pump_reg="flowrest_Ingress_reg_pkt_count",
        accel_regs=("flowrest_Ingress_reg_pkt_count",),
        index_value=None,
        index_expr="flowrest_meta.register_index",
        proj_vars=("procurator_phase",),
        cutpoint_cond=None,
        reason="test_dynamic_index",
        step_op="add",
        step_delta=1,
    )


def _candidate_with_unresolved_local() -> WraparoundCandidate:
    return WraparoundCandidate(
        pump_reg="flowrest_Ingress_reg_pkt_count",
        accel_regs=("flowrest_Ingress_reg_pkt_count",),
        index_value=None,
        index_expr="flowrest_Ingress_idx_calc.get$bv16(runtime_port)",
        proj_vars=("procurator_phase",),
        cutpoint_cond=None,
        reason="test_dynamic_index",
        step_op="add",
        step_delta=1,
    )


def _candidate_with_precise_crc_index() -> WraparoundCandidate:
    return WraparoundCandidate(
        pump_reg="flowrest_Ingress_reg_pkt_count",
        accel_regs=("flowrest_Ingress_reg_pkt_count",),
        index_value=None,
        index_expr=(
            "(if 4096bv32 == 0bv32 then 0bv32 else "
            "add.bv32(0bv32, urem.bv32("
            "0bv16++(__p4b_crc16_bmv2_byte(0bv16, 10bv8)), 4096bv32)))"
        ),
        proj_vars=("procurator_phase",),
        cutpoint_cond=None,
        reason="test_dynamic_index",
        step_op="add",
        step_delta=1,
    )


def _candidate_with_undeclared_callee_index() -> WraparoundCandidate:
    return WraparoundCandidate(
        pump_reg="flowrest_Ingress_reg_pkt_count",
        accel_regs=("flowrest_Ingress_reg_pkt_count",),
        index_value=None,
        index_expr="Ghost_idx_calc.get$bv16(1bv16)",
        proj_vars=("procurator_phase",),
        cutpoint_cond=None,
        reason="test_dynamic_index",
        step_op="add",
        step_delta=1,
    )


class WraparoundDynamicIndexTests(unittest.TestCase):
    def test_legacy_cegis_falls_back_when_index_expr_mentions_global(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_BASE_BPL, encoding="utf-8")
            runner = _NoRun()

            manifest_path = _run_cegis_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_BASE_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stage_order="entry_confirm_closure",
            )

            self.assertEqual(runner.calls, [])
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertFalse(manifest["certified"])
            self.assertEqual(manifest["attempts"], [])
            self.assertIn("dynamic index expression depends on pre-loop globals", manifest["diagnostic"])
            self.assertIn("flowrest_meta.register_index", manifest["diagnostic"])

    def test_legacy_cegis_falls_back_when_index_expr_mentions_unresolved_local(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_BASE_BPL, encoding="utf-8")
            runner = _NoRun()

            manifest_path = _run_cegis_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_BASE_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate_with_unresolved_local(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stage_order="entry_confirm_closure",
            )

            self.assertEqual(runner.calls, [])
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertFalse(manifest["certified"])
            self.assertEqual(manifest["attempts"], [])
            self.assertIn("dynamic index expression contains unresolved pre-loop values", manifest["diagnostic"])
            self.assertIn("runtime_port", manifest["diagnostic"])

    def test_legacy_cegis_accepts_precise_crc_conditional_index_expr(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_BASE_BPL, encoding="utf-8")
            runner = _NoRun()

            with self.assertRaisesRegex(AssertionError, "dynamic-index fallback should not run solver stages"):
                _run_cegis_loop(
                    spec_path=out_dir / "x.prop",
                    spec_text="",
                    base_bpl=base_bpl,
                    base_text=_BASE_BPL,
                    out_dir=out_dir,
                    work_dir=out_dir / "work",
                    candidate=_candidate_with_precise_crc_index(),
                    partition_ports={},
                    timeout_seconds=1,
                    closure_timeout_cap_seconds=1,
                    resource_limits=False,
                    confirm_unroll=1,
                    max_confirm_unroll=1,
                    max_iters=1,
                    enable_env_completion_refinement=False,
                    runner=runner,
                    toolchain_nowitness=Path("tc.xml"),
                    toolchain_witness=Path("tc_w.xml"),
                    witness_settings=Path("s_w.epf"),
                    closure_toolchain=Path("tc_cl.xml"),
                    settings=Path("s.epf"),
                    closure_settings=Path("s_cl.epf"),
                    stage_order="entry_confirm_closure",
                )

            self.assertEqual(runner.calls, ["entry_check"])

    def test_legacy_cegis_falls_back_when_index_expr_mentions_undeclared_callee(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_BASE_BPL, encoding="utf-8")
            runner = _NoRun()

            manifest_path = _run_cegis_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_BASE_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate_with_undeclared_callee_index(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stage_order="entry_confirm_closure",
            )

            self.assertEqual(runner.calls, [])
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertFalse(manifest["certified"])
            self.assertEqual(manifest["attempts"], [])
            self.assertIn("dynamic index expression references undeclared call symbols", manifest["diagnostic"])
            self.assertIn("Ghost_idx_calc.get$bv16", manifest["diagnostic"])

    def test_legacy_cegis_rewrites_callee_alias_to_declared_symbol(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_BASE_BPL, encoding="utf-8")
            runner = _NoRun()

            # Candidate uses an unprefixed hash symbol; base model declares only
            # `flowrest_Ingress_idx_calc.get$...`. We should normalize and proceed.
            aliased = WraparoundCandidate(
                pump_reg="flowrest_Ingress_reg_pkt_count",
                accel_regs=("flowrest_Ingress_reg_pkt_count",),
                index_value=None,
                index_expr="Ingress_idx_calc.get$bv16(1bv16)",
                proj_vars=("procurator_phase",),
                cutpoint_cond=None,
                reason="test_dynamic_index",
                step_op="add",
                step_delta=1,
            )

            with self.assertRaisesRegex(AssertionError, "dynamic-index fallback should not run solver stages"):
                _run_cegis_loop(
                    spec_path=out_dir / "x.prop",
                    spec_text="",
                    base_bpl=base_bpl,
                    base_text=_BASE_BPL,
                    out_dir=out_dir,
                    work_dir=out_dir / "work",
                    candidate=aliased,
                    partition_ports={},
                    timeout_seconds=1,
                    closure_timeout_cap_seconds=1,
                    resource_limits=False,
                    confirm_unroll=1,
                    max_confirm_unroll=1,
                    max_iters=1,
                    enable_env_completion_refinement=False,
                    runner=runner,
                    toolchain_nowitness=Path("tc.xml"),
                    toolchain_witness=Path("tc_w.xml"),
                    witness_settings=Path("s_w.epf"),
                    closure_toolchain=Path("tc_cl.xml"),
                    settings=Path("s.epf"),
                    closure_settings=Path("s_cl.epf"),
                    stage_order="entry_confirm_closure",
                )

            self.assertEqual(runner.calls, ["entry_check"])

    def test_schedule_replay_rewrites_callee_alias_to_declared_symbol(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_BASE_BPL, encoding="utf-8")
            runner = _NoRun()

            aliased = WraparoundCandidate(
                pump_reg="flowrest_Ingress_reg_pkt_count",
                accel_regs=("flowrest_Ingress_reg_pkt_count",),
                index_value=None,
                index_expr="Ingress_idx_calc.get$bv16(1bv16)",
                proj_vars=("procurator_phase",),
                cutpoint_cond=None,
                reason="test_dynamic_index",
                step_op="add",
                step_delta=1,
            )

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_BASE_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=aliased,
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stage_order="entry_confirm_closure",
            )

            # This minimal fixture has no deterministic schedule metadata, so
            # schedule-replay exits before solver stages. Crucially, it must not
            # report undeclared-callee fallback after alias normalization.
            self.assertEqual(runner.calls, [])
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertIn("deterministic schedule metadata", manifest["diagnostic"])
            self.assertNotIn("undeclared call symbols", manifest["diagnostic"])

    def test_schedule_replay_falls_back_when_index_expr_mentions_global(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_BASE_BPL, encoding="utf-8")
            runner = _NoRun()

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_BASE_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stage_order="entry_confirm_closure",
            )

            self.assertEqual(runner.calls, [])
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertFalse(manifest["certified"])
            self.assertEqual(manifest["attempts"], [])
            self.assertIn("dynamic index expression depends on pre-loop globals", manifest["diagnostic"])
            self.assertIn("flowrest_meta.register_index", manifest["diagnostic"])

    def test_schedule_replay_falls_back_when_index_expr_mentions_unresolved_local(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_BASE_BPL, encoding="utf-8")
            runner = _NoRun()

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_BASE_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate_with_unresolved_local(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stage_order="entry_confirm_closure",
            )

            self.assertEqual(runner.calls, [])
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertFalse(manifest["certified"])
            self.assertEqual(manifest["attempts"], [])
            self.assertIn("dynamic index expression contains unresolved pre-loop values", manifest["diagnostic"])
            self.assertIn("runtime_port", manifest["diagnostic"])

    def test_schedule_replay_falls_back_when_index_expr_mentions_undeclared_callee(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_BASE_BPL, encoding="utf-8")
            runner = _NoRun()

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_BASE_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate_with_undeclared_callee_index(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stage_order="entry_confirm_closure",
            )

            self.assertEqual(runner.calls, [])
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertFalse(manifest["certified"])
            self.assertEqual(manifest["attempts"], [])
            self.assertIn("dynamic index expression references undeclared call symbols", manifest["diagnostic"])
            self.assertIn("Ghost_idx_calc.get$bv16", manifest["diagnostic"])


if __name__ == "__main__":
    unittest.main()
