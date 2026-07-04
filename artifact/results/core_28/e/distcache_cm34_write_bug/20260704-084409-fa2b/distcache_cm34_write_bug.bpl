// ===== BEGIN PREAMBLE =====
function bvule.bv16(left:bv16, right:bv16) returns(bool);
function {:builtin "bvule"} bvule.bv16$builtin(left:bv16, right:bv16) returns(bool);
axiom (forall left:bv16, right:bv16 :: bvule.bv16(left, right) <==> bvule.bv16$builtin(left, right));
function bvule.bv32(left:bv32, right:bv32) returns(bool);
function {:builtin "bvule"} bvule.bv32$builtin(left:bv32, right:bv32) returns(bool);
axiom (forall left:bv32, right:bv32 :: bvule.bv32(left, right) <==> bvule.bv32$builtin(left, right));
// ===== END PREAMBLE =====

// ===== BEGIN NODE leaf (prefixed) =====
type leaf_Ref;
type leaf_error=bv1;
type leaf_HeaderStack = [int]leaf_Ref;
var leaf_last:[leaf_HeaderStack]leaf_Ref;
var leaf_forward:bool;
var leaf_isValid:[leaf_Ref]bool;
var leaf_emit:[leaf_Ref]bool;
var leaf_stack.index:[leaf_HeaderStack]int;
var leaf_size:[leaf_HeaderStack]int;
var leaf_drop:bool;
var leaf_p4b_clone_i2e:bool;
var leaf_p4b_clone_e2e:bool;
var leaf_p4b_clone_i2i:bool;
var leaf_p4b_recirculate:bool;
var leaf_p4b_digest:bool;
var leaf_p4b_checksum_verified:bool;
var leaf_p4b_checksum_updated:bool;
var leaf_p4b_checksum_error:bool;

// leaf_Struct leaf_standard_metadata_t
type leaf_standard_metadata_t;
var leaf_standard_metadata.egress_port:bv9;
type leaf_CounterType = int;
type leaf_MeterType = int;
type leaf_HashAlgorithm = int;
type leaf_CloneType = int;
type leaf_ethernet_t;
type leaf_ipv4_t;
type leaf_udp_t;
type leaf_op_t;
type leaf_vallen_t;
type leaf_val_t;
type leaf_shadowtype_t;
type leaf_seq_t;
type leaf_inswitch_t;
type leaf_stat_t;
type leaf_clone_t;
type leaf_frequency_t;
type leaf_fraginfo_t;

// leaf_Struct leaf_headers
var leaf_hdr:leaf_Ref;

// leaf_Header leaf_ethernet_t
var leaf_hdr.ethernet_hdr:leaf_Ref;
var leaf_hdr.ethernet_hdr.valid:bool;
var leaf_hdr.ethernet_hdr.dstAddr:bv48;
var leaf_hdr.ethernet_hdr.srcAddr:bv48;
var leaf_hdr.ethernet_hdr.etherType:bv16;

// leaf_Header leaf_ipv4_t
var leaf_hdr.ipv4_hdr:leaf_Ref;
var leaf_hdr.ipv4_hdr.valid:bool;
var leaf_hdr.ipv4_hdr.version:bv4;
var leaf_hdr.ipv4_hdr.ihl:bv4;
var leaf_hdr.ipv4_hdr.diffserv:bv8;
var leaf_hdr.ipv4_hdr.totalLen:bv16;
var leaf_hdr.ipv4_hdr.identification:bv16;
var leaf_hdr.ipv4_hdr.flags:bv3;
var leaf_hdr.ipv4_hdr.fragOffset:bv13;
var leaf_hdr.ipv4_hdr.ttl:bv8;
var leaf_hdr.ipv4_hdr.protocol:bv8;
var leaf_hdr.ipv4_hdr.hdrChecksum:bv16;
var leaf_hdr.ipv4_hdr.srcAddr:bv32;
var leaf_hdr.ipv4_hdr.dstAddr:bv32;

// leaf_Header leaf_udp_t
var leaf_hdr.udp_hdr:leaf_Ref;
var leaf_hdr.udp_hdr.valid:bool;
var leaf_hdr.udp_hdr.srcPort:bv16;
var leaf_hdr.udp_hdr.dstPort:bv16;
var leaf_hdr.udp_hdr.hdrlen:bv16;
var leaf_hdr.udp_hdr.checksum:bv16;

// leaf_Header leaf_op_t
var leaf_hdr.op_hdr:leaf_Ref;
var leaf_hdr.op_hdr.valid:bool;
var leaf_hdr.op_hdr.optype:bv16;
var leaf_hdr.op_hdr.keylolo:bv32;
var leaf_hdr.op_hdr.keylohi:bv32;
var leaf_hdr.op_hdr.keyhilo:bv32;
var leaf_hdr.op_hdr.keyhihilo:bv16;
var leaf_hdr.op_hdr.keyhihihi:bv16;

// leaf_Header leaf_vallen_t
var leaf_hdr.vallen_hdr:leaf_Ref;
var leaf_hdr.vallen_hdr.valid:bool;
var leaf_hdr.vallen_hdr.vallen:bv16;

// leaf_Header leaf_val_t
var leaf_hdr.val1_hdr:leaf_Ref;
var leaf_hdr.val1_hdr.valid:bool;
var leaf_hdr.val1_hdr.vallo:bv32;
var leaf_hdr.val1_hdr.valhi:bv32;

// leaf_Header leaf_val_t
var leaf_hdr.val2_hdr:leaf_Ref;
var leaf_hdr.val2_hdr.valid:bool;
var leaf_hdr.val2_hdr.vallo:bv32;
var leaf_hdr.val2_hdr.valhi:bv32;

// leaf_Header leaf_val_t
var leaf_hdr.val3_hdr:leaf_Ref;
var leaf_hdr.val3_hdr.valid:bool;
var leaf_hdr.val3_hdr.vallo:bv32;
var leaf_hdr.val3_hdr.valhi:bv32;

// leaf_Header leaf_val_t
var leaf_hdr.val4_hdr:leaf_Ref;
var leaf_hdr.val4_hdr.valid:bool;
var leaf_hdr.val4_hdr.vallo:bv32;
var leaf_hdr.val4_hdr.valhi:bv32;

// leaf_Header leaf_val_t
var leaf_hdr.val5_hdr:leaf_Ref;
var leaf_hdr.val5_hdr.valid:bool;
var leaf_hdr.val5_hdr.vallo:bv32;
var leaf_hdr.val5_hdr.valhi:bv32;

// leaf_Header leaf_val_t
var leaf_hdr.val6_hdr:leaf_Ref;
var leaf_hdr.val6_hdr.valid:bool;
var leaf_hdr.val6_hdr.vallo:bv32;
var leaf_hdr.val6_hdr.valhi:bv32;

// leaf_Header leaf_val_t
var leaf_hdr.val7_hdr:leaf_Ref;
var leaf_hdr.val7_hdr.valid:bool;
var leaf_hdr.val7_hdr.vallo:bv32;
var leaf_hdr.val7_hdr.valhi:bv32;

// leaf_Header leaf_val_t
var leaf_hdr.val8_hdr:leaf_Ref;
var leaf_hdr.val8_hdr.valid:bool;
var leaf_hdr.val8_hdr.vallo:bv32;
var leaf_hdr.val8_hdr.valhi:bv32;

// leaf_Header leaf_val_t
var leaf_hdr.val9_hdr:leaf_Ref;
var leaf_hdr.val9_hdr.valid:bool;
var leaf_hdr.val9_hdr.vallo:bv32;
var leaf_hdr.val9_hdr.valhi:bv32;

// leaf_Header leaf_val_t
var leaf_hdr.val10_hdr:leaf_Ref;
var leaf_hdr.val10_hdr.valid:bool;
var leaf_hdr.val10_hdr.vallo:bv32;
var leaf_hdr.val10_hdr.valhi:bv32;

// leaf_Header leaf_val_t
var leaf_hdr.val11_hdr:leaf_Ref;
var leaf_hdr.val11_hdr.valid:bool;
var leaf_hdr.val11_hdr.vallo:bv32;
var leaf_hdr.val11_hdr.valhi:bv32;

// leaf_Header leaf_val_t
var leaf_hdr.val12_hdr:leaf_Ref;
var leaf_hdr.val12_hdr.valid:bool;
var leaf_hdr.val12_hdr.vallo:bv32;
var leaf_hdr.val12_hdr.valhi:bv32;

// leaf_Header leaf_val_t
var leaf_hdr.val13_hdr:leaf_Ref;
var leaf_hdr.val13_hdr.valid:bool;
var leaf_hdr.val13_hdr.vallo:bv32;
var leaf_hdr.val13_hdr.valhi:bv32;

