import re
import json
import subprocess
import tempfile
import unittest
from pathlib import Path


class TestP4BFlowDoSHash(unittest.TestCase):
    def _p4b_bin(self, repo_root: Path) -> Path:
        candidates = [
            repo_root / "P4B-Translator" / "build-host" / "backends" / "verify" / "p4c-translator",
            repo_root / "P4B-Translator" / "build-host" / "p4c-translator",
        ]
        for candidate in candidates:
            if candidate.exists():
                return candidate
        return candidates[0]

    def test_v1model_hash_range_uses_bv_comparisons(self) -> None:
        """Regression: hash(out bit<W>, ...) range assumes must be typed Boogie BV ops."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "external_int_flowdos" / "switch-flow.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing FlowDoS dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "flowdos.bpl"
            cmd = [
                str(p4b_bin),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "--goto",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertRegex(text, r"assume\(buge\.bv32\(counter_pos(?:_\d+)?, 0bv32\)")
        self.assertRegex(text, r"bule\.bv32\(counter_pos(?:_\d+)?, 4095bv32\)\);")
        self.assertIsNone(re.search(r"counter_pos(?:_\d+)?\s*>=\s*0bv32", text))
        self.assertIsNone(re.search(r"4096bv32\s*>=\s*counter_pos(?:_\d+)?", text))

    def test_v1model_hash_range_coerces_mixed_width_args(self) -> None:
        """Regression: forced hash range width must change the Boogie expression too."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4 = repo_root / "P4B-Translator" / "testdata" / "p4_16_samples" / "flowlet_switching-bmv2.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing p4c flowlet switching sample or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "flowlet.bpl"
            cmd = [
                str(p4b_bin),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "--goto",
                "--no-slicing",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("0bv2++ecmp_base", text)
        self.assertIn("0bv12++ecmp_count", text)
        self.assertIn("sub.bv14(0bv12++ecmp_count, 1bv14)", text)
        self.assertIn("model=crc16_bmv2 precision=precise", text)
        self.assertIn("urem.bv14", text)
        self.assertIn("if 0bv12++ecmp_count == 0bv14 then 0bv2++ecmp_base", text)
        self.assertIn("__p4b_crc16_bmv2_byte", text)
        self.assertNotRegex(text, r"function hash__crc16\$bv14\$bv32\$bv32\$bv8\$bv16\$bv16\$bv16\$bv14")

    def test_flowdos_reset_counter_is_not_exported_as_steady_wraparound_candidate(self) -> None:
        """Regression: threshold-reset counters are not steady wraparound pumps."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "external_int_flowdos" / "switch-flow.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing FlowDoS dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "flowdos.bpl"
            meta = Path(td) / "flowdos.meta.json"
            cmd = [
                str(p4b_bin),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "--goto",
                "--meta-out",
                str(meta),
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            data = json.loads(meta.read_text(encoding="utf-8"))

        updates = data.get("wraparound", {}).get("updates", [])
        counter = [u for u in updates if u.get("reg") == "MyIngress_counter_filter"]
        self.assertFalse(counter, updates)

        index_defs = data.get("wraparound", {}).get("index_definitions", [])
        counter_pos_defs = [d for d in index_defs if d.get("target_var") == "counter_pos"]
        self.assertTrue(counter_pos_defs, index_defs)
        counter_pos_expr = counter_pos_defs[0].get("expr", "")
        self.assertIn("__p4b_crc16_bmv2_byte", counter_pos_expr)
        self.assertIn("urem.bv32", counter_pos_expr)
        self.assertIn("4096bv32", counter_pos_expr)
        self.assertNotIn("hash__crc16", counter_pos_expr)

    def test_flowdos_counter_write_sites_disambiguate_increment_from_reset(self) -> None:
        """Regression: Flow-INT counter checks can target the increment write only."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "external_int_flowdos" / "switch-flow.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing Flow-INT dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "flowdos.bpl"
            cmd = [
                str(p4b_bin),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "--goto",
                "--fail-fast-register-assert",
                "MyIngress_counter_filter:oldnewsite:255:0:1",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("var MyIngress_counter_filter__next_write_site:int;", text)
        self.assertIn("var MyIngress_counter_filter__last_write_site:int;", text)
        self.assertIn("MyIngress_counter_filter__next_write_site := 1;", text)
        self.assertIn("MyIngress_counter_filter__next_write_site := 2;", text)
        self.assertIn(
            "MyIngress_counter_filter__last_write_site := MyIngress_counter_filter__next_write_site;",
            text,
        )
        self.assertIn(
            "MyIngress_counter_filter__last_old_value == 255bv8 && "
            "MyIngress_counter_filter__last_value == 0bv8 && "
            "MyIngress_counter_filter__last_write_site == 1",
            text,
        )

    def test_flowrest_pkt_len_total_register_action_exports_steady_affine_update(self) -> None:
        """Regression: init-or-accumulate RegisterAction still exports the steady pump."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4 = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "dataset"
            / "external_flowrest_per_flow"
            / "unsw_per_flow_16_classes.p4"
        )
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing Flowrest dataset or p4include")

        from dslc.backends.boogie.node.p4b import _maybe_tofino_cpp_defines

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "flowrest.bpl"
            meta = Path(td) / "flowrest.meta.json"
            cmd = [
                str(p4b_bin),
                *_maybe_tofino_cpp_defines(str(p4)),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "--goto",
                "--meta-out",
                str(meta),
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            data = json.loads(meta.read_text(encoding="utf-8"))

        updates = data.get("wraparound", {}).get("updates", [])
        hits = [u for u in updates if u.get("reg") == "Ingress_reg_pkt_len_total"]
        self.assertTrue(hits, updates)
        self.assertTrue(any(u.get("op") == "add" and u.get("delta_is_const") is False for u in hits), hits)


if __name__ == "__main__":
    unittest.main()
