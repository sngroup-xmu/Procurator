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
var leaf_meta.hashval_for_spine_partition:bv16;
var leaf_meta.cm1_predicate:bv4;
var leaf_meta.cm2_predicate:bv4;
var leaf_meta.cm3_predicate:bv4;
var leaf_meta.cm4_predicate:bv4;
var leaf_meta.is_hot:bv1;
var leaf_meta.is_report1:bv1;
var leaf_meta.is_report2:bv1;
var leaf_meta.is_report3:bv1;
var leaf_meta.is_report:bv1;
var leaf_meta.is_latest:bv1;
var leaf_meta.is_deleted:bv1;
var leaf_meta.is_lastclone_for_pktloss:bv1;
var leaf_meta.spine_sid:bv10;
var leaf_meta.bypass_egress:bv1;
var leaf_meta:leaf_metadata;
var leaf_standard_metadata:leaf_standard_metadata_t;

function {:builtin "bvand"} band.bv16(leaf_left:bv16, leaf_right:bv16) returns(bv16);
type leaf_egressSpec_t = bv9;
function leaf_hash_csum16$bv16$bv32$bv32$bv32$bv16$bv16$bv16(leaf_arg0:bv16, leaf_arg1:bv32, leaf_arg2:bv32, leaf_arg3:bv32, leaf_arg4:bv16, leaf_arg5:bv16, leaf_arg6:bv16) returns(bv16);

function {:builtin "bvuge"} buge.bv16(leaf_left:bv16, leaf_right:bv16) returns(bool);

function {:builtin "bvule"} bule.bv16(leaf_left:bv16, leaf_right:bv16) returns(bool);

// leaf_Table leaf_netcacheIngress_hash_for_partition_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheIngress_hash_for_partition_tbl.action;
const unique leaf_netcacheIngress_hash_for_partition_tbl.action.netcacheIngress_hash_for_partition : leaf_netcacheIngress_hash_for_partition_tbl.action;
const unique leaf_netcacheIngress_hash_for_partition_tbl.action.NoAction_3 : leaf_netcacheIngress_hash_for_partition_tbl.action;
var leaf_netcacheIngress_hash_for_partition_tbl.action_run : leaf_netcacheIngress_hash_for_partition_tbl.action;
var leaf_netcacheIngress_hash_for_partition_tbl.hit : bool;

// leaf_Table leaf_netcacheIngress_hash_spine_partition_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheIngress_hash_spine_partition_tbl.action;
var leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.spine_sid_1:bv10;
var leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.eport_5:leaf_egressSpec_t;
const unique leaf_netcacheIngress_hash_spine_partition_tbl.action.netcacheIngress_hash_spine_partition : leaf_netcacheIngress_hash_spine_partition_tbl.action;
const unique leaf_netcacheIngress_hash_spine_partition_tbl.action.NoAction_5 : leaf_netcacheIngress_hash_spine_partition_tbl.action;
var leaf_netcacheIngress_hash_spine_partition_tbl.action_run : leaf_netcacheIngress_hash_spine_partition_tbl.action;
var leaf_netcacheIngress_hash_spine_partition_tbl.hit : bool;
var leaf_hdr_eg:leaf_Ref;

// leaf_Header leaf_ethernet_t

// leaf_Header leaf_ipv4_t

// leaf_Header leaf_udp_t
var leaf_hdr_eg.udp_hdr:leaf_Ref;
var leaf_hdr_eg.udp_hdr.valid:bool;
var leaf_hdr_eg.udp_hdr.srcPort:bv16;
var leaf_hdr_eg.udp_hdr.dstPort:bv16;
var leaf_hdr_eg.udp_hdr.hdrlen:bv16;
var leaf_hdr_eg.udp_hdr.checksum:bv16;

// leaf_Header leaf_op_t
var leaf_hdr_eg.op_hdr:leaf_Ref;
var leaf_hdr_eg.op_hdr.valid:bool;
var leaf_hdr_eg.op_hdr.optype:bv16;
var leaf_hdr_eg.op_hdr.keylolo:bv32;
var leaf_hdr_eg.op_hdr.keylohi:bv32;
var leaf_hdr_eg.op_hdr.keyhilo:bv32;
var leaf_hdr_eg.op_hdr.keyhihilo:bv16;
var leaf_hdr_eg.op_hdr.keyhihihi:bv16;

// leaf_Header leaf_vallen_t
var leaf_hdr_eg.vallen_hdr:leaf_Ref;
var leaf_hdr_eg.vallen_hdr.valid:bool;
var leaf_hdr_eg.vallen_hdr.vallen:bv16;

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

// leaf_Header leaf_seq_t

// leaf_Header leaf_inswitch_t
var leaf_hdr_eg.inswitch_hdr:leaf_Ref;
var leaf_hdr_eg.inswitch_hdr.valid:bool;
var leaf_hdr_eg.inswitch_hdr.is_cached:bv1;
var leaf_hdr_eg.inswitch_hdr.is_sampled:bv1;
var leaf_hdr_eg.inswitch_hdr.client_sid:bv10;
var leaf_hdr_eg.inswitch_hdr.padding1:bv4;
var leaf_hdr_eg.inswitch_hdr.hot_threshold:bv16;
var leaf_hdr_eg.inswitch_hdr.hashval_for_cm1:bv16;
var leaf_hdr_eg.inswitch_hdr.hashval_for_cm2:bv16;
var leaf_hdr_eg.inswitch_hdr.hashval_for_cm3:bv16;
var leaf_hdr_eg.inswitch_hdr.hashval_for_cm4:bv16;
var leaf_hdr_eg.inswitch_hdr.hashval_for_bf1:bv18;
var leaf_hdr_eg.inswitch_hdr.padding2:bv14;
var leaf_hdr_eg.inswitch_hdr.hashval_for_bf2:bv18;
var leaf_hdr_eg.inswitch_hdr.padding3:bv14;
var leaf_hdr_eg.inswitch_hdr.hashval_for_bf3:bv18;
var leaf_hdr_eg.inswitch_hdr.padding4:bv14;
var leaf_hdr_eg.inswitch_hdr.hashval_for_seq:bv16;
var leaf_hdr_eg.inswitch_hdr.idx:bv16;

// leaf_Header leaf_stat_t
var leaf_hdr_eg.stat_hdr:leaf_Ref;
var leaf_hdr_eg.stat_hdr.valid:bool;
var leaf_hdr_eg.stat_hdr.stat:bv8;
var leaf_hdr_eg.stat_hdr.nodeidx_foreval:bv16;
var leaf_hdr_eg.stat_hdr.padding:bv8;

// leaf_Header leaf_clone_t
var leaf_hdr_eg.clone_hdr:leaf_Ref;
var leaf_hdr_eg.clone_hdr.valid:bool;
var leaf_hdr_eg.clone_hdr.clonenum_for_pktloss:bv16;
var leaf_hdr_eg.clone_hdr.client_udpport:bv16;
var leaf_hdr_eg.clone_hdr.server_sid:bv10;
var leaf_hdr_eg.clone_hdr.padding:bv6;
var leaf_hdr_eg.clone_hdr.server_udpport:bv16;

// leaf_Header leaf_frequency_t

// leaf_Header leaf_fraginfo_t
var leaf_hdr_eg.fraginfo_hdr:leaf_Ref;
var leaf_hdr_eg.fraginfo_hdr.valid:bool;
var leaf_hdr_eg.fraginfo_hdr.padding1:bv16;
var leaf_hdr_eg.fraginfo_hdr.padding2:bv32;
var leaf_hdr_eg.fraginfo_hdr.cur_fragidx:bv16;
var leaf_hdr_eg.fraginfo_hdr.max_fragnum:bv16;
var leaf_cm1_res_0:bv16;
var leaf_cm2_res_0:bv16;
var leaf_cm3_res_0:bv16;
var leaf_cm4_res_0:bv16;

// leaf_Register leaf_netcacheEgress_cm1_reg
var leaf_netcacheEgress_cm1_reg:[bv32]bv16;
var leaf_netcacheEgress_cm1_reg__last_index:bv32;
var leaf_netcacheEgress_cm1_reg__last_value:bv16;
var leaf_netcacheEgress_cm1_reg__last_old_value:bv16;
var leaf_netcacheEgress_cm1_reg__wrote_any:bool;
var leaf_netcacheEgress_cm1_reg__wrote_index0:bool;
var leaf_netcacheEgress_cm1_reg__last0_old_value:bv16;
var leaf_netcacheEgress_cm1_reg__last0_value:bv16;
var leaf_netcacheEgress_cm1_reg__next_write_site:int;
var leaf_netcacheEgress_cm1_reg__last_write_site:int;
const leaf_netcacheEgress_cm1_reg.size:bv32;
axiom leaf_netcacheEgress_cm1_reg.size == 65536bv32;

// leaf_Register leaf_netcacheEgress_cm2_reg
var leaf_netcacheEgress_cm2_reg:[bv32]bv16;
var leaf_netcacheEgress_cm2_reg__last_index:bv32;
var leaf_netcacheEgress_cm2_reg__last_value:bv16;
var leaf_netcacheEgress_cm2_reg__last_old_value:bv16;
var leaf_netcacheEgress_cm2_reg__wrote_any:bool;
var leaf_netcacheEgress_cm2_reg__wrote_index0:bool;
var leaf_netcacheEgress_cm2_reg__last0_old_value:bv16;
var leaf_netcacheEgress_cm2_reg__last0_value:bv16;
var leaf_netcacheEgress_cm2_reg__next_write_site:int;
var leaf_netcacheEgress_cm2_reg__last_write_site:int;
const leaf_netcacheEgress_cm2_reg.size:bv32;
axiom leaf_netcacheEgress_cm2_reg.size == 65536bv32;

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

function {:builtin "bvadd"} add.bv16(leaf_left:bv16, leaf_right:bv16) returns(bv16);

// leaf_Table leaf_netcacheEgress_access_cm1_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_access_cm1_tbl.action;
const unique leaf_netcacheEgress_access_cm1_tbl.action.netcacheEgress_update_cm1 : leaf_netcacheEgress_access_cm1_tbl.action;
const unique leaf_netcacheEgress_access_cm1_tbl.action.netcacheEgress_initialize_cm1_predicate : leaf_netcacheEgress_access_cm1_tbl.action;
var leaf_netcacheEgress_access_cm1_tbl.action_run : leaf_netcacheEgress_access_cm1_tbl.action;
var leaf_netcacheEgress_access_cm1_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_access_cm2_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_access_cm2_tbl.action;
const unique leaf_netcacheEgress_access_cm2_tbl.action.netcacheEgress_update_cm2 : leaf_netcacheEgress_access_cm2_tbl.action;
const unique leaf_netcacheEgress_access_cm2_tbl.action.netcacheEgress_initialize_cm2_predicate : leaf_netcacheEgress_access_cm2_tbl.action;
var leaf_netcacheEgress_access_cm2_tbl.action_run : leaf_netcacheEgress_access_cm2_tbl.action;
var leaf_netcacheEgress_access_cm2_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_access_cm3_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_access_cm3_tbl.action;
const unique leaf_netcacheEgress_access_cm3_tbl.action.netcacheEgress_update_cm3 : leaf_netcacheEgress_access_cm3_tbl.action;
const unique leaf_netcacheEgress_access_cm3_tbl.action.netcacheEgress_initialize_cm3_predicate : leaf_netcacheEgress_access_cm3_tbl.action;
var leaf_netcacheEgress_access_cm3_tbl.action_run : leaf_netcacheEgress_access_cm3_tbl.action;
var leaf_netcacheEgress_access_cm3_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_access_cm4_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_access_cm4_tbl.action;
const unique leaf_netcacheEgress_access_cm4_tbl.action.netcacheEgress_update_cm4 : leaf_netcacheEgress_access_cm4_tbl.action;
const unique leaf_netcacheEgress_access_cm4_tbl.action.netcacheEgress_initialize_cm4_predicate : leaf_netcacheEgress_access_cm4_tbl.action;
var leaf_netcacheEgress_access_cm4_tbl.action_run : leaf_netcacheEgress_access_cm4_tbl.action;
var leaf_netcacheEgress_access_cm4_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_access_bf1_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_access_bf1_tbl.action;
const unique leaf_netcacheEgress_access_bf1_tbl.action.netcacheEgress_update_bf1 : leaf_netcacheEgress_access_bf1_tbl.action;
const unique leaf_netcacheEgress_access_bf1_tbl.action.netcacheEgress_reset_is_report1 : leaf_netcacheEgress_access_bf1_tbl.action;
var leaf_netcacheEgress_access_bf1_tbl.action_run : leaf_netcacheEgress_access_bf1_tbl.action;
var leaf_netcacheEgress_access_bf1_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_access_bf2_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_access_bf2_tbl.action;
const unique leaf_netcacheEgress_access_bf2_tbl.action.netcacheEgress_update_bf2 : leaf_netcacheEgress_access_bf2_tbl.action;
const unique leaf_netcacheEgress_access_bf2_tbl.action.netcacheEgress_reset_is_report2 : leaf_netcacheEgress_access_bf2_tbl.action;
var leaf_netcacheEgress_access_bf2_tbl.action_run : leaf_netcacheEgress_access_bf2_tbl.action;
var leaf_netcacheEgress_access_bf2_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_access_bf3_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_access_bf3_tbl.action;
const unique leaf_netcacheEgress_access_bf3_tbl.action.netcacheEgress_update_bf3 : leaf_netcacheEgress_access_bf3_tbl.action;
const unique leaf_netcacheEgress_access_bf3_tbl.action.netcacheEgress_reset_is_report3 : leaf_netcacheEgress_access_bf3_tbl.action;
var leaf_netcacheEgress_access_bf3_tbl.action_run : leaf_netcacheEgress_access_bf3_tbl.action;
var leaf_netcacheEgress_access_bf3_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_access_cache_frequency_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_access_cache_frequency_tbl.action;
const unique leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_get_cache_frequency : leaf_netcacheEgress_access_cache_frequency_tbl.action;
const unique leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_update_cache_frequency : leaf_netcacheEgress_access_cache_frequency_tbl.action;
const unique leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency : leaf_netcacheEgress_access_cache_frequency_tbl.action;
const unique leaf_netcacheEgress_access_cache_frequency_tbl.action.NoAction_11 : leaf_netcacheEgress_access_cache_frequency_tbl.action;
var leaf_netcacheEgress_access_cache_frequency_tbl.action_run : leaf_netcacheEgress_access_cache_frequency_tbl.action;
var leaf_netcacheEgress_access_cache_frequency_tbl.hit : bool;

// leaf_Register leaf_netcacheEgress_latest_reg
var leaf_netcacheEgress_latest_reg:[bv32]bv1;
var leaf_netcacheEgress_latest_reg__last_index:bv32;
var leaf_netcacheEgress_latest_reg__last_value:bv1;
var leaf_netcacheEgress_latest_reg__last_old_value:bv1;
var leaf_netcacheEgress_latest_reg__wrote_any:bool;
var leaf_netcacheEgress_latest_reg__wrote_index0:bool;
var leaf_netcacheEgress_latest_reg__last0_old_value:bv1;
var leaf_netcacheEgress_latest_reg__last0_value:bv1;
var leaf_netcacheEgress_latest_reg__next_write_site:int;
var leaf_netcacheEgress_latest_reg__last_write_site:int;
const leaf_netcacheEgress_latest_reg.size:bv32;
axiom leaf_netcacheEgress_latest_reg.size == 32768bv32;

// leaf_Table leaf_netcacheEgress_access_latest_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_access_latest_tbl.action;
const unique leaf_netcacheEgress_access_latest_tbl.action.netcacheEgress_get_latest : leaf_netcacheEgress_access_latest_tbl.action;
const unique leaf_netcacheEgress_access_latest_tbl.action.netcacheEgress_set_and_get_latest : leaf_netcacheEgress_access_latest_tbl.action;
const unique leaf_netcacheEgress_access_latest_tbl.action.netcacheEgress_reset_and_get_latest : leaf_netcacheEgress_access_latest_tbl.action;
const unique leaf_netcacheEgress_access_latest_tbl.action.netcacheEgress_reset_is_latest : leaf_netcacheEgress_access_latest_tbl.action;
var leaf_netcacheEgress_access_latest_tbl.action_run : leaf_netcacheEgress_access_latest_tbl.action;
var leaf_netcacheEgress_access_latest_tbl.hit : bool;

// leaf_Register leaf_netcacheEgress_deleted_reg
var leaf_netcacheEgress_deleted_reg:[bv32]bv1;
var leaf_netcacheEgress_deleted_reg__last_index:bv32;
var leaf_netcacheEgress_deleted_reg__last_value:bv1;
var leaf_netcacheEgress_deleted_reg__last_old_value:bv1;
var leaf_netcacheEgress_deleted_reg__wrote_any:bool;
var leaf_netcacheEgress_deleted_reg__wrote_index0:bool;
var leaf_netcacheEgress_deleted_reg__last0_old_value:bv1;
var leaf_netcacheEgress_deleted_reg__last0_value:bv1;
var leaf_netcacheEgress_deleted_reg__next_write_site:int;
var leaf_netcacheEgress_deleted_reg__last_write_site:int;
const leaf_netcacheEgress_deleted_reg.size:bv32;
axiom leaf_netcacheEgress_deleted_reg.size == 32768bv32;

// leaf_Table leaf_netcacheEgress_access_deleted_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_access_deleted_tbl.action;
const unique leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_get_deleted : leaf_netcacheEgress_access_deleted_tbl.action;
const unique leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_set_and_get_deleted : leaf_netcacheEgress_access_deleted_tbl.action;
const unique leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_reset_and_get_deleted : leaf_netcacheEgress_access_deleted_tbl.action;
const unique leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_reset_is_deleted : leaf_netcacheEgress_access_deleted_tbl.action;
var leaf_netcacheEgress_access_deleted_tbl.action_run : leaf_netcacheEgress_access_deleted_tbl.action;
var leaf_netcacheEgress_access_deleted_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_access_seq_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_access_seq_tbl.action;
const unique leaf_netcacheEgress_access_seq_tbl.action.netcacheEgress_assign_seq : leaf_netcacheEgress_access_seq_tbl.action;
const unique leaf_netcacheEgress_access_seq_tbl.action.NoAction_12 : leaf_netcacheEgress_access_seq_tbl.action;
var leaf_netcacheEgress_access_seq_tbl.action_run : leaf_netcacheEgress_access_seq_tbl.action;
var leaf_netcacheEgress_access_seq_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_access_savedseq_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_access_savedseq_tbl.action;
const unique leaf_netcacheEgress_access_savedseq_tbl.action.netcacheEgress_get_savedseq : leaf_netcacheEgress_access_savedseq_tbl.action;
const unique leaf_netcacheEgress_access_savedseq_tbl.action.netcacheEgress_set_and_get_savedseq : leaf_netcacheEgress_access_savedseq_tbl.action;
const unique leaf_netcacheEgress_access_savedseq_tbl.action.NoAction_13 : leaf_netcacheEgress_access_savedseq_tbl.action;
var leaf_netcacheEgress_access_savedseq_tbl.action_run : leaf_netcacheEgress_access_savedseq_tbl.action;
var leaf_netcacheEgress_access_savedseq_tbl.hit : bool;

// leaf_Register leaf_netcacheEgress_vallen_reg
var leaf_netcacheEgress_vallen_reg:[bv32]bv16;
var leaf_netcacheEgress_vallen_reg__last_index:bv32;
var leaf_netcacheEgress_vallen_reg__last_value:bv16;
var leaf_netcacheEgress_vallen_reg__last_old_value:bv16;
var leaf_netcacheEgress_vallen_reg__wrote_any:bool;
var leaf_netcacheEgress_vallen_reg__wrote_index0:bool;
var leaf_netcacheEgress_vallen_reg__last0_old_value:bv16;
var leaf_netcacheEgress_vallen_reg__last0_value:bv16;
var leaf_netcacheEgress_vallen_reg__next_write_site:int;
var leaf_netcacheEgress_vallen_reg__last_write_site:int;
const leaf_netcacheEgress_vallen_reg.size:bv32;
axiom leaf_netcacheEgress_vallen_reg.size == 32768bv32;

// leaf_Table leaf_netcacheEgress_update_vallen_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_update_vallen_tbl.action;
const unique leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_get_vallen : leaf_netcacheEgress_update_vallen_tbl.action;
const unique leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_set_and_get_vallen : leaf_netcacheEgress_update_vallen_tbl.action;
const unique leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_reset_and_get_vallen : leaf_netcacheEgress_update_vallen_tbl.action;
const unique leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_reset_access_val_mode : leaf_netcacheEgress_update_vallen_tbl.action;
const unique leaf_netcacheEgress_update_vallen_tbl.action.NoAction_14 : leaf_netcacheEgress_update_vallen_tbl.action;
var leaf_netcacheEgress_update_vallen_tbl.action_run : leaf_netcacheEgress_update_vallen_tbl.action;
var leaf_netcacheEgress_update_vallen_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_bypass_egress_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_bypass_egress_tbl.action;
const unique leaf_netcacheEgress_bypass_egress_tbl.action.netcacheEgress_set_bypass_egress : leaf_netcacheEgress_bypass_egress_tbl.action;
const unique leaf_netcacheEgress_bypass_egress_tbl.action.NoAction_47 : leaf_netcacheEgress_bypass_egress_tbl.action;
var leaf_netcacheEgress_bypass_egress_tbl.action_run : leaf_netcacheEgress_bypass_egress_tbl.action;
var leaf_netcacheEgress_bypass_egress_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_save_client_udpport_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_save_client_udpport_tbl.action;
const unique leaf_netcacheEgress_save_client_udpport_tbl.action.netcacheEgress_save_client_udpport : leaf_netcacheEgress_save_client_udpport_tbl.action;
const unique leaf_netcacheEgress_save_client_udpport_tbl.action.NoAction_48 : leaf_netcacheEgress_save_client_udpport_tbl.action;
var leaf_netcacheEgress_save_client_udpport_tbl.action_run : leaf_netcacheEgress_save_client_udpport_tbl.action;
var leaf_netcacheEgress_save_client_udpport_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_prepare_for_cachepop_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_prepare_for_cachepop_tbl.action;
var leaf_netcacheEgress_prepare_for_cachepop_tbl.netcacheEgress_set_server_sid_and_port.server_sid_2:bv10;
const unique leaf_netcacheEgress_prepare_for_cachepop_tbl.action.netcacheEgress_set_server_sid_and_port : leaf_netcacheEgress_prepare_for_cachepop_tbl.action;
const unique leaf_netcacheEgress_prepare_for_cachepop_tbl.action.netcacheEgress_reset_server_sid : leaf_netcacheEgress_prepare_for_cachepop_tbl.action;
const unique leaf_netcacheEgress_prepare_for_cachepop_tbl.action.NoAction_49 : leaf_netcacheEgress_prepare_for_cachepop_tbl.action;
var leaf_netcacheEgress_prepare_for_cachepop_tbl.action_run : leaf_netcacheEgress_prepare_for_cachepop_tbl.action;
var leaf_netcacheEgress_prepare_for_cachepop_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_is_hot_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_is_hot_tbl.action;
const unique leaf_netcacheEgress_is_hot_tbl.action.netcacheEgress_set_is_hot : leaf_netcacheEgress_is_hot_tbl.action;
const unique leaf_netcacheEgress_is_hot_tbl.action.netcacheEgress_reset_is_hot : leaf_netcacheEgress_is_hot_tbl.action;
var leaf_netcacheEgress_is_hot_tbl.action_run : leaf_netcacheEgress_is_hot_tbl.action;
var leaf_netcacheEgress_is_hot_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_is_report_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_is_report_tbl.action;
const unique leaf_netcacheEgress_is_report_tbl.action.netcacheEgress_set_is_report : leaf_netcacheEgress_is_report_tbl.action;
const unique leaf_netcacheEgress_is_report_tbl.action.netcacheEgress_reset_is_report : leaf_netcacheEgress_is_report_tbl.action;
var leaf_netcacheEgress_is_report_tbl.action_run : leaf_netcacheEgress_is_report_tbl.action;
var leaf_netcacheEgress_is_report_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_lastclone_lastscansplit_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_lastclone_lastscansplit_tbl.action;
const unique leaf_netcacheEgress_lastclone_lastscansplit_tbl.action.netcacheEgress_set_is_lastclone : leaf_netcacheEgress_lastclone_lastscansplit_tbl.action;
const unique leaf_netcacheEgress_lastclone_lastscansplit_tbl.action.netcacheEgress_reset_is_lastclone_lastscansplit : leaf_netcacheEgress_lastclone_lastscansplit_tbl.action;
var leaf_netcacheEgress_lastclone_lastscansplit_tbl.action_run : leaf_netcacheEgress_lastclone_lastscansplit_tbl.action;
var leaf_netcacheEgress_lastclone_lastscansplit_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_eg_port_forward_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_eg_port_forward_tbl.action;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid:bv10;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.reflector_port:bv16;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid_7:bv10;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.client_sid_4:bv10;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.server_port:bv16;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8:bv10;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5:bv16;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_9:bv10;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_getreq_pop_to_getreq_by_mirroring.server_sid_3:bv10;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5:bv10;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3:bv16;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1:bv8;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_10:bv10;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_6:bv16;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.switchos_sid_11:bv10;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.reflector_port_7:bv16;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_12:bv10;
var leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_8:bv16;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_forward_netcache_getreq_pop_clone_for_pktloss_and_getreq : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_getreq_pop_to_getreq_by_mirroring : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_putreq_inswitch_to_putreq_seq : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_putreq_inswitch_to_netcache_putreq_seq_cached : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_delreq_inswitch_to_delreq_seq : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_delreq_inswitch_to_netcache_delreq_seq_cached : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_putreq_largevalue_inswitch_to_putreq_largevalue_seq : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_putreq_largevalue_inswitch_to_putreq_largevalue_seq_cached : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone : leaf_netcacheEgress_eg_port_forward_tbl.action;
const unique leaf_netcacheEgress_eg_port_forward_tbl.action.NoAction_50 : leaf_netcacheEgress_eg_port_forward_tbl.action;
var leaf_netcacheEgress_eg_port_forward_tbl.action_run : leaf_netcacheEgress_eg_port_forward_tbl.action;
var leaf_netcacheEgress_eg_port_forward_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_update_ipmac_srcport_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_update_ipmac_srcport_tbl.action;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_mac:bv48;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_mac:bv48;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_ip:bv32;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_ip:bv32;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_port_4:bv16;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_mac_3:bv48;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_mac:bv48;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_ip_3:bv32;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_ip:bv32;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_port:bv16;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_mac_2:bv48;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_ip_2:bv32;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3:bv48;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3:bv32;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_mac_4:bv48;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_mac_4:bv48;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_ip_4:bv32;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_ip_4:bv32;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_port_2:bv16;
const unique leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_ipmac_srcport_server2client : leaf_netcacheEgress_update_ipmac_srcport_tbl.action;
const unique leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_ipmac_srcport_switch2switchos : leaf_netcacheEgress_update_ipmac_srcport_tbl.action;
const unique leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_dstipmac_switch2switchos : leaf_netcacheEgress_update_ipmac_srcport_tbl.action;
const unique leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_dstipmac_client2server : leaf_netcacheEgress_update_ipmac_srcport_tbl.action;
const unique leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_ipmac_srcport_client2server : leaf_netcacheEgress_update_ipmac_srcport_tbl.action;
const unique leaf_netcacheEgress_update_ipmac_srcport_tbl.action.NoAction_51 : leaf_netcacheEgress_update_ipmac_srcport_tbl.action;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run : leaf_netcacheEgress_update_ipmac_srcport_tbl.action;
var leaf_netcacheEgress_update_ipmac_srcport_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_update_pktlen_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_update_pktlen_tbl.action;
var leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen:bv16;
var leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen:bv16;
var leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.udplen_delta:bv16;
var leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.iplen_delta:bv16;
const unique leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen : leaf_netcacheEgress_update_pktlen_tbl.action;
const unique leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_add_pktlen : leaf_netcacheEgress_update_pktlen_tbl.action;
const unique leaf_netcacheEgress_update_pktlen_tbl.action.NoAction_52 : leaf_netcacheEgress_update_pktlen_tbl.action;
var leaf_netcacheEgress_update_pktlen_tbl.action_run : leaf_netcacheEgress_update_pktlen_tbl.action;
var leaf_netcacheEgress_update_pktlen_tbl.hit : bool;

// leaf_Table leaf_netcacheEgress_add_and_remove_value_header_tbl leaf_Actionlist leaf_Declaration
type leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_only_vallen : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val1 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val2 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val3 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val4 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val5 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val6 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val7 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val8 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val9 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val10 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val11 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val12 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val13 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val14 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val15 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val16 : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
const unique leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_remove_all : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
var leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run : leaf_netcacheEgress_add_and_remove_value_header_tbl.action;
var leaf_netcacheEgress_add_and_remove_value_header_tbl.hit : bool;

function {:builtin "bvsub"} sub.bv17(leaf_left:bv17, leaf_right:bv17) returns(bv17);

function {:builtin "bvsub"} sub.bv33(leaf_left:bv33, leaf_right:bv33) returns(bv33);

// leaf_Action leaf_NoAction_11
procedure {:inline 1} leaf_NoAction_11()
{
}

// leaf_Action leaf_NoAction_12
procedure {:inline 1} leaf_NoAction_12()
{
}

// leaf_Action leaf_NoAction_13
procedure {:inline 1} leaf_NoAction_13()
{
}

// leaf_Action leaf_NoAction_3
procedure {:inline 1} leaf_NoAction_3()
{
}

// leaf_Action leaf_NoAction_47
procedure {:inline 1} leaf_NoAction_47()
{
}

// leaf_Action leaf_NoAction_48
procedure {:inline 1} leaf_NoAction_48()
{
}

// leaf_Action leaf_NoAction_49
procedure {:inline 1} leaf_NoAction_49()
{
}

// leaf_Action leaf_NoAction_5
procedure {:inline 1} leaf_NoAction_5()
{
}

// leaf_Action leaf_NoAction_50
procedure {:inline 1} leaf_NoAction_50()
{
}

// leaf_Action leaf_NoAction_51
procedure {:inline 1} leaf_NoAction_51()
{
}

