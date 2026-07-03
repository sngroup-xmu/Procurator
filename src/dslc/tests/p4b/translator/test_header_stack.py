import subprocess
import tempfile
import unittest
from pathlib import Path
from dslc.tests.helpers import repo_root_from_test


class TestP4BHeaderStackDeclarations(unittest.TestCase):
    def _p4b_bin(self, repo_root: Path) -> Path:
        candidates = [
            repo_root / "third_party" / "p4c" / "source" / "build-host" / "backends" / "verify" / "p4c-translator",
            repo_root / "third_party" / "p4c" / "source" / "build-host" / "p4c-translator",
        ]
        for path in candidates:
            if path.exists():
                return path
        return candidates[0]

    def test_netchain_sliced_header_stack_declarations(self) -> None:
        repo_root = repo_root_from_test(Path(__file__))
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("p4c translator not built")

        p4 = repo_root / "benchmarks" / "datasets" / "Netchain" / "netchain_16.p4"
        entries = repo_root / "benchmarks" / "datasets" / "Netchain" / "commands_1.txt"
        p4include = repo_root / "third_party" / "p4c" / "source" / "p4include"
        if not p4.exists() or not entries.exists() or not p4include.is_dir():
            self.skipTest("missing Netchain dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "netchain.bpl"
            cmd = [
                str(p4b_bin),
                "-I",
                str(p4include),
                "--goto",
                "--bmv2cmds",
                str(entries),
                "--slicing-vars=sequence_reg[0]",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("const hdr.overlay:HeaderStack;", text)
        self.assertIn("var hdr.overlay.last:Ref;", text)
        self.assertIn("var hdr.overlay.last.swip:bv32;", text)
        for idx in range(10):
            self.assertIn(f"var hdr.overlay.{idx}:Ref;", text)
            self.assertIn(f"var hdr.overlay.{idx}.valid:bool;", text)
            self.assertIn(f"var hdr.overlay.{idx}.swip:bv32;", text)
        self.assertIn("call packet_in.extract.headers.overlay.next(hdr.overlay);", text)
        self.assertIn("hdr.overlay.0.swip := hdr.overlay.1.swip;", text)
