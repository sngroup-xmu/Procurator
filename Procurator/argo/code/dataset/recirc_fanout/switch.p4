/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

/*
 * Microbenchmark: Recirculation-based fan-out.
 *
 * A write packet is delivered to one replica in the first pass and is
 * recirculated to deliver a second copy to the other replica in a later pass.
 *
 * The key idea (for verification): recirculation splits a logical broadcast into
 * sequential sends across passes, enabling non-atomic fan-out interleavings
 * (e.g., A, B, A', B').
 */

header fanout_t {
    bit<1> pass;
    bit<1> write_id; // 0=A, 1=B
}

struct headers {
    fanout_t fanout;
}

struct metadata {
    bit<1> do_recirculate;
}

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.fanout);
        transition accept;
    }
}

control MyVerifyChecksum(inout headers hdr, inout metadata meta) { apply { } }
control MyComputeChecksum(inout headers hdr, inout metadata meta) { apply { } }

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    apply {
        // Default: drop.
        standard_metadata.egress_spec = 0;
        meta.do_recirculate = 0;

        if (hdr.fanout.isValid()) {
            if (hdr.fanout.pass == 0) {
                // First pass: send one copy, then recirculate for the second copy.
                if (hdr.fanout.write_id == 0) {
                    standard_metadata.egress_spec = 1;
                } else {
                    standard_metadata.egress_spec = 2;
                }
                hdr.fanout.pass = 1;
                meta.do_recirculate = 1;
            } else {
                // Second pass: send to the other replica.
                if (hdr.fanout.write_id == 0) {
                    standard_metadata.egress_spec = 2;
                } else {
                    standard_metadata.egress_spec = 1;
                }
            }
        }
    }
}

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {
        if (meta.do_recirculate == 1) {
            recirculate(meta);
        }
    }
}

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.fanout);
    }
}

V1Switch(
    MyParser(),
    MyVerifyChecksum(),
    MyIngress(),
    MyEgress(),
    MyComputeChecksum(),
    MyDeparser()
) main;
