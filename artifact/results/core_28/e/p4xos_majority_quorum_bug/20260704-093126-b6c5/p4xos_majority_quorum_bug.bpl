// ===== BEGIN PREAMBLE =====
function bvule.bv16(left:bv16, right:bv16) returns(bool);
function {:builtin "bvule"} bvule.bv16$builtin(left:bv16, right:bv16) returns(bool);
axiom (forall left:bv16, right:bv16 :: bvule.bv16(left, right) <==> bvule.bv16$builtin(left, right));
function bvule.bv32(left:bv32, right:bv32) returns(bool);
function {:builtin "bvule"} bvule.bv32$builtin(left:bv32, right:bv32) returns(bool);
axiom (forall left:bv32, right:bv32 :: bvule.bv32(left, right) <==> bvule.bv32$builtin(left, right));
// ===== END PREAMBLE =====

// ===== BEGIN NODE learner (prefixed) =====
type learner_Ref;
type learner_error=bv1;
type learner_HeaderStack = [int]learner_Ref;
var learner_last:[learner_HeaderStack]learner_Ref;
var learner_forward:bool;
var learner_isValid:[learner_Ref]bool;
var learner_emit:[learner_Ref]bool;
var learner_stack.index:[learner_HeaderStack]int;
var learner_size:[learner_HeaderStack]int;
var learner_drop:bool;
var learner_p4b_clone_i2e:bool;
var learner_p4b_clone_e2e:bool;
var learner_p4b_clone_i2i:bool;
var learner_p4b_recirculate:bool;
var learner_p4b_digest:bool;
var learner_p4b_checksum_verified:bool;
var learner_p4b_checksum_updated:bool;
var learner_p4b_checksum_error:bool;

// learner_Struct learner_standard_metadata_t
type learner_standard_metadata_t;
var learner_standard_metadata.ingress_port:bv9;
var learner_standard_metadata.egress_spec:bv9;
var learner_standard_metadata.egress_port:bv9;
var learner_standard_metadata.instance_type:bv32;
var learner_standard_metadata.packet_length:bv32;
var learner_standard_metadata.enq_timestamp:bv32;
var learner_standard_metadata.enq_qdepth:bv19;
var learner_standard_metadata.deq_timedelta:bv32;
var learner_standard_metadata.deq_qdepth:bv19;
var learner_standard_metadata.ingress_global_timestamp:bv48;
var learner_standard_metadata.egress_global_timestamp:bv48;
var learner_standard_metadata.mcast_grp:bv16;
var learner_standard_metadata.egress_rid:bv16;
var learner_standard_metadata.checksum_error:bv1;
var learner_standard_metadata.parser_error:learner_error;
var learner_standard_metadata.priority:bv3;
type learner_CounterType = int;
type learner_MeterType = int;
type learner_HashAlgorithm = int;
type learner_CloneType = int;
type learner_EthernetAddress = bv48;
type learner_IPv4Address = bv32;
type learner_PortId = bv4;
type learner_ethernet_t;
type learner_arp_t;
type learner_ipv4_t;
type learner_icmp_t;
type learner_udp_t;
type learner_paxos_t;

// learner_Struct learner_headers
var learner_hdr:learner_Ref;

// learner_Header learner_ethernet_t
var learner_hdr.ethernet:learner_Ref;
var learner_hdr.ethernet.valid:bool;
var learner_hdr.ethernet.dstAddr:learner_EthernetAddress;
var learner_hdr.ethernet.srcAddr:learner_EthernetAddress;
var learner_hdr.ethernet.etherType:bv16;

// learner_Header learner_arp_t
var learner_hdr.arp:learner_Ref;
var learner_hdr.arp.valid:bool;
var learner_hdr.arp.hrd:bv16;
var learner_hdr.arp.pro:bv16;
var learner_hdr.arp.hln:bv8;
var learner_hdr.arp.pln:bv8;
var learner_hdr.arp.op:bv16;
var learner_hdr.arp.sha:bv48;
var learner_hdr.arp.spa:bv32;
var learner_hdr.arp.tha:bv48;
var learner_hdr.arp.tpa:bv32;

// learner_Header learner_ipv4_t
var learner_hdr.ipv4:learner_Ref;
var learner_hdr.ipv4.valid:bool;
var learner_hdr.ipv4.version:bv4;
var learner_hdr.ipv4.ihl:bv4;
var learner_hdr.ipv4.diffserv:bv8;
var learner_hdr.ipv4.totalLen:bv16;
var learner_hdr.ipv4.identification:bv16;
var learner_hdr.ipv4.flags:bv3;
var learner_hdr.ipv4.fragOffset:bv13;
var learner_hdr.ipv4.ttl:bv8;
var learner_hdr.ipv4.protocol:bv8;
var learner_hdr.ipv4.hdrChecksum:bv16;
var learner_hdr.ipv4.srcAddr:learner_IPv4Address;
var learner_hdr.ipv4.dstAddr:learner_IPv4Address;

// learner_Header learner_icmp_t
var learner_hdr.icmp:learner_Ref;
var learner_hdr.icmp.valid:bool;
var learner_hdr.icmp.icmpType:bv8;
var learner_hdr.icmp.icmpCode:bv8;
var learner_hdr.icmp.hdrChecksum:bv16;
var learner_hdr.icmp.identifier:bv16;
var learner_hdr.icmp.seqNumber:bv16;
var learner_hdr.icmp.payload:bv256;

// learner_Header learner_udp_t
var learner_hdr.udp:learner_Ref;
var learner_hdr.udp.valid:bool;
var learner_hdr.udp.srcPort:bv16;
var learner_hdr.udp.dstPort:bv16;
var learner_hdr.udp.length_:bv16;
var learner_hdr.udp.checksum:bv16;

// learner_Header learner_paxos_t
var learner_hdr.paxos:learner_Ref;
var learner_hdr.paxos.valid:bool;
var learner_hdr.paxos.msgtype:bv16;
var learner_hdr.paxos.inst:bv32;
var learner_hdr.paxos.rnd:bv16;
var learner_hdr.paxos.vrnd:bv16;
var learner_hdr.paxos.acptid:bv16;
var learner_hdr.paxos.paxoslen:bv32;
var learner_hdr.paxos.paxosval:bv256;

// learner_Struct learner_paxos_metadata_t
type learner_paxos_metadata_t;

// learner_Struct learner_metadata
type learner_metadata;
var learner_meta.paxos_metadata:learner_paxos_metadata_t;
var learner_meta.paxos_metadata.round:bv16;
var learner_meta.paxos_metadata.set_drop:bv1;
var learner_meta.paxos_metadata.ack_count:bv8;
var learner_meta.paxos_metadata.ack_acceptors:bv8;
var learner_meta:learner_metadata;
var learner_standard_metadata:learner_standard_metadata_t;
var learner_acptid_0:bv8;
var learner_acptid_1:bv8;

// learner_Register learner_ingress_registerRound
var learner_ingress_registerRound:[bv32]bv16;
var learner_ingress_registerRound__last_index:bv32;
var learner_ingress_registerRound__last_value:bv16;
var learner_ingress_registerRound__last_old_value:bv16;
var learner_ingress_registerRound__wrote_any:bool;
var learner_ingress_registerRound__wrote_index0:bool;
var learner_ingress_registerRound__last0_old_value:bv16;
var learner_ingress_registerRound__last0_value:bv16;
var learner_ingress_registerRound__next_write_site:int;
var learner_ingress_registerRound__last_write_site:int;
const learner_ingress_registerRound.size:bv32;
axiom learner_ingress_registerRound.size == 65536bv32;

// learner_Register learner_ingress_registerValue
var learner_ingress_registerValue:[bv32]bv256;
var learner_ingress_registerValue__last_index:bv32;
var learner_ingress_registerValue__last_value:bv256;
var learner_ingress_registerValue__last_old_value:bv256;
var learner_ingress_registerValue__wrote_any:bool;
var learner_ingress_registerValue__wrote_index0:bool;
var learner_ingress_registerValue__last0_old_value:bv256;
var learner_ingress_registerValue__last0_value:bv256;
var learner_ingress_registerValue__next_write_site:int;
var learner_ingress_registerValue__last_write_site:int;
const learner_ingress_registerValue.size:bv32;
axiom learner_ingress_registerValue.size == 65536bv32;

// learner_Register learner_ingress_registerHistory2B
var learner_ingress_registerHistory2B:[bv32]bv8;
var learner_ingress_registerHistory2B__last_index:bv32;
var learner_ingress_registerHistory2B__last_value:bv8;
var learner_ingress_registerHistory2B__last_old_value:bv8;
var learner_ingress_registerHistory2B__wrote_any:bool;
var learner_ingress_registerHistory2B__wrote_index0:bool;
var learner_ingress_registerHistory2B__last0_old_value:bv8;
var learner_ingress_registerHistory2B__last0_value:bv8;
var learner_ingress_registerHistory2B__next_write_site:int;
var learner_ingress_registerHistory2B__last_write_site:int;
const learner_ingress_registerHistory2B.size:bv32;
axiom learner_ingress_registerHistory2B.size == 65536bv32;

function {:builtin "bvshl"} shl.bv8(learner_left:bv8, learner_right:bv8) returns(bv8);

function {:builtin "bvor"} bor.bv8(learner_left:bv8, learner_right:bv8) returns(bv8);

// learner_Table learner_ingress_learner_tbl learner_Actionlist learner_Declaration
type learner_ingress_learner_tbl.action;
const unique learner_ingress_learner_tbl.action.ingress_handle_2b : learner_ingress_learner_tbl.action;
var learner_ingress_learner_tbl.action_run : learner_ingress_learner_tbl.action;
var learner_ingress_learner_tbl.hit : bool;

// learner_Table learner_ingress_reset_consensus_instance learner_Actionlist learner_Declaration
type learner_ingress_reset_consensus_instance.action;
const unique learner_ingress_reset_consensus_instance.action.ingress_handle_new_value : learner_ingress_reset_consensus_instance.action;
var learner_ingress_reset_consensus_instance.action_run : learner_ingress_reset_consensus_instance.action;
var learner_ingress_reset_consensus_instance.hit : bool;

// learner_Table learner_ingress_transport_tbl learner_Actionlist learner_Declaration
type learner_ingress_transport_tbl.action;
var learner_ingress_transport_tbl.ingress_forward.port:learner_PortId;
var learner_ingress_transport_tbl.ingress_forward.learnerPort:bv16;
const unique learner_ingress_transport_tbl.action.ingress_drop : learner_ingress_transport_tbl.action;
const unique learner_ingress_transport_tbl.action.ingress_forward : learner_ingress_transport_tbl.action;
var learner_ingress_transport_tbl.action_run : learner_ingress_transport_tbl.action;
var learner_ingress_transport_tbl.hit : bool;

function {:builtin "bvugt"} bugt.bv16(learner_left:bv16, learner_right:bv16) returns(bool);

function {:builtin "bvule"} bule.bv8(learner_left:bv8, learner_right:bv8) returns(bool);

// learner_Table learner_egress_place_holder_table learner_Actionlist learner_Declaration
type learner_egress_place_holder_table.action;
const unique learner_egress_place_holder_table.action.NoAction : learner_egress_place_holder_table.action;
var learner_egress_place_holder_table.action_run : learner_egress_place_holder_table.action;
var learner_egress_place_holder_table.hit : bool;

function {:builtin "bvsub"} sub.bv17(learner_left:bv17, learner_right:bv17) returns(bv17);

function {:builtin "bvsub"} sub.bv33(learner_left:bv33, learner_right:bv33) returns(bv33);

// learner_Action learner_NoAction
procedure {:inline 1} learner_NoAction()
{
}

// learner_Parser learner_TopParser
procedure {:inline 1} learner_TopParser()
	modifies learner_drop, learner_isValid;
{
    goto learner_State$TopParser$start;

        learner_State$TopParser$start:
    call learner_packet_in.extract(learner_hdr.ethernet);
    goto learner_State$TopParser$start$parse_arp_2, learner_State$TopParser$start$parse_ipv4_1, learner_State$TopParser$start$DEFAULT;
    
learner_State$TopParser$start$parse_arp_2:
    assume (learner_hdr.ethernet.etherType == 2054bv16);
    goto learner_State$TopParser$parse_arp;
    
learner_State$TopParser$start$parse_ipv4_1:
    assume (learner_hdr.ethernet.etherType == 2048bv16);
    goto learner_State$TopParser$parse_ipv4;

    learner_State$TopParser$start$DEFAULT:
    assume(!(learner_hdr.ethernet.etherType == 2054bv16)&&!(learner_hdr.ethernet.etherType == 2048bv16));
goto learner_State$reject;

        learner_State$TopParser$parse_arp:
    call learner_packet_in.extract(learner_hdr.arp);
    goto learner_State$accept;

        learner_State$TopParser$parse_ipv4:
    call learner_packet_in.extract(learner_hdr.ipv4);
    goto learner_State$TopParser$parse_ipv4$parse_icmp_3, learner_State$TopParser$parse_ipv4$parse_udp_2, learner_State$TopParser$parse_ipv4$DEFAULT;
    
learner_State$TopParser$parse_ipv4$parse_icmp_3:
    assume (learner_hdr.ipv4.protocol == 1bv8);
    goto learner_State$TopParser$parse_icmp;
    
learner_State$TopParser$parse_ipv4$parse_udp_2:
    assume (learner_hdr.ipv4.protocol == 17bv8);
    goto learner_State$TopParser$parse_udp;

    learner_State$TopParser$parse_ipv4$DEFAULT:
    assume(!(learner_hdr.ipv4.protocol == 1bv8)&&!(learner_hdr.ipv4.protocol == 17bv8));
    goto learner_State$accept;

        learner_State$TopParser$parse_icmp:
    call learner_packet_in.extract(learner_hdr.icmp);
    goto learner_State$accept;

        learner_State$TopParser$parse_udp:
    call learner_packet_in.extract(learner_hdr.udp);
    goto learner_State$TopParser$parse_udp$parse_paxos_2, learner_State$TopParser$parse_udp$DEFAULT;
    
learner_State$TopParser$parse_udp$parse_paxos_2:
    assume (learner_hdr.udp.dstPort == 34952bv16);
    goto learner_State$TopParser$parse_paxos;

    learner_State$TopParser$parse_udp$DEFAULT:
    assume(!(learner_hdr.udp.dstPort == 34952bv16));
    goto learner_State$accept;

        learner_State$TopParser$parse_paxos:
    call learner_packet_in.extract(learner_hdr.paxos);
    goto learner_State$accept;

    learner_State$accept:
    call learner_accept();
    goto learner_Exit;

    learner_State$reject:
    call learner_reject();
    goto learner_Exit;

    learner_Exit:
}
procedure {:inline 1} learner_accept()
{
}

// learner_Control learner_computeChecksum
procedure {:inline 1} learner_computeChecksum()
	modifies learner_hdr.ipv4.hdrChecksum, learner_p4b_checksum_updated;
{
    if (learner_isValid[learner_hdr.ipv4]) {
        learner_p4b_checksum_updated := true;
        havoc learner_hdr.ipv4.hdrChecksum;
    }
}

// learner_Control learner_egress
procedure {:inline 1} learner_egress()
	modifies learner_egress_place_holder_table.action_run, learner_egress_place_holder_table.hit;
{
    call learner_egress_place_holder_table.apply();
}

// learner_Table learner_egress_place_holder_table
procedure {:inline 1} learner_egress_place_holder_table.apply()
	modifies learner_egress_place_holder_table.action_run, learner_egress_place_holder_table.hit;
{
    learner_egress_place_holder_table.hit := false;
    learner_egress_place_holder_table.action_run := learner_egress_place_holder_table.action.NoAction;
    call learner_NoAction();
    goto learner_Exit;

    learner_Exit:
}

// learner_Control learner_ingress
procedure {:inline 1} learner_ingress()
	modifies learner_acptid_0, learner_acptid_1, learner_drop, learner_forward, learner_hdr.paxos.msgtype, learner_hdr.udp.dstPort, learner_ingress_learner_tbl.action_run, learner_ingress_learner_tbl.hit, learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__next_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_index0, learner_ingress_registerRound, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__next_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_index0, learner_ingress_registerValue, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__next_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_index0, learner_ingress_reset_consensus_instance.action_run, learner_ingress_reset_consensus_instance.hit, learner_ingress_transport_tbl.action_run, learner_ingress_transport_tbl.hit, learner_ingress_transport_tbl.ingress_forward.learnerPort, learner_ingress_transport_tbl.ingress_forward.port, learner_meta.paxos_metadata.ack_acceptors, learner_meta.paxos_metadata.round, learner_meta.paxos_metadata.set_drop, learner_standard_metadata.egress_port, learner_standard_metadata.egress_spec;
{
havoc learner_acptid_0;
havoc learner_acptid_1;
    if(learner_isValid[learner_hdr.ipv4]){
        if(learner_isValid[learner_hdr.paxos]){
            assume (((learner_hdr.paxos.acptid == 0bv16)) || ((learner_hdr.paxos.acptid == 1bv16))) || ((learner_hdr.paxos.acptid == 2bv16));
            call learner_ingress_read_round();
            if(bugt.bv16(learner_hdr.paxos.rnd, learner_meta.paxos_metadata.round)){
                call learner_ingress_reset_consensus_instance.apply();
            }
            else{
                if((learner_hdr.paxos.rnd == learner_meta.paxos_metadata.round)){
                    call learner_ingress_learner_tbl.apply();
                }
            }
            if((((learner_meta.paxos_metadata.ack_acceptors == 6bv8)) || ((learner_meta.paxos_metadata.ack_acceptors == 5bv8))) || ((learner_meta.paxos_metadata.ack_acceptors == 3bv8))){
                call learner_ingress_transport_tbl.apply();
            }
            assert bule.bv8(learner_meta.paxos_metadata.ack_acceptors, 7bv8);
        }
    }
}

// learner_Action learner_ingress_drop
procedure {:inline 1} learner_ingress_drop()
	modifies learner_drop;
{
    call learner_mark_to_drop();
}

// learner_Action learner_ingress_forward
procedure {:inline 1} learner_ingress_forward(learner_port:learner_PortId, learner_learnerPort:bv16)
	modifies learner_forward, learner_hdr.udp.dstPort, learner_standard_metadata.egress_port, learner_standard_metadata.egress_spec;
{
    learner_standard_metadata.egress_spec := 0bv5++learner_port;
    learner_standard_metadata.egress_port := 0bv5++learner_port;
    learner_forward := true;
    learner_hdr.udp.dstPort := learner_learnerPort;
}

