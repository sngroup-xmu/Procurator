from __future__ import annotations

import json
import tempfile
import unittest
from dataclasses import asdict
from pathlib import Path

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.bench.validate_counterexample import validate_wraparound_manifest
from dslc.workflows.wraparound_cegis import _manifest_certified_unsafe_data
from dslc.workflows.wraparound_schedule import (
    infer_static_deterministic_schedule,
    sha256_text,
)
from dslc.workflows.wraparound_support.loop_schedule import _run_schedule_replay_cegar_loop
from dslc.workflows.wraparound_support.schedule.stable_projection import stable_substitution_env_shape_assumes

from dslc.tests.wraparound.schedule.fixtures import _MIN_BPL, _SequenceRunner


_STABLE_SHAPE_BPL = """\
var procurator_phase: int;
var procurator_step: int;
var s1_hdr.ipv4.dscp: bv6;
var s1_meta.route.hit: bool;
var r: [bv32]bv8;
var r__last0_value: bv8;

procedure main() returns()
  modifies procurator_phase, r, r__last0_value;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    // env inject -> s1
  } else if (procurator_phase == 1) {
    // node pass -> s1
    if (s1_hdr.ipv4.dscp == 32bv6) {
      r[0bv32] := add.bv8(r[0bv32], 1bv8);
      r__last0_value := r[0bv32];
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
  modifies procurator_phase, procurator_step, s1_hdr.ipv4.dscp, s1_meta.route.hit, r, r__last0_value;
{
  procurator_step := 0;
  procurator_phase := 0;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
"""


def _stable_shape_candidate() -> WraparoundCandidate:
    return WraparoundCandidate(
        pump_reg="r",
        accel_regs=("r",),
        index_value=0,
        index_expr=None,
        proj_vars=("procurator_phase",),
        cutpoint_cond="(procurator_phase == 0)",
        reason="stable_shape_test",
        step_op="add",
        step_delta=1,
        stable_substitutions=(
            ("s1_hdr.ipv4.dscp", "32bv6"),
            ("s1_meta.route.hit", "true"),
        ),
    )


class StableProjectionTests(unittest.TestCase):
    def test_stable_substitutions_become_env_shape_assumes(self) -> None:
        preds = stable_substitution_env_shape_assumes(candidate=_stable_shape_candidate())
        self.assertEqual(
            preds,
            ("s1_hdr.ipv4.dscp == 32bv6", "s1_meta.route.hit == true"),
        )

    def test_schedule_replay_uses_candidate_stable_shape_as_env_shape(self) -> None:
        runner = _SequenceRunner(["SAFE"])
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            base_bpl = out_dir / "base.bpl"
            base_bpl.write_text(_STABLE_SHAPE_BPL, encoding="utf-8")

            manifest_path = _run_schedule_replay_cegar_loop(
                spec_path=out_dir / "x.prop",
                spec_text="",
                base_bpl=base_bpl,
                base_text=_STABLE_SHAPE_BPL,
                out_dir=out_dir,
                work_dir=out_dir / "work",
                candidate=_stable_shape_candidate(),
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
            self.assertEqual(attempt["cfg"]["proj_predicates"], [])
            self.assertEqual(attempt["cfg"]["proj_predicate_sources"], [])
            self.assertEqual(
                attempt["cfg"]["env_shape_assumes"],
                ["s1_hdr.ipv4.dscp == 32bv6", "s1_meta.route.hit == true"],
            )
            self.assertIn("candidate_stable_env_shape=2", attempt["cfg"]["notes"])
            entry_text = next(text for stage, text in runner.snapshots if stage == "entry_check")
            near_text = next(text for stage, text in runner.snapshots if stage == "near_wrap")
            closure_text = next(text for stage, text in runner.snapshots if stage == "closure_check")
            self.assertIn("s1_hdr.ipv4.dscp == 32bv6", entry_text)
            self.assertIn("s1_meta.route.hit == true", near_text)
            self.assertNotIn("wrap_closure_pred_0 := (s1_hdr.ipv4.dscp == 32bv6);", closure_text)
            self.assertNotIn("wrap_closure_pred_1 := (s1_meta.route.hit == true);", closure_text)
            preds = [p for p in attempt["schedule"]["projection"] if p["kind"] == "predicate"]
            self.assertEqual(preds, [])
            ok, msg = validate_wraparound_manifest(manifest_path)
            self.assertTrue(ok, msg)

    def test_manifest_accepts_certified_candidate_env_shape_assumes(self) -> None:
        sched = infer_static_deterministic_schedule(
            base_bpl_text=_MIN_BPL,
            candidate=_stable_shape_candidate(),
            base_bpl_sha256=sha256_text(_MIN_BPL),
        )
        assert sched is not None
        projection = sched.with_projection_vars(
            ("procurator_phase",),
            source="dependency_projection",
        )
        manifest = {
            "cegar_mode": "schedule_replay",
            "base_bpl_sha256": sha256_text(_MIN_BPL),
            "candidate": asdict(_stable_shape_candidate()),
            "attempts": [
                {
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
                        "env_shape_assumes": ["s1_hdr.ipv4.dscp == 32bv6"],
                        "projection_complete": True,
                        "closure_assumes": [],
                        "notes": [],
                    },
                    "entry": {"result_line": "RESULT: UNSAFE"},
                    "near_wrap": {"result_line": "RESULT: UNSAFE"},
                    "closure": {"result_line": "RESULT: SAFE"},
                    "schedule": projection.to_manifest(),
                    "certified": True,
                }
            ],
        }
        self.assertTrue(_manifest_certified_unsafe_data(manifest))

        manifest["attempts"][0]["cfg"]["env_shape_assumes"] = ["s1_hdr.ipv4.dscp == 32bv6", "x == 1bv1"]
        self.assertFalse(_manifest_certified_unsafe_data(manifest))


if __name__ == "__main__":
    unittest.main()
