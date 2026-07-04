// ===== BEGIN PREAMBLE =====
function bvule.bv16(left:bv16, right:bv16) returns(bool);
function {:builtin "bvule"} bvule.bv16$builtin(left:bv16, right:bv16) returns(bool);
axiom (forall left:bv16, right:bv16 :: bvule.bv16(left, right) <==> bvule.bv16$builtin(left, right));
function bvule.bv32(left:bv32, right:bv32) returns(bool);
function {:builtin "bvule"} bvule.bv32$builtin(left:bv32, right:bv32) returns(bool);
axiom (forall left:bv32, right:bv32 :: bvule.bv32(left, right) <==> bvule.bv32$builtin(left, right));
// ===== END PREAMBLE =====

// ===== BEGIN NODE s1 (prefixed) =====
type s1_Ref;
type s1_error=bv1;
type s1_HeaderStack = [int]s1_Ref;
var s1_last:[s1_HeaderStack]s1_Ref;
var s1_forward:bool;
var s1_isValid:[s1_Ref]bool;
var s1_emit:[s1_Ref]bool;
var s1_stack.index:[s1_HeaderStack]int;
var s1_size:[s1_HeaderStack]int;
var s1_drop:bool;
var s1_p4b_clone_i2e:bool;
var s1_p4b_clone_e2e:bool;
var s1_p4b_clone_i2i:bool;
var s1_p4b_recirculate:bool;
var s1_p4b_digest:bool;
var s1_p4b_checksum_verified:bool;
var s1_p4b_checksum_updated:bool;
var s1_p4b_checksum_error:bool;

// s1_Struct s1_standard_metadata_t
type s1_standard_metadata_t;
var s1_standard_metadata.ingress_port:bv9;
var s1_standard_metadata.egress_spec:bv9;
var s1_standard_metadata.egress_port:bv9;
var s1_standard_metadata.instance_type:bv32;
var s1_standard_metadata.packet_length:bv32;
var s1_standard_metadata.enq_timestamp:bv32;
var s1_standard_metadata.enq_qdepth:bv19;
var s1_standard_metadata.deq_timedelta:bv32;
var s1_standard_metadata.deq_qdepth:bv19;
var s1_standard_metadata.ingress_global_timestamp:bv48;
var s1_standard_metadata.egress_global_timestamp:bv48;
var s1_standard_metadata.mcast_grp:bv16;
var s1_standard_metadata.egress_rid:bv16;
var s1_standard_metadata.checksum_error:bv1;
var s1_standard_metadata.parser_error:s1_error;
var s1_standard_metadata.priority:bv3;
type s1_CounterType = int;
type s1_MeterType = int;
type s1_HashAlgorithm = int;
type s1_CloneType = int;

// s1_Struct s1_location_t
type s1_location_t;

// s1_Struct s1_my_md_t
type s1_my_md_t;

// s1_Struct s1_reply_addr_t
type s1_reply_addr_t;

// s1_Struct s1_sequence_md_t
type s1_sequence_md_t;
type s1_ethernet_t;
type s1_ipv4_t;
type s1_nc_hdr_t;
type s1_tcp_t;
type s1_udp_t;
type s1_overlay_t;

// s1_Struct s1_metadata
type s1_metadata;
var s1_meta.location:s1_location_t;
var s1_meta.location.index:bv16;
var s1_meta.my_md:s1_my_md_t;
var s1_meta.my_md.ipaddress:bv32;
var s1_meta.my_md.role:bv16;
var s1_meta.my_md.failed:bv16;
var s1_meta.reply_to_client_md:s1_reply_addr_t;
var s1_meta.reply_to_client_md.ipv4_srcAddr:bv32;
var s1_meta.reply_to_client_md.ipv4_dstAddr:bv32;
var s1_meta.sequence_md:s1_sequence_md_t;
var s1_meta.sequence_md.seq:bv16;
var s1_meta.sequence_md.tmp:bv16;

// s1_Struct s1_headers
var s1_hdr:s1_Ref;

// s1_Header s1_ethernet_t
var s1_hdr.ethernet:s1_Ref;
var s1_hdr.ethernet.valid:bool;
var s1_hdr.ethernet.dstAddr:bv48;
var s1_hdr.ethernet.srcAddr:bv48;
var s1_hdr.ethernet.etherType:bv16;

// s1_Header s1_ipv4_t
var s1_hdr.ipv4:s1_Ref;
var s1_hdr.ipv4.valid:bool;
var s1_hdr.ipv4.version:bv4;
var s1_hdr.ipv4.ihl:bv4;
var s1_hdr.ipv4.diffserv:bv8;
var s1_hdr.ipv4.totalLen:bv16;
var s1_hdr.ipv4.identification:bv16;
var s1_hdr.ipv4.flags:bv3;
var s1_hdr.ipv4.fragOffset:bv13;
var s1_hdr.ipv4.ttl:bv8;
var s1_hdr.ipv4.protocol:bv8;
var s1_hdr.ipv4.hdrChecksum:bv16;
var s1_hdr.ipv4.srcAddr:bv32;
var s1_hdr.ipv4.dstAddr:bv32;

// s1_Header s1_nc_hdr_t
var s1_hdr.nc_hdr:s1_Ref;
var s1_hdr.nc_hdr.valid:bool;
var s1_hdr.nc_hdr.op:bv8;
var s1_hdr.nc_hdr.sc:bv8;
var s1_hdr.nc_hdr.seq:bv16;
var s1_hdr.nc_hdr.key:bv128;
var s1_hdr.nc_hdr.value:bv128;
var s1_hdr.nc_hdr.vgroup:bv16;

// s1_Header s1_tcp_t
var s1_hdr.tcp:s1_Ref;
var s1_hdr.tcp.valid:bool;
var s1_hdr.tcp.srcPort:bv16;
var s1_hdr.tcp.dstPort:bv16;
var s1_hdr.tcp.seqNo:bv32;
var s1_hdr.tcp.ackNo:bv32;
var s1_hdr.tcp.dataOffset:bv4;
var s1_hdr.tcp.res:bv3;
var s1_hdr.tcp.ecn:bv3;
var s1_hdr.tcp.ctrl:bv6;
var s1_hdr.tcp.window:bv16;
var s1_hdr.tcp.checksum:bv16;
var s1_hdr.tcp.urgentPtr:bv16;

// s1_Header s1_udp_t
var s1_hdr.udp:s1_Ref;
var s1_hdr.udp.valid:bool;
var s1_hdr.udp.srcPort:bv16;
var s1_hdr.udp.dstPort:bv16;
var s1_hdr.udp.len:bv16;
var s1_hdr.udp.checksum:bv16;
const s1_hdr.overlay:s1_HeaderStack;

// s1_Header s1_overlay_t
var s1_hdr.overlay.last:s1_Ref;
var s1_hdr.overlay.last.valid:bool;
var s1_hdr.overlay.last.swip:bv32;

// s1_Header s1_overlay_t
var s1_hdr.overlay.0:s1_Ref;
var s1_hdr.overlay.0.valid:bool;
var s1_hdr.overlay.0.swip:bv32;

// s1_Header s1_overlay_t
var s1_hdr.overlay.1:s1_Ref;
var s1_hdr.overlay.1.valid:bool;
var s1_hdr.overlay.1.swip:bv32;

// s1_Header s1_overlay_t
var s1_hdr.overlay.2:s1_Ref;
var s1_hdr.overlay.2.valid:bool;
var s1_hdr.overlay.2.swip:bv32;

// s1_Header s1_overlay_t
var s1_hdr.overlay.3:s1_Ref;
var s1_hdr.overlay.3.valid:bool;
var s1_hdr.overlay.3.swip:bv32;

// s1_Header s1_overlay_t
var s1_hdr.overlay.4:s1_Ref;
var s1_hdr.overlay.4.valid:bool;
var s1_hdr.overlay.4.swip:bv32;

// s1_Header s1_overlay_t
var s1_hdr.overlay.5:s1_Ref;
var s1_hdr.overlay.5.valid:bool;
var s1_hdr.overlay.5.swip:bv32;

// s1_Header s1_overlay_t
var s1_hdr.overlay.6:s1_Ref;
var s1_hdr.overlay.6.valid:bool;
var s1_hdr.overlay.6.swip:bv32;

// s1_Header s1_overlay_t
var s1_hdr.overlay.7:s1_Ref;
var s1_hdr.overlay.7.valid:bool;
var s1_hdr.overlay.7.swip:bv32;

// s1_Header s1_overlay_t
var s1_hdr.overlay.8:s1_Ref;
var s1_hdr.overlay.8.valid:bool;
var s1_hdr.overlay.8.swip:bv32;

// s1_Header s1_overlay_t
var s1_hdr.overlay.9:s1_Ref;
var s1_hdr.overlay.9.valid:bool;
var s1_hdr.overlay.9.swip:bv32;
var s1_meta:s1_metadata;
var s1_standard_metadata:s1_standard_metadata_t;

// s1_Table s1_ethernet_set_mac s1_Actionlist s1_Declaration
type s1_ethernet_set_mac.action;
var s1_ethernet_set_mac.ethernet_set_mac_act.smac:bv48;
var s1_ethernet_set_mac.ethernet_set_mac_act.dmac:bv48;
const unique s1_ethernet_set_mac.action.ethernet_set_mac_act : s1_ethernet_set_mac.action;
const unique s1_ethernet_set_mac.action.NoAction : s1_ethernet_set_mac.action;
var s1_ethernet_set_mac.action_run : s1_ethernet_set_mac.action;
var s1_ethernet_set_mac.hit : bool;

// s1_Register s1_sequence_reg
var s1_sequence_reg:[bv32]bv16;
var s1_sequence_reg__last_index:bv32;
var s1_sequence_reg__last_value:bv16;
var s1_sequence_reg__last_old_value:bv16;
var s1_sequence_reg__wrote_any:bool;
var s1_sequence_reg__wrote_index0:bool;
var s1_sequence_reg__last0_old_value:bv16;
var s1_sequence_reg__last0_value:bv16;
var s1_sequence_reg__next_write_site:int;
var s1_sequence_reg__last_write_site:int;
const s1_sequence_reg.size:bv32;
axiom s1_sequence_reg.size == 4096bv32;

// s1_Register s1_value_reg
var s1_value_reg:[bv32]bv128;
var s1_value_reg__last_index:bv32;
var s1_value_reg__last_value:bv128;
var s1_value_reg__last_old_value:bv128;
var s1_value_reg__wrote_any:bool;
var s1_value_reg__wrote_index0:bool;
var s1_value_reg__last0_old_value:bv128;
var s1_value_reg__last0_value:bv128;
var s1_value_reg__next_write_site:int;
var s1_value_reg__last_write_site:int;
const s1_value_reg.size:bv32;
axiom s1_value_reg.size == 4096bv32;

function {:builtin "bvadd"} add.bv8(s1_left:bv8, s1_right:bv8) returns(bv8);

function {:builtin "bvadd"} add.bv16(s1_left:bv16, s1_right:bv16) returns(bv16);

// s1_Table s1_assign_value s1_Actionlist s1_Declaration
type s1_assign_value.action;
const unique s1_assign_value.action.assign_value_act : s1_assign_value.action;
const unique s1_assign_value.action.NoAction_3 : s1_assign_value.action;
var s1_assign_value.action_run : s1_assign_value.action;
var s1_assign_value.hit : bool;

// s1_Table s1_drop_packet s1_Actionlist s1_Declaration
type s1_drop_packet.action;
const unique s1_drop_packet.action.drop_packet_act : s1_drop_packet.action;
const unique s1_drop_packet.action.NoAction_4 : s1_drop_packet.action;
var s1_drop_packet.action_run : s1_drop_packet.action;
var s1_drop_packet.hit : bool;

// s1_Table s1_failure_recovery s1_Actionlist s1_Declaration
type s1_failure_recovery.action;
var s1_failure_recovery.failure_recovery_act.nexthop:bv32;
const unique s1_failure_recovery.action.failover_act : s1_failure_recovery.action;
const unique s1_failure_recovery.action.failover_write_reply_act : s1_failure_recovery.action;
const unique s1_failure_recovery.action.failure_recovery_act : s1_failure_recovery.action;
const unique s1_failure_recovery.action.nop : s1_failure_recovery.action;
const unique s1_failure_recovery.action.drop_packet_act : s1_failure_recovery.action;
const unique s1_failure_recovery.action.NoAction_5 : s1_failure_recovery.action;
var s1_failure_recovery.action_run : s1_failure_recovery.action;
var s1_failure_recovery.hit : bool;

// s1_Table s1_find_index s1_Actionlist s1_Declaration
type s1_find_index.action;
var s1_find_index.find_index_act.index_1:bv16;
const unique s1_find_index.action.find_index_act : s1_find_index.action;
const unique s1_find_index.action.NoAction_6 : s1_find_index.action;
var s1_find_index.action_run : s1_find_index.action;
var s1_find_index.hit : bool;

// s1_Table s1_gen_reply s1_Actionlist s1_Declaration
type s1_gen_reply.action;
var s1_gen_reply.gen_reply_act.message_type:bv8;
const unique s1_gen_reply.action.gen_reply_act : s1_gen_reply.action;
const unique s1_gen_reply.action.NoAction_7 : s1_gen_reply.action;
var s1_gen_reply.action_run : s1_gen_reply.action;
var s1_gen_reply.hit : bool;

// s1_Table s1_get_my_address s1_Actionlist s1_Declaration
type s1_get_my_address.action;
var s1_get_my_address.get_my_address_act.sw_ip:bv32;
var s1_get_my_address.get_my_address_act.sw_role:bv16;
const unique s1_get_my_address.action.get_my_address_act : s1_get_my_address.action;
const unique s1_get_my_address.action.NoAction_8 : s1_get_my_address.action;
var s1_get_my_address.action_run : s1_get_my_address.action;
var s1_get_my_address.hit : bool;

// s1_Table s1_get_next_hop s1_Actionlist s1_Declaration
type s1_get_next_hop.action;
const unique s1_get_next_hop.action.get_next_hop_act : s1_get_next_hop.action;
const unique s1_get_next_hop.action.NoAction_9 : s1_get_next_hop.action;
var s1_get_next_hop.action_run : s1_get_next_hop.action;
var s1_get_next_hop.hit : bool;

// s1_Table s1_get_sequence s1_Actionlist s1_Declaration
type s1_get_sequence.action;
const unique s1_get_sequence.action.get_sequence_act : s1_get_sequence.action;
const unique s1_get_sequence.action.NoAction_10 : s1_get_sequence.action;
var s1_get_sequence.action_run : s1_get_sequence.action;
var s1_get_sequence.hit : bool;

// s1_Table s1_ipv4_route s1_Actionlist s1_Declaration
type s1_ipv4_route.action;
var s1_ipv4_route.set_egress.egress_spec_1:bv9;
const unique s1_ipv4_route.action.set_egress : s1_ipv4_route.action;
const unique s1_ipv4_route.action.NoAction_11 : s1_ipv4_route.action;
var s1_ipv4_route.action_run : s1_ipv4_route.action;
var s1_ipv4_route.hit : bool;

// s1_Table s1_maintain_sequence s1_Actionlist s1_Declaration
type s1_maintain_sequence.action;
const unique s1_maintain_sequence.action.maintain_sequence_act : s1_maintain_sequence.action;
const unique s1_maintain_sequence.action.NoAction_12 : s1_maintain_sequence.action;
var s1_maintain_sequence.action_run : s1_maintain_sequence.action;
var s1_maintain_sequence.hit : bool;

// s1_Table s1_pop_chain s1_Actionlist s1_Declaration
type s1_pop_chain.action;
const unique s1_pop_chain.action.pop_chain_act : s1_pop_chain.action;
const unique s1_pop_chain.action.NoAction_13 : s1_pop_chain.action;
var s1_pop_chain.action_run : s1_pop_chain.action;
var s1_pop_chain.hit : bool;

// s1_Table s1_pop_chain_again s1_Actionlist s1_Declaration
type s1_pop_chain_again.action;
const unique s1_pop_chain_again.action.pop_chain_act : s1_pop_chain_again.action;
const unique s1_pop_chain_again.action.NoAction_14 : s1_pop_chain_again.action;
var s1_pop_chain_again.action_run : s1_pop_chain_again.action;
var s1_pop_chain_again.hit : bool;

// s1_Table s1_read_value s1_Actionlist s1_Declaration
type s1_read_value.action;
const unique s1_read_value.action.read_value_act : s1_read_value.action;
const unique s1_read_value.action.NoAction_15 : s1_read_value.action;
var s1_read_value.action_run : s1_read_value.action;
var s1_read_value.hit : bool;

function {:builtin "bvugt"} bugt.bv16(s1_left:bv16, s1_right:bv16) returns(bool);

function {:builtin "bvsub"} sub.bv17(s1_left:bv17, s1_right:bv17) returns(bv17);

function {:builtin "bvsub"} sub.bv33(s1_left:bv33, s1_right:bv33) returns(bv33);

// s1_Action s1_NoAction
procedure {:inline 1} s1_NoAction()
{
}

// s1_Action s1_NoAction_10
procedure {:inline 1} s1_NoAction_10()
{
}

// s1_Action s1_NoAction_11
procedure {:inline 1} s1_NoAction_11()
{
}

// s1_Action s1_NoAction_12
procedure {:inline 1} s1_NoAction_12()
{
}

// s1_Action s1_NoAction_13
procedure {:inline 1} s1_NoAction_13()
{
}

// s1_Action s1_NoAction_14
procedure {:inline 1} s1_NoAction_14()
{
}

// s1_Action s1_NoAction_15
procedure {:inline 1} s1_NoAction_15()
{
}

// s1_Action s1_NoAction_3
procedure {:inline 1} s1_NoAction_3()
{
}

// s1_Action s1_NoAction_4
procedure {:inline 1} s1_NoAction_4()
{
}

// s1_Action s1_NoAction_5
procedure {:inline 1} s1_NoAction_5()
{
}

// s1_Action s1_NoAction_6
procedure {:inline 1} s1_NoAction_6()
{
}

// s1_Action s1_NoAction_7
procedure {:inline 1} s1_NoAction_7()
{
}

// s1_Action s1_NoAction_8
procedure {:inline 1} s1_NoAction_8()
{
}

// s1_Action s1_NoAction_9
procedure {:inline 1} s1_NoAction_9()
{
}

// s1_Parser s1_ParserImpl
procedure {:inline 1} s1_ParserImpl()
	modifies s1_drop, s1_hdr.ipv4.protocol, s1_hdr.udp.dstPort, s1_isValid, s1_stack.index;
{
    goto s1_State$ParserImpl$start;

        s1_State$ParserImpl$start:
    goto s1_State$ParserImpl$parse_ethernet;

        s1_State$ParserImpl$parse_ethernet:
    call s1_packet_in.extract(s1_hdr.ethernet);
    goto s1_State$ParserImpl$parse_ethernet$parse_ipv4_2, s1_State$ParserImpl$parse_ethernet$DEFAULT;
    
s1_State$ParserImpl$parse_ethernet$parse_ipv4_2:
    assume (s1_hdr.ethernet.etherType == 2048bv16);
    goto s1_State$ParserImpl$parse_ipv4;

    s1_State$ParserImpl$parse_ethernet$DEFAULT:
    assume(!(s1_hdr.ethernet.etherType == 2048bv16));
    goto s1_State$accept;

        s1_State$ParserImpl$parse_ipv4:
    call s1_packet_in.extract(s1_hdr.ipv4);
    s1_hdr.ipv4.protocol := 17bv8;
    goto s1_State$ParserImpl$parse_ipv4$parse_tcp_3, s1_State$ParserImpl$parse_ipv4$parse_udp_2, s1_State$ParserImpl$parse_ipv4$DEFAULT;
    
s1_State$ParserImpl$parse_ipv4$parse_tcp_3:
    assume (s1_hdr.ipv4.protocol == 6bv8);
    goto s1_State$ParserImpl$parse_tcp;
    
s1_State$ParserImpl$parse_ipv4$parse_udp_2:
    assume (s1_hdr.ipv4.protocol == 17bv8);
    goto s1_State$ParserImpl$parse_udp;

    s1_State$ParserImpl$parse_ipv4$DEFAULT:
    assume(!(s1_hdr.ipv4.protocol == 6bv8)&&!(s1_hdr.ipv4.protocol == 17bv8));
    goto s1_State$accept;

        s1_State$ParserImpl$parse_nc_hdr:
    call s1_packet_in.extract(s1_hdr.nc_hdr);
    goto s1_State$ParserImpl$parse_nc_hdr$accept_3, s1_State$ParserImpl$parse_nc_hdr$accept_2, s1_State$ParserImpl$parse_nc_hdr$DEFAULT;
    
s1_State$ParserImpl$parse_nc_hdr$accept_3:
    assume (s1_hdr.nc_hdr.op == 10bv8);
    goto s1_State$accept;
    
s1_State$ParserImpl$parse_nc_hdr$accept_2:
    assume (s1_hdr.nc_hdr.op == 12bv8);
    goto s1_State$accept;

    s1_State$ParserImpl$parse_nc_hdr$DEFAULT:
    assume(!(s1_hdr.nc_hdr.op == 10bv8)&&!(s1_hdr.nc_hdr.op == 12bv8));
    goto s1_State$accept;

        s1_State$ParserImpl$parse_overlay:
    call s1_packet_in.extract.headers.overlay.next(s1_hdr.overlay);
    goto s1_State$ParserImpl$parse_overlay$parse_nc_hdr_2, s1_State$ParserImpl$parse_overlay$DEFAULT;
    
s1_State$ParserImpl$parse_overlay$parse_nc_hdr_2:
    assume (s1_hdr.overlay.last.swip == 0bv32);
    goto s1_State$ParserImpl$parse_nc_hdr;

    s1_State$ParserImpl$parse_overlay$DEFAULT:
    assume(!(s1_hdr.overlay.last.swip == 0bv32));
    goto s1_State$ParserImpl$parse_overlay;

        s1_State$ParserImpl$parse_tcp:
    call s1_packet_in.extract(s1_hdr.tcp);
    goto s1_State$accept;

        s1_State$ParserImpl$parse_udp:
    call s1_packet_in.extract(s1_hdr.udp);
    s1_hdr.udp.dstPort := 8888bv16;
    goto s1_State$ParserImpl$parse_udp$parse_overlay_3, s1_State$ParserImpl$parse_udp$parse_overlay_2, s1_State$ParserImpl$parse_udp$DEFAULT;
    
s1_State$ParserImpl$parse_udp$parse_overlay_3:
    assume (s1_hdr.udp.dstPort == 8888bv16);
    goto s1_State$ParserImpl$parse_overlay;
    
s1_State$ParserImpl$parse_udp$parse_overlay_2:
    assume (s1_hdr.udp.dstPort == 8889bv16);
    goto s1_State$ParserImpl$parse_overlay;

    s1_State$ParserImpl$parse_udp$DEFAULT:
    assume(!(s1_hdr.udp.dstPort == 8888bv16)&&!(s1_hdr.udp.dstPort == 8889bv16));
    goto s1_State$accept;

    s1_State$accept:
    call s1_accept();
    goto s1_Exit;

    s1_State$reject:
    call s1_reject();
    goto s1_Exit;

    s1_Exit:
}
procedure {:inline 1} s1_accept()
{
}