// leaf_Header leaf_val_t
var leaf_hdr.val14_hdr:leaf_Ref;
var leaf_hdr.val14_hdr.valid:bool;
var leaf_hdr.val14_hdr.vallo:bv32;
var leaf_hdr.val14_hdr.valhi:bv32;

// leaf_Header leaf_val_t
var leaf_hdr.val15_hdr:leaf_Ref;
var leaf_hdr.val15_hdr.valid:bool;
var leaf_hdr.val15_hdr.vallo:bv32;
var leaf_hdr.val15_hdr.valhi:bv32;

// leaf_Header leaf_val_t
var leaf_hdr.val16_hdr:leaf_Ref;
var leaf_hdr.val16_hdr.valid:bool;
var leaf_hdr.val16_hdr.vallo:bv32;
var leaf_hdr.val16_hdr.valhi:bv32;

// leaf_Header leaf_shadowtype_t
var leaf_hdr.shadowtype_hdr:leaf_Ref;
var leaf_hdr.shadowtype_hdr.valid:bool;
var leaf_hdr.shadowtype_hdr.shadowtype:bv16;

// leaf_Header leaf_seq_t
var leaf_hdr.seq_hdr:leaf_Ref;
var leaf_hdr.seq_hdr.valid:bool;
var leaf_hdr.seq_hdr.seq:bv32;

// leaf_Header leaf_inswitch_t
var leaf_hdr.inswitch_hdr:leaf_Ref;
var leaf_hdr.inswitch_hdr.valid:bool;
var leaf_hdr.inswitch_hdr.is_cached:bv1;
var leaf_hdr.inswitch_hdr.is_sampled:bv1;
var leaf_hdr.inswitch_hdr.client_sid:bv10;
var leaf_hdr.inswitch_hdr.padding1:bv4;
var leaf_hdr.inswitch_hdr.hot_threshold:bv16;
var leaf_hdr.inswitch_hdr.hashval_for_cm1:bv16;
var leaf_hdr.inswitch_hdr.hashval_for_cm2:bv16;
var leaf_hdr.inswitch_hdr.hashval_for_cm3:bv16;
var leaf_hdr.inswitch_hdr.hashval_for_cm4:bv16;
var leaf_hdr.inswitch_hdr.hashval_for_bf1:bv18;
var leaf_hdr.inswitch_hdr.padding2:bv14;
var leaf_hdr.inswitch_hdr.hashval_for_bf2:bv18;
var leaf_hdr.inswitch_hdr.padding3:bv14;
var leaf_hdr.inswitch_hdr.hashval_for_bf3:bv18;
var leaf_hdr.inswitch_hdr.padding4:bv14;
var leaf_hdr.inswitch_hdr.hashval_for_seq:bv16;
var leaf_hdr.inswitch_hdr.idx:bv16;

// leaf_Header leaf_stat_t
var leaf_hdr.stat_hdr:leaf_Ref;
var leaf_hdr.stat_hdr.valid:bool;
var leaf_hdr.stat_hdr.stat:bv8;
var leaf_hdr.stat_hdr.nodeidx_foreval:bv16;
var leaf_hdr.stat_hdr.padding:bv8;

// leaf_Header leaf_clone_t
var leaf_hdr.clone_hdr:leaf_Ref;
var leaf_hdr.clone_hdr.valid:bool;
var leaf_hdr.clone_hdr.clonenum_for_pktloss:bv16;
var leaf_hdr.clone_hdr.client_udpport:bv16;
var leaf_hdr.clone_hdr.server_sid:bv10;
var leaf_hdr.clone_hdr.padding:bv6;
var leaf_hdr.clone_hdr.server_udpport:bv16;

// leaf_Header leaf_frequency_t
var leaf_hdr.frequency_hdr:leaf_Ref;
var leaf_hdr.frequency_hdr.valid:bool;
var leaf_hdr.frequency_hdr.frequency:bv32;

// leaf_Header leaf_fraginfo_t
var leaf_hdr.fraginfo_hdr:leaf_Ref;
var leaf_hdr.fraginfo_hdr.valid:bool;
var leaf_hdr.fraginfo_hdr.padding1:bv16;
var leaf_hdr.fraginfo_hdr.padding2:bv32;
var leaf_hdr.fraginfo_hdr.cur_fragidx:bv16;
var leaf_hdr.fraginfo_hdr.max_fragnum:bv16;

// leaf_Struct leaf_metadata
type leaf_metadata;
var leaf_meta.bypass_egress:bv1;
var leaf_meta:leaf_metadata;

function {:builtin "bvand"} band.bv16(leaf_left:bv16, leaf_right:bv16) returns(bv16);
type leaf_egressSpec_t = bv9;
var leaf_hdr_eg:leaf_Ref;

// leaf_Header leaf_ethernet_t

// leaf_Header leaf_ipv4_t

// leaf_Header leaf_udp_t

// leaf_Header leaf_op_t
var leaf_hdr_eg.op_hdr:leaf_Ref;
var leaf_hdr_eg.op_hdr.optype:bv16;

// leaf_Header leaf_vallen_t

// leaf_Header leaf_val_t

// leaf_Header leaf_val_t

// leaf_Header leaf_val_t

// leaf_Header leaf_val_t

// leaf_Header leaf_val_t

// leaf_Header leaf_val_t

// leaf_Header leaf_val_t

// leaf_Header leaf_val_t

// leaf_Header leaf_val_t

// leaf_Header leaf_val_t

// leaf_Header leaf_val_t

// leaf_Header leaf_val_t

// leaf_Header leaf_val_t

// leaf_Header leaf_val_t

// leaf_Header leaf_val_t

// leaf_Header leaf_val_t

// leaf_Header leaf_shadowtype_t
var leaf_hdr_eg.shadowtype_hdr:leaf_Ref;
var leaf_hdr_eg.shadowtype_hdr.shadowtype:bv16;

// leaf_Header leaf_seq_t

// leaf_Header leaf_inswitch_t
var leaf_hdr_eg.inswitch_hdr:leaf_Ref;
var leaf_hdr_eg.inswitch_hdr.valid:bool;
var leaf_hdr_eg.inswitch_hdr.hot_threshold:bv16;
var leaf_hdr_eg.inswitch_hdr.hashval_for_cm3:bv16;
var leaf_hdr_eg.inswitch_hdr.hashval_for_cm4:bv16;

// leaf_Header leaf_stat_t

// leaf_Header leaf_clone_t

// leaf_Header leaf_frequency_t

// leaf_Header leaf_fraginfo_t

// leaf_Register leaf_netcacheEgress_cm3_reg
var leaf_netcacheEgress_cm3_reg:[bv32]bv16;
var leaf_netcacheEgress_cm3_reg__last_index:bv32;
var leaf_netcacheEgress_cm3_reg__last_value:bv16;
var leaf_netcacheEgress_cm3_reg__last_old_value:bv16;
var leaf_netcacheEgress_cm3_reg__wrote_any:bool;
var leaf_netcacheEgress_cm3_reg__wrote_index0:bool;
var leaf_netcacheEgress_cm3_reg__last0_old_value:bv16;
var leaf_netcacheEgress_cm3_reg__last0_value:bv16;
var leaf_netcacheEgress_cm3_reg__next_write_site:int;
var leaf_netcacheEgress_cm3_reg__last_write_site:int;
const leaf_netcacheEgress_cm3_reg.size:bv32;
axiom leaf_netcacheEgress_cm3_reg.size == 65536bv32;

// leaf_Register leaf_netcacheEgress_cm4_reg
var leaf_netcacheEgress_cm4_reg:[bv32]bv16;
var leaf_netcacheEgress_cm4_reg__last_index:bv32;
var leaf_netcacheEgress_cm4_reg__last_value:bv16;
var leaf_netcacheEgress_cm4_reg__last_old_value:bv16;
var leaf_netcacheEgress_cm4_reg__wrote_any:bool;
var leaf_netcacheEgress_cm4_reg__wrote_index0:bool;
var leaf_netcacheEgress_cm4_reg__last0_old_value:bv16;
var leaf_netcacheEgress_cm4_reg__last0_value:bv16;
var leaf_netcacheEgress_cm4_reg__next_write_site:int;
var leaf_netcacheEgress_cm4_reg__last_write_site:int;
const leaf_netcacheEgress_cm4_reg.size:bv32;
axiom leaf_netcacheEgress_cm4_reg.size == 65536bv32;

function {:builtin "bvsub"} sub.bv17(leaf_left:bv17, leaf_right:bv17) returns(bv17);

