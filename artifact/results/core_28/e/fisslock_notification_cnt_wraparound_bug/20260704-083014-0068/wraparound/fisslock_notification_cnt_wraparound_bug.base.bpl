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
type sw_MulticastGroupId_t = bv16;
type sw_QueueId_t = bv5;
type sw_MirrorType_t = bv3;
type sw_MirrorId_t = bv10;
type sw_ResubmitType_t = bv3;
type sw_DigestType_t = bv3;
type sw_L1ExclusionId_t = bv16;
type sw_L2ExclusionId_t = bv9;
type sw_MeterType_t = int;
type sw_MeterColor_t = bv8;
type sw_CounterType_t = int;
type sw_SelectorMode_t = int;
type sw_HashAlgorithm_t = int;
type sw_ingress_intrinsic_metadata_t;

// sw_Struct sw_ingress_intrinsic_metadata_for_tm_t
type sw_ingress_intrinsic_metadata_for_tm_t;

// sw_Struct sw_ingress_intrinsic_metadata_from_parser_t
type sw_ingress_intrinsic_metadata_from_parser_t;

// sw_Struct sw_ingress_intrinsic_metadata_for_deparser_t
type sw_ingress_intrinsic_metadata_for_deparser_t;
type sw_egress_intrinsic_metadata_t;

// sw_Struct sw_egress_intrinsic_metadata_from_parser_t
type sw_egress_intrinsic_metadata_from_parser_t;

// sw_Struct sw_egress_intrinsic_metadata_for_deparser_t
type sw_egress_intrinsic_metadata_for_deparser_t;

// sw_Struct sw_egress_intrinsic_metadata_for_output_port_t
type sw_egress_intrinsic_metadata_for_output_port_t;
type sw_pktgen_timer_header_t;
type sw_pktgen_port_down_header_t;
type sw_pktgen_recirc_header_t;
type sw_ptp_metadata_t;
type sw_MathOp_t = int;
type sw_mac_addr_t = bv48;
type sw_ipv4_addr_t = bv32;
type sw_ipv6_addr_t = bv128;
type sw_udp_port_t = bv16;
type sw_eth_type = bv16;
type sw_ethernet_t;
type sw_ipv4_t;
type sw_ipv6_t;
type sw_udp_t;
type sw_arp_t;
type sw_qp_t = bv24;
type sw_psn_t = bv24;
type sw_msn_t = bv24;
type sw_key_t = bv32;
type sw_mem_addr_t = bv64;
type sw_roce_t;
type sw_roce_reth_t;
type sw_roce_deth_t;
type sw_roce_aeth_t;
type sw_lid_t = bv32;
type sw_host_t = bv8;
type sw_lock_hdr_t;

// sw_Struct sw_metadata_t
type sw_metadata_t;

// sw_Struct sw_header_t
type sw_header_t;
var sw_hdr:sw_header_t;

// sw_Header sw_ethernet_t
var sw_hdr.ethernet:sw_Ref;
var sw_hdr.ethernet.valid:bool;
var sw_hdr.ethernet.dst_mac:sw_mac_addr_t;
var sw_hdr.ethernet.src_mac:sw_mac_addr_t;
var sw_hdr.ethernet.l3_proto:sw_eth_type;

// sw_Header sw_ipv4_t
var sw_hdr.ipv4:sw_Ref;
var sw_hdr.ipv4.valid:bool;
var sw_hdr.ipv4.version:bv4;
var sw_hdr.ipv4.ihl:bv4;
var sw_hdr.ipv4.diffserv:bv8;
var sw_hdr.ipv4.total_len:bv16;
var sw_hdr.ipv4.ident:bv16;
var sw_hdr.ipv4.flags:bv3;
var sw_hdr.ipv4.frag_offset:bv13;
var sw_hdr.ipv4.ttl:bv8;
var sw_hdr.ipv4.l4_proto:bv8;
var sw_hdr.ipv4.hdr_cksum:bv16;
var sw_hdr.ipv4.src_ip:sw_ipv4_addr_t;
var sw_hdr.ipv4.dst_ip:sw_ipv4_addr_t;

// sw_Header sw_ipv6_t
var sw_hdr.ipv6:sw_Ref;
var sw_hdr.ipv6.valid:bool;
var sw_hdr.ipv6.version:bv4;
var sw_hdr.ipv6.traffic_class:bv8;
var sw_hdr.ipv6.flow_table:bv20;
var sw_hdr.ipv6.payload_len:bv16;
var sw_hdr.ipv6.next_hdr:bv8;
var sw_hdr.ipv6.hop_limit:bv8;
var sw_hdr.ipv6.src_ip:sw_ipv6_addr_t;
var sw_hdr.ipv6.dst_ip:sw_ipv6_addr_t;

// sw_Header sw_arp_t
var sw_hdr.arp:sw_Ref;
var sw_hdr.arp.valid:bool;
var sw_hdr.arp.hw_type:bv16;
var sw_hdr.arp.proto_type:bv16;
var sw_hdr.arp.hw_addr_len:bv8;
var sw_hdr.arp.proto_addr_len:bv8;
var sw_hdr.arp.opcode:bv16;
var sw_hdr.arp.src_mac:sw_mac_addr_t;
var sw_hdr.arp.src_ip:sw_ipv4_addr_t;
var sw_hdr.arp.dst_mac:sw_mac_addr_t;
var sw_hdr.arp.dst_ip:sw_ipv4_addr_t;

// sw_Header sw_udp_t
var sw_hdr.udp:sw_Ref;
var sw_hdr.udp.valid:bool;
var sw_hdr.udp.src_port:sw_udp_port_t;
var sw_hdr.udp.dst_port:sw_udp_port_t;
var sw_hdr.udp.len:bv16;
var sw_hdr.udp.checksum:bv16;

// sw_Header sw_roce_t
var sw_hdr.roce:sw_Ref;
var sw_hdr.roce.valid:bool;
var sw_hdr.roce.opcode:bv8;
var sw_hdr.roce._unused:bv4;
var sw_hdr.roce.trans_hdr_ver:bv4;
var sw_hdr.roce.p_key:bv16;
var sw_hdr.roce._reserved:bv8;
var sw_hdr.roce.dest_qp:sw_qp_t;
var sw_hdr.roce.ack_req:bv1;
var sw_hdr.roce.__reserved:bv7;
var sw_hdr.roce.psn:sw_psn_t;

// sw_Header sw_roce_reth_t
var sw_hdr.roce_reth:sw_Ref;
var sw_hdr.roce_reth.valid:bool;
var sw_hdr.roce_reth.vaddr:sw_mem_addr_t;
var sw_hdr.roce_reth.rkey:sw_key_t;
var sw_hdr.roce_reth.length:bv32;

// sw_Header sw_roce_deth_t

// sw_Header sw_roce_aeth_t
var sw_hdr.roce_aeth:sw_Ref;
var sw_hdr.roce_aeth.valid:bool;
var sw_hdr.roce_aeth.syndrome:bv8;
var sw_hdr.roce_aeth.msn:sw_msn_t;

// sw_Header sw_lock_hdr_t
var sw_hdr.lock:sw_Ref;
var sw_hdr.lock.valid:bool;
var sw_hdr.lock.type:bv8;
var sw_hdr.lock.multicasted:bv1;
var sw_hdr.lock.granted:bv1;
var sw_hdr.lock.transferred:bv1;
var sw_hdr.lock.reserved:bv3;
var sw_hdr.lock.old_mode:bv1;
var sw_hdr.lock.mode:bv1;
var sw_hdr.lock.id:sw_lid_t;
var sw_hdr.lock.machine_id:sw_host_t;
var sw_hdr.lock.task_id:bv32;
var sw_hdr.lock.agent:sw_host_t;
var sw_hdr.lock.wq_size:bv32;
var sw_hdr.lock.ncnt:bv8;
var sw_ig_md:sw_metadata_t;
var sw_ig_md.lock_free_mode:bv1;
var sw_ig_md.lock_rw_mode:bv1;
var sw_ig_md.lock_agent:sw_host_t;
var sw_ig_md.lock_index:sw_lid_t;
var sw_ig_md.agent_changed:bv1;
var sw_ig_md.lock_out_of_range:bv1;
var sw_ig_md.is_roce:bv1;
var sw_ig_md.pkt_psn:sw_psn_t;

// sw_Header sw_ingress_intrinsic_metadata_t
var sw_ig_intr_md:sw_Ref;
var sw_ig_intr_md.valid:bool;
var sw_ig_intr_md.resubmit_flag:bv1;
var sw_ig_intr_md._pad1:bv1;
var sw_ig_intr_md.packet_version:bv2;
var sw_ig_intr_md._pad2:bv3;
var sw_ig_intr_md.ingress_port:sw_PortId_t;
var sw_ig_intr_md.ingress_mac_tstamp:bv48;
var sw_pkt:sw_Ref;

// sw_Header sw_roce_deth_t

// sw_Header sw_roce_deth_t
var sw_eg_md:sw_metadata_t;
var sw_eg_md.lock_agent:sw_host_t;
var sw_eg_md.is_roce:bv1;
var sw_eg_md.pkt_psn:sw_psn_t;

// sw_Header sw_egress_intrinsic_metadata_t
var sw_eg_intr_md:sw_Ref;
var sw_eg_intr_md.valid:bool;
var sw_eg_intr_md._pad0:bv7;
var sw_eg_intr_md.egress_port:sw_PortId_t;
var sw_eg_intr_md._pad1:bv5;
var sw_eg_intr_md.enq_qdepth:bv19;
var sw_eg_intr_md._pad2:bv6;
var sw_eg_intr_md.enq_congest_stat:bv2;
var sw_eg_intr_md._pad3:bv14;
var sw_eg_intr_md.enq_tstamp:bv18;
var sw_eg_intr_md._pad4:bv5;
var sw_eg_intr_md.deq_qdepth:bv19;
var sw_eg_intr_md._pad5:bv6;
var sw_eg_intr_md.deq_congest_stat:bv2;
var sw_eg_intr_md.app_pool_congest_stat:bv8;
var sw_eg_intr_md._pad6:bv14;
var sw_eg_intr_md.deq_timedelta:bv18;
var sw_eg_intr_md.egress_rid:bv16;
var sw_eg_intr_md._pad7:bv7;
var sw_eg_intr_md.egress_rid_first:bv1;
var sw_eg_intr_md._pad8:bv3;
var sw_eg_intr_md.egress_qid:sw_QueueId_t;
var sw_eg_intr_md._pad9:bv5;
var sw_eg_intr_md.egress_cos:bv3;
var sw_eg_intr_md._pad10:bv7;
var sw_eg_intr_md.deflection_flag:bv1;
var sw_eg_intr_md.pkt_length:bv16;

// sw_Header sw_roce_deth_t

// sw_Header sw_roce_deth_t
var sw_ig_intr_dprsr_md.mirror_type:sw_MirrorType_t;
var sw_ig_intr_tm_md.ucast_egress_port:sw_PortId_t;

// sw_Register sw_IngressPipe_lock_free_mode_array
var sw_IngressPipe_lock_free_mode_array:[sw_lid_t]bv1;
var sw_IngressPipe_lock_free_mode_array__last_index:sw_lid_t;
var sw_IngressPipe_lock_free_mode_array__last_value:bv1;
var sw_IngressPipe_lock_free_mode_array__last_old_value:bv1;
var sw_IngressPipe_lock_free_mode_array__wrote_any:bool;
var sw_IngressPipe_lock_free_mode_array__wrote_index0:bool;
var sw_IngressPipe_lock_free_mode_array__last0_old_value:bv1;
var sw_IngressPipe_lock_free_mode_array__last0_value:bv1;
var sw_IngressPipe_lock_free_mode_array__next_write_site:int;
var sw_IngressPipe_lock_free_mode_array__last_write_site:int;
const sw_IngressPipe_lock_free_mode_array.size:sw_lid_t;
axiom sw_IngressPipe_lock_free_mode_array.size == 4194304bv32;

// sw_Register sw_IngressPipe_lock_rw_mode_array
var sw_IngressPipe_lock_rw_mode_array:[sw_lid_t]bv1;
var sw_IngressPipe_lock_rw_mode_array__last_index:sw_lid_t;
var sw_IngressPipe_lock_rw_mode_array__last_value:bv1;
var sw_IngressPipe_lock_rw_mode_array__last_old_value:bv1;
var sw_IngressPipe_lock_rw_mode_array__wrote_any:bool;
var sw_IngressPipe_lock_rw_mode_array__wrote_index0:bool;
var sw_IngressPipe_lock_rw_mode_array__last0_old_value:bv1;
var sw_IngressPipe_lock_rw_mode_array__last0_value:bv1;
var sw_IngressPipe_lock_rw_mode_array__next_write_site:int;
var sw_IngressPipe_lock_rw_mode_array__last_write_site:int;
const sw_IngressPipe_lock_rw_mode_array.size:sw_lid_t;
axiom sw_IngressPipe_lock_rw_mode_array.size == 4194304bv32;
var sw___ra_val_IngressPipe_set_shared:bv1;
var sw___ra_ret_IngressPipe_set_shared:bv1;
var sw___ra_val_IngressPipe_set_excl:bv1;
var sw___ra_ret_IngressPipe_set_excl:bv1;
var sw___ra_val_IngressPipe_get_mode:bv1;
var sw___ra_ret_IngressPipe_get_mode:bv1;
var sw___ra_val_IngressPipe_acquire:bv1;
var sw___ra_ret_IngressPipe_acquire:bv1;
var sw___ra_val_IngressPipe_release:bv1;
var sw___ra_ret_IngressPipe_release:bv1;

// sw_Table sw_IngressPipe_rw_table sw_Actionlist sw_Declaration
type sw_IngressPipe_rw_table.action;
const unique sw_IngressPipe_rw_table.action.IngressPipe_lock_shared : sw_IngressPipe_rw_table.action;
const unique sw_IngressPipe_rw_table.action.IngressPipe_lock_excl : sw_IngressPipe_rw_table.action;
const unique sw_IngressPipe_rw_table.action.IngressPipe_lock_mode_get : sw_IngressPipe_rw_table.action;
const unique sw_IngressPipe_rw_table.action.IngressPipe_nop : sw_IngressPipe_rw_table.action;
var sw_IngressPipe_rw_table.action_run : sw_IngressPipe_rw_table.action;
var sw_IngressPipe_rw_table.hit : bool;

// sw_Table sw_IngressPipe_acquire_table sw_Actionlist sw_Declaration
type sw_IngressPipe_acquire_table.action;
const unique sw_IngressPipe_acquire_table.action.IngressPipe_acquire_lock : sw_IngressPipe_acquire_table.action;
var sw_IngressPipe_acquire_table.action_run : sw_IngressPipe_acquire_table.action;
var sw_IngressPipe_acquire_table.hit : bool;

// sw_Table sw_IngressPipe_release_table sw_Actionlist sw_Declaration
type sw_IngressPipe_release_table.action;
const unique sw_IngressPipe_release_table.action.IngressPipe_release_lock : sw_IngressPipe_release_table.action;
var sw_IngressPipe_release_table.action_run : sw_IngressPipe_release_table.action;
var sw_IngressPipe_release_table.hit : bool;

// sw_Register sw_IngressPipe_CounterTable_1_notification_cnt_1
var sw_IngressPipe_CounterTable_1_notification_cnt_1:[sw_lid_t]bv8;
var sw_IngressPipe_CounterTable_1_notification_cnt_1__last_index:sw_lid_t;
var sw_IngressPipe_CounterTable_1_notification_cnt_1__last_value:bv8;
var sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value:bv8;
var sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_any:bool;
var sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_index0:bool;
var sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_old_value:bv8;
var sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value:bv8;
var sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site:int;
var sw_IngressPipe_CounterTable_1_notification_cnt_1__last_write_site:int;
const sw_IngressPipe_CounterTable_1_notification_cnt_1.size:sw_lid_t;
axiom sw_IngressPipe_CounterTable_1_notification_cnt_1.size == 1bv32;

function {:builtin "bvadd"} add.bv8(sw_left:bv8, sw_right:bv8) returns(bv8);
var sw___ra_val_IngressPipe_CounterTable_1_cmp_ncnt:bv8;
var sw___ra_ret_IngressPipe_CounterTable_1_cmp_ncnt:bv1;
var sw___ra_val_IngressPipe_CounterTable_1_count_ncnt:bv8;
var sw___ra_ret_IngressPipe_CounterTable_1_count_ncnt:bv8;
var sw___ra_val_IngressPipe_CounterTable_1_reset_ncnt:bv8;
var sw___ra_ret_IngressPipe_CounterTable_1_reset_ncnt:bv8;

// sw_Table sw_IngressPipe_CounterTable_1_counter_table_1 sw_Actionlist sw_Declaration
type sw_IngressPipe_CounterTable_1_counter_table_1.action;
const unique sw_IngressPipe_CounterTable_1_counter_table_1.action.IngressPipe_CounterTable_1_get_notification_cnt : sw_IngressPipe_CounterTable_1_counter_table_1.action;
const unique sw_IngressPipe_CounterTable_1_counter_table_1.action.IngressPipe_CounterTable_1_reset_notification_cnt : sw_IngressPipe_CounterTable_1_counter_table_1.action;
const unique sw_IngressPipe_CounterTable_1_counter_table_1.action.IngressPipe_CounterTable_1_new_notification : sw_IngressPipe_CounterTable_1_counter_table_1.action;
const unique sw_IngressPipe_CounterTable_1_counter_table_1.action.IngressPipe_CounterTable_1_nop : sw_IngressPipe_CounterTable_1_counter_table_1.action;
var sw_IngressPipe_CounterTable_1_counter_table_1.action_run : sw_IngressPipe_CounterTable_1_counter_table_1.action;
var sw_IngressPipe_CounterTable_1_counter_table_1.hit : bool;

// sw_Register sw_IngressPipe_CounterTable_2_notification_cnt_2
var sw_IngressPipe_CounterTable_2_notification_cnt_2:[sw_lid_t]bv8;
var sw_IngressPipe_CounterTable_2_notification_cnt_2__last_index:sw_lid_t;
var sw_IngressPipe_CounterTable_2_notification_cnt_2__last_value:bv8;
var sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value:bv8;
var sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_any:bool;
var sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_index0:bool;
var sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_old_value:bv8;
var sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_value:bv8;
var sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site:int;
var sw_IngressPipe_CounterTable_2_notification_cnt_2__last_write_site:int;
const sw_IngressPipe_CounterTable_2_notification_cnt_2.size:sw_lid_t;
axiom sw_IngressPipe_CounterTable_2_notification_cnt_2.size == 1bv32;
var sw___ra_val_IngressPipe_CounterTable_2_cmp_ncnt:bv8;
var sw___ra_ret_IngressPipe_CounterTable_2_cmp_ncnt:bv1;
var sw___ra_val_IngressPipe_CounterTable_2_count_ncnt:bv8;
var sw___ra_ret_IngressPipe_CounterTable_2_count_ncnt:bv8;
var sw___ra_val_IngressPipe_CounterTable_2_reset_ncnt:bv8;
var sw___ra_ret_IngressPipe_CounterTable_2_reset_ncnt:bv8;

// sw_Table sw_IngressPipe_CounterTable_2_counter_table_2 sw_Actionlist sw_Declaration
type sw_IngressPipe_CounterTable_2_counter_table_2.action;
const unique sw_IngressPipe_CounterTable_2_counter_table_2.action.IngressPipe_CounterTable_2_get_notification_cnt : sw_IngressPipe_CounterTable_2_counter_table_2.action;
const unique sw_IngressPipe_CounterTable_2_counter_table_2.action.IngressPipe_CounterTable_2_reset_notification_cnt : sw_IngressPipe_CounterTable_2_counter_table_2.action;
const unique sw_IngressPipe_CounterTable_2_counter_table_2.action.IngressPipe_CounterTable_2_new_notification : sw_IngressPipe_CounterTable_2_counter_table_2.action;
const unique sw_IngressPipe_CounterTable_2_counter_table_2.action.IngressPipe_CounterTable_2_nop : sw_IngressPipe_CounterTable_2_counter_table_2.action;
var sw_IngressPipe_CounterTable_2_counter_table_2.action_run : sw_IngressPipe_CounterTable_2_counter_table_2.action;
var sw_IngressPipe_CounterTable_2_counter_table_2.hit : bool;

// sw_Register sw_IngressPipe_CounterTable_3_notification_cnt_3
var sw_IngressPipe_CounterTable_3_notification_cnt_3:[sw_lid_t]bv8;
var sw_IngressPipe_CounterTable_3_notification_cnt_3__last_index:sw_lid_t;
var sw_IngressPipe_CounterTable_3_notification_cnt_3__last_value:bv8;
var sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value:bv8;
var sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_any:bool;
var sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_index0:bool;
var sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_old_value:bv8;
var sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_value:bv8;
var sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site:int;
var sw_IngressPipe_CounterTable_3_notification_cnt_3__last_write_site:int;
const sw_IngressPipe_CounterTable_3_notification_cnt_3.size:sw_lid_t;
axiom sw_IngressPipe_CounterTable_3_notification_cnt_3.size == 1bv32;
var sw___ra_val_IngressPipe_CounterTable_3_cmp_ncnt:bv8;
var sw___ra_ret_IngressPipe_CounterTable_3_cmp_ncnt:bv1;
var sw___ra_val_IngressPipe_CounterTable_3_count_ncnt:bv8;
var sw___ra_ret_IngressPipe_CounterTable_3_count_ncnt:bv8;
var sw___ra_val_IngressPipe_CounterTable_3_reset_ncnt:bv8;
var sw___ra_ret_IngressPipe_CounterTable_3_reset_ncnt:bv8;

