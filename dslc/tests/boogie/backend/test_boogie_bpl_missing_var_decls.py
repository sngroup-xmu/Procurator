import unittest

from dslc.backends.boogie.core.bpl import assert_no_missing_var_decls, find_missing_var_decls


class TestBoogieBplMissingVarDecls(unittest.TestCase):
    def test_find_missing_packet_var_decl(self) -> None:
        raw = "var hdr.ipv4.srcAddr:bv32;\nhdr.ipv4.srcAddr := hdr.ipv4.dstAddr;\n"
        self.assertEqual(find_missing_var_decls(raw), ["hdr.ipv4.dstAddr"])

    def test_nested_metadata_suffix_is_not_reported_as_bare_var(self) -> None:
        raw = (
            "var sw_ig_md.switchml_md.pool_index:sw_pool_index_t;\n"
            "var sw_ig_md.switchml_md.map_result:sw_worker_bitmap_t;\n"
            "procedure mainProcedure() returns()\n"
            "  modifies sw_ig_md.switchml_md.pool_index, sw_ig_md.switchml_md.map_result;\n"
            "{\n"
            "  sw_ig_md.switchml_md.pool_index := sw_ig_md.switchml_md.pool_index;\n"
            "  sw_ig_md.switchml_md.map_result := 0bv32;\n"
            "}\n"
        )
        self.assertEqual(find_missing_var_decls(raw), [])
        assert_no_missing_var_decls(raw)


if __name__ == "__main__":
    unittest.main()
