import unittest

from dslc.analysis.wraparound_candidates import infer_wraparound_candidates


class TestWraparoundCandidateGating(unittest.TestCase):
    def test_require_meta_step_filters_global_assert_candidates(self) -> None:
        # Minimal spec: global assert references a reg slot, so the "global_asserts" inference triggers.
        spec_text = """
import s1 from "x.p4";
topology {}
global {
  assert { s1_sequence_reg_0[0] >= s1_sequence_reg_0[0]; };
}
"""

        # Minimal Boogie text: types are only used when inferring from meta updates; keep empty here.
        bpl_text = ""

        # Empty meta: no monotone step info available.
        cands = infer_wraparound_candidates(
            spec_text=spec_text,
            bpl_text=bpl_text,
            meta_by_node={},
            require_meta_step_for_global_asserts=True,
        )
        self.assertEqual(cands, [])

        # If we do not require meta, we accept the "global_asserts" candidate (legacy/force mode).
        cands2 = infer_wraparound_candidates(
            spec_text=spec_text,
            bpl_text=bpl_text,
            meta_by_node={},
            require_meta_step_for_global_asserts=False,
        )
        self.assertEqual(len(cands2), 1)
        self.assertEqual(cands2[0].reason, "global_asserts")

    def test_meta_candidates_selected_via_driver_dependency(self) -> None:
        """
        Regression: functional wraparound specs may not mention the counter register
        in the global assertion (it is a driver). We should still infer candidates
        when the counter influences an observed variable in Boogie.
        """

        spec_text = """
import leaf from "dummy.p4";
topology {}
global {
  assert { leaf_hdr_eg.frequency_hdr.frequency != 0; };
}
"""

        # Minimal Boogie program: observed var depends on the counter reg via a read.
        bpl_text = "\n".join(
            [
                "var leaf_hdr_eg.frequency_hdr.frequency: bv32;",
                "var leaf_cache_frequency_reg: [bv32]bv32;",
                "procedure LeafIngress() {",
                "  leaf_hdr_eg.frequency_hdr.frequency := leaf_cache_frequency_reg[0bv32];",
                "}",
            ]
        )

        meta_by_node = {
            "leaf": {
                "wraparound": {
                    "updates": [
                        {
                            "reg": "cache_frequency_reg",
                            "value_var": "cache_frequency_md.frequency",
                            "op": "add",
                            "delta_is_const": True,
                            "delta_const": 1,
                            "idx_const": 7,
                        }
                    ]
                }
            }
        }

        cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=bpl_text, meta_by_node=meta_by_node)
        self.assertTrue(cands, "should infer a wraparound candidate from meta updates")
        self.assertEqual(cands[0].pump_reg, "leaf_cache_frequency_reg")

    def test_meta_index_expr_derived_from_bpl_action_and_env_literals(self) -> None:
        """
        Flowrest/TNA reports RegisterAction indices as `meta.register_index`.
        That variable is computed inside the P4 pass, while wraparound
        fast-forwarding happens before the scheduler loop.  Candidate inference
        must recover the stable hash expression over env literals instead of
        certifying a stale pre-loop global.
        """

        spec_text = """
import flowrest from "flowrest.p4";
topology {}
global {
  assert { flowrest_meta.pkt_count != 1; };
}
"""

        bpl_text = "\n".join(
            [
                "var flowrest_hdr.ipv4.src_addr: bv32;",
                "var flowrest_hdr.ipv4.dst_addr: bv32;",
                "var flowrest_hdr.ipv4.protocol: bv8;",
                "var flowrest_hdr.tcp.src_port: bv16;",
                "var flowrest_hdr.tcp.dst_port: bv16;",
                "var flowrest_meta.hdr_srcport: bv16;",
                "var flowrest_meta.hdr_dstport: bv16;",
                "var flowrest_meta.register_index: bv16;",
                "var flowrest_meta.pkt_count: bv8;",
                "var flowrest___ra_ret_Ingress_read_pkt_count: bv8;",
                "var flowrest_Ingress_reg_pkt_count: [bv16]bv8;",
                "function flowrest_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8(",
                "  flowrest_a:bv32, flowrest_b:bv32, flowrest_c:bv16, flowrest_d:bv16, flowrest_e:bv8",
                ") returns(bv16);",
                "var io_hdr.ipv4.src_addr: bv32;",
                "var io_hdr.ipv4.dst_addr: bv32;",
                "var io_hdr.ipv4.protocol: bv8;",
                "var io_hdr.tcp.src_port: bv16;",
                "var io_hdr.tcp.dst_port: bv16;",
                "assume (io_hdr.ipv4.src_addr == 167772161bv32);",
                "assume (io_hdr.ipv4.dst_addr == 167772162bv32);",
                "assume (io_hdr.tcp.src_port == 1234bv16);",
                "assume (io_hdr.tcp.dst_port == 443bv16);",
                "assume (io_hdr.ipv4.protocol == 6bv8);",
                "procedure mainProcedure() {",
                "  flowrest_hdr.ipv4.src_addr := io_hdr.ipv4.src_addr;",
                "  flowrest_hdr.ipv4.dst_addr := io_hdr.ipv4.dst_addr;",
                "  flowrest_hdr.ipv4.protocol := io_hdr.ipv4.protocol;",
                "  flowrest_hdr.tcp.src_port := io_hdr.tcp.src_port;",
                "  flowrest_hdr.tcp.dst_port := io_hdr.tcp.dst_port;",
                "}",
                "procedure flowrest_Ingress() {",
                "  flowrest_meta.hdr_srcport := flowrest_hdr.tcp.src_port;",
                "  flowrest_meta.hdr_srcport := flowrest_meta.hdr_srcport;",
                "  flowrest_meta.hdr_dstport := flowrest_hdr.tcp.dst_port;",
                "  call flowrest_Ingress_get_register_index(flowrest_meta.hdr_srcport, flowrest_meta.hdr_dstport);",
                "  call flowrest___ra_ret_Ingress_read_pkt_count := flowrest_Ingress_read_pkt_count.apply(flowrest_Ingress_reg_pkt_count[flowrest_meta.register_index]);",
                "  flowrest_meta.pkt_count := flowrest___ra_ret_Ingress_read_pkt_count;",
                "}",
                "procedure {:inline 1} flowrest_Ingress_get_register_index(flowrest_srcPort_2:bv16, flowrest_dstPort_2:bv16)",
                "  modifies flowrest_meta.register_index;",
                "{",
                "  flowrest_meta.register_index := flowrest_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8(",
                "    flowrest_hdr.ipv4.src_addr, flowrest_hdr.ipv4.dst_addr, flowrest_srcPort_2, flowrest_dstPort_2, flowrest_hdr.ipv4.protocol);",
                "}",
            ]
        )

        meta_by_node = {
            "flowrest": {
                "wraparound": {
                    "updates": [
                        {
                            "reg": "Ingress_reg_pkt_count",
                            "value_var": "__ra_ret_Ingress_read_pkt_count",
                            "op": "add",
                            "delta_is_const": True,
                            "delta_const": 1,
                            "idx_expr": "meta.register_index",
                        }
                    ]
                }
            }
        }

        cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=bpl_text, meta_by_node=meta_by_node)
        self.assertTrue(cands, "should infer Flowrest's pkt_count register as a candidate")
        cand = cands[0]
        self.assertEqual(cand.pump_reg, "flowrest_Ingress_reg_pkt_count")
        self.assertIsNone(cand.index_value)
        self.assertIsNotNone(cand.index_expr)
        assert cand.index_expr is not None
        self.assertIn("flowrest_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8", cand.index_expr)
        self.assertIn("167772161bv32", cand.index_expr)
        self.assertIn("167772162bv32", cand.index_expr)
        self.assertIn("1234bv16", cand.index_expr)
        self.assertIn("443bv16", cand.index_expr)
        self.assertIn("6bv8", cand.index_expr)
        self.assertNotIn("flowrest_meta.register_index", cand.index_expr)

    def test_meta_index_expr_prefers_structured_p4b_definition(self) -> None:
        """
        P4B should export callsite-specialized index definitions, so candidate
        inference does not need to recover action parameters from Boogie
        procedure bodies for Flowrest/TNA hash indices.
        """

        spec_text = """
import flowrest from "flowrest.p4";
topology {}
global {
  assert { flowrest_meta.pkt_count != 1; };
}
"""

        bpl_text = "\n".join(
            [
                "var flowrest_hdr.ipv4.src_addr: bv32;",
                "var flowrest_hdr.ipv4.dst_addr: bv32;",
                "var flowrest_hdr.ipv4.protocol: bv8;",
                "var flowrest_meta.hdr_srcport: bv16;",
                "var flowrest_meta.hdr_dstport: bv16;",
                "var flowrest_meta.register_index: bv16;",
                "var flowrest_meta.pkt_count: bv8;",
                "var flowrest___ra_ret_Ingress_read_pkt_count: bv8;",
                "var flowrest_Ingress_reg_pkt_count: [bv16]bv8;",
                "function flowrest_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8(",
                "  flowrest_a:bv32, flowrest_b:bv32, flowrest_c:bv16, flowrest_d:bv16, flowrest_e:bv8",
                ") returns(bv16);",
                "assume (flowrest_hdr.ipv4.src_addr == 167772161bv32);",
                "assume (flowrest_hdr.ipv4.dst_addr == 167772162bv32);",
                "assume (flowrest_hdr.ipv4.protocol == 6bv8);",
                "assume (flowrest_meta.hdr_srcport == 1234bv16);",
                "assume (flowrest_meta.hdr_dstport == 443bv16);",
                "procedure flowrest_Ingress() {",
                "  flowrest_meta.pkt_count := flowrest___ra_ret_Ingress_read_pkt_count;",
                "}",
                # No `flowrest_Ingress_get_register_index` procedure appears here.
            ]
        )

        meta_by_node = {
            "flowrest": {
                "wraparound": {
                    "index_definitions": [
                        {
                            "target_var": "meta.register_index",
                            "expr": (
                                "Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8("
                                "hdr.ipv4.src_addr, hdr.ipv4.dst_addr, "
                                "meta.hdr_srcport, meta.hdr_dstport, hdr.ipv4.protocol)"
                            ),
                            "deps": [
                                "hdr.ipv4.src_addr",
                                "hdr.ipv4.dst_addr",
                                "meta.hdr_srcport",
                                "meta.hdr_dstport",
                                "hdr.ipv4.protocol",
                            ],
                            "context": "Ingress.get_register_index",
                        }
                    ],
                    "updates": [
                        {
                            "reg": "Ingress_reg_pkt_count",
                            "value_var": "__ra_ret_Ingress_read_pkt_count",
                            "op": "add",
                            "delta_is_const": True,
                            "delta_const": 1,
                            "idx_expr": "meta.register_index",
                        }
                    ],
                }
            }
        }

        cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=bpl_text, meta_by_node=meta_by_node)
        self.assertTrue(cands, "should infer Flowrest's pkt_count register as a candidate")
        cand = cands[0]
        self.assertEqual(cand.pump_reg, "flowrest_Ingress_reg_pkt_count")
        self.assertIsNone(cand.index_value)
        self.assertEqual(
            cand.index_expr,
            (
                "flowrest_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8("
                "167772161bv32, 167772162bv32, 1234bv16, 443bv16, 6bv8)"
            ),
        )
        self.assertNotIn("flowrest_meta.register_index", cand.proj_vars)

    def test_meta_index_definition_matches_prefixed_suffixed_name(self) -> None:
        """
        P4B may export local aliases like counter_pos while Boogie globals are
        node-prefixed and suffixed as flowdos_counter_pos_0.
        """

        from dslc.analysis.wraparound_bpl_index import _derive_index_expr_from_meta_definition

        bpl_text = "\n".join(
            [
                "var flowdos_counter_pos_0: bv32;",
                "var flowdos_hdr.ipv4.srcAddr: bv32;",
                "function flowdos_hash__crc16$bv32$bv32$bv32(",
                "  flowdos_a:bv32, flowdos_b:bv32, flowdos_c:bv32",
                ") returns(bv32);",
                "assume (flowdos_hdr.ipv4.srcAddr == 167772161bv32);",
            ]
        )
        meta = {
            "wraparound": {
                "index_definitions": [
                    {
                        "target_var": "counter_pos",
                        "expr": (
                            "hash__crc16$bv32$int$bv32("
                            "0bv32, hdr.ipv4.srcAddr, 4096bv32)"
                        ),
                        "deps": ["hdr.ipv4.srcAddr"],
                    }
                ]
            }
        }
        expr = _derive_index_expr_from_meta_definition(
            "counter_pos",
            node="flowdos",
            meta=meta,
            bpl_text=bpl_text,
            var_types={
                "flowdos_counter_pos_0": "bv32",
                "flowdos_hdr.ipv4.srcAddr": "bv32",
            },
        )
        self.assertEqual(
            expr,
            "flowdos_hash__crc16$bv32$bv32$bv32(0bv32, 167772161bv32, 4096bv32)",
        )

    def test_ambiguous_meta_index_definition_is_not_used_for_fast_forward(self) -> None:
        from dslc.analysis.wraparound_bpl_index import _derive_index_expr_from_meta_definition

        bpl_text = "\n".join(
            [
                "var flowdos_counter_pos_0: bv32;",
                "var flowdos_hdr.ipv4.srcAddr: bv32;",
                "function flowdos_hash__crc16$bv32$bv32$bv32(",
                "  flowdos_a:bv32, flowdos_b:bv32, flowdos_c:bv32",
                ") returns(bv32);",
                "assume (flowdos_hdr.ipv4.srcAddr == 167772161bv32);",
            ]
        )
        meta = {
            "wraparound": {
                "index_definitions": [
                    {
                        "target_var": "counter_pos",
                        "expr": "hash__crc16$bv32$int$bv32(0bv32, hdr.ipv4.srcAddr, 4096bv32)",
                        "deps": ["hdr.ipv4.srcAddr"],
                        "ambiguous": True,
                    }
                ]
            }
        }
        expr = _derive_index_expr_from_meta_definition(
            "counter_pos",
            node="flowdos",
            meta=meta,
            bpl_text=bpl_text,
            var_types={
                "flowdos_counter_pos_0": "bv32",
                "flowdos_hdr.ipv4.srcAddr": "bv32",
            },
        )
        self.assertIsNone(expr)

    def test_meta_update_delta_recovers_env_fixed_header_value(self) -> None:
        """
        Flowrest/ETC feature counters often update as `x += hdr.ipv4.total_len`.
        P4B reports the additive shape but cannot mark the P4-local delta as a
        literal. Candidate inference should recover the env-fixed Boogie
        literal and use it as the wraparound step.
        """

        spec_text = """
import flowrest from "flowrest.p4";
topology {}
global {
  assert {
    !(flowrest_Ingress_reg_pkt_len_total__wrote_index0
      && flowrest_Ingress_reg_pkt_len_total__last0_value == 0);
  };
}
"""

        bpl_text = "\n".join(
            [
                "var flowrest_hdr.ipv4.total_len: bv16;",
                "var flowrest_meta.register_index: bv16;",
                "var flowrest___ra_ret_Ingress_read_pkt_len_total: bv16;",
                "var flowrest_Ingress_reg_pkt_len_total: [bv16]bv16;",
                "var flowrest_Ingress_reg_pkt_len_total__wrote_index0: bool;",
                "var flowrest_Ingress_reg_pkt_len_total__last0_value: bv16;",
                "assume (flowrest_hdr.ipv4.total_len == 32768bv16);",
                "procedure {:inline 1} flowrest_Ingress_read_pkt_len_total.apply(flowrest_pkt_len_total_in:bv16, flowrest_output_in:bv16) returns (flowrest_pkt_len_total_out:bv16, flowrest_output_out:bv16)",
                "{",
                "  var flowrest_pkt_len_total:bv16;",
                "  flowrest_pkt_len_total := flowrest_pkt_len_total_in;",
                "  flowrest_pkt_len_total := add.bv16(flowrest_pkt_len_total, flowrest_hdr.ipv4.total_len);",
                "  flowrest_pkt_len_total_out := flowrest_pkt_len_total;",
                "}",
                "procedure flowrest_Ingress() {",
                "  flowrest___ra_ret_Ingress_read_pkt_len_total := flowrest_Ingress_reg_pkt_len_total[flowrest_meta.register_index];",
                "}",
            ]
        )

        meta_by_node = {
            "flowrest": {
                "wraparound": {
                    "updates": [
                        {
                            "reg": "Ingress_reg_pkt_len_total",
                            "value_var": "__ra_ret_Ingress_read_pkt_len_total",
                            "op": "add",
                            "delta_is_const": False,
                            "delta_const": "",
                            "idx_const": 0,
                            "context": "Ingress_read_pkt_len_total",
                            "value_width": 16,
                        }
                    ]
                }
            }
        }

        cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=bpl_text, meta_by_node=meta_by_node)
        self.assertTrue(cands, "should infer feature counter candidate with env-fixed delta")
        self.assertEqual(cands[0].pump_reg, "flowrest_Ingress_reg_pkt_len_total")
        self.assertEqual(cands[0].index_value, 0)
        self.assertIsNone(cands[0].index_expr)
        self.assertEqual(cands[0].step_delta, 32768)

    def test_meta_index_expr_not_derived_when_constant_source_has_unknown_write(self) -> None:
        spec_text = """
import flowrest from "flowrest.p4";
topology {}
global {
  assert { flowrest_meta.pkt_count != 1; };
}
"""

        bpl_text = "\n".join(
            [
                "var flowrest_hdr.tcp.src_port: bv16;",
                "var flowrest_meta.hdr_srcport: bv16;",
                "var flowrest_meta.register_index: bv16;",
                "var flowrest_meta.pkt_count: bv8;",
                "var flowrest___ra_ret_Ingress_read_pkt_count: bv8;",
                "var flowrest_Ingress_reg_pkt_count: [bv16]bv8;",
                "var flowrest_dynamic_port: bv16;",
                "function flowrest_Ingress_idx_calc.get$bv16(flowrest_a:bv16) returns(bv16);",
                "assume (flowrest_hdr.tcp.src_port == 1234bv16);",
                "procedure flowrest_Ingress() {",
                "  flowrest_meta.hdr_srcport := flowrest_hdr.tcp.src_port;",
                "  flowrest_meta.hdr_srcport := flowrest_dynamic_port;",
                "  call flowrest_Ingress_get_register_index(flowrest_meta.hdr_srcport);",
                "  call flowrest___ra_ret_Ingress_read_pkt_count := flowrest_Ingress_read_pkt_count.apply(flowrest_Ingress_reg_pkt_count[flowrest_meta.register_index]);",
                "  flowrest_meta.pkt_count := flowrest___ra_ret_Ingress_read_pkt_count;",
                "}",
                "procedure {:inline 1} flowrest_Ingress_get_register_index(flowrest_srcPort_2:bv16)",
                "  modifies flowrest_meta.register_index;",
                "{",
                "  flowrest_meta.register_index := flowrest_Ingress_idx_calc.get$bv16(flowrest_srcPort_2);",
                "}",
            ]
        )

        meta_by_node = {
            "flowrest": {
                "wraparound": {
                    "updates": [
                        {
                            "reg": "Ingress_reg_pkt_count",
                            "value_var": "__ra_ret_Ingress_read_pkt_count",
                            "op": "add",
                            "delta_is_const": True,
                            "delta_const": 1,
                            "idx_expr": "meta.register_index",
                        }
                    ]
                }
            }
        }

        cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=bpl_text, meta_by_node=meta_by_node)
        self.assertTrue(cands)
        self.assertEqual(cands[0].index_expr, "flowrest_meta.register_index")

    def test_node_assume_constant_resolves_meta_register_index(self) -> None:
        spec_text = """
import etc from "etc.p4";
topology {}
node etc {
  assume {
    meta.register_index == 0;
  };
}
global {
  assert {
    !(etc_Ingress_reg_pkt_count__wrote_any
      && etc_Ingress_reg_pkt_count__last_value == 0);
  };
}
"""

        bpl_text = "\n".join(
            [
                "var procurator_phase: int;",
                "var etc_meta.register_index: bv11;",
                "var etc___ra_ret_Ingress_read_pkt_count: bv8;",
                "var etc_Ingress_reg_pkt_count: [bv11]bv8;",
                "var etc_Ingress_reg_pkt_count__wrote_any: bool;",
                "var etc_Ingress_reg_pkt_count__last_value: bv8;",
            ]
        )
        meta_by_node = {
            "etc": {
                "wraparound": {
                    "updates": [
                        {
                            "reg": "Ingress_reg_pkt_count",
                            "value_var": "__ra_ret_Ingress_read_pkt_count",
                            "op": "add",
                            "delta_is_const": True,
                            "delta_const": 1,
                            "idx_expr": "meta.register_index",
                        }
                    ]
                }
            }
        }

        cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=bpl_text, meta_by_node=meta_by_node)

        self.assertTrue(cands)
        self.assertEqual(cands[0].pump_reg, "etc_Ingress_reg_pkt_count")
        self.assertEqual(cands[0].index_value, 0)
        self.assertIsNone(cands[0].index_expr)

    def test_node_assume_does_not_override_p4_computed_register_index(self) -> None:
        spec_text = """
import etc from "etc.p4";
topology {}
node etc {
  assume {
    meta.register_index == 0;
  };
}
global {
  assert {
    !(etc_Ingress_reg_pkt_count__wrote_index0
      && etc_Ingress_reg_pkt_count__last0_value == 0);
  };
}
"""

        bpl_text = "\n".join(
            [
                "var etc_hdr.ipv4.src_addr: bv32;",
                "var etc_hdr.ipv4.dst_addr: bv32;",
                "var etc_hdr.ipv4.protocol: bv8;",
                "var etc_hdr.tcp.src_port: bv16;",
                "var etc_hdr.tcp.dst_port: bv16;",
                "var etc_meta.hdr_srcport: bv16;",
                "var etc_meta.hdr_dstport: bv16;",
                "var etc_meta.register_index: bv11;",
                "var etc___ra_ret_Ingress_read_pkt_count: bv8;",
                "var etc_Ingress_reg_pkt_count: [bv11]bv8;",
                "var etc_Ingress_reg_pkt_count__wrote_index0: bool;",
                "var etc_Ingress_reg_pkt_count__last0_value: bv8;",
                "function etc_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8(",
                "  etc_a:bv32, etc_b:bv32, etc_c:bv16, etc_d:bv16, etc_e:bv8",
                ") returns(bv11);",
                "assume (etc_hdr.ipv4.src_addr == 167772161bv32);",
                "assume (etc_hdr.ipv4.dst_addr == 167772162bv32);",
                "assume (etc_hdr.ipv4.protocol == 6bv8);",
                "assume (etc_hdr.tcp.src_port == 1234bv16);",
                "assume (etc_hdr.tcp.dst_port == 443bv16);",
                "procedure etc_Ingress() {",
                "  call etc_Ingress_get_register_index(etc_meta.hdr_srcport, etc_meta.hdr_dstport);",
                "  call etc___ra_ret_Ingress_read_pkt_count := etc_Ingress_read_pkt_count.apply(etc_Ingress_reg_pkt_count[etc_meta.register_index]);",
                "}",
                "procedure {:inline 1} etc_Ingress_get_register_index(etc_srcPort_2:bv16, etc_dstPort_2:bv16)",
                "  modifies etc_meta.register_index;",
                "{",
                "  etc_meta.register_index := etc_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8(",
                "    etc_hdr.ipv4.src_addr, etc_hdr.ipv4.dst_addr, etc_srcPort_2, etc_dstPort_2, etc_hdr.ipv4.protocol);",
                "}",
            ]
        )

        meta_by_node = {
            "etc": {
                "wraparound": {
                    "deterministic_definitions": [
                        {
                            "target_var": "meta.hdr_srcport",
                            "expr": "hdr.tcp.src_port",
                            "deps": ["hdr.tcp.src_port"],
                            "context": "parse_tcp",
                        },
                        {
                            "target_var": "meta.hdr_dstport",
                            "expr": "hdr.tcp.dst_port",
                            "deps": ["hdr.tcp.dst_port"],
                            "context": "parse_tcp",
                        },
                    ],
                    "index_definitions": [
                        {
                            "target_var": "meta.register_index",
                            "expr": (
                                "Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8("
                                "hdr.ipv4.src_addr, hdr.ipv4.dst_addr, "
                                "meta.hdr_srcport, meta.hdr_dstport, hdr.ipv4.protocol)"
                            ),
                            "deps": [
                                "hdr.ipv4.src_addr",
                                "hdr.ipv4.dst_addr",
                                "meta.hdr_srcport",
                                "meta.hdr_dstport",
                                "hdr.ipv4.protocol",
                            ],
                        }
                    ],
                    "updates": [
                        {
                            "reg": "Ingress_reg_pkt_count",
                            "value_var": "__ra_ret_Ingress_read_pkt_count",
                            "op": "add",
                            "delta_is_const": True,
                            "delta_const": 1,
                            "idx_expr": "meta.register_index",
                        }
                    ],
                }
            }
        }

        cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=bpl_text, meta_by_node=meta_by_node)

        self.assertTrue(cands)
        self.assertEqual(cands[0].pump_reg, "etc_Ingress_reg_pkt_count")
        self.assertIsNone(cands[0].index_value)
        self.assertEqual(
            cands[0].index_expr,
            (
                "etc_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8("
                "167772161bv32, 167772162bv32, 1234bv16, 443bv16, 6bv8)"
            ),
        )

    def test_index0_seed_uses_singleton_sliced_register_domain(self) -> None:
        spec_text = """
import etc from "etc.p4";
topology {}
global {
  assert {
    !(etc_Ingress_reg_pkt_len_total__wrote_index0
      && etc_Ingress_reg_pkt_len_total__last0_value == 0);
  };
}
"""

        bpl_text = "\n".join(
            [
                "var etc_hdr.ipv4.src_addr: bv32;",
                "var etc_hdr.ipv4.dst_addr: bv32;",
                "var etc_hdr.ipv4.protocol: bv8;",
                "var etc_meta.hdr_srcport: bv16;",
                "var etc_meta.hdr_dstport: bv16;",
                "var etc_meta.register_index: bv11;",
                "var etc___ra_ret_Ingress_read_pkt_len_total: bv16;",
                "var etc_Ingress_reg_pkt_len_total: [bv11]bv16;",
                "var etc_Ingress_reg_pkt_len_total__wrote_index0: bool;",
                "var etc_Ingress_reg_pkt_len_total__last0_value: bv16;",
                "const etc_Ingress_reg_pkt_len_total.size:int;",
                "axiom etc_Ingress_reg_pkt_len_total.size == 1;",
                "function etc_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8(",
                "  etc_a:bv32, etc_b:bv32, etc_c:bv16, etc_d:bv16, etc_e:bv8",
                ") returns(bv11);",
                "assume (etc_hdr.ipv4.src_addr == 167772161bv32);",
                "assume (etc_hdr.ipv4.dst_addr == 167772162bv32);",
                "assume (etc_hdr.ipv4.protocol == 6bv8);",
                "assume (etc_meta.hdr_srcport == 1234bv16);",
                "assume (etc_meta.hdr_dstport == 443bv16);",
            ]
        )

        meta_by_node = {
            "etc": {
                "wraparound": {
                    "index_definitions": [
                        {
                            "target_var": "meta.register_index",
                            "expr": (
                                "Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8("
                                "hdr.ipv4.src_addr, hdr.ipv4.dst_addr, "
                                "meta.hdr_srcport, meta.hdr_dstport, hdr.ipv4.protocol)"
                            ),
                            "deps": [
                                "hdr.ipv4.src_addr",
                                "hdr.ipv4.dst_addr",
                                "meta.hdr_srcport",
                                "meta.hdr_dstport",
                                "hdr.ipv4.protocol",
                            ],
                        }
                    ],
                    "updates": [
                        {
                            "reg": "Ingress_reg_pkt_len_total",
                            "value_var": "__ra_ret_Ingress_read_pkt_len_total",
                            "op": "add",
                            "delta_is_const": True,
                            "delta_const": 32768,
                            "idx_expr": "meta.register_index",
                        }
                    ],
                }
            }
        }

        cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=bpl_text, meta_by_node=meta_by_node)

        self.assertTrue(cands)
        self.assertEqual(cands[0].pump_reg, "etc_Ingress_reg_pkt_len_total")
        self.assertEqual(cands[0].index_value, 0)
        self.assertIsNone(cands[0].index_expr)

    def test_meta_index_expr_not_derived_after_havoc(self) -> None:
        spec_text = """
import flowrest from "flowrest.p4";
topology {}
global {
  assert { flowrest_meta.pkt_count != 1; };
}
"""

        bpl_text = "\n".join(
            [
                "var flowrest_hdr.tcp.src_port: bv16;",
                "var flowrest_meta.hdr_srcport: bv16;",
                "var flowrest_meta.register_index: bv16;",
                "var flowrest_meta.pkt_count: bv8;",
                "var flowrest___ra_ret_Ingress_read_pkt_count: bv8;",
                "var flowrest_Ingress_reg_pkt_count: [bv16]bv8;",
                "function flowrest_Ingress_idx_calc.get$bv16(flowrest_a:bv16) returns(bv16);",
                "assume (flowrest_hdr.tcp.src_port == 1234bv16);",
                "procedure flowrest_Ingress() {",
                "  havoc flowrest_meta.hdr_srcport;",
                "  flowrest_meta.hdr_srcport := flowrest_hdr.tcp.src_port;",
                "  call flowrest_Ingress_get_register_index(flowrest_meta.hdr_srcport);",
                "  call flowrest___ra_ret_Ingress_read_pkt_count := flowrest_Ingress_read_pkt_count.apply(flowrest_Ingress_reg_pkt_count[flowrest_meta.register_index]);",
                "  flowrest_meta.pkt_count := flowrest___ra_ret_Ingress_read_pkt_count;",
                "}",
                "procedure {:inline 1} flowrest_Ingress_get_register_index(flowrest_srcPort_2:bv16)",
                "  modifies flowrest_meta.register_index;",
                "{",
                "  flowrest_meta.register_index := flowrest_Ingress_idx_calc.get$bv16(flowrest_srcPort_2);",
                "}",
            ]
        )

        meta_by_node = {
            "flowrest": {
                "wraparound": {
                    "updates": [
                        {
                            "reg": "Ingress_reg_pkt_count",
                            "value_var": "__ra_ret_Ingress_read_pkt_count",
                            "op": "add",
                            "delta_is_const": True,
                            "delta_const": 1,
                            "idx_expr": "meta.register_index",
                        }
                    ]
                }
            }
        }

        cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=bpl_text, meta_by_node=meta_by_node)
        self.assertTrue(cands)
        self.assertEqual(cands[0].index_expr, "flowrest_meta.register_index")

    def test_meta_index_expr_derived_from_parser_path_before_ingress_call(self) -> None:
        spec_text = """
import flowrest from "flowrest.p4";
topology {}
global {
  assert { flowrest_meta.pkt_count != 1; };
}
"""

        bpl_text = "\n".join(
            [
                "var io_hdr.ethernet.ether_type: bv16;",
                "var io_hdr.ipv4.src_addr: bv32;",
                "var io_hdr.ipv4.dst_addr: bv32;",
                "var io_hdr.ipv4.protocol: bv8;",
                "var io_hdr.tcp.src_port: bv16;",
                "var io_hdr.tcp.dst_port: bv16;",
                "var flowrest_hdr.ethernet.ether_type: bv16;",
                "var flowrest_hdr.ipv4.src_addr: bv32;",
                "var flowrest_hdr.ipv4.dst_addr: bv32;",
                "var flowrest_hdr.ipv4.protocol: bv8;",
                "var flowrest_hdr.tcp.src_port: bv16;",
                "var flowrest_hdr.tcp.dst_port: bv16;",
                "var flowrest_hdr.udp.src_port: bv16;",
                "var flowrest_hdr.udp.dst_port: bv16;",
                "var flowrest_meta.hdr_srcport: bv16;",
                "var flowrest_meta.hdr_dstport: bv16;",
                "var flowrest_meta.register_index: bv16;",
                "var flowrest_meta.pkt_count: bv8;",
                "var flowrest___ra_ret_Ingress_read_pkt_count: bv8;",
                "var flowrest_Ingress_reg_pkt_count: [bv16]bv8;",
                "function flowrest_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8(",
                "  flowrest_a:bv32, flowrest_b:bv32, flowrest_c:bv16, flowrest_d:bv16, flowrest_e:bv8",
                ") returns(bv16);",
                "procedure main() {",
                "  io_hdr.ethernet.ether_type := 2048bv16;",
                "  io_hdr.ipv4.src_addr := 167772161bv32;",
                "  io_hdr.ipv4.dst_addr := 167772162bv32;",
                "  io_hdr.ipv4.protocol := 6bv8;",
                "  io_hdr.tcp.src_port := 1234bv16;",
                "  io_hdr.tcp.dst_port := 443bv16;",
                "  flowrest_hdr.ethernet.ether_type := io_hdr.ethernet.ether_type;",
                "  flowrest_hdr.ipv4.src_addr := io_hdr.ipv4.src_addr;",
                "  flowrest_hdr.ipv4.dst_addr := io_hdr.ipv4.dst_addr;",
                "  flowrest_hdr.ipv4.protocol := io_hdr.ipv4.protocol;",
                "  flowrest_hdr.tcp.src_port := io_hdr.tcp.src_port;",
                "  flowrest_hdr.tcp.dst_port := io_hdr.tcp.dst_port;",
                "  flowrest_meta.hdr_srcport := flowrest_runtime_srcport;",
                "  flowrest_meta.hdr_dstport := flowrest_runtime_dstport;",
                "  call flowrest_mainProcedure();",
                "  flowrest_hdr.ethernet.ether_type := 999bv16;",
                "}",
                "procedure flowrest_mainProcedure() {",
                "  call flowrest_main();",
                "}",
                "procedure {:inline 1} flowrest_main() {",
                "  call flowrest_pipe();",
                "}",
                "procedure {:inline 1} flowrest_pipe() {",
                "  call flowrest_IngressParser();",
                "  call flowrest_Ingress();",
                "}",
                "procedure {:inline 1} flowrest_IngressParser() {",
                "  goto flowrest_State$start;",
                "flowrest_State$start:",
                "  goto flowrest_State$parse_tcp, flowrest_State$parse_udp;",
                "flowrest_State$parse_tcp:",
                "  assume (flowrest_hdr.ipv4.protocol == 6bv8);",
                "  flowrest_meta.hdr_dstport := flowrest_hdr.tcp.dst_port;",
                "  flowrest_meta.hdr_srcport := flowrest_hdr.tcp.src_port;",
                "  goto flowrest_State$accept;",
                "flowrest_State$parse_udp:",
                "  assume (flowrest_hdr.ipv4.protocol == 17bv8);",
                "  flowrest_meta.hdr_dstport := flowrest_hdr.udp.dst_port;",
                "  flowrest_meta.hdr_srcport := flowrest_hdr.udp.src_port;",
                "  goto flowrest_State$accept;",
                "flowrest_State$accept:",
                "}",
                "procedure {:inline 1} flowrest_Ingress() {",
                "  call flowrest_Ingress_get_register_index(flowrest_meta.hdr_srcport, flowrest_meta.hdr_dstport);",
                "  call flowrest___ra_ret_Ingress_read_pkt_count := flowrest_Ingress_read_pkt_count.apply(flowrest_Ingress_reg_pkt_count[flowrest_meta.register_index]);",
                "  flowrest_meta.pkt_count := flowrest___ra_ret_Ingress_read_pkt_count;",
                "}",
                "procedure {:inline 1} flowrest_Ingress_get_register_index(flowrest_srcPort_2:bv16, flowrest_dstPort_2:bv16)",
                "  modifies flowrest_meta.register_index;",
                "{",
                "  flowrest_meta.register_index := flowrest_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8(",
                "    flowrest_hdr.ipv4.src_addr, flowrest_hdr.ipv4.dst_addr, flowrest_srcPort_2, flowrest_dstPort_2, flowrest_hdr.ipv4.protocol);",
                "}",
            ]
        )

        meta_by_node = {
            "flowrest": {
                "wraparound": {
                    "updates": [
                        {
                            "reg": "Ingress_reg_pkt_count",
                            "value_var": "__ra_ret_Ingress_read_pkt_count",
                            "op": "add",
                            "delta_is_const": True,
                            "delta_const": 1,
                            "idx_expr": "meta.register_index",
                        }
                    ]
                }
            }
        }

        cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=bpl_text, meta_by_node=meta_by_node)
        self.assertTrue(cands)
        idx = cands[0].index_expr or ""
        self.assertIn("flowrest_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8", idx)
        self.assertIn("167772161bv32", idx)
        self.assertIn("167772162bv32", idx)
        self.assertIn("1234bv16", idx)
        self.assertIn("443bv16", idx)
        self.assertIn("6bv8", idx)
        self.assertNotIn("flowrest_meta.hdr_srcport", idx)

    def test_meta_index_expr_not_derived_when_value_identifier_remains(self) -> None:
        spec_text = """
import flowrest from "flowrest.p4";
topology {}
global {
  assert { flowrest_meta.pkt_count != 1; };
}
"""

        bpl_text = "\n".join(
            [
                "var flowrest_meta.register_index: bv16;",
                "var flowrest_meta.pkt_count: bv8;",
                "var flowrest___ra_ret_Ingress_read_pkt_count: bv8;",
                "var flowrest_Ingress_reg_pkt_count: [bv16]bv8;",
                "function flowrest_Ingress_idx_calc.get$bv16(flowrest_a:bv16) returns(bv16);",
                "procedure flowrest_Ingress() {",
                "  call flowrest_Ingress_get_register_index(flowrest_runtime_port);",
                "  call flowrest___ra_ret_Ingress_read_pkt_count := flowrest_Ingress_read_pkt_count.apply(flowrest_Ingress_reg_pkt_count[flowrest_meta.register_index]);",
                "  flowrest_meta.pkt_count := flowrest___ra_ret_Ingress_read_pkt_count;",
                "}",
                "procedure {:inline 1} flowrest_Ingress_get_register_index(flowrest_srcPort_2:bv16)",
                "  modifies flowrest_meta.register_index;",
                "{",
                "  flowrest_meta.register_index := flowrest_Ingress_idx_calc.get$bv16(flowrest_srcPort_2);",
                "}",
            ]
        )

        meta_by_node = {
            "flowrest": {
                "wraparound": {
                    "updates": [
                        {
                            "reg": "Ingress_reg_pkt_count",
                            "value_var": "__ra_ret_Ingress_read_pkt_count",
                            "op": "add",
                            "delta_is_const": True,
                            "delta_const": 1,
                            "idx_expr": "meta.register_index",
                        }
                    ]
                }
            }
        }

        cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=bpl_text, meta_by_node=meta_by_node)
        self.assertTrue(cands)
        self.assertEqual(cands[0].index_expr, "flowrest_meta.register_index")