// sw_Table sw_IngressPipe_CounterTable_3_counter_table_3 sw_Actionlist sw_Declaration
type sw_IngressPipe_CounterTable_3_counter_table_3.action;
const unique sw_IngressPipe_CounterTable_3_counter_table_3.action.IngressPipe_CounterTable_3_get_notification_cnt : sw_IngressPipe_CounterTable_3_counter_table_3.action;
const unique sw_IngressPipe_CounterTable_3_counter_table_3.action.IngressPipe_CounterTable_3_reset_notification_cnt : sw_IngressPipe_CounterTable_3_counter_table_3.action;
const unique sw_IngressPipe_CounterTable_3_counter_table_3.action.IngressPipe_CounterTable_3_new_notification : sw_IngressPipe_CounterTable_3_counter_table_3.action;
const unique sw_IngressPipe_CounterTable_3_counter_table_3.action.IngressPipe_CounterTable_3_nop : sw_IngressPipe_CounterTable_3_counter_table_3.action;
var sw_IngressPipe_CounterTable_3_counter_table_3.action_run : sw_IngressPipe_CounterTable_3_counter_table_3.action;
var sw_IngressPipe_CounterTable_3_counter_table_3.hit : bool;

// sw_Register sw_IngressPipe_LockOperation_1_lock_agent_array_1
var sw_IngressPipe_LockOperation_1_lock_agent_array_1:[sw_lid_t]sw_host_t;
var sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index:sw_lid_t;
var sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value:sw_host_t;
var sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value:sw_host_t;
var sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any:bool;
var sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0:bool;
var sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value:sw_host_t;
var sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value:sw_host_t;
var sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site:int;
var sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site:int;
const sw_IngressPipe_LockOperation_1_lock_agent_array_1.size:sw_lid_t;
axiom sw_IngressPipe_LockOperation_1_lock_agent_array_1.size == 1bv32;
var sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent:sw_host_t;
var sw___ra_ret_IngressPipe_LockOperation_1_set_lock_agent:sw_host_t;
var sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent:sw_host_t;
var sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent:sw_host_t;

// sw_Table sw_IngressPipe_LockOperation_1_lock_operation_1 sw_Actionlist sw_Declaration
type sw_IngressPipe_LockOperation_1_lock_operation_1.action;
const unique sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_new_agent : sw_IngressPipe_LockOperation_1_lock_operation_1.action;
const unique sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_mcast_to_agent : sw_IngressPipe_LockOperation_1_lock_operation_1.action;
const unique sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_fwd_to_agent : sw_IngressPipe_LockOperation_1_lock_operation_1.action;
const unique sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_transfer_agent : sw_IngressPipe_LockOperation_1_lock_operation_1.action;
const unique sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_reset_agent : sw_IngressPipe_LockOperation_1_lock_operation_1.action;
const unique sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_nop : sw_IngressPipe_LockOperation_1_lock_operation_1.action;
var sw_IngressPipe_LockOperation_1_lock_operation_1.action_run : sw_IngressPipe_LockOperation_1_lock_operation_1.action;
var sw_IngressPipe_LockOperation_1_lock_operation_1.hit : bool;

// sw_Register sw_IngressPipe_LockOperation_2_lock_agent_array_2
var sw_IngressPipe_LockOperation_2_lock_agent_array_2:[sw_lid_t]sw_host_t;
var sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index:sw_lid_t;
var sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value:sw_host_t;
var sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value:sw_host_t;
var sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any:bool;
var sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0:bool;
var sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value:sw_host_t;
var sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value:sw_host_t;
var sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site:int;
var sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site:int;
const sw_IngressPipe_LockOperation_2_lock_agent_array_2.size:sw_lid_t;
axiom sw_IngressPipe_LockOperation_2_lock_agent_array_2.size == 1bv32;
var sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent:sw_host_t;
var sw___ra_ret_IngressPipe_LockOperation_2_set_lock_agent:sw_host_t;
var sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent:sw_host_t;
var sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent:sw_host_t;

// sw_Table sw_IngressPipe_LockOperation_2_lock_operation_2 sw_Actionlist sw_Declaration
type sw_IngressPipe_LockOperation_2_lock_operation_2.action;
const unique sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_new_agent : sw_IngressPipe_LockOperation_2_lock_operation_2.action;
const unique sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_mcast_to_agent : sw_IngressPipe_LockOperation_2_lock_operation_2.action;
const unique sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_fwd_to_agent : sw_IngressPipe_LockOperation_2_lock_operation_2.action;
const unique sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_transfer_agent : sw_IngressPipe_LockOperation_2_lock_operation_2.action;
const unique sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_reset_agent : sw_IngressPipe_LockOperation_2_lock_operation_2.action;
const unique sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_nop : sw_IngressPipe_LockOperation_2_lock_operation_2.action;
var sw_IngressPipe_LockOperation_2_lock_operation_2.action_run : sw_IngressPipe_LockOperation_2_lock_operation_2.action;
var sw_IngressPipe_LockOperation_2_lock_operation_2.hit : bool;

// sw_Register sw_IngressPipe_LockOperation_3_lock_agent_array_3
var sw_IngressPipe_LockOperation_3_lock_agent_array_3:[sw_lid_t]sw_host_t;
var sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index:sw_lid_t;
var sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value:sw_host_t;
var sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value:sw_host_t;
var sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any:bool;
var sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0:bool;
var sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value:sw_host_t;
var sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value:sw_host_t;
var sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site:int;
var sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site:int;
const sw_IngressPipe_LockOperation_3_lock_agent_array_3.size:sw_lid_t;
axiom sw_IngressPipe_LockOperation_3_lock_agent_array_3.size == 1bv32;
var sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent:sw_host_t;
var sw___ra_ret_IngressPipe_LockOperation_3_set_lock_agent:sw_host_t;
var sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent:sw_host_t;
var sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent:sw_host_t;

// sw_Table sw_IngressPipe_LockOperation_3_lock_operation_3 sw_Actionlist sw_Declaration
type sw_IngressPipe_LockOperation_3_lock_operation_3.action;
const unique sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_new_agent : sw_IngressPipe_LockOperation_3_lock_operation_3.action;
const unique sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_mcast_to_agent : sw_IngressPipe_LockOperation_3_lock_operation_3.action;
const unique sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_fwd_to_agent : sw_IngressPipe_LockOperation_3_lock_operation_3.action;
const unique sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_transfer_agent : sw_IngressPipe_LockOperation_3_lock_operation_3.action;
const unique sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_reset_agent : sw_IngressPipe_LockOperation_3_lock_operation_3.action;
const unique sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_nop : sw_IngressPipe_LockOperation_3_lock_operation_3.action;
var sw_IngressPipe_LockOperation_3_lock_operation_3.action_run : sw_IngressPipe_LockOperation_3_lock_operation_3.action;
var sw_IngressPipe_LockOperation_3_lock_operation_3.hit : bool;

// sw_Header sw_roce_deth_t
var sw_meta.lock_agent:sw_host_t;

function {:builtin "bvsub"} sub.bv17(sw_left:bv17, sw_right:bv17) returns(bv17);

function {:builtin "bvsub"} sub.bv33(sw_left:bv33, sw_right:bv33) returns(bv33);

// sw_Control sw_EgressDeparser
procedure {:inline 1} sw_EgressDeparser()
{
}

// sw_Parser sw_EgressParser
procedure {:inline 1} sw_EgressParser()
	modifies sw_drop, sw_eg_md.is_roce, sw_eg_md.pkt_psn, sw_isValid;
{
    goto sw_State$EgressParser$start;

        sw_State$EgressParser$start:
    call sw_packet_in.extract(sw_eg_intr_md);
    call sw_packet_in.extract(sw_hdr.ethernet);
    goto sw_State$EgressParser$start$parse_ipv4_4, sw_State$EgressParser$start$parse_ipv6_3, sw_State$EgressParser$start$parse_arp_2, sw_State$EgressParser$start$DEFAULT;
    
sw_State$EgressParser$start$parse_ipv4_4:
    assume (sw_hdr.ethernet.l3_proto == 2048bv16);
    goto sw_State$EgressParser$parse_ipv4;
    
sw_State$EgressParser$start$parse_ipv6_3:
    assume (sw_hdr.ethernet.l3_proto == 34525bv16);
    goto sw_State$EgressParser$parse_ipv6;
    
sw_State$EgressParser$start$parse_arp_2:
    assume (sw_hdr.ethernet.l3_proto == 2054bv16);
    goto sw_State$EgressParser$parse_arp;

    sw_State$EgressParser$start$DEFAULT:
    assume(!(sw_hdr.ethernet.l3_proto == 2048bv16)&&!(sw_hdr.ethernet.l3_proto == 34525bv16)&&!(sw_hdr.ethernet.l3_proto == 2054bv16));
    goto sw_State$accept;

        sw_State$EgressParser$parse_arp:
    call sw_packet_in.extract(sw_hdr.arp);
    goto sw_State$accept;

        sw_State$EgressParser$parse_ipv4:
    call sw_packet_in.extract(sw_hdr.ipv4);
    goto sw_State$EgressParser$parse_ipv4$parse_udp_2, sw_State$EgressParser$parse_ipv4$DEFAULT;
    
sw_State$EgressParser$parse_ipv4$parse_udp_2:
    assume (sw_hdr.ipv4.l4_proto == 17bv8);
    goto sw_State$EgressParser$parse_udp;

    sw_State$EgressParser$parse_ipv4$DEFAULT:
    assume(!(sw_hdr.ipv4.l4_proto == 17bv8));
    goto sw_State$accept;

        sw_State$EgressParser$parse_ipv6:
    call sw_packet_in.extract(sw_hdr.ipv6);
    goto sw_State$accept;

        sw_State$EgressParser$parse_udp:
    call sw_packet_in.extract(sw_hdr.udp);
    goto sw_State$EgressParser$parse_udp$parse_roce_4, sw_State$EgressParser$parse_udp$parse_lock_3, sw_State$EgressParser$parse_udp$parse_lock_2, sw_State$EgressParser$parse_udp$DEFAULT;
    
sw_State$EgressParser$parse_udp$parse_roce_4:
    assume (sw_hdr.udp.dst_port == 4791bv16);
    goto sw_State$EgressParser$parse_roce;
    
sw_State$EgressParser$parse_udp$parse_lock_3:
    assume (sw_hdr.udp.dst_port == 20001bv16);
    goto sw_State$EgressParser$parse_lock;
    
sw_State$EgressParser$parse_udp$parse_lock_2:
    assume (sw_hdr.udp.dst_port == 20002bv16);
    goto sw_State$EgressParser$parse_lock;

    sw_State$EgressParser$parse_udp$DEFAULT:
    assume(!(sw_hdr.udp.dst_port == 4791bv16)&&!(sw_hdr.udp.dst_port == 20001bv16)&&!(sw_hdr.udp.dst_port == 20002bv16));
    goto sw_State$accept;

        sw_State$EgressParser$parse_lock:
    call sw_packet_in.extract(sw_hdr.lock);
    goto sw_State$accept;

        sw_State$EgressParser$parse_roce:
    call sw_packet_in.extract(sw_hdr.roce);
    sw_eg_md.is_roce := 1bv1;
    sw_eg_md.pkt_psn := sw_hdr.roce.psn;
    goto sw_State$EgressParser$parse_roce$parse_roce_reth_5, sw_State$EgressParser$parse_roce$parse_roce_aeth_4, sw_State$EgressParser$parse_roce$parse_roce_reth_3, sw_State$EgressParser$parse_roce$parse_roce_aeth_2, sw_State$EgressParser$parse_roce$DEFAULT;
    
sw_State$EgressParser$parse_roce$parse_roce_reth_5:
    assume (sw_hdr.roce.opcode == 12bv8);
    goto sw_State$EgressParser$parse_roce_reth;
    
sw_State$EgressParser$parse_roce$parse_roce_aeth_4:
    assume (sw_hdr.roce.opcode == 16bv8);
    goto sw_State$EgressParser$parse_roce_aeth;
    
sw_State$EgressParser$parse_roce$parse_roce_reth_3:
    assume (sw_hdr.roce.opcode == 10bv8);
    goto sw_State$EgressParser$parse_roce_reth;
    
sw_State$EgressParser$parse_roce$parse_roce_aeth_2:
    assume (sw_hdr.roce.opcode == 17bv8);
    goto sw_State$EgressParser$parse_roce_aeth;

    sw_State$EgressParser$parse_roce$DEFAULT:
    assume(!(sw_hdr.roce.opcode == 12bv8)&&!(sw_hdr.roce.opcode == 16bv8)&&!(sw_hdr.roce.opcode == 10bv8)&&!(sw_hdr.roce.opcode == 17bv8));
    goto sw_State$accept;

        sw_State$EgressParser$parse_roce_reth:
    call sw_packet_in.extract(sw_hdr.roce_reth);
    goto sw_State$accept;

        sw_State$EgressParser$parse_roce_aeth:
    call sw_packet_in.extract(sw_hdr.roce_aeth);
    goto sw_State$accept;

    sw_State$accept:
    call sw_accept();
    goto sw_Exit;

    sw_State$reject:
    call sw_reject();
    goto sw_Exit;

    sw_Exit:
}

// sw_Control sw_EgressPipe
procedure {:inline 1} sw_EgressPipe()
	modifies sw_hdr.lock.type;
{
    if(((sw_hdr.lock.multicasted == 1bv1)) && ((sw_eg_intr_md.egress_rid == 2bv16))){
        sw_hdr.lock.type := 3bv8;
    }
    else{
        if(((sw_hdr.lock.multicasted == 1bv1)) && ((sw_eg_intr_md.egress_rid == 1bv16))){
            sw_hdr.lock.type := 1bv8;
        }
    }
}

// sw_Control sw_IngressDeparser
procedure {:inline 1} sw_IngressDeparser()
{
}

// sw_Parser sw_IngressParser
procedure {:inline 1} sw_IngressParser()
	modifies sw_drop, sw_ig_md.is_roce, sw_ig_md.pkt_psn, sw_isValid;
{
    goto sw_State$IngressParser$start;

        sw_State$IngressParser$start:
    call sw_packet_in.extract(sw_ig_intr_md);
    goto sw_State$IngressParser$start$parse_resubmit_2, sw_State$IngressParser$start$parse_port_metadata_1, sw_State$IngressParser$start$DEFAULT;
    
sw_State$IngressParser$start$parse_resubmit_2:
    assume (sw_ig_intr_md.resubmit_flag == 1bv1);
    goto sw_State$IngressParser$parse_resubmit;
    
sw_State$IngressParser$start$parse_port_metadata_1:
    assume (sw_ig_intr_md.resubmit_flag == 0bv1);
    goto sw_State$IngressParser$parse_port_metadata;

    sw_State$IngressParser$start$DEFAULT:
    assume(!(sw_ig_intr_md.resubmit_flag == 1bv1)&&!(sw_ig_intr_md.resubmit_flag == 0bv1));
goto sw_State$reject;

        sw_State$IngressParser$parse_resubmit:
    goto sw_State$reject;

        sw_State$IngressParser$parse_port_metadata:
    call sw_pkt.advance(64bv32);
    call sw_packet_in.extract(sw_hdr.ethernet);
    goto sw_State$IngressParser$parse_port_metadata$parse_ipv4_4, sw_State$IngressParser$parse_port_metadata$parse_ipv6_3, sw_State$IngressParser$parse_port_metadata$parse_arp_2, sw_State$IngressParser$parse_port_metadata$DEFAULT;
    
sw_State$IngressParser$parse_port_metadata$parse_ipv4_4:
    assume (sw_hdr.ethernet.l3_proto == 2048bv16);
    goto sw_State$IngressParser$parse_ipv4;
    
sw_State$IngressParser$parse_port_metadata$parse_ipv6_3:
    assume (sw_hdr.ethernet.l3_proto == 34525bv16);
    goto sw_State$IngressParser$parse_ipv6;
    
sw_State$IngressParser$parse_port_metadata$parse_arp_2:
    assume (sw_hdr.ethernet.l3_proto == 2054bv16);
    goto sw_State$IngressParser$parse_arp;

    sw_State$IngressParser$parse_port_metadata$DEFAULT:
    assume(!(sw_hdr.ethernet.l3_proto == 2048bv16)&&!(sw_hdr.ethernet.l3_proto == 34525bv16)&&!(sw_hdr.ethernet.l3_proto == 2054bv16));
    goto sw_State$accept;

        sw_State$IngressParser$parse_arp:
    call sw_packet_in.extract(sw_hdr.arp);
    goto sw_State$accept;

        sw_State$IngressParser$parse_ipv4:
    call sw_packet_in.extract(sw_hdr.ipv4);
    goto sw_State$IngressParser$parse_ipv4$parse_udp_2, sw_State$IngressParser$parse_ipv4$DEFAULT;
    
sw_State$IngressParser$parse_ipv4$parse_udp_2:
    assume (sw_hdr.ipv4.l4_proto == 17bv8);
    goto sw_State$IngressParser$parse_udp;

    sw_State$IngressParser$parse_ipv4$DEFAULT:
    assume(!(sw_hdr.ipv4.l4_proto == 17bv8));
    goto sw_State$accept;

        sw_State$IngressParser$parse_ipv6:
    call sw_packet_in.extract(sw_hdr.ipv6);
    goto sw_State$accept;

        sw_State$IngressParser$parse_udp:
    call sw_packet_in.extract(sw_hdr.udp);
    goto sw_State$IngressParser$parse_udp$parse_roce_4, sw_State$IngressParser$parse_udp$parse_lock_3, sw_State$IngressParser$parse_udp$parse_lock_2, sw_State$IngressParser$parse_udp$DEFAULT;
    
sw_State$IngressParser$parse_udp$parse_roce_4:
    assume (sw_hdr.udp.dst_port == 4791bv16);
    goto sw_State$IngressParser$parse_roce;
    
sw_State$IngressParser$parse_udp$parse_lock_3:
    assume (sw_hdr.udp.dst_port == 20001bv16);
    goto sw_State$IngressParser$parse_lock;
    
sw_State$IngressParser$parse_udp$parse_lock_2:
    assume (sw_hdr.udp.dst_port == 20002bv16);
    goto sw_State$IngressParser$parse_lock;

    sw_State$IngressParser$parse_udp$DEFAULT:
    assume(!(sw_hdr.udp.dst_port == 4791bv16)&&!(sw_hdr.udp.dst_port == 20001bv16)&&!(sw_hdr.udp.dst_port == 20002bv16));
    goto sw_State$accept;

        sw_State$IngressParser$parse_lock:
    call sw_packet_in.extract(sw_hdr.lock);
    goto sw_State$accept;

        sw_State$IngressParser$parse_roce:
    call sw_packet_in.extract(sw_hdr.roce);
    sw_ig_md.is_roce := 1bv1;
    sw_ig_md.pkt_psn := sw_hdr.roce.psn;
    goto sw_State$IngressParser$parse_roce$parse_roce_reth_5, sw_State$IngressParser$parse_roce$parse_roce_aeth_4, sw_State$IngressParser$parse_roce$parse_roce_reth_3, sw_State$IngressParser$parse_roce$parse_roce_aeth_2, sw_State$IngressParser$parse_roce$DEFAULT;
    
sw_State$IngressParser$parse_roce$parse_roce_reth_5:
    assume (sw_hdr.roce.opcode == 12bv8);
    goto sw_State$IngressParser$parse_roce_reth;
    
sw_State$IngressParser$parse_roce$parse_roce_aeth_4:
    assume (sw_hdr.roce.opcode == 16bv8);
    goto sw_State$IngressParser$parse_roce_aeth;
    
sw_State$IngressParser$parse_roce$parse_roce_reth_3:
    assume (sw_hdr.roce.opcode == 10bv8);
    goto sw_State$IngressParser$parse_roce_reth;
    
sw_State$IngressParser$parse_roce$parse_roce_aeth_2:
    assume (sw_hdr.roce.opcode == 17bv8);
    goto sw_State$IngressParser$parse_roce_aeth;

    sw_State$IngressParser$parse_roce$DEFAULT:
    assume(!(sw_hdr.roce.opcode == 12bv8)&&!(sw_hdr.roce.opcode == 16bv8)&&!(sw_hdr.roce.opcode == 10bv8)&&!(sw_hdr.roce.opcode == 17bv8));
    goto sw_State$accept;

        sw_State$IngressParser$parse_roce_reth:
    call sw_packet_in.extract(sw_hdr.roce_reth);
    goto sw_State$accept;

        sw_State$IngressParser$parse_roce_aeth:
    call sw_packet_in.extract(sw_hdr.roce_aeth);
    goto sw_State$accept;

    sw_State$accept:
    call sw_accept();
    goto sw_Exit;

    sw_State$reject:
    call sw_reject();
    goto sw_Exit;

    sw_Exit:
}

