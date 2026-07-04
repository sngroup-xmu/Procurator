// ===== BEGIN PREAMBLE =====
function bvule.bv16(left:bv16, right:bv16) returns(bool);
function {:builtin "bvule"} bvule.bv16$builtin(left:bv16, right:bv16) returns(bool);
axiom (forall left:bv16, right:bv16 :: bvule.bv16(left, right) <==> bvule.bv16$builtin(left, right));
function bvule.bv32(left:bv32, right:bv32) returns(bool);
function {:builtin "bvule"} bvule.bv32$builtin(left:bv32, right:bv32) returns(bool);
axiom (forall left:bv32, right:bv32 :: bvule.bv32(left, right) <==> bvule.bv32$builtin(left, right));
// ===== END PREAMBLE =====

// ===== BEGIN NODE spine (prefixed) =====
type spine_Ref;
type spine_error=bv1;
type spine_HeaderStack = [int]spine_Ref;
var spine_last:[spine_HeaderStack]spine_Ref;
var spine_forward:bool;
var spine_isValid:[spine_Ref]bool;
var spine_emit:[spine_Ref]bool;
var spine_stack.index:[spine_HeaderStack]int;
var spine_size:[spine_HeaderStack]int;
var spine_drop:bool;
var spine_p4b_clone_i2e:bool;
var spine_p4b_clone_e2e:bool;
var spine_p4b_clone_i2i:bool;
var spine_p4b_recirculate:bool;
var spine_p4b_digest:bool;
var spine_p4b_checksum_verified:bool;
var spine_p4b_checksum_updated:bool;
var spine_p4b_checksum_error:bool;

// spine_Struct spine_standard_metadata_t
type spine_standard_metadata_t;
var spine_standard_metadata.egress_port:bv9;
type spine_CounterType = int;
type spine_MeterType = int;
type spine_HashAlgorithm = int;
type spine_CloneType = int;
type spine_ethernet_t;
type spine_ipv4_t;
type spine_udp_t;
type spine_op_t;
type spine_vallen_t;
type spine_val_t;
type spine_shadowtype_t;
type spine_seq_t;
type spine_inswitch_t;
type spine_stat_t;
type spine_clone_t;
type spine_frequency_t;
type spine_fraginfo_t;

// spine_Struct spine_headers
var spine_hdr:spine_Ref;

// spine_Header spine_ethernet_t
var spine_hdr.ethernet_hdr:spine_Ref;
var spine_hdr.ethernet_hdr.valid:bool;
var spine_hdr.ethernet_hdr.dstAddr:bv48;
var spine_hdr.ethernet_hdr.srcAddr:bv48;
var spine_hdr.ethernet_hdr.etherType:bv16;

// spine_Header spine_ipv4_t
var spine_hdr.ipv4_hdr:spine_Ref;
var spine_hdr.ipv4_hdr.valid:bool;
var spine_hdr.ipv4_hdr.version:bv4;
var spine_hdr.ipv4_hdr.ihl:bv4;
var spine_hdr.ipv4_hdr.diffserv:bv8;
var spine_hdr.ipv4_hdr.totalLen:bv16;
var spine_hdr.ipv4_hdr.identification:bv16;
var spine_hdr.ipv4_hdr.flags:bv3;
var spine_hdr.ipv4_hdr.fragOffset:bv13;
var spine_hdr.ipv4_hdr.ttl:bv8;
var spine_hdr.ipv4_hdr.protocol:bv8;
var spine_hdr.ipv4_hdr.hdrChecksum:bv16;
var spine_hdr.ipv4_hdr.srcAddr:bv32;
var spine_hdr.ipv4_hdr.dstAddr:bv32;

// spine_Header spine_udp_t
var spine_hdr.udp_hdr:spine_Ref;
var spine_hdr.udp_hdr.valid:bool;
var spine_hdr.udp_hdr.srcPort:bv16;
var spine_hdr.udp_hdr.dstPort:bv16;
var spine_hdr.udp_hdr.hdrlen:bv16;
var spine_hdr.udp_hdr.checksum:bv16;

// spine_Header spine_op_t
var spine_hdr.op_hdr:spine_Ref;
var spine_hdr.op_hdr.valid:bool;
var spine_hdr.op_hdr.optype:bv16;
var spine_hdr.op_hdr.keylolo:bv32;
var spine_hdr.op_hdr.keylohi:bv32;
var spine_hdr.op_hdr.keyhilo:bv32;
var spine_hdr.op_hdr.keyhihilo:bv16;
var spine_hdr.op_hdr.keyhihihi:bv16;

// spine_Header spine_vallen_t
var spine_hdr.vallen_hdr:spine_Ref;
var spine_hdr.vallen_hdr.valid:bool;
var spine_hdr.vallen_hdr.vallen:bv16;

// spine_Header spine_val_t
var spine_hdr.val1_hdr:spine_Ref;
var spine_hdr.val1_hdr.valid:bool;
var spine_hdr.val1_hdr.vallo:bv32;
var spine_hdr.val1_hdr.valhi:bv32;

// spine_Header spine_val_t
var spine_hdr.val2_hdr:spine_Ref;
var spine_hdr.val2_hdr.valid:bool;
var spine_hdr.val2_hdr.vallo:bv32;
var spine_hdr.val2_hdr.valhi:bv32;

// spine_Header spine_val_t
var spine_hdr.val3_hdr:spine_Ref;
var spine_hdr.val3_hdr.valid:bool;
var spine_hdr.val3_hdr.vallo:bv32;
var spine_hdr.val3_hdr.valhi:bv32;

// spine_Header spine_val_t
var spine_hdr.val4_hdr:spine_Ref;
var spine_hdr.val4_hdr.valid:bool;
var spine_hdr.val4_hdr.vallo:bv32;
var spine_hdr.val4_hdr.valhi:bv32;

// spine_Header spine_val_t
var spine_hdr.val5_hdr:spine_Ref;
var spine_hdr.val5_hdr.valid:bool;
var spine_hdr.val5_hdr.vallo:bv32;
var spine_hdr.val5_hdr.valhi:bv32;

// spine_Header spine_val_t
var spine_hdr.val6_hdr:spine_Ref;
var spine_hdr.val6_hdr.valid:bool;
var spine_hdr.val6_hdr.vallo:bv32;
var spine_hdr.val6_hdr.valhi:bv32;

// spine_Header spine_val_t
var spine_hdr.val7_hdr:spine_Ref;
var spine_hdr.val7_hdr.valid:bool;
var spine_hdr.val7_hdr.vallo:bv32;
var spine_hdr.val7_hdr.valhi:bv32;

// spine_Header spine_val_t
var spine_hdr.val8_hdr:spine_Ref;
var spine_hdr.val8_hdr.valid:bool;
var spine_hdr.val8_hdr.vallo:bv32;
var spine_hdr.val8_hdr.valhi:bv32;

// spine_Header spine_val_t
var spine_hdr.val9_hdr:spine_Ref;
var spine_hdr.val9_hdr.valid:bool;
var spine_hdr.val9_hdr.vallo:bv32;
var spine_hdr.val9_hdr.valhi:bv32;

// spine_Header spine_val_t
var spine_hdr.val10_hdr:spine_Ref;
var spine_hdr.val10_hdr.valid:bool;
var spine_hdr.val10_hdr.vallo:bv32;
var spine_hdr.val10_hdr.valhi:bv32;

// spine_Header spine_val_t
var spine_hdr.val11_hdr:spine_Ref;
var spine_hdr.val11_hdr.valid:bool;
var spine_hdr.val11_hdr.vallo:bv32;
var spine_hdr.val11_hdr.valhi:bv32;

// spine_Header spine_val_t
var spine_hdr.val12_hdr:spine_Ref;
var spine_hdr.val12_hdr.valid:bool;
var spine_hdr.val12_hdr.vallo:bv32;
var spine_hdr.val12_hdr.valhi:bv32;

// spine_Header spine_val_t
var spine_hdr.val13_hdr:spine_Ref;
var spine_hdr.val13_hdr.valid:bool;
var spine_hdr.val13_hdr.vallo:bv32;
var spine_hdr.val13_hdr.valhi:bv32;

// spine_Header spine_val_t
var spine_hdr.val14_hdr:spine_Ref;
var spine_hdr.val14_hdr.valid:bool;
var spine_hdr.val14_hdr.vallo:bv32;
var spine_hdr.val14_hdr.valhi:bv32;

// spine_Header spine_val_t
var spine_hdr.val15_hdr:spine_Ref;
var spine_hdr.val15_hdr.valid:bool;
var spine_hdr.val15_hdr.vallo:bv32;
var spine_hdr.val15_hdr.valhi:bv32;

// spine_Header spine_val_t
var spine_hdr.val16_hdr:spine_Ref;
var spine_hdr.val16_hdr.valid:bool;
var spine_hdr.val16_hdr.vallo:bv32;
var spine_hdr.val16_hdr.valhi:bv32;

// spine_Header spine_shadowtype_t
var spine_hdr.shadowtype_hdr:spine_Ref;
var spine_hdr.shadowtype_hdr.valid:bool;
var spine_hdr.shadowtype_hdr.shadowtype:bv16;

// spine_Header spine_seq_t
var spine_hdr.seq_hdr:spine_Ref;
var spine_hdr.seq_hdr.valid:bool;
var spine_hdr.seq_hdr.seq:bv32;

// spine_Header spine_inswitch_t
var spine_hdr.inswitch_hdr:spine_Ref;
var spine_hdr.inswitch_hdr.valid:bool;
var spine_hdr.inswitch_hdr.is_cached:bv1;
var spine_hdr.inswitch_hdr.is_sampled:bv1;
var spine_hdr.inswitch_hdr.client_sid:bv10;
var spine_hdr.inswitch_hdr.padding1:bv4;
var spine_hdr.inswitch_hdr.hot_threshold:bv16;
var spine_hdr.inswitch_hdr.hashval_for_cm1:bv16;
var spine_hdr.inswitch_hdr.hashval_for_cm2:bv16;
var spine_hdr.inswitch_hdr.hashval_for_cm3:bv16;
var spine_hdr.inswitch_hdr.hashval_for_cm4:bv16;
var spine_hdr.inswitch_hdr.hashval_for_bf1:bv18;
var spine_hdr.inswitch_hdr.padding2:bv14;
var spine_hdr.inswitch_hdr.hashval_for_bf2:bv18;
var spine_hdr.inswitch_hdr.padding3:bv14;
var spine_hdr.inswitch_hdr.hashval_for_bf3:bv18;
var spine_hdr.inswitch_hdr.padding4:bv14;
var spine_hdr.inswitch_hdr.hashval_for_seq:bv16;
var spine_hdr.inswitch_hdr.idx:bv16;

// spine_Header spine_stat_t
var spine_hdr.stat_hdr:spine_Ref;
var spine_hdr.stat_hdr.valid:bool;
var spine_hdr.stat_hdr.stat:bv8;
var spine_hdr.stat_hdr.nodeidx_foreval:bv16;
var spine_hdr.stat_hdr.padding:bv8;

// spine_Header spine_clone_t
var spine_hdr.clone_hdr:spine_Ref;
var spine_hdr.clone_hdr.valid:bool;
var spine_hdr.clone_hdr.clonenum_for_pktloss:bv16;
var spine_hdr.clone_hdr.client_udpport:bv16;
var spine_hdr.clone_hdr.server_sid:bv10;
var spine_hdr.clone_hdr.padding:bv6;
var spine_hdr.clone_hdr.server_udpport:bv16;

// spine_Header spine_frequency_t
var spine_hdr.frequency_hdr:spine_Ref;
var spine_hdr.frequency_hdr.valid:bool;
var spine_hdr.frequency_hdr.frequency:bv32;

// spine_Header spine_fraginfo_t
var spine_hdr.fraginfo_hdr:spine_Ref;
var spine_hdr.fraginfo_hdr.valid:bool;
var spine_hdr.fraginfo_hdr.padding1:bv16;
var spine_hdr.fraginfo_hdr.padding2:bv32;
var spine_hdr.fraginfo_hdr.cur_fragidx:bv16;
var spine_hdr.fraginfo_hdr.max_fragnum:bv16;

// spine_Struct spine_metadata
type spine_metadata;
var spine_meta.is_spine:bv1;
var spine_meta.is_cached:bv1;
var spine_meta.is_deleted:bv1;
var spine_meta.idx:bv16;
var spine_meta:spine_metadata;

function {:builtin "bvand"} band.bv16(spine_left:bv16, spine_right:bv16) returns(bv16);
type spine_egressSpec_t = bv9;

// spine_Table spine_partitionswitchIngress_cache_lookup_tbl spine_Actionlist spine_Declaration
type spine_partitionswitchIngress_cache_lookup_tbl.action;
var spine_partitionswitchIngress_cache_lookup_tbl.partitionswitchIngress_cached_action.idx_1:bv16;
const unique spine_partitionswitchIngress_cache_lookup_tbl.action.partitionswitchIngress_cached_action : spine_partitionswitchIngress_cache_lookup_tbl.action;
const unique spine_partitionswitchIngress_cache_lookup_tbl.action.partitionswitchIngress_uncached_action : spine_partitionswitchIngress_cache_lookup_tbl.action;
var spine_partitionswitchIngress_cache_lookup_tbl.action_run : spine_partitionswitchIngress_cache_lookup_tbl.action;
var spine_partitionswitchIngress_cache_lookup_tbl.hit : bool;

// spine_Table spine_partitionswitchIngress_set_spine_tbl spine_Actionlist spine_Declaration
type spine_partitionswitchIngress_set_spine_tbl.action;
const unique spine_partitionswitchIngress_set_spine_tbl.action.partitionswitchIngress_set_spine : spine_partitionswitchIngress_set_spine_tbl.action;
const unique spine_partitionswitchIngress_set_spine_tbl.action.NoAction_7 : spine_partitionswitchIngress_set_spine_tbl.action;
var spine_partitionswitchIngress_set_spine_tbl.action_run : spine_partitionswitchIngress_set_spine_tbl.action;
var spine_partitionswitchIngress_set_spine_tbl.hit : bool;
var spine_hdr_eg:spine_Ref;

// spine_Header spine_ethernet_t

// spine_Header spine_ipv4_t

// spine_Header spine_udp_t

// spine_Header spine_op_t
var spine_hdr_eg.op_hdr:spine_Ref;
var spine_hdr_eg.op_hdr.valid:bool;
var spine_hdr_eg.op_hdr.optype:bv16;
var spine_hdr_eg.op_hdr.keylolo:bv32;
var spine_hdr_eg.op_hdr.keylohi:bv32;
var spine_hdr_eg.op_hdr.keyhilo:bv32;
var spine_hdr_eg.op_hdr.keyhihilo:bv16;
var spine_hdr_eg.op_hdr.keyhihihi:bv16;

// spine_Header spine_vallen_t
var spine_hdr_eg.vallen_hdr:spine_Ref;
var spine_hdr_eg.vallen_hdr.valid:bool;
var spine_hdr_eg.vallen_hdr.vallen:bv16;

// spine_Header spine_val_t

// spine_Header spine_val_t

// spine_Header spine_val_t

// spine_Header spine_val_t

// spine_Header spine_val_t

// spine_Header spine_val_t

// spine_Header spine_val_t

// spine_Header spine_val_t

// spine_Header spine_val_t

// spine_Header spine_val_t

// spine_Header spine_val_t

// spine_Header spine_val_t

// spine_Header spine_val_t

// spine_Header spine_val_t

// spine_Header spine_val_t

// spine_Header spine_val_t

// spine_Header spine_shadowtype_t

// spine_Header spine_seq_t

// spine_Header spine_inswitch_t
var spine_hdr_eg.inswitch_hdr:spine_Ref;
var spine_hdr_eg.inswitch_hdr.valid:bool;
var spine_hdr_eg.inswitch_hdr.is_cached:bv1;
var spine_hdr_eg.inswitch_hdr.is_sampled:bv1;
var spine_hdr_eg.inswitch_hdr.client_sid:bv10;
var spine_hdr_eg.inswitch_hdr.padding1:bv4;
var spine_hdr_eg.inswitch_hdr.hot_threshold:bv16;
var spine_hdr_eg.inswitch_hdr.hashval_for_cm1:bv16;
var spine_hdr_eg.inswitch_hdr.hashval_for_cm2:bv16;
var spine_hdr_eg.inswitch_hdr.hashval_for_cm3:bv16;
var spine_hdr_eg.inswitch_hdr.hashval_for_cm4:bv16;
var spine_hdr_eg.inswitch_hdr.hashval_for_bf1:bv18;
var spine_hdr_eg.inswitch_hdr.padding2:bv14;
var spine_hdr_eg.inswitch_hdr.hashval_for_bf2:bv18;
var spine_hdr_eg.inswitch_hdr.padding3:bv14;
var spine_hdr_eg.inswitch_hdr.hashval_for_bf3:bv18;
var spine_hdr_eg.inswitch_hdr.padding4:bv14;
var spine_hdr_eg.inswitch_hdr.hashval_for_seq:bv16;
var spine_hdr_eg.inswitch_hdr.idx:bv16;

// spine_Header spine_stat_t

// spine_Header spine_clone_t

// spine_Header spine_frequency_t

// spine_Header spine_fraginfo_t
var spine_cache_frequency_res_0:bv32;

