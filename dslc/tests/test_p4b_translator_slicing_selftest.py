import subprocess
import tempfile
import unittest
from pathlib import Path


class TestP4BTranslatorSlicingSelftest(unittest.TestCase):
    def _p4b_bin(self, repo_root: Path) -> Path:
        # This repo builds the verify backend translator under backends/verify/.
        candidates = [
            repo_root / "P4B-Translator" / "build-host" / "backends" / "verify" / "p4c-translator",
            repo_root / "P4B-Translator" / "build-host" / "p4c-translator",
        ]
        for p in candidates:
            if p.exists():
                return p
        return candidates[0]

    def test_netchain_seq_seed_slicing(self) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        p4b_bin = self._p4b_bin(repo_root)
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
            "--slicing-vars=sequence_reg[0]",
            "--slicing-selftest=netchain_seq",
            str(p4),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    def test_netchain_pop_front_header_stack_slicing(self) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        p4b_bin = self._p4b_bin(repo_root)
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
            "--slicing-vars=hdr.overlay.0.swip",
            "--slicing-selftest=netchain_pop_front",
            str(p4),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    def test_distcache_register_alias_seed_slicing(self) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "distcache" / "leafswitch" / "netcache.p4"
        entries = (
            repo_root / "Procurator" / "argo" / "code" / "dataset" / "distcache" / "leafswitch" / "flow_entries.txt"
        )
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not entries.exists() or not p4include.is_dir():
            self.skipTest("missing DistCache dataset or p4include")

        cmd = [
            str(p4b_bin),
            "-I",
            str(p4include),
            "--goto",
            "--bmv2cmds",
            str(entries),
            "--slicing-vars=netcacheEgress_cm3_reg,netcacheEgress_cm4_reg",
            "--slicing-selftest=distcache_reg_alias",
            str(p4),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    def test_distcache_parser_select_fields_not_dropped(self) -> None:
        """Regression: parser select fields must remain declared under slicing."""

        repo_root = Path(__file__).resolve().parents[2]
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "distcache" / "leafswitch" / "netcache.p4"
        entries = (
            repo_root / "Procurator" / "argo" / "code" / "dataset" / "distcache" / "leafswitch" / "flow_entries.txt"
        )
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not entries.exists() or not p4include.is_dir():
            self.skipTest("missing DistCache dataset or p4include")

        cmd = [
            str(p4b_bin),
            "-I",
            str(p4include),
            "--goto",
            "--bmv2cmds",
            str(entries),
            "--slicing-vars=hdr.op_hdr.optype",
            "--slicing-selftest=distcache_parser_select",
            str(p4),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    def test_distcache_bmv2_table_names_match_control_prefixed_tables(self) -> None:
        """Regression: BMv2 entries should apply even if P4 table names are control-prefixed."""

        repo_root = Path(__file__).resolve().parents[2]
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "dataset"
            / "distcache"
            / "clientrackswitch"
            / "partitionswitch.p4"
        )
        entries = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "dataset"
            / "distcache"
            / "clientrackswitch"
            / "flow_entries.txt"
        )
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not entries.exists() or not p4include.is_dir():
            self.skipTest("missing DistCache clientrackswitch dataset or p4include")

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
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            text = out_bpl.read_text(encoding="utf-8", errors="replace")
            # flow_entries.txt configures poweroftwochoice_tbl with optype 0x30/0x1009/0x2009.
            self.assertIn("procedure {:inline 1} partitionswitchIngress_poweroftwochoice_tbl.apply()", text)
            self.assertIn("if(hdr.op_hdr.optype == 48bv16)", text)
            self.assertIn("else if(hdr.op_hdr.optype == 4105bv16)", text)
            self.assertIn("else if(hdr.op_hdr.optype == 8201bv16)", text)

    def test_p4db_struct_types_are_declared(self) -> None:
        """Regression: P4->Boogie must emit `type T;` for opaque struct locals."""

        repo_root = Path(__file__).resolve().parents[2]
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "P4DB" / "tests" / "damper" / "router.p4"
        entries = repo_root / "Procurator" / "argo" / "code" / "spec" / "bench" / "p4db_damper_threshold1_commands.txt"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not entries.exists() or not p4include.is_dir():
            self.skipTest("missing P4DB dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            cmd = [
                str(p4b_bin),
                "-I",
                str(p4include),
                "--std",
                "p4-14",
                "--goto",
                str(p4),
                "-o",
                str(out_bpl),
                "--bmv2cmds",
                str(entries),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            text = out_bpl.read_text(encoding="utf-8", errors="replace")
            # router.p4 introduces a local of struct type `break_list`.
            self.assertIn("// Struct break_list", text)
            self.assertRegex(
                text,
                r"(?m)^\s*type\s+break_list\s*(?:=|;)\s*",
                msg="missing type decl for break_list",
            )

    def test_recirc_meta_flow_cross_stage_slicing(self) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "recirc_fanout" / "switch.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing recirc_fanout dataset or p4include")

        cmd = [
            str(p4b_bin),
            "-I",
            str(p4include),
            "--goto",
            "--slicing-vars=hdr.fanout.write_id",
            "--slicing-selftest=recirc_meta_flow",
            str(p4),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    def test_frr_pkt_par_write_not_dropped_by_action_slicing(self) -> None:
        """Regression: action-level slicing must keep stateful `pkt_par.write` for multi-step semantics."""

        repo_root = Path(__file__).resolve().parents[2]
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "FRR" / "main.p4"
        entries = repo_root / "Procurator" / "argo" / "code" / "dataset" / "FRR" / "commands.txt"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not entries.exists() or not p4include.is_dir():
            self.skipTest("missing FRR dataset or p4include")

        cmd = [
            str(p4b_bin),
            "-I",
            str(p4include),
            "--goto",
            "--bmv2cmds",
            str(entries),
            "--slicing-vars=meta.local_metadata.out_port,meta.local_metadata.pkt_par",
            "--slicing-selftest=frr_pkt_par_write",
            str(p4),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    def test_tofino_ingress_parser_labels_consistent(self) -> None:
        """Regression: Tofino/TNA parser apply must not produce dangling goto labels."""

        repo_root = Path(__file__).resolve().parents[2]
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "NetLock" / "switch" / "p4" / "netlock.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing NetLock dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines

            cmd = [
                str(p4b_bin),
                *_maybe_tofino_cpp_defines(str(p4)),
                "-I",
                str(p4include),
                "--goto",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            text = out_bpl.read_text(encoding="utf-8", errors="replace")
            self.assertIn("State$SwitchIngressParser$TofinoIngressParser_start:", text)
            self.assertIn("State$SwitchIngressParser$TofinoIngressParser_parse_resubmit:", text)
            self.assertIn("State$SwitchIngressParser$TofinoIngressParser_parse_port_metadata:", text)

    def test_tofino_table_slicing_keeps_table_semantics(self) -> None:
        """Regression: Tofino/TNA slicing must not stub out table.apply bodies."""

        repo_root = Path(__file__).resolve().parents[2]
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "NetLock" / "switch" / "p4" / "netlock.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing NetLock dataset or p4include")

        from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            cmd = [
                str(p4b_bin),
                *_maybe_tofino_cpp_defines(str(p4)),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "--goto",
                "--slicing-vars=head_register[0]",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            text = out_bpl.read_text(encoding="utf-8", errors="replace")
            self.assertIn("SwitchIngress_check_lock_exist_table.action_run", text)
            self.assertIn("procedure {:inline 1} SwitchIngress_check_lock_exist_table.apply()", text)
            self.assertIn("assume SwitchIngress_check_lock_exist_table.action_run ==", text)
            self.assertNotIn("procedure SwitchIngress_check_lock_exist_table.apply();", text)

    def test_fisslock_const_entries_translated_to_key_matches(self) -> None:
        """Regression: `const entries` tables must be key-dependent (no unconstrained action choice)."""

        repo_root = Path(__file__).resolve().parents[2]
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "fisslock" / "p4" / "switch.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing fisslock dataset or p4include")

        from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            cmd = [
                str(p4b_bin),
                *_maybe_tofino_cpp_defines(str(p4)),
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

            proc = "IngressPipe_CounterTable_1_counter_table_1.apply"
            start = text.find(f"procedure {{:inline 1}} {proc}()")
            self.assertNotEqual(start, -1, msg=f"missing procedure {proc}()")

            # Find the procedure-body opening brace, not the attribute brace in `{:inline 1}`.
            import re

            m = re.search(r"\n\s*\{", text[start:])
            self.assertIsNotNone(m, msg=f"missing body start for {proc}()")
            assert m is not None
            brace = start + m.end() - 1

            depth = 0
            end = -1
            for i in range(brace, len(text)):
                c = text[i]
                if c == "{":
                    depth += 1
                elif c == "}":
                    depth -= 1
                    if depth == 0:
                        end = i + 1
                        break
            self.assertNotEqual(end, -1, msg=f"unterminated body for {proc}()")
            body = text[brace:end]

            # Must contain key-based if-else chain derived from const entries.
            self.assertIn("if(hdr.lock.type == 1bv8", body)
            self.assertIn("hdr.lock.mode == 0bv1", body)
            self.assertIn("hdr.lock.old_mode == 0bv1", body)

            # Must NOT use the unconstrained goto/assume action selector for const entries.
            self.assertNotRegex(body, re.compile(r"(?m)^\\s*goto\\s+.*action_", re.MULTILINE))

            # In goto mode, default action must be executed when no entry matches.
            self.assertIn("if(!IngressPipe_CounterTable_1_counter_table_1.hit)", body)

    def test_atp_register_slicing_emits_register_decls(self) -> None:
        """Regression: slicing must not leave dangling register reads/writes without decls."""

        repo_root = Path(__file__).resolve().parents[2]
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

            import re

            # Collect base names for register read/write call sites.
            read_bases = set(
                m.group("base")
                for m in re.finditer(
                    r"\b(?P<base>[A-Za-z_][A-Za-z0-9_]*)\.read\(\s*(?P=base)\s*,", text
                )
            )
            write_bases = set(
                m.group("base")
                for m in re.finditer(r"\bcall\s+(?P<base>[A-Za-z_][A-Za-z0-9_]*)\.write\(", text)
            )
            bases = sorted(read_bases | write_bases)
            self.assertTrue(bases, "expected at least one register read/write in ATP output")

            decl_vars = set(m.group("name") for m in re.finditer(r"^\s*var\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*:", text, re.M))
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

        repo_root = Path(__file__).resolve().parents[2]
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


if __name__ == "__main__":
    unittest.main()