// leaf_Action leaf_NoAction_52
procedure {:inline 1} leaf_NoAction_52()
{
}
procedure {:inline 1} leaf_accept()
{
}
procedure {:inline 1} leaf_main()
	modifies leaf_cm1_res_0, leaf_cm2_res_0, leaf_cm3_res_0, leaf_cm4_res_0, leaf_drop, leaf_hdr.op_hdr.optype, leaf_hdr_eg.clone_hdr.client_udpport, leaf_hdr_eg.clone_hdr.clonenum_for_pktloss, leaf_hdr_eg.clone_hdr.server_sid, leaf_hdr_eg.clone_hdr.server_udpport, leaf_hdr_eg.fraginfo_hdr.cur_fragidx, leaf_hdr_eg.inswitch_hdr.client_sid, leaf_hdr_eg.inswitch_hdr.is_cached, leaf_hdr_eg.inswitch_hdr.is_sampled, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.stat_hdr.nodeidx_foreval, leaf_hdr_eg.stat_hdr.stat, leaf_hdr_eg.udp_hdr.dstPort, leaf_hdr_eg.udp_hdr.hdrlen, leaf_hdr_eg.udp_hdr.srcPort, leaf_hdr_eg.vallen_hdr.vallen, leaf_isValid, leaf_meta.bypass_egress, leaf_meta.cm1_predicate, leaf_meta.cm2_predicate, leaf_meta.cm3_predicate, leaf_meta.cm4_predicate, leaf_meta.hashval_for_spine_partition, leaf_meta.is_deleted, leaf_meta.is_hot, leaf_meta.is_lastclone_for_pktloss, leaf_meta.is_latest, leaf_meta.is_report, leaf_meta.is_report1, leaf_meta.is_report2, leaf_meta.is_report3, leaf_meta.spine_sid, leaf_netcacheEgress_access_bf1_tbl.action_run, leaf_netcacheEgress_access_bf1_tbl.hit, leaf_netcacheEgress_access_bf2_tbl.action_run, leaf_netcacheEgress_access_bf2_tbl.hit, leaf_netcacheEgress_access_bf3_tbl.action_run, leaf_netcacheEgress_access_bf3_tbl.hit, leaf_netcacheEgress_access_cache_frequency_tbl.action_run, leaf_netcacheEgress_access_cache_frequency_tbl.hit, leaf_netcacheEgress_access_cm1_tbl.action_run, leaf_netcacheEgress_access_cm1_tbl.hit, leaf_netcacheEgress_access_cm2_tbl.action_run, leaf_netcacheEgress_access_cm2_tbl.hit, leaf_netcacheEgress_access_cm3_tbl.action_run, leaf_netcacheEgress_access_cm3_tbl.hit, leaf_netcacheEgress_access_cm4_tbl.action_run, leaf_netcacheEgress_access_cm4_tbl.hit, leaf_netcacheEgress_access_deleted_tbl.action_run, leaf_netcacheEgress_access_deleted_tbl.hit, leaf_netcacheEgress_access_latest_tbl.action_run, leaf_netcacheEgress_access_latest_tbl.hit, leaf_netcacheEgress_access_savedseq_tbl.action_run, leaf_netcacheEgress_access_savedseq_tbl.hit, leaf_netcacheEgress_access_seq_tbl.action_run, leaf_netcacheEgress_access_seq_tbl.hit, leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run, leaf_netcacheEgress_add_and_remove_value_header_tbl.hit, leaf_netcacheEgress_bypass_egress_tbl.action_run, leaf_netcacheEgress_bypass_egress_tbl.hit, leaf_netcacheEgress_cm1_reg, leaf_netcacheEgress_cm1_reg__last0_old_value, leaf_netcacheEgress_cm1_reg__last0_value, leaf_netcacheEgress_cm1_reg__last_index, leaf_netcacheEgress_cm1_reg__last_old_value, leaf_netcacheEgress_cm1_reg__last_value, leaf_netcacheEgress_cm1_reg__last_write_site, leaf_netcacheEgress_cm1_reg__next_write_site, leaf_netcacheEgress_cm1_reg__wrote_any, leaf_netcacheEgress_cm1_reg__wrote_index0, leaf_netcacheEgress_cm2_reg, leaf_netcacheEgress_cm2_reg__last0_old_value, leaf_netcacheEgress_cm2_reg__last0_value, leaf_netcacheEgress_cm2_reg__last_index, leaf_netcacheEgress_cm2_reg__last_old_value, leaf_netcacheEgress_cm2_reg__last_value, leaf_netcacheEgress_cm2_reg__last_write_site, leaf_netcacheEgress_cm2_reg__next_write_site, leaf_netcacheEgress_cm2_reg__wrote_any, leaf_netcacheEgress_cm2_reg__wrote_index0, leaf_netcacheEgress_deleted_reg, leaf_netcacheEgress_deleted_reg__last0_old_value, leaf_netcacheEgress_deleted_reg__last0_value, leaf_netcacheEgress_deleted_reg__last_index, leaf_netcacheEgress_deleted_reg__last_old_value, leaf_netcacheEgress_deleted_reg__last_value, leaf_netcacheEgress_deleted_reg__last_write_site, leaf_netcacheEgress_deleted_reg__next_write_site, leaf_netcacheEgress_deleted_reg__wrote_any, leaf_netcacheEgress_deleted_reg__wrote_index0, leaf_netcacheEgress_eg_port_forward_tbl.action_run, leaf_netcacheEgress_eg_port_forward_tbl.hit, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_9, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid_7, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.reflector_port_7, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.switchos_sid_11, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_6, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_10, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_12, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_getreq_pop_to_getreq_by_mirroring.server_sid_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.client_sid_4, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.server_port, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.reflector_port, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid, leaf_netcacheEgress_is_hot_tbl.action_run, leaf_netcacheEgress_is_hot_tbl.hit, leaf_netcacheEgress_is_report_tbl.action_run, leaf_netcacheEgress_is_report_tbl.hit, leaf_netcacheEgress_lastclone_lastscansplit_tbl.action_run, leaf_netcacheEgress_lastclone_lastscansplit_tbl.hit, leaf_netcacheEgress_latest_reg, leaf_netcacheEgress_latest_reg__last0_old_value, leaf_netcacheEgress_latest_reg__last0_value, leaf_netcacheEgress_latest_reg__last_index, leaf_netcacheEgress_latest_reg__last_old_value, leaf_netcacheEgress_latest_reg__last_value, leaf_netcacheEgress_latest_reg__last_write_site, leaf_netcacheEgress_latest_reg__next_write_site, leaf_netcacheEgress_latest_reg__wrote_any, leaf_netcacheEgress_latest_reg__wrote_index0, leaf_netcacheEgress_prepare_for_cachepop_tbl.action_run, leaf_netcacheEgress_prepare_for_cachepop_tbl.hit, leaf_netcacheEgress_prepare_for_cachepop_tbl.netcacheEgress_set_server_sid_and_port.server_sid_2, leaf_netcacheEgress_save_client_udpport_tbl.action_run, leaf_netcacheEgress_save_client_udpport_tbl.hit, leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run, leaf_netcacheEgress_update_ipmac_srcport_tbl.hit, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_ip_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_mac_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_ip_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_mac_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_port_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_ip_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_mac_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_port_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_ip_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_port, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_mac, leaf_netcacheEgress_update_pktlen_tbl.action_run, leaf_netcacheEgress_update_pktlen_tbl.hit, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.iplen_delta, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.udplen_delta, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_vallen_tbl.action_run, leaf_netcacheEgress_update_vallen_tbl.hit, leaf_netcacheEgress_vallen_reg, leaf_netcacheEgress_vallen_reg__last0_old_value, leaf_netcacheEgress_vallen_reg__last0_value, leaf_netcacheEgress_vallen_reg__last_index, leaf_netcacheEgress_vallen_reg__last_old_value, leaf_netcacheEgress_vallen_reg__last_value, leaf_netcacheEgress_vallen_reg__last_write_site, leaf_netcacheEgress_vallen_reg__next_write_site, leaf_netcacheEgress_vallen_reg__wrote_any, leaf_netcacheEgress_vallen_reg__wrote_index0, leaf_netcacheIngress_hash_for_partition_tbl.action_run, leaf_netcacheIngress_hash_for_partition_tbl.hit, leaf_netcacheIngress_hash_spine_partition_tbl.action_run, leaf_netcacheIngress_hash_spine_partition_tbl.hit, leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.eport_5, leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.spine_sid_1, leaf_p4b_clone_i2e, leaf_standard_metadata.egress_port;
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
	modifies leaf_cm1_res_0, leaf_cm2_res_0, leaf_cm3_res_0, leaf_cm4_res_0, leaf_drop, leaf_hdr.op_hdr.optype, leaf_hdr_eg.clone_hdr.client_udpport, leaf_hdr_eg.clone_hdr.clonenum_for_pktloss, leaf_hdr_eg.clone_hdr.server_sid, leaf_hdr_eg.clone_hdr.server_udpport, leaf_hdr_eg.fraginfo_hdr.cur_fragidx, leaf_hdr_eg.inswitch_hdr.client_sid, leaf_hdr_eg.inswitch_hdr.is_cached, leaf_hdr_eg.inswitch_hdr.is_sampled, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.stat_hdr.nodeidx_foreval, leaf_hdr_eg.stat_hdr.stat, leaf_hdr_eg.udp_hdr.dstPort, leaf_hdr_eg.udp_hdr.hdrlen, leaf_hdr_eg.udp_hdr.srcPort, leaf_hdr_eg.vallen_hdr.vallen, leaf_isValid, leaf_meta.bypass_egress, leaf_meta.cm1_predicate, leaf_meta.cm2_predicate, leaf_meta.cm3_predicate, leaf_meta.cm4_predicate, leaf_meta.hashval_for_spine_partition, leaf_meta.is_deleted, leaf_meta.is_hot, leaf_meta.is_lastclone_for_pktloss, leaf_meta.is_latest, leaf_meta.is_report, leaf_meta.is_report1, leaf_meta.is_report2, leaf_meta.is_report3, leaf_meta.spine_sid, leaf_netcacheEgress_access_bf1_tbl.action_run, leaf_netcacheEgress_access_bf1_tbl.hit, leaf_netcacheEgress_access_bf2_tbl.action_run, leaf_netcacheEgress_access_bf2_tbl.hit, leaf_netcacheEgress_access_bf3_tbl.action_run, leaf_netcacheEgress_access_bf3_tbl.hit, leaf_netcacheEgress_access_cache_frequency_tbl.action_run, leaf_netcacheEgress_access_cache_frequency_tbl.hit, leaf_netcacheEgress_access_cm1_tbl.action_run, leaf_netcacheEgress_access_cm1_tbl.hit, leaf_netcacheEgress_access_cm2_tbl.action_run, leaf_netcacheEgress_access_cm2_tbl.hit, leaf_netcacheEgress_access_cm3_tbl.action_run, leaf_netcacheEgress_access_cm3_tbl.hit, leaf_netcacheEgress_access_cm4_tbl.action_run, leaf_netcacheEgress_access_cm4_tbl.hit, leaf_netcacheEgress_access_deleted_tbl.action_run, leaf_netcacheEgress_access_deleted_tbl.hit, leaf_netcacheEgress_access_latest_tbl.action_run, leaf_netcacheEgress_access_latest_tbl.hit, leaf_netcacheEgress_access_savedseq_tbl.action_run, leaf_netcacheEgress_access_savedseq_tbl.hit, leaf_netcacheEgress_access_seq_tbl.action_run, leaf_netcacheEgress_access_seq_tbl.hit, leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run, leaf_netcacheEgress_add_and_remove_value_header_tbl.hit, leaf_netcacheEgress_bypass_egress_tbl.action_run, leaf_netcacheEgress_bypass_egress_tbl.hit, leaf_netcacheEgress_cm1_reg, leaf_netcacheEgress_cm1_reg__last0_old_value, leaf_netcacheEgress_cm1_reg__last0_value, leaf_netcacheEgress_cm1_reg__last_index, leaf_netcacheEgress_cm1_reg__last_old_value, leaf_netcacheEgress_cm1_reg__last_value, leaf_netcacheEgress_cm1_reg__last_write_site, leaf_netcacheEgress_cm1_reg__next_write_site, leaf_netcacheEgress_cm1_reg__wrote_any, leaf_netcacheEgress_cm1_reg__wrote_index0, leaf_netcacheEgress_cm2_reg, leaf_netcacheEgress_cm2_reg__last0_old_value, leaf_netcacheEgress_cm2_reg__last0_value, leaf_netcacheEgress_cm2_reg__last_index, leaf_netcacheEgress_cm2_reg__last_old_value, leaf_netcacheEgress_cm2_reg__last_value, leaf_netcacheEgress_cm2_reg__last_write_site, leaf_netcacheEgress_cm2_reg__next_write_site, leaf_netcacheEgress_cm2_reg__wrote_any, leaf_netcacheEgress_cm2_reg__wrote_index0, leaf_netcacheEgress_deleted_reg, leaf_netcacheEgress_deleted_reg__last0_old_value, leaf_netcacheEgress_deleted_reg__last0_value, leaf_netcacheEgress_deleted_reg__last_index, leaf_netcacheEgress_deleted_reg__last_old_value, leaf_netcacheEgress_deleted_reg__last_value, leaf_netcacheEgress_deleted_reg__last_write_site, leaf_netcacheEgress_deleted_reg__next_write_site, leaf_netcacheEgress_deleted_reg__wrote_any, leaf_netcacheEgress_deleted_reg__wrote_index0, leaf_netcacheEgress_eg_port_forward_tbl.action_run, leaf_netcacheEgress_eg_port_forward_tbl.hit, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_9, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid_7, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.reflector_port_7, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.switchos_sid_11, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_6, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_10, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_12, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_getreq_pop_to_getreq_by_mirroring.server_sid_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.client_sid_4, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.server_port, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.reflector_port, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid, leaf_netcacheEgress_is_hot_tbl.action_run, leaf_netcacheEgress_is_hot_tbl.hit, leaf_netcacheEgress_is_report_tbl.action_run, leaf_netcacheEgress_is_report_tbl.hit, leaf_netcacheEgress_lastclone_lastscansplit_tbl.action_run, leaf_netcacheEgress_lastclone_lastscansplit_tbl.hit, leaf_netcacheEgress_latest_reg, leaf_netcacheEgress_latest_reg__last0_old_value, leaf_netcacheEgress_latest_reg__last0_value, leaf_netcacheEgress_latest_reg__last_index, leaf_netcacheEgress_latest_reg__last_old_value, leaf_netcacheEgress_latest_reg__last_value, leaf_netcacheEgress_latest_reg__last_write_site, leaf_netcacheEgress_latest_reg__next_write_site, leaf_netcacheEgress_latest_reg__wrote_any, leaf_netcacheEgress_latest_reg__wrote_index0, leaf_netcacheEgress_prepare_for_cachepop_tbl.action_run, leaf_netcacheEgress_prepare_for_cachepop_tbl.hit, leaf_netcacheEgress_prepare_for_cachepop_tbl.netcacheEgress_set_server_sid_and_port.server_sid_2, leaf_netcacheEgress_save_client_udpport_tbl.action_run, leaf_netcacheEgress_save_client_udpport_tbl.hit, leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run, leaf_netcacheEgress_update_ipmac_srcport_tbl.hit, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_ip_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_mac_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_ip_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_mac_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_port_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_ip_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_mac_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_port_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_ip_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_port, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_mac, leaf_netcacheEgress_update_pktlen_tbl.action_run, leaf_netcacheEgress_update_pktlen_tbl.hit, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.iplen_delta, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.udplen_delta, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_vallen_tbl.action_run, leaf_netcacheEgress_update_vallen_tbl.hit, leaf_netcacheEgress_vallen_reg, leaf_netcacheEgress_vallen_reg__last0_old_value, leaf_netcacheEgress_vallen_reg__last0_value, leaf_netcacheEgress_vallen_reg__last_index, leaf_netcacheEgress_vallen_reg__last_old_value, leaf_netcacheEgress_vallen_reg__last_value, leaf_netcacheEgress_vallen_reg__last_write_site, leaf_netcacheEgress_vallen_reg__next_write_site, leaf_netcacheEgress_vallen_reg__wrote_any, leaf_netcacheEgress_vallen_reg__wrote_index0, leaf_netcacheIngress_hash_for_partition_tbl.action_run, leaf_netcacheIngress_hash_for_partition_tbl.hit, leaf_netcacheIngress_hash_spine_partition_tbl.action_run, leaf_netcacheIngress_hash_spine_partition_tbl.hit, leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.eport_5, leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.spine_sid_1, leaf_p4b_checksum_error, leaf_p4b_checksum_updated, leaf_p4b_checksum_verified, leaf_p4b_clone_e2e, leaf_p4b_clone_i2e, leaf_p4b_clone_i2i, leaf_p4b_digest, leaf_p4b_recirculate, leaf_standard_metadata.egress_port;
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
procedure leaf_mark_to_drop();
    ensures leaf_drop==true;
	modifies leaf_drop;

// leaf_Control leaf_netcacheComputeChecksum
procedure {:inline 1} leaf_netcacheComputeChecksum()
{
}

// leaf_Control leaf_netcacheEgress
procedure {:inline 1} leaf_netcacheEgress()
	modifies leaf_cm1_res_0, leaf_cm2_res_0, leaf_cm3_res_0, leaf_cm4_res_0, leaf_drop, leaf_hdr_eg.clone_hdr.client_udpport, leaf_hdr_eg.clone_hdr.clonenum_for_pktloss, leaf_hdr_eg.clone_hdr.server_sid, leaf_hdr_eg.clone_hdr.server_udpport, leaf_hdr_eg.fraginfo_hdr.cur_fragidx, leaf_hdr_eg.inswitch_hdr.client_sid, leaf_hdr_eg.inswitch_hdr.is_cached, leaf_hdr_eg.inswitch_hdr.is_sampled, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.stat_hdr.nodeidx_foreval, leaf_hdr_eg.stat_hdr.stat, leaf_hdr_eg.udp_hdr.dstPort, leaf_hdr_eg.udp_hdr.hdrlen, leaf_hdr_eg.udp_hdr.srcPort, leaf_hdr_eg.vallen_hdr.vallen, leaf_isValid, leaf_meta.bypass_egress, leaf_meta.cm1_predicate, leaf_meta.cm2_predicate, leaf_meta.cm3_predicate, leaf_meta.cm4_predicate, leaf_meta.is_deleted, leaf_meta.is_hot, leaf_meta.is_lastclone_for_pktloss, leaf_meta.is_latest, leaf_meta.is_report, leaf_meta.is_report1, leaf_meta.is_report2, leaf_meta.is_report3, leaf_meta.spine_sid, leaf_netcacheEgress_access_bf1_tbl.action_run, leaf_netcacheEgress_access_bf1_tbl.hit, leaf_netcacheEgress_access_bf2_tbl.action_run, leaf_netcacheEgress_access_bf2_tbl.hit, leaf_netcacheEgress_access_bf3_tbl.action_run, leaf_netcacheEgress_access_bf3_tbl.hit, leaf_netcacheEgress_access_cache_frequency_tbl.action_run, leaf_netcacheEgress_access_cache_frequency_tbl.hit, leaf_netcacheEgress_access_cm1_tbl.action_run, leaf_netcacheEgress_access_cm1_tbl.hit, leaf_netcacheEgress_access_cm2_tbl.action_run, leaf_netcacheEgress_access_cm2_tbl.hit, leaf_netcacheEgress_access_cm3_tbl.action_run, leaf_netcacheEgress_access_cm3_tbl.hit, leaf_netcacheEgress_access_cm4_tbl.action_run, leaf_netcacheEgress_access_cm4_tbl.hit, leaf_netcacheEgress_access_deleted_tbl.action_run, leaf_netcacheEgress_access_deleted_tbl.hit, leaf_netcacheEgress_access_latest_tbl.action_run, leaf_netcacheEgress_access_latest_tbl.hit, leaf_netcacheEgress_access_savedseq_tbl.action_run, leaf_netcacheEgress_access_savedseq_tbl.hit, leaf_netcacheEgress_access_seq_tbl.action_run, leaf_netcacheEgress_access_seq_tbl.hit, leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run, leaf_netcacheEgress_add_and_remove_value_header_tbl.hit, leaf_netcacheEgress_bypass_egress_tbl.action_run, leaf_netcacheEgress_bypass_egress_tbl.hit, leaf_netcacheEgress_cm1_reg, leaf_netcacheEgress_cm1_reg__last0_old_value, leaf_netcacheEgress_cm1_reg__last0_value, leaf_netcacheEgress_cm1_reg__last_index, leaf_netcacheEgress_cm1_reg__last_old_value, leaf_netcacheEgress_cm1_reg__last_value, leaf_netcacheEgress_cm1_reg__last_write_site, leaf_netcacheEgress_cm1_reg__next_write_site, leaf_netcacheEgress_cm1_reg__wrote_any, leaf_netcacheEgress_cm1_reg__wrote_index0, leaf_netcacheEgress_cm2_reg, leaf_netcacheEgress_cm2_reg__last0_old_value, leaf_netcacheEgress_cm2_reg__last0_value, leaf_netcacheEgress_cm2_reg__last_index, leaf_netcacheEgress_cm2_reg__last_old_value, leaf_netcacheEgress_cm2_reg__last_value, leaf_netcacheEgress_cm2_reg__last_write_site, leaf_netcacheEgress_cm2_reg__next_write_site, leaf_netcacheEgress_cm2_reg__wrote_any, leaf_netcacheEgress_cm2_reg__wrote_index0, leaf_netcacheEgress_deleted_reg, leaf_netcacheEgress_deleted_reg__last0_old_value, leaf_netcacheEgress_deleted_reg__last0_value, leaf_netcacheEgress_deleted_reg__last_index, leaf_netcacheEgress_deleted_reg__last_old_value, leaf_netcacheEgress_deleted_reg__last_value, leaf_netcacheEgress_deleted_reg__last_write_site, leaf_netcacheEgress_deleted_reg__next_write_site, leaf_netcacheEgress_deleted_reg__wrote_any, leaf_netcacheEgress_deleted_reg__wrote_index0, leaf_netcacheEgress_eg_port_forward_tbl.action_run, leaf_netcacheEgress_eg_port_forward_tbl.hit, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_9, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid_7, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.reflector_port_7, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.switchos_sid_11, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_6, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_10, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_12, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_getreq_pop_to_getreq_by_mirroring.server_sid_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.client_sid_4, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.server_port, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.reflector_port, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid, leaf_netcacheEgress_is_hot_tbl.action_run, leaf_netcacheEgress_is_hot_tbl.hit, leaf_netcacheEgress_is_report_tbl.action_run, leaf_netcacheEgress_is_report_tbl.hit, leaf_netcacheEgress_lastclone_lastscansplit_tbl.action_run, leaf_netcacheEgress_lastclone_lastscansplit_tbl.hit, leaf_netcacheEgress_latest_reg, leaf_netcacheEgress_latest_reg__last0_old_value, leaf_netcacheEgress_latest_reg__last0_value, leaf_netcacheEgress_latest_reg__last_index, leaf_netcacheEgress_latest_reg__last_old_value, leaf_netcacheEgress_latest_reg__last_value, leaf_netcacheEgress_latest_reg__last_write_site, leaf_netcacheEgress_latest_reg__next_write_site, leaf_netcacheEgress_latest_reg__wrote_any, leaf_netcacheEgress_latest_reg__wrote_index0, leaf_netcacheEgress_prepare_for_cachepop_tbl.action_run, leaf_netcacheEgress_prepare_for_cachepop_tbl.hit, leaf_netcacheEgress_prepare_for_cachepop_tbl.netcacheEgress_set_server_sid_and_port.server_sid_2, leaf_netcacheEgress_save_client_udpport_tbl.action_run, leaf_netcacheEgress_save_client_udpport_tbl.hit, leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run, leaf_netcacheEgress_update_ipmac_srcport_tbl.hit, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_ip_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_mac_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_ip_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_mac_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_port_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_ip_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_mac_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_port_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_ip_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_port, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_mac, leaf_netcacheEgress_update_pktlen_tbl.action_run, leaf_netcacheEgress_update_pktlen_tbl.hit, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.iplen_delta, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.udplen_delta, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_vallen_tbl.action_run, leaf_netcacheEgress_update_vallen_tbl.hit, leaf_netcacheEgress_vallen_reg, leaf_netcacheEgress_vallen_reg__last0_old_value, leaf_netcacheEgress_vallen_reg__last0_value, leaf_netcacheEgress_vallen_reg__last_index, leaf_netcacheEgress_vallen_reg__last_old_value, leaf_netcacheEgress_vallen_reg__last_value, leaf_netcacheEgress_vallen_reg__last_write_site, leaf_netcacheEgress_vallen_reg__next_write_site, leaf_netcacheEgress_vallen_reg__wrote_any, leaf_netcacheEgress_vallen_reg__wrote_index0, leaf_p4b_clone_i2e, leaf_standard_metadata.egress_port;
{
havoc leaf_cm1_res_0;
havoc leaf_cm2_res_0;
havoc leaf_cm3_res_0;
havoc leaf_cm4_res_0;
    call leaf_netcacheEgress_bypass_egress_tbl.apply();
    if((leaf_meta.bypass_egress == 1bv1)){
    }
    else{
        call leaf_netcacheEgress_access_latest_tbl.apply();
        call leaf_netcacheEgress_access_seq_tbl.apply();
        call leaf_netcacheEgress_save_client_udpport_tbl.apply();
        call leaf_netcacheEgress_prepare_for_cachepop_tbl.apply();
        call leaf_netcacheEgress_access_cm1_tbl.apply();
        call leaf_netcacheEgress_access_cm2_tbl.apply();
        call leaf_netcacheEgress_access_cm3_tbl.apply();
        call leaf_netcacheEgress_access_cm4_tbl.apply();
        call leaf_netcacheEgress_is_hot_tbl.apply();
        call leaf_netcacheEgress_access_cache_frequency_tbl.apply();
        call leaf_netcacheEgress_access_deleted_tbl.apply();
        call leaf_netcacheEgress_access_savedseq_tbl.apply();
        call leaf_netcacheEgress_update_vallen_tbl.apply();
        call leaf_netcacheEgress_access_bf1_tbl.apply();
        call leaf_netcacheEgress_access_bf2_tbl.apply();
        call leaf_netcacheEgress_access_bf3_tbl.apply();
        call leaf_netcacheEgress_is_report_tbl.apply();
        call leaf_netcacheEgress_lastclone_lastscansplit_tbl.apply();
        call leaf_netcacheEgress_eg_port_forward_tbl.apply();
        call leaf_netcacheEgress_update_ipmac_srcport_tbl.apply();
        call leaf_netcacheEgress_update_pktlen_tbl.apply();
        call leaf_netcacheEgress_add_and_remove_value_header_tbl.apply();
    }
}

// leaf_Table leaf_netcacheEgress_access_bf1_tbl
procedure {:inline 1} leaf_netcacheEgress_access_bf1_tbl.apply()
	modifies leaf_hdr_eg.op_hdr.optype, leaf_meta.is_hot, leaf_meta.is_report1, leaf_netcacheEgress_access_bf1_tbl.action_run, leaf_netcacheEgress_access_bf1_tbl.hit;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_meta.is_hot := leaf_meta.is_hot;
    leaf_netcacheEgress_access_bf1_tbl.hit := false;
    leaf_netcacheEgress_access_bf1_tbl.action_run := leaf_netcacheEgress_access_bf1_tbl.action.netcacheEgress_reset_is_report1;
    call leaf_netcacheEgress_reset_is_report1();
    goto leaf_Exit;

    leaf_action_netcacheEgress_update_bf1:
    assume leaf_netcacheEgress_access_bf1_tbl.action_run == leaf_netcacheEgress_access_bf1_tbl.action.netcacheEgress_update_bf1;
    call leaf_netcacheEgress_update_bf1();
    goto leaf_Exit;

    leaf_action_netcacheEgress_reset_is_report1:
    assume leaf_netcacheEgress_access_bf1_tbl.action_run == leaf_netcacheEgress_access_bf1_tbl.action.netcacheEgress_reset_is_report1;
    call leaf_netcacheEgress_reset_is_report1();
    goto leaf_Exit;

    leaf_Exit:
}

// leaf_Table leaf_netcacheEgress_access_bf2_tbl
procedure {:inline 1} leaf_netcacheEgress_access_bf2_tbl.apply()
	modifies leaf_hdr_eg.op_hdr.optype, leaf_meta.is_hot, leaf_meta.is_report2, leaf_netcacheEgress_access_bf2_tbl.action_run, leaf_netcacheEgress_access_bf2_tbl.hit;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_meta.is_hot := leaf_meta.is_hot;
    leaf_netcacheEgress_access_bf2_tbl.hit := false;
    leaf_netcacheEgress_access_bf2_tbl.action_run := leaf_netcacheEgress_access_bf2_tbl.action.netcacheEgress_reset_is_report2;
    call leaf_netcacheEgress_reset_is_report2();
    goto leaf_Exit;

    leaf_action_netcacheEgress_update_bf2:
    assume leaf_netcacheEgress_access_bf2_tbl.action_run == leaf_netcacheEgress_access_bf2_tbl.action.netcacheEgress_update_bf2;
    call leaf_netcacheEgress_update_bf2();
    goto leaf_Exit;

    leaf_action_netcacheEgress_reset_is_report2:
    assume leaf_netcacheEgress_access_bf2_tbl.action_run == leaf_netcacheEgress_access_bf2_tbl.action.netcacheEgress_reset_is_report2;
    call leaf_netcacheEgress_reset_is_report2();
    goto leaf_Exit;

    leaf_Exit:
}

// leaf_Table leaf_netcacheEgress_access_bf3_tbl
procedure {:inline 1} leaf_netcacheEgress_access_bf3_tbl.apply()
	modifies leaf_hdr_eg.op_hdr.optype, leaf_meta.is_hot, leaf_meta.is_report3, leaf_netcacheEgress_access_bf3_tbl.action_run, leaf_netcacheEgress_access_bf3_tbl.hit;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_meta.is_hot := leaf_meta.is_hot;
    leaf_netcacheEgress_access_bf3_tbl.hit := false;
    leaf_netcacheEgress_access_bf3_tbl.action_run := leaf_netcacheEgress_access_bf3_tbl.action.netcacheEgress_reset_is_report3;
    call leaf_netcacheEgress_reset_is_report3();
    goto leaf_Exit;

    leaf_action_netcacheEgress_update_bf3:
    assume leaf_netcacheEgress_access_bf3_tbl.action_run == leaf_netcacheEgress_access_bf3_tbl.action.netcacheEgress_update_bf3;
    call leaf_netcacheEgress_update_bf3();
    goto leaf_Exit;

    leaf_action_netcacheEgress_reset_is_report3:
    assume leaf_netcacheEgress_access_bf3_tbl.action_run == leaf_netcacheEgress_access_bf3_tbl.action.netcacheEgress_reset_is_report3;
    call leaf_netcacheEgress_reset_is_report3();
    goto leaf_Exit;

    leaf_Exit:
}