// spine_Table spine_partitionswitchEgress_add_and_remove_value_header_tbl spine_Actionlist spine_Declaration
type spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;

function {:builtin "bvuge"} buge.bv16(spine_left:bv16, spine_right:bv16) returns(bool);

function {:builtin "bvule"} bule.bv16(spine_left:bv16, spine_right:bv16) returns(bool);
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_only_vallen : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val1 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val2 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val3 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val4 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val5 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val6 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val7 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val8 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val9 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val10 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val11 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val12 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val13 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val14 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val15 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val16 : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
const unique spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_remove_all : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
var spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run : spine_partitionswitchEgress_add_and_remove_value_header_tbl.action;
var spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit : bool;

// spine_Register spine_partitionswitchEgress_vallen_reg
var spine_partitionswitchEgress_vallen_reg:[bv32]bv16;
var spine_partitionswitchEgress_vallen_reg__last_index:bv32;
var spine_partitionswitchEgress_vallen_reg__last_value:bv16;
var spine_partitionswitchEgress_vallen_reg__last_old_value:bv16;
var spine_partitionswitchEgress_vallen_reg__wrote_any:bool;
var spine_partitionswitchEgress_vallen_reg__wrote_index0:bool;
var spine_partitionswitchEgress_vallen_reg__last0_old_value:bv16;
var spine_partitionswitchEgress_vallen_reg__last0_value:bv16;
var spine_partitionswitchEgress_vallen_reg__next_write_site:int;
var spine_partitionswitchEgress_vallen_reg__last_write_site:int;
const spine_partitionswitchEgress_vallen_reg.size:bv32;
axiom spine_partitionswitchEgress_vallen_reg.size == 32768bv32;

// spine_Table spine_partitionswitchEgress_update_vallen_tbl spine_Actionlist spine_Declaration
type spine_partitionswitchEgress_update_vallen_tbl.action;
const unique spine_partitionswitchEgress_update_vallen_tbl.action.partitionswitchEgress_get_vallen : spine_partitionswitchEgress_update_vallen_tbl.action;
const unique spine_partitionswitchEgress_update_vallen_tbl.action.partitionswitchEgress_set_and_get_vallen : spine_partitionswitchEgress_update_vallen_tbl.action;
const unique spine_partitionswitchEgress_update_vallen_tbl.action.partitionswitchEgress_reset_and_get_vallen : spine_partitionswitchEgress_update_vallen_tbl.action;
const unique spine_partitionswitchEgress_update_vallen_tbl.action.partitionswitchEgress_reset_access_val_mode : spine_partitionswitchEgress_update_vallen_tbl.action;
const unique spine_partitionswitchEgress_update_vallen_tbl.action.NoAction_8 : spine_partitionswitchEgress_update_vallen_tbl.action;
var spine_partitionswitchEgress_update_vallen_tbl.action_run : spine_partitionswitchEgress_update_vallen_tbl.action;
var spine_partitionswitchEgress_update_vallen_tbl.hit : bool;

// spine_Register spine_partitionswitchEgress_deleted_reg
var spine_partitionswitchEgress_deleted_reg:[bv32]bv1;
var spine_partitionswitchEgress_deleted_reg__last_index:bv32;
var spine_partitionswitchEgress_deleted_reg__last_value:bv1;
var spine_partitionswitchEgress_deleted_reg__last_old_value:bv1;
var spine_partitionswitchEgress_deleted_reg__wrote_any:bool;
var spine_partitionswitchEgress_deleted_reg__wrote_index0:bool;
var spine_partitionswitchEgress_deleted_reg__last0_old_value:bv1;
var spine_partitionswitchEgress_deleted_reg__last0_value:bv1;
var spine_partitionswitchEgress_deleted_reg__next_write_site:int;
var spine_partitionswitchEgress_deleted_reg__last_write_site:int;
const spine_partitionswitchEgress_deleted_reg.size:bv32;
axiom spine_partitionswitchEgress_deleted_reg.size == 32768bv32;

// spine_Table spine_partitionswitchEgress_access_deleted_tbl spine_Actionlist spine_Declaration
type spine_partitionswitchEgress_access_deleted_tbl.action;
const unique spine_partitionswitchEgress_access_deleted_tbl.action.partitionswitchEgress_get_deleted : spine_partitionswitchEgress_access_deleted_tbl.action;
const unique spine_partitionswitchEgress_access_deleted_tbl.action.partitionswitchEgress_set_and_get_deleted : spine_partitionswitchEgress_access_deleted_tbl.action;
const unique spine_partitionswitchEgress_access_deleted_tbl.action.partitionswitchEgress_reset_and_get_deleted : spine_partitionswitchEgress_access_deleted_tbl.action;
const unique spine_partitionswitchEgress_access_deleted_tbl.action.partitionswitchEgress_reset_is_deleted : spine_partitionswitchEgress_access_deleted_tbl.action;
var spine_partitionswitchEgress_access_deleted_tbl.action_run : spine_partitionswitchEgress_access_deleted_tbl.action;
var spine_partitionswitchEgress_access_deleted_tbl.hit : bool;

// spine_Register spine_partitionswitchEgress_cache_frequency_reg
var spine_partitionswitchEgress_cache_frequency_reg:[bv32]bv32;
var spine_partitionswitchEgress_cache_frequency_reg__last_index:bv32;
var spine_partitionswitchEgress_cache_frequency_reg__last_value:bv32;
var spine_partitionswitchEgress_cache_frequency_reg__last_old_value:bv32;
var spine_partitionswitchEgress_cache_frequency_reg__wrote_any:bool;
var spine_partitionswitchEgress_cache_frequency_reg__wrote_index0:bool;
var spine_partitionswitchEgress_cache_frequency_reg__last0_old_value:bv32;
var spine_partitionswitchEgress_cache_frequency_reg__last0_value:bv32;
var spine_partitionswitchEgress_cache_frequency_reg__next_write_site:int;
var spine_partitionswitchEgress_cache_frequency_reg__last_write_site:int;
const spine_partitionswitchEgress_cache_frequency_reg.size:bv32;
axiom spine_partitionswitchEgress_cache_frequency_reg.size == 8bv32;

function {:builtin "bvule"} bule.bv32(spine_left:bv32, spine_right:bv32) returns(bool);

function {:builtin "bvadd"} add.bv32(spine_left:bv32, spine_right:bv32) returns(bv32);

// spine_Table spine_partitionswitchEgress_access_cache_frequency_tbl spine_Actionlist spine_Declaration
type spine_partitionswitchEgress_access_cache_frequency_tbl.action;
const unique spine_partitionswitchEgress_access_cache_frequency_tbl.action.partitionswitchEgress_get_cache_frequency : spine_partitionswitchEgress_access_cache_frequency_tbl.action;
const unique spine_partitionswitchEgress_access_cache_frequency_tbl.action.partitionswitchEgress_update_cache_frequency : spine_partitionswitchEgress_access_cache_frequency_tbl.action;
const unique spine_partitionswitchEgress_access_cache_frequency_tbl.action.partitionswitchEgress_reset_cache_frequency : spine_partitionswitchEgress_access_cache_frequency_tbl.action;
const unique spine_partitionswitchEgress_access_cache_frequency_tbl.action.NoAction_41 : spine_partitionswitchEgress_access_cache_frequency_tbl.action;
var spine_partitionswitchEgress_access_cache_frequency_tbl.action_run : spine_partitionswitchEgress_access_cache_frequency_tbl.action;
var spine_partitionswitchEgress_access_cache_frequency_tbl.hit : bool;

// spine_Table spine_partitionswitchEgress_eg_port_forward_tbl spine_Actionlist spine_Declaration
type spine_partitionswitchEgress_eg_port_forward_tbl.action;
var spine_partitionswitchEgress_eg_port_forward_tbl.partitionswitchEgress_update_netcache_getreq_spine_to_getres_by_mirroring.stat_1:bv8;
const unique spine_partitionswitchEgress_eg_port_forward_tbl.action.partitionswitchEgress_update_netcache_getreq_spine_to_getreq : spine_partitionswitchEgress_eg_port_forward_tbl.action;
const unique spine_partitionswitchEgress_eg_port_forward_tbl.action.partitionswitchEgress_update_netcache_getreq_spine_to_getres_by_mirroring : spine_partitionswitchEgress_eg_port_forward_tbl.action;
const unique spine_partitionswitchEgress_eg_port_forward_tbl.action.NoAction_42 : spine_partitionswitchEgress_eg_port_forward_tbl.action;
var spine_partitionswitchEgress_eg_port_forward_tbl.action_run : spine_partitionswitchEgress_eg_port_forward_tbl.action;
var spine_partitionswitchEgress_eg_port_forward_tbl.hit : bool;

// spine_Table spine_partitionswitchEgress_update_pktlen_tbl spine_Actionlist spine_Declaration
type spine_partitionswitchEgress_update_pktlen_tbl.action;
var spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen:bv16;
var spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen:bv16;
var spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_add_pktlen.udplen_delta:bv16;
var spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_add_pktlen.iplen_delta:bv16;
const unique spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen : spine_partitionswitchEgress_update_pktlen_tbl.action;
const unique spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_add_pktlen : spine_partitionswitchEgress_update_pktlen_tbl.action;
const unique spine_partitionswitchEgress_update_pktlen_tbl.action.NoAction_43 : spine_partitionswitchEgress_update_pktlen_tbl.action;
var spine_partitionswitchEgress_update_pktlen_tbl.action_run : spine_partitionswitchEgress_update_pktlen_tbl.action;
var spine_partitionswitchEgress_update_pktlen_tbl.hit : bool;

function {:builtin "bvsub"} sub.bv17(spine_left:bv17, spine_right:bv17) returns(bv17);

function {:builtin "bvsub"} sub.bv33(spine_left:bv33, spine_right:bv33) returns(bv33);

// spine_Action spine_NoAction_41
procedure {:inline 1} spine_NoAction_41()
{
}

// spine_Action spine_NoAction_42
procedure {:inline 1} spine_NoAction_42()
{
}

// spine_Action spine_NoAction_43
procedure {:inline 1} spine_NoAction_43()
{
}

// spine_Action spine_NoAction_7
procedure {:inline 1} spine_NoAction_7()
{
}
procedure {:inline 1} spine_accept()
{
}
procedure {:inline 1} spine_main()
	modifies spine_cache_frequency_res_0, spine_drop, spine_hdr.op_hdr.keyhihihi, spine_hdr.op_hdr.keyhihilo, spine_hdr.op_hdr.keyhilo, spine_hdr.op_hdr.keylohi, spine_hdr.op_hdr.keylolo, spine_hdr.op_hdr.optype, spine_hdr.udp_hdr.checksum, spine_hdr_eg.op_hdr.optype, spine_hdr_eg.vallen_hdr.vallen, spine_isValid, spine_meta.idx, spine_meta.is_cached, spine_meta.is_deleted, spine_meta.is_spine, spine_p4b_checksum_updated, spine_partitionswitchEgress_access_cache_frequency_tbl.action_run, spine_partitionswitchEgress_access_cache_frequency_tbl.hit, spine_partitionswitchEgress_access_deleted_tbl.action_run, spine_partitionswitchEgress_access_deleted_tbl.hit, spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run, spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit, spine_partitionswitchEgress_cache_frequency_reg, spine_partitionswitchEgress_cache_frequency_reg__last0_old_value, spine_partitionswitchEgress_cache_frequency_reg__last0_value, spine_partitionswitchEgress_cache_frequency_reg__last_index, spine_partitionswitchEgress_cache_frequency_reg__last_old_value, spine_partitionswitchEgress_cache_frequency_reg__last_value, spine_partitionswitchEgress_cache_frequency_reg__last_write_site, spine_partitionswitchEgress_cache_frequency_reg__next_write_site, spine_partitionswitchEgress_cache_frequency_reg__wrote_any, spine_partitionswitchEgress_cache_frequency_reg__wrote_index0, spine_partitionswitchEgress_deleted_reg, spine_partitionswitchEgress_deleted_reg__last0_old_value, spine_partitionswitchEgress_deleted_reg__last0_value, spine_partitionswitchEgress_deleted_reg__last_index, spine_partitionswitchEgress_deleted_reg__last_old_value, spine_partitionswitchEgress_deleted_reg__last_value, spine_partitionswitchEgress_deleted_reg__last_write_site, spine_partitionswitchEgress_deleted_reg__next_write_site, spine_partitionswitchEgress_deleted_reg__wrote_any, spine_partitionswitchEgress_deleted_reg__wrote_index0, spine_partitionswitchEgress_eg_port_forward_tbl.action_run, spine_partitionswitchEgress_eg_port_forward_tbl.hit, spine_partitionswitchEgress_eg_port_forward_tbl.partitionswitchEgress_update_netcache_getreq_spine_to_getres_by_mirroring.stat_1, spine_partitionswitchEgress_update_pktlen_tbl.action_run, spine_partitionswitchEgress_update_pktlen_tbl.hit, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_vallen_tbl.action_run, spine_partitionswitchEgress_update_vallen_tbl.hit, spine_partitionswitchEgress_vallen_reg, spine_partitionswitchEgress_vallen_reg__last0_old_value, spine_partitionswitchEgress_vallen_reg__last0_value, spine_partitionswitchEgress_vallen_reg__last_index, spine_partitionswitchEgress_vallen_reg__last_old_value, spine_partitionswitchEgress_vallen_reg__last_value, spine_partitionswitchEgress_vallen_reg__last_write_site, spine_partitionswitchEgress_vallen_reg__next_write_site, spine_partitionswitchEgress_vallen_reg__wrote_any, spine_partitionswitchEgress_vallen_reg__wrote_index0, spine_partitionswitchIngress_cache_lookup_tbl.action_run, spine_partitionswitchIngress_cache_lookup_tbl.hit, spine_partitionswitchIngress_cache_lookup_tbl.partitionswitchIngress_cached_action.idx_1, spine_partitionswitchIngress_set_spine_tbl.action_run, spine_partitionswitchIngress_set_spine_tbl.hit;
{
    call spine_partitionswitchParser();
    call spine_partitionswitchVerifyChecksum();
    call spine_partitionswitchIngress();
    call spine_partitionswitchEgress();
    call spine_partitionswitchComputeChecksum();
    if(spine_forward == false){
        spine_drop := true;
    }
}
procedure spine_mainProcedure()
	modifies spine_cache_frequency_res_0, spine_drop, spine_hdr.op_hdr.keyhihihi, spine_hdr.op_hdr.keyhihilo, spine_hdr.op_hdr.keyhilo, spine_hdr.op_hdr.keylohi, spine_hdr.op_hdr.keylolo, spine_hdr.op_hdr.optype, spine_hdr.udp_hdr.checksum, spine_hdr_eg.op_hdr.optype, spine_hdr_eg.vallen_hdr.vallen, spine_isValid, spine_meta.idx, spine_meta.is_cached, spine_meta.is_deleted, spine_meta.is_spine, spine_p4b_checksum_error, spine_p4b_checksum_updated, spine_p4b_checksum_verified, spine_p4b_clone_e2e, spine_p4b_clone_i2e, spine_p4b_clone_i2i, spine_p4b_digest, spine_p4b_recirculate, spine_partitionswitchEgress_access_cache_frequency_tbl.action_run, spine_partitionswitchEgress_access_cache_frequency_tbl.hit, spine_partitionswitchEgress_access_deleted_tbl.action_run, spine_partitionswitchEgress_access_deleted_tbl.hit, spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run, spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit, spine_partitionswitchEgress_cache_frequency_reg, spine_partitionswitchEgress_cache_frequency_reg__last0_old_value, spine_partitionswitchEgress_cache_frequency_reg__last0_value, spine_partitionswitchEgress_cache_frequency_reg__last_index, spine_partitionswitchEgress_cache_frequency_reg__last_old_value, spine_partitionswitchEgress_cache_frequency_reg__last_value, spine_partitionswitchEgress_cache_frequency_reg__last_write_site, spine_partitionswitchEgress_cache_frequency_reg__next_write_site, spine_partitionswitchEgress_cache_frequency_reg__wrote_any, spine_partitionswitchEgress_cache_frequency_reg__wrote_index0, spine_partitionswitchEgress_deleted_reg, spine_partitionswitchEgress_deleted_reg__last0_old_value, spine_partitionswitchEgress_deleted_reg__last0_value, spine_partitionswitchEgress_deleted_reg__last_index, spine_partitionswitchEgress_deleted_reg__last_old_value, spine_partitionswitchEgress_deleted_reg__last_value, spine_partitionswitchEgress_deleted_reg__last_write_site, spine_partitionswitchEgress_deleted_reg__next_write_site, spine_partitionswitchEgress_deleted_reg__wrote_any, spine_partitionswitchEgress_deleted_reg__wrote_index0, spine_partitionswitchEgress_eg_port_forward_tbl.action_run, spine_partitionswitchEgress_eg_port_forward_tbl.hit, spine_partitionswitchEgress_eg_port_forward_tbl.partitionswitchEgress_update_netcache_getreq_spine_to_getres_by_mirroring.stat_1, spine_partitionswitchEgress_update_pktlen_tbl.action_run, spine_partitionswitchEgress_update_pktlen_tbl.hit, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_vallen_tbl.action_run, spine_partitionswitchEgress_update_vallen_tbl.hit, spine_partitionswitchEgress_vallen_reg, spine_partitionswitchEgress_vallen_reg__last0_old_value, spine_partitionswitchEgress_vallen_reg__last0_value, spine_partitionswitchEgress_vallen_reg__last_index, spine_partitionswitchEgress_vallen_reg__last_old_value, spine_partitionswitchEgress_vallen_reg__last_value, spine_partitionswitchEgress_vallen_reg__last_write_site, spine_partitionswitchEgress_vallen_reg__next_write_site, spine_partitionswitchEgress_vallen_reg__wrote_any, spine_partitionswitchEgress_vallen_reg__wrote_index0, spine_partitionswitchIngress_cache_lookup_tbl.action_run, spine_partitionswitchIngress_cache_lookup_tbl.hit, spine_partitionswitchIngress_cache_lookup_tbl.partitionswitchIngress_cached_action.idx_1, spine_partitionswitchIngress_set_spine_tbl.action_run, spine_partitionswitchIngress_set_spine_tbl.hit;
{
    spine_p4b_checksum_error := false;
    spine_p4b_checksum_updated := false;
    spine_p4b_checksum_verified := false;
    spine_p4b_digest := false;
    spine_p4b_recirculate := false;
    spine_p4b_clone_i2i := false;
    spine_p4b_clone_e2e := false;
    spine_p4b_clone_i2e := false;
    call spine_main();
}
procedure spine_packet_in.extract(spine_header:spine_Ref);
    ensures (spine_isValid[spine_header] == true);
	modifies spine_isValid;