// sw_Control sw_IngressPipe
procedure {:inline 1} sw_IngressPipe()
	modifies sw_IngressPipe_CounterTable_1_counter_table_1.action_run, sw_IngressPipe_CounterTable_1_counter_table_1.hit, sw_IngressPipe_CounterTable_1_notification_cnt_1, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_index, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_any, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_index0, sw_IngressPipe_CounterTable_2_counter_table_2.action_run, sw_IngressPipe_CounterTable_2_counter_table_2.hit, sw_IngressPipe_CounterTable_2_notification_cnt_2, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_index, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_any, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_index0, sw_IngressPipe_CounterTable_3_counter_table_3.action_run, sw_IngressPipe_CounterTable_3_counter_table_3.hit, sw_IngressPipe_CounterTable_3_notification_cnt_3, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_index, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_any, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_index0, sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0, sw_IngressPipe_LockOperation_1_lock_operation_1.action_run, sw_IngressPipe_LockOperation_1_lock_operation_1.hit, sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0, sw_IngressPipe_LockOperation_2_lock_operation_2.action_run, sw_IngressPipe_LockOperation_2_lock_operation_2.hit, sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0, sw_IngressPipe_LockOperation_3_lock_operation_3.action_run, sw_IngressPipe_LockOperation_3_lock_operation_3.hit, sw_IngressPipe_acquire_table.action_run, sw_IngressPipe_acquire_table.hit, sw_IngressPipe_lock_free_mode_array, sw_IngressPipe_lock_free_mode_array__last0_old_value, sw_IngressPipe_lock_free_mode_array__last0_value, sw_IngressPipe_lock_free_mode_array__last_index, sw_IngressPipe_lock_free_mode_array__last_old_value, sw_IngressPipe_lock_free_mode_array__last_value, sw_IngressPipe_lock_free_mode_array__last_write_site, sw_IngressPipe_lock_free_mode_array__next_write_site, sw_IngressPipe_lock_free_mode_array__wrote_any, sw_IngressPipe_lock_free_mode_array__wrote_index0, sw_IngressPipe_lock_rw_mode_array, sw_IngressPipe_lock_rw_mode_array__last0_old_value, sw_IngressPipe_lock_rw_mode_array__last0_value, sw_IngressPipe_lock_rw_mode_array__last_index, sw_IngressPipe_lock_rw_mode_array__last_old_value, sw_IngressPipe_lock_rw_mode_array__last_value, sw_IngressPipe_lock_rw_mode_array__last_write_site, sw_IngressPipe_lock_rw_mode_array__next_write_site, sw_IngressPipe_lock_rw_mode_array__wrote_any, sw_IngressPipe_lock_rw_mode_array__wrote_index0, sw_IngressPipe_release_table.action_run, sw_IngressPipe_release_table.hit, sw_IngressPipe_rw_table.action_run, sw_IngressPipe_rw_table.hit, sw___ra_ret_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_ret_IngressPipe_acquire, sw___ra_ret_IngressPipe_get_mode, sw___ra_ret_IngressPipe_release, sw___ra_ret_IngressPipe_set_excl, sw___ra_ret_IngressPipe_set_shared, sw___ra_val_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_1_count_ncnt, sw___ra_val_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_2_count_ncnt, sw___ra_val_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_3_count_ncnt, sw___ra_val_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_val_IngressPipe_acquire, sw___ra_val_IngressPipe_get_mode, sw___ra_val_IngressPipe_release, sw___ra_val_IngressPipe_set_excl, sw___ra_val_IngressPipe_set_shared, sw_hdr.lock.agent, sw_hdr.lock.mode, sw_hdr.lock.multicasted, sw_hdr.lock.old_mode, sw_hdr.lock.transferred, sw_hdr.lock.type, sw_ig_md.agent_changed, sw_ig_md.lock_agent, sw_ig_md.lock_free_mode, sw_ig_md.lock_index, sw_ig_md.lock_out_of_range, sw_ig_md.lock_rw_mode;
{
    if(sw_isValid[sw_hdr.lock]){
        sw_ig_md.agent_changed := 0bv1;
        sw_ig_md.lock_out_of_range := 0bv1;
        sw_hdr.lock.multicasted := 0bv1;
        sw_ig_md.lock_index := 0bv13++sw_ig_md.lock_index[19:0];
        if((sw_hdr.lock.id[32:19] == 0bv13)){
            call sw_IngressPipe_CounterTable_1_counter_table_1.apply();
        }
        else{
            if((sw_hdr.lock.id[32:19] == 1bv13)){
                call sw_IngressPipe_CounterTable_2_counter_table_2.apply();
            }
            else{
                if((sw_hdr.lock.id[32:19] == 2bv13)){
                    call sw_IngressPipe_CounterTable_3_counter_table_3.apply();
                }
                else{
                    sw_ig_md.lock_out_of_range := 1bv1;
                }
            }
        }
        if((sw_ig_md.lock_out_of_range == 1bv1)){
        }
        else{
            if(((((sw_hdr.lock.type == 5bv8)) || ((sw_hdr.lock.type == 6bv8))) && ((sw_hdr.lock.old_mode == 0bv1))) && ((sw_ig_md.agent_changed == 0bv1))){
            }
            else{
                if((sw_hdr.lock.type == 3bv8)){
                }
                else{
                    if((sw_hdr.lock.type != 6bv8)){
                        call sw_IngressPipe_acquire_table.apply();
                    }
                    else{
                        call sw_IngressPipe_release_table.apply();
                    }
                    call sw_IngressPipe_rw_table.apply();
                    sw_ig_md.lock_agent := sw_hdr.lock.machine_id;
                    if((sw_hdr.lock.id[32:19] == 0bv13)){
                        call sw_IngressPipe_LockOperation_1_lock_operation_1.apply();
                    }
                    else{
                        if((sw_hdr.lock.id[32:19] == 1bv13)){
                            call sw_IngressPipe_LockOperation_2_lock_operation_2.apply();
                        }
                        else{
                            call sw_IngressPipe_LockOperation_3_lock_operation_3.apply();
                        }
                    }
                }
            }
        }
    }
    else{
    }
}

// sw_RegisterAction sw_IngressPipe_CounterTable_1_cmp_ncnt.apply
procedure {:inline 1} sw_IngressPipe_CounterTable_1_cmp_ncnt.apply(sw_value_in:bv8, sw_flag_in:bv1) returns (sw_value_out:bv8, sw_flag_out:bv1)
{
    var sw_value:bv8;
    var sw_flag:bv1;
    sw_value := sw_value_in;
    sw_flag := sw_flag_in;
    if((sw_value == sw_hdr.lock.ncnt)){
        sw_value := 0bv8;
        sw_flag := 1bv1;
    }
    else{
        sw_flag := 0bv1;
    }
    sw_value_out := sw_value;
    sw_flag_out := sw_flag;
}

// sw_RegisterAction sw_IngressPipe_CounterTable_1_count_ncnt.apply
procedure {:inline 1} sw_IngressPipe_CounterTable_1_count_ncnt.apply(sw_value_in:bv8) returns (sw_value_out:bv8)
{
    var sw_value:bv8;
    sw_value := sw_value_in;
    sw_value := add.bv8(sw_value, 1bv8);
    sw_value_out := sw_value;
}

// sw_Table sw_IngressPipe_CounterTable_1_counter_table_1
procedure {:inline 1} sw_IngressPipe_CounterTable_1_counter_table_1.apply()
	modifies sw_IngressPipe_CounterTable_1_counter_table_1.action_run, sw_IngressPipe_CounterTable_1_counter_table_1.hit, sw_IngressPipe_CounterTable_1_notification_cnt_1, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_index, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_any, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_index0, sw___ra_ret_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_1_count_ncnt, sw___ra_val_IngressPipe_CounterTable_1_reset_ncnt, sw_hdr.lock.mode, sw_hdr.lock.old_mode, sw_hdr.lock.type, sw_ig_md.agent_changed;
{
    sw_hdr.lock.type := sw_hdr.lock.type;
    sw_hdr.lock.mode := sw_hdr.lock.mode;
    sw_hdr.lock.old_mode := sw_hdr.lock.old_mode;
    sw_IngressPipe_CounterTable_1_counter_table_1.hit := false;
    if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 0bv1){
        sw_IngressPipe_CounterTable_1_counter_table_1.hit := true;
        sw_IngressPipe_CounterTable_1_counter_table_1.action_run := sw_IngressPipe_CounterTable_1_counter_table_1.action.IngressPipe_CounterTable_1_new_notification;
        call sw_IngressPipe_CounterTable_1_new_notification();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 1bv1){
        sw_IngressPipe_CounterTable_1_counter_table_1.hit := true;
        sw_IngressPipe_CounterTable_1_counter_table_1.action_run := sw_IngressPipe_CounterTable_1_counter_table_1.action.IngressPipe_CounterTable_1_new_notification;
        call sw_IngressPipe_CounterTable_1_new_notification();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 0bv1){
        sw_IngressPipe_CounterTable_1_counter_table_1.hit := true;
        sw_IngressPipe_CounterTable_1_counter_table_1.action_run := sw_IngressPipe_CounterTable_1_counter_table_1.action.IngressPipe_CounterTable_1_get_notification_cnt;
        call sw_IngressPipe_CounterTable_1_get_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 1bv1){
        sw_IngressPipe_CounterTable_1_counter_table_1.hit := true;
        sw_IngressPipe_CounterTable_1_counter_table_1.action_run := sw_IngressPipe_CounterTable_1_counter_table_1.action.IngressPipe_CounterTable_1_reset_notification_cnt;
        call sw_IngressPipe_CounterTable_1_reset_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 1bv1 && sw_hdr.lock.old_mode == 0bv1){
        sw_IngressPipe_CounterTable_1_counter_table_1.hit := true;
        sw_IngressPipe_CounterTable_1_counter_table_1.action_run := sw_IngressPipe_CounterTable_1_counter_table_1.action.IngressPipe_CounterTable_1_get_notification_cnt;
        call sw_IngressPipe_CounterTable_1_get_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 1bv1 && sw_hdr.lock.old_mode == 1bv1){
        sw_IngressPipe_CounterTable_1_counter_table_1.hit := true;
        sw_IngressPipe_CounterTable_1_counter_table_1.action_run := sw_IngressPipe_CounterTable_1_counter_table_1.action.IngressPipe_CounterTable_1_reset_notification_cnt;
        call sw_IngressPipe_CounterTable_1_reset_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 0bv1){
        sw_IngressPipe_CounterTable_1_counter_table_1.hit := true;
        sw_IngressPipe_CounterTable_1_counter_table_1.action_run := sw_IngressPipe_CounterTable_1_counter_table_1.action.IngressPipe_CounterTable_1_get_notification_cnt;
        call sw_IngressPipe_CounterTable_1_get_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 1bv1){
        sw_IngressPipe_CounterTable_1_counter_table_1.hit := true;
        sw_IngressPipe_CounterTable_1_counter_table_1.action_run := sw_IngressPipe_CounterTable_1_counter_table_1.action.IngressPipe_CounterTable_1_reset_notification_cnt;
        call sw_IngressPipe_CounterTable_1_reset_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 1bv1 && sw_hdr.lock.old_mode == 0bv1){
        sw_IngressPipe_CounterTable_1_counter_table_1.hit := true;
        sw_IngressPipe_CounterTable_1_counter_table_1.action_run := sw_IngressPipe_CounterTable_1_counter_table_1.action.IngressPipe_CounterTable_1_get_notification_cnt;
        call sw_IngressPipe_CounterTable_1_get_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 1bv1 && sw_hdr.lock.old_mode == 1bv1){
        sw_IngressPipe_CounterTable_1_counter_table_1.hit := true;
        sw_IngressPipe_CounterTable_1_counter_table_1.action_run := sw_IngressPipe_CounterTable_1_counter_table_1.action.IngressPipe_CounterTable_1_reset_notification_cnt;
        call sw_IngressPipe_CounterTable_1_reset_notification_cnt();
        goto sw_Exit;
    }
    if(!sw_IngressPipe_CounterTable_1_counter_table_1.hit){
        sw_IngressPipe_CounterTable_1_counter_table_1.action_run := sw_IngressPipe_CounterTable_1_counter_table_1.action.IngressPipe_CounterTable_1_nop;
        call sw_IngressPipe_CounterTable_1_nop();
        goto sw_Exit;
    }

    sw_Exit:
}

// sw_Action sw_IngressPipe_CounterTable_1_get_notification_cnt
procedure {:inline 1} sw_IngressPipe_CounterTable_1_get_notification_cnt()
	modifies sw_IngressPipe_CounterTable_1_notification_cnt_1, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_index, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_any, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_index0, sw___ra_ret_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_1_cmp_ncnt, sw_ig_md.agent_changed;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_CounterTable_1_cmp_ncnt := sw_IngressPipe_CounterTable_1_notification_cnt_1.read(sw_IngressPipe_CounterTable_1_notification_cnt_1, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_cmp_ncnt := sw_IngressPipe_CounterTable_1_cmp_ncnt.apply(sw___ra_val_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_cmp_ncnt);
    sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site := 1;
    call sw_IngressPipe_CounterTable_1_notification_cnt_1.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_CounterTable_1_cmp_ncnt);
    sw_ig_md.agent_changed := sw___ra_ret_IngressPipe_CounterTable_1_cmp_ncnt;
}

// sw_Action sw_IngressPipe_CounterTable_1_new_notification
procedure {:inline 1} sw_IngressPipe_CounterTable_1_new_notification()
	modifies sw_IngressPipe_CounterTable_1_notification_cnt_1, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_index, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_any, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_index0, sw___ra_ret_IngressPipe_CounterTable_1_count_ncnt, sw___ra_val_IngressPipe_CounterTable_1_count_ncnt;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_CounterTable_1_count_ncnt := sw_IngressPipe_CounterTable_1_notification_cnt_1.read(sw_IngressPipe_CounterTable_1_notification_cnt_1, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_CounterTable_1_count_ncnt := sw_IngressPipe_CounterTable_1_count_ncnt.apply(sw___ra_val_IngressPipe_CounterTable_1_count_ncnt);
    sw___ra_ret_IngressPipe_CounterTable_1_count_ncnt := sw___ra_val_IngressPipe_CounterTable_1_count_ncnt;
    sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site := 2;
    call sw_IngressPipe_CounterTable_1_notification_cnt_1.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_CounterTable_1_count_ncnt);
}

// sw_Action sw_IngressPipe_CounterTable_1_nop
procedure {:inline 1} sw_IngressPipe_CounterTable_1_nop()
{
}
function {:inline true}sw_IngressPipe_CounterTable_1_notification_cnt_1.read(sw_reg:[sw_lid_t]bv8, sw_index:sw_lid_t)returns (bv8) {sw_reg[sw_index]}
procedure {:inline 1} sw_IngressPipe_CounterTable_1_notification_cnt_1.write(sw_index:sw_lid_t, sw_value:bv8)
	modifies sw_IngressPipe_CounterTable_1_notification_cnt_1, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_index, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_any, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_index0;
{
    sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value := sw_IngressPipe_CounterTable_1_notification_cnt_1[sw_index];
    sw_IngressPipe_CounterTable_1_notification_cnt_1[sw_index] := sw_value;
    sw_IngressPipe_CounterTable_1_notification_cnt_1__last_index := sw_index;
    sw_IngressPipe_CounterTable_1_notification_cnt_1__last_value := sw_value;
    sw_IngressPipe_CounterTable_1_notification_cnt_1__last_write_site := sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site;
    sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_index0 := true;
        sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_old_value := sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value;
        sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value := sw_value;
    }
}

// sw_RegisterAction sw_IngressPipe_CounterTable_1_reset_ncnt.apply
procedure {:inline 1} sw_IngressPipe_CounterTable_1_reset_ncnt.apply(sw_value_in:bv8) returns (sw_value_out:bv8)
{
    var sw_value:bv8;
    sw_value := sw_value_in;
    sw_value := 0bv8;
    sw_value_out := sw_value;
}

// sw_Action sw_IngressPipe_CounterTable_1_reset_notification_cnt
procedure {:inline 1} sw_IngressPipe_CounterTable_1_reset_notification_cnt()
	modifies sw_IngressPipe_CounterTable_1_notification_cnt_1, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_index, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_any, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_index0, sw___ra_ret_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_1_reset_ncnt;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_CounterTable_1_reset_ncnt := sw_IngressPipe_CounterTable_1_notification_cnt_1.read(sw_IngressPipe_CounterTable_1_notification_cnt_1, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_CounterTable_1_reset_ncnt := sw_IngressPipe_CounterTable_1_reset_ncnt.apply(sw___ra_val_IngressPipe_CounterTable_1_reset_ncnt);
    sw___ra_ret_IngressPipe_CounterTable_1_reset_ncnt := sw___ra_val_IngressPipe_CounterTable_1_reset_ncnt;
    sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site := 3;
    call sw_IngressPipe_CounterTable_1_notification_cnt_1.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_CounterTable_1_reset_ncnt);
}

// sw_RegisterAction sw_IngressPipe_CounterTable_2_cmp_ncnt.apply
procedure {:inline 1} sw_IngressPipe_CounterTable_2_cmp_ncnt.apply(sw_value_in:bv8, sw_flag_in:bv1) returns (sw_value_out:bv8, sw_flag_out:bv1)
{
    var sw_value:bv8;
    var sw_flag:bv1;
    sw_value := sw_value_in;
    sw_flag := sw_flag_in;
    if((sw_value == sw_hdr.lock.ncnt)){
        sw_value := 0bv8;
        sw_flag := 1bv1;
    }
    else{
        sw_flag := 0bv1;
    }
    sw_value_out := sw_value;
    sw_flag_out := sw_flag;
}

// sw_RegisterAction sw_IngressPipe_CounterTable_2_count_ncnt.apply
procedure {:inline 1} sw_IngressPipe_CounterTable_2_count_ncnt.apply(sw_value_in:bv8) returns (sw_value_out:bv8)
{
    var sw_value:bv8;
    sw_value := sw_value_in;
    sw_value := add.bv8(sw_value, 1bv8);
    sw_value_out := sw_value;
}

// sw_Table sw_IngressPipe_CounterTable_2_counter_table_2
procedure {:inline 1} sw_IngressPipe_CounterTable_2_counter_table_2.apply()
	modifies sw_IngressPipe_CounterTable_2_counter_table_2.action_run, sw_IngressPipe_CounterTable_2_counter_table_2.hit, sw_IngressPipe_CounterTable_2_notification_cnt_2, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_index, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_any, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_index0, sw___ra_ret_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_2_count_ncnt, sw___ra_val_IngressPipe_CounterTable_2_reset_ncnt, sw_hdr.lock.mode, sw_hdr.lock.old_mode, sw_hdr.lock.type, sw_ig_md.agent_changed;
{
    sw_hdr.lock.type := sw_hdr.lock.type;
    sw_hdr.lock.mode := sw_hdr.lock.mode;
    sw_hdr.lock.old_mode := sw_hdr.lock.old_mode;
    sw_IngressPipe_CounterTable_2_counter_table_2.hit := false;
    if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 0bv1){
        sw_IngressPipe_CounterTable_2_counter_table_2.hit := true;
        sw_IngressPipe_CounterTable_2_counter_table_2.action_run := sw_IngressPipe_CounterTable_2_counter_table_2.action.IngressPipe_CounterTable_2_new_notification;
        call sw_IngressPipe_CounterTable_2_new_notification();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 1bv1){
        sw_IngressPipe_CounterTable_2_counter_table_2.hit := true;
        sw_IngressPipe_CounterTable_2_counter_table_2.action_run := sw_IngressPipe_CounterTable_2_counter_table_2.action.IngressPipe_CounterTable_2_new_notification;
        call sw_IngressPipe_CounterTable_2_new_notification();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 0bv1){
        sw_IngressPipe_CounterTable_2_counter_table_2.hit := true;
        sw_IngressPipe_CounterTable_2_counter_table_2.action_run := sw_IngressPipe_CounterTable_2_counter_table_2.action.IngressPipe_CounterTable_2_get_notification_cnt;
        call sw_IngressPipe_CounterTable_2_get_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 1bv1){
        sw_IngressPipe_CounterTable_2_counter_table_2.hit := true;
        sw_IngressPipe_CounterTable_2_counter_table_2.action_run := sw_IngressPipe_CounterTable_2_counter_table_2.action.IngressPipe_CounterTable_2_reset_notification_cnt;
        call sw_IngressPipe_CounterTable_2_reset_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 1bv1 && sw_hdr.lock.old_mode == 0bv1){
        sw_IngressPipe_CounterTable_2_counter_table_2.hit := true;
        sw_IngressPipe_CounterTable_2_counter_table_2.action_run := sw_IngressPipe_CounterTable_2_counter_table_2.action.IngressPipe_CounterTable_2_get_notification_cnt;
        call sw_IngressPipe_CounterTable_2_get_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 1bv1 && sw_hdr.lock.old_mode == 1bv1){
        sw_IngressPipe_CounterTable_2_counter_table_2.hit := true;
        sw_IngressPipe_CounterTable_2_counter_table_2.action_run := sw_IngressPipe_CounterTable_2_counter_table_2.action.IngressPipe_CounterTable_2_reset_notification_cnt;
        call sw_IngressPipe_CounterTable_2_reset_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 0bv1){
        sw_IngressPipe_CounterTable_2_counter_table_2.hit := true;
        sw_IngressPipe_CounterTable_2_counter_table_2.action_run := sw_IngressPipe_CounterTable_2_counter_table_2.action.IngressPipe_CounterTable_2_get_notification_cnt;
        call sw_IngressPipe_CounterTable_2_get_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 1bv1){
        sw_IngressPipe_CounterTable_2_counter_table_2.hit := true;
        sw_IngressPipe_CounterTable_2_counter_table_2.action_run := sw_IngressPipe_CounterTable_2_counter_table_2.action.IngressPipe_CounterTable_2_reset_notification_cnt;
        call sw_IngressPipe_CounterTable_2_reset_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 1bv1 && sw_hdr.lock.old_mode == 0bv1){
        sw_IngressPipe_CounterTable_2_counter_table_2.hit := true;
        sw_IngressPipe_CounterTable_2_counter_table_2.action_run := sw_IngressPipe_CounterTable_2_counter_table_2.action.IngressPipe_CounterTable_2_get_notification_cnt;
        call sw_IngressPipe_CounterTable_2_get_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 1bv1 && sw_hdr.lock.old_mode == 1bv1){
        sw_IngressPipe_CounterTable_2_counter_table_2.hit := true;
        sw_IngressPipe_CounterTable_2_counter_table_2.action_run := sw_IngressPipe_CounterTable_2_counter_table_2.action.IngressPipe_CounterTable_2_reset_notification_cnt;
        call sw_IngressPipe_CounterTable_2_reset_notification_cnt();
        goto sw_Exit;
    }
    if(!sw_IngressPipe_CounterTable_2_counter_table_2.hit){
        sw_IngressPipe_CounterTable_2_counter_table_2.action_run := sw_IngressPipe_CounterTable_2_counter_table_2.action.IngressPipe_CounterTable_2_nop;
        call sw_IngressPipe_CounterTable_2_nop();
        goto sw_Exit;
    }

    sw_Exit:
}

