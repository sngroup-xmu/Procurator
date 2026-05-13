import json
import tempfile
import unittest
from pathlib import Path

from dslc.bench.validate_counterexample import validate_wraparound_manifest
from dslc.tests.toolchain.wraparound_manifest_fixtures import _closure_binding_text, _write_stage_artifacts
from dslc.tests.wraparound.schedule.fixtures import _MIN_BPL, _candidate
from dslc.workflows.wraparound_schedule import compute_actor_schedule_id, infer_static_deterministic_schedule, sha256_text


class TestValidateWraparoundManifestArtifacts(unittest.TestCase):
    def _certified_manifest(self, root: Path, *, artifacts: dict, schedule: dict) -> dict:
        base_hash = sha256_text(_MIN_BPL)
        base = root / "base.bpl"
        base.write_text(_MIN_BPL, encoding="utf-8")
        return {
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
                    "artifacts": artifacts,
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
                    },
                    "schedule": schedule,
                }
            ],
        }

    def test_validate_schedule_replay_rejects_scalar_projection_without_closure_equality(self) -> None:
        base_hash = sha256_text(_MIN_BPL)
        sched = infer_static_deterministic_schedule(
            base_bpl_text=_MIN_BPL,
            candidate=_candidate(),
            base_bpl_sha256=base_hash,
        )
        assert sched is not None
        sched_manifest = sched.with_projection_vars(("procurator_phase",), source="dependency_projection").to_manifest()
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            artifacts = _write_stage_artifacts(
                root,
                _MIN_BPL,
                closure_binding_text=(
                    "\nvar wrap_closure_snap_procurator_phase: int;\n"
                    "wrap_closure_snap_procurator_phase := procurator_phase;\n"
                ),
            )
            manifest = self._certified_manifest(root, artifacts=artifacts, schedule=sched_manifest)
            path = root / "wraparound.cegis.manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            ok, msg = validate_wraparound_manifest(path)

        self.assertFalse(ok)
        self.assertIn("not certified", msg)

    def test_validate_schedule_replay_rejects_focused_near_wrap_as_certified_confirm(self) -> None:
        base_hash = sha256_text(_MIN_BPL)
        sched = infer_static_deterministic_schedule(
            base_bpl_text=_MIN_BPL,
            candidate=_candidate(),
            base_bpl_sha256=base_hash,
        )
        assert sched is not None
        sched_manifest = sched.with_projection_vars(("procurator_phase",), source="dependency_projection").to_manifest()
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            artifacts = _write_stage_artifacts(
                root,
                _MIN_BPL,
                extra_bpl_text="\nassert false; // WRAPAROUND_NEAR_FOCUSED_ASSERT\n",
                closure_binding_text=_closure_binding_text(proj_vars=("procurator_phase",)),
            )
            manifest = self._certified_manifest(root, artifacts=artifacts, schedule=sched_manifest)
            path = root / "wraparound.cegis.manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            ok, msg = validate_wraparound_manifest(path)

        self.assertFalse(ok)
        self.assertIn("not certified", msg)

    def test_validate_schedule_replay_rejects_predicates_without_explicit_sources(self) -> None:
        base_hash = sha256_text(_MIN_BPL)
        sched = infer_static_deterministic_schedule(
            base_bpl_text=_MIN_BPL,
            candidate=_candidate(),
            base_bpl_sha256=base_hash,
        )
        assert sched is not None
        predicate = "(procurator_phase == 0)"
        sched_manifest = sched.with_projection_vars(
            ("procurator_phase",),
            proj_predicates=(predicate,),
            proj_predicate_sources=("dependency_projection",),
            source="dependency_projection",
        ).to_manifest()
        sched_manifest["schedule_id"] = compute_actor_schedule_id(
            candidate_id=str(sched_manifest["candidate_id"]),
            target_regs=[str(v) for v in sched_manifest["target_regs"]],
            index_value=int(sched_manifest["index_value"]),
            step_delta=int(sched_manifest["step_delta"]),
            actors=[str(v) for v in sched_manifest["actors"]],
            projection=list(sched_manifest["projection"]),
            base_bpl_sha256=base_hash,
        )
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            base = root / "base.bpl"
            base.write_text(_MIN_BPL, encoding="utf-8")
            artifacts = _write_stage_artifacts(
                root,
                _MIN_BPL,
                extra_bpl_text=f"\nassume {predicate};\n",
                closure_binding_text=_closure_binding_text(
                    proj_vars=("procurator_phase",),
                    proj_predicates=(predicate,),
                ),
            )
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
                        "artifacts": artifacts,
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
                            "proj_predicates": [predicate],
                            "proj_predicate_sources": [],
                            "proj_exprs": [],
                            "env_shape_assumes": [],
                            "projection_complete": True,
                            "closure_assumes": [],
                            "notes": [],
                        },
                        "schedule": sched_manifest,
                    }
                ],
            }
            path = root / "wraparound.cegis.manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            ok, msg = validate_wraparound_manifest(path)

        self.assertFalse(ok)
        self.assertIn("not certified", msg)

    def test_validate_schedule_replay_rejects_unreadable_log_artifact_without_throwing(self) -> None:
        base_hash = sha256_text(_MIN_BPL)
        sched = infer_static_deterministic_schedule(
            base_bpl_text=_MIN_BPL,
            candidate=_candidate(),
            base_bpl_sha256=base_hash,
        )
        assert sched is not None
        sched_manifest = sched.with_projection_vars(("procurator_phase",), source="dependency_projection").to_manifest()
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            base = root / "base.bpl"
            base.write_text(_MIN_BPL, encoding="utf-8")
            artifacts = _write_stage_artifacts(
                root,
                _MIN_BPL,
                closure_binding_text=_closure_binding_text(proj_vars=("procurator_phase",)),
            )
            entry_log_dir = root / "entry.log.dir"
            entry_log_dir.mkdir()
            artifacts["entry_log"] = str(entry_log_dir)
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
                        "artifacts": artifacts,
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
                        },
                        "schedule": sched_manifest,
                    }
                ],
            }
            path = root / "wraparound.cegis.manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            ok, msg = validate_wraparound_manifest(path)

        self.assertFalse(ok)
        self.assertIn("not certified", msg)


if __name__ == "__main__":
    unittest.main()
