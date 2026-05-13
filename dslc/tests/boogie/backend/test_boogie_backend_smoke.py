import re
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from dslc.compiler import compile_spec_text


class TestBoogieBackendSmoke(unittest.TestCase):
    @staticmethod
    def _native_register_bpl(*, include_marker: bool = True, include_mirror_modifies: bool = True) -> str:
        marker = "// Register my_reg\n" if include_marker else ""
        modifies = "my_reg"
        if include_mirror_modifies:
            modifies += (
                ", my_reg__last_index, my_reg__last_value, my_reg__last_old_value, "
                "my_reg__wrote_any, my_reg__wrote_index0, my_reg__last0_old_value, "
                "my_reg__last0_value, my_reg__last_write_site"
            )
        return f"""\
type Ref;
var standard_metadata.egress_port:bv9;
var hdr.ipv4:Ref;
var hdr.ipv4.dstAddr:bv32;
var isValid:[Ref]bool;

{marker}var my_reg:[bv32]bv32;
var my_reg__last_index:bv32;
var my_reg__last_value:bv32;
var my_reg__last_old_value:bv32;
var my_reg__wrote_any:bool;
var my_reg__wrote_index0:bool;
var my_reg__last0_old_value:bv32;
var my_reg__last0_value:bv32;
var my_reg__next_write_site:int;
var my_reg__last_write_site:int;

procedure {{:inline 1}} my_reg.write(index:bv32, value:bv32)
  modifies {modifies};
{{
  my_reg__last_old_value := my_reg[index];
  my_reg[index] := value;
  my_reg__last_index := index;
  my_reg__last_value := value;
  my_reg__last_write_site := my_reg__next_write_site;
  my_reg__wrote_any := true;
  if (index == 0bv32) {{
    my_reg__wrote_index0 := true;
    my_reg__last0_old_value := my_reg__last_old_value;
    my_reg__last0_value := value;
  }}
}}

procedure mainProcedure() returns()
{{
}}
"""

    def test_boogie_harness_smoke(self) -> None:
        # Use a repo-shipped .bpl as input to avoid depending on building a translator here.
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
  int Counter = 0;
  Counter += 1;
  assert {{ Counter >= 1; }};
}}
global {{
  queue_capacity = 2;
  int G = 41;
  G += 1;
  assert {{ G == 42; }};
}}
"""
        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            outp = compile_spec_text(spec_text=spec, backend="boogie", out=out_bpl)
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        self.assertRegex(text, r"\bprocedure\s+ULTIMATE\.start\s*\(")
        self.assertRegex(text, r"\bfork\b")
        self.assertRegex(text, r"\batomic\b")
        self.assertRegex(text, r"\bvar\s+s1_inbox_count\b")
        # DSL locals are modeled as Boogie globals
        self.assertRegex(text, r"\bvar\s+dsl_G\s*:\s*int;")
        self.assertRegex(text, r"\bvar\s+s1_dsl_Counter\s*:\s*int;")
        # Initialization should occur in ULTIMATE.start
        self.assertRegex(text, r"\bdsl_G\s*:=\s*41;")
        self.assertRegex(text, r"\bs1_dsl_Counter\s*:=\s*0;")
        # Per-pass assignment should be emitted in the node thread
        self.assertRegex(text, r"\bs1_dsl_Counter\s*:=\s*s1_dsl_Counter\s*\+\s*1;")

    def test_concurrent_harness_is_stutter_free(self) -> None:
        # Regression/performance: avoid encoding explicit “do nothing” steps with
        # `if (*) { ... }` wrappers inside thread loops. These stuttering steps
        # introduce always-enabled self-loops that can make TraceAbstraction
        # diverge (even when the system is logically bounded via max_steps).
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
}}
global {{
  queue_capacity = 1;
  assert {{ true; }};
}}
"""
        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            outp = compile_spec_text(spec_text=spec, backend="boogie", out=out_bpl, boogie_harness="concurrent")
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        # With a single inject target and k==1, there should be no `if (*)` in either thread.
        env_start = text.find("procedure EnvThread()")
        self.assertNotEqual(env_start, -1)
        env_end = text.find("procedure s1Thread()", env_start)
        self.assertNotEqual(env_end, -1)
        env_body = text[env_start:env_end]
        self.assertNotIn("if (*)", env_body)

        thr_start = env_end
        thr_end = text.find("procedure ULTIMATE.start()", thr_start)
        self.assertNotEqual(thr_end, -1)
        thr_body = text[thr_start:thr_end]
        self.assertNotIn("if (*)", thr_body)

    def test_concurrent_harness_two_slot_inbox_k2(self) -> None:
        # Regression: for queue_capacity==2 we must materialize two inbox mailboxes and
        # actually load/dequeue them in the node thread (otherwise bugs that need two
        # pending packets become unreachable).
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
  env {{
    // Ensure DSL globals can be modified in EnvThread without Boogie type errors.
    phase = phase + 1;
  }}
}}
global {{
  queue_capacity = 2;
  int phase = 0;
  assert {{ phase >= 0; }};
}}
"""
        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            outp = compile_spec_text(spec_text=spec, backend="boogie", out=out_bpl, boogie_harness="concurrent")
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        # Two-slot inbox mailboxes are declared for on-wire vars.
        self.assertRegex(text, r"\bvar\s+s1_mb0_hdr\.ipv4\.dstAddr\b")
        self.assertRegex(text, r"\bvar\s+s1_mb1_hdr\.ipv4\.dstAddr\b")

        # EnvThread must list DSL globals it modifies.
        self.assertRegex(text, r"(?s)procedure EnvThread\(\) returns\(\)\s*modifies\b.*\bdsl_phase\b")
        # ULTIMATE.start must also cover vars modified by forked procedures.
        self.assertRegex(text, r"(?s)procedure ULTIMATE\.start\(\) returns\(\)\s*modifies\b.*\bdsl_phase\b")

        # Node thread must load and shift a mailbox slot when dequeueing.
        self.assertRegex(
            text,
            r"(?s)procedure s1Thread\(\) returns\(\).*?s1_hdr\.ipv4\.dstAddr := s1_mb0_hdr\.ipv4\.dstAddr;",
        )
        self.assertRegex(
            text,
            r"(?s)procedure s1Thread\(\) returns\(\).*?s1_mb0_hdr\.ipv4\.dstAddr := s1_mb1_hdr\.ipv4\.dstAddr;",
        )

    def test_host_env_target_table_assignments_are_in_modifies(self) -> None:
        bpl_text = """\