// sw_Action sw_IngressPipe_CounterTable_2_get_notification_cnt
procedure {:inline 1} sw_IngressPipe_CounterTable_2_get_notification_cnt()
	modifies sw_IngressPipe_CounterTable_2_notification_cnt_2, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_index, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_any, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_index0, sw___ra_ret_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_2_cmp_ncnt, sw_ig_md.agent_changed;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_CounterTable_2_cmp_ncnt := sw_IngressPipe_CounterTable_2_notification_cnt_2.read(sw_IngressPipe_CounterTable_2_notification_cnt_2, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_cmp_ncnt := sw_IngressPipe_CounterTable_2_cmp_ncnt.apply(sw___ra_val_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_cmp_ncnt);
    sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site := 1;
    call sw_IngressPipe_CounterTable_2_notification_cnt_2.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_CounterTable_2_cmp_ncnt);
    sw_ig_md.agent_changed := sw___ra_ret_IngressPipe_CounterTable_2_cmp_ncnt;
}

// sw_Action sw_IngressPipe_CounterTable_2_new_notification
procedure {:inline 1} sw_IngressPipe_CounterTable_2_new_notification()
	modifies sw_IngressPipe_CounterTable_2_notification_cnt_2, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_index, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_any, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_index0, sw___ra_ret_IngressPipe_CounterTable_2_count_ncnt, sw___ra_val_IngressPipe_CounterTable_2_count_ncnt;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_CounterTable_2_count_ncnt := sw_IngressPipe_CounterTable_2_notification_cnt_2.read(sw_IngressPipe_CounterTable_2_notification_cnt_2, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_CounterTable_2_count_ncnt := sw_IngressPipe_CounterTable_2_count_ncnt.apply(sw___ra_val_IngressPipe_CounterTable_2_count_ncnt);
    sw___ra_ret_IngressPipe_CounterTable_2_count_ncnt := sw___ra_val_IngressPipe_CounterTable_2_count_ncnt;
    sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site := 2;
    call sw_IngressPipe_CounterTable_2_notification_cnt_2.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_CounterTable_2_count_ncnt);
}

// sw_Action sw_IngressPipe_CounterTable_2_nop
procedure {:inline 1} sw_IngressPipe_CounterTable_2_nop()
{
}
function {:inline true}sw_IngressPipe_CounterTable_2_notification_cnt_2.read(sw_reg:[sw_lid_t]bv8, sw_index:sw_lid_t)returns (bv8) {sw_reg[sw_index]}
procedure {:inline 1} sw_IngressPipe_CounterTable_2_notification_cnt_2.write(sw_index:sw_lid_t, sw_value:bv8)
	modifies sw_IngressPipe_CounterTable_2_notification_cnt_2, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_index, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_any, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_index0;
{
    sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value := sw_IngressPipe_CounterTable_2_notification_cnt_2[sw_index];
    sw_IngressPipe_CounterTable_2_notification_cnt_2[sw_index] := sw_value;
    sw_IngressPipe_CounterTable_2_notification_cnt_2__last_index := sw_index;
    sw_IngressPipe_CounterTable_2_notification_cnt_2__last_value := sw_value;
    sw_IngressPipe_CounterTable_2_notification_cnt_2__last_write_site := sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site;
    sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_index0 := true;
        sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_old_value := sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value;
        sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_value := sw_value;
    }
}

// sw_RegisterAction sw_IngressPipe_CounterTable_2_reset_ncnt.apply
procedure {:inline 1} sw_IngressPipe_CounterTable_2_reset_ncnt.apply(sw_value_in:bv8) returns (sw_value_out:bv8)
{
    var sw_value:bv8;
    sw_value := sw_value_in;
    sw_value := 0bv8;
    sw_value_out := sw_value;
}

// sw_Action sw_IngressPipe_CounterTable_2_reset_notification_cnt
procedure {:inline 1} sw_IngressPipe_CounterTable_2_reset_notification_cnt()
	modifies sw_IngressPipe_CounterTable_2_notification_cnt_2, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_index, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_any, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_index0, sw___ra_ret_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_2_reset_ncnt;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_CounterTable_2_reset_ncnt := sw_IngressPipe_CounterTable_2_notification_cnt_2.read(sw_IngressPipe_CounterTable_2_notification_cnt_2, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_CounterTable_2_reset_ncnt := sw_IngressPipe_CounterTable_2_reset_ncnt.apply(sw___ra_val_IngressPipe_CounterTable_2_reset_ncnt);
    sw___ra_ret_IngressPipe_CounterTable_2_reset_ncnt := sw___ra_val_IngressPipe_CounterTable_2_reset_ncnt;
    sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site := 3;
    call sw_IngressPipe_CounterTable_2_notification_cnt_2.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_CounterTable_2_reset_ncnt);
}

// sw_RegisterAction sw_IngressPipe_CounterTable_3_cmp_ncnt.apply
procedure {:inline 1} sw_IngressPipe_CounterTable_3_cmp_ncnt.apply(sw_value_in:bv8, sw_flag_in:bv1) returns (sw_value_out:bv8, sw_flag_out:bv1)
{
    var sw_value:bv8;
    var sw_flag:bv1;
    sw_value := sw_value_in;
    sw_flag := sw_flag_in;
    if((sw_value == sw_hdr.lock.ncnt)){
        sw_value := 0bv8;
        sw_flag := 1bv1;
    }
    else{
        sw_flag := 0bv1;
    }
    sw_value_out := sw_value;
    sw_flag_out := sw_flag;
}

// sw_RegisterAction sw_IngressPipe_CounterTable_3_count_ncnt.apply
procedure {:inline 1} sw_IngressPipe_CounterTable_3_count_ncnt.apply(sw_value_in:bv8) returns (sw_value_out:bv8)
{
    var sw_value:bv8;
    sw_value := sw_value_in;
    sw_value := add.bv8(sw_value, 1bv8);
    sw_value_out := sw_value;
}

// sw_Table sw_IngressPipe_CounterTable_3_counter_table_3
procedure {:inline 1} sw_IngressPipe_CounterTable_3_counter_table_3.apply()
	modifies sw_IngressPipe_CounterTable_3_counter_table_3.action_run, sw_IngressPipe_CounterTable_3_counter_table_3.hit, sw_IngressPipe_CounterTable_3_notification_cnt_3, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_index, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_any, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_index0, sw___ra_ret_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_3_count_ncnt, sw___ra_val_IngressPipe_CounterTable_3_reset_ncnt, sw_hdr.lock.mode, sw_hdr.lock.old_mode, sw_hdr.lock.type, sw_ig_md.agent_changed;
{
    sw_hdr.lock.type := sw_hdr.lock.type;
    sw_hdr.lock.mode := sw_hdr.lock.mode;
    sw_hdr.lock.old_mode := sw_hdr.lock.old_mode;
    sw_IngressPipe_CounterTable_3_counter_table_3.hit := false;
    if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 0bv1){
        sw_IngressPipe_CounterTable_3_counter_table_3.hit := true;
        sw_IngressPipe_CounterTable_3_counter_table_3.action_run := sw_IngressPipe_CounterTable_3_counter_table_3.action.IngressPipe_CounterTable_3_new_notification;
        call sw_IngressPipe_CounterTable_3_new_notification();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 1bv1){
        sw_IngressPipe_CounterTable_3_counter_table_3.hit := true;
        sw_IngressPipe_CounterTable_3_counter_table_3.action_run := sw_IngressPipe_CounterTable_3_counter_table_3.action.IngressPipe_CounterTable_3_new_notification;
        call sw_IngressPipe_CounterTable_3_new_notification();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 0bv1){
        sw_IngressPipe_CounterTable_3_counter_table_3.hit := true;
        sw_IngressPipe_CounterTable_3_counter_table_3.action_run := sw_IngressPipe_CounterTable_3_counter_table_3.action.IngressPipe_CounterTable_3_get_notification_cnt;
        call sw_IngressPipe_CounterTable_3_get_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 1bv1){
        sw_IngressPipe_CounterTable_3_counter_table_3.hit := true;
        sw_IngressPipe_CounterTable_3_counter_table_3.action_run := sw_IngressPipe_CounterTable_3_counter_table_3.action.IngressPipe_CounterTable_3_reset_notification_cnt;
        call sw_IngressPipe_CounterTable_3_reset_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 1bv1 && sw_hdr.lock.old_mode == 0bv1){
        sw_IngressPipe_CounterTable_3_counter_table_3.hit := true;
        sw_IngressPipe_CounterTable_3_counter_table_3.action_run := sw_IngressPipe_CounterTable_3_counter_table_3.action.IngressPipe_CounterTable_3_get_notification_cnt;
        call sw_IngressPipe_CounterTable_3_get_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 1bv1 && sw_hdr.lock.old_mode == 1bv1){
        sw_IngressPipe_CounterTable_3_counter_table_3.hit := true;
        sw_IngressPipe_CounterTable_3_counter_table_3.action_run := sw_IngressPipe_CounterTable_3_counter_table_3.action.IngressPipe_CounterTable_3_reset_notification_cnt;
        call sw_IngressPipe_CounterTable_3_reset_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 0bv1){
        sw_IngressPipe_CounterTable_3_counter_table_3.hit := true;
        sw_IngressPipe_CounterTable_3_counter_table_3.action_run := sw_IngressPipe_CounterTable_3_counter_table_3.action.IngressPipe_CounterTable_3_get_notification_cnt;
        call sw_IngressPipe_CounterTable_3_get_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 0bv1 && sw_hdr.lock.old_mode == 1bv1){
        sw_IngressPipe_CounterTable_3_counter_table_3.hit := true;
        sw_IngressPipe_CounterTable_3_counter_table_3.action_run := sw_IngressPipe_CounterTable_3_counter_table_3.action.IngressPipe_CounterTable_3_reset_notification_cnt;
        call sw_IngressPipe_CounterTable_3_reset_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 1bv1 && sw_hdr.lock.old_mode == 0bv1){
        sw_IngressPipe_CounterTable_3_counter_table_3.hit := true;
        sw_IngressPipe_CounterTable_3_counter_table_3.action_run := sw_IngressPipe_CounterTable_3_counter_table_3.action.IngressPipe_CounterTable_3_get_notification_cnt;
        call sw_IngressPipe_CounterTable_3_get_notification_cnt();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 1bv1 && sw_hdr.lock.old_mode == 1bv1){
        sw_IngressPipe_CounterTable_3_counter_table_3.hit := true;
        sw_IngressPipe_CounterTable_3_counter_table_3.action_run := sw_IngressPipe_CounterTable_3_counter_table_3.action.IngressPipe_CounterTable_3_reset_notification_cnt;
        call sw_IngressPipe_CounterTable_3_reset_notification_cnt();
        goto sw_Exit;
    }
    if(!sw_IngressPipe_CounterTable_3_counter_table_3.hit){
        sw_IngressPipe_CounterTable_3_counter_table_3.action_run := sw_IngressPipe_CounterTable_3_counter_table_3.action.IngressPipe_CounterTable_3_nop;
        call sw_IngressPipe_CounterTable_3_nop();
        goto sw_Exit;
    }

    sw_Exit:
}

// sw_Action sw_IngressPipe_CounterTable_3_get_notification_cnt
procedure {:inline 1} sw_IngressPipe_CounterTable_3_get_notification_cnt()
	modifies sw_IngressPipe_CounterTable_3_notification_cnt_3, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_index, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_any, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_index0, sw___ra_ret_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_3_cmp_ncnt, sw_ig_md.agent_changed;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_CounterTable_3_cmp_ncnt := sw_IngressPipe_CounterTable_3_notification_cnt_3.read(sw_IngressPipe_CounterTable_3_notification_cnt_3, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_cmp_ncnt := sw_IngressPipe_CounterTable_3_cmp_ncnt.apply(sw___ra_val_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_cmp_ncnt);
    sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site := 1;
    call sw_IngressPipe_CounterTable_3_notification_cnt_3.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_CounterTable_3_cmp_ncnt);
    sw_ig_md.agent_changed := sw___ra_ret_IngressPipe_CounterTable_3_cmp_ncnt;
}

// sw_Action sw_IngressPipe_CounterTable_3_new_notification
procedure {:inline 1} sw_IngressPipe_CounterTable_3_new_notification()
	modifies sw_IngressPipe_CounterTable_3_notification_cnt_3, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_index, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_any, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_index0, sw___ra_ret_IngressPipe_CounterTable_3_count_ncnt, sw___ra_val_IngressPipe_CounterTable_3_count_ncnt;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_CounterTable_3_count_ncnt := sw_IngressPipe_CounterTable_3_notification_cnt_3.read(sw_IngressPipe_CounterTable_3_notification_cnt_3, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_CounterTable_3_count_ncnt := sw_IngressPipe_CounterTable_3_count_ncnt.apply(sw___ra_val_IngressPipe_CounterTable_3_count_ncnt);
    sw___ra_ret_IngressPipe_CounterTable_3_count_ncnt := sw___ra_val_IngressPipe_CounterTable_3_count_ncnt;
    sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site := 2;
    call sw_IngressPipe_CounterTable_3_notification_cnt_3.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_CounterTable_3_count_ncnt);
}

// sw_Action sw_IngressPipe_CounterTable_3_nop
procedure {:inline 1} sw_IngressPipe_CounterTable_3_nop()
{
}
function {:inline true}sw_IngressPipe_CounterTable_3_notification_cnt_3.read(sw_reg:[sw_lid_t]bv8, sw_index:sw_lid_t)returns (bv8) {sw_reg[sw_index]}
procedure {:inline 1} sw_IngressPipe_CounterTable_3_notification_cnt_3.write(sw_index:sw_lid_t, sw_value:bv8)
	modifies sw_IngressPipe_CounterTable_3_notification_cnt_3, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_index, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_any, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_index0;
{
    sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value := sw_IngressPipe_CounterTable_3_notification_cnt_3[sw_index];
    sw_IngressPipe_CounterTable_3_notification_cnt_3[sw_index] := sw_value;
    sw_IngressPipe_CounterTable_3_notification_cnt_3__last_index := sw_index;
    sw_IngressPipe_CounterTable_3_notification_cnt_3__last_value := sw_value;
    sw_IngressPipe_CounterTable_3_notification_cnt_3__last_write_site := sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site;
    sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_index0 := true;
        sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_old_value := sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value;
        sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_value := sw_value;
    }
}

// sw_RegisterAction sw_IngressPipe_CounterTable_3_reset_ncnt.apply
procedure {:inline 1} sw_IngressPipe_CounterTable_3_reset_ncnt.apply(sw_value_in:bv8) returns (sw_value_out:bv8)
{
    var sw_value:bv8;
    sw_value := sw_value_in;
    sw_value := 0bv8;
    sw_value_out := sw_value;
}

// sw_Action sw_IngressPipe_CounterTable_3_reset_notification_cnt
procedure {:inline 1} sw_IngressPipe_CounterTable_3_reset_notification_cnt()
	modifies sw_IngressPipe_CounterTable_3_notification_cnt_3, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_index, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_any, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_index0, sw___ra_ret_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_3_reset_ncnt;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_CounterTable_3_reset_ncnt := sw_IngressPipe_CounterTable_3_notification_cnt_3.read(sw_IngressPipe_CounterTable_3_notification_cnt_3, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_CounterTable_3_reset_ncnt := sw_IngressPipe_CounterTable_3_reset_ncnt.apply(sw___ra_val_IngressPipe_CounterTable_3_reset_ncnt);
    sw___ra_ret_IngressPipe_CounterTable_3_reset_ncnt := sw___ra_val_IngressPipe_CounterTable_3_reset_ncnt;
    sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site := 3;
    call sw_IngressPipe_CounterTable_3_notification_cnt_3.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_CounterTable_3_reset_ncnt);
}

// sw_Action sw_IngressPipe_LockOperation_1_fwd_to_agent
procedure {:inline 1} sw_IngressPipe_LockOperation_1_fwd_to_agent()
	modifies sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0, sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent, sw_hdr.lock.agent;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent := sw_IngressPipe_LockOperation_1_lock_agent_array_1.read(sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent := sw_IngressPipe_LockOperation_1_get_lock_agent.apply(sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent);
    sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site := 3;
    call sw_IngressPipe_LockOperation_1_lock_agent_array_1.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent);
    sw_hdr.lock.agent := sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent;
}

// sw_RegisterAction sw_IngressPipe_LockOperation_1_get_lock_agent.apply
procedure {:inline 1} sw_IngressPipe_LockOperation_1_get_lock_agent.apply(sw_value_in:sw_host_t, sw_agent_in:sw_host_t) returns (sw_value_out:sw_host_t, sw_agent_out:sw_host_t)
{
    var sw_value:sw_host_t;
    var sw_agent:sw_host_t;
    sw_value := sw_value_in;
    sw_agent := sw_agent_in;
    sw_agent := sw_value;
    sw_value_out := sw_value;
    sw_agent_out := sw_agent;
}
function {:inline true}sw_IngressPipe_LockOperation_1_lock_agent_array_1.read(sw_reg:[sw_lid_t]sw_host_t, sw_index:sw_lid_t)returns (sw_host_t) {sw_reg[sw_index]}
procedure {:inline 1} sw_IngressPipe_LockOperation_1_lock_agent_array_1.write(sw_index:sw_lid_t, sw_value:sw_host_t)
	modifies sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0;
{
    sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value := sw_IngressPipe_LockOperation_1_lock_agent_array_1[sw_index];
    sw_IngressPipe_LockOperation_1_lock_agent_array_1[sw_index] := sw_value;
    sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index := sw_index;
    sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value := sw_value;
    sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site := sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site;
    sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0 := true;
        sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value := sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value;
        sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value := sw_value;
    }
}

// sw_Table sw_IngressPipe_LockOperation_1_lock_operation_1
procedure {:inline 1} sw_IngressPipe_LockOperation_1_lock_operation_1.apply()
	modifies sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0, sw_IngressPipe_LockOperation_1_lock_operation_1.action_run, sw_IngressPipe_LockOperation_1_lock_operation_1.hit, sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent, sw_hdr.lock.agent, sw_hdr.lock.mode, sw_hdr.lock.multicasted, sw_hdr.lock.transferred, sw_hdr.lock.type, sw_ig_md.lock_agent, sw_ig_md.lock_free_mode, sw_ig_md.lock_rw_mode;
{
    sw_hdr.lock.type := sw_hdr.lock.type;
    sw_hdr.lock.mode := sw_hdr.lock.mode;
    sw_ig_md.lock_free_mode := sw_ig_md.lock_free_mode;
    sw_ig_md.lock_rw_mode := sw_ig_md.lock_rw_mode;
    sw_IngressPipe_LockOperation_1_lock_operation_1.hit := false;
    if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 0bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_new_agent;
        call sw_IngressPipe_LockOperation_1_new_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 0bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_new_agent;
        call sw_IngressPipe_LockOperation_1_new_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 0bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_new_agent;
        call sw_IngressPipe_LockOperation_1_new_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 0bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_new_agent;
        call sw_IngressPipe_LockOperation_1_new_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_mcast_to_agent;
        call sw_IngressPipe_LockOperation_1_mcast_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_fwd_to_agent;
        call sw_IngressPipe_LockOperation_1_fwd_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_fwd_to_agent;
        call sw_IngressPipe_LockOperation_1_fwd_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_fwd_to_agent;
        call sw_IngressPipe_LockOperation_1_fwd_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 4bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_fwd_to_agent;
        call sw_IngressPipe_LockOperation_1_fwd_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 4bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_fwd_to_agent;
        call sw_IngressPipe_LockOperation_1_fwd_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_transfer_agent;
        call sw_IngressPipe_LockOperation_1_transfer_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_transfer_agent;
        call sw_IngressPipe_LockOperation_1_transfer_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_transfer_agent;
        call sw_IngressPipe_LockOperation_1_transfer_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_transfer_agent;
        call sw_IngressPipe_LockOperation_1_transfer_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_reset_agent;
        call sw_IngressPipe_LockOperation_1_reset_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_reset_agent;
        call sw_IngressPipe_LockOperation_1_reset_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_reset_agent;
        call sw_IngressPipe_LockOperation_1_reset_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_1_lock_operation_1.hit := true;
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_reset_agent;
        call sw_IngressPipe_LockOperation_1_reset_agent();
        goto sw_Exit;
    }
    if(!sw_IngressPipe_LockOperation_1_lock_operation_1.hit){
        sw_IngressPipe_LockOperation_1_lock_operation_1.action_run := sw_IngressPipe_LockOperation_1_lock_operation_1.action.IngressPipe_LockOperation_1_nop;
        call sw_IngressPipe_LockOperation_1_nop();
        goto sw_Exit;
    }

    sw_Exit:
}

// sw_Action sw_IngressPipe_LockOperation_1_mcast_to_agent
procedure {:inline 1} sw_IngressPipe_LockOperation_1_mcast_to_agent()
	modifies sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0, sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent, sw_hdr.lock.agent, sw_hdr.lock.multicasted, sw_hdr.lock.type;
{
    sw_hdr.lock.multicasted := 1bv1;
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent := sw_IngressPipe_LockOperation_1_lock_agent_array_1.read(sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent := sw_IngressPipe_LockOperation_1_get_lock_agent.apply(sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent);
    sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site := 2;
    call sw_IngressPipe_LockOperation_1_lock_agent_array_1.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent);
    sw_hdr.lock.agent := sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent;
    sw_hdr.lock.type := 3bv8;
}

// sw_Action sw_IngressPipe_LockOperation_1_new_agent
procedure {:inline 1} sw_IngressPipe_LockOperation_1_new_agent()
	modifies sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0, sw___ra_ret_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent, sw_hdr.lock.transferred, sw_hdr.lock.type;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent := sw_IngressPipe_LockOperation_1_lock_agent_array_1.read(sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent := sw_IngressPipe_LockOperation_1_set_lock_agent.apply(sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent);
    sw___ra_ret_IngressPipe_LockOperation_1_set_lock_agent := sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent;
    sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site := 1;
    call sw_IngressPipe_LockOperation_1_lock_agent_array_1.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent);
    sw_hdr.lock.type := 2bv8;
    sw_hdr.lock.transferred := 0bv1;
}

// sw_Action sw_IngressPipe_LockOperation_1_nop
procedure {:inline 1} sw_IngressPipe_LockOperation_1_nop()
{
}

