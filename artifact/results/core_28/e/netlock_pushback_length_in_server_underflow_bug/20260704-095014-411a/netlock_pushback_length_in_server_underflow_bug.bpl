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
type sw_ether_type_t = bv16;
type sw_ip_protocol_t = bv8;
type sw_pkt_type_t = bv8;

// sw_Struct sw_pair
type sw_pair = bv64;
type sw_ethernet_t;
type sw_ipv4_t;
type sw_tcp_t;
type sw_udp_t;
type sw_nlk_hdr_t;
type sw_adm_hdr_t;
type sw_recirculate_hdr_t;
type sw_probe_hdr_t;
type sw_mirror_hdr_t;
type sw_mirror_bridged_metadata_h;

// sw_Struct sw_header_t
type sw_header_t;

// sw_Struct sw_metadata_t
type sw_metadata_t;

// sw_Register sw_slots_two_sides_register
var sw_slots_two_sides_register:[bv32]sw_pair;
var sw_slots_two_sides_register__last_index:bv32;
var sw_slots_two_sides_register__last_value:sw_pair;
var sw_slots_two_sides_register__last_old_value:sw_pair;
var sw_slots_two_sides_register__wrote_any:bool;
var sw_slots_two_sides_register__wrote_index0:bool;
var sw_slots_two_sides_register__last0_old_value:sw_pair;
var sw_slots_two_sides_register__last0_value:sw_pair;
var sw_slots_two_sides_register__next_write_site:int;
var sw_slots_two_sides_register__last_write_site:int;
const sw_slots_two_sides_register.size:bv32;
axiom sw_slots_two_sides_register.size == 11000bv32;

// sw_Register sw_timestamp_hi_array_register
var sw_timestamp_hi_array_register:[bv32]bv32;
var sw_timestamp_hi_array_register__last_index:bv32;
var sw_timestamp_hi_array_register__last_value:bv32;
var sw_timestamp_hi_array_register__last_old_value:bv32;
var sw_timestamp_hi_array_register__wrote_any:bool;
var sw_timestamp_hi_array_register__wrote_index0:bool;
var sw_timestamp_hi_array_register__last0_old_value:bv32;
var sw_timestamp_hi_array_register__last0_value:bv32;
var sw_timestamp_hi_array_register__next_write_site:int;
var sw_timestamp_hi_array_register__last_write_site:int;
const sw_timestamp_hi_array_register.size:bv32;
axiom sw_timestamp_hi_array_register.size == 110000bv32;

// sw_Register sw_shared_and_exclusive_count_register
var sw_shared_and_exclusive_count_register:[bv32]sw_pair;
var sw_shared_and_exclusive_count_register__last_index:bv32;
var sw_shared_and_exclusive_count_register__last_value:sw_pair;
var sw_shared_and_exclusive_count_register__last_old_value:sw_pair;
var sw_shared_and_exclusive_count_register__wrote_any:bool;
var sw_shared_and_exclusive_count_register__wrote_index0:bool;
var sw_shared_and_exclusive_count_register__last0_old_value:sw_pair;
var sw_shared_and_exclusive_count_register__last0_value:sw_pair;
var sw_shared_and_exclusive_count_register__next_write_site:int;
var sw_shared_and_exclusive_count_register__last_write_site:int;
const sw_shared_and_exclusive_count_register.size:bv32;
axiom sw_shared_and_exclusive_count_register.size == 11000bv32;

// sw_Register sw_tail_register
var sw_tail_register:[bv32]bv32;
var sw_tail_register__last_index:bv32;
var sw_tail_register__last_value:bv32;
var sw_tail_register__last_old_value:bv32;
var sw_tail_register__wrote_any:bool;
var sw_tail_register__wrote_index0:bool;
var sw_tail_register__last0_old_value:bv32;
var sw_tail_register__last0_value:bv32;
var sw_tail_register__next_write_site:int;
var sw_tail_register__last_write_site:int;
const sw_tail_register.size:bv32;
axiom sw_tail_register.size == 11000bv32;

// sw_Register sw_ip_array_register
var sw_ip_array_register:[bv32]bv32;
var sw_ip_array_register__last_index:bv32;
var sw_ip_array_register__last_value:bv32;
var sw_ip_array_register__last_old_value:bv32;
var sw_ip_array_register__wrote_any:bool;
var sw_ip_array_register__wrote_index0:bool;
var sw_ip_array_register__last0_old_value:bv32;
var sw_ip_array_register__last0_value:bv32;
var sw_ip_array_register__next_write_site:int;
var sw_ip_array_register__last_write_site:int;
const sw_ip_array_register.size:bv32;
axiom sw_ip_array_register.size == 110000bv32;

// sw_Register sw_mode_array_register
var sw_mode_array_register:[bv32]bv8;
var sw_mode_array_register__last_index:bv32;
var sw_mode_array_register__last_value:bv8;
var sw_mode_array_register__last_old_value:bv8;
var sw_mode_array_register__wrote_any:bool;
var sw_mode_array_register__wrote_index0:bool;
var sw_mode_array_register__last0_old_value:bv8;
var sw_mode_array_register__last0_value:bv8;
var sw_mode_array_register__next_write_site:int;
var sw_mode_array_register__last_write_site:int;
const sw_mode_array_register.size:bv32;
axiom sw_mode_array_register.size == 110000bv32;

// sw_Register sw_client_id_array_register
var sw_client_id_array_register:[bv32]bv8;
var sw_client_id_array_register__last_index:bv32;
var sw_client_id_array_register__last_value:bv8;
var sw_client_id_array_register__last_old_value:bv8;
var sw_client_id_array_register__wrote_any:bool;
var sw_client_id_array_register__wrote_index0:bool;
var sw_client_id_array_register__last0_old_value:bv8;
var sw_client_id_array_register__last0_value:bv8;
var sw_client_id_array_register__next_write_site:int;
var sw_client_id_array_register__last_write_site:int;
const sw_client_id_array_register.size:bv32;
axiom sw_client_id_array_register.size == 110000bv32;

// sw_Register sw_tid_array_register
var sw_tid_array_register:[bv32]bv32;
var sw_tid_array_register__last_index:bv32;
var sw_tid_array_register__last_value:bv32;
var sw_tid_array_register__last_old_value:bv32;
var sw_tid_array_register__wrote_any:bool;
var sw_tid_array_register__wrote_index0:bool;
var sw_tid_array_register__last0_old_value:bv32;
var sw_tid_array_register__last0_value:bv32;
var sw_tid_array_register__next_write_site:int;
var sw_tid_array_register__last_write_site:int;
const sw_tid_array_register.size:bv32;
axiom sw_tid_array_register.size == 110000bv32;

// sw_Register sw_timestamp_lo_array_register
var sw_timestamp_lo_array_register:[bv32]bv32;
var sw_timestamp_lo_array_register__last_index:bv32;
var sw_timestamp_lo_array_register__last_value:bv32;
var sw_timestamp_lo_array_register__last_old_value:bv32;
var sw_timestamp_lo_array_register__wrote_any:bool;
var sw_timestamp_lo_array_register__wrote_index0:bool;
var sw_timestamp_lo_array_register__last0_old_value:bv32;
var sw_timestamp_lo_array_register__last0_value:bv32;
var sw_timestamp_lo_array_register__next_write_site:int;
var sw_timestamp_lo_array_register__last_write_site:int;
const sw_timestamp_lo_array_register.size:bv32;
axiom sw_timestamp_lo_array_register.size == 110000bv32;

// sw_Register sw_tenant_acq_counter_register
var sw_tenant_acq_counter_register:[bv4]bv32;
var sw_tenant_acq_counter_register__last_index:bv4;
var sw_tenant_acq_counter_register__last_value:bv32;
var sw_tenant_acq_counter_register__last_old_value:bv32;
var sw_tenant_acq_counter_register__wrote_any:bool;
var sw_tenant_acq_counter_register__wrote_index0:bool;
var sw_tenant_acq_counter_register__last0_old_value:bv32;
var sw_tenant_acq_counter_register__last0_value:bv32;
var sw_tenant_acq_counter_register__next_write_site:int;
var sw_tenant_acq_counter_register__last_write_site:int;
const sw_tenant_acq_counter_register.size:bv4;
axiom sw_tenant_acq_counter_register.size == 12bv4;

// sw_Register sw_queue_size_op_register
var sw_queue_size_op_register:[bv32]bv32;
var sw_queue_size_op_register__last_index:bv32;
var sw_queue_size_op_register__last_value:bv32;
var sw_queue_size_op_register__last_old_value:bv32;
var sw_queue_size_op_register__wrote_any:bool;
var sw_queue_size_op_register__wrote_index0:bool;
var sw_queue_size_op_register__last0_old_value:bv32;
var sw_queue_size_op_register__last0_value:bv32;
var sw_queue_size_op_register__next_write_site:int;
var sw_queue_size_op_register__last_write_site:int;
const sw_queue_size_op_register.size:bv32;
axiom sw_queue_size_op_register.size == 11000bv32;

// sw_Register sw_left_bound_register
var sw_left_bound_register:[bv32]bv32;
var sw_left_bound_register__last_index:bv32;
var sw_left_bound_register__last_value:bv32;
var sw_left_bound_register__last_old_value:bv32;
var sw_left_bound_register__wrote_any:bool;
var sw_left_bound_register__wrote_index0:bool;
var sw_left_bound_register__last0_old_value:bv32;
var sw_left_bound_register__last0_value:bv32;
var sw_left_bound_register__next_write_site:int;
var sw_left_bound_register__last_write_site:int;
const sw_left_bound_register.size:bv32;
axiom sw_left_bound_register.size == 11000bv32;

// sw_Register sw_right_bound_register
var sw_right_bound_register:[bv32]bv32;
var sw_right_bound_register__last_index:bv32;
var sw_right_bound_register__last_value:bv32;
var sw_right_bound_register__last_old_value:bv32;
var sw_right_bound_register__wrote_any:bool;
var sw_right_bound_register__wrote_index0:bool;
var sw_right_bound_register__last0_old_value:bv32;
var sw_right_bound_register__last0_value:bv32;
var sw_right_bound_register__next_write_site:int;
var sw_right_bound_register__last_write_site:int;
const sw_right_bound_register.size:bv32;
axiom sw_right_bound_register.size == 11000bv32;

// sw_Register sw_head_register
var sw_head_register:[bv32]bv32;
var sw_head_register__last_index:bv32;
var sw_head_register__last_value:bv32;
var sw_head_register__last_old_value:bv32;
var sw_head_register__wrote_any:bool;
var sw_head_register__wrote_index0:bool;
var sw_head_register__last0_old_value:bv32;
var sw_head_register__last0_value:bv32;
var sw_head_register__next_write_site:int;
var sw_head_register__last_write_site:int;
const sw_head_register.size:bv32;
axiom sw_head_register.size == 11000bv32;

// sw_Register sw_failure_status_register
var sw_failure_status_register:[bv1]bv8;
var sw_failure_status_register__last_index:bv1;
var sw_failure_status_register__last_value:bv8;
var sw_failure_status_register__last_old_value:bv8;
var sw_failure_status_register__wrote_any:bool;
var sw_failure_status_register__wrote_index0:bool;
var sw_failure_status_register__last0_old_value:bv8;
var sw_failure_status_register__last0_value:bv8;
var sw_failure_status_register__next_write_site:int;
var sw_failure_status_register__last_write_site:int;
const sw_failure_status_register.size:bv1;
axiom sw_failure_status_register.size == 1bv1;
var sw_hdr:sw_header_t;

// sw_Header sw_mirror_bridged_metadata_h
var sw_hdr.bridged_md:sw_Ref;
var sw_hdr.bridged_md.valid:bool;
var sw_hdr.bridged_md.pkt_type:sw_pkt_type_t;

// sw_Header sw_ethernet_t
var sw_hdr.ethernet:sw_Ref;
var sw_hdr.ethernet.valid:bool;
var sw_hdr.ethernet.dstAddr:sw_mac_addr_t;
var sw_hdr.ethernet.srcAddr:sw_mac_addr_t;
var sw_hdr.ethernet.etherType:sw_ether_type_t;

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
var sw_hdr.ipv4.protocol:sw_ip_protocol_t;
var sw_hdr.ipv4.hdrChecksum:bv16;
var sw_hdr.ipv4.srcAddr:sw_ipv4_addr_t;
var sw_hdr.ipv4.dstAddr:sw_ipv4_addr_t;

// sw_Header sw_tcp_t
var sw_hdr.tcp:sw_Ref;
var sw_hdr.tcp.valid:bool;
var sw_hdr.tcp.srcPort:bv16;
var sw_hdr.tcp.dstPort:bv16;
var sw_hdr.tcp.seqNo:bv32;
var sw_hdr.tcp.ackNo:bv32;
var sw_hdr.tcp.dataOffset:bv4;
var sw_hdr.tcp.res:bv3;
var sw_hdr.tcp.ecn:bv3;
var sw_hdr.tcp.ctrl:bv6;
var sw_hdr.tcp.window:bv16;
var sw_hdr.tcp.checksum:bv16;
var sw_hdr.tcp.urgentPtr:bv16;

// sw_Header sw_udp_t
var sw_hdr.udp:sw_Ref;
var sw_hdr.udp.valid:bool;
var sw_hdr.udp.srcPort:bv16;
var sw_hdr.udp.dstPort:bv16;
var sw_hdr.udp.pkt_length:bv16;
var sw_hdr.udp.checksum:bv16;

// sw_Header sw_nlk_hdr_t
var sw_hdr.nlk_hdr:sw_Ref;
var sw_hdr.nlk_hdr.valid:bool;
var sw_hdr.nlk_hdr.recirc_flag:bv8;
var sw_hdr.nlk_hdr.op:bv8;
var sw_hdr.nlk_hdr.mode:bv8;
var sw_hdr.nlk_hdr.client_id:bv8;
var sw_hdr.nlk_hdr.tid:bv32;
var sw_hdr.nlk_hdr.lock:bv32;
var sw_hdr.nlk_hdr.timestamp_lo:bv32;
var sw_hdr.nlk_hdr.timestamp_hi:bv32;
var sw_hdr.nlk_hdr.empty_slots:bv32;
var sw_hdr.nlk_hdr.head:bv32;
var sw_hdr.nlk_hdr.tail:bv32;
var sw_hdr.nlk_hdr.ncnt:bv8;
var sw_hdr.nlk_hdr.transferred:bv8;

// sw_Header sw_adm_hdr_t
var sw_hdr.adm_hdr:sw_Ref;
var sw_hdr.adm_hdr.valid:bool;
var sw_hdr.adm_hdr.op:bv8;
var sw_hdr.adm_hdr.lock:bv32;
var sw_hdr.adm_hdr.new_left:bv32;
var sw_hdr.adm_hdr.new_right:bv32;

// sw_Header sw_recirculate_hdr_t
var sw_hdr.recirculate_hdr:sw_Ref;
var sw_hdr.recirculate_hdr.valid:bool;
var sw_hdr.recirculate_hdr.dequeued_mode:bv8;
var sw_hdr.recirculate_hdr.cur_head:bv32;
var sw_hdr.recirculate_hdr.cur_tail:bv32;

// sw_Header sw_probe_hdr_t
var sw_hdr.probe_hdr:sw_Ref;
var sw_hdr.probe_hdr.valid:bool;
var sw_hdr.probe_hdr.failure_status:bv8;
var sw_hdr.probe_hdr.op:bv8;
var sw_hdr.probe_hdr.mode:bv8;
var sw_hdr.probe_hdr.client_id:bv8;
var sw_hdr.probe_hdr.tid:bv32;
var sw_hdr.probe_hdr.lock:bv32;
var sw_hdr.probe_hdr.timestamp_lo:bv32;
var sw_hdr.probe_hdr.timestamp_hi:bv32;
var sw_eg_md:sw_metadata_t;
var sw_eg_md.head:bv32;
var sw_eg_md.tail:bv32;
var sw_eg_md.queue_size_op:bv32;
var sw_eg_md.do_resubmit:bv1;
var sw_eg_md.routed:bv1;
var sw_eg_md.dropped:bv1;
var sw_eg_md.lock_exist:bv1;
var sw_eg_md.recirc_flag:bv8;
var sw_eg_md.dequeued_mode:bv8;
var sw_eg_md.recirced:bv2;
var sw_eg_md.locked:bv32;
var sw_eg_md.left:bv32;
var sw_eg_md.right:bv32;
var sw_eg_md.src_ip:bv32;
var sw_eg_md.dst_ip:bv32;
var sw_eg_md.empty_slots:bv32;
var sw_eg_md.length_in_server:bv32;
var sw_eg_md.size_of_queue:bv32;
var sw_eg_md.empty_slots_before_pop:bv32;
var sw_eg_md.ts_hi:bv32;
var sw_eg_md.ts_lo:bv32;
var sw_eg_md.lock_id:bv32;
var sw_eg_md.failure_status:bv8;
var sw_eg_md.ing_mir_ses:sw_MirrorId_t;
var sw_eg_md.clone_md:bv8;
var sw_eg_md.mode:bv8;
var sw_eg_md.client_id:bv8;
var sw_eg_md.tid:bv32;
var sw_eg_md.ip_address:bv32;
var sw_eg_md.timestamp_lo:bv32;
var sw_eg_md.timestamp_hi:bv32;
var sw_eg_md.pkt_type:sw_pkt_type_t;

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
var sw_eg_intr_md_from_prsr:sw_egress_intrinsic_metadata_from_parser_t;
var sw_eg_intr_md_from_prsr.global_tstamp:bv48;
var sw_eg_intr_md_from_prsr.global_ver:bv32;
var sw_eg_intr_md_from_prsr.parser_err:bv16;
var sw_eg_intr_dprs_md:sw_egress_intrinsic_metadata_for_deparser_t;
var sw_eg_intr_dprs_md.drop_ctl:bv3;
var sw_eg_intr_dprs_md.mirror_type:sw_MirrorType_t;
var sw_eg_intr_dprs_md.coalesce_flush:bv1;
var sw_eg_intr_dprs_md.coalesce_length:bv7;
var sw_eg_intr_oport_md:sw_egress_intrinsic_metadata_for_output_port_t;
var sw_eg_intr_oport_md.capture_tstamp_on_tx:bv1;
var sw_eg_intr_oport_md.update_delay_on_tx:bv1;

// sw_Table sw_SwitchEgress_change_mode_table sw_Actionlist sw_Declaration
type sw_SwitchEgress_change_mode_table.action;
var sw_SwitchEgress_change_mode_table.SwitchEgress_change_mode_act.udp_src_port:bv16;
const unique sw_SwitchEgress_change_mode_table.action.SwitchEgress_change_mode_act : sw_SwitchEgress_change_mode_table.action;
const unique sw_SwitchEgress_change_mode_table.action.NoAction : sw_SwitchEgress_change_mode_table.action;
var sw_SwitchEgress_change_mode_table.action_run : sw_SwitchEgress_change_mode_table.action;
var sw_SwitchEgress_change_mode_table.hit : bool;

// sw_Table sw_SwitchEgress_test_table sw_Actionlist sw_Declaration
type sw_SwitchEgress_test_table.action;
const unique sw_SwitchEgress_test_table.action.SwitchEgress_nop : sw_SwitchEgress_test_table.action;
var sw_SwitchEgress_test_table.action_run : sw_SwitchEgress_test_table.action;
var sw_SwitchEgress_test_table.hit : bool;

// sw_Table sw_SwitchEgress_change_op_type_table sw_Actionlist sw_Declaration
type sw_SwitchEgress_change_op_type_table.action;
const unique sw_SwitchEgress_change_op_type_table.action.SwitchEgress_change_op_type_action : sw_SwitchEgress_change_op_type_table.action;
var sw_SwitchEgress_change_op_type_table.action_run : sw_SwitchEgress_change_op_type_table.action;
var sw_SwitchEgress_change_op_type_table.hit : bool;
var sw_ig_md:sw_metadata_t;
var sw_ig_md.head:bv32;
var sw_ig_md.tail:bv32;
var sw_ig_md.queue_size_op:bv32;
var sw_ig_md.do_resubmit:bv1;
var sw_ig_md.routed:bv1;
var sw_ig_md.dropped:bv1;
var sw_ig_md.lock_exist:bv1;
var sw_ig_md.recirc_flag:bv8;
var sw_ig_md.dequeued_mode:bv8;
var sw_ig_md.recirced:bv2;
var sw_ig_md.locked:bv32;
var sw_ig_md.left:bv32;
var sw_ig_md.right:bv32;
var sw_ig_md.src_ip:bv32;
var sw_ig_md.dst_ip:bv32;
var sw_ig_md.empty_slots:bv32;
var sw_ig_md.length_in_server:bv32;
var sw_ig_md.size_of_queue:bv32;
var sw_ig_md.empty_slots_before_pop:bv32;
var sw_ig_md.ts_hi:bv32;
var sw_ig_md.ts_lo:bv32;
var sw_ig_md.lock_id:bv32;
var sw_ig_md.failure_status:bv8;
var sw_ig_md.ing_mir_ses:sw_MirrorId_t;
var sw_ig_md.clone_md:bv8;
var sw_ig_md.mode:bv8;
var sw_ig_md.client_id:bv8;
var sw_ig_md.tid:bv32;
var sw_ig_md.ip_address:bv32;
var sw_ig_md.timestamp_lo:bv32;
var sw_ig_md.timestamp_hi:bv32;
var sw_ig_md.pkt_type:sw_pkt_type_t;

// sw_Header sw_ingress_intrinsic_metadata_t
var sw_ig_intr_md:sw_Ref;
var sw_ig_intr_md.valid:bool;
var sw_ig_intr_md.resubmit_flag:bv1;
var sw_ig_intr_md._pad1:bv1;
var sw_ig_intr_md.packet_version:bv2;
var sw_ig_intr_md._pad2:bv3;
var sw_ig_intr_md.ingress_port:sw_PortId_t;
var sw_ig_intr_md.ingress_mac_tstamp:bv48;
var sw_ig_intr_prsr_md:sw_ingress_intrinsic_metadata_from_parser_t;
var sw_ig_intr_prsr_md.global_tstamp:bv48;
var sw_ig_intr_prsr_md.global_ver:bv32;
var sw_ig_intr_prsr_md.parser_err:bv16;
var sw_ig_intr_dprsr_md:sw_ingress_intrinsic_metadata_for_deparser_t;
var sw_ig_intr_dprsr_md.drop_ctl:bv3;
var sw_ig_intr_dprsr_md.digest_type:sw_DigestType_t;
var sw_ig_intr_dprsr_md.resubmit_type:sw_ResubmitType_t;
var sw_ig_intr_dprsr_md.mirror_type:sw_MirrorType_t;
var sw_ig_intr_tm_md:sw_ingress_intrinsic_metadata_for_tm_t;
var sw_ig_intr_tm_md.ucast_egress_port:sw_PortId_t;
var sw_ig_intr_tm_md.bypass_egress:bv1;
var sw_ig_intr_tm_md.deflect_on_drop:bv1;
var sw_ig_intr_tm_md.ingress_cos:bv3;
var sw_ig_intr_tm_md.qid:sw_QueueId_t;
var sw_ig_intr_tm_md.icos_for_copy_to_cpu:bv3;
var sw_ig_intr_tm_md.copy_to_cpu:bv1;
var sw_ig_intr_tm_md.packet_color:bv2;
var sw_ig_intr_tm_md.disable_ucast_cutthru:bv1;
var sw_ig_intr_tm_md.enable_mcast_cutthru:bv1;
var sw_ig_intr_tm_md.mcast_grp_a:sw_MulticastGroupId_t;
var sw_ig_intr_tm_md.mcast_grp_b:sw_MulticastGroupId_t;
var sw_ig_intr_tm_md.level1_mcast_hash:bv13;
var sw_ig_intr_tm_md.level2_mcast_hash:bv13;
var sw_ig_intr_tm_md.level1_exclusion_id:sw_L1ExclusionId_t;
var sw_ig_intr_tm_md.level2_exclusion_id:sw_L2ExclusionId_t;
var sw_ig_intr_tm_md.rid:bv16;
var sw___ra_val_SwitchIngress_decode_get_queue_size_op_alu:bv32;
var sw___ra_ret_SwitchIngress_decode_get_queue_size_op_alu:bv32;
var sw___ra_val_SwitchIngress_decode_get_left_bound_alu:bv32;
var sw___ra_ret_SwitchIngress_decode_get_left_bound_alu:bv32;
var sw___ra_val_SwitchIngress_decode_get_right_bound_alu:bv32;
var sw___ra_ret_SwitchIngress_decode_get_right_bound_alu:bv32;

function {:builtin "bvsub"} sub.bv32(sw_left:bv32, sw_right:bv32) returns(bv32);

// sw_Table sw_SwitchIngress_decode_decode_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_decode_decode_table.action;
const unique sw_SwitchIngress_decode_decode_table.action.SwitchIngress_decode_decode_action : sw_SwitchIngress_decode_decode_table.action;
var sw_SwitchIngress_decode_decode_table.action_run : sw_SwitchIngress_decode_decode_table.action;
var sw_SwitchIngress_decode_decode_table.hit : bool;

// sw_Table sw_SwitchIngress_decode_get_left_bound_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_decode_get_left_bound_table.action;
const unique sw_SwitchIngress_decode_get_left_bound_table.action.SwitchIngress_decode_get_left_bound_action : sw_SwitchIngress_decode_get_left_bound_table.action;
var sw_SwitchIngress_decode_get_left_bound_table.action_run : sw_SwitchIngress_decode_get_left_bound_table.action;
var sw_SwitchIngress_decode_get_left_bound_table.hit : bool;

// sw_Table sw_SwitchIngress_decode_get_right_bound_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_decode_get_right_bound_table.action;
const unique sw_SwitchIngress_decode_get_right_bound_table.action.SwitchIngress_decode_get_right_bound_action : sw_SwitchIngress_decode_get_right_bound_table.action;
var sw_SwitchIngress_decode_get_right_bound_table.action_run : sw_SwitchIngress_decode_get_right_bound_table.action;
var sw_SwitchIngress_decode_get_right_bound_table.hit : bool;

// sw_Table sw_SwitchIngress_decode_get_size_of_queue_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_decode_get_size_of_queue_table.action;
const unique sw_SwitchIngress_decode_get_size_of_queue_table.action.SwitchIngress_decode_get_size_of_queue_action : sw_SwitchIngress_decode_get_size_of_queue_table.action;
var sw_SwitchIngress_decode_get_size_of_queue_table.action_run : sw_SwitchIngress_decode_get_size_of_queue_table.action;
var sw_SwitchIngress_decode_get_size_of_queue_table.hit : bool;

function {:builtin "bvugt"} bugt.bv32(sw_left:bv32, sw_right:bv32) returns(bool);

function {:builtin "bvadd"} add.bv32(sw_left:bv32, sw_right:bv32) returns(bv32);

function {:builtin "bvule"} bule.bv32(sw_left:bv32, sw_right:bv32) returns(bool);
var sw___ra_val_SwitchIngress_acquire_lock_dec_empty_slots_alu:sw_pair;
var sw___ra_ret_SwitchIngress_acquire_lock_dec_empty_slots_alu:bv32;
var sw___ra_val_SwitchIngress_acquire_lock_push_back_alu:sw_pair;
var sw___ra_ret_SwitchIngress_acquire_lock_push_back_alu:bv32;
var sw___ra_val_SwitchIngress_acquire_lock_acquire_shared_lock_alu:sw_pair;
var sw___ra_ret_SwitchIngress_acquire_lock_acquire_shared_lock_alu:bv32;
var sw___ra_val_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu:sw_pair;
var sw___ra_ret_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu:bv32;
var sw___ra_val_SwitchIngress_acquire_lock_update_tail_alu:bv32;
var sw___ra_ret_SwitchIngress_acquire_lock_update_tail_alu:bv32;
var sw___ra_val_SwitchIngress_acquire_lock_update_ip_array_alu:bv32;
var sw___ra_ret_SwitchIngress_acquire_lock_update_ip_array_alu:bv32;
var sw___ra_val_SwitchIngress_acquire_lock_update_mode_array_alu:bv8;
var sw___ra_ret_SwitchIngress_acquire_lock_update_mode_array_alu:bv8;
var sw___ra_val_SwitchIngress_acquire_lock_update_client_id_array_alu:bv8;
var sw___ra_ret_SwitchIngress_acquire_lock_update_client_id_array_alu:bv8;
var sw___ra_val_SwitchIngress_acquire_lock_update_tid_array_alu:bv32;
var sw___ra_ret_SwitchIngress_acquire_lock_update_tid_array_alu:bv32;
var sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu:bv32;
var sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu:bv32;
var sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu:bv32;
var sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu:bv32;

// sw_Table sw_SwitchIngress_acquire_lock_dec_empty_slots_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action;
const unique sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action.SwitchIngress_acquire_lock_dec_empty_slots_action : sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action;
const unique sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action.SwitchIngress_acquire_lock_push_back_action : sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action;
const unique sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action.NoAction_3 : sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action;
var sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action_run : sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action;
var sw_SwitchIngress_acquire_lock_dec_empty_slots_table.hit : bool;

// sw_Table sw_SwitchIngress_acquire_lock_acquire_lock_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_acquire_lock_acquire_lock_table.action;
const unique sw_SwitchIngress_acquire_lock_acquire_lock_table.action.SwitchIngress_acquire_lock_acquire_shared_lock_action : sw_SwitchIngress_acquire_lock_acquire_lock_table.action;
const unique sw_SwitchIngress_acquire_lock_acquire_lock_table.action.SwitchIngress_acquire_lock_acquire_exclusive_lock_action : sw_SwitchIngress_acquire_lock_acquire_lock_table.action;
const unique sw_SwitchIngress_acquire_lock_acquire_lock_table.action.NoAction_4 : sw_SwitchIngress_acquire_lock_acquire_lock_table.action;
var sw_SwitchIngress_acquire_lock_acquire_lock_table.action_run : sw_SwitchIngress_acquire_lock_acquire_lock_table.action;
var sw_SwitchIngress_acquire_lock_acquire_lock_table.hit : bool;

// sw_Table sw_SwitchIngress_acquire_lock_fix_src_port_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_acquire_lock_fix_src_port_table.action;
var sw_SwitchIngress_acquire_lock_fix_src_port_table.SwitchIngress_acquire_lock_fix_src_port_action.fix_port:bv16;
const unique sw_SwitchIngress_acquire_lock_fix_src_port_table.action.SwitchIngress_acquire_lock_fix_src_port_action : sw_SwitchIngress_acquire_lock_fix_src_port_table.action;
const unique sw_SwitchIngress_acquire_lock_fix_src_port_table.action.NoAction_5 : sw_SwitchIngress_acquire_lock_fix_src_port_table.action;
var sw_SwitchIngress_acquire_lock_fix_src_port_table.action_run : sw_SwitchIngress_acquire_lock_fix_src_port_table.action;
var sw_SwitchIngress_acquire_lock_fix_src_port_table.hit : bool;

// sw_Table sw_SwitchIngress_acquire_lock_set_tag_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_acquire_lock_set_tag_table.action;
const unique sw_SwitchIngress_acquire_lock_set_tag_table.action.SwitchIngress_acquire_lock_set_as_primary_action : sw_SwitchIngress_acquire_lock_set_tag_table.action;
const unique sw_SwitchIngress_acquire_lock_set_tag_table.action.SwitchIngress_acquire_lock_set_as_secondary_action : sw_SwitchIngress_acquire_lock_set_tag_table.action;
const unique sw_SwitchIngress_acquire_lock_set_tag_table.action.SwitchIngress_acquire_lock_set_as_failure_notification_action : sw_SwitchIngress_acquire_lock_set_tag_table.action;
const unique sw_SwitchIngress_acquire_lock_set_tag_table.action.NoAction_6 : sw_SwitchIngress_acquire_lock_set_tag_table.action;
var sw_SwitchIngress_acquire_lock_set_tag_table.action_run : sw_SwitchIngress_acquire_lock_set_tag_table.action;
var sw_SwitchIngress_acquire_lock_set_tag_table.hit : bool;

// sw_Table sw_SwitchIngress_acquire_lock_update_tail_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_acquire_lock_update_tail_table.action;
const unique sw_SwitchIngress_acquire_lock_update_tail_table.action.SwitchIngress_acquire_lock_update_tail_action : sw_SwitchIngress_acquire_lock_update_tail_table.action;
var sw_SwitchIngress_acquire_lock_update_tail_table.action_run : sw_SwitchIngress_acquire_lock_update_tail_table.action;
var sw_SwitchIngress_acquire_lock_update_tail_table.hit : bool;

// sw_Table sw_SwitchIngress_acquire_lock_forward_to_server_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_acquire_lock_forward_to_server_table.action;
var sw_SwitchIngress_acquire_lock_forward_to_server_table.SwitchIngress_acquire_lock_forward_to_server_action.server_ip:sw_ipv4_addr_t;
const unique sw_SwitchIngress_acquire_lock_forward_to_server_table.action.SwitchIngress_acquire_lock_forward_to_server_action : sw_SwitchIngress_acquire_lock_forward_to_server_table.action;
const unique sw_SwitchIngress_acquire_lock_forward_to_server_table.action.NoAction_7 : sw_SwitchIngress_acquire_lock_forward_to_server_table.action;
var sw_SwitchIngress_acquire_lock_forward_to_server_table.action_run : sw_SwitchIngress_acquire_lock_forward_to_server_table.action;
var sw_SwitchIngress_acquire_lock_forward_to_server_table.hit : bool;

// sw_Table sw_SwitchIngress_acquire_lock_update_ip_array_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_acquire_lock_update_ip_array_table.action;
const unique sw_SwitchIngress_acquire_lock_update_ip_array_table.action.SwitchIngress_acquire_lock_update_ip_array_action : sw_SwitchIngress_acquire_lock_update_ip_array_table.action;
var sw_SwitchIngress_acquire_lock_update_ip_array_table.action_run : sw_SwitchIngress_acquire_lock_update_ip_array_table.action;
var sw_SwitchIngress_acquire_lock_update_ip_array_table.hit : bool;

// sw_Table sw_SwitchIngress_acquire_lock_update_mode_array_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_acquire_lock_update_mode_array_table.action;
const unique sw_SwitchIngress_acquire_lock_update_mode_array_table.action.SwitchIngress_acquire_lock_update_mode_array_action : sw_SwitchIngress_acquire_lock_update_mode_array_table.action;
var sw_SwitchIngress_acquire_lock_update_mode_array_table.action_run : sw_SwitchIngress_acquire_lock_update_mode_array_table.action;
var sw_SwitchIngress_acquire_lock_update_mode_array_table.hit : bool;

// sw_Table sw_SwitchIngress_acquire_lock_update_client_id_array_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_acquire_lock_update_client_id_array_table.action;
const unique sw_SwitchIngress_acquire_lock_update_client_id_array_table.action.SwitchIngress_acquire_lock_update_client_id_array_action : sw_SwitchIngress_acquire_lock_update_client_id_array_table.action;
var sw_SwitchIngress_acquire_lock_update_client_id_array_table.action_run : sw_SwitchIngress_acquire_lock_update_client_id_array_table.action;
var sw_SwitchIngress_acquire_lock_update_client_id_array_table.hit : bool;

// sw_Table sw_SwitchIngress_acquire_lock_update_tid_array_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_acquire_lock_update_tid_array_table.action;
const unique sw_SwitchIngress_acquire_lock_update_tid_array_table.action.SwitchIngress_acquire_lock_update_tid_array_action : sw_SwitchIngress_acquire_lock_update_tid_array_table.action;
var sw_SwitchIngress_acquire_lock_update_tid_array_table.action_run : sw_SwitchIngress_acquire_lock_update_tid_array_table.action;
var sw_SwitchIngress_acquire_lock_update_tid_array_table.hit : bool;

// sw_Table sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action;
const unique sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action.SwitchIngress_acquire_lock_update_timestamp_hi_array_action : sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action;
var sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action_run : sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action;
var sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.hit : bool;

// sw_Table sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action;
const unique sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action.SwitchIngress_acquire_lock_update_timestamp_lo_array_action : sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action;
var sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action_run : sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action;
var sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.hit : bool;

// sw_Table sw_SwitchIngress_acquire_lock_notify_tail_client_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_acquire_lock_notify_tail_client_table.action;
const unique sw_SwitchIngress_acquire_lock_notify_tail_client_table.action.SwitchIngress_acquire_lock_notify_tail_client_action : sw_SwitchIngress_acquire_lock_notify_tail_client_table.action;
var sw_SwitchIngress_acquire_lock_notify_tail_client_table.action_run : sw_SwitchIngress_acquire_lock_notify_tail_client_table.action;
var sw_SwitchIngress_acquire_lock_notify_tail_client_table.hit : bool;

// sw_Table sw_SwitchIngress_acquire_lock_switch_direct_grant_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action;
const unique sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action.SwitchIngress_acquire_lock_switch_direct_grant_action : sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action;
var sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action_run : sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action;
var sw_SwitchIngress_acquire_lock_switch_direct_grant_table.hit : bool;

// sw_Table sw_SwitchIngress_acquire_lock_drop_packet_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_acquire_lock_drop_packet_table.action;
const unique sw_SwitchIngress_acquire_lock_drop_packet_table.action.SwitchIngress_acquire_lock_drop : sw_SwitchIngress_acquire_lock_drop_packet_table.action;
var sw_SwitchIngress_acquire_lock_drop_packet_table.action_run : sw_SwitchIngress_acquire_lock_drop_packet_table.action;
var sw_SwitchIngress_acquire_lock_drop_packet_table.hit : bool;
var sw___ra_val_SwitchIngress_release_lock_inc_empty_slots_alu:sw_pair;
var sw___ra_ret_SwitchIngress_release_lock_inc_empty_slots_alu:bv32;
var sw___ra_val_SwitchIngress_release_lock_update_head_alu:bv32;
var sw___ra_ret_SwitchIngress_release_lock_update_head_alu:bv32;
var sw___ra_val_SwitchIngress_release_lock_update_lock_alu:sw_pair;
var sw___ra_ret_SwitchIngress_release_lock_update_lock_alu:sw_pair;
var sw___ra_val_SwitchIngress_release_lock_get_tid_alu:bv32;
var sw___ra_ret_SwitchIngress_release_lock_get_tid_alu:bv32;
var sw___ra_val_SwitchIngress_release_lock_get_client_id_alu:bv8;
var sw___ra_ret_SwitchIngress_release_lock_get_client_id_alu:bv8;
var sw___ra_val_SwitchIngress_release_lock_get_mode_alu:bv8;
var sw___ra_ret_SwitchIngress_release_lock_get_mode_alu:bv8;
var sw___ra_val_SwitchIngress_release_lock_get_ip_alu:bv32;
var sw___ra_ret_SwitchIngress_release_lock_get_ip_alu:bv32;
var sw___ra_val_SwitchIngress_release_lock_get_tail_alu:bv32;
var sw___ra_ret_SwitchIngress_release_lock_get_tail_alu:bv32;

// sw_Table sw_SwitchIngress_release_lock_get_recirc_info_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_get_recirc_info_table.action;
const unique sw_SwitchIngress_release_lock_get_recirc_info_table.action.SwitchIngress_release_lock_get_recirc_info_action : sw_SwitchIngress_release_lock_get_recirc_info_table.action;
var sw_SwitchIngress_release_lock_get_recirc_info_table.action_run : sw_SwitchIngress_release_lock_get_recirc_info_table.action;
var sw_SwitchIngress_release_lock_get_recirc_info_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_inc_empty_slots_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_inc_empty_slots_table.action;
const unique sw_SwitchIngress_release_lock_inc_empty_slots_table.action.SwitchIngress_release_lock_inc_empty_slots_action : sw_SwitchIngress_release_lock_inc_empty_slots_table.action;
var sw_SwitchIngress_release_lock_inc_empty_slots_table.action_run : sw_SwitchIngress_release_lock_inc_empty_slots_table.action;
var sw_SwitchIngress_release_lock_inc_empty_slots_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_update_head_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_update_head_table.action;
const unique sw_SwitchIngress_release_lock_update_head_table.action.SwitchIngress_release_lock_update_head_action : sw_SwitchIngress_release_lock_update_head_table.action;
var sw_SwitchIngress_release_lock_update_head_table.action_run : sw_SwitchIngress_release_lock_update_head_table.action;
var sw_SwitchIngress_release_lock_update_head_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_update_lock_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_update_lock_table.action;
const unique sw_SwitchIngress_release_lock_update_lock_table.action.SwitchIngress_release_lock_update_lock_action : sw_SwitchIngress_release_lock_update_lock_table.action;
var sw_SwitchIngress_release_lock_update_lock_table.action_run : sw_SwitchIngress_release_lock_update_lock_table.action;
var sw_SwitchIngress_release_lock_update_lock_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_get_tail_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_get_tail_table.action;
const unique sw_SwitchIngress_release_lock_get_tail_table.action.SwitchIngress_release_lock_get_tail_action : sw_SwitchIngress_release_lock_get_tail_table.action;
var sw_SwitchIngress_release_lock_get_tail_table.action_run : sw_SwitchIngress_release_lock_get_tail_table.action;
var sw_SwitchIngress_release_lock_get_tail_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_fix_src_port_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_fix_src_port_table.action;
var sw_SwitchIngress_release_lock_fix_src_port_table.SwitchIngress_release_lock_fix_src_port_action.fix_port_3:bv16;
const unique sw_SwitchIngress_release_lock_fix_src_port_table.action.SwitchIngress_release_lock_fix_src_port_action : sw_SwitchIngress_release_lock_fix_src_port_table.action;
const unique sw_SwitchIngress_release_lock_fix_src_port_table.action.NoAction_8 : sw_SwitchIngress_release_lock_fix_src_port_table.action;
var sw_SwitchIngress_release_lock_fix_src_port_table.action_run : sw_SwitchIngress_release_lock_fix_src_port_table.action;
var sw_SwitchIngress_release_lock_fix_src_port_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_set_tag_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_set_tag_table.action;
const unique sw_SwitchIngress_release_lock_set_tag_table.action.SwitchIngress_release_lock_set_as_primary_action : sw_SwitchIngress_release_lock_set_tag_table.action;
const unique sw_SwitchIngress_release_lock_set_tag_table.action.SwitchIngress_release_lock_set_as_secondary_action : sw_SwitchIngress_release_lock_set_tag_table.action;
const unique sw_SwitchIngress_release_lock_set_tag_table.action.SwitchIngress_release_lock_set_as_failure_notification_action : sw_SwitchIngress_release_lock_set_tag_table.action;
const unique sw_SwitchIngress_release_lock_set_tag_table.action.NoAction_9 : sw_SwitchIngress_release_lock_set_tag_table.action;
var sw_SwitchIngress_release_lock_set_tag_table.action_run : sw_SwitchIngress_release_lock_set_tag_table.action;
var sw_SwitchIngress_release_lock_set_tag_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_get_mode_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_get_mode_table.action;
const unique sw_SwitchIngress_release_lock_get_mode_table.action.SwitchIngress_release_lock_get_mode_action : sw_SwitchIngress_release_lock_get_mode_table.action;
var sw_SwitchIngress_release_lock_get_mode_table.action_run : sw_SwitchIngress_release_lock_get_mode_table.action;
var sw_SwitchIngress_release_lock_get_mode_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_get_ip_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_get_ip_table.action;
const unique sw_SwitchIngress_release_lock_get_ip_table.action.SwitchIngress_release_lock_get_ip_action : sw_SwitchIngress_release_lock_get_ip_table.action;
var sw_SwitchIngress_release_lock_get_ip_table.action_run : sw_SwitchIngress_release_lock_get_ip_table.action;
var sw_SwitchIngress_release_lock_get_ip_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_forward_to_server_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_forward_to_server_table.action;
var sw_SwitchIngress_release_lock_forward_to_server_table.SwitchIngress_release_lock_forward_to_server_action.server_ip_3:sw_ipv4_addr_t;
const unique sw_SwitchIngress_release_lock_forward_to_server_table.action.SwitchIngress_release_lock_forward_to_server_action : sw_SwitchIngress_release_lock_forward_to_server_table.action;
const unique sw_SwitchIngress_release_lock_forward_to_server_table.action.NoAction_10 : sw_SwitchIngress_release_lock_forward_to_server_table.action;
var sw_SwitchIngress_release_lock_forward_to_server_table.action_run : sw_SwitchIngress_release_lock_forward_to_server_table.action;
var sw_SwitchIngress_release_lock_forward_to_server_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_notify_head_client_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_notify_head_client_table.action;
const unique sw_SwitchIngress_release_lock_notify_head_client_table.action.SwitchIngress_release_lock_notify_head_client_action : sw_SwitchIngress_release_lock_notify_head_client_table.action;
var sw_SwitchIngress_release_lock_notify_head_client_table.action_run : sw_SwitchIngress_release_lock_notify_head_client_table.action;
var sw_SwitchIngress_release_lock_notify_head_client_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_get_tid_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_get_tid_table.action;
const unique sw_SwitchIngress_release_lock_get_tid_table.action.SwitchIngress_release_lock_get_tid_action : sw_SwitchIngress_release_lock_get_tid_table.action;
var sw_SwitchIngress_release_lock_get_tid_table.action_run : sw_SwitchIngress_release_lock_get_tid_table.action;
var sw_SwitchIngress_release_lock_get_tid_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_get_client_id_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_get_client_id_table.action;
const unique sw_SwitchIngress_release_lock_get_client_id_table.action.SwitchIngress_release_lock_get_client_id_action : sw_SwitchIngress_release_lock_get_client_id_table.action;
var sw_SwitchIngress_release_lock_get_client_id_table.action_run : sw_SwitchIngress_release_lock_get_client_id_table.action;
var sw_SwitchIngress_release_lock_get_client_id_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_get_timestamp_hi_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_get_timestamp_hi_table.action;
const unique sw_SwitchIngress_release_lock_get_timestamp_hi_table.action.SwitchIngress_release_lock_get_timestamp_hi_action : sw_SwitchIngress_release_lock_get_timestamp_hi_table.action;
var sw_SwitchIngress_release_lock_get_timestamp_hi_table.action_run : sw_SwitchIngress_release_lock_get_timestamp_hi_table.action;
var sw_SwitchIngress_release_lock_get_timestamp_hi_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_get_timestamp_lo_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_get_timestamp_lo_table.action;
const unique sw_SwitchIngress_release_lock_get_timestamp_lo_table.action.SwitchIngress_release_lock_get_timestamp_lo_action : sw_SwitchIngress_release_lock_get_timestamp_lo_table.action;
var sw_SwitchIngress_release_lock_get_timestamp_lo_table.action_run : sw_SwitchIngress_release_lock_get_timestamp_lo_table.action;
var sw_SwitchIngress_release_lock_get_timestamp_lo_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_i2e_mirror_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_i2e_mirror_table.action;
var sw_SwitchIngress_release_lock_i2e_mirror_table.SwitchIngress_release_lock_i2e_mirror_action.mirror_id:sw_MirrorId_t;
const unique sw_SwitchIngress_release_lock_i2e_mirror_table.action.SwitchIngress_release_lock_i2e_mirror_action : sw_SwitchIngress_release_lock_i2e_mirror_table.action;
const unique sw_SwitchIngress_release_lock_i2e_mirror_table.action.NoAction_11 : sw_SwitchIngress_release_lock_i2e_mirror_table.action;
var sw_SwitchIngress_release_lock_i2e_mirror_table.action_run : sw_SwitchIngress_release_lock_i2e_mirror_table.action;
var sw_SwitchIngress_release_lock_i2e_mirror_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_metahead_plus_1_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_metahead_plus_1_table.action;
const unique sw_SwitchIngress_release_lock_metahead_plus_1_table.action.SwitchIngress_release_lock_metahead_plus_1_action : sw_SwitchIngress_release_lock_metahead_plus_1_table.action;
var sw_SwitchIngress_release_lock_metahead_plus_1_table.action_run : sw_SwitchIngress_release_lock_metahead_plus_1_table.action;
var sw_SwitchIngress_release_lock_metahead_plus_1_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_metahead_plus_2_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_metahead_plus_2_table.action;
const unique sw_SwitchIngress_release_lock_metahead_plus_2_table.action.SwitchIngress_release_lock_metahead_plus_2_action : sw_SwitchIngress_release_lock_metahead_plus_2_table.action;
var sw_SwitchIngress_release_lock_metahead_plus_2_table.action_run : sw_SwitchIngress_release_lock_metahead_plus_2_table.action;
var sw_SwitchIngress_release_lock_metahead_plus_2_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_mark_to_resubmit_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_mark_to_resubmit_table.action;
const unique sw_SwitchIngress_release_lock_mark_to_resubmit_table.action.SwitchIngress_release_lock_mark_to_resubmit_action : sw_SwitchIngress_release_lock_mark_to_resubmit_table.action;
var sw_SwitchIngress_release_lock_mark_to_resubmit_table.action_run : sw_SwitchIngress_release_lock_mark_to_resubmit_table.action;
var sw_SwitchIngress_release_lock_mark_to_resubmit_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_mark_to_resubmit_2_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_mark_to_resubmit_2_table.action;
const unique sw_SwitchIngress_release_lock_mark_to_resubmit_2_table.action.SwitchIngress_release_lock_mark_to_resubmit_2_action : sw_SwitchIngress_release_lock_mark_to_resubmit_2_table.action;
var sw_SwitchIngress_release_lock_mark_to_resubmit_2_table.action_run : sw_SwitchIngress_release_lock_mark_to_resubmit_2_table.action;
var sw_SwitchIngress_release_lock_mark_to_resubmit_2_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_drop_packet_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_drop_packet_table.action;
const unique sw_SwitchIngress_release_lock_drop_packet_table.action.SwitchIngress_release_lock_drop : sw_SwitchIngress_release_lock_drop_packet_table.action;
var sw_SwitchIngress_release_lock_drop_packet_table.action_run : sw_SwitchIngress_release_lock_drop_packet_table.action;
var sw_SwitchIngress_release_lock_drop_packet_table.hit : bool;

// sw_Table sw_SwitchIngress_release_lock_resubmit_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_release_lock_resubmit_table.action;
const unique sw_SwitchIngress_release_lock_resubmit_table.action.SwitchIngress_release_lock_resubmit_action : sw_SwitchIngress_release_lock_resubmit_table.action;
var sw_SwitchIngress_release_lock_resubmit_table.action_run : sw_SwitchIngress_release_lock_resubmit_table.action;
var sw_SwitchIngress_release_lock_resubmit_table.hit : bool;

// sw_Table sw_SwitchIngress_check_lock_exist_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_check_lock_exist_table.action;
var sw_SwitchIngress_check_lock_exist_table.SwitchIngress_check_lock_exist_action.index_1:bv32;
const unique sw_SwitchIngress_check_lock_exist_table.action.SwitchIngress_check_lock_exist_action : sw_SwitchIngress_check_lock_exist_table.action;
const unique sw_SwitchIngress_check_lock_exist_table.action.NoAction_12 : sw_SwitchIngress_check_lock_exist_table.action;
var sw_SwitchIngress_check_lock_exist_table.action_run : sw_SwitchIngress_check_lock_exist_table.action;
var sw_SwitchIngress_check_lock_exist_table.hit : bool;

// sw_Table sw_SwitchIngress_fix_src_port_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_fix_src_port_table.action;
var sw_SwitchIngress_fix_src_port_table.SwitchIngress_fix_src_port_action.fix_port_4:bv16;
const unique sw_SwitchIngress_fix_src_port_table.action.SwitchIngress_fix_src_port_action : sw_SwitchIngress_fix_src_port_table.action;
const unique sw_SwitchIngress_fix_src_port_table.action.NoAction_13 : sw_SwitchIngress_fix_src_port_table.action;
var sw_SwitchIngress_fix_src_port_table.action_run : sw_SwitchIngress_fix_src_port_table.action;
var sw_SwitchIngress_fix_src_port_table.hit : bool;

// sw_Table sw_SwitchIngress_set_tag_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_set_tag_table.action;
const unique sw_SwitchIngress_set_tag_table.action.SwitchIngress_set_as_primary_action : sw_SwitchIngress_set_tag_table.action;
const unique sw_SwitchIngress_set_tag_table.action.SwitchIngress_set_as_secondary_action : sw_SwitchIngress_set_tag_table.action;
const unique sw_SwitchIngress_set_tag_table.action.SwitchIngress_set_as_failure_notification_action : sw_SwitchIngress_set_tag_table.action;
const unique sw_SwitchIngress_set_tag_table.action.NoAction_14 : sw_SwitchIngress_set_tag_table.action;
var sw_SwitchIngress_set_tag_table.action_run : sw_SwitchIngress_set_tag_table.action;
var sw_SwitchIngress_set_tag_table.hit : bool;

// sw_Table sw_SwitchIngress_forward_to_server_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_forward_to_server_table.action;
var sw_SwitchIngress_forward_to_server_table.SwitchIngress_forward_to_server_action.server_ip_4:sw_ipv4_addr_t;
const unique sw_SwitchIngress_forward_to_server_table.action.SwitchIngress_forward_to_server_action : sw_SwitchIngress_forward_to_server_table.action;
const unique sw_SwitchIngress_forward_to_server_table.action.NoAction_15 : sw_SwitchIngress_forward_to_server_table.action;
var sw_SwitchIngress_forward_to_server_table.action_run : sw_SwitchIngress_forward_to_server_table.action;
var sw_SwitchIngress_forward_to_server_table.hit : bool;

// sw_Table sw_SwitchIngress_ipv4_route_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_ipv4_route_table.action;
var sw_SwitchIngress_ipv4_route_table.SwitchIngress_set_egress.egress_spec:sw_PortId_t;
const unique sw_SwitchIngress_ipv4_route_table.action.SwitchIngress_set_egress : sw_SwitchIngress_ipv4_route_table.action;
const unique sw_SwitchIngress_ipv4_route_table.action.SwitchIngress_drop : sw_SwitchIngress_ipv4_route_table.action;
var sw_SwitchIngress_ipv4_route_table.action_run : sw_SwitchIngress_ipv4_route_table.action;
var sw_SwitchIngress_ipv4_route_table.hit : bool;

// sw_Table sw_SwitchIngress_ipv4_route_table_2 sw_Actionlist sw_Declaration
type sw_SwitchIngress_ipv4_route_table_2.action;
var sw_SwitchIngress_ipv4_route_table_2.set_egress_1.egress_spec_1:sw_PortId_t;
const unique sw_SwitchIngress_ipv4_route_table_2.action.set_egress_1 : sw_SwitchIngress_ipv4_route_table_2.action;
const unique sw_SwitchIngress_ipv4_route_table_2.action.drop_0 : sw_SwitchIngress_ipv4_route_table_2.action;
var sw_SwitchIngress_ipv4_route_table_2.action_run : sw_SwitchIngress_ipv4_route_table_2.action;
var sw_SwitchIngress_ipv4_route_table_2.hit : bool;

function {:builtin "bvadd"} add.bv8(sw_left:bv8, sw_right:bv8) returns(bv8);

// sw_Table sw_SwitchIngress_recirculate_table_2 sw_Actionlist sw_Declaration
type sw_SwitchIngress_recirculate_table_2.action;
const unique sw_SwitchIngress_recirculate_table_2.action.SwitchIngress_do_recirculate_2 : sw_SwitchIngress_recirculate_table_2.action;
var sw_SwitchIngress_recirculate_table_2.action_run : sw_SwitchIngress_recirculate_table_2.action;
var sw_SwitchIngress_recirculate_table_2.hit : bool;

// sw_Table sw_SwitchIngress_recirculate_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_recirculate_table.action;
const unique sw_SwitchIngress_recirculate_table.action.SwitchIngress_do_recirculate : sw_SwitchIngress_recirculate_table.action;
var sw_SwitchIngress_recirculate_table.action_run : sw_SwitchIngress_recirculate_table.action;
var sw_SwitchIngress_recirculate_table.hit : bool;

// sw_Table sw_SwitchIngress_i2e_clone_table sw_Actionlist sw_Declaration
type sw_SwitchIngress_i2e_clone_table.action;
var sw_SwitchIngress_i2e_clone_table.SwitchIngress_i2e_clone_action.mirror_id_2:sw_MirrorId_t;
const unique sw_SwitchIngress_i2e_clone_table.action.SwitchIngress_i2e_clone_action : sw_SwitchIngress_i2e_clone_table.action;
const unique sw_SwitchIngress_i2e_clone_table.action.drop_1 : sw_SwitchIngress_i2e_clone_table.action;
var sw_SwitchIngress_i2e_clone_table.action_run : sw_SwitchIngress_i2e_clone_table.action;
var sw_SwitchIngress_i2e_clone_table.hit : bool;

function {:builtin "bvult"} bult.bv8(sw_left:bv8, sw_right:bv8) returns(bool);
var sw_pkt:sw_Ref;

// sw_Header sw_mirror_hdr_t
var sw_tmp:sw_Ref;
var sw_tmp.valid:bool;
var sw_tmp.pkt_type:sw_pkt_type_t;
var sw_tmp.mode:bv8;
var sw_tmp.client_id:bv8;
var sw_tmp.tid:bv32;
var sw_tmp.ip_address:bv32;
var sw_tmp.timestamp_lo:bv32;
var sw_tmp.timestamp_hi:bv32;

// sw_Header sw_mirror_hdr_t
var sw_mirror_md_0:sw_Ref;
var sw_mirror_md_0.valid:bool;
var sw_mirror_md_0.pkt_type:sw_pkt_type_t;
var sw_mirror_md_0.mode:bv8;
var sw_mirror_md_0.client_id:bv8;
var sw_mirror_md_0.tid:bv32;
var sw_mirror_md_0.ip_address:bv32;
var sw_mirror_md_0.timestamp_lo:bv32;
var sw_mirror_md_0.timestamp_hi:bv32;

// sw_Header sw_mirror_hdr_t
var sw_mirror_hdr_0:sw_Ref;
var sw_mirror_hdr_0.valid:bool;
var sw_mirror_hdr_0.pkt_type:sw_pkt_type_t;
var sw_mirror_hdr_0.mode:bv8;
var sw_mirror_hdr_0.client_id:bv8;
var sw_mirror_hdr_0.tid:bv32;
var sw_mirror_hdr_0.ip_address:bv32;
var sw_mirror_hdr_0.timestamp_lo:bv32;
var sw_mirror_hdr_0.timestamp_hi:bv32;

function {:builtin "bvsub"} sub.bv17(sw_left:bv17, sw_right:bv17) returns(bv17);

function {:builtin "bvsub"} sub.bv33(sw_left:bv33, sw_right:bv33) returns(bv33);

// sw_Action sw_NoAction
procedure {:inline 1} sw_NoAction()
{
}

// sw_Action sw_NoAction_10
procedure {:inline 1} sw_NoAction_10()
{
}

// sw_Action sw_NoAction_11
procedure {:inline 1} sw_NoAction_11()
{
}

// sw_Action sw_NoAction_12
procedure {:inline 1} sw_NoAction_12()
{
}

// sw_Action sw_NoAction_13
procedure {:inline 1} sw_NoAction_13()
{
}

// sw_Action sw_NoAction_14
procedure {:inline 1} sw_NoAction_14()
{
}

// sw_Action sw_NoAction_15
procedure {:inline 1} sw_NoAction_15()
{
}

// sw_Action sw_NoAction_3
procedure {:inline 1} sw_NoAction_3()
{
}

// sw_Action sw_NoAction_4
procedure {:inline 1} sw_NoAction_4()
{
}

// sw_Action sw_NoAction_5
procedure {:inline 1} sw_NoAction_5()
{
}

// sw_Action sw_NoAction_6
procedure {:inline 1} sw_NoAction_6()
{
}

// sw_Action sw_NoAction_7
procedure {:inline 1} sw_NoAction_7()
{
}

// sw_Action sw_NoAction_8
procedure {:inline 1} sw_NoAction_8()
{
}

// sw_Action sw_NoAction_9
procedure {:inline 1} sw_NoAction_9()
{
}

// sw_Control sw_SwitchEgress
procedure {:inline 1} sw_SwitchEgress()
	modifies sw_SwitchEgress_change_mode_table.action_run, sw_SwitchEgress_change_mode_table.hit, sw_SwitchEgress_change_op_type_table.action_run, sw_SwitchEgress_change_op_type_table.hit, sw_SwitchEgress_test_table.action_run, sw_SwitchEgress_test_table.hit, sw_eg_md.tid, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.srcAddr, sw_hdr.nlk_hdr.client_id, sw_hdr.nlk_hdr.head, sw_hdr.nlk_hdr.mode, sw_hdr.nlk_hdr.op, sw_hdr.nlk_hdr.recirc_flag, sw_hdr.nlk_hdr.tail, sw_hdr.nlk_hdr.tid, sw_hdr.udp.dstPort, sw_hdr.udp.srcPort;
{
    call sw_SwitchEgress_test_table.apply();
    call sw_SwitchEgress_change_op_type_table.apply();
    call sw_SwitchEgress_change_mode_table.apply();
}

// sw_Control sw_SwitchEgressDeparser
procedure {:inline 1} sw_SwitchEgressDeparser()
{
    call sw_pkt.emit(sw_hdr);
}

// sw_Parser sw_SwitchEgressParser
procedure {:inline 1} sw_SwitchEgressParser()
	modifies sw_drop, sw_eg_md.client_id, sw_eg_md.clone_md, sw_eg_md.ip_address, sw_eg_md.mode, sw_eg_md.tid, sw_eg_md.timestamp_hi, sw_eg_md.timestamp_lo, sw_isValid, sw_mirror_hdr_0, sw_mirror_md_0;
{
    goto sw_State$SwitchEgressParser$start;

        sw_State$SwitchEgressParser$start:
    call sw_packet_in.extract(sw_eg_intr_md);
    havoc sw_mirror_md_0;
    goto sw_State$SwitchEgressParser$start$parse_bridged_md_2, sw_State$SwitchEgressParser$start$parse_mirror_1, sw_State$SwitchEgressParser$start$DEFAULT;
    
sw_State$SwitchEgressParser$start$parse_bridged_md_2:
    assume (sw_mirror_md_0.pkt_type == 0bv8);
    goto sw_State$SwitchEgressParser$parse_bridged_md;
    
sw_State$SwitchEgressParser$start$parse_mirror_1:
    assume (sw_mirror_md_0.pkt_type == 1bv8);
    goto sw_State$SwitchEgressParser$parse_mirror;

    sw_State$SwitchEgressParser$start$DEFAULT:
    assume(!(sw_mirror_md_0.pkt_type == 0bv8)&&!(sw_mirror_md_0.pkt_type == 1bv8));
goto sw_State$reject;

        sw_State$SwitchEgressParser$parse_bridged_md:
    call sw_packet_in.extract(sw_hdr.bridged_md);
    goto sw_State$SwitchEgressParser$parse_ethernet;

        sw_State$SwitchEgressParser$parse_mirror:
    call sw_setInvalid(sw_mirror_hdr_0);
    call sw_packet_in.extract(sw_mirror_hdr_0);
    sw_eg_md.clone_md := 1bv8;
    sw_eg_md.mode := sw_mirror_hdr_0.mode;
    sw_eg_md.tid := sw_mirror_hdr_0.tid;
    sw_eg_md.timestamp_lo := sw_mirror_hdr_0.timestamp_lo;
    sw_eg_md.timestamp_hi := sw_mirror_hdr_0.timestamp_hi;
    sw_eg_md.client_id := sw_mirror_hdr_0.client_id;
    sw_eg_md.ip_address := sw_mirror_hdr_0.ip_address;
    goto sw_State$SwitchEgressParser$parse_ethernet;

        sw_State$SwitchEgressParser$parse_ethernet:
    call sw_packet_in.extract(sw_hdr.ethernet);
    goto sw_State$SwitchEgressParser$parse_ethernet$parse_ipv4_2, sw_State$SwitchEgressParser$parse_ethernet$DEFAULT;
    
sw_State$SwitchEgressParser$parse_ethernet$parse_ipv4_2:
    assume (sw_hdr.ethernet.etherType == 2048bv16);
    goto sw_State$SwitchEgressParser$parse_ipv4;

    sw_State$SwitchEgressParser$parse_ethernet$DEFAULT:
    assume(!(sw_hdr.ethernet.etherType == 2048bv16));
    goto sw_State$accept;

        sw_State$SwitchEgressParser$parse_ipv4:
    call sw_packet_in.extract(sw_hdr.ipv4);
    goto sw_State$SwitchEgressParser$parse_ipv4$parse_tcp_3, sw_State$SwitchEgressParser$parse_ipv4$parse_udp_2, sw_State$SwitchEgressParser$parse_ipv4$DEFAULT;
    
sw_State$SwitchEgressParser$parse_ipv4$parse_tcp_3:
    assume (sw_hdr.ipv4.protocol == 6bv8);
    goto sw_State$SwitchEgressParser$parse_tcp;
    
sw_State$SwitchEgressParser$parse_ipv4$parse_udp_2:
    assume (sw_hdr.ipv4.protocol == 17bv8);
    goto sw_State$SwitchEgressParser$parse_udp;

    sw_State$SwitchEgressParser$parse_ipv4$DEFAULT:
    assume(!(sw_hdr.ipv4.protocol == 6bv8)&&!(sw_hdr.ipv4.protocol == 17bv8));
    goto sw_State$accept;

        sw_State$SwitchEgressParser$parse_tcp:
    call sw_packet_in.extract(sw_hdr.tcp);
    goto sw_State$accept;

        sw_State$SwitchEgressParser$parse_udp:
    call sw_packet_in.extract(sw_hdr.udp);
    goto sw_State$SwitchEgressParser$parse_udp$parse_nlk_hdr_3, sw_State$SwitchEgressParser$parse_udp$parse_nlk_hdr_2, sw_State$SwitchEgressParser$parse_udp$DEFAULT;
    
sw_State$SwitchEgressParser$parse_udp$parse_nlk_hdr_3:
    assume (sw_hdr.udp.dstPort == 8888bv16);
    goto sw_State$SwitchEgressParser$parse_nlk_hdr;
    
sw_State$SwitchEgressParser$parse_udp$parse_nlk_hdr_2:
    assume (sw_hdr.udp.dstPort == 8889bv16);
    goto sw_State$SwitchEgressParser$parse_nlk_hdr;

    sw_State$SwitchEgressParser$parse_udp$DEFAULT:
    assume(!(sw_hdr.udp.dstPort == 8888bv16)&&!(sw_hdr.udp.dstPort == 8889bv16));
    goto sw_State$accept;

        sw_State$SwitchEgressParser$parse_nlk_hdr:
    call sw_packet_in.extract(sw_hdr.nlk_hdr);
    goto sw_State$accept;

    sw_State$accept:
    call sw_accept();
    goto sw_Exit;

    sw_State$reject:
    call sw_reject();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchEgress_change_mode_act
procedure {:inline 1} sw_SwitchEgress_change_mode_act(sw_udp_src_port:bv16)
	modifies sw_hdr.udp.srcPort;
{
    sw_hdr.udp.srcPort := sw_udp_src_port;
}

// sw_Table sw_SwitchEgress_change_mode_table
procedure {:inline 1} sw_SwitchEgress_change_mode_table.apply()
	modifies sw_SwitchEgress_change_mode_table.action_run, sw_SwitchEgress_change_mode_table.hit, sw_eg_md.tid, sw_hdr.udp.srcPort;
{
    sw_eg_md.tid := sw_eg_md.tid;
    sw_SwitchEgress_change_mode_table.hit := false;
    sw_SwitchEgress_change_mode_table.action_run := sw_SwitchEgress_change_mode_table.action.NoAction;
    call sw_NoAction();
    goto sw_Exit;

    sw_action_SwitchEgress_change_mode_act:
    assume sw_SwitchEgress_change_mode_table.action_run == sw_SwitchEgress_change_mode_table.action.SwitchEgress_change_mode_act;
    call sw_SwitchEgress_change_mode_act(sw_SwitchEgress_change_mode_table.SwitchEgress_change_mode_act.udp_src_port);
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchEgress_change_op_type_action
procedure {:inline 1} sw_SwitchEgress_change_op_type_action()
	modifies sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.srcAddr, sw_hdr.nlk_hdr.client_id, sw_hdr.nlk_hdr.head, sw_hdr.nlk_hdr.mode, sw_hdr.nlk_hdr.op, sw_hdr.nlk_hdr.recirc_flag, sw_hdr.nlk_hdr.tail, sw_hdr.nlk_hdr.tid, sw_hdr.udp.dstPort;
{
    sw_hdr.nlk_hdr.recirc_flag := 0bv8;
    sw_hdr.nlk_hdr.op := 0bv8;
    sw_hdr.nlk_hdr.head := sw_eg_md.timestamp_lo;
    sw_hdr.nlk_hdr.tail := sw_eg_md.timestamp_hi;
    sw_hdr.nlk_hdr.tid := sw_eg_md.tid;
    sw_hdr.nlk_hdr.mode := sw_eg_md.mode;
    sw_hdr.nlk_hdr.client_id := sw_eg_md.client_id;
    sw_hdr.ipv4.dstAddr := sw_eg_md.ip_address;
    sw_hdr.ipv4.srcAddr := sw_eg_md.ip_address;
    sw_hdr.udp.dstPort := 8888bv16;
}

// sw_Table sw_SwitchEgress_change_op_type_table
procedure {:inline 1} sw_SwitchEgress_change_op_type_table.apply()
	modifies sw_SwitchEgress_change_op_type_table.action_run, sw_SwitchEgress_change_op_type_table.hit, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.srcAddr, sw_hdr.nlk_hdr.client_id, sw_hdr.nlk_hdr.head, sw_hdr.nlk_hdr.mode, sw_hdr.nlk_hdr.op, sw_hdr.nlk_hdr.recirc_flag, sw_hdr.nlk_hdr.tail, sw_hdr.nlk_hdr.tid, sw_hdr.udp.dstPort;
{
    sw_SwitchEgress_change_op_type_table.hit := false;
    sw_SwitchEgress_change_op_type_table.action_run := sw_SwitchEgress_change_op_type_table.action.SwitchEgress_change_op_type_action;
    call sw_SwitchEgress_change_op_type_action();
    goto sw_Exit;

    sw_action_SwitchEgress_change_op_type_action:
    assume sw_SwitchEgress_change_op_type_table.action_run == sw_SwitchEgress_change_op_type_table.action.SwitchEgress_change_op_type_action;
    call sw_SwitchEgress_change_op_type_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchEgress_nop
procedure {:inline 1} sw_SwitchEgress_nop()
{
}

// sw_Table sw_SwitchEgress_test_table
procedure {:inline 1} sw_SwitchEgress_test_table.apply()
	modifies sw_SwitchEgress_test_table.action_run, sw_SwitchEgress_test_table.hit, sw_hdr.ipv4.srcAddr;
{
    sw_hdr.ipv4.srcAddr := sw_hdr.ipv4.srcAddr;
    sw_SwitchEgress_test_table.hit := false;
    sw_SwitchEgress_test_table.action_run := sw_SwitchEgress_test_table.action.SwitchEgress_nop;
    call sw_SwitchEgress_nop();
    goto sw_Exit;

    sw_action_SwitchEgress_nop:
    assume sw_SwitchEgress_test_table.action_run == sw_SwitchEgress_test_table.action.SwitchEgress_nop;
    call sw_SwitchEgress_nop();
    goto sw_Exit;

    sw_Exit:
}

// sw_Control sw_SwitchIngress
procedure {:inline 1} sw_SwitchIngress()
	modifies sw_SwitchIngress_acquire_lock_acquire_lock_table.action_run, sw_SwitchIngress_acquire_lock_acquire_lock_table.hit, sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action_run, sw_SwitchIngress_acquire_lock_dec_empty_slots_table.hit, sw_SwitchIngress_acquire_lock_drop_packet_table.action_run, sw_SwitchIngress_acquire_lock_drop_packet_table.hit, sw_SwitchIngress_acquire_lock_fix_src_port_table.action_run, sw_SwitchIngress_acquire_lock_fix_src_port_table.hit, sw_SwitchIngress_acquire_lock_forward_to_server_table.action_run, sw_SwitchIngress_acquire_lock_forward_to_server_table.hit, sw_SwitchIngress_acquire_lock_notify_tail_client_table.action_run, sw_SwitchIngress_acquire_lock_notify_tail_client_table.hit, sw_SwitchIngress_acquire_lock_set_tag_table.action_run, sw_SwitchIngress_acquire_lock_set_tag_table.hit, sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action_run, sw_SwitchIngress_acquire_lock_switch_direct_grant_table.hit, sw_SwitchIngress_acquire_lock_update_client_id_array_table.action_run, sw_SwitchIngress_acquire_lock_update_client_id_array_table.hit, sw_SwitchIngress_acquire_lock_update_ip_array_table.action_run, sw_SwitchIngress_acquire_lock_update_ip_array_table.hit, sw_SwitchIngress_acquire_lock_update_mode_array_table.action_run, sw_SwitchIngress_acquire_lock_update_mode_array_table.hit, sw_SwitchIngress_acquire_lock_update_tail_table.action_run, sw_SwitchIngress_acquire_lock_update_tail_table.hit, sw_SwitchIngress_acquire_lock_update_tid_array_table.action_run, sw_SwitchIngress_acquire_lock_update_tid_array_table.hit, sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action_run, sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.hit, sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action_run, sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.hit, sw_SwitchIngress_check_lock_exist_table.SwitchIngress_check_lock_exist_action.index_1, sw_SwitchIngress_check_lock_exist_table.action_run, sw_SwitchIngress_check_lock_exist_table.hit, sw_SwitchIngress_decode_decode_table.action_run, sw_SwitchIngress_decode_decode_table.hit, sw_SwitchIngress_decode_get_left_bound_table.action_run, sw_SwitchIngress_decode_get_left_bound_table.hit, sw_SwitchIngress_decode_get_right_bound_table.action_run, sw_SwitchIngress_decode_get_right_bound_table.hit, sw_SwitchIngress_decode_get_size_of_queue_table.action_run, sw_SwitchIngress_decode_get_size_of_queue_table.hit, sw_SwitchIngress_fix_src_port_table.action_run, sw_SwitchIngress_fix_src_port_table.hit, sw_SwitchIngress_forward_to_server_table.action_run, sw_SwitchIngress_forward_to_server_table.hit, sw_SwitchIngress_i2e_clone_table.action_run, sw_SwitchIngress_i2e_clone_table.hit, sw_SwitchIngress_ipv4_route_table.action_run, sw_SwitchIngress_ipv4_route_table.hit, sw_SwitchIngress_ipv4_route_table_2.action_run, sw_SwitchIngress_ipv4_route_table_2.hit, sw_SwitchIngress_release_lock_drop_packet_table.action_run, sw_SwitchIngress_release_lock_drop_packet_table.hit, sw_SwitchIngress_release_lock_fix_src_port_table.action_run, sw_SwitchIngress_release_lock_fix_src_port_table.hit, sw_SwitchIngress_release_lock_forward_to_server_table.action_run, sw_SwitchIngress_release_lock_forward_to_server_table.hit, sw_SwitchIngress_release_lock_get_client_id_table.action_run, sw_SwitchIngress_release_lock_get_client_id_table.hit, sw_SwitchIngress_release_lock_get_ip_table.action_run, sw_SwitchIngress_release_lock_get_ip_table.hit, sw_SwitchIngress_release_lock_get_mode_table.action_run, sw_SwitchIngress_release_lock_get_mode_table.hit, sw_SwitchIngress_release_lock_get_recirc_info_table.action_run, sw_SwitchIngress_release_lock_get_recirc_info_table.hit, sw_SwitchIngress_release_lock_get_tail_table.action_run, sw_SwitchIngress_release_lock_get_tail_table.hit, sw_SwitchIngress_release_lock_get_tid_table.action_run, sw_SwitchIngress_release_lock_get_tid_table.hit, sw_SwitchIngress_release_lock_get_timestamp_hi_table.action_run, sw_SwitchIngress_release_lock_get_timestamp_hi_table.hit, sw_SwitchIngress_release_lock_get_timestamp_lo_table.action_run, sw_SwitchIngress_release_lock_get_timestamp_lo_table.hit, sw_SwitchIngress_release_lock_i2e_mirror_table.action_run, sw_SwitchIngress_release_lock_i2e_mirror_table.hit, sw_SwitchIngress_release_lock_inc_empty_slots_table.action_run, sw_SwitchIngress_release_lock_inc_empty_slots_table.hit, sw_SwitchIngress_release_lock_metahead_plus_1_table.action_run, sw_SwitchIngress_release_lock_metahead_plus_1_table.hit, sw_SwitchIngress_release_lock_metahead_plus_2_table.action_run, sw_SwitchIngress_release_lock_metahead_plus_2_table.hit, sw_SwitchIngress_release_lock_notify_head_client_table.action_run, sw_SwitchIngress_release_lock_notify_head_client_table.hit, sw_SwitchIngress_release_lock_set_tag_table.action_run, sw_SwitchIngress_release_lock_set_tag_table.hit, sw_SwitchIngress_release_lock_update_head_table.action_run, sw_SwitchIngress_release_lock_update_head_table.hit, sw_SwitchIngress_release_lock_update_lock_table.action_run, sw_SwitchIngress_release_lock_update_lock_table.hit, sw_SwitchIngress_set_tag_table.action_run, sw_SwitchIngress_set_tag_table.hit, sw___ra_ret_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_ret_SwitchIngress_acquire_lock_push_back_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_client_id_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_ip_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_mode_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_tid_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw___ra_ret_SwitchIngress_decode_get_left_bound_alu, sw___ra_ret_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_ret_SwitchIngress_decode_get_right_bound_alu, sw___ra_ret_SwitchIngress_release_lock_get_client_id_alu, sw___ra_ret_SwitchIngress_release_lock_get_ip_alu, sw___ra_ret_SwitchIngress_release_lock_get_mode_alu, sw___ra_ret_SwitchIngress_release_lock_get_tail_alu, sw___ra_ret_SwitchIngress_release_lock_get_tid_alu, sw___ra_ret_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_ret_SwitchIngress_release_lock_update_head_alu, sw___ra_ret_SwitchIngress_release_lock_update_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_val_SwitchIngress_acquire_lock_push_back_alu, sw___ra_val_SwitchIngress_acquire_lock_update_client_id_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_ip_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_mode_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tid_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw___ra_val_SwitchIngress_decode_get_left_bound_alu, sw___ra_val_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_val_SwitchIngress_decode_get_right_bound_alu, sw___ra_val_SwitchIngress_release_lock_get_client_id_alu, sw___ra_val_SwitchIngress_release_lock_get_ip_alu, sw___ra_val_SwitchIngress_release_lock_get_mode_alu, sw___ra_val_SwitchIngress_release_lock_get_tail_alu, sw___ra_val_SwitchIngress_release_lock_get_tid_alu, sw___ra_val_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_val_SwitchIngress_release_lock_update_head_alu, sw___ra_val_SwitchIngress_release_lock_update_lock_alu, sw_client_id_array_register, sw_client_id_array_register__last0_old_value, sw_client_id_array_register__last0_value, sw_client_id_array_register__last_index, sw_client_id_array_register__last_old_value, sw_client_id_array_register__last_value, sw_client_id_array_register__last_write_site, sw_client_id_array_register__next_write_site, sw_client_id_array_register__wrote_any, sw_client_id_array_register__wrote_index0, sw_hdr.ethernet.dstAddr, sw_hdr.ethernet.srcAddr, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.srcAddr, sw_hdr.nlk_hdr.empty_slots, sw_hdr.nlk_hdr.head, sw_hdr.nlk_hdr.lock, sw_hdr.nlk_hdr.mode, sw_hdr.nlk_hdr.op, sw_hdr.nlk_hdr.tail, sw_hdr.udp.srcPort, sw_head_register, sw_head_register__last0_old_value, sw_head_register__last0_value, sw_head_register__last_index, sw_head_register__last_old_value, sw_head_register__last_value, sw_head_register__last_write_site, sw_head_register__next_write_site, sw_head_register__wrote_any, sw_head_register__wrote_index0, sw_ig_intr_dprsr_md.drop_ctl, sw_ig_intr_dprsr_md.mirror_type, sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.client_id, sw_ig_md.clone_md, sw_ig_md.dequeued_mode, sw_ig_md.empty_slots, sw_ig_md.empty_slots_before_pop, sw_ig_md.failure_status, sw_ig_md.head, sw_ig_md.ing_mir_ses, sw_ig_md.ip_address, sw_ig_md.left, sw_ig_md.length_in_server, sw_ig_md.lock_exist, sw_ig_md.lock_id, sw_ig_md.locked, sw_ig_md.mode, sw_ig_md.pkt_type, sw_ig_md.queue_size_op, sw_ig_md.recirc_flag, sw_ig_md.right, sw_ig_md.routed, sw_ig_md.size_of_queue, sw_ig_md.tail, sw_ig_md.tid, sw_ig_md.timestamp_hi, sw_ig_md.timestamp_lo, sw_ig_md.ts_hi, sw_ig_md.ts_lo, sw_ip_array_register, sw_ip_array_register__last0_old_value, sw_ip_array_register__last0_value, sw_ip_array_register__last_index, sw_ip_array_register__last_old_value, sw_ip_array_register__last_value, sw_ip_array_register__last_write_site, sw_ip_array_register__next_write_site, sw_ip_array_register__wrote_any, sw_ip_array_register__wrote_index0, sw_left_bound_register, sw_left_bound_register__last0_old_value, sw_left_bound_register__last0_value, sw_left_bound_register__last_index, sw_left_bound_register__last_old_value, sw_left_bound_register__last_value, sw_left_bound_register__last_write_site, sw_left_bound_register__next_write_site, sw_left_bound_register__wrote_any, sw_left_bound_register__wrote_index0, sw_mode_array_register, sw_mode_array_register__last0_old_value, sw_mode_array_register__last0_value, sw_mode_array_register__last_index, sw_mode_array_register__last_old_value, sw_mode_array_register__last_value, sw_mode_array_register__last_write_site, sw_mode_array_register__next_write_site, sw_mode_array_register__wrote_any, sw_mode_array_register__wrote_index0, sw_p4b_clone_i2e, sw_p4b_recirculate, sw_queue_size_op_register, sw_queue_size_op_register__last0_old_value, sw_queue_size_op_register__last0_value, sw_queue_size_op_register__last_index, sw_queue_size_op_register__last_old_value, sw_queue_size_op_register__last_value, sw_queue_size_op_register__last_write_site, sw_queue_size_op_register__next_write_site, sw_queue_size_op_register__wrote_any, sw_queue_size_op_register__wrote_index0, sw_right_bound_register, sw_right_bound_register__last0_old_value, sw_right_bound_register__last0_value, sw_right_bound_register__last_index, sw_right_bound_register__last_old_value, sw_right_bound_register__last_value, sw_right_bound_register__last_write_site, sw_right_bound_register__next_write_site, sw_right_bound_register__wrote_any, sw_right_bound_register__wrote_index0, sw_shared_and_exclusive_count_register, sw_shared_and_exclusive_count_register__last0_old_value, sw_shared_and_exclusive_count_register__last0_value, sw_shared_and_exclusive_count_register__last_index, sw_shared_and_exclusive_count_register__last_old_value, sw_shared_and_exclusive_count_register__last_value, sw_shared_and_exclusive_count_register__last_write_site, sw_shared_and_exclusive_count_register__next_write_site, sw_shared_and_exclusive_count_register__wrote_any, sw_shared_and_exclusive_count_register__wrote_index0, sw_slots_two_sides_register, sw_slots_two_sides_register__last0_old_value, sw_slots_two_sides_register__last0_value, sw_slots_two_sides_register__last_index, sw_slots_two_sides_register__last_old_value, sw_slots_two_sides_register__last_value, sw_slots_two_sides_register__last_write_site, sw_slots_two_sides_register__next_write_site, sw_slots_two_sides_register__wrote_any, sw_slots_two_sides_register__wrote_index0, sw_tail_register, sw_tail_register__last0_old_value, sw_tail_register__last0_value, sw_tail_register__last_index, sw_tail_register__last_old_value, sw_tail_register__last_value, sw_tail_register__last_write_site, sw_tail_register__next_write_site, sw_tail_register__wrote_any, sw_tail_register__wrote_index0, sw_tid_array_register, sw_tid_array_register__last0_old_value, sw_tid_array_register__last0_value, sw_tid_array_register__last_index, sw_tid_array_register__last_old_value, sw_tid_array_register__last_value, sw_tid_array_register__last_write_site, sw_tid_array_register__next_write_site, sw_tid_array_register__wrote_any, sw_tid_array_register__wrote_index0, sw_timestamp_hi_array_register, sw_timestamp_hi_array_register__last0_old_value, sw_timestamp_hi_array_register__last0_value, sw_timestamp_hi_array_register__last_index, sw_timestamp_hi_array_register__last_old_value, sw_timestamp_hi_array_register__last_value, sw_timestamp_hi_array_register__last_write_site, sw_timestamp_hi_array_register__next_write_site, sw_timestamp_hi_array_register__wrote_any, sw_timestamp_hi_array_register__wrote_index0, sw_timestamp_lo_array_register, sw_timestamp_lo_array_register__last0_old_value, sw_timestamp_lo_array_register__last0_value, sw_timestamp_lo_array_register__last_index, sw_timestamp_lo_array_register__last_old_value, sw_timestamp_lo_array_register__last_value, sw_timestamp_lo_array_register__last_write_site, sw_timestamp_lo_array_register__next_write_site, sw_timestamp_lo_array_register__wrote_any, sw_timestamp_lo_array_register__wrote_index0;
{
    if((sw_isValid[sw_hdr.nlk_hdr]) && ((sw_hdr.udp.dstPort == 4321bv16))){
        if(sw_isValid[sw_hdr.recirculate_hdr]){
            if(bult.bv8(sw_hdr.recirculate_hdr.dequeued_mode, 2bv8)){
                sw_p4b_recirculate := true;
                call sw_SwitchIngress_i2e_clone_table.apply();
            }
            else{
                call sw_SwitchIngress_ipv4_route_table_2.apply();
            }
        }
        else{
            sw_p4b_recirculate := true;
        }
    }
    else{
        if((sw_isValid[sw_hdr.nlk_hdr]) && ((((sw_hdr.nlk_hdr.op == 0bv8)) || ((sw_hdr.nlk_hdr.op == 2bv8))) || ((sw_hdr.nlk_hdr.op == 1bv8)))){
            call sw_SwitchIngress_check_lock_exist_table.apply();
            if((sw_ig_md.lock_exist == 1bv1)){
                call sw_SwitchIngress_decode_get_left_bound_table.apply();
                call sw_SwitchIngress_decode_get_right_bound_table.apply();
                call sw_SwitchIngress_decode_get_size_of_queue_table.apply();
                call sw_SwitchIngress_decode_decode_table.apply();
                if(((sw_hdr.nlk_hdr.op == 0bv8)) || ((sw_hdr.nlk_hdr.op == 2bv8))){
                    call sw_SwitchIngress_acquire_lock_dec_empty_slots_table.apply();
                    if(((sw_ig_md.length_in_server != 0bv32)) && (((sw_hdr.nlk_hdr.op == 0bv8)) || ((sw_hdr.nlk_hdr.op == 2bv8)))){
                        call sw_SwitchIngress_acquire_lock_fix_src_port_table.apply();
                        call sw_SwitchIngress_acquire_lock_set_tag_table.apply();
                        call sw_SwitchIngress_acquire_lock_forward_to_server_table.apply();
                    }
                    else{
                        call sw_SwitchIngress_acquire_lock_acquire_lock_table.apply();
                        call sw_SwitchIngress_acquire_lock_update_tail_table.apply();
                        call sw_SwitchIngress_acquire_lock_update_ip_array_table.apply();
                        call sw_SwitchIngress_acquire_lock_update_mode_array_table.apply();
                        call sw_SwitchIngress_acquire_lock_update_client_id_array_table.apply();
                        call sw_SwitchIngress_acquire_lock_update_tid_array_table.apply();
                        call sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.apply();
                        call sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.apply();
                        if((sw_ig_md.locked == 0bv32)){
                            call sw_SwitchIngress_acquire_lock_notify_tail_client_table.apply();
                            if((sw_hdr.nlk_hdr.op == 0bv8)){
                                call sw_SwitchIngress_acquire_lock_switch_direct_grant_table.apply();
                            }
                        }
                        else{
                            call sw_SwitchIngress_acquire_lock_drop_packet_table.apply();
                        }
                    }
                }
                else{
                    if((sw_hdr.nlk_hdr.op == 1bv8)){
                        if((sw_hdr.nlk_hdr.recirc_flag == 0bv8)){
                            call sw_SwitchIngress_release_lock_inc_empty_slots_table.apply();
                            call sw_SwitchIngress_release_lock_update_head_table.apply();
                            call sw_SwitchIngress_release_lock_update_lock_table.apply();
                        }
                        else{
                            call sw_SwitchIngress_release_lock_get_recirc_info_table.apply();
                        }
                        if(((sw_ig_md.empty_slots_before_pop == sw_ig_md.size_of_queue)) && ((sw_hdr.nlk_hdr.recirc_flag == 0bv8))){
                            call sw_SwitchIngress_release_lock_fix_src_port_table.apply();
                            call sw_SwitchIngress_release_lock_set_tag_table.apply();
                            call sw_SwitchIngress_release_lock_forward_to_server_table.apply();
                        }
                        else{
                            if((sw_hdr.nlk_hdr.recirc_flag == 0bv8)){
                                call sw_SwitchIngress_release_lock_get_tail_table.apply();
                            }
                            call sw_SwitchIngress_release_lock_get_ip_table.apply();
                            call sw_SwitchIngress_release_lock_get_mode_table.apply();
                            call sw_SwitchIngress_release_lock_get_client_id_table.apply();
                            call sw_SwitchIngress_release_lock_get_tid_table.apply();
                            call sw_SwitchIngress_release_lock_notify_head_client_table.apply();
                            call sw_SwitchIngress_release_lock_get_timestamp_hi_table.apply();
                            call sw_SwitchIngress_release_lock_get_timestamp_lo_table.apply();
                            if((((sw_ig_md.recirc_flag == 1bv8)) && (((sw_ig_md.dequeued_mode == 1bv8)) || ((sw_ig_md.mode == 1bv8)))) || (((sw_ig_md.recirc_flag == 2bv8)) && ((sw_ig_md.mode == 0bv8)))){
                                call sw_SwitchIngress_release_lock_i2e_mirror_table.apply();
                            }
                            if(((((sw_ig_md.recirc_flag == 1bv8)) && (((sw_ig_md.dequeued_mode == 1bv8)) || ((sw_ig_md.mode == 1bv8)))) || (((sw_ig_md.recirc_flag == 2bv8)) && ((sw_ig_md.mode == 0bv8)))) || ((sw_ig_md.recirc_flag == 0bv8))){
                                if((sw_ig_md.head != sw_ig_md.tail)){
                                    if((sw_ig_md.recirc_flag == 0bv8)){
                                        sw_p4b_recirculate := true;
                                    }
                                    else{
                                        if((((sw_ig_md.recirc_flag == 1bv8)) && ((sw_ig_md.mode == 0bv8))) || ((sw_ig_md.recirc_flag == 2bv8))){
                                            sw_p4b_recirculate := true;
                                        }
                                    }
                                }
                                if((sw_ig_md.head == sw_ig_md.right)){
                                    call sw_SwitchIngress_release_lock_metahead_plus_1_table.apply();
                                }
                                else{
                                    call sw_SwitchIngress_release_lock_metahead_plus_2_table.apply();
                                }
                                if((sw_ig_md.do_resubmit == 1bv1)){
                                    sw_p4b_recirculate := true;
                                }
                            }
                            if((sw_ig_md.do_resubmit == 0bv1)){
                                call sw_SwitchIngress_release_lock_drop_packet_table.apply();
                            }
                        }
                    }
                }
            }
            else{
                call sw_SwitchIngress_fix_src_port_table.apply();
                call sw_SwitchIngress_set_tag_table.apply();
                call sw_SwitchIngress_forward_to_server_table.apply();
            }
        }
    }
    if(((sw_isValid[sw_hdr.nlk_hdr]) && ((sw_ig_md.routed == 0bv1))) && ((sw_ig_md.recirced == 0bv2))){
        call sw_SwitchIngress_ipv4_route_table.apply();
    }
}

// sw_Control sw_SwitchIngressDeparser
procedure {:inline 1} sw_SwitchIngressDeparser()
	modifies sw_isValid, sw_p4b_clone_i2e, sw_tmp;
{
    call sw_setValid(sw_tmp);
    havoc sw_tmp;
    sw_p4b_clone_i2e := sw_p4b_clone_i2e || (sw_ig_intr_dprsr_md.mirror_type == 1bv3);
    call sw_pkt.emit(sw_hdr);
}

// sw_Parser sw_SwitchIngressParser
procedure {:inline 1} sw_SwitchIngressParser()
	modifies sw_drop, sw_isValid;
{
    goto sw_State$SwitchIngressParser$start;

        sw_State$SwitchIngressParser$start:
    call sw_setInvalid(sw_ig_intr_md);
    goto sw_State$SwitchIngressParser$TofinoIngressParser_start;

        sw_State$SwitchIngressParser$TofinoIngressParser_start:
    call sw_packet_in.extract(sw_ig_intr_md);
    goto sw_State$SwitchIngressParser$TofinoIngressParser_start$TofinoIngressParser_parse_resubmit_2, sw_State$SwitchIngressParser$TofinoIngressParser_start$TofinoIngressParser_parse_port_metadata_1, sw_State$SwitchIngressParser$TofinoIngressParser_start$DEFAULT;
    
sw_State$SwitchIngressParser$TofinoIngressParser_start$TofinoIngressParser_parse_resubmit_2:
    assume (sw_ig_intr_md.resubmit_flag == 1bv1);
    goto sw_State$SwitchIngressParser$TofinoIngressParser_parse_resubmit;
    
sw_State$SwitchIngressParser$TofinoIngressParser_start$TofinoIngressParser_parse_port_metadata_1:
    assume (sw_ig_intr_md.resubmit_flag == 0bv1);
    goto sw_State$SwitchIngressParser$TofinoIngressParser_parse_port_metadata;

    sw_State$SwitchIngressParser$TofinoIngressParser_start$DEFAULT:
    assume(!(sw_ig_intr_md.resubmit_flag == 1bv1)&&!(sw_ig_intr_md.resubmit_flag == 0bv1));
goto sw_State$reject;

        sw_State$SwitchIngressParser$TofinoIngressParser_parse_resubmit:
    goto sw_State$reject;

        sw_State$SwitchIngressParser$TofinoIngressParser_parse_port_metadata:
    call sw_pkt.advance(64bv32);
    goto sw_State$SwitchIngressParser$start_0;

        sw_State$SwitchIngressParser$start_0:
    call sw_packet_in.extract(sw_hdr.ethernet);
    goto sw_State$SwitchIngressParser$start_0$parse_ipv4_2, sw_State$SwitchIngressParser$start_0$DEFAULT;
    
sw_State$SwitchIngressParser$start_0$parse_ipv4_2:
    assume (sw_hdr.ethernet.etherType == 2048bv16);
    goto sw_State$SwitchIngressParser$parse_ipv4;

    sw_State$SwitchIngressParser$start_0$DEFAULT:
    assume(!(sw_hdr.ethernet.etherType == 2048bv16));
    goto sw_State$accept;

        sw_State$SwitchIngressParser$parse_ipv4:
    call sw_packet_in.extract(sw_hdr.ipv4);
    goto sw_State$SwitchIngressParser$parse_ipv4$parse_tcp_3, sw_State$SwitchIngressParser$parse_ipv4$parse_udp_2, sw_State$SwitchIngressParser$parse_ipv4$DEFAULT;
    
sw_State$SwitchIngressParser$parse_ipv4$parse_tcp_3:
    assume (sw_hdr.ipv4.protocol == 6bv8);
    goto sw_State$SwitchIngressParser$parse_tcp;
    
sw_State$SwitchIngressParser$parse_ipv4$parse_udp_2:
    assume (sw_hdr.ipv4.protocol == 17bv8);
    goto sw_State$SwitchIngressParser$parse_udp;

    sw_State$SwitchIngressParser$parse_ipv4$DEFAULT:
    assume(!(sw_hdr.ipv4.protocol == 6bv8)&&!(sw_hdr.ipv4.protocol == 17bv8));
    goto sw_State$accept;

        sw_State$SwitchIngressParser$parse_tcp:
    call sw_packet_in.extract(sw_hdr.tcp);
    goto sw_State$accept;

        sw_State$SwitchIngressParser$parse_udp:
    call sw_packet_in.extract(sw_hdr.udp);
    goto sw_State$SwitchIngressParser$parse_udp$parse_probe_hdr_6, sw_State$SwitchIngressParser$parse_udp$parse_nlk_hdr_5, sw_State$SwitchIngressParser$parse_udp$parse_nlk_hdr_4, sw_State$SwitchIngressParser$parse_udp$parse_adm_hdr_3, sw_State$SwitchIngressParser$parse_udp$parse_nlk_hdr_2, sw_State$SwitchIngressParser$parse_udp$DEFAULT;
    
sw_State$SwitchIngressParser$parse_udp$parse_probe_hdr_6:
    assume (sw_hdr.udp.dstPort == 9998bv16);
    goto sw_State$SwitchIngressParser$parse_probe_hdr;
    
sw_State$SwitchIngressParser$parse_udp$parse_nlk_hdr_5:
    assume (sw_hdr.udp.dstPort == 8888bv16);
    goto sw_State$SwitchIngressParser$parse_nlk_hdr;
    
sw_State$SwitchIngressParser$parse_udp$parse_nlk_hdr_4:
    assume (sw_hdr.udp.dstPort == 8889bv16);
    goto sw_State$SwitchIngressParser$parse_nlk_hdr;
    
sw_State$SwitchIngressParser$parse_udp$parse_adm_hdr_3:
    assume (sw_hdr.udp.dstPort == 7777bv16);
    goto sw_State$SwitchIngressParser$parse_adm_hdr;
    
sw_State$SwitchIngressParser$parse_udp$parse_nlk_hdr_2:
    assume (sw_hdr.udp.dstPort == 4321bv16);
    goto sw_State$SwitchIngressParser$parse_nlk_hdr;

    sw_State$SwitchIngressParser$parse_udp$DEFAULT:
    assume(!(sw_hdr.udp.dstPort == 9998bv16)&&!(sw_hdr.udp.dstPort == 8888bv16)&&!(sw_hdr.udp.dstPort == 8889bv16)&&!(sw_hdr.udp.dstPort == 7777bv16)&&!(sw_hdr.udp.dstPort == 4321bv16));
    goto sw_State$accept;

        sw_State$SwitchIngressParser$parse_nlk_hdr:
    call sw_packet_in.extract(sw_hdr.nlk_hdr);
    goto sw_State$SwitchIngressParser$parse_nlk_hdr$parse_recirculate_hdr_3, sw_State$SwitchIngressParser$parse_nlk_hdr$parse_recirculate_hdr_2, sw_State$SwitchIngressParser$parse_nlk_hdr$DEFAULT;
    
sw_State$SwitchIngressParser$parse_nlk_hdr$parse_recirculate_hdr_3:
    assume (sw_hdr.nlk_hdr.recirc_flag == 1bv8);
    goto sw_State$SwitchIngressParser$parse_recirculate_hdr;
    
sw_State$SwitchIngressParser$parse_nlk_hdr$parse_recirculate_hdr_2:
    assume (sw_hdr.nlk_hdr.recirc_flag == 2bv8);
    goto sw_State$SwitchIngressParser$parse_recirculate_hdr;

    sw_State$SwitchIngressParser$parse_nlk_hdr$DEFAULT:
    assume(!(sw_hdr.nlk_hdr.recirc_flag == 1bv8)&&!(sw_hdr.nlk_hdr.recirc_flag == 2bv8));
    goto sw_State$accept;

        sw_State$SwitchIngressParser$parse_recirculate_hdr:
    call sw_packet_in.extract(sw_hdr.recirculate_hdr);
    goto sw_State$accept;

        sw_State$SwitchIngressParser$parse_adm_hdr:
    call sw_packet_in.extract(sw_hdr.adm_hdr);
    goto sw_State$accept;

        sw_State$SwitchIngressParser$parse_probe_hdr:
    call sw_packet_in.extract(sw_hdr.probe_hdr);
    goto sw_State$accept;

    sw_State$accept:
    call sw_accept();
    goto sw_Exit;

    sw_State$reject:
    call sw_reject();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_acquire_lock_acquire_exclusive_lock_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_acquire_exclusive_lock_action()
	modifies sw___ra_ret_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw_ig_md.locked, sw_shared_and_exclusive_count_register, sw_shared_and_exclusive_count_register__last0_old_value, sw_shared_and_exclusive_count_register__last0_value, sw_shared_and_exclusive_count_register__last_index, sw_shared_and_exclusive_count_register__last_old_value, sw_shared_and_exclusive_count_register__last_value, sw_shared_and_exclusive_count_register__last_write_site, sw_shared_and_exclusive_count_register__next_write_site, sw_shared_and_exclusive_count_register__wrote_any, sw_shared_and_exclusive_count_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu := sw_shared_and_exclusive_count_register.read(sw_shared_and_exclusive_count_register, sw_ig_md.lock_id);
    call sw___ra_val_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu := sw_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu.apply(sw___ra_val_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu);
    sw_shared_and_exclusive_count_register__next_write_site := 2;
    call sw_shared_and_exclusive_count_register.write(sw_ig_md.lock_id, sw___ra_val_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu);
    sw_ig_md.locked := sw___ra_ret_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu;
}

// sw_RegisterAction sw_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu.apply
procedure {:inline 1} sw_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu.apply(sw_value_in:sw_pair, sw_result_in:bv32) returns (sw_value_out:sw_pair, sw_result_out:bv32)
{
    var sw_value:sw_pair;
    var sw_result:bv32;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    if((bugt.bv32(sw_value[64:32], 0bv32)) || (bugt.bv32(sw_value[32:0], 0bv32))){
        sw_value := add.bv32(sw_value[64:32], 1bv32)++sw_value[32:0];
        sw_result := 1bv32;
    }
    else{
        sw_value := add.bv32(sw_value[64:32], 1bv32)++sw_value[32:0];
        sw_result := 0bv32;
    }
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Table sw_SwitchIngress_acquire_lock_acquire_lock_table
procedure {:inline 1} sw_SwitchIngress_acquire_lock_acquire_lock_table.apply()
	modifies sw_SwitchIngress_acquire_lock_acquire_lock_table.action_run, sw_SwitchIngress_acquire_lock_acquire_lock_table.hit, sw___ra_ret_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw_hdr.nlk_hdr.mode, sw_ig_md.locked, sw_shared_and_exclusive_count_register, sw_shared_and_exclusive_count_register__last0_old_value, sw_shared_and_exclusive_count_register__last0_value, sw_shared_and_exclusive_count_register__last_index, sw_shared_and_exclusive_count_register__last_old_value, sw_shared_and_exclusive_count_register__last_value, sw_shared_and_exclusive_count_register__last_write_site, sw_shared_and_exclusive_count_register__next_write_site, sw_shared_and_exclusive_count_register__wrote_any, sw_shared_and_exclusive_count_register__wrote_index0;
{
    sw_hdr.nlk_hdr.mode := sw_hdr.nlk_hdr.mode;
    sw_SwitchIngress_acquire_lock_acquire_lock_table.hit := false;
    if(sw_hdr.nlk_hdr.mode == 0bv8){
        sw_SwitchIngress_acquire_lock_acquire_lock_table.hit := true;
        sw_SwitchIngress_acquire_lock_acquire_lock_table.action_run := sw_SwitchIngress_acquire_lock_acquire_lock_table.action.SwitchIngress_acquire_lock_acquire_shared_lock_action;
        call sw_SwitchIngress_acquire_lock_acquire_shared_lock_action();
        goto sw_Exit;
    }
    else if(sw_hdr.nlk_hdr.mode == 1bv8){
        sw_SwitchIngress_acquire_lock_acquire_lock_table.hit := true;
        sw_SwitchIngress_acquire_lock_acquire_lock_table.action_run := sw_SwitchIngress_acquire_lock_acquire_lock_table.action.SwitchIngress_acquire_lock_acquire_exclusive_lock_action;
        call sw_SwitchIngress_acquire_lock_acquire_exclusive_lock_action();
        goto sw_Exit;
    }
    if(!sw_SwitchIngress_acquire_lock_acquire_lock_table.hit){
        sw_SwitchIngress_acquire_lock_acquire_lock_table.action_run := sw_SwitchIngress_acquire_lock_acquire_lock_table.action.NoAction_4;
        call sw_NoAction_4();
        goto sw_Exit;
    }

    sw_Exit:
}

// sw_Action sw_SwitchIngress_acquire_lock_acquire_shared_lock_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_acquire_shared_lock_action()
	modifies sw___ra_ret_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw_ig_md.locked, sw_shared_and_exclusive_count_register, sw_shared_and_exclusive_count_register__last0_old_value, sw_shared_and_exclusive_count_register__last0_value, sw_shared_and_exclusive_count_register__last_index, sw_shared_and_exclusive_count_register__last_old_value, sw_shared_and_exclusive_count_register__last_value, sw_shared_and_exclusive_count_register__last_write_site, sw_shared_and_exclusive_count_register__next_write_site, sw_shared_and_exclusive_count_register__wrote_any, sw_shared_and_exclusive_count_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_acquire_lock_acquire_shared_lock_alu := sw_shared_and_exclusive_count_register.read(sw_shared_and_exclusive_count_register, sw_ig_md.lock_id);
    call sw___ra_val_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_acquire_shared_lock_alu := sw_SwitchIngress_acquire_lock_acquire_shared_lock_alu.apply(sw___ra_val_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_acquire_shared_lock_alu);
    sw_shared_and_exclusive_count_register__next_write_site := 1;
    call sw_shared_and_exclusive_count_register.write(sw_ig_md.lock_id, sw___ra_val_SwitchIngress_acquire_lock_acquire_shared_lock_alu);
    sw_ig_md.locked := sw___ra_ret_SwitchIngress_acquire_lock_acquire_shared_lock_alu;
}

// sw_RegisterAction sw_SwitchIngress_acquire_lock_acquire_shared_lock_alu.apply
procedure {:inline 1} sw_SwitchIngress_acquire_lock_acquire_shared_lock_alu.apply(sw_value_in:sw_pair, sw_result_in:bv32) returns (sw_value_out:sw_pair, sw_result_out:bv32)
{
    var sw_value:sw_pair;
    var sw_result:bv32;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    if(bugt.bv32(sw_value[64:32], 0bv32)){
        sw_value := sw_value[64:32]++add.bv32(sw_value[32:0], 1bv32);
        sw_result := sw_value[32:0];
    }
    else{
        sw_value := sw_value[64:32]++add.bv32(sw_value[32:0], 1bv32);
        sw_result := 0bv32;
    }
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Action sw_SwitchIngress_acquire_lock_dec_empty_slots_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_dec_empty_slots_action()
	modifies sw___ra_ret_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_val_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw_ig_md.length_in_server, sw_slots_two_sides_register, sw_slots_two_sides_register__last0_old_value, sw_slots_two_sides_register__last0_value, sw_slots_two_sides_register__last_index, sw_slots_two_sides_register__last_old_value, sw_slots_two_sides_register__last_value, sw_slots_two_sides_register__last_write_site, sw_slots_two_sides_register__next_write_site, sw_slots_two_sides_register__wrote_any, sw_slots_two_sides_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_acquire_lock_dec_empty_slots_alu := sw_slots_two_sides_register.read(sw_slots_two_sides_register, sw_ig_md.lock_id);
    call sw___ra_val_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_ret_SwitchIngress_acquire_lock_dec_empty_slots_alu := sw_SwitchIngress_acquire_lock_dec_empty_slots_alu.apply(sw___ra_val_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_ret_SwitchIngress_acquire_lock_dec_empty_slots_alu);
    sw_slots_two_sides_register__next_write_site := 1;
    call sw_slots_two_sides_register.write(sw_ig_md.lock_id, sw___ra_val_SwitchIngress_acquire_lock_dec_empty_slots_alu);
    sw_ig_md.length_in_server := sw___ra_ret_SwitchIngress_acquire_lock_dec_empty_slots_alu;
}

// sw_RegisterAction sw_SwitchIngress_acquire_lock_dec_empty_slots_alu.apply
procedure {:inline 1} sw_SwitchIngress_acquire_lock_dec_empty_slots_alu.apply(sw_value_in:sw_pair, sw_result_in:bv32) returns (sw_value_out:sw_pair, sw_result_out:bv32)
{
    var sw_value:sw_pair;
    var sw_result:bv32;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    if((bugt.bv32(sw_value[64:32], 0bv32)) && (bule.bv32(add.bv32(sw_value[32:0], sw_ig_md.queue_size_op), 0bv32))){
        sw_value := add.bv32(sw_value[64:32], 4294967295bv32)++sw_value[32:0];
    }
    else{
        sw_value := sw_value[64:32]++add.bv32(sw_value[32:0], 1bv32);
    }
    sw_result := sw_value[32:0];
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Table sw_SwitchIngress_acquire_lock_dec_empty_slots_table
procedure {:inline 1} sw_SwitchIngress_acquire_lock_dec_empty_slots_table.apply()
	modifies sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action_run, sw_SwitchIngress_acquire_lock_dec_empty_slots_table.hit, sw___ra_ret_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_ret_SwitchIngress_acquire_lock_push_back_alu, sw___ra_val_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_val_SwitchIngress_acquire_lock_push_back_alu, sw_hdr.nlk_hdr.op, sw_ig_md.empty_slots, sw_ig_md.length_in_server, sw_slots_two_sides_register, sw_slots_two_sides_register__last0_old_value, sw_slots_two_sides_register__last0_value, sw_slots_two_sides_register__last_index, sw_slots_two_sides_register__last_old_value, sw_slots_two_sides_register__last_value, sw_slots_two_sides_register__last_write_site, sw_slots_two_sides_register__next_write_site, sw_slots_two_sides_register__wrote_any, sw_slots_two_sides_register__wrote_index0;
{
    sw_hdr.nlk_hdr.op := sw_hdr.nlk_hdr.op;
    sw_SwitchIngress_acquire_lock_dec_empty_slots_table.hit := false;
    if(sw_hdr.nlk_hdr.op == 0bv8){
        sw_SwitchIngress_acquire_lock_dec_empty_slots_table.hit := true;
        sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action_run := sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action.SwitchIngress_acquire_lock_dec_empty_slots_action;
        call sw_SwitchIngress_acquire_lock_dec_empty_slots_action();
        goto sw_Exit;
    }
    else if(sw_hdr.nlk_hdr.op == 2bv8){
        sw_SwitchIngress_acquire_lock_dec_empty_slots_table.hit := true;
        sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action_run := sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action.SwitchIngress_acquire_lock_push_back_action;
        call sw_SwitchIngress_acquire_lock_push_back_action();
        goto sw_Exit;
    }
    if(!sw_SwitchIngress_acquire_lock_dec_empty_slots_table.hit){
        sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action_run := sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action.NoAction_3;
        call sw_NoAction_3();
        goto sw_Exit;
    }

    sw_Exit:
}

// sw_Action sw_SwitchIngress_acquire_lock_drop
procedure {:inline 1} sw_SwitchIngress_acquire_lock_drop()
	modifies sw_ig_intr_dprsr_md.drop_ctl;
{
    sw_ig_intr_dprsr_md.drop_ctl := 1bv3;
}

// sw_Table sw_SwitchIngress_acquire_lock_drop_packet_table
procedure {:inline 1} sw_SwitchIngress_acquire_lock_drop_packet_table.apply()
	modifies sw_SwitchIngress_acquire_lock_drop_packet_table.action_run, sw_SwitchIngress_acquire_lock_drop_packet_table.hit, sw_ig_intr_dprsr_md.drop_ctl;
{
    sw_SwitchIngress_acquire_lock_drop_packet_table.hit := false;
    sw_SwitchIngress_acquire_lock_drop_packet_table.action_run := sw_SwitchIngress_acquire_lock_drop_packet_table.action.SwitchIngress_acquire_lock_drop;
    call sw_SwitchIngress_acquire_lock_drop();
    goto sw_Exit;

    sw_action_SwitchIngress_acquire_lock_drop:
    assume sw_SwitchIngress_acquire_lock_drop_packet_table.action_run == sw_SwitchIngress_acquire_lock_drop_packet_table.action.SwitchIngress_acquire_lock_drop;
    call sw_SwitchIngress_acquire_lock_drop();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_acquire_lock_fix_src_port_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_fix_src_port_action(sw_fix_port:bv16)
	modifies sw_hdr.ethernet.srcAddr, sw_hdr.udp.srcPort;
{
    sw_hdr.ethernet.srcAddr := 0bv16++sw_hdr.ipv4.srcAddr;
    sw_hdr.udp.srcPort := sw_fix_port;
}

// sw_Table sw_SwitchIngress_acquire_lock_fix_src_port_table
procedure {:inline 1} sw_SwitchIngress_acquire_lock_fix_src_port_table.apply()
	modifies sw_SwitchIngress_acquire_lock_fix_src_port_table.action_run, sw_SwitchIngress_acquire_lock_fix_src_port_table.hit, sw_hdr.ethernet.srcAddr, sw_hdr.nlk_hdr.lock, sw_hdr.udp.srcPort;
{
    sw_hdr.nlk_hdr.lock := sw_hdr.nlk_hdr.lock;
    sw_SwitchIngress_acquire_lock_fix_src_port_table.hit := false;
    sw_SwitchIngress_acquire_lock_fix_src_port_table.action_run := sw_SwitchIngress_acquire_lock_fix_src_port_table.action.NoAction_5;
    call sw_NoAction_5();
    goto sw_Exit;

    sw_action_SwitchIngress_acquire_lock_fix_src_port_action:
    assume sw_SwitchIngress_acquire_lock_fix_src_port_table.action_run == sw_SwitchIngress_acquire_lock_fix_src_port_table.action.SwitchIngress_acquire_lock_fix_src_port_action;
    call sw_SwitchIngress_acquire_lock_fix_src_port_action(sw_SwitchIngress_acquire_lock_fix_src_port_table.SwitchIngress_acquire_lock_fix_src_port_action.fix_port);
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_acquire_lock_forward_to_server_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_forward_to_server_action(sw_server_ip:sw_ipv4_addr_t)
	modifies sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.srcAddr, sw_hdr.nlk_hdr.empty_slots, sw_hdr.nlk_hdr.head, sw_hdr.nlk_hdr.tail;
{
    sw_hdr.ipv4.srcAddr := sw_server_ip;
    sw_hdr.ipv4.dstAddr := sw_server_ip;
    sw_hdr.nlk_hdr.empty_slots := sw_ig_md.empty_slots;
    sw_hdr.nlk_hdr.head := sw_ig_md.head;
    sw_hdr.nlk_hdr.tail := sw_ig_md.tail;
}

// sw_Table sw_SwitchIngress_acquire_lock_forward_to_server_table
procedure {:inline 1} sw_SwitchIngress_acquire_lock_forward_to_server_table.apply()
	modifies sw_SwitchIngress_acquire_lock_forward_to_server_table.action_run, sw_SwitchIngress_acquire_lock_forward_to_server_table.hit, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.srcAddr, sw_hdr.nlk_hdr.empty_slots, sw_hdr.nlk_hdr.head, sw_hdr.nlk_hdr.lock, sw_hdr.nlk_hdr.tail;
{
    sw_hdr.nlk_hdr.lock := sw_hdr.nlk_hdr.lock;
    sw_SwitchIngress_acquire_lock_forward_to_server_table.hit := false;
    sw_SwitchIngress_acquire_lock_forward_to_server_table.action_run := sw_SwitchIngress_acquire_lock_forward_to_server_table.action.NoAction_7;
    call sw_NoAction_7();
    goto sw_Exit;

    sw_action_SwitchIngress_acquire_lock_forward_to_server_action:
    assume sw_SwitchIngress_acquire_lock_forward_to_server_table.action_run == sw_SwitchIngress_acquire_lock_forward_to_server_table.action.SwitchIngress_acquire_lock_forward_to_server_action;
    call sw_SwitchIngress_acquire_lock_forward_to_server_action(sw_SwitchIngress_acquire_lock_forward_to_server_table.SwitchIngress_acquire_lock_forward_to_server_action.server_ip);
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_acquire_lock_notify_tail_client_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_notify_tail_client_action()
	modifies sw_hdr.ipv4.dstAddr, sw_hdr.nlk_hdr.empty_slots, sw_hdr.nlk_hdr.head, sw_hdr.nlk_hdr.tail;
{
    sw_hdr.ipv4.dstAddr := sw_hdr.ipv4.srcAddr;
    sw_hdr.nlk_hdr.empty_slots := sw_ig_md.length_in_server;
    sw_hdr.nlk_hdr.head := sw_ig_md.head;
    sw_hdr.nlk_hdr.tail := sw_ig_md.tail;
}

// sw_Table sw_SwitchIngress_acquire_lock_notify_tail_client_table
procedure {:inline 1} sw_SwitchIngress_acquire_lock_notify_tail_client_table.apply()
	modifies sw_SwitchIngress_acquire_lock_notify_tail_client_table.action_run, sw_SwitchIngress_acquire_lock_notify_tail_client_table.hit, sw_hdr.ipv4.dstAddr, sw_hdr.nlk_hdr.empty_slots, sw_hdr.nlk_hdr.head, sw_hdr.nlk_hdr.tail;
{
    sw_SwitchIngress_acquire_lock_notify_tail_client_table.hit := false;
    sw_SwitchIngress_acquire_lock_notify_tail_client_table.action_run := sw_SwitchIngress_acquire_lock_notify_tail_client_table.action.SwitchIngress_acquire_lock_notify_tail_client_action;
    call sw_SwitchIngress_acquire_lock_notify_tail_client_action();
    goto sw_Exit;

    sw_action_SwitchIngress_acquire_lock_notify_tail_client_action:
    assume sw_SwitchIngress_acquire_lock_notify_tail_client_table.action_run == sw_SwitchIngress_acquire_lock_notify_tail_client_table.action.SwitchIngress_acquire_lock_notify_tail_client_action;
    call sw_SwitchIngress_acquire_lock_notify_tail_client_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_acquire_lock_push_back_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_push_back_action()
	modifies sw___ra_ret_SwitchIngress_acquire_lock_push_back_alu, sw___ra_val_SwitchIngress_acquire_lock_push_back_alu, sw_ig_md.empty_slots, sw_slots_two_sides_register, sw_slots_two_sides_register__last0_old_value, sw_slots_two_sides_register__last0_value, sw_slots_two_sides_register__last_index, sw_slots_two_sides_register__last_old_value, sw_slots_two_sides_register__last_value, sw_slots_two_sides_register__last_write_site, sw_slots_two_sides_register__next_write_site, sw_slots_two_sides_register__wrote_any, sw_slots_two_sides_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_acquire_lock_push_back_alu := sw_slots_two_sides_register.read(sw_slots_two_sides_register, sw_ig_md.lock_id);
    call sw___ra_val_SwitchIngress_acquire_lock_push_back_alu, sw___ra_ret_SwitchIngress_acquire_lock_push_back_alu := sw_SwitchIngress_acquire_lock_push_back_alu.apply(sw___ra_val_SwitchIngress_acquire_lock_push_back_alu, sw___ra_ret_SwitchIngress_acquire_lock_push_back_alu);
    sw_slots_two_sides_register__next_write_site := 2;
    call sw_slots_two_sides_register.write(sw_ig_md.lock_id, sw___ra_val_SwitchIngress_acquire_lock_push_back_alu);
    sw_ig_md.empty_slots := sw___ra_ret_SwitchIngress_acquire_lock_push_back_alu;
}

// sw_RegisterAction sw_SwitchIngress_acquire_lock_push_back_alu.apply
procedure {:inline 1} sw_SwitchIngress_acquire_lock_push_back_alu.apply(sw_value_in:sw_pair, sw_result_in:bv32) returns (sw_value_out:sw_pair, sw_result_out:bv32)
{
    var sw_value:sw_pair;
    var sw_result:bv32;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    sw_result := sw_value[64:32];
    if(bugt.bv32(sw_value[64:32], 0bv32)){
        sw_value := add.bv32(sw_value[64:32], 4294967295bv32)++sw_value[32:0];
    }
    sw_value := sw_value[64:32]++add.bv32(sw_value[32:0], 4294967295bv32);
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Action sw_SwitchIngress_acquire_lock_set_as_failure_notification_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_set_as_failure_notification_action()
	modifies sw_hdr.ethernet.dstAddr;
{
    sw_hdr.ethernet.dstAddr := 3bv48;
}

// sw_Action sw_SwitchIngress_acquire_lock_set_as_primary_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_set_as_primary_action()
	modifies sw_hdr.ethernet.dstAddr;
{
    sw_hdr.ethernet.dstAddr := 1bv48;
}

// sw_Action sw_SwitchIngress_acquire_lock_set_as_secondary_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_set_as_secondary_action()
	modifies sw_hdr.ethernet.dstAddr;
{
    sw_hdr.ethernet.dstAddr := 2bv48;
}

// sw_Table sw_SwitchIngress_acquire_lock_set_tag_table
procedure {:inline 1} sw_SwitchIngress_acquire_lock_set_tag_table.apply()
	modifies sw_SwitchIngress_acquire_lock_set_tag_table.action_run, sw_SwitchIngress_acquire_lock_set_tag_table.hit, sw_hdr.ethernet.dstAddr, sw_ig_md.failure_status, sw_ig_md.lock_exist;
{
    sw_ig_md.failure_status := sw_ig_md.failure_status;
    sw_ig_md.lock_exist := sw_ig_md.lock_exist;
    sw_SwitchIngress_acquire_lock_set_tag_table.hit := false;
    sw_SwitchIngress_acquire_lock_set_tag_table.action_run := sw_SwitchIngress_acquire_lock_set_tag_table.action.NoAction_6;
    call sw_NoAction_6();
    goto sw_Exit;

    sw_action_SwitchIngress_acquire_lock_set_as_primary_action:
    assume sw_SwitchIngress_acquire_lock_set_tag_table.action_run == sw_SwitchIngress_acquire_lock_set_tag_table.action.SwitchIngress_acquire_lock_set_as_primary_action;
    call sw_SwitchIngress_acquire_lock_set_as_primary_action();
    goto sw_Exit;

    sw_action_SwitchIngress_acquire_lock_set_as_secondary_action:
    assume sw_SwitchIngress_acquire_lock_set_tag_table.action_run == sw_SwitchIngress_acquire_lock_set_tag_table.action.SwitchIngress_acquire_lock_set_as_secondary_action;
    call sw_SwitchIngress_acquire_lock_set_as_secondary_action();
    goto sw_Exit;

    sw_action_SwitchIngress_acquire_lock_set_as_failure_notification_action:
    assume sw_SwitchIngress_acquire_lock_set_tag_table.action_run == sw_SwitchIngress_acquire_lock_set_tag_table.action.SwitchIngress_acquire_lock_set_as_failure_notification_action;
    call sw_SwitchIngress_acquire_lock_set_as_failure_notification_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_acquire_lock_switch_direct_grant_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_switch_direct_grant_action()
	modifies sw_hdr.nlk_hdr.op;
{
    sw_hdr.nlk_hdr.op := 4bv8;
}

// sw_Table sw_SwitchIngress_acquire_lock_switch_direct_grant_table
procedure {:inline 1} sw_SwitchIngress_acquire_lock_switch_direct_grant_table.apply()
	modifies sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action_run, sw_SwitchIngress_acquire_lock_switch_direct_grant_table.hit, sw_hdr.nlk_hdr.op;
{
    sw_SwitchIngress_acquire_lock_switch_direct_grant_table.hit := false;
    sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action_run := sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action.SwitchIngress_acquire_lock_switch_direct_grant_action;
    call sw_SwitchIngress_acquire_lock_switch_direct_grant_action();
    goto sw_Exit;

    sw_action_SwitchIngress_acquire_lock_switch_direct_grant_action:
    assume sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action_run == sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action.SwitchIngress_acquire_lock_switch_direct_grant_action;
    call sw_SwitchIngress_acquire_lock_switch_direct_grant_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_acquire_lock_update_client_id_array_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_client_id_array_action()
	modifies sw___ra_ret_SwitchIngress_acquire_lock_update_client_id_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_client_id_array_alu, sw_client_id_array_register, sw_client_id_array_register__last0_old_value, sw_client_id_array_register__last0_value, sw_client_id_array_register__last_index, sw_client_id_array_register__last_old_value, sw_client_id_array_register__last_value, sw_client_id_array_register__last_write_site, sw_client_id_array_register__next_write_site, sw_client_id_array_register__wrote_any, sw_client_id_array_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_acquire_lock_update_client_id_array_alu := sw_client_id_array_register.read(sw_client_id_array_register, sw_ig_md.tail);
    call sw___ra_val_SwitchIngress_acquire_lock_update_client_id_array_alu := sw_SwitchIngress_acquire_lock_update_client_id_array_alu.apply(sw___ra_val_SwitchIngress_acquire_lock_update_client_id_array_alu);
    sw___ra_ret_SwitchIngress_acquire_lock_update_client_id_array_alu := sw___ra_val_SwitchIngress_acquire_lock_update_client_id_array_alu;
    sw_client_id_array_register__next_write_site := 1;
    call sw_client_id_array_register.write(sw_ig_md.tail, sw___ra_val_SwitchIngress_acquire_lock_update_client_id_array_alu);
}

// sw_RegisterAction sw_SwitchIngress_acquire_lock_update_client_id_array_alu.apply
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_client_id_array_alu.apply(sw_value_in:bv8) returns (sw_value_out:bv8)
{
    var sw_value:bv8;
    sw_value := sw_value_in;
    sw_value := sw_hdr.nlk_hdr.client_id;
    sw_value_out := sw_value;
}

// sw_Table sw_SwitchIngress_acquire_lock_update_client_id_array_table
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_client_id_array_table.apply()
	modifies sw_SwitchIngress_acquire_lock_update_client_id_array_table.action_run, sw_SwitchIngress_acquire_lock_update_client_id_array_table.hit, sw___ra_ret_SwitchIngress_acquire_lock_update_client_id_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_client_id_array_alu, sw_client_id_array_register, sw_client_id_array_register__last0_old_value, sw_client_id_array_register__last0_value, sw_client_id_array_register__last_index, sw_client_id_array_register__last_old_value, sw_client_id_array_register__last_value, sw_client_id_array_register__last_write_site, sw_client_id_array_register__next_write_site, sw_client_id_array_register__wrote_any, sw_client_id_array_register__wrote_index0;
{
    sw_SwitchIngress_acquire_lock_update_client_id_array_table.hit := false;
    sw_SwitchIngress_acquire_lock_update_client_id_array_table.action_run := sw_SwitchIngress_acquire_lock_update_client_id_array_table.action.SwitchIngress_acquire_lock_update_client_id_array_action;
    call sw_SwitchIngress_acquire_lock_update_client_id_array_action();
    goto sw_Exit;

    sw_action_SwitchIngress_acquire_lock_update_client_id_array_action:
    assume sw_SwitchIngress_acquire_lock_update_client_id_array_table.action_run == sw_SwitchIngress_acquire_lock_update_client_id_array_table.action.SwitchIngress_acquire_lock_update_client_id_array_action;
    call sw_SwitchIngress_acquire_lock_update_client_id_array_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_acquire_lock_update_ip_array_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_ip_array_action()
	modifies sw___ra_ret_SwitchIngress_acquire_lock_update_ip_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_ip_array_alu, sw_ip_array_register, sw_ip_array_register__last0_old_value, sw_ip_array_register__last0_value, sw_ip_array_register__last_index, sw_ip_array_register__last_old_value, sw_ip_array_register__last_value, sw_ip_array_register__last_write_site, sw_ip_array_register__next_write_site, sw_ip_array_register__wrote_any, sw_ip_array_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_acquire_lock_update_ip_array_alu := sw_ip_array_register.read(sw_ip_array_register, sw_ig_md.tail);
    call sw___ra_val_SwitchIngress_acquire_lock_update_ip_array_alu := sw_SwitchIngress_acquire_lock_update_ip_array_alu.apply(sw___ra_val_SwitchIngress_acquire_lock_update_ip_array_alu);
    sw___ra_ret_SwitchIngress_acquire_lock_update_ip_array_alu := sw___ra_val_SwitchIngress_acquire_lock_update_ip_array_alu;
    sw_ip_array_register__next_write_site := 1;
    call sw_ip_array_register.write(sw_ig_md.tail, sw___ra_val_SwitchIngress_acquire_lock_update_ip_array_alu);
}

// sw_RegisterAction sw_SwitchIngress_acquire_lock_update_ip_array_alu.apply
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_ip_array_alu.apply(sw_value_in:bv32) returns (sw_value_out:bv32)
{
    var sw_value:bv32;
    sw_value := sw_value_in;
    sw_value := sw_hdr.ipv4.srcAddr;
    sw_value_out := sw_value;
}

// sw_Table sw_SwitchIngress_acquire_lock_update_ip_array_table
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_ip_array_table.apply()
	modifies sw_SwitchIngress_acquire_lock_update_ip_array_table.action_run, sw_SwitchIngress_acquire_lock_update_ip_array_table.hit, sw___ra_ret_SwitchIngress_acquire_lock_update_ip_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_ip_array_alu, sw_ip_array_register, sw_ip_array_register__last0_old_value, sw_ip_array_register__last0_value, sw_ip_array_register__last_index, sw_ip_array_register__last_old_value, sw_ip_array_register__last_value, sw_ip_array_register__last_write_site, sw_ip_array_register__next_write_site, sw_ip_array_register__wrote_any, sw_ip_array_register__wrote_index0;
{
    sw_SwitchIngress_acquire_lock_update_ip_array_table.hit := false;
    sw_SwitchIngress_acquire_lock_update_ip_array_table.action_run := sw_SwitchIngress_acquire_lock_update_ip_array_table.action.SwitchIngress_acquire_lock_update_ip_array_action;
    call sw_SwitchIngress_acquire_lock_update_ip_array_action();
    goto sw_Exit;

    sw_action_SwitchIngress_acquire_lock_update_ip_array_action:
    assume sw_SwitchIngress_acquire_lock_update_ip_array_table.action_run == sw_SwitchIngress_acquire_lock_update_ip_array_table.action.SwitchIngress_acquire_lock_update_ip_array_action;
    call sw_SwitchIngress_acquire_lock_update_ip_array_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_acquire_lock_update_mode_array_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_mode_array_action()
	modifies sw___ra_ret_SwitchIngress_acquire_lock_update_mode_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_mode_array_alu, sw_mode_array_register, sw_mode_array_register__last0_old_value, sw_mode_array_register__last0_value, sw_mode_array_register__last_index, sw_mode_array_register__last_old_value, sw_mode_array_register__last_value, sw_mode_array_register__last_write_site, sw_mode_array_register__next_write_site, sw_mode_array_register__wrote_any, sw_mode_array_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_acquire_lock_update_mode_array_alu := sw_mode_array_register.read(sw_mode_array_register, sw_ig_md.tail);
    call sw___ra_val_SwitchIngress_acquire_lock_update_mode_array_alu := sw_SwitchIngress_acquire_lock_update_mode_array_alu.apply(sw___ra_val_SwitchIngress_acquire_lock_update_mode_array_alu);
    sw___ra_ret_SwitchIngress_acquire_lock_update_mode_array_alu := sw___ra_val_SwitchIngress_acquire_lock_update_mode_array_alu;
    sw_mode_array_register__next_write_site := 1;
    call sw_mode_array_register.write(sw_ig_md.tail, sw___ra_val_SwitchIngress_acquire_lock_update_mode_array_alu);
}

// sw_RegisterAction sw_SwitchIngress_acquire_lock_update_mode_array_alu.apply
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_mode_array_alu.apply(sw_value_in:bv8) returns (sw_value_out:bv8)
{
    var sw_value:bv8;
    sw_value := sw_value_in;
    sw_value := sw_hdr.nlk_hdr.mode;
    sw_value_out := sw_value;
}

// sw_Table sw_SwitchIngress_acquire_lock_update_mode_array_table
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_mode_array_table.apply()
	modifies sw_SwitchIngress_acquire_lock_update_mode_array_table.action_run, sw_SwitchIngress_acquire_lock_update_mode_array_table.hit, sw___ra_ret_SwitchIngress_acquire_lock_update_mode_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_mode_array_alu, sw_mode_array_register, sw_mode_array_register__last0_old_value, sw_mode_array_register__last0_value, sw_mode_array_register__last_index, sw_mode_array_register__last_old_value, sw_mode_array_register__last_value, sw_mode_array_register__last_write_site, sw_mode_array_register__next_write_site, sw_mode_array_register__wrote_any, sw_mode_array_register__wrote_index0;
{
    sw_SwitchIngress_acquire_lock_update_mode_array_table.hit := false;
    sw_SwitchIngress_acquire_lock_update_mode_array_table.action_run := sw_SwitchIngress_acquire_lock_update_mode_array_table.action.SwitchIngress_acquire_lock_update_mode_array_action;
    call sw_SwitchIngress_acquire_lock_update_mode_array_action();
    goto sw_Exit;

    sw_action_SwitchIngress_acquire_lock_update_mode_array_action:
    assume sw_SwitchIngress_acquire_lock_update_mode_array_table.action_run == sw_SwitchIngress_acquire_lock_update_mode_array_table.action.SwitchIngress_acquire_lock_update_mode_array_action;
    call sw_SwitchIngress_acquire_lock_update_mode_array_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_acquire_lock_update_tail_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_tail_action()
	modifies sw___ra_ret_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tail_alu, sw_ig_md.tail, sw_tail_register, sw_tail_register__last0_old_value, sw_tail_register__last0_value, sw_tail_register__last_index, sw_tail_register__last_old_value, sw_tail_register__last_value, sw_tail_register__last_write_site, sw_tail_register__next_write_site, sw_tail_register__wrote_any, sw_tail_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_acquire_lock_update_tail_alu := sw_tail_register.read(sw_tail_register, sw_ig_md.lock_id);
    call sw___ra_val_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_tail_alu := sw_SwitchIngress_acquire_lock_update_tail_alu.apply(sw___ra_val_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_tail_alu);
    sw_tail_register__next_write_site := 1;
    call sw_tail_register.write(sw_ig_md.lock_id, sw___ra_val_SwitchIngress_acquire_lock_update_tail_alu);
    sw_ig_md.tail := sw___ra_ret_SwitchIngress_acquire_lock_update_tail_alu;
}

// sw_RegisterAction sw_SwitchIngress_acquire_lock_update_tail_alu.apply
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_tail_alu.apply(sw_value_in:bv32, sw_result_in:bv32) returns (sw_value_out:bv32, sw_result_out:bv32)
{
    var sw_value:bv32;
    var sw_result:bv32;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    if((sw_value == sw_ig_md.right)){
        sw_value := sw_ig_md.left;
    }
    else{
        sw_value := add.bv32(sw_value, 1bv32);
    }
    sw_result := sw_value;
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Table sw_SwitchIngress_acquire_lock_update_tail_table
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_tail_table.apply()
	modifies sw_SwitchIngress_acquire_lock_update_tail_table.action_run, sw_SwitchIngress_acquire_lock_update_tail_table.hit, sw___ra_ret_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tail_alu, sw_ig_md.tail, sw_tail_register, sw_tail_register__last0_old_value, sw_tail_register__last0_value, sw_tail_register__last_index, sw_tail_register__last_old_value, sw_tail_register__last_value, sw_tail_register__last_write_site, sw_tail_register__next_write_site, sw_tail_register__wrote_any, sw_tail_register__wrote_index0;
{
    sw_SwitchIngress_acquire_lock_update_tail_table.hit := false;
    sw_SwitchIngress_acquire_lock_update_tail_table.action_run := sw_SwitchIngress_acquire_lock_update_tail_table.action.SwitchIngress_acquire_lock_update_tail_action;
    call sw_SwitchIngress_acquire_lock_update_tail_action();
    goto sw_Exit;

    sw_action_SwitchIngress_acquire_lock_update_tail_action:
    assume sw_SwitchIngress_acquire_lock_update_tail_table.action_run == sw_SwitchIngress_acquire_lock_update_tail_table.action.SwitchIngress_acquire_lock_update_tail_action;
    call sw_SwitchIngress_acquire_lock_update_tail_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_acquire_lock_update_tid_array_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_tid_array_action()
	modifies sw___ra_ret_SwitchIngress_acquire_lock_update_tid_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tid_array_alu, sw_tid_array_register, sw_tid_array_register__last0_old_value, sw_tid_array_register__last0_value, sw_tid_array_register__last_index, sw_tid_array_register__last_old_value, sw_tid_array_register__last_value, sw_tid_array_register__last_write_site, sw_tid_array_register__next_write_site, sw_tid_array_register__wrote_any, sw_tid_array_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_acquire_lock_update_tid_array_alu := sw_tid_array_register.read(sw_tid_array_register, sw_ig_md.tail);
    call sw___ra_val_SwitchIngress_acquire_lock_update_tid_array_alu := sw_SwitchIngress_acquire_lock_update_tid_array_alu.apply(sw___ra_val_SwitchIngress_acquire_lock_update_tid_array_alu);
    sw___ra_ret_SwitchIngress_acquire_lock_update_tid_array_alu := sw___ra_val_SwitchIngress_acquire_lock_update_tid_array_alu;
    sw_tid_array_register__next_write_site := 1;
    call sw_tid_array_register.write(sw_ig_md.tail, sw___ra_val_SwitchIngress_acquire_lock_update_tid_array_alu);
}

// sw_RegisterAction sw_SwitchIngress_acquire_lock_update_tid_array_alu.apply
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_tid_array_alu.apply(sw_value_in:bv32) returns (sw_value_out:bv32)
{
    var sw_value:bv32;
    sw_value := sw_value_in;
    sw_value := sw_hdr.nlk_hdr.tid;
    sw_value_out := sw_value;
}

// sw_Table sw_SwitchIngress_acquire_lock_update_tid_array_table
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_tid_array_table.apply()
	modifies sw_SwitchIngress_acquire_lock_update_tid_array_table.action_run, sw_SwitchIngress_acquire_lock_update_tid_array_table.hit, sw___ra_ret_SwitchIngress_acquire_lock_update_tid_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tid_array_alu, sw_tid_array_register, sw_tid_array_register__last0_old_value, sw_tid_array_register__last0_value, sw_tid_array_register__last_index, sw_tid_array_register__last_old_value, sw_tid_array_register__last_value, sw_tid_array_register__last_write_site, sw_tid_array_register__next_write_site, sw_tid_array_register__wrote_any, sw_tid_array_register__wrote_index0;
{
    sw_SwitchIngress_acquire_lock_update_tid_array_table.hit := false;
    sw_SwitchIngress_acquire_lock_update_tid_array_table.action_run := sw_SwitchIngress_acquire_lock_update_tid_array_table.action.SwitchIngress_acquire_lock_update_tid_array_action;
    call sw_SwitchIngress_acquire_lock_update_tid_array_action();
    goto sw_Exit;

    sw_action_SwitchIngress_acquire_lock_update_tid_array_action:
    assume sw_SwitchIngress_acquire_lock_update_tid_array_table.action_run == sw_SwitchIngress_acquire_lock_update_tid_array_table.action.SwitchIngress_acquire_lock_update_tid_array_action;
    call sw_SwitchIngress_acquire_lock_update_tid_array_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_action()
	modifies sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw_timestamp_hi_array_register, sw_timestamp_hi_array_register__last0_old_value, sw_timestamp_hi_array_register__last0_value, sw_timestamp_hi_array_register__last_index, sw_timestamp_hi_array_register__last_old_value, sw_timestamp_hi_array_register__last_value, sw_timestamp_hi_array_register__last_write_site, sw_timestamp_hi_array_register__next_write_site, sw_timestamp_hi_array_register__wrote_any, sw_timestamp_hi_array_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu := sw_timestamp_hi_array_register.read(sw_timestamp_hi_array_register, sw_ig_md.tail);
    call sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu := sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu.apply(sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu);
    sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu := sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu;
    sw_timestamp_hi_array_register__next_write_site := 1;
    call sw_timestamp_hi_array_register.write(sw_ig_md.tail, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu);
}

// sw_RegisterAction sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu.apply
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu.apply(sw_value_in:bv32) returns (sw_value_out:bv32)
{
    var sw_value:bv32;
    sw_value := sw_value_in;
    sw_value := sw_ig_md.ts_hi;
    sw_value_out := sw_value;
}

// sw_Table sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.apply()
	modifies sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action_run, sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.hit, sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw_timestamp_hi_array_register, sw_timestamp_hi_array_register__last0_old_value, sw_timestamp_hi_array_register__last0_value, sw_timestamp_hi_array_register__last_index, sw_timestamp_hi_array_register__last_old_value, sw_timestamp_hi_array_register__last_value, sw_timestamp_hi_array_register__last_write_site, sw_timestamp_hi_array_register__next_write_site, sw_timestamp_hi_array_register__wrote_any, sw_timestamp_hi_array_register__wrote_index0;
{
    sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.hit := false;
    sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action_run := sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action.SwitchIngress_acquire_lock_update_timestamp_hi_array_action;
    call sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_action();
    goto sw_Exit;

    sw_action_SwitchIngress_acquire_lock_update_timestamp_hi_array_action:
    assume sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action_run == sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action.SwitchIngress_acquire_lock_update_timestamp_hi_array_action;
    call sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_action
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_action()
	modifies sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw_timestamp_lo_array_register, sw_timestamp_lo_array_register__last0_old_value, sw_timestamp_lo_array_register__last0_value, sw_timestamp_lo_array_register__last_index, sw_timestamp_lo_array_register__last_old_value, sw_timestamp_lo_array_register__last_value, sw_timestamp_lo_array_register__last_write_site, sw_timestamp_lo_array_register__next_write_site, sw_timestamp_lo_array_register__wrote_any, sw_timestamp_lo_array_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu := sw_timestamp_lo_array_register.read(sw_timestamp_lo_array_register, sw_ig_md.tail);
    call sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu := sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu.apply(sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu);
    sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu := sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu;
    sw_timestamp_lo_array_register__next_write_site := 1;
    call sw_timestamp_lo_array_register.write(sw_ig_md.tail, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu);
}

// sw_RegisterAction sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu.apply
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu.apply(sw_value_in:bv32) returns (sw_value_out:bv32)
{
    var sw_value:bv32;
    sw_value := sw_value_in;
    sw_value := sw_ig_md.ts_lo;
    sw_value_out := sw_value;
}

// sw_Table sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table
procedure {:inline 1} sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.apply()
	modifies sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action_run, sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.hit, sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw_timestamp_lo_array_register, sw_timestamp_lo_array_register__last0_old_value, sw_timestamp_lo_array_register__last0_value, sw_timestamp_lo_array_register__last_index, sw_timestamp_lo_array_register__last_old_value, sw_timestamp_lo_array_register__last_value, sw_timestamp_lo_array_register__last_write_site, sw_timestamp_lo_array_register__next_write_site, sw_timestamp_lo_array_register__wrote_any, sw_timestamp_lo_array_register__wrote_index0;
{
    sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.hit := false;
    sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action_run := sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action.SwitchIngress_acquire_lock_update_timestamp_lo_array_action;
    call sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_action();
    goto sw_Exit;

    sw_action_SwitchIngress_acquire_lock_update_timestamp_lo_array_action:
    assume sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action_run == sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action.SwitchIngress_acquire_lock_update_timestamp_lo_array_action;
    call sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_check_lock_exist_action
procedure {:inline 1} sw_SwitchIngress_check_lock_exist_action(sw_index_1:bv32)
	modifies sw_ig_md.lock_exist, sw_ig_md.lock_id;
{
    sw_ig_md.lock_exist := 1bv1;
    sw_ig_md.lock_id := sw_index_1;
}

// sw_Table sw_SwitchIngress_check_lock_exist_table
procedure {:inline 1} sw_SwitchIngress_check_lock_exist_table.apply()
	modifies sw_SwitchIngress_check_lock_exist_table.SwitchIngress_check_lock_exist_action.index_1, sw_SwitchIngress_check_lock_exist_table.action_run, sw_SwitchIngress_check_lock_exist_table.hit, sw_hdr.nlk_hdr.lock, sw_ig_md.lock_exist, sw_ig_md.lock_id;
{
    sw_hdr.nlk_hdr.lock := sw_hdr.nlk_hdr.lock;
    sw_SwitchIngress_check_lock_exist_table.hit := false;
    if(sw_hdr.nlk_hdr.lock == 0bv32){
        sw_SwitchIngress_check_lock_exist_table.hit := true;
        sw_SwitchIngress_check_lock_exist_table.action_run := sw_SwitchIngress_check_lock_exist_table.action.SwitchIngress_check_lock_exist_action;
        sw_SwitchIngress_check_lock_exist_table.SwitchIngress_check_lock_exist_action.index_1 := 0bv32;
        call sw_SwitchIngress_check_lock_exist_action(sw_SwitchIngress_check_lock_exist_table.SwitchIngress_check_lock_exist_action.index_1);
        goto sw_Exit;
    }
    if(!sw_SwitchIngress_check_lock_exist_table.hit){
        sw_SwitchIngress_check_lock_exist_table.action_run := sw_SwitchIngress_check_lock_exist_table.action.NoAction_12;
        call sw_NoAction_12();
        goto sw_Exit;
    }

    sw_Exit:
}

// sw_Action sw_SwitchIngress_decode_decode_action
procedure {:inline 1} sw_SwitchIngress_decode_decode_action()
	modifies sw___ra_ret_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_val_SwitchIngress_decode_get_queue_size_op_alu, sw_ig_md.queue_size_op, sw_ig_md.ts_hi, sw_ig_md.ts_lo, sw_queue_size_op_register, sw_queue_size_op_register__last0_old_value, sw_queue_size_op_register__last0_value, sw_queue_size_op_register__last_index, sw_queue_size_op_register__last_old_value, sw_queue_size_op_register__last_value, sw_queue_size_op_register__last_write_site, sw_queue_size_op_register__next_write_site, sw_queue_size_op_register__wrote_any, sw_queue_size_op_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_decode_get_queue_size_op_alu := sw_queue_size_op_register.read(sw_queue_size_op_register, sw_ig_md.lock_id);
    call sw___ra_val_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_ret_SwitchIngress_decode_get_queue_size_op_alu := sw_SwitchIngress_decode_get_queue_size_op_alu.apply(sw___ra_val_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_ret_SwitchIngress_decode_get_queue_size_op_alu);
    sw_queue_size_op_register__next_write_site := 1;
    call sw_queue_size_op_register.write(sw_ig_md.lock_id, sw___ra_val_SwitchIngress_decode_get_queue_size_op_alu);
    sw_ig_md.queue_size_op := sw___ra_ret_SwitchIngress_decode_get_queue_size_op_alu;
    sw_ig_md.ts_hi := sw_hdr.nlk_hdr.timestamp_hi;
    sw_ig_md.ts_lo := sw_hdr.nlk_hdr.timestamp_lo;
}

// sw_Table sw_SwitchIngress_decode_decode_table
procedure {:inline 1} sw_SwitchIngress_decode_decode_table.apply()
	modifies sw_SwitchIngress_decode_decode_table.action_run, sw_SwitchIngress_decode_decode_table.hit, sw___ra_ret_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_val_SwitchIngress_decode_get_queue_size_op_alu, sw_ig_md.queue_size_op, sw_ig_md.ts_hi, sw_ig_md.ts_lo, sw_queue_size_op_register, sw_queue_size_op_register__last0_old_value, sw_queue_size_op_register__last0_value, sw_queue_size_op_register__last_index, sw_queue_size_op_register__last_old_value, sw_queue_size_op_register__last_value, sw_queue_size_op_register__last_write_site, sw_queue_size_op_register__next_write_site, sw_queue_size_op_register__wrote_any, sw_queue_size_op_register__wrote_index0;
{
    sw_SwitchIngress_decode_decode_table.hit := false;
    sw_SwitchIngress_decode_decode_table.action_run := sw_SwitchIngress_decode_decode_table.action.SwitchIngress_decode_decode_action;
    call sw_SwitchIngress_decode_decode_action();
    goto sw_Exit;

    sw_action_SwitchIngress_decode_decode_action:
    assume sw_SwitchIngress_decode_decode_table.action_run == sw_SwitchIngress_decode_decode_table.action.SwitchIngress_decode_decode_action;
    call sw_SwitchIngress_decode_decode_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_decode_get_left_bound_action
procedure {:inline 1} sw_SwitchIngress_decode_get_left_bound_action()
	modifies sw___ra_ret_SwitchIngress_decode_get_left_bound_alu, sw___ra_val_SwitchIngress_decode_get_left_bound_alu, sw_ig_md.left, sw_left_bound_register, sw_left_bound_register__last0_old_value, sw_left_bound_register__last0_value, sw_left_bound_register__last_index, sw_left_bound_register__last_old_value, sw_left_bound_register__last_value, sw_left_bound_register__last_write_site, sw_left_bound_register__next_write_site, sw_left_bound_register__wrote_any, sw_left_bound_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_decode_get_left_bound_alu := sw_left_bound_register.read(sw_left_bound_register, sw_ig_md.lock_id);
    call sw___ra_val_SwitchIngress_decode_get_left_bound_alu, sw___ra_ret_SwitchIngress_decode_get_left_bound_alu := sw_SwitchIngress_decode_get_left_bound_alu.apply(sw___ra_val_SwitchIngress_decode_get_left_bound_alu, sw___ra_ret_SwitchIngress_decode_get_left_bound_alu);
    sw_left_bound_register__next_write_site := 1;
    call sw_left_bound_register.write(sw_ig_md.lock_id, sw___ra_val_SwitchIngress_decode_get_left_bound_alu);
    sw_ig_md.left := sw___ra_ret_SwitchIngress_decode_get_left_bound_alu;
}

// sw_RegisterAction sw_SwitchIngress_decode_get_left_bound_alu.apply
procedure {:inline 1} sw_SwitchIngress_decode_get_left_bound_alu.apply(sw_value_in:bv32, sw_result_in:bv32) returns (sw_value_out:bv32, sw_result_out:bv32)
{
    var sw_value:bv32;
    var sw_result:bv32;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    sw_result := sw_value;
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Table sw_SwitchIngress_decode_get_left_bound_table
procedure {:inline 1} sw_SwitchIngress_decode_get_left_bound_table.apply()
	modifies sw_SwitchIngress_decode_get_left_bound_table.action_run, sw_SwitchIngress_decode_get_left_bound_table.hit, sw___ra_ret_SwitchIngress_decode_get_left_bound_alu, sw___ra_val_SwitchIngress_decode_get_left_bound_alu, sw_ig_md.left, sw_left_bound_register, sw_left_bound_register__last0_old_value, sw_left_bound_register__last0_value, sw_left_bound_register__last_index, sw_left_bound_register__last_old_value, sw_left_bound_register__last_value, sw_left_bound_register__last_write_site, sw_left_bound_register__next_write_site, sw_left_bound_register__wrote_any, sw_left_bound_register__wrote_index0;
{
    sw_SwitchIngress_decode_get_left_bound_table.hit := false;
    sw_SwitchIngress_decode_get_left_bound_table.action_run := sw_SwitchIngress_decode_get_left_bound_table.action.SwitchIngress_decode_get_left_bound_action;
    call sw_SwitchIngress_decode_get_left_bound_action();
    goto sw_Exit;

    sw_action_SwitchIngress_decode_get_left_bound_action:
    assume sw_SwitchIngress_decode_get_left_bound_table.action_run == sw_SwitchIngress_decode_get_left_bound_table.action.SwitchIngress_decode_get_left_bound_action;
    call sw_SwitchIngress_decode_get_left_bound_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_RegisterAction sw_SwitchIngress_decode_get_queue_size_op_alu.apply
procedure {:inline 1} sw_SwitchIngress_decode_get_queue_size_op_alu.apply(sw_value_in:bv32, sw_result_in:bv32) returns (sw_value_out:bv32, sw_result_out:bv32)
{
    var sw_value:bv32;
    var sw_result:bv32;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    sw_result := sw_value;
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Action sw_SwitchIngress_decode_get_right_bound_action
procedure {:inline 1} sw_SwitchIngress_decode_get_right_bound_action()
	modifies sw___ra_ret_SwitchIngress_decode_get_right_bound_alu, sw___ra_val_SwitchIngress_decode_get_right_bound_alu, sw_ig_md.right, sw_right_bound_register, sw_right_bound_register__last0_old_value, sw_right_bound_register__last0_value, sw_right_bound_register__last_index, sw_right_bound_register__last_old_value, sw_right_bound_register__last_value, sw_right_bound_register__last_write_site, sw_right_bound_register__next_write_site, sw_right_bound_register__wrote_any, sw_right_bound_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_decode_get_right_bound_alu := sw_right_bound_register.read(sw_right_bound_register, sw_ig_md.lock_id);
    call sw___ra_val_SwitchIngress_decode_get_right_bound_alu, sw___ra_ret_SwitchIngress_decode_get_right_bound_alu := sw_SwitchIngress_decode_get_right_bound_alu.apply(sw___ra_val_SwitchIngress_decode_get_right_bound_alu, sw___ra_ret_SwitchIngress_decode_get_right_bound_alu);
    sw_right_bound_register__next_write_site := 1;
    call sw_right_bound_register.write(sw_ig_md.lock_id, sw___ra_val_SwitchIngress_decode_get_right_bound_alu);
    sw_ig_md.right := sw___ra_ret_SwitchIngress_decode_get_right_bound_alu;
}

// sw_RegisterAction sw_SwitchIngress_decode_get_right_bound_alu.apply
procedure {:inline 1} sw_SwitchIngress_decode_get_right_bound_alu.apply(sw_value_in:bv32, sw_result_in:bv32) returns (sw_value_out:bv32, sw_result_out:bv32)
{
    var sw_value:bv32;
    var sw_result:bv32;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    sw_result := sw_value;
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Table sw_SwitchIngress_decode_get_right_bound_table
procedure {:inline 1} sw_SwitchIngress_decode_get_right_bound_table.apply()
	modifies sw_SwitchIngress_decode_get_right_bound_table.action_run, sw_SwitchIngress_decode_get_right_bound_table.hit, sw___ra_ret_SwitchIngress_decode_get_right_bound_alu, sw___ra_val_SwitchIngress_decode_get_right_bound_alu, sw_ig_md.right, sw_right_bound_register, sw_right_bound_register__last0_old_value, sw_right_bound_register__last0_value, sw_right_bound_register__last_index, sw_right_bound_register__last_old_value, sw_right_bound_register__last_value, sw_right_bound_register__last_write_site, sw_right_bound_register__next_write_site, sw_right_bound_register__wrote_any, sw_right_bound_register__wrote_index0;
{
    sw_SwitchIngress_decode_get_right_bound_table.hit := false;
    sw_SwitchIngress_decode_get_right_bound_table.action_run := sw_SwitchIngress_decode_get_right_bound_table.action.SwitchIngress_decode_get_right_bound_action;
    call sw_SwitchIngress_decode_get_right_bound_action();
    goto sw_Exit;

    sw_action_SwitchIngress_decode_get_right_bound_action:
    assume sw_SwitchIngress_decode_get_right_bound_table.action_run == sw_SwitchIngress_decode_get_right_bound_table.action.SwitchIngress_decode_get_right_bound_action;
    call sw_SwitchIngress_decode_get_right_bound_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_decode_get_size_of_queue_action
procedure {:inline 1} sw_SwitchIngress_decode_get_size_of_queue_action()
	modifies sw_ig_md.size_of_queue;
{
    sw_ig_md.size_of_queue := sub.bv32(sw_ig_md.right, sw_ig_md.left);
}

// sw_Table sw_SwitchIngress_decode_get_size_of_queue_table
procedure {:inline 1} sw_SwitchIngress_decode_get_size_of_queue_table.apply()
	modifies sw_SwitchIngress_decode_get_size_of_queue_table.action_run, sw_SwitchIngress_decode_get_size_of_queue_table.hit, sw_ig_md.size_of_queue;
{
    sw_SwitchIngress_decode_get_size_of_queue_table.hit := false;
    sw_SwitchIngress_decode_get_size_of_queue_table.action_run := sw_SwitchIngress_decode_get_size_of_queue_table.action.SwitchIngress_decode_get_size_of_queue_action;
    call sw_SwitchIngress_decode_get_size_of_queue_action();
    goto sw_Exit;

    sw_action_SwitchIngress_decode_get_size_of_queue_action:
    assume sw_SwitchIngress_decode_get_size_of_queue_table.action_run == sw_SwitchIngress_decode_get_size_of_queue_table.action.SwitchIngress_decode_get_size_of_queue_action;
    call sw_SwitchIngress_decode_get_size_of_queue_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_do_recirculate
procedure {:inline 1} sw_SwitchIngress_do_recirculate()
	modifies sw_hdr.nlk_hdr.recirc_flag, sw_hdr.recirculate_hdr.dequeued_mode, sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.recirced, sw_p4b_recirculate;
{
    sw_hdr.nlk_hdr.recirc_flag := 1bv8;
    sw_p4b_recirculate := true;
    sw_hdr.recirculate_hdr.dequeued_mode := 1bv8;
    sw_ig_md.recirced := 1bv2;
    sw_ig_intr_tm_md.ucast_egress_port := 68bv9;
    sw_ig_intr_tm_md.bypass_egress := 1bv1;
}

// sw_Action sw_SwitchIngress_do_recirculate_2
procedure {:inline 1} sw_SwitchIngress_do_recirculate_2()
	modifies sw_hdr.nlk_hdr.recirc_flag, sw_hdr.recirculate_hdr.dequeued_mode, sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.recirced;
{
    sw_hdr.nlk_hdr.recirc_flag := 2bv8;
    sw_hdr.recirculate_hdr.dequeued_mode := add.bv8(sw_hdr.recirculate_hdr.dequeued_mode, 1bv8);
    sw_ig_md.recirced := 1bv2;
    sw_ig_intr_tm_md.ucast_egress_port := 68bv9;
    sw_ig_intr_tm_md.bypass_egress := 1bv1;
}

// sw_Action sw_SwitchIngress_drop
procedure {:inline 1} sw_SwitchIngress_drop()
	modifies sw_ig_intr_dprsr_md.drop_ctl;
{
    sw_ig_intr_dprsr_md.drop_ctl := 1bv3;
}

// sw_Action sw_SwitchIngress_fix_src_port_action
procedure {:inline 1} sw_SwitchIngress_fix_src_port_action(sw_fix_port_4:bv16)
	modifies sw_hdr.ethernet.srcAddr, sw_hdr.udp.srcPort;
{
    sw_hdr.ethernet.srcAddr := 0bv16++sw_hdr.ipv4.srcAddr;
    sw_hdr.udp.srcPort := sw_fix_port_4;
}

// sw_Table sw_SwitchIngress_fix_src_port_table
procedure {:inline 1} sw_SwitchIngress_fix_src_port_table.apply()
	modifies sw_SwitchIngress_fix_src_port_table.action_run, sw_SwitchIngress_fix_src_port_table.hit, sw_hdr.ethernet.srcAddr, sw_hdr.nlk_hdr.lock, sw_hdr.udp.srcPort;
{
    sw_hdr.nlk_hdr.lock := sw_hdr.nlk_hdr.lock;
    sw_SwitchIngress_fix_src_port_table.hit := false;
    sw_SwitchIngress_fix_src_port_table.action_run := sw_SwitchIngress_fix_src_port_table.action.NoAction_13;
    call sw_NoAction_13();
    goto sw_Exit;

    sw_action_SwitchIngress_fix_src_port_action:
    assume sw_SwitchIngress_fix_src_port_table.action_run == sw_SwitchIngress_fix_src_port_table.action.SwitchIngress_fix_src_port_action;
    call sw_SwitchIngress_fix_src_port_action(sw_SwitchIngress_fix_src_port_table.SwitchIngress_fix_src_port_action.fix_port_4);
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_forward_to_server_action
procedure {:inline 1} sw_SwitchIngress_forward_to_server_action(sw_server_ip_4:sw_ipv4_addr_t)
	modifies sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.srcAddr;
{
    sw_hdr.ipv4.srcAddr := sw_server_ip_4;
    sw_hdr.ipv4.dstAddr := sw_server_ip_4;
}

// sw_Table sw_SwitchIngress_forward_to_server_table
procedure {:inline 1} sw_SwitchIngress_forward_to_server_table.apply()
	modifies sw_SwitchIngress_forward_to_server_table.action_run, sw_SwitchIngress_forward_to_server_table.hit, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.srcAddr, sw_hdr.nlk_hdr.lock;
{
    sw_hdr.nlk_hdr.lock := sw_hdr.nlk_hdr.lock;
    sw_SwitchIngress_forward_to_server_table.hit := false;
    sw_SwitchIngress_forward_to_server_table.action_run := sw_SwitchIngress_forward_to_server_table.action.NoAction_15;
    call sw_NoAction_15();
    goto sw_Exit;

    sw_action_SwitchIngress_forward_to_server_action:
    assume sw_SwitchIngress_forward_to_server_table.action_run == sw_SwitchIngress_forward_to_server_table.action.SwitchIngress_forward_to_server_action;
    call sw_SwitchIngress_forward_to_server_action(sw_SwitchIngress_forward_to_server_table.SwitchIngress_forward_to_server_action.server_ip_4);
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_i2e_clone_action
procedure {:inline 1} sw_SwitchIngress_i2e_clone_action(sw_mirror_id_2:sw_MirrorId_t)
	modifies sw_ig_intr_dprsr_md.mirror_type, sw_ig_md.clone_md, sw_ig_md.ing_mir_ses, sw_ig_md.pkt_type, sw_p4b_clone_i2e;
{
    sw_ig_md.clone_md := 1bv8;
    sw_ig_intr_dprsr_md.mirror_type := 1bv3;
    sw_p4b_clone_i2e := sw_p4b_clone_i2e || (1bv3 != 0bv3);
    sw_ig_md.ing_mir_ses := sw_mirror_id_2;
    sw_ig_md.pkt_type := 1bv8;
}

// sw_Table sw_SwitchIngress_i2e_clone_table
procedure {:inline 1} sw_SwitchIngress_i2e_clone_table.apply()
	modifies sw_SwitchIngress_i2e_clone_table.action_run, sw_SwitchIngress_i2e_clone_table.hit, sw_hdr.ipv4.dstAddr, sw_ig_intr_dprsr_md.drop_ctl, sw_ig_intr_dprsr_md.mirror_type, sw_ig_md.clone_md, sw_ig_md.ing_mir_ses, sw_ig_md.pkt_type, sw_p4b_clone_i2e;
{
    sw_hdr.ipv4.dstAddr := sw_hdr.ipv4.dstAddr;
    sw_SwitchIngress_i2e_clone_table.hit := false;
    sw_SwitchIngress_i2e_clone_table.action_run := sw_SwitchIngress_i2e_clone_table.action.drop_1;
    call sw_drop_1();
    goto sw_Exit;

    sw_action_SwitchIngress_i2e_clone_action:
    assume sw_SwitchIngress_i2e_clone_table.action_run == sw_SwitchIngress_i2e_clone_table.action.SwitchIngress_i2e_clone_action;
    call sw_SwitchIngress_i2e_clone_action(sw_SwitchIngress_i2e_clone_table.SwitchIngress_i2e_clone_action.mirror_id_2);
    goto sw_Exit;

    sw_action_drop_1:
    assume sw_SwitchIngress_i2e_clone_table.action_run == sw_SwitchIngress_i2e_clone_table.action.drop_1;
    call sw_drop_1();
    goto sw_Exit;

    sw_Exit:
}

// sw_Table sw_SwitchIngress_ipv4_route_table
procedure {:inline 1} sw_SwitchIngress_ipv4_route_table.apply()
	modifies sw_SwitchIngress_ipv4_route_table.action_run, sw_SwitchIngress_ipv4_route_table.hit, sw_hdr.ipv4.dstAddr, sw_ig_intr_dprsr_md.drop_ctl, sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.routed;
{
    sw_hdr.ipv4.dstAddr := sw_hdr.ipv4.dstAddr;
    sw_SwitchIngress_ipv4_route_table.hit := false;
    sw_SwitchIngress_ipv4_route_table.action_run := sw_SwitchIngress_ipv4_route_table.action.SwitchIngress_drop;
    call sw_SwitchIngress_drop();
    goto sw_Exit;

    sw_action_SwitchIngress_set_egress:
    assume sw_SwitchIngress_ipv4_route_table.action_run == sw_SwitchIngress_ipv4_route_table.action.SwitchIngress_set_egress;
    call sw_SwitchIngress_set_egress(sw_SwitchIngress_ipv4_route_table.SwitchIngress_set_egress.egress_spec);
    goto sw_Exit;

    sw_action_SwitchIngress_drop:
    assume sw_SwitchIngress_ipv4_route_table.action_run == sw_SwitchIngress_ipv4_route_table.action.SwitchIngress_drop;
    call sw_SwitchIngress_drop();
    goto sw_Exit;

    sw_Exit:
}

// sw_Table sw_SwitchIngress_ipv4_route_table_2
procedure {:inline 1} sw_SwitchIngress_ipv4_route_table_2.apply()
	modifies sw_SwitchIngress_ipv4_route_table_2.action_run, sw_SwitchIngress_ipv4_route_table_2.hit, sw_hdr.ipv4.dstAddr, sw_ig_intr_dprsr_md.drop_ctl, sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.routed;
{
    sw_hdr.ipv4.dstAddr := sw_hdr.ipv4.dstAddr;
    sw_SwitchIngress_ipv4_route_table_2.hit := false;
    sw_SwitchIngress_ipv4_route_table_2.action_run := sw_SwitchIngress_ipv4_route_table_2.action.drop_0;
    call sw_drop_0();
    goto sw_Exit;

    sw_action_set_egress_1:
    assume sw_SwitchIngress_ipv4_route_table_2.action_run == sw_SwitchIngress_ipv4_route_table_2.action.set_egress_1;
    call sw_set_egress_1(sw_SwitchIngress_ipv4_route_table_2.set_egress_1.egress_spec_1);
    goto sw_Exit;

    sw_action_drop_0:
    assume sw_SwitchIngress_ipv4_route_table_2.action_run == sw_SwitchIngress_ipv4_route_table_2.action.drop_0;
    call sw_drop_0();
    goto sw_Exit;

    sw_Exit:
}

// sw_Table sw_SwitchIngress_recirculate_table
procedure {:inline 1} sw_SwitchIngress_recirculate_table.apply()
	modifies sw_SwitchIngress_recirculate_table.action_run, sw_SwitchIngress_recirculate_table.hit, sw_hdr.nlk_hdr.recirc_flag, sw_hdr.recirculate_hdr.dequeued_mode, sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.recirced, sw_p4b_recirculate;
{
    sw_SwitchIngress_recirculate_table.hit := false;
    sw_SwitchIngress_recirculate_table.action_run := sw_SwitchIngress_recirculate_table.action.SwitchIngress_do_recirculate;
    call sw_SwitchIngress_do_recirculate();
    goto sw_Exit;

    sw_action_SwitchIngress_do_recirculate:
    assume sw_SwitchIngress_recirculate_table.action_run == sw_SwitchIngress_recirculate_table.action.SwitchIngress_do_recirculate;
    call sw_SwitchIngress_do_recirculate();
    goto sw_Exit;

    sw_Exit:
}

// sw_Table sw_SwitchIngress_recirculate_table_2
procedure {:inline 1} sw_SwitchIngress_recirculate_table_2.apply()
	modifies sw_SwitchIngress_recirculate_table_2.action_run, sw_SwitchIngress_recirculate_table_2.hit, sw_hdr.nlk_hdr.recirc_flag, sw_hdr.recirculate_hdr.dequeued_mode, sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.recirced;
{
    sw_SwitchIngress_recirculate_table_2.hit := false;
    sw_SwitchIngress_recirculate_table_2.action_run := sw_SwitchIngress_recirculate_table_2.action.SwitchIngress_do_recirculate_2;
    call sw_SwitchIngress_do_recirculate_2();
    goto sw_Exit;

    sw_action_SwitchIngress_do_recirculate_2:
    assume sw_SwitchIngress_recirculate_table_2.action_run == sw_SwitchIngress_recirculate_table_2.action.SwitchIngress_do_recirculate_2;
    call sw_SwitchIngress_do_recirculate_2();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_drop
procedure {:inline 1} sw_SwitchIngress_release_lock_drop()
	modifies sw_ig_intr_dprsr_md.drop_ctl;
{
    sw_ig_intr_dprsr_md.drop_ctl := 1bv3;
}

// sw_Table sw_SwitchIngress_release_lock_drop_packet_table
procedure {:inline 1} sw_SwitchIngress_release_lock_drop_packet_table.apply()
	modifies sw_SwitchIngress_release_lock_drop_packet_table.action_run, sw_SwitchIngress_release_lock_drop_packet_table.hit, sw_ig_intr_dprsr_md.drop_ctl;
{
    sw_SwitchIngress_release_lock_drop_packet_table.hit := false;
    sw_SwitchIngress_release_lock_drop_packet_table.action_run := sw_SwitchIngress_release_lock_drop_packet_table.action.SwitchIngress_release_lock_drop;
    call sw_SwitchIngress_release_lock_drop();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_drop:
    assume sw_SwitchIngress_release_lock_drop_packet_table.action_run == sw_SwitchIngress_release_lock_drop_packet_table.action.SwitchIngress_release_lock_drop;
    call sw_SwitchIngress_release_lock_drop();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_fix_src_port_action
procedure {:inline 1} sw_SwitchIngress_release_lock_fix_src_port_action(sw_fix_port_3:bv16)
	modifies sw_hdr.ethernet.srcAddr, sw_hdr.udp.srcPort;
{
    sw_hdr.ethernet.srcAddr := 0bv16++sw_hdr.ipv4.srcAddr;
    sw_hdr.udp.srcPort := sw_fix_port_3;
}

// sw_Table sw_SwitchIngress_release_lock_fix_src_port_table
procedure {:inline 1} sw_SwitchIngress_release_lock_fix_src_port_table.apply()
	modifies sw_SwitchIngress_release_lock_fix_src_port_table.action_run, sw_SwitchIngress_release_lock_fix_src_port_table.hit, sw_hdr.ethernet.srcAddr, sw_hdr.nlk_hdr.lock, sw_hdr.udp.srcPort;
{
    sw_hdr.nlk_hdr.lock := sw_hdr.nlk_hdr.lock;
    sw_SwitchIngress_release_lock_fix_src_port_table.hit := false;
    sw_SwitchIngress_release_lock_fix_src_port_table.action_run := sw_SwitchIngress_release_lock_fix_src_port_table.action.NoAction_8;
    call sw_NoAction_8();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_fix_src_port_action:
    assume sw_SwitchIngress_release_lock_fix_src_port_table.action_run == sw_SwitchIngress_release_lock_fix_src_port_table.action.SwitchIngress_release_lock_fix_src_port_action;
    call sw_SwitchIngress_release_lock_fix_src_port_action(sw_SwitchIngress_release_lock_fix_src_port_table.SwitchIngress_release_lock_fix_src_port_action.fix_port_3);
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_forward_to_server_action
procedure {:inline 1} sw_SwitchIngress_release_lock_forward_to_server_action(sw_server_ip_3:sw_ipv4_addr_t)
	modifies sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.srcAddr, sw_hdr.nlk_hdr.empty_slots, sw_hdr.nlk_hdr.head, sw_hdr.nlk_hdr.tail;
{
    sw_hdr.ipv4.srcAddr := sw_server_ip_3;
    sw_hdr.ipv4.dstAddr := sw_server_ip_3;
    sw_hdr.nlk_hdr.empty_slots := sw_ig_md.empty_slots_before_pop;
    sw_hdr.nlk_hdr.head := sw_ig_md.head;
    sw_hdr.nlk_hdr.tail := sw_ig_md.tail;
}

// sw_Table sw_SwitchIngress_release_lock_forward_to_server_table
procedure {:inline 1} sw_SwitchIngress_release_lock_forward_to_server_table.apply()
	modifies sw_SwitchIngress_release_lock_forward_to_server_table.action_run, sw_SwitchIngress_release_lock_forward_to_server_table.hit, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.srcAddr, sw_hdr.nlk_hdr.empty_slots, sw_hdr.nlk_hdr.head, sw_hdr.nlk_hdr.lock, sw_hdr.nlk_hdr.tail;
{
    sw_hdr.nlk_hdr.lock := sw_hdr.nlk_hdr.lock;
    sw_SwitchIngress_release_lock_forward_to_server_table.hit := false;
    sw_SwitchIngress_release_lock_forward_to_server_table.action_run := sw_SwitchIngress_release_lock_forward_to_server_table.action.NoAction_10;
    call sw_NoAction_10();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_forward_to_server_action:
    assume sw_SwitchIngress_release_lock_forward_to_server_table.action_run == sw_SwitchIngress_release_lock_forward_to_server_table.action.SwitchIngress_release_lock_forward_to_server_action;
    call sw_SwitchIngress_release_lock_forward_to_server_action(sw_SwitchIngress_release_lock_forward_to_server_table.SwitchIngress_release_lock_forward_to_server_action.server_ip_3);
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_get_client_id_action
procedure {:inline 1} sw_SwitchIngress_release_lock_get_client_id_action()
	modifies sw___ra_ret_SwitchIngress_release_lock_get_client_id_alu, sw___ra_val_SwitchIngress_release_lock_get_client_id_alu, sw_client_id_array_register, sw_client_id_array_register__last0_old_value, sw_client_id_array_register__last0_value, sw_client_id_array_register__last_index, sw_client_id_array_register__last_old_value, sw_client_id_array_register__last_value, sw_client_id_array_register__last_write_site, sw_client_id_array_register__next_write_site, sw_client_id_array_register__wrote_any, sw_client_id_array_register__wrote_index0, sw_ig_md.client_id;
{
    sw___ra_val_SwitchIngress_release_lock_get_client_id_alu := sw_client_id_array_register.read(sw_client_id_array_register, sw_ig_md.head);
    call sw___ra_val_SwitchIngress_release_lock_get_client_id_alu, sw___ra_ret_SwitchIngress_release_lock_get_client_id_alu := sw_SwitchIngress_release_lock_get_client_id_alu.apply(sw___ra_val_SwitchIngress_release_lock_get_client_id_alu, sw___ra_ret_SwitchIngress_release_lock_get_client_id_alu);
    sw_client_id_array_register__next_write_site := 2;
    call sw_client_id_array_register.write(sw_ig_md.head, sw___ra_val_SwitchIngress_release_lock_get_client_id_alu);
    sw_ig_md.client_id := sw___ra_ret_SwitchIngress_release_lock_get_client_id_alu;
}

// sw_RegisterAction sw_SwitchIngress_release_lock_get_client_id_alu.apply
procedure {:inline 1} sw_SwitchIngress_release_lock_get_client_id_alu.apply(sw_value_in:bv8, sw_result_in:bv8) returns (sw_value_out:bv8, sw_result_out:bv8)
{
    var sw_value:bv8;
    var sw_result:bv8;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    sw_result := sw_value;
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Table sw_SwitchIngress_release_lock_get_client_id_table
procedure {:inline 1} sw_SwitchIngress_release_lock_get_client_id_table.apply()
	modifies sw_SwitchIngress_release_lock_get_client_id_table.action_run, sw_SwitchIngress_release_lock_get_client_id_table.hit, sw___ra_ret_SwitchIngress_release_lock_get_client_id_alu, sw___ra_val_SwitchIngress_release_lock_get_client_id_alu, sw_client_id_array_register, sw_client_id_array_register__last0_old_value, sw_client_id_array_register__last0_value, sw_client_id_array_register__last_index, sw_client_id_array_register__last_old_value, sw_client_id_array_register__last_value, sw_client_id_array_register__last_write_site, sw_client_id_array_register__next_write_site, sw_client_id_array_register__wrote_any, sw_client_id_array_register__wrote_index0, sw_ig_md.client_id;
{
    sw_SwitchIngress_release_lock_get_client_id_table.hit := false;
    sw_SwitchIngress_release_lock_get_client_id_table.action_run := sw_SwitchIngress_release_lock_get_client_id_table.action.SwitchIngress_release_lock_get_client_id_action;
    call sw_SwitchIngress_release_lock_get_client_id_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_get_client_id_action:
    assume sw_SwitchIngress_release_lock_get_client_id_table.action_run == sw_SwitchIngress_release_lock_get_client_id_table.action.SwitchIngress_release_lock_get_client_id_action;
    call sw_SwitchIngress_release_lock_get_client_id_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_get_ip_action
procedure {:inline 1} sw_SwitchIngress_release_lock_get_ip_action()
	modifies sw___ra_ret_SwitchIngress_release_lock_get_ip_alu, sw___ra_val_SwitchIngress_release_lock_get_ip_alu, sw_ig_md.ip_address, sw_ig_md.timestamp_hi, sw_ig_md.timestamp_lo, sw_ip_array_register, sw_ip_array_register__last0_old_value, sw_ip_array_register__last0_value, sw_ip_array_register__last_index, sw_ip_array_register__last_old_value, sw_ip_array_register__last_value, sw_ip_array_register__last_write_site, sw_ip_array_register__next_write_site, sw_ip_array_register__wrote_any, sw_ip_array_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_release_lock_get_ip_alu := sw_ip_array_register.read(sw_ip_array_register, sw_ig_md.head);
    call sw___ra_val_SwitchIngress_release_lock_get_ip_alu, sw___ra_ret_SwitchIngress_release_lock_get_ip_alu := sw_SwitchIngress_release_lock_get_ip_alu.apply(sw___ra_val_SwitchIngress_release_lock_get_ip_alu, sw___ra_ret_SwitchIngress_release_lock_get_ip_alu);
    sw_ip_array_register__next_write_site := 2;
    call sw_ip_array_register.write(sw_ig_md.head, sw___ra_val_SwitchIngress_release_lock_get_ip_alu);
    sw_ig_md.ip_address := sw___ra_ret_SwitchIngress_release_lock_get_ip_alu;
    sw_ig_md.timestamp_hi := sw_ig_md.tail;
    sw_ig_md.timestamp_lo := sw_ig_md.head;
}

// sw_RegisterAction sw_SwitchIngress_release_lock_get_ip_alu.apply
procedure {:inline 1} sw_SwitchIngress_release_lock_get_ip_alu.apply(sw_value_in:bv32, sw_result_in:bv32) returns (sw_value_out:bv32, sw_result_out:bv32)
{
    var sw_value:bv32;
    var sw_result:bv32;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    sw_result := sw_value;
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Table sw_SwitchIngress_release_lock_get_ip_table
procedure {:inline 1} sw_SwitchIngress_release_lock_get_ip_table.apply()
	modifies sw_SwitchIngress_release_lock_get_ip_table.action_run, sw_SwitchIngress_release_lock_get_ip_table.hit, sw___ra_ret_SwitchIngress_release_lock_get_ip_alu, sw___ra_val_SwitchIngress_release_lock_get_ip_alu, sw_ig_md.ip_address, sw_ig_md.timestamp_hi, sw_ig_md.timestamp_lo, sw_ip_array_register, sw_ip_array_register__last0_old_value, sw_ip_array_register__last0_value, sw_ip_array_register__last_index, sw_ip_array_register__last_old_value, sw_ip_array_register__last_value, sw_ip_array_register__last_write_site, sw_ip_array_register__next_write_site, sw_ip_array_register__wrote_any, sw_ip_array_register__wrote_index0;
{
    sw_SwitchIngress_release_lock_get_ip_table.hit := false;
    sw_SwitchIngress_release_lock_get_ip_table.action_run := sw_SwitchIngress_release_lock_get_ip_table.action.SwitchIngress_release_lock_get_ip_action;
    call sw_SwitchIngress_release_lock_get_ip_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_get_ip_action:
    assume sw_SwitchIngress_release_lock_get_ip_table.action_run == sw_SwitchIngress_release_lock_get_ip_table.action.SwitchIngress_release_lock_get_ip_action;
    call sw_SwitchIngress_release_lock_get_ip_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_get_mode_action
procedure {:inline 1} sw_SwitchIngress_release_lock_get_mode_action()
	modifies sw___ra_ret_SwitchIngress_release_lock_get_mode_alu, sw___ra_val_SwitchIngress_release_lock_get_mode_alu, sw_ig_md.mode, sw_mode_array_register, sw_mode_array_register__last0_old_value, sw_mode_array_register__last0_value, sw_mode_array_register__last_index, sw_mode_array_register__last_old_value, sw_mode_array_register__last_value, sw_mode_array_register__last_write_site, sw_mode_array_register__next_write_site, sw_mode_array_register__wrote_any, sw_mode_array_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_release_lock_get_mode_alu := sw_mode_array_register.read(sw_mode_array_register, sw_ig_md.head);
    call sw___ra_val_SwitchIngress_release_lock_get_mode_alu, sw___ra_ret_SwitchIngress_release_lock_get_mode_alu := sw_SwitchIngress_release_lock_get_mode_alu.apply(sw___ra_val_SwitchIngress_release_lock_get_mode_alu, sw___ra_ret_SwitchIngress_release_lock_get_mode_alu);
    sw_mode_array_register__next_write_site := 2;
    call sw_mode_array_register.write(sw_ig_md.head, sw___ra_val_SwitchIngress_release_lock_get_mode_alu);
    sw_ig_md.mode := sw___ra_ret_SwitchIngress_release_lock_get_mode_alu;
}

// sw_RegisterAction sw_SwitchIngress_release_lock_get_mode_alu.apply
procedure {:inline 1} sw_SwitchIngress_release_lock_get_mode_alu.apply(sw_value_in:bv8, sw_result_in:bv8) returns (sw_value_out:bv8, sw_result_out:bv8)
{
    var sw_value:bv8;
    var sw_result:bv8;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    sw_result := sw_value;
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Table sw_SwitchIngress_release_lock_get_mode_table
procedure {:inline 1} sw_SwitchIngress_release_lock_get_mode_table.apply()
	modifies sw_SwitchIngress_release_lock_get_mode_table.action_run, sw_SwitchIngress_release_lock_get_mode_table.hit, sw___ra_ret_SwitchIngress_release_lock_get_mode_alu, sw___ra_val_SwitchIngress_release_lock_get_mode_alu, sw_ig_md.mode, sw_mode_array_register, sw_mode_array_register__last0_old_value, sw_mode_array_register__last0_value, sw_mode_array_register__last_index, sw_mode_array_register__last_old_value, sw_mode_array_register__last_value, sw_mode_array_register__last_write_site, sw_mode_array_register__next_write_site, sw_mode_array_register__wrote_any, sw_mode_array_register__wrote_index0;
{
    sw_SwitchIngress_release_lock_get_mode_table.hit := false;
    sw_SwitchIngress_release_lock_get_mode_table.action_run := sw_SwitchIngress_release_lock_get_mode_table.action.SwitchIngress_release_lock_get_mode_action;
    call sw_SwitchIngress_release_lock_get_mode_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_get_mode_action:
    assume sw_SwitchIngress_release_lock_get_mode_table.action_run == sw_SwitchIngress_release_lock_get_mode_table.action.SwitchIngress_release_lock_get_mode_action;
    call sw_SwitchIngress_release_lock_get_mode_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_get_recirc_info_action
procedure {:inline 1} sw_SwitchIngress_release_lock_get_recirc_info_action()
	modifies sw_ig_md.dequeued_mode, sw_ig_md.head, sw_ig_md.recirc_flag, sw_ig_md.tail;
{
    sw_ig_md.tail := sw_hdr.recirculate_hdr.cur_tail;
    sw_ig_md.head := sw_hdr.recirculate_hdr.cur_head;
    sw_ig_md.recirc_flag := sw_hdr.nlk_hdr.recirc_flag;
    sw_ig_md.dequeued_mode := sw_hdr.recirculate_hdr.dequeued_mode;
}

// sw_Table sw_SwitchIngress_release_lock_get_recirc_info_table
procedure {:inline 1} sw_SwitchIngress_release_lock_get_recirc_info_table.apply()
	modifies sw_SwitchIngress_release_lock_get_recirc_info_table.action_run, sw_SwitchIngress_release_lock_get_recirc_info_table.hit, sw_ig_md.dequeued_mode, sw_ig_md.head, sw_ig_md.recirc_flag, sw_ig_md.tail;
{
    sw_SwitchIngress_release_lock_get_recirc_info_table.hit := false;
    sw_SwitchIngress_release_lock_get_recirc_info_table.action_run := sw_SwitchIngress_release_lock_get_recirc_info_table.action.SwitchIngress_release_lock_get_recirc_info_action;
    call sw_SwitchIngress_release_lock_get_recirc_info_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_get_recirc_info_action:
    assume sw_SwitchIngress_release_lock_get_recirc_info_table.action_run == sw_SwitchIngress_release_lock_get_recirc_info_table.action.SwitchIngress_release_lock_get_recirc_info_action;
    call sw_SwitchIngress_release_lock_get_recirc_info_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_get_tail_action
procedure {:inline 1} sw_SwitchIngress_release_lock_get_tail_action()
	modifies sw___ra_ret_SwitchIngress_release_lock_get_tail_alu, sw___ra_val_SwitchIngress_release_lock_get_tail_alu, sw_ig_md.tail, sw_tail_register, sw_tail_register__last0_old_value, sw_tail_register__last0_value, sw_tail_register__last_index, sw_tail_register__last_old_value, sw_tail_register__last_value, sw_tail_register__last_write_site, sw_tail_register__next_write_site, sw_tail_register__wrote_any, sw_tail_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_release_lock_get_tail_alu := sw_tail_register.read(sw_tail_register, sw_ig_md.lock_id);
    call sw___ra_val_SwitchIngress_release_lock_get_tail_alu, sw___ra_ret_SwitchIngress_release_lock_get_tail_alu := sw_SwitchIngress_release_lock_get_tail_alu.apply(sw___ra_val_SwitchIngress_release_lock_get_tail_alu, sw___ra_ret_SwitchIngress_release_lock_get_tail_alu);
    sw_tail_register__next_write_site := 2;
    call sw_tail_register.write(sw_ig_md.lock_id, sw___ra_val_SwitchIngress_release_lock_get_tail_alu);
    sw_ig_md.tail := sw___ra_ret_SwitchIngress_release_lock_get_tail_alu;
}

// sw_RegisterAction sw_SwitchIngress_release_lock_get_tail_alu.apply
procedure {:inline 1} sw_SwitchIngress_release_lock_get_tail_alu.apply(sw_value_in:bv32, sw_result_in:bv32) returns (sw_value_out:bv32, sw_result_out:bv32)
{
    var sw_value:bv32;
    var sw_result:bv32;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    sw_result := sw_value;
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Table sw_SwitchIngress_release_lock_get_tail_table
procedure {:inline 1} sw_SwitchIngress_release_lock_get_tail_table.apply()
	modifies sw_SwitchIngress_release_lock_get_tail_table.action_run, sw_SwitchIngress_release_lock_get_tail_table.hit, sw___ra_ret_SwitchIngress_release_lock_get_tail_alu, sw___ra_val_SwitchIngress_release_lock_get_tail_alu, sw_ig_md.tail, sw_tail_register, sw_tail_register__last0_old_value, sw_tail_register__last0_value, sw_tail_register__last_index, sw_tail_register__last_old_value, sw_tail_register__last_value, sw_tail_register__last_write_site, sw_tail_register__next_write_site, sw_tail_register__wrote_any, sw_tail_register__wrote_index0;
{
    sw_SwitchIngress_release_lock_get_tail_table.hit := false;
    sw_SwitchIngress_release_lock_get_tail_table.action_run := sw_SwitchIngress_release_lock_get_tail_table.action.SwitchIngress_release_lock_get_tail_action;
    call sw_SwitchIngress_release_lock_get_tail_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_get_tail_action:
    assume sw_SwitchIngress_release_lock_get_tail_table.action_run == sw_SwitchIngress_release_lock_get_tail_table.action.SwitchIngress_release_lock_get_tail_action;
    call sw_SwitchIngress_release_lock_get_tail_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_get_tid_action
procedure {:inline 1} sw_SwitchIngress_release_lock_get_tid_action()
	modifies sw___ra_ret_SwitchIngress_release_lock_get_tid_alu, sw___ra_val_SwitchIngress_release_lock_get_tid_alu, sw_ig_md.tid, sw_tid_array_register, sw_tid_array_register__last0_old_value, sw_tid_array_register__last0_value, sw_tid_array_register__last_index, sw_tid_array_register__last_old_value, sw_tid_array_register__last_value, sw_tid_array_register__last_write_site, sw_tid_array_register__next_write_site, sw_tid_array_register__wrote_any, sw_tid_array_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_release_lock_get_tid_alu := sw_tid_array_register.read(sw_tid_array_register, sw_ig_md.head);
    call sw___ra_val_SwitchIngress_release_lock_get_tid_alu, sw___ra_ret_SwitchIngress_release_lock_get_tid_alu := sw_SwitchIngress_release_lock_get_tid_alu.apply(sw___ra_val_SwitchIngress_release_lock_get_tid_alu, sw___ra_ret_SwitchIngress_release_lock_get_tid_alu);
    sw_tid_array_register__next_write_site := 2;
    call sw_tid_array_register.write(sw_ig_md.head, sw___ra_val_SwitchIngress_release_lock_get_tid_alu);
    sw_ig_md.tid := sw___ra_ret_SwitchIngress_release_lock_get_tid_alu;
}

// sw_RegisterAction sw_SwitchIngress_release_lock_get_tid_alu.apply
procedure {:inline 1} sw_SwitchIngress_release_lock_get_tid_alu.apply(sw_value_in:bv32, sw_result_in:bv32) returns (sw_value_out:bv32, sw_result_out:bv32)
{
    var sw_value:bv32;
    var sw_result:bv32;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    sw_result := sw_value;
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Table sw_SwitchIngress_release_lock_get_tid_table
procedure {:inline 1} sw_SwitchIngress_release_lock_get_tid_table.apply()
	modifies sw_SwitchIngress_release_lock_get_tid_table.action_run, sw_SwitchIngress_release_lock_get_tid_table.hit, sw___ra_ret_SwitchIngress_release_lock_get_tid_alu, sw___ra_val_SwitchIngress_release_lock_get_tid_alu, sw_ig_md.tid, sw_tid_array_register, sw_tid_array_register__last0_old_value, sw_tid_array_register__last0_value, sw_tid_array_register__last_index, sw_tid_array_register__last_old_value, sw_tid_array_register__last_value, sw_tid_array_register__last_write_site, sw_tid_array_register__next_write_site, sw_tid_array_register__wrote_any, sw_tid_array_register__wrote_index0;
{
    sw_SwitchIngress_release_lock_get_tid_table.hit := false;
    sw_SwitchIngress_release_lock_get_tid_table.action_run := sw_SwitchIngress_release_lock_get_tid_table.action.SwitchIngress_release_lock_get_tid_action;
    call sw_SwitchIngress_release_lock_get_tid_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_get_tid_action:
    assume sw_SwitchIngress_release_lock_get_tid_table.action_run == sw_SwitchIngress_release_lock_get_tid_table.action.SwitchIngress_release_lock_get_tid_action;
    call sw_SwitchIngress_release_lock_get_tid_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_get_timestamp_hi_action
procedure {:inline 1} sw_SwitchIngress_release_lock_get_timestamp_hi_action()
{
}

// sw_RegisterAction sw_SwitchIngress_release_lock_get_timestamp_hi_alu.apply
procedure {:inline 1} sw_SwitchIngress_release_lock_get_timestamp_hi_alu.apply(sw_value_in:bv32, sw_result_in:bv32) returns (sw_value_out:bv32, sw_result_out:bv32)
{
    var sw_value:bv32;
    var sw_result:bv32;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    sw_result := sw_value;
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Table sw_SwitchIngress_release_lock_get_timestamp_hi_table
procedure {:inline 1} sw_SwitchIngress_release_lock_get_timestamp_hi_table.apply()
	modifies sw_SwitchIngress_release_lock_get_timestamp_hi_table.action_run, sw_SwitchIngress_release_lock_get_timestamp_hi_table.hit;
{
    sw_SwitchIngress_release_lock_get_timestamp_hi_table.hit := false;
    sw_SwitchIngress_release_lock_get_timestamp_hi_table.action_run := sw_SwitchIngress_release_lock_get_timestamp_hi_table.action.SwitchIngress_release_lock_get_timestamp_hi_action;
    call sw_SwitchIngress_release_lock_get_timestamp_hi_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_get_timestamp_hi_action:
    assume sw_SwitchIngress_release_lock_get_timestamp_hi_table.action_run == sw_SwitchIngress_release_lock_get_timestamp_hi_table.action.SwitchIngress_release_lock_get_timestamp_hi_action;
    call sw_SwitchIngress_release_lock_get_timestamp_hi_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_get_timestamp_lo_action
procedure {:inline 1} sw_SwitchIngress_release_lock_get_timestamp_lo_action()
{
}

// sw_RegisterAction sw_SwitchIngress_release_lock_get_timestamp_lo_alu.apply
procedure {:inline 1} sw_SwitchIngress_release_lock_get_timestamp_lo_alu.apply(sw_value_in:bv32, sw_result_in:bv32) returns (sw_value_out:bv32, sw_result_out:bv32)
{
    var sw_value:bv32;
    var sw_result:bv32;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    sw_result := sw_value;
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Table sw_SwitchIngress_release_lock_get_timestamp_lo_table
procedure {:inline 1} sw_SwitchIngress_release_lock_get_timestamp_lo_table.apply()
	modifies sw_SwitchIngress_release_lock_get_timestamp_lo_table.action_run, sw_SwitchIngress_release_lock_get_timestamp_lo_table.hit;
{
    sw_SwitchIngress_release_lock_get_timestamp_lo_table.hit := false;
    sw_SwitchIngress_release_lock_get_timestamp_lo_table.action_run := sw_SwitchIngress_release_lock_get_timestamp_lo_table.action.SwitchIngress_release_lock_get_timestamp_lo_action;
    call sw_SwitchIngress_release_lock_get_timestamp_lo_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_get_timestamp_lo_action:
    assume sw_SwitchIngress_release_lock_get_timestamp_lo_table.action_run == sw_SwitchIngress_release_lock_get_timestamp_lo_table.action.SwitchIngress_release_lock_get_timestamp_lo_action;
    call sw_SwitchIngress_release_lock_get_timestamp_lo_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_i2e_mirror_action
procedure {:inline 1} sw_SwitchIngress_release_lock_i2e_mirror_action(sw_mirror_id:sw_MirrorId_t)
	modifies sw_ig_intr_dprsr_md.mirror_type, sw_ig_md.clone_md, sw_ig_md.ing_mir_ses, sw_ig_md.pkt_type, sw_p4b_clone_i2e;
{
    sw_ig_md.clone_md := 1bv8;
    sw_ig_intr_dprsr_md.mirror_type := 1bv3;
    sw_p4b_clone_i2e := sw_p4b_clone_i2e || (1bv3 != 0bv3);
    sw_ig_md.ing_mir_ses := sw_mirror_id;
    sw_ig_md.pkt_type := 1bv8;
}

// sw_Table sw_SwitchIngress_release_lock_i2e_mirror_table
procedure {:inline 1} sw_SwitchIngress_release_lock_i2e_mirror_table.apply()
	modifies sw_SwitchIngress_release_lock_i2e_mirror_table.action_run, sw_SwitchIngress_release_lock_i2e_mirror_table.hit, sw_hdr.ipv4.dstAddr, sw_ig_intr_dprsr_md.mirror_type, sw_ig_md.clone_md, sw_ig_md.ing_mir_ses, sw_ig_md.pkt_type, sw_p4b_clone_i2e;
{
    sw_hdr.ipv4.dstAddr := sw_hdr.ipv4.dstAddr;
    sw_SwitchIngress_release_lock_i2e_mirror_table.hit := false;
    sw_SwitchIngress_release_lock_i2e_mirror_table.action_run := sw_SwitchIngress_release_lock_i2e_mirror_table.action.NoAction_11;
    call sw_NoAction_11();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_i2e_mirror_action:
    assume sw_SwitchIngress_release_lock_i2e_mirror_table.action_run == sw_SwitchIngress_release_lock_i2e_mirror_table.action.SwitchIngress_release_lock_i2e_mirror_action;
    call sw_SwitchIngress_release_lock_i2e_mirror_action(sw_SwitchIngress_release_lock_i2e_mirror_table.SwitchIngress_release_lock_i2e_mirror_action.mirror_id);
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_inc_empty_slots_action
procedure {:inline 1} sw_SwitchIngress_release_lock_inc_empty_slots_action()
	modifies sw___ra_ret_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_val_SwitchIngress_release_lock_inc_empty_slots_alu, sw_ig_md.empty_slots_before_pop, sw_slots_two_sides_register, sw_slots_two_sides_register__last0_old_value, sw_slots_two_sides_register__last0_value, sw_slots_two_sides_register__last_index, sw_slots_two_sides_register__last_old_value, sw_slots_two_sides_register__last_value, sw_slots_two_sides_register__last_write_site, sw_slots_two_sides_register__next_write_site, sw_slots_two_sides_register__wrote_any, sw_slots_two_sides_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_release_lock_inc_empty_slots_alu := sw_slots_two_sides_register.read(sw_slots_two_sides_register, sw_ig_md.lock_id);
    call sw___ra_val_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_ret_SwitchIngress_release_lock_inc_empty_slots_alu := sw_SwitchIngress_release_lock_inc_empty_slots_alu.apply(sw___ra_val_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_ret_SwitchIngress_release_lock_inc_empty_slots_alu);
    sw_slots_two_sides_register__next_write_site := 3;
    call sw_slots_two_sides_register.write(sw_ig_md.lock_id, sw___ra_val_SwitchIngress_release_lock_inc_empty_slots_alu);
    sw_ig_md.empty_slots_before_pop := sw___ra_ret_SwitchIngress_release_lock_inc_empty_slots_alu;
}

// sw_RegisterAction sw_SwitchIngress_release_lock_inc_empty_slots_alu.apply
procedure {:inline 1} sw_SwitchIngress_release_lock_inc_empty_slots_alu.apply(sw_value_in:sw_pair, sw_result_in:bv32) returns (sw_value_out:sw_pair, sw_result_out:bv32)
{
    var sw_value:sw_pair;
    var sw_result:bv32;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    sw_result := sw_value[64:32];
    if(bule.bv32(sw_value[64:32], sw_ig_md.size_of_queue)){
        sw_value := add.bv32(sw_value[64:32], 1bv32)++sw_value[32:0];
    }
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Table sw_SwitchIngress_release_lock_inc_empty_slots_table
procedure {:inline 1} sw_SwitchIngress_release_lock_inc_empty_slots_table.apply()
	modifies sw_SwitchIngress_release_lock_inc_empty_slots_table.action_run, sw_SwitchIngress_release_lock_inc_empty_slots_table.hit, sw___ra_ret_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_val_SwitchIngress_release_lock_inc_empty_slots_alu, sw_ig_md.empty_slots_before_pop, sw_slots_two_sides_register, sw_slots_two_sides_register__last0_old_value, sw_slots_two_sides_register__last0_value, sw_slots_two_sides_register__last_index, sw_slots_two_sides_register__last_old_value, sw_slots_two_sides_register__last_value, sw_slots_two_sides_register__last_write_site, sw_slots_two_sides_register__next_write_site, sw_slots_two_sides_register__wrote_any, sw_slots_two_sides_register__wrote_index0;
{
    sw_SwitchIngress_release_lock_inc_empty_slots_table.hit := false;
    sw_SwitchIngress_release_lock_inc_empty_slots_table.action_run := sw_SwitchIngress_release_lock_inc_empty_slots_table.action.SwitchIngress_release_lock_inc_empty_slots_action;
    call sw_SwitchIngress_release_lock_inc_empty_slots_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_inc_empty_slots_action:
    assume sw_SwitchIngress_release_lock_inc_empty_slots_table.action_run == sw_SwitchIngress_release_lock_inc_empty_slots_table.action.SwitchIngress_release_lock_inc_empty_slots_action;
    call sw_SwitchIngress_release_lock_inc_empty_slots_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_mark_to_resubmit_2_action
procedure {:inline 1} sw_SwitchIngress_release_lock_mark_to_resubmit_2_action()
	modifies sw_hdr.nlk_hdr.recirc_flag, sw_ig_md.do_resubmit;
{
    sw_hdr.nlk_hdr.recirc_flag := 2bv8;
    sw_ig_md.do_resubmit := 1bv1;
}

// sw_Table sw_SwitchIngress_release_lock_mark_to_resubmit_2_table
procedure {:inline 1} sw_SwitchIngress_release_lock_mark_to_resubmit_2_table.apply()
	modifies sw_SwitchIngress_release_lock_mark_to_resubmit_2_table.action_run, sw_SwitchIngress_release_lock_mark_to_resubmit_2_table.hit, sw_hdr.nlk_hdr.recirc_flag, sw_ig_md.do_resubmit;
{
    sw_SwitchIngress_release_lock_mark_to_resubmit_2_table.hit := false;
    sw_SwitchIngress_release_lock_mark_to_resubmit_2_table.action_run := sw_SwitchIngress_release_lock_mark_to_resubmit_2_table.action.SwitchIngress_release_lock_mark_to_resubmit_2_action;
    call sw_SwitchIngress_release_lock_mark_to_resubmit_2_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_mark_to_resubmit_2_action:
    assume sw_SwitchIngress_release_lock_mark_to_resubmit_2_table.action_run == sw_SwitchIngress_release_lock_mark_to_resubmit_2_table.action.SwitchIngress_release_lock_mark_to_resubmit_2_action;
    call sw_SwitchIngress_release_lock_mark_to_resubmit_2_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_mark_to_resubmit_action
procedure {:inline 1} sw_SwitchIngress_release_lock_mark_to_resubmit_action()
	modifies sw_hdr.nlk_hdr.recirc_flag, sw_hdr.recirculate_hdr.dequeued_mode, sw_ig_md.do_resubmit, sw_p4b_recirculate;
{
    sw_hdr.nlk_hdr.recirc_flag := 1bv8;
    sw_p4b_recirculate := true;
    sw_hdr.recirculate_hdr.dequeued_mode := sw_ig_md.mode;
    sw_ig_md.do_resubmit := 1bv1;
}

// sw_Table sw_SwitchIngress_release_lock_mark_to_resubmit_table
procedure {:inline 1} sw_SwitchIngress_release_lock_mark_to_resubmit_table.apply()
	modifies sw_SwitchIngress_release_lock_mark_to_resubmit_table.action_run, sw_SwitchIngress_release_lock_mark_to_resubmit_table.hit, sw_hdr.nlk_hdr.recirc_flag, sw_hdr.recirculate_hdr.dequeued_mode, sw_ig_md.do_resubmit, sw_p4b_recirculate;
{
    sw_SwitchIngress_release_lock_mark_to_resubmit_table.hit := false;
    sw_SwitchIngress_release_lock_mark_to_resubmit_table.action_run := sw_SwitchIngress_release_lock_mark_to_resubmit_table.action.SwitchIngress_release_lock_mark_to_resubmit_action;
    call sw_SwitchIngress_release_lock_mark_to_resubmit_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_mark_to_resubmit_action:
    assume sw_SwitchIngress_release_lock_mark_to_resubmit_table.action_run == sw_SwitchIngress_release_lock_mark_to_resubmit_table.action.SwitchIngress_release_lock_mark_to_resubmit_action;
    call sw_SwitchIngress_release_lock_mark_to_resubmit_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_metahead_plus_1_action
procedure {:inline 1} sw_SwitchIngress_release_lock_metahead_plus_1_action()
	modifies sw_ig_md.head;
{
    sw_ig_md.head := sw_ig_md.left;
}

// sw_Table sw_SwitchIngress_release_lock_metahead_plus_1_table
procedure {:inline 1} sw_SwitchIngress_release_lock_metahead_plus_1_table.apply()
	modifies sw_SwitchIngress_release_lock_metahead_plus_1_table.action_run, sw_SwitchIngress_release_lock_metahead_plus_1_table.hit, sw_ig_md.head;
{
    sw_SwitchIngress_release_lock_metahead_plus_1_table.hit := false;
    sw_SwitchIngress_release_lock_metahead_plus_1_table.action_run := sw_SwitchIngress_release_lock_metahead_plus_1_table.action.SwitchIngress_release_lock_metahead_plus_1_action;
    call sw_SwitchIngress_release_lock_metahead_plus_1_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_metahead_plus_1_action:
    assume sw_SwitchIngress_release_lock_metahead_plus_1_table.action_run == sw_SwitchIngress_release_lock_metahead_plus_1_table.action.SwitchIngress_release_lock_metahead_plus_1_action;
    call sw_SwitchIngress_release_lock_metahead_plus_1_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_metahead_plus_2_action
procedure {:inline 1} sw_SwitchIngress_release_lock_metahead_plus_2_action()
	modifies sw_ig_md.head;
{
    sw_ig_md.head := add.bv32(sw_ig_md.head, 1bv32);
}

// sw_Table sw_SwitchIngress_release_lock_metahead_plus_2_table
procedure {:inline 1} sw_SwitchIngress_release_lock_metahead_plus_2_table.apply()
	modifies sw_SwitchIngress_release_lock_metahead_plus_2_table.action_run, sw_SwitchIngress_release_lock_metahead_plus_2_table.hit, sw_ig_md.head;
{
    sw_SwitchIngress_release_lock_metahead_plus_2_table.hit := false;
    sw_SwitchIngress_release_lock_metahead_plus_2_table.action_run := sw_SwitchIngress_release_lock_metahead_plus_2_table.action.SwitchIngress_release_lock_metahead_plus_2_action;
    call sw_SwitchIngress_release_lock_metahead_plus_2_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_metahead_plus_2_action:
    assume sw_SwitchIngress_release_lock_metahead_plus_2_table.action_run == sw_SwitchIngress_release_lock_metahead_plus_2_table.action.SwitchIngress_release_lock_metahead_plus_2_action;
    call sw_SwitchIngress_release_lock_metahead_plus_2_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_notify_head_client_action
procedure {:inline 1} sw_SwitchIngress_release_lock_notify_head_client_action()
	modifies sw_hdr.ipv4.dstAddr;
{
    sw_hdr.ipv4.dstAddr := sw_ig_md.ip_address;
}

// sw_Table sw_SwitchIngress_release_lock_notify_head_client_table
procedure {:inline 1} sw_SwitchIngress_release_lock_notify_head_client_table.apply()
	modifies sw_SwitchIngress_release_lock_notify_head_client_table.action_run, sw_SwitchIngress_release_lock_notify_head_client_table.hit, sw_hdr.ipv4.dstAddr;
{
    sw_SwitchIngress_release_lock_notify_head_client_table.hit := false;
    sw_SwitchIngress_release_lock_notify_head_client_table.action_run := sw_SwitchIngress_release_lock_notify_head_client_table.action.SwitchIngress_release_lock_notify_head_client_action;
    call sw_SwitchIngress_release_lock_notify_head_client_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_notify_head_client_action:
    assume sw_SwitchIngress_release_lock_notify_head_client_table.action_run == sw_SwitchIngress_release_lock_notify_head_client_table.action.SwitchIngress_release_lock_notify_head_client_action;
    call sw_SwitchIngress_release_lock_notify_head_client_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_resubmit_action
procedure {:inline 1} sw_SwitchIngress_release_lock_resubmit_action()
	modifies sw_hdr.recirculate_hdr.cur_head, sw_hdr.recirculate_hdr.cur_tail, sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.recirced;
{
    sw_ig_md.recirced := 1bv2;
    sw_hdr.recirculate_hdr.cur_tail := sw_ig_md.tail;
    sw_hdr.recirculate_hdr.cur_head := sw_ig_md.head;
    sw_ig_intr_tm_md.ucast_egress_port := 68bv9;
    sw_ig_intr_tm_md.bypass_egress := 1bv1;
}

// sw_Table sw_SwitchIngress_release_lock_resubmit_table
procedure {:inline 1} sw_SwitchIngress_release_lock_resubmit_table.apply()
	modifies sw_SwitchIngress_release_lock_resubmit_table.action_run, sw_SwitchIngress_release_lock_resubmit_table.hit, sw_hdr.recirculate_hdr.cur_head, sw_hdr.recirculate_hdr.cur_tail, sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.recirced;
{
    sw_SwitchIngress_release_lock_resubmit_table.hit := false;
    sw_SwitchIngress_release_lock_resubmit_table.action_run := sw_SwitchIngress_release_lock_resubmit_table.action.SwitchIngress_release_lock_resubmit_action;
    call sw_SwitchIngress_release_lock_resubmit_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_resubmit_action:
    assume sw_SwitchIngress_release_lock_resubmit_table.action_run == sw_SwitchIngress_release_lock_resubmit_table.action.SwitchIngress_release_lock_resubmit_action;
    call sw_SwitchIngress_release_lock_resubmit_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_set_as_failure_notification_action
procedure {:inline 1} sw_SwitchIngress_release_lock_set_as_failure_notification_action()
	modifies sw_hdr.ethernet.dstAddr;
{
    sw_hdr.ethernet.dstAddr := 3bv48;
}

// sw_Action sw_SwitchIngress_release_lock_set_as_primary_action
procedure {:inline 1} sw_SwitchIngress_release_lock_set_as_primary_action()
	modifies sw_hdr.ethernet.dstAddr;
{
    sw_hdr.ethernet.dstAddr := 1bv48;
}

// sw_Action sw_SwitchIngress_release_lock_set_as_secondary_action
procedure {:inline 1} sw_SwitchIngress_release_lock_set_as_secondary_action()
	modifies sw_hdr.ethernet.dstAddr;
{
    sw_hdr.ethernet.dstAddr := 2bv48;
}

// sw_Table sw_SwitchIngress_release_lock_set_tag_table
procedure {:inline 1} sw_SwitchIngress_release_lock_set_tag_table.apply()
	modifies sw_SwitchIngress_release_lock_set_tag_table.action_run, sw_SwitchIngress_release_lock_set_tag_table.hit, sw_hdr.ethernet.dstAddr, sw_ig_md.failure_status, sw_ig_md.lock_exist;
{
    sw_ig_md.failure_status := sw_ig_md.failure_status;
    sw_ig_md.lock_exist := sw_ig_md.lock_exist;
    sw_SwitchIngress_release_lock_set_tag_table.hit := false;
    sw_SwitchIngress_release_lock_set_tag_table.action_run := sw_SwitchIngress_release_lock_set_tag_table.action.NoAction_9;
    call sw_NoAction_9();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_set_as_primary_action:
    assume sw_SwitchIngress_release_lock_set_tag_table.action_run == sw_SwitchIngress_release_lock_set_tag_table.action.SwitchIngress_release_lock_set_as_primary_action;
    call sw_SwitchIngress_release_lock_set_as_primary_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_set_as_secondary_action:
    assume sw_SwitchIngress_release_lock_set_tag_table.action_run == sw_SwitchIngress_release_lock_set_tag_table.action.SwitchIngress_release_lock_set_as_secondary_action;
    call sw_SwitchIngress_release_lock_set_as_secondary_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_set_as_failure_notification_action:
    assume sw_SwitchIngress_release_lock_set_tag_table.action_run == sw_SwitchIngress_release_lock_set_tag_table.action.SwitchIngress_release_lock_set_as_failure_notification_action;
    call sw_SwitchIngress_release_lock_set_as_failure_notification_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_update_head_action
procedure {:inline 1} sw_SwitchIngress_release_lock_update_head_action()
	modifies sw___ra_ret_SwitchIngress_release_lock_update_head_alu, sw___ra_val_SwitchIngress_release_lock_update_head_alu, sw_head_register, sw_head_register__last0_old_value, sw_head_register__last0_value, sw_head_register__last_index, sw_head_register__last_old_value, sw_head_register__last_value, sw_head_register__last_write_site, sw_head_register__next_write_site, sw_head_register__wrote_any, sw_head_register__wrote_index0, sw_ig_md.head;
{
    sw___ra_val_SwitchIngress_release_lock_update_head_alu := sw_head_register.read(sw_head_register, sw_ig_md.lock_id);
    call sw___ra_val_SwitchIngress_release_lock_update_head_alu, sw___ra_ret_SwitchIngress_release_lock_update_head_alu := sw_SwitchIngress_release_lock_update_head_alu.apply(sw___ra_val_SwitchIngress_release_lock_update_head_alu, sw___ra_ret_SwitchIngress_release_lock_update_head_alu);
    sw_head_register__next_write_site := 1;
    call sw_head_register.write(sw_ig_md.lock_id, sw___ra_val_SwitchIngress_release_lock_update_head_alu);
    sw_ig_md.head := sw___ra_ret_SwitchIngress_release_lock_update_head_alu;
}

// sw_RegisterAction sw_SwitchIngress_release_lock_update_head_alu.apply
procedure {:inline 1} sw_SwitchIngress_release_lock_update_head_alu.apply(sw_value_in:bv32, sw_result_in:bv32) returns (sw_value_out:bv32, sw_result_out:bv32)
{
    var sw_value:bv32;
    var sw_result:bv32;
    sw_value := sw_value_in;
    sw_result := sw_result_in;
    if((sw_value == sw_ig_md.right)){
        sw_value := sw_ig_md.left;
        sw_result := sw_value;
    }
    else{
        sw_value := add.bv32(sw_value, 1bv32);
        sw_result := sw_value;
    }
    sw_value_out := sw_value;
    sw_result_out := sw_result;
}

// sw_Table sw_SwitchIngress_release_lock_update_head_table
procedure {:inline 1} sw_SwitchIngress_release_lock_update_head_table.apply()
	modifies sw_SwitchIngress_release_lock_update_head_table.action_run, sw_SwitchIngress_release_lock_update_head_table.hit, sw___ra_ret_SwitchIngress_release_lock_update_head_alu, sw___ra_val_SwitchIngress_release_lock_update_head_alu, sw_head_register, sw_head_register__last0_old_value, sw_head_register__last0_value, sw_head_register__last_index, sw_head_register__last_old_value, sw_head_register__last_value, sw_head_register__last_write_site, sw_head_register__next_write_site, sw_head_register__wrote_any, sw_head_register__wrote_index0, sw_ig_md.head;
{
    sw_SwitchIngress_release_lock_update_head_table.hit := false;
    sw_SwitchIngress_release_lock_update_head_table.action_run := sw_SwitchIngress_release_lock_update_head_table.action.SwitchIngress_release_lock_update_head_action;
    call sw_SwitchIngress_release_lock_update_head_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_update_head_action:
    assume sw_SwitchIngress_release_lock_update_head_table.action_run == sw_SwitchIngress_release_lock_update_head_table.action.SwitchIngress_release_lock_update_head_action;
    call sw_SwitchIngress_release_lock_update_head_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_release_lock_update_lock_action
procedure {:inline 1} sw_SwitchIngress_release_lock_update_lock_action()
	modifies sw___ra_ret_SwitchIngress_release_lock_update_lock_alu, sw___ra_val_SwitchIngress_release_lock_update_lock_alu, sw_shared_and_exclusive_count_register, sw_shared_and_exclusive_count_register__last0_old_value, sw_shared_and_exclusive_count_register__last0_value, sw_shared_and_exclusive_count_register__last_index, sw_shared_and_exclusive_count_register__last_old_value, sw_shared_and_exclusive_count_register__last_value, sw_shared_and_exclusive_count_register__last_write_site, sw_shared_and_exclusive_count_register__next_write_site, sw_shared_and_exclusive_count_register__wrote_any, sw_shared_and_exclusive_count_register__wrote_index0;
{
    sw___ra_val_SwitchIngress_release_lock_update_lock_alu := sw_shared_and_exclusive_count_register.read(sw_shared_and_exclusive_count_register, sw_ig_md.lock_id);
    call sw___ra_val_SwitchIngress_release_lock_update_lock_alu := sw_SwitchIngress_release_lock_update_lock_alu.apply(sw___ra_val_SwitchIngress_release_lock_update_lock_alu);
    sw___ra_ret_SwitchIngress_release_lock_update_lock_alu := sw___ra_val_SwitchIngress_release_lock_update_lock_alu;
    sw_shared_and_exclusive_count_register__next_write_site := 3;
    call sw_shared_and_exclusive_count_register.write(sw_ig_md.lock_id, sw___ra_val_SwitchIngress_release_lock_update_lock_alu);
}

// sw_RegisterAction sw_SwitchIngress_release_lock_update_lock_alu.apply
procedure {:inline 1} sw_SwitchIngress_release_lock_update_lock_alu.apply(sw_value_in:sw_pair) returns (sw_value_out:sw_pair)
{
    var sw_value:sw_pair;
    sw_value := sw_value_in;
    if((sw_hdr.nlk_hdr.mode == 1bv8)){
        sw_value := add.bv32(sw_value[64:32], 4294967295bv32)++sw_value[32:0];
    }
    else{
        if((sw_hdr.nlk_hdr.mode == 0bv8)){
            sw_value := sw_value[64:32]++add.bv32(sw_value[32:0], 4294967295bv32);
        }
    }
    sw_value_out := sw_value;
}

// sw_Table sw_SwitchIngress_release_lock_update_lock_table
procedure {:inline 1} sw_SwitchIngress_release_lock_update_lock_table.apply()
	modifies sw_SwitchIngress_release_lock_update_lock_table.action_run, sw_SwitchIngress_release_lock_update_lock_table.hit, sw___ra_ret_SwitchIngress_release_lock_update_lock_alu, sw___ra_val_SwitchIngress_release_lock_update_lock_alu, sw_shared_and_exclusive_count_register, sw_shared_and_exclusive_count_register__last0_old_value, sw_shared_and_exclusive_count_register__last0_value, sw_shared_and_exclusive_count_register__last_index, sw_shared_and_exclusive_count_register__last_old_value, sw_shared_and_exclusive_count_register__last_value, sw_shared_and_exclusive_count_register__last_write_site, sw_shared_and_exclusive_count_register__next_write_site, sw_shared_and_exclusive_count_register__wrote_any, sw_shared_and_exclusive_count_register__wrote_index0;
{
    sw_SwitchIngress_release_lock_update_lock_table.hit := false;
    sw_SwitchIngress_release_lock_update_lock_table.action_run := sw_SwitchIngress_release_lock_update_lock_table.action.SwitchIngress_release_lock_update_lock_action;
    call sw_SwitchIngress_release_lock_update_lock_action();
    goto sw_Exit;

    sw_action_SwitchIngress_release_lock_update_lock_action:
    assume sw_SwitchIngress_release_lock_update_lock_table.action_run == sw_SwitchIngress_release_lock_update_lock_table.action.SwitchIngress_release_lock_update_lock_action;
    call sw_SwitchIngress_release_lock_update_lock_action();
    goto sw_Exit;

    sw_Exit:
}

// sw_Action sw_SwitchIngress_set_as_failure_notification_action
procedure {:inline 1} sw_SwitchIngress_set_as_failure_notification_action()
	modifies sw_hdr.ethernet.dstAddr;
{
    sw_hdr.ethernet.dstAddr := 3bv48;
}

// sw_Action sw_SwitchIngress_set_as_primary_action
procedure {:inline 1} sw_SwitchIngress_set_as_primary_action()
	modifies sw_hdr.ethernet.dstAddr;
{
    sw_hdr.ethernet.dstAddr := 1bv48;
}

// sw_Action sw_SwitchIngress_set_as_secondary_action
procedure {:inline 1} sw_SwitchIngress_set_as_secondary_action()
	modifies sw_hdr.ethernet.dstAddr;
{
    sw_hdr.ethernet.dstAddr := 2bv48;
}

// sw_Action sw_SwitchIngress_set_egress
procedure {:inline 1} sw_SwitchIngress_set_egress(sw_egress_spec:sw_PortId_t)
	modifies sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.routed;
{
    sw_ig_intr_tm_md.ucast_egress_port := sw_egress_spec;
    sw_ig_intr_tm_md.bypass_egress := 1bv1;
    sw_ig_md.routed := 1bv1;
}

// sw_Table sw_SwitchIngress_set_tag_table
procedure {:inline 1} sw_SwitchIngress_set_tag_table.apply()
	modifies sw_SwitchIngress_set_tag_table.action_run, sw_SwitchIngress_set_tag_table.hit, sw_hdr.ethernet.dstAddr, sw_ig_md.failure_status, sw_ig_md.lock_exist;
{
    sw_ig_md.failure_status := sw_ig_md.failure_status;
    sw_ig_md.lock_exist := sw_ig_md.lock_exist;
    sw_SwitchIngress_set_tag_table.hit := false;
    sw_SwitchIngress_set_tag_table.action_run := sw_SwitchIngress_set_tag_table.action.NoAction_14;
    call sw_NoAction_14();
    goto sw_Exit;

    sw_action_SwitchIngress_set_as_primary_action:
    assume sw_SwitchIngress_set_tag_table.action_run == sw_SwitchIngress_set_tag_table.action.SwitchIngress_set_as_primary_action;
    call sw_SwitchIngress_set_as_primary_action();
    goto sw_Exit;

    sw_action_SwitchIngress_set_as_secondary_action:
    assume sw_SwitchIngress_set_tag_table.action_run == sw_SwitchIngress_set_tag_table.action.SwitchIngress_set_as_secondary_action;
    call sw_SwitchIngress_set_as_secondary_action();
    goto sw_Exit;

    sw_action_SwitchIngress_set_as_failure_notification_action:
    assume sw_SwitchIngress_set_tag_table.action_run == sw_SwitchIngress_set_tag_table.action.SwitchIngress_set_as_failure_notification_action;
    call sw_SwitchIngress_set_as_failure_notification_action();
    goto sw_Exit;

    sw_Exit:
}
procedure {:inline 1} sw_accept()
{
}
function {:inline true}sw_client_id_array_register.read(sw_reg:[bv32]bv8, sw_index:bv32)returns (bv8) {sw_reg[sw_index]}
procedure {:inline 1} sw_client_id_array_register.write(sw_index:bv32, sw_value:bv8)
	modifies sw_client_id_array_register, sw_client_id_array_register__last0_old_value, sw_client_id_array_register__last0_value, sw_client_id_array_register__last_index, sw_client_id_array_register__last_old_value, sw_client_id_array_register__last_value, sw_client_id_array_register__last_write_site, sw_client_id_array_register__wrote_any, sw_client_id_array_register__wrote_index0;
{
    sw_client_id_array_register__last_old_value := sw_client_id_array_register[sw_index];
    sw_client_id_array_register[sw_index] := sw_value;
    sw_client_id_array_register__last_index := sw_index;
    sw_client_id_array_register__last_value := sw_value;
    sw_client_id_array_register__last_write_site := sw_client_id_array_register__next_write_site;
    sw_client_id_array_register__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_client_id_array_register__wrote_index0 := true;
        sw_client_id_array_register__last0_old_value := sw_client_id_array_register__last_old_value;
        sw_client_id_array_register__last0_value := sw_value;
    }
}

// sw_Action sw_drop_0
procedure {:inline 1} sw_drop_0()
	modifies sw_ig_intr_dprsr_md.drop_ctl;
{
    sw_ig_intr_dprsr_md.drop_ctl := 1bv3;
}

// sw_Action sw_drop_1
procedure {:inline 1} sw_drop_1()
	modifies sw_ig_intr_dprsr_md.drop_ctl;
{
    sw_ig_intr_dprsr_md.drop_ctl := 1bv3;
}
function {:inline true}sw_failure_status_register.read(sw_reg:[bv1]bv8, sw_index:bv1)returns (bv8) {sw_reg[sw_index]}
procedure {:inline 1} sw_failure_status_register.write(sw_index:bv1, sw_value:bv8)
	modifies sw_failure_status_register, sw_failure_status_register__last0_old_value, sw_failure_status_register__last0_value, sw_failure_status_register__last_index, sw_failure_status_register__last_old_value, sw_failure_status_register__last_value, sw_failure_status_register__last_write_site, sw_failure_status_register__wrote_any, sw_failure_status_register__wrote_index0;
{
    sw_failure_status_register__last_old_value := sw_failure_status_register[sw_index];
    sw_failure_status_register[sw_index] := sw_value;
    sw_failure_status_register__last_index := sw_index;
    sw_failure_status_register__last_value := sw_value;
    sw_failure_status_register__last_write_site := sw_failure_status_register__next_write_site;
    sw_failure_status_register__wrote_any := true;
    if (sw_index == 0bv1) {
        sw_failure_status_register__wrote_index0 := true;
        sw_failure_status_register__last0_old_value := sw_failure_status_register__last_old_value;
        sw_failure_status_register__last0_value := sw_value;
    }
}
function {:inline true}sw_head_register.read(sw_reg:[bv32]bv32, sw_index:bv32)returns (bv32) {sw_reg[sw_index]}
procedure {:inline 1} sw_head_register.write(sw_index:bv32, sw_value:bv32)
	modifies sw_head_register, sw_head_register__last0_old_value, sw_head_register__last0_value, sw_head_register__last_index, sw_head_register__last_old_value, sw_head_register__last_value, sw_head_register__last_write_site, sw_head_register__wrote_any, sw_head_register__wrote_index0;
{
    sw_head_register__last_old_value := sw_head_register[sw_index];
    sw_head_register[sw_index] := sw_value;
    sw_head_register__last_index := sw_index;
    sw_head_register__last_value := sw_value;
    sw_head_register__last_write_site := sw_head_register__next_write_site;
    sw_head_register__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_head_register__wrote_index0 := true;
        sw_head_register__last0_old_value := sw_head_register__last_old_value;
        sw_head_register__last0_value := sw_value;
    }
}
function {:inline true}sw_ip_array_register.read(sw_reg:[bv32]bv32, sw_index:bv32)returns (bv32) {sw_reg[sw_index]}
procedure {:inline 1} sw_ip_array_register.write(sw_index:bv32, sw_value:bv32)
	modifies sw_ip_array_register, sw_ip_array_register__last0_old_value, sw_ip_array_register__last0_value, sw_ip_array_register__last_index, sw_ip_array_register__last_old_value, sw_ip_array_register__last_value, sw_ip_array_register__last_write_site, sw_ip_array_register__wrote_any, sw_ip_array_register__wrote_index0;
{
    sw_ip_array_register__last_old_value := sw_ip_array_register[sw_index];
    sw_ip_array_register[sw_index] := sw_value;
    sw_ip_array_register__last_index := sw_index;
    sw_ip_array_register__last_value := sw_value;
    sw_ip_array_register__last_write_site := sw_ip_array_register__next_write_site;
    sw_ip_array_register__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_ip_array_register__wrote_index0 := true;
        sw_ip_array_register__last0_old_value := sw_ip_array_register__last_old_value;
        sw_ip_array_register__last0_value := sw_value;
    }
}
function {:inline true}sw_left_bound_register.read(sw_reg:[bv32]bv32, sw_index:bv32)returns (bv32) {sw_reg[sw_index]}
procedure {:inline 1} sw_left_bound_register.write(sw_index:bv32, sw_value:bv32)
	modifies sw_left_bound_register, sw_left_bound_register__last0_old_value, sw_left_bound_register__last0_value, sw_left_bound_register__last_index, sw_left_bound_register__last_old_value, sw_left_bound_register__last_value, sw_left_bound_register__last_write_site, sw_left_bound_register__wrote_any, sw_left_bound_register__wrote_index0;
{
    sw_left_bound_register__last_old_value := sw_left_bound_register[sw_index];
    sw_left_bound_register[sw_index] := sw_value;
    sw_left_bound_register__last_index := sw_index;
    sw_left_bound_register__last_value := sw_value;
    sw_left_bound_register__last_write_site := sw_left_bound_register__next_write_site;
    sw_left_bound_register__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_left_bound_register__wrote_index0 := true;
        sw_left_bound_register__last0_old_value := sw_left_bound_register__last_old_value;
        sw_left_bound_register__last0_value := sw_value;
    }
}
procedure {:inline 1} sw_main()
	modifies sw_SwitchEgress_change_mode_table.action_run, sw_SwitchEgress_change_mode_table.hit, sw_SwitchEgress_change_op_type_table.action_run, sw_SwitchEgress_change_op_type_table.hit, sw_SwitchEgress_test_table.action_run, sw_SwitchEgress_test_table.hit, sw_SwitchIngress_acquire_lock_acquire_lock_table.action_run, sw_SwitchIngress_acquire_lock_acquire_lock_table.hit, sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action_run, sw_SwitchIngress_acquire_lock_dec_empty_slots_table.hit, sw_SwitchIngress_acquire_lock_drop_packet_table.action_run, sw_SwitchIngress_acquire_lock_drop_packet_table.hit, sw_SwitchIngress_acquire_lock_fix_src_port_table.action_run, sw_SwitchIngress_acquire_lock_fix_src_port_table.hit, sw_SwitchIngress_acquire_lock_forward_to_server_table.action_run, sw_SwitchIngress_acquire_lock_forward_to_server_table.hit, sw_SwitchIngress_acquire_lock_notify_tail_client_table.action_run, sw_SwitchIngress_acquire_lock_notify_tail_client_table.hit, sw_SwitchIngress_acquire_lock_set_tag_table.action_run, sw_SwitchIngress_acquire_lock_set_tag_table.hit, sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action_run, sw_SwitchIngress_acquire_lock_switch_direct_grant_table.hit, sw_SwitchIngress_acquire_lock_update_client_id_array_table.action_run, sw_SwitchIngress_acquire_lock_update_client_id_array_table.hit, sw_SwitchIngress_acquire_lock_update_ip_array_table.action_run, sw_SwitchIngress_acquire_lock_update_ip_array_table.hit, sw_SwitchIngress_acquire_lock_update_mode_array_table.action_run, sw_SwitchIngress_acquire_lock_update_mode_array_table.hit, sw_SwitchIngress_acquire_lock_update_tail_table.action_run, sw_SwitchIngress_acquire_lock_update_tail_table.hit, sw_SwitchIngress_acquire_lock_update_tid_array_table.action_run, sw_SwitchIngress_acquire_lock_update_tid_array_table.hit, sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action_run, sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.hit, sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action_run, sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.hit, sw_SwitchIngress_check_lock_exist_table.SwitchIngress_check_lock_exist_action.index_1, sw_SwitchIngress_check_lock_exist_table.action_run, sw_SwitchIngress_check_lock_exist_table.hit, sw_SwitchIngress_decode_decode_table.action_run, sw_SwitchIngress_decode_decode_table.hit, sw_SwitchIngress_decode_get_left_bound_table.action_run, sw_SwitchIngress_decode_get_left_bound_table.hit, sw_SwitchIngress_decode_get_right_bound_table.action_run, sw_SwitchIngress_decode_get_right_bound_table.hit, sw_SwitchIngress_decode_get_size_of_queue_table.action_run, sw_SwitchIngress_decode_get_size_of_queue_table.hit, sw_SwitchIngress_fix_src_port_table.action_run, sw_SwitchIngress_fix_src_port_table.hit, sw_SwitchIngress_forward_to_server_table.action_run, sw_SwitchIngress_forward_to_server_table.hit, sw_SwitchIngress_i2e_clone_table.action_run, sw_SwitchIngress_i2e_clone_table.hit, sw_SwitchIngress_ipv4_route_table.action_run, sw_SwitchIngress_ipv4_route_table.hit, sw_SwitchIngress_ipv4_route_table_2.action_run, sw_SwitchIngress_ipv4_route_table_2.hit, sw_SwitchIngress_release_lock_drop_packet_table.action_run, sw_SwitchIngress_release_lock_drop_packet_table.hit, sw_SwitchIngress_release_lock_fix_src_port_table.action_run, sw_SwitchIngress_release_lock_fix_src_port_table.hit, sw_SwitchIngress_release_lock_forward_to_server_table.action_run, sw_SwitchIngress_release_lock_forward_to_server_table.hit, sw_SwitchIngress_release_lock_get_client_id_table.action_run, sw_SwitchIngress_release_lock_get_client_id_table.hit, sw_SwitchIngress_release_lock_get_ip_table.action_run, sw_SwitchIngress_release_lock_get_ip_table.hit, sw_SwitchIngress_release_lock_get_mode_table.action_run, sw_SwitchIngress_release_lock_get_mode_table.hit, sw_SwitchIngress_release_lock_get_recirc_info_table.action_run, sw_SwitchIngress_release_lock_get_recirc_info_table.hit, sw_SwitchIngress_release_lock_get_tail_table.action_run, sw_SwitchIngress_release_lock_get_tail_table.hit, sw_SwitchIngress_release_lock_get_tid_table.action_run, sw_SwitchIngress_release_lock_get_tid_table.hit, sw_SwitchIngress_release_lock_get_timestamp_hi_table.action_run, sw_SwitchIngress_release_lock_get_timestamp_hi_table.hit, sw_SwitchIngress_release_lock_get_timestamp_lo_table.action_run, sw_SwitchIngress_release_lock_get_timestamp_lo_table.hit, sw_SwitchIngress_release_lock_i2e_mirror_table.action_run, sw_SwitchIngress_release_lock_i2e_mirror_table.hit, sw_SwitchIngress_release_lock_inc_empty_slots_table.action_run, sw_SwitchIngress_release_lock_inc_empty_slots_table.hit, sw_SwitchIngress_release_lock_metahead_plus_1_table.action_run, sw_SwitchIngress_release_lock_metahead_plus_1_table.hit, sw_SwitchIngress_release_lock_metahead_plus_2_table.action_run, sw_SwitchIngress_release_lock_metahead_plus_2_table.hit, sw_SwitchIngress_release_lock_notify_head_client_table.action_run, sw_SwitchIngress_release_lock_notify_head_client_table.hit, sw_SwitchIngress_release_lock_set_tag_table.action_run, sw_SwitchIngress_release_lock_set_tag_table.hit, sw_SwitchIngress_release_lock_update_head_table.action_run, sw_SwitchIngress_release_lock_update_head_table.hit, sw_SwitchIngress_release_lock_update_lock_table.action_run, sw_SwitchIngress_release_lock_update_lock_table.hit, sw_SwitchIngress_set_tag_table.action_run, sw_SwitchIngress_set_tag_table.hit, sw___ra_ret_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_ret_SwitchIngress_acquire_lock_push_back_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_client_id_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_ip_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_mode_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_tid_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw___ra_ret_SwitchIngress_decode_get_left_bound_alu, sw___ra_ret_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_ret_SwitchIngress_decode_get_right_bound_alu, sw___ra_ret_SwitchIngress_release_lock_get_client_id_alu, sw___ra_ret_SwitchIngress_release_lock_get_ip_alu, sw___ra_ret_SwitchIngress_release_lock_get_mode_alu, sw___ra_ret_SwitchIngress_release_lock_get_tail_alu, sw___ra_ret_SwitchIngress_release_lock_get_tid_alu, sw___ra_ret_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_ret_SwitchIngress_release_lock_update_head_alu, sw___ra_ret_SwitchIngress_release_lock_update_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_val_SwitchIngress_acquire_lock_push_back_alu, sw___ra_val_SwitchIngress_acquire_lock_update_client_id_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_ip_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_mode_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tid_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw___ra_val_SwitchIngress_decode_get_left_bound_alu, sw___ra_val_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_val_SwitchIngress_decode_get_right_bound_alu, sw___ra_val_SwitchIngress_release_lock_get_client_id_alu, sw___ra_val_SwitchIngress_release_lock_get_ip_alu, sw___ra_val_SwitchIngress_release_lock_get_mode_alu, sw___ra_val_SwitchIngress_release_lock_get_tail_alu, sw___ra_val_SwitchIngress_release_lock_get_tid_alu, sw___ra_val_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_val_SwitchIngress_release_lock_update_head_alu, sw___ra_val_SwitchIngress_release_lock_update_lock_alu, sw_client_id_array_register, sw_client_id_array_register__last0_old_value, sw_client_id_array_register__last0_value, sw_client_id_array_register__last_index, sw_client_id_array_register__last_old_value, sw_client_id_array_register__last_value, sw_client_id_array_register__last_write_site, sw_client_id_array_register__next_write_site, sw_client_id_array_register__wrote_any, sw_client_id_array_register__wrote_index0, sw_drop, sw_eg_md.client_id, sw_eg_md.clone_md, sw_eg_md.ip_address, sw_eg_md.mode, sw_eg_md.tid, sw_eg_md.timestamp_hi, sw_eg_md.timestamp_lo, sw_hdr.ethernet.dstAddr, sw_hdr.ethernet.srcAddr, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.srcAddr, sw_hdr.nlk_hdr.client_id, sw_hdr.nlk_hdr.empty_slots, sw_hdr.nlk_hdr.head, sw_hdr.nlk_hdr.lock, sw_hdr.nlk_hdr.mode, sw_hdr.nlk_hdr.op, sw_hdr.nlk_hdr.recirc_flag, sw_hdr.nlk_hdr.tail, sw_hdr.nlk_hdr.tid, sw_hdr.udp.dstPort, sw_hdr.udp.srcPort, sw_head_register, sw_head_register__last0_old_value, sw_head_register__last0_value, sw_head_register__last_index, sw_head_register__last_old_value, sw_head_register__last_value, sw_head_register__last_write_site, sw_head_register__next_write_site, sw_head_register__wrote_any, sw_head_register__wrote_index0, sw_ig_intr_dprsr_md.drop_ctl, sw_ig_intr_dprsr_md.mirror_type, sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.client_id, sw_ig_md.clone_md, sw_ig_md.dequeued_mode, sw_ig_md.empty_slots, sw_ig_md.empty_slots_before_pop, sw_ig_md.failure_status, sw_ig_md.head, sw_ig_md.ing_mir_ses, sw_ig_md.ip_address, sw_ig_md.left, sw_ig_md.length_in_server, sw_ig_md.lock_exist, sw_ig_md.lock_id, sw_ig_md.locked, sw_ig_md.mode, sw_ig_md.pkt_type, sw_ig_md.queue_size_op, sw_ig_md.recirc_flag, sw_ig_md.right, sw_ig_md.routed, sw_ig_md.size_of_queue, sw_ig_md.tail, sw_ig_md.tid, sw_ig_md.timestamp_hi, sw_ig_md.timestamp_lo, sw_ig_md.ts_hi, sw_ig_md.ts_lo, sw_ip_array_register, sw_ip_array_register__last0_old_value, sw_ip_array_register__last0_value, sw_ip_array_register__last_index, sw_ip_array_register__last_old_value, sw_ip_array_register__last_value, sw_ip_array_register__last_write_site, sw_ip_array_register__next_write_site, sw_ip_array_register__wrote_any, sw_ip_array_register__wrote_index0, sw_isValid, sw_left_bound_register, sw_left_bound_register__last0_old_value, sw_left_bound_register__last0_value, sw_left_bound_register__last_index, sw_left_bound_register__last_old_value, sw_left_bound_register__last_value, sw_left_bound_register__last_write_site, sw_left_bound_register__next_write_site, sw_left_bound_register__wrote_any, sw_left_bound_register__wrote_index0, sw_mirror_hdr_0, sw_mirror_md_0, sw_mode_array_register, sw_mode_array_register__last0_old_value, sw_mode_array_register__last0_value, sw_mode_array_register__last_index, sw_mode_array_register__last_old_value, sw_mode_array_register__last_value, sw_mode_array_register__last_write_site, sw_mode_array_register__next_write_site, sw_mode_array_register__wrote_any, sw_mode_array_register__wrote_index0, sw_p4b_clone_i2e, sw_p4b_recirculate, sw_queue_size_op_register, sw_queue_size_op_register__last0_old_value, sw_queue_size_op_register__last0_value, sw_queue_size_op_register__last_index, sw_queue_size_op_register__last_old_value, sw_queue_size_op_register__last_value, sw_queue_size_op_register__last_write_site, sw_queue_size_op_register__next_write_site, sw_queue_size_op_register__wrote_any, sw_queue_size_op_register__wrote_index0, sw_right_bound_register, sw_right_bound_register__last0_old_value, sw_right_bound_register__last0_value, sw_right_bound_register__last_index, sw_right_bound_register__last_old_value, sw_right_bound_register__last_value, sw_right_bound_register__last_write_site, sw_right_bound_register__next_write_site, sw_right_bound_register__wrote_any, sw_right_bound_register__wrote_index0, sw_shared_and_exclusive_count_register, sw_shared_and_exclusive_count_register__last0_old_value, sw_shared_and_exclusive_count_register__last0_value, sw_shared_and_exclusive_count_register__last_index, sw_shared_and_exclusive_count_register__last_old_value, sw_shared_and_exclusive_count_register__last_value, sw_shared_and_exclusive_count_register__last_write_site, sw_shared_and_exclusive_count_register__next_write_site, sw_shared_and_exclusive_count_register__wrote_any, sw_shared_and_exclusive_count_register__wrote_index0, sw_slots_two_sides_register, sw_slots_two_sides_register__last0_old_value, sw_slots_two_sides_register__last0_value, sw_slots_two_sides_register__last_index, sw_slots_two_sides_register__last_old_value, sw_slots_two_sides_register__last_value, sw_slots_two_sides_register__last_write_site, sw_slots_two_sides_register__next_write_site, sw_slots_two_sides_register__wrote_any, sw_slots_two_sides_register__wrote_index0, sw_tail_register, sw_tail_register__last0_old_value, sw_tail_register__last0_value, sw_tail_register__last_index, sw_tail_register__last_old_value, sw_tail_register__last_value, sw_tail_register__last_write_site, sw_tail_register__next_write_site, sw_tail_register__wrote_any, sw_tail_register__wrote_index0, sw_tid_array_register, sw_tid_array_register__last0_old_value, sw_tid_array_register__last0_value, sw_tid_array_register__last_index, sw_tid_array_register__last_old_value, sw_tid_array_register__last_value, sw_tid_array_register__last_write_site, sw_tid_array_register__next_write_site, sw_tid_array_register__wrote_any, sw_tid_array_register__wrote_index0, sw_timestamp_hi_array_register, sw_timestamp_hi_array_register__last0_old_value, sw_timestamp_hi_array_register__last0_value, sw_timestamp_hi_array_register__last_index, sw_timestamp_hi_array_register__last_old_value, sw_timestamp_hi_array_register__last_value, sw_timestamp_hi_array_register__last_write_site, sw_timestamp_hi_array_register__next_write_site, sw_timestamp_hi_array_register__wrote_any, sw_timestamp_hi_array_register__wrote_index0, sw_timestamp_lo_array_register, sw_timestamp_lo_array_register__last0_old_value, sw_timestamp_lo_array_register__last0_value, sw_timestamp_lo_array_register__last_index, sw_timestamp_lo_array_register__last_old_value, sw_timestamp_lo_array_register__last_value, sw_timestamp_lo_array_register__last_write_site, sw_timestamp_lo_array_register__next_write_site, sw_timestamp_lo_array_register__wrote_any, sw_timestamp_lo_array_register__wrote_index0, sw_tmp;
{
    call sw_pipe();
    if(sw_forward == false){
        sw_drop := true;
    }
}
procedure sw_mainProcedure()
	modifies sw_SwitchEgress_change_mode_table.action_run, sw_SwitchEgress_change_mode_table.hit, sw_SwitchEgress_change_op_type_table.action_run, sw_SwitchEgress_change_op_type_table.hit, sw_SwitchEgress_test_table.action_run, sw_SwitchEgress_test_table.hit, sw_SwitchIngress_acquire_lock_acquire_lock_table.action_run, sw_SwitchIngress_acquire_lock_acquire_lock_table.hit, sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action_run, sw_SwitchIngress_acquire_lock_dec_empty_slots_table.hit, sw_SwitchIngress_acquire_lock_drop_packet_table.action_run, sw_SwitchIngress_acquire_lock_drop_packet_table.hit, sw_SwitchIngress_acquire_lock_fix_src_port_table.action_run, sw_SwitchIngress_acquire_lock_fix_src_port_table.hit, sw_SwitchIngress_acquire_lock_forward_to_server_table.action_run, sw_SwitchIngress_acquire_lock_forward_to_server_table.hit, sw_SwitchIngress_acquire_lock_notify_tail_client_table.action_run, sw_SwitchIngress_acquire_lock_notify_tail_client_table.hit, sw_SwitchIngress_acquire_lock_set_tag_table.action_run, sw_SwitchIngress_acquire_lock_set_tag_table.hit, sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action_run, sw_SwitchIngress_acquire_lock_switch_direct_grant_table.hit, sw_SwitchIngress_acquire_lock_update_client_id_array_table.action_run, sw_SwitchIngress_acquire_lock_update_client_id_array_table.hit, sw_SwitchIngress_acquire_lock_update_ip_array_table.action_run, sw_SwitchIngress_acquire_lock_update_ip_array_table.hit, sw_SwitchIngress_acquire_lock_update_mode_array_table.action_run, sw_SwitchIngress_acquire_lock_update_mode_array_table.hit, sw_SwitchIngress_acquire_lock_update_tail_table.action_run, sw_SwitchIngress_acquire_lock_update_tail_table.hit, sw_SwitchIngress_acquire_lock_update_tid_array_table.action_run, sw_SwitchIngress_acquire_lock_update_tid_array_table.hit, sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action_run, sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.hit, sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action_run, sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.hit, sw_SwitchIngress_check_lock_exist_table.SwitchIngress_check_lock_exist_action.index_1, sw_SwitchIngress_check_lock_exist_table.action_run, sw_SwitchIngress_check_lock_exist_table.hit, sw_SwitchIngress_decode_decode_table.action_run, sw_SwitchIngress_decode_decode_table.hit, sw_SwitchIngress_decode_get_left_bound_table.action_run, sw_SwitchIngress_decode_get_left_bound_table.hit, sw_SwitchIngress_decode_get_right_bound_table.action_run, sw_SwitchIngress_decode_get_right_bound_table.hit, sw_SwitchIngress_decode_get_size_of_queue_table.action_run, sw_SwitchIngress_decode_get_size_of_queue_table.hit, sw_SwitchIngress_fix_src_port_table.action_run, sw_SwitchIngress_fix_src_port_table.hit, sw_SwitchIngress_forward_to_server_table.action_run, sw_SwitchIngress_forward_to_server_table.hit, sw_SwitchIngress_i2e_clone_table.action_run, sw_SwitchIngress_i2e_clone_table.hit, sw_SwitchIngress_ipv4_route_table.action_run, sw_SwitchIngress_ipv4_route_table.hit, sw_SwitchIngress_ipv4_route_table_2.action_run, sw_SwitchIngress_ipv4_route_table_2.hit, sw_SwitchIngress_release_lock_drop_packet_table.action_run, sw_SwitchIngress_release_lock_drop_packet_table.hit, sw_SwitchIngress_release_lock_fix_src_port_table.action_run, sw_SwitchIngress_release_lock_fix_src_port_table.hit, sw_SwitchIngress_release_lock_forward_to_server_table.action_run, sw_SwitchIngress_release_lock_forward_to_server_table.hit, sw_SwitchIngress_release_lock_get_client_id_table.action_run, sw_SwitchIngress_release_lock_get_client_id_table.hit, sw_SwitchIngress_release_lock_get_ip_table.action_run, sw_SwitchIngress_release_lock_get_ip_table.hit, sw_SwitchIngress_release_lock_get_mode_table.action_run, sw_SwitchIngress_release_lock_get_mode_table.hit, sw_SwitchIngress_release_lock_get_recirc_info_table.action_run, sw_SwitchIngress_release_lock_get_recirc_info_table.hit, sw_SwitchIngress_release_lock_get_tail_table.action_run, sw_SwitchIngress_release_lock_get_tail_table.hit, sw_SwitchIngress_release_lock_get_tid_table.action_run, sw_SwitchIngress_release_lock_get_tid_table.hit, sw_SwitchIngress_release_lock_get_timestamp_hi_table.action_run, sw_SwitchIngress_release_lock_get_timestamp_hi_table.hit, sw_SwitchIngress_release_lock_get_timestamp_lo_table.action_run, sw_SwitchIngress_release_lock_get_timestamp_lo_table.hit, sw_SwitchIngress_release_lock_i2e_mirror_table.action_run, sw_SwitchIngress_release_lock_i2e_mirror_table.hit, sw_SwitchIngress_release_lock_inc_empty_slots_table.action_run, sw_SwitchIngress_release_lock_inc_empty_slots_table.hit, sw_SwitchIngress_release_lock_metahead_plus_1_table.action_run, sw_SwitchIngress_release_lock_metahead_plus_1_table.hit, sw_SwitchIngress_release_lock_metahead_plus_2_table.action_run, sw_SwitchIngress_release_lock_metahead_plus_2_table.hit, sw_SwitchIngress_release_lock_notify_head_client_table.action_run, sw_SwitchIngress_release_lock_notify_head_client_table.hit, sw_SwitchIngress_release_lock_set_tag_table.action_run, sw_SwitchIngress_release_lock_set_tag_table.hit, sw_SwitchIngress_release_lock_update_head_table.action_run, sw_SwitchIngress_release_lock_update_head_table.hit, sw_SwitchIngress_release_lock_update_lock_table.action_run, sw_SwitchIngress_release_lock_update_lock_table.hit, sw_SwitchIngress_set_tag_table.action_run, sw_SwitchIngress_set_tag_table.hit, sw___ra_ret_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_ret_SwitchIngress_acquire_lock_push_back_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_client_id_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_ip_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_mode_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_tid_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw___ra_ret_SwitchIngress_decode_get_left_bound_alu, sw___ra_ret_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_ret_SwitchIngress_decode_get_right_bound_alu, sw___ra_ret_SwitchIngress_release_lock_get_client_id_alu, sw___ra_ret_SwitchIngress_release_lock_get_ip_alu, sw___ra_ret_SwitchIngress_release_lock_get_mode_alu, sw___ra_ret_SwitchIngress_release_lock_get_tail_alu, sw___ra_ret_SwitchIngress_release_lock_get_tid_alu, sw___ra_ret_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_ret_SwitchIngress_release_lock_update_head_alu, sw___ra_ret_SwitchIngress_release_lock_update_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_val_SwitchIngress_acquire_lock_push_back_alu, sw___ra_val_SwitchIngress_acquire_lock_update_client_id_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_ip_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_mode_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tid_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw___ra_val_SwitchIngress_decode_get_left_bound_alu, sw___ra_val_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_val_SwitchIngress_decode_get_right_bound_alu, sw___ra_val_SwitchIngress_release_lock_get_client_id_alu, sw___ra_val_SwitchIngress_release_lock_get_ip_alu, sw___ra_val_SwitchIngress_release_lock_get_mode_alu, sw___ra_val_SwitchIngress_release_lock_get_tail_alu, sw___ra_val_SwitchIngress_release_lock_get_tid_alu, sw___ra_val_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_val_SwitchIngress_release_lock_update_head_alu, sw___ra_val_SwitchIngress_release_lock_update_lock_alu, sw_client_id_array_register, sw_client_id_array_register__last0_old_value, sw_client_id_array_register__last0_value, sw_client_id_array_register__last_index, sw_client_id_array_register__last_old_value, sw_client_id_array_register__last_value, sw_client_id_array_register__last_write_site, sw_client_id_array_register__next_write_site, sw_client_id_array_register__wrote_any, sw_client_id_array_register__wrote_index0, sw_drop, sw_eg_md.client_id, sw_eg_md.clone_md, sw_eg_md.ip_address, sw_eg_md.mode, sw_eg_md.tid, sw_eg_md.timestamp_hi, sw_eg_md.timestamp_lo, sw_hdr.ethernet.dstAddr, sw_hdr.ethernet.srcAddr, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.srcAddr, sw_hdr.nlk_hdr.client_id, sw_hdr.nlk_hdr.empty_slots, sw_hdr.nlk_hdr.head, sw_hdr.nlk_hdr.lock, sw_hdr.nlk_hdr.mode, sw_hdr.nlk_hdr.op, sw_hdr.nlk_hdr.recirc_flag, sw_hdr.nlk_hdr.tail, sw_hdr.nlk_hdr.tid, sw_hdr.udp.dstPort, sw_hdr.udp.srcPort, sw_head_register, sw_head_register__last0_old_value, sw_head_register__last0_value, sw_head_register__last_index, sw_head_register__last_old_value, sw_head_register__last_value, sw_head_register__last_write_site, sw_head_register__next_write_site, sw_head_register__wrote_any, sw_head_register__wrote_index0, sw_ig_intr_dprsr_md.drop_ctl, sw_ig_intr_dprsr_md.mirror_type, sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.client_id, sw_ig_md.clone_md, sw_ig_md.dequeued_mode, sw_ig_md.empty_slots, sw_ig_md.empty_slots_before_pop, sw_ig_md.failure_status, sw_ig_md.head, sw_ig_md.ing_mir_ses, sw_ig_md.ip_address, sw_ig_md.left, sw_ig_md.length_in_server, sw_ig_md.lock_exist, sw_ig_md.lock_id, sw_ig_md.locked, sw_ig_md.mode, sw_ig_md.pkt_type, sw_ig_md.queue_size_op, sw_ig_md.recirc_flag, sw_ig_md.right, sw_ig_md.routed, sw_ig_md.size_of_queue, sw_ig_md.tail, sw_ig_md.tid, sw_ig_md.timestamp_hi, sw_ig_md.timestamp_lo, sw_ig_md.ts_hi, sw_ig_md.ts_lo, sw_ip_array_register, sw_ip_array_register__last0_old_value, sw_ip_array_register__last0_value, sw_ip_array_register__last_index, sw_ip_array_register__last_old_value, sw_ip_array_register__last_value, sw_ip_array_register__last_write_site, sw_ip_array_register__next_write_site, sw_ip_array_register__wrote_any, sw_ip_array_register__wrote_index0, sw_isValid, sw_left_bound_register, sw_left_bound_register__last0_old_value, sw_left_bound_register__last0_value, sw_left_bound_register__last_index, sw_left_bound_register__last_old_value, sw_left_bound_register__last_value, sw_left_bound_register__last_write_site, sw_left_bound_register__next_write_site, sw_left_bound_register__wrote_any, sw_left_bound_register__wrote_index0, sw_mirror_hdr_0, sw_mirror_md_0, sw_mode_array_register, sw_mode_array_register__last0_old_value, sw_mode_array_register__last0_value, sw_mode_array_register__last_index, sw_mode_array_register__last_old_value, sw_mode_array_register__last_value, sw_mode_array_register__last_write_site, sw_mode_array_register__next_write_site, sw_mode_array_register__wrote_any, sw_mode_array_register__wrote_index0, sw_p4b_checksum_error, sw_p4b_checksum_updated, sw_p4b_checksum_verified, sw_p4b_clone_e2e, sw_p4b_clone_i2e, sw_p4b_clone_i2i, sw_p4b_digest, sw_p4b_recirculate, sw_queue_size_op_register, sw_queue_size_op_register__last0_old_value, sw_queue_size_op_register__last0_value, sw_queue_size_op_register__last_index, sw_queue_size_op_register__last_old_value, sw_queue_size_op_register__last_value, sw_queue_size_op_register__last_write_site, sw_queue_size_op_register__next_write_site, sw_queue_size_op_register__wrote_any, sw_queue_size_op_register__wrote_index0, sw_right_bound_register, sw_right_bound_register__last0_old_value, sw_right_bound_register__last0_value, sw_right_bound_register__last_index, sw_right_bound_register__last_old_value, sw_right_bound_register__last_value, sw_right_bound_register__last_write_site, sw_right_bound_register__next_write_site, sw_right_bound_register__wrote_any, sw_right_bound_register__wrote_index0, sw_shared_and_exclusive_count_register, sw_shared_and_exclusive_count_register__last0_old_value, sw_shared_and_exclusive_count_register__last0_value, sw_shared_and_exclusive_count_register__last_index, sw_shared_and_exclusive_count_register__last_old_value, sw_shared_and_exclusive_count_register__last_value, sw_shared_and_exclusive_count_register__last_write_site, sw_shared_and_exclusive_count_register__next_write_site, sw_shared_and_exclusive_count_register__wrote_any, sw_shared_and_exclusive_count_register__wrote_index0, sw_slots_two_sides_register, sw_slots_two_sides_register__last0_old_value, sw_slots_two_sides_register__last0_value, sw_slots_two_sides_register__last_index, sw_slots_two_sides_register__last_old_value, sw_slots_two_sides_register__last_value, sw_slots_two_sides_register__last_write_site, sw_slots_two_sides_register__next_write_site, sw_slots_two_sides_register__wrote_any, sw_slots_two_sides_register__wrote_index0, sw_tail_register, sw_tail_register__last0_old_value, sw_tail_register__last0_value, sw_tail_register__last_index, sw_tail_register__last_old_value, sw_tail_register__last_value, sw_tail_register__last_write_site, sw_tail_register__next_write_site, sw_tail_register__wrote_any, sw_tail_register__wrote_index0, sw_tid_array_register, sw_tid_array_register__last0_old_value, sw_tid_array_register__last0_value, sw_tid_array_register__last_index, sw_tid_array_register__last_old_value, sw_tid_array_register__last_value, sw_tid_array_register__last_write_site, sw_tid_array_register__next_write_site, sw_tid_array_register__wrote_any, sw_tid_array_register__wrote_index0, sw_timestamp_hi_array_register, sw_timestamp_hi_array_register__last0_old_value, sw_timestamp_hi_array_register__last0_value, sw_timestamp_hi_array_register__last_index, sw_timestamp_hi_array_register__last_old_value, sw_timestamp_hi_array_register__last_value, sw_timestamp_hi_array_register__last_write_site, sw_timestamp_hi_array_register__next_write_site, sw_timestamp_hi_array_register__wrote_any, sw_timestamp_hi_array_register__wrote_index0, sw_timestamp_lo_array_register, sw_timestamp_lo_array_register__last0_old_value, sw_timestamp_lo_array_register__last0_value, sw_timestamp_lo_array_register__last_index, sw_timestamp_lo_array_register__last_old_value, sw_timestamp_lo_array_register__last_value, sw_timestamp_lo_array_register__last_write_site, sw_timestamp_lo_array_register__next_write_site, sw_timestamp_lo_array_register__wrote_any, sw_timestamp_lo_array_register__wrote_index0, sw_tmp;
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
function {:inline true}sw_mode_array_register.read(sw_reg:[bv32]bv8, sw_index:bv32)returns (bv8) {sw_reg[sw_index]}
procedure {:inline 1} sw_mode_array_register.write(sw_index:bv32, sw_value:bv8)
	modifies sw_mode_array_register, sw_mode_array_register__last0_old_value, sw_mode_array_register__last0_value, sw_mode_array_register__last_index, sw_mode_array_register__last_old_value, sw_mode_array_register__last_value, sw_mode_array_register__last_write_site, sw_mode_array_register__wrote_any, sw_mode_array_register__wrote_index0;
{
    sw_mode_array_register__last_old_value := sw_mode_array_register[sw_index];
    sw_mode_array_register[sw_index] := sw_value;
    sw_mode_array_register__last_index := sw_index;
    sw_mode_array_register__last_value := sw_value;
    sw_mode_array_register__last_write_site := sw_mode_array_register__next_write_site;
    sw_mode_array_register__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_mode_array_register__wrote_index0 := true;
        sw_mode_array_register__last0_old_value := sw_mode_array_register__last_old_value;
        sw_mode_array_register__last0_value := sw_value;
    }
}
procedure sw_packet_in.extract(sw_header:sw_Ref);
    ensures (sw_isValid[sw_header] == true);
	modifies sw_isValid;
procedure {:inline 1} sw_pipe()
	modifies sw_SwitchEgress_change_mode_table.action_run, sw_SwitchEgress_change_mode_table.hit, sw_SwitchEgress_change_op_type_table.action_run, sw_SwitchEgress_change_op_type_table.hit, sw_SwitchEgress_test_table.action_run, sw_SwitchEgress_test_table.hit, sw_SwitchIngress_acquire_lock_acquire_lock_table.action_run, sw_SwitchIngress_acquire_lock_acquire_lock_table.hit, sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action_run, sw_SwitchIngress_acquire_lock_dec_empty_slots_table.hit, sw_SwitchIngress_acquire_lock_drop_packet_table.action_run, sw_SwitchIngress_acquire_lock_drop_packet_table.hit, sw_SwitchIngress_acquire_lock_fix_src_port_table.action_run, sw_SwitchIngress_acquire_lock_fix_src_port_table.hit, sw_SwitchIngress_acquire_lock_forward_to_server_table.action_run, sw_SwitchIngress_acquire_lock_forward_to_server_table.hit, sw_SwitchIngress_acquire_lock_notify_tail_client_table.action_run, sw_SwitchIngress_acquire_lock_notify_tail_client_table.hit, sw_SwitchIngress_acquire_lock_set_tag_table.action_run, sw_SwitchIngress_acquire_lock_set_tag_table.hit, sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action_run, sw_SwitchIngress_acquire_lock_switch_direct_grant_table.hit, sw_SwitchIngress_acquire_lock_update_client_id_array_table.action_run, sw_SwitchIngress_acquire_lock_update_client_id_array_table.hit, sw_SwitchIngress_acquire_lock_update_ip_array_table.action_run, sw_SwitchIngress_acquire_lock_update_ip_array_table.hit, sw_SwitchIngress_acquire_lock_update_mode_array_table.action_run, sw_SwitchIngress_acquire_lock_update_mode_array_table.hit, sw_SwitchIngress_acquire_lock_update_tail_table.action_run, sw_SwitchIngress_acquire_lock_update_tail_table.hit, sw_SwitchIngress_acquire_lock_update_tid_array_table.action_run, sw_SwitchIngress_acquire_lock_update_tid_array_table.hit, sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action_run, sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.hit, sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action_run, sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.hit, sw_SwitchIngress_check_lock_exist_table.SwitchIngress_check_lock_exist_action.index_1, sw_SwitchIngress_check_lock_exist_table.action_run, sw_SwitchIngress_check_lock_exist_table.hit, sw_SwitchIngress_decode_decode_table.action_run, sw_SwitchIngress_decode_decode_table.hit, sw_SwitchIngress_decode_get_left_bound_table.action_run, sw_SwitchIngress_decode_get_left_bound_table.hit, sw_SwitchIngress_decode_get_right_bound_table.action_run, sw_SwitchIngress_decode_get_right_bound_table.hit, sw_SwitchIngress_decode_get_size_of_queue_table.action_run, sw_SwitchIngress_decode_get_size_of_queue_table.hit, sw_SwitchIngress_fix_src_port_table.action_run, sw_SwitchIngress_fix_src_port_table.hit, sw_SwitchIngress_forward_to_server_table.action_run, sw_SwitchIngress_forward_to_server_table.hit, sw_SwitchIngress_i2e_clone_table.action_run, sw_SwitchIngress_i2e_clone_table.hit, sw_SwitchIngress_ipv4_route_table.action_run, sw_SwitchIngress_ipv4_route_table.hit, sw_SwitchIngress_ipv4_route_table_2.action_run, sw_SwitchIngress_ipv4_route_table_2.hit, sw_SwitchIngress_release_lock_drop_packet_table.action_run, sw_SwitchIngress_release_lock_drop_packet_table.hit, sw_SwitchIngress_release_lock_fix_src_port_table.action_run, sw_SwitchIngress_release_lock_fix_src_port_table.hit, sw_SwitchIngress_release_lock_forward_to_server_table.action_run, sw_SwitchIngress_release_lock_forward_to_server_table.hit, sw_SwitchIngress_release_lock_get_client_id_table.action_run, sw_SwitchIngress_release_lock_get_client_id_table.hit, sw_SwitchIngress_release_lock_get_ip_table.action_run, sw_SwitchIngress_release_lock_get_ip_table.hit, sw_SwitchIngress_release_lock_get_mode_table.action_run, sw_SwitchIngress_release_lock_get_mode_table.hit, sw_SwitchIngress_release_lock_get_recirc_info_table.action_run, sw_SwitchIngress_release_lock_get_recirc_info_table.hit, sw_SwitchIngress_release_lock_get_tail_table.action_run, sw_SwitchIngress_release_lock_get_tail_table.hit, sw_SwitchIngress_release_lock_get_tid_table.action_run, sw_SwitchIngress_release_lock_get_tid_table.hit, sw_SwitchIngress_release_lock_get_timestamp_hi_table.action_run, sw_SwitchIngress_release_lock_get_timestamp_hi_table.hit, sw_SwitchIngress_release_lock_get_timestamp_lo_table.action_run, sw_SwitchIngress_release_lock_get_timestamp_lo_table.hit, sw_SwitchIngress_release_lock_i2e_mirror_table.action_run, sw_SwitchIngress_release_lock_i2e_mirror_table.hit, sw_SwitchIngress_release_lock_inc_empty_slots_table.action_run, sw_SwitchIngress_release_lock_inc_empty_slots_table.hit, sw_SwitchIngress_release_lock_metahead_plus_1_table.action_run, sw_SwitchIngress_release_lock_metahead_plus_1_table.hit, sw_SwitchIngress_release_lock_metahead_plus_2_table.action_run, sw_SwitchIngress_release_lock_metahead_plus_2_table.hit, sw_SwitchIngress_release_lock_notify_head_client_table.action_run, sw_SwitchIngress_release_lock_notify_head_client_table.hit, sw_SwitchIngress_release_lock_set_tag_table.action_run, sw_SwitchIngress_release_lock_set_tag_table.hit, sw_SwitchIngress_release_lock_update_head_table.action_run, sw_SwitchIngress_release_lock_update_head_table.hit, sw_SwitchIngress_release_lock_update_lock_table.action_run, sw_SwitchIngress_release_lock_update_lock_table.hit, sw_SwitchIngress_set_tag_table.action_run, sw_SwitchIngress_set_tag_table.hit, sw___ra_ret_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_ret_SwitchIngress_acquire_lock_push_back_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_client_id_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_ip_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_mode_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_tid_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw___ra_ret_SwitchIngress_decode_get_left_bound_alu, sw___ra_ret_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_ret_SwitchIngress_decode_get_right_bound_alu, sw___ra_ret_SwitchIngress_release_lock_get_client_id_alu, sw___ra_ret_SwitchIngress_release_lock_get_ip_alu, sw___ra_ret_SwitchIngress_release_lock_get_mode_alu, sw___ra_ret_SwitchIngress_release_lock_get_tail_alu, sw___ra_ret_SwitchIngress_release_lock_get_tid_alu, sw___ra_ret_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_ret_SwitchIngress_release_lock_update_head_alu, sw___ra_ret_SwitchIngress_release_lock_update_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_val_SwitchIngress_acquire_lock_push_back_alu, sw___ra_val_SwitchIngress_acquire_lock_update_client_id_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_ip_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_mode_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tid_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw___ra_val_SwitchIngress_decode_get_left_bound_alu, sw___ra_val_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_val_SwitchIngress_decode_get_right_bound_alu, sw___ra_val_SwitchIngress_release_lock_get_client_id_alu, sw___ra_val_SwitchIngress_release_lock_get_ip_alu, sw___ra_val_SwitchIngress_release_lock_get_mode_alu, sw___ra_val_SwitchIngress_release_lock_get_tail_alu, sw___ra_val_SwitchIngress_release_lock_get_tid_alu, sw___ra_val_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_val_SwitchIngress_release_lock_update_head_alu, sw___ra_val_SwitchIngress_release_lock_update_lock_alu, sw_client_id_array_register, sw_client_id_array_register__last0_old_value, sw_client_id_array_register__last0_value, sw_client_id_array_register__last_index, sw_client_id_array_register__last_old_value, sw_client_id_array_register__last_value, sw_client_id_array_register__last_write_site, sw_client_id_array_register__next_write_site, sw_client_id_array_register__wrote_any, sw_client_id_array_register__wrote_index0, sw_drop, sw_eg_md.client_id, sw_eg_md.clone_md, sw_eg_md.ip_address, sw_eg_md.mode, sw_eg_md.tid, sw_eg_md.timestamp_hi, sw_eg_md.timestamp_lo, sw_hdr.ethernet.dstAddr, sw_hdr.ethernet.srcAddr, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.srcAddr, sw_hdr.nlk_hdr.client_id, sw_hdr.nlk_hdr.empty_slots, sw_hdr.nlk_hdr.head, sw_hdr.nlk_hdr.lock, sw_hdr.nlk_hdr.mode, sw_hdr.nlk_hdr.op, sw_hdr.nlk_hdr.recirc_flag, sw_hdr.nlk_hdr.tail, sw_hdr.nlk_hdr.tid, sw_hdr.udp.dstPort, sw_hdr.udp.srcPort, sw_head_register, sw_head_register__last0_old_value, sw_head_register__last0_value, sw_head_register__last_index, sw_head_register__last_old_value, sw_head_register__last_value, sw_head_register__last_write_site, sw_head_register__next_write_site, sw_head_register__wrote_any, sw_head_register__wrote_index0, sw_ig_intr_dprsr_md.drop_ctl, sw_ig_intr_dprsr_md.mirror_type, sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.client_id, sw_ig_md.clone_md, sw_ig_md.dequeued_mode, sw_ig_md.empty_slots, sw_ig_md.empty_slots_before_pop, sw_ig_md.failure_status, sw_ig_md.head, sw_ig_md.ing_mir_ses, sw_ig_md.ip_address, sw_ig_md.left, sw_ig_md.length_in_server, sw_ig_md.lock_exist, sw_ig_md.lock_id, sw_ig_md.locked, sw_ig_md.mode, sw_ig_md.pkt_type, sw_ig_md.queue_size_op, sw_ig_md.recirc_flag, sw_ig_md.right, sw_ig_md.routed, sw_ig_md.size_of_queue, sw_ig_md.tail, sw_ig_md.tid, sw_ig_md.timestamp_hi, sw_ig_md.timestamp_lo, sw_ig_md.ts_hi, sw_ig_md.ts_lo, sw_ip_array_register, sw_ip_array_register__last0_old_value, sw_ip_array_register__last0_value, sw_ip_array_register__last_index, sw_ip_array_register__last_old_value, sw_ip_array_register__last_value, sw_ip_array_register__last_write_site, sw_ip_array_register__next_write_site, sw_ip_array_register__wrote_any, sw_ip_array_register__wrote_index0, sw_isValid, sw_left_bound_register, sw_left_bound_register__last0_old_value, sw_left_bound_register__last0_value, sw_left_bound_register__last_index, sw_left_bound_register__last_old_value, sw_left_bound_register__last_value, sw_left_bound_register__last_write_site, sw_left_bound_register__next_write_site, sw_left_bound_register__wrote_any, sw_left_bound_register__wrote_index0, sw_mirror_hdr_0, sw_mirror_md_0, sw_mode_array_register, sw_mode_array_register__last0_old_value, sw_mode_array_register__last0_value, sw_mode_array_register__last_index, sw_mode_array_register__last_old_value, sw_mode_array_register__last_value, sw_mode_array_register__last_write_site, sw_mode_array_register__next_write_site, sw_mode_array_register__wrote_any, sw_mode_array_register__wrote_index0, sw_p4b_clone_i2e, sw_p4b_recirculate, sw_queue_size_op_register, sw_queue_size_op_register__last0_old_value, sw_queue_size_op_register__last0_value, sw_queue_size_op_register__last_index, sw_queue_size_op_register__last_old_value, sw_queue_size_op_register__last_value, sw_queue_size_op_register__last_write_site, sw_queue_size_op_register__next_write_site, sw_queue_size_op_register__wrote_any, sw_queue_size_op_register__wrote_index0, sw_right_bound_register, sw_right_bound_register__last0_old_value, sw_right_bound_register__last0_value, sw_right_bound_register__last_index, sw_right_bound_register__last_old_value, sw_right_bound_register__last_value, sw_right_bound_register__last_write_site, sw_right_bound_register__next_write_site, sw_right_bound_register__wrote_any, sw_right_bound_register__wrote_index0, sw_shared_and_exclusive_count_register, sw_shared_and_exclusive_count_register__last0_old_value, sw_shared_and_exclusive_count_register__last0_value, sw_shared_and_exclusive_count_register__last_index, sw_shared_and_exclusive_count_register__last_old_value, sw_shared_and_exclusive_count_register__last_value, sw_shared_and_exclusive_count_register__last_write_site, sw_shared_and_exclusive_count_register__next_write_site, sw_shared_and_exclusive_count_register__wrote_any, sw_shared_and_exclusive_count_register__wrote_index0, sw_slots_two_sides_register, sw_slots_two_sides_register__last0_old_value, sw_slots_two_sides_register__last0_value, sw_slots_two_sides_register__last_index, sw_slots_two_sides_register__last_old_value, sw_slots_two_sides_register__last_value, sw_slots_two_sides_register__last_write_site, sw_slots_two_sides_register__next_write_site, sw_slots_two_sides_register__wrote_any, sw_slots_two_sides_register__wrote_index0, sw_tail_register, sw_tail_register__last0_old_value, sw_tail_register__last0_value, sw_tail_register__last_index, sw_tail_register__last_old_value, sw_tail_register__last_value, sw_tail_register__last_write_site, sw_tail_register__next_write_site, sw_tail_register__wrote_any, sw_tail_register__wrote_index0, sw_tid_array_register, sw_tid_array_register__last0_old_value, sw_tid_array_register__last0_value, sw_tid_array_register__last_index, sw_tid_array_register__last_old_value, sw_tid_array_register__last_value, sw_tid_array_register__last_write_site, sw_tid_array_register__next_write_site, sw_tid_array_register__wrote_any, sw_tid_array_register__wrote_index0, sw_timestamp_hi_array_register, sw_timestamp_hi_array_register__last0_old_value, sw_timestamp_hi_array_register__last0_value, sw_timestamp_hi_array_register__last_index, sw_timestamp_hi_array_register__last_old_value, sw_timestamp_hi_array_register__last_value, sw_timestamp_hi_array_register__last_write_site, sw_timestamp_hi_array_register__next_write_site, sw_timestamp_hi_array_register__wrote_any, sw_timestamp_hi_array_register__wrote_index0, sw_timestamp_lo_array_register, sw_timestamp_lo_array_register__last0_old_value, sw_timestamp_lo_array_register__last0_value, sw_timestamp_lo_array_register__last_index, sw_timestamp_lo_array_register__last_old_value, sw_timestamp_lo_array_register__last_value, sw_timestamp_lo_array_register__last_write_site, sw_timestamp_lo_array_register__next_write_site, sw_timestamp_lo_array_register__wrote_any, sw_timestamp_lo_array_register__wrote_index0, sw_tmp;
{
    call sw_SwitchIngressParser();
    call sw_SwitchIngress();
    call sw_SwitchIngressDeparser();
    call sw_SwitchEgressParser();
    call sw_SwitchEgress();
    call sw_SwitchEgressDeparser();
}
procedure sw_pkt.advance(sw_arg0:bv32);
procedure sw_pkt.emit(sw_arg0:sw_header_t);
function {:inline true}sw_queue_size_op_register.read(sw_reg:[bv32]bv32, sw_index:bv32)returns (bv32) {sw_reg[sw_index]}
procedure {:inline 1} sw_queue_size_op_register.write(sw_index:bv32, sw_value:bv32)
	modifies sw_queue_size_op_register, sw_queue_size_op_register__last0_old_value, sw_queue_size_op_register__last0_value, sw_queue_size_op_register__last_index, sw_queue_size_op_register__last_old_value, sw_queue_size_op_register__last_value, sw_queue_size_op_register__last_write_site, sw_queue_size_op_register__wrote_any, sw_queue_size_op_register__wrote_index0;
{
    sw_queue_size_op_register__last_old_value := sw_queue_size_op_register[sw_index];
    sw_queue_size_op_register[sw_index] := sw_value;
    sw_queue_size_op_register__last_index := sw_index;
    sw_queue_size_op_register__last_value := sw_value;
    sw_queue_size_op_register__last_write_site := sw_queue_size_op_register__next_write_site;
    sw_queue_size_op_register__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_queue_size_op_register__wrote_index0 := true;
        sw_queue_size_op_register__last0_old_value := sw_queue_size_op_register__last_old_value;
        sw_queue_size_op_register__last0_value := sw_value;
    }
}
procedure sw_reject();
    ensures sw_drop==true;
	modifies sw_drop;
function {:inline true}sw_right_bound_register.read(sw_reg:[bv32]bv32, sw_index:bv32)returns (bv32) {sw_reg[sw_index]}
procedure {:inline 1} sw_right_bound_register.write(sw_index:bv32, sw_value:bv32)
	modifies sw_right_bound_register, sw_right_bound_register__last0_old_value, sw_right_bound_register__last0_value, sw_right_bound_register__last_index, sw_right_bound_register__last_old_value, sw_right_bound_register__last_value, sw_right_bound_register__last_write_site, sw_right_bound_register__wrote_any, sw_right_bound_register__wrote_index0;
{
    sw_right_bound_register__last_old_value := sw_right_bound_register[sw_index];
    sw_right_bound_register[sw_index] := sw_value;
    sw_right_bound_register__last_index := sw_index;
    sw_right_bound_register__last_value := sw_value;
    sw_right_bound_register__last_write_site := sw_right_bound_register__next_write_site;
    sw_right_bound_register__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_right_bound_register__wrote_index0 := true;
        sw_right_bound_register__last0_old_value := sw_right_bound_register__last_old_value;
        sw_right_bound_register__last0_value := sw_value;
    }
}
procedure {:inline 1} sw_setInvalid(sw_header:sw_Ref);
    ensures (sw_isValid[sw_header] == false);
	modifies sw_isValid;
procedure {:inline 1} sw_setValid(sw_header:sw_Ref);

// sw_Action sw_set_egress_1
procedure {:inline 1} sw_set_egress_1(sw_egress_spec_1:sw_PortId_t)
	modifies sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.routed;
{
    sw_ig_intr_tm_md.ucast_egress_port := sw_egress_spec_1;
    sw_ig_intr_tm_md.bypass_egress := 1bv1;
    sw_ig_md.routed := 1bv1;
}
function {:inline true}sw_shared_and_exclusive_count_register.read(sw_reg:[bv32]sw_pair, sw_index:bv32)returns (sw_pair) {sw_reg[sw_index]}
procedure {:inline 1} sw_shared_and_exclusive_count_register.write(sw_index:bv32, sw_value:sw_pair)
	modifies sw_shared_and_exclusive_count_register, sw_shared_and_exclusive_count_register__last0_old_value, sw_shared_and_exclusive_count_register__last0_value, sw_shared_and_exclusive_count_register__last_index, sw_shared_and_exclusive_count_register__last_old_value, sw_shared_and_exclusive_count_register__last_value, sw_shared_and_exclusive_count_register__last_write_site, sw_shared_and_exclusive_count_register__wrote_any, sw_shared_and_exclusive_count_register__wrote_index0;
{
    sw_shared_and_exclusive_count_register__last_old_value := sw_shared_and_exclusive_count_register[sw_index];
    sw_shared_and_exclusive_count_register[sw_index] := sw_value;
    sw_shared_and_exclusive_count_register__last_index := sw_index;
    sw_shared_and_exclusive_count_register__last_value := sw_value;
    sw_shared_and_exclusive_count_register__last_write_site := sw_shared_and_exclusive_count_register__next_write_site;
    sw_shared_and_exclusive_count_register__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_shared_and_exclusive_count_register__wrote_index0 := true;
        sw_shared_and_exclusive_count_register__last0_old_value := sw_shared_and_exclusive_count_register__last_old_value;
        sw_shared_and_exclusive_count_register__last0_value := sw_value;
    }
}
function {:inline true}sw_slots_two_sides_register.read(sw_reg:[bv32]sw_pair, sw_index:bv32)returns (sw_pair) {sw_reg[sw_index]}
procedure {:inline 1} sw_slots_two_sides_register.write(sw_index:bv32, sw_value:sw_pair)
	modifies sw_slots_two_sides_register, sw_slots_two_sides_register__last0_old_value, sw_slots_two_sides_register__last0_value, sw_slots_two_sides_register__last_index, sw_slots_two_sides_register__last_old_value, sw_slots_two_sides_register__last_value, sw_slots_two_sides_register__last_write_site, sw_slots_two_sides_register__wrote_any, sw_slots_two_sides_register__wrote_index0;
{
    sw_slots_two_sides_register__last_old_value := sw_slots_two_sides_register[sw_index];
    sw_slots_two_sides_register[sw_index] := sw_value;
    sw_slots_two_sides_register__last_index := sw_index;
    sw_slots_two_sides_register__last_value := sw_value;
    sw_slots_two_sides_register__last_write_site := sw_slots_two_sides_register__next_write_site;
    sw_slots_two_sides_register__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_slots_two_sides_register__wrote_index0 := true;
        sw_slots_two_sides_register__last0_old_value := sw_slots_two_sides_register__last_old_value;
        sw_slots_two_sides_register__last0_value := sw_value;
    }
}
function {:inline true}sw_tail_register.read(sw_reg:[bv32]bv32, sw_index:bv32)returns (bv32) {sw_reg[sw_index]}
procedure {:inline 1} sw_tail_register.write(sw_index:bv32, sw_value:bv32)
	modifies sw_tail_register, sw_tail_register__last0_old_value, sw_tail_register__last0_value, sw_tail_register__last_index, sw_tail_register__last_old_value, sw_tail_register__last_value, sw_tail_register__last_write_site, sw_tail_register__wrote_any, sw_tail_register__wrote_index0;
{
    sw_tail_register__last_old_value := sw_tail_register[sw_index];
    sw_tail_register[sw_index] := sw_value;
    sw_tail_register__last_index := sw_index;
    sw_tail_register__last_value := sw_value;
    sw_tail_register__last_write_site := sw_tail_register__next_write_site;
    sw_tail_register__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_tail_register__wrote_index0 := true;
        sw_tail_register__last0_old_value := sw_tail_register__last_old_value;
        sw_tail_register__last0_value := sw_value;
    }
}
function {:inline true}sw_tenant_acq_counter_register.read(sw_reg:[bv4]bv32, sw_index:bv4)returns (bv32) {sw_reg[sw_index]}
procedure {:inline 1} sw_tenant_acq_counter_register.write(sw_index:bv4, sw_value:bv32)
	modifies sw_tenant_acq_counter_register, sw_tenant_acq_counter_register__last0_old_value, sw_tenant_acq_counter_register__last0_value, sw_tenant_acq_counter_register__last_index, sw_tenant_acq_counter_register__last_old_value, sw_tenant_acq_counter_register__last_value, sw_tenant_acq_counter_register__last_write_site, sw_tenant_acq_counter_register__wrote_any, sw_tenant_acq_counter_register__wrote_index0;
{
    sw_tenant_acq_counter_register__last_old_value := sw_tenant_acq_counter_register[sw_index];
    sw_tenant_acq_counter_register[sw_index] := sw_value;
    sw_tenant_acq_counter_register__last_index := sw_index;
    sw_tenant_acq_counter_register__last_value := sw_value;
    sw_tenant_acq_counter_register__last_write_site := sw_tenant_acq_counter_register__next_write_site;
    sw_tenant_acq_counter_register__wrote_any := true;
    if (sw_index == 0bv4) {
        sw_tenant_acq_counter_register__wrote_index0 := true;
        sw_tenant_acq_counter_register__last0_old_value := sw_tenant_acq_counter_register__last_old_value;
        sw_tenant_acq_counter_register__last0_value := sw_value;
    }
}
function {:inline true}sw_tid_array_register.read(sw_reg:[bv32]bv32, sw_index:bv32)returns (bv32) {sw_reg[sw_index]}
procedure {:inline 1} sw_tid_array_register.write(sw_index:bv32, sw_value:bv32)
	modifies sw_tid_array_register, sw_tid_array_register__last0_old_value, sw_tid_array_register__last0_value, sw_tid_array_register__last_index, sw_tid_array_register__last_old_value, sw_tid_array_register__last_value, sw_tid_array_register__last_write_site, sw_tid_array_register__wrote_any, sw_tid_array_register__wrote_index0;
{
    sw_tid_array_register__last_old_value := sw_tid_array_register[sw_index];
    sw_tid_array_register[sw_index] := sw_value;
    sw_tid_array_register__last_index := sw_index;
    sw_tid_array_register__last_value := sw_value;
    sw_tid_array_register__last_write_site := sw_tid_array_register__next_write_site;
    sw_tid_array_register__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_tid_array_register__wrote_index0 := true;
        sw_tid_array_register__last0_old_value := sw_tid_array_register__last_old_value;
        sw_tid_array_register__last0_value := sw_value;
    }
}
function {:inline true}sw_timestamp_hi_array_register.read(sw_reg:[bv32]bv32, sw_index:bv32)returns (bv32) {sw_reg[sw_index]}
procedure {:inline 1} sw_timestamp_hi_array_register.write(sw_index:bv32, sw_value:bv32)
	modifies sw_timestamp_hi_array_register, sw_timestamp_hi_array_register__last0_old_value, sw_timestamp_hi_array_register__last0_value, sw_timestamp_hi_array_register__last_index, sw_timestamp_hi_array_register__last_old_value, sw_timestamp_hi_array_register__last_value, sw_timestamp_hi_array_register__last_write_site, sw_timestamp_hi_array_register__wrote_any, sw_timestamp_hi_array_register__wrote_index0;
{
    sw_timestamp_hi_array_register__last_old_value := sw_timestamp_hi_array_register[sw_index];
    sw_timestamp_hi_array_register[sw_index] := sw_value;
    sw_timestamp_hi_array_register__last_index := sw_index;
    sw_timestamp_hi_array_register__last_value := sw_value;
    sw_timestamp_hi_array_register__last_write_site := sw_timestamp_hi_array_register__next_write_site;
    sw_timestamp_hi_array_register__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_timestamp_hi_array_register__wrote_index0 := true;
        sw_timestamp_hi_array_register__last0_old_value := sw_timestamp_hi_array_register__last_old_value;
        sw_timestamp_hi_array_register__last0_value := sw_value;
    }
}
function {:inline true}sw_timestamp_lo_array_register.read(sw_reg:[bv32]bv32, sw_index:bv32)returns (bv32) {sw_reg[sw_index]}
procedure {:inline 1} sw_timestamp_lo_array_register.write(sw_index:bv32, sw_value:bv32)
	modifies sw_timestamp_lo_array_register, sw_timestamp_lo_array_register__last0_old_value, sw_timestamp_lo_array_register__last0_value, sw_timestamp_lo_array_register__last_index, sw_timestamp_lo_array_register__last_old_value, sw_timestamp_lo_array_register__last_value, sw_timestamp_lo_array_register__last_write_site, sw_timestamp_lo_array_register__wrote_any, sw_timestamp_lo_array_register__wrote_index0;
{
    sw_timestamp_lo_array_register__last_old_value := sw_timestamp_lo_array_register[sw_index];
    sw_timestamp_lo_array_register[sw_index] := sw_value;
    sw_timestamp_lo_array_register__last_index := sw_index;
    sw_timestamp_lo_array_register__last_value := sw_value;
    sw_timestamp_lo_array_register__last_write_site := sw_timestamp_lo_array_register__next_write_site;
    sw_timestamp_lo_array_register__wrote_any := true;
    if (sw_index == 0bv32) {
        sw_timestamp_lo_array_register__wrote_index0 := true;
        sw_timestamp_lo_array_register__last0_old_value := sw_timestamp_lo_array_register__last_old_value;
        sw_timestamp_lo_array_register__last0_value := sw_value;
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

// Register debug snapshots (for trace inspection)
var sw_client_id_array_register__dbg0: bv8;
var sw_client_id_array_register__last_index__dbg: bv32;
var sw_client_id_array_register__last_value__dbg: bv8;
var sw_client_id_array_register__last_old_value__dbg: bv8;
var sw_client_id_array_register__wrote_any__dbg: bool;
var sw_client_id_array_register__wrote_index0__dbg: bool;
var sw_client_id_array_register__last0_old_value__dbg: bv8;
var sw_client_id_array_register__last0_value__dbg: bv8;
var sw_failure_status_register__dbg0: bv8;
var sw_failure_status_register__last_index__dbg: bv1;
var sw_failure_status_register__last_value__dbg: bv8;
var sw_failure_status_register__last_old_value__dbg: bv8;
var sw_failure_status_register__wrote_any__dbg: bool;
var sw_failure_status_register__wrote_index0__dbg: bool;
var sw_failure_status_register__last0_old_value__dbg: bv8;
var sw_failure_status_register__last0_value__dbg: bv8;
var sw_head_register__dbg0: bv32;
var sw_head_register__last_index__dbg: bv32;
var sw_head_register__last_value__dbg: bv32;
var sw_head_register__last_old_value__dbg: bv32;
var sw_head_register__wrote_any__dbg: bool;
var sw_head_register__wrote_index0__dbg: bool;
var sw_head_register__last0_old_value__dbg: bv32;
var sw_head_register__last0_value__dbg: bv32;
var sw_ip_array_register__dbg0: bv32;
var sw_ip_array_register__last_index__dbg: bv32;
var sw_ip_array_register__last_value__dbg: bv32;
var sw_ip_array_register__last_old_value__dbg: bv32;
var sw_ip_array_register__wrote_any__dbg: bool;
var sw_ip_array_register__wrote_index0__dbg: bool;
var sw_ip_array_register__last0_old_value__dbg: bv32;
var sw_ip_array_register__last0_value__dbg: bv32;
var sw_left_bound_register__dbg0: bv32;
var sw_left_bound_register__last_index__dbg: bv32;
var sw_left_bound_register__last_value__dbg: bv32;
var sw_left_bound_register__last_old_value__dbg: bv32;
var sw_left_bound_register__wrote_any__dbg: bool;
var sw_left_bound_register__wrote_index0__dbg: bool;
var sw_left_bound_register__last0_old_value__dbg: bv32;
var sw_left_bound_register__last0_value__dbg: bv32;
var sw_mode_array_register__dbg0: bv8;
var sw_mode_array_register__last_index__dbg: bv32;
var sw_mode_array_register__last_value__dbg: bv8;
var sw_mode_array_register__last_old_value__dbg: bv8;
var sw_mode_array_register__wrote_any__dbg: bool;
var sw_mode_array_register__wrote_index0__dbg: bool;
var sw_mode_array_register__last0_old_value__dbg: bv8;
var sw_mode_array_register__last0_value__dbg: bv8;
var sw_queue_size_op_register__dbg0: bv32;
var sw_queue_size_op_register__last_index__dbg: bv32;
var sw_queue_size_op_register__last_value__dbg: bv32;
var sw_queue_size_op_register__last_old_value__dbg: bv32;
var sw_queue_size_op_register__wrote_any__dbg: bool;
var sw_queue_size_op_register__wrote_index0__dbg: bool;
var sw_queue_size_op_register__last0_old_value__dbg: bv32;
var sw_queue_size_op_register__last0_value__dbg: bv32;
var sw_right_bound_register__dbg0: bv32;
var sw_right_bound_register__last_index__dbg: bv32;
var sw_right_bound_register__last_value__dbg: bv32;
var sw_right_bound_register__last_old_value__dbg: bv32;
var sw_right_bound_register__wrote_any__dbg: bool;
var sw_right_bound_register__wrote_index0__dbg: bool;
var sw_right_bound_register__last0_old_value__dbg: bv32;
var sw_right_bound_register__last0_value__dbg: bv32;
var sw_shared_and_exclusive_count_register__dbg0: sw_pair;
var sw_shared_and_exclusive_count_register__last_index__dbg: bv32;
var sw_shared_and_exclusive_count_register__last_value__dbg: sw_pair;
var sw_shared_and_exclusive_count_register__last_old_value__dbg: sw_pair;
var sw_shared_and_exclusive_count_register__wrote_any__dbg: bool;
var sw_shared_and_exclusive_count_register__wrote_index0__dbg: bool;
var sw_shared_and_exclusive_count_register__last0_old_value__dbg: sw_pair;
var sw_shared_and_exclusive_count_register__last0_value__dbg: sw_pair;
var sw_slots_two_sides_register__dbg0: sw_pair;
var sw_slots_two_sides_register__last_index__dbg: bv32;
var sw_slots_two_sides_register__last_value__dbg: sw_pair;
var sw_slots_two_sides_register__last_old_value__dbg: sw_pair;
var sw_slots_two_sides_register__wrote_any__dbg: bool;
var sw_slots_two_sides_register__wrote_index0__dbg: bool;
var sw_slots_two_sides_register__last0_old_value__dbg: sw_pair;
var sw_slots_two_sides_register__last0_value__dbg: sw_pair;
var sw_tail_register__dbg0: bv32;
var sw_tail_register__last_index__dbg: bv32;
var sw_tail_register__last_value__dbg: bv32;
var sw_tail_register__last_old_value__dbg: bv32;
var sw_tail_register__wrote_any__dbg: bool;
var sw_tail_register__wrote_index0__dbg: bool;
var sw_tail_register__last0_old_value__dbg: bv32;
var sw_tail_register__last0_value__dbg: bv32;
var sw_tenant_acq_counter_register__dbg0: bv32;
var sw_tenant_acq_counter_register__last_index__dbg: bv4;
var sw_tenant_acq_counter_register__last_value__dbg: bv32;
var sw_tenant_acq_counter_register__last_old_value__dbg: bv32;
var sw_tenant_acq_counter_register__wrote_any__dbg: bool;
var sw_tenant_acq_counter_register__wrote_index0__dbg: bool;
var sw_tenant_acq_counter_register__last0_old_value__dbg: bv32;
var sw_tenant_acq_counter_register__last0_value__dbg: bv32;
var sw_tid_array_register__dbg0: bv32;
var sw_tid_array_register__last_index__dbg: bv32;
var sw_tid_array_register__last_value__dbg: bv32;
var sw_tid_array_register__last_old_value__dbg: bv32;
var sw_tid_array_register__wrote_any__dbg: bool;
var sw_tid_array_register__wrote_index0__dbg: bool;
var sw_tid_array_register__last0_old_value__dbg: bv32;
var sw_tid_array_register__last0_value__dbg: bv32;
var sw_timestamp_hi_array_register__dbg0: bv32;
var sw_timestamp_hi_array_register__last_index__dbg: bv32;
var sw_timestamp_hi_array_register__last_value__dbg: bv32;
var sw_timestamp_hi_array_register__last_old_value__dbg: bv32;
var sw_timestamp_hi_array_register__wrote_any__dbg: bool;
var sw_timestamp_hi_array_register__wrote_index0__dbg: bool;
var sw_timestamp_hi_array_register__last0_old_value__dbg: bv32;
var sw_timestamp_hi_array_register__last0_value__dbg: bv32;
var sw_timestamp_lo_array_register__dbg0: bv32;
var sw_timestamp_lo_array_register__last_index__dbg: bv32;
var sw_timestamp_lo_array_register__last_value__dbg: bv32;
var sw_timestamp_lo_array_register__last_old_value__dbg: bv32;
var sw_timestamp_lo_array_register__wrote_any__dbg: bool;
var sw_timestamp_lo_array_register__wrote_index0__dbg: bool;
var sw_timestamp_lo_array_register__last0_old_value__dbg: bv32;
var sw_timestamp_lo_array_register__last0_value__dbg: bv32;

var sw_inbox_count: int;
var client_inbox_count: int;

var sw_pkt_external: bool;
var client_pkt_external: bool;

// Host packet fields (mirrors connected node symbols)
var client_hdr.bridged_md.valid: bool;
var client_hdr.bridged_md.pkt_type: sw_pkt_type_t;
var client_hdr.ethernet.valid: bool;
var client_hdr.ethernet.dstAddr: sw_mac_addr_t;
var client_hdr.ethernet.srcAddr: sw_mac_addr_t;
var client_hdr.ethernet.etherType: sw_ether_type_t;
var client_hdr.ipv4.valid: bool;
var client_hdr.ipv4.version: bv4;
var client_hdr.ipv4.ihl: bv4;
var client_hdr.ipv4.diffserv: bv8;
var client_hdr.ipv4.totalLen: bv16;
var client_hdr.ipv4.identification: bv16;
var client_hdr.ipv4.flags: bv3;
var client_hdr.ipv4.fragOffset: bv13;
var client_hdr.ipv4.ttl: bv8;
var client_hdr.ipv4.protocol: sw_ip_protocol_t;
var client_hdr.ipv4.hdrChecksum: bv16;
var client_hdr.ipv4.srcAddr: sw_ipv4_addr_t;
var client_hdr.ipv4.dstAddr: sw_ipv4_addr_t;
var client_hdr.tcp.valid: bool;
var client_hdr.tcp.srcPort: bv16;
var client_hdr.tcp.dstPort: bv16;
var client_hdr.tcp.seqNo: bv32;
var client_hdr.tcp.ackNo: bv32;
var client_hdr.tcp.dataOffset: bv4;
var client_hdr.tcp.res: bv3;
var client_hdr.tcp.ecn: bv3;
var client_hdr.tcp.ctrl: bv6;
var client_hdr.tcp.window: bv16;
var client_hdr.tcp.checksum: bv16;
var client_hdr.tcp.urgentPtr: bv16;
var client_hdr.udp.valid: bool;
var client_hdr.udp.srcPort: bv16;
var client_hdr.udp.dstPort: bv16;
var client_hdr.udp.pkt_length: bv16;
var client_hdr.udp.checksum: bv16;
var client_hdr.nlk_hdr.valid: bool;
var client_hdr.nlk_hdr.recirc_flag: bv8;
var client_hdr.nlk_hdr.op: bv8;
var client_hdr.nlk_hdr.mode: bv8;
var client_hdr.nlk_hdr.client_id: bv8;
var client_hdr.nlk_hdr.tid: bv32;
var client_hdr.nlk_hdr.lock: bv32;
var client_hdr.nlk_hdr.timestamp_lo: bv32;
var client_hdr.nlk_hdr.timestamp_hi: bv32;
var client_hdr.nlk_hdr.empty_slots: bv32;
var client_hdr.nlk_hdr.head: bv32;
var client_hdr.nlk_hdr.tail: bv32;
var client_hdr.nlk_hdr.ncnt: bv8;
var client_hdr.nlk_hdr.transferred: bv8;
var client_hdr.adm_hdr.valid: bool;
var client_hdr.adm_hdr.op: bv8;
var client_hdr.adm_hdr.lock: bv32;
var client_hdr.adm_hdr.new_left: bv32;
var client_hdr.adm_hdr.new_right: bv32;
var client_hdr.recirculate_hdr.valid: bool;
var client_hdr.recirculate_hdr.dequeued_mode: bv8;
var client_hdr.recirculate_hdr.cur_head: bv32;
var client_hdr.recirculate_hdr.cur_tail: bv32;
var client_hdr.probe_hdr.valid: bool;
var client_hdr.probe_hdr.failure_status: bv8;
var client_hdr.probe_hdr.op: bv8;
var client_hdr.probe_hdr.mode: bv8;
var client_hdr.probe_hdr.client_id: bv8;
var client_hdr.probe_hdr.tid: bv32;
var client_hdr.probe_hdr.lock: bv32;
var client_hdr.probe_hdr.timestamp_lo: bv32;
var client_hdr.probe_hdr.timestamp_hi: bv32;
var client_eg_md.head: bv32;
var client_eg_md.tail: bv32;
var client_eg_md.queue_size_op: bv32;
var client_eg_md.do_resubmit: bv1;
var client_eg_md.routed: bv1;
var client_eg_md.dropped: bv1;
var client_eg_md.lock_exist: bv1;
var client_eg_md.recirc_flag: bv8;
var client_eg_md.dequeued_mode: bv8;
var client_eg_md.recirced: bv2;
var client_eg_md.locked: bv32;
var client_eg_md.left: bv32;
var client_eg_md.right: bv32;
var client_eg_md.src_ip: bv32;
var client_eg_md.dst_ip: bv32;
var client_eg_md.empty_slots: bv32;
var client_eg_md.length_in_server: bv32;
var client_eg_md.size_of_queue: bv32;
var client_eg_md.empty_slots_before_pop: bv32;
var client_eg_md.ts_hi: bv32;
var client_eg_md.ts_lo: bv32;
var client_eg_md.lock_id: bv32;
var client_eg_md.failure_status: bv8;
var client_eg_md.ing_mir_ses: sw_MirrorId_t;
var client_eg_md.clone_md: bv8;
var client_eg_md.mode: bv8;
var client_eg_md.client_id: bv8;
var client_eg_md.tid: bv32;
var client_eg_md.ip_address: bv32;
var client_eg_md.timestamp_lo: bv32;
var client_eg_md.timestamp_hi: bv32;
var client_eg_md.pkt_type: sw_pkt_type_t;
var client_eg_intr_md.valid: bool;
var client_eg_intr_md._pad0: bv7;
var client_eg_intr_md._pad1: bv5;
var client_eg_intr_md.enq_qdepth: bv19;
var client_eg_intr_md._pad2: bv6;
var client_eg_intr_md.enq_congest_stat: bv2;
var client_eg_intr_md._pad3: bv14;
var client_eg_intr_md.enq_tstamp: bv18;
var client_eg_intr_md._pad4: bv5;
var client_eg_intr_md.deq_qdepth: bv19;
var client_eg_intr_md._pad5: bv6;
var client_eg_intr_md.deq_congest_stat: bv2;
var client_eg_intr_md.app_pool_congest_stat: bv8;
var client_eg_intr_md._pad6: bv14;
var client_eg_intr_md.deq_timedelta: bv18;
var client_eg_intr_md.egress_rid: bv16;
var client_eg_intr_md._pad7: bv7;
var client_eg_intr_md.egress_rid_first: bv1;
var client_eg_intr_md._pad8: bv3;
var client_eg_intr_md.egress_qid: sw_QueueId_t;
var client_eg_intr_md._pad9: bv5;
var client_eg_intr_md.egress_cos: bv3;
var client_eg_intr_md._pad10: bv7;
var client_eg_intr_md.deflection_flag: bv1;
var client_eg_intr_md.pkt_length: bv16;
var client_eg_intr_dprs_md.drop_ctl: bv3;
var client_eg_intr_dprs_md.mirror_type: sw_MirrorType_t;
var client_eg_intr_dprs_md.coalesce_flush: bv1;
var client_eg_intr_dprs_md.coalesce_length: bv7;
var client_eg_intr_oport_md.capture_tstamp_on_tx: bv1;
var client_eg_intr_oport_md.update_delay_on_tx: bv1;
var client_ig_md.head: bv32;
var client_ig_md.tail: bv32;
var client_ig_md.queue_size_op: bv32;
var client_ig_md.do_resubmit: bv1;
var client_ig_md.routed: bv1;
var client_ig_md.dropped: bv1;
var client_ig_md.lock_exist: bv1;
var client_ig_md.recirc_flag: bv8;
var client_ig_md.dequeued_mode: bv8;
var client_ig_md.recirced: bv2;
var client_ig_md.locked: bv32;
var client_ig_md.left: bv32;
var client_ig_md.right: bv32;
var client_ig_md.src_ip: bv32;
var client_ig_md.dst_ip: bv32;
var client_ig_md.empty_slots: bv32;
var client_ig_md.length_in_server: bv32;
var client_ig_md.size_of_queue: bv32;
var client_ig_md.empty_slots_before_pop: bv32;
var client_ig_md.ts_hi: bv32;
var client_ig_md.ts_lo: bv32;
var client_ig_md.lock_id: bv32;
var client_ig_md.failure_status: bv8;
var client_ig_md.ing_mir_ses: sw_MirrorId_t;
var client_ig_md.clone_md: bv8;
var client_ig_md.mode: bv8;
var client_ig_md.client_id: bv8;
var client_ig_md.tid: bv32;
var client_ig_md.ip_address: bv32;
var client_ig_md.timestamp_lo: bv32;
var client_ig_md.timestamp_hi: bv32;
var client_ig_md.pkt_type: sw_pkt_type_t;
var client_ig_intr_md.valid: bool;
var client_ig_intr_md.resubmit_flag: bv1;
var client_ig_intr_md._pad1: bv1;
var client_ig_intr_md.packet_version: bv2;
var client_ig_intr_md._pad2: bv3;
var client_ig_intr_md.ingress_port: sw_PortId_t;
var client_ig_intr_md.ingress_mac_tstamp: bv48;
var client_ig_intr_prsr_md.global_tstamp: bv48;
var client_ig_intr_prsr_md.global_ver: bv32;
var client_ig_intr_prsr_md.parser_err: bv16;
var client_ig_intr_dprsr_md.drop_ctl: bv3;
var client_ig_intr_dprsr_md.digest_type: sw_DigestType_t;
var client_ig_intr_dprsr_md.resubmit_type: sw_ResubmitType_t;
var client_ig_intr_dprsr_md.mirror_type: sw_MirrorType_t;
var client_ig_intr_tm_md.bypass_egress: bv1;
var client_ig_intr_tm_md.deflect_on_drop: bv1;
var client_ig_intr_tm_md.ingress_cos: bv3;
var client_ig_intr_tm_md.qid: sw_QueueId_t;
var client_ig_intr_tm_md.icos_for_copy_to_cpu: bv3;
var client_ig_intr_tm_md.copy_to_cpu: bv1;
var client_ig_intr_tm_md.packet_color: bv2;
var client_ig_intr_tm_md.disable_ucast_cutthru: bv1;
var client_ig_intr_tm_md.enable_mcast_cutthru: bv1;
var client_ig_intr_tm_md.mcast_grp_a: sw_MulticastGroupId_t;
var client_ig_intr_tm_md.mcast_grp_b: sw_MulticastGroupId_t;
var client_ig_intr_tm_md.level1_mcast_hash: bv13;
var client_ig_intr_tm_md.level2_mcast_hash: bv13;
var client_ig_intr_tm_md.level1_exclusion_id: sw_L1ExclusionId_t;
var client_ig_intr_tm_md.level2_exclusion_id: sw_L2ExclusionId_t;
var client_ig_intr_tm_md.rid: bv16;

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

procedure mainProcedure() returns()
  modifies client_eg_intr_dprs_md.coalesce_flush, client_eg_intr_dprs_md.coalesce_length, client_eg_intr_dprs_md.drop_ctl, client_eg_intr_dprs_md.mirror_type, client_eg_intr_md._pad0, client_eg_intr_md._pad1, client_eg_intr_md._pad10, client_eg_intr_md._pad2, client_eg_intr_md._pad3, client_eg_intr_md._pad4, client_eg_intr_md._pad5, client_eg_intr_md._pad6, client_eg_intr_md._pad7, client_eg_intr_md._pad8, client_eg_intr_md._pad9, client_eg_intr_md.app_pool_congest_stat, client_eg_intr_md.deflection_flag, client_eg_intr_md.deq_congest_stat, client_eg_intr_md.deq_qdepth, client_eg_intr_md.deq_timedelta, client_eg_intr_md.egress_cos, client_eg_intr_md.egress_qid, client_eg_intr_md.egress_rid, client_eg_intr_md.egress_rid_first, client_eg_intr_md.enq_congest_stat, client_eg_intr_md.enq_qdepth, client_eg_intr_md.enq_tstamp, client_eg_intr_md.pkt_length, client_eg_intr_md.valid, client_eg_intr_oport_md.capture_tstamp_on_tx, client_eg_intr_oport_md.update_delay_on_tx, client_eg_md.client_id, client_eg_md.clone_md, client_eg_md.dequeued_mode, client_eg_md.do_resubmit, client_eg_md.dropped, client_eg_md.dst_ip, client_eg_md.empty_slots, client_eg_md.empty_slots_before_pop, client_eg_md.failure_status, client_eg_md.head, client_eg_md.ing_mir_ses, client_eg_md.ip_address, client_eg_md.left, client_eg_md.length_in_server, client_eg_md.lock_exist, client_eg_md.lock_id, client_eg_md.locked, client_eg_md.mode, client_eg_md.pkt_type, client_eg_md.queue_size_op, client_eg_md.recirc_flag, client_eg_md.recirced, client_eg_md.right, client_eg_md.routed, client_eg_md.size_of_queue, client_eg_md.src_ip, client_eg_md.tail, client_eg_md.tid, client_eg_md.timestamp_hi, client_eg_md.timestamp_lo, client_eg_md.ts_hi, client_eg_md.ts_lo, client_hdr.adm_hdr.lock, client_hdr.adm_hdr.new_left, client_hdr.adm_hdr.new_right, client_hdr.adm_hdr.op, client_hdr.adm_hdr.valid, client_hdr.bridged_md.pkt_type, client_hdr.bridged_md.valid, client_hdr.ethernet.dstAddr, client_hdr.ethernet.etherType, client_hdr.ethernet.srcAddr, client_hdr.ethernet.valid, client_hdr.ipv4.diffserv, client_hdr.ipv4.dstAddr, client_hdr.ipv4.flags, client_hdr.ipv4.fragOffset, client_hdr.ipv4.hdrChecksum, client_hdr.ipv4.identification, client_hdr.ipv4.ihl, client_hdr.ipv4.protocol, client_hdr.ipv4.srcAddr, client_hdr.ipv4.totalLen, client_hdr.ipv4.ttl, client_hdr.ipv4.valid, client_hdr.ipv4.version, client_hdr.nlk_hdr.client_id, client_hdr.nlk_hdr.empty_slots, client_hdr.nlk_hdr.head, client_hdr.nlk_hdr.lock, client_hdr.nlk_hdr.mode, client_hdr.nlk_hdr.ncnt, client_hdr.nlk_hdr.op, client_hdr.nlk_hdr.recirc_flag, client_hdr.nlk_hdr.tail, client_hdr.nlk_hdr.tid, client_hdr.nlk_hdr.timestamp_hi, client_hdr.nlk_hdr.timestamp_lo, client_hdr.nlk_hdr.transferred, client_hdr.nlk_hdr.valid, client_hdr.probe_hdr.client_id, client_hdr.probe_hdr.failure_status, client_hdr.probe_hdr.lock, client_hdr.probe_hdr.mode, client_hdr.probe_hdr.op, client_hdr.probe_hdr.tid, client_hdr.probe_hdr.timestamp_hi, client_hdr.probe_hdr.timestamp_lo, client_hdr.probe_hdr.valid, client_hdr.recirculate_hdr.cur_head, client_hdr.recirculate_hdr.cur_tail, client_hdr.recirculate_hdr.dequeued_mode, client_hdr.recirculate_hdr.valid, client_hdr.tcp.ackNo, client_hdr.tcp.checksum, client_hdr.tcp.ctrl, client_hdr.tcp.dataOffset, client_hdr.tcp.dstPort, client_hdr.tcp.ecn, client_hdr.tcp.res, client_hdr.tcp.seqNo, client_hdr.tcp.srcPort, client_hdr.tcp.urgentPtr, client_hdr.tcp.valid, client_hdr.tcp.window, client_hdr.udp.checksum, client_hdr.udp.dstPort, client_hdr.udp.pkt_length, client_hdr.udp.srcPort, client_hdr.udp.valid, client_ig_intr_dprsr_md.digest_type, client_ig_intr_dprsr_md.drop_ctl, client_ig_intr_dprsr_md.mirror_type, client_ig_intr_dprsr_md.resubmit_type, client_ig_intr_md._pad1, client_ig_intr_md._pad2, client_ig_intr_md.ingress_mac_tstamp, client_ig_intr_md.ingress_port, client_ig_intr_md.packet_version, client_ig_intr_md.resubmit_flag, client_ig_intr_md.valid, client_ig_intr_prsr_md.global_tstamp, client_ig_intr_prsr_md.global_ver, client_ig_intr_prsr_md.parser_err, client_ig_intr_tm_md.bypass_egress, client_ig_intr_tm_md.copy_to_cpu, client_ig_intr_tm_md.deflect_on_drop, client_ig_intr_tm_md.disable_ucast_cutthru, client_ig_intr_tm_md.enable_mcast_cutthru, client_ig_intr_tm_md.icos_for_copy_to_cpu, client_ig_intr_tm_md.ingress_cos, client_ig_intr_tm_md.level1_exclusion_id, client_ig_intr_tm_md.level1_mcast_hash, client_ig_intr_tm_md.level2_exclusion_id, client_ig_intr_tm_md.level2_mcast_hash, client_ig_intr_tm_md.mcast_grp_a, client_ig_intr_tm_md.mcast_grp_b, client_ig_intr_tm_md.packet_color, client_ig_intr_tm_md.qid, client_ig_intr_tm_md.rid, client_ig_md.client_id, client_ig_md.clone_md, client_ig_md.dequeued_mode, client_ig_md.do_resubmit, client_ig_md.dropped, client_ig_md.dst_ip, client_ig_md.empty_slots, client_ig_md.empty_slots_before_pop, client_ig_md.failure_status, client_ig_md.head, client_ig_md.ing_mir_ses, client_ig_md.ip_address, client_ig_md.left, client_ig_md.length_in_server, client_ig_md.lock_exist, client_ig_md.lock_id, client_ig_md.locked, client_ig_md.mode, client_ig_md.pkt_type, client_ig_md.queue_size_op, client_ig_md.recirc_flag, client_ig_md.recirced, client_ig_md.right, client_ig_md.routed, client_ig_md.size_of_queue, client_ig_md.src_ip, client_ig_md.tail, client_ig_md.tid, client_ig_md.timestamp_hi, client_ig_md.timestamp_lo, client_ig_md.ts_hi, client_ig_md.ts_lo, client_inbox_count, client_pkt_external, dsl_phase, procurator_bad, procurator_step, sw_SwitchEgress_change_mode_table.action_run, sw_SwitchEgress_change_mode_table.hit, sw_SwitchEgress_change_op_type_table.action_run, sw_SwitchEgress_change_op_type_table.hit, sw_SwitchEgress_test_table.action_run, sw_SwitchEgress_test_table.hit, sw_SwitchIngress_acquire_lock_acquire_lock_table.action_run, sw_SwitchIngress_acquire_lock_acquire_lock_table.hit, sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action_run, sw_SwitchIngress_acquire_lock_dec_empty_slots_table.hit, sw_SwitchIngress_acquire_lock_drop_packet_table.action_run, sw_SwitchIngress_acquire_lock_drop_packet_table.hit, sw_SwitchIngress_acquire_lock_fix_src_port_table.action_run, sw_SwitchIngress_acquire_lock_fix_src_port_table.hit, sw_SwitchIngress_acquire_lock_forward_to_server_table.action_run, sw_SwitchIngress_acquire_lock_forward_to_server_table.hit, sw_SwitchIngress_acquire_lock_notify_tail_client_table.action_run, sw_SwitchIngress_acquire_lock_notify_tail_client_table.hit, sw_SwitchIngress_acquire_lock_set_tag_table.action_run, sw_SwitchIngress_acquire_lock_set_tag_table.hit, sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action_run, sw_SwitchIngress_acquire_lock_switch_direct_grant_table.hit, sw_SwitchIngress_acquire_lock_update_client_id_array_table.action_run, sw_SwitchIngress_acquire_lock_update_client_id_array_table.hit, sw_SwitchIngress_acquire_lock_update_ip_array_table.action_run, sw_SwitchIngress_acquire_lock_update_ip_array_table.hit, sw_SwitchIngress_acquire_lock_update_mode_array_table.action_run, sw_SwitchIngress_acquire_lock_update_mode_array_table.hit, sw_SwitchIngress_acquire_lock_update_tail_table.action_run, sw_SwitchIngress_acquire_lock_update_tail_table.hit, sw_SwitchIngress_acquire_lock_update_tid_array_table.action_run, sw_SwitchIngress_acquire_lock_update_tid_array_table.hit, sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action_run, sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.hit, sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action_run, sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.hit, sw_SwitchIngress_check_lock_exist_table.SwitchIngress_check_lock_exist_action.index_1, sw_SwitchIngress_check_lock_exist_table.action_run, sw_SwitchIngress_check_lock_exist_table.hit, sw_SwitchIngress_decode_decode_table.action_run, sw_SwitchIngress_decode_decode_table.hit, sw_SwitchIngress_decode_get_left_bound_table.action_run, sw_SwitchIngress_decode_get_left_bound_table.hit, sw_SwitchIngress_decode_get_right_bound_table.action_run, sw_SwitchIngress_decode_get_right_bound_table.hit, sw_SwitchIngress_decode_get_size_of_queue_table.action_run, sw_SwitchIngress_decode_get_size_of_queue_table.hit, sw_SwitchIngress_fix_src_port_table.action_run, sw_SwitchIngress_fix_src_port_table.hit, sw_SwitchIngress_forward_to_server_table.action_run, sw_SwitchIngress_forward_to_server_table.hit, sw_SwitchIngress_i2e_clone_table.action_run, sw_SwitchIngress_i2e_clone_table.hit, sw_SwitchIngress_ipv4_route_table.action_run, sw_SwitchIngress_ipv4_route_table.hit, sw_SwitchIngress_ipv4_route_table_2.action_run, sw_SwitchIngress_ipv4_route_table_2.hit, sw_SwitchIngress_release_lock_drop_packet_table.action_run, sw_SwitchIngress_release_lock_drop_packet_table.hit, sw_SwitchIngress_release_lock_fix_src_port_table.action_run, sw_SwitchIngress_release_lock_fix_src_port_table.hit, sw_SwitchIngress_release_lock_forward_to_server_table.action_run, sw_SwitchIngress_release_lock_forward_to_server_table.hit, sw_SwitchIngress_release_lock_get_client_id_table.action_run, sw_SwitchIngress_release_lock_get_client_id_table.hit, sw_SwitchIngress_release_lock_get_ip_table.action_run, sw_SwitchIngress_release_lock_get_ip_table.hit, sw_SwitchIngress_release_lock_get_mode_table.action_run, sw_SwitchIngress_release_lock_get_mode_table.hit, sw_SwitchIngress_release_lock_get_recirc_info_table.action_run, sw_SwitchIngress_release_lock_get_recirc_info_table.hit, sw_SwitchIngress_release_lock_get_tail_table.action_run, sw_SwitchIngress_release_lock_get_tail_table.hit, sw_SwitchIngress_release_lock_get_tid_table.action_run, sw_SwitchIngress_release_lock_get_tid_table.hit, sw_SwitchIngress_release_lock_get_timestamp_hi_table.action_run, sw_SwitchIngress_release_lock_get_timestamp_hi_table.hit, sw_SwitchIngress_release_lock_get_timestamp_lo_table.action_run, sw_SwitchIngress_release_lock_get_timestamp_lo_table.hit, sw_SwitchIngress_release_lock_i2e_mirror_table.action_run, sw_SwitchIngress_release_lock_i2e_mirror_table.hit, sw_SwitchIngress_release_lock_inc_empty_slots_table.action_run, sw_SwitchIngress_release_lock_inc_empty_slots_table.hit, sw_SwitchIngress_release_lock_metahead_plus_1_table.action_run, sw_SwitchIngress_release_lock_metahead_plus_1_table.hit, sw_SwitchIngress_release_lock_metahead_plus_2_table.action_run, sw_SwitchIngress_release_lock_metahead_plus_2_table.hit, sw_SwitchIngress_release_lock_notify_head_client_table.action_run, sw_SwitchIngress_release_lock_notify_head_client_table.hit, sw_SwitchIngress_release_lock_set_tag_table.action_run, sw_SwitchIngress_release_lock_set_tag_table.hit, sw_SwitchIngress_release_lock_update_head_table.action_run, sw_SwitchIngress_release_lock_update_head_table.hit, sw_SwitchIngress_release_lock_update_lock_table.action_run, sw_SwitchIngress_release_lock_update_lock_table.hit, sw_SwitchIngress_set_tag_table.action_run, sw_SwitchIngress_set_tag_table.hit, sw___ra_ret_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_ret_SwitchIngress_acquire_lock_push_back_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_client_id_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_ip_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_mode_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_tid_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw___ra_ret_SwitchIngress_decode_get_left_bound_alu, sw___ra_ret_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_ret_SwitchIngress_decode_get_right_bound_alu, sw___ra_ret_SwitchIngress_release_lock_get_client_id_alu, sw___ra_ret_SwitchIngress_release_lock_get_ip_alu, sw___ra_ret_SwitchIngress_release_lock_get_mode_alu, sw___ra_ret_SwitchIngress_release_lock_get_tail_alu, sw___ra_ret_SwitchIngress_release_lock_get_tid_alu, sw___ra_ret_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_ret_SwitchIngress_release_lock_update_head_alu, sw___ra_ret_SwitchIngress_release_lock_update_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_val_SwitchIngress_acquire_lock_push_back_alu, sw___ra_val_SwitchIngress_acquire_lock_update_client_id_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_ip_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_mode_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tid_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw___ra_val_SwitchIngress_decode_get_left_bound_alu, sw___ra_val_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_val_SwitchIngress_decode_get_right_bound_alu, sw___ra_val_SwitchIngress_release_lock_get_client_id_alu, sw___ra_val_SwitchIngress_release_lock_get_ip_alu, sw___ra_val_SwitchIngress_release_lock_get_mode_alu, sw___ra_val_SwitchIngress_release_lock_get_tail_alu, sw___ra_val_SwitchIngress_release_lock_get_tid_alu, sw___ra_val_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_val_SwitchIngress_release_lock_update_head_alu, sw___ra_val_SwitchIngress_release_lock_update_lock_alu, sw_client_id_array_register, sw_client_id_array_register__dbg0, sw_client_id_array_register__last0_old_value, sw_client_id_array_register__last0_old_value__dbg, sw_client_id_array_register__last0_value, sw_client_id_array_register__last0_value__dbg, sw_client_id_array_register__last_index, sw_client_id_array_register__last_index__dbg, sw_client_id_array_register__last_old_value, sw_client_id_array_register__last_old_value__dbg, sw_client_id_array_register__last_value, sw_client_id_array_register__last_value__dbg, sw_client_id_array_register__last_write_site, sw_client_id_array_register__next_write_site, sw_client_id_array_register__wrote_any, sw_client_id_array_register__wrote_any__dbg, sw_client_id_array_register__wrote_index0, sw_client_id_array_register__wrote_index0__dbg, sw_drop, sw_eg_intr_dprs_md.coalesce_flush, sw_eg_intr_dprs_md.coalesce_length, sw_eg_intr_dprs_md.drop_ctl, sw_eg_intr_dprs_md.mirror_type, sw_eg_intr_md._pad0, sw_eg_intr_md._pad1, sw_eg_intr_md._pad10, sw_eg_intr_md._pad2, sw_eg_intr_md._pad3, sw_eg_intr_md._pad4, sw_eg_intr_md._pad5, sw_eg_intr_md._pad6, sw_eg_intr_md._pad7, sw_eg_intr_md._pad8, sw_eg_intr_md._pad9, sw_eg_intr_md.app_pool_congest_stat, sw_eg_intr_md.deflection_flag, sw_eg_intr_md.deq_congest_stat, sw_eg_intr_md.deq_qdepth, sw_eg_intr_md.deq_timedelta, sw_eg_intr_md.egress_cos, sw_eg_intr_md.egress_qid, sw_eg_intr_md.egress_rid, sw_eg_intr_md.egress_rid_first, sw_eg_intr_md.enq_congest_stat, sw_eg_intr_md.enq_qdepth, sw_eg_intr_md.enq_tstamp, sw_eg_intr_md.pkt_length, sw_eg_intr_md.valid, sw_eg_intr_oport_md.capture_tstamp_on_tx, sw_eg_intr_oport_md.update_delay_on_tx, sw_eg_md.client_id, sw_eg_md.clone_md, sw_eg_md.dequeued_mode, sw_eg_md.do_resubmit, sw_eg_md.dropped, sw_eg_md.dst_ip, sw_eg_md.empty_slots, sw_eg_md.empty_slots_before_pop, sw_eg_md.failure_status, sw_eg_md.head, sw_eg_md.ing_mir_ses, sw_eg_md.ip_address, sw_eg_md.left, sw_eg_md.length_in_server, sw_eg_md.lock_exist, sw_eg_md.lock_id, sw_eg_md.locked, sw_eg_md.mode, sw_eg_md.pkt_type, sw_eg_md.queue_size_op, sw_eg_md.recirc_flag, sw_eg_md.recirced, sw_eg_md.right, sw_eg_md.routed, sw_eg_md.size_of_queue, sw_eg_md.src_ip, sw_eg_md.tail, sw_eg_md.tid, sw_eg_md.timestamp_hi, sw_eg_md.timestamp_lo, sw_eg_md.ts_hi, sw_eg_md.ts_lo, sw_failure_status_register__dbg0, sw_failure_status_register__last0_old_value, sw_failure_status_register__last0_old_value__dbg, sw_failure_status_register__last0_value, sw_failure_status_register__last0_value__dbg, sw_failure_status_register__last_index, sw_failure_status_register__last_index__dbg, sw_failure_status_register__last_old_value, sw_failure_status_register__last_old_value__dbg, sw_failure_status_register__last_value, sw_failure_status_register__last_value__dbg, sw_failure_status_register__last_write_site, sw_failure_status_register__next_write_site, sw_failure_status_register__wrote_any, sw_failure_status_register__wrote_any__dbg, sw_failure_status_register__wrote_index0, sw_failure_status_register__wrote_index0__dbg, sw_hdr.adm_hdr.lock, sw_hdr.adm_hdr.new_left, sw_hdr.adm_hdr.new_right, sw_hdr.adm_hdr.op, sw_hdr.adm_hdr.valid, sw_hdr.bridged_md.pkt_type, sw_hdr.bridged_md.valid, sw_hdr.ethernet.dstAddr, sw_hdr.ethernet.etherType, sw_hdr.ethernet.srcAddr, sw_hdr.ethernet.valid, sw_hdr.ipv4.diffserv, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.flags, sw_hdr.ipv4.fragOffset, sw_hdr.ipv4.hdrChecksum, sw_hdr.ipv4.identification, sw_hdr.ipv4.ihl, sw_hdr.ipv4.protocol, sw_hdr.ipv4.srcAddr, sw_hdr.ipv4.totalLen, sw_hdr.ipv4.ttl, sw_hdr.ipv4.valid, sw_hdr.ipv4.version, sw_hdr.nlk_hdr.client_id, sw_hdr.nlk_hdr.empty_slots, sw_hdr.nlk_hdr.head, sw_hdr.nlk_hdr.lock, sw_hdr.nlk_hdr.mode, sw_hdr.nlk_hdr.ncnt, sw_hdr.nlk_hdr.op, sw_hdr.nlk_hdr.recirc_flag, sw_hdr.nlk_hdr.tail, sw_hdr.nlk_hdr.tid, sw_hdr.nlk_hdr.timestamp_hi, sw_hdr.nlk_hdr.timestamp_lo, sw_hdr.nlk_hdr.transferred, sw_hdr.nlk_hdr.valid, sw_hdr.probe_hdr.client_id, sw_hdr.probe_hdr.failure_status, sw_hdr.probe_hdr.lock, sw_hdr.probe_hdr.mode, sw_hdr.probe_hdr.op, sw_hdr.probe_hdr.tid, sw_hdr.probe_hdr.timestamp_hi, sw_hdr.probe_hdr.timestamp_lo, sw_hdr.probe_hdr.valid, sw_hdr.recirculate_hdr.cur_head, sw_hdr.recirculate_hdr.cur_tail, sw_hdr.recirculate_hdr.dequeued_mode, sw_hdr.recirculate_hdr.valid, sw_hdr.tcp.ackNo, sw_hdr.tcp.checksum, sw_hdr.tcp.ctrl, sw_hdr.tcp.dataOffset, sw_hdr.tcp.dstPort, sw_hdr.tcp.ecn, sw_hdr.tcp.res, sw_hdr.tcp.seqNo, sw_hdr.tcp.srcPort, sw_hdr.tcp.urgentPtr, sw_hdr.tcp.valid, sw_hdr.tcp.window, sw_hdr.udp.checksum, sw_hdr.udp.dstPort, sw_hdr.udp.pkt_length, sw_hdr.udp.srcPort, sw_hdr.udp.valid, sw_head_register, sw_head_register__dbg0, sw_head_register__last0_old_value, sw_head_register__last0_old_value__dbg, sw_head_register__last0_value, sw_head_register__last0_value__dbg, sw_head_register__last_index, sw_head_register__last_index__dbg, sw_head_register__last_old_value, sw_head_register__last_old_value__dbg, sw_head_register__last_value, sw_head_register__last_value__dbg, sw_head_register__last_write_site, sw_head_register__next_write_site, sw_head_register__wrote_any, sw_head_register__wrote_any__dbg, sw_head_register__wrote_index0, sw_head_register__wrote_index0__dbg, sw_ig_intr_dprsr_md.digest_type, sw_ig_intr_dprsr_md.drop_ctl, sw_ig_intr_dprsr_md.mirror_type, sw_ig_intr_dprsr_md.resubmit_type, sw_ig_intr_md._pad1, sw_ig_intr_md._pad2, sw_ig_intr_md.ingress_mac_tstamp, sw_ig_intr_md.ingress_port, sw_ig_intr_md.packet_version, sw_ig_intr_md.resubmit_flag, sw_ig_intr_md.valid, sw_ig_intr_prsr_md.global_tstamp, sw_ig_intr_prsr_md.global_ver, sw_ig_intr_prsr_md.parser_err, sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.copy_to_cpu, sw_ig_intr_tm_md.deflect_on_drop, sw_ig_intr_tm_md.disable_ucast_cutthru, sw_ig_intr_tm_md.enable_mcast_cutthru, sw_ig_intr_tm_md.icos_for_copy_to_cpu, sw_ig_intr_tm_md.ingress_cos, sw_ig_intr_tm_md.level1_exclusion_id, sw_ig_intr_tm_md.level1_mcast_hash, sw_ig_intr_tm_md.level2_exclusion_id, sw_ig_intr_tm_md.level2_mcast_hash, sw_ig_intr_tm_md.mcast_grp_a, sw_ig_intr_tm_md.mcast_grp_b, sw_ig_intr_tm_md.packet_color, sw_ig_intr_tm_md.qid, sw_ig_intr_tm_md.rid, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.client_id, sw_ig_md.clone_md, sw_ig_md.dequeued_mode, sw_ig_md.do_resubmit, sw_ig_md.dropped, sw_ig_md.dst_ip, sw_ig_md.empty_slots, sw_ig_md.empty_slots_before_pop, sw_ig_md.failure_status, sw_ig_md.head, sw_ig_md.ing_mir_ses, sw_ig_md.ip_address, sw_ig_md.left, sw_ig_md.length_in_server, sw_ig_md.lock_exist, sw_ig_md.lock_id, sw_ig_md.locked, sw_ig_md.mode, sw_ig_md.pkt_type, sw_ig_md.queue_size_op, sw_ig_md.recirc_flag, sw_ig_md.recirced, sw_ig_md.right, sw_ig_md.routed, sw_ig_md.size_of_queue, sw_ig_md.src_ip, sw_ig_md.tail, sw_ig_md.tid, sw_ig_md.timestamp_hi, sw_ig_md.timestamp_lo, sw_ig_md.ts_hi, sw_ig_md.ts_lo, sw_inbox_count, sw_ip_array_register, sw_ip_array_register__dbg0, sw_ip_array_register__last0_old_value, sw_ip_array_register__last0_old_value__dbg, sw_ip_array_register__last0_value, sw_ip_array_register__last0_value__dbg, sw_ip_array_register__last_index, sw_ip_array_register__last_index__dbg, sw_ip_array_register__last_old_value, sw_ip_array_register__last_old_value__dbg, sw_ip_array_register__last_value, sw_ip_array_register__last_value__dbg, sw_ip_array_register__last_write_site, sw_ip_array_register__next_write_site, sw_ip_array_register__wrote_any, sw_ip_array_register__wrote_any__dbg, sw_ip_array_register__wrote_index0, sw_ip_array_register__wrote_index0__dbg, sw_isValid, sw_left_bound_register, sw_left_bound_register__dbg0, sw_left_bound_register__last0_old_value, sw_left_bound_register__last0_old_value__dbg, sw_left_bound_register__last0_value, sw_left_bound_register__last0_value__dbg, sw_left_bound_register__last_index, sw_left_bound_register__last_index__dbg, sw_left_bound_register__last_old_value, sw_left_bound_register__last_old_value__dbg, sw_left_bound_register__last_value, sw_left_bound_register__last_value__dbg, sw_left_bound_register__last_write_site, sw_left_bound_register__next_write_site, sw_left_bound_register__wrote_any, sw_left_bound_register__wrote_any__dbg, sw_left_bound_register__wrote_index0, sw_left_bound_register__wrote_index0__dbg, sw_mirror_hdr_0, sw_mirror_md_0, sw_mode_array_register, sw_mode_array_register__dbg0, sw_mode_array_register__last0_old_value, sw_mode_array_register__last0_old_value__dbg, sw_mode_array_register__last0_value, sw_mode_array_register__last0_value__dbg, sw_mode_array_register__last_index, sw_mode_array_register__last_index__dbg, sw_mode_array_register__last_old_value, sw_mode_array_register__last_old_value__dbg, sw_mode_array_register__last_value, sw_mode_array_register__last_value__dbg, sw_mode_array_register__last_write_site, sw_mode_array_register__next_write_site, sw_mode_array_register__wrote_any, sw_mode_array_register__wrote_any__dbg, sw_mode_array_register__wrote_index0, sw_mode_array_register__wrote_index0__dbg, sw_p4b_checksum_error, sw_p4b_checksum_updated, sw_p4b_checksum_verified, sw_p4b_clone_e2e, sw_p4b_clone_i2e, sw_p4b_clone_i2i, sw_p4b_digest, sw_p4b_recirculate, sw_pkt_external, sw_queue_size_op_register, sw_queue_size_op_register__dbg0, sw_queue_size_op_register__last0_old_value, sw_queue_size_op_register__last0_old_value__dbg, sw_queue_size_op_register__last0_value, sw_queue_size_op_register__last0_value__dbg, sw_queue_size_op_register__last_index, sw_queue_size_op_register__last_index__dbg, sw_queue_size_op_register__last_old_value, sw_queue_size_op_register__last_old_value__dbg, sw_queue_size_op_register__last_value, sw_queue_size_op_register__last_value__dbg, sw_queue_size_op_register__last_write_site, sw_queue_size_op_register__next_write_site, sw_queue_size_op_register__wrote_any, sw_queue_size_op_register__wrote_any__dbg, sw_queue_size_op_register__wrote_index0, sw_queue_size_op_register__wrote_index0__dbg, sw_right_bound_register, sw_right_bound_register__dbg0, sw_right_bound_register__last0_old_value, sw_right_bound_register__last0_old_value__dbg, sw_right_bound_register__last0_value, sw_right_bound_register__last0_value__dbg, sw_right_bound_register__last_index, sw_right_bound_register__last_index__dbg, sw_right_bound_register__last_old_value, sw_right_bound_register__last_old_value__dbg, sw_right_bound_register__last_value, sw_right_bound_register__last_value__dbg, sw_right_bound_register__last_write_site, sw_right_bound_register__next_write_site, sw_right_bound_register__wrote_any, sw_right_bound_register__wrote_any__dbg, sw_right_bound_register__wrote_index0, sw_right_bound_register__wrote_index0__dbg, sw_shared_and_exclusive_count_register, sw_shared_and_exclusive_count_register__dbg0, sw_shared_and_exclusive_count_register__last0_old_value, sw_shared_and_exclusive_count_register__last0_old_value__dbg, sw_shared_and_exclusive_count_register__last0_value, sw_shared_and_exclusive_count_register__last0_value__dbg, sw_shared_and_exclusive_count_register__last_index, sw_shared_and_exclusive_count_register__last_index__dbg, sw_shared_and_exclusive_count_register__last_old_value, sw_shared_and_exclusive_count_register__last_old_value__dbg, sw_shared_and_exclusive_count_register__last_value, sw_shared_and_exclusive_count_register__last_value__dbg, sw_shared_and_exclusive_count_register__last_write_site, sw_shared_and_exclusive_count_register__next_write_site, sw_shared_and_exclusive_count_register__wrote_any, sw_shared_and_exclusive_count_register__wrote_any__dbg, sw_shared_and_exclusive_count_register__wrote_index0, sw_shared_and_exclusive_count_register__wrote_index0__dbg, sw_slots_two_sides_register, sw_slots_two_sides_register__dbg0, sw_slots_two_sides_register__last0_old_value, sw_slots_two_sides_register__last0_old_value__dbg, sw_slots_two_sides_register__last0_value, sw_slots_two_sides_register__last0_value__dbg, sw_slots_two_sides_register__last_index, sw_slots_two_sides_register__last_index__dbg, sw_slots_two_sides_register__last_old_value, sw_slots_two_sides_register__last_old_value__dbg, sw_slots_two_sides_register__last_value, sw_slots_two_sides_register__last_value__dbg, sw_slots_two_sides_register__last_write_site, sw_slots_two_sides_register__next_write_site, sw_slots_two_sides_register__wrote_any, sw_slots_two_sides_register__wrote_any__dbg, sw_slots_two_sides_register__wrote_index0, sw_slots_two_sides_register__wrote_index0__dbg, sw_tail_register, sw_tail_register__dbg0, sw_tail_register__last0_old_value, sw_tail_register__last0_old_value__dbg, sw_tail_register__last0_value, sw_tail_register__last0_value__dbg, sw_tail_register__last_index, sw_tail_register__last_index__dbg, sw_tail_register__last_old_value, sw_tail_register__last_old_value__dbg, sw_tail_register__last_value, sw_tail_register__last_value__dbg, sw_tail_register__last_write_site, sw_tail_register__next_write_site, sw_tail_register__wrote_any, sw_tail_register__wrote_any__dbg, sw_tail_register__wrote_index0, sw_tail_register__wrote_index0__dbg, sw_tenant_acq_counter_register__dbg0, sw_tenant_acq_counter_register__last0_old_value, sw_tenant_acq_counter_register__last0_old_value__dbg, sw_tenant_acq_counter_register__last0_value, sw_tenant_acq_counter_register__last0_value__dbg, sw_tenant_acq_counter_register__last_index, sw_tenant_acq_counter_register__last_index__dbg, sw_tenant_acq_counter_register__last_old_value, sw_tenant_acq_counter_register__last_old_value__dbg, sw_tenant_acq_counter_register__last_value, sw_tenant_acq_counter_register__last_value__dbg, sw_tenant_acq_counter_register__last_write_site, sw_tenant_acq_counter_register__next_write_site, sw_tenant_acq_counter_register__wrote_any, sw_tenant_acq_counter_register__wrote_any__dbg, sw_tenant_acq_counter_register__wrote_index0, sw_tenant_acq_counter_register__wrote_index0__dbg, sw_tid_array_register, sw_tid_array_register__dbg0, sw_tid_array_register__last0_old_value, sw_tid_array_register__last0_old_value__dbg, sw_tid_array_register__last0_value, sw_tid_array_register__last0_value__dbg, sw_tid_array_register__last_index, sw_tid_array_register__last_index__dbg, sw_tid_array_register__last_old_value, sw_tid_array_register__last_old_value__dbg, sw_tid_array_register__last_value, sw_tid_array_register__last_value__dbg, sw_tid_array_register__last_write_site, sw_tid_array_register__next_write_site, sw_tid_array_register__wrote_any, sw_tid_array_register__wrote_any__dbg, sw_tid_array_register__wrote_index0, sw_tid_array_register__wrote_index0__dbg, sw_timestamp_hi_array_register, sw_timestamp_hi_array_register__dbg0, sw_timestamp_hi_array_register__last0_old_value, sw_timestamp_hi_array_register__last0_old_value__dbg, sw_timestamp_hi_array_register__last0_value, sw_timestamp_hi_array_register__last0_value__dbg, sw_timestamp_hi_array_register__last_index, sw_timestamp_hi_array_register__last_index__dbg, sw_timestamp_hi_array_register__last_old_value, sw_timestamp_hi_array_register__last_old_value__dbg, sw_timestamp_hi_array_register__last_value, sw_timestamp_hi_array_register__last_value__dbg, sw_timestamp_hi_array_register__last_write_site, sw_timestamp_hi_array_register__next_write_site, sw_timestamp_hi_array_register__wrote_any, sw_timestamp_hi_array_register__wrote_any__dbg, sw_timestamp_hi_array_register__wrote_index0, sw_timestamp_hi_array_register__wrote_index0__dbg, sw_timestamp_lo_array_register, sw_timestamp_lo_array_register__dbg0, sw_timestamp_lo_array_register__last0_old_value, sw_timestamp_lo_array_register__last0_old_value__dbg, sw_timestamp_lo_array_register__last0_value, sw_timestamp_lo_array_register__last0_value__dbg, sw_timestamp_lo_array_register__last_index, sw_timestamp_lo_array_register__last_index__dbg, sw_timestamp_lo_array_register__last_old_value, sw_timestamp_lo_array_register__last_old_value__dbg, sw_timestamp_lo_array_register__last_value, sw_timestamp_lo_array_register__last_value__dbg, sw_timestamp_lo_array_register__last_write_site, sw_timestamp_lo_array_register__next_write_site, sw_timestamp_lo_array_register__wrote_any, sw_timestamp_lo_array_register__wrote_any__dbg, sw_timestamp_lo_array_register__wrote_index0, sw_timestamp_lo_array_register__wrote_index0__dbg, sw_tmp;
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
  dsl_phase := 0;
  // initialize P4 registers (default 0)
  assume (forall i:bv32 :: sw_client_id_array_register[i] == 0bv8);
  assume sw_client_id_array_register[0bv32] == 0bv8;
  assume sw_failure_status_register[0bv1] == 0bv8;
  assume (forall i:bv32 :: ((i != 0bv32)) ==> sw_head_register[i] == 0bv32);
  assume sw_head_register[0bv32] == 0bv32;
  assume sw_head_register[0bv32] == 0bv32;
  assume (forall i:bv32 :: sw_ip_array_register[i] == 0bv32);
  assume sw_ip_array_register[0bv32] == 0bv32;
  assume (forall i:bv32 :: ((i != 0bv32)) ==> sw_left_bound_register[i] == 0bv32);
  assume sw_left_bound_register[0bv32] == 0bv32;
  assume sw_left_bound_register[0bv32] == 0bv32;
  assume (forall i:bv32 :: sw_mode_array_register[i] == 0bv8);
  assume sw_mode_array_register[0bv32] == 0bv8;
  assume (forall i:bv32 :: ((i != 0bv32)) ==> sw_queue_size_op_register[i] == 0bv32);
  assume sw_queue_size_op_register[0bv32] == 0bv32;
  assume sw_queue_size_op_register[0bv32] == 0bv32;
  assume (forall i:bv32 :: ((i != 0bv32)) ==> sw_right_bound_register[i] == 0bv32);
  assume sw_right_bound_register[0bv32] == 9bv32;
  assume sw_right_bound_register[0bv32] == 9bv32;
  assume (forall i:bv32 :: ((i != 0bv32)) ==> sw_shared_and_exclusive_count_register[i] == 0bv64);
  assume sw_shared_and_exclusive_count_register[0bv32] == 0bv64;
  assume sw_shared_and_exclusive_count_register[0bv32] == 0bv64;
  assume (forall i:bv32 :: ((i != 0bv32)) ==> sw_slots_two_sides_register[i] == 0bv64);
  assume sw_slots_two_sides_register[0bv32] == 0bv64;
  assume sw_slots_two_sides_register[0bv32] == 0bv64;
  assume (forall i:bv32 :: ((i != 0bv32)) ==> sw_tail_register[i] == 0bv32);
  assume sw_tail_register[0bv32] == 0bv32;
  assume sw_tail_register[0bv32] == 0bv32;
  assume sw_tenant_acq_counter_register[0bv4] == 0bv32;
  assume (forall i:bv32 :: sw_tid_array_register[i] == 0bv32);
  assume sw_tid_array_register[0bv32] == 0bv32;
  assume (forall i:bv32 :: sw_timestamp_hi_array_register[i] == 0bv32);
  assume sw_timestamp_hi_array_register[0bv32] == 0bv32;
  assume (forall i:bv32 :: sw_timestamp_lo_array_register[i] == 0bv32);
  assume sw_timestamp_lo_array_register[0bv32] == 0bv32;
  // initialize register write tracking (debug)
  sw_client_id_array_register__last_index := 0bv32;
  sw_client_id_array_register__last_value := 0bv8;
  sw_client_id_array_register__last_old_value := 0bv8;
  sw_client_id_array_register__wrote_any := false;
  sw_client_id_array_register__wrote_index0 := false;
  sw_client_id_array_register__next_write_site := 0;
  sw_client_id_array_register__last_write_site := 0;
  sw_client_id_array_register__last0_old_value := 0bv8;
  sw_client_id_array_register__last0_value := 0bv8;
  sw_failure_status_register__last_index := 0bv1;
  sw_failure_status_register__last_value := 0bv8;
  sw_failure_status_register__last_old_value := 0bv8;
  sw_failure_status_register__wrote_any := false;
  sw_failure_status_register__wrote_index0 := false;
  sw_failure_status_register__next_write_site := 0;
  sw_failure_status_register__last_write_site := 0;
  sw_failure_status_register__last0_old_value := 0bv8;
  sw_failure_status_register__last0_value := 0bv8;
  sw_head_register__last_index := 0bv32;
  sw_head_register__last_value := 0bv32;
  sw_head_register__last_old_value := 0bv32;
  sw_head_register__wrote_any := false;
  sw_head_register__wrote_index0 := false;
  sw_head_register__next_write_site := 0;
  sw_head_register__last_write_site := 0;
  sw_head_register__last0_old_value := 0bv32;
  sw_head_register__last0_value := 0bv32;
  sw_ip_array_register__last_index := 0bv32;
  sw_ip_array_register__last_value := 0bv32;
  sw_ip_array_register__last_old_value := 0bv32;
  sw_ip_array_register__wrote_any := false;
  sw_ip_array_register__wrote_index0 := false;
  sw_ip_array_register__next_write_site := 0;
  sw_ip_array_register__last_write_site := 0;
  sw_ip_array_register__last0_old_value := 0bv32;
  sw_ip_array_register__last0_value := 0bv32;
  sw_left_bound_register__last_index := 0bv32;
  sw_left_bound_register__last_value := 0bv32;
  sw_left_bound_register__last_old_value := 0bv32;
  sw_left_bound_register__wrote_any := false;
  sw_left_bound_register__wrote_index0 := false;
  sw_left_bound_register__next_write_site := 0;
  sw_left_bound_register__last_write_site := 0;
  sw_left_bound_register__last0_old_value := 0bv32;
  sw_left_bound_register__last0_value := 0bv32;
  sw_mode_array_register__last_index := 0bv32;
  sw_mode_array_register__last_value := 0bv8;
  sw_mode_array_register__last_old_value := 0bv8;
  sw_mode_array_register__wrote_any := false;
  sw_mode_array_register__wrote_index0 := false;
  sw_mode_array_register__next_write_site := 0;
  sw_mode_array_register__last_write_site := 0;
  sw_mode_array_register__last0_old_value := 0bv8;
  sw_mode_array_register__last0_value := 0bv8;
  sw_queue_size_op_register__last_index := 0bv32;
  sw_queue_size_op_register__last_value := 0bv32;
  sw_queue_size_op_register__last_old_value := 0bv32;
  sw_queue_size_op_register__wrote_any := false;
  sw_queue_size_op_register__wrote_index0 := false;
  sw_queue_size_op_register__next_write_site := 0;
  sw_queue_size_op_register__last_write_site := 0;
  sw_queue_size_op_register__last0_old_value := 0bv32;
  sw_queue_size_op_register__last0_value := 0bv32;
  sw_right_bound_register__last_index := 0bv32;
  sw_right_bound_register__last_value := 0bv32;
  sw_right_bound_register__last_old_value := 0bv32;
  sw_right_bound_register__wrote_any := false;
  sw_right_bound_register__wrote_index0 := false;
  sw_right_bound_register__next_write_site := 0;
  sw_right_bound_register__last_write_site := 0;
  sw_right_bound_register__last0_old_value := 0bv32;
  sw_right_bound_register__last0_value := 0bv32;
  sw_shared_and_exclusive_count_register__last_index := 0bv32;
  sw_shared_and_exclusive_count_register__last_value := 0bv64;
  sw_shared_and_exclusive_count_register__last_old_value := 0bv64;
  sw_shared_and_exclusive_count_register__wrote_any := false;
  sw_shared_and_exclusive_count_register__wrote_index0 := false;
  sw_shared_and_exclusive_count_register__next_write_site := 0;
  sw_shared_and_exclusive_count_register__last_write_site := 0;
  sw_shared_and_exclusive_count_register__last0_old_value := 0bv64;
  sw_shared_and_exclusive_count_register__last0_value := 0bv64;
  sw_slots_two_sides_register__last_index := 0bv32;
  sw_slots_two_sides_register__last_value := 0bv64;
  sw_slots_two_sides_register__last_old_value := 0bv64;
  sw_slots_two_sides_register__wrote_any := false;
  sw_slots_two_sides_register__wrote_index0 := false;
  sw_slots_two_sides_register__next_write_site := 0;
  sw_slots_two_sides_register__last_write_site := 0;
  sw_slots_two_sides_register__last0_old_value := 0bv64;
  sw_slots_two_sides_register__last0_value := 0bv64;
  sw_tail_register__last_index := 0bv32;
  sw_tail_register__last_value := 0bv32;
  sw_tail_register__last_old_value := 0bv32;
  sw_tail_register__wrote_any := false;
  sw_tail_register__wrote_index0 := false;
  sw_tail_register__next_write_site := 0;
  sw_tail_register__last_write_site := 0;
  sw_tail_register__last0_old_value := 0bv32;
  sw_tail_register__last0_value := 0bv32;
  sw_tenant_acq_counter_register__last_index := 0bv4;
  sw_tenant_acq_counter_register__last_value := 0bv32;
  sw_tenant_acq_counter_register__last_old_value := 0bv32;
  sw_tenant_acq_counter_register__wrote_any := false;
  sw_tenant_acq_counter_register__wrote_index0 := false;
  sw_tenant_acq_counter_register__next_write_site := 0;
  sw_tenant_acq_counter_register__last_write_site := 0;
  sw_tenant_acq_counter_register__last0_old_value := 0bv32;
  sw_tenant_acq_counter_register__last0_value := 0bv32;
  sw_tid_array_register__last_index := 0bv32;
  sw_tid_array_register__last_value := 0bv32;
  sw_tid_array_register__last_old_value := 0bv32;
  sw_tid_array_register__wrote_any := false;
  sw_tid_array_register__wrote_index0 := false;
  sw_tid_array_register__next_write_site := 0;
  sw_tid_array_register__last_write_site := 0;
  sw_tid_array_register__last0_old_value := 0bv32;
  sw_tid_array_register__last0_value := 0bv32;
  sw_timestamp_hi_array_register__last_index := 0bv32;
  sw_timestamp_hi_array_register__last_value := 0bv32;
  sw_timestamp_hi_array_register__last_old_value := 0bv32;
  sw_timestamp_hi_array_register__wrote_any := false;
  sw_timestamp_hi_array_register__wrote_index0 := false;
  sw_timestamp_hi_array_register__next_write_site := 0;
  sw_timestamp_hi_array_register__last_write_site := 0;
  sw_timestamp_hi_array_register__last0_old_value := 0bv32;
  sw_timestamp_hi_array_register__last0_value := 0bv32;
  sw_timestamp_lo_array_register__last_index := 0bv32;
  sw_timestamp_lo_array_register__last_value := 0bv32;
  sw_timestamp_lo_array_register__last_old_value := 0bv32;
  sw_timestamp_lo_array_register__wrote_any := false;
  sw_timestamp_lo_array_register__wrote_index0 := false;
  sw_timestamp_lo_array_register__next_write_site := 0;
  sw_timestamp_lo_array_register__last_write_site := 0;
  sw_timestamp_lo_array_register__last0_old_value := 0bv32;
  sw_timestamp_lo_array_register__last0_value := 0bv32;

  procurator_step := 0;
  procurator_bad := false;
  // step 0: host_send -> client
  // inject packet into connected node (host -> node)
  if (sw_inbox_count < 1) {
    assume sw_inbox_count < 1;
    havoc client_hdr.bridged_md.valid;
    havoc client_hdr.bridged_md.pkt_type;
    havoc client_hdr.ethernet.dstAddr;
    havoc client_hdr.ethernet.srcAddr;
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
    havoc client_hdr.tcp.valid;
    havoc client_hdr.tcp.srcPort;
    havoc client_hdr.tcp.dstPort;
    havoc client_hdr.tcp.seqNo;
    havoc client_hdr.tcp.ackNo;
    havoc client_hdr.tcp.dataOffset;
    havoc client_hdr.tcp.res;
    havoc client_hdr.tcp.ecn;
    havoc client_hdr.tcp.ctrl;
    havoc client_hdr.tcp.window;
    havoc client_hdr.tcp.checksum;
    havoc client_hdr.tcp.urgentPtr;
    havoc client_hdr.udp.srcPort;
    havoc client_hdr.udp.pkt_length;
    havoc client_hdr.udp.checksum;
    havoc client_hdr.nlk_hdr.empty_slots;
    havoc client_hdr.nlk_hdr.head;
    havoc client_hdr.nlk_hdr.tail;
    havoc client_hdr.nlk_hdr.ncnt;
    havoc client_hdr.nlk_hdr.transferred;
    havoc client_hdr.adm_hdr.valid;
    havoc client_hdr.adm_hdr.op;
    havoc client_hdr.adm_hdr.lock;
    havoc client_hdr.adm_hdr.new_left;
    havoc client_hdr.adm_hdr.new_right;
    havoc client_hdr.recirculate_hdr.valid;
    havoc client_hdr.recirculate_hdr.dequeued_mode;
    havoc client_hdr.recirculate_hdr.cur_head;
    havoc client_hdr.recirculate_hdr.cur_tail;
    havoc client_hdr.probe_hdr.valid;
    havoc client_hdr.probe_hdr.failure_status;
    havoc client_hdr.probe_hdr.op;
    havoc client_hdr.probe_hdr.mode;
    havoc client_hdr.probe_hdr.client_id;
    havoc client_hdr.probe_hdr.tid;
    havoc client_hdr.probe_hdr.lock;
    havoc client_hdr.probe_hdr.timestamp_lo;
    havoc client_hdr.probe_hdr.timestamp_hi;
    havoc client_eg_md.head;
    havoc client_eg_md.tail;
    havoc client_eg_md.queue_size_op;
    havoc client_eg_md.do_resubmit;
    havoc client_eg_md.routed;
    havoc client_eg_md.dropped;
    havoc client_eg_md.lock_exist;
    havoc client_eg_md.recirc_flag;
    havoc client_eg_md.dequeued_mode;
    havoc client_eg_md.recirced;
    havoc client_eg_md.locked;
    havoc client_eg_md.left;
    havoc client_eg_md.right;
    havoc client_eg_md.src_ip;
    havoc client_eg_md.dst_ip;
    havoc client_eg_md.empty_slots;
    havoc client_eg_md.length_in_server;
    havoc client_eg_md.size_of_queue;
    havoc client_eg_md.empty_slots_before_pop;
    havoc client_eg_md.ts_hi;
    havoc client_eg_md.ts_lo;
    havoc client_eg_md.lock_id;
    havoc client_eg_md.failure_status;
    havoc client_eg_md.ing_mir_ses;
    havoc client_eg_md.clone_md;
    havoc client_eg_md.mode;
    havoc client_eg_md.client_id;
    havoc client_eg_md.tid;
    havoc client_eg_md.ip_address;
    havoc client_eg_md.timestamp_lo;
    havoc client_eg_md.timestamp_hi;
    havoc client_eg_md.pkt_type;
    havoc client_eg_intr_md.valid;
    havoc client_eg_intr_md._pad0;
    havoc client_eg_intr_md._pad1;
    havoc client_eg_intr_md.enq_qdepth;
    havoc client_eg_intr_md._pad2;
    havoc client_eg_intr_md.enq_congest_stat;
    havoc client_eg_intr_md._pad3;
    havoc client_eg_intr_md.enq_tstamp;
    havoc client_eg_intr_md._pad4;
    havoc client_eg_intr_md.deq_qdepth;
    havoc client_eg_intr_md._pad5;
    havoc client_eg_intr_md.deq_congest_stat;
    havoc client_eg_intr_md.app_pool_congest_stat;
    havoc client_eg_intr_md._pad6;
    havoc client_eg_intr_md.deq_timedelta;
    havoc client_eg_intr_md.egress_rid;
    havoc client_eg_intr_md._pad7;
    havoc client_eg_intr_md.egress_rid_first;
    havoc client_eg_intr_md._pad8;
    havoc client_eg_intr_md.egress_qid;
    havoc client_eg_intr_md._pad9;
    havoc client_eg_intr_md.egress_cos;
    havoc client_eg_intr_md._pad10;
    havoc client_eg_intr_md.deflection_flag;
    havoc client_eg_intr_md.pkt_length;
    havoc client_eg_intr_dprs_md.drop_ctl;
    havoc client_eg_intr_dprs_md.mirror_type;
    havoc client_eg_intr_dprs_md.coalesce_flush;
    havoc client_eg_intr_dprs_md.coalesce_length;
    havoc client_eg_intr_oport_md.capture_tstamp_on_tx;
    havoc client_eg_intr_oport_md.update_delay_on_tx;
    havoc client_ig_md.head;
    havoc client_ig_md.tail;
    havoc client_ig_md.queue_size_op;
    havoc client_ig_md.do_resubmit;
    havoc client_ig_md.routed;
    havoc client_ig_md.dropped;
    havoc client_ig_md.lock_exist;
    havoc client_ig_md.recirc_flag;
    havoc client_ig_md.dequeued_mode;
    havoc client_ig_md.recirced;
    havoc client_ig_md.locked;
    havoc client_ig_md.left;
    havoc client_ig_md.right;
    havoc client_ig_md.src_ip;
    havoc client_ig_md.dst_ip;
    havoc client_ig_md.empty_slots;
    havoc client_ig_md.length_in_server;
    havoc client_ig_md.size_of_queue;
    havoc client_ig_md.empty_slots_before_pop;
    havoc client_ig_md.ts_hi;
    havoc client_ig_md.ts_lo;
    havoc client_ig_md.lock_id;
    havoc client_ig_md.failure_status;
    havoc client_ig_md.ing_mir_ses;
    havoc client_ig_md.clone_md;
    havoc client_ig_md.mode;
    havoc client_ig_md.client_id;
    havoc client_ig_md.tid;
    havoc client_ig_md.ip_address;
    havoc client_ig_md.timestamp_lo;
    havoc client_ig_md.timestamp_hi;
    havoc client_ig_md.pkt_type;
    havoc client_ig_intr_md.valid;
    havoc client_ig_intr_md._pad1;
    havoc client_ig_intr_md.packet_version;
    havoc client_ig_intr_md._pad2;
    havoc client_ig_intr_md.ingress_port;
    havoc client_ig_intr_md.ingress_mac_tstamp;
    havoc client_ig_intr_prsr_md.global_tstamp;
    havoc client_ig_intr_prsr_md.global_ver;
    havoc client_ig_intr_prsr_md.parser_err;
    havoc client_ig_intr_dprsr_md.drop_ctl;
    havoc client_ig_intr_dprsr_md.digest_type;
    havoc client_ig_intr_dprsr_md.resubmit_type;
    havoc client_ig_intr_tm_md.bypass_egress;
    havoc client_ig_intr_tm_md.deflect_on_drop;
    havoc client_ig_intr_tm_md.ingress_cos;
    havoc client_ig_intr_tm_md.qid;
    havoc client_ig_intr_tm_md.icos_for_copy_to_cpu;
    havoc client_ig_intr_tm_md.copy_to_cpu;
    havoc client_ig_intr_tm_md.packet_color;
    havoc client_ig_intr_tm_md.disable_ucast_cutthru;
    havoc client_ig_intr_tm_md.enable_mcast_cutthru;
    havoc client_ig_intr_tm_md.mcast_grp_a;
    havoc client_ig_intr_tm_md.mcast_grp_b;
    havoc client_ig_intr_tm_md.level1_mcast_hash;
    havoc client_ig_intr_tm_md.level2_mcast_hash;
    havoc client_ig_intr_tm_md.level1_exclusion_id;
    havoc client_ig_intr_tm_md.level2_exclusion_id;
    havoc client_ig_intr_tm_md.rid;
    client_hdr.ethernet.valid := true;
    client_hdr.ipv4.valid := true;
    client_hdr.udp.valid := true;
    client_hdr.nlk_hdr.valid := true;
    client_hdr.ethernet.etherType := 2048bv16;
    client_hdr.ipv4.protocol := 17bv8;
    client_hdr.udp.dstPort := 8888bv16;
    client_hdr.nlk_hdr.lock := 0bv32;
    client_hdr.nlk_hdr.client_id := 0bv8;
    client_hdr.nlk_hdr.tid := 0bv32;
    client_hdr.nlk_hdr.timestamp_lo := 0bv32;
    client_hdr.nlk_hdr.timestamp_hi := 0bv32;
    client_hdr.nlk_hdr.recirc_flag := 0bv8;
    client_ig_intr_md.resubmit_flag := 0bv1;
    client_ig_intr_dprsr_md.mirror_type := 0bv3;
    client_hdr.nlk_hdr.op := 2bv8;
    client_hdr.nlk_hdr.mode := 0bv8;
    dsl_phase := 1;
    assume (sw_ig_md.lock_id == 0bv32);
    sw_hdr.bridged_md.valid := client_hdr.bridged_md.valid;
    sw_hdr.bridged_md.pkt_type := client_hdr.bridged_md.pkt_type;
    sw_hdr.ethernet.valid := client_hdr.ethernet.valid;
    sw_hdr.ethernet.dstAddr := client_hdr.ethernet.dstAddr;
    sw_hdr.ethernet.srcAddr := client_hdr.ethernet.srcAddr;
    sw_hdr.ethernet.etherType := client_hdr.ethernet.etherType;
    sw_hdr.ipv4.valid := client_hdr.ipv4.valid;
    sw_hdr.ipv4.version := client_hdr.ipv4.version;
    sw_hdr.ipv4.ihl := client_hdr.ipv4.ihl;
    sw_hdr.ipv4.diffserv := client_hdr.ipv4.diffserv;
    sw_hdr.ipv4.totalLen := client_hdr.ipv4.totalLen;
    sw_hdr.ipv4.identification := client_hdr.ipv4.identification;
    sw_hdr.ipv4.flags := client_hdr.ipv4.flags;
    sw_hdr.ipv4.fragOffset := client_hdr.ipv4.fragOffset;
    sw_hdr.ipv4.ttl := client_hdr.ipv4.ttl;
    sw_hdr.ipv4.protocol := client_hdr.ipv4.protocol;
    sw_hdr.ipv4.hdrChecksum := client_hdr.ipv4.hdrChecksum;
    sw_hdr.ipv4.srcAddr := client_hdr.ipv4.srcAddr;
    sw_hdr.ipv4.dstAddr := client_hdr.ipv4.dstAddr;
    sw_hdr.tcp.valid := client_hdr.tcp.valid;
    sw_hdr.tcp.srcPort := client_hdr.tcp.srcPort;
    sw_hdr.tcp.dstPort := client_hdr.tcp.dstPort;
    sw_hdr.tcp.seqNo := client_hdr.tcp.seqNo;
    sw_hdr.tcp.ackNo := client_hdr.tcp.ackNo;
    sw_hdr.tcp.dataOffset := client_hdr.tcp.dataOffset;
    sw_hdr.tcp.res := client_hdr.tcp.res;
    sw_hdr.tcp.ecn := client_hdr.tcp.ecn;
    sw_hdr.tcp.ctrl := client_hdr.tcp.ctrl;
    sw_hdr.tcp.window := client_hdr.tcp.window;
    sw_hdr.tcp.checksum := client_hdr.tcp.checksum;
    sw_hdr.tcp.urgentPtr := client_hdr.tcp.urgentPtr;
    sw_hdr.udp.valid := client_hdr.udp.valid;
    sw_hdr.udp.srcPort := client_hdr.udp.srcPort;
    sw_hdr.udp.dstPort := client_hdr.udp.dstPort;
    sw_hdr.udp.pkt_length := client_hdr.udp.pkt_length;
    sw_hdr.udp.checksum := client_hdr.udp.checksum;
    sw_hdr.nlk_hdr.valid := client_hdr.nlk_hdr.valid;
    sw_hdr.nlk_hdr.recirc_flag := client_hdr.nlk_hdr.recirc_flag;
    sw_hdr.nlk_hdr.op := client_hdr.nlk_hdr.op;
    sw_hdr.nlk_hdr.mode := client_hdr.nlk_hdr.mode;
    sw_hdr.nlk_hdr.client_id := client_hdr.nlk_hdr.client_id;
    sw_hdr.nlk_hdr.tid := client_hdr.nlk_hdr.tid;
    sw_hdr.nlk_hdr.lock := client_hdr.nlk_hdr.lock;
    sw_hdr.nlk_hdr.timestamp_lo := client_hdr.nlk_hdr.timestamp_lo;
    sw_hdr.nlk_hdr.timestamp_hi := client_hdr.nlk_hdr.timestamp_hi;
    sw_hdr.nlk_hdr.empty_slots := client_hdr.nlk_hdr.empty_slots;
    sw_hdr.nlk_hdr.head := client_hdr.nlk_hdr.head;
    sw_hdr.nlk_hdr.tail := client_hdr.nlk_hdr.tail;
    sw_hdr.nlk_hdr.ncnt := client_hdr.nlk_hdr.ncnt;
    sw_hdr.nlk_hdr.transferred := client_hdr.nlk_hdr.transferred;
    sw_hdr.adm_hdr.valid := client_hdr.adm_hdr.valid;
    sw_hdr.adm_hdr.op := client_hdr.adm_hdr.op;
    sw_hdr.adm_hdr.lock := client_hdr.adm_hdr.lock;
    sw_hdr.adm_hdr.new_left := client_hdr.adm_hdr.new_left;
    sw_hdr.adm_hdr.new_right := client_hdr.adm_hdr.new_right;
    sw_hdr.recirculate_hdr.valid := client_hdr.recirculate_hdr.valid;
    sw_hdr.recirculate_hdr.dequeued_mode := client_hdr.recirculate_hdr.dequeued_mode;
    sw_hdr.recirculate_hdr.cur_head := client_hdr.recirculate_hdr.cur_head;
    sw_hdr.recirculate_hdr.cur_tail := client_hdr.recirculate_hdr.cur_tail;
    sw_hdr.probe_hdr.valid := client_hdr.probe_hdr.valid;
    sw_hdr.probe_hdr.failure_status := client_hdr.probe_hdr.failure_status;
    sw_hdr.probe_hdr.op := client_hdr.probe_hdr.op;
    sw_hdr.probe_hdr.mode := client_hdr.probe_hdr.mode;
    sw_hdr.probe_hdr.client_id := client_hdr.probe_hdr.client_id;
    sw_hdr.probe_hdr.tid := client_hdr.probe_hdr.tid;
    sw_hdr.probe_hdr.lock := client_hdr.probe_hdr.lock;
    sw_hdr.probe_hdr.timestamp_lo := client_hdr.probe_hdr.timestamp_lo;
    sw_hdr.probe_hdr.timestamp_hi := client_hdr.probe_hdr.timestamp_hi;
    sw_eg_md.head := client_eg_md.head;
    sw_eg_md.tail := client_eg_md.tail;
    sw_eg_md.queue_size_op := client_eg_md.queue_size_op;
    sw_eg_md.do_resubmit := client_eg_md.do_resubmit;
    sw_eg_md.routed := client_eg_md.routed;
    sw_eg_md.dropped := client_eg_md.dropped;
    sw_eg_md.lock_exist := client_eg_md.lock_exist;
    sw_eg_md.recirc_flag := client_eg_md.recirc_flag;
    sw_eg_md.dequeued_mode := client_eg_md.dequeued_mode;
    sw_eg_md.recirced := client_eg_md.recirced;
    sw_eg_md.locked := client_eg_md.locked;
    sw_eg_md.left := client_eg_md.left;
    sw_eg_md.right := client_eg_md.right;
    sw_eg_md.src_ip := client_eg_md.src_ip;
    sw_eg_md.dst_ip := client_eg_md.dst_ip;
    sw_eg_md.empty_slots := client_eg_md.empty_slots;
    sw_eg_md.length_in_server := client_eg_md.length_in_server;
    sw_eg_md.size_of_queue := client_eg_md.size_of_queue;
    sw_eg_md.empty_slots_before_pop := client_eg_md.empty_slots_before_pop;
    sw_eg_md.ts_hi := client_eg_md.ts_hi;
    sw_eg_md.ts_lo := client_eg_md.ts_lo;
    sw_eg_md.lock_id := client_eg_md.lock_id;
    sw_eg_md.failure_status := client_eg_md.failure_status;
    sw_eg_md.ing_mir_ses := client_eg_md.ing_mir_ses;
    sw_eg_md.clone_md := client_eg_md.clone_md;
    sw_eg_md.mode := client_eg_md.mode;
    sw_eg_md.client_id := client_eg_md.client_id;
    sw_eg_md.tid := client_eg_md.tid;
    sw_eg_md.ip_address := client_eg_md.ip_address;
    sw_eg_md.timestamp_lo := client_eg_md.timestamp_lo;
    sw_eg_md.timestamp_hi := client_eg_md.timestamp_hi;
    sw_eg_md.pkt_type := client_eg_md.pkt_type;
    sw_eg_intr_md.valid := client_eg_intr_md.valid;
    sw_eg_intr_md._pad0 := client_eg_intr_md._pad0;
    sw_eg_intr_md._pad1 := client_eg_intr_md._pad1;
    sw_eg_intr_md.enq_qdepth := client_eg_intr_md.enq_qdepth;
    sw_eg_intr_md._pad2 := client_eg_intr_md._pad2;
    sw_eg_intr_md.enq_congest_stat := client_eg_intr_md.enq_congest_stat;
    sw_eg_intr_md._pad3 := client_eg_intr_md._pad3;
    sw_eg_intr_md.enq_tstamp := client_eg_intr_md.enq_tstamp;
    sw_eg_intr_md._pad4 := client_eg_intr_md._pad4;
    sw_eg_intr_md.deq_qdepth := client_eg_intr_md.deq_qdepth;
    sw_eg_intr_md._pad5 := client_eg_intr_md._pad5;
    sw_eg_intr_md.deq_congest_stat := client_eg_intr_md.deq_congest_stat;
    sw_eg_intr_md.app_pool_congest_stat := client_eg_intr_md.app_pool_congest_stat;
    sw_eg_intr_md._pad6 := client_eg_intr_md._pad6;
    sw_eg_intr_md.deq_timedelta := client_eg_intr_md.deq_timedelta;
    sw_eg_intr_md.egress_rid := client_eg_intr_md.egress_rid;
    sw_eg_intr_md._pad7 := client_eg_intr_md._pad7;
    sw_eg_intr_md.egress_rid_first := client_eg_intr_md.egress_rid_first;
    sw_eg_intr_md._pad8 := client_eg_intr_md._pad8;
    sw_eg_intr_md.egress_qid := client_eg_intr_md.egress_qid;
    sw_eg_intr_md._pad9 := client_eg_intr_md._pad9;
    sw_eg_intr_md.egress_cos := client_eg_intr_md.egress_cos;
    sw_eg_intr_md._pad10 := client_eg_intr_md._pad10;
    sw_eg_intr_md.deflection_flag := client_eg_intr_md.deflection_flag;
    sw_eg_intr_md.pkt_length := client_eg_intr_md.pkt_length;
    sw_eg_intr_dprs_md.drop_ctl := client_eg_intr_dprs_md.drop_ctl;
    sw_eg_intr_dprs_md.mirror_type := client_eg_intr_dprs_md.mirror_type;
    sw_eg_intr_dprs_md.coalesce_flush := client_eg_intr_dprs_md.coalesce_flush;
    sw_eg_intr_dprs_md.coalesce_length := client_eg_intr_dprs_md.coalesce_length;
    sw_eg_intr_oport_md.capture_tstamp_on_tx := client_eg_intr_oport_md.capture_tstamp_on_tx;
    sw_eg_intr_oport_md.update_delay_on_tx := client_eg_intr_oport_md.update_delay_on_tx;
    sw_ig_md.head := client_ig_md.head;
    sw_ig_md.tail := client_ig_md.tail;
    sw_ig_md.queue_size_op := client_ig_md.queue_size_op;
    sw_ig_md.do_resubmit := client_ig_md.do_resubmit;
    sw_ig_md.routed := client_ig_md.routed;
    sw_ig_md.dropped := client_ig_md.dropped;
    sw_ig_md.lock_exist := client_ig_md.lock_exist;
    sw_ig_md.recirc_flag := client_ig_md.recirc_flag;
    sw_ig_md.dequeued_mode := client_ig_md.dequeued_mode;
    sw_ig_md.recirced := client_ig_md.recirced;
    sw_ig_md.locked := client_ig_md.locked;
    sw_ig_md.left := client_ig_md.left;
    sw_ig_md.right := client_ig_md.right;
    sw_ig_md.src_ip := client_ig_md.src_ip;
    sw_ig_md.dst_ip := client_ig_md.dst_ip;
    sw_ig_md.empty_slots := client_ig_md.empty_slots;
    sw_ig_md.length_in_server := client_ig_md.length_in_server;
    sw_ig_md.size_of_queue := client_ig_md.size_of_queue;
    sw_ig_md.empty_slots_before_pop := client_ig_md.empty_slots_before_pop;
    sw_ig_md.ts_hi := client_ig_md.ts_hi;
    sw_ig_md.ts_lo := client_ig_md.ts_lo;
    sw_ig_md.lock_id := client_ig_md.lock_id;
    sw_ig_md.failure_status := client_ig_md.failure_status;
    sw_ig_md.ing_mir_ses := client_ig_md.ing_mir_ses;
    sw_ig_md.clone_md := client_ig_md.clone_md;
    sw_ig_md.mode := client_ig_md.mode;
    sw_ig_md.client_id := client_ig_md.client_id;
    sw_ig_md.tid := client_ig_md.tid;
    sw_ig_md.ip_address := client_ig_md.ip_address;
    sw_ig_md.timestamp_lo := client_ig_md.timestamp_lo;
    sw_ig_md.timestamp_hi := client_ig_md.timestamp_hi;
    sw_ig_md.pkt_type := client_ig_md.pkt_type;
    sw_ig_intr_md.valid := client_ig_intr_md.valid;
    sw_ig_intr_md.resubmit_flag := client_ig_intr_md.resubmit_flag;
    sw_ig_intr_md._pad1 := client_ig_intr_md._pad1;
    sw_ig_intr_md.packet_version := client_ig_intr_md.packet_version;
    sw_ig_intr_md._pad2 := client_ig_intr_md._pad2;
    sw_ig_intr_md.ingress_port := client_ig_intr_md.ingress_port;
    sw_ig_intr_md.ingress_mac_tstamp := client_ig_intr_md.ingress_mac_tstamp;
    sw_ig_intr_prsr_md.global_tstamp := client_ig_intr_prsr_md.global_tstamp;
    sw_ig_intr_prsr_md.global_ver := client_ig_intr_prsr_md.global_ver;
    sw_ig_intr_prsr_md.parser_err := client_ig_intr_prsr_md.parser_err;
    sw_ig_intr_dprsr_md.drop_ctl := client_ig_intr_dprsr_md.drop_ctl;
    sw_ig_intr_dprsr_md.digest_type := client_ig_intr_dprsr_md.digest_type;
    sw_ig_intr_dprsr_md.resubmit_type := client_ig_intr_dprsr_md.resubmit_type;
    sw_ig_intr_dprsr_md.mirror_type := client_ig_intr_dprsr_md.mirror_type;
    sw_ig_intr_tm_md.bypass_egress := client_ig_intr_tm_md.bypass_egress;
    sw_ig_intr_tm_md.deflect_on_drop := client_ig_intr_tm_md.deflect_on_drop;
    sw_ig_intr_tm_md.ingress_cos := client_ig_intr_tm_md.ingress_cos;
    sw_ig_intr_tm_md.qid := client_ig_intr_tm_md.qid;
    sw_ig_intr_tm_md.icos_for_copy_to_cpu := client_ig_intr_tm_md.icos_for_copy_to_cpu;
    sw_ig_intr_tm_md.copy_to_cpu := client_ig_intr_tm_md.copy_to_cpu;
    sw_ig_intr_tm_md.packet_color := client_ig_intr_tm_md.packet_color;
    sw_ig_intr_tm_md.disable_ucast_cutthru := client_ig_intr_tm_md.disable_ucast_cutthru;
    sw_ig_intr_tm_md.enable_mcast_cutthru := client_ig_intr_tm_md.enable_mcast_cutthru;
    sw_ig_intr_tm_md.mcast_grp_a := client_ig_intr_tm_md.mcast_grp_a;
    sw_ig_intr_tm_md.mcast_grp_b := client_ig_intr_tm_md.mcast_grp_b;
    sw_ig_intr_tm_md.level1_mcast_hash := client_ig_intr_tm_md.level1_mcast_hash;
    sw_ig_intr_tm_md.level2_mcast_hash := client_ig_intr_tm_md.level2_mcast_hash;
    sw_ig_intr_tm_md.level1_exclusion_id := client_ig_intr_tm_md.level1_exclusion_id;
    sw_ig_intr_tm_md.level2_exclusion_id := client_ig_intr_tm_md.level2_exclusion_id;
    sw_ig_intr_tm_md.rid := client_ig_intr_tm_md.rid;
    sw_pkt_external := true;
    sw_inbox_count := sw_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 1: host_recv -> client
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
  // Register debug snapshot
  sw_client_id_array_register__dbg0 := sw_client_id_array_register[0bv32];
  sw_client_id_array_register__last_index__dbg := sw_client_id_array_register__last_index;
  sw_client_id_array_register__last_value__dbg := sw_client_id_array_register__last_value;
  sw_client_id_array_register__last_old_value__dbg := sw_client_id_array_register__last_old_value;
  sw_client_id_array_register__wrote_any__dbg := sw_client_id_array_register__wrote_any;
  sw_client_id_array_register__wrote_index0__dbg := sw_client_id_array_register__wrote_index0;
  sw_client_id_array_register__last0_old_value__dbg := sw_client_id_array_register__last0_old_value;
  sw_client_id_array_register__last0_value__dbg := sw_client_id_array_register__last0_value;
  sw_failure_status_register__dbg0 := sw_failure_status_register[0bv1];
  sw_failure_status_register__last_index__dbg := sw_failure_status_register__last_index;
  sw_failure_status_register__last_value__dbg := sw_failure_status_register__last_value;
  sw_failure_status_register__last_old_value__dbg := sw_failure_status_register__last_old_value;
  sw_failure_status_register__wrote_any__dbg := sw_failure_status_register__wrote_any;
  sw_failure_status_register__wrote_index0__dbg := sw_failure_status_register__wrote_index0;
  sw_failure_status_register__last0_old_value__dbg := sw_failure_status_register__last0_old_value;
  sw_failure_status_register__last0_value__dbg := sw_failure_status_register__last0_value;
  sw_head_register__dbg0 := sw_head_register[0bv32];
  sw_head_register__last_index__dbg := sw_head_register__last_index;
  sw_head_register__last_value__dbg := sw_head_register__last_value;
  sw_head_register__last_old_value__dbg := sw_head_register__last_old_value;
  sw_head_register__wrote_any__dbg := sw_head_register__wrote_any;
  sw_head_register__wrote_index0__dbg := sw_head_register__wrote_index0;
  sw_head_register__last0_old_value__dbg := sw_head_register__last0_old_value;
  sw_head_register__last0_value__dbg := sw_head_register__last0_value;
  sw_ip_array_register__dbg0 := sw_ip_array_register[0bv32];
  sw_ip_array_register__last_index__dbg := sw_ip_array_register__last_index;
  sw_ip_array_register__last_value__dbg := sw_ip_array_register__last_value;
  sw_ip_array_register__last_old_value__dbg := sw_ip_array_register__last_old_value;
  sw_ip_array_register__wrote_any__dbg := sw_ip_array_register__wrote_any;
  sw_ip_array_register__wrote_index0__dbg := sw_ip_array_register__wrote_index0;
  sw_ip_array_register__last0_old_value__dbg := sw_ip_array_register__last0_old_value;
  sw_ip_array_register__last0_value__dbg := sw_ip_array_register__last0_value;
  sw_left_bound_register__dbg0 := sw_left_bound_register[0bv32];
  sw_left_bound_register__last_index__dbg := sw_left_bound_register__last_index;
  sw_left_bound_register__last_value__dbg := sw_left_bound_register__last_value;
  sw_left_bound_register__last_old_value__dbg := sw_left_bound_register__last_old_value;
  sw_left_bound_register__wrote_any__dbg := sw_left_bound_register__wrote_any;
  sw_left_bound_register__wrote_index0__dbg := sw_left_bound_register__wrote_index0;
  sw_left_bound_register__last0_old_value__dbg := sw_left_bound_register__last0_old_value;
  sw_left_bound_register__last0_value__dbg := sw_left_bound_register__last0_value;
  sw_mode_array_register__dbg0 := sw_mode_array_register[0bv32];
  sw_mode_array_register__last_index__dbg := sw_mode_array_register__last_index;
  sw_mode_array_register__last_value__dbg := sw_mode_array_register__last_value;
  sw_mode_array_register__last_old_value__dbg := sw_mode_array_register__last_old_value;
  sw_mode_array_register__wrote_any__dbg := sw_mode_array_register__wrote_any;
  sw_mode_array_register__wrote_index0__dbg := sw_mode_array_register__wrote_index0;
  sw_mode_array_register__last0_old_value__dbg := sw_mode_array_register__last0_old_value;
  sw_mode_array_register__last0_value__dbg := sw_mode_array_register__last0_value;
  sw_queue_size_op_register__dbg0 := sw_queue_size_op_register[0bv32];
  sw_queue_size_op_register__last_index__dbg := sw_queue_size_op_register__last_index;
  sw_queue_size_op_register__last_value__dbg := sw_queue_size_op_register__last_value;
  sw_queue_size_op_register__last_old_value__dbg := sw_queue_size_op_register__last_old_value;
  sw_queue_size_op_register__wrote_any__dbg := sw_queue_size_op_register__wrote_any;
  sw_queue_size_op_register__wrote_index0__dbg := sw_queue_size_op_register__wrote_index0;
  sw_queue_size_op_register__last0_old_value__dbg := sw_queue_size_op_register__last0_old_value;
  sw_queue_size_op_register__last0_value__dbg := sw_queue_size_op_register__last0_value;
  sw_right_bound_register__dbg0 := sw_right_bound_register[0bv32];
  sw_right_bound_register__last_index__dbg := sw_right_bound_register__last_index;
  sw_right_bound_register__last_value__dbg := sw_right_bound_register__last_value;
  sw_right_bound_register__last_old_value__dbg := sw_right_bound_register__last_old_value;
  sw_right_bound_register__wrote_any__dbg := sw_right_bound_register__wrote_any;
  sw_right_bound_register__wrote_index0__dbg := sw_right_bound_register__wrote_index0;
  sw_right_bound_register__last0_old_value__dbg := sw_right_bound_register__last0_old_value;
  sw_right_bound_register__last0_value__dbg := sw_right_bound_register__last0_value;
  sw_shared_and_exclusive_count_register__dbg0 := sw_shared_and_exclusive_count_register[0bv32];
  sw_shared_and_exclusive_count_register__last_index__dbg := sw_shared_and_exclusive_count_register__last_index;
  sw_shared_and_exclusive_count_register__last_value__dbg := sw_shared_and_exclusive_count_register__last_value;
  sw_shared_and_exclusive_count_register__last_old_value__dbg := sw_shared_and_exclusive_count_register__last_old_value;
  sw_shared_and_exclusive_count_register__wrote_any__dbg := sw_shared_and_exclusive_count_register__wrote_any;
  sw_shared_and_exclusive_count_register__wrote_index0__dbg := sw_shared_and_exclusive_count_register__wrote_index0;
  sw_shared_and_exclusive_count_register__last0_old_value__dbg := sw_shared_and_exclusive_count_register__last0_old_value;
  sw_shared_and_exclusive_count_register__last0_value__dbg := sw_shared_and_exclusive_count_register__last0_value;
  sw_slots_two_sides_register__dbg0 := sw_slots_two_sides_register[0bv32];
  sw_slots_two_sides_register__last_index__dbg := sw_slots_two_sides_register__last_index;
  sw_slots_two_sides_register__last_value__dbg := sw_slots_two_sides_register__last_value;
  sw_slots_two_sides_register__last_old_value__dbg := sw_slots_two_sides_register__last_old_value;
  sw_slots_two_sides_register__wrote_any__dbg := sw_slots_two_sides_register__wrote_any;
  sw_slots_two_sides_register__wrote_index0__dbg := sw_slots_two_sides_register__wrote_index0;
  sw_slots_two_sides_register__last0_old_value__dbg := sw_slots_two_sides_register__last0_old_value;
  sw_slots_two_sides_register__last0_value__dbg := sw_slots_two_sides_register__last0_value;
  sw_tail_register__dbg0 := sw_tail_register[0bv32];
  sw_tail_register__last_index__dbg := sw_tail_register__last_index;
  sw_tail_register__last_value__dbg := sw_tail_register__last_value;
  sw_tail_register__last_old_value__dbg := sw_tail_register__last_old_value;
  sw_tail_register__wrote_any__dbg := sw_tail_register__wrote_any;
  sw_tail_register__wrote_index0__dbg := sw_tail_register__wrote_index0;
  sw_tail_register__last0_old_value__dbg := sw_tail_register__last0_old_value;
  sw_tail_register__last0_value__dbg := sw_tail_register__last0_value;
  sw_tenant_acq_counter_register__dbg0 := sw_tenant_acq_counter_register[0bv4];
  sw_tenant_acq_counter_register__last_index__dbg := sw_tenant_acq_counter_register__last_index;
  sw_tenant_acq_counter_register__last_value__dbg := sw_tenant_acq_counter_register__last_value;
  sw_tenant_acq_counter_register__last_old_value__dbg := sw_tenant_acq_counter_register__last_old_value;
  sw_tenant_acq_counter_register__wrote_any__dbg := sw_tenant_acq_counter_register__wrote_any;
  sw_tenant_acq_counter_register__wrote_index0__dbg := sw_tenant_acq_counter_register__wrote_index0;
  sw_tenant_acq_counter_register__last0_old_value__dbg := sw_tenant_acq_counter_register__last0_old_value;
  sw_tenant_acq_counter_register__last0_value__dbg := sw_tenant_acq_counter_register__last0_value;
  sw_tid_array_register__dbg0 := sw_tid_array_register[0bv32];
  sw_tid_array_register__last_index__dbg := sw_tid_array_register__last_index;
  sw_tid_array_register__last_value__dbg := sw_tid_array_register__last_value;
  sw_tid_array_register__last_old_value__dbg := sw_tid_array_register__last_old_value;
  sw_tid_array_register__wrote_any__dbg := sw_tid_array_register__wrote_any;
  sw_tid_array_register__wrote_index0__dbg := sw_tid_array_register__wrote_index0;
  sw_tid_array_register__last0_old_value__dbg := sw_tid_array_register__last0_old_value;
  sw_tid_array_register__last0_value__dbg := sw_tid_array_register__last0_value;
  sw_timestamp_hi_array_register__dbg0 := sw_timestamp_hi_array_register[0bv32];
  sw_timestamp_hi_array_register__last_index__dbg := sw_timestamp_hi_array_register__last_index;
  sw_timestamp_hi_array_register__last_value__dbg := sw_timestamp_hi_array_register__last_value;
  sw_timestamp_hi_array_register__last_old_value__dbg := sw_timestamp_hi_array_register__last_old_value;
  sw_timestamp_hi_array_register__wrote_any__dbg := sw_timestamp_hi_array_register__wrote_any;
  sw_timestamp_hi_array_register__wrote_index0__dbg := sw_timestamp_hi_array_register__wrote_index0;
  sw_timestamp_hi_array_register__last0_old_value__dbg := sw_timestamp_hi_array_register__last0_old_value;
  sw_timestamp_hi_array_register__last0_value__dbg := sw_timestamp_hi_array_register__last0_value;
  sw_timestamp_lo_array_register__dbg0 := sw_timestamp_lo_array_register[0bv32];
  sw_timestamp_lo_array_register__last_index__dbg := sw_timestamp_lo_array_register__last_index;
  sw_timestamp_lo_array_register__last_value__dbg := sw_timestamp_lo_array_register__last_value;
  sw_timestamp_lo_array_register__last_old_value__dbg := sw_timestamp_lo_array_register__last_old_value;
  sw_timestamp_lo_array_register__wrote_any__dbg := sw_timestamp_lo_array_register__wrote_any;
  sw_timestamp_lo_array_register__wrote_index0__dbg := sw_timestamp_lo_array_register__wrote_index0;
  sw_timestamp_lo_array_register__last0_old_value__dbg := sw_timestamp_lo_array_register__last0_old_value;
  sw_timestamp_lo_array_register__last0_value__dbg := sw_timestamp_lo_array_register__last0_value;
  // Global assertions (accumulated into procurator_bad)
  if (!(((dsl_phase != 1) || (sw_slots_two_sides_register__dbg0 == 0bv64)))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  assert !procurator_bad;
}


procedure ULTIMATE.start() returns()
  modifies client_eg_intr_dprs_md.coalesce_flush, client_eg_intr_dprs_md.coalesce_length, client_eg_intr_dprs_md.drop_ctl, client_eg_intr_dprs_md.mirror_type, client_eg_intr_md._pad0, client_eg_intr_md._pad1, client_eg_intr_md._pad10, client_eg_intr_md._pad2, client_eg_intr_md._pad3, client_eg_intr_md._pad4, client_eg_intr_md._pad5, client_eg_intr_md._pad6, client_eg_intr_md._pad7, client_eg_intr_md._pad8, client_eg_intr_md._pad9, client_eg_intr_md.app_pool_congest_stat, client_eg_intr_md.deflection_flag, client_eg_intr_md.deq_congest_stat, client_eg_intr_md.deq_qdepth, client_eg_intr_md.deq_timedelta, client_eg_intr_md.egress_cos, client_eg_intr_md.egress_qid, client_eg_intr_md.egress_rid, client_eg_intr_md.egress_rid_first, client_eg_intr_md.enq_congest_stat, client_eg_intr_md.enq_qdepth, client_eg_intr_md.enq_tstamp, client_eg_intr_md.pkt_length, client_eg_intr_md.valid, client_eg_intr_oport_md.capture_tstamp_on_tx, client_eg_intr_oport_md.update_delay_on_tx, client_eg_md.client_id, client_eg_md.clone_md, client_eg_md.dequeued_mode, client_eg_md.do_resubmit, client_eg_md.dropped, client_eg_md.dst_ip, client_eg_md.empty_slots, client_eg_md.empty_slots_before_pop, client_eg_md.failure_status, client_eg_md.head, client_eg_md.ing_mir_ses, client_eg_md.ip_address, client_eg_md.left, client_eg_md.length_in_server, client_eg_md.lock_exist, client_eg_md.lock_id, client_eg_md.locked, client_eg_md.mode, client_eg_md.pkt_type, client_eg_md.queue_size_op, client_eg_md.recirc_flag, client_eg_md.recirced, client_eg_md.right, client_eg_md.routed, client_eg_md.size_of_queue, client_eg_md.src_ip, client_eg_md.tail, client_eg_md.tid, client_eg_md.timestamp_hi, client_eg_md.timestamp_lo, client_eg_md.ts_hi, client_eg_md.ts_lo, client_hdr.adm_hdr.lock, client_hdr.adm_hdr.new_left, client_hdr.adm_hdr.new_right, client_hdr.adm_hdr.op, client_hdr.adm_hdr.valid, client_hdr.bridged_md.pkt_type, client_hdr.bridged_md.valid, client_hdr.ethernet.dstAddr, client_hdr.ethernet.etherType, client_hdr.ethernet.srcAddr, client_hdr.ethernet.valid, client_hdr.ipv4.diffserv, client_hdr.ipv4.dstAddr, client_hdr.ipv4.flags, client_hdr.ipv4.fragOffset, client_hdr.ipv4.hdrChecksum, client_hdr.ipv4.identification, client_hdr.ipv4.ihl, client_hdr.ipv4.protocol, client_hdr.ipv4.srcAddr, client_hdr.ipv4.totalLen, client_hdr.ipv4.ttl, client_hdr.ipv4.valid, client_hdr.ipv4.version, client_hdr.nlk_hdr.client_id, client_hdr.nlk_hdr.empty_slots, client_hdr.nlk_hdr.head, client_hdr.nlk_hdr.lock, client_hdr.nlk_hdr.mode, client_hdr.nlk_hdr.ncnt, client_hdr.nlk_hdr.op, client_hdr.nlk_hdr.recirc_flag, client_hdr.nlk_hdr.tail, client_hdr.nlk_hdr.tid, client_hdr.nlk_hdr.timestamp_hi, client_hdr.nlk_hdr.timestamp_lo, client_hdr.nlk_hdr.transferred, client_hdr.nlk_hdr.valid, client_hdr.probe_hdr.client_id, client_hdr.probe_hdr.failure_status, client_hdr.probe_hdr.lock, client_hdr.probe_hdr.mode, client_hdr.probe_hdr.op, client_hdr.probe_hdr.tid, client_hdr.probe_hdr.timestamp_hi, client_hdr.probe_hdr.timestamp_lo, client_hdr.probe_hdr.valid, client_hdr.recirculate_hdr.cur_head, client_hdr.recirculate_hdr.cur_tail, client_hdr.recirculate_hdr.dequeued_mode, client_hdr.recirculate_hdr.valid, client_hdr.tcp.ackNo, client_hdr.tcp.checksum, client_hdr.tcp.ctrl, client_hdr.tcp.dataOffset, client_hdr.tcp.dstPort, client_hdr.tcp.ecn, client_hdr.tcp.res, client_hdr.tcp.seqNo, client_hdr.tcp.srcPort, client_hdr.tcp.urgentPtr, client_hdr.tcp.valid, client_hdr.tcp.window, client_hdr.udp.checksum, client_hdr.udp.dstPort, client_hdr.udp.pkt_length, client_hdr.udp.srcPort, client_hdr.udp.valid, client_ig_intr_dprsr_md.digest_type, client_ig_intr_dprsr_md.drop_ctl, client_ig_intr_dprsr_md.mirror_type, client_ig_intr_dprsr_md.resubmit_type, client_ig_intr_md._pad1, client_ig_intr_md._pad2, client_ig_intr_md.ingress_mac_tstamp, client_ig_intr_md.ingress_port, client_ig_intr_md.packet_version, client_ig_intr_md.resubmit_flag, client_ig_intr_md.valid, client_ig_intr_prsr_md.global_tstamp, client_ig_intr_prsr_md.global_ver, client_ig_intr_prsr_md.parser_err, client_ig_intr_tm_md.bypass_egress, client_ig_intr_tm_md.copy_to_cpu, client_ig_intr_tm_md.deflect_on_drop, client_ig_intr_tm_md.disable_ucast_cutthru, client_ig_intr_tm_md.enable_mcast_cutthru, client_ig_intr_tm_md.icos_for_copy_to_cpu, client_ig_intr_tm_md.ingress_cos, client_ig_intr_tm_md.level1_exclusion_id, client_ig_intr_tm_md.level1_mcast_hash, client_ig_intr_tm_md.level2_exclusion_id, client_ig_intr_tm_md.level2_mcast_hash, client_ig_intr_tm_md.mcast_grp_a, client_ig_intr_tm_md.mcast_grp_b, client_ig_intr_tm_md.packet_color, client_ig_intr_tm_md.qid, client_ig_intr_tm_md.rid, client_ig_md.client_id, client_ig_md.clone_md, client_ig_md.dequeued_mode, client_ig_md.do_resubmit, client_ig_md.dropped, client_ig_md.dst_ip, client_ig_md.empty_slots, client_ig_md.empty_slots_before_pop, client_ig_md.failure_status, client_ig_md.head, client_ig_md.ing_mir_ses, client_ig_md.ip_address, client_ig_md.left, client_ig_md.length_in_server, client_ig_md.lock_exist, client_ig_md.lock_id, client_ig_md.locked, client_ig_md.mode, client_ig_md.pkt_type, client_ig_md.queue_size_op, client_ig_md.recirc_flag, client_ig_md.recirced, client_ig_md.right, client_ig_md.routed, client_ig_md.size_of_queue, client_ig_md.src_ip, client_ig_md.tail, client_ig_md.tid, client_ig_md.timestamp_hi, client_ig_md.timestamp_lo, client_ig_md.ts_hi, client_ig_md.ts_lo, client_inbox_count, client_pkt_external, dsl_phase, procurator_bad, procurator_step, sw_SwitchEgress_change_mode_table.action_run, sw_SwitchEgress_change_mode_table.hit, sw_SwitchEgress_change_op_type_table.action_run, sw_SwitchEgress_change_op_type_table.hit, sw_SwitchEgress_test_table.action_run, sw_SwitchEgress_test_table.hit, sw_SwitchIngress_acquire_lock_acquire_lock_table.action_run, sw_SwitchIngress_acquire_lock_acquire_lock_table.hit, sw_SwitchIngress_acquire_lock_dec_empty_slots_table.action_run, sw_SwitchIngress_acquire_lock_dec_empty_slots_table.hit, sw_SwitchIngress_acquire_lock_drop_packet_table.action_run, sw_SwitchIngress_acquire_lock_drop_packet_table.hit, sw_SwitchIngress_acquire_lock_fix_src_port_table.action_run, sw_SwitchIngress_acquire_lock_fix_src_port_table.hit, sw_SwitchIngress_acquire_lock_forward_to_server_table.action_run, sw_SwitchIngress_acquire_lock_forward_to_server_table.hit, sw_SwitchIngress_acquire_lock_notify_tail_client_table.action_run, sw_SwitchIngress_acquire_lock_notify_tail_client_table.hit, sw_SwitchIngress_acquire_lock_set_tag_table.action_run, sw_SwitchIngress_acquire_lock_set_tag_table.hit, sw_SwitchIngress_acquire_lock_switch_direct_grant_table.action_run, sw_SwitchIngress_acquire_lock_switch_direct_grant_table.hit, sw_SwitchIngress_acquire_lock_update_client_id_array_table.action_run, sw_SwitchIngress_acquire_lock_update_client_id_array_table.hit, sw_SwitchIngress_acquire_lock_update_ip_array_table.action_run, sw_SwitchIngress_acquire_lock_update_ip_array_table.hit, sw_SwitchIngress_acquire_lock_update_mode_array_table.action_run, sw_SwitchIngress_acquire_lock_update_mode_array_table.hit, sw_SwitchIngress_acquire_lock_update_tail_table.action_run, sw_SwitchIngress_acquire_lock_update_tail_table.hit, sw_SwitchIngress_acquire_lock_update_tid_array_table.action_run, sw_SwitchIngress_acquire_lock_update_tid_array_table.hit, sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.action_run, sw_SwitchIngress_acquire_lock_update_timestamp_hi_array_table.hit, sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.action_run, sw_SwitchIngress_acquire_lock_update_timestamp_lo_array_table.hit, sw_SwitchIngress_check_lock_exist_table.SwitchIngress_check_lock_exist_action.index_1, sw_SwitchIngress_check_lock_exist_table.action_run, sw_SwitchIngress_check_lock_exist_table.hit, sw_SwitchIngress_decode_decode_table.action_run, sw_SwitchIngress_decode_decode_table.hit, sw_SwitchIngress_decode_get_left_bound_table.action_run, sw_SwitchIngress_decode_get_left_bound_table.hit, sw_SwitchIngress_decode_get_right_bound_table.action_run, sw_SwitchIngress_decode_get_right_bound_table.hit, sw_SwitchIngress_decode_get_size_of_queue_table.action_run, sw_SwitchIngress_decode_get_size_of_queue_table.hit, sw_SwitchIngress_fix_src_port_table.action_run, sw_SwitchIngress_fix_src_port_table.hit, sw_SwitchIngress_forward_to_server_table.action_run, sw_SwitchIngress_forward_to_server_table.hit, sw_SwitchIngress_i2e_clone_table.action_run, sw_SwitchIngress_i2e_clone_table.hit, sw_SwitchIngress_ipv4_route_table.action_run, sw_SwitchIngress_ipv4_route_table.hit, sw_SwitchIngress_ipv4_route_table_2.action_run, sw_SwitchIngress_ipv4_route_table_2.hit, sw_SwitchIngress_release_lock_drop_packet_table.action_run, sw_SwitchIngress_release_lock_drop_packet_table.hit, sw_SwitchIngress_release_lock_fix_src_port_table.action_run, sw_SwitchIngress_release_lock_fix_src_port_table.hit, sw_SwitchIngress_release_lock_forward_to_server_table.action_run, sw_SwitchIngress_release_lock_forward_to_server_table.hit, sw_SwitchIngress_release_lock_get_client_id_table.action_run, sw_SwitchIngress_release_lock_get_client_id_table.hit, sw_SwitchIngress_release_lock_get_ip_table.action_run, sw_SwitchIngress_release_lock_get_ip_table.hit, sw_SwitchIngress_release_lock_get_mode_table.action_run, sw_SwitchIngress_release_lock_get_mode_table.hit, sw_SwitchIngress_release_lock_get_recirc_info_table.action_run, sw_SwitchIngress_release_lock_get_recirc_info_table.hit, sw_SwitchIngress_release_lock_get_tail_table.action_run, sw_SwitchIngress_release_lock_get_tail_table.hit, sw_SwitchIngress_release_lock_get_tid_table.action_run, sw_SwitchIngress_release_lock_get_tid_table.hit, sw_SwitchIngress_release_lock_get_timestamp_hi_table.action_run, sw_SwitchIngress_release_lock_get_timestamp_hi_table.hit, sw_SwitchIngress_release_lock_get_timestamp_lo_table.action_run, sw_SwitchIngress_release_lock_get_timestamp_lo_table.hit, sw_SwitchIngress_release_lock_i2e_mirror_table.action_run, sw_SwitchIngress_release_lock_i2e_mirror_table.hit, sw_SwitchIngress_release_lock_inc_empty_slots_table.action_run, sw_SwitchIngress_release_lock_inc_empty_slots_table.hit, sw_SwitchIngress_release_lock_metahead_plus_1_table.action_run, sw_SwitchIngress_release_lock_metahead_plus_1_table.hit, sw_SwitchIngress_release_lock_metahead_plus_2_table.action_run, sw_SwitchIngress_release_lock_metahead_plus_2_table.hit, sw_SwitchIngress_release_lock_notify_head_client_table.action_run, sw_SwitchIngress_release_lock_notify_head_client_table.hit, sw_SwitchIngress_release_lock_set_tag_table.action_run, sw_SwitchIngress_release_lock_set_tag_table.hit, sw_SwitchIngress_release_lock_update_head_table.action_run, sw_SwitchIngress_release_lock_update_head_table.hit, sw_SwitchIngress_release_lock_update_lock_table.action_run, sw_SwitchIngress_release_lock_update_lock_table.hit, sw_SwitchIngress_set_tag_table.action_run, sw_SwitchIngress_set_tag_table.hit, sw___ra_ret_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_ret_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_ret_SwitchIngress_acquire_lock_push_back_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_client_id_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_ip_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_mode_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_tid_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw___ra_ret_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw___ra_ret_SwitchIngress_decode_get_left_bound_alu, sw___ra_ret_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_ret_SwitchIngress_decode_get_right_bound_alu, sw___ra_ret_SwitchIngress_release_lock_get_client_id_alu, sw___ra_ret_SwitchIngress_release_lock_get_ip_alu, sw___ra_ret_SwitchIngress_release_lock_get_mode_alu, sw___ra_ret_SwitchIngress_release_lock_get_tail_alu, sw___ra_ret_SwitchIngress_release_lock_get_tid_alu, sw___ra_ret_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_ret_SwitchIngress_release_lock_update_head_alu, sw___ra_ret_SwitchIngress_release_lock_update_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_exclusive_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_acquire_shared_lock_alu, sw___ra_val_SwitchIngress_acquire_lock_dec_empty_slots_alu, sw___ra_val_SwitchIngress_acquire_lock_push_back_alu, sw___ra_val_SwitchIngress_acquire_lock_update_client_id_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_ip_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_mode_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tail_alu, sw___ra_val_SwitchIngress_acquire_lock_update_tid_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_hi_array_alu, sw___ra_val_SwitchIngress_acquire_lock_update_timestamp_lo_array_alu, sw___ra_val_SwitchIngress_decode_get_left_bound_alu, sw___ra_val_SwitchIngress_decode_get_queue_size_op_alu, sw___ra_val_SwitchIngress_decode_get_right_bound_alu, sw___ra_val_SwitchIngress_release_lock_get_client_id_alu, sw___ra_val_SwitchIngress_release_lock_get_ip_alu, sw___ra_val_SwitchIngress_release_lock_get_mode_alu, sw___ra_val_SwitchIngress_release_lock_get_tail_alu, sw___ra_val_SwitchIngress_release_lock_get_tid_alu, sw___ra_val_SwitchIngress_release_lock_inc_empty_slots_alu, sw___ra_val_SwitchIngress_release_lock_update_head_alu, sw___ra_val_SwitchIngress_release_lock_update_lock_alu, sw_client_id_array_register, sw_client_id_array_register__dbg0, sw_client_id_array_register__last0_old_value, sw_client_id_array_register__last0_old_value__dbg, sw_client_id_array_register__last0_value, sw_client_id_array_register__last0_value__dbg, sw_client_id_array_register__last_index, sw_client_id_array_register__last_index__dbg, sw_client_id_array_register__last_old_value, sw_client_id_array_register__last_old_value__dbg, sw_client_id_array_register__last_value, sw_client_id_array_register__last_value__dbg, sw_client_id_array_register__last_write_site, sw_client_id_array_register__next_write_site, sw_client_id_array_register__wrote_any, sw_client_id_array_register__wrote_any__dbg, sw_client_id_array_register__wrote_index0, sw_client_id_array_register__wrote_index0__dbg, sw_drop, sw_eg_intr_dprs_md.coalesce_flush, sw_eg_intr_dprs_md.coalesce_length, sw_eg_intr_dprs_md.drop_ctl, sw_eg_intr_dprs_md.mirror_type, sw_eg_intr_md._pad0, sw_eg_intr_md._pad1, sw_eg_intr_md._pad10, sw_eg_intr_md._pad2, sw_eg_intr_md._pad3, sw_eg_intr_md._pad4, sw_eg_intr_md._pad5, sw_eg_intr_md._pad6, sw_eg_intr_md._pad7, sw_eg_intr_md._pad8, sw_eg_intr_md._pad9, sw_eg_intr_md.app_pool_congest_stat, sw_eg_intr_md.deflection_flag, sw_eg_intr_md.deq_congest_stat, sw_eg_intr_md.deq_qdepth, sw_eg_intr_md.deq_timedelta, sw_eg_intr_md.egress_cos, sw_eg_intr_md.egress_qid, sw_eg_intr_md.egress_rid, sw_eg_intr_md.egress_rid_first, sw_eg_intr_md.enq_congest_stat, sw_eg_intr_md.enq_qdepth, sw_eg_intr_md.enq_tstamp, sw_eg_intr_md.pkt_length, sw_eg_intr_md.valid, sw_eg_intr_oport_md.capture_tstamp_on_tx, sw_eg_intr_oport_md.update_delay_on_tx, sw_eg_md.client_id, sw_eg_md.clone_md, sw_eg_md.dequeued_mode, sw_eg_md.do_resubmit, sw_eg_md.dropped, sw_eg_md.dst_ip, sw_eg_md.empty_slots, sw_eg_md.empty_slots_before_pop, sw_eg_md.failure_status, sw_eg_md.head, sw_eg_md.ing_mir_ses, sw_eg_md.ip_address, sw_eg_md.left, sw_eg_md.length_in_server, sw_eg_md.lock_exist, sw_eg_md.lock_id, sw_eg_md.locked, sw_eg_md.mode, sw_eg_md.pkt_type, sw_eg_md.queue_size_op, sw_eg_md.recirc_flag, sw_eg_md.recirced, sw_eg_md.right, sw_eg_md.routed, sw_eg_md.size_of_queue, sw_eg_md.src_ip, sw_eg_md.tail, sw_eg_md.tid, sw_eg_md.timestamp_hi, sw_eg_md.timestamp_lo, sw_eg_md.ts_hi, sw_eg_md.ts_lo, sw_failure_status_register__dbg0, sw_failure_status_register__last0_old_value, sw_failure_status_register__last0_old_value__dbg, sw_failure_status_register__last0_value, sw_failure_status_register__last0_value__dbg, sw_failure_status_register__last_index, sw_failure_status_register__last_index__dbg, sw_failure_status_register__last_old_value, sw_failure_status_register__last_old_value__dbg, sw_failure_status_register__last_value, sw_failure_status_register__last_value__dbg, sw_failure_status_register__last_write_site, sw_failure_status_register__next_write_site, sw_failure_status_register__wrote_any, sw_failure_status_register__wrote_any__dbg, sw_failure_status_register__wrote_index0, sw_failure_status_register__wrote_index0__dbg, sw_hdr.adm_hdr.lock, sw_hdr.adm_hdr.new_left, sw_hdr.adm_hdr.new_right, sw_hdr.adm_hdr.op, sw_hdr.adm_hdr.valid, sw_hdr.bridged_md.pkt_type, sw_hdr.bridged_md.valid, sw_hdr.ethernet.dstAddr, sw_hdr.ethernet.etherType, sw_hdr.ethernet.srcAddr, sw_hdr.ethernet.valid, sw_hdr.ipv4.diffserv, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.flags, sw_hdr.ipv4.fragOffset, sw_hdr.ipv4.hdrChecksum, sw_hdr.ipv4.identification, sw_hdr.ipv4.ihl, sw_hdr.ipv4.protocol, sw_hdr.ipv4.srcAddr, sw_hdr.ipv4.totalLen, sw_hdr.ipv4.ttl, sw_hdr.ipv4.valid, sw_hdr.ipv4.version, sw_hdr.nlk_hdr.client_id, sw_hdr.nlk_hdr.empty_slots, sw_hdr.nlk_hdr.head, sw_hdr.nlk_hdr.lock, sw_hdr.nlk_hdr.mode, sw_hdr.nlk_hdr.ncnt, sw_hdr.nlk_hdr.op, sw_hdr.nlk_hdr.recirc_flag, sw_hdr.nlk_hdr.tail, sw_hdr.nlk_hdr.tid, sw_hdr.nlk_hdr.timestamp_hi, sw_hdr.nlk_hdr.timestamp_lo, sw_hdr.nlk_hdr.transferred, sw_hdr.nlk_hdr.valid, sw_hdr.probe_hdr.client_id, sw_hdr.probe_hdr.failure_status, sw_hdr.probe_hdr.lock, sw_hdr.probe_hdr.mode, sw_hdr.probe_hdr.op, sw_hdr.probe_hdr.tid, sw_hdr.probe_hdr.timestamp_hi, sw_hdr.probe_hdr.timestamp_lo, sw_hdr.probe_hdr.valid, sw_hdr.recirculate_hdr.cur_head, sw_hdr.recirculate_hdr.cur_tail, sw_hdr.recirculate_hdr.dequeued_mode, sw_hdr.recirculate_hdr.valid, sw_hdr.tcp.ackNo, sw_hdr.tcp.checksum, sw_hdr.tcp.ctrl, sw_hdr.tcp.dataOffset, sw_hdr.tcp.dstPort, sw_hdr.tcp.ecn, sw_hdr.tcp.res, sw_hdr.tcp.seqNo, sw_hdr.tcp.srcPort, sw_hdr.tcp.urgentPtr, sw_hdr.tcp.valid, sw_hdr.tcp.window, sw_hdr.udp.checksum, sw_hdr.udp.dstPort, sw_hdr.udp.pkt_length, sw_hdr.udp.srcPort, sw_hdr.udp.valid, sw_head_register, sw_head_register__dbg0, sw_head_register__last0_old_value, sw_head_register__last0_old_value__dbg, sw_head_register__last0_value, sw_head_register__last0_value__dbg, sw_head_register__last_index, sw_head_register__last_index__dbg, sw_head_register__last_old_value, sw_head_register__last_old_value__dbg, sw_head_register__last_value, sw_head_register__last_value__dbg, sw_head_register__last_write_site, sw_head_register__next_write_site, sw_head_register__wrote_any, sw_head_register__wrote_any__dbg, sw_head_register__wrote_index0, sw_head_register__wrote_index0__dbg, sw_ig_intr_dprsr_md.digest_type, sw_ig_intr_dprsr_md.drop_ctl, sw_ig_intr_dprsr_md.mirror_type, sw_ig_intr_dprsr_md.resubmit_type, sw_ig_intr_md._pad1, sw_ig_intr_md._pad2, sw_ig_intr_md.ingress_mac_tstamp, sw_ig_intr_md.ingress_port, sw_ig_intr_md.packet_version, sw_ig_intr_md.resubmit_flag, sw_ig_intr_md.valid, sw_ig_intr_prsr_md.global_tstamp, sw_ig_intr_prsr_md.global_ver, sw_ig_intr_prsr_md.parser_err, sw_ig_intr_tm_md.bypass_egress, sw_ig_intr_tm_md.copy_to_cpu, sw_ig_intr_tm_md.deflect_on_drop, sw_ig_intr_tm_md.disable_ucast_cutthru, sw_ig_intr_tm_md.enable_mcast_cutthru, sw_ig_intr_tm_md.icos_for_copy_to_cpu, sw_ig_intr_tm_md.ingress_cos, sw_ig_intr_tm_md.level1_exclusion_id, sw_ig_intr_tm_md.level1_mcast_hash, sw_ig_intr_tm_md.level2_exclusion_id, sw_ig_intr_tm_md.level2_mcast_hash, sw_ig_intr_tm_md.mcast_grp_a, sw_ig_intr_tm_md.mcast_grp_b, sw_ig_intr_tm_md.packet_color, sw_ig_intr_tm_md.qid, sw_ig_intr_tm_md.rid, sw_ig_intr_tm_md.ucast_egress_port, sw_ig_md.client_id, sw_ig_md.clone_md, sw_ig_md.dequeued_mode, sw_ig_md.do_resubmit, sw_ig_md.dropped, sw_ig_md.dst_ip, sw_ig_md.empty_slots, sw_ig_md.empty_slots_before_pop, sw_ig_md.failure_status, sw_ig_md.head, sw_ig_md.ing_mir_ses, sw_ig_md.ip_address, sw_ig_md.left, sw_ig_md.length_in_server, sw_ig_md.lock_exist, sw_ig_md.lock_id, sw_ig_md.locked, sw_ig_md.mode, sw_ig_md.pkt_type, sw_ig_md.queue_size_op, sw_ig_md.recirc_flag, sw_ig_md.recirced, sw_ig_md.right, sw_ig_md.routed, sw_ig_md.size_of_queue, sw_ig_md.src_ip, sw_ig_md.tail, sw_ig_md.tid, sw_ig_md.timestamp_hi, sw_ig_md.timestamp_lo, sw_ig_md.ts_hi, sw_ig_md.ts_lo, sw_inbox_count, sw_ip_array_register, sw_ip_array_register__dbg0, sw_ip_array_register__last0_old_value, sw_ip_array_register__last0_old_value__dbg, sw_ip_array_register__last0_value, sw_ip_array_register__last0_value__dbg, sw_ip_array_register__last_index, sw_ip_array_register__last_index__dbg, sw_ip_array_register__last_old_value, sw_ip_array_register__last_old_value__dbg, sw_ip_array_register__last_value, sw_ip_array_register__last_value__dbg, sw_ip_array_register__last_write_site, sw_ip_array_register__next_write_site, sw_ip_array_register__wrote_any, sw_ip_array_register__wrote_any__dbg, sw_ip_array_register__wrote_index0, sw_ip_array_register__wrote_index0__dbg, sw_isValid, sw_left_bound_register, sw_left_bound_register__dbg0, sw_left_bound_register__last0_old_value, sw_left_bound_register__last0_old_value__dbg, sw_left_bound_register__last0_value, sw_left_bound_register__last0_value__dbg, sw_left_bound_register__last_index, sw_left_bound_register__last_index__dbg, sw_left_bound_register__last_old_value, sw_left_bound_register__last_old_value__dbg, sw_left_bound_register__last_value, sw_left_bound_register__last_value__dbg, sw_left_bound_register__last_write_site, sw_left_bound_register__next_write_site, sw_left_bound_register__wrote_any, sw_left_bound_register__wrote_any__dbg, sw_left_bound_register__wrote_index0, sw_left_bound_register__wrote_index0__dbg, sw_mirror_hdr_0, sw_mirror_md_0, sw_mode_array_register, sw_mode_array_register__dbg0, sw_mode_array_register__last0_old_value, sw_mode_array_register__last0_old_value__dbg, sw_mode_array_register__last0_value, sw_mode_array_register__last0_value__dbg, sw_mode_array_register__last_index, sw_mode_array_register__last_index__dbg, sw_mode_array_register__last_old_value, sw_mode_array_register__last_old_value__dbg, sw_mode_array_register__last_value, sw_mode_array_register__last_value__dbg, sw_mode_array_register__last_write_site, sw_mode_array_register__next_write_site, sw_mode_array_register__wrote_any, sw_mode_array_register__wrote_any__dbg, sw_mode_array_register__wrote_index0, sw_mode_array_register__wrote_index0__dbg, sw_p4b_checksum_error, sw_p4b_checksum_updated, sw_p4b_checksum_verified, sw_p4b_clone_e2e, sw_p4b_clone_i2e, sw_p4b_clone_i2i, sw_p4b_digest, sw_p4b_recirculate, sw_pkt_external, sw_queue_size_op_register, sw_queue_size_op_register__dbg0, sw_queue_size_op_register__last0_old_value, sw_queue_size_op_register__last0_old_value__dbg, sw_queue_size_op_register__last0_value, sw_queue_size_op_register__last0_value__dbg, sw_queue_size_op_register__last_index, sw_queue_size_op_register__last_index__dbg, sw_queue_size_op_register__last_old_value, sw_queue_size_op_register__last_old_value__dbg, sw_queue_size_op_register__last_value, sw_queue_size_op_register__last_value__dbg, sw_queue_size_op_register__last_write_site, sw_queue_size_op_register__next_write_site, sw_queue_size_op_register__wrote_any, sw_queue_size_op_register__wrote_any__dbg, sw_queue_size_op_register__wrote_index0, sw_queue_size_op_register__wrote_index0__dbg, sw_right_bound_register, sw_right_bound_register__dbg0, sw_right_bound_register__last0_old_value, sw_right_bound_register__last0_old_value__dbg, sw_right_bound_register__last0_value, sw_right_bound_register__last0_value__dbg, sw_right_bound_register__last_index, sw_right_bound_register__last_index__dbg, sw_right_bound_register__last_old_value, sw_right_bound_register__last_old_value__dbg, sw_right_bound_register__last_value, sw_right_bound_register__last_value__dbg, sw_right_bound_register__last_write_site, sw_right_bound_register__next_write_site, sw_right_bound_register__wrote_any, sw_right_bound_register__wrote_any__dbg, sw_right_bound_register__wrote_index0, sw_right_bound_register__wrote_index0__dbg, sw_shared_and_exclusive_count_register, sw_shared_and_exclusive_count_register__dbg0, sw_shared_and_exclusive_count_register__last0_old_value, sw_shared_and_exclusive_count_register__last0_old_value__dbg, sw_shared_and_exclusive_count_register__last0_value, sw_shared_and_exclusive_count_register__last0_value__dbg, sw_shared_and_exclusive_count_register__last_index, sw_shared_and_exclusive_count_register__last_index__dbg, sw_shared_and_exclusive_count_register__last_old_value, sw_shared_and_exclusive_count_register__last_old_value__dbg, sw_shared_and_exclusive_count_register__last_value, sw_shared_and_exclusive_count_register__last_value__dbg, sw_shared_and_exclusive_count_register__last_write_site, sw_shared_and_exclusive_count_register__next_write_site, sw_shared_and_exclusive_count_register__wrote_any, sw_shared_and_exclusive_count_register__wrote_any__dbg, sw_shared_and_exclusive_count_register__wrote_index0, sw_shared_and_exclusive_count_register__wrote_index0__dbg, sw_slots_two_sides_register, sw_slots_two_sides_register__dbg0, sw_slots_two_sides_register__last0_old_value, sw_slots_two_sides_register__last0_old_value__dbg, sw_slots_two_sides_register__last0_value, sw_slots_two_sides_register__last0_value__dbg, sw_slots_two_sides_register__last_index, sw_slots_two_sides_register__last_index__dbg, sw_slots_two_sides_register__last_old_value, sw_slots_two_sides_register__last_old_value__dbg, sw_slots_two_sides_register__last_value, sw_slots_two_sides_register__last_value__dbg, sw_slots_two_sides_register__last_write_site, sw_slots_two_sides_register__next_write_site, sw_slots_two_sides_register__wrote_any, sw_slots_two_sides_register__wrote_any__dbg, sw_slots_two_sides_register__wrote_index0, sw_slots_two_sides_register__wrote_index0__dbg, sw_tail_register, sw_tail_register__dbg0, sw_tail_register__last0_old_value, sw_tail_register__last0_old_value__dbg, sw_tail_register__last0_value, sw_tail_register__last0_value__dbg, sw_tail_register__last_index, sw_tail_register__last_index__dbg, sw_tail_register__last_old_value, sw_tail_register__last_old_value__dbg, sw_tail_register__last_value, sw_tail_register__last_value__dbg, sw_tail_register__last_write_site, sw_tail_register__next_write_site, sw_tail_register__wrote_any, sw_tail_register__wrote_any__dbg, sw_tail_register__wrote_index0, sw_tail_register__wrote_index0__dbg, sw_tenant_acq_counter_register__dbg0, sw_tenant_acq_counter_register__last0_old_value, sw_tenant_acq_counter_register__last0_old_value__dbg, sw_tenant_acq_counter_register__last0_value, sw_tenant_acq_counter_register__last0_value__dbg, sw_tenant_acq_counter_register__last_index, sw_tenant_acq_counter_register__last_index__dbg, sw_tenant_acq_counter_register__last_old_value, sw_tenant_acq_counter_register__last_old_value__dbg, sw_tenant_acq_counter_register__last_value, sw_tenant_acq_counter_register__last_value__dbg, sw_tenant_acq_counter_register__last_write_site, sw_tenant_acq_counter_register__next_write_site, sw_tenant_acq_counter_register__wrote_any, sw_tenant_acq_counter_register__wrote_any__dbg, sw_tenant_acq_counter_register__wrote_index0, sw_tenant_acq_counter_register__wrote_index0__dbg, sw_tid_array_register, sw_tid_array_register__dbg0, sw_tid_array_register__last0_old_value, sw_tid_array_register__last0_old_value__dbg, sw_tid_array_register__last0_value, sw_tid_array_register__last0_value__dbg, sw_tid_array_register__last_index, sw_tid_array_register__last_index__dbg, sw_tid_array_register__last_old_value, sw_tid_array_register__last_old_value__dbg, sw_tid_array_register__last_value, sw_tid_array_register__last_value__dbg, sw_tid_array_register__last_write_site, sw_tid_array_register__next_write_site, sw_tid_array_register__wrote_any, sw_tid_array_register__wrote_any__dbg, sw_tid_array_register__wrote_index0, sw_tid_array_register__wrote_index0__dbg, sw_timestamp_hi_array_register, sw_timestamp_hi_array_register__dbg0, sw_timestamp_hi_array_register__last0_old_value, sw_timestamp_hi_array_register__last0_old_value__dbg, sw_timestamp_hi_array_register__last0_value, sw_timestamp_hi_array_register__last0_value__dbg, sw_timestamp_hi_array_register__last_index, sw_timestamp_hi_array_register__last_index__dbg, sw_timestamp_hi_array_register__last_old_value, sw_timestamp_hi_array_register__last_old_value__dbg, sw_timestamp_hi_array_register__last_value, sw_timestamp_hi_array_register__last_value__dbg, sw_timestamp_hi_array_register__last_write_site, sw_timestamp_hi_array_register__next_write_site, sw_timestamp_hi_array_register__wrote_any, sw_timestamp_hi_array_register__wrote_any__dbg, sw_timestamp_hi_array_register__wrote_index0, sw_timestamp_hi_array_register__wrote_index0__dbg, sw_timestamp_lo_array_register, sw_timestamp_lo_array_register__dbg0, sw_timestamp_lo_array_register__last0_old_value, sw_timestamp_lo_array_register__last0_old_value__dbg, sw_timestamp_lo_array_register__last0_value, sw_timestamp_lo_array_register__last0_value__dbg, sw_timestamp_lo_array_register__last_index, sw_timestamp_lo_array_register__last_index__dbg, sw_timestamp_lo_array_register__last_old_value, sw_timestamp_lo_array_register__last_old_value__dbg, sw_timestamp_lo_array_register__last_value, sw_timestamp_lo_array_register__last_value__dbg, sw_timestamp_lo_array_register__last_write_site, sw_timestamp_lo_array_register__next_write_site, sw_timestamp_lo_array_register__wrote_any, sw_timestamp_lo_array_register__wrote_any__dbg, sw_timestamp_lo_array_register__wrote_index0, sw_timestamp_lo_array_register__wrote_index0__dbg, sw_tmp;
{
  call mainProcedure();
}

// ===== END HARNESS =====
