import pathlib
import unittest


class TestDistcacheP2CSpineloadWraparoundSpec(unittest.TestCase):
    def test_spec_file_exists_and_is_functional(self) -> None:
        p = pathlib.Path("benchmarks/specs/bench/distcache_p2c_spineload_wraparound_bug.prop")
        self.assertTrue(p.exists(), "spec must exist")
        txt = p.read_text(encoding="utf-8", errors="replace")

        # Two-phase script markers (pump + suffix + query).
        self.assertIn("hdr.op_hdr.optype = 4105", txt)  # update_spine_load (0x1009)
        self.assertIn("hdr.op_hdr.optype = 8201", txt)  # update_leaf_load (0x2009)
        self.assertIn("hdr.op_hdr.optype = 48", txt)    # P2C query (0x30)

        # Functional: should key the property on the decision event, not on optype at the end of the pass.
        self.assertIn("clientTrack_poweroftwochoice_tbl_0.hit", txt)
        self.assertNotIn("clientTrack_hdr.op_hdr.optype != 48", txt)

        # Must be marked as a wraparound benchmark.
        self.assertIn("wraparound", txt.lower())


if __name__ == "__main__":
    unittest.main()
