import pathlib
import unittest


class TestDistcacheP2CWraparoundSpec(unittest.TestCase):
    def test_spec_file_exists_and_has_expected_markers(self) -> None:
        p = pathlib.Path("benchmarks/specs/bench/distcache_p2c_wraparound_bug.prop")
        self.assertTrue(p.exists(), "spec must exist")
        txt = p.read_text(encoding="utf-8", errors="replace")
        # Sanity: the spec must reference both opcodes used by the two-packet script.
        self.assertIn("hdr.op_hdr.optype = 8201", txt)  # update_leaf_load (0x2009)
        self.assertIn("hdr.op_hdr.optype = 48", txt)    # P2C query (0x30)
        # Must be marked as a wraparound benchmark.
        self.assertIn("wraparound", txt.lower())


if __name__ == "__main__":
    unittest.main()
