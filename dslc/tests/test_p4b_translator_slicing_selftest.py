import subprocess
import unittest
from pathlib import Path


class TestP4BTranslatorSlicingSelftest(unittest.TestCase):
    def test_netchain_seq_seed_slicing(self) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        p4b_bin = repo_root / "P4B-Translator" / "build-host" / "p4c-translator"
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "Netchain" / "netchain_16.p4"
        entries = repo_root / "Procurator" / "argo" / "code" / "dataset" / "Netchain" / "commands_1.txt"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not entries.exists() or not p4include.is_dir():
            self.skipTest("missing Netchain dataset or p4include")

        cmd = [
            str(p4b_bin),
            "-I",
            str(p4include),
            "--goto",
            "--bmv2cmds",
            str(entries),
            "--slicing-vars=sequence_reg_0[0]",
            "--slicing-selftest=netchain_seq",
            str(p4),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)


if __name__ == "__main__":
    unittest.main()
