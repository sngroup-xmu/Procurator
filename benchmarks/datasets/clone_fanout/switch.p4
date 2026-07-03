/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

/*
 * Microbenchmark: clone/mirror payload dependency.
 *
 * The ingress pipeline writes hdr.fanout.pass before issuing an I2E clone.
 * Slicing for the clone event must keep both the payload update and the clone
 * call; otherwise the generated model can forget the packet snapshot that the
 * clone/mirror event carries into later pipeline work.
 */

header fanout_t {
    bit<1> pass;
    bit<1> payload;
}

struct headers {
    fanout_t fanout;
}

struct metadata {
    bit<1> do_clone;
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
        standard_metadata.egress_spec = 0;
        meta.do_clone = 0;

        if (hdr.fanout.isValid()) {
            hdr.fanout.pass = 1;
            meta.do_clone = 1;
            if (hdr.fanout.pass == 1) {
                clone(CloneType.I2E, 1);
            }
        }
    }
}

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {
        if (hdr.fanout.pass == 1) {
            standard_metadata.egress_spec = 1;
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
