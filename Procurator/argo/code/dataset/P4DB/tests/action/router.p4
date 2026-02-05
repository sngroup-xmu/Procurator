#include "../include/header.p4"
#include "../include/metadata.p4"
#include "../include/parser.p4"
#include "../include/checksum.p4"
#include "../include/actions.p4"

field_list action_list {
    ethernet;
    ipv4;
    routing_metadata;
    odb_metadata.action_id;
    odb_metadata.action_parameter1;
    odb_metadata.action_parameter2;
    odb_metadata.action_parameter3;
    odb_metadata.action_parameter4;
}

#define ACTION_LIST action_list
#include "../../lib/odb.p4"

ACTION_WITH_1_PARAM(set_nhop, 1, id)
ACTION_WITHOUT_PARAM(_drop, 2)

table action_1 {
    reads {
        odb_metadata.action_id : exact;
    }
    actions {
        gen_action;
    }
    size: 512;
}

table ipv4_nhop {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        ACT(set_nhop);
        ACT(_drop);
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
    if(valid(ipv4) and ipv4.ttl > 0) {
        apply(ipv4_nhop);
        apply(action_1);
        apply(forward_table);
        apply(send_frame);
    }
}