// learner_Action learner_ingress_handle_2b
procedure {:inline 1} learner_ingress_handle_2b()
	modifies learner_acptid_0, learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__next_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_index0, learner_ingress_registerRound, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__next_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_index0, learner_ingress_registerValue, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__next_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_index0, learner_meta.paxos_metadata.ack_acceptors;
{
    // learner_write
    learner_ingress_registerRound__next_write_site := 1;
    call learner_ingress_registerRound.write(learner_hdr.paxos.inst, learner_hdr.paxos.rnd);
    // learner_write
    learner_ingress_registerValue__next_write_site := 1;
    call learner_ingress_registerValue.write(learner_hdr.paxos.inst, learner_hdr.paxos.paxosval);
    learner_acptid_0 := shl.bv8(1bv8, learner_hdr.paxos.acptid[8:0]);
    learner_meta.paxos_metadata.ack_acceptors := bor.bv8(learner_meta.paxos_metadata.ack_acceptors, learner_acptid_0);
    // learner_write
    learner_ingress_registerHistory2B__next_write_site := 1;
    call learner_ingress_registerHistory2B.write(learner_hdr.paxos.inst, learner_meta.paxos_metadata.ack_acceptors);
}

// learner_Action learner_ingress_handle_new_value
procedure {:inline 1} learner_ingress_handle_new_value()
	modifies learner_acptid_1, learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__next_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_index0, learner_ingress_registerRound, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__next_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_index0, learner_ingress_registerValue, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__next_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_index0;
{
    // learner_write
    learner_ingress_registerRound__next_write_site := 2;
    call learner_ingress_registerRound.write(learner_hdr.paxos.inst, learner_hdr.paxos.rnd);
    // learner_write
    learner_ingress_registerValue__next_write_site := 2;
    call learner_ingress_registerValue.write(learner_hdr.paxos.inst, learner_hdr.paxos.paxosval);
    learner_acptid_1 := shl.bv8(1bv8, learner_hdr.paxos.acptid[8:0]);
    // learner_write
    learner_ingress_registerHistory2B__next_write_site := 2;
    call learner_ingress_registerHistory2B.write(learner_hdr.paxos.inst, learner_acptid_1);
}

// learner_Table learner_ingress_learner_tbl
procedure {:inline 1} learner_ingress_learner_tbl.apply()
	modifies learner_acptid_0, learner_hdr.paxos.msgtype, learner_ingress_learner_tbl.action_run, learner_ingress_learner_tbl.hit, learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__next_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_index0, learner_ingress_registerRound, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__next_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_index0, learner_ingress_registerValue, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__next_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_index0, learner_meta.paxos_metadata.ack_acceptors;
{
    learner_hdr.paxos.msgtype := learner_hdr.paxos.msgtype;
    learner_ingress_learner_tbl.hit := false;
    if(learner_hdr.paxos.msgtype == 3bv16){
        learner_ingress_learner_tbl.hit := true;
        learner_ingress_learner_tbl.action_run := learner_ingress_learner_tbl.action.ingress_handle_2b;
        call learner_ingress_handle_2b();
        goto learner_Exit;
    }
    if(!learner_ingress_learner_tbl.hit){
        learner_ingress_learner_tbl.action_run := learner_ingress_learner_tbl.action.ingress_handle_2b;
        call learner_ingress_handle_2b();
        goto learner_Exit;
    }

    learner_Exit:
}

// learner_Action learner_ingress_read_round
procedure {:inline 1} learner_ingress_read_round()
	modifies learner_meta.paxos_metadata.ack_acceptors, learner_meta.paxos_metadata.round, learner_meta.paxos_metadata.set_drop;
{
    // learner_read
    learner_meta.paxos_metadata.round := learner_ingress_registerRound.read(learner_ingress_registerRound, learner_hdr.paxos.inst);
    learner_meta.paxos_metadata.set_drop := 0bv1;
    // learner_read
    learner_meta.paxos_metadata.ack_acceptors := learner_ingress_registerHistory2B.read(learner_ingress_registerHistory2B, learner_hdr.paxos.inst);
}
function {:inline true}learner_ingress_registerHistory2B.read(learner_reg:[bv32]bv8, learner_index:bv32)returns (bv8) {learner_reg[learner_index]}
procedure {:inline 1} learner_ingress_registerHistory2B.write(learner_index:bv32, learner_value:bv8)
	modifies learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_index0;
{
    learner_ingress_registerHistory2B__last_old_value := learner_ingress_registerHistory2B[learner_index];
    learner_ingress_registerHistory2B[learner_index] := learner_value;
    learner_ingress_registerHistory2B__last_index := learner_index;
    learner_ingress_registerHistory2B__last_value := learner_value;
    learner_ingress_registerHistory2B__last_write_site := learner_ingress_registerHistory2B__next_write_site;
    learner_ingress_registerHistory2B__wrote_any := true;
    if (learner_index == 0bv32) {
        learner_ingress_registerHistory2B__wrote_index0 := true;
        learner_ingress_registerHistory2B__last0_old_value := learner_ingress_registerHistory2B__last_old_value;
        learner_ingress_registerHistory2B__last0_value := learner_value;
    }
}
function {:inline true}learner_ingress_registerRound.read(learner_reg:[bv32]bv16, learner_index:bv32)returns (bv16) {learner_reg[learner_index]}
procedure {:inline 1} learner_ingress_registerRound.write(learner_index:bv32, learner_value:bv16)
	modifies learner_ingress_registerRound, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_index0;
{
    learner_ingress_registerRound__last_old_value := learner_ingress_registerRound[learner_index];
    learner_ingress_registerRound[learner_index] := learner_value;
    learner_ingress_registerRound__last_index := learner_index;
    learner_ingress_registerRound__last_value := learner_value;
    learner_ingress_registerRound__last_write_site := learner_ingress_registerRound__next_write_site;
    learner_ingress_registerRound__wrote_any := true;
    if (learner_index == 0bv32) {
        learner_ingress_registerRound__wrote_index0 := true;
        learner_ingress_registerRound__last0_old_value := learner_ingress_registerRound__last_old_value;
        learner_ingress_registerRound__last0_value := learner_value;
    }
}
function {:inline true}learner_ingress_registerValue.read(learner_reg:[bv32]bv256, learner_index:bv32)returns (bv256) {learner_reg[learner_index]}
procedure {:inline 1} learner_ingress_registerValue.write(learner_index:bv32, learner_value:bv256)
	modifies learner_ingress_registerValue, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_index0;
{
    learner_ingress_registerValue__last_old_value := learner_ingress_registerValue[learner_index];
    learner_ingress_registerValue[learner_index] := learner_value;
    learner_ingress_registerValue__last_index := learner_index;
    learner_ingress_registerValue__last_value := learner_value;
    learner_ingress_registerValue__last_write_site := learner_ingress_registerValue__next_write_site;
    learner_ingress_registerValue__wrote_any := true;
    if (learner_index == 0bv32) {
        learner_ingress_registerValue__wrote_index0 := true;
        learner_ingress_registerValue__last0_old_value := learner_ingress_registerValue__last_old_value;
        learner_ingress_registerValue__last0_value := learner_value;
    }
}

// learner_Table learner_ingress_reset_consensus_instance
procedure {:inline 1} learner_ingress_reset_consensus_instance.apply()
	modifies learner_acptid_1, learner_hdr.paxos.msgtype, learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__next_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_index0, learner_ingress_registerRound, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__next_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_index0, learner_ingress_registerValue, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__next_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_index0, learner_ingress_reset_consensus_instance.action_run, learner_ingress_reset_consensus_instance.hit;
{
    learner_hdr.paxos.msgtype := learner_hdr.paxos.msgtype;
    learner_ingress_reset_consensus_instance.hit := false;
    learner_ingress_reset_consensus_instance.action_run := learner_ingress_reset_consensus_instance.action.ingress_handle_new_value;
    call learner_ingress_handle_new_value();
    goto learner_Exit;

    learner_action_ingress_handle_new_value:
    assume learner_ingress_reset_consensus_instance.action_run == learner_ingress_reset_consensus_instance.action.ingress_handle_new_value;
    call learner_ingress_handle_new_value();
    goto learner_Exit;

    learner_Exit:
}

// learner_Table learner_ingress_transport_tbl
procedure {:inline 1} learner_ingress_transport_tbl.apply()
	modifies learner_drop, learner_forward, learner_hdr.udp.dstPort, learner_ingress_transport_tbl.action_run, learner_ingress_transport_tbl.hit, learner_ingress_transport_tbl.ingress_forward.learnerPort, learner_ingress_transport_tbl.ingress_forward.port, learner_meta.paxos_metadata.set_drop, learner_standard_metadata.egress_port, learner_standard_metadata.egress_spec;
{
    learner_meta.paxos_metadata.set_drop := learner_meta.paxos_metadata.set_drop;
    learner_ingress_transport_tbl.hit := false;
    if(learner_meta.paxos_metadata.set_drop == 1bv1){
        learner_ingress_transport_tbl.hit := true;
        learner_ingress_transport_tbl.action_run := learner_ingress_transport_tbl.action.ingress_drop;
        call learner_ingress_drop();
        goto learner_Exit;
    }
    else if(learner_meta.paxos_metadata.set_drop == 0bv1){
        learner_ingress_transport_tbl.hit := true;
        learner_ingress_transport_tbl.action_run := learner_ingress_transport_tbl.action.ingress_forward;
        learner_ingress_transport_tbl.ingress_forward.port := 1bv4;
        learner_ingress_transport_tbl.ingress_forward.learnerPort := 34952bv16;
        call learner_ingress_forward(learner_ingress_transport_tbl.ingress_forward.port, learner_ingress_transport_tbl.ingress_forward.learnerPort);
        goto learner_Exit;
    }
    if(!learner_ingress_transport_tbl.hit){
        learner_ingress_transport_tbl.action_run := learner_ingress_transport_tbl.action.ingress_drop;
        call learner_ingress_drop();
        goto learner_Exit;
    }

    learner_Exit:
}
procedure {:inline 1} learner_main()
	modifies learner_acptid_0, learner_acptid_1, learner_drop, learner_egress_place_holder_table.action_run, learner_egress_place_holder_table.hit, learner_forward, learner_hdr.ipv4.hdrChecksum, learner_hdr.paxos.msgtype, learner_hdr.udp.dstPort, learner_ingress_learner_tbl.action_run, learner_ingress_learner_tbl.hit, learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__next_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_index0, learner_ingress_registerRound, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__next_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_index0, learner_ingress_registerValue, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__next_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_index0, learner_ingress_reset_consensus_instance.action_run, learner_ingress_reset_consensus_instance.hit, learner_ingress_transport_tbl.action_run, learner_ingress_transport_tbl.hit, learner_ingress_transport_tbl.ingress_forward.learnerPort, learner_ingress_transport_tbl.ingress_forward.port, learner_isValid, learner_meta.paxos_metadata.ack_acceptors, learner_meta.paxos_metadata.round, learner_meta.paxos_metadata.set_drop, learner_p4b_checksum_updated, learner_standard_metadata.egress_port, learner_standard_metadata.egress_spec;
{
    call learner_TopParser();
    call learner_verifyChecksum();
    call learner_ingress();
    call learner_egress();
    call learner_computeChecksum();
    if(learner_forward == false){
        learner_drop := true;
    }
}
procedure learner_mainProcedure()
	modifies learner_acptid_0, learner_acptid_1, learner_drop, learner_egress_place_holder_table.action_run, learner_egress_place_holder_table.hit, learner_forward, learner_hdr.ipv4.hdrChecksum, learner_hdr.paxos.msgtype, learner_hdr.udp.dstPort, learner_ingress_learner_tbl.action_run, learner_ingress_learner_tbl.hit, learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__next_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_index0, learner_ingress_registerRound, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__next_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_index0, learner_ingress_registerValue, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__next_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_index0, learner_ingress_reset_consensus_instance.action_run, learner_ingress_reset_consensus_instance.hit, learner_ingress_transport_tbl.action_run, learner_ingress_transport_tbl.hit, learner_ingress_transport_tbl.ingress_forward.learnerPort, learner_ingress_transport_tbl.ingress_forward.port, learner_isValid, learner_meta.paxos_metadata.ack_acceptors, learner_meta.paxos_metadata.round, learner_meta.paxos_metadata.set_drop, learner_p4b_checksum_error, learner_p4b_checksum_updated, learner_p4b_checksum_verified, learner_p4b_clone_e2e, learner_p4b_clone_i2e, learner_p4b_clone_i2i, learner_p4b_digest, learner_p4b_recirculate, learner_standard_metadata.egress_port, learner_standard_metadata.egress_spec;
{
    learner_p4b_checksum_error := false;
    learner_p4b_checksum_updated := false;
    learner_p4b_checksum_verified := false;
    learner_p4b_digest := false;
    learner_p4b_recirculate := false;
    learner_p4b_clone_i2i := false;
    learner_p4b_clone_e2e := false;
    learner_p4b_clone_i2e := false;
    call learner_main();
}
procedure learner_mark_to_drop();
    ensures learner_drop==true;
	modifies learner_drop;
procedure learner_packet.emit(learner_arg0:learner_Ref);
procedure learner_packet_in.extract(learner_header:learner_Ref);
    ensures (learner_isValid[learner_header] == true);
	modifies learner_isValid;
procedure learner_reject();
    ensures learner_drop==true;
	modifies learner_drop;
procedure {:inline 1} learner_setInvalid(learner_header:learner_Ref);
    ensures (learner_isValid[learner_header] == false);
	modifies learner_isValid;
procedure {:inline 1} learner_setValid(learner_header:learner_Ref);

// learner_Control learner_verifyChecksum
procedure {:inline 1} learner_verifyChecksum()
{
}
// ===== END NODE learner =====

// ===== BEGIN ENQUEUE PROCEDURES =====
// ===== END ENQUEUE PROCEDURES =====

// ===== BEGIN HARNESS =====
// Auto-generated by Procurator (DSL -> Boogie harness: sequential scheduler)
// Message abstraction: Bag(K=1) using inbox_count per node; single-slot mailbox for packet fields

var procurator_step: int;
var procurator_bad: bool;

// DSL state variables (modeled as Boogie globals)
var dsl_phase: int;
var dsl_reset_epoch: int;
var learner_dsl_seen_a0: bool;
var learner_dsl_seen_a1: bool;
var learner_dsl_seen_a2: bool;
var learner_dsl_seen_epoch: int;
var learner_dsl_vote_cnt: int;

// Register debug snapshots (for trace inspection)
var learner_ingress_registerHistory2B__dbg0: bv8;
var learner_ingress_registerHistory2B__last_index__dbg: bv32;
var learner_ingress_registerHistory2B__last_value__dbg: bv8;
var learner_ingress_registerHistory2B__last_old_value__dbg: bv8;
var learner_ingress_registerHistory2B__wrote_any__dbg: bool;
var learner_ingress_registerHistory2B__wrote_index0__dbg: bool;
var learner_ingress_registerHistory2B__last0_old_value__dbg: bv8;
var learner_ingress_registerHistory2B__last0_value__dbg: bv8;
var learner_ingress_registerRound__dbg0: bv16;
var learner_ingress_registerRound__last_index__dbg: bv32;
var learner_ingress_registerRound__last_value__dbg: bv16;
var learner_ingress_registerRound__last_old_value__dbg: bv16;
var learner_ingress_registerRound__wrote_any__dbg: bool;
var learner_ingress_registerRound__wrote_index0__dbg: bool;
var learner_ingress_registerRound__last0_old_value__dbg: bv16;
var learner_ingress_registerRound__last0_value__dbg: bv16;
var learner_ingress_registerValue__dbg0: bv256;
var learner_ingress_registerValue__last_index__dbg: bv32;
var learner_ingress_registerValue__last_value__dbg: bv256;
var learner_ingress_registerValue__last_old_value__dbg: bv256;
var learner_ingress_registerValue__wrote_any__dbg: bool;
var learner_ingress_registerValue__wrote_index0__dbg: bool;
var learner_ingress_registerValue__last0_old_value__dbg: bv256;
var learner_ingress_registerValue__last0_value__dbg: bv256;

var learner_inbox_count: int;
var client_inbox_count: int;

var learner_pkt_external: bool;
var client_pkt_external: bool;

// Host packet fields (mirrors connected node symbols)
var client_standard_metadata.ingress_port: bv9;
var client_standard_metadata.instance_type: bv32;
var client_standard_metadata.packet_length: bv32;
var client_standard_metadata.enq_timestamp: bv32;
var client_standard_metadata.enq_qdepth: bv19;
var client_standard_metadata.deq_timedelta: bv32;
var client_standard_metadata.deq_qdepth: bv19;
var client_standard_metadata.ingress_global_timestamp: bv48;
var client_standard_metadata.egress_global_timestamp: bv48;
var client_standard_metadata.mcast_grp: bv16;
var client_standard_metadata.egress_rid: bv16;
var client_standard_metadata.checksum_error: bv1;
var client_standard_metadata.parser_error: learner_error;
var client_standard_metadata.priority: bv3;
var client_hdr.ethernet.valid: bool;
var client_hdr.ethernet.dstAddr: learner_EthernetAddress;
var client_hdr.ethernet.srcAddr: learner_EthernetAddress;
var client_hdr.ethernet.etherType: bv16;
var client_hdr.arp.valid: bool;
var client_hdr.arp.hrd: bv16;
var client_hdr.arp.pro: bv16;
var client_hdr.arp.hln: bv8;
var client_hdr.arp.pln: bv8;
var client_hdr.arp.op: bv16;
var client_hdr.arp.sha: bv48;
var client_hdr.arp.spa: bv32;
var client_hdr.arp.tha: bv48;
var client_hdr.arp.tpa: bv32;
var client_hdr.ipv4.valid: bool;
var client_hdr.ipv4.version: bv4;
var client_hdr.ipv4.ihl: bv4;
var client_hdr.ipv4.diffserv: bv8;
var client_hdr.ipv4.totalLen: bv16;
var client_hdr.ipv4.identification: bv16;
var client_hdr.ipv4.flags: bv3;
var client_hdr.ipv4.fragOffset: bv13;
var client_hdr.ipv4.ttl: bv8;
var client_hdr.ipv4.protocol: bv8;
var client_hdr.ipv4.hdrChecksum: bv16;
var client_hdr.ipv4.srcAddr: learner_IPv4Address;
var client_hdr.ipv4.dstAddr: learner_IPv4Address;
var client_hdr.icmp.valid: bool;
var client_hdr.icmp.icmpType: bv8;
var client_hdr.icmp.icmpCode: bv8;
var client_hdr.icmp.hdrChecksum: bv16;
var client_hdr.icmp.identifier: bv16;
var client_hdr.icmp.seqNumber: bv16;
var client_hdr.icmp.payload: bv256;
var client_hdr.udp.valid: bool;
var client_hdr.udp.srcPort: bv16;
var client_hdr.udp.dstPort: bv16;
var client_hdr.udp.length_: bv16;
var client_hdr.udp.checksum: bv16;
var client_hdr.paxos.valid: bool;
var client_hdr.paxos.msgtype: bv16;
var client_hdr.paxos.inst: bv32;
var client_hdr.paxos.rnd: bv16;
var client_hdr.paxos.vrnd: bv16;
var client_hdr.paxos.acptid: bv16;
var client_hdr.paxos.paxoslen: bv32;
var client_hdr.paxos.paxosval: bv256;
var client_meta.paxos_metadata: learner_paxos_metadata_t;
var client_meta.paxos_metadata.round: bv16;
var client_meta.paxos_metadata.set_drop: bv1;
var client_meta.paxos_metadata.ack_count: bv8;
var client_meta.paxos_metadata.ack_acceptors: bv8;

