import unittest

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.speclang.model import SpecModel
from dslc.workflows.wraparound_cegis import _select_refinement_assumes_from_witness_diff


class TestWraparoundCegisClosureDiffRefine(unittest.TestCase):
    def test_picks_assumes_that_block_closure_counterexample(self) -> None:
        base_bpl = "\n".join(
            [
                # DistCache/P2C-style control vars (shape).
                "var clientTrack_meta.hashval_for_partition:bv16;",
                "type clientTrack_poweroftwochoice_tbl_0.action;",
                "const unique clientTrack_poweroftwochoice_tbl_0.action.poweroftwochoice : clientTrack_poweroftwochoice_tbl_0.action;",
                "const unique clientTrack_poweroftwochoice_tbl_0.action.update_leaf_load : clientTrack_poweroftwochoice_tbl_0.action;",
                "var clientTrack_poweroftwochoice_tbl_0.hit : bool;",
                "var clientTrack_poweroftwochoice_tbl_0.action_run : clientTrack_poweroftwochoice_tbl_0.action;",
                # A mandatory projection var (must not be pinned by refinement synthesis).
                "var procurator_phase:int;",
            ]
        )

        # Seed CONFIRM witness: takes the P2C path (poweroftwochoice) with a stable hash bucket.
        confirm_graphml = """<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <graph edgedefault="directed">
    <node id="N0"><data key="assumption">clientTrack_meta.hashval_for_partition == 5bv16</data></node>
    <node id="N1"><data key="assumption">clientTrack_poweroftwochoice_tbl_0.hit == true</data></node>
    <node id="N2"><data key="assumption">clientTrack_poweroftwochoice_tbl_0.action_run == clientTrack_poweroftwochoice_tbl_0.action.poweroftwochoice</data></node>
    <node id="N3"><data key="assumption">procurator_phase == 0</data></node>
  </graph>
</graphml>
"""

        # CLOSURE counterexample: diverges in a way that would break monotonicity (different action/hash).
        cex_graphml = """<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <graph edgedefault="directed">
    <node id="N0"><data key="assumption">clientTrack_meta.hashval_for_partition == 7bv16</data></node>
    <node id="N1"><data key="assumption">clientTrack_poweroftwochoice_tbl_0.hit == false</data></node>
    <node id="N2"><data key="assumption">clientTrack_poweroftwochoice_tbl_0.action_run == clientTrack_poweroftwochoice_tbl_0.action.update_leaf_load</data></node>
  </graph>
</graphml>
"""

        cand = WraparoundCandidate(
            pump_reg="clientTrack_partitionswitchIngress_leafload_reg",
            accel_regs=("clientTrack_partitionswitchIngress_leafload_reg",),
            index_value=0,
            index_expr=None,
            proj_vars=("procurator_phase",),
            cutpoint_cond=None,
            reason="unit_test",
            step_op="add",
            step_delta=1,
        )

        picked = _select_refinement_assumes_from_witness_diff(
            confirm_witness_text=confirm_graphml,
            cex_witness_text=cex_graphml,
            base_bpl_text=base_bpl,
            candidate=cand,
            spec_model=SpecModel(),
            max_new=8,
        )

        # Refinement assumptions must match CONFIRM and contradict the closure CEX.
        self.assertIn(
            "clientTrack_poweroftwochoice_tbl_0.action_run == clientTrack_poweroftwochoice_tbl_0.action.poweroftwochoice",
            picked,
        )
        self.assertIn("clientTrack_meta.hashval_for_partition == 5bv16", picked)
        self.assertIn("clientTrack_poweroftwochoice_tbl_0.hit == true", picked)

        # Ensure we prefer the most "shape-driving" constraint first (action selection).
        self.assertTrue(picked[0].endswith(".action.poweroftwochoice"))
