import unittest

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.speclang.model import SpecModel
from dslc.workflows.wraparound_cegis import _synthesize_refinement_assumes_from_witness


class TestWraparoundCegisRefinementAssumes(unittest.TestCase):
    def test_combines_env_and_shape_constraints(self) -> None:
        base_bpl = "\n".join(
            [
                "var clientTrack_meta.leafswitchidx:bv16;",
                "var clientTrack_meta.hashval_for_partition:bv16;",
                "type clientTrack_poweroftwochoice_tbl_0.action;",
                "const unique clientTrack_poweroftwochoice_tbl_0.action.update_leaf_load : clientTrack_poweroftwochoice_tbl_0.action;",
                "var clientTrack_poweroftwochoice_tbl_0.hit : bool;",
                "var clientTrack_poweroftwochoice_tbl_0.action_run : clientTrack_poweroftwochoice_tbl_0.action;",
                "var procurator_phase:int;",
            ]
        )

        witness_graphml = """<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <graph edgedefault="directed">
    <node id="N0"><data key="assumption">clientTrack_meta.leafswitchidx == 7bv16</data></node>
    <node id="N1"><data key="assumption">clientTrack_meta.hashval_for_partition == 5bv16</data></node>
    <node id="N2"><data key="assumption">clientTrack_poweroftwochoice_tbl_0.hit == true</data></node>
    <node id="N3"><data key="assumption">clientTrack_poweroftwochoice_tbl_0.action_run == clientTrack_poweroftwochoice_tbl_0.action.update_leaf_load</data></node>
    <node id="N4"><data key="assumption">procurator_phase == 0</data></node>
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

        out = _synthesize_refinement_assumes_from_witness(
            witness_text=witness_graphml,
            base_bpl_text=base_bpl,
            candidate=cand,
            spec_model=SpecModel(),
        )

        # env-profile assumptions
        self.assertIn("clientTrack_meta.leafswitchidx == 7bv16", out)
        # shape assumptions
        self.assertIn("clientTrack_meta.hashval_for_partition == 5bv16", out)
        self.assertIn("clientTrack_poweroftwochoice_tbl_0.hit == true", out)
        self.assertIn(
            "clientTrack_poweroftwochoice_tbl_0.action_run == clientTrack_poweroftwochoice_tbl_0.action.update_leaf_load",
            out,
        )
        # Do not pin scheduler variables from witnesses.
        self.assertNotIn("procurator_phase == 0", out)
