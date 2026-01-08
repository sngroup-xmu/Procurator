parser SwitchV2PIngressParser(
    packet_in pkt,
    out headers hdr,
    out ig_metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        //ig_md = ingress_metadata_initializer;
        ig_md.switchv2p_md.switch_type = TOR;
        ig_md.switchv2p_md.switch_id = 0;
        ig_md.switchv2p_md.key = 0;
        ig_md.switchv2p_md.val = 0;
        ig_md.switchv2p_md.mirror_session = 0;
        ig_md.switchv2p_md.mirror_header_type = 0;
        ig_md.switchv2p_md.to_gw = false;
        ig_md.switchv2p_md.in_cache = false;
        ig_md.switchv2p_md.misdelivered = false;

        pkt.extract(ig_intr_md);
        transition parse_port_metadata;
    }

    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4_outter);
        pkt.extract(hdr.ipv4_inner);
        transition select(hdr.ipv4_inner.protocol) {
            IP_PROTOCOLS_SWITCHV2P : parse_switchv2p;
            default : reject;
        }
    }

    state parse_switchv2p {
        type_t switchv2p_type = pkt.lookahead<type_t>(); // V todo: hdr.switchv2p.type
        transition select(switchv2p_type) {
            INVALIDATION_TYPE: parse_tagged;
            LEARNING_TYPE: parse_tagged;
            EVICTION_TAG_TYPE: parse_tagged;
            default: parse_normal;
        }
    }

    state parse_tagged { 
        pkt.extract(hdr.switchv2p);
        //ig_md.switchv2p_md.setValid();
        ig_md.switchv2p_md.key = hdr.switchv2p.key;
        ig_md.switchv2p_md.val = hdr.switchv2p.val;
        transition accept;
    }

    state parse_normal {
        pkt.extract(hdr.switchv2p);
        //ig_md.switchv2p_md.setValid();
        ig_md.switchv2p_md.key = hdr.ipv4_inner.dst_addr;
        ig_md.switchv2p_md.val = hdr.ipv4_outter.dst_addr;
        transition accept;
    }
}


control SwitchV2PIngressDeparser(
        packet_out pkt,
        inout headers hdr,
        in ig_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {

    Mirror() ing_port_mirror;

    apply {

        if (ig_intr_dprsr_md.mirror_type == MIRROR_TYPE_LEARNING) {
            ing_port_mirror.emit<mirror_h>(ig_md.switchv2p_md.mirror_session, {ig_md.switchv2p_md.mirror_header_type, hdr.ipv4_outter.dst_addr});
        } else if (ig_intr_dprsr_md.mirror_type == MIRROR_TYPE_INVALIDATION) {
            ing_port_mirror.emit<mirror_h>(ig_md.switchv2p_md.mirror_session, {ig_md.switchv2p_md.mirror_header_type, hdr.ipv4_outter.dst_addr});
        }
        pkt.emit(hdr);
    }
}


parser SwitchV2PEgressParser(
        packet_in pkt,
        out headers hdr_eg,
        out eg_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    
    state start {
        pkt.extract(eg_intr_md);
        pkt.extract(hdr_eg.mirror);
        pkt.extract(hdr_eg.ethernet);
        pkt.extract(hdr_eg.ipv4_outter);
        pkt.extract(hdr_eg.ipv4_inner);
        pkt.extract(hdr_eg.switchv2p);

        transition accept;
    }
}

control SwitchV2PEgressDeparser(
        packet_out pkt,
        inout headers hdr_eg,
        in eg_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr_eg);
    } 
}