// sw_Action sw_IngressPipe_LockOperation_1_reset_agent
procedure {:inline 1} sw_IngressPipe_LockOperation_1_reset_agent()
	modifies sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0, sw___ra_ret_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent, sw_ig_md.lock_agent;
{
    sw_ig_md.lock_agent := 0bv8;
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent := sw_IngressPipe_LockOperation_1_lock_agent_array_1.read(sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent := sw_IngressPipe_LockOperation_1_set_lock_agent.apply(sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent);
    sw___ra_ret_IngressPipe_LockOperation_1_set_lock_agent := sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent;
    sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site := 5;
    call sw_IngressPipe_LockOperation_1_lock_agent_array_1.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent);
}

// sw_RegisterAction sw_IngressPipe_LockOperation_1_set_lock_agent.apply
procedure {:inline 1} sw_IngressPipe_LockOperation_1_set_lock_agent.apply(sw_value_in:sw_host_t) returns (sw_value_out:sw_host_t)
{
    var sw_value:sw_host_t;
    sw_value := sw_value_in;
    sw_value := sw_ig_md.lock_agent;
    sw_value_out := sw_value;
}

// sw_Action sw_IngressPipe_LockOperation_1_transfer_agent
procedure {:inline 1} sw_IngressPipe_LockOperation_1_transfer_agent()
	modifies sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0, sw___ra_ret_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent, sw_hdr.lock.transferred, sw_hdr.lock.type;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent := sw_IngressPipe_LockOperation_1_lock_agent_array_1.read(sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent := sw_IngressPipe_LockOperation_1_set_lock_agent.apply(sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent);
    sw___ra_ret_IngressPipe_LockOperation_1_set_lock_agent := sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent;
    sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site := 4;
    call sw_IngressPipe_LockOperation_1_lock_agent_array_1.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent);
    sw_hdr.lock.type := 2bv8;
    sw_hdr.lock.transferred := 1bv1;
}

// sw_Action sw_IngressPipe_LockOperation_2_fwd_to_agent
procedure {:inline 1} sw_IngressPipe_LockOperation_2_fwd_to_agent()
	modifies sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0, sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent, sw_hdr.lock.agent;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent := sw_IngressPipe_LockOperation_2_lock_agent_array_2.read(sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent := sw_IngressPipe_LockOperation_2_get_lock_agent.apply(sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent);
    sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site := 3;
    call sw_IngressPipe_LockOperation_2_lock_agent_array_2.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent);
    sw_hdr.lock.agent := sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent;
}

// sw_RegisterAction sw_IngressPipe_LockOperation_2_get_lock_agent.apply
procedure {:inline 1} sw_IngressPipe_LockOperation_2_get_lock_agent.apply(sw_value_in:sw_host_t, sw_agent_in:sw_host_t) returns (sw_value_out:sw_host_t, sw_agent_out:sw_host_t)
{
    var sw_value:sw_host_t;
    var sw_agent:sw_host_t;
    sw_value := sw_value_in;
    sw_agent := sw_agent_in;
    sw_agent := sw_value;
    sw_value_out := sw_value;
    sw_agent_out := sw_agent;
}
function {:inline true}sw_IngressPipe_LockOperation_2_lock_agent_array_2.read(sw_reg:[sw_lid_t]sw_host_t, sw_index:sw_lid_t)returns (sw_host_t) {sw_reg[sw_index]}
procedure {:inline 1} sw_IngressPipe_LockOperation_2_lock_agent_array_2.write(sw_index:sw_lid_t, sw_value:sw_host_t)
	modifies sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0;
{
    sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value := sw_IngressPipe_LockOperation_2_lock_agent_array_2[sw_index];
    sw_IngressPipe_LockOperation_2_lock_agent_array_2[sw_index] := sw_value;
    sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index := sw_index;
    sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value := sw_value;
    sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site := sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site;
    sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0 := true;
        sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value := sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value;
        sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value := sw_value;
    }
}

// sw_Table sw_IngressPipe_LockOperation_2_lock_operation_2
procedure {:inline 1} sw_IngressPipe_LockOperation_2_lock_operation_2.apply()
	modifies sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0, sw_IngressPipe_LockOperation_2_lock_operation_2.action_run, sw_IngressPipe_LockOperation_2_lock_operation_2.hit, sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent, sw_hdr.lock.agent, sw_hdr.lock.mode, sw_hdr.lock.multicasted, sw_hdr.lock.transferred, sw_hdr.lock.type, sw_ig_md.lock_agent, sw_ig_md.lock_free_mode, sw_ig_md.lock_rw_mode;
{
    sw_hdr.lock.type := sw_hdr.lock.type;
    sw_hdr.lock.mode := sw_hdr.lock.mode;
    sw_ig_md.lock_free_mode := sw_ig_md.lock_free_mode;
    sw_ig_md.lock_rw_mode := sw_ig_md.lock_rw_mode;
    sw_IngressPipe_LockOperation_2_lock_operation_2.hit := false;
    if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 0bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_new_agent;
        call sw_IngressPipe_LockOperation_2_new_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 0bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_new_agent;
        call sw_IngressPipe_LockOperation_2_new_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 0bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_new_agent;
        call sw_IngressPipe_LockOperation_2_new_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 0bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_new_agent;
        call sw_IngressPipe_LockOperation_2_new_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_mcast_to_agent;
        call sw_IngressPipe_LockOperation_2_mcast_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_fwd_to_agent;
        call sw_IngressPipe_LockOperation_2_fwd_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_fwd_to_agent;
        call sw_IngressPipe_LockOperation_2_fwd_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_fwd_to_agent;
        call sw_IngressPipe_LockOperation_2_fwd_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 4bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_fwd_to_agent;
        call sw_IngressPipe_LockOperation_2_fwd_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 4bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_fwd_to_agent;
        call sw_IngressPipe_LockOperation_2_fwd_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_transfer_agent;
        call sw_IngressPipe_LockOperation_2_transfer_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_transfer_agent;
        call sw_IngressPipe_LockOperation_2_transfer_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_transfer_agent;
        call sw_IngressPipe_LockOperation_2_transfer_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_transfer_agent;
        call sw_IngressPipe_LockOperation_2_transfer_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_reset_agent;
        call sw_IngressPipe_LockOperation_2_reset_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_reset_agent;
        call sw_IngressPipe_LockOperation_2_reset_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_reset_agent;
        call sw_IngressPipe_LockOperation_2_reset_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_2_lock_operation_2.hit := true;
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_reset_agent;
        call sw_IngressPipe_LockOperation_2_reset_agent();
        goto sw_Exit;
    }
    if(!sw_IngressPipe_LockOperation_2_lock_operation_2.hit){
        sw_IngressPipe_LockOperation_2_lock_operation_2.action_run := sw_IngressPipe_LockOperation_2_lock_operation_2.action.IngressPipe_LockOperation_2_nop;
        call sw_IngressPipe_LockOperation_2_nop();
        goto sw_Exit;
    }

    sw_Exit:
}

// sw_Action sw_IngressPipe_LockOperation_2_mcast_to_agent
procedure {:inline 1} sw_IngressPipe_LockOperation_2_mcast_to_agent()
	modifies sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0, sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent, sw_hdr.lock.agent, sw_hdr.lock.multicasted, sw_hdr.lock.type;
{
    sw_hdr.lock.multicasted := 1bv1;
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent := sw_IngressPipe_LockOperation_2_lock_agent_array_2.read(sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent := sw_IngressPipe_LockOperation_2_get_lock_agent.apply(sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent);
    sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site := 2;
    call sw_IngressPipe_LockOperation_2_lock_agent_array_2.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent);
    sw_hdr.lock.agent := sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent;
    sw_hdr.lock.type := 3bv8;
}

// sw_Action sw_IngressPipe_LockOperation_2_new_agent
procedure {:inline 1} sw_IngressPipe_LockOperation_2_new_agent()
	modifies sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0, sw___ra_ret_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent, sw_hdr.lock.transferred, sw_hdr.lock.type;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent := sw_IngressPipe_LockOperation_2_lock_agent_array_2.read(sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent := sw_IngressPipe_LockOperation_2_set_lock_agent.apply(sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent);
    sw___ra_ret_IngressPipe_LockOperation_2_set_lock_agent := sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent;
    sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site := 1;
    call sw_IngressPipe_LockOperation_2_lock_agent_array_2.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent);
    sw_hdr.lock.type := 2bv8;
    sw_hdr.lock.transferred := 0bv1;
}

// sw_Action sw_IngressPipe_LockOperation_2_nop
procedure {:inline 1} sw_IngressPipe_LockOperation_2_nop()
{
}

// sw_Action sw_IngressPipe_LockOperation_2_reset_agent
procedure {:inline 1} sw_IngressPipe_LockOperation_2_reset_agent()
	modifies sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0, sw___ra_ret_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent, sw_ig_md.lock_agent;
{
    sw_ig_md.lock_agent := 0bv8;
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent := sw_IngressPipe_LockOperation_2_lock_agent_array_2.read(sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent := sw_IngressPipe_LockOperation_2_set_lock_agent.apply(sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent);
    sw___ra_ret_IngressPipe_LockOperation_2_set_lock_agent := sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent;
    sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site := 5;
    call sw_IngressPipe_LockOperation_2_lock_agent_array_2.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent);
}

// sw_RegisterAction sw_IngressPipe_LockOperation_2_set_lock_agent.apply
procedure {:inline 1} sw_IngressPipe_LockOperation_2_set_lock_agent.apply(sw_value_in:sw_host_t) returns (sw_value_out:sw_host_t)
{
    var sw_value:sw_host_t;
    sw_value := sw_value_in;
    sw_value := sw_ig_md.lock_agent;
    sw_value_out := sw_value;
}

// sw_Action sw_IngressPipe_LockOperation_2_transfer_agent
procedure {:inline 1} sw_IngressPipe_LockOperation_2_transfer_agent()
	modifies sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0, sw___ra_ret_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent, sw_hdr.lock.transferred, sw_hdr.lock.type;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent := sw_IngressPipe_LockOperation_2_lock_agent_array_2.read(sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent := sw_IngressPipe_LockOperation_2_set_lock_agent.apply(sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent);
    sw___ra_ret_IngressPipe_LockOperation_2_set_lock_agent := sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent;
    sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site := 4;
    call sw_IngressPipe_LockOperation_2_lock_agent_array_2.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent);
    sw_hdr.lock.type := 2bv8;
    sw_hdr.lock.transferred := 1bv1;
}

// sw_Action sw_IngressPipe_LockOperation_3_fwd_to_agent
procedure {:inline 1} sw_IngressPipe_LockOperation_3_fwd_to_agent()
	modifies sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0, sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent, sw_hdr.lock.agent;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent := sw_IngressPipe_LockOperation_3_lock_agent_array_3.read(sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent := sw_IngressPipe_LockOperation_3_get_lock_agent.apply(sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent);
    sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site := 3;
    call sw_IngressPipe_LockOperation_3_lock_agent_array_3.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent);
    sw_hdr.lock.agent := sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent;
}

// sw_RegisterAction sw_IngressPipe_LockOperation_3_get_lock_agent.apply
procedure {:inline 1} sw_IngressPipe_LockOperation_3_get_lock_agent.apply(sw_value_in:sw_host_t, sw_agent_in:sw_host_t) returns (sw_value_out:sw_host_t, sw_agent_out:sw_host_t)
{
    var sw_value:sw_host_t;
    var sw_agent:sw_host_t;
    sw_value := sw_value_in;
    sw_agent := sw_agent_in;
    sw_agent := sw_value;
    sw_value_out := sw_value;
    sw_agent_out := sw_agent;
}
function {:inline true}sw_IngressPipe_LockOperation_3_lock_agent_array_3.read(sw_reg:[sw_lid_t]sw_host_t, sw_index:sw_lid_t)returns (sw_host_t) {sw_reg[sw_index]}
procedure {:inline 1} sw_IngressPipe_LockOperation_3_lock_agent_array_3.write(sw_index:sw_lid_t, sw_value:sw_host_t)
	modifies sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0;
{
    sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value := sw_IngressPipe_LockOperation_3_lock_agent_array_3[sw_index];
    sw_IngressPipe_LockOperation_3_lock_agent_array_3[sw_index] := sw_value;
    sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index := sw_index;
    sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value := sw_value;
    sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site := sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site;
    sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0 := true;
        sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value := sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value;
        sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value := sw_value;
    }
}

// sw_Table sw_IngressPipe_LockOperation_3_lock_operation_3
procedure {:inline 1} sw_IngressPipe_LockOperation_3_lock_operation_3.apply()
	modifies sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0, sw_IngressPipe_LockOperation_3_lock_operation_3.action_run, sw_IngressPipe_LockOperation_3_lock_operation_3.hit, sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent, sw_hdr.lock.agent, sw_hdr.lock.mode, sw_hdr.lock.multicasted, sw_hdr.lock.transferred, sw_hdr.lock.type, sw_ig_md.lock_agent, sw_ig_md.lock_free_mode, sw_ig_md.lock_rw_mode;
{
    sw_hdr.lock.type := sw_hdr.lock.type;
    sw_hdr.lock.mode := sw_hdr.lock.mode;
    sw_ig_md.lock_free_mode := sw_ig_md.lock_free_mode;
    sw_ig_md.lock_rw_mode := sw_ig_md.lock_rw_mode;
    sw_IngressPipe_LockOperation_3_lock_operation_3.hit := false;
    if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 0bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_new_agent;
        call sw_IngressPipe_LockOperation_3_new_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 0bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_new_agent;
        call sw_IngressPipe_LockOperation_3_new_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 0bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_new_agent;
        call sw_IngressPipe_LockOperation_3_new_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 0bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_new_agent;
        call sw_IngressPipe_LockOperation_3_new_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_mcast_to_agent;
        call sw_IngressPipe_LockOperation_3_mcast_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_fwd_to_agent;
        call sw_IngressPipe_LockOperation_3_fwd_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_fwd_to_agent;
        call sw_IngressPipe_LockOperation_3_fwd_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_fwd_to_agent;
        call sw_IngressPipe_LockOperation_3_fwd_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 4bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_fwd_to_agent;
        call sw_IngressPipe_LockOperation_3_fwd_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 4bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_fwd_to_agent;
        call sw_IngressPipe_LockOperation_3_fwd_to_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_transfer_agent;
        call sw_IngressPipe_LockOperation_3_transfer_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_transfer_agent;
        call sw_IngressPipe_LockOperation_3_transfer_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_transfer_agent;
        call sw_IngressPipe_LockOperation_3_transfer_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_transfer_agent;
        call sw_IngressPipe_LockOperation_3_transfer_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_reset_agent;
        call sw_IngressPipe_LockOperation_3_reset_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 0bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_reset_agent;
        call sw_IngressPipe_LockOperation_3_reset_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 0bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_reset_agent;
        call sw_IngressPipe_LockOperation_3_reset_agent();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_hdr.lock.mode == 1bv1 && sw_ig_md.lock_free_mode == 1bv1 && sw_ig_md.lock_rw_mode == 1bv1){
        sw_IngressPipe_LockOperation_3_lock_operation_3.hit := true;
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_reset_agent;
        call sw_IngressPipe_LockOperation_3_reset_agent();
        goto sw_Exit;
    }
    if(!sw_IngressPipe_LockOperation_3_lock_operation_3.hit){
        sw_IngressPipe_LockOperation_3_lock_operation_3.action_run := sw_IngressPipe_LockOperation_3_lock_operation_3.action.IngressPipe_LockOperation_3_nop;
        call sw_IngressPipe_LockOperation_3_nop();
        goto sw_Exit;
    }

    sw_Exit:
}

// sw_Action sw_IngressPipe_LockOperation_3_mcast_to_agent
procedure {:inline 1} sw_IngressPipe_LockOperation_3_mcast_to_agent()
	modifies sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0, sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent, sw_hdr.lock.agent, sw_hdr.lock.multicasted, sw_hdr.lock.type;
{
    sw_hdr.lock.multicasted := 1bv1;
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent := sw_IngressPipe_LockOperation_3_lock_agent_array_3.read(sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent := sw_IngressPipe_LockOperation_3_get_lock_agent.apply(sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent);
    sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site := 2;
    call sw_IngressPipe_LockOperation_3_lock_agent_array_3.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent);
    sw_hdr.lock.agent := sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent;
    sw_hdr.lock.type := 3bv8;
}

// sw_Action sw_IngressPipe_LockOperation_3_new_agent
procedure {:inline 1} sw_IngressPipe_LockOperation_3_new_agent()
	modifies sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0, sw___ra_ret_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent, sw_hdr.lock.transferred, sw_hdr.lock.type;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent := sw_IngressPipe_LockOperation_3_lock_agent_array_3.read(sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent := sw_IngressPipe_LockOperation_3_set_lock_agent.apply(sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent);
    sw___ra_ret_IngressPipe_LockOperation_3_set_lock_agent := sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent;
    sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site := 1;
    call sw_IngressPipe_LockOperation_3_lock_agent_array_3.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent);
    sw_hdr.lock.type := 2bv8;
    sw_hdr.lock.transferred := 0bv1;
}

// sw_Action sw_IngressPipe_LockOperation_3_nop
procedure {:inline 1} sw_IngressPipe_LockOperation_3_nop()
{
}

// sw_Action sw_IngressPipe_LockOperation_3_reset_agent
procedure {:inline 1} sw_IngressPipe_LockOperation_3_reset_agent()
	modifies sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0, sw___ra_ret_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent, sw_ig_md.lock_agent;
{
    sw_ig_md.lock_agent := 0bv8;
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent := sw_IngressPipe_LockOperation_3_lock_agent_array_3.read(sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent := sw_IngressPipe_LockOperation_3_set_lock_agent.apply(sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent);
    sw___ra_ret_IngressPipe_LockOperation_3_set_lock_agent := sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent;
    sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site := 5;
    call sw_IngressPipe_LockOperation_3_lock_agent_array_3.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent);
}

// sw_RegisterAction sw_IngressPipe_LockOperation_3_set_lock_agent.apply
procedure {:inline 1} sw_IngressPipe_LockOperation_3_set_lock_agent.apply(sw_value_in:sw_host_t) returns (sw_value_out:sw_host_t)
{
    var sw_value:sw_host_t;
    sw_value := sw_value_in;
    sw_value := sw_ig_md.lock_agent;
    sw_value_out := sw_value;
}

// sw_Action sw_IngressPipe_LockOperation_3_transfer_agent
procedure {:inline 1} sw_IngressPipe_LockOperation_3_transfer_agent()
	modifies sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0, sw___ra_ret_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent, sw_hdr.lock.transferred, sw_hdr.lock.type;
{
    assume (sw_ig_md.lock_index == 0bv32);
    sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent := sw_IngressPipe_LockOperation_3_lock_agent_array_3.read(sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_ig_md.lock_index);
    call sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent := sw_IngressPipe_LockOperation_3_set_lock_agent.apply(sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent);
    sw___ra_ret_IngressPipe_LockOperation_3_set_lock_agent := sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent;
    sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site := 4;
    call sw_IngressPipe_LockOperation_3_lock_agent_array_3.write(sw_ig_md.lock_index, sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent);
    sw_hdr.lock.type := 2bv8;
    sw_hdr.lock.transferred := 1bv1;
}

// sw_RegisterAction sw_IngressPipe_acquire.apply
procedure {:inline 1} sw_IngressPipe_acquire.apply(sw_value_in:bv1, sw_state_in:bv1) returns (sw_value_out:bv1, sw_state_out:bv1)
{
    var sw_value:bv1;
    var sw_state:bv1;
    sw_value := sw_value_in;
    sw_state := sw_state_in;
    sw_state := sw_value;
    sw_value := 1bv1;
    sw_value_out := sw_value;
    sw_state_out := sw_state;
}

// sw_Action sw_IngressPipe_acquire_lock
procedure {:inline 1} sw_IngressPipe_acquire_lock()
	modifies sw_IngressPipe_lock_free_mode_array, sw_IngressPipe_lock_free_mode_array__last0_old_value, sw_IngressPipe_lock_free_mode_array__last0_value, sw_IngressPipe_lock_free_mode_array__last_index, sw_IngressPipe_lock_free_mode_array__last_old_value, sw_IngressPipe_lock_free_mode_array__last_value, sw_IngressPipe_lock_free_mode_array__last_write_site, sw_IngressPipe_lock_free_mode_array__next_write_site, sw_IngressPipe_lock_free_mode_array__wrote_any, sw_IngressPipe_lock_free_mode_array__wrote_index0, sw___ra_ret_IngressPipe_acquire, sw___ra_val_IngressPipe_acquire, sw_ig_md.lock_free_mode;
{
    sw___ra_val_IngressPipe_acquire := sw_IngressPipe_lock_free_mode_array.read(sw_IngressPipe_lock_free_mode_array, sw_hdr.lock.id);
    call sw___ra_val_IngressPipe_acquire, sw___ra_ret_IngressPipe_acquire := sw_IngressPipe_acquire.apply(sw___ra_val_IngressPipe_acquire, sw___ra_ret_IngressPipe_acquire);
    sw_IngressPipe_lock_free_mode_array__next_write_site := 1;
    call sw_IngressPipe_lock_free_mode_array.write(sw_hdr.lock.id, sw___ra_val_IngressPipe_acquire);
    sw_ig_md.lock_free_mode := sw___ra_ret_IngressPipe_acquire;
}

