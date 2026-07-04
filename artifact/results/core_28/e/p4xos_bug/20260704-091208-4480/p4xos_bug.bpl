// ===== BEGIN PREAMBLE =====
function bvule.bv16(left:bv16, right:bv16) returns(bool);
function {:builtin "bvule"} bvule.bv16$builtin(left:bv16, right:bv16) returns(bool);
axiom (forall left:bv16, right:bv16 :: bvule.bv16(left, right) <==> bvule.bv16$builtin(left, right));
function bvule.bv32(left:bv32, right:bv32) returns(bool);
function {:builtin "bvule"} bvule.bv32$builtin(left:bv32, right:bv32) returns(bool);
axiom (forall left:bv32, right:bv32 :: bvule.bv32(left, right) <==> bvule.bv32$builtin(left, right));
// ===== END PREAMBLE =====

// ===== BEGIN NODE acceptor0 (prefixed) =====
type acceptor0_Ref;
type acceptor0_error=bv1;
type acceptor0_HeaderStack = [int]acceptor0_Ref;
var acceptor0_last:[acceptor0_HeaderStack]acceptor0_Ref;
var acceptor0_forward:bool;
var acceptor0_isValid:[acceptor0_Ref]bool;
var acceptor0_emit:[acceptor0_Ref]bool;
var acceptor0_stack.index:[acceptor0_HeaderStack]int;
var acceptor0_size:[acceptor0_HeaderStack]int;
var acceptor0_drop:bool;
var acceptor0_p4b_clone_i2e:bool;
var acceptor0_p4b_clone_e2e:bool;
var acceptor0_p4b_clone_i2i:bool;
var acceptor0_p4b_recirculate:bool;
var acceptor0_p4b_digest:bool;
var acceptor0_p4b_checksum_verified:bool;
var acceptor0_p4b_checksum_updated:bool;
var acceptor0_p4b_checksum_error:bool;

// acceptor0_Struct acceptor0_standard_metadata_t
type acceptor0_standard_metadata_t;
var acceptor0_standard_metadata.ingress_port:bv9;
var acceptor0_standard_metadata.egress_spec:bv9;
var acceptor0_standard_metadata.egress_port:bv9;
var acceptor0_standard_metadata.instance_type:bv32;
var acceptor0_standard_metadata.packet_length:bv32;
var acceptor0_standard_metadata.enq_timestamp:bv32;
var acceptor0_standard_metadata.enq_qdepth:bv19;
var acceptor0_standard_metadata.deq_timedelta:bv32;
var acceptor0_standard_metadata.deq_qdepth:bv19;
var acceptor0_standard_metadata.ingress_global_timestamp:bv48;
var acceptor0_standard_metadata.egress_global_timestamp:bv48;
var acceptor0_standard_metadata.mcast_grp:bv16;
var acceptor0_standard_metadata.egress_rid:bv16;
var acceptor0_standard_metadata.checksum_error:bv1;
var acceptor0_standard_metadata.parser_error:acceptor0_error;
var acceptor0_standard_metadata.priority:bv3;
type acceptor0_CounterType = int;
type acceptor0_MeterType = int;
type acceptor0_HashAlgorithm = int;
type acceptor0_CloneType = int;
type acceptor0_EthernetAddress = bv48;
type acceptor0_IPv4Address = bv32;
type acceptor0_PortId = bv4;
type acceptor0_ethernet_t;
type acceptor0_arp_t;
type acceptor0_ipv4_t;
type acceptor0_icmp_t;
type acceptor0_udp_t;
type acceptor0_paxos_t;

// acceptor0_Struct acceptor0_headers
var acceptor0_hdr:acceptor0_Ref;

// acceptor0_Header acceptor0_ethernet_t
var acceptor0_hdr.ethernet:acceptor0_Ref;
var acceptor0_hdr.ethernet.valid:bool;
var acceptor0_hdr.ethernet.dstAddr:acceptor0_EthernetAddress;
var acceptor0_hdr.ethernet.srcAddr:acceptor0_EthernetAddress;
var acceptor0_hdr.ethernet.etherType:bv16;

// acceptor0_Header acceptor0_arp_t
var acceptor0_hdr.arp:acceptor0_Ref;
var acceptor0_hdr.arp.valid:bool;
var acceptor0_hdr.arp.hrd:bv16;
var acceptor0_hdr.arp.pro:bv16;
var acceptor0_hdr.arp.hln:bv8;
var acceptor0_hdr.arp.pln:bv8;
var acceptor0_hdr.arp.op:bv16;
var acceptor0_hdr.arp.sha:bv48;
var acceptor0_hdr.arp.spa:bv32;
var acceptor0_hdr.arp.tha:bv48;
var acceptor0_hdr.arp.tpa:bv32;

// acceptor0_Header acceptor0_ipv4_t
var acceptor0_hdr.ipv4:acceptor0_Ref;
var acceptor0_hdr.ipv4.valid:bool;
var acceptor0_hdr.ipv4.version:bv4;
var acceptor0_hdr.ipv4.ihl:bv4;
var acceptor0_hdr.ipv4.diffserv:bv8;
var acceptor0_hdr.ipv4.totalLen:bv16;
var acceptor0_hdr.ipv4.identification:bv16;
var acceptor0_hdr.ipv4.flags:bv3;
var acceptor0_hdr.ipv4.fragOffset:bv13;
var acceptor0_hdr.ipv4.ttl:bv8;
var acceptor0_hdr.ipv4.protocol:bv8;
var acceptor0_hdr.ipv4.hdrChecksum:bv16;
var acceptor0_hdr.ipv4.srcAddr:acceptor0_IPv4Address;
var acceptor0_hdr.ipv4.dstAddr:acceptor0_IPv4Address;

// acceptor0_Header acceptor0_icmp_t
var acceptor0_hdr.icmp:acceptor0_Ref;
var acceptor0_hdr.icmp.valid:bool;
var acceptor0_hdr.icmp.icmpType:bv8;
var acceptor0_hdr.icmp.icmpCode:bv8;
var acceptor0_hdr.icmp.hdrChecksum:bv16;
var acceptor0_hdr.icmp.identifier:bv16;
var acceptor0_hdr.icmp.seqNumber:bv16;
var acceptor0_hdr.icmp.payload:bv256;

// acceptor0_Header acceptor0_udp_t
var acceptor0_hdr.udp:acceptor0_Ref;
var acceptor0_hdr.udp.valid:bool;
var acceptor0_hdr.udp.srcPort:bv16;
var acceptor0_hdr.udp.dstPort:bv16;
var acceptor0_hdr.udp.length_:bv16;
var acceptor0_hdr.udp.checksum:bv16;

// acceptor0_Header acceptor0_paxos_t
var acceptor0_hdr.paxos:acceptor0_Ref;
var acceptor0_hdr.paxos.valid:bool;
var acceptor0_hdr.paxos.msgtype:bv16;
var acceptor0_hdr.paxos.inst:bv32;
var acceptor0_hdr.paxos.rnd:bv16;
var acceptor0_hdr.paxos.vrnd:bv16;
var acceptor0_hdr.paxos.acptid:bv16;
var acceptor0_hdr.paxos.paxoslen:bv32;
var acceptor0_hdr.paxos.paxosval:bv256;

// acceptor0_Struct acceptor0_paxos_metadata_t
type acceptor0_paxos_metadata_t;

// acceptor0_Struct acceptor0_metadata
type acceptor0_metadata;
var acceptor0_meta.paxos_metadata:acceptor0_paxos_metadata_t;
var acceptor0_meta.paxos_metadata.round:bv16;
var acceptor0_meta.paxos_metadata.set_drop:bv1;
var acceptor0_meta.paxos_metadata.ack_count:bv8;
var acceptor0_meta.paxos_metadata.ack_acceptors:bv8;
var acceptor0_meta:acceptor0_metadata;
var acceptor0_standard_metadata:acceptor0_standard_metadata_t;
var acceptor0_ipdst_0:bv32;

// acceptor0_Register acceptor0_ingress_registerAcceptorID
var acceptor0_ingress_registerAcceptorID:[bv32]bv16;
var acceptor0_ingress_registerAcceptorID__last_index:bv32;
var acceptor0_ingress_registerAcceptorID__last_value:bv16;
var acceptor0_ingress_registerAcceptorID__last_old_value:bv16;
var acceptor0_ingress_registerAcceptorID__wrote_any:bool;
var acceptor0_ingress_registerAcceptorID__wrote_index0:bool;
var acceptor0_ingress_registerAcceptorID__last0_old_value:bv16;
var acceptor0_ingress_registerAcceptorID__last0_value:bv16;
var acceptor0_ingress_registerAcceptorID__next_write_site:int;
var acceptor0_ingress_registerAcceptorID__last_write_site:int;
const acceptor0_ingress_registerAcceptorID.size:bv32;
axiom acceptor0_ingress_registerAcceptorID.size == 1bv32;

// acceptor0_Register acceptor0_ingress_registerRound
var acceptor0_ingress_registerRound:[bv32]bv16;
var acceptor0_ingress_registerRound__last_index:bv32;
var acceptor0_ingress_registerRound__last_value:bv16;
var acceptor0_ingress_registerRound__last_old_value:bv16;
var acceptor0_ingress_registerRound__wrote_any:bool;
var acceptor0_ingress_registerRound__wrote_index0:bool;
var acceptor0_ingress_registerRound__last0_old_value:bv16;
var acceptor0_ingress_registerRound__last0_value:bv16;
var acceptor0_ingress_registerRound__next_write_site:int;
var acceptor0_ingress_registerRound__last_write_site:int;
const acceptor0_ingress_registerRound.size:bv32;
axiom acceptor0_ingress_registerRound.size == 65536bv32;

// acceptor0_Register acceptor0_ingress_registerVRound
var acceptor0_ingress_registerVRound:[bv32]bv16;
var acceptor0_ingress_registerVRound__last_index:bv32;
var acceptor0_ingress_registerVRound__last_value:bv16;
var acceptor0_ingress_registerVRound__last_old_value:bv16;
var acceptor0_ingress_registerVRound__wrote_any:bool;
var acceptor0_ingress_registerVRound__wrote_index0:bool;
var acceptor0_ingress_registerVRound__last0_old_value:bv16;
var acceptor0_ingress_registerVRound__last0_value:bv16;
var acceptor0_ingress_registerVRound__next_write_site:int;
var acceptor0_ingress_registerVRound__last_write_site:int;
const acceptor0_ingress_registerVRound.size:bv32;
axiom acceptor0_ingress_registerVRound.size == 65536bv32;

// acceptor0_Register acceptor0_ingress_registerValue
var acceptor0_ingress_registerValue:[bv32]bv256;
var acceptor0_ingress_registerValue__last_index:bv32;
var acceptor0_ingress_registerValue__last_value:bv256;
var acceptor0_ingress_registerValue__last_old_value:bv256;
var acceptor0_ingress_registerValue__wrote_any:bool;
var acceptor0_ingress_registerValue__wrote_index0:bool;
var acceptor0_ingress_registerValue__last0_old_value:bv256;
var acceptor0_ingress_registerValue__last0_value:bv256;
var acceptor0_ingress_registerValue__next_write_site:int;
var acceptor0_ingress_registerValue__last_write_site:int;
const acceptor0_ingress_registerValue.size:bv32;
axiom acceptor0_ingress_registerValue.size == 65536bv32;

// acceptor0_Register acceptor0_ingress_learner_mac_address
var acceptor0_ingress_learner_mac_address:[bv32]bv48;
var acceptor0_ingress_learner_mac_address__last_index:bv32;
var acceptor0_ingress_learner_mac_address__last_value:bv48;
var acceptor0_ingress_learner_mac_address__last_old_value:bv48;
var acceptor0_ingress_learner_mac_address__wrote_any:bool;
var acceptor0_ingress_learner_mac_address__wrote_index0:bool;
var acceptor0_ingress_learner_mac_address__last0_old_value:bv48;
var acceptor0_ingress_learner_mac_address__last0_value:bv48;
var acceptor0_ingress_learner_mac_address__next_write_site:int;
var acceptor0_ingress_learner_mac_address__last_write_site:int;
const acceptor0_ingress_learner_mac_address.size:bv32;
axiom acceptor0_ingress_learner_mac_address.size == 1bv32;

// acceptor0_Register acceptor0_ingress_learner_address
var acceptor0_ingress_learner_address:[bv32]bv32;
var acceptor0_ingress_learner_address__last_index:bv32;
var acceptor0_ingress_learner_address__last_value:bv32;
var acceptor0_ingress_learner_address__last_old_value:bv32;
var acceptor0_ingress_learner_address__wrote_any:bool;
var acceptor0_ingress_learner_address__wrote_index0:bool;
var acceptor0_ingress_learner_address__last0_old_value:bv32;
var acceptor0_ingress_learner_address__last0_value:bv32;
var acceptor0_ingress_learner_address__next_write_site:int;
var acceptor0_ingress_learner_address__last_write_site:int;
const acceptor0_ingress_learner_address.size:bv32;
axiom acceptor0_ingress_learner_address.size == 1bv32;

// acceptor0_Table acceptor0_ingress_acceptor_tbl acceptor0_Actionlist acceptor0_Declaration
type acceptor0_ingress_acceptor_tbl.action;
const unique acceptor0_ingress_acceptor_tbl.action.ingress_handle_1a : acceptor0_ingress_acceptor_tbl.action;
const unique acceptor0_ingress_acceptor_tbl.action.ingress_handle_2a : acceptor0_ingress_acceptor_tbl.action;
const unique acceptor0_ingress_acceptor_tbl.action.ingress_drop : acceptor0_ingress_acceptor_tbl.action;
var acceptor0_ingress_acceptor_tbl.action_run : acceptor0_ingress_acceptor_tbl.action;
var acceptor0_ingress_acceptor_tbl.hit : bool;

// acceptor0_Table acceptor0_ingress_transport_tbl acceptor0_Actionlist acceptor0_Declaration
type acceptor0_ingress_transport_tbl.action;
var acceptor0_ingress_transport_tbl.ingress_forward.port:acceptor0_PortId;
var acceptor0_ingress_transport_tbl.ingress_forward.udp_dst:bv16;
const unique acceptor0_ingress_transport_tbl.action.drop_1 : acceptor0_ingress_transport_tbl.action;
const unique acceptor0_ingress_transport_tbl.action.ingress_forward : acceptor0_ingress_transport_tbl.action;
var acceptor0_ingress_transport_tbl.action_run : acceptor0_ingress_transport_tbl.action;
var acceptor0_ingress_transport_tbl.hit : bool;

// acceptor0_Register acceptor0_ingress_my_mac_address
var acceptor0_ingress_my_mac_address:[bv32]bv48;
var acceptor0_ingress_my_mac_address__last_index:bv32;
var acceptor0_ingress_my_mac_address__last_value:bv48;
var acceptor0_ingress_my_mac_address__last_old_value:bv48;
var acceptor0_ingress_my_mac_address__wrote_any:bool;
var acceptor0_ingress_my_mac_address__wrote_index0:bool;
var acceptor0_ingress_my_mac_address__last0_old_value:bv48;
var acceptor0_ingress_my_mac_address__last0_value:bv48;
var acceptor0_ingress_my_mac_address__next_write_site:int;
var acceptor0_ingress_my_mac_address__last_write_site:int;
const acceptor0_ingress_my_mac_address.size:bv32;
axiom acceptor0_ingress_my_mac_address.size == 1bv32;

// acceptor0_Register acceptor0_ingress_my_ip_address
var acceptor0_ingress_my_ip_address:[bv32]bv32;
var acceptor0_ingress_my_ip_address__last_index:bv32;
var acceptor0_ingress_my_ip_address__last_value:bv32;
var acceptor0_ingress_my_ip_address__last_old_value:bv32;
var acceptor0_ingress_my_ip_address__wrote_any:bool;
var acceptor0_ingress_my_ip_address__wrote_index0:bool;
var acceptor0_ingress_my_ip_address__last0_old_value:bv32;
var acceptor0_ingress_my_ip_address__last0_value:bv32;
var acceptor0_ingress_my_ip_address__next_write_site:int;
var acceptor0_ingress_my_ip_address__last_write_site:int;
const acceptor0_ingress_my_ip_address.size:bv32;
axiom acceptor0_ingress_my_ip_address.size == 1bv32;

// acceptor0_Table acceptor0_ingress_arp_tbl acceptor0_Actionlist acceptor0_Declaration
type acceptor0_ingress_arp_tbl.action;
const unique acceptor0_ingress_arp_tbl.action.ingress_handle_arp_request : acceptor0_ingress_arp_tbl.action;
const unique acceptor0_ingress_arp_tbl.action.ingress_handle_arp_reply : acceptor0_ingress_arp_tbl.action;
const unique acceptor0_ingress_arp_tbl.action.drop_2 : acceptor0_ingress_arp_tbl.action;
var acceptor0_ingress_arp_tbl.action_run : acceptor0_ingress_arp_tbl.action;
var acceptor0_ingress_arp_tbl.hit : bool;

function {:builtin "bvadd"} add.bv16(acceptor0_left:bv16, acceptor0_right:bv16) returns(bv16);

// acceptor0_Table acceptor0_ingress_icmp_tbl acceptor0_Actionlist acceptor0_Declaration
type acceptor0_ingress_icmp_tbl.action;
const unique acceptor0_ingress_icmp_tbl.action.ingress_handle_icmp_request : acceptor0_ingress_icmp_tbl.action;
const unique acceptor0_ingress_icmp_tbl.action.ingress_handle_icmp_reply : acceptor0_ingress_icmp_tbl.action;
const unique acceptor0_ingress_icmp_tbl.action.drop_3 : acceptor0_ingress_icmp_tbl.action;
var acceptor0_ingress_icmp_tbl.action_run : acceptor0_ingress_icmp_tbl.action;
var acceptor0_ingress_icmp_tbl.hit : bool;

function {:builtin "bvuge"} buge.bv16(acceptor0_left:bv16, acceptor0_right:bv16) returns(bool);

function {:builtin "bvule"} bule.bv16(acceptor0_left:bv16, acceptor0_right:bv16) returns(bool);

// acceptor0_Table acceptor0_egress_place_holder_table acceptor0_Actionlist acceptor0_Declaration
type acceptor0_egress_place_holder_table.action;
const unique acceptor0_egress_place_holder_table.action.NoAction : acceptor0_egress_place_holder_table.action;
var acceptor0_egress_place_holder_table.action_run : acceptor0_egress_place_holder_table.action;
var acceptor0_egress_place_holder_table.hit : bool;

function {:builtin "bvsub"} sub.bv17(acceptor0_left:bv17, acceptor0_right:bv17) returns(bv17);

function {:builtin "bvsub"} sub.bv33(acceptor0_left:bv33, acceptor0_right:bv33) returns(bv33);

// acceptor0_Action acceptor0_NoAction
procedure {:inline 1} acceptor0_NoAction()
{
}

// acceptor0_Parser acceptor0_TopParser
procedure {:inline 1} acceptor0_TopParser()
	modifies acceptor0_drop, acceptor0_isValid;
{
    goto acceptor0_State$TopParser$start;

        acceptor0_State$TopParser$start:
    call acceptor0_packet_in.extract(acceptor0_hdr.ethernet);
    goto acceptor0_State$TopParser$start$parse_arp_2, acceptor0_State$TopParser$start$parse_ipv4_1, acceptor0_State$TopParser$start$DEFAULT;
    
acceptor0_State$TopParser$start$parse_arp_2:
    assume (acceptor0_hdr.ethernet.etherType == 2054bv16);
    goto acceptor0_State$TopParser$parse_arp;
    
acceptor0_State$TopParser$start$parse_ipv4_1:
    assume (acceptor0_hdr.ethernet.etherType == 2048bv16);
    goto acceptor0_State$TopParser$parse_ipv4;

    acceptor0_State$TopParser$start$DEFAULT:
    assume(!(acceptor0_hdr.ethernet.etherType == 2054bv16)&&!(acceptor0_hdr.ethernet.etherType == 2048bv16));
goto acceptor0_State$reject;

        acceptor0_State$TopParser$parse_arp:
    call acceptor0_packet_in.extract(acceptor0_hdr.arp);
    goto acceptor0_State$accept;

        acceptor0_State$TopParser$parse_ipv4:
    call acceptor0_packet_in.extract(acceptor0_hdr.ipv4);
    goto acceptor0_State$TopParser$parse_ipv4$parse_icmp_3, acceptor0_State$TopParser$parse_ipv4$parse_udp_2, acceptor0_State$TopParser$parse_ipv4$DEFAULT;
    
acceptor0_State$TopParser$parse_ipv4$parse_icmp_3:
    assume (acceptor0_hdr.ipv4.protocol == 1bv8);
    goto acceptor0_State$TopParser$parse_icmp;
    
acceptor0_State$TopParser$parse_ipv4$parse_udp_2:
    assume (acceptor0_hdr.ipv4.protocol == 17bv8);
    goto acceptor0_State$TopParser$parse_udp;

    acceptor0_State$TopParser$parse_ipv4$DEFAULT:
    assume(!(acceptor0_hdr.ipv4.protocol == 1bv8)&&!(acceptor0_hdr.ipv4.protocol == 17bv8));
    goto acceptor0_State$accept;

        acceptor0_State$TopParser$parse_icmp:
    call acceptor0_packet_in.extract(acceptor0_hdr.icmp);
    goto acceptor0_State$accept;

        acceptor0_State$TopParser$parse_udp:
    call acceptor0_packet_in.extract(acceptor0_hdr.udp);
    goto acceptor0_State$TopParser$parse_udp$parse_paxos_2, acceptor0_State$TopParser$parse_udp$DEFAULT;
    
acceptor0_State$TopParser$parse_udp$parse_paxos_2:
    assume (acceptor0_hdr.udp.dstPort == 34952bv16);
    goto acceptor0_State$TopParser$parse_paxos;

    acceptor0_State$TopParser$parse_udp$DEFAULT:
    assume(!(acceptor0_hdr.udp.dstPort == 34952bv16));
    goto acceptor0_State$accept;

        acceptor0_State$TopParser$parse_paxos:
    call acceptor0_packet_in.extract(acceptor0_hdr.paxos);
    goto acceptor0_State$accept;

    acceptor0_State$accept:
    call acceptor0_accept();
    goto acceptor0_Exit;

    acceptor0_State$reject:
    call acceptor0_reject();
    goto acceptor0_Exit;

    acceptor0_Exit:
}
procedure {:inline 1} acceptor0_accept()
{
}

// acceptor0_Control acceptor0_computeChecksum
procedure {:inline 1} acceptor0_computeChecksum()
	modifies acceptor0_hdr.ipv4.hdrChecksum, acceptor0_p4b_checksum_updated;
{
    if (acceptor0_isValid[acceptor0_hdr.ipv4]) {
        acceptor0_p4b_checksum_updated := true;
        havoc acceptor0_hdr.ipv4.hdrChecksum;
    }
}

// acceptor0_Action acceptor0_drop_1
procedure {:inline 1} acceptor0_drop_1()
	modifies acceptor0_drop;
{
    call acceptor0_mark_to_drop();
}

// acceptor0_Action acceptor0_drop_2
procedure {:inline 1} acceptor0_drop_2()
	modifies acceptor0_drop;
{
    call acceptor0_mark_to_drop();
}

// acceptor0_Action acceptor0_drop_3
procedure {:inline 1} acceptor0_drop_3()
	modifies acceptor0_drop;
{
    call acceptor0_mark_to_drop();
}

// acceptor0_Control acceptor0_egress
procedure {:inline 1} acceptor0_egress()
	modifies acceptor0_egress_place_holder_table.hit;
{
    call acceptor0_egress_place_holder_table.apply();
}

// acceptor0_Table acceptor0_egress_place_holder_table
procedure {:inline 1} acceptor0_egress_place_holder_table.apply()
	modifies acceptor0_egress_place_holder_table.hit;
{
    acceptor0_egress_place_holder_table.hit := false;
    goto acceptor0_Exit;

    acceptor0_Exit:
}

// acceptor0_Control acceptor0_ingress
procedure {:inline 1} acceptor0_ingress()
	modifies acceptor0_drop, acceptor0_forward, acceptor0_hdr.arp.op, acceptor0_hdr.arp.sha, acceptor0_hdr.arp.spa, acceptor0_hdr.arp.tha, acceptor0_hdr.arp.tpa, acceptor0_hdr.ethernet.dstAddr, acceptor0_hdr.ethernet.srcAddr, acceptor0_hdr.icmp.hdrChecksum, acceptor0_hdr.icmp.icmpType, acceptor0_hdr.ipv4.dstAddr, acceptor0_hdr.ipv4.srcAddr, acceptor0_hdr.paxos.acptid, acceptor0_hdr.paxos.msgtype, acceptor0_hdr.paxos.paxosval, acceptor0_hdr.paxos.vrnd, acceptor0_hdr.udp.dstPort, acceptor0_ingress_acceptor_tbl.action_run, acceptor0_ingress_acceptor_tbl.hit, acceptor0_ingress_arp_tbl.action_run, acceptor0_ingress_arp_tbl.hit, acceptor0_ingress_icmp_tbl.action_run, acceptor0_ingress_icmp_tbl.hit, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_index0, acceptor0_ingress_registerVRound, acceptor0_ingress_registerVRound__last0_old_value, acceptor0_ingress_registerVRound__last0_value, acceptor0_ingress_registerVRound__last_index, acceptor0_ingress_registerVRound__last_old_value, acceptor0_ingress_registerVRound__last_value, acceptor0_ingress_registerVRound__last_write_site, acceptor0_ingress_registerVRound__next_write_site, acceptor0_ingress_registerVRound__wrote_any, acceptor0_ingress_registerVRound__wrote_index0, acceptor0_ingress_registerValue, acceptor0_ingress_registerValue__last0_old_value, acceptor0_ingress_registerValue__last0_value, acceptor0_ingress_registerValue__last_index, acceptor0_ingress_registerValue__last_old_value, acceptor0_ingress_registerValue__last_value, acceptor0_ingress_registerValue__last_write_site, acceptor0_ingress_registerValue__next_write_site, acceptor0_ingress_registerValue__wrote_any, acceptor0_ingress_registerValue__wrote_index0, acceptor0_ingress_transport_tbl.action_run, acceptor0_ingress_transport_tbl.hit, acceptor0_ipdst_0, acceptor0_meta.paxos_metadata.round, acceptor0_standard_metadata.egress_port, acceptor0_standard_metadata.egress_spec;
{
havoc acceptor0_ipdst_0;
    if(acceptor0_isValid[acceptor0_hdr.arp]){
        call acceptor0_ingress_arp_tbl.apply();
    }
    else{
        if(acceptor0_isValid[acceptor0_hdr.ipv4]){
            if(acceptor0_isValid[acceptor0_hdr.paxos]){
                call acceptor0_ingress_read_round();
                if(buge.bv16(acceptor0_hdr.paxos.rnd, acceptor0_meta.paxos_metadata.round)){
                    // acceptor0_read
                    acceptor0_hdr.paxos.vrnd := acceptor0_ingress_registerVRound.read(acceptor0_ingress_registerVRound, acceptor0_hdr.paxos.inst);
                    assert bule.bv16(acceptor0_hdr.paxos.vrnd, acceptor0_meta.paxos_metadata.round);
                    call acceptor0_ingress_acceptor_tbl.apply();
                    call acceptor0_ingress_transport_tbl.apply();
                }
            }
            else{
                if(acceptor0_isValid[acceptor0_hdr.icmp]){
                    call acceptor0_ingress_icmp_tbl.apply();
                }
            }
        }
    }
}

// acceptor0_Table acceptor0_ingress_acceptor_tbl
procedure {:inline 1} acceptor0_ingress_acceptor_tbl.apply()
	modifies acceptor0_drop, acceptor0_hdr.paxos.acptid, acceptor0_hdr.paxos.msgtype, acceptor0_hdr.paxos.paxosval, acceptor0_hdr.paxos.vrnd, acceptor0_ingress_acceptor_tbl.action_run, acceptor0_ingress_acceptor_tbl.hit, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_index0, acceptor0_ingress_registerVRound, acceptor0_ingress_registerVRound__last0_old_value, acceptor0_ingress_registerVRound__last0_value, acceptor0_ingress_registerVRound__last_index, acceptor0_ingress_registerVRound__last_old_value, acceptor0_ingress_registerVRound__last_value, acceptor0_ingress_registerVRound__last_write_site, acceptor0_ingress_registerVRound__next_write_site, acceptor0_ingress_registerVRound__wrote_any, acceptor0_ingress_registerVRound__wrote_index0, acceptor0_ingress_registerValue, acceptor0_ingress_registerValue__last0_old_value, acceptor0_ingress_registerValue__last0_value, acceptor0_ingress_registerValue__last_index, acceptor0_ingress_registerValue__last_old_value, acceptor0_ingress_registerValue__last_value, acceptor0_ingress_registerValue__last_write_site, acceptor0_ingress_registerValue__next_write_site, acceptor0_ingress_registerValue__wrote_any, acceptor0_ingress_registerValue__wrote_index0;
{
    acceptor0_hdr.paxos.msgtype := acceptor0_hdr.paxos.msgtype;
    acceptor0_ingress_acceptor_tbl.hit := false;
    goto acceptor0_action_ingress_handle_1a, acceptor0_action_ingress_handle_2a, acceptor0_action_ingress_drop;

    acceptor0_action_ingress_handle_1a:
    assume acceptor0_ingress_acceptor_tbl.action_run == acceptor0_ingress_acceptor_tbl.action.ingress_handle_1a;
    call acceptor0_ingress_handle_1a();
    goto acceptor0_Exit;

    acceptor0_action_ingress_handle_2a:
    assume acceptor0_ingress_acceptor_tbl.action_run == acceptor0_ingress_acceptor_tbl.action.ingress_handle_2a;
    call acceptor0_ingress_handle_2a();
    goto acceptor0_Exit;

    acceptor0_action_ingress_drop:
    assume acceptor0_ingress_acceptor_tbl.action_run == acceptor0_ingress_acceptor_tbl.action.ingress_drop;
    call acceptor0_ingress_drop();
    goto acceptor0_Exit;

    acceptor0_Exit:
}

// acceptor0_Table acceptor0_ingress_arp_tbl
procedure {:inline 1} acceptor0_ingress_arp_tbl.apply()
	modifies acceptor0_drop, acceptor0_forward, acceptor0_hdr.arp.op, acceptor0_hdr.arp.sha, acceptor0_hdr.arp.spa, acceptor0_hdr.arp.tha, acceptor0_hdr.arp.tpa, acceptor0_hdr.ethernet.dstAddr, acceptor0_hdr.ethernet.srcAddr, acceptor0_ingress_arp_tbl.action_run, acceptor0_ingress_arp_tbl.hit, acceptor0_standard_metadata.egress_port, acceptor0_standard_metadata.egress_spec;
{
    acceptor0_hdr.arp.op := acceptor0_hdr.arp.op;
    acceptor0_ingress_arp_tbl.hit := false;
    goto acceptor0_action_ingress_handle_arp_request, acceptor0_action_ingress_handle_arp_reply, acceptor0_action_drop_2;

    acceptor0_action_ingress_handle_arp_request:
    assume acceptor0_ingress_arp_tbl.action_run == acceptor0_ingress_arp_tbl.action.ingress_handle_arp_request;
    call acceptor0_ingress_handle_arp_request();
    goto acceptor0_Exit;

    acceptor0_action_ingress_handle_arp_reply:
    assume acceptor0_ingress_arp_tbl.action_run == acceptor0_ingress_arp_tbl.action.ingress_handle_arp_reply;
    call acceptor0_ingress_handle_arp_reply();
    goto acceptor0_Exit;

    acceptor0_action_drop_2:
    assume acceptor0_ingress_arp_tbl.action_run == acceptor0_ingress_arp_tbl.action.drop_2;
    call acceptor0_drop_2();
    goto acceptor0_Exit;

    acceptor0_Exit:
}

// acceptor0_Action acceptor0_ingress_drop
procedure {:inline 1} acceptor0_ingress_drop()
	modifies acceptor0_drop;
{
    call acceptor0_mark_to_drop();
}

// acceptor0_Action acceptor0_ingress_forward
procedure {:inline 1} acceptor0_ingress_forward(acceptor0_port:acceptor0_PortId, acceptor0_udp_dst:bv16)
	modifies acceptor0_forward, acceptor0_hdr.udp.dstPort, acceptor0_standard_metadata.egress_port, acceptor0_standard_metadata.egress_spec;
{
    acceptor0_standard_metadata.egress_spec := 0bv5++acceptor0_port;
    acceptor0_standard_metadata.egress_port := 0bv5++acceptor0_port;
    acceptor0_forward := true;
    acceptor0_hdr.udp.dstPort := acceptor0_udp_dst;
}

// acceptor0_Action acceptor0_ingress_handle_1a
procedure {:inline 1} acceptor0_ingress_handle_1a()
	modifies acceptor0_hdr.paxos.acptid, acceptor0_hdr.paxos.msgtype, acceptor0_hdr.paxos.paxosval, acceptor0_hdr.paxos.vrnd, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_index0;
{
    acceptor0_hdr.paxos.msgtype := 1bv16;
    // acceptor0_read
    acceptor0_hdr.paxos.vrnd := acceptor0_ingress_registerVRound.read(acceptor0_ingress_registerVRound, acceptor0_hdr.paxos.inst);
    // acceptor0_read
    acceptor0_hdr.paxos.paxosval := acceptor0_ingress_registerValue.read(acceptor0_ingress_registerValue, acceptor0_hdr.paxos.inst);
    // acceptor0_read
    acceptor0_hdr.paxos.acptid := acceptor0_ingress_registerAcceptorID.read(acceptor0_ingress_registerAcceptorID, 0bv32);
    // acceptor0_write
    acceptor0_ingress_registerRound__next_write_site := 1;
    call acceptor0_ingress_registerRound.write(acceptor0_hdr.paxos.inst, acceptor0_hdr.paxos.rnd);
}

// acceptor0_Action acceptor0_ingress_handle_2a
procedure {:inline 1} acceptor0_ingress_handle_2a()
	modifies acceptor0_hdr.paxos.acptid, acceptor0_hdr.paxos.msgtype, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_index0, acceptor0_ingress_registerVRound, acceptor0_ingress_registerVRound__last0_old_value, acceptor0_ingress_registerVRound__last0_value, acceptor0_ingress_registerVRound__last_index, acceptor0_ingress_registerVRound__last_old_value, acceptor0_ingress_registerVRound__last_value, acceptor0_ingress_registerVRound__last_write_site, acceptor0_ingress_registerVRound__next_write_site, acceptor0_ingress_registerVRound__wrote_any, acceptor0_ingress_registerVRound__wrote_index0, acceptor0_ingress_registerValue, acceptor0_ingress_registerValue__last0_old_value, acceptor0_ingress_registerValue__last0_value, acceptor0_ingress_registerValue__last_index, acceptor0_ingress_registerValue__last_old_value, acceptor0_ingress_registerValue__last_value, acceptor0_ingress_registerValue__last_write_site, acceptor0_ingress_registerValue__next_write_site, acceptor0_ingress_registerValue__wrote_any, acceptor0_ingress_registerValue__wrote_index0;
{
    acceptor0_hdr.paxos.msgtype := 3bv16;
    // acceptor0_read
    acceptor0_hdr.paxos.acptid := acceptor0_ingress_registerAcceptorID.read(acceptor0_ingress_registerAcceptorID, 0bv32);
    // acceptor0_write
    acceptor0_ingress_registerRound__next_write_site := 2;
    call acceptor0_ingress_registerRound.write(acceptor0_hdr.paxos.inst, acceptor0_hdr.paxos.rnd);
    // acceptor0_write
    acceptor0_ingress_registerVRound__next_write_site := 1;
    call acceptor0_ingress_registerVRound.write(acceptor0_hdr.paxos.inst, acceptor0_hdr.paxos.rnd);
    // acceptor0_write
    acceptor0_ingress_registerValue__next_write_site := 1;
    call acceptor0_ingress_registerValue.write(acceptor0_hdr.paxos.inst, acceptor0_hdr.paxos.paxosval);
}

// acceptor0_Action acceptor0_ingress_handle_arp_reply
procedure {:inline 1} acceptor0_ingress_handle_arp_reply()
{
}

// acceptor0_Action acceptor0_ingress_handle_arp_request
procedure {:inline 1} acceptor0_ingress_handle_arp_request()
	modifies acceptor0_forward, acceptor0_hdr.arp.op, acceptor0_hdr.arp.sha, acceptor0_hdr.arp.spa, acceptor0_hdr.arp.tha, acceptor0_hdr.arp.tpa, acceptor0_hdr.ethernet.dstAddr, acceptor0_hdr.ethernet.srcAddr, acceptor0_standard_metadata.egress_port, acceptor0_standard_metadata.egress_spec;
{
    acceptor0_hdr.ethernet.dstAddr := acceptor0_hdr.ethernet.srcAddr;
    // acceptor0_read
    acceptor0_hdr.ethernet.srcAddr := acceptor0_ingress_my_mac_address.read(acceptor0_ingress_my_mac_address, 0bv32);
    acceptor0_hdr.arp.op := 2bv16;
    acceptor0_hdr.arp.tha := acceptor0_hdr.arp.sha;
    acceptor0_hdr.arp.tpa := acceptor0_hdr.arp.spa;
    // acceptor0_read
    acceptor0_hdr.arp.sha := acceptor0_ingress_my_mac_address.read(acceptor0_ingress_my_mac_address, 0bv32);
    // acceptor0_read
    acceptor0_hdr.arp.spa := acceptor0_ingress_my_ip_address.read(acceptor0_ingress_my_ip_address, 0bv32);
    acceptor0_standard_metadata.egress_spec := acceptor0_standard_metadata.ingress_port;
    acceptor0_standard_metadata.egress_port := acceptor0_standard_metadata.ingress_port;
    acceptor0_forward := true;
}

// acceptor0_Action acceptor0_ingress_handle_icmp_reply
procedure {:inline 1} acceptor0_ingress_handle_icmp_reply()
{
}

// acceptor0_Action acceptor0_ingress_handle_icmp_request
procedure {:inline 1} acceptor0_ingress_handle_icmp_request()
	modifies acceptor0_hdr.ethernet.dstAddr, acceptor0_hdr.ethernet.srcAddr, acceptor0_hdr.icmp.hdrChecksum, acceptor0_hdr.icmp.icmpType, acceptor0_hdr.ipv4.dstAddr, acceptor0_hdr.ipv4.srcAddr, acceptor0_ipdst_0;
{
    acceptor0_hdr.ethernet.dstAddr := acceptor0_hdr.ethernet.srcAddr;
    // acceptor0_read
    acceptor0_hdr.ethernet.srcAddr := acceptor0_ingress_my_mac_address.read(acceptor0_ingress_my_mac_address, 0bv32);
    acceptor0_ipdst_0 := acceptor0_hdr.ipv4.dstAddr;
    acceptor0_hdr.ipv4.dstAddr := acceptor0_hdr.ipv4.srcAddr;
    acceptor0_hdr.ipv4.srcAddr := acceptor0_ipdst_0;
    acceptor0_hdr.icmp.icmpType := 0bv8;
    acceptor0_hdr.icmp.hdrChecksum := add.bv16(acceptor0_hdr.icmp.hdrChecksum, 2048bv16);
}

// acceptor0_Table acceptor0_ingress_icmp_tbl
procedure {:inline 1} acceptor0_ingress_icmp_tbl.apply()
	modifies acceptor0_drop, acceptor0_hdr.ethernet.dstAddr, acceptor0_hdr.ethernet.srcAddr, acceptor0_hdr.icmp.hdrChecksum, acceptor0_hdr.icmp.icmpType, acceptor0_hdr.ipv4.dstAddr, acceptor0_hdr.ipv4.srcAddr, acceptor0_ingress_icmp_tbl.action_run, acceptor0_ingress_icmp_tbl.hit, acceptor0_ipdst_0;
{
    acceptor0_hdr.icmp.icmpType := acceptor0_hdr.icmp.icmpType;
    acceptor0_ingress_icmp_tbl.hit := false;
    goto acceptor0_action_ingress_handle_icmp_request, acceptor0_action_ingress_handle_icmp_reply, acceptor0_action_drop_3;

    acceptor0_action_ingress_handle_icmp_request:
    assume acceptor0_ingress_icmp_tbl.action_run == acceptor0_ingress_icmp_tbl.action.ingress_handle_icmp_request;
    call acceptor0_ingress_handle_icmp_request();
    goto acceptor0_Exit;

    acceptor0_action_ingress_handle_icmp_reply:
    assume acceptor0_ingress_icmp_tbl.action_run == acceptor0_ingress_icmp_tbl.action.ingress_handle_icmp_reply;
    call acceptor0_ingress_handle_icmp_reply();
    goto acceptor0_Exit;

    acceptor0_action_drop_3:
    assume acceptor0_ingress_icmp_tbl.action_run == acceptor0_ingress_icmp_tbl.action.drop_3;
    call acceptor0_drop_3();
    goto acceptor0_Exit;

    acceptor0_Exit:
}
function {:inline true}acceptor0_ingress_learner_address.read(acceptor0_reg:[bv32]bv32, acceptor0_index:bv32)returns (bv32) {acceptor0_reg[acceptor0_index]}
procedure {:inline 1} acceptor0_ingress_learner_address.write(acceptor0_index:bv32, acceptor0_value:bv32)
	modifies acceptor0_ingress_learner_address, acceptor0_ingress_learner_address__last0_old_value, acceptor0_ingress_learner_address__last0_value, acceptor0_ingress_learner_address__last_index, acceptor0_ingress_learner_address__last_old_value, acceptor0_ingress_learner_address__last_value, acceptor0_ingress_learner_address__last_write_site, acceptor0_ingress_learner_address__wrote_any, acceptor0_ingress_learner_address__wrote_index0;
{
    acceptor0_ingress_learner_address__last_old_value := acceptor0_ingress_learner_address[acceptor0_index];
    acceptor0_ingress_learner_address[acceptor0_index] := acceptor0_value;
    acceptor0_ingress_learner_address__last_index := acceptor0_index;
    acceptor0_ingress_learner_address__last_value := acceptor0_value;
    acceptor0_ingress_learner_address__last_write_site := acceptor0_ingress_learner_address__next_write_site;
    acceptor0_ingress_learner_address__wrote_any := true;
    if (acceptor0_index == 0bv32) {
        acceptor0_ingress_learner_address__wrote_index0 := true;
        acceptor0_ingress_learner_address__last0_old_value := acceptor0_ingress_learner_address__last_old_value;
        acceptor0_ingress_learner_address__last0_value := acceptor0_value;
    }
}
function {:inline true}acceptor0_ingress_learner_mac_address.read(acceptor0_reg:[bv32]bv48, acceptor0_index:bv32)returns (bv48) {acceptor0_reg[acceptor0_index]}
procedure {:inline 1} acceptor0_ingress_learner_mac_address.write(acceptor0_index:bv32, acceptor0_value:bv48)
	modifies acceptor0_ingress_learner_mac_address, acceptor0_ingress_learner_mac_address__last0_old_value, acceptor0_ingress_learner_mac_address__last0_value, acceptor0_ingress_learner_mac_address__last_index, acceptor0_ingress_learner_mac_address__last_old_value, acceptor0_ingress_learner_mac_address__last_value, acceptor0_ingress_learner_mac_address__last_write_site, acceptor0_ingress_learner_mac_address__wrote_any, acceptor0_ingress_learner_mac_address__wrote_index0;
{
    acceptor0_ingress_learner_mac_address__last_old_value := acceptor0_ingress_learner_mac_address[acceptor0_index];
    acceptor0_ingress_learner_mac_address[acceptor0_index] := acceptor0_value;
    acceptor0_ingress_learner_mac_address__last_index := acceptor0_index;
    acceptor0_ingress_learner_mac_address__last_value := acceptor0_value;
    acceptor0_ingress_learner_mac_address__last_write_site := acceptor0_ingress_learner_mac_address__next_write_site;
    acceptor0_ingress_learner_mac_address__wrote_any := true;
    if (acceptor0_index == 0bv32) {
        acceptor0_ingress_learner_mac_address__wrote_index0 := true;
        acceptor0_ingress_learner_mac_address__last0_old_value := acceptor0_ingress_learner_mac_address__last_old_value;
        acceptor0_ingress_learner_mac_address__last0_value := acceptor0_value;
    }
}
function {:inline true}acceptor0_ingress_my_ip_address.read(acceptor0_reg:[bv32]bv32, acceptor0_index:bv32)returns (bv32) {acceptor0_reg[acceptor0_index]}
procedure {:inline 1} acceptor0_ingress_my_ip_address.write(acceptor0_index:bv32, acceptor0_value:bv32)
	modifies acceptor0_ingress_my_ip_address, acceptor0_ingress_my_ip_address__last0_old_value, acceptor0_ingress_my_ip_address__last0_value, acceptor0_ingress_my_ip_address__last_index, acceptor0_ingress_my_ip_address__last_old_value, acceptor0_ingress_my_ip_address__last_value, acceptor0_ingress_my_ip_address__last_write_site, acceptor0_ingress_my_ip_address__wrote_any, acceptor0_ingress_my_ip_address__wrote_index0;
{
    acceptor0_ingress_my_ip_address__last_old_value := acceptor0_ingress_my_ip_address[acceptor0_index];
    acceptor0_ingress_my_ip_address[acceptor0_index] := acceptor0_value;
    acceptor0_ingress_my_ip_address__last_index := acceptor0_index;
    acceptor0_ingress_my_ip_address__last_value := acceptor0_value;
    acceptor0_ingress_my_ip_address__last_write_site := acceptor0_ingress_my_ip_address__next_write_site;
    acceptor0_ingress_my_ip_address__wrote_any := true;
    if (acceptor0_index == 0bv32) {
        acceptor0_ingress_my_ip_address__wrote_index0 := true;
        acceptor0_ingress_my_ip_address__last0_old_value := acceptor0_ingress_my_ip_address__last_old_value;
        acceptor0_ingress_my_ip_address__last0_value := acceptor0_value;
    }
}
function {:inline true}acceptor0_ingress_my_mac_address.read(acceptor0_reg:[bv32]bv48, acceptor0_index:bv32)returns (bv48) {acceptor0_reg[acceptor0_index]}
procedure {:inline 1} acceptor0_ingress_my_mac_address.write(acceptor0_index:bv32, acceptor0_value:bv48)
	modifies acceptor0_ingress_my_mac_address, acceptor0_ingress_my_mac_address__last0_old_value, acceptor0_ingress_my_mac_address__last0_value, acceptor0_ingress_my_mac_address__last_index, acceptor0_ingress_my_mac_address__last_old_value, acceptor0_ingress_my_mac_address__last_value, acceptor0_ingress_my_mac_address__last_write_site, acceptor0_ingress_my_mac_address__wrote_any, acceptor0_ingress_my_mac_address__wrote_index0;
{
    acceptor0_ingress_my_mac_address__last_old_value := acceptor0_ingress_my_mac_address[acceptor0_index];
    acceptor0_ingress_my_mac_address[acceptor0_index] := acceptor0_value;
    acceptor0_ingress_my_mac_address__last_index := acceptor0_index;
    acceptor0_ingress_my_mac_address__last_value := acceptor0_value;
    acceptor0_ingress_my_mac_address__last_write_site := acceptor0_ingress_my_mac_address__next_write_site;
    acceptor0_ingress_my_mac_address__wrote_any := true;
    if (acceptor0_index == 0bv32) {
        acceptor0_ingress_my_mac_address__wrote_index0 := true;
        acceptor0_ingress_my_mac_address__last0_old_value := acceptor0_ingress_my_mac_address__last_old_value;
        acceptor0_ingress_my_mac_address__last0_value := acceptor0_value;
    }
}

// acceptor0_Action acceptor0_ingress_read_round
procedure {:inline 1} acceptor0_ingress_read_round()
	modifies acceptor0_meta.paxos_metadata.round;
{
    // acceptor0_read
    acceptor0_meta.paxos_metadata.round := acceptor0_ingress_registerRound.read(acceptor0_ingress_registerRound, acceptor0_hdr.paxos.inst);
}
function {:inline true}acceptor0_ingress_registerAcceptorID.read(acceptor0_reg:[bv32]bv16, acceptor0_index:bv32)returns (bv16) {acceptor0_reg[acceptor0_index]}
procedure {:inline 1} acceptor0_ingress_registerAcceptorID.write(acceptor0_index:bv32, acceptor0_value:bv16)
	modifies acceptor0_ingress_registerAcceptorID, acceptor0_ingress_registerAcceptorID__last0_old_value, acceptor0_ingress_registerAcceptorID__last0_value, acceptor0_ingress_registerAcceptorID__last_index, acceptor0_ingress_registerAcceptorID__last_old_value, acceptor0_ingress_registerAcceptorID__last_value, acceptor0_ingress_registerAcceptorID__last_write_site, acceptor0_ingress_registerAcceptorID__wrote_any, acceptor0_ingress_registerAcceptorID__wrote_index0;
{
    acceptor0_ingress_registerAcceptorID__last_old_value := acceptor0_ingress_registerAcceptorID[acceptor0_index];
    acceptor0_ingress_registerAcceptorID[acceptor0_index] := acceptor0_value;
    acceptor0_ingress_registerAcceptorID__last_index := acceptor0_index;
    acceptor0_ingress_registerAcceptorID__last_value := acceptor0_value;
    acceptor0_ingress_registerAcceptorID__last_write_site := acceptor0_ingress_registerAcceptorID__next_write_site;
    acceptor0_ingress_registerAcceptorID__wrote_any := true;
    if (acceptor0_index == 0bv32) {
        acceptor0_ingress_registerAcceptorID__wrote_index0 := true;
        acceptor0_ingress_registerAcceptorID__last0_old_value := acceptor0_ingress_registerAcceptorID__last_old_value;
        acceptor0_ingress_registerAcceptorID__last0_value := acceptor0_value;
    }
}
function {:inline true}acceptor0_ingress_registerRound.read(acceptor0_reg:[bv32]bv16, acceptor0_index:bv32)returns (bv16) {acceptor0_reg[acceptor0_index]}
procedure {:inline 1} acceptor0_ingress_registerRound.write(acceptor0_index:bv32, acceptor0_value:bv16)
	modifies acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_index0;
{
    acceptor0_ingress_registerRound__last_old_value := acceptor0_ingress_registerRound[acceptor0_index];
    acceptor0_ingress_registerRound[acceptor0_index] := acceptor0_value;
    acceptor0_ingress_registerRound__last_index := acceptor0_index;
    acceptor0_ingress_registerRound__last_value := acceptor0_value;
    acceptor0_ingress_registerRound__last_write_site := acceptor0_ingress_registerRound__next_write_site;
    acceptor0_ingress_registerRound__wrote_any := true;
    if (acceptor0_index == 0bv32) {
        acceptor0_ingress_registerRound__wrote_index0 := true;
        acceptor0_ingress_registerRound__last0_old_value := acceptor0_ingress_registerRound__last_old_value;
        acceptor0_ingress_registerRound__last0_value := acceptor0_value;
    }
}
function {:inline true}acceptor0_ingress_registerVRound.read(acceptor0_reg:[bv32]bv16, acceptor0_index:bv32)returns (bv16) {acceptor0_reg[acceptor0_index]}
procedure {:inline 1} acceptor0_ingress_registerVRound.write(acceptor0_index:bv32, acceptor0_value:bv16)
	modifies acceptor0_ingress_registerVRound, acceptor0_ingress_registerVRound__last0_old_value, acceptor0_ingress_registerVRound__last0_value, acceptor0_ingress_registerVRound__last_index, acceptor0_ingress_registerVRound__last_old_value, acceptor0_ingress_registerVRound__last_value, acceptor0_ingress_registerVRound__last_write_site, acceptor0_ingress_registerVRound__wrote_any, acceptor0_ingress_registerVRound__wrote_index0;
{
    acceptor0_ingress_registerVRound__last_old_value := acceptor0_ingress_registerVRound[acceptor0_index];
    acceptor0_ingress_registerVRound[acceptor0_index] := acceptor0_value;
    acceptor0_ingress_registerVRound__last_index := acceptor0_index;
    acceptor0_ingress_registerVRound__last_value := acceptor0_value;
    acceptor0_ingress_registerVRound__last_write_site := acceptor0_ingress_registerVRound__next_write_site;
    acceptor0_ingress_registerVRound__wrote_any := true;
    if (acceptor0_index == 0bv32) {
        acceptor0_ingress_registerVRound__wrote_index0 := true;
        acceptor0_ingress_registerVRound__last0_old_value := acceptor0_ingress_registerVRound__last_old_value;
        acceptor0_ingress_registerVRound__last0_value := acceptor0_value;
    }
}
function {:inline true}acceptor0_ingress_registerValue.read(acceptor0_reg:[bv32]bv256, acceptor0_index:bv32)returns (bv256) {acceptor0_reg[acceptor0_index]}
procedure {:inline 1} acceptor0_ingress_registerValue.write(acceptor0_index:bv32, acceptor0_value:bv256)
	modifies acceptor0_ingress_registerValue, acceptor0_ingress_registerValue__last0_old_value, acceptor0_ingress_registerValue__last0_value, acceptor0_ingress_registerValue__last_index, acceptor0_ingress_registerValue__last_old_value, acceptor0_ingress_registerValue__last_value, acceptor0_ingress_registerValue__last_write_site, acceptor0_ingress_registerValue__wrote_any, acceptor0_ingress_registerValue__wrote_index0;
{
    acceptor0_ingress_registerValue__last_old_value := acceptor0_ingress_registerValue[acceptor0_index];
    acceptor0_ingress_registerValue[acceptor0_index] := acceptor0_value;
    acceptor0_ingress_registerValue__last_index := acceptor0_index;
    acceptor0_ingress_registerValue__last_value := acceptor0_value;
    acceptor0_ingress_registerValue__last_write_site := acceptor0_ingress_registerValue__next_write_site;
    acceptor0_ingress_registerValue__wrote_any := true;
    if (acceptor0_index == 0bv32) {
        acceptor0_ingress_registerValue__wrote_index0 := true;
        acceptor0_ingress_registerValue__last0_old_value := acceptor0_ingress_registerValue__last_old_value;
        acceptor0_ingress_registerValue__last0_value := acceptor0_value;
    }
}

// acceptor0_Table acceptor0_ingress_transport_tbl
procedure {:inline 1} acceptor0_ingress_transport_tbl.apply()
	modifies acceptor0_drop, acceptor0_forward, acceptor0_hdr.ipv4.dstAddr, acceptor0_hdr.udp.dstPort, acceptor0_ingress_transport_tbl.action_run, acceptor0_ingress_transport_tbl.hit, acceptor0_standard_metadata.egress_port, acceptor0_standard_metadata.egress_spec;
{
    acceptor0_hdr.ipv4.dstAddr := acceptor0_hdr.ipv4.dstAddr;
    acceptor0_ingress_transport_tbl.hit := false;
    goto acceptor0_action_drop_1, acceptor0_action_ingress_forward;

    acceptor0_action_drop_1:
    assume acceptor0_ingress_transport_tbl.action_run == acceptor0_ingress_transport_tbl.action.drop_1;
    call acceptor0_drop_1();
    goto acceptor0_Exit;

    acceptor0_action_ingress_forward:
    assume acceptor0_ingress_transport_tbl.action_run == acceptor0_ingress_transport_tbl.action.ingress_forward;
    call acceptor0_ingress_forward(acceptor0_ingress_transport_tbl.ingress_forward.port, acceptor0_ingress_transport_tbl.ingress_forward.udp_dst);
    goto acceptor0_Exit;

    acceptor0_Exit:
}
procedure {:inline 1} acceptor0_main()
	modifies acceptor0_drop, acceptor0_egress_place_holder_table.hit, acceptor0_forward, acceptor0_hdr.arp.op, acceptor0_hdr.arp.sha, acceptor0_hdr.arp.spa, acceptor0_hdr.arp.tha, acceptor0_hdr.arp.tpa, acceptor0_hdr.ethernet.dstAddr, acceptor0_hdr.ethernet.srcAddr, acceptor0_hdr.icmp.hdrChecksum, acceptor0_hdr.icmp.icmpType, acceptor0_hdr.ipv4.dstAddr, acceptor0_hdr.ipv4.hdrChecksum, acceptor0_hdr.ipv4.srcAddr, acceptor0_hdr.paxos.acptid, acceptor0_hdr.paxos.msgtype, acceptor0_hdr.paxos.paxosval, acceptor0_hdr.paxos.vrnd, acceptor0_hdr.udp.dstPort, acceptor0_ingress_acceptor_tbl.action_run, acceptor0_ingress_acceptor_tbl.hit, acceptor0_ingress_arp_tbl.action_run, acceptor0_ingress_arp_tbl.hit, acceptor0_ingress_icmp_tbl.action_run, acceptor0_ingress_icmp_tbl.hit, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_index0, acceptor0_ingress_registerVRound, acceptor0_ingress_registerVRound__last0_old_value, acceptor0_ingress_registerVRound__last0_value, acceptor0_ingress_registerVRound__last_index, acceptor0_ingress_registerVRound__last_old_value, acceptor0_ingress_registerVRound__last_value, acceptor0_ingress_registerVRound__last_write_site, acceptor0_ingress_registerVRound__next_write_site, acceptor0_ingress_registerVRound__wrote_any, acceptor0_ingress_registerVRound__wrote_index0, acceptor0_ingress_registerValue, acceptor0_ingress_registerValue__last0_old_value, acceptor0_ingress_registerValue__last0_value, acceptor0_ingress_registerValue__last_index, acceptor0_ingress_registerValue__last_old_value, acceptor0_ingress_registerValue__last_value, acceptor0_ingress_registerValue__last_write_site, acceptor0_ingress_registerValue__next_write_site, acceptor0_ingress_registerValue__wrote_any, acceptor0_ingress_registerValue__wrote_index0, acceptor0_ingress_transport_tbl.action_run, acceptor0_ingress_transport_tbl.hit, acceptor0_ipdst_0, acceptor0_isValid, acceptor0_meta.paxos_metadata.round, acceptor0_p4b_checksum_updated, acceptor0_standard_metadata.egress_port, acceptor0_standard_metadata.egress_spec;
{
    call acceptor0_TopParser();
    call acceptor0_verifyChecksum();
    call acceptor0_ingress();
    call acceptor0_egress();
    call acceptor0_computeChecksum();
    if(acceptor0_forward == false){
        acceptor0_drop := true;
    }
}
procedure acceptor0_mainProcedure()
	modifies acceptor0_drop, acceptor0_egress_place_holder_table.hit, acceptor0_forward, acceptor0_hdr.arp.op, acceptor0_hdr.arp.sha, acceptor0_hdr.arp.spa, acceptor0_hdr.arp.tha, acceptor0_hdr.arp.tpa, acceptor0_hdr.ethernet.dstAddr, acceptor0_hdr.ethernet.srcAddr, acceptor0_hdr.icmp.hdrChecksum, acceptor0_hdr.icmp.icmpType, acceptor0_hdr.ipv4.dstAddr, acceptor0_hdr.ipv4.hdrChecksum, acceptor0_hdr.ipv4.srcAddr, acceptor0_hdr.paxos.acptid, acceptor0_hdr.paxos.msgtype, acceptor0_hdr.paxos.paxosval, acceptor0_hdr.paxos.vrnd, acceptor0_hdr.udp.dstPort, acceptor0_ingress_acceptor_tbl.action_run, acceptor0_ingress_acceptor_tbl.hit, acceptor0_ingress_arp_tbl.action_run, acceptor0_ingress_arp_tbl.hit, acceptor0_ingress_icmp_tbl.action_run, acceptor0_ingress_icmp_tbl.hit, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_index0, acceptor0_ingress_registerVRound, acceptor0_ingress_registerVRound__last0_old_value, acceptor0_ingress_registerVRound__last0_value, acceptor0_ingress_registerVRound__last_index, acceptor0_ingress_registerVRound__last_old_value, acceptor0_ingress_registerVRound__last_value, acceptor0_ingress_registerVRound__last_write_site, acceptor0_ingress_registerVRound__next_write_site, acceptor0_ingress_registerVRound__wrote_any, acceptor0_ingress_registerVRound__wrote_index0, acceptor0_ingress_registerValue, acceptor0_ingress_registerValue__last0_old_value, acceptor0_ingress_registerValue__last0_value, acceptor0_ingress_registerValue__last_index, acceptor0_ingress_registerValue__last_old_value, acceptor0_ingress_registerValue__last_value, acceptor0_ingress_registerValue__last_write_site, acceptor0_ingress_registerValue__next_write_site, acceptor0_ingress_registerValue__wrote_any, acceptor0_ingress_registerValue__wrote_index0, acceptor0_ingress_transport_tbl.action_run, acceptor0_ingress_transport_tbl.hit, acceptor0_ipdst_0, acceptor0_isValid, acceptor0_meta.paxos_metadata.round, acceptor0_p4b_checksum_error, acceptor0_p4b_checksum_updated, acceptor0_p4b_checksum_verified, acceptor0_p4b_clone_e2e, acceptor0_p4b_clone_i2e, acceptor0_p4b_clone_i2i, acceptor0_p4b_digest, acceptor0_p4b_recirculate, acceptor0_standard_metadata.egress_port, acceptor0_standard_metadata.egress_spec;
{
    acceptor0_p4b_checksum_error := false;
    acceptor0_p4b_checksum_updated := false;
    acceptor0_p4b_checksum_verified := false;
    acceptor0_p4b_digest := false;
    acceptor0_p4b_recirculate := false;
    acceptor0_p4b_clone_i2i := false;
    acceptor0_p4b_clone_e2e := false;
    acceptor0_p4b_clone_i2e := false;
    call acceptor0_main();
}
procedure acceptor0_mark_to_drop();
    ensures acceptor0_drop==true;
	modifies acceptor0_drop;
procedure acceptor0_packet.emit(acceptor0_arg0:acceptor0_Ref);
procedure acceptor0_packet_in.extract(acceptor0_header:acceptor0_Ref);
    ensures (acceptor0_isValid[acceptor0_header] == true);
	modifies acceptor0_isValid;
procedure acceptor0_reject();
    ensures acceptor0_drop==true;
	modifies acceptor0_drop;
procedure {:inline 1} acceptor0_setInvalid(acceptor0_header:acceptor0_Ref);
    ensures (acceptor0_isValid[acceptor0_header] == false);
	modifies acceptor0_isValid;
procedure {:inline 1} acceptor0_setValid(acceptor0_header:acceptor0_Ref);

// acceptor0_Control acceptor0_verifyChecksum
procedure {:inline 1} acceptor0_verifyChecksum()
{
}
// ===== END NODE acceptor0 =====

// ===== BEGIN NODE acceptor1 (prefixed) =====
type acceptor1_Ref;
type acceptor1_error=bv1;
type acceptor1_HeaderStack = [int]acceptor1_Ref;
var acceptor1_last:[acceptor1_HeaderStack]acceptor1_Ref;
var acceptor1_forward:bool;
var acceptor1_isValid:[acceptor1_Ref]bool;
var acceptor1_emit:[acceptor1_Ref]bool;
var acceptor1_stack.index:[acceptor1_HeaderStack]int;
var acceptor1_size:[acceptor1_HeaderStack]int;
var acceptor1_drop:bool;
var acceptor1_p4b_clone_i2e:bool;
var acceptor1_p4b_clone_e2e:bool;
var acceptor1_p4b_clone_i2i:bool;
var acceptor1_p4b_recirculate:bool;
var acceptor1_p4b_digest:bool;
var acceptor1_p4b_checksum_verified:bool;
var acceptor1_p4b_checksum_updated:bool;
var acceptor1_p4b_checksum_error:bool;

// acceptor1_Struct acceptor1_standard_metadata_t
type acceptor1_standard_metadata_t;
var acceptor1_standard_metadata.ingress_port:bv9;
var acceptor1_standard_metadata.egress_spec:bv9;
var acceptor1_standard_metadata.egress_port:bv9;
var acceptor1_standard_metadata.instance_type:bv32;
var acceptor1_standard_metadata.packet_length:bv32;
var acceptor1_standard_metadata.enq_timestamp:bv32;
var acceptor1_standard_metadata.enq_qdepth:bv19;
var acceptor1_standard_metadata.deq_timedelta:bv32;
var acceptor1_standard_metadata.deq_qdepth:bv19;
var acceptor1_standard_metadata.ingress_global_timestamp:bv48;
var acceptor1_standard_metadata.egress_global_timestamp:bv48;
var acceptor1_standard_metadata.mcast_grp:bv16;
var acceptor1_standard_metadata.egress_rid:bv16;
var acceptor1_standard_metadata.checksum_error:bv1;
var acceptor1_standard_metadata.parser_error:acceptor1_error;
var acceptor1_standard_metadata.priority:bv3;
type acceptor1_CounterType = int;
type acceptor1_MeterType = int;
type acceptor1_HashAlgorithm = int;
type acceptor1_CloneType = int;
type acceptor1_EthernetAddress = bv48;
type acceptor1_IPv4Address = bv32;
type acceptor1_PortId = bv4;
type acceptor1_ethernet_t;
type acceptor1_arp_t;
type acceptor1_ipv4_t;
type acceptor1_icmp_t;
type acceptor1_udp_t;
type acceptor1_paxos_t;

// acceptor1_Struct acceptor1_headers
var acceptor1_hdr:acceptor1_Ref;

// acceptor1_Header acceptor1_ethernet_t
var acceptor1_hdr.ethernet:acceptor1_Ref;
var acceptor1_hdr.ethernet.valid:bool;
var acceptor1_hdr.ethernet.dstAddr:acceptor1_EthernetAddress;
var acceptor1_hdr.ethernet.srcAddr:acceptor1_EthernetAddress;
var acceptor1_hdr.ethernet.etherType:bv16;

// acceptor1_Header acceptor1_arp_t
var acceptor1_hdr.arp:acceptor1_Ref;
var acceptor1_hdr.arp.valid:bool;
var acceptor1_hdr.arp.hrd:bv16;
var acceptor1_hdr.arp.pro:bv16;
var acceptor1_hdr.arp.hln:bv8;
var acceptor1_hdr.arp.pln:bv8;
var acceptor1_hdr.arp.op:bv16;
var acceptor1_hdr.arp.sha:bv48;
var acceptor1_hdr.arp.spa:bv32;
var acceptor1_hdr.arp.tha:bv48;
var acceptor1_hdr.arp.tpa:bv32;

// acceptor1_Header acceptor1_ipv4_t
var acceptor1_hdr.ipv4:acceptor1_Ref;
var acceptor1_hdr.ipv4.valid:bool;
var acceptor1_hdr.ipv4.version:bv4;
var acceptor1_hdr.ipv4.ihl:bv4;
var acceptor1_hdr.ipv4.diffserv:bv8;
var acceptor1_hdr.ipv4.totalLen:bv16;
var acceptor1_hdr.ipv4.identification:bv16;
var acceptor1_hdr.ipv4.flags:bv3;
var acceptor1_hdr.ipv4.fragOffset:bv13;
var acceptor1_hdr.ipv4.ttl:bv8;
var acceptor1_hdr.ipv4.protocol:bv8;
var acceptor1_hdr.ipv4.hdrChecksum:bv16;
var acceptor1_hdr.ipv4.srcAddr:acceptor1_IPv4Address;
var acceptor1_hdr.ipv4.dstAddr:acceptor1_IPv4Address;

// acceptor1_Header acceptor1_icmp_t
var acceptor1_hdr.icmp:acceptor1_Ref;
var acceptor1_hdr.icmp.valid:bool;
var acceptor1_hdr.icmp.icmpType:bv8;
var acceptor1_hdr.icmp.icmpCode:bv8;
var acceptor1_hdr.icmp.hdrChecksum:bv16;
var acceptor1_hdr.icmp.identifier:bv16;
var acceptor1_hdr.icmp.seqNumber:bv16;
var acceptor1_hdr.icmp.payload:bv256;

// acceptor1_Header acceptor1_udp_t
var acceptor1_hdr.udp:acceptor1_Ref;
var acceptor1_hdr.udp.valid:bool;
var acceptor1_hdr.udp.srcPort:bv16;
var acceptor1_hdr.udp.dstPort:bv16;
var acceptor1_hdr.udp.length_:bv16;
var acceptor1_hdr.udp.checksum:bv16;

// acceptor1_Header acceptor1_paxos_t
var acceptor1_hdr.paxos:acceptor1_Ref;
var acceptor1_hdr.paxos.valid:bool;
var acceptor1_hdr.paxos.msgtype:bv16;
var acceptor1_hdr.paxos.inst:bv32;
var acceptor1_hdr.paxos.rnd:bv16;
var acceptor1_hdr.paxos.vrnd:bv16;
var acceptor1_hdr.paxos.acptid:bv16;
var acceptor1_hdr.paxos.paxoslen:bv32;
var acceptor1_hdr.paxos.paxosval:bv256;

// acceptor1_Struct acceptor1_paxos_metadata_t
type acceptor1_paxos_metadata_t;

// acceptor1_Struct acceptor1_metadata
type acceptor1_metadata;
var acceptor1_meta.paxos_metadata:acceptor1_paxos_metadata_t;
var acceptor1_meta.paxos_metadata.round:bv16;
var acceptor1_meta.paxos_metadata.set_drop:bv1;
var acceptor1_meta.paxos_metadata.ack_count:bv8;
var acceptor1_meta.paxos_metadata.ack_acceptors:bv8;
var acceptor1_meta:acceptor1_metadata;
var acceptor1_standard_metadata:acceptor1_standard_metadata_t;
var acceptor1_ipdst_0:bv32;

// acceptor1_Register acceptor1_ingress_registerAcceptorID
var acceptor1_ingress_registerAcceptorID:[bv32]bv16;
var acceptor1_ingress_registerAcceptorID__last_index:bv32;
var acceptor1_ingress_registerAcceptorID__last_value:bv16;
var acceptor1_ingress_registerAcceptorID__last_old_value:bv16;
var acceptor1_ingress_registerAcceptorID__wrote_any:bool;
var acceptor1_ingress_registerAcceptorID__wrote_index0:bool;
var acceptor1_ingress_registerAcceptorID__last0_old_value:bv16;
var acceptor1_ingress_registerAcceptorID__last0_value:bv16;
var acceptor1_ingress_registerAcceptorID__next_write_site:int;
var acceptor1_ingress_registerAcceptorID__last_write_site:int;
const acceptor1_ingress_registerAcceptorID.size:bv32;
axiom acceptor1_ingress_registerAcceptorID.size == 1bv32;

// acceptor1_Register acceptor1_ingress_registerRound
var acceptor1_ingress_registerRound:[bv32]bv16;
var acceptor1_ingress_registerRound__last_index:bv32;
var acceptor1_ingress_registerRound__last_value:bv16;
var acceptor1_ingress_registerRound__last_old_value:bv16;
var acceptor1_ingress_registerRound__wrote_any:bool;
var acceptor1_ingress_registerRound__wrote_index0:bool;
var acceptor1_ingress_registerRound__last0_old_value:bv16;
var acceptor1_ingress_registerRound__last0_value:bv16;
var acceptor1_ingress_registerRound__next_write_site:int;
var acceptor1_ingress_registerRound__last_write_site:int;
const acceptor1_ingress_registerRound.size:bv32;
axiom acceptor1_ingress_registerRound.size == 65536bv32;

// acceptor1_Register acceptor1_ingress_registerVRound
var acceptor1_ingress_registerVRound:[bv32]bv16;
var acceptor1_ingress_registerVRound__last_index:bv32;
var acceptor1_ingress_registerVRound__last_value:bv16;
var acceptor1_ingress_registerVRound__last_old_value:bv16;
var acceptor1_ingress_registerVRound__wrote_any:bool;
var acceptor1_ingress_registerVRound__wrote_index0:bool;
var acceptor1_ingress_registerVRound__last0_old_value:bv16;
var acceptor1_ingress_registerVRound__last0_value:bv16;
var acceptor1_ingress_registerVRound__next_write_site:int;
var acceptor1_ingress_registerVRound__last_write_site:int;
const acceptor1_ingress_registerVRound.size:bv32;
axiom acceptor1_ingress_registerVRound.size == 65536bv32;

// acceptor1_Register acceptor1_ingress_registerValue
var acceptor1_ingress_registerValue:[bv32]bv256;
var acceptor1_ingress_registerValue__last_index:bv32;
var acceptor1_ingress_registerValue__last_value:bv256;
var acceptor1_ingress_registerValue__last_old_value:bv256;
var acceptor1_ingress_registerValue__wrote_any:bool;
var acceptor1_ingress_registerValue__wrote_index0:bool;
var acceptor1_ingress_registerValue__last0_old_value:bv256;
var acceptor1_ingress_registerValue__last0_value:bv256;
var acceptor1_ingress_registerValue__next_write_site:int;
var acceptor1_ingress_registerValue__last_write_site:int;
const acceptor1_ingress_registerValue.size:bv32;
axiom acceptor1_ingress_registerValue.size == 65536bv32;

// acceptor1_Register acceptor1_ingress_learner_mac_address
var acceptor1_ingress_learner_mac_address:[bv32]bv48;
var acceptor1_ingress_learner_mac_address__last_index:bv32;
var acceptor1_ingress_learner_mac_address__last_value:bv48;
var acceptor1_ingress_learner_mac_address__last_old_value:bv48;
var acceptor1_ingress_learner_mac_address__wrote_any:bool;
var acceptor1_ingress_learner_mac_address__wrote_index0:bool;
var acceptor1_ingress_learner_mac_address__last0_old_value:bv48;
var acceptor1_ingress_learner_mac_address__last0_value:bv48;
var acceptor1_ingress_learner_mac_address__next_write_site:int;
var acceptor1_ingress_learner_mac_address__last_write_site:int;
const acceptor1_ingress_learner_mac_address.size:bv32;
axiom acceptor1_ingress_learner_mac_address.size == 1bv32;

// acceptor1_Register acceptor1_ingress_learner_address
var acceptor1_ingress_learner_address:[bv32]bv32;
var acceptor1_ingress_learner_address__last_index:bv32;
var acceptor1_ingress_learner_address__last_value:bv32;
var acceptor1_ingress_learner_address__last_old_value:bv32;
var acceptor1_ingress_learner_address__wrote_any:bool;
var acceptor1_ingress_learner_address__wrote_index0:bool;
var acceptor1_ingress_learner_address__last0_old_value:bv32;
var acceptor1_ingress_learner_address__last0_value:bv32;
var acceptor1_ingress_learner_address__next_write_site:int;
var acceptor1_ingress_learner_address__last_write_site:int;
const acceptor1_ingress_learner_address.size:bv32;
axiom acceptor1_ingress_learner_address.size == 1bv32;

// acceptor1_Table acceptor1_ingress_acceptor_tbl acceptor1_Actionlist acceptor1_Declaration
type acceptor1_ingress_acceptor_tbl.action;
const unique acceptor1_ingress_acceptor_tbl.action.ingress_handle_1a : acceptor1_ingress_acceptor_tbl.action;
const unique acceptor1_ingress_acceptor_tbl.action.ingress_handle_2a : acceptor1_ingress_acceptor_tbl.action;
const unique acceptor1_ingress_acceptor_tbl.action.ingress_drop : acceptor1_ingress_acceptor_tbl.action;
var acceptor1_ingress_acceptor_tbl.action_run : acceptor1_ingress_acceptor_tbl.action;
var acceptor1_ingress_acceptor_tbl.hit : bool;

// acceptor1_Table acceptor1_ingress_transport_tbl acceptor1_Actionlist acceptor1_Declaration
type acceptor1_ingress_transport_tbl.action;
var acceptor1_ingress_transport_tbl.ingress_forward.port:acceptor1_PortId;
var acceptor1_ingress_transport_tbl.ingress_forward.udp_dst:bv16;
const unique acceptor1_ingress_transport_tbl.action.drop_1 : acceptor1_ingress_transport_tbl.action;
const unique acceptor1_ingress_transport_tbl.action.ingress_forward : acceptor1_ingress_transport_tbl.action;
var acceptor1_ingress_transport_tbl.action_run : acceptor1_ingress_transport_tbl.action;
var acceptor1_ingress_transport_tbl.hit : bool;

// acceptor1_Register acceptor1_ingress_my_mac_address
var acceptor1_ingress_my_mac_address:[bv32]bv48;
var acceptor1_ingress_my_mac_address__last_index:bv32;
var acceptor1_ingress_my_mac_address__last_value:bv48;
var acceptor1_ingress_my_mac_address__last_old_value:bv48;
var acceptor1_ingress_my_mac_address__wrote_any:bool;
var acceptor1_ingress_my_mac_address__wrote_index0:bool;
var acceptor1_ingress_my_mac_address__last0_old_value:bv48;
var acceptor1_ingress_my_mac_address__last0_value:bv48;
var acceptor1_ingress_my_mac_address__next_write_site:int;
var acceptor1_ingress_my_mac_address__last_write_site:int;
const acceptor1_ingress_my_mac_address.size:bv32;
axiom acceptor1_ingress_my_mac_address.size == 1bv32;

// acceptor1_Register acceptor1_ingress_my_ip_address
var acceptor1_ingress_my_ip_address:[bv32]bv32;
var acceptor1_ingress_my_ip_address__last_index:bv32;
var acceptor1_ingress_my_ip_address__last_value:bv32;
var acceptor1_ingress_my_ip_address__last_old_value:bv32;
var acceptor1_ingress_my_ip_address__wrote_any:bool;
var acceptor1_ingress_my_ip_address__wrote_index0:bool;
var acceptor1_ingress_my_ip_address__last0_old_value:bv32;
var acceptor1_ingress_my_ip_address__last0_value:bv32;
var acceptor1_ingress_my_ip_address__next_write_site:int;
var acceptor1_ingress_my_ip_address__last_write_site:int;
const acceptor1_ingress_my_ip_address.size:bv32;
axiom acceptor1_ingress_my_ip_address.size == 1bv32;

// acceptor1_Table acceptor1_ingress_arp_tbl acceptor1_Actionlist acceptor1_Declaration
type acceptor1_ingress_arp_tbl.action;
const unique acceptor1_ingress_arp_tbl.action.ingress_handle_arp_request : acceptor1_ingress_arp_tbl.action;
const unique acceptor1_ingress_arp_tbl.action.ingress_handle_arp_reply : acceptor1_ingress_arp_tbl.action;
const unique acceptor1_ingress_arp_tbl.action.drop_2 : acceptor1_ingress_arp_tbl.action;
var acceptor1_ingress_arp_tbl.action_run : acceptor1_ingress_arp_tbl.action;
var acceptor1_ingress_arp_tbl.hit : bool;


// acceptor1_Table acceptor1_ingress_icmp_tbl acceptor1_Actionlist acceptor1_Declaration
type acceptor1_ingress_icmp_tbl.action;
const unique acceptor1_ingress_icmp_tbl.action.ingress_handle_icmp_request : acceptor1_ingress_icmp_tbl.action;
const unique acceptor1_ingress_icmp_tbl.action.ingress_handle_icmp_reply : acceptor1_ingress_icmp_tbl.action;
const unique acceptor1_ingress_icmp_tbl.action.drop_3 : acceptor1_ingress_icmp_tbl.action;
var acceptor1_ingress_icmp_tbl.action_run : acceptor1_ingress_icmp_tbl.action;
var acceptor1_ingress_icmp_tbl.hit : bool;



// acceptor1_Table acceptor1_egress_place_holder_table acceptor1_Actionlist acceptor1_Declaration
type acceptor1_egress_place_holder_table.action;
const unique acceptor1_egress_place_holder_table.action.NoAction : acceptor1_egress_place_holder_table.action;
var acceptor1_egress_place_holder_table.action_run : acceptor1_egress_place_holder_table.action;
var acceptor1_egress_place_holder_table.hit : bool;



// acceptor1_Action acceptor1_NoAction
procedure {:inline 1} acceptor1_NoAction()
{
}

// acceptor1_Parser acceptor1_TopParser
procedure {:inline 1} acceptor1_TopParser()
	modifies acceptor1_drop, acceptor1_isValid;
{
    goto acceptor1_State$TopParser$start;

        acceptor1_State$TopParser$start:
    call acceptor1_packet_in.extract(acceptor1_hdr.ethernet);
    goto acceptor1_State$TopParser$start$parse_arp_2, acceptor1_State$TopParser$start$parse_ipv4_1, acceptor1_State$TopParser$start$DEFAULT;
    
acceptor1_State$TopParser$start$parse_arp_2:
    assume (acceptor1_hdr.ethernet.etherType == 2054bv16);
    goto acceptor1_State$TopParser$parse_arp;
    
acceptor1_State$TopParser$start$parse_ipv4_1:
    assume (acceptor1_hdr.ethernet.etherType == 2048bv16);
    goto acceptor1_State$TopParser$parse_ipv4;

    acceptor1_State$TopParser$start$DEFAULT:
    assume(!(acceptor1_hdr.ethernet.etherType == 2054bv16)&&!(acceptor1_hdr.ethernet.etherType == 2048bv16));
goto acceptor1_State$reject;

        acceptor1_State$TopParser$parse_arp:
    call acceptor1_packet_in.extract(acceptor1_hdr.arp);
    goto acceptor1_State$accept;

        acceptor1_State$TopParser$parse_ipv4:
    call acceptor1_packet_in.extract(acceptor1_hdr.ipv4);
    goto acceptor1_State$TopParser$parse_ipv4$parse_icmp_3, acceptor1_State$TopParser$parse_ipv4$parse_udp_2, acceptor1_State$TopParser$parse_ipv4$DEFAULT;
    
acceptor1_State$TopParser$parse_ipv4$parse_icmp_3:
    assume (acceptor1_hdr.ipv4.protocol == 1bv8);
    goto acceptor1_State$TopParser$parse_icmp;
    
acceptor1_State$TopParser$parse_ipv4$parse_udp_2:
    assume (acceptor1_hdr.ipv4.protocol == 17bv8);
    goto acceptor1_State$TopParser$parse_udp;

    acceptor1_State$TopParser$parse_ipv4$DEFAULT:
    assume(!(acceptor1_hdr.ipv4.protocol == 1bv8)&&!(acceptor1_hdr.ipv4.protocol == 17bv8));
    goto acceptor1_State$accept;

        acceptor1_State$TopParser$parse_icmp:
    call acceptor1_packet_in.extract(acceptor1_hdr.icmp);
    goto acceptor1_State$accept;

        acceptor1_State$TopParser$parse_udp:
    call acceptor1_packet_in.extract(acceptor1_hdr.udp);
    goto acceptor1_State$TopParser$parse_udp$parse_paxos_2, acceptor1_State$TopParser$parse_udp$DEFAULT;
    
acceptor1_State$TopParser$parse_udp$parse_paxos_2:
    assume (acceptor1_hdr.udp.dstPort == 34952bv16);
    goto acceptor1_State$TopParser$parse_paxos;

    acceptor1_State$TopParser$parse_udp$DEFAULT:
    assume(!(acceptor1_hdr.udp.dstPort == 34952bv16));
    goto acceptor1_State$accept;

        acceptor1_State$TopParser$parse_paxos:
    call acceptor1_packet_in.extract(acceptor1_hdr.paxos);
    goto acceptor1_State$accept;

    acceptor1_State$accept:
    call acceptor1_accept();
    goto acceptor1_Exit;

    acceptor1_State$reject:
    call acceptor1_reject();
    goto acceptor1_Exit;

    acceptor1_Exit:
}
procedure {:inline 1} acceptor1_accept()
{
}

// acceptor1_Control acceptor1_computeChecksum
procedure {:inline 1} acceptor1_computeChecksum()
	modifies acceptor1_hdr.ipv4.hdrChecksum, acceptor1_p4b_checksum_updated;
{
    if (acceptor1_isValid[acceptor1_hdr.ipv4]) {
        acceptor1_p4b_checksum_updated := true;
        havoc acceptor1_hdr.ipv4.hdrChecksum;
    }
}

// acceptor1_Action acceptor1_drop_1
procedure {:inline 1} acceptor1_drop_1()
	modifies acceptor1_drop;
{
    call acceptor1_mark_to_drop();
}

// acceptor1_Action acceptor1_drop_2
procedure {:inline 1} acceptor1_drop_2()
	modifies acceptor1_drop;
{
    call acceptor1_mark_to_drop();
}

// acceptor1_Action acceptor1_drop_3
procedure {:inline 1} acceptor1_drop_3()
	modifies acceptor1_drop;
{
    call acceptor1_mark_to_drop();
}

// acceptor1_Control acceptor1_egress
procedure {:inline 1} acceptor1_egress()
	modifies acceptor1_egress_place_holder_table.hit;
{
    call acceptor1_egress_place_holder_table.apply();
}

// acceptor1_Table acceptor1_egress_place_holder_table
procedure {:inline 1} acceptor1_egress_place_holder_table.apply()
	modifies acceptor1_egress_place_holder_table.hit;
{
    acceptor1_egress_place_holder_table.hit := false;
    goto acceptor1_Exit;

    acceptor1_Exit:
}

// acceptor1_Control acceptor1_ingress
procedure {:inline 1} acceptor1_ingress()
	modifies acceptor1_drop, acceptor1_forward, acceptor1_hdr.arp.op, acceptor1_hdr.arp.sha, acceptor1_hdr.arp.spa, acceptor1_hdr.arp.tha, acceptor1_hdr.arp.tpa, acceptor1_hdr.ethernet.dstAddr, acceptor1_hdr.ethernet.srcAddr, acceptor1_hdr.icmp.hdrChecksum, acceptor1_hdr.icmp.icmpType, acceptor1_hdr.ipv4.dstAddr, acceptor1_hdr.ipv4.srcAddr, acceptor1_hdr.paxos.acptid, acceptor1_hdr.paxos.msgtype, acceptor1_hdr.paxos.paxosval, acceptor1_hdr.paxos.vrnd, acceptor1_hdr.udp.dstPort, acceptor1_ingress_acceptor_tbl.action_run, acceptor1_ingress_acceptor_tbl.hit, acceptor1_ingress_arp_tbl.action_run, acceptor1_ingress_arp_tbl.hit, acceptor1_ingress_icmp_tbl.action_run, acceptor1_ingress_icmp_tbl.hit, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_index0, acceptor1_ingress_registerVRound, acceptor1_ingress_registerVRound__last0_old_value, acceptor1_ingress_registerVRound__last0_value, acceptor1_ingress_registerVRound__last_index, acceptor1_ingress_registerVRound__last_old_value, acceptor1_ingress_registerVRound__last_value, acceptor1_ingress_registerVRound__last_write_site, acceptor1_ingress_registerVRound__next_write_site, acceptor1_ingress_registerVRound__wrote_any, acceptor1_ingress_registerVRound__wrote_index0, acceptor1_ingress_registerValue, acceptor1_ingress_registerValue__last0_old_value, acceptor1_ingress_registerValue__last0_value, acceptor1_ingress_registerValue__last_index, acceptor1_ingress_registerValue__last_old_value, acceptor1_ingress_registerValue__last_value, acceptor1_ingress_registerValue__last_write_site, acceptor1_ingress_registerValue__next_write_site, acceptor1_ingress_registerValue__wrote_any, acceptor1_ingress_registerValue__wrote_index0, acceptor1_ingress_transport_tbl.action_run, acceptor1_ingress_transport_tbl.hit, acceptor1_ipdst_0, acceptor1_meta.paxos_metadata.round, acceptor1_standard_metadata.egress_port, acceptor1_standard_metadata.egress_spec;
{
havoc acceptor1_ipdst_0;
    if(acceptor1_isValid[acceptor1_hdr.arp]){
        call acceptor1_ingress_arp_tbl.apply();
    }
    else{
        if(acceptor1_isValid[acceptor1_hdr.ipv4]){
            if(acceptor1_isValid[acceptor1_hdr.paxos]){
                call acceptor1_ingress_read_round();
                if(buge.bv16(acceptor1_hdr.paxos.rnd, acceptor1_meta.paxos_metadata.round)){
                    // acceptor1_read
                    acceptor1_hdr.paxos.vrnd := acceptor1_ingress_registerVRound.read(acceptor1_ingress_registerVRound, acceptor1_hdr.paxos.inst);
                    assert bule.bv16(acceptor1_hdr.paxos.vrnd, acceptor1_meta.paxos_metadata.round);
                    call acceptor1_ingress_acceptor_tbl.apply();
                    call acceptor1_ingress_transport_tbl.apply();
                }
            }
            else{
                if(acceptor1_isValid[acceptor1_hdr.icmp]){
                    call acceptor1_ingress_icmp_tbl.apply();
                }
            }
        }
    }
}

// acceptor1_Table acceptor1_ingress_acceptor_tbl
procedure {:inline 1} acceptor1_ingress_acceptor_tbl.apply()
	modifies acceptor1_drop, acceptor1_hdr.paxos.acptid, acceptor1_hdr.paxos.msgtype, acceptor1_hdr.paxos.paxosval, acceptor1_hdr.paxos.vrnd, acceptor1_ingress_acceptor_tbl.action_run, acceptor1_ingress_acceptor_tbl.hit, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_index0, acceptor1_ingress_registerVRound, acceptor1_ingress_registerVRound__last0_old_value, acceptor1_ingress_registerVRound__last0_value, acceptor1_ingress_registerVRound__last_index, acceptor1_ingress_registerVRound__last_old_value, acceptor1_ingress_registerVRound__last_value, acceptor1_ingress_registerVRound__last_write_site, acceptor1_ingress_registerVRound__next_write_site, acceptor1_ingress_registerVRound__wrote_any, acceptor1_ingress_registerVRound__wrote_index0, acceptor1_ingress_registerValue, acceptor1_ingress_registerValue__last0_old_value, acceptor1_ingress_registerValue__last0_value, acceptor1_ingress_registerValue__last_index, acceptor1_ingress_registerValue__last_old_value, acceptor1_ingress_registerValue__last_value, acceptor1_ingress_registerValue__last_write_site, acceptor1_ingress_registerValue__next_write_site, acceptor1_ingress_registerValue__wrote_any, acceptor1_ingress_registerValue__wrote_index0;
{
    acceptor1_hdr.paxos.msgtype := acceptor1_hdr.paxos.msgtype;
    acceptor1_ingress_acceptor_tbl.hit := false;
    goto acceptor1_action_ingress_handle_1a, acceptor1_action_ingress_handle_2a, acceptor1_action_ingress_drop;

    acceptor1_action_ingress_handle_1a:
    assume acceptor1_ingress_acceptor_tbl.action_run == acceptor1_ingress_acceptor_tbl.action.ingress_handle_1a;
    call acceptor1_ingress_handle_1a();
    goto acceptor1_Exit;

    acceptor1_action_ingress_handle_2a:
    assume acceptor1_ingress_acceptor_tbl.action_run == acceptor1_ingress_acceptor_tbl.action.ingress_handle_2a;
    call acceptor1_ingress_handle_2a();
    goto acceptor1_Exit;

    acceptor1_action_ingress_drop:
    assume acceptor1_ingress_acceptor_tbl.action_run == acceptor1_ingress_acceptor_tbl.action.ingress_drop;
    call acceptor1_ingress_drop();
    goto acceptor1_Exit;

    acceptor1_Exit:
}

// acceptor1_Table acceptor1_ingress_arp_tbl
procedure {:inline 1} acceptor1_ingress_arp_tbl.apply()
	modifies acceptor1_drop, acceptor1_forward, acceptor1_hdr.arp.op, acceptor1_hdr.arp.sha, acceptor1_hdr.arp.spa, acceptor1_hdr.arp.tha, acceptor1_hdr.arp.tpa, acceptor1_hdr.ethernet.dstAddr, acceptor1_hdr.ethernet.srcAddr, acceptor1_ingress_arp_tbl.action_run, acceptor1_ingress_arp_tbl.hit, acceptor1_standard_metadata.egress_port, acceptor1_standard_metadata.egress_spec;
{
    acceptor1_hdr.arp.op := acceptor1_hdr.arp.op;
    acceptor1_ingress_arp_tbl.hit := false;
    goto acceptor1_action_ingress_handle_arp_request, acceptor1_action_ingress_handle_arp_reply, acceptor1_action_drop_2;

    acceptor1_action_ingress_handle_arp_request:
    assume acceptor1_ingress_arp_tbl.action_run == acceptor1_ingress_arp_tbl.action.ingress_handle_arp_request;
    call acceptor1_ingress_handle_arp_request();
    goto acceptor1_Exit;

    acceptor1_action_ingress_handle_arp_reply:
    assume acceptor1_ingress_arp_tbl.action_run == acceptor1_ingress_arp_tbl.action.ingress_handle_arp_reply;
    call acceptor1_ingress_handle_arp_reply();
    goto acceptor1_Exit;

    acceptor1_action_drop_2:
    assume acceptor1_ingress_arp_tbl.action_run == acceptor1_ingress_arp_tbl.action.drop_2;
    call acceptor1_drop_2();
    goto acceptor1_Exit;

    acceptor1_Exit:
}

// acceptor1_Action acceptor1_ingress_drop
procedure {:inline 1} acceptor1_ingress_drop()
	modifies acceptor1_drop;
{
    call acceptor1_mark_to_drop();
}

// acceptor1_Action acceptor1_ingress_forward
procedure {:inline 1} acceptor1_ingress_forward(acceptor1_port:acceptor1_PortId, acceptor1_udp_dst:bv16)
	modifies acceptor1_forward, acceptor1_hdr.udp.dstPort, acceptor1_standard_metadata.egress_port, acceptor1_standard_metadata.egress_spec;
{
    acceptor1_standard_metadata.egress_spec := 0bv5++acceptor1_port;
    acceptor1_standard_metadata.egress_port := 0bv5++acceptor1_port;
    acceptor1_forward := true;
    acceptor1_hdr.udp.dstPort := acceptor1_udp_dst;
}

// acceptor1_Action acceptor1_ingress_handle_1a
procedure {:inline 1} acceptor1_ingress_handle_1a()
	modifies acceptor1_hdr.paxos.acptid, acceptor1_hdr.paxos.msgtype, acceptor1_hdr.paxos.paxosval, acceptor1_hdr.paxos.vrnd, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_index0;
{
    acceptor1_hdr.paxos.msgtype := 1bv16;
    // acceptor1_read
    acceptor1_hdr.paxos.vrnd := acceptor1_ingress_registerVRound.read(acceptor1_ingress_registerVRound, acceptor1_hdr.paxos.inst);
    // acceptor1_read
    acceptor1_hdr.paxos.paxosval := acceptor1_ingress_registerValue.read(acceptor1_ingress_registerValue, acceptor1_hdr.paxos.inst);
    // acceptor1_read
    acceptor1_hdr.paxos.acptid := acceptor1_ingress_registerAcceptorID.read(acceptor1_ingress_registerAcceptorID, 0bv32);
    // acceptor1_write
    acceptor1_ingress_registerRound__next_write_site := 1;
    call acceptor1_ingress_registerRound.write(acceptor1_hdr.paxos.inst, acceptor1_hdr.paxos.rnd);
}

// acceptor1_Action acceptor1_ingress_handle_2a
procedure {:inline 1} acceptor1_ingress_handle_2a()
	modifies acceptor1_hdr.paxos.acptid, acceptor1_hdr.paxos.msgtype, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_index0, acceptor1_ingress_registerVRound, acceptor1_ingress_registerVRound__last0_old_value, acceptor1_ingress_registerVRound__last0_value, acceptor1_ingress_registerVRound__last_index, acceptor1_ingress_registerVRound__last_old_value, acceptor1_ingress_registerVRound__last_value, acceptor1_ingress_registerVRound__last_write_site, acceptor1_ingress_registerVRound__next_write_site, acceptor1_ingress_registerVRound__wrote_any, acceptor1_ingress_registerVRound__wrote_index0, acceptor1_ingress_registerValue, acceptor1_ingress_registerValue__last0_old_value, acceptor1_ingress_registerValue__last0_value, acceptor1_ingress_registerValue__last_index, acceptor1_ingress_registerValue__last_old_value, acceptor1_ingress_registerValue__last_value, acceptor1_ingress_registerValue__last_write_site, acceptor1_ingress_registerValue__next_write_site, acceptor1_ingress_registerValue__wrote_any, acceptor1_ingress_registerValue__wrote_index0;
{
    acceptor1_hdr.paxos.msgtype := 3bv16;
    // acceptor1_read
    acceptor1_hdr.paxos.acptid := acceptor1_ingress_registerAcceptorID.read(acceptor1_ingress_registerAcceptorID, 0bv32);
    // acceptor1_write
    acceptor1_ingress_registerRound__next_write_site := 2;
    call acceptor1_ingress_registerRound.write(acceptor1_hdr.paxos.inst, acceptor1_hdr.paxos.rnd);
    // acceptor1_write
    acceptor1_ingress_registerVRound__next_write_site := 1;
    call acceptor1_ingress_registerVRound.write(acceptor1_hdr.paxos.inst, acceptor1_hdr.paxos.rnd);
    // acceptor1_write
    acceptor1_ingress_registerValue__next_write_site := 1;
    call acceptor1_ingress_registerValue.write(acceptor1_hdr.paxos.inst, acceptor1_hdr.paxos.paxosval);
}

// acceptor1_Action acceptor1_ingress_handle_arp_reply
procedure {:inline 1} acceptor1_ingress_handle_arp_reply()
{
}

// acceptor1_Action acceptor1_ingress_handle_arp_request
procedure {:inline 1} acceptor1_ingress_handle_arp_request()
	modifies acceptor1_forward, acceptor1_hdr.arp.op, acceptor1_hdr.arp.sha, acceptor1_hdr.arp.spa, acceptor1_hdr.arp.tha, acceptor1_hdr.arp.tpa, acceptor1_hdr.ethernet.dstAddr, acceptor1_hdr.ethernet.srcAddr, acceptor1_standard_metadata.egress_port, acceptor1_standard_metadata.egress_spec;
{
    acceptor1_hdr.ethernet.dstAddr := acceptor1_hdr.ethernet.srcAddr;
    // acceptor1_read
    acceptor1_hdr.ethernet.srcAddr := acceptor1_ingress_my_mac_address.read(acceptor1_ingress_my_mac_address, 0bv32);
    acceptor1_hdr.arp.op := 2bv16;
    acceptor1_hdr.arp.tha := acceptor1_hdr.arp.sha;
    acceptor1_hdr.arp.tpa := acceptor1_hdr.arp.spa;
    // acceptor1_read
    acceptor1_hdr.arp.sha := acceptor1_ingress_my_mac_address.read(acceptor1_ingress_my_mac_address, 0bv32);
    // acceptor1_read
    acceptor1_hdr.arp.spa := acceptor1_ingress_my_ip_address.read(acceptor1_ingress_my_ip_address, 0bv32);
    acceptor1_standard_metadata.egress_spec := acceptor1_standard_metadata.ingress_port;
    acceptor1_standard_metadata.egress_port := acceptor1_standard_metadata.ingress_port;
    acceptor1_forward := true;
}

// acceptor1_Action acceptor1_ingress_handle_icmp_reply
procedure {:inline 1} acceptor1_ingress_handle_icmp_reply()
{
}

// acceptor1_Action acceptor1_ingress_handle_icmp_request
procedure {:inline 1} acceptor1_ingress_handle_icmp_request()
	modifies acceptor1_hdr.ethernet.dstAddr, acceptor1_hdr.ethernet.srcAddr, acceptor1_hdr.icmp.hdrChecksum, acceptor1_hdr.icmp.icmpType, acceptor1_hdr.ipv4.dstAddr, acceptor1_hdr.ipv4.srcAddr, acceptor1_ipdst_0;
{
    acceptor1_hdr.ethernet.dstAddr := acceptor1_hdr.ethernet.srcAddr;
    // acceptor1_read
    acceptor1_hdr.ethernet.srcAddr := acceptor1_ingress_my_mac_address.read(acceptor1_ingress_my_mac_address, 0bv32);
    acceptor1_ipdst_0 := acceptor1_hdr.ipv4.dstAddr;
    acceptor1_hdr.ipv4.dstAddr := acceptor1_hdr.ipv4.srcAddr;
    acceptor1_hdr.ipv4.srcAddr := acceptor1_ipdst_0;
    acceptor1_hdr.icmp.icmpType := 0bv8;
    acceptor1_hdr.icmp.hdrChecksum := add.bv16(acceptor1_hdr.icmp.hdrChecksum, 2048bv16);
}

// acceptor1_Table acceptor1_ingress_icmp_tbl
procedure {:inline 1} acceptor1_ingress_icmp_tbl.apply()
	modifies acceptor1_drop, acceptor1_hdr.ethernet.dstAddr, acceptor1_hdr.ethernet.srcAddr, acceptor1_hdr.icmp.hdrChecksum, acceptor1_hdr.icmp.icmpType, acceptor1_hdr.ipv4.dstAddr, acceptor1_hdr.ipv4.srcAddr, acceptor1_ingress_icmp_tbl.action_run, acceptor1_ingress_icmp_tbl.hit, acceptor1_ipdst_0;
{
    acceptor1_hdr.icmp.icmpType := acceptor1_hdr.icmp.icmpType;
    acceptor1_ingress_icmp_tbl.hit := false;
    goto acceptor1_action_ingress_handle_icmp_request, acceptor1_action_ingress_handle_icmp_reply, acceptor1_action_drop_3;

    acceptor1_action_ingress_handle_icmp_request:
    assume acceptor1_ingress_icmp_tbl.action_run == acceptor1_ingress_icmp_tbl.action.ingress_handle_icmp_request;
    call acceptor1_ingress_handle_icmp_request();
    goto acceptor1_Exit;

    acceptor1_action_ingress_handle_icmp_reply:
    assume acceptor1_ingress_icmp_tbl.action_run == acceptor1_ingress_icmp_tbl.action.ingress_handle_icmp_reply;
    call acceptor1_ingress_handle_icmp_reply();
    goto acceptor1_Exit;

    acceptor1_action_drop_3:
    assume acceptor1_ingress_icmp_tbl.action_run == acceptor1_ingress_icmp_tbl.action.drop_3;
    call acceptor1_drop_3();
    goto acceptor1_Exit;

    acceptor1_Exit:
}
function {:inline true}acceptor1_ingress_learner_address.read(acceptor1_reg:[bv32]bv32, acceptor1_index:bv32)returns (bv32) {acceptor1_reg[acceptor1_index]}
procedure {:inline 1} acceptor1_ingress_learner_address.write(acceptor1_index:bv32, acceptor1_value:bv32)
	modifies acceptor1_ingress_learner_address, acceptor1_ingress_learner_address__last0_old_value, acceptor1_ingress_learner_address__last0_value, acceptor1_ingress_learner_address__last_index, acceptor1_ingress_learner_address__last_old_value, acceptor1_ingress_learner_address__last_value, acceptor1_ingress_learner_address__last_write_site, acceptor1_ingress_learner_address__wrote_any, acceptor1_ingress_learner_address__wrote_index0;
{
    acceptor1_ingress_learner_address__last_old_value := acceptor1_ingress_learner_address[acceptor1_index];
    acceptor1_ingress_learner_address[acceptor1_index] := acceptor1_value;
    acceptor1_ingress_learner_address__last_index := acceptor1_index;
    acceptor1_ingress_learner_address__last_value := acceptor1_value;
    acceptor1_ingress_learner_address__last_write_site := acceptor1_ingress_learner_address__next_write_site;
    acceptor1_ingress_learner_address__wrote_any := true;
    if (acceptor1_index == 0bv32) {
        acceptor1_ingress_learner_address__wrote_index0 := true;
        acceptor1_ingress_learner_address__last0_old_value := acceptor1_ingress_learner_address__last_old_value;
        acceptor1_ingress_learner_address__last0_value := acceptor1_value;
    }
}
function {:inline true}acceptor1_ingress_learner_mac_address.read(acceptor1_reg:[bv32]bv48, acceptor1_index:bv32)returns (bv48) {acceptor1_reg[acceptor1_index]}
procedure {:inline 1} acceptor1_ingress_learner_mac_address.write(acceptor1_index:bv32, acceptor1_value:bv48)
	modifies acceptor1_ingress_learner_mac_address, acceptor1_ingress_learner_mac_address__last0_old_value, acceptor1_ingress_learner_mac_address__last0_value, acceptor1_ingress_learner_mac_address__last_index, acceptor1_ingress_learner_mac_address__last_old_value, acceptor1_ingress_learner_mac_address__last_value, acceptor1_ingress_learner_mac_address__last_write_site, acceptor1_ingress_learner_mac_address__wrote_any, acceptor1_ingress_learner_mac_address__wrote_index0;
{
    acceptor1_ingress_learner_mac_address__last_old_value := acceptor1_ingress_learner_mac_address[acceptor1_index];
    acceptor1_ingress_learner_mac_address[acceptor1_index] := acceptor1_value;
    acceptor1_ingress_learner_mac_address__last_index := acceptor1_index;
    acceptor1_ingress_learner_mac_address__last_value := acceptor1_value;
    acceptor1_ingress_learner_mac_address__last_write_site := acceptor1_ingress_learner_mac_address__next_write_site;
    acceptor1_ingress_learner_mac_address__wrote_any := true;
    if (acceptor1_index == 0bv32) {
        acceptor1_ingress_learner_mac_address__wrote_index0 := true;
        acceptor1_ingress_learner_mac_address__last0_old_value := acceptor1_ingress_learner_mac_address__last_old_value;
        acceptor1_ingress_learner_mac_address__last0_value := acceptor1_value;
    }
}
function {:inline true}acceptor1_ingress_my_ip_address.read(acceptor1_reg:[bv32]bv32, acceptor1_index:bv32)returns (bv32) {acceptor1_reg[acceptor1_index]}
procedure {:inline 1} acceptor1_ingress_my_ip_address.write(acceptor1_index:bv32, acceptor1_value:bv32)
	modifies acceptor1_ingress_my_ip_address, acceptor1_ingress_my_ip_address__last0_old_value, acceptor1_ingress_my_ip_address__last0_value, acceptor1_ingress_my_ip_address__last_index, acceptor1_ingress_my_ip_address__last_old_value, acceptor1_ingress_my_ip_address__last_value, acceptor1_ingress_my_ip_address__last_write_site, acceptor1_ingress_my_ip_address__wrote_any, acceptor1_ingress_my_ip_address__wrote_index0;
{
    acceptor1_ingress_my_ip_address__last_old_value := acceptor1_ingress_my_ip_address[acceptor1_index];
    acceptor1_ingress_my_ip_address[acceptor1_index] := acceptor1_value;
    acceptor1_ingress_my_ip_address__last_index := acceptor1_index;
    acceptor1_ingress_my_ip_address__last_value := acceptor1_value;
    acceptor1_ingress_my_ip_address__last_write_site := acceptor1_ingress_my_ip_address__next_write_site;
    acceptor1_ingress_my_ip_address__wrote_any := true;
    if (acceptor1_index == 0bv32) {
        acceptor1_ingress_my_ip_address__wrote_index0 := true;
        acceptor1_ingress_my_ip_address__last0_old_value := acceptor1_ingress_my_ip_address__last_old_value;
        acceptor1_ingress_my_ip_address__last0_value := acceptor1_value;
    }
}
function {:inline true}acceptor1_ingress_my_mac_address.read(acceptor1_reg:[bv32]bv48, acceptor1_index:bv32)returns (bv48) {acceptor1_reg[acceptor1_index]}
procedure {:inline 1} acceptor1_ingress_my_mac_address.write(acceptor1_index:bv32, acceptor1_value:bv48)
	modifies acceptor1_ingress_my_mac_address, acceptor1_ingress_my_mac_address__last0_old_value, acceptor1_ingress_my_mac_address__last0_value, acceptor1_ingress_my_mac_address__last_index, acceptor1_ingress_my_mac_address__last_old_value, acceptor1_ingress_my_mac_address__last_value, acceptor1_ingress_my_mac_address__last_write_site, acceptor1_ingress_my_mac_address__wrote_any, acceptor1_ingress_my_mac_address__wrote_index0;
{
    acceptor1_ingress_my_mac_address__last_old_value := acceptor1_ingress_my_mac_address[acceptor1_index];
    acceptor1_ingress_my_mac_address[acceptor1_index] := acceptor1_value;
    acceptor1_ingress_my_mac_address__last_index := acceptor1_index;
    acceptor1_ingress_my_mac_address__last_value := acceptor1_value;
    acceptor1_ingress_my_mac_address__last_write_site := acceptor1_ingress_my_mac_address__next_write_site;
    acceptor1_ingress_my_mac_address__wrote_any := true;
    if (acceptor1_index == 0bv32) {
        acceptor1_ingress_my_mac_address__wrote_index0 := true;
        acceptor1_ingress_my_mac_address__last0_old_value := acceptor1_ingress_my_mac_address__last_old_value;
        acceptor1_ingress_my_mac_address__last0_value := acceptor1_value;
    }
}

// acceptor1_Action acceptor1_ingress_read_round
procedure {:inline 1} acceptor1_ingress_read_round()
	modifies acceptor1_meta.paxos_metadata.round;
{
    // acceptor1_read
    acceptor1_meta.paxos_metadata.round := acceptor1_ingress_registerRound.read(acceptor1_ingress_registerRound, acceptor1_hdr.paxos.inst);
}
function {:inline true}acceptor1_ingress_registerAcceptorID.read(acceptor1_reg:[bv32]bv16, acceptor1_index:bv32)returns (bv16) {acceptor1_reg[acceptor1_index]}
procedure {:inline 1} acceptor1_ingress_registerAcceptorID.write(acceptor1_index:bv32, acceptor1_value:bv16)
	modifies acceptor1_ingress_registerAcceptorID, acceptor1_ingress_registerAcceptorID__last0_old_value, acceptor1_ingress_registerAcceptorID__last0_value, acceptor1_ingress_registerAcceptorID__last_index, acceptor1_ingress_registerAcceptorID__last_old_value, acceptor1_ingress_registerAcceptorID__last_value, acceptor1_ingress_registerAcceptorID__last_write_site, acceptor1_ingress_registerAcceptorID__wrote_any, acceptor1_ingress_registerAcceptorID__wrote_index0;
{
    acceptor1_ingress_registerAcceptorID__last_old_value := acceptor1_ingress_registerAcceptorID[acceptor1_index];
    acceptor1_ingress_registerAcceptorID[acceptor1_index] := acceptor1_value;
    acceptor1_ingress_registerAcceptorID__last_index := acceptor1_index;
    acceptor1_ingress_registerAcceptorID__last_value := acceptor1_value;
    acceptor1_ingress_registerAcceptorID__last_write_site := acceptor1_ingress_registerAcceptorID__next_write_site;
    acceptor1_ingress_registerAcceptorID__wrote_any := true;
    if (acceptor1_index == 0bv32) {
        acceptor1_ingress_registerAcceptorID__wrote_index0 := true;
        acceptor1_ingress_registerAcceptorID__last0_old_value := acceptor1_ingress_registerAcceptorID__last_old_value;
        acceptor1_ingress_registerAcceptorID__last0_value := acceptor1_value;
    }
}
function {:inline true}acceptor1_ingress_registerRound.read(acceptor1_reg:[bv32]bv16, acceptor1_index:bv32)returns (bv16) {acceptor1_reg[acceptor1_index]}
procedure {:inline 1} acceptor1_ingress_registerRound.write(acceptor1_index:bv32, acceptor1_value:bv16)
	modifies acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_index0;
{
    acceptor1_ingress_registerRound__last_old_value := acceptor1_ingress_registerRound[acceptor1_index];
    acceptor1_ingress_registerRound[acceptor1_index] := acceptor1_value;
    acceptor1_ingress_registerRound__last_index := acceptor1_index;
    acceptor1_ingress_registerRound__last_value := acceptor1_value;
    acceptor1_ingress_registerRound__last_write_site := acceptor1_ingress_registerRound__next_write_site;
    acceptor1_ingress_registerRound__wrote_any := true;
    if (acceptor1_index == 0bv32) {
        acceptor1_ingress_registerRound__wrote_index0 := true;
        acceptor1_ingress_registerRound__last0_old_value := acceptor1_ingress_registerRound__last_old_value;
        acceptor1_ingress_registerRound__last0_value := acceptor1_value;
    }
}
function {:inline true}acceptor1_ingress_registerVRound.read(acceptor1_reg:[bv32]bv16, acceptor1_index:bv32)returns (bv16) {acceptor1_reg[acceptor1_index]}
procedure {:inline 1} acceptor1_ingress_registerVRound.write(acceptor1_index:bv32, acceptor1_value:bv16)
	modifies acceptor1_ingress_registerVRound, acceptor1_ingress_registerVRound__last0_old_value, acceptor1_ingress_registerVRound__last0_value, acceptor1_ingress_registerVRound__last_index, acceptor1_ingress_registerVRound__last_old_value, acceptor1_ingress_registerVRound__last_value, acceptor1_ingress_registerVRound__last_write_site, acceptor1_ingress_registerVRound__wrote_any, acceptor1_ingress_registerVRound__wrote_index0;
{
    acceptor1_ingress_registerVRound__last_old_value := acceptor1_ingress_registerVRound[acceptor1_index];
    acceptor1_ingress_registerVRound[acceptor1_index] := acceptor1_value;
    acceptor1_ingress_registerVRound__last_index := acceptor1_index;
    acceptor1_ingress_registerVRound__last_value := acceptor1_value;
    acceptor1_ingress_registerVRound__last_write_site := acceptor1_ingress_registerVRound__next_write_site;
    acceptor1_ingress_registerVRound__wrote_any := true;
    if (acceptor1_index == 0bv32) {
        acceptor1_ingress_registerVRound__wrote_index0 := true;
        acceptor1_ingress_registerVRound__last0_old_value := acceptor1_ingress_registerVRound__last_old_value;
        acceptor1_ingress_registerVRound__last0_value := acceptor1_value;
    }
}
function {:inline true}acceptor1_ingress_registerValue.read(acceptor1_reg:[bv32]bv256, acceptor1_index:bv32)returns (bv256) {acceptor1_reg[acceptor1_index]}
procedure {:inline 1} acceptor1_ingress_registerValue.write(acceptor1_index:bv32, acceptor1_value:bv256)
	modifies acceptor1_ingress_registerValue, acceptor1_ingress_registerValue__last0_old_value, acceptor1_ingress_registerValue__last0_value, acceptor1_ingress_registerValue__last_index, acceptor1_ingress_registerValue__last_old_value, acceptor1_ingress_registerValue__last_value, acceptor1_ingress_registerValue__last_write_site, acceptor1_ingress_registerValue__wrote_any, acceptor1_ingress_registerValue__wrote_index0;
{
    acceptor1_ingress_registerValue__last_old_value := acceptor1_ingress_registerValue[acceptor1_index];
    acceptor1_ingress_registerValue[acceptor1_index] := acceptor1_value;
    acceptor1_ingress_registerValue__last_index := acceptor1_index;
    acceptor1_ingress_registerValue__last_value := acceptor1_value;
    acceptor1_ingress_registerValue__last_write_site := acceptor1_ingress_registerValue__next_write_site;
    acceptor1_ingress_registerValue__wrote_any := true;
    if (acceptor1_index == 0bv32) {
        acceptor1_ingress_registerValue__wrote_index0 := true;
        acceptor1_ingress_registerValue__last0_old_value := acceptor1_ingress_registerValue__last_old_value;
        acceptor1_ingress_registerValue__last0_value := acceptor1_value;
    }
}

// acceptor1_Table acceptor1_ingress_transport_tbl
procedure {:inline 1} acceptor1_ingress_transport_tbl.apply()
	modifies acceptor1_drop, acceptor1_forward, acceptor1_hdr.ipv4.dstAddr, acceptor1_hdr.udp.dstPort, acceptor1_ingress_transport_tbl.action_run, acceptor1_ingress_transport_tbl.hit, acceptor1_standard_metadata.egress_port, acceptor1_standard_metadata.egress_spec;
{
    acceptor1_hdr.ipv4.dstAddr := acceptor1_hdr.ipv4.dstAddr;
    acceptor1_ingress_transport_tbl.hit := false;
    goto acceptor1_action_drop_1, acceptor1_action_ingress_forward;

    acceptor1_action_drop_1:
    assume acceptor1_ingress_transport_tbl.action_run == acceptor1_ingress_transport_tbl.action.drop_1;
    call acceptor1_drop_1();
    goto acceptor1_Exit;

    acceptor1_action_ingress_forward:
    assume acceptor1_ingress_transport_tbl.action_run == acceptor1_ingress_transport_tbl.action.ingress_forward;
    call acceptor1_ingress_forward(acceptor1_ingress_transport_tbl.ingress_forward.port, acceptor1_ingress_transport_tbl.ingress_forward.udp_dst);
    goto acceptor1_Exit;

    acceptor1_Exit:
}
procedure {:inline 1} acceptor1_main()
	modifies acceptor1_drop, acceptor1_egress_place_holder_table.hit, acceptor1_forward, acceptor1_hdr.arp.op, acceptor1_hdr.arp.sha, acceptor1_hdr.arp.spa, acceptor1_hdr.arp.tha, acceptor1_hdr.arp.tpa, acceptor1_hdr.ethernet.dstAddr, acceptor1_hdr.ethernet.srcAddr, acceptor1_hdr.icmp.hdrChecksum, acceptor1_hdr.icmp.icmpType, acceptor1_hdr.ipv4.dstAddr, acceptor1_hdr.ipv4.hdrChecksum, acceptor1_hdr.ipv4.srcAddr, acceptor1_hdr.paxos.acptid, acceptor1_hdr.paxos.msgtype, acceptor1_hdr.paxos.paxosval, acceptor1_hdr.paxos.vrnd, acceptor1_hdr.udp.dstPort, acceptor1_ingress_acceptor_tbl.action_run, acceptor1_ingress_acceptor_tbl.hit, acceptor1_ingress_arp_tbl.action_run, acceptor1_ingress_arp_tbl.hit, acceptor1_ingress_icmp_tbl.action_run, acceptor1_ingress_icmp_tbl.hit, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_index0, acceptor1_ingress_registerVRound, acceptor1_ingress_registerVRound__last0_old_value, acceptor1_ingress_registerVRound__last0_value, acceptor1_ingress_registerVRound__last_index, acceptor1_ingress_registerVRound__last_old_value, acceptor1_ingress_registerVRound__last_value, acceptor1_ingress_registerVRound__last_write_site, acceptor1_ingress_registerVRound__next_write_site, acceptor1_ingress_registerVRound__wrote_any, acceptor1_ingress_registerVRound__wrote_index0, acceptor1_ingress_registerValue, acceptor1_ingress_registerValue__last0_old_value, acceptor1_ingress_registerValue__last0_value, acceptor1_ingress_registerValue__last_index, acceptor1_ingress_registerValue__last_old_value, acceptor1_ingress_registerValue__last_value, acceptor1_ingress_registerValue__last_write_site, acceptor1_ingress_registerValue__next_write_site, acceptor1_ingress_registerValue__wrote_any, acceptor1_ingress_registerValue__wrote_index0, acceptor1_ingress_transport_tbl.action_run, acceptor1_ingress_transport_tbl.hit, acceptor1_ipdst_0, acceptor1_isValid, acceptor1_meta.paxos_metadata.round, acceptor1_p4b_checksum_updated, acceptor1_standard_metadata.egress_port, acceptor1_standard_metadata.egress_spec;
{
    call acceptor1_TopParser();
    call acceptor1_verifyChecksum();
    call acceptor1_ingress();
    call acceptor1_egress();
    call acceptor1_computeChecksum();
    if(acceptor1_forward == false){
        acceptor1_drop := true;
    }
}
procedure acceptor1_mainProcedure()
	modifies acceptor1_drop, acceptor1_egress_place_holder_table.hit, acceptor1_forward, acceptor1_hdr.arp.op, acceptor1_hdr.arp.sha, acceptor1_hdr.arp.spa, acceptor1_hdr.arp.tha, acceptor1_hdr.arp.tpa, acceptor1_hdr.ethernet.dstAddr, acceptor1_hdr.ethernet.srcAddr, acceptor1_hdr.icmp.hdrChecksum, acceptor1_hdr.icmp.icmpType, acceptor1_hdr.ipv4.dstAddr, acceptor1_hdr.ipv4.hdrChecksum, acceptor1_hdr.ipv4.srcAddr, acceptor1_hdr.paxos.acptid, acceptor1_hdr.paxos.msgtype, acceptor1_hdr.paxos.paxosval, acceptor1_hdr.paxos.vrnd, acceptor1_hdr.udp.dstPort, acceptor1_ingress_acceptor_tbl.action_run, acceptor1_ingress_acceptor_tbl.hit, acceptor1_ingress_arp_tbl.action_run, acceptor1_ingress_arp_tbl.hit, acceptor1_ingress_icmp_tbl.action_run, acceptor1_ingress_icmp_tbl.hit, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_index0, acceptor1_ingress_registerVRound, acceptor1_ingress_registerVRound__last0_old_value, acceptor1_ingress_registerVRound__last0_value, acceptor1_ingress_registerVRound__last_index, acceptor1_ingress_registerVRound__last_old_value, acceptor1_ingress_registerVRound__last_value, acceptor1_ingress_registerVRound__last_write_site, acceptor1_ingress_registerVRound__next_write_site, acceptor1_ingress_registerVRound__wrote_any, acceptor1_ingress_registerVRound__wrote_index0, acceptor1_ingress_registerValue, acceptor1_ingress_registerValue__last0_old_value, acceptor1_ingress_registerValue__last0_value, acceptor1_ingress_registerValue__last_index, acceptor1_ingress_registerValue__last_old_value, acceptor1_ingress_registerValue__last_value, acceptor1_ingress_registerValue__last_write_site, acceptor1_ingress_registerValue__next_write_site, acceptor1_ingress_registerValue__wrote_any, acceptor1_ingress_registerValue__wrote_index0, acceptor1_ingress_transport_tbl.action_run, acceptor1_ingress_transport_tbl.hit, acceptor1_ipdst_0, acceptor1_isValid, acceptor1_meta.paxos_metadata.round, acceptor1_p4b_checksum_error, acceptor1_p4b_checksum_updated, acceptor1_p4b_checksum_verified, acceptor1_p4b_clone_e2e, acceptor1_p4b_clone_i2e, acceptor1_p4b_clone_i2i, acceptor1_p4b_digest, acceptor1_p4b_recirculate, acceptor1_standard_metadata.egress_port, acceptor1_standard_metadata.egress_spec;
{
    acceptor1_p4b_checksum_error := false;
    acceptor1_p4b_checksum_updated := false;
    acceptor1_p4b_checksum_verified := false;
    acceptor1_p4b_digest := false;
    acceptor1_p4b_recirculate := false;
    acceptor1_p4b_clone_i2i := false;
    acceptor1_p4b_clone_e2e := false;
    acceptor1_p4b_clone_i2e := false;
    call acceptor1_main();
}
procedure acceptor1_mark_to_drop();
    ensures acceptor1_drop==true;
	modifies acceptor1_drop;
procedure acceptor1_packet.emit(acceptor1_arg0:acceptor1_Ref);
procedure acceptor1_packet_in.extract(acceptor1_header:acceptor1_Ref);
    ensures (acceptor1_isValid[acceptor1_header] == true);
	modifies acceptor1_isValid;
procedure acceptor1_reject();
    ensures acceptor1_drop==true;
	modifies acceptor1_drop;
procedure {:inline 1} acceptor1_setInvalid(acceptor1_header:acceptor1_Ref);
    ensures (acceptor1_isValid[acceptor1_header] == false);
	modifies acceptor1_isValid;
procedure {:inline 1} acceptor1_setValid(acceptor1_header:acceptor1_Ref);

// acceptor1_Control acceptor1_verifyChecksum
procedure {:inline 1} acceptor1_verifyChecksum()
{
}
// ===== END NODE acceptor1 =====

// ===== BEGIN NODE acceptor2 (prefixed) =====
type acceptor2_Ref;
type acceptor2_error=bv1;
type acceptor2_HeaderStack = [int]acceptor2_Ref;
var acceptor2_last:[acceptor2_HeaderStack]acceptor2_Ref;
var acceptor2_forward:bool;
var acceptor2_isValid:[acceptor2_Ref]bool;
var acceptor2_emit:[acceptor2_Ref]bool;
var acceptor2_stack.index:[acceptor2_HeaderStack]int;
var acceptor2_size:[acceptor2_HeaderStack]int;
var acceptor2_drop:bool;
var acceptor2_p4b_clone_i2e:bool;
var acceptor2_p4b_clone_e2e:bool;
var acceptor2_p4b_clone_i2i:bool;
var acceptor2_p4b_recirculate:bool;
var acceptor2_p4b_digest:bool;
var acceptor2_p4b_checksum_verified:bool;
var acceptor2_p4b_checksum_updated:bool;
var acceptor2_p4b_checksum_error:bool;

// acceptor2_Struct acceptor2_standard_metadata_t
type acceptor2_standard_metadata_t;
var acceptor2_standard_metadata.ingress_port:bv9;
var acceptor2_standard_metadata.egress_spec:bv9;
var acceptor2_standard_metadata.egress_port:bv9;
var acceptor2_standard_metadata.instance_type:bv32;
var acceptor2_standard_metadata.packet_length:bv32;
var acceptor2_standard_metadata.enq_timestamp:bv32;
var acceptor2_standard_metadata.enq_qdepth:bv19;
var acceptor2_standard_metadata.deq_timedelta:bv32;
var acceptor2_standard_metadata.deq_qdepth:bv19;
var acceptor2_standard_metadata.ingress_global_timestamp:bv48;
var acceptor2_standard_metadata.egress_global_timestamp:bv48;
var acceptor2_standard_metadata.mcast_grp:bv16;
var acceptor2_standard_metadata.egress_rid:bv16;
var acceptor2_standard_metadata.checksum_error:bv1;
var acceptor2_standard_metadata.parser_error:acceptor2_error;
var acceptor2_standard_metadata.priority:bv3;
type acceptor2_CounterType = int;
type acceptor2_MeterType = int;
type acceptor2_HashAlgorithm = int;
type acceptor2_CloneType = int;
type acceptor2_EthernetAddress = bv48;
type acceptor2_IPv4Address = bv32;
type acceptor2_PortId = bv4;
type acceptor2_ethernet_t;
type acceptor2_arp_t;
type acceptor2_ipv4_t;
type acceptor2_icmp_t;
type acceptor2_udp_t;
type acceptor2_paxos_t;

// acceptor2_Struct acceptor2_headers
var acceptor2_hdr:acceptor2_Ref;

// acceptor2_Header acceptor2_ethernet_t
var acceptor2_hdr.ethernet:acceptor2_Ref;
var acceptor2_hdr.ethernet.valid:bool;
var acceptor2_hdr.ethernet.dstAddr:acceptor2_EthernetAddress;
var acceptor2_hdr.ethernet.srcAddr:acceptor2_EthernetAddress;
var acceptor2_hdr.ethernet.etherType:bv16;

// acceptor2_Header acceptor2_arp_t
var acceptor2_hdr.arp:acceptor2_Ref;
var acceptor2_hdr.arp.valid:bool;
var acceptor2_hdr.arp.hrd:bv16;
var acceptor2_hdr.arp.pro:bv16;
var acceptor2_hdr.arp.hln:bv8;
var acceptor2_hdr.arp.pln:bv8;
var acceptor2_hdr.arp.op:bv16;
var acceptor2_hdr.arp.sha:bv48;
var acceptor2_hdr.arp.spa:bv32;
var acceptor2_hdr.arp.tha:bv48;
var acceptor2_hdr.arp.tpa:bv32;

// acceptor2_Header acceptor2_ipv4_t
var acceptor2_hdr.ipv4:acceptor2_Ref;
var acceptor2_hdr.ipv4.valid:bool;
var acceptor2_hdr.ipv4.version:bv4;
var acceptor2_hdr.ipv4.ihl:bv4;
var acceptor2_hdr.ipv4.diffserv:bv8;
var acceptor2_hdr.ipv4.totalLen:bv16;
var acceptor2_hdr.ipv4.identification:bv16;
var acceptor2_hdr.ipv4.flags:bv3;
var acceptor2_hdr.ipv4.fragOffset:bv13;
var acceptor2_hdr.ipv4.ttl:bv8;
var acceptor2_hdr.ipv4.protocol:bv8;
var acceptor2_hdr.ipv4.hdrChecksum:bv16;
var acceptor2_hdr.ipv4.srcAddr:acceptor2_IPv4Address;
var acceptor2_hdr.ipv4.dstAddr:acceptor2_IPv4Address;

// acceptor2_Header acceptor2_icmp_t
var acceptor2_hdr.icmp:acceptor2_Ref;
var acceptor2_hdr.icmp.valid:bool;
var acceptor2_hdr.icmp.icmpType:bv8;
var acceptor2_hdr.icmp.icmpCode:bv8;
var acceptor2_hdr.icmp.hdrChecksum:bv16;
var acceptor2_hdr.icmp.identifier:bv16;
var acceptor2_hdr.icmp.seqNumber:bv16;
var acceptor2_hdr.icmp.payload:bv256;

// acceptor2_Header acceptor2_udp_t
var acceptor2_hdr.udp:acceptor2_Ref;
var acceptor2_hdr.udp.valid:bool;
var acceptor2_hdr.udp.srcPort:bv16;
var acceptor2_hdr.udp.dstPort:bv16;
var acceptor2_hdr.udp.length_:bv16;
var acceptor2_hdr.udp.checksum:bv16;

// acceptor2_Header acceptor2_paxos_t
var acceptor2_hdr.paxos:acceptor2_Ref;
var acceptor2_hdr.paxos.valid:bool;
var acceptor2_hdr.paxos.msgtype:bv16;
var acceptor2_hdr.paxos.inst:bv32;
var acceptor2_hdr.paxos.rnd:bv16;
var acceptor2_hdr.paxos.vrnd:bv16;
var acceptor2_hdr.paxos.acptid:bv16;
var acceptor2_hdr.paxos.paxoslen:bv32;
var acceptor2_hdr.paxos.paxosval:bv256;

// acceptor2_Struct acceptor2_paxos_metadata_t
type acceptor2_paxos_metadata_t;

// acceptor2_Struct acceptor2_metadata
type acceptor2_metadata;
var acceptor2_meta.paxos_metadata:acceptor2_paxos_metadata_t;
var acceptor2_meta.paxos_metadata.round:bv16;
var acceptor2_meta.paxos_metadata.set_drop:bv1;
var acceptor2_meta.paxos_metadata.ack_count:bv8;
var acceptor2_meta.paxos_metadata.ack_acceptors:bv8;
var acceptor2_meta:acceptor2_metadata;
var acceptor2_standard_metadata:acceptor2_standard_metadata_t;
var acceptor2_ipdst_0:bv32;

// acceptor2_Register acceptor2_ingress_registerAcceptorID
var acceptor2_ingress_registerAcceptorID:[bv32]bv16;
var acceptor2_ingress_registerAcceptorID__last_index:bv32;
var acceptor2_ingress_registerAcceptorID__last_value:bv16;
var acceptor2_ingress_registerAcceptorID__last_old_value:bv16;
var acceptor2_ingress_registerAcceptorID__wrote_any:bool;
var acceptor2_ingress_registerAcceptorID__wrote_index0:bool;
var acceptor2_ingress_registerAcceptorID__last0_old_value:bv16;
var acceptor2_ingress_registerAcceptorID__last0_value:bv16;
var acceptor2_ingress_registerAcceptorID__next_write_site:int;
var acceptor2_ingress_registerAcceptorID__last_write_site:int;
const acceptor2_ingress_registerAcceptorID.size:bv32;
axiom acceptor2_ingress_registerAcceptorID.size == 1bv32;

// acceptor2_Register acceptor2_ingress_registerRound
var acceptor2_ingress_registerRound:[bv32]bv16;
var acceptor2_ingress_registerRound__last_index:bv32;
var acceptor2_ingress_registerRound__last_value:bv16;
var acceptor2_ingress_registerRound__last_old_value:bv16;
var acceptor2_ingress_registerRound__wrote_any:bool;
var acceptor2_ingress_registerRound__wrote_index0:bool;
var acceptor2_ingress_registerRound__last0_old_value:bv16;
var acceptor2_ingress_registerRound__last0_value:bv16;
var acceptor2_ingress_registerRound__next_write_site:int;
var acceptor2_ingress_registerRound__last_write_site:int;
const acceptor2_ingress_registerRound.size:bv32;
axiom acceptor2_ingress_registerRound.size == 65536bv32;

// acceptor2_Register acceptor2_ingress_registerVRound
var acceptor2_ingress_registerVRound:[bv32]bv16;
var acceptor2_ingress_registerVRound__last_index:bv32;
var acceptor2_ingress_registerVRound__last_value:bv16;
var acceptor2_ingress_registerVRound__last_old_value:bv16;
var acceptor2_ingress_registerVRound__wrote_any:bool;
var acceptor2_ingress_registerVRound__wrote_index0:bool;
var acceptor2_ingress_registerVRound__last0_old_value:bv16;
var acceptor2_ingress_registerVRound__last0_value:bv16;
var acceptor2_ingress_registerVRound__next_write_site:int;
var acceptor2_ingress_registerVRound__last_write_site:int;
const acceptor2_ingress_registerVRound.size:bv32;
axiom acceptor2_ingress_registerVRound.size == 65536bv32;

// acceptor2_Register acceptor2_ingress_registerValue
var acceptor2_ingress_registerValue:[bv32]bv256;
var acceptor2_ingress_registerValue__last_index:bv32;
var acceptor2_ingress_registerValue__last_value:bv256;
var acceptor2_ingress_registerValue__last_old_value:bv256;
var acceptor2_ingress_registerValue__wrote_any:bool;
var acceptor2_ingress_registerValue__wrote_index0:bool;
var acceptor2_ingress_registerValue__last0_old_value:bv256;
var acceptor2_ingress_registerValue__last0_value:bv256;
var acceptor2_ingress_registerValue__next_write_site:int;
var acceptor2_ingress_registerValue__last_write_site:int;
const acceptor2_ingress_registerValue.size:bv32;
axiom acceptor2_ingress_registerValue.size == 65536bv32;

// acceptor2_Register acceptor2_ingress_learner_mac_address
var acceptor2_ingress_learner_mac_address:[bv32]bv48;
var acceptor2_ingress_learner_mac_address__last_index:bv32;
var acceptor2_ingress_learner_mac_address__last_value:bv48;
var acceptor2_ingress_learner_mac_address__last_old_value:bv48;
var acceptor2_ingress_learner_mac_address__wrote_any:bool;
var acceptor2_ingress_learner_mac_address__wrote_index0:bool;
var acceptor2_ingress_learner_mac_address__last0_old_value:bv48;
var acceptor2_ingress_learner_mac_address__last0_value:bv48;
var acceptor2_ingress_learner_mac_address__next_write_site:int;
var acceptor2_ingress_learner_mac_address__last_write_site:int;
const acceptor2_ingress_learner_mac_address.size:bv32;
axiom acceptor2_ingress_learner_mac_address.size == 1bv32;

// acceptor2_Register acceptor2_ingress_learner_address
var acceptor2_ingress_learner_address:[bv32]bv32;
var acceptor2_ingress_learner_address__last_index:bv32;
var acceptor2_ingress_learner_address__last_value:bv32;
var acceptor2_ingress_learner_address__last_old_value:bv32;
var acceptor2_ingress_learner_address__wrote_any:bool;
var acceptor2_ingress_learner_address__wrote_index0:bool;
var acceptor2_ingress_learner_address__last0_old_value:bv32;
var acceptor2_ingress_learner_address__last0_value:bv32;
var acceptor2_ingress_learner_address__next_write_site:int;
var acceptor2_ingress_learner_address__last_write_site:int;
const acceptor2_ingress_learner_address.size:bv32;
axiom acceptor2_ingress_learner_address.size == 1bv32;

// acceptor2_Table acceptor2_ingress_acceptor_tbl acceptor2_Actionlist acceptor2_Declaration
type acceptor2_ingress_acceptor_tbl.action;
const unique acceptor2_ingress_acceptor_tbl.action.ingress_handle_1a : acceptor2_ingress_acceptor_tbl.action;
const unique acceptor2_ingress_acceptor_tbl.action.ingress_handle_2a : acceptor2_ingress_acceptor_tbl.action;
const unique acceptor2_ingress_acceptor_tbl.action.ingress_drop : acceptor2_ingress_acceptor_tbl.action;
var acceptor2_ingress_acceptor_tbl.action_run : acceptor2_ingress_acceptor_tbl.action;
var acceptor2_ingress_acceptor_tbl.hit : bool;

// acceptor2_Table acceptor2_ingress_transport_tbl acceptor2_Actionlist acceptor2_Declaration
type acceptor2_ingress_transport_tbl.action;
var acceptor2_ingress_transport_tbl.ingress_forward.port:acceptor2_PortId;
var acceptor2_ingress_transport_tbl.ingress_forward.udp_dst:bv16;
const unique acceptor2_ingress_transport_tbl.action.drop_1 : acceptor2_ingress_transport_tbl.action;
const unique acceptor2_ingress_transport_tbl.action.ingress_forward : acceptor2_ingress_transport_tbl.action;
var acceptor2_ingress_transport_tbl.action_run : acceptor2_ingress_transport_tbl.action;
var acceptor2_ingress_transport_tbl.hit : bool;

// acceptor2_Register acceptor2_ingress_my_mac_address
var acceptor2_ingress_my_mac_address:[bv32]bv48;
var acceptor2_ingress_my_mac_address__last_index:bv32;
var acceptor2_ingress_my_mac_address__last_value:bv48;
var acceptor2_ingress_my_mac_address__last_old_value:bv48;
var acceptor2_ingress_my_mac_address__wrote_any:bool;
var acceptor2_ingress_my_mac_address__wrote_index0:bool;
var acceptor2_ingress_my_mac_address__last0_old_value:bv48;
var acceptor2_ingress_my_mac_address__last0_value:bv48;
var acceptor2_ingress_my_mac_address__next_write_site:int;
var acceptor2_ingress_my_mac_address__last_write_site:int;
const acceptor2_ingress_my_mac_address.size:bv32;
axiom acceptor2_ingress_my_mac_address.size == 1bv32;

// acceptor2_Register acceptor2_ingress_my_ip_address
var acceptor2_ingress_my_ip_address:[bv32]bv32;
var acceptor2_ingress_my_ip_address__last_index:bv32;
var acceptor2_ingress_my_ip_address__last_value:bv32;
var acceptor2_ingress_my_ip_address__last_old_value:bv32;
var acceptor2_ingress_my_ip_address__wrote_any:bool;
var acceptor2_ingress_my_ip_address__wrote_index0:bool;
var acceptor2_ingress_my_ip_address__last0_old_value:bv32;
var acceptor2_ingress_my_ip_address__last0_value:bv32;
var acceptor2_ingress_my_ip_address__next_write_site:int;
var acceptor2_ingress_my_ip_address__last_write_site:int;
const acceptor2_ingress_my_ip_address.size:bv32;
axiom acceptor2_ingress_my_ip_address.size == 1bv32;

// acceptor2_Table acceptor2_ingress_arp_tbl acceptor2_Actionlist acceptor2_Declaration
type acceptor2_ingress_arp_tbl.action;
const unique acceptor2_ingress_arp_tbl.action.ingress_handle_arp_request : acceptor2_ingress_arp_tbl.action;
const unique acceptor2_ingress_arp_tbl.action.ingress_handle_arp_reply : acceptor2_ingress_arp_tbl.action;
const unique acceptor2_ingress_arp_tbl.action.drop_2 : acceptor2_ingress_arp_tbl.action;
var acceptor2_ingress_arp_tbl.action_run : acceptor2_ingress_arp_tbl.action;
var acceptor2_ingress_arp_tbl.hit : bool;


// acceptor2_Table acceptor2_ingress_icmp_tbl acceptor2_Actionlist acceptor2_Declaration
type acceptor2_ingress_icmp_tbl.action;
const unique acceptor2_ingress_icmp_tbl.action.ingress_handle_icmp_request : acceptor2_ingress_icmp_tbl.action;
const unique acceptor2_ingress_icmp_tbl.action.ingress_handle_icmp_reply : acceptor2_ingress_icmp_tbl.action;
const unique acceptor2_ingress_icmp_tbl.action.drop_3 : acceptor2_ingress_icmp_tbl.action;
var acceptor2_ingress_icmp_tbl.action_run : acceptor2_ingress_icmp_tbl.action;
var acceptor2_ingress_icmp_tbl.hit : bool;



// acceptor2_Table acceptor2_egress_place_holder_table acceptor2_Actionlist acceptor2_Declaration
type acceptor2_egress_place_holder_table.action;
const unique acceptor2_egress_place_holder_table.action.NoAction : acceptor2_egress_place_holder_table.action;
var acceptor2_egress_place_holder_table.action_run : acceptor2_egress_place_holder_table.action;
var acceptor2_egress_place_holder_table.hit : bool;



// acceptor2_Action acceptor2_NoAction
procedure {:inline 1} acceptor2_NoAction()
{
}

// acceptor2_Parser acceptor2_TopParser
procedure {:inline 1} acceptor2_TopParser()
	modifies acceptor2_drop, acceptor2_isValid;
{
    goto acceptor2_State$TopParser$start;

        acceptor2_State$TopParser$start:
    call acceptor2_packet_in.extract(acceptor2_hdr.ethernet);
    goto acceptor2_State$TopParser$start$parse_arp_2, acceptor2_State$TopParser$start$parse_ipv4_1, acceptor2_State$TopParser$start$DEFAULT;
    
acceptor2_State$TopParser$start$parse_arp_2:
    assume (acceptor2_hdr.ethernet.etherType == 2054bv16);
    goto acceptor2_State$TopParser$parse_arp;
    
acceptor2_State$TopParser$start$parse_ipv4_1:
    assume (acceptor2_hdr.ethernet.etherType == 2048bv16);
    goto acceptor2_State$TopParser$parse_ipv4;

    acceptor2_State$TopParser$start$DEFAULT:
    assume(!(acceptor2_hdr.ethernet.etherType == 2054bv16)&&!(acceptor2_hdr.ethernet.etherType == 2048bv16));
goto acceptor2_State$reject;

        acceptor2_State$TopParser$parse_arp:
    call acceptor2_packet_in.extract(acceptor2_hdr.arp);
    goto acceptor2_State$accept;

        acceptor2_State$TopParser$parse_ipv4:
    call acceptor2_packet_in.extract(acceptor2_hdr.ipv4);
    goto acceptor2_State$TopParser$parse_ipv4$parse_icmp_3, acceptor2_State$TopParser$parse_ipv4$parse_udp_2, acceptor2_State$TopParser$parse_ipv4$DEFAULT;
    
acceptor2_State$TopParser$parse_ipv4$parse_icmp_3:
    assume (acceptor2_hdr.ipv4.protocol == 1bv8);
    goto acceptor2_State$TopParser$parse_icmp;
    
acceptor2_State$TopParser$parse_ipv4$parse_udp_2:
    assume (acceptor2_hdr.ipv4.protocol == 17bv8);
    goto acceptor2_State$TopParser$parse_udp;

    acceptor2_State$TopParser$parse_ipv4$DEFAULT:
    assume(!(acceptor2_hdr.ipv4.protocol == 1bv8)&&!(acceptor2_hdr.ipv4.protocol == 17bv8));
    goto acceptor2_State$accept;

        acceptor2_State$TopParser$parse_icmp:
    call acceptor2_packet_in.extract(acceptor2_hdr.icmp);
    goto acceptor2_State$accept;

        acceptor2_State$TopParser$parse_udp:
    call acceptor2_packet_in.extract(acceptor2_hdr.udp);
    goto acceptor2_State$TopParser$parse_udp$parse_paxos_2, acceptor2_State$TopParser$parse_udp$DEFAULT;
    
acceptor2_State$TopParser$parse_udp$parse_paxos_2:
    assume (acceptor2_hdr.udp.dstPort == 34952bv16);
    goto acceptor2_State$TopParser$parse_paxos;

    acceptor2_State$TopParser$parse_udp$DEFAULT:
    assume(!(acceptor2_hdr.udp.dstPort == 34952bv16));
    goto acceptor2_State$accept;

        acceptor2_State$TopParser$parse_paxos:
    call acceptor2_packet_in.extract(acceptor2_hdr.paxos);
    goto acceptor2_State$accept;

    acceptor2_State$accept:
    call acceptor2_accept();
    goto acceptor2_Exit;

    acceptor2_State$reject:
    call acceptor2_reject();
    goto acceptor2_Exit;

    acceptor2_Exit:
}
procedure {:inline 1} acceptor2_accept()
{
}

// acceptor2_Control acceptor2_computeChecksum
procedure {:inline 1} acceptor2_computeChecksum()
	modifies acceptor2_hdr.ipv4.hdrChecksum, acceptor2_p4b_checksum_updated;
{
    if (acceptor2_isValid[acceptor2_hdr.ipv4]) {
        acceptor2_p4b_checksum_updated := true;
        havoc acceptor2_hdr.ipv4.hdrChecksum;
    }
}

// acceptor2_Action acceptor2_drop_1
procedure {:inline 1} acceptor2_drop_1()
	modifies acceptor2_drop;
{
    call acceptor2_mark_to_drop();
}

// acceptor2_Action acceptor2_drop_2
procedure {:inline 1} acceptor2_drop_2()
	modifies acceptor2_drop;
{
    call acceptor2_mark_to_drop();
}

// acceptor2_Action acceptor2_drop_3
procedure {:inline 1} acceptor2_drop_3()
	modifies acceptor2_drop;
{
    call acceptor2_mark_to_drop();
}

// acceptor2_Control acceptor2_egress
procedure {:inline 1} acceptor2_egress()
	modifies acceptor2_egress_place_holder_table.hit;
{
    call acceptor2_egress_place_holder_table.apply();
}

// acceptor2_Table acceptor2_egress_place_holder_table
procedure {:inline 1} acceptor2_egress_place_holder_table.apply()
	modifies acceptor2_egress_place_holder_table.hit;
{
    acceptor2_egress_place_holder_table.hit := false;
    goto acceptor2_Exit;

    acceptor2_Exit:
}

// acceptor2_Control acceptor2_ingress
procedure {:inline 1} acceptor2_ingress()
	modifies acceptor2_drop, acceptor2_forward, acceptor2_hdr.arp.op, acceptor2_hdr.arp.sha, acceptor2_hdr.arp.spa, acceptor2_hdr.arp.tha, acceptor2_hdr.arp.tpa, acceptor2_hdr.ethernet.dstAddr, acceptor2_hdr.ethernet.srcAddr, acceptor2_hdr.icmp.hdrChecksum, acceptor2_hdr.icmp.icmpType, acceptor2_hdr.ipv4.dstAddr, acceptor2_hdr.ipv4.srcAddr, acceptor2_hdr.paxos.acptid, acceptor2_hdr.paxos.msgtype, acceptor2_hdr.paxos.paxosval, acceptor2_hdr.paxos.vrnd, acceptor2_hdr.udp.dstPort, acceptor2_ingress_acceptor_tbl.action_run, acceptor2_ingress_acceptor_tbl.hit, acceptor2_ingress_arp_tbl.action_run, acceptor2_ingress_arp_tbl.hit, acceptor2_ingress_icmp_tbl.action_run, acceptor2_ingress_icmp_tbl.hit, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_index0, acceptor2_ingress_registerVRound, acceptor2_ingress_registerVRound__last0_old_value, acceptor2_ingress_registerVRound__last0_value, acceptor2_ingress_registerVRound__last_index, acceptor2_ingress_registerVRound__last_old_value, acceptor2_ingress_registerVRound__last_value, acceptor2_ingress_registerVRound__last_write_site, acceptor2_ingress_registerVRound__next_write_site, acceptor2_ingress_registerVRound__wrote_any, acceptor2_ingress_registerVRound__wrote_index0, acceptor2_ingress_registerValue, acceptor2_ingress_registerValue__last0_old_value, acceptor2_ingress_registerValue__last0_value, acceptor2_ingress_registerValue__last_index, acceptor2_ingress_registerValue__last_old_value, acceptor2_ingress_registerValue__last_value, acceptor2_ingress_registerValue__last_write_site, acceptor2_ingress_registerValue__next_write_site, acceptor2_ingress_registerValue__wrote_any, acceptor2_ingress_registerValue__wrote_index0, acceptor2_ingress_transport_tbl.action_run, acceptor2_ingress_transport_tbl.hit, acceptor2_ipdst_0, acceptor2_meta.paxos_metadata.round, acceptor2_standard_metadata.egress_port, acceptor2_standard_metadata.egress_spec;
{
havoc acceptor2_ipdst_0;
    if(acceptor2_isValid[acceptor2_hdr.arp]){
        call acceptor2_ingress_arp_tbl.apply();
    }
    else{
        if(acceptor2_isValid[acceptor2_hdr.ipv4]){
            if(acceptor2_isValid[acceptor2_hdr.paxos]){
                call acceptor2_ingress_read_round();
                if(buge.bv16(acceptor2_hdr.paxos.rnd, acceptor2_meta.paxos_metadata.round)){
                    // acceptor2_read
                    acceptor2_hdr.paxos.vrnd := acceptor2_ingress_registerVRound.read(acceptor2_ingress_registerVRound, acceptor2_hdr.paxos.inst);
                    assert bule.bv16(acceptor2_hdr.paxos.vrnd, acceptor2_meta.paxos_metadata.round);
                    call acceptor2_ingress_acceptor_tbl.apply();
                    call acceptor2_ingress_transport_tbl.apply();
                }
            }
            else{
                if(acceptor2_isValid[acceptor2_hdr.icmp]){
                    call acceptor2_ingress_icmp_tbl.apply();
                }
            }
        }
    }
}

// acceptor2_Table acceptor2_ingress_acceptor_tbl
procedure {:inline 1} acceptor2_ingress_acceptor_tbl.apply()
	modifies acceptor2_drop, acceptor2_hdr.paxos.acptid, acceptor2_hdr.paxos.msgtype, acceptor2_hdr.paxos.paxosval, acceptor2_hdr.paxos.vrnd, acceptor2_ingress_acceptor_tbl.action_run, acceptor2_ingress_acceptor_tbl.hit, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_index0, acceptor2_ingress_registerVRound, acceptor2_ingress_registerVRound__last0_old_value, acceptor2_ingress_registerVRound__last0_value, acceptor2_ingress_registerVRound__last_index, acceptor2_ingress_registerVRound__last_old_value, acceptor2_ingress_registerVRound__last_value, acceptor2_ingress_registerVRound__last_write_site, acceptor2_ingress_registerVRound__next_write_site, acceptor2_ingress_registerVRound__wrote_any, acceptor2_ingress_registerVRound__wrote_index0, acceptor2_ingress_registerValue, acceptor2_ingress_registerValue__last0_old_value, acceptor2_ingress_registerValue__last0_value, acceptor2_ingress_registerValue__last_index, acceptor2_ingress_registerValue__last_old_value, acceptor2_ingress_registerValue__last_value, acceptor2_ingress_registerValue__last_write_site, acceptor2_ingress_registerValue__next_write_site, acceptor2_ingress_registerValue__wrote_any, acceptor2_ingress_registerValue__wrote_index0;
{
    acceptor2_hdr.paxos.msgtype := acceptor2_hdr.paxos.msgtype;
    acceptor2_ingress_acceptor_tbl.hit := false;
    goto acceptor2_action_ingress_handle_1a, acceptor2_action_ingress_handle_2a, acceptor2_action_ingress_drop;

    acceptor2_action_ingress_handle_1a:
    assume acceptor2_ingress_acceptor_tbl.action_run == acceptor2_ingress_acceptor_tbl.action.ingress_handle_1a;
    call acceptor2_ingress_handle_1a();
    goto acceptor2_Exit;

    acceptor2_action_ingress_handle_2a:
    assume acceptor2_ingress_acceptor_tbl.action_run == acceptor2_ingress_acceptor_tbl.action.ingress_handle_2a;
    call acceptor2_ingress_handle_2a();
    goto acceptor2_Exit;

    acceptor2_action_ingress_drop:
    assume acceptor2_ingress_acceptor_tbl.action_run == acceptor2_ingress_acceptor_tbl.action.ingress_drop;
    call acceptor2_ingress_drop();
    goto acceptor2_Exit;

    acceptor2_Exit:
}

// acceptor2_Table acceptor2_ingress_arp_tbl
procedure {:inline 1} acceptor2_ingress_arp_tbl.apply()
	modifies acceptor2_drop, acceptor2_forward, acceptor2_hdr.arp.op, acceptor2_hdr.arp.sha, acceptor2_hdr.arp.spa, acceptor2_hdr.arp.tha, acceptor2_hdr.arp.tpa, acceptor2_hdr.ethernet.dstAddr, acceptor2_hdr.ethernet.srcAddr, acceptor2_ingress_arp_tbl.action_run, acceptor2_ingress_arp_tbl.hit, acceptor2_standard_metadata.egress_port, acceptor2_standard_metadata.egress_spec;
{
    acceptor2_hdr.arp.op := acceptor2_hdr.arp.op;
    acceptor2_ingress_arp_tbl.hit := false;
    goto acceptor2_action_ingress_handle_arp_request, acceptor2_action_ingress_handle_arp_reply, acceptor2_action_drop_2;

    acceptor2_action_ingress_handle_arp_request:
    assume acceptor2_ingress_arp_tbl.action_run == acceptor2_ingress_arp_tbl.action.ingress_handle_arp_request;
    call acceptor2_ingress_handle_arp_request();
    goto acceptor2_Exit;

    acceptor2_action_ingress_handle_arp_reply:
    assume acceptor2_ingress_arp_tbl.action_run == acceptor2_ingress_arp_tbl.action.ingress_handle_arp_reply;
    call acceptor2_ingress_handle_arp_reply();
    goto acceptor2_Exit;

    acceptor2_action_drop_2:
    assume acceptor2_ingress_arp_tbl.action_run == acceptor2_ingress_arp_tbl.action.drop_2;
    call acceptor2_drop_2();
    goto acceptor2_Exit;

    acceptor2_Exit:
}

// acceptor2_Action acceptor2_ingress_drop
procedure {:inline 1} acceptor2_ingress_drop()
	modifies acceptor2_drop;
{
    call acceptor2_mark_to_drop();
}

// acceptor2_Action acceptor2_ingress_forward
procedure {:inline 1} acceptor2_ingress_forward(acceptor2_port:acceptor2_PortId, acceptor2_udp_dst:bv16)
	modifies acceptor2_forward, acceptor2_hdr.udp.dstPort, acceptor2_standard_metadata.egress_port, acceptor2_standard_metadata.egress_spec;
{
    acceptor2_standard_metadata.egress_spec := 0bv5++acceptor2_port;
    acceptor2_standard_metadata.egress_port := 0bv5++acceptor2_port;
    acceptor2_forward := true;
    acceptor2_hdr.udp.dstPort := acceptor2_udp_dst;
}

// acceptor2_Action acceptor2_ingress_handle_1a
procedure {:inline 1} acceptor2_ingress_handle_1a()
	modifies acceptor2_hdr.paxos.acptid, acceptor2_hdr.paxos.msgtype, acceptor2_hdr.paxos.paxosval, acceptor2_hdr.paxos.vrnd, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_index0;
{
    acceptor2_hdr.paxos.msgtype := 1bv16;
    // acceptor2_read
    acceptor2_hdr.paxos.vrnd := acceptor2_ingress_registerVRound.read(acceptor2_ingress_registerVRound, acceptor2_hdr.paxos.inst);
    // acceptor2_read
    acceptor2_hdr.paxos.paxosval := acceptor2_ingress_registerValue.read(acceptor2_ingress_registerValue, acceptor2_hdr.paxos.inst);
    // acceptor2_read
    acceptor2_hdr.paxos.acptid := acceptor2_ingress_registerAcceptorID.read(acceptor2_ingress_registerAcceptorID, 0bv32);
    // acceptor2_write
    acceptor2_ingress_registerRound__next_write_site := 1;
    call acceptor2_ingress_registerRound.write(acceptor2_hdr.paxos.inst, acceptor2_hdr.paxos.rnd);
}

// acceptor2_Action acceptor2_ingress_handle_2a
procedure {:inline 1} acceptor2_ingress_handle_2a()
	modifies acceptor2_hdr.paxos.acptid, acceptor2_hdr.paxos.msgtype, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_index0, acceptor2_ingress_registerVRound, acceptor2_ingress_registerVRound__last0_old_value, acceptor2_ingress_registerVRound__last0_value, acceptor2_ingress_registerVRound__last_index, acceptor2_ingress_registerVRound__last_old_value, acceptor2_ingress_registerVRound__last_value, acceptor2_ingress_registerVRound__last_write_site, acceptor2_ingress_registerVRound__next_write_site, acceptor2_ingress_registerVRound__wrote_any, acceptor2_ingress_registerVRound__wrote_index0, acceptor2_ingress_registerValue, acceptor2_ingress_registerValue__last0_old_value, acceptor2_ingress_registerValue__last0_value, acceptor2_ingress_registerValue__last_index, acceptor2_ingress_registerValue__last_old_value, acceptor2_ingress_registerValue__last_value, acceptor2_ingress_registerValue__last_write_site, acceptor2_ingress_registerValue__next_write_site, acceptor2_ingress_registerValue__wrote_any, acceptor2_ingress_registerValue__wrote_index0;
{
    acceptor2_hdr.paxos.msgtype := 3bv16;
    // acceptor2_read
    acceptor2_hdr.paxos.acptid := acceptor2_ingress_registerAcceptorID.read(acceptor2_ingress_registerAcceptorID, 0bv32);
    // acceptor2_write
    acceptor2_ingress_registerRound__next_write_site := 2;
    call acceptor2_ingress_registerRound.write(acceptor2_hdr.paxos.inst, acceptor2_hdr.paxos.rnd);
    // acceptor2_write
    acceptor2_ingress_registerVRound__next_write_site := 1;
    call acceptor2_ingress_registerVRound.write(acceptor2_hdr.paxos.inst, acceptor2_hdr.paxos.rnd);
    // acceptor2_write
    acceptor2_ingress_registerValue__next_write_site := 1;
    call acceptor2_ingress_registerValue.write(acceptor2_hdr.paxos.inst, acceptor2_hdr.paxos.paxosval);
}

// acceptor2_Action acceptor2_ingress_handle_arp_reply
procedure {:inline 1} acceptor2_ingress_handle_arp_reply()
{
}

// acceptor2_Action acceptor2_ingress_handle_arp_request
procedure {:inline 1} acceptor2_ingress_handle_arp_request()
	modifies acceptor2_forward, acceptor2_hdr.arp.op, acceptor2_hdr.arp.sha, acceptor2_hdr.arp.spa, acceptor2_hdr.arp.tha, acceptor2_hdr.arp.tpa, acceptor2_hdr.ethernet.dstAddr, acceptor2_hdr.ethernet.srcAddr, acceptor2_standard_metadata.egress_port, acceptor2_standard_metadata.egress_spec;
{
    acceptor2_hdr.ethernet.dstAddr := acceptor2_hdr.ethernet.srcAddr;
    // acceptor2_read
    acceptor2_hdr.ethernet.srcAddr := acceptor2_ingress_my_mac_address.read(acceptor2_ingress_my_mac_address, 0bv32);
    acceptor2_hdr.arp.op := 2bv16;
    acceptor2_hdr.arp.tha := acceptor2_hdr.arp.sha;
    acceptor2_hdr.arp.tpa := acceptor2_hdr.arp.spa;
    // acceptor2_read
    acceptor2_hdr.arp.sha := acceptor2_ingress_my_mac_address.read(acceptor2_ingress_my_mac_address, 0bv32);
    // acceptor2_read
    acceptor2_hdr.arp.spa := acceptor2_ingress_my_ip_address.read(acceptor2_ingress_my_ip_address, 0bv32);
    acceptor2_standard_metadata.egress_spec := acceptor2_standard_metadata.ingress_port;
    acceptor2_standard_metadata.egress_port := acceptor2_standard_metadata.ingress_port;
    acceptor2_forward := true;
}

// acceptor2_Action acceptor2_ingress_handle_icmp_reply
procedure {:inline 1} acceptor2_ingress_handle_icmp_reply()
{
}

// acceptor2_Action acceptor2_ingress_handle_icmp_request
procedure {:inline 1} acceptor2_ingress_handle_icmp_request()
	modifies acceptor2_hdr.ethernet.dstAddr, acceptor2_hdr.ethernet.srcAddr, acceptor2_hdr.icmp.hdrChecksum, acceptor2_hdr.icmp.icmpType, acceptor2_hdr.ipv4.dstAddr, acceptor2_hdr.ipv4.srcAddr, acceptor2_ipdst_0;
{
    acceptor2_hdr.ethernet.dstAddr := acceptor2_hdr.ethernet.srcAddr;
    // acceptor2_read
    acceptor2_hdr.ethernet.srcAddr := acceptor2_ingress_my_mac_address.read(acceptor2_ingress_my_mac_address, 0bv32);
    acceptor2_ipdst_0 := acceptor2_hdr.ipv4.dstAddr;
    acceptor2_hdr.ipv4.dstAddr := acceptor2_hdr.ipv4.srcAddr;
    acceptor2_hdr.ipv4.srcAddr := acceptor2_ipdst_0;
    acceptor2_hdr.icmp.icmpType := 0bv8;
    acceptor2_hdr.icmp.hdrChecksum := add.bv16(acceptor2_hdr.icmp.hdrChecksum, 2048bv16);
}

// acceptor2_Table acceptor2_ingress_icmp_tbl
procedure {:inline 1} acceptor2_ingress_icmp_tbl.apply()
	modifies acceptor2_drop, acceptor2_hdr.ethernet.dstAddr, acceptor2_hdr.ethernet.srcAddr, acceptor2_hdr.icmp.hdrChecksum, acceptor2_hdr.icmp.icmpType, acceptor2_hdr.ipv4.dstAddr, acceptor2_hdr.ipv4.srcAddr, acceptor2_ingress_icmp_tbl.action_run, acceptor2_ingress_icmp_tbl.hit, acceptor2_ipdst_0;
{
    acceptor2_hdr.icmp.icmpType := acceptor2_hdr.icmp.icmpType;
    acceptor2_ingress_icmp_tbl.hit := false;
    goto acceptor2_action_ingress_handle_icmp_request, acceptor2_action_ingress_handle_icmp_reply, acceptor2_action_drop_3;

    acceptor2_action_ingress_handle_icmp_request:
    assume acceptor2_ingress_icmp_tbl.action_run == acceptor2_ingress_icmp_tbl.action.ingress_handle_icmp_request;
    call acceptor2_ingress_handle_icmp_request();
    goto acceptor2_Exit;

    acceptor2_action_ingress_handle_icmp_reply:
    assume acceptor2_ingress_icmp_tbl.action_run == acceptor2_ingress_icmp_tbl.action.ingress_handle_icmp_reply;
    call acceptor2_ingress_handle_icmp_reply();
    goto acceptor2_Exit;

    acceptor2_action_drop_3:
    assume acceptor2_ingress_icmp_tbl.action_run == acceptor2_ingress_icmp_tbl.action.drop_3;
    call acceptor2_drop_3();
    goto acceptor2_Exit;

    acceptor2_Exit:
}
function {:inline true}acceptor2_ingress_learner_address.read(acceptor2_reg:[bv32]bv32, acceptor2_index:bv32)returns (bv32) {acceptor2_reg[acceptor2_index]}
procedure {:inline 1} acceptor2_ingress_learner_address.write(acceptor2_index:bv32, acceptor2_value:bv32)
	modifies acceptor2_ingress_learner_address, acceptor2_ingress_learner_address__last0_old_value, acceptor2_ingress_learner_address__last0_value, acceptor2_ingress_learner_address__last_index, acceptor2_ingress_learner_address__last_old_value, acceptor2_ingress_learner_address__last_value, acceptor2_ingress_learner_address__last_write_site, acceptor2_ingress_learner_address__wrote_any, acceptor2_ingress_learner_address__wrote_index0;
{
    acceptor2_ingress_learner_address__last_old_value := acceptor2_ingress_learner_address[acceptor2_index];
    acceptor2_ingress_learner_address[acceptor2_index] := acceptor2_value;
    acceptor2_ingress_learner_address__last_index := acceptor2_index;
    acceptor2_ingress_learner_address__last_value := acceptor2_value;
    acceptor2_ingress_learner_address__last_write_site := acceptor2_ingress_learner_address__next_write_site;
    acceptor2_ingress_learner_address__wrote_any := true;
    if (acceptor2_index == 0bv32) {
        acceptor2_ingress_learner_address__wrote_index0 := true;
        acceptor2_ingress_learner_address__last0_old_value := acceptor2_ingress_learner_address__last_old_value;
        acceptor2_ingress_learner_address__last0_value := acceptor2_value;
    }
}
function {:inline true}acceptor2_ingress_learner_mac_address.read(acceptor2_reg:[bv32]bv48, acceptor2_index:bv32)returns (bv48) {acceptor2_reg[acceptor2_index]}
procedure {:inline 1} acceptor2_ingress_learner_mac_address.write(acceptor2_index:bv32, acceptor2_value:bv48)
	modifies acceptor2_ingress_learner_mac_address, acceptor2_ingress_learner_mac_address__last0_old_value, acceptor2_ingress_learner_mac_address__last0_value, acceptor2_ingress_learner_mac_address__last_index, acceptor2_ingress_learner_mac_address__last_old_value, acceptor2_ingress_learner_mac_address__last_value, acceptor2_ingress_learner_mac_address__last_write_site, acceptor2_ingress_learner_mac_address__wrote_any, acceptor2_ingress_learner_mac_address__wrote_index0;
{
    acceptor2_ingress_learner_mac_address__last_old_value := acceptor2_ingress_learner_mac_address[acceptor2_index];
    acceptor2_ingress_learner_mac_address[acceptor2_index] := acceptor2_value;
    acceptor2_ingress_learner_mac_address__last_index := acceptor2_index;
    acceptor2_ingress_learner_mac_address__last_value := acceptor2_value;
    acceptor2_ingress_learner_mac_address__last_write_site := acceptor2_ingress_learner_mac_address__next_write_site;
    acceptor2_ingress_learner_mac_address__wrote_any := true;
    if (acceptor2_index == 0bv32) {
        acceptor2_ingress_learner_mac_address__wrote_index0 := true;
        acceptor2_ingress_learner_mac_address__last0_old_value := acceptor2_ingress_learner_mac_address__last_old_value;
        acceptor2_ingress_learner_mac_address__last0_value := acceptor2_value;
    }
}
function {:inline true}acceptor2_ingress_my_ip_address.read(acceptor2_reg:[bv32]bv32, acceptor2_index:bv32)returns (bv32) {acceptor2_reg[acceptor2_index]}
procedure {:inline 1} acceptor2_ingress_my_ip_address.write(acceptor2_index:bv32, acceptor2_value:bv32)
	modifies acceptor2_ingress_my_ip_address, acceptor2_ingress_my_ip_address__last0_old_value, acceptor2_ingress_my_ip_address__last0_value, acceptor2_ingress_my_ip_address__last_index, acceptor2_ingress_my_ip_address__last_old_value, acceptor2_ingress_my_ip_address__last_value, acceptor2_ingress_my_ip_address__last_write_site, acceptor2_ingress_my_ip_address__wrote_any, acceptor2_ingress_my_ip_address__wrote_index0;
{
    acceptor2_ingress_my_ip_address__last_old_value := acceptor2_ingress_my_ip_address[acceptor2_index];
    acceptor2_ingress_my_ip_address[acceptor2_index] := acceptor2_value;
    acceptor2_ingress_my_ip_address__last_index := acceptor2_index;
    acceptor2_ingress_my_ip_address__last_value := acceptor2_value;
    acceptor2_ingress_my_ip_address__last_write_site := acceptor2_ingress_my_ip_address__next_write_site;
    acceptor2_ingress_my_ip_address__wrote_any := true;
    if (acceptor2_index == 0bv32) {
        acceptor2_ingress_my_ip_address__wrote_index0 := true;
        acceptor2_ingress_my_ip_address__last0_old_value := acceptor2_ingress_my_ip_address__last_old_value;
        acceptor2_ingress_my_ip_address__last0_value := acceptor2_value;
    }
}
function {:inline true}acceptor2_ingress_my_mac_address.read(acceptor2_reg:[bv32]bv48, acceptor2_index:bv32)returns (bv48) {acceptor2_reg[acceptor2_index]}
procedure {:inline 1} acceptor2_ingress_my_mac_address.write(acceptor2_index:bv32, acceptor2_value:bv48)
	modifies acceptor2_ingress_my_mac_address, acceptor2_ingress_my_mac_address__last0_old_value, acceptor2_ingress_my_mac_address__last0_value, acceptor2_ingress_my_mac_address__last_index, acceptor2_ingress_my_mac_address__last_old_value, acceptor2_ingress_my_mac_address__last_value, acceptor2_ingress_my_mac_address__last_write_site, acceptor2_ingress_my_mac_address__wrote_any, acceptor2_ingress_my_mac_address__wrote_index0;
{
    acceptor2_ingress_my_mac_address__last_old_value := acceptor2_ingress_my_mac_address[acceptor2_index];
    acceptor2_ingress_my_mac_address[acceptor2_index] := acceptor2_value;
    acceptor2_ingress_my_mac_address__last_index := acceptor2_index;
    acceptor2_ingress_my_mac_address__last_value := acceptor2_value;
    acceptor2_ingress_my_mac_address__last_write_site := acceptor2_ingress_my_mac_address__next_write_site;
    acceptor2_ingress_my_mac_address__wrote_any := true;
    if (acceptor2_index == 0bv32) {
        acceptor2_ingress_my_mac_address__wrote_index0 := true;
        acceptor2_ingress_my_mac_address__last0_old_value := acceptor2_ingress_my_mac_address__last_old_value;
        acceptor2_ingress_my_mac_address__last0_value := acceptor2_value;
    }
}

// acceptor2_Action acceptor2_ingress_read_round
procedure {:inline 1} acceptor2_ingress_read_round()
	modifies acceptor2_meta.paxos_metadata.round;
{
    // acceptor2_read
    acceptor2_meta.paxos_metadata.round := acceptor2_ingress_registerRound.read(acceptor2_ingress_registerRound, acceptor2_hdr.paxos.inst);
}
function {:inline true}acceptor2_ingress_registerAcceptorID.read(acceptor2_reg:[bv32]bv16, acceptor2_index:bv32)returns (bv16) {acceptor2_reg[acceptor2_index]}
procedure {:inline 1} acceptor2_ingress_registerAcceptorID.write(acceptor2_index:bv32, acceptor2_value:bv16)
	modifies acceptor2_ingress_registerAcceptorID, acceptor2_ingress_registerAcceptorID__last0_old_value, acceptor2_ingress_registerAcceptorID__last0_value, acceptor2_ingress_registerAcceptorID__last_index, acceptor2_ingress_registerAcceptorID__last_old_value, acceptor2_ingress_registerAcceptorID__last_value, acceptor2_ingress_registerAcceptorID__last_write_site, acceptor2_ingress_registerAcceptorID__wrote_any, acceptor2_ingress_registerAcceptorID__wrote_index0;
{
    acceptor2_ingress_registerAcceptorID__last_old_value := acceptor2_ingress_registerAcceptorID[acceptor2_index];
    acceptor2_ingress_registerAcceptorID[acceptor2_index] := acceptor2_value;
    acceptor2_ingress_registerAcceptorID__last_index := acceptor2_index;
    acceptor2_ingress_registerAcceptorID__last_value := acceptor2_value;
    acceptor2_ingress_registerAcceptorID__last_write_site := acceptor2_ingress_registerAcceptorID__next_write_site;
    acceptor2_ingress_registerAcceptorID__wrote_any := true;
    if (acceptor2_index == 0bv32) {
        acceptor2_ingress_registerAcceptorID__wrote_index0 := true;
        acceptor2_ingress_registerAcceptorID__last0_old_value := acceptor2_ingress_registerAcceptorID__last_old_value;
        acceptor2_ingress_registerAcceptorID__last0_value := acceptor2_value;
    }
}
function {:inline true}acceptor2_ingress_registerRound.read(acceptor2_reg:[bv32]bv16, acceptor2_index:bv32)returns (bv16) {acceptor2_reg[acceptor2_index]}
procedure {:inline 1} acceptor2_ingress_registerRound.write(acceptor2_index:bv32, acceptor2_value:bv16)
	modifies acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_index0;
{
    acceptor2_ingress_registerRound__last_old_value := acceptor2_ingress_registerRound[acceptor2_index];
    acceptor2_ingress_registerRound[acceptor2_index] := acceptor2_value;
    acceptor2_ingress_registerRound__last_index := acceptor2_index;
    acceptor2_ingress_registerRound__last_value := acceptor2_value;
    acceptor2_ingress_registerRound__last_write_site := acceptor2_ingress_registerRound__next_write_site;
    acceptor2_ingress_registerRound__wrote_any := true;
    if (acceptor2_index == 0bv32) {
        acceptor2_ingress_registerRound__wrote_index0 := true;
        acceptor2_ingress_registerRound__last0_old_value := acceptor2_ingress_registerRound__last_old_value;
        acceptor2_ingress_registerRound__last0_value := acceptor2_value;
    }
}
function {:inline true}acceptor2_ingress_registerVRound.read(acceptor2_reg:[bv32]bv16, acceptor2_index:bv32)returns (bv16) {acceptor2_reg[acceptor2_index]}
procedure {:inline 1} acceptor2_ingress_registerVRound.write(acceptor2_index:bv32, acceptor2_value:bv16)
	modifies acceptor2_ingress_registerVRound, acceptor2_ingress_registerVRound__last0_old_value, acceptor2_ingress_registerVRound__last0_value, acceptor2_ingress_registerVRound__last_index, acceptor2_ingress_registerVRound__last_old_value, acceptor2_ingress_registerVRound__last_value, acceptor2_ingress_registerVRound__last_write_site, acceptor2_ingress_registerVRound__wrote_any, acceptor2_ingress_registerVRound__wrote_index0;
{
    acceptor2_ingress_registerVRound__last_old_value := acceptor2_ingress_registerVRound[acceptor2_index];
    acceptor2_ingress_registerVRound[acceptor2_index] := acceptor2_value;
    acceptor2_ingress_registerVRound__last_index := acceptor2_index;
    acceptor2_ingress_registerVRound__last_value := acceptor2_value;
    acceptor2_ingress_registerVRound__last_write_site := acceptor2_ingress_registerVRound__next_write_site;
    acceptor2_ingress_registerVRound__wrote_any := true;
    if (acceptor2_index == 0bv32) {
        acceptor2_ingress_registerVRound__wrote_index0 := true;
        acceptor2_ingress_registerVRound__last0_old_value := acceptor2_ingress_registerVRound__last_old_value;
        acceptor2_ingress_registerVRound__last0_value := acceptor2_value;
    }
}
function {:inline true}acceptor2_ingress_registerValue.read(acceptor2_reg:[bv32]bv256, acceptor2_index:bv32)returns (bv256) {acceptor2_reg[acceptor2_index]}
procedure {:inline 1} acceptor2_ingress_registerValue.write(acceptor2_index:bv32, acceptor2_value:bv256)
	modifies acceptor2_ingress_registerValue, acceptor2_ingress_registerValue__last0_old_value, acceptor2_ingress_registerValue__last0_value, acceptor2_ingress_registerValue__last_index, acceptor2_ingress_registerValue__last_old_value, acceptor2_ingress_registerValue__last_value, acceptor2_ingress_registerValue__last_write_site, acceptor2_ingress_registerValue__wrote_any, acceptor2_ingress_registerValue__wrote_index0;
{
    acceptor2_ingress_registerValue__last_old_value := acceptor2_ingress_registerValue[acceptor2_index];
    acceptor2_ingress_registerValue[acceptor2_index] := acceptor2_value;
    acceptor2_ingress_registerValue__last_index := acceptor2_index;
    acceptor2_ingress_registerValue__last_value := acceptor2_value;
    acceptor2_ingress_registerValue__last_write_site := acceptor2_ingress_registerValue__next_write_site;
    acceptor2_ingress_registerValue__wrote_any := true;
    if (acceptor2_index == 0bv32) {
        acceptor2_ingress_registerValue__wrote_index0 := true;
        acceptor2_ingress_registerValue__last0_old_value := acceptor2_ingress_registerValue__last_old_value;
        acceptor2_ingress_registerValue__last0_value := acceptor2_value;
    }
}

// acceptor2_Table acceptor2_ingress_transport_tbl
procedure {:inline 1} acceptor2_ingress_transport_tbl.apply()
	modifies acceptor2_drop, acceptor2_forward, acceptor2_hdr.ipv4.dstAddr, acceptor2_hdr.udp.dstPort, acceptor2_ingress_transport_tbl.action_run, acceptor2_ingress_transport_tbl.hit, acceptor2_standard_metadata.egress_port, acceptor2_standard_metadata.egress_spec;
{
    acceptor2_hdr.ipv4.dstAddr := acceptor2_hdr.ipv4.dstAddr;
    acceptor2_ingress_transport_tbl.hit := false;
    goto acceptor2_action_drop_1, acceptor2_action_ingress_forward;

    acceptor2_action_drop_1:
    assume acceptor2_ingress_transport_tbl.action_run == acceptor2_ingress_transport_tbl.action.drop_1;
    call acceptor2_drop_1();
    goto acceptor2_Exit;

    acceptor2_action_ingress_forward:
    assume acceptor2_ingress_transport_tbl.action_run == acceptor2_ingress_transport_tbl.action.ingress_forward;
    call acceptor2_ingress_forward(acceptor2_ingress_transport_tbl.ingress_forward.port, acceptor2_ingress_transport_tbl.ingress_forward.udp_dst);
    goto acceptor2_Exit;

    acceptor2_Exit:
}
procedure {:inline 1} acceptor2_main()
	modifies acceptor2_drop, acceptor2_egress_place_holder_table.hit, acceptor2_forward, acceptor2_hdr.arp.op, acceptor2_hdr.arp.sha, acceptor2_hdr.arp.spa, acceptor2_hdr.arp.tha, acceptor2_hdr.arp.tpa, acceptor2_hdr.ethernet.dstAddr, acceptor2_hdr.ethernet.srcAddr, acceptor2_hdr.icmp.hdrChecksum, acceptor2_hdr.icmp.icmpType, acceptor2_hdr.ipv4.dstAddr, acceptor2_hdr.ipv4.hdrChecksum, acceptor2_hdr.ipv4.srcAddr, acceptor2_hdr.paxos.acptid, acceptor2_hdr.paxos.msgtype, acceptor2_hdr.paxos.paxosval, acceptor2_hdr.paxos.vrnd, acceptor2_hdr.udp.dstPort, acceptor2_ingress_acceptor_tbl.action_run, acceptor2_ingress_acceptor_tbl.hit, acceptor2_ingress_arp_tbl.action_run, acceptor2_ingress_arp_tbl.hit, acceptor2_ingress_icmp_tbl.action_run, acceptor2_ingress_icmp_tbl.hit, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_index0, acceptor2_ingress_registerVRound, acceptor2_ingress_registerVRound__last0_old_value, acceptor2_ingress_registerVRound__last0_value, acceptor2_ingress_registerVRound__last_index, acceptor2_ingress_registerVRound__last_old_value, acceptor2_ingress_registerVRound__last_value, acceptor2_ingress_registerVRound__last_write_site, acceptor2_ingress_registerVRound__next_write_site, acceptor2_ingress_registerVRound__wrote_any, acceptor2_ingress_registerVRound__wrote_index0, acceptor2_ingress_registerValue, acceptor2_ingress_registerValue__last0_old_value, acceptor2_ingress_registerValue__last0_value, acceptor2_ingress_registerValue__last_index, acceptor2_ingress_registerValue__last_old_value, acceptor2_ingress_registerValue__last_value, acceptor2_ingress_registerValue__last_write_site, acceptor2_ingress_registerValue__next_write_site, acceptor2_ingress_registerValue__wrote_any, acceptor2_ingress_registerValue__wrote_index0, acceptor2_ingress_transport_tbl.action_run, acceptor2_ingress_transport_tbl.hit, acceptor2_ipdst_0, acceptor2_isValid, acceptor2_meta.paxos_metadata.round, acceptor2_p4b_checksum_updated, acceptor2_standard_metadata.egress_port, acceptor2_standard_metadata.egress_spec;
{
    call acceptor2_TopParser();
    call acceptor2_verifyChecksum();
    call acceptor2_ingress();
    call acceptor2_egress();
    call acceptor2_computeChecksum();
    if(acceptor2_forward == false){
        acceptor2_drop := true;
    }
}
procedure acceptor2_mainProcedure()
	modifies acceptor2_drop, acceptor2_egress_place_holder_table.hit, acceptor2_forward, acceptor2_hdr.arp.op, acceptor2_hdr.arp.sha, acceptor2_hdr.arp.spa, acceptor2_hdr.arp.tha, acceptor2_hdr.arp.tpa, acceptor2_hdr.ethernet.dstAddr, acceptor2_hdr.ethernet.srcAddr, acceptor2_hdr.icmp.hdrChecksum, acceptor2_hdr.icmp.icmpType, acceptor2_hdr.ipv4.dstAddr, acceptor2_hdr.ipv4.hdrChecksum, acceptor2_hdr.ipv4.srcAddr, acceptor2_hdr.paxos.acptid, acceptor2_hdr.paxos.msgtype, acceptor2_hdr.paxos.paxosval, acceptor2_hdr.paxos.vrnd, acceptor2_hdr.udp.dstPort, acceptor2_ingress_acceptor_tbl.action_run, acceptor2_ingress_acceptor_tbl.hit, acceptor2_ingress_arp_tbl.action_run, acceptor2_ingress_arp_tbl.hit, acceptor2_ingress_icmp_tbl.action_run, acceptor2_ingress_icmp_tbl.hit, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_index0, acceptor2_ingress_registerVRound, acceptor2_ingress_registerVRound__last0_old_value, acceptor2_ingress_registerVRound__last0_value, acceptor2_ingress_registerVRound__last_index, acceptor2_ingress_registerVRound__last_old_value, acceptor2_ingress_registerVRound__last_value, acceptor2_ingress_registerVRound__last_write_site, acceptor2_ingress_registerVRound__next_write_site, acceptor2_ingress_registerVRound__wrote_any, acceptor2_ingress_registerVRound__wrote_index0, acceptor2_ingress_registerValue, acceptor2_ingress_registerValue__last0_old_value, acceptor2_ingress_registerValue__last0_value, acceptor2_ingress_registerValue__last_index, acceptor2_ingress_registerValue__last_old_value, acceptor2_ingress_registerValue__last_value, acceptor2_ingress_registerValue__last_write_site, acceptor2_ingress_registerValue__next_write_site, acceptor2_ingress_registerValue__wrote_any, acceptor2_ingress_registerValue__wrote_index0, acceptor2_ingress_transport_tbl.action_run, acceptor2_ingress_transport_tbl.hit, acceptor2_ipdst_0, acceptor2_isValid, acceptor2_meta.paxos_metadata.round, acceptor2_p4b_checksum_error, acceptor2_p4b_checksum_updated, acceptor2_p4b_checksum_verified, acceptor2_p4b_clone_e2e, acceptor2_p4b_clone_i2e, acceptor2_p4b_clone_i2i, acceptor2_p4b_digest, acceptor2_p4b_recirculate, acceptor2_standard_metadata.egress_port, acceptor2_standard_metadata.egress_spec;
{
    acceptor2_p4b_checksum_error := false;
    acceptor2_p4b_checksum_updated := false;
    acceptor2_p4b_checksum_verified := false;
    acceptor2_p4b_digest := false;
    acceptor2_p4b_recirculate := false;
    acceptor2_p4b_clone_i2i := false;
    acceptor2_p4b_clone_e2e := false;
    acceptor2_p4b_clone_i2e := false;
    call acceptor2_main();
}
procedure acceptor2_mark_to_drop();
    ensures acceptor2_drop==true;
	modifies acceptor2_drop;
procedure acceptor2_packet.emit(acceptor2_arg0:acceptor2_Ref);
procedure acceptor2_packet_in.extract(acceptor2_header:acceptor2_Ref);
    ensures (acceptor2_isValid[acceptor2_header] == true);
	modifies acceptor2_isValid;
procedure acceptor2_reject();
    ensures acceptor2_drop==true;
	modifies acceptor2_drop;
procedure {:inline 1} acceptor2_setInvalid(acceptor2_header:acceptor2_Ref);
    ensures (acceptor2_isValid[acceptor2_header] == false);
	modifies acceptor2_isValid;
procedure {:inline 1} acceptor2_setValid(acceptor2_header:acceptor2_Ref);

// acceptor2_Control acceptor2_verifyChecksum
procedure {:inline 1} acceptor2_verifyChecksum()
{
}
// ===== END NODE acceptor2 =====

// ===== BEGIN NODE leader (prefixed) =====
type leader_Ref;
type leader_error=bv1;
type leader_HeaderStack = [int]leader_Ref;
var leader_last:[leader_HeaderStack]leader_Ref;
var leader_forward:bool;
var leader_isValid:[leader_Ref]bool;
var leader_emit:[leader_Ref]bool;
var leader_stack.index:[leader_HeaderStack]int;
var leader_size:[leader_HeaderStack]int;
var leader_drop:bool;
var leader_p4b_clone_i2e:bool;
var leader_p4b_clone_e2e:bool;
var leader_p4b_clone_i2i:bool;
var leader_p4b_recirculate:bool;
var leader_p4b_digest:bool;
var leader_p4b_checksum_verified:bool;
var leader_p4b_checksum_updated:bool;
var leader_p4b_checksum_error:bool;

// leader_Struct leader_standard_metadata_t
type leader_standard_metadata_t;
var leader_standard_metadata.ingress_port:bv9;
var leader_standard_metadata.egress_spec:bv9;
var leader_standard_metadata.egress_port:bv9;
var leader_standard_metadata.instance_type:bv32;
var leader_standard_metadata.packet_length:bv32;
var leader_standard_metadata.enq_timestamp:bv32;
var leader_standard_metadata.enq_qdepth:bv19;
var leader_standard_metadata.deq_timedelta:bv32;
var leader_standard_metadata.deq_qdepth:bv19;
var leader_standard_metadata.ingress_global_timestamp:bv48;
var leader_standard_metadata.egress_global_timestamp:bv48;
var leader_standard_metadata.mcast_grp:bv16;
var leader_standard_metadata.egress_rid:bv16;
var leader_standard_metadata.checksum_error:bv1;
var leader_standard_metadata.parser_error:leader_error;
var leader_standard_metadata.priority:bv3;
type leader_CounterType = int;
type leader_MeterType = int;
type leader_HashAlgorithm = int;
type leader_CloneType = int;
type leader_EthernetAddress = bv48;
type leader_IPv4Address = bv32;
type leader_PortId = bv4;
type leader_ethernet_t;
type leader_arp_t;
type leader_ipv4_t;
type leader_icmp_t;
type leader_udp_t;
type leader_paxos_t;

// leader_Struct leader_headers
var leader_hdr:leader_Ref;

// leader_Header leader_ethernet_t
var leader_hdr.ethernet:leader_Ref;
var leader_hdr.ethernet.valid:bool;
var leader_hdr.ethernet.dstAddr:leader_EthernetAddress;
var leader_hdr.ethernet.srcAddr:leader_EthernetAddress;
var leader_hdr.ethernet.etherType:bv16;

// leader_Header leader_arp_t
var leader_hdr.arp:leader_Ref;
var leader_hdr.arp.valid:bool;
var leader_hdr.arp.hrd:bv16;
var leader_hdr.arp.pro:bv16;
var leader_hdr.arp.hln:bv8;
var leader_hdr.arp.pln:bv8;
var leader_hdr.arp.op:bv16;
var leader_hdr.arp.sha:bv48;
var leader_hdr.arp.spa:bv32;
var leader_hdr.arp.tha:bv48;
var leader_hdr.arp.tpa:bv32;

// leader_Header leader_ipv4_t
var leader_hdr.ipv4:leader_Ref;
var leader_hdr.ipv4.valid:bool;
var leader_hdr.ipv4.version:bv4;
var leader_hdr.ipv4.ihl:bv4;
var leader_hdr.ipv4.diffserv:bv8;
var leader_hdr.ipv4.totalLen:bv16;
var leader_hdr.ipv4.identification:bv16;
var leader_hdr.ipv4.flags:bv3;
var leader_hdr.ipv4.fragOffset:bv13;
var leader_hdr.ipv4.ttl:bv8;
var leader_hdr.ipv4.protocol:bv8;
var leader_hdr.ipv4.hdrChecksum:bv16;
var leader_hdr.ipv4.srcAddr:leader_IPv4Address;
var leader_hdr.ipv4.dstAddr:leader_IPv4Address;

// leader_Header leader_icmp_t
var leader_hdr.icmp:leader_Ref;
var leader_hdr.icmp.valid:bool;
var leader_hdr.icmp.icmpType:bv8;
var leader_hdr.icmp.icmpCode:bv8;
var leader_hdr.icmp.hdrChecksum:bv16;
var leader_hdr.icmp.identifier:bv16;
var leader_hdr.icmp.seqNumber:bv16;
var leader_hdr.icmp.payload:bv256;

// leader_Header leader_udp_t
var leader_hdr.udp:leader_Ref;
var leader_hdr.udp.valid:bool;
var leader_hdr.udp.srcPort:bv16;
var leader_hdr.udp.dstPort:bv16;
var leader_hdr.udp.length_:bv16;
var leader_hdr.udp.checksum:bv16;

// leader_Header leader_paxos_t
var leader_hdr.paxos:leader_Ref;
var leader_hdr.paxos.valid:bool;
var leader_hdr.paxos.msgtype:bv16;
var leader_hdr.paxos.inst:bv32;
var leader_hdr.paxos.rnd:bv16;
var leader_hdr.paxos.vrnd:bv16;
var leader_hdr.paxos.acptid:bv16;
var leader_hdr.paxos.paxoslen:bv32;
var leader_hdr.paxos.paxosval:bv256;

// leader_Struct leader_paxos_metadata_t
type leader_paxos_metadata_t;

// leader_Struct leader_metadata
type leader_metadata;
var leader_meta.paxos_metadata:leader_paxos_metadata_t;
var leader_meta.paxos_metadata.round:bv16;
var leader_meta.paxos_metadata.set_drop:bv1;
var leader_meta.paxos_metadata.ack_count:bv8;
var leader_meta.paxos_metadata.ack_acceptors:bv8;
var leader_meta:leader_metadata;
var leader_standard_metadata:leader_standard_metadata_t;
var leader_index_0:bv32;
var leader_current_instance_0:bv32;
var leader_index_1:bv32;
var leader_reset_value_0:bv32;

// leader_Register leader_ingress_ctrlInstane
var leader_ingress_ctrlInstane:[bv32]bv32;
var leader_ingress_ctrlInstane__last_index:bv32;
var leader_ingress_ctrlInstane__last_value:bv32;
var leader_ingress_ctrlInstane__last_old_value:bv32;
var leader_ingress_ctrlInstane__wrote_any:bool;
var leader_ingress_ctrlInstane__wrote_index0:bool;
var leader_ingress_ctrlInstane__last0_old_value:bv32;
var leader_ingress_ctrlInstane__last0_value:bv32;
var leader_ingress_ctrlInstane__next_write_site:int;
var leader_ingress_ctrlInstane__last_write_site:int;
const leader_ingress_ctrlInstane.size:bv32;
axiom leader_ingress_ctrlInstane.size == 1bv32;

function {:builtin "bvadd"} add.bv32(leader_left:bv32, leader_right:bv32) returns(bv32);

// leader_Table leader_ingress_leader_tbl leader_Actionlist leader_Declaration
type leader_ingress_leader_tbl.action;
const unique leader_ingress_leader_tbl.action.ingress_increase_instance : leader_ingress_leader_tbl.action;
const unique leader_ingress_leader_tbl.action.ingress_reset_instance : leader_ingress_leader_tbl.action;
const unique leader_ingress_leader_tbl.action.ingress_drop : leader_ingress_leader_tbl.action;
var leader_ingress_leader_tbl.action_run : leader_ingress_leader_tbl.action;
var leader_ingress_leader_tbl.hit : bool;

// leader_Table leader_ingress_transport_tbl leader_Actionlist leader_Declaration
type leader_ingress_transport_tbl.action;
var leader_ingress_transport_tbl.ingress_forward.port:leader_PortId;
var leader_ingress_transport_tbl.ingress_forward.acceptorPort:bv16;
const unique leader_ingress_transport_tbl.action.drop_1 : leader_ingress_transport_tbl.action;
const unique leader_ingress_transport_tbl.action.ingress_forward : leader_ingress_transport_tbl.action;
var leader_ingress_transport_tbl.action_run : leader_ingress_transport_tbl.action;
var leader_ingress_transport_tbl.hit : bool;

// leader_Table leader_egress_place_holder_table leader_Actionlist leader_Declaration
type leader_egress_place_holder_table.action;
const unique leader_egress_place_holder_table.action.NoAction : leader_egress_place_holder_table.action;
var leader_egress_place_holder_table.action_run : leader_egress_place_holder_table.action;
var leader_egress_place_holder_table.hit : bool;



// leader_Action leader_NoAction
procedure {:inline 1} leader_NoAction()
{
}

// leader_Parser leader_TopParser
procedure {:inline 1} leader_TopParser()
	modifies leader_drop, leader_isValid;
{
    goto leader_State$TopParser$start;

        leader_State$TopParser$start:
    call leader_packet_in.extract(leader_hdr.ethernet);
    goto leader_State$TopParser$start$parse_arp_2, leader_State$TopParser$start$parse_ipv4_1, leader_State$TopParser$start$DEFAULT;
    
leader_State$TopParser$start$parse_arp_2:
    assume (leader_hdr.ethernet.etherType == 2054bv16);
    goto leader_State$TopParser$parse_arp;
    
leader_State$TopParser$start$parse_ipv4_1:
    assume (leader_hdr.ethernet.etherType == 2048bv16);
    goto leader_State$TopParser$parse_ipv4;

    leader_State$TopParser$start$DEFAULT:
    assume(!(leader_hdr.ethernet.etherType == 2054bv16)&&!(leader_hdr.ethernet.etherType == 2048bv16));
goto leader_State$reject;

        leader_State$TopParser$parse_arp:
    call leader_packet_in.extract(leader_hdr.arp);
    goto leader_State$accept;

        leader_State$TopParser$parse_ipv4:
    call leader_packet_in.extract(leader_hdr.ipv4);
    goto leader_State$TopParser$parse_ipv4$parse_icmp_3, leader_State$TopParser$parse_ipv4$parse_udp_2, leader_State$TopParser$parse_ipv4$DEFAULT;
    
leader_State$TopParser$parse_ipv4$parse_icmp_3:
    assume (leader_hdr.ipv4.protocol == 1bv8);
    goto leader_State$TopParser$parse_icmp;
    
leader_State$TopParser$parse_ipv4$parse_udp_2:
    assume (leader_hdr.ipv4.protocol == 17bv8);
    goto leader_State$TopParser$parse_udp;

    leader_State$TopParser$parse_ipv4$DEFAULT:
    assume(!(leader_hdr.ipv4.protocol == 1bv8)&&!(leader_hdr.ipv4.protocol == 17bv8));
    goto leader_State$accept;

        leader_State$TopParser$parse_icmp:
    call leader_packet_in.extract(leader_hdr.icmp);
    goto leader_State$accept;

        leader_State$TopParser$parse_udp:
    call leader_packet_in.extract(leader_hdr.udp);
    goto leader_State$TopParser$parse_udp$parse_paxos_2, leader_State$TopParser$parse_udp$DEFAULT;
    
leader_State$TopParser$parse_udp$parse_paxos_2:
    assume (leader_hdr.udp.dstPort == 34952bv16);
    goto leader_State$TopParser$parse_paxos;

    leader_State$TopParser$parse_udp$DEFAULT:
    assume(!(leader_hdr.udp.dstPort == 34952bv16));
    goto leader_State$accept;

        leader_State$TopParser$parse_paxos:
    call leader_packet_in.extract(leader_hdr.paxos);
    goto leader_State$accept;

    leader_State$accept:
    call leader_accept();
    goto leader_Exit;

    leader_State$reject:
    call leader_reject();
    goto leader_Exit;

    leader_Exit:
}
procedure {:inline 1} leader_accept()
{
}

// leader_Control leader_computeChecksum
procedure {:inline 1} leader_computeChecksum()
	modifies leader_hdr.ipv4.hdrChecksum, leader_p4b_checksum_updated;
{
    if (leader_isValid[leader_hdr.ipv4]) {
        leader_p4b_checksum_updated := true;
        havoc leader_hdr.ipv4.hdrChecksum;
    }
}

// leader_Action leader_drop_1
procedure {:inline 1} leader_drop_1()
	modifies leader_drop;
{
    call leader_mark_to_drop();
}

// leader_Control leader_egress
procedure {:inline 1} leader_egress()
	modifies leader_egress_place_holder_table.hit;
{
    call leader_egress_place_holder_table.apply();
}

// leader_Table leader_egress_place_holder_table
procedure {:inline 1} leader_egress_place_holder_table.apply()
	modifies leader_egress_place_holder_table.hit;
{
    leader_egress_place_holder_table.hit := false;
    goto leader_Exit;

    leader_Exit:
}

// leader_Control leader_ingress
procedure {:inline 1} leader_ingress()
	modifies leader_current_instance_0, leader_drop, leader_forward, leader_hdr.paxos.inst, leader_hdr.paxos.msgtype, leader_hdr.udp.dstPort, leader_index_0, leader_index_1, leader_ingress_ctrlInstane, leader_ingress_ctrlInstane__last0_old_value, leader_ingress_ctrlInstane__last0_value, leader_ingress_ctrlInstane__last_index, leader_ingress_ctrlInstane__last_old_value, leader_ingress_ctrlInstane__last_value, leader_ingress_ctrlInstane__last_write_site, leader_ingress_ctrlInstane__next_write_site, leader_ingress_ctrlInstane__wrote_any, leader_ingress_ctrlInstane__wrote_index0, leader_ingress_leader_tbl.action_run, leader_ingress_leader_tbl.hit, leader_ingress_transport_tbl.action_run, leader_ingress_transport_tbl.hit, leader_meta.paxos_metadata.set_drop, leader_reset_value_0, leader_standard_metadata.egress_port, leader_standard_metadata.egress_spec;
{
havoc leader_index_0;
havoc leader_current_instance_0;
havoc leader_index_1;
havoc leader_reset_value_0;
    if(leader_isValid[leader_hdr.ipv4]){
        if(leader_isValid[leader_hdr.paxos]){
            call leader_ingress_leader_tbl.apply();
            call leader_ingress_transport_tbl.apply();
        }
    }
}
function {:inline true}leader_ingress_ctrlInstane.read(leader_reg:[bv32]bv32, leader_index:bv32)returns (bv32) {leader_reg[leader_index]}
procedure {:inline 1} leader_ingress_ctrlInstane.write(leader_index:bv32, leader_value:bv32)
	modifies leader_ingress_ctrlInstane, leader_ingress_ctrlInstane__last0_old_value, leader_ingress_ctrlInstane__last0_value, leader_ingress_ctrlInstane__last_index, leader_ingress_ctrlInstane__last_old_value, leader_ingress_ctrlInstane__last_value, leader_ingress_ctrlInstane__last_write_site, leader_ingress_ctrlInstane__wrote_any, leader_ingress_ctrlInstane__wrote_index0;
{
    leader_ingress_ctrlInstane__last_old_value := leader_ingress_ctrlInstane[leader_index];
    leader_ingress_ctrlInstane[leader_index] := leader_value;
    leader_ingress_ctrlInstane__last_index := leader_index;
    leader_ingress_ctrlInstane__last_value := leader_value;
    leader_ingress_ctrlInstane__last_write_site := leader_ingress_ctrlInstane__next_write_site;
    leader_ingress_ctrlInstane__wrote_any := true;
    if (leader_index == 0bv32) {
        leader_ingress_ctrlInstane__wrote_index0 := true;
        leader_ingress_ctrlInstane__last0_old_value := leader_ingress_ctrlInstane__last_old_value;
        leader_ingress_ctrlInstane__last0_value := leader_value;
    }
}

// leader_Action leader_ingress_drop
procedure {:inline 1} leader_ingress_drop()
	modifies leader_drop;
{
    call leader_mark_to_drop();
}

// leader_Action leader_ingress_forward
procedure {:inline 1} leader_ingress_forward(leader_port:leader_PortId, leader_acceptorPort:bv16)
	modifies leader_forward, leader_hdr.udp.dstPort, leader_standard_metadata.egress_port, leader_standard_metadata.egress_spec;
{
    leader_standard_metadata.egress_spec := 0bv5++leader_port;
    leader_standard_metadata.egress_port := 0bv5++leader_port;
    leader_forward := true;
    leader_hdr.udp.dstPort := leader_acceptorPort;
}

// leader_Action leader_ingress_increase_instance
procedure {:inline 1} leader_ingress_increase_instance()
	modifies leader_current_instance_0, leader_hdr.paxos.inst, leader_index_0, leader_ingress_ctrlInstane, leader_ingress_ctrlInstane__last0_old_value, leader_ingress_ctrlInstane__last0_value, leader_ingress_ctrlInstane__last_index, leader_ingress_ctrlInstane__last_old_value, leader_ingress_ctrlInstane__last_value, leader_ingress_ctrlInstane__last_write_site, leader_ingress_ctrlInstane__next_write_site, leader_ingress_ctrlInstane__wrote_any, leader_ingress_ctrlInstane__wrote_index0, leader_meta.paxos_metadata.set_drop;
{
    leader_index_0 := 0bv32;
    // leader_read
    leader_current_instance_0 := leader_ingress_ctrlInstane.read(leader_ingress_ctrlInstane, leader_index_0);
    leader_hdr.paxos.inst := leader_current_instance_0;
    leader_current_instance_0 := add.bv32(leader_current_instance_0, 1bv32);
    // leader_write
    leader_ingress_ctrlInstane__next_write_site := 1;
    call leader_ingress_ctrlInstane.write(leader_index_0, leader_current_instance_0);
    leader_meta.paxos_metadata.set_drop := 0bv1;
}

// leader_Table leader_ingress_leader_tbl
procedure {:inline 1} leader_ingress_leader_tbl.apply()
	modifies leader_current_instance_0, leader_drop, leader_hdr.paxos.inst, leader_hdr.paxos.msgtype, leader_index_0, leader_index_1, leader_ingress_ctrlInstane, leader_ingress_ctrlInstane__last0_old_value, leader_ingress_ctrlInstane__last0_value, leader_ingress_ctrlInstane__last_index, leader_ingress_ctrlInstane__last_old_value, leader_ingress_ctrlInstane__last_value, leader_ingress_ctrlInstane__last_write_site, leader_ingress_ctrlInstane__next_write_site, leader_ingress_ctrlInstane__wrote_any, leader_ingress_ctrlInstane__wrote_index0, leader_ingress_leader_tbl.action_run, leader_ingress_leader_tbl.hit, leader_meta.paxos_metadata.set_drop, leader_reset_value_0;
{
    leader_hdr.paxos.msgtype := leader_hdr.paxos.msgtype;
    leader_ingress_leader_tbl.hit := false;
    goto leader_action_ingress_increase_instance, leader_action_ingress_reset_instance, leader_action_ingress_drop;

    leader_action_ingress_increase_instance:
    assume leader_ingress_leader_tbl.action_run == leader_ingress_leader_tbl.action.ingress_increase_instance;
    call leader_ingress_increase_instance();
    goto leader_Exit;

    leader_action_ingress_reset_instance:
    assume leader_ingress_leader_tbl.action_run == leader_ingress_leader_tbl.action.ingress_reset_instance;
    call leader_ingress_reset_instance();
    goto leader_Exit;

    leader_action_ingress_drop:
    assume leader_ingress_leader_tbl.action_run == leader_ingress_leader_tbl.action.ingress_drop;
    call leader_ingress_drop();
    goto leader_Exit;

    leader_Exit:
}

// leader_Action leader_ingress_reset_instance
procedure {:inline 1} leader_ingress_reset_instance()
	modifies leader_index_1, leader_ingress_ctrlInstane, leader_ingress_ctrlInstane__last0_old_value, leader_ingress_ctrlInstane__last0_value, leader_ingress_ctrlInstane__last_index, leader_ingress_ctrlInstane__last_old_value, leader_ingress_ctrlInstane__last_value, leader_ingress_ctrlInstane__last_write_site, leader_ingress_ctrlInstane__next_write_site, leader_ingress_ctrlInstane__wrote_any, leader_ingress_ctrlInstane__wrote_index0, leader_meta.paxos_metadata.set_drop, leader_reset_value_0;
{
    leader_index_1 := 0bv32;
    leader_reset_value_0 := 0bv32;
    // leader_write
    leader_ingress_ctrlInstane__next_write_site := 2;
    call leader_ingress_ctrlInstane.write(leader_index_1, leader_reset_value_0);
    leader_meta.paxos_metadata.set_drop := 1bv1;
}

// leader_Table leader_ingress_transport_tbl
procedure {:inline 1} leader_ingress_transport_tbl.apply()
	modifies leader_drop, leader_forward, leader_hdr.udp.dstPort, leader_ingress_transport_tbl.action_run, leader_ingress_transport_tbl.hit, leader_meta.paxos_metadata.set_drop, leader_standard_metadata.egress_port, leader_standard_metadata.egress_spec;
{
    leader_meta.paxos_metadata.set_drop := leader_meta.paxos_metadata.set_drop;
    leader_ingress_transport_tbl.hit := false;
    goto leader_action_drop_1, leader_action_ingress_forward;

    leader_action_drop_1:
    assume leader_ingress_transport_tbl.action_run == leader_ingress_transport_tbl.action.drop_1;
    call leader_drop_1();
    goto leader_Exit;

    leader_action_ingress_forward:
    assume leader_ingress_transport_tbl.action_run == leader_ingress_transport_tbl.action.ingress_forward;
    call leader_ingress_forward(leader_ingress_transport_tbl.ingress_forward.port, leader_ingress_transport_tbl.ingress_forward.acceptorPort);
    goto leader_Exit;

    leader_Exit:
}
procedure {:inline 1} leader_main()
	modifies leader_current_instance_0, leader_drop, leader_egress_place_holder_table.hit, leader_forward, leader_hdr.ipv4.hdrChecksum, leader_hdr.paxos.inst, leader_hdr.paxos.msgtype, leader_hdr.udp.dstPort, leader_index_0, leader_index_1, leader_ingress_ctrlInstane, leader_ingress_ctrlInstane__last0_old_value, leader_ingress_ctrlInstane__last0_value, leader_ingress_ctrlInstane__last_index, leader_ingress_ctrlInstane__last_old_value, leader_ingress_ctrlInstane__last_value, leader_ingress_ctrlInstane__last_write_site, leader_ingress_ctrlInstane__next_write_site, leader_ingress_ctrlInstane__wrote_any, leader_ingress_ctrlInstane__wrote_index0, leader_ingress_leader_tbl.action_run, leader_ingress_leader_tbl.hit, leader_ingress_transport_tbl.action_run, leader_ingress_transport_tbl.hit, leader_isValid, leader_meta.paxos_metadata.set_drop, leader_p4b_checksum_updated, leader_reset_value_0, leader_standard_metadata.egress_port, leader_standard_metadata.egress_spec;
{
    call leader_TopParser();
    call leader_verifyChecksum();
    call leader_ingress();
    call leader_egress();
    call leader_computeChecksum();
    if(leader_forward == false){
        leader_drop := true;
    }
}
procedure leader_mainProcedure()
	modifies leader_current_instance_0, leader_drop, leader_egress_place_holder_table.hit, leader_forward, leader_hdr.ipv4.hdrChecksum, leader_hdr.paxos.inst, leader_hdr.paxos.msgtype, leader_hdr.udp.dstPort, leader_index_0, leader_index_1, leader_ingress_ctrlInstane, leader_ingress_ctrlInstane__last0_old_value, leader_ingress_ctrlInstane__last0_value, leader_ingress_ctrlInstane__last_index, leader_ingress_ctrlInstane__last_old_value, leader_ingress_ctrlInstane__last_value, leader_ingress_ctrlInstane__last_write_site, leader_ingress_ctrlInstane__next_write_site, leader_ingress_ctrlInstane__wrote_any, leader_ingress_ctrlInstane__wrote_index0, leader_ingress_leader_tbl.action_run, leader_ingress_leader_tbl.hit, leader_ingress_transport_tbl.action_run, leader_ingress_transport_tbl.hit, leader_isValid, leader_meta.paxos_metadata.set_drop, leader_p4b_checksum_error, leader_p4b_checksum_updated, leader_p4b_checksum_verified, leader_p4b_clone_e2e, leader_p4b_clone_i2e, leader_p4b_clone_i2i, leader_p4b_digest, leader_p4b_recirculate, leader_reset_value_0, leader_standard_metadata.egress_port, leader_standard_metadata.egress_spec;
{
    leader_p4b_checksum_error := false;
    leader_p4b_checksum_updated := false;
    leader_p4b_checksum_verified := false;
    leader_p4b_digest := false;
    leader_p4b_recirculate := false;
    leader_p4b_clone_i2i := false;
    leader_p4b_clone_e2e := false;
    leader_p4b_clone_i2e := false;
    call leader_main();
}
procedure leader_mark_to_drop();
    ensures leader_drop==true;
	modifies leader_drop;
procedure leader_packet.emit(leader_arg0:leader_Ref);
procedure leader_packet_in.extract(leader_header:leader_Ref);
    ensures (leader_isValid[leader_header] == true);
	modifies leader_isValid;
procedure leader_reject();
    ensures leader_drop==true;
	modifies leader_drop;
procedure {:inline 1} leader_setInvalid(leader_header:leader_Ref);
    ensures (leader_isValid[leader_header] == false);
	modifies leader_isValid;
procedure {:inline 1} leader_setValid(leader_header:leader_Ref);

// leader_Control leader_verifyChecksum
procedure {:inline 1} leader_verifyChecksum()
{
}
// ===== END NODE leader =====

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
	modifies learner_egress_place_holder_table.hit;
{
    call learner_egress_place_holder_table.apply();
}

// learner_Table learner_egress_place_holder_table
procedure {:inline 1} learner_egress_place_holder_table.apply()
	modifies learner_egress_place_holder_table.hit;
{
    learner_egress_place_holder_table.hit := false;
    goto learner_Exit;

    learner_Exit:
}

// learner_Control learner_ingress
procedure {:inline 1} learner_ingress()
	modifies learner_acptid_0, learner_acptid_1, learner_drop, learner_forward, learner_hdr.paxos.msgtype, learner_hdr.udp.dstPort, learner_ingress_learner_tbl.action_run, learner_ingress_learner_tbl.hit, learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__next_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_index0, learner_ingress_registerRound, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__next_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_index0, learner_ingress_registerValue, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__next_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_index0, learner_ingress_reset_consensus_instance.action_run, learner_ingress_reset_consensus_instance.hit, learner_ingress_transport_tbl.action_run, learner_ingress_transport_tbl.hit, learner_meta.paxos_metadata.ack_acceptors, learner_meta.paxos_metadata.round, learner_meta.paxos_metadata.set_drop, learner_standard_metadata.egress_port, learner_standard_metadata.egress_spec;
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
    goto learner_action_ingress_handle_2b;

    learner_action_ingress_handle_2b:
    assume learner_ingress_learner_tbl.action_run == learner_ingress_learner_tbl.action.ingress_handle_2b;
    call learner_ingress_handle_2b();
    goto learner_Exit;

    learner_Exit:
}

// learner_Action learner_ingress_read_round
procedure {:inline 1} learner_ingress_read_round()
	modifies learner_meta.paxos_metadata.ack_acceptors, learner_meta.paxos_metadata.round, learner_meta.paxos_metadata.set_drop;
{
    // learner_read
    learner_meta.paxos_metadata.round := learner_ingress_registerRound.read(learner_ingress_registerRound, learner_hdr.paxos.inst);
    learner_meta.paxos_metadata.set_drop := 1bv1;
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
    goto learner_action_ingress_handle_new_value;

    learner_action_ingress_handle_new_value:
    assume learner_ingress_reset_consensus_instance.action_run == learner_ingress_reset_consensus_instance.action.ingress_handle_new_value;
    call learner_ingress_handle_new_value();
    goto learner_Exit;

    learner_Exit:
}

// learner_Table learner_ingress_transport_tbl
procedure {:inline 1} learner_ingress_transport_tbl.apply()
	modifies learner_drop, learner_forward, learner_hdr.udp.dstPort, learner_ingress_transport_tbl.action_run, learner_ingress_transport_tbl.hit, learner_meta.paxos_metadata.set_drop, learner_standard_metadata.egress_port, learner_standard_metadata.egress_spec;
{
    learner_meta.paxos_metadata.set_drop := learner_meta.paxos_metadata.set_drop;
    learner_ingress_transport_tbl.hit := false;
    goto learner_action_ingress_drop, learner_action_ingress_forward;

    learner_action_ingress_drop:
    assume learner_ingress_transport_tbl.action_run == learner_ingress_transport_tbl.action.ingress_drop;
    call learner_ingress_drop();
    goto learner_Exit;

    learner_action_ingress_forward:
    assume learner_ingress_transport_tbl.action_run == learner_ingress_transport_tbl.action.ingress_forward;
    call learner_ingress_forward(learner_ingress_transport_tbl.ingress_forward.port, learner_ingress_transport_tbl.ingress_forward.learnerPort);
    goto learner_Exit;

    learner_Exit:
}
procedure {:inline 1} learner_main()
	modifies learner_acptid_0, learner_acptid_1, learner_drop, learner_egress_place_holder_table.hit, learner_forward, learner_hdr.ipv4.hdrChecksum, learner_hdr.paxos.msgtype, learner_hdr.udp.dstPort, learner_ingress_learner_tbl.action_run, learner_ingress_learner_tbl.hit, learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__next_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_index0, learner_ingress_registerRound, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__next_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_index0, learner_ingress_registerValue, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__next_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_index0, learner_ingress_reset_consensus_instance.action_run, learner_ingress_reset_consensus_instance.hit, learner_ingress_transport_tbl.action_run, learner_ingress_transport_tbl.hit, learner_isValid, learner_meta.paxos_metadata.ack_acceptors, learner_meta.paxos_metadata.round, learner_meta.paxos_metadata.set_drop, learner_p4b_checksum_updated, learner_standard_metadata.egress_port, learner_standard_metadata.egress_spec;
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
	modifies learner_acptid_0, learner_acptid_1, learner_drop, learner_egress_place_holder_table.hit, learner_forward, learner_hdr.ipv4.hdrChecksum, learner_hdr.paxos.msgtype, learner_hdr.udp.dstPort, learner_ingress_learner_tbl.action_run, learner_ingress_learner_tbl.hit, learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__next_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_index0, learner_ingress_registerRound, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__next_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_index0, learner_ingress_registerValue, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__next_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_index0, learner_ingress_reset_consensus_instance.action_run, learner_ingress_reset_consensus_instance.hit, learner_ingress_transport_tbl.action_run, learner_ingress_transport_tbl.hit, learner_isValid, learner_meta.paxos_metadata.ack_acceptors, learner_meta.paxos_metadata.round, learner_meta.paxos_metadata.set_drop, learner_p4b_checksum_error, learner_p4b_checksum_updated, learner_p4b_checksum_verified, learner_p4b_clone_e2e, learner_p4b_clone_i2e, learner_p4b_clone_i2i, learner_p4b_digest, learner_p4b_recirculate, learner_standard_metadata.egress_port, learner_standard_metadata.egress_spec;
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
// Message abstraction: Bag(K=3) using inbox_count per node; single-slot mailbox for packet fields

var procurator_step: int;

// Register debug snapshots (for trace inspection)
var leader_ingress_ctrlInstane__dbg0: bv32;
var leader_ingress_ctrlInstane__last_index__dbg: bv32;
var leader_ingress_ctrlInstane__last_value__dbg: bv32;
var leader_ingress_ctrlInstane__last_old_value__dbg: bv32;
var leader_ingress_ctrlInstane__wrote_any__dbg: bool;
var leader_ingress_ctrlInstane__wrote_index0__dbg: bool;
var leader_ingress_ctrlInstane__last0_old_value__dbg: bv32;
var leader_ingress_ctrlInstane__last0_value__dbg: bv32;
var acceptor0_ingress_learner_address__dbg0: bv32;
var acceptor0_ingress_learner_address__last_index__dbg: bv32;
var acceptor0_ingress_learner_address__last_value__dbg: bv32;
var acceptor0_ingress_learner_address__last_old_value__dbg: bv32;
var acceptor0_ingress_learner_address__wrote_any__dbg: bool;
var acceptor0_ingress_learner_address__wrote_index0__dbg: bool;
var acceptor0_ingress_learner_address__last0_old_value__dbg: bv32;
var acceptor0_ingress_learner_address__last0_value__dbg: bv32;
var acceptor0_ingress_learner_mac_address__dbg0: bv48;
var acceptor0_ingress_learner_mac_address__last_index__dbg: bv32;
var acceptor0_ingress_learner_mac_address__last_value__dbg: bv48;
var acceptor0_ingress_learner_mac_address__last_old_value__dbg: bv48;
var acceptor0_ingress_learner_mac_address__wrote_any__dbg: bool;
var acceptor0_ingress_learner_mac_address__wrote_index0__dbg: bool;
var acceptor0_ingress_learner_mac_address__last0_old_value__dbg: bv48;
var acceptor0_ingress_learner_mac_address__last0_value__dbg: bv48;
var acceptor0_ingress_my_ip_address__dbg0: bv32;
var acceptor0_ingress_my_ip_address__last_index__dbg: bv32;
var acceptor0_ingress_my_ip_address__last_value__dbg: bv32;
var acceptor0_ingress_my_ip_address__last_old_value__dbg: bv32;
var acceptor0_ingress_my_ip_address__wrote_any__dbg: bool;
var acceptor0_ingress_my_ip_address__wrote_index0__dbg: bool;
var acceptor0_ingress_my_ip_address__last0_old_value__dbg: bv32;
var acceptor0_ingress_my_ip_address__last0_value__dbg: bv32;
var acceptor0_ingress_my_mac_address__dbg0: bv48;
var acceptor0_ingress_my_mac_address__last_index__dbg: bv32;
var acceptor0_ingress_my_mac_address__last_value__dbg: bv48;
var acceptor0_ingress_my_mac_address__last_old_value__dbg: bv48;
var acceptor0_ingress_my_mac_address__wrote_any__dbg: bool;
var acceptor0_ingress_my_mac_address__wrote_index0__dbg: bool;
var acceptor0_ingress_my_mac_address__last0_old_value__dbg: bv48;
var acceptor0_ingress_my_mac_address__last0_value__dbg: bv48;
var acceptor0_ingress_registerAcceptorID__dbg0: bv16;
var acceptor0_ingress_registerAcceptorID__last_index__dbg: bv32;
var acceptor0_ingress_registerAcceptorID__last_value__dbg: bv16;
var acceptor0_ingress_registerAcceptorID__last_old_value__dbg: bv16;
var acceptor0_ingress_registerAcceptorID__wrote_any__dbg: bool;
var acceptor0_ingress_registerAcceptorID__wrote_index0__dbg: bool;
var acceptor0_ingress_registerAcceptorID__last0_old_value__dbg: bv16;
var acceptor0_ingress_registerAcceptorID__last0_value__dbg: bv16;
var acceptor0_ingress_registerRound__dbg0: bv16;
var acceptor0_ingress_registerRound__last_index__dbg: bv32;
var acceptor0_ingress_registerRound__last_value__dbg: bv16;
var acceptor0_ingress_registerRound__last_old_value__dbg: bv16;
var acceptor0_ingress_registerRound__wrote_any__dbg: bool;
var acceptor0_ingress_registerRound__wrote_index0__dbg: bool;
var acceptor0_ingress_registerRound__last0_old_value__dbg: bv16;
var acceptor0_ingress_registerRound__last0_value__dbg: bv16;
var acceptor0_ingress_registerVRound__dbg0: bv16;
var acceptor0_ingress_registerVRound__last_index__dbg: bv32;
var acceptor0_ingress_registerVRound__last_value__dbg: bv16;
var acceptor0_ingress_registerVRound__last_old_value__dbg: bv16;
var acceptor0_ingress_registerVRound__wrote_any__dbg: bool;
var acceptor0_ingress_registerVRound__wrote_index0__dbg: bool;
var acceptor0_ingress_registerVRound__last0_old_value__dbg: bv16;
var acceptor0_ingress_registerVRound__last0_value__dbg: bv16;
var acceptor0_ingress_registerValue__dbg0: bv256;
var acceptor0_ingress_registerValue__last_index__dbg: bv32;
var acceptor0_ingress_registerValue__last_value__dbg: bv256;
var acceptor0_ingress_registerValue__last_old_value__dbg: bv256;
var acceptor0_ingress_registerValue__wrote_any__dbg: bool;
var acceptor0_ingress_registerValue__wrote_index0__dbg: bool;
var acceptor0_ingress_registerValue__last0_old_value__dbg: bv256;
var acceptor0_ingress_registerValue__last0_value__dbg: bv256;
var acceptor1_ingress_learner_address__dbg0: bv32;
var acceptor1_ingress_learner_address__last_index__dbg: bv32;
var acceptor1_ingress_learner_address__last_value__dbg: bv32;
var acceptor1_ingress_learner_address__last_old_value__dbg: bv32;
var acceptor1_ingress_learner_address__wrote_any__dbg: bool;
var acceptor1_ingress_learner_address__wrote_index0__dbg: bool;
var acceptor1_ingress_learner_address__last0_old_value__dbg: bv32;
var acceptor1_ingress_learner_address__last0_value__dbg: bv32;
var acceptor1_ingress_learner_mac_address__dbg0: bv48;
var acceptor1_ingress_learner_mac_address__last_index__dbg: bv32;
var acceptor1_ingress_learner_mac_address__last_value__dbg: bv48;
var acceptor1_ingress_learner_mac_address__last_old_value__dbg: bv48;
var acceptor1_ingress_learner_mac_address__wrote_any__dbg: bool;
var acceptor1_ingress_learner_mac_address__wrote_index0__dbg: bool;
var acceptor1_ingress_learner_mac_address__last0_old_value__dbg: bv48;
var acceptor1_ingress_learner_mac_address__last0_value__dbg: bv48;
var acceptor1_ingress_my_ip_address__dbg0: bv32;
var acceptor1_ingress_my_ip_address__last_index__dbg: bv32;
var acceptor1_ingress_my_ip_address__last_value__dbg: bv32;
var acceptor1_ingress_my_ip_address__last_old_value__dbg: bv32;
var acceptor1_ingress_my_ip_address__wrote_any__dbg: bool;
var acceptor1_ingress_my_ip_address__wrote_index0__dbg: bool;
var acceptor1_ingress_my_ip_address__last0_old_value__dbg: bv32;
var acceptor1_ingress_my_ip_address__last0_value__dbg: bv32;
var acceptor1_ingress_my_mac_address__dbg0: bv48;
var acceptor1_ingress_my_mac_address__last_index__dbg: bv32;
var acceptor1_ingress_my_mac_address__last_value__dbg: bv48;
var acceptor1_ingress_my_mac_address__last_old_value__dbg: bv48;
var acceptor1_ingress_my_mac_address__wrote_any__dbg: bool;
var acceptor1_ingress_my_mac_address__wrote_index0__dbg: bool;
var acceptor1_ingress_my_mac_address__last0_old_value__dbg: bv48;
var acceptor1_ingress_my_mac_address__last0_value__dbg: bv48;
var acceptor1_ingress_registerAcceptorID__dbg0: bv16;
var acceptor1_ingress_registerAcceptorID__last_index__dbg: bv32;
var acceptor1_ingress_registerAcceptorID__last_value__dbg: bv16;
var acceptor1_ingress_registerAcceptorID__last_old_value__dbg: bv16;
var acceptor1_ingress_registerAcceptorID__wrote_any__dbg: bool;
var acceptor1_ingress_registerAcceptorID__wrote_index0__dbg: bool;
var acceptor1_ingress_registerAcceptorID__last0_old_value__dbg: bv16;
var acceptor1_ingress_registerAcceptorID__last0_value__dbg: bv16;
var acceptor1_ingress_registerRound__dbg0: bv16;
var acceptor1_ingress_registerRound__last_index__dbg: bv32;
var acceptor1_ingress_registerRound__last_value__dbg: bv16;
var acceptor1_ingress_registerRound__last_old_value__dbg: bv16;
var acceptor1_ingress_registerRound__wrote_any__dbg: bool;
var acceptor1_ingress_registerRound__wrote_index0__dbg: bool;
var acceptor1_ingress_registerRound__last0_old_value__dbg: bv16;
var acceptor1_ingress_registerRound__last0_value__dbg: bv16;
var acceptor1_ingress_registerVRound__dbg0: bv16;
var acceptor1_ingress_registerVRound__last_index__dbg: bv32;
var acceptor1_ingress_registerVRound__last_value__dbg: bv16;
var acceptor1_ingress_registerVRound__last_old_value__dbg: bv16;
var acceptor1_ingress_registerVRound__wrote_any__dbg: bool;
var acceptor1_ingress_registerVRound__wrote_index0__dbg: bool;
var acceptor1_ingress_registerVRound__last0_old_value__dbg: bv16;
var acceptor1_ingress_registerVRound__last0_value__dbg: bv16;
var acceptor1_ingress_registerValue__dbg0: bv256;
var acceptor1_ingress_registerValue__last_index__dbg: bv32;
var acceptor1_ingress_registerValue__last_value__dbg: bv256;
var acceptor1_ingress_registerValue__last_old_value__dbg: bv256;
var acceptor1_ingress_registerValue__wrote_any__dbg: bool;
var acceptor1_ingress_registerValue__wrote_index0__dbg: bool;
var acceptor1_ingress_registerValue__last0_old_value__dbg: bv256;
var acceptor1_ingress_registerValue__last0_value__dbg: bv256;
var acceptor2_ingress_learner_address__dbg0: bv32;
var acceptor2_ingress_learner_address__last_index__dbg: bv32;
var acceptor2_ingress_learner_address__last_value__dbg: bv32;
var acceptor2_ingress_learner_address__last_old_value__dbg: bv32;
var acceptor2_ingress_learner_address__wrote_any__dbg: bool;
var acceptor2_ingress_learner_address__wrote_index0__dbg: bool;
var acceptor2_ingress_learner_address__last0_old_value__dbg: bv32;
var acceptor2_ingress_learner_address__last0_value__dbg: bv32;
var acceptor2_ingress_learner_mac_address__dbg0: bv48;
var acceptor2_ingress_learner_mac_address__last_index__dbg: bv32;
var acceptor2_ingress_learner_mac_address__last_value__dbg: bv48;
var acceptor2_ingress_learner_mac_address__last_old_value__dbg: bv48;
var acceptor2_ingress_learner_mac_address__wrote_any__dbg: bool;
var acceptor2_ingress_learner_mac_address__wrote_index0__dbg: bool;
var acceptor2_ingress_learner_mac_address__last0_old_value__dbg: bv48;
var acceptor2_ingress_learner_mac_address__last0_value__dbg: bv48;
var acceptor2_ingress_my_ip_address__dbg0: bv32;
var acceptor2_ingress_my_ip_address__last_index__dbg: bv32;
var acceptor2_ingress_my_ip_address__last_value__dbg: bv32;
var acceptor2_ingress_my_ip_address__last_old_value__dbg: bv32;
var acceptor2_ingress_my_ip_address__wrote_any__dbg: bool;
var acceptor2_ingress_my_ip_address__wrote_index0__dbg: bool;
var acceptor2_ingress_my_ip_address__last0_old_value__dbg: bv32;
var acceptor2_ingress_my_ip_address__last0_value__dbg: bv32;
var acceptor2_ingress_my_mac_address__dbg0: bv48;
var acceptor2_ingress_my_mac_address__last_index__dbg: bv32;
var acceptor2_ingress_my_mac_address__last_value__dbg: bv48;
var acceptor2_ingress_my_mac_address__last_old_value__dbg: bv48;
var acceptor2_ingress_my_mac_address__wrote_any__dbg: bool;
var acceptor2_ingress_my_mac_address__wrote_index0__dbg: bool;
var acceptor2_ingress_my_mac_address__last0_old_value__dbg: bv48;
var acceptor2_ingress_my_mac_address__last0_value__dbg: bv48;
var acceptor2_ingress_registerAcceptorID__dbg0: bv16;
var acceptor2_ingress_registerAcceptorID__last_index__dbg: bv32;
var acceptor2_ingress_registerAcceptorID__last_value__dbg: bv16;
var acceptor2_ingress_registerAcceptorID__last_old_value__dbg: bv16;
var acceptor2_ingress_registerAcceptorID__wrote_any__dbg: bool;
var acceptor2_ingress_registerAcceptorID__wrote_index0__dbg: bool;
var acceptor2_ingress_registerAcceptorID__last0_old_value__dbg: bv16;
var acceptor2_ingress_registerAcceptorID__last0_value__dbg: bv16;
var acceptor2_ingress_registerRound__dbg0: bv16;
var acceptor2_ingress_registerRound__last_index__dbg: bv32;
var acceptor2_ingress_registerRound__last_value__dbg: bv16;
var acceptor2_ingress_registerRound__last_old_value__dbg: bv16;
var acceptor2_ingress_registerRound__wrote_any__dbg: bool;
var acceptor2_ingress_registerRound__wrote_index0__dbg: bool;
var acceptor2_ingress_registerRound__last0_old_value__dbg: bv16;
var acceptor2_ingress_registerRound__last0_value__dbg: bv16;
var acceptor2_ingress_registerVRound__dbg0: bv16;
var acceptor2_ingress_registerVRound__last_index__dbg: bv32;
var acceptor2_ingress_registerVRound__last_value__dbg: bv16;
var acceptor2_ingress_registerVRound__last_old_value__dbg: bv16;
var acceptor2_ingress_registerVRound__wrote_any__dbg: bool;
var acceptor2_ingress_registerVRound__wrote_index0__dbg: bool;
var acceptor2_ingress_registerVRound__last0_old_value__dbg: bv16;
var acceptor2_ingress_registerVRound__last0_value__dbg: bv16;
var acceptor2_ingress_registerValue__dbg0: bv256;
var acceptor2_ingress_registerValue__last_index__dbg: bv32;
var acceptor2_ingress_registerValue__last_value__dbg: bv256;
var acceptor2_ingress_registerValue__last_old_value__dbg: bv256;
var acceptor2_ingress_registerValue__wrote_any__dbg: bool;
var acceptor2_ingress_registerValue__wrote_index0__dbg: bool;
var acceptor2_ingress_registerValue__last0_old_value__dbg: bv256;
var acceptor2_ingress_registerValue__last0_value__dbg: bv256;
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

var leader_inbox_count: int;
var acceptor0_inbox_count: int;
var acceptor1_inbox_count: int;
var acceptor2_inbox_count: int;
var learner_inbox_count: int;

var leader_pkt_external: bool;
var acceptor0_pkt_external: bool;
var acceptor1_pkt_external: bool;
var acceptor2_pkt_external: bool;
var learner_pkt_external: bool;

// Forwarding (derived from DSL topology)
procedure leader_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (leader_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure acceptor0_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (acceptor0_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure acceptor1_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (acceptor1_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure acceptor2_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (acceptor2_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

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

procedure main() returns()
  modifies acceptor0_drop, acceptor0_egress_place_holder_table.hit, acceptor0_forward, acceptor0_hdr.arp.hln, acceptor0_hdr.arp.hrd, acceptor0_hdr.arp.op, acceptor0_hdr.arp.pln, acceptor0_hdr.arp.pro, acceptor0_hdr.arp.sha, acceptor0_hdr.arp.spa, acceptor0_hdr.arp.tha, acceptor0_hdr.arp.tpa, acceptor0_hdr.arp.valid, acceptor0_hdr.ethernet.dstAddr, acceptor0_hdr.ethernet.etherType, acceptor0_hdr.ethernet.srcAddr, acceptor0_hdr.ethernet.valid, acceptor0_hdr.icmp.hdrChecksum, acceptor0_hdr.icmp.icmpCode, acceptor0_hdr.icmp.icmpType, acceptor0_hdr.icmp.identifier, acceptor0_hdr.icmp.payload, acceptor0_hdr.icmp.seqNumber, acceptor0_hdr.icmp.valid, acceptor0_hdr.ipv4.diffserv, acceptor0_hdr.ipv4.dstAddr, acceptor0_hdr.ipv4.flags, acceptor0_hdr.ipv4.fragOffset, acceptor0_hdr.ipv4.hdrChecksum, acceptor0_hdr.ipv4.identification, acceptor0_hdr.ipv4.ihl, acceptor0_hdr.ipv4.protocol, acceptor0_hdr.ipv4.srcAddr, acceptor0_hdr.ipv4.totalLen, acceptor0_hdr.ipv4.ttl, acceptor0_hdr.ipv4.valid, acceptor0_hdr.ipv4.version, acceptor0_hdr.paxos.acptid, acceptor0_hdr.paxos.inst, acceptor0_hdr.paxos.msgtype, acceptor0_hdr.paxos.paxoslen, acceptor0_hdr.paxos.paxosval, acceptor0_hdr.paxos.rnd, acceptor0_hdr.paxos.valid, acceptor0_hdr.paxos.vrnd, acceptor0_hdr.udp.checksum, acceptor0_hdr.udp.dstPort, acceptor0_hdr.udp.length_, acceptor0_hdr.udp.srcPort, acceptor0_hdr.udp.valid, acceptor0_inbox_count, acceptor0_ingress_acceptor_tbl.action_run, acceptor0_ingress_acceptor_tbl.hit, acceptor0_ingress_arp_tbl.action_run, acceptor0_ingress_arp_tbl.hit, acceptor0_ingress_icmp_tbl.action_run, acceptor0_ingress_icmp_tbl.hit, acceptor0_ingress_learner_address__dbg0, acceptor0_ingress_learner_address__last0_old_value, acceptor0_ingress_learner_address__last0_old_value__dbg, acceptor0_ingress_learner_address__last0_value, acceptor0_ingress_learner_address__last0_value__dbg, acceptor0_ingress_learner_address__last_index, acceptor0_ingress_learner_address__last_index__dbg, acceptor0_ingress_learner_address__last_old_value, acceptor0_ingress_learner_address__last_old_value__dbg, acceptor0_ingress_learner_address__last_value, acceptor0_ingress_learner_address__last_value__dbg, acceptor0_ingress_learner_address__last_write_site, acceptor0_ingress_learner_address__next_write_site, acceptor0_ingress_learner_address__wrote_any, acceptor0_ingress_learner_address__wrote_any__dbg, acceptor0_ingress_learner_address__wrote_index0, acceptor0_ingress_learner_address__wrote_index0__dbg, acceptor0_ingress_learner_mac_address__dbg0, acceptor0_ingress_learner_mac_address__last0_old_value, acceptor0_ingress_learner_mac_address__last0_old_value__dbg, acceptor0_ingress_learner_mac_address__last0_value, acceptor0_ingress_learner_mac_address__last0_value__dbg, acceptor0_ingress_learner_mac_address__last_index, acceptor0_ingress_learner_mac_address__last_index__dbg, acceptor0_ingress_learner_mac_address__last_old_value, acceptor0_ingress_learner_mac_address__last_old_value__dbg, acceptor0_ingress_learner_mac_address__last_value, acceptor0_ingress_learner_mac_address__last_value__dbg, acceptor0_ingress_learner_mac_address__last_write_site, acceptor0_ingress_learner_mac_address__next_write_site, acceptor0_ingress_learner_mac_address__wrote_any, acceptor0_ingress_learner_mac_address__wrote_any__dbg, acceptor0_ingress_learner_mac_address__wrote_index0, acceptor0_ingress_learner_mac_address__wrote_index0__dbg, acceptor0_ingress_my_ip_address__dbg0, acceptor0_ingress_my_ip_address__last0_old_value, acceptor0_ingress_my_ip_address__last0_old_value__dbg, acceptor0_ingress_my_ip_address__last0_value, acceptor0_ingress_my_ip_address__last0_value__dbg, acceptor0_ingress_my_ip_address__last_index, acceptor0_ingress_my_ip_address__last_index__dbg, acceptor0_ingress_my_ip_address__last_old_value, acceptor0_ingress_my_ip_address__last_old_value__dbg, acceptor0_ingress_my_ip_address__last_value, acceptor0_ingress_my_ip_address__last_value__dbg, acceptor0_ingress_my_ip_address__last_write_site, acceptor0_ingress_my_ip_address__next_write_site, acceptor0_ingress_my_ip_address__wrote_any, acceptor0_ingress_my_ip_address__wrote_any__dbg, acceptor0_ingress_my_ip_address__wrote_index0, acceptor0_ingress_my_ip_address__wrote_index0__dbg, acceptor0_ingress_my_mac_address__dbg0, acceptor0_ingress_my_mac_address__last0_old_value, acceptor0_ingress_my_mac_address__last0_old_value__dbg, acceptor0_ingress_my_mac_address__last0_value, acceptor0_ingress_my_mac_address__last0_value__dbg, acceptor0_ingress_my_mac_address__last_index, acceptor0_ingress_my_mac_address__last_index__dbg, acceptor0_ingress_my_mac_address__last_old_value, acceptor0_ingress_my_mac_address__last_old_value__dbg, acceptor0_ingress_my_mac_address__last_value, acceptor0_ingress_my_mac_address__last_value__dbg, acceptor0_ingress_my_mac_address__last_write_site, acceptor0_ingress_my_mac_address__next_write_site, acceptor0_ingress_my_mac_address__wrote_any, acceptor0_ingress_my_mac_address__wrote_any__dbg, acceptor0_ingress_my_mac_address__wrote_index0, acceptor0_ingress_my_mac_address__wrote_index0__dbg, acceptor0_ingress_registerAcceptorID__dbg0, acceptor0_ingress_registerAcceptorID__last0_old_value, acceptor0_ingress_registerAcceptorID__last0_old_value__dbg, acceptor0_ingress_registerAcceptorID__last0_value, acceptor0_ingress_registerAcceptorID__last0_value__dbg, acceptor0_ingress_registerAcceptorID__last_index, acceptor0_ingress_registerAcceptorID__last_index__dbg, acceptor0_ingress_registerAcceptorID__last_old_value, acceptor0_ingress_registerAcceptorID__last_old_value__dbg, acceptor0_ingress_registerAcceptorID__last_value, acceptor0_ingress_registerAcceptorID__last_value__dbg, acceptor0_ingress_registerAcceptorID__last_write_site, acceptor0_ingress_registerAcceptorID__next_write_site, acceptor0_ingress_registerAcceptorID__wrote_any, acceptor0_ingress_registerAcceptorID__wrote_any__dbg, acceptor0_ingress_registerAcceptorID__wrote_index0, acceptor0_ingress_registerAcceptorID__wrote_index0__dbg, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__dbg0, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_old_value__dbg, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last0_value__dbg, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_index__dbg, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_old_value__dbg, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_value__dbg, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_any__dbg, acceptor0_ingress_registerRound__wrote_index0, acceptor0_ingress_registerRound__wrote_index0__dbg, acceptor0_ingress_registerVRound, acceptor0_ingress_registerVRound__dbg0, acceptor0_ingress_registerVRound__last0_old_value, acceptor0_ingress_registerVRound__last0_old_value__dbg, acceptor0_ingress_registerVRound__last0_value, acceptor0_ingress_registerVRound__last0_value__dbg, acceptor0_ingress_registerVRound__last_index, acceptor0_ingress_registerVRound__last_index__dbg, acceptor0_ingress_registerVRound__last_old_value, acceptor0_ingress_registerVRound__last_old_value__dbg, acceptor0_ingress_registerVRound__last_value, acceptor0_ingress_registerVRound__last_value__dbg, acceptor0_ingress_registerVRound__last_write_site, acceptor0_ingress_registerVRound__next_write_site, acceptor0_ingress_registerVRound__wrote_any, acceptor0_ingress_registerVRound__wrote_any__dbg, acceptor0_ingress_registerVRound__wrote_index0, acceptor0_ingress_registerVRound__wrote_index0__dbg, acceptor0_ingress_registerValue, acceptor0_ingress_registerValue__dbg0, acceptor0_ingress_registerValue__last0_old_value, acceptor0_ingress_registerValue__last0_old_value__dbg, acceptor0_ingress_registerValue__last0_value, acceptor0_ingress_registerValue__last0_value__dbg, acceptor0_ingress_registerValue__last_index, acceptor0_ingress_registerValue__last_index__dbg, acceptor0_ingress_registerValue__last_old_value, acceptor0_ingress_registerValue__last_old_value__dbg, acceptor0_ingress_registerValue__last_value, acceptor0_ingress_registerValue__last_value__dbg, acceptor0_ingress_registerValue__last_write_site, acceptor0_ingress_registerValue__next_write_site, acceptor0_ingress_registerValue__wrote_any, acceptor0_ingress_registerValue__wrote_any__dbg, acceptor0_ingress_registerValue__wrote_index0, acceptor0_ingress_registerValue__wrote_index0__dbg, acceptor0_ingress_transport_tbl.action_run, acceptor0_ingress_transport_tbl.hit, acceptor0_ipdst_0, acceptor0_isValid, acceptor0_meta.paxos_metadata, acceptor0_meta.paxos_metadata.ack_acceptors, acceptor0_meta.paxos_metadata.ack_count, acceptor0_meta.paxos_metadata.round, acceptor0_meta.paxos_metadata.set_drop, acceptor0_p4b_checksum_error, acceptor0_p4b_checksum_updated, acceptor0_p4b_checksum_verified, acceptor0_p4b_clone_e2e, acceptor0_p4b_clone_i2e, acceptor0_p4b_clone_i2i, acceptor0_p4b_digest, acceptor0_p4b_recirculate, acceptor0_pkt_external, acceptor0_standard_metadata.checksum_error, acceptor0_standard_metadata.deq_qdepth, acceptor0_standard_metadata.deq_timedelta, acceptor0_standard_metadata.egress_global_timestamp, acceptor0_standard_metadata.egress_port, acceptor0_standard_metadata.egress_rid, acceptor0_standard_metadata.egress_spec, acceptor0_standard_metadata.enq_qdepth, acceptor0_standard_metadata.enq_timestamp, acceptor0_standard_metadata.ingress_global_timestamp, acceptor0_standard_metadata.ingress_port, acceptor0_standard_metadata.instance_type, acceptor0_standard_metadata.mcast_grp, acceptor0_standard_metadata.packet_length, acceptor0_standard_metadata.parser_error, acceptor0_standard_metadata.priority, acceptor1_drop, acceptor1_egress_place_holder_table.hit, acceptor1_forward, acceptor1_hdr.arp.hln, acceptor1_hdr.arp.hrd, acceptor1_hdr.arp.op, acceptor1_hdr.arp.pln, acceptor1_hdr.arp.pro, acceptor1_hdr.arp.sha, acceptor1_hdr.arp.spa, acceptor1_hdr.arp.tha, acceptor1_hdr.arp.tpa, acceptor1_hdr.arp.valid, acceptor1_hdr.ethernet.dstAddr, acceptor1_hdr.ethernet.etherType, acceptor1_hdr.ethernet.srcAddr, acceptor1_hdr.ethernet.valid, acceptor1_hdr.icmp.hdrChecksum, acceptor1_hdr.icmp.icmpCode, acceptor1_hdr.icmp.icmpType, acceptor1_hdr.icmp.identifier, acceptor1_hdr.icmp.payload, acceptor1_hdr.icmp.seqNumber, acceptor1_hdr.icmp.valid, acceptor1_hdr.ipv4.diffserv, acceptor1_hdr.ipv4.dstAddr, acceptor1_hdr.ipv4.flags, acceptor1_hdr.ipv4.fragOffset, acceptor1_hdr.ipv4.hdrChecksum, acceptor1_hdr.ipv4.identification, acceptor1_hdr.ipv4.ihl, acceptor1_hdr.ipv4.protocol, acceptor1_hdr.ipv4.srcAddr, acceptor1_hdr.ipv4.totalLen, acceptor1_hdr.ipv4.ttl, acceptor1_hdr.ipv4.valid, acceptor1_hdr.ipv4.version, acceptor1_hdr.paxos.acptid, acceptor1_hdr.paxos.inst, acceptor1_hdr.paxos.msgtype, acceptor1_hdr.paxos.paxoslen, acceptor1_hdr.paxos.paxosval, acceptor1_hdr.paxos.rnd, acceptor1_hdr.paxos.valid, acceptor1_hdr.paxos.vrnd, acceptor1_hdr.udp.checksum, acceptor1_hdr.udp.dstPort, acceptor1_hdr.udp.length_, acceptor1_hdr.udp.srcPort, acceptor1_hdr.udp.valid, acceptor1_inbox_count, acceptor1_ingress_acceptor_tbl.action_run, acceptor1_ingress_acceptor_tbl.hit, acceptor1_ingress_arp_tbl.action_run, acceptor1_ingress_arp_tbl.hit, acceptor1_ingress_icmp_tbl.action_run, acceptor1_ingress_icmp_tbl.hit, acceptor1_ingress_learner_address__dbg0, acceptor1_ingress_learner_address__last0_old_value, acceptor1_ingress_learner_address__last0_old_value__dbg, acceptor1_ingress_learner_address__last0_value, acceptor1_ingress_learner_address__last0_value__dbg, acceptor1_ingress_learner_address__last_index, acceptor1_ingress_learner_address__last_index__dbg, acceptor1_ingress_learner_address__last_old_value, acceptor1_ingress_learner_address__last_old_value__dbg, acceptor1_ingress_learner_address__last_value, acceptor1_ingress_learner_address__last_value__dbg, acceptor1_ingress_learner_address__last_write_site, acceptor1_ingress_learner_address__next_write_site, acceptor1_ingress_learner_address__wrote_any, acceptor1_ingress_learner_address__wrote_any__dbg, acceptor1_ingress_learner_address__wrote_index0, acceptor1_ingress_learner_address__wrote_index0__dbg, acceptor1_ingress_learner_mac_address__dbg0, acceptor1_ingress_learner_mac_address__last0_old_value, acceptor1_ingress_learner_mac_address__last0_old_value__dbg, acceptor1_ingress_learner_mac_address__last0_value, acceptor1_ingress_learner_mac_address__last0_value__dbg, acceptor1_ingress_learner_mac_address__last_index, acceptor1_ingress_learner_mac_address__last_index__dbg, acceptor1_ingress_learner_mac_address__last_old_value, acceptor1_ingress_learner_mac_address__last_old_value__dbg, acceptor1_ingress_learner_mac_address__last_value, acceptor1_ingress_learner_mac_address__last_value__dbg, acceptor1_ingress_learner_mac_address__last_write_site, acceptor1_ingress_learner_mac_address__next_write_site, acceptor1_ingress_learner_mac_address__wrote_any, acceptor1_ingress_learner_mac_address__wrote_any__dbg, acceptor1_ingress_learner_mac_address__wrote_index0, acceptor1_ingress_learner_mac_address__wrote_index0__dbg, acceptor1_ingress_my_ip_address__dbg0, acceptor1_ingress_my_ip_address__last0_old_value, acceptor1_ingress_my_ip_address__last0_old_value__dbg, acceptor1_ingress_my_ip_address__last0_value, acceptor1_ingress_my_ip_address__last0_value__dbg, acceptor1_ingress_my_ip_address__last_index, acceptor1_ingress_my_ip_address__last_index__dbg, acceptor1_ingress_my_ip_address__last_old_value, acceptor1_ingress_my_ip_address__last_old_value__dbg, acceptor1_ingress_my_ip_address__last_value, acceptor1_ingress_my_ip_address__last_value__dbg, acceptor1_ingress_my_ip_address__last_write_site, acceptor1_ingress_my_ip_address__next_write_site, acceptor1_ingress_my_ip_address__wrote_any, acceptor1_ingress_my_ip_address__wrote_any__dbg, acceptor1_ingress_my_ip_address__wrote_index0, acceptor1_ingress_my_ip_address__wrote_index0__dbg, acceptor1_ingress_my_mac_address__dbg0, acceptor1_ingress_my_mac_address__last0_old_value, acceptor1_ingress_my_mac_address__last0_old_value__dbg, acceptor1_ingress_my_mac_address__last0_value, acceptor1_ingress_my_mac_address__last0_value__dbg, acceptor1_ingress_my_mac_address__last_index, acceptor1_ingress_my_mac_address__last_index__dbg, acceptor1_ingress_my_mac_address__last_old_value, acceptor1_ingress_my_mac_address__last_old_value__dbg, acceptor1_ingress_my_mac_address__last_value, acceptor1_ingress_my_mac_address__last_value__dbg, acceptor1_ingress_my_mac_address__last_write_site, acceptor1_ingress_my_mac_address__next_write_site, acceptor1_ingress_my_mac_address__wrote_any, acceptor1_ingress_my_mac_address__wrote_any__dbg, acceptor1_ingress_my_mac_address__wrote_index0, acceptor1_ingress_my_mac_address__wrote_index0__dbg, acceptor1_ingress_registerAcceptorID__dbg0, acceptor1_ingress_registerAcceptorID__last0_old_value, acceptor1_ingress_registerAcceptorID__last0_old_value__dbg, acceptor1_ingress_registerAcceptorID__last0_value, acceptor1_ingress_registerAcceptorID__last0_value__dbg, acceptor1_ingress_registerAcceptorID__last_index, acceptor1_ingress_registerAcceptorID__last_index__dbg, acceptor1_ingress_registerAcceptorID__last_old_value, acceptor1_ingress_registerAcceptorID__last_old_value__dbg, acceptor1_ingress_registerAcceptorID__last_value, acceptor1_ingress_registerAcceptorID__last_value__dbg, acceptor1_ingress_registerAcceptorID__last_write_site, acceptor1_ingress_registerAcceptorID__next_write_site, acceptor1_ingress_registerAcceptorID__wrote_any, acceptor1_ingress_registerAcceptorID__wrote_any__dbg, acceptor1_ingress_registerAcceptorID__wrote_index0, acceptor1_ingress_registerAcceptorID__wrote_index0__dbg, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__dbg0, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_old_value__dbg, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last0_value__dbg, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_index__dbg, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_old_value__dbg, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_value__dbg, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_any__dbg, acceptor1_ingress_registerRound__wrote_index0, acceptor1_ingress_registerRound__wrote_index0__dbg, acceptor1_ingress_registerVRound, acceptor1_ingress_registerVRound__dbg0, acceptor1_ingress_registerVRound__last0_old_value, acceptor1_ingress_registerVRound__last0_old_value__dbg, acceptor1_ingress_registerVRound__last0_value, acceptor1_ingress_registerVRound__last0_value__dbg, acceptor1_ingress_registerVRound__last_index, acceptor1_ingress_registerVRound__last_index__dbg, acceptor1_ingress_registerVRound__last_old_value, acceptor1_ingress_registerVRound__last_old_value__dbg, acceptor1_ingress_registerVRound__last_value, acceptor1_ingress_registerVRound__last_value__dbg, acceptor1_ingress_registerVRound__last_write_site, acceptor1_ingress_registerVRound__next_write_site, acceptor1_ingress_registerVRound__wrote_any, acceptor1_ingress_registerVRound__wrote_any__dbg, acceptor1_ingress_registerVRound__wrote_index0, acceptor1_ingress_registerVRound__wrote_index0__dbg, acceptor1_ingress_registerValue, acceptor1_ingress_registerValue__dbg0, acceptor1_ingress_registerValue__last0_old_value, acceptor1_ingress_registerValue__last0_old_value__dbg, acceptor1_ingress_registerValue__last0_value, acceptor1_ingress_registerValue__last0_value__dbg, acceptor1_ingress_registerValue__last_index, acceptor1_ingress_registerValue__last_index__dbg, acceptor1_ingress_registerValue__last_old_value, acceptor1_ingress_registerValue__last_old_value__dbg, acceptor1_ingress_registerValue__last_value, acceptor1_ingress_registerValue__last_value__dbg, acceptor1_ingress_registerValue__last_write_site, acceptor1_ingress_registerValue__next_write_site, acceptor1_ingress_registerValue__wrote_any, acceptor1_ingress_registerValue__wrote_any__dbg, acceptor1_ingress_registerValue__wrote_index0, acceptor1_ingress_registerValue__wrote_index0__dbg, acceptor1_ingress_transport_tbl.action_run, acceptor1_ingress_transport_tbl.hit, acceptor1_ipdst_0, acceptor1_isValid, acceptor1_meta.paxos_metadata, acceptor1_meta.paxos_metadata.ack_acceptors, acceptor1_meta.paxos_metadata.ack_count, acceptor1_meta.paxos_metadata.round, acceptor1_meta.paxos_metadata.set_drop, acceptor1_p4b_checksum_error, acceptor1_p4b_checksum_updated, acceptor1_p4b_checksum_verified, acceptor1_p4b_clone_e2e, acceptor1_p4b_clone_i2e, acceptor1_p4b_clone_i2i, acceptor1_p4b_digest, acceptor1_p4b_recirculate, acceptor1_pkt_external, acceptor1_standard_metadata.checksum_error, acceptor1_standard_metadata.deq_qdepth, acceptor1_standard_metadata.deq_timedelta, acceptor1_standard_metadata.egress_global_timestamp, acceptor1_standard_metadata.egress_port, acceptor1_standard_metadata.egress_rid, acceptor1_standard_metadata.egress_spec, acceptor1_standard_metadata.enq_qdepth, acceptor1_standard_metadata.enq_timestamp, acceptor1_standard_metadata.ingress_global_timestamp, acceptor1_standard_metadata.ingress_port, acceptor1_standard_metadata.instance_type, acceptor1_standard_metadata.mcast_grp, acceptor1_standard_metadata.packet_length, acceptor1_standard_metadata.parser_error, acceptor1_standard_metadata.priority, acceptor2_drop, acceptor2_egress_place_holder_table.hit, acceptor2_forward, acceptor2_hdr.arp.hln, acceptor2_hdr.arp.hrd, acceptor2_hdr.arp.op, acceptor2_hdr.arp.pln, acceptor2_hdr.arp.pro, acceptor2_hdr.arp.sha, acceptor2_hdr.arp.spa, acceptor2_hdr.arp.tha, acceptor2_hdr.arp.tpa, acceptor2_hdr.arp.valid, acceptor2_hdr.ethernet.dstAddr, acceptor2_hdr.ethernet.etherType, acceptor2_hdr.ethernet.srcAddr, acceptor2_hdr.ethernet.valid, acceptor2_hdr.icmp.hdrChecksum, acceptor2_hdr.icmp.icmpCode, acceptor2_hdr.icmp.icmpType, acceptor2_hdr.icmp.identifier, acceptor2_hdr.icmp.payload, acceptor2_hdr.icmp.seqNumber, acceptor2_hdr.icmp.valid, acceptor2_hdr.ipv4.diffserv, acceptor2_hdr.ipv4.dstAddr, acceptor2_hdr.ipv4.flags, acceptor2_hdr.ipv4.fragOffset, acceptor2_hdr.ipv4.hdrChecksum, acceptor2_hdr.ipv4.identification, acceptor2_hdr.ipv4.ihl, acceptor2_hdr.ipv4.protocol, acceptor2_hdr.ipv4.srcAddr, acceptor2_hdr.ipv4.totalLen, acceptor2_hdr.ipv4.ttl, acceptor2_hdr.ipv4.valid, acceptor2_hdr.ipv4.version, acceptor2_hdr.paxos.acptid, acceptor2_hdr.paxos.inst, acceptor2_hdr.paxos.msgtype, acceptor2_hdr.paxos.paxoslen, acceptor2_hdr.paxos.paxosval, acceptor2_hdr.paxos.rnd, acceptor2_hdr.paxos.valid, acceptor2_hdr.paxos.vrnd, acceptor2_hdr.udp.checksum, acceptor2_hdr.udp.dstPort, acceptor2_hdr.udp.length_, acceptor2_hdr.udp.srcPort, acceptor2_hdr.udp.valid, acceptor2_inbox_count, acceptor2_ingress_acceptor_tbl.action_run, acceptor2_ingress_acceptor_tbl.hit, acceptor2_ingress_arp_tbl.action_run, acceptor2_ingress_arp_tbl.hit, acceptor2_ingress_icmp_tbl.action_run, acceptor2_ingress_icmp_tbl.hit, acceptor2_ingress_learner_address__dbg0, acceptor2_ingress_learner_address__last0_old_value, acceptor2_ingress_learner_address__last0_old_value__dbg, acceptor2_ingress_learner_address__last0_value, acceptor2_ingress_learner_address__last0_value__dbg, acceptor2_ingress_learner_address__last_index, acceptor2_ingress_learner_address__last_index__dbg, acceptor2_ingress_learner_address__last_old_value, acceptor2_ingress_learner_address__last_old_value__dbg, acceptor2_ingress_learner_address__last_value, acceptor2_ingress_learner_address__last_value__dbg, acceptor2_ingress_learner_address__last_write_site, acceptor2_ingress_learner_address__next_write_site, acceptor2_ingress_learner_address__wrote_any, acceptor2_ingress_learner_address__wrote_any__dbg, acceptor2_ingress_learner_address__wrote_index0, acceptor2_ingress_learner_address__wrote_index0__dbg, acceptor2_ingress_learner_mac_address__dbg0, acceptor2_ingress_learner_mac_address__last0_old_value, acceptor2_ingress_learner_mac_address__last0_old_value__dbg, acceptor2_ingress_learner_mac_address__last0_value, acceptor2_ingress_learner_mac_address__last0_value__dbg, acceptor2_ingress_learner_mac_address__last_index, acceptor2_ingress_learner_mac_address__last_index__dbg, acceptor2_ingress_learner_mac_address__last_old_value, acceptor2_ingress_learner_mac_address__last_old_value__dbg, acceptor2_ingress_learner_mac_address__last_value, acceptor2_ingress_learner_mac_address__last_value__dbg, acceptor2_ingress_learner_mac_address__last_write_site, acceptor2_ingress_learner_mac_address__next_write_site, acceptor2_ingress_learner_mac_address__wrote_any, acceptor2_ingress_learner_mac_address__wrote_any__dbg, acceptor2_ingress_learner_mac_address__wrote_index0, acceptor2_ingress_learner_mac_address__wrote_index0__dbg, acceptor2_ingress_my_ip_address__dbg0, acceptor2_ingress_my_ip_address__last0_old_value, acceptor2_ingress_my_ip_address__last0_old_value__dbg, acceptor2_ingress_my_ip_address__last0_value, acceptor2_ingress_my_ip_address__last0_value__dbg, acceptor2_ingress_my_ip_address__last_index, acceptor2_ingress_my_ip_address__last_index__dbg, acceptor2_ingress_my_ip_address__last_old_value, acceptor2_ingress_my_ip_address__last_old_value__dbg, acceptor2_ingress_my_ip_address__last_value, acceptor2_ingress_my_ip_address__last_value__dbg, acceptor2_ingress_my_ip_address__last_write_site, acceptor2_ingress_my_ip_address__next_write_site, acceptor2_ingress_my_ip_address__wrote_any, acceptor2_ingress_my_ip_address__wrote_any__dbg, acceptor2_ingress_my_ip_address__wrote_index0, acceptor2_ingress_my_ip_address__wrote_index0__dbg, acceptor2_ingress_my_mac_address__dbg0, acceptor2_ingress_my_mac_address__last0_old_value, acceptor2_ingress_my_mac_address__last0_old_value__dbg, acceptor2_ingress_my_mac_address__last0_value, acceptor2_ingress_my_mac_address__last0_value__dbg, acceptor2_ingress_my_mac_address__last_index, acceptor2_ingress_my_mac_address__last_index__dbg, acceptor2_ingress_my_mac_address__last_old_value, acceptor2_ingress_my_mac_address__last_old_value__dbg, acceptor2_ingress_my_mac_address__last_value, acceptor2_ingress_my_mac_address__last_value__dbg, acceptor2_ingress_my_mac_address__last_write_site, acceptor2_ingress_my_mac_address__next_write_site, acceptor2_ingress_my_mac_address__wrote_any, acceptor2_ingress_my_mac_address__wrote_any__dbg, acceptor2_ingress_my_mac_address__wrote_index0, acceptor2_ingress_my_mac_address__wrote_index0__dbg, acceptor2_ingress_registerAcceptorID__dbg0, acceptor2_ingress_registerAcceptorID__last0_old_value, acceptor2_ingress_registerAcceptorID__last0_old_value__dbg, acceptor2_ingress_registerAcceptorID__last0_value, acceptor2_ingress_registerAcceptorID__last0_value__dbg, acceptor2_ingress_registerAcceptorID__last_index, acceptor2_ingress_registerAcceptorID__last_index__dbg, acceptor2_ingress_registerAcceptorID__last_old_value, acceptor2_ingress_registerAcceptorID__last_old_value__dbg, acceptor2_ingress_registerAcceptorID__last_value, acceptor2_ingress_registerAcceptorID__last_value__dbg, acceptor2_ingress_registerAcceptorID__last_write_site, acceptor2_ingress_registerAcceptorID__next_write_site, acceptor2_ingress_registerAcceptorID__wrote_any, acceptor2_ingress_registerAcceptorID__wrote_any__dbg, acceptor2_ingress_registerAcceptorID__wrote_index0, acceptor2_ingress_registerAcceptorID__wrote_index0__dbg, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__dbg0, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_old_value__dbg, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last0_value__dbg, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_index__dbg, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_old_value__dbg, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_value__dbg, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_any__dbg, acceptor2_ingress_registerRound__wrote_index0, acceptor2_ingress_registerRound__wrote_index0__dbg, acceptor2_ingress_registerVRound, acceptor2_ingress_registerVRound__dbg0, acceptor2_ingress_registerVRound__last0_old_value, acceptor2_ingress_registerVRound__last0_old_value__dbg, acceptor2_ingress_registerVRound__last0_value, acceptor2_ingress_registerVRound__last0_value__dbg, acceptor2_ingress_registerVRound__last_index, acceptor2_ingress_registerVRound__last_index__dbg, acceptor2_ingress_registerVRound__last_old_value, acceptor2_ingress_registerVRound__last_old_value__dbg, acceptor2_ingress_registerVRound__last_value, acceptor2_ingress_registerVRound__last_value__dbg, acceptor2_ingress_registerVRound__last_write_site, acceptor2_ingress_registerVRound__next_write_site, acceptor2_ingress_registerVRound__wrote_any, acceptor2_ingress_registerVRound__wrote_any__dbg, acceptor2_ingress_registerVRound__wrote_index0, acceptor2_ingress_registerVRound__wrote_index0__dbg, acceptor2_ingress_registerValue, acceptor2_ingress_registerValue__dbg0, acceptor2_ingress_registerValue__last0_old_value, acceptor2_ingress_registerValue__last0_old_value__dbg, acceptor2_ingress_registerValue__last0_value, acceptor2_ingress_registerValue__last0_value__dbg, acceptor2_ingress_registerValue__last_index, acceptor2_ingress_registerValue__last_index__dbg, acceptor2_ingress_registerValue__last_old_value, acceptor2_ingress_registerValue__last_old_value__dbg, acceptor2_ingress_registerValue__last_value, acceptor2_ingress_registerValue__last_value__dbg, acceptor2_ingress_registerValue__last_write_site, acceptor2_ingress_registerValue__next_write_site, acceptor2_ingress_registerValue__wrote_any, acceptor2_ingress_registerValue__wrote_any__dbg, acceptor2_ingress_registerValue__wrote_index0, acceptor2_ingress_registerValue__wrote_index0__dbg, acceptor2_ingress_transport_tbl.action_run, acceptor2_ingress_transport_tbl.hit, acceptor2_ipdst_0, acceptor2_isValid, acceptor2_meta.paxos_metadata, acceptor2_meta.paxos_metadata.ack_acceptors, acceptor2_meta.paxos_metadata.ack_count, acceptor2_meta.paxos_metadata.round, acceptor2_meta.paxos_metadata.set_drop, acceptor2_p4b_checksum_error, acceptor2_p4b_checksum_updated, acceptor2_p4b_checksum_verified, acceptor2_p4b_clone_e2e, acceptor2_p4b_clone_i2e, acceptor2_p4b_clone_i2i, acceptor2_p4b_digest, acceptor2_p4b_recirculate, acceptor2_pkt_external, acceptor2_standard_metadata.checksum_error, acceptor2_standard_metadata.deq_qdepth, acceptor2_standard_metadata.deq_timedelta, acceptor2_standard_metadata.egress_global_timestamp, acceptor2_standard_metadata.egress_port, acceptor2_standard_metadata.egress_rid, acceptor2_standard_metadata.egress_spec, acceptor2_standard_metadata.enq_qdepth, acceptor2_standard_metadata.enq_timestamp, acceptor2_standard_metadata.ingress_global_timestamp, acceptor2_standard_metadata.ingress_port, acceptor2_standard_metadata.instance_type, acceptor2_standard_metadata.mcast_grp, acceptor2_standard_metadata.packet_length, acceptor2_standard_metadata.parser_error, acceptor2_standard_metadata.priority, leader_current_instance_0, leader_drop, leader_egress_place_holder_table.hit, leader_forward, leader_hdr.arp.hln, leader_hdr.arp.hrd, leader_hdr.arp.op, leader_hdr.arp.pln, leader_hdr.arp.pro, leader_hdr.arp.sha, leader_hdr.arp.spa, leader_hdr.arp.tha, leader_hdr.arp.tpa, leader_hdr.arp.valid, leader_hdr.ethernet.dstAddr, leader_hdr.ethernet.etherType, leader_hdr.ethernet.srcAddr, leader_hdr.ethernet.valid, leader_hdr.icmp.hdrChecksum, leader_hdr.icmp.icmpCode, leader_hdr.icmp.icmpType, leader_hdr.icmp.identifier, leader_hdr.icmp.payload, leader_hdr.icmp.seqNumber, leader_hdr.icmp.valid, leader_hdr.ipv4.diffserv, leader_hdr.ipv4.dstAddr, leader_hdr.ipv4.flags, leader_hdr.ipv4.fragOffset, leader_hdr.ipv4.hdrChecksum, leader_hdr.ipv4.identification, leader_hdr.ipv4.ihl, leader_hdr.ipv4.protocol, leader_hdr.ipv4.srcAddr, leader_hdr.ipv4.totalLen, leader_hdr.ipv4.ttl, leader_hdr.ipv4.valid, leader_hdr.ipv4.version, leader_hdr.paxos.acptid, leader_hdr.paxos.inst, leader_hdr.paxos.msgtype, leader_hdr.paxos.paxoslen, leader_hdr.paxos.paxosval, leader_hdr.paxos.rnd, leader_hdr.paxos.valid, leader_hdr.paxos.vrnd, leader_hdr.udp.checksum, leader_hdr.udp.dstPort, leader_hdr.udp.length_, leader_hdr.udp.srcPort, leader_hdr.udp.valid, leader_inbox_count, leader_index_0, leader_index_1, leader_ingress_ctrlInstane, leader_ingress_ctrlInstane__dbg0, leader_ingress_ctrlInstane__last0_old_value, leader_ingress_ctrlInstane__last0_old_value__dbg, leader_ingress_ctrlInstane__last0_value, leader_ingress_ctrlInstane__last0_value__dbg, leader_ingress_ctrlInstane__last_index, leader_ingress_ctrlInstane__last_index__dbg, leader_ingress_ctrlInstane__last_old_value, leader_ingress_ctrlInstane__last_old_value__dbg, leader_ingress_ctrlInstane__last_value, leader_ingress_ctrlInstane__last_value__dbg, leader_ingress_ctrlInstane__last_write_site, leader_ingress_ctrlInstane__next_write_site, leader_ingress_ctrlInstane__wrote_any, leader_ingress_ctrlInstane__wrote_any__dbg, leader_ingress_ctrlInstane__wrote_index0, leader_ingress_ctrlInstane__wrote_index0__dbg, leader_ingress_leader_tbl.action_run, leader_ingress_leader_tbl.hit, leader_ingress_transport_tbl.action_run, leader_ingress_transport_tbl.hit, leader_isValid, leader_meta.paxos_metadata, leader_meta.paxos_metadata.ack_acceptors, leader_meta.paxos_metadata.ack_count, leader_meta.paxos_metadata.round, leader_meta.paxos_metadata.set_drop, leader_p4b_checksum_error, leader_p4b_checksum_updated, leader_p4b_checksum_verified, leader_p4b_clone_e2e, leader_p4b_clone_i2e, leader_p4b_clone_i2i, leader_p4b_digest, leader_p4b_recirculate, leader_pkt_external, leader_reset_value_0, leader_standard_metadata.checksum_error, leader_standard_metadata.deq_qdepth, leader_standard_metadata.deq_timedelta, leader_standard_metadata.egress_global_timestamp, leader_standard_metadata.egress_port, leader_standard_metadata.egress_rid, leader_standard_metadata.egress_spec, leader_standard_metadata.enq_qdepth, leader_standard_metadata.enq_timestamp, leader_standard_metadata.ingress_global_timestamp, leader_standard_metadata.ingress_port, leader_standard_metadata.instance_type, leader_standard_metadata.mcast_grp, leader_standard_metadata.packet_length, leader_standard_metadata.parser_error, leader_standard_metadata.priority, learner_acptid_0, learner_acptid_1, learner_drop, learner_egress_place_holder_table.hit, learner_forward, learner_hdr.arp.hln, learner_hdr.arp.hrd, learner_hdr.arp.op, learner_hdr.arp.pln, learner_hdr.arp.pro, learner_hdr.arp.sha, learner_hdr.arp.spa, learner_hdr.arp.tha, learner_hdr.arp.tpa, learner_hdr.arp.valid, learner_hdr.ethernet.dstAddr, learner_hdr.ethernet.etherType, learner_hdr.ethernet.srcAddr, learner_hdr.ethernet.valid, learner_hdr.icmp.hdrChecksum, learner_hdr.icmp.icmpCode, learner_hdr.icmp.icmpType, learner_hdr.icmp.identifier, learner_hdr.icmp.payload, learner_hdr.icmp.seqNumber, learner_hdr.icmp.valid, learner_hdr.ipv4.diffserv, learner_hdr.ipv4.dstAddr, learner_hdr.ipv4.flags, learner_hdr.ipv4.fragOffset, learner_hdr.ipv4.hdrChecksum, learner_hdr.ipv4.identification, learner_hdr.ipv4.ihl, learner_hdr.ipv4.protocol, learner_hdr.ipv4.srcAddr, learner_hdr.ipv4.totalLen, learner_hdr.ipv4.ttl, learner_hdr.ipv4.valid, learner_hdr.ipv4.version, learner_hdr.paxos.acptid, learner_hdr.paxos.inst, learner_hdr.paxos.msgtype, learner_hdr.paxos.paxoslen, learner_hdr.paxos.paxosval, learner_hdr.paxos.rnd, learner_hdr.paxos.valid, learner_hdr.paxos.vrnd, learner_hdr.udp.checksum, learner_hdr.udp.dstPort, learner_hdr.udp.length_, learner_hdr.udp.srcPort, learner_hdr.udp.valid, learner_inbox_count, learner_ingress_learner_tbl.action_run, learner_ingress_learner_tbl.hit, learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__dbg0, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_old_value__dbg, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last0_value__dbg, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_index__dbg, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_old_value__dbg, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_value__dbg, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__next_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_any__dbg, learner_ingress_registerHistory2B__wrote_index0, learner_ingress_registerHistory2B__wrote_index0__dbg, learner_ingress_registerRound, learner_ingress_registerRound__dbg0, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_old_value__dbg, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last0_value__dbg, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_index__dbg, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_old_value__dbg, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_value__dbg, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__next_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_any__dbg, learner_ingress_registerRound__wrote_index0, learner_ingress_registerRound__wrote_index0__dbg, learner_ingress_registerValue, learner_ingress_registerValue__dbg0, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_old_value__dbg, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last0_value__dbg, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_index__dbg, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_old_value__dbg, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_value__dbg, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__next_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_any__dbg, learner_ingress_registerValue__wrote_index0, learner_ingress_registerValue__wrote_index0__dbg, learner_ingress_reset_consensus_instance.action_run, learner_ingress_reset_consensus_instance.hit, learner_ingress_transport_tbl.action_run, learner_ingress_transport_tbl.hit, learner_isValid, learner_meta.paxos_metadata, learner_meta.paxos_metadata.ack_acceptors, learner_meta.paxos_metadata.ack_count, learner_meta.paxos_metadata.round, learner_meta.paxos_metadata.set_drop, learner_p4b_checksum_error, learner_p4b_checksum_updated, learner_p4b_checksum_verified, learner_p4b_clone_e2e, learner_p4b_clone_i2e, learner_p4b_clone_i2i, learner_p4b_digest, learner_p4b_recirculate, learner_pkt_external, learner_standard_metadata.checksum_error, learner_standard_metadata.deq_qdepth, learner_standard_metadata.deq_timedelta, learner_standard_metadata.egress_global_timestamp, learner_standard_metadata.egress_port, learner_standard_metadata.egress_rid, learner_standard_metadata.egress_spec, learner_standard_metadata.enq_qdepth, learner_standard_metadata.enq_timestamp, learner_standard_metadata.ingress_global_timestamp, learner_standard_metadata.ingress_port, learner_standard_metadata.instance_type, learner_standard_metadata.mcast_grp, learner_standard_metadata.packet_length, learner_standard_metadata.parser_error, learner_standard_metadata.priority, procurator_step;
{
  // One scheduler step: pick exactly one action.
  if (*) {
    // env inject -> leader
    assume leader_inbox_count < 3;
    leader_pkt_external := true;
    havoc leader_standard_metadata.ingress_port;
    havoc leader_standard_metadata.instance_type;
    havoc leader_standard_metadata.packet_length;
    havoc leader_standard_metadata.enq_timestamp;
    havoc leader_standard_metadata.enq_qdepth;
    havoc leader_standard_metadata.deq_timedelta;
    havoc leader_standard_metadata.deq_qdepth;
    havoc leader_standard_metadata.ingress_global_timestamp;
    havoc leader_standard_metadata.egress_global_timestamp;
    havoc leader_standard_metadata.mcast_grp;
    havoc leader_standard_metadata.egress_rid;
    havoc leader_standard_metadata.checksum_error;
    havoc leader_standard_metadata.parser_error;
    havoc leader_standard_metadata.priority;
    havoc leader_hdr.ethernet.valid;
    havoc leader_hdr.ethernet.dstAddr;
    havoc leader_hdr.ethernet.srcAddr;
    havoc leader_hdr.ethernet.etherType;
    havoc leader_hdr.arp.valid;
    havoc leader_hdr.arp.hrd;
    havoc leader_hdr.arp.pro;
    havoc leader_hdr.arp.hln;
    havoc leader_hdr.arp.pln;
    havoc leader_hdr.arp.op;
    havoc leader_hdr.arp.sha;
    havoc leader_hdr.arp.spa;
    havoc leader_hdr.arp.tha;
    havoc leader_hdr.arp.tpa;
    havoc leader_hdr.ipv4.valid;
    havoc leader_hdr.ipv4.version;
    havoc leader_hdr.ipv4.ihl;
    havoc leader_hdr.ipv4.diffserv;
    havoc leader_hdr.ipv4.totalLen;
    havoc leader_hdr.ipv4.identification;
    havoc leader_hdr.ipv4.flags;
    havoc leader_hdr.ipv4.fragOffset;
    havoc leader_hdr.ipv4.ttl;
    havoc leader_hdr.ipv4.protocol;
    havoc leader_hdr.ipv4.hdrChecksum;
    havoc leader_hdr.ipv4.srcAddr;
    havoc leader_hdr.ipv4.dstAddr;
    havoc leader_hdr.icmp.valid;
    havoc leader_hdr.icmp.icmpType;
    havoc leader_hdr.icmp.icmpCode;
    havoc leader_hdr.icmp.hdrChecksum;
    havoc leader_hdr.icmp.identifier;
    havoc leader_hdr.icmp.seqNumber;
    havoc leader_hdr.icmp.payload;
    havoc leader_hdr.udp.valid;
    havoc leader_hdr.udp.srcPort;
    havoc leader_hdr.udp.dstPort;
    havoc leader_hdr.udp.length_;
    havoc leader_hdr.udp.checksum;
    havoc leader_hdr.paxos.valid;
    havoc leader_hdr.paxos.msgtype;
    havoc leader_hdr.paxos.inst;
    havoc leader_hdr.paxos.rnd;
    havoc leader_hdr.paxos.vrnd;
    havoc leader_hdr.paxos.acptid;
    havoc leader_hdr.paxos.paxoslen;
    havoc leader_hdr.paxos.paxosval;
    havoc leader_meta.paxos_metadata;
    havoc leader_meta.paxos_metadata.round;
    havoc leader_meta.paxos_metadata.set_drop;
    havoc leader_meta.paxos_metadata.ack_count;
    havoc leader_meta.paxos_metadata.ack_acceptors;
    leader_inbox_count := leader_inbox_count + 1;
  } else if (*) {
    // env inject -> acceptor0
    assume acceptor0_inbox_count < 3;
    acceptor0_pkt_external := true;
    havoc acceptor0_standard_metadata.ingress_port;
    havoc acceptor0_standard_metadata.instance_type;
    havoc acceptor0_standard_metadata.packet_length;
    havoc acceptor0_standard_metadata.enq_timestamp;
    havoc acceptor0_standard_metadata.enq_qdepth;
    havoc acceptor0_standard_metadata.deq_timedelta;
    havoc acceptor0_standard_metadata.deq_qdepth;
    havoc acceptor0_standard_metadata.ingress_global_timestamp;
    havoc acceptor0_standard_metadata.egress_global_timestamp;
    havoc acceptor0_standard_metadata.mcast_grp;
    havoc acceptor0_standard_metadata.egress_rid;
    havoc acceptor0_standard_metadata.checksum_error;
    havoc acceptor0_standard_metadata.parser_error;
    havoc acceptor0_standard_metadata.priority;
    havoc acceptor0_hdr.ethernet.valid;
    havoc acceptor0_hdr.ethernet.dstAddr;
    havoc acceptor0_hdr.ethernet.srcAddr;
    havoc acceptor0_hdr.ethernet.etherType;
    havoc acceptor0_hdr.arp.valid;
    havoc acceptor0_hdr.arp.hrd;
    havoc acceptor0_hdr.arp.pro;
    havoc acceptor0_hdr.arp.hln;
    havoc acceptor0_hdr.arp.pln;
    havoc acceptor0_hdr.arp.op;
    havoc acceptor0_hdr.arp.sha;
    havoc acceptor0_hdr.arp.spa;
    havoc acceptor0_hdr.arp.tha;
    havoc acceptor0_hdr.arp.tpa;
    havoc acceptor0_hdr.ipv4.valid;
    havoc acceptor0_hdr.ipv4.version;
    havoc acceptor0_hdr.ipv4.ihl;
    havoc acceptor0_hdr.ipv4.diffserv;
    havoc acceptor0_hdr.ipv4.totalLen;
    havoc acceptor0_hdr.ipv4.identification;
    havoc acceptor0_hdr.ipv4.flags;
    havoc acceptor0_hdr.ipv4.fragOffset;
    havoc acceptor0_hdr.ipv4.ttl;
    havoc acceptor0_hdr.ipv4.protocol;
    havoc acceptor0_hdr.ipv4.hdrChecksum;
    havoc acceptor0_hdr.ipv4.srcAddr;
    havoc acceptor0_hdr.ipv4.dstAddr;
    havoc acceptor0_hdr.icmp.valid;
    havoc acceptor0_hdr.icmp.icmpType;
    havoc acceptor0_hdr.icmp.icmpCode;
    havoc acceptor0_hdr.icmp.hdrChecksum;
    havoc acceptor0_hdr.icmp.identifier;
    havoc acceptor0_hdr.icmp.seqNumber;
    havoc acceptor0_hdr.icmp.payload;
    havoc acceptor0_hdr.udp.valid;
    havoc acceptor0_hdr.udp.srcPort;
    havoc acceptor0_hdr.udp.dstPort;
    havoc acceptor0_hdr.udp.length_;
    havoc acceptor0_hdr.udp.checksum;
    havoc acceptor0_hdr.paxos.valid;
    havoc acceptor0_hdr.paxos.msgtype;
    havoc acceptor0_hdr.paxos.inst;
    havoc acceptor0_hdr.paxos.rnd;
    havoc acceptor0_hdr.paxos.vrnd;
    havoc acceptor0_hdr.paxos.acptid;
    havoc acceptor0_hdr.paxos.paxoslen;
    havoc acceptor0_hdr.paxos.paxosval;
    havoc acceptor0_meta.paxos_metadata;
    havoc acceptor0_meta.paxos_metadata.round;
    havoc acceptor0_meta.paxos_metadata.set_drop;
    havoc acceptor0_meta.paxos_metadata.ack_count;
    havoc acceptor0_meta.paxos_metadata.ack_acceptors;
    acceptor0_inbox_count := acceptor0_inbox_count + 1;
  } else if (*) {
    // env inject -> acceptor1
    assume acceptor1_inbox_count < 3;
    acceptor1_pkt_external := true;
    havoc acceptor1_standard_metadata.ingress_port;
    havoc acceptor1_standard_metadata.instance_type;
    havoc acceptor1_standard_metadata.packet_length;
    havoc acceptor1_standard_metadata.enq_timestamp;
    havoc acceptor1_standard_metadata.enq_qdepth;
    havoc acceptor1_standard_metadata.deq_timedelta;
    havoc acceptor1_standard_metadata.deq_qdepth;
    havoc acceptor1_standard_metadata.ingress_global_timestamp;
    havoc acceptor1_standard_metadata.egress_global_timestamp;
    havoc acceptor1_standard_metadata.mcast_grp;
    havoc acceptor1_standard_metadata.egress_rid;
    havoc acceptor1_standard_metadata.checksum_error;
    havoc acceptor1_standard_metadata.parser_error;
    havoc acceptor1_standard_metadata.priority;
    havoc acceptor1_hdr.ethernet.valid;
    havoc acceptor1_hdr.ethernet.dstAddr;
    havoc acceptor1_hdr.ethernet.srcAddr;
    havoc acceptor1_hdr.ethernet.etherType;
    havoc acceptor1_hdr.arp.valid;
    havoc acceptor1_hdr.arp.hrd;
    havoc acceptor1_hdr.arp.pro;
    havoc acceptor1_hdr.arp.hln;
    havoc acceptor1_hdr.arp.pln;
    havoc acceptor1_hdr.arp.op;
    havoc acceptor1_hdr.arp.sha;
    havoc acceptor1_hdr.arp.spa;
    havoc acceptor1_hdr.arp.tha;
    havoc acceptor1_hdr.arp.tpa;
    havoc acceptor1_hdr.ipv4.valid;
    havoc acceptor1_hdr.ipv4.version;
    havoc acceptor1_hdr.ipv4.ihl;
    havoc acceptor1_hdr.ipv4.diffserv;
    havoc acceptor1_hdr.ipv4.totalLen;
    havoc acceptor1_hdr.ipv4.identification;
    havoc acceptor1_hdr.ipv4.flags;
    havoc acceptor1_hdr.ipv4.fragOffset;
    havoc acceptor1_hdr.ipv4.ttl;
    havoc acceptor1_hdr.ipv4.protocol;
    havoc acceptor1_hdr.ipv4.hdrChecksum;
    havoc acceptor1_hdr.ipv4.srcAddr;
    havoc acceptor1_hdr.ipv4.dstAddr;
    havoc acceptor1_hdr.icmp.valid;
    havoc acceptor1_hdr.icmp.icmpType;
    havoc acceptor1_hdr.icmp.icmpCode;
    havoc acceptor1_hdr.icmp.hdrChecksum;
    havoc acceptor1_hdr.icmp.identifier;
    havoc acceptor1_hdr.icmp.seqNumber;
    havoc acceptor1_hdr.icmp.payload;
    havoc acceptor1_hdr.udp.valid;
    havoc acceptor1_hdr.udp.srcPort;
    havoc acceptor1_hdr.udp.dstPort;
    havoc acceptor1_hdr.udp.length_;
    havoc acceptor1_hdr.udp.checksum;
    havoc acceptor1_hdr.paxos.valid;
    havoc acceptor1_hdr.paxos.msgtype;
    havoc acceptor1_hdr.paxos.inst;
    havoc acceptor1_hdr.paxos.rnd;
    havoc acceptor1_hdr.paxos.vrnd;
    havoc acceptor1_hdr.paxos.acptid;
    havoc acceptor1_hdr.paxos.paxoslen;
    havoc acceptor1_hdr.paxos.paxosval;
    havoc acceptor1_meta.paxos_metadata;
    havoc acceptor1_meta.paxos_metadata.round;
    havoc acceptor1_meta.paxos_metadata.set_drop;
    havoc acceptor1_meta.paxos_metadata.ack_count;
    havoc acceptor1_meta.paxos_metadata.ack_acceptors;
    acceptor1_inbox_count := acceptor1_inbox_count + 1;
  } else if (*) {
    // env inject -> acceptor2
    assume acceptor2_inbox_count < 3;
    acceptor2_pkt_external := true;
    havoc acceptor2_standard_metadata.ingress_port;
    havoc acceptor2_standard_metadata.instance_type;
    havoc acceptor2_standard_metadata.packet_length;
    havoc acceptor2_standard_metadata.enq_timestamp;
    havoc acceptor2_standard_metadata.enq_qdepth;
    havoc acceptor2_standard_metadata.deq_timedelta;
    havoc acceptor2_standard_metadata.deq_qdepth;
    havoc acceptor2_standard_metadata.ingress_global_timestamp;
    havoc acceptor2_standard_metadata.egress_global_timestamp;
    havoc acceptor2_standard_metadata.mcast_grp;
    havoc acceptor2_standard_metadata.egress_rid;
    havoc acceptor2_standard_metadata.checksum_error;
    havoc acceptor2_standard_metadata.parser_error;
    havoc acceptor2_standard_metadata.priority;
    havoc acceptor2_hdr.ethernet.valid;
    havoc acceptor2_hdr.ethernet.dstAddr;
    havoc acceptor2_hdr.ethernet.srcAddr;
    havoc acceptor2_hdr.ethernet.etherType;
    havoc acceptor2_hdr.arp.valid;
    havoc acceptor2_hdr.arp.hrd;
    havoc acceptor2_hdr.arp.pro;
    havoc acceptor2_hdr.arp.hln;
    havoc acceptor2_hdr.arp.pln;
    havoc acceptor2_hdr.arp.op;
    havoc acceptor2_hdr.arp.sha;
    havoc acceptor2_hdr.arp.spa;
    havoc acceptor2_hdr.arp.tha;
    havoc acceptor2_hdr.arp.tpa;
    havoc acceptor2_hdr.ipv4.valid;
    havoc acceptor2_hdr.ipv4.version;
    havoc acceptor2_hdr.ipv4.ihl;
    havoc acceptor2_hdr.ipv4.diffserv;
    havoc acceptor2_hdr.ipv4.totalLen;
    havoc acceptor2_hdr.ipv4.identification;
    havoc acceptor2_hdr.ipv4.flags;
    havoc acceptor2_hdr.ipv4.fragOffset;
    havoc acceptor2_hdr.ipv4.ttl;
    havoc acceptor2_hdr.ipv4.protocol;
    havoc acceptor2_hdr.ipv4.hdrChecksum;
    havoc acceptor2_hdr.ipv4.srcAddr;
    havoc acceptor2_hdr.ipv4.dstAddr;
    havoc acceptor2_hdr.icmp.valid;
    havoc acceptor2_hdr.icmp.icmpType;
    havoc acceptor2_hdr.icmp.icmpCode;
    havoc acceptor2_hdr.icmp.hdrChecksum;
    havoc acceptor2_hdr.icmp.identifier;
    havoc acceptor2_hdr.icmp.seqNumber;
    havoc acceptor2_hdr.icmp.payload;
    havoc acceptor2_hdr.udp.valid;
    havoc acceptor2_hdr.udp.srcPort;
    havoc acceptor2_hdr.udp.dstPort;
    havoc acceptor2_hdr.udp.length_;
    havoc acceptor2_hdr.udp.checksum;
    havoc acceptor2_hdr.paxos.valid;
    havoc acceptor2_hdr.paxos.msgtype;
    havoc acceptor2_hdr.paxos.inst;
    havoc acceptor2_hdr.paxos.rnd;
    havoc acceptor2_hdr.paxos.vrnd;
    havoc acceptor2_hdr.paxos.acptid;
    havoc acceptor2_hdr.paxos.paxoslen;
    havoc acceptor2_hdr.paxos.paxosval;
    havoc acceptor2_meta.paxos_metadata;
    havoc acceptor2_meta.paxos_metadata.round;
    havoc acceptor2_meta.paxos_metadata.set_drop;
    havoc acceptor2_meta.paxos_metadata.ack_count;
    havoc acceptor2_meta.paxos_metadata.ack_acceptors;
    acceptor2_inbox_count := acceptor2_inbox_count + 1;
  } else if (*) {
    // node pass -> leader
    assume leader_inbox_count > 0;
    leader_inbox_count := leader_inbox_count - 1;
    call leader_mainProcedure();
    if (leader_p4b_clone_i2e) {
      assume leader_inbox_count < 3;
      leader_pkt_external := false;
      leader_inbox_count := leader_inbox_count + 1;
    }
    leader_p4b_clone_i2e := false;
    if (leader_p4b_clone_e2e) {
      assume leader_inbox_count < 3;
      leader_pkt_external := false;
      leader_inbox_count := leader_inbox_count + 1;
    }
    leader_p4b_clone_e2e := false;
    if (leader_p4b_clone_i2i) {
      assume leader_inbox_count < 3;
      leader_pkt_external := false;
      leader_inbox_count := leader_inbox_count + 1;
    }
    leader_p4b_clone_i2i := false;
    if (leader_p4b_recirculate) {
      assume leader_inbox_count < 3;
      leader_pkt_external := false;
      leader_inbox_count := leader_inbox_count + 1;
    }
    leader_p4b_recirculate := false;
    call leader_Forward();
    // Register debug snapshot
    leader_ingress_ctrlInstane__dbg0 := leader_ingress_ctrlInstane[0bv32];
    leader_ingress_ctrlInstane__last_index__dbg := leader_ingress_ctrlInstane__last_index;
    leader_ingress_ctrlInstane__last_value__dbg := leader_ingress_ctrlInstane__last_value;
    leader_ingress_ctrlInstane__last_old_value__dbg := leader_ingress_ctrlInstane__last_old_value;
    leader_ingress_ctrlInstane__wrote_any__dbg := leader_ingress_ctrlInstane__wrote_any;
    leader_ingress_ctrlInstane__wrote_index0__dbg := leader_ingress_ctrlInstane__wrote_index0;
    leader_ingress_ctrlInstane__last0_old_value__dbg := leader_ingress_ctrlInstane__last0_old_value;
    leader_ingress_ctrlInstane__last0_value__dbg := leader_ingress_ctrlInstane__last0_value;
    acceptor0_ingress_learner_address__dbg0 := acceptor0_ingress_learner_address[0bv32];
    acceptor0_ingress_learner_address__last_index__dbg := acceptor0_ingress_learner_address__last_index;
    acceptor0_ingress_learner_address__last_value__dbg := acceptor0_ingress_learner_address__last_value;
    acceptor0_ingress_learner_address__last_old_value__dbg := acceptor0_ingress_learner_address__last_old_value;
    acceptor0_ingress_learner_address__wrote_any__dbg := acceptor0_ingress_learner_address__wrote_any;
    acceptor0_ingress_learner_address__wrote_index0__dbg := acceptor0_ingress_learner_address__wrote_index0;
    acceptor0_ingress_learner_address__last0_old_value__dbg := acceptor0_ingress_learner_address__last0_old_value;
    acceptor0_ingress_learner_address__last0_value__dbg := acceptor0_ingress_learner_address__last0_value;
    acceptor0_ingress_learner_mac_address__dbg0 := acceptor0_ingress_learner_mac_address[0bv32];
    acceptor0_ingress_learner_mac_address__last_index__dbg := acceptor0_ingress_learner_mac_address__last_index;
    acceptor0_ingress_learner_mac_address__last_value__dbg := acceptor0_ingress_learner_mac_address__last_value;
    acceptor0_ingress_learner_mac_address__last_old_value__dbg := acceptor0_ingress_learner_mac_address__last_old_value;
    acceptor0_ingress_learner_mac_address__wrote_any__dbg := acceptor0_ingress_learner_mac_address__wrote_any;
    acceptor0_ingress_learner_mac_address__wrote_index0__dbg := acceptor0_ingress_learner_mac_address__wrote_index0;
    acceptor0_ingress_learner_mac_address__last0_old_value__dbg := acceptor0_ingress_learner_mac_address__last0_old_value;
    acceptor0_ingress_learner_mac_address__last0_value__dbg := acceptor0_ingress_learner_mac_address__last0_value;
    acceptor0_ingress_my_ip_address__dbg0 := acceptor0_ingress_my_ip_address[0bv32];
    acceptor0_ingress_my_ip_address__last_index__dbg := acceptor0_ingress_my_ip_address__last_index;
    acceptor0_ingress_my_ip_address__last_value__dbg := acceptor0_ingress_my_ip_address__last_value;
    acceptor0_ingress_my_ip_address__last_old_value__dbg := acceptor0_ingress_my_ip_address__last_old_value;
    acceptor0_ingress_my_ip_address__wrote_any__dbg := acceptor0_ingress_my_ip_address__wrote_any;
    acceptor0_ingress_my_ip_address__wrote_index0__dbg := acceptor0_ingress_my_ip_address__wrote_index0;
    acceptor0_ingress_my_ip_address__last0_old_value__dbg := acceptor0_ingress_my_ip_address__last0_old_value;
    acceptor0_ingress_my_ip_address__last0_value__dbg := acceptor0_ingress_my_ip_address__last0_value;
    acceptor0_ingress_my_mac_address__dbg0 := acceptor0_ingress_my_mac_address[0bv32];
    acceptor0_ingress_my_mac_address__last_index__dbg := acceptor0_ingress_my_mac_address__last_index;
    acceptor0_ingress_my_mac_address__last_value__dbg := acceptor0_ingress_my_mac_address__last_value;
    acceptor0_ingress_my_mac_address__last_old_value__dbg := acceptor0_ingress_my_mac_address__last_old_value;
    acceptor0_ingress_my_mac_address__wrote_any__dbg := acceptor0_ingress_my_mac_address__wrote_any;
    acceptor0_ingress_my_mac_address__wrote_index0__dbg := acceptor0_ingress_my_mac_address__wrote_index0;
    acceptor0_ingress_my_mac_address__last0_old_value__dbg := acceptor0_ingress_my_mac_address__last0_old_value;
    acceptor0_ingress_my_mac_address__last0_value__dbg := acceptor0_ingress_my_mac_address__last0_value;
    acceptor0_ingress_registerAcceptorID__dbg0 := acceptor0_ingress_registerAcceptorID[0bv32];
    acceptor0_ingress_registerAcceptorID__last_index__dbg := acceptor0_ingress_registerAcceptorID__last_index;
    acceptor0_ingress_registerAcceptorID__last_value__dbg := acceptor0_ingress_registerAcceptorID__last_value;
    acceptor0_ingress_registerAcceptorID__last_old_value__dbg := acceptor0_ingress_registerAcceptorID__last_old_value;
    acceptor0_ingress_registerAcceptorID__wrote_any__dbg := acceptor0_ingress_registerAcceptorID__wrote_any;
    acceptor0_ingress_registerAcceptorID__wrote_index0__dbg := acceptor0_ingress_registerAcceptorID__wrote_index0;
    acceptor0_ingress_registerAcceptorID__last0_old_value__dbg := acceptor0_ingress_registerAcceptorID__last0_old_value;
    acceptor0_ingress_registerAcceptorID__last0_value__dbg := acceptor0_ingress_registerAcceptorID__last0_value;
    acceptor0_ingress_registerRound__dbg0 := acceptor0_ingress_registerRound[0bv32];
    acceptor0_ingress_registerRound__last_index__dbg := acceptor0_ingress_registerRound__last_index;
    acceptor0_ingress_registerRound__last_value__dbg := acceptor0_ingress_registerRound__last_value;
    acceptor0_ingress_registerRound__last_old_value__dbg := acceptor0_ingress_registerRound__last_old_value;
    acceptor0_ingress_registerRound__wrote_any__dbg := acceptor0_ingress_registerRound__wrote_any;
    acceptor0_ingress_registerRound__wrote_index0__dbg := acceptor0_ingress_registerRound__wrote_index0;
    acceptor0_ingress_registerRound__last0_old_value__dbg := acceptor0_ingress_registerRound__last0_old_value;
    acceptor0_ingress_registerRound__last0_value__dbg := acceptor0_ingress_registerRound__last0_value;
    acceptor0_ingress_registerVRound__dbg0 := acceptor0_ingress_registerVRound[0bv32];
    acceptor0_ingress_registerVRound__last_index__dbg := acceptor0_ingress_registerVRound__last_index;
    acceptor0_ingress_registerVRound__last_value__dbg := acceptor0_ingress_registerVRound__last_value;
    acceptor0_ingress_registerVRound__last_old_value__dbg := acceptor0_ingress_registerVRound__last_old_value;
    acceptor0_ingress_registerVRound__wrote_any__dbg := acceptor0_ingress_registerVRound__wrote_any;
    acceptor0_ingress_registerVRound__wrote_index0__dbg := acceptor0_ingress_registerVRound__wrote_index0;
    acceptor0_ingress_registerVRound__last0_old_value__dbg := acceptor0_ingress_registerVRound__last0_old_value;
    acceptor0_ingress_registerVRound__last0_value__dbg := acceptor0_ingress_registerVRound__last0_value;
    acceptor0_ingress_registerValue__dbg0 := acceptor0_ingress_registerValue[0bv32];
    acceptor0_ingress_registerValue__last_index__dbg := acceptor0_ingress_registerValue__last_index;
    acceptor0_ingress_registerValue__last_value__dbg := acceptor0_ingress_registerValue__last_value;
    acceptor0_ingress_registerValue__last_old_value__dbg := acceptor0_ingress_registerValue__last_old_value;
    acceptor0_ingress_registerValue__wrote_any__dbg := acceptor0_ingress_registerValue__wrote_any;
    acceptor0_ingress_registerValue__wrote_index0__dbg := acceptor0_ingress_registerValue__wrote_index0;
    acceptor0_ingress_registerValue__last0_old_value__dbg := acceptor0_ingress_registerValue__last0_old_value;
    acceptor0_ingress_registerValue__last0_value__dbg := acceptor0_ingress_registerValue__last0_value;
    acceptor1_ingress_learner_address__dbg0 := acceptor1_ingress_learner_address[0bv32];
    acceptor1_ingress_learner_address__last_index__dbg := acceptor1_ingress_learner_address__last_index;
    acceptor1_ingress_learner_address__last_value__dbg := acceptor1_ingress_learner_address__last_value;
    acceptor1_ingress_learner_address__last_old_value__dbg := acceptor1_ingress_learner_address__last_old_value;
    acceptor1_ingress_learner_address__wrote_any__dbg := acceptor1_ingress_learner_address__wrote_any;
    acceptor1_ingress_learner_address__wrote_index0__dbg := acceptor1_ingress_learner_address__wrote_index0;
    acceptor1_ingress_learner_address__last0_old_value__dbg := acceptor1_ingress_learner_address__last0_old_value;
    acceptor1_ingress_learner_address__last0_value__dbg := acceptor1_ingress_learner_address__last0_value;
    acceptor1_ingress_learner_mac_address__dbg0 := acceptor1_ingress_learner_mac_address[0bv32];
    acceptor1_ingress_learner_mac_address__last_index__dbg := acceptor1_ingress_learner_mac_address__last_index;
    acceptor1_ingress_learner_mac_address__last_value__dbg := acceptor1_ingress_learner_mac_address__last_value;
    acceptor1_ingress_learner_mac_address__last_old_value__dbg := acceptor1_ingress_learner_mac_address__last_old_value;
    acceptor1_ingress_learner_mac_address__wrote_any__dbg := acceptor1_ingress_learner_mac_address__wrote_any;
    acceptor1_ingress_learner_mac_address__wrote_index0__dbg := acceptor1_ingress_learner_mac_address__wrote_index0;
    acceptor1_ingress_learner_mac_address__last0_old_value__dbg := acceptor1_ingress_learner_mac_address__last0_old_value;
    acceptor1_ingress_learner_mac_address__last0_value__dbg := acceptor1_ingress_learner_mac_address__last0_value;
    acceptor1_ingress_my_ip_address__dbg0 := acceptor1_ingress_my_ip_address[0bv32];
    acceptor1_ingress_my_ip_address__last_index__dbg := acceptor1_ingress_my_ip_address__last_index;
    acceptor1_ingress_my_ip_address__last_value__dbg := acceptor1_ingress_my_ip_address__last_value;
    acceptor1_ingress_my_ip_address__last_old_value__dbg := acceptor1_ingress_my_ip_address__last_old_value;
    acceptor1_ingress_my_ip_address__wrote_any__dbg := acceptor1_ingress_my_ip_address__wrote_any;
    acceptor1_ingress_my_ip_address__wrote_index0__dbg := acceptor1_ingress_my_ip_address__wrote_index0;
    acceptor1_ingress_my_ip_address__last0_old_value__dbg := acceptor1_ingress_my_ip_address__last0_old_value;
    acceptor1_ingress_my_ip_address__last0_value__dbg := acceptor1_ingress_my_ip_address__last0_value;
    acceptor1_ingress_my_mac_address__dbg0 := acceptor1_ingress_my_mac_address[0bv32];
    acceptor1_ingress_my_mac_address__last_index__dbg := acceptor1_ingress_my_mac_address__last_index;
    acceptor1_ingress_my_mac_address__last_value__dbg := acceptor1_ingress_my_mac_address__last_value;
    acceptor1_ingress_my_mac_address__last_old_value__dbg := acceptor1_ingress_my_mac_address__last_old_value;
    acceptor1_ingress_my_mac_address__wrote_any__dbg := acceptor1_ingress_my_mac_address__wrote_any;
    acceptor1_ingress_my_mac_address__wrote_index0__dbg := acceptor1_ingress_my_mac_address__wrote_index0;
    acceptor1_ingress_my_mac_address__last0_old_value__dbg := acceptor1_ingress_my_mac_address__last0_old_value;
    acceptor1_ingress_my_mac_address__last0_value__dbg := acceptor1_ingress_my_mac_address__last0_value;
    acceptor1_ingress_registerAcceptorID__dbg0 := acceptor1_ingress_registerAcceptorID[0bv32];
    acceptor1_ingress_registerAcceptorID__last_index__dbg := acceptor1_ingress_registerAcceptorID__last_index;
    acceptor1_ingress_registerAcceptorID__last_value__dbg := acceptor1_ingress_registerAcceptorID__last_value;
    acceptor1_ingress_registerAcceptorID__last_old_value__dbg := acceptor1_ingress_registerAcceptorID__last_old_value;
    acceptor1_ingress_registerAcceptorID__wrote_any__dbg := acceptor1_ingress_registerAcceptorID__wrote_any;
    acceptor1_ingress_registerAcceptorID__wrote_index0__dbg := acceptor1_ingress_registerAcceptorID__wrote_index0;
    acceptor1_ingress_registerAcceptorID__last0_old_value__dbg := acceptor1_ingress_registerAcceptorID__last0_old_value;
    acceptor1_ingress_registerAcceptorID__last0_value__dbg := acceptor1_ingress_registerAcceptorID__last0_value;
    acceptor1_ingress_registerRound__dbg0 := acceptor1_ingress_registerRound[0bv32];
    acceptor1_ingress_registerRound__last_index__dbg := acceptor1_ingress_registerRound__last_index;
    acceptor1_ingress_registerRound__last_value__dbg := acceptor1_ingress_registerRound__last_value;
    acceptor1_ingress_registerRound__last_old_value__dbg := acceptor1_ingress_registerRound__last_old_value;
    acceptor1_ingress_registerRound__wrote_any__dbg := acceptor1_ingress_registerRound__wrote_any;
    acceptor1_ingress_registerRound__wrote_index0__dbg := acceptor1_ingress_registerRound__wrote_index0;
    acceptor1_ingress_registerRound__last0_old_value__dbg := acceptor1_ingress_registerRound__last0_old_value;
    acceptor1_ingress_registerRound__last0_value__dbg := acceptor1_ingress_registerRound__last0_value;
    acceptor1_ingress_registerVRound__dbg0 := acceptor1_ingress_registerVRound[0bv32];
    acceptor1_ingress_registerVRound__last_index__dbg := acceptor1_ingress_registerVRound__last_index;
    acceptor1_ingress_registerVRound__last_value__dbg := acceptor1_ingress_registerVRound__last_value;
    acceptor1_ingress_registerVRound__last_old_value__dbg := acceptor1_ingress_registerVRound__last_old_value;
    acceptor1_ingress_registerVRound__wrote_any__dbg := acceptor1_ingress_registerVRound__wrote_any;
    acceptor1_ingress_registerVRound__wrote_index0__dbg := acceptor1_ingress_registerVRound__wrote_index0;
    acceptor1_ingress_registerVRound__last0_old_value__dbg := acceptor1_ingress_registerVRound__last0_old_value;
    acceptor1_ingress_registerVRound__last0_value__dbg := acceptor1_ingress_registerVRound__last0_value;
    acceptor1_ingress_registerValue__dbg0 := acceptor1_ingress_registerValue[0bv32];
    acceptor1_ingress_registerValue__last_index__dbg := acceptor1_ingress_registerValue__last_index;
    acceptor1_ingress_registerValue__last_value__dbg := acceptor1_ingress_registerValue__last_value;
    acceptor1_ingress_registerValue__last_old_value__dbg := acceptor1_ingress_registerValue__last_old_value;
    acceptor1_ingress_registerValue__wrote_any__dbg := acceptor1_ingress_registerValue__wrote_any;
    acceptor1_ingress_registerValue__wrote_index0__dbg := acceptor1_ingress_registerValue__wrote_index0;
    acceptor1_ingress_registerValue__last0_old_value__dbg := acceptor1_ingress_registerValue__last0_old_value;
    acceptor1_ingress_registerValue__last0_value__dbg := acceptor1_ingress_registerValue__last0_value;
    acceptor2_ingress_learner_address__dbg0 := acceptor2_ingress_learner_address[0bv32];
    acceptor2_ingress_learner_address__last_index__dbg := acceptor2_ingress_learner_address__last_index;
    acceptor2_ingress_learner_address__last_value__dbg := acceptor2_ingress_learner_address__last_value;
    acceptor2_ingress_learner_address__last_old_value__dbg := acceptor2_ingress_learner_address__last_old_value;
    acceptor2_ingress_learner_address__wrote_any__dbg := acceptor2_ingress_learner_address__wrote_any;
    acceptor2_ingress_learner_address__wrote_index0__dbg := acceptor2_ingress_learner_address__wrote_index0;
    acceptor2_ingress_learner_address__last0_old_value__dbg := acceptor2_ingress_learner_address__last0_old_value;
    acceptor2_ingress_learner_address__last0_value__dbg := acceptor2_ingress_learner_address__last0_value;
    acceptor2_ingress_learner_mac_address__dbg0 := acceptor2_ingress_learner_mac_address[0bv32];
    acceptor2_ingress_learner_mac_address__last_index__dbg := acceptor2_ingress_learner_mac_address__last_index;
    acceptor2_ingress_learner_mac_address__last_value__dbg := acceptor2_ingress_learner_mac_address__last_value;
    acceptor2_ingress_learner_mac_address__last_old_value__dbg := acceptor2_ingress_learner_mac_address__last_old_value;
    acceptor2_ingress_learner_mac_address__wrote_any__dbg := acceptor2_ingress_learner_mac_address__wrote_any;
    acceptor2_ingress_learner_mac_address__wrote_index0__dbg := acceptor2_ingress_learner_mac_address__wrote_index0;
    acceptor2_ingress_learner_mac_address__last0_old_value__dbg := acceptor2_ingress_learner_mac_address__last0_old_value;
    acceptor2_ingress_learner_mac_address__last0_value__dbg := acceptor2_ingress_learner_mac_address__last0_value;
    acceptor2_ingress_my_ip_address__dbg0 := acceptor2_ingress_my_ip_address[0bv32];
    acceptor2_ingress_my_ip_address__last_index__dbg := acceptor2_ingress_my_ip_address__last_index;
    acceptor2_ingress_my_ip_address__last_value__dbg := acceptor2_ingress_my_ip_address__last_value;
    acceptor2_ingress_my_ip_address__last_old_value__dbg := acceptor2_ingress_my_ip_address__last_old_value;
    acceptor2_ingress_my_ip_address__wrote_any__dbg := acceptor2_ingress_my_ip_address__wrote_any;
    acceptor2_ingress_my_ip_address__wrote_index0__dbg := acceptor2_ingress_my_ip_address__wrote_index0;
    acceptor2_ingress_my_ip_address__last0_old_value__dbg := acceptor2_ingress_my_ip_address__last0_old_value;
    acceptor2_ingress_my_ip_address__last0_value__dbg := acceptor2_ingress_my_ip_address__last0_value;
    acceptor2_ingress_my_mac_address__dbg0 := acceptor2_ingress_my_mac_address[0bv32];
    acceptor2_ingress_my_mac_address__last_index__dbg := acceptor2_ingress_my_mac_address__last_index;
    acceptor2_ingress_my_mac_address__last_value__dbg := acceptor2_ingress_my_mac_address__last_value;
    acceptor2_ingress_my_mac_address__last_old_value__dbg := acceptor2_ingress_my_mac_address__last_old_value;
    acceptor2_ingress_my_mac_address__wrote_any__dbg := acceptor2_ingress_my_mac_address__wrote_any;
    acceptor2_ingress_my_mac_address__wrote_index0__dbg := acceptor2_ingress_my_mac_address__wrote_index0;
    acceptor2_ingress_my_mac_address__last0_old_value__dbg := acceptor2_ingress_my_mac_address__last0_old_value;
    acceptor2_ingress_my_mac_address__last0_value__dbg := acceptor2_ingress_my_mac_address__last0_value;
    acceptor2_ingress_registerAcceptorID__dbg0 := acceptor2_ingress_registerAcceptorID[0bv32];
    acceptor2_ingress_registerAcceptorID__last_index__dbg := acceptor2_ingress_registerAcceptorID__last_index;
    acceptor2_ingress_registerAcceptorID__last_value__dbg := acceptor2_ingress_registerAcceptorID__last_value;
    acceptor2_ingress_registerAcceptorID__last_old_value__dbg := acceptor2_ingress_registerAcceptorID__last_old_value;
    acceptor2_ingress_registerAcceptorID__wrote_any__dbg := acceptor2_ingress_registerAcceptorID__wrote_any;
    acceptor2_ingress_registerAcceptorID__wrote_index0__dbg := acceptor2_ingress_registerAcceptorID__wrote_index0;
    acceptor2_ingress_registerAcceptorID__last0_old_value__dbg := acceptor2_ingress_registerAcceptorID__last0_old_value;
    acceptor2_ingress_registerAcceptorID__last0_value__dbg := acceptor2_ingress_registerAcceptorID__last0_value;
    acceptor2_ingress_registerRound__dbg0 := acceptor2_ingress_registerRound[0bv32];
    acceptor2_ingress_registerRound__last_index__dbg := acceptor2_ingress_registerRound__last_index;
    acceptor2_ingress_registerRound__last_value__dbg := acceptor2_ingress_registerRound__last_value;
    acceptor2_ingress_registerRound__last_old_value__dbg := acceptor2_ingress_registerRound__last_old_value;
    acceptor2_ingress_registerRound__wrote_any__dbg := acceptor2_ingress_registerRound__wrote_any;
    acceptor2_ingress_registerRound__wrote_index0__dbg := acceptor2_ingress_registerRound__wrote_index0;
    acceptor2_ingress_registerRound__last0_old_value__dbg := acceptor2_ingress_registerRound__last0_old_value;
    acceptor2_ingress_registerRound__last0_value__dbg := acceptor2_ingress_registerRound__last0_value;
    acceptor2_ingress_registerVRound__dbg0 := acceptor2_ingress_registerVRound[0bv32];
    acceptor2_ingress_registerVRound__last_index__dbg := acceptor2_ingress_registerVRound__last_index;
    acceptor2_ingress_registerVRound__last_value__dbg := acceptor2_ingress_registerVRound__last_value;
    acceptor2_ingress_registerVRound__last_old_value__dbg := acceptor2_ingress_registerVRound__last_old_value;
    acceptor2_ingress_registerVRound__wrote_any__dbg := acceptor2_ingress_registerVRound__wrote_any;
    acceptor2_ingress_registerVRound__wrote_index0__dbg := acceptor2_ingress_registerVRound__wrote_index0;
    acceptor2_ingress_registerVRound__last0_old_value__dbg := acceptor2_ingress_registerVRound__last0_old_value;
    acceptor2_ingress_registerVRound__last0_value__dbg := acceptor2_ingress_registerVRound__last0_value;
    acceptor2_ingress_registerValue__dbg0 := acceptor2_ingress_registerValue[0bv32];
    acceptor2_ingress_registerValue__last_index__dbg := acceptor2_ingress_registerValue__last_index;
    acceptor2_ingress_registerValue__last_value__dbg := acceptor2_ingress_registerValue__last_value;
    acceptor2_ingress_registerValue__last_old_value__dbg := acceptor2_ingress_registerValue__last_old_value;
    acceptor2_ingress_registerValue__wrote_any__dbg := acceptor2_ingress_registerValue__wrote_any;
    acceptor2_ingress_registerValue__wrote_index0__dbg := acceptor2_ingress_registerValue__wrote_index0;
    acceptor2_ingress_registerValue__last0_old_value__dbg := acceptor2_ingress_registerValue__last0_old_value;
    acceptor2_ingress_registerValue__last0_value__dbg := acceptor2_ingress_registerValue__last0_value;
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
    // Global assertions
    assert (bvule.bv32$builtin(acceptor0_hdr.paxos.inst, 300bv32) && (acceptor0_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor1_hdr.paxos.inst, 300bv32) && (acceptor1_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor2_hdr.paxos.inst, 300bv32) && (acceptor2_hdr.paxos.inst != 300bv32));
  } else if (*) {
    // node pass -> acceptor0
    assume acceptor0_inbox_count > 0;
    acceptor0_inbox_count := acceptor0_inbox_count - 1;
    call acceptor0_mainProcedure();
    if (acceptor0_p4b_clone_i2e) {
      assume acceptor0_inbox_count < 3;
      acceptor0_pkt_external := false;
      acceptor0_inbox_count := acceptor0_inbox_count + 1;
    }
    acceptor0_p4b_clone_i2e := false;
    if (acceptor0_p4b_clone_e2e) {
      assume acceptor0_inbox_count < 3;
      acceptor0_pkt_external := false;
      acceptor0_inbox_count := acceptor0_inbox_count + 1;
    }
    acceptor0_p4b_clone_e2e := false;
    if (acceptor0_p4b_clone_i2i) {
      assume acceptor0_inbox_count < 3;
      acceptor0_pkt_external := false;
      acceptor0_inbox_count := acceptor0_inbox_count + 1;
    }
    acceptor0_p4b_clone_i2i := false;
    if (acceptor0_p4b_recirculate) {
      assume acceptor0_inbox_count < 3;
      acceptor0_pkt_external := false;
      acceptor0_inbox_count := acceptor0_inbox_count + 1;
    }
    acceptor0_p4b_recirculate := false;
    call acceptor0_Forward();
    // Register debug snapshot
    leader_ingress_ctrlInstane__dbg0 := leader_ingress_ctrlInstane[0bv32];
    leader_ingress_ctrlInstane__last_index__dbg := leader_ingress_ctrlInstane__last_index;
    leader_ingress_ctrlInstane__last_value__dbg := leader_ingress_ctrlInstane__last_value;
    leader_ingress_ctrlInstane__last_old_value__dbg := leader_ingress_ctrlInstane__last_old_value;
    leader_ingress_ctrlInstane__wrote_any__dbg := leader_ingress_ctrlInstane__wrote_any;
    leader_ingress_ctrlInstane__wrote_index0__dbg := leader_ingress_ctrlInstane__wrote_index0;
    leader_ingress_ctrlInstane__last0_old_value__dbg := leader_ingress_ctrlInstane__last0_old_value;
    leader_ingress_ctrlInstane__last0_value__dbg := leader_ingress_ctrlInstane__last0_value;
    acceptor0_ingress_learner_address__dbg0 := acceptor0_ingress_learner_address[0bv32];
    acceptor0_ingress_learner_address__last_index__dbg := acceptor0_ingress_learner_address__last_index;
    acceptor0_ingress_learner_address__last_value__dbg := acceptor0_ingress_learner_address__last_value;
    acceptor0_ingress_learner_address__last_old_value__dbg := acceptor0_ingress_learner_address__last_old_value;
    acceptor0_ingress_learner_address__wrote_any__dbg := acceptor0_ingress_learner_address__wrote_any;
    acceptor0_ingress_learner_address__wrote_index0__dbg := acceptor0_ingress_learner_address__wrote_index0;
    acceptor0_ingress_learner_address__last0_old_value__dbg := acceptor0_ingress_learner_address__last0_old_value;
    acceptor0_ingress_learner_address__last0_value__dbg := acceptor0_ingress_learner_address__last0_value;
    acceptor0_ingress_learner_mac_address__dbg0 := acceptor0_ingress_learner_mac_address[0bv32];
    acceptor0_ingress_learner_mac_address__last_index__dbg := acceptor0_ingress_learner_mac_address__last_index;
    acceptor0_ingress_learner_mac_address__last_value__dbg := acceptor0_ingress_learner_mac_address__last_value;
    acceptor0_ingress_learner_mac_address__last_old_value__dbg := acceptor0_ingress_learner_mac_address__last_old_value;
    acceptor0_ingress_learner_mac_address__wrote_any__dbg := acceptor0_ingress_learner_mac_address__wrote_any;
    acceptor0_ingress_learner_mac_address__wrote_index0__dbg := acceptor0_ingress_learner_mac_address__wrote_index0;
    acceptor0_ingress_learner_mac_address__last0_old_value__dbg := acceptor0_ingress_learner_mac_address__last0_old_value;
    acceptor0_ingress_learner_mac_address__last0_value__dbg := acceptor0_ingress_learner_mac_address__last0_value;
    acceptor0_ingress_my_ip_address__dbg0 := acceptor0_ingress_my_ip_address[0bv32];
    acceptor0_ingress_my_ip_address__last_index__dbg := acceptor0_ingress_my_ip_address__last_index;
    acceptor0_ingress_my_ip_address__last_value__dbg := acceptor0_ingress_my_ip_address__last_value;
    acceptor0_ingress_my_ip_address__last_old_value__dbg := acceptor0_ingress_my_ip_address__last_old_value;
    acceptor0_ingress_my_ip_address__wrote_any__dbg := acceptor0_ingress_my_ip_address__wrote_any;
    acceptor0_ingress_my_ip_address__wrote_index0__dbg := acceptor0_ingress_my_ip_address__wrote_index0;
    acceptor0_ingress_my_ip_address__last0_old_value__dbg := acceptor0_ingress_my_ip_address__last0_old_value;
    acceptor0_ingress_my_ip_address__last0_value__dbg := acceptor0_ingress_my_ip_address__last0_value;
    acceptor0_ingress_my_mac_address__dbg0 := acceptor0_ingress_my_mac_address[0bv32];
    acceptor0_ingress_my_mac_address__last_index__dbg := acceptor0_ingress_my_mac_address__last_index;
    acceptor0_ingress_my_mac_address__last_value__dbg := acceptor0_ingress_my_mac_address__last_value;
    acceptor0_ingress_my_mac_address__last_old_value__dbg := acceptor0_ingress_my_mac_address__last_old_value;
    acceptor0_ingress_my_mac_address__wrote_any__dbg := acceptor0_ingress_my_mac_address__wrote_any;
    acceptor0_ingress_my_mac_address__wrote_index0__dbg := acceptor0_ingress_my_mac_address__wrote_index0;
    acceptor0_ingress_my_mac_address__last0_old_value__dbg := acceptor0_ingress_my_mac_address__last0_old_value;
    acceptor0_ingress_my_mac_address__last0_value__dbg := acceptor0_ingress_my_mac_address__last0_value;
    acceptor0_ingress_registerAcceptorID__dbg0 := acceptor0_ingress_registerAcceptorID[0bv32];
    acceptor0_ingress_registerAcceptorID__last_index__dbg := acceptor0_ingress_registerAcceptorID__last_index;
    acceptor0_ingress_registerAcceptorID__last_value__dbg := acceptor0_ingress_registerAcceptorID__last_value;
    acceptor0_ingress_registerAcceptorID__last_old_value__dbg := acceptor0_ingress_registerAcceptorID__last_old_value;
    acceptor0_ingress_registerAcceptorID__wrote_any__dbg := acceptor0_ingress_registerAcceptorID__wrote_any;
    acceptor0_ingress_registerAcceptorID__wrote_index0__dbg := acceptor0_ingress_registerAcceptorID__wrote_index0;
    acceptor0_ingress_registerAcceptorID__last0_old_value__dbg := acceptor0_ingress_registerAcceptorID__last0_old_value;
    acceptor0_ingress_registerAcceptorID__last0_value__dbg := acceptor0_ingress_registerAcceptorID__last0_value;
    acceptor0_ingress_registerRound__dbg0 := acceptor0_ingress_registerRound[0bv32];
    acceptor0_ingress_registerRound__last_index__dbg := acceptor0_ingress_registerRound__last_index;
    acceptor0_ingress_registerRound__last_value__dbg := acceptor0_ingress_registerRound__last_value;
    acceptor0_ingress_registerRound__last_old_value__dbg := acceptor0_ingress_registerRound__last_old_value;
    acceptor0_ingress_registerRound__wrote_any__dbg := acceptor0_ingress_registerRound__wrote_any;
    acceptor0_ingress_registerRound__wrote_index0__dbg := acceptor0_ingress_registerRound__wrote_index0;
    acceptor0_ingress_registerRound__last0_old_value__dbg := acceptor0_ingress_registerRound__last0_old_value;
    acceptor0_ingress_registerRound__last0_value__dbg := acceptor0_ingress_registerRound__last0_value;
    acceptor0_ingress_registerVRound__dbg0 := acceptor0_ingress_registerVRound[0bv32];
    acceptor0_ingress_registerVRound__last_index__dbg := acceptor0_ingress_registerVRound__last_index;
    acceptor0_ingress_registerVRound__last_value__dbg := acceptor0_ingress_registerVRound__last_value;
    acceptor0_ingress_registerVRound__last_old_value__dbg := acceptor0_ingress_registerVRound__last_old_value;
    acceptor0_ingress_registerVRound__wrote_any__dbg := acceptor0_ingress_registerVRound__wrote_any;
    acceptor0_ingress_registerVRound__wrote_index0__dbg := acceptor0_ingress_registerVRound__wrote_index0;
    acceptor0_ingress_registerVRound__last0_old_value__dbg := acceptor0_ingress_registerVRound__last0_old_value;
    acceptor0_ingress_registerVRound__last0_value__dbg := acceptor0_ingress_registerVRound__last0_value;
    acceptor0_ingress_registerValue__dbg0 := acceptor0_ingress_registerValue[0bv32];
    acceptor0_ingress_registerValue__last_index__dbg := acceptor0_ingress_registerValue__last_index;
    acceptor0_ingress_registerValue__last_value__dbg := acceptor0_ingress_registerValue__last_value;
    acceptor0_ingress_registerValue__last_old_value__dbg := acceptor0_ingress_registerValue__last_old_value;
    acceptor0_ingress_registerValue__wrote_any__dbg := acceptor0_ingress_registerValue__wrote_any;
    acceptor0_ingress_registerValue__wrote_index0__dbg := acceptor0_ingress_registerValue__wrote_index0;
    acceptor0_ingress_registerValue__last0_old_value__dbg := acceptor0_ingress_registerValue__last0_old_value;
    acceptor0_ingress_registerValue__last0_value__dbg := acceptor0_ingress_registerValue__last0_value;
    acceptor1_ingress_learner_address__dbg0 := acceptor1_ingress_learner_address[0bv32];
    acceptor1_ingress_learner_address__last_index__dbg := acceptor1_ingress_learner_address__last_index;
    acceptor1_ingress_learner_address__last_value__dbg := acceptor1_ingress_learner_address__last_value;
    acceptor1_ingress_learner_address__last_old_value__dbg := acceptor1_ingress_learner_address__last_old_value;
    acceptor1_ingress_learner_address__wrote_any__dbg := acceptor1_ingress_learner_address__wrote_any;
    acceptor1_ingress_learner_address__wrote_index0__dbg := acceptor1_ingress_learner_address__wrote_index0;
    acceptor1_ingress_learner_address__last0_old_value__dbg := acceptor1_ingress_learner_address__last0_old_value;
    acceptor1_ingress_learner_address__last0_value__dbg := acceptor1_ingress_learner_address__last0_value;
    acceptor1_ingress_learner_mac_address__dbg0 := acceptor1_ingress_learner_mac_address[0bv32];
    acceptor1_ingress_learner_mac_address__last_index__dbg := acceptor1_ingress_learner_mac_address__last_index;
    acceptor1_ingress_learner_mac_address__last_value__dbg := acceptor1_ingress_learner_mac_address__last_value;
    acceptor1_ingress_learner_mac_address__last_old_value__dbg := acceptor1_ingress_learner_mac_address__last_old_value;
    acceptor1_ingress_learner_mac_address__wrote_any__dbg := acceptor1_ingress_learner_mac_address__wrote_any;
    acceptor1_ingress_learner_mac_address__wrote_index0__dbg := acceptor1_ingress_learner_mac_address__wrote_index0;
    acceptor1_ingress_learner_mac_address__last0_old_value__dbg := acceptor1_ingress_learner_mac_address__last0_old_value;
    acceptor1_ingress_learner_mac_address__last0_value__dbg := acceptor1_ingress_learner_mac_address__last0_value;
    acceptor1_ingress_my_ip_address__dbg0 := acceptor1_ingress_my_ip_address[0bv32];
    acceptor1_ingress_my_ip_address__last_index__dbg := acceptor1_ingress_my_ip_address__last_index;
    acceptor1_ingress_my_ip_address__last_value__dbg := acceptor1_ingress_my_ip_address__last_value;
    acceptor1_ingress_my_ip_address__last_old_value__dbg := acceptor1_ingress_my_ip_address__last_old_value;
    acceptor1_ingress_my_ip_address__wrote_any__dbg := acceptor1_ingress_my_ip_address__wrote_any;
    acceptor1_ingress_my_ip_address__wrote_index0__dbg := acceptor1_ingress_my_ip_address__wrote_index0;
    acceptor1_ingress_my_ip_address__last0_old_value__dbg := acceptor1_ingress_my_ip_address__last0_old_value;
    acceptor1_ingress_my_ip_address__last0_value__dbg := acceptor1_ingress_my_ip_address__last0_value;
    acceptor1_ingress_my_mac_address__dbg0 := acceptor1_ingress_my_mac_address[0bv32];
    acceptor1_ingress_my_mac_address__last_index__dbg := acceptor1_ingress_my_mac_address__last_index;
    acceptor1_ingress_my_mac_address__last_value__dbg := acceptor1_ingress_my_mac_address__last_value;
    acceptor1_ingress_my_mac_address__last_old_value__dbg := acceptor1_ingress_my_mac_address__last_old_value;
    acceptor1_ingress_my_mac_address__wrote_any__dbg := acceptor1_ingress_my_mac_address__wrote_any;
    acceptor1_ingress_my_mac_address__wrote_index0__dbg := acceptor1_ingress_my_mac_address__wrote_index0;
    acceptor1_ingress_my_mac_address__last0_old_value__dbg := acceptor1_ingress_my_mac_address__last0_old_value;
    acceptor1_ingress_my_mac_address__last0_value__dbg := acceptor1_ingress_my_mac_address__last0_value;
    acceptor1_ingress_registerAcceptorID__dbg0 := acceptor1_ingress_registerAcceptorID[0bv32];
    acceptor1_ingress_registerAcceptorID__last_index__dbg := acceptor1_ingress_registerAcceptorID__last_index;
    acceptor1_ingress_registerAcceptorID__last_value__dbg := acceptor1_ingress_registerAcceptorID__last_value;
    acceptor1_ingress_registerAcceptorID__last_old_value__dbg := acceptor1_ingress_registerAcceptorID__last_old_value;
    acceptor1_ingress_registerAcceptorID__wrote_any__dbg := acceptor1_ingress_registerAcceptorID__wrote_any;
    acceptor1_ingress_registerAcceptorID__wrote_index0__dbg := acceptor1_ingress_registerAcceptorID__wrote_index0;
    acceptor1_ingress_registerAcceptorID__last0_old_value__dbg := acceptor1_ingress_registerAcceptorID__last0_old_value;
    acceptor1_ingress_registerAcceptorID__last0_value__dbg := acceptor1_ingress_registerAcceptorID__last0_value;
    acceptor1_ingress_registerRound__dbg0 := acceptor1_ingress_registerRound[0bv32];
    acceptor1_ingress_registerRound__last_index__dbg := acceptor1_ingress_registerRound__last_index;
    acceptor1_ingress_registerRound__last_value__dbg := acceptor1_ingress_registerRound__last_value;
    acceptor1_ingress_registerRound__last_old_value__dbg := acceptor1_ingress_registerRound__last_old_value;
    acceptor1_ingress_registerRound__wrote_any__dbg := acceptor1_ingress_registerRound__wrote_any;
    acceptor1_ingress_registerRound__wrote_index0__dbg := acceptor1_ingress_registerRound__wrote_index0;
    acceptor1_ingress_registerRound__last0_old_value__dbg := acceptor1_ingress_registerRound__last0_old_value;
    acceptor1_ingress_registerRound__last0_value__dbg := acceptor1_ingress_registerRound__last0_value;
    acceptor1_ingress_registerVRound__dbg0 := acceptor1_ingress_registerVRound[0bv32];
    acceptor1_ingress_registerVRound__last_index__dbg := acceptor1_ingress_registerVRound__last_index;
    acceptor1_ingress_registerVRound__last_value__dbg := acceptor1_ingress_registerVRound__last_value;
    acceptor1_ingress_registerVRound__last_old_value__dbg := acceptor1_ingress_registerVRound__last_old_value;
    acceptor1_ingress_registerVRound__wrote_any__dbg := acceptor1_ingress_registerVRound__wrote_any;
    acceptor1_ingress_registerVRound__wrote_index0__dbg := acceptor1_ingress_registerVRound__wrote_index0;
    acceptor1_ingress_registerVRound__last0_old_value__dbg := acceptor1_ingress_registerVRound__last0_old_value;
    acceptor1_ingress_registerVRound__last0_value__dbg := acceptor1_ingress_registerVRound__last0_value;
    acceptor1_ingress_registerValue__dbg0 := acceptor1_ingress_registerValue[0bv32];
    acceptor1_ingress_registerValue__last_index__dbg := acceptor1_ingress_registerValue__last_index;
    acceptor1_ingress_registerValue__last_value__dbg := acceptor1_ingress_registerValue__last_value;
    acceptor1_ingress_registerValue__last_old_value__dbg := acceptor1_ingress_registerValue__last_old_value;
    acceptor1_ingress_registerValue__wrote_any__dbg := acceptor1_ingress_registerValue__wrote_any;
    acceptor1_ingress_registerValue__wrote_index0__dbg := acceptor1_ingress_registerValue__wrote_index0;
    acceptor1_ingress_registerValue__last0_old_value__dbg := acceptor1_ingress_registerValue__last0_old_value;
    acceptor1_ingress_registerValue__last0_value__dbg := acceptor1_ingress_registerValue__last0_value;
    acceptor2_ingress_learner_address__dbg0 := acceptor2_ingress_learner_address[0bv32];
    acceptor2_ingress_learner_address__last_index__dbg := acceptor2_ingress_learner_address__last_index;
    acceptor2_ingress_learner_address__last_value__dbg := acceptor2_ingress_learner_address__last_value;
    acceptor2_ingress_learner_address__last_old_value__dbg := acceptor2_ingress_learner_address__last_old_value;
    acceptor2_ingress_learner_address__wrote_any__dbg := acceptor2_ingress_learner_address__wrote_any;
    acceptor2_ingress_learner_address__wrote_index0__dbg := acceptor2_ingress_learner_address__wrote_index0;
    acceptor2_ingress_learner_address__last0_old_value__dbg := acceptor2_ingress_learner_address__last0_old_value;
    acceptor2_ingress_learner_address__last0_value__dbg := acceptor2_ingress_learner_address__last0_value;
    acceptor2_ingress_learner_mac_address__dbg0 := acceptor2_ingress_learner_mac_address[0bv32];
    acceptor2_ingress_learner_mac_address__last_index__dbg := acceptor2_ingress_learner_mac_address__last_index;
    acceptor2_ingress_learner_mac_address__last_value__dbg := acceptor2_ingress_learner_mac_address__last_value;
    acceptor2_ingress_learner_mac_address__last_old_value__dbg := acceptor2_ingress_learner_mac_address__last_old_value;
    acceptor2_ingress_learner_mac_address__wrote_any__dbg := acceptor2_ingress_learner_mac_address__wrote_any;
    acceptor2_ingress_learner_mac_address__wrote_index0__dbg := acceptor2_ingress_learner_mac_address__wrote_index0;
    acceptor2_ingress_learner_mac_address__last0_old_value__dbg := acceptor2_ingress_learner_mac_address__last0_old_value;
    acceptor2_ingress_learner_mac_address__last0_value__dbg := acceptor2_ingress_learner_mac_address__last0_value;
    acceptor2_ingress_my_ip_address__dbg0 := acceptor2_ingress_my_ip_address[0bv32];
    acceptor2_ingress_my_ip_address__last_index__dbg := acceptor2_ingress_my_ip_address__last_index;
    acceptor2_ingress_my_ip_address__last_value__dbg := acceptor2_ingress_my_ip_address__last_value;
    acceptor2_ingress_my_ip_address__last_old_value__dbg := acceptor2_ingress_my_ip_address__last_old_value;
    acceptor2_ingress_my_ip_address__wrote_any__dbg := acceptor2_ingress_my_ip_address__wrote_any;
    acceptor2_ingress_my_ip_address__wrote_index0__dbg := acceptor2_ingress_my_ip_address__wrote_index0;
    acceptor2_ingress_my_ip_address__last0_old_value__dbg := acceptor2_ingress_my_ip_address__last0_old_value;
    acceptor2_ingress_my_ip_address__last0_value__dbg := acceptor2_ingress_my_ip_address__last0_value;
    acceptor2_ingress_my_mac_address__dbg0 := acceptor2_ingress_my_mac_address[0bv32];
    acceptor2_ingress_my_mac_address__last_index__dbg := acceptor2_ingress_my_mac_address__last_index;
    acceptor2_ingress_my_mac_address__last_value__dbg := acceptor2_ingress_my_mac_address__last_value;
    acceptor2_ingress_my_mac_address__last_old_value__dbg := acceptor2_ingress_my_mac_address__last_old_value;
    acceptor2_ingress_my_mac_address__wrote_any__dbg := acceptor2_ingress_my_mac_address__wrote_any;
    acceptor2_ingress_my_mac_address__wrote_index0__dbg := acceptor2_ingress_my_mac_address__wrote_index0;
    acceptor2_ingress_my_mac_address__last0_old_value__dbg := acceptor2_ingress_my_mac_address__last0_old_value;
    acceptor2_ingress_my_mac_address__last0_value__dbg := acceptor2_ingress_my_mac_address__last0_value;
    acceptor2_ingress_registerAcceptorID__dbg0 := acceptor2_ingress_registerAcceptorID[0bv32];
    acceptor2_ingress_registerAcceptorID__last_index__dbg := acceptor2_ingress_registerAcceptorID__last_index;
    acceptor2_ingress_registerAcceptorID__last_value__dbg := acceptor2_ingress_registerAcceptorID__last_value;
    acceptor2_ingress_registerAcceptorID__last_old_value__dbg := acceptor2_ingress_registerAcceptorID__last_old_value;
    acceptor2_ingress_registerAcceptorID__wrote_any__dbg := acceptor2_ingress_registerAcceptorID__wrote_any;
    acceptor2_ingress_registerAcceptorID__wrote_index0__dbg := acceptor2_ingress_registerAcceptorID__wrote_index0;
    acceptor2_ingress_registerAcceptorID__last0_old_value__dbg := acceptor2_ingress_registerAcceptorID__last0_old_value;
    acceptor2_ingress_registerAcceptorID__last0_value__dbg := acceptor2_ingress_registerAcceptorID__last0_value;
    acceptor2_ingress_registerRound__dbg0 := acceptor2_ingress_registerRound[0bv32];
    acceptor2_ingress_registerRound__last_index__dbg := acceptor2_ingress_registerRound__last_index;
    acceptor2_ingress_registerRound__last_value__dbg := acceptor2_ingress_registerRound__last_value;
    acceptor2_ingress_registerRound__last_old_value__dbg := acceptor2_ingress_registerRound__last_old_value;
    acceptor2_ingress_registerRound__wrote_any__dbg := acceptor2_ingress_registerRound__wrote_any;
    acceptor2_ingress_registerRound__wrote_index0__dbg := acceptor2_ingress_registerRound__wrote_index0;
    acceptor2_ingress_registerRound__last0_old_value__dbg := acceptor2_ingress_registerRound__last0_old_value;
    acceptor2_ingress_registerRound__last0_value__dbg := acceptor2_ingress_registerRound__last0_value;
    acceptor2_ingress_registerVRound__dbg0 := acceptor2_ingress_registerVRound[0bv32];
    acceptor2_ingress_registerVRound__last_index__dbg := acceptor2_ingress_registerVRound__last_index;
    acceptor2_ingress_registerVRound__last_value__dbg := acceptor2_ingress_registerVRound__last_value;
    acceptor2_ingress_registerVRound__last_old_value__dbg := acceptor2_ingress_registerVRound__last_old_value;
    acceptor2_ingress_registerVRound__wrote_any__dbg := acceptor2_ingress_registerVRound__wrote_any;
    acceptor2_ingress_registerVRound__wrote_index0__dbg := acceptor2_ingress_registerVRound__wrote_index0;
    acceptor2_ingress_registerVRound__last0_old_value__dbg := acceptor2_ingress_registerVRound__last0_old_value;
    acceptor2_ingress_registerVRound__last0_value__dbg := acceptor2_ingress_registerVRound__last0_value;
    acceptor2_ingress_registerValue__dbg0 := acceptor2_ingress_registerValue[0bv32];
    acceptor2_ingress_registerValue__last_index__dbg := acceptor2_ingress_registerValue__last_index;
    acceptor2_ingress_registerValue__last_value__dbg := acceptor2_ingress_registerValue__last_value;
    acceptor2_ingress_registerValue__last_old_value__dbg := acceptor2_ingress_registerValue__last_old_value;
    acceptor2_ingress_registerValue__wrote_any__dbg := acceptor2_ingress_registerValue__wrote_any;
    acceptor2_ingress_registerValue__wrote_index0__dbg := acceptor2_ingress_registerValue__wrote_index0;
    acceptor2_ingress_registerValue__last0_old_value__dbg := acceptor2_ingress_registerValue__last0_old_value;
    acceptor2_ingress_registerValue__last0_value__dbg := acceptor2_ingress_registerValue__last0_value;
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
    // Global assertions
    assert (bvule.bv32$builtin(acceptor0_hdr.paxos.inst, 300bv32) && (acceptor0_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor1_hdr.paxos.inst, 300bv32) && (acceptor1_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor2_hdr.paxos.inst, 300bv32) && (acceptor2_hdr.paxos.inst != 300bv32));
  } else if (*) {
    // node pass -> acceptor1
    assume acceptor1_inbox_count > 0;
    acceptor1_inbox_count := acceptor1_inbox_count - 1;
    call acceptor1_mainProcedure();
    if (acceptor1_p4b_clone_i2e) {
      assume acceptor1_inbox_count < 3;
      acceptor1_pkt_external := false;
      acceptor1_inbox_count := acceptor1_inbox_count + 1;
    }
    acceptor1_p4b_clone_i2e := false;
    if (acceptor1_p4b_clone_e2e) {
      assume acceptor1_inbox_count < 3;
      acceptor1_pkt_external := false;
      acceptor1_inbox_count := acceptor1_inbox_count + 1;
    }
    acceptor1_p4b_clone_e2e := false;
    if (acceptor1_p4b_clone_i2i) {
      assume acceptor1_inbox_count < 3;
      acceptor1_pkt_external := false;
      acceptor1_inbox_count := acceptor1_inbox_count + 1;
    }
    acceptor1_p4b_clone_i2i := false;
    if (acceptor1_p4b_recirculate) {
      assume acceptor1_inbox_count < 3;
      acceptor1_pkt_external := false;
      acceptor1_inbox_count := acceptor1_inbox_count + 1;
    }
    acceptor1_p4b_recirculate := false;
    call acceptor1_Forward();
    // Register debug snapshot
    leader_ingress_ctrlInstane__dbg0 := leader_ingress_ctrlInstane[0bv32];
    leader_ingress_ctrlInstane__last_index__dbg := leader_ingress_ctrlInstane__last_index;
    leader_ingress_ctrlInstane__last_value__dbg := leader_ingress_ctrlInstane__last_value;
    leader_ingress_ctrlInstane__last_old_value__dbg := leader_ingress_ctrlInstane__last_old_value;
    leader_ingress_ctrlInstane__wrote_any__dbg := leader_ingress_ctrlInstane__wrote_any;
    leader_ingress_ctrlInstane__wrote_index0__dbg := leader_ingress_ctrlInstane__wrote_index0;
    leader_ingress_ctrlInstane__last0_old_value__dbg := leader_ingress_ctrlInstane__last0_old_value;
    leader_ingress_ctrlInstane__last0_value__dbg := leader_ingress_ctrlInstane__last0_value;
    acceptor0_ingress_learner_address__dbg0 := acceptor0_ingress_learner_address[0bv32];
    acceptor0_ingress_learner_address__last_index__dbg := acceptor0_ingress_learner_address__last_index;
    acceptor0_ingress_learner_address__last_value__dbg := acceptor0_ingress_learner_address__last_value;
    acceptor0_ingress_learner_address__last_old_value__dbg := acceptor0_ingress_learner_address__last_old_value;
    acceptor0_ingress_learner_address__wrote_any__dbg := acceptor0_ingress_learner_address__wrote_any;
    acceptor0_ingress_learner_address__wrote_index0__dbg := acceptor0_ingress_learner_address__wrote_index0;
    acceptor0_ingress_learner_address__last0_old_value__dbg := acceptor0_ingress_learner_address__last0_old_value;
    acceptor0_ingress_learner_address__last0_value__dbg := acceptor0_ingress_learner_address__last0_value;
    acceptor0_ingress_learner_mac_address__dbg0 := acceptor0_ingress_learner_mac_address[0bv32];
    acceptor0_ingress_learner_mac_address__last_index__dbg := acceptor0_ingress_learner_mac_address__last_index;
    acceptor0_ingress_learner_mac_address__last_value__dbg := acceptor0_ingress_learner_mac_address__last_value;
    acceptor0_ingress_learner_mac_address__last_old_value__dbg := acceptor0_ingress_learner_mac_address__last_old_value;
    acceptor0_ingress_learner_mac_address__wrote_any__dbg := acceptor0_ingress_learner_mac_address__wrote_any;
    acceptor0_ingress_learner_mac_address__wrote_index0__dbg := acceptor0_ingress_learner_mac_address__wrote_index0;
    acceptor0_ingress_learner_mac_address__last0_old_value__dbg := acceptor0_ingress_learner_mac_address__last0_old_value;
    acceptor0_ingress_learner_mac_address__last0_value__dbg := acceptor0_ingress_learner_mac_address__last0_value;
    acceptor0_ingress_my_ip_address__dbg0 := acceptor0_ingress_my_ip_address[0bv32];
    acceptor0_ingress_my_ip_address__last_index__dbg := acceptor0_ingress_my_ip_address__last_index;
    acceptor0_ingress_my_ip_address__last_value__dbg := acceptor0_ingress_my_ip_address__last_value;
    acceptor0_ingress_my_ip_address__last_old_value__dbg := acceptor0_ingress_my_ip_address__last_old_value;
    acceptor0_ingress_my_ip_address__wrote_any__dbg := acceptor0_ingress_my_ip_address__wrote_any;
    acceptor0_ingress_my_ip_address__wrote_index0__dbg := acceptor0_ingress_my_ip_address__wrote_index0;
    acceptor0_ingress_my_ip_address__last0_old_value__dbg := acceptor0_ingress_my_ip_address__last0_old_value;
    acceptor0_ingress_my_ip_address__last0_value__dbg := acceptor0_ingress_my_ip_address__last0_value;
    acceptor0_ingress_my_mac_address__dbg0 := acceptor0_ingress_my_mac_address[0bv32];
    acceptor0_ingress_my_mac_address__last_index__dbg := acceptor0_ingress_my_mac_address__last_index;
    acceptor0_ingress_my_mac_address__last_value__dbg := acceptor0_ingress_my_mac_address__last_value;
    acceptor0_ingress_my_mac_address__last_old_value__dbg := acceptor0_ingress_my_mac_address__last_old_value;
    acceptor0_ingress_my_mac_address__wrote_any__dbg := acceptor0_ingress_my_mac_address__wrote_any;
    acceptor0_ingress_my_mac_address__wrote_index0__dbg := acceptor0_ingress_my_mac_address__wrote_index0;
    acceptor0_ingress_my_mac_address__last0_old_value__dbg := acceptor0_ingress_my_mac_address__last0_old_value;
    acceptor0_ingress_my_mac_address__last0_value__dbg := acceptor0_ingress_my_mac_address__last0_value;
    acceptor0_ingress_registerAcceptorID__dbg0 := acceptor0_ingress_registerAcceptorID[0bv32];
    acceptor0_ingress_registerAcceptorID__last_index__dbg := acceptor0_ingress_registerAcceptorID__last_index;
    acceptor0_ingress_registerAcceptorID__last_value__dbg := acceptor0_ingress_registerAcceptorID__last_value;
    acceptor0_ingress_registerAcceptorID__last_old_value__dbg := acceptor0_ingress_registerAcceptorID__last_old_value;
    acceptor0_ingress_registerAcceptorID__wrote_any__dbg := acceptor0_ingress_registerAcceptorID__wrote_any;
    acceptor0_ingress_registerAcceptorID__wrote_index0__dbg := acceptor0_ingress_registerAcceptorID__wrote_index0;
    acceptor0_ingress_registerAcceptorID__last0_old_value__dbg := acceptor0_ingress_registerAcceptorID__last0_old_value;
    acceptor0_ingress_registerAcceptorID__last0_value__dbg := acceptor0_ingress_registerAcceptorID__last0_value;
    acceptor0_ingress_registerRound__dbg0 := acceptor0_ingress_registerRound[0bv32];
    acceptor0_ingress_registerRound__last_index__dbg := acceptor0_ingress_registerRound__last_index;
    acceptor0_ingress_registerRound__last_value__dbg := acceptor0_ingress_registerRound__last_value;
    acceptor0_ingress_registerRound__last_old_value__dbg := acceptor0_ingress_registerRound__last_old_value;
    acceptor0_ingress_registerRound__wrote_any__dbg := acceptor0_ingress_registerRound__wrote_any;
    acceptor0_ingress_registerRound__wrote_index0__dbg := acceptor0_ingress_registerRound__wrote_index0;
    acceptor0_ingress_registerRound__last0_old_value__dbg := acceptor0_ingress_registerRound__last0_old_value;
    acceptor0_ingress_registerRound__last0_value__dbg := acceptor0_ingress_registerRound__last0_value;
    acceptor0_ingress_registerVRound__dbg0 := acceptor0_ingress_registerVRound[0bv32];
    acceptor0_ingress_registerVRound__last_index__dbg := acceptor0_ingress_registerVRound__last_index;
    acceptor0_ingress_registerVRound__last_value__dbg := acceptor0_ingress_registerVRound__last_value;
    acceptor0_ingress_registerVRound__last_old_value__dbg := acceptor0_ingress_registerVRound__last_old_value;
    acceptor0_ingress_registerVRound__wrote_any__dbg := acceptor0_ingress_registerVRound__wrote_any;
    acceptor0_ingress_registerVRound__wrote_index0__dbg := acceptor0_ingress_registerVRound__wrote_index0;
    acceptor0_ingress_registerVRound__last0_old_value__dbg := acceptor0_ingress_registerVRound__last0_old_value;
    acceptor0_ingress_registerVRound__last0_value__dbg := acceptor0_ingress_registerVRound__last0_value;
    acceptor0_ingress_registerValue__dbg0 := acceptor0_ingress_registerValue[0bv32];
    acceptor0_ingress_registerValue__last_index__dbg := acceptor0_ingress_registerValue__last_index;
    acceptor0_ingress_registerValue__last_value__dbg := acceptor0_ingress_registerValue__last_value;
    acceptor0_ingress_registerValue__last_old_value__dbg := acceptor0_ingress_registerValue__last_old_value;
    acceptor0_ingress_registerValue__wrote_any__dbg := acceptor0_ingress_registerValue__wrote_any;
    acceptor0_ingress_registerValue__wrote_index0__dbg := acceptor0_ingress_registerValue__wrote_index0;
    acceptor0_ingress_registerValue__last0_old_value__dbg := acceptor0_ingress_registerValue__last0_old_value;
    acceptor0_ingress_registerValue__last0_value__dbg := acceptor0_ingress_registerValue__last0_value;
    acceptor1_ingress_learner_address__dbg0 := acceptor1_ingress_learner_address[0bv32];
    acceptor1_ingress_learner_address__last_index__dbg := acceptor1_ingress_learner_address__last_index;
    acceptor1_ingress_learner_address__last_value__dbg := acceptor1_ingress_learner_address__last_value;
    acceptor1_ingress_learner_address__last_old_value__dbg := acceptor1_ingress_learner_address__last_old_value;
    acceptor1_ingress_learner_address__wrote_any__dbg := acceptor1_ingress_learner_address__wrote_any;
    acceptor1_ingress_learner_address__wrote_index0__dbg := acceptor1_ingress_learner_address__wrote_index0;
    acceptor1_ingress_learner_address__last0_old_value__dbg := acceptor1_ingress_learner_address__last0_old_value;
    acceptor1_ingress_learner_address__last0_value__dbg := acceptor1_ingress_learner_address__last0_value;
    acceptor1_ingress_learner_mac_address__dbg0 := acceptor1_ingress_learner_mac_address[0bv32];
    acceptor1_ingress_learner_mac_address__last_index__dbg := acceptor1_ingress_learner_mac_address__last_index;
    acceptor1_ingress_learner_mac_address__last_value__dbg := acceptor1_ingress_learner_mac_address__last_value;
    acceptor1_ingress_learner_mac_address__last_old_value__dbg := acceptor1_ingress_learner_mac_address__last_old_value;
    acceptor1_ingress_learner_mac_address__wrote_any__dbg := acceptor1_ingress_learner_mac_address__wrote_any;
    acceptor1_ingress_learner_mac_address__wrote_index0__dbg := acceptor1_ingress_learner_mac_address__wrote_index0;
    acceptor1_ingress_learner_mac_address__last0_old_value__dbg := acceptor1_ingress_learner_mac_address__last0_old_value;
    acceptor1_ingress_learner_mac_address__last0_value__dbg := acceptor1_ingress_learner_mac_address__last0_value;
    acceptor1_ingress_my_ip_address__dbg0 := acceptor1_ingress_my_ip_address[0bv32];
    acceptor1_ingress_my_ip_address__last_index__dbg := acceptor1_ingress_my_ip_address__last_index;
    acceptor1_ingress_my_ip_address__last_value__dbg := acceptor1_ingress_my_ip_address__last_value;
    acceptor1_ingress_my_ip_address__last_old_value__dbg := acceptor1_ingress_my_ip_address__last_old_value;
    acceptor1_ingress_my_ip_address__wrote_any__dbg := acceptor1_ingress_my_ip_address__wrote_any;
    acceptor1_ingress_my_ip_address__wrote_index0__dbg := acceptor1_ingress_my_ip_address__wrote_index0;
    acceptor1_ingress_my_ip_address__last0_old_value__dbg := acceptor1_ingress_my_ip_address__last0_old_value;
    acceptor1_ingress_my_ip_address__last0_value__dbg := acceptor1_ingress_my_ip_address__last0_value;
    acceptor1_ingress_my_mac_address__dbg0 := acceptor1_ingress_my_mac_address[0bv32];
    acceptor1_ingress_my_mac_address__last_index__dbg := acceptor1_ingress_my_mac_address__last_index;
    acceptor1_ingress_my_mac_address__last_value__dbg := acceptor1_ingress_my_mac_address__last_value;
    acceptor1_ingress_my_mac_address__last_old_value__dbg := acceptor1_ingress_my_mac_address__last_old_value;
    acceptor1_ingress_my_mac_address__wrote_any__dbg := acceptor1_ingress_my_mac_address__wrote_any;
    acceptor1_ingress_my_mac_address__wrote_index0__dbg := acceptor1_ingress_my_mac_address__wrote_index0;
    acceptor1_ingress_my_mac_address__last0_old_value__dbg := acceptor1_ingress_my_mac_address__last0_old_value;
    acceptor1_ingress_my_mac_address__last0_value__dbg := acceptor1_ingress_my_mac_address__last0_value;
    acceptor1_ingress_registerAcceptorID__dbg0 := acceptor1_ingress_registerAcceptorID[0bv32];
    acceptor1_ingress_registerAcceptorID__last_index__dbg := acceptor1_ingress_registerAcceptorID__last_index;
    acceptor1_ingress_registerAcceptorID__last_value__dbg := acceptor1_ingress_registerAcceptorID__last_value;
    acceptor1_ingress_registerAcceptorID__last_old_value__dbg := acceptor1_ingress_registerAcceptorID__last_old_value;
    acceptor1_ingress_registerAcceptorID__wrote_any__dbg := acceptor1_ingress_registerAcceptorID__wrote_any;
    acceptor1_ingress_registerAcceptorID__wrote_index0__dbg := acceptor1_ingress_registerAcceptorID__wrote_index0;
    acceptor1_ingress_registerAcceptorID__last0_old_value__dbg := acceptor1_ingress_registerAcceptorID__last0_old_value;
    acceptor1_ingress_registerAcceptorID__last0_value__dbg := acceptor1_ingress_registerAcceptorID__last0_value;
    acceptor1_ingress_registerRound__dbg0 := acceptor1_ingress_registerRound[0bv32];
    acceptor1_ingress_registerRound__last_index__dbg := acceptor1_ingress_registerRound__last_index;
    acceptor1_ingress_registerRound__last_value__dbg := acceptor1_ingress_registerRound__last_value;
    acceptor1_ingress_registerRound__last_old_value__dbg := acceptor1_ingress_registerRound__last_old_value;
    acceptor1_ingress_registerRound__wrote_any__dbg := acceptor1_ingress_registerRound__wrote_any;
    acceptor1_ingress_registerRound__wrote_index0__dbg := acceptor1_ingress_registerRound__wrote_index0;
    acceptor1_ingress_registerRound__last0_old_value__dbg := acceptor1_ingress_registerRound__last0_old_value;
    acceptor1_ingress_registerRound__last0_value__dbg := acceptor1_ingress_registerRound__last0_value;
    acceptor1_ingress_registerVRound__dbg0 := acceptor1_ingress_registerVRound[0bv32];
    acceptor1_ingress_registerVRound__last_index__dbg := acceptor1_ingress_registerVRound__last_index;
    acceptor1_ingress_registerVRound__last_value__dbg := acceptor1_ingress_registerVRound__last_value;
    acceptor1_ingress_registerVRound__last_old_value__dbg := acceptor1_ingress_registerVRound__last_old_value;
    acceptor1_ingress_registerVRound__wrote_any__dbg := acceptor1_ingress_registerVRound__wrote_any;
    acceptor1_ingress_registerVRound__wrote_index0__dbg := acceptor1_ingress_registerVRound__wrote_index0;
    acceptor1_ingress_registerVRound__last0_old_value__dbg := acceptor1_ingress_registerVRound__last0_old_value;
    acceptor1_ingress_registerVRound__last0_value__dbg := acceptor1_ingress_registerVRound__last0_value;
    acceptor1_ingress_registerValue__dbg0 := acceptor1_ingress_registerValue[0bv32];
    acceptor1_ingress_registerValue__last_index__dbg := acceptor1_ingress_registerValue__last_index;
    acceptor1_ingress_registerValue__last_value__dbg := acceptor1_ingress_registerValue__last_value;
    acceptor1_ingress_registerValue__last_old_value__dbg := acceptor1_ingress_registerValue__last_old_value;
    acceptor1_ingress_registerValue__wrote_any__dbg := acceptor1_ingress_registerValue__wrote_any;
    acceptor1_ingress_registerValue__wrote_index0__dbg := acceptor1_ingress_registerValue__wrote_index0;
    acceptor1_ingress_registerValue__last0_old_value__dbg := acceptor1_ingress_registerValue__last0_old_value;
    acceptor1_ingress_registerValue__last0_value__dbg := acceptor1_ingress_registerValue__last0_value;
    acceptor2_ingress_learner_address__dbg0 := acceptor2_ingress_learner_address[0bv32];
    acceptor2_ingress_learner_address__last_index__dbg := acceptor2_ingress_learner_address__last_index;
    acceptor2_ingress_learner_address__last_value__dbg := acceptor2_ingress_learner_address__last_value;
    acceptor2_ingress_learner_address__last_old_value__dbg := acceptor2_ingress_learner_address__last_old_value;
    acceptor2_ingress_learner_address__wrote_any__dbg := acceptor2_ingress_learner_address__wrote_any;
    acceptor2_ingress_learner_address__wrote_index0__dbg := acceptor2_ingress_learner_address__wrote_index0;
    acceptor2_ingress_learner_address__last0_old_value__dbg := acceptor2_ingress_learner_address__last0_old_value;
    acceptor2_ingress_learner_address__last0_value__dbg := acceptor2_ingress_learner_address__last0_value;
    acceptor2_ingress_learner_mac_address__dbg0 := acceptor2_ingress_learner_mac_address[0bv32];
    acceptor2_ingress_learner_mac_address__last_index__dbg := acceptor2_ingress_learner_mac_address__last_index;
    acceptor2_ingress_learner_mac_address__last_value__dbg := acceptor2_ingress_learner_mac_address__last_value;
    acceptor2_ingress_learner_mac_address__last_old_value__dbg := acceptor2_ingress_learner_mac_address__last_old_value;
    acceptor2_ingress_learner_mac_address__wrote_any__dbg := acceptor2_ingress_learner_mac_address__wrote_any;
    acceptor2_ingress_learner_mac_address__wrote_index0__dbg := acceptor2_ingress_learner_mac_address__wrote_index0;
    acceptor2_ingress_learner_mac_address__last0_old_value__dbg := acceptor2_ingress_learner_mac_address__last0_old_value;
    acceptor2_ingress_learner_mac_address__last0_value__dbg := acceptor2_ingress_learner_mac_address__last0_value;
    acceptor2_ingress_my_ip_address__dbg0 := acceptor2_ingress_my_ip_address[0bv32];
    acceptor2_ingress_my_ip_address__last_index__dbg := acceptor2_ingress_my_ip_address__last_index;
    acceptor2_ingress_my_ip_address__last_value__dbg := acceptor2_ingress_my_ip_address__last_value;
    acceptor2_ingress_my_ip_address__last_old_value__dbg := acceptor2_ingress_my_ip_address__last_old_value;
    acceptor2_ingress_my_ip_address__wrote_any__dbg := acceptor2_ingress_my_ip_address__wrote_any;
    acceptor2_ingress_my_ip_address__wrote_index0__dbg := acceptor2_ingress_my_ip_address__wrote_index0;
    acceptor2_ingress_my_ip_address__last0_old_value__dbg := acceptor2_ingress_my_ip_address__last0_old_value;
    acceptor2_ingress_my_ip_address__last0_value__dbg := acceptor2_ingress_my_ip_address__last0_value;
    acceptor2_ingress_my_mac_address__dbg0 := acceptor2_ingress_my_mac_address[0bv32];
    acceptor2_ingress_my_mac_address__last_index__dbg := acceptor2_ingress_my_mac_address__last_index;
    acceptor2_ingress_my_mac_address__last_value__dbg := acceptor2_ingress_my_mac_address__last_value;
    acceptor2_ingress_my_mac_address__last_old_value__dbg := acceptor2_ingress_my_mac_address__last_old_value;
    acceptor2_ingress_my_mac_address__wrote_any__dbg := acceptor2_ingress_my_mac_address__wrote_any;
    acceptor2_ingress_my_mac_address__wrote_index0__dbg := acceptor2_ingress_my_mac_address__wrote_index0;
    acceptor2_ingress_my_mac_address__last0_old_value__dbg := acceptor2_ingress_my_mac_address__last0_old_value;
    acceptor2_ingress_my_mac_address__last0_value__dbg := acceptor2_ingress_my_mac_address__last0_value;
    acceptor2_ingress_registerAcceptorID__dbg0 := acceptor2_ingress_registerAcceptorID[0bv32];
    acceptor2_ingress_registerAcceptorID__last_index__dbg := acceptor2_ingress_registerAcceptorID__last_index;
    acceptor2_ingress_registerAcceptorID__last_value__dbg := acceptor2_ingress_registerAcceptorID__last_value;
    acceptor2_ingress_registerAcceptorID__last_old_value__dbg := acceptor2_ingress_registerAcceptorID__last_old_value;
    acceptor2_ingress_registerAcceptorID__wrote_any__dbg := acceptor2_ingress_registerAcceptorID__wrote_any;
    acceptor2_ingress_registerAcceptorID__wrote_index0__dbg := acceptor2_ingress_registerAcceptorID__wrote_index0;
    acceptor2_ingress_registerAcceptorID__last0_old_value__dbg := acceptor2_ingress_registerAcceptorID__last0_old_value;
    acceptor2_ingress_registerAcceptorID__last0_value__dbg := acceptor2_ingress_registerAcceptorID__last0_value;
    acceptor2_ingress_registerRound__dbg0 := acceptor2_ingress_registerRound[0bv32];
    acceptor2_ingress_registerRound__last_index__dbg := acceptor2_ingress_registerRound__last_index;
    acceptor2_ingress_registerRound__last_value__dbg := acceptor2_ingress_registerRound__last_value;
    acceptor2_ingress_registerRound__last_old_value__dbg := acceptor2_ingress_registerRound__last_old_value;
    acceptor2_ingress_registerRound__wrote_any__dbg := acceptor2_ingress_registerRound__wrote_any;
    acceptor2_ingress_registerRound__wrote_index0__dbg := acceptor2_ingress_registerRound__wrote_index0;
    acceptor2_ingress_registerRound__last0_old_value__dbg := acceptor2_ingress_registerRound__last0_old_value;
    acceptor2_ingress_registerRound__last0_value__dbg := acceptor2_ingress_registerRound__last0_value;
    acceptor2_ingress_registerVRound__dbg0 := acceptor2_ingress_registerVRound[0bv32];
    acceptor2_ingress_registerVRound__last_index__dbg := acceptor2_ingress_registerVRound__last_index;
    acceptor2_ingress_registerVRound__last_value__dbg := acceptor2_ingress_registerVRound__last_value;
    acceptor2_ingress_registerVRound__last_old_value__dbg := acceptor2_ingress_registerVRound__last_old_value;
    acceptor2_ingress_registerVRound__wrote_any__dbg := acceptor2_ingress_registerVRound__wrote_any;
    acceptor2_ingress_registerVRound__wrote_index0__dbg := acceptor2_ingress_registerVRound__wrote_index0;
    acceptor2_ingress_registerVRound__last0_old_value__dbg := acceptor2_ingress_registerVRound__last0_old_value;
    acceptor2_ingress_registerVRound__last0_value__dbg := acceptor2_ingress_registerVRound__last0_value;
    acceptor2_ingress_registerValue__dbg0 := acceptor2_ingress_registerValue[0bv32];
    acceptor2_ingress_registerValue__last_index__dbg := acceptor2_ingress_registerValue__last_index;
    acceptor2_ingress_registerValue__last_value__dbg := acceptor2_ingress_registerValue__last_value;
    acceptor2_ingress_registerValue__last_old_value__dbg := acceptor2_ingress_registerValue__last_old_value;
    acceptor2_ingress_registerValue__wrote_any__dbg := acceptor2_ingress_registerValue__wrote_any;
    acceptor2_ingress_registerValue__wrote_index0__dbg := acceptor2_ingress_registerValue__wrote_index0;
    acceptor2_ingress_registerValue__last0_old_value__dbg := acceptor2_ingress_registerValue__last0_old_value;
    acceptor2_ingress_registerValue__last0_value__dbg := acceptor2_ingress_registerValue__last0_value;
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
    // Global assertions
    assert (bvule.bv32$builtin(acceptor0_hdr.paxos.inst, 300bv32) && (acceptor0_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor1_hdr.paxos.inst, 300bv32) && (acceptor1_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor2_hdr.paxos.inst, 300bv32) && (acceptor2_hdr.paxos.inst != 300bv32));
  } else if (*) {
    // node pass -> acceptor2
    assume acceptor2_inbox_count > 0;
    acceptor2_inbox_count := acceptor2_inbox_count - 1;
    call acceptor2_mainProcedure();
    if (acceptor2_p4b_clone_i2e) {
      assume acceptor2_inbox_count < 3;
      acceptor2_pkt_external := false;
      acceptor2_inbox_count := acceptor2_inbox_count + 1;
    }
    acceptor2_p4b_clone_i2e := false;
    if (acceptor2_p4b_clone_e2e) {
      assume acceptor2_inbox_count < 3;
      acceptor2_pkt_external := false;
      acceptor2_inbox_count := acceptor2_inbox_count + 1;
    }
    acceptor2_p4b_clone_e2e := false;
    if (acceptor2_p4b_clone_i2i) {
      assume acceptor2_inbox_count < 3;
      acceptor2_pkt_external := false;
      acceptor2_inbox_count := acceptor2_inbox_count + 1;
    }
    acceptor2_p4b_clone_i2i := false;
    if (acceptor2_p4b_recirculate) {
      assume acceptor2_inbox_count < 3;
      acceptor2_pkt_external := false;
      acceptor2_inbox_count := acceptor2_inbox_count + 1;
    }
    acceptor2_p4b_recirculate := false;
    call acceptor2_Forward();
    // Register debug snapshot
    leader_ingress_ctrlInstane__dbg0 := leader_ingress_ctrlInstane[0bv32];
    leader_ingress_ctrlInstane__last_index__dbg := leader_ingress_ctrlInstane__last_index;
    leader_ingress_ctrlInstane__last_value__dbg := leader_ingress_ctrlInstane__last_value;
    leader_ingress_ctrlInstane__last_old_value__dbg := leader_ingress_ctrlInstane__last_old_value;
    leader_ingress_ctrlInstane__wrote_any__dbg := leader_ingress_ctrlInstane__wrote_any;
    leader_ingress_ctrlInstane__wrote_index0__dbg := leader_ingress_ctrlInstane__wrote_index0;
    leader_ingress_ctrlInstane__last0_old_value__dbg := leader_ingress_ctrlInstane__last0_old_value;
    leader_ingress_ctrlInstane__last0_value__dbg := leader_ingress_ctrlInstane__last0_value;
    acceptor0_ingress_learner_address__dbg0 := acceptor0_ingress_learner_address[0bv32];
    acceptor0_ingress_learner_address__last_index__dbg := acceptor0_ingress_learner_address__last_index;
    acceptor0_ingress_learner_address__last_value__dbg := acceptor0_ingress_learner_address__last_value;
    acceptor0_ingress_learner_address__last_old_value__dbg := acceptor0_ingress_learner_address__last_old_value;
    acceptor0_ingress_learner_address__wrote_any__dbg := acceptor0_ingress_learner_address__wrote_any;
    acceptor0_ingress_learner_address__wrote_index0__dbg := acceptor0_ingress_learner_address__wrote_index0;
    acceptor0_ingress_learner_address__last0_old_value__dbg := acceptor0_ingress_learner_address__last0_old_value;
    acceptor0_ingress_learner_address__last0_value__dbg := acceptor0_ingress_learner_address__last0_value;
    acceptor0_ingress_learner_mac_address__dbg0 := acceptor0_ingress_learner_mac_address[0bv32];
    acceptor0_ingress_learner_mac_address__last_index__dbg := acceptor0_ingress_learner_mac_address__last_index;
    acceptor0_ingress_learner_mac_address__last_value__dbg := acceptor0_ingress_learner_mac_address__last_value;
    acceptor0_ingress_learner_mac_address__last_old_value__dbg := acceptor0_ingress_learner_mac_address__last_old_value;
    acceptor0_ingress_learner_mac_address__wrote_any__dbg := acceptor0_ingress_learner_mac_address__wrote_any;
    acceptor0_ingress_learner_mac_address__wrote_index0__dbg := acceptor0_ingress_learner_mac_address__wrote_index0;
    acceptor0_ingress_learner_mac_address__last0_old_value__dbg := acceptor0_ingress_learner_mac_address__last0_old_value;
    acceptor0_ingress_learner_mac_address__last0_value__dbg := acceptor0_ingress_learner_mac_address__last0_value;
    acceptor0_ingress_my_ip_address__dbg0 := acceptor0_ingress_my_ip_address[0bv32];
    acceptor0_ingress_my_ip_address__last_index__dbg := acceptor0_ingress_my_ip_address__last_index;
    acceptor0_ingress_my_ip_address__last_value__dbg := acceptor0_ingress_my_ip_address__last_value;
    acceptor0_ingress_my_ip_address__last_old_value__dbg := acceptor0_ingress_my_ip_address__last_old_value;
    acceptor0_ingress_my_ip_address__wrote_any__dbg := acceptor0_ingress_my_ip_address__wrote_any;
    acceptor0_ingress_my_ip_address__wrote_index0__dbg := acceptor0_ingress_my_ip_address__wrote_index0;
    acceptor0_ingress_my_ip_address__last0_old_value__dbg := acceptor0_ingress_my_ip_address__last0_old_value;
    acceptor0_ingress_my_ip_address__last0_value__dbg := acceptor0_ingress_my_ip_address__last0_value;
    acceptor0_ingress_my_mac_address__dbg0 := acceptor0_ingress_my_mac_address[0bv32];
    acceptor0_ingress_my_mac_address__last_index__dbg := acceptor0_ingress_my_mac_address__last_index;
    acceptor0_ingress_my_mac_address__last_value__dbg := acceptor0_ingress_my_mac_address__last_value;
    acceptor0_ingress_my_mac_address__last_old_value__dbg := acceptor0_ingress_my_mac_address__last_old_value;
    acceptor0_ingress_my_mac_address__wrote_any__dbg := acceptor0_ingress_my_mac_address__wrote_any;
    acceptor0_ingress_my_mac_address__wrote_index0__dbg := acceptor0_ingress_my_mac_address__wrote_index0;
    acceptor0_ingress_my_mac_address__last0_old_value__dbg := acceptor0_ingress_my_mac_address__last0_old_value;
    acceptor0_ingress_my_mac_address__last0_value__dbg := acceptor0_ingress_my_mac_address__last0_value;
    acceptor0_ingress_registerAcceptorID__dbg0 := acceptor0_ingress_registerAcceptorID[0bv32];
    acceptor0_ingress_registerAcceptorID__last_index__dbg := acceptor0_ingress_registerAcceptorID__last_index;
    acceptor0_ingress_registerAcceptorID__last_value__dbg := acceptor0_ingress_registerAcceptorID__last_value;
    acceptor0_ingress_registerAcceptorID__last_old_value__dbg := acceptor0_ingress_registerAcceptorID__last_old_value;
    acceptor0_ingress_registerAcceptorID__wrote_any__dbg := acceptor0_ingress_registerAcceptorID__wrote_any;
    acceptor0_ingress_registerAcceptorID__wrote_index0__dbg := acceptor0_ingress_registerAcceptorID__wrote_index0;
    acceptor0_ingress_registerAcceptorID__last0_old_value__dbg := acceptor0_ingress_registerAcceptorID__last0_old_value;
    acceptor0_ingress_registerAcceptorID__last0_value__dbg := acceptor0_ingress_registerAcceptorID__last0_value;
    acceptor0_ingress_registerRound__dbg0 := acceptor0_ingress_registerRound[0bv32];
    acceptor0_ingress_registerRound__last_index__dbg := acceptor0_ingress_registerRound__last_index;
    acceptor0_ingress_registerRound__last_value__dbg := acceptor0_ingress_registerRound__last_value;
    acceptor0_ingress_registerRound__last_old_value__dbg := acceptor0_ingress_registerRound__last_old_value;
    acceptor0_ingress_registerRound__wrote_any__dbg := acceptor0_ingress_registerRound__wrote_any;
    acceptor0_ingress_registerRound__wrote_index0__dbg := acceptor0_ingress_registerRound__wrote_index0;
    acceptor0_ingress_registerRound__last0_old_value__dbg := acceptor0_ingress_registerRound__last0_old_value;
    acceptor0_ingress_registerRound__last0_value__dbg := acceptor0_ingress_registerRound__last0_value;
    acceptor0_ingress_registerVRound__dbg0 := acceptor0_ingress_registerVRound[0bv32];
    acceptor0_ingress_registerVRound__last_index__dbg := acceptor0_ingress_registerVRound__last_index;
    acceptor0_ingress_registerVRound__last_value__dbg := acceptor0_ingress_registerVRound__last_value;
    acceptor0_ingress_registerVRound__last_old_value__dbg := acceptor0_ingress_registerVRound__last_old_value;
    acceptor0_ingress_registerVRound__wrote_any__dbg := acceptor0_ingress_registerVRound__wrote_any;
    acceptor0_ingress_registerVRound__wrote_index0__dbg := acceptor0_ingress_registerVRound__wrote_index0;
    acceptor0_ingress_registerVRound__last0_old_value__dbg := acceptor0_ingress_registerVRound__last0_old_value;
    acceptor0_ingress_registerVRound__last0_value__dbg := acceptor0_ingress_registerVRound__last0_value;
    acceptor0_ingress_registerValue__dbg0 := acceptor0_ingress_registerValue[0bv32];
    acceptor0_ingress_registerValue__last_index__dbg := acceptor0_ingress_registerValue__last_index;
    acceptor0_ingress_registerValue__last_value__dbg := acceptor0_ingress_registerValue__last_value;
    acceptor0_ingress_registerValue__last_old_value__dbg := acceptor0_ingress_registerValue__last_old_value;
    acceptor0_ingress_registerValue__wrote_any__dbg := acceptor0_ingress_registerValue__wrote_any;
    acceptor0_ingress_registerValue__wrote_index0__dbg := acceptor0_ingress_registerValue__wrote_index0;
    acceptor0_ingress_registerValue__last0_old_value__dbg := acceptor0_ingress_registerValue__last0_old_value;
    acceptor0_ingress_registerValue__last0_value__dbg := acceptor0_ingress_registerValue__last0_value;
    acceptor1_ingress_learner_address__dbg0 := acceptor1_ingress_learner_address[0bv32];
    acceptor1_ingress_learner_address__last_index__dbg := acceptor1_ingress_learner_address__last_index;
    acceptor1_ingress_learner_address__last_value__dbg := acceptor1_ingress_learner_address__last_value;
    acceptor1_ingress_learner_address__last_old_value__dbg := acceptor1_ingress_learner_address__last_old_value;
    acceptor1_ingress_learner_address__wrote_any__dbg := acceptor1_ingress_learner_address__wrote_any;
    acceptor1_ingress_learner_address__wrote_index0__dbg := acceptor1_ingress_learner_address__wrote_index0;
    acceptor1_ingress_learner_address__last0_old_value__dbg := acceptor1_ingress_learner_address__last0_old_value;
    acceptor1_ingress_learner_address__last0_value__dbg := acceptor1_ingress_learner_address__last0_value;
    acceptor1_ingress_learner_mac_address__dbg0 := acceptor1_ingress_learner_mac_address[0bv32];
    acceptor1_ingress_learner_mac_address__last_index__dbg := acceptor1_ingress_learner_mac_address__last_index;
    acceptor1_ingress_learner_mac_address__last_value__dbg := acceptor1_ingress_learner_mac_address__last_value;
    acceptor1_ingress_learner_mac_address__last_old_value__dbg := acceptor1_ingress_learner_mac_address__last_old_value;
    acceptor1_ingress_learner_mac_address__wrote_any__dbg := acceptor1_ingress_learner_mac_address__wrote_any;
    acceptor1_ingress_learner_mac_address__wrote_index0__dbg := acceptor1_ingress_learner_mac_address__wrote_index0;
    acceptor1_ingress_learner_mac_address__last0_old_value__dbg := acceptor1_ingress_learner_mac_address__last0_old_value;
    acceptor1_ingress_learner_mac_address__last0_value__dbg := acceptor1_ingress_learner_mac_address__last0_value;
    acceptor1_ingress_my_ip_address__dbg0 := acceptor1_ingress_my_ip_address[0bv32];
    acceptor1_ingress_my_ip_address__last_index__dbg := acceptor1_ingress_my_ip_address__last_index;
    acceptor1_ingress_my_ip_address__last_value__dbg := acceptor1_ingress_my_ip_address__last_value;
    acceptor1_ingress_my_ip_address__last_old_value__dbg := acceptor1_ingress_my_ip_address__last_old_value;
    acceptor1_ingress_my_ip_address__wrote_any__dbg := acceptor1_ingress_my_ip_address__wrote_any;
    acceptor1_ingress_my_ip_address__wrote_index0__dbg := acceptor1_ingress_my_ip_address__wrote_index0;
    acceptor1_ingress_my_ip_address__last0_old_value__dbg := acceptor1_ingress_my_ip_address__last0_old_value;
    acceptor1_ingress_my_ip_address__last0_value__dbg := acceptor1_ingress_my_ip_address__last0_value;
    acceptor1_ingress_my_mac_address__dbg0 := acceptor1_ingress_my_mac_address[0bv32];
    acceptor1_ingress_my_mac_address__last_index__dbg := acceptor1_ingress_my_mac_address__last_index;
    acceptor1_ingress_my_mac_address__last_value__dbg := acceptor1_ingress_my_mac_address__last_value;
    acceptor1_ingress_my_mac_address__last_old_value__dbg := acceptor1_ingress_my_mac_address__last_old_value;
    acceptor1_ingress_my_mac_address__wrote_any__dbg := acceptor1_ingress_my_mac_address__wrote_any;
    acceptor1_ingress_my_mac_address__wrote_index0__dbg := acceptor1_ingress_my_mac_address__wrote_index0;
    acceptor1_ingress_my_mac_address__last0_old_value__dbg := acceptor1_ingress_my_mac_address__last0_old_value;
    acceptor1_ingress_my_mac_address__last0_value__dbg := acceptor1_ingress_my_mac_address__last0_value;
    acceptor1_ingress_registerAcceptorID__dbg0 := acceptor1_ingress_registerAcceptorID[0bv32];
    acceptor1_ingress_registerAcceptorID__last_index__dbg := acceptor1_ingress_registerAcceptorID__last_index;
    acceptor1_ingress_registerAcceptorID__last_value__dbg := acceptor1_ingress_registerAcceptorID__last_value;
    acceptor1_ingress_registerAcceptorID__last_old_value__dbg := acceptor1_ingress_registerAcceptorID__last_old_value;
    acceptor1_ingress_registerAcceptorID__wrote_any__dbg := acceptor1_ingress_registerAcceptorID__wrote_any;
    acceptor1_ingress_registerAcceptorID__wrote_index0__dbg := acceptor1_ingress_registerAcceptorID__wrote_index0;
    acceptor1_ingress_registerAcceptorID__last0_old_value__dbg := acceptor1_ingress_registerAcceptorID__last0_old_value;
    acceptor1_ingress_registerAcceptorID__last0_value__dbg := acceptor1_ingress_registerAcceptorID__last0_value;
    acceptor1_ingress_registerRound__dbg0 := acceptor1_ingress_registerRound[0bv32];
    acceptor1_ingress_registerRound__last_index__dbg := acceptor1_ingress_registerRound__last_index;
    acceptor1_ingress_registerRound__last_value__dbg := acceptor1_ingress_registerRound__last_value;
    acceptor1_ingress_registerRound__last_old_value__dbg := acceptor1_ingress_registerRound__last_old_value;
    acceptor1_ingress_registerRound__wrote_any__dbg := acceptor1_ingress_registerRound__wrote_any;
    acceptor1_ingress_registerRound__wrote_index0__dbg := acceptor1_ingress_registerRound__wrote_index0;
    acceptor1_ingress_registerRound__last0_old_value__dbg := acceptor1_ingress_registerRound__last0_old_value;
    acceptor1_ingress_registerRound__last0_value__dbg := acceptor1_ingress_registerRound__last0_value;
    acceptor1_ingress_registerVRound__dbg0 := acceptor1_ingress_registerVRound[0bv32];
    acceptor1_ingress_registerVRound__last_index__dbg := acceptor1_ingress_registerVRound__last_index;
    acceptor1_ingress_registerVRound__last_value__dbg := acceptor1_ingress_registerVRound__last_value;
    acceptor1_ingress_registerVRound__last_old_value__dbg := acceptor1_ingress_registerVRound__last_old_value;
    acceptor1_ingress_registerVRound__wrote_any__dbg := acceptor1_ingress_registerVRound__wrote_any;
    acceptor1_ingress_registerVRound__wrote_index0__dbg := acceptor1_ingress_registerVRound__wrote_index0;
    acceptor1_ingress_registerVRound__last0_old_value__dbg := acceptor1_ingress_registerVRound__last0_old_value;
    acceptor1_ingress_registerVRound__last0_value__dbg := acceptor1_ingress_registerVRound__last0_value;
    acceptor1_ingress_registerValue__dbg0 := acceptor1_ingress_registerValue[0bv32];
    acceptor1_ingress_registerValue__last_index__dbg := acceptor1_ingress_registerValue__last_index;
    acceptor1_ingress_registerValue__last_value__dbg := acceptor1_ingress_registerValue__last_value;
    acceptor1_ingress_registerValue__last_old_value__dbg := acceptor1_ingress_registerValue__last_old_value;
    acceptor1_ingress_registerValue__wrote_any__dbg := acceptor1_ingress_registerValue__wrote_any;
    acceptor1_ingress_registerValue__wrote_index0__dbg := acceptor1_ingress_registerValue__wrote_index0;
    acceptor1_ingress_registerValue__last0_old_value__dbg := acceptor1_ingress_registerValue__last0_old_value;
    acceptor1_ingress_registerValue__last0_value__dbg := acceptor1_ingress_registerValue__last0_value;
    acceptor2_ingress_learner_address__dbg0 := acceptor2_ingress_learner_address[0bv32];
    acceptor2_ingress_learner_address__last_index__dbg := acceptor2_ingress_learner_address__last_index;
    acceptor2_ingress_learner_address__last_value__dbg := acceptor2_ingress_learner_address__last_value;
    acceptor2_ingress_learner_address__last_old_value__dbg := acceptor2_ingress_learner_address__last_old_value;
    acceptor2_ingress_learner_address__wrote_any__dbg := acceptor2_ingress_learner_address__wrote_any;
    acceptor2_ingress_learner_address__wrote_index0__dbg := acceptor2_ingress_learner_address__wrote_index0;
    acceptor2_ingress_learner_address__last0_old_value__dbg := acceptor2_ingress_learner_address__last0_old_value;
    acceptor2_ingress_learner_address__last0_value__dbg := acceptor2_ingress_learner_address__last0_value;
    acceptor2_ingress_learner_mac_address__dbg0 := acceptor2_ingress_learner_mac_address[0bv32];
    acceptor2_ingress_learner_mac_address__last_index__dbg := acceptor2_ingress_learner_mac_address__last_index;
    acceptor2_ingress_learner_mac_address__last_value__dbg := acceptor2_ingress_learner_mac_address__last_value;
    acceptor2_ingress_learner_mac_address__last_old_value__dbg := acceptor2_ingress_learner_mac_address__last_old_value;
    acceptor2_ingress_learner_mac_address__wrote_any__dbg := acceptor2_ingress_learner_mac_address__wrote_any;
    acceptor2_ingress_learner_mac_address__wrote_index0__dbg := acceptor2_ingress_learner_mac_address__wrote_index0;
    acceptor2_ingress_learner_mac_address__last0_old_value__dbg := acceptor2_ingress_learner_mac_address__last0_old_value;
    acceptor2_ingress_learner_mac_address__last0_value__dbg := acceptor2_ingress_learner_mac_address__last0_value;
    acceptor2_ingress_my_ip_address__dbg0 := acceptor2_ingress_my_ip_address[0bv32];
    acceptor2_ingress_my_ip_address__last_index__dbg := acceptor2_ingress_my_ip_address__last_index;
    acceptor2_ingress_my_ip_address__last_value__dbg := acceptor2_ingress_my_ip_address__last_value;
    acceptor2_ingress_my_ip_address__last_old_value__dbg := acceptor2_ingress_my_ip_address__last_old_value;
    acceptor2_ingress_my_ip_address__wrote_any__dbg := acceptor2_ingress_my_ip_address__wrote_any;
    acceptor2_ingress_my_ip_address__wrote_index0__dbg := acceptor2_ingress_my_ip_address__wrote_index0;
    acceptor2_ingress_my_ip_address__last0_old_value__dbg := acceptor2_ingress_my_ip_address__last0_old_value;
    acceptor2_ingress_my_ip_address__last0_value__dbg := acceptor2_ingress_my_ip_address__last0_value;
    acceptor2_ingress_my_mac_address__dbg0 := acceptor2_ingress_my_mac_address[0bv32];
    acceptor2_ingress_my_mac_address__last_index__dbg := acceptor2_ingress_my_mac_address__last_index;
    acceptor2_ingress_my_mac_address__last_value__dbg := acceptor2_ingress_my_mac_address__last_value;
    acceptor2_ingress_my_mac_address__last_old_value__dbg := acceptor2_ingress_my_mac_address__last_old_value;
    acceptor2_ingress_my_mac_address__wrote_any__dbg := acceptor2_ingress_my_mac_address__wrote_any;
    acceptor2_ingress_my_mac_address__wrote_index0__dbg := acceptor2_ingress_my_mac_address__wrote_index0;
    acceptor2_ingress_my_mac_address__last0_old_value__dbg := acceptor2_ingress_my_mac_address__last0_old_value;
    acceptor2_ingress_my_mac_address__last0_value__dbg := acceptor2_ingress_my_mac_address__last0_value;
    acceptor2_ingress_registerAcceptorID__dbg0 := acceptor2_ingress_registerAcceptorID[0bv32];
    acceptor2_ingress_registerAcceptorID__last_index__dbg := acceptor2_ingress_registerAcceptorID__last_index;
    acceptor2_ingress_registerAcceptorID__last_value__dbg := acceptor2_ingress_registerAcceptorID__last_value;
    acceptor2_ingress_registerAcceptorID__last_old_value__dbg := acceptor2_ingress_registerAcceptorID__last_old_value;
    acceptor2_ingress_registerAcceptorID__wrote_any__dbg := acceptor2_ingress_registerAcceptorID__wrote_any;
    acceptor2_ingress_registerAcceptorID__wrote_index0__dbg := acceptor2_ingress_registerAcceptorID__wrote_index0;
    acceptor2_ingress_registerAcceptorID__last0_old_value__dbg := acceptor2_ingress_registerAcceptorID__last0_old_value;
    acceptor2_ingress_registerAcceptorID__last0_value__dbg := acceptor2_ingress_registerAcceptorID__last0_value;
    acceptor2_ingress_registerRound__dbg0 := acceptor2_ingress_registerRound[0bv32];
    acceptor2_ingress_registerRound__last_index__dbg := acceptor2_ingress_registerRound__last_index;
    acceptor2_ingress_registerRound__last_value__dbg := acceptor2_ingress_registerRound__last_value;
    acceptor2_ingress_registerRound__last_old_value__dbg := acceptor2_ingress_registerRound__last_old_value;
    acceptor2_ingress_registerRound__wrote_any__dbg := acceptor2_ingress_registerRound__wrote_any;
    acceptor2_ingress_registerRound__wrote_index0__dbg := acceptor2_ingress_registerRound__wrote_index0;
    acceptor2_ingress_registerRound__last0_old_value__dbg := acceptor2_ingress_registerRound__last0_old_value;
    acceptor2_ingress_registerRound__last0_value__dbg := acceptor2_ingress_registerRound__last0_value;
    acceptor2_ingress_registerVRound__dbg0 := acceptor2_ingress_registerVRound[0bv32];
    acceptor2_ingress_registerVRound__last_index__dbg := acceptor2_ingress_registerVRound__last_index;
    acceptor2_ingress_registerVRound__last_value__dbg := acceptor2_ingress_registerVRound__last_value;
    acceptor2_ingress_registerVRound__last_old_value__dbg := acceptor2_ingress_registerVRound__last_old_value;
    acceptor2_ingress_registerVRound__wrote_any__dbg := acceptor2_ingress_registerVRound__wrote_any;
    acceptor2_ingress_registerVRound__wrote_index0__dbg := acceptor2_ingress_registerVRound__wrote_index0;
    acceptor2_ingress_registerVRound__last0_old_value__dbg := acceptor2_ingress_registerVRound__last0_old_value;
    acceptor2_ingress_registerVRound__last0_value__dbg := acceptor2_ingress_registerVRound__last0_value;
    acceptor2_ingress_registerValue__dbg0 := acceptor2_ingress_registerValue[0bv32];
    acceptor2_ingress_registerValue__last_index__dbg := acceptor2_ingress_registerValue__last_index;
    acceptor2_ingress_registerValue__last_value__dbg := acceptor2_ingress_registerValue__last_value;
    acceptor2_ingress_registerValue__last_old_value__dbg := acceptor2_ingress_registerValue__last_old_value;
    acceptor2_ingress_registerValue__wrote_any__dbg := acceptor2_ingress_registerValue__wrote_any;
    acceptor2_ingress_registerValue__wrote_index0__dbg := acceptor2_ingress_registerValue__wrote_index0;
    acceptor2_ingress_registerValue__last0_old_value__dbg := acceptor2_ingress_registerValue__last0_old_value;
    acceptor2_ingress_registerValue__last0_value__dbg := acceptor2_ingress_registerValue__last0_value;
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
    // Global assertions
    assert (bvule.bv32$builtin(acceptor0_hdr.paxos.inst, 300bv32) && (acceptor0_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor1_hdr.paxos.inst, 300bv32) && (acceptor1_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor2_hdr.paxos.inst, 300bv32) && (acceptor2_hdr.paxos.inst != 300bv32));
  } else if (*) {
    // node pass -> learner
    assume learner_inbox_count > 0;
    learner_inbox_count := learner_inbox_count - 1;
    call learner_mainProcedure();
    if (learner_p4b_clone_i2e) {
      assume learner_inbox_count < 3;
      learner_pkt_external := false;
      learner_inbox_count := learner_inbox_count + 1;
    }
    learner_p4b_clone_i2e := false;
    if (learner_p4b_clone_e2e) {
      assume learner_inbox_count < 3;
      learner_pkt_external := false;
      learner_inbox_count := learner_inbox_count + 1;
    }
    learner_p4b_clone_e2e := false;
    if (learner_p4b_clone_i2i) {
      assume learner_inbox_count < 3;
      learner_pkt_external := false;
      learner_inbox_count := learner_inbox_count + 1;
    }
    learner_p4b_clone_i2i := false;
    if (learner_p4b_recirculate) {
      assume learner_inbox_count < 3;
      learner_pkt_external := false;
      learner_inbox_count := learner_inbox_count + 1;
    }
    learner_p4b_recirculate := false;
    call learner_Forward();
    // Register debug snapshot
    leader_ingress_ctrlInstane__dbg0 := leader_ingress_ctrlInstane[0bv32];
    leader_ingress_ctrlInstane__last_index__dbg := leader_ingress_ctrlInstane__last_index;
    leader_ingress_ctrlInstane__last_value__dbg := leader_ingress_ctrlInstane__last_value;
    leader_ingress_ctrlInstane__last_old_value__dbg := leader_ingress_ctrlInstane__last_old_value;
    leader_ingress_ctrlInstane__wrote_any__dbg := leader_ingress_ctrlInstane__wrote_any;
    leader_ingress_ctrlInstane__wrote_index0__dbg := leader_ingress_ctrlInstane__wrote_index0;
    leader_ingress_ctrlInstane__last0_old_value__dbg := leader_ingress_ctrlInstane__last0_old_value;
    leader_ingress_ctrlInstane__last0_value__dbg := leader_ingress_ctrlInstane__last0_value;
    acceptor0_ingress_learner_address__dbg0 := acceptor0_ingress_learner_address[0bv32];
    acceptor0_ingress_learner_address__last_index__dbg := acceptor0_ingress_learner_address__last_index;
    acceptor0_ingress_learner_address__last_value__dbg := acceptor0_ingress_learner_address__last_value;
    acceptor0_ingress_learner_address__last_old_value__dbg := acceptor0_ingress_learner_address__last_old_value;
    acceptor0_ingress_learner_address__wrote_any__dbg := acceptor0_ingress_learner_address__wrote_any;
    acceptor0_ingress_learner_address__wrote_index0__dbg := acceptor0_ingress_learner_address__wrote_index0;
    acceptor0_ingress_learner_address__last0_old_value__dbg := acceptor0_ingress_learner_address__last0_old_value;
    acceptor0_ingress_learner_address__last0_value__dbg := acceptor0_ingress_learner_address__last0_value;
    acceptor0_ingress_learner_mac_address__dbg0 := acceptor0_ingress_learner_mac_address[0bv32];
    acceptor0_ingress_learner_mac_address__last_index__dbg := acceptor0_ingress_learner_mac_address__last_index;
    acceptor0_ingress_learner_mac_address__last_value__dbg := acceptor0_ingress_learner_mac_address__last_value;
    acceptor0_ingress_learner_mac_address__last_old_value__dbg := acceptor0_ingress_learner_mac_address__last_old_value;
    acceptor0_ingress_learner_mac_address__wrote_any__dbg := acceptor0_ingress_learner_mac_address__wrote_any;
    acceptor0_ingress_learner_mac_address__wrote_index0__dbg := acceptor0_ingress_learner_mac_address__wrote_index0;
    acceptor0_ingress_learner_mac_address__last0_old_value__dbg := acceptor0_ingress_learner_mac_address__last0_old_value;
    acceptor0_ingress_learner_mac_address__last0_value__dbg := acceptor0_ingress_learner_mac_address__last0_value;
    acceptor0_ingress_my_ip_address__dbg0 := acceptor0_ingress_my_ip_address[0bv32];
    acceptor0_ingress_my_ip_address__last_index__dbg := acceptor0_ingress_my_ip_address__last_index;
    acceptor0_ingress_my_ip_address__last_value__dbg := acceptor0_ingress_my_ip_address__last_value;
    acceptor0_ingress_my_ip_address__last_old_value__dbg := acceptor0_ingress_my_ip_address__last_old_value;
    acceptor0_ingress_my_ip_address__wrote_any__dbg := acceptor0_ingress_my_ip_address__wrote_any;
    acceptor0_ingress_my_ip_address__wrote_index0__dbg := acceptor0_ingress_my_ip_address__wrote_index0;
    acceptor0_ingress_my_ip_address__last0_old_value__dbg := acceptor0_ingress_my_ip_address__last0_old_value;
    acceptor0_ingress_my_ip_address__last0_value__dbg := acceptor0_ingress_my_ip_address__last0_value;
    acceptor0_ingress_my_mac_address__dbg0 := acceptor0_ingress_my_mac_address[0bv32];
    acceptor0_ingress_my_mac_address__last_index__dbg := acceptor0_ingress_my_mac_address__last_index;
    acceptor0_ingress_my_mac_address__last_value__dbg := acceptor0_ingress_my_mac_address__last_value;
    acceptor0_ingress_my_mac_address__last_old_value__dbg := acceptor0_ingress_my_mac_address__last_old_value;
    acceptor0_ingress_my_mac_address__wrote_any__dbg := acceptor0_ingress_my_mac_address__wrote_any;
    acceptor0_ingress_my_mac_address__wrote_index0__dbg := acceptor0_ingress_my_mac_address__wrote_index0;
    acceptor0_ingress_my_mac_address__last0_old_value__dbg := acceptor0_ingress_my_mac_address__last0_old_value;
    acceptor0_ingress_my_mac_address__last0_value__dbg := acceptor0_ingress_my_mac_address__last0_value;
    acceptor0_ingress_registerAcceptorID__dbg0 := acceptor0_ingress_registerAcceptorID[0bv32];
    acceptor0_ingress_registerAcceptorID__last_index__dbg := acceptor0_ingress_registerAcceptorID__last_index;
    acceptor0_ingress_registerAcceptorID__last_value__dbg := acceptor0_ingress_registerAcceptorID__last_value;
    acceptor0_ingress_registerAcceptorID__last_old_value__dbg := acceptor0_ingress_registerAcceptorID__last_old_value;
    acceptor0_ingress_registerAcceptorID__wrote_any__dbg := acceptor0_ingress_registerAcceptorID__wrote_any;
    acceptor0_ingress_registerAcceptorID__wrote_index0__dbg := acceptor0_ingress_registerAcceptorID__wrote_index0;
    acceptor0_ingress_registerAcceptorID__last0_old_value__dbg := acceptor0_ingress_registerAcceptorID__last0_old_value;
    acceptor0_ingress_registerAcceptorID__last0_value__dbg := acceptor0_ingress_registerAcceptorID__last0_value;
    acceptor0_ingress_registerRound__dbg0 := acceptor0_ingress_registerRound[0bv32];
    acceptor0_ingress_registerRound__last_index__dbg := acceptor0_ingress_registerRound__last_index;
    acceptor0_ingress_registerRound__last_value__dbg := acceptor0_ingress_registerRound__last_value;
    acceptor0_ingress_registerRound__last_old_value__dbg := acceptor0_ingress_registerRound__last_old_value;
    acceptor0_ingress_registerRound__wrote_any__dbg := acceptor0_ingress_registerRound__wrote_any;
    acceptor0_ingress_registerRound__wrote_index0__dbg := acceptor0_ingress_registerRound__wrote_index0;
    acceptor0_ingress_registerRound__last0_old_value__dbg := acceptor0_ingress_registerRound__last0_old_value;
    acceptor0_ingress_registerRound__last0_value__dbg := acceptor0_ingress_registerRound__last0_value;
    acceptor0_ingress_registerVRound__dbg0 := acceptor0_ingress_registerVRound[0bv32];
    acceptor0_ingress_registerVRound__last_index__dbg := acceptor0_ingress_registerVRound__last_index;
    acceptor0_ingress_registerVRound__last_value__dbg := acceptor0_ingress_registerVRound__last_value;
    acceptor0_ingress_registerVRound__last_old_value__dbg := acceptor0_ingress_registerVRound__last_old_value;
    acceptor0_ingress_registerVRound__wrote_any__dbg := acceptor0_ingress_registerVRound__wrote_any;
    acceptor0_ingress_registerVRound__wrote_index0__dbg := acceptor0_ingress_registerVRound__wrote_index0;
    acceptor0_ingress_registerVRound__last0_old_value__dbg := acceptor0_ingress_registerVRound__last0_old_value;
    acceptor0_ingress_registerVRound__last0_value__dbg := acceptor0_ingress_registerVRound__last0_value;
    acceptor0_ingress_registerValue__dbg0 := acceptor0_ingress_registerValue[0bv32];
    acceptor0_ingress_registerValue__last_index__dbg := acceptor0_ingress_registerValue__last_index;
    acceptor0_ingress_registerValue__last_value__dbg := acceptor0_ingress_registerValue__last_value;
    acceptor0_ingress_registerValue__last_old_value__dbg := acceptor0_ingress_registerValue__last_old_value;
    acceptor0_ingress_registerValue__wrote_any__dbg := acceptor0_ingress_registerValue__wrote_any;
    acceptor0_ingress_registerValue__wrote_index0__dbg := acceptor0_ingress_registerValue__wrote_index0;
    acceptor0_ingress_registerValue__last0_old_value__dbg := acceptor0_ingress_registerValue__last0_old_value;
    acceptor0_ingress_registerValue__last0_value__dbg := acceptor0_ingress_registerValue__last0_value;
    acceptor1_ingress_learner_address__dbg0 := acceptor1_ingress_learner_address[0bv32];
    acceptor1_ingress_learner_address__last_index__dbg := acceptor1_ingress_learner_address__last_index;
    acceptor1_ingress_learner_address__last_value__dbg := acceptor1_ingress_learner_address__last_value;
    acceptor1_ingress_learner_address__last_old_value__dbg := acceptor1_ingress_learner_address__last_old_value;
    acceptor1_ingress_learner_address__wrote_any__dbg := acceptor1_ingress_learner_address__wrote_any;
    acceptor1_ingress_learner_address__wrote_index0__dbg := acceptor1_ingress_learner_address__wrote_index0;
    acceptor1_ingress_learner_address__last0_old_value__dbg := acceptor1_ingress_learner_address__last0_old_value;
    acceptor1_ingress_learner_address__last0_value__dbg := acceptor1_ingress_learner_address__last0_value;
    acceptor1_ingress_learner_mac_address__dbg0 := acceptor1_ingress_learner_mac_address[0bv32];
    acceptor1_ingress_learner_mac_address__last_index__dbg := acceptor1_ingress_learner_mac_address__last_index;
    acceptor1_ingress_learner_mac_address__last_value__dbg := acceptor1_ingress_learner_mac_address__last_value;
    acceptor1_ingress_learner_mac_address__last_old_value__dbg := acceptor1_ingress_learner_mac_address__last_old_value;
    acceptor1_ingress_learner_mac_address__wrote_any__dbg := acceptor1_ingress_learner_mac_address__wrote_any;
    acceptor1_ingress_learner_mac_address__wrote_index0__dbg := acceptor1_ingress_learner_mac_address__wrote_index0;
    acceptor1_ingress_learner_mac_address__last0_old_value__dbg := acceptor1_ingress_learner_mac_address__last0_old_value;
    acceptor1_ingress_learner_mac_address__last0_value__dbg := acceptor1_ingress_learner_mac_address__last0_value;
    acceptor1_ingress_my_ip_address__dbg0 := acceptor1_ingress_my_ip_address[0bv32];
    acceptor1_ingress_my_ip_address__last_index__dbg := acceptor1_ingress_my_ip_address__last_index;
    acceptor1_ingress_my_ip_address__last_value__dbg := acceptor1_ingress_my_ip_address__last_value;
    acceptor1_ingress_my_ip_address__last_old_value__dbg := acceptor1_ingress_my_ip_address__last_old_value;
    acceptor1_ingress_my_ip_address__wrote_any__dbg := acceptor1_ingress_my_ip_address__wrote_any;
    acceptor1_ingress_my_ip_address__wrote_index0__dbg := acceptor1_ingress_my_ip_address__wrote_index0;
    acceptor1_ingress_my_ip_address__last0_old_value__dbg := acceptor1_ingress_my_ip_address__last0_old_value;
    acceptor1_ingress_my_ip_address__last0_value__dbg := acceptor1_ingress_my_ip_address__last0_value;
    acceptor1_ingress_my_mac_address__dbg0 := acceptor1_ingress_my_mac_address[0bv32];
    acceptor1_ingress_my_mac_address__last_index__dbg := acceptor1_ingress_my_mac_address__last_index;
    acceptor1_ingress_my_mac_address__last_value__dbg := acceptor1_ingress_my_mac_address__last_value;
    acceptor1_ingress_my_mac_address__last_old_value__dbg := acceptor1_ingress_my_mac_address__last_old_value;
    acceptor1_ingress_my_mac_address__wrote_any__dbg := acceptor1_ingress_my_mac_address__wrote_any;
    acceptor1_ingress_my_mac_address__wrote_index0__dbg := acceptor1_ingress_my_mac_address__wrote_index0;
    acceptor1_ingress_my_mac_address__last0_old_value__dbg := acceptor1_ingress_my_mac_address__last0_old_value;
    acceptor1_ingress_my_mac_address__last0_value__dbg := acceptor1_ingress_my_mac_address__last0_value;
    acceptor1_ingress_registerAcceptorID__dbg0 := acceptor1_ingress_registerAcceptorID[0bv32];
    acceptor1_ingress_registerAcceptorID__last_index__dbg := acceptor1_ingress_registerAcceptorID__last_index;
    acceptor1_ingress_registerAcceptorID__last_value__dbg := acceptor1_ingress_registerAcceptorID__last_value;
    acceptor1_ingress_registerAcceptorID__last_old_value__dbg := acceptor1_ingress_registerAcceptorID__last_old_value;
    acceptor1_ingress_registerAcceptorID__wrote_any__dbg := acceptor1_ingress_registerAcceptorID__wrote_any;
    acceptor1_ingress_registerAcceptorID__wrote_index0__dbg := acceptor1_ingress_registerAcceptorID__wrote_index0;
    acceptor1_ingress_registerAcceptorID__last0_old_value__dbg := acceptor1_ingress_registerAcceptorID__last0_old_value;
    acceptor1_ingress_registerAcceptorID__last0_value__dbg := acceptor1_ingress_registerAcceptorID__last0_value;
    acceptor1_ingress_registerRound__dbg0 := acceptor1_ingress_registerRound[0bv32];
    acceptor1_ingress_registerRound__last_index__dbg := acceptor1_ingress_registerRound__last_index;
    acceptor1_ingress_registerRound__last_value__dbg := acceptor1_ingress_registerRound__last_value;
    acceptor1_ingress_registerRound__last_old_value__dbg := acceptor1_ingress_registerRound__last_old_value;
    acceptor1_ingress_registerRound__wrote_any__dbg := acceptor1_ingress_registerRound__wrote_any;
    acceptor1_ingress_registerRound__wrote_index0__dbg := acceptor1_ingress_registerRound__wrote_index0;
    acceptor1_ingress_registerRound__last0_old_value__dbg := acceptor1_ingress_registerRound__last0_old_value;
    acceptor1_ingress_registerRound__last0_value__dbg := acceptor1_ingress_registerRound__last0_value;
    acceptor1_ingress_registerVRound__dbg0 := acceptor1_ingress_registerVRound[0bv32];
    acceptor1_ingress_registerVRound__last_index__dbg := acceptor1_ingress_registerVRound__last_index;
    acceptor1_ingress_registerVRound__last_value__dbg := acceptor1_ingress_registerVRound__last_value;
    acceptor1_ingress_registerVRound__last_old_value__dbg := acceptor1_ingress_registerVRound__last_old_value;
    acceptor1_ingress_registerVRound__wrote_any__dbg := acceptor1_ingress_registerVRound__wrote_any;
    acceptor1_ingress_registerVRound__wrote_index0__dbg := acceptor1_ingress_registerVRound__wrote_index0;
    acceptor1_ingress_registerVRound__last0_old_value__dbg := acceptor1_ingress_registerVRound__last0_old_value;
    acceptor1_ingress_registerVRound__last0_value__dbg := acceptor1_ingress_registerVRound__last0_value;
    acceptor1_ingress_registerValue__dbg0 := acceptor1_ingress_registerValue[0bv32];
    acceptor1_ingress_registerValue__last_index__dbg := acceptor1_ingress_registerValue__last_index;
    acceptor1_ingress_registerValue__last_value__dbg := acceptor1_ingress_registerValue__last_value;
    acceptor1_ingress_registerValue__last_old_value__dbg := acceptor1_ingress_registerValue__last_old_value;
    acceptor1_ingress_registerValue__wrote_any__dbg := acceptor1_ingress_registerValue__wrote_any;
    acceptor1_ingress_registerValue__wrote_index0__dbg := acceptor1_ingress_registerValue__wrote_index0;
    acceptor1_ingress_registerValue__last0_old_value__dbg := acceptor1_ingress_registerValue__last0_old_value;
    acceptor1_ingress_registerValue__last0_value__dbg := acceptor1_ingress_registerValue__last0_value;
    acceptor2_ingress_learner_address__dbg0 := acceptor2_ingress_learner_address[0bv32];
    acceptor2_ingress_learner_address__last_index__dbg := acceptor2_ingress_learner_address__last_index;
    acceptor2_ingress_learner_address__last_value__dbg := acceptor2_ingress_learner_address__last_value;
    acceptor2_ingress_learner_address__last_old_value__dbg := acceptor2_ingress_learner_address__last_old_value;
    acceptor2_ingress_learner_address__wrote_any__dbg := acceptor2_ingress_learner_address__wrote_any;
    acceptor2_ingress_learner_address__wrote_index0__dbg := acceptor2_ingress_learner_address__wrote_index0;
    acceptor2_ingress_learner_address__last0_old_value__dbg := acceptor2_ingress_learner_address__last0_old_value;
    acceptor2_ingress_learner_address__last0_value__dbg := acceptor2_ingress_learner_address__last0_value;
    acceptor2_ingress_learner_mac_address__dbg0 := acceptor2_ingress_learner_mac_address[0bv32];
    acceptor2_ingress_learner_mac_address__last_index__dbg := acceptor2_ingress_learner_mac_address__last_index;
    acceptor2_ingress_learner_mac_address__last_value__dbg := acceptor2_ingress_learner_mac_address__last_value;
    acceptor2_ingress_learner_mac_address__last_old_value__dbg := acceptor2_ingress_learner_mac_address__last_old_value;
    acceptor2_ingress_learner_mac_address__wrote_any__dbg := acceptor2_ingress_learner_mac_address__wrote_any;
    acceptor2_ingress_learner_mac_address__wrote_index0__dbg := acceptor2_ingress_learner_mac_address__wrote_index0;
    acceptor2_ingress_learner_mac_address__last0_old_value__dbg := acceptor2_ingress_learner_mac_address__last0_old_value;
    acceptor2_ingress_learner_mac_address__last0_value__dbg := acceptor2_ingress_learner_mac_address__last0_value;
    acceptor2_ingress_my_ip_address__dbg0 := acceptor2_ingress_my_ip_address[0bv32];
    acceptor2_ingress_my_ip_address__last_index__dbg := acceptor2_ingress_my_ip_address__last_index;
    acceptor2_ingress_my_ip_address__last_value__dbg := acceptor2_ingress_my_ip_address__last_value;
    acceptor2_ingress_my_ip_address__last_old_value__dbg := acceptor2_ingress_my_ip_address__last_old_value;
    acceptor2_ingress_my_ip_address__wrote_any__dbg := acceptor2_ingress_my_ip_address__wrote_any;
    acceptor2_ingress_my_ip_address__wrote_index0__dbg := acceptor2_ingress_my_ip_address__wrote_index0;
    acceptor2_ingress_my_ip_address__last0_old_value__dbg := acceptor2_ingress_my_ip_address__last0_old_value;
    acceptor2_ingress_my_ip_address__last0_value__dbg := acceptor2_ingress_my_ip_address__last0_value;
    acceptor2_ingress_my_mac_address__dbg0 := acceptor2_ingress_my_mac_address[0bv32];
    acceptor2_ingress_my_mac_address__last_index__dbg := acceptor2_ingress_my_mac_address__last_index;
    acceptor2_ingress_my_mac_address__last_value__dbg := acceptor2_ingress_my_mac_address__last_value;
    acceptor2_ingress_my_mac_address__last_old_value__dbg := acceptor2_ingress_my_mac_address__last_old_value;
    acceptor2_ingress_my_mac_address__wrote_any__dbg := acceptor2_ingress_my_mac_address__wrote_any;
    acceptor2_ingress_my_mac_address__wrote_index0__dbg := acceptor2_ingress_my_mac_address__wrote_index0;
    acceptor2_ingress_my_mac_address__last0_old_value__dbg := acceptor2_ingress_my_mac_address__last0_old_value;
    acceptor2_ingress_my_mac_address__last0_value__dbg := acceptor2_ingress_my_mac_address__last0_value;
    acceptor2_ingress_registerAcceptorID__dbg0 := acceptor2_ingress_registerAcceptorID[0bv32];
    acceptor2_ingress_registerAcceptorID__last_index__dbg := acceptor2_ingress_registerAcceptorID__last_index;
    acceptor2_ingress_registerAcceptorID__last_value__dbg := acceptor2_ingress_registerAcceptorID__last_value;
    acceptor2_ingress_registerAcceptorID__last_old_value__dbg := acceptor2_ingress_registerAcceptorID__last_old_value;
    acceptor2_ingress_registerAcceptorID__wrote_any__dbg := acceptor2_ingress_registerAcceptorID__wrote_any;
    acceptor2_ingress_registerAcceptorID__wrote_index0__dbg := acceptor2_ingress_registerAcceptorID__wrote_index0;
    acceptor2_ingress_registerAcceptorID__last0_old_value__dbg := acceptor2_ingress_registerAcceptorID__last0_old_value;
    acceptor2_ingress_registerAcceptorID__last0_value__dbg := acceptor2_ingress_registerAcceptorID__last0_value;
    acceptor2_ingress_registerRound__dbg0 := acceptor2_ingress_registerRound[0bv32];
    acceptor2_ingress_registerRound__last_index__dbg := acceptor2_ingress_registerRound__last_index;
    acceptor2_ingress_registerRound__last_value__dbg := acceptor2_ingress_registerRound__last_value;
    acceptor2_ingress_registerRound__last_old_value__dbg := acceptor2_ingress_registerRound__last_old_value;
    acceptor2_ingress_registerRound__wrote_any__dbg := acceptor2_ingress_registerRound__wrote_any;
    acceptor2_ingress_registerRound__wrote_index0__dbg := acceptor2_ingress_registerRound__wrote_index0;
    acceptor2_ingress_registerRound__last0_old_value__dbg := acceptor2_ingress_registerRound__last0_old_value;
    acceptor2_ingress_registerRound__last0_value__dbg := acceptor2_ingress_registerRound__last0_value;
    acceptor2_ingress_registerVRound__dbg0 := acceptor2_ingress_registerVRound[0bv32];
    acceptor2_ingress_registerVRound__last_index__dbg := acceptor2_ingress_registerVRound__last_index;
    acceptor2_ingress_registerVRound__last_value__dbg := acceptor2_ingress_registerVRound__last_value;
    acceptor2_ingress_registerVRound__last_old_value__dbg := acceptor2_ingress_registerVRound__last_old_value;
    acceptor2_ingress_registerVRound__wrote_any__dbg := acceptor2_ingress_registerVRound__wrote_any;
    acceptor2_ingress_registerVRound__wrote_index0__dbg := acceptor2_ingress_registerVRound__wrote_index0;
    acceptor2_ingress_registerVRound__last0_old_value__dbg := acceptor2_ingress_registerVRound__last0_old_value;
    acceptor2_ingress_registerVRound__last0_value__dbg := acceptor2_ingress_registerVRound__last0_value;
    acceptor2_ingress_registerValue__dbg0 := acceptor2_ingress_registerValue[0bv32];
    acceptor2_ingress_registerValue__last_index__dbg := acceptor2_ingress_registerValue__last_index;
    acceptor2_ingress_registerValue__last_value__dbg := acceptor2_ingress_registerValue__last_value;
    acceptor2_ingress_registerValue__last_old_value__dbg := acceptor2_ingress_registerValue__last_old_value;
    acceptor2_ingress_registerValue__wrote_any__dbg := acceptor2_ingress_registerValue__wrote_any;
    acceptor2_ingress_registerValue__wrote_index0__dbg := acceptor2_ingress_registerValue__wrote_index0;
    acceptor2_ingress_registerValue__last0_old_value__dbg := acceptor2_ingress_registerValue__last0_old_value;
    acceptor2_ingress_registerValue__last0_value__dbg := acceptor2_ingress_registerValue__last0_value;
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
    // Global assertions
    assert (bvule.bv32$builtin(acceptor0_hdr.paxos.inst, 300bv32) && (acceptor0_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor1_hdr.paxos.inst, 300bv32) && (acceptor1_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor2_hdr.paxos.inst, 300bv32) && (acceptor2_hdr.paxos.inst != 300bv32));
  } else {
    // idle
  }
}

procedure mainProcedure() returns()
  modifies acceptor0_drop, acceptor0_egress_place_holder_table.hit, acceptor0_forward, acceptor0_hdr.arp.hln, acceptor0_hdr.arp.hrd, acceptor0_hdr.arp.op, acceptor0_hdr.arp.pln, acceptor0_hdr.arp.pro, acceptor0_hdr.arp.sha, acceptor0_hdr.arp.spa, acceptor0_hdr.arp.tha, acceptor0_hdr.arp.tpa, acceptor0_hdr.arp.valid, acceptor0_hdr.ethernet.dstAddr, acceptor0_hdr.ethernet.etherType, acceptor0_hdr.ethernet.srcAddr, acceptor0_hdr.ethernet.valid, acceptor0_hdr.icmp.hdrChecksum, acceptor0_hdr.icmp.icmpCode, acceptor0_hdr.icmp.icmpType, acceptor0_hdr.icmp.identifier, acceptor0_hdr.icmp.payload, acceptor0_hdr.icmp.seqNumber, acceptor0_hdr.icmp.valid, acceptor0_hdr.ipv4.diffserv, acceptor0_hdr.ipv4.dstAddr, acceptor0_hdr.ipv4.flags, acceptor0_hdr.ipv4.fragOffset, acceptor0_hdr.ipv4.hdrChecksum, acceptor0_hdr.ipv4.identification, acceptor0_hdr.ipv4.ihl, acceptor0_hdr.ipv4.protocol, acceptor0_hdr.ipv4.srcAddr, acceptor0_hdr.ipv4.totalLen, acceptor0_hdr.ipv4.ttl, acceptor0_hdr.ipv4.valid, acceptor0_hdr.ipv4.version, acceptor0_hdr.paxos.acptid, acceptor0_hdr.paxos.inst, acceptor0_hdr.paxos.msgtype, acceptor0_hdr.paxos.paxoslen, acceptor0_hdr.paxos.paxosval, acceptor0_hdr.paxos.rnd, acceptor0_hdr.paxos.valid, acceptor0_hdr.paxos.vrnd, acceptor0_hdr.udp.checksum, acceptor0_hdr.udp.dstPort, acceptor0_hdr.udp.length_, acceptor0_hdr.udp.srcPort, acceptor0_hdr.udp.valid, acceptor0_inbox_count, acceptor0_ingress_acceptor_tbl.action_run, acceptor0_ingress_acceptor_tbl.hit, acceptor0_ingress_arp_tbl.action_run, acceptor0_ingress_arp_tbl.hit, acceptor0_ingress_icmp_tbl.action_run, acceptor0_ingress_icmp_tbl.hit, acceptor0_ingress_learner_address__dbg0, acceptor0_ingress_learner_address__last0_old_value, acceptor0_ingress_learner_address__last0_old_value__dbg, acceptor0_ingress_learner_address__last0_value, acceptor0_ingress_learner_address__last0_value__dbg, acceptor0_ingress_learner_address__last_index, acceptor0_ingress_learner_address__last_index__dbg, acceptor0_ingress_learner_address__last_old_value, acceptor0_ingress_learner_address__last_old_value__dbg, acceptor0_ingress_learner_address__last_value, acceptor0_ingress_learner_address__last_value__dbg, acceptor0_ingress_learner_address__last_write_site, acceptor0_ingress_learner_address__next_write_site, acceptor0_ingress_learner_address__wrote_any, acceptor0_ingress_learner_address__wrote_any__dbg, acceptor0_ingress_learner_address__wrote_index0, acceptor0_ingress_learner_address__wrote_index0__dbg, acceptor0_ingress_learner_mac_address__dbg0, acceptor0_ingress_learner_mac_address__last0_old_value, acceptor0_ingress_learner_mac_address__last0_old_value__dbg, acceptor0_ingress_learner_mac_address__last0_value, acceptor0_ingress_learner_mac_address__last0_value__dbg, acceptor0_ingress_learner_mac_address__last_index, acceptor0_ingress_learner_mac_address__last_index__dbg, acceptor0_ingress_learner_mac_address__last_old_value, acceptor0_ingress_learner_mac_address__last_old_value__dbg, acceptor0_ingress_learner_mac_address__last_value, acceptor0_ingress_learner_mac_address__last_value__dbg, acceptor0_ingress_learner_mac_address__last_write_site, acceptor0_ingress_learner_mac_address__next_write_site, acceptor0_ingress_learner_mac_address__wrote_any, acceptor0_ingress_learner_mac_address__wrote_any__dbg, acceptor0_ingress_learner_mac_address__wrote_index0, acceptor0_ingress_learner_mac_address__wrote_index0__dbg, acceptor0_ingress_my_ip_address__dbg0, acceptor0_ingress_my_ip_address__last0_old_value, acceptor0_ingress_my_ip_address__last0_old_value__dbg, acceptor0_ingress_my_ip_address__last0_value, acceptor0_ingress_my_ip_address__last0_value__dbg, acceptor0_ingress_my_ip_address__last_index, acceptor0_ingress_my_ip_address__last_index__dbg, acceptor0_ingress_my_ip_address__last_old_value, acceptor0_ingress_my_ip_address__last_old_value__dbg, acceptor0_ingress_my_ip_address__last_value, acceptor0_ingress_my_ip_address__last_value__dbg, acceptor0_ingress_my_ip_address__last_write_site, acceptor0_ingress_my_ip_address__next_write_site, acceptor0_ingress_my_ip_address__wrote_any, acceptor0_ingress_my_ip_address__wrote_any__dbg, acceptor0_ingress_my_ip_address__wrote_index0, acceptor0_ingress_my_ip_address__wrote_index0__dbg, acceptor0_ingress_my_mac_address__dbg0, acceptor0_ingress_my_mac_address__last0_old_value, acceptor0_ingress_my_mac_address__last0_old_value__dbg, acceptor0_ingress_my_mac_address__last0_value, acceptor0_ingress_my_mac_address__last0_value__dbg, acceptor0_ingress_my_mac_address__last_index, acceptor0_ingress_my_mac_address__last_index__dbg, acceptor0_ingress_my_mac_address__last_old_value, acceptor0_ingress_my_mac_address__last_old_value__dbg, acceptor0_ingress_my_mac_address__last_value, acceptor0_ingress_my_mac_address__last_value__dbg, acceptor0_ingress_my_mac_address__last_write_site, acceptor0_ingress_my_mac_address__next_write_site, acceptor0_ingress_my_mac_address__wrote_any, acceptor0_ingress_my_mac_address__wrote_any__dbg, acceptor0_ingress_my_mac_address__wrote_index0, acceptor0_ingress_my_mac_address__wrote_index0__dbg, acceptor0_ingress_registerAcceptorID__dbg0, acceptor0_ingress_registerAcceptorID__last0_old_value, acceptor0_ingress_registerAcceptorID__last0_old_value__dbg, acceptor0_ingress_registerAcceptorID__last0_value, acceptor0_ingress_registerAcceptorID__last0_value__dbg, acceptor0_ingress_registerAcceptorID__last_index, acceptor0_ingress_registerAcceptorID__last_index__dbg, acceptor0_ingress_registerAcceptorID__last_old_value, acceptor0_ingress_registerAcceptorID__last_old_value__dbg, acceptor0_ingress_registerAcceptorID__last_value, acceptor0_ingress_registerAcceptorID__last_value__dbg, acceptor0_ingress_registerAcceptorID__last_write_site, acceptor0_ingress_registerAcceptorID__next_write_site, acceptor0_ingress_registerAcceptorID__wrote_any, acceptor0_ingress_registerAcceptorID__wrote_any__dbg, acceptor0_ingress_registerAcceptorID__wrote_index0, acceptor0_ingress_registerAcceptorID__wrote_index0__dbg, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__dbg0, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_old_value__dbg, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last0_value__dbg, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_index__dbg, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_old_value__dbg, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_value__dbg, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_any__dbg, acceptor0_ingress_registerRound__wrote_index0, acceptor0_ingress_registerRound__wrote_index0__dbg, acceptor0_ingress_registerVRound, acceptor0_ingress_registerVRound__dbg0, acceptor0_ingress_registerVRound__last0_old_value, acceptor0_ingress_registerVRound__last0_old_value__dbg, acceptor0_ingress_registerVRound__last0_value, acceptor0_ingress_registerVRound__last0_value__dbg, acceptor0_ingress_registerVRound__last_index, acceptor0_ingress_registerVRound__last_index__dbg, acceptor0_ingress_registerVRound__last_old_value, acceptor0_ingress_registerVRound__last_old_value__dbg, acceptor0_ingress_registerVRound__last_value, acceptor0_ingress_registerVRound__last_value__dbg, acceptor0_ingress_registerVRound__last_write_site, acceptor0_ingress_registerVRound__next_write_site, acceptor0_ingress_registerVRound__wrote_any, acceptor0_ingress_registerVRound__wrote_any__dbg, acceptor0_ingress_registerVRound__wrote_index0, acceptor0_ingress_registerVRound__wrote_index0__dbg, acceptor0_ingress_registerValue, acceptor0_ingress_registerValue__dbg0, acceptor0_ingress_registerValue__last0_old_value, acceptor0_ingress_registerValue__last0_old_value__dbg, acceptor0_ingress_registerValue__last0_value, acceptor0_ingress_registerValue__last0_value__dbg, acceptor0_ingress_registerValue__last_index, acceptor0_ingress_registerValue__last_index__dbg, acceptor0_ingress_registerValue__last_old_value, acceptor0_ingress_registerValue__last_old_value__dbg, acceptor0_ingress_registerValue__last_value, acceptor0_ingress_registerValue__last_value__dbg, acceptor0_ingress_registerValue__last_write_site, acceptor0_ingress_registerValue__next_write_site, acceptor0_ingress_registerValue__wrote_any, acceptor0_ingress_registerValue__wrote_any__dbg, acceptor0_ingress_registerValue__wrote_index0, acceptor0_ingress_registerValue__wrote_index0__dbg, acceptor0_ingress_transport_tbl.action_run, acceptor0_ingress_transport_tbl.hit, acceptor0_ipdst_0, acceptor0_isValid, acceptor0_meta.paxos_metadata, acceptor0_meta.paxos_metadata.ack_acceptors, acceptor0_meta.paxos_metadata.ack_count, acceptor0_meta.paxos_metadata.round, acceptor0_meta.paxos_metadata.set_drop, acceptor0_p4b_checksum_error, acceptor0_p4b_checksum_updated, acceptor0_p4b_checksum_verified, acceptor0_p4b_clone_e2e, acceptor0_p4b_clone_i2e, acceptor0_p4b_clone_i2i, acceptor0_p4b_digest, acceptor0_p4b_recirculate, acceptor0_pkt_external, acceptor0_standard_metadata.checksum_error, acceptor0_standard_metadata.deq_qdepth, acceptor0_standard_metadata.deq_timedelta, acceptor0_standard_metadata.egress_global_timestamp, acceptor0_standard_metadata.egress_port, acceptor0_standard_metadata.egress_rid, acceptor0_standard_metadata.egress_spec, acceptor0_standard_metadata.enq_qdepth, acceptor0_standard_metadata.enq_timestamp, acceptor0_standard_metadata.ingress_global_timestamp, acceptor0_standard_metadata.ingress_port, acceptor0_standard_metadata.instance_type, acceptor0_standard_metadata.mcast_grp, acceptor0_standard_metadata.packet_length, acceptor0_standard_metadata.parser_error, acceptor0_standard_metadata.priority, acceptor1_drop, acceptor1_egress_place_holder_table.hit, acceptor1_forward, acceptor1_hdr.arp.hln, acceptor1_hdr.arp.hrd, acceptor1_hdr.arp.op, acceptor1_hdr.arp.pln, acceptor1_hdr.arp.pro, acceptor1_hdr.arp.sha, acceptor1_hdr.arp.spa, acceptor1_hdr.arp.tha, acceptor1_hdr.arp.tpa, acceptor1_hdr.arp.valid, acceptor1_hdr.ethernet.dstAddr, acceptor1_hdr.ethernet.etherType, acceptor1_hdr.ethernet.srcAddr, acceptor1_hdr.ethernet.valid, acceptor1_hdr.icmp.hdrChecksum, acceptor1_hdr.icmp.icmpCode, acceptor1_hdr.icmp.icmpType, acceptor1_hdr.icmp.identifier, acceptor1_hdr.icmp.payload, acceptor1_hdr.icmp.seqNumber, acceptor1_hdr.icmp.valid, acceptor1_hdr.ipv4.diffserv, acceptor1_hdr.ipv4.dstAddr, acceptor1_hdr.ipv4.flags, acceptor1_hdr.ipv4.fragOffset, acceptor1_hdr.ipv4.hdrChecksum, acceptor1_hdr.ipv4.identification, acceptor1_hdr.ipv4.ihl, acceptor1_hdr.ipv4.protocol, acceptor1_hdr.ipv4.srcAddr, acceptor1_hdr.ipv4.totalLen, acceptor1_hdr.ipv4.ttl, acceptor1_hdr.ipv4.valid, acceptor1_hdr.ipv4.version, acceptor1_hdr.paxos.acptid, acceptor1_hdr.paxos.inst, acceptor1_hdr.paxos.msgtype, acceptor1_hdr.paxos.paxoslen, acceptor1_hdr.paxos.paxosval, acceptor1_hdr.paxos.rnd, acceptor1_hdr.paxos.valid, acceptor1_hdr.paxos.vrnd, acceptor1_hdr.udp.checksum, acceptor1_hdr.udp.dstPort, acceptor1_hdr.udp.length_, acceptor1_hdr.udp.srcPort, acceptor1_hdr.udp.valid, acceptor1_inbox_count, acceptor1_ingress_acceptor_tbl.action_run, acceptor1_ingress_acceptor_tbl.hit, acceptor1_ingress_arp_tbl.action_run, acceptor1_ingress_arp_tbl.hit, acceptor1_ingress_icmp_tbl.action_run, acceptor1_ingress_icmp_tbl.hit, acceptor1_ingress_learner_address__dbg0, acceptor1_ingress_learner_address__last0_old_value, acceptor1_ingress_learner_address__last0_old_value__dbg, acceptor1_ingress_learner_address__last0_value, acceptor1_ingress_learner_address__last0_value__dbg, acceptor1_ingress_learner_address__last_index, acceptor1_ingress_learner_address__last_index__dbg, acceptor1_ingress_learner_address__last_old_value, acceptor1_ingress_learner_address__last_old_value__dbg, acceptor1_ingress_learner_address__last_value, acceptor1_ingress_learner_address__last_value__dbg, acceptor1_ingress_learner_address__last_write_site, acceptor1_ingress_learner_address__next_write_site, acceptor1_ingress_learner_address__wrote_any, acceptor1_ingress_learner_address__wrote_any__dbg, acceptor1_ingress_learner_address__wrote_index0, acceptor1_ingress_learner_address__wrote_index0__dbg, acceptor1_ingress_learner_mac_address__dbg0, acceptor1_ingress_learner_mac_address__last0_old_value, acceptor1_ingress_learner_mac_address__last0_old_value__dbg, acceptor1_ingress_learner_mac_address__last0_value, acceptor1_ingress_learner_mac_address__last0_value__dbg, acceptor1_ingress_learner_mac_address__last_index, acceptor1_ingress_learner_mac_address__last_index__dbg, acceptor1_ingress_learner_mac_address__last_old_value, acceptor1_ingress_learner_mac_address__last_old_value__dbg, acceptor1_ingress_learner_mac_address__last_value, acceptor1_ingress_learner_mac_address__last_value__dbg, acceptor1_ingress_learner_mac_address__last_write_site, acceptor1_ingress_learner_mac_address__next_write_site, acceptor1_ingress_learner_mac_address__wrote_any, acceptor1_ingress_learner_mac_address__wrote_any__dbg, acceptor1_ingress_learner_mac_address__wrote_index0, acceptor1_ingress_learner_mac_address__wrote_index0__dbg, acceptor1_ingress_my_ip_address__dbg0, acceptor1_ingress_my_ip_address__last0_old_value, acceptor1_ingress_my_ip_address__last0_old_value__dbg, acceptor1_ingress_my_ip_address__last0_value, acceptor1_ingress_my_ip_address__last0_value__dbg, acceptor1_ingress_my_ip_address__last_index, acceptor1_ingress_my_ip_address__last_index__dbg, acceptor1_ingress_my_ip_address__last_old_value, acceptor1_ingress_my_ip_address__last_old_value__dbg, acceptor1_ingress_my_ip_address__last_value, acceptor1_ingress_my_ip_address__last_value__dbg, acceptor1_ingress_my_ip_address__last_write_site, acceptor1_ingress_my_ip_address__next_write_site, acceptor1_ingress_my_ip_address__wrote_any, acceptor1_ingress_my_ip_address__wrote_any__dbg, acceptor1_ingress_my_ip_address__wrote_index0, acceptor1_ingress_my_ip_address__wrote_index0__dbg, acceptor1_ingress_my_mac_address__dbg0, acceptor1_ingress_my_mac_address__last0_old_value, acceptor1_ingress_my_mac_address__last0_old_value__dbg, acceptor1_ingress_my_mac_address__last0_value, acceptor1_ingress_my_mac_address__last0_value__dbg, acceptor1_ingress_my_mac_address__last_index, acceptor1_ingress_my_mac_address__last_index__dbg, acceptor1_ingress_my_mac_address__last_old_value, acceptor1_ingress_my_mac_address__last_old_value__dbg, acceptor1_ingress_my_mac_address__last_value, acceptor1_ingress_my_mac_address__last_value__dbg, acceptor1_ingress_my_mac_address__last_write_site, acceptor1_ingress_my_mac_address__next_write_site, acceptor1_ingress_my_mac_address__wrote_any, acceptor1_ingress_my_mac_address__wrote_any__dbg, acceptor1_ingress_my_mac_address__wrote_index0, acceptor1_ingress_my_mac_address__wrote_index0__dbg, acceptor1_ingress_registerAcceptorID__dbg0, acceptor1_ingress_registerAcceptorID__last0_old_value, acceptor1_ingress_registerAcceptorID__last0_old_value__dbg, acceptor1_ingress_registerAcceptorID__last0_value, acceptor1_ingress_registerAcceptorID__last0_value__dbg, acceptor1_ingress_registerAcceptorID__last_index, acceptor1_ingress_registerAcceptorID__last_index__dbg, acceptor1_ingress_registerAcceptorID__last_old_value, acceptor1_ingress_registerAcceptorID__last_old_value__dbg, acceptor1_ingress_registerAcceptorID__last_value, acceptor1_ingress_registerAcceptorID__last_value__dbg, acceptor1_ingress_registerAcceptorID__last_write_site, acceptor1_ingress_registerAcceptorID__next_write_site, acceptor1_ingress_registerAcceptorID__wrote_any, acceptor1_ingress_registerAcceptorID__wrote_any__dbg, acceptor1_ingress_registerAcceptorID__wrote_index0, acceptor1_ingress_registerAcceptorID__wrote_index0__dbg, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__dbg0, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_old_value__dbg, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last0_value__dbg, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_index__dbg, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_old_value__dbg, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_value__dbg, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_any__dbg, acceptor1_ingress_registerRound__wrote_index0, acceptor1_ingress_registerRound__wrote_index0__dbg, acceptor1_ingress_registerVRound, acceptor1_ingress_registerVRound__dbg0, acceptor1_ingress_registerVRound__last0_old_value, acceptor1_ingress_registerVRound__last0_old_value__dbg, acceptor1_ingress_registerVRound__last0_value, acceptor1_ingress_registerVRound__last0_value__dbg, acceptor1_ingress_registerVRound__last_index, acceptor1_ingress_registerVRound__last_index__dbg, acceptor1_ingress_registerVRound__last_old_value, acceptor1_ingress_registerVRound__last_old_value__dbg, acceptor1_ingress_registerVRound__last_value, acceptor1_ingress_registerVRound__last_value__dbg, acceptor1_ingress_registerVRound__last_write_site, acceptor1_ingress_registerVRound__next_write_site, acceptor1_ingress_registerVRound__wrote_any, acceptor1_ingress_registerVRound__wrote_any__dbg, acceptor1_ingress_registerVRound__wrote_index0, acceptor1_ingress_registerVRound__wrote_index0__dbg, acceptor1_ingress_registerValue, acceptor1_ingress_registerValue__dbg0, acceptor1_ingress_registerValue__last0_old_value, acceptor1_ingress_registerValue__last0_old_value__dbg, acceptor1_ingress_registerValue__last0_value, acceptor1_ingress_registerValue__last0_value__dbg, acceptor1_ingress_registerValue__last_index, acceptor1_ingress_registerValue__last_index__dbg, acceptor1_ingress_registerValue__last_old_value, acceptor1_ingress_registerValue__last_old_value__dbg, acceptor1_ingress_registerValue__last_value, acceptor1_ingress_registerValue__last_value__dbg, acceptor1_ingress_registerValue__last_write_site, acceptor1_ingress_registerValue__next_write_site, acceptor1_ingress_registerValue__wrote_any, acceptor1_ingress_registerValue__wrote_any__dbg, acceptor1_ingress_registerValue__wrote_index0, acceptor1_ingress_registerValue__wrote_index0__dbg, acceptor1_ingress_transport_tbl.action_run, acceptor1_ingress_transport_tbl.hit, acceptor1_ipdst_0, acceptor1_isValid, acceptor1_meta.paxos_metadata, acceptor1_meta.paxos_metadata.ack_acceptors, acceptor1_meta.paxos_metadata.ack_count, acceptor1_meta.paxos_metadata.round, acceptor1_meta.paxos_metadata.set_drop, acceptor1_p4b_checksum_error, acceptor1_p4b_checksum_updated, acceptor1_p4b_checksum_verified, acceptor1_p4b_clone_e2e, acceptor1_p4b_clone_i2e, acceptor1_p4b_clone_i2i, acceptor1_p4b_digest, acceptor1_p4b_recirculate, acceptor1_pkt_external, acceptor1_standard_metadata.checksum_error, acceptor1_standard_metadata.deq_qdepth, acceptor1_standard_metadata.deq_timedelta, acceptor1_standard_metadata.egress_global_timestamp, acceptor1_standard_metadata.egress_port, acceptor1_standard_metadata.egress_rid, acceptor1_standard_metadata.egress_spec, acceptor1_standard_metadata.enq_qdepth, acceptor1_standard_metadata.enq_timestamp, acceptor1_standard_metadata.ingress_global_timestamp, acceptor1_standard_metadata.ingress_port, acceptor1_standard_metadata.instance_type, acceptor1_standard_metadata.mcast_grp, acceptor1_standard_metadata.packet_length, acceptor1_standard_metadata.parser_error, acceptor1_standard_metadata.priority, acceptor2_drop, acceptor2_egress_place_holder_table.hit, acceptor2_forward, acceptor2_hdr.arp.hln, acceptor2_hdr.arp.hrd, acceptor2_hdr.arp.op, acceptor2_hdr.arp.pln, acceptor2_hdr.arp.pro, acceptor2_hdr.arp.sha, acceptor2_hdr.arp.spa, acceptor2_hdr.arp.tha, acceptor2_hdr.arp.tpa, acceptor2_hdr.arp.valid, acceptor2_hdr.ethernet.dstAddr, acceptor2_hdr.ethernet.etherType, acceptor2_hdr.ethernet.srcAddr, acceptor2_hdr.ethernet.valid, acceptor2_hdr.icmp.hdrChecksum, acceptor2_hdr.icmp.icmpCode, acceptor2_hdr.icmp.icmpType, acceptor2_hdr.icmp.identifier, acceptor2_hdr.icmp.payload, acceptor2_hdr.icmp.seqNumber, acceptor2_hdr.icmp.valid, acceptor2_hdr.ipv4.diffserv, acceptor2_hdr.ipv4.dstAddr, acceptor2_hdr.ipv4.flags, acceptor2_hdr.ipv4.fragOffset, acceptor2_hdr.ipv4.hdrChecksum, acceptor2_hdr.ipv4.identification, acceptor2_hdr.ipv4.ihl, acceptor2_hdr.ipv4.protocol, acceptor2_hdr.ipv4.srcAddr, acceptor2_hdr.ipv4.totalLen, acceptor2_hdr.ipv4.ttl, acceptor2_hdr.ipv4.valid, acceptor2_hdr.ipv4.version, acceptor2_hdr.paxos.acptid, acceptor2_hdr.paxos.inst, acceptor2_hdr.paxos.msgtype, acceptor2_hdr.paxos.paxoslen, acceptor2_hdr.paxos.paxosval, acceptor2_hdr.paxos.rnd, acceptor2_hdr.paxos.valid, acceptor2_hdr.paxos.vrnd, acceptor2_hdr.udp.checksum, acceptor2_hdr.udp.dstPort, acceptor2_hdr.udp.length_, acceptor2_hdr.udp.srcPort, acceptor2_hdr.udp.valid, acceptor2_inbox_count, acceptor2_ingress_acceptor_tbl.action_run, acceptor2_ingress_acceptor_tbl.hit, acceptor2_ingress_arp_tbl.action_run, acceptor2_ingress_arp_tbl.hit, acceptor2_ingress_icmp_tbl.action_run, acceptor2_ingress_icmp_tbl.hit, acceptor2_ingress_learner_address__dbg0, acceptor2_ingress_learner_address__last0_old_value, acceptor2_ingress_learner_address__last0_old_value__dbg, acceptor2_ingress_learner_address__last0_value, acceptor2_ingress_learner_address__last0_value__dbg, acceptor2_ingress_learner_address__last_index, acceptor2_ingress_learner_address__last_index__dbg, acceptor2_ingress_learner_address__last_old_value, acceptor2_ingress_learner_address__last_old_value__dbg, acceptor2_ingress_learner_address__last_value, acceptor2_ingress_learner_address__last_value__dbg, acceptor2_ingress_learner_address__last_write_site, acceptor2_ingress_learner_address__next_write_site, acceptor2_ingress_learner_address__wrote_any, acceptor2_ingress_learner_address__wrote_any__dbg, acceptor2_ingress_learner_address__wrote_index0, acceptor2_ingress_learner_address__wrote_index0__dbg, acceptor2_ingress_learner_mac_address__dbg0, acceptor2_ingress_learner_mac_address__last0_old_value, acceptor2_ingress_learner_mac_address__last0_old_value__dbg, acceptor2_ingress_learner_mac_address__last0_value, acceptor2_ingress_learner_mac_address__last0_value__dbg, acceptor2_ingress_learner_mac_address__last_index, acceptor2_ingress_learner_mac_address__last_index__dbg, acceptor2_ingress_learner_mac_address__last_old_value, acceptor2_ingress_learner_mac_address__last_old_value__dbg, acceptor2_ingress_learner_mac_address__last_value, acceptor2_ingress_learner_mac_address__last_value__dbg, acceptor2_ingress_learner_mac_address__last_write_site, acceptor2_ingress_learner_mac_address__next_write_site, acceptor2_ingress_learner_mac_address__wrote_any, acceptor2_ingress_learner_mac_address__wrote_any__dbg, acceptor2_ingress_learner_mac_address__wrote_index0, acceptor2_ingress_learner_mac_address__wrote_index0__dbg, acceptor2_ingress_my_ip_address__dbg0, acceptor2_ingress_my_ip_address__last0_old_value, acceptor2_ingress_my_ip_address__last0_old_value__dbg, acceptor2_ingress_my_ip_address__last0_value, acceptor2_ingress_my_ip_address__last0_value__dbg, acceptor2_ingress_my_ip_address__last_index, acceptor2_ingress_my_ip_address__last_index__dbg, acceptor2_ingress_my_ip_address__last_old_value, acceptor2_ingress_my_ip_address__last_old_value__dbg, acceptor2_ingress_my_ip_address__last_value, acceptor2_ingress_my_ip_address__last_value__dbg, acceptor2_ingress_my_ip_address__last_write_site, acceptor2_ingress_my_ip_address__next_write_site, acceptor2_ingress_my_ip_address__wrote_any, acceptor2_ingress_my_ip_address__wrote_any__dbg, acceptor2_ingress_my_ip_address__wrote_index0, acceptor2_ingress_my_ip_address__wrote_index0__dbg, acceptor2_ingress_my_mac_address__dbg0, acceptor2_ingress_my_mac_address__last0_old_value, acceptor2_ingress_my_mac_address__last0_old_value__dbg, acceptor2_ingress_my_mac_address__last0_value, acceptor2_ingress_my_mac_address__last0_value__dbg, acceptor2_ingress_my_mac_address__last_index, acceptor2_ingress_my_mac_address__last_index__dbg, acceptor2_ingress_my_mac_address__last_old_value, acceptor2_ingress_my_mac_address__last_old_value__dbg, acceptor2_ingress_my_mac_address__last_value, acceptor2_ingress_my_mac_address__last_value__dbg, acceptor2_ingress_my_mac_address__last_write_site, acceptor2_ingress_my_mac_address__next_write_site, acceptor2_ingress_my_mac_address__wrote_any, acceptor2_ingress_my_mac_address__wrote_any__dbg, acceptor2_ingress_my_mac_address__wrote_index0, acceptor2_ingress_my_mac_address__wrote_index0__dbg, acceptor2_ingress_registerAcceptorID__dbg0, acceptor2_ingress_registerAcceptorID__last0_old_value, acceptor2_ingress_registerAcceptorID__last0_old_value__dbg, acceptor2_ingress_registerAcceptorID__last0_value, acceptor2_ingress_registerAcceptorID__last0_value__dbg, acceptor2_ingress_registerAcceptorID__last_index, acceptor2_ingress_registerAcceptorID__last_index__dbg, acceptor2_ingress_registerAcceptorID__last_old_value, acceptor2_ingress_registerAcceptorID__last_old_value__dbg, acceptor2_ingress_registerAcceptorID__last_value, acceptor2_ingress_registerAcceptorID__last_value__dbg, acceptor2_ingress_registerAcceptorID__last_write_site, acceptor2_ingress_registerAcceptorID__next_write_site, acceptor2_ingress_registerAcceptorID__wrote_any, acceptor2_ingress_registerAcceptorID__wrote_any__dbg, acceptor2_ingress_registerAcceptorID__wrote_index0, acceptor2_ingress_registerAcceptorID__wrote_index0__dbg, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__dbg0, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_old_value__dbg, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last0_value__dbg, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_index__dbg, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_old_value__dbg, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_value__dbg, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_any__dbg, acceptor2_ingress_registerRound__wrote_index0, acceptor2_ingress_registerRound__wrote_index0__dbg, acceptor2_ingress_registerVRound, acceptor2_ingress_registerVRound__dbg0, acceptor2_ingress_registerVRound__last0_old_value, acceptor2_ingress_registerVRound__last0_old_value__dbg, acceptor2_ingress_registerVRound__last0_value, acceptor2_ingress_registerVRound__last0_value__dbg, acceptor2_ingress_registerVRound__last_index, acceptor2_ingress_registerVRound__last_index__dbg, acceptor2_ingress_registerVRound__last_old_value, acceptor2_ingress_registerVRound__last_old_value__dbg, acceptor2_ingress_registerVRound__last_value, acceptor2_ingress_registerVRound__last_value__dbg, acceptor2_ingress_registerVRound__last_write_site, acceptor2_ingress_registerVRound__next_write_site, acceptor2_ingress_registerVRound__wrote_any, acceptor2_ingress_registerVRound__wrote_any__dbg, acceptor2_ingress_registerVRound__wrote_index0, acceptor2_ingress_registerVRound__wrote_index0__dbg, acceptor2_ingress_registerValue, acceptor2_ingress_registerValue__dbg0, acceptor2_ingress_registerValue__last0_old_value, acceptor2_ingress_registerValue__last0_old_value__dbg, acceptor2_ingress_registerValue__last0_value, acceptor2_ingress_registerValue__last0_value__dbg, acceptor2_ingress_registerValue__last_index, acceptor2_ingress_registerValue__last_index__dbg, acceptor2_ingress_registerValue__last_old_value, acceptor2_ingress_registerValue__last_old_value__dbg, acceptor2_ingress_registerValue__last_value, acceptor2_ingress_registerValue__last_value__dbg, acceptor2_ingress_registerValue__last_write_site, acceptor2_ingress_registerValue__next_write_site, acceptor2_ingress_registerValue__wrote_any, acceptor2_ingress_registerValue__wrote_any__dbg, acceptor2_ingress_registerValue__wrote_index0, acceptor2_ingress_registerValue__wrote_index0__dbg, acceptor2_ingress_transport_tbl.action_run, acceptor2_ingress_transport_tbl.hit, acceptor2_ipdst_0, acceptor2_isValid, acceptor2_meta.paxos_metadata, acceptor2_meta.paxos_metadata.ack_acceptors, acceptor2_meta.paxos_metadata.ack_count, acceptor2_meta.paxos_metadata.round, acceptor2_meta.paxos_metadata.set_drop, acceptor2_p4b_checksum_error, acceptor2_p4b_checksum_updated, acceptor2_p4b_checksum_verified, acceptor2_p4b_clone_e2e, acceptor2_p4b_clone_i2e, acceptor2_p4b_clone_i2i, acceptor2_p4b_digest, acceptor2_p4b_recirculate, acceptor2_pkt_external, acceptor2_standard_metadata.checksum_error, acceptor2_standard_metadata.deq_qdepth, acceptor2_standard_metadata.deq_timedelta, acceptor2_standard_metadata.egress_global_timestamp, acceptor2_standard_metadata.egress_port, acceptor2_standard_metadata.egress_rid, acceptor2_standard_metadata.egress_spec, acceptor2_standard_metadata.enq_qdepth, acceptor2_standard_metadata.enq_timestamp, acceptor2_standard_metadata.ingress_global_timestamp, acceptor2_standard_metadata.ingress_port, acceptor2_standard_metadata.instance_type, acceptor2_standard_metadata.mcast_grp, acceptor2_standard_metadata.packet_length, acceptor2_standard_metadata.parser_error, acceptor2_standard_metadata.priority, leader_current_instance_0, leader_drop, leader_egress_place_holder_table.hit, leader_forward, leader_hdr.arp.hln, leader_hdr.arp.hrd, leader_hdr.arp.op, leader_hdr.arp.pln, leader_hdr.arp.pro, leader_hdr.arp.sha, leader_hdr.arp.spa, leader_hdr.arp.tha, leader_hdr.arp.tpa, leader_hdr.arp.valid, leader_hdr.ethernet.dstAddr, leader_hdr.ethernet.etherType, leader_hdr.ethernet.srcAddr, leader_hdr.ethernet.valid, leader_hdr.icmp.hdrChecksum, leader_hdr.icmp.icmpCode, leader_hdr.icmp.icmpType, leader_hdr.icmp.identifier, leader_hdr.icmp.payload, leader_hdr.icmp.seqNumber, leader_hdr.icmp.valid, leader_hdr.ipv4.diffserv, leader_hdr.ipv4.dstAddr, leader_hdr.ipv4.flags, leader_hdr.ipv4.fragOffset, leader_hdr.ipv4.hdrChecksum, leader_hdr.ipv4.identification, leader_hdr.ipv4.ihl, leader_hdr.ipv4.protocol, leader_hdr.ipv4.srcAddr, leader_hdr.ipv4.totalLen, leader_hdr.ipv4.ttl, leader_hdr.ipv4.valid, leader_hdr.ipv4.version, leader_hdr.paxos.acptid, leader_hdr.paxos.inst, leader_hdr.paxos.msgtype, leader_hdr.paxos.paxoslen, leader_hdr.paxos.paxosval, leader_hdr.paxos.rnd, leader_hdr.paxos.valid, leader_hdr.paxos.vrnd, leader_hdr.udp.checksum, leader_hdr.udp.dstPort, leader_hdr.udp.length_, leader_hdr.udp.srcPort, leader_hdr.udp.valid, leader_inbox_count, leader_index_0, leader_index_1, leader_ingress_ctrlInstane, leader_ingress_ctrlInstane__dbg0, leader_ingress_ctrlInstane__last0_old_value, leader_ingress_ctrlInstane__last0_old_value__dbg, leader_ingress_ctrlInstane__last0_value, leader_ingress_ctrlInstane__last0_value__dbg, leader_ingress_ctrlInstane__last_index, leader_ingress_ctrlInstane__last_index__dbg, leader_ingress_ctrlInstane__last_old_value, leader_ingress_ctrlInstane__last_old_value__dbg, leader_ingress_ctrlInstane__last_value, leader_ingress_ctrlInstane__last_value__dbg, leader_ingress_ctrlInstane__last_write_site, leader_ingress_ctrlInstane__next_write_site, leader_ingress_ctrlInstane__wrote_any, leader_ingress_ctrlInstane__wrote_any__dbg, leader_ingress_ctrlInstane__wrote_index0, leader_ingress_ctrlInstane__wrote_index0__dbg, leader_ingress_leader_tbl.action_run, leader_ingress_leader_tbl.hit, leader_ingress_transport_tbl.action_run, leader_ingress_transport_tbl.hit, leader_isValid, leader_meta.paxos_metadata, leader_meta.paxos_metadata.ack_acceptors, leader_meta.paxos_metadata.ack_count, leader_meta.paxos_metadata.round, leader_meta.paxos_metadata.set_drop, leader_p4b_checksum_error, leader_p4b_checksum_updated, leader_p4b_checksum_verified, leader_p4b_clone_e2e, leader_p4b_clone_i2e, leader_p4b_clone_i2i, leader_p4b_digest, leader_p4b_recirculate, leader_pkt_external, leader_reset_value_0, leader_standard_metadata.checksum_error, leader_standard_metadata.deq_qdepth, leader_standard_metadata.deq_timedelta, leader_standard_metadata.egress_global_timestamp, leader_standard_metadata.egress_port, leader_standard_metadata.egress_rid, leader_standard_metadata.egress_spec, leader_standard_metadata.enq_qdepth, leader_standard_metadata.enq_timestamp, leader_standard_metadata.ingress_global_timestamp, leader_standard_metadata.ingress_port, leader_standard_metadata.instance_type, leader_standard_metadata.mcast_grp, leader_standard_metadata.packet_length, leader_standard_metadata.parser_error, leader_standard_metadata.priority, learner_acptid_0, learner_acptid_1, learner_drop, learner_egress_place_holder_table.hit, learner_forward, learner_hdr.arp.hln, learner_hdr.arp.hrd, learner_hdr.arp.op, learner_hdr.arp.pln, learner_hdr.arp.pro, learner_hdr.arp.sha, learner_hdr.arp.spa, learner_hdr.arp.tha, learner_hdr.arp.tpa, learner_hdr.arp.valid, learner_hdr.ethernet.dstAddr, learner_hdr.ethernet.etherType, learner_hdr.ethernet.srcAddr, learner_hdr.ethernet.valid, learner_hdr.icmp.hdrChecksum, learner_hdr.icmp.icmpCode, learner_hdr.icmp.icmpType, learner_hdr.icmp.identifier, learner_hdr.icmp.payload, learner_hdr.icmp.seqNumber, learner_hdr.icmp.valid, learner_hdr.ipv4.diffserv, learner_hdr.ipv4.dstAddr, learner_hdr.ipv4.flags, learner_hdr.ipv4.fragOffset, learner_hdr.ipv4.hdrChecksum, learner_hdr.ipv4.identification, learner_hdr.ipv4.ihl, learner_hdr.ipv4.protocol, learner_hdr.ipv4.srcAddr, learner_hdr.ipv4.totalLen, learner_hdr.ipv4.ttl, learner_hdr.ipv4.valid, learner_hdr.ipv4.version, learner_hdr.paxos.acptid, learner_hdr.paxos.inst, learner_hdr.paxos.msgtype, learner_hdr.paxos.paxoslen, learner_hdr.paxos.paxosval, learner_hdr.paxos.rnd, learner_hdr.paxos.valid, learner_hdr.paxos.vrnd, learner_hdr.udp.checksum, learner_hdr.udp.dstPort, learner_hdr.udp.length_, learner_hdr.udp.srcPort, learner_hdr.udp.valid, learner_inbox_count, learner_ingress_learner_tbl.action_run, learner_ingress_learner_tbl.hit, learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__dbg0, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_old_value__dbg, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last0_value__dbg, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_index__dbg, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_old_value__dbg, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_value__dbg, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__next_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_any__dbg, learner_ingress_registerHistory2B__wrote_index0, learner_ingress_registerHistory2B__wrote_index0__dbg, learner_ingress_registerRound, learner_ingress_registerRound__dbg0, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_old_value__dbg, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last0_value__dbg, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_index__dbg, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_old_value__dbg, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_value__dbg, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__next_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_any__dbg, learner_ingress_registerRound__wrote_index0, learner_ingress_registerRound__wrote_index0__dbg, learner_ingress_registerValue, learner_ingress_registerValue__dbg0, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_old_value__dbg, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last0_value__dbg, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_index__dbg, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_old_value__dbg, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_value__dbg, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__next_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_any__dbg, learner_ingress_registerValue__wrote_index0, learner_ingress_registerValue__wrote_index0__dbg, learner_ingress_reset_consensus_instance.action_run, learner_ingress_reset_consensus_instance.hit, learner_ingress_transport_tbl.action_run, learner_ingress_transport_tbl.hit, learner_isValid, learner_meta.paxos_metadata, learner_meta.paxos_metadata.ack_acceptors, learner_meta.paxos_metadata.ack_count, learner_meta.paxos_metadata.round, learner_meta.paxos_metadata.set_drop, learner_p4b_checksum_error, learner_p4b_checksum_updated, learner_p4b_checksum_verified, learner_p4b_clone_e2e, learner_p4b_clone_i2e, learner_p4b_clone_i2i, learner_p4b_digest, learner_p4b_recirculate, learner_pkt_external, learner_standard_metadata.checksum_error, learner_standard_metadata.deq_qdepth, learner_standard_metadata.deq_timedelta, learner_standard_metadata.egress_global_timestamp, learner_standard_metadata.egress_port, learner_standard_metadata.egress_rid, learner_standard_metadata.egress_spec, learner_standard_metadata.enq_qdepth, learner_standard_metadata.enq_timestamp, learner_standard_metadata.ingress_global_timestamp, learner_standard_metadata.ingress_port, learner_standard_metadata.instance_type, learner_standard_metadata.mcast_grp, learner_standard_metadata.packet_length, learner_standard_metadata.parser_error, learner_standard_metadata.priority, procurator_step;
{
  // initialize inboxes
  leader_inbox_count := 0;
  leader_pkt_external := false;
  acceptor0_inbox_count := 0;
  acceptor0_pkt_external := false;
  acceptor1_inbox_count := 0;
  acceptor1_pkt_external := false;
  acceptor2_inbox_count := 0;
  acceptor2_pkt_external := false;
  learner_inbox_count := 0;
  learner_pkt_external := false;
  // initialize P4B event flags (clone/recirculate)
  leader_p4b_clone_i2e := false;
  leader_p4b_clone_e2e := false;
  leader_p4b_clone_i2i := false;
  leader_p4b_recirculate := false;
  acceptor0_p4b_clone_i2e := false;
  acceptor0_p4b_clone_e2e := false;
  acceptor0_p4b_clone_i2i := false;
  acceptor0_p4b_recirculate := false;
  acceptor1_p4b_clone_i2e := false;
  acceptor1_p4b_clone_e2e := false;
  acceptor1_p4b_clone_i2i := false;
  acceptor1_p4b_recirculate := false;
  acceptor2_p4b_clone_i2e := false;
  acceptor2_p4b_clone_e2e := false;
  acceptor2_p4b_clone_i2i := false;
  acceptor2_p4b_recirculate := false;
  learner_p4b_clone_i2e := false;
  learner_p4b_clone_e2e := false;
  learner_p4b_clone_i2i := false;
  learner_p4b_recirculate := false;

  // initialize P4 registers (default 0)
  assume leader_ingress_ctrlInstane[0bv32] == 0bv32;
  assume acceptor0_ingress_learner_address[0bv32] == 0bv32;
  assume acceptor0_ingress_learner_mac_address[0bv32] == 0bv48;
  assume acceptor0_ingress_my_ip_address[0bv32] == 0bv32;
  assume acceptor0_ingress_my_mac_address[0bv32] == 0bv48;
  assume acceptor0_ingress_registerAcceptorID[0bv32] == 0bv16;
  assume (forall i:bv32 :: acceptor0_ingress_registerRound[i] == 0bv16);
  assume acceptor0_ingress_registerRound[0bv32] == 0bv16;
  assume (forall i:bv32 :: acceptor0_ingress_registerVRound[i] == 0bv16);
  assume acceptor0_ingress_registerVRound[0bv32] == 0bv16;
  assume (forall i:bv32 :: acceptor0_ingress_registerValue[i] == 0bv256);
  assume acceptor0_ingress_registerValue[0bv32] == 0bv256;
  assume acceptor1_ingress_learner_address[0bv32] == 0bv32;
  assume acceptor1_ingress_learner_mac_address[0bv32] == 0bv48;
  assume acceptor1_ingress_my_ip_address[0bv32] == 0bv32;
  assume acceptor1_ingress_my_mac_address[0bv32] == 0bv48;
  assume acceptor1_ingress_registerAcceptorID[0bv32] == 0bv16;
  assume (forall i:bv32 :: acceptor1_ingress_registerRound[i] == 0bv16);
  assume acceptor1_ingress_registerRound[0bv32] == 0bv16;
  assume (forall i:bv32 :: acceptor1_ingress_registerVRound[i] == 0bv16);
  assume acceptor1_ingress_registerVRound[0bv32] == 0bv16;
  assume (forall i:bv32 :: acceptor1_ingress_registerValue[i] == 0bv256);
  assume acceptor1_ingress_registerValue[0bv32] == 0bv256;
  assume acceptor2_ingress_learner_address[0bv32] == 0bv32;
  assume acceptor2_ingress_learner_mac_address[0bv32] == 0bv48;
  assume acceptor2_ingress_my_ip_address[0bv32] == 0bv32;
  assume acceptor2_ingress_my_mac_address[0bv32] == 0bv48;
  assume acceptor2_ingress_registerAcceptorID[0bv32] == 0bv16;
  assume (forall i:bv32 :: acceptor2_ingress_registerRound[i] == 0bv16);
  assume acceptor2_ingress_registerRound[0bv32] == 0bv16;
  assume (forall i:bv32 :: acceptor2_ingress_registerVRound[i] == 0bv16);
  assume acceptor2_ingress_registerVRound[0bv32] == 0bv16;
  assume (forall i:bv32 :: acceptor2_ingress_registerValue[i] == 0bv256);
  assume acceptor2_ingress_registerValue[0bv32] == 0bv256;
  assume (forall i:bv32 :: learner_ingress_registerHistory2B[i] == 0bv8);
  assume learner_ingress_registerHistory2B[0bv32] == 0bv8;
  assume (forall i:bv32 :: learner_ingress_registerRound[i] == 0bv16);
  assume learner_ingress_registerRound[0bv32] == 0bv16;
  assume (forall i:bv32 :: learner_ingress_registerValue[i] == 0bv256);
  assume learner_ingress_registerValue[0bv32] == 0bv256;
  // initialize register write tracking (debug)
  leader_ingress_ctrlInstane__last_index := 0bv32;
  leader_ingress_ctrlInstane__last_value := 0bv32;
  leader_ingress_ctrlInstane__last_old_value := 0bv32;
  leader_ingress_ctrlInstane__wrote_any := false;
  leader_ingress_ctrlInstane__wrote_index0 := false;
  leader_ingress_ctrlInstane__next_write_site := 0;
  leader_ingress_ctrlInstane__last_write_site := 0;
  leader_ingress_ctrlInstane__last0_old_value := 0bv32;
  leader_ingress_ctrlInstane__last0_value := 0bv32;
  acceptor0_ingress_learner_address__last_index := 0bv32;
  acceptor0_ingress_learner_address__last_value := 0bv32;
  acceptor0_ingress_learner_address__last_old_value := 0bv32;
  acceptor0_ingress_learner_address__wrote_any := false;
  acceptor0_ingress_learner_address__wrote_index0 := false;
  acceptor0_ingress_learner_address__next_write_site := 0;
  acceptor0_ingress_learner_address__last_write_site := 0;
  acceptor0_ingress_learner_address__last0_old_value := 0bv32;
  acceptor0_ingress_learner_address__last0_value := 0bv32;
  acceptor0_ingress_learner_mac_address__last_index := 0bv32;
  acceptor0_ingress_learner_mac_address__last_value := 0bv48;
  acceptor0_ingress_learner_mac_address__last_old_value := 0bv48;
  acceptor0_ingress_learner_mac_address__wrote_any := false;
  acceptor0_ingress_learner_mac_address__wrote_index0 := false;
  acceptor0_ingress_learner_mac_address__next_write_site := 0;
  acceptor0_ingress_learner_mac_address__last_write_site := 0;
  acceptor0_ingress_learner_mac_address__last0_old_value := 0bv48;
  acceptor0_ingress_learner_mac_address__last0_value := 0bv48;
  acceptor0_ingress_my_ip_address__last_index := 0bv32;
  acceptor0_ingress_my_ip_address__last_value := 0bv32;
  acceptor0_ingress_my_ip_address__last_old_value := 0bv32;
  acceptor0_ingress_my_ip_address__wrote_any := false;
  acceptor0_ingress_my_ip_address__wrote_index0 := false;
  acceptor0_ingress_my_ip_address__next_write_site := 0;
  acceptor0_ingress_my_ip_address__last_write_site := 0;
  acceptor0_ingress_my_ip_address__last0_old_value := 0bv32;
  acceptor0_ingress_my_ip_address__last0_value := 0bv32;
  acceptor0_ingress_my_mac_address__last_index := 0bv32;
  acceptor0_ingress_my_mac_address__last_value := 0bv48;
  acceptor0_ingress_my_mac_address__last_old_value := 0bv48;
  acceptor0_ingress_my_mac_address__wrote_any := false;
  acceptor0_ingress_my_mac_address__wrote_index0 := false;
  acceptor0_ingress_my_mac_address__next_write_site := 0;
  acceptor0_ingress_my_mac_address__last_write_site := 0;
  acceptor0_ingress_my_mac_address__last0_old_value := 0bv48;
  acceptor0_ingress_my_mac_address__last0_value := 0bv48;
  acceptor0_ingress_registerAcceptorID__last_index := 0bv32;
  acceptor0_ingress_registerAcceptorID__last_value := 0bv16;
  acceptor0_ingress_registerAcceptorID__last_old_value := 0bv16;
  acceptor0_ingress_registerAcceptorID__wrote_any := false;
  acceptor0_ingress_registerAcceptorID__wrote_index0 := false;
  acceptor0_ingress_registerAcceptorID__next_write_site := 0;
  acceptor0_ingress_registerAcceptorID__last_write_site := 0;
  acceptor0_ingress_registerAcceptorID__last0_old_value := 0bv16;
  acceptor0_ingress_registerAcceptorID__last0_value := 0bv16;
  acceptor0_ingress_registerRound__last_index := 0bv32;
  acceptor0_ingress_registerRound__last_value := 0bv16;
  acceptor0_ingress_registerRound__last_old_value := 0bv16;
  acceptor0_ingress_registerRound__wrote_any := false;
  acceptor0_ingress_registerRound__wrote_index0 := false;
  acceptor0_ingress_registerRound__next_write_site := 0;
  acceptor0_ingress_registerRound__last_write_site := 0;
  acceptor0_ingress_registerRound__last0_old_value := 0bv16;
  acceptor0_ingress_registerRound__last0_value := 0bv16;
  acceptor0_ingress_registerVRound__last_index := 0bv32;
  acceptor0_ingress_registerVRound__last_value := 0bv16;
  acceptor0_ingress_registerVRound__last_old_value := 0bv16;
  acceptor0_ingress_registerVRound__wrote_any := false;
  acceptor0_ingress_registerVRound__wrote_index0 := false;
  acceptor0_ingress_registerVRound__next_write_site := 0;
  acceptor0_ingress_registerVRound__last_write_site := 0;
  acceptor0_ingress_registerVRound__last0_old_value := 0bv16;
  acceptor0_ingress_registerVRound__last0_value := 0bv16;
  acceptor0_ingress_registerValue__last_index := 0bv32;
  acceptor0_ingress_registerValue__last_value := 0bv256;
  acceptor0_ingress_registerValue__last_old_value := 0bv256;
  acceptor0_ingress_registerValue__wrote_any := false;
  acceptor0_ingress_registerValue__wrote_index0 := false;
  acceptor0_ingress_registerValue__next_write_site := 0;
  acceptor0_ingress_registerValue__last_write_site := 0;
  acceptor0_ingress_registerValue__last0_old_value := 0bv256;
  acceptor0_ingress_registerValue__last0_value := 0bv256;
  acceptor1_ingress_learner_address__last_index := 0bv32;
  acceptor1_ingress_learner_address__last_value := 0bv32;
  acceptor1_ingress_learner_address__last_old_value := 0bv32;
  acceptor1_ingress_learner_address__wrote_any := false;
  acceptor1_ingress_learner_address__wrote_index0 := false;
  acceptor1_ingress_learner_address__next_write_site := 0;
  acceptor1_ingress_learner_address__last_write_site := 0;
  acceptor1_ingress_learner_address__last0_old_value := 0bv32;
  acceptor1_ingress_learner_address__last0_value := 0bv32;
  acceptor1_ingress_learner_mac_address__last_index := 0bv32;
  acceptor1_ingress_learner_mac_address__last_value := 0bv48;
  acceptor1_ingress_learner_mac_address__last_old_value := 0bv48;
  acceptor1_ingress_learner_mac_address__wrote_any := false;
  acceptor1_ingress_learner_mac_address__wrote_index0 := false;
  acceptor1_ingress_learner_mac_address__next_write_site := 0;
  acceptor1_ingress_learner_mac_address__last_write_site := 0;
  acceptor1_ingress_learner_mac_address__last0_old_value := 0bv48;
  acceptor1_ingress_learner_mac_address__last0_value := 0bv48;
  acceptor1_ingress_my_ip_address__last_index := 0bv32;
  acceptor1_ingress_my_ip_address__last_value := 0bv32;
  acceptor1_ingress_my_ip_address__last_old_value := 0bv32;
  acceptor1_ingress_my_ip_address__wrote_any := false;
  acceptor1_ingress_my_ip_address__wrote_index0 := false;
  acceptor1_ingress_my_ip_address__next_write_site := 0;
  acceptor1_ingress_my_ip_address__last_write_site := 0;
  acceptor1_ingress_my_ip_address__last0_old_value := 0bv32;
  acceptor1_ingress_my_ip_address__last0_value := 0bv32;
  acceptor1_ingress_my_mac_address__last_index := 0bv32;
  acceptor1_ingress_my_mac_address__last_value := 0bv48;
  acceptor1_ingress_my_mac_address__last_old_value := 0bv48;
  acceptor1_ingress_my_mac_address__wrote_any := false;
  acceptor1_ingress_my_mac_address__wrote_index0 := false;
  acceptor1_ingress_my_mac_address__next_write_site := 0;
  acceptor1_ingress_my_mac_address__last_write_site := 0;
  acceptor1_ingress_my_mac_address__last0_old_value := 0bv48;
  acceptor1_ingress_my_mac_address__last0_value := 0bv48;
  acceptor1_ingress_registerAcceptorID__last_index := 0bv32;
  acceptor1_ingress_registerAcceptorID__last_value := 0bv16;
  acceptor1_ingress_registerAcceptorID__last_old_value := 0bv16;
  acceptor1_ingress_registerAcceptorID__wrote_any := false;
  acceptor1_ingress_registerAcceptorID__wrote_index0 := false;
  acceptor1_ingress_registerAcceptorID__next_write_site := 0;
  acceptor1_ingress_registerAcceptorID__last_write_site := 0;
  acceptor1_ingress_registerAcceptorID__last0_old_value := 0bv16;
  acceptor1_ingress_registerAcceptorID__last0_value := 0bv16;
  acceptor1_ingress_registerRound__last_index := 0bv32;
  acceptor1_ingress_registerRound__last_value := 0bv16;
  acceptor1_ingress_registerRound__last_old_value := 0bv16;
  acceptor1_ingress_registerRound__wrote_any := false;
  acceptor1_ingress_registerRound__wrote_index0 := false;
  acceptor1_ingress_registerRound__next_write_site := 0;
  acceptor1_ingress_registerRound__last_write_site := 0;
  acceptor1_ingress_registerRound__last0_old_value := 0bv16;
  acceptor1_ingress_registerRound__last0_value := 0bv16;
  acceptor1_ingress_registerVRound__last_index := 0bv32;
  acceptor1_ingress_registerVRound__last_value := 0bv16;
  acceptor1_ingress_registerVRound__last_old_value := 0bv16;
  acceptor1_ingress_registerVRound__wrote_any := false;
  acceptor1_ingress_registerVRound__wrote_index0 := false;
  acceptor1_ingress_registerVRound__next_write_site := 0;
  acceptor1_ingress_registerVRound__last_write_site := 0;
  acceptor1_ingress_registerVRound__last0_old_value := 0bv16;
  acceptor1_ingress_registerVRound__last0_value := 0bv16;
  acceptor1_ingress_registerValue__last_index := 0bv32;
  acceptor1_ingress_registerValue__last_value := 0bv256;
  acceptor1_ingress_registerValue__last_old_value := 0bv256;
  acceptor1_ingress_registerValue__wrote_any := false;
  acceptor1_ingress_registerValue__wrote_index0 := false;
  acceptor1_ingress_registerValue__next_write_site := 0;
  acceptor1_ingress_registerValue__last_write_site := 0;
  acceptor1_ingress_registerValue__last0_old_value := 0bv256;
  acceptor1_ingress_registerValue__last0_value := 0bv256;
  acceptor2_ingress_learner_address__last_index := 0bv32;
  acceptor2_ingress_learner_address__last_value := 0bv32;
  acceptor2_ingress_learner_address__last_old_value := 0bv32;
  acceptor2_ingress_learner_address__wrote_any := false;
  acceptor2_ingress_learner_address__wrote_index0 := false;
  acceptor2_ingress_learner_address__next_write_site := 0;
  acceptor2_ingress_learner_address__last_write_site := 0;
  acceptor2_ingress_learner_address__last0_old_value := 0bv32;
  acceptor2_ingress_learner_address__last0_value := 0bv32;
  acceptor2_ingress_learner_mac_address__last_index := 0bv32;
  acceptor2_ingress_learner_mac_address__last_value := 0bv48;
  acceptor2_ingress_learner_mac_address__last_old_value := 0bv48;
  acceptor2_ingress_learner_mac_address__wrote_any := false;
  acceptor2_ingress_learner_mac_address__wrote_index0 := false;
  acceptor2_ingress_learner_mac_address__next_write_site := 0;
  acceptor2_ingress_learner_mac_address__last_write_site := 0;
  acceptor2_ingress_learner_mac_address__last0_old_value := 0bv48;
  acceptor2_ingress_learner_mac_address__last0_value := 0bv48;
  acceptor2_ingress_my_ip_address__last_index := 0bv32;
  acceptor2_ingress_my_ip_address__last_value := 0bv32;
  acceptor2_ingress_my_ip_address__last_old_value := 0bv32;
  acceptor2_ingress_my_ip_address__wrote_any := false;
  acceptor2_ingress_my_ip_address__wrote_index0 := false;
  acceptor2_ingress_my_ip_address__next_write_site := 0;
  acceptor2_ingress_my_ip_address__last_write_site := 0;
  acceptor2_ingress_my_ip_address__last0_old_value := 0bv32;
  acceptor2_ingress_my_ip_address__last0_value := 0bv32;
  acceptor2_ingress_my_mac_address__last_index := 0bv32;
  acceptor2_ingress_my_mac_address__last_value := 0bv48;
  acceptor2_ingress_my_mac_address__last_old_value := 0bv48;
  acceptor2_ingress_my_mac_address__wrote_any := false;
  acceptor2_ingress_my_mac_address__wrote_index0 := false;
  acceptor2_ingress_my_mac_address__next_write_site := 0;
  acceptor2_ingress_my_mac_address__last_write_site := 0;
  acceptor2_ingress_my_mac_address__last0_old_value := 0bv48;
  acceptor2_ingress_my_mac_address__last0_value := 0bv48;
  acceptor2_ingress_registerAcceptorID__last_index := 0bv32;
  acceptor2_ingress_registerAcceptorID__last_value := 0bv16;
  acceptor2_ingress_registerAcceptorID__last_old_value := 0bv16;
  acceptor2_ingress_registerAcceptorID__wrote_any := false;
  acceptor2_ingress_registerAcceptorID__wrote_index0 := false;
  acceptor2_ingress_registerAcceptorID__next_write_site := 0;
  acceptor2_ingress_registerAcceptorID__last_write_site := 0;
  acceptor2_ingress_registerAcceptorID__last0_old_value := 0bv16;
  acceptor2_ingress_registerAcceptorID__last0_value := 0bv16;
  acceptor2_ingress_registerRound__last_index := 0bv32;
  acceptor2_ingress_registerRound__last_value := 0bv16;
  acceptor2_ingress_registerRound__last_old_value := 0bv16;
  acceptor2_ingress_registerRound__wrote_any := false;
  acceptor2_ingress_registerRound__wrote_index0 := false;
  acceptor2_ingress_registerRound__next_write_site := 0;
  acceptor2_ingress_registerRound__last_write_site := 0;
  acceptor2_ingress_registerRound__last0_old_value := 0bv16;
  acceptor2_ingress_registerRound__last0_value := 0bv16;
  acceptor2_ingress_registerVRound__last_index := 0bv32;
  acceptor2_ingress_registerVRound__last_value := 0bv16;
  acceptor2_ingress_registerVRound__last_old_value := 0bv16;
  acceptor2_ingress_registerVRound__wrote_any := false;
  acceptor2_ingress_registerVRound__wrote_index0 := false;
  acceptor2_ingress_registerVRound__next_write_site := 0;
  acceptor2_ingress_registerVRound__last_write_site := 0;
  acceptor2_ingress_registerVRound__last0_old_value := 0bv16;
  acceptor2_ingress_registerVRound__last0_value := 0bv16;
  acceptor2_ingress_registerValue__last_index := 0bv32;
  acceptor2_ingress_registerValue__last_value := 0bv256;
  acceptor2_ingress_registerValue__last_old_value := 0bv256;
  acceptor2_ingress_registerValue__wrote_any := false;
  acceptor2_ingress_registerValue__wrote_index0 := false;
  acceptor2_ingress_registerValue__next_write_site := 0;
  acceptor2_ingress_registerValue__last_write_site := 0;
  acceptor2_ingress_registerValue__last0_old_value := 0bv256;
  acceptor2_ingress_registerValue__last0_value := 0bv256;
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
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}


procedure ULTIMATE.start() returns()
  modifies acceptor0_drop, acceptor0_egress_place_holder_table.hit, acceptor0_forward, acceptor0_hdr.arp.hln, acceptor0_hdr.arp.hrd, acceptor0_hdr.arp.op, acceptor0_hdr.arp.pln, acceptor0_hdr.arp.pro, acceptor0_hdr.arp.sha, acceptor0_hdr.arp.spa, acceptor0_hdr.arp.tha, acceptor0_hdr.arp.tpa, acceptor0_hdr.arp.valid, acceptor0_hdr.ethernet.dstAddr, acceptor0_hdr.ethernet.etherType, acceptor0_hdr.ethernet.srcAddr, acceptor0_hdr.ethernet.valid, acceptor0_hdr.icmp.hdrChecksum, acceptor0_hdr.icmp.icmpCode, acceptor0_hdr.icmp.icmpType, acceptor0_hdr.icmp.identifier, acceptor0_hdr.icmp.payload, acceptor0_hdr.icmp.seqNumber, acceptor0_hdr.icmp.valid, acceptor0_hdr.ipv4.diffserv, acceptor0_hdr.ipv4.dstAddr, acceptor0_hdr.ipv4.flags, acceptor0_hdr.ipv4.fragOffset, acceptor0_hdr.ipv4.hdrChecksum, acceptor0_hdr.ipv4.identification, acceptor0_hdr.ipv4.ihl, acceptor0_hdr.ipv4.protocol, acceptor0_hdr.ipv4.srcAddr, acceptor0_hdr.ipv4.totalLen, acceptor0_hdr.ipv4.ttl, acceptor0_hdr.ipv4.valid, acceptor0_hdr.ipv4.version, acceptor0_hdr.paxos.acptid, acceptor0_hdr.paxos.inst, acceptor0_hdr.paxos.msgtype, acceptor0_hdr.paxos.paxoslen, acceptor0_hdr.paxos.paxosval, acceptor0_hdr.paxos.rnd, acceptor0_hdr.paxos.valid, acceptor0_hdr.paxos.vrnd, acceptor0_hdr.udp.checksum, acceptor0_hdr.udp.dstPort, acceptor0_hdr.udp.length_, acceptor0_hdr.udp.srcPort, acceptor0_hdr.udp.valid, acceptor0_inbox_count, acceptor0_ingress_acceptor_tbl.action_run, acceptor0_ingress_acceptor_tbl.hit, acceptor0_ingress_arp_tbl.action_run, acceptor0_ingress_arp_tbl.hit, acceptor0_ingress_icmp_tbl.action_run, acceptor0_ingress_icmp_tbl.hit, acceptor0_ingress_learner_address__dbg0, acceptor0_ingress_learner_address__last0_old_value, acceptor0_ingress_learner_address__last0_old_value__dbg, acceptor0_ingress_learner_address__last0_value, acceptor0_ingress_learner_address__last0_value__dbg, acceptor0_ingress_learner_address__last_index, acceptor0_ingress_learner_address__last_index__dbg, acceptor0_ingress_learner_address__last_old_value, acceptor0_ingress_learner_address__last_old_value__dbg, acceptor0_ingress_learner_address__last_value, acceptor0_ingress_learner_address__last_value__dbg, acceptor0_ingress_learner_address__last_write_site, acceptor0_ingress_learner_address__next_write_site, acceptor0_ingress_learner_address__wrote_any, acceptor0_ingress_learner_address__wrote_any__dbg, acceptor0_ingress_learner_address__wrote_index0, acceptor0_ingress_learner_address__wrote_index0__dbg, acceptor0_ingress_learner_mac_address__dbg0, acceptor0_ingress_learner_mac_address__last0_old_value, acceptor0_ingress_learner_mac_address__last0_old_value__dbg, acceptor0_ingress_learner_mac_address__last0_value, acceptor0_ingress_learner_mac_address__last0_value__dbg, acceptor0_ingress_learner_mac_address__last_index, acceptor0_ingress_learner_mac_address__last_index__dbg, acceptor0_ingress_learner_mac_address__last_old_value, acceptor0_ingress_learner_mac_address__last_old_value__dbg, acceptor0_ingress_learner_mac_address__last_value, acceptor0_ingress_learner_mac_address__last_value__dbg, acceptor0_ingress_learner_mac_address__last_write_site, acceptor0_ingress_learner_mac_address__next_write_site, acceptor0_ingress_learner_mac_address__wrote_any, acceptor0_ingress_learner_mac_address__wrote_any__dbg, acceptor0_ingress_learner_mac_address__wrote_index0, acceptor0_ingress_learner_mac_address__wrote_index0__dbg, acceptor0_ingress_my_ip_address__dbg0, acceptor0_ingress_my_ip_address__last0_old_value, acceptor0_ingress_my_ip_address__last0_old_value__dbg, acceptor0_ingress_my_ip_address__last0_value, acceptor0_ingress_my_ip_address__last0_value__dbg, acceptor0_ingress_my_ip_address__last_index, acceptor0_ingress_my_ip_address__last_index__dbg, acceptor0_ingress_my_ip_address__last_old_value, acceptor0_ingress_my_ip_address__last_old_value__dbg, acceptor0_ingress_my_ip_address__last_value, acceptor0_ingress_my_ip_address__last_value__dbg, acceptor0_ingress_my_ip_address__last_write_site, acceptor0_ingress_my_ip_address__next_write_site, acceptor0_ingress_my_ip_address__wrote_any, acceptor0_ingress_my_ip_address__wrote_any__dbg, acceptor0_ingress_my_ip_address__wrote_index0, acceptor0_ingress_my_ip_address__wrote_index0__dbg, acceptor0_ingress_my_mac_address__dbg0, acceptor0_ingress_my_mac_address__last0_old_value, acceptor0_ingress_my_mac_address__last0_old_value__dbg, acceptor0_ingress_my_mac_address__last0_value, acceptor0_ingress_my_mac_address__last0_value__dbg, acceptor0_ingress_my_mac_address__last_index, acceptor0_ingress_my_mac_address__last_index__dbg, acceptor0_ingress_my_mac_address__last_old_value, acceptor0_ingress_my_mac_address__last_old_value__dbg, acceptor0_ingress_my_mac_address__last_value, acceptor0_ingress_my_mac_address__last_value__dbg, acceptor0_ingress_my_mac_address__last_write_site, acceptor0_ingress_my_mac_address__next_write_site, acceptor0_ingress_my_mac_address__wrote_any, acceptor0_ingress_my_mac_address__wrote_any__dbg, acceptor0_ingress_my_mac_address__wrote_index0, acceptor0_ingress_my_mac_address__wrote_index0__dbg, acceptor0_ingress_registerAcceptorID__dbg0, acceptor0_ingress_registerAcceptorID__last0_old_value, acceptor0_ingress_registerAcceptorID__last0_old_value__dbg, acceptor0_ingress_registerAcceptorID__last0_value, acceptor0_ingress_registerAcceptorID__last0_value__dbg, acceptor0_ingress_registerAcceptorID__last_index, acceptor0_ingress_registerAcceptorID__last_index__dbg, acceptor0_ingress_registerAcceptorID__last_old_value, acceptor0_ingress_registerAcceptorID__last_old_value__dbg, acceptor0_ingress_registerAcceptorID__last_value, acceptor0_ingress_registerAcceptorID__last_value__dbg, acceptor0_ingress_registerAcceptorID__last_write_site, acceptor0_ingress_registerAcceptorID__next_write_site, acceptor0_ingress_registerAcceptorID__wrote_any, acceptor0_ingress_registerAcceptorID__wrote_any__dbg, acceptor0_ingress_registerAcceptorID__wrote_index0, acceptor0_ingress_registerAcceptorID__wrote_index0__dbg, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__dbg0, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_old_value__dbg, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last0_value__dbg, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_index__dbg, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_old_value__dbg, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_value__dbg, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_any__dbg, acceptor0_ingress_registerRound__wrote_index0, acceptor0_ingress_registerRound__wrote_index0__dbg, acceptor0_ingress_registerVRound, acceptor0_ingress_registerVRound__dbg0, acceptor0_ingress_registerVRound__last0_old_value, acceptor0_ingress_registerVRound__last0_old_value__dbg, acceptor0_ingress_registerVRound__last0_value, acceptor0_ingress_registerVRound__last0_value__dbg, acceptor0_ingress_registerVRound__last_index, acceptor0_ingress_registerVRound__last_index__dbg, acceptor0_ingress_registerVRound__last_old_value, acceptor0_ingress_registerVRound__last_old_value__dbg, acceptor0_ingress_registerVRound__last_value, acceptor0_ingress_registerVRound__last_value__dbg, acceptor0_ingress_registerVRound__last_write_site, acceptor0_ingress_registerVRound__next_write_site, acceptor0_ingress_registerVRound__wrote_any, acceptor0_ingress_registerVRound__wrote_any__dbg, acceptor0_ingress_registerVRound__wrote_index0, acceptor0_ingress_registerVRound__wrote_index0__dbg, acceptor0_ingress_registerValue, acceptor0_ingress_registerValue__dbg0, acceptor0_ingress_registerValue__last0_old_value, acceptor0_ingress_registerValue__last0_old_value__dbg, acceptor0_ingress_registerValue__last0_value, acceptor0_ingress_registerValue__last0_value__dbg, acceptor0_ingress_registerValue__last_index, acceptor0_ingress_registerValue__last_index__dbg, acceptor0_ingress_registerValue__last_old_value, acceptor0_ingress_registerValue__last_old_value__dbg, acceptor0_ingress_registerValue__last_value, acceptor0_ingress_registerValue__last_value__dbg, acceptor0_ingress_registerValue__last_write_site, acceptor0_ingress_registerValue__next_write_site, acceptor0_ingress_registerValue__wrote_any, acceptor0_ingress_registerValue__wrote_any__dbg, acceptor0_ingress_registerValue__wrote_index0, acceptor0_ingress_registerValue__wrote_index0__dbg, acceptor0_ingress_transport_tbl.action_run, acceptor0_ingress_transport_tbl.hit, acceptor0_ipdst_0, acceptor0_isValid, acceptor0_meta.paxos_metadata, acceptor0_meta.paxos_metadata.ack_acceptors, acceptor0_meta.paxos_metadata.ack_count, acceptor0_meta.paxos_metadata.round, acceptor0_meta.paxos_metadata.set_drop, acceptor0_p4b_checksum_error, acceptor0_p4b_checksum_updated, acceptor0_p4b_checksum_verified, acceptor0_p4b_clone_e2e, acceptor0_p4b_clone_i2e, acceptor0_p4b_clone_i2i, acceptor0_p4b_digest, acceptor0_p4b_recirculate, acceptor0_pkt_external, acceptor0_standard_metadata.checksum_error, acceptor0_standard_metadata.deq_qdepth, acceptor0_standard_metadata.deq_timedelta, acceptor0_standard_metadata.egress_global_timestamp, acceptor0_standard_metadata.egress_port, acceptor0_standard_metadata.egress_rid, acceptor0_standard_metadata.egress_spec, acceptor0_standard_metadata.enq_qdepth, acceptor0_standard_metadata.enq_timestamp, acceptor0_standard_metadata.ingress_global_timestamp, acceptor0_standard_metadata.ingress_port, acceptor0_standard_metadata.instance_type, acceptor0_standard_metadata.mcast_grp, acceptor0_standard_metadata.packet_length, acceptor0_standard_metadata.parser_error, acceptor0_standard_metadata.priority, acceptor1_drop, acceptor1_egress_place_holder_table.hit, acceptor1_forward, acceptor1_hdr.arp.hln, acceptor1_hdr.arp.hrd, acceptor1_hdr.arp.op, acceptor1_hdr.arp.pln, acceptor1_hdr.arp.pro, acceptor1_hdr.arp.sha, acceptor1_hdr.arp.spa, acceptor1_hdr.arp.tha, acceptor1_hdr.arp.tpa, acceptor1_hdr.arp.valid, acceptor1_hdr.ethernet.dstAddr, acceptor1_hdr.ethernet.etherType, acceptor1_hdr.ethernet.srcAddr, acceptor1_hdr.ethernet.valid, acceptor1_hdr.icmp.hdrChecksum, acceptor1_hdr.icmp.icmpCode, acceptor1_hdr.icmp.icmpType, acceptor1_hdr.icmp.identifier, acceptor1_hdr.icmp.payload, acceptor1_hdr.icmp.seqNumber, acceptor1_hdr.icmp.valid, acceptor1_hdr.ipv4.diffserv, acceptor1_hdr.ipv4.dstAddr, acceptor1_hdr.ipv4.flags, acceptor1_hdr.ipv4.fragOffset, acceptor1_hdr.ipv4.hdrChecksum, acceptor1_hdr.ipv4.identification, acceptor1_hdr.ipv4.ihl, acceptor1_hdr.ipv4.protocol, acceptor1_hdr.ipv4.srcAddr, acceptor1_hdr.ipv4.totalLen, acceptor1_hdr.ipv4.ttl, acceptor1_hdr.ipv4.valid, acceptor1_hdr.ipv4.version, acceptor1_hdr.paxos.acptid, acceptor1_hdr.paxos.inst, acceptor1_hdr.paxos.msgtype, acceptor1_hdr.paxos.paxoslen, acceptor1_hdr.paxos.paxosval, acceptor1_hdr.paxos.rnd, acceptor1_hdr.paxos.valid, acceptor1_hdr.paxos.vrnd, acceptor1_hdr.udp.checksum, acceptor1_hdr.udp.dstPort, acceptor1_hdr.udp.length_, acceptor1_hdr.udp.srcPort, acceptor1_hdr.udp.valid, acceptor1_inbox_count, acceptor1_ingress_acceptor_tbl.action_run, acceptor1_ingress_acceptor_tbl.hit, acceptor1_ingress_arp_tbl.action_run, acceptor1_ingress_arp_tbl.hit, acceptor1_ingress_icmp_tbl.action_run, acceptor1_ingress_icmp_tbl.hit, acceptor1_ingress_learner_address__dbg0, acceptor1_ingress_learner_address__last0_old_value, acceptor1_ingress_learner_address__last0_old_value__dbg, acceptor1_ingress_learner_address__last0_value, acceptor1_ingress_learner_address__last0_value__dbg, acceptor1_ingress_learner_address__last_index, acceptor1_ingress_learner_address__last_index__dbg, acceptor1_ingress_learner_address__last_old_value, acceptor1_ingress_learner_address__last_old_value__dbg, acceptor1_ingress_learner_address__last_value, acceptor1_ingress_learner_address__last_value__dbg, acceptor1_ingress_learner_address__last_write_site, acceptor1_ingress_learner_address__next_write_site, acceptor1_ingress_learner_address__wrote_any, acceptor1_ingress_learner_address__wrote_any__dbg, acceptor1_ingress_learner_address__wrote_index0, acceptor1_ingress_learner_address__wrote_index0__dbg, acceptor1_ingress_learner_mac_address__dbg0, acceptor1_ingress_learner_mac_address__last0_old_value, acceptor1_ingress_learner_mac_address__last0_old_value__dbg, acceptor1_ingress_learner_mac_address__last0_value, acceptor1_ingress_learner_mac_address__last0_value__dbg, acceptor1_ingress_learner_mac_address__last_index, acceptor1_ingress_learner_mac_address__last_index__dbg, acceptor1_ingress_learner_mac_address__last_old_value, acceptor1_ingress_learner_mac_address__last_old_value__dbg, acceptor1_ingress_learner_mac_address__last_value, acceptor1_ingress_learner_mac_address__last_value__dbg, acceptor1_ingress_learner_mac_address__last_write_site, acceptor1_ingress_learner_mac_address__next_write_site, acceptor1_ingress_learner_mac_address__wrote_any, acceptor1_ingress_learner_mac_address__wrote_any__dbg, acceptor1_ingress_learner_mac_address__wrote_index0, acceptor1_ingress_learner_mac_address__wrote_index0__dbg, acceptor1_ingress_my_ip_address__dbg0, acceptor1_ingress_my_ip_address__last0_old_value, acceptor1_ingress_my_ip_address__last0_old_value__dbg, acceptor1_ingress_my_ip_address__last0_value, acceptor1_ingress_my_ip_address__last0_value__dbg, acceptor1_ingress_my_ip_address__last_index, acceptor1_ingress_my_ip_address__last_index__dbg, acceptor1_ingress_my_ip_address__last_old_value, acceptor1_ingress_my_ip_address__last_old_value__dbg, acceptor1_ingress_my_ip_address__last_value, acceptor1_ingress_my_ip_address__last_value__dbg, acceptor1_ingress_my_ip_address__last_write_site, acceptor1_ingress_my_ip_address__next_write_site, acceptor1_ingress_my_ip_address__wrote_any, acceptor1_ingress_my_ip_address__wrote_any__dbg, acceptor1_ingress_my_ip_address__wrote_index0, acceptor1_ingress_my_ip_address__wrote_index0__dbg, acceptor1_ingress_my_mac_address__dbg0, acceptor1_ingress_my_mac_address__last0_old_value, acceptor1_ingress_my_mac_address__last0_old_value__dbg, acceptor1_ingress_my_mac_address__last0_value, acceptor1_ingress_my_mac_address__last0_value__dbg, acceptor1_ingress_my_mac_address__last_index, acceptor1_ingress_my_mac_address__last_index__dbg, acceptor1_ingress_my_mac_address__last_old_value, acceptor1_ingress_my_mac_address__last_old_value__dbg, acceptor1_ingress_my_mac_address__last_value, acceptor1_ingress_my_mac_address__last_value__dbg, acceptor1_ingress_my_mac_address__last_write_site, acceptor1_ingress_my_mac_address__next_write_site, acceptor1_ingress_my_mac_address__wrote_any, acceptor1_ingress_my_mac_address__wrote_any__dbg, acceptor1_ingress_my_mac_address__wrote_index0, acceptor1_ingress_my_mac_address__wrote_index0__dbg, acceptor1_ingress_registerAcceptorID__dbg0, acceptor1_ingress_registerAcceptorID__last0_old_value, acceptor1_ingress_registerAcceptorID__last0_old_value__dbg, acceptor1_ingress_registerAcceptorID__last0_value, acceptor1_ingress_registerAcceptorID__last0_value__dbg, acceptor1_ingress_registerAcceptorID__last_index, acceptor1_ingress_registerAcceptorID__last_index__dbg, acceptor1_ingress_registerAcceptorID__last_old_value, acceptor1_ingress_registerAcceptorID__last_old_value__dbg, acceptor1_ingress_registerAcceptorID__last_value, acceptor1_ingress_registerAcceptorID__last_value__dbg, acceptor1_ingress_registerAcceptorID__last_write_site, acceptor1_ingress_registerAcceptorID__next_write_site, acceptor1_ingress_registerAcceptorID__wrote_any, acceptor1_ingress_registerAcceptorID__wrote_any__dbg, acceptor1_ingress_registerAcceptorID__wrote_index0, acceptor1_ingress_registerAcceptorID__wrote_index0__dbg, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__dbg0, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_old_value__dbg, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last0_value__dbg, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_index__dbg, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_old_value__dbg, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_value__dbg, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_any__dbg, acceptor1_ingress_registerRound__wrote_index0, acceptor1_ingress_registerRound__wrote_index0__dbg, acceptor1_ingress_registerVRound, acceptor1_ingress_registerVRound__dbg0, acceptor1_ingress_registerVRound__last0_old_value, acceptor1_ingress_registerVRound__last0_old_value__dbg, acceptor1_ingress_registerVRound__last0_value, acceptor1_ingress_registerVRound__last0_value__dbg, acceptor1_ingress_registerVRound__last_index, acceptor1_ingress_registerVRound__last_index__dbg, acceptor1_ingress_registerVRound__last_old_value, acceptor1_ingress_registerVRound__last_old_value__dbg, acceptor1_ingress_registerVRound__last_value, acceptor1_ingress_registerVRound__last_value__dbg, acceptor1_ingress_registerVRound__last_write_site, acceptor1_ingress_registerVRound__next_write_site, acceptor1_ingress_registerVRound__wrote_any, acceptor1_ingress_registerVRound__wrote_any__dbg, acceptor1_ingress_registerVRound__wrote_index0, acceptor1_ingress_registerVRound__wrote_index0__dbg, acceptor1_ingress_registerValue, acceptor1_ingress_registerValue__dbg0, acceptor1_ingress_registerValue__last0_old_value, acceptor1_ingress_registerValue__last0_old_value__dbg, acceptor1_ingress_registerValue__last0_value, acceptor1_ingress_registerValue__last0_value__dbg, acceptor1_ingress_registerValue__last_index, acceptor1_ingress_registerValue__last_index__dbg, acceptor1_ingress_registerValue__last_old_value, acceptor1_ingress_registerValue__last_old_value__dbg, acceptor1_ingress_registerValue__last_value, acceptor1_ingress_registerValue__last_value__dbg, acceptor1_ingress_registerValue__last_write_site, acceptor1_ingress_registerValue__next_write_site, acceptor1_ingress_registerValue__wrote_any, acceptor1_ingress_registerValue__wrote_any__dbg, acceptor1_ingress_registerValue__wrote_index0, acceptor1_ingress_registerValue__wrote_index0__dbg, acceptor1_ingress_transport_tbl.action_run, acceptor1_ingress_transport_tbl.hit, acceptor1_ipdst_0, acceptor1_isValid, acceptor1_meta.paxos_metadata, acceptor1_meta.paxos_metadata.ack_acceptors, acceptor1_meta.paxos_metadata.ack_count, acceptor1_meta.paxos_metadata.round, acceptor1_meta.paxos_metadata.set_drop, acceptor1_p4b_checksum_error, acceptor1_p4b_checksum_updated, acceptor1_p4b_checksum_verified, acceptor1_p4b_clone_e2e, acceptor1_p4b_clone_i2e, acceptor1_p4b_clone_i2i, acceptor1_p4b_digest, acceptor1_p4b_recirculate, acceptor1_pkt_external, acceptor1_standard_metadata.checksum_error, acceptor1_standard_metadata.deq_qdepth, acceptor1_standard_metadata.deq_timedelta, acceptor1_standard_metadata.egress_global_timestamp, acceptor1_standard_metadata.egress_port, acceptor1_standard_metadata.egress_rid, acceptor1_standard_metadata.egress_spec, acceptor1_standard_metadata.enq_qdepth, acceptor1_standard_metadata.enq_timestamp, acceptor1_standard_metadata.ingress_global_timestamp, acceptor1_standard_metadata.ingress_port, acceptor1_standard_metadata.instance_type, acceptor1_standard_metadata.mcast_grp, acceptor1_standard_metadata.packet_length, acceptor1_standard_metadata.parser_error, acceptor1_standard_metadata.priority, acceptor2_drop, acceptor2_egress_place_holder_table.hit, acceptor2_forward, acceptor2_hdr.arp.hln, acceptor2_hdr.arp.hrd, acceptor2_hdr.arp.op, acceptor2_hdr.arp.pln, acceptor2_hdr.arp.pro, acceptor2_hdr.arp.sha, acceptor2_hdr.arp.spa, acceptor2_hdr.arp.tha, acceptor2_hdr.arp.tpa, acceptor2_hdr.arp.valid, acceptor2_hdr.ethernet.dstAddr, acceptor2_hdr.ethernet.etherType, acceptor2_hdr.ethernet.srcAddr, acceptor2_hdr.ethernet.valid, acceptor2_hdr.icmp.hdrChecksum, acceptor2_hdr.icmp.icmpCode, acceptor2_hdr.icmp.icmpType, acceptor2_hdr.icmp.identifier, acceptor2_hdr.icmp.payload, acceptor2_hdr.icmp.seqNumber, acceptor2_hdr.icmp.valid, acceptor2_hdr.ipv4.diffserv, acceptor2_hdr.ipv4.dstAddr, acceptor2_hdr.ipv4.flags, acceptor2_hdr.ipv4.fragOffset, acceptor2_hdr.ipv4.hdrChecksum, acceptor2_hdr.ipv4.identification, acceptor2_hdr.ipv4.ihl, acceptor2_hdr.ipv4.protocol, acceptor2_hdr.ipv4.srcAddr, acceptor2_hdr.ipv4.totalLen, acceptor2_hdr.ipv4.ttl, acceptor2_hdr.ipv4.valid, acceptor2_hdr.ipv4.version, acceptor2_hdr.paxos.acptid, acceptor2_hdr.paxos.inst, acceptor2_hdr.paxos.msgtype, acceptor2_hdr.paxos.paxoslen, acceptor2_hdr.paxos.paxosval, acceptor2_hdr.paxos.rnd, acceptor2_hdr.paxos.valid, acceptor2_hdr.paxos.vrnd, acceptor2_hdr.udp.checksum, acceptor2_hdr.udp.dstPort, acceptor2_hdr.udp.length_, acceptor2_hdr.udp.srcPort, acceptor2_hdr.udp.valid, acceptor2_inbox_count, acceptor2_ingress_acceptor_tbl.action_run, acceptor2_ingress_acceptor_tbl.hit, acceptor2_ingress_arp_tbl.action_run, acceptor2_ingress_arp_tbl.hit, acceptor2_ingress_icmp_tbl.action_run, acceptor2_ingress_icmp_tbl.hit, acceptor2_ingress_learner_address__dbg0, acceptor2_ingress_learner_address__last0_old_value, acceptor2_ingress_learner_address__last0_old_value__dbg, acceptor2_ingress_learner_address__last0_value, acceptor2_ingress_learner_address__last0_value__dbg, acceptor2_ingress_learner_address__last_index, acceptor2_ingress_learner_address__last_index__dbg, acceptor2_ingress_learner_address__last_old_value, acceptor2_ingress_learner_address__last_old_value__dbg, acceptor2_ingress_learner_address__last_value, acceptor2_ingress_learner_address__last_value__dbg, acceptor2_ingress_learner_address__last_write_site, acceptor2_ingress_learner_address__next_write_site, acceptor2_ingress_learner_address__wrote_any, acceptor2_ingress_learner_address__wrote_any__dbg, acceptor2_ingress_learner_address__wrote_index0, acceptor2_ingress_learner_address__wrote_index0__dbg, acceptor2_ingress_learner_mac_address__dbg0, acceptor2_ingress_learner_mac_address__last0_old_value, acceptor2_ingress_learner_mac_address__last0_old_value__dbg, acceptor2_ingress_learner_mac_address__last0_value, acceptor2_ingress_learner_mac_address__last0_value__dbg, acceptor2_ingress_learner_mac_address__last_index, acceptor2_ingress_learner_mac_address__last_index__dbg, acceptor2_ingress_learner_mac_address__last_old_value, acceptor2_ingress_learner_mac_address__last_old_value__dbg, acceptor2_ingress_learner_mac_address__last_value, acceptor2_ingress_learner_mac_address__last_value__dbg, acceptor2_ingress_learner_mac_address__last_write_site, acceptor2_ingress_learner_mac_address__next_write_site, acceptor2_ingress_learner_mac_address__wrote_any, acceptor2_ingress_learner_mac_address__wrote_any__dbg, acceptor2_ingress_learner_mac_address__wrote_index0, acceptor2_ingress_learner_mac_address__wrote_index0__dbg, acceptor2_ingress_my_ip_address__dbg0, acceptor2_ingress_my_ip_address__last0_old_value, acceptor2_ingress_my_ip_address__last0_old_value__dbg, acceptor2_ingress_my_ip_address__last0_value, acceptor2_ingress_my_ip_address__last0_value__dbg, acceptor2_ingress_my_ip_address__last_index, acceptor2_ingress_my_ip_address__last_index__dbg, acceptor2_ingress_my_ip_address__last_old_value, acceptor2_ingress_my_ip_address__last_old_value__dbg, acceptor2_ingress_my_ip_address__last_value, acceptor2_ingress_my_ip_address__last_value__dbg, acceptor2_ingress_my_ip_address__last_write_site, acceptor2_ingress_my_ip_address__next_write_site, acceptor2_ingress_my_ip_address__wrote_any, acceptor2_ingress_my_ip_address__wrote_any__dbg, acceptor2_ingress_my_ip_address__wrote_index0, acceptor2_ingress_my_ip_address__wrote_index0__dbg, acceptor2_ingress_my_mac_address__dbg0, acceptor2_ingress_my_mac_address__last0_old_value, acceptor2_ingress_my_mac_address__last0_old_value__dbg, acceptor2_ingress_my_mac_address__last0_value, acceptor2_ingress_my_mac_address__last0_value__dbg, acceptor2_ingress_my_mac_address__last_index, acceptor2_ingress_my_mac_address__last_index__dbg, acceptor2_ingress_my_mac_address__last_old_value, acceptor2_ingress_my_mac_address__last_old_value__dbg, acceptor2_ingress_my_mac_address__last_value, acceptor2_ingress_my_mac_address__last_value__dbg, acceptor2_ingress_my_mac_address__last_write_site, acceptor2_ingress_my_mac_address__next_write_site, acceptor2_ingress_my_mac_address__wrote_any, acceptor2_ingress_my_mac_address__wrote_any__dbg, acceptor2_ingress_my_mac_address__wrote_index0, acceptor2_ingress_my_mac_address__wrote_index0__dbg, acceptor2_ingress_registerAcceptorID__dbg0, acceptor2_ingress_registerAcceptorID__last0_old_value, acceptor2_ingress_registerAcceptorID__last0_old_value__dbg, acceptor2_ingress_registerAcceptorID__last0_value, acceptor2_ingress_registerAcceptorID__last0_value__dbg, acceptor2_ingress_registerAcceptorID__last_index, acceptor2_ingress_registerAcceptorID__last_index__dbg, acceptor2_ingress_registerAcceptorID__last_old_value, acceptor2_ingress_registerAcceptorID__last_old_value__dbg, acceptor2_ingress_registerAcceptorID__last_value, acceptor2_ingress_registerAcceptorID__last_value__dbg, acceptor2_ingress_registerAcceptorID__last_write_site, acceptor2_ingress_registerAcceptorID__next_write_site, acceptor2_ingress_registerAcceptorID__wrote_any, acceptor2_ingress_registerAcceptorID__wrote_any__dbg, acceptor2_ingress_registerAcceptorID__wrote_index0, acceptor2_ingress_registerAcceptorID__wrote_index0__dbg, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__dbg0, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_old_value__dbg, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last0_value__dbg, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_index__dbg, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_old_value__dbg, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_value__dbg, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_any__dbg, acceptor2_ingress_registerRound__wrote_index0, acceptor2_ingress_registerRound__wrote_index0__dbg, acceptor2_ingress_registerVRound, acceptor2_ingress_registerVRound__dbg0, acceptor2_ingress_registerVRound__last0_old_value, acceptor2_ingress_registerVRound__last0_old_value__dbg, acceptor2_ingress_registerVRound__last0_value, acceptor2_ingress_registerVRound__last0_value__dbg, acceptor2_ingress_registerVRound__last_index, acceptor2_ingress_registerVRound__last_index__dbg, acceptor2_ingress_registerVRound__last_old_value, acceptor2_ingress_registerVRound__last_old_value__dbg, acceptor2_ingress_registerVRound__last_value, acceptor2_ingress_registerVRound__last_value__dbg, acceptor2_ingress_registerVRound__last_write_site, acceptor2_ingress_registerVRound__next_write_site, acceptor2_ingress_registerVRound__wrote_any, acceptor2_ingress_registerVRound__wrote_any__dbg, acceptor2_ingress_registerVRound__wrote_index0, acceptor2_ingress_registerVRound__wrote_index0__dbg, acceptor2_ingress_registerValue, acceptor2_ingress_registerValue__dbg0, acceptor2_ingress_registerValue__last0_old_value, acceptor2_ingress_registerValue__last0_old_value__dbg, acceptor2_ingress_registerValue__last0_value, acceptor2_ingress_registerValue__last0_value__dbg, acceptor2_ingress_registerValue__last_index, acceptor2_ingress_registerValue__last_index__dbg, acceptor2_ingress_registerValue__last_old_value, acceptor2_ingress_registerValue__last_old_value__dbg, acceptor2_ingress_registerValue__last_value, acceptor2_ingress_registerValue__last_value__dbg, acceptor2_ingress_registerValue__last_write_site, acceptor2_ingress_registerValue__next_write_site, acceptor2_ingress_registerValue__wrote_any, acceptor2_ingress_registerValue__wrote_any__dbg, acceptor2_ingress_registerValue__wrote_index0, acceptor2_ingress_registerValue__wrote_index0__dbg, acceptor2_ingress_transport_tbl.action_run, acceptor2_ingress_transport_tbl.hit, acceptor2_ipdst_0, acceptor2_isValid, acceptor2_meta.paxos_metadata, acceptor2_meta.paxos_metadata.ack_acceptors, acceptor2_meta.paxos_metadata.ack_count, acceptor2_meta.paxos_metadata.round, acceptor2_meta.paxos_metadata.set_drop, acceptor2_p4b_checksum_error, acceptor2_p4b_checksum_updated, acceptor2_p4b_checksum_verified, acceptor2_p4b_clone_e2e, acceptor2_p4b_clone_i2e, acceptor2_p4b_clone_i2i, acceptor2_p4b_digest, acceptor2_p4b_recirculate, acceptor2_pkt_external, acceptor2_standard_metadata.checksum_error, acceptor2_standard_metadata.deq_qdepth, acceptor2_standard_metadata.deq_timedelta, acceptor2_standard_metadata.egress_global_timestamp, acceptor2_standard_metadata.egress_port, acceptor2_standard_metadata.egress_rid, acceptor2_standard_metadata.egress_spec, acceptor2_standard_metadata.enq_qdepth, acceptor2_standard_metadata.enq_timestamp, acceptor2_standard_metadata.ingress_global_timestamp, acceptor2_standard_metadata.ingress_port, acceptor2_standard_metadata.instance_type, acceptor2_standard_metadata.mcast_grp, acceptor2_standard_metadata.packet_length, acceptor2_standard_metadata.parser_error, acceptor2_standard_metadata.priority, leader_current_instance_0, leader_drop, leader_egress_place_holder_table.hit, leader_forward, leader_hdr.arp.hln, leader_hdr.arp.hrd, leader_hdr.arp.op, leader_hdr.arp.pln, leader_hdr.arp.pro, leader_hdr.arp.sha, leader_hdr.arp.spa, leader_hdr.arp.tha, leader_hdr.arp.tpa, leader_hdr.arp.valid, leader_hdr.ethernet.dstAddr, leader_hdr.ethernet.etherType, leader_hdr.ethernet.srcAddr, leader_hdr.ethernet.valid, leader_hdr.icmp.hdrChecksum, leader_hdr.icmp.icmpCode, leader_hdr.icmp.icmpType, leader_hdr.icmp.identifier, leader_hdr.icmp.payload, leader_hdr.icmp.seqNumber, leader_hdr.icmp.valid, leader_hdr.ipv4.diffserv, leader_hdr.ipv4.dstAddr, leader_hdr.ipv4.flags, leader_hdr.ipv4.fragOffset, leader_hdr.ipv4.hdrChecksum, leader_hdr.ipv4.identification, leader_hdr.ipv4.ihl, leader_hdr.ipv4.protocol, leader_hdr.ipv4.srcAddr, leader_hdr.ipv4.totalLen, leader_hdr.ipv4.ttl, leader_hdr.ipv4.valid, leader_hdr.ipv4.version, leader_hdr.paxos.acptid, leader_hdr.paxos.inst, leader_hdr.paxos.msgtype, leader_hdr.paxos.paxoslen, leader_hdr.paxos.paxosval, leader_hdr.paxos.rnd, leader_hdr.paxos.valid, leader_hdr.paxos.vrnd, leader_hdr.udp.checksum, leader_hdr.udp.dstPort, leader_hdr.udp.length_, leader_hdr.udp.srcPort, leader_hdr.udp.valid, leader_inbox_count, leader_index_0, leader_index_1, leader_ingress_ctrlInstane, leader_ingress_ctrlInstane__dbg0, leader_ingress_ctrlInstane__last0_old_value, leader_ingress_ctrlInstane__last0_old_value__dbg, leader_ingress_ctrlInstane__last0_value, leader_ingress_ctrlInstane__last0_value__dbg, leader_ingress_ctrlInstane__last_index, leader_ingress_ctrlInstane__last_index__dbg, leader_ingress_ctrlInstane__last_old_value, leader_ingress_ctrlInstane__last_old_value__dbg, leader_ingress_ctrlInstane__last_value, leader_ingress_ctrlInstane__last_value__dbg, leader_ingress_ctrlInstane__last_write_site, leader_ingress_ctrlInstane__next_write_site, leader_ingress_ctrlInstane__wrote_any, leader_ingress_ctrlInstane__wrote_any__dbg, leader_ingress_ctrlInstane__wrote_index0, leader_ingress_ctrlInstane__wrote_index0__dbg, leader_ingress_leader_tbl.action_run, leader_ingress_leader_tbl.hit, leader_ingress_transport_tbl.action_run, leader_ingress_transport_tbl.hit, leader_isValid, leader_meta.paxos_metadata, leader_meta.paxos_metadata.ack_acceptors, leader_meta.paxos_metadata.ack_count, leader_meta.paxos_metadata.round, leader_meta.paxos_metadata.set_drop, leader_p4b_checksum_error, leader_p4b_checksum_updated, leader_p4b_checksum_verified, leader_p4b_clone_e2e, leader_p4b_clone_i2e, leader_p4b_clone_i2i, leader_p4b_digest, leader_p4b_recirculate, leader_pkt_external, leader_reset_value_0, leader_standard_metadata.checksum_error, leader_standard_metadata.deq_qdepth, leader_standard_metadata.deq_timedelta, leader_standard_metadata.egress_global_timestamp, leader_standard_metadata.egress_port, leader_standard_metadata.egress_rid, leader_standard_metadata.egress_spec, leader_standard_metadata.enq_qdepth, leader_standard_metadata.enq_timestamp, leader_standard_metadata.ingress_global_timestamp, leader_standard_metadata.ingress_port, leader_standard_metadata.instance_type, leader_standard_metadata.mcast_grp, leader_standard_metadata.packet_length, leader_standard_metadata.parser_error, leader_standard_metadata.priority, learner_acptid_0, learner_acptid_1, learner_drop, learner_egress_place_holder_table.hit, learner_forward, learner_hdr.arp.hln, learner_hdr.arp.hrd, learner_hdr.arp.op, learner_hdr.arp.pln, learner_hdr.arp.pro, learner_hdr.arp.sha, learner_hdr.arp.spa, learner_hdr.arp.tha, learner_hdr.arp.tpa, learner_hdr.arp.valid, learner_hdr.ethernet.dstAddr, learner_hdr.ethernet.etherType, learner_hdr.ethernet.srcAddr, learner_hdr.ethernet.valid, learner_hdr.icmp.hdrChecksum, learner_hdr.icmp.icmpCode, learner_hdr.icmp.icmpType, learner_hdr.icmp.identifier, learner_hdr.icmp.payload, learner_hdr.icmp.seqNumber, learner_hdr.icmp.valid, learner_hdr.ipv4.diffserv, learner_hdr.ipv4.dstAddr, learner_hdr.ipv4.flags, learner_hdr.ipv4.fragOffset, learner_hdr.ipv4.hdrChecksum, learner_hdr.ipv4.identification, learner_hdr.ipv4.ihl, learner_hdr.ipv4.protocol, learner_hdr.ipv4.srcAddr, learner_hdr.ipv4.totalLen, learner_hdr.ipv4.ttl, learner_hdr.ipv4.valid, learner_hdr.ipv4.version, learner_hdr.paxos.acptid, learner_hdr.paxos.inst, learner_hdr.paxos.msgtype, learner_hdr.paxos.paxoslen, learner_hdr.paxos.paxosval, learner_hdr.paxos.rnd, learner_hdr.paxos.valid, learner_hdr.paxos.vrnd, learner_hdr.udp.checksum, learner_hdr.udp.dstPort, learner_hdr.udp.length_, learner_hdr.udp.srcPort, learner_hdr.udp.valid, learner_inbox_count, learner_ingress_learner_tbl.action_run, learner_ingress_learner_tbl.hit, learner_ingress_registerHistory2B, learner_ingress_registerHistory2B__dbg0, learner_ingress_registerHistory2B__last0_old_value, learner_ingress_registerHistory2B__last0_old_value__dbg, learner_ingress_registerHistory2B__last0_value, learner_ingress_registerHistory2B__last0_value__dbg, learner_ingress_registerHistory2B__last_index, learner_ingress_registerHistory2B__last_index__dbg, learner_ingress_registerHistory2B__last_old_value, learner_ingress_registerHistory2B__last_old_value__dbg, learner_ingress_registerHistory2B__last_value, learner_ingress_registerHistory2B__last_value__dbg, learner_ingress_registerHistory2B__last_write_site, learner_ingress_registerHistory2B__next_write_site, learner_ingress_registerHistory2B__wrote_any, learner_ingress_registerHistory2B__wrote_any__dbg, learner_ingress_registerHistory2B__wrote_index0, learner_ingress_registerHistory2B__wrote_index0__dbg, learner_ingress_registerRound, learner_ingress_registerRound__dbg0, learner_ingress_registerRound__last0_old_value, learner_ingress_registerRound__last0_old_value__dbg, learner_ingress_registerRound__last0_value, learner_ingress_registerRound__last0_value__dbg, learner_ingress_registerRound__last_index, learner_ingress_registerRound__last_index__dbg, learner_ingress_registerRound__last_old_value, learner_ingress_registerRound__last_old_value__dbg, learner_ingress_registerRound__last_value, learner_ingress_registerRound__last_value__dbg, learner_ingress_registerRound__last_write_site, learner_ingress_registerRound__next_write_site, learner_ingress_registerRound__wrote_any, learner_ingress_registerRound__wrote_any__dbg, learner_ingress_registerRound__wrote_index0, learner_ingress_registerRound__wrote_index0__dbg, learner_ingress_registerValue, learner_ingress_registerValue__dbg0, learner_ingress_registerValue__last0_old_value, learner_ingress_registerValue__last0_old_value__dbg, learner_ingress_registerValue__last0_value, learner_ingress_registerValue__last0_value__dbg, learner_ingress_registerValue__last_index, learner_ingress_registerValue__last_index__dbg, learner_ingress_registerValue__last_old_value, learner_ingress_registerValue__last_old_value__dbg, learner_ingress_registerValue__last_value, learner_ingress_registerValue__last_value__dbg, learner_ingress_registerValue__last_write_site, learner_ingress_registerValue__next_write_site, learner_ingress_registerValue__wrote_any, learner_ingress_registerValue__wrote_any__dbg, learner_ingress_registerValue__wrote_index0, learner_ingress_registerValue__wrote_index0__dbg, learner_ingress_reset_consensus_instance.action_run, learner_ingress_reset_consensus_instance.hit, learner_ingress_transport_tbl.action_run, learner_ingress_transport_tbl.hit, learner_isValid, learner_meta.paxos_metadata, learner_meta.paxos_metadata.ack_acceptors, learner_meta.paxos_metadata.ack_count, learner_meta.paxos_metadata.round, learner_meta.paxos_metadata.set_drop, learner_p4b_checksum_error, learner_p4b_checksum_updated, learner_p4b_checksum_verified, learner_p4b_clone_e2e, learner_p4b_clone_i2e, learner_p4b_clone_i2i, learner_p4b_digest, learner_p4b_recirculate, learner_pkt_external, learner_standard_metadata.checksum_error, learner_standard_metadata.deq_qdepth, learner_standard_metadata.deq_timedelta, learner_standard_metadata.egress_global_timestamp, learner_standard_metadata.egress_port, learner_standard_metadata.egress_rid, learner_standard_metadata.egress_spec, learner_standard_metadata.enq_qdepth, learner_standard_metadata.enq_timestamp, learner_standard_metadata.ingress_global_timestamp, learner_standard_metadata.ingress_port, learner_standard_metadata.instance_type, learner_standard_metadata.mcast_grp, learner_standard_metadata.packet_length, learner_standard_metadata.parser_error, learner_standard_metadata.priority, procurator_step;
{
  call mainProcedure();
}

// ===== END HARNESS =====
