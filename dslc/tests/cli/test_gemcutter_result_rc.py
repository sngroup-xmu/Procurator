from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from dslc.cli.gemcutter import (
    _ComposeJob,
    _run_one,
    _wraparound_manifest_certified_unsafe,
)
from dslc.tests.toolchain.wraparound_manifest_fixtures import _closure_binding_text, _write_stage_artifacts


class _FakeRes:
    def __init__(self, result_line: str, returncode: int = 0):
        self.result_line = result_line
        self.returncode = returncode


class TestGemcutterResultRc(unittest.TestCase):
    def _mk_job(self, tmp: Path) -> _ComposeJob:
        return _ComposeJob(
            spec_path=tmp / "case.prop",
            out_bpl=tmp / "out" / "case.bpl",
            work_dir=tmp / "work",
            log_path=tmp / "logs" / "case.log",
            ultimate_home=tmp / "ultimate-home",
        )

    def test_timeout_result_maps_to_nonzero_rc(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            job = self._mk_job(tmp)
            job.spec_path.parent.mkdir(parents=True, exist_ok=True)
            job.spec_path.write_text("dummy", encoding="utf-8")

            import dslc.cli.gemcutter as gemcutter

            orig_compile = gemcutter.compile_spec_file
            orig_run = gemcutter.run_ultimate
            try:
                def fake_compile_spec_file(**kwargs):
                    out = Path(kwargs["out"])
                    out.parent.mkdir(parents=True, exist_ok=True)
                    out.write_text("procedure main() {}\n", encoding="utf-8")

                def fake_run_ultimate(**_kwargs):
                    return _FakeRes("RESULT: Ultimate could not prove your program: Timeout", returncode=0)

                gemcutter.compile_spec_file = fake_compile_spec_file
                gemcutter.run_ultimate = fake_run_ultimate

                rc = _run_one(
                    job=job,
                    p4b_bin=None,
                    max_env_inputs=False,
                    enable_slicing=True,
                    prune_env_inputs=True,
                    keep_control_seeds=True,
                    por_enabled=False,
                    por_guard_enabled=True,
                    boogie_harness="sequential",
                    pipeline_two_stage=False,
                    max_steps=None,
                    honor_spec_max_steps=False,
                    emit_reg_debug=False,
                    skip_duplicated_fail_fast_global_asserts=False,
                    ultimate=tmp / "Ultimate",
                    toolchain=tmp / "ReachSafety.xml",
                    witness_toolchain=None,
                    settings=tmp / "settings.epf",
                    ultimate_async=False,
                    ultimate_timeout_seconds=5,
                    resource_limits=False,
                    ultimate_xmx_gb=1,
                    witness_rerun=False,
                    focused_direct="off",
                )
            finally:
                gemcutter.compile_spec_file = orig_compile
                gemcutter.run_ultimate = orig_run

            self.assertEqual(rc, 2)

    def test_wraparound_manifest_certified_unsafe_uses_artifact_validator(self) -> None:
        import copy
        import json

        from dslc.tests.wraparound.schedule.fixtures import _MIN_BPL, _candidate
        from dslc.workflows.wraparound_cegis import _manifest_certified_unsafe_data
        from dslc.workflows.wraparound_schedule import (
            compute_actor_schedule_id,
            infer_static_deterministic_schedule,
            sha256_text,
        )

        base_hash = sha256_text(_MIN_BPL)
        sched = infer_static_deterministic_schedule(
            base_bpl_text=_MIN_BPL,
            candidate=_candidate(),
            base_bpl_sha256=base_hash,
        )
        assert sched is not None
        nb_slot_predicate = (
            "!((nb_SwitchIngress_my_symmetric_hash.get$alg_t_CRC32$bv32$bv32$bv16$bv16$bv8"
            "(167772161bv32, 167772162bv32, 1234bv16, 443bv16, 6bv8)) != "
            "(nb_SwitchIngress_Register_full_flow_hash["
            "nb_SwitchIngress_my_symmetric_hash.get$alg_t_CRC32$bv32$bv32$bv16$bv16$bv8"
            "(167772161bv32, 167772162bv32, 1234bv16, 443bv16, 6bv8)[16:0]]))"
        )
        schedule = sched.with_projection_vars(
            ("procurator_phase",),
            proj_predicates=(nb_slot_predicate,),
            proj_predicate_sources=("dependency_projection",),
            source="dependency_projection",
        ).to_manifest()
        schedule["schedule_id"] = compute_actor_schedule_id(
            candidate_id=str(schedule["candidate_id"]),
            target_regs=[str(v) for v in schedule["target_regs"]],
            index_value=int(schedule["index_value"]),
            step_delta=int(schedule["step_delta"]),
            actors=[str(v) for v in schedule["actors"]],
            projection=list(schedule["projection"]),
            base_bpl_sha256=base_hash,
        )

        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            base = root / "base.bpl"
            base.write_text(_MIN_BPL, encoding="utf-8")

            manifest = {
                "cegar_mode": "schedule_replay",
                "base_bpl": str(base),
                "base_bpl_sha256": base_hash,
                "candidate": {
                    "pump_reg": "r",
                    "accel_regs": ["r"],
                    "index_value": 0,
                    "index_expr": None,
                    "proj_vars": ["procurator_phase"],
                    "cutpoint_cond": "(procurator_phase == 0)",
                    "reason": "test",
                    "step_op": "add",
                    "step_delta": 1,
                },
                "attempts": [
                    {
                        "artifacts": _write_stage_artifacts(
                            root,
                            _MIN_BPL,
                            extra_bpl_text=f"\nassume {nb_slot_predicate};\n",
                            closure_binding_text=_closure_binding_text(
                                proj_vars=("procurator_phase",),
                                proj_predicates=(nb_slot_predicate,),
                            ),
                        ),
                        "entry": {"result_line": "RESULT: UNSAFE"},
                        "near_wrap": {"result_line": "RESULT: UNSAFE"},
                        "closure": {"result_line": "RESULT: SAFE"},
                        "certified": True,
                        "cfg": {
                            "pump_reg": "r",
                            "accel_regs": ["r"],
                            "index_value": 0,
                            "index_expr": None,
                            "cutpoint_cond": "(procurator_phase == 0)",
                            "step_op": "add",
                            "step_delta": 1,
                            "proj_vars": ["procurator_phase"],
                            "proj_predicates": [nb_slot_predicate],
                            "proj_predicate_sources": ["dependency_projection"],
                            "proj_exprs": [],
                            "env_shape_assumes": [],
                            "projection_complete": True,
                            "closure_assumes": [],
                            "notes": ["dependency_projection_incomplete"],
                        },
                        "schedule": copy.deepcopy(schedule),
                    }
                ],
            }
            path = root / "wraparound.cegis.manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")

            self.assertFalse(_manifest_certified_unsafe_data(manifest))
            self.assertTrue(_wraparound_manifest_certified_unsafe(path))

    def test_wraparound_manifest_certified_unsafe_rejects_generic_only_schedule_replay(self) -> None:
        import copy
        import json

        from dslc.tests.wraparound.schedule.fixtures import _MIN_BPL, _candidate
        from dslc.workflows.wraparound_cegis import _manifest_certified_unsafe_data
        from dslc.workflows.wraparound_schedule import infer_static_deterministic_schedule, sha256_text

        base_hash = sha256_text(_MIN_BPL)
        sched = infer_static_deterministic_schedule(
            base_bpl_text=_MIN_BPL,
            candidate=_candidate(),
            base_bpl_sha256=base_hash,
        )
        assert sched is not None
        schedule = sched.with_projection_vars(("procurator_phase",), source="dependency_projection").to_manifest()

        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            base = root / "base.bpl"
            base.write_text(_MIN_BPL, encoding="utf-8")
            manifest = {
                "cegar_mode": "schedule_replay",
                "base_bpl": str(base),
                "base_bpl_sha256": base_hash,
                "candidate": {
                    "pump_reg": "r",
                    "accel_regs": ["r"],
                    "index_value": 0,
                    "index_expr": None,
                    "proj_vars": ["procurator_phase"],
                    "cutpoint_cond": "(procurator_phase == 0)",
                    "reason": "test",
                    "step_op": "add",
                    "step_delta": 1,
                },
                "attempts": [
                    {
                        "artifacts": _write_stage_artifacts(root, _MIN_BPL, raw_bpl=True),
                        "entry": {"result_line": "RESULT: UNSAFE"},
                        "near_wrap": {"result_line": "RESULT: UNSAFE"},
                        "closure": {"result_line": "RESULT: SAFE"},
                        "certified": True,
                        "cfg": {
                            "pump_reg": "r",
                            "accel_regs": ["r"],
                            "index_value": 0,
                            "index_expr": None,
                            "cutpoint_cond": "(procurator_phase == 0)",
                            "step_op": "add",
                            "step_delta": 1,
                            "proj_vars": ["procurator_phase"],
                            "proj_predicates": [],
                            "proj_predicate_sources": [],
                            "proj_exprs": [],
                            "env_shape_assumes": [],
                            "projection_complete": True,
                            "closure_assumes": [],
                            "notes": [],
                        },
                        "schedule": copy.deepcopy(schedule),
                    }
                ],
            }
            path = root / "wraparound.cegis.manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")

            self.assertTrue(_manifest_certified_unsafe_data(manifest))
            self.assertFalse(_wraparound_manifest_certified_unsafe(path))


if __name__ == "__main__":
    unittest.main()
