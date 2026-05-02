import re
import subprocess
import tempfile
import unittest
from pathlib import Path


class TestP4BTranslatorRegressions(unittest.TestCase):
    def _p4b_bin(self, repo_root: Path) -> Path:
        candidates = [
            repo_root / "P4B-Translator" / "build-host" / "backends" / "verify" / "p4c-translator",
            repo_root / "P4B-Translator" / "build-host" / "p4c-translator",
        ]
        for p in candidates:
            if p.exists():
                return p
        return candidates[0]

    def test_atp_register_slicing_emits_register_decls(self) -> None:
        """Regression: slicing must not leave dangling register reads/writes without decls."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "ATP" / "p4src" / "p4ml_lc_16.p4"
        entries = repo_root / "Procurator" / "argo" / "code" / "dataset" / "ATP" / "p4src" / "atp" / "flow.txt"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not entries.exists() or not p4include.is_dir():
            self.skipTest("missing ATP dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            cmd = [
                str(p4b_bin),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "--goto",
                "--bmv2cmds",
                str(entries),
                "--slicing-vars=hdr.p4ml_agtr_index.agtr",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        read_bases = set(
            m.group("base")
            for m in re.finditer(r"\b(?P<base>[A-Za-z_][A-Za-z0-9_]*)\.read\(\s*(?P=base)\s*,", text)
        )
        write_bases = set(
            m.group("base") for m in re.finditer(r"\bcall\s+(?P<base>[A-Za-z_][A-Za-z0-9_]*)\.write\(", text)
        )
        bases = sorted(read_bases | write_bases)
        self.assertTrue(bases, "expected at least one register read/write in ATP output")

        decl_vars = set(
            m.group("name") for m in re.finditer(r"^\s*var\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*:", text, re.M)
        )
        decl_reads = set(
            m.group("name")
            for m in re.finditer(r"^\s*function\b.*\b(?P<name>[A-Za-z_][A-Za-z0-9_]*)\.read\b", text, re.M)
        )
        decl_writes = set(
            m.group("name")
            for m in re.finditer(r"^\s*procedure\b\s+.*\b(?P<name>[A-Za-z_][A-Za-z0-9_]*)\.write\b", text, re.M)
        )

        missing = [b for b in bases if b not in decl_vars or b not in decl_reads or b not in decl_writes]
        self.assertEqual(missing, [], f"missing register decls for bases: {missing}")

    def test_p4db_damper_table_set_default_not_lost_under_slicing(self) -> None:
        """Regression: table_set_default should apply to P4_14 macro tables under slicing."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "P4DB" / "tests" / "damper" / "router.p4"
        entries = repo_root / "Procurator" / "argo" / "code" / "spec" / "bench" / "p4db_damper_threshold1_commands.txt"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not entries.exists() or not p4include.is_dir():
            self.skipTest("missing P4DB dataset, commands, or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            cmd = [
                str(p4b_bin),
                "--std",
                "p4-14",
                "-I",
                str(p4include),
                "--goto",
                "--bmv2cmds",
                str(entries),
                "--slicing-vars=damper_register",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("procedure {:inline 1} damper_tbl_1.apply()", text)
        self.assertIn("damper_tbl_1.action_run := damper_tbl_1.action.set_damper", text)
        self.assertIn("damper_tbl_1.set_damper.threshold := 1bv16", text)

    def test_flowdos_parser_local_temps_are_declared_and_modified(self) -> None:
        """Regression: parser-local temps introduced by copied states need globals/modifies."""

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

        for name in [
            "tcp_opt_cnt_0",
            "int_parser_hop_data_len",
            "int_parser_hop_data_len_0",
        ]:
            self.assertRegex(text, rf"(?m)^var\s+{re.escape(name)}\b")

        m = re.search(
            r"(?s)procedure\s+\{:\s*inline\s+1\}\s+MyParser\(\)\s+modifies\s+(?P<mods>[^;]+);",
            text,
        )
        self.assertIsNotNone(m, "FlowDoS parser must have a modifies clause")
        mods = m.group("mods") if m else ""
        self.assertIn("tcp_opt_cnt_0", mods)
        self.assertIn("int_parser_hop_data_len", mods)
        self.assertIn("int_parser_hop_data_len_0", mods)


if __name__ == "__main__":
    unittest.main()
