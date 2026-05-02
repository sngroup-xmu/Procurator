from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import dslc.workflows.wraparound_cegis as wraparound_cegis
from dslc.bench.validate_counterexample import validate_wraparound_manifest
from dslc.workflows.wraparound_cegis import (
    WraparoundCegarMode,
    _manifest_certified_unsafe_data,
    _run_schedule_replay_cegar_loop,
)
from dslc.workflows.wraparound_schedule import (
    infer_static_deterministic_schedule,
    projection_predicates_from_assumes,
    sha256_text,
)

from dslc.tests.wraparound.schedule.fixtures import (
    _MIN_BPL,
    _SequenceRunner,
    _TimeoutRecordingRunner,
    _candidate,
    _candidate_with_mailbox_projection,
    _candidate_with_unavailable_projection,
)


class WraparoundScheduleTests(unittest.TestCase):
    def test_static_schedule_extracts_phase_actor_array(self) -> None:
        sched = infer_static_deterministic_schedule(
            base_bpl_text=_MIN_BPL,
            candidate=_candidate(),
            base_bpl_sha256=sha256_text(_MIN_BPL),
        )
        self.assertIsNotNone(sched)
        assert sched is not None
        self.assertEqual(sched.actors, ("env", "s1"))
        self.assertEqual(sched.phases, (0, 1))
        self.assertEqual(sched.reactions, ("env_inject:s1", "node_pass:s1"))
        self.assertNotIn("reactions", sched.to_manifest())
        self.assertNotIn("phases", sched.to_manifest())
        self.assertEqual(sched.step_delta, 1)
        self.assertEqual(sched.bitwidth, 8)
        self.assertTrue(sched.schedule_id)

    def test_schedule_identity_ignores_phase_metadata(self) -> None:
        sched = infer_static_deterministic_schedule(
            base_bpl_text=_MIN_BPL,
            candidate=_candidate(),
            base_bpl_sha256=sha256_text(_MIN_BPL),
        )
        self.assertIsNotNone(sched)
        assert sched is not None
        mutated = sched.__class__(
            schedule_id=sched.schedule_id,
            candidate_id=sched.candidate_id,
            actors=sched.actors,
            phases=(10, 20),
            reactions=sched.reactions,
            target_regs=sched.target_regs,
            index_value=sched.index_value,
            step_delta=sched.step_delta,
            bitwidth=sched.bitwidth,
            projection=sched.projection,
            entry_witness=sched.entry_witness,
            base_bpl_sha256=sched.base_bpl_sha256,
            conditions=sched.conditions,
            encoding=sched.encoding,
            coverage=sched.coverage,
        )
        self.assertEqual(mutated.with_projection_vars(("procurator_phase",)).schedule_id, sched.schedule_id)

    def test_schedule_replay_certifies_when_closure_is_safe(self) -> None:
        runner = _SequenceRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=2,
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
            self.assertEqual(manifest["cegar_mode"], "schedule_replay")
            self.assertTrue(manifest["certified"])
            self.assertEqual(runner.calls, ["entry_check", "near_wrap", "closure_check"])
            entry_text = next(text for stage, text in runner.snapshots if stage == "entry_check")
            self.assertIn("call __wraparound_entry_error();", entry_text)
            self.assertIn("assume((procurator_phase == 0));", entry_text)
            self.assertIn("WRAPAROUND_ENTRY_ASSERT", entry_text)
            self.assertNotIn("__wraparound_pump_error", entry_text)
            self.assertNotIn("var wrap_target_old", entry_text)
            near_text = next(text for stage, text in runner.snapshots if stage == "near_wrap")
            self.assertIn("assume((procurator_phase == 0));", near_text)
            self.assertEqual(manifest["blockers"], [])
            self.assertEqual(len(manifest["attempts"]), 1)
            self.assertTrue(_manifest_certified_unsafe_data(manifest))
            ok, msg = validate_wraparound_manifest(manifest_path)
            self.assertTrue(ok, msg)

    def test_schedule_replay_blocks_failed_schedule_and_reruns_entry(self) -> None:
        runner = _SequenceRunner(["UNSAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=2,
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
            self.assertEqual(manifest["cegar_mode"], "schedule_replay")
            self.assertFalse(manifest["certified"])
            # The first closure counterexample creates a blocker. Since this MVP
            # has only one static deterministic schedule, blocking it makes the
            # next ENTRY query unreachable and triggers ordinary fallback.
            self.assertEqual(runner.calls, ["entry_check", "near_wrap", "closure_check", "entry_check"])
            self.assertEqual(len(manifest["blockers"]), 1)
            self.assertEqual(len(manifest["attempts"]), 2)
            second_entry_text = runner.snapshots[-1][1]
            self.assertIn("assume(false);", second_entry_text)
            self.assertIn("entry unreachable or blocked", manifest["diagnostic"])
            self.assertFalse(_manifest_certified_unsafe_data(manifest))

    def test_schedule_replay_writes_manifest_after_entry(self) -> None:
        class StopAfterEntryRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                res = super().run(stage=stage, **kwargs)
                if stage == "near_wrap":
                    raise RuntimeError("stop after entry manifest")
                return res

        runner = StopAfterEntryRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            with self.assertRaisesRegex(RuntimeError, "stop after entry"):
                _run_schedule_replay_cegar_loop(
                    spec_path=out_dir / "x.prop",
                    spec_text="",
                    base_bpl=base_bpl,
                    base_text=_MIN_BPL,
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
                )

            manifest_path = out_dir / "wraparound.cegis.manifest.json"
            self.assertTrue(manifest_path.exists())
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(manifest["diagnostic"], "entry reached; running near-wrap check")
            self.assertEqual(len(manifest["attempts"]), 1)
            self.assertEqual(manifest["attempts"][0]["entry"]["result_line"], "RESULT: UNSAFE")
            self.assertIsNone(manifest["attempts"][0]["near_wrap"])

    def test_schedule_replay_stop_after_entry(self) -> None:
        runner = _SequenceRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=2,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stop_after="entry",
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(runner.calls, ["entry_check"])
            self.assertEqual(manifest["diagnostic"], "stopped after entry by request")
            self.assertEqual(manifest["attempts"][0]["diagnostic"], "stopped after entry by request")
            self.assertIsNone(manifest["attempts"][0]["near_wrap"])
            self.assertIsNone(manifest["attempts"][0]["closure"])

    def test_schedule_replay_stop_after_near_wrap(self) -> None:
        runner = _SequenceRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=2,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=Path("tc_w.xml"),
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stop_after="near_wrap",
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(runner.calls, ["entry_check", "near_wrap"])
            self.assertEqual(manifest["diagnostic"], "stopped after near_wrap by request")
            self.assertEqual(manifest["attempts"][0]["near_wrap"]["result_line"], "RESULT: UNSAFE")
            self.assertIsNone(manifest["attempts"][0]["closure"])

    def test_multi_schedule_replay_uses_nowitness_fast_path(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            spec = root / "x.prop"
            out_dir = root / "out"
            spec.write_text("global { assert { true; }; }\n", encoding="utf-8")

            tc_nowit = root / "ReachSafety.xml"
            tc_wit = root / "ReachSafety-Witness.xml"
            tc_closure = root / "ClosureCheck.xml"
            st_nowit = root / "nowitness.epf"
            st_wit = root / "witness.epf"
            st_closure = root / "closure.epf"

            captured: dict[str, object] = {}
            old_compile = wraparound_cegis.compile_spec_file
            old_infer = wraparound_cegis.infer_wraparound_candidates
            old_defaults = wraparound_cegis._default_toolchain_paths
            old_schedule_loop = wraparound_cegis._run_schedule_replay_cegar_loop
            try:
                def fake_compile_spec_file(**kwargs):  # type: ignore[no-untyped-def]
                    Path(kwargs["out"]).write_text(_MIN_BPL, encoding="utf-8")
                    Path(kwargs["work_dir"]).mkdir(parents=True, exist_ok=True)

                def fake_loop(**kwargs):  # type: ignore[no-untyped-def]
                    captured.update(kwargs)
                    mpath = Path(kwargs["out_dir"]) / "wraparound.cegis.manifest.json"
                    mpath.write_text('{"attempts": []}', encoding="utf-8")
                    return mpath

                wraparound_cegis.compile_spec_file = fake_compile_spec_file  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = lambda **_kwargs: [_candidate()]  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = lambda **_kwargs: (  # type: ignore[assignment]
                    tc_nowit,
                    tc_wit,
                    tc_closure,
                    st_nowit,
                    st_wit,
                    st_closure,
                )
                wraparound_cegis._run_schedule_replay_cegar_loop = fake_loop  # type: ignore[assignment]

                manifests = wraparound_cegis.run_wraparound_cegis_multi(
                    spec_path=spec,
                    out_dir=out_dir,
                    p4b_bin=None,
                    ultimate=root / "Ultimate.py",
                    cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
                    max_targets=1,
                    max_iters=1,
                )
            finally:
                wraparound_cegis.compile_spec_file = old_compile  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = old_infer  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = old_defaults  # type: ignore[assignment]
                wraparound_cegis._run_schedule_replay_cegar_loop = old_schedule_loop  # type: ignore[assignment]

            self.assertEqual(len(manifests), 1)
            self.assertEqual(captured["toolchain_nowitness"], tc_nowit)
            self.assertEqual(captured["settings"], st_nowit)
            self.assertEqual(captured["toolchain_witness"], tc_wit)
            self.assertEqual(captured["witness_settings"], st_wit)

    def test_multi_schedule_replay_uses_allinline_stage_settings_with_high_memory(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            spec = root / "x.prop"
            out_dir = root / "out"
            toolchain_dir = root / "dslc" / "toolchain" / "ultimate"
            toolchain_dir.mkdir(parents=True)
            spec.write_text("global { assert { true; }; }\n", encoding="utf-8")

            tc_nowit = root / "ReachSafety.xml"
            tc_wit = root / "ReachSafety-Witness.xml"
            tc_closure = root / "ClosureCheck.xml"
            st_nowit = root / "nowitness.epf"
            st_wit = root / "witness.epf"
            st_closure = toolchain_dir / "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf"
            st_closure.write_text("# allinline\n", encoding="utf-8")

            captured: dict[str, object] = {}
            old_repo_root = wraparound_cegis.repo_root
            old_compile = wraparound_cegis.compile_spec_file
            old_infer = wraparound_cegis.infer_wraparound_candidates
            old_defaults = wraparound_cegis._default_toolchain_paths
            old_schedule_loop = wraparound_cegis._run_schedule_replay_cegar_loop
            try:
                def fake_compile_spec_file(**kwargs):  # type: ignore[no-untyped-def]
                    Path(kwargs["out"]).write_text(_MIN_BPL, encoding="utf-8")
                    Path(kwargs["work_dir"]).mkdir(parents=True, exist_ok=True)

                def fake_loop(**kwargs):  # type: ignore[no-untyped-def]
                    captured.update(kwargs)
                    mpath = Path(kwargs["out_dir"]) / "wraparound.cegis.manifest.json"
                    mpath.write_text('{"attempts": []}', encoding="utf-8")
                    return mpath

                wraparound_cegis.repo_root = lambda: root  # type: ignore[assignment]
                wraparound_cegis.compile_spec_file = fake_compile_spec_file  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = lambda **_kwargs: [_candidate()]  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = lambda **_kwargs: (  # type: ignore[assignment]
                    tc_nowit,
                    tc_wit,
                    tc_closure,
                    st_nowit,
                    st_wit,
                    st_closure,
                )
                wraparound_cegis._run_schedule_replay_cegar_loop = fake_loop  # type: ignore[assignment]

                manifests = wraparound_cegis.run_wraparound_cegis_multi(
                    spec_path=spec,
                    out_dir=out_dir,
                    p4b_bin=None,
                    ultimate=root / "Ultimate.py",
                    ultimate_xmx_gb=8,
                    cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
                    max_targets=1,
                    max_iters=1,
                )
            finally:
                wraparound_cegis.repo_root = old_repo_root  # type: ignore[assignment]
                wraparound_cegis.compile_spec_file = old_compile  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = old_infer  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = old_defaults  # type: ignore[assignment]
                wraparound_cegis._run_schedule_replay_cegar_loop = old_schedule_loop  # type: ignore[assignment]

            self.assertEqual(len(manifests), 1)
            self.assertEqual(captured["toolchain_nowitness"], tc_nowit)
            self.assertEqual(captured["settings"], st_closure)
            self.assertEqual(captured["closure_settings"], st_closure)
            self.assertEqual(captured["toolchain_witness"], tc_wit)
            self.assertEqual(captured["witness_settings"], st_wit)

    def test_multi_schedule_replay_high_memory_prefers_allinline_over_closure_specific_epf(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            spec = root / "x.prop"
            out_dir = root / "out"
            toolchain_dir = root / "dslc" / "toolchain" / "ultimate"
            toolchain_dir.mkdir(parents=True)
            spec.write_text("global { assert { true; }; }\n", encoding="utf-8")

            allinline = toolchain_dir / "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf"
            allinline.write_text("# allinline\n", encoding="utf-8")

            tc_nowit = root / "ReachSafety.xml"
            tc_wit = root / "ReachSafety-Witness.xml"
            tc_closure = root / "ClosureCheck.xml"
            st_nowit = root / "nowitness.epf"
            st_wit = root / "witness.epf"
            # Simulates a restored ClosureCheck-32bit-GemCutter-ALL-witness.epf:
            # high-memory schedule replay must still pick the all-inline profile.
            st_closure_specific = root / "ClosureCheck-32bit-GemCutter-ALL-witness.epf"

            captured: dict[str, object] = {}
            old_repo_root = wraparound_cegis.repo_root
            old_compile = wraparound_cegis.compile_spec_file
            old_infer = wraparound_cegis.infer_wraparound_candidates
            old_defaults = wraparound_cegis._default_toolchain_paths
            old_schedule_loop = wraparound_cegis._run_schedule_replay_cegar_loop
            try:
                def fake_compile_spec_file(**kwargs):  # type: ignore[no-untyped-def]
                    Path(kwargs["out"]).write_text(_MIN_BPL, encoding="utf-8")
                    Path(kwargs["work_dir"]).mkdir(parents=True, exist_ok=True)

                def fake_loop(**kwargs):  # type: ignore[no-untyped-def]
                    captured.update(kwargs)
                    mpath = Path(kwargs["out_dir"]) / "wraparound.cegis.manifest.json"
                    mpath.write_text('{"attempts": []}', encoding="utf-8")
                    return mpath

                wraparound_cegis.repo_root = lambda: root  # type: ignore[assignment]
                wraparound_cegis.compile_spec_file = fake_compile_spec_file  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = lambda **_kwargs: [_candidate()]  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = lambda **_kwargs: (  # type: ignore[assignment]
                    tc_nowit,
                    tc_wit,
                    tc_closure,
                    st_nowit,
                    st_wit,
                    st_closure_specific,
                )
                wraparound_cegis._run_schedule_replay_cegar_loop = fake_loop  # type: ignore[assignment]

                manifests = wraparound_cegis.run_wraparound_cegis_multi(
                    spec_path=spec,
                    out_dir=out_dir,
                    p4b_bin=None,
                    ultimate=root / "Ultimate.py",
                    ultimate_xmx_gb=8,
                    cegar_mode=WraparoundCegarMode.SCHEDULE_REPLAY.value,
                    max_targets=1,
                    max_iters=1,
                )
            finally:
                wraparound_cegis.repo_root = old_repo_root  # type: ignore[assignment]
                wraparound_cegis.compile_spec_file = old_compile  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = old_infer  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = old_defaults  # type: ignore[assignment]
                wraparound_cegis._run_schedule_replay_cegar_loop = old_schedule_loop  # type: ignore[assignment]

            self.assertEqual(len(manifests), 1)
            self.assertEqual(captured["settings"], allinline.resolve())
            self.assertEqual(captured["closure_settings"], allinline.resolve())

    def test_multi_legacy_keeps_witness_stage_toolchain(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            spec = root / "x.prop"
            out_dir = root / "out"
            spec.write_text("global { assert { true; }; }\n", encoding="utf-8")

            tc_nowit = root / "ReachSafety.xml"
            tc_wit = root / "ReachSafety-Witness.xml"
            tc_closure = root / "ClosureCheck.xml"
            st_nowit = root / "nowitness.epf"
            st_wit = root / "witness.epf"
            st_closure = root / "closure.epf"

            captured: dict[str, object] = {}
            old_compile = wraparound_cegis.compile_spec_file
            old_infer = wraparound_cegis.infer_wraparound_candidates
            old_defaults = wraparound_cegis._default_toolchain_paths
            old_legacy_loop = wraparound_cegis._run_cegis_loop
            try:
                def fake_compile_spec_file(**kwargs):  # type: ignore[no-untyped-def]
                    Path(kwargs["out"]).write_text(_MIN_BPL, encoding="utf-8")
                    Path(kwargs["work_dir"]).mkdir(parents=True, exist_ok=True)

                def fake_loop(**kwargs):  # type: ignore[no-untyped-def]
                    captured.update(kwargs)
                    mpath = Path(kwargs["out_dir"]) / "wraparound.cegis.manifest.json"
                    mpath.write_text('{"attempts": []}', encoding="utf-8")
                    return mpath

                wraparound_cegis.compile_spec_file = fake_compile_spec_file  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = lambda **_kwargs: [_candidate()]  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = lambda **_kwargs: (  # type: ignore[assignment]
                    tc_nowit,
                    tc_wit,
                    tc_closure,
                    st_nowit,
                    st_wit,
                    st_closure,
                )
                wraparound_cegis._run_cegis_loop = fake_loop  # type: ignore[assignment]

                manifests = wraparound_cegis.run_wraparound_cegis_multi(
                    spec_path=spec,
                    out_dir=out_dir,
                    p4b_bin=None,
                    ultimate=root / "Ultimate.py",
                    cegar_mode=WraparoundCegarMode.LEGACY_CLOSURE_ASSUMES.value,
                    max_targets=1,
                    max_iters=1,
                )
            finally:
                wraparound_cegis.compile_spec_file = old_compile  # type: ignore[assignment]
                wraparound_cegis.infer_wraparound_candidates = old_infer  # type: ignore[assignment]
                wraparound_cegis._default_toolchain_paths = old_defaults  # type: ignore[assignment]
                wraparound_cegis._run_cegis_loop = old_legacy_loop  # type: ignore[assignment]

            self.assertEqual(len(manifests), 1)
            self.assertEqual(captured["toolchain_nowitness"], tc_wit)
            self.assertEqual(captured["settings"], st_wit)
            self.assertEqual(captured["toolchain_witness"], tc_wit)
            self.assertEqual(captured["witness_settings"], st_wit)

    def test_schedule_replay_seeds_closure_assumes_from_near_wrap_witness(self) -> None:
        class WitnessRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                if stage.startswith("confirm.witness."):
                    input_bpl = Path(kwargs["input_bpl"])
                    witness = input_bpl.parent / f"{input_bpl.name}-witness.graphml"
                    witness.write_text(
                        """<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <graph edgedefault="directed">
    <node id="N0">
      <data key="assumption">s1_hdr.nc_hdr.op == 12</data>
    </node>
  </graph>
</graphml>
""",
                        encoding="utf-8",
                    )
                return super().run(stage=stage, **kwargs)

        runner = WitnessRunner(["Timeout", "SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")
            witness_toolchain = out_dir / "tc_w.xml"
            witness_toolchain.write_text("<toolchain>ultimate.witnessprinter</toolchain>", encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=2,
                enable_env_completion_refinement=True,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=witness_toolchain,
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(
                runner.calls,
                ["entry_check", "near_wrap", "closure_check", "confirm.witness.unroll1", "closure_check"],
            )
            first, attempt = manifest["attempts"]
            self.assertEqual(first["diagnostic"], "closure unknown; seeded witness replay conditions for next closure")
            self.assertIn("s1_hdr.nc_hdr.op == 12bv8", attempt["cfg"]["closure_assumes"])
            self.assertTrue(any(n == "closure_seed_assumes=1" for n in attempt["cfg"]["notes"]))
            projection = attempt["schedule"]["projection"]
            self.assertFalse(
                any(
                    p["lhs"] == "s1_hdr.nc_hdr.op"
                    for p in projection
                )
            )
            conditions = attempt["schedule"]["conditions"]
            self.assertTrue(
                any(
                    p["lhs"] == "s1_hdr.nc_hdr.op"
                    and p["rhs"] == "12bv8"
                    and p["source"] == "near_wrap_witness"
                    for p in conditions
                )
            )
            self.assertEqual(attempt["schedule"]["actors"], ["env", "s1"])
            closure_text = [text for stage, text in runner.snapshots if stage == "closure_check"][-1]
            self.assertIn("assume(s1_hdr.nc_hdr.op == 12bv8);", closure_text)
            closure_call = closure_text.split("call __wraparound_closure_assert_all(", 1)[1]
            self.assertNotIn("s1_hdr.nc_hdr.op == 12bv8", closure_call)
            near_text = next(text for stage, text in runner.snapshots if stage == "near_wrap")
            self.assertNotIn("assume(s1_hdr.nc_hdr.op == 12bv8);", near_text)
            self.assertFalse(manifest["certified"])
            self.assertFalse(_manifest_certified_unsafe_data(manifest))
            self.assertEqual(attempt["diagnostic"], "closure safe under witness replay conditions only; falling back")

    def test_schedule_replay_skips_diagnostic_witness_when_refinement_disabled(self) -> None:
        class WitnessRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                if stage.startswith("confirm.witness."):
                    raise AssertionError("diagnostic witness should be skipped")
                return super().run(stage=stage, **kwargs)

        runner = WitnessRunner(["Timeout"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")
            witness_toolchain = out_dir / "tc_w.xml"
            witness_toolchain.write_text("<toolchain>ultimate.witnessprinter</toolchain>", encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=3,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=witness_toolchain,
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(runner.calls, ["entry_check", "near_wrap", "closure_check"])
            self.assertEqual(len(manifest["attempts"]), 1)
            self.assertEqual(manifest["diagnostic"], "closure unknown/timeout; falling back")
            self.assertEqual(manifest["attempts"][0]["schedule"]["conditions"], [])
            self.assertFalse(_manifest_certified_unsafe_data(manifest))

    def test_schedule_replay_does_not_reuse_stale_near_wrap_witness(self) -> None:
        class NoWitnessRunner(_SequenceRunner):
            pass

        runner = NoWitnessRunner(["Timeout"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")
            witness_toolchain = out_dir / "tc_w.xml"
            witness_toolchain.write_text("<toolchain>ultimate.witnessprinter</toolchain>", encoding="utf-8")

            stale = out_dir / "stale.bpl-witness.graphml"
            stale.write_text(
                """<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <graph edgedefault="directed">
    <node id="N0">
      <data key="assumption">s1_hdr.nc_hdr.op == 12</data>
    </node>
  </graph>
</graphml>
""",
                encoding="utf-8",
            )

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=2,
                enable_env_completion_refinement=True,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=witness_toolchain,
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(runner.calls, ["entry_check", "near_wrap", "closure_check", "confirm.witness.unroll1"])
            self.assertEqual(len(manifest["attempts"]), 1)
            self.assertEqual(manifest["diagnostic"], "closure unknown/timeout; falling back")
            self.assertEqual(manifest["attempts"][0]["cfg"]["closure_assumes"], [])
            self.assertEqual(manifest["attempts"][0]["schedule"]["conditions"], [])
            self.assertFalse(_manifest_certified_unsafe_data(manifest))

    def test_schedule_manifest_projection_matches_closure_snapshot_vars(self) -> None:
        runner = _SequenceRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate_with_unavailable_projection(),
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
            projection_lhs = [p["lhs"] for p in manifest["attempts"][0]["schedule"]["projection"]]
            self.assertEqual(projection_lhs, ["procurator_phase"])
            self.assertTrue(
                any(
                    n.startswith("dependency_projection_live_deps=")
                    for n in manifest["attempts"][0]["cfg"]["notes"]
                )
            )
            closure_text = next(text for stage, text in runner.snapshots if stage == "closure_check")
            self.assertIn("var wrap_closure_snap_procurator_phase: int;", closure_text)
            self.assertNotIn("wrap_closure_snap_missing_projection", closure_text)
            self.assertNotIn("wrap_closure_snap_r", closure_text)

    def test_schedule_replay_witness_timeout_not_capped_by_closure(self) -> None:
        class WitnessRunner(_TimeoutRecordingRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                if stage.startswith("confirm.witness."):
                    input_bpl = Path(kwargs["input_bpl"])
                    witness = input_bpl.parent / f"{input_bpl.name}-witness.graphml"
                    witness.write_text(
                        """<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <graph edgedefault="directed">
    <node id="N0">
      <data key="assumption">s1_hdr.nc_hdr.op == 12</data>
    </node>
  </graph>
</graphml>
""",
                        encoding="utf-8",
                    )
                return super().run(stage=stage, **kwargs)

        runner = WitnessRunner(["Timeout", "Timeout"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL, encoding="utf-8")
            witness_toolchain = out_dir / "tc_w.xml"
            witness_toolchain.write_text("<toolchain>ultimate.witnessprinter</toolchain>", encoding="utf-8")

            _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_MIN_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate(),
                partition_ports={},
                timeout_seconds=180,
                closure_timeout_cap_seconds=45,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=2,
                enable_env_completion_refinement=True,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=witness_toolchain,
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
            )

            timeouts = dict(runner.timeouts)
            self.assertEqual(timeouts["entry_check"], 180)
            self.assertEqual(timeouts["near_wrap"], 180)
            self.assertIn("closure_check", timeouts)
            self.assertEqual(timeouts["confirm.witness.unroll1"], 300)

    def test_schedule_replay_weakens_projection_without_rerunning_entry_or_near_wrap(self) -> None:
        class WitnessRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                if stage.startswith("confirm.witness."):
                    input_bpl = Path(kwargs["input_bpl"])
                    witness = input_bpl.parent / f"{input_bpl.name}-witness.graphml"
                    witness.write_text(
                        """<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <graph edgedefault="directed">
    <node id="N0">
      <data key="assumption">s1_hdr.nc_hdr.op == 12</data>
    </node>
  </graph>
</graphml>
""",
                        encoding="utf-8",
                    )
                return super().run(stage=stage, **kwargs)

        runner = WitnessRunner(["Timeout", "Timeout", "SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL + "var s1_inbox_count: int;\n", encoding="utf-8")
            witness_toolchain = out_dir / "tc_w.xml"
            witness_toolchain.write_text("<toolchain>ultimate.witnessprinter</toolchain>", encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=base_bpl.read_text(encoding="utf-8"),
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate_with_mailbox_projection(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=3,
                enable_env_completion_refinement=True,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=witness_toolchain,
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
                    "confirm.witness.unroll1",
                    "closure_check",
                    "closure_check",
                ],
            )
            self.assertFalse(manifest["certified"])
            self.assertEqual(len(manifest["attempts"]), 3)
            first, second, third = manifest["attempts"]
            self.assertEqual(first["diagnostic"], "closure unknown; seeded witness replay conditions for next closure")
            self.assertTrue(any(n == "closure_seed_assumes=1" for n in second["cfg"]["notes"]))
            self.assertEqual(second["diagnostic"], "closure unknown; weakening projection with near-wrap witness predicates")
            self.assertTrue(any(n == "closure_seed_assumes=1" for n in third["cfg"]["notes"]))
            self.assertTrue(any(n == "drop_proj_vars=s1_inbox_count" for n in third["cfg"]["notes"]))
            self.assertEqual(third["artifacts"]["entry_bpl"], first["artifacts"]["entry_bpl"])
            self.assertEqual(third["artifacts"]["entry_log"], first["artifacts"]["entry_log"])
            self.assertEqual(third["schedule"]["actors"], ["env", "s1"])
            projection = third["schedule"]["projection"]
            self.assertTrue(any(p["lhs"] == "procurator_phase" for p in projection))
            self.assertFalse(
                any(
                    p["lhs"] == "s1_inbox_count" and p["source"] == "candidate_projection"
                    for p in projection
                )
            )
            self.assertFalse(any(p["source"] == "near_wrap_witness" for p in projection))
            self.assertTrue(
                any(p["lhs"] == "s1_hdr.nc_hdr.op" and p["source"] == "near_wrap_witness" for p in third["schedule"]["conditions"])
            )
            self.assertEqual(third["diagnostic"], "closure safe under witness replay conditions only; falling back")

    def test_projection_conditions_parse_numeric_dotted_fields(self) -> None:
        preds = projection_predicates_from_assumes(
            ["h1_hdr.overlay.5.valid == false", "assume(s1_find_index.hit == true);"],
            source="near_wrap_witness",
        )
        self.assertEqual([p.lhs for p in preds], ["h1_hdr.overlay.5.valid", "s1_find_index.hit"])

    def test_static_schedule_rejects_unmapped_phase_actor(self) -> None:
        bpl = _MIN_BPL.replace("// env inject -> s1", "// missing actor comment")
        sched = infer_static_deterministic_schedule(
            base_bpl_text=bpl,
            candidate=_candidate(),
            base_bpl_sha256=sha256_text(bpl),
        )
        self.assertIsNone(sched)

    def test_schedule_replay_stop_after_closure_prevents_projection_weakening_retry(self) -> None:
        class WitnessRunner(_SequenceRunner):
            def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
                if stage.startswith("confirm.witness."):
                    input_bpl = Path(kwargs["input_bpl"])
                    witness = input_bpl.parent / f"{input_bpl.name}-witness.graphml"
                    witness.write_text(
                        """<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <graph edgedefault="directed">
    <node id="N0">
      <data key="assumption">s1_hdr.nc_hdr.op == 12</data>
    </node>
  </graph>
</graphml>
""",
                        encoding="utf-8",
                    )
                return super().run(stage=stage, **kwargs)

        runner = WitnessRunner(["Timeout", "SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_MIN_BPL + "var s1_inbox_count: int;\n", encoding="utf-8")
            witness_toolchain = out_dir / "tc_w.xml"
            witness_toolchain.write_text("<toolchain>ultimate.witnessprinter</toolchain>", encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=base_bpl.read_text(encoding="utf-8"),
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_candidate_with_mailbox_projection(),
                partition_ports={},
                timeout_seconds=1,
                closure_timeout_cap_seconds=1,
                resource_limits=False,
                confirm_unroll=1,
                max_confirm_unroll=1,
                max_iters=2,
                enable_env_completion_refinement=False,
                runner=runner,
                toolchain_nowitness=Path("tc.xml"),
                toolchain_witness=witness_toolchain,
                witness_settings=Path("s_w.epf"),
                closure_toolchain=Path("tc_cl.xml"),
                settings=Path("s.epf"),
                closure_settings=Path("s_cl.epf"),
                stop_after="closure",
            )

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(
                runner.calls,
                ["entry_check", "near_wrap", "closure_check"],
            )
            self.assertFalse(manifest["certified"])
            self.assertEqual(manifest["diagnostic"], "stopped after closure by request")
            self.assertEqual(len(manifest["attempts"]), 1)
            self.assertEqual(manifest["attempts"][0]["diagnostic"], "stopped after closure by request")


if __name__ == "__main__":
    unittest.main()
