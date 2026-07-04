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
type s1_PortId_t = bv9;

// s1_Struct s1_standard_metadata_t
type s1_standard_metadata_t;
var s1_standard_metadata.ingress_port:s1_PortId_t;
var s1_standard_metadata.egress_spec:s1_PortId_t;
var s1_standard_metadata.egress_port:s1_PortId_t;
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

// s1_Struct s1_intrinsic_metadata_t
type s1_intrinsic_metadata_t;

// s1_Struct s1_ingress_metadata_t
type s1_ingress_metadata_t;
type s1_header_bfs_t;
type s1_header_ff_tags_t;

// s1_Struct s1_metadata
type s1_metadata;
var s1_meta.local_metadata:s1_ingress_metadata_t;
var s1_meta.local_metadata.pkt_start:bv1;
var s1_meta.local_metadata.pkt_curr:bv8;
var s1_meta.local_metadata.pkt_par:bv8;
var s1_meta.local_metadata.out_port:bv8;
var s1_meta.local_metadata.if_out_failed:bv8;
var s1_meta.local_metadata.first_visit:bv1;
var s1_meta.local_metadata.failure_visit:bv1;
var s1_meta.local_metadata.is_completed:bv1;
var s1_meta.local_metadata.starting_port:bv32;
var s1_meta.local_metadata.all_ports:bv32;
var s1_meta.local_metadata.out_port_xor:bv32;

// s1_Struct s1_headers
var s1_hdr:s1_Ref;

// s1_Header s1_header_bfs_t
var s1_hdr.bfsTag:s1_Ref;
var s1_hdr.bfsTag.valid:bool;
var s1_hdr.bfsTag.inst:bv32;
var s1_hdr.bfsTag.pkt_v1_curr:bv8;
var s1_hdr.bfsTag.pkt_v1_par:bv8;
var s1_hdr.bfsTag.pkt_v2_curr:bv8;
var s1_hdr.bfsTag.pkt_v2_par:bv8;
var s1_hdr.bfsTag.pkt_v3_curr:bv8;
var s1_hdr.bfsTag.pkt_v3_par:bv8;
var s1_hdr.bfsTag.pkt_v4_curr:bv8;
var s1_hdr.bfsTag.pkt_v4_par:bv8;

// s1_Header s1_header_ff_tags_t
var s1_hdr.ff_tags:s1_Ref;
var s1_hdr.ff_tags.valid:bool;
var s1_hdr.ff_tags.preamble:bv64;
var s1_hdr.ff_tags.shortest_path:bv8;
var s1_hdr.ff_tags.path_length:bv8;
var s1_hdr.ff_tags.is_edge:bv1;
var s1_hdr.ff_tags.bfs_start:bv1;

// s1_Register s1_pkt_curr
var s1_pkt_curr:[bv32]bv8;
var s1_pkt_curr__last_index:bv32;
var s1_pkt_curr__last_value:bv8;
var s1_pkt_curr__last_old_value:bv8;
var s1_pkt_curr__wrote_any:bool;
var s1_pkt_curr__wrote_index0:bool;
var s1_pkt_curr__last0_old_value:bv8;
var s1_pkt_curr__last0_value:bv8;
var s1_pkt_curr__next_write_site:int;
var s1_pkt_curr__last_write_site:int;
const s1_pkt_curr.size:bv32;
axiom s1_pkt_curr.size == 65536bv32;

// s1_Register s1_pkt_par
var s1_pkt_par:[bv32]bv8;
var s1_pkt_par__last_index:bv32;
var s1_pkt_par__last_value:bv8;
var s1_pkt_par__last_old_value:bv8;
var s1_pkt_par__wrote_any:bool;
var s1_pkt_par__wrote_index0:bool;
var s1_pkt_par__last0_old_value:bv8;
var s1_pkt_par__last0_value:bv8;
var s1_pkt_par__next_write_site:int;
var s1_pkt_par__last_write_site:int;
const s1_pkt_par.size:bv32;
axiom s1_pkt_par.size == 65536bv32;
var s1_meta:s1_metadata;
var s1_standard_metadata:s1_standard_metadata_t;

// s1_Register s1_all_ports_status
var s1_all_ports_status:[bv32]bv32;
var s1_all_ports_status__last_index:bv32;
var s1_all_ports_status__last_value:bv32;
var s1_all_ports_status__last_old_value:bv32;
var s1_all_ports_status__wrote_any:bool;
var s1_all_ports_status__wrote_index0:bool;
var s1_all_ports_status__last0_old_value:bv32;
var s1_all_ports_status__last0_value:bv32;
var s1_all_ports_status__next_write_site:int;
var s1_all_ports_status__last_write_site:int;
const s1_all_ports_status.size:bv32;
axiom s1_all_ports_status.size == 1bv32;

function {:builtin "bvadd"} add.bv8(s1_left:bv8, s1_right:bv8) returns(bv8);

// s1_Table s1_default_route s1_Actionlist s1_Declaration
type s1_default_route.action;
var s1_default_route.set_default_route.send_to:bv8;
const unique s1_default_route.action.set_default_route : s1_default_route.action;
const unique s1_default_route.action.NoAction : s1_default_route.action;
var s1_default_route.action_run : s1_default_route.action;
var s1_default_route.hit : bool;

// s1_Table s1_fwd_parent s1_Actionlist s1_Declaration
type s1_fwd_parent.action;
const unique s1_fwd_parent.action.towards_parent : s1_fwd_parent.action;
const unique s1_fwd_parent.action.NoAction_2 : s1_fwd_parent.action;
var s1_fwd_parent.action_run : s1_fwd_parent.action;
var s1_fwd_parent.hit : bool;

// s1_Table s1_fwd_pkt s1_Actionlist s1_Declaration
type s1_fwd_pkt.action;
var s1_fwd_pkt.fwd._port:bv9;
const unique s1_fwd_pkt.action.fwd : s1_fwd_pkt.action;
const unique s1_fwd_pkt.action.NoAction_3 : s1_fwd_pkt.action;
var s1_fwd_pkt.action_run : s1_fwd_pkt.action;
var s1_fwd_pkt.hit : bool;

// s1_Table s1_send_in_ingress s1_Actionlist s1_Declaration
type s1_send_in_ingress.action;
const unique s1_send_in_ingress.action.send_in : s1_send_in_ingress.action;
const unique s1_send_in_ingress.action.NoAction_4 : s1_send_in_ingress.action;
var s1_send_in_ingress.action_run : s1_send_in_ingress.action;
var s1_send_in_ingress.hit : bool;

// s1_Table s1_send_parent s1_Actionlist s1_Declaration
type s1_send_parent.action;
const unique s1_send_parent.action.send_on_parent : s1_send_parent.action;
const unique s1_send_parent.action.NoAction_5 : s1_send_parent.action;
var s1_send_parent.action_run : s1_send_parent.action;
var s1_send_parent.hit : bool;

// s1_Table s1_set_out_port s1_Actionlist s1_Declaration
type s1_set_out_port.action;
var s1_set_out_port.set_out_meta.meta_state:bv32;
const unique s1_set_out_port.action.set_out_meta : s1_set_out_port.action;
const unique s1_set_out_port.action.NoAction_6 : s1_set_out_port.action;
var s1_set_out_port.action_run : s1_set_out_port.action;
var s1_set_out_port.hit : bool;

// s1_Table s1_start_bfs s1_Actionlist s1_Declaration
type s1_start_bfs.action;
const unique s1_start_bfs.action.set_bfs_tags : s1_start_bfs.action;
const unique s1_start_bfs.action.NoAction_7 : s1_start_bfs.action;
var s1_start_bfs.action_run : s1_start_bfs.action;
var s1_start_bfs.hit : bool;

function {:builtin "bvult"} bult.bv8(s1_left:bv8, s1_right:bv8) returns(bool);

function {:builtin "bvxor"} bxor.bv32(s1_left:bv32, s1_right:bv32) returns(bv32);

// s1_Table s1_check_out_failed s1_Actionlist s1_Declaration
type s1_check_out_failed.action;
var s1_check_out_failed.skip_failures._working:bv8;
const unique s1_check_out_failed.action.skip_failures : s1_check_out_failed.action;
const unique s1_check_out_failed.action.NoAction_8 : s1_check_out_failed.action;
var s1_check_out_failed.action_run : s1_check_out_failed.action;
var s1_check_out_failed.hit : bool;

// s1_Table s1_check_outport_status s1_Actionlist s1_Declaration
type s1_check_outport_status.action;
var s1_check_outport_status.xor_outport._all_ports:bv32;
const unique s1_check_outport_status.action.xor_outport : s1_check_outport_status.action;
const unique s1_check_outport_status.action.NoAction_9 : s1_check_outport_status.action;
var s1_check_outport_status.action_run : s1_check_outport_status.action;
var s1_check_outport_status.hit : bool;

// s1_Table s1_curr_par_eq_neq_ingress s1_Actionlist s1_Declaration
type s1_curr_par_eq_neq_ingress.action;
const unique s1_curr_par_eq_neq_ingress.action.set_next_port : s1_curr_par_eq_neq_ingress.action;
const unique s1_curr_par_eq_neq_ingress.action.NoAction_10 : s1_curr_par_eq_neq_ingress.action;
var s1_curr_par_eq_neq_ingress.action_run : s1_curr_par_eq_neq_ingress.action;
var s1_curr_par_eq_neq_ingress.hit : bool;