// spine_Control spine_partitionswitchComputeChecksum
procedure {:inline 1} spine_partitionswitchComputeChecksum()
	modifies spine_hdr.udp_hdr.checksum, spine_p4b_checksum_updated;
{
    if (spine_isValid[spine_hdr.udp_hdr]) {
        spine_p4b_checksum_updated := true;
        havoc spine_hdr.udp_hdr.checksum;
    }
}

// spine_Control spine_partitionswitchEgress
procedure {:inline 1} spine_partitionswitchEgress()
	modifies spine_cache_frequency_res_0, spine_hdr_eg.op_hdr.optype, spine_hdr_eg.vallen_hdr.vallen, spine_isValid, spine_meta.is_cached, spine_meta.is_deleted, spine_partitionswitchEgress_access_cache_frequency_tbl.action_run, spine_partitionswitchEgress_access_cache_frequency_tbl.hit, spine_partitionswitchEgress_access_deleted_tbl.action_run, spine_partitionswitchEgress_access_deleted_tbl.hit, spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run, spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit, spine_partitionswitchEgress_cache_frequency_reg, spine_partitionswitchEgress_cache_frequency_reg__last0_old_value, spine_partitionswitchEgress_cache_frequency_reg__last0_value, spine_partitionswitchEgress_cache_frequency_reg__last_index, spine_partitionswitchEgress_cache_frequency_reg__last_old_value, spine_partitionswitchEgress_cache_frequency_reg__last_value, spine_partitionswitchEgress_cache_frequency_reg__last_write_site, spine_partitionswitchEgress_cache_frequency_reg__next_write_site, spine_partitionswitchEgress_cache_frequency_reg__wrote_any, spine_partitionswitchEgress_cache_frequency_reg__wrote_index0, spine_partitionswitchEgress_deleted_reg, spine_partitionswitchEgress_deleted_reg__last0_old_value, spine_partitionswitchEgress_deleted_reg__last0_value, spine_partitionswitchEgress_deleted_reg__last_index, spine_partitionswitchEgress_deleted_reg__last_old_value, spine_partitionswitchEgress_deleted_reg__last_value, spine_partitionswitchEgress_deleted_reg__last_write_site, spine_partitionswitchEgress_deleted_reg__next_write_site, spine_partitionswitchEgress_deleted_reg__wrote_any, spine_partitionswitchEgress_deleted_reg__wrote_index0, spine_partitionswitchEgress_eg_port_forward_tbl.action_run, spine_partitionswitchEgress_eg_port_forward_tbl.hit, spine_partitionswitchEgress_eg_port_forward_tbl.partitionswitchEgress_update_netcache_getreq_spine_to_getres_by_mirroring.stat_1, spine_partitionswitchEgress_update_pktlen_tbl.action_run, spine_partitionswitchEgress_update_pktlen_tbl.hit, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_vallen_tbl.action_run, spine_partitionswitchEgress_update_vallen_tbl.hit, spine_partitionswitchEgress_vallen_reg, spine_partitionswitchEgress_vallen_reg__last0_old_value, spine_partitionswitchEgress_vallen_reg__last0_value, spine_partitionswitchEgress_vallen_reg__last_index, spine_partitionswitchEgress_vallen_reg__last_old_value, spine_partitionswitchEgress_vallen_reg__last_value, spine_partitionswitchEgress_vallen_reg__last_write_site, spine_partitionswitchEgress_vallen_reg__next_write_site, spine_partitionswitchEgress_vallen_reg__wrote_any, spine_partitionswitchEgress_vallen_reg__wrote_index0;
{
havoc spine_cache_frequency_res_0;
    call spine_partitionswitchEgress_access_deleted_tbl.apply();
    call spine_partitionswitchEgress_access_cache_frequency_tbl.apply();
    if((spine_meta.is_spine == 1bv1)){
        call spine_partitionswitchEgress_update_vallen_tbl.apply();
    }
    call spine_partitionswitchEgress_eg_port_forward_tbl.apply();
    if((spine_meta.is_spine == 1bv1)){
        call spine_partitionswitchEgress_update_pktlen_tbl.apply();
        call spine_partitionswitchEgress_add_and_remove_value_header_tbl.apply();
    }
}

// spine_Table spine_partitionswitchEgress_access_cache_frequency_tbl
procedure {:inline 1} spine_partitionswitchEgress_access_cache_frequency_tbl.apply()
	modifies spine_cache_frequency_res_0, spine_hdr_eg.op_hdr.optype, spine_meta.is_cached, spine_partitionswitchEgress_access_cache_frequency_tbl.action_run, spine_partitionswitchEgress_access_cache_frequency_tbl.hit, spine_partitionswitchEgress_cache_frequency_reg, spine_partitionswitchEgress_cache_frequency_reg__last0_old_value, spine_partitionswitchEgress_cache_frequency_reg__last0_value, spine_partitionswitchEgress_cache_frequency_reg__last_index, spine_partitionswitchEgress_cache_frequency_reg__last_old_value, spine_partitionswitchEgress_cache_frequency_reg__last_value, spine_partitionswitchEgress_cache_frequency_reg__last_write_site, spine_partitionswitchEgress_cache_frequency_reg__next_write_site, spine_partitionswitchEgress_cache_frequency_reg__wrote_any, spine_partitionswitchEgress_cache_frequency_reg__wrote_index0;
{
    spine_hdr_eg.op_hdr.optype := spine_hdr_eg.op_hdr.optype;
    spine_meta.is_cached := spine_meta.is_cached;
    spine_partitionswitchEgress_access_cache_frequency_tbl.hit := false;
    if(spine_hdr_eg.op_hdr.optype == 512bv16 && spine_meta.is_cached == 1bv1){
        spine_partitionswitchEgress_access_cache_frequency_tbl.hit := true;
        spine_partitionswitchEgress_access_cache_frequency_tbl.action_run := spine_partitionswitchEgress_access_cache_frequency_tbl.action.partitionswitchEgress_update_cache_frequency;
        call spine_partitionswitchEgress_update_cache_frequency();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 127bv16 && spine_meta.is_cached == 0bv1){
        spine_partitionswitchEgress_access_cache_frequency_tbl.hit := true;
        spine_partitionswitchEgress_access_cache_frequency_tbl.action_run := spine_partitionswitchEgress_access_cache_frequency_tbl.action.partitionswitchEgress_reset_cache_frequency;
        call spine_partitionswitchEgress_reset_cache_frequency();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 351bv16 && spine_meta.is_cached == 0bv1){
        spine_partitionswitchEgress_access_cache_frequency_tbl.hit := true;
        spine_partitionswitchEgress_access_cache_frequency_tbl.action_run := spine_partitionswitchEgress_access_cache_frequency_tbl.action.partitionswitchEgress_reset_cache_frequency;
        call spine_partitionswitchEgress_reset_cache_frequency();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 127bv16 && spine_meta.is_cached == 1bv1){
        spine_partitionswitchEgress_access_cache_frequency_tbl.hit := true;
        spine_partitionswitchEgress_access_cache_frequency_tbl.action_run := spine_partitionswitchEgress_access_cache_frequency_tbl.action.partitionswitchEgress_reset_cache_frequency;
        call spine_partitionswitchEgress_reset_cache_frequency();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 351bv16 && spine_meta.is_cached == 1bv1){
        spine_partitionswitchEgress_access_cache_frequency_tbl.hit := true;
        spine_partitionswitchEgress_access_cache_frequency_tbl.action_run := spine_partitionswitchEgress_access_cache_frequency_tbl.action.partitionswitchEgress_reset_cache_frequency;
        call spine_partitionswitchEgress_reset_cache_frequency();
        goto spine_Exit;
    }
    if(!spine_partitionswitchEgress_access_cache_frequency_tbl.hit){
        spine_partitionswitchEgress_access_cache_frequency_tbl.action_run := spine_partitionswitchEgress_access_cache_frequency_tbl.action.NoAction_41;
        call spine_NoAction_41();
        goto spine_Exit;
    }

    spine_Exit:
}

// spine_Table spine_partitionswitchEgress_access_deleted_tbl
procedure {:inline 1} spine_partitionswitchEgress_access_deleted_tbl.apply()
	modifies spine_hdr_eg.op_hdr.optype, spine_meta.is_cached, spine_meta.is_deleted, spine_partitionswitchEgress_access_deleted_tbl.action_run, spine_partitionswitchEgress_access_deleted_tbl.hit, spine_partitionswitchEgress_deleted_reg, spine_partitionswitchEgress_deleted_reg__last0_old_value, spine_partitionswitchEgress_deleted_reg__last0_value, spine_partitionswitchEgress_deleted_reg__last_index, spine_partitionswitchEgress_deleted_reg__last_old_value, spine_partitionswitchEgress_deleted_reg__last_value, spine_partitionswitchEgress_deleted_reg__last_write_site, spine_partitionswitchEgress_deleted_reg__next_write_site, spine_partitionswitchEgress_deleted_reg__wrote_any, spine_partitionswitchEgress_deleted_reg__wrote_index0;
{
    spine_hdr_eg.op_hdr.optype := spine_hdr_eg.op_hdr.optype;
    spine_meta.is_cached := spine_meta.is_cached;
    spine_partitionswitchEgress_access_deleted_tbl.hit := false;
    if(spine_hdr_eg.op_hdr.optype == 512bv16 && spine_meta.is_cached == 1bv1){
        spine_partitionswitchEgress_access_deleted_tbl.hit := true;
        spine_partitionswitchEgress_access_deleted_tbl.action_run := spine_partitionswitchEgress_access_deleted_tbl.action.partitionswitchEgress_get_deleted;
        call spine_partitionswitchEgress_get_deleted();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 1bv16 && spine_meta.is_cached == 1bv1){
        spine_partitionswitchEgress_access_deleted_tbl.hit := true;
        spine_partitionswitchEgress_access_deleted_tbl.action_run := spine_partitionswitchEgress_access_deleted_tbl.action.partitionswitchEgress_set_and_get_deleted;
        call spine_partitionswitchEgress_set_and_get_deleted();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 64bv16 && spine_meta.is_cached == 1bv1){
        spine_partitionswitchEgress_access_deleted_tbl.hit := true;
        spine_partitionswitchEgress_access_deleted_tbl.action_run := spine_partitionswitchEgress_access_deleted_tbl.action.partitionswitchEgress_set_and_get_deleted;
        call spine_partitionswitchEgress_set_and_get_deleted();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 59bv16 && spine_meta.is_cached == 1bv1){
        spine_partitionswitchEgress_access_deleted_tbl.hit := true;
        spine_partitionswitchEgress_access_deleted_tbl.action_run := spine_partitionswitchEgress_access_deleted_tbl.action.partitionswitchEgress_reset_and_get_deleted;
        call spine_partitionswitchEgress_reset_and_get_deleted();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 127bv16 && spine_meta.is_cached == 1bv1){
        spine_partitionswitchEgress_access_deleted_tbl.hit := true;
        spine_partitionswitchEgress_access_deleted_tbl.action_run := spine_partitionswitchEgress_access_deleted_tbl.action.partitionswitchEgress_reset_and_get_deleted;
        call spine_partitionswitchEgress_reset_and_get_deleted();
        goto spine_Exit;
    }
    if(!spine_partitionswitchEgress_access_deleted_tbl.hit){
        spine_partitionswitchEgress_access_deleted_tbl.action_run := spine_partitionswitchEgress_access_deleted_tbl.action.partitionswitchEgress_reset_is_deleted;
        call spine_partitionswitchEgress_reset_is_deleted();
        goto spine_Exit;
    }

    spine_Exit:
}

// spine_Table spine_partitionswitchEgress_add_and_remove_value_header_tbl
procedure {:inline 1} spine_partitionswitchEgress_add_and_remove_value_header_tbl.apply()
	modifies spine_hdr_eg.op_hdr.optype, spine_hdr_eg.vallen_hdr.vallen, spine_isValid, spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run, spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit;
{
    spine_hdr_eg.op_hdr.optype := spine_hdr_eg.op_hdr.optype;
    spine_hdr_eg.vallen_hdr.vallen := spine_hdr_eg.vallen_hdr.vallen;
    spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := false;
    if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_only_vallen;
        call spine_partitionswitchEgress_add_only_vallen();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 1bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 8bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val1;
        call spine_partitionswitchEgress_add_to_val1();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 9bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 16bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val2;
        call spine_partitionswitchEgress_add_to_val2();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 17bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 24bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val3;
        call spine_partitionswitchEgress_add_to_val3();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 25bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 32bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val4;
        call spine_partitionswitchEgress_add_to_val4();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 33bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 40bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val5;
        call spine_partitionswitchEgress_add_to_val5();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 41bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 48bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val6;
        call spine_partitionswitchEgress_add_to_val6();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 49bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 56bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val7;
        call spine_partitionswitchEgress_add_to_val7();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 57bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 64bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val8;
        call spine_partitionswitchEgress_add_to_val8();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 65bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 72bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val9;
        call spine_partitionswitchEgress_add_to_val9();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 73bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 80bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val10;
        call spine_partitionswitchEgress_add_to_val10();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 81bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 88bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val11;
        call spine_partitionswitchEgress_add_to_val11();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 89bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 96bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val12;
        call spine_partitionswitchEgress_add_to_val12();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 97bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 104bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val13;
        call spine_partitionswitchEgress_add_to_val13();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 105bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 112bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val14;
        call spine_partitionswitchEgress_add_to_val14();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 113bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 120bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val15;
        call spine_partitionswitchEgress_add_to_val15();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 121bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 128bv16))){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit := true;
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_add_to_val16;
        call spine_partitionswitchEgress_add_to_val16();
        goto spine_Exit;
    }
    if(!spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit){
        spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run := spine_partitionswitchEgress_add_and_remove_value_header_tbl.action.partitionswitchEgress_remove_all;
        call spine_partitionswitchEgress_remove_all();
        goto spine_Exit;
    }

    spine_Exit:
}

