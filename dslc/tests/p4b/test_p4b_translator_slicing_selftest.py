import subprocess
import tempfile
import unittest
from pathlib import Path
import re
import json


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
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
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

    def test_netchain_seq_register_mirrors_emitted_by_p4b(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "Netchain" / "netchain_16.p4"
        entries = repo_root / "Procurator" / "argo" / "code" / "dataset" / "Netchain" / "commands_1.txt"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not entries.exists() or not p4include.is_dir():
            self.skipTest("missing Netchain dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "netchain.bpl"
            cmd = [
                str(p4b_bin),
                "--std",
                "p4-16",
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

        for name in [
            "sequence_reg__last_index",
            "sequence_reg__last_value",
            "sequence_reg__wrote_any",
            "sequence_reg__wrote_index0",
            "sequence_reg__last0_value",
        ]:
            self.assertEqual(len(re.findall(rf"^var\s+{re.escape(name)}\b", text, flags=re.MULTILINE)), 1)

        self.assertRegex(text, r"(?s)procedure\s+\{:\s*inline\s+1\}\s+sequence_reg\.write\(.*?"
                               r"sequence_reg__last_index\s*:=\s*index;.*?"
                               r"sequence_reg__last0_value\s*:=\s*value;")
        self.assertNotIn("value_reg__last0_value", text)

    def test_netchain_pop_front_header_stack_slicing(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
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
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
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

    def test_distcache_kept_registers_keep_write_helpers(self) -> None:
        """Slicing must not keep register mirror globals without their helper procedures."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "distcache" / "leafswitch" / "netcache.p4"
        entries = repo_root / "Procurator" / "argo" / "code" / "spec" / "bench" / "distcache_leaf_cm_hotness_entries_min.txt"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not entries.exists() or not p4include.is_dir():
            self.skipTest("missing DistCache dataset, entries, or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "distcache_cm34.bpl"
            cmd = [
                str(p4b_bin),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "--goto",
                "--no-slicing-control-seeds",
                "--bmv2cmds",
                str(entries),
                "--slicing-vars=netcacheEgress_cm3_reg,netcacheEgress_cm4_reg",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        for reg in ["netcacheEgress_cm3_reg", "netcacheEgress_cm4_reg"]:
            self.assertRegex(text, rf"(?m)^function\s+{{:inline true}}{reg}\.read\b")
            self.assertRegex(text, rf"(?m)^procedure\s+{{:inline 1}}\s+{reg}\.write\b")
            self.assertRegex(
                text,
                rf"(?s)procedure\s+{{:inline 1}}\s+{reg}\.write\(.*?"
                rf"{reg}__wrote_any\s*:=\s*true;.*?"
                rf"{reg}__last0_value\s*:=\s*value;",
            )

    def test_distcache_parser_select_fields_not_dropped(self) -> None:
        """Regression: parser select fields must remain declared under slicing."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
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

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
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

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
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
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
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

    def test_recirc_payload_flow_cross_pass_slicing(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
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
            "--slicing-vars=standard_metadata.egress_spec",
            "--slicing-selftest=recirc_payload_flow",
            str(p4),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    def test_clone_payload_flow_cross_pass_slicing(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "clone_fanout" / "switch.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
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

    def test_frr_pkt_par_write_not_dropped_by_action_slicing(self) -> None:
        """Regression: action-level slicing must keep stateful `pkt_par.write` for multi-step semantics."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
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

    def test_netlock_pushback_underflow_regaction_execute_not_dropped_in_assignments(self) -> None:
        """Regression: slicing must keep regAction.execute() even when it appears under an assignment RHS."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "NetLock" / "switch" / "p4" / "netlock.p4"
        entries = repo_root / "Procurator" / "argo" / "code" / "spec" / "bench" / "netlock_min_entries_pushback_empty0.txt"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not entries.exists() or not p4include.is_dir():
            self.skipTest("missing NetLock dataset/entries or p4include")

        from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines

        cmd = [
            str(p4b_bin),
            *_maybe_tofino_cpp_defines(str(p4)),
            "--std",
            "p4-16",
            "-I",
            str(p4include),
            "--goto",
            "--bmv2cmds",
            str(entries),
            "--no-slicing-control-seeds",
            "--slicing-vars=slots_two_sides_register[0]",
            "--slicing-selftest=netlock_pushback_underflow",
            str(p4),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    def test_tofino_ingress_parser_labels_consistent(self) -> None:
        """Regression: Tofino/TNA parser apply must not produce dangling goto labels."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
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

    def test_psa_random_read_lowered_to_bounded_nondet(self) -> None:
        """Regression: PSA Random.read() is a zero-arg extern method, not register.read."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "P4B-Translator" / "testdata" / "p4_16_samples" / "psa-random.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing PSA random sample or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "psa-random.bpl"
            cmd = [
                str(p4b_bin),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "-I",
                str(p4.parent),
                "--goto",
                "--no-slicing",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("var __random_read_0:bv16;", text)
        self.assertIn("havoc __random_read_0;", text)
        self.assertIn("buge.bv16(__random_read_0, 200bv16)", text)
        self.assertIn("bule.bv16(__random_read_0, 400bv16)", text)

    def test_external_int_flowdos_parser_compatibility(self) -> None:
        """Regression: upstream INT FlowDoS should translate without dataset shims."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "external_int_flowdos" / "switch-flow.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing external INT FlowDoS dataset or p4include")

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

        self.assertIn("var int_parser_hop_data_len_0:bv32;", text)
        self.assertNotIn("var int_parser_hop_data_len_0:Ref;", text)
        self.assertNotIn("assume ();", text)
        self.assertNotIn("assume(!()&&!());", text)
        self.assertRegex(text, r"(?m)^var\s+tcp_opt_cnt\b")
        self.assertRegex(
            text,
            r"(?s)procedure\s+\{:\s*inline\s+1\}\s+MyParser\(\)\s+modifies\s+[^;]*tcp_opt_cnt",
        )
        self.assertNotRegex(text, r"(?m)^var\s+(tcp_opt_cnt|int_parser_hop_data_len(?:_\d+)?)\s*:\s*Ref;")
        labels = set(re.findall(r"(?m)^\s*(State\$[A-Za-z0-9_.$]+):", text))
        goto_targets = []
        for match in re.finditer(r"\bgoto\s+([^;]+);", text):
            goto_targets.extend(t.strip() for t in match.group(1).split(",") if t.strip().startswith("State$"))
        missing = sorted(t for t in goto_targets if t not in labels)
        self.assertEqual(missing, [])
        self.assertRegex(
            text,
            r"(?s)State\$MyParser\$int_parser_start:\s*.*?"
            r"meta\._int\.src_port := hdr\.tcp\.srcPort;.*?"
            r"goto State\$MyParser\$int_parser_start_false;",
        )
        self.assertRegex(
            text,
            r"(?s)State\$MyParser\$int_parser_start_0:\s*.*?"
            r"meta\._int\.src_port := hdr\.udp\.srcPort;.*?"
            r"goto State\$MyParser\$int_parser_start_false_0;",
        )
        self.assertIn("goto State$MyParser$int_parser_start;", text)
        self.assertIn("goto State$MyParser$int_parser_start_0;", text)

    def test_external_int_flowdos_reset_counter_not_exported_as_wraparound_meta(self) -> None:
        """Regression: counters with threshold resets are not exported as steady pumps."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "external_int_flowdos" / "switch-flow.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing external INT FlowDoS dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "flowdos.bpl"
            out_meta = Path(td) / "flowdos.meta.json"
            cmd = [
                str(p4b_bin),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "--goto",
                "--meta-out",
                str(out_meta),
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            meta = json.loads(out_meta.read_text(encoding="utf-8"))

        updates = meta.get("wraparound", {}).get("updates", [])
        counter_updates = [u for u in updates if u.get("reg") == "MyIngress_counter_filter"]
        self.assertFalse(counter_updates, f"FlowDoS reset counter must not be exported, got {updates!r}")
        index_defs = meta.get("wraparound", {}).get("index_definitions", [])
        counter_defs = [d for d in index_defs if d.get("target_var") == "counter_pos"]
        self.assertTrue(counter_defs, f"expected counter_pos hash index definition, got {index_defs!r}")
        exprs = [d.get("expr", "") for d in counter_defs]
        self.assertTrue(any("__p4b_crc16_bmv2_byte" in e and "urem.bv32" in e for e in exprs))
        self.assertFalse(any("hash__crc16" in e for e in exprs))
        self.assertTrue(
            any("hdr.ipv4.srcAddr" in e for e in exprs),
            f"expected callsite-specialized counter_pos definition, got {counter_defs!r}",
        )

    def test_external_int_flowdos_hash_index_dependency_slicing(self) -> None:
        """Regression: slicing must keep hash(...) producer for dynamic register indices."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "external_int_flowdos" / "switch-flow.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing external INT FlowDoS dataset or p4include")

        cmd = [
            str(p4b_bin),
            "--std",
            "p4-16",
            "-I",
            str(p4include),
            "--goto",
            "--slicing-vars=counter_filter",
            "--slicing-selftest=flowdos_hash_index_dependency",
            str(p4),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    def test_external_netbeacon_total_pkts_keeps_result_guard_defs(self) -> None:
        """Regression: noaction table branches must not kill prior guard definitions."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "dataset"
            / "external_netbeacon_sec23"
            / "NetBeacon"
            / "switch"
            / "data_plane"
            / "switch.p4"
        )
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing external NetBeacon dataset or p4include")

        from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines

        cmd = [
            str(p4b_bin),
            *_maybe_tofino_cpp_defines(str(p4)),
            "--std",
            "p4-16",
            "-I",
            str(p4include),
            "-I",
            str(p4.parent),
            "--goto",
            "--no-slicing-control-seeds",
            "--slicing-vars=SwitchIngress_Register_total_pkts",
            "--slicing-selftest=netbeacon_total_pkts_result_guard",
            str(p4),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    def test_external_etc_noms2024_tna_hash_get_uses_data_fields(self) -> None:
        """Regression: TNA Hash<W>.get({fields}) must keep data arguments in Boogie."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "external_etc_noms2024" / "noms_20_5_4.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing external ETC_NOMS_2024 dataset or p4include")

        from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "etc.bpl"
            cmd = [
                str(p4b_bin),
                *_maybe_tofino_cpp_defines(str(p4)),
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

        self.assertIn("var Ingress_reg_pkt_count:[bv11]bv8;", text)
        self.assertIn("var Ingress_reg_pkt_len_total:[bv11]bv16;", text)
        self.assertIn(
            "p4b_hash_model: extern base=Ingress_flow_id_calc "
            "algorithm=HashAlgorithm_t.CRC32 model=crc32_bmv2 precision=precise",
            text,
        )
        self.assertIn(
            "p4b_hash_model: extern base=Ingress_idx_calc "
            "algorithm=HashAlgorithm_t.CRC16 model=crc16_bmv2 precision=precise",
            text,
        )
        self.assertIn("__p4b_crc32_bmv2_byte", text)
        self.assertIn("__p4b_crc16_bmv2_byte", text)
        self.assertRegex(
            text,
            r"(?s)meta\.flow_ID := .*__p4b_crc32_bmv2_byte.*"
            r"hdr\.ipv4\.src_addr.*hdr\.ipv4\.dst_addr.*srcPort(?:_\d+)?.*"
            r"dstPort(?:_\d+)?.*hdr\.ipv4\.protocol.*;",
        )
        self.assertRegex(
            text,
            r"(?s)meta\.register_index := .*__p4b_crc16_bmv2_byte.*"
            r"hdr\.ipv4\.src_addr.*hdr\.ipv4\.dst_addr.*srcPort(?:_\d+)?.*"
            r"dstPort(?:_\d+)?.*hdr\.ipv4\.protocol.*;",
        )
        self.assertRegex(
            text,
            r"(?s)procedure \{:inline 1\} Ingress_read_pkt_count\.apply"
            r"\(pkt_count_in:bv8, output_in:bv8\) returns "
            r"\(pkt_count_out:bv8, output_out:bv8\)\s*\{\s*var pkt_count:bv8;\s*var output:bv8;",
        )
        self.assertNotRegex(text, r"(?m)^var (output|pkt_count|status|classified_flag|flow_iat_min):")
        self.assertNotRegex(
            text,
            r"procedure \{:inline 1\} Ingress_read_pkt_count\.apply[^{]*\n\s*modifies",
        )
        self.assertNotIn("function Ingress_idx_calc.get() returns(bv11);", text)
        self.assertNotIn("meta.register_index := Ingress_idx_calc.get();", text)
        self.assertNotIn("function Ingress_flow_id_calc.get() returns(bv32);", text)
        self.assertNotIn("meta.flow_ID := Ingress_flow_id_calc.get();", text)

    def test_external_flowrest_registeraction_execute_wraparound_meta(self) -> None:
        """Regression: TNA RegisterAction.execute counters must be exported to wraparound meta."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

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
            self.skipTest("missing external Flowrest dataset or p4include")

        from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "flowrest.bpl"
            out_meta = Path(td) / "flowrest.meta.json"
            cmd = [
                str(p4b_bin),
                *_maybe_tofino_cpp_defines(str(p4)),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "-I",
                str(p4.parent),
                "--goto",
                "--no-slicing",
                "--meta-out",
                str(out_meta),
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            meta = json.loads(out_meta.read_text(encoding="utf-8"))
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        updates = meta.get("wraparound", {}).get("updates", [])
        pkt_count_updates = [u for u in updates if u.get("reg") == "Ingress_reg_pkt_count"]
        self.assertTrue(pkt_count_updates, "expected Flowrest reg_pkt_count RegisterAction.execute update")
        pkt = pkt_count_updates[0]
        self.assertEqual(pkt.get("idx_vars"), ["meta.register_index"])
        self.assertEqual(pkt.get("idx_expr"), "meta.register_index")
        self.assertEqual(pkt.get("value_var"), "__ra_ret_Ingress_read_pkt_count")
        self.assertEqual(pkt.get("op"), "add")
        self.assertIs(pkt.get("delta_is_const"), True)
        self.assertEqual(pkt.get("delta_const"), "1")
        self.assertEqual(pkt.get("value_width"), 8)
        self.assertEqual(pkt.get("index_width"), 16)
        defs = meta.get("wraparound", {}).get("index_definitions", [])
        reg_defs = [d for d in defs if d.get("target_var") == "meta.register_index"]
        self.assertTrue(reg_defs, "expected structured meta.register_index definition")
        self.assertTrue(
            any(
                d.get("expr")
                == (
                    "Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8("
                    "hdr.ipv4.src_addr, hdr.ipv4.dst_addr, "
                    "meta.hdr_srcport, meta.hdr_dstport, hdr.ipv4.protocol)"
                )
                for d in reg_defs
            ),
            f"expected callsite-specialized index definition, got {reg_defs!r}",
        )
        self.assertRegex(
            text,
            r"(?s)procedure \{:inline 1\} Ingress_update_flow_ID\.apply"
            r"\(flow_ID_in:bv32\) returns \(flow_ID_out:bv32\).*"
            r"flow_ID := meta\.flow_ID;",
        )

    def test_external_flowrest_slicing_keeps_registeraction_inout_writeback(self) -> None:
        """Regression: slicing must not drop RegisterAction inout updates used for register writeback."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

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
            self.skipTest("missing external Flowrest dataset or p4include")

        from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "flowrest.sliced.bpl"
            cmd = [
                str(p4b_bin),
                *_maybe_tofino_cpp_defines(str(p4)),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "-I",
                str(p4.parent),
                "--goto",
                "--slicing-vars=meta.pkt_count",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertRegex(
            text,
            r"(?s)procedure \{:inline 1\} Ingress_update_flow_ID\.apply"
            r"\(flow_ID_in:bv32\) returns \(flow_ID_out:bv32\).*"
            r"flow_ID := meta\.flow_ID;",
        )

    def test_external_flowrest_register_seed_prunes_unrelated_tables(self) -> None:
        """Regression: register-only slicing should not retain unrelated ML table suffixes."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

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
            self.skipTest("missing external Flowrest dataset or p4include")

        from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "flowrest.sliced.bpl"
            cmd = [
                str(p4b_bin),
                *_maybe_tofino_cpp_defines(str(p4)),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "-I",
                str(p4.parent),
                "--goto",
                "--no-slicing-control-seeds",
                "--slicing-vars=Ingress_reg_pkt_len_total",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("procedure {:inline 1} Ingress_read_pkt_len_total.apply", text)
        self.assertIn("Ingress_reg_pkt_len_total.write", text)
        for name in [
            "Ingress_table_feature0.apply",
            "Ingress_table_feature1.apply",
            "Ingress_table_feature6.apply",
            "Ingress_code_table0.apply",
            "Ingress_code_table2.apply",
            "Ingress_voting_table.apply",
        ]:
            self.assertNotIn(name, text)

    def test_external_flowrest_flow_duration_seed_prunes_sibling_feature_registers(self) -> None:
        """Regression: flow_duration slicing keeps only its timestamp/flow-ID dependency chain."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

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
            self.skipTest("missing external Flowrest dataset or p4include")

        from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines

        cmd = [
            str(p4b_bin),
            *_maybe_tofino_cpp_defines(str(p4)),
            "--std",
            "p4-16",
            "-I",
            str(p4include),
            "-I",
            str(p4.parent),
            "--goto",
            "--no-slicing-control-seeds",
            "--slicing-vars=Ingress_reg_flow_duration",
            "--slicing-selftest=flowrest_flow_duration_target_prefix",
            str(p4),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    def test_external_flowrest_ttl_seed_keeps_ttl_assignments(self) -> None:
        """Regression: property-observed header fields must keep P4 writes under slicing."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

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
            self.skipTest("missing external Flowrest dataset or p4include")

        from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "flowrest.sliced.bpl"
            cmd = [
                str(p4b_bin),
                *_maybe_tofino_cpp_defines(str(p4)),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "-I",
                str(p4.parent),
                "--goto",
                "--slicing-vars=hdr.ipv4.ttl,meta.pkt_count",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("hdr.ipv4.ttl := 127bv8;", text)
        self.assertIn("hdr.ipv4.ttl := 128bv8;", text)
        self.assertIn("hdr.ipv4.ttl := 255bv8;", text)
        self.assertIn("meta.classified_flag", text)
        self.assertIn("Ingress_update_classified_flag.apply", text)

    def test_external_etc_pkt_len_target_prefix_slicing(self) -> None:
        """Regression: ETC pkt_len target slicing must not keep classification suffixes."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "dataset"
            / "external_etc_noms2024"
            / "noms_20_5_4.p4"
        )
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing external ETC dataset or p4include")

        from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines

        cmd = [
            str(p4b_bin),
            *_maybe_tofino_cpp_defines(str(p4)),
            "--std",
            "p4-16",
            "-I",
            str(p4include),
            "--goto",
            "--no-slicing-control-seeds",
            "--slicing-vars=Ingress_reg_pkt_len_total",
            "--fail-fast-register-assert",
            "Ingress_reg_pkt_len_total:any:0",
            "--slicing-selftest=etc_pkt_len_target_prefix",
            str(p4),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    def test_external_etc_slicing_keep_vars_do_not_become_roots(self) -> None:
        """Regression: kept env fields must be declared without expanding the slice."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "dataset"
            / "external_etc_noms2024"
            / "noms_20_5_4.p4"
        )
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing external ETC dataset or p4include")

        from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "etc.sliced.bpl"
            cmd = [
                str(p4b_bin),
                *_maybe_tofino_cpp_defines(str(p4)),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "--goto",
                "--no-slicing-control-seeds",
                "--slicing-vars=Ingress_reg_pkt_len_total[0]",
                "--slicing-keep-vars=hdr.ipv4.total_len,ig_prsr_md.global_tstamp",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("var hdr.ipv4.total_len:bv16;", text)
        self.assertIn("var ig_prsr_md.global_tstamp:bv48;", text)
        self.assertIn("procedure {:inline 1} Ingress_read_pkt_len_total.apply", text)
        self.assertIn("Ingress_reg_pkt_len_total.write", text)
        for name in [
            "Ingress_read_pkt_count.apply",
            "Ingress_read_pkt_len_max.apply",
            "Ingress_read_time_last_pkt.apply",
            "Ingress_read_flow_iat_min.apply",
            "Ingress_read_flow_iat_max.apply",
            "Ingress_code_table0.apply",
            "Ingress_voting_table.apply",
        ]:
            self.assertNotIn(name, text)

    def test_external_flowrest_regaction_execute_respects_pruned_register_index(self) -> None:
        """Regression: RegisterAction.execute must respect regMaxIndex slicing assumptions."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

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
            self.skipTest("missing external Flowrest dataset or p4include")

        from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "flowrest.sliced.bpl"
            cmd = [
                str(p4b_bin),
                *_maybe_tofino_cpp_defines(str(p4)),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "-I",
                str(p4.parent),
                "--goto",
                "--slicing-vars=Ingress_reg_pkt_count[0]",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("axiom Ingress_reg_pkt_count.size == 1;", text)
        self.assertRegex(
            text,
            r"(?s)assume \(meta\.register_index == 0bv16\);\s*"
            r"__ra_val_Ingress_read_pkt_count := "
            r"Ingress_reg_pkt_count\.read\(Ingress_reg_pkt_count, meta\.register_index\);",
        )

    def test_external_etc_regaction_index_prune_declares_nonstandard_bv_width(self) -> None:
        """Regression: index pruning must declare helper functions for bv11 indices."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4 = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "dataset"
            / "external_etc_noms2024"
            / "noms_20_5_4.p4"
        )
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing external ETC dataset or p4include")

        from dslc.backends.boogie_p4b import _maybe_tofino_cpp_defines

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "etc.sliced.bpl"
            cmd = [
                str(p4b_bin),
                *_maybe_tofino_cpp_defines(str(p4)),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "-I",
                str(p4.parent),
                "--goto",
                "--slicing-vars=Ingress_reg_pkt_len_total[0]",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertNotIn('function {:bvbuiltin "bvule"} bule.bv11(left:bv11, right:bv11) returns(bool);', text)
        self.assertIn("axiom Ingress_reg_pkt_len_total.size == 1;", text)
        self.assertIn("axiom Ingress_reg_status.size == 1;", text)
        self.assertIn("axiom Ingress_reg_flow_ID.size == 1;", text)
        self.assertRegex(
            text,
            r"(?s)assume \(meta\.register_index == 0bv11\);\s*"
            r"__ra_val_Ingress_read_pkt_len_total := "
            r"Ingress_reg_pkt_len_total\.read\(Ingress_reg_pkt_len_total, meta\.register_index\);",
        )

    def test_tofino_table_slicing_keeps_table_semantics(self) -> None:
        """Regression: Tofino/TNA slicing must not stub out table.apply bodies."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
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

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
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

    def test_gecko_json_slicing_keeps_child_field_decls(self) -> None:
        """
        Regression: JSON-IR slicing may collect register/index metadata, but it
        must not filter declarations/tables while statement pruning is disabled.
        Keeping the full declaration set avoids dangling references from the
        unpruned JSON control flow.
        """

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        ir_json = repo_root / "Procurator" / "argo" / "code" / "dataset" / "gecko" / "timer_b.json"
        entries = repo_root / "Procurator" / "argo" / "code" / "dataset" / "gecko" / "control" / "b.txt"
        if not ir_json.exists() or not entries.exists():
            self.skipTest("missing Gecko JSON IR dataset or entries")

        with tempfile.TemporaryDirectory() as td:
            out_s = Path(td) / "slicing.bpl"
            out_n = Path(td) / "noslicing.bpl"

            cmd_s = [
                str(p4b_bin),
                "--goto",
                "--fromJSON",
                str(ir_json),
                "--bmv2cmds",
                str(entries),
                "--slicing-vars=hdr.albion.operation",
                "-o",
                str(out_s),
            ]
            cmd_n = [
                str(p4b_bin),
                "--goto",
                "--fromJSON",
                str(ir_json),
                "--bmv2cmds",
                str(entries),
                "--no-slicing",
                "-o",
                str(out_n),
            ]

            subprocess.run(cmd_s, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            subprocess.run(cmd_n, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            text_s = out_s.read_text(encoding="utf-8", errors="replace")
            text_n = out_n.read_text(encoding="utf-8", errors="replace")

            self.assertIn("var hdr.albion_data.data_0:", text_s)
            self.assertIn("var hdr.albion.index:", text_s)

            import re

            vars_s = len(re.findall(r"(?m)^\s*var\s+", text_s))
            vars_n = len(re.findall(r"(?m)^\s*var\s+", text_n))
            self.assertEqual(vars_s, vars_n, "JSON slicing should not filter declarations without statement pruning")


if __name__ == "__main__":
    unittest.main()