function {:builtin "bvsub"} sub.bv33(leaf_left:bv33, leaf_right:bv33) returns(bv33);
procedure {:inline 1} leaf_accept()
{
}
procedure {:inline 1} leaf_main()
	modifies leaf_drop, leaf_isValid;
{
    call leaf_netcacheParser();
    call leaf_netcacheVerifyChecksum();
    call leaf_netcacheIngress();
    call leaf_netcacheEgress();
    call leaf_netcacheComputeChecksum();
    if(leaf_forward == false){
        leaf_drop := true;
    }
}
procedure leaf_mainProcedure()
	modifies leaf_drop, leaf_isValid, leaf_p4b_checksum_error, leaf_p4b_checksum_updated, leaf_p4b_checksum_verified, leaf_p4b_clone_e2e, leaf_p4b_clone_i2e, leaf_p4b_clone_i2i, leaf_p4b_digest, leaf_p4b_recirculate;
{
    leaf_p4b_checksum_error := false;
    leaf_p4b_checksum_updated := false;
    leaf_p4b_checksum_verified := false;
    leaf_p4b_digest := false;
    leaf_p4b_recirculate := false;
    leaf_p4b_clone_i2i := false;
    leaf_p4b_clone_e2e := false;
    leaf_p4b_clone_i2e := false;
    call leaf_main();
}

// leaf_Control leaf_netcacheComputeChecksum
procedure {:inline 1} leaf_netcacheComputeChecksum()
{
}

// leaf_Control leaf_netcacheEgress
procedure {:inline 1} leaf_netcacheEgress()
{
}
function {:inline true}leaf_netcacheEgress_cm3_reg.read(leaf_reg:[bv32]bv16, leaf_index:bv32)returns (bv16) {leaf_reg[leaf_index]}
procedure {:inline 1} leaf_netcacheEgress_cm3_reg.write(leaf_index:bv32, leaf_value:bv16)
	modifies leaf_netcacheEgress_cm3_reg, leaf_netcacheEgress_cm3_reg__last0_old_value, leaf_netcacheEgress_cm3_reg__last0_value, leaf_netcacheEgress_cm3_reg__last_index, leaf_netcacheEgress_cm3_reg__last_old_value, leaf_netcacheEgress_cm3_reg__last_value, leaf_netcacheEgress_cm3_reg__last_write_site, leaf_netcacheEgress_cm3_reg__wrote_any, leaf_netcacheEgress_cm3_reg__wrote_index0;
{
    leaf_netcacheEgress_cm3_reg__last_old_value := leaf_netcacheEgress_cm3_reg[leaf_index];
    leaf_netcacheEgress_cm3_reg[leaf_index] := leaf_value;
    leaf_netcacheEgress_cm3_reg__last_index := leaf_index;
    leaf_netcacheEgress_cm3_reg__last_value := leaf_value;
    leaf_netcacheEgress_cm3_reg__last_write_site := leaf_netcacheEgress_cm3_reg__next_write_site;
    leaf_netcacheEgress_cm3_reg__wrote_any := true;
    if (leaf_index == 0bv32) {
        leaf_netcacheEgress_cm3_reg__wrote_index0 := true;
        leaf_netcacheEgress_cm3_reg__last0_old_value := leaf_netcacheEgress_cm3_reg__last_old_value;
        leaf_netcacheEgress_cm3_reg__last0_value := leaf_value;
    }
}
function {:inline true}leaf_netcacheEgress_cm4_reg.read(leaf_reg:[bv32]bv16, leaf_index:bv32)returns (bv16) {leaf_reg[leaf_index]}
procedure {:inline 1} leaf_netcacheEgress_cm4_reg.write(leaf_index:bv32, leaf_value:bv16)
	modifies leaf_netcacheEgress_cm4_reg, leaf_netcacheEgress_cm4_reg__last0_old_value, leaf_netcacheEgress_cm4_reg__last0_value, leaf_netcacheEgress_cm4_reg__last_index, leaf_netcacheEgress_cm4_reg__last_old_value, leaf_netcacheEgress_cm4_reg__last_value, leaf_netcacheEgress_cm4_reg__last_write_site, leaf_netcacheEgress_cm4_reg__wrote_any, leaf_netcacheEgress_cm4_reg__wrote_index0;
{
    leaf_netcacheEgress_cm4_reg__last_old_value := leaf_netcacheEgress_cm4_reg[leaf_index];
    leaf_netcacheEgress_cm4_reg[leaf_index] := leaf_value;
    leaf_netcacheEgress_cm4_reg__last_index := leaf_index;
    leaf_netcacheEgress_cm4_reg__last_value := leaf_value;
    leaf_netcacheEgress_cm4_reg__last_write_site := leaf_netcacheEgress_cm4_reg__next_write_site;
    leaf_netcacheEgress_cm4_reg__wrote_any := true;
    if (leaf_index == 0bv32) {
        leaf_netcacheEgress_cm4_reg__wrote_index0 := true;
        leaf_netcacheEgress_cm4_reg__last0_old_value := leaf_netcacheEgress_cm4_reg__last_old_value;
        leaf_netcacheEgress_cm4_reg__last0_value := leaf_value;
    }
}

// leaf_Control leaf_netcacheIngress
procedure {:inline 1} leaf_netcacheIngress()
{
}