// s1_Table s1_curr_par_eq_zero s1_Actionlist s1_Declaration
type s1_curr_par_eq_zero.action;
const unique s1_curr_par_eq_zero.action.set_par_to_ingress : s1_curr_par_eq_zero.action;
const unique s1_curr_par_eq_zero.action.NoAction_11 : s1_curr_par_eq_zero.action;
var s1_curr_par_eq_zero.action_run : s1_curr_par_eq_zero.action;
var s1_curr_par_eq_zero.hit : bool;

// s1_Table s1_curr_par_neq_in s1_Actionlist s1_Declaration
type s1_curr_par_neq_in.action;
const unique s1_curr_par_neq_in.action.set_out_to_ingress : s1_curr_par_neq_in.action;
const unique s1_curr_par_neq_in.action.NoAction_12 : s1_curr_par_neq_in.action;
var s1_curr_par_neq_in.action_run : s1_curr_par_neq_in.action;
var s1_curr_par_neq_in.hit : bool;

// s1_Table s1_hit_depth s1_Actionlist s1_Declaration
type s1_hit_depth.action;
const unique s1_hit_depth.action.go_to_next : s1_hit_depth.action;
var s1_hit_depth.action_run : s1_hit_depth.action;
var s1_hit_depth.hit : bool;

// s1_Table s1_if_status s1_Actionlist s1_Declaration
type s1_if_status.action;
var s1_if_status.set_if_status._value:bv8;
const unique s1_if_status.action.set_if_status : s1_if_status.action;
const unique s1_if_status.action.NoAction_13 : s1_if_status.action;
var s1_if_status.action_run : s1_if_status.action;
var s1_if_status.hit : bool;

// s1_Table s1_jump_to_next s1_Actionlist s1_Declaration
type s1_jump_to_next.action;
const unique s1_jump_to_next.action.skip_parent : s1_jump_to_next.action;
const unique s1_jump_to_next.action.NoAction_14 : s1_jump_to_next.action;
var s1_jump_to_next.action_run : s1_jump_to_next.action;
var s1_jump_to_next.hit : bool;

// s1_Table s1_out_eq_zero s1_Actionlist s1_Declaration
type s1_out_eq_zero.action;
const unique s1_out_eq_zero.action.start_from_one : s1_out_eq_zero.action;
const unique s1_out_eq_zero.action.NoAction_15 : s1_out_eq_zero.action;
var s1_out_eq_zero.action_run : s1_out_eq_zero.action;
var s1_out_eq_zero.hit : bool;

// s1_Table s1_set_egress_port s1_Actionlist s1_Declaration
type s1_set_egress_port.action;
var s1_set_egress_port.starting_port_meta.port_start:bv32;
const unique s1_set_egress_port.action.starting_port_meta : s1_set_egress_port.action;
const unique s1_set_egress_port.action.NoAction_16 : s1_set_egress_port.action;
var s1_set_egress_port.action_run : s1_set_egress_port.action;
var s1_set_egress_port.hit : bool;

// s1_Table s1_set_parent_out s1_Actionlist s1_Declaration
type s1_set_parent_out.action;
const unique s1_set_parent_out.action.send_to_parent : s1_set_parent_out.action;
var s1_set_parent_out.action_run : s1_set_parent_out.action;
var s1_set_parent_out.hit : bool;

// s1_Table s1_to_parent s1_Actionlist s1_Declaration
type s1_to_parent.action;
const unique s1_to_parent.action.outport_to_parent : s1_to_parent.action;
var s1_to_parent.action_run : s1_to_parent.action;
var s1_to_parent.hit : bool;

// s1_Table s1_try_next s1_Actionlist s1_Declaration
type s1_try_next.action;
const unique s1_try_next.action.next_outport : s1_try_next.action;
const unique s1_try_next.action.NoAction_17 : s1_try_next.action;
var s1_try_next.action_run : s1_try_next.action;
var s1_try_next.hit : bool;

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

// s1_Action s1_NoAction_16
procedure {:inline 1} s1_NoAction_16()
{
}

// s1_Action s1_NoAction_17
procedure {:inline 1} s1_NoAction_17()
{
}

// s1_Action s1_NoAction_2
procedure {:inline 1} s1_NoAction_2()
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
	modifies s1_drop, s1_isValid, s1_meta.local_metadata.pkt_curr, s1_meta.local_metadata.pkt_par, s1_meta.local_metadata.pkt_start;
{
    goto s1_State$ParserImpl$start;

        s1_State$ParserImpl$start:
    call s1_packet_in.extract(s1_hdr.ff_tags);
    call s1_packet_in.extract(s1_hdr.bfsTag);
    // s1_read
    s1_meta.local_metadata.pkt_curr := s1_pkt_curr.read(s1_pkt_curr, s1_hdr.bfsTag.inst);
    // s1_read
    s1_meta.local_metadata.pkt_par := s1_pkt_par.read(s1_pkt_par, s1_hdr.bfsTag.inst);
    s1_meta.local_metadata.pkt_start := s1_hdr.ff_tags.bfs_start;
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
function {:inline true}s1_all_ports_status.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_all_ports_status.write(s1_index:bv32, s1_value:bv32)
	modifies s1_all_ports_status, s1_all_ports_status__last0_old_value, s1_all_ports_status__last0_value, s1_all_ports_status__last_index, s1_all_ports_status__last_old_value, s1_all_ports_status__last_value, s1_all_ports_status__last_write_site, s1_all_ports_status__wrote_any, s1_all_ports_status__wrote_index0;
{
    s1_all_ports_status__last_old_value := s1_all_ports_status[s1_index];
    s1_all_ports_status[s1_index] := s1_value;
    s1_all_ports_status__last_index := s1_index;
    s1_all_ports_status__last_value := s1_value;
    s1_all_ports_status__last_write_site := s1_all_ports_status__next_write_site;
    s1_all_ports_status__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_all_ports_status__wrote_index0 := true;
        s1_all_ports_status__last0_old_value := s1_all_ports_status__last_old_value;
        s1_all_ports_status__last0_value := s1_value;
    }
}

// s1_Table s1_check_out_failed
procedure {:inline 1} s1_check_out_failed.apply()
	modifies s1_check_out_failed.action_run, s1_check_out_failed.hit, s1_meta.local_metadata.all_ports, s1_meta.local_metadata.out_port, s1_meta.local_metadata.starting_port;
{
    s1_meta.local_metadata.starting_port := s1_meta.local_metadata.starting_port;
    s1_meta.local_metadata.all_ports := s1_meta.local_metadata.all_ports;
    s1_check_out_failed.hit := false;
    s1_check_out_failed.action_run := s1_check_out_failed.action.NoAction_8;
    call s1_NoAction_8();
    goto s1_Exit;

    s1_action_skip_failures:
    assume s1_check_out_failed.action_run == s1_check_out_failed.action.skip_failures;
    call s1_skip_failures(s1_check_out_failed.skip_failures._working);
    goto s1_Exit;

    s1_Exit:
}

// s1_Table s1_check_outport_status
procedure {:inline 1} s1_check_outport_status.apply()
	modifies s1_check_outport_status.action_run, s1_check_outport_status.hit, s1_meta.local_metadata.all_ports, s1_meta.local_metadata.out_port_xor;
{
    s1_check_outport_status.hit := false;
    s1_check_outport_status.action_run := s1_check_outport_status.action.NoAction_9;
    call s1_NoAction_9();
    goto s1_Exit;

    s1_action_xor_outport:
    assume s1_check_outport_status.action_run == s1_check_outport_status.action.xor_outport;
    call s1_xor_outport(s1_check_outport_status.xor_outport._all_ports);
    goto s1_Exit;

    s1_Exit:
}

// s1_Control s1_computeChecksum
procedure {:inline 1} s1_computeChecksum()
{
}

// s1_Table s1_curr_par_eq_neq_ingress
procedure {:inline 1} s1_curr_par_eq_neq_ingress.apply()
	modifies s1_curr_par_eq_neq_ingress.action_run, s1_curr_par_eq_neq_ingress.hit, s1_meta.local_metadata.out_port, s1_meta.local_metadata.pkt_curr;
{
    s1_curr_par_eq_neq_ingress.hit := false;
    s1_curr_par_eq_neq_ingress.action_run := s1_curr_par_eq_neq_ingress.action.NoAction_10;
    call s1_NoAction_10();
    goto s1_Exit;

    s1_action_set_next_port:
    assume s1_curr_par_eq_neq_ingress.action_run == s1_curr_par_eq_neq_ingress.action.set_next_port;
    call s1_set_next_port();
    goto s1_Exit;

    s1_Exit:
}

// s1_Table s1_curr_par_eq_zero
procedure {:inline 1} s1_curr_par_eq_zero.apply()
	modifies s1_curr_par_eq_zero.action_run, s1_curr_par_eq_zero.hit, s1_meta.local_metadata.first_visit, s1_meta.local_metadata.out_port, s1_meta.local_metadata.pkt_par, s1_pkt_par, s1_pkt_par__last0_old_value, s1_pkt_par__last0_value, s1_pkt_par__last_index, s1_pkt_par__last_old_value, s1_pkt_par__last_value, s1_pkt_par__last_write_site, s1_pkt_par__next_write_site, s1_pkt_par__wrote_any, s1_pkt_par__wrote_index0;
{
    s1_curr_par_eq_zero.hit := false;
    s1_curr_par_eq_zero.action_run := s1_curr_par_eq_zero.action.NoAction_11;
    call s1_NoAction_11();
    goto s1_Exit;

    s1_action_set_par_to_ingress:
    assume s1_curr_par_eq_zero.action_run == s1_curr_par_eq_zero.action.set_par_to_ingress;
    call s1_set_par_to_ingress();
    goto s1_Exit;

    s1_Exit:
}

