#include "switchv2p_cache.p4"
#include "switchv2p_forwarding.p4"

control SwitchV2PIngress(
    inout headers hdr,
    inout ig_metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Cache() cache;
    SwitchV2PForwarding() fw;

    action set_config(switch_type_t switch_type, type_t switch_id) {
        ig_md.switchv2p_md.switch_type = switch_type;
        ig_md.switchv2p_md.switch_id = switch_id;
    }

    table switch_config {
        actions = {
            set_config;
        }
        const size = 1;
    }

    action set_to_gw(bool to_gw) {
        ig_md.switchv2p_md.to_gw = to_gw;
    }

    table match_gw {
        key = {
            hdr.ipv4_outter.dst_addr: exact;
        }
        actions = {
            set_to_gw;
        }
        default_action = set_to_gw(false);
        const size = 1;
    }

    apply {
        switch_config.apply();
        match_gw.apply();
        cache.apply(hdr, ig_md, ig_intr_prsr_md, ig_intr_dprsr_md);
        hdr.mirror.setValid();
        hdr.mirror.type = NORMAL_TYPE;
        fw.apply(hdr, ig_md, ig_intr_md, ig_intr_dprsr_md, ig_intr_tm_md);
    }

}

control SwitchV2PEgress(
    inout headers hdr_eg,
    inout eg_metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {

    action set_dest(ipv4_addr_t dst) {
        hdr_eg.ipv4_outter.dst_addr = dst;
    }
    
    table switch_id_to_dst {
        key = {
            hdr_eg.switchv2p.switch_id: exact;
        }
        actions = {
            set_dest;
        }
        const default_action = set_dest(0);
        const size = 256;
    }

    table src_to_tor {
        key = {
            hdr_eg.ipv4_outter.src_addr: exact;
        }
        actions = {
            set_dest;
        }
        const default_action = set_dest(0);
    }


    apply {
        if (hdr_eg.mirror.type == INVALIDATION_TYPE) {
            hdr_eg.switchv2p.type = INVALIDATION_TYPE;
            hdr_eg.switchv2p.key = hdr_eg.ipv4_inner.dst_addr;
            hdr_eg.ipv4_outter.total_len = 50;
            hdr_eg.ipv4_inner.total_len = 30;
            switch_id_to_dst.apply();
        } else if (hdr_eg.mirror.type == LEARNING_TYPE) {
            hdr_eg.switchv2p.type = LEARNING_TYPE;
            hdr_eg.switchv2p.key = hdr_eg.ipv4_inner.dst_addr;
            hdr_eg.switchv2p.val = hdr_eg.mirror.val;
            hdr_eg.ipv4_outter.total_len = 50;
            hdr_eg.ipv4_inner.total_len = 30;
            src_to_tor.apply();
        }
        hdr_eg.mirror.setInvalid();
    }
}