// leaf_Table leaf_netcacheEgress_access_cache_frequency_tbl
procedure {:inline 1} leaf_netcacheEgress_access_cache_frequency_tbl.apply()
	modifies leaf_hdr_eg.inswitch_hdr.is_cached, leaf_hdr_eg.inswitch_hdr.is_sampled, leaf_hdr_eg.op_hdr.optype, leaf_meta.is_latest, leaf_netcacheEgress_access_cache_frequency_tbl.action_run, leaf_netcacheEgress_access_cache_frequency_tbl.hit;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.inswitch_hdr.is_sampled := leaf_hdr_eg.inswitch_hdr.is_sampled;
    leaf_hdr_eg.inswitch_hdr.is_cached := leaf_hdr_eg.inswitch_hdr.is_cached;
    leaf_meta.is_latest := leaf_meta.is_latest;
    leaf_netcacheEgress_access_cache_frequency_tbl.hit := false;
    if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 0bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_update_cache_frequency;
        call leaf_netcacheEgress_update_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 1bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_update_cache_frequency;
        call leaf_netcacheEgress_update_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 0bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 0bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 36bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 0bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_get_cache_frequency;
        call leaf_netcacheEgress_get_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 0bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 0bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 36bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 0bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_get_cache_frequency;
        call leaf_netcacheEgress_get_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 0bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 0bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 36bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 0bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_get_cache_frequency;
        call leaf_netcacheEgress_get_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 0bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 0bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 36bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 0bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_get_cache_frequency;
        call leaf_netcacheEgress_get_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 1bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 1bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 36bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 1bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_get_cache_frequency;
        call leaf_netcacheEgress_get_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 1bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 1bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 36bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 1bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_get_cache_frequency;
        call leaf_netcacheEgress_get_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 1bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 1bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 36bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 1bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_get_cache_frequency;
        call leaf_netcacheEgress_get_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 1bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 1bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_reset_cache_frequency;
        call leaf_netcacheEgress_reset_cache_frequency();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 36bv16 && leaf_hdr_eg.inswitch_hdr.is_sampled == 1bv1 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_cache_frequency_tbl.hit := true;
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.netcacheEgress_get_cache_frequency;
        call leaf_netcacheEgress_get_cache_frequency();
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_access_cache_frequency_tbl.hit){
        leaf_netcacheEgress_access_cache_frequency_tbl.action_run := leaf_netcacheEgress_access_cache_frequency_tbl.action.NoAction_11;
        call leaf_NoAction_11();
        goto leaf_Exit;
    }

    leaf_Exit:
}

// leaf_Table leaf_netcacheEgress_access_cm1_tbl
procedure {:inline 1} leaf_netcacheEgress_access_cm1_tbl.apply()
	modifies leaf_cm1_res_0, leaf_hdr_eg.inswitch_hdr.is_cached, leaf_hdr_eg.inswitch_hdr.is_sampled, leaf_hdr_eg.op_hdr.optype, leaf_meta.cm1_predicate, leaf_meta.is_latest, leaf_netcacheEgress_access_cm1_tbl.action_run, leaf_netcacheEgress_access_cm1_tbl.hit, leaf_netcacheEgress_cm1_reg, leaf_netcacheEgress_cm1_reg__last0_old_value, leaf_netcacheEgress_cm1_reg__last0_value, leaf_netcacheEgress_cm1_reg__last_index, leaf_netcacheEgress_cm1_reg__last_old_value, leaf_netcacheEgress_cm1_reg__last_value, leaf_netcacheEgress_cm1_reg__last_write_site, leaf_netcacheEgress_cm1_reg__next_write_site, leaf_netcacheEgress_cm1_reg__wrote_any, leaf_netcacheEgress_cm1_reg__wrote_index0;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.inswitch_hdr.is_sampled := leaf_hdr_eg.inswitch_hdr.is_sampled;
    leaf_hdr_eg.inswitch_hdr.is_cached := leaf_hdr_eg.inswitch_hdr.is_cached;
    leaf_meta.is_latest := leaf_meta.is_latest;
    leaf_netcacheEgress_access_cm1_tbl.hit := false;
    leaf_netcacheEgress_access_cm1_tbl.action_run := leaf_netcacheEgress_access_cm1_tbl.action.netcacheEgress_initialize_cm1_predicate;
    call leaf_netcacheEgress_initialize_cm1_predicate();
    goto leaf_Exit;

    leaf_action_netcacheEgress_update_cm1:
    assume leaf_netcacheEgress_access_cm1_tbl.action_run == leaf_netcacheEgress_access_cm1_tbl.action.netcacheEgress_update_cm1;
    call leaf_netcacheEgress_update_cm1();
    goto leaf_Exit;

    leaf_action_netcacheEgress_initialize_cm1_predicate:
    assume leaf_netcacheEgress_access_cm1_tbl.action_run == leaf_netcacheEgress_access_cm1_tbl.action.netcacheEgress_initialize_cm1_predicate;
    call leaf_netcacheEgress_initialize_cm1_predicate();
    goto leaf_Exit;

    leaf_Exit:
}

// leaf_Table leaf_netcacheEgress_access_cm2_tbl
procedure {:inline 1} leaf_netcacheEgress_access_cm2_tbl.apply()
	modifies leaf_cm2_res_0, leaf_hdr_eg.inswitch_hdr.is_cached, leaf_hdr_eg.inswitch_hdr.is_sampled, leaf_hdr_eg.op_hdr.optype, leaf_meta.cm2_predicate, leaf_meta.is_latest, leaf_netcacheEgress_access_cm2_tbl.action_run, leaf_netcacheEgress_access_cm2_tbl.hit, leaf_netcacheEgress_cm2_reg, leaf_netcacheEgress_cm2_reg__last0_old_value, leaf_netcacheEgress_cm2_reg__last0_value, leaf_netcacheEgress_cm2_reg__last_index, leaf_netcacheEgress_cm2_reg__last_old_value, leaf_netcacheEgress_cm2_reg__last_value, leaf_netcacheEgress_cm2_reg__last_write_site, leaf_netcacheEgress_cm2_reg__next_write_site, leaf_netcacheEgress_cm2_reg__wrote_any, leaf_netcacheEgress_cm2_reg__wrote_index0;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.inswitch_hdr.is_sampled := leaf_hdr_eg.inswitch_hdr.is_sampled;
    leaf_hdr_eg.inswitch_hdr.is_cached := leaf_hdr_eg.inswitch_hdr.is_cached;
    leaf_meta.is_latest := leaf_meta.is_latest;
    leaf_netcacheEgress_access_cm2_tbl.hit := false;
    leaf_netcacheEgress_access_cm2_tbl.action_run := leaf_netcacheEgress_access_cm2_tbl.action.netcacheEgress_initialize_cm2_predicate;
    call leaf_netcacheEgress_initialize_cm2_predicate();
    goto leaf_Exit;

    leaf_action_netcacheEgress_update_cm2:
    assume leaf_netcacheEgress_access_cm2_tbl.action_run == leaf_netcacheEgress_access_cm2_tbl.action.netcacheEgress_update_cm2;
    call leaf_netcacheEgress_update_cm2();
    goto leaf_Exit;

    leaf_action_netcacheEgress_initialize_cm2_predicate:
    assume leaf_netcacheEgress_access_cm2_tbl.action_run == leaf_netcacheEgress_access_cm2_tbl.action.netcacheEgress_initialize_cm2_predicate;
    call leaf_netcacheEgress_initialize_cm2_predicate();
    goto leaf_Exit;

    leaf_Exit:
}

// leaf_Table leaf_netcacheEgress_access_cm3_tbl
procedure {:inline 1} leaf_netcacheEgress_access_cm3_tbl.apply()
	modifies leaf_cm3_res_0, leaf_hdr_eg.inswitch_hdr.is_cached, leaf_hdr_eg.inswitch_hdr.is_sampled, leaf_hdr_eg.op_hdr.optype, leaf_meta.cm3_predicate, leaf_meta.is_latest, leaf_netcacheEgress_access_cm3_tbl.action_run, leaf_netcacheEgress_access_cm3_tbl.hit, leaf_netcacheEgress_cm1_reg, leaf_netcacheEgress_cm1_reg__last0_old_value, leaf_netcacheEgress_cm1_reg__last0_value, leaf_netcacheEgress_cm1_reg__last_index, leaf_netcacheEgress_cm1_reg__last_old_value, leaf_netcacheEgress_cm1_reg__last_value, leaf_netcacheEgress_cm1_reg__last_write_site, leaf_netcacheEgress_cm1_reg__next_write_site, leaf_netcacheEgress_cm1_reg__wrote_any, leaf_netcacheEgress_cm1_reg__wrote_index0;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.inswitch_hdr.is_sampled := leaf_hdr_eg.inswitch_hdr.is_sampled;
    leaf_hdr_eg.inswitch_hdr.is_cached := leaf_hdr_eg.inswitch_hdr.is_cached;
    leaf_meta.is_latest := leaf_meta.is_latest;
    leaf_netcacheEgress_access_cm3_tbl.hit := false;
    leaf_netcacheEgress_access_cm3_tbl.action_run := leaf_netcacheEgress_access_cm3_tbl.action.netcacheEgress_initialize_cm3_predicate;
    call leaf_netcacheEgress_initialize_cm3_predicate();
    goto leaf_Exit;

    leaf_action_netcacheEgress_update_cm3:
    assume leaf_netcacheEgress_access_cm3_tbl.action_run == leaf_netcacheEgress_access_cm3_tbl.action.netcacheEgress_update_cm3;
    call leaf_netcacheEgress_update_cm3();
    goto leaf_Exit;

    leaf_action_netcacheEgress_initialize_cm3_predicate:
    assume leaf_netcacheEgress_access_cm3_tbl.action_run == leaf_netcacheEgress_access_cm3_tbl.action.netcacheEgress_initialize_cm3_predicate;
    call leaf_netcacheEgress_initialize_cm3_predicate();
    goto leaf_Exit;

    leaf_Exit:
}

// leaf_Table leaf_netcacheEgress_access_cm4_tbl
procedure {:inline 1} leaf_netcacheEgress_access_cm4_tbl.apply()
	modifies leaf_cm4_res_0, leaf_hdr_eg.inswitch_hdr.is_cached, leaf_hdr_eg.inswitch_hdr.is_sampled, leaf_hdr_eg.op_hdr.optype, leaf_meta.cm4_predicate, leaf_meta.is_latest, leaf_netcacheEgress_access_cm4_tbl.action_run, leaf_netcacheEgress_access_cm4_tbl.hit, leaf_netcacheEgress_cm1_reg, leaf_netcacheEgress_cm1_reg__last0_old_value, leaf_netcacheEgress_cm1_reg__last0_value, leaf_netcacheEgress_cm1_reg__last_index, leaf_netcacheEgress_cm1_reg__last_old_value, leaf_netcacheEgress_cm1_reg__last_value, leaf_netcacheEgress_cm1_reg__last_write_site, leaf_netcacheEgress_cm1_reg__next_write_site, leaf_netcacheEgress_cm1_reg__wrote_any, leaf_netcacheEgress_cm1_reg__wrote_index0;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.inswitch_hdr.is_sampled := leaf_hdr_eg.inswitch_hdr.is_sampled;
    leaf_hdr_eg.inswitch_hdr.is_cached := leaf_hdr_eg.inswitch_hdr.is_cached;
    leaf_meta.is_latest := leaf_meta.is_latest;
    leaf_netcacheEgress_access_cm4_tbl.hit := false;
    leaf_netcacheEgress_access_cm4_tbl.action_run := leaf_netcacheEgress_access_cm4_tbl.action.netcacheEgress_initialize_cm4_predicate;
    call leaf_netcacheEgress_initialize_cm4_predicate();
    goto leaf_Exit;

    leaf_action_netcacheEgress_update_cm4:
    assume leaf_netcacheEgress_access_cm4_tbl.action_run == leaf_netcacheEgress_access_cm4_tbl.action.netcacheEgress_update_cm4;
    call leaf_netcacheEgress_update_cm4();
    goto leaf_Exit;

    leaf_action_netcacheEgress_initialize_cm4_predicate:
    assume leaf_netcacheEgress_access_cm4_tbl.action_run == leaf_netcacheEgress_access_cm4_tbl.action.netcacheEgress_initialize_cm4_predicate;
    call leaf_netcacheEgress_initialize_cm4_predicate();
    goto leaf_Exit;

    leaf_Exit:
}

// leaf_Table leaf_netcacheEgress_access_deleted_tbl
procedure {:inline 1} leaf_netcacheEgress_access_deleted_tbl.apply()
	modifies leaf_hdr_eg.inswitch_hdr.is_cached, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.stat_hdr.stat, leaf_meta.is_deleted, leaf_meta.is_latest, leaf_netcacheEgress_access_deleted_tbl.action_run, leaf_netcacheEgress_access_deleted_tbl.hit, leaf_netcacheEgress_deleted_reg, leaf_netcacheEgress_deleted_reg__last0_old_value, leaf_netcacheEgress_deleted_reg__last0_value, leaf_netcacheEgress_deleted_reg__last_index, leaf_netcacheEgress_deleted_reg__last_old_value, leaf_netcacheEgress_deleted_reg__last_value, leaf_netcacheEgress_deleted_reg__last_write_site, leaf_netcacheEgress_deleted_reg__next_write_site, leaf_netcacheEgress_deleted_reg__wrote_any, leaf_netcacheEgress_deleted_reg__wrote_index0;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.inswitch_hdr.is_cached := leaf_hdr_eg.inswitch_hdr.is_cached;
    leaf_meta.is_latest := leaf_meta.is_latest;
    leaf_hdr_eg.stat_hdr.stat := leaf_hdr_eg.stat_hdr.stat;
    leaf_netcacheEgress_access_deleted_tbl.hit := false;
    if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_hdr_eg.stat_hdr.stat == 0bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_set_and_get_deleted;
        call leaf_netcacheEgress_set_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_hdr_eg.stat_hdr.stat == 0bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_set_and_get_deleted;
        call leaf_netcacheEgress_set_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_hdr_eg.stat_hdr.stat == 1bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_reset_and_get_deleted;
        call leaf_netcacheEgress_reset_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_hdr_eg.stat_hdr.stat == 1bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_reset_and_get_deleted;
        call leaf_netcacheEgress_reset_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_hdr_eg.stat_hdr.stat == 0bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_set_and_get_deleted;
        call leaf_netcacheEgress_set_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_hdr_eg.stat_hdr.stat == 0bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_set_and_get_deleted;
        call leaf_netcacheEgress_set_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_hdr_eg.stat_hdr.stat == 1bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_reset_and_get_deleted;
        call leaf_netcacheEgress_reset_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_hdr_eg.stat_hdr.stat == 1bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_reset_and_get_deleted;
        call leaf_netcacheEgress_reset_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_hdr_eg.stat_hdr.stat == 0bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_get_deleted;
        call leaf_netcacheEgress_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_hdr_eg.stat_hdr.stat == 0bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_set_and_get_deleted;
        call leaf_netcacheEgress_set_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_hdr_eg.stat_hdr.stat == 0bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_set_and_get_deleted;
        call leaf_netcacheEgress_set_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_hdr_eg.stat_hdr.stat == 0bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_set_and_get_deleted;
        call leaf_netcacheEgress_set_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_hdr_eg.stat_hdr.stat == 1bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_get_deleted;
        call leaf_netcacheEgress_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_hdr_eg.stat_hdr.stat == 1bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_reset_and_get_deleted;
        call leaf_netcacheEgress_reset_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_hdr_eg.stat_hdr.stat == 1bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_reset_and_get_deleted;
        call leaf_netcacheEgress_reset_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_hdr_eg.stat_hdr.stat == 1bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_reset_and_get_deleted;
        call leaf_netcacheEgress_reset_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_hdr_eg.stat_hdr.stat == 0bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_get_deleted;
        call leaf_netcacheEgress_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_hdr_eg.stat_hdr.stat == 0bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_set_and_get_deleted;
        call leaf_netcacheEgress_set_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_hdr_eg.stat_hdr.stat == 0bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_set_and_get_deleted;
        call leaf_netcacheEgress_set_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_hdr_eg.stat_hdr.stat == 0bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_set_and_get_deleted;
        call leaf_netcacheEgress_set_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_hdr_eg.stat_hdr.stat == 1bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_get_deleted;
        call leaf_netcacheEgress_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_hdr_eg.stat_hdr.stat == 1bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_reset_and_get_deleted;
        call leaf_netcacheEgress_reset_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_hdr_eg.stat_hdr.stat == 1bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_reset_and_get_deleted;
        call leaf_netcacheEgress_reset_and_get_deleted();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_hdr_eg.stat_hdr.stat == 1bv8){
        leaf_netcacheEgress_access_deleted_tbl.hit := true;
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_reset_and_get_deleted;
        call leaf_netcacheEgress_reset_and_get_deleted();
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_access_deleted_tbl.hit){
        leaf_netcacheEgress_access_deleted_tbl.action_run := leaf_netcacheEgress_access_deleted_tbl.action.netcacheEgress_reset_is_deleted;
        call leaf_netcacheEgress_reset_is_deleted();
        goto leaf_Exit;
    }

    leaf_Exit:
}

// leaf_Table leaf_netcacheEgress_access_latest_tbl
procedure {:inline 1} leaf_netcacheEgress_access_latest_tbl.apply()
	modifies leaf_hdr_eg.fraginfo_hdr.cur_fragidx, leaf_hdr_eg.inswitch_hdr.is_cached, leaf_hdr_eg.op_hdr.optype, leaf_meta.is_latest, leaf_netcacheEgress_access_latest_tbl.action_run, leaf_netcacheEgress_access_latest_tbl.hit, leaf_netcacheEgress_latest_reg, leaf_netcacheEgress_latest_reg__last0_old_value, leaf_netcacheEgress_latest_reg__last0_value, leaf_netcacheEgress_latest_reg__last_index, leaf_netcacheEgress_latest_reg__last_old_value, leaf_netcacheEgress_latest_reg__last_value, leaf_netcacheEgress_latest_reg__last_write_site, leaf_netcacheEgress_latest_reg__next_write_site, leaf_netcacheEgress_latest_reg__wrote_any, leaf_netcacheEgress_latest_reg__wrote_index0;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.inswitch_hdr.is_cached := leaf_hdr_eg.inswitch_hdr.is_cached;
    leaf_hdr_eg.fraginfo_hdr.cur_fragidx := leaf_hdr_eg.fraginfo_hdr.cur_fragidx;
    leaf_netcacheEgress_access_latest_tbl.hit := false;
    if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_hdr_eg.fraginfo_hdr.cur_fragidx == 0bv16){
        leaf_netcacheEgress_access_latest_tbl.hit := true;
        leaf_netcacheEgress_access_latest_tbl.action_run := leaf_netcacheEgress_access_latest_tbl.action.netcacheEgress_set_and_get_latest;
        call leaf_netcacheEgress_set_and_get_latest();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_hdr_eg.fraginfo_hdr.cur_fragidx == 0bv16){
        leaf_netcacheEgress_access_latest_tbl.hit := true;
        leaf_netcacheEgress_access_latest_tbl.action_run := leaf_netcacheEgress_access_latest_tbl.action.netcacheEgress_reset_and_get_latest;
        call leaf_netcacheEgress_reset_and_get_latest();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_hdr_eg.fraginfo_hdr.cur_fragidx == 0bv16){
        leaf_netcacheEgress_access_latest_tbl.hit := true;
        leaf_netcacheEgress_access_latest_tbl.action_run := leaf_netcacheEgress_access_latest_tbl.action.netcacheEgress_get_latest;
        call leaf_netcacheEgress_get_latest();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 5bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_hdr_eg.fraginfo_hdr.cur_fragidx == 0bv16){
        leaf_netcacheEgress_access_latest_tbl.hit := true;
        leaf_netcacheEgress_access_latest_tbl.action_run := leaf_netcacheEgress_access_latest_tbl.action.netcacheEgress_reset_and_get_latest;
        call leaf_netcacheEgress_reset_and_get_latest();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 20bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_hdr_eg.fraginfo_hdr.cur_fragidx == 0bv16){
        leaf_netcacheEgress_access_latest_tbl.hit := true;
        leaf_netcacheEgress_access_latest_tbl.action_run := leaf_netcacheEgress_access_latest_tbl.action.netcacheEgress_reset_and_get_latest;
        call leaf_netcacheEgress_reset_and_get_latest();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_hdr_eg.fraginfo_hdr.cur_fragidx == 0bv16){
        leaf_netcacheEgress_access_latest_tbl.hit := true;
        leaf_netcacheEgress_access_latest_tbl.action_run := leaf_netcacheEgress_access_latest_tbl.action.netcacheEgress_set_and_get_latest;
        call leaf_netcacheEgress_set_and_get_latest();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_hdr_eg.fraginfo_hdr.cur_fragidx == 0bv16){
        leaf_netcacheEgress_access_latest_tbl.hit := true;
        leaf_netcacheEgress_access_latest_tbl.action_run := leaf_netcacheEgress_access_latest_tbl.action.netcacheEgress_set_and_get_latest;
        call leaf_netcacheEgress_set_and_get_latest();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 164bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_hdr_eg.fraginfo_hdr.cur_fragidx == 0bv16){
        leaf_netcacheEgress_access_latest_tbl.hit := true;
        leaf_netcacheEgress_access_latest_tbl.action_run := leaf_netcacheEgress_access_latest_tbl.action.netcacheEgress_reset_and_get_latest;
        call leaf_netcacheEgress_reset_and_get_latest();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_hdr_eg.fraginfo_hdr.cur_fragidx == 0bv16){
        leaf_netcacheEgress_access_latest_tbl.hit := true;
        leaf_netcacheEgress_access_latest_tbl.action_run := leaf_netcacheEgress_access_latest_tbl.action.netcacheEgress_reset_and_get_latest;
        call leaf_netcacheEgress_reset_and_get_latest();
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_access_latest_tbl.hit){
        leaf_netcacheEgress_access_latest_tbl.action_run := leaf_netcacheEgress_access_latest_tbl.action.netcacheEgress_reset_is_latest;
        call leaf_netcacheEgress_reset_is_latest();
        goto leaf_Exit;
    }

    leaf_Exit:
}

// leaf_Table leaf_netcacheEgress_access_savedseq_tbl
procedure {:inline 1} leaf_netcacheEgress_access_savedseq_tbl.apply()
	modifies leaf_hdr_eg.inswitch_hdr.is_cached, leaf_hdr_eg.op_hdr.optype, leaf_meta.is_latest, leaf_netcacheEgress_access_savedseq_tbl.action_run, leaf_netcacheEgress_access_savedseq_tbl.hit;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.inswitch_hdr.is_cached := leaf_hdr_eg.inswitch_hdr.is_cached;
    leaf_meta.is_latest := leaf_meta.is_latest;
    leaf_netcacheEgress_access_savedseq_tbl.hit := false;
    if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_savedseq_tbl.hit := true;
        leaf_netcacheEgress_access_savedseq_tbl.action_run := leaf_netcacheEgress_access_savedseq_tbl.action.netcacheEgress_set_and_get_savedseq;
        call leaf_netcacheEgress_set_and_get_savedseq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_savedseq_tbl.hit := true;
        leaf_netcacheEgress_access_savedseq_tbl.action_run := leaf_netcacheEgress_access_savedseq_tbl.action.netcacheEgress_set_and_get_savedseq;
        call leaf_netcacheEgress_set_and_get_savedseq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_savedseq_tbl.hit := true;
        leaf_netcacheEgress_access_savedseq_tbl.action_run := leaf_netcacheEgress_access_savedseq_tbl.action.netcacheEgress_set_and_get_savedseq;
        call leaf_netcacheEgress_set_and_get_savedseq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_savedseq_tbl.hit := true;
        leaf_netcacheEgress_access_savedseq_tbl.action_run := leaf_netcacheEgress_access_savedseq_tbl.action.netcacheEgress_set_and_get_savedseq;
        call leaf_netcacheEgress_set_and_get_savedseq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_savedseq_tbl.hit := true;
        leaf_netcacheEgress_access_savedseq_tbl.action_run := leaf_netcacheEgress_access_savedseq_tbl.action.netcacheEgress_set_and_get_savedseq;
        call leaf_netcacheEgress_set_and_get_savedseq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_savedseq_tbl.hit := true;
        leaf_netcacheEgress_access_savedseq_tbl.action_run := leaf_netcacheEgress_access_savedseq_tbl.action.netcacheEgress_set_and_get_savedseq;
        call leaf_netcacheEgress_set_and_get_savedseq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_access_savedseq_tbl.hit := true;
        leaf_netcacheEgress_access_savedseq_tbl.action_run := leaf_netcacheEgress_access_savedseq_tbl.action.netcacheEgress_set_and_get_savedseq;
        call leaf_netcacheEgress_set_and_get_savedseq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_savedseq_tbl.hit := true;
        leaf_netcacheEgress_access_savedseq_tbl.action_run := leaf_netcacheEgress_access_savedseq_tbl.action.netcacheEgress_set_and_get_savedseq;
        call leaf_netcacheEgress_set_and_get_savedseq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_savedseq_tbl.hit := true;
        leaf_netcacheEgress_access_savedseq_tbl.action_run := leaf_netcacheEgress_access_savedseq_tbl.action.netcacheEgress_set_and_get_savedseq;
        call leaf_netcacheEgress_set_and_get_savedseq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_access_savedseq_tbl.hit := true;
        leaf_netcacheEgress_access_savedseq_tbl.action_run := leaf_netcacheEgress_access_savedseq_tbl.action.netcacheEgress_set_and_get_savedseq;
        call leaf_netcacheEgress_set_and_get_savedseq();
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_access_savedseq_tbl.hit){
        leaf_netcacheEgress_access_savedseq_tbl.action_run := leaf_netcacheEgress_access_savedseq_tbl.action.NoAction_13;
        call leaf_NoAction_13();
        goto leaf_Exit;
    }

    leaf_Exit:
}

// leaf_Table leaf_netcacheEgress_access_seq_tbl
procedure {:inline 1} leaf_netcacheEgress_access_seq_tbl.apply()
	modifies leaf_hdr_eg.fraginfo_hdr.cur_fragidx, leaf_hdr_eg.op_hdr.optype, leaf_netcacheEgress_access_seq_tbl.action_run, leaf_netcacheEgress_access_seq_tbl.hit;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.fraginfo_hdr.cur_fragidx := leaf_hdr_eg.fraginfo_hdr.cur_fragidx;
    leaf_netcacheEgress_access_seq_tbl.hit := false;
    if(leaf_hdr_eg.op_hdr.optype == 5bv16 && leaf_hdr_eg.fraginfo_hdr.cur_fragidx == 0bv16){
        leaf_netcacheEgress_access_seq_tbl.hit := true;
        leaf_netcacheEgress_access_seq_tbl.action_run := leaf_netcacheEgress_access_seq_tbl.action.netcacheEgress_assign_seq;
        call leaf_netcacheEgress_assign_seq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 20bv16 && leaf_hdr_eg.fraginfo_hdr.cur_fragidx == 0bv16){
        leaf_netcacheEgress_access_seq_tbl.hit := true;
        leaf_netcacheEgress_access_seq_tbl.action_run := leaf_netcacheEgress_access_seq_tbl.action.netcacheEgress_assign_seq;
        call leaf_netcacheEgress_assign_seq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 164bv16 && leaf_hdr_eg.fraginfo_hdr.cur_fragidx == 0bv16){
        leaf_netcacheEgress_access_seq_tbl.hit := true;
        leaf_netcacheEgress_access_seq_tbl.action_run := leaf_netcacheEgress_access_seq_tbl.action.netcacheEgress_assign_seq;
        call leaf_netcacheEgress_assign_seq();
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_access_seq_tbl.hit){
        leaf_netcacheEgress_access_seq_tbl.action_run := leaf_netcacheEgress_access_seq_tbl.action.NoAction_12;
        call leaf_NoAction_12();
        goto leaf_Exit;
    }

    leaf_Exit:
}

// leaf_Table leaf_netcacheEgress_add_and_remove_value_header_tbl
procedure {:inline 1} leaf_netcacheEgress_add_and_remove_value_header_tbl.apply()
	modifies leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.vallen_hdr.vallen, leaf_isValid, leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run, leaf_netcacheEgress_add_and_remove_value_header_tbl.hit;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.vallen_hdr.vallen := leaf_hdr_eg.vallen_hdr.vallen;
    leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := false;
    if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_only_vallen;
        call leaf_netcacheEgress_add_only_vallen();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 1bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 8bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val1;
        call leaf_netcacheEgress_add_to_val1();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 9bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 16bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val2;
        call leaf_netcacheEgress_add_to_val2();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 17bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 24bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val3;
        call leaf_netcacheEgress_add_to_val3();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 25bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 32bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val4;
        call leaf_netcacheEgress_add_to_val4();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 33bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 40bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val5;
        call leaf_netcacheEgress_add_to_val5();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 41bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 48bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val6;
        call leaf_netcacheEgress_add_to_val6();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 49bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 56bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val7;
        call leaf_netcacheEgress_add_to_val7();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 57bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 64bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val8;
        call leaf_netcacheEgress_add_to_val8();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 65bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 72bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val9;
        call leaf_netcacheEgress_add_to_val9();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 73bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 80bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val10;
        call leaf_netcacheEgress_add_to_val10();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 81bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 88bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val11;
        call leaf_netcacheEgress_add_to_val11();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 89bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 96bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val12;
        call leaf_netcacheEgress_add_to_val12();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 97bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 104bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val13;
        call leaf_netcacheEgress_add_to_val13();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 105bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 112bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val14;
        call leaf_netcacheEgress_add_to_val14();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 113bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 120bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val15;
        call leaf_netcacheEgress_add_to_val15();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 121bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 128bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val16;
        call leaf_netcacheEgress_add_to_val16();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_only_vallen;
        call leaf_netcacheEgress_add_only_vallen();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 1bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 8bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val1;
        call leaf_netcacheEgress_add_to_val1();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 9bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 16bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val2;
        call leaf_netcacheEgress_add_to_val2();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 17bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 24bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val3;
        call leaf_netcacheEgress_add_to_val3();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 25bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 32bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val4;
        call leaf_netcacheEgress_add_to_val4();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 33bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 40bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val5;
        call leaf_netcacheEgress_add_to_val5();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 41bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 48bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val6;
        call leaf_netcacheEgress_add_to_val6();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 49bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 56bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val7;
        call leaf_netcacheEgress_add_to_val7();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 57bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 64bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val8;
        call leaf_netcacheEgress_add_to_val8();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 65bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 72bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val9;
        call leaf_netcacheEgress_add_to_val9();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 73bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 80bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val10;
        call leaf_netcacheEgress_add_to_val10();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 81bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 88bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val11;
        call leaf_netcacheEgress_add_to_val11();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 89bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 96bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val12;
        call leaf_netcacheEgress_add_to_val12();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 97bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 104bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val13;
        call leaf_netcacheEgress_add_to_val13();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 105bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 112bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val14;
        call leaf_netcacheEgress_add_to_val14();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 113bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 120bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val15;
        call leaf_netcacheEgress_add_to_val15();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 121bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 128bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val16;
        call leaf_netcacheEgress_add_to_val16();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_only_vallen;
        call leaf_netcacheEgress_add_only_vallen();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 1bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 8bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val1;
        call leaf_netcacheEgress_add_to_val1();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 9bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 16bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val2;
        call leaf_netcacheEgress_add_to_val2();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 17bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 24bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val3;
        call leaf_netcacheEgress_add_to_val3();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 25bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 32bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val4;
        call leaf_netcacheEgress_add_to_val4();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 33bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 40bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val5;
        call leaf_netcacheEgress_add_to_val5();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 41bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 48bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val6;
        call leaf_netcacheEgress_add_to_val6();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 49bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 56bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val7;
        call leaf_netcacheEgress_add_to_val7();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 57bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 64bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val8;
        call leaf_netcacheEgress_add_to_val8();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 65bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 72bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val9;
        call leaf_netcacheEgress_add_to_val9();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 73bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 80bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val10;
        call leaf_netcacheEgress_add_to_val10();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 81bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 88bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val11;
        call leaf_netcacheEgress_add_to_val11();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 89bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 96bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val12;
        call leaf_netcacheEgress_add_to_val12();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 97bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 104bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val13;
        call leaf_netcacheEgress_add_to_val13();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 105bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 112bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val14;
        call leaf_netcacheEgress_add_to_val14();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 113bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 120bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val15;
        call leaf_netcacheEgress_add_to_val15();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 121bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 128bv16))){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.hit := true;
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_add_to_val16;
        call leaf_netcacheEgress_add_to_val16();
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_add_and_remove_value_header_tbl.hit){
        leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run := leaf_netcacheEgress_add_and_remove_value_header_tbl.action.netcacheEgress_remove_all;
        call leaf_netcacheEgress_remove_all();
        goto leaf_Exit;
    }

    leaf_Exit:
}

