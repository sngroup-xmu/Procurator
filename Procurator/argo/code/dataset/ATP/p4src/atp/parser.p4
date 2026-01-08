//no use:only agtr once
// parser TofinoIngressParser(
//         packet_in pkt,
//         out ingress_intrinsic_metadata_t ig_intr_md) {
//     state start {
//         pkt.extract(ig_intr_md);
//         transition select(ig_intr_md.resubmit_flag) {
//             1 : parse_resubmit;
//             0 : parse_port_metadata;
//         }
//     }

//     state parse_resubmit {
//         // Parse resubmitted packet here.
//         transition reject;
//     }

//     state parse_port_metadata {
//         pkt.advance(PORT_METADATA_SIZE);
//         transition accept;
//     }
// }

// parser TofinoEgressParser(
//         packet_in pkt,
//         out egress_intrinsic_metadata_t eg_intr_md) {
//     state start {
//         pkt.extract(eg_intr_md);
//         transition accept;
//     }
// }


// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out headers hdr,
        inout metadata   data,
        inout standard_metadata_t standard_metadata) {

    //TofinoIngressParser() tofino_parser;

    state start {
        //tofino_parser.apply(pkt, ig_intr_md);
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_ATP   : parse_p4ml_ipv4;
            default : accept;
        }
    }

    state parse_p4ml_ipv4 {
        pkt.extract(hdr.ipv4);
        transition parse_udp;
    }

    state parse_udp{
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            6001: parse_p4ml;
            default: accept;
        }
    }
    

    state parse_p4ml {
        pkt.extract(hdr.p4ml);
        transition parse_agtr_index;  
    }
    state parse_agtr_index{
        pkt.extract(hdr.p4ml_agtr_index);
        transition parse_entry;
    }
    state parse_entry {
        pkt.extract(hdr.p4ml_entries);
        transition accept;
    }

}

// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------