// s1_Table s1_curr_par_neq_in
procedure {:inline 1} s1_curr_par_neq_in.apply()
	modifies s1_curr_par_neq_in.action_run, s1_curr_par_neq_in.hit, s1_meta.local_metadata.failure_visit, s1_meta.local_metadata.out_port;
{
    s1_curr_par_neq_in.hit := false;
    s1_curr_par_neq_in.action_run := s1_curr_par_neq_in.action.set_out_to_ingress;
    call s1_set_out_to_ingress();
    goto s1_Exit;

    s1_Exit:
}

// s1_Table s1_default_route
procedure {:inline 1} s1_default_route.apply()
	modifies s1_default_route.action_run, s1_default_route.hit, s1_meta.local_metadata.out_port, s1_standard_metadata.ingress_port;
{
    s1_standard_metadata.ingress_port := s1_standard_metadata.ingress_port;
    s1_default_route.hit := false;
    s1_default_route.action_run := s1_default_route.action.NoAction;
    call s1_NoAction();
    goto s1_Exit;

    s1_action_set_default_route:
    assume s1_default_route.action_run == s1_default_route.action.set_default_route;
    call s1_set_default_route(s1_default_route.set_default_route.send_to);
    goto s1_Exit;

    s1_Exit:
}

// s1_Control s1_egress
procedure {:inline 1} s1_egress()
{
}

// s1_Action s1_fwd
procedure {:inline 1} s1_fwd(s1__port:bv9)
	modifies s1_forward, s1_hdr.ff_tags.path_length, s1_pkt_curr, s1_pkt_curr__last0_old_value, s1_pkt_curr__last0_value, s1_pkt_curr__last_index, s1_pkt_curr__last_old_value, s1_pkt_curr__last_value, s1_pkt_curr__last_write_site, s1_pkt_curr__next_write_site, s1_pkt_curr__wrote_any, s1_pkt_curr__wrote_index0, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    s1_standard_metadata.egress_spec := s1__port;
    s1_standard_metadata.egress_port := s1__port;
    s1_forward := true;
    // s1_write
    s1_pkt_curr__next_write_site := 2;
    call s1_pkt_curr.write(s1_hdr.bfsTag.inst, s1__port[8:0]);
    s1_hdr.ff_tags.path_length := add.bv8(s1_hdr.ff_tags.path_length, 1bv8);
}

// s1_Table s1_fwd_parent
procedure {:inline 1} s1_fwd_parent.apply()
	modifies s1_forward, s1_fwd_parent.action_run, s1_fwd_parent.hit, s1_hdr.ff_tags.path_length, s1_pkt_curr, s1_pkt_curr__last0_old_value, s1_pkt_curr__last0_value, s1_pkt_curr__last_index, s1_pkt_curr__last_old_value, s1_pkt_curr__last_value, s1_pkt_curr__last_write_site, s1_pkt_curr__next_write_site, s1_pkt_curr__wrote_any, s1_pkt_curr__wrote_index0, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    s1_fwd_parent.hit := false;
    s1_fwd_parent.action_run := s1_fwd_parent.action.NoAction_2;
    call s1_NoAction_2();
    goto s1_Exit;

    s1_action_towards_parent:
    assume s1_fwd_parent.action_run == s1_fwd_parent.action.towards_parent;
    call s1_towards_parent();
    goto s1_Exit;

    s1_Exit:
}

// s1_Table s1_fwd_pkt
procedure {:inline 1} s1_fwd_pkt.apply()
	modifies s1_forward, s1_fwd_pkt.action_run, s1_fwd_pkt.hit, s1_hdr.ff_tags.path_length, s1_meta.local_metadata.all_ports, s1_meta.local_metadata.starting_port, s1_pkt_curr, s1_pkt_curr__last0_old_value, s1_pkt_curr__last0_value, s1_pkt_curr__last_index, s1_pkt_curr__last_old_value, s1_pkt_curr__last_value, s1_pkt_curr__last_write_site, s1_pkt_curr__next_write_site, s1_pkt_curr__wrote_any, s1_pkt_curr__wrote_index0, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    s1_meta.local_metadata.starting_port := s1_meta.local_metadata.starting_port;
    s1_meta.local_metadata.all_ports := s1_meta.local_metadata.all_ports;
    s1_fwd_pkt.hit := false;
    s1_fwd_pkt.action_run := s1_fwd_pkt.action.NoAction_3;
    call s1_NoAction_3();
    goto s1_Exit;

    s1_action_fwd:
    assume s1_fwd_pkt.action_run == s1_fwd_pkt.action.fwd;
    call s1_fwd(s1_fwd_pkt.fwd._port);
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_go_to_next
procedure {:inline 1} s1_go_to_next()
	modifies s1_meta.local_metadata.is_completed, s1_meta.local_metadata.out_port, s1_meta.local_metadata.pkt_curr;
{
    s1_meta.local_metadata.out_port := s1_meta.local_metadata.pkt_par;
    s1_meta.local_metadata.pkt_curr := 0bv8;
    s1_meta.local_metadata.is_completed := 1bv1;
}

// s1_Table s1_hit_depth
procedure {:inline 1} s1_hit_depth.apply()
	modifies s1_hit_depth.action_run, s1_hit_depth.hit, s1_meta.local_metadata.is_completed, s1_meta.local_metadata.out_port, s1_meta.local_metadata.pkt_curr;
{
    s1_hit_depth.hit := false;
    s1_hit_depth.action_run := s1_hit_depth.action.go_to_next;
    call s1_go_to_next();
    goto s1_Exit;

    s1_action_go_to_next:
    assume s1_hit_depth.action_run == s1_hit_depth.action.go_to_next;
    call s1_go_to_next();
    goto s1_Exit;

    s1_Exit:
}

// s1_Table s1_if_status
procedure {:inline 1} s1_if_status.apply()
	modifies s1_if_status.action_run, s1_if_status.hit, s1_meta.local_metadata.if_out_failed, s1_meta.local_metadata.out_port_xor, s1_meta.local_metadata.starting_port;
{
    s1_meta.local_metadata.starting_port := s1_meta.local_metadata.starting_port;
    s1_meta.local_metadata.out_port_xor := s1_meta.local_metadata.out_port_xor;
    s1_if_status.hit := false;
    s1_if_status.action_run := s1_if_status.action.NoAction_13;
    call s1_NoAction_13();
    goto s1_Exit;

    s1_action_set_if_status:
    assume s1_if_status.action_run == s1_if_status.action.set_if_status;
    call s1_set_if_status(s1_if_status.set_if_status._value);
    goto s1_Exit;

    s1_Exit:
}

// s1_Control s1_ingress
procedure {:inline 1} s1_ingress()
	modifies s1_check_out_failed.action_run, s1_check_out_failed.hit, s1_check_outport_status.action_run, s1_check_outport_status.hit, s1_curr_par_eq_neq_ingress.action_run, s1_curr_par_eq_neq_ingress.hit, s1_curr_par_eq_zero.action_run, s1_curr_par_eq_zero.hit, s1_curr_par_neq_in.action_run, s1_curr_par_neq_in.hit, s1_default_route.action_run, s1_default_route.hit, s1_forward, s1_fwd_parent.action_run, s1_fwd_parent.hit, s1_fwd_pkt.action_run, s1_fwd_pkt.hit, s1_hdr.ff_tags.bfs_start, s1_hdr.ff_tags.path_length, s1_hit_depth.action_run, s1_hit_depth.hit, s1_if_status.action_run, s1_if_status.hit, s1_jump_to_next.action_run, s1_jump_to_next.hit, s1_meta.local_metadata.all_ports, s1_meta.local_metadata.failure_visit, s1_meta.local_metadata.first_visit, s1_meta.local_metadata.if_out_failed, s1_meta.local_metadata.is_completed, s1_meta.local_metadata.out_port, s1_meta.local_metadata.out_port_xor, s1_meta.local_metadata.pkt_curr, s1_meta.local_metadata.pkt_par, s1_meta.local_metadata.pkt_start, s1_meta.local_metadata.starting_port, s1_out_eq_zero.action_run, s1_out_eq_zero.hit, s1_pkt_curr, s1_pkt_curr__last0_old_value, s1_pkt_curr__last0_value, s1_pkt_curr__last_index, s1_pkt_curr__last_old_value, s1_pkt_curr__last_value, s1_pkt_curr__last_write_site, s1_pkt_curr__next_write_site, s1_pkt_curr__wrote_any, s1_pkt_curr__wrote_index0, s1_pkt_par, s1_pkt_par__last0_old_value, s1_pkt_par__last0_value, s1_pkt_par__last_index, s1_pkt_par__last_old_value, s1_pkt_par__last_value, s1_pkt_par__last_write_site, s1_pkt_par__next_write_site, s1_pkt_par__wrote_any, s1_pkt_par__wrote_index0, s1_send_in_ingress.action_run, s1_send_in_ingress.hit, s1_send_parent.action_run, s1_send_parent.hit, s1_set_egress_port.action_run, s1_set_egress_port.hit, s1_set_out_port.action_run, s1_set_out_port.hit, s1_set_parent_out.action_run, s1_set_parent_out.hit, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_standard_metadata.ingress_port, s1_start_bfs.action_run, s1_start_bfs.hit, s1_to_parent.action_run, s1_to_parent.hit, s1_try_next.action_run, s1_try_next.hit;
{
    if(s1_isValid[s1_hdr.bfsTag]){
        if((s1_meta.local_metadata.pkt_start == 0bv1)){
            call s1_default_route.apply();
            if((s1_meta.local_metadata.out_port == 0bv8)){
                call s1_start_bfs.apply();
            }
        }
        else{
            if(((s1_meta.local_metadata.pkt_curr == 0bv8)) && ((s1_meta.local_metadata.pkt_par == 0bv8))){
                call s1_curr_par_eq_zero.apply();
            }
            else{
                if(((0bv1++s1_meta.local_metadata.pkt_curr != s1_standard_metadata.ingress_port)) && ((0bv1++s1_meta.local_metadata.pkt_par != s1_standard_metadata.ingress_port))){
                    call s1_curr_par_neq_in.apply();
                }
                else{
                    call s1_curr_par_eq_neq_ingress.apply();
                    if((s1_meta.local_metadata.out_port == 5bv8)){
                        call s1_hit_depth.apply();
                    }
                    if((s1_meta.local_metadata.is_completed == 0bv1)){
                        call s1_set_egress_port.apply();
                        if((s1_meta.local_metadata.out_port != 4bv8)){
                            call s1_check_out_failed.apply();
                        }
                        else{
                            call s1_check_outport_status.apply();
                            call s1_if_status.apply();
                            if((s1_meta.local_metadata.if_out_failed == s1_meta.local_metadata.out_port)){
                                call s1_try_next.apply();
                                if((s1_meta.local_metadata.out_port == 5bv8)){
                                    call s1_to_parent.apply();
                                }
                            }
                        }
                        if(((s1_meta.local_metadata.is_completed == 0bv1)) && ((s1_meta.local_metadata.out_port == s1_meta.local_metadata.pkt_par))){
                            call s1_jump_to_next.apply();
                            if((s1_meta.local_metadata.out_port == 5bv8)){
                                call s1_set_parent_out.apply();
                            }
                        }
                    }
                    if((s1_meta.local_metadata.is_completed == 1bv1)){
                        if((s1_meta.local_metadata.out_port == 0bv8)){
                            call s1_out_eq_zero.apply();
                        }
                    }
                    assert (bult.bv8(s1_meta.local_metadata.out_port, 5bv8)) || ((s1_meta.local_metadata.out_port == s1_meta.local_metadata.pkt_par));
                }
            }
        }
        if((s1_meta.local_metadata.first_visit == 1bv1)){
            call s1_send_parent.apply();
        }
        if((s1_meta.local_metadata.failure_visit == 1bv1)){
            call s1_send_in_ingress.apply();
        }
        if(((s1_meta.local_metadata.first_visit == 0bv1)) && ((s1_meta.local_metadata.failure_visit == 0bv1))){
            if((s1_meta.local_metadata.is_completed == 0bv1)){
                call s1_set_out_port.apply();
                call s1_fwd_pkt.apply();
            }
            else{
                call s1_fwd_parent.apply();
            }
        }
    }
}

