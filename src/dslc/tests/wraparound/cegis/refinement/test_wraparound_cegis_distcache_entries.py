from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from dslc.utils.repo import repo_root
from dslc.workflows.wraparound_cegis import (
    _abstract_distcache_partition_hashes_to_caps,
    _infer_distcache_cache_frequency_get_optype,
    _infer_distcache_cache_frequency_update_profile,
    _infer_distcache_cache_lookup_idx,
    _infer_distcache_partition_eports,
)


class TestWraparoundCegisDistCacheEntries(unittest.TestCase):
    def test_infers_cache_frequency_profile_and_cache_lookup_idx_from_bench_spec(self) -> None:
        # This asserts the entry-derived "shape template" inference keeps working on the
        # repo's DistCache cache_frequency wraparound benchmark.
        spec_path = repo_root() / "benchmarks/specs/bench/distcache_leaf_cache_frequency_wraparound.prop"
        self.assertTrue(spec_path.exists(), spec_path)
        spec_text = spec_path.read_text(encoding="utf-8", errors="replace")

        idx = _infer_distcache_cache_lookup_idx(spec_text, spec_dir=spec_path.parent)
        self.assertEqual(idx, 7)

        prof = _infer_distcache_cache_frequency_update_profile(spec_text, spec_dir=spec_path.parent)
        self.assertEqual(prof.get("optype"), 0x4)
        self.assertEqual(prof.get("is_sampled"), 0x0)
        self.assertEqual(prof.get("is_cached"), 0x1)
        self.assertEqual(prof.get("is_latest"), 0x1)

        get_op = _infer_distcache_cache_frequency_get_optype(
            spec_text,
            spec_dir=spec_path.parent,
            is_sampled=int(prof.get("is_sampled", 0)),
            is_cached=int(prof.get("is_cached", 0)),
            is_latest=int(prof.get("is_latest", 0)),
        )
        self.assertEqual(get_op, 0x24)

    def test_infers_partition_eports_with_trailing_action_args(self) -> None:
        # Regression test: some BMv2 entries include extra action args after the eport token,
        # e.g. "=> 0x480 4". Our regex should still extract the first token.
        with tempfile.TemporaryDirectory(prefix="procurator-distcache-eports-") as td:
            d = Path(td)
            (d / "e.txt").write_text(
                "\n".join(
                    [
                        "table_add hash_leaf_partition_tbl hash_leaf_partition 0x30 0x0->0xf => 0x480 4",
                        "table_add hash_spine_partition_tbl hash_spine_partition 0x30 0x0->0xf => 0x1e 0x3",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )
            spec_text = 'entries "e.txt";\n'
            ports = _infer_distcache_partition_eports(spec_text, spec_dir=d)
            self.assertEqual(ports.get("leaf_eport"), 0x480)
            self.assertEqual(ports.get("spine_eport"), 0x1E)

    def test_abstracts_precise_partition_hashes_to_capped_havoc(self) -> None:
        bpl = "\n".join(
            [
                "procedure {:inline 1} clientTrack_partitionswitchIngress_hash_for_partition()",
                "  modifies clientTrack_meta.hashval_for_partition, clientTrack_meta.hashval_for_spine_partition;",
                "{",
                "  clientTrack_meta.hashval_for_partition := clientTrack___p4b_crc32_bmv2_byte(4294967295bv32, 0bv8)[16:0];",
                "  assume(buge.bv16(clientTrack_meta.hashval_for_partition, 0bv16) && bule.bv16(clientTrack_meta.hashval_for_partition, 32767bv16));",
                "  clientTrack_meta.hashval_for_spine_partition := clientTrack_hash_csum16$bv16$bv32(0bv16, 0bv32);",
                "  assume(buge.bv16(clientTrack_meta.hashval_for_spine_partition, 0bv16) && bule.bv16(clientTrack_meta.hashval_for_spine_partition, 32767bv16));",
                "}",
                "",
            ]
        )

        out = _abstract_distcache_partition_hashes_to_caps(
            bpl,
            node_prefixes=["clientTrack"],
            caps={"hashval_for_partition": 15, "hashval_for_spine_partition": 15},
        )

        self.assertNotIn("__p4b_crc32_bmv2_byte", out)
        self.assertNotIn("clientTrack_hash_csum16", out)
        self.assertIn("havoc clientTrack_meta.hashval_for_partition;", out)
        self.assertIn("assume(bule.bv16(clientTrack_meta.hashval_for_partition, 15bv16));", out)
        self.assertIn("havoc clientTrack_meta.hashval_for_spine_partition;", out)
        self.assertIn("assume(bule.bv16(clientTrack_meta.hashval_for_spine_partition, 15bv16));", out)


if __name__ == "__main__":
    unittest.main()
