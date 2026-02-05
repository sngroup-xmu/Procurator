#include "../include/header.p4"
#include "../include/metadata.p4"
#include "../include/parser.p4"
#include "../include/checksum.p4"
#include "../include/actions.p4"

field_list break_list {
    ethernet;
    ipv4;
    routing_metadata;
}

#define BREAK_LIST break_list
#include "../../lib/odb.p4"

table break_1 {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        gen_break;
    }
    size: 512;
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

DAMPER_CONTROL(1, break_1)


control ingress {
    if(valid(ipv4) and ipv4.ttl > 0) {
        DAMPER(1); 
        apply(ipv4_nhop);
        apply(forward_table);
        apply(send_frame);
    }
}