type Ref;
var standard_metadata.egress_port:bv9;
var hdr.ipv4:Ref;
var hdr.ipv4.dstAddr:bv32;
var isValid:[Ref]bool;
type tbl.action;
const unique tbl.action.set: tbl.action;
var tbl.action_run: tbl.action;
var tbl.set.arg:bv8;

procedure mainProcedure() returns()
{
}
"""
        spec_tmpl = """
import sw from "{raw}";
topology {{ }}
node sw {{ }}
host io {{
  connect sw;
  env {{
    sw_tbl.action_run = sw_tbl.action.set;
    sw_tbl.set.arg = 7;
    hdr.ipv4.dstAddr = 1;
  }}
}}
global {{
  queue_capacity = 1;
  deterministic_scheduler = true;
  host_eager = true;
  max_steps = 1;
  assert {{ true; }};
}}
"""

        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            raw_bpl = td_path / "prog.bpl"
            raw_bpl.write_text(bpl_text, encoding="utf-8")
            spec = spec_tmpl.format(raw=raw_bpl.as_posix())

            for harness in ("concurrent", "sequential"):
                out_bpl = td_path / f"out-{harness}.bpl"
                outp = compile_spec_text(
                    spec_text=spec,
                    backend="boogie",
                    out=out_bpl,
                    boogie_harness=harness,
                    pipeline_two_stage=False,
                    honor_spec_max_steps=True,
                    emit_reg_debug=False,
                )
                text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

                if harness == "concurrent":
                    self.assertRegex(
                        text,
                        r"(?s)procedure ioThread\(\) returns\(\)\s*modifies\b.*\bsw_tbl\.action_run\b",
                    )
                    self.assertRegex(
                        text,
                        r"(?s)procedure ioThread\(\) returns\(\)\s*modifies\b.*\bsw_tbl\.set\.arg\b",
                    )
                self.assertRegex(
                    text,
                    r"(?s)procedure (?:ULTIMATE\.start|mainProcedure)\(\) returns\(\)\s*modifies\b.*\bsw_tbl\.action_run\b",
                )
                self.assertRegex(
                    text,
                    r"(?s)procedure (?:ULTIMATE\.start|mainProcedure)\(\) returns\(\)\s*modifies\b.*\bsw_tbl\.set\.arg\b",
                )

    def test_no_reg_debug_omits_register_snapshot_vars(self) -> None:
        # Regression: `--no-reg-debug` should eliminate per-pass register snapshot globals
        # (`reg__dbg0`, `reg__last_*__dbg`, ...) and must not leave them in modifies clauses.
        bpl_text = """\