// s1_Table s1_jump_to_next
procedure {:inline 1} s1_jump_to_next.apply()
	modifies s1_jump_to_next.action_run, s1_jump_to_next.hit, s1_meta.local_metadata.out_port;
{
    s1_jump_to_next.hit := false;
    s1_jump_to_next.action_run := s1_jump_to_next.action.NoAction_14;
    call s1_NoAction_14();
    goto s1_Exit;

    s1_action_skip_parent:
    assume s1_jump_to_next.action_run == s1_jump_to_next.action.skip_parent;
    call s1_skip_parent();
    goto s1_Exit;

    s1_Exit:
}
procedure {:inline 1} s1_main()
	modifies s1_check_out_failed.action_run, s1_check_out_failed.hit, s1_check_outport_status.action_run, s1_check_outport_status.hit, s1_curr_par_eq_neq_ingress.action_run, s1_curr_par_eq_neq_ingress.hit, s1_curr_par_eq_zero.action_run, s1_curr_par_eq_zero.hit, s1_curr_par_neq_in.action_run, s1_curr_par_neq_in.hit, s1_default_route.action_run, s1_default_route.hit, s1_drop, s1_forward, s1_fwd_parent.action_run, s1_fwd_parent.hit, s1_fwd_pkt.action_run, s1_fwd_pkt.hit, s1_hdr.ff_tags.bfs_start, s1_hdr.ff_tags.path_length, s1_hit_depth.action_run, s1_hit_depth.hit, s1_if_status.action_run, s1_if_status.hit, s1_isValid, s1_jump_to_next.action_run, s1_jump_to_next.hit, s1_meta.local_metadata.all_ports, s1_meta.local_metadata.failure_visit, s1_meta.local_metadata.first_visit, s1_meta.local_metadata.if_out_failed, s1_meta.local_metadata.is_completed, s1_meta.local_metadata.out_port, s1_meta.local_metadata.out_port_xor, s1_meta.local_metadata.pkt_curr, s1_meta.local_metadata.pkt_par, s1_meta.local_metadata.pkt_start, s1_meta.local_metadata.starting_port, s1_out_eq_zero.action_run, s1_out_eq_zero.hit, s1_pkt_curr, s1_pkt_curr__last0_old_value, s1_pkt_curr__last0_value, s1_pkt_curr__last_index, s1_pkt_curr__last_old_value, s1_pkt_curr__last_value, s1_pkt_curr__last_write_site, s1_pkt_curr__next_write_site, s1_pkt_curr__wrote_any, s1_pkt_curr__wrote_index0, s1_pkt_par, s1_pkt_par__last0_old_value, s1_pkt_par__last0_value, s1_pkt_par__last_index, s1_pkt_par__last_old_value, s1_pkt_par__last_value, s1_pkt_par__last_write_site, s1_pkt_par__next_write_site, s1_pkt_par__wrote_any, s1_pkt_par__wrote_index0, s1_send_in_ingress.action_run, s1_send_in_ingress.hit, s1_send_parent.action_run, s1_send_parent.hit, s1_set_egress_port.action_run, s1_set_egress_port.hit, s1_set_out_port.action_run, s1_set_out_port.hit, s1_set_parent_out.action_run, s1_set_parent_out.hit, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_standard_metadata.ingress_port, s1_start_bfs.action_run, s1_start_bfs.hit, s1_to_parent.action_run, s1_to_parent.hit, s1_try_next.action_run, s1_try_next.hit;
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
	modifies s1_check_out_failed.action_run, s1_check_out_failed.hit, s1_check_outport_status.action_run, s1_check_outport_status.hit, s1_curr_par_eq_neq_ingress.action_run, s1_curr_par_eq_neq_ingress.hit, s1_curr_par_eq_zero.action_run, s1_curr_par_eq_zero.hit, s1_curr_par_neq_in.action_run, s1_curr_par_neq_in.hit, s1_default_route.action_run, s1_default_route.hit, s1_drop, s1_forward, s1_fwd_parent.action_run, s1_fwd_parent.hit, s1_fwd_pkt.action_run, s1_fwd_pkt.hit, s1_hdr.ff_tags.bfs_start, s1_hdr.ff_tags.path_length, s1_hit_depth.action_run, s1_hit_depth.hit, s1_if_status.action_run, s1_if_status.hit, s1_isValid, s1_jump_to_next.action_run, s1_jump_to_next.hit, s1_meta.local_metadata.all_ports, s1_meta.local_metadata.failure_visit, s1_meta.local_metadata.first_visit, s1_meta.local_metadata.if_out_failed, s1_meta.local_metadata.is_completed, s1_meta.local_metadata.out_port, s1_meta.local_metadata.out_port_xor, s1_meta.local_metadata.pkt_curr, s1_meta.local_metadata.pkt_par, s1_meta.local_metadata.pkt_start, s1_meta.local_metadata.starting_port, s1_out_eq_zero.action_run, s1_out_eq_zero.hit, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_curr, s1_pkt_curr__last0_old_value, s1_pkt_curr__last0_value, s1_pkt_curr__last_index, s1_pkt_curr__last_old_value, s1_pkt_curr__last_value, s1_pkt_curr__last_write_site, s1_pkt_curr__next_write_site, s1_pkt_curr__wrote_any, s1_pkt_curr__wrote_index0, s1_pkt_par, s1_pkt_par__last0_old_value, s1_pkt_par__last0_value, s1_pkt_par__last_index, s1_pkt_par__last_old_value, s1_pkt_par__last_value, s1_pkt_par__last_write_site, s1_pkt_par__next_write_site, s1_pkt_par__wrote_any, s1_pkt_par__wrote_index0, s1_send_in_ingress.action_run, s1_send_in_ingress.hit, s1_send_parent.action_run, s1_send_parent.hit, s1_set_egress_port.action_run, s1_set_egress_port.hit, s1_set_out_port.action_run, s1_set_out_port.hit, s1_set_parent_out.action_run, s1_set_parent_out.hit, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_standard_metadata.ingress_port, s1_start_bfs.action_run, s1_start_bfs.hit, s1_to_parent.action_run, s1_to_parent.hit, s1_try_next.action_run, s1_try_next.hit;
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
procedure s1_mark_to_drop();
    ensures s1_drop==true;
	modifies s1_drop;

// s1_Action s1_next_outport
procedure {:inline 1} s1_next_outport()
	modifies s1_meta.local_metadata.out_port;
{
    s1_meta.local_metadata.out_port := add.bv8(s1_meta.local_metadata.out_port, 1bv8);
}