// s1_Table s1_assign_value
procedure {:inline 1} s1_assign_value.apply()
	modifies s1_assign_value.action_run, s1_assign_value.hit, s1_sequence_reg, s1_sequence_reg__last0_old_value, s1_sequence_reg__last0_value, s1_sequence_reg__last_index, s1_sequence_reg__last_old_value, s1_sequence_reg__last_value, s1_sequence_reg__last_write_site, s1_sequence_reg__next_write_site, s1_sequence_reg__wrote_any, s1_sequence_reg__wrote_index0, s1_value_reg, s1_value_reg__last0_old_value, s1_value_reg__last0_value, s1_value_reg__last_index, s1_value_reg__last_old_value, s1_value_reg__last_value, s1_value_reg__last_write_site, s1_value_reg__next_write_site, s1_value_reg__wrote_any, s1_value_reg__wrote_index0;
{
    s1_assign_value.hit := false;
    s1_assign_value.action_run := s1_assign_value.action.assign_value_act;
    call s1_assign_value_act();
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_assign_value_act
procedure {:inline 1} s1_assign_value_act()
	modifies s1_sequence_reg, s1_sequence_reg__last0_old_value, s1_sequence_reg__last0_value, s1_sequence_reg__last_index, s1_sequence_reg__last_old_value, s1_sequence_reg__last_value, s1_sequence_reg__last_write_site, s1_sequence_reg__next_write_site, s1_sequence_reg__wrote_any, s1_sequence_reg__wrote_index0, s1_value_reg, s1_value_reg__last0_old_value, s1_value_reg__last0_value, s1_value_reg__last_index, s1_value_reg__last_old_value, s1_value_reg__last_value, s1_value_reg__last_write_site, s1_value_reg__next_write_site, s1_value_reg__wrote_any, s1_value_reg__wrote_index0;
{
    // s1_write
    s1_sequence_reg__next_write_site := 1;
    call s1_sequence_reg.write(0bv16++s1_meta.location.index, s1_hdr.nc_hdr.seq);
    // s1_write
    s1_value_reg__next_write_site := 1;
    call s1_value_reg.write(0bv16++s1_meta.location.index, s1_hdr.nc_hdr.value);
}

// s1_Control s1_computeChecksum
procedure {:inline 1} s1_computeChecksum()
	modifies s1_hdr.ipv4.hdrChecksum, s1_hdr.udp.checksum, s1_p4b_checksum_updated;
{
    if (true) {
        s1_p4b_checksum_updated := true;
        havoc s1_hdr.ipv4.hdrChecksum;
    }
    if (true) {
        s1_p4b_checksum_updated := true;
        havoc s1_hdr.udp.checksum;
    }
}

// s1_Table s1_drop_packet
procedure {:inline 1} s1_drop_packet.apply()
	modifies s1_drop, s1_drop_packet.action_run, s1_drop_packet.hit;
{
    s1_drop_packet.hit := false;
    s1_drop_packet.action_run := s1_drop_packet.action.drop_packet_act;
    call s1_drop_packet_act();
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_drop_packet_act
procedure {:inline 1} s1_drop_packet_act()
	modifies s1_drop;
{
    call s1_mark_to_drop();
}

// s1_Control s1_egress
procedure {:inline 1} s1_egress()
	modifies s1_ethernet_set_mac.action_run, s1_ethernet_set_mac.ethernet_set_mac_act.dmac, s1_ethernet_set_mac.ethernet_set_mac_act.smac, s1_ethernet_set_mac.hit, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.srcAddr, s1_standard_metadata.egress_port;
{
    call s1_ethernet_set_mac.apply();
}

// s1_Table s1_ethernet_set_mac
procedure {:inline 1} s1_ethernet_set_mac.apply()
	modifies s1_ethernet_set_mac.action_run, s1_ethernet_set_mac.ethernet_set_mac_act.dmac, s1_ethernet_set_mac.ethernet_set_mac_act.smac, s1_ethernet_set_mac.hit, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.srcAddr, s1_standard_metadata.egress_port;
{
    s1_standard_metadata.egress_port := s1_standard_metadata.egress_port;
    s1_ethernet_set_mac.hit := false;
    if(s1_standard_metadata.egress_port == 1bv9){
        s1_ethernet_set_mac.hit := true;
        s1_ethernet_set_mac.action_run := s1_ethernet_set_mac.action.ethernet_set_mac_act;
        s1_ethernet_set_mac.ethernet_set_mac_act.smac := 187723572702737bv48;
        s1_ethernet_set_mac.ethernet_set_mac_act.dmac := 187723572702787bv48;
        call s1_ethernet_set_mac_act(s1_ethernet_set_mac.ethernet_set_mac_act.smac, s1_ethernet_set_mac.ethernet_set_mac_act.dmac);
        goto s1_Exit;
    }
    else if(s1_standard_metadata.egress_port == 2bv9){
        s1_ethernet_set_mac.hit := true;
        s1_ethernet_set_mac.action_run := s1_ethernet_set_mac.action.ethernet_set_mac_act;
        s1_ethernet_set_mac.ethernet_set_mac_act.smac := 187723572702738bv48;
        s1_ethernet_set_mac.ethernet_set_mac_act.dmac := 187723572702754bv48;
        call s1_ethernet_set_mac_act(s1_ethernet_set_mac.ethernet_set_mac_act.smac, s1_ethernet_set_mac.ethernet_set_mac_act.dmac);
        goto s1_Exit;
    }
    if(!s1_ethernet_set_mac.hit){
        s1_ethernet_set_mac.action_run := s1_ethernet_set_mac.action.NoAction;
        call s1_NoAction();
        goto s1_Exit;
    }

    s1_Exit:
}

// s1_Action s1_ethernet_set_mac_act
procedure {:inline 1} s1_ethernet_set_mac_act(s1_smac:bv48, s1_dmac:bv48)
	modifies s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.srcAddr;
{
    s1_hdr.ethernet.srcAddr := s1_smac;
    s1_hdr.ethernet.dstAddr := s1_dmac;
}

// s1_Action s1_failover_act
procedure {:inline 1} s1_failover_act()
	modifies s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.totalLen, s1_hdr.nc_hdr.sc, s1_hdr.overlay.0.swip, s1_hdr.overlay.0.valid, s1_hdr.overlay.1.swip, s1_hdr.overlay.1.valid, s1_hdr.overlay.2.swip, s1_hdr.overlay.2.valid, s1_hdr.overlay.3.swip, s1_hdr.overlay.3.valid, s1_hdr.overlay.4.swip, s1_hdr.overlay.4.valid, s1_hdr.overlay.5.swip, s1_hdr.overlay.5.valid, s1_hdr.overlay.6.swip, s1_hdr.overlay.6.valid, s1_hdr.overlay.7.swip, s1_hdr.overlay.7.valid, s1_hdr.overlay.8.swip, s1_hdr.overlay.8.valid, s1_hdr.overlay.9.valid, s1_hdr.udp.len, s1_isValid;
{
    s1_hdr.ipv4.dstAddr := s1_hdr.overlay.1.swip;
    s1_hdr.nc_hdr.sc := add.bv8(s1_hdr.nc_hdr.sc, 255bv8);
    // s1_pop_front
    s1_hdr.overlay.0.swip := s1_hdr.overlay.1.swip;
    s1_hdr.overlay.0.valid := s1_hdr.overlay.1.valid;
    s1_isValid[s1_hdr.overlay.0] := s1_isValid[s1_hdr.overlay.1];
    s1_hdr.overlay.1.swip := s1_hdr.overlay.2.swip;
    s1_hdr.overlay.1.valid := s1_hdr.overlay.2.valid;
    s1_isValid[s1_hdr.overlay.1] := s1_isValid[s1_hdr.overlay.2];
    s1_hdr.overlay.2.swip := s1_hdr.overlay.3.swip;
    s1_hdr.overlay.2.valid := s1_hdr.overlay.3.valid;
    s1_isValid[s1_hdr.overlay.2] := s1_isValid[s1_hdr.overlay.3];
    s1_hdr.overlay.3.swip := s1_hdr.overlay.4.swip;
    s1_hdr.overlay.3.valid := s1_hdr.overlay.4.valid;
    s1_isValid[s1_hdr.overlay.3] := s1_isValid[s1_hdr.overlay.4];
    s1_hdr.overlay.4.swip := s1_hdr.overlay.5.swip;
    s1_hdr.overlay.4.valid := s1_hdr.overlay.5.valid;
    s1_isValid[s1_hdr.overlay.4] := s1_isValid[s1_hdr.overlay.5];
    s1_hdr.overlay.5.swip := s1_hdr.overlay.6.swip;
    s1_hdr.overlay.5.valid := s1_hdr.overlay.6.valid;
    s1_isValid[s1_hdr.overlay.5] := s1_isValid[s1_hdr.overlay.6];
    s1_hdr.overlay.6.swip := s1_hdr.overlay.7.swip;
    s1_hdr.overlay.6.valid := s1_hdr.overlay.7.valid;
    s1_isValid[s1_hdr.overlay.6] := s1_isValid[s1_hdr.overlay.7];
    s1_hdr.overlay.7.swip := s1_hdr.overlay.8.swip;
    s1_hdr.overlay.7.valid := s1_hdr.overlay.8.valid;
    s1_isValid[s1_hdr.overlay.7] := s1_isValid[s1_hdr.overlay.8];
    s1_hdr.overlay.8.swip := s1_hdr.overlay.9.swip;
    s1_hdr.overlay.8.valid := s1_hdr.overlay.9.valid;
    s1_isValid[s1_hdr.overlay.8] := s1_isValid[s1_hdr.overlay.9];
    s1_hdr.overlay.9.valid := false;
    s1_isValid[s1_hdr.overlay.9] := false;
    s1_hdr.udp.len := add.bv16(s1_hdr.udp.len, 65532bv16);
    s1_hdr.ipv4.totalLen := add.bv16(s1_hdr.ipv4.totalLen, 65532bv16);
}

// s1_Action s1_failover_write_reply_act
procedure {:inline 1} s1_failover_write_reply_act()
	modifies s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.srcAddr, s1_hdr.nc_hdr.op, s1_hdr.udp.dstPort, s1_meta.reply_to_client_md.ipv4_dstAddr, s1_meta.reply_to_client_md.ipv4_srcAddr;
{
    s1_meta.reply_to_client_md.ipv4_srcAddr := s1_hdr.ipv4.dstAddr;
    s1_meta.reply_to_client_md.ipv4_dstAddr := s1_hdr.ipv4.srcAddr;
    s1_hdr.ipv4.srcAddr := s1_meta.reply_to_client_md.ipv4_srcAddr;
    s1_hdr.ipv4.dstAddr := s1_meta.reply_to_client_md.ipv4_dstAddr;
    s1_hdr.nc_hdr.op := 13bv8;
    s1_hdr.udp.dstPort := 8889bv16;
}

// s1_Table s1_failure_recovery
procedure {:inline 1} s1_failure_recovery.apply()
	modifies s1_failure_recovery.action_run, s1_failure_recovery.hit, s1_hdr.ipv4.dstAddr, s1_hdr.nc_hdr.vgroup, s1_hdr.overlay.1.swip;
{
    s1_hdr.ipv4.dstAddr := s1_hdr.ipv4.dstAddr;
    s1_hdr.overlay.1.swip := s1_hdr.overlay.1.swip;
    s1_hdr.nc_hdr.vgroup := s1_hdr.nc_hdr.vgroup;
    s1_failure_recovery.hit := false;
    s1_failure_recovery.action_run := s1_failure_recovery.action.nop;
    call s1_nop();
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_failure_recovery_act
procedure {:inline 1} s1_failure_recovery_act(s1_nexthop:bv32)
	modifies s1_hdr.ipv4.dstAddr, s1_hdr.overlay.0.swip;
{
    s1_hdr.overlay.0.swip := s1_nexthop;
    s1_hdr.ipv4.dstAddr := s1_nexthop;
}

// s1_Table s1_find_index
procedure {:inline 1} s1_find_index.apply()
	modifies s1_find_index.action_run, s1_find_index.find_index_act.index_1, s1_find_index.hit, s1_hdr.nc_hdr.key, s1_meta.location.index;
{
    s1_hdr.nc_hdr.key := s1_hdr.nc_hdr.key;
    s1_find_index.hit := false;
    if(s1_hdr.nc_hdr.key == 2024bv128){
        s1_find_index.hit := true;
        s1_find_index.action_run := s1_find_index.action.find_index_act;
        s1_find_index.find_index_act.index_1 := 0bv16;
        call s1_find_index_act(s1_find_index.find_index_act.index_1);
        goto s1_Exit;
    }
    else if(s1_hdr.nc_hdr.key == 2025bv128){
        s1_find_index.hit := true;
        s1_find_index.action_run := s1_find_index.action.find_index_act;
        s1_find_index.find_index_act.index_1 := 1bv16;
        call s1_find_index_act(s1_find_index.find_index_act.index_1);
        goto s1_Exit;
    }
    else if(s1_hdr.nc_hdr.key == 2026bv128){
        s1_find_index.hit := true;
        s1_find_index.action_run := s1_find_index.action.find_index_act;
        s1_find_index.find_index_act.index_1 := 2bv16;
        call s1_find_index_act(s1_find_index.find_index_act.index_1);
        goto s1_Exit;
    }
    else if(s1_hdr.nc_hdr.key == 2027bv128){
        s1_find_index.hit := true;
        s1_find_index.action_run := s1_find_index.action.find_index_act;
        s1_find_index.find_index_act.index_1 := 3bv16;
        call s1_find_index_act(s1_find_index.find_index_act.index_1);
        goto s1_Exit;
    }
    else if(s1_hdr.nc_hdr.key == 2028bv128){
        s1_find_index.hit := true;
        s1_find_index.action_run := s1_find_index.action.find_index_act;
        s1_find_index.find_index_act.index_1 := 4bv16;
        call s1_find_index_act(s1_find_index.find_index_act.index_1);
        goto s1_Exit;
    }
    if(!s1_find_index.hit){
        s1_find_index.action_run := s1_find_index.action.NoAction_6;
        call s1_NoAction_6();
        goto s1_Exit;
    }

    s1_Exit:
}

// s1_Action s1_find_index_act
procedure {:inline 1} s1_find_index_act(s1_index_1:bv16)
	modifies s1_meta.location.index;
{
    s1_meta.location.index := s1_index_1;
}

// s1_Table s1_gen_reply
procedure {:inline 1} s1_gen_reply.apply()
	modifies s1_gen_reply.action_run, s1_gen_reply.gen_reply_act.message_type, s1_gen_reply.hit, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.srcAddr, s1_hdr.nc_hdr.op, s1_hdr.udp.dstPort, s1_meta.reply_to_client_md.ipv4_dstAddr, s1_meta.reply_to_client_md.ipv4_srcAddr;
{
    s1_hdr.nc_hdr.op := s1_hdr.nc_hdr.op;
    s1_gen_reply.hit := false;
    if(s1_hdr.nc_hdr.op == 10bv8){
        s1_gen_reply.hit := true;
        s1_gen_reply.action_run := s1_gen_reply.action.gen_reply_act;
        s1_gen_reply.gen_reply_act.message_type := 11bv8;
        call s1_gen_reply_act(s1_gen_reply.gen_reply_act.message_type);
        goto s1_Exit;
    }
    else if(s1_hdr.nc_hdr.op == 12bv8){
        s1_gen_reply.hit := true;
        s1_gen_reply.action_run := s1_gen_reply.action.gen_reply_act;
        s1_gen_reply.gen_reply_act.message_type := 13bv8;
        call s1_gen_reply_act(s1_gen_reply.gen_reply_act.message_type);
        goto s1_Exit;
    }
    if(!s1_gen_reply.hit){
        s1_gen_reply.action_run := s1_gen_reply.action.NoAction_7;
        call s1_NoAction_7();
        goto s1_Exit;
    }

    s1_Exit:
}

// s1_Action s1_gen_reply_act
procedure {:inline 1} s1_gen_reply_act(s1_message_type:bv8)
	modifies s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.srcAddr, s1_hdr.nc_hdr.op, s1_hdr.udp.dstPort, s1_meta.reply_to_client_md.ipv4_dstAddr, s1_meta.reply_to_client_md.ipv4_srcAddr;
{
    s1_meta.reply_to_client_md.ipv4_srcAddr := s1_hdr.ipv4.dstAddr;
    s1_meta.reply_to_client_md.ipv4_dstAddr := s1_hdr.ipv4.srcAddr;
    s1_hdr.ipv4.srcAddr := s1_meta.reply_to_client_md.ipv4_srcAddr;
    s1_hdr.ipv4.dstAddr := s1_meta.reply_to_client_md.ipv4_dstAddr;
    s1_hdr.nc_hdr.op := s1_message_type;
    s1_hdr.udp.dstPort := 8889bv16;
}

// s1_Table s1_get_my_address
procedure {:inline 1} s1_get_my_address.apply()
	modifies s1_get_my_address.action_run, s1_get_my_address.get_my_address_act.sw_ip, s1_get_my_address.get_my_address_act.sw_role, s1_get_my_address.hit, s1_hdr.nc_hdr.key, s1_meta.my_md.ipaddress, s1_meta.my_md.role;
{
    s1_hdr.nc_hdr.key := s1_hdr.nc_hdr.key;
    s1_get_my_address.hit := false;
    s1_get_my_address.action_run := s1_get_my_address.action.get_my_address_act;
    s1_get_my_address.get_my_address_act.sw_ip := 167797761bv32;
    s1_get_my_address.get_my_address_act.sw_role := 100bv16;
    call s1_get_my_address_act(s1_get_my_address.get_my_address_act.sw_ip, s1_get_my_address.get_my_address_act.sw_role);
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_get_my_address_act
procedure {:inline 1} s1_get_my_address_act(s1_sw_ip:bv32, s1_sw_role:bv16)
	modifies s1_meta.my_md.ipaddress, s1_meta.my_md.role;
{
    s1_meta.my_md.ipaddress := s1_sw_ip;
    s1_meta.my_md.role := s1_sw_role;
}

// s1_Table s1_get_next_hop
procedure {:inline 1} s1_get_next_hop.apply()
	modifies s1_get_next_hop.action_run, s1_get_next_hop.hit, s1_hdr.ipv4.dstAddr;
{
    s1_get_next_hop.hit := false;
    s1_get_next_hop.action_run := s1_get_next_hop.action.get_next_hop_act;
    call s1_get_next_hop_act();
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_get_next_hop_act
procedure {:inline 1} s1_get_next_hop_act()
	modifies s1_hdr.ipv4.dstAddr;
{
    s1_hdr.ipv4.dstAddr := s1_hdr.overlay.0.swip;
}

// s1_Table s1_get_sequence
procedure {:inline 1} s1_get_sequence.apply()
	modifies s1_get_sequence.action_run, s1_get_sequence.hit, s1_meta.sequence_md.seq;
{
    s1_get_sequence.hit := false;
    s1_get_sequence.action_run := s1_get_sequence.action.get_sequence_act;
    call s1_get_sequence_act();
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_get_sequence_act
procedure {:inline 1} s1_get_sequence_act()
	modifies s1_meta.sequence_md.seq;
{
    // s1_read
    s1_meta.sequence_md.seq := s1_sequence_reg.read(s1_sequence_reg, 0bv16++s1_meta.location.index);
}

// s1_Control s1_ingress
procedure {:inline 1} s1_ingress()
	modifies s1_assign_value.action_run, s1_assign_value.hit, s1_drop, s1_drop_packet.action_run, s1_drop_packet.hit, s1_failure_recovery.action_run, s1_failure_recovery.hit, s1_find_index.action_run, s1_find_index.find_index_act.index_1, s1_find_index.hit, s1_forward, s1_gen_reply.action_run, s1_gen_reply.gen_reply_act.message_type, s1_gen_reply.hit, s1_get_my_address.action_run, s1_get_my_address.get_my_address_act.sw_ip, s1_get_my_address.get_my_address_act.sw_role, s1_get_my_address.hit, s1_get_next_hop.action_run, s1_get_next_hop.hit, s1_get_sequence.action_run, s1_get_sequence.hit, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.srcAddr, s1_hdr.ipv4.totalLen, s1_hdr.ipv4.ttl, s1_hdr.nc_hdr.key, s1_hdr.nc_hdr.op, s1_hdr.nc_hdr.sc, s1_hdr.nc_hdr.seq, s1_hdr.nc_hdr.value, s1_hdr.nc_hdr.vgroup, s1_hdr.overlay.0.swip, s1_hdr.overlay.0.valid, s1_hdr.overlay.1.swip, s1_hdr.overlay.1.valid, s1_hdr.overlay.2.swip, s1_hdr.overlay.2.valid, s1_hdr.overlay.3.swip, s1_hdr.overlay.3.valid, s1_hdr.overlay.4.swip, s1_hdr.overlay.4.valid, s1_hdr.overlay.5.swip, s1_hdr.overlay.5.valid, s1_hdr.overlay.6.swip, s1_hdr.overlay.6.valid, s1_hdr.overlay.7.swip, s1_hdr.overlay.7.valid, s1_hdr.overlay.8.swip, s1_hdr.overlay.8.valid, s1_hdr.overlay.9.valid, s1_hdr.udp.dstPort, s1_hdr.udp.len, s1_ipv4_route.action_run, s1_ipv4_route.hit, s1_ipv4_route.set_egress.egress_spec_1, s1_isValid, s1_maintain_sequence.action_run, s1_maintain_sequence.hit, s1_meta.location.index, s1_meta.my_md.ipaddress, s1_meta.my_md.role, s1_meta.reply_to_client_md.ipv4_dstAddr, s1_meta.reply_to_client_md.ipv4_srcAddr, s1_meta.sequence_md.seq, s1_pop_chain.action_run, s1_pop_chain.hit, s1_pop_chain_again.action_run, s1_pop_chain_again.hit, s1_read_value.action_run, s1_read_value.hit, s1_sequence_reg, s1_sequence_reg__last0_old_value, s1_sequence_reg__last0_value, s1_sequence_reg__last_index, s1_sequence_reg__last_old_value, s1_sequence_reg__last_value, s1_sequence_reg__last_write_site, s1_sequence_reg__next_write_site, s1_sequence_reg__wrote_any, s1_sequence_reg__wrote_index0, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_value_reg, s1_value_reg__last0_old_value, s1_value_reg__last0_value, s1_value_reg__last_index, s1_value_reg__last_old_value, s1_value_reg__last_value, s1_value_reg__last_write_site, s1_value_reg__next_write_site, s1_value_reg__wrote_any, s1_value_reg__wrote_index0;
{
    if(s1_isValid[s1_hdr.nc_hdr]){
        call s1_get_my_address.apply();
        if((s1_hdr.ipv4.dstAddr == s1_meta.my_md.ipaddress)){
            call s1_find_index.apply();
            call s1_get_sequence.apply();
            if((s1_hdr.nc_hdr.op == 10bv8)){
                call s1_read_value.apply();
            }
            else{
                if((s1_hdr.nc_hdr.op == 12bv8)){
                    if((s1_meta.my_md.role == 100bv16)){
                        call s1_maintain_sequence.apply();
                    }
                    if(((s1_meta.my_md.role == 100bv16)) || (bugt.bv16(s1_hdr.nc_hdr.seq, s1_meta.sequence_md.seq))){
                        call s1_assign_value.apply();
                        call s1_pop_chain.apply();
                    }
                    else{
                        call s1_drop_packet.apply();
                    }
                }
            }
            if((s1_meta.my_md.role == 102bv16)){
                call s1_pop_chain_again.apply();
                call s1_gen_reply.apply();
            }
            else{
                call s1_get_next_hop.apply();
            }
        }
    }
    if(s1_isValid[s1_hdr.nc_hdr]){
        call s1_failure_recovery.apply();
    }
    if((s1_isValid[s1_hdr.tcp]) || (s1_isValid[s1_hdr.udp])){
        call s1_ipv4_route.apply();
    }
}

// s1_Table s1_ipv4_route
procedure {:inline 1} s1_ipv4_route.apply()
	modifies s1_forward, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.ttl, s1_ipv4_route.action_run, s1_ipv4_route.hit, s1_ipv4_route.set_egress.egress_spec_1, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    s1_hdr.ipv4.dstAddr := s1_hdr.ipv4.dstAddr;
    s1_ipv4_route.hit := false;
    if(s1_hdr.ipv4.dstAddr == 167772161bv32){
        s1_ipv4_route.hit := true;
        s1_ipv4_route.action_run := s1_ipv4_route.action.set_egress;
        s1_ipv4_route.set_egress.egress_spec_1 := 1bv9;
        call s1_set_egress(s1_ipv4_route.set_egress.egress_spec_1);
        goto s1_Exit;
    }
    else if(s1_hdr.ipv4.dstAddr == 167772162bv32){
        s1_ipv4_route.hit := true;
        s1_ipv4_route.action_run := s1_ipv4_route.action.set_egress;
        s1_ipv4_route.set_egress.egress_spec_1 := 1bv9;
        call s1_set_egress(s1_ipv4_route.set_egress.egress_spec_1);
        goto s1_Exit;
    }
    else if(s1_hdr.ipv4.dstAddr == 167797762bv32){
        s1_ipv4_route.hit := true;
        s1_ipv4_route.action_run := s1_ipv4_route.action.set_egress;
        s1_ipv4_route.set_egress.egress_spec_1 := 2bv9;
        call s1_set_egress(s1_ipv4_route.set_egress.egress_spec_1);
        goto s1_Exit;
    }
    else if(s1_hdr.ipv4.dstAddr == 167797763bv32){
        s1_ipv4_route.hit := true;
        s1_ipv4_route.action_run := s1_ipv4_route.action.set_egress;
        s1_ipv4_route.set_egress.egress_spec_1 := 1bv9;
        call s1_set_egress(s1_ipv4_route.set_egress.egress_spec_1);
        goto s1_Exit;
    }
    else if(s1_hdr.ipv4.dstAddr == 167797764bv32){
        s1_ipv4_route.hit := true;
        s1_ipv4_route.action_run := s1_ipv4_route.action.set_egress;
        s1_ipv4_route.set_egress.egress_spec_1 := 1bv9;
        call s1_set_egress(s1_ipv4_route.set_egress.egress_spec_1);
        goto s1_Exit;
    }
    if(!s1_ipv4_route.hit){
        s1_ipv4_route.action_run := s1_ipv4_route.action.NoAction_11;
        call s1_NoAction_11();
        goto s1_Exit;
    }

    s1_Exit:
}
procedure {:inline 1} s1_main()
	modifies s1_assign_value.action_run, s1_assign_value.hit, s1_drop, s1_drop_packet.action_run, s1_drop_packet.hit, s1_ethernet_set_mac.action_run, s1_ethernet_set_mac.ethernet_set_mac_act.dmac, s1_ethernet_set_mac.ethernet_set_mac_act.smac, s1_ethernet_set_mac.hit, s1_failure_recovery.action_run, s1_failure_recovery.hit, s1_find_index.action_run, s1_find_index.find_index_act.index_1, s1_find_index.hit, s1_forward, s1_gen_reply.action_run, s1_gen_reply.gen_reply_act.message_type, s1_gen_reply.hit, s1_get_my_address.action_run, s1_get_my_address.get_my_address_act.sw_ip, s1_get_my_address.get_my_address_act.sw_role, s1_get_my_address.hit, s1_get_next_hop.action_run, s1_get_next_hop.hit, s1_get_sequence.action_run, s1_get_sequence.hit, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.srcAddr, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.hdrChecksum, s1_hdr.ipv4.protocol, s1_hdr.ipv4.srcAddr, s1_hdr.ipv4.totalLen, s1_hdr.ipv4.ttl, s1_hdr.nc_hdr.key, s1_hdr.nc_hdr.op, s1_hdr.nc_hdr.sc, s1_hdr.nc_hdr.seq, s1_hdr.nc_hdr.value, s1_hdr.nc_hdr.vgroup, s1_hdr.overlay.0.swip, s1_hdr.overlay.0.valid, s1_hdr.overlay.1.swip, s1_hdr.overlay.1.valid, s1_hdr.overlay.2.swip, s1_hdr.overlay.2.valid, s1_hdr.overlay.3.swip, s1_hdr.overlay.3.valid, s1_hdr.overlay.4.swip, s1_hdr.overlay.4.valid, s1_hdr.overlay.5.swip, s1_hdr.overlay.5.valid, s1_hdr.overlay.6.swip, s1_hdr.overlay.6.valid, s1_hdr.overlay.7.swip, s1_hdr.overlay.7.valid, s1_hdr.overlay.8.swip, s1_hdr.overlay.8.valid, s1_hdr.overlay.9.valid, s1_hdr.udp.checksum, s1_hdr.udp.dstPort, s1_hdr.udp.len, s1_ipv4_route.action_run, s1_ipv4_route.hit, s1_ipv4_route.set_egress.egress_spec_1, s1_isValid, s1_maintain_sequence.action_run, s1_maintain_sequence.hit, s1_meta.location.index, s1_meta.my_md.ipaddress, s1_meta.my_md.role, s1_meta.reply_to_client_md.ipv4_dstAddr, s1_meta.reply_to_client_md.ipv4_srcAddr, s1_meta.sequence_md.seq, s1_p4b_checksum_updated, s1_pop_chain.action_run, s1_pop_chain.hit, s1_pop_chain_again.action_run, s1_pop_chain_again.hit, s1_read_value.action_run, s1_read_value.hit, s1_sequence_reg, s1_sequence_reg__last0_old_value, s1_sequence_reg__last0_value, s1_sequence_reg__last_index, s1_sequence_reg__last_old_value, s1_sequence_reg__last_value, s1_sequence_reg__last_write_site, s1_sequence_reg__next_write_site, s1_sequence_reg__wrote_any, s1_sequence_reg__wrote_index0, s1_stack.index, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_value_reg, s1_value_reg__last0_old_value, s1_value_reg__last0_value, s1_value_reg__last_index, s1_value_reg__last_old_value, s1_value_reg__last_value, s1_value_reg__last_write_site, s1_value_reg__next_write_site, s1_value_reg__wrote_any, s1_value_reg__wrote_index0;
{
    call s1_ParserImpl();
    call s1_verifyChecksum();
    call s1_ingress();
    call s1_egress();
    call s1_computeChecksum();
    if(s1_forward == false){
        s1_drop := true;
    }
}
procedure s1_mainProcedure()
	modifies s1_assign_value.action_run, s1_assign_value.hit, s1_drop, s1_drop_packet.action_run, s1_drop_packet.hit, s1_ethernet_set_mac.action_run, s1_ethernet_set_mac.ethernet_set_mac_act.dmac, s1_ethernet_set_mac.ethernet_set_mac_act.smac, s1_ethernet_set_mac.hit, s1_failure_recovery.action_run, s1_failure_recovery.hit, s1_find_index.action_run, s1_find_index.find_index_act.index_1, s1_find_index.hit, s1_forward, s1_gen_reply.action_run, s1_gen_reply.gen_reply_act.message_type, s1_gen_reply.hit, s1_get_my_address.action_run, s1_get_my_address.get_my_address_act.sw_ip, s1_get_my_address.get_my_address_act.sw_role, s1_get_my_address.hit, s1_get_next_hop.action_run, s1_get_next_hop.hit, s1_get_sequence.action_run, s1_get_sequence.hit, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.srcAddr, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.hdrChecksum, s1_hdr.ipv4.protocol, s1_hdr.ipv4.srcAddr, s1_hdr.ipv4.totalLen, s1_hdr.ipv4.ttl, s1_hdr.nc_hdr.key, s1_hdr.nc_hdr.op, s1_hdr.nc_hdr.sc, s1_hdr.nc_hdr.seq, s1_hdr.nc_hdr.value, s1_hdr.nc_hdr.vgroup, s1_hdr.overlay.0.swip, s1_hdr.overlay.0.valid, s1_hdr.overlay.1.swip, s1_hdr.overlay.1.valid, s1_hdr.overlay.2.swip, s1_hdr.overlay.2.valid, s1_hdr.overlay.3.swip, s1_hdr.overlay.3.valid, s1_hdr.overlay.4.swip, s1_hdr.overlay.4.valid, s1_hdr.overlay.5.swip, s1_hdr.overlay.5.valid, s1_hdr.overlay.6.swip, s1_hdr.overlay.6.valid, s1_hdr.overlay.7.swip, s1_hdr.overlay.7.valid, s1_hdr.overlay.8.swip, s1_hdr.overlay.8.valid, s1_hdr.overlay.9.valid, s1_hdr.udp.checksum, s1_hdr.udp.dstPort, s1_hdr.udp.len, s1_ipv4_route.action_run, s1_ipv4_route.hit, s1_ipv4_route.set_egress.egress_spec_1, s1_isValid, s1_maintain_sequence.action_run, s1_maintain_sequence.hit, s1_meta.location.index, s1_meta.my_md.ipaddress, s1_meta.my_md.role, s1_meta.reply_to_client_md.ipv4_dstAddr, s1_meta.reply_to_client_md.ipv4_srcAddr, s1_meta.sequence_md.seq, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pop_chain.action_run, s1_pop_chain.hit, s1_pop_chain_again.action_run, s1_pop_chain_again.hit, s1_read_value.action_run, s1_read_value.hit, s1_sequence_reg, s1_sequence_reg__last0_old_value, s1_sequence_reg__last0_value, s1_sequence_reg__last_index, s1_sequence_reg__last_old_value, s1_sequence_reg__last_value, s1_sequence_reg__last_write_site, s1_sequence_reg__next_write_site, s1_sequence_reg__wrote_any, s1_sequence_reg__wrote_index0, s1_stack.index, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_value_reg, s1_value_reg__last0_old_value, s1_value_reg__last0_value, s1_value_reg__last_index, s1_value_reg__last_old_value, s1_value_reg__last_value, s1_value_reg__last_write_site, s1_value_reg__next_write_site, s1_value_reg__wrote_any, s1_value_reg__wrote_index0;
{
    s1_p4b_checksum_error := false;
    s1_p4b_checksum_updated := false;
    s1_p4b_checksum_verified := false;
    s1_p4b_digest := false;
    s1_p4b_recirculate := false;
    s1_p4b_clone_i2i := false;
    s1_p4b_clone_e2e := false;
    s1_p4b_clone_i2e := false;
    call s1_main();
}

// s1_Table s1_maintain_sequence
procedure {:inline 1} s1_maintain_sequence.apply()
	modifies s1_hdr.nc_hdr.seq, s1_maintain_sequence.action_run, s1_maintain_sequence.hit, s1_meta.sequence_md.seq, s1_sequence_reg, s1_sequence_reg__last0_old_value, s1_sequence_reg__last0_value, s1_sequence_reg__last_index, s1_sequence_reg__last_old_value, s1_sequence_reg__last_value, s1_sequence_reg__last_write_site, s1_sequence_reg__next_write_site, s1_sequence_reg__wrote_any, s1_sequence_reg__wrote_index0;
{
    s1_maintain_sequence.hit := false;
    s1_maintain_sequence.action_run := s1_maintain_sequence.action.maintain_sequence_act;
    call s1_maintain_sequence_act();
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_maintain_sequence_act
procedure {:inline 1} s1_maintain_sequence_act()
	modifies s1_hdr.nc_hdr.seq, s1_meta.sequence_md.seq, s1_sequence_reg, s1_sequence_reg__last0_old_value, s1_sequence_reg__last0_value, s1_sequence_reg__last_index, s1_sequence_reg__last_old_value, s1_sequence_reg__last_value, s1_sequence_reg__last_write_site, s1_sequence_reg__next_write_site, s1_sequence_reg__wrote_any, s1_sequence_reg__wrote_index0;
{
    s1_meta.sequence_md.seq := add.bv16(s1_meta.sequence_md.seq, 1bv16);
    // s1_write
    s1_sequence_reg__next_write_site := 2;
    call s1_sequence_reg.write(0bv16++s1_meta.location.index, s1_meta.sequence_md.seq);
    // s1_read
    s1_hdr.nc_hdr.seq := s1_sequence_reg.read(s1_sequence_reg, 0bv16++s1_meta.location.index);
}
procedure s1_mark_to_drop();
    ensures s1_drop==true;
	modifies s1_drop;

// s1_Action s1_nop
procedure {:inline 1} s1_nop()
{
}
procedure s1_packet.emit(s1_arg0:s1_Ref);
procedure s1_packet_in.extract(s1_header:s1_Ref);
    ensures (s1_isValid[s1_header] == true);
	modifies s1_isValid;
procedure {:inline 1} s1_packet_in.extract.headers.overlay.next(s1_stack:s1_HeaderStack);
ensures(s1_isValid[s1_stack[s1_stack.index[s1_stack]]]==true && s1_stack.index[s1_stack]==old(s1_stack.index[s1_stack])+1);
	modifies s1_isValid, s1_stack.index;

// s1_Table s1_pop_chain
procedure {:inline 1} s1_pop_chain.apply()
	modifies s1_hdr.ipv4.totalLen, s1_hdr.nc_hdr.sc, s1_hdr.overlay.0.swip, s1_hdr.overlay.0.valid, s1_hdr.overlay.1.swip, s1_hdr.overlay.1.valid, s1_hdr.overlay.2.swip, s1_hdr.overlay.2.valid, s1_hdr.overlay.3.swip, s1_hdr.overlay.3.valid, s1_hdr.overlay.4.swip, s1_hdr.overlay.4.valid, s1_hdr.overlay.5.swip, s1_hdr.overlay.5.valid, s1_hdr.overlay.6.swip, s1_hdr.overlay.6.valid, s1_hdr.overlay.7.swip, s1_hdr.overlay.7.valid, s1_hdr.overlay.8.swip, s1_hdr.overlay.8.valid, s1_hdr.overlay.9.valid, s1_hdr.udp.len, s1_isValid, s1_pop_chain.action_run, s1_pop_chain.hit;
{
    s1_pop_chain.hit := false;
    s1_pop_chain.action_run := s1_pop_chain.action.pop_chain_act;
    call s1_pop_chain_act();
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_pop_chain_act
procedure {:inline 1} s1_pop_chain_act()
	modifies s1_hdr.ipv4.totalLen, s1_hdr.nc_hdr.sc, s1_hdr.overlay.0.swip, s1_hdr.overlay.0.valid, s1_hdr.overlay.1.swip, s1_hdr.overlay.1.valid, s1_hdr.overlay.2.swip, s1_hdr.overlay.2.valid, s1_hdr.overlay.3.swip, s1_hdr.overlay.3.valid, s1_hdr.overlay.4.swip, s1_hdr.overlay.4.valid, s1_hdr.overlay.5.swip, s1_hdr.overlay.5.valid, s1_hdr.overlay.6.swip, s1_hdr.overlay.6.valid, s1_hdr.overlay.7.swip, s1_hdr.overlay.7.valid, s1_hdr.overlay.8.swip, s1_hdr.overlay.8.valid, s1_hdr.overlay.9.valid, s1_hdr.udp.len, s1_isValid;
{
    s1_hdr.nc_hdr.sc := add.bv8(s1_hdr.nc_hdr.sc, 255bv8);
    // s1_pop_front
    s1_hdr.overlay.0.swip := s1_hdr.overlay.1.swip;
    s1_hdr.overlay.0.valid := s1_hdr.overlay.1.valid;
    s1_isValid[s1_hdr.overlay.0] := s1_isValid[s1_hdr.overlay.1];
    s1_hdr.overlay.1.swip := s1_hdr.overlay.2.swip;
    s1_hdr.overlay.1.valid := s1_hdr.overlay.2.valid;
    s1_isValid[s1_hdr.overlay.1] := s1_isValid[s1_hdr.overlay.2];
    s1_hdr.overlay.2.swip := s1_hdr.overlay.3.swip;
    s1_hdr.overlay.2.valid := s1_hdr.overlay.3.valid;
    s1_isValid[s1_hdr.overlay.2] := s1_isValid[s1_hdr.overlay.3];
    s1_hdr.overlay.3.swip := s1_hdr.overlay.4.swip;
    s1_hdr.overlay.3.valid := s1_hdr.overlay.4.valid;
    s1_isValid[s1_hdr.overlay.3] := s1_isValid[s1_hdr.overlay.4];
    s1_hdr.overlay.4.swip := s1_hdr.overlay.5.swip;
    s1_hdr.overlay.4.valid := s1_hdr.overlay.5.valid;
    s1_isValid[s1_hdr.overlay.4] := s1_isValid[s1_hdr.overlay.5];
    s1_hdr.overlay.5.swip := s1_hdr.overlay.6.swip;
    s1_hdr.overlay.5.valid := s1_hdr.overlay.6.valid;
    s1_isValid[s1_hdr.overlay.5] := s1_isValid[s1_hdr.overlay.6];
    s1_hdr.overlay.6.swip := s1_hdr.overlay.7.swip;
    s1_hdr.overlay.6.valid := s1_hdr.overlay.7.valid;
    s1_isValid[s1_hdr.overlay.6] := s1_isValid[s1_hdr.overlay.7];
    s1_hdr.overlay.7.swip := s1_hdr.overlay.8.swip;
    s1_hdr.overlay.7.valid := s1_hdr.overlay.8.valid;
    s1_isValid[s1_hdr.overlay.7] := s1_isValid[s1_hdr.overlay.8];
    s1_hdr.overlay.8.swip := s1_hdr.overlay.9.swip;
    s1_hdr.overlay.8.valid := s1_hdr.overlay.9.valid;
    s1_isValid[s1_hdr.overlay.8] := s1_isValid[s1_hdr.overlay.9];
    s1_hdr.overlay.9.valid := false;
    s1_isValid[s1_hdr.overlay.9] := false;
    s1_hdr.udp.len := add.bv16(s1_hdr.udp.len, 65532bv16);
    s1_hdr.ipv4.totalLen := add.bv16(s1_hdr.ipv4.totalLen, 65532bv16);
}

// s1_Table s1_pop_chain_again
procedure {:inline 1} s1_pop_chain_again.apply()
	modifies s1_hdr.ipv4.totalLen, s1_hdr.nc_hdr.sc, s1_hdr.overlay.0.swip, s1_hdr.overlay.0.valid, s1_hdr.overlay.1.swip, s1_hdr.overlay.1.valid, s1_hdr.overlay.2.swip, s1_hdr.overlay.2.valid, s1_hdr.overlay.3.swip, s1_hdr.overlay.3.valid, s1_hdr.overlay.4.swip, s1_hdr.overlay.4.valid, s1_hdr.overlay.5.swip, s1_hdr.overlay.5.valid, s1_hdr.overlay.6.swip, s1_hdr.overlay.6.valid, s1_hdr.overlay.7.swip, s1_hdr.overlay.7.valid, s1_hdr.overlay.8.swip, s1_hdr.overlay.8.valid, s1_hdr.overlay.9.valid, s1_hdr.udp.len, s1_isValid, s1_pop_chain_again.action_run, s1_pop_chain_again.hit;
{
    s1_pop_chain_again.hit := false;
    s1_pop_chain_again.action_run := s1_pop_chain_again.action.NoAction_14;
    call s1_NoAction_14();
    goto s1_Exit;

    s1_action_pop_chain_act:
    assume s1_pop_chain_again.action_run == s1_pop_chain_again.action.pop_chain_act;
    call s1_pop_chain_act();
    goto s1_Exit;

    s1_Exit:
}

// s1_Table s1_read_value
procedure {:inline 1} s1_read_value.apply()
	modifies s1_hdr.nc_hdr.value, s1_read_value.action_run, s1_read_value.hit;
{
    s1_read_value.hit := false;
    s1_read_value.action_run := s1_read_value.action.read_value_act;
    call s1_read_value_act();
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_read_value_act
procedure {:inline 1} s1_read_value_act()
	modifies s1_hdr.nc_hdr.value;
{
    // s1_read
    s1_hdr.nc_hdr.value := s1_value_reg.read(s1_value_reg, 0bv16++s1_meta.location.index);
}
procedure s1_reject();
    ensures s1_drop==true;
	modifies s1_drop;
function {:inline true}s1_sequence_reg.read(s1_reg:[bv32]bv16, s1_index:bv32)returns (bv16) {s1_reg[s1_index]}
procedure {:inline 1} s1_sequence_reg.write(s1_index:bv32, s1_value:bv16)
	modifies s1_sequence_reg, s1_sequence_reg__last0_old_value, s1_sequence_reg__last0_value, s1_sequence_reg__last_index, s1_sequence_reg__last_old_value, s1_sequence_reg__last_value, s1_sequence_reg__last_write_site, s1_sequence_reg__wrote_any, s1_sequence_reg__wrote_index0;
{
    s1_sequence_reg__last_old_value := s1_sequence_reg[s1_index];
    s1_sequence_reg[s1_index] := s1_value;
    s1_sequence_reg__last_index := s1_index;
    s1_sequence_reg__last_value := s1_value;
    s1_sequence_reg__last_write_site := s1_sequence_reg__next_write_site;
    s1_sequence_reg__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_sequence_reg__wrote_index0 := true;
        s1_sequence_reg__last0_old_value := s1_sequence_reg__last_old_value;
        s1_sequence_reg__last0_value := s1_value;
    }
}
procedure {:inline 1} s1_setInvalid(s1_header:s1_Ref);
    ensures (s1_isValid[s1_header] == false);
	modifies s1_isValid;
procedure {:inline 1} s1_setValid(s1_header:s1_Ref);

// s1_Action s1_set_egress
procedure {:inline 1} s1_set_egress(s1_egress_spec_1:bv9)
	modifies s1_forward, s1_hdr.ipv4.ttl, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    s1_standard_metadata.egress_spec := s1_egress_spec_1;
    s1_standard_metadata.egress_port := s1_egress_spec_1;
    s1_forward := true;
    s1_hdr.ipv4.ttl := add.bv8(s1_hdr.ipv4.ttl, 255bv8);
}
function {:inline true}s1_value_reg.read(s1_reg:[bv32]bv128, s1_index:bv32)returns (bv128) {s1_reg[s1_index]}
procedure {:inline 1} s1_value_reg.write(s1_index:bv32, s1_value:bv128)
	modifies s1_value_reg, s1_value_reg__last0_old_value, s1_value_reg__last0_value, s1_value_reg__last_index, s1_value_reg__last_old_value, s1_value_reg__last_value, s1_value_reg__last_write_site, s1_value_reg__wrote_any, s1_value_reg__wrote_index0;
{
    s1_value_reg__last_old_value := s1_value_reg[s1_index];
    s1_value_reg[s1_index] := s1_value;
    s1_value_reg__last_index := s1_index;
    s1_value_reg__last_value := s1_value;
    s1_value_reg__last_write_site := s1_value_reg__next_write_site;
    s1_value_reg__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_value_reg__wrote_index0 := true;
        s1_value_reg__last0_old_value := s1_value_reg__last_old_value;
        s1_value_reg__last0_value := s1_value;
    }
}

// s1_Control s1_verifyChecksum
procedure {:inline 1} s1_verifyChecksum()
{
}
// ===== END NODE s1 =====

// ===== BEGIN NODE s2 (prefixed) =====
type s2_Ref;
type s2_error=bv1;
type s2_HeaderStack = [int]s2_Ref;
var s2_last:[s2_HeaderStack]s2_Ref;
var s2_forward:bool;
var s2_isValid:[s2_Ref]bool;
var s2_emit:[s2_Ref]bool;
var s2_stack.index:[s2_HeaderStack]int;
var s2_size:[s2_HeaderStack]int;
var s2_drop:bool;
var s2_p4b_clone_i2e:bool;
var s2_p4b_clone_e2e:bool;
var s2_p4b_clone_i2i:bool;
var s2_p4b_recirculate:bool;
var s2_p4b_digest:bool;
var s2_p4b_checksum_verified:bool;
var s2_p4b_checksum_updated:bool;
var s2_p4b_checksum_error:bool;

// s2_Struct s2_standard_metadata_t
type s2_standard_metadata_t;
var s2_standard_metadata.ingress_port:bv9;
var s2_standard_metadata.egress_spec:bv9;
var s2_standard_metadata.egress_port:bv9;
var s2_standard_metadata.instance_type:bv32;
var s2_standard_metadata.packet_length:bv32;
var s2_standard_metadata.enq_timestamp:bv32;
var s2_standard_metadata.enq_qdepth:bv19;
var s2_standard_metadata.deq_timedelta:bv32;
var s2_standard_metadata.deq_qdepth:bv19;
var s2_standard_metadata.ingress_global_timestamp:bv48;
var s2_standard_metadata.egress_global_timestamp:bv48;
var s2_standard_metadata.mcast_grp:bv16;
var s2_standard_metadata.egress_rid:bv16;
var s2_standard_metadata.checksum_error:bv1;
var s2_standard_metadata.parser_error:s2_error;
var s2_standard_metadata.priority:bv3;
type s2_CounterType = int;
type s2_MeterType = int;
type s2_HashAlgorithm = int;
type s2_CloneType = int;

// s2_Struct s2_location_t
type s2_location_t;

// s2_Struct s2_my_md_t
type s2_my_md_t;

// s2_Struct s2_reply_addr_t
type s2_reply_addr_t;

// s2_Struct s2_sequence_md_t
type s2_sequence_md_t;
type s2_ethernet_t;
type s2_ipv4_t;
type s2_nc_hdr_t;
type s2_tcp_t;
type s2_udp_t;
type s2_overlay_t;

// s2_Struct s2_metadata
type s2_metadata;
var s2_meta.location:s2_location_t;
var s2_meta.location.index:bv16;
var s2_meta.my_md:s2_my_md_t;
var s2_meta.my_md.ipaddress:bv32;
var s2_meta.my_md.role:bv16;
var s2_meta.my_md.failed:bv16;
var s2_meta.reply_to_client_md:s2_reply_addr_t;
var s2_meta.reply_to_client_md.ipv4_srcAddr:bv32;
var s2_meta.reply_to_client_md.ipv4_dstAddr:bv32;
var s2_meta.sequence_md:s2_sequence_md_t;
var s2_meta.sequence_md.seq:bv16;
var s2_meta.sequence_md.tmp:bv16;

// s2_Struct s2_headers
var s2_hdr:s2_Ref;

// s2_Header s2_ethernet_t
var s2_hdr.ethernet:s2_Ref;
var s2_hdr.ethernet.valid:bool;
var s2_hdr.ethernet.dstAddr:bv48;
var s2_hdr.ethernet.srcAddr:bv48;
var s2_hdr.ethernet.etherType:bv16;

// s2_Header s2_ipv4_t
var s2_hdr.ipv4:s2_Ref;
var s2_hdr.ipv4.valid:bool;
var s2_hdr.ipv4.version:bv4;
var s2_hdr.ipv4.ihl:bv4;
var s2_hdr.ipv4.diffserv:bv8;
var s2_hdr.ipv4.totalLen:bv16;
var s2_hdr.ipv4.identification:bv16;
var s2_hdr.ipv4.flags:bv3;
var s2_hdr.ipv4.fragOffset:bv13;
var s2_hdr.ipv4.ttl:bv8;
var s2_hdr.ipv4.protocol:bv8;
var s2_hdr.ipv4.hdrChecksum:bv16;
var s2_hdr.ipv4.srcAddr:bv32;
var s2_hdr.ipv4.dstAddr:bv32;

// s2_Header s2_nc_hdr_t
var s2_hdr.nc_hdr:s2_Ref;
var s2_hdr.nc_hdr.valid:bool;
var s2_hdr.nc_hdr.op:bv8;
var s2_hdr.nc_hdr.sc:bv8;
var s2_hdr.nc_hdr.seq:bv16;
var s2_hdr.nc_hdr.key:bv128;
var s2_hdr.nc_hdr.value:bv128;
var s2_hdr.nc_hdr.vgroup:bv16;

// s2_Header s2_tcp_t
var s2_hdr.tcp:s2_Ref;
var s2_hdr.tcp.valid:bool;
var s2_hdr.tcp.srcPort:bv16;
var s2_hdr.tcp.dstPort:bv16;
var s2_hdr.tcp.seqNo:bv32;
var s2_hdr.tcp.ackNo:bv32;
var s2_hdr.tcp.dataOffset:bv4;
var s2_hdr.tcp.res:bv3;
var s2_hdr.tcp.ecn:bv3;
var s2_hdr.tcp.ctrl:bv6;
var s2_hdr.tcp.window:bv16;
var s2_hdr.tcp.checksum:bv16;
var s2_hdr.tcp.urgentPtr:bv16;

// s2_Header s2_udp_t
var s2_hdr.udp:s2_Ref;
var s2_hdr.udp.valid:bool;
var s2_hdr.udp.srcPort:bv16;
var s2_hdr.udp.dstPort:bv16;
var s2_hdr.udp.len:bv16;
var s2_hdr.udp.checksum:bv16;
const s2_hdr.overlay:s2_HeaderStack;

// s2_Header s2_overlay_t
var s2_hdr.overlay.last:s2_Ref;
var s2_hdr.overlay.last.valid:bool;
var s2_hdr.overlay.last.swip:bv32;

// s2_Header s2_overlay_t
var s2_hdr.overlay.0:s2_Ref;
var s2_hdr.overlay.0.valid:bool;
var s2_hdr.overlay.0.swip:bv32;

// s2_Header s2_overlay_t
var s2_hdr.overlay.1:s2_Ref;
var s2_hdr.overlay.1.valid:bool;
var s2_hdr.overlay.1.swip:bv32;

// s2_Header s2_overlay_t
var s2_hdr.overlay.2:s2_Ref;
var s2_hdr.overlay.2.valid:bool;
var s2_hdr.overlay.2.swip:bv32;

// s2_Header s2_overlay_t
var s2_hdr.overlay.3:s2_Ref;
var s2_hdr.overlay.3.valid:bool;
var s2_hdr.overlay.3.swip:bv32;

// s2_Header s2_overlay_t
var s2_hdr.overlay.4:s2_Ref;
var s2_hdr.overlay.4.valid:bool;
var s2_hdr.overlay.4.swip:bv32;

// s2_Header s2_overlay_t
var s2_hdr.overlay.5:s2_Ref;
var s2_hdr.overlay.5.valid:bool;
var s2_hdr.overlay.5.swip:bv32;

// s2_Header s2_overlay_t
var s2_hdr.overlay.6:s2_Ref;
var s2_hdr.overlay.6.valid:bool;
var s2_hdr.overlay.6.swip:bv32;

// s2_Header s2_overlay_t
var s2_hdr.overlay.7:s2_Ref;
var s2_hdr.overlay.7.valid:bool;
var s2_hdr.overlay.7.swip:bv32;

// s2_Header s2_overlay_t
var s2_hdr.overlay.8:s2_Ref;
var s2_hdr.overlay.8.valid:bool;
var s2_hdr.overlay.8.swip:bv32;

// s2_Header s2_overlay_t
var s2_hdr.overlay.9:s2_Ref;
var s2_hdr.overlay.9.valid:bool;
var s2_hdr.overlay.9.swip:bv32;
var s2_meta:s2_metadata;
var s2_standard_metadata:s2_standard_metadata_t;

// s2_Table s2_ethernet_set_mac s2_Actionlist s2_Declaration
type s2_ethernet_set_mac.action;
var s2_ethernet_set_mac.ethernet_set_mac_act.smac:bv48;
var s2_ethernet_set_mac.ethernet_set_mac_act.dmac:bv48;
const unique s2_ethernet_set_mac.action.ethernet_set_mac_act : s2_ethernet_set_mac.action;
const unique s2_ethernet_set_mac.action.NoAction : s2_ethernet_set_mac.action;
var s2_ethernet_set_mac.action_run : s2_ethernet_set_mac.action;
var s2_ethernet_set_mac.hit : bool;

// s2_Register s2_sequence_reg
var s2_sequence_reg:[bv32]bv16;
var s2_sequence_reg__last_index:bv32;
var s2_sequence_reg__last_value:bv16;
var s2_sequence_reg__last_old_value:bv16;
var s2_sequence_reg__wrote_any:bool;
var s2_sequence_reg__wrote_index0:bool;
var s2_sequence_reg__last0_old_value:bv16;
var s2_sequence_reg__last0_value:bv16;
var s2_sequence_reg__next_write_site:int;
var s2_sequence_reg__last_write_site:int;
const s2_sequence_reg.size:bv32;
axiom s2_sequence_reg.size == 4096bv32;

// s2_Register s2_value_reg
var s2_value_reg:[bv32]bv128;
var s2_value_reg__last_index:bv32;
var s2_value_reg__last_value:bv128;
var s2_value_reg__last_old_value:bv128;
var s2_value_reg__wrote_any:bool;
var s2_value_reg__wrote_index0:bool;
var s2_value_reg__last0_old_value:bv128;
var s2_value_reg__last0_value:bv128;
var s2_value_reg__next_write_site:int;
var s2_value_reg__last_write_site:int;
const s2_value_reg.size:bv32;
axiom s2_value_reg.size == 4096bv32;



// s2_Table s2_assign_value s2_Actionlist s2_Declaration
type s2_assign_value.action;
const unique s2_assign_value.action.assign_value_act : s2_assign_value.action;
const unique s2_assign_value.action.NoAction_3 : s2_assign_value.action;
var s2_assign_value.action_run : s2_assign_value.action;
var s2_assign_value.hit : bool;

// s2_Table s2_drop_packet s2_Actionlist s2_Declaration
type s2_drop_packet.action;
const unique s2_drop_packet.action.drop_packet_act : s2_drop_packet.action;
const unique s2_drop_packet.action.NoAction_4 : s2_drop_packet.action;
var s2_drop_packet.action_run : s2_drop_packet.action;
var s2_drop_packet.hit : bool;

// s2_Table s2_failure_recovery s2_Actionlist s2_Declaration
type s2_failure_recovery.action;
var s2_failure_recovery.failure_recovery_act.nexthop:bv32;
const unique s2_failure_recovery.action.failover_act : s2_failure_recovery.action;
const unique s2_failure_recovery.action.failover_write_reply_act : s2_failure_recovery.action;
const unique s2_failure_recovery.action.failure_recovery_act : s2_failure_recovery.action;
const unique s2_failure_recovery.action.nop : s2_failure_recovery.action;
const unique s2_failure_recovery.action.drop_packet_act : s2_failure_recovery.action;
const unique s2_failure_recovery.action.NoAction_5 : s2_failure_recovery.action;
var s2_failure_recovery.action_run : s2_failure_recovery.action;
var s2_failure_recovery.hit : bool;

// s2_Table s2_find_index s2_Actionlist s2_Declaration
type s2_find_index.action;
var s2_find_index.find_index_act.index_1:bv16;
const unique s2_find_index.action.find_index_act : s2_find_index.action;
const unique s2_find_index.action.NoAction_6 : s2_find_index.action;
var s2_find_index.action_run : s2_find_index.action;
var s2_find_index.hit : bool;

// s2_Table s2_gen_reply s2_Actionlist s2_Declaration
type s2_gen_reply.action;
var s2_gen_reply.gen_reply_act.message_type:bv8;
const unique s2_gen_reply.action.gen_reply_act : s2_gen_reply.action;
const unique s2_gen_reply.action.NoAction_7 : s2_gen_reply.action;
var s2_gen_reply.action_run : s2_gen_reply.action;
var s2_gen_reply.hit : bool;

// s2_Table s2_get_my_address s2_Actionlist s2_Declaration
type s2_get_my_address.action;
var s2_get_my_address.get_my_address_act.sw_ip:bv32;
var s2_get_my_address.get_my_address_act.sw_role:bv16;
const unique s2_get_my_address.action.get_my_address_act : s2_get_my_address.action;
const unique s2_get_my_address.action.NoAction_8 : s2_get_my_address.action;
var s2_get_my_address.action_run : s2_get_my_address.action;
var s2_get_my_address.hit : bool;

// s2_Table s2_get_next_hop s2_Actionlist s2_Declaration
type s2_get_next_hop.action;
const unique s2_get_next_hop.action.get_next_hop_act : s2_get_next_hop.action;
const unique s2_get_next_hop.action.NoAction_9 : s2_get_next_hop.action;
var s2_get_next_hop.action_run : s2_get_next_hop.action;
var s2_get_next_hop.hit : bool;

// s2_Table s2_get_sequence s2_Actionlist s2_Declaration
type s2_get_sequence.action;
const unique s2_get_sequence.action.get_sequence_act : s2_get_sequence.action;
const unique s2_get_sequence.action.NoAction_10 : s2_get_sequence.action;
var s2_get_sequence.action_run : s2_get_sequence.action;
var s2_get_sequence.hit : bool;

// s2_Table s2_ipv4_route s2_Actionlist s2_Declaration
type s2_ipv4_route.action;
var s2_ipv4_route.set_egress.egress_spec_1:bv9;
const unique s2_ipv4_route.action.set_egress : s2_ipv4_route.action;
const unique s2_ipv4_route.action.NoAction_11 : s2_ipv4_route.action;
var s2_ipv4_route.action_run : s2_ipv4_route.action;
var s2_ipv4_route.hit : bool;

// s2_Table s2_maintain_sequence s2_Actionlist s2_Declaration
type s2_maintain_sequence.action;
const unique s2_maintain_sequence.action.maintain_sequence_act : s2_maintain_sequence.action;
const unique s2_maintain_sequence.action.NoAction_12 : s2_maintain_sequence.action;
var s2_maintain_sequence.action_run : s2_maintain_sequence.action;
var s2_maintain_sequence.hit : bool;

// s2_Table s2_pop_chain s2_Actionlist s2_Declaration
type s2_pop_chain.action;
const unique s2_pop_chain.action.pop_chain_act : s2_pop_chain.action;
const unique s2_pop_chain.action.NoAction_13 : s2_pop_chain.action;
var s2_pop_chain.action_run : s2_pop_chain.action;
var s2_pop_chain.hit : bool;

// s2_Table s2_pop_chain_again s2_Actionlist s2_Declaration
type s2_pop_chain_again.action;
const unique s2_pop_chain_again.action.pop_chain_act : s2_pop_chain_again.action;
const unique s2_pop_chain_again.action.NoAction_14 : s2_pop_chain_again.action;
var s2_pop_chain_again.action_run : s2_pop_chain_again.action;
var s2_pop_chain_again.hit : bool;

// s2_Table s2_read_value s2_Actionlist s2_Declaration
type s2_read_value.action;
const unique s2_read_value.action.read_value_act : s2_read_value.action;
const unique s2_read_value.action.NoAction_15 : s2_read_value.action;
var s2_read_value.action_run : s2_read_value.action;
var s2_read_value.hit : bool;




// s2_Action s2_NoAction
procedure {:inline 1} s2_NoAction()
{
}

// s2_Action s2_NoAction_10
procedure {:inline 1} s2_NoAction_10()
{
}

// s2_Action s2_NoAction_11
procedure {:inline 1} s2_NoAction_11()
{
}

// s2_Action s2_NoAction_12
procedure {:inline 1} s2_NoAction_12()
{
}

// s2_Action s2_NoAction_13
procedure {:inline 1} s2_NoAction_13()
{
}

// s2_Action s2_NoAction_14
procedure {:inline 1} s2_NoAction_14()
{
}

// s2_Action s2_NoAction_15
procedure {:inline 1} s2_NoAction_15()
{
}

// s2_Action s2_NoAction_3
procedure {:inline 1} s2_NoAction_3()
{
}

// s2_Action s2_NoAction_4
procedure {:inline 1} s2_NoAction_4()
{
}

// s2_Action s2_NoAction_5
procedure {:inline 1} s2_NoAction_5()
{
}

// s2_Action s2_NoAction_6
procedure {:inline 1} s2_NoAction_6()
{
}

// s2_Action s2_NoAction_7
procedure {:inline 1} s2_NoAction_7()
{
}

// s2_Action s2_NoAction_8
procedure {:inline 1} s2_NoAction_8()
{
}

// s2_Action s2_NoAction_9
procedure {:inline 1} s2_NoAction_9()
{
}

// s2_Parser s2_ParserImpl
procedure {:inline 1} s2_ParserImpl()
	modifies s2_drop, s2_hdr.ipv4.protocol, s2_hdr.udp.dstPort, s2_isValid, s2_stack.index;
{
    goto s2_State$ParserImpl$start;

        s2_State$ParserImpl$start:
    goto s2_State$ParserImpl$parse_ethernet;

        s2_State$ParserImpl$parse_ethernet:
    call s2_packet_in.extract(s2_hdr.ethernet);
    goto s2_State$ParserImpl$parse_ethernet$parse_ipv4_2, s2_State$ParserImpl$parse_ethernet$DEFAULT;
    
s2_State$ParserImpl$parse_ethernet$parse_ipv4_2:
    assume (s2_hdr.ethernet.etherType == 2048bv16);
    goto s2_State$ParserImpl$parse_ipv4;

    s2_State$ParserImpl$parse_ethernet$DEFAULT:
    assume(!(s2_hdr.ethernet.etherType == 2048bv16));
    goto s2_State$accept;

        s2_State$ParserImpl$parse_ipv4:
    call s2_packet_in.extract(s2_hdr.ipv4);
    s2_hdr.ipv4.protocol := 17bv8;
    goto s2_State$ParserImpl$parse_ipv4$parse_tcp_3, s2_State$ParserImpl$parse_ipv4$parse_udp_2, s2_State$ParserImpl$parse_ipv4$DEFAULT;
    
s2_State$ParserImpl$parse_ipv4$parse_tcp_3:
    assume (s2_hdr.ipv4.protocol == 6bv8);
    goto s2_State$ParserImpl$parse_tcp;
    
s2_State$ParserImpl$parse_ipv4$parse_udp_2:
    assume (s2_hdr.ipv4.protocol == 17bv8);
    goto s2_State$ParserImpl$parse_udp;

    s2_State$ParserImpl$parse_ipv4$DEFAULT:
    assume(!(s2_hdr.ipv4.protocol == 6bv8)&&!(s2_hdr.ipv4.protocol == 17bv8));
    goto s2_State$accept;

        s2_State$ParserImpl$parse_nc_hdr:
    call s2_packet_in.extract(s2_hdr.nc_hdr);
    goto s2_State$ParserImpl$parse_nc_hdr$accept_3, s2_State$ParserImpl$parse_nc_hdr$accept_2, s2_State$ParserImpl$parse_nc_hdr$DEFAULT;
    
s2_State$ParserImpl$parse_nc_hdr$accept_3:
    assume (s2_hdr.nc_hdr.op == 10bv8);
    goto s2_State$accept;
    
s2_State$ParserImpl$parse_nc_hdr$accept_2:
    assume (s2_hdr.nc_hdr.op == 12bv8);
    goto s2_State$accept;

    s2_State$ParserImpl$parse_nc_hdr$DEFAULT:
    assume(!(s2_hdr.nc_hdr.op == 10bv8)&&!(s2_hdr.nc_hdr.op == 12bv8));
    goto s2_State$accept;

        s2_State$ParserImpl$parse_overlay:
    call s2_packet_in.extract.headers.overlay.next(s2_hdr.overlay);
    goto s2_State$ParserImpl$parse_overlay$parse_nc_hdr_2, s2_State$ParserImpl$parse_overlay$DEFAULT;
    
s2_State$ParserImpl$parse_overlay$parse_nc_hdr_2:
    assume (s2_hdr.overlay.last.swip == 0bv32);
    goto s2_State$ParserImpl$parse_nc_hdr;

    s2_State$ParserImpl$parse_overlay$DEFAULT:
    assume(!(s2_hdr.overlay.last.swip == 0bv32));
    goto s2_State$ParserImpl$parse_overlay;

        s2_State$ParserImpl$parse_tcp:
    call s2_packet_in.extract(s2_hdr.tcp);
    goto s2_State$accept;

        s2_State$ParserImpl$parse_udp:
    call s2_packet_in.extract(s2_hdr.udp);
    s2_hdr.udp.dstPort := 8888bv16;
    goto s2_State$ParserImpl$parse_udp$parse_overlay_3, s2_State$ParserImpl$parse_udp$parse_overlay_2, s2_State$ParserImpl$parse_udp$DEFAULT;
    
s2_State$ParserImpl$parse_udp$parse_overlay_3:
    assume (s2_hdr.udp.dstPort == 8888bv16);
    goto s2_State$ParserImpl$parse_overlay;
    
s2_State$ParserImpl$parse_udp$parse_overlay_2:
    assume (s2_hdr.udp.dstPort == 8889bv16);
    goto s2_State$ParserImpl$parse_overlay;

    s2_State$ParserImpl$parse_udp$DEFAULT:
    assume(!(s2_hdr.udp.dstPort == 8888bv16)&&!(s2_hdr.udp.dstPort == 8889bv16));
    goto s2_State$accept;

    s2_State$accept:
    call s2_accept();
    goto s2_Exit;

    s2_State$reject:
    call s2_reject();
    goto s2_Exit;

    s2_Exit:
}
procedure {:inline 1} s2_accept()
{
}

// s2_Table s2_assign_value
procedure {:inline 1} s2_assign_value.apply()
	modifies s2_assign_value.action_run, s2_assign_value.hit, s2_sequence_reg, s2_sequence_reg__last0_old_value, s2_sequence_reg__last0_value, s2_sequence_reg__last_index, s2_sequence_reg__last_old_value, s2_sequence_reg__last_value, s2_sequence_reg__last_write_site, s2_sequence_reg__next_write_site, s2_sequence_reg__wrote_any, s2_sequence_reg__wrote_index0, s2_value_reg, s2_value_reg__last0_old_value, s2_value_reg__last0_value, s2_value_reg__last_index, s2_value_reg__last_old_value, s2_value_reg__last_value, s2_value_reg__last_write_site, s2_value_reg__next_write_site, s2_value_reg__wrote_any, s2_value_reg__wrote_index0;
{
    s2_assign_value.hit := false;
    s2_assign_value.action_run := s2_assign_value.action.assign_value_act;
    call s2_assign_value_act();
    goto s2_Exit;

    s2_Exit:
}

// s2_Action s2_assign_value_act
procedure {:inline 1} s2_assign_value_act()
	modifies s2_sequence_reg, s2_sequence_reg__last0_old_value, s2_sequence_reg__last0_value, s2_sequence_reg__last_index, s2_sequence_reg__last_old_value, s2_sequence_reg__last_value, s2_sequence_reg__last_write_site, s2_sequence_reg__next_write_site, s2_sequence_reg__wrote_any, s2_sequence_reg__wrote_index0, s2_value_reg, s2_value_reg__last0_old_value, s2_value_reg__last0_value, s2_value_reg__last_index, s2_value_reg__last_old_value, s2_value_reg__last_value, s2_value_reg__last_write_site, s2_value_reg__next_write_site, s2_value_reg__wrote_any, s2_value_reg__wrote_index0;
{
    // s2_write
    s2_sequence_reg__next_write_site := 1;
    call s2_sequence_reg.write(0bv16++s2_meta.location.index, s2_hdr.nc_hdr.seq);
    // s2_write
    s2_value_reg__next_write_site := 1;
    call s2_value_reg.write(0bv16++s2_meta.location.index, s2_hdr.nc_hdr.value);
}

// s2_Control s2_computeChecksum
procedure {:inline 1} s2_computeChecksum()
	modifies s2_hdr.ipv4.hdrChecksum, s2_hdr.udp.checksum, s2_p4b_checksum_updated;
{
    if (true) {
        s2_p4b_checksum_updated := true;
        havoc s2_hdr.ipv4.hdrChecksum;
    }
    if (true) {
        s2_p4b_checksum_updated := true;
        havoc s2_hdr.udp.checksum;
    }
}

// s2_Table s2_drop_packet
procedure {:inline 1} s2_drop_packet.apply()
	modifies s2_drop, s2_drop_packet.action_run, s2_drop_packet.hit;
{
    s2_drop_packet.hit := false;
    s2_drop_packet.action_run := s2_drop_packet.action.drop_packet_act;
    call s2_drop_packet_act();
    goto s2_Exit;

    s2_Exit:
}

// s2_Action s2_drop_packet_act
procedure {:inline 1} s2_drop_packet_act()
	modifies s2_drop;
{
    call s2_mark_to_drop();
}

// s2_Control s2_egress
procedure {:inline 1} s2_egress()
	modifies s2_ethernet_set_mac.action_run, s2_ethernet_set_mac.ethernet_set_mac_act.dmac, s2_ethernet_set_mac.ethernet_set_mac_act.smac, s2_ethernet_set_mac.hit, s2_hdr.ethernet.dstAddr, s2_hdr.ethernet.srcAddr, s2_standard_metadata.egress_port;
{
    call s2_ethernet_set_mac.apply();
}

// s2_Table s2_ethernet_set_mac
procedure {:inline 1} s2_ethernet_set_mac.apply()
	modifies s2_ethernet_set_mac.action_run, s2_ethernet_set_mac.ethernet_set_mac_act.dmac, s2_ethernet_set_mac.ethernet_set_mac_act.smac, s2_ethernet_set_mac.hit, s2_hdr.ethernet.dstAddr, s2_hdr.ethernet.srcAddr, s2_standard_metadata.egress_port;
{
    s2_standard_metadata.egress_port := s2_standard_metadata.egress_port;
    s2_ethernet_set_mac.hit := false;
    if(s2_standard_metadata.egress_port == 1bv9){
        s2_ethernet_set_mac.hit := true;
        s2_ethernet_set_mac.action_run := s2_ethernet_set_mac.action.ethernet_set_mac_act;
        s2_ethernet_set_mac.ethernet_set_mac_act.smac := 187723572702753bv48;
        s2_ethernet_set_mac.ethernet_set_mac_act.dmac := 187723572702788bv48;
        call s2_ethernet_set_mac_act(s2_ethernet_set_mac.ethernet_set_mac_act.smac, s2_ethernet_set_mac.ethernet_set_mac_act.dmac);
        goto s2_Exit;
    }
    else if(s2_standard_metadata.egress_port == 2bv9){
        s2_ethernet_set_mac.hit := true;
        s2_ethernet_set_mac.action_run := s2_ethernet_set_mac.action.ethernet_set_mac_act;
        s2_ethernet_set_mac.ethernet_set_mac_act.smac := 187723572702754bv48;
        s2_ethernet_set_mac.ethernet_set_mac_act.dmac := 187723572702738bv48;
        call s2_ethernet_set_mac_act(s2_ethernet_set_mac.ethernet_set_mac_act.smac, s2_ethernet_set_mac.ethernet_set_mac_act.dmac);
        goto s2_Exit;
    }
    else if(s2_standard_metadata.egress_port == 3bv9){
        s2_ethernet_set_mac.hit := true;
        s2_ethernet_set_mac.action_run := s2_ethernet_set_mac.action.ethernet_set_mac_act;
        s2_ethernet_set_mac.ethernet_set_mac_act.smac := 187723572702755bv48;
        s2_ethernet_set_mac.ethernet_set_mac_act.dmac := 187723572702770bv48;
        call s2_ethernet_set_mac_act(s2_ethernet_set_mac.ethernet_set_mac_act.smac, s2_ethernet_set_mac.ethernet_set_mac_act.dmac);
        goto s2_Exit;
    }
    if(!s2_ethernet_set_mac.hit){
        s2_ethernet_set_mac.action_run := s2_ethernet_set_mac.action.NoAction;
        call s2_NoAction();
        goto s2_Exit;
    }

    s2_Exit:
}

// s2_Action s2_ethernet_set_mac_act
procedure {:inline 1} s2_ethernet_set_mac_act(s2_smac:bv48, s2_dmac:bv48)
	modifies s2_hdr.ethernet.dstAddr, s2_hdr.ethernet.srcAddr;
{
    s2_hdr.ethernet.srcAddr := s2_smac;
    s2_hdr.ethernet.dstAddr := s2_dmac;
}

// s2_Action s2_failover_act
procedure {:inline 1} s2_failover_act()
	modifies s2_hdr.ipv4.dstAddr, s2_hdr.ipv4.totalLen, s2_hdr.nc_hdr.sc, s2_hdr.overlay.0.swip, s2_hdr.overlay.0.valid, s2_hdr.overlay.1.swip, s2_hdr.overlay.1.valid, s2_hdr.overlay.2.swip, s2_hdr.overlay.2.valid, s2_hdr.overlay.3.swip, s2_hdr.overlay.3.valid, s2_hdr.overlay.4.swip, s2_hdr.overlay.4.valid, s2_hdr.overlay.5.swip, s2_hdr.overlay.5.valid, s2_hdr.overlay.6.swip, s2_hdr.overlay.6.valid, s2_hdr.overlay.7.swip, s2_hdr.overlay.7.valid, s2_hdr.overlay.8.swip, s2_hdr.overlay.8.valid, s2_hdr.overlay.9.valid, s2_hdr.udp.len, s2_isValid;
{
    s2_hdr.ipv4.dstAddr := s2_hdr.overlay.1.swip;
    s2_hdr.nc_hdr.sc := add.bv8(s2_hdr.nc_hdr.sc, 255bv8);
    // s2_pop_front
    s2_hdr.overlay.0.swip := s2_hdr.overlay.1.swip;
    s2_hdr.overlay.0.valid := s2_hdr.overlay.1.valid;
    s2_isValid[s2_hdr.overlay.0] := s2_isValid[s2_hdr.overlay.1];
    s2_hdr.overlay.1.swip := s2_hdr.overlay.2.swip;
    s2_hdr.overlay.1.valid := s2_hdr.overlay.2.valid;
    s2_isValid[s2_hdr.overlay.1] := s2_isValid[s2_hdr.overlay.2];
    s2_hdr.overlay.2.swip := s2_hdr.overlay.3.swip;
    s2_hdr.overlay.2.valid := s2_hdr.overlay.3.valid;
    s2_isValid[s2_hdr.overlay.2] := s2_isValid[s2_hdr.overlay.3];
    s2_hdr.overlay.3.swip := s2_hdr.overlay.4.swip;
    s2_hdr.overlay.3.valid := s2_hdr.overlay.4.valid;
    s2_isValid[s2_hdr.overlay.3] := s2_isValid[s2_hdr.overlay.4];
    s2_hdr.overlay.4.swip := s2_hdr.overlay.5.swip;
    s2_hdr.overlay.4.valid := s2_hdr.overlay.5.valid;
    s2_isValid[s2_hdr.overlay.4] := s2_isValid[s2_hdr.overlay.5];
    s2_hdr.overlay.5.swip := s2_hdr.overlay.6.swip;
    s2_hdr.overlay.5.valid := s2_hdr.overlay.6.valid;
    s2_isValid[s2_hdr.overlay.5] := s2_isValid[s2_hdr.overlay.6];
    s2_hdr.overlay.6.swip := s2_hdr.overlay.7.swip;
    s2_hdr.overlay.6.valid := s2_hdr.overlay.7.valid;
    s2_isValid[s2_hdr.overlay.6] := s2_isValid[s2_hdr.overlay.7];
    s2_hdr.overlay.7.swip := s2_hdr.overlay.8.swip;
    s2_hdr.overlay.7.valid := s2_hdr.overlay.8.valid;
    s2_isValid[s2_hdr.overlay.7] := s2_isValid[s2_hdr.overlay.8];
    s2_hdr.overlay.8.swip := s2_hdr.overlay.9.swip;
    s2_hdr.overlay.8.valid := s2_hdr.overlay.9.valid;
    s2_isValid[s2_hdr.overlay.8] := s2_isValid[s2_hdr.overlay.9];
    s2_hdr.overlay.9.valid := false;
    s2_isValid[s2_hdr.overlay.9] := false;
    s2_hdr.udp.len := add.bv16(s2_hdr.udp.len, 65532bv16);
    s2_hdr.ipv4.totalLen := add.bv16(s2_hdr.ipv4.totalLen, 65532bv16);
}

// s2_Action s2_failover_write_reply_act
procedure {:inline 1} s2_failover_write_reply_act()
	modifies s2_hdr.ipv4.dstAddr, s2_hdr.ipv4.srcAddr, s2_hdr.nc_hdr.op, s2_hdr.udp.dstPort, s2_meta.reply_to_client_md.ipv4_dstAddr, s2_meta.reply_to_client_md.ipv4_srcAddr;
{
    s2_meta.reply_to_client_md.ipv4_srcAddr := s2_hdr.ipv4.dstAddr;
    s2_meta.reply_to_client_md.ipv4_dstAddr := s2_hdr.ipv4.srcAddr;
    s2_hdr.ipv4.srcAddr := s2_meta.reply_to_client_md.ipv4_srcAddr;
    s2_hdr.ipv4.dstAddr := s2_meta.reply_to_client_md.ipv4_dstAddr;
    s2_hdr.nc_hdr.op := 13bv8;
    s2_hdr.udp.dstPort := 8889bv16;
}

// s2_Table s2_failure_recovery
procedure {:inline 1} s2_failure_recovery.apply()
	modifies s2_failure_recovery.action_run, s2_failure_recovery.hit, s2_hdr.ipv4.dstAddr, s2_hdr.nc_hdr.vgroup, s2_hdr.overlay.1.swip;
{
    s2_hdr.ipv4.dstAddr := s2_hdr.ipv4.dstAddr;
    s2_hdr.overlay.1.swip := s2_hdr.overlay.1.swip;
    s2_hdr.nc_hdr.vgroup := s2_hdr.nc_hdr.vgroup;
    s2_failure_recovery.hit := false;
    s2_failure_recovery.action_run := s2_failure_recovery.action.nop;
    call s2_nop();
    goto s2_Exit;

    s2_Exit:
}

// s2_Action s2_failure_recovery_act
procedure {:inline 1} s2_failure_recovery_act(s2_nexthop:bv32)
	modifies s2_hdr.ipv4.dstAddr, s2_hdr.overlay.0.swip;
{
    s2_hdr.overlay.0.swip := s2_nexthop;
    s2_hdr.ipv4.dstAddr := s2_nexthop;
}

// s2_Table s2_find_index
procedure {:inline 1} s2_find_index.apply()
	modifies s2_find_index.action_run, s2_find_index.find_index_act.index_1, s2_find_index.hit, s2_hdr.nc_hdr.key, s2_meta.location.index;
{
    s2_hdr.nc_hdr.key := s2_hdr.nc_hdr.key;
    s2_find_index.hit := false;
    if(s2_hdr.nc_hdr.key == 2024bv128){
        s2_find_index.hit := true;
        s2_find_index.action_run := s2_find_index.action.find_index_act;
        s2_find_index.find_index_act.index_1 := 0bv16;
        call s2_find_index_act(s2_find_index.find_index_act.index_1);
        goto s2_Exit;
    }
    else if(s2_hdr.nc_hdr.key == 2025bv128){
        s2_find_index.hit := true;
        s2_find_index.action_run := s2_find_index.action.find_index_act;
        s2_find_index.find_index_act.index_1 := 1bv16;
        call s2_find_index_act(s2_find_index.find_index_act.index_1);
        goto s2_Exit;
    }
    else if(s2_hdr.nc_hdr.key == 2026bv128){
        s2_find_index.hit := true;
        s2_find_index.action_run := s2_find_index.action.find_index_act;
        s2_find_index.find_index_act.index_1 := 2bv16;
        call s2_find_index_act(s2_find_index.find_index_act.index_1);
        goto s2_Exit;
    }
    else if(s2_hdr.nc_hdr.key == 2027bv128){
        s2_find_index.hit := true;
        s2_find_index.action_run := s2_find_index.action.find_index_act;
        s2_find_index.find_index_act.index_1 := 3bv16;
        call s2_find_index_act(s2_find_index.find_index_act.index_1);
        goto s2_Exit;
    }
    else if(s2_hdr.nc_hdr.key == 2028bv128){
        s2_find_index.hit := true;
        s2_find_index.action_run := s2_find_index.action.find_index_act;
        s2_find_index.find_index_act.index_1 := 4bv16;
        call s2_find_index_act(s2_find_index.find_index_act.index_1);
        goto s2_Exit;
    }
    if(!s2_find_index.hit){
        s2_find_index.action_run := s2_find_index.action.NoAction_6;
        call s2_NoAction_6();
        goto s2_Exit;
    }

    s2_Exit:
}

// s2_Action s2_find_index_act
procedure {:inline 1} s2_find_index_act(s2_index_1:bv16)
	modifies s2_meta.location.index;
{
    s2_meta.location.index := s2_index_1;
}

// s2_Table s2_gen_reply
procedure {:inline 1} s2_gen_reply.apply()
	modifies s2_gen_reply.action_run, s2_gen_reply.gen_reply_act.message_type, s2_gen_reply.hit, s2_hdr.ipv4.dstAddr, s2_hdr.ipv4.srcAddr, s2_hdr.nc_hdr.op, s2_hdr.udp.dstPort, s2_meta.reply_to_client_md.ipv4_dstAddr, s2_meta.reply_to_client_md.ipv4_srcAddr;
{
    s2_hdr.nc_hdr.op := s2_hdr.nc_hdr.op;
    s2_gen_reply.hit := false;
    if(s2_hdr.nc_hdr.op == 10bv8){
        s2_gen_reply.hit := true;
        s2_gen_reply.action_run := s2_gen_reply.action.gen_reply_act;
        s2_gen_reply.gen_reply_act.message_type := 11bv8;
        call s2_gen_reply_act(s2_gen_reply.gen_reply_act.message_type);
        goto s2_Exit;
    }
    else if(s2_hdr.nc_hdr.op == 12bv8){
        s2_gen_reply.hit := true;
        s2_gen_reply.action_run := s2_gen_reply.action.gen_reply_act;
        s2_gen_reply.gen_reply_act.message_type := 13bv8;
        call s2_gen_reply_act(s2_gen_reply.gen_reply_act.message_type);
        goto s2_Exit;
    }
    if(!s2_gen_reply.hit){
        s2_gen_reply.action_run := s2_gen_reply.action.NoAction_7;
        call s2_NoAction_7();
        goto s2_Exit;
    }

    s2_Exit:
}

// s2_Action s2_gen_reply_act
procedure {:inline 1} s2_gen_reply_act(s2_message_type:bv8)
	modifies s2_hdr.ipv4.dstAddr, s2_hdr.ipv4.srcAddr, s2_hdr.nc_hdr.op, s2_hdr.udp.dstPort, s2_meta.reply_to_client_md.ipv4_dstAddr, s2_meta.reply_to_client_md.ipv4_srcAddr;
{
    s2_meta.reply_to_client_md.ipv4_srcAddr := s2_hdr.ipv4.dstAddr;
    s2_meta.reply_to_client_md.ipv4_dstAddr := s2_hdr.ipv4.srcAddr;
    s2_hdr.ipv4.srcAddr := s2_meta.reply_to_client_md.ipv4_srcAddr;
    s2_hdr.ipv4.dstAddr := s2_meta.reply_to_client_md.ipv4_dstAddr;
    s2_hdr.nc_hdr.op := s2_message_type;
    s2_hdr.udp.dstPort := 8889bv16;
}

// s2_Table s2_get_my_address
procedure {:inline 1} s2_get_my_address.apply()
	modifies s2_get_my_address.action_run, s2_get_my_address.get_my_address_act.sw_ip, s2_get_my_address.get_my_address_act.sw_role, s2_get_my_address.hit, s2_hdr.nc_hdr.key, s2_meta.my_md.ipaddress, s2_meta.my_md.role;
{
    s2_hdr.nc_hdr.key := s2_hdr.nc_hdr.key;
    s2_get_my_address.hit := false;
    s2_get_my_address.action_run := s2_get_my_address.action.get_my_address_act;
    s2_get_my_address.get_my_address_act.sw_ip := 167797762bv32;
    s2_get_my_address.get_my_address_act.sw_role := 101bv16;
    call s2_get_my_address_act(s2_get_my_address.get_my_address_act.sw_ip, s2_get_my_address.get_my_address_act.sw_role);
    goto s2_Exit;

    s2_Exit:
}

// s2_Action s2_get_my_address_act
procedure {:inline 1} s2_get_my_address_act(s2_sw_ip:bv32, s2_sw_role:bv16)
	modifies s2_meta.my_md.ipaddress, s2_meta.my_md.role;
{
    s2_meta.my_md.ipaddress := s2_sw_ip;
    s2_meta.my_md.role := s2_sw_role;
}

// s2_Table s2_get_next_hop
procedure {:inline 1} s2_get_next_hop.apply()
	modifies s2_get_next_hop.action_run, s2_get_next_hop.hit, s2_hdr.ipv4.dstAddr;
{
    s2_get_next_hop.hit := false;
    s2_get_next_hop.action_run := s2_get_next_hop.action.get_next_hop_act;
    call s2_get_next_hop_act();
    goto s2_Exit;

    s2_Exit:
}

// s2_Action s2_get_next_hop_act
procedure {:inline 1} s2_get_next_hop_act()
	modifies s2_hdr.ipv4.dstAddr;
{
    s2_hdr.ipv4.dstAddr := s2_hdr.overlay.0.swip;
}

// s2_Table s2_get_sequence
procedure {:inline 1} s2_get_sequence.apply()
	modifies s2_get_sequence.action_run, s2_get_sequence.hit, s2_meta.sequence_md.seq;
{
    s2_get_sequence.hit := false;
    s2_get_sequence.action_run := s2_get_sequence.action.get_sequence_act;
    call s2_get_sequence_act();
    goto s2_Exit;

    s2_Exit:
}

// s2_Action s2_get_sequence_act
procedure {:inline 1} s2_get_sequence_act()
	modifies s2_meta.sequence_md.seq;
{
    // s2_read
    s2_meta.sequence_md.seq := s2_sequence_reg.read(s2_sequence_reg, 0bv16++s2_meta.location.index);
}

// s2_Control s2_ingress
procedure {:inline 1} s2_ingress()
	modifies s2_assign_value.action_run, s2_assign_value.hit, s2_drop, s2_drop_packet.action_run, s2_drop_packet.hit, s2_failure_recovery.action_run, s2_failure_recovery.hit, s2_find_index.action_run, s2_find_index.find_index_act.index_1, s2_find_index.hit, s2_forward, s2_gen_reply.action_run, s2_gen_reply.gen_reply_act.message_type, s2_gen_reply.hit, s2_get_my_address.action_run, s2_get_my_address.get_my_address_act.sw_ip, s2_get_my_address.get_my_address_act.sw_role, s2_get_my_address.hit, s2_get_next_hop.action_run, s2_get_next_hop.hit, s2_get_sequence.action_run, s2_get_sequence.hit, s2_hdr.ipv4.dstAddr, s2_hdr.ipv4.srcAddr, s2_hdr.ipv4.totalLen, s2_hdr.ipv4.ttl, s2_hdr.nc_hdr.key, s2_hdr.nc_hdr.op, s2_hdr.nc_hdr.sc, s2_hdr.nc_hdr.seq, s2_hdr.nc_hdr.value, s2_hdr.nc_hdr.vgroup, s2_hdr.overlay.0.swip, s2_hdr.overlay.0.valid, s2_hdr.overlay.1.swip, s2_hdr.overlay.1.valid, s2_hdr.overlay.2.swip, s2_hdr.overlay.2.valid, s2_hdr.overlay.3.swip, s2_hdr.overlay.3.valid, s2_hdr.overlay.4.swip, s2_hdr.overlay.4.valid, s2_hdr.overlay.5.swip, s2_hdr.overlay.5.valid, s2_hdr.overlay.6.swip, s2_hdr.overlay.6.valid, s2_hdr.overlay.7.swip, s2_hdr.overlay.7.valid, s2_hdr.overlay.8.swip, s2_hdr.overlay.8.valid, s2_hdr.overlay.9.valid, s2_hdr.udp.dstPort, s2_hdr.udp.len, s2_ipv4_route.action_run, s2_ipv4_route.hit, s2_ipv4_route.set_egress.egress_spec_1, s2_isValid, s2_maintain_sequence.action_run, s2_maintain_sequence.hit, s2_meta.location.index, s2_meta.my_md.ipaddress, s2_meta.my_md.role, s2_meta.reply_to_client_md.ipv4_dstAddr, s2_meta.reply_to_client_md.ipv4_srcAddr, s2_meta.sequence_md.seq, s2_pop_chain.action_run, s2_pop_chain.hit, s2_pop_chain_again.action_run, s2_pop_chain_again.hit, s2_read_value.action_run, s2_read_value.hit, s2_sequence_reg, s2_sequence_reg__last0_old_value, s2_sequence_reg__last0_value, s2_sequence_reg__last_index, s2_sequence_reg__last_old_value, s2_sequence_reg__last_value, s2_sequence_reg__last_write_site, s2_sequence_reg__next_write_site, s2_sequence_reg__wrote_any, s2_sequence_reg__wrote_index0, s2_standard_metadata.egress_port, s2_standard_metadata.egress_spec, s2_value_reg, s2_value_reg__last0_old_value, s2_value_reg__last0_value, s2_value_reg__last_index, s2_value_reg__last_old_value, s2_value_reg__last_value, s2_value_reg__last_write_site, s2_value_reg__next_write_site, s2_value_reg__wrote_any, s2_value_reg__wrote_index0;
{
    if(s2_isValid[s2_hdr.nc_hdr]){
        call s2_get_my_address.apply();
        if((s2_hdr.ipv4.dstAddr == s2_meta.my_md.ipaddress)){
            call s2_find_index.apply();
            call s2_get_sequence.apply();
            if((s2_hdr.nc_hdr.op == 10bv8)){
                call s2_read_value.apply();
            }
            else{
                if((s2_hdr.nc_hdr.op == 12bv8)){
                    if((s2_meta.my_md.role == 100bv16)){
                        call s2_maintain_sequence.apply();
                    }
                    if(((s2_meta.my_md.role == 100bv16)) || (bugt.bv16(s2_hdr.nc_hdr.seq, s2_meta.sequence_md.seq))){
                        call s2_assign_value.apply();
                        call s2_pop_chain.apply();
                    }
                    else{
                        call s2_drop_packet.apply();
                    }
                }
            }
            if((s2_meta.my_md.role == 102bv16)){
                call s2_pop_chain_again.apply();
                call s2_gen_reply.apply();
            }
            else{
                call s2_get_next_hop.apply();
            }
        }
    }
    if(s2_isValid[s2_hdr.nc_hdr]){
        call s2_failure_recovery.apply();
    }
    if((s2_isValid[s2_hdr.tcp]) || (s2_isValid[s2_hdr.udp])){
        call s2_ipv4_route.apply();
    }
}

// s2_Table s2_ipv4_route
procedure {:inline 1} s2_ipv4_route.apply()
	modifies s2_forward, s2_hdr.ipv4.dstAddr, s2_hdr.ipv4.ttl, s2_ipv4_route.action_run, s2_ipv4_route.hit, s2_ipv4_route.set_egress.egress_spec_1, s2_standard_metadata.egress_port, s2_standard_metadata.egress_spec;
{
    s2_hdr.ipv4.dstAddr := s2_hdr.ipv4.dstAddr;
    s2_ipv4_route.hit := false;
    if(s2_hdr.ipv4.dstAddr == 167772161bv32){
        s2_ipv4_route.hit := true;
        s2_ipv4_route.action_run := s2_ipv4_route.action.set_egress;
        s2_ipv4_route.set_egress.egress_spec_1 := 1bv9;
        call s2_set_egress(s2_ipv4_route.set_egress.egress_spec_1);
        goto s2_Exit;
    }
    else if(s2_hdr.ipv4.dstAddr == 167772162bv32){
        s2_ipv4_route.hit := true;
        s2_ipv4_route.action_run := s2_ipv4_route.action.set_egress;
        s2_ipv4_route.set_egress.egress_spec_1 := 1bv9;
        call s2_set_egress(s2_ipv4_route.set_egress.egress_spec_1);
        goto s2_Exit;
    }
    else if(s2_hdr.ipv4.dstAddr == 167797761bv32){
        s2_ipv4_route.hit := true;
        s2_ipv4_route.action_run := s2_ipv4_route.action.set_egress;
        s2_ipv4_route.set_egress.egress_spec_1 := 2bv9;
        call s2_set_egress(s2_ipv4_route.set_egress.egress_spec_1);
        goto s2_Exit;
    }
    else if(s2_hdr.ipv4.dstAddr == 167797763bv32){
        s2_ipv4_route.hit := true;
        s2_ipv4_route.action_run := s2_ipv4_route.action.set_egress;
        s2_ipv4_route.set_egress.egress_spec_1 := 3bv9;
        call s2_set_egress(s2_ipv4_route.set_egress.egress_spec_1);
        goto s2_Exit;
    }
    else if(s2_hdr.ipv4.dstAddr == 167797764bv32){
        s2_ipv4_route.hit := true;
        s2_ipv4_route.action_run := s2_ipv4_route.action.set_egress;
        s2_ipv4_route.set_egress.egress_spec_1 := 1bv9;
        call s2_set_egress(s2_ipv4_route.set_egress.egress_spec_1);
        goto s2_Exit;
    }
    if(!s2_ipv4_route.hit){
        s2_ipv4_route.action_run := s2_ipv4_route.action.NoAction_11;
        call s2_NoAction_11();
        goto s2_Exit;
    }

    s2_Exit:
}
procedure {:inline 1} s2_main()
	modifies s2_assign_value.action_run, s2_assign_value.hit, s2_drop, s2_drop_packet.action_run, s2_drop_packet.hit, s2_ethernet_set_mac.action_run, s2_ethernet_set_mac.ethernet_set_mac_act.dmac, s2_ethernet_set_mac.ethernet_set_mac_act.smac, s2_ethernet_set_mac.hit, s2_failure_recovery.action_run, s2_failure_recovery.hit, s2_find_index.action_run, s2_find_index.find_index_act.index_1, s2_find_index.hit, s2_forward, s2_gen_reply.action_run, s2_gen_reply.gen_reply_act.message_type, s2_gen_reply.hit, s2_get_my_address.action_run, s2_get_my_address.get_my_address_act.sw_ip, s2_get_my_address.get_my_address_act.sw_role, s2_get_my_address.hit, s2_get_next_hop.action_run, s2_get_next_hop.hit, s2_get_sequence.action_run, s2_get_sequence.hit, s2_hdr.ethernet.dstAddr, s2_hdr.ethernet.srcAddr, s2_hdr.ipv4.dstAddr, s2_hdr.ipv4.hdrChecksum, s2_hdr.ipv4.protocol, s2_hdr.ipv4.srcAddr, s2_hdr.ipv4.totalLen, s2_hdr.ipv4.ttl, s2_hdr.nc_hdr.key, s2_hdr.nc_hdr.op, s2_hdr.nc_hdr.sc, s2_hdr.nc_hdr.seq, s2_hdr.nc_hdr.value, s2_hdr.nc_hdr.vgroup, s2_hdr.overlay.0.swip, s2_hdr.overlay.0.valid, s2_hdr.overlay.1.swip, s2_hdr.overlay.1.valid, s2_hdr.overlay.2.swip, s2_hdr.overlay.2.valid, s2_hdr.overlay.3.swip, s2_hdr.overlay.3.valid, s2_hdr.overlay.4.swip, s2_hdr.overlay.4.valid, s2_hdr.overlay.5.swip, s2_hdr.overlay.5.valid, s2_hdr.overlay.6.swip, s2_hdr.overlay.6.valid, s2_hdr.overlay.7.swip, s2_hdr.overlay.7.valid, s2_hdr.overlay.8.swip, s2_hdr.overlay.8.valid, s2_hdr.overlay.9.valid, s2_hdr.udp.checksum, s2_hdr.udp.dstPort, s2_hdr.udp.len, s2_ipv4_route.action_run, s2_ipv4_route.hit, s2_ipv4_route.set_egress.egress_spec_1, s2_isValid, s2_maintain_sequence.action_run, s2_maintain_sequence.hit, s2_meta.location.index, s2_meta.my_md.ipaddress, s2_meta.my_md.role, s2_meta.reply_to_client_md.ipv4_dstAddr, s2_meta.reply_to_client_md.ipv4_srcAddr, s2_meta.sequence_md.seq, s2_p4b_checksum_updated, s2_pop_chain.action_run, s2_pop_chain.hit, s2_pop_chain_again.action_run, s2_pop_chain_again.hit, s2_read_value.action_run, s2_read_value.hit, s2_sequence_reg, s2_sequence_reg__last0_old_value, s2_sequence_reg__last0_value, s2_sequence_reg__last_index, s2_sequence_reg__last_old_value, s2_sequence_reg__last_value, s2_sequence_reg__last_write_site, s2_sequence_reg__next_write_site, s2_sequence_reg__wrote_any, s2_sequence_reg__wrote_index0, s2_stack.index, s2_standard_metadata.egress_port, s2_standard_metadata.egress_spec, s2_value_reg, s2_value_reg__last0_old_value, s2_value_reg__last0_value, s2_value_reg__last_index, s2_value_reg__last_old_value, s2_value_reg__last_value, s2_value_reg__last_write_site, s2_value_reg__next_write_site, s2_value_reg__wrote_any, s2_value_reg__wrote_index0;
{
    call s2_ParserImpl();
    call s2_verifyChecksum();
    call s2_ingress();
    call s2_egress();
    call s2_computeChecksum();
    if(s2_forward == false){
        s2_drop := true;
    }
}
procedure s2_mainProcedure()
	modifies s2_assign_value.action_run, s2_assign_value.hit, s2_drop, s2_drop_packet.action_run, s2_drop_packet.hit, s2_ethernet_set_mac.action_run, s2_ethernet_set_mac.ethernet_set_mac_act.dmac, s2_ethernet_set_mac.ethernet_set_mac_act.smac, s2_ethernet_set_mac.hit, s2_failure_recovery.action_run, s2_failure_recovery.hit, s2_find_index.action_run, s2_find_index.find_index_act.index_1, s2_find_index.hit, s2_forward, s2_gen_reply.action_run, s2_gen_reply.gen_reply_act.message_type, s2_gen_reply.hit, s2_get_my_address.action_run, s2_get_my_address.get_my_address_act.sw_ip, s2_get_my_address.get_my_address_act.sw_role, s2_get_my_address.hit, s2_get_next_hop.action_run, s2_get_next_hop.hit, s2_get_sequence.action_run, s2_get_sequence.hit, s2_hdr.ethernet.dstAddr, s2_hdr.ethernet.srcAddr, s2_hdr.ipv4.dstAddr, s2_hdr.ipv4.hdrChecksum, s2_hdr.ipv4.protocol, s2_hdr.ipv4.srcAddr, s2_hdr.ipv4.totalLen, s2_hdr.ipv4.ttl, s2_hdr.nc_hdr.key, s2_hdr.nc_hdr.op, s2_hdr.nc_hdr.sc, s2_hdr.nc_hdr.seq, s2_hdr.nc_hdr.value, s2_hdr.nc_hdr.vgroup, s2_hdr.overlay.0.swip, s2_hdr.overlay.0.valid, s2_hdr.overlay.1.swip, s2_hdr.overlay.1.valid, s2_hdr.overlay.2.swip, s2_hdr.overlay.2.valid, s2_hdr.overlay.3.swip, s2_hdr.overlay.3.valid, s2_hdr.overlay.4.swip, s2_hdr.overlay.4.valid, s2_hdr.overlay.5.swip, s2_hdr.overlay.5.valid, s2_hdr.overlay.6.swip, s2_hdr.overlay.6.valid, s2_hdr.overlay.7.swip, s2_hdr.overlay.7.valid, s2_hdr.overlay.8.swip, s2_hdr.overlay.8.valid, s2_hdr.overlay.9.valid, s2_hdr.udp.checksum, s2_hdr.udp.dstPort, s2_hdr.udp.len, s2_ipv4_route.action_run, s2_ipv4_route.hit, s2_ipv4_route.set_egress.egress_spec_1, s2_isValid, s2_maintain_sequence.action_run, s2_maintain_sequence.hit, s2_meta.location.index, s2_meta.my_md.ipaddress, s2_meta.my_md.role, s2_meta.reply_to_client_md.ipv4_dstAddr, s2_meta.reply_to_client_md.ipv4_srcAddr, s2_meta.sequence_md.seq, s2_p4b_checksum_error, s2_p4b_checksum_updated, s2_p4b_checksum_verified, s2_p4b_clone_e2e, s2_p4b_clone_i2e, s2_p4b_clone_i2i, s2_p4b_digest, s2_p4b_recirculate, s2_pop_chain.action_run, s2_pop_chain.hit, s2_pop_chain_again.action_run, s2_pop_chain_again.hit, s2_read_value.action_run, s2_read_value.hit, s2_sequence_reg, s2_sequence_reg__last0_old_value, s2_sequence_reg__last0_value, s2_sequence_reg__last_index, s2_sequence_reg__last_old_value, s2_sequence_reg__last_value, s2_sequence_reg__last_write_site, s2_sequence_reg__next_write_site, s2_sequence_reg__wrote_any, s2_sequence_reg__wrote_index0, s2_stack.index, s2_standard_metadata.egress_port, s2_standard_metadata.egress_spec, s2_value_reg, s2_value_reg__last0_old_value, s2_value_reg__last0_value, s2_value_reg__last_index, s2_value_reg__last_old_value, s2_value_reg__last_value, s2_value_reg__last_write_site, s2_value_reg__next_write_site, s2_value_reg__wrote_any, s2_value_reg__wrote_index0;
{
    s2_p4b_checksum_error := false;
    s2_p4b_checksum_updated := false;
    s2_p4b_checksum_verified := false;
    s2_p4b_digest := false;
    s2_p4b_recirculate := false;
    s2_p4b_clone_i2i := false;
    s2_p4b_clone_e2e := false;
    s2_p4b_clone_i2e := false;
    call s2_main();
}

// s2_Table s2_maintain_sequence
procedure {:inline 1} s2_maintain_sequence.apply()
	modifies s2_hdr.nc_hdr.seq, s2_maintain_sequence.action_run, s2_maintain_sequence.hit, s2_meta.sequence_md.seq, s2_sequence_reg, s2_sequence_reg__last0_old_value, s2_sequence_reg__last0_value, s2_sequence_reg__last_index, s2_sequence_reg__last_old_value, s2_sequence_reg__last_value, s2_sequence_reg__last_write_site, s2_sequence_reg__next_write_site, s2_sequence_reg__wrote_any, s2_sequence_reg__wrote_index0;
{
    s2_maintain_sequence.hit := false;
    s2_maintain_sequence.action_run := s2_maintain_sequence.action.maintain_sequence_act;
    call s2_maintain_sequence_act();
    goto s2_Exit;

    s2_Exit:
}

// s2_Action s2_maintain_sequence_act
procedure {:inline 1} s2_maintain_sequence_act()
	modifies s2_hdr.nc_hdr.seq, s2_meta.sequence_md.seq, s2_sequence_reg, s2_sequence_reg__last0_old_value, s2_sequence_reg__last0_value, s2_sequence_reg__last_index, s2_sequence_reg__last_old_value, s2_sequence_reg__last_value, s2_sequence_reg__last_write_site, s2_sequence_reg__next_write_site, s2_sequence_reg__wrote_any, s2_sequence_reg__wrote_index0;
{
    s2_meta.sequence_md.seq := add.bv16(s2_meta.sequence_md.seq, 1bv16);
    // s2_write
    s2_sequence_reg__next_write_site := 2;
    call s2_sequence_reg.write(0bv16++s2_meta.location.index, s2_meta.sequence_md.seq);
    // s2_read
    s2_hdr.nc_hdr.seq := s2_sequence_reg.read(s2_sequence_reg, 0bv16++s2_meta.location.index);
}
procedure s2_mark_to_drop();
    ensures s2_drop==true;
	modifies s2_drop;

// s2_Action s2_nop
procedure {:inline 1} s2_nop()
{
}
procedure s2_packet.emit(s2_arg0:s2_Ref);
procedure s2_packet_in.extract(s2_header:s2_Ref);
    ensures (s2_isValid[s2_header] == true);
	modifies s2_isValid;
procedure {:inline 1} s2_packet_in.extract.headers.overlay.next(s2_stack:s2_HeaderStack);
ensures(s2_isValid[s2_stack[s2_stack.index[s2_stack]]]==true && s2_stack.index[s2_stack]==old(s2_stack.index[s2_stack])+1);
	modifies s2_isValid, s2_stack.index;

// s2_Table s2_pop_chain
procedure {:inline 1} s2_pop_chain.apply()
	modifies s2_hdr.ipv4.totalLen, s2_hdr.nc_hdr.sc, s2_hdr.overlay.0.swip, s2_hdr.overlay.0.valid, s2_hdr.overlay.1.swip, s2_hdr.overlay.1.valid, s2_hdr.overlay.2.swip, s2_hdr.overlay.2.valid, s2_hdr.overlay.3.swip, s2_hdr.overlay.3.valid, s2_hdr.overlay.4.swip, s2_hdr.overlay.4.valid, s2_hdr.overlay.5.swip, s2_hdr.overlay.5.valid, s2_hdr.overlay.6.swip, s2_hdr.overlay.6.valid, s2_hdr.overlay.7.swip, s2_hdr.overlay.7.valid, s2_hdr.overlay.8.swip, s2_hdr.overlay.8.valid, s2_hdr.overlay.9.valid, s2_hdr.udp.len, s2_isValid, s2_pop_chain.action_run, s2_pop_chain.hit;
{
    s2_pop_chain.hit := false;
    s2_pop_chain.action_run := s2_pop_chain.action.pop_chain_act;
    call s2_pop_chain_act();
    goto s2_Exit;

    s2_Exit:
}

// s2_Action s2_pop_chain_act
procedure {:inline 1} s2_pop_chain_act()
	modifies s2_hdr.ipv4.totalLen, s2_hdr.nc_hdr.sc, s2_hdr.overlay.0.swip, s2_hdr.overlay.0.valid, s2_hdr.overlay.1.swip, s2_hdr.overlay.1.valid, s2_hdr.overlay.2.swip, s2_hdr.overlay.2.valid, s2_hdr.overlay.3.swip, s2_hdr.overlay.3.valid, s2_hdr.overlay.4.swip, s2_hdr.overlay.4.valid, s2_hdr.overlay.5.swip, s2_hdr.overlay.5.valid, s2_hdr.overlay.6.swip, s2_hdr.overlay.6.valid, s2_hdr.overlay.7.swip, s2_hdr.overlay.7.valid, s2_hdr.overlay.8.swip, s2_hdr.overlay.8.valid, s2_hdr.overlay.9.valid, s2_hdr.udp.len, s2_isValid;
{
    s2_hdr.nc_hdr.sc := add.bv8(s2_hdr.nc_hdr.sc, 255bv8);
    // s2_pop_front
    s2_hdr.overlay.0.swip := s2_hdr.overlay.1.swip;
    s2_hdr.overlay.0.valid := s2_hdr.overlay.1.valid;
    s2_isValid[s2_hdr.overlay.0] := s2_isValid[s2_hdr.overlay.1];
    s2_hdr.overlay.1.swip := s2_hdr.overlay.2.swip;
    s2_hdr.overlay.1.valid := s2_hdr.overlay.2.valid;
    s2_isValid[s2_hdr.overlay.1] := s2_isValid[s2_hdr.overlay.2];
    s2_hdr.overlay.2.swip := s2_hdr.overlay.3.swip;
    s2_hdr.overlay.2.valid := s2_hdr.overlay.3.valid;
    s2_isValid[s2_hdr.overlay.2] := s2_isValid[s2_hdr.overlay.3];
    s2_hdr.overlay.3.swip := s2_hdr.overlay.4.swip;
    s2_hdr.overlay.3.valid := s2_hdr.overlay.4.valid;
    s2_isValid[s2_hdr.overlay.3] := s2_isValid[s2_hdr.overlay.4];
    s2_hdr.overlay.4.swip := s2_hdr.overlay.5.swip;
    s2_hdr.overlay.4.valid := s2_hdr.overlay.5.valid;
    s2_isValid[s2_hdr.overlay.4] := s2_isValid[s2_hdr.overlay.5];
    s2_hdr.overlay.5.swip := s2_hdr.overlay.6.swip;
    s2_hdr.overlay.5.valid := s2_hdr.overlay.6.valid;
    s2_isValid[s2_hdr.overlay.5] := s2_isValid[s2_hdr.overlay.6];
    s2_hdr.overlay.6.swip := s2_hdr.overlay.7.swip;
    s2_hdr.overlay.6.valid := s2_hdr.overlay.7.valid;
    s2_isValid[s2_hdr.overlay.6] := s2_isValid[s2_hdr.overlay.7];
    s2_hdr.overlay.7.swip := s2_hdr.overlay.8.swip;
    s2_hdr.overlay.7.valid := s2_hdr.overlay.8.valid;
    s2_isValid[s2_hdr.overlay.7] := s2_isValid[s2_hdr.overlay.8];
    s2_hdr.overlay.8.swip := s2_hdr.overlay.9.swip;
    s2_hdr.overlay.8.valid := s2_hdr.overlay.9.valid;
    s2_isValid[s2_hdr.overlay.8] := s2_isValid[s2_hdr.overlay.9];
    s2_hdr.overlay.9.valid := false;
    s2_isValid[s2_hdr.overlay.9] := false;
    s2_hdr.udp.len := add.bv16(s2_hdr.udp.len, 65532bv16);
    s2_hdr.ipv4.totalLen := add.bv16(s2_hdr.ipv4.totalLen, 65532bv16);
}

// s2_Table s2_pop_chain_again
procedure {:inline 1} s2_pop_chain_again.apply()
	modifies s2_hdr.ipv4.totalLen, s2_hdr.nc_hdr.sc, s2_hdr.overlay.0.swip, s2_hdr.overlay.0.valid, s2_hdr.overlay.1.swip, s2_hdr.overlay.1.valid, s2_hdr.overlay.2.swip, s2_hdr.overlay.2.valid, s2_hdr.overlay.3.swip, s2_hdr.overlay.3.valid, s2_hdr.overlay.4.swip, s2_hdr.overlay.4.valid, s2_hdr.overlay.5.swip, s2_hdr.overlay.5.valid, s2_hdr.overlay.6.swip, s2_hdr.overlay.6.valid, s2_hdr.overlay.7.swip, s2_hdr.overlay.7.valid, s2_hdr.overlay.8.swip, s2_hdr.overlay.8.valid, s2_hdr.overlay.9.valid, s2_hdr.udp.len, s2_isValid, s2_pop_chain_again.action_run, s2_pop_chain_again.hit;
{
    s2_pop_chain_again.hit := false;
    s2_pop_chain_again.action_run := s2_pop_chain_again.action.NoAction_14;
    call s2_NoAction_14();
    goto s2_Exit;

    s2_action_pop_chain_act:
    assume s2_pop_chain_again.action_run == s2_pop_chain_again.action.pop_chain_act;
    call s2_pop_chain_act();
    goto s2_Exit;

    s2_Exit:
}

// s2_Table s2_read_value
procedure {:inline 1} s2_read_value.apply()
	modifies s2_hdr.nc_hdr.value, s2_read_value.action_run, s2_read_value.hit;
{
    s2_read_value.hit := false;
    s2_read_value.action_run := s2_read_value.action.read_value_act;
    call s2_read_value_act();
    goto s2_Exit;

    s2_Exit:
}

// s2_Action s2_read_value_act
procedure {:inline 1} s2_read_value_act()
	modifies s2_hdr.nc_hdr.value;
{
    // s2_read
    s2_hdr.nc_hdr.value := s2_value_reg.read(s2_value_reg, 0bv16++s2_meta.location.index);
}
procedure s2_reject();
    ensures s2_drop==true;
	modifies s2_drop;
function {:inline true}s2_sequence_reg.read(s2_reg:[bv32]bv16, s2_index:bv32)returns (bv16) {s2_reg[s2_index]}
procedure {:inline 1} s2_sequence_reg.write(s2_index:bv32, s2_value:bv16)
	modifies s2_sequence_reg, s2_sequence_reg__last0_old_value, s2_sequence_reg__last0_value, s2_sequence_reg__last_index, s2_sequence_reg__last_old_value, s2_sequence_reg__last_value, s2_sequence_reg__last_write_site, s2_sequence_reg__wrote_any, s2_sequence_reg__wrote_index0;
{
    s2_sequence_reg__last_old_value := s2_sequence_reg[s2_index];
    s2_sequence_reg[s2_index] := s2_value;
    s2_sequence_reg__last_index := s2_index;
    s2_sequence_reg__last_value := s2_value;
    s2_sequence_reg__last_write_site := s2_sequence_reg__next_write_site;
    s2_sequence_reg__wrote_any := true;
    if (s2_index == 0bv32) {
        s2_sequence_reg__wrote_index0 := true;
        s2_sequence_reg__last0_old_value := s2_sequence_reg__last_old_value;
        s2_sequence_reg__last0_value := s2_value;
    }
}
procedure {:inline 1} s2_setInvalid(s2_header:s2_Ref);
    ensures (s2_isValid[s2_header] == false);
	modifies s2_isValid;
procedure {:inline 1} s2_setValid(s2_header:s2_Ref);

// s2_Action s2_set_egress
procedure {:inline 1} s2_set_egress(s2_egress_spec_1:bv9)
	modifies s2_forward, s2_hdr.ipv4.ttl, s2_standard_metadata.egress_port, s2_standard_metadata.egress_spec;
{
    s2_standard_metadata.egress_spec := s2_egress_spec_1;
    s2_standard_metadata.egress_port := s2_egress_spec_1;
    s2_forward := true;
    s2_hdr.ipv4.ttl := add.bv8(s2_hdr.ipv4.ttl, 255bv8);
}
function {:inline true}s2_value_reg.read(s2_reg:[bv32]bv128, s2_index:bv32)returns (bv128) {s2_reg[s2_index]}
procedure {:inline 1} s2_value_reg.write(s2_index:bv32, s2_value:bv128)
	modifies s2_value_reg, s2_value_reg__last0_old_value, s2_value_reg__last0_value, s2_value_reg__last_index, s2_value_reg__last_old_value, s2_value_reg__last_value, s2_value_reg__last_write_site, s2_value_reg__wrote_any, s2_value_reg__wrote_index0;
{
    s2_value_reg__last_old_value := s2_value_reg[s2_index];
    s2_value_reg[s2_index] := s2_value;
    s2_value_reg__last_index := s2_index;
    s2_value_reg__last_value := s2_value;
    s2_value_reg__last_write_site := s2_value_reg__next_write_site;
    s2_value_reg__wrote_any := true;
    if (s2_index == 0bv32) {
        s2_value_reg__wrote_index0 := true;
        s2_value_reg__last0_old_value := s2_value_reg__last_old_value;
        s2_value_reg__last0_value := s2_value;
    }
}

// s2_Control s2_verifyChecksum
procedure {:inline 1} s2_verifyChecksum()
{
}
// ===== END NODE s2 =====

// ===== BEGIN ENQUEUE PROCEDURES =====
procedure s1__enqueue_s2() returns()
  modifies s2_hdr.ethernet.dstAddr, s2_hdr.ethernet.etherType, s2_hdr.ethernet.srcAddr, s2_hdr.ethernet.valid, s2_hdr.ipv4.diffserv, s2_hdr.ipv4.dstAddr, s2_hdr.ipv4.flags, s2_hdr.ipv4.fragOffset, s2_hdr.ipv4.hdrChecksum, s2_hdr.ipv4.identification, s2_hdr.ipv4.ihl, s2_hdr.ipv4.protocol, s2_hdr.ipv4.srcAddr, s2_hdr.ipv4.totalLen, s2_hdr.ipv4.ttl, s2_hdr.ipv4.valid, s2_hdr.ipv4.version, s2_hdr.nc_hdr.key, s2_hdr.nc_hdr.op, s2_hdr.nc_hdr.sc, s2_hdr.nc_hdr.seq, s2_hdr.nc_hdr.valid, s2_hdr.nc_hdr.value, s2_hdr.nc_hdr.vgroup, s2_hdr.overlay.0.swip, s2_hdr.overlay.0.valid, s2_hdr.overlay.1.swip, s2_hdr.overlay.1.valid, s2_hdr.overlay.2.swip, s2_hdr.overlay.2.valid, s2_hdr.overlay.3.swip, s2_hdr.overlay.3.valid, s2_hdr.overlay.4.swip, s2_hdr.overlay.4.valid, s2_hdr.overlay.5.swip, s2_hdr.overlay.5.valid, s2_hdr.overlay.6.swip, s2_hdr.overlay.6.valid, s2_hdr.overlay.7.swip, s2_hdr.overlay.7.valid, s2_hdr.overlay.8.swip, s2_hdr.overlay.8.valid, s2_hdr.overlay.9.swip, s2_hdr.overlay.9.valid, s2_hdr.overlay.last.swip, s2_hdr.overlay.last.valid, s2_hdr.tcp.ackNo, s2_hdr.tcp.checksum, s2_hdr.tcp.ctrl, s2_hdr.tcp.dataOffset, s2_hdr.tcp.dstPort, s2_hdr.tcp.ecn, s2_hdr.tcp.res, s2_hdr.tcp.seqNo, s2_hdr.tcp.srcPort, s2_hdr.tcp.urgentPtr, s2_hdr.tcp.valid, s2_hdr.tcp.window, s2_hdr.udp.checksum, s2_hdr.udp.dstPort, s2_hdr.udp.len, s2_hdr.udp.srcPort, s2_hdr.udp.valid, s2_inbox_count, s2_pkt_external;
{
  assume s2_inbox_count < 1;
  s2_hdr.ethernet.valid := s1_hdr.ethernet.valid;
  s2_hdr.ethernet.dstAddr := s1_hdr.ethernet.dstAddr;
  s2_hdr.ethernet.srcAddr := s1_hdr.ethernet.srcAddr;
  s2_hdr.ethernet.etherType := s1_hdr.ethernet.etherType;
  s2_hdr.ipv4.valid := s1_hdr.ipv4.valid;
  s2_hdr.ipv4.version := s1_hdr.ipv4.version;
  s2_hdr.ipv4.ihl := s1_hdr.ipv4.ihl;
  s2_hdr.ipv4.diffserv := s1_hdr.ipv4.diffserv;
  s2_hdr.ipv4.totalLen := s1_hdr.ipv4.totalLen;
  s2_hdr.ipv4.identification := s1_hdr.ipv4.identification;
  s2_hdr.ipv4.flags := s1_hdr.ipv4.flags;
  s2_hdr.ipv4.fragOffset := s1_hdr.ipv4.fragOffset;
  s2_hdr.ipv4.ttl := s1_hdr.ipv4.ttl;
  s2_hdr.ipv4.protocol := s1_hdr.ipv4.protocol;
  s2_hdr.ipv4.hdrChecksum := s1_hdr.ipv4.hdrChecksum;
  s2_hdr.ipv4.srcAddr := s1_hdr.ipv4.srcAddr;
  s2_hdr.ipv4.dstAddr := s1_hdr.ipv4.dstAddr;
  s2_hdr.nc_hdr.valid := s1_hdr.nc_hdr.valid;
  s2_hdr.nc_hdr.op := s1_hdr.nc_hdr.op;
  s2_hdr.nc_hdr.sc := s1_hdr.nc_hdr.sc;
  s2_hdr.nc_hdr.seq := s1_hdr.nc_hdr.seq;
  s2_hdr.nc_hdr.key := s1_hdr.nc_hdr.key;
  s2_hdr.nc_hdr.value := s1_hdr.nc_hdr.value;
  s2_hdr.nc_hdr.vgroup := s1_hdr.nc_hdr.vgroup;
  s2_hdr.tcp.valid := s1_hdr.tcp.valid;
  s2_hdr.tcp.srcPort := s1_hdr.tcp.srcPort;
  s2_hdr.tcp.dstPort := s1_hdr.tcp.dstPort;
  s2_hdr.tcp.seqNo := s1_hdr.tcp.seqNo;
  s2_hdr.tcp.ackNo := s1_hdr.tcp.ackNo;
  s2_hdr.tcp.dataOffset := s1_hdr.tcp.dataOffset;
  s2_hdr.tcp.res := s1_hdr.tcp.res;
  s2_hdr.tcp.ecn := s1_hdr.tcp.ecn;
  s2_hdr.tcp.ctrl := s1_hdr.tcp.ctrl;
  s2_hdr.tcp.window := s1_hdr.tcp.window;
  s2_hdr.tcp.checksum := s1_hdr.tcp.checksum;
  s2_hdr.tcp.urgentPtr := s1_hdr.tcp.urgentPtr;
  s2_hdr.udp.valid := s1_hdr.udp.valid;
  s2_hdr.udp.srcPort := s1_hdr.udp.srcPort;
  s2_hdr.udp.dstPort := s1_hdr.udp.dstPort;
  s2_hdr.udp.len := s1_hdr.udp.len;
  s2_hdr.udp.checksum := s1_hdr.udp.checksum;
  s2_hdr.overlay.last.valid := s1_hdr.overlay.last.valid;
  s2_hdr.overlay.last.swip := s1_hdr.overlay.last.swip;
  s2_hdr.overlay.0.valid := s1_hdr.overlay.0.valid;
  s2_hdr.overlay.0.swip := s1_hdr.overlay.0.swip;
  s2_hdr.overlay.1.valid := s1_hdr.overlay.1.valid;
  s2_hdr.overlay.1.swip := s1_hdr.overlay.1.swip;
  s2_hdr.overlay.2.valid := s1_hdr.overlay.2.valid;
  s2_hdr.overlay.2.swip := s1_hdr.overlay.2.swip;
  s2_hdr.overlay.3.valid := s1_hdr.overlay.3.valid;
  s2_hdr.overlay.3.swip := s1_hdr.overlay.3.swip;
  s2_hdr.overlay.4.valid := s1_hdr.overlay.4.valid;
  s2_hdr.overlay.4.swip := s1_hdr.overlay.4.swip;
  s2_hdr.overlay.5.valid := s1_hdr.overlay.5.valid;
  s2_hdr.overlay.5.swip := s1_hdr.overlay.5.swip;
  s2_hdr.overlay.6.valid := s1_hdr.overlay.6.valid;
  s2_hdr.overlay.6.swip := s1_hdr.overlay.6.swip;
  s2_hdr.overlay.7.valid := s1_hdr.overlay.7.valid;
  s2_hdr.overlay.7.swip := s1_hdr.overlay.7.swip;
  s2_hdr.overlay.8.valid := s1_hdr.overlay.8.valid;
  s2_hdr.overlay.8.swip := s1_hdr.overlay.8.swip;
  s2_hdr.overlay.9.valid := s1_hdr.overlay.9.valid;
  s2_hdr.overlay.9.swip := s1_hdr.overlay.9.swip;
  s2_pkt_external := false;
  s2_inbox_count := s2_inbox_count + 1;
}

// ===== END ENQUEUE PROCEDURES =====

// ===== BEGIN HARNESS =====
// Auto-generated by Procurator (DSL -> Boogie harness: sequential scheduler)
// Message abstraction: Bag(K=1) using inbox_count per node; single-slot mailbox for packet fields

var procurator_step: int;
var procurator_phase: int;

// Register debug snapshots (for trace inspection)
var s1_sequence_reg__dbg0: bv16;
var s1_sequence_reg__last_index__dbg: bv32;
var s1_sequence_reg__last_value__dbg: bv16;
var s1_sequence_reg__last_old_value__dbg: bv16;
var s1_sequence_reg__wrote_any__dbg: bool;
var s1_sequence_reg__wrote_index0__dbg: bool;
var s1_sequence_reg__last0_old_value__dbg: bv16;
var s1_sequence_reg__last0_value__dbg: bv16;
var s1_value_reg__dbg0: bv128;
var s1_value_reg__last_index__dbg: bv32;
var s1_value_reg__last_value__dbg: bv128;
var s1_value_reg__last_old_value__dbg: bv128;
var s1_value_reg__wrote_any__dbg: bool;
var s1_value_reg__wrote_index0__dbg: bool;
var s1_value_reg__last0_old_value__dbg: bv128;
var s1_value_reg__last0_value__dbg: bv128;
var s2_sequence_reg__dbg0: bv16;
var s2_sequence_reg__last_index__dbg: bv32;
var s2_sequence_reg__last_value__dbg: bv16;
var s2_sequence_reg__last_old_value__dbg: bv16;
var s2_sequence_reg__wrote_any__dbg: bool;
var s2_sequence_reg__wrote_index0__dbg: bool;
var s2_sequence_reg__last0_old_value__dbg: bv16;
var s2_sequence_reg__last0_value__dbg: bv16;
var s2_value_reg__dbg0: bv128;
var s2_value_reg__last_index__dbg: bv32;
var s2_value_reg__last_value__dbg: bv128;
var s2_value_reg__last_old_value__dbg: bv128;
var s2_value_reg__wrote_any__dbg: bool;
var s2_value_reg__wrote_index0__dbg: bool;
var s2_value_reg__last0_old_value__dbg: bv128;
var s2_value_reg__last0_value__dbg: bv128;

var s1_inbox_count: int;
var s2_inbox_count: int;
var h1_inbox_count: int;

var s1_pkt_external: bool;
var s2_pkt_external: bool;
var h1_pkt_external: bool;

// Host packet fields (mirrors connected node symbols)
var h1_standard_metadata.ingress_port: bv9;
var h1_standard_metadata.instance_type: bv32;
var h1_standard_metadata.packet_length: bv32;
var h1_standard_metadata.enq_timestamp: bv32;
var h1_standard_metadata.enq_qdepth: bv19;
var h1_standard_metadata.deq_timedelta: bv32;
var h1_standard_metadata.deq_qdepth: bv19;
var h1_standard_metadata.ingress_global_timestamp: bv48;
var h1_standard_metadata.egress_global_timestamp: bv48;
var h1_standard_metadata.mcast_grp: bv16;
var h1_standard_metadata.egress_rid: bv16;
var h1_standard_metadata.checksum_error: bv1;
var h1_standard_metadata.parser_error: s1_error;
var h1_standard_metadata.priority: bv3;
var h1_meta.location: s1_location_t;
var h1_meta.location.index: bv16;
var h1_meta.my_md: s1_my_md_t;
var h1_meta.my_md.ipaddress: bv32;
var h1_meta.my_md.role: bv16;
var h1_meta.my_md.failed: bv16;
var h1_meta.reply_to_client_md: s1_reply_addr_t;
var h1_meta.reply_to_client_md.ipv4_srcAddr: bv32;
var h1_meta.reply_to_client_md.ipv4_dstAddr: bv32;
var h1_meta.sequence_md: s1_sequence_md_t;
var h1_meta.sequence_md.seq: bv16;
var h1_meta.sequence_md.tmp: bv16;
var h1_hdr.ethernet.valid: bool;
var h1_hdr.ethernet.dstAddr: bv48;
var h1_hdr.ethernet.srcAddr: bv48;
var h1_hdr.ethernet.etherType: bv16;
var h1_hdr.ipv4.valid: bool;
var h1_hdr.ipv4.version: bv4;
var h1_hdr.ipv4.ihl: bv4;
var h1_hdr.ipv4.diffserv: bv8;
var h1_hdr.ipv4.totalLen: bv16;
var h1_hdr.ipv4.identification: bv16;
var h1_hdr.ipv4.flags: bv3;
var h1_hdr.ipv4.fragOffset: bv13;
var h1_hdr.ipv4.ttl: bv8;
var h1_hdr.ipv4.protocol: bv8;
var h1_hdr.ipv4.hdrChecksum: bv16;
var h1_hdr.ipv4.srcAddr: bv32;
var h1_hdr.ipv4.dstAddr: bv32;
var h1_hdr.nc_hdr.valid: bool;
var h1_hdr.nc_hdr.op: bv8;
var h1_hdr.nc_hdr.sc: bv8;
var h1_hdr.nc_hdr.seq: bv16;
var h1_hdr.nc_hdr.key: bv128;
var h1_hdr.nc_hdr.value: bv128;
var h1_hdr.nc_hdr.vgroup: bv16;
var h1_hdr.tcp.valid: bool;
var h1_hdr.tcp.srcPort: bv16;
var h1_hdr.tcp.dstPort: bv16;
var h1_hdr.tcp.seqNo: bv32;
var h1_hdr.tcp.ackNo: bv32;
var h1_hdr.tcp.dataOffset: bv4;
var h1_hdr.tcp.res: bv3;
var h1_hdr.tcp.ecn: bv3;
var h1_hdr.tcp.ctrl: bv6;
var h1_hdr.tcp.window: bv16;
var h1_hdr.tcp.checksum: bv16;
var h1_hdr.tcp.urgentPtr: bv16;
var h1_hdr.udp.valid: bool;
var h1_hdr.udp.srcPort: bv16;
var h1_hdr.udp.dstPort: bv16;
var h1_hdr.udp.len: bv16;
var h1_hdr.udp.checksum: bv16;
var h1_hdr.overlay.last.valid: bool;
var h1_hdr.overlay.last.swip: bv32;
var h1_hdr.overlay.0.valid: bool;
var h1_hdr.overlay.0.swip: bv32;
var h1_hdr.overlay.1.valid: bool;
var h1_hdr.overlay.1.swip: bv32;
var h1_hdr.overlay.2.valid: bool;
var h1_hdr.overlay.2.swip: bv32;
var h1_hdr.overlay.3.valid: bool;
var h1_hdr.overlay.3.swip: bv32;
var h1_hdr.overlay.4.valid: bool;
var h1_hdr.overlay.4.swip: bv32;
var h1_hdr.overlay.5.valid: bool;
var h1_hdr.overlay.5.swip: bv32;
var h1_hdr.overlay.6.valid: bool;
var h1_hdr.overlay.6.swip: bv32;
var h1_hdr.overlay.7.valid: bool;
var h1_hdr.overlay.7.swip: bv32;
var h1_hdr.overlay.8.valid: bool;
var h1_hdr.overlay.8.swip: bv32;
var h1_hdr.overlay.9.valid: bool;
var h1_hdr.overlay.9.swip: bv32;

// Forwarding (derived from DSL topology)
procedure s1_Forward() returns()
  modifies s2_hdr.ethernet.dstAddr, s2_hdr.ethernet.etherType, s2_hdr.ethernet.srcAddr, s2_hdr.ethernet.valid, s2_hdr.ipv4.diffserv, s2_hdr.ipv4.dstAddr, s2_hdr.ipv4.flags, s2_hdr.ipv4.fragOffset, s2_hdr.ipv4.hdrChecksum, s2_hdr.ipv4.identification, s2_hdr.ipv4.ihl, s2_hdr.ipv4.protocol, s2_hdr.ipv4.srcAddr, s2_hdr.ipv4.totalLen, s2_hdr.ipv4.ttl, s2_hdr.ipv4.valid, s2_hdr.ipv4.version, s2_hdr.nc_hdr.key, s2_hdr.nc_hdr.op, s2_hdr.nc_hdr.sc, s2_hdr.nc_hdr.seq, s2_hdr.nc_hdr.valid, s2_hdr.nc_hdr.value, s2_hdr.nc_hdr.vgroup, s2_hdr.overlay.0.swip, s2_hdr.overlay.0.valid, s2_hdr.overlay.1.swip, s2_hdr.overlay.1.valid, s2_hdr.overlay.2.swip, s2_hdr.overlay.2.valid, s2_hdr.overlay.3.swip, s2_hdr.overlay.3.valid, s2_hdr.overlay.4.swip, s2_hdr.overlay.4.valid, s2_hdr.overlay.5.swip, s2_hdr.overlay.5.valid, s2_hdr.overlay.6.swip, s2_hdr.overlay.6.valid, s2_hdr.overlay.7.swip, s2_hdr.overlay.7.valid, s2_hdr.overlay.8.swip, s2_hdr.overlay.8.valid, s2_hdr.overlay.9.swip, s2_hdr.overlay.9.valid, s2_hdr.overlay.last.swip, s2_hdr.overlay.last.valid, s2_hdr.tcp.ackNo, s2_hdr.tcp.checksum, s2_hdr.tcp.ctrl, s2_hdr.tcp.dataOffset, s2_hdr.tcp.dstPort, s2_hdr.tcp.ecn, s2_hdr.tcp.res, s2_hdr.tcp.seqNo, s2_hdr.tcp.srcPort, s2_hdr.tcp.urgentPtr, s2_hdr.tcp.valid, s2_hdr.tcp.window, s2_hdr.udp.checksum, s2_hdr.udp.dstPort, s2_hdr.udp.len, s2_hdr.udp.srcPort, s2_hdr.udp.valid, s2_inbox_count, s2_pkt_external;
{
  // If no forwarding decision was made, do nothing.
  if (s1_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // wildcard forwarding (ALL): broadcast to all configured downstream mailboxes.
  call s1__enqueue_s2();
  return;
}

procedure s2_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (s2_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure main() returns()
  modifies h1_hdr.ethernet.dstAddr, h1_hdr.ethernet.etherType, h1_hdr.ethernet.srcAddr, h1_hdr.ethernet.valid, h1_hdr.ipv4.diffserv, h1_hdr.ipv4.dstAddr, h1_hdr.ipv4.flags, h1_hdr.ipv4.fragOffset, h1_hdr.ipv4.hdrChecksum, h1_hdr.ipv4.identification, h1_hdr.ipv4.ihl, h1_hdr.ipv4.protocol, h1_hdr.ipv4.srcAddr, h1_hdr.ipv4.totalLen, h1_hdr.ipv4.ttl, h1_hdr.ipv4.valid, h1_hdr.ipv4.version, h1_hdr.nc_hdr.key, h1_hdr.nc_hdr.op, h1_hdr.nc_hdr.sc, h1_hdr.nc_hdr.seq, h1_hdr.nc_hdr.valid, h1_hdr.nc_hdr.value, h1_hdr.nc_hdr.vgroup, h1_hdr.overlay.0.swip, h1_hdr.overlay.0.valid, h1_hdr.overlay.1.swip, h1_hdr.overlay.1.valid, h1_hdr.overlay.2.swip, h1_hdr.overlay.2.valid, h1_hdr.overlay.3.swip, h1_hdr.overlay.3.valid, h1_hdr.overlay.4.swip, h1_hdr.overlay.4.valid, h1_hdr.overlay.5.swip, h1_hdr.overlay.5.valid, h1_hdr.overlay.6.swip, h1_hdr.overlay.6.valid, h1_hdr.overlay.7.swip, h1_hdr.overlay.7.valid, h1_hdr.overlay.8.swip, h1_hdr.overlay.8.valid, h1_hdr.overlay.9.swip, h1_hdr.overlay.9.valid, h1_hdr.overlay.last.swip, h1_hdr.overlay.last.valid, h1_hdr.tcp.ackNo, h1_hdr.tcp.checksum, h1_hdr.tcp.ctrl, h1_hdr.tcp.dataOffset, h1_hdr.tcp.dstPort, h1_hdr.tcp.ecn, h1_hdr.tcp.res, h1_hdr.tcp.seqNo, h1_hdr.tcp.srcPort, h1_hdr.tcp.urgentPtr, h1_hdr.tcp.valid, h1_hdr.tcp.window, h1_hdr.udp.checksum, h1_hdr.udp.dstPort, h1_hdr.udp.len, h1_hdr.udp.srcPort, h1_hdr.udp.valid, h1_inbox_count, h1_meta.location, h1_meta.location.index, h1_meta.my_md, h1_meta.my_md.failed, h1_meta.my_md.ipaddress, h1_meta.my_md.role, h1_meta.reply_to_client_md, h1_meta.reply_to_client_md.ipv4_dstAddr, h1_meta.reply_to_client_md.ipv4_srcAddr, h1_meta.sequence_md, h1_meta.sequence_md.seq, h1_meta.sequence_md.tmp, h1_pkt_external, h1_standard_metadata.checksum_error, h1_standard_metadata.deq_qdepth, h1_standard_metadata.deq_timedelta, h1_standard_metadata.egress_global_timestamp, h1_standard_metadata.egress_rid, h1_standard_metadata.enq_qdepth, h1_standard_metadata.enq_timestamp, h1_standard_metadata.ingress_global_timestamp, h1_standard_metadata.ingress_port, h1_standard_metadata.instance_type, h1_standard_metadata.mcast_grp, h1_standard_metadata.packet_length, h1_standard_metadata.parser_error, h1_standard_metadata.priority, procurator_phase, procurator_step, s1_assign_value.action_run, s1_assign_value.hit, s1_drop, s1_drop_packet.action_run, s1_drop_packet.hit, s1_ethernet_set_mac.action_run, s1_ethernet_set_mac.ethernet_set_mac_act.dmac, s1_ethernet_set_mac.ethernet_set_mac_act.smac, s1_ethernet_set_mac.hit, s1_failure_recovery.action_run, s1_failure_recovery.hit, s1_find_index.action_run, s1_find_index.find_index_act.index_1, s1_find_index.hit, s1_forward, s1_gen_reply.action_run, s1_gen_reply.gen_reply_act.message_type, s1_gen_reply.hit, s1_get_my_address.action_run, s1_get_my_address.get_my_address_act.sw_ip, s1_get_my_address.get_my_address_act.sw_role, s1_get_my_address.hit, s1_get_next_hop.action_run, s1_get_next_hop.hit, s1_get_sequence.action_run, s1_get_sequence.hit, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.etherType, s1_hdr.ethernet.srcAddr, s1_hdr.ethernet.valid, s1_hdr.ipv4.diffserv, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.flags, s1_hdr.ipv4.fragOffset, s1_hdr.ipv4.hdrChecksum, s1_hdr.ipv4.identification, s1_hdr.ipv4.ihl, s1_hdr.ipv4.protocol, s1_hdr.ipv4.srcAddr, s1_hdr.ipv4.totalLen, s1_hdr.ipv4.ttl, s1_hdr.ipv4.valid, s1_hdr.ipv4.version, s1_hdr.nc_hdr.key, s1_hdr.nc_hdr.op, s1_hdr.nc_hdr.sc, s1_hdr.nc_hdr.seq, s1_hdr.nc_hdr.valid, s1_hdr.nc_hdr.value, s1_hdr.nc_hdr.vgroup, s1_hdr.overlay.0.swip, s1_hdr.overlay.0.valid, s1_hdr.overlay.1.swip, s1_hdr.overlay.1.valid, s1_hdr.overlay.2.swip, s1_hdr.overlay.2.valid, s1_hdr.overlay.3.swip, s1_hdr.overlay.3.valid, s1_hdr.overlay.4.swip, s1_hdr.overlay.4.valid, s1_hdr.overlay.5.swip, s1_hdr.overlay.5.valid, s1_hdr.overlay.6.swip, s1_hdr.overlay.6.valid, s1_hdr.overlay.7.swip, s1_hdr.overlay.7.valid, s1_hdr.overlay.8.swip, s1_hdr.overlay.8.valid, s1_hdr.overlay.9.swip, s1_hdr.overlay.9.valid, s1_hdr.overlay.last.swip, s1_hdr.overlay.last.valid, s1_hdr.tcp.ackNo, s1_hdr.tcp.checksum, s1_hdr.tcp.ctrl, s1_hdr.tcp.dataOffset, s1_hdr.tcp.dstPort, s1_hdr.tcp.ecn, s1_hdr.tcp.res, s1_hdr.tcp.seqNo, s1_hdr.tcp.srcPort, s1_hdr.tcp.urgentPtr, s1_hdr.tcp.valid, s1_hdr.tcp.window, s1_hdr.udp.checksum, s1_hdr.udp.dstPort, s1_hdr.udp.len, s1_hdr.udp.srcPort, s1_hdr.udp.valid, s1_inbox_count, s1_ipv4_route.action_run, s1_ipv4_route.hit, s1_ipv4_route.set_egress.egress_spec_1, s1_isValid, s1_maintain_sequence.action_run, s1_maintain_sequence.hit, s1_meta.location, s1_meta.location.index, s1_meta.my_md, s1_meta.my_md.failed, s1_meta.my_md.ipaddress, s1_meta.my_md.role, s1_meta.reply_to_client_md, s1_meta.reply_to_client_md.ipv4_dstAddr, s1_meta.reply_to_client_md.ipv4_srcAddr, s1_meta.sequence_md, s1_meta.sequence_md.seq, s1_meta.sequence_md.tmp, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_external, s1_pop_chain.action_run, s1_pop_chain.hit, s1_pop_chain_again.action_run, s1_pop_chain_again.hit, s1_read_value.action_run, s1_read_value.hit, s1_sequence_reg, s1_sequence_reg__dbg0, s1_sequence_reg__last0_old_value, s1_sequence_reg__last0_old_value__dbg, s1_sequence_reg__last0_value, s1_sequence_reg__last0_value__dbg, s1_sequence_reg__last_index, s1_sequence_reg__last_index__dbg, s1_sequence_reg__last_old_value, s1_sequence_reg__last_old_value__dbg, s1_sequence_reg__last_value, s1_sequence_reg__last_value__dbg, s1_sequence_reg__last_write_site, s1_sequence_reg__next_write_site, s1_sequence_reg__wrote_any, s1_sequence_reg__wrote_any__dbg, s1_sequence_reg__wrote_index0, s1_sequence_reg__wrote_index0__dbg, s1_stack.index, s1_standard_metadata.checksum_error, s1_standard_metadata.deq_qdepth, s1_standard_metadata.deq_timedelta, s1_standard_metadata.egress_global_timestamp, s1_standard_metadata.egress_port, s1_standard_metadata.egress_rid, s1_standard_metadata.egress_spec, s1_standard_metadata.enq_qdepth, s1_standard_metadata.enq_timestamp, s1_standard_metadata.ingress_global_timestamp, s1_standard_metadata.ingress_port, s1_standard_metadata.instance_type, s1_standard_metadata.mcast_grp, s1_standard_metadata.packet_length, s1_standard_metadata.parser_error, s1_standard_metadata.priority, s1_value_reg, s1_value_reg__dbg0, s1_value_reg__last0_old_value, s1_value_reg__last0_old_value__dbg, s1_value_reg__last0_value, s1_value_reg__last0_value__dbg, s1_value_reg__last_index, s1_value_reg__last_index__dbg, s1_value_reg__last_old_value, s1_value_reg__last_old_value__dbg, s1_value_reg__last_value, s1_value_reg__last_value__dbg, s1_value_reg__last_write_site, s1_value_reg__next_write_site, s1_value_reg__wrote_any, s1_value_reg__wrote_any__dbg, s1_value_reg__wrote_index0, s1_value_reg__wrote_index0__dbg, s2_assign_value.action_run, s2_assign_value.hit, s2_drop, s2_drop_packet.action_run, s2_drop_packet.hit, s2_ethernet_set_mac.action_run, s2_ethernet_set_mac.ethernet_set_mac_act.dmac, s2_ethernet_set_mac.ethernet_set_mac_act.smac, s2_ethernet_set_mac.hit, s2_failure_recovery.action_run, s2_failure_recovery.hit, s2_find_index.action_run, s2_find_index.find_index_act.index_1, s2_find_index.hit, s2_forward, s2_gen_reply.action_run, s2_gen_reply.gen_reply_act.message_type, s2_gen_reply.hit, s2_get_my_address.action_run, s2_get_my_address.get_my_address_act.sw_ip, s2_get_my_address.get_my_address_act.sw_role, s2_get_my_address.hit, s2_get_next_hop.action_run, s2_get_next_hop.hit, s2_get_sequence.action_run, s2_get_sequence.hit, s2_hdr.ethernet.dstAddr, s2_hdr.ethernet.etherType, s2_hdr.ethernet.srcAddr, s2_hdr.ethernet.valid, s2_hdr.ipv4.diffserv, s2_hdr.ipv4.dstAddr, s2_hdr.ipv4.flags, s2_hdr.ipv4.fragOffset, s2_hdr.ipv4.hdrChecksum, s2_hdr.ipv4.identification, s2_hdr.ipv4.ihl, s2_hdr.ipv4.protocol, s2_hdr.ipv4.srcAddr, s2_hdr.ipv4.totalLen, s2_hdr.ipv4.ttl, s2_hdr.ipv4.valid, s2_hdr.ipv4.version, s2_hdr.nc_hdr.key, s2_hdr.nc_hdr.op, s2_hdr.nc_hdr.sc, s2_hdr.nc_hdr.seq, s2_hdr.nc_hdr.valid, s2_hdr.nc_hdr.value, s2_hdr.nc_hdr.vgroup, s2_hdr.overlay.0.swip, s2_hdr.overlay.0.valid, s2_hdr.overlay.1.swip, s2_hdr.overlay.1.valid, s2_hdr.overlay.2.swip, s2_hdr.overlay.2.valid, s2_hdr.overlay.3.swip, s2_hdr.overlay.3.valid, s2_hdr.overlay.4.swip, s2_hdr.overlay.4.valid, s2_hdr.overlay.5.swip, s2_hdr.overlay.5.valid, s2_hdr.overlay.6.swip, s2_hdr.overlay.6.valid, s2_hdr.overlay.7.swip, s2_hdr.overlay.7.valid, s2_hdr.overlay.8.swip, s2_hdr.overlay.8.valid, s2_hdr.overlay.9.swip, s2_hdr.overlay.9.valid, s2_hdr.overlay.last.swip, s2_hdr.overlay.last.valid, s2_hdr.tcp.ackNo, s2_hdr.tcp.checksum, s2_hdr.tcp.ctrl, s2_hdr.tcp.dataOffset, s2_hdr.tcp.dstPort, s2_hdr.tcp.ecn, s2_hdr.tcp.res, s2_hdr.tcp.seqNo, s2_hdr.tcp.srcPort, s2_hdr.tcp.urgentPtr, s2_hdr.tcp.valid, s2_hdr.tcp.window, s2_hdr.udp.checksum, s2_hdr.udp.dstPort, s2_hdr.udp.len, s2_hdr.udp.srcPort, s2_hdr.udp.valid, s2_inbox_count, s2_ipv4_route.action_run, s2_ipv4_route.hit, s2_ipv4_route.set_egress.egress_spec_1, s2_isValid, s2_maintain_sequence.action_run, s2_maintain_sequence.hit, s2_meta.location, s2_meta.location.index, s2_meta.my_md, s2_meta.my_md.failed, s2_meta.my_md.ipaddress, s2_meta.my_md.role, s2_meta.reply_to_client_md, s2_meta.reply_to_client_md.ipv4_dstAddr, s2_meta.reply_to_client_md.ipv4_srcAddr, s2_meta.sequence_md, s2_meta.sequence_md.seq, s2_meta.sequence_md.tmp, s2_p4b_checksum_error, s2_p4b_checksum_updated, s2_p4b_checksum_verified, s2_p4b_clone_e2e, s2_p4b_clone_i2e, s2_p4b_clone_i2i, s2_p4b_digest, s2_p4b_recirculate, s2_pkt_external, s2_pop_chain.action_run, s2_pop_chain.hit, s2_pop_chain_again.action_run, s2_pop_chain_again.hit, s2_read_value.action_run, s2_read_value.hit, s2_sequence_reg, s2_sequence_reg__dbg0, s2_sequence_reg__last0_old_value, s2_sequence_reg__last0_old_value__dbg, s2_sequence_reg__last0_value, s2_sequence_reg__last0_value__dbg, s2_sequence_reg__last_index, s2_sequence_reg__last_index__dbg, s2_sequence_reg__last_old_value, s2_sequence_reg__last_old_value__dbg, s2_sequence_reg__last_value, s2_sequence_reg__last_value__dbg, s2_sequence_reg__last_write_site, s2_sequence_reg__next_write_site, s2_sequence_reg__wrote_any, s2_sequence_reg__wrote_any__dbg, s2_sequence_reg__wrote_index0, s2_sequence_reg__wrote_index0__dbg, s2_stack.index, s2_standard_metadata.checksum_error, s2_standard_metadata.deq_qdepth, s2_standard_metadata.deq_timedelta, s2_standard_metadata.egress_global_timestamp, s2_standard_metadata.egress_port, s2_standard_metadata.egress_rid, s2_standard_metadata.egress_spec, s2_standard_metadata.enq_qdepth, s2_standard_metadata.enq_timestamp, s2_standard_metadata.ingress_global_timestamp, s2_standard_metadata.ingress_port, s2_standard_metadata.instance_type, s2_standard_metadata.mcast_grp, s2_standard_metadata.packet_length, s2_standard_metadata.parser_error, s2_standard_metadata.priority, s2_value_reg, s2_value_reg__dbg0, s2_value_reg__last0_old_value, s2_value_reg__last0_old_value__dbg, s2_value_reg__last0_value, s2_value_reg__last0_value__dbg, s2_value_reg__last_index, s2_value_reg__last_index__dbg, s2_value_reg__last_old_value, s2_value_reg__last_old_value__dbg, s2_value_reg__last_value, s2_value_reg__last_value__dbg, s2_value_reg__last_write_site, s2_value_reg__next_write_site, s2_value_reg__wrote_any, s2_value_reg__wrote_any__dbg, s2_value_reg__wrote_index0, s2_value_reg__wrote_index0__dbg;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    // host send -> h1
    // inject packet into connected node (host -> node)
    if (s1_inbox_count < 1) {
      assume s1_inbox_count < 1;
      havoc h1_standard_metadata.ingress_port;
      havoc h1_standard_metadata.instance_type;
      havoc h1_standard_metadata.packet_length;
      havoc h1_standard_metadata.enq_timestamp;
      havoc h1_standard_metadata.enq_qdepth;
      havoc h1_standard_metadata.deq_timedelta;
      havoc h1_standard_metadata.deq_qdepth;
      havoc h1_standard_metadata.ingress_global_timestamp;
      havoc h1_standard_metadata.egress_global_timestamp;
      havoc h1_standard_metadata.mcast_grp;
      havoc h1_standard_metadata.egress_rid;
      havoc h1_standard_metadata.checksum_error;
      havoc h1_standard_metadata.parser_error;
      havoc h1_standard_metadata.priority;
      havoc h1_meta.location;
      havoc h1_meta.location.index;
      havoc h1_meta.my_md;
      havoc h1_meta.my_md.ipaddress;
      havoc h1_meta.my_md.role;
      havoc h1_meta.my_md.failed;
      havoc h1_meta.reply_to_client_md;
      havoc h1_meta.reply_to_client_md.ipv4_srcAddr;
      havoc h1_meta.reply_to_client_md.ipv4_dstAddr;
      havoc h1_meta.sequence_md;
      havoc h1_meta.sequence_md.seq;
      havoc h1_meta.sequence_md.tmp;
      havoc h1_hdr.ethernet.dstAddr;
      havoc h1_hdr.ethernet.srcAddr;
      havoc h1_hdr.ipv4.version;
      havoc h1_hdr.ipv4.ihl;
      havoc h1_hdr.ipv4.diffserv;
      havoc h1_hdr.ipv4.totalLen;
      havoc h1_hdr.ipv4.identification;
      havoc h1_hdr.ipv4.flags;
      havoc h1_hdr.ipv4.fragOffset;
      havoc h1_hdr.ipv4.ttl;
      havoc h1_hdr.ipv4.hdrChecksum;
      havoc h1_hdr.nc_hdr.sc;
      havoc h1_hdr.nc_hdr.value;
      havoc h1_hdr.nc_hdr.vgroup;
      havoc h1_hdr.tcp.srcPort;
      havoc h1_hdr.tcp.dstPort;
      havoc h1_hdr.tcp.seqNo;
      havoc h1_hdr.tcp.ackNo;
      havoc h1_hdr.tcp.dataOffset;
      havoc h1_hdr.tcp.res;
      havoc h1_hdr.tcp.ecn;
      havoc h1_hdr.tcp.ctrl;
      havoc h1_hdr.tcp.window;
      havoc h1_hdr.tcp.checksum;
      havoc h1_hdr.tcp.urgentPtr;
      havoc h1_hdr.udp.srcPort;
      havoc h1_hdr.udp.dstPort;
      havoc h1_hdr.udp.len;
      havoc h1_hdr.udp.checksum;
      havoc h1_hdr.overlay.last.valid;
      havoc h1_hdr.overlay.last.swip;
      havoc h1_hdr.overlay.4.valid;
      havoc h1_hdr.overlay.4.swip;
      havoc h1_hdr.overlay.5.valid;
      havoc h1_hdr.overlay.5.swip;
      havoc h1_hdr.overlay.6.valid;
      havoc h1_hdr.overlay.6.swip;
      havoc h1_hdr.overlay.7.valid;
      havoc h1_hdr.overlay.7.swip;
      havoc h1_hdr.overlay.8.valid;
      havoc h1_hdr.overlay.8.swip;
      havoc h1_hdr.overlay.9.valid;
      havoc h1_hdr.overlay.9.swip;
      h1_hdr.ethernet.valid := true;
      h1_hdr.ipv4.valid := true;
      h1_hdr.nc_hdr.valid := true;
      h1_hdr.udp.valid := true;
      h1_hdr.tcp.valid := false;
      h1_hdr.ipv4.protocol := 17bv8;
      h1_hdr.overlay.0.valid := true;
      h1_hdr.overlay.1.valid := true;
      h1_hdr.overlay.2.valid := true;
      h1_hdr.overlay.3.valid := true;
      h1_hdr.ethernet.etherType := 2048bv16;
      h1_hdr.ipv4.srcAddr := 1bv32;
      h1_hdr.ipv4.dstAddr := 167797761bv32;
      h1_hdr.overlay.0.swip := 167797761bv32;
      h1_hdr.overlay.1.swip := 167797762bv32;
      h1_hdr.overlay.2.swip := 0bv32;
      h1_hdr.overlay.3.swip := 0bv32;
      h1_hdr.nc_hdr.op := 12bv8;
      h1_hdr.nc_hdr.key := 2024bv128;
      h1_hdr.nc_hdr.seq := 1bv16;
      assume (s1_meta.location.index == 0bv16);
      assume (s2_meta.location.index == 0bv16);
      assume (s1_find_index.hit == true);
      assume (s2_find_index.hit == true);
      assume (s1_meta.my_md.role == 100bv16);
      assume (s2_meta.my_md.role == 101bv16);
      assume (s1_standard_metadata.egress_port != 0bv9);
      s1_standard_metadata.ingress_port := h1_standard_metadata.ingress_port;
      s1_standard_metadata.instance_type := h1_standard_metadata.instance_type;
      s1_standard_metadata.packet_length := h1_standard_metadata.packet_length;
      s1_standard_metadata.enq_timestamp := h1_standard_metadata.enq_timestamp;
      s1_standard_metadata.enq_qdepth := h1_standard_metadata.enq_qdepth;
      s1_standard_metadata.deq_timedelta := h1_standard_metadata.deq_timedelta;
      s1_standard_metadata.deq_qdepth := h1_standard_metadata.deq_qdepth;
      s1_standard_metadata.ingress_global_timestamp := h1_standard_metadata.ingress_global_timestamp;
      s1_standard_metadata.egress_global_timestamp := h1_standard_metadata.egress_global_timestamp;
      s1_standard_metadata.mcast_grp := h1_standard_metadata.mcast_grp;
      s1_standard_metadata.egress_rid := h1_standard_metadata.egress_rid;
      s1_standard_metadata.checksum_error := h1_standard_metadata.checksum_error;
      s1_standard_metadata.parser_error := h1_standard_metadata.parser_error;
      s1_standard_metadata.priority := h1_standard_metadata.priority;
      s1_meta.location := h1_meta.location;
      s1_meta.location.index := h1_meta.location.index;
      s1_meta.my_md := h1_meta.my_md;
      s1_meta.my_md.ipaddress := h1_meta.my_md.ipaddress;
      s1_meta.my_md.role := h1_meta.my_md.role;
      s1_meta.my_md.failed := h1_meta.my_md.failed;
      s1_meta.reply_to_client_md := h1_meta.reply_to_client_md;
      s1_meta.reply_to_client_md.ipv4_srcAddr := h1_meta.reply_to_client_md.ipv4_srcAddr;
      s1_meta.reply_to_client_md.ipv4_dstAddr := h1_meta.reply_to_client_md.ipv4_dstAddr;
      s1_meta.sequence_md := h1_meta.sequence_md;
      s1_meta.sequence_md.seq := h1_meta.sequence_md.seq;
      s1_meta.sequence_md.tmp := h1_meta.sequence_md.tmp;
      s1_hdr.ethernet.valid := h1_hdr.ethernet.valid;
      s1_hdr.ethernet.dstAddr := h1_hdr.ethernet.dstAddr;
      s1_hdr.ethernet.srcAddr := h1_hdr.ethernet.srcAddr;
      s1_hdr.ethernet.etherType := 2048bv16;
      s1_hdr.ipv4.valid := h1_hdr.ipv4.valid;
      s1_hdr.ipv4.version := h1_hdr.ipv4.version;
      s1_hdr.ipv4.ihl := h1_hdr.ipv4.ihl;
      s1_hdr.ipv4.diffserv := h1_hdr.ipv4.diffserv;
      s1_hdr.ipv4.totalLen := h1_hdr.ipv4.totalLen;
      s1_hdr.ipv4.identification := h1_hdr.ipv4.identification;
      s1_hdr.ipv4.flags := h1_hdr.ipv4.flags;
      s1_hdr.ipv4.fragOffset := h1_hdr.ipv4.fragOffset;
      s1_hdr.ipv4.ttl := h1_hdr.ipv4.ttl;
      s1_hdr.ipv4.protocol := 17bv8;
      s1_hdr.ipv4.hdrChecksum := h1_hdr.ipv4.hdrChecksum;
      s1_hdr.ipv4.srcAddr := 1bv32;
      s1_hdr.ipv4.dstAddr := 167797761bv32;
      s1_hdr.nc_hdr.valid := h1_hdr.nc_hdr.valid;
      s1_hdr.nc_hdr.op := 12bv8;
      s1_hdr.nc_hdr.sc := h1_hdr.nc_hdr.sc;
      s1_hdr.nc_hdr.seq := 1bv16;
      s1_hdr.nc_hdr.key := 2024bv128;
      s1_hdr.nc_hdr.value := h1_hdr.nc_hdr.value;
      s1_hdr.nc_hdr.vgroup := h1_hdr.nc_hdr.vgroup;
      s1_hdr.tcp.valid := h1_hdr.tcp.valid;
      s1_hdr.tcp.srcPort := h1_hdr.tcp.srcPort;
      s1_hdr.tcp.dstPort := h1_hdr.tcp.dstPort;
      s1_hdr.tcp.seqNo := h1_hdr.tcp.seqNo;
      s1_hdr.tcp.ackNo := h1_hdr.tcp.ackNo;
      s1_hdr.tcp.dataOffset := h1_hdr.tcp.dataOffset;
      s1_hdr.tcp.res := h1_hdr.tcp.res;
      s1_hdr.tcp.ecn := h1_hdr.tcp.ecn;
      s1_hdr.tcp.ctrl := h1_hdr.tcp.ctrl;
      s1_hdr.tcp.window := h1_hdr.tcp.window;
      s1_hdr.tcp.checksum := h1_hdr.tcp.checksum;
      s1_hdr.tcp.urgentPtr := h1_hdr.tcp.urgentPtr;
      s1_hdr.udp.valid := h1_hdr.udp.valid;
      s1_hdr.udp.srcPort := h1_hdr.udp.srcPort;
      s1_hdr.udp.dstPort := h1_hdr.udp.dstPort;
      s1_hdr.udp.len := h1_hdr.udp.len;
      s1_hdr.udp.checksum := h1_hdr.udp.checksum;
      s1_hdr.overlay.last.valid := h1_hdr.overlay.last.valid;
      s1_hdr.overlay.last.swip := h1_hdr.overlay.last.swip;
      s1_hdr.overlay.0.valid := h1_hdr.overlay.0.valid;
      s1_hdr.overlay.0.swip := 167797761bv32;
      s1_hdr.overlay.1.valid := h1_hdr.overlay.1.valid;
      s1_hdr.overlay.1.swip := 167797762bv32;
      s1_hdr.overlay.2.valid := h1_hdr.overlay.2.valid;
      s1_hdr.overlay.2.swip := 0bv32;
      s1_hdr.overlay.3.valid := h1_hdr.overlay.3.valid;
      s1_hdr.overlay.3.swip := 0bv32;
      s1_hdr.overlay.4.valid := h1_hdr.overlay.4.valid;
      s1_hdr.overlay.4.swip := h1_hdr.overlay.4.swip;
      s1_hdr.overlay.5.valid := h1_hdr.overlay.5.valid;
      s1_hdr.overlay.5.swip := h1_hdr.overlay.5.swip;
      s1_hdr.overlay.6.valid := h1_hdr.overlay.6.valid;
      s1_hdr.overlay.6.swip := h1_hdr.overlay.6.swip;
      s1_hdr.overlay.7.valid := h1_hdr.overlay.7.valid;
      s1_hdr.overlay.7.swip := h1_hdr.overlay.7.swip;
      s1_hdr.overlay.8.valid := h1_hdr.overlay.8.valid;
      s1_hdr.overlay.8.swip := h1_hdr.overlay.8.swip;
      s1_hdr.overlay.9.valid := h1_hdr.overlay.9.valid;
      s1_hdr.overlay.9.swip := h1_hdr.overlay.9.swip;
      s1_pkt_external := true;
      s1_inbox_count := s1_inbox_count + 1;
    }
  } else if (procurator_phase == 1) {
    // host recv -> h1
  } else if (procurator_phase == 2) {
    // node pass -> s1
    if (s1_inbox_count > 0) {
    assume s1_inbox_count > 0;
    s1_inbox_count := s1_inbox_count - 1;
    call s1_mainProcedure();
    if (s1_p4b_clone_i2e) {
      assume s1_inbox_count < 1;
      s1_pkt_external := false;
      s1_inbox_count := s1_inbox_count + 1;
    }
    s1_p4b_clone_i2e := false;
    if (s1_p4b_clone_e2e) {
      assume s1_inbox_count < 1;
      s1_pkt_external := false;
      s1_inbox_count := s1_inbox_count + 1;
    }
    s1_p4b_clone_e2e := false;
    if (s1_p4b_clone_i2i) {
      assume s1_inbox_count < 1;
      s1_pkt_external := false;
      s1_inbox_count := s1_inbox_count + 1;
    }
    s1_p4b_clone_i2i := false;
    if (s1_p4b_recirculate) {
      assume s1_inbox_count < 1;
      s1_pkt_external := false;
      s1_inbox_count := s1_inbox_count + 1;
    }
    s1_p4b_recirculate := false;
    call s1_Forward();
    // Register debug snapshot
    s1_sequence_reg__dbg0 := s1_sequence_reg[0bv32];
    s1_sequence_reg__last_index__dbg := s1_sequence_reg__last_index;
    s1_sequence_reg__last_value__dbg := s1_sequence_reg__last_value;
    s1_sequence_reg__last_old_value__dbg := s1_sequence_reg__last_old_value;
    s1_sequence_reg__wrote_any__dbg := s1_sequence_reg__wrote_any;
    s1_sequence_reg__wrote_index0__dbg := s1_sequence_reg__wrote_index0;
    s1_sequence_reg__last0_old_value__dbg := s1_sequence_reg__last0_old_value;
    s1_sequence_reg__last0_value__dbg := s1_sequence_reg__last0_value;
    s1_value_reg__dbg0 := s1_value_reg[0bv32];
    s1_value_reg__last_index__dbg := s1_value_reg__last_index;
    s1_value_reg__last_value__dbg := s1_value_reg__last_value;
    s1_value_reg__last_old_value__dbg := s1_value_reg__last_old_value;
    s1_value_reg__wrote_any__dbg := s1_value_reg__wrote_any;
    s1_value_reg__wrote_index0__dbg := s1_value_reg__wrote_index0;
    s1_value_reg__last0_old_value__dbg := s1_value_reg__last0_old_value;
    s1_value_reg__last0_value__dbg := s1_value_reg__last0_value;
    s2_sequence_reg__dbg0 := s2_sequence_reg[0bv32];
    s2_sequence_reg__last_index__dbg := s2_sequence_reg__last_index;
    s2_sequence_reg__last_value__dbg := s2_sequence_reg__last_value;
    s2_sequence_reg__last_old_value__dbg := s2_sequence_reg__last_old_value;
    s2_sequence_reg__wrote_any__dbg := s2_sequence_reg__wrote_any;
    s2_sequence_reg__wrote_index0__dbg := s2_sequence_reg__wrote_index0;
    s2_sequence_reg__last0_old_value__dbg := s2_sequence_reg__last0_old_value;
    s2_sequence_reg__last0_value__dbg := s2_sequence_reg__last0_value;
    s2_value_reg__dbg0 := s2_value_reg[0bv32];
    s2_value_reg__last_index__dbg := s2_value_reg__last_index;
    s2_value_reg__last_value__dbg := s2_value_reg__last_value;
    s2_value_reg__last_old_value__dbg := s2_value_reg__last_old_value;
    s2_value_reg__wrote_any__dbg := s2_value_reg__wrote_any;
    s2_value_reg__wrote_index0__dbg := s2_value_reg__wrote_index0;
    s2_value_reg__last0_old_value__dbg := s2_value_reg__last0_old_value;
    s2_value_reg__last0_value__dbg := s2_value_reg__last0_value;
    // Global assertions
    call __wraparound_assert(bvule.bv16$builtin(s2_sequence_reg__dbg0, s1_sequence_reg__dbg0));
    }
  } else if (procurator_phase == 3) {
    // node pass -> s2
    if (s2_inbox_count > 0) {
    assume s2_inbox_count > 0;
    s2_inbox_count := s2_inbox_count - 1;
    call s2_mainProcedure();
    if (s2_p4b_clone_i2e) {
      assume s2_inbox_count < 1;
      s2_pkt_external := false;
      s2_inbox_count := s2_inbox_count + 1;
    }
    s2_p4b_clone_i2e := false;
    if (s2_p4b_clone_e2e) {
      assume s2_inbox_count < 1;
      s2_pkt_external := false;
      s2_inbox_count := s2_inbox_count + 1;
    }
    s2_p4b_clone_e2e := false;
    if (s2_p4b_clone_i2i) {
      assume s2_inbox_count < 1;
      s2_pkt_external := false;
      s2_inbox_count := s2_inbox_count + 1;
    }
    s2_p4b_clone_i2i := false;
    if (s2_p4b_recirculate) {
      assume s2_inbox_count < 1;
      s2_pkt_external := false;
      s2_inbox_count := s2_inbox_count + 1;
    }
    s2_p4b_recirculate := false;
    call s2_Forward();
    // Register debug snapshot
    s1_sequence_reg__dbg0 := s1_sequence_reg[0bv32];
    s1_sequence_reg__last_index__dbg := s1_sequence_reg__last_index;
    s1_sequence_reg__last_value__dbg := s1_sequence_reg__last_value;
    s1_sequence_reg__last_old_value__dbg := s1_sequence_reg__last_old_value;
    s1_sequence_reg__wrote_any__dbg := s1_sequence_reg__wrote_any;
    s1_sequence_reg__wrote_index0__dbg := s1_sequence_reg__wrote_index0;
    s1_sequence_reg__last0_old_value__dbg := s1_sequence_reg__last0_old_value;
    s1_sequence_reg__last0_value__dbg := s1_sequence_reg__last0_value;
    s1_value_reg__dbg0 := s1_value_reg[0bv32];
    s1_value_reg__last_index__dbg := s1_value_reg__last_index;
    s1_value_reg__last_value__dbg := s1_value_reg__last_value;
    s1_value_reg__last_old_value__dbg := s1_value_reg__last_old_value;
    s1_value_reg__wrote_any__dbg := s1_value_reg__wrote_any;
    s1_value_reg__wrote_index0__dbg := s1_value_reg__wrote_index0;
    s1_value_reg__last0_old_value__dbg := s1_value_reg__last0_old_value;
    s1_value_reg__last0_value__dbg := s1_value_reg__last0_value;
    s2_sequence_reg__dbg0 := s2_sequence_reg[0bv32];
    s2_sequence_reg__last_index__dbg := s2_sequence_reg__last_index;
    s2_sequence_reg__last_value__dbg := s2_sequence_reg__last_value;
    s2_sequence_reg__last_old_value__dbg := s2_sequence_reg__last_old_value;
    s2_sequence_reg__wrote_any__dbg := s2_sequence_reg__wrote_any;
    s2_sequence_reg__wrote_index0__dbg := s2_sequence_reg__wrote_index0;
    s2_sequence_reg__last0_old_value__dbg := s2_sequence_reg__last0_old_value;
    s2_sequence_reg__last0_value__dbg := s2_sequence_reg__last0_value;
    s2_value_reg__dbg0 := s2_value_reg[0bv32];
    s2_value_reg__last_index__dbg := s2_value_reg__last_index;
    s2_value_reg__last_value__dbg := s2_value_reg__last_value;
    s2_value_reg__last_old_value__dbg := s2_value_reg__last_old_value;
    s2_value_reg__wrote_any__dbg := s2_value_reg__wrote_any;
    s2_value_reg__wrote_index0__dbg := s2_value_reg__wrote_index0;
    s2_value_reg__last0_old_value__dbg := s2_value_reg__last0_old_value;
    s2_value_reg__last0_value__dbg := s2_value_reg__last0_value;
    // Global assertions
    call __wraparound_assert(bvule.bv16$builtin(s2_sequence_reg__dbg0, s1_sequence_reg__dbg0));
    }
  } else {
    assume false;
  }
    if (procurator_phase == 3) {
      procurator_phase := 0;
    } else {
      procurator_phase := procurator_phase + 1;
    }
}

procedure mainProcedure() returns()
  modifies h1_hdr.ethernet.dstAddr, h1_hdr.ethernet.etherType, h1_hdr.ethernet.srcAddr, h1_hdr.ethernet.valid, h1_hdr.ipv4.diffserv, h1_hdr.ipv4.dstAddr, h1_hdr.ipv4.flags, h1_hdr.ipv4.fragOffset, h1_hdr.ipv4.hdrChecksum, h1_hdr.ipv4.identification, h1_hdr.ipv4.ihl, h1_hdr.ipv4.protocol, h1_hdr.ipv4.srcAddr, h1_hdr.ipv4.totalLen, h1_hdr.ipv4.ttl, h1_hdr.ipv4.valid, h1_hdr.ipv4.version, h1_hdr.nc_hdr.key, h1_hdr.nc_hdr.op, h1_hdr.nc_hdr.sc, h1_hdr.nc_hdr.seq, h1_hdr.nc_hdr.valid, h1_hdr.nc_hdr.value, h1_hdr.nc_hdr.vgroup, h1_hdr.overlay.0.swip, h1_hdr.overlay.0.valid, h1_hdr.overlay.1.swip, h1_hdr.overlay.1.valid, h1_hdr.overlay.2.swip, h1_hdr.overlay.2.valid, h1_hdr.overlay.3.swip, h1_hdr.overlay.3.valid, h1_hdr.overlay.4.swip, h1_hdr.overlay.4.valid, h1_hdr.overlay.5.swip, h1_hdr.overlay.5.valid, h1_hdr.overlay.6.swip, h1_hdr.overlay.6.valid, h1_hdr.overlay.7.swip, h1_hdr.overlay.7.valid, h1_hdr.overlay.8.swip, h1_hdr.overlay.8.valid, h1_hdr.overlay.9.swip, h1_hdr.overlay.9.valid, h1_hdr.overlay.last.swip, h1_hdr.overlay.last.valid, h1_hdr.tcp.ackNo, h1_hdr.tcp.checksum, h1_hdr.tcp.ctrl, h1_hdr.tcp.dataOffset, h1_hdr.tcp.dstPort, h1_hdr.tcp.ecn, h1_hdr.tcp.res, h1_hdr.tcp.seqNo, h1_hdr.tcp.srcPort, h1_hdr.tcp.urgentPtr, h1_hdr.tcp.valid, h1_hdr.tcp.window, h1_hdr.udp.checksum, h1_hdr.udp.dstPort, h1_hdr.udp.len, h1_hdr.udp.srcPort, h1_hdr.udp.valid, h1_inbox_count, h1_meta.location, h1_meta.location.index, h1_meta.my_md, h1_meta.my_md.failed, h1_meta.my_md.ipaddress, h1_meta.my_md.role, h1_meta.reply_to_client_md, h1_meta.reply_to_client_md.ipv4_dstAddr, h1_meta.reply_to_client_md.ipv4_srcAddr, h1_meta.sequence_md, h1_meta.sequence_md.seq, h1_meta.sequence_md.tmp, h1_pkt_external, h1_standard_metadata.checksum_error, h1_standard_metadata.deq_qdepth, h1_standard_metadata.deq_timedelta, h1_standard_metadata.egress_global_timestamp, h1_standard_metadata.egress_rid, h1_standard_metadata.enq_qdepth, h1_standard_metadata.enq_timestamp, h1_standard_metadata.ingress_global_timestamp, h1_standard_metadata.ingress_port, h1_standard_metadata.instance_type, h1_standard_metadata.mcast_grp, h1_standard_metadata.packet_length, h1_standard_metadata.parser_error, h1_standard_metadata.priority, procurator_phase, procurator_step, s1_assign_value.action_run, s1_assign_value.hit, s1_drop, s1_drop_packet.action_run, s1_drop_packet.hit, s1_ethernet_set_mac.action_run, s1_ethernet_set_mac.ethernet_set_mac_act.dmac, s1_ethernet_set_mac.ethernet_set_mac_act.smac, s1_ethernet_set_mac.hit, s1_failure_recovery.action_run, s1_failure_recovery.hit, s1_find_index.action_run, s1_find_index.find_index_act.index_1, s1_find_index.hit, s1_forward, s1_gen_reply.action_run, s1_gen_reply.gen_reply_act.message_type, s1_gen_reply.hit, s1_get_my_address.action_run, s1_get_my_address.get_my_address_act.sw_ip, s1_get_my_address.get_my_address_act.sw_role, s1_get_my_address.hit, s1_get_next_hop.action_run, s1_get_next_hop.hit, s1_get_sequence.action_run, s1_get_sequence.hit, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.etherType, s1_hdr.ethernet.srcAddr, s1_hdr.ethernet.valid, s1_hdr.ipv4.diffserv, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.flags, s1_hdr.ipv4.fragOffset, s1_hdr.ipv4.hdrChecksum, s1_hdr.ipv4.identification, s1_hdr.ipv4.ihl, s1_hdr.ipv4.protocol, s1_hdr.ipv4.srcAddr, s1_hdr.ipv4.totalLen, s1_hdr.ipv4.ttl, s1_hdr.ipv4.valid, s1_hdr.ipv4.version, s1_hdr.nc_hdr.key, s1_hdr.nc_hdr.op, s1_hdr.nc_hdr.sc, s1_hdr.nc_hdr.seq, s1_hdr.nc_hdr.valid, s1_hdr.nc_hdr.value, s1_hdr.nc_hdr.vgroup, s1_hdr.overlay.0.swip, s1_hdr.overlay.0.valid, s1_hdr.overlay.1.swip, s1_hdr.overlay.1.valid, s1_hdr.overlay.2.swip, s1_hdr.overlay.2.valid, s1_hdr.overlay.3.swip, s1_hdr.overlay.3.valid, s1_hdr.overlay.4.swip, s1_hdr.overlay.4.valid, s1_hdr.overlay.5.swip, s1_hdr.overlay.5.valid, s1_hdr.overlay.6.swip, s1_hdr.overlay.6.valid, s1_hdr.overlay.7.swip, s1_hdr.overlay.7.valid, s1_hdr.overlay.8.swip, s1_hdr.overlay.8.valid, s1_hdr.overlay.9.swip, s1_hdr.overlay.9.valid, s1_hdr.overlay.last.swip, s1_hdr.overlay.last.valid, s1_hdr.tcp.ackNo, s1_hdr.tcp.checksum, s1_hdr.tcp.ctrl, s1_hdr.tcp.dataOffset, s1_hdr.tcp.dstPort, s1_hdr.tcp.ecn, s1_hdr.tcp.res, s1_hdr.tcp.seqNo, s1_hdr.tcp.srcPort, s1_hdr.tcp.urgentPtr, s1_hdr.tcp.valid, s1_hdr.tcp.window, s1_hdr.udp.checksum, s1_hdr.udp.dstPort, s1_hdr.udp.len, s1_hdr.udp.srcPort, s1_hdr.udp.valid, s1_inbox_count, s1_ipv4_route.action_run, s1_ipv4_route.hit, s1_ipv4_route.set_egress.egress_spec_1, s1_isValid, s1_maintain_sequence.action_run, s1_maintain_sequence.hit, s1_meta.location, s1_meta.location.index, s1_meta.my_md, s1_meta.my_md.failed, s1_meta.my_md.ipaddress, s1_meta.my_md.role, s1_meta.reply_to_client_md, s1_meta.reply_to_client_md.ipv4_dstAddr, s1_meta.reply_to_client_md.ipv4_srcAddr, s1_meta.sequence_md, s1_meta.sequence_md.seq, s1_meta.sequence_md.tmp, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_external, s1_pop_chain.action_run, s1_pop_chain.hit, s1_pop_chain_again.action_run, s1_pop_chain_again.hit, s1_read_value.action_run, s1_read_value.hit, s1_sequence_reg, s1_sequence_reg__dbg0, s1_sequence_reg__last0_old_value, s1_sequence_reg__last0_old_value__dbg, s1_sequence_reg__last0_value, s1_sequence_reg__last0_value__dbg, s1_sequence_reg__last_index, s1_sequence_reg__last_index__dbg, s1_sequence_reg__last_old_value, s1_sequence_reg__last_old_value__dbg, s1_sequence_reg__last_value, s1_sequence_reg__last_value__dbg, s1_sequence_reg__last_write_site, s1_sequence_reg__next_write_site, s1_sequence_reg__wrote_any, s1_sequence_reg__wrote_any__dbg, s1_sequence_reg__wrote_index0, s1_sequence_reg__wrote_index0__dbg, s1_stack.index, s1_standard_metadata.checksum_error, s1_standard_metadata.deq_qdepth, s1_standard_metadata.deq_timedelta, s1_standard_metadata.egress_global_timestamp, s1_standard_metadata.egress_port, s1_standard_metadata.egress_rid, s1_standard_metadata.egress_spec, s1_standard_metadata.enq_qdepth, s1_standard_metadata.enq_timestamp, s1_standard_metadata.ingress_global_timestamp, s1_standard_metadata.ingress_port, s1_standard_metadata.instance_type, s1_standard_metadata.mcast_grp, s1_standard_metadata.packet_length, s1_standard_metadata.parser_error, s1_standard_metadata.priority, s1_value_reg, s1_value_reg__dbg0, s1_value_reg__last0_old_value, s1_value_reg__last0_old_value__dbg, s1_value_reg__last0_value, s1_value_reg__last0_value__dbg, s1_value_reg__last_index, s1_value_reg__last_index__dbg, s1_value_reg__last_old_value, s1_value_reg__last_old_value__dbg, s1_value_reg__last_value, s1_value_reg__last_value__dbg, s1_value_reg__last_write_site, s1_value_reg__next_write_site, s1_value_reg__wrote_any, s1_value_reg__wrote_any__dbg, s1_value_reg__wrote_index0, s1_value_reg__wrote_index0__dbg, s2_assign_value.action_run, s2_assign_value.hit, s2_drop, s2_drop_packet.action_run, s2_drop_packet.hit, s2_ethernet_set_mac.action_run, s2_ethernet_set_mac.ethernet_set_mac_act.dmac, s2_ethernet_set_mac.ethernet_set_mac_act.smac, s2_ethernet_set_mac.hit, s2_failure_recovery.action_run, s2_failure_recovery.hit, s2_find_index.action_run, s2_find_index.find_index_act.index_1, s2_find_index.hit, s2_forward, s2_gen_reply.action_run, s2_gen_reply.gen_reply_act.message_type, s2_gen_reply.hit, s2_get_my_address.action_run, s2_get_my_address.get_my_address_act.sw_ip, s2_get_my_address.get_my_address_act.sw_role, s2_get_my_address.hit, s2_get_next_hop.action_run, s2_get_next_hop.hit, s2_get_sequence.action_run, s2_get_sequence.hit, s2_hdr.ethernet.dstAddr, s2_hdr.ethernet.etherType, s2_hdr.ethernet.srcAddr, s2_hdr.ethernet.valid, s2_hdr.ipv4.diffserv, s2_hdr.ipv4.dstAddr, s2_hdr.ipv4.flags, s2_hdr.ipv4.fragOffset, s2_hdr.ipv4.hdrChecksum, s2_hdr.ipv4.identification, s2_hdr.ipv4.ihl, s2_hdr.ipv4.protocol, s2_hdr.ipv4.srcAddr, s2_hdr.ipv4.totalLen, s2_hdr.ipv4.ttl, s2_hdr.ipv4.valid, s2_hdr.ipv4.version, s2_hdr.nc_hdr.key, s2_hdr.nc_hdr.op, s2_hdr.nc_hdr.sc, s2_hdr.nc_hdr.seq, s2_hdr.nc_hdr.valid, s2_hdr.nc_hdr.value, s2_hdr.nc_hdr.vgroup, s2_hdr.overlay.0.swip, s2_hdr.overlay.0.valid, s2_hdr.overlay.1.swip, s2_hdr.overlay.1.valid, s2_hdr.overlay.2.swip, s2_hdr.overlay.2.valid, s2_hdr.overlay.3.swip, s2_hdr.overlay.3.valid, s2_hdr.overlay.4.swip, s2_hdr.overlay.4.valid, s2_hdr.overlay.5.swip, s2_hdr.overlay.5.valid, s2_hdr.overlay.6.swip, s2_hdr.overlay.6.valid, s2_hdr.overlay.7.swip, s2_hdr.overlay.7.valid, s2_hdr.overlay.8.swip, s2_hdr.overlay.8.valid, s2_hdr.overlay.9.swip, s2_hdr.overlay.9.valid, s2_hdr.overlay.last.swip, s2_hdr.overlay.last.valid, s2_hdr.tcp.ackNo, s2_hdr.tcp.checksum, s2_hdr.tcp.ctrl, s2_hdr.tcp.dataOffset, s2_hdr.tcp.dstPort, s2_hdr.tcp.ecn, s2_hdr.tcp.res, s2_hdr.tcp.seqNo, s2_hdr.tcp.srcPort, s2_hdr.tcp.urgentPtr, s2_hdr.tcp.valid, s2_hdr.tcp.window, s2_hdr.udp.checksum, s2_hdr.udp.dstPort, s2_hdr.udp.len, s2_hdr.udp.srcPort, s2_hdr.udp.valid, s2_inbox_count, s2_ipv4_route.action_run, s2_ipv4_route.hit, s2_ipv4_route.set_egress.egress_spec_1, s2_isValid, s2_maintain_sequence.action_run, s2_maintain_sequence.hit, s2_meta.location, s2_meta.location.index, s2_meta.my_md, s2_meta.my_md.failed, s2_meta.my_md.ipaddress, s2_meta.my_md.role, s2_meta.reply_to_client_md, s2_meta.reply_to_client_md.ipv4_dstAddr, s2_meta.reply_to_client_md.ipv4_srcAddr, s2_meta.sequence_md, s2_meta.sequence_md.seq, s2_meta.sequence_md.tmp, s2_p4b_checksum_error, s2_p4b_checksum_updated, s2_p4b_checksum_verified, s2_p4b_clone_e2e, s2_p4b_clone_i2e, s2_p4b_clone_i2i, s2_p4b_digest, s2_p4b_recirculate, s2_pkt_external, s2_pop_chain.action_run, s2_pop_chain.hit, s2_pop_chain_again.action_run, s2_pop_chain_again.hit, s2_read_value.action_run, s2_read_value.hit, s2_sequence_reg, s2_sequence_reg__dbg0, s2_sequence_reg__last0_old_value, s2_sequence_reg__last0_old_value__dbg, s2_sequence_reg__last0_value, s2_sequence_reg__last0_value__dbg, s2_sequence_reg__last_index, s2_sequence_reg__last_index__dbg, s2_sequence_reg__last_old_value, s2_sequence_reg__last_old_value__dbg, s2_sequence_reg__last_value, s2_sequence_reg__last_value__dbg, s2_sequence_reg__last_write_site, s2_sequence_reg__next_write_site, s2_sequence_reg__wrote_any, s2_sequence_reg__wrote_any__dbg, s2_sequence_reg__wrote_index0, s2_sequence_reg__wrote_index0__dbg, s2_stack.index, s2_standard_metadata.checksum_error, s2_standard_metadata.deq_qdepth, s2_standard_metadata.deq_timedelta, s2_standard_metadata.egress_global_timestamp, s2_standard_metadata.egress_port, s2_standard_metadata.egress_rid, s2_standard_metadata.egress_spec, s2_standard_metadata.enq_qdepth, s2_standard_metadata.enq_timestamp, s2_standard_metadata.ingress_global_timestamp, s2_standard_metadata.ingress_port, s2_standard_metadata.instance_type, s2_standard_metadata.mcast_grp, s2_standard_metadata.packet_length, s2_standard_metadata.parser_error, s2_standard_metadata.priority, s2_value_reg, s2_value_reg__dbg0, s2_value_reg__last0_old_value, s2_value_reg__last0_old_value__dbg, s2_value_reg__last0_value, s2_value_reg__last0_value__dbg, s2_value_reg__last_index, s2_value_reg__last_index__dbg, s2_value_reg__last_old_value, s2_value_reg__last_old_value__dbg, s2_value_reg__last_value, s2_value_reg__last_value__dbg, s2_value_reg__last_write_site, s2_value_reg__next_write_site, s2_value_reg__wrote_any, s2_value_reg__wrote_any__dbg, s2_value_reg__wrote_index0, s2_value_reg__wrote_index0__dbg;
{
  // initialize inboxes
  s1_inbox_count := 0;
  s1_pkt_external := false;
  s2_inbox_count := 0;
  s2_pkt_external := false;
  h1_inbox_count := 0;
  h1_pkt_external := false;
  // initialize P4B event flags (clone/recirculate)
  s1_p4b_clone_i2e := false;
  s1_p4b_clone_e2e := false;
  s1_p4b_clone_i2i := false;
  s1_p4b_recirculate := false;
  s2_p4b_clone_i2e := false;
  s2_p4b_clone_e2e := false;
  s2_p4b_clone_i2i := false;
  s2_p4b_recirculate := false;

  // initialize P4 registers (default 0)
  assume (forall i:bv32 :: s1_sequence_reg[i] == 0bv16);
  assume s1_sequence_reg[0bv32] == 0bv16;
  assume (forall i:bv32 :: s1_value_reg[i] == 0bv128);
  assume s1_value_reg[0bv32] == 0bv128;
  assume (forall i:bv32 :: s2_sequence_reg[i] == 0bv16);
  assume s2_sequence_reg[0bv32] == 0bv16;
  assume (forall i:bv32 :: s2_value_reg[i] == 0bv128);
  assume s2_value_reg[0bv32] == 0bv128;
  // initialize register write tracking (debug)
  s1_sequence_reg__last_index := 0bv32;
  s1_sequence_reg__last_value := 0bv16;
  s1_sequence_reg__last_old_value := 0bv16;
  s1_sequence_reg__wrote_any := false;
  s1_sequence_reg__wrote_index0 := false;
  s1_sequence_reg__next_write_site := 0;
  s1_sequence_reg__last_write_site := 0;
  s1_sequence_reg__last0_old_value := 0bv16;
  s1_sequence_reg__last0_value := 0bv16;
  s1_value_reg__last_index := 0bv32;
  s1_value_reg__last_value := 0bv128;
  s1_value_reg__last_old_value := 0bv128;
  s1_value_reg__wrote_any := false;
  s1_value_reg__wrote_index0 := false;
  s1_value_reg__next_write_site := 0;
  s1_value_reg__last_write_site := 0;
  s1_value_reg__last0_old_value := 0bv128;
  s1_value_reg__last0_value := 0bv128;
  s2_sequence_reg__last_index := 0bv32;
  s2_sequence_reg__last_value := 0bv16;
  s2_sequence_reg__last_old_value := 0bv16;
  s2_sequence_reg__wrote_any := false;
  s2_sequence_reg__wrote_index0 := false;
  s2_sequence_reg__next_write_site := 0;
  s2_sequence_reg__last_write_site := 0;
  s2_sequence_reg__last0_old_value := 0bv16;
  s2_sequence_reg__last0_value := 0bv16;
  s2_value_reg__last_index := 0bv32;
  s2_value_reg__last_value := 0bv128;
  s2_value_reg__last_old_value := 0bv128;
  s2_value_reg__wrote_any := false;
  s2_value_reg__wrote_index0 := false;
  s2_value_reg__next_write_site := 0;
  s2_value_reg__last_write_site := 0;
  s2_value_reg__last0_old_value := 0bv128;
  s2_value_reg__last0_value := 0bv128;

  procurator_step := 0;
  procurator_phase := 0;
  // wraparound confirm fast-forward (generated)
  s1_sequence_reg[0bv32] := 65535bv16;

  s1_sequence_reg__last_index := 0bv32;

  s1_sequence_reg__last_value := 65535bv16;

  s1_sequence_reg__wrote_any := true;

  if (0bv32 == 0bv32) {

    s1_sequence_reg__wrote_index0 := true;

    s1_sequence_reg__last0_value := 65535bv16;

  }
  s2_sequence_reg[0bv32] := 65535bv16;

  s2_sequence_reg__last_index := 0bv32;

  s2_sequence_reg__last_value := 65535bv16;

  s2_sequence_reg__wrote_any := true;

  if (0bv32 == 0bv32) {

    s2_sequence_reg__wrote_index0 := true;

    s2_sequence_reg__last0_value := 65535bv16;

  }
  // wraparound dynamic-index slot defaults (generated)
  assume s1_value_reg[0bv32] == 0bv128;
  assume s2_value_reg[0bv32] == 0bv128;


  // UNROLLED 4 steps (wraparound)
    // wraparound inlined phase 0 (generated)
    assume procurator_phase == 0;
    // host send -> h1
    // inject packet into connected node (host -> node)
    if (s1_inbox_count < 1) {
      assume s1_inbox_count < 1;
      havoc h1_standard_metadata.ingress_port;
      havoc h1_standard_metadata.instance_type;
      havoc h1_standard_metadata.packet_length;
      havoc h1_standard_metadata.enq_timestamp;
      havoc h1_standard_metadata.enq_qdepth;
      havoc h1_standard_metadata.deq_timedelta;
      havoc h1_standard_metadata.deq_qdepth;
      havoc h1_standard_metadata.ingress_global_timestamp;
      havoc h1_standard_metadata.egress_global_timestamp;
      havoc h1_standard_metadata.mcast_grp;
      havoc h1_standard_metadata.egress_rid;
      havoc h1_standard_metadata.checksum_error;
      havoc h1_standard_metadata.parser_error;
      havoc h1_standard_metadata.priority;
      havoc h1_meta.location;
      havoc h1_meta.location.index;
      havoc h1_meta.my_md;
      havoc h1_meta.my_md.ipaddress;
      havoc h1_meta.my_md.role;
      havoc h1_meta.my_md.failed;
      havoc h1_meta.reply_to_client_md;
      havoc h1_meta.reply_to_client_md.ipv4_srcAddr;
      havoc h1_meta.reply_to_client_md.ipv4_dstAddr;
      havoc h1_meta.sequence_md;
      havoc h1_meta.sequence_md.seq;
      havoc h1_meta.sequence_md.tmp;
      havoc h1_hdr.ethernet.dstAddr;
      havoc h1_hdr.ethernet.srcAddr;
      havoc h1_hdr.ipv4.version;
      havoc h1_hdr.ipv4.ihl;
      havoc h1_hdr.ipv4.diffserv;
      havoc h1_hdr.ipv4.totalLen;
      havoc h1_hdr.ipv4.identification;
      havoc h1_hdr.ipv4.flags;
      havoc h1_hdr.ipv4.fragOffset;
      havoc h1_hdr.ipv4.ttl;
      havoc h1_hdr.ipv4.hdrChecksum;
      havoc h1_hdr.nc_hdr.sc;
      havoc h1_hdr.nc_hdr.value;
      havoc h1_hdr.nc_hdr.vgroup;
      havoc h1_hdr.tcp.srcPort;
      havoc h1_hdr.tcp.dstPort;
      havoc h1_hdr.tcp.seqNo;
      havoc h1_hdr.tcp.ackNo;
      havoc h1_hdr.tcp.dataOffset;
      havoc h1_hdr.tcp.res;
      havoc h1_hdr.tcp.ecn;
      havoc h1_hdr.tcp.ctrl;
      havoc h1_hdr.tcp.window;
      havoc h1_hdr.tcp.checksum;
      havoc h1_hdr.tcp.urgentPtr;
      havoc h1_hdr.udp.srcPort;
      havoc h1_hdr.udp.dstPort;
      havoc h1_hdr.udp.len;
      havoc h1_hdr.udp.checksum;
      havoc h1_hdr.overlay.last.valid;
      havoc h1_hdr.overlay.last.swip;
      havoc h1_hdr.overlay.4.valid;
      havoc h1_hdr.overlay.4.swip;
      havoc h1_hdr.overlay.5.valid;
      havoc h1_hdr.overlay.5.swip;
      havoc h1_hdr.overlay.6.valid;
      havoc h1_hdr.overlay.6.swip;
      havoc h1_hdr.overlay.7.valid;
      havoc h1_hdr.overlay.7.swip;
      havoc h1_hdr.overlay.8.valid;
      havoc h1_hdr.overlay.8.swip;
      havoc h1_hdr.overlay.9.valid;
      havoc h1_hdr.overlay.9.swip;
      h1_hdr.ethernet.valid := true;
      h1_hdr.ipv4.valid := true;
      h1_hdr.nc_hdr.valid := true;
      h1_hdr.udp.valid := true;
      h1_hdr.tcp.valid := false;
      h1_hdr.ipv4.protocol := 17bv8;
      h1_hdr.overlay.0.valid := true;
      h1_hdr.overlay.1.valid := true;
      h1_hdr.overlay.2.valid := true;
      h1_hdr.overlay.3.valid := true;
      h1_hdr.ethernet.etherType := 2048bv16;
      h1_hdr.ipv4.srcAddr := 1bv32;
      h1_hdr.ipv4.dstAddr := 167797761bv32;
      h1_hdr.overlay.0.swip := 167797761bv32;
      h1_hdr.overlay.1.swip := 167797762bv32;
      h1_hdr.overlay.2.swip := 0bv32;
      h1_hdr.overlay.3.swip := 0bv32;
      h1_hdr.nc_hdr.op := 12bv8;
      h1_hdr.nc_hdr.key := 2024bv128;
      h1_hdr.nc_hdr.seq := 1bv16;
      assume (s1_meta.location.index == 0bv16);
      assume (s2_meta.location.index == 0bv16);
      assume (s1_find_index.hit == true);
      assume (s2_find_index.hit == true);
      assume (s1_meta.my_md.role == 100bv16);
      assume (s2_meta.my_md.role == 101bv16);
      assume (s1_standard_metadata.egress_port != 0bv9);
      s1_standard_metadata.ingress_port := h1_standard_metadata.ingress_port;
      s1_standard_metadata.instance_type := h1_standard_metadata.instance_type;
      s1_standard_metadata.packet_length := h1_standard_metadata.packet_length;
      s1_standard_metadata.enq_timestamp := h1_standard_metadata.enq_timestamp;
      s1_standard_metadata.enq_qdepth := h1_standard_metadata.enq_qdepth;
      s1_standard_metadata.deq_timedelta := h1_standard_metadata.deq_timedelta;
      s1_standard_metadata.deq_qdepth := h1_standard_metadata.deq_qdepth;
      s1_standard_metadata.ingress_global_timestamp := h1_standard_metadata.ingress_global_timestamp;
      s1_standard_metadata.egress_global_timestamp := h1_standard_metadata.egress_global_timestamp;
      s1_standard_metadata.mcast_grp := h1_standard_metadata.mcast_grp;
      s1_standard_metadata.egress_rid := h1_standard_metadata.egress_rid;
      s1_standard_metadata.checksum_error := h1_standard_metadata.checksum_error;
      s1_standard_metadata.parser_error := h1_standard_metadata.parser_error;
      s1_standard_metadata.priority := h1_standard_metadata.priority;
      s1_meta.location := h1_meta.location;
      s1_meta.location.index := h1_meta.location.index;
      s1_meta.my_md := h1_meta.my_md;
      s1_meta.my_md.ipaddress := h1_meta.my_md.ipaddress;
      s1_meta.my_md.role := h1_meta.my_md.role;
      s1_meta.my_md.failed := h1_meta.my_md.failed;
      s1_meta.reply_to_client_md := h1_meta.reply_to_client_md;
      s1_meta.reply_to_client_md.ipv4_srcAddr := h1_meta.reply_to_client_md.ipv4_srcAddr;
      s1_meta.reply_to_client_md.ipv4_dstAddr := h1_meta.reply_to_client_md.ipv4_dstAddr;
      s1_meta.sequence_md := h1_meta.sequence_md;
      s1_meta.sequence_md.seq := h1_meta.sequence_md.seq;
      s1_meta.sequence_md.tmp := h1_meta.sequence_md.tmp;
      s1_hdr.ethernet.valid := h1_hdr.ethernet.valid;
      s1_hdr.ethernet.dstAddr := h1_hdr.ethernet.dstAddr;
      s1_hdr.ethernet.srcAddr := h1_hdr.ethernet.srcAddr;
      s1_hdr.ethernet.etherType := 2048bv16;
      s1_hdr.ipv4.valid := h1_hdr.ipv4.valid;
      s1_hdr.ipv4.version := h1_hdr.ipv4.version;
      s1_hdr.ipv4.ihl := h1_hdr.ipv4.ihl;
      s1_hdr.ipv4.diffserv := h1_hdr.ipv4.diffserv;
      s1_hdr.ipv4.totalLen := h1_hdr.ipv4.totalLen;
      s1_hdr.ipv4.identification := h1_hdr.ipv4.identification;
      s1_hdr.ipv4.flags := h1_hdr.ipv4.flags;
      s1_hdr.ipv4.fragOffset := h1_hdr.ipv4.fragOffset;
      s1_hdr.ipv4.ttl := h1_hdr.ipv4.ttl;
      s1_hdr.ipv4.protocol := 17bv8;
      s1_hdr.ipv4.hdrChecksum := h1_hdr.ipv4.hdrChecksum;
      s1_hdr.ipv4.srcAddr := 1bv32;
      s1_hdr.ipv4.dstAddr := 167797761bv32;
      s1_hdr.nc_hdr.valid := h1_hdr.nc_hdr.valid;
      s1_hdr.nc_hdr.op := 12bv8;
      s1_hdr.nc_hdr.sc := h1_hdr.nc_hdr.sc;
      s1_hdr.nc_hdr.seq := 1bv16;
      s1_hdr.nc_hdr.key := 2024bv128;
      s1_hdr.nc_hdr.value := h1_hdr.nc_hdr.value;
      s1_hdr.nc_hdr.vgroup := h1_hdr.nc_hdr.vgroup;
      s1_hdr.tcp.valid := h1_hdr.tcp.valid;
      s1_hdr.tcp.srcPort := h1_hdr.tcp.srcPort;
      s1_hdr.tcp.dstPort := h1_hdr.tcp.dstPort;
      s1_hdr.tcp.seqNo := h1_hdr.tcp.seqNo;
      s1_hdr.tcp.ackNo := h1_hdr.tcp.ackNo;
      s1_hdr.tcp.dataOffset := h1_hdr.tcp.dataOffset;
      s1_hdr.tcp.res := h1_hdr.tcp.res;
      s1_hdr.tcp.ecn := h1_hdr.tcp.ecn;
      s1_hdr.tcp.ctrl := h1_hdr.tcp.ctrl;
      s1_hdr.tcp.window := h1_hdr.tcp.window;
      s1_hdr.tcp.checksum := h1_hdr.tcp.checksum;
      s1_hdr.tcp.urgentPtr := h1_hdr.tcp.urgentPtr;
      s1_hdr.udp.valid := h1_hdr.udp.valid;
      s1_hdr.udp.srcPort := h1_hdr.udp.srcPort;
      s1_hdr.udp.dstPort := h1_hdr.udp.dstPort;
      s1_hdr.udp.len := h1_hdr.udp.len;
      s1_hdr.udp.checksum := h1_hdr.udp.checksum;
      s1_hdr.overlay.last.valid := h1_hdr.overlay.last.valid;
      s1_hdr.overlay.last.swip := h1_hdr.overlay.last.swip;
      s1_hdr.overlay.0.valid := h1_hdr.overlay.0.valid;
      s1_hdr.overlay.0.swip := 167797761bv32;
      s1_hdr.overlay.1.valid := h1_hdr.overlay.1.valid;
      s1_hdr.overlay.1.swip := 167797762bv32;
      s1_hdr.overlay.2.valid := h1_hdr.overlay.2.valid;
      s1_hdr.overlay.2.swip := 0bv32;
      s1_hdr.overlay.3.valid := h1_hdr.overlay.3.valid;
      s1_hdr.overlay.3.swip := 0bv32;
      s1_hdr.overlay.4.valid := h1_hdr.overlay.4.valid;
      s1_hdr.overlay.4.swip := h1_hdr.overlay.4.swip;
      s1_hdr.overlay.5.valid := h1_hdr.overlay.5.valid;
      s1_hdr.overlay.5.swip := h1_hdr.overlay.5.swip;
      s1_hdr.overlay.6.valid := h1_hdr.overlay.6.valid;
      s1_hdr.overlay.6.swip := h1_hdr.overlay.6.swip;
      s1_hdr.overlay.7.valid := h1_hdr.overlay.7.valid;
      s1_hdr.overlay.7.swip := h1_hdr.overlay.7.swip;
      s1_hdr.overlay.8.valid := h1_hdr.overlay.8.valid;
      s1_hdr.overlay.8.swip := h1_hdr.overlay.8.swip;
      s1_hdr.overlay.9.valid := h1_hdr.overlay.9.valid;
      s1_hdr.overlay.9.swip := h1_hdr.overlay.9.swip;
      s1_pkt_external := true;
      s1_inbox_count := s1_inbox_count + 1;
    }
    procurator_phase := 1;
    procurator_step := procurator_step + 1;
    // wraparound inlined phase 1 (generated)
    assume procurator_phase == 1;
    // host recv -> h1
    procurator_phase := 2;
    procurator_step := procurator_step + 1;
    // wraparound inlined phase 2 (generated)
    assume procurator_phase == 2;
    // node pass -> s1
    if (s1_inbox_count > 0) {
    assume s1_inbox_count > 0;
    s1_inbox_count := s1_inbox_count - 1;
    call s1_mainProcedure();
    if (s1_p4b_clone_i2e) {
      assume s1_inbox_count < 1;
      s1_pkt_external := false;
      s1_inbox_count := s1_inbox_count + 1;
    }
    s1_p4b_clone_i2e := false;
    if (s1_p4b_clone_e2e) {
      assume s1_inbox_count < 1;
      s1_pkt_external := false;
      s1_inbox_count := s1_inbox_count + 1;
    }
    s1_p4b_clone_e2e := false;
    if (s1_p4b_clone_i2i) {
      assume s1_inbox_count < 1;
      s1_pkt_external := false;
      s1_inbox_count := s1_inbox_count + 1;
    }
    s1_p4b_clone_i2i := false;
    if (s1_p4b_recirculate) {
      assume s1_inbox_count < 1;
      s1_pkt_external := false;
      s1_inbox_count := s1_inbox_count + 1;
    }
    s1_p4b_recirculate := false;
    call s1_Forward();
    // Register debug snapshot
    s1_sequence_reg__dbg0 := s1_sequence_reg[0bv32];
    s1_sequence_reg__last_index__dbg := s1_sequence_reg__last_index;
    s1_sequence_reg__last_value__dbg := s1_sequence_reg__last_value;
    s1_sequence_reg__last_old_value__dbg := s1_sequence_reg__last_old_value;
    s1_sequence_reg__wrote_any__dbg := s1_sequence_reg__wrote_any;
    s1_sequence_reg__wrote_index0__dbg := s1_sequence_reg__wrote_index0;
    s1_sequence_reg__last0_old_value__dbg := s1_sequence_reg__last0_old_value;
    s1_sequence_reg__last0_value__dbg := s1_sequence_reg__last0_value;
    s1_value_reg__dbg0 := s1_value_reg[0bv32];
    s1_value_reg__last_index__dbg := s1_value_reg__last_index;
    s1_value_reg__last_value__dbg := s1_value_reg__last_value;
    s1_value_reg__last_old_value__dbg := s1_value_reg__last_old_value;
    s1_value_reg__wrote_any__dbg := s1_value_reg__wrote_any;
    s1_value_reg__wrote_index0__dbg := s1_value_reg__wrote_index0;
    s1_value_reg__last0_old_value__dbg := s1_value_reg__last0_old_value;
    s1_value_reg__last0_value__dbg := s1_value_reg__last0_value;
    s2_sequence_reg__dbg0 := s2_sequence_reg[0bv32];
    s2_sequence_reg__last_index__dbg := s2_sequence_reg__last_index;
    s2_sequence_reg__last_value__dbg := s2_sequence_reg__last_value;
    s2_sequence_reg__last_old_value__dbg := s2_sequence_reg__last_old_value;
    s2_sequence_reg__wrote_any__dbg := s2_sequence_reg__wrote_any;
    s2_sequence_reg__wrote_index0__dbg := s2_sequence_reg__wrote_index0;
    s2_sequence_reg__last0_old_value__dbg := s2_sequence_reg__last0_old_value;
    s2_sequence_reg__last0_value__dbg := s2_sequence_reg__last0_value;
    s2_value_reg__dbg0 := s2_value_reg[0bv32];
    s2_value_reg__last_index__dbg := s2_value_reg__last_index;
    s2_value_reg__last_value__dbg := s2_value_reg__last_value;
    s2_value_reg__last_old_value__dbg := s2_value_reg__last_old_value;
    s2_value_reg__wrote_any__dbg := s2_value_reg__wrote_any;
    s2_value_reg__wrote_index0__dbg := s2_value_reg__wrote_index0;
    s2_value_reg__last0_old_value__dbg := s2_value_reg__last0_old_value;
    s2_value_reg__last0_value__dbg := s2_value_reg__last0_value;
    // Global assertions
    call __wraparound_assert(bvule.bv16$builtin(s2_sequence_reg__dbg0, s1_sequence_reg__dbg0));
    }
    procurator_phase := 3;
    procurator_step := procurator_step + 1;
    // wraparound inlined phase 3 (generated)
    assume procurator_phase == 3;
    // node pass -> s2
    if (s2_inbox_count > 0) {
    assume s2_inbox_count > 0;
    s2_inbox_count := s2_inbox_count - 1;
    call s2_mainProcedure();
    if (s2_p4b_clone_i2e) {
      assume s2_inbox_count < 1;
      s2_pkt_external := false;
      s2_inbox_count := s2_inbox_count + 1;
    }
    s2_p4b_clone_i2e := false;
    if (s2_p4b_clone_e2e) {
      assume s2_inbox_count < 1;
      s2_pkt_external := false;
      s2_inbox_count := s2_inbox_count + 1;
    }
    s2_p4b_clone_e2e := false;
    if (s2_p4b_clone_i2i) {
      assume s2_inbox_count < 1;
      s2_pkt_external := false;
      s2_inbox_count := s2_inbox_count + 1;
    }
    s2_p4b_clone_i2i := false;
    if (s2_p4b_recirculate) {
      assume s2_inbox_count < 1;
      s2_pkt_external := false;
      s2_inbox_count := s2_inbox_count + 1;
    }
    s2_p4b_recirculate := false;
    call s2_Forward();
    // Register debug snapshot
    s1_sequence_reg__dbg0 := s1_sequence_reg[0bv32];
    s1_sequence_reg__last_index__dbg := s1_sequence_reg__last_index;
    s1_sequence_reg__last_value__dbg := s1_sequence_reg__last_value;
    s1_sequence_reg__last_old_value__dbg := s1_sequence_reg__last_old_value;
    s1_sequence_reg__wrote_any__dbg := s1_sequence_reg__wrote_any;
    s1_sequence_reg__wrote_index0__dbg := s1_sequence_reg__wrote_index0;
    s1_sequence_reg__last0_old_value__dbg := s1_sequence_reg__last0_old_value;
    s1_sequence_reg__last0_value__dbg := s1_sequence_reg__last0_value;
    s1_value_reg__dbg0 := s1_value_reg[0bv32];
    s1_value_reg__last_index__dbg := s1_value_reg__last_index;
    s1_value_reg__last_value__dbg := s1_value_reg__last_value;
    s1_value_reg__last_old_value__dbg := s1_value_reg__last_old_value;
    s1_value_reg__wrote_any__dbg := s1_value_reg__wrote_any;
    s1_value_reg__wrote_index0__dbg := s1_value_reg__wrote_index0;
    s1_value_reg__last0_old_value__dbg := s1_value_reg__last0_old_value;
    s1_value_reg__last0_value__dbg := s1_value_reg__last0_value;
    s2_sequence_reg__dbg0 := s2_sequence_reg[0bv32];
    s2_sequence_reg__last_index__dbg := s2_sequence_reg__last_index;
    s2_sequence_reg__last_value__dbg := s2_sequence_reg__last_value;
    s2_sequence_reg__last_old_value__dbg := s2_sequence_reg__last_old_value;
    s2_sequence_reg__wrote_any__dbg := s2_sequence_reg__wrote_any;
    s2_sequence_reg__wrote_index0__dbg := s2_sequence_reg__wrote_index0;
    s2_sequence_reg__last0_old_value__dbg := s2_sequence_reg__last0_old_value;
    s2_sequence_reg__last0_value__dbg := s2_sequence_reg__last0_value;
    s2_value_reg__dbg0 := s2_value_reg[0bv32];
    s2_value_reg__last_index__dbg := s2_value_reg__last_index;
    s2_value_reg__last_value__dbg := s2_value_reg__last_value;
    s2_value_reg__last_old_value__dbg := s2_value_reg__last_old_value;
    s2_value_reg__wrote_any__dbg := s2_value_reg__wrote_any;
    s2_value_reg__wrote_index0__dbg := s2_value_reg__wrote_index0;
    s2_value_reg__last0_old_value__dbg := s2_value_reg__last0_old_value;
    s2_value_reg__last0_value__dbg := s2_value_reg__last0_value;
    // Global assertions
    call __wraparound_assert(bvule.bv16$builtin(s2_sequence_reg__dbg0, s1_sequence_reg__dbg0));
    }
    procurator_phase := 0;
    procurator_step := procurator_step + 1;
}


procedure ULTIMATE.start() returns()
  modifies h1_hdr.ethernet.dstAddr, h1_hdr.ethernet.etherType, h1_hdr.ethernet.srcAddr, h1_hdr.ethernet.valid, h1_hdr.ipv4.diffserv, h1_hdr.ipv4.dstAddr, h1_hdr.ipv4.flags, h1_hdr.ipv4.fragOffset, h1_hdr.ipv4.hdrChecksum, h1_hdr.ipv4.identification, h1_hdr.ipv4.ihl, h1_hdr.ipv4.protocol, h1_hdr.ipv4.srcAddr, h1_hdr.ipv4.totalLen, h1_hdr.ipv4.ttl, h1_hdr.ipv4.valid, h1_hdr.ipv4.version, h1_hdr.nc_hdr.key, h1_hdr.nc_hdr.op, h1_hdr.nc_hdr.sc, h1_hdr.nc_hdr.seq, h1_hdr.nc_hdr.valid, h1_hdr.nc_hdr.value, h1_hdr.nc_hdr.vgroup, h1_hdr.overlay.0.swip, h1_hdr.overlay.0.valid, h1_hdr.overlay.1.swip, h1_hdr.overlay.1.valid, h1_hdr.overlay.2.swip, h1_hdr.overlay.2.valid, h1_hdr.overlay.3.swip, h1_hdr.overlay.3.valid, h1_hdr.overlay.4.swip, h1_hdr.overlay.4.valid, h1_hdr.overlay.5.swip, h1_hdr.overlay.5.valid, h1_hdr.overlay.6.swip, h1_hdr.overlay.6.valid, h1_hdr.overlay.7.swip, h1_hdr.overlay.7.valid, h1_hdr.overlay.8.swip, h1_hdr.overlay.8.valid, h1_hdr.overlay.9.swip, h1_hdr.overlay.9.valid, h1_hdr.overlay.last.swip, h1_hdr.overlay.last.valid, h1_hdr.tcp.ackNo, h1_hdr.tcp.checksum, h1_hdr.tcp.ctrl, h1_hdr.tcp.dataOffset, h1_hdr.tcp.dstPort, h1_hdr.tcp.ecn, h1_hdr.tcp.res, h1_hdr.tcp.seqNo, h1_hdr.tcp.srcPort, h1_hdr.tcp.urgentPtr, h1_hdr.tcp.valid, h1_hdr.tcp.window, h1_hdr.udp.checksum, h1_hdr.udp.dstPort, h1_hdr.udp.len, h1_hdr.udp.srcPort, h1_hdr.udp.valid, h1_inbox_count, h1_meta.location, h1_meta.location.index, h1_meta.my_md, h1_meta.my_md.failed, h1_meta.my_md.ipaddress, h1_meta.my_md.role, h1_meta.reply_to_client_md, h1_meta.reply_to_client_md.ipv4_dstAddr, h1_meta.reply_to_client_md.ipv4_srcAddr, h1_meta.sequence_md, h1_meta.sequence_md.seq, h1_meta.sequence_md.tmp, h1_pkt_external, h1_standard_metadata.checksum_error, h1_standard_metadata.deq_qdepth, h1_standard_metadata.deq_timedelta, h1_standard_metadata.egress_global_timestamp, h1_standard_metadata.egress_rid, h1_standard_metadata.enq_qdepth, h1_standard_metadata.enq_timestamp, h1_standard_metadata.ingress_global_timestamp, h1_standard_metadata.ingress_port, h1_standard_metadata.instance_type, h1_standard_metadata.mcast_grp, h1_standard_metadata.packet_length, h1_standard_metadata.parser_error, h1_standard_metadata.priority, procurator_phase, procurator_step, s1_assign_value.action_run, s1_assign_value.hit, s1_drop, s1_drop_packet.action_run, s1_drop_packet.hit, s1_ethernet_set_mac.action_run, s1_ethernet_set_mac.ethernet_set_mac_act.dmac, s1_ethernet_set_mac.ethernet_set_mac_act.smac, s1_ethernet_set_mac.hit, s1_failure_recovery.action_run, s1_failure_recovery.hit, s1_find_index.action_run, s1_find_index.find_index_act.index_1, s1_find_index.hit, s1_forward, s1_gen_reply.action_run, s1_gen_reply.gen_reply_act.message_type, s1_gen_reply.hit, s1_get_my_address.action_run, s1_get_my_address.get_my_address_act.sw_ip, s1_get_my_address.get_my_address_act.sw_role, s1_get_my_address.hit, s1_get_next_hop.action_run, s1_get_next_hop.hit, s1_get_sequence.action_run, s1_get_sequence.hit, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.etherType, s1_hdr.ethernet.srcAddr, s1_hdr.ethernet.valid, s1_hdr.ipv4.diffserv, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.flags, s1_hdr.ipv4.fragOffset, s1_hdr.ipv4.hdrChecksum, s1_hdr.ipv4.identification, s1_hdr.ipv4.ihl, s1_hdr.ipv4.protocol, s1_hdr.ipv4.srcAddr, s1_hdr.ipv4.totalLen, s1_hdr.ipv4.ttl, s1_hdr.ipv4.valid, s1_hdr.ipv4.version, s1_hdr.nc_hdr.key, s1_hdr.nc_hdr.op, s1_hdr.nc_hdr.sc, s1_hdr.nc_hdr.seq, s1_hdr.nc_hdr.valid, s1_hdr.nc_hdr.value, s1_hdr.nc_hdr.vgroup, s1_hdr.overlay.0.swip, s1_hdr.overlay.0.valid, s1_hdr.overlay.1.swip, s1_hdr.overlay.1.valid, s1_hdr.overlay.2.swip, s1_hdr.overlay.2.valid, s1_hdr.overlay.3.swip, s1_hdr.overlay.3.valid, s1_hdr.overlay.4.swip, s1_hdr.overlay.4.valid, s1_hdr.overlay.5.swip, s1_hdr.overlay.5.valid, s1_hdr.overlay.6.swip, s1_hdr.overlay.6.valid, s1_hdr.overlay.7.swip, s1_hdr.overlay.7.valid, s1_hdr.overlay.8.swip, s1_hdr.overlay.8.valid, s1_hdr.overlay.9.swip, s1_hdr.overlay.9.valid, s1_hdr.overlay.last.swip, s1_hdr.overlay.last.valid, s1_hdr.tcp.ackNo, s1_hdr.tcp.checksum, s1_hdr.tcp.ctrl, s1_hdr.tcp.dataOffset, s1_hdr.tcp.dstPort, s1_hdr.tcp.ecn, s1_hdr.tcp.res, s1_hdr.tcp.seqNo, s1_hdr.tcp.srcPort, s1_hdr.tcp.urgentPtr, s1_hdr.tcp.valid, s1_hdr.tcp.window, s1_hdr.udp.checksum, s1_hdr.udp.dstPort, s1_hdr.udp.len, s1_hdr.udp.srcPort, s1_hdr.udp.valid, s1_inbox_count, s1_ipv4_route.action_run, s1_ipv4_route.hit, s1_ipv4_route.set_egress.egress_spec_1, s1_isValid, s1_maintain_sequence.action_run, s1_maintain_sequence.hit, s1_meta.location, s1_meta.location.index, s1_meta.my_md, s1_meta.my_md.failed, s1_meta.my_md.ipaddress, s1_meta.my_md.role, s1_meta.reply_to_client_md, s1_meta.reply_to_client_md.ipv4_dstAddr, s1_meta.reply_to_client_md.ipv4_srcAddr, s1_meta.sequence_md, s1_meta.sequence_md.seq, s1_meta.sequence_md.tmp, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_external, s1_pop_chain.action_run, s1_pop_chain.hit, s1_pop_chain_again.action_run, s1_pop_chain_again.hit, s1_read_value.action_run, s1_read_value.hit, s1_sequence_reg, s1_sequence_reg__dbg0, s1_sequence_reg__last0_old_value, s1_sequence_reg__last0_old_value__dbg, s1_sequence_reg__last0_value, s1_sequence_reg__last0_value__dbg, s1_sequence_reg__last_index, s1_sequence_reg__last_index__dbg, s1_sequence_reg__last_old_value, s1_sequence_reg__last_old_value__dbg, s1_sequence_reg__last_value, s1_sequence_reg__last_value__dbg, s1_sequence_reg__last_write_site, s1_sequence_reg__next_write_site, s1_sequence_reg__wrote_any, s1_sequence_reg__wrote_any__dbg, s1_sequence_reg__wrote_index0, s1_sequence_reg__wrote_index0__dbg, s1_stack.index, s1_standard_metadata.checksum_error, s1_standard_metadata.deq_qdepth, s1_standard_metadata.deq_timedelta, s1_standard_metadata.egress_global_timestamp, s1_standard_metadata.egress_port, s1_standard_metadata.egress_rid, s1_standard_metadata.egress_spec, s1_standard_metadata.enq_qdepth, s1_standard_metadata.enq_timestamp, s1_standard_metadata.ingress_global_timestamp, s1_standard_metadata.ingress_port, s1_standard_metadata.instance_type, s1_standard_metadata.mcast_grp, s1_standard_metadata.packet_length, s1_standard_metadata.parser_error, s1_standard_metadata.priority, s1_value_reg, s1_value_reg__dbg0, s1_value_reg__last0_old_value, s1_value_reg__last0_old_value__dbg, s1_value_reg__last0_value, s1_value_reg__last0_value__dbg, s1_value_reg__last_index, s1_value_reg__last_index__dbg, s1_value_reg__last_old_value, s1_value_reg__last_old_value__dbg, s1_value_reg__last_value, s1_value_reg__last_value__dbg, s1_value_reg__last_write_site, s1_value_reg__next_write_site, s1_value_reg__wrote_any, s1_value_reg__wrote_any__dbg, s1_value_reg__wrote_index0, s1_value_reg__wrote_index0__dbg, s2_assign_value.action_run, s2_assign_value.hit, s2_drop, s2_drop_packet.action_run, s2_drop_packet.hit, s2_ethernet_set_mac.action_run, s2_ethernet_set_mac.ethernet_set_mac_act.dmac, s2_ethernet_set_mac.ethernet_set_mac_act.smac, s2_ethernet_set_mac.hit, s2_failure_recovery.action_run, s2_failure_recovery.hit, s2_find_index.action_run, s2_find_index.find_index_act.index_1, s2_find_index.hit, s2_forward, s2_gen_reply.action_run, s2_gen_reply.gen_reply_act.message_type, s2_gen_reply.hit, s2_get_my_address.action_run, s2_get_my_address.get_my_address_act.sw_ip, s2_get_my_address.get_my_address_act.sw_role, s2_get_my_address.hit, s2_get_next_hop.action_run, s2_get_next_hop.hit, s2_get_sequence.action_run, s2_get_sequence.hit, s2_hdr.ethernet.dstAddr, s2_hdr.ethernet.etherType, s2_hdr.ethernet.srcAddr, s2_hdr.ethernet.valid, s2_hdr.ipv4.diffserv, s2_hdr.ipv4.dstAddr, s2_hdr.ipv4.flags, s2_hdr.ipv4.fragOffset, s2_hdr.ipv4.hdrChecksum, s2_hdr.ipv4.identification, s2_hdr.ipv4.ihl, s2_hdr.ipv4.protocol, s2_hdr.ipv4.srcAddr, s2_hdr.ipv4.totalLen, s2_hdr.ipv4.ttl, s2_hdr.ipv4.valid, s2_hdr.ipv4.version, s2_hdr.nc_hdr.key, s2_hdr.nc_hdr.op, s2_hdr.nc_hdr.sc, s2_hdr.nc_hdr.seq, s2_hdr.nc_hdr.valid, s2_hdr.nc_hdr.value, s2_hdr.nc_hdr.vgroup, s2_hdr.overlay.0.swip, s2_hdr.overlay.0.valid, s2_hdr.overlay.1.swip, s2_hdr.overlay.1.valid, s2_hdr.overlay.2.swip, s2_hdr.overlay.2.valid, s2_hdr.overlay.3.swip, s2_hdr.overlay.3.valid, s2_hdr.overlay.4.swip, s2_hdr.overlay.4.valid, s2_hdr.overlay.5.swip, s2_hdr.overlay.5.valid, s2_hdr.overlay.6.swip, s2_hdr.overlay.6.valid, s2_hdr.overlay.7.swip, s2_hdr.overlay.7.valid, s2_hdr.overlay.8.swip, s2_hdr.overlay.8.valid, s2_hdr.overlay.9.swip, s2_hdr.overlay.9.valid, s2_hdr.overlay.last.swip, s2_hdr.overlay.last.valid, s2_hdr.tcp.ackNo, s2_hdr.tcp.checksum, s2_hdr.tcp.ctrl, s2_hdr.tcp.dataOffset, s2_hdr.tcp.dstPort, s2_hdr.tcp.ecn, s2_hdr.tcp.res, s2_hdr.tcp.seqNo, s2_hdr.tcp.srcPort, s2_hdr.tcp.urgentPtr, s2_hdr.tcp.valid, s2_hdr.tcp.window, s2_hdr.udp.checksum, s2_hdr.udp.dstPort, s2_hdr.udp.len, s2_hdr.udp.srcPort, s2_hdr.udp.valid, s2_inbox_count, s2_ipv4_route.action_run, s2_ipv4_route.hit, s2_ipv4_route.set_egress.egress_spec_1, s2_isValid, s2_maintain_sequence.action_run, s2_maintain_sequence.hit, s2_meta.location, s2_meta.location.index, s2_meta.my_md, s2_meta.my_md.failed, s2_meta.my_md.ipaddress, s2_meta.my_md.role, s2_meta.reply_to_client_md, s2_meta.reply_to_client_md.ipv4_dstAddr, s2_meta.reply_to_client_md.ipv4_srcAddr, s2_meta.sequence_md, s2_meta.sequence_md.seq, s2_meta.sequence_md.tmp, s2_p4b_checksum_error, s2_p4b_checksum_updated, s2_p4b_checksum_verified, s2_p4b_clone_e2e, s2_p4b_clone_i2e, s2_p4b_clone_i2i, s2_p4b_digest, s2_p4b_recirculate, s2_pkt_external, s2_pop_chain.action_run, s2_pop_chain.hit, s2_pop_chain_again.action_run, s2_pop_chain_again.hit, s2_read_value.action_run, s2_read_value.hit, s2_sequence_reg, s2_sequence_reg__dbg0, s2_sequence_reg__last0_old_value, s2_sequence_reg__last0_old_value__dbg, s2_sequence_reg__last0_value, s2_sequence_reg__last0_value__dbg, s2_sequence_reg__last_index, s2_sequence_reg__last_index__dbg, s2_sequence_reg__last_old_value, s2_sequence_reg__last_old_value__dbg, s2_sequence_reg__last_value, s2_sequence_reg__last_value__dbg, s2_sequence_reg__last_write_site, s2_sequence_reg__next_write_site, s2_sequence_reg__wrote_any, s2_sequence_reg__wrote_any__dbg, s2_sequence_reg__wrote_index0, s2_sequence_reg__wrote_index0__dbg, s2_stack.index, s2_standard_metadata.checksum_error, s2_standard_metadata.deq_qdepth, s2_standard_metadata.deq_timedelta, s2_standard_metadata.egress_global_timestamp, s2_standard_metadata.egress_port, s2_standard_metadata.egress_rid, s2_standard_metadata.egress_spec, s2_standard_metadata.enq_qdepth, s2_standard_metadata.enq_timestamp, s2_standard_metadata.ingress_global_timestamp, s2_standard_metadata.ingress_port, s2_standard_metadata.instance_type, s2_standard_metadata.mcast_grp, s2_standard_metadata.packet_length, s2_standard_metadata.parser_error, s2_standard_metadata.priority, s2_value_reg, s2_value_reg__dbg0, s2_value_reg__last0_old_value, s2_value_reg__last0_old_value__dbg, s2_value_reg__last0_value, s2_value_reg__last0_value__dbg, s2_value_reg__last_index, s2_value_reg__last_index__dbg, s2_value_reg__last_old_value, s2_value_reg__last_old_value__dbg, s2_value_reg__last_value, s2_value_reg__last_value__dbg, s2_value_reg__last_write_site, s2_value_reg__next_write_site, s2_value_reg__wrote_any, s2_value_reg__wrote_any__dbg, s2_value_reg__wrote_index0, s2_value_reg__wrote_index0__dbg;
{
  call mainProcedure();
}

// ===== END HARNESS =====
procedure {:inline 1} __wraparound_assert(cond: bool) returns()
{
  if ((s1_sequence_reg__last0_value != 65535bv16) || (s2_sequence_reg__last0_value != 65535bv16)) {
    assert cond;
  } else {
    assume true;
  }
}

