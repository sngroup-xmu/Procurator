// ===== BEGIN PREAMBLE =====
function bvule.bv16(left:bv16, right:bv16) returns(bool);
function {:builtin "bvule"} bvule.bv16$builtin(left:bv16, right:bv16) returns(bool);
axiom (forall left:bv16, right:bv16 :: bvule.bv16(left, right) <==> bvule.bv16$builtin(left, right));
function bvule.bv32(left:bv32, right:bv32) returns(bool);
function {:builtin "bvule"} bvule.bv32$builtin(left:bv32, right:bv32) returns(bool);
axiom (forall left:bv32, right:bv32 :: bvule.bv32(left, right) <==> bvule.bv32$builtin(left, right));
// ===== END PREAMBLE =====

// ===== BEGIN NODE sw (prefixed) =====
type sw_Ref;
type sw_error=bv1;
type sw_HeaderStack = [int]sw_Ref;
var sw_last:[sw_HeaderStack]sw_Ref;
var sw_forward:bool;
var sw_isValid:[sw_Ref]bool;
var sw_emit:[sw_Ref]bool;
var sw_stack.index:[sw_HeaderStack]int;
var sw_size:[sw_HeaderStack]int;
var sw_drop:bool;
var sw_p4b_clone_i2e:bool;
var sw_p4b_clone_e2e:bool;
var sw_p4b_clone_i2i:bool;
var sw_p4b_recirculate:bool;
var sw_p4b_digest:bool;
var sw_p4b_checksum_verified:bool;
var sw_p4b_checksum_updated:bool;
var sw_p4b_checksum_error:bool;
type sw_PortId_t = bv9;

// sw_Struct sw_standard_metadata_t
type sw_standard_metadata_t;
var sw_standard_metadata.ingress_port:sw_PortId_t;
var sw_standard_metadata.egress_spec:sw_PortId_t;
var sw_standard_metadata.egress_port:sw_PortId_t;
var sw_standard_metadata.instance_type:bv32;
var sw_standard_metadata.packet_length:bv32;
var sw_standard_metadata.enq_timestamp:bv32;
var sw_standard_metadata.enq_qdepth:bv19;
var sw_standard_metadata.deq_timedelta:bv32;
var sw_standard_metadata.deq_qdepth:bv19;
var sw_standard_metadata.ingress_global_timestamp:bv48;
var sw_standard_metadata.egress_global_timestamp:bv48;
var sw_standard_metadata.mcast_grp:bv16;
var sw_standard_metadata.egress_rid:bv16;
var sw_standard_metadata.checksum_error:bv1;
var sw_standard_metadata.parser_error:sw_error;
var sw_standard_metadata.priority:bv3;
type sw_CounterType = int;
type sw_MeterType = int;
type sw_HashAlgorithm = int;
type sw_CloneType = int;

// sw_Struct sw_odb_metadata_t
type sw_odb_metadata_t;

// sw_Struct sw_p4db_intrinsic_metadata_t
type sw_p4db_intrinsic_metadata_t;

// sw_Struct sw_routing_metadata_t
type sw_routing_metadata_t;
type sw_ethernet_t;
type sw_ipv4_t;

// sw_Struct sw_metadata
type sw_metadata;
var sw_meta.odb_metadata:sw_odb_metadata_t;
var sw_meta.odb_metadata.match_result:bv32;
var sw_meta.odb_metadata.damper:bv16;
var sw_meta.odb_metadata.damper_threshold:bv16;
var sw_meta.odb_metadata.action_id:bv16;
var sw_meta.odb_metadata.action_parameter1:bv64;
var sw_meta.odb_metadata.action_parameter2:bv64;
var sw_meta.odb_metadata.action_parameter3:bv64;
var sw_meta.odb_metadata.action_parameter4:bv64;
var sw_meta.p4db_intrinsic_metadata:sw_p4db_intrinsic_metadata_t;
var sw_meta.p4db_intrinsic_metadata.ingress_global_timestamp:bv48;
var sw_meta.p4db_intrinsic_metadata.lf_field_list:bv8;
var sw_meta.p4db_intrinsic_metadata.mcast_grp:bv16;
var sw_meta.p4db_intrinsic_metadata.egress_rid:bv16;
var sw_meta.p4db_intrinsic_metadata.resubmit_flag:bv8;
var sw_meta.p4db_intrinsic_metadata.recirculate_flag:bv8;
var sw_meta.p4db_intrinsic_metadata.degist_receiver0:bv8;
var sw_meta.p4db_intrinsic_metadata.degist_receiver1:bv8;
var sw_meta.p4db_intrinsic_metadata.degist_receiver2:bv8;
var sw_meta.p4db_intrinsic_metadata.degist_receiver3:bv8;
var sw_meta.p4db_intrinsic_metadata.degist_receiver4:bv8;
var sw_meta.p4db_intrinsic_metadata.degist_receiver5:bv8;
var sw_meta.p4db_intrinsic_metadata.degist_receiver6:bv8;
var sw_meta.p4db_intrinsic_metadata.degist_receiver7:bv8;
var sw_meta.p4db_intrinsic_metadata.degist_receiver8:bv8;
var sw_meta.p4db_intrinsic_metadata.degist_receiver9:bv8;
var sw_meta.routing_metadata:sw_routing_metadata_t;
var sw_meta.routing_metadata.nhop_ipv4:bv32;

// sw_Struct sw_headers
var sw_hdr:sw_Ref;

// sw_Header sw_ethernet_t
var sw_hdr.ethernet:sw_Ref;
var sw_hdr.ethernet.valid:bool;
var sw_hdr.ethernet.dstAddr:bv48;
var sw_hdr.ethernet.srcAddr:bv48;
var sw_hdr.ethernet.etherType:bv16;

// sw_Header sw_ipv4_t
var sw_hdr.ipv4:sw_Ref;
var sw_hdr.ipv4.valid:bool;
var sw_hdr.ipv4.version:bv4;
var sw_hdr.ipv4.ihl:bv4;
var sw_hdr.ipv4.diffserv:bv8;
var sw_hdr.ipv4.totalLen:bv16;
var sw_hdr.ipv4.identification:bv16;
var sw_hdr.ipv4.flags:bv3;
var sw_hdr.ipv4.fragOffset:bv13;
var sw_hdr.ipv4.ttl:bv8;
var sw_hdr.ipv4.protocol:bv8;
var sw_hdr.ipv4.hdrChecksum:bv16;
var sw_hdr.ipv4.srcAddr:bv32;
var sw_hdr.ipv4.dstAddr:bv32;
var sw_meta:sw_metadata;
var sw_standard_metadata:sw_standard_metadata_t;

// sw_Register sw_damper_register
var sw_damper_register:[bv10]bv16;
var sw_damper_register__last_index:bv10;
var sw_damper_register__last_value:bv16;
var sw_damper_register__last_old_value:bv16;
var sw_damper_register__wrote_any:bool;
var sw_damper_register__wrote_index0:bool;
var sw_damper_register__last0_old_value:bv16;
var sw_damper_register__last0_value:bv16;
var sw_damper_register__next_write_site:int;
var sw_damper_register__last_write_site:int;
const sw_damper_register.size:int;
axiom sw_damper_register.size == 1024;

// sw_Struct sw_break_list
type sw_break_list;

function {:builtin "bvadd"} add.bv16(sw_left:bv16, sw_right:bv16) returns(bv16);

// sw_Table sw_break_1 sw_Actionlist sw_Declaration
type sw_break_1.action;
var sw_break_1.gen_break.id:bv8;

function {:builtin "bvand"} band.bv32(sw_left:bv32, sw_right:bv32) returns(bv32);
const unique sw_break_1.action.gen_break : sw_break_1.action;
const unique sw_break_1.action.NoAction : sw_break_1.action;
var sw_break_1.action_run : sw_break_1.action;
var sw_break_1.hit : bool;