// Forwarding (derived from DSL topology)
procedure learner_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (learner_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure mainProcedure() returns()
  modifies client_hdr.arp.hln, client_hdr.arp.hrd, client_hdr.arp.op, client_hdr.arp.pln, client_hdr.arp.pro, client_hdr.arp.sha, client_hdr.arp.spa, client_hdr.arp.tha, client_hdr.arp.tpa, client_hdr.arp.valid, client_hdr.ethernet.dstAddr, client_hdr.ethernet.etherType, client_hdr.ethernet.srcAddr, client_hdr.ethernet.valid, client_hdr.icmp.hdrChecksum, client_hdr.icmp.icmpCode, client_hdr.icmp.icmpType, client_hdr.icmp.identifier, client_hdr.icmp.payload, client_hdr.icmp.seqNumber, client_hdr.icmp.valid, client_hdr.ipv4.diffserv, client_hdr.ipv4.dstAddr, client_hdr.ipv4.flags, client_hdr.ipv4.fragOffset, client_hdr.ipv4.hdrChecksum, client_hdr.ipv4.identification, client_hdr.ipv4.ihl, client_hdr.ipv4.protocol, client_hdr.ipv4.srcAddr, client_hdr.ipv4.totalLen, client_hdr.ipv4.ttl, client_hdr.ipv4.valid, client_hdr.ipv4.version, client_hdr.paxos.acptid, client_hdr.paxos.inst, client_hdr.paxos.msgtype, client_hdr.paxos.paxoslen, client_hdr.paxos.paxosval, client_hdr.paxos.rnd, client_hdr.paxos.valid, client_hdr.paxos.vrnd, client_hdr.udp.checksum, client_hdr.udp.dstPort, client_hdr.udp.length_, client_hdr.udp.srcPort, client_hdr.udp.valid, client_inbox_count, client_meta.paxos_metadata, client_meta.paxos_metadata.ack_acceptors, client_meta.paxos_metadata.ack_count, client_meta.paxos_metadata.round, client_meta.paxos_metadata.set_drop, client_pkt_external, client_standard_metadata.checksum_error, client_standard_metadata.deq_qdepth, client_standard_metadata.deq_timedelta, client_standard_metadata.egress_global_timestamp, client_standard_metadata.egress_rid, client_standard_metadata.enq_qdepth, client_standard_metadata.enq_timestamp, client_standard_metadata.ingress_global_timestamp, client_standard_metadata.ingress_port, client_standard_metadata.instance_type, client_standard_metadata.mcast_grp, client_standard_metadata.packet_length, client_standard_metadata.parser_error, client_standard_metadata.priority, dsl_phase, dsl_reset_epoch, learner_acptid_0, learner_acptid_1, learner_drop, learner_dsl_seen_a0, learner_dsl_seen_a1, learner_dsl_seen_a2, learner_dsl_seen_epoch, learner_dsl_vote_cnt, learner_egress_place_holder_table.action_run, learner_egress_place_holder_table.hit, learner_forward, learner_hdr.arp.hln, learner_hdr.arp.hrd, learner_hdr.arp.op, learner_hdr.arp.pln, learner_hdr.arp.pro, learner_hdr.arp.sha, learner_hdr.arp.spa, learner_hdr.arp.tha, learner_hdr.arp.tpa, learner_hdr.arp.valid, learner_hdr.ethernet.dstAddr, learner_hdr.ethernet.etherType, learner_hdr.ethernet.srcAddr, learner_hdr.ethernet.valid, learner_hdr.icmp.hdrChecksum, learner_hdr.icmp.icmpCode, learner_hdr.icmp.icmpType, learner_hdr.icmp.identifier, learner_hdr.icmp.payload, learner_hdr.icmp.seqNumber, learner_hdr.icmp.valid, learner_hdr.ipv4.diffserv, learner_hdr.ipv4.dstAddr, learner_hdr.ipv4.flags, learner_hdr.ipv4.fragOffset, learner_hdr.ipv4.hdrChecksum, learner_hdr.ipv4.identification, learner_hdr.ipv4.ihl, learner_hdr.ipv4.protocol, learner_hdr.ipv4.srcAddr, learner_hdr.ipv4.totalLen, learner_hdr.ipv4.ttl, learner_hdr.ipv4.valid, learner_hdr.ipv4.version, learner_hdr.paxos.acptid, learner_hdr.paxos.inst, learner_hdr.paxos.msgtype, learner_hdr.paxos.paxoslen, learner_hdr.paxos.paxosval, learner_hdr.paxos.rnd, learner_hdr.paxos.valid, learner_hdr.paxos.vrnd, learner_hdr.udp.checksum, learner_hdr.udp.dstPort, learner_hdr.udp.length_, learner_hdr.udp.srcPort, learner_hdr.udp.valid, learner_inbox_count, learner_ingress_learner_tbl.action_run, learner_ingress_learner_tbl.hit, learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__dbg0, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_old_value__dbg, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last0_value__dbg, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_index__dbg, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_old_value__dbg, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_value__dbg, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__next_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_any__dbg, learner_ingress_registerHistory2B__wrote_index0, learner_ingress_registerHistory2B__wrote_index0__dbg, learner_ingress_registerRound, learner_ingress_registerRound__dbg0, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_old_value__dbg, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last0_value__dbg, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_index__dbg, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_old_value__dbg, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_value__dbg, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__next_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_any__dbg, learner_ingress_registerRound__wrote_index0, learner_ingress_registerRound__wrote_index0__dbg, learner_ingress_registerValue, learner_ingress_registerValue__dbg0, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_old_value__dbg, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last0_value__dbg, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_index__dbg, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_old_value__dbg, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_value__dbg, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__next_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_any__dbg, learner_ingress_registerValue__wrote_index0, learner_ingress_registerValue__wrote_index0__dbg, learner_ingress_reset_consensus_instance.action_run, learner_ingress_reset_consensus_instance.hit, learner_ingress_transport_tbl.action_run, learner_ingress_transport_tbl.hit, learner_ingress_transport_tbl.ingress_forward.learnerPort, learner_ingress_transport_tbl.ingress_forward.port, learner_isValid, learner_meta.paxos_metadata, learner_meta.paxos_metadata.ack_acceptors, learner_meta.paxos_metadata.ack_count, learner_meta.paxos_metadata.round, learner_meta.paxos_metadata.set_drop, learner_p4b_checksum_error, learner_p4b_checksum_updated, learner_p4b_checksum_verified, learner_p4b_clone_e2e, learner_p4b_clone_i2e, learner_p4b_clone_i2i, learner_p4b_digest, learner_p4b_recirculate, learner_pkt_external, learner_standard_metadata.checksum_error, learner_standard_metadata.deq_qdepth, learner_standard_metadata.deq_timedelta, learner_standard_metadata.egress_global_timestamp, learner_standard_metadata.egress_port, learner_standard_metadata.egress_rid, learner_standard_metadata.egress_spec, learner_standard_metadata.enq_qdepth, learner_standard_metadata.enq_timestamp, learner_standard_metadata.ingress_global_timestamp, learner_standard_metadata.ingress_port, learner_standard_metadata.instance_type, learner_standard_metadata.mcast_grp, learner_standard_metadata.packet_length, learner_standard_metadata.parser_error, learner_standard_metadata.priority, procurator_bad, procurator_step;
{
  // initialize inboxes
  learner_inbox_count := 0;
  learner_pkt_external := false;
  client_inbox_count := 0;
  client_pkt_external := false;
  // initialize P4B event flags (clone/recirculate)
  learner_p4b_clone_i2e := false;
  learner_p4b_clone_e2e := false;
  learner_p4b_clone_i2i := false;
  learner_p4b_recirculate := false;

  // initialize DSL state
  dsl_phase := 0;
  dsl_reset_epoch := 0;
  learner_dsl_seen_epoch := 0;
  learner_dsl_seen_a0 := false;
  learner_dsl_seen_a1 := false;
  learner_dsl_seen_a2 := false;
  learner_dsl_vote_cnt := 0;
  // initialize P4 registers (default 0)
  assume (forall i:bv32 :: learner_ingress_registerHistory2B[i] == 0bv8);
  assume learner_ingress_registerHistory2B[0bv32] == 0bv8;
  assume (forall i:bv32 :: learner_ingress_registerRound[i] == 0bv16);
  assume learner_ingress_registerRound[0bv32] == 0bv16;
  assume (forall i:bv32 :: learner_ingress_registerValue[i] == 0bv256);
  assume learner_ingress_registerValue[0bv32] == 0bv256;
  // initialize register write tracking (debug)
  learner_ingress_registerHistory2B__last_index := 0bv32;
  learner_ingress_registerHistory2B__last_value := 0bv8;
  learner_ingress_registerHistory2B__last_old_value := 0bv8;
  learner_ingress_registerHistory2B__wrote_any := false;
  learner_ingress_registerHistory2B__wrote_index0 := false;
  learner_ingress_registerHistory2B__next_write_site := 0;
  learner_ingress_registerHistory2B__last_write_site := 0;
  learner_ingress_registerHistory2B__last0_old_value := 0bv8;
  learner_ingress_registerHistory2B__last0_value := 0bv8;
  learner_ingress_registerRound__last_index := 0bv32;
  learner_ingress_registerRound__last_value := 0bv16;
  learner_ingress_registerRound__last_old_value := 0bv16;
  learner_ingress_registerRound__wrote_any := false;
  learner_ingress_registerRound__wrote_index0 := false;
  learner_ingress_registerRound__next_write_site := 0;
  learner_ingress_registerRound__last_write_site := 0;
  learner_ingress_registerRound__last0_old_value := 0bv16;
  learner_ingress_registerRound__last0_value := 0bv16;
  learner_ingress_registerValue__last_index := 0bv32;
  learner_ingress_registerValue__last_value := 0bv256;
  learner_ingress_registerValue__last_old_value := 0bv256;
  learner_ingress_registerValue__wrote_any := false;
  learner_ingress_registerValue__wrote_index0 := false;
  learner_ingress_registerValue__next_write_site := 0;
  learner_ingress_registerValue__last_write_site := 0;
  learner_ingress_registerValue__last0_old_value := 0bv256;
  learner_ingress_registerValue__last0_value := 0bv256;

  procurator_step := 0;
  procurator_bad := false;
  // step 0: host_send -> client
  // inject packet into connected node (host -> node)
  if (learner_inbox_count < 1) {
    assume learner_inbox_count < 1;
    havoc client_standard_metadata.ingress_port;
    havoc client_standard_metadata.instance_type;
    havoc client_standard_metadata.packet_length;
    havoc client_standard_metadata.enq_timestamp;
    havoc client_standard_metadata.enq_qdepth;
    havoc client_standard_metadata.deq_timedelta;
    havoc client_standard_metadata.deq_qdepth;
    havoc client_standard_metadata.ingress_global_timestamp;
    havoc client_standard_metadata.egress_global_timestamp;
    havoc client_standard_metadata.mcast_grp;
    havoc client_standard_metadata.egress_rid;
    havoc client_standard_metadata.checksum_error;
    havoc client_standard_metadata.parser_error;
    havoc client_standard_metadata.priority;
    havoc client_hdr.ethernet.dstAddr;
    havoc client_hdr.ethernet.srcAddr;
    havoc client_hdr.arp.valid;
    havoc client_hdr.arp.hrd;
    havoc client_hdr.arp.pro;
    havoc client_hdr.arp.hln;
    havoc client_hdr.arp.pln;
    havoc client_hdr.arp.op;
    havoc client_hdr.arp.sha;
    havoc client_hdr.arp.spa;
    havoc client_hdr.arp.tha;
    havoc client_hdr.arp.tpa;
    havoc client_hdr.ipv4.version;
    havoc client_hdr.ipv4.ihl;
    havoc client_hdr.ipv4.diffserv;
    havoc client_hdr.ipv4.totalLen;
    havoc client_hdr.ipv4.identification;
    havoc client_hdr.ipv4.flags;
    havoc client_hdr.ipv4.fragOffset;
    havoc client_hdr.ipv4.ttl;
    havoc client_hdr.ipv4.hdrChecksum;
    havoc client_hdr.ipv4.srcAddr;
    havoc client_hdr.ipv4.dstAddr;
    havoc client_hdr.icmp.valid;
    havoc client_hdr.icmp.icmpType;
    havoc client_hdr.icmp.icmpCode;
    havoc client_hdr.icmp.hdrChecksum;
    havoc client_hdr.icmp.identifier;
    havoc client_hdr.icmp.seqNumber;
    havoc client_hdr.icmp.payload;
    havoc client_hdr.udp.srcPort;
    havoc client_hdr.udp.length_;
    havoc client_hdr.udp.checksum;
    havoc client_hdr.paxos.inst;
    havoc client_hdr.paxos.vrnd;
    havoc client_hdr.paxos.acptid;
    havoc client_hdr.paxos.paxoslen;
    havoc client_meta.paxos_metadata;
    havoc client_meta.paxos_metadata.round;
    havoc client_meta.paxos_metadata.set_drop;
    havoc client_meta.paxos_metadata.ack_count;
    havoc client_meta.paxos_metadata.ack_acceptors;
    client_hdr.ethernet.valid := true;
    client_hdr.ipv4.valid := true;
    client_hdr.udp.valid := true;
    client_hdr.paxos.valid := true;
    client_hdr.ethernet.etherType := 2048bv16;
    client_hdr.ipv4.protocol := 17bv8;
    client_hdr.udp.dstPort := 34952bv16;
    client_hdr.paxos.msgtype := 3bv16;
    client_hdr.paxos.rnd := 0bv16;
    client_hdr.paxos.paxosval := 1bv256;
    if ((dsl_phase == 0)) {
      client_hdr.paxos.inst := 0bv32;
      client_hdr.paxos.acptid := 0bv16;
      dsl_phase := 1;
    } else {
      if ((dsl_phase == 1)) {
        client_hdr.paxos.inst := 0bv32;
        client_hdr.paxos.acptid := 2bv16;
        dsl_phase := 2;
      } else {
        if ((dsl_phase == 2)) {
          client_hdr.paxos.inst := 1bv32;
          client_hdr.paxos.acptid := 0bv16;
          dsl_phase := 3;
        } else {
          dsl_reset_epoch := 1;
          client_hdr.paxos.inst := 0bv32;
          client_hdr.paxos.acptid := 0bv16;
        }
      }
    }
    learner_standard_metadata.ingress_port := client_standard_metadata.ingress_port;
    learner_standard_metadata.instance_type := client_standard_metadata.instance_type;
    learner_standard_metadata.packet_length := client_standard_metadata.packet_length;
    learner_standard_metadata.enq_timestamp := client_standard_metadata.enq_timestamp;
    learner_standard_metadata.enq_qdepth := client_standard_metadata.enq_qdepth;
    learner_standard_metadata.deq_timedelta := client_standard_metadata.deq_timedelta;
    learner_standard_metadata.deq_qdepth := client_standard_metadata.deq_qdepth;
    learner_standard_metadata.ingress_global_timestamp := client_standard_metadata.ingress_global_timestamp;
    learner_standard_metadata.egress_global_timestamp := client_standard_metadata.egress_global_timestamp;
    learner_standard_metadata.mcast_grp := client_standard_metadata.mcast_grp;
    learner_standard_metadata.egress_rid := client_standard_metadata.egress_rid;
    learner_standard_metadata.checksum_error := client_standard_metadata.checksum_error;
    learner_standard_metadata.parser_error := client_standard_metadata.parser_error;
    learner_standard_metadata.priority := client_standard_metadata.priority;
    learner_hdr.ethernet.valid := client_hdr.ethernet.valid;
    learner_hdr.ethernet.dstAddr := client_hdr.ethernet.dstAddr;
    learner_hdr.ethernet.srcAddr := client_hdr.ethernet.srcAddr;
    learner_hdr.ethernet.etherType := client_hdr.ethernet.etherType;
    learner_hdr.arp.valid := client_hdr.arp.valid;
    learner_hdr.arp.hrd := client_hdr.arp.hrd;
    learner_hdr.arp.pro := client_hdr.arp.pro;
    learner_hdr.arp.hln := client_hdr.arp.hln;
    learner_hdr.arp.pln := client_hdr.arp.pln;
    learner_hdr.arp.op := client_hdr.arp.op;
    learner_hdr.arp.sha := client_hdr.arp.sha;
    learner_hdr.arp.spa := client_hdr.arp.spa;
    learner_hdr.arp.tha := client_hdr.arp.tha;
    learner_hdr.arp.tpa := client_hdr.arp.tpa;
    learner_hdr.ipv4.valid := client_hdr.ipv4.valid;
    learner_hdr.ipv4.version := client_hdr.ipv4.version;
    learner_hdr.ipv4.ihl := client_hdr.ipv4.ihl;
    learner_hdr.ipv4.diffserv := client_hdr.ipv4.diffserv;
    learner_hdr.ipv4.totalLen := client_hdr.ipv4.totalLen;
    learner_hdr.ipv4.identification := client_hdr.ipv4.identification;
    learner_hdr.ipv4.flags := client_hdr.ipv4.flags;
    learner_hdr.ipv4.fragOffset := client_hdr.ipv4.fragOffset;
    learner_hdr.ipv4.ttl := client_hdr.ipv4.ttl;
    learner_hdr.ipv4.protocol := client_hdr.ipv4.protocol;
    learner_hdr.ipv4.hdrChecksum := client_hdr.ipv4.hdrChecksum;
    learner_hdr.ipv4.srcAddr := client_hdr.ipv4.srcAddr;
    learner_hdr.ipv4.dstAddr := client_hdr.ipv4.dstAddr;
    learner_hdr.icmp.valid := client_hdr.icmp.valid;
    learner_hdr.icmp.icmpType := client_hdr.icmp.icmpType;
    learner_hdr.icmp.icmpCode := client_hdr.icmp.icmpCode;
    learner_hdr.icmp.hdrChecksum := client_hdr.icmp.hdrChecksum;
    learner_hdr.icmp.identifier := client_hdr.icmp.identifier;
    learner_hdr.icmp.seqNumber := client_hdr.icmp.seqNumber;
    learner_hdr.icmp.payload := client_hdr.icmp.payload;
    learner_hdr.udp.valid := client_hdr.udp.valid;
    learner_hdr.udp.srcPort := client_hdr.udp.srcPort;
    learner_hdr.udp.dstPort := client_hdr.udp.dstPort;
    learner_hdr.udp.length_ := client_hdr.udp.length_;
    learner_hdr.udp.checksum := client_hdr.udp.checksum;
    learner_hdr.paxos.valid := client_hdr.paxos.valid;
    learner_hdr.paxos.msgtype := client_hdr.paxos.msgtype;
    learner_hdr.paxos.inst := client_hdr.paxos.inst;
    learner_hdr.paxos.rnd := client_hdr.paxos.rnd;
    learner_hdr.paxos.vrnd := client_hdr.paxos.vrnd;
    learner_hdr.paxos.acptid := client_hdr.paxos.acptid;
    learner_hdr.paxos.paxoslen := client_hdr.paxos.paxoslen;
    learner_hdr.paxos.paxosval := client_hdr.paxos.paxosval;
    learner_meta.paxos_metadata := client_meta.paxos_metadata;
    learner_meta.paxos_metadata.round := client_meta.paxos_metadata.round;
    learner_meta.paxos_metadata.set_drop := client_meta.paxos_metadata.set_drop;
    learner_meta.paxos_metadata.ack_count := client_meta.paxos_metadata.ack_count;
    learner_meta.paxos_metadata.ack_acceptors := client_meta.paxos_metadata.ack_acceptors;
    learner_pkt_external := true;
    learner_inbox_count := learner_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 1: host_recv -> client
  procurator_step := procurator_step + 1;
  // step 2: node_pass -> learner
  if (learner_inbox_count > 0) {
  assume learner_inbox_count > 0;
  learner_inbox_count := learner_inbox_count - 1;
  // DSL statements (per-pass instrumentation)
  if ((learner_dsl_seen_epoch != dsl_reset_epoch)) {
    learner_dsl_seen_epoch := dsl_reset_epoch;
    learner_dsl_seen_a0 := false;
    learner_dsl_seen_a1 := false;
    learner_dsl_seen_a2 := false;
    learner_dsl_vote_cnt := 0;
  }
  if ((learner_hdr.paxos.valid && (learner_hdr.paxos.msgtype == 3bv16) && (learner_hdr.paxos.inst == 0bv32))) {
    if (((learner_hdr.paxos.acptid == 0bv16) && !(learner_dsl_seen_a0))) {
      learner_dsl_seen_a0 := true;
      learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
    } else {
      if (((learner_hdr.paxos.acptid == 1bv16) && !(learner_dsl_seen_a1))) {
        learner_dsl_seen_a1 := true;
        learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
      } else {
        if (((learner_hdr.paxos.acptid == 2bv16) && !(learner_dsl_seen_a2))) {
          learner_dsl_seen_a2 := true;
          learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
        }
      }
    }
  }
  call learner_mainProcedure();
  if (learner_p4b_clone_i2e) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_i2e := false;
  if (learner_p4b_clone_e2e) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_e2e := false;
  if (learner_p4b_clone_i2i) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_i2i := false;
  if (learner_p4b_recirculate) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_recirculate := false;
  call learner_Forward();
  // Register debug snapshot
  learner_ingress_registerHistory2B__dbg0 := learner_ingress_registerHistory2B[0bv32];
  learner_ingress_registerHistory2B__last_index__dbg := learner_ingress_registerHistory2B__last_index;
  learner_ingress_registerHistory2B__last_value__dbg := learner_ingress_registerHistory2B__last_value;
  learner_ingress_registerHistory2B__last_old_value__dbg := learner_ingress_registerHistory2B__last_old_value;
  learner_ingress_registerHistory2B__wrote_any__dbg := learner_ingress_registerHistory2B__wrote_any;
  learner_ingress_registerHistory2B__wrote_index0__dbg := learner_ingress_registerHistory2B__wrote_index0;
  learner_ingress_registerHistory2B__last0_old_value__dbg := learner_ingress_registerHistory2B__last0_old_value;
  learner_ingress_registerHistory2B__last0_value__dbg := learner_ingress_registerHistory2B__last0_value;
  learner_ingress_registerRound__dbg0 := learner_ingress_registerRound[0bv32];
  learner_ingress_registerRound__last_index__dbg := learner_ingress_registerRound__last_index;
  learner_ingress_registerRound__last_value__dbg := learner_ingress_registerRound__last_value;
  learner_ingress_registerRound__last_old_value__dbg := learner_ingress_registerRound__last_old_value;
  learner_ingress_registerRound__wrote_any__dbg := learner_ingress_registerRound__wrote_any;
  learner_ingress_registerRound__wrote_index0__dbg := learner_ingress_registerRound__wrote_index0;
  learner_ingress_registerRound__last0_old_value__dbg := learner_ingress_registerRound__last0_old_value;
  learner_ingress_registerRound__last0_value__dbg := learner_ingress_registerRound__last0_value;
  learner_ingress_registerValue__dbg0 := learner_ingress_registerValue[0bv32];
  learner_ingress_registerValue__last_index__dbg := learner_ingress_registerValue__last_index;
  learner_ingress_registerValue__last_value__dbg := learner_ingress_registerValue__last_value;
  learner_ingress_registerValue__last_old_value__dbg := learner_ingress_registerValue__last_old_value;
  learner_ingress_registerValue__wrote_any__dbg := learner_ingress_registerValue__wrote_any;
  learner_ingress_registerValue__wrote_index0__dbg := learner_ingress_registerValue__wrote_index0;
  learner_ingress_registerValue__last0_old_value__dbg := learner_ingress_registerValue__last0_old_value;
  learner_ingress_registerValue__last0_value__dbg := learner_ingress_registerValue__last0_value;
  // Global assertions (accumulated into procurator_bad)
  if (!(((dsl_reset_epoch < 1) || (learner_hdr.paxos.inst != 0bv32) || ((learner_meta.paxos_metadata.ack_acceptors != 3bv8) && (learner_meta.paxos_metadata.ack_acceptors != 5bv8) && (learner_meta.paxos_metadata.ack_acceptors != 6bv8)) || (learner_dsl_vote_cnt >= 2)))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  // step 3: host_send -> client
  // inject packet into connected node (host -> node)
  if (learner_inbox_count < 1) {
    assume learner_inbox_count < 1;
    havoc client_standard_metadata.ingress_port;
    havoc client_standard_metadata.instance_type;
    havoc client_standard_metadata.packet_length;
    havoc client_standard_metadata.enq_timestamp;
    havoc client_standard_metadata.enq_qdepth;
    havoc client_standard_metadata.deq_timedelta;
    havoc client_standard_metadata.deq_qdepth;
    havoc client_standard_metadata.ingress_global_timestamp;
    havoc client_standard_metadata.egress_global_timestamp;
    havoc client_standard_metadata.mcast_grp;
    havoc client_standard_metadata.egress_rid;
    havoc client_standard_metadata.checksum_error;
    havoc client_standard_metadata.parser_error;
    havoc client_standard_metadata.priority;
    havoc client_hdr.ethernet.dstAddr;
    havoc client_hdr.ethernet.srcAddr;
    havoc client_hdr.arp.valid;
    havoc client_hdr.arp.hrd;
    havoc client_hdr.arp.pro;
    havoc client_hdr.arp.hln;
    havoc client_hdr.arp.pln;
    havoc client_hdr.arp.op;
    havoc client_hdr.arp.sha;
    havoc client_hdr.arp.spa;
    havoc client_hdr.arp.tha;
    havoc client_hdr.arp.tpa;
    havoc client_hdr.ipv4.version;
    havoc client_hdr.ipv4.ihl;
    havoc client_hdr.ipv4.diffserv;
    havoc client_hdr.ipv4.totalLen;
    havoc client_hdr.ipv4.identification;
    havoc client_hdr.ipv4.flags;
    havoc client_hdr.ipv4.fragOffset;
    havoc client_hdr.ipv4.ttl;
    havoc client_hdr.ipv4.hdrChecksum;
    havoc client_hdr.ipv4.srcAddr;
    havoc client_hdr.ipv4.dstAddr;
    havoc client_hdr.icmp.valid;
    havoc client_hdr.icmp.icmpType;
    havoc client_hdr.icmp.icmpCode;
    havoc client_hdr.icmp.hdrChecksum;
    havoc client_hdr.icmp.identifier;
    havoc client_hdr.icmp.seqNumber;
    havoc client_hdr.icmp.payload;
    havoc client_hdr.udp.srcPort;
    havoc client_hdr.udp.length_;
    havoc client_hdr.udp.checksum;
    havoc client_hdr.paxos.inst;
    havoc client_hdr.paxos.vrnd;
    havoc client_hdr.paxos.acptid;
    havoc client_hdr.paxos.paxoslen;
    havoc client_meta.paxos_metadata;
    havoc client_meta.paxos_metadata.round;
    havoc client_meta.paxos_metadata.set_drop;
    havoc client_meta.paxos_metadata.ack_count;
    havoc client_meta.paxos_metadata.ack_acceptors;
    client_hdr.ethernet.valid := true;
    client_hdr.ipv4.valid := true;
    client_hdr.udp.valid := true;
    client_hdr.paxos.valid := true;
    client_hdr.ethernet.etherType := 2048bv16;
    client_hdr.ipv4.protocol := 17bv8;
    client_hdr.udp.dstPort := 34952bv16;
    client_hdr.paxos.msgtype := 3bv16;
    client_hdr.paxos.rnd := 0bv16;
    client_hdr.paxos.paxosval := 1bv256;
    if ((dsl_phase == 0)) {
      client_hdr.paxos.inst := 0bv32;
      client_hdr.paxos.acptid := 0bv16;
      dsl_phase := 1;
    } else {
      if ((dsl_phase == 1)) {
        client_hdr.paxos.inst := 0bv32;
        client_hdr.paxos.acptid := 2bv16;
        dsl_phase := 2;
      } else {
        if ((dsl_phase == 2)) {
          client_hdr.paxos.inst := 1bv32;
          client_hdr.paxos.acptid := 0bv16;
          dsl_phase := 3;
        } else {
          dsl_reset_epoch := 1;
          client_hdr.paxos.inst := 0bv32;
          client_hdr.paxos.acptid := 0bv16;
        }
      }
    }
    learner_standard_metadata.ingress_port := client_standard_metadata.ingress_port;
    learner_standard_metadata.instance_type := client_standard_metadata.instance_type;
    learner_standard_metadata.packet_length := client_standard_metadata.packet_length;
    learner_standard_metadata.enq_timestamp := client_standard_metadata.enq_timestamp;
    learner_standard_metadata.enq_qdepth := client_standard_metadata.enq_qdepth;
    learner_standard_metadata.deq_timedelta := client_standard_metadata.deq_timedelta;
    learner_standard_metadata.deq_qdepth := client_standard_metadata.deq_qdepth;
    learner_standard_metadata.ingress_global_timestamp := client_standard_metadata.ingress_global_timestamp;
    learner_standard_metadata.egress_global_timestamp := client_standard_metadata.egress_global_timestamp;
    learner_standard_metadata.mcast_grp := client_standard_metadata.mcast_grp;
    learner_standard_metadata.egress_rid := client_standard_metadata.egress_rid;
    learner_standard_metadata.checksum_error := client_standard_metadata.checksum_error;
    learner_standard_metadata.parser_error := client_standard_metadata.parser_error;
    learner_standard_metadata.priority := client_standard_metadata.priority;
    learner_hdr.ethernet.valid := client_hdr.ethernet.valid;
    learner_hdr.ethernet.dstAddr := client_hdr.ethernet.dstAddr;
    learner_hdr.ethernet.srcAddr := client_hdr.ethernet.srcAddr;
    learner_hdr.ethernet.etherType := client_hdr.ethernet.etherType;
    learner_hdr.arp.valid := client_hdr.arp.valid;
    learner_hdr.arp.hrd := client_hdr.arp.hrd;
    learner_hdr.arp.pro := client_hdr.arp.pro;
    learner_hdr.arp.hln := client_hdr.arp.hln;
    learner_hdr.arp.pln := client_hdr.arp.pln;
    learner_hdr.arp.op := client_hdr.arp.op;
    learner_hdr.arp.sha := client_hdr.arp.sha;
    learner_hdr.arp.spa := client_hdr.arp.spa;
    learner_hdr.arp.tha := client_hdr.arp.tha;
    learner_hdr.arp.tpa := client_hdr.arp.tpa;
    learner_hdr.ipv4.valid := client_hdr.ipv4.valid;
    learner_hdr.ipv4.version := client_hdr.ipv4.version;
    learner_hdr.ipv4.ihl := client_hdr.ipv4.ihl;
    learner_hdr.ipv4.diffserv := client_hdr.ipv4.diffserv;
    learner_hdr.ipv4.totalLen := client_hdr.ipv4.totalLen;
    learner_hdr.ipv4.identification := client_hdr.ipv4.identification;
    learner_hdr.ipv4.flags := client_hdr.ipv4.flags;
    learner_hdr.ipv4.fragOffset := client_hdr.ipv4.fragOffset;
    learner_hdr.ipv4.ttl := client_hdr.ipv4.ttl;
    learner_hdr.ipv4.protocol := client_hdr.ipv4.protocol;
    learner_hdr.ipv4.hdrChecksum := client_hdr.ipv4.hdrChecksum;
    learner_hdr.ipv4.srcAddr := client_hdr.ipv4.srcAddr;
    learner_hdr.ipv4.dstAddr := client_hdr.ipv4.dstAddr;
    learner_hdr.icmp.valid := client_hdr.icmp.valid;
    learner_hdr.icmp.icmpType := client_hdr.icmp.icmpType;
    learner_hdr.icmp.icmpCode := client_hdr.icmp.icmpCode;
    learner_hdr.icmp.hdrChecksum := client_hdr.icmp.hdrChecksum;
    learner_hdr.icmp.identifier := client_hdr.icmp.identifier;
    learner_hdr.icmp.seqNumber := client_hdr.icmp.seqNumber;
    learner_hdr.icmp.payload := client_hdr.icmp.payload;
    learner_hdr.udp.valid := client_hdr.udp.valid;
    learner_hdr.udp.srcPort := client_hdr.udp.srcPort;
    learner_hdr.udp.dstPort := client_hdr.udp.dstPort;
    learner_hdr.udp.length_ := client_hdr.udp.length_;
    learner_hdr.udp.checksum := client_hdr.udp.checksum;
    learner_hdr.paxos.valid := client_hdr.paxos.valid;
    learner_hdr.paxos.msgtype := client_hdr.paxos.msgtype;
    learner_hdr.paxos.inst := client_hdr.paxos.inst;
    learner_hdr.paxos.rnd := client_hdr.paxos.rnd;
    learner_hdr.paxos.vrnd := client_hdr.paxos.vrnd;
    learner_hdr.paxos.acptid := client_hdr.paxos.acptid;
    learner_hdr.paxos.paxoslen := client_hdr.paxos.paxoslen;
    learner_hdr.paxos.paxosval := client_hdr.paxos.paxosval;
    learner_meta.paxos_metadata := client_meta.paxos_metadata;
    learner_meta.paxos_metadata.round := client_meta.paxos_metadata.round;
    learner_meta.paxos_metadata.set_drop := client_meta.paxos_metadata.set_drop;
    learner_meta.paxos_metadata.ack_count := client_meta.paxos_metadata.ack_count;
    learner_meta.paxos_metadata.ack_acceptors := client_meta.paxos_metadata.ack_acceptors;
    learner_pkt_external := true;
    learner_inbox_count := learner_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 4: host_recv -> client
  procurator_step := procurator_step + 1;
  // step 5: node_pass -> learner
  if (learner_inbox_count > 0) {
  assume learner_inbox_count > 0;
  learner_inbox_count := learner_inbox_count - 1;
  // DSL statements (per-pass instrumentation)
  if ((learner_dsl_seen_epoch != dsl_reset_epoch)) {
    learner_dsl_seen_epoch := dsl_reset_epoch;
    learner_dsl_seen_a0 := false;
    learner_dsl_seen_a1 := false;
    learner_dsl_seen_a2 := false;
    learner_dsl_vote_cnt := 0;
  }
  if ((learner_hdr.paxos.valid && (learner_hdr.paxos.msgtype == 3bv16) && (learner_hdr.paxos.inst == 0bv32))) {
    if (((learner_hdr.paxos.acptid == 0bv16) && !(learner_dsl_seen_a0))) {
      learner_dsl_seen_a0 := true;
      learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
    } else {
      if (((learner_hdr.paxos.acptid == 1bv16) && !(learner_dsl_seen_a1))) {
        learner_dsl_seen_a1 := true;
        learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
      } else {
        if (((learner_hdr.paxos.acptid == 2bv16) && !(learner_dsl_seen_a2))) {
          learner_dsl_seen_a2 := true;
          learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
        }
      }
    }
  }
  call learner_mainProcedure();
  if (learner_p4b_clone_i2e) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_i2e := false;
  if (learner_p4b_clone_e2e) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_e2e := false;
  if (learner_p4b_clone_i2i) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_i2i := false;
  if (learner_p4b_recirculate) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_recirculate := false;
  call learner_Forward();
  // Register debug snapshot
  learner_ingress_registerHistory2B__dbg0 := learner_ingress_registerHistory2B[0bv32];
  learner_ingress_registerHistory2B__last_index__dbg := learner_ingress_registerHistory2B__last_index;
  learner_ingress_registerHistory2B__last_value__dbg := learner_ingress_registerHistory2B__last_value;
  learner_ingress_registerHistory2B__last_old_value__dbg := learner_ingress_registerHistory2B__last_old_value;
  learner_ingress_registerHistory2B__wrote_any__dbg := learner_ingress_registerHistory2B__wrote_any;
  learner_ingress_registerHistory2B__wrote_index0__dbg := learner_ingress_registerHistory2B__wrote_index0;
  learner_ingress_registerHistory2B__last0_old_value__dbg := learner_ingress_registerHistory2B__last0_old_value;
  learner_ingress_registerHistory2B__last0_value__dbg := learner_ingress_registerHistory2B__last0_value;
  learner_ingress_registerRound__dbg0 := learner_ingress_registerRound[0bv32];
  learner_ingress_registerRound__last_index__dbg := learner_ingress_registerRound__last_index;
  learner_ingress_registerRound__last_value__dbg := learner_ingress_registerRound__last_value;
  learner_ingress_registerRound__last_old_value__dbg := learner_ingress_registerRound__last_old_value;
  learner_ingress_registerRound__wrote_any__dbg := learner_ingress_registerRound__wrote_any;
  learner_ingress_registerRound__wrote_index0__dbg := learner_ingress_registerRound__wrote_index0;
  learner_ingress_registerRound__last0_old_value__dbg := learner_ingress_registerRound__last0_old_value;
  learner_ingress_registerRound__last0_value__dbg := learner_ingress_registerRound__last0_value;
  learner_ingress_registerValue__dbg0 := learner_ingress_registerValue[0bv32];
  learner_ingress_registerValue__last_index__dbg := learner_ingress_registerValue__last_index;
  learner_ingress_registerValue__last_value__dbg := learner_ingress_registerValue__last_value;
  learner_ingress_registerValue__last_old_value__dbg := learner_ingress_registerValue__last_old_value;
  learner_ingress_registerValue__wrote_any__dbg := learner_ingress_registerValue__wrote_any;
  learner_ingress_registerValue__wrote_index0__dbg := learner_ingress_registerValue__wrote_index0;
  learner_ingress_registerValue__last0_old_value__dbg := learner_ingress_registerValue__last0_old_value;
  learner_ingress_registerValue__last0_value__dbg := learner_ingress_registerValue__last0_value;
  // Global assertions (accumulated into procurator_bad)
  if (!(((dsl_reset_epoch < 1) || (learner_hdr.paxos.inst != 0bv32) || ((learner_meta.paxos_metadata.ack_acceptors != 3bv8) && (learner_meta.paxos_metadata.ack_acceptors != 5bv8) && (learner_meta.paxos_metadata.ack_acceptors != 6bv8)) || (learner_dsl_vote_cnt >= 2)))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  // step 6: host_send -> client
  // inject packet into connected node (host -> node)
  if (learner_inbox_count < 1) {
    assume learner_inbox_count < 1;
    havoc client_standard_metadata.ingress_port;
    havoc client_standard_metadata.instance_type;
    havoc client_standard_metadata.packet_length;
    havoc client_standard_metadata.enq_timestamp;
    havoc client_standard_metadata.enq_qdepth;
    havoc client_standard_metadata.deq_timedelta;
    havoc client_standard_metadata.deq_qdepth;
    havoc client_standard_metadata.ingress_global_timestamp;
    havoc client_standard_metadata.egress_global_timestamp;
    havoc client_standard_metadata.mcast_grp;
    havoc client_standard_metadata.egress_rid;
    havoc client_standard_metadata.checksum_error;
    havoc client_standard_metadata.parser_error;
    havoc client_standard_metadata.priority;
    havoc client_hdr.ethernet.dstAddr;
    havoc client_hdr.ethernet.srcAddr;
    havoc client_hdr.arp.valid;
    havoc client_hdr.arp.hrd;
    havoc client_hdr.arp.pro;
    havoc client_hdr.arp.hln;
    havoc client_hdr.arp.pln;
    havoc client_hdr.arp.op;
    havoc client_hdr.arp.sha;
    havoc client_hdr.arp.spa;
    havoc client_hdr.arp.tha;
    havoc client_hdr.arp.tpa;
    havoc client_hdr.ipv4.version;
    havoc client_hdr.ipv4.ihl;
    havoc client_hdr.ipv4.diffserv;
    havoc client_hdr.ipv4.totalLen;
    havoc client_hdr.ipv4.identification;
    havoc client_hdr.ipv4.flags;
    havoc client_hdr.ipv4.fragOffset;
    havoc client_hdr.ipv4.ttl;
    havoc client_hdr.ipv4.hdrChecksum;
    havoc client_hdr.ipv4.srcAddr;
    havoc client_hdr.ipv4.dstAddr;
    havoc client_hdr.icmp.valid;
    havoc client_hdr.icmp.icmpType;
    havoc client_hdr.icmp.icmpCode;
    havoc client_hdr.icmp.hdrChecksum;
    havoc client_hdr.icmp.identifier;
    havoc client_hdr.icmp.seqNumber;
    havoc client_hdr.icmp.payload;
    havoc client_hdr.udp.srcPort;
    havoc client_hdr.udp.length_;
    havoc client_hdr.udp.checksum;
    havoc client_hdr.paxos.inst;
    havoc client_hdr.paxos.vrnd;
    havoc client_hdr.paxos.acptid;
    havoc client_hdr.paxos.paxoslen;
    havoc client_meta.paxos_metadata;
    havoc client_meta.paxos_metadata.round;
    havoc client_meta.paxos_metadata.set_drop;
    havoc client_meta.paxos_metadata.ack_count;
    havoc client_meta.paxos_metadata.ack_acceptors;
    client_hdr.ethernet.valid := true;
    client_hdr.ipv4.valid := true;
    client_hdr.udp.valid := true;
    client_hdr.paxos.valid := true;
    client_hdr.ethernet.etherType := 2048bv16;
    client_hdr.ipv4.protocol := 17bv8;
    client_hdr.udp.dstPort := 34952bv16;
    client_hdr.paxos.msgtype := 3bv16;
    client_hdr.paxos.rnd := 0bv16;
    client_hdr.paxos.paxosval := 1bv256;
    if ((dsl_phase == 0)) {
      client_hdr.paxos.inst := 0bv32;
      client_hdr.paxos.acptid := 0bv16;
      dsl_phase := 1;
    } else {
      if ((dsl_phase == 1)) {
        client_hdr.paxos.inst := 0bv32;
        client_hdr.paxos.acptid := 2bv16;
        dsl_phase := 2;
      } else {
        if ((dsl_phase == 2)) {
          client_hdr.paxos.inst := 1bv32;
          client_hdr.paxos.acptid := 0bv16;
          dsl_phase := 3;
        } else {
          dsl_reset_epoch := 1;
          client_hdr.paxos.inst := 0bv32;
          client_hdr.paxos.acptid := 0bv16;
        }
      }
    }
    learner_standard_metadata.ingress_port := client_standard_metadata.ingress_port;
    learner_standard_metadata.instance_type := client_standard_metadata.instance_type;
    learner_standard_metadata.packet_length := client_standard_metadata.packet_length;
    learner_standard_metadata.enq_timestamp := client_standard_metadata.enq_timestamp;
    learner_standard_metadata.enq_qdepth := client_standard_metadata.enq_qdepth;
    learner_standard_metadata.deq_timedelta := client_standard_metadata.deq_timedelta;
    learner_standard_metadata.deq_qdepth := client_standard_metadata.deq_qdepth;
    learner_standard_metadata.ingress_global_timestamp := client_standard_metadata.ingress_global_timestamp;
    learner_standard_metadata.egress_global_timestamp := client_standard_metadata.egress_global_timestamp;
    learner_standard_metadata.mcast_grp := client_standard_metadata.mcast_grp;
    learner_standard_metadata.egress_rid := client_standard_metadata.egress_rid;
    learner_standard_metadata.checksum_error := client_standard_metadata.checksum_error;
    learner_standard_metadata.parser_error := client_standard_metadata.parser_error;
    learner_standard_metadata.priority := client_standard_metadata.priority;
    learner_hdr.ethernet.valid := client_hdr.ethernet.valid;
    learner_hdr.ethernet.dstAddr := client_hdr.ethernet.dstAddr;
    learner_hdr.ethernet.srcAddr := client_hdr.ethernet.srcAddr;
    learner_hdr.ethernet.etherType := client_hdr.ethernet.etherType;
    learner_hdr.arp.valid := client_hdr.arp.valid;
    learner_hdr.arp.hrd := client_hdr.arp.hrd;
    learner_hdr.arp.pro := client_hdr.arp.pro;
    learner_hdr.arp.hln := client_hdr.arp.hln;
    learner_hdr.arp.pln := client_hdr.arp.pln;
    learner_hdr.arp.op := client_hdr.arp.op;
    learner_hdr.arp.sha := client_hdr.arp.sha;
    learner_hdr.arp.spa := client_hdr.arp.spa;
    learner_hdr.arp.tha := client_hdr.arp.tha;
    learner_hdr.arp.tpa := client_hdr.arp.tpa;
    learner_hdr.ipv4.valid := client_hdr.ipv4.valid;
    learner_hdr.ipv4.version := client_hdr.ipv4.version;
    learner_hdr.ipv4.ihl := client_hdr.ipv4.ihl;
    learner_hdr.ipv4.diffserv := client_hdr.ipv4.diffserv;
    learner_hdr.ipv4.totalLen := client_hdr.ipv4.totalLen;
    learner_hdr.ipv4.identification := client_hdr.ipv4.identification;
    learner_hdr.ipv4.flags := client_hdr.ipv4.flags;
    learner_hdr.ipv4.fragOffset := client_hdr.ipv4.fragOffset;
    learner_hdr.ipv4.ttl := client_hdr.ipv4.ttl;
    learner_hdr.ipv4.protocol := client_hdr.ipv4.protocol;
    learner_hdr.ipv4.hdrChecksum := client_hdr.ipv4.hdrChecksum;
    learner_hdr.ipv4.srcAddr := client_hdr.ipv4.srcAddr;
    learner_hdr.ipv4.dstAddr := client_hdr.ipv4.dstAddr;
    learner_hdr.icmp.valid := client_hdr.icmp.valid;
    learner_hdr.icmp.icmpType := client_hdr.icmp.icmpType;
    learner_hdr.icmp.icmpCode := client_hdr.icmp.icmpCode;
    learner_hdr.icmp.hdrChecksum := client_hdr.icmp.hdrChecksum;
    learner_hdr.icmp.identifier := client_hdr.icmp.identifier;
    learner_hdr.icmp.seqNumber := client_hdr.icmp.seqNumber;
    learner_hdr.icmp.payload := client_hdr.icmp.payload;
    learner_hdr.udp.valid := client_hdr.udp.valid;
    learner_hdr.udp.srcPort := client_hdr.udp.srcPort;
    learner_hdr.udp.dstPort := client_hdr.udp.dstPort;
    learner_hdr.udp.length_ := client_hdr.udp.length_;
    learner_hdr.udp.checksum := client_hdr.udp.checksum;
    learner_hdr.paxos.valid := client_hdr.paxos.valid;
    learner_hdr.paxos.msgtype := client_hdr.paxos.msgtype;
    learner_hdr.paxos.inst := client_hdr.paxos.inst;
    learner_hdr.paxos.rnd := client_hdr.paxos.rnd;
    learner_hdr.paxos.vrnd := client_hdr.paxos.vrnd;
    learner_hdr.paxos.acptid := client_hdr.paxos.acptid;
    learner_hdr.paxos.paxoslen := client_hdr.paxos.paxoslen;
    learner_hdr.paxos.paxosval := client_hdr.paxos.paxosval;
    learner_meta.paxos_metadata := client_meta.paxos_metadata;
    learner_meta.paxos_metadata.round := client_meta.paxos_metadata.round;
    learner_meta.paxos_metadata.set_drop := client_meta.paxos_metadata.set_drop;
    learner_meta.paxos_metadata.ack_count := client_meta.paxos_metadata.ack_count;
    learner_meta.paxos_metadata.ack_acceptors := client_meta.paxos_metadata.ack_acceptors;
    learner_pkt_external := true;
    learner_inbox_count := learner_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 7: host_recv -> client
  procurator_step := procurator_step + 1;
  // step 8: node_pass -> learner
  if (learner_inbox_count > 0) {
  assume learner_inbox_count > 0;
  learner_inbox_count := learner_inbox_count - 1;
  // DSL statements (per-pass instrumentation)
  if ((learner_dsl_seen_epoch != dsl_reset_epoch)) {
    learner_dsl_seen_epoch := dsl_reset_epoch;
    learner_dsl_seen_a0 := false;
    learner_dsl_seen_a1 := false;
    learner_dsl_seen_a2 := false;
    learner_dsl_vote_cnt := 0;
  }
  if ((learner_hdr.paxos.valid && (learner_hdr.paxos.msgtype == 3bv16) && (learner_hdr.paxos.inst == 0bv32))) {
    if (((learner_hdr.paxos.acptid == 0bv16) && !(learner_dsl_seen_a0))) {
      learner_dsl_seen_a0 := true;
      learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
    } else {
      if (((learner_hdr.paxos.acptid == 1bv16) && !(learner_dsl_seen_a1))) {
        learner_dsl_seen_a1 := true;
        learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
      } else {
        if (((learner_hdr.paxos.acptid == 2bv16) && !(learner_dsl_seen_a2))) {
          learner_dsl_seen_a2 := true;
          learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
        }
      }
    }
  }
  call learner_mainProcedure();
  if (learner_p4b_clone_i2e) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_i2e := false;
  if (learner_p4b_clone_e2e) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_e2e := false;
  if (learner_p4b_clone_i2i) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_i2i := false;
  if (learner_p4b_recirculate) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_recirculate := false;
  call learner_Forward();
  // Register debug snapshot
  learner_ingress_registerHistory2B__dbg0 := learner_ingress_registerHistory2B[0bv32];
  learner_ingress_registerHistory2B__last_index__dbg := learner_ingress_registerHistory2B__last_index;
  learner_ingress_registerHistory2B__last_value__dbg := learner_ingress_registerHistory2B__last_value;
  learner_ingress_registerHistory2B__last_old_value__dbg := learner_ingress_registerHistory2B__last_old_value;
  learner_ingress_registerHistory2B__wrote_any__dbg := learner_ingress_registerHistory2B__wrote_any;
  learner_ingress_registerHistory2B__wrote_index0__dbg := learner_ingress_registerHistory2B__wrote_index0;
  learner_ingress_registerHistory2B__last0_old_value__dbg := learner_ingress_registerHistory2B__last0_old_value;
  learner_ingress_registerHistory2B__last0_value__dbg := learner_ingress_registerHistory2B__last0_value;
  learner_ingress_registerRound__dbg0 := learner_ingress_registerRound[0bv32];
  learner_ingress_registerRound__last_index__dbg := learner_ingress_registerRound__last_index;
  learner_ingress_registerRound__last_value__dbg := learner_ingress_registerRound__last_value;
  learner_ingress_registerRound__last_old_value__dbg := learner_ingress_registerRound__last_old_value;
  learner_ingress_registerRound__wrote_any__dbg := learner_ingress_registerRound__wrote_any;
  learner_ingress_registerRound__wrote_index0__dbg := learner_ingress_registerRound__wrote_index0;
  learner_ingress_registerRound__last0_old_value__dbg := learner_ingress_registerRound__last0_old_value;
  learner_ingress_registerRound__last0_value__dbg := learner_ingress_registerRound__last0_value;
  learner_ingress_registerValue__dbg0 := learner_ingress_registerValue[0bv32];
  learner_ingress_registerValue__last_index__dbg := learner_ingress_registerValue__last_index;
  learner_ingress_registerValue__last_value__dbg := learner_ingress_registerValue__last_value;
  learner_ingress_registerValue__last_old_value__dbg := learner_ingress_registerValue__last_old_value;
  learner_ingress_registerValue__wrote_any__dbg := learner_ingress_registerValue__wrote_any;
  learner_ingress_registerValue__wrote_index0__dbg := learner_ingress_registerValue__wrote_index0;
  learner_ingress_registerValue__last0_old_value__dbg := learner_ingress_registerValue__last0_old_value;
  learner_ingress_registerValue__last0_value__dbg := learner_ingress_registerValue__last0_value;
  // Global assertions (accumulated into procurator_bad)
  if (!(((dsl_reset_epoch < 1) || (learner_hdr.paxos.inst != 0bv32) || ((learner_meta.paxos_metadata.ack_acceptors != 3bv8) && (learner_meta.paxos_metadata.ack_acceptors != 5bv8) && (learner_meta.paxos_metadata.ack_acceptors != 6bv8)) || (learner_dsl_vote_cnt >= 2)))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  // step 9: host_send -> client
  // inject packet into connected node (host -> node)
  if (learner_inbox_count < 1) {
    assume learner_inbox_count < 1;
    havoc client_standard_metadata.ingress_port;
    havoc client_standard_metadata.instance_type;
    havoc client_standard_metadata.packet_length;
    havoc client_standard_metadata.enq_timestamp;
    havoc client_standard_metadata.enq_qdepth;
    havoc client_standard_metadata.deq_timedelta;
    havoc client_standard_metadata.deq_qdepth;
    havoc client_standard_metadata.ingress_global_timestamp;
    havoc client_standard_metadata.egress_global_timestamp;
    havoc client_standard_metadata.mcast_grp;
    havoc client_standard_metadata.egress_rid;
    havoc client_standard_metadata.checksum_error;
    havoc client_standard_metadata.parser_error;
    havoc client_standard_metadata.priority;
    havoc client_hdr.ethernet.dstAddr;
    havoc client_hdr.ethernet.srcAddr;
    havoc client_hdr.arp.valid;
    havoc client_hdr.arp.hrd;
    havoc client_hdr.arp.pro;
    havoc client_hdr.arp.hln;
    havoc client_hdr.arp.pln;
    havoc client_hdr.arp.op;
    havoc client_hdr.arp.sha;
    havoc client_hdr.arp.spa;
    havoc client_hdr.arp.tha;
    havoc client_hdr.arp.tpa;
    havoc client_hdr.ipv4.version;
    havoc client_hdr.ipv4.ihl;
    havoc client_hdr.ipv4.diffserv;
    havoc client_hdr.ipv4.totalLen;
    havoc client_hdr.ipv4.identification;
    havoc client_hdr.ipv4.flags;
    havoc client_hdr.ipv4.fragOffset;
    havoc client_hdr.ipv4.ttl;
    havoc client_hdr.ipv4.hdrChecksum;
    havoc client_hdr.ipv4.srcAddr;
    havoc client_hdr.ipv4.dstAddr;
    havoc client_hdr.icmp.valid;
    havoc client_hdr.icmp.icmpType;
    havoc client_hdr.icmp.icmpCode;
    havoc client_hdr.icmp.hdrChecksum;
    havoc client_hdr.icmp.identifier;
    havoc client_hdr.icmp.seqNumber;
    havoc client_hdr.icmp.payload;
    havoc client_hdr.udp.srcPort;
    havoc client_hdr.udp.length_;
    havoc client_hdr.udp.checksum;
    havoc client_hdr.paxos.inst;
    havoc client_hdr.paxos.vrnd;
    havoc client_hdr.paxos.acptid;
    havoc client_hdr.paxos.paxoslen;
    havoc client_meta.paxos_metadata;
    havoc client_meta.paxos_metadata.round;
    havoc client_meta.paxos_metadata.set_drop;
    havoc client_meta.paxos_metadata.ack_count;
    havoc client_meta.paxos_metadata.ack_acceptors;
    client_hdr.ethernet.valid := true;
    client_hdr.ipv4.valid := true;
    client_hdr.udp.valid := true;
    client_hdr.paxos.valid := true;
    client_hdr.ethernet.etherType := 2048bv16;
    client_hdr.ipv4.protocol := 17bv8;
    client_hdr.udp.dstPort := 34952bv16;
    client_hdr.paxos.msgtype := 3bv16;
    client_hdr.paxos.rnd := 0bv16;
    client_hdr.paxos.paxosval := 1bv256;
    if ((dsl_phase == 0)) {
      client_hdr.paxos.inst := 0bv32;
      client_hdr.paxos.acptid := 0bv16;
      dsl_phase := 1;
    } else {
      if ((dsl_phase == 1)) {
        client_hdr.paxos.inst := 0bv32;
        client_hdr.paxos.acptid := 2bv16;
        dsl_phase := 2;
      } else {
        if ((dsl_phase == 2)) {
          client_hdr.paxos.inst := 1bv32;
          client_hdr.paxos.acptid := 0bv16;
          dsl_phase := 3;
        } else {
          dsl_reset_epoch := 1;
          client_hdr.paxos.inst := 0bv32;
          client_hdr.paxos.acptid := 0bv16;
        }
      }
    }
    learner_standard_metadata.ingress_port := client_standard_metadata.ingress_port;
    learner_standard_metadata.instance_type := client_standard_metadata.instance_type;
    learner_standard_metadata.packet_length := client_standard_metadata.packet_length;
    learner_standard_metadata.enq_timestamp := client_standard_metadata.enq_timestamp;
    learner_standard_metadata.enq_qdepth := client_standard_metadata.enq_qdepth;
    learner_standard_metadata.deq_timedelta := client_standard_metadata.deq_timedelta;
    learner_standard_metadata.deq_qdepth := client_standard_metadata.deq_qdepth;
    learner_standard_metadata.ingress_global_timestamp := client_standard_metadata.ingress_global_timestamp;
    learner_standard_metadata.egress_global_timestamp := client_standard_metadata.egress_global_timestamp;
    learner_standard_metadata.mcast_grp := client_standard_metadata.mcast_grp;
    learner_standard_metadata.egress_rid := client_standard_metadata.egress_rid;
    learner_standard_metadata.checksum_error := client_standard_metadata.checksum_error;
    learner_standard_metadata.parser_error := client_standard_metadata.parser_error;
    learner_standard_metadata.priority := client_standard_metadata.priority;
    learner_hdr.ethernet.valid := client_hdr.ethernet.valid;
    learner_hdr.ethernet.dstAddr := client_hdr.ethernet.dstAddr;
    learner_hdr.ethernet.srcAddr := client_hdr.ethernet.srcAddr;
    learner_hdr.ethernet.etherType := client_hdr.ethernet.etherType;
    learner_hdr.arp.valid := client_hdr.arp.valid;
    learner_hdr.arp.hrd := client_hdr.arp.hrd;
    learner_hdr.arp.pro := client_hdr.arp.pro;
    learner_hdr.arp.hln := client_hdr.arp.hln;
    learner_hdr.arp.pln := client_hdr.arp.pln;
    learner_hdr.arp.op := client_hdr.arp.op;
    learner_hdr.arp.sha := client_hdr.arp.sha;
    learner_hdr.arp.spa := client_hdr.arp.spa;
    learner_hdr.arp.tha := client_hdr.arp.tha;
    learner_hdr.arp.tpa := client_hdr.arp.tpa;
    learner_hdr.ipv4.valid := client_hdr.ipv4.valid;
    learner_hdr.ipv4.version := client_hdr.ipv4.version;
    learner_hdr.ipv4.ihl := client_hdr.ipv4.ihl;
    learner_hdr.ipv4.diffserv := client_hdr.ipv4.diffserv;
    learner_hdr.ipv4.totalLen := client_hdr.ipv4.totalLen;
    learner_hdr.ipv4.identification := client_hdr.ipv4.identification;
    learner_hdr.ipv4.flags := client_hdr.ipv4.flags;
    learner_hdr.ipv4.fragOffset := client_hdr.ipv4.fragOffset;
    learner_hdr.ipv4.ttl := client_hdr.ipv4.ttl;
    learner_hdr.ipv4.protocol := client_hdr.ipv4.protocol;
    learner_hdr.ipv4.hdrChecksum := client_hdr.ipv4.hdrChecksum;
    learner_hdr.ipv4.srcAddr := client_hdr.ipv4.srcAddr;
    learner_hdr.ipv4.dstAddr := client_hdr.ipv4.dstAddr;
    learner_hdr.icmp.valid := client_hdr.icmp.valid;
    learner_hdr.icmp.icmpType := client_hdr.icmp.icmpType;
    learner_hdr.icmp.icmpCode := client_hdr.icmp.icmpCode;
    learner_hdr.icmp.hdrChecksum := client_hdr.icmp.hdrChecksum;
    learner_hdr.icmp.identifier := client_hdr.icmp.identifier;
    learner_hdr.icmp.seqNumber := client_hdr.icmp.seqNumber;
    learner_hdr.icmp.payload := client_hdr.icmp.payload;
    learner_hdr.udp.valid := client_hdr.udp.valid;
    learner_hdr.udp.srcPort := client_hdr.udp.srcPort;
    learner_hdr.udp.dstPort := client_hdr.udp.dstPort;
    learner_hdr.udp.length_ := client_hdr.udp.length_;
    learner_hdr.udp.checksum := client_hdr.udp.checksum;
    learner_hdr.paxos.valid := client_hdr.paxos.valid;
    learner_hdr.paxos.msgtype := client_hdr.paxos.msgtype;
    learner_hdr.paxos.inst := client_hdr.paxos.inst;
    learner_hdr.paxos.rnd := client_hdr.paxos.rnd;
    learner_hdr.paxos.vrnd := client_hdr.paxos.vrnd;
    learner_hdr.paxos.acptid := client_hdr.paxos.acptid;
    learner_hdr.paxos.paxoslen := client_hdr.paxos.paxoslen;
    learner_hdr.paxos.paxosval := client_hdr.paxos.paxosval;
    learner_meta.paxos_metadata := client_meta.paxos_metadata;
    learner_meta.paxos_metadata.round := client_meta.paxos_metadata.round;
    learner_meta.paxos_metadata.set_drop := client_meta.paxos_metadata.set_drop;
    learner_meta.paxos_metadata.ack_count := client_meta.paxos_metadata.ack_count;
    learner_meta.paxos_metadata.ack_acceptors := client_meta.paxos_metadata.ack_acceptors;
    learner_pkt_external := true;
    learner_inbox_count := learner_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 10: host_recv -> client
  procurator_step := procurator_step + 1;
  // step 11: node_pass -> learner
  if (learner_inbox_count > 0) {
  assume learner_inbox_count > 0;
  learner_inbox_count := learner_inbox_count - 1;
  // DSL statements (per-pass instrumentation)
  if ((learner_dsl_seen_epoch != dsl_reset_epoch)) {
    learner_dsl_seen_epoch := dsl_reset_epoch;
    learner_dsl_seen_a0 := false;
    learner_dsl_seen_a1 := false;
    learner_dsl_seen_a2 := false;
    learner_dsl_vote_cnt := 0;
  }
  if ((learner_hdr.paxos.valid && (learner_hdr.paxos.msgtype == 3bv16) && (learner_hdr.paxos.inst == 0bv32))) {
    if (((learner_hdr.paxos.acptid == 0bv16) && !(learner_dsl_seen_a0))) {
      learner_dsl_seen_a0 := true;
      learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
    } else {
      if (((learner_hdr.paxos.acptid == 1bv16) && !(learner_dsl_seen_a1))) {
        learner_dsl_seen_a1 := true;
        learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
      } else {
        if (((learner_hdr.paxos.acptid == 2bv16) && !(learner_dsl_seen_a2))) {
          learner_dsl_seen_a2 := true;
          learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
        }
      }
    }
  }
  call learner_mainProcedure();
  if (learner_p4b_clone_i2e) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_i2e := false;
  if (learner_p4b_clone_e2e) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_e2e := false;
  if (learner_p4b_clone_i2i) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_i2i := false;
  if (learner_p4b_recirculate) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_recirculate := false;
  call learner_Forward();
  // Register debug snapshot
  learner_ingress_registerHistory2B__dbg0 := learner_ingress_registerHistory2B[0bv32];
  learner_ingress_registerHistory2B__last_index__dbg := learner_ingress_registerHistory2B__last_index;
  learner_ingress_registerHistory2B__last_value__dbg := learner_ingress_registerHistory2B__last_value;
  learner_ingress_registerHistory2B__last_old_value__dbg := learner_ingress_registerHistory2B__last_old_value;
  learner_ingress_registerHistory2B__wrote_any__dbg := learner_ingress_registerHistory2B__wrote_any;
  learner_ingress_registerHistory2B__wrote_index0__dbg := learner_ingress_registerHistory2B__wrote_index0;
  learner_ingress_registerHistory2B__last0_old_value__dbg := learner_ingress_registerHistory2B__last0_old_value;
  learner_ingress_registerHistory2B__last0_value__dbg := learner_ingress_registerHistory2B__last0_value;
  learner_ingress_registerRound__dbg0 := learner_ingress_registerRound[0bv32];
  learner_ingress_registerRound__last_index__dbg := learner_ingress_registerRound__last_index;
  learner_ingress_registerRound__last_value__dbg := learner_ingress_registerRound__last_value;
  learner_ingress_registerRound__last_old_value__dbg := learner_ingress_registerRound__last_old_value;
  learner_ingress_registerRound__wrote_any__dbg := learner_ingress_registerRound__wrote_any;
  learner_ingress_registerRound__wrote_index0__dbg := learner_ingress_registerRound__wrote_index0;
  learner_ingress_registerRound__last0_old_value__dbg := learner_ingress_registerRound__last0_old_value;
  learner_ingress_registerRound__last0_value__dbg := learner_ingress_registerRound__last0_value;
  learner_ingress_registerValue__dbg0 := learner_ingress_registerValue[0bv32];
  learner_ingress_registerValue__last_index__dbg := learner_ingress_registerValue__last_index;
  learner_ingress_registerValue__last_value__dbg := learner_ingress_registerValue__last_value;
  learner_ingress_registerValue__last_old_value__dbg := learner_ingress_registerValue__last_old_value;
  learner_ingress_registerValue__wrote_any__dbg := learner_ingress_registerValue__wrote_any;
  learner_ingress_registerValue__wrote_index0__dbg := learner_ingress_registerValue__wrote_index0;
  learner_ingress_registerValue__last0_old_value__dbg := learner_ingress_registerValue__last0_old_value;
  learner_ingress_registerValue__last0_value__dbg := learner_ingress_registerValue__last0_value;
  // Global assertions (accumulated into procurator_bad)
  if (!(((dsl_reset_epoch < 1) || (learner_hdr.paxos.inst != 0bv32) || ((learner_meta.paxos_metadata.ack_acceptors != 3bv8) && (learner_meta.paxos_metadata.ack_acceptors != 5bv8) && (learner_meta.paxos_metadata.ack_acceptors != 6bv8)) || (learner_dsl_vote_cnt >= 2)))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  // step 12: host_send -> client
  // inject packet into connected node (host -> node)
  if (learner_inbox_count < 1) {
    assume learner_inbox_count < 1;
    havoc client_standard_metadata.ingress_port;
    havoc client_standard_metadata.instance_type;
    havoc client_standard_metadata.packet_length;
    havoc client_standard_metadata.enq_timestamp;
    havoc client_standard_metadata.enq_qdepth;
    havoc client_standard_metadata.deq_timedelta;
    havoc client_standard_metadata.deq_qdepth;
    havoc client_standard_metadata.ingress_global_timestamp;
    havoc client_standard_metadata.egress_global_timestamp;
    havoc client_standard_metadata.mcast_grp;
    havoc client_standard_metadata.egress_rid;
    havoc client_standard_metadata.checksum_error;
    havoc client_standard_metadata.parser_error;
    havoc client_standard_metadata.priority;
    havoc client_hdr.ethernet.dstAddr;
    havoc client_hdr.ethernet.srcAddr;
    havoc client_hdr.arp.valid;
    havoc client_hdr.arp.hrd;
    havoc client_hdr.arp.pro;
    havoc client_hdr.arp.hln;
    havoc client_hdr.arp.pln;
    havoc client_hdr.arp.op;
    havoc client_hdr.arp.sha;
    havoc client_hdr.arp.spa;
    havoc client_hdr.arp.tha;
    havoc client_hdr.arp.tpa;
    havoc client_hdr.ipv4.version;
    havoc client_hdr.ipv4.ihl;
    havoc client_hdr.ipv4.diffserv;
    havoc client_hdr.ipv4.totalLen;
    havoc client_hdr.ipv4.identification;
    havoc client_hdr.ipv4.flags;
    havoc client_hdr.ipv4.fragOffset;
    havoc client_hdr.ipv4.ttl;
    havoc client_hdr.ipv4.hdrChecksum;
    havoc client_hdr.ipv4.srcAddr;
    havoc client_hdr.ipv4.dstAddr;
    havoc client_hdr.icmp.valid;
    havoc client_hdr.icmp.icmpType;
    havoc client_hdr.icmp.icmpCode;
    havoc client_hdr.icmp.hdrChecksum;
    havoc client_hdr.icmp.identifier;
    havoc client_hdr.icmp.seqNumber;
    havoc client_hdr.icmp.payload;
    havoc client_hdr.udp.srcPort;
    havoc client_hdr.udp.length_;
    havoc client_hdr.udp.checksum;
    havoc client_hdr.paxos.inst;
    havoc client_hdr.paxos.vrnd;
    havoc client_hdr.paxos.acptid;
    havoc client_hdr.paxos.paxoslen;
    havoc client_meta.paxos_metadata;
    havoc client_meta.paxos_metadata.round;
    havoc client_meta.paxos_metadata.set_drop;
    havoc client_meta.paxos_metadata.ack_count;
    havoc client_meta.paxos_metadata.ack_acceptors;
    client_hdr.ethernet.valid := true;
    client_hdr.ipv4.valid := true;
    client_hdr.udp.valid := true;
    client_hdr.paxos.valid := true;
    client_hdr.ethernet.etherType := 2048bv16;
    client_hdr.ipv4.protocol := 17bv8;
    client_hdr.udp.dstPort := 34952bv16;
    client_hdr.paxos.msgtype := 3bv16;
    client_hdr.paxos.rnd := 0bv16;
    client_hdr.paxos.paxosval := 1bv256;
    if ((dsl_phase == 0)) {
      client_hdr.paxos.inst := 0bv32;
      client_hdr.paxos.acptid := 0bv16;
      dsl_phase := 1;
    } else {
      if ((dsl_phase == 1)) {
        client_hdr.paxos.inst := 0bv32;
        client_hdr.paxos.acptid := 2bv16;
        dsl_phase := 2;
      } else {
        if ((dsl_phase == 2)) {
          client_hdr.paxos.inst := 1bv32;
          client_hdr.paxos.acptid := 0bv16;
          dsl_phase := 3;
        } else {
          dsl_reset_epoch := 1;
          client_hdr.paxos.inst := 0bv32;
          client_hdr.paxos.acptid := 0bv16;
        }
      }
    }
    learner_standard_metadata.ingress_port := client_standard_metadata.ingress_port;
    learner_standard_metadata.instance_type := client_standard_metadata.instance_type;
    learner_standard_metadata.packet_length := client_standard_metadata.packet_length;
    learner_standard_metadata.enq_timestamp := client_standard_metadata.enq_timestamp;
    learner_standard_metadata.enq_qdepth := client_standard_metadata.enq_qdepth;
    learner_standard_metadata.deq_timedelta := client_standard_metadata.deq_timedelta;
    learner_standard_metadata.deq_qdepth := client_standard_metadata.deq_qdepth;
    learner_standard_metadata.ingress_global_timestamp := client_standard_metadata.ingress_global_timestamp;
    learner_standard_metadata.egress_global_timestamp := client_standard_metadata.egress_global_timestamp;
    learner_standard_metadata.mcast_grp := client_standard_metadata.mcast_grp;
    learner_standard_metadata.egress_rid := client_standard_metadata.egress_rid;
    learner_standard_metadata.checksum_error := client_standard_metadata.checksum_error;
    learner_standard_metadata.parser_error := client_standard_metadata.parser_error;
    learner_standard_metadata.priority := client_standard_metadata.priority;
    learner_hdr.ethernet.valid := client_hdr.ethernet.valid;
    learner_hdr.ethernet.dstAddr := client_hdr.ethernet.dstAddr;
    learner_hdr.ethernet.srcAddr := client_hdr.ethernet.srcAddr;
    learner_hdr.ethernet.etherType := client_hdr.ethernet.etherType;
    learner_hdr.arp.valid := client_hdr.arp.valid;
    learner_hdr.arp.hrd := client_hdr.arp.hrd;
    learner_hdr.arp.pro := client_hdr.arp.pro;
    learner_hdr.arp.hln := client_hdr.arp.hln;
    learner_hdr.arp.pln := client_hdr.arp.pln;
    learner_hdr.arp.op := client_hdr.arp.op;
    learner_hdr.arp.sha := client_hdr.arp.sha;
    learner_hdr.arp.spa := client_hdr.arp.spa;
    learner_hdr.arp.tha := client_hdr.arp.tha;
    learner_hdr.arp.tpa := client_hdr.arp.tpa;
    learner_hdr.ipv4.valid := client_hdr.ipv4.valid;
    learner_hdr.ipv4.version := client_hdr.ipv4.version;
    learner_hdr.ipv4.ihl := client_hdr.ipv4.ihl;
    learner_hdr.ipv4.diffserv := client_hdr.ipv4.diffserv;
    learner_hdr.ipv4.totalLen := client_hdr.ipv4.totalLen;
    learner_hdr.ipv4.identification := client_hdr.ipv4.identification;
    learner_hdr.ipv4.flags := client_hdr.ipv4.flags;
    learner_hdr.ipv4.fragOffset := client_hdr.ipv4.fragOffset;
    learner_hdr.ipv4.ttl := client_hdr.ipv4.ttl;
    learner_hdr.ipv4.protocol := client_hdr.ipv4.protocol;
    learner_hdr.ipv4.hdrChecksum := client_hdr.ipv4.hdrChecksum;
    learner_hdr.ipv4.srcAddr := client_hdr.ipv4.srcAddr;
    learner_hdr.ipv4.dstAddr := client_hdr.ipv4.dstAddr;
    learner_hdr.icmp.valid := client_hdr.icmp.valid;
    learner_hdr.icmp.icmpType := client_hdr.icmp.icmpType;
    learner_hdr.icmp.icmpCode := client_hdr.icmp.icmpCode;
    learner_hdr.icmp.hdrChecksum := client_hdr.icmp.hdrChecksum;
    learner_hdr.icmp.identifier := client_hdr.icmp.identifier;
    learner_hdr.icmp.seqNumber := client_hdr.icmp.seqNumber;
    learner_hdr.icmp.payload := client_hdr.icmp.payload;
    learner_hdr.udp.valid := client_hdr.udp.valid;
    learner_hdr.udp.srcPort := client_hdr.udp.srcPort;
    learner_hdr.udp.dstPort := client_hdr.udp.dstPort;
    learner_hdr.udp.length_ := client_hdr.udp.length_;
    learner_hdr.udp.checksum := client_hdr.udp.checksum;
    learner_hdr.paxos.valid := client_hdr.paxos.valid;
    learner_hdr.paxos.msgtype := client_hdr.paxos.msgtype;
    learner_hdr.paxos.inst := client_hdr.paxos.inst;
    learner_hdr.paxos.rnd := client_hdr.paxos.rnd;
    learner_hdr.paxos.vrnd := client_hdr.paxos.vrnd;
    learner_hdr.paxos.acptid := client_hdr.paxos.acptid;
    learner_hdr.paxos.paxoslen := client_hdr.paxos.paxoslen;
    learner_hdr.paxos.paxosval := client_hdr.paxos.paxosval;
    learner_meta.paxos_metadata := client_meta.paxos_metadata;
    learner_meta.paxos_metadata.round := client_meta.paxos_metadata.round;
    learner_meta.paxos_metadata.set_drop := client_meta.paxos_metadata.set_drop;
    learner_meta.paxos_metadata.ack_count := client_meta.paxos_metadata.ack_count;
    learner_meta.paxos_metadata.ack_acceptors := client_meta.paxos_metadata.ack_acceptors;
    learner_pkt_external := true;
    learner_inbox_count := learner_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 13: host_recv -> client
  procurator_step := procurator_step + 1;
  // step 14: node_pass -> learner
  if (learner_inbox_count > 0) {
  assume learner_inbox_count > 0;
  learner_inbox_count := learner_inbox_count - 1;
  // DSL statements (per-pass instrumentation)
  if ((learner_dsl_seen_epoch != dsl_reset_epoch)) {
    learner_dsl_seen_epoch := dsl_reset_epoch;
    learner_dsl_seen_a0 := false;
    learner_dsl_seen_a1 := false;
    learner_dsl_seen_a2 := false;
    learner_dsl_vote_cnt := 0;
  }
  if ((learner_hdr.paxos.valid && (learner_hdr.paxos.msgtype == 3bv16) && (learner_hdr.paxos.inst == 0bv32))) {
    if (((learner_hdr.paxos.acptid == 0bv16) && !(learner_dsl_seen_a0))) {
      learner_dsl_seen_a0 := true;
      learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
    } else {
      if (((learner_hdr.paxos.acptid == 1bv16) && !(learner_dsl_seen_a1))) {
        learner_dsl_seen_a1 := true;
        learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
      } else {
        if (((learner_hdr.paxos.acptid == 2bv16) && !(learner_dsl_seen_a2))) {
          learner_dsl_seen_a2 := true;
          learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
        }
      }
    }
  }
  call learner_mainProcedure();
  if (learner_p4b_clone_i2e) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_i2e := false;
  if (learner_p4b_clone_e2e) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_e2e := false;
  if (learner_p4b_clone_i2i) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_i2i := false;
  if (learner_p4b_recirculate) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_recirculate := false;
  call learner_Forward();
  // Register debug snapshot
  learner_ingress_registerHistory2B__dbg0 := learner_ingress_registerHistory2B[0bv32];
  learner_ingress_registerHistory2B__last_index__dbg := learner_ingress_registerHistory2B__last_index;
  learner_ingress_registerHistory2B__last_value__dbg := learner_ingress_registerHistory2B__last_value;
  learner_ingress_registerHistory2B__last_old_value__dbg := learner_ingress_registerHistory2B__last_old_value;
  learner_ingress_registerHistory2B__wrote_any__dbg := learner_ingress_registerHistory2B__wrote_any;
  learner_ingress_registerHistory2B__wrote_index0__dbg := learner_ingress_registerHistory2B__wrote_index0;
  learner_ingress_registerHistory2B__last0_old_value__dbg := learner_ingress_registerHistory2B__last0_old_value;
  learner_ingress_registerHistory2B__last0_value__dbg := learner_ingress_registerHistory2B__last0_value;
  learner_ingress_registerRound__dbg0 := learner_ingress_registerRound[0bv32];
  learner_ingress_registerRound__last_index__dbg := learner_ingress_registerRound__last_index;
  learner_ingress_registerRound__last_value__dbg := learner_ingress_registerRound__last_value;
  learner_ingress_registerRound__last_old_value__dbg := learner_ingress_registerRound__last_old_value;
  learner_ingress_registerRound__wrote_any__dbg := learner_ingress_registerRound__wrote_any;
  learner_ingress_registerRound__wrote_index0__dbg := learner_ingress_registerRound__wrote_index0;
  learner_ingress_registerRound__last0_old_value__dbg := learner_ingress_registerRound__last0_old_value;
  learner_ingress_registerRound__last0_value__dbg := learner_ingress_registerRound__last0_value;
  learner_ingress_registerValue__dbg0 := learner_ingress_registerValue[0bv32];
  learner_ingress_registerValue__last_index__dbg := learner_ingress_registerValue__last_index;
  learner_ingress_registerValue__last_value__dbg := learner_ingress_registerValue__last_value;
  learner_ingress_registerValue__last_old_value__dbg := learner_ingress_registerValue__last_old_value;
  learner_ingress_registerValue__wrote_any__dbg := learner_ingress_registerValue__wrote_any;
  learner_ingress_registerValue__wrote_index0__dbg := learner_ingress_registerValue__wrote_index0;
  learner_ingress_registerValue__last0_old_value__dbg := learner_ingress_registerValue__last0_old_value;
  learner_ingress_registerValue__last0_value__dbg := learner_ingress_registerValue__last0_value;
  // Global assertions (accumulated into procurator_bad)
  if (!(((dsl_reset_epoch < 1) || (learner_hdr.paxos.inst != 0bv32) || ((learner_meta.paxos_metadata.ack_acceptors != 3bv8) && (learner_meta.paxos_metadata.ack_acceptors != 5bv8) && (learner_meta.paxos_metadata.ack_acceptors != 6bv8)) || (learner_dsl_vote_cnt >= 2)))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  // step 15: host_send -> client
  // inject packet into connected node (host -> node)
  if (learner_inbox_count < 1) {
    assume learner_inbox_count < 1;
    havoc client_standard_metadata.ingress_port;
    havoc client_standard_metadata.instance_type;
    havoc client_standard_metadata.packet_length;
    havoc client_standard_metadata.enq_timestamp;
    havoc client_standard_metadata.enq_qdepth;
    havoc client_standard_metadata.deq_timedelta;
    havoc client_standard_metadata.deq_qdepth;
    havoc client_standard_metadata.ingress_global_timestamp;
    havoc client_standard_metadata.egress_global_timestamp;
    havoc client_standard_metadata.mcast_grp;
    havoc client_standard_metadata.egress_rid;
    havoc client_standard_metadata.checksum_error;
    havoc client_standard_metadata.parser_error;
    havoc client_standard_metadata.priority;
    havoc client_hdr.ethernet.dstAddr;
    havoc client_hdr.ethernet.srcAddr;
    havoc client_hdr.arp.valid;
    havoc client_hdr.arp.hrd;
    havoc client_hdr.arp.pro;
    havoc client_hdr.arp.hln;
    havoc client_hdr.arp.pln;
    havoc client_hdr.arp.op;
    havoc client_hdr.arp.sha;
    havoc client_hdr.arp.spa;
    havoc client_hdr.arp.tha;
    havoc client_hdr.arp.tpa;
    havoc client_hdr.ipv4.version;
    havoc client_hdr.ipv4.ihl;
    havoc client_hdr.ipv4.diffserv;
    havoc client_hdr.ipv4.totalLen;
    havoc client_hdr.ipv4.identification;
    havoc client_hdr.ipv4.flags;
    havoc client_hdr.ipv4.fragOffset;
    havoc client_hdr.ipv4.ttl;
    havoc client_hdr.ipv4.hdrChecksum;
    havoc client_hdr.ipv4.srcAddr;
    havoc client_hdr.ipv4.dstAddr;
    havoc client_hdr.icmp.valid;
    havoc client_hdr.icmp.icmpType;
    havoc client_hdr.icmp.icmpCode;
    havoc client_hdr.icmp.hdrChecksum;
    havoc client_hdr.icmp.identifier;
    havoc client_hdr.icmp.seqNumber;
    havoc client_hdr.icmp.payload;
    havoc client_hdr.udp.srcPort;
    havoc client_hdr.udp.length_;
    havoc client_hdr.udp.checksum;
    havoc client_hdr.paxos.inst;
    havoc client_hdr.paxos.vrnd;
    havoc client_hdr.paxos.acptid;
    havoc client_hdr.paxos.paxoslen;
    havoc client_meta.paxos_metadata;
    havoc client_meta.paxos_metadata.round;
    havoc client_meta.paxos_metadata.set_drop;
    havoc client_meta.paxos_metadata.ack_count;
    havoc client_meta.paxos_metadata.ack_acceptors;
    client_hdr.ethernet.valid := true;
    client_hdr.ipv4.valid := true;
    client_hdr.udp.valid := true;
    client_hdr.paxos.valid := true;
    client_hdr.ethernet.etherType := 2048bv16;
    client_hdr.ipv4.protocol := 17bv8;
    client_hdr.udp.dstPort := 34952bv16;
    client_hdr.paxos.msgtype := 3bv16;
    client_hdr.paxos.rnd := 0bv16;
    client_hdr.paxos.paxosval := 1bv256;
    if ((dsl_phase == 0)) {
      client_hdr.paxos.inst := 0bv32;
      client_hdr.paxos.acptid := 0bv16;
      dsl_phase := 1;
    } else {
      if ((dsl_phase == 1)) {
        client_hdr.paxos.inst := 0bv32;
        client_hdr.paxos.acptid := 2bv16;
        dsl_phase := 2;
      } else {
        if ((dsl_phase == 2)) {
          client_hdr.paxos.inst := 1bv32;
          client_hdr.paxos.acptid := 0bv16;
          dsl_phase := 3;
        } else {
          dsl_reset_epoch := 1;
          client_hdr.paxos.inst := 0bv32;
          client_hdr.paxos.acptid := 0bv16;
        }
      }
    }
    learner_standard_metadata.ingress_port := client_standard_metadata.ingress_port;
    learner_standard_metadata.instance_type := client_standard_metadata.instance_type;
    learner_standard_metadata.packet_length := client_standard_metadata.packet_length;
    learner_standard_metadata.enq_timestamp := client_standard_metadata.enq_timestamp;
    learner_standard_metadata.enq_qdepth := client_standard_metadata.enq_qdepth;
    learner_standard_metadata.deq_timedelta := client_standard_metadata.deq_timedelta;
    learner_standard_metadata.deq_qdepth := client_standard_metadata.deq_qdepth;
    learner_standard_metadata.ingress_global_timestamp := client_standard_metadata.ingress_global_timestamp;
    learner_standard_metadata.egress_global_timestamp := client_standard_metadata.egress_global_timestamp;
    learner_standard_metadata.mcast_grp := client_standard_metadata.mcast_grp;
    learner_standard_metadata.egress_rid := client_standard_metadata.egress_rid;
    learner_standard_metadata.checksum_error := client_standard_metadata.checksum_error;
    learner_standard_metadata.parser_error := client_standard_metadata.parser_error;
    learner_standard_metadata.priority := client_standard_metadata.priority;
    learner_hdr.ethernet.valid := client_hdr.ethernet.valid;
    learner_hdr.ethernet.dstAddr := client_hdr.ethernet.dstAddr;
    learner_hdr.ethernet.srcAddr := client_hdr.ethernet.srcAddr;
    learner_hdr.ethernet.etherType := client_hdr.ethernet.etherType;
    learner_hdr.arp.valid := client_hdr.arp.valid;
    learner_hdr.arp.hrd := client_hdr.arp.hrd;
    learner_hdr.arp.pro := client_hdr.arp.pro;
    learner_hdr.arp.hln := client_hdr.arp.hln;
    learner_hdr.arp.pln := client_hdr.arp.pln;
    learner_hdr.arp.op := client_hdr.arp.op;
    learner_hdr.arp.sha := client_hdr.arp.sha;
    learner_hdr.arp.spa := client_hdr.arp.spa;
    learner_hdr.arp.tha := client_hdr.arp.tha;
    learner_hdr.arp.tpa := client_hdr.arp.tpa;
    learner_hdr.ipv4.valid := client_hdr.ipv4.valid;
    learner_hdr.ipv4.version := client_hdr.ipv4.version;
    learner_hdr.ipv4.ihl := client_hdr.ipv4.ihl;
    learner_hdr.ipv4.diffserv := client_hdr.ipv4.diffserv;
    learner_hdr.ipv4.totalLen := client_hdr.ipv4.totalLen;
    learner_hdr.ipv4.identification := client_hdr.ipv4.identification;
    learner_hdr.ipv4.flags := client_hdr.ipv4.flags;
    learner_hdr.ipv4.fragOffset := client_hdr.ipv4.fragOffset;
    learner_hdr.ipv4.ttl := client_hdr.ipv4.ttl;
    learner_hdr.ipv4.protocol := client_hdr.ipv4.protocol;
    learner_hdr.ipv4.hdrChecksum := client_hdr.ipv4.hdrChecksum;
    learner_hdr.ipv4.srcAddr := client_hdr.ipv4.srcAddr;
    learner_hdr.ipv4.dstAddr := client_hdr.ipv4.dstAddr;
    learner_hdr.icmp.valid := client_hdr.icmp.valid;
    learner_hdr.icmp.icmpType := client_hdr.icmp.icmpType;
    learner_hdr.icmp.icmpCode := client_hdr.icmp.icmpCode;
    learner_hdr.icmp.hdrChecksum := client_hdr.icmp.hdrChecksum;
    learner_hdr.icmp.identifier := client_hdr.icmp.identifier;
    learner_hdr.icmp.seqNumber := client_hdr.icmp.seqNumber;
    learner_hdr.icmp.payload := client_hdr.icmp.payload;
    learner_hdr.udp.valid := client_hdr.udp.valid;
    learner_hdr.udp.srcPort := client_hdr.udp.srcPort;
    learner_hdr.udp.dstPort := client_hdr.udp.dstPort;
    learner_hdr.udp.length_ := client_hdr.udp.length_;
    learner_hdr.udp.checksum := client_hdr.udp.checksum;
    learner_hdr.paxos.valid := client_hdr.paxos.valid;
    learner_hdr.paxos.msgtype := client_hdr.paxos.msgtype;
    learner_hdr.paxos.inst := client_hdr.paxos.inst;
    learner_hdr.paxos.rnd := client_hdr.paxos.rnd;
    learner_hdr.paxos.vrnd := client_hdr.paxos.vrnd;
    learner_hdr.paxos.acptid := client_hdr.paxos.acptid;
    learner_hdr.paxos.paxoslen := client_hdr.paxos.paxoslen;
    learner_hdr.paxos.paxosval := client_hdr.paxos.paxosval;
    learner_meta.paxos_metadata := client_meta.paxos_metadata;
    learner_meta.paxos_metadata.round := client_meta.paxos_metadata.round;
    learner_meta.paxos_metadata.set_drop := client_meta.paxos_metadata.set_drop;
    learner_meta.paxos_metadata.ack_count := client_meta.paxos_metadata.ack_count;
    learner_meta.paxos_metadata.ack_acceptors := client_meta.paxos_metadata.ack_acceptors;
    learner_pkt_external := true;
    learner_inbox_count := learner_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 16: host_recv -> client
  procurator_step := procurator_step + 1;
  // step 17: node_pass -> learner
  if (learner_inbox_count > 0) {
  assume learner_inbox_count > 0;
  learner_inbox_count := learner_inbox_count - 1;
  // DSL statements (per-pass instrumentation)
  if ((learner_dsl_seen_epoch != dsl_reset_epoch)) {
    learner_dsl_seen_epoch := dsl_reset_epoch;
    learner_dsl_seen_a0 := false;
    learner_dsl_seen_a1 := false;
    learner_dsl_seen_a2 := false;
    learner_dsl_vote_cnt := 0;
  }
  if ((learner_hdr.paxos.valid && (learner_hdr.paxos.msgtype == 3bv16) && (learner_hdr.paxos.inst == 0bv32))) {
    if (((learner_hdr.paxos.acptid == 0bv16) && !(learner_dsl_seen_a0))) {
      learner_dsl_seen_a0 := true;
      learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
    } else {
      if (((learner_hdr.paxos.acptid == 1bv16) && !(learner_dsl_seen_a1))) {
        learner_dsl_seen_a1 := true;
        learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
      } else {
        if (((learner_hdr.paxos.acptid == 2bv16) && !(learner_dsl_seen_a2))) {
          learner_dsl_seen_a2 := true;
          learner_dsl_vote_cnt := learner_dsl_vote_cnt + 1;
        }
      }
    }
  }
  call learner_mainProcedure();
  if (learner_p4b_clone_i2e) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_i2e := false;
  if (learner_p4b_clone_e2e) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_e2e := false;
  if (learner_p4b_clone_i2i) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_clone_i2i := false;
  if (learner_p4b_recirculate) {
    assume learner_inbox_count < 1;
    learner_pkt_external := false;
    learner_inbox_count := learner_inbox_count + 1;
  }
  learner_p4b_recirculate := false;
  call learner_Forward();
  // Register debug snapshot
  learner_ingress_registerHistory2B__dbg0 := learner_ingress_registerHistory2B[0bv32];
  learner_ingress_registerHistory2B__last_index__dbg := learner_ingress_registerHistory2B__last_index;
  learner_ingress_registerHistory2B__last_value__dbg := learner_ingress_registerHistory2B__last_value;
  learner_ingress_registerHistory2B__last_old_value__dbg := learner_ingress_registerHistory2B__last_old_value;
  learner_ingress_registerHistory2B__wrote_any__dbg := learner_ingress_registerHistory2B__wrote_any;
  learner_ingress_registerHistory2B__wrote_index0__dbg := learner_ingress_registerHistory2B__wrote_index0;
  learner_ingress_registerHistory2B__last0_old_value__dbg := learner_ingress_registerHistory2B__last0_old_value;
  learner_ingress_registerHistory2B__last0_value__dbg := learner_ingress_registerHistory2B__last0_value;
  learner_ingress_registerRound__dbg0 := learner_ingress_registerRound[0bv32];
  learner_ingress_registerRound__last_index__dbg := learner_ingress_registerRound__last_index;
  learner_ingress_registerRound__last_value__dbg := learner_ingress_registerRound__last_value;
  learner_ingress_registerRound__last_old_value__dbg := learner_ingress_registerRound__last_old_value;
  learner_ingress_registerRound__wrote_any__dbg := learner_ingress_registerRound__wrote_any;
  learner_ingress_registerRound__wrote_index0__dbg := learner_ingress_registerRound__wrote_index0;
  learner_ingress_registerRound__last0_old_value__dbg := learner_ingress_registerRound__last0_old_value;
  learner_ingress_registerRound__last0_value__dbg := learner_ingress_registerRound__last0_value;
  learner_ingress_registerValue__dbg0 := learner_ingress_registerValue[0bv32];
  learner_ingress_registerValue__last_index__dbg := learner_ingress_registerValue__last_index;
  learner_ingress_registerValue__last_value__dbg := learner_ingress_registerValue__last_value;
  learner_ingress_registerValue__last_old_value__dbg := learner_ingress_registerValue__last_old_value;
  learner_ingress_registerValue__wrote_any__dbg := learner_ingress_registerValue__wrote_any;
  learner_ingress_registerValue__wrote_index0__dbg := learner_ingress_registerValue__wrote_index0;
  learner_ingress_registerValue__last0_old_value__dbg := learner_ingress_registerValue__last0_old_value;
  learner_ingress_registerValue__last0_value__dbg := learner_ingress_registerValue__last0_value;
  // Global assertions (accumulated into procurator_bad)
  if (!(((dsl_reset_epoch < 1) || (learner_hdr.paxos.inst != 0bv32) || ((learner_meta.paxos_metadata.ack_acceptors != 3bv8) && (learner_meta.paxos_metadata.ack_acceptors != 5bv8) && (learner_meta.paxos_metadata.ack_acceptors != 6bv8)) || (learner_dsl_vote_cnt >= 2)))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  // step 18: host_send -> client
  // inject packet into connected node (host -> node)
  if (learner_inbox_count < 1) {
    assume learner_inbox_count < 1;
    havoc client_standard_metadata.ingress_port;
    havoc client_standard_metadata.instance_type;
    havoc client_standard_metadata.packet_length;
    havoc client_standard_metadata.enq_timestamp;
    havoc client_standard_metadata.enq_qdepth;
    havoc client_standard_metadata.deq_timedelta;
    havoc client_standard_metadata.deq_qdepth;
    havoc client_standard_metadata.ingress_global_timestamp;
    havoc client_standard_metadata.egress_global_timestamp;
    havoc client_standard_metadata.mcast_grp;
    havoc client_standard_metadata.egress_rid;
    havoc client_standard_metadata.checksum_error;
    havoc client_standard_metadata.parser_error;
    havoc client_standard_metadata.priority;
    havoc client_hdr.ethernet.dstAddr;
    havoc client_hdr.ethernet.srcAddr;
    havoc client_hdr.arp.valid;
    havoc client_hdr.arp.hrd;
    havoc client_hdr.arp.pro;
    havoc client_hdr.arp.hln;
    havoc client_hdr.arp.pln;
    havoc client_hdr.arp.op;
    havoc client_hdr.arp.sha;
    havoc client_hdr.arp.spa;
    havoc client_hdr.arp.tha;
    havoc client_hdr.arp.tpa;
    havoc client_hdr.ipv4.version;
    havoc client_hdr.ipv4.ihl;
    havoc client_hdr.ipv4.diffserv;
    havoc client_hdr.ipv4.totalLen;
    havoc client_hdr.ipv4.identification;
    havoc client_hdr.ipv4.flags;
    havoc client_hdr.ipv4.fragOffset;
    havoc client_hdr.ipv4.ttl;
    havoc client_hdr.ipv4.hdrChecksum;
    havoc client_hdr.ipv4.srcAddr;
    havoc client_hdr.ipv4.dstAddr;
    havoc client_hdr.icmp.valid;
    havoc client_hdr.icmp.icmpType;
    havoc client_hdr.icmp.icmpCode;
    havoc client_hdr.icmp.hdrChecksum;
    havoc client_hdr.icmp.identifier;
    havoc client_hdr.icmp.seqNumber;
    havoc client_hdr.icmp.payload;
    havoc client_hdr.udp.srcPort;
    havoc client_hdr.udp.length_;
    havoc client_hdr.udp.checksum;
    havoc client_hdr.paxos.inst;
    havoc client_hdr.paxos.vrnd;
    havoc client_hdr.paxos.acptid;
    havoc client_hdr.paxos.paxoslen;
    havoc client_meta.paxos_metadata;
    havoc client_meta.paxos_metadata.round;
    havoc client_meta.paxos_metadata.set_drop;
    havoc client_meta.paxos_metadata.ack_count;
    havoc client_meta.paxos_metadata.ack_acceptors;
    client_hdr.ethernet.valid := true;
    client_hdr.ipv4.valid := true;
    client_hdr.udp.valid := true;
    client_hdr.paxos.valid := true;
    client_hdr.ethernet.etherType := 2048bv16;
    client_hdr.ipv4.protocol := 17bv8;
    client_hdr.udp.dstPort := 34952bv16;
    client_hdr.paxos.msgtype := 3bv16;
    client_hdr.paxos.rnd := 0bv16;
    client_hdr.paxos.paxosval := 1bv256;
    if ((dsl_phase == 0)) {
      client_hdr.paxos.inst := 0bv32;
      client_hdr.paxos.acptid := 0bv16;
      dsl_phase := 1;
    } else {
      if ((dsl_phase == 1)) {
        client_hdr.paxos.inst := 0bv32;
        client_hdr.paxos.acptid := 2bv16;
        dsl_phase := 2;
      } else {
        if ((dsl_phase == 2)) {
          client_hdr.paxos.inst := 1bv32;
          client_hdr.paxos.acptid := 0bv16;
          dsl_phase := 3;
        } else {
          dsl_reset_epoch := 1;
          client_hdr.paxos.inst := 0bv32;
          client_hdr.paxos.acptid := 0bv16;
        }
      }
    }
    learner_standard_metadata.ingress_port := client_standard_metadata.ingress_port;
    learner_standard_metadata.instance_type := client_standard_metadata.instance_type;
    learner_standard_metadata.packet_length := client_standard_metadata.packet_length;
    learner_standard_metadata.enq_timestamp := client_standard_metadata.enq_timestamp;
    learner_standard_metadata.enq_qdepth := client_standard_metadata.enq_qdepth;
    learner_standard_metadata.deq_timedelta := client_standard_metadata.deq_timedelta;
    learner_standard_metadata.deq_qdepth := client_standard_metadata.deq_qdepth;
    learner_standard_metadata.ingress_global_timestamp := client_standard_metadata.ingress_global_timestamp;
    learner_standard_metadata.egress_global_timestamp := client_standard_metadata.egress_global_timestamp;
    learner_standard_metadata.mcast_grp := client_standard_metadata.mcast_grp;
    learner_standard_metadata.egress_rid := client_standard_metadata.egress_rid;
    learner_standard_metadata.checksum_error := client_standard_metadata.checksum_error;
    learner_standard_metadata.parser_error := client_standard_metadata.parser_error;
    learner_standard_metadata.priority := client_standard_metadata.priority;
    learner_hdr.ethernet.valid := client_hdr.ethernet.valid;
    learner_hdr.ethernet.dstAddr := client_hdr.ethernet.dstAddr;
    learner_hdr.ethernet.srcAddr := client_hdr.ethernet.srcAddr;
    learner_hdr.ethernet.etherType := client_hdr.ethernet.etherType;
    learner_hdr.arp.valid := client_hdr.arp.valid;
    learner_hdr.arp.hrd := client_hdr.arp.hrd;
    learner_hdr.arp.pro := client_hdr.arp.pro;
    learner_hdr.arp.hln := client_hdr.arp.hln;
    learner_hdr.arp.pln := client_hdr.arp.pln;
    learner_hdr.arp.op := client_hdr.arp.op;
    learner_hdr.arp.sha := client_hdr.arp.sha;
    learner_hdr.arp.spa := client_hdr.arp.spa;
    learner_hdr.arp.tha := client_hdr.arp.tha;
    learner_hdr.arp.tpa := client_hdr.arp.tpa;
    learner_hdr.ipv4.valid := client_hdr.ipv4.valid;
    learner_hdr.ipv4.version := client_hdr.ipv4.version;
    learner_hdr.ipv4.ihl := client_hdr.ipv4.ihl;
    learner_hdr.ipv4.diffserv := client_hdr.ipv4.diffserv;
    learner_hdr.ipv4.totalLen := client_hdr.ipv4.totalLen;
    learner_hdr.ipv4.identification := client_hdr.ipv4.identification;
    learner_hdr.ipv4.flags := client_hdr.ipv4.flags;
    learner_hdr.ipv4.fragOffset := client_hdr.ipv4.fragOffset;
    learner_hdr.ipv4.ttl := client_hdr.ipv4.ttl;
    learner_hdr.ipv4.protocol := client_hdr.ipv4.protocol;
    learner_hdr.ipv4.hdrChecksum := client_hdr.ipv4.hdrChecksum;
    learner_hdr.ipv4.srcAddr := client_hdr.ipv4.srcAddr;
    learner_hdr.ipv4.dstAddr := client_hdr.ipv4.dstAddr;
    learner_hdr.icmp.valid := client_hdr.icmp.valid;
    learner_hdr.icmp.icmpType := client_hdr.icmp.icmpType;
    learner_hdr.icmp.icmpCode := client_hdr.icmp.icmpCode;
    learner_hdr.icmp.hdrChecksum := client_hdr.icmp.hdrChecksum;
    learner_hdr.icmp.identifier := client_hdr.icmp.identifier;
    learner_hdr.icmp.seqNumber := client_hdr.icmp.seqNumber;
    learner_hdr.icmp.payload := client_hdr.icmp.payload;
    learner_hdr.udp.valid := client_hdr.udp.valid;
    learner_hdr.udp.srcPort := client_hdr.udp.srcPort;
    learner_hdr.udp.dstPort := client_hdr.udp.dstPort;
    learner_hdr.udp.length_ := client_hdr.udp.length_;
    learner_hdr.udp.checksum := client_hdr.udp.checksum;
    learner_hdr.paxos.valid := client_hdr.paxos.valid;
    learner_hdr.paxos.msgtype := client_hdr.paxos.msgtype;
    learner_hdr.paxos.inst := client_hdr.paxos.inst;
    learner_hdr.paxos.rnd := client_hdr.paxos.rnd;
    learner_hdr.paxos.vrnd := client_hdr.paxos.vrnd;
    learner_hdr.paxos.acptid := client_hdr.paxos.acptid;
    learner_hdr.paxos.paxoslen := client_hdr.paxos.paxoslen;
    learner_hdr.paxos.paxosval := client_hdr.paxos.paxosval;
    learner_meta.paxos_metadata := client_meta.paxos_metadata;
    learner_meta.paxos_metadata.round := client_meta.paxos_metadata.round;
    learner_meta.paxos_metadata.set_drop := client_meta.paxos_metadata.set_drop;
    learner_meta.paxos_metadata.ack_count := client_meta.paxos_metadata.ack_count;
    learner_meta.paxos_metadata.ack_acceptors := client_meta.paxos_metadata.ack_acceptors;
    learner_pkt_external := true;
    learner_inbox_count := learner_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 19: host_recv -> client
  procurator_step := procurator_step + 1;
  assert !procurator_bad;
}


procedure ULTIMATE.start() returns()
  modifies client_hdr.arp.hln, client_hdr.arp.hrd, client_hdr.arp.op, client_hdr.arp.pln, client_hdr.arp.pro, client_hdr.arp.sha, client_hdr.arp.spa, client_hdr.arp.tha, client_hdr.arp.tpa, client_hdr.arp.valid, client_hdr.ethernet.dstAddr, client_hdr.ethernet.etherType, client_hdr.ethernet.srcAddr, client_hdr.ethernet.valid, client_hdr.icmp.hdrChecksum, client_hdr.icmp.icmpCode, client_hdr.icmp.icmpType, client_hdr.icmp.identifier, client_hdr.icmp.payload, client_hdr.icmp.seqNumber, client_hdr.icmp.valid, client_hdr.ipv4.diffserv, client_hdr.ipv4.dstAddr, client_hdr.ipv4.flags, client_hdr.ipv4.fragOffset, client_hdr.ipv4.hdrChecksum, client_hdr.ipv4.identification, client_hdr.ipv4.ihl, client_hdr.ipv4.protocol, client_hdr.ipv4.srcAddr, client_hdr.ipv4.totalLen, client_hdr.ipv4.ttl, client_hdr.ipv4.valid, client_hdr.ipv4.version, client_hdr.paxos.acptid, client_hdr.paxos.inst, client_hdr.paxos.msgtype, client_hdr.paxos.paxoslen, client_hdr.paxos.paxosval, client_hdr.paxos.rnd, client_hdr.paxos.valid, client_hdr.paxos.vrnd, client_hdr.udp.checksum, client_hdr.udp.dstPort, client_hdr.udp.length_, client_hdr.udp.srcPort, client_hdr.udp.valid, client_inbox_count, client_meta.paxos_metadata, client_meta.paxos_metadata.ack_acceptors, client_meta.paxos_metadata.ack_count, client_meta.paxos_metadata.round, client_meta.paxos_metadata.set_drop, client_pkt_external, client_standard_metadata.checksum_error, client_standard_metadata.deq_qdepth, client_standard_metadata.deq_timedelta, client_standard_metadata.egress_global_timestamp, client_standard_metadata.egress_rid, client_standard_metadata.enq_qdepth, client_standard_metadata.enq_timestamp, client_standard_metadata.ingress_global_timestamp, client_standard_metadata.ingress_port, client_standard_metadata.instance_type, client_standard_metadata.mcast_grp, client_standard_metadata.packet_length, client_standard_metadata.parser_error, client_standard_metadata.priority, dsl_phase, dsl_reset_epoch, learner_acptid_0, learner_acptid_1, learner_drop, learner_dsl_seen_a0, learner_dsl_seen_a1, learner_dsl_seen_a2, learner_dsl_seen_epoch, learner_dsl_vote_cnt, learner_egress_place_holder_table.action_run, learner_egress_place_holder_table.hit, learner_forward, learner_hdr.arp.hln, learner_hdr.arp.hrd, learner_hdr.arp.op, learner_hdr.arp.pln, learner_hdr.arp.pro, learner_hdr.arp.sha, learner_hdr.arp.spa, learner_hdr.arp.tha, learner_hdr.arp.tpa, learner_hdr.arp.valid, learner_hdr.ethernet.dstAddr, learner_hdr.ethernet.etherType, learner_hdr.ethernet.srcAddr, learner_hdr.ethernet.valid, learner_hdr.icmp.hdrChecksum, learner_hdr.icmp.icmpCode, learner_hdr.icmp.icmpType, learner_hdr.icmp.identifier, learner_hdr.icmp.payload, learner_hdr.icmp.seqNumber, learner_hdr.icmp.valid, learner_hdr.ipv4.diffserv, learner_hdr.ipv4.dstAddr, learner_hdr.ipv4.flags, learner_hdr.ipv4.fragOffset, learner_hdr.ipv4.hdrChecksum, learner_hdr.ipv4.identification, learner_hdr.ipv4.ihl, learner_hdr.ipv4.protocol, learner_hdr.ipv4.srcAddr, learner_hdr.ipv4.totalLen, learner_hdr.ipv4.ttl, learner_hdr.ipv4.valid, learner_hdr.ipv4.version, learner_hdr.paxos.acptid, learner_hdr.paxos.inst, learner_hdr.paxos.msgtype, learner_hdr.paxos.paxoslen, learner_hdr.paxos.paxosval, learner_hdr.paxos.rnd, learner_hdr.paxos.valid, learner_hdr.paxos.vrnd, learner_hdr.udp.checksum, learner_hdr.udp.dstPort, learner_hdr.udp.length_, learner_hdr.udp.srcPort, learner_hdr.udp.valid, learner_inbox_count, learner_ingress_learner_tbl.action_run, learner_ingress_learner_tbl.hit, learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__dbg0, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_old_value__dbg, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last0_value__dbg, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_index__dbg, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_old_value__dbg, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_value__dbg, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__next_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_any__dbg, learner_ingress_registerHistory2B__wrote_index0, learner_ingress_registerHistory2B__wrote_index0__dbg, learner_ingress_registerRound, learner_ingress_registerRound__dbg0, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_old_value__dbg, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last0_value__dbg, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_index__dbg, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_old_value__dbg, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_value__dbg, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__next_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_any__dbg, learner_ingress_registerRound__wrote_index0, learner_ingress_registerRound__wrote_index0__dbg, learner_ingress_registerValue, learner_ingress_registerValue__dbg0, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_old_value__dbg, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last0_value__dbg, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_index__dbg, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_old_value__dbg, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_value__dbg, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__next_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_any__dbg, learner_ingress_registerValue__wrote_index0, learner_ingress_registerValue__wrote_index0__dbg, learner_ingress_reset_consensus_instance.action_run, learner_ingress_reset_consensus_instance.hit, learner_ingress_transport_tbl.action_run, learner_ingress_transport_tbl.hit, learner_ingress_transport_tbl.ingress_forward.learnerPort, learner_ingress_transport_tbl.ingress_forward.port, learner_isValid, learner_meta.paxos_metadata, learner_meta.paxos_metadata.ack_acceptors, learner_meta.paxos_metadata.ack_count, learner_meta.paxos_metadata.round, learner_meta.paxos_metadata.set_drop, learner_p4b_checksum_error, learner_p4b_checksum_updated, learner_p4b_checksum_verified, learner_p4b_clone_e2e, learner_p4b_clone_i2e, learner_p4b_clone_i2i, learner_p4b_digest, learner_p4b_recirculate, learner_pkt_external, learner_standard_metadata.checksum_error, learner_standard_metadata.deq_qdepth, learner_standard_metadata.deq_timedelta, learner_standard_metadata.egress_global_timestamp, learner_standard_metadata.egress_port, learner_standard_metadata.egress_rid, learner_standard_metadata.egress_spec, learner_standard_metadata.enq_qdepth, learner_standard_metadata.enq_timestamp, learner_standard_metadata.ingress_global_timestamp, learner_standard_metadata.ingress_port, learner_standard_metadata.instance_type, learner_standard_metadata.mcast_grp, learner_standard_metadata.packet_length, learner_standard_metadata.parser_error, learner_standard_metadata.priority, procurator_bad, procurator_step;
{
  call mainProcedure();
}

// ===== END HARNESS =====
