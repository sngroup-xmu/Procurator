import unittest

from dslc.bench.p4b_semantic_audit import CHECK_FAIL, CHECK_OK, CHECK_PRUNED, CHECK_WEAK, audit_text


class TestP4BSemanticAudit(unittest.TestCase):
    def test_register_model_requires_mirrors(self) -> None:
        src = "control C() { Register<bit<8>, bit<32>>(16) r; apply { r.write(0, 1); } }"
        bpl = """
        var r:[bv32]bv8;
        var r__wrote_any:bool;
        var r__last_value:bv8;
        var r__last0_value:bv8;
        function {:inline true}r.read(reg:[bv32]bv8, index:bv32) returns (bv8) {reg[index]}
        procedure {:inline 1} r.write(index:bv32, value:bv8);
        """

        out = audit_text(src, bpl, {"register_sizes": {"r": 16}})

        self.assertEqual(out["semantic_status"], CHECK_OK)
        self.assertIn("register", out["semantic_features"])

    def test_counter_comment_only_is_failure(self) -> None:
        src = "control C() { Counter<bit<10>,bit<12>>(1024, PSA_CounterType_t.PACKETS) counter; apply { counter.count(1024); } }"
        bpl = """
        procedure {:inline 1} C()
        {
            // count
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_FAIL)
        self.assertEqual(out["semantic_checks"][0]["feature"], "counter")
        self.assertIn("comment/no-op", out["semantic_failures"][0])

    def test_counter_state_and_explicit_update_are_ok(self) -> None:
        src = "control C() { Counter<bit<10>,bit<12>>(1024, PSA_CounterType_t.PACKETS) counter; apply { counter.count(1024); } }"
        bpl = """
        var MyIC_counter__counter:[bv12]bv10;
        procedure {:inline 1} MyIC_counter.add(index:bv12, value:bv10);
        procedure {:inline 1} MyIC_counter.count(index:bv12);
        procedure {:inline 1} C()
        {
            call MyIC_counter.count(1024bv12);
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_OK)
        self.assertIn("counter", out["semantic_features"])
        self.assertIn("counter_update", out["semantic_features"])

    def test_direct_counter_binding_without_explicit_count_checks_state_only(self) -> None:
        src = "control C() { DirectCounter<bit<12>>(PSA_CounterType_t.PACKETS) counter0; table t { actions = { NoAction; } psa_direct_counter = counter0; } apply { t.apply(); } }"
        bpl = """
        var MyIC_counter0__counter:[bv32]bv12;
        procedure {:inline 1} MyIC_counter0.count(index:bv32);
        procedure {:inline 1} MyIC_counter0.add(index:bv32, value:bv12);
        procedure {:inline 1} C()
        {
            call MyIC_t.apply();
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_OK)
        self.assertIn("counter", out["semantic_features"])
        self.assertNotIn("counter_update", out["semantic_features"])

    def test_meter_uninterpreted_execute_is_weak(self) -> None:
        src = "control C() { Meter<bit<12>>(1024, PSA_MeterType_t.PACKETS) m; apply { m.execute(0); } }"
        bpl = """
        procedure {:inline 1} C()
        {
            call m.execute(0bv12);
        }
        procedure m.execute(arg0:int);
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_WEAK)
        self.assertIn("uninterpreted effect", out["semantic_failures"][0])

    def test_meter_expression_execute_is_weak(self) -> None:
        src = "control C() { Meter<bit<12>>(1024, PSA_MeterType_t.PACKETS) m; apply { if (m.execute(0) == PSA_MeterColor_t.GREEN) { } } }"
        bpl = """
        procedure {:inline 1} C()
        {
            tmp := m.execute(0bv12);
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_WEAK)

    def test_digest_pack_event_flag_is_ok(self) -> None:
        src = "control C() { Digest<mac_learn_digest_t>() d; apply { d.pack(meta.msg); } }"
        bpl = """
        var p4b_digest:bool;
        procedure {:inline 1} C()
        {
            p4b_digest := true;
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_OK)

    def test_checksum_extern_summary_is_weak(self) -> None:
        src = "control C() { InternetChecksum() ck; apply { ck.clear(); ck.add({h.a}); h.csum = ck.get(); } }"
        bpl = """
        function C_ck.get() returns(bv16);
        procedure {:inline 1} C()
        {
            call C_ck.clear();
            call C_ck.add();
            h.csum := C_ck.get();
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_WEAK)

    def test_checksum_event_summary_is_ok(self) -> None:
        src = "control C() { apply { update_checksum(h.isValid(), {h.a}, h.csum, HashAlgorithm.csum16); } }"
        bpl = """
        var p4b_checksum_updated:bool;
        procedure {:inline 1} C()
        {
            if (h.valid) {
                p4b_checksum_updated := true;
                havoc h.csum;
            }
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_OK)

    def test_v1model_hash_requires_function_and_range(self) -> None:
        src = "control C() { apply { hash(meta.idx, HashAlgorithm.crc32, 0, { hdr.ipv4.srcAddr }, 16); } }"
        bpl = """
        function hash_crc32$bv32$bv32$bv32(arg0:bv32, arg1:bv32, arg2:bv32) returns(bv32);
        procedure {:inline 1} C()
        {
            // p4b_hash_model: builtin algorithm=HashAlgorithm.crc32 model=crc32_uf precision=deterministic_uninterpreted
            meta.idx := hash_crc32$bv32$bv32$bv32(0bv32, hdr.ipv4.srcAddr, 16bv32);
            assume(buge.bv32(meta.idx, 0bv32) && bule.bv32(meta.idx, 15bv32));
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_WEAK)
        self.assertIn("uninterpreted", out["semantic_failures"][0])

    def test_identity_hash_model_is_precise(self) -> None:
        src = "control C() { apply { hash(meta.idx, HashAlgorithm.identity, { hdr.a, hdr.b }); } }"
        bpl = """
        procedure {:inline 1} C()
        {
            // p4b_hash_model: builtin algorithm=HashAlgorithm.identity model=identity precision=precise
            meta.idx := (hdr.a++hdr.b)[16:0];
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_OK)

    def test_three_arg_hash_requires_function_assignment_not_range(self) -> None:
        src = "control C() { apply { hash(meta.output, HashAlgorithm.lookup3, { hdr.sa, hdr.da }); } }"
        bpl = """
        function hash__lookup3$bv16$bv16(arg0:bv16, arg1:bv16) returns(bv32);
        procedure {:inline 1} C()
        {
            // p4b_hash_model: builtin algorithm=HashAlgorithm.lookup3 model=HashAlgorithm_lookup3_uf precision=deterministic_uninterpreted
            meta.output := hash__lookup3$bv16$bv16(hdr.sa, hdr.da);
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_WEAK)
        self.assertIn("hash_builtin_3arg", out["semantic_features"])

    def test_three_arg_hash_target_helper_summary_is_ok(self) -> None:
        src = "control C() { apply { hash(meta.output, HashAlgorithm.lookup3, { hdr.sa, hdr.da }); } }"
        bpl = """
        function hash__lookup3$bv16$bv16(arg0:bv16, arg1:bv16) returns(bv32);
        procedure {:inline 1} C()
        {
            // p4b_hash_model: builtin algorithm=HashAlgorithm.lookup3 model=ubpf_runtime_helper precision=target_helper
            meta.output := hash__lookup3$bv16$bv16(hdr.sa, hdr.da);
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_OK)
        self.assertIn("hash_builtin_3arg", out["semantic_features"])

    def test_three_arg_hash_comment_only_is_failure(self) -> None:
        src = "control C() { apply { hash(meta.output, HashAlgorithm.lookup3, { hdr.sa }); } }"
        bpl = """
        procedure {:inline 1} C()
        {
            // hash
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_FAIL)
        self.assertEqual(out["semantic_checks"][0]["feature"], "hash_builtin_3arg")

    def test_hash_extern_havoc_fallback_is_weak(self) -> None:
        src = "control C() { Hash<bit<16>>(HashAlgorithm_t.CRC16) h; apply { x = h.get({a}); } }"
        bpl = """
        var __hash_get_0:bv16;
        procedure {:inline 1} C()
        {
            havoc __hash_get_0;
            x := __hash_get_0;
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_WEAK)

    def test_hash_extern_crc_uf_is_weak(self) -> None:
        src = "control C() { Hash<bit<16>>(HashAlgorithm_t.CRC16) h; apply { x = h.get({a}); } }"
        bpl = """
        function C_h.get$bv16(arg0:bv16) returns(bv16);
        procedure {:inline 1} C()
        {
            // p4b_hash_model: extern base=C_h algorithm=HashAlgorithm_t.CRC16 model=crc16_uf precision=deterministic_uninterpreted
            x := C_h.get$bv16(a);
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_WEAK)

    def test_hash_extern_target_helper_summary_is_ok(self) -> None:
        src = "control C() { Hash<bit<16>>(PNA_HashAlgorithm_t.TOEPLITZ) h; apply { x = h.get_hash({a}); } }"
        bpl = """
        function C_h.get_hash$alg_PNA_HashAlgorithm_t_TOEPLITZ$bv16(arg0:bv16) returns(bv16);
        procedure {:inline 1} C()
        {
            // p4b_hash_model: extern base=C_h algorithm=PNA_HashAlgorithm_t.TOEPLITZ model=dpdk_rss_helper precision=target_helper
            x := C_h.get_hash$alg_PNA_HashAlgorithm_t_TOEPLITZ$bv16(a);
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_OK)
        self.assertIn("hash_extern", out["semantic_features"])

    def test_hash_extern_identity_precise_is_ok(self) -> None:
        src = "control C() { Hash<bit<16>>(HashAlgorithm_t.IDENTITY) h; apply { x = h.get({a}); } }"
        bpl = """
        procedure {:inline 1} C()
        {
            // p4b_hash_model: extern base=C_h algorithm=HashAlgorithm_t.IDENTITY model=identity precision=precise
            x := a[16:0];
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_OK)

    def test_mixed_hash_precision_is_weak(self) -> None:
        src = """
        control C() {
            Hash<bit<16>>(HashAlgorithm_t.IDENTITY) identity_hash;
            Hash<bit<16>>(HashAlgorithm_t.CRC16) crc_hash;
            apply {
                x = identity_hash.get({a});
                y = crc_hash.get({b});
            }
        }
        """
        bpl = """
        function C_crc_hash.get$bv16(arg0:bv16) returns(bv16);
        procedure {:inline 1} C()
        {
            // p4b_hash_model: extern base=C_identity_hash algorithm=HashAlgorithm_t.IDENTITY model=identity precision=precise
            x := a[16:0];
            // p4b_hash_model: extern base=C_crc_hash algorithm=HashAlgorithm_t.CRC16 model=crc16_uf precision=deterministic_uninterpreted
            y := C_crc_hash.get$bv16(b);
        }
        """

        out = audit_text(src, bpl)

        self.assertEqual(out["semantic_status"], CHECK_WEAK)
        self.assertIn("uninterpreted", out["semantic_failures"][0])

    def test_slicing_can_mark_irrelevant_feature_pruned(self) -> None:
        src = "control C() { Random<bit<16>>(0, 10) r; apply { x = r.read(); } }"
        bpl = "procedure {:inline 1} C() { }\n"

        out = audit_text(src, bpl, slicing_mode=True)

        self.assertEqual(out["semantic_status"], "SKIP")
        self.assertEqual(out["semantic_checks"][0]["status"], CHECK_PRUNED)


if __name__ == "__main__":
    unittest.main()