// leaf_Action leaf_netcacheEgress_add_only_vallen
procedure {:inline 1} leaf_netcacheEgress_add_only_vallen()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_pktlen
procedure {:inline 1} leaf_netcacheEgress_add_pktlen(leaf_udplen_delta:bv16, leaf_iplen_delta:bv16)
	modifies leaf_hdr_eg.udp_hdr.hdrlen;
{
    leaf_hdr_eg.udp_hdr.hdrlen := add.bv16(leaf_hdr_eg.udp_hdr.hdrlen, leaf_udplen_delta);
}

// leaf_Action leaf_netcacheEgress_add_to_val1
procedure {:inline 1} leaf_netcacheEgress_add_to_val1()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_to_val10
procedure {:inline 1} leaf_netcacheEgress_add_to_val10()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_to_val11
procedure {:inline 1} leaf_netcacheEgress_add_to_val11()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_to_val12
procedure {:inline 1} leaf_netcacheEgress_add_to_val12()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_to_val13
procedure {:inline 1} leaf_netcacheEgress_add_to_val13()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_to_val14
procedure {:inline 1} leaf_netcacheEgress_add_to_val14()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_to_val15
procedure {:inline 1} leaf_netcacheEgress_add_to_val15()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_to_val16
procedure {:inline 1} leaf_netcacheEgress_add_to_val16()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_to_val2
procedure {:inline 1} leaf_netcacheEgress_add_to_val2()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_to_val3
procedure {:inline 1} leaf_netcacheEgress_add_to_val3()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_to_val4
procedure {:inline 1} leaf_netcacheEgress_add_to_val4()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_to_val5
procedure {:inline 1} leaf_netcacheEgress_add_to_val5()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_to_val6
procedure {:inline 1} leaf_netcacheEgress_add_to_val6()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_to_val7
procedure {:inline 1} leaf_netcacheEgress_add_to_val7()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_to_val8
procedure {:inline 1} leaf_netcacheEgress_add_to_val8()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_add_to_val9
procedure {:inline 1} leaf_netcacheEgress_add_to_val9()
	modifies leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_assign_seq
procedure {:inline 1} leaf_netcacheEgress_assign_seq()
{
}

// leaf_Table leaf_netcacheEgress_bypass_egress_tbl
procedure {:inline 1} leaf_netcacheEgress_bypass_egress_tbl.apply()
	modifies leaf_hdr_eg.op_hdr.optype, leaf_meta.bypass_egress, leaf_meta.spine_sid, leaf_netcacheEgress_bypass_egress_tbl.action_run, leaf_netcacheEgress_bypass_egress_tbl.hit;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_meta.spine_sid := leaf_meta.spine_sid;
    leaf_netcacheEgress_bypass_egress_tbl.hit := false;
    if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_meta.spine_sid == 0bv10){
        leaf_netcacheEgress_bypass_egress_tbl.hit := true;
        leaf_netcacheEgress_bypass_egress_tbl.action_run := leaf_netcacheEgress_bypass_egress_tbl.action.netcacheEgress_set_bypass_egress;
        call leaf_netcacheEgress_set_bypass_egress();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 59bv16 && leaf_meta.spine_sid == 0bv10){
        leaf_netcacheEgress_bypass_egress_tbl.hit := true;
        leaf_netcacheEgress_bypass_egress_tbl.action_run := leaf_netcacheEgress_bypass_egress_tbl.action.netcacheEgress_set_bypass_egress;
        call leaf_netcacheEgress_set_bypass_egress();
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_bypass_egress_tbl.hit){
        leaf_netcacheEgress_bypass_egress_tbl.action_run := leaf_netcacheEgress_bypass_egress_tbl.action.NoAction_47;
        call leaf_NoAction_47();
        goto leaf_Exit;
    }

    leaf_Exit:
}
function {:inline true}leaf_netcacheEgress_cm1_reg.read(leaf_reg:[bv32]bv16, leaf_index:bv32)returns (bv16) {leaf_reg[leaf_index]}
procedure {:inline 1} leaf_netcacheEgress_cm1_reg.write(leaf_index:bv32, leaf_value:bv16)
	modifies leaf_netcacheEgress_cm1_reg, leaf_netcacheEgress_cm1_reg__last0_old_value, leaf_netcacheEgress_cm1_reg__last0_value, leaf_netcacheEgress_cm1_reg__last_index, leaf_netcacheEgress_cm1_reg__last_old_value, leaf_netcacheEgress_cm1_reg__last_value, leaf_netcacheEgress_cm1_reg__last_write_site, leaf_netcacheEgress_cm1_reg__wrote_any, leaf_netcacheEgress_cm1_reg__wrote_index0;
{
    leaf_netcacheEgress_cm1_reg__last_old_value := leaf_netcacheEgress_cm1_reg[leaf_index];
    leaf_netcacheEgress_cm1_reg[leaf_index] := leaf_value;
    leaf_netcacheEgress_cm1_reg__last_index := leaf_index;
    leaf_netcacheEgress_cm1_reg__last_value := leaf_value;
    leaf_netcacheEgress_cm1_reg__last_write_site := leaf_netcacheEgress_cm1_reg__next_write_site;
    leaf_netcacheEgress_cm1_reg__wrote_any := true;
    if (leaf_index == 0bv32) {
        leaf_netcacheEgress_cm1_reg__wrote_index0 := true;
        leaf_netcacheEgress_cm1_reg__last0_old_value := leaf_netcacheEgress_cm1_reg__last_old_value;
        leaf_netcacheEgress_cm1_reg__last0_value := leaf_value;
    }
}
function {:inline true}leaf_netcacheEgress_cm2_reg.read(leaf_reg:[bv32]bv16, leaf_index:bv32)returns (bv16) {leaf_reg[leaf_index]}
procedure {:inline 1} leaf_netcacheEgress_cm2_reg.write(leaf_index:bv32, leaf_value:bv16)
	modifies leaf_netcacheEgress_cm2_reg, leaf_netcacheEgress_cm2_reg__last0_old_value, leaf_netcacheEgress_cm2_reg__last0_value, leaf_netcacheEgress_cm2_reg__last_index, leaf_netcacheEgress_cm2_reg__last_old_value, leaf_netcacheEgress_cm2_reg__last_value, leaf_netcacheEgress_cm2_reg__last_write_site, leaf_netcacheEgress_cm2_reg__wrote_any, leaf_netcacheEgress_cm2_reg__wrote_index0;
{
    leaf_netcacheEgress_cm2_reg__last_old_value := leaf_netcacheEgress_cm2_reg[leaf_index];
    leaf_netcacheEgress_cm2_reg[leaf_index] := leaf_value;
    leaf_netcacheEgress_cm2_reg__last_index := leaf_index;
    leaf_netcacheEgress_cm2_reg__last_value := leaf_value;
    leaf_netcacheEgress_cm2_reg__last_write_site := leaf_netcacheEgress_cm2_reg__next_write_site;
    leaf_netcacheEgress_cm2_reg__wrote_any := true;
    if (leaf_index == 0bv32) {
        leaf_netcacheEgress_cm2_reg__wrote_index0 := true;
        leaf_netcacheEgress_cm2_reg__last0_old_value := leaf_netcacheEgress_cm2_reg__last_old_value;
        leaf_netcacheEgress_cm2_reg__last0_value := leaf_value;
    }
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
function {:inline true}leaf_netcacheEgress_deleted_reg.read(leaf_reg:[bv32]bv1, leaf_index:bv32)returns (bv1) {leaf_reg[leaf_index]}
procedure {:inline 1} leaf_netcacheEgress_deleted_reg.write(leaf_index:bv32, leaf_value:bv1)
	modifies leaf_netcacheEgress_deleted_reg, leaf_netcacheEgress_deleted_reg__last0_old_value, leaf_netcacheEgress_deleted_reg__last0_value, leaf_netcacheEgress_deleted_reg__last_index, leaf_netcacheEgress_deleted_reg__last_old_value, leaf_netcacheEgress_deleted_reg__last_value, leaf_netcacheEgress_deleted_reg__last_write_site, leaf_netcacheEgress_deleted_reg__wrote_any, leaf_netcacheEgress_deleted_reg__wrote_index0;
{
    leaf_netcacheEgress_deleted_reg__last_old_value := leaf_netcacheEgress_deleted_reg[leaf_index];
    leaf_netcacheEgress_deleted_reg[leaf_index] := leaf_value;
    leaf_netcacheEgress_deleted_reg__last_index := leaf_index;
    leaf_netcacheEgress_deleted_reg__last_value := leaf_value;
    leaf_netcacheEgress_deleted_reg__last_write_site := leaf_netcacheEgress_deleted_reg__next_write_site;
    leaf_netcacheEgress_deleted_reg__wrote_any := true;
    if (leaf_index == 0bv32) {
        leaf_netcacheEgress_deleted_reg__wrote_index0 := true;
        leaf_netcacheEgress_deleted_reg__last0_old_value := leaf_netcacheEgress_deleted_reg__last_old_value;
        leaf_netcacheEgress_deleted_reg__last0_value := leaf_value;
    }
}

// leaf_Table leaf_netcacheEgress_eg_port_forward_tbl
procedure {:inline 1} leaf_netcacheEgress_eg_port_forward_tbl.apply()
	modifies leaf_drop, leaf_hdr_eg.clone_hdr.clonenum_for_pktloss, leaf_hdr_eg.clone_hdr.server_sid, leaf_hdr_eg.inswitch_hdr.client_sid, leaf_hdr_eg.inswitch_hdr.is_cached, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.stat_hdr.nodeidx_foreval, leaf_hdr_eg.stat_hdr.stat, leaf_hdr_eg.udp_hdr.dstPort, leaf_hdr_eg.udp_hdr.srcPort, leaf_isValid, leaf_meta.is_deleted, leaf_meta.is_hot, leaf_meta.is_lastclone_for_pktloss, leaf_meta.is_latest, leaf_meta.is_report, leaf_netcacheEgress_eg_port_forward_tbl.action_run, leaf_netcacheEgress_eg_port_forward_tbl.hit, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_9, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid_7, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.reflector_port_7, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.switchos_sid_11, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_6, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_10, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_12, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_getreq_pop_to_getreq_by_mirroring.server_sid_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.client_sid_4, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.server_port, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.reflector_port, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid, leaf_p4b_clone_i2e;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.inswitch_hdr.is_cached := leaf_hdr_eg.inswitch_hdr.is_cached;
    leaf_meta.is_hot := leaf_meta.is_hot;
    leaf_meta.is_report := leaf_meta.is_report;
    leaf_meta.is_latest := leaf_meta.is_latest;
    leaf_meta.is_deleted := leaf_meta.is_deleted;
    leaf_hdr_eg.inswitch_hdr.client_sid := leaf_hdr_eg.inswitch_hdr.client_sid;
    leaf_meta.is_lastclone_for_pktloss := leaf_meta.is_lastclone_for_pktloss;
    leaf_hdr_eg.clone_hdr.server_sid := leaf_hdr_eg.clone_hdr.server_sid;
    leaf_netcacheEgress_eg_port_forward_tbl.hit := false;
    if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_10 := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_6 := 5008bv16;
        call leaf_netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_10, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_6);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_12 := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_8 := 5008bv16;
        call leaf_netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_12, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_8);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 5bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_putreq_inswitch_to_putreq_seq;
        call leaf_netcacheEgress_update_putreq_inswitch_to_putreq_seq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 20bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_delreq_inswitch_to_delreq_seq;
        call leaf_netcacheEgress_update_delreq_inswitch_to_delreq_seq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack;
        call leaf_netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 164bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_putreq_largevalue_inswitch_to_putreq_largevalue_seq;
        call leaf_netcacheEgress_update_putreq_largevalue_inswitch_to_putreq_largevalue_seq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 288bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_forward_netcache_getreq_pop_clone_for_pktloss_and_getreq;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_9 := 20bv10;
        call leaf_netcacheEgress_forward_netcache_getreq_pop_clone_for_pktloss_and_getreq(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_9);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 288bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 1bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_getreq_pop_to_getreq_by_mirroring;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_getreq_pop_to_getreq_by_mirroring.server_sid_3 := 20bv10;
        call leaf_netcacheEgress_update_netcache_getreq_pop_to_getreq_by_mirroring(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_getreq_pop_to_getreq_by_mirroring.server_sid_3);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 100bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.reflector_port := 5008bv16;
        call leaf_netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.reflector_port);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 116bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid_7 := 20bv10;
        call leaf_netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid_7);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 116bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 1bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.client_sid_4 := 10bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.server_port := 1152bv16;
        call leaf_netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.client_sid_4, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.server_port);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_10 := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_6 := 5008bv16;
        call leaf_netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_10, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_6);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_12 := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_8 := 5008bv16;
        call leaf_netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_12, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_8);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack;
        call leaf_netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_10 := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_6 := 5008bv16;
        call leaf_netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_10, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_6);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_12 := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_8 := 5008bv16;
        call leaf_netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_12, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_8);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 5bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_putreq_inswitch_to_putreq_seq;
        call leaf_netcacheEgress_update_putreq_inswitch_to_putreq_seq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 20bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_delreq_inswitch_to_delreq_seq;
        call leaf_netcacheEgress_update_delreq_inswitch_to_delreq_seq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack;
        call leaf_netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 164bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_putreq_largevalue_inswitch_to_putreq_largevalue_seq;
        call leaf_netcacheEgress_update_putreq_largevalue_inswitch_to_putreq_largevalue_seq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_10 := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_6 := 5008bv16;
        call leaf_netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_10, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_6);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_12 := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_8 := 5008bv16;
        call leaf_netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_12, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_8);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack;
        call leaf_netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8 := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5 := 5008bv16;
        call leaf_netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8 := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5 := 5008bv16;
        call leaf_netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8 := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5 := 5008bv16;
        call leaf_netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8 := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5 := 5008bv16;
        call leaf_netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 5bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_putreq_inswitch_to_netcache_putreq_seq_cached;
        call leaf_netcacheEgress_update_putreq_inswitch_to_netcache_putreq_seq_cached();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 20bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_delreq_inswitch_to_netcache_delreq_seq_cached;
        call leaf_netcacheEgress_update_delreq_inswitch_to_netcache_delreq_seq_cached();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 36bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.switchos_sid_11 := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.reflector_port_7 := 5008bv16;
        call leaf_netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.switchos_sid_11, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.reflector_port_7);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack;
        call leaf_netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 164bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_putreq_largevalue_inswitch_to_putreq_largevalue_seq_cached;
        call leaf_netcacheEgress_update_putreq_largevalue_inswitch_to_putreq_largevalue_seq_cached();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 100bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.reflector_port := 5008bv16;
        call leaf_netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.reflector_port);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 116bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid_7 := 20bv10;
        call leaf_netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid_7);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 116bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 1bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.client_sid_4 := 10bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.server_port := 1152bv16;
        call leaf_netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.client_sid_4, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.server_port);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack;
        call leaf_netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 5bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_putreq_inswitch_to_netcache_putreq_seq_cached;
        call leaf_netcacheEgress_update_putreq_inswitch_to_netcache_putreq_seq_cached();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 20bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_delreq_inswitch_to_netcache_delreq_seq_cached;
        call leaf_netcacheEgress_update_delreq_inswitch_to_netcache_delreq_seq_cached();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack;
        call leaf_netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 164bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_putreq_largevalue_inswitch_to_putreq_largevalue_seq_cached;
        call leaf_netcacheEgress_update_putreq_largevalue_inswitch_to_putreq_largevalue_seq_cached();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5 := 10bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3 := 1152bv16;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1 := 1bv8;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 0bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 0bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack;
        call leaf_netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5 := 10bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3 := 1152bv16;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1 := 0bv8;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5 := 10bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3 := 1152bv16;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1 := 1bv8;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 0bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5 := 10bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3 := 1152bv16;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1 := 0bv8;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8 := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5 := 5008bv16;
        call leaf_netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8 := 20bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5 := 5008bv16;
        call leaf_netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5 := 10bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3 := 1152bv16;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1 := 1bv8;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 0bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5 := 10bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3 := 1152bv16;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1 := 0bv8;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 0bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getreq;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getreq();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 0bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5 := 10bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3 := 1152bv16;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1 := 1bv8;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_hot == 1bv1 && leaf_meta.is_report == 1bv1 && leaf_meta.is_latest == 1bv1 && leaf_meta.is_deleted == 1bv1 && leaf_hdr_eg.inswitch_hdr.client_sid == 10bv10 && leaf_meta.is_lastclone_for_pktloss == 0bv1 && leaf_hdr_eg.clone_hdr.server_sid == 20bv10){
        leaf_netcacheEgress_eg_port_forward_tbl.hit := true;
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5 := 10bv10;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3 := 1152bv16;
        leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1 := 0bv8;
        call leaf_netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring(leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1);
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_eg_port_forward_tbl.hit){
        leaf_netcacheEgress_eg_port_forward_tbl.action_run := leaf_netcacheEgress_eg_port_forward_tbl.action.NoAction_50;
        call leaf_NoAction_50();
        goto leaf_Exit;
    }

    leaf_Exit:
}

// leaf_Action leaf_netcacheEgress_forward_netcache_getreq_pop_clone_for_pktloss_and_getreq
procedure {:inline 1} leaf_netcacheEgress_forward_netcache_getreq_pop_clone_for_pktloss_and_getreq(leaf_switchos_sid_9:bv10)
	modifies leaf_hdr_eg.clone_hdr.clonenum_for_pktloss, leaf_p4b_clone_i2e;
{
    leaf_hdr_eg.clone_hdr.clonenum_for_pktloss := add.bv16(leaf_hdr_eg.clone_hdr.clonenum_for_pktloss, 65535bv16);
    leaf_p4b_clone_i2e := true;
}

// leaf_Action leaf_netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack
procedure {:inline 1} leaf_netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack(leaf_switchos_sid_7:bv10)
	modifies leaf_hdr_eg.clone_hdr.clonenum_for_pktloss, leaf_p4b_clone_i2e;
{
    leaf_hdr_eg.clone_hdr.clonenum_for_pktloss := add.bv16(leaf_hdr_eg.clone_hdr.clonenum_for_pktloss, 65535bv16);
    leaf_p4b_clone_i2e := true;
}

// leaf_Action leaf_netcacheEgress_get_cache_frequency
procedure {:inline 1} leaf_netcacheEgress_get_cache_frequency()
{
}

// leaf_Action leaf_netcacheEgress_get_deleted
procedure {:inline 1} leaf_netcacheEgress_get_deleted()
	modifies leaf_meta.is_deleted;
{
    // leaf_read
    leaf_meta.is_deleted := leaf_netcacheEgress_deleted_reg.read(leaf_netcacheEgress_deleted_reg, 0bv16++leaf_hdr_eg.inswitch_hdr.idx);
}

// leaf_Action leaf_netcacheEgress_get_latest
procedure {:inline 1} leaf_netcacheEgress_get_latest()
	modifies leaf_meta.is_latest;
{
    // leaf_read
    leaf_meta.is_latest := leaf_netcacheEgress_latest_reg.read(leaf_netcacheEgress_latest_reg, 0bv16++leaf_hdr_eg.inswitch_hdr.idx);
}

// leaf_Action leaf_netcacheEgress_get_vallen
procedure {:inline 1} leaf_netcacheEgress_get_vallen()
	modifies leaf_hdr_eg.vallen_hdr.vallen, leaf_isValid;
{
    call leaf_setValid(leaf_hdr_eg.vallen_hdr);
    // leaf_read
    leaf_hdr_eg.vallen_hdr.vallen := leaf_netcacheEgress_vallen_reg.read(leaf_netcacheEgress_vallen_reg, 0bv16++leaf_hdr_eg.inswitch_hdr.idx);
}

// leaf_Action leaf_netcacheEgress_initialize_cm1_predicate
procedure {:inline 1} leaf_netcacheEgress_initialize_cm1_predicate()
	modifies leaf_meta.cm1_predicate;
{
    leaf_meta.cm1_predicate := 1bv4;
}

// leaf_Action leaf_netcacheEgress_initialize_cm2_predicate
procedure {:inline 1} leaf_netcacheEgress_initialize_cm2_predicate()
	modifies leaf_meta.cm2_predicate;
{
    leaf_meta.cm2_predicate := 1bv4;
}

// leaf_Action leaf_netcacheEgress_initialize_cm3_predicate
procedure {:inline 1} leaf_netcacheEgress_initialize_cm3_predicate()
	modifies leaf_meta.cm3_predicate;
{
    leaf_meta.cm3_predicate := 1bv4;
}

// leaf_Action leaf_netcacheEgress_initialize_cm4_predicate
procedure {:inline 1} leaf_netcacheEgress_initialize_cm4_predicate()
	modifies leaf_meta.cm4_predicate;
{
    leaf_meta.cm4_predicate := 1bv4;
}

// leaf_Table leaf_netcacheEgress_is_hot_tbl
procedure {:inline 1} leaf_netcacheEgress_is_hot_tbl.apply()
	modifies leaf_meta.cm1_predicate, leaf_meta.cm2_predicate, leaf_meta.cm3_predicate, leaf_meta.cm4_predicate, leaf_meta.is_hot, leaf_netcacheEgress_is_hot_tbl.action_run, leaf_netcacheEgress_is_hot_tbl.hit;
{
    leaf_meta.cm1_predicate := leaf_meta.cm1_predicate;
    leaf_meta.cm2_predicate := leaf_meta.cm2_predicate;
    leaf_meta.cm3_predicate := leaf_meta.cm3_predicate;
    leaf_meta.cm4_predicate := leaf_meta.cm4_predicate;
    leaf_netcacheEgress_is_hot_tbl.hit := false;
    if(leaf_meta.cm1_predicate == 2bv4 && leaf_meta.cm2_predicate == 2bv4 && leaf_meta.cm3_predicate == 2bv4 && leaf_meta.cm4_predicate == 2bv4){
        leaf_netcacheEgress_is_hot_tbl.hit := true;
        leaf_netcacheEgress_is_hot_tbl.action_run := leaf_netcacheEgress_is_hot_tbl.action.netcacheEgress_set_is_hot;
        call leaf_netcacheEgress_set_is_hot();
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_is_hot_tbl.hit){
        leaf_netcacheEgress_is_hot_tbl.action_run := leaf_netcacheEgress_is_hot_tbl.action.netcacheEgress_reset_is_hot;
        call leaf_netcacheEgress_reset_is_hot();
        goto leaf_Exit;
    }

    leaf_Exit:
}

// leaf_Table leaf_netcacheEgress_is_report_tbl
procedure {:inline 1} leaf_netcacheEgress_is_report_tbl.apply()
	modifies leaf_meta.is_report, leaf_meta.is_report1, leaf_meta.is_report2, leaf_meta.is_report3, leaf_netcacheEgress_is_report_tbl.action_run, leaf_netcacheEgress_is_report_tbl.hit;
{
    leaf_meta.is_report1 := leaf_meta.is_report1;
    leaf_meta.is_report2 := leaf_meta.is_report2;
    leaf_meta.is_report3 := leaf_meta.is_report3;
    leaf_netcacheEgress_is_report_tbl.hit := false;
    if(leaf_meta.is_report1 == 1bv1 && leaf_meta.is_report2 == 1bv1 && leaf_meta.is_report3 == 1bv1){
        leaf_netcacheEgress_is_report_tbl.hit := true;
        leaf_netcacheEgress_is_report_tbl.action_run := leaf_netcacheEgress_is_report_tbl.action.netcacheEgress_set_is_report;
        call leaf_netcacheEgress_set_is_report();
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_is_report_tbl.hit){
        leaf_netcacheEgress_is_report_tbl.action_run := leaf_netcacheEgress_is_report_tbl.action.netcacheEgress_reset_is_report;
        call leaf_netcacheEgress_reset_is_report();
        goto leaf_Exit;
    }

    leaf_Exit:
}

// leaf_Table leaf_netcacheEgress_lastclone_lastscansplit_tbl
procedure {:inline 1} leaf_netcacheEgress_lastclone_lastscansplit_tbl.apply()
	modifies leaf_hdr_eg.clone_hdr.clonenum_for_pktloss, leaf_hdr_eg.op_hdr.optype, leaf_meta.is_lastclone_for_pktloss, leaf_netcacheEgress_lastclone_lastscansplit_tbl.action_run, leaf_netcacheEgress_lastclone_lastscansplit_tbl.hit;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.clone_hdr.clonenum_for_pktloss := leaf_hdr_eg.clone_hdr.clonenum_for_pktloss;
    leaf_netcacheEgress_lastclone_lastscansplit_tbl.hit := false;
    if(leaf_hdr_eg.op_hdr.optype == 288bv16 && leaf_hdr_eg.clone_hdr.clonenum_for_pktloss == 0bv16){
        leaf_netcacheEgress_lastclone_lastscansplit_tbl.hit := true;
        leaf_netcacheEgress_lastclone_lastscansplit_tbl.action_run := leaf_netcacheEgress_lastclone_lastscansplit_tbl.action.netcacheEgress_set_is_lastclone;
        call leaf_netcacheEgress_set_is_lastclone();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 116bv16 && leaf_hdr_eg.clone_hdr.clonenum_for_pktloss == 0bv16){
        leaf_netcacheEgress_lastclone_lastscansplit_tbl.hit := true;
        leaf_netcacheEgress_lastclone_lastscansplit_tbl.action_run := leaf_netcacheEgress_lastclone_lastscansplit_tbl.action.netcacheEgress_set_is_lastclone;
        call leaf_netcacheEgress_set_is_lastclone();
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_lastclone_lastscansplit_tbl.hit){
        leaf_netcacheEgress_lastclone_lastscansplit_tbl.action_run := leaf_netcacheEgress_lastclone_lastscansplit_tbl.action.netcacheEgress_reset_is_lastclone_lastscansplit;
        call leaf_netcacheEgress_reset_is_lastclone_lastscansplit();
        goto leaf_Exit;
    }

    leaf_Exit:
}
function {:inline true}leaf_netcacheEgress_latest_reg.read(leaf_reg:[bv32]bv1, leaf_index:bv32)returns (bv1) {leaf_reg[leaf_index]}
procedure {:inline 1} leaf_netcacheEgress_latest_reg.write(leaf_index:bv32, leaf_value:bv1)
	modifies leaf_netcacheEgress_latest_reg, leaf_netcacheEgress_latest_reg__last0_old_value, leaf_netcacheEgress_latest_reg__last0_value, leaf_netcacheEgress_latest_reg__last_index, leaf_netcacheEgress_latest_reg__last_old_value, leaf_netcacheEgress_latest_reg__last_value, leaf_netcacheEgress_latest_reg__last_write_site, leaf_netcacheEgress_latest_reg__wrote_any, leaf_netcacheEgress_latest_reg__wrote_index0;
{
    leaf_netcacheEgress_latest_reg__last_old_value := leaf_netcacheEgress_latest_reg[leaf_index];
    leaf_netcacheEgress_latest_reg[leaf_index] := leaf_value;
    leaf_netcacheEgress_latest_reg__last_index := leaf_index;
    leaf_netcacheEgress_latest_reg__last_value := leaf_value;
    leaf_netcacheEgress_latest_reg__last_write_site := leaf_netcacheEgress_latest_reg__next_write_site;
    leaf_netcacheEgress_latest_reg__wrote_any := true;
    if (leaf_index == 0bv32) {
        leaf_netcacheEgress_latest_reg__wrote_index0 := true;
        leaf_netcacheEgress_latest_reg__last0_old_value := leaf_netcacheEgress_latest_reg__last_old_value;
        leaf_netcacheEgress_latest_reg__last0_value := leaf_value;
    }
}

