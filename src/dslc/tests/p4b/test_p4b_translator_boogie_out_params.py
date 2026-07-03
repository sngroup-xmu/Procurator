import subprocess
import tempfile
import unittest
from pathlib import Path
from dslc.tests.helpers import repo_root_from_test
import re


class TestP4BTranslatorBoogieOutParams(unittest.TestCase):
    def _p4b_bin(self, repo_root: Path) -> Path:
        candidates = [
            repo_root / "third_party" / "p4c" / "source" / "build-host" / "backends" / "verify" / "p4c-translator",
            repo_root / "third_party" / "p4c" / "source" / "build-host" / "p4c-translator",
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

        repo_root = repo_root_from_test(Path(__file__))
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("p4c translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "benchmarks" / "datasets" / "DDOSD" / "src" / "ddosd_procurator_det.p4"
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
        p4include = repo_root / "third_party" / "p4c" / "source" / "p4include"
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

        # (1) DDOSD out effects must be modeled as writes to caller-visible
        # variables.  Newer p4c frontends lift action parameters into control
        # locals before the verify backend sees the IR, so these helpers may be
        # no-arg procedures with `modifies` rather than Boogie-return procedures.
        expected_effects = {
            "ingress_cs_hash": ["src_h1_0", "src_h2_0", "src_h3_0", "src_h4_0"],
            "ingress_cs_ghash": ["src_g1_0", "src_g2_0", "src_g3_0", "src_g4_0"],
            "ingress_median": ["meta.ip_count"],
            r"cs_hash_\d+": ["dst_h1_0", "dst_h2_0", "dst_h3_0", "dst_h4_0"],
            r"cs_ghash_\d+": ["dst_g1_0", "dst_g2_0", "dst_g3_0", "dst_g4_0"],
            r"median_\d+": ["meta.ip_count"],
        }
        for proc, vars_ in expected_effects.items():
            m = re.search(
                rf"(?ms)^procedure\s+\{{:\s*inline\s+1\}}\s+{proc}\b[^\n]*\n"
                rf"(?:\s+modifies\s+(?P<mods>[^;]+);\n)?\s*\{{(?P<body>.*?)^\}}",
                txt,
            )
            self.assertIsNotNone(m, f"missing procedure {proc}")
            assert m is not None
            mods = m.group("mods") or ""
            body = m.group("body")
            for var in vars_:
                self.assertIn(var, mods, f"{proc} must advertise modification of {var}")
                self.assertRegex(body, rf"\b{re.escape(var)}\s*:=", f"{proc} must assign {var}")

        for tgt in ["ingress_cs_hash", "ingress_cs_ghash", "ingress_median", "cs_hash_1", "cs_ghash_1", "median_1"]:
            self.assertRegex(txt, rf"(?m)^\s*call\s+{tgt}\(\);", f"missing call to {tgt}")


if __name__ == "__main__":
    unittest.main()
