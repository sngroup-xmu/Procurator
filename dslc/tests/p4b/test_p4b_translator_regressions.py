import re
import subprocess
import tempfile
import unittest
from pathlib import Path

from dslc.backends.boogie.core.bpl import find_missing_type_decls
from dslc.backends.boogie.node.p4b import _maybe_tofino_cpp_defines
from dslc.backends.boogie.node.p4b import _detect_missing_read_write_decls


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
        self.assertTrue(read_bases or write_bases, "expected at least one register read/write in ATP output")

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

        missing = []
        for b in sorted(read_bases | write_bases):
            if b not in decl_vars:
                missing.append(b)
            elif b in read_bases and b not in decl_reads:
                missing.append(b)
            elif b in write_bases and b not in decl_writes:
                missing.append(b)
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

    def test_json_ir_slicing_does_not_prune_register_domains(self) -> None:
        """JSON IR skips statement pruning, so register domains must stay complete."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4json = repo_root / "Procurator" / "argo" / "code" / "dataset" / "gecko" / "timer_b.json"
        entries = repo_root / "Procurator" / "argo" / "code" / "dataset" / "gecko" / "control" / "b.txt"
        if not p4json.exists() or not entries.exists():
            self.skipTest("missing Gecko JSON dataset or control-plane commands")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "gecko_json_sliced.bpl"
            cmd = [
                str(p4b_bin),
                "--goto",
                "--fromJSON",
                str(p4json),
                "--bmv2cmds",
                str(entries),
                "--slicing-vars=register_data_record[0]",
                "-o",
                str(out_bpl),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertRegex(text, r"axiom register_data_record(?:_\d+)?\.size == 140500bv32;")
        self.assertNotRegex(text, r"axiom register_data_record(?:_\d+)?\.size == 1bv32;")

    def test_gecko_json_register_actions_and_packet_emit_are_well_declared(self) -> None:
        """Regression: JSON-IR RegisterAction and packet_out.emit names must be declaration-safe."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4json = repo_root / "Procurator" / "argo" / "code" / "dataset" / "gecko" / "timer_a.json"
        entries = repo_root / "Procurator" / "argo" / "code" / "dataset" / "gecko" / "control" / "a.txt"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4json.exists() or not entries.exists() or not p4include.is_dir():
            self.skipTest("missing Gecko JSON dataset, control-plane commands, or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "gecko_timer_a.bpl"
            cmd = [
                str(p4b_bin),
                "-I",
                str(p4include),
                "--goto",
                "--fromJSON",
                str(p4json),
                "--bmv2cmds",
                str(entries),
                "--slicing-vars=hdr.albion.operation",
                "-o",
                str(out_bpl),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertEqual(_detect_missing_read_write_decls(out_bpl), [])
        self.assertEqual(find_missing_type_decls(text), [])
        self.assertNotRegex(text, r"(?m)^function\b.*\bpkt\.emit\b")
        self.assertRegex(text, r"(?m)^procedure\b.*\bpkt\.emit\b")

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

        self.assertRegex(text, r"(?m)^var\s+tcp_opt_cnt(?:_\d+)?\b")
        for name in ["int_parser_hop_data_len", "int_parser_hop_data_len_0"]:
            self.assertRegex(text, rf"(?m)^var\s+{re.escape(name)}\b")

        m = re.search(
            r"(?s)procedure\s+\{:\s*inline\s+1\}\s+MyParser\(\)\s+modifies\s+(?P<mods>[^;]+);",
            text,
        )
        self.assertIsNotNone(m, "FlowDoS parser must have a modifies clause")
        mods = m.group("mods") if m else ""
        self.assertRegex(mods, r"\btcp_opt_cnt(?:_\d+)?\b")
        self.assertIn("int_parser_hop_data_len", mods)
        self.assertIn("int_parser_hop_data_len_0", mods)

    def test_flowdos_no_table_rules_keep_hit_false_on_apply(self) -> None:
        """Regression: table.apply().hit must be deterministic false on miss/default path."""

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

        m = re.search(
            r"(?s)procedure\s+\{:\s*inline\s+1\}\s+[A-Za-z0-9_$.]*ipv4_block\.apply\(\)\s+modifies\s+[^;]+;\s*\{(?P<body>.*?)\n\}",
            text,
        )
        self.assertIsNotNone(m, "FlowDoS ipv4_block.apply must exist")
        body = m.group("body") if m else ""
        self.assertRegex(body, r"[A-Za-z0-9_$.]*ipv4_block\.hit := false;")
        self.assertNotRegex(body, r"[A-Za-z0-9_$.]*ipv4_block\.hit := true;")

    def test_ubpf_three_arg_hash_lowers_to_deterministic_assignment(self) -> None:
        """Regression: uBPF hash(out, algo, data) must not be emitted as a no-op."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4 = repo_root / "P4B-Translator" / "testdata" / "p4_16_samples" / "hash_ubpf.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        sample_include = repo_root / "P4B-Translator" / "testdata" / "p4_16_samples"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing uBPF hash sample or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "hash_ubpf.bpl"
            cmd = [
                str(p4b_bin),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "-I",
                str(sample_include),
                "--goto",
                "--no-slicing",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertRegex(text, r"function\s+hash_lookup3\$bv16\$bv8")
        self.assertIn("meta.output := hash_lookup3$bv16$bv8(headers.test.sa, headers.test.da);", text)
        self.assertNotIn("// hash", text)

    def test_psa_identity_hash_extern_lowers_to_precise_slice(self) -> None:
        """Regression: identity Hash.get_hash must not use the CRC/UF hash abstraction."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4include = repo_root / "P4B-Translator" / "p4include"
        sample_dir = repo_root / "P4B-Translator" / "testdata" / "p4_16_samples"
        p4 = sample_dir / "psa-hash-04.p4"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing PSA hash sample or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "psa_hash_04.bpl"
            cmd = [
                str(p4b_bin),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "-I",
                str(sample_dir),
                "--goto",
                "--no-slicing",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("p4b_hash_model: extern", text)
        self.assertIn("model=identity precision=precise", text)
        self.assertIn("model=crc16_uf precision=deterministic_uninterpreted", text)
        self.assertRegex(text, r"b\.data1 := .*hdr\.ipv4\.protocol")
        self.assertNotRegex(text, r"b\.data1 := .*h1(?:_\d+)?\.get_hash")
        self.assertRegex(text, r"b\.data0 := .*get_hash.*\(")

    def test_counter_externs_emit_stateful_updates(self) -> None:
        """Regression: PSA and eBPF counters must not survive as comment-only effects."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4include = repo_root / "P4B-Translator" / "p4include"
        sample_dir = repo_root / "P4B-Translator" / "testdata" / "p4_16_samples"
        cases = [
            ("psa-counter1.p4", "MyIC_counter__counter", "call MyIC_counter.count(1024bv12);"),
            ("count_add_ebpf.p4", "pipe_counters__counter", "call pipe_counters.add(headers.ipv4.dstAddr, 0bv16++headers.ipv4.totalLen);"),
        ]
        if not p4include.is_dir() or not sample_dir.is_dir():
            self.skipTest("missing p4include or p4c samples")

        with tempfile.TemporaryDirectory() as td:
            for filename, state_name, update_call in cases:
                p4 = sample_dir / filename
                if not p4.exists():
                    self.skipTest(f"missing sample {filename}")
                out_bpl = Path(td) / f"{filename}.bpl"
                cmd = [
                    str(p4b_bin),
                    "--std",
                    "p4-16",
                    "-I",
                    str(p4include),
                    "-I",
                    str(sample_dir),
                    "--goto",
                    "--no-slicing",
                    "-o",
                    str(out_bpl),
                    str(p4),
                ]
                subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
                text = out_bpl.read_text(encoding="utf-8", errors="replace")
                self.assertIn(f"var {state_name}", text)
                self.assertIn(update_call, text)
                self.assertNotIn("// count", text)

    def test_psa_meter_execute_emits_stateful_model(self) -> None:
        """Regression: PSA Meter.execute must not remain an unmodeled extern call."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4include = repo_root / "P4B-Translator" / "p4include"
        sample_dir = repo_root / "P4B-Translator" / "testdata" / "p4_16_samples"
        if not p4include.is_dir() or not sample_dir.is_dir():
            self.skipTest("missing p4include or p4c samples")

        cases = [
            ("psa-meter1.p4", "call __meter_execute_", "MyIC_meter0.execute_colored("),
            ("psa-meter3.p4", "call __meter_execute_", "MyIC_meter0.execute(0bv12)"),
        ]
        with tempfile.TemporaryDirectory() as td:
            for filename, call_prefix, execute_call in cases:
                p4 = sample_dir / filename
                if not p4.exists():
                    self.skipTest(f"missing sample {filename}")
                out_bpl = Path(td) / f"{filename}.bpl"
                cmd = [
                    str(p4b_bin),
                    "--std",
                    "p4-16",
                    "-I",
                    str(p4include),
                    "-I",
                    str(sample_dir),
                    "--goto",
                    "--no-slicing",
                    "-o",
                    str(out_bpl),
                    str(p4),
                ]
                subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
                text = out_bpl.read_text(encoding="utf-8", errors="replace")
                self.assertIn("var MyIC_meter0__meter:[bv12]int;", text)
                self.assertIn("var MyIC_meter0__executed_any:bool;", text)
                self.assertIn("procedure {:inline 1} MyIC_meter0.execute(index:bv12) returns (color:int)", text)
                self.assertIn(call_prefix, text)
                self.assertIn(execute_call, text)
                self.assertNotIn("tmp := MyIC_meter0.execute(0bv12);", text)

    def test_psa_checksum_update_emits_conservative_event_model(self) -> None:
        """Regression: checksum calls must not survive as comment-only effects."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4include = repo_root / "P4B-Translator" / "p4include"
        sample_dir = repo_root / "P4B-Translator" / "testdata" / "p4_16_samples"
        p4 = sample_dir / "checksum1-bmv2.p4"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing PSA checksum sample or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "psa_checksum.bpl"
            cmd = [
                str(p4b_bin),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "-I",
                str(sample_dir),
                "--goto",
                "--no-slicing",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("var p4b_checksum_verified:bool;", text)
        self.assertIn("var p4b_checksum_updated:bool;", text)
        self.assertIn("var p4b_checksum_error:bool;", text)
        self.assertRegex(text, r"p4b_checksum_(?:verified|updated) := true;")
        self.assertNotIn("// verify_checksum", text)
        self.assertNotIn("// update_checksum", text)

    def test_pna_nic_package_calls_main_deparser(self) -> None:
        """Regression: PNA_NIC has four executable blocks; do not drop the deparser."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4include.is_dir() or not (p4include / "pna.p4").exists():
            self.skipTest("missing PNA p4include")

        p4_text = """
#include <core.p4>
#include <pna.p4>

header H {
    bit<8> f;
}

struct Headers {
    H h;
}

struct Meta {
    bit<8> m;
}

parser P(packet_in pkt,
         out Headers hdr,
         inout Meta meta,
         in pna_main_parser_input_metadata_t istd) {
    state start {
        transition accept;
    }
}

control Pre(in Headers hdr,
            inout Meta meta,
            in pna_pre_input_metadata_t istd,
            inout pna_pre_output_metadata_t ostd) {
    apply {
        meta.m = 1w0 ++ 7w1;
    }
}

control Main(inout Headers hdr,
             inout Meta meta,
             in pna_main_input_metadata_t im,
             inout pna_main_output_metadata_t om) {
    apply {
        hdr.h.f = meta.m;
    }
}

control D(packet_out pkt,
          in Headers hdr,
          in Meta meta,
          in pna_main_output_metadata_t ostd) {
    apply {
        pkt.emit(hdr.h);
    }
}

PNA_NIC(P(), Pre(), Main(), D()) main;
"""

        with tempfile.TemporaryDirectory() as td:
            p4 = Path(td) / "pna_nic_smoke.p4"
            p4.write_text(p4_text, encoding="utf-8")
            out_bpl = Path(td) / "pna_nic_smoke.bpl"
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

        m = re.search(r"(?s)procedure\s+\{:\s*inline\s+1\}\s+main\(\).*?(?=procedure\s+\{:\s*inline\s+1\}|$)", text)
        self.assertIsNotNone(m, "expected generated PNA_NIC main procedure")
        main_body = m.group(0) if m else ""
        self.assertIn("call P();", main_body)
        self.assertIn("call Pre();", main_body)
        self.assertIn("call Main();", main_body)
        self.assertIn("call D();", main_body)

    def test_tna_registeraction_execute_rhs_is_stateful(self) -> None:
        """Regression: TNA RegisterAction.execute on RHS must read/apply/write the register."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "external_etc_noms2024" / "noms_20_5_4.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing ETC TNA dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "etc.bpl"
            cmd = [str(p4b_bin), *_maybe_tofino_cpp_defines(str(p4))]
            cmd.extend(
                [
                    "--std",
                    "p4-16",
                    "-I",
                    str(p4include),
                    "--goto",
                    "--slicing-vars=Ingress_reg_pkt_count[0]",
                    "-o",
                    str(out_bpl),
                    str(p4),
                ]
            )
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertNotIn("function Ingress_read_pkt_count.execute", text)
        self.assertNotIn("meta.pkt_count := Ingress_read_pkt_count.execute(meta.register_index);", text)
        self.assertIn("__ra_val_Ingress_read_pkt_count := Ingress_reg_pkt_count.read", text)
        self.assertIn(
            "call __ra_val_Ingress_read_pkt_count, __ra_ret_Ingress_read_pkt_count := "
            "Ingress_read_pkt_count.apply(__ra_val_Ingress_read_pkt_count, __ra_ret_Ingress_read_pkt_count);",
            text,
        )
        self.assertIn("call Ingress_reg_pkt_count.write(meta.register_index, __ra_val_Ingress_read_pkt_count);", text)
        self.assertIn("meta.pkt_count := __ra_ret_Ingress_read_pkt_count;", text)

    def test_fisslock_sliced_register_size_consts_are_declared(self) -> None:
        """Regression: sliced register size axioms must retain their const declarations."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "fisslock" / "p4" / "switch.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing FissLock TNA dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "fisslock_sliced.bpl"
            cmd = [str(p4b_bin), *_maybe_tofino_cpp_defines(str(p4))]
            cmd.extend(
                [
                    "--std",
                    "p4-16",
                    "-I",
                    str(p4include),
                    "--goto",
                    "--slicing-vars=hdr.lock.transferred,IngressPipe_CounterTable_1_notification_cnt_1[0]",
                    "-o",
                    str(out_bpl),
                    str(p4),
                ]
            )
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        size_axioms = set(re.findall(r"axiom\s+([A-Za-z_][A-Za-z0-9_]*\.size)\s*==", text))
        size_consts = set(re.findall(r"const\s+([A-Za-z_][A-Za-z0-9_]*\.size)\s*:", text))
        self.assertTrue(size_axioms, "expected sliced FissLock output to retain register size axioms")
        self.assertEqual(size_axioms - size_consts, set())
        self.assertIn("IngressPipe_CounterTable_2_notification_cnt_2.size", size_axioms)

    def test_tofino_constructor_style_local_instantiation_translates(self) -> None:
        """Regression: TNA programs may instantiate a local control as `C c();`."""

        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built")

        p4 = repo_root / "Procurator" / "argo" / "code" / "dataset" / "tofinoTest" / "test.p4"
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing tofinoTest dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "tofino_test.bpl"
            cmd = [str(p4b_bin), *_maybe_tofino_cpp_defines(str(p4))]
            cmd.extend(
                [
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
            )
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("procedure {:inline 1} EmptyEgress_bypass_bypass_egress.apply()", text)
        self.assertIn("call EmptyEgress_bypass_bypass_egress.apply();", text)
        self.assertIn("procedure {:inline 1} pipe()", text)
        self.assertIn("call IngressParser();", text)
        self.assertIn("call EmptyEgress();", text)

    def test_neuralp4_sliced_modifies_do_not_redeclare_pruned_temps(self) -> None:
        """Regression: slicing must not reintroduce pruned ANN temporaries via modifies."""

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
            / "external_neuralp4_noms25"
            / "NeuralP4"
            / "p4-vm"
            / "netml-iot-16x32x2-q4-4"
            / "code"
            / "ANN.p4"
        )
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing NeuralP4 dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "ann_sliced.bpl"
            cmd = [
                str(p4b_bin),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "--goto",
                "--slicing-vars=MyIngress_reg_n_received_stimuli[0],"
                "MyIngress_reg_received_stimuli[0],MyIngress_reg_run_id[0],hdr.ann.valid",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("procedure {:inline 1} MyIngress()", text)
        self.assertRegex(text, r"(?m)^var\s+MyIngress_reg_run_id\b")
        self.assertNotRegex(text, r"(?m)^var\s+res_\d+")
        self.assertNotRegex(text, r"(?m)^var\s+operand_[abc]\d*_\d+")
        self.assertNotRegex(text, r"(?m)^\s*havoc\s+res_\d+;")
        self.assertNotRegex(text, r"(?m)^\s*havoc\s+operand_[abc]\d*_\d+;")
        for m in re.finditer(r"(?m)^procedure[^\n]*\n\s+modifies\s+(?P<mods>[^;]+);", text):
            mods = m.group("mods")
            self.assertNotRegex(mods, r"\bres_\d+")
            self.assertNotRegex(mods, r"\boperand_[abc]\d*_\d+")
        main_match = re.search(
            r"(?m)^procedure\s+mainProcedure\(\)\n\s+modifies\s+(?P<mods>[^;]+);",
            text,
        )
        self.assertIsNotNone(main_match)
        self.assertIn("p4b_checksum_error", main_match.group("mods"))
        self.assertIn("p4b_clone_i2e", main_match.group("mods"))

    def test_neuralp4_argmax_slice_keeps_used_temporaries_declared(self) -> None:
        """Regression: retained NeuralP4 arithmetic statements need temp decls."""

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
            / "external_neuralp4_noms25"
            / "NeuralP4"
            / "p4-vm"
            / "netml-iot-16x32x2-q4-4"
            / "code"
            / "ANN.p4"
        )
        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing NeuralP4 dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "ann_argmax_sliced.bpl"
            cmd = [
                str(p4b_bin),
                "--std",
                "p4-16",
                "-I",
                str(p4include),
                "--goto",
                "--slicing-vars=MyIngress_reg_neuron_max_value[0],"
                "MyIngress_reg_neuron_1_data[0],hdr.ann.valid,"
                "hdr.ann.data_1,hdr.ann.data_2,hdr.ann.neuron_id",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        for name in ("res_1_47", "operand_a_1_47", "operand_b1_2"):
            self.assertRegex(text, rf"(?m)^var\s+{name}\s*:")
            self.assertRegex(text, rf"(?m)\b{name}\b")
        my_ingress = re.search(
            r"(?m)^procedure\s+\{:inline 1\}\s+MyIngress\(\)\n\s+modifies\s+(?P<mods>[^;]+);",
            text,
        )
        self.assertIsNotNone(my_ingress)
        mods = my_ingress.group("mods")
        for name in ("res_1_47", "operand_a_1_47", "operand_b1_2"):
            self.assertIn(name, mods)


if __name__ == "__main__":
    unittest.main()