// spine_Action spine_partitionswitchEgress_add_only_vallen
procedure {:inline 1} spine_partitionswitchEgress_add_only_vallen()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val1
procedure {:inline 1} spine_partitionswitchEgress_add_to_val1()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val10
procedure {:inline 1} spine_partitionswitchEgress_add_to_val10()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val11
procedure {:inline 1} spine_partitionswitchEgress_add_to_val11()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val12
procedure {:inline 1} spine_partitionswitchEgress_add_to_val12()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val13
procedure {:inline 1} spine_partitionswitchEgress_add_to_val13()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val14
procedure {:inline 1} spine_partitionswitchEgress_add_to_val14()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val15
procedure {:inline 1} spine_partitionswitchEgress_add_to_val15()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val16
procedure {:inline 1} spine_partitionswitchEgress_add_to_val16()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val2
procedure {:inline 1} spine_partitionswitchEgress_add_to_val2()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val3
procedure {:inline 1} spine_partitionswitchEgress_add_to_val3()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val4
procedure {:inline 1} spine_partitionswitchEgress_add_to_val4()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val5
procedure {:inline 1} spine_partitionswitchEgress_add_to_val5()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val6
procedure {:inline 1} spine_partitionswitchEgress_add_to_val6()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val7
procedure {:inline 1} spine_partitionswitchEgress_add_to_val7()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val8
procedure {:inline 1} spine_partitionswitchEgress_add_to_val8()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_add_to_val9
procedure {:inline 1} spine_partitionswitchEgress_add_to_val9()
	modifies spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
}
function {:inline true}spine_partitionswitchEgress_cache_frequency_reg.read(spine_reg:[bv32]bv32, spine_index:bv32)returns (bv32) {spine_reg[spine_index]}
procedure {:inline 1} spine_partitionswitchEgress_cache_frequency_reg.write(spine_index:bv32, spine_value:bv32)
	modifies spine_partitionswitchEgress_cache_frequency_reg, spine_partitionswitchEgress_cache_frequency_reg__last0_old_value, spine_partitionswitchEgress_cache_frequency_reg__last0_value, spine_partitionswitchEgress_cache_frequency_reg__last_index, spine_partitionswitchEgress_cache_frequency_reg__last_old_value, spine_partitionswitchEgress_cache_frequency_reg__last_value, spine_partitionswitchEgress_cache_frequency_reg__last_write_site, spine_partitionswitchEgress_cache_frequency_reg__wrote_any, spine_partitionswitchEgress_cache_frequency_reg__wrote_index0;
{
    spine_partitionswitchEgress_cache_frequency_reg__last_old_value := spine_partitionswitchEgress_cache_frequency_reg[spine_index];
    spine_partitionswitchEgress_cache_frequency_reg[spine_index] := spine_value;
    spine_partitionswitchEgress_cache_frequency_reg__last_index := spine_index;
    spine_partitionswitchEgress_cache_frequency_reg__last_value := spine_value;
    spine_partitionswitchEgress_cache_frequency_reg__last_write_site := spine_partitionswitchEgress_cache_frequency_reg__next_write_site;
    spine_partitionswitchEgress_cache_frequency_reg__wrote_any := true;
    if (spine_index == 0bv32) {
        spine_partitionswitchEgress_cache_frequency_reg__wrote_index0 := true;
        spine_partitionswitchEgress_cache_frequency_reg__last0_old_value := spine_partitionswitchEgress_cache_frequency_reg__last_old_value;
        spine_partitionswitchEgress_cache_frequency_reg__last0_value := spine_value;
    }
}
function {:inline true}spine_partitionswitchEgress_deleted_reg.read(spine_reg:[bv32]bv1, spine_index:bv32)returns (bv1) {spine_reg[spine_index]}
procedure {:inline 1} spine_partitionswitchEgress_deleted_reg.write(spine_index:bv32, spine_value:bv1)
	modifies spine_partitionswitchEgress_deleted_reg, spine_partitionswitchEgress_deleted_reg__last0_old_value, spine_partitionswitchEgress_deleted_reg__last0_value, spine_partitionswitchEgress_deleted_reg__last_index, spine_partitionswitchEgress_deleted_reg__last_old_value, spine_partitionswitchEgress_deleted_reg__last_value, spine_partitionswitchEgress_deleted_reg__last_write_site, spine_partitionswitchEgress_deleted_reg__wrote_any, spine_partitionswitchEgress_deleted_reg__wrote_index0;
{
    spine_partitionswitchEgress_deleted_reg__last_old_value := spine_partitionswitchEgress_deleted_reg[spine_index];
    spine_partitionswitchEgress_deleted_reg[spine_index] := spine_value;
    spine_partitionswitchEgress_deleted_reg__last_index := spine_index;
    spine_partitionswitchEgress_deleted_reg__last_value := spine_value;
    spine_partitionswitchEgress_deleted_reg__last_write_site := spine_partitionswitchEgress_deleted_reg__next_write_site;
    spine_partitionswitchEgress_deleted_reg__wrote_any := true;
    if (spine_index == 0bv32) {
        spine_partitionswitchEgress_deleted_reg__wrote_index0 := true;
        spine_partitionswitchEgress_deleted_reg__last0_old_value := spine_partitionswitchEgress_deleted_reg__last_old_value;
        spine_partitionswitchEgress_deleted_reg__last0_value := spine_value;
    }
}

// spine_Table spine_partitionswitchEgress_eg_port_forward_tbl
procedure {:inline 1} spine_partitionswitchEgress_eg_port_forward_tbl.apply()
	modifies spine_hdr_eg.op_hdr.optype, spine_meta.is_cached, spine_partitionswitchEgress_eg_port_forward_tbl.action_run, spine_partitionswitchEgress_eg_port_forward_tbl.hit, spine_partitionswitchEgress_eg_port_forward_tbl.partitionswitchEgress_update_netcache_getreq_spine_to_getres_by_mirroring.stat_1;
{
    spine_hdr_eg.op_hdr.optype := spine_hdr_eg.op_hdr.optype;
    spine_meta.is_cached := spine_meta.is_cached;
    spine_partitionswitchEgress_eg_port_forward_tbl.hit := false;
    if(spine_hdr_eg.op_hdr.optype == 512bv16 && spine_meta.is_cached == 0bv1){
        spine_partitionswitchEgress_eg_port_forward_tbl.hit := true;
        spine_partitionswitchEgress_eg_port_forward_tbl.action_run := spine_partitionswitchEgress_eg_port_forward_tbl.action.partitionswitchEgress_update_netcache_getreq_spine_to_getreq;
        call spine_partitionswitchEgress_update_netcache_getreq_spine_to_getreq();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 512bv16 && spine_meta.is_cached == 1bv1){
        spine_partitionswitchEgress_eg_port_forward_tbl.hit := true;
        spine_partitionswitchEgress_eg_port_forward_tbl.action_run := spine_partitionswitchEgress_eg_port_forward_tbl.action.partitionswitchEgress_update_netcache_getreq_spine_to_getres_by_mirroring;
        spine_partitionswitchEgress_eg_port_forward_tbl.partitionswitchEgress_update_netcache_getreq_spine_to_getres_by_mirroring.stat_1 := 1bv8;
        call spine_partitionswitchEgress_update_netcache_getreq_spine_to_getres_by_mirroring(spine_partitionswitchEgress_eg_port_forward_tbl.partitionswitchEgress_update_netcache_getreq_spine_to_getres_by_mirroring.stat_1);
        goto spine_Exit;
    }
    if(!spine_partitionswitchEgress_eg_port_forward_tbl.hit){
        spine_partitionswitchEgress_eg_port_forward_tbl.action_run := spine_partitionswitchEgress_eg_port_forward_tbl.action.NoAction_42;
        call spine_NoAction_42();
        goto spine_Exit;
    }

    spine_Exit:
}

// spine_Action spine_partitionswitchEgress_get_deleted
procedure {:inline 1} spine_partitionswitchEgress_get_deleted()
	modifies spine_meta.is_cached, spine_meta.is_deleted;
{
    // spine_read
    spine_meta.is_deleted := spine_partitionswitchEgress_deleted_reg.read(spine_partitionswitchEgress_deleted_reg, 0bv16++spine_meta.idx);
    if((spine_meta.is_deleted == 1bv1)){
        spine_meta.is_cached := 0bv1;
    }
}

// spine_Action spine_partitionswitchEgress_get_vallen
procedure {:inline 1} spine_partitionswitchEgress_get_vallen()
	modifies spine_hdr_eg.vallen_hdr.vallen, spine_isValid;
{
    call spine_setValid(spine_hdr_eg.vallen_hdr);
    // spine_read
    spine_hdr_eg.vallen_hdr.vallen := spine_partitionswitchEgress_vallen_reg.read(spine_partitionswitchEgress_vallen_reg, 0bv16++spine_meta.idx);
}

// spine_Action spine_partitionswitchEgress_remove_all
procedure {:inline 1} spine_partitionswitchEgress_remove_all()
	modifies spine_isValid;
{
    call spine_setInvalid(spine_hdr_eg.vallen_hdr);
}

// spine_Action spine_partitionswitchEgress_reset_access_val_mode
procedure {:inline 1} spine_partitionswitchEgress_reset_access_val_mode()
{
}

// spine_Action spine_partitionswitchEgress_reset_and_get_deleted
procedure {:inline 1} spine_partitionswitchEgress_reset_and_get_deleted()
	modifies spine_meta.is_deleted, spine_partitionswitchEgress_deleted_reg, spine_partitionswitchEgress_deleted_reg__last0_old_value, spine_partitionswitchEgress_deleted_reg__last0_value, spine_partitionswitchEgress_deleted_reg__last_index, spine_partitionswitchEgress_deleted_reg__last_old_value, spine_partitionswitchEgress_deleted_reg__last_value, spine_partitionswitchEgress_deleted_reg__last_write_site, spine_partitionswitchEgress_deleted_reg__next_write_site, spine_partitionswitchEgress_deleted_reg__wrote_any, spine_partitionswitchEgress_deleted_reg__wrote_index0;
{
    // spine_write
    spine_partitionswitchEgress_deleted_reg__next_write_site := 2;
    call spine_partitionswitchEgress_deleted_reg.write(0bv16++spine_meta.idx, 0bv1);
    spine_meta.is_deleted := 0bv1;
}

// spine_Action spine_partitionswitchEgress_reset_cache_frequency
procedure {:inline 1} spine_partitionswitchEgress_reset_cache_frequency()
	modifies spine_partitionswitchEgress_cache_frequency_reg, spine_partitionswitchEgress_cache_frequency_reg__last0_old_value, spine_partitionswitchEgress_cache_frequency_reg__last0_value, spine_partitionswitchEgress_cache_frequency_reg__last_index, spine_partitionswitchEgress_cache_frequency_reg__last_old_value, spine_partitionswitchEgress_cache_frequency_reg__last_value, spine_partitionswitchEgress_cache_frequency_reg__last_write_site, spine_partitionswitchEgress_cache_frequency_reg__next_write_site, spine_partitionswitchEgress_cache_frequency_reg__wrote_any, spine_partitionswitchEgress_cache_frequency_reg__wrote_index0;
{
    // spine_write
    spine_partitionswitchEgress_cache_frequency_reg__next_write_site := 2;
    assume (bule.bv32(0bv16++spine_hdr_eg.inswitch_hdr.idx, 7bv32));
    call spine_partitionswitchEgress_cache_frequency_reg.write(0bv16++spine_hdr_eg.inswitch_hdr.idx, 0bv32);
}

// spine_Action spine_partitionswitchEgress_reset_is_deleted
procedure {:inline 1} spine_partitionswitchEgress_reset_is_deleted()
	modifies spine_meta.is_deleted;
{
    spine_meta.is_deleted := 0bv1;
}

// spine_Action spine_partitionswitchEgress_set_and_get_deleted
procedure {:inline 1} spine_partitionswitchEgress_set_and_get_deleted()
	modifies spine_meta.is_deleted, spine_partitionswitchEgress_deleted_reg, spine_partitionswitchEgress_deleted_reg__last0_old_value, spine_partitionswitchEgress_deleted_reg__last0_value, spine_partitionswitchEgress_deleted_reg__last_index, spine_partitionswitchEgress_deleted_reg__last_old_value, spine_partitionswitchEgress_deleted_reg__last_value, spine_partitionswitchEgress_deleted_reg__last_write_site, spine_partitionswitchEgress_deleted_reg__next_write_site, spine_partitionswitchEgress_deleted_reg__wrote_any, spine_partitionswitchEgress_deleted_reg__wrote_index0;
{
    // spine_write
    spine_partitionswitchEgress_deleted_reg__next_write_site := 1;
    call spine_partitionswitchEgress_deleted_reg.write(0bv16++spine_meta.idx, 1bv1);
    spine_meta.is_deleted := 1bv1;
}

// spine_Action spine_partitionswitchEgress_set_and_get_vallen
procedure {:inline 1} spine_partitionswitchEgress_set_and_get_vallen()
	modifies spine_partitionswitchEgress_vallen_reg, spine_partitionswitchEgress_vallen_reg__last0_old_value, spine_partitionswitchEgress_vallen_reg__last0_value, spine_partitionswitchEgress_vallen_reg__last_index, spine_partitionswitchEgress_vallen_reg__last_old_value, spine_partitionswitchEgress_vallen_reg__last_value, spine_partitionswitchEgress_vallen_reg__last_write_site, spine_partitionswitchEgress_vallen_reg__next_write_site, spine_partitionswitchEgress_vallen_reg__wrote_any, spine_partitionswitchEgress_vallen_reg__wrote_index0;
{
    // spine_write
    spine_partitionswitchEgress_vallen_reg__next_write_site := 1;
    call spine_partitionswitchEgress_vallen_reg.write(0bv16++spine_meta.idx, spine_hdr_eg.vallen_hdr.vallen);
}

// spine_Action spine_partitionswitchEgress_update_cache_frequency
procedure {:inline 1} spine_partitionswitchEgress_update_cache_frequency()
	modifies spine_cache_frequency_res_0, spine_partitionswitchEgress_cache_frequency_reg, spine_partitionswitchEgress_cache_frequency_reg__last0_old_value, spine_partitionswitchEgress_cache_frequency_reg__last0_value, spine_partitionswitchEgress_cache_frequency_reg__last_index, spine_partitionswitchEgress_cache_frequency_reg__last_old_value, spine_partitionswitchEgress_cache_frequency_reg__last_value, spine_partitionswitchEgress_cache_frequency_reg__last_write_site, spine_partitionswitchEgress_cache_frequency_reg__next_write_site, spine_partitionswitchEgress_cache_frequency_reg__wrote_any, spine_partitionswitchEgress_cache_frequency_reg__wrote_index0;
{
    // spine_read
        assume (bule.bv32(0bv16++spine_hdr_eg.inswitch_hdr.idx, 7bv32));
spine_cache_frequency_res_0 := spine_partitionswitchEgress_cache_frequency_reg.read(spine_partitionswitchEgress_cache_frequency_reg, 0bv16++spine_hdr_eg.inswitch_hdr.idx);
    // spine_write
    spine_partitionswitchEgress_cache_frequency_reg__next_write_site := 1;
    assume (bule.bv32(0bv16++spine_hdr_eg.inswitch_hdr.idx, 7bv32));
    call spine_partitionswitchEgress_cache_frequency_reg.write(0bv16++spine_hdr_eg.inswitch_hdr.idx, add.bv32(spine_cache_frequency_res_0, 1bv32));
}

// spine_Action spine_partitionswitchEgress_update_netcache_getreq_spine_to_getreq
procedure {:inline 1} spine_partitionswitchEgress_update_netcache_getreq_spine_to_getreq()
	modifies spine_hdr_eg.op_hdr.optype;
{
    spine_hdr_eg.op_hdr.optype := 48bv16;
}

// spine_Action spine_partitionswitchEgress_update_netcache_getreq_spine_to_getres_by_mirroring
procedure {:inline 1} spine_partitionswitchEgress_update_netcache_getreq_spine_to_getres_by_mirroring(spine_stat_1:bv8)
	modifies spine_hdr_eg.op_hdr.optype;
{
    spine_hdr_eg.op_hdr.optype := 9bv16;
}

// spine_Action spine_partitionswitchEgress_update_pktlen
procedure {:inline 1} spine_partitionswitchEgress_update_pktlen(spine_udplen:bv16, spine_iplen:bv16)
{
}

// spine_Table spine_partitionswitchEgress_update_pktlen_tbl
procedure {:inline 1} spine_partitionswitchEgress_update_pktlen_tbl.apply()
	modifies spine_hdr_eg.op_hdr.optype, spine_hdr_eg.vallen_hdr.vallen, spine_partitionswitchEgress_update_pktlen_tbl.action_run, spine_partitionswitchEgress_update_pktlen_tbl.hit, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen;
{
    spine_hdr_eg.op_hdr.optype := spine_hdr_eg.op_hdr.optype;
    spine_hdr_eg.vallen_hdr.vallen := spine_hdr_eg.vallen_hdr.vallen;
    spine_partitionswitchEgress_update_pktlen_tbl.hit := false;
    if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 9bv16 && (buge.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16)) && (bule.bv16(spine_hdr_eg.vallen_hdr.vallen, 0bv16))){
        spine_partitionswitchEgress_update_pktlen_tbl.hit := true;
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.partitionswitchEgress_update_pktlen;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen := 32bv16;
        spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen := 64bv16;
        call spine_partitionswitchEgress_update_pktlen(spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen);
        goto spine_Exit;
    }
    if(!spine_partitionswitchEgress_update_pktlen_tbl.hit){
        spine_partitionswitchEgress_update_pktlen_tbl.action_run := spine_partitionswitchEgress_update_pktlen_tbl.action.NoAction_43;
        call spine_NoAction_43();
        goto spine_Exit;
    }

    spine_Exit:
}

