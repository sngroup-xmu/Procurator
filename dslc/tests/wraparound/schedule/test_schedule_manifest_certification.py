from __future__ import annotations

import copy
import json
import tempfile
import unittest
from pathlib import Path

import dslc.workflows.wraparound_cegis as wraparound_cegis
from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.workflows.wraparound_cegis import _manifest_certified_unsafe_data
from dslc.workflows.wraparound_cegis import _run_schedule_replay_cegar_loop
from dslc.workflows.wraparound_schedule import sha256_text

from dslc.tests.wraparound.schedule.fixtures import (
    _MIN_BPL,
    _SequenceRunner,
    _candidate,
    _dependency_schedule_manifest,
    _dependency_schedule_manifest_with_predicate,
    _schedule_cfg,
)


class WraparoundScheduleManifestTests(unittest.TestCase):
    def test_schedule_manifest_requires_hash_and_certified_flag(self) -> None:
        sched_manifest = _dependency_schedule_manifest()
        manifest = {
            "cegar_mode": "schedule_replay",
            "base_bpl_sha256": sha256_text(_MIN_BPL),
            "attempts": [
                {
                    "cfg": _schedule_cfg(),
                    "entry": {"result_line": "RESULT: UNSAFE"},
                    "near_wrap": {"result_line": "RESULT: UNSAFE"},
                    "confirm": {"result_line": "RESULT: UNSAFE"},
                    "closure": {"result_line": "RESULT: SAFE"},
                    "schedule": copy.deepcopy(sched_manifest),
                    "certified": False,
                }
            ],
        }
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["certified"] = True
        self.assertTrue(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["cfg"]["projection_complete"] = False
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["cfg"]["projection_complete"] = True
        self.assertTrue(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"]["projection"] = []
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"]["projection"] = copy.deepcopy(sched_manifest["projection"])
        self.assertTrue(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"]["projection"] = list(sched_manifest["projection"]) + [
            {"lhs": "s1_hdr.nc_hdr.op", "rhs": "12bv8", "kind": "data_dep", "source": "near_wrap_witness"}
        ]
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"]["projection"] = [
            dict(p, source="candidate_projection") for p in sched_manifest["projection"]
        ]
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"]["projection"] = copy.deepcopy(sched_manifest["projection"])
        manifest["attempts"][0]["schedule"]["projection"][0]["rhs"] = "other_snapshot"
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"]["projection"] = copy.deepcopy(sched_manifest["projection"])
        manifest["attempts"][0]["schedule"]["conditions"] = [
            {"lhs": "s1_find_index.hit", "rhs": "true", "kind": "control", "source": "near_wrap_witness"}
        ]
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"]["conditions"] = []
        self.assertTrue(_manifest_certified_unsafe_data(manifest))
        del manifest["attempts"][0]["schedule"]["conditions"]
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"]["conditions"] = []
        manifest["attempts"][0]["schedule"]["reactions"] = ["env_inject:s1"]
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        del manifest["attempts"][0]["schedule"]["reactions"]
        manifest["attempts"][0]["schedule"]["phases"] = [0, 1]
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        del manifest["attempts"][0]["schedule"]["phases"]
        self.assertTrue(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["cfg"]["closure_assumes"] = ["s1_find_index.hit == true"]
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["cfg"]["closure_assumes"] = []
        self.assertTrue(_manifest_certified_unsafe_data(manifest))
        del manifest["attempts"][0]["cfg"]["closure_assumes"]
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["cfg"]["closure_assumes"] = []
        manifest["attempts"][0]["cfg"]["projection_complete"] = "false"
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["cfg"]["projection_complete"] = True
        manifest["attempts"][0]["certified"] = "false"
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["certified"] = True
        self.assertTrue(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"]["base_bpl_sha256"] = "stale"
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"] = copy.deepcopy(sched_manifest)
        manifest["attempts"][0]["schedule"]["actors"] = []
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"] = copy.deepcopy(sched_manifest)
        manifest["attempts"][0]["schedule"]["actors"] = ["env", "s2"]
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"] = copy.deepcopy(sched_manifest)
        manifest["attempts"][0]["schedule"]["target_regs"] = ["other_reg"]
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"] = copy.deepcopy(sched_manifest)
        manifest["attempts"][0]["schedule"]["step_delta"] = 2
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"] = copy.deepcopy(sched_manifest)
        manifest["attempts"][0]["cfg"]["step_delta"] = 2
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["cfg"]["step_delta"] = 1

    def test_schedule_manifest_requires_dependency_predicates(self) -> None:
        sched_manifest = _dependency_schedule_manifest_with_predicate()
        manifest = {
            "cegar_mode": "schedule_replay",
            "base_bpl_sha256": sha256_text(_MIN_BPL),
            "attempts": [
                {
                    "cfg": _schedule_cfg(proj_predicates=("procurator_phase == 0",)),
                    "entry": {"result_line": "RESULT: UNSAFE"},
                    "near_wrap": {"result_line": "RESULT: UNSAFE"},
                    "closure": {"result_line": "RESULT: SAFE"},
                    "schedule": copy.deepcopy(sched_manifest),
                    "certified": True,
                }
            ],
        }
        self.assertTrue(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"]["projection"] = [
            p for p in sched_manifest["projection"] if p["kind"] != "predicate"
        ]
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"]["projection"] = copy.deepcopy(sched_manifest["projection"])
        manifest["attempts"][0]["schedule"]["projection"][-1]["rhs"] = "procurator_phase == 1"
        self.assertFalse(_manifest_certified_unsafe_data(manifest))

    def test_schedule_manifest_rejects_unstable_dependency_predicates(self) -> None:
        sched_manifest = _dependency_schedule_manifest_with_predicate()
        unstable = "s1_meta.location.index == 0bv16"
        sched_manifest["projection"][-1]["rhs"] = unstable
        sched_manifest["schedule_id"] = wraparound_cegis.compute_actor_schedule_id(
            candidate_id=str(sched_manifest["candidate_id"]),
            target_regs=[str(v) for v in sched_manifest["target_regs"]],
            index_value=int(sched_manifest["index_value"]),
            step_delta=int(sched_manifest["step_delta"]),
            actors=[str(v) for v in sched_manifest["actors"]],
            projection=list(sched_manifest["projection"]),
            base_bpl_sha256=sha256_text(_MIN_BPL),
        )
        manifest = {
            "cegar_mode": "schedule_replay",
            "base_bpl_sha256": sha256_text(_MIN_BPL),
            "attempts": [
                {
                    "cfg": _schedule_cfg(proj_predicates=(unstable,)),
                    "entry": {"result_line": "RESULT: UNSAFE"},
                    "near_wrap": {"result_line": "RESULT: UNSAFE"},
                    "closure": {"result_line": "RESULT: SAFE"},
                    "schedule": sched_manifest,
                    "certified": True,
                }
            ],
        }
        self.assertFalse(_manifest_certified_unsafe_data(manifest))

    def test_schedule_manifest_rejects_unstable_array_index_predicate(self) -> None:
        sched_manifest = _dependency_schedule_manifest_with_predicate()
        unstable = "flow_id_reg[s1_hdr.foo] == 7bv32"
        sched_manifest["projection"][-1]["rhs"] = unstable
        sched_manifest["schedule_id"] = wraparound_cegis.compute_actor_schedule_id(
            candidate_id=str(sched_manifest["candidate_id"]),
            target_regs=[str(v) for v in sched_manifest["target_regs"]],
            index_value=int(sched_manifest["index_value"]),
            step_delta=int(sched_manifest["step_delta"]),
            actors=[str(v) for v in sched_manifest["actors"]],
            projection=list(sched_manifest["projection"]),
            base_bpl_sha256=sha256_text(_MIN_BPL),
        )
        manifest = {
            "cegar_mode": "schedule_replay",
            "base_bpl_sha256": sha256_text(_MIN_BPL),
            "attempts": [
                {
                    "cfg": _schedule_cfg(proj_predicates=(unstable,)),
                    "entry": {"result_line": "RESULT: UNSAFE"},
                    "near_wrap": {"result_line": "RESULT: UNSAFE"},
                    "closure": {"result_line": "RESULT: SAFE"},
                    "schedule": sched_manifest,
                    "certified": True,
                }
            ],
        }
        self.assertFalse(_manifest_certified_unsafe_data(manifest))

    def test_schedule_manifest_accepts_literal_array_index_predicate(self) -> None:
        sched_manifest = _dependency_schedule_manifest_with_predicate()
        stable = "flow_id_reg[0bv32] == 7bv32"
        sched_manifest["projection"][-1]["rhs"] = stable
        sched_manifest["schedule_id"] = wraparound_cegis.compute_actor_schedule_id(
            candidate_id=str(sched_manifest["candidate_id"]),
            target_regs=[str(v) for v in sched_manifest["target_regs"]],
            index_value=int(sched_manifest["index_value"]),
            step_delta=int(sched_manifest["step_delta"]),
            actors=[str(v) for v in sched_manifest["actors"]],
            projection=list(sched_manifest["projection"]),
            base_bpl_sha256=sha256_text(_MIN_BPL),
        )
        manifest = {
            "cegar_mode": "schedule_replay",
            "base_bpl_sha256": sha256_text(_MIN_BPL),
            "attempts": [
                {
                    "cfg": _schedule_cfg(proj_predicates=(stable,)),
                    "entry": {"result_line": "RESULT: UNSAFE"},
                    "near_wrap": {"result_line": "RESULT: UNSAFE"},
                    "closure": {"result_line": "RESULT: SAFE"},
                    "schedule": sched_manifest,
                    "certified": True,
                }
            ],
        }
        self.assertTrue(_manifest_certified_unsafe_data(manifest))

    def test_schedule_manifest_requires_expression_projection_entries(self) -> None:
        sched_manifest = _dependency_schedule_manifest()
        sched_manifest["projection"] = list(sched_manifest["projection"]) + [
            {
                "lhs": "expr:0",
                "rhs": "flow_id_reg[0bv32]",
                "kind": "expr",
                "source": "dependency_projection",
            }
        ]
        sched_manifest["schedule_id"] = wraparound_cegis.compute_actor_schedule_id(
            candidate_id=str(sched_manifest["candidate_id"]),
            target_regs=[str(v) for v in sched_manifest["target_regs"]],
            index_value=int(sched_manifest["index_value"]),
            step_delta=int(sched_manifest["step_delta"]),
            actors=[str(v) for v in sched_manifest["actors"]],
            projection=list(sched_manifest["projection"]),
            base_bpl_sha256=sha256_text(_MIN_BPL),
        )
        manifest = {
            "cegar_mode": "schedule_replay",
            "base_bpl_sha256": sha256_text(_MIN_BPL),
            "attempts": [
                {
                    "cfg": _schedule_cfg(),
                    "entry": {"result_line": "RESULT: UNSAFE"},
                    "near_wrap": {"result_line": "RESULT: UNSAFE"},
                    "closure": {"result_line": "RESULT: SAFE"},
                    "schedule": copy.deepcopy(sched_manifest),
                    "certified": True,
                }
            ],
        }
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["cfg"]["proj_exprs"] = ["flow_id_reg[0bv32]"]
        self.assertTrue(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["schedule"]["projection"][-1]["rhs"] = "flow_id_reg[1bv32]"
        manifest["attempts"][0]["schedule"]["schedule_id"] = wraparound_cegis.compute_actor_schedule_id(
            candidate_id=str(sched_manifest["candidate_id"]),
            target_regs=[str(v) for v in sched_manifest["target_regs"]],
            index_value=int(sched_manifest["index_value"]),
            step_delta=int(sched_manifest["step_delta"]),
            actors=[str(v) for v in sched_manifest["actors"]],
            projection=list(manifest["attempts"][0]["schedule"]["projection"]),
            base_bpl_sha256=sha256_text(_MIN_BPL),
        )
        self.assertFalse(_manifest_certified_unsafe_data(manifest))

    def test_schedule_manifest_requires_explicit_near_wrap(self) -> None:
        sched_manifest = _dependency_schedule_manifest()
        manifest = {
            "cegar_mode": "schedule_replay",
            "base_bpl_sha256": sha256_text(_MIN_BPL),
            "attempts": [
                {
                    "cfg": _schedule_cfg(),
                    "entry": {"result_line": "RESULT: UNSAFE"},
                    "confirm": {"result_line": "RESULT: UNSAFE"},
                    "closure": {"result_line": "RESULT: SAFE"},
                    "schedule": sched_manifest,
                    "certified": True,
                }
            ],
        }
        self.assertFalse(_manifest_certified_unsafe_data(manifest))
        manifest["attempts"][0]["near_wrap"] = {"result_line": "RESULT: UNSAFE"}
        self.assertTrue(_manifest_certified_unsafe_data(manifest))
        del manifest["attempts"][0]["cfg"]
        self.assertFalse(_manifest_certified_unsafe_data(manifest))

    def test_schedule_mode_accepts_non_unit_add_step_for_certification(self) -> None:
        cand = WraparoundCandidate(
            pump_reg="r",
            accel_regs=("r",),
            index_value=0,
            index_expr=None,
            proj_vars=("procurator_phase",),
            cutpoint_cond="(procurator_phase == 0)",
            reason="test",
            step_op="add",
            step_delta=2,
        )
        runner = _SequenceRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            non_unit_bpl = _MIN_BPL.replace(
                "r[0bv32] := add.bv8(r[0bv32], 1bv8);",
                "r[0bv32] := add.bv8(r[0bv32], 2bv8);",
            )
            base_bpl.write_text(non_unit_bpl, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=non_unit_bpl,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=cand,
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
            self.assertEqual(len(runner.calls), 3)
            self.assertTrue(manifest["certified"])
            self.assertEqual(manifest["attempts"][0]["cfg"]["step_delta"], 2)
            self.assertEqual(manifest["attempts"][0]["schedule"]["step_delta"], 2)

    def test_schedule_mode_unsupported_candidate_is_uncertified(self) -> None:
        runner = _SequenceRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text("var r: [bv32]bv8;\nprocedure mainProcedure() returns() {}\n", encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=base_bpl.read_text(encoding="utf-8"),
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
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(manifest["attempts"], [])
            self.assertFalse(manifest["certified"])
            self.assertIn("falling back", manifest["diagnostic"])
            self.assertFalse(_manifest_certified_unsafe_data(manifest))




if __name__ == "__main__":
    unittest.main()