// sw_Table sw_IngressPipe_acquire_table
procedure {:inline 1} sw_IngressPipe_acquire_table.apply()
	modifies sw_IngressPipe_acquire_table.action_run, sw_IngressPipe_acquire_table.hit, sw_IngressPipe_lock_free_mode_array, sw_IngressPipe_lock_free_mode_array__last0_old_value, sw_IngressPipe_lock_free_mode_array__last0_value, sw_IngressPipe_lock_free_mode_array__last_index, sw_IngressPipe_lock_free_mode_array__last_old_value, sw_IngressPipe_lock_free_mode_array__last_value, sw_IngressPipe_lock_free_mode_array__last_write_site, sw_IngressPipe_lock_free_mode_array__next_write_site, sw_IngressPipe_lock_free_mode_array__wrote_any, sw_IngressPipe_lock_free_mode_array__wrote_index0, sw___ra_ret_IngressPipe_acquire, sw___ra_val_IngressPipe_acquire, sw_ig_md.lock_free_mode;
{
    sw_IngressPipe_acquire_table.hit := false;
    goto sw_action_IngressPipe_acquire_lock;

    sw_action_IngressPipe_acquire_lock:
    assume sw_IngressPipe_acquire_table.action_run == sw_IngressPipe_acquire_table.action.IngressPipe_acquire_lock;
    call sw_IngressPipe_acquire_lock();
    goto sw_Exit;

    sw_Exit:
}

// sw_RegisterAction sw_IngressPipe_get_mode.apply
procedure {:inline 1} sw_IngressPipe_get_mode.apply(sw_value_in:bv1, sw_state_in:bv1) returns (sw_value_out:bv1, sw_state_out:bv1)
{
    var sw_value:bv1;
    var sw_state:bv1;
    sw_value := sw_value_in;
    sw_state := sw_state_in;
    sw_state := sw_value;
    sw_value_out := sw_value;
    sw_state_out := sw_state;
}

// sw_Action sw_IngressPipe_lock_excl
procedure {:inline 1} sw_IngressPipe_lock_excl()
	modifies sw_IngressPipe_lock_rw_mode_array, sw_IngressPipe_lock_rw_mode_array__last0_old_value, sw_IngressPipe_lock_rw_mode_array__last0_value, sw_IngressPipe_lock_rw_mode_array__last_index, sw_IngressPipe_lock_rw_mode_array__last_old_value, sw_IngressPipe_lock_rw_mode_array__last_value, sw_IngressPipe_lock_rw_mode_array__last_write_site, sw_IngressPipe_lock_rw_mode_array__next_write_site, sw_IngressPipe_lock_rw_mode_array__wrote_any, sw_IngressPipe_lock_rw_mode_array__wrote_index0, sw___ra_ret_IngressPipe_set_excl, sw___ra_val_IngressPipe_set_excl, sw_ig_md.lock_rw_mode;
{
    sw___ra_val_IngressPipe_set_excl := sw_IngressPipe_lock_rw_mode_array.read(sw_IngressPipe_lock_rw_mode_array, sw_hdr.lock.id);
    call sw___ra_val_IngressPipe_set_excl, sw___ra_ret_IngressPipe_set_excl := sw_IngressPipe_set_excl.apply(sw___ra_val_IngressPipe_set_excl, sw___ra_ret_IngressPipe_set_excl);
    sw_IngressPipe_lock_rw_mode_array__next_write_site := 2;
    call sw_IngressPipe_lock_rw_mode_array.write(sw_hdr.lock.id, sw___ra_val_IngressPipe_set_excl);
    sw_ig_md.lock_rw_mode := sw___ra_ret_IngressPipe_set_excl;
}
function {:inline true}sw_IngressPipe_lock_free_mode_array.read(sw_reg:[sw_lid_t]bv1, sw_index:sw_lid_t)returns (bv1) {sw_reg[sw_index]}
procedure {:inline 1} sw_IngressPipe_lock_free_mode_array.write(sw_index:sw_lid_t, sw_value:bv1)
	modifies sw_IngressPipe_lock_free_mode_array, sw_IngressPipe_lock_free_mode_array__last0_old_value, sw_IngressPipe_lock_free_mode_array__last0_value, sw_IngressPipe_lock_free_mode_array__last_index, sw_IngressPipe_lock_free_mode_array__last_old_value, sw_IngressPipe_lock_free_mode_array__last_value, sw_IngressPipe_lock_free_mode_array__last_write_site, sw_IngressPipe_lock_free_mode_array__wrote_any, sw_IngressPipe_lock_free_mode_array__wrote_index0;
{
    sw_IngressPipe_lock_free_mode_array__last_old_value := sw_IngressPipe_lock_free_mode_array[sw_index];
    sw_IngressPipe_lock_free_mode_array[sw_index] := sw_value;
    sw_IngressPipe_lock_free_mode_array__last_index := sw_index;
    sw_IngressPipe_lock_free_mode_array__last_value := sw_value;
    sw_IngressPipe_lock_free_mode_array__last_write_site := sw_IngressPipe_lock_free_mode_array__next_write_site;
    sw_IngressPipe_lock_free_mode_array__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_IngressPipe_lock_free_mode_array__wrote_index0 := true;
        sw_IngressPipe_lock_free_mode_array__last0_old_value := sw_IngressPipe_lock_free_mode_array__last_old_value;
        sw_IngressPipe_lock_free_mode_array__last0_value := sw_value;
    }
}

// sw_Action sw_IngressPipe_lock_mode_get
procedure {:inline 1} sw_IngressPipe_lock_mode_get()
	modifies sw_IngressPipe_lock_rw_mode_array, sw_IngressPipe_lock_rw_mode_array__last0_old_value, sw_IngressPipe_lock_rw_mode_array__last0_value, sw_IngressPipe_lock_rw_mode_array__last_index, sw_IngressPipe_lock_rw_mode_array__last_old_value, sw_IngressPipe_lock_rw_mode_array__last_value, sw_IngressPipe_lock_rw_mode_array__last_write_site, sw_IngressPipe_lock_rw_mode_array__next_write_site, sw_IngressPipe_lock_rw_mode_array__wrote_any, sw_IngressPipe_lock_rw_mode_array__wrote_index0, sw___ra_ret_IngressPipe_get_mode, sw___ra_val_IngressPipe_get_mode, sw_ig_md.lock_rw_mode;
{
    sw___ra_val_IngressPipe_get_mode := sw_IngressPipe_lock_rw_mode_array.read(sw_IngressPipe_lock_rw_mode_array, sw_hdr.lock.id);
    call sw___ra_val_IngressPipe_get_mode, sw___ra_ret_IngressPipe_get_mode := sw_IngressPipe_get_mode.apply(sw___ra_val_IngressPipe_get_mode, sw___ra_ret_IngressPipe_get_mode);
    sw_IngressPipe_lock_rw_mode_array__next_write_site := 3;
    call sw_IngressPipe_lock_rw_mode_array.write(sw_hdr.lock.id, sw___ra_val_IngressPipe_get_mode);
    sw_ig_md.lock_rw_mode := sw___ra_ret_IngressPipe_get_mode;
}
function {:inline true}sw_IngressPipe_lock_rw_mode_array.read(sw_reg:[sw_lid_t]bv1, sw_index:sw_lid_t)returns (bv1) {sw_reg[sw_index]}
procedure {:inline 1} sw_IngressPipe_lock_rw_mode_array.write(sw_index:sw_lid_t, sw_value:bv1)
	modifies sw_IngressPipe_lock_rw_mode_array, sw_IngressPipe_lock_rw_mode_array__last0_old_value, sw_IngressPipe_lock_rw_mode_array__last0_value, sw_IngressPipe_lock_rw_mode_array__last_index, sw_IngressPipe_lock_rw_mode_array__last_old_value, sw_IngressPipe_lock_rw_mode_array__last_value, sw_IngressPipe_lock_rw_mode_array__last_write_site, sw_IngressPipe_lock_rw_mode_array__wrote_any, sw_IngressPipe_lock_rw_mode_array__wrote_index0;
{
    sw_IngressPipe_lock_rw_mode_array__last_old_value := sw_IngressPipe_lock_rw_mode_array[sw_index];
    sw_IngressPipe_lock_rw_mode_array[sw_index] := sw_value;
    sw_IngressPipe_lock_rw_mode_array__last_index := sw_index;
    sw_IngressPipe_lock_rw_mode_array__last_value := sw_value;
    sw_IngressPipe_lock_rw_mode_array__last_write_site := sw_IngressPipe_lock_rw_mode_array__next_write_site;
    sw_IngressPipe_lock_rw_mode_array__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_IngressPipe_lock_rw_mode_array__wrote_index0 := true;
        sw_IngressPipe_lock_rw_mode_array__last0_old_value := sw_IngressPipe_lock_rw_mode_array__last_old_value;
        sw_IngressPipe_lock_rw_mode_array__last0_value := sw_value;
    }
}

// sw_Action sw_IngressPipe_lock_shared
procedure {:inline 1} sw_IngressPipe_lock_shared()
	modifies sw_IngressPipe_lock_rw_mode_array, sw_IngressPipe_lock_rw_mode_array__last0_old_value, sw_IngressPipe_lock_rw_mode_array__last0_value, sw_IngressPipe_lock_rw_mode_array__last_index, sw_IngressPipe_lock_rw_mode_array__last_old_value, sw_IngressPipe_lock_rw_mode_array__last_value, sw_IngressPipe_lock_rw_mode_array__last_write_site, sw_IngressPipe_lock_rw_mode_array__next_write_site, sw_IngressPipe_lock_rw_mode_array__wrote_any, sw_IngressPipe_lock_rw_mode_array__wrote_index0, sw___ra_ret_IngressPipe_set_shared, sw___ra_val_IngressPipe_set_shared, sw_ig_md.lock_rw_mode;
{
    sw___ra_val_IngressPipe_set_shared := sw_IngressPipe_lock_rw_mode_array.read(sw_IngressPipe_lock_rw_mode_array, sw_hdr.lock.id);
    call sw___ra_val_IngressPipe_set_shared, sw___ra_ret_IngressPipe_set_shared := sw_IngressPipe_set_shared.apply(sw___ra_val_IngressPipe_set_shared, sw___ra_ret_IngressPipe_set_shared);
    sw_IngressPipe_lock_rw_mode_array__next_write_site := 1;
    call sw_IngressPipe_lock_rw_mode_array.write(sw_hdr.lock.id, sw___ra_val_IngressPipe_set_shared);
    sw_ig_md.lock_rw_mode := sw___ra_ret_IngressPipe_set_shared;
}

// sw_Action sw_IngressPipe_nop
procedure {:inline 1} sw_IngressPipe_nop()
{
}

// sw_RegisterAction sw_IngressPipe_release.apply
procedure {:inline 1} sw_IngressPipe_release.apply(sw_value_in:bv1, sw_state_in:bv1) returns (sw_value_out:bv1, sw_state_out:bv1)
{
    var sw_value:bv1;
    var sw_state:bv1;
    sw_value := sw_value_in;
    sw_state := sw_state_in;
    sw_state := sw_value;
    sw_value := 0bv1;
    sw_value_out := sw_value;
    sw_state_out := sw_state;
}

// sw_Action sw_IngressPipe_release_lock
procedure {:inline 1} sw_IngressPipe_release_lock()
	modifies sw_IngressPipe_lock_free_mode_array, sw_IngressPipe_lock_free_mode_array__last0_old_value, sw_IngressPipe_lock_free_mode_array__last0_value, sw_IngressPipe_lock_free_mode_array__last_index, sw_IngressPipe_lock_free_mode_array__last_old_value, sw_IngressPipe_lock_free_mode_array__last_value, sw_IngressPipe_lock_free_mode_array__last_write_site, sw_IngressPipe_lock_free_mode_array__next_write_site, sw_IngressPipe_lock_free_mode_array__wrote_any, sw_IngressPipe_lock_free_mode_array__wrote_index0, sw___ra_ret_IngressPipe_release, sw___ra_val_IngressPipe_release, sw_ig_md.lock_free_mode;
{
    sw___ra_val_IngressPipe_release := sw_IngressPipe_lock_free_mode_array.read(sw_IngressPipe_lock_free_mode_array, sw_hdr.lock.id);
    call sw___ra_val_IngressPipe_release, sw___ra_ret_IngressPipe_release := sw_IngressPipe_release.apply(sw___ra_val_IngressPipe_release, sw___ra_ret_IngressPipe_release);
    sw_IngressPipe_lock_free_mode_array__next_write_site := 2;
    call sw_IngressPipe_lock_free_mode_array.write(sw_hdr.lock.id, sw___ra_val_IngressPipe_release);
    sw_ig_md.lock_free_mode := sw___ra_ret_IngressPipe_release;
}

// sw_Table sw_IngressPipe_release_table
procedure {:inline 1} sw_IngressPipe_release_table.apply()
	modifies sw_IngressPipe_lock_free_mode_array, sw_IngressPipe_lock_free_mode_array__last0_old_value, sw_IngressPipe_lock_free_mode_array__last0_value, sw_IngressPipe_lock_free_mode_array__last_index, sw_IngressPipe_lock_free_mode_array__last_old_value, sw_IngressPipe_lock_free_mode_array__last_value, sw_IngressPipe_lock_free_mode_array__last_write_site, sw_IngressPipe_lock_free_mode_array__next_write_site, sw_IngressPipe_lock_free_mode_array__wrote_any, sw_IngressPipe_lock_free_mode_array__wrote_index0, sw_IngressPipe_release_table.action_run, sw_IngressPipe_release_table.hit, sw___ra_ret_IngressPipe_release, sw___ra_val_IngressPipe_release, sw_ig_md.lock_free_mode;
{
    sw_IngressPipe_release_table.hit := false;
    goto sw_action_IngressPipe_release_lock;

    sw_action_IngressPipe_release_lock:
    assume sw_IngressPipe_release_table.action_run == sw_IngressPipe_release_table.action.IngressPipe_release_lock;
    call sw_IngressPipe_release_lock();
    goto sw_Exit;

    sw_Exit:
}

// sw_Table sw_IngressPipe_rw_table
procedure {:inline 1} sw_IngressPipe_rw_table.apply()
	modifies sw_IngressPipe_lock_rw_mode_array, sw_IngressPipe_lock_rw_mode_array__last0_old_value, sw_IngressPipe_lock_rw_mode_array__last0_value, sw_IngressPipe_lock_rw_mode_array__last_index, sw_IngressPipe_lock_rw_mode_array__last_old_value, sw_IngressPipe_lock_rw_mode_array__last_value, sw_IngressPipe_lock_rw_mode_array__last_write_site, sw_IngressPipe_lock_rw_mode_array__next_write_site, sw_IngressPipe_lock_rw_mode_array__wrote_any, sw_IngressPipe_lock_rw_mode_array__wrote_index0, sw_IngressPipe_rw_table.action_run, sw_IngressPipe_rw_table.hit, sw___ra_ret_IngressPipe_get_mode, sw___ra_ret_IngressPipe_set_excl, sw___ra_ret_IngressPipe_set_shared, sw___ra_val_IngressPipe_get_mode, sw___ra_val_IngressPipe_set_excl, sw___ra_val_IngressPipe_set_shared, sw_hdr.lock.mode, sw_hdr.lock.type, sw_ig_md.lock_free_mode, sw_ig_md.lock_rw_mode;
{
    sw_hdr.lock.type := sw_hdr.lock.type;
    sw_ig_md.lock_free_mode := sw_ig_md.lock_free_mode;
    sw_hdr.lock.mode := sw_hdr.lock.mode;
    sw_IngressPipe_rw_table.hit := false;
    if(sw_hdr.lock.type == 5bv8 && sw_ig_md.lock_free_mode == 1bv1 && sw_hdr.lock.mode == 0bv1){
        sw_IngressPipe_rw_table.hit := true;
        sw_IngressPipe_rw_table.action_run := sw_IngressPipe_rw_table.action.IngressPipe_lock_shared;
        call sw_IngressPipe_lock_shared();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 5bv8 && sw_ig_md.lock_free_mode == 1bv1 && sw_hdr.lock.mode == 1bv1){
        sw_IngressPipe_rw_table.hit := true;
        sw_IngressPipe_rw_table.action_run := sw_IngressPipe_rw_table.action.IngressPipe_lock_excl;
        call sw_IngressPipe_lock_excl();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_ig_md.lock_free_mode == 1bv1 && sw_hdr.lock.mode == 0bv1){
        sw_IngressPipe_rw_table.hit := true;
        sw_IngressPipe_rw_table.action_run := sw_IngressPipe_rw_table.action.IngressPipe_lock_shared;
        call sw_IngressPipe_lock_shared();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 6bv8 && sw_ig_md.lock_free_mode == 1bv1 && sw_hdr.lock.mode == 1bv1){
        sw_IngressPipe_rw_table.hit := true;
        sw_IngressPipe_rw_table.action_run := sw_IngressPipe_rw_table.action.IngressPipe_lock_excl;
        call sw_IngressPipe_lock_excl();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_ig_md.lock_free_mode == 0bv1 && sw_hdr.lock.mode == 0bv1){
        sw_IngressPipe_rw_table.hit := true;
        sw_IngressPipe_rw_table.action_run := sw_IngressPipe_rw_table.action.IngressPipe_lock_shared;
        call sw_IngressPipe_lock_shared();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_ig_md.lock_free_mode == 0bv1 && sw_hdr.lock.mode == 1bv1){
        sw_IngressPipe_rw_table.hit := true;
        sw_IngressPipe_rw_table.action_run := sw_IngressPipe_rw_table.action.IngressPipe_lock_excl;
        call sw_IngressPipe_lock_excl();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_ig_md.lock_free_mode == 1bv1 && sw_hdr.lock.mode == 0bv1){
        sw_IngressPipe_rw_table.hit := true;
        sw_IngressPipe_rw_table.action_run := sw_IngressPipe_rw_table.action.IngressPipe_lock_mode_get;
        call sw_IngressPipe_lock_mode_get();
        goto sw_Exit;
    }
    else if(sw_hdr.lock.type == 1bv8 && sw_ig_md.lock_free_mode == 1bv1 && sw_hdr.lock.mode == 1bv1){
        sw_IngressPipe_rw_table.hit := true;
        sw_IngressPipe_rw_table.action_run := sw_IngressPipe_rw_table.action.IngressPipe_lock_mode_get;
        call sw_IngressPipe_lock_mode_get();
        goto sw_Exit;
    }
    if(!sw_IngressPipe_rw_table.hit){
        sw_IngressPipe_rw_table.action_run := sw_IngressPipe_rw_table.action.IngressPipe_nop;
        call sw_IngressPipe_nop();
        goto sw_Exit;
    }

    sw_Exit:
}

// sw_RegisterAction sw_IngressPipe_set_excl.apply
procedure {:inline 1} sw_IngressPipe_set_excl.apply(sw_value_in:bv1, sw_state_in:bv1) returns (sw_value_out:bv1, sw_state_out:bv1)
{
    var sw_value:bv1;
    var sw_state:bv1;
    sw_value := sw_value_in;
    sw_state := sw_state_in;
    sw_state := sw_value;
    sw_value := 1bv1;
    sw_value_out := sw_value;
    sw_state_out := sw_state;
}