type Ref;
var standard_metadata.egress_port:bv9;
var hdr.ipv4:Ref;
var hdr.ipv4.dstAddr:bv32;
var isValid:[Ref]bool;

// Register my_reg
var my_reg:[bv32]bv32;

procedure mainProcedure() returns()
{
}
"""

        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            raw_bpl = td_path / "prog.bpl"
            raw_bpl.write_text(bpl_text, encoding="utf-8")

            spec = f"""
import s1 from "{raw_bpl.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
}}
global {{
  queue_capacity = 1;
  assert {{ true; }};
}}
"""

            # With reg-debug enabled (default), we expect snapshot vars.
            out_bpl_dbg = td_path / "out_dbg.bpl"
            outp_dbg = compile_spec_text(
                spec_text=spec,
                backend="boogie",
                out=out_bpl_dbg,
                boogie_harness="sequential",
                pipeline_two_stage=False,
                emit_reg_debug=True,
            )
            text_dbg = outp_dbg.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")
            self.assertIn("s1_my_reg__dbg0", text_dbg)

            # With reg-debug disabled, no `__dbg` vars should remain.
            out_bpl_no = td_path / "out_no_dbg.bpl"
            outp_no = compile_spec_text(
                spec_text=spec,
                backend="boogie",
                out=out_bpl_no,
                boogie_harness="sequential",
                pipeline_two_stage=False,
                emit_reg_debug=False,
            )
            text_no = outp_no.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")
            self.assertNotIn("__dbg", text_no)
            # Still recognize the register and keep the scalar mirror used by DSL/witness reads.
        self.assertIn("s1_my_reg__last0_value", text_no)

    def test_exact_register_mirror_assert_enables_p4b_fail_fast(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        spec = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "spec"
            / "bench"
            / "external_flowrest_per_flow_pkt_len_total_wraparound_direct.prop"
        )
        self.assertTrue(spec.exists())
        p4b_bin = repo_root / "P4B-Translator" / "build-host" / "backends" / "verify" / "p4c-translator"
        self.assertTrue(p4b_bin.exists())

        with tempfile.TemporaryDirectory() as td:
            outp = compile_spec_text(
                spec_text=spec.read_text(encoding="utf-8"),
                backend="boogie",
                out=Path(td) / "out.bpl",
                base_dir=spec.parent,
                p4b_bin=p4b_bin,
                boogie_harness="sequential",
                pipeline_two_stage=False,
                honor_spec_max_steps=True,
                emit_reg_debug=False,
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        self.assertIn(
            "if (flowrest_Ingress_reg_pkt_len_total__wrote_any && "
            "flowrest_Ingress_reg_pkt_len_total__last_value == 0bv16) {",
            text,
        )
        self.assertIn("assert false;", text)
        self.assertIn("assume false;", text)
        # P4B fail-fast assertions are additional early targets.  The original
        # DSL assertion remains in the harness for witness classification and
        # can also help the solver converge on some bounded cases.
        self.assertIn("// Global assertions (accumulated into procurator_bad)", text)
        self.assertIn("assert !procurator_bad;", text)

    def test_guarded_register_mirror_assert_does_not_enable_fail_fast(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        spec = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "spec"
            / "bench"
            / "external_flowrest_per_flow_pkt_len_total_wraparound.prop"
        )
        self.assertTrue(spec.exists())
        p4b_bin = repo_root / "P4B-Translator" / "build-host" / "backends" / "verify" / "p4c-translator"
        self.assertTrue(p4b_bin.exists())

        with tempfile.TemporaryDirectory() as td:
            outp = compile_spec_text(
                spec_text=spec.read_text(encoding="utf-8"),
                backend="boogie",
                out=Path(td) / "out.bpl",
                base_dir=spec.parent,
                p4b_bin=p4b_bin,
                boogie_harness="sequential",
                pipeline_two_stage=False,
                honor_spec_max_steps=True,
                emit_reg_debug=False,
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        self.assertNotIn(
            "if (flowrest_Ingress_reg_pkt_len_total__wrote_any && "
            "flowrest_Ingress_reg_pkt_len_total__last_value == 0bv16) {",
            text,
        )

    def test_guarded_register_mirror_assert_gets_dsl_direct_check(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        spec = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "spec"
            / "bench"
            / "external_flowrest_per_flow_flow_duration_wraparound.prop"
        )
        self.assertTrue(spec.exists())
        p4b_bin = repo_root / "P4B-Translator" / "build-host" / "backends" / "verify" / "p4c-translator"
        self.assertTrue(p4b_bin.exists())

        with tempfile.TemporaryDirectory() as td:
            outp = compile_spec_text(
                spec_text=spec.read_text(encoding="utf-8"),
                backend="boogie",
                out=Path(td) / "out.bpl",
                base_dir=spec.parent,
                p4b_bin=p4b_bin,
                boogie_harness="sequential",
                pipeline_two_stage=False,
                honor_spec_max_steps=True,
                emit_reg_debug=False,
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        direct = (
            "if (!((dsl_phase < 3))) {\n"
            "    assert !((flowrest_Ingress_reg_flow_duration__wrote_any && "
            "(flowrest_Ingress_reg_flow_duration__last_value == 0bv32)));\n"
            "  }"
        )
        self.assertIn("// Global assertions (direct guarded checks)", text)
        self.assertIn(direct, text)
        self.assertEqual(text.count("flowrest_Ingress_reg_flow_duration__last_value == 0bv32"), 1)
        self.assertNotIn("// Global assertions (accumulated into procurator_bad)", text)
        self.assertNotIn("assert !procurator_bad;", text)
        self.assertNotIn(
            "if (flowrest_Ingress_reg_flow_duration__wrote_any && "
            "flowrest_Ingress_reg_flow_duration__last_value == 0bv32) {",
            text,
        )
        self.assertNotIn("assert false;", text)
        self.assertNotIn("assume false;", text)

    def test_conjunctive_guarded_register_mirror_assert_gets_dsl_direct_check(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        spec = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "spec"
            / "bench"
            / "external_flowrest_per_flow_flow_duration_wraparound_direct.prop"
        )
        self.assertTrue(spec.exists())
        p4b_bin = repo_root / "P4B-Translator" / "build-host" / "backends" / "verify" / "p4c-translator"
        self.assertTrue(p4b_bin.exists())

        with tempfile.TemporaryDirectory() as td:
            outp = compile_spec_text(
                spec_text=spec.read_text(encoding="utf-8"),
                backend="boogie",
                out=Path(td) / "out.bpl",
                base_dir=spec.parent,
                p4b_bin=p4b_bin,
                boogie_harness="sequential",
                pipeline_two_stage=False,
                honor_spec_max_steps=True,
                emit_reg_debug=False,
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        self.assertIn("// Global assertions (direct guarded checks)", text)
        self.assertIn("if (((flowrest_meta.is_first != 1bv1) && (flowrest_meta.iat != 0bv32))) {", text)
        self.assertIn(
            "assert !((flowrest_Ingress_reg_flow_duration__wrote_any && "
            "(flowrest_Ingress_reg_flow_duration__last_value == 0bv32)));",
            text,
        )
        self.assertNotIn("// Global assertions (accumulated into procurator_bad)", text)
        self.assertNotIn("assert !procurator_bad;", text)

    def test_bounded_direct_check_preserves_accumulated_fallback_for_other_asserts(self) -> None:
        raw_bpl = self._native_register_bpl()
        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            raw_path = td_path / "node.bpl"
            raw_path.write_text(raw_bpl, encoding="utf-8")
            spec = f"""
