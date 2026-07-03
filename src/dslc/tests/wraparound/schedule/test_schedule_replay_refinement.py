from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from dslc.workflows.wraparound_cegis import _run_schedule_replay_cegar_loop

from dslc.tests.wraparound.schedule.fixtures import (
    _MIN_BPL,
    _SequenceRunner,
    _TimeoutRecordingRunner,
    _candidate,
    _candidate_with_mailbox_projection,
)


_WITNESS = """<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <graph edgedefault="directed">
    <node id="N0">
      <data key="assumption">s1_hdr.nc_hdr.op == 12</data>
    </node>
  </graph>
</graphml>
"""


class _WitnessWriterMixin:
    def run(self, *, stage: str, **kwargs):  # type: ignore[no-untyped-def]
        if stage.startswith("confirm.witness."):
            input_bpl = Path(kwargs["input_bpl"])
            witness = input_bpl.parent / f"{input_bpl.name}-witness.graphml"
            witness.write_text(_WITNESS, encoding="utf-8")
        return super().run(stage=stage, **kwargs)


class TestScheduleReplayRefinement(unittest.TestCase):
    def test_schedule_replay_witness_timeout_not_capped_by_closure(self) -> None:
        class WitnessRunner(_WitnessWriterMixin, _TimeoutRecordingRunner):
            pass

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
        class WitnessRunner(_WitnessWriterMixin, _SequenceRunner):
            pass

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
            self.assertFalse(any(p["lhs"] == "s1_inbox_count" and p["source"] == "candidate_projection" for p in projection))
            self.assertFalse(any(p["source"] == "near_wrap_witness" for p in projection))
            self.assertTrue(
                any(p["lhs"] == "s1_hdr.nc_hdr.op" and p["source"] == "near_wrap_witness" for p in third["schedule"]["conditions"])
            )
            self.assertEqual(third["diagnostic"], "closure safe under witness replay conditions only; falling back")

    def test_schedule_replay_stop_after_closure_prevents_projection_weakening_retry(self) -> None:
        class WitnessRunner(_WitnessWriterMixin, _SequenceRunner):
            pass

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
            self.assertEqual(runner.calls, ["entry_check", "near_wrap", "closure_check"])
            self.assertFalse(manifest["certified"])
            self.assertEqual(manifest["diagnostic"], "stopped after closure by request")
            self.assertEqual(len(manifest["attempts"]), 1)
            self.assertEqual(manifest["attempts"][0]["diagnostic"], "stopped after closure by request")


if __name__ == "__main__":
    unittest.main()