// leaf_Table leaf_netcacheEgress_prepare_for_cachepop_tbl
procedure {:inline 1} leaf_netcacheEgress_prepare_for_cachepop_tbl.apply()
	modifies leaf_hdr_eg.clone_hdr.server_sid, leaf_hdr_eg.clone_hdr.server_udpport, leaf_hdr_eg.op_hdr.optype, leaf_isValid, leaf_netcacheEgress_prepare_for_cachepop_tbl.action_run, leaf_netcacheEgress_prepare_for_cachepop_tbl.hit, leaf_netcacheEgress_prepare_for_cachepop_tbl.netcacheEgress_set_server_sid_and_port.server_sid_2, leaf_standard_metadata.egress_port;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_standard_metadata.egress_port := leaf_standard_metadata.egress_port;
    leaf_netcacheEgress_prepare_for_cachepop_tbl.hit := false;
    if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_standard_metadata.egress_port == 4bv9){
        leaf_netcacheEgress_prepare_for_cachepop_tbl.hit := true;
        leaf_netcacheEgress_prepare_for_cachepop_tbl.action_run := leaf_netcacheEgress_prepare_for_cachepop_tbl.action.netcacheEgress_set_server_sid_and_port;
        leaf_netcacheEgress_prepare_for_cachepop_tbl.netcacheEgress_set_server_sid_and_port.server_sid_2 := 20bv10;
        call leaf_netcacheEgress_set_server_sid_and_port(leaf_netcacheEgress_prepare_for_cachepop_tbl.netcacheEgress_set_server_sid_and_port.server_sid_2);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 288bv16 && leaf_standard_metadata.egress_port == 4bv9){
        leaf_netcacheEgress_prepare_for_cachepop_tbl.hit := true;
        leaf_netcacheEgress_prepare_for_cachepop_tbl.action_run := leaf_netcacheEgress_prepare_for_cachepop_tbl.action.NoAction_49;
        call leaf_NoAction_49();
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_prepare_for_cachepop_tbl.hit){
        leaf_netcacheEgress_prepare_for_cachepop_tbl.action_run := leaf_netcacheEgress_prepare_for_cachepop_tbl.action.netcacheEgress_reset_server_sid;
        call leaf_netcacheEgress_reset_server_sid();
        goto leaf_Exit;
    }

    leaf_Exit:
}

// leaf_Action leaf_netcacheEgress_remove_all
procedure {:inline 1} leaf_netcacheEgress_remove_all()
	modifies leaf_isValid;
{
    call leaf_setInvalid(leaf_hdr_eg.vallen_hdr);
}

// leaf_Action leaf_netcacheEgress_reset_access_val_mode
procedure {:inline 1} leaf_netcacheEgress_reset_access_val_mode()
{
}

// leaf_Action leaf_netcacheEgress_reset_and_get_deleted
procedure {:inline 1} leaf_netcacheEgress_reset_and_get_deleted()
	modifies leaf_meta.is_deleted, leaf_netcacheEgress_deleted_reg, leaf_netcacheEgress_deleted_reg__last0_old_value, leaf_netcacheEgress_deleted_reg__last0_value, leaf_netcacheEgress_deleted_reg__last_index, leaf_netcacheEgress_deleted_reg__last_old_value, leaf_netcacheEgress_deleted_reg__last_value, leaf_netcacheEgress_deleted_reg__last_write_site, leaf_netcacheEgress_deleted_reg__next_write_site, leaf_netcacheEgress_deleted_reg__wrote_any, leaf_netcacheEgress_deleted_reg__wrote_index0;
{
    // leaf_write
    leaf_netcacheEgress_deleted_reg__next_write_site := 2;
    call leaf_netcacheEgress_deleted_reg.write(0bv16++leaf_hdr_eg.inswitch_hdr.idx, 0bv1);
    leaf_meta.is_deleted := 0bv1;
}

// leaf_Action leaf_netcacheEgress_reset_and_get_latest
procedure {:inline 1} leaf_netcacheEgress_reset_and_get_latest()
	modifies leaf_meta.is_latest, leaf_netcacheEgress_latest_reg, leaf_netcacheEgress_latest_reg__last0_old_value, leaf_netcacheEgress_latest_reg__last0_value, leaf_netcacheEgress_latest_reg__last_index, leaf_netcacheEgress_latest_reg__last_old_value, leaf_netcacheEgress_latest_reg__last_value, leaf_netcacheEgress_latest_reg__last_write_site, leaf_netcacheEgress_latest_reg__next_write_site, leaf_netcacheEgress_latest_reg__wrote_any, leaf_netcacheEgress_latest_reg__wrote_index0;
{
    // leaf_write
    leaf_netcacheEgress_latest_reg__next_write_site := 2;
    call leaf_netcacheEgress_latest_reg.write(0bv16++leaf_hdr_eg.inswitch_hdr.idx, 0bv1);
    leaf_meta.is_latest := 0bv1;
}

// leaf_Action leaf_netcacheEgress_reset_cache_frequency
procedure {:inline 1} leaf_netcacheEgress_reset_cache_frequency()
{
}

// leaf_Action leaf_netcacheEgress_reset_is_deleted
procedure {:inline 1} leaf_netcacheEgress_reset_is_deleted()
	modifies leaf_meta.is_deleted;
{
    leaf_meta.is_deleted := 0bv1;
}

// leaf_Action leaf_netcacheEgress_reset_is_hot
procedure {:inline 1} leaf_netcacheEgress_reset_is_hot()
	modifies leaf_meta.is_hot;
{
    leaf_meta.is_hot := 0bv1;
}

// leaf_Action leaf_netcacheEgress_reset_is_lastclone_lastscansplit
procedure {:inline 1} leaf_netcacheEgress_reset_is_lastclone_lastscansplit()
	modifies leaf_meta.is_lastclone_for_pktloss;
{
    leaf_meta.is_lastclone_for_pktloss := 0bv1;
}

// leaf_Action leaf_netcacheEgress_reset_is_latest
procedure {:inline 1} leaf_netcacheEgress_reset_is_latest()
	modifies leaf_meta.is_latest;
{
    leaf_meta.is_latest := 0bv1;
}

// leaf_Action leaf_netcacheEgress_reset_is_report
procedure {:inline 1} leaf_netcacheEgress_reset_is_report()
	modifies leaf_meta.is_report;
{
    leaf_meta.is_report := 0bv1;
}

// leaf_Action leaf_netcacheEgress_reset_is_report1
procedure {:inline 1} leaf_netcacheEgress_reset_is_report1()
	modifies leaf_meta.is_report1;
{
    leaf_meta.is_report1 := 0bv1;
}

// leaf_Action leaf_netcacheEgress_reset_is_report2
procedure {:inline 1} leaf_netcacheEgress_reset_is_report2()
	modifies leaf_meta.is_report2;
{
    leaf_meta.is_report2 := 0bv1;
}

// leaf_Action leaf_netcacheEgress_reset_is_report3
procedure {:inline 1} leaf_netcacheEgress_reset_is_report3()
	modifies leaf_meta.is_report3;
{
    leaf_meta.is_report3 := 0bv1;
}

// leaf_Action leaf_netcacheEgress_reset_server_sid
procedure {:inline 1} leaf_netcacheEgress_reset_server_sid()
	modifies leaf_hdr_eg.clone_hdr.server_sid;
{
    leaf_hdr_eg.clone_hdr.server_sid := 0bv10;
}

// leaf_Action leaf_netcacheEgress_save_client_udpport
procedure {:inline 1} leaf_netcacheEgress_save_client_udpport()
	modifies leaf_hdr_eg.clone_hdr.client_udpport;
{
    leaf_hdr_eg.clone_hdr.client_udpport := leaf_hdr_eg.udp_hdr.srcPort;
}

// leaf_Table leaf_netcacheEgress_save_client_udpport_tbl
procedure {:inline 1} leaf_netcacheEgress_save_client_udpport_tbl.apply()
	modifies leaf_hdr_eg.clone_hdr.client_udpport, leaf_hdr_eg.op_hdr.optype, leaf_netcacheEgress_save_client_udpport_tbl.action_run, leaf_netcacheEgress_save_client_udpport_tbl.hit;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_netcacheEgress_save_client_udpport_tbl.hit := false;
    if(leaf_hdr_eg.op_hdr.optype == 4bv16){
        leaf_netcacheEgress_save_client_udpport_tbl.hit := true;
        leaf_netcacheEgress_save_client_udpport_tbl.action_run := leaf_netcacheEgress_save_client_udpport_tbl.action.netcacheEgress_save_client_udpport;
        call leaf_netcacheEgress_save_client_udpport();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 100bv16){
        leaf_netcacheEgress_save_client_udpport_tbl.hit := true;
        leaf_netcacheEgress_save_client_udpport_tbl.action_run := leaf_netcacheEgress_save_client_udpport_tbl.action.netcacheEgress_save_client_udpport;
        call leaf_netcacheEgress_save_client_udpport();
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_save_client_udpport_tbl.hit){
        leaf_netcacheEgress_save_client_udpport_tbl.action_run := leaf_netcacheEgress_save_client_udpport_tbl.action.NoAction_48;
        call leaf_NoAction_48();
        goto leaf_Exit;
    }

    leaf_Exit:
}

// leaf_Action leaf_netcacheEgress_set_and_get_deleted
procedure {:inline 1} leaf_netcacheEgress_set_and_get_deleted()
	modifies leaf_meta.is_deleted, leaf_netcacheEgress_deleted_reg, leaf_netcacheEgress_deleted_reg__last0_old_value, leaf_netcacheEgress_deleted_reg__last0_value, leaf_netcacheEgress_deleted_reg__last_index, leaf_netcacheEgress_deleted_reg__last_old_value, leaf_netcacheEgress_deleted_reg__last_value, leaf_netcacheEgress_deleted_reg__last_write_site, leaf_netcacheEgress_deleted_reg__next_write_site, leaf_netcacheEgress_deleted_reg__wrote_any, leaf_netcacheEgress_deleted_reg__wrote_index0;
{
    // leaf_write
    leaf_netcacheEgress_deleted_reg__next_write_site := 1;
    call leaf_netcacheEgress_deleted_reg.write(0bv16++leaf_hdr_eg.inswitch_hdr.idx, 1bv1);
    leaf_meta.is_deleted := 1bv1;
}

// leaf_Action leaf_netcacheEgress_set_and_get_latest
procedure {:inline 1} leaf_netcacheEgress_set_and_get_latest()
	modifies leaf_meta.is_latest, leaf_netcacheEgress_latest_reg, leaf_netcacheEgress_latest_reg__last0_old_value, leaf_netcacheEgress_latest_reg__last0_value, leaf_netcacheEgress_latest_reg__last_index, leaf_netcacheEgress_latest_reg__last_old_value, leaf_netcacheEgress_latest_reg__last_value, leaf_netcacheEgress_latest_reg__last_write_site, leaf_netcacheEgress_latest_reg__next_write_site, leaf_netcacheEgress_latest_reg__wrote_any, leaf_netcacheEgress_latest_reg__wrote_index0;
{
    // leaf_write
    leaf_netcacheEgress_latest_reg__next_write_site := 1;
    call leaf_netcacheEgress_latest_reg.write(0bv16++leaf_hdr_eg.inswitch_hdr.idx, 1bv1);
    leaf_meta.is_latest := 1bv1;
}

// leaf_Action leaf_netcacheEgress_set_and_get_savedseq
procedure {:inline 1} leaf_netcacheEgress_set_and_get_savedseq()
{
}

// leaf_Action leaf_netcacheEgress_set_and_get_vallen
procedure {:inline 1} leaf_netcacheEgress_set_and_get_vallen()
	modifies leaf_netcacheEgress_vallen_reg, leaf_netcacheEgress_vallen_reg__last0_old_value, leaf_netcacheEgress_vallen_reg__last0_value, leaf_netcacheEgress_vallen_reg__last_index, leaf_netcacheEgress_vallen_reg__last_old_value, leaf_netcacheEgress_vallen_reg__last_value, leaf_netcacheEgress_vallen_reg__last_write_site, leaf_netcacheEgress_vallen_reg__next_write_site, leaf_netcacheEgress_vallen_reg__wrote_any, leaf_netcacheEgress_vallen_reg__wrote_index0;
{
    // leaf_write
    leaf_netcacheEgress_vallen_reg__next_write_site := 1;
    call leaf_netcacheEgress_vallen_reg.write(0bv16++leaf_hdr_eg.inswitch_hdr.idx, leaf_hdr_eg.vallen_hdr.vallen);
}

// leaf_Action leaf_netcacheEgress_set_bypass_egress
procedure {:inline 1} leaf_netcacheEgress_set_bypass_egress()
	modifies leaf_meta.bypass_egress;
{
    leaf_meta.bypass_egress := 1bv1;
}

// leaf_Action leaf_netcacheEgress_set_is_hot
procedure {:inline 1} leaf_netcacheEgress_set_is_hot()
	modifies leaf_meta.is_hot;
{
    leaf_meta.is_hot := 1bv1;
}

// leaf_Action leaf_netcacheEgress_set_is_lastclone
procedure {:inline 1} leaf_netcacheEgress_set_is_lastclone()
	modifies leaf_meta.is_lastclone_for_pktloss;
{
    leaf_meta.is_lastclone_for_pktloss := 1bv1;
}

// leaf_Action leaf_netcacheEgress_set_is_report
procedure {:inline 1} leaf_netcacheEgress_set_is_report()
	modifies leaf_meta.is_report;
{
    leaf_meta.is_report := 1bv1;
}

// leaf_Action leaf_netcacheEgress_set_server_sid_and_port
procedure {:inline 1} leaf_netcacheEgress_set_server_sid_and_port(leaf_server_sid_2:bv10)
	modifies leaf_hdr_eg.clone_hdr.server_sid, leaf_hdr_eg.clone_hdr.server_udpport, leaf_isValid;
{
    leaf_hdr_eg.clone_hdr.server_sid := leaf_server_sid_2;
    leaf_hdr_eg.clone_hdr.server_udpport := leaf_hdr_eg.udp_hdr.dstPort;
    call leaf_setValid(leaf_hdr_eg.clone_hdr);
}

// leaf_Action leaf_netcacheEgress_update_bf1
procedure {:inline 1} leaf_netcacheEgress_update_bf1()
	modifies leaf_meta.is_report1;
{
    leaf_meta.is_report1 := 1bv1;
}

// leaf_Action leaf_netcacheEgress_update_bf2
procedure {:inline 1} leaf_netcacheEgress_update_bf2()
	modifies leaf_meta.is_report2;
{
    leaf_meta.is_report2 := 1bv1;
}

// leaf_Action leaf_netcacheEgress_update_bf3
procedure {:inline 1} leaf_netcacheEgress_update_bf3()
	modifies leaf_meta.is_report3;
{
    leaf_meta.is_report3 := 1bv1;
}

// leaf_Action leaf_netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone
procedure {:inline 1} leaf_netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone(leaf_switchos_sid_11:bv10, leaf_reflector_port_7:bv16)
	modifies leaf_drop, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.udp_hdr.dstPort, leaf_isValid, leaf_p4b_clone_i2e;
{
    leaf_hdr_eg.op_hdr.optype := 256bv16;
    leaf_hdr_eg.udp_hdr.dstPort := leaf_reflector_port_7;
    call leaf_setInvalid(leaf_hdr_eg.inswitch_hdr);
    call leaf_setInvalid(leaf_hdr_eg.clone_hdr);
    call leaf_mark_to_drop();
    leaf_p4b_clone_i2e := true;
}

// leaf_Action leaf_netcacheEgress_update_cache_frequency
procedure {:inline 1} leaf_netcacheEgress_update_cache_frequency()
{
}

// leaf_Action leaf_netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone
procedure {:inline 1} leaf_netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone(leaf_switchos_sid_10:bv10, leaf_reflector_port_6:bv16)
	modifies leaf_drop, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.udp_hdr.dstPort, leaf_isValid, leaf_p4b_clone_i2e;
{
    call leaf_setInvalid(leaf_hdr_eg.inswitch_hdr);
    call leaf_setInvalid(leaf_hdr_eg.stat_hdr);
    call leaf_setInvalid(leaf_hdr_eg.clone_hdr);
    leaf_hdr_eg.op_hdr.optype := 112bv16;
    leaf_hdr_eg.udp_hdr.dstPort := leaf_reflector_port_6;
    call leaf_mark_to_drop();
    leaf_p4b_clone_i2e := true;
}

// leaf_Action leaf_netcacheEgress_update_cm1
procedure {:inline 1} leaf_netcacheEgress_update_cm1()
	modifies leaf_cm1_res_0, leaf_meta.cm1_predicate, leaf_netcacheEgress_cm1_reg, leaf_netcacheEgress_cm1_reg__last0_old_value, leaf_netcacheEgress_cm1_reg__last0_value, leaf_netcacheEgress_cm1_reg__last_index, leaf_netcacheEgress_cm1_reg__last_old_value, leaf_netcacheEgress_cm1_reg__last_value, leaf_netcacheEgress_cm1_reg__last_write_site, leaf_netcacheEgress_cm1_reg__next_write_site, leaf_netcacheEgress_cm1_reg__wrote_any, leaf_netcacheEgress_cm1_reg__wrote_index0;
{
    // leaf_read
    leaf_cm1_res_0 := leaf_netcacheEgress_cm1_reg.read(leaf_netcacheEgress_cm1_reg, 0bv16++leaf_hdr_eg.inswitch_hdr.hashval_for_cm1);
    leaf_meta.cm1_predicate := 1bv4;
    if(buge.bv16(leaf_cm1_res_0, leaf_hdr_eg.inswitch_hdr.hot_threshold)){
        leaf_meta.cm1_predicate := 2bv4;
    }
    // leaf_write
    leaf_netcacheEgress_cm1_reg__next_write_site := 1;
    call leaf_netcacheEgress_cm1_reg.write(0bv16++leaf_hdr_eg.inswitch_hdr.hashval_for_cm1, add.bv16(leaf_cm1_res_0, 1bv16));
}

// leaf_Action leaf_netcacheEgress_update_cm2
procedure {:inline 1} leaf_netcacheEgress_update_cm2()
	modifies leaf_cm2_res_0, leaf_meta.cm2_predicate, leaf_netcacheEgress_cm2_reg, leaf_netcacheEgress_cm2_reg__last0_old_value, leaf_netcacheEgress_cm2_reg__last0_value, leaf_netcacheEgress_cm2_reg__last_index, leaf_netcacheEgress_cm2_reg__last_old_value, leaf_netcacheEgress_cm2_reg__last_value, leaf_netcacheEgress_cm2_reg__last_write_site, leaf_netcacheEgress_cm2_reg__next_write_site, leaf_netcacheEgress_cm2_reg__wrote_any, leaf_netcacheEgress_cm2_reg__wrote_index0;
{
    // leaf_read
    leaf_cm2_res_0 := leaf_netcacheEgress_cm2_reg.read(leaf_netcacheEgress_cm2_reg, 0bv16++leaf_hdr_eg.inswitch_hdr.hashval_for_cm2);
    leaf_meta.cm2_predicate := 1bv4;
    if(buge.bv16(leaf_cm2_res_0, leaf_hdr_eg.inswitch_hdr.hot_threshold)){
        leaf_meta.cm2_predicate := 2bv4;
    }
    // leaf_write
    leaf_netcacheEgress_cm2_reg__next_write_site := 1;
    call leaf_netcacheEgress_cm2_reg.write(0bv16++leaf_hdr_eg.inswitch_hdr.hashval_for_cm2, add.bv16(leaf_cm2_res_0, 1bv16));
}

// leaf_Action leaf_netcacheEgress_update_cm3
procedure {:inline 1} leaf_netcacheEgress_update_cm3()
	modifies leaf_cm3_res_0, leaf_meta.cm3_predicate, leaf_netcacheEgress_cm1_reg, leaf_netcacheEgress_cm1_reg__last0_old_value, leaf_netcacheEgress_cm1_reg__last0_value, leaf_netcacheEgress_cm1_reg__last_index, leaf_netcacheEgress_cm1_reg__last_old_value, leaf_netcacheEgress_cm1_reg__last_value, leaf_netcacheEgress_cm1_reg__last_write_site, leaf_netcacheEgress_cm1_reg__next_write_site, leaf_netcacheEgress_cm1_reg__wrote_any, leaf_netcacheEgress_cm1_reg__wrote_index0;
{
    // leaf_read
    leaf_cm3_res_0 := leaf_netcacheEgress_cm3_reg.read(leaf_netcacheEgress_cm3_reg, 0bv16++leaf_hdr_eg.inswitch_hdr.hashval_for_cm3);
    leaf_meta.cm3_predicate := 1bv4;
    if(buge.bv16(leaf_cm3_res_0, leaf_hdr_eg.inswitch_hdr.hot_threshold)){
        leaf_meta.cm3_predicate := 2bv4;
    }
    // leaf_write
    leaf_netcacheEgress_cm1_reg__next_write_site := 2;
    call leaf_netcacheEgress_cm1_reg.write(0bv16++leaf_hdr_eg.inswitch_hdr.hashval_for_cm3, add.bv16(leaf_cm3_res_0, 1bv16));
}

// leaf_Action leaf_netcacheEgress_update_cm4
procedure {:inline 1} leaf_netcacheEgress_update_cm4()
	modifies leaf_cm4_res_0, leaf_meta.cm4_predicate, leaf_netcacheEgress_cm1_reg, leaf_netcacheEgress_cm1_reg__last0_old_value, leaf_netcacheEgress_cm1_reg__last0_value, leaf_netcacheEgress_cm1_reg__last_index, leaf_netcacheEgress_cm1_reg__last_old_value, leaf_netcacheEgress_cm1_reg__last_value, leaf_netcacheEgress_cm1_reg__last_write_site, leaf_netcacheEgress_cm1_reg__next_write_site, leaf_netcacheEgress_cm1_reg__wrote_any, leaf_netcacheEgress_cm1_reg__wrote_index0;
{
    // leaf_read
    leaf_cm4_res_0 := leaf_netcacheEgress_cm4_reg.read(leaf_netcacheEgress_cm4_reg, 0bv16++leaf_hdr_eg.inswitch_hdr.hashval_for_cm4);
    leaf_meta.cm4_predicate := 1bv4;
    if(buge.bv16(leaf_cm4_res_0, leaf_hdr_eg.inswitch_hdr.hot_threshold)){
        leaf_meta.cm4_predicate := 2bv4;
    }
    // leaf_write
    leaf_netcacheEgress_cm1_reg__next_write_site := 3;
    call leaf_netcacheEgress_cm1_reg.write(0bv16++leaf_hdr_eg.inswitch_hdr.hashval_for_cm4, add.bv16(leaf_cm4_res_0, 1bv16));
}

// leaf_Action leaf_netcacheEgress_update_delreq_inswitch_to_delreq_seq
procedure {:inline 1} leaf_netcacheEgress_update_delreq_inswitch_to_delreq_seq()
	modifies leaf_hdr_eg.op_hdr.optype, leaf_isValid;
{
    leaf_hdr_eg.op_hdr.optype := 2bv16;
    call leaf_setInvalid(leaf_hdr_eg.inswitch_hdr);
    call leaf_setInvalid(leaf_hdr_eg.clone_hdr);
}

// leaf_Action leaf_netcacheEgress_update_delreq_inswitch_to_netcache_delreq_seq_cached
procedure {:inline 1} leaf_netcacheEgress_update_delreq_inswitch_to_netcache_delreq_seq_cached()
	modifies leaf_hdr_eg.op_hdr.optype, leaf_isValid;
{
    leaf_hdr_eg.op_hdr.optype := 34bv16;
    call leaf_setInvalid(leaf_hdr_eg.inswitch_hdr);
    call leaf_setInvalid(leaf_hdr_eg.clone_hdr);
}

// leaf_Action leaf_netcacheEgress_update_dstipmac_client2server
procedure {:inline 1} leaf_netcacheEgress_update_dstipmac_client2server(leaf_server_mac_3:bv48, leaf_server_ip_3:bv32)
{
}

// leaf_Action leaf_netcacheEgress_update_dstipmac_switch2switchos
procedure {:inline 1} leaf_netcacheEgress_update_dstipmac_switch2switchos(leaf_switch_mac_2:bv48, leaf_switch_ip_2:bv32)
{
}

// leaf_Action leaf_netcacheEgress_update_getreq_inswitch_to_getreq
procedure {:inline 1} leaf_netcacheEgress_update_getreq_inswitch_to_getreq()
	modifies leaf_hdr_eg.op_hdr.optype, leaf_isValid;
{
    leaf_hdr_eg.op_hdr.optype := 48bv16;
    call leaf_setInvalid(leaf_hdr_eg.inswitch_hdr);
    call leaf_setInvalid(leaf_hdr_eg.clone_hdr);
}

// leaf_Action leaf_netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring
procedure {:inline 1} leaf_netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring(leaf_client_sid_5:bv10, leaf_server_port_3:bv16, leaf_stat_1:bv8)
	modifies leaf_drop, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.stat_hdr.nodeidx_foreval, leaf_hdr_eg.stat_hdr.stat, leaf_hdr_eg.udp_hdr.dstPort, leaf_hdr_eg.udp_hdr.srcPort, leaf_isValid, leaf_p4b_clone_i2e;
{
    leaf_hdr_eg.op_hdr.optype := 9bv16;
    leaf_hdr_eg.stat_hdr.stat := leaf_stat_1;
    leaf_hdr_eg.stat_hdr.nodeidx_foreval := 65535bv16;
    leaf_hdr_eg.udp_hdr.srcPort := leaf_server_port_3;
    leaf_hdr_eg.udp_hdr.dstPort := leaf_hdr_eg.clone_hdr.client_udpport;
    call leaf_setInvalid(leaf_hdr_eg.inswitch_hdr);
    call leaf_setValid(leaf_hdr_eg.stat_hdr);
    call leaf_setInvalid(leaf_hdr_eg.clone_hdr);
    call leaf_mark_to_drop();
    leaf_p4b_clone_i2e := true;
}

// leaf_Action leaf_netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq
procedure {:inline 1} leaf_netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq(leaf_switchos_sid_8:bv10, leaf_reflector_port_5:bv16)
	modifies leaf_drop, leaf_hdr_eg.clone_hdr.clonenum_for_pktloss, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.udp_hdr.dstPort, leaf_isValid, leaf_p4b_clone_i2e;
{
    leaf_hdr_eg.op_hdr.optype := 288bv16;
    leaf_hdr_eg.udp_hdr.dstPort := leaf_reflector_port_5;
    leaf_hdr_eg.clone_hdr.clonenum_for_pktloss := 3bv16;
    call leaf_setInvalid(leaf_hdr_eg.inswitch_hdr);
    call leaf_setValid(leaf_hdr_eg.clone_hdr);
    call leaf_mark_to_drop();
    leaf_p4b_clone_i2e := true;
}

// leaf_Action leaf_netcacheEgress_update_ipmac_srcport_client2server
procedure {:inline 1} leaf_netcacheEgress_update_ipmac_srcport_client2server(leaf_client_mac_4:bv48, leaf_server_mac_4:bv48, leaf_client_ip_4:bv32, leaf_server_ip_4:bv32, leaf_client_port_2:bv16)
	modifies leaf_hdr_eg.udp_hdr.srcPort;
{
    leaf_hdr_eg.udp_hdr.srcPort := leaf_client_port_2;
}

// leaf_Action leaf_netcacheEgress_update_ipmac_srcport_server2client
procedure {:inline 1} leaf_netcacheEgress_update_ipmac_srcport_server2client(leaf_client_mac:bv48, leaf_server_mac:bv48, leaf_client_ip:bv32, leaf_server_ip:bv32, leaf_server_port_4:bv16)
	modifies leaf_hdr_eg.udp_hdr.srcPort;
{
    leaf_hdr_eg.udp_hdr.srcPort := leaf_server_port_4;
}

// leaf_Action leaf_netcacheEgress_update_ipmac_srcport_switch2switchos
procedure {:inline 1} leaf_netcacheEgress_update_ipmac_srcport_switch2switchos(leaf_client_mac_3:bv48, leaf_switch_mac:bv48, leaf_client_ip_3:bv32, leaf_switch_ip:bv32, leaf_client_port:bv16)
	modifies leaf_hdr_eg.udp_hdr.srcPort;
{
    leaf_hdr_eg.udp_hdr.srcPort := leaf_client_port;
}