// spine_Table spine_partitionswitchEgress_update_vallen_tbl
procedure {:inline 1} spine_partitionswitchEgress_update_vallen_tbl.apply()
	modifies spine_hdr_eg.op_hdr.optype, spine_hdr_eg.vallen_hdr.vallen, spine_isValid, spine_meta.is_cached, spine_partitionswitchEgress_update_vallen_tbl.action_run, spine_partitionswitchEgress_update_vallen_tbl.hit, spine_partitionswitchEgress_vallen_reg, spine_partitionswitchEgress_vallen_reg__last0_old_value, spine_partitionswitchEgress_vallen_reg__last0_value, spine_partitionswitchEgress_vallen_reg__last_index, spine_partitionswitchEgress_vallen_reg__last_old_value, spine_partitionswitchEgress_vallen_reg__last_value, spine_partitionswitchEgress_vallen_reg__last_write_site, spine_partitionswitchEgress_vallen_reg__next_write_site, spine_partitionswitchEgress_vallen_reg__wrote_any, spine_partitionswitchEgress_vallen_reg__wrote_index0;
{
    spine_hdr_eg.op_hdr.optype := spine_hdr_eg.op_hdr.optype;
    spine_meta.is_cached := spine_meta.is_cached;
    spine_partitionswitchEgress_update_vallen_tbl.hit := false;
    if(spine_hdr_eg.op_hdr.optype == 512bv16 && spine_meta.is_cached == 1bv1){
        spine_partitionswitchEgress_update_vallen_tbl.hit := true;
        spine_partitionswitchEgress_update_vallen_tbl.action_run := spine_partitionswitchEgress_update_vallen_tbl.action.partitionswitchEgress_get_vallen;
        call spine_partitionswitchEgress_get_vallen();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 127bv16 && spine_meta.is_cached == 0bv1){
        spine_partitionswitchEgress_update_vallen_tbl.hit := true;
        spine_partitionswitchEgress_update_vallen_tbl.action_run := spine_partitionswitchEgress_update_vallen_tbl.action.partitionswitchEgress_set_and_get_vallen;
        call spine_partitionswitchEgress_set_and_get_vallen();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 127bv16 && spine_meta.is_cached == 1bv1){
        spine_partitionswitchEgress_update_vallen_tbl.hit := true;
        spine_partitionswitchEgress_update_vallen_tbl.action_run := spine_partitionswitchEgress_update_vallen_tbl.action.partitionswitchEgress_set_and_get_vallen;
        call spine_partitionswitchEgress_set_and_get_vallen();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 59bv16 && spine_meta.is_cached == 0bv1){
        spine_partitionswitchEgress_update_vallen_tbl.hit := true;
        spine_partitionswitchEgress_update_vallen_tbl.action_run := spine_partitionswitchEgress_update_vallen_tbl.action.partitionswitchEgress_set_and_get_vallen;
        call spine_partitionswitchEgress_set_and_get_vallen();
        goto spine_Exit;
    }
    else if(spine_hdr_eg.op_hdr.optype == 59bv16 && spine_meta.is_cached == 1bv1){
        spine_partitionswitchEgress_update_vallen_tbl.hit := true;
        spine_partitionswitchEgress_update_vallen_tbl.action_run := spine_partitionswitchEgress_update_vallen_tbl.action.partitionswitchEgress_set_and_get_vallen;
        call spine_partitionswitchEgress_set_and_get_vallen();
        goto spine_Exit;
    }
    if(!spine_partitionswitchEgress_update_vallen_tbl.hit){
        spine_partitionswitchEgress_update_vallen_tbl.action_run := spine_partitionswitchEgress_update_vallen_tbl.action.partitionswitchEgress_reset_access_val_mode;
        call spine_partitionswitchEgress_reset_access_val_mode();
        goto spine_Exit;
    }

    spine_Exit:
}
function {:inline true}spine_partitionswitchEgress_vallen_reg.read(spine_reg:[bv32]bv16, spine_index:bv32)returns (bv16) {spine_reg[spine_index]}
procedure {:inline 1} spine_partitionswitchEgress_vallen_reg.write(spine_index:bv32, spine_value:bv16)
	modifies spine_partitionswitchEgress_vallen_reg, spine_partitionswitchEgress_vallen_reg__last0_old_value, spine_partitionswitchEgress_vallen_reg__last0_value, spine_partitionswitchEgress_vallen_reg__last_index, spine_partitionswitchEgress_vallen_reg__last_old_value, spine_partitionswitchEgress_vallen_reg__last_value, spine_partitionswitchEgress_vallen_reg__last_write_site, spine_partitionswitchEgress_vallen_reg__wrote_any, spine_partitionswitchEgress_vallen_reg__wrote_index0;
{
    spine_partitionswitchEgress_vallen_reg__last_old_value := spine_partitionswitchEgress_vallen_reg[spine_index];
    spine_partitionswitchEgress_vallen_reg[spine_index] := spine_value;
    spine_partitionswitchEgress_vallen_reg__last_index := spine_index;
    spine_partitionswitchEgress_vallen_reg__last_value := spine_value;
    spine_partitionswitchEgress_vallen_reg__last_write_site := spine_partitionswitchEgress_vallen_reg__next_write_site;
    spine_partitionswitchEgress_vallen_reg__wrote_any := true;
    if (spine_index == 0bv32) {
        spine_partitionswitchEgress_vallen_reg__wrote_index0 := true;
        spine_partitionswitchEgress_vallen_reg__last0_old_value := spine_partitionswitchEgress_vallen_reg__last_old_value;
        spine_partitionswitchEgress_vallen_reg__last0_value := spine_value;
    }
}

// spine_Control spine_partitionswitchIngress
procedure {:inline 1} spine_partitionswitchIngress()
	modifies spine_hdr.op_hdr.keyhihihi, spine_hdr.op_hdr.keyhihilo, spine_hdr.op_hdr.keyhilo, spine_hdr.op_hdr.keylohi, spine_hdr.op_hdr.keylolo, spine_hdr.op_hdr.optype, spine_meta.idx, spine_meta.is_cached, spine_meta.is_spine, spine_partitionswitchIngress_cache_lookup_tbl.action_run, spine_partitionswitchIngress_cache_lookup_tbl.hit, spine_partitionswitchIngress_cache_lookup_tbl.partitionswitchIngress_cached_action.idx_1, spine_partitionswitchIngress_set_spine_tbl.action_run, spine_partitionswitchIngress_set_spine_tbl.hit;
{
    if(spine_isValid[spine_hdr.op_hdr]){
        call spine_partitionswitchIngress_set_spine_tbl.apply();
        call spine_partitionswitchIngress_cache_lookup_tbl.apply();
    }
    else{
    }
}

// spine_Table spine_partitionswitchIngress_cache_lookup_tbl
procedure {:inline 1} spine_partitionswitchIngress_cache_lookup_tbl.apply()
	modifies spine_hdr.op_hdr.keyhihihi, spine_hdr.op_hdr.keyhihilo, spine_hdr.op_hdr.keyhilo, spine_hdr.op_hdr.keylohi, spine_hdr.op_hdr.keylolo, spine_meta.idx, spine_meta.is_cached, spine_partitionswitchIngress_cache_lookup_tbl.action_run, spine_partitionswitchIngress_cache_lookup_tbl.hit, spine_partitionswitchIngress_cache_lookup_tbl.partitionswitchIngress_cached_action.idx_1;
{
    spine_hdr.op_hdr.keylolo := spine_hdr.op_hdr.keylolo;
    spine_hdr.op_hdr.keylohi := spine_hdr.op_hdr.keylohi;
    spine_hdr.op_hdr.keyhilo := spine_hdr.op_hdr.keyhilo;
    spine_hdr.op_hdr.keyhihilo := spine_hdr.op_hdr.keyhihilo;
    spine_hdr.op_hdr.keyhihihi := spine_hdr.op_hdr.keyhihihi;
    spine_partitionswitchIngress_cache_lookup_tbl.hit := false;
    if(spine_hdr.op_hdr.keylolo == 2882338817bv32 && spine_hdr.op_hdr.keylohi == 0bv32 && spine_hdr.op_hdr.keyhilo == 0bv32 && spine_hdr.op_hdr.keyhihilo == 0bv16 && spine_hdr.op_hdr.keyhihihi == 0bv16){
        spine_partitionswitchIngress_cache_lookup_tbl.hit := true;
        spine_partitionswitchIngress_cache_lookup_tbl.action_run := spine_partitionswitchIngress_cache_lookup_tbl.action.partitionswitchIngress_cached_action;
        spine_partitionswitchIngress_cache_lookup_tbl.partitionswitchIngress_cached_action.idx_1 := 7bv16;
        call spine_partitionswitchIngress_cached_action(spine_partitionswitchIngress_cache_lookup_tbl.partitionswitchIngress_cached_action.idx_1);
        goto spine_Exit;
    }
    if(!spine_partitionswitchIngress_cache_lookup_tbl.hit){
        spine_partitionswitchIngress_cache_lookup_tbl.action_run := spine_partitionswitchIngress_cache_lookup_tbl.action.partitionswitchIngress_uncached_action;
        call spine_partitionswitchIngress_uncached_action();
        goto spine_Exit;
    }

    spine_Exit:
}

// spine_Action spine_partitionswitchIngress_cached_action
procedure {:inline 1} spine_partitionswitchIngress_cached_action(spine_idx_1:bv16)
	modifies spine_meta.idx, spine_meta.is_cached;
{
    spine_meta.idx := spine_idx_1;
    spine_meta.is_cached := 1bv1;
}

// spine_Action spine_partitionswitchIngress_set_spine
procedure {:inline 1} spine_partitionswitchIngress_set_spine()
	modifies spine_meta.is_spine;
{
    spine_meta.is_spine := 1bv1;
}

// spine_Table spine_partitionswitchIngress_set_spine_tbl
procedure {:inline 1} spine_partitionswitchIngress_set_spine_tbl.apply()
	modifies spine_hdr.op_hdr.optype, spine_meta.is_spine, spine_partitionswitchIngress_set_spine_tbl.action_run, spine_partitionswitchIngress_set_spine_tbl.hit;
{
    spine_hdr.op_hdr.optype := spine_hdr.op_hdr.optype;
    spine_partitionswitchIngress_set_spine_tbl.hit := false;
    if(spine_hdr.op_hdr.optype == 512bv16){
        spine_partitionswitchIngress_set_spine_tbl.hit := true;
        spine_partitionswitchIngress_set_spine_tbl.action_run := spine_partitionswitchIngress_set_spine_tbl.action.partitionswitchIngress_set_spine;
        call spine_partitionswitchIngress_set_spine();
        goto spine_Exit;
    }
    else if(spine_hdr.op_hdr.optype == 127bv16){
        spine_partitionswitchIngress_set_spine_tbl.hit := true;
        spine_partitionswitchIngress_set_spine_tbl.action_run := spine_partitionswitchIngress_set_spine_tbl.action.partitionswitchIngress_set_spine;
        call spine_partitionswitchIngress_set_spine();
        goto spine_Exit;
    }
    else if(spine_hdr.op_hdr.optype == 59bv16){
        spine_partitionswitchIngress_set_spine_tbl.hit := true;
        spine_partitionswitchIngress_set_spine_tbl.action_run := spine_partitionswitchIngress_set_spine_tbl.action.partitionswitchIngress_set_spine;
        call spine_partitionswitchIngress_set_spine();
        goto spine_Exit;
    }
    if(!spine_partitionswitchIngress_set_spine_tbl.hit){
        spine_partitionswitchIngress_set_spine_tbl.action_run := spine_partitionswitchIngress_set_spine_tbl.action.NoAction_7;
        call spine_NoAction_7();
        goto spine_Exit;
    }

    spine_Exit:
}

// spine_Action spine_partitionswitchIngress_uncached_action
procedure {:inline 1} spine_partitionswitchIngress_uncached_action()
	modifies spine_meta.is_cached;
{
    spine_meta.is_cached := 0bv1;
}