import s1 from "{raw_path.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
}}
global {{
  queue_capacity = 1;
  deterministic_scheduler = true;
  max_steps = 2;
  int phase = 0;
  assert {{
    !(s1_my_reg__wrote_any && s1_my_reg__last_value == 0 && phase == 0);
    true;
  }};
}}
"""
            outp = compile_spec_text(
                spec_text=spec,
                backend="boogie",
                out=td_path / "out.bpl",
                boogie_harness="sequential",
                pipeline_two_stage=False,
                honor_spec_max_steps=True,
                emit_reg_debug=False,
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        self.assertIn("// Global assertions (direct guarded checks)", text)
        self.assertIn(
            "assert !((s1_my_reg__wrote_any && (s1_my_reg__last_value == 0bv32)));",
            text,
        )
        self.assertIn("// Global assertions (accumulated into procurator_bad)", text)
        self.assertIn("if (!(true)) { procurator_bad := true; }", text)
        self.assertIn("assert !procurator_bad;", text)

    def test_fail_fast_can_skip_duplicate_global_assert_when_opted_in(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        spec = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "spec"
            / "bench"
            / "external_flowrest_per_flow_pkt_len_total_wraparound_direct.prop"
        )
        self.assertTrue(spec.exists())
        p4b_bin = repo_root / "P4B-Translator" / "build-host" / "backends" / "verify" / "p4c-translator"
        self.assertTrue(p4b_bin.exists())

        with tempfile.TemporaryDirectory() as td:
            outp = compile_spec_text(
                spec_text=spec.read_text(encoding="utf-8"),
                backend="boogie",
                out=Path(td) / "out.bpl",
                base_dir=spec.parent,
                p4b_bin=p4b_bin,
                boogie_harness="sequential",
                pipeline_two_stage=False,
                honor_spec_max_steps=True,
                emit_reg_debug=False,
                skip_duplicated_fail_fast_global_asserts=True,
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        self.assertIn(
            "if (flowrest_Ingress_reg_pkt_len_total__wrote_any && "
            "flowrest_Ingress_reg_pkt_len_total__last_value == 0bv16) {",
            text,
        )
        self.assertIn("assert false;", text)
        self.assertIn("assume false;", text)
        self.assertNotIn("// Global assertions (accumulated into procurator_bad)", text)
        self.assertNotIn("assert !procurator_bad;", text)

    def test_skip_duplicate_assert_keeps_guarded_dsl_direct_check_when_p4b_not_inferred(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        spec = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "spec"
            / "bench"
            / "external_flowrest_per_flow_pkt_len_total_wraparound.prop"
        )
        self.assertTrue(spec.exists())
        p4b_bin = repo_root / "P4B-Translator" / "build-host" / "backends" / "verify" / "p4c-translator"
        self.assertTrue(p4b_bin.exists())

        with tempfile.TemporaryDirectory() as td:
            outp = compile_spec_text(
                spec_text=spec.read_text(encoding="utf-8"),
                backend="boogie",
                out=Path(td) / "out.bpl",
                base_dir=spec.parent,
                p4b_bin=p4b_bin,
                boogie_harness="sequential",
                pipeline_two_stage=False,
                honor_spec_max_steps=True,
                emit_reg_debug=False,
                skip_duplicated_fail_fast_global_asserts=True,
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        self.assertNotIn(
            "if (flowrest_Ingress_reg_pkt_len_total__wrote_any && "
            "flowrest_Ingress_reg_pkt_len_total__last_value == 0bv16) {",
            text,
        )
        self.assertIn("// Global assertions (direct guarded checks)", text)
        self.assertNotIn("// Global assertions (accumulated into procurator_bad)", text)
        self.assertNotIn("assert !procurator_bad;", text)

    def test_required_env_packet_vars_are_kept_without_widening_p4_slice(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        spec = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "spec"
            / "bench"
            / "external_etc_noms2024_pkt_len_total_wraparound_slot0.prop"
        )
        self.assertTrue(spec.exists())
        p4b_bin = repo_root / "P4B-Translator" / "build-host" / "backends" / "verify" / "p4c-translator"
        self.assertTrue(p4b_bin.exists())

        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            outp = compile_spec_text(
                spec_text=spec.read_text(encoding="utf-8"),
                backend="boogie",
                out=td_path / "out.bpl",
                base_dir=spec.parent,
                p4b_bin=p4b_bin,
                work_dir=td_path / "work",
                boogie_harness="sequential",
                pipeline_two_stage=False,
                honor_spec_max_steps=True,
                emit_reg_debug=False,
                keep_control_seeds=False,
                skip_duplicated_fail_fast_global_asserts=True,
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")
            raw_text = (td_path / "work" / "etc.raw.bpl").read_text(encoding="utf-8", errors="replace")

        # Env/assume fields are required by the harness and must remain declared/havoced.
        self.assertIn("var hdr.ipv4.total_len:bv16;", raw_text)
        self.assertIn("var ig_prsr_md.global_tstamp:bv48;", raw_text)
        self.assertIn("havoc etc_hdr.ipv4.total_len;", text)
        self.assertIn("havoc etc_ig_prsr_md.global_tstamp;", text)
        self.assertIn("assume etc_Ingress_reg_pkt_len_total[0bv11] == 0bv16;", text)
        self.assertIn("assume etc_Ingress_reg_status[0bv11] == 0bv1;", text)
        self.assertIn("assume etc_Ingress_reg_flow_ID[0bv11] == 0bv32;", text)
        self.assertNotIn("forall i:bv11 :: etc_Ingress_reg_pkt_len_total[i] == 0bv16", text)
        self.assertNotIn("forall i:bv11 :: etc_Ingress_reg_status[i] == 0bv1", text)
        self.assertNotIn("forall i:bv11 :: etc_Ingress_reg_flow_ID[i] == 0bv32", text)

        # They must not be promoted to slicing roots; otherwise unrelated feature
        # updates flow back into the IR slice and the ETC model balloons again.
        self.assertIn("procedure {:inline 1} Ingress_read_pkt_len_total.apply", raw_text)
        self.assertIn("Ingress_reg_pkt_len_total.write", raw_text)
        for name in [
            "Ingress_read_pkt_count.apply",
            "Ingress_read_pkt_len_max.apply",
            "Ingress_read_time_last_pkt.apply",
            "Ingress_read_flow_iat_min.apply",
            "Ingress_read_flow_iat_max.apply",
            "Ingress_code_table0.apply",
            "Ingress_voting_table.apply",
        ]:
            self.assertNotIn(name, raw_text)

    def test_dslc_owns_control_seeds_for_p4b_slicing(self) -> None:
        raw_bpl = """\
