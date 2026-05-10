import unittest

from dslc.tests.toolchain.wraparound_manifest_fixtures import _closure_binding_text, _write_stage_artifacts


class TestValidateCounterexample(unittest.TestCase):
    def test_validate_wraparound_manifest_rejects_self_consistent_json_without_artifacts(self) -> None:
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import validate_wraparound_manifest
        from dslc.tests.test_wraparound_schedule import _MIN_BPL, _candidate
        from dslc.workflows.wraparound_schedule import infer_static_deterministic_schedule, sha256_text

        base_hash = sha256_text(_MIN_BPL)
        sched = infer_static_deterministic_schedule(
            base_bpl_text=_MIN_BPL,
            candidate=_candidate(),
            base_bpl_sha256=base_hash,
        )
        assert sched is not None
        sched_manifest = sched.with_projection_vars(("procurator_phase",), source="dependency_projection").to_manifest()
        manifest = {
            "cegar_mode": "schedule_replay",
            "base_bpl": "/does/not/exist.bpl",
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
                    "artifacts": {
                        "entry_log": "/does/not/exist.entry.log",
                        "confirm_log": "/does/not/exist.near.log",
                        "closure_log": "/does/not/exist.closure.log",
                    },
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
                        "env_shape_assumes": [],
                        "projection_complete": True,
                        "closure_assumes": [],
                    },
                    "schedule": sched_manifest,
                }
            ],
        }
        with tempfile.TemporaryDirectory() as td:
            path = Path(td) / "wraparound.cegis.manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            ok, msg = validate_wraparound_manifest(path)

        self.assertFalse(ok)
        self.assertIn("not certified", msg)

    def test_validate_wraparound_manifest_rejects_schedule_conditions(self) -> None:
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import validate_wraparound_manifest

        manifest = {
            "cegar_mode": "schedule_replay",
            "base_bpl_sha256": "base-hash",
            "attempts": [
                {
                    "entry": {"result_line": "RESULT: UNSAFE"},
                    "near_wrap": {"result_line": "RESULT: UNSAFE"},
                    "closure": {"result_line": "RESULT: SAFE"},
                    "certified": True,
                    "cfg": {"proj_vars": ["procurator_phase"]},
                    "schedule": {
                        "schedule_id": "schedule-id",
                        "base_bpl_sha256": "base-hash",
                        "actors": ["h1", "s1", "s2"],
                        "projection": [
                            {
                                "lhs": "procurator_phase",
                                "rhs": "entry_snapshot",
                                "kind": "scheduler",
                                "source": "dependency_projection",
                            }
                        ],
                        "conditions": [
                            {
                                "lhs": "s1_find_index.hit",
                                "rhs": "true",
                                "kind": "control",
                                "source": "near_wrap_witness",
                            }
                        ],
                    },
                }
            ],
        }
        with tempfile.TemporaryDirectory() as td:
            path = Path(td) / "wraparound.cegis.manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            ok, msg = validate_wraparound_manifest(path)

        self.assertFalse(ok)
        self.assertIn("not certified", msg)

    def test_validate_wraparound_manifest_rejects_projection_mismatch(self) -> None:
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import validate_wraparound_manifest

        manifest = {
            "cegar_mode": "schedule_replay",
            "base_bpl_sha256": "base-hash",
            "attempts": [
                {
                    "entry": {"result_line": "RESULT: UNSAFE"},
                    "near_wrap": {"result_line": "RESULT: UNSAFE"},
                    "closure": {"result_line": "RESULT: SAFE"},
                    "certified": True,
                    "cfg": {"proj_vars": ["procurator_phase"]},
                    "schedule": {
                        "schedule_id": "schedule-id",
                        "base_bpl_sha256": "base-hash",
                        "actors": ["h1", "s1", "s2"],
                        "projection": [],
                        "conditions": [],
                    },
                }
            ],
        }
        with tempfile.TemporaryDirectory() as td:
            path = Path(td) / "wraparound.cegis.manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            ok, msg = validate_wraparound_manifest(path)

        self.assertFalse(ok)
        self.assertIn("not certified", msg)

    def test_validate_wraparound_manifest_uses_final_stage_result(self) -> None:
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import validate_wraparound_manifest
        from dslc.tests.test_wraparound_schedule import _MIN_BPL, _candidate
        from dslc.workflows.wraparound_schedule import infer_static_deterministic_schedule, sha256_text

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

        self.assertTrue(ok, msg)
        self.assertIn("certified", msg)

    def test_validate_schedule_replay_accepts_artifact_certified_dependency_predicates(self) -> None:
        import copy
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import validate_wraparound_manifest
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
        projection = sched.with_projection_vars(
            ("procurator_phase",),
            proj_predicates=(nb_slot_predicate,),
            proj_predicate_sources=("dependency_projection",),
            source="dependency_projection",
        ).to_manifest()
        projection["schedule_id"] = compute_actor_schedule_id(
            candidate_id=str(projection["candidate_id"]),
            target_regs=[str(v) for v in projection["target_regs"]],
            index_value=int(projection["index_value"]),
            step_delta=int(projection["step_delta"]),
            actors=[str(v) for v in projection["actors"]],
            projection=list(projection["projection"]),
            base_bpl_sha256=base_hash,
        )

        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            base = root / "base.bpl"
            base.write_text(_MIN_BPL, encoding="utf-8")
            artifacts = _write_stage_artifacts(
                root,
                _MIN_BPL,
                extra_bpl_text=f"\nassume {nb_slot_predicate};\n",
                closure_binding_text=_closure_binding_text(
                    proj_vars=("procurator_phase",),
                    proj_predicates=(nb_slot_predicate,),
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
                            "proj_predicates": [nb_slot_predicate],
                            "proj_predicate_sources": ["dependency_projection"],
                            "proj_exprs": [],
                            "env_shape_assumes": [],
                            "projection_complete": True,
                            "closure_assumes": [],
                            "notes": ["dependency_projection_incomplete"],
                        },
                        "schedule": copy.deepcopy(projection),
                    }
                ],
            }
            path = root / "wraparound.cegis.manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")

            self.assertFalse(_manifest_certified_unsafe_data(manifest))
            ok, msg = validate_wraparound_manifest(path)

        self.assertTrue(ok, msg)
        self.assertIn("certified", msg)

    def test_validate_schedule_replay_rejects_malformed_artifact_schedule_without_throwing(self) -> None:
        import copy
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import validate_wraparound_manifest
        from dslc.tests.wraparound.schedule.fixtures import _MIN_BPL, _candidate
        from dslc.workflows.wraparound_schedule import infer_static_deterministic_schedule, sha256_text

        base_hash = sha256_text(_MIN_BPL)
        sched = infer_static_deterministic_schedule(
            base_bpl_text=_MIN_BPL,
            candidate=_candidate(),
            base_bpl_sha256=base_hash,
        )
        assert sched is not None
        schedule = sched.with_projection_vars(("procurator_phase",), source="dependency_projection").to_manifest()
        schedule["index_value"] = "not-an-int"

        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            base = root / "base.bpl"
            base.write_text(_MIN_BPL, encoding="utf-8")
            artifacts = _write_stage_artifacts(root, _MIN_BPL)

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
                            "notes": [],
                        },
                        "schedule": copy.deepcopy(schedule),
                    }
                ],
            }
            path = root / "wraparound.cegis.manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")

            ok, msg = validate_wraparound_manifest(path)

        self.assertFalse(ok)
        self.assertIn("not certified", msg)

    def test_validate_schedule_replay_rejects_raw_stage_bpl_artifacts(self) -> None:
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import validate_wraparound_manifest
        from dslc.tests.wraparound.schedule.fixtures import _MIN_BPL, _candidate
        from dslc.workflows.wraparound_schedule import infer_static_deterministic_schedule, sha256_text

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

    def test_validate_schedule_replay_rejects_closure_safe_registration_followed_by_timeout(self) -> None:
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import validate_wraparound_manifest
        from dslc.tests.wraparound.schedule.fixtures import _MIN_BPL, _candidate
        from dslc.workflows.wraparound_schedule import infer_static_deterministic_schedule, sha256_text

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
                            closure_final="RESULT: Ultimate could not prove your program: Timeout",
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

    def test_validate_schedule_replay_rejects_entry_unsafe_registration_followed_by_timeout(self) -> None:
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import validate_wraparound_manifest
        from dslc.tests.wraparound.schedule.fixtures import _MIN_BPL, _candidate
        from dslc.workflows.wraparound_schedule import infer_static_deterministic_schedule, sha256_text

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
                            entry_final="RESULT: Ultimate could not prove your program: Timeout",
                            closure_binding_text=_closure_binding_text(proj_vars=("procurator_phase",)),
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

    def test_validate_schedule_replay_rejects_log_path_prefix_match(self) -> None:
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import validate_wraparound_manifest
        from dslc.tests.wraparound.schedule.fixtures import _MIN_BPL, _candidate
        from dslc.workflows.wraparound_schedule import infer_static_deterministic_schedule, sha256_text

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
                            log_bpl_suffix=".old",
                            closure_binding_text=_closure_binding_text(proj_vars=("procurator_phase",)),
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

    def test_validate_schedule_replay_rejects_closure_predicate_slot_without_predicate_obligation(self) -> None:
        import copy
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import validate_wraparound_manifest
        from dslc.tests.wraparound.schedule.fixtures import _MIN_BPL, _candidate
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
        predicate = "(procurator_phase == 0)"
        schedule = sched.with_projection_vars(
            ("procurator_phase",),
            proj_predicates=(predicate,),
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
                            extra_bpl_text=f"\nassume {predicate};\n",
                            closure_binding_text=_closure_binding_text(
                                proj_vars=("procurator_phase",),
                                proj_predicate_count=1,
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
                            "proj_predicates": [predicate],
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
            ok, msg = validate_wraparound_manifest(path)

        self.assertFalse(ok)
        self.assertIn("not certified", msg)

    def test_validate_schedule_replay_accepts_projection_expr_artifacts(self) -> None:
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import validate_wraparound_manifest
        from dslc.tests.wraparound.schedule.fixtures import _MIN_BPL, _candidate
        from dslc.workflows.wraparound_schedule import infer_static_deterministic_schedule, sha256_text

        base_text = _MIN_BPL + "\nvar value_reg: [bv32]bv8;\n"
        base_hash = sha256_text(base_text)
        sched = infer_static_deterministic_schedule(
            base_bpl_text=base_text,
            candidate=_candidate(),
            base_bpl_sha256=base_hash,
        )
        assert sched is not None
        expr = "value_reg[0bv32]"
        sched_manifest = sched.with_projection_vars(
            ("procurator_phase",),
            proj_exprs=(expr,),
            source="dependency_projection",
        ).to_manifest()
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            base = root / "base.bpl"
            base.write_text(base_text, encoding="utf-8")
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
                            base_text,
                            extra_bpl_text=f"\nassume {expr} == 0bv8;\n",
                            closure_binding_text=_closure_binding_text(
                                proj_vars=("procurator_phase",),
                                proj_exprs=(expr,),
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
                            "proj_predicates": [],
                            "proj_predicate_sources": [],
                            "proj_exprs": [expr],
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

        self.assertTrue(ok, msg)
        self.assertIn("certified", msg)

    def test_validate_schedule_replay_rejects_projection_expr_missing_from_stage_bpl(self) -> None:
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import validate_wraparound_manifest
        from dslc.tests.wraparound.schedule.fixtures import _MIN_BPL, _candidate
        from dslc.workflows.wraparound_schedule import infer_static_deterministic_schedule, sha256_text

        base_text = _MIN_BPL + "\nvar value_reg: [bv32]bv8;\n"
        base_hash = sha256_text(base_text)
        sched = infer_static_deterministic_schedule(
            base_bpl_text=base_text,
            candidate=_candidate(),
            base_bpl_sha256=base_hash,
        )
        assert sched is not None
        expr = "value_reg[0bv32]"
        sched_manifest = sched.with_projection_vars(
            ("procurator_phase",),
            proj_exprs=(expr,),
            source="dependency_projection",
        ).to_manifest()
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            base = root / "base.bpl"
            base.write_text(base_text, encoding="utf-8")
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
                            base_text.replace("value_reg", "unused_reg"),
                            closure_binding_text=_closure_binding_text(proj_vars=("procurator_phase",)),
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
                            "proj_predicates": [],
                            "proj_predicate_sources": [],
                            "proj_exprs": [expr],
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

    def test_validate_schedule_replay_rejects_stage_bpl_for_different_cfg(self) -> None:
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import validate_wraparound_manifest
        from dslc.tests.wraparound.schedule.fixtures import _MIN_BPL, _candidate
        from dslc.workflows.wraparound_schedule import infer_static_deterministic_schedule, sha256_text

        base_hash = sha256_text(_MIN_BPL)
        sched = infer_static_deterministic_schedule(
            base_bpl_text=_MIN_BPL,
            candidate=_candidate(),
            base_bpl_sha256=base_hash,
        )
        assert sched is not None
        sched_manifest = sched.with_projection_vars(("procurator_phase",), source="dependency_projection").to_manifest()
        wrong_stage_base = """\
var other_phase: int;
var other_reg: [bv32]bv8;

procedure mainProcedure() returns()
{
}
"""
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
                        "artifacts": _write_stage_artifacts(root, wrong_stage_base),
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
                        "schedule": sched_manifest,
                    }
                ],
            }
            path = root / "wraparound.cegis.manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            ok, msg = validate_wraparound_manifest(path)

        self.assertFalse(ok)
        self.assertIn("not certified", msg)

    def test_witness_summary_matches_dsl_guard_line(self) -> None:
        from dslc.bench.validate_counterexample import _extract_dsl_guard_lines

        bpl = """
procedure main()
{
  // Global assertions (accumulated into procurator_bad)
  if (!((x == 0bv8))) { procurator_bad := true; }
  assert !procurator_bad;
}
"""
        guards = _extract_dsl_guard_lines(bpl)
        self.assertEqual(guards, ["if (!((x == 0bv8))) { procurator_bad := true; }"])

    def test_summarize_witness_accepts_normalized_procurator_bad_assignment(self) -> None:
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import summarize_witness

        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            (out_dir / "toy.bpl").write_text(
                "procedure main(){ if (!((x==0bv8))) { procurator_bad := true; } assert !procurator_bad; }",
                encoding="utf-8",
            )
            (out_dir / "toy.bpl-witness.graphml").write_text(
                "<graphml><graph><node>"
                "<data key=\"sourcecode\">[procurator_bad := true;]</data>"
                "</node></graph></graphml>",
                encoding="utf-8",
            )

            s = summarize_witness(out_dir=out_dir)
            self.assertTrue(s.ok)
            self.assertEqual(s.kind, "dsl_assert")

    def test_summarize_witness_accepts_fresh_focused_marker(self) -> None:
        import hashlib
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import summarize_witness

        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            bpl = out_dir / "toy.bpl"
            focused = out_dir / "toy.focused-index0.bpl"
            bpl.write_text("procedure main() {}\n", encoding="utf-8")
            focused.write_text("procedure main() {}\n", encoding="utf-8")
            (out_dir / "toy.focused-index0.unsafe.json").write_text(
                json.dumps(
                    {
                        "kind": "focused_under_approx",
                        "source_bpl": str(bpl),
                        "bpl": str(focused),
                        "source_bpl_sha256": hashlib.sha256(bpl.read_bytes()).hexdigest(),
                        "focused_bpl_sha256": hashlib.sha256(focused.read_bytes()).hexdigest(),
                    }
                )
                + "\n",
                encoding="utf-8",
            )

            s = summarize_witness(out_dir=out_dir)
            self.assertTrue(s.ok)
            self.assertEqual(s.kind, "focused_under_approx")

    def test_summarize_witness_accepts_direct_global_assert(self) -> None:
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import summarize_witness

        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            (out_dir / "toy.bpl").write_text(
                "\n".join(
                    [
                        "procedure main(){",
                        "  // DSL assertions",
                        "  assert ((x == 0bv8));",
                        "}",
                    ]
                ),
                encoding="utf-8",
            )
            (out_dir / "toy.bpl-witness.graphml").write_text(
                "<graphml><graph><node><data key=\"sourcecode\">assert x == 0bv8;</data></node></graph></graphml>",
                encoding="utf-8",
            )

            s = summarize_witness(out_dir=out_dir)
            self.assertTrue(s.ok)
            self.assertEqual(s.kind, "dsl_assert")

    def test_summarize_witness_accepts_wraparound_assert_call(self) -> None:
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import summarize_witness

        # Wraparound stages rewrite assertions as `call __wraparound_assert(<expr>);` and
        # Ultimate's witness printer tends to normalize away redundant parentheses.
        bpl = "\n".join(
            [
                "procedure main(){",
                "  // Global assertions",
                "  call __wraparound_assert((!((x && (y == z))) || (r != 0bv32) || (s == 1bv1)));",
                "}",
            ]
        )
        # Mimic GraphML witness XML escaping of "&&" as "&amp;&amp;" and fewer parentheses.
        witness = (
            "<graphml><graph><node><data key=\"sourcecode\">"
            "call __wraparound_assert(!(x &amp;&amp; y == z) || r != 0bv32 || s == 1bv1);"
            "</data></node></graph></graphml>"
        )

        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            (out_dir / "toy.bpl").write_text(bpl, encoding="utf-8")
            (out_dir / "toy.bpl-witness.graphml").write_text(witness, encoding="utf-8")

            s = summarize_witness(out_dir=out_dir)
            self.assertTrue(s.ok, msg=s.details)
            self.assertEqual(s.kind, "dsl_assert")

    def test_summarize_witness_uses_programfile_when_multiple_bpl(self) -> None:
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import summarize_witness

        # Simulate a wraparound run directory with multiple stage BPLs where the
        # newest `.bpl` is not the one that produced the newest witness.
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            confirm_bpl = out_dir / "toy.confirm.bpl"
            closure_bpl = out_dir / "toy.closure.bpl"

            confirm_bpl.write_text(
                "\n".join(
                    [
                        "procedure main(){",
                        "  // Global assertions",
                        "  call __wraparound_assert((x == 0bv8));",
                        "}",
                    ]
                ),
                encoding="utf-8",
            )
            # Write a newer BPL with no assertion section; previously this could confuse
            # the witness summary if we picked the newest `.bpl` by mtime.
            closure_bpl.write_text("procedure main() { return; }", encoding="utf-8")

            witness_text = (
                "<graphml><graph>"
                f"<data key=\"programfile\">{confirm_bpl.as_posix()}</data>"
                "<node><data key=\"sourcecode\">call __wraparound_assert(x == 0bv8);</data></node>"
                "</graph></graphml>"
            )
            (out_dir / "toy.bpl-witness.graphml").write_text(witness_text, encoding="utf-8")

            s = summarize_witness(out_dir=out_dir)
            self.assertTrue(s.ok, msg=s.details)
            self.assertEqual(s.kind, "dsl_assert")


if __name__ == "__main__":
    unittest.main()