// spine_Parser spine_partitionswitchParser
procedure {:inline 1} spine_partitionswitchParser()
	modifies spine_drop, spine_isValid;
{
    goto spine_State$partitionswitchParser$start;

        spine_State$partitionswitchParser$start:
    call spine_packet_in.extract(spine_hdr.ethernet_hdr);
    goto spine_State$partitionswitchParser$start$parse_ipv4_2, spine_State$partitionswitchParser$start$DEFAULT;
    
spine_State$partitionswitchParser$start$parse_ipv4_2:
    assume (spine_hdr.ethernet_hdr.etherType == 2048bv16);
    goto spine_State$partitionswitchParser$parse_ipv4;

    spine_State$partitionswitchParser$start$DEFAULT:
    assume(!(spine_hdr.ethernet_hdr.etherType == 2048bv16));
    goto spine_State$accept;

        spine_State$partitionswitchParser$parse_ipv4:
    call spine_packet_in.extract(spine_hdr.ipv4_hdr);
    goto spine_State$partitionswitchParser$parse_ipv4$parse_udp_dstport_2, spine_State$partitionswitchParser$parse_ipv4$DEFAULT;
    
spine_State$partitionswitchParser$parse_ipv4$parse_udp_dstport_2:
    assume (spine_hdr.ipv4_hdr.protocol == 17bv8);
    goto spine_State$partitionswitchParser$parse_udp_dstport;

    spine_State$partitionswitchParser$parse_ipv4$DEFAULT:
    assume(!(spine_hdr.ipv4_hdr.protocol == 17bv8));
    goto spine_State$accept;

        spine_State$partitionswitchParser$parse_udp_dstport:
    call spine_packet_in.extract(spine_hdr.udp_hdr);
    goto spine_State$partitionswitchParser$parse_udp_dstport$parse_op_4, spine_State$partitionswitchParser$parse_udp_dstport$parse_op_3, spine_State$partitionswitchParser$parse_udp_dstport$parse_op_2, spine_State$partitionswitchParser$parse_udp_dstport$DEFAULT;
    
spine_State$partitionswitchParser$parse_udp_dstport$parse_op_4:
    assume (band.bv16(spine_hdr.udp_hdr.dstPort, 65408bv16) == band.bv16(1152bv16, 65408bv16));
    goto spine_State$partitionswitchParser$parse_op;
    
spine_State$partitionswitchParser$parse_udp_dstport$parse_op_3:
    assume (band.bv16(spine_hdr.udp_hdr.dstPort, 65408bv16) == band.bv16(4224bv16, 65408bv16));
    goto spine_State$partitionswitchParser$parse_op;
    
spine_State$partitionswitchParser$parse_udp_dstport$parse_op_2:
    assume (spine_hdr.udp_hdr.dstPort == 5008bv16);
    goto spine_State$partitionswitchParser$parse_op;

    spine_State$partitionswitchParser$parse_udp_dstport$DEFAULT:
    assume(!(band.bv16(spine_hdr.udp_hdr.dstPort, 65408bv16) == band.bv16(1152bv16, 65408bv16))&&!(band.bv16(spine_hdr.udp_hdr.dstPort, 65408bv16) == band.bv16(4224bv16, 65408bv16))&&!(spine_hdr.udp_hdr.dstPort == 5008bv16));
    goto spine_State$partitionswitchParser$parse_udp_srcport;

        spine_State$partitionswitchParser$parse_udp_srcport:
    goto spine_State$partitionswitchParser$parse_udp_srcport$parse_op_4, spine_State$partitionswitchParser$parse_udp_srcport$parse_op_3, spine_State$partitionswitchParser$parse_udp_srcport$parse_op_2, spine_State$partitionswitchParser$parse_udp_srcport$DEFAULT;
    
spine_State$partitionswitchParser$parse_udp_srcport$parse_op_4:
    assume (band.bv16(spine_hdr.udp_hdr.srcPort, 65408bv16) == band.bv16(1152bv16, 65408bv16));
    goto spine_State$partitionswitchParser$parse_op;
    
spine_State$partitionswitchParser$parse_udp_srcport$parse_op_3:
    assume (band.bv16(spine_hdr.udp_hdr.srcPort, 65408bv16) == band.bv16(4224bv16, 65408bv16));
    goto spine_State$partitionswitchParser$parse_op;
    
spine_State$partitionswitchParser$parse_udp_srcport$parse_op_2:
    assume (spine_hdr.udp_hdr.srcPort == 5009bv16);
    goto spine_State$partitionswitchParser$parse_op;

    spine_State$partitionswitchParser$parse_udp_srcport$DEFAULT:
    assume(!(band.bv16(spine_hdr.udp_hdr.srcPort, 65408bv16) == band.bv16(1152bv16, 65408bv16))&&!(band.bv16(spine_hdr.udp_hdr.srcPort, 65408bv16) == band.bv16(4224bv16, 65408bv16))&&!(spine_hdr.udp_hdr.srcPort == 5009bv16));
    goto spine_State$accept;

        spine_State$partitionswitchParser$parse_op:
    call spine_packet_in.extract(spine_hdr.op_hdr);
    goto spine_State$partitionswitchParser$parse_op$parse_clone_8, spine_State$partitionswitchParser$parse_op$parse_frequency_7, spine_State$partitionswitchParser$parse_op$parse_fraginfo_6, spine_State$partitionswitchParser$parse_op$parse_vallen_5, spine_State$partitionswitchParser$parse_op$parse_shadowtype_4, spine_State$partitionswitchParser$parse_op$parse_shadowtype_3, spine_State$partitionswitchParser$parse_op$parse_shadowtype_2, spine_State$partitionswitchParser$parse_op$DEFAULT;
    
spine_State$partitionswitchParser$parse_op$parse_clone_8:
    assume (spine_hdr.op_hdr.optype == 288bv16);
    goto spine_State$partitionswitchParser$parse_clone;
    
spine_State$partitionswitchParser$parse_op$parse_frequency_7:
    assume (spine_hdr.op_hdr.optype == 256bv16);
    goto spine_State$partitionswitchParser$parse_frequency;
    
spine_State$partitionswitchParser$parse_op$parse_fraginfo_6:
    assume (spine_hdr.op_hdr.optype == 720bv16);
    goto spine_State$partitionswitchParser$parse_fraginfo;
    
spine_State$partitionswitchParser$parse_op$parse_vallen_5:
    assume (band.bv16(spine_hdr.op_hdr.optype, 1bv16) == band.bv16(1bv16, 1bv16));
    goto spine_State$partitionswitchParser$parse_vallen;
    
spine_State$partitionswitchParser$parse_op$parse_shadowtype_4:
    assume (band.bv16(spine_hdr.op_hdr.optype, 2bv16) == band.bv16(2bv16, 2bv16));
    goto spine_State$partitionswitchParser$parse_shadowtype;
    
spine_State$partitionswitchParser$parse_op$parse_shadowtype_3:
    assume (band.bv16(spine_hdr.op_hdr.optype, 4bv16) == band.bv16(4bv16, 4bv16));
    goto spine_State$partitionswitchParser$parse_shadowtype;
    
spine_State$partitionswitchParser$parse_op$parse_shadowtype_2:
    assume (band.bv16(spine_hdr.op_hdr.optype, 8bv16) == band.bv16(8bv16, 8bv16));
    goto spine_State$partitionswitchParser$parse_shadowtype;

    spine_State$partitionswitchParser$parse_op$DEFAULT:
    assume(!(spine_hdr.op_hdr.optype == 288bv16)&&!(spine_hdr.op_hdr.optype == 256bv16)&&!(spine_hdr.op_hdr.optype == 720bv16)&&!(band.bv16(spine_hdr.op_hdr.optype, 1bv16) == band.bv16(1bv16, 1bv16))&&!(band.bv16(spine_hdr.op_hdr.optype, 2bv16) == band.bv16(2bv16, 2bv16))&&!(band.bv16(spine_hdr.op_hdr.optype, 4bv16) == band.bv16(4bv16, 4bv16))&&!(band.bv16(spine_hdr.op_hdr.optype, 8bv16) == band.bv16(8bv16, 8bv16)));
    goto spine_State$accept;

        spine_State$partitionswitchParser$parse_vallen:
    call spine_packet_in.extract(spine_hdr.vallen_hdr);
    goto spine_State$partitionswitchParser$parse_vallen$parse_shadowtype_34, spine_State$partitionswitchParser$parse_vallen$parse_val_len1_33, spine_State$partitionswitchParser$parse_vallen$parse_val_len1_32, spine_State$partitionswitchParser$parse_vallen$parse_val_len2_31, spine_State$partitionswitchParser$parse_vallen$parse_val_len2_30, spine_State$partitionswitchParser$parse_vallen$parse_val_len3_29, spine_State$partitionswitchParser$parse_vallen$parse_val_len3_28, spine_State$partitionswitchParser$parse_vallen$parse_val_len4_27, spine_State$partitionswitchParser$parse_vallen$parse_val_len4_26, spine_State$partitionswitchParser$parse_vallen$parse_val_len5_25, spine_State$partitionswitchParser$parse_vallen$parse_val_len5_24, spine_State$partitionswitchParser$parse_vallen$parse_val_len6_23, spine_State$partitionswitchParser$parse_vallen$parse_val_len6_22, spine_State$partitionswitchParser$parse_vallen$parse_val_len7_21, spine_State$partitionswitchParser$parse_vallen$parse_val_len7_20, spine_State$partitionswitchParser$parse_vallen$parse_val_len8_19, spine_State$partitionswitchParser$parse_vallen$parse_val_len8_18, spine_State$partitionswitchParser$parse_vallen$parse_val_len9_17, spine_State$partitionswitchParser$parse_vallen$parse_val_len9_16, spine_State$partitionswitchParser$parse_vallen$parse_val_len10_15, spine_State$partitionswitchParser$parse_vallen$parse_val_len10_14, spine_State$partitionswitchParser$parse_vallen$parse_val_len11_13, spine_State$partitionswitchParser$parse_vallen$parse_val_len11_12, spine_State$partitionswitchParser$parse_vallen$parse_val_len12_11, spine_State$partitionswitchParser$parse_vallen$parse_val_len12_10, spine_State$partitionswitchParser$parse_vallen$parse_val_len13_9, spine_State$partitionswitchParser$parse_vallen$parse_val_len13_8, spine_State$partitionswitchParser$parse_vallen$parse_val_len14_7, spine_State$partitionswitchParser$parse_vallen$parse_val_len14_6, spine_State$partitionswitchParser$parse_vallen$parse_val_len15_5, spine_State$partitionswitchParser$parse_vallen$parse_val_len15_4, spine_State$partitionswitchParser$parse_vallen$parse_val_len16_3, spine_State$partitionswitchParser$parse_vallen$parse_val_len16_2, spine_State$partitionswitchParser$parse_vallen$DEFAULT;
    
spine_State$partitionswitchParser$parse_vallen$parse_shadowtype_34:
    assume (spine_hdr.vallen_hdr.vallen == 0bv16);
    goto spine_State$partitionswitchParser$parse_shadowtype;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len1_33:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(0bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len1;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len1_32:
    assume (spine_hdr.vallen_hdr.vallen == 8bv16);
    goto spine_State$partitionswitchParser$parse_val_len1;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len2_31:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(8bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len2;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len2_30:
    assume (spine_hdr.vallen_hdr.vallen == 16bv16);
    goto spine_State$partitionswitchParser$parse_val_len2;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len3_29:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(16bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len3;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len3_28:
    assume (spine_hdr.vallen_hdr.vallen == 24bv16);
    goto spine_State$partitionswitchParser$parse_val_len3;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len4_27:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(24bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len4;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len4_26:
    assume (spine_hdr.vallen_hdr.vallen == 32bv16);
    goto spine_State$partitionswitchParser$parse_val_len4;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len5_25:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(32bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len5;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len5_24:
    assume (spine_hdr.vallen_hdr.vallen == 40bv16);
    goto spine_State$partitionswitchParser$parse_val_len5;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len6_23:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(40bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len6;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len6_22:
    assume (spine_hdr.vallen_hdr.vallen == 48bv16);
    goto spine_State$partitionswitchParser$parse_val_len6;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len7_21:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(48bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len7;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len7_20:
    assume (spine_hdr.vallen_hdr.vallen == 56bv16);
    goto spine_State$partitionswitchParser$parse_val_len7;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len8_19:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(56bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len8;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len8_18:
    assume (spine_hdr.vallen_hdr.vallen == 64bv16);
    goto spine_State$partitionswitchParser$parse_val_len8;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len9_17:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(64bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len9;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len9_16:
    assume (spine_hdr.vallen_hdr.vallen == 72bv16);
    goto spine_State$partitionswitchParser$parse_val_len9;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len10_15:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(72bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len10;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len10_14:
    assume (spine_hdr.vallen_hdr.vallen == 80bv16);
    goto spine_State$partitionswitchParser$parse_val_len10;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len11_13:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(80bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len11;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len11_12:
    assume (spine_hdr.vallen_hdr.vallen == 88bv16);
    goto spine_State$partitionswitchParser$parse_val_len11;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len12_11:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(88bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len12;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len12_10:
    assume (spine_hdr.vallen_hdr.vallen == 96bv16);
    goto spine_State$partitionswitchParser$parse_val_len12;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len13_9:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(96bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len13;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len13_8:
    assume (spine_hdr.vallen_hdr.vallen == 104bv16);
    goto spine_State$partitionswitchParser$parse_val_len13;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len14_7:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(104bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len14;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len14_6:
    assume (spine_hdr.vallen_hdr.vallen == 112bv16);
    goto spine_State$partitionswitchParser$parse_val_len14;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len15_5:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(112bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len15;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len15_4:
    assume (spine_hdr.vallen_hdr.vallen == 120bv16);
    goto spine_State$partitionswitchParser$parse_val_len15;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len16_3:
    assume (band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(120bv16, 65528bv16));
    goto spine_State$partitionswitchParser$parse_val_len16;
    
spine_State$partitionswitchParser$parse_vallen$parse_val_len16_2:
    assume (spine_hdr.vallen_hdr.vallen == 128bv16);
    goto spine_State$partitionswitchParser$parse_val_len16;

    spine_State$partitionswitchParser$parse_vallen$DEFAULT:
    assume(!(spine_hdr.vallen_hdr.vallen == 0bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(0bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 8bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(8bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 16bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(16bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 24bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(24bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 32bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(32bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 40bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(40bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 48bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(48bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 56bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(56bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 64bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(64bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 72bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(72bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 80bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(80bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 88bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(88bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 96bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(96bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 104bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(104bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 112bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(112bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 120bv16)&&!(band.bv16(spine_hdr.vallen_hdr.vallen, 65528bv16) == band.bv16(120bv16, 65528bv16))&&!(spine_hdr.vallen_hdr.vallen == 128bv16));
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len1:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len2:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    call spine_packet_in.extract(spine_hdr.val2_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len3:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    call spine_packet_in.extract(spine_hdr.val2_hdr);
    call spine_packet_in.extract(spine_hdr.val3_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len4:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    call spine_packet_in.extract(spine_hdr.val2_hdr);
    call spine_packet_in.extract(spine_hdr.val3_hdr);
    call spine_packet_in.extract(spine_hdr.val4_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len5:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    call spine_packet_in.extract(spine_hdr.val2_hdr);
    call spine_packet_in.extract(spine_hdr.val3_hdr);
    call spine_packet_in.extract(spine_hdr.val4_hdr);
    call spine_packet_in.extract(spine_hdr.val5_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len6:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    call spine_packet_in.extract(spine_hdr.val2_hdr);
    call spine_packet_in.extract(spine_hdr.val3_hdr);
    call spine_packet_in.extract(spine_hdr.val4_hdr);
    call spine_packet_in.extract(spine_hdr.val5_hdr);
    call spine_packet_in.extract(spine_hdr.val6_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len7:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    call spine_packet_in.extract(spine_hdr.val2_hdr);
    call spine_packet_in.extract(spine_hdr.val3_hdr);
    call spine_packet_in.extract(spine_hdr.val4_hdr);
    call spine_packet_in.extract(spine_hdr.val5_hdr);
    call spine_packet_in.extract(spine_hdr.val6_hdr);
    call spine_packet_in.extract(spine_hdr.val7_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len8:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    call spine_packet_in.extract(spine_hdr.val2_hdr);
    call spine_packet_in.extract(spine_hdr.val3_hdr);
    call spine_packet_in.extract(spine_hdr.val4_hdr);
    call spine_packet_in.extract(spine_hdr.val5_hdr);
    call spine_packet_in.extract(spine_hdr.val6_hdr);
    call spine_packet_in.extract(spine_hdr.val7_hdr);
    call spine_packet_in.extract(spine_hdr.val8_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len9:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    call spine_packet_in.extract(spine_hdr.val2_hdr);
    call spine_packet_in.extract(spine_hdr.val3_hdr);
    call spine_packet_in.extract(spine_hdr.val4_hdr);
    call spine_packet_in.extract(spine_hdr.val5_hdr);
    call spine_packet_in.extract(spine_hdr.val6_hdr);
    call spine_packet_in.extract(spine_hdr.val7_hdr);
    call spine_packet_in.extract(spine_hdr.val8_hdr);
    call spine_packet_in.extract(spine_hdr.val9_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len10:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    call spine_packet_in.extract(spine_hdr.val2_hdr);
    call spine_packet_in.extract(spine_hdr.val3_hdr);
    call spine_packet_in.extract(spine_hdr.val4_hdr);
    call spine_packet_in.extract(spine_hdr.val5_hdr);
    call spine_packet_in.extract(spine_hdr.val6_hdr);
    call spine_packet_in.extract(spine_hdr.val7_hdr);
    call spine_packet_in.extract(spine_hdr.val8_hdr);
    call spine_packet_in.extract(spine_hdr.val9_hdr);
    call spine_packet_in.extract(spine_hdr.val10_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len11:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    call spine_packet_in.extract(spine_hdr.val2_hdr);
    call spine_packet_in.extract(spine_hdr.val3_hdr);
    call spine_packet_in.extract(spine_hdr.val4_hdr);
    call spine_packet_in.extract(spine_hdr.val5_hdr);
    call spine_packet_in.extract(spine_hdr.val6_hdr);
    call spine_packet_in.extract(spine_hdr.val7_hdr);
    call spine_packet_in.extract(spine_hdr.val8_hdr);
    call spine_packet_in.extract(spine_hdr.val9_hdr);
    call spine_packet_in.extract(spine_hdr.val10_hdr);
    call spine_packet_in.extract(spine_hdr.val11_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len12:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    call spine_packet_in.extract(spine_hdr.val2_hdr);
    call spine_packet_in.extract(spine_hdr.val3_hdr);
    call spine_packet_in.extract(spine_hdr.val4_hdr);
    call spine_packet_in.extract(spine_hdr.val5_hdr);
    call spine_packet_in.extract(spine_hdr.val6_hdr);
    call spine_packet_in.extract(spine_hdr.val7_hdr);
    call spine_packet_in.extract(spine_hdr.val8_hdr);
    call spine_packet_in.extract(spine_hdr.val9_hdr);
    call spine_packet_in.extract(spine_hdr.val10_hdr);
    call spine_packet_in.extract(spine_hdr.val11_hdr);
    call spine_packet_in.extract(spine_hdr.val12_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len13:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    call spine_packet_in.extract(spine_hdr.val2_hdr);
    call spine_packet_in.extract(spine_hdr.val3_hdr);
    call spine_packet_in.extract(spine_hdr.val4_hdr);
    call spine_packet_in.extract(spine_hdr.val5_hdr);
    call spine_packet_in.extract(spine_hdr.val6_hdr);
    call spine_packet_in.extract(spine_hdr.val7_hdr);
    call spine_packet_in.extract(spine_hdr.val8_hdr);
    call spine_packet_in.extract(spine_hdr.val9_hdr);
    call spine_packet_in.extract(spine_hdr.val10_hdr);
    call spine_packet_in.extract(spine_hdr.val11_hdr);
    call spine_packet_in.extract(spine_hdr.val12_hdr);
    call spine_packet_in.extract(spine_hdr.val13_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len14:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    call spine_packet_in.extract(spine_hdr.val2_hdr);
    call spine_packet_in.extract(spine_hdr.val3_hdr);
    call spine_packet_in.extract(spine_hdr.val4_hdr);
    call spine_packet_in.extract(spine_hdr.val5_hdr);
    call spine_packet_in.extract(spine_hdr.val6_hdr);
    call spine_packet_in.extract(spine_hdr.val7_hdr);
    call spine_packet_in.extract(spine_hdr.val8_hdr);
    call spine_packet_in.extract(spine_hdr.val9_hdr);
    call spine_packet_in.extract(spine_hdr.val10_hdr);
    call spine_packet_in.extract(spine_hdr.val11_hdr);
    call spine_packet_in.extract(spine_hdr.val12_hdr);
    call spine_packet_in.extract(spine_hdr.val13_hdr);
    call spine_packet_in.extract(spine_hdr.val14_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len15:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    call spine_packet_in.extract(spine_hdr.val2_hdr);
    call spine_packet_in.extract(spine_hdr.val3_hdr);
    call spine_packet_in.extract(spine_hdr.val4_hdr);
    call spine_packet_in.extract(spine_hdr.val5_hdr);
    call spine_packet_in.extract(spine_hdr.val6_hdr);
    call spine_packet_in.extract(spine_hdr.val7_hdr);
    call spine_packet_in.extract(spine_hdr.val8_hdr);
    call spine_packet_in.extract(spine_hdr.val9_hdr);
    call spine_packet_in.extract(spine_hdr.val10_hdr);
    call spine_packet_in.extract(spine_hdr.val11_hdr);
    call spine_packet_in.extract(spine_hdr.val12_hdr);
    call spine_packet_in.extract(spine_hdr.val13_hdr);
    call spine_packet_in.extract(spine_hdr.val14_hdr);
    call spine_packet_in.extract(spine_hdr.val15_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_val_len16:
    call spine_packet_in.extract(spine_hdr.val1_hdr);
    call spine_packet_in.extract(spine_hdr.val2_hdr);
    call spine_packet_in.extract(spine_hdr.val3_hdr);
    call spine_packet_in.extract(spine_hdr.val4_hdr);
    call spine_packet_in.extract(spine_hdr.val5_hdr);
    call spine_packet_in.extract(spine_hdr.val6_hdr);
    call spine_packet_in.extract(spine_hdr.val7_hdr);
    call spine_packet_in.extract(spine_hdr.val8_hdr);
    call spine_packet_in.extract(spine_hdr.val9_hdr);
    call spine_packet_in.extract(spine_hdr.val10_hdr);
    call spine_packet_in.extract(spine_hdr.val11_hdr);
    call spine_packet_in.extract(spine_hdr.val12_hdr);
    call spine_packet_in.extract(spine_hdr.val13_hdr);
    call spine_packet_in.extract(spine_hdr.val14_hdr);
    call spine_packet_in.extract(spine_hdr.val15_hdr);
    call spine_packet_in.extract(spine_hdr.val16_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype;

        spine_State$partitionswitchParser$parse_shadowtype:
    call spine_packet_in.extract(spine_hdr.shadowtype_hdr);
    goto spine_State$partitionswitchParser$parse_shadowtype$parse_seq_4, spine_State$partitionswitchParser$parse_shadowtype$parse_inswitch_3, spine_State$partitionswitchParser$parse_shadowtype$parse_stat_2, spine_State$partitionswitchParser$parse_shadowtype$DEFAULT;
    
spine_State$partitionswitchParser$parse_shadowtype$parse_seq_4:
    assume (band.bv16(spine_hdr.shadowtype_hdr.shadowtype, 2bv16) == band.bv16(2bv16, 2bv16));
    goto spine_State$partitionswitchParser$parse_seq;
    
spine_State$partitionswitchParser$parse_shadowtype$parse_inswitch_3:
    assume (band.bv16(spine_hdr.shadowtype_hdr.shadowtype, 4bv16) == band.bv16(4bv16, 4bv16));
    goto spine_State$partitionswitchParser$parse_inswitch;
    
spine_State$partitionswitchParser$parse_shadowtype$parse_stat_2:
    assume (band.bv16(spine_hdr.shadowtype_hdr.shadowtype, 8bv16) == band.bv16(8bv16, 8bv16));
    goto spine_State$partitionswitchParser$parse_stat;

    spine_State$partitionswitchParser$parse_shadowtype$DEFAULT:
    assume(!(band.bv16(spine_hdr.shadowtype_hdr.shadowtype, 2bv16) == band.bv16(2bv16, 2bv16))&&!(band.bv16(spine_hdr.shadowtype_hdr.shadowtype, 4bv16) == band.bv16(4bv16, 4bv16))&&!(band.bv16(spine_hdr.shadowtype_hdr.shadowtype, 8bv16) == band.bv16(8bv16, 8bv16)));
    goto spine_State$accept;

        spine_State$partitionswitchParser$parse_seq:
    call spine_packet_in.extract(spine_hdr.seq_hdr);
    goto spine_State$partitionswitchParser$parse_seq$parse_fraginfo_6, spine_State$partitionswitchParser$parse_seq$parse_fraginfo_5, spine_State$partitionswitchParser$parse_seq$parse_fraginfo_4, spine_State$partitionswitchParser$parse_seq$parse_inswitch_3, spine_State$partitionswitchParser$parse_seq$parse_stat_2, spine_State$partitionswitchParser$parse_seq$DEFAULT;
    
spine_State$partitionswitchParser$parse_seq$parse_fraginfo_6:
    assume (spine_hdr.shadowtype_hdr.shadowtype == 50bv16);
    goto spine_State$partitionswitchParser$parse_fraginfo;
    
spine_State$partitionswitchParser$parse_seq$parse_fraginfo_5:
    assume (spine_hdr.shadowtype_hdr.shadowtype == 66bv16);
    goto spine_State$partitionswitchParser$parse_fraginfo;
    
spine_State$partitionswitchParser$parse_seq$parse_fraginfo_4:
    assume (spine_hdr.shadowtype_hdr.shadowtype == 82bv16);
    goto spine_State$partitionswitchParser$parse_fraginfo;
    
spine_State$partitionswitchParser$parse_seq$parse_inswitch_3:
    assume (band.bv16(spine_hdr.shadowtype_hdr.shadowtype, 4bv16) == band.bv16(4bv16, 4bv16));
    goto spine_State$partitionswitchParser$parse_inswitch;
    
spine_State$partitionswitchParser$parse_seq$parse_stat_2:
    assume (band.bv16(spine_hdr.shadowtype_hdr.shadowtype, 8bv16) == band.bv16(8bv16, 8bv16));
    goto spine_State$partitionswitchParser$parse_stat;

    spine_State$partitionswitchParser$parse_seq$DEFAULT:
    assume(!(spine_hdr.shadowtype_hdr.shadowtype == 50bv16)&&!(spine_hdr.shadowtype_hdr.shadowtype == 66bv16)&&!(spine_hdr.shadowtype_hdr.shadowtype == 82bv16)&&!(band.bv16(spine_hdr.shadowtype_hdr.shadowtype, 4bv16) == band.bv16(4bv16, 4bv16))&&!(band.bv16(spine_hdr.shadowtype_hdr.shadowtype, 8bv16) == band.bv16(8bv16, 8bv16)));
    goto spine_State$accept;

        spine_State$partitionswitchParser$parse_inswitch:
    call spine_packet_in.extract(spine_hdr.inswitch_hdr);
    goto spine_State$partitionswitchParser$parse_inswitch$parse_clone_5, spine_State$partitionswitchParser$parse_inswitch$parse_fraginfo_4, spine_State$partitionswitchParser$parse_inswitch$parse_fraginfo_3, spine_State$partitionswitchParser$parse_inswitch$parse_stat_2, spine_State$partitionswitchParser$parse_inswitch$DEFAULT;
    
spine_State$partitionswitchParser$parse_inswitch$parse_clone_5:
    assume (spine_hdr.shadowtype_hdr.shadowtype == 116bv16);
    goto spine_State$partitionswitchParser$parse_clone;
    
spine_State$partitionswitchParser$parse_inswitch$parse_fraginfo_4:
    assume (spine_hdr.shadowtype_hdr.shadowtype == 164bv16);
    goto spine_State$partitionswitchParser$parse_fraginfo;
    
spine_State$partitionswitchParser$parse_inswitch$parse_fraginfo_3:
    assume (spine_hdr.shadowtype_hdr.shadowtype == 22bv16);
    goto spine_State$partitionswitchParser$parse_fraginfo;
    
spine_State$partitionswitchParser$parse_inswitch$parse_stat_2:
    assume (band.bv16(spine_hdr.shadowtype_hdr.shadowtype, 8bv16) == band.bv16(8bv16, 8bv16));
    goto spine_State$partitionswitchParser$parse_stat;

    spine_State$partitionswitchParser$parse_inswitch$DEFAULT:
    assume(!(spine_hdr.shadowtype_hdr.shadowtype == 116bv16)&&!(spine_hdr.shadowtype_hdr.shadowtype == 164bv16)&&!(spine_hdr.shadowtype_hdr.shadowtype == 22bv16)&&!(band.bv16(spine_hdr.shadowtype_hdr.shadowtype, 8bv16) == band.bv16(8bv16, 8bv16)));
    goto spine_State$accept;

        spine_State$partitionswitchParser$parse_stat:
    call spine_packet_in.extract(spine_hdr.stat_hdr);
    goto spine_State$partitionswitchParser$parse_stat$parse_clone_5, spine_State$partitionswitchParser$parse_stat$parse_clone_4, spine_State$partitionswitchParser$parse_stat$parse_clone_3, spine_State$partitionswitchParser$parse_stat$parse_clone_2, spine_State$partitionswitchParser$parse_stat$DEFAULT;
    
spine_State$partitionswitchParser$parse_stat$parse_clone_5:
    assume (spine_hdr.shadowtype_hdr.shadowtype == 47bv16);
    goto spine_State$partitionswitchParser$parse_clone;
    
spine_State$partitionswitchParser$parse_stat$parse_clone_4:
    assume (spine_hdr.shadowtype_hdr.shadowtype == 63bv16);
    goto spine_State$partitionswitchParser$parse_clone;
    
spine_State$partitionswitchParser$parse_stat$parse_clone_3:
    assume (spine_hdr.shadowtype_hdr.shadowtype == 79bv16);
    goto spine_State$partitionswitchParser$parse_clone;
    
spine_State$partitionswitchParser$parse_stat$parse_clone_2:
    assume (spine_hdr.shadowtype_hdr.shadowtype == 95bv16);
    goto spine_State$partitionswitchParser$parse_clone;

    spine_State$partitionswitchParser$parse_stat$DEFAULT:
    assume(!(spine_hdr.shadowtype_hdr.shadowtype == 47bv16)&&!(spine_hdr.shadowtype_hdr.shadowtype == 63bv16)&&!(spine_hdr.shadowtype_hdr.shadowtype == 79bv16)&&!(spine_hdr.shadowtype_hdr.shadowtype == 95bv16));
    goto spine_State$accept;

        spine_State$partitionswitchParser$parse_clone:
    call spine_packet_in.extract(spine_hdr.clone_hdr);
    goto spine_State$accept;

        spine_State$partitionswitchParser$parse_frequency:
    call spine_packet_in.extract(spine_hdr.frequency_hdr);
    goto spine_State$accept;

        spine_State$partitionswitchParser$parse_fraginfo:
    call spine_packet_in.extract(spine_hdr.fraginfo_hdr);
    goto spine_State$accept;

    spine_State$accept:
    call spine_accept();
    goto spine_Exit;

    spine_State$reject:
    call spine_reject();
    goto spine_Exit;

    spine_Exit:
}

// spine_Control spine_partitionswitchVerifyChecksum
procedure {:inline 1} spine_partitionswitchVerifyChecksum()
{
}
procedure spine_reject();
    ensures spine_drop==true;
	modifies spine_drop;
procedure {:inline 1} spine_setInvalid(spine_header:spine_Ref);
    ensures (spine_isValid[spine_header] == false);
	modifies spine_isValid;
procedure {:inline 1} spine_setValid(spine_header:spine_Ref);
// ===== END NODE spine =====

// ===== BEGIN ENQUEUE PROCEDURES =====
// ===== END ENQUEUE PROCEDURES =====

// ===== BEGIN HARNESS =====
// Auto-generated by Procurator (DSL -> Boogie harness: sequential scheduler)
// Message abstraction: Bag(K=1) using inbox_count per node; single-slot mailbox for packet fields

var procurator_step: int;
var procurator_bad: bool;

// Register debug snapshots (for trace inspection)
var spine_partitionswitchEgress_cache_frequency_reg__dbg0: bv32;
var spine_partitionswitchEgress_cache_frequency_reg__last_index__dbg: bv32;
var spine_partitionswitchEgress_cache_frequency_reg__last_value__dbg: bv32;
var spine_partitionswitchEgress_cache_frequency_reg__last_old_value__dbg: bv32;
var spine_partitionswitchEgress_cache_frequency_reg__wrote_any__dbg: bool;
var spine_partitionswitchEgress_cache_frequency_reg__wrote_index0__dbg: bool;
var spine_partitionswitchEgress_cache_frequency_reg__last0_old_value__dbg: bv32;
var spine_partitionswitchEgress_cache_frequency_reg__last0_value__dbg: bv32;
var spine_partitionswitchEgress_deleted_reg__dbg0: bv1;
var spine_partitionswitchEgress_deleted_reg__last_index__dbg: bv32;
var spine_partitionswitchEgress_deleted_reg__last_value__dbg: bv1;
var spine_partitionswitchEgress_deleted_reg__last_old_value__dbg: bv1;
var spine_partitionswitchEgress_deleted_reg__wrote_any__dbg: bool;
var spine_partitionswitchEgress_deleted_reg__wrote_index0__dbg: bool;
var spine_partitionswitchEgress_deleted_reg__last0_old_value__dbg: bv1;
var spine_partitionswitchEgress_deleted_reg__last0_value__dbg: bv1;
var spine_partitionswitchEgress_vallen_reg__dbg0: bv16;
var spine_partitionswitchEgress_vallen_reg__last_index__dbg: bv32;
var spine_partitionswitchEgress_vallen_reg__last_value__dbg: bv16;
var spine_partitionswitchEgress_vallen_reg__last_old_value__dbg: bv16;
var spine_partitionswitchEgress_vallen_reg__wrote_any__dbg: bool;
var spine_partitionswitchEgress_vallen_reg__wrote_index0__dbg: bool;
var spine_partitionswitchEgress_vallen_reg__last0_old_value__dbg: bv16;
var spine_partitionswitchEgress_vallen_reg__last0_value__dbg: bv16;

var spine_inbox_count: int;

var spine_pkt_external: bool;

// Forwarding (derived from DSL topology)
procedure spine_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (spine_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure mainProcedure() returns()
  modifies procurator_bad, procurator_step, spine_cache_frequency_res_0, spine_drop, spine_hdr.ethernet_hdr.etherType, spine_hdr.ethernet_hdr.valid, spine_hdr.inswitch_hdr.idx, spine_hdr.ipv4_hdr.protocol, spine_hdr.ipv4_hdr.valid, spine_hdr.op_hdr.keyhihihi, spine_hdr.op_hdr.keyhihilo, spine_hdr.op_hdr.keyhilo, spine_hdr.op_hdr.keylohi, spine_hdr.op_hdr.keylolo, spine_hdr.op_hdr.optype, spine_hdr.op_hdr.valid, spine_hdr.shadowtype_hdr.shadowtype, spine_hdr.udp_hdr.checksum, spine_hdr.udp_hdr.dstPort, spine_hdr.udp_hdr.srcPort, spine_hdr.udp_hdr.valid, spine_hdr.vallen_hdr.vallen, spine_hdr_eg.inswitch_hdr.idx, spine_hdr_eg.op_hdr.optype, spine_hdr_eg.vallen_hdr.vallen, spine_inbox_count, spine_isValid, spine_meta.idx, spine_meta.is_cached, spine_meta.is_deleted, spine_meta.is_spine, spine_p4b_checksum_error, spine_p4b_checksum_updated, spine_p4b_checksum_verified, spine_p4b_clone_e2e, spine_p4b_clone_i2e, spine_p4b_clone_i2i, spine_p4b_digest, spine_p4b_recirculate, spine_partitionswitchEgress_access_cache_frequency_tbl.action_run, spine_partitionswitchEgress_access_cache_frequency_tbl.hit, spine_partitionswitchEgress_access_deleted_tbl.action_run, spine_partitionswitchEgress_access_deleted_tbl.hit, spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run, spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit, spine_partitionswitchEgress_cache_frequency_reg, spine_partitionswitchEgress_cache_frequency_reg__dbg0, spine_partitionswitchEgress_cache_frequency_reg__last0_old_value, spine_partitionswitchEgress_cache_frequency_reg__last0_old_value__dbg, spine_partitionswitchEgress_cache_frequency_reg__last0_value, spine_partitionswitchEgress_cache_frequency_reg__last0_value__dbg, spine_partitionswitchEgress_cache_frequency_reg__last_index, spine_partitionswitchEgress_cache_frequency_reg__last_index__dbg, spine_partitionswitchEgress_cache_frequency_reg__last_old_value, spine_partitionswitchEgress_cache_frequency_reg__last_old_value__dbg, spine_partitionswitchEgress_cache_frequency_reg__last_value, spine_partitionswitchEgress_cache_frequency_reg__last_value__dbg, spine_partitionswitchEgress_cache_frequency_reg__last_write_site, spine_partitionswitchEgress_cache_frequency_reg__next_write_site, spine_partitionswitchEgress_cache_frequency_reg__wrote_any, spine_partitionswitchEgress_cache_frequency_reg__wrote_any__dbg, spine_partitionswitchEgress_cache_frequency_reg__wrote_index0, spine_partitionswitchEgress_cache_frequency_reg__wrote_index0__dbg, spine_partitionswitchEgress_deleted_reg, spine_partitionswitchEgress_deleted_reg__dbg0, spine_partitionswitchEgress_deleted_reg__last0_old_value, spine_partitionswitchEgress_deleted_reg__last0_old_value__dbg, spine_partitionswitchEgress_deleted_reg__last0_value, spine_partitionswitchEgress_deleted_reg__last0_value__dbg, spine_partitionswitchEgress_deleted_reg__last_index, spine_partitionswitchEgress_deleted_reg__last_index__dbg, spine_partitionswitchEgress_deleted_reg__last_old_value, spine_partitionswitchEgress_deleted_reg__last_old_value__dbg, spine_partitionswitchEgress_deleted_reg__last_value, spine_partitionswitchEgress_deleted_reg__last_value__dbg, spine_partitionswitchEgress_deleted_reg__last_write_site, spine_partitionswitchEgress_deleted_reg__next_write_site, spine_partitionswitchEgress_deleted_reg__wrote_any, spine_partitionswitchEgress_deleted_reg__wrote_any__dbg, spine_partitionswitchEgress_deleted_reg__wrote_index0, spine_partitionswitchEgress_deleted_reg__wrote_index0__dbg, spine_partitionswitchEgress_eg_port_forward_tbl.action_run, spine_partitionswitchEgress_eg_port_forward_tbl.hit, spine_partitionswitchEgress_eg_port_forward_tbl.partitionswitchEgress_update_netcache_getreq_spine_to_getres_by_mirroring.stat_1, spine_partitionswitchEgress_update_pktlen_tbl.action_run, spine_partitionswitchEgress_update_pktlen_tbl.hit, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_vallen_tbl.action_run, spine_partitionswitchEgress_update_vallen_tbl.hit, spine_partitionswitchEgress_vallen_reg, spine_partitionswitchEgress_vallen_reg__dbg0, spine_partitionswitchEgress_vallen_reg__last0_old_value, spine_partitionswitchEgress_vallen_reg__last0_old_value__dbg, spine_partitionswitchEgress_vallen_reg__last0_value, spine_partitionswitchEgress_vallen_reg__last0_value__dbg, spine_partitionswitchEgress_vallen_reg__last_index, spine_partitionswitchEgress_vallen_reg__last_index__dbg, spine_partitionswitchEgress_vallen_reg__last_old_value, spine_partitionswitchEgress_vallen_reg__last_old_value__dbg, spine_partitionswitchEgress_vallen_reg__last_value, spine_partitionswitchEgress_vallen_reg__last_value__dbg, spine_partitionswitchEgress_vallen_reg__last_write_site, spine_partitionswitchEgress_vallen_reg__next_write_site, spine_partitionswitchEgress_vallen_reg__wrote_any, spine_partitionswitchEgress_vallen_reg__wrote_any__dbg, spine_partitionswitchEgress_vallen_reg__wrote_index0, spine_partitionswitchEgress_vallen_reg__wrote_index0__dbg, spine_partitionswitchIngress_cache_lookup_tbl.action_run, spine_partitionswitchIngress_cache_lookup_tbl.hit, spine_partitionswitchIngress_cache_lookup_tbl.partitionswitchIngress_cached_action.idx_1, spine_partitionswitchIngress_set_spine_tbl.action_run, spine_partitionswitchIngress_set_spine_tbl.hit, spine_pkt_external;
{
  // initialize inboxes
  spine_inbox_count := 0;
  spine_pkt_external := false;
  // initialize P4B event flags (clone/recirculate)
  spine_p4b_clone_i2e := false;
  spine_p4b_clone_e2e := false;
  spine_p4b_clone_i2i := false;
  spine_p4b_recirculate := false;

  // initialize P4 registers (default 0)
  assume (forall i:bv32 :: spine_partitionswitchEgress_cache_frequency_reg[i] == 0bv32);
  assume spine_partitionswitchEgress_cache_frequency_reg[0bv32] == 0bv32;
  assume (forall i:bv32 :: spine_partitionswitchEgress_deleted_reg[i] == 0bv1);
  assume spine_partitionswitchEgress_deleted_reg[0bv32] == 0bv1;
  assume (forall i:bv32 :: spine_partitionswitchEgress_vallen_reg[i] == 0bv16);
  assume spine_partitionswitchEgress_vallen_reg[0bv32] == 0bv16;
  // initialize register write tracking (debug)
  spine_partitionswitchEgress_cache_frequency_reg__last_index := 0bv32;
  spine_partitionswitchEgress_cache_frequency_reg__last_value := 0bv32;
  spine_partitionswitchEgress_cache_frequency_reg__last_old_value := 0bv32;
  spine_partitionswitchEgress_cache_frequency_reg__wrote_any := false;
  spine_partitionswitchEgress_cache_frequency_reg__wrote_index0 := false;
  spine_partitionswitchEgress_cache_frequency_reg__next_write_site := 0;
  spine_partitionswitchEgress_cache_frequency_reg__last_write_site := 0;
  spine_partitionswitchEgress_cache_frequency_reg__last0_old_value := 0bv32;
  spine_partitionswitchEgress_cache_frequency_reg__last0_value := 0bv32;
  spine_partitionswitchEgress_deleted_reg__last_index := 0bv32;
  spine_partitionswitchEgress_deleted_reg__last_value := 0bv1;
  spine_partitionswitchEgress_deleted_reg__last_old_value := 0bv1;
  spine_partitionswitchEgress_deleted_reg__wrote_any := false;
  spine_partitionswitchEgress_deleted_reg__wrote_index0 := false;
  spine_partitionswitchEgress_deleted_reg__next_write_site := 0;
  spine_partitionswitchEgress_deleted_reg__last_write_site := 0;
  spine_partitionswitchEgress_deleted_reg__last0_old_value := 0bv1;
  spine_partitionswitchEgress_deleted_reg__last0_value := 0bv1;
  spine_partitionswitchEgress_vallen_reg__last_index := 0bv32;
  spine_partitionswitchEgress_vallen_reg__last_value := 0bv16;
  spine_partitionswitchEgress_vallen_reg__last_old_value := 0bv16;
  spine_partitionswitchEgress_vallen_reg__wrote_any := false;
  spine_partitionswitchEgress_vallen_reg__wrote_index0 := false;
  spine_partitionswitchEgress_vallen_reg__next_write_site := 0;
  spine_partitionswitchEgress_vallen_reg__last_write_site := 0;
  spine_partitionswitchEgress_vallen_reg__last0_old_value := 0bv16;
  spine_partitionswitchEgress_vallen_reg__last0_value := 0bv16;

  procurator_step := 0;
  procurator_bad := false;
  // step 0: env_inject -> spine
  if (spine_inbox_count < 1) {
  assume spine_inbox_count < 1;
  spine_pkt_external := true;
  havoc spine_hdr.ethernet_hdr.valid;
  havoc spine_hdr.ethernet_hdr.etherType;
  havoc spine_hdr.ipv4_hdr.valid;
  havoc spine_hdr.ipv4_hdr.protocol;
  havoc spine_hdr.udp_hdr.valid;
  havoc spine_hdr.udp_hdr.srcPort;
  havoc spine_hdr.udp_hdr.dstPort;
  havoc spine_hdr.udp_hdr.checksum;
  havoc spine_hdr.op_hdr.valid;
  havoc spine_hdr.op_hdr.optype;
  havoc spine_hdr.op_hdr.keylolo;
  havoc spine_hdr.op_hdr.keylohi;
  havoc spine_hdr.op_hdr.keyhilo;
  havoc spine_hdr.op_hdr.keyhihilo;
  havoc spine_hdr.op_hdr.keyhihihi;
  havoc spine_hdr.vallen_hdr.vallen;
  havoc spine_hdr.shadowtype_hdr.shadowtype;
  havoc spine_hdr.inswitch_hdr.idx;
  havoc spine_meta.is_spine;
  havoc spine_meta.is_cached;
  havoc spine_meta.is_deleted;
  havoc spine_meta.idx;
  havoc spine_hdr_eg.op_hdr.optype;
  havoc spine_hdr_eg.vallen_hdr.vallen;
  havoc spine_hdr_eg.inswitch_hdr.idx;
  assume (spine_hdr.ethernet_hdr.valid == true);
  assume (spine_hdr.ipv4_hdr.valid == true);
  assume (spine_hdr.udp_hdr.valid == true);
  assume (spine_hdr.op_hdr.valid == true);
  assume (spine_hdr.ethernet_hdr.etherType == 2048bv16);
  assume (spine_hdr.ipv4_hdr.protocol == 17bv8);
  assume (spine_hdr.udp_hdr.dstPort == 5008bv16);
  assume (spine_hdr.op_hdr.optype == 512bv16);
  assume (spine_hdr.op_hdr.keylolo == 2882338817bv32);
  assume (spine_hdr.op_hdr.keylohi == 0bv32);
  assume (spine_hdr.op_hdr.keyhilo == 0bv32);
  assume (spine_hdr.op_hdr.keyhihilo == 0bv16);
  assume (spine_hdr.op_hdr.keyhihihi == 0bv16);
  assume (spine_hdr.inswitch_hdr.idx == 0bv16);
  assume (spine_partitionswitchEgress_cache_frequency_reg[7bv32] == 0bv32);
  spine_inbox_count := spine_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 1: node_pass -> spine
  if (spine_inbox_count > 0) {
  assume spine_inbox_count > 0;
  spine_inbox_count := spine_inbox_count - 1;
  call spine_mainProcedure();
  if (spine_p4b_clone_i2e) {
    assume spine_inbox_count < 1;
    spine_pkt_external := false;
    spine_inbox_count := spine_inbox_count + 1;
  }
  spine_p4b_clone_i2e := false;
  if (spine_p4b_clone_e2e) {
    assume spine_inbox_count < 1;
    spine_pkt_external := false;
    spine_inbox_count := spine_inbox_count + 1;
  }
  spine_p4b_clone_e2e := false;
  if (spine_p4b_clone_i2i) {
    assume spine_inbox_count < 1;
    spine_pkt_external := false;
    spine_inbox_count := spine_inbox_count + 1;
  }
  spine_p4b_clone_i2i := false;
  if (spine_p4b_recirculate) {
    assume spine_inbox_count < 1;
    spine_pkt_external := false;
    spine_inbox_count := spine_inbox_count + 1;
  }
  spine_p4b_recirculate := false;
  call spine_Forward();
  // Register debug snapshot
  spine_partitionswitchEgress_cache_frequency_reg__dbg0 := spine_partitionswitchEgress_cache_frequency_reg[0bv32];
  spine_partitionswitchEgress_cache_frequency_reg__last_index__dbg := spine_partitionswitchEgress_cache_frequency_reg__last_index;
  spine_partitionswitchEgress_cache_frequency_reg__last_value__dbg := spine_partitionswitchEgress_cache_frequency_reg__last_value;
  spine_partitionswitchEgress_cache_frequency_reg__last_old_value__dbg := spine_partitionswitchEgress_cache_frequency_reg__last_old_value;
  spine_partitionswitchEgress_cache_frequency_reg__wrote_any__dbg := spine_partitionswitchEgress_cache_frequency_reg__wrote_any;
  spine_partitionswitchEgress_cache_frequency_reg__wrote_index0__dbg := spine_partitionswitchEgress_cache_frequency_reg__wrote_index0;
  spine_partitionswitchEgress_cache_frequency_reg__last0_old_value__dbg := spine_partitionswitchEgress_cache_frequency_reg__last0_old_value;
  spine_partitionswitchEgress_cache_frequency_reg__last0_value__dbg := spine_partitionswitchEgress_cache_frequency_reg__last0_value;
  spine_partitionswitchEgress_deleted_reg__dbg0 := spine_partitionswitchEgress_deleted_reg[0bv32];
  spine_partitionswitchEgress_deleted_reg__last_index__dbg := spine_partitionswitchEgress_deleted_reg__last_index;
  spine_partitionswitchEgress_deleted_reg__last_value__dbg := spine_partitionswitchEgress_deleted_reg__last_value;
  spine_partitionswitchEgress_deleted_reg__last_old_value__dbg := spine_partitionswitchEgress_deleted_reg__last_old_value;
  spine_partitionswitchEgress_deleted_reg__wrote_any__dbg := spine_partitionswitchEgress_deleted_reg__wrote_any;
  spine_partitionswitchEgress_deleted_reg__wrote_index0__dbg := spine_partitionswitchEgress_deleted_reg__wrote_index0;
  spine_partitionswitchEgress_deleted_reg__last0_old_value__dbg := spine_partitionswitchEgress_deleted_reg__last0_old_value;
  spine_partitionswitchEgress_deleted_reg__last0_value__dbg := spine_partitionswitchEgress_deleted_reg__last0_value;
  spine_partitionswitchEgress_vallen_reg__dbg0 := spine_partitionswitchEgress_vallen_reg[0bv32];
  spine_partitionswitchEgress_vallen_reg__last_index__dbg := spine_partitionswitchEgress_vallen_reg__last_index;
  spine_partitionswitchEgress_vallen_reg__last_value__dbg := spine_partitionswitchEgress_vallen_reg__last_value;
  spine_partitionswitchEgress_vallen_reg__last_old_value__dbg := spine_partitionswitchEgress_vallen_reg__last_old_value;
  spine_partitionswitchEgress_vallen_reg__wrote_any__dbg := spine_partitionswitchEgress_vallen_reg__wrote_any;
  spine_partitionswitchEgress_vallen_reg__wrote_index0__dbg := spine_partitionswitchEgress_vallen_reg__wrote_index0;
  spine_partitionswitchEgress_vallen_reg__last0_old_value__dbg := spine_partitionswitchEgress_vallen_reg__last0_old_value;
  spine_partitionswitchEgress_vallen_reg__last0_value__dbg := spine_partitionswitchEgress_vallen_reg__last0_value;
  // Global assertions (accumulated into procurator_bad)
  if (!(((spine_meta.is_cached == 0bv1) || (spine_partitionswitchEgress_cache_frequency_reg[7bv32] != 0bv32)))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  assert !procurator_bad;
}


procedure ULTIMATE.start() returns()
  modifies procurator_bad, procurator_step, spine_cache_frequency_res_0, spine_drop, spine_hdr.ethernet_hdr.etherType, spine_hdr.ethernet_hdr.valid, spine_hdr.inswitch_hdr.idx, spine_hdr.ipv4_hdr.protocol, spine_hdr.ipv4_hdr.valid, spine_hdr.op_hdr.keyhihihi, spine_hdr.op_hdr.keyhihilo, spine_hdr.op_hdr.keyhilo, spine_hdr.op_hdr.keylohi, spine_hdr.op_hdr.keylolo, spine_hdr.op_hdr.optype, spine_hdr.op_hdr.valid, spine_hdr.shadowtype_hdr.shadowtype, spine_hdr.udp_hdr.checksum, spine_hdr.udp_hdr.dstPort, spine_hdr.udp_hdr.srcPort, spine_hdr.udp_hdr.valid, spine_hdr.vallen_hdr.vallen, spine_hdr_eg.inswitch_hdr.idx, spine_hdr_eg.op_hdr.optype, spine_hdr_eg.vallen_hdr.vallen, spine_inbox_count, spine_isValid, spine_meta.idx, spine_meta.is_cached, spine_meta.is_deleted, spine_meta.is_spine, spine_p4b_checksum_error, spine_p4b_checksum_updated, spine_p4b_checksum_verified, spine_p4b_clone_e2e, spine_p4b_clone_i2e, spine_p4b_clone_i2i, spine_p4b_digest, spine_p4b_recirculate, spine_partitionswitchEgress_access_cache_frequency_tbl.action_run, spine_partitionswitchEgress_access_cache_frequency_tbl.hit, spine_partitionswitchEgress_access_deleted_tbl.action_run, spine_partitionswitchEgress_access_deleted_tbl.hit, spine_partitionswitchEgress_add_and_remove_value_header_tbl.action_run, spine_partitionswitchEgress_add_and_remove_value_header_tbl.hit, spine_partitionswitchEgress_cache_frequency_reg, spine_partitionswitchEgress_cache_frequency_reg__dbg0, spine_partitionswitchEgress_cache_frequency_reg__last0_old_value, spine_partitionswitchEgress_cache_frequency_reg__last0_old_value__dbg, spine_partitionswitchEgress_cache_frequency_reg__last0_value, spine_partitionswitchEgress_cache_frequency_reg__last0_value__dbg, spine_partitionswitchEgress_cache_frequency_reg__last_index, spine_partitionswitchEgress_cache_frequency_reg__last_index__dbg, spine_partitionswitchEgress_cache_frequency_reg__last_old_value, spine_partitionswitchEgress_cache_frequency_reg__last_old_value__dbg, spine_partitionswitchEgress_cache_frequency_reg__last_value, spine_partitionswitchEgress_cache_frequency_reg__last_value__dbg, spine_partitionswitchEgress_cache_frequency_reg__last_write_site, spine_partitionswitchEgress_cache_frequency_reg__next_write_site, spine_partitionswitchEgress_cache_frequency_reg__wrote_any, spine_partitionswitchEgress_cache_frequency_reg__wrote_any__dbg, spine_partitionswitchEgress_cache_frequency_reg__wrote_index0, spine_partitionswitchEgress_cache_frequency_reg__wrote_index0__dbg, spine_partitionswitchEgress_deleted_reg, spine_partitionswitchEgress_deleted_reg__dbg0, spine_partitionswitchEgress_deleted_reg__last0_old_value, spine_partitionswitchEgress_deleted_reg__last0_old_value__dbg, spine_partitionswitchEgress_deleted_reg__last0_value, spine_partitionswitchEgress_deleted_reg__last0_value__dbg, spine_partitionswitchEgress_deleted_reg__last_index, spine_partitionswitchEgress_deleted_reg__last_index__dbg, spine_partitionswitchEgress_deleted_reg__last_old_value, spine_partitionswitchEgress_deleted_reg__last_old_value__dbg, spine_partitionswitchEgress_deleted_reg__last_value, spine_partitionswitchEgress_deleted_reg__last_value__dbg, spine_partitionswitchEgress_deleted_reg__last_write_site, spine_partitionswitchEgress_deleted_reg__next_write_site, spine_partitionswitchEgress_deleted_reg__wrote_any, spine_partitionswitchEgress_deleted_reg__wrote_any__dbg, spine_partitionswitchEgress_deleted_reg__wrote_index0, spine_partitionswitchEgress_deleted_reg__wrote_index0__dbg, spine_partitionswitchEgress_eg_port_forward_tbl.action_run, spine_partitionswitchEgress_eg_port_forward_tbl.hit, spine_partitionswitchEgress_eg_port_forward_tbl.partitionswitchEgress_update_netcache_getreq_spine_to_getres_by_mirroring.stat_1, spine_partitionswitchEgress_update_pktlen_tbl.action_run, spine_partitionswitchEgress_update_pktlen_tbl.hit, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.iplen, spine_partitionswitchEgress_update_pktlen_tbl.partitionswitchEgress_update_pktlen.udplen, spine_partitionswitchEgress_update_vallen_tbl.action_run, spine_partitionswitchEgress_update_vallen_tbl.hit, spine_partitionswitchEgress_vallen_reg, spine_partitionswitchEgress_vallen_reg__dbg0, spine_partitionswitchEgress_vallen_reg__last0_old_value, spine_partitionswitchEgress_vallen_reg__last0_old_value__dbg, spine_partitionswitchEgress_vallen_reg__last0_value, spine_partitionswitchEgress_vallen_reg__last0_value__dbg, spine_partitionswitchEgress_vallen_reg__last_index, spine_partitionswitchEgress_vallen_reg__last_index__dbg, spine_partitionswitchEgress_vallen_reg__last_old_value, spine_partitionswitchEgress_vallen_reg__last_old_value__dbg, spine_partitionswitchEgress_vallen_reg__last_value, spine_partitionswitchEgress_vallen_reg__last_value__dbg, spine_partitionswitchEgress_vallen_reg__last_write_site, spine_partitionswitchEgress_vallen_reg__next_write_site, spine_partitionswitchEgress_vallen_reg__wrote_any, spine_partitionswitchEgress_vallen_reg__wrote_any__dbg, spine_partitionswitchEgress_vallen_reg__wrote_index0, spine_partitionswitchEgress_vallen_reg__wrote_index0__dbg, spine_partitionswitchIngress_cache_lookup_tbl.action_run, spine_partitionswitchIngress_cache_lookup_tbl.hit, spine_partitionswitchIngress_cache_lookup_tbl.partitionswitchIngress_cached_action.idx_1, spine_partitionswitchIngress_set_spine_tbl.action_run, spine_partitionswitchIngress_set_spine_tbl.hit, spine_pkt_external;
{
  call mainProcedure();
}

// ===== END HARNESS =====