// sw_RegisterAction sw_IngressPipe_set_shared.apply
procedure {:inline 1} sw_IngressPipe_set_shared.apply(sw_value_in:bv1, sw_state_in:bv1) returns (sw_value_out:bv1, sw_state_out:bv1)
{
    var sw_value:bv1;
    var sw_state:bv1;
    sw_value := sw_value_in;
    sw_state := sw_state_in;
    sw_state := sw_value;
    sw_value := 0bv1;
    sw_value_out := sw_value;
    sw_state_out := sw_state;
}
procedure {:inline 1} sw_accept()
{
}
procedure {:inline 1} sw_main()
	modifies sw_IngressPipe_CounterTable_1_counter_table_1.action_run, sw_IngressPipe_CounterTable_1_counter_table_1.hit, sw_IngressPipe_CounterTable_1_notification_cnt_1, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_index, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_any, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_index0, sw_IngressPipe_CounterTable_2_counter_table_2.action_run, sw_IngressPipe_CounterTable_2_counter_table_2.hit, sw_IngressPipe_CounterTable_2_notification_cnt_2, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_index, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_any, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_index0, sw_IngressPipe_CounterTable_3_counter_table_3.action_run, sw_IngressPipe_CounterTable_3_counter_table_3.hit, sw_IngressPipe_CounterTable_3_notification_cnt_3, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_index, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_any, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_index0, sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0, sw_IngressPipe_LockOperation_1_lock_operation_1.action_run, sw_IngressPipe_LockOperation_1_lock_operation_1.hit, sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0, sw_IngressPipe_LockOperation_2_lock_operation_2.action_run, sw_IngressPipe_LockOperation_2_lock_operation_2.hit, sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0, sw_IngressPipe_LockOperation_3_lock_operation_3.action_run, sw_IngressPipe_LockOperation_3_lock_operation_3.hit, sw_IngressPipe_acquire_table.action_run, sw_IngressPipe_acquire_table.hit, sw_IngressPipe_lock_free_mode_array, sw_IngressPipe_lock_free_mode_array__last0_old_value, sw_IngressPipe_lock_free_mode_array__last0_value, sw_IngressPipe_lock_free_mode_array__last_index, sw_IngressPipe_lock_free_mode_array__last_old_value, sw_IngressPipe_lock_free_mode_array__last_value, sw_IngressPipe_lock_free_mode_array__last_write_site, sw_IngressPipe_lock_free_mode_array__next_write_site, sw_IngressPipe_lock_free_mode_array__wrote_any, sw_IngressPipe_lock_free_mode_array__wrote_index0, sw_IngressPipe_lock_rw_mode_array, sw_IngressPipe_lock_rw_mode_array__last0_old_value, sw_IngressPipe_lock_rw_mode_array__last0_value, sw_IngressPipe_lock_rw_mode_array__last_index, sw_IngressPipe_lock_rw_mode_array__last_old_value, sw_IngressPipe_lock_rw_mode_array__last_value, sw_IngressPipe_lock_rw_mode_array__last_write_site, sw_IngressPipe_lock_rw_mode_array__next_write_site, sw_IngressPipe_lock_rw_mode_array__wrote_any, sw_IngressPipe_lock_rw_mode_array__wrote_index0, sw_IngressPipe_release_table.action_run, sw_IngressPipe_release_table.hit, sw_IngressPipe_rw_table.action_run, sw_IngressPipe_rw_table.hit, sw___ra_ret_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_ret_IngressPipe_acquire, sw___ra_ret_IngressPipe_get_mode, sw___ra_ret_IngressPipe_release, sw___ra_ret_IngressPipe_set_excl, sw___ra_ret_IngressPipe_set_shared, sw___ra_val_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_1_count_ncnt, sw___ra_val_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_2_count_ncnt, sw___ra_val_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_3_count_ncnt, sw___ra_val_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_val_IngressPipe_acquire, sw___ra_val_IngressPipe_get_mode, sw___ra_val_IngressPipe_release, sw___ra_val_IngressPipe_set_excl, sw___ra_val_IngressPipe_set_shared, sw_drop, sw_eg_md.is_roce, sw_eg_md.pkt_psn, sw_hdr.lock.agent, sw_hdr.lock.mode, sw_hdr.lock.multicasted, sw_hdr.lock.old_mode, sw_hdr.lock.transferred, sw_hdr.lock.type, sw_ig_md.agent_changed, sw_ig_md.is_roce, sw_ig_md.lock_agent, sw_ig_md.lock_free_mode, sw_ig_md.lock_index, sw_ig_md.lock_out_of_range, sw_ig_md.lock_rw_mode, sw_ig_md.pkt_psn, sw_isValid;
{
    call sw_pipe();
    if(sw_forward == false){
        sw_drop := true;
    }
}
procedure sw_mainProcedure()
	modifies sw_IngressPipe_CounterTable_1_counter_table_1.action_run, sw_IngressPipe_CounterTable_1_counter_table_1.hit, sw_IngressPipe_CounterTable_1_notification_cnt_1, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_index, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_any, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_index0, sw_IngressPipe_CounterTable_2_counter_table_2.action_run, sw_IngressPipe_CounterTable_2_counter_table_2.hit, sw_IngressPipe_CounterTable_2_notification_cnt_2, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_index, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_any, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_index0, sw_IngressPipe_CounterTable_3_counter_table_3.action_run, sw_IngressPipe_CounterTable_3_counter_table_3.hit, sw_IngressPipe_CounterTable_3_notification_cnt_3, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_index, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_any, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_index0, sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0, sw_IngressPipe_LockOperation_1_lock_operation_1.action_run, sw_IngressPipe_LockOperation_1_lock_operation_1.hit, sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0, sw_IngressPipe_LockOperation_2_lock_operation_2.action_run, sw_IngressPipe_LockOperation_2_lock_operation_2.hit, sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0, sw_IngressPipe_LockOperation_3_lock_operation_3.action_run, sw_IngressPipe_LockOperation_3_lock_operation_3.hit, sw_IngressPipe_acquire_table.action_run, sw_IngressPipe_acquire_table.hit, sw_IngressPipe_lock_free_mode_array, sw_IngressPipe_lock_free_mode_array__last0_old_value, sw_IngressPipe_lock_free_mode_array__last0_value, sw_IngressPipe_lock_free_mode_array__last_index, sw_IngressPipe_lock_free_mode_array__last_old_value, sw_IngressPipe_lock_free_mode_array__last_value, sw_IngressPipe_lock_free_mode_array__last_write_site, sw_IngressPipe_lock_free_mode_array__next_write_site, sw_IngressPipe_lock_free_mode_array__wrote_any, sw_IngressPipe_lock_free_mode_array__wrote_index0, sw_IngressPipe_lock_rw_mode_array, sw_IngressPipe_lock_rw_mode_array__last0_old_value, sw_IngressPipe_lock_rw_mode_array__last0_value, sw_IngressPipe_lock_rw_mode_array__last_index, sw_IngressPipe_lock_rw_mode_array__last_old_value, sw_IngressPipe_lock_rw_mode_array__last_value, sw_IngressPipe_lock_rw_mode_array__last_write_site, sw_IngressPipe_lock_rw_mode_array__next_write_site, sw_IngressPipe_lock_rw_mode_array__wrote_any, sw_IngressPipe_lock_rw_mode_array__wrote_index0, sw_IngressPipe_release_table.action_run, sw_IngressPipe_release_table.hit, sw_IngressPipe_rw_table.action_run, sw_IngressPipe_rw_table.hit, sw___ra_ret_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_ret_IngressPipe_acquire, sw___ra_ret_IngressPipe_get_mode, sw___ra_ret_IngressPipe_release, sw___ra_ret_IngressPipe_set_excl, sw___ra_ret_IngressPipe_set_shared, sw___ra_val_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_1_count_ncnt, sw___ra_val_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_2_count_ncnt, sw___ra_val_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_3_count_ncnt, sw___ra_val_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_val_IngressPipe_acquire, sw___ra_val_IngressPipe_get_mode, sw___ra_val_IngressPipe_release, sw___ra_val_IngressPipe_set_excl, sw___ra_val_IngressPipe_set_shared, sw_drop, sw_eg_md.is_roce, sw_eg_md.pkt_psn, sw_hdr.lock.agent, sw_hdr.lock.mode, sw_hdr.lock.multicasted, sw_hdr.lock.old_mode, sw_hdr.lock.transferred, sw_hdr.lock.type, sw_ig_md.agent_changed, sw_ig_md.is_roce, sw_ig_md.lock_agent, sw_ig_md.lock_free_mode, sw_ig_md.lock_index, sw_ig_md.lock_out_of_range, sw_ig_md.lock_rw_mode, sw_ig_md.pkt_psn, sw_isValid, sw_p4b_checksum_error, sw_p4b_checksum_updated, sw_p4b_checksum_verified, sw_p4b_clone_e2e, sw_p4b_clone_i2e, sw_p4b_clone_i2i, sw_p4b_digest, sw_p4b_recirculate;
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
procedure sw_packet_in.extract(sw_header:sw_Ref);
    ensures (sw_isValid[sw_header] == true);
	modifies sw_isValid;
procedure {:inline 1} sw_pipe()
	modifies sw_IngressPipe_CounterTable_1_counter_table_1.action_run, sw_IngressPipe_CounterTable_1_counter_table_1.hit, sw_IngressPipe_CounterTable_1_notification_cnt_1, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_index, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_any, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_index0, sw_IngressPipe_CounterTable_2_counter_table_2.action_run, sw_IngressPipe_CounterTable_2_counter_table_2.hit, sw_IngressPipe_CounterTable_2_notification_cnt_2, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_index, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_any, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_index0, sw_IngressPipe_CounterTable_3_counter_table_3.action_run, sw_IngressPipe_CounterTable_3_counter_table_3.hit, sw_IngressPipe_CounterTable_3_notification_cnt_3, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_index, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_any, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_index0, sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0, sw_IngressPipe_LockOperation_1_lock_operation_1.action_run, sw_IngressPipe_LockOperation_1_lock_operation_1.hit, sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0, sw_IngressPipe_LockOperation_2_lock_operation_2.action_run, sw_IngressPipe_LockOperation_2_lock_operation_2.hit, sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0, sw_IngressPipe_LockOperation_3_lock_operation_3.action_run, sw_IngressPipe_LockOperation_3_lock_operation_3.hit, sw_IngressPipe_acquire_table.action_run, sw_IngressPipe_acquire_table.hit, sw_IngressPipe_lock_free_mode_array, sw_IngressPipe_lock_free_mode_array__last0_old_value, sw_IngressPipe_lock_free_mode_array__last0_value, sw_IngressPipe_lock_free_mode_array__last_index, sw_IngressPipe_lock_free_mode_array__last_old_value, sw_IngressPipe_lock_free_mode_array__last_value, sw_IngressPipe_lock_free_mode_array__last_write_site, sw_IngressPipe_lock_free_mode_array__next_write_site, sw_IngressPipe_lock_free_mode_array__wrote_any, sw_IngressPipe_lock_free_mode_array__wrote_index0, sw_IngressPipe_lock_rw_mode_array, sw_IngressPipe_lock_rw_mode_array__last0_old_value, sw_IngressPipe_lock_rw_mode_array__last0_value, sw_IngressPipe_lock_rw_mode_array__last_index, sw_IngressPipe_lock_rw_mode_array__last_old_value, sw_IngressPipe_lock_rw_mode_array__last_value, sw_IngressPipe_lock_rw_mode_array__last_write_site, sw_IngressPipe_lock_rw_mode_array__next_write_site, sw_IngressPipe_lock_rw_mode_array__wrote_any, sw_IngressPipe_lock_rw_mode_array__wrote_index0, sw_IngressPipe_release_table.action_run, sw_IngressPipe_release_table.hit, sw_IngressPipe_rw_table.action_run, sw_IngressPipe_rw_table.hit, sw___ra_ret_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_ret_IngressPipe_acquire, sw___ra_ret_IngressPipe_get_mode, sw___ra_ret_IngressPipe_release, sw___ra_ret_IngressPipe_set_excl, sw___ra_ret_IngressPipe_set_shared, sw___ra_val_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_1_count_ncnt, sw___ra_val_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_2_count_ncnt, sw___ra_val_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_3_count_ncnt, sw___ra_val_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_val_IngressPipe_acquire, sw___ra_val_IngressPipe_get_mode, sw___ra_val_IngressPipe_release, sw___ra_val_IngressPipe_set_excl, sw___ra_val_IngressPipe_set_shared, sw_drop, sw_eg_md.is_roce, sw_eg_md.pkt_psn, sw_hdr.lock.agent, sw_hdr.lock.mode, sw_hdr.lock.multicasted, sw_hdr.lock.old_mode, sw_hdr.lock.transferred, sw_hdr.lock.type, sw_ig_md.agent_changed, sw_ig_md.is_roce, sw_ig_md.lock_agent, sw_ig_md.lock_free_mode, sw_ig_md.lock_index, sw_ig_md.lock_out_of_range, sw_ig_md.lock_rw_mode, sw_ig_md.pkt_psn, sw_isValid;
{
    call sw_IngressParser();
    call sw_IngressPipe();
    call sw_IngressDeparser();
    call sw_EgressParser();
    call sw_EgressPipe();
    call sw_EgressDeparser();
}
procedure sw_pkt.advance(sw_arg0:bv32);
procedure sw_reject();
    ensures sw_drop==true;
	modifies sw_drop;
// ===== END NODE sw =====

// ===== BEGIN ENQUEUE PROCEDURES =====
// ===== END ENQUEUE PROCEDURES =====

// ===== BEGIN HARNESS =====
// Auto-generated by Procurator (DSL -> Boogie harness: sequential scheduler)
// Message abstraction: Bag(K=1) using inbox_count per node; single-slot mailbox for packet fields

var procurator_step: int;
var procurator_phase: int;

// DSL state variables (modeled as Boogie globals)
var dsl_pump_mode: bool;

var sw_inbox_count: int;
var client_inbox_count: int;

var sw_pkt_external: bool;
var client_pkt_external: bool;

// Host packet fields (mirrors connected node symbols)
var client_hdr.ethernet.valid: bool;
var client_hdr.ethernet.dst_mac: sw_mac_addr_t;
var client_hdr.ethernet.l3_proto: sw_eth_type;
var client_hdr.ipv4.valid: bool;
var client_hdr.ipv4.l4_proto: bv8;
var client_hdr.ipv4.hdr_cksum: bv16;
var client_hdr.udp.valid: bool;
var client_hdr.udp.dst_port: sw_udp_port_t;
var client_hdr.roce.opcode: bv8;
var client_hdr.roce.psn: sw_psn_t;
var client_hdr.lock.valid: bool;
var client_hdr.lock.type: bv8;
var client_hdr.lock.multicasted: bv1;
var client_hdr.lock.granted: bv1;
var client_hdr.lock.transferred: bv1;
var client_hdr.lock.old_mode: bv1;
var client_hdr.lock.mode: bv1;
var client_hdr.lock.id: sw_lid_t;
var client_hdr.lock.machine_id: sw_host_t;
var client_hdr.lock.task_id: bv32;
var client_hdr.lock.agent: sw_host_t;
var client_hdr.lock.wq_size: bv32;
var client_hdr.lock.ncnt: bv8;
var client_ig_md.lock_free_mode: bv1;
var client_ig_md.lock_rw_mode: bv1;
var client_ig_md.lock_agent: sw_host_t;
var client_ig_md.lock_index: sw_lid_t;
var client_ig_md.agent_changed: bv1;
var client_ig_md.lock_out_of_range: bv1;
var client_ig_md.is_roce: bv1;
var client_ig_md.pkt_psn: sw_psn_t;
var client_ig_intr_md.resubmit_flag: bv1;
var client_eg_md.is_roce: bv1;
var client_eg_md.pkt_psn: sw_psn_t;
var client_eg_intr_md.egress_rid: bv16;

// Forwarding (derived from DSL topology)
procedure sw_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (sw_eg_intr_md.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure main() returns()
  modifies client_eg_intr_md.egress_rid, client_eg_md.is_roce, client_eg_md.pkt_psn, client_hdr.ethernet.dst_mac, client_hdr.ethernet.l3_proto, client_hdr.ethernet.valid, client_hdr.ipv4.hdr_cksum, client_hdr.ipv4.l4_proto, client_hdr.ipv4.valid, client_hdr.lock.agent, client_hdr.lock.granted, client_hdr.lock.id, client_hdr.lock.machine_id, client_hdr.lock.mode, client_hdr.lock.multicasted, client_hdr.lock.ncnt, client_hdr.lock.old_mode, client_hdr.lock.task_id, client_hdr.lock.transferred, client_hdr.lock.type, client_hdr.lock.valid, client_hdr.lock.wq_size, client_hdr.roce.opcode, client_hdr.roce.psn, client_hdr.udp.dst_port, client_hdr.udp.valid, client_ig_intr_md.resubmit_flag, client_ig_md.agent_changed, client_ig_md.is_roce, client_ig_md.lock_agent, client_ig_md.lock_free_mode, client_ig_md.lock_index, client_ig_md.lock_out_of_range, client_ig_md.lock_rw_mode, client_ig_md.pkt_psn, client_inbox_count, client_pkt_external, dsl_pump_mode, procurator_phase, procurator_step, sw_IngressPipe_CounterTable_1_counter_table_1.action_run, sw_IngressPipe_CounterTable_1_counter_table_1.hit, sw_IngressPipe_CounterTable_1_notification_cnt_1, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_index, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_any, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_index0, sw_IngressPipe_CounterTable_2_counter_table_2.action_run, sw_IngressPipe_CounterTable_2_counter_table_2.hit, sw_IngressPipe_CounterTable_2_notification_cnt_2, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_index, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_any, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_index0, sw_IngressPipe_CounterTable_3_counter_table_3.action_run, sw_IngressPipe_CounterTable_3_counter_table_3.hit, sw_IngressPipe_CounterTable_3_notification_cnt_3, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_index, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_any, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_index0, sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0, sw_IngressPipe_LockOperation_1_lock_operation_1.action_run, sw_IngressPipe_LockOperation_1_lock_operation_1.hit, sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0, sw_IngressPipe_LockOperation_2_lock_operation_2.action_run, sw_IngressPipe_LockOperation_2_lock_operation_2.hit, sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0, sw_IngressPipe_LockOperation_3_lock_operation_3.action_run, sw_IngressPipe_LockOperation_3_lock_operation_3.hit, sw_IngressPipe_acquire_table.action_run, sw_IngressPipe_acquire_table.hit, sw_IngressPipe_lock_free_mode_array, sw_IngressPipe_lock_free_mode_array__last0_old_value, sw_IngressPipe_lock_free_mode_array__last0_value, sw_IngressPipe_lock_free_mode_array__last_index, sw_IngressPipe_lock_free_mode_array__last_old_value, sw_IngressPipe_lock_free_mode_array__last_value, sw_IngressPipe_lock_free_mode_array__last_write_site, sw_IngressPipe_lock_free_mode_array__next_write_site, sw_IngressPipe_lock_free_mode_array__wrote_any, sw_IngressPipe_lock_free_mode_array__wrote_index0, sw_IngressPipe_lock_rw_mode_array, sw_IngressPipe_lock_rw_mode_array__last0_old_value, sw_IngressPipe_lock_rw_mode_array__last0_value, sw_IngressPipe_lock_rw_mode_array__last_index, sw_IngressPipe_lock_rw_mode_array__last_old_value, sw_IngressPipe_lock_rw_mode_array__last_value, sw_IngressPipe_lock_rw_mode_array__last_write_site, sw_IngressPipe_lock_rw_mode_array__next_write_site, sw_IngressPipe_lock_rw_mode_array__wrote_any, sw_IngressPipe_lock_rw_mode_array__wrote_index0, sw_IngressPipe_release_table.action_run, sw_IngressPipe_release_table.hit, sw_IngressPipe_rw_table.action_run, sw_IngressPipe_rw_table.hit, sw___ra_ret_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_ret_IngressPipe_acquire, sw___ra_ret_IngressPipe_get_mode, sw___ra_ret_IngressPipe_release, sw___ra_ret_IngressPipe_set_excl, sw___ra_ret_IngressPipe_set_shared, sw___ra_val_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_1_count_ncnt, sw___ra_val_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_2_count_ncnt, sw___ra_val_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_3_count_ncnt, sw___ra_val_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_val_IngressPipe_acquire, sw___ra_val_IngressPipe_get_mode, sw___ra_val_IngressPipe_release, sw___ra_val_IngressPipe_set_excl, sw___ra_val_IngressPipe_set_shared, sw_drop, sw_eg_intr_md.egress_rid, sw_eg_md.is_roce, sw_eg_md.pkt_psn, sw_hdr.ethernet.dst_mac, sw_hdr.ethernet.l3_proto, sw_hdr.ethernet.valid, sw_hdr.ipv4.hdr_cksum, sw_hdr.ipv4.l4_proto, sw_hdr.ipv4.valid, sw_hdr.lock.agent, sw_hdr.lock.granted, sw_hdr.lock.id, sw_hdr.lock.machine_id, sw_hdr.lock.mode, sw_hdr.lock.multicasted, sw_hdr.lock.ncnt, sw_hdr.lock.old_mode, sw_hdr.lock.task_id, sw_hdr.lock.transferred, sw_hdr.lock.type, sw_hdr.lock.valid, sw_hdr.lock.wq_size, sw_hdr.roce.opcode, sw_hdr.roce.psn, sw_hdr.udp.dst_port, sw_hdr.udp.valid, sw_ig_intr_md.resubmit_flag, sw_ig_md.agent_changed, sw_ig_md.is_roce, sw_ig_md.lock_agent, sw_ig_md.lock_free_mode, sw_ig_md.lock_index, sw_ig_md.lock_out_of_range, sw_ig_md.lock_rw_mode, sw_ig_md.pkt_psn, sw_inbox_count, sw_isValid, sw_p4b_checksum_error, sw_p4b_checksum_updated, sw_p4b_checksum_verified, sw_p4b_clone_e2e, sw_p4b_clone_i2e, sw_p4b_clone_i2i, sw_p4b_digest, sw_p4b_recirculate, sw_pkt_external;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    // host send -> client
    // inject packet into connected node (host -> node)
    if (sw_inbox_count < 1) {
      assume sw_inbox_count < 1;
      havoc client_hdr.lock.type;
      havoc client_ig_md.lock_free_mode;
      havoc client_ig_md.lock_rw_mode;
      havoc client_ig_md.lock_agent;
      havoc client_ig_md.lock_index;
      havoc client_ig_md.agent_changed;
      havoc client_ig_md.lock_out_of_range;
      havoc client_ig_md.is_roce;
      havoc client_ig_md.pkt_psn;
      havoc client_eg_md.is_roce;
      havoc client_eg_md.pkt_psn;
      havoc client_eg_intr_md.egress_rid;
      client_hdr.ethernet.valid := true;
      client_hdr.ipv4.valid := true;
      client_hdr.udp.valid := true;
      client_hdr.lock.valid := true;
      client_hdr.ethernet.l3_proto := 2048bv16;
      client_hdr.ethernet.dst_mac := 0bv48;
      client_hdr.ipv4.l4_proto := 17bv8;
      client_hdr.ipv4.hdr_cksum := 0bv16;
      client_hdr.udp.dst_port := 20001bv16;
      client_hdr.roce.opcode := 0bv8;
      client_hdr.roce.psn := 0bv24;
      client_ig_intr_md.resubmit_flag := 0bv1;
      client_hdr.lock.id := 0bv32;
      client_hdr.lock.mode := 0bv1;
      client_hdr.lock.old_mode := 0bv1;
      client_hdr.lock.ncnt := 0bv8;
      client_hdr.lock.transferred := 0bv1;
      client_hdr.lock.granted := 0bv1;
      client_hdr.lock.multicasted := 0bv1;
      client_hdr.lock.machine_id := 1bv8;
      client_hdr.lock.agent := 2bv8;
      client_hdr.lock.task_id := 0bv32;
      client_hdr.lock.wq_size := 0bv32;
      if (dsl_pump_mode) {
        client_hdr.lock.type := 1bv8;
      } else {
        client_hdr.lock.type := 5bv8;
      }
      assume (sw_hdr.lock.id == 0bv32);
      assume (sw_ig_md.lock_index == 0bv32);
      assume (sw_ig_md.lock_out_of_range == 0bv1);
      sw_hdr.ethernet.valid := client_hdr.ethernet.valid;
      sw_hdr.ethernet.dst_mac := client_hdr.ethernet.dst_mac;
      sw_hdr.ethernet.l3_proto := client_hdr.ethernet.l3_proto;
      sw_hdr.ipv4.valid := client_hdr.ipv4.valid;
      sw_hdr.ipv4.l4_proto := client_hdr.ipv4.l4_proto;
      sw_hdr.ipv4.hdr_cksum := client_hdr.ipv4.hdr_cksum;
      sw_hdr.udp.valid := client_hdr.udp.valid;
      sw_hdr.udp.dst_port := client_hdr.udp.dst_port;
      sw_hdr.roce.opcode := client_hdr.roce.opcode;
      sw_hdr.roce.psn := client_hdr.roce.psn;
      sw_hdr.lock.valid := client_hdr.lock.valid;
      sw_hdr.lock.type := client_hdr.lock.type;
      sw_hdr.lock.multicasted := client_hdr.lock.multicasted;
      sw_hdr.lock.granted := client_hdr.lock.granted;
      sw_hdr.lock.transferred := client_hdr.lock.transferred;
      sw_hdr.lock.old_mode := client_hdr.lock.old_mode;
      sw_hdr.lock.mode := client_hdr.lock.mode;
      sw_hdr.lock.id := client_hdr.lock.id;
      sw_hdr.lock.machine_id := client_hdr.lock.machine_id;
      sw_hdr.lock.task_id := client_hdr.lock.task_id;
      sw_hdr.lock.agent := client_hdr.lock.agent;
      sw_hdr.lock.wq_size := client_hdr.lock.wq_size;
      sw_hdr.lock.ncnt := client_hdr.lock.ncnt;
      sw_ig_md.lock_free_mode := client_ig_md.lock_free_mode;
      sw_ig_md.lock_rw_mode := client_ig_md.lock_rw_mode;
      sw_ig_md.lock_agent := client_ig_md.lock_agent;
      sw_ig_md.lock_index := client_ig_md.lock_index;
      sw_ig_md.agent_changed := client_ig_md.agent_changed;
      sw_ig_md.lock_out_of_range := client_ig_md.lock_out_of_range;
      sw_ig_md.is_roce := client_ig_md.is_roce;
      sw_ig_md.pkt_psn := client_ig_md.pkt_psn;
      sw_ig_intr_md.resubmit_flag := client_ig_intr_md.resubmit_flag;
      sw_eg_md.is_roce := client_eg_md.is_roce;
      sw_eg_md.pkt_psn := client_eg_md.pkt_psn;
      sw_eg_intr_md.egress_rid := client_eg_intr_md.egress_rid;
      sw_pkt_external := true;
      sw_inbox_count := sw_inbox_count + 1;
    }
  } else if (procurator_phase == 1) {
    // host recv -> client
  } else if (procurator_phase == 2) {
    // node pass -> sw
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
    // Global assertions
    assert (dsl_pump_mode || (sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value != 0bv8) || (sw_hdr.lock.transferred == 0bv1));
    }
  } else {
    assume false;
  }
    if (procurator_phase == 2) {
      procurator_phase := 0;
    } else {
      procurator_phase := procurator_phase + 1;
    }
}

