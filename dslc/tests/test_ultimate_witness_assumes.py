from __future__ import annotations

import unittest

from dslc.toolchain.ultimate_witness import extract_assumptions_from_graphml, synthesize_boogie_assumes


_GRAPHML = """<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <graph edgedefault="directed">
    <node id="N0">
      <data key="assumption">clientTrack_meta.hashval_for_partition == 3</data>
      <data key="assumption">dsl_pump_mode = true</data>
      <data key="note">ignore this</data>
    </node>
  </graph>
</graphml>
"""


_BPL = """\
var clientTrack_meta.hashval_for_partition: bv16;
var dsl_pump_mode: bool;
var tmp: int;
var arr: [bv32]bv8;
"""


class UltimateWitnessAssumeTests(unittest.TestCase):
    def test_extract_and_synthesize(self) -> None:
        wa = extract_assumptions_from_graphml(_GRAPHML)
        self.assertTrue(any(a.expr.startswith("clientTrack_meta.hashval_for_partition") for a in wa))

        assumes = synthesize_boogie_assumes(witness_assumptions=wa, base_bpl_text=_BPL)
        # bv16 should be normalized to a bv literal.
        self.assertIn("clientTrack_meta.hashval_for_partition == 3bv16", assumes)
        self.assertIn("dsl_pump_mode == true", assumes)

    def test_extract_edge_assumptions(self) -> None:
        wa = extract_assumptions_from_graphml(
            """<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <key id="assumption" attr.name="assumption" for="edge"/>
  <graph edgedefault="directed">
    <node id="N0"/>
    <node id="N1"/>
    <edge source="N0" target="N1">
      <data key="assumption">clientTrack_meta.hashval_for_partition == 0x3</data>
    </edge>
  </graph>
</graphml>
"""
        )
        assumes = synthesize_boogie_assumes(witness_assumptions=wa, base_bpl_text=_BPL)
        self.assertIn("clientTrack_meta.hashval_for_partition == 3bv16", assumes)

    def test_filters_unknown_vars_and_arrays(self) -> None:
        wa = extract_assumptions_from_graphml(
            """<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <graph edgedefault="directed">
    <node id="N0">
      <data key="assumption">arr == 1</data>
      <data key="assumption">unknown == 2</data>
      <data key="assumption">tmp == 7</data>
    </node>
  </graph>
</graphml>
"""
        )
        assumes = synthesize_boogie_assumes(witness_assumptions=wa, base_bpl_text=_BPL, allow_prefixes=("tmp",))
        self.assertEqual(assumes, ["tmp == 7"])


if __name__ == "__main__":
    unittest.main()