// sw_Table sw_damper_end_tbl_1 sw_Actionlist sw_Declaration
type sw_damper_end_tbl_1.action;
var sw_damper_end_tbl_1.clear_damper.index:bv10;
const unique sw_damper_end_tbl_1.action.clear_damper : sw_damper_end_tbl_1.action;
const unique sw_damper_end_tbl_1.action.NoAction : sw_damper_end_tbl_1.action;
var sw_damper_end_tbl_1.action_run : sw_damper_end_tbl_1.action;
var sw_damper_end_tbl_1.hit : bool;

// sw_Table sw_damper_tbl_1 sw_Actionlist sw_Declaration
type sw_damper_tbl_1.action;
var sw_damper_tbl_1.set_damper.index:bv10;
var sw_damper_tbl_1.set_damper.threshold:bv16;
const unique sw_damper_tbl_1.action.set_damper : sw_damper_tbl_1.action;
const unique sw_damper_tbl_1.action.NoAction : sw_damper_tbl_1.action;
var sw_damper_tbl_1.action_run : sw_damper_tbl_1.action;
var sw_damper_tbl_1.hit : bool;

function {:builtin "bvuge"} buge.bv16(sw_left:bv16, sw_right:bv16) returns(bool);

function {:builtin "bvsub"} sub.bv8(sw_left:bv8, sw_right:bv8) returns(bv8);

// sw_Table sw_forward_table sw_Actionlist sw_Declaration
type sw_forward_table.action;
var sw_forward_table.set_dmac.dmac:bv48;
var sw_forward_table.set_dmac.port:bv9;
const unique sw_forward_table.action.set_dmac : sw_forward_table.action;
const unique sw_forward_table.action._drop : sw_forward_table.action;
const unique sw_forward_table.action.NoAction : sw_forward_table.action;
var sw_forward_table.action_run : sw_forward_table.action;
var sw_forward_table.hit : bool;

// sw_Table sw_ipv4_nhop sw_Actionlist sw_Declaration
type sw_ipv4_nhop.action;
var sw_ipv4_nhop.set_nhop.nhop_ipv4:bv32;
const unique sw_ipv4_nhop.action.set_nhop : sw_ipv4_nhop.action;
const unique sw_ipv4_nhop.action._drop : sw_ipv4_nhop.action;
const unique sw_ipv4_nhop.action.NoAction : sw_ipv4_nhop.action;
var sw_ipv4_nhop.action_run : sw_ipv4_nhop.action;
var sw_ipv4_nhop.hit : bool;

// sw_Table sw_send_frame sw_Actionlist sw_Declaration
type sw_send_frame.action;
var sw_send_frame.set_smac.smac:bv48;
const unique sw_send_frame.action.set_smac : sw_send_frame.action;
const unique sw_send_frame.action._drop : sw_send_frame.action;
const unique sw_send_frame.action.NoAction : sw_send_frame.action;
var sw_send_frame.action_run : sw_send_frame.action;
var sw_send_frame.hit : bool;

function {:builtin "bvugt"} bugt.bv8(sw_left:bv8, sw_right:bv8) returns(bool);

function {:builtin "bvsub"} sub.bv17(sw_left:bv17, sw_right:bv17) returns(bv17);

function {:builtin "bvsub"} sub.bv33(sw_left:bv33, sw_right:bv33) returns(bv33);

