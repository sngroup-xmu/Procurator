from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

from dslc.bench.validate_counterexample import validate_wraparound_manifest
from dslc.workflows.wraparound_cegis import StageRunResult, _run_schedule_replay_cegar_loop
from dslc.workflows.wraparound_support.schedule.certification import (
    projection_complete_for_certification as _projection_complete_for_certification,
)
from dslc.workflows.wraparound_support.schedule.prefix_cutpoint import (
    branch_projection_resolves_only_ambiguity as _branch_projection_resolves_only_ambiguity,
)

from dslc.tests.wraparound.schedule.fixtures import (
    _BRANCH_GUARD_BPL,
    _SequenceRunner,
    _branch_guard_candidate,
)


class WraparoundSchedulePrefixCutpointTests(unittest.TestCase):
    def test_branch_projection_allows_soft_cutpoint_guard_noise(self) -> None:
        dep = SimpleNamespace(
            notes=(
                "dependency_projection_period=2",
                "dependency_projection_live_deps=3",
                "dependency_projection_cutpoint_predicates=2",
                "dependency_projection_cutpoint_guard_alternatives=2",
                "dependency_projection_ambiguous_cutpoint_predicates=flow_reg[0bv32] == 7bv32",
                "dependency_projection_incomplete",
                "dependency_projection_unstable_cutpoint_guards=2",
                "dependency_projection_incomplete",
                "dependency_projection_dynamic_slot_exprs=time_reg[0bv32]",
            )
        )

        self.assertTrue(
            _branch_projection_resolves_only_ambiguity(
                dep,
                ("!(flow_reg[0bv32] == 7bv32)",),
            )
        )
        self.assertFalse(
            _branch_projection_resolves_only_ambiguity(
                dep,
                ("flow_reg[0bv32] == 7bv32", "!(flow_reg[0bv32] == 7bv32)"),
            )
        )
        self.assertFalse(_branch_projection_resolves_only_ambiguity(dep, ()))

    def test_projection_certification_rejects_hard_notes_even_if_extractor_says_complete(self) -> None:
        soft = SimpleNamespace(
            complete=True,
            notes=("dependency_projection_unstable_cutpoint_guards=1", "dependency_projection_incomplete"),
            unresolved_calls=(),
        )
        self.assertTrue(
            _projection_complete_for_certification(
                soft,
                selected_branch=(),
                branch_projection_complete=False,
                index_projection_complete=True,
            )
        )

        hard = SimpleNamespace(
            complete=True,
            notes=("dependency_projection_dynamic_slot_index_mismatch=flow_id_reg",),
            unresolved_calls=(),
        )
        self.assertFalse(
            _projection_complete_for_certification(
                hard,
                selected_branch=(),
                branch_projection_complete=False,
                index_projection_complete=True,
            )
        )

        hard_index = SimpleNamespace(complete=True, notes=(), unresolved_calls=())
        self.assertFalse(
            _projection_complete_for_certification(
                hard_index,
                selected_branch=(),
                branch_projection_complete=False,
                index_projection_complete=False,
            )
        )

    def _branch_guard_bpl_with_write_mirror(self) -> str:
        return (
            _BRANCH_GUARD_BPL.replace(
                "var r__last_value: bv8;\n",
                "var r__last_value: bv8;\nvar r__wrote_any: bool;\n",
            )
            .replace(
                "modifies procurator_phase, procurator_step, time_reg, flow_reg, r, r__last_index, r__last_value;",
                "modifies procurator_phase, procurator_step, time_reg, flow_reg, r, r__last_index, r__last_value, r__wrote_any;",
            )
            .replace(
                "      r__last_value := r[0bv32];\n",
                "      r__last_value := r[0bv32];\n      r__wrote_any := true;\n",
            )
            .replace(
                "    procurator_step := procurator_step + 1;\n",
                "    procurator_step := procurator_step + 1;\n"
                "    assert (!(r__wrote_any && (r__last_value == 0bv8)));\n",
            )
        )

    def test_schedule_replay_selects_branch_projection_for_ambiguous_cutpoint_guards(self) -> None:
        runner = _SequenceRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_BRANCH_GUARD_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_BRANCH_GUARD_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_branch_guard_candidate(),
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
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertTrue(manifest["certified"])
            attempt = manifest["attempts"][0]
            self.assertTrue(attempt["cfg"]["projection_complete"])
            self.assertIn("!(time_reg[0bv32] == 0bv32)", attempt["cfg"]["proj_predicates"])
            self.assertIn("flow_reg[0bv32] == 7bv32", attempt["cfg"]["proj_predicates"])
            self.assertNotIn("time_reg[0bv32] == 0bv32", attempt["cfg"]["proj_predicates"])
            self.assertIn("dependency_projection_branch_alternative=", ";".join(attempt["cfg"]["notes"]))
            entry_text = next(text for stage, text in runner.snapshots if stage == "entry_check")
            near_text = next(text for stage, text in runner.snapshots if stage == "near_wrap")
            closure_text = next(text for stage, text in runner.snapshots if stage == "closure_check")
            self.assertIn("assume(((procurator_phase == 0)) && (!(time_reg[0bv32] == 0bv32))", entry_text)
            self.assertIn("assume(((procurator_phase == 0)) && (!(time_reg[0bv32] == 0bv32))", near_text)
            self.assertIn("wrap_closure_pred_0 := (!(time_reg[0bv32] == 0bv32));", closure_text)
            self.assertIn("wrap_closure_pred_1 := (flow_reg[0bv32] == 7bv32);", closure_text)
            self.assertIn("assume(((procurator_phase == 0)) && (!(time_reg[0bv32] == 0bv32))", closure_text)
            ok, msg = validate_wraparound_manifest(manifest_path)
            self.assertTrue(ok, msg)

    def test_schedule_replay_uses_prefix_entry_for_reachable_branch_cutpoint(self) -> None:
        class PrefixEntryRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                if stage == "entry_check" or stage.startswith("entry_check.prefix."):
                    self.calls.append(stage)
                    input_bpl = Path(kwargs["input_bpl"])
                    log_path = kwargs.get("log_path")
                    text = input_bpl.read_text(encoding="utf-8")
                    self.snapshots.append((stage, text))
                    result = "UNSAFE" if stage.startswith("entry_check.prefix.") else "SAFE"
                    if log_path is not None:
                        self._write_log(log_path, input_bpl, f"RESULT: {result}")
                    return StageRunResult(
                        stage=stage,
                        returncode=0,
                        wall_time_s=0.0,
                        result_line=f"RESULT: {result}",
                    )
                return super().run(stage=stage, **kwargs)

        runner = PrefixEntryRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_BRANCH_GUARD_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_BRANCH_GUARD_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_branch_guard_candidate(),
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
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(
                runner.calls,
                ["entry_check", "entry_check.prefix.unroll1", "near_wrap", "closure_check"],
            )
            attempt = manifest["attempts"][0]
            self.assertTrue(attempt["certified"])
            self.assertEqual(attempt["entry"]["stage"], "entry_check.prefix.unroll1")
            self.assertIn("entry_prefix_unroll=1", attempt["cfg"]["notes"])
            self.assertTrue(attempt["artifacts"]["entry_bpl"].endswith(".entry_prefix.unroll1.bpl"))

            initial_entry = next(text for stage, text in runner.snapshots if stage == "entry_check")
            prefix_entry = next(text for stage, text in runner.snapshots if stage.startswith("entry_check.prefix."))
            near_text = next(text for stage, text in runner.snapshots if stage == "near_wrap")
            self.assertLess(
                initial_entry.index("call __wraparound_entry_error();"),
                initial_entry.index("return;"),
            )
            self.assertNotIn("while (true)", initial_entry)
            self.assertIn("// UNROLLED 2 steps (wraparound)", prefix_entry)
            self.assertLess(
                prefix_entry.index("// UNROLLED 2 steps (wraparound)"),
                prefix_entry.index("assume(((procurator_phase == 0)) && (!(time_reg[0bv32] == 0bv32))"),
            )
            self.assertLess(
                prefix_entry.index("assume(((procurator_phase == 0)) && (!(time_reg[0bv32] == 0bv32))"),
                prefix_entry.index("call __wraparound_entry_error();"),
            )
            self.assertIn("WRAPAROUND_CONFIRM_PREFIX_CUTPOINT after 2 steps", near_text)
            self.assertLess(
                near_text.index("WRAPAROUND_CONFIRM_PREFIX_CUTPOINT after 2 steps"),
                near_text.index("wraparound confirm fast-forward"),
            )
            self.assertIn("__wraparound_confirm_active := false;", near_text)
            self.assertIn("__wraparound_confirm_active := true;", near_text)
            self.assertIn("if ((__wraparound_confirm_active && (", near_text)
            ok, msg = validate_wraparound_manifest(manifest_path)
            self.assertTrue(ok, msg)

    def test_schedule_replay_uses_focused_near_after_prefix_entry(self) -> None:
        class FocusedPrefixRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                if stage == "entry_check" or stage.startswith("entry_check.prefix."):
                    self.calls.append(stage)
                    input_bpl = Path(kwargs["input_bpl"])
                    log_path = kwargs.get("log_path")
                    text = input_bpl.read_text(encoding="utf-8")
                    self.snapshots.append((stage, text))
                    result = "UNSAFE" if stage.startswith("entry_check.prefix.") else "SAFE"
                    if log_path is not None:
                        self._write_log(log_path, input_bpl, f"RESULT: {result}")
                    return StageRunResult(stage=stage, returncode=0, wall_time_s=0.0, result_line=f"RESULT: {result}")
                if stage == "near_wrap.focused":
                    self.calls.append(stage)
                    input_bpl = Path(kwargs["input_bpl"])
                    log_path = kwargs.get("log_path")
                    text = input_bpl.read_text(encoding="utf-8")
                    self.snapshots.append((stage, text))
                    if log_path is not None:
                        self._write_log(log_path, input_bpl, "RESULT: UNSAFE")
                    return StageRunResult(stage=stage, returncode=0, wall_time_s=0.0, result_line="RESULT: UNSAFE")
                return super().run(stage=stage, **kwargs)

        bpl = self._branch_guard_bpl_with_write_mirror()
        runner = FocusedPrefixRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(bpl, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=bpl,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_branch_guard_candidate(),
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
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(
                runner.calls,
                ["entry_check", "entry_check.prefix.unroll1", "near_wrap.focused", "near_wrap", "closure_check"],
            )
            focused_text = next(text for stage, text in runner.snapshots if stage == "near_wrap.focused")
            self.assertIn("WRAPAROUND_NEAR_FOCUSED_ASSERT", focused_text)
            self.assertIn("__wraparound_confirm_active", focused_text)
            self.assertIn("r__wrote_any", focused_text)
            self.assertIn("r__last_index == 0bv32", focused_text)
            self.assertIn("r__last_value == 0bv8", focused_text)
            attempt = manifest["attempts"][0]
            self.assertTrue(attempt["certified"])
            self.assertEqual(attempt["near_wrap"]["stage"], "near_wrap")
            self.assertFalse(attempt["artifacts"]["confirm_bpl"].endswith(".focused.bpl"))
            self.assertEqual(attempt["artifacts"]["source_confirm_bpl"], "")
            self.assertEqual(attempt["artifacts"]["source_confirm_log"], "")
            ok, msg = validate_wraparound_manifest(manifest_path)
            self.assertTrue(ok, msg)

    def test_schedule_replay_focused_near_safe_falls_back_to_normal_near(self) -> None:
        class FocusedSafeRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                if stage == "entry_check" or stage.startswith("entry_check.prefix."):
                    self.calls.append(stage)
                    input_bpl = Path(kwargs["input_bpl"])
                    log_path = kwargs.get("log_path")
                    text = input_bpl.read_text(encoding="utf-8")
                    self.snapshots.append((stage, text))
                    result = "UNSAFE" if stage.startswith("entry_check.prefix.") else "SAFE"
                    if log_path is not None:
                        self._write_log(log_path, input_bpl, f"RESULT: {result}")
                    return StageRunResult(stage=stage, returncode=0, wall_time_s=0.0, result_line=f"RESULT: {result}")
                if stage == "near_wrap.focused":
                    self.calls.append(stage)
                    input_bpl = Path(kwargs["input_bpl"])
                    log_path = kwargs.get("log_path")
                    text = input_bpl.read_text(encoding="utf-8")
                    self.snapshots.append((stage, text))
                    if log_path is not None:
                        self._write_log(log_path, input_bpl, "RESULT: SAFE")
                    return StageRunResult(stage=stage, returncode=0, wall_time_s=0.0, result_line="RESULT: SAFE")
                return super().run(stage=stage, **kwargs)

        bpl = self._branch_guard_bpl_with_write_mirror()
        runner = FocusedSafeRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(bpl, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=bpl,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_branch_guard_candidate(),
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
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(
                runner.calls,
                ["entry_check", "entry_check.prefix.unroll1", "near_wrap.focused", "near_wrap", "closure_check"],
            )
            attempt = manifest["attempts"][0]
            self.assertTrue(attempt["certified"])
            self.assertEqual(attempt["near_wrap"]["stage"], "near_wrap")
            self.assertFalse(attempt["artifacts"]["confirm_bpl"].endswith(".focused.bpl"))
            self.assertEqual(attempt["artifacts"]["source_confirm_bpl"], "")
            self.assertEqual(attempt["artifacts"]["source_confirm_log"], "")
            ok, msg = validate_wraparound_manifest(manifest_path)
            self.assertTrue(ok, msg)

    def test_schedule_replay_can_certify_from_prefix_closure_cutpoint(self) -> None:
        class PrefixClosureRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                self.calls.append(stage)
                input_bpl = Path(kwargs["input_bpl"])
                log_path = kwargs.get("log_path")
                text = input_bpl.read_text(encoding="utf-8")
                self.snapshots.append((stage, text))
                if stage in {
                    "entry_check",
                    "entry_check.closure_prefix.unroll1",
                    "near_wrap",
                    "near_wrap.closure_prefix.unroll1",
                }:
                    result = "UNSAFE"
                elif stage == "closure_check":
                    result = "UNSAFE"
                elif stage == "closure_check.prefix.unroll1":
                    result = "SAFE"
                else:
                    raise AssertionError(stage)
                if log_path is not None:
                    self._write_log(log_path, input_bpl, f"RESULT: {result}")
                return StageRunResult(stage=stage, returncode=0, wall_time_s=0.0, result_line=f"RESULT: {result}")

        runner = PrefixClosureRunner([])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            bpl = _BRANCH_GUARD_BPL.replace("var r: [bv32]bv8;\n", "var s1_inbox_count: int;\nvar r: [bv32]bv8;\n")
            base_bpl.write_text(bpl, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=bpl,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_branch_guard_candidate(),
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
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(
                runner.calls,
                [
                    "entry_check",
                    "near_wrap",
                    "closure_check",
                    "near_wrap.closure_prefix.unroll1",
                    "closure_check.prefix.unroll1",
                    "entry_check.closure_prefix.unroll1",
                ],
            )
            self.assertTrue(manifest["certified"])
            attempt = manifest["attempts"][0]
            self.assertTrue(attempt["certified"])
            self.assertEqual(attempt["entry"]["stage"], "entry_check.closure_prefix.unroll1")
            self.assertEqual(attempt["near_wrap"]["stage"], "near_wrap.closure_prefix.unroll1")
            self.assertEqual(attempt["closure"]["stage"], "closure_check.prefix.unroll1")
            self.assertEqual(attempt["diagnostic"], "certified schedule-replay wraparound bug via prefix closure")
            self.assertIn("closure_prefix_unroll=1", attempt["cfg"]["notes"])
            self.assertIn("closure_prefix_entry_unroll1=UNSAFE", attempt["cfg"]["notes"])
            self.assertTrue(attempt["artifacts"]["entry_bpl"].endswith(".entry_prefix.unroll1.bpl"))
            self.assertTrue(attempt["artifacts"]["closure_bpl"].endswith(".closure_prefix.unroll1.bpl"))
            self.assertTrue(attempt["artifacts"]["confirm_bpl"].endswith(".near_wrap.prefix1.unroll1.bpl"))

            prefix_closure = next(text for stage, text in runner.snapshots if stage == "closure_check.prefix.unroll1")
            self.assertIn("WRAPAROUND_CONFIRM_PREFIX_CUTPOINT after 2 steps", prefix_closure)
            self.assertLess(
                prefix_closure.index("WRAPAROUND_CONFIRM_PREFIX_CUTPOINT after 2 steps"),
                prefix_closure.index("wraparound closure_check setup"),
            )
            self.assertLess(
                prefix_closure.index("wraparound closure_check setup"),
                prefix_closure.index("wraparound closure_check asserts"),
            )
            ok, msg = validate_wraparound_manifest(manifest_path)
            self.assertTrue(ok, msg)

    def test_schedule_replay_can_certify_mailbox_macro_closure_suffix(self) -> None:
        class MacroClosureRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                self.calls.append(stage)
                input_bpl = Path(kwargs["input_bpl"])
                log_path = kwargs.get("log_path")
                text = input_bpl.read_text(encoding="utf-8")
                self.snapshots.append((stage, text))
                if stage in {
                    "entry_check",
                    "entry_check.closure_prefix.unroll1",
                    "near_wrap",
                    "near_wrap.closure_prefix.unroll1",
                }:
                    result = "UNSAFE"
                elif stage == "closure_check":
                    result = "UNSAFE"
                elif stage == "closure_check.prefix.unroll1":
                    result = "UNSAFE"
                elif stage == "closure_check.prefix.unroll1.suffix2":
                    result = "SAFE"
                else:
                    raise AssertionError(stage)
                if log_path is not None:
                    self._write_log(log_path, input_bpl, f"RESULT: {result}")
                return StageRunResult(stage=stage, returncode=0, wall_time_s=0.0, result_line=f"RESULT: {result}")

        runner = MacroClosureRunner([])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            bpl = _BRANCH_GUARD_BPL.replace("var r: [bv32]bv8;\n", "var s1_inbox_count: int;\nvar r: [bv32]bv8;\n")
            base_bpl.write_text(bpl, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=bpl,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_branch_guard_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=3,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(
                runner.calls,
                [
                    "entry_check",
                    "near_wrap",
                    "closure_check",
                    "near_wrap.closure_prefix.unroll1",
                    "closure_check.prefix.unroll1",
                    "closure_check.prefix.unroll1.suffix2",
                    "entry_check.closure_prefix.unroll1",
                ],
            )
            self.assertTrue(manifest["certified"])
            attempt = manifest["attempts"][0]
            self.assertEqual(attempt["closure"]["stage"], "closure_check.prefix.unroll1.suffix2")
            self.assertIn("closure_suffix_unroll=2", attempt["cfg"]["notes"])
            self.assertIn("closure_prefix_entry_unroll1=UNSAFE", attempt["cfg"]["notes"])
            self.assertTrue(attempt["artifacts"]["closure_bpl"].endswith(".closure_prefix.unroll1.suffix2.bpl"))

            one_round = next(text for stage, text in runner.snapshots if stage == "closure_check.prefix.unroll1")
            two_round = next(text for stage, text in runner.snapshots if stage == "closure_check.prefix.unroll1.suffix2")
            self.assertIn("// UNROLLED 4 steps (wraparound)", one_round)
            self.assertIn("// UNROLLED 6 steps (wraparound)", two_round)
            self.assertIn("WRAPAROUND_CONFIRM_PREFIX_CUTPOINT after 2 steps", two_round)
            self.assertIn("(wrap_closure_after_r == add.bv8(wrap_closure_seq0, 1bv8))", two_round)

    def test_schedule_replay_records_failed_mailbox_macro_closure_suffixes(self) -> None:
        class FailedMacroClosureRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                self.calls.append(stage)
                input_bpl = Path(kwargs["input_bpl"])
                log_path = kwargs.get("log_path")
                text = input_bpl.read_text(encoding="utf-8")
                self.snapshots.append((stage, text))
                if stage in {
                    "entry_check",
                    "entry_check.closure_prefix.unroll1",
                    "near_wrap",
                    "near_wrap.closure_prefix.unroll1",
                    "closure_check",
                    "closure_check.prefix.unroll1",
                    "closure_check.prefix.unroll1.suffix2",
                    "closure_check.prefix.unroll1.suffix3",
                }:
                    result = "UNSAFE"
                else:
                    raise AssertionError(stage)
                if log_path is not None:
                    self._write_log(log_path, input_bpl, f"RESULT: {result}")
                return StageRunResult(stage=stage, returncode=0, wall_time_s=0.0, result_line=f"RESULT: {result}")

        runner = FailedMacroClosureRunner([])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            bpl = _BRANCH_GUARD_BPL.replace("var r: [bv32]bv8;\n", "var s1_inbox_count: int;\nvar r: [bv32]bv8;\n")
            base_bpl.write_text(bpl, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=bpl,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_branch_guard_candidate(),
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
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(
                runner.calls,
                [
                    "entry_check",
                    "near_wrap",
                    "closure_check",
                    "near_wrap.closure_prefix.unroll1",
                    "closure_check.prefix.unroll1",
                    "closure_check.prefix.unroll1.suffix2",
                    "closure_check.prefix.unroll1.suffix3",
                ],
            )
            self.assertFalse(manifest["certified"])
            attempt = manifest["attempts"][0]
            self.assertFalse(attempt["certified"])
            self.assertEqual(attempt["closure"]["stage"], "closure_check")
            self.assertEqual(attempt["diagnostic"], "closure counterexample; blocking schedule")
            self.assertFalse(any(n.startswith("closure_prefix_entry_unroll1=") for n in attempt["cfg"]["notes"]))
            self.assertIn("closure_prefix_unroll1_suffix1=UNSAFE", attempt["cfg"]["notes"])
            self.assertIn("closure_prefix_unroll1_suffix2=UNSAFE", attempt["cfg"]["notes"])
            self.assertIn("closure_prefix_unroll1_suffix3=UNSAFE", attempt["cfg"]["notes"])
            self.assertFalse(validate_wraparound_manifest(manifest_path)[0])

    def test_schedule_replay_mailbox_closure_prefix_auto_expands_when_confirm_growth_disabled(self) -> None:
        class PrefixSweepRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                self.calls.append(stage)
                input_bpl = Path(kwargs["input_bpl"])
                log_path = kwargs.get("log_path")
                text = input_bpl.read_text(encoding="utf-8")
                self.snapshots.append((stage, text))
                if stage in {
                    "entry_check",
                    "entry_check.closure_prefix.unroll3",
                    "near_wrap",
                    "closure_check",
                    "near_wrap.closure_prefix.unroll1",
                    "closure_check.prefix.unroll1",
                    "closure_check.prefix.unroll1.suffix2",
                    "closure_check.prefix.unroll1.suffix3",
                }:
                    result = "UNSAFE"
                elif stage in {
                    "near_wrap.closure_prefix.unroll2",
                    "closure_check.prefix.unroll2",
                    "closure_check.prefix.unroll2.suffix2",
                    "closure_check.prefix.unroll2.suffix3",
                }:
                    result = "UNSAFE"
                elif stage in {
                    "near_wrap.closure_prefix.unroll3",
                }:
                    result = "UNSAFE"
                elif stage == "closure_check.prefix.unroll3":
                    result = "SAFE"
                else:
                    raise AssertionError(stage)
                if log_path is not None:
                    self._write_log(log_path, input_bpl, f"RESULT: {result}")
                return StageRunResult(stage=stage, returncode=0, wall_time_s=0.0, result_line=f"RESULT: {result}")

        runner = PrefixSweepRunner([])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            bpl = _BRANCH_GUARD_BPL.replace("var r: [bv32]bv8;\n", "var s1_inbox_count: int;\nvar r: [bv32]bv8;\n")
            base_bpl.write_text(bpl, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=bpl,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_branch_guard_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=0,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(
                runner.calls,
                [
                    "entry_check",
                    "near_wrap",
                    "closure_check",
                    "near_wrap.closure_prefix.unroll1",
                    "closure_check.prefix.unroll1",
                    "closure_check.prefix.unroll1.suffix2",
                    "closure_check.prefix.unroll1.suffix3",
                    "near_wrap.closure_prefix.unroll2",
                    "closure_check.prefix.unroll2",
                    "closure_check.prefix.unroll2.suffix2",
                    "closure_check.prefix.unroll2.suffix3",
                    "near_wrap.closure_prefix.unroll3",
                    "closure_check.prefix.unroll3",
                    "entry_check.closure_prefix.unroll3",
                ],
            )
            self.assertTrue(manifest["certified"])
            attempt = manifest["attempts"][0]
            self.assertEqual(attempt["entry"]["stage"], "entry_check.closure_prefix.unroll3")
            self.assertEqual(attempt["closure"]["stage"], "closure_check.prefix.unroll3")
            self.assertIn("closure_prefix_entry_unroll3=UNSAFE", attempt["cfg"]["notes"])
            self.assertIn("closure_prefix_auto_cap=3", attempt["cfg"]["notes"])
            self.assertIn("closure_prefix_unroll=3", attempt["cfg"]["notes"])

    def test_schedule_replay_prefix_closure_requires_prefix_entry_reachability(self) -> None:
        class PrefixEntrySafeRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                self.calls.append(stage)
                input_bpl = Path(kwargs["input_bpl"])
                log_path = kwargs.get("log_path")
                text = input_bpl.read_text(encoding="utf-8")
                self.snapshots.append((stage, text))
                if stage in {
                    "entry_check",
                    "near_wrap",
                    "near_wrap.closure_prefix.unroll1",
                }:
                    result = "UNSAFE"
                elif stage == "closure_check":
                    result = "UNSAFE"
                elif stage == "closure_check.prefix.unroll1":
                    result = "SAFE"
                elif stage == "entry_check.closure_prefix.unroll1":
                    result = "SAFE"
                else:
                    raise AssertionError(stage)
                if log_path is not None:
                    self._write_log(log_path, input_bpl, f"RESULT: {result}")
                return StageRunResult(stage=stage, returncode=0, wall_time_s=0.0, result_line=f"RESULT: {result}")

        runner = PrefixEntrySafeRunner([])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            bpl = _BRANCH_GUARD_BPL.replace("var r: [bv32]bv8;\n", "var s1_inbox_count: int;\nvar r: [bv32]bv8;\n")
            base_bpl.write_text(bpl, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=bpl,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_branch_guard_candidate(),
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
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(
                runner.calls,
                [
                    "entry_check",
                    "near_wrap",
                    "closure_check",
                    "near_wrap.closure_prefix.unroll1",
                    "closure_check.prefix.unroll1",
                    "entry_check.closure_prefix.unroll1",
                ],
            )
            self.assertFalse(manifest["certified"])
            attempt = manifest["attempts"][0]
            self.assertFalse(attempt["certified"])
            self.assertEqual(attempt["entry"]["stage"], "entry_check")
            self.assertEqual(attempt["near_wrap"]["stage"], "near_wrap")
            self.assertEqual(attempt["closure"]["stage"], "closure_check")
            self.assertIn("closure_prefix_entry_unroll1=SAFE", attempt["cfg"]["notes"])

    def test_schedule_replay_non_mailbox_closure_prefix_does_not_auto_expand_when_confirm_growth_disabled(self) -> None:
        class NonMailboxRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                self.calls.append(stage)
                input_bpl = Path(kwargs["input_bpl"])
                log_path = kwargs.get("log_path")
                text = input_bpl.read_text(encoding="utf-8")
                self.snapshots.append((stage, text))
                if stage in {"entry_check", "near_wrap"}:
                    result = "UNSAFE"
                elif stage == "closure_check":
                    result = "UNKNOWN"
                else:
                    raise AssertionError(stage)
                if log_path is not None:
                    self._write_log(log_path, input_bpl, f"RESULT: {result}")
                return StageRunResult(stage=stage, returncode=0, wall_time_s=0.0, result_line=f"RESULT: {result}")

        runner = NonMailboxRunner([])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_BRANCH_GUARD_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_BRANCH_GUARD_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_branch_guard_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=0,
                max_iters=1,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(
                runner.calls,
                [
                    "entry_check",
                    "near_wrap",
                    "closure_check",
                ],
            )
            attempt = manifest["attempts"][0]
            self.assertFalse(manifest["certified"])
            self.assertNotIn("closure_prefix_auto_cap=3", attempt["cfg"]["notes"])