// leaf_Parser leaf_netcacheParser
procedure {:inline 1} leaf_netcacheParser()
	modifies leaf_drop, leaf_isValid;
{
    goto leaf_State$netcacheParser$start;

        leaf_State$netcacheParser$start:
    call leaf_packet_in.extract(leaf_hdr.ethernet_hdr);
    goto leaf_State$netcacheParser$start$parse_ipv4_2, leaf_State$netcacheParser$start$DEFAULT;
    
leaf_State$netcacheParser$start$parse_ipv4_2:
    assume (leaf_hdr.ethernet_hdr.etherType == 2048bv16);
    goto leaf_State$netcacheParser$parse_ipv4;

    leaf_State$netcacheParser$start$DEFAULT:
    assume(!(leaf_hdr.ethernet_hdr.etherType == 2048bv16));
    goto leaf_State$accept;

        leaf_State$netcacheParser$parse_ipv4:
    call leaf_packet_in.extract(leaf_hdr.ipv4_hdr);
    goto leaf_State$netcacheParser$parse_ipv4$parse_udp_dstport_2, leaf_State$netcacheParser$parse_ipv4$DEFAULT;
    
leaf_State$netcacheParser$parse_ipv4$parse_udp_dstport_2:
    assume (leaf_hdr.ipv4_hdr.protocol == 17bv8);
    goto leaf_State$netcacheParser$parse_udp_dstport;

    leaf_State$netcacheParser$parse_ipv4$DEFAULT:
    assume(!(leaf_hdr.ipv4_hdr.protocol == 17bv8));
    goto leaf_State$accept;

        leaf_State$netcacheParser$parse_udp_dstport:
    call leaf_packet_in.extract(leaf_hdr.udp_hdr);
    goto leaf_State$netcacheParser$parse_udp_dstport$parse_op_4, leaf_State$netcacheParser$parse_udp_dstport$parse_op_3, leaf_State$netcacheParser$parse_udp_dstport$parse_op_2, leaf_State$netcacheParser$parse_udp_dstport$DEFAULT;
    
leaf_State$netcacheParser$parse_udp_dstport$parse_op_4:
    assume (band.bv16(leaf_hdr.udp_hdr.dstPort, 65408bv16) == band.bv16(1152bv16, 65408bv16));
    goto leaf_State$netcacheParser$parse_op;
    
leaf_State$netcacheParser$parse_udp_dstport$parse_op_3:
    assume (band.bv16(leaf_hdr.udp_hdr.dstPort, 65408bv16) == band.bv16(4224bv16, 65408bv16));
    goto leaf_State$netcacheParser$parse_op;
    
leaf_State$netcacheParser$parse_udp_dstport$parse_op_2:
    assume (leaf_hdr.udp_hdr.dstPort == 5008bv16);
    goto leaf_State$netcacheParser$parse_op;

    leaf_State$netcacheParser$parse_udp_dstport$DEFAULT:
    assume(!(band.bv16(leaf_hdr.udp_hdr.dstPort, 65408bv16) == band.bv16(1152bv16, 65408bv16))&&!(band.bv16(leaf_hdr.udp_hdr.dstPort, 65408bv16) == band.bv16(4224bv16, 65408bv16))&&!(leaf_hdr.udp_hdr.dstPort == 5008bv16));
    goto leaf_State$netcacheParser$parse_udp_srcport;

        leaf_State$netcacheParser$parse_udp_srcport:
    goto leaf_State$netcacheParser$parse_udp_srcport$parse_op_4, leaf_State$netcacheParser$parse_udp_srcport$parse_op_3, leaf_State$netcacheParser$parse_udp_srcport$parse_op_2, leaf_State$netcacheParser$parse_udp_srcport$DEFAULT;
    
leaf_State$netcacheParser$parse_udp_srcport$parse_op_4:
    assume (band.bv16(leaf_hdr.udp_hdr.srcPort, 65408bv16) == band.bv16(1152bv16, 65408bv16));
    goto leaf_State$netcacheParser$parse_op;
    
leaf_State$netcacheParser$parse_udp_srcport$parse_op_3:
    assume (band.bv16(leaf_hdr.udp_hdr.srcPort, 65408bv16) == band.bv16(4224bv16, 65408bv16));
    goto leaf_State$netcacheParser$parse_op;
    
leaf_State$netcacheParser$parse_udp_srcport$parse_op_2:
    assume (leaf_hdr.udp_hdr.srcPort == 5009bv16);
    goto leaf_State$netcacheParser$parse_op;

    leaf_State$netcacheParser$parse_udp_srcport$DEFAULT:
    assume(!(band.bv16(leaf_hdr.udp_hdr.srcPort, 65408bv16) == band.bv16(1152bv16, 65408bv16))&&!(band.bv16(leaf_hdr.udp_hdr.srcPort, 65408bv16) == band.bv16(4224bv16, 65408bv16))&&!(leaf_hdr.udp_hdr.srcPort == 5009bv16));
    goto leaf_State$accept;

        leaf_State$netcacheParser$parse_op:
    call leaf_packet_in.extract(leaf_hdr.op_hdr);
    goto leaf_State$netcacheParser$parse_op$parse_clone_8, leaf_State$netcacheParser$parse_op$parse_frequency_7, leaf_State$netcacheParser$parse_op$parse_fraginfo_6, leaf_State$netcacheParser$parse_op$parse_vallen_5, leaf_State$netcacheParser$parse_op$parse_shadowtype_4, leaf_State$netcacheParser$parse_op$parse_shadowtype_3, leaf_State$netcacheParser$parse_op$parse_shadowtype_2, leaf_State$netcacheParser$parse_op$DEFAULT;
    
leaf_State$netcacheParser$parse_op$parse_clone_8:
    assume (leaf_hdr.op_hdr.optype == 288bv16);
    goto leaf_State$netcacheParser$parse_clone;
    
leaf_State$netcacheParser$parse_op$parse_frequency_7:
    assume (leaf_hdr.op_hdr.optype == 256bv16);
    goto leaf_State$netcacheParser$parse_frequency;
    
leaf_State$netcacheParser$parse_op$parse_fraginfo_6:
    assume (leaf_hdr.op_hdr.optype == 720bv16);
    goto leaf_State$netcacheParser$parse_fraginfo;
    
leaf_State$netcacheParser$parse_op$parse_vallen_5:
    assume (band.bv16(leaf_hdr.op_hdr.optype, 1bv16) == band.bv16(1bv16, 1bv16));
    goto leaf_State$netcacheParser$parse_vallen;
    
leaf_State$netcacheParser$parse_op$parse_shadowtype_4:
    assume (band.bv16(leaf_hdr.op_hdr.optype, 2bv16) == band.bv16(2bv16, 2bv16));
    goto leaf_State$netcacheParser$parse_shadowtype;
    
leaf_State$netcacheParser$parse_op$parse_shadowtype_3:
    assume (band.bv16(leaf_hdr.op_hdr.optype, 4bv16) == band.bv16(4bv16, 4bv16));
    goto leaf_State$netcacheParser$parse_shadowtype;
    
leaf_State$netcacheParser$parse_op$parse_shadowtype_2:
    assume (band.bv16(leaf_hdr.op_hdr.optype, 8bv16) == band.bv16(8bv16, 8bv16));
    goto leaf_State$netcacheParser$parse_shadowtype;

    leaf_State$netcacheParser$parse_op$DEFAULT:
    assume(!(leaf_hdr.op_hdr.optype == 288bv16)&&!(leaf_hdr.op_hdr.optype == 256bv16)&&!(leaf_hdr.op_hdr.optype == 720bv16)&&!(band.bv16(leaf_hdr.op_hdr.optype, 1bv16) == band.bv16(1bv16, 1bv16))&&!(band.bv16(leaf_hdr.op_hdr.optype, 2bv16) == band.bv16(2bv16, 2bv16))&&!(band.bv16(leaf_hdr.op_hdr.optype, 4bv16) == band.bv16(4bv16, 4bv16))&&!(band.bv16(leaf_hdr.op_hdr.optype, 8bv16) == band.bv16(8bv16, 8bv16)));
    goto leaf_State$accept;

        leaf_State$netcacheParser$parse_vallen:
    call leaf_packet_in.extract(leaf_hdr.vallen_hdr);
    goto leaf_State$netcacheParser$parse_vallen$parse_shadowtype_34, leaf_State$netcacheParser$parse_vallen$parse_val_len1_33, leaf_State$netcacheParser$parse_vallen$parse_val_len1_32, leaf_State$netcacheParser$parse_vallen$parse_val_len2_31, leaf_State$netcacheParser$parse_vallen$parse_val_len2_30, leaf_State$netcacheParser$parse_vallen$parse_val_len3_29, leaf_State$netcacheParser$parse_vallen$parse_val_len3_28, leaf_State$netcacheParser$parse_vallen$parse_val_len4_27, leaf_State$netcacheParser$parse_vallen$parse_val_len4_26, leaf_State$netcacheParser$parse_vallen$parse_val_len5_25, leaf_State$netcacheParser$parse_vallen$parse_val_len5_24, leaf_State$netcacheParser$parse_vallen$parse_val_len6_23, leaf_State$netcacheParser$parse_vallen$parse_val_len6_22, leaf_State$netcacheParser$parse_vallen$parse_val_len7_21, leaf_State$netcacheParser$parse_vallen$parse_val_len7_20, leaf_State$netcacheParser$parse_vallen$parse_val_len8_19, leaf_State$netcacheParser$parse_vallen$parse_val_len8_18, leaf_State$netcacheParser$parse_vallen$parse_val_len9_17, leaf_State$netcacheParser$parse_vallen$parse_val_len9_16, leaf_State$netcacheParser$parse_vallen$parse_val_len10_15, leaf_State$netcacheParser$parse_vallen$parse_val_len10_14, leaf_State$netcacheParser$parse_vallen$parse_val_len11_13, leaf_State$netcacheParser$parse_vallen$parse_val_len11_12, leaf_State$netcacheParser$parse_vallen$parse_val_len12_11, leaf_State$netcacheParser$parse_vallen$parse_val_len12_10, leaf_State$netcacheParser$parse_vallen$parse_val_len13_9, leaf_State$netcacheParser$parse_vallen$parse_val_len13_8, leaf_State$netcacheParser$parse_vallen$parse_val_len14_7, leaf_State$netcacheParser$parse_vallen$parse_val_len14_6, leaf_State$netcacheParser$parse_vallen$parse_val_len15_5, leaf_State$netcacheParser$parse_vallen$parse_val_len15_4, leaf_State$netcacheParser$parse_vallen$parse_val_len16_3, leaf_State$netcacheParser$parse_vallen$parse_val_len16_2, leaf_State$netcacheParser$parse_vallen$DEFAULT;
    
leaf_State$netcacheParser$parse_vallen$parse_shadowtype_34:
    assume (leaf_hdr.vallen_hdr.vallen == 0bv16);
    goto leaf_State$netcacheParser$parse_shadowtype;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len1_33:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(0bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len1;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len1_32:
    assume (leaf_hdr.vallen_hdr.vallen == 8bv16);
    goto leaf_State$netcacheParser$parse_val_len1;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len2_31:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(8bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len2;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len2_30:
    assume (leaf_hdr.vallen_hdr.vallen == 16bv16);
    goto leaf_State$netcacheParser$parse_val_len2;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len3_29:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(16bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len3;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len3_28:
    assume (leaf_hdr.vallen_hdr.vallen == 24bv16);
    goto leaf_State$netcacheParser$parse_val_len3;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len4_27:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(24bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len4;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len4_26:
    assume (leaf_hdr.vallen_hdr.vallen == 32bv16);
    goto leaf_State$netcacheParser$parse_val_len4;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len5_25:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(32bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len5;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len5_24:
    assume (leaf_hdr.vallen_hdr.vallen == 40bv16);
    goto leaf_State$netcacheParser$parse_val_len5;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len6_23:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(40bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len6;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len6_22:
    assume (leaf_hdr.vallen_hdr.vallen == 48bv16);
    goto leaf_State$netcacheParser$parse_val_len6;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len7_21:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(48bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len7;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len7_20:
    assume (leaf_hdr.vallen_hdr.vallen == 56bv16);
    goto leaf_State$netcacheParser$parse_val_len7;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len8_19:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(56bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len8;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len8_18:
    assume (leaf_hdr.vallen_hdr.vallen == 64bv16);
    goto leaf_State$netcacheParser$parse_val_len8;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len9_17:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(64bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len9;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len9_16:
    assume (leaf_hdr.vallen_hdr.vallen == 72bv16);
    goto leaf_State$netcacheParser$parse_val_len9;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len10_15:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(72bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len10;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len10_14:
    assume (leaf_hdr.vallen_hdr.vallen == 80bv16);
    goto leaf_State$netcacheParser$parse_val_len10;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len11_13:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(80bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len11;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len11_12:
    assume (leaf_hdr.vallen_hdr.vallen == 88bv16);
    goto leaf_State$netcacheParser$parse_val_len11;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len12_11:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(88bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len12;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len12_10:
    assume (leaf_hdr.vallen_hdr.vallen == 96bv16);
    goto leaf_State$netcacheParser$parse_val_len12;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len13_9:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(96bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len13;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len13_8:
    assume (leaf_hdr.vallen_hdr.vallen == 104bv16);
    goto leaf_State$netcacheParser$parse_val_len13;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len14_7:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(104bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len14;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len14_6:
    assume (leaf_hdr.vallen_hdr.vallen == 112bv16);
    goto leaf_State$netcacheParser$parse_val_len14;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len15_5:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(112bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len15;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len15_4:
    assume (leaf_hdr.vallen_hdr.vallen == 120bv16);
    goto leaf_State$netcacheParser$parse_val_len15;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len16_3:
    assume (band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(120bv16, 65528bv16));
    goto leaf_State$netcacheParser$parse_val_len16;
    
leaf_State$netcacheParser$parse_vallen$parse_val_len16_2:
    assume (leaf_hdr.vallen_hdr.vallen == 128bv16);
    goto leaf_State$netcacheParser$parse_val_len16;

    leaf_State$netcacheParser$parse_vallen$DEFAULT:
    assume(!(leaf_hdr.vallen_hdr.vallen == 0bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(0bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 8bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(8bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 16bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(16bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 24bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(24bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 32bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(32bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 40bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(40bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 48bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(48bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 56bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(56bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 64bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(64bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 72bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(72bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 80bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(80bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 88bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(88bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 96bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(96bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 104bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(104bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 112bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(112bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 120bv16)&&!(band.bv16(leaf_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(120bv16, 65528bv16))&&!(leaf_hdr.vallen_hdr.vallen == 128bv16));
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len1:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len2:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    call leaf_packet_in.extract(leaf_hdr.val2_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len3:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    call leaf_packet_in.extract(leaf_hdr.val2_hdr);
    call leaf_packet_in.extract(leaf_hdr.val3_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len4:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    call leaf_packet_in.extract(leaf_hdr.val2_hdr);
    call leaf_packet_in.extract(leaf_hdr.val3_hdr);
    call leaf_packet_in.extract(leaf_hdr.val4_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len5:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    call leaf_packet_in.extract(leaf_hdr.val2_hdr);
    call leaf_packet_in.extract(leaf_hdr.val3_hdr);
    call leaf_packet_in.extract(leaf_hdr.val4_hdr);
    call leaf_packet_in.extract(leaf_hdr.val5_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len6:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    call leaf_packet_in.extract(leaf_hdr.val2_hdr);
    call leaf_packet_in.extract(leaf_hdr.val3_hdr);
    call leaf_packet_in.extract(leaf_hdr.val4_hdr);
    call leaf_packet_in.extract(leaf_hdr.val5_hdr);
    call leaf_packet_in.extract(leaf_hdr.val6_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len7:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    call leaf_packet_in.extract(leaf_hdr.val2_hdr);
    call leaf_packet_in.extract(leaf_hdr.val3_hdr);
    call leaf_packet_in.extract(leaf_hdr.val4_hdr);
    call leaf_packet_in.extract(leaf_hdr.val5_hdr);
    call leaf_packet_in.extract(leaf_hdr.val6_hdr);
    call leaf_packet_in.extract(leaf_hdr.val7_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len8:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    call leaf_packet_in.extract(leaf_hdr.val2_hdr);
    call leaf_packet_in.extract(leaf_hdr.val3_hdr);
    call leaf_packet_in.extract(leaf_hdr.val4_hdr);
    call leaf_packet_in.extract(leaf_hdr.val5_hdr);
    call leaf_packet_in.extract(leaf_hdr.val6_hdr);
    call leaf_packet_in.extract(leaf_hdr.val7_hdr);
    call leaf_packet_in.extract(leaf_hdr.val8_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len9:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    call leaf_packet_in.extract(leaf_hdr.val2_hdr);
    call leaf_packet_in.extract(leaf_hdr.val3_hdr);
    call leaf_packet_in.extract(leaf_hdr.val4_hdr);
    call leaf_packet_in.extract(leaf_hdr.val5_hdr);
    call leaf_packet_in.extract(leaf_hdr.val6_hdr);
    call leaf_packet_in.extract(leaf_hdr.val7_hdr);
    call leaf_packet_in.extract(leaf_hdr.val8_hdr);
    call leaf_packet_in.extract(leaf_hdr.val9_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len10:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    call leaf_packet_in.extract(leaf_hdr.val2_hdr);
    call leaf_packet_in.extract(leaf_hdr.val3_hdr);
    call leaf_packet_in.extract(leaf_hdr.val4_hdr);
    call leaf_packet_in.extract(leaf_hdr.val5_hdr);
    call leaf_packet_in.extract(leaf_hdr.val6_hdr);
    call leaf_packet_in.extract(leaf_hdr.val7_hdr);
    call leaf_packet_in.extract(leaf_hdr.val8_hdr);
    call leaf_packet_in.extract(leaf_hdr.val9_hdr);
    call leaf_packet_in.extract(leaf_hdr.val10_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len11:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    call leaf_packet_in.extract(leaf_hdr.val2_hdr);
    call leaf_packet_in.extract(leaf_hdr.val3_hdr);
    call leaf_packet_in.extract(leaf_hdr.val4_hdr);
    call leaf_packet_in.extract(leaf_hdr.val5_hdr);
    call leaf_packet_in.extract(leaf_hdr.val6_hdr);
    call leaf_packet_in.extract(leaf_hdr.val7_hdr);
    call leaf_packet_in.extract(leaf_hdr.val8_hdr);
    call leaf_packet_in.extract(leaf_hdr.val9_hdr);
    call leaf_packet_in.extract(leaf_hdr.val10_hdr);
    call leaf_packet_in.extract(leaf_hdr.val11_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len12:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    call leaf_packet_in.extract(leaf_hdr.val2_hdr);
    call leaf_packet_in.extract(leaf_hdr.val3_hdr);
    call leaf_packet_in.extract(leaf_hdr.val4_hdr);
    call leaf_packet_in.extract(leaf_hdr.val5_hdr);
    call leaf_packet_in.extract(leaf_hdr.val6_hdr);
    call leaf_packet_in.extract(leaf_hdr.val7_hdr);
    call leaf_packet_in.extract(leaf_hdr.val8_hdr);
    call leaf_packet_in.extract(leaf_hdr.val9_hdr);
    call leaf_packet_in.extract(leaf_hdr.val10_hdr);
    call leaf_packet_in.extract(leaf_hdr.val11_hdr);
    call leaf_packet_in.extract(leaf_hdr.val12_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len13:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    call leaf_packet_in.extract(leaf_hdr.val2_hdr);
    call leaf_packet_in.extract(leaf_hdr.val3_hdr);
    call leaf_packet_in.extract(leaf_hdr.val4_hdr);
    call leaf_packet_in.extract(leaf_hdr.val5_hdr);
    call leaf_packet_in.extract(leaf_hdr.val6_hdr);
    call leaf_packet_in.extract(leaf_hdr.val7_hdr);
    call leaf_packet_in.extract(leaf_hdr.val8_hdr);
    call leaf_packet_in.extract(leaf_hdr.val9_hdr);
    call leaf_packet_in.extract(leaf_hdr.val10_hdr);
    call leaf_packet_in.extract(leaf_hdr.val11_hdr);
    call leaf_packet_in.extract(leaf_hdr.val12_hdr);
    call leaf_packet_in.extract(leaf_hdr.val13_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len14:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    call leaf_packet_in.extract(leaf_hdr.val2_hdr);
    call leaf_packet_in.extract(leaf_hdr.val3_hdr);
    call leaf_packet_in.extract(leaf_hdr.val4_hdr);
    call leaf_packet_in.extract(leaf_hdr.val5_hdr);
    call leaf_packet_in.extract(leaf_hdr.val6_hdr);
    call leaf_packet_in.extract(leaf_hdr.val7_hdr);
    call leaf_packet_in.extract(leaf_hdr.val8_hdr);
    call leaf_packet_in.extract(leaf_hdr.val9_hdr);
    call leaf_packet_in.extract(leaf_hdr.val10_hdr);
    call leaf_packet_in.extract(leaf_hdr.val11_hdr);
    call leaf_packet_in.extract(leaf_hdr.val12_hdr);
    call leaf_packet_in.extract(leaf_hdr.val13_hdr);
    call leaf_packet_in.extract(leaf_hdr.val14_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len15:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    call leaf_packet_in.extract(leaf_hdr.val2_hdr);
    call leaf_packet_in.extract(leaf_hdr.val3_hdr);
    call leaf_packet_in.extract(leaf_hdr.val4_hdr);
    call leaf_packet_in.extract(leaf_hdr.val5_hdr);
    call leaf_packet_in.extract(leaf_hdr.val6_hdr);
    call leaf_packet_in.extract(leaf_hdr.val7_hdr);
    call leaf_packet_in.extract(leaf_hdr.val8_hdr);
    call leaf_packet_in.extract(leaf_hdr.val9_hdr);
    call leaf_packet_in.extract(leaf_hdr.val10_hdr);
    call leaf_packet_in.extract(leaf_hdr.val11_hdr);
    call leaf_packet_in.extract(leaf_hdr.val12_hdr);
    call leaf_packet_in.extract(leaf_hdr.val13_hdr);
    call leaf_packet_in.extract(leaf_hdr.val14_hdr);
    call leaf_packet_in.extract(leaf_hdr.val15_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_val_len16:
    call leaf_packet_in.extract(leaf_hdr.val1_hdr);
    call leaf_packet_in.extract(leaf_hdr.val2_hdr);
    call leaf_packet_in.extract(leaf_hdr.val3_hdr);
    call leaf_packet_in.extract(leaf_hdr.val4_hdr);
    call leaf_packet_in.extract(leaf_hdr.val5_hdr);
    call leaf_packet_in.extract(leaf_hdr.val6_hdr);
    call leaf_packet_in.extract(leaf_hdr.val7_hdr);
    call leaf_packet_in.extract(leaf_hdr.val8_hdr);
    call leaf_packet_in.extract(leaf_hdr.val9_hdr);
    call leaf_packet_in.extract(leaf_hdr.val10_hdr);
    call leaf_packet_in.extract(leaf_hdr.val11_hdr);
    call leaf_packet_in.extract(leaf_hdr.val12_hdr);
    call leaf_packet_in.extract(leaf_hdr.val13_hdr);
    call leaf_packet_in.extract(leaf_hdr.val14_hdr);
    call leaf_packet_in.extract(leaf_hdr.val15_hdr);
    call leaf_packet_in.extract(leaf_hdr.val16_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype;

        leaf_State$netcacheParser$parse_shadowtype:
    call leaf_packet_in.extract(leaf_hdr.shadowtype_hdr);
    goto leaf_State$netcacheParser$parse_shadowtype$parse_seq_4, leaf_State$netcacheParser$parse_shadowtype$parse_inswitch_3, leaf_State$netcacheParser$parse_shadowtype$parse_stat_2, leaf_State$netcacheParser$parse_shadowtype$DEFAULT;
    
leaf_State$netcacheParser$parse_shadowtype$parse_seq_4:
    assume (band.bv16(leaf_hdr.shadowtype_hdr.shadowtype, 2bv16) == band.bv16(2bv16, 2bv16));
    goto leaf_State$netcacheParser$parse_seq;
    
leaf_State$netcacheParser$parse_shadowtype$parse_inswitch_3:
    assume (band.bv16(leaf_hdr.shadowtype_hdr.shadowtype, 4bv16) == band.bv16(4bv16, 4bv16));
    goto leaf_State$netcacheParser$parse_inswitch;
    
leaf_State$netcacheParser$parse_shadowtype$parse_stat_2:
    assume (band.bv16(leaf_hdr.shadowtype_hdr.shadowtype, 8bv16) == band.bv16(8bv16, 8bv16));
    goto leaf_State$netcacheParser$parse_stat;

    leaf_State$netcacheParser$parse_shadowtype$DEFAULT:
    assume(!(band.bv16(leaf_hdr.shadowtype_hdr.shadowtype, 2bv16) == band.bv16(2bv16, 2bv16))&&!(band.bv16(leaf_hdr.shadowtype_hdr.shadowtype, 4bv16) == band.bv16(4bv16, 4bv16))&&!(band.bv16(leaf_hdr.shadowtype_hdr.shadowtype, 8bv16) == band.bv16(8bv16, 8bv16)));
    goto leaf_State$accept;

        leaf_State$netcacheParser$parse_seq:
    call leaf_packet_in.extract(leaf_hdr.seq_hdr);
    goto leaf_State$netcacheParser$parse_seq$parse_fraginfo_6, leaf_State$netcacheParser$parse_seq$parse_fraginfo_5, leaf_State$netcacheParser$parse_seq$parse_fraginfo_4, leaf_State$netcacheParser$parse_seq$parse_inswitch_3, leaf_State$netcacheParser$parse_seq$parse_stat_2, leaf_State$netcacheParser$parse_seq$DEFAULT;
    
leaf_State$netcacheParser$parse_seq$parse_fraginfo_6:
    assume (leaf_hdr.shadowtype_hdr.shadowtype == 50bv16);
    goto leaf_State$netcacheParser$parse_fraginfo;
    
leaf_State$netcacheParser$parse_seq$parse_fraginfo_5:
    assume (leaf_hdr.shadowtype_hdr.shadowtype == 66bv16);
    goto leaf_State$netcacheParser$parse_fraginfo;
    
leaf_State$netcacheParser$parse_seq$parse_fraginfo_4:
    assume (leaf_hdr.shadowtype_hdr.shadowtype == 82bv16);
    goto leaf_State$netcacheParser$parse_fraginfo;
    
leaf_State$netcacheParser$parse_seq$parse_inswitch_3:
    assume (band.bv16(leaf_hdr.shadowtype_hdr.shadowtype, 4bv16) == band.bv16(4bv16, 4bv16));
    goto leaf_State$netcacheParser$parse_inswitch;
    
leaf_State$netcacheParser$parse_seq$parse_stat_2:
    assume (band.bv16(leaf_hdr.shadowtype_hdr.shadowtype, 8bv16) == band.bv16(8bv16, 8bv16));
    goto leaf_State$netcacheParser$parse_stat;

    leaf_State$netcacheParser$parse_seq$DEFAULT:
    assume(!(leaf_hdr.shadowtype_hdr.shadowtype == 50bv16)&&!(leaf_hdr.shadowtype_hdr.shadowtype == 66bv16)&&!(leaf_hdr.shadowtype_hdr.shadowtype == 82bv16)&&!(band.bv16(leaf_hdr.shadowtype_hdr.shadowtype, 4bv16) == band.bv16(4bv16, 4bv16))&&!(band.bv16(leaf_hdr.shadowtype_hdr.shadowtype, 8bv16) == band.bv16(8bv16, 8bv16)));
    goto leaf_State$accept;

        leaf_State$netcacheParser$parse_inswitch:
    call leaf_packet_in.extract(leaf_hdr.inswitch_hdr);
    goto leaf_State$netcacheParser$parse_inswitch$parse_clone_5, leaf_State$netcacheParser$parse_inswitch$parse_fraginfo_4, leaf_State$netcacheParser$parse_inswitch$parse_fraginfo_3, leaf_State$netcacheParser$parse_inswitch$parse_stat_2, leaf_State$netcacheParser$parse_inswitch$DEFAULT;
    
leaf_State$netcacheParser$parse_inswitch$parse_clone_5:
    assume (leaf_hdr.shadowtype_hdr.shadowtype == 116bv16);
    goto leaf_State$netcacheParser$parse_clone;
    
leaf_State$netcacheParser$parse_inswitch$parse_fraginfo_4:
    assume (leaf_hdr.shadowtype_hdr.shadowtype == 164bv16);
    goto leaf_State$netcacheParser$parse_fraginfo;
    
leaf_State$netcacheParser$parse_inswitch$parse_fraginfo_3:
    assume (leaf_hdr.shadowtype_hdr.shadowtype == 22bv16);
    goto leaf_State$netcacheParser$parse_fraginfo;
    
leaf_State$netcacheParser$parse_inswitch$parse_stat_2:
    assume (band.bv16(leaf_hdr.shadowtype_hdr.shadowtype, 8bv16) == band.bv16(8bv16, 8bv16));
    goto leaf_State$netcacheParser$parse_stat;

    leaf_State$netcacheParser$parse_inswitch$DEFAULT:
    assume(!(leaf_hdr.shadowtype_hdr.shadowtype == 116bv16)&&!(leaf_hdr.shadowtype_hdr.shadowtype == 164bv16)&&!(leaf_hdr.shadowtype_hdr.shadowtype == 22bv16)&&!(band.bv16(leaf_hdr.shadowtype_hdr.shadowtype, 8bv16) == band.bv16(8bv16, 8bv16)));
    goto leaf_State$accept;

        leaf_State$netcacheParser$parse_stat:
    call leaf_packet_in.extract(leaf_hdr.stat_hdr);
    goto leaf_State$netcacheParser$parse_stat$parse_clone_5, leaf_State$netcacheParser$parse_stat$parse_clone_4, leaf_State$netcacheParser$parse_stat$parse_clone_3, leaf_State$netcacheParser$parse_stat$parse_clone_2, leaf_State$netcacheParser$parse_stat$DEFAULT;
    
leaf_State$netcacheParser$parse_stat$parse_clone_5:
    assume (leaf_hdr.shadowtype_hdr.shadowtype == 47bv16);
    goto leaf_State$netcacheParser$parse_clone;
    
leaf_State$netcacheParser$parse_stat$parse_clone_4:
    assume (leaf_hdr.shadowtype_hdr.shadowtype == 63bv16);
    goto leaf_State$netcacheParser$parse_clone;
    
leaf_State$netcacheParser$parse_stat$parse_clone_3:
    assume (leaf_hdr.shadowtype_hdr.shadowtype == 79bv16);
    goto leaf_State$netcacheParser$parse_clone;
    
leaf_State$netcacheParser$parse_stat$parse_clone_2:
    assume (leaf_hdr.shadowtype_hdr.shadowtype == 95bv16);
    goto leaf_State$netcacheParser$parse_clone;

    leaf_State$netcacheParser$parse_stat$DEFAULT:
    assume(!(leaf_hdr.shadowtype_hdr.shadowtype == 47bv16)&&!(leaf_hdr.shadowtype_hdr.shadowtype == 63bv16)&&!(leaf_hdr.shadowtype_hdr.shadowtype == 79bv16)&&!(leaf_hdr.shadowtype_hdr.shadowtype == 95bv16));
    goto leaf_State$accept;

        leaf_State$netcacheParser$parse_clone:
    call leaf_packet_in.extract(leaf_hdr.clone_hdr);
    goto leaf_State$accept;

        leaf_State$netcacheParser$parse_frequency:
    call leaf_packet_in.extract(leaf_hdr.frequency_hdr);
    goto leaf_State$accept;

        leaf_State$netcacheParser$parse_fraginfo:
    call leaf_packet_in.extract(leaf_hdr.fraginfo_hdr);
    goto leaf_State$accept;

    leaf_State$accept:
    call leaf_accept();
    goto leaf_Exit;

    leaf_State$reject:
    call leaf_reject();
    goto leaf_Exit;

    leaf_Exit:
}

// leaf_Control leaf_netcacheVerifyChecksum
procedure {:inline 1} leaf_netcacheVerifyChecksum()
{
}
procedure leaf_packet_in.extract(leaf_header:leaf_Ref);
    ensures (leaf_isValid[leaf_header] == true);
	modifies leaf_isValid;
procedure leaf_reject();
    ensures leaf_drop==true;
	modifies leaf_drop;
// ===== END NODE leaf =====

// ===== BEGIN ENQUEUE PROCEDURES =====
// ===== END ENQUEUE PROCEDURES =====

// ===== BEGIN HARNESS =====
// Auto-generated by Procurator (DSL -> Boogie harness: sequential scheduler)
// Message abstraction: Bag(K=1) using inbox_count per node; single-slot mailbox for packet fields

var procurator_step: int;
var procurator_bad: bool;

var leaf_inbox_count: int;
var io_inbox_count: int;

var leaf_pkt_external: bool;
var io_pkt_external: bool;

// Host packet fields (mirrors connected node symbols)
var io_hdr.ethernet_hdr.etherType: bv16;
var io_hdr.ipv4_hdr.protocol: bv8;
var io_hdr.udp_hdr.srcPort: bv16;
var io_hdr.udp_hdr.dstPort: bv16;
var io_hdr.op_hdr.optype: bv16;
var io_hdr.vallen_hdr.vallen: bv16;
var io_hdr.shadowtype_hdr.shadowtype: bv16;
var io_meta.bypass_egress: bv1;
var io_hdr_eg.op_hdr.optype: bv16;
var io_hdr_eg.shadowtype_hdr.shadowtype: bv16;
var io_hdr_eg.inswitch_hdr.valid: bool;
var io_hdr_eg.inswitch_hdr.hot_threshold: bv16;
var io_hdr_eg.inswitch_hdr.hashval_for_cm3: bv16;
var io_hdr_eg.inswitch_hdr.hashval_for_cm4: bv16;

// Forwarding (derived from DSL topology)
procedure leaf_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (leaf_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure mainProcedure() returns()
  modifies io_hdr.ethernet_hdr.etherType, io_hdr.ipv4_hdr.protocol, io_hdr.op_hdr.optype, io_hdr.shadowtype_hdr.shadowtype, io_hdr.udp_hdr.dstPort, io_hdr.udp_hdr.srcPort, io_hdr.vallen_hdr.vallen, io_hdr_eg.inswitch_hdr.hashval_for_cm3, io_hdr_eg.inswitch_hdr.hashval_for_cm4, io_hdr_eg.inswitch_hdr.hot_threshold, io_hdr_eg.inswitch_hdr.valid, io_hdr_eg.op_hdr.optype, io_hdr_eg.shadowtype_hdr.shadowtype, io_inbox_count, io_meta.bypass_egress, io_pkt_external, leaf_drop, leaf_hdr.ethernet_hdr.etherType, leaf_hdr.ipv4_hdr.protocol, leaf_hdr.op_hdr.optype, leaf_hdr.shadowtype_hdr.shadowtype, leaf_hdr.udp_hdr.dstPort, leaf_hdr.udp_hdr.srcPort, leaf_hdr.vallen_hdr.vallen, leaf_hdr_eg.inswitch_hdr.hashval_for_cm3, leaf_hdr_eg.inswitch_hdr.hashval_for_cm4, leaf_hdr_eg.inswitch_hdr.hot_threshold, leaf_hdr_eg.inswitch_hdr.valid, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.shadowtype_hdr.shadowtype, leaf_inbox_count, leaf_isValid, leaf_meta.bypass_egress, leaf_netcacheEgress_cm3_reg__last0_old_value, leaf_netcacheEgress_cm3_reg__last0_value, leaf_netcacheEgress_cm3_reg__last_index, leaf_netcacheEgress_cm3_reg__last_old_value, leaf_netcacheEgress_cm3_reg__last_value, leaf_netcacheEgress_cm3_reg__last_write_site, leaf_netcacheEgress_cm3_reg__next_write_site, leaf_netcacheEgress_cm3_reg__wrote_any, leaf_netcacheEgress_cm3_reg__wrote_index0, leaf_netcacheEgress_cm4_reg__last0_old_value, leaf_netcacheEgress_cm4_reg__last0_value, leaf_netcacheEgress_cm4_reg__last_index, leaf_netcacheEgress_cm4_reg__last_old_value, leaf_netcacheEgress_cm4_reg__last_value, leaf_netcacheEgress_cm4_reg__last_write_site, leaf_netcacheEgress_cm4_reg__next_write_site, leaf_netcacheEgress_cm4_reg__wrote_any, leaf_netcacheEgress_cm4_reg__wrote_index0, leaf_p4b_checksum_error, leaf_p4b_checksum_updated, leaf_p4b_checksum_verified, leaf_p4b_clone_e2e, leaf_p4b_clone_i2e, leaf_p4b_clone_i2i, leaf_p4b_digest, leaf_p4b_recirculate, leaf_pkt_external, procurator_bad, procurator_step;
{
  // initialize inboxes
  leaf_inbox_count := 0;
  leaf_pkt_external := false;
  io_inbox_count := 0;
  io_pkt_external := false;
  // initialize P4B event flags (clone/recirculate)
  leaf_p4b_clone_i2e := false;
  leaf_p4b_clone_e2e := false;
  leaf_p4b_clone_i2i := false;
  leaf_p4b_recirculate := false;

  // initialize P4 registers (default 0)
  assume leaf_netcacheEgress_cm3_reg[0bv32] == 0bv16;
  assume leaf_netcacheEgress_cm4_reg[0bv32] == 0bv16;
  // initialize register write tracking (debug)
  leaf_netcacheEgress_cm3_reg__last_index := 0bv32;
  leaf_netcacheEgress_cm3_reg__last_value := 0bv16;
  leaf_netcacheEgress_cm3_reg__last_old_value := 0bv16;
  leaf_netcacheEgress_cm3_reg__wrote_any := false;
  leaf_netcacheEgress_cm3_reg__wrote_index0 := false;
  leaf_netcacheEgress_cm3_reg__next_write_site := 0;
  leaf_netcacheEgress_cm3_reg__last_write_site := 0;
  leaf_netcacheEgress_cm3_reg__last0_old_value := 0bv16;
  leaf_netcacheEgress_cm3_reg__last0_value := 0bv16;
  leaf_netcacheEgress_cm4_reg__last_index := 0bv32;
  leaf_netcacheEgress_cm4_reg__last_value := 0bv16;
  leaf_netcacheEgress_cm4_reg__last_old_value := 0bv16;
  leaf_netcacheEgress_cm4_reg__wrote_any := false;
  leaf_netcacheEgress_cm4_reg__wrote_index0 := false;
  leaf_netcacheEgress_cm4_reg__next_write_site := 0;
  leaf_netcacheEgress_cm4_reg__last_write_site := 0;
  leaf_netcacheEgress_cm4_reg__last0_old_value := 0bv16;
  leaf_netcacheEgress_cm4_reg__last0_value := 0bv16;

  procurator_step := 0;
  procurator_bad := false;
  // step 0: host_send -> io
  // inject packet into connected node (host -> node)
  if (leaf_inbox_count < 1) {
    assume leaf_inbox_count < 1;
    havoc io_hdr.ethernet_hdr.etherType;
    havoc io_hdr.ipv4_hdr.protocol;
    havoc io_hdr.udp_hdr.srcPort;
    havoc io_hdr.udp_hdr.dstPort;
    havoc io_hdr.op_hdr.optype;
    havoc io_hdr.vallen_hdr.vallen;
    havoc io_hdr.shadowtype_hdr.shadowtype;
    io_meta.bypass_egress := 0bv1;
    io_hdr_eg.inswitch_hdr.valid := true;
    io_hdr_eg.inswitch_hdr.hashval_for_cm3 := 0bv16;
    io_hdr_eg.inswitch_hdr.hashval_for_cm4 := 0bv16;
    io_hdr_eg.inswitch_hdr.hot_threshold := 1bv16;
    io_hdr_eg.op_hdr.optype := 4bv16;
    io_hdr_eg.shadowtype_hdr.shadowtype := 4bv16;
    leaf_hdr.ethernet_hdr.etherType := io_hdr.ethernet_hdr.etherType;
    leaf_hdr.ipv4_hdr.protocol := io_hdr.ipv4_hdr.protocol;
    leaf_hdr.udp_hdr.srcPort := io_hdr.udp_hdr.srcPort;
    leaf_hdr.udp_hdr.dstPort := io_hdr.udp_hdr.dstPort;
    leaf_hdr.op_hdr.optype := io_hdr.op_hdr.optype;
    leaf_hdr.vallen_hdr.vallen := io_hdr.vallen_hdr.vallen;
    leaf_hdr.shadowtype_hdr.shadowtype := io_hdr.shadowtype_hdr.shadowtype;
    leaf_meta.bypass_egress := io_meta.bypass_egress;
    leaf_hdr_eg.op_hdr.optype := io_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.shadowtype_hdr.shadowtype := io_hdr_eg.shadowtype_hdr.shadowtype;
    leaf_hdr_eg.inswitch_hdr.valid := io_hdr_eg.inswitch_hdr.valid;
    leaf_hdr_eg.inswitch_hdr.hot_threshold := io_hdr_eg.inswitch_hdr.hot_threshold;
    leaf_hdr_eg.inswitch_hdr.hashval_for_cm3 := io_hdr_eg.inswitch_hdr.hashval_for_cm3;
    leaf_hdr_eg.inswitch_hdr.hashval_for_cm4 := io_hdr_eg.inswitch_hdr.hashval_for_cm4;
    leaf_pkt_external := true;
    leaf_inbox_count := leaf_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 1: host_recv -> io
  procurator_step := procurator_step + 1;
  // step 2: node_pass -> leaf
  if (leaf_inbox_count > 0) {
  assume leaf_inbox_count > 0;
  leaf_inbox_count := leaf_inbox_count - 1;
  call leaf_mainProcedure();
  if (leaf_p4b_clone_i2e) {
    assume leaf_inbox_count < 1;
    leaf_pkt_external := false;
    leaf_inbox_count := leaf_inbox_count + 1;
  }
  leaf_p4b_clone_i2e := false;
  if (leaf_p4b_clone_e2e) {
    assume leaf_inbox_count < 1;
    leaf_pkt_external := false;
    leaf_inbox_count := leaf_inbox_count + 1;
  }
  leaf_p4b_clone_e2e := false;
  if (leaf_p4b_clone_i2i) {
    assume leaf_inbox_count < 1;
    leaf_pkt_external := false;
    leaf_inbox_count := leaf_inbox_count + 1;
  }
  leaf_p4b_clone_i2i := false;
  if (leaf_p4b_recirculate) {
    assume leaf_inbox_count < 1;
    leaf_pkt_external := false;
    leaf_inbox_count := leaf_inbox_count + 1;
  }
  leaf_p4b_recirculate := false;
  call leaf_Forward();
  // Global assertions (accumulated into procurator_bad)
  if (!((leaf_netcacheEgress_cm3_reg__wrote_any && leaf_netcacheEgress_cm4_reg__wrote_any))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  assert !procurator_bad;
}


procedure ULTIMATE.start() returns()
  modifies io_hdr.ethernet_hdr.etherType, io_hdr.ipv4_hdr.protocol, io_hdr.op_hdr.optype, io_hdr.shadowtype_hdr.shadowtype, io_hdr.udp_hdr.dstPort, io_hdr.udp_hdr.srcPort, io_hdr.vallen_hdr.vallen, io_hdr_eg.inswitch_hdr.hashval_for_cm3, io_hdr_eg.inswitch_hdr.hashval_for_cm4, io_hdr_eg.inswitch_hdr.hot_threshold, io_hdr_eg.inswitch_hdr.valid, io_hdr_eg.op_hdr.optype, io_hdr_eg.shadowtype_hdr.shadowtype, io_inbox_count, io_meta.bypass_egress, io_pkt_external, leaf_drop, leaf_hdr.ethernet_hdr.etherType, leaf_hdr.ipv4_hdr.protocol, leaf_hdr.op_hdr.optype, leaf_hdr.shadowtype_hdr.shadowtype, leaf_hdr.udp_hdr.dstPort, leaf_hdr.udp_hdr.srcPort, leaf_hdr.vallen_hdr.vallen, leaf_hdr_eg.inswitch_hdr.hashval_for_cm3, leaf_hdr_eg.inswitch_hdr.hashval_for_cm4, leaf_hdr_eg.inswitch_hdr.hot_threshold, leaf_hdr_eg.inswitch_hdr.valid, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.shadowtype_hdr.shadowtype, leaf_inbox_count, leaf_isValid, leaf_meta.bypass_egress, leaf_netcacheEgress_cm3_reg__last0_old_value, leaf_netcacheEgress_cm3_reg__last0_value, leaf_netcacheEgress_cm3_reg__last_index, leaf_netcacheEgress_cm3_reg__last_old_value, leaf_netcacheEgress_cm3_reg__last_value, leaf_netcacheEgress_cm3_reg__last_write_site, leaf_netcacheEgress_cm3_reg__next_write_site, leaf_netcacheEgress_cm3_reg__wrote_any, leaf_netcacheEgress_cm3_reg__wrote_index0, leaf_netcacheEgress_cm4_reg__last0_old_value, leaf_netcacheEgress_cm4_reg__last0_value, leaf_netcacheEgress_cm4_reg__last_index, leaf_netcacheEgress_cm4_reg__last_old_value, leaf_netcacheEgress_cm4_reg__last_value, leaf_netcacheEgress_cm4_reg__last_write_site, leaf_netcacheEgress_cm4_reg__next_write_site, leaf_netcacheEgress_cm4_reg__wrote_any, leaf_netcacheEgress_cm4_reg__wrote_index0, leaf_p4b_checksum_error, leaf_p4b_checksum_updated, leaf_p4b_checksum_verified, leaf_p4b_clone_e2e, leaf_p4b_clone_i2e, leaf_p4b_clone_i2i, leaf_p4b_digest, leaf_p4b_recirculate, leaf_pkt_external, procurator_bad, procurator_step;
{
  call mainProcedure();
}

// ===== END HARNESS =====
