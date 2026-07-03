#include <core.p4>
#include <v1model.p4>
#include "includes/header.p4"
#include "includes/parser.p4"

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    register<bit<32>>(1) ctrlInstane;

    action increase_instance() {
        bit<32> index = 0;
        bit<32> current_instance = 32w0;

        ctrlInstane.read(current_instance, index);
        hdr.paxos.inst = current_instance;

        current_instance = current_instance + 1;
        ctrlInstane.write(index, current_instance);
        meta.paxos_metadata.set_drop = 0;
    }

    action reset_instance() {
        bit<32> index = 0;
        bit<32> reset_value = 32w0;
        ctrlInstane.write(index, reset_value);
        // Do not need to forward this message
        meta.paxos_metadata.set_drop = 1;
    }

    action drop() {
        mark_to_drop();
    }

    table leader_tbl {
        key = {hdr.paxos.msgtype : exact;}
        actions = {
            increase_instance;
            reset_instance;
            drop;
        }
        size = 4;
        default_action = drop();
    }


    action forward(PortId port, bit<16> acceptorPort) {
        standard_metadata.egress_spec = (bit<9>)port;
        hdr.udp.dstPort = acceptorPort;
    }

    table transport_tbl {
        key = { meta.paxos_metadata.set_drop : exact; }
        actions = {
            drop;
             forward;
        }
        size = 2;
        default_action =  drop();
    }

    apply {
        if (hdr.ipv4.isValid()) {
            if (hdr.paxos.isValid()) {
                leader_tbl.apply();
                transport_tbl.apply();
            }
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    table place_holder_table {
        actions = {
            NoAction;
        }
        size = 2;
        default_action = NoAction();
    }
    apply {
        place_holder_table.apply();
    }
}

V1Switch(TopParser(), verifyChecksum(), ingress(), egress(), computeChecksum(), TopDeparser()) main;