procedure mainProcedure() returns()
  modifies client_eg_intr_md.egress_rid, client_eg_md.is_roce, client_eg_md.pkt_psn, client_hdr.ethernet.dst_mac, client_hdr.ethernet.l3_proto, client_hdr.ethernet.valid, client_hdr.ipv4.hdr_cksum, client_hdr.ipv4.l4_proto, client_hdr.ipv4.valid, client_hdr.lock.agent, client_hdr.lock.granted, client_hdr.lock.id, client_hdr.lock.machine_id, client_hdr.lock.mode, client_hdr.lock.multicasted, client_hdr.lock.ncnt, client_hdr.lock.old_mode, client_hdr.lock.task_id, client_hdr.lock.transferred, client_hdr.lock.type, client_hdr.lock.valid, client_hdr.lock.wq_size, client_hdr.roce.opcode, client_hdr.roce.psn, client_hdr.udp.dst_port, client_hdr.udp.valid, client_ig_intr_md.resubmit_flag, client_ig_md.agent_changed, client_ig_md.is_roce, client_ig_md.lock_agent, client_ig_md.lock_free_mode, client_ig_md.lock_index, client_ig_md.lock_out_of_range, client_ig_md.lock_rw_mode, client_ig_md.pkt_psn, client_inbox_count, client_pkt_external, dsl_pump_mode, procurator_phase, procurator_step, sw_IngressPipe_CounterTable_1_counter_table_1.action_run, sw_IngressPipe_CounterTable_1_counter_table_1.hit, sw_IngressPipe_CounterTable_1_notification_cnt_1, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_index, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_any, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_index0, sw_IngressPipe_CounterTable_2_counter_table_2.action_run, sw_IngressPipe_CounterTable_2_counter_table_2.hit, sw_IngressPipe_CounterTable_2_notification_cnt_2, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_index, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_any, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_index0, sw_IngressPipe_CounterTable_3_counter_table_3.action_run, sw_IngressPipe_CounterTable_3_counter_table_3.hit, sw_IngressPipe_CounterTable_3_notification_cnt_3, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_index, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_any, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_index0, sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0, sw_IngressPipe_LockOperation_1_lock_operation_1.action_run, sw_IngressPipe_LockOperation_1_lock_operation_1.hit, sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0, sw_IngressPipe_LockOperation_2_lock_operation_2.action_run, sw_IngressPipe_LockOperation_2_lock_operation_2.hit, sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0, sw_IngressPipe_LockOperation_3_lock_operation_3.action_run, sw_IngressPipe_LockOperation_3_lock_operation_3.hit, sw_IngressPipe_acquire_table.action_run, sw_IngressPipe_acquire_table.hit, sw_IngressPipe_lock_free_mode_array, sw_IngressPipe_lock_free_mode_array__last0_old_value, sw_IngressPipe_lock_free_mode_array__last0_value, sw_IngressPipe_lock_free_mode_array__last_index, sw_IngressPipe_lock_free_mode_array__last_old_value, sw_IngressPipe_lock_free_mode_array__last_value, sw_IngressPipe_lock_free_mode_array__last_write_site, sw_IngressPipe_lock_free_mode_array__next_write_site, sw_IngressPipe_lock_free_mode_array__wrote_any, sw_IngressPipe_lock_free_mode_array__wrote_index0, sw_IngressPipe_lock_rw_mode_array, sw_IngressPipe_lock_rw_mode_array__last0_old_value, sw_IngressPipe_lock_rw_mode_array__last0_value, sw_IngressPipe_lock_rw_mode_array__last_index, sw_IngressPipe_lock_rw_mode_array__last_old_value, sw_IngressPipe_lock_rw_mode_array__last_value, sw_IngressPipe_lock_rw_mode_array__last_write_site, sw_IngressPipe_lock_rw_mode_array__next_write_site, sw_IngressPipe_lock_rw_mode_array__wrote_any, sw_IngressPipe_lock_rw_mode_array__wrote_index0, sw_IngressPipe_release_table.action_run, sw_IngressPipe_release_table.hit, sw_IngressPipe_rw_table.action_run, sw_IngressPipe_rw_table.hit, sw___ra_ret_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_ret_IngressPipe_acquire, sw___ra_ret_IngressPipe_get_mode, sw___ra_ret_IngressPipe_release, sw___ra_ret_IngressPipe_set_excl, sw___ra_ret_IngressPipe_set_shared, sw___ra_val_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_1_count_ncnt, sw___ra_val_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_2_count_ncnt, sw___ra_val_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_3_count_ncnt, sw___ra_val_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_val_IngressPipe_acquire, sw___ra_val_IngressPipe_get_mode, sw___ra_val_IngressPipe_release, sw___ra_val_IngressPipe_set_excl, sw___ra_val_IngressPipe_set_shared, sw_drop, sw_eg_intr_md.egress_rid, sw_eg_md.is_roce, sw_eg_md.pkt_psn, sw_hdr.ethernet.dst_mac, sw_hdr.ethernet.l3_proto, sw_hdr.ethernet.valid, sw_hdr.ipv4.hdr_cksum, sw_hdr.ipv4.l4_proto, sw_hdr.ipv4.valid, sw_hdr.lock.agent, sw_hdr.lock.granted, sw_hdr.lock.id, sw_hdr.lock.machine_id, sw_hdr.lock.mode, sw_hdr.lock.multicasted, sw_hdr.lock.ncnt, sw_hdr.lock.old_mode, sw_hdr.lock.task_id, sw_hdr.lock.transferred, sw_hdr.lock.type, sw_hdr.lock.valid, sw_hdr.lock.wq_size, sw_hdr.roce.opcode, sw_hdr.roce.psn, sw_hdr.udp.dst_port, sw_hdr.udp.valid, sw_ig_intr_md.resubmit_flag, sw_ig_md.agent_changed, sw_ig_md.is_roce, sw_ig_md.lock_agent, sw_ig_md.lock_free_mode, sw_ig_md.lock_index, sw_ig_md.lock_out_of_range, sw_ig_md.lock_rw_mode, sw_ig_md.pkt_psn, sw_inbox_count, sw_isValid, sw_p4b_checksum_error, sw_p4b_checksum_updated, sw_p4b_checksum_verified, sw_p4b_clone_e2e, sw_p4b_clone_i2e, sw_p4b_clone_i2i, sw_p4b_digest, sw_p4b_recirculate, sw_pkt_external;
{
  // initialize inboxes
  sw_inbox_count := 0;
  sw_pkt_external := false;
  client_inbox_count := 0;
  client_pkt_external := false;
  // initialize P4B event flags (clone/recirculate)
  sw_p4b_clone_i2e := false;
  sw_p4b_clone_e2e := false;
  sw_p4b_clone_i2i := false;
  sw_p4b_recirculate := false;

  // initialize DSL state
  dsl_pump_mode := true;
  // initialize P4 registers (default 0)
  assume sw_IngressPipe_CounterTable_1_notification_cnt_1[0bv32] == 0bv8;
  assume sw_IngressPipe_CounterTable_2_notification_cnt_2[0bv32] == 0bv8;
  assume sw_IngressPipe_CounterTable_3_notification_cnt_3[0bv32] == 0bv8;
  assume sw_IngressPipe_LockOperation_1_lock_agent_array_1[0bv32] == 0bv8;
  assume sw_IngressPipe_LockOperation_2_lock_agent_array_2[0bv32] == 0bv8;
  assume sw_IngressPipe_LockOperation_3_lock_agent_array_3[0bv32] == 0bv8;
  assume (forall i:sw_lid_t :: sw_IngressPipe_lock_free_mode_array[i] == 0bv1);
  assume sw_IngressPipe_lock_free_mode_array[0bv32] == 0bv1;
  assume (forall i:sw_lid_t :: sw_IngressPipe_lock_rw_mode_array[i] == 0bv1);
  assume sw_IngressPipe_lock_rw_mode_array[0bv32] == 0bv1;
  // initialize register write tracking (debug)
  sw_IngressPipe_CounterTable_1_notification_cnt_1__last_index := 0bv32;
  sw_IngressPipe_CounterTable_1_notification_cnt_1__last_value := 0bv8;
  sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value := 0bv8;
  sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_any := false;
  sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_index0 := false;
  sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site := 0;
  sw_IngressPipe_CounterTable_1_notification_cnt_1__last_write_site := 0;
  sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_old_value := 0bv8;
  sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value := 0bv8;
  sw_IngressPipe_CounterTable_2_notification_cnt_2__last_index := 0bv32;
  sw_IngressPipe_CounterTable_2_notification_cnt_2__last_value := 0bv8;
  sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value := 0bv8;
  sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_any := false;
  sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_index0 := false;
  sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site := 0;
  sw_IngressPipe_CounterTable_2_notification_cnt_2__last_write_site := 0;
  sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_old_value := 0bv8;
  sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_value := 0bv8;
  sw_IngressPipe_CounterTable_3_notification_cnt_3__last_index := 0bv32;
  sw_IngressPipe_CounterTable_3_notification_cnt_3__last_value := 0bv8;
  sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value := 0bv8;
  sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_any := false;
  sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_index0 := false;
  sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site := 0;
  sw_IngressPipe_CounterTable_3_notification_cnt_3__last_write_site := 0;
  sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_old_value := 0bv8;
  sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_value := 0bv8;
  sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index := 0bv32;
  sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value := 0bv8;
  sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value := 0bv8;
  sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any := false;
  sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0 := false;
  sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site := 0;
  sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site := 0;
  sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value := 0bv8;
  sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value := 0bv8;
  sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index := 0bv32;
  sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value := 0bv8;
  sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value := 0bv8;
  sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any := false;
  sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0 := false;
  sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site := 0;
  sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site := 0;
  sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value := 0bv8;
  sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value := 0bv8;
  sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index := 0bv32;
  sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value := 0bv8;
  sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value := 0bv8;
  sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any := false;
  sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0 := false;
  sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site := 0;
  sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site := 0;
  sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value := 0bv8;
  sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value := 0bv8;
  sw_IngressPipe_lock_free_mode_array__last_index := 0bv32;
  sw_IngressPipe_lock_free_mode_array__last_value := 0bv1;
  sw_IngressPipe_lock_free_mode_array__last_old_value := 0bv1;
  sw_IngressPipe_lock_free_mode_array__wrote_any := false;
  sw_IngressPipe_lock_free_mode_array__wrote_index0 := false;
  sw_IngressPipe_lock_free_mode_array__next_write_site := 0;
  sw_IngressPipe_lock_free_mode_array__last_write_site := 0;
  sw_IngressPipe_lock_free_mode_array__last0_old_value := 0bv1;
  sw_IngressPipe_lock_free_mode_array__last0_value := 0bv1;
  sw_IngressPipe_lock_rw_mode_array__last_index := 0bv32;
  sw_IngressPipe_lock_rw_mode_array__last_value := 0bv1;
  sw_IngressPipe_lock_rw_mode_array__last_old_value := 0bv1;
  sw_IngressPipe_lock_rw_mode_array__wrote_any := false;
  sw_IngressPipe_lock_rw_mode_array__wrote_index0 := false;
  sw_IngressPipe_lock_rw_mode_array__next_write_site := 0;
  sw_IngressPipe_lock_rw_mode_array__last_write_site := 0;
  sw_IngressPipe_lock_rw_mode_array__last0_old_value := 0bv1;
  sw_IngressPipe_lock_rw_mode_array__last0_value := 0bv1;

  procurator_step := 0;
  procurator_phase := 0;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}


procedure ULTIMATE.start() returns()
  modifies client_eg_intr_md.egress_rid, client_eg_md.is_roce, client_eg_md.pkt_psn, client_hdr.ethernet.dst_mac, client_hdr.ethernet.l3_proto, client_hdr.ethernet.valid, client_hdr.ipv4.hdr_cksum, client_hdr.ipv4.l4_proto, client_hdr.ipv4.valid, client_hdr.lock.agent, client_hdr.lock.granted, client_hdr.lock.id, client_hdr.lock.machine_id, client_hdr.lock.mode, client_hdr.lock.multicasted, client_hdr.lock.ncnt, client_hdr.lock.old_mode, client_hdr.lock.task_id, client_hdr.lock.transferred, client_hdr.lock.type, client_hdr.lock.valid, client_hdr.lock.wq_size, client_hdr.roce.opcode, client_hdr.roce.psn, client_hdr.udp.dst_port, client_hdr.udp.valid, client_ig_intr_md.resubmit_flag, client_ig_md.agent_changed, client_ig_md.is_roce, client_ig_md.lock_agent, client_ig_md.lock_free_mode, client_ig_md.lock_index, client_ig_md.lock_out_of_range, client_ig_md.lock_rw_mode, client_ig_md.pkt_psn, client_inbox_count, client_pkt_external, dsl_pump_mode, procurator_phase, procurator_step, sw_IngressPipe_CounterTable_1_counter_table_1.action_run, sw_IngressPipe_CounterTable_1_counter_table_1.hit, sw_IngressPipe_CounterTable_1_notification_cnt_1, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last0_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_index, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_old_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_value, sw_IngressPipe_CounterTable_1_notification_cnt_1__last_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__next_write_site, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_any, sw_IngressPipe_CounterTable_1_notification_cnt_1__wrote_index0, sw_IngressPipe_CounterTable_2_counter_table_2.action_run, sw_IngressPipe_CounterTable_2_counter_table_2.hit, sw_IngressPipe_CounterTable_2_notification_cnt_2, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last0_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_index, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_old_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_value, sw_IngressPipe_CounterTable_2_notification_cnt_2__last_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__next_write_site, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_any, sw_IngressPipe_CounterTable_2_notification_cnt_2__wrote_index0, sw_IngressPipe_CounterTable_3_counter_table_3.action_run, sw_IngressPipe_CounterTable_3_counter_table_3.hit, sw_IngressPipe_CounterTable_3_notification_cnt_3, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last0_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_index, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_old_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_value, sw_IngressPipe_CounterTable_3_notification_cnt_3__last_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__next_write_site, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_any, sw_IngressPipe_CounterTable_3_notification_cnt_3__wrote_index0, sw_IngressPipe_LockOperation_1_lock_agent_array_1, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last0_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_index, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_old_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_value, sw_IngressPipe_LockOperation_1_lock_agent_array_1__last_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__next_write_site, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_any, sw_IngressPipe_LockOperation_1_lock_agent_array_1__wrote_index0, sw_IngressPipe_LockOperation_1_lock_operation_1.action_run, sw_IngressPipe_LockOperation_1_lock_operation_1.hit, sw_IngressPipe_LockOperation_2_lock_agent_array_2, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last0_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_index, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_old_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_value, sw_IngressPipe_LockOperation_2_lock_agent_array_2__last_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__next_write_site, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_any, sw_IngressPipe_LockOperation_2_lock_agent_array_2__wrote_index0, sw_IngressPipe_LockOperation_2_lock_operation_2.action_run, sw_IngressPipe_LockOperation_2_lock_operation_2.hit, sw_IngressPipe_LockOperation_3_lock_agent_array_3, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last0_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_index, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_old_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_value, sw_IngressPipe_LockOperation_3_lock_agent_array_3__last_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__next_write_site, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_any, sw_IngressPipe_LockOperation_3_lock_agent_array_3__wrote_index0, sw_IngressPipe_LockOperation_3_lock_operation_3.action_run, sw_IngressPipe_LockOperation_3_lock_operation_3.hit, sw_IngressPipe_acquire_table.action_run, sw_IngressPipe_acquire_table.hit, sw_IngressPipe_lock_free_mode_array, sw_IngressPipe_lock_free_mode_array__last0_old_value, sw_IngressPipe_lock_free_mode_array__last0_value, sw_IngressPipe_lock_free_mode_array__last_index, sw_IngressPipe_lock_free_mode_array__last_old_value, sw_IngressPipe_lock_free_mode_array__last_value, sw_IngressPipe_lock_free_mode_array__last_write_site, sw_IngressPipe_lock_free_mode_array__next_write_site, sw_IngressPipe_lock_free_mode_array__wrote_any, sw_IngressPipe_lock_free_mode_array__wrote_index0, sw_IngressPipe_lock_rw_mode_array, sw_IngressPipe_lock_rw_mode_array__last0_old_value, sw_IngressPipe_lock_rw_mode_array__last0_value, sw_IngressPipe_lock_rw_mode_array__last_index, sw_IngressPipe_lock_rw_mode_array__last_old_value, sw_IngressPipe_lock_rw_mode_array__last_value, sw_IngressPipe_lock_rw_mode_array__last_write_site, sw_IngressPipe_lock_rw_mode_array__next_write_site, sw_IngressPipe_lock_rw_mode_array__wrote_any, sw_IngressPipe_lock_rw_mode_array__wrote_index0, sw_IngressPipe_release_table.action_run, sw_IngressPipe_release_table.hit, sw_IngressPipe_rw_table.action_run, sw_IngressPipe_rw_table.hit, sw___ra_ret_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_count_ncnt, sw___ra_ret_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_ret_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_ret_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_ret_IngressPipe_acquire, sw___ra_ret_IngressPipe_get_mode, sw___ra_ret_IngressPipe_release, sw___ra_ret_IngressPipe_set_excl, sw___ra_ret_IngressPipe_set_shared, sw___ra_val_IngressPipe_CounterTable_1_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_1_count_ncnt, sw___ra_val_IngressPipe_CounterTable_1_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_2_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_2_count_ncnt, sw___ra_val_IngressPipe_CounterTable_2_reset_ncnt, sw___ra_val_IngressPipe_CounterTable_3_cmp_ncnt, sw___ra_val_IngressPipe_CounterTable_3_count_ncnt, sw___ra_val_IngressPipe_CounterTable_3_reset_ncnt, sw___ra_val_IngressPipe_LockOperation_1_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_1_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_2_set_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_get_lock_agent, sw___ra_val_IngressPipe_LockOperation_3_set_lock_agent, sw___ra_val_IngressPipe_acquire, sw___ra_val_IngressPipe_get_mode, sw___ra_val_IngressPipe_release, sw___ra_val_IngressPipe_set_excl, sw___ra_val_IngressPipe_set_shared, sw_drop, sw_eg_intr_md.egress_rid, sw_eg_md.is_roce, sw_eg_md.pkt_psn, sw_hdr.ethernet.dst_mac, sw_hdr.ethernet.l3_proto, sw_hdr.ethernet.valid, sw_hdr.ipv4.hdr_cksum, sw_hdr.ipv4.l4_proto, sw_hdr.ipv4.valid, sw_hdr.lock.agent, sw_hdr.lock.granted, sw_hdr.lock.id, sw_hdr.lock.machine_id, sw_hdr.lock.mode, sw_hdr.lock.multicasted, sw_hdr.lock.ncnt, sw_hdr.lock.old_mode, sw_hdr.lock.task_id, sw_hdr.lock.transferred, sw_hdr.lock.type, sw_hdr.lock.valid, sw_hdr.lock.wq_size, sw_hdr.roce.opcode, sw_hdr.roce.psn, sw_hdr.udp.dst_port, sw_hdr.udp.valid, sw_ig_intr_md.resubmit_flag, sw_ig_md.agent_changed, sw_ig_md.is_roce, sw_ig_md.lock_agent, sw_ig_md.lock_free_mode, sw_ig_md.lock_index, sw_ig_md.lock_out_of_range, sw_ig_md.lock_rw_mode, sw_ig_md.pkt_psn, sw_inbox_count, sw_isValid, sw_p4b_checksum_error, sw_p4b_checksum_updated, sw_p4b_checksum_verified, sw_p4b_clone_e2e, sw_p4b_clone_i2e, sw_p4b_clone_i2i, sw_p4b_digest, sw_p4b_recirculate, sw_pkt_external;
{
  call mainProcedure();
}

// ===== END HARNESS =====
