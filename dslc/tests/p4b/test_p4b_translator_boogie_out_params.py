import subprocess
import tempfile
import unittest
from pathlib import Path
import re


class TestP4BTranslatorBoogieOutParams(unittest.TestCase):
    def _p4b_bin(self, repo_root: Path) -> Path:
        candidates = [
            repo_root / "P4B-Translator" / "build-host" / "backends" / "verify" / "p4c-translator",
            repo_root / "P4B-Translator" / "build-host" / "p4c-translator",
        ]
        for p in candidates:
            if p.exists():
                return p
        return candidates[0]

    def test_ddosd_action_out_params_and_neg_bv_literals(self) -> None:
        """
        Regression: DDOSD exposes two translator issues that must never regress:
          1) action out/inout params must be encoded as Boogie returns (not as in-params),
             otherwise Ultimate TypeChecker rejects "in-parameter modified".
          2) negative InfInt bitvector constants must be rendered modulo 2^w (no `-1bv32`).
        """

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "DDOSD" / "src" / "ddosd_procurator_det.p4"
        entries = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "dataset"
            / "DDOSD"
            / "scripts"
            / "control_rules_window_collision_seed.txt"
        )
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not entries.exists() or not p4include.is_dir():
            self.skipTest("missing DDOSD dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "ddosd.raw.bpl"
            cmd = [
                str(p4b_bin),
                "-I",
                str(p4include),
                "--goto",
                "--bmv2cmds",
                str(entries),
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            txt = out_bpl.read_text(encoding="utf-8", errors="replace")

        # (2) Negative bitvector literals must be normalized (Ultimate rejects `-1bv32`).
        self.assertNotIn("-1bv", txt)

        # (1) DDOSD out params must become Boogie returns.
        # In the buggy version, Ultimate TypeChecker rejects assignments to out params
        # because they were encoded as in-parameters.
        proc_names = [
            "cs_hash",
            "cs_ghash",
            "median",
            "ingress_cs_hash",
            "ingress_cs_ghash",
            "ingress_median",
        ]
        for name in proc_names:
            # NOTE: use *single* backslashes for regex escapes in raw strings.
            # `\\b` would match a literal `\b` in the text, not a word-boundary.
            m = re.search(rf"(?m)^\s*procedure\b.*\b{name}(?:_\d+)?\b.*\breturns\s*\(", txt)
            self.assertIsNotNone(m, f"procedure {name} must use Boogie returns")

        # Call sites should use `call out := foo(in)` (not by-ref in-params).
        # Check both the helper wrappers (ingress_*) and the underlying actions (*_N).
        call_targets = [
            "ingress_cs_hash",
            "ingress_cs_ghash",
            "ingress_median",
            r"cs_hash_\d+",
            r"cs_ghash_\d+",
            r"median_\d+",
        ]
        for tgt in call_targets:
            self.assertRegex(txt, rf":=\s*{tgt}\s*\(", f"missing return-style call to {tgt}")


if __name__ == "__main__":
    unittest.main()