// s1_Table s1_out_eq_zero
procedure {:inline 1} s1_out_eq_zero.apply()
	modifies s1_meta.local_metadata.is_completed, s1_meta.local_metadata.out_port, s1_out_eq_zero.action_run, s1_out_eq_zero.hit;
{
    s1_out_eq_zero.hit := false;
    s1_out_eq_zero.action_run := s1_out_eq_zero.action.NoAction_15;
    call s1_NoAction_15();
    goto s1_Exit;

    s1_action_start_from_one:
    assume s1_out_eq_zero.action_run == s1_out_eq_zero.action.start_from_one;
    call s1_start_from_one();
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_outport_to_parent
procedure {:inline 1} s1_outport_to_parent()
	modifies s1_meta.local_metadata.is_completed, s1_meta.local_metadata.out_port, s1_meta.local_metadata.pkt_curr;
{
    s1_meta.local_metadata.out_port := s1_meta.local_metadata.pkt_par;
    s1_meta.local_metadata.pkt_curr := 0bv8;
    s1_meta.local_metadata.is_completed := 1bv1;
}
procedure s1_packet.emit(s1_arg0:s1_Ref);
procedure s1_packet_in.extract(s1_header:s1_Ref);
    ensures (s1_isValid[s1_header] == true);
	modifies s1_isValid;
function {:inline true}s1_pkt_curr.read(s1_reg:[bv32]bv8, s1_index:bv32)returns (bv8) {s1_reg[s1_index]}
procedure {:inline 1} s1_pkt_curr.write(s1_index:bv32, s1_value:bv8)
	modifies s1_pkt_curr, s1_pkt_curr__last0_old_value, s1_pkt_curr__last0_value, s1_pkt_curr__last_index, s1_pkt_curr__last_old_value, s1_pkt_curr__last_value, s1_pkt_curr__last_write_site, s1_pkt_curr__wrote_any, s1_pkt_curr__wrote_index0;
{
    s1_pkt_curr__last_old_value := s1_pkt_curr[s1_index];
    s1_pkt_curr[s1_index] := s1_value;
    s1_pkt_curr__last_index := s1_index;
    s1_pkt_curr__last_value := s1_value;
    s1_pkt_curr__last_write_site := s1_pkt_curr__next_write_site;
    s1_pkt_curr__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_pkt_curr__wrote_index0 := true;
        s1_pkt_curr__last0_old_value := s1_pkt_curr__last_old_value;
        s1_pkt_curr__last0_value := s1_value;
    }
}
function {:inline true}s1_pkt_par.read(s1_reg:[bv32]bv8, s1_index:bv32)returns (bv8) {s1_reg[s1_index]}
procedure {:inline 1} s1_pkt_par.write(s1_index:bv32, s1_value:bv8)
	modifies s1_pkt_par, s1_pkt_par__last0_old_value, s1_pkt_par__last0_value, s1_pkt_par__last_index, s1_pkt_par__last_old_value, s1_pkt_par__last_value, s1_pkt_par__last_write_site, s1_pkt_par__wrote_any, s1_pkt_par__wrote_index0;
{
    s1_pkt_par__last_old_value := s1_pkt_par[s1_index];
    s1_pkt_par[s1_index] := s1_value;
    s1_pkt_par__last_index := s1_index;
    s1_pkt_par__last_value := s1_value;
    s1_pkt_par__last_write_site := s1_pkt_par__next_write_site;
    s1_pkt_par__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_pkt_par__wrote_index0 := true;
        s1_pkt_par__last0_old_value := s1_pkt_par__last_old_value;
        s1_pkt_par__last0_value := s1_value;
    }
}
procedure s1_reject();
    ensures s1_drop==true;
	modifies s1_drop;

// s1_Action s1_send_in
procedure {:inline 1} s1_send_in()
	modifies s1_forward, s1_hdr.ff_tags.path_length, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    s1_standard_metadata.egress_spec := s1_standard_metadata.ingress_port;
    s1_standard_metadata.egress_port := s1_standard_metadata.ingress_port;
    s1_forward := true;
    s1_hdr.ff_tags.path_length := add.bv8(s1_hdr.ff_tags.path_length, 1bv8);
}

// s1_Table s1_send_in_ingress
procedure {:inline 1} s1_send_in_ingress.apply()
	modifies s1_forward, s1_hdr.ff_tags.path_length, s1_send_in_ingress.action_run, s1_send_in_ingress.hit, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    s1_send_in_ingress.hit := false;
    s1_send_in_ingress.action_run := s1_send_in_ingress.action.send_in;
    call s1_send_in();
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_send_on_parent
procedure {:inline 1} s1_send_on_parent()
	modifies s1_forward, s1_hdr.ff_tags.path_length, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    s1_standard_metadata.egress_spec := 0bv1++s1_meta.local_metadata.out_port;
    s1_standard_metadata.egress_port := 0bv1++s1_meta.local_metadata.out_port;
    s1_forward := true;
    s1_hdr.ff_tags.path_length := add.bv8(s1_hdr.ff_tags.path_length, 1bv8);
}

// s1_Table s1_send_parent
procedure {:inline 1} s1_send_parent.apply()
	modifies s1_forward, s1_hdr.ff_tags.path_length, s1_send_parent.action_run, s1_send_parent.hit, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    s1_send_parent.hit := false;
    s1_send_parent.action_run := s1_send_parent.action.NoAction_5;
    call s1_NoAction_5();
    goto s1_Exit;

    s1_action_send_on_parent:
    assume s1_send_parent.action_run == s1_send_parent.action.send_on_parent;
    call s1_send_on_parent();
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_send_to_parent
procedure {:inline 1} s1_send_to_parent()
	modifies s1_meta.local_metadata.is_completed, s1_meta.local_metadata.out_port, s1_meta.local_metadata.pkt_curr;
{
    s1_meta.local_metadata.out_port := s1_meta.local_metadata.pkt_par;
    s1_meta.local_metadata.pkt_curr := 0bv8;
    s1_meta.local_metadata.is_completed := 1bv1;
}
procedure {:inline 1} s1_setInvalid(s1_header:s1_Ref);
    ensures (s1_isValid[s1_header] == false);
	modifies s1_isValid;
procedure {:inline 1} s1_setValid(s1_header:s1_Ref);

// s1_Action s1_set_bfs_tags
procedure {:inline 1} s1_set_bfs_tags()
	modifies s1_hdr.ff_tags.bfs_start, s1_meta.local_metadata.out_port, s1_meta.local_metadata.pkt_par, s1_meta.local_metadata.pkt_start, s1_pkt_par, s1_pkt_par__last0_old_value, s1_pkt_par__last0_value, s1_pkt_par__last_index, s1_pkt_par__last_old_value, s1_pkt_par__last_value, s1_pkt_par__last_write_site, s1_pkt_par__next_write_site, s1_pkt_par__wrote_any, s1_pkt_par__wrote_index0;
{
    s1_meta.local_metadata.pkt_start := 1bv1;
    s1_hdr.ff_tags.bfs_start := s1_meta.local_metadata.pkt_start;
    s1_meta.local_metadata.pkt_par := 0bv8;
    // s1_write
    s1_pkt_par__next_write_site := 1;
    call s1_pkt_par.write(s1_hdr.bfsTag.inst, s1_meta.local_metadata.pkt_par);
    s1_meta.local_metadata.out_port := 1bv8;
}

// s1_Action s1_set_default_route
procedure {:inline 1} s1_set_default_route(s1_send_to:bv8)
	modifies s1_meta.local_metadata.out_port;
{
    s1_meta.local_metadata.out_port := s1_send_to;
}

