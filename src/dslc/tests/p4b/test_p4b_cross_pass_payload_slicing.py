import subprocess
import unittest
from pathlib import Path


class TestP4BCrossPassPayloadSlicing(unittest.TestCase):
    def _p4b_bin(self, repo_root: Path) -> Path:
        candidates = [
            repo_root / "third_party" / "p4c" / "source" / "build-host" / "backends" / "verify" / "p4c-translator",
            repo_root / "third_party" / "p4c" / "source" / "build-host" / "p4c-translator",
        ]
        for path in candidates:
            if path.exists():
                return path
        return candidates[0]

    def test_recirc_payload_flow_cross_pass_slicing(self) -> None:
        repo_root = next(path for path in Path(__file__).resolve().parents if (path / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("p4c translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "benchmarks" / "datasets" / "recirc_fanout" / "switch.p4"
        p4include = repo_root / "third_party" / "p4c" / "source" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing recirc_fanout dataset or p4include")

        cmd = [
            str(p4b_bin),
            "-I",
            str(p4include),
            "--goto",
            "--slicing-vars=standard_metadata.egress_spec",
            "--slicing-selftest=recirc_payload_flow",
            str(p4),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    def test_clone_payload_flow_cross_pass_slicing(self) -> None:
        repo_root = next(path for path in Path(__file__).resolve().parents if (path / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("p4c translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "benchmarks" / "datasets" / "clone_fanout" / "switch.p4"
        p4include = repo_root / "third_party" / "p4c" / "source" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing clone_fanout dataset or p4include")

        cmd = [
            str(p4b_bin),
            "-I",
            str(p4include),
            "--goto",
            "--slicing-vars=p4b_clone_i2e",
            "--slicing-selftest=clone_payload_flow",
            str(p4),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)


if __name__ == "__main__":
    unittest.main()
