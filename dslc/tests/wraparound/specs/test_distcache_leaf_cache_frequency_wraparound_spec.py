import pathlib
import unittest


class TestDistcacheLeafCacheFrequencyWraparoundSpec(unittest.TestCase):
    def test_spec_file_exists_and_is_functional(self) -> None:
        p = pathlib.Path("Procurator/argo/code/spec/bench/distcache_leaf_cache_frequency_wraparound.prop")
        self.assertTrue(p.exists(), "spec must exist")
        txt = p.read_text(encoding="utf-8", errors="replace")

        # Two-phase script markers (pump + query).
        self.assertIn("hdr.op_hdr.optype = 4", txt)      # pump: GETREQ_INSWITCH
        self.assertIn("hdr.op_hdr.optype = 36", txt)     # query: GET_CACHE_FREQUENCY (0x24)

        # Functional: guard by pump_mode (stable), not by optype at end of pass.
        self.assertIn("pump_mode", txt)
        self.assertIn("leaf_hdr_eg.frequency_hdr.frequency", txt)
        self.assertNotIn("leaf_hdr.op_hdr.optype != 36", txt)

        # Must be marked as a wraparound benchmark.
        self.assertIn("wraparound", txt.lower())


if __name__ == "__main__":
    unittest.main()