// s1_Table s1_set_egress_port
procedure {:inline 1} s1_set_egress_port.apply()
	modifies s1_meta.local_metadata.all_ports, s1_meta.local_metadata.out_port, s1_meta.local_metadata.starting_port, s1_set_egress_port.action_run, s1_set_egress_port.hit;
{
    s1_meta.local_metadata.out_port := s1_meta.local_metadata.out_port;
    s1_set_egress_port.hit := false;
    s1_set_egress_port.action_run := s1_set_egress_port.action.NoAction_16;
    call s1_NoAction_16();
    goto s1_Exit;

    s1_action_starting_port_meta:
    assume s1_set_egress_port.action_run == s1_set_egress_port.action.starting_port_meta;
    call s1_starting_port_meta(s1_set_egress_port.starting_port_meta.port_start);
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_set_if_status
procedure {:inline 1} s1_set_if_status(s1__value:bv8)
	modifies s1_meta.local_metadata.if_out_failed;
{
    s1_meta.local_metadata.if_out_failed := s1__value;
}

// s1_Action s1_set_next_port
procedure {:inline 1} s1_set_next_port()
	modifies s1_meta.local_metadata.out_port, s1_meta.local_metadata.pkt_curr;
{
    s1_meta.local_metadata.pkt_curr := add.bv8(s1_meta.local_metadata.pkt_curr, 1bv8);
    s1_meta.local_metadata.out_port := s1_meta.local_metadata.pkt_curr;
}

// s1_Action s1_set_out_meta
procedure {:inline 1} s1_set_out_meta(s1_meta_state:bv32)
	modifies s1_meta.local_metadata.all_ports, s1_meta.local_metadata.starting_port;
{
    s1_meta.local_metadata.starting_port := s1_meta_state;
    // s1_read
    s1_meta.local_metadata.all_ports := s1_all_ports_status.read(s1_all_ports_status, 0bv32);
}

// s1_Table s1_set_out_port
procedure {:inline 1} s1_set_out_port.apply()
	modifies s1_meta.local_metadata.all_ports, s1_meta.local_metadata.out_port, s1_meta.local_metadata.starting_port, s1_set_out_port.action_run, s1_set_out_port.hit;
{
    s1_meta.local_metadata.out_port := s1_meta.local_metadata.out_port;
    s1_set_out_port.hit := false;
    s1_set_out_port.action_run := s1_set_out_port.action.NoAction_6;
    call s1_NoAction_6();
    goto s1_Exit;

    s1_action_set_out_meta:
    assume s1_set_out_port.action_run == s1_set_out_port.action.set_out_meta;
    call s1_set_out_meta(s1_set_out_port.set_out_meta.meta_state);
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_set_out_to_ingress
procedure {:inline 1} s1_set_out_to_ingress()
	modifies s1_meta.local_metadata.failure_visit, s1_meta.local_metadata.out_port;
{
    s1_meta.local_metadata.out_port := s1_meta.local_metadata.out_port;
    s1_meta.local_metadata.failure_visit := 1bv1;
}

// s1_Action s1_set_par_to_ingress
procedure {:inline 1} s1_set_par_to_ingress()
	modifies s1_meta.local_metadata.first_visit, s1_meta.local_metadata.out_port, s1_meta.local_metadata.pkt_par, s1_pkt_par, s1_pkt_par__last0_old_value, s1_pkt_par__last0_value, s1_pkt_par__last_index, s1_pkt_par__last_old_value, s1_pkt_par__last_value, s1_pkt_par__last_write_site, s1_pkt_par__next_write_site, s1_pkt_par__wrote_any, s1_pkt_par__wrote_index0;
{
    s1_meta.local_metadata.pkt_par := s1_standard_metadata.ingress_port[8:0];
    // s1_write
    s1_pkt_par__next_write_site := 2;
    call s1_pkt_par.write(s1_hdr.bfsTag.inst, s1_meta.local_metadata.pkt_par);
    s1_meta.local_metadata.out_port := s1_standard_metadata.ingress_port[8:0];
    s1_meta.local_metadata.first_visit := 1bv1;
}

// s1_Table s1_set_parent_out
procedure {:inline 1} s1_set_parent_out.apply()
	modifies s1_meta.local_metadata.is_completed, s1_meta.local_metadata.out_port, s1_meta.local_metadata.pkt_curr, s1_set_parent_out.action_run, s1_set_parent_out.hit;
{
    s1_set_parent_out.hit := false;
    s1_set_parent_out.action_run := s1_set_parent_out.action.send_to_parent;
    call s1_send_to_parent();
    goto s1_Exit;

    s1_action_send_to_parent:
    assume s1_set_parent_out.action_run == s1_set_parent_out.action.send_to_parent;
    call s1_send_to_parent();
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_skip_failures
procedure {:inline 1} s1_skip_failures(s1__working:bv8)
	modifies s1_meta.local_metadata.out_port;
{
    assume bult.bv8(s1__working, 5bv8);
    s1_meta.local_metadata.out_port := s1__working;
}

// s1_Action s1_skip_parent
procedure {:inline 1} s1_skip_parent()
	modifies s1_meta.local_metadata.out_port;
{
    s1_meta.local_metadata.out_port := add.bv8(s1_meta.local_metadata.out_port, 1bv8);
}

// s1_Table s1_start_bfs
procedure {:inline 1} s1_start_bfs.apply()
	modifies s1_hdr.ff_tags.bfs_start, s1_meta.local_metadata.out_port, s1_meta.local_metadata.pkt_par, s1_meta.local_metadata.pkt_start, s1_pkt_par, s1_pkt_par__last0_old_value, s1_pkt_par__last0_value, s1_pkt_par__last_index, s1_pkt_par__last_old_value, s1_pkt_par__last_value, s1_pkt_par__last_write_site, s1_pkt_par__next_write_site, s1_pkt_par__wrote_any, s1_pkt_par__wrote_index0, s1_start_bfs.action_run, s1_start_bfs.hit;
{
    s1_start_bfs.hit := false;
    s1_start_bfs.action_run := s1_start_bfs.action.NoAction_7;
    call s1_NoAction_7();
    goto s1_Exit;

    s1_action_set_bfs_tags:
    assume s1_start_bfs.action_run == s1_start_bfs.action.set_bfs_tags;
    call s1_set_bfs_tags();
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_start_from_one
procedure {:inline 1} s1_start_from_one()
	modifies s1_meta.local_metadata.is_completed, s1_meta.local_metadata.out_port;
{
    s1_meta.local_metadata.out_port := 1bv8;
    s1_meta.local_metadata.is_completed := 0bv1;
}

// s1_Action s1_starting_port_meta
procedure {:inline 1} s1_starting_port_meta(s1_port_start:bv32)
	modifies s1_meta.local_metadata.all_ports, s1_meta.local_metadata.starting_port;
{
    s1_meta.local_metadata.starting_port := s1_port_start;
    // s1_read
    s1_meta.local_metadata.all_ports := s1_all_ports_status.read(s1_all_ports_status, 0bv32);
}

// s1_Table s1_to_parent
procedure {:inline 1} s1_to_parent.apply()
	modifies s1_meta.local_metadata.is_completed, s1_meta.local_metadata.out_port, s1_meta.local_metadata.pkt_curr, s1_to_parent.action_run, s1_to_parent.hit;
{
    s1_to_parent.hit := false;
    s1_to_parent.action_run := s1_to_parent.action.outport_to_parent;
    call s1_outport_to_parent();
    goto s1_Exit;

    s1_action_outport_to_parent:
    assume s1_to_parent.action_run == s1_to_parent.action.outport_to_parent;
    call s1_outport_to_parent();
    goto s1_Exit;

    s1_Exit:
}

// s1_Action s1_towards_parent
procedure {:inline 1} s1_towards_parent()
	modifies s1_forward, s1_hdr.ff_tags.path_length, s1_pkt_curr, s1_pkt_curr__last0_old_value, s1_pkt_curr__last0_value, s1_pkt_curr__last_index, s1_pkt_curr__last_old_value, s1_pkt_curr__last_value, s1_pkt_curr__last_write_site, s1_pkt_curr__next_write_site, s1_pkt_curr__wrote_any, s1_pkt_curr__wrote_index0, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    // s1_write
    s1_pkt_curr__next_write_site := 1;
    call s1_pkt_curr.write(s1_hdr.bfsTag.inst, s1_meta.local_metadata.pkt_curr);
    s1_standard_metadata.egress_spec := 0bv1++s1_meta.local_metadata.out_port;
    s1_standard_metadata.egress_port := 0bv1++s1_meta.local_metadata.out_port;
    s1_forward := true;
    s1_hdr.ff_tags.path_length := add.bv8(s1_hdr.ff_tags.path_length, 1bv8);
}

// s1_Table s1_try_next
procedure {:inline 1} s1_try_next.apply()
	modifies s1_meta.local_metadata.out_port, s1_try_next.action_run, s1_try_next.hit;
{
    s1_try_next.hit := false;
    s1_try_next.action_run := s1_try_next.action.NoAction_17;
    call s1_NoAction_17();
    goto s1_Exit;

    s1_action_next_outport:
    assume s1_try_next.action_run == s1_try_next.action.next_outport;
    call s1_next_outport();
    goto s1_Exit;

    s1_Exit:
}

// s1_Control s1_verifyChecksum
procedure {:inline 1} s1_verifyChecksum()
{
}

// s1_Action s1_xor_outport
procedure {:inline 1} s1_xor_outport(s1__all_ports:bv32)
	modifies s1_meta.local_metadata.all_ports, s1_meta.local_metadata.out_port_xor;
{
    // s1_read
    s1_meta.local_metadata.all_ports := s1_all_ports_status.read(s1_all_ports_status, 0bv32);
    s1_meta.local_metadata.out_port_xor := bxor.bv32(s1_meta.local_metadata.all_ports, s1__all_ports);
}
// ===== END NODE s1 =====

// ===== BEGIN ENQUEUE PROCEDURES =====
// ===== END ENQUEUE PROCEDURES =====

// ===== BEGIN HARNESS =====
// Auto-generated by Procurator (DSL -> Boogie harness: sequential scheduler)
// Message abstraction: Bag(K=1) using inbox_count per node; single-slot mailbox for packet fields

var procurator_step: int;
var procurator_bad: bool;

// Register debug snapshots (for trace inspection)
var s1_all_ports_status__dbg0: bv32;
var s1_all_ports_status__last_index__dbg: bv32;
var s1_all_ports_status__last_value__dbg: bv32;
var s1_all_ports_status__last_old_value__dbg: bv32;
var s1_all_ports_status__wrote_any__dbg: bool;
var s1_all_ports_status__wrote_index0__dbg: bool;
var s1_all_ports_status__last0_old_value__dbg: bv32;
var s1_all_ports_status__last0_value__dbg: bv32;
var s1_pkt_curr__dbg0: bv8;
var s1_pkt_curr__last_index__dbg: bv32;
var s1_pkt_curr__last_value__dbg: bv8;
var s1_pkt_curr__last_old_value__dbg: bv8;
var s1_pkt_curr__wrote_any__dbg: bool;
var s1_pkt_curr__wrote_index0__dbg: bool;
var s1_pkt_curr__last0_old_value__dbg: bv8;
var s1_pkt_curr__last0_value__dbg: bv8;
var s1_pkt_par__dbg0: bv8;
var s1_pkt_par__last_index__dbg: bv32;
var s1_pkt_par__last_value__dbg: bv8;
var s1_pkt_par__last_old_value__dbg: bv8;
var s1_pkt_par__wrote_any__dbg: bool;
var s1_pkt_par__wrote_index0__dbg: bool;
var s1_pkt_par__last0_old_value__dbg: bv8;
var s1_pkt_par__last0_value__dbg: bv8;

var s1_inbox_count: int;

var s1_pkt_external: bool;

// Forwarding (derived from DSL topology)
procedure s1_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (s1_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure mainProcedure() returns()
  modifies procurator_bad, procurator_step, s1_all_ports_status__dbg0, s1_all_ports_status__last0_old_value, s1_all_ports_status__last0_old_value__dbg, s1_all_ports_status__last0_value, s1_all_ports_status__last0_value__dbg, s1_all_ports_status__last_index, s1_all_ports_status__last_index__dbg, s1_all_ports_status__last_old_value, s1_all_ports_status__last_old_value__dbg, s1_all_ports_status__last_value, s1_all_ports_status__last_value__dbg, s1_all_ports_status__last_write_site, s1_all_ports_status__next_write_site, s1_all_ports_status__wrote_any, s1_all_ports_status__wrote_any__dbg, s1_all_ports_status__wrote_index0, s1_all_ports_status__wrote_index0__dbg, s1_check_out_failed.action_run, s1_check_out_failed.hit, s1_check_outport_status.action_run, s1_check_outport_status.hit, s1_curr_par_eq_neq_ingress.action_run, s1_curr_par_eq_neq_ingress.hit, s1_curr_par_eq_zero.action_run, s1_curr_par_eq_zero.hit, s1_curr_par_neq_in.action_run, s1_curr_par_neq_in.hit, s1_default_route.action_run, s1_default_route.hit, s1_drop, s1_forward, s1_fwd_parent.action_run, s1_fwd_parent.hit, s1_fwd_pkt.action_run, s1_fwd_pkt.hit, s1_hdr.bfsTag.inst, s1_hdr.bfsTag.pkt_v1_curr, s1_hdr.bfsTag.pkt_v1_par, s1_hdr.bfsTag.pkt_v2_curr, s1_hdr.bfsTag.pkt_v2_par, s1_hdr.bfsTag.pkt_v3_curr, s1_hdr.bfsTag.pkt_v3_par, s1_hdr.bfsTag.pkt_v4_curr, s1_hdr.bfsTag.pkt_v4_par, s1_hdr.bfsTag.valid, s1_hdr.ff_tags.bfs_start, s1_hdr.ff_tags.is_edge, s1_hdr.ff_tags.path_length, s1_hdr.ff_tags.preamble, s1_hdr.ff_tags.shortest_path, s1_hdr.ff_tags.valid, s1_hit_depth.action_run, s1_hit_depth.hit, s1_if_status.action_run, s1_if_status.hit, s1_inbox_count, s1_isValid, s1_jump_to_next.action_run, s1_jump_to_next.hit, s1_meta.local_metadata, s1_meta.local_metadata.all_ports, s1_meta.local_metadata.failure_visit, s1_meta.local_metadata.first_visit, s1_meta.local_metadata.if_out_failed, s1_meta.local_metadata.is_completed, s1_meta.local_metadata.out_port, s1_meta.local_metadata.out_port_xor, s1_meta.local_metadata.pkt_curr, s1_meta.local_metadata.pkt_par, s1_meta.local_metadata.pkt_start, s1_meta.local_metadata.starting_port, s1_out_eq_zero.action_run, s1_out_eq_zero.hit, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_curr, s1_pkt_curr__dbg0, s1_pkt_curr__last0_old_value, s1_pkt_curr__last0_old_value__dbg, s1_pkt_curr__last0_value, s1_pkt_curr__last0_value__dbg, s1_pkt_curr__last_index, s1_pkt_curr__last_index__dbg, s1_pkt_curr__last_old_value, s1_pkt_curr__last_old_value__dbg, s1_pkt_curr__last_value, s1_pkt_curr__last_value__dbg, s1_pkt_curr__last_write_site, s1_pkt_curr__next_write_site, s1_pkt_curr__wrote_any, s1_pkt_curr__wrote_any__dbg, s1_pkt_curr__wrote_index0, s1_pkt_curr__wrote_index0__dbg, s1_pkt_external, s1_pkt_par, s1_pkt_par__dbg0, s1_pkt_par__last0_old_value, s1_pkt_par__last0_old_value__dbg, s1_pkt_par__last0_value, s1_pkt_par__last0_value__dbg, s1_pkt_par__last_index, s1_pkt_par__last_index__dbg, s1_pkt_par__last_old_value, s1_pkt_par__last_old_value__dbg, s1_pkt_par__last_value, s1_pkt_par__last_value__dbg, s1_pkt_par__last_write_site, s1_pkt_par__next_write_site, s1_pkt_par__wrote_any, s1_pkt_par__wrote_any__dbg, s1_pkt_par__wrote_index0, s1_pkt_par__wrote_index0__dbg, s1_send_in_ingress.action_run, s1_send_in_ingress.hit, s1_send_parent.action_run, s1_send_parent.hit, s1_set_egress_port.action_run, s1_set_egress_port.hit, s1_set_out_port.action_run, s1_set_out_port.hit, s1_set_parent_out.action_run, s1_set_parent_out.hit, s1_standard_metadata.checksum_error, s1_standard_metadata.deq_qdepth, s1_standard_metadata.deq_timedelta, s1_standard_metadata.egress_global_timestamp, s1_standard_metadata.egress_port, s1_standard_metadata.egress_rid, s1_standard_metadata.egress_spec, s1_standard_metadata.enq_qdepth, s1_standard_metadata.enq_timestamp, s1_standard_metadata.ingress_global_timestamp, s1_standard_metadata.ingress_port, s1_standard_metadata.instance_type, s1_standard_metadata.mcast_grp, s1_standard_metadata.packet_length, s1_standard_metadata.parser_error, s1_standard_metadata.priority, s1_start_bfs.action_run, s1_start_bfs.hit, s1_to_parent.action_run, s1_to_parent.hit, s1_try_next.action_run, s1_try_next.hit;
{
  // initialize inboxes
  s1_inbox_count := 0;
  s1_pkt_external := false;
  // initialize P4B event flags (clone/recirculate)
  s1_p4b_clone_i2e := false;
  s1_p4b_clone_e2e := false;
  s1_p4b_clone_i2i := false;
  s1_p4b_recirculate := false;

  // initialize P4 registers (default 0)
  assume s1_all_ports_status[0bv32] == 0bv32;
  assume (forall i:bv32 :: ((i != 0bv32)) ==> s1_pkt_curr[i] == 0bv8);
  assume s1_pkt_curr[0bv32] == 2bv8;
  assume s1_pkt_curr[0bv32] == 2bv8;
  assume (forall i:bv32 :: ((i != 0bv32)) ==> s1_pkt_par[i] == 0bv8);
  assume s1_pkt_par[0bv32] == 3bv8;
  assume s1_pkt_par[0bv32] == 3bv8;
  // initialize register write tracking (debug)
  s1_all_ports_status__last_index := 0bv32;
  s1_all_ports_status__last_value := 0bv32;
  s1_all_ports_status__last_old_value := 0bv32;
  s1_all_ports_status__wrote_any := false;
  s1_all_ports_status__wrote_index0 := false;
  s1_all_ports_status__next_write_site := 0;
  s1_all_ports_status__last_write_site := 0;
  s1_all_ports_status__last0_old_value := 0bv32;
  s1_all_ports_status__last0_value := 0bv32;
  s1_pkt_curr__last_index := 0bv32;
  s1_pkt_curr__last_value := 0bv8;
  s1_pkt_curr__last_old_value := 0bv8;
  s1_pkt_curr__wrote_any := false;
  s1_pkt_curr__wrote_index0 := false;
  s1_pkt_curr__next_write_site := 0;
  s1_pkt_curr__last_write_site := 0;
  s1_pkt_curr__last0_old_value := 0bv8;
  s1_pkt_curr__last0_value := 0bv8;
  s1_pkt_par__last_index := 0bv32;
  s1_pkt_par__last_value := 0bv8;
  s1_pkt_par__last_old_value := 0bv8;
  s1_pkt_par__wrote_any := false;
  s1_pkt_par__wrote_index0 := false;
  s1_pkt_par__next_write_site := 0;
  s1_pkt_par__last_write_site := 0;
  s1_pkt_par__last0_old_value := 0bv8;
  s1_pkt_par__last0_value := 0bv8;

  procurator_step := 0;
  procurator_bad := false;
  // step 0: env_inject -> s1
  if (s1_inbox_count < 1) {
  assume s1_inbox_count < 1;
  s1_pkt_external := true;
  havoc s1_standard_metadata.ingress_port;
  havoc s1_standard_metadata.instance_type;
  havoc s1_standard_metadata.packet_length;
  havoc s1_standard_metadata.enq_timestamp;
  havoc s1_standard_metadata.enq_qdepth;
  havoc s1_standard_metadata.deq_timedelta;
  havoc s1_standard_metadata.deq_qdepth;
  havoc s1_standard_metadata.ingress_global_timestamp;
  havoc s1_standard_metadata.egress_global_timestamp;
  havoc s1_standard_metadata.mcast_grp;
  havoc s1_standard_metadata.egress_rid;
  havoc s1_standard_metadata.checksum_error;
  havoc s1_standard_metadata.parser_error;
  havoc s1_standard_metadata.priority;
  havoc s1_meta.local_metadata;
  havoc s1_meta.local_metadata.pkt_start;
  havoc s1_meta.local_metadata.pkt_curr;
  havoc s1_meta.local_metadata.pkt_par;
  havoc s1_meta.local_metadata.out_port;
  havoc s1_meta.local_metadata.if_out_failed;
  havoc s1_meta.local_metadata.first_visit;
  havoc s1_meta.local_metadata.failure_visit;
  havoc s1_meta.local_metadata.is_completed;
  havoc s1_meta.local_metadata.starting_port;
  havoc s1_meta.local_metadata.all_ports;
  havoc s1_meta.local_metadata.out_port_xor;
  havoc s1_hdr.bfsTag.valid;
  havoc s1_hdr.bfsTag.inst;
  havoc s1_hdr.bfsTag.pkt_v1_curr;
  havoc s1_hdr.bfsTag.pkt_v1_par;
  havoc s1_hdr.bfsTag.pkt_v2_curr;
  havoc s1_hdr.bfsTag.pkt_v2_par;
  havoc s1_hdr.bfsTag.pkt_v3_curr;
  havoc s1_hdr.bfsTag.pkt_v3_par;
  havoc s1_hdr.bfsTag.pkt_v4_curr;
  havoc s1_hdr.bfsTag.pkt_v4_par;
  havoc s1_hdr.ff_tags.valid;
  havoc s1_hdr.ff_tags.preamble;
  havoc s1_hdr.ff_tags.shortest_path;
  havoc s1_hdr.ff_tags.path_length;
  havoc s1_hdr.ff_tags.is_edge;
  havoc s1_hdr.ff_tags.bfs_start;
  assume (s1_hdr.ff_tags.valid == true);
  assume (s1_hdr.bfsTag.valid == true);
  assume (s1_hdr.ff_tags.bfs_start == 1bv1);
  assume (s1_hdr.bfsTag.inst == 0bv32);
  assume (s1_standard_metadata.ingress_port == 1bv9);
  s1_inbox_count := s1_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 1: node_pass -> s1
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
  s1_all_ports_status__dbg0 := s1_all_ports_status[0bv32];
  s1_all_ports_status__last_index__dbg := s1_all_ports_status__last_index;
  s1_all_ports_status__last_value__dbg := s1_all_ports_status__last_value;
  s1_all_ports_status__last_old_value__dbg := s1_all_ports_status__last_old_value;
  s1_all_ports_status__wrote_any__dbg := s1_all_ports_status__wrote_any;
  s1_all_ports_status__wrote_index0__dbg := s1_all_ports_status__wrote_index0;
  s1_all_ports_status__last0_old_value__dbg := s1_all_ports_status__last0_old_value;
  s1_all_ports_status__last0_value__dbg := s1_all_ports_status__last0_value;
  s1_pkt_curr__dbg0 := s1_pkt_curr[0bv32];
  s1_pkt_curr__last_index__dbg := s1_pkt_curr__last_index;
  s1_pkt_curr__last_value__dbg := s1_pkt_curr__last_value;
  s1_pkt_curr__last_old_value__dbg := s1_pkt_curr__last_old_value;
  s1_pkt_curr__wrote_any__dbg := s1_pkt_curr__wrote_any;
  s1_pkt_curr__wrote_index0__dbg := s1_pkt_curr__wrote_index0;
  s1_pkt_curr__last0_old_value__dbg := s1_pkt_curr__last0_old_value;
  s1_pkt_curr__last0_value__dbg := s1_pkt_curr__last0_value;
  s1_pkt_par__dbg0 := s1_pkt_par[0bv32];
  s1_pkt_par__last_index__dbg := s1_pkt_par__last_index;
  s1_pkt_par__last_value__dbg := s1_pkt_par__last_value;
  s1_pkt_par__last_old_value__dbg := s1_pkt_par__last_old_value;
  s1_pkt_par__wrote_any__dbg := s1_pkt_par__wrote_any;
  s1_pkt_par__wrote_index0__dbg := s1_pkt_par__wrote_index0;
  s1_pkt_par__last0_old_value__dbg := s1_pkt_par__last0_old_value;
  s1_pkt_par__last0_value__dbg := s1_pkt_par__last0_value;
  // Global assertions (accumulated into procurator_bad)
  if (!((s1_standard_metadata.egress_port != s1_standard_metadata.ingress_port))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  assert !procurator_bad;
}


procedure ULTIMATE.start() returns()
  modifies procurator_bad, procurator_step, s1_all_ports_status__dbg0, s1_all_ports_status__last0_old_value, s1_all_ports_status__last0_old_value__dbg, s1_all_ports_status__last0_value, s1_all_ports_status__last0_value__dbg, s1_all_ports_status__last_index, s1_all_ports_status__last_index__dbg, s1_all_ports_status__last_old_value, s1_all_ports_status__last_old_value__dbg, s1_all_ports_status__last_value, s1_all_ports_status__last_value__dbg, s1_all_ports_status__last_write_site, s1_all_ports_status__next_write_site, s1_all_ports_status__wrote_any, s1_all_ports_status__wrote_any__dbg, s1_all_ports_status__wrote_index0, s1_all_ports_status__wrote_index0__dbg, s1_check_out_failed.action_run, s1_check_out_failed.hit, s1_check_outport_status.action_run, s1_check_outport_status.hit, s1_curr_par_eq_neq_ingress.action_run, s1_curr_par_eq_neq_ingress.hit, s1_curr_par_eq_zero.action_run, s1_curr_par_eq_zero.hit, s1_curr_par_neq_in.action_run, s1_curr_par_neq_in.hit, s1_default_route.action_run, s1_default_route.hit, s1_drop, s1_forward, s1_fwd_parent.action_run, s1_fwd_parent.hit, s1_fwd_pkt.action_run, s1_fwd_pkt.hit, s1_hdr.bfsTag.inst, s1_hdr.bfsTag.pkt_v1_curr, s1_hdr.bfsTag.pkt_v1_par, s1_hdr.bfsTag.pkt_v2_curr, s1_hdr.bfsTag.pkt_v2_par, s1_hdr.bfsTag.pkt_v3_curr, s1_hdr.bfsTag.pkt_v3_par, s1_hdr.bfsTag.pkt_v4_curr, s1_hdr.bfsTag.pkt_v4_par, s1_hdr.bfsTag.valid, s1_hdr.ff_tags.bfs_start, s1_hdr.ff_tags.is_edge, s1_hdr.ff_tags.path_length, s1_hdr.ff_tags.preamble, s1_hdr.ff_tags.shortest_path, s1_hdr.ff_tags.valid, s1_hit_depth.action_run, s1_hit_depth.hit, s1_if_status.action_run, s1_if_status.hit, s1_inbox_count, s1_isValid, s1_jump_to_next.action_run, s1_jump_to_next.hit, s1_meta.local_metadata, s1_meta.local_metadata.all_ports, s1_meta.local_metadata.failure_visit, s1_meta.local_metadata.first_visit, s1_meta.local_metadata.if_out_failed, s1_meta.local_metadata.is_completed, s1_meta.local_metadata.out_port, s1_meta.local_metadata.out_port_xor, s1_meta.local_metadata.pkt_curr, s1_meta.local_metadata.pkt_par, s1_meta.local_metadata.pkt_start, s1_meta.local_metadata.starting_port, s1_out_eq_zero.action_run, s1_out_eq_zero.hit, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_curr, s1_pkt_curr__dbg0, s1_pkt_curr__last0_old_value, s1_pkt_curr__last0_old_value__dbg, s1_pkt_curr__last0_value, s1_pkt_curr__last0_value__dbg, s1_pkt_curr__last_index, s1_pkt_curr__last_index__dbg, s1_pkt_curr__last_old_value, s1_pkt_curr__last_old_value__dbg, s1_pkt_curr__last_value, s1_pkt_curr__last_value__dbg, s1_pkt_curr__last_write_site, s1_pkt_curr__next_write_site, s1_pkt_curr__wrote_any, s1_pkt_curr__wrote_any__dbg, s1_pkt_curr__wrote_index0, s1_pkt_curr__wrote_index0__dbg, s1_pkt_external, s1_pkt_par, s1_pkt_par__dbg0, s1_pkt_par__last0_old_value, s1_pkt_par__last0_old_value__dbg, s1_pkt_par__last0_value, s1_pkt_par__last0_value__dbg, s1_pkt_par__last_index, s1_pkt_par__last_index__dbg, s1_pkt_par__last_old_value, s1_pkt_par__last_old_value__dbg, s1_pkt_par__last_value, s1_pkt_par__last_value__dbg, s1_pkt_par__last_write_site, s1_pkt_par__next_write_site, s1_pkt_par__wrote_any, s1_pkt_par__wrote_any__dbg, s1_pkt_par__wrote_index0, s1_pkt_par__wrote_index0__dbg, s1_send_in_ingress.action_run, s1_send_in_ingress.hit, s1_send_parent.action_run, s1_send_parent.hit, s1_set_egress_port.action_run, s1_set_egress_port.hit, s1_set_out_port.action_run, s1_set_out_port.hit, s1_set_parent_out.action_run, s1_set_parent_out.hit, s1_standard_metadata.checksum_error, s1_standard_metadata.deq_qdepth, s1_standard_metadata.deq_timedelta, s1_standard_metadata.egress_global_timestamp, s1_standard_metadata.egress_port, s1_standard_metadata.egress_rid, s1_standard_metadata.egress_spec, s1_standard_metadata.enq_qdepth, s1_standard_metadata.enq_timestamp, s1_standard_metadata.ingress_global_timestamp, s1_standard_metadata.ingress_port, s1_standard_metadata.instance_type, s1_standard_metadata.mcast_grp, s1_standard_metadata.packet_length, s1_standard_metadata.parser_error, s1_standard_metadata.priority, s1_start_bfs.action_run, s1_start_bfs.hit, s1_to_parent.action_run, s1_to_parent.hit, s1_try_next.action_run, s1_try_next.hit;
{
  call mainProcedure();
}

// ===== END HARNESS =====
