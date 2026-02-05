#include <core.p4>
#include <v1model.p4>
#include "includes/header.p4"
#include "includes/parser.p4"

// Fixed version of learner.p4 for reproducing the majority-quorum bug.
//
// The original learner implementation sets paxos_metadata.set_drop to 1 in read_round()
// and never resets it to 0, so even when a majority is detected the transport_tbl uses
// the drop action. That local "drop_flag" bug prevents exercising the intended learner
// forwarding logic.
//
// This file keeps everything else identical to learner.p4 but changes set_drop := 0
// in read_round(), so that when the majority condition holds, transport_tbl forwards.

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    register<bit<ROUND_SIZE>>(INSTANCE_COUNT) registerRound;
    register<bit<VALUE_SIZE>>(INSTANCE_COUNT) registerValue;
    register<bit<8>>(INSTANCE_COUNT) registerHistory2B;

    action drop() {
        mark_to_drop();
    }

    action read_round() {
        registerRound.read(meta.paxos_metadata.round, hdr.paxos.inst);
        // FIX: allow forwarding when the majority condition holds.
        meta.paxos_metadata.set_drop = 0;
        registerHistory2B.read(meta.paxos_metadata.ack_acceptors, hdr.paxos.inst);
    }

    action handle_2b() {
        registerRound.write(hdr.paxos.inst, hdr.paxos.rnd);
        registerValue.write(hdr.paxos.inst, hdr.paxos.paxosval);
        // Limit to 8 bits for left shift operation
        bit<8> acptid = 8w1 << (bit<8>)hdr.paxos.acptid;
        meta.paxos_metadata.ack_acceptors = meta.paxos_metadata.ack_acceptors | acptid;
        registerHistory2B.write(hdr.paxos.inst, meta.paxos_metadata.ack_acceptors);
    }

    table learner_tbl {
        key = {hdr.paxos.msgtype : exact;}
        actions = {
            handle_2b;
        }
        size = 1;
        default_action = handle_2b;
    }

    action handle_new_value() {
        registerRound.write(hdr.paxos.inst, hdr.paxos.rnd);
        registerValue.write(hdr.paxos.inst, hdr.paxos.paxosval);
        bit<8> acptid = 8w1 << (bit<8>)hdr.paxos.acptid;
        registerHistory2B.write(hdr.paxos.inst, acptid);
    }

    table reset_consensus_instance {
        key = {hdr.paxos.msgtype : exact;}
        actions = {
            handle_new_value;
        }
        size = 1;
        default_action = handle_new_value;
    }

    action forward(PortId port, bit<16> learnerPort) {
        standard_metadata.egress_spec = (bit<9>)port;
        hdr.udp.dstPort = learnerPort;
    }

    table transport_tbl {
        key = { meta.paxos_metadata.set_drop : exact; }
        actions = {
            drop;
             forward;
        }
        size = 2;
        default_action = drop();
    }

    apply {
        if (hdr.ipv4.isValid()) {
            if (hdr.paxos.isValid()) {
                // fair assumption
                @assume[hdr.paxos.acptid == 0 || hdr.paxos.acptid == 1 || hdr.paxos.acptid == 2] {}

                read_round();
                if (hdr.paxos.rnd > meta.paxos_metadata.round) {
                    reset_consensus_instance.apply();
                }
                else if (hdr.paxos.rnd == meta.paxos_metadata.round) {
                    learner_tbl.apply();
                }
                // TODO: replace this with counting number of 1 in Binary
                // e.g count_number_of_1_binary(paxos_metadata.acceptors) == MAJORITY
                if (meta.paxos_metadata.ack_acceptors == 6       // 0b110
                    || meta.paxos_metadata.ack_acceptors == 5    // 0b101
                    || meta.paxos_metadata.ack_acceptors == 3)   // 0b011
                {
                    // deliver the value
                    transport_tbl.apply();
                }

                @assert[meta.paxos_metadata.ack_acceptors <= 7] {}
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