type Ref;
var p4b_recirculate:bool;
var standard_metadata.egress_port:bv9;
var hdr.ipv4:Ref;
var hdr.ipv4.ttl:bv8;
var isValid:[Ref]bool;

procedure mainProcedure() returns()
  modifies p4b_recirculate;
{
}
"""

        seen: dict[str, object] = {}

        class FakeP4BTranslator:
            def __init__(self, _p4b_bin: str):
                pass

            def compile_to_bpl(
                self,
                _p4_path: str,
                out_bpl: str,
                _entries_path: str | None,
                out_meta: str | None = None,
                **kwargs: object,
            ) -> None:
                seen.update(kwargs)
                Path(out_bpl).write_text(raw_bpl, encoding="utf-8")
                if out_meta:
                    Path(out_meta).write_text("{}", encoding="utf-8")

        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            p4 = td_path / "prog.p4"
            p4.write_text("#include <core.p4>\n", encoding="utf-8")

            spec = f"""
import s1 from "{p4.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
}}
global {{
  queue_capacity = 1;
  assert {{ s1_hdr.ipv4.ttl == s1_hdr.ipv4.ttl; }}
  ;
}}
"""
            with mock.patch("dslc.backends.boogie.compiler.P4BTranslator", FakeP4BTranslator):
                compile_spec_text(
                    spec_text=spec,
                    backend="boogie",
                    out=td_path / "out.bpl",
                    p4b_bin=Path("/fake/p4c-translator"),
                    boogie_harness="sequential",
                    pipeline_two_stage=False,
                    emit_reg_debug=False,
                    keep_control_seeds=True,
                )

        self.assertFalse(seen.get("keep_control_seeds"))
        slicing_vars = set(seen.get("slicing_vars") or [])
        self.assertIn("p4b_recirculate", slicing_vars)
        self.assertIn("hdr.ipv4.ttl", slicing_vars)

    def test_host_env_fields_remain_declared_under_slicing(self) -> None:
        # Regression: host.env assignments may reference packet fields that are not
        # property seeds. These fields must still be declared in the merged harness.
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
host io {{
  connect s1;
  env {{
    hdr.ethernet.etherType = 2048;
    hdr.ipv4.dstAddr = 1;
  }}
}}
node s1 {{
  external_input = false;
}}
global {{
  env_thread = false;
  host_eager = true;
  queue_capacity = 1;
  assert {{ true; }};
}}
"""
        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            outp = compile_spec_text(
                spec_text=spec,
                backend="boogie",
                out=out_bpl,
                boogie_harness="sequential",
                pipeline_two_stage=False,
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        self.assertRegex(text, r"\bvar\s+io_hdr\.ethernet\.etherType\s*:\s*bv16;")
        self.assertRegex(text, r"\bvar\s+io_hdr\.ipv4\.dstAddr\s*:\s*[A-Za-z0-9_\.]+;")
        self.assertRegex(text, r"\bio_hdr\.ethernet\.etherType\s*:=\s*2048bv16;")
        self.assertRegex(text, r"\bio_hdr\.ipv4\.dstAddr\s*:=\s*1bv32;")

    def test_env_top_level_const_assign_skips_redundant_havoc_for_external_node(self) -> None:
        # Optimization/soundness: when env inject logic always overwrites a packet field with
        # a top-level literal assignment, skip the redundant pre-assignment havoc.
        # Conditional assignments must still keep havoc.
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
  env {{
    hdr.ethernet.etherType = 2048;
    if (phase == 0) {{
      hdr.ipv4.dstAddr = 1;
    }}
  }}
}}
global {{
  int phase = 0;
  queue_capacity = 1;
  assert {{ true; }};
}}
"""
        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            outp = compile_spec_text(
                spec_text=spec,
                backend="boogie",
                out=out_bpl,
                boogie_harness="sequential",
                pipeline_two_stage=False,
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        self.assertNotIn("havoc s1_hdr.ethernet.etherType;", text)
        self.assertIn("havoc s1_hdr.ipv4.dstAddr;", text)
        self.assertIn("s1_hdr.ethernet.etherType := 2048bv16;", text)

    def test_host_env_top_level_const_assign_skips_redundant_havoc(self) -> None:
        # Same optimization for host-driven packet construction (host -> node injection).
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
host io {{
  connect s1;
  env {{
    hdr.ethernet.etherType = 2048;
    if (phase == 0) {{
      hdr.ipv4.dstAddr = 1;
    }}
  }}
}}
node s1 {{
  external_input = false;
}}
global {{
  env_thread = false;
  host_eager = true;
  int phase = 0;
  queue_capacity = 1;
  assert {{ true; }};
}}
"""
        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            outp = compile_spec_text(
                spec_text=spec,
                backend="boogie",
                out=out_bpl,
                boogie_harness="sequential",
                pipeline_two_stage=False,
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        self.assertNotIn("havoc io_hdr.ethernet.etherType;", text)
        self.assertIn("havoc io_hdr.ipv4.dstAddr;", text)
        self.assertIn("io_hdr.ethernet.etherType := 2048bv16;", text)

    def test_env_top_level_nonconst_assign_still_skips_redundant_havoc(self) -> None:
        # Optimization extension: top-level unconditional overwrite does not require
        # literal RHS; old value is irrelevant if RHS does not self-reference LHS.
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
  env {{
    hdr.ipv4.dstAddr = phase;
  }}
}}
global {{
  int phase = 1;
  queue_capacity = 1;
  assert {{ true; }};
}}
"""
        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            outp = compile_spec_text(
                spec_text=spec,
                backend="boogie",
                out=out_bpl,
                boogie_harness="sequential",
                pipeline_two_stage=False,
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        self.assertNotIn("havoc s1_hdr.ipv4.dstAddr;", text)
        self.assertIn("s1_hdr.ipv4.dstAddr := dsl_phase;", text)

    def test_env_top_level_self_ref_assign_keeps_havoc(self) -> None:
        # Soundness guard: self-referential updates (`x := x + ...`) still need initial havoc.
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        bpl = repo_root / "Procurator" / "argo" / "code" / "Translator" / "feature-testcases" / "bool" / "out.bpl"
        self.assertTrue(bpl.exists())

        spec = f"""
import s1 from "{bpl.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
  env {{
    hdr.ipv4.dstAddr += 1;
  }}
}}
global {{
  queue_capacity = 1;
  assert {{ true; }};
}}
"""
        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            outp = compile_spec_text(
                spec_text=spec,
                backend="boogie",
                out=out_bpl,
                boogie_harness="sequential",
                pipeline_two_stage=False,
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        self.assertIn("havoc s1_hdr.ipv4.dstAddr;", text)
        self.assertIn("s1_hdr.ipv4.dstAddr := s1_hdr.ipv4.dstAddr + 1bv32;", text)


if __name__ == "__main__":
    unittest.main()