// sw_Parser sw_ParserImpl
procedure {:inline 1} sw_ParserImpl()
	modifies sw_drop, sw_isValid;
{
    goto sw_State$ParserImpl$start;

        sw_State$ParserImpl$parse_ethernet:
    call sw_packet_in.extract(sw_hdr.ethernet);
    goto sw_State$ParserImpl$parse_ethernet$parse_ipv4_2, sw_State$ParserImpl$parse_ethernet$DEFAULT;
    
sw_State$ParserImpl$parse_ethernet$parse_ipv4_2:
    assume (sw_hdr.ethernet.etherType == 2048bv16);
    goto sw_State$ParserImpl$parse_ipv4;

    sw_State$ParserImpl$parse_ethernet$DEFAULT:
    assume(!(sw_hdr.ethernet.etherType == 2048bv16));
    goto sw_State$accept;

        sw_State$ParserImpl$parse_ipv4:
    call sw_packet_in.extract(sw_hdr.ipv4);
    goto sw_State$accept;

        sw_State$ParserImpl$start:
    goto sw_State$ParserImpl$parse_ethernet;

    sw_State$accept:
    call sw_accept();
    goto sw_Exit;

    sw_State$reject:
    call sw_reject();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw__drop
procedure {:inline 1} sw__drop()
	modifies sw_drop;
{
    call sw_mark_to_drop();
}
procedure {:inline 1} sw_accept()
{
}

// sw_Table sw_break_1
procedure {:inline 1} sw_break_1.apply()
	modifies sw_break_1.action_run, sw_break_1.gen_break.id, sw_break_1.hit, sw_hdr.ipv4.dstAddr, sw_p4b_digest;
{
    sw_hdr.ipv4.dstAddr := sw_hdr.ipv4.dstAddr;
    sw_break_1.hit := false;
    if(band.bv32(sw_hdr.ipv4.dstAddr, 4294967295bv32) == 167772161bv32){
        sw_break_1.hit := true;
        sw_break_1.action_run := sw_break_1.action.gen_break;
        sw_break_1.gen_break.id := 1bv8;
        call sw_gen_break(sw_break_1.gen_break.id);
        goto sw_Exit;
    }
    else if(band.bv32(sw_hdr.ipv4.dstAddr, 4294967295bv32) == 167772162bv32){
        sw_break_1.hit := true;
        sw_break_1.action_run := sw_break_1.action.gen_break;
        sw_break_1.gen_break.id := 1bv8;
        call sw_gen_break(sw_break_1.gen_break.id);
        goto sw_Exit;
    }

    sw_Exit:
}

// sw_Action sw_clear_damper
procedure {:inline 1} sw_clear_damper(sw_index:bv10)
	modifies sw_damper_register, sw_damper_register__last0_old_value, sw_damper_register__last0_value, sw_damper_register__last_index, sw_damper_register__last_old_value, sw_damper_register__last_value, sw_damper_register__last_write_site, sw_damper_register__next_write_site, sw_damper_register__wrote_any, sw_damper_register__wrote_index0;
{
    sw_damper_register__next_write_site := 1;
    call sw_damper_register.write(sw_index, 0bv16);
}

// sw_Control sw_computeChecksum
procedure {:inline 1} sw_computeChecksum()
	modifies sw_hdr.ipv4.hdrChecksum, sw_p4b_checksum_updated;
{
    if (true) {
        sw_p4b_checksum_updated := true;
        havoc sw_hdr.ipv4.hdrChecksum;
    }
}

// sw_Control sw_damper_1
procedure {:inline 1} sw_damper_1()
	modifies sw_break_1.action_run, sw_break_1.gen_break.id, sw_break_1.hit, sw_damper_end_tbl_1.action_run, sw_damper_end_tbl_1.clear_damper.index, sw_damper_end_tbl_1.hit, sw_damper_register, sw_damper_register__last0_old_value, sw_damper_register__last0_value, sw_damper_register__last_index, sw_damper_register__last_old_value, sw_damper_register__last_value, sw_damper_register__last_write_site, sw_damper_register__next_write_site, sw_damper_register__wrote_any, sw_damper_register__wrote_index0, sw_damper_tbl_1.action_run, sw_damper_tbl_1.hit, sw_damper_tbl_1.set_damper.index, sw_damper_tbl_1.set_damper.threshold, sw_hdr.ipv4.dstAddr, sw_meta.odb_metadata.damper, sw_meta.odb_metadata.damper_threshold, sw_p4b_digest;
{
    call sw_damper_tbl_1.apply();
    if(buge.bv16(sw_meta.odb_metadata.damper, sw_meta.odb_metadata.damper_threshold)){
        call sw_break_1.apply();
        call sw_damper_end_tbl_1.apply();
    }
}

// sw_Table sw_damper_end_tbl_1
procedure {:inline 1} sw_damper_end_tbl_1.apply()
	modifies sw_damper_end_tbl_1.action_run, sw_damper_end_tbl_1.clear_damper.index, sw_damper_end_tbl_1.hit, sw_damper_register, sw_damper_register__last0_old_value, sw_damper_register__last0_value, sw_damper_register__last_index, sw_damper_register__last_old_value, sw_damper_register__last_value, sw_damper_register__last_write_site, sw_damper_register__next_write_site, sw_damper_register__wrote_any, sw_damper_register__wrote_index0;
{
    sw_damper_end_tbl_1.hit := false;
    sw_damper_end_tbl_1.action_run := sw_damper_end_tbl_1.action.clear_damper;
    sw_damper_end_tbl_1.clear_damper.index := 0bv10;
    call sw_clear_damper(sw_damper_end_tbl_1.clear_damper.index);
    goto sw_Exit;

    sw_Exit:
}
function {:inline true}sw_damper_register.read(sw_reg:[bv10]bv16, sw_index:bv10)returns (bv16) {sw_reg[sw_index]}
procedure sw_damper_register.register_write(sw_arg0:bv10, sw_arg1:bv16);
procedure {:inline 1} sw_damper_register.write(sw_index:bv10, sw_value:bv16)
	modifies sw_damper_register, sw_damper_register__last0_old_value, sw_damper_register__last0_value, sw_damper_register__last_index, sw_damper_register__last_old_value, sw_damper_register__last_value, sw_damper_register__last_write_site, sw_damper_register__wrote_any, sw_damper_register__wrote_index0;
{
    sw_damper_register__last_old_value := sw_damper_register[sw_index];
    sw_damper_register[sw_index] := sw_value;
    sw_damper_register__last_index := sw_index;
    sw_damper_register__last_value := sw_value;
    sw_damper_register__last_write_site := sw_damper_register__next_write_site;
    sw_damper_register__wrote_any := true;
    if (sw_index == 0bv10) {
        sw_damper_register__wrote_index0 := true;
        sw_damper_register__last0_old_value := sw_damper_register__last_old_value;
        sw_damper_register__last0_value := sw_value;
    }
}

// sw_Table sw_damper_tbl_1
procedure {:inline 1} sw_damper_tbl_1.apply()
	modifies sw_damper_register, sw_damper_register__last0_old_value, sw_damper_register__last0_value, sw_damper_register__last_index, sw_damper_register__last_old_value, sw_damper_register__last_value, sw_damper_register__last_write_site, sw_damper_register__next_write_site, sw_damper_register__wrote_any, sw_damper_register__wrote_index0, sw_damper_tbl_1.action_run, sw_damper_tbl_1.hit, sw_damper_tbl_1.set_damper.index, sw_damper_tbl_1.set_damper.threshold, sw_meta.odb_metadata.damper, sw_meta.odb_metadata.damper_threshold;
{
    sw_damper_tbl_1.hit := false;
    sw_damper_tbl_1.action_run := sw_damper_tbl_1.action.set_damper;
    sw_damper_tbl_1.set_damper.index := 0bv10;
    sw_damper_tbl_1.set_damper.threshold := 1bv16;
    call sw_set_damper(sw_damper_tbl_1.set_damper.index, sw_damper_tbl_1.set_damper.threshold);
    goto sw_Exit;

    sw_Exit:
}

// sw_Control sw_egress
procedure {:inline 1} sw_egress()
{
}

// sw_Table sw_forward_table
procedure {:inline 1} sw_forward_table.apply()
	modifies sw_forward, sw_forward_table.action_run, sw_forward_table.hit, sw_forward_table.set_dmac.dmac, sw_forward_table.set_dmac.port, sw_hdr.ethernet.dstAddr, sw_meta.routing_metadata.nhop_ipv4, sw_standard_metadata.egress_port, sw_standard_metadata.egress_spec;
{
    sw_meta.routing_metadata.nhop_ipv4 := sw_meta.routing_metadata.nhop_ipv4;
    sw_forward_table.hit := false;
    if(sw_meta.routing_metadata.nhop_ipv4 == 167772161bv32){
        sw_forward_table.hit := true;
        sw_forward_table.action_run := sw_forward_table.action.set_dmac;
        sw_forward_table.set_dmac.dmac := 140883517308929bv48;
        sw_forward_table.set_dmac.port := 1bv9;
        call sw_set_dmac(sw_forward_table.set_dmac.dmac, sw_forward_table.set_dmac.port);
        goto sw_Exit;
    }
    else if(sw_meta.routing_metadata.nhop_ipv4 == 167772162bv32){
        sw_forward_table.hit := true;
        sw_forward_table.action_run := sw_forward_table.action.set_dmac;
        sw_forward_table.set_dmac.dmac := 140883517308930bv48;
        sw_forward_table.set_dmac.port := 2bv9;
        call sw_set_dmac(sw_forward_table.set_dmac.dmac, sw_forward_table.set_dmac.port);
        goto sw_Exit;
    }

    sw_Exit:
}

// sw_Action sw_gen_break
procedure {:inline 1} sw_gen_break(sw_id:bv8)
	modifies sw_p4b_digest;
{
    sw_p4b_digest := true;
}

// sw_Control sw_ingress
procedure {:inline 1} sw_ingress()
	modifies sw_break_1.action_run, sw_break_1.gen_break.id, sw_break_1.hit, sw_damper_end_tbl_1.action_run, sw_damper_end_tbl_1.clear_damper.index, sw_damper_end_tbl_1.hit, sw_damper_register, sw_damper_register__last0_old_value, sw_damper_register__last0_value, sw_damper_register__last_index, sw_damper_register__last_old_value, sw_damper_register__last_value, sw_damper_register__last_write_site, sw_damper_register__next_write_site, sw_damper_register__wrote_any, sw_damper_register__wrote_index0, sw_damper_tbl_1.action_run, sw_damper_tbl_1.hit, sw_damper_tbl_1.set_damper.index, sw_damper_tbl_1.set_damper.threshold, sw_forward, sw_forward_table.action_run, sw_forward_table.hit, sw_forward_table.set_dmac.dmac, sw_forward_table.set_dmac.port, sw_hdr.ethernet.dstAddr, sw_hdr.ethernet.srcAddr, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.ttl, sw_ipv4_nhop.action_run, sw_ipv4_nhop.hit, sw_ipv4_nhop.set_nhop.nhop_ipv4, sw_meta.odb_metadata.damper, sw_meta.odb_metadata.damper_threshold, sw_meta.routing_metadata.nhop_ipv4, sw_p4b_digest, sw_send_frame.action_run, sw_send_frame.hit, sw_send_frame.set_smac.smac, sw_standard_metadata.egress_port, sw_standard_metadata.egress_spec;
{
    if((sw_isValid[sw_hdr.ipv4]) && (bugt.bv8(sw_hdr.ipv4.ttl, 0bv8))){
        call sw_damper_1();
        call sw_ipv4_nhop.apply();
        call sw_forward_table.apply();
        call sw_send_frame.apply();
    }
}

// sw_Table sw_ipv4_nhop
procedure {:inline 1} sw_ipv4_nhop.apply()
	modifies sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.ttl, sw_ipv4_nhop.action_run, sw_ipv4_nhop.hit, sw_ipv4_nhop.set_nhop.nhop_ipv4, sw_meta.routing_metadata.nhop_ipv4;
{
    sw_hdr.ipv4.dstAddr := sw_hdr.ipv4.dstAddr;
    sw_ipv4_nhop.hit := false;
    if(band.bv32(sw_hdr.ipv4.dstAddr, 4294967295bv32) == 167772161bv32){
        sw_ipv4_nhop.hit := true;
        sw_ipv4_nhop.action_run := sw_ipv4_nhop.action.set_nhop;
        sw_ipv4_nhop.set_nhop.nhop_ipv4 := 167772161bv32;
        call sw_set_nhop(sw_ipv4_nhop.set_nhop.nhop_ipv4);
        goto sw_Exit;
    }
    else if(band.bv32(sw_hdr.ipv4.dstAddr, 4294967295bv32) == 167772162bv32){
        sw_ipv4_nhop.hit := true;
        sw_ipv4_nhop.action_run := sw_ipv4_nhop.action.set_nhop;
        sw_ipv4_nhop.set_nhop.nhop_ipv4 := 167772162bv32;
        call sw_set_nhop(sw_ipv4_nhop.set_nhop.nhop_ipv4);
        goto sw_Exit;
    }

    sw_Exit:
}
procedure {:inline 1} sw_main()
	modifies sw_break_1.action_run, sw_break_1.gen_break.id, sw_break_1.hit, sw_damper_end_tbl_1.action_run, sw_damper_end_tbl_1.clear_damper.index, sw_damper_end_tbl_1.hit, sw_damper_register, sw_damper_register__last0_old_value, sw_damper_register__last0_value, sw_damper_register__last_index, sw_damper_register__last_old_value, sw_damper_register__last_value, sw_damper_register__last_write_site, sw_damper_register__next_write_site, sw_damper_register__wrote_any, sw_damper_register__wrote_index0, sw_damper_tbl_1.action_run, sw_damper_tbl_1.hit, sw_damper_tbl_1.set_damper.index, sw_damper_tbl_1.set_damper.threshold, sw_drop, sw_forward, sw_forward_table.action_run, sw_forward_table.hit, sw_forward_table.set_dmac.dmac, sw_forward_table.set_dmac.port, sw_hdr.ethernet.dstAddr, sw_hdr.ethernet.srcAddr, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.hdrChecksum, sw_hdr.ipv4.ttl, sw_ipv4_nhop.action_run, sw_ipv4_nhop.hit, sw_ipv4_nhop.set_nhop.nhop_ipv4, sw_isValid, sw_meta.odb_metadata.damper, sw_meta.odb_metadata.damper_threshold, sw_meta.routing_metadata.nhop_ipv4, sw_p4b_checksum_error, sw_p4b_checksum_updated, sw_p4b_checksum_verified, sw_p4b_digest, sw_send_frame.action_run, sw_send_frame.hit, sw_send_frame.set_smac.smac, sw_standard_metadata.egress_port, sw_standard_metadata.egress_spec;
{
    call sw_ParserImpl();
    call sw_verifyChecksum();
    call sw_ingress();
    call sw_egress();
    call sw_computeChecksum();
    if(sw_forward == false){
        sw_drop := true;
    }
}
procedure sw_mainProcedure()
	modifies sw_break_1.action_run, sw_break_1.gen_break.id, sw_break_1.hit, sw_damper_end_tbl_1.action_run, sw_damper_end_tbl_1.clear_damper.index, sw_damper_end_tbl_1.hit, sw_damper_register, sw_damper_register__last0_old_value, sw_damper_register__last0_value, sw_damper_register__last_index, sw_damper_register__last_old_value, sw_damper_register__last_value, sw_damper_register__last_write_site, sw_damper_register__next_write_site, sw_damper_register__wrote_any, sw_damper_register__wrote_index0, sw_damper_tbl_1.action_run, sw_damper_tbl_1.hit, sw_damper_tbl_1.set_damper.index, sw_damper_tbl_1.set_damper.threshold, sw_drop, sw_forward, sw_forward_table.action_run, sw_forward_table.hit, sw_forward_table.set_dmac.dmac, sw_forward_table.set_dmac.port, sw_hdr.ethernet.dstAddr, sw_hdr.ethernet.srcAddr, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.hdrChecksum, sw_hdr.ipv4.ttl, sw_ipv4_nhop.action_run, sw_ipv4_nhop.hit, sw_ipv4_nhop.set_nhop.nhop_ipv4, sw_isValid, sw_meta.odb_metadata.damper, sw_meta.odb_metadata.damper_threshold, sw_meta.routing_metadata.nhop_ipv4, sw_p4b_checksum_error, sw_p4b_checksum_updated, sw_p4b_checksum_verified, sw_p4b_clone_e2e, sw_p4b_clone_i2e, sw_p4b_clone_i2i, sw_p4b_digest, sw_p4b_recirculate, sw_send_frame.action_run, sw_send_frame.hit, sw_send_frame.set_smac.smac, sw_standard_metadata.egress_port, sw_standard_metadata.egress_spec;
{
    sw_p4b_checksum_error := false;
    sw_p4b_checksum_updated := false;
    sw_p4b_checksum_verified := false;
    sw_p4b_digest := false;
    sw_p4b_recirculate := false;
    sw_p4b_clone_i2i := false;
    sw_p4b_clone_e2e := false;
    sw_p4b_clone_i2e := false;
    call sw_main();
}
procedure sw_mark_to_drop();
    ensures sw_drop==true;
	modifies sw_drop;
procedure sw_packet.emit(sw_arg0:sw_Ref);
procedure sw_packet_in.extract(sw_header:sw_Ref);
    ensures (sw_isValid[sw_header] == true);
	modifies sw_isValid;
procedure sw_reject();
    ensures sw_drop==true;
	modifies sw_drop;

// sw_Table sw_send_frame
procedure {:inline 1} sw_send_frame.apply()
	modifies sw_hdr.ethernet.srcAddr, sw_send_frame.action_run, sw_send_frame.hit, sw_send_frame.set_smac.smac, sw_standard_metadata.egress_port;
{
    sw_standard_metadata.egress_port := sw_standard_metadata.egress_port;
    sw_send_frame.hit := false;
    if(sw_standard_metadata.egress_port == 1bv9){
        sw_send_frame.hit := true;
        sw_send_frame.action_run := sw_send_frame.action.set_smac;
        sw_send_frame.set_smac.smac := 140883517308929bv48;
        call sw_set_smac(sw_send_frame.set_smac.smac);
        goto sw_Exit;
    }
    else if(sw_standard_metadata.egress_port == 2bv9){
        sw_send_frame.hit := true;
        sw_send_frame.action_run := sw_send_frame.action.set_smac;
        sw_send_frame.set_smac.smac := 140883517308930bv48;
        call sw_set_smac(sw_send_frame.set_smac.smac);
        goto sw_Exit;
    }

    sw_Exit:
}
procedure {:inline 1} sw_setInvalid(sw_header:sw_Ref);
    ensures (sw_isValid[sw_header] == false);
	modifies sw_isValid;
procedure {:inline 1} sw_setValid(sw_header:sw_Ref);

// sw_Action sw_set_damper
procedure {:inline 1} sw_set_damper(sw_index:bv10, sw_threshold:bv16)
	modifies sw_damper_register, sw_damper_register__last0_old_value, sw_damper_register__last0_value, sw_damper_register__last_index, sw_damper_register__last_old_value, sw_damper_register__last_value, sw_damper_register__last_write_site, sw_damper_register__next_write_site, sw_damper_register__wrote_any, sw_damper_register__wrote_index0, sw_meta.odb_metadata.damper, sw_meta.odb_metadata.damper_threshold;
{
    sw_meta.odb_metadata.damper := sw_damper_register.read(sw_damper_register, sw_index);
    sw_damper_register__next_write_site := 2;
    call sw_damper_register.write(sw_index, add.bv16(sw_meta.odb_metadata.damper, 1bv16));
    sw_meta.odb_metadata.damper_threshold := sw_threshold;
}

// sw_Action sw_set_dmac
procedure {:inline 1} sw_set_dmac(sw_dmac:bv48, sw_port:bv9)
	modifies sw_forward, sw_hdr.ethernet.dstAddr, sw_standard_metadata.egress_port, sw_standard_metadata.egress_spec;
{
    sw_hdr.ethernet.dstAddr := sw_dmac;
    sw_standard_metadata.egress_spec := sw_port;
    sw_standard_metadata.egress_port := sw_port;
    sw_forward := true;
}

// sw_Action sw_set_nhop
procedure {:inline 1} sw_set_nhop(sw_nhop_ipv4:bv32)
	modifies sw_hdr.ipv4.ttl, sw_meta.routing_metadata.nhop_ipv4;
{
    sw_meta.routing_metadata.nhop_ipv4 := sw_nhop_ipv4;
    sw_hdr.ipv4.ttl := sub.bv8(sw_hdr.ipv4.ttl, 1bv8);
}

// sw_Action sw_set_smac
procedure {:inline 1} sw_set_smac(sw_smac:bv48)
	modifies sw_hdr.ethernet.srcAddr;
{
    sw_hdr.ethernet.srcAddr := sw_smac;
}

// sw_Control sw_verifyChecksum
procedure {:inline 1} sw_verifyChecksum()
	modifies sw_p4b_checksum_error, sw_p4b_checksum_verified;
{
    if (true) {
        sw_p4b_checksum_verified := true;
        havoc sw_p4b_checksum_error;
    }
}
// ===== END NODE sw =====

// ===== BEGIN ENQUEUE PROCEDURES =====
// ===== END ENQUEUE PROCEDURES =====

// ===== BEGIN HARNESS =====
// Auto-generated by Procurator (DSL -> Boogie harness: sequential scheduler)
// Message abstraction: Bag(K=1) using inbox_count per node; single-slot mailbox for packet fields

var procurator_step: int;
var procurator_bad: bool;

// DSL state variables (modeled as Boogie globals)
var dsl_phase: int;

var sw_inbox_count: int;
var io_inbox_count: int;

var sw_pkt_external: bool;
var io_pkt_external: bool;

// Host packet fields (mirrors connected node symbols)
var io_standard_metadata.ingress_port: sw_PortId_t;
var io_standard_metadata.instance_type: bv32;
var io_standard_metadata.packet_length: bv32;
var io_standard_metadata.enq_timestamp: bv32;
var io_standard_metadata.enq_qdepth: bv19;
var io_standard_metadata.deq_timedelta: bv32;
var io_standard_metadata.deq_qdepth: bv19;
var io_standard_metadata.ingress_global_timestamp: bv48;
var io_standard_metadata.egress_global_timestamp: bv48;
var io_standard_metadata.mcast_grp: bv16;
var io_standard_metadata.egress_rid: bv16;
var io_standard_metadata.checksum_error: bv1;
var io_standard_metadata.parser_error: sw_error;
var io_standard_metadata.priority: bv3;
var io_meta.odb_metadata: sw_odb_metadata_t;
var io_meta.odb_metadata.match_result: bv32;
var io_meta.odb_metadata.damper: bv16;
var io_meta.odb_metadata.damper_threshold: bv16;
var io_meta.odb_metadata.action_id: bv16;
var io_meta.odb_metadata.action_parameter1: bv64;
var io_meta.odb_metadata.action_parameter2: bv64;
var io_meta.odb_metadata.action_parameter3: bv64;
var io_meta.odb_metadata.action_parameter4: bv64;
var io_meta.p4db_intrinsic_metadata: sw_p4db_intrinsic_metadata_t;
var io_meta.p4db_intrinsic_metadata.ingress_global_timestamp: bv48;
var io_meta.p4db_intrinsic_metadata.lf_field_list: bv8;
var io_meta.p4db_intrinsic_metadata.mcast_grp: bv16;
var io_meta.p4db_intrinsic_metadata.egress_rid: bv16;
var io_meta.p4db_intrinsic_metadata.resubmit_flag: bv8;
var io_meta.p4db_intrinsic_metadata.recirculate_flag: bv8;
var io_meta.p4db_intrinsic_metadata.degist_receiver0: bv8;
var io_meta.p4db_intrinsic_metadata.degist_receiver1: bv8;
var io_meta.p4db_intrinsic_metadata.degist_receiver2: bv8;
var io_meta.p4db_intrinsic_metadata.degist_receiver3: bv8;
var io_meta.p4db_intrinsic_metadata.degist_receiver4: bv8;
var io_meta.p4db_intrinsic_metadata.degist_receiver5: bv8;
var io_meta.p4db_intrinsic_metadata.degist_receiver6: bv8;
var io_meta.p4db_intrinsic_metadata.degist_receiver7: bv8;
var io_meta.p4db_intrinsic_metadata.degist_receiver8: bv8;
var io_meta.p4db_intrinsic_metadata.degist_receiver9: bv8;
var io_meta.routing_metadata: sw_routing_metadata_t;
var io_meta.routing_metadata.nhop_ipv4: bv32;
var io_hdr.ethernet.valid: bool;
var io_hdr.ethernet.dstAddr: bv48;
var io_hdr.ethernet.srcAddr: bv48;
var io_hdr.ethernet.etherType: bv16;
var io_hdr.ipv4.valid: bool;
var io_hdr.ipv4.version: bv4;
var io_hdr.ipv4.ihl: bv4;
var io_hdr.ipv4.diffserv: bv8;
var io_hdr.ipv4.totalLen: bv16;
var io_hdr.ipv4.identification: bv16;
var io_hdr.ipv4.flags: bv3;
var io_hdr.ipv4.fragOffset: bv13;
var io_hdr.ipv4.ttl: bv8;
var io_hdr.ipv4.protocol: bv8;
var io_hdr.ipv4.hdrChecksum: bv16;
var io_hdr.ipv4.srcAddr: bv32;
var io_hdr.ipv4.dstAddr: bv32;

// Forwarding (derived from DSL topology)
procedure sw_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (sw_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure mainProcedure() returns()
  modifies dsl_phase, io_hdr.ethernet.dstAddr, io_hdr.ethernet.etherType, io_hdr.ethernet.srcAddr, io_hdr.ethernet.valid, io_hdr.ipv4.diffserv, io_hdr.ipv4.dstAddr, io_hdr.ipv4.flags, io_hdr.ipv4.fragOffset, io_hdr.ipv4.hdrChecksum, io_hdr.ipv4.identification, io_hdr.ipv4.ihl, io_hdr.ipv4.protocol, io_hdr.ipv4.srcAddr, io_hdr.ipv4.totalLen, io_hdr.ipv4.ttl, io_hdr.ipv4.valid, io_hdr.ipv4.version, io_inbox_count, io_meta.odb_metadata, io_meta.odb_metadata.action_id, io_meta.odb_metadata.action_parameter1, io_meta.odb_metadata.action_parameter2, io_meta.odb_metadata.action_parameter3, io_meta.odb_metadata.action_parameter4, io_meta.odb_metadata.damper, io_meta.odb_metadata.damper_threshold, io_meta.odb_metadata.match_result, io_meta.p4db_intrinsic_metadata, io_meta.p4db_intrinsic_metadata.degist_receiver0, io_meta.p4db_intrinsic_metadata.degist_receiver1, io_meta.p4db_intrinsic_metadata.degist_receiver2, io_meta.p4db_intrinsic_metadata.degist_receiver3, io_meta.p4db_intrinsic_metadata.degist_receiver4, io_meta.p4db_intrinsic_metadata.degist_receiver5, io_meta.p4db_intrinsic_metadata.degist_receiver6, io_meta.p4db_intrinsic_metadata.degist_receiver7, io_meta.p4db_intrinsic_metadata.degist_receiver8, io_meta.p4db_intrinsic_metadata.degist_receiver9, io_meta.p4db_intrinsic_metadata.egress_rid, io_meta.p4db_intrinsic_metadata.ingress_global_timestamp, io_meta.p4db_intrinsic_metadata.lf_field_list, io_meta.p4db_intrinsic_metadata.mcast_grp, io_meta.p4db_intrinsic_metadata.recirculate_flag, io_meta.p4db_intrinsic_metadata.resubmit_flag, io_meta.routing_metadata, io_meta.routing_metadata.nhop_ipv4, io_pkt_external, io_standard_metadata.checksum_error, io_standard_metadata.deq_qdepth, io_standard_metadata.deq_timedelta, io_standard_metadata.egress_global_timestamp, io_standard_metadata.egress_rid, io_standard_metadata.enq_qdepth, io_standard_metadata.enq_timestamp, io_standard_metadata.ingress_global_timestamp, io_standard_metadata.ingress_port, io_standard_metadata.instance_type, io_standard_metadata.mcast_grp, io_standard_metadata.packet_length, io_standard_metadata.parser_error, io_standard_metadata.priority, procurator_bad, procurator_step, sw_break_1.action_run, sw_break_1.gen_break.id, sw_break_1.hit, sw_damper_end_tbl_1.action_run, sw_damper_end_tbl_1.clear_damper.index, sw_damper_end_tbl_1.hit, sw_damper_register, sw_damper_register__last0_old_value, sw_damper_register__last0_value, sw_damper_register__last_index, sw_damper_register__last_old_value, sw_damper_register__last_value, sw_damper_register__last_write_site, sw_damper_register__next_write_site, sw_damper_register__wrote_any, sw_damper_register__wrote_index0, sw_damper_tbl_1.action_run, sw_damper_tbl_1.hit, sw_damper_tbl_1.set_damper.index, sw_damper_tbl_1.set_damper.threshold, sw_drop, sw_forward, sw_forward_table.action_run, sw_forward_table.hit, sw_forward_table.set_dmac.dmac, sw_forward_table.set_dmac.port, sw_hdr.ethernet.dstAddr, sw_hdr.ethernet.etherType, sw_hdr.ethernet.srcAddr, sw_hdr.ethernet.valid, sw_hdr.ipv4.diffserv, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.flags, sw_hdr.ipv4.fragOffset, sw_hdr.ipv4.hdrChecksum, sw_hdr.ipv4.identification, sw_hdr.ipv4.ihl, sw_hdr.ipv4.protocol, sw_hdr.ipv4.srcAddr, sw_hdr.ipv4.totalLen, sw_hdr.ipv4.ttl, sw_hdr.ipv4.valid, sw_hdr.ipv4.version, sw_inbox_count, sw_ipv4_nhop.action_run, sw_ipv4_nhop.hit, sw_ipv4_nhop.set_nhop.nhop_ipv4, sw_isValid, sw_meta.odb_metadata, sw_meta.odb_metadata.action_id, sw_meta.odb_metadata.action_parameter1, sw_meta.odb_metadata.action_parameter2, sw_meta.odb_metadata.action_parameter3, sw_meta.odb_metadata.action_parameter4, sw_meta.odb_metadata.damper, sw_meta.odb_metadata.damper_threshold, sw_meta.odb_metadata.match_result, sw_meta.p4db_intrinsic_metadata, sw_meta.p4db_intrinsic_metadata.degist_receiver0, sw_meta.p4db_intrinsic_metadata.degist_receiver1, sw_meta.p4db_intrinsic_metadata.degist_receiver2, sw_meta.p4db_intrinsic_metadata.degist_receiver3, sw_meta.p4db_intrinsic_metadata.degist_receiver4, sw_meta.p4db_intrinsic_metadata.degist_receiver5, sw_meta.p4db_intrinsic_metadata.degist_receiver6, sw_meta.p4db_intrinsic_metadata.degist_receiver7, sw_meta.p4db_intrinsic_metadata.degist_receiver8, sw_meta.p4db_intrinsic_metadata.degist_receiver9, sw_meta.p4db_intrinsic_metadata.egress_rid, sw_meta.p4db_intrinsic_metadata.ingress_global_timestamp, sw_meta.p4db_intrinsic_metadata.lf_field_list, sw_meta.p4db_intrinsic_metadata.mcast_grp, sw_meta.p4db_intrinsic_metadata.recirculate_flag, sw_meta.p4db_intrinsic_metadata.resubmit_flag, sw_meta.routing_metadata, sw_meta.routing_metadata.nhop_ipv4, sw_p4b_checksum_error, sw_p4b_checksum_updated, sw_p4b_checksum_verified, sw_p4b_clone_e2e, sw_p4b_clone_i2e, sw_p4b_clone_i2i, sw_p4b_digest, sw_p4b_recirculate, sw_pkt_external, sw_send_frame.action_run, sw_send_frame.hit, sw_send_frame.set_smac.smac, sw_standard_metadata.checksum_error, sw_standard_metadata.deq_qdepth, sw_standard_metadata.deq_timedelta, sw_standard_metadata.egress_global_timestamp, sw_standard_metadata.egress_port, sw_standard_metadata.egress_rid, sw_standard_metadata.egress_spec, sw_standard_metadata.enq_qdepth, sw_standard_metadata.enq_timestamp, sw_standard_metadata.ingress_global_timestamp, sw_standard_metadata.ingress_port, sw_standard_metadata.instance_type, sw_standard_metadata.mcast_grp, sw_standard_metadata.packet_length, sw_standard_metadata.parser_error, sw_standard_metadata.priority;
{
  // initialize inboxes
  sw_inbox_count := 0;
  sw_pkt_external := false;
  io_inbox_count := 0;
  io_pkt_external := false;
  // initialize P4B event flags (clone/recirculate)
  sw_p4b_clone_i2e := false;
  sw_p4b_clone_e2e := false;
  sw_p4b_clone_i2i := false;
  sw_p4b_recirculate := false;

  // initialize DSL state
  dsl_phase := 0;
  // initialize P4 registers (default 0)
  assume (forall i:bv10 :: ((i != 0bv10)) ==> sw_damper_register[i] == 0bv16);
  assume sw_damper_register[0bv10] == 0bv16;
  assume sw_damper_register[0bv10] == 0bv16;
  // initialize register write tracking (debug)
  sw_damper_register__last_index := 0bv10;
  sw_damper_register__last_value := 0bv16;
  sw_damper_register__last_old_value := 0bv16;
  sw_damper_register__wrote_any := false;
  sw_damper_register__wrote_index0 := false;
  sw_damper_register__next_write_site := 0;
  sw_damper_register__last_write_site := 0;
  sw_damper_register__last0_old_value := 0bv16;
  sw_damper_register__last0_value := 0bv16;

  procurator_step := 0;
  procurator_bad := false;
  // step 0: host_send -> io
  // inject packet into connected node (host -> node)
  if (sw_inbox_count < 1) {
    assume sw_inbox_count < 1;
    havoc io_standard_metadata.instance_type;
    havoc io_standard_metadata.packet_length;
    havoc io_standard_metadata.enq_timestamp;
    havoc io_standard_metadata.enq_qdepth;
    havoc io_standard_metadata.deq_timedelta;
    havoc io_standard_metadata.deq_qdepth;
    havoc io_standard_metadata.ingress_global_timestamp;
    havoc io_standard_metadata.egress_global_timestamp;
    havoc io_standard_metadata.mcast_grp;
    havoc io_standard_metadata.egress_rid;
    havoc io_standard_metadata.checksum_error;
    havoc io_standard_metadata.parser_error;
    havoc io_standard_metadata.priority;
    havoc io_meta.odb_metadata;
    havoc io_meta.odb_metadata.match_result;
    havoc io_meta.odb_metadata.damper;
    havoc io_meta.odb_metadata.damper_threshold;
    havoc io_meta.odb_metadata.action_id;
    havoc io_meta.odb_metadata.action_parameter1;
    havoc io_meta.odb_metadata.action_parameter2;
    havoc io_meta.odb_metadata.action_parameter3;
    havoc io_meta.odb_metadata.action_parameter4;
    havoc io_meta.p4db_intrinsic_metadata;
    havoc io_meta.p4db_intrinsic_metadata.ingress_global_timestamp;
    havoc io_meta.p4db_intrinsic_metadata.lf_field_list;
    havoc io_meta.p4db_intrinsic_metadata.mcast_grp;
    havoc io_meta.p4db_intrinsic_metadata.egress_rid;
    havoc io_meta.p4db_intrinsic_metadata.resubmit_flag;
    havoc io_meta.p4db_intrinsic_metadata.recirculate_flag;
    havoc io_meta.p4db_intrinsic_metadata.degist_receiver0;
    havoc io_meta.p4db_intrinsic_metadata.degist_receiver1;
    havoc io_meta.p4db_intrinsic_metadata.degist_receiver2;
    havoc io_meta.p4db_intrinsic_metadata.degist_receiver3;
    havoc io_meta.p4db_intrinsic_metadata.degist_receiver4;
    havoc io_meta.p4db_intrinsic_metadata.degist_receiver5;
    havoc io_meta.p4db_intrinsic_metadata.degist_receiver6;
    havoc io_meta.p4db_intrinsic_metadata.degist_receiver7;
    havoc io_meta.p4db_intrinsic_metadata.degist_receiver8;
    havoc io_meta.p4db_intrinsic_metadata.degist_receiver9;
    havoc io_meta.routing_metadata;
    havoc io_meta.routing_metadata.nhop_ipv4;
    havoc io_hdr.ethernet.dstAddr;
    havoc io_hdr.ethernet.srcAddr;
    havoc io_hdr.ipv4.version;
    havoc io_hdr.ipv4.ihl;
    havoc io_hdr.ipv4.diffserv;
    havoc io_hdr.ipv4.totalLen;
    havoc io_hdr.ipv4.identification;
    havoc io_hdr.ipv4.flags;
    havoc io_hdr.ipv4.fragOffset;
    havoc io_hdr.ipv4.protocol;
    havoc io_hdr.ipv4.hdrChecksum;
    io_hdr.ethernet.valid := true;
    io_hdr.ipv4.valid := true;
    io_hdr.ethernet.etherType := 2048bv16;
    io_hdr.ipv4.ttl := 2bv8;
    io_hdr.ipv4.dstAddr := 167772161bv32;
    io_hdr.ipv4.srcAddr := 167772162bv32;
    io_standard_metadata.ingress_port := 1bv9;
    if ((dsl_phase == 0)) {
      dsl_phase := 1;
    } else {
      dsl_phase := 2;
    }
    sw_standard_metadata.ingress_port := io_standard_metadata.ingress_port;
    sw_standard_metadata.instance_type := io_standard_metadata.instance_type;
    sw_standard_metadata.packet_length := io_standard_metadata.packet_length;
    sw_standard_metadata.enq_timestamp := io_standard_metadata.enq_timestamp;
    sw_standard_metadata.enq_qdepth := io_standard_metadata.enq_qdepth;
    sw_standard_metadata.deq_timedelta := io_standard_metadata.deq_timedelta;
    sw_standard_metadata.deq_qdepth := io_standard_metadata.deq_qdepth;
    sw_standard_metadata.ingress_global_timestamp := io_standard_metadata.ingress_global_timestamp;
    sw_standard_metadata.egress_global_timestamp := io_standard_metadata.egress_global_timestamp;
    sw_standard_metadata.mcast_grp := io_standard_metadata.mcast_grp;
    sw_standard_metadata.egress_rid := io_standard_metadata.egress_rid;
    sw_standard_metadata.checksum_error := io_standard_metadata.checksum_error;
    sw_standard_metadata.parser_error := io_standard_metadata.parser_error;
    sw_standard_metadata.priority := io_standard_metadata.priority;
    sw_meta.odb_metadata := io_meta.odb_metadata;
    sw_meta.odb_metadata.match_result := io_meta.odb_metadata.match_result;
    sw_meta.odb_metadata.damper := io_meta.odb_metadata.damper;
    sw_meta.odb_metadata.damper_threshold := io_meta.odb_metadata.damper_threshold;
    sw_meta.odb_metadata.action_id := io_meta.odb_metadata.action_id;
    sw_meta.odb_metadata.action_parameter1 := io_meta.odb_metadata.action_parameter1;
    sw_meta.odb_metadata.action_parameter2 := io_meta.odb_metadata.action_parameter2;
    sw_meta.odb_metadata.action_parameter3 := io_meta.odb_metadata.action_parameter3;
    sw_meta.odb_metadata.action_parameter4 := io_meta.odb_metadata.action_parameter4;
    sw_meta.p4db_intrinsic_metadata := io_meta.p4db_intrinsic_metadata;
    sw_meta.p4db_intrinsic_metadata.ingress_global_timestamp := io_meta.p4db_intrinsic_metadata.ingress_global_timestamp;
    sw_meta.p4db_intrinsic_metadata.lf_field_list := io_meta.p4db_intrinsic_metadata.lf_field_list;
    sw_meta.p4db_intrinsic_metadata.mcast_grp := io_meta.p4db_intrinsic_metadata.mcast_grp;
    sw_meta.p4db_intrinsic_metadata.egress_rid := io_meta.p4db_intrinsic_metadata.egress_rid;
    sw_meta.p4db_intrinsic_metadata.resubmit_flag := io_meta.p4db_intrinsic_metadata.resubmit_flag;
    sw_meta.p4db_intrinsic_metadata.recirculate_flag := io_meta.p4db_intrinsic_metadata.recirculate_flag;
    sw_meta.p4db_intrinsic_metadata.degist_receiver0 := io_meta.p4db_intrinsic_metadata.degist_receiver0;
    sw_meta.p4db_intrinsic_metadata.degist_receiver1 := io_meta.p4db_intrinsic_metadata.degist_receiver1;
    sw_meta.p4db_intrinsic_metadata.degist_receiver2 := io_meta.p4db_intrinsic_metadata.degist_receiver2;
    sw_meta.p4db_intrinsic_metadata.degist_receiver3 := io_meta.p4db_intrinsic_metadata.degist_receiver3;
    sw_meta.p4db_intrinsic_metadata.degist_receiver4 := io_meta.p4db_intrinsic_metadata.degist_receiver4;
    sw_meta.p4db_intrinsic_metadata.degist_receiver5 := io_meta.p4db_intrinsic_metadata.degist_receiver5;
    sw_meta.p4db_intrinsic_metadata.degist_receiver6 := io_meta.p4db_intrinsic_metadata.degist_receiver6;
    sw_meta.p4db_intrinsic_metadata.degist_receiver7 := io_meta.p4db_intrinsic_metadata.degist_receiver7;
    sw_meta.p4db_intrinsic_metadata.degist_receiver8 := io_meta.p4db_intrinsic_metadata.degist_receiver8;
    sw_meta.p4db_intrinsic_metadata.degist_receiver9 := io_meta.p4db_intrinsic_metadata.degist_receiver9;
    sw_meta.routing_metadata := io_meta.routing_metadata;
    sw_meta.routing_metadata.nhop_ipv4 := io_meta.routing_metadata.nhop_ipv4;
    sw_hdr.ethernet.valid := io_hdr.ethernet.valid;
    sw_hdr.ethernet.dstAddr := io_hdr.ethernet.dstAddr;
    sw_hdr.ethernet.srcAddr := io_hdr.ethernet.srcAddr;
    sw_hdr.ethernet.etherType := io_hdr.ethernet.etherType;
    sw_hdr.ipv4.valid := io_hdr.ipv4.valid;
    sw_hdr.ipv4.version := io_hdr.ipv4.version;
    sw_hdr.ipv4.ihl := io_hdr.ipv4.ihl;
    sw_hdr.ipv4.diffserv := io_hdr.ipv4.diffserv;
    sw_hdr.ipv4.totalLen := io_hdr.ipv4.totalLen;
    sw_hdr.ipv4.identification := io_hdr.ipv4.identification;
    sw_hdr.ipv4.flags := io_hdr.ipv4.flags;
    sw_hdr.ipv4.fragOffset := io_hdr.ipv4.fragOffset;
    sw_hdr.ipv4.ttl := io_hdr.ipv4.ttl;
    sw_hdr.ipv4.protocol := io_hdr.ipv4.protocol;
    sw_hdr.ipv4.hdrChecksum := io_hdr.ipv4.hdrChecksum;
    sw_hdr.ipv4.srcAddr := io_hdr.ipv4.srcAddr;
    sw_hdr.ipv4.dstAddr := io_hdr.ipv4.dstAddr;
    sw_pkt_external := true;
    sw_inbox_count := sw_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 1: host_recv -> io
  procurator_step := procurator_step + 1;
  // step 2: node_pass -> sw
  if (sw_inbox_count > 0) {
  assume sw_inbox_count > 0;
  sw_inbox_count := sw_inbox_count - 1;
  call sw_mainProcedure();
  if (sw_p4b_clone_i2e) {
    assume sw_inbox_count < 1;
    sw_pkt_external := false;
    sw_inbox_count := sw_inbox_count + 1;
  }
  sw_p4b_clone_i2e := false;
  if (sw_p4b_clone_e2e) {
    assume sw_inbox_count < 1;
    sw_pkt_external := false;
    sw_inbox_count := sw_inbox_count + 1;
  }
  sw_p4b_clone_e2e := false;
  if (sw_p4b_clone_i2i) {
    assume sw_inbox_count < 1;
    sw_pkt_external := false;
    sw_inbox_count := sw_inbox_count + 1;
  }
  sw_p4b_clone_i2i := false;
  if (sw_p4b_recirculate) {
    assume sw_inbox_count < 1;
    sw_pkt_external := false;
    sw_inbox_count := sw_inbox_count + 1;
  }
  sw_p4b_recirculate := false;
  call sw_Forward();
  // Global assertions (accumulated into procurator_bad)
  if (!(((dsl_phase != 1) || (sw_damper_register__last0_value == 0bv16)))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  assert !procurator_bad;
}


procedure ULTIMATE.start() returns()
  modifies dsl_phase, io_hdr.ethernet.dstAddr, io_hdr.ethernet.etherType, io_hdr.ethernet.srcAddr, io_hdr.ethernet.valid, io_hdr.ipv4.diffserv, io_hdr.ipv4.dstAddr, io_hdr.ipv4.flags, io_hdr.ipv4.fragOffset, io_hdr.ipv4.hdrChecksum, io_hdr.ipv4.identification, io_hdr.ipv4.ihl, io_hdr.ipv4.protocol, io_hdr.ipv4.srcAddr, io_hdr.ipv4.totalLen, io_hdr.ipv4.ttl, io_hdr.ipv4.valid, io_hdr.ipv4.version, io_inbox_count, io_meta.odb_metadata, io_meta.odb_metadata.action_id, io_meta.odb_metadata.action_parameter1, io_meta.odb_metadata.action_parameter2, io_meta.odb_metadata.action_parameter3, io_meta.odb_metadata.action_parameter4, io_meta.odb_metadata.damper, io_meta.odb_metadata.damper_threshold, io_meta.odb_metadata.match_result, io_meta.p4db_intrinsic_metadata, io_meta.p4db_intrinsic_metadata.degist_receiver0, io_meta.p4db_intrinsic_metadata.degist_receiver1, io_meta.p4db_intrinsic_metadata.degist_receiver2, io_meta.p4db_intrinsic_metadata.degist_receiver3, io_meta.p4db_intrinsic_metadata.degist_receiver4, io_meta.p4db_intrinsic_metadata.degist_receiver5, io_meta.p4db_intrinsic_metadata.degist_receiver6, io_meta.p4db_intrinsic_metadata.degist_receiver7, io_meta.p4db_intrinsic_metadata.degist_receiver8, io_meta.p4db_intrinsic_metadata.degist_receiver9, io_meta.p4db_intrinsic_metadata.egress_rid, io_meta.p4db_intrinsic_metadata.ingress_global_timestamp, io_meta.p4db_intrinsic_metadata.lf_field_list, io_meta.p4db_intrinsic_metadata.mcast_grp, io_meta.p4db_intrinsic_metadata.recirculate_flag, io_meta.p4db_intrinsic_metadata.resubmit_flag, io_meta.routing_metadata, io_meta.routing_metadata.nhop_ipv4, io_pkt_external, io_standard_metadata.checksum_error, io_standard_metadata.deq_qdepth, io_standard_metadata.deq_timedelta, io_standard_metadata.egress_global_timestamp, io_standard_metadata.egress_rid, io_standard_metadata.enq_qdepth, io_standard_metadata.enq_timestamp, io_standard_metadata.ingress_global_timestamp, io_standard_metadata.ingress_port, io_standard_metadata.instance_type, io_standard_metadata.mcast_grp, io_standard_metadata.packet_length, io_standard_metadata.parser_error, io_standard_metadata.priority, procurator_bad, procurator_step, sw_break_1.action_run, sw_break_1.gen_break.id, sw_break_1.hit, sw_damper_end_tbl_1.action_run, sw_damper_end_tbl_1.clear_damper.index, sw_damper_end_tbl_1.hit, sw_damper_register, sw_damper_register__last0_old_value, sw_damper_register__last0_value, sw_damper_register__last_index, sw_damper_register__last_old_value, sw_damper_register__last_value, sw_damper_register__last_write_site, sw_damper_register__next_write_site, sw_damper_register__wrote_any, sw_damper_register__wrote_index0, sw_damper_tbl_1.action_run, sw_damper_tbl_1.hit, sw_damper_tbl_1.set_damper.index, sw_damper_tbl_1.set_damper.threshold, sw_drop, sw_forward, sw_forward_table.action_run, sw_forward_table.hit, sw_forward_table.set_dmac.dmac, sw_forward_table.set_dmac.port, sw_hdr.ethernet.dstAddr, sw_hdr.ethernet.etherType, sw_hdr.ethernet.srcAddr, sw_hdr.ethernet.valid, sw_hdr.ipv4.diffserv, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.flags, sw_hdr.ipv4.fragOffset, sw_hdr.ipv4.hdrChecksum, sw_hdr.ipv4.identification, sw_hdr.ipv4.ihl, sw_hdr.ipv4.protocol, sw_hdr.ipv4.srcAddr, sw_hdr.ipv4.totalLen, sw_hdr.ipv4.ttl, sw_hdr.ipv4.valid, sw_hdr.ipv4.version, sw_inbox_count, sw_ipv4_nhop.action_run, sw_ipv4_nhop.hit, sw_ipv4_nhop.set_nhop.nhop_ipv4, sw_isValid, sw_meta.odb_metadata, sw_meta.odb_metadata.action_id, sw_meta.odb_metadata.action_parameter1, sw_meta.odb_metadata.action_parameter2, sw_meta.odb_metadata.action_parameter3, sw_meta.odb_metadata.action_parameter4, sw_meta.odb_metadata.damper, sw_meta.odb_metadata.damper_threshold, sw_meta.odb_metadata.match_result, sw_meta.p4db_intrinsic_metadata, sw_meta.p4db_intrinsic_metadata.degist_receiver0, sw_meta.p4db_intrinsic_metadata.degist_receiver1, sw_meta.p4db_intrinsic_metadata.degist_receiver2, sw_meta.p4db_intrinsic_metadata.degist_receiver3, sw_meta.p4db_intrinsic_metadata.degist_receiver4, sw_meta.p4db_intrinsic_metadata.degist_receiver5, sw_meta.p4db_intrinsic_metadata.degist_receiver6, sw_meta.p4db_intrinsic_metadata.degist_receiver7, sw_meta.p4db_intrinsic_metadata.degist_receiver8, sw_meta.p4db_intrinsic_metadata.degist_receiver9, sw_meta.p4db_intrinsic_metadata.egress_rid, sw_meta.p4db_intrinsic_metadata.ingress_global_timestamp, sw_meta.p4db_intrinsic_metadata.lf_field_list, sw_meta.p4db_intrinsic_metadata.mcast_grp, sw_meta.p4db_intrinsic_metadata.recirculate_flag, sw_meta.p4db_intrinsic_metadata.resubmit_flag, sw_meta.routing_metadata, sw_meta.routing_metadata.nhop_ipv4, sw_p4b_checksum_error, sw_p4b_checksum_updated, sw_p4b_checksum_verified, sw_p4b_clone_e2e, sw_p4b_clone_i2e, sw_p4b_clone_i2i, sw_p4b_digest, sw_p4b_recirculate, sw_pkt_external, sw_send_frame.action_run, sw_send_frame.hit, sw_send_frame.set_smac.smac, sw_standard_metadata.checksum_error, sw_standard_metadata.deq_qdepth, sw_standard_metadata.deq_timedelta, sw_standard_metadata.egress_global_timestamp, sw_standard_metadata.egress_port, sw_standard_metadata.egress_rid, sw_standard_metadata.egress_spec, sw_standard_metadata.enq_qdepth, sw_standard_metadata.enq_timestamp, sw_standard_metadata.ingress_global_timestamp, sw_standard_metadata.ingress_port, sw_standard_metadata.instance_type, sw_standard_metadata.mcast_grp, sw_standard_metadata.packet_length, sw_standard_metadata.parser_error, sw_standard_metadata.priority;
{
  call mainProcedure();
}

// ===== END HARNESS =====
