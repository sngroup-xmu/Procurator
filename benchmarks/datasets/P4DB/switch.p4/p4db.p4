action _drop() {
    drop();
}

action set_nhop(nhop_ipv4) {
    modify_field(routing_metadata.nhop_ipv4, nhop_ipv4);
    add_to_field(ipv4.ttl, -1);
}

action set_dmac(dmac, port) {
    modify_field(ethernet.dstAddr, dmac);
    modify_field(standard_metadata.egress_spec, port);
}

action set_smac(smac) {
    modify_field(ethernet.srcAddr, smac);
}


header_type routing_metadata_t {
    fields {
        nhop_ipv4 : 32;
    }
}

metadata routing_metadata_t routing_metadata;

field_list watch_list {
    ethernet;
    ipv4;
}

#define WATCH_LIST watch_list
#include "../lib/odb.p4"

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

field_list match_list {
    ethernet;
    ipv4;
    routing_metadata;
    odb_metadata.match_result;
}


#define MATCH_LIST match_list

table match_1 {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        gen_match;
    }
    size: 512;
}

field_list break_list {
    ethernet;
    ipv4;
    routing_metadata;
}

#define BREAK_LIST break_list

table break_1 {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        gen_break;
    }
    size: 512;
}

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

DAMPER_CONTROL(1, break_1)

table pipeline_1 {
    reads {
        odb_metadata.action_id : exact;
    }
    actions {
        gen_action;
    }
    size: 512;
}


action forward_action (port) {
    modify_field(standard_metadata.egress_spec, port);
}

table port_forward {
    reads {
        standard_metadata.ingress_port : exact;
    }
    actions {
        forward_action;   
    }
}


field_list predication_list {
    ethernet;
    ipv4;
}

#define PREDICATION_LIST predication_list

table predication_1 {
    reads {
        ipv4.dstAddr : exact;
        ipv4.srcAddr : exact;
    }
    actions {
        gen_predication;
    }
}
