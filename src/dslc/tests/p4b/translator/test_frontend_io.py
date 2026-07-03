import re
import subprocess
import tempfile
import unittest
from pathlib import Path
from dslc.tests.helpers import repo_root_from_test


class TestP4BVerifyFrontendIo(unittest.TestCase):
    def _p4b_bin(self, repo_root: Path) -> Path:
        candidates = [
            repo_root / "third_party" / "p4c" / "source" / "build-host" / "backends" / "verify" / "p4c-translator",
            repo_root / "third_party" / "p4c" / "source" / "build-host" / "p4c-translator",
        ]
        for path in candidates:
            if path.exists():
                return path
        return candidates[0]

    def test_missing_output_path_reports_error_instead_of_crashing(self) -> None:
        repo_root = repo_root_from_test(Path(__file__))
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("p4c translator not built")

        p4 = repo_root / "benchmarks" / "datasets" / "Netchain" / "netchain_16.p4"
        p4include = repo_root / "third_party" / "p4c" / "source" / "p4include"
        if not p4.exists() or not p4include.is_dir():
            self.skipTest("missing Netchain dataset or p4include")

        cmd = [str(p4b_bin), "-I", str(p4include), "--goto", str(p4)]
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

        self.assertNotEqual(proc.returncode, 0)
        self.assertIn("missing required -o <outfile>", proc.stdout)
        self.assertNotIn("SIGSEGV", proc.stdout)

    def test_tna_program_under_space_path_translates(self) -> None:
        repo_root = repo_root_from_test(Path(__file__))
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("p4c translator not built")

        soter = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "dataset"
            / "external_soter_srds22"
            / "Soter"
            / "Detection process"
            / "P4"
            / "simple_l3_test.p4"
        )
        p4include = repo_root / "third_party" / "p4c" / "source" / "p4include"
        if not soter.exists() or not p4include.is_dir():
            self.skipTest("missing Soter dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "soter.bpl"
            cmd = [
                str(p4b_bin),
                "-I",
                str(p4include),
                "--goto",
                "-o",
                str(out_bpl),
                str(soter),
            ]
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            self.assertEqual(proc.returncode, 0, proc.stdout)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("procedure", text)
        self.assertNotIn("fatal error: tna.p4", proc.stdout)
        self.assertNotIn("Detection: No such file or directory", proc.stdout)

    def test_tna_checksum_add_gets_declared_as_void_extern(self) -> None:
        repo_root = repo_root_from_test(Path(__file__))
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("p4c translator not built")

        netbeacon = (
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
        p4include = repo_root / "third_party" / "p4c" / "source" / "p4include"
        if not netbeacon.exists() or not p4include.is_dir():
            self.skipTest("missing NetBeacon dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "netbeacon.bpl"
            cmd = [
                str(p4b_bin),
                "-I",
                str(p4include),
                "--goto",
                "-o",
                str(out_bpl),
                str(netbeacon),
            ]
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            self.assertEqual(proc.returncode, 0, proc.stdout)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("procedure SwitchIngressParser_ipv4_checksum.add", text)
        self.assertIn("call SwitchIngressParser_ipv4_checksum.add(hdr.ipv4);", text)
        self.assertNotIn("function SwitchIngressParser_ipv4_checksum.add", text)
        self.assertNotIn("returns(ipv4_h)", text)

    def test_switchml_tna_stateful_features_translate_without_dangling_decls(self) -> None:
        repo_root = repo_root_from_test(Path(__file__))
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("p4c translator not built")

        switchml = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "dataset"
            / "external_switchml_nsdi21"
            / "switchml"
            / "dev_root"
            / "p4"
            / "switchml.p4"
        )
        p4include = repo_root / "third_party" / "p4c" / "source" / "p4include"
        if not switchml.exists() or not p4include.is_dir():
            self.skipTest("missing SwitchML dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "switchml.bpl"
            cmd = [
                str(p4b_bin),
                "-I",
                str(p4include),
                "--goto",
                "-o",
                str(out_bpl),
                str(switchml),
            ]
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            self.assertEqual(proc.returncode, 0, proc.stdout)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("type packet_type_t = bv4;", text)
        self.assertIn("var ig_md.port_metadata:port_metadata_t;", text)
        self.assertIn("var Egress_rdma_sender_psn_register:[bv32]bv32;", text)
        self.assertIn("function {:inline true}Egress_rdma_sender_psn_register.read", text)
        self.assertIn("procedure {:inline 1} Egress_rdma_sender_psn_register.write", text)
        self.assertIn("Egress_rdma_sender_psn_register.read(Egress_rdma_sender_psn_register, 0bv32)", text)
        self.assertIn("call Egress_rdma_sender_psn_register.write(0bv32,", text)
        self.assertIn("procedure IngressParser_ipv4_checksum.add", text)
        self.assertIn("call IngressParser_ipv4_checksum.add(hdr.ipv4);", text)
        self.assertNotIn("function IngressParser_ipv4_checksum.add", text)
        self.assertNotIn("returns(ipv4_h)", text)
        self.assertIn("var tmp_8.switchml_md.pool_index:pool_index_t;", text)
        self.assertIn("var tmp_8.switchml_md.worker_bitmap_before:worker_bitmap_t;", text)
        self.assertIn("tmp_8.switchml_md.pool_index", text)

        read_bases = set(
            m.group("base")
            for m in re.finditer(r"\b(?P<base>[A-Za-z_][A-Za-z0-9_]*)\.read\(\s*(?P=base)\s*,", text)
        )
        write_bases = set(
            m.group("base") for m in re.finditer(r"\bcall\s+(?P<base>[A-Za-z_][A-Za-z0-9_]*)\.write\(", text)
        )
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
        missing = [
            base for base in sorted(read_bases | write_bases)
            if base not in decl_vars or base not in decl_reads or base not in decl_writes
        ]
        self.assertEqual(missing, [], f"missing register declarations for bases: {missing}")

    def test_switchml_bit_to_bool_cast_is_not_havoced(self) -> None:
        repo_root = repo_root_from_test(Path(__file__))
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("p4c translator not built")

        switchml = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "dataset"
            / "external_switchml_nsdi21"
            / "switchml"
            / "dev_root"
            / "p4"
            / "switchml.p4"
        )
        p4include = repo_root / "third_party" / "p4c" / "source" / "p4include"
        if not switchml.exists() or not p4include.is_dir():
            self.skipTest("missing SwitchML dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "switchml.bpl"
            cmd = [
                str(p4b_bin),
                "-I",
                str(p4include),
                "--goto",
                "-o",
                str(out_bpl),
                str(switchml),
            ]
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            self.assertEqual(proc.returncode, 0, proc.stdout)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertNotRegex(
            text,
            r"procedure \{:\s*inline 1\} Ingress_rdma_receiver_(?:first|middle|last|only)_packet"
            r"(?:(?!^procedure ).)*havoc rdma_receiver_sequence_violation;",
        )
        self.assertRegex(
            text,
            r"rdma_receiver_sequence_violation := "
            r"\(rdma_receiver_result(?:_[0-9]+)?\[32:31\] != 0bv1\);",
        )

    def test_switchml_value00_slice_prunes_sibling_aggregation_registers(self) -> None:
        """Regression: slicing value00 must not retain dead value01..31 register artifacts."""

        repo_root = repo_root_from_test(Path(__file__))
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("p4c translator not built")

        switchml = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "dataset"
            / "external_switchml_nsdi21"
            / "switchml"
            / "dev_root"
            / "p4"
            / "switchml.p4"
        )
        p4include = repo_root / "third_party" / "p4c" / "source" / "p4include"
        if not switchml.exists() or not p4include.is_dir():
            self.skipTest("missing SwitchML dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "switchml-value00.bpl"
            cmd = [
                str(p4b_bin),
                "-I",
                str(p4include),
                "--goto",
                "--no-slicing-control-seeds",
                "--slicing-vars=Ingress_value00_values",
                "-o",
                str(out_bpl),
                str(switchml),
            ]
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            self.assertEqual(proc.returncode, 0, proc.stdout)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("var Ingress_value00_values:[pool_index_t]value_pair_t;", text)
        self.assertIn("function {:inline true}Ingress_value00_values.read", text)
        self.assertIn("procedure {:inline 1} Ingress_value00_values.write", text)
        self.assertIn("procedure {:inline 1} Ingress_value00_sum.apply()", text)

        for idx in range(1, 32):
            name = f"Ingress_value{idx:02d}_values"
            self.assertNotIn(f"var {name}:", text)
            self.assertNotIn(f"{name}.read", text)
            self.assertNotIn(f"{name}.write", text)
            self.assertNotIn(f"procedure {{:inline 1}} Ingress_value{idx:02d}", text)

    def test_switchml_sliced_counter_count_modifies_cover_add_callee(self) -> None:
        """Regression: slicing must keep wrapper modifies transitive across body calls."""

        repo_root = repo_root_from_test(Path(__file__))
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("p4c translator not built")

        switchml = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "dataset"
            / "external_switchml_nsdi21"
            / "switchml"
            / "dev_root"
            / "p4"
            / "switchml.p4"
        )
        p4include = repo_root / "third_party" / "p4c" / "source" / "p4include"
        if not switchml.exists() or not p4include.is_dir():
            self.skipTest("missing SwitchML dataset or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "switchml-bitmap.bpl"
            cmd = [
                str(p4b_bin),
                "-I",
                str(p4include),
                "--goto",
                "--no-slicing-control-seeds",
                (
                    "--slicing-vars="
                    "Ingress_update_and_check_worker_bitmap_worker_bitmap,"
                    "Ingress_workers_counter_workers_count,"
                    "Ingress_value00_values"
                ),
                "-o",
                str(out_bpl),
                str(switchml),
            ]
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            self.assertEqual(proc.returncode, 0, proc.stdout)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        proc_re = re.compile(
            r"(?ms)^procedure\s+\{:\s*inline\s+1\}\s+"
            r"(?P<name>[A-Za-z_][A-Za-z0-9_$.]*)\([^)]*\)\n"
            r"(?:\s+modifies\s+(?P<mods>[^;]+);\n)?"
            r"\{(?P<body>.*?)^\}"
        )
        procedures = {
            m.group("name"): {
                "mods": {
                    mod.strip()
                    for mod in (m.group("mods") or "").split(",")
                    if mod.strip()
                },
                "body": m.group("body"),
            }
            for m in proc_re.finditer(text)
        }

        checked = 0
        for name, proc_info in procedures.items():
            if not name.endswith(".count"):
                continue
            add_name = name[: -len(".count")] + ".add"
            if add_name not in procedures:
                continue
            if f"call {add_name}(" not in proc_info["body"]:
                continue
            missing = procedures[add_name]["mods"] - proc_info["mods"]
            self.assertEqual(missing, set(), f"{name} misses callee modifies: {sorted(missing)}")
            checked += 1

        self.assertGreater(checked, 0, "expected at least one sliced SwitchML counter wrapper")

    def test_saturated_ops_lower_to_guarded_ite(self) -> None:
        """Regression: |+| and |-| must use saturating semantics, not modular wrap."""

        repo_root = repo_root_from_test(Path(__file__))
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("p4c translator not built")

        saturated = (
            repo_root
            / "third_party" / "p4c" / "source"
            / "testdata"
            / "p4_16_samples"
            / "saturated-bmv2.p4"
        )
        p4include = repo_root / "third_party" / "p4c" / "source" / "p4include"
        if not saturated.exists() or not p4include.is_dir():
            self.skipTest("missing saturated sample or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "saturated.bpl"
            cmd = [
                str(p4b_bin),
                "-I",
                str(p4include),
                "--goto",
                "--no-slicing",
                "-o",
                str(out_bpl),
                str(saturated),
            ]
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            self.assertEqual(proc.returncode, 0, proc.stdout)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        # Saturating add: if sum wraps then clamp to MAX (all ones).
        self.assertIn("if bult.bv8(add.bv8(", text)
        self.assertIn("then sub.bv8(0bv8, 1bv8) else add.bv8(", text)
        self.assertIn("if bult.bv16(add.bv16(", text)
        self.assertIn("then sub.bv16(0bv16, 1bv16) else add.bv16(", text)
        # Saturating sub: if underflow then clamp to 0.
        self.assertIn("if bult.bv8(", text)
        self.assertIn("then 0bv8 else sub.bv8(", text)
        self.assertIn("if bult.bv16(", text)
        self.assertIn("then 0bv16 else sub.bv16(", text)

    def test_saturated_ops_ua_mode_keep_saturating_guards(self) -> None:
        """Regression: UA/bv2int mode must preserve saturating arithmetic guards."""

        repo_root = repo_root_from_test(Path(__file__))
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("p4c translator not built")

        saturated = (
            repo_root
            / "third_party" / "p4c" / "source"
            / "testdata"
            / "p4_16_samples"
            / "saturated-bmv2.p4"
        )
        p4include = repo_root / "third_party" / "p4c" / "source" / "p4include"
        if not saturated.exists() or not p4include.is_dir():
            self.skipTest("missing saturated sample or p4include")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "saturated-ua.bpl"
            cmd = [
                str(p4b_bin),
                "-I",
                str(p4include),
                "--goto",
                "--ua",
                "--no-slicing",
                "-o",
                str(out_bpl),
                str(saturated),
            ]
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            self.assertEqual(proc.returncode, 0, proc.stdout)
            text = out_bpl.read_text(encoding="utf-8", errors="replace")

        self.assertIn("function {:inline true} addsat.bv8(", text)
        self.assertIn("if(((left%power_2_8()) + (right%power_2_8())) >= power_2_8()) then power_2_8()-1", text)
        self.assertIn("function {:inline true} addsat.bv16(", text)
        self.assertIn("if(((left%power_2_16()) + (right%power_2_16())) >= power_2_16()) then power_2_16()-1", text)
        self.assertIn("function {:inline true} subsat.bv8(", text)
        self.assertIn("if((left%power_2_8()) < (right%power_2_8())) then 0", text)
        self.assertIn("function {:inline true} subsat.bv16(", text)
        self.assertIn("if((left%power_2_16()) < (right%power_2_16())) then 0", text)


if __name__ == "__main__":
    unittest.main()
