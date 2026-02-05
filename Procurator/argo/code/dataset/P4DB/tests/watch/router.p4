#include "../include/header.p4"
#include "../include/metadata.p4"
#include "../include/parser.p4"
#include "../include/checksum.p4"
#include "../include/actions.p4"

field_list watch_list {
    ethernet;
    ipv4;
}

#define WATCH_LIST watch_list
#include "../../lib/odb.p4"

table watch_1 {
    reads {
        ipv4.dstAddr : exact;
        ipv4.srcAddr : exact;
    }
    actions {
        gen_watch;
    }
    size: 1024;
}

table watch_2 {
    reads {
        ipv4.dstAddr : exact;
        ipv4.srcAddr : exact;
    }
    actions {
        gen_watch;
    }
    size: 512;
}

table watch_3 {
    reads {
        ipv4.dstAddr : exact;
        ipv4.srcAddr : exact;
    }
    actions {
        gen_watch;
    }
    size: 256;
}

table watch_4 {
    reads {
        ipv4.dstAddr : exact;
        ipv4.srcAddr : exact;
    }
    actions {
        gen_watch;
    }
    size: 1024;
}

table ipv4_nhop {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        set_nhop;
        _drop;
    }
    size: 1024;
}

table forward_table {
    reads {
        routing_metadata.nhop_ipv4 : exact;
    }
    actions {
        set_dmac;
        _drop;
    }
    size: 512;
}

table send_frame {
    reads {
        standard_metadata.egress_port: exact;
    }
    actions {
        set_smac;
        _drop;
    }
    size: 256;
}

control ingress {
    apply(watch_1);
    if(valid(ipv4) and ipv4.ttl > 0) {
        apply(watch_2);
        apply(ipv4_nhop);
        apply(watch_3);
        apply(forward_table);
        apply(watch_4);
        apply(send_frame);
    }
}
