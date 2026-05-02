import re
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

        self.assertIn("buge.bv32(counter_pos_0, 0bv32)", text)
        self.assertIn("bule.bv32(counter_pos_0, 4095bv32)", text)
        self.assertIsNone(re.search(r"counter_pos_0\s*>=\s*0bv32", text))
        self.assertIsNone(re.search(r"4096bv32\s*>=\s*counter_pos_0", text))

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
        self.assertRegex(text, r"function hash__crc16\$bv14\$bv32\$bv32\$bv8\$bv16\$bv16\$bv16\$bv14")


if __name__ == "__main__":
    unittest.main()
