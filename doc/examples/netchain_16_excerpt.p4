/*
Excerpt from `Procurator/argo/code/dataset/Netchain/netchain_16.p4`.

Purpose: provide a small, stable snippet for line-by-line P4 ↔ Boogie alignment docs.
This is not meant to be a standalone compilable P4 program (some surrounding type/table
definitions are omitted).
*/

struct headers {
    @name(".ethernet")
    ethernet_t    ethernet;
    @name(".ipv4")
    ipv4_t        ipv4;
    @name(".nc_hdr")
    nc_hdr_t      nc_hdr;
    @name(".tcp")
    tcp_t         tcp;
    @name(".udp")
    udp_t         udp;
    @name(".overlay")
    overlay_t[10] overlay;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        transition parse_ethernet;
    }
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract(hdr.ipv4);
        hdr.ipv4.protocol = 8w17;
        transition select(hdr.ipv4.protocol) {
            8w6: parse_tcp;
            8w17: parse_udp;
            default: accept;
        }
    }
    @name(".parse_nc_hdr") state parse_nc_hdr {
        packet.extract(hdr.nc_hdr);
        transition select(hdr.nc_hdr.op) {
            8w10: accept;
            8w12: accept;
            default: accept;
        }
    }
    @name(".parse_overlay") state parse_overlay {
        packet.extract(hdr.overlay.next);
        transition select(hdr.overlay.last.swip) {
            32w0: parse_nc_hdr;
            default: parse_overlay;
        }
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }
    @name(".parse_udp") state parse_udp {
        packet.extract(hdr.udp);
        hdr.udp.dstPort = 16w8888;
        transition select(hdr.udp.dstPort) {
            16w8888: parse_overlay;
            16w8889: parse_overlay;
            default: accept;
        }
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".sequence_reg") register<bit<16>>(32w4096) sequence_reg;
    @name(".value_reg") register<bit<128>>(32w4096) value_reg;

    @name(".assign_value_act") action assign_value_act() {
        sequence_reg.write((bit<32>)meta.location.index, (bit<16>)hdr.nc_hdr.seq);
        value_reg.write((bit<32>)meta.location.index, (bit<128>)hdr.nc_hdr.value);
    }
    @name(".drop_packet_act") action drop_packet_act() {
        mark_to_drop();
    }
    @name(".pop_chain_act") action pop_chain_act() {
        hdr.nc_hdr.sc = hdr.nc_hdr.sc + 8w255;
        hdr.overlay.pop_front(1);
        hdr.udp.len = hdr.udp.len + 16w65532;
        hdr.ipv4.totalLen = hdr.ipv4.totalLen + 16w65532;
    }
    @name(".get_sequence_act") action get_sequence_act() {
        sequence_reg.read(meta.sequence_md.seq, (bit<32>)meta.location.index);
    }
    @name(".maintain_sequence_act") action maintain_sequence_act() {
        meta.sequence_md.seq = meta.sequence_md.seq + 16w1;
        sequence_reg.write((bit<32>)meta.location.index, (bit<16>)meta.sequence_md.seq);
        sequence_reg.read(hdr.nc_hdr.seq, (bit<32>)meta.location.index);
    }
    @name(".read_value_act") action read_value_act() {
        value_reg.read(hdr.nc_hdr.value, (bit<32>)meta.location.index);
    }

    // ... (tables omitted; see the full file for definitions)

    apply {
        if (hdr.nc_hdr.isValid()) {
            get_my_address.apply();
            if (hdr.ipv4.dstAddr == meta.my_md.ipaddress) {
                find_index.apply();
                get_sequence.apply();
                if (hdr.nc_hdr.op == 8w10) {
                    read_value.apply();
                }
                else {
                    if (hdr.nc_hdr.op == 8w12) {
                        if (meta.my_md.role == 16w100) {
                            maintain_sequence.apply();
                        }
                        if (meta.my_md.role == 16w100 || hdr.nc_hdr.seq > meta.sequence_md.seq) {
                            assign_value.apply();
                            pop_chain.apply();
                        }
                        else {
                            drop_packet.apply();
                        }
                    }
                }
                if (meta.my_md.role == 16w102) {
                    pop_chain_again.apply();
                    gen_reply.apply();
                }
                else {
                    get_next_hop.apply();
                }
            }
        }
        if (hdr.nc_hdr.isValid()) {
            failure_recovery.apply();
        }
        if (hdr.tcp.isValid() || hdr.udp.isValid()) {
            ipv4_route.apply();
        }
    }
}