// leaf_Table leaf_netcacheEgress_update_ipmac_srcport_tbl
procedure {:inline 1} leaf_netcacheEgress_update_ipmac_srcport_tbl.apply()
	modifies leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.udp_hdr.srcPort, leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run, leaf_netcacheEgress_update_ipmac_srcport_tbl.hit, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_ip_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_mac_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_ip_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_mac_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_port_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_ip_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_mac_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_port_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_ip_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_port, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_mac, leaf_standard_metadata.egress_port;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_standard_metadata.egress_port := leaf_standard_metadata.egress_port;
    leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := false;
    if(leaf_hdr_eg.op_hdr.optype == 208bv16 && leaf_standard_metadata.egress_port == 1bv9){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := true;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_ipmac_srcport_server2client;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_mac := 2bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_mac := 3bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_ip := 167772162bv32;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_ip := 167773186bv32;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_port_4 := 1152bv16;
        call leaf_netcacheEgress_update_ipmac_srcport_server2client(leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_port_4);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 224bv16 && leaf_standard_metadata.egress_port == 1bv9){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := true;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_ipmac_srcport_server2client;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_mac := 2bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_mac := 3bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_ip := 167772162bv32;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_ip := 167773186bv32;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_port_4 := 1152bv16;
        call leaf_netcacheEgress_update_ipmac_srcport_server2client(leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_port_4);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 48bv16 && leaf_standard_metadata.egress_port == 4bv9){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := true;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_dstipmac_client2server;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3 := 3bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3 := 167773186bv32;
        call leaf_netcacheEgress_update_dstipmac_client2server(leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && leaf_standard_metadata.egress_port == 4bv9){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := true;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_dstipmac_client2server;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3 := 3bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3 := 167773186bv32;
        call leaf_netcacheEgress_update_dstipmac_client2server(leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && leaf_standard_metadata.egress_port == 4bv9){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := true;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_dstipmac_client2server;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3 := 3bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3 := 167773186bv32;
        call leaf_netcacheEgress_update_dstipmac_client2server(leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 2bv16 && leaf_standard_metadata.egress_port == 4bv9){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := true;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_dstipmac_client2server;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3 := 3bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3 := 167773186bv32;
        call leaf_netcacheEgress_update_dstipmac_client2server(leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 34bv16 && leaf_standard_metadata.egress_port == 4bv9){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := true;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_dstipmac_client2server;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3 := 3bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3 := 167773186bv32;
        call leaf_netcacheEgress_update_dstipmac_client2server(leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 784bv16 && leaf_standard_metadata.egress_port == 4bv9){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := true;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_dstipmac_client2server;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3 := 3bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3 := 167773186bv32;
        call leaf_netcacheEgress_update_dstipmac_client2server(leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 50bv16 && leaf_standard_metadata.egress_port == 4bv9){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := true;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_dstipmac_client2server;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3 := 3bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3 := 167773186bv32;
        call leaf_netcacheEgress_update_dstipmac_client2server(leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 66bv16 && leaf_standard_metadata.egress_port == 4bv9){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := true;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_dstipmac_client2server;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3 := 3bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3 := 167773186bv32;
        call leaf_netcacheEgress_update_dstipmac_client2server(leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 400bv16 && leaf_standard_metadata.egress_port == 4bv9){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := true;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_ipmac_srcport_client2server;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_mac_4 := 2bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_mac_4 := 3bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_ip_4 := 167772162bv32;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_ip_4 := 167773186bv32;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_port_2 := 123bv16;
        call leaf_netcacheEgress_update_ipmac_srcport_client2server(leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_mac_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_mac_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_ip_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_ip_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_port_2);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 112bv16 && leaf_standard_metadata.egress_port == 4bv9){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := true;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_ipmac_srcport_switch2switchos;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_mac_3 := 2bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_mac := 3bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_ip_3 := 167772162bv32;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_ip := 167773186bv32;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_port := 123bv16;
        call leaf_netcacheEgress_update_ipmac_srcport_switch2switchos(leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_ip_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_port);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 256bv16 && leaf_standard_metadata.egress_port == 4bv9){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := true;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_ipmac_srcport_switch2switchos;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_mac_3 := 2bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_mac := 3bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_ip_3 := 167772162bv32;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_ip := 167773186bv32;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_port := 123bv16;
        call leaf_netcacheEgress_update_ipmac_srcport_switch2switchos(leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_ip_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_port);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 288bv16 && leaf_standard_metadata.egress_port == 4bv9){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := true;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_dstipmac_switch2switchos;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_mac_2 := 3bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_ip_2 := 167773186bv32;
        call leaf_netcacheEgress_update_dstipmac_switch2switchos(leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_mac_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_ip_2);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 116bv16 && leaf_standard_metadata.egress_port == 4bv9){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.hit := true;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.netcacheEgress_update_dstipmac_switch2switchos;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_mac_2 := 3bv48;
        leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_ip_2 := 167773186bv32;
        call leaf_netcacheEgress_update_dstipmac_switch2switchos(leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_mac_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_ip_2);
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_update_ipmac_srcport_tbl.hit){
        leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run := leaf_netcacheEgress_update_ipmac_srcport_tbl.action.NoAction_51;
        call leaf_NoAction_51();
        goto leaf_Exit;
    }

    leaf_Exit:
}

// leaf_Action leaf_netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone
procedure {:inline 1} leaf_netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone(leaf_switchos_sid_12:bv10, leaf_reflector_port_8:bv16)
	modifies leaf_drop, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.udp_hdr.dstPort, leaf_isValid, leaf_p4b_clone_i2e;
{
    leaf_hdr_eg.op_hdr.optype := 112bv16;
    leaf_hdr_eg.udp_hdr.dstPort := leaf_reflector_port_8;
    call leaf_setInvalid(leaf_hdr_eg.inswitch_hdr);
    call leaf_setInvalid(leaf_hdr_eg.stat_hdr);
    call leaf_setInvalid(leaf_hdr_eg.clone_hdr);
    call leaf_mark_to_drop();
    leaf_p4b_clone_i2e := true;
}

// leaf_Action leaf_netcacheEgress_update_netcache_getreq_pop_to_getreq_by_mirroring
procedure {:inline 1} leaf_netcacheEgress_update_netcache_getreq_pop_to_getreq_by_mirroring(leaf_server_sid_3:bv10)
	modifies leaf_drop, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.udp_hdr.dstPort, leaf_isValid, leaf_p4b_clone_i2e;
{
    leaf_hdr_eg.op_hdr.optype := 48bv16;
    leaf_hdr_eg.udp_hdr.dstPort := leaf_hdr_eg.clone_hdr.server_udpport;
    call leaf_setInvalid(leaf_hdr_eg.clone_hdr);
    call leaf_mark_to_drop();
    leaf_p4b_clone_i2e := true;
}

// leaf_Action leaf_netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack
procedure {:inline 1} leaf_netcacheEgress_update_netcache_valueupdate_inswitch_to_netcache_valueupdate_ack()
	modifies leaf_hdr_eg.op_hdr.optype, leaf_isValid;
{
    leaf_hdr_eg.op_hdr.optype := 400bv16;
    call leaf_setInvalid(leaf_hdr_eg.inswitch_hdr);
    call leaf_setInvalid(leaf_hdr_eg.stat_hdr);
    call leaf_setInvalid(leaf_hdr_eg.clone_hdr);
}

// leaf_Action leaf_netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring
procedure {:inline 1} leaf_netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring(leaf_client_sid_4:bv10, leaf_server_port:bv16)
	modifies leaf_drop, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.udp_hdr.dstPort, leaf_hdr_eg.udp_hdr.srcPort, leaf_isValid, leaf_p4b_clone_i2e;
{
    leaf_hdr_eg.op_hdr.optype := 208bv16;
    leaf_hdr_eg.udp_hdr.srcPort := leaf_server_port;
    leaf_hdr_eg.udp_hdr.dstPort := leaf_hdr_eg.clone_hdr.client_udpport;
    call leaf_setInvalid(leaf_hdr_eg.inswitch_hdr);
    call leaf_setInvalid(leaf_hdr_eg.clone_hdr);
    call leaf_mark_to_drop();
    leaf_p4b_clone_i2e := true;
}

// leaf_Action leaf_netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack
procedure {:inline 1} leaf_netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack(leaf_switchos_sid:bv10, leaf_reflector_port:bv16)
	modifies leaf_drop, leaf_hdr_eg.clone_hdr.clonenum_for_pktloss, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.udp_hdr.dstPort, leaf_isValid, leaf_p4b_clone_i2e;
{
    leaf_hdr_eg.op_hdr.optype := 116bv16;
    leaf_hdr_eg.udp_hdr.dstPort := leaf_reflector_port;
    leaf_hdr_eg.clone_hdr.clonenum_for_pktloss := 3bv16;
    call leaf_setValid(leaf_hdr_eg.clone_hdr);
    call leaf_mark_to_drop();
    leaf_p4b_clone_i2e := true;
}

// leaf_Action leaf_netcacheEgress_update_pktlen
procedure {:inline 1} leaf_netcacheEgress_update_pktlen(leaf_udplen:bv16, leaf_iplen:bv16)
	modifies leaf_hdr_eg.udp_hdr.hdrlen;
{
    leaf_hdr_eg.udp_hdr.hdrlen := leaf_udplen;
}

// leaf_Table leaf_netcacheEgress_update_pktlen_tbl
procedure {:inline 1} leaf_netcacheEgress_update_pktlen_tbl.apply()
	modifies leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.udp_hdr.hdrlen, leaf_hdr_eg.vallen_hdr.vallen, leaf_netcacheEgress_update_pktlen_tbl.action_run, leaf_netcacheEgress_update_pktlen_tbl.hit, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.iplen_delta, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.udplen_delta, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.vallen_hdr.vallen := leaf_hdr_eg.vallen_hdr.vallen;
    leaf_netcacheEgress_update_pktlen_tbl.hit := false;
    if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 34bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 54bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 34bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 54bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 34bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 54bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 1bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 8bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 42bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 62bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 1bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 8bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 42bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 62bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 1bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 8bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 42bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 62bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 9bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 16bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 50bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 70bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 9bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 16bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 50bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 70bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 9bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 16bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 50bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 70bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 17bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 24bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 58bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 78bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 17bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 24bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 58bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 78bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 17bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 24bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 58bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 78bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 25bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 32bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 66bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 86bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 25bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 32bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 66bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 86bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 25bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 32bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 66bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 86bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 33bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 40bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 74bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 94bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 33bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 40bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 74bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 94bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 33bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 40bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 74bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 94bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 41bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 48bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 82bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 102bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 41bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 48bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 82bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 102bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 41bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 48bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 82bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 102bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 49bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 56bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 90bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 110bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 49bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 56bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 90bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 110bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 49bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 56bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 90bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 110bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 57bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 64bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 98bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 118bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 57bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 64bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 98bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 118bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 57bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 64bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 98bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 118bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 65bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 72bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 106bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 126bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 65bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 72bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 106bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 126bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 65bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 72bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 106bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 126bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 73bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 80bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 114bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 134bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 73bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 80bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 114bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 134bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 73bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 80bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 114bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 134bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 81bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 88bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 122bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 142bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 81bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 88bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 122bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 142bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 81bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 88bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 122bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 142bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 89bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 96bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 130bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 150bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 89bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 96bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 130bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 150bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 89bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 96bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 130bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 150bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 97bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 104bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 138bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 158bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 97bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 104bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 138bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 158bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 97bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 104bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 138bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 158bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 105bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 112bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 146bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 166bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 105bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 112bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 146bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 166bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 105bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 112bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 146bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 166bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 113bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 120bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 154bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 174bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 113bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 120bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 154bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 174bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 113bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 120bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 154bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 174bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 121bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 128bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 162bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 182bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 3bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 121bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 128bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 162bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 182bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 67bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 121bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 128bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 162bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 182bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 112bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 128bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 26bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 46bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 48bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 128bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 26bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 46bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 208bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 128bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 26bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 46bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 400bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 128bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 26bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 46bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 2bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 128bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 32bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 52bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 34bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 128bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 32bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 52bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 256bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 128bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 30bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 50bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 288bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 128bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 34bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 54bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 116bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 128bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_update_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen := 64bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen := 84bv16;
        call leaf_netcacheEgress_update_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 50bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 65535bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_add_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.udplen_delta := 6bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.iplen_delta := 6bv16;
        call leaf_netcacheEgress_add_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.udplen_delta, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.iplen_delta);
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 66bv16 && (buge.bv16(leaf_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(leaf_hdr_eg.vallen_hdr.vallen, 65535bv16))){
        leaf_netcacheEgress_update_pktlen_tbl.hit := true;
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.netcacheEgress_add_pktlen;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.udplen_delta := 6bv16;
        leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.iplen_delta := 6bv16;
        call leaf_netcacheEgress_add_pktlen(leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.udplen_delta, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.iplen_delta);
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_update_pktlen_tbl.hit){
        leaf_netcacheEgress_update_pktlen_tbl.action_run := leaf_netcacheEgress_update_pktlen_tbl.action.NoAction_52;
        call leaf_NoAction_52();
        goto leaf_Exit;
    }

    leaf_Exit:
}

// leaf_Action leaf_netcacheEgress_update_putreq_inswitch_to_netcache_putreq_seq_cached
procedure {:inline 1} leaf_netcacheEgress_update_putreq_inswitch_to_netcache_putreq_seq_cached()
	modifies leaf_hdr_eg.op_hdr.optype, leaf_isValid;
{
    leaf_hdr_eg.op_hdr.optype := 67bv16;
    call leaf_setInvalid(leaf_hdr_eg.inswitch_hdr);
    call leaf_setInvalid(leaf_hdr_eg.clone_hdr);
}

// leaf_Action leaf_netcacheEgress_update_putreq_inswitch_to_putreq_seq
procedure {:inline 1} leaf_netcacheEgress_update_putreq_inswitch_to_putreq_seq()
	modifies leaf_hdr_eg.op_hdr.optype, leaf_isValid;
{
    leaf_hdr_eg.op_hdr.optype := 3bv16;
    call leaf_setInvalid(leaf_hdr_eg.inswitch_hdr);
    call leaf_setInvalid(leaf_hdr_eg.clone_hdr);
}

// leaf_Action leaf_netcacheEgress_update_putreq_largevalue_inswitch_to_putreq_largevalue_seq
procedure {:inline 1} leaf_netcacheEgress_update_putreq_largevalue_inswitch_to_putreq_largevalue_seq()
	modifies leaf_hdr_eg.op_hdr.optype, leaf_isValid;
{
    leaf_hdr_eg.op_hdr.optype := 50bv16;
    call leaf_setInvalid(leaf_hdr_eg.inswitch_hdr);
    call leaf_setInvalid(leaf_hdr_eg.clone_hdr);
}

// leaf_Action leaf_netcacheEgress_update_putreq_largevalue_inswitch_to_putreq_largevalue_seq_cached
procedure {:inline 1} leaf_netcacheEgress_update_putreq_largevalue_inswitch_to_putreq_largevalue_seq_cached()
	modifies leaf_hdr_eg.op_hdr.optype, leaf_isValid;
{
    leaf_hdr_eg.op_hdr.optype := 66bv16;
    call leaf_setInvalid(leaf_hdr_eg.inswitch_hdr);
    call leaf_setInvalid(leaf_hdr_eg.clone_hdr);
}

// leaf_Table leaf_netcacheEgress_update_vallen_tbl
procedure {:inline 1} leaf_netcacheEgress_update_vallen_tbl.apply()
	modifies leaf_hdr_eg.inswitch_hdr.is_cached, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.vallen_hdr.vallen, leaf_isValid, leaf_meta.is_latest, leaf_netcacheEgress_update_vallen_tbl.action_run, leaf_netcacheEgress_update_vallen_tbl.hit, leaf_netcacheEgress_vallen_reg, leaf_netcacheEgress_vallen_reg__last0_old_value, leaf_netcacheEgress_vallen_reg__last0_value, leaf_netcacheEgress_vallen_reg__last_index, leaf_netcacheEgress_vallen_reg__last_old_value, leaf_netcacheEgress_vallen_reg__last_value, leaf_netcacheEgress_vallen_reg__last_write_site, leaf_netcacheEgress_vallen_reg__next_write_site, leaf_netcacheEgress_vallen_reg__wrote_any, leaf_netcacheEgress_vallen_reg__wrote_index0;
{
    leaf_hdr_eg.op_hdr.optype := leaf_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.inswitch_hdr.is_cached := leaf_hdr_eg.inswitch_hdr.is_cached;
    leaf_meta.is_latest := leaf_meta.is_latest;
    leaf_netcacheEgress_update_vallen_tbl.hit := false;
    if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_update_vallen_tbl.hit := true;
        leaf_netcacheEgress_update_vallen_tbl.action_run := leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_set_and_get_vallen;
        call leaf_netcacheEgress_set_and_get_vallen();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_update_vallen_tbl.hit := true;
        leaf_netcacheEgress_update_vallen_tbl.action_run := leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_set_and_get_vallen;
        call leaf_netcacheEgress_set_and_get_vallen();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_update_vallen_tbl.hit := true;
        leaf_netcacheEgress_update_vallen_tbl.action_run := leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_set_and_get_vallen;
        call leaf_netcacheEgress_set_and_get_vallen();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 0bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_update_vallen_tbl.hit := true;
        leaf_netcacheEgress_update_vallen_tbl.action_run := leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_set_and_get_vallen;
        call leaf_netcacheEgress_set_and_get_vallen();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_update_vallen_tbl.hit := true;
        leaf_netcacheEgress_update_vallen_tbl.action_run := leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_get_vallen;
        call leaf_netcacheEgress_get_vallen();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_update_vallen_tbl.hit := true;
        leaf_netcacheEgress_update_vallen_tbl.action_run := leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_set_and_get_vallen;
        call leaf_netcacheEgress_set_and_get_vallen();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_update_vallen_tbl.hit := true;
        leaf_netcacheEgress_update_vallen_tbl.action_run := leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_set_and_get_vallen;
        call leaf_netcacheEgress_set_and_get_vallen();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 0bv1){
        leaf_netcacheEgress_update_vallen_tbl.hit := true;
        leaf_netcacheEgress_update_vallen_tbl.action_run := leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_set_and_get_vallen;
        call leaf_netcacheEgress_set_and_get_vallen();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 4bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_update_vallen_tbl.hit := true;
        leaf_netcacheEgress_update_vallen_tbl.action_run := leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_get_vallen;
        call leaf_netcacheEgress_get_vallen();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 127bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_update_vallen_tbl.hit := true;
        leaf_netcacheEgress_update_vallen_tbl.action_run := leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_set_and_get_vallen;
        call leaf_netcacheEgress_set_and_get_vallen();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 351bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_update_vallen_tbl.hit := true;
        leaf_netcacheEgress_update_vallen_tbl.action_run := leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_set_and_get_vallen;
        call leaf_netcacheEgress_set_and_get_vallen();
        goto leaf_Exit;
    }
    else if(leaf_hdr_eg.op_hdr.optype == 143bv16 && leaf_hdr_eg.inswitch_hdr.is_cached == 1bv1 && leaf_meta.is_latest == 1bv1){
        leaf_netcacheEgress_update_vallen_tbl.hit := true;
        leaf_netcacheEgress_update_vallen_tbl.action_run := leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_set_and_get_vallen;
        call leaf_netcacheEgress_set_and_get_vallen();
        goto leaf_Exit;
    }
    if(!leaf_netcacheEgress_update_vallen_tbl.hit){
        leaf_netcacheEgress_update_vallen_tbl.action_run := leaf_netcacheEgress_update_vallen_tbl.action.netcacheEgress_reset_access_val_mode;
        call leaf_netcacheEgress_reset_access_val_mode();
        goto leaf_Exit;
    }

    leaf_Exit:
}
function {:inline true}leaf_netcacheEgress_vallen_reg.read(leaf_reg:[bv32]bv16, leaf_index:bv32)returns (bv16) {leaf_reg[leaf_index]}
procedure {:inline 1} leaf_netcacheEgress_vallen_reg.write(leaf_index:bv32, leaf_value:bv16)
	modifies leaf_netcacheEgress_vallen_reg, leaf_netcacheEgress_vallen_reg__last0_old_value, leaf_netcacheEgress_vallen_reg__last0_value, leaf_netcacheEgress_vallen_reg__last_index, leaf_netcacheEgress_vallen_reg__last_old_value, leaf_netcacheEgress_vallen_reg__last_value, leaf_netcacheEgress_vallen_reg__last_write_site, leaf_netcacheEgress_vallen_reg__wrote_any, leaf_netcacheEgress_vallen_reg__wrote_index0;
{
    leaf_netcacheEgress_vallen_reg__last_old_value := leaf_netcacheEgress_vallen_reg[leaf_index];
    leaf_netcacheEgress_vallen_reg[leaf_index] := leaf_value;
    leaf_netcacheEgress_vallen_reg__last_index := leaf_index;
    leaf_netcacheEgress_vallen_reg__last_value := leaf_value;
    leaf_netcacheEgress_vallen_reg__last_write_site := leaf_netcacheEgress_vallen_reg__next_write_site;
    leaf_netcacheEgress_vallen_reg__wrote_any := true;
    if (leaf_index == 0bv32) {
        leaf_netcacheEgress_vallen_reg__wrote_index0 := true;
        leaf_netcacheEgress_vallen_reg__last0_old_value := leaf_netcacheEgress_vallen_reg__last_old_value;
        leaf_netcacheEgress_vallen_reg__last0_value := leaf_value;
    }
}

// leaf_Control leaf_netcacheIngress
procedure {:inline 1} leaf_netcacheIngress()
	modifies leaf_hdr.op_hdr.optype, leaf_meta.hashval_for_spine_partition, leaf_meta.spine_sid, leaf_netcacheIngress_hash_for_partition_tbl.action_run, leaf_netcacheIngress_hash_for_partition_tbl.hit, leaf_netcacheIngress_hash_spine_partition_tbl.action_run, leaf_netcacheIngress_hash_spine_partition_tbl.hit, leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.eport_5, leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.spine_sid_1, leaf_p4b_clone_i2e;
{
    if(leaf_isValid[leaf_hdr.op_hdr]){
        call leaf_netcacheIngress_hash_for_partition_tbl.apply();
        call leaf_netcacheIngress_hash_spine_partition_tbl.apply();
    }
    else{
    }
}

// leaf_Action leaf_netcacheIngress_hash_for_partition
procedure {:inline 1} leaf_netcacheIngress_hash_for_partition()
	modifies leaf_meta.hashval_for_spine_partition;
{
    // leaf_p4b_hash_model: leaf_builtin leaf_algorithm=leaf_HashAlgorithm.csum16 leaf_model=leaf_checksum16_uf leaf_precision=leaf_deterministic_uninterpreted
    leaf_meta.hashval_for_spine_partition := leaf_hash_csum16$bv16$bv32$bv32$bv32$bv16$bv16$bv16(0bv16, leaf_hdr.op_hdr.keylolo, leaf_hdr.op_hdr.keylohi, leaf_hdr.op_hdr.keyhilo, leaf_hdr.op_hdr.keyhihilo, leaf_hdr.op_hdr.keyhihihi, 32768bv16);
    assume(buge.bv16(leaf_meta.hashval_for_spine_partition, 0bv16) && bule.bv16(leaf_meta.hashval_for_spine_partition, 32767bv16));
}

// leaf_Table leaf_netcacheIngress_hash_for_partition_tbl
procedure {:inline 1} leaf_netcacheIngress_hash_for_partition_tbl.apply()
	modifies leaf_hdr.op_hdr.optype, leaf_meta.hashval_for_spine_partition, leaf_netcacheIngress_hash_for_partition_tbl.action_run, leaf_netcacheIngress_hash_for_partition_tbl.hit;
{
    leaf_hdr.op_hdr.optype := leaf_hdr.op_hdr.optype;
    leaf_netcacheIngress_hash_for_partition_tbl.hit := false;
    if(leaf_hdr.op_hdr.optype == 48bv16){
        leaf_netcacheIngress_hash_for_partition_tbl.hit := true;
        leaf_netcacheIngress_hash_for_partition_tbl.action_run := leaf_netcacheIngress_hash_for_partition_tbl.action.netcacheIngress_hash_for_partition;
        call leaf_netcacheIngress_hash_for_partition();
        goto leaf_Exit;
    }
    else if(leaf_hdr.op_hdr.optype == 127bv16){
        leaf_netcacheIngress_hash_for_partition_tbl.hit := true;
        leaf_netcacheIngress_hash_for_partition_tbl.action_run := leaf_netcacheIngress_hash_for_partition_tbl.action.netcacheIngress_hash_for_partition;
        call leaf_netcacheIngress_hash_for_partition();
        goto leaf_Exit;
    }
    else if(leaf_hdr.op_hdr.optype == 1bv16){
        leaf_netcacheIngress_hash_for_partition_tbl.hit := true;
        leaf_netcacheIngress_hash_for_partition_tbl.action_run := leaf_netcacheIngress_hash_for_partition_tbl.action.netcacheIngress_hash_for_partition;
        call leaf_netcacheIngress_hash_for_partition();
        goto leaf_Exit;
    }
    else if(leaf_hdr.op_hdr.optype == 64bv16){
        leaf_netcacheIngress_hash_for_partition_tbl.hit := true;
        leaf_netcacheIngress_hash_for_partition_tbl.action_run := leaf_netcacheIngress_hash_for_partition_tbl.action.netcacheIngress_hash_for_partition;
        call leaf_netcacheIngress_hash_for_partition();
        goto leaf_Exit;
    }
    else if(leaf_hdr.op_hdr.optype == 0bv16){
        leaf_netcacheIngress_hash_for_partition_tbl.hit := true;
        leaf_netcacheIngress_hash_for_partition_tbl.action_run := leaf_netcacheIngress_hash_for_partition_tbl.action.netcacheIngress_hash_for_partition;
        call leaf_netcacheIngress_hash_for_partition();
        goto leaf_Exit;
    }
    else if(leaf_hdr.op_hdr.optype == 784bv16){
        leaf_netcacheIngress_hash_for_partition_tbl.hit := true;
        leaf_netcacheIngress_hash_for_partition_tbl.action_run := leaf_netcacheIngress_hash_for_partition_tbl.action.netcacheIngress_hash_for_partition;
        call leaf_netcacheIngress_hash_for_partition();
        goto leaf_Exit;
    }
    else if(leaf_hdr.op_hdr.optype == 36bv16){
        leaf_netcacheIngress_hash_for_partition_tbl.hit := true;
        leaf_netcacheIngress_hash_for_partition_tbl.action_run := leaf_netcacheIngress_hash_for_partition_tbl.action.netcacheIngress_hash_for_partition;
        call leaf_netcacheIngress_hash_for_partition();
        goto leaf_Exit;
    }
    else if(leaf_hdr.op_hdr.optype == 59bv16){
        leaf_netcacheIngress_hash_for_partition_tbl.hit := true;
        leaf_netcacheIngress_hash_for_partition_tbl.action_run := leaf_netcacheIngress_hash_for_partition_tbl.action.netcacheIngress_hash_for_partition;
        call leaf_netcacheIngress_hash_for_partition();
        goto leaf_Exit;
    }
    else if(leaf_hdr.op_hdr.optype == 84bv16){
        leaf_netcacheIngress_hash_for_partition_tbl.hit := true;
        leaf_netcacheIngress_hash_for_partition_tbl.action_run := leaf_netcacheIngress_hash_for_partition_tbl.action.netcacheIngress_hash_for_partition;
        call leaf_netcacheIngress_hash_for_partition();
        goto leaf_Exit;
    }
    else if(leaf_hdr.op_hdr.optype == 720bv16){
        leaf_netcacheIngress_hash_for_partition_tbl.hit := true;
        leaf_netcacheIngress_hash_for_partition_tbl.action_run := leaf_netcacheIngress_hash_for_partition_tbl.action.netcacheIngress_hash_for_partition;
        call leaf_netcacheIngress_hash_for_partition();
        goto leaf_Exit;
    }
    else if(leaf_hdr.op_hdr.optype == 351bv16){
        leaf_netcacheIngress_hash_for_partition_tbl.hit := true;
        leaf_netcacheIngress_hash_for_partition_tbl.action_run := leaf_netcacheIngress_hash_for_partition_tbl.action.netcacheIngress_hash_for_partition;
        call leaf_netcacheIngress_hash_for_partition();
        goto leaf_Exit;
    }
    if(!leaf_netcacheIngress_hash_for_partition_tbl.hit){
        leaf_netcacheIngress_hash_for_partition_tbl.action_run := leaf_netcacheIngress_hash_for_partition_tbl.action.NoAction_3;
        call leaf_NoAction_3();
        goto leaf_Exit;
    }

    leaf_Exit:
}

// leaf_Action leaf_netcacheIngress_hash_spine_partition
procedure {:inline 1} leaf_netcacheIngress_hash_spine_partition(leaf_spine_sid_1:bv10, leaf_eport_5:leaf_egressSpec_t)
	modifies leaf_meta.spine_sid, leaf_p4b_clone_i2e;
{
    leaf_meta.spine_sid := leaf_spine_sid_1;
    leaf_p4b_clone_i2e := true;
}

// leaf_Table leaf_netcacheIngress_hash_spine_partition_tbl
procedure {:inline 1} leaf_netcacheIngress_hash_spine_partition_tbl.apply()
	modifies leaf_hdr.op_hdr.optype, leaf_meta.hashval_for_spine_partition, leaf_meta.spine_sid, leaf_netcacheIngress_hash_spine_partition_tbl.action_run, leaf_netcacheIngress_hash_spine_partition_tbl.hit, leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.eport_5, leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.spine_sid_1, leaf_p4b_clone_i2e;
{
    leaf_hdr.op_hdr.optype := leaf_hdr.op_hdr.optype;
    leaf_meta.hashval_for_spine_partition := leaf_meta.hashval_for_spine_partition;
    leaf_netcacheIngress_hash_spine_partition_tbl.hit := false;
    if(leaf_hdr.op_hdr.optype == 127bv16 && (buge.bv16(leaf_meta.hashval_for_spine_partition, 0bv16)) && (bule.bv16(leaf_meta.hashval_for_spine_partition, 15bv16))){
        leaf_netcacheIngress_hash_spine_partition_tbl.hit := true;
        leaf_netcacheIngress_hash_spine_partition_tbl.action_run := leaf_netcacheIngress_hash_spine_partition_tbl.action.netcacheIngress_hash_spine_partition;
        leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.spine_sid_1 := 30bv10;
        leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.eport_5 := 3bv9;
        call leaf_netcacheIngress_hash_spine_partition(leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.spine_sid_1, leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.eport_5);
        goto leaf_Exit;
    }
    else if(leaf_hdr.op_hdr.optype == 59bv16 && (buge.bv16(leaf_meta.hashval_for_spine_partition, 0bv16)) && (bule.bv16(leaf_meta.hashval_for_spine_partition, 15bv16))){
        leaf_netcacheIngress_hash_spine_partition_tbl.hit := true;
        leaf_netcacheIngress_hash_spine_partition_tbl.action_run := leaf_netcacheIngress_hash_spine_partition_tbl.action.netcacheIngress_hash_spine_partition;
        leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.spine_sid_1 := 30bv10;
        leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.eport_5 := 3bv9;
        call leaf_netcacheIngress_hash_spine_partition(leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.spine_sid_1, leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.eport_5);
        goto leaf_Exit;
    }
    if(!leaf_netcacheIngress_hash_spine_partition_tbl.hit){
        leaf_netcacheIngress_hash_spine_partition_tbl.action_run := leaf_netcacheIngress_hash_spine_partition_tbl.action.NoAction_5;
        call leaf_NoAction_5();
        goto leaf_Exit;
    }

    leaf_Exit:
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
procedure {:inline 1} leaf_setInvalid(leaf_header:leaf_Ref);
    ensures (leaf_isValid[leaf_header] == false);
	modifies leaf_isValid;
procedure {:inline 1} leaf_setValid(leaf_header:leaf_Ref);
// ===== END NODE leaf =====

// ===== BEGIN ENQUEUE PROCEDURES =====
// ===== END ENQUEUE PROCEDURES =====

// ===== BEGIN HARNESS =====
// Auto-generated by Procurator (DSL -> Boogie harness: sequential scheduler)
// Message abstraction: Bag(K=1) using inbox_count per node; single-slot mailbox for packet fields

var procurator_step: int;
var procurator_bad: bool;

// Register debug snapshots (for trace inspection)
var leaf_netcacheEgress_cm1_reg__dbg0: bv16;
var leaf_netcacheEgress_cm1_reg__last_index__dbg: bv32;
var leaf_netcacheEgress_cm1_reg__last_value__dbg: bv16;
var leaf_netcacheEgress_cm1_reg__last_old_value__dbg: bv16;
var leaf_netcacheEgress_cm1_reg__wrote_any__dbg: bool;
var leaf_netcacheEgress_cm1_reg__wrote_index0__dbg: bool;
var leaf_netcacheEgress_cm1_reg__last0_old_value__dbg: bv16;
var leaf_netcacheEgress_cm1_reg__last0_value__dbg: bv16;
var leaf_netcacheEgress_cm2_reg__dbg0: bv16;
var leaf_netcacheEgress_cm2_reg__last_index__dbg: bv32;
var leaf_netcacheEgress_cm2_reg__last_value__dbg: bv16;
var leaf_netcacheEgress_cm2_reg__last_old_value__dbg: bv16;
var leaf_netcacheEgress_cm2_reg__wrote_any__dbg: bool;
var leaf_netcacheEgress_cm2_reg__wrote_index0__dbg: bool;
var leaf_netcacheEgress_cm2_reg__last0_old_value__dbg: bv16;
var leaf_netcacheEgress_cm2_reg__last0_value__dbg: bv16;
var leaf_netcacheEgress_cm3_reg__dbg0: bv16;
var leaf_netcacheEgress_cm3_reg__last_index__dbg: bv32;
var leaf_netcacheEgress_cm3_reg__last_value__dbg: bv16;
var leaf_netcacheEgress_cm3_reg__last_old_value__dbg: bv16;
var leaf_netcacheEgress_cm3_reg__wrote_any__dbg: bool;
var leaf_netcacheEgress_cm3_reg__wrote_index0__dbg: bool;
var leaf_netcacheEgress_cm3_reg__last0_old_value__dbg: bv16;
var leaf_netcacheEgress_cm3_reg__last0_value__dbg: bv16;
var leaf_netcacheEgress_cm4_reg__dbg0: bv16;
var leaf_netcacheEgress_cm4_reg__last_index__dbg: bv32;
var leaf_netcacheEgress_cm4_reg__last_value__dbg: bv16;
var leaf_netcacheEgress_cm4_reg__last_old_value__dbg: bv16;
var leaf_netcacheEgress_cm4_reg__wrote_any__dbg: bool;
var leaf_netcacheEgress_cm4_reg__wrote_index0__dbg: bool;
var leaf_netcacheEgress_cm4_reg__last0_old_value__dbg: bv16;
var leaf_netcacheEgress_cm4_reg__last0_value__dbg: bv16;
var leaf_netcacheEgress_deleted_reg__dbg0: bv1;
var leaf_netcacheEgress_deleted_reg__last_index__dbg: bv32;
var leaf_netcacheEgress_deleted_reg__last_value__dbg: bv1;
var leaf_netcacheEgress_deleted_reg__last_old_value__dbg: bv1;
var leaf_netcacheEgress_deleted_reg__wrote_any__dbg: bool;
var leaf_netcacheEgress_deleted_reg__wrote_index0__dbg: bool;
var leaf_netcacheEgress_deleted_reg__last0_old_value__dbg: bv1;
var leaf_netcacheEgress_deleted_reg__last0_value__dbg: bv1;
var leaf_netcacheEgress_latest_reg__dbg0: bv1;
var leaf_netcacheEgress_latest_reg__last_index__dbg: bv32;
var leaf_netcacheEgress_latest_reg__last_value__dbg: bv1;
var leaf_netcacheEgress_latest_reg__last_old_value__dbg: bv1;
var leaf_netcacheEgress_latest_reg__wrote_any__dbg: bool;
var leaf_netcacheEgress_latest_reg__wrote_index0__dbg: bool;
var leaf_netcacheEgress_latest_reg__last0_old_value__dbg: bv1;
var leaf_netcacheEgress_latest_reg__last0_value__dbg: bv1;
var leaf_netcacheEgress_vallen_reg__dbg0: bv16;
var leaf_netcacheEgress_vallen_reg__last_index__dbg: bv32;
var leaf_netcacheEgress_vallen_reg__last_value__dbg: bv16;
var leaf_netcacheEgress_vallen_reg__last_old_value__dbg: bv16;
var leaf_netcacheEgress_vallen_reg__wrote_any__dbg: bool;
var leaf_netcacheEgress_vallen_reg__wrote_index0__dbg: bool;
var leaf_netcacheEgress_vallen_reg__last0_old_value__dbg: bv16;
var leaf_netcacheEgress_vallen_reg__last0_value__dbg: bv16;

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
var io_hdr.op_hdr.keylolo: bv32;
var io_hdr.op_hdr.keylohi: bv32;
var io_hdr.op_hdr.keyhilo: bv32;
var io_hdr.op_hdr.keyhihilo: bv16;
var io_hdr.op_hdr.keyhihihi: bv16;
var io_hdr.vallen_hdr.vallen: bv16;
var io_hdr.shadowtype_hdr.shadowtype: bv16;
var io_meta.hashval_for_spine_partition: bv16;
var io_meta.cm1_predicate: bv4;
var io_meta.cm2_predicate: bv4;
var io_meta.cm3_predicate: bv4;
var io_meta.cm4_predicate: bv4;
var io_meta.is_hot: bv1;
var io_meta.is_report1: bv1;
var io_meta.is_report2: bv1;
var io_meta.is_report3: bv1;
var io_meta.is_report: bv1;
var io_meta.is_latest: bv1;
var io_meta.is_deleted: bv1;
var io_meta.is_lastclone_for_pktloss: bv1;
var io_meta.spine_sid: bv10;
var io_meta.bypass_egress: bv1;
var io_hdr_eg.udp_hdr.srcPort: bv16;
var io_hdr_eg.udp_hdr.dstPort: bv16;
var io_hdr_eg.udp_hdr.hdrlen: bv16;
var io_hdr_eg.op_hdr.optype: bv16;
var io_hdr_eg.vallen_hdr.vallen: bv16;
var io_hdr_eg.inswitch_hdr.is_cached: bv1;
var io_hdr_eg.inswitch_hdr.is_sampled: bv1;
var io_hdr_eg.inswitch_hdr.client_sid: bv10;
var io_hdr_eg.inswitch_hdr.hot_threshold: bv16;
var io_hdr_eg.inswitch_hdr.hashval_for_cm1: bv16;
var io_hdr_eg.inswitch_hdr.hashval_for_cm2: bv16;
var io_hdr_eg.inswitch_hdr.hashval_for_cm3: bv16;
var io_hdr_eg.inswitch_hdr.hashval_for_cm4: bv16;
var io_hdr_eg.inswitch_hdr.idx: bv16;
var io_hdr_eg.stat_hdr.stat: bv8;
var io_hdr_eg.stat_hdr.nodeidx_foreval: bv16;
var io_hdr_eg.clone_hdr.clonenum_for_pktloss: bv16;
var io_hdr_eg.clone_hdr.client_udpport: bv16;
var io_hdr_eg.clone_hdr.server_sid: bv10;
var io_hdr_eg.clone_hdr.server_udpport: bv16;
var io_hdr_eg.fraginfo_hdr.cur_fragidx: bv16;

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
  modifies io_hdr.ethernet_hdr.etherType, io_hdr.ipv4_hdr.protocol, io_hdr.op_hdr.keyhihihi, io_hdr.op_hdr.keyhihilo, io_hdr.op_hdr.keyhilo, io_hdr.op_hdr.keylohi, io_hdr.op_hdr.keylolo, io_hdr.op_hdr.optype, io_hdr.shadowtype_hdr.shadowtype, io_hdr.udp_hdr.dstPort, io_hdr.udp_hdr.srcPort, io_hdr.vallen_hdr.vallen, io_hdr_eg.clone_hdr.client_udpport, io_hdr_eg.clone_hdr.clonenum_for_pktloss, io_hdr_eg.clone_hdr.server_sid, io_hdr_eg.clone_hdr.server_udpport, io_hdr_eg.fraginfo_hdr.cur_fragidx, io_hdr_eg.inswitch_hdr.client_sid, io_hdr_eg.inswitch_hdr.hashval_for_cm1, io_hdr_eg.inswitch_hdr.hashval_for_cm2, io_hdr_eg.inswitch_hdr.hashval_for_cm3, io_hdr_eg.inswitch_hdr.hashval_for_cm4, io_hdr_eg.inswitch_hdr.hot_threshold, io_hdr_eg.inswitch_hdr.idx, io_hdr_eg.inswitch_hdr.is_cached, io_hdr_eg.inswitch_hdr.is_sampled, io_hdr_eg.op_hdr.optype, io_hdr_eg.stat_hdr.nodeidx_foreval, io_hdr_eg.stat_hdr.stat, io_hdr_eg.udp_hdr.dstPort, io_hdr_eg.udp_hdr.hdrlen, io_hdr_eg.udp_hdr.srcPort, io_hdr_eg.vallen_hdr.vallen, io_inbox_count, io_meta.bypass_egress, io_meta.cm1_predicate, io_meta.cm2_predicate, io_meta.cm3_predicate, io_meta.cm4_predicate, io_meta.hashval_for_spine_partition, io_meta.is_deleted, io_meta.is_hot, io_meta.is_lastclone_for_pktloss, io_meta.is_latest, io_meta.is_report, io_meta.is_report1, io_meta.is_report2, io_meta.is_report3, io_meta.spine_sid, io_pkt_external, leaf_cm1_res_0, leaf_cm2_res_0, leaf_cm3_res_0, leaf_cm4_res_0, leaf_drop, leaf_hdr.ethernet_hdr.etherType, leaf_hdr.ipv4_hdr.protocol, leaf_hdr.op_hdr.keyhihihi, leaf_hdr.op_hdr.keyhihilo, leaf_hdr.op_hdr.keyhilo, leaf_hdr.op_hdr.keylohi, leaf_hdr.op_hdr.keylolo, leaf_hdr.op_hdr.optype, leaf_hdr.shadowtype_hdr.shadowtype, leaf_hdr.udp_hdr.dstPort, leaf_hdr.udp_hdr.srcPort, leaf_hdr.vallen_hdr.vallen, leaf_hdr_eg.clone_hdr.client_udpport, leaf_hdr_eg.clone_hdr.clonenum_for_pktloss, leaf_hdr_eg.clone_hdr.server_sid, leaf_hdr_eg.clone_hdr.server_udpport, leaf_hdr_eg.fraginfo_hdr.cur_fragidx, leaf_hdr_eg.inswitch_hdr.client_sid, leaf_hdr_eg.inswitch_hdr.hashval_for_cm1, leaf_hdr_eg.inswitch_hdr.hashval_for_cm2, leaf_hdr_eg.inswitch_hdr.hashval_for_cm3, leaf_hdr_eg.inswitch_hdr.hashval_for_cm4, leaf_hdr_eg.inswitch_hdr.hot_threshold, leaf_hdr_eg.inswitch_hdr.idx, leaf_hdr_eg.inswitch_hdr.is_cached, leaf_hdr_eg.inswitch_hdr.is_sampled, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.stat_hdr.nodeidx_foreval, leaf_hdr_eg.stat_hdr.stat, leaf_hdr_eg.udp_hdr.dstPort, leaf_hdr_eg.udp_hdr.hdrlen, leaf_hdr_eg.udp_hdr.srcPort, leaf_hdr_eg.vallen_hdr.vallen, leaf_inbox_count, leaf_isValid, leaf_meta.bypass_egress, leaf_meta.cm1_predicate, leaf_meta.cm2_predicate, leaf_meta.cm3_predicate, leaf_meta.cm4_predicate, leaf_meta.hashval_for_spine_partition, leaf_meta.is_deleted, leaf_meta.is_hot, leaf_meta.is_lastclone_for_pktloss, leaf_meta.is_latest, leaf_meta.is_report, leaf_meta.is_report1, leaf_meta.is_report2, leaf_meta.is_report3, leaf_meta.spine_sid, leaf_netcacheEgress_access_bf1_tbl.action_run, leaf_netcacheEgress_access_bf1_tbl.hit, leaf_netcacheEgress_access_bf2_tbl.action_run, leaf_netcacheEgress_access_bf2_tbl.hit, leaf_netcacheEgress_access_bf3_tbl.action_run, leaf_netcacheEgress_access_bf3_tbl.hit, leaf_netcacheEgress_access_cache_frequency_tbl.action_run, leaf_netcacheEgress_access_cache_frequency_tbl.hit, leaf_netcacheEgress_access_cm1_tbl.action_run, leaf_netcacheEgress_access_cm1_tbl.hit, leaf_netcacheEgress_access_cm2_tbl.action_run, leaf_netcacheEgress_access_cm2_tbl.hit, leaf_netcacheEgress_access_cm3_tbl.action_run, leaf_netcacheEgress_access_cm3_tbl.hit, leaf_netcacheEgress_access_cm4_tbl.action_run, leaf_netcacheEgress_access_cm4_tbl.hit, leaf_netcacheEgress_access_deleted_tbl.action_run, leaf_netcacheEgress_access_deleted_tbl.hit, leaf_netcacheEgress_access_latest_tbl.action_run, leaf_netcacheEgress_access_latest_tbl.hit, leaf_netcacheEgress_access_savedseq_tbl.action_run, leaf_netcacheEgress_access_savedseq_tbl.hit, leaf_netcacheEgress_access_seq_tbl.action_run, leaf_netcacheEgress_access_seq_tbl.hit, leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run, leaf_netcacheEgress_add_and_remove_value_header_tbl.hit, leaf_netcacheEgress_bypass_egress_tbl.action_run, leaf_netcacheEgress_bypass_egress_tbl.hit, leaf_netcacheEgress_cm1_reg, leaf_netcacheEgress_cm1_reg__dbg0, leaf_netcacheEgress_cm1_reg__last0_old_value, leaf_netcacheEgress_cm1_reg__last0_old_value__dbg, leaf_netcacheEgress_cm1_reg__last0_value, leaf_netcacheEgress_cm1_reg__last0_value__dbg, leaf_netcacheEgress_cm1_reg__last_index, leaf_netcacheEgress_cm1_reg__last_index__dbg, leaf_netcacheEgress_cm1_reg__last_old_value, leaf_netcacheEgress_cm1_reg__last_old_value__dbg, leaf_netcacheEgress_cm1_reg__last_value, leaf_netcacheEgress_cm1_reg__last_value__dbg, leaf_netcacheEgress_cm1_reg__last_write_site, leaf_netcacheEgress_cm1_reg__next_write_site, leaf_netcacheEgress_cm1_reg__wrote_any, leaf_netcacheEgress_cm1_reg__wrote_any__dbg, leaf_netcacheEgress_cm1_reg__wrote_index0, leaf_netcacheEgress_cm1_reg__wrote_index0__dbg, leaf_netcacheEgress_cm2_reg, leaf_netcacheEgress_cm2_reg__dbg0, leaf_netcacheEgress_cm2_reg__last0_old_value, leaf_netcacheEgress_cm2_reg__last0_old_value__dbg, leaf_netcacheEgress_cm2_reg__last0_value, leaf_netcacheEgress_cm2_reg__last0_value__dbg, leaf_netcacheEgress_cm2_reg__last_index, leaf_netcacheEgress_cm2_reg__last_index__dbg, leaf_netcacheEgress_cm2_reg__last_old_value, leaf_netcacheEgress_cm2_reg__last_old_value__dbg, leaf_netcacheEgress_cm2_reg__last_value, leaf_netcacheEgress_cm2_reg__last_value__dbg, leaf_netcacheEgress_cm2_reg__last_write_site, leaf_netcacheEgress_cm2_reg__next_write_site, leaf_netcacheEgress_cm2_reg__wrote_any, leaf_netcacheEgress_cm2_reg__wrote_any__dbg, leaf_netcacheEgress_cm2_reg__wrote_index0, leaf_netcacheEgress_cm2_reg__wrote_index0__dbg, leaf_netcacheEgress_cm3_reg__dbg0, leaf_netcacheEgress_cm3_reg__last0_old_value, leaf_netcacheEgress_cm3_reg__last0_old_value__dbg, leaf_netcacheEgress_cm3_reg__last0_value, leaf_netcacheEgress_cm3_reg__last0_value__dbg, leaf_netcacheEgress_cm3_reg__last_index, leaf_netcacheEgress_cm3_reg__last_index__dbg, leaf_netcacheEgress_cm3_reg__last_old_value, leaf_netcacheEgress_cm3_reg__last_old_value__dbg, leaf_netcacheEgress_cm3_reg__last_value, leaf_netcacheEgress_cm3_reg__last_value__dbg, leaf_netcacheEgress_cm3_reg__last_write_site, leaf_netcacheEgress_cm3_reg__next_write_site, leaf_netcacheEgress_cm3_reg__wrote_any, leaf_netcacheEgress_cm3_reg__wrote_any__dbg, leaf_netcacheEgress_cm3_reg__wrote_index0, leaf_netcacheEgress_cm3_reg__wrote_index0__dbg, leaf_netcacheEgress_cm4_reg__dbg0, leaf_netcacheEgress_cm4_reg__last0_old_value, leaf_netcacheEgress_cm4_reg__last0_old_value__dbg, leaf_netcacheEgress_cm4_reg__last0_value, leaf_netcacheEgress_cm4_reg__last0_value__dbg, leaf_netcacheEgress_cm4_reg__last_index, leaf_netcacheEgress_cm4_reg__last_index__dbg, leaf_netcacheEgress_cm4_reg__last_old_value, leaf_netcacheEgress_cm4_reg__last_old_value__dbg, leaf_netcacheEgress_cm4_reg__last_value, leaf_netcacheEgress_cm4_reg__last_value__dbg, leaf_netcacheEgress_cm4_reg__last_write_site, leaf_netcacheEgress_cm4_reg__next_write_site, leaf_netcacheEgress_cm4_reg__wrote_any, leaf_netcacheEgress_cm4_reg__wrote_any__dbg, leaf_netcacheEgress_cm4_reg__wrote_index0, leaf_netcacheEgress_cm4_reg__wrote_index0__dbg, leaf_netcacheEgress_deleted_reg, leaf_netcacheEgress_deleted_reg__dbg0, leaf_netcacheEgress_deleted_reg__last0_old_value, leaf_netcacheEgress_deleted_reg__last0_old_value__dbg, leaf_netcacheEgress_deleted_reg__last0_value, leaf_netcacheEgress_deleted_reg__last0_value__dbg, leaf_netcacheEgress_deleted_reg__last_index, leaf_netcacheEgress_deleted_reg__last_index__dbg, leaf_netcacheEgress_deleted_reg__last_old_value, leaf_netcacheEgress_deleted_reg__last_old_value__dbg, leaf_netcacheEgress_deleted_reg__last_value, leaf_netcacheEgress_deleted_reg__last_value__dbg, leaf_netcacheEgress_deleted_reg__last_write_site, leaf_netcacheEgress_deleted_reg__next_write_site, leaf_netcacheEgress_deleted_reg__wrote_any, leaf_netcacheEgress_deleted_reg__wrote_any__dbg, leaf_netcacheEgress_deleted_reg__wrote_index0, leaf_netcacheEgress_deleted_reg__wrote_index0__dbg, leaf_netcacheEgress_eg_port_forward_tbl.action_run, leaf_netcacheEgress_eg_port_forward_tbl.hit, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_9, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid_7, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.reflector_port_7, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.switchos_sid_11, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_6, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_10, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_12, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_getreq_pop_to_getreq_by_mirroring.server_sid_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.client_sid_4, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.server_port, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.reflector_port, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid, leaf_netcacheEgress_is_hot_tbl.action_run, leaf_netcacheEgress_is_hot_tbl.hit, leaf_netcacheEgress_is_report_tbl.action_run, leaf_netcacheEgress_is_report_tbl.hit, leaf_netcacheEgress_lastclone_lastscansplit_tbl.action_run, leaf_netcacheEgress_lastclone_lastscansplit_tbl.hit, leaf_netcacheEgress_latest_reg, leaf_netcacheEgress_latest_reg__dbg0, leaf_netcacheEgress_latest_reg__last0_old_value, leaf_netcacheEgress_latest_reg__last0_old_value__dbg, leaf_netcacheEgress_latest_reg__last0_value, leaf_netcacheEgress_latest_reg__last0_value__dbg, leaf_netcacheEgress_latest_reg__last_index, leaf_netcacheEgress_latest_reg__last_index__dbg, leaf_netcacheEgress_latest_reg__last_old_value, leaf_netcacheEgress_latest_reg__last_old_value__dbg, leaf_netcacheEgress_latest_reg__last_value, leaf_netcacheEgress_latest_reg__last_value__dbg, leaf_netcacheEgress_latest_reg__last_write_site, leaf_netcacheEgress_latest_reg__next_write_site, leaf_netcacheEgress_latest_reg__wrote_any, leaf_netcacheEgress_latest_reg__wrote_any__dbg, leaf_netcacheEgress_latest_reg__wrote_index0, leaf_netcacheEgress_latest_reg__wrote_index0__dbg, leaf_netcacheEgress_prepare_for_cachepop_tbl.action_run, leaf_netcacheEgress_prepare_for_cachepop_tbl.hit, leaf_netcacheEgress_prepare_for_cachepop_tbl.netcacheEgress_set_server_sid_and_port.server_sid_2, leaf_netcacheEgress_save_client_udpport_tbl.action_run, leaf_netcacheEgress_save_client_udpport_tbl.hit, leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run, leaf_netcacheEgress_update_ipmac_srcport_tbl.hit, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_ip_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_mac_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_ip_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_mac_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_port_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_ip_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_mac_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_port_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_ip_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_port, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_mac, leaf_netcacheEgress_update_pktlen_tbl.action_run, leaf_netcacheEgress_update_pktlen_tbl.hit, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.iplen_delta, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.udplen_delta, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_vallen_tbl.action_run, leaf_netcacheEgress_update_vallen_tbl.hit, leaf_netcacheEgress_vallen_reg, leaf_netcacheEgress_vallen_reg__dbg0, leaf_netcacheEgress_vallen_reg__last0_old_value, leaf_netcacheEgress_vallen_reg__last0_old_value__dbg, leaf_netcacheEgress_vallen_reg__last0_value, leaf_netcacheEgress_vallen_reg__last0_value__dbg, leaf_netcacheEgress_vallen_reg__last_index, leaf_netcacheEgress_vallen_reg__last_index__dbg, leaf_netcacheEgress_vallen_reg__last_old_value, leaf_netcacheEgress_vallen_reg__last_old_value__dbg, leaf_netcacheEgress_vallen_reg__last_value, leaf_netcacheEgress_vallen_reg__last_value__dbg, leaf_netcacheEgress_vallen_reg__last_write_site, leaf_netcacheEgress_vallen_reg__next_write_site, leaf_netcacheEgress_vallen_reg__wrote_any, leaf_netcacheEgress_vallen_reg__wrote_any__dbg, leaf_netcacheEgress_vallen_reg__wrote_index0, leaf_netcacheEgress_vallen_reg__wrote_index0__dbg, leaf_netcacheIngress_hash_for_partition_tbl.action_run, leaf_netcacheIngress_hash_for_partition_tbl.hit, leaf_netcacheIngress_hash_spine_partition_tbl.action_run, leaf_netcacheIngress_hash_spine_partition_tbl.hit, leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.eport_5, leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.spine_sid_1, leaf_p4b_checksum_error, leaf_p4b_checksum_updated, leaf_p4b_checksum_verified, leaf_p4b_clone_e2e, leaf_p4b_clone_i2e, leaf_p4b_clone_i2i, leaf_p4b_digest, leaf_p4b_recirculate, leaf_pkt_external, leaf_standard_metadata.egress_port, procurator_bad, procurator_step;
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
  assume (forall i:bv32 :: leaf_netcacheEgress_cm1_reg[i] == 0bv16);
  assume leaf_netcacheEgress_cm1_reg[0bv32] == 0bv16;
  assume (forall i:bv32 :: leaf_netcacheEgress_cm2_reg[i] == 0bv16);
  assume leaf_netcacheEgress_cm2_reg[0bv32] == 0bv16;
  assume (forall i:bv32 :: leaf_netcacheEgress_cm3_reg[i] == 0bv16);
  assume leaf_netcacheEgress_cm3_reg[0bv32] == 0bv16;
  assume (forall i:bv32 :: leaf_netcacheEgress_cm4_reg[i] == 0bv16);
  assume leaf_netcacheEgress_cm4_reg[0bv32] == 0bv16;
  assume (forall i:bv32 :: leaf_netcacheEgress_deleted_reg[i] == 0bv1);
  assume leaf_netcacheEgress_deleted_reg[0bv32] == 0bv1;
  assume (forall i:bv32 :: leaf_netcacheEgress_latest_reg[i] == 0bv1);
  assume leaf_netcacheEgress_latest_reg[0bv32] == 0bv1;
  assume (forall i:bv32 :: leaf_netcacheEgress_vallen_reg[i] == 0bv16);
  assume leaf_netcacheEgress_vallen_reg[0bv32] == 0bv16;
  // initialize register write tracking (debug)
  leaf_netcacheEgress_cm1_reg__last_index := 0bv32;
  leaf_netcacheEgress_cm1_reg__last_value := 0bv16;
  leaf_netcacheEgress_cm1_reg__last_old_value := 0bv16;
  leaf_netcacheEgress_cm1_reg__wrote_any := false;
  leaf_netcacheEgress_cm1_reg__wrote_index0 := false;
  leaf_netcacheEgress_cm1_reg__next_write_site := 0;
  leaf_netcacheEgress_cm1_reg__last_write_site := 0;
  leaf_netcacheEgress_cm1_reg__last0_old_value := 0bv16;
  leaf_netcacheEgress_cm1_reg__last0_value := 0bv16;
  leaf_netcacheEgress_cm2_reg__last_index := 0bv32;
  leaf_netcacheEgress_cm2_reg__last_value := 0bv16;
  leaf_netcacheEgress_cm2_reg__last_old_value := 0bv16;
  leaf_netcacheEgress_cm2_reg__wrote_any := false;
  leaf_netcacheEgress_cm2_reg__wrote_index0 := false;
  leaf_netcacheEgress_cm2_reg__next_write_site := 0;
  leaf_netcacheEgress_cm2_reg__last_write_site := 0;
  leaf_netcacheEgress_cm2_reg__last0_old_value := 0bv16;
  leaf_netcacheEgress_cm2_reg__last0_value := 0bv16;
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
  leaf_netcacheEgress_deleted_reg__last_index := 0bv32;
  leaf_netcacheEgress_deleted_reg__last_value := 0bv1;
  leaf_netcacheEgress_deleted_reg__last_old_value := 0bv1;
  leaf_netcacheEgress_deleted_reg__wrote_any := false;
  leaf_netcacheEgress_deleted_reg__wrote_index0 := false;
  leaf_netcacheEgress_deleted_reg__next_write_site := 0;
  leaf_netcacheEgress_deleted_reg__last_write_site := 0;
  leaf_netcacheEgress_deleted_reg__last0_old_value := 0bv1;
  leaf_netcacheEgress_deleted_reg__last0_value := 0bv1;
  leaf_netcacheEgress_latest_reg__last_index := 0bv32;
  leaf_netcacheEgress_latest_reg__last_value := 0bv1;
  leaf_netcacheEgress_latest_reg__last_old_value := 0bv1;
  leaf_netcacheEgress_latest_reg__wrote_any := false;
  leaf_netcacheEgress_latest_reg__wrote_index0 := false;
  leaf_netcacheEgress_latest_reg__next_write_site := 0;
  leaf_netcacheEgress_latest_reg__last_write_site := 0;
  leaf_netcacheEgress_latest_reg__last0_old_value := 0bv1;
  leaf_netcacheEgress_latest_reg__last0_value := 0bv1;
  leaf_netcacheEgress_vallen_reg__last_index := 0bv32;
  leaf_netcacheEgress_vallen_reg__last_value := 0bv16;
  leaf_netcacheEgress_vallen_reg__last_old_value := 0bv16;
  leaf_netcacheEgress_vallen_reg__wrote_any := false;
  leaf_netcacheEgress_vallen_reg__wrote_index0 := false;
  leaf_netcacheEgress_vallen_reg__next_write_site := 0;
  leaf_netcacheEgress_vallen_reg__last_write_site := 0;
  leaf_netcacheEgress_vallen_reg__last0_old_value := 0bv16;
  leaf_netcacheEgress_vallen_reg__last0_value := 0bv16;

  procurator_step := 0;
  procurator_bad := false;
  // step 0: host_send -> io
  // inject packet into connected node (host -> node)
  if (leaf_inbox_count < 1) {
    assume leaf_inbox_count < 1;
    havoc io_hdr.udp_hdr.srcPort;
    havoc io_hdr.op_hdr.keylolo;
    havoc io_hdr.op_hdr.keylohi;
    havoc io_hdr.op_hdr.keyhilo;
    havoc io_hdr.op_hdr.keyhihilo;
    havoc io_hdr.op_hdr.keyhihihi;
    havoc io_hdr.vallen_hdr.vallen;
    havoc io_hdr.shadowtype_hdr.shadowtype;
    havoc io_meta.hashval_for_spine_partition;
    havoc io_hdr_eg.udp_hdr.srcPort;
    havoc io_hdr_eg.udp_hdr.dstPort;
    havoc io_hdr_eg.udp_hdr.hdrlen;
    havoc io_hdr_eg.vallen_hdr.vallen;
    havoc io_hdr_eg.inswitch_hdr.hot_threshold;
    havoc io_hdr_eg.inswitch_hdr.hashval_for_cm1;
    havoc io_hdr_eg.inswitch_hdr.hashval_for_cm2;
    havoc io_hdr_eg.inswitch_hdr.hashval_for_cm3;
    havoc io_hdr_eg.inswitch_hdr.hashval_for_cm4;
    havoc io_hdr_eg.inswitch_hdr.idx;
    havoc io_hdr_eg.stat_hdr.stat;
    havoc io_hdr_eg.stat_hdr.nodeidx_foreval;
    havoc io_hdr_eg.clone_hdr.client_udpport;
    havoc io_hdr_eg.clone_hdr.server_udpport;
    havoc io_hdr_eg.fraginfo_hdr.cur_fragidx;
    io_hdr.ethernet_hdr.etherType := 2048bv16;
    io_hdr.ipv4_hdr.protocol := 17bv8;
    io_hdr.udp_hdr.dstPort := 5008bv16;
    io_hdr.op_hdr.optype := 288bv16;
    io_meta.bypass_egress := 0bv1;
    io_meta.spine_sid := 0bv10;
    io_hdr_eg.op_hdr.optype := 288bv16;
    io_meta.cm1_predicate := 0bv4;
    io_meta.cm2_predicate := 0bv4;
    io_meta.cm3_predicate := 0bv4;
    io_meta.cm4_predicate := 0bv4;
    io_meta.is_hot := 0bv1;
    io_meta.is_report1 := 0bv1;
    io_meta.is_report2 := 0bv1;
    io_meta.is_report3 := 0bv1;
    io_meta.is_report := 0bv1;
    io_meta.is_latest := 0bv1;
    io_meta.is_deleted := 0bv1;
    io_meta.is_lastclone_for_pktloss := 0bv1;
    io_hdr_eg.clone_hdr.server_sid := 20bv10;
    io_hdr_eg.clone_hdr.clonenum_for_pktloss := 1bv16;
    io_hdr_eg.inswitch_hdr.is_cached := 0bv1;
    io_hdr_eg.inswitch_hdr.is_sampled := 0bv1;
    io_hdr_eg.inswitch_hdr.client_sid := 0bv10;
    leaf_hdr.ethernet_hdr.etherType := io_hdr.ethernet_hdr.etherType;
    leaf_hdr.ipv4_hdr.protocol := io_hdr.ipv4_hdr.protocol;
    leaf_hdr.udp_hdr.srcPort := io_hdr.udp_hdr.srcPort;
    leaf_hdr.udp_hdr.dstPort := io_hdr.udp_hdr.dstPort;
    leaf_hdr.op_hdr.optype := io_hdr.op_hdr.optype;
    leaf_hdr.op_hdr.keylolo := io_hdr.op_hdr.keylolo;
    leaf_hdr.op_hdr.keylohi := io_hdr.op_hdr.keylohi;
    leaf_hdr.op_hdr.keyhilo := io_hdr.op_hdr.keyhilo;
    leaf_hdr.op_hdr.keyhihilo := io_hdr.op_hdr.keyhihilo;
    leaf_hdr.op_hdr.keyhihihi := io_hdr.op_hdr.keyhihihi;
    leaf_hdr.vallen_hdr.vallen := io_hdr.vallen_hdr.vallen;
    leaf_hdr.shadowtype_hdr.shadowtype := io_hdr.shadowtype_hdr.shadowtype;
    leaf_meta.hashval_for_spine_partition := io_meta.hashval_for_spine_partition;
    leaf_meta.cm1_predicate := io_meta.cm1_predicate;
    leaf_meta.cm2_predicate := io_meta.cm2_predicate;
    leaf_meta.cm3_predicate := io_meta.cm3_predicate;
    leaf_meta.cm4_predicate := io_meta.cm4_predicate;
    leaf_meta.is_hot := io_meta.is_hot;
    leaf_meta.is_report1 := io_meta.is_report1;
    leaf_meta.is_report2 := io_meta.is_report2;
    leaf_meta.is_report3 := io_meta.is_report3;
    leaf_meta.is_report := io_meta.is_report;
    leaf_meta.is_latest := io_meta.is_latest;
    leaf_meta.is_deleted := io_meta.is_deleted;
    leaf_meta.is_lastclone_for_pktloss := io_meta.is_lastclone_for_pktloss;
    leaf_meta.spine_sid := io_meta.spine_sid;
    leaf_meta.bypass_egress := io_meta.bypass_egress;
    leaf_hdr_eg.udp_hdr.srcPort := io_hdr_eg.udp_hdr.srcPort;
    leaf_hdr_eg.udp_hdr.dstPort := io_hdr_eg.udp_hdr.dstPort;
    leaf_hdr_eg.udp_hdr.hdrlen := io_hdr_eg.udp_hdr.hdrlen;
    leaf_hdr_eg.op_hdr.optype := io_hdr_eg.op_hdr.optype;
    leaf_hdr_eg.vallen_hdr.vallen := io_hdr_eg.vallen_hdr.vallen;
    leaf_hdr_eg.inswitch_hdr.is_cached := io_hdr_eg.inswitch_hdr.is_cached;
    leaf_hdr_eg.inswitch_hdr.is_sampled := io_hdr_eg.inswitch_hdr.is_sampled;
    leaf_hdr_eg.inswitch_hdr.client_sid := io_hdr_eg.inswitch_hdr.client_sid;
    leaf_hdr_eg.inswitch_hdr.hot_threshold := io_hdr_eg.inswitch_hdr.hot_threshold;
    leaf_hdr_eg.inswitch_hdr.hashval_for_cm1 := io_hdr_eg.inswitch_hdr.hashval_for_cm1;
    leaf_hdr_eg.inswitch_hdr.hashval_for_cm2 := io_hdr_eg.inswitch_hdr.hashval_for_cm2;
    leaf_hdr_eg.inswitch_hdr.hashval_for_cm3 := io_hdr_eg.inswitch_hdr.hashval_for_cm3;
    leaf_hdr_eg.inswitch_hdr.hashval_for_cm4 := io_hdr_eg.inswitch_hdr.hashval_for_cm4;
    leaf_hdr_eg.inswitch_hdr.idx := io_hdr_eg.inswitch_hdr.idx;
    leaf_hdr_eg.stat_hdr.stat := io_hdr_eg.stat_hdr.stat;
    leaf_hdr_eg.stat_hdr.nodeidx_foreval := io_hdr_eg.stat_hdr.nodeidx_foreval;
    leaf_hdr_eg.clone_hdr.clonenum_for_pktloss := io_hdr_eg.clone_hdr.clonenum_for_pktloss;
    leaf_hdr_eg.clone_hdr.client_udpport := io_hdr_eg.clone_hdr.client_udpport;
    leaf_hdr_eg.clone_hdr.server_sid := io_hdr_eg.clone_hdr.server_sid;
    leaf_hdr_eg.clone_hdr.server_udpport := io_hdr_eg.clone_hdr.server_udpport;
    leaf_hdr_eg.fraginfo_hdr.cur_fragidx := io_hdr_eg.fraginfo_hdr.cur_fragidx;
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
  // DSL statements (per-pass instrumentation)
  if (leaf_pkt_external) {
    leaf_forward := true;
    leaf_drop := false;
    leaf_standard_metadata.egress_port := 4bv9;
  }
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
  // Register debug snapshot
  leaf_netcacheEgress_cm1_reg__dbg0 := leaf_netcacheEgress_cm1_reg[0bv32];
  leaf_netcacheEgress_cm1_reg__last_index__dbg := leaf_netcacheEgress_cm1_reg__last_index;
  leaf_netcacheEgress_cm1_reg__last_value__dbg := leaf_netcacheEgress_cm1_reg__last_value;
  leaf_netcacheEgress_cm1_reg__last_old_value__dbg := leaf_netcacheEgress_cm1_reg__last_old_value;
  leaf_netcacheEgress_cm1_reg__wrote_any__dbg := leaf_netcacheEgress_cm1_reg__wrote_any;
  leaf_netcacheEgress_cm1_reg__wrote_index0__dbg := leaf_netcacheEgress_cm1_reg__wrote_index0;
  leaf_netcacheEgress_cm1_reg__last0_old_value__dbg := leaf_netcacheEgress_cm1_reg__last0_old_value;
  leaf_netcacheEgress_cm1_reg__last0_value__dbg := leaf_netcacheEgress_cm1_reg__last0_value;
  leaf_netcacheEgress_cm2_reg__dbg0 := leaf_netcacheEgress_cm2_reg[0bv32];
  leaf_netcacheEgress_cm2_reg__last_index__dbg := leaf_netcacheEgress_cm2_reg__last_index;
  leaf_netcacheEgress_cm2_reg__last_value__dbg := leaf_netcacheEgress_cm2_reg__last_value;
  leaf_netcacheEgress_cm2_reg__last_old_value__dbg := leaf_netcacheEgress_cm2_reg__last_old_value;
  leaf_netcacheEgress_cm2_reg__wrote_any__dbg := leaf_netcacheEgress_cm2_reg__wrote_any;
  leaf_netcacheEgress_cm2_reg__wrote_index0__dbg := leaf_netcacheEgress_cm2_reg__wrote_index0;
  leaf_netcacheEgress_cm2_reg__last0_old_value__dbg := leaf_netcacheEgress_cm2_reg__last0_old_value;
  leaf_netcacheEgress_cm2_reg__last0_value__dbg := leaf_netcacheEgress_cm2_reg__last0_value;
  leaf_netcacheEgress_cm3_reg__dbg0 := leaf_netcacheEgress_cm3_reg[0bv32];
  leaf_netcacheEgress_cm3_reg__last_index__dbg := leaf_netcacheEgress_cm3_reg__last_index;
  leaf_netcacheEgress_cm3_reg__last_value__dbg := leaf_netcacheEgress_cm3_reg__last_value;
  leaf_netcacheEgress_cm3_reg__last_old_value__dbg := leaf_netcacheEgress_cm3_reg__last_old_value;
  leaf_netcacheEgress_cm3_reg__wrote_any__dbg := leaf_netcacheEgress_cm3_reg__wrote_any;
  leaf_netcacheEgress_cm3_reg__wrote_index0__dbg := leaf_netcacheEgress_cm3_reg__wrote_index0;
  leaf_netcacheEgress_cm3_reg__last0_old_value__dbg := leaf_netcacheEgress_cm3_reg__last0_old_value;
  leaf_netcacheEgress_cm3_reg__last0_value__dbg := leaf_netcacheEgress_cm3_reg__last0_value;
  leaf_netcacheEgress_cm4_reg__dbg0 := leaf_netcacheEgress_cm4_reg[0bv32];
  leaf_netcacheEgress_cm4_reg__last_index__dbg := leaf_netcacheEgress_cm4_reg__last_index;
  leaf_netcacheEgress_cm4_reg__last_value__dbg := leaf_netcacheEgress_cm4_reg__last_value;
  leaf_netcacheEgress_cm4_reg__last_old_value__dbg := leaf_netcacheEgress_cm4_reg__last_old_value;
  leaf_netcacheEgress_cm4_reg__wrote_any__dbg := leaf_netcacheEgress_cm4_reg__wrote_any;
  leaf_netcacheEgress_cm4_reg__wrote_index0__dbg := leaf_netcacheEgress_cm4_reg__wrote_index0;
  leaf_netcacheEgress_cm4_reg__last0_old_value__dbg := leaf_netcacheEgress_cm4_reg__last0_old_value;
  leaf_netcacheEgress_cm4_reg__last0_value__dbg := leaf_netcacheEgress_cm4_reg__last0_value;
  leaf_netcacheEgress_deleted_reg__dbg0 := leaf_netcacheEgress_deleted_reg[0bv32];
  leaf_netcacheEgress_deleted_reg__last_index__dbg := leaf_netcacheEgress_deleted_reg__last_index;
  leaf_netcacheEgress_deleted_reg__last_value__dbg := leaf_netcacheEgress_deleted_reg__last_value;
  leaf_netcacheEgress_deleted_reg__last_old_value__dbg := leaf_netcacheEgress_deleted_reg__last_old_value;
  leaf_netcacheEgress_deleted_reg__wrote_any__dbg := leaf_netcacheEgress_deleted_reg__wrote_any;
  leaf_netcacheEgress_deleted_reg__wrote_index0__dbg := leaf_netcacheEgress_deleted_reg__wrote_index0;
  leaf_netcacheEgress_deleted_reg__last0_old_value__dbg := leaf_netcacheEgress_deleted_reg__last0_old_value;
  leaf_netcacheEgress_deleted_reg__last0_value__dbg := leaf_netcacheEgress_deleted_reg__last0_value;
  leaf_netcacheEgress_latest_reg__dbg0 := leaf_netcacheEgress_latest_reg[0bv32];
  leaf_netcacheEgress_latest_reg__last_index__dbg := leaf_netcacheEgress_latest_reg__last_index;
  leaf_netcacheEgress_latest_reg__last_value__dbg := leaf_netcacheEgress_latest_reg__last_value;
  leaf_netcacheEgress_latest_reg__last_old_value__dbg := leaf_netcacheEgress_latest_reg__last_old_value;
  leaf_netcacheEgress_latest_reg__wrote_any__dbg := leaf_netcacheEgress_latest_reg__wrote_any;
  leaf_netcacheEgress_latest_reg__wrote_index0__dbg := leaf_netcacheEgress_latest_reg__wrote_index0;
  leaf_netcacheEgress_latest_reg__last0_old_value__dbg := leaf_netcacheEgress_latest_reg__last0_old_value;
  leaf_netcacheEgress_latest_reg__last0_value__dbg := leaf_netcacheEgress_latest_reg__last0_value;
  leaf_netcacheEgress_vallen_reg__dbg0 := leaf_netcacheEgress_vallen_reg[0bv32];
  leaf_netcacheEgress_vallen_reg__last_index__dbg := leaf_netcacheEgress_vallen_reg__last_index;
  leaf_netcacheEgress_vallen_reg__last_value__dbg := leaf_netcacheEgress_vallen_reg__last_value;
  leaf_netcacheEgress_vallen_reg__last_old_value__dbg := leaf_netcacheEgress_vallen_reg__last_old_value;
  leaf_netcacheEgress_vallen_reg__wrote_any__dbg := leaf_netcacheEgress_vallen_reg__wrote_any;
  leaf_netcacheEgress_vallen_reg__wrote_index0__dbg := leaf_netcacheEgress_vallen_reg__wrote_index0;
  leaf_netcacheEgress_vallen_reg__last0_old_value__dbg := leaf_netcacheEgress_vallen_reg__last0_old_value;
  leaf_netcacheEgress_vallen_reg__last0_value__dbg := leaf_netcacheEgress_vallen_reg__last0_value;
  // Global assertions (accumulated into procurator_bad)
  if (!(leaf_drop)) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  assert !procurator_bad;
}


procedure ULTIMATE.start() returns()
  modifies io_hdr.ethernet_hdr.etherType, io_hdr.ipv4_hdr.protocol, io_hdr.op_hdr.keyhihihi, io_hdr.op_hdr.keyhihilo, io_hdr.op_hdr.keyhilo, io_hdr.op_hdr.keylohi, io_hdr.op_hdr.keylolo, io_hdr.op_hdr.optype, io_hdr.shadowtype_hdr.shadowtype, io_hdr.udp_hdr.dstPort, io_hdr.udp_hdr.srcPort, io_hdr.vallen_hdr.vallen, io_hdr_eg.clone_hdr.client_udpport, io_hdr_eg.clone_hdr.clonenum_for_pktloss, io_hdr_eg.clone_hdr.server_sid, io_hdr_eg.clone_hdr.server_udpport, io_hdr_eg.fraginfo_hdr.cur_fragidx, io_hdr_eg.inswitch_hdr.client_sid, io_hdr_eg.inswitch_hdr.hashval_for_cm1, io_hdr_eg.inswitch_hdr.hashval_for_cm2, io_hdr_eg.inswitch_hdr.hashval_for_cm3, io_hdr_eg.inswitch_hdr.hashval_for_cm4, io_hdr_eg.inswitch_hdr.hot_threshold, io_hdr_eg.inswitch_hdr.idx, io_hdr_eg.inswitch_hdr.is_cached, io_hdr_eg.inswitch_hdr.is_sampled, io_hdr_eg.op_hdr.optype, io_hdr_eg.stat_hdr.nodeidx_foreval, io_hdr_eg.stat_hdr.stat, io_hdr_eg.udp_hdr.dstPort, io_hdr_eg.udp_hdr.hdrlen, io_hdr_eg.udp_hdr.srcPort, io_hdr_eg.vallen_hdr.vallen, io_inbox_count, io_meta.bypass_egress, io_meta.cm1_predicate, io_meta.cm2_predicate, io_meta.cm3_predicate, io_meta.cm4_predicate, io_meta.hashval_for_spine_partition, io_meta.is_deleted, io_meta.is_hot, io_meta.is_lastclone_for_pktloss, io_meta.is_latest, io_meta.is_report, io_meta.is_report1, io_meta.is_report2, io_meta.is_report3, io_meta.spine_sid, io_pkt_external, leaf_cm1_res_0, leaf_cm2_res_0, leaf_cm3_res_0, leaf_cm4_res_0, leaf_drop, leaf_hdr.ethernet_hdr.etherType, leaf_hdr.ipv4_hdr.protocol, leaf_hdr.op_hdr.keyhihihi, leaf_hdr.op_hdr.keyhihilo, leaf_hdr.op_hdr.keyhilo, leaf_hdr.op_hdr.keylohi, leaf_hdr.op_hdr.keylolo, leaf_hdr.op_hdr.optype, leaf_hdr.shadowtype_hdr.shadowtype, leaf_hdr.udp_hdr.dstPort, leaf_hdr.udp_hdr.srcPort, leaf_hdr.vallen_hdr.vallen, leaf_hdr_eg.clone_hdr.client_udpport, leaf_hdr_eg.clone_hdr.clonenum_for_pktloss, leaf_hdr_eg.clone_hdr.server_sid, leaf_hdr_eg.clone_hdr.server_udpport, leaf_hdr_eg.fraginfo_hdr.cur_fragidx, leaf_hdr_eg.inswitch_hdr.client_sid, leaf_hdr_eg.inswitch_hdr.hashval_for_cm1, leaf_hdr_eg.inswitch_hdr.hashval_for_cm2, leaf_hdr_eg.inswitch_hdr.hashval_for_cm3, leaf_hdr_eg.inswitch_hdr.hashval_for_cm4, leaf_hdr_eg.inswitch_hdr.hot_threshold, leaf_hdr_eg.inswitch_hdr.idx, leaf_hdr_eg.inswitch_hdr.is_cached, leaf_hdr_eg.inswitch_hdr.is_sampled, leaf_hdr_eg.op_hdr.optype, leaf_hdr_eg.stat_hdr.nodeidx_foreval, leaf_hdr_eg.stat_hdr.stat, leaf_hdr_eg.udp_hdr.dstPort, leaf_hdr_eg.udp_hdr.hdrlen, leaf_hdr_eg.udp_hdr.srcPort, leaf_hdr_eg.vallen_hdr.vallen, leaf_inbox_count, leaf_isValid, leaf_meta.bypass_egress, leaf_meta.cm1_predicate, leaf_meta.cm2_predicate, leaf_meta.cm3_predicate, leaf_meta.cm4_predicate, leaf_meta.hashval_for_spine_partition, leaf_meta.is_deleted, leaf_meta.is_hot, leaf_meta.is_lastclone_for_pktloss, leaf_meta.is_latest, leaf_meta.is_report, leaf_meta.is_report1, leaf_meta.is_report2, leaf_meta.is_report3, leaf_meta.spine_sid, leaf_netcacheEgress_access_bf1_tbl.action_run, leaf_netcacheEgress_access_bf1_tbl.hit, leaf_netcacheEgress_access_bf2_tbl.action_run, leaf_netcacheEgress_access_bf2_tbl.hit, leaf_netcacheEgress_access_bf3_tbl.action_run, leaf_netcacheEgress_access_bf3_tbl.hit, leaf_netcacheEgress_access_cache_frequency_tbl.action_run, leaf_netcacheEgress_access_cache_frequency_tbl.hit, leaf_netcacheEgress_access_cm1_tbl.action_run, leaf_netcacheEgress_access_cm1_tbl.hit, leaf_netcacheEgress_access_cm2_tbl.action_run, leaf_netcacheEgress_access_cm2_tbl.hit, leaf_netcacheEgress_access_cm3_tbl.action_run, leaf_netcacheEgress_access_cm3_tbl.hit, leaf_netcacheEgress_access_cm4_tbl.action_run, leaf_netcacheEgress_access_cm4_tbl.hit, leaf_netcacheEgress_access_deleted_tbl.action_run, leaf_netcacheEgress_access_deleted_tbl.hit, leaf_netcacheEgress_access_latest_tbl.action_run, leaf_netcacheEgress_access_latest_tbl.hit, leaf_netcacheEgress_access_savedseq_tbl.action_run, leaf_netcacheEgress_access_savedseq_tbl.hit, leaf_netcacheEgress_access_seq_tbl.action_run, leaf_netcacheEgress_access_seq_tbl.hit, leaf_netcacheEgress_add_and_remove_value_header_tbl.action_run, leaf_netcacheEgress_add_and_remove_value_header_tbl.hit, leaf_netcacheEgress_bypass_egress_tbl.action_run, leaf_netcacheEgress_bypass_egress_tbl.hit, leaf_netcacheEgress_cm1_reg, leaf_netcacheEgress_cm1_reg__dbg0, leaf_netcacheEgress_cm1_reg__last0_old_value, leaf_netcacheEgress_cm1_reg__last0_old_value__dbg, leaf_netcacheEgress_cm1_reg__last0_value, leaf_netcacheEgress_cm1_reg__last0_value__dbg, leaf_netcacheEgress_cm1_reg__last_index, leaf_netcacheEgress_cm1_reg__last_index__dbg, leaf_netcacheEgress_cm1_reg__last_old_value, leaf_netcacheEgress_cm1_reg__last_old_value__dbg, leaf_netcacheEgress_cm1_reg__last_value, leaf_netcacheEgress_cm1_reg__last_value__dbg, leaf_netcacheEgress_cm1_reg__last_write_site, leaf_netcacheEgress_cm1_reg__next_write_site, leaf_netcacheEgress_cm1_reg__wrote_any, leaf_netcacheEgress_cm1_reg__wrote_any__dbg, leaf_netcacheEgress_cm1_reg__wrote_index0, leaf_netcacheEgress_cm1_reg__wrote_index0__dbg, leaf_netcacheEgress_cm2_reg, leaf_netcacheEgress_cm2_reg__dbg0, leaf_netcacheEgress_cm2_reg__last0_old_value, leaf_netcacheEgress_cm2_reg__last0_old_value__dbg, leaf_netcacheEgress_cm2_reg__last0_value, leaf_netcacheEgress_cm2_reg__last0_value__dbg, leaf_netcacheEgress_cm2_reg__last_index, leaf_netcacheEgress_cm2_reg__last_index__dbg, leaf_netcacheEgress_cm2_reg__last_old_value, leaf_netcacheEgress_cm2_reg__last_old_value__dbg, leaf_netcacheEgress_cm2_reg__last_value, leaf_netcacheEgress_cm2_reg__last_value__dbg, leaf_netcacheEgress_cm2_reg__last_write_site, leaf_netcacheEgress_cm2_reg__next_write_site, leaf_netcacheEgress_cm2_reg__wrote_any, leaf_netcacheEgress_cm2_reg__wrote_any__dbg, leaf_netcacheEgress_cm2_reg__wrote_index0, leaf_netcacheEgress_cm2_reg__wrote_index0__dbg, leaf_netcacheEgress_cm3_reg__dbg0, leaf_netcacheEgress_cm3_reg__last0_old_value, leaf_netcacheEgress_cm3_reg__last0_old_value__dbg, leaf_netcacheEgress_cm3_reg__last0_value, leaf_netcacheEgress_cm3_reg__last0_value__dbg, leaf_netcacheEgress_cm3_reg__last_index, leaf_netcacheEgress_cm3_reg__last_index__dbg, leaf_netcacheEgress_cm3_reg__last_old_value, leaf_netcacheEgress_cm3_reg__last_old_value__dbg, leaf_netcacheEgress_cm3_reg__last_value, leaf_netcacheEgress_cm3_reg__last_value__dbg, leaf_netcacheEgress_cm3_reg__last_write_site, leaf_netcacheEgress_cm3_reg__next_write_site, leaf_netcacheEgress_cm3_reg__wrote_any, leaf_netcacheEgress_cm3_reg__wrote_any__dbg, leaf_netcacheEgress_cm3_reg__wrote_index0, leaf_netcacheEgress_cm3_reg__wrote_index0__dbg, leaf_netcacheEgress_cm4_reg__dbg0, leaf_netcacheEgress_cm4_reg__last0_old_value, leaf_netcacheEgress_cm4_reg__last0_old_value__dbg, leaf_netcacheEgress_cm4_reg__last0_value, leaf_netcacheEgress_cm4_reg__last0_value__dbg, leaf_netcacheEgress_cm4_reg__last_index, leaf_netcacheEgress_cm4_reg__last_index__dbg, leaf_netcacheEgress_cm4_reg__last_old_value, leaf_netcacheEgress_cm4_reg__last_old_value__dbg, leaf_netcacheEgress_cm4_reg__last_value, leaf_netcacheEgress_cm4_reg__last_value__dbg, leaf_netcacheEgress_cm4_reg__last_write_site, leaf_netcacheEgress_cm4_reg__next_write_site, leaf_netcacheEgress_cm4_reg__wrote_any, leaf_netcacheEgress_cm4_reg__wrote_any__dbg, leaf_netcacheEgress_cm4_reg__wrote_index0, leaf_netcacheEgress_cm4_reg__wrote_index0__dbg, leaf_netcacheEgress_deleted_reg, leaf_netcacheEgress_deleted_reg__dbg0, leaf_netcacheEgress_deleted_reg__last0_old_value, leaf_netcacheEgress_deleted_reg__last0_old_value__dbg, leaf_netcacheEgress_deleted_reg__last0_value, leaf_netcacheEgress_deleted_reg__last0_value__dbg, leaf_netcacheEgress_deleted_reg__last_index, leaf_netcacheEgress_deleted_reg__last_index__dbg, leaf_netcacheEgress_deleted_reg__last_old_value, leaf_netcacheEgress_deleted_reg__last_old_value__dbg, leaf_netcacheEgress_deleted_reg__last_value, leaf_netcacheEgress_deleted_reg__last_value__dbg, leaf_netcacheEgress_deleted_reg__last_write_site, leaf_netcacheEgress_deleted_reg__next_write_site, leaf_netcacheEgress_deleted_reg__wrote_any, leaf_netcacheEgress_deleted_reg__wrote_any__dbg, leaf_netcacheEgress_deleted_reg__wrote_index0, leaf_netcacheEgress_deleted_reg__wrote_index0__dbg, leaf_netcacheEgress_eg_port_forward_tbl.action_run, leaf_netcacheEgress_eg_port_forward_tbl.hit, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_9, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_forward_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid_7, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.reflector_port_7, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_evict_loadfreq_inswitch_to_cache_evict_loadfreq_inswitch_ack_drop_and_clone.switchos_sid_11, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_6, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_cache_pop_inswitch_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_10, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.client_sid_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.server_port_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_getres_by_mirroring.stat_1, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.reflector_port_5, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq.switchos_sid_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.reflector_port_8, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_cache_pop_inswitch_nlatest_to_cache_pop_inswitch_ack_drop_and_clone.switchos_sid_12, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_getreq_pop_to_getreq_by_mirroring.server_sid_3, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.client_sid_4, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_pop_to_warmupack_by_mirroring.server_port, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.reflector_port, leaf_netcacheEgress_eg_port_forward_tbl.netcacheEgress_update_netcache_warmupreq_inswitch_to_netcache_warmupreq_inswitch_pop_clone_for_pktloss_and_warmupack.switchos_sid, leaf_netcacheEgress_is_hot_tbl.action_run, leaf_netcacheEgress_is_hot_tbl.hit, leaf_netcacheEgress_is_report_tbl.action_run, leaf_netcacheEgress_is_report_tbl.hit, leaf_netcacheEgress_lastclone_lastscansplit_tbl.action_run, leaf_netcacheEgress_lastclone_lastscansplit_tbl.hit, leaf_netcacheEgress_latest_reg, leaf_netcacheEgress_latest_reg__dbg0, leaf_netcacheEgress_latest_reg__last0_old_value, leaf_netcacheEgress_latest_reg__last0_old_value__dbg, leaf_netcacheEgress_latest_reg__last0_value, leaf_netcacheEgress_latest_reg__last0_value__dbg, leaf_netcacheEgress_latest_reg__last_index, leaf_netcacheEgress_latest_reg__last_index__dbg, leaf_netcacheEgress_latest_reg__last_old_value, leaf_netcacheEgress_latest_reg__last_old_value__dbg, leaf_netcacheEgress_latest_reg__last_value, leaf_netcacheEgress_latest_reg__last_value__dbg, leaf_netcacheEgress_latest_reg__last_write_site, leaf_netcacheEgress_latest_reg__next_write_site, leaf_netcacheEgress_latest_reg__wrote_any, leaf_netcacheEgress_latest_reg__wrote_any__dbg, leaf_netcacheEgress_latest_reg__wrote_index0, leaf_netcacheEgress_latest_reg__wrote_index0__dbg, leaf_netcacheEgress_prepare_for_cachepop_tbl.action_run, leaf_netcacheEgress_prepare_for_cachepop_tbl.hit, leaf_netcacheEgress_prepare_for_cachepop_tbl.netcacheEgress_set_server_sid_and_port.server_sid_2, leaf_netcacheEgress_save_client_udpport_tbl.action_run, leaf_netcacheEgress_save_client_udpport_tbl.hit, leaf_netcacheEgress_update_ipmac_srcport_tbl.action_run, leaf_netcacheEgress_update_ipmac_srcport_tbl.hit, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_ip_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_client2server.server_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_ip_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_dstipmac_switch2switchos.switch_mac_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_ip_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_mac_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.client_port_2, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_ip_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_client2server.server_mac_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.client_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_mac, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_server2client.server_port_4, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_ip_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_mac_3, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.client_port, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_ip, leaf_netcacheEgress_update_ipmac_srcport_tbl.netcacheEgress_update_ipmac_srcport_switch2switchos.switch_mac, leaf_netcacheEgress_update_pktlen_tbl.action_run, leaf_netcacheEgress_update_pktlen_tbl.hit, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.iplen_delta, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_add_pktlen.udplen_delta, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.iplen, leaf_netcacheEgress_update_pktlen_tbl.netcacheEgress_update_pktlen.udplen, leaf_netcacheEgress_update_vallen_tbl.action_run, leaf_netcacheEgress_update_vallen_tbl.hit, leaf_netcacheEgress_vallen_reg, leaf_netcacheEgress_vallen_reg__dbg0, leaf_netcacheEgress_vallen_reg__last0_old_value, leaf_netcacheEgress_vallen_reg__last0_old_value__dbg, leaf_netcacheEgress_vallen_reg__last0_value, leaf_netcacheEgress_vallen_reg__last0_value__dbg, leaf_netcacheEgress_vallen_reg__last_index, leaf_netcacheEgress_vallen_reg__last_index__dbg, leaf_netcacheEgress_vallen_reg__last_old_value, leaf_netcacheEgress_vallen_reg__last_old_value__dbg, leaf_netcacheEgress_vallen_reg__last_value, leaf_netcacheEgress_vallen_reg__last_value__dbg, leaf_netcacheEgress_vallen_reg__last_write_site, leaf_netcacheEgress_vallen_reg__next_write_site, leaf_netcacheEgress_vallen_reg__wrote_any, leaf_netcacheEgress_vallen_reg__wrote_any__dbg, leaf_netcacheEgress_vallen_reg__wrote_index0, leaf_netcacheEgress_vallen_reg__wrote_index0__dbg, leaf_netcacheIngress_hash_for_partition_tbl.action_run, leaf_netcacheIngress_hash_for_partition_tbl.hit, leaf_netcacheIngress_hash_spine_partition_tbl.action_run, leaf_netcacheIngress_hash_spine_partition_tbl.hit, leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.eport_5, leaf_netcacheIngress_hash_spine_partition_tbl.netcacheIngress_hash_spine_partition.spine_sid_1, leaf_p4b_checksum_error, leaf_p4b_checksum_updated, leaf_p4b_checksum_verified, leaf_p4b_clone_e2e, leaf_p4b_clone_i2e, leaf_p4b_clone_i2i, leaf_p4b_digest, leaf_p4b_recirculate, leaf_pkt_external, leaf_standard_metadata.egress_port, procurator_bad, procurator_step;
{
  call mainProcedure();
}

// ===== END HARNESS =====
