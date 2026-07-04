// ===== BEGIN PREAMBLE =====
function bvule.bv16(left:bv16, right:bv16) returns(bool);
function {:builtin "bvule"} bvule.bv16$builtin(left:bv16, right:bv16) returns(bool);
axiom (forall left:bv16, right:bv16 :: bvule.bv16(left, right) <==> bvule.bv16$builtin(left, right));
function bvule.bv32(left:bv32, right:bv32) returns(bool);
function {:builtin "bvule"} bvule.bv32$builtin(left:bv32, right:bv32) returns(bool);
axiom (forall left:bv32, right:bv32 :: bvule.bv32(left, right) <==> bvule.bv32$builtin(left, right));
// ===== END PREAMBLE =====

// ===== BEGIN NODE ta (prefixed) =====
type ta_Ref;
type ta_error=bv1;
type ta_HeaderStack = [int]ta_Ref;
var ta_last:[ta_HeaderStack]ta_Ref;
var ta_forward:bool;
var ta_isValid:[ta_Ref]bool;
var ta_emit:[ta_Ref]bool;
var ta_stack.index:[ta_HeaderStack]int;
var ta_size:[ta_HeaderStack]int;
var ta_drop:bool;
var ta_p4b_clone_i2e:bool;
var ta_p4b_clone_e2e:bool;
var ta_p4b_clone_i2i:bool;
var ta_p4b_recirculate:bool;
var ta_p4b_digest:bool;
var ta_p4b_checksum_verified:bool;
var ta_p4b_checksum_updated:bool;
var ta_p4b_checksum_error:bool;
type ta_PortId_t = bv9;
type ta_MulticastGroupId_t = bv16;
type ta_QueueId_t = bv5;
type ta_MirrorType_t = bv3;
type ta_MirrorId_t = bv10;
type ta_ResubmitType_t = bv3;
type ta_DigestType_t = bv3;
type ta_L1ExclusionId_t = bv16;
type ta_L2ExclusionId_t = bv9;
type ta_MeterType_t = int;
type ta_MeterColor_t = bv8;
type ta_CounterType_t = int;
type ta_SelectorMode_t = int;
type ta_HashAlgorithm_t = int;
type ta_ingress_intrinsic_metadata_t;

// ta_Struct ta_ingress_intrinsic_metadata_for_tm_t
type ta_ingress_intrinsic_metadata_for_tm_t;

// ta_Struct ta_ingress_intrinsic_metadata_from_parser_t
type ta_ingress_intrinsic_metadata_from_parser_t;

// ta_Struct ta_ingress_intrinsic_metadata_for_deparser_t
type ta_ingress_intrinsic_metadata_for_deparser_t;
type ta_egress_intrinsic_metadata_t;

// ta_Struct ta_egress_intrinsic_metadata_from_parser_t
type ta_egress_intrinsic_metadata_from_parser_t;

// ta_Struct ta_egress_intrinsic_metadata_for_deparser_t
type ta_egress_intrinsic_metadata_for_deparser_t;

// ta_Struct ta_egress_intrinsic_metadata_for_output_port_t
type ta_egress_intrinsic_metadata_for_output_port_t;
type ta_pktgen_timer_header_t;
type ta_pktgen_port_down_header_t;
type ta_pktgen_recirc_header_t;
type ta_ptp_metadata_t;
type ta_MathOp_t = int;
type ta_ethernet_t;
type ta_mirror_h;
type ta_albion_t;
type ta_albion_data_t;
type ta_albion_timer_t;

// ta_Struct ta_headers
var ta_hdr:ta_Ref;

// ta_Header ta_mirror_h
var ta_hdr.mirror_1:ta_Ref;
var ta_hdr.mirror_1.valid:bool;
var ta_hdr.mirror_1.pkt_type:bv8;

// ta_Header ta_mirror_h
var ta_hdr.mirror_2:ta_Ref;
var ta_hdr.mirror_2.valid:bool;
var ta_hdr.mirror_2.pkt_type:bv8;

// ta_Header ta_ethernet_t
var ta_hdr.ethernet:ta_Ref;
var ta_hdr.ethernet.valid:bool;
var ta_hdr.ethernet.dst_addr:bv48;
var ta_hdr.ethernet.src_addr:bv48;
var ta_hdr.ethernet.ether_type:bv16;

// ta_Header ta_albion_t
var ta_hdr.albion:ta_Ref;
var ta_hdr.albion.valid:bool;
var ta_hdr.albion.request_id_high:bv32;
var ta_hdr.albion.request_id_low:bv32;
var ta_hdr.albion.operation:bv32;
var ta_hdr.albion.address_h:bv32;
var ta_hdr.albion.address_l:bv32;
var ta_hdr.albion.time:bv32;
var ta_hdr.albion.num:bv32;
var ta_hdr.albion.index:bv32;
var ta_hdr.albion.CS_id_1:bv32;
var ta_hdr.albion.CS_offset_1:bv32;
var ta_hdr.albion.CS_id_2:bv32;
var ta_hdr.albion.CS_offset_2:bv32;
var ta_hdr.albion.CS_id_3:bv32;
var ta_hdr.albion.CS_offset_3:bv32;
var ta_hdr.albion.port:bv16;

// ta_Header ta_albion_data_t
var ta_hdr.albion_data:ta_Ref;
var ta_hdr.albion_data.valid:bool;
var ta_hdr.albion_data.data_0:bv32;
var ta_hdr.albion_data.data_1:bv32;
var ta_hdr.albion_data.data_2:bv32;
var ta_hdr.albion_data.data_3:bv32;
var ta_hdr.albion_data.data_4:bv32;
var ta_hdr.albion_data.data_5:bv32;
var ta_hdr.albion_data.data_6:bv32;
var ta_hdr.albion_data.data_7:bv32;
var ta_hdr.albion_data.data_8:bv32;
var ta_hdr.albion_data.data_9:bv32;
var ta_hdr.albion_data.data_10:bv32;
var ta_hdr.albion_data.data_11:bv32;

// ta_Header ta_albion_timer_t
var ta_hdr.albion_timer:ta_Ref;
var ta_hdr.albion_timer.valid:bool;
var ta_hdr.albion_timer.times:bv32;
var ta_hdr.albion_timer.const_time:bv32;
var ta_hdr.albion_timer.now:bv32;
var ta_hdr.albion_timer.address_high_0:bv32;
var ta_hdr.albion_timer.address_low_0:bv32;
var ta_hdr.albion_timer.state_0:bv32;
var ta_hdr.albion_timer.address_high_1:bv32;
var ta_hdr.albion_timer.address_low_1:bv32;
var ta_hdr.albion_timer.state_1:bv32;
var ta_hdr.albion_timer.address_high_2:bv32;
var ta_hdr.albion_timer.address_low_2:bv32;
var ta_hdr.albion_timer.state_2:bv32;
var ta_hdr.albion_timer.address_high_3:bv32;
var ta_hdr.albion_timer.address_low_3:bv32;
var ta_hdr.albion_timer.state_3:bv32;

// ta_Struct ta_my_ingress_metadata_t
type ta_my_ingress_metadata_t;

// ta_Struct ta_my_egress_metadata_t
type ta_my_egress_metadata_t;
var ta_meta:ta_my_ingress_metadata_t;
var ta_meta.time_1:bv32;
var ta_meta.time_2:bv32;
var ta_meta.state:bv32;
var ta_meta.state_sub:bv32;
var ta_meta.no_use_1:bv8;
var ta_meta.no_use_2:bv8;

// ta_Header ta_ingress_intrinsic_metadata_t
var ta_ig_intr_md:ta_Ref;
var ta_ig_intr_md.valid:bool;
var ta_ig_intr_md.resubmit_flag:bv1;
var ta_ig_intr_md._pad1:bv1;
var ta_ig_intr_md.packet_version:bv2;
var ta_ig_intr_md._pad2:bv3;
var ta_ig_intr_md.ingress_port:ta_PortId_t;
var ta_ig_intr_md.ingress_mac_tstamp:bv48;
var ta_pkt:ta_Ref;
var ta_ig_prsr_md:ta_ingress_intrinsic_metadata_from_parser_t;
var ta_ig_prsr_md.global_tstamp:bv48;
var ta_ig_prsr_md.global_ver:bv32;
var ta_ig_prsr_md.parser_err:bv16;
var ta_ig_dprsr_md:ta_ingress_intrinsic_metadata_for_deparser_t;
var ta_ig_dprsr_md.drop_ctl:bv3;
var ta_ig_dprsr_md.digest_type:ta_DigestType_t;
var ta_ig_dprsr_md.resubmit_type:ta_ResubmitType_t;
var ta_ig_dprsr_md.mirror_type:ta_MirrorType_t;
var ta_ig_tm_md:ta_ingress_intrinsic_metadata_for_tm_t;
var ta_ig_tm_md.ucast_egress_port:ta_PortId_t;
var ta_ig_tm_md.bypass_egress:bv1;
var ta_ig_tm_md.deflect_on_drop:bv1;
var ta_ig_tm_md.ingress_cos:bv3;
var ta_ig_tm_md.qid:ta_QueueId_t;
var ta_ig_tm_md.icos_for_copy_to_cpu:bv3;
var ta_ig_tm_md.copy_to_cpu:bv1;
var ta_ig_tm_md.packet_color:bv2;
var ta_ig_tm_md.disable_ucast_cutthru:bv1;
var ta_ig_tm_md.enable_mcast_cutthru:bv1;
var ta_ig_tm_md.mcast_grp_a:ta_MulticastGroupId_t;
var ta_ig_tm_md.mcast_grp_b:ta_MulticastGroupId_t;
var ta_ig_tm_md.level1_mcast_hash:bv13;
var ta_ig_tm_md.level2_mcast_hash:bv13;
var ta_ig_tm_md.level1_exclusion_id:ta_L1ExclusionId_t;
var ta_ig_tm_md.level2_exclusion_id:ta_L2ExclusionId_t;
var ta_ig_tm_md.rid:bv16;

// ta_Register ta_register_request_id_low_0
var ta_register_request_id_low_0:[bv32]bv32;
var ta_register_request_id_low_0__last_index:bv32;
var ta_register_request_id_low_0__last_value:bv32;
var ta_register_request_id_low_0__last_old_value:bv32;
var ta_register_request_id_low_0__wrote_any:bool;
var ta_register_request_id_low_0__wrote_index0:bool;
var ta_register_request_id_low_0__last0_old_value:bv32;
var ta_register_request_id_low_0__last0_value:bv32;
var ta_register_request_id_low_0__next_write_site:int;
var ta_register_request_id_low_0__last_write_site:int;
const ta_register_request_id_low_0.size:bv32;
axiom ta_register_request_id_low_0.size == 1bv32;

function {:builtin "bvadd"} add.bv32(ta_left:bv32, ta_right:bv32) returns(bv32);

// ta_Register ta_register_num_0
var ta_register_num_0:[bv32]bv32;
var ta_register_num_0__last_index:bv32;
var ta_register_num_0__last_value:bv32;
var ta_register_num_0__last_old_value:bv32;
var ta_register_num_0__wrote_any:bool;
var ta_register_num_0__wrote_index0:bool;
var ta_register_num_0__last0_old_value:bv32;
var ta_register_num_0__last0_value:bv32;
var ta_register_num_0__next_write_site:int;
var ta_register_num_0__last_write_site:int;
const ta_register_num_0.size:bv32;
axiom ta_register_num_0.size == 1bv32;

// ta_Register ta_register_timer_0
var ta_register_timer_0:[bv32]bv32;
var ta_register_timer_0__last_index:bv32;
var ta_register_timer_0__last_value:bv32;
var ta_register_timer_0__last_old_value:bv32;
var ta_register_timer_0__wrote_any:bool;
var ta_register_timer_0__wrote_index0:bool;
var ta_register_timer_0__last0_old_value:bv32;
var ta_register_timer_0__last0_value:bv32;
var ta_register_timer_0__next_write_site:int;
var ta_register_timer_0__last_write_site:int;
const ta_register_timer_0.size:bv32;
axiom ta_register_timer_0.size == 1bv32;
var ta___ra_val_register_timer_add_0:bv32;
var ta___ra_ret_register_timer_add_0:bv32;
var ta___ra_val_register_timer_read_0:bv32;
var ta___ra_ret_register_timer_read_0:bv32;

// ta_Table ta_table_register_timer_interaction_0 ta_Actionlist ta_Declaration
type ta_table_register_timer_interaction_0.action;
const unique ta_table_register_timer_interaction_0.action.no_action : ta_table_register_timer_interaction_0.action;
const unique ta_table_register_timer_interaction_0.action.action_register_timer_add : ta_table_register_timer_interaction_0.action;
const unique ta_table_register_timer_interaction_0.action.action_register_timer_read : ta_table_register_timer_interaction_0.action;
var ta_table_register_timer_interaction_0.action_run : ta_table_register_timer_interaction_0.action;
var ta_table_register_timer_interaction_0.hit : bool;
var ta___ra_val_register_num_add_0:bv32;
var ta___ra_ret_register_num_add_0:bv32;
var ta___ra_val_register_num_zero_0:bv32;
var ta___ra_ret_register_num_zero_0:bv32;

// ta_Table ta_table_register_num_interaction_0 ta_Actionlist ta_Declaration
type ta_table_register_num_interaction_0.action;
const unique ta_table_register_num_interaction_0.action.action_register_num_add : ta_table_register_num_interaction_0.action;
const unique ta_table_register_num_interaction_0.action.action_register_num_zero : ta_table_register_num_interaction_0.action;
var ta_table_register_num_interaction_0.action_run : ta_table_register_num_interaction_0.action;
var ta_table_register_num_interaction_0.hit : bool;

// ta_Register ta_register_request_id_high_0
var ta_register_request_id_high_0:[bv32]bv32;
var ta_register_request_id_high_0__last_index:bv32;
var ta_register_request_id_high_0__last_value:bv32;
var ta_register_request_id_high_0__last_old_value:bv32;
var ta_register_request_id_high_0__wrote_any:bool;
var ta_register_request_id_high_0__wrote_index0:bool;
var ta_register_request_id_high_0__last0_old_value:bv32;
var ta_register_request_id_high_0__last0_value:bv32;
var ta_register_request_id_high_0__next_write_site:int;
var ta_register_request_id_high_0__last_write_site:int;
const ta_register_request_id_high_0.size:bv32;
axiom ta_register_request_id_high_0.size == 1bv32;
var ta___ra_val_register_request_id_high_add_0:bv32;
var ta___ra_ret_register_request_id_high_add_0:bv32;

// ta_Table ta_table_register_request_id_high_interaction_0 ta_Actionlist ta_Declaration
type ta_table_register_request_id_high_interaction_0.action;
const unique ta_table_register_request_id_high_interaction_0.action.action_register_request_id_high_add : ta_table_register_request_id_high_interaction_0.action;
const unique ta_table_register_request_id_high_interaction_0.action.no_action_1 : ta_table_register_request_id_high_interaction_0.action;
var ta_table_register_request_id_high_interaction_0.action_run : ta_table_register_request_id_high_interaction_0.action;
var ta_table_register_request_id_high_interaction_0.hit : bool;

// ta_Register ta_register_state
var ta_register_state:[bv32]bv32;
var ta_register_state__last_index:bv32;
var ta_register_state__last_value:bv32;
var ta_register_state__last_old_value:bv32;
var ta_register_state__wrote_any:bool;
var ta_register_state__wrote_index0:bool;
var ta_register_state__last0_old_value:bv32;
var ta_register_state__last0_value:bv32;
var ta_register_state__next_write_site:int;
var ta_register_state__last_write_site:int;
const ta_register_state.size:bv32;
axiom ta_register_state.size == 20000bv32;

function {:builtin "bvand"} band.bv32(ta_left:bv32, ta_right:bv32) returns(bv32);

// ta_Register ta_register_state_4
var ta_register_state_4:[bv32]bv32;
var ta_register_state_4__last_index:bv32;
var ta_register_state_4__last_value:bv32;
var ta_register_state_4__last_old_value:bv32;
var ta_register_state_4__wrote_any:bool;
var ta_register_state_4__wrote_index0:bool;
var ta_register_state_4__last0_old_value:bv32;
var ta_register_state_4__last0_value:bv32;
var ta_register_state_4__next_write_site:int;
var ta_register_state_4__last_write_site:int;
const ta_register_state_4.size:bv32;
axiom ta_register_state_4.size == 20000bv32;

// ta_Register ta_register_state_5
var ta_register_state_5:[bv32]bv32;
var ta_register_state_5__last_index:bv32;
var ta_register_state_5__last_value:bv32;
var ta_register_state_5__last_old_value:bv32;
var ta_register_state_5__wrote_any:bool;
var ta_register_state_5__wrote_index0:bool;
var ta_register_state_5__last0_old_value:bv32;
var ta_register_state_5__last0_value:bv32;
var ta_register_state_5__next_write_site:int;
var ta_register_state_5__last_write_site:int;
const ta_register_state_5.size:bv32;
axiom ta_register_state_5.size == 20000bv32;

// ta_Register ta_register_state_6
var ta_register_state_6:[bv32]bv32;
var ta_register_state_6__last_index:bv32;
var ta_register_state_6__last_value:bv32;
var ta_register_state_6__last_old_value:bv32;
var ta_register_state_6__wrote_any:bool;
var ta_register_state_6__wrote_index0:bool;
var ta_register_state_6__last0_old_value:bv32;
var ta_register_state_6__last0_value:bv32;
var ta_register_state_6__next_write_site:int;
var ta_register_state_6__last_write_site:int;
const ta_register_state_6.size:bv32;
axiom ta_register_state_6.size == 20000bv32;
var ta___ra_val_register_state_0_w_0:bv32;
var ta___ra_ret_register_state_0_w_0:bv32;
var ta___ra_val_register_state_0_r_0:bv32;
var ta___ra_ret_register_state_0_r_0:bv32;
var ta___ra_val_register_state_0_sub_0:bv32;
var ta___ra_ret_register_state_0_sub_0:bv32;

// ta_Table ta_table_register_state_0_interaction_0 ta_Actionlist ta_Declaration
type ta_table_register_state_0_interaction_0.action;
const unique ta_table_register_state_0_interaction_0.action.action_register_state_0_w : ta_table_register_state_0_interaction_0.action;
const unique ta_table_register_state_0_interaction_0.action.action_register_state_0_r : ta_table_register_state_0_interaction_0.action;
const unique ta_table_register_state_0_interaction_0.action.action_register_state_0_r_timer : ta_table_register_state_0_interaction_0.action;
const unique ta_table_register_state_0_interaction_0.action.action_register_state_0_sub : ta_table_register_state_0_interaction_0.action;
const unique ta_table_register_state_0_interaction_0.action.no_action_2 : ta_table_register_state_0_interaction_0.action;
var ta_table_register_state_0_interaction_0.action_run : ta_table_register_state_0_interaction_0.action;
var ta_table_register_state_0_interaction_0.hit : bool;
var ta___ra_val_register_state_1_w_0:bv32;
var ta___ra_ret_register_state_1_w_0:bv32;
var ta___ra_val_register_state_1_r_0:bv32;
var ta___ra_ret_register_state_1_r_0:bv32;
var ta___ra_val_register_state_1_sub_0:bv32;
var ta___ra_ret_register_state_1_sub_0:bv32;

// ta_Table ta_table_register_state_1_interaction_0 ta_Actionlist ta_Declaration
type ta_table_register_state_1_interaction_0.action;
const unique ta_table_register_state_1_interaction_0.action.action_register_state_1_w : ta_table_register_state_1_interaction_0.action;
const unique ta_table_register_state_1_interaction_0.action.action_register_state_1_r : ta_table_register_state_1_interaction_0.action;
const unique ta_table_register_state_1_interaction_0.action.action_register_state_1_r_timer : ta_table_register_state_1_interaction_0.action;
const unique ta_table_register_state_1_interaction_0.action.action_register_state_1_sub : ta_table_register_state_1_interaction_0.action;
const unique ta_table_register_state_1_interaction_0.action.no_action_3 : ta_table_register_state_1_interaction_0.action;
var ta_table_register_state_1_interaction_0.action_run : ta_table_register_state_1_interaction_0.action;
var ta_table_register_state_1_interaction_0.hit : bool;
var ta___ra_val_register_state_2_w_0:bv32;
var ta___ra_ret_register_state_2_w_0:bv32;
var ta___ra_val_register_state_2_r_0:bv32;
var ta___ra_ret_register_state_2_r_0:bv32;
var ta___ra_val_register_state_2_sub_0:bv32;
var ta___ra_ret_register_state_2_sub_0:bv32;

// ta_Table ta_table_register_state_2_interaction_0 ta_Actionlist ta_Declaration
type ta_table_register_state_2_interaction_0.action;
const unique ta_table_register_state_2_interaction_0.action.action_register_state_2_w : ta_table_register_state_2_interaction_0.action;
const unique ta_table_register_state_2_interaction_0.action.action_register_state_2_r : ta_table_register_state_2_interaction_0.action;
const unique ta_table_register_state_2_interaction_0.action.action_register_state_2_r_timer : ta_table_register_state_2_interaction_0.action;
const unique ta_table_register_state_2_interaction_0.action.action_register_state_2_sub : ta_table_register_state_2_interaction_0.action;
const unique ta_table_register_state_2_interaction_0.action.no_action_4 : ta_table_register_state_2_interaction_0.action;
var ta_table_register_state_2_interaction_0.action_run : ta_table_register_state_2_interaction_0.action;
var ta_table_register_state_2_interaction_0.hit : bool;
var ta___ra_val_register_state_3_w_0:bv32;
var ta___ra_ret_register_state_3_w_0:bv32;
var ta___ra_val_register_state_3_r_0:bv32;
var ta___ra_ret_register_state_3_r_0:bv32;
var ta___ra_val_register_state_3_sub_0:bv32;
var ta___ra_ret_register_state_3_sub_0:bv32;

// ta_Table ta_table_register_state_3_interaction_0 ta_Actionlist ta_Declaration
type ta_table_register_state_3_interaction_0.action;
const unique ta_table_register_state_3_interaction_0.action.action_register_state_3_w : ta_table_register_state_3_interaction_0.action;
const unique ta_table_register_state_3_interaction_0.action.action_register_state_3_r : ta_table_register_state_3_interaction_0.action;
const unique ta_table_register_state_3_interaction_0.action.action_register_state_3_r_timer : ta_table_register_state_3_interaction_0.action;
const unique ta_table_register_state_3_interaction_0.action.action_register_state_3_sub : ta_table_register_state_3_interaction_0.action;
const unique ta_table_register_state_3_interaction_0.action.no_action_5 : ta_table_register_state_3_interaction_0.action;
var ta_table_register_state_3_interaction_0.action_run : ta_table_register_state_3_interaction_0.action;
var ta_table_register_state_3_interaction_0.hit : bool;

// ta_Register ta_register_address_h_record
var ta_register_address_h_record:[bv32]bv32;
var ta_register_address_h_record__last_index:bv32;
var ta_register_address_h_record__last_value:bv32;
var ta_register_address_h_record__last_old_value:bv32;
var ta_register_address_h_record__wrote_any:bool;
var ta_register_address_h_record__wrote_index0:bool;
var ta_register_address_h_record__last0_old_value:bv32;
var ta_register_address_h_record__last0_value:bv32;
var ta_register_address_h_record__next_write_site:int;
var ta_register_address_h_record__last_write_site:int;
const ta_register_address_h_record.size:bv32;
axiom ta_register_address_h_record.size == 14000bv32;

// ta_Register ta_register_address_l_record
var ta_register_address_l_record:[bv32]bv32;
var ta_register_address_l_record__last_index:bv32;
var ta_register_address_l_record__last_value:bv32;
var ta_register_address_l_record__last_old_value:bv32;
var ta_register_address_l_record__wrote_any:bool;
var ta_register_address_l_record__wrote_index0:bool;
var ta_register_address_l_record__last0_old_value:bv32;
var ta_register_address_l_record__last0_value:bv32;
var ta_register_address_l_record__next_write_site:int;
var ta_register_address_l_record__last_write_site:int;
const ta_register_address_l_record.size:bv32;
axiom ta_register_address_l_record.size == 14000bv32;

// ta_Register ta_register_address_h_record_4
var ta_register_address_h_record_4:[bv32]bv32;
var ta_register_address_h_record_4__last_index:bv32;
var ta_register_address_h_record_4__last_value:bv32;
var ta_register_address_h_record_4__last_old_value:bv32;
var ta_register_address_h_record_4__wrote_any:bool;
var ta_register_address_h_record_4__wrote_index0:bool;
var ta_register_address_h_record_4__last0_old_value:bv32;
var ta_register_address_h_record_4__last0_value:bv32;
var ta_register_address_h_record_4__next_write_site:int;
var ta_register_address_h_record_4__last_write_site:int;
const ta_register_address_h_record_4.size:bv32;
axiom ta_register_address_h_record_4.size == 14000bv32;

// ta_Register ta_register_address_l_record_4
var ta_register_address_l_record_4:[bv32]bv32;
var ta_register_address_l_record_4__last_index:bv32;
var ta_register_address_l_record_4__last_value:bv32;
var ta_register_address_l_record_4__last_old_value:bv32;
var ta_register_address_l_record_4__wrote_any:bool;
var ta_register_address_l_record_4__wrote_index0:bool;
var ta_register_address_l_record_4__last0_old_value:bv32;
var ta_register_address_l_record_4__last0_value:bv32;
var ta_register_address_l_record_4__next_write_site:int;
var ta_register_address_l_record_4__last_write_site:int;
const ta_register_address_l_record_4.size:bv32;
axiom ta_register_address_l_record_4.size == 14000bv32;

// ta_Register ta_register_address_h_record_5
var ta_register_address_h_record_5:[bv32]bv32;
var ta_register_address_h_record_5__last_index:bv32;
var ta_register_address_h_record_5__last_value:bv32;
var ta_register_address_h_record_5__last_old_value:bv32;
var ta_register_address_h_record_5__wrote_any:bool;
var ta_register_address_h_record_5__wrote_index0:bool;
var ta_register_address_h_record_5__last0_old_value:bv32;
var ta_register_address_h_record_5__last0_value:bv32;
var ta_register_address_h_record_5__next_write_site:int;
var ta_register_address_h_record_5__last_write_site:int;
const ta_register_address_h_record_5.size:bv32;
axiom ta_register_address_h_record_5.size == 14000bv32;

// ta_Register ta_register_address_l_record_5
var ta_register_address_l_record_5:[bv32]bv32;
var ta_register_address_l_record_5__last_index:bv32;
var ta_register_address_l_record_5__last_value:bv32;
var ta_register_address_l_record_5__last_old_value:bv32;
var ta_register_address_l_record_5__wrote_any:bool;
var ta_register_address_l_record_5__wrote_index0:bool;
var ta_register_address_l_record_5__last0_old_value:bv32;
var ta_register_address_l_record_5__last0_value:bv32;
var ta_register_address_l_record_5__next_write_site:int;
var ta_register_address_l_record_5__last_write_site:int;
const ta_register_address_l_record_5.size:bv32;
axiom ta_register_address_l_record_5.size == 14000bv32;

// ta_Register ta_register_address_h_record_6
var ta_register_address_h_record_6:[bv32]bv32;
var ta_register_address_h_record_6__last_index:bv32;
var ta_register_address_h_record_6__last_value:bv32;
var ta_register_address_h_record_6__last_old_value:bv32;
var ta_register_address_h_record_6__wrote_any:bool;
var ta_register_address_h_record_6__wrote_index0:bool;
var ta_register_address_h_record_6__last0_old_value:bv32;
var ta_register_address_h_record_6__last0_value:bv32;
var ta_register_address_h_record_6__next_write_site:int;
var ta_register_address_h_record_6__last_write_site:int;
const ta_register_address_h_record_6.size:bv32;
axiom ta_register_address_h_record_6.size == 14000bv32;

// ta_Register ta_register_address_l_record_6
var ta_register_address_l_record_6:[bv32]bv32;
var ta_register_address_l_record_6__last_index:bv32;
var ta_register_address_l_record_6__last_value:bv32;
var ta_register_address_l_record_6__last_old_value:bv32;
var ta_register_address_l_record_6__wrote_any:bool;
var ta_register_address_l_record_6__wrote_index0:bool;
var ta_register_address_l_record_6__last0_old_value:bv32;
var ta_register_address_l_record_6__last0_value:bv32;
var ta_register_address_l_record_6__next_write_site:int;
var ta_register_address_l_record_6__last_write_site:int;
const ta_register_address_l_record_6.size:bv32;
axiom ta_register_address_l_record_6.size == 14000bv32;
var ta___ra_val_register_address_h_record_0_read_0:bv32;
var ta___ra_ret_register_address_h_record_0_read_0:bv32;
var ta___ra_val_register_address_h_record_0_write_0:bv32;
var ta___ra_ret_register_address_h_record_0_write_0:bv32;

// ta_Table ta_table_register_address_h_record_0_interaction_0 ta_Actionlist ta_Declaration
type ta_table_register_address_h_record_0_interaction_0.action;
const unique ta_table_register_address_h_record_0_interaction_0.action.no_action_6 : ta_table_register_address_h_record_0_interaction_0.action;
const unique ta_table_register_address_h_record_0_interaction_0.action.action_register_address_h_record_0_read : ta_table_register_address_h_record_0_interaction_0.action;
const unique ta_table_register_address_h_record_0_interaction_0.action.action_register_address_h_record_0_write : ta_table_register_address_h_record_0_interaction_0.action;
const unique ta_table_register_address_h_record_0_interaction_0.action.action_register_address_h_record_0_read_timer : ta_table_register_address_h_record_0_interaction_0.action;
var ta_table_register_address_h_record_0_interaction_0.action_run : ta_table_register_address_h_record_0_interaction_0.action;
var ta_table_register_address_h_record_0_interaction_0.hit : bool;
var ta___ra_val_register_address_l_record_0_read_0:bv32;
var ta___ra_ret_register_address_l_record_0_read_0:bv32;
var ta___ra_val_register_address_l_record_0_write_0:bv32;
var ta___ra_ret_register_address_l_record_0_write_0:bv32;

// ta_Table ta_table_register_address_l_record_0_interaction_0 ta_Actionlist ta_Declaration
type ta_table_register_address_l_record_0_interaction_0.action;
const unique ta_table_register_address_l_record_0_interaction_0.action.no_action_7 : ta_table_register_address_l_record_0_interaction_0.action;
const unique ta_table_register_address_l_record_0_interaction_0.action.action_register_address_l_record_0_read : ta_table_register_address_l_record_0_interaction_0.action;
const unique ta_table_register_address_l_record_0_interaction_0.action.action_register_address_l_record_0_write : ta_table_register_address_l_record_0_interaction_0.action;
const unique ta_table_register_address_l_record_0_interaction_0.action.action_register_address_l_record_0_read_timer : ta_table_register_address_l_record_0_interaction_0.action;
var ta_table_register_address_l_record_0_interaction_0.action_run : ta_table_register_address_l_record_0_interaction_0.action;
var ta_table_register_address_l_record_0_interaction_0.hit : bool;
var ta___ra_val_register_address_h_record_1_read_0:bv32;
var ta___ra_ret_register_address_h_record_1_read_0:bv32;
var ta___ra_val_register_address_h_record_1_write_0:bv32;
var ta___ra_ret_register_address_h_record_1_write_0:bv32;

// ta_Table ta_table_register_address_h_record_1_interaction_0 ta_Actionlist ta_Declaration
type ta_table_register_address_h_record_1_interaction_0.action;
const unique ta_table_register_address_h_record_1_interaction_0.action.no_action_8 : ta_table_register_address_h_record_1_interaction_0.action;
const unique ta_table_register_address_h_record_1_interaction_0.action.action_register_address_h_record_1_read : ta_table_register_address_h_record_1_interaction_0.action;
const unique ta_table_register_address_h_record_1_interaction_0.action.action_register_address_h_record_1_write : ta_table_register_address_h_record_1_interaction_0.action;
const unique ta_table_register_address_h_record_1_interaction_0.action.action_register_address_h_record_1_read_timer : ta_table_register_address_h_record_1_interaction_0.action;
var ta_table_register_address_h_record_1_interaction_0.action_run : ta_table_register_address_h_record_1_interaction_0.action;
var ta_table_register_address_h_record_1_interaction_0.hit : bool;
var ta___ra_val_register_address_l_record_1_read_0:bv32;
var ta___ra_ret_register_address_l_record_1_read_0:bv32;
var ta___ra_val_register_address_l_record_1_write_0:bv32;
var ta___ra_ret_register_address_l_record_1_write_0:bv32;

// ta_Table ta_table_register_address_l_record_1_interaction_0 ta_Actionlist ta_Declaration
type ta_table_register_address_l_record_1_interaction_0.action;
const unique ta_table_register_address_l_record_1_interaction_0.action.no_action_9 : ta_table_register_address_l_record_1_interaction_0.action;
const unique ta_table_register_address_l_record_1_interaction_0.action.action_register_address_l_record_1_read : ta_table_register_address_l_record_1_interaction_0.action;
const unique ta_table_register_address_l_record_1_interaction_0.action.action_register_address_l_record_1_write : ta_table_register_address_l_record_1_interaction_0.action;
const unique ta_table_register_address_l_record_1_interaction_0.action.action_register_address_l_record_1_read_timer : ta_table_register_address_l_record_1_interaction_0.action;
var ta_table_register_address_l_record_1_interaction_0.action_run : ta_table_register_address_l_record_1_interaction_0.action;
var ta_table_register_address_l_record_1_interaction_0.hit : bool;
var ta___ra_val_register_address_h_record_2_read_0:bv32;
var ta___ra_ret_register_address_h_record_2_read_0:bv32;
var ta___ra_val_register_address_h_record_2_write_0:bv32;
var ta___ra_ret_register_address_h_record_2_write_0:bv32;

// ta_Table ta_table_register_address_h_record_2_interaction_0 ta_Actionlist ta_Declaration
type ta_table_register_address_h_record_2_interaction_0.action;
const unique ta_table_register_address_h_record_2_interaction_0.action.no_action_10 : ta_table_register_address_h_record_2_interaction_0.action;
const unique ta_table_register_address_h_record_2_interaction_0.action.action_register_address_h_record_2_read : ta_table_register_address_h_record_2_interaction_0.action;
const unique ta_table_register_address_h_record_2_interaction_0.action.action_register_address_h_record_2_write : ta_table_register_address_h_record_2_interaction_0.action;
const unique ta_table_register_address_h_record_2_interaction_0.action.action_register_address_h_record_2_read_timer : ta_table_register_address_h_record_2_interaction_0.action;
var ta_table_register_address_h_record_2_interaction_0.action_run : ta_table_register_address_h_record_2_interaction_0.action;
var ta_table_register_address_h_record_2_interaction_0.hit : bool;
var ta___ra_val_register_address_l_record_2_read_0:bv32;
var ta___ra_ret_register_address_l_record_2_read_0:bv32;
var ta___ra_val_register_address_l_record_2_write_0:bv32;
var ta___ra_ret_register_address_l_record_2_write_0:bv32;

// ta_Table ta_table_register_address_l_record_2_interaction_0 ta_Actionlist ta_Declaration
type ta_table_register_address_l_record_2_interaction_0.action;
const unique ta_table_register_address_l_record_2_interaction_0.action.no_action_11 : ta_table_register_address_l_record_2_interaction_0.action;
const unique ta_table_register_address_l_record_2_interaction_0.action.action_register_address_l_record_2_read : ta_table_register_address_l_record_2_interaction_0.action;
const unique ta_table_register_address_l_record_2_interaction_0.action.action_register_address_l_record_2_write : ta_table_register_address_l_record_2_interaction_0.action;
const unique ta_table_register_address_l_record_2_interaction_0.action.action_register_address_l_record_2_read_timer : ta_table_register_address_l_record_2_interaction_0.action;
var ta_table_register_address_l_record_2_interaction_0.action_run : ta_table_register_address_l_record_2_interaction_0.action;
var ta_table_register_address_l_record_2_interaction_0.hit : bool;
var ta___ra_val_register_address_h_record_3_read_0:bv32;
var ta___ra_ret_register_address_h_record_3_read_0:bv32;
var ta___ra_val_register_address_h_record_3_write_0:bv32;
var ta___ra_ret_register_address_h_record_3_write_0:bv32;

// ta_Table ta_table_register_address_h_record_3_interaction_0 ta_Actionlist ta_Declaration
type ta_table_register_address_h_record_3_interaction_0.action;
const unique ta_table_register_address_h_record_3_interaction_0.action.no_action_12 : ta_table_register_address_h_record_3_interaction_0.action;
const unique ta_table_register_address_h_record_3_interaction_0.action.action_register_address_h_record_3_read : ta_table_register_address_h_record_3_interaction_0.action;
const unique ta_table_register_address_h_record_3_interaction_0.action.action_register_address_h_record_3_write : ta_table_register_address_h_record_3_interaction_0.action;
const unique ta_table_register_address_h_record_3_interaction_0.action.action_register_address_h_record_3_read_timer : ta_table_register_address_h_record_3_interaction_0.action;
var ta_table_register_address_h_record_3_interaction_0.action_run : ta_table_register_address_h_record_3_interaction_0.action;
var ta_table_register_address_h_record_3_interaction_0.hit : bool;
var ta___ra_val_register_address_l_record_3_read_0:bv32;
var ta___ra_ret_register_address_l_record_3_read_0:bv32;
var ta___ra_val_register_address_l_record_3_write_0:bv32;
var ta___ra_ret_register_address_l_record_3_write_0:bv32;

// ta_Table ta_table_register_address_l_record_3_interaction_0 ta_Actionlist ta_Declaration
type ta_table_register_address_l_record_3_interaction_0.action;
const unique ta_table_register_address_l_record_3_interaction_0.action.no_action_13 : ta_table_register_address_l_record_3_interaction_0.action;
const unique ta_table_register_address_l_record_3_interaction_0.action.action_register_address_l_record_3_read : ta_table_register_address_l_record_3_interaction_0.action;
const unique ta_table_register_address_l_record_3_interaction_0.action.action_register_address_l_record_3_write : ta_table_register_address_l_record_3_interaction_0.action;
const unique ta_table_register_address_l_record_3_interaction_0.action.action_register_address_l_record_3_read_timer : ta_table_register_address_l_record_3_interaction_0.action;
var ta_table_register_address_l_record_3_interaction_0.action_run : ta_table_register_address_l_record_3_interaction_0.action;
var ta_table_register_address_l_record_3_interaction_0.hit : bool;

// ta_Table ta_table_send_to_somewhere_0 ta_Actionlist ta_Declaration
type ta_table_send_to_somewhere_0.action;
const unique ta_table_send_to_somewhere_0.action.action_send_to_master : ta_table_send_to_somewhere_0.action;
const unique ta_table_send_to_somewhere_0.action.action_send_to_client : ta_table_send_to_somewhere_0.action;
const unique ta_table_send_to_somewhere_0.action.action_send_to_self : ta_table_send_to_somewhere_0.action;
const unique ta_table_send_to_somewhere_0.action.action_send_to_CS : ta_table_send_to_somewhere_0.action;
const unique ta_table_send_to_somewhere_0.action.action_send_to_CS_1 : ta_table_send_to_somewhere_0.action;
const unique ta_table_send_to_somewhere_0.action.action_send_to_CS_2 : ta_table_send_to_somewhere_0.action;
const unique ta_table_send_to_somewhere_0.action.action_send_to_CS_3 : ta_table_send_to_somewhere_0.action;
const unique ta_table_send_to_somewhere_0.action.action_send_to_CS_4 : ta_table_send_to_somewhere_0.action;
const unique ta_table_send_to_somewhere_0.action.no_action_14 : ta_table_send_to_somewhere_0.action;
var ta_table_send_to_somewhere_0.action_run : ta_table_send_to_somewhere_0.action;
var ta_table_send_to_somewhere_0.hit : bool;

// ta_Table ta_table_state_check_0 ta_Actionlist ta_Declaration
type ta_table_state_check_0.action;
const unique ta_table_state_check_0.action.action_state_failed : ta_table_state_check_0.action;
const unique ta_table_state_check_0.action.no_action_15 : ta_table_state_check_0.action;
var ta_table_state_check_0.action_run : ta_table_state_check_0.action;
var ta_table_state_check_0.hit : bool;

// ta_Table ta_table_success_check_0 ta_Actionlist ta_Declaration
type ta_table_success_check_0.action;
const unique ta_table_success_check_0.action.action_op_change_to_1 : ta_table_success_check_0.action;
const unique ta_table_success_check_0.action.action_op_change_to_2 : ta_table_success_check_0.action;
const unique ta_table_success_check_0.action.no_action_16 : ta_table_success_check_0.action;
var ta_table_success_check_0.action_run : ta_table_success_check_0.action;
var ta_table_success_check_0.hit : bool;
var ta___ra_val_register_request_id_low_add_0:bv32;
var ta___ra_ret_register_request_id_low_add_0:bv32;

function {:builtin "bvshl"} shl.bv32(ta_left:bv32, ta_right:bv32) returns(bv32);

function {:builtin "bvuge"} buge.bv32(ta_left:bv32, ta_right:bv32) returns(bool);
var ta_meta.session_id:ta_MirrorId_t;
var ta_meta.no_use:bv8;
var ta_meta.id_1:bv32;
var ta_meta.offset_1:bv32;
var ta_meta.id_2:bv32;
var ta_meta.offset_2:bv32;
var ta_meta.id_3:bv32;
var ta_meta.offset_3:bv32;

// ta_Header ta_egress_intrinsic_metadata_t
var ta_eg_intr_md:ta_Ref;
var ta_eg_intr_md.valid:bool;
var ta_eg_intr_md._pad0:bv7;
var ta_eg_intr_md.egress_port:ta_PortId_t;
var ta_eg_intr_md._pad1:bv5;
var ta_eg_intr_md.enq_qdepth:bv19;
var ta_eg_intr_md._pad2:bv6;
var ta_eg_intr_md.enq_congest_stat:bv2;
var ta_eg_intr_md._pad3:bv14;
var ta_eg_intr_md.enq_tstamp:bv18;
var ta_eg_intr_md._pad4:bv5;
var ta_eg_intr_md.deq_qdepth:bv19;
var ta_eg_intr_md._pad5:bv6;
var ta_eg_intr_md.deq_congest_stat:bv2;
var ta_eg_intr_md.app_pool_congest_stat:bv8;
var ta_eg_intr_md._pad6:bv14;
var ta_eg_intr_md.deq_timedelta:bv18;
var ta_eg_intr_md.egress_rid:bv16;
var ta_eg_intr_md._pad7:bv7;
var ta_eg_intr_md.egress_rid_first:bv1;
var ta_eg_intr_md._pad8:bv3;
var ta_eg_intr_md.egress_qid:ta_QueueId_t;
var ta_eg_intr_md._pad9:bv5;
var ta_eg_intr_md.egress_cos:bv3;
var ta_eg_intr_md._pad10:bv7;
var ta_eg_intr_md.deflection_flag:bv1;
var ta_eg_intr_md.pkt_length:bv16;

// ta_Header ta_mirror_h
var ta_mirror_md_0:ta_Ref;
var ta_mirror_md_0.valid:bool;
var ta_mirror_md_0.pkt_type:bv8;
var ta_eg_prsr_md:ta_egress_intrinsic_metadata_from_parser_t;
var ta_eg_prsr_md.global_tstamp:bv48;
var ta_eg_prsr_md.global_ver:bv32;
var ta_eg_prsr_md.parser_err:bv16;
var ta_eg_dprsr_md:ta_egress_intrinsic_metadata_for_deparser_t;
var ta_eg_dprsr_md.drop_ctl:bv3;
var ta_eg_dprsr_md.mirror_type:ta_MirrorType_t;
var ta_eg_dprsr_md.coalesce_flush:bv1;
var ta_eg_dprsr_md.coalesce_length:bv7;
var ta_eg_oport_md:ta_egress_intrinsic_metadata_for_output_port_t;
var ta_eg_oport_md.capture_tstamp_on_tx:bv1;
var ta_eg_oport_md.update_delay_on_tx:bv1;

// ta_Table ta_table_check_timer_0 ta_Actionlist ta_Declaration
type ta_table_check_timer_0.action;
const unique ta_table_check_timer_0.action.action_send_to_master_2 : ta_table_check_timer_0.action;
const unique ta_table_check_timer_0.action.action_no_action : ta_table_check_timer_0.action;
var ta_table_check_timer_0.action_run : ta_table_check_timer_0.action;
var ta_table_check_timer_0.hit : bool;

function {:builtin "bvsub"} sub.bv17(ta_left:bv17, ta_right:bv17) returns(bv17);

function {:builtin "bvsub"} sub.bv33(ta_left:bv33, ta_right:bv33) returns(bv33);

// ta_Control ta_aEgress
procedure {:inline 1} ta_aEgress()
	modifies ta_eg_dprsr_md.mirror_type, ta_hdr.albion.operation, ta_hdr.albion_timer.state_0, ta_hdr.albion_timer.state_1, ta_hdr.albion_timer.state_2, ta_hdr.albion_timer.state_3, ta_hdr.albion_timer.times, ta_isValid, ta_meta.no_use, ta_meta.session_id, ta_p4b_clone_e2e, ta_table_check_timer_0.action_run, ta_table_check_timer_0.hit;
{
    if(ta_isValid[ta_hdr.mirror_1]){
        call ta_setInvalid(ta_hdr.mirror_1);
    }
    else{
        if((ta_hdr.albion.operation == 100bv32)){
            call ta_table_check_timer_0.apply();
        }
        if((ta_hdr.albion.operation == 101bv32)){
            if((ta_hdr.albion_timer.times == 0bv32)){
                ta_hdr.albion.operation := 100bv32;
            }
            else{
                ta_hdr.albion_timer.times := add.bv32(ta_hdr.albion_timer.times, 4294967295bv32);
            }
        }
    }
}

// ta_Control ta_aEgressDeparser
procedure {:inline 1} ta_aEgressDeparser()
{
    call ta_pkt.emit(ta_hdr);
}

// ta_Parser ta_aEgressParser
procedure {:inline 1} ta_aEgressParser()
	modifies ta_drop, ta_isValid, ta_mirror_md_0;
{
    goto ta_State$aEgressParser$start;

        ta_State$aEgressParser$start:
    call ta_packet_in.extract(ta_eg_intr_md);
    havoc ta_mirror_md_0;
    goto ta_State$aEgressParser$start$parse_mirror_2, ta_State$aEgressParser$start$DEFAULT;
    
ta_State$aEgressParser$start$parse_mirror_2:
    assume (ta_mirror_md_0.pkt_type == 3bv8);
    goto ta_State$aEgressParser$parse_mirror;

    ta_State$aEgressParser$start$DEFAULT:
    assume(!(ta_mirror_md_0.pkt_type == 3bv8));
    goto ta_State$aEgressParser$parse_ethernet;

        ta_State$aEgressParser$parse_mirror:
    call ta_packet_in.extract(ta_hdr.mirror_1);
    goto ta_State$aEgressParser$parse_ethernet;

        ta_State$aEgressParser$parse_ethernet:
    call ta_packet_in.extract(ta_hdr.ethernet);
    goto ta_State$aEgressParser$parse_ethernet$parse_albion_2, ta_State$aEgressParser$parse_ethernet$DEFAULT;
    
ta_State$aEgressParser$parse_ethernet$parse_albion_2:
    assume (ta_hdr.ethernet.ether_type == 21845bv16);
    goto ta_State$aEgressParser$parse_albion;

    ta_State$aEgressParser$parse_ethernet$DEFAULT:
    assume(!(ta_hdr.ethernet.ether_type == 21845bv16));
    goto ta_State$reject;

        ta_State$aEgressParser$parse_albion:
    call ta_packet_in.extract(ta_hdr.albion);
    goto ta_State$aEgressParser$parse_albion$parse_albion_timer_3, ta_State$aEgressParser$parse_albion$parse_albion_timer_2, ta_State$aEgressParser$parse_albion$DEFAULT;
    
ta_State$aEgressParser$parse_albion$parse_albion_timer_3:
    assume (ta_hdr.albion.operation == 100bv32);
    goto ta_State$aEgressParser$parse_albion_timer;
    
ta_State$aEgressParser$parse_albion$parse_albion_timer_2:
    assume (ta_hdr.albion.operation == 101bv32);
    goto ta_State$aEgressParser$parse_albion_timer;

    ta_State$aEgressParser$parse_albion$DEFAULT:
    assume(!(ta_hdr.albion.operation == 100bv32)&&!(ta_hdr.albion.operation == 101bv32));
    goto ta_State$aEgressParser$parse_albion_data;

        ta_State$aEgressParser$parse_albion_data:
    call ta_packet_in.extract(ta_hdr.albion_data);
    goto ta_State$accept;

        ta_State$aEgressParser$parse_albion_timer:
    call ta_packet_in.extract(ta_hdr.albion_timer);
    goto ta_State$accept;

    ta_State$accept:
    call ta_accept();
    goto ta_Exit;

    ta_State$reject:
    call ta_reject();
    goto ta_Exit;

    ta_Exit:
}

// ta_Control ta_aIngress
procedure {:inline 1} ta_aIngress()
	modifies ta___ra_ret_register_address_h_record_0_read_0, ta___ra_ret_register_address_h_record_0_write_0, ta___ra_ret_register_address_h_record_1_read_0, ta___ra_ret_register_address_h_record_1_write_0, ta___ra_ret_register_address_h_record_2_read_0, ta___ra_ret_register_address_h_record_2_write_0, ta___ra_ret_register_address_h_record_3_read_0, ta___ra_ret_register_address_h_record_3_write_0, ta___ra_ret_register_address_l_record_0_read_0, ta___ra_ret_register_address_l_record_0_write_0, ta___ra_ret_register_address_l_record_1_read_0, ta___ra_ret_register_address_l_record_1_write_0, ta___ra_ret_register_address_l_record_2_read_0, ta___ra_ret_register_address_l_record_2_write_0, ta___ra_ret_register_address_l_record_3_read_0, ta___ra_ret_register_address_l_record_3_write_0, ta___ra_ret_register_num_add_0, ta___ra_ret_register_num_zero_0, ta___ra_ret_register_request_id_high_add_0, ta___ra_ret_register_request_id_low_add_0, ta___ra_ret_register_state_0_r_0, ta___ra_ret_register_state_0_sub_0, ta___ra_ret_register_state_0_w_0, ta___ra_ret_register_state_1_r_0, ta___ra_ret_register_state_1_sub_0, ta___ra_ret_register_state_1_w_0, ta___ra_ret_register_state_2_r_0, ta___ra_ret_register_state_2_sub_0, ta___ra_ret_register_state_2_w_0, ta___ra_ret_register_state_3_r_0, ta___ra_ret_register_state_3_sub_0, ta___ra_ret_register_state_3_w_0, ta___ra_ret_register_timer_add_0, ta___ra_ret_register_timer_read_0, ta___ra_val_register_address_h_record_0_read_0, ta___ra_val_register_address_h_record_0_write_0, ta___ra_val_register_address_h_record_1_read_0, ta___ra_val_register_address_h_record_1_write_0, ta___ra_val_register_address_h_record_2_read_0, ta___ra_val_register_address_h_record_2_write_0, ta___ra_val_register_address_h_record_3_read_0, ta___ra_val_register_address_h_record_3_write_0, ta___ra_val_register_address_l_record_0_read_0, ta___ra_val_register_address_l_record_0_write_0, ta___ra_val_register_address_l_record_1_read_0, ta___ra_val_register_address_l_record_1_write_0, ta___ra_val_register_address_l_record_2_read_0, ta___ra_val_register_address_l_record_2_write_0, ta___ra_val_register_address_l_record_3_read_0, ta___ra_val_register_address_l_record_3_write_0, ta___ra_val_register_num_add_0, ta___ra_val_register_num_zero_0, ta___ra_val_register_request_id_high_add_0, ta___ra_val_register_request_id_low_add_0, ta___ra_val_register_state_0_r_0, ta___ra_val_register_state_0_sub_0, ta___ra_val_register_state_0_w_0, ta___ra_val_register_state_1_r_0, ta___ra_val_register_state_1_sub_0, ta___ra_val_register_state_1_w_0, ta___ra_val_register_state_2_r_0, ta___ra_val_register_state_2_sub_0, ta___ra_val_register_state_2_w_0, ta___ra_val_register_state_3_r_0, ta___ra_val_register_state_3_sub_0, ta___ra_val_register_state_3_w_0, ta___ra_val_register_timer_add_0, ta___ra_val_register_timer_read_0, ta_hdr.albion.CS_id_1, ta_hdr.albion.index, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion.port, ta_hdr.albion.request_id_high, ta_hdr.albion.request_id_low, ta_hdr.albion.time, ta_hdr.albion_timer.address_high_0, ta_hdr.albion_timer.address_high_1, ta_hdr.albion_timer.address_high_2, ta_hdr.albion_timer.address_high_3, ta_hdr.albion_timer.address_low_0, ta_hdr.albion_timer.address_low_1, ta_hdr.albion_timer.address_low_2, ta_hdr.albion_timer.address_low_3, ta_hdr.albion_timer.state_0, ta_hdr.albion_timer.state_1, ta_hdr.albion_timer.state_2, ta_hdr.albion_timer.state_3, ta_ig_tm_md.ucast_egress_port, ta_meta.state, ta_meta.state_sub, ta_register_address_h_record, ta_register_address_h_record_4, ta_register_address_h_record_4__last0_old_value, ta_register_address_h_record_4__last0_value, ta_register_address_h_record_4__last_index, ta_register_address_h_record_4__last_old_value, ta_register_address_h_record_4__last_value, ta_register_address_h_record_4__last_write_site, ta_register_address_h_record_4__next_write_site, ta_register_address_h_record_4__wrote_any, ta_register_address_h_record_4__wrote_index0, ta_register_address_h_record_5, ta_register_address_h_record_5__last0_old_value, ta_register_address_h_record_5__last0_value, ta_register_address_h_record_5__last_index, ta_register_address_h_record_5__last_old_value, ta_register_address_h_record_5__last_value, ta_register_address_h_record_5__last_write_site, ta_register_address_h_record_5__next_write_site, ta_register_address_h_record_5__wrote_any, ta_register_address_h_record_5__wrote_index0, ta_register_address_h_record_6, ta_register_address_h_record_6__last0_old_value, ta_register_address_h_record_6__last0_value, ta_register_address_h_record_6__last_index, ta_register_address_h_record_6__last_old_value, ta_register_address_h_record_6__last_value, ta_register_address_h_record_6__last_write_site, ta_register_address_h_record_6__next_write_site, ta_register_address_h_record_6__wrote_any, ta_register_address_h_record_6__wrote_index0, ta_register_address_h_record__last0_old_value, ta_register_address_h_record__last0_value, ta_register_address_h_record__last_index, ta_register_address_h_record__last_old_value, ta_register_address_h_record__last_value, ta_register_address_h_record__last_write_site, ta_register_address_h_record__next_write_site, ta_register_address_h_record__wrote_any, ta_register_address_h_record__wrote_index0, ta_register_address_l_record, ta_register_address_l_record_4, ta_register_address_l_record_4__last0_old_value, ta_register_address_l_record_4__last0_value, ta_register_address_l_record_4__last_index, ta_register_address_l_record_4__last_old_value, ta_register_address_l_record_4__last_value, ta_register_address_l_record_4__last_write_site, ta_register_address_l_record_4__next_write_site, ta_register_address_l_record_4__wrote_any, ta_register_address_l_record_4__wrote_index0, ta_register_address_l_record_5, ta_register_address_l_record_5__last0_old_value, ta_register_address_l_record_5__last0_value, ta_register_address_l_record_5__last_index, ta_register_address_l_record_5__last_old_value, ta_register_address_l_record_5__last_value, ta_register_address_l_record_5__last_write_site, ta_register_address_l_record_5__next_write_site, ta_register_address_l_record_5__wrote_any, ta_register_address_l_record_5__wrote_index0, ta_register_address_l_record_6, ta_register_address_l_record_6__last0_old_value, ta_register_address_l_record_6__last0_value, ta_register_address_l_record_6__last_index, ta_register_address_l_record_6__last_old_value, ta_register_address_l_record_6__last_value, ta_register_address_l_record_6__last_write_site, ta_register_address_l_record_6__next_write_site, ta_register_address_l_record_6__wrote_any, ta_register_address_l_record_6__wrote_index0, ta_register_address_l_record__last0_old_value, ta_register_address_l_record__last0_value, ta_register_address_l_record__last_index, ta_register_address_l_record__last_old_value, ta_register_address_l_record__last_value, ta_register_address_l_record__last_write_site, ta_register_address_l_record__next_write_site, ta_register_address_l_record__wrote_any, ta_register_address_l_record__wrote_index0, ta_register_num_0, ta_register_num_0__last0_old_value, ta_register_num_0__last0_value, ta_register_num_0__last_index, ta_register_num_0__last_old_value, ta_register_num_0__last_value, ta_register_num_0__last_write_site, ta_register_num_0__next_write_site, ta_register_num_0__wrote_any, ta_register_num_0__wrote_index0, ta_register_request_id_high_0, ta_register_request_id_high_0__last0_old_value, ta_register_request_id_high_0__last0_value, ta_register_request_id_high_0__last_index, ta_register_request_id_high_0__last_old_value, ta_register_request_id_high_0__last_value, ta_register_request_id_high_0__last_write_site, ta_register_request_id_high_0__next_write_site, ta_register_request_id_high_0__wrote_any, ta_register_request_id_high_0__wrote_index0, ta_register_request_id_low_0, ta_register_request_id_low_0__last0_old_value, ta_register_request_id_low_0__last0_value, ta_register_request_id_low_0__last_index, ta_register_request_id_low_0__last_old_value, ta_register_request_id_low_0__last_value, ta_register_request_id_low_0__last_write_site, ta_register_request_id_low_0__next_write_site, ta_register_request_id_low_0__wrote_any, ta_register_request_id_low_0__wrote_index0, ta_register_state, ta_register_state_4, ta_register_state_4__last0_old_value, ta_register_state_4__last0_value, ta_register_state_4__last_index, ta_register_state_4__last_old_value, ta_register_state_4__last_value, ta_register_state_4__last_write_site, ta_register_state_4__next_write_site, ta_register_state_4__wrote_any, ta_register_state_4__wrote_index0, ta_register_state_5, ta_register_state_5__last0_old_value, ta_register_state_5__last0_value, ta_register_state_5__last_index, ta_register_state_5__last_old_value, ta_register_state_5__last_value, ta_register_state_5__last_write_site, ta_register_state_5__next_write_site, ta_register_state_5__wrote_any, ta_register_state_5__wrote_index0, ta_register_state_6, ta_register_state_6__last0_old_value, ta_register_state_6__last0_value, ta_register_state_6__last_index, ta_register_state_6__last_old_value, ta_register_state_6__last_value, ta_register_state_6__last_write_site, ta_register_state_6__next_write_site, ta_register_state_6__wrote_any, ta_register_state_6__wrote_index0, ta_register_state__last0_old_value, ta_register_state__last0_value, ta_register_state__last_index, ta_register_state__last_old_value, ta_register_state__last_value, ta_register_state__last_write_site, ta_register_state__next_write_site, ta_register_state__wrote_any, ta_register_state__wrote_index0, ta_register_timer_0, ta_register_timer_0__last0_old_value, ta_register_timer_0__last0_value, ta_register_timer_0__last_index, ta_register_timer_0__last_old_value, ta_register_timer_0__last_value, ta_register_timer_0__last_write_site, ta_register_timer_0__next_write_site, ta_register_timer_0__wrote_any, ta_register_timer_0__wrote_index0, ta_table_register_address_h_record_0_interaction_0.action_run, ta_table_register_address_h_record_0_interaction_0.hit, ta_table_register_address_h_record_1_interaction_0.action_run, ta_table_register_address_h_record_1_interaction_0.hit, ta_table_register_address_h_record_2_interaction_0.action_run, ta_table_register_address_h_record_2_interaction_0.hit, ta_table_register_address_h_record_3_interaction_0.action_run, ta_table_register_address_h_record_3_interaction_0.hit, ta_table_register_address_l_record_0_interaction_0.action_run, ta_table_register_address_l_record_0_interaction_0.hit, ta_table_register_address_l_record_1_interaction_0.action_run, ta_table_register_address_l_record_1_interaction_0.hit, ta_table_register_address_l_record_2_interaction_0.action_run, ta_table_register_address_l_record_2_interaction_0.hit, ta_table_register_address_l_record_3_interaction_0.action_run, ta_table_register_address_l_record_3_interaction_0.hit, ta_table_register_num_interaction_0.action_run, ta_table_register_num_interaction_0.hit, ta_table_register_request_id_high_interaction_0.action_run, ta_table_register_request_id_high_interaction_0.hit, ta_table_register_state_0_interaction_0.action_run, ta_table_register_state_0_interaction_0.hit, ta_table_register_state_1_interaction_0.action_run, ta_table_register_state_1_interaction_0.hit, ta_table_register_state_2_interaction_0.action_run, ta_table_register_state_2_interaction_0.hit, ta_table_register_state_3_interaction_0.action_run, ta_table_register_state_3_interaction_0.hit, ta_table_register_timer_interaction_0.action_run, ta_table_register_timer_interaction_0.hit, ta_table_send_to_somewhere_0.action_run, ta_table_send_to_somewhere_0.hit, ta_table_state_check_0.action_run, ta_table_state_check_0.hit, ta_table_success_check_0.action_run, ta_table_success_check_0.hit;
{
    if(ta_isValid[ta_hdr.albion]){
        if((ta_hdr.albion.operation == 1bv32)){
            ta___ra_val_register_request_id_low_add_0 := ta_register_request_id_low_0.read(ta_register_request_id_low_0, 0bv32);
            call ta___ra_val_register_request_id_low_add_0, ta___ra_ret_register_request_id_low_add_0 := ta_register_request_id_low_add_0.apply(ta___ra_val_register_request_id_low_add_0, ta___ra_ret_register_request_id_low_add_0);
            ta_register_request_id_low_0__next_write_site := 1;
            call ta_register_request_id_low_0.write(0bv32, ta___ra_val_register_request_id_low_add_0);
            ta_hdr.albion.request_id_low := ta___ra_ret_register_request_id_low_add_0;
            call ta_table_register_num_interaction_0.apply();
            call ta_table_register_timer_interaction_0.apply();
        }
        else{
            if((ta_hdr.albion.operation == 100bv32)){
                call ta_table_register_num_interaction_0.apply();
                call ta_table_register_timer_interaction_0.apply();
            }
            else{
                if((ta_hdr.albion.operation == 30bv32)){
                    ta_meta.state_sub := 4294967294bv32;
                    ta_hdr.albion.operation := 33bv32;
                    ta_hdr.albion.CS_id_1 := 0bv32;
                }
                else{
                    if((ta_hdr.albion.operation == 31bv32)){
                        ta_meta.state_sub := 4294967293bv32;
                        ta_hdr.albion.operation := 33bv32;
                        ta_hdr.albion.CS_id_1 := 0bv32;
                    }
                    else{
                        if((ta_hdr.albion.operation == 32bv32)){
                            ta_meta.state_sub := 4294967291bv32;
                            ta_hdr.albion.operation := 33bv32;
                            ta_hdr.albion.CS_id_1 := 0bv32;
                        }
                    }
                }
            }
        }
        call ta_table_register_state_0_interaction_0.apply();
        call ta_table_register_address_h_record_0_interaction_0.apply();
        call ta_table_register_address_l_record_0_interaction_0.apply();
        if((ta_hdr.albion.operation == 1bv32)){
            call ta_table_register_request_id_high_interaction_0.apply();
            ta_hdr.albion.index := shl.bv32(ta_hdr.albion.time, 3bv32);
            if(buge.bv32(ta_hdr.albion.num, 8bv32)){
                ta_hdr.albion.operation := 200bv32;
            }
        }
        call ta_table_register_state_1_interaction_0.apply();
        call ta_table_register_address_h_record_1_interaction_0.apply();
        call ta_table_register_address_l_record_1_interaction_0.apply();
        if((ta_hdr.albion.operation == 1bv32)){
            ta_hdr.albion.index := add.bv32(ta_hdr.albion.index, ta_hdr.albion.num);
        }
        call ta_table_register_state_2_interaction_0.apply();
        call ta_table_register_address_h_record_2_interaction_0.apply();
        call ta_table_register_address_l_record_2_interaction_0.apply();
        call ta_table_register_state_3_interaction_0.apply();
        call ta_table_register_address_h_record_3_interaction_0.apply();
        call ta_table_register_address_l_record_3_interaction_0.apply();
        if((ta_hdr.albion.operation == 1bv32)){
            call ta_table_state_check_0.apply();
        }
        if((ta_hdr.albion.operation == 33bv32)){
            call ta_table_success_check_0.apply();
        }
        call ta_table_send_to_somewhere_0.apply();
    }
}

// ta_Control ta_aIngressDeparser
procedure {:inline 1} ta_aIngressDeparser()
{
    call ta_pkt.emit(ta_hdr);
}

// ta_Parser ta_aIngressParser
procedure {:inline 1} ta_aIngressParser()
	modifies ta_drop, ta_isValid;
{
    goto ta_State$aIngressParser$start;

        ta_State$aIngressParser$start:
    call ta_packet_in.extract(ta_ig_intr_md);
    call ta_pkt.advance(64bv32);
    call ta_packet_in.extract(ta_hdr.ethernet);
    goto ta_State$aIngressParser$start$parse_albion_2, ta_State$aIngressParser$start$DEFAULT;
    
ta_State$aIngressParser$start$parse_albion_2:
    assume (ta_hdr.ethernet.ether_type == 21845bv16);
    goto ta_State$aIngressParser$parse_albion;

    ta_State$aIngressParser$start$DEFAULT:
    assume(!(ta_hdr.ethernet.ether_type == 21845bv16));
    goto ta_State$reject;

        ta_State$aIngressParser$parse_albion:
    call ta_packet_in.extract(ta_hdr.albion);
    goto ta_State$aIngressParser$parse_albion$parse_albion_timer_3, ta_State$aIngressParser$parse_albion$parse_albion_timer_2, ta_State$aIngressParser$parse_albion$DEFAULT;
    
ta_State$aIngressParser$parse_albion$parse_albion_timer_3:
    assume (ta_hdr.albion.operation == 100bv32);
    goto ta_State$aIngressParser$parse_albion_timer;
    
ta_State$aIngressParser$parse_albion$parse_albion_timer_2:
    assume (ta_hdr.albion.operation == 101bv32);
    goto ta_State$aIngressParser$parse_albion_timer;

    ta_State$aIngressParser$parse_albion$DEFAULT:
    assume(!(ta_hdr.albion.operation == 100bv32)&&!(ta_hdr.albion.operation == 101bv32));
    goto ta_State$aIngressParser$parse_albion_data;

        ta_State$aIngressParser$parse_albion_data:
    call ta_packet_in.extract(ta_hdr.albion_data);
    goto ta_State$accept;

        ta_State$aIngressParser$parse_albion_timer:
    call ta_packet_in.extract(ta_hdr.albion_timer);
    goto ta_State$accept;

    ta_State$accept:
    call ta_accept();
    goto ta_Exit;

    ta_State$reject:
    call ta_reject();
    goto ta_Exit;

    ta_Exit:
}
procedure {:inline 1} ta_accept()
{
}

// ta_Action ta_action_no_action
procedure {:inline 1} ta_action_no_action()
	modifies ta_hdr.albion.operation, ta_hdr.albion_timer.times;
{
    ta_hdr.albion_timer.times := ta_hdr.albion_timer.const_time;
    ta_hdr.albion.operation := 101bv32;
}

// ta_Action ta_action_op_change_to_1
procedure {:inline 1} ta_action_op_change_to_1()
	modifies ta_hdr.albion.operation;
{
    ta_hdr.albion.operation := 34bv32;
}

// ta_Action ta_action_op_change_to_2
procedure {:inline 1} ta_action_op_change_to_2()
	modifies ta_hdr.albion.operation;
{
    ta_hdr.albion.operation := 35bv32;
}

// ta_Action ta_action_register_address_h_record_0_read
procedure {:inline 1} ta_action_register_address_h_record_0_read()
	modifies ta___ra_ret_register_address_h_record_0_read_0, ta___ra_val_register_address_h_record_0_read_0, ta_hdr.albion.address_h, ta_register_address_h_record, ta_register_address_h_record__last0_old_value, ta_register_address_h_record__last0_value, ta_register_address_h_record__last_index, ta_register_address_h_record__last_old_value, ta_register_address_h_record__last_value, ta_register_address_h_record__last_write_site, ta_register_address_h_record__next_write_site, ta_register_address_h_record__wrote_any, ta_register_address_h_record__wrote_index0;
{
    ta___ra_val_register_address_h_record_0_read_0 := ta_register_address_h_record.read(ta_register_address_h_record, ta_hdr.albion.time);
    call ta___ra_val_register_address_h_record_0_read_0, ta___ra_ret_register_address_h_record_0_read_0 := ta_register_address_h_record_0_read_0.apply(ta___ra_val_register_address_h_record_0_read_0, ta___ra_ret_register_address_h_record_0_read_0);
    ta_register_address_h_record__next_write_site := 1;
    call ta_register_address_h_record.write(ta_hdr.albion.time, ta___ra_val_register_address_h_record_0_read_0);
    ta_hdr.albion.address_h := ta___ra_ret_register_address_h_record_0_read_0;
}

// ta_Action ta_action_register_address_h_record_0_read_timer
procedure {:inline 1} ta_action_register_address_h_record_0_read_timer()
	modifies ta___ra_ret_register_address_h_record_0_read_0, ta___ra_val_register_address_h_record_0_read_0, ta_hdr.albion_timer.address_high_0, ta_register_address_h_record, ta_register_address_h_record__last0_old_value, ta_register_address_h_record__last0_value, ta_register_address_h_record__last_index, ta_register_address_h_record__last_old_value, ta_register_address_h_record__last_value, ta_register_address_h_record__last_write_site, ta_register_address_h_record__next_write_site, ta_register_address_h_record__wrote_any, ta_register_address_h_record__wrote_index0;
{
    ta___ra_val_register_address_h_record_0_read_0 := ta_register_address_h_record.read(ta_register_address_h_record, ta_hdr.albion.time);
    call ta___ra_val_register_address_h_record_0_read_0, ta___ra_ret_register_address_h_record_0_read_0 := ta_register_address_h_record_0_read_0.apply(ta___ra_val_register_address_h_record_0_read_0, ta___ra_ret_register_address_h_record_0_read_0);
    ta_register_address_h_record__next_write_site := 2;
    call ta_register_address_h_record.write(ta_hdr.albion.time, ta___ra_val_register_address_h_record_0_read_0);
    ta_hdr.albion_timer.address_high_0 := ta___ra_ret_register_address_h_record_0_read_0;
}

// ta_Action ta_action_register_address_h_record_0_write
procedure {:inline 1} ta_action_register_address_h_record_0_write()
	modifies ta___ra_ret_register_address_h_record_0_write_0, ta___ra_val_register_address_h_record_0_write_0, ta_register_address_h_record, ta_register_address_h_record__last0_old_value, ta_register_address_h_record__last0_value, ta_register_address_h_record__last_index, ta_register_address_h_record__last_old_value, ta_register_address_h_record__last_value, ta_register_address_h_record__last_write_site, ta_register_address_h_record__next_write_site, ta_register_address_h_record__wrote_any, ta_register_address_h_record__wrote_index0;
{
    ta___ra_val_register_address_h_record_0_write_0 := ta_register_address_h_record.read(ta_register_address_h_record, ta_hdr.albion.time);
    call ta___ra_val_register_address_h_record_0_write_0 := ta_register_address_h_record_0_write_0.apply(ta___ra_val_register_address_h_record_0_write_0);
    ta___ra_ret_register_address_h_record_0_write_0 := ta___ra_val_register_address_h_record_0_write_0;
    ta_register_address_h_record__next_write_site := 3;
    call ta_register_address_h_record.write(ta_hdr.albion.time, ta___ra_val_register_address_h_record_0_write_0);
}

// ta_Action ta_action_register_address_h_record_1_read
procedure {:inline 1} ta_action_register_address_h_record_1_read()
	modifies ta___ra_ret_register_address_h_record_1_read_0, ta___ra_val_register_address_h_record_1_read_0, ta_hdr.albion.address_h, ta_register_address_h_record_4, ta_register_address_h_record_4__last0_old_value, ta_register_address_h_record_4__last0_value, ta_register_address_h_record_4__last_index, ta_register_address_h_record_4__last_old_value, ta_register_address_h_record_4__last_value, ta_register_address_h_record_4__last_write_site, ta_register_address_h_record_4__next_write_site, ta_register_address_h_record_4__wrote_any, ta_register_address_h_record_4__wrote_index0;
{
    ta___ra_val_register_address_h_record_1_read_0 := ta_register_address_h_record_4.read(ta_register_address_h_record_4, ta_hdr.albion.time);
    call ta___ra_val_register_address_h_record_1_read_0, ta___ra_ret_register_address_h_record_1_read_0 := ta_register_address_h_record_1_read_0.apply(ta___ra_val_register_address_h_record_1_read_0, ta___ra_ret_register_address_h_record_1_read_0);
    ta_register_address_h_record_4__next_write_site := 1;
    call ta_register_address_h_record_4.write(ta_hdr.albion.time, ta___ra_val_register_address_h_record_1_read_0);
    ta_hdr.albion.address_h := ta___ra_ret_register_address_h_record_1_read_0;
}

// ta_Action ta_action_register_address_h_record_1_read_timer
procedure {:inline 1} ta_action_register_address_h_record_1_read_timer()
	modifies ta___ra_ret_register_address_h_record_1_read_0, ta___ra_val_register_address_h_record_1_read_0, ta_hdr.albion_timer.address_high_1, ta_register_address_h_record_4, ta_register_address_h_record_4__last0_old_value, ta_register_address_h_record_4__last0_value, ta_register_address_h_record_4__last_index, ta_register_address_h_record_4__last_old_value, ta_register_address_h_record_4__last_value, ta_register_address_h_record_4__last_write_site, ta_register_address_h_record_4__next_write_site, ta_register_address_h_record_4__wrote_any, ta_register_address_h_record_4__wrote_index0;
{
    ta___ra_val_register_address_h_record_1_read_0 := ta_register_address_h_record_4.read(ta_register_address_h_record_4, ta_hdr.albion.time);
    call ta___ra_val_register_address_h_record_1_read_0, ta___ra_ret_register_address_h_record_1_read_0 := ta_register_address_h_record_1_read_0.apply(ta___ra_val_register_address_h_record_1_read_0, ta___ra_ret_register_address_h_record_1_read_0);
    ta_register_address_h_record_4__next_write_site := 2;
    call ta_register_address_h_record_4.write(ta_hdr.albion.time, ta___ra_val_register_address_h_record_1_read_0);
    ta_hdr.albion_timer.address_high_1 := ta___ra_ret_register_address_h_record_1_read_0;
}

// ta_Action ta_action_register_address_h_record_1_write
procedure {:inline 1} ta_action_register_address_h_record_1_write()
	modifies ta___ra_ret_register_address_h_record_1_write_0, ta___ra_val_register_address_h_record_1_write_0, ta_register_address_h_record_4, ta_register_address_h_record_4__last0_old_value, ta_register_address_h_record_4__last0_value, ta_register_address_h_record_4__last_index, ta_register_address_h_record_4__last_old_value, ta_register_address_h_record_4__last_value, ta_register_address_h_record_4__last_write_site, ta_register_address_h_record_4__next_write_site, ta_register_address_h_record_4__wrote_any, ta_register_address_h_record_4__wrote_index0;
{
    ta___ra_val_register_address_h_record_1_write_0 := ta_register_address_h_record_4.read(ta_register_address_h_record_4, ta_hdr.albion.time);
    call ta___ra_val_register_address_h_record_1_write_0 := ta_register_address_h_record_1_write_0.apply(ta___ra_val_register_address_h_record_1_write_0);
    ta___ra_ret_register_address_h_record_1_write_0 := ta___ra_val_register_address_h_record_1_write_0;
    ta_register_address_h_record_4__next_write_site := 3;
    call ta_register_address_h_record_4.write(ta_hdr.albion.time, ta___ra_val_register_address_h_record_1_write_0);
}

// ta_Action ta_action_register_address_h_record_2_read
procedure {:inline 1} ta_action_register_address_h_record_2_read()
	modifies ta___ra_ret_register_address_h_record_2_read_0, ta___ra_val_register_address_h_record_2_read_0, ta_hdr.albion.address_h, ta_register_address_h_record_5, ta_register_address_h_record_5__last0_old_value, ta_register_address_h_record_5__last0_value, ta_register_address_h_record_5__last_index, ta_register_address_h_record_5__last_old_value, ta_register_address_h_record_5__last_value, ta_register_address_h_record_5__last_write_site, ta_register_address_h_record_5__next_write_site, ta_register_address_h_record_5__wrote_any, ta_register_address_h_record_5__wrote_index0;
{
    ta___ra_val_register_address_h_record_2_read_0 := ta_register_address_h_record_5.read(ta_register_address_h_record_5, ta_hdr.albion.time);
    call ta___ra_val_register_address_h_record_2_read_0, ta___ra_ret_register_address_h_record_2_read_0 := ta_register_address_h_record_2_read_0.apply(ta___ra_val_register_address_h_record_2_read_0, ta___ra_ret_register_address_h_record_2_read_0);
    ta_register_address_h_record_5__next_write_site := 1;
    call ta_register_address_h_record_5.write(ta_hdr.albion.time, ta___ra_val_register_address_h_record_2_read_0);
    ta_hdr.albion.address_h := ta___ra_ret_register_address_h_record_2_read_0;
}

// ta_Action ta_action_register_address_h_record_2_read_timer
procedure {:inline 1} ta_action_register_address_h_record_2_read_timer()
	modifies ta___ra_ret_register_address_h_record_2_read_0, ta___ra_val_register_address_h_record_2_read_0, ta_hdr.albion_timer.address_high_2, ta_register_address_h_record_5, ta_register_address_h_record_5__last0_old_value, ta_register_address_h_record_5__last0_value, ta_register_address_h_record_5__last_index, ta_register_address_h_record_5__last_old_value, ta_register_address_h_record_5__last_value, ta_register_address_h_record_5__last_write_site, ta_register_address_h_record_5__next_write_site, ta_register_address_h_record_5__wrote_any, ta_register_address_h_record_5__wrote_index0;
{
    ta___ra_val_register_address_h_record_2_read_0 := ta_register_address_h_record_5.read(ta_register_address_h_record_5, ta_hdr.albion.time);
    call ta___ra_val_register_address_h_record_2_read_0, ta___ra_ret_register_address_h_record_2_read_0 := ta_register_address_h_record_2_read_0.apply(ta___ra_val_register_address_h_record_2_read_0, ta___ra_ret_register_address_h_record_2_read_0);
    ta_register_address_h_record_5__next_write_site := 2;
    call ta_register_address_h_record_5.write(ta_hdr.albion.time, ta___ra_val_register_address_h_record_2_read_0);
    ta_hdr.albion_timer.address_high_2 := ta___ra_ret_register_address_h_record_2_read_0;
}

// ta_Action ta_action_register_address_h_record_2_write
procedure {:inline 1} ta_action_register_address_h_record_2_write()
	modifies ta___ra_ret_register_address_h_record_2_write_0, ta___ra_val_register_address_h_record_2_write_0, ta_register_address_h_record_5, ta_register_address_h_record_5__last0_old_value, ta_register_address_h_record_5__last0_value, ta_register_address_h_record_5__last_index, ta_register_address_h_record_5__last_old_value, ta_register_address_h_record_5__last_value, ta_register_address_h_record_5__last_write_site, ta_register_address_h_record_5__next_write_site, ta_register_address_h_record_5__wrote_any, ta_register_address_h_record_5__wrote_index0;
{
    ta___ra_val_register_address_h_record_2_write_0 := ta_register_address_h_record_5.read(ta_register_address_h_record_5, ta_hdr.albion.time);
    call ta___ra_val_register_address_h_record_2_write_0 := ta_register_address_h_record_2_write_0.apply(ta___ra_val_register_address_h_record_2_write_0);
    ta___ra_ret_register_address_h_record_2_write_0 := ta___ra_val_register_address_h_record_2_write_0;
    ta_register_address_h_record_5__next_write_site := 3;
    call ta_register_address_h_record_5.write(ta_hdr.albion.time, ta___ra_val_register_address_h_record_2_write_0);
}

// ta_Action ta_action_register_address_h_record_3_read
procedure {:inline 1} ta_action_register_address_h_record_3_read()
	modifies ta___ra_ret_register_address_h_record_3_read_0, ta___ra_val_register_address_h_record_3_read_0, ta_hdr.albion.address_h, ta_register_address_h_record_6, ta_register_address_h_record_6__last0_old_value, ta_register_address_h_record_6__last0_value, ta_register_address_h_record_6__last_index, ta_register_address_h_record_6__last_old_value, ta_register_address_h_record_6__last_value, ta_register_address_h_record_6__last_write_site, ta_register_address_h_record_6__next_write_site, ta_register_address_h_record_6__wrote_any, ta_register_address_h_record_6__wrote_index0;
{
    ta___ra_val_register_address_h_record_3_read_0 := ta_register_address_h_record_6.read(ta_register_address_h_record_6, ta_hdr.albion.time);
    call ta___ra_val_register_address_h_record_3_read_0, ta___ra_ret_register_address_h_record_3_read_0 := ta_register_address_h_record_3_read_0.apply(ta___ra_val_register_address_h_record_3_read_0, ta___ra_ret_register_address_h_record_3_read_0);
    ta_register_address_h_record_6__next_write_site := 1;
    call ta_register_address_h_record_6.write(ta_hdr.albion.time, ta___ra_val_register_address_h_record_3_read_0);
    ta_hdr.albion.address_h := ta___ra_ret_register_address_h_record_3_read_0;
}

// ta_Action ta_action_register_address_h_record_3_read_timer
procedure {:inline 1} ta_action_register_address_h_record_3_read_timer()
	modifies ta___ra_ret_register_address_h_record_3_read_0, ta___ra_val_register_address_h_record_3_read_0, ta_hdr.albion_timer.address_high_3, ta_register_address_h_record_6, ta_register_address_h_record_6__last0_old_value, ta_register_address_h_record_6__last0_value, ta_register_address_h_record_6__last_index, ta_register_address_h_record_6__last_old_value, ta_register_address_h_record_6__last_value, ta_register_address_h_record_6__last_write_site, ta_register_address_h_record_6__next_write_site, ta_register_address_h_record_6__wrote_any, ta_register_address_h_record_6__wrote_index0;
{
    ta___ra_val_register_address_h_record_3_read_0 := ta_register_address_h_record_6.read(ta_register_address_h_record_6, ta_hdr.albion.time);
    call ta___ra_val_register_address_h_record_3_read_0, ta___ra_ret_register_address_h_record_3_read_0 := ta_register_address_h_record_3_read_0.apply(ta___ra_val_register_address_h_record_3_read_0, ta___ra_ret_register_address_h_record_3_read_0);
    ta_register_address_h_record_6__next_write_site := 2;
    call ta_register_address_h_record_6.write(ta_hdr.albion.time, ta___ra_val_register_address_h_record_3_read_0);
    ta_hdr.albion_timer.address_high_3 := ta___ra_ret_register_address_h_record_3_read_0;
}

// ta_Action ta_action_register_address_h_record_3_write
procedure {:inline 1} ta_action_register_address_h_record_3_write()
	modifies ta___ra_ret_register_address_h_record_3_write_0, ta___ra_val_register_address_h_record_3_write_0, ta_register_address_h_record_6, ta_register_address_h_record_6__last0_old_value, ta_register_address_h_record_6__last0_value, ta_register_address_h_record_6__last_index, ta_register_address_h_record_6__last_old_value, ta_register_address_h_record_6__last_value, ta_register_address_h_record_6__last_write_site, ta_register_address_h_record_6__next_write_site, ta_register_address_h_record_6__wrote_any, ta_register_address_h_record_6__wrote_index0;
{
    ta___ra_val_register_address_h_record_3_write_0 := ta_register_address_h_record_6.read(ta_register_address_h_record_6, ta_hdr.albion.time);
    call ta___ra_val_register_address_h_record_3_write_0 := ta_register_address_h_record_3_write_0.apply(ta___ra_val_register_address_h_record_3_write_0);
    ta___ra_ret_register_address_h_record_3_write_0 := ta___ra_val_register_address_h_record_3_write_0;
    ta_register_address_h_record_6__next_write_site := 3;
    call ta_register_address_h_record_6.write(ta_hdr.albion.time, ta___ra_val_register_address_h_record_3_write_0);
}

// ta_Action ta_action_register_address_l_record_0_read
procedure {:inline 1} ta_action_register_address_l_record_0_read()
	modifies ta___ra_ret_register_address_l_record_0_read_0, ta___ra_val_register_address_l_record_0_read_0, ta_hdr.albion.address_l, ta_register_address_l_record, ta_register_address_l_record__last0_old_value, ta_register_address_l_record__last0_value, ta_register_address_l_record__last_index, ta_register_address_l_record__last_old_value, ta_register_address_l_record__last_value, ta_register_address_l_record__last_write_site, ta_register_address_l_record__next_write_site, ta_register_address_l_record__wrote_any, ta_register_address_l_record__wrote_index0;
{
    ta___ra_val_register_address_l_record_0_read_0 := ta_register_address_l_record.read(ta_register_address_l_record, ta_hdr.albion.time);
    call ta___ra_val_register_address_l_record_0_read_0, ta___ra_ret_register_address_l_record_0_read_0 := ta_register_address_l_record_0_read_0.apply(ta___ra_val_register_address_l_record_0_read_0, ta___ra_ret_register_address_l_record_0_read_0);
    ta_register_address_l_record__next_write_site := 1;
    call ta_register_address_l_record.write(ta_hdr.albion.time, ta___ra_val_register_address_l_record_0_read_0);
    ta_hdr.albion.address_l := ta___ra_ret_register_address_l_record_0_read_0;
}

// ta_Action ta_action_register_address_l_record_0_read_timer
procedure {:inline 1} ta_action_register_address_l_record_0_read_timer()
	modifies ta___ra_ret_register_address_l_record_0_read_0, ta___ra_val_register_address_l_record_0_read_0, ta_hdr.albion_timer.address_low_0, ta_register_address_l_record, ta_register_address_l_record__last0_old_value, ta_register_address_l_record__last0_value, ta_register_address_l_record__last_index, ta_register_address_l_record__last_old_value, ta_register_address_l_record__last_value, ta_register_address_l_record__last_write_site, ta_register_address_l_record__next_write_site, ta_register_address_l_record__wrote_any, ta_register_address_l_record__wrote_index0;
{
    ta___ra_val_register_address_l_record_0_read_0 := ta_register_address_l_record.read(ta_register_address_l_record, ta_hdr.albion.time);
    call ta___ra_val_register_address_l_record_0_read_0, ta___ra_ret_register_address_l_record_0_read_0 := ta_register_address_l_record_0_read_0.apply(ta___ra_val_register_address_l_record_0_read_0, ta___ra_ret_register_address_l_record_0_read_0);
    ta_register_address_l_record__next_write_site := 2;
    call ta_register_address_l_record.write(ta_hdr.albion.time, ta___ra_val_register_address_l_record_0_read_0);
    ta_hdr.albion_timer.address_low_0 := ta___ra_ret_register_address_l_record_0_read_0;
}

// ta_Action ta_action_register_address_l_record_0_write
procedure {:inline 1} ta_action_register_address_l_record_0_write()
	modifies ta___ra_ret_register_address_l_record_0_write_0, ta___ra_val_register_address_l_record_0_write_0, ta_register_address_l_record, ta_register_address_l_record__last0_old_value, ta_register_address_l_record__last0_value, ta_register_address_l_record__last_index, ta_register_address_l_record__last_old_value, ta_register_address_l_record__last_value, ta_register_address_l_record__last_write_site, ta_register_address_l_record__next_write_site, ta_register_address_l_record__wrote_any, ta_register_address_l_record__wrote_index0;
{
    ta___ra_val_register_address_l_record_0_write_0 := ta_register_address_l_record.read(ta_register_address_l_record, ta_hdr.albion.time);
    call ta___ra_val_register_address_l_record_0_write_0 := ta_register_address_l_record_0_write_0.apply(ta___ra_val_register_address_l_record_0_write_0);
    ta___ra_ret_register_address_l_record_0_write_0 := ta___ra_val_register_address_l_record_0_write_0;
    ta_register_address_l_record__next_write_site := 3;
    call ta_register_address_l_record.write(ta_hdr.albion.time, ta___ra_val_register_address_l_record_0_write_0);
}

// ta_Action ta_action_register_address_l_record_1_read
procedure {:inline 1} ta_action_register_address_l_record_1_read()
	modifies ta___ra_ret_register_address_l_record_1_read_0, ta___ra_val_register_address_l_record_1_read_0, ta_hdr.albion.address_l, ta_register_address_l_record_4, ta_register_address_l_record_4__last0_old_value, ta_register_address_l_record_4__last0_value, ta_register_address_l_record_4__last_index, ta_register_address_l_record_4__last_old_value, ta_register_address_l_record_4__last_value, ta_register_address_l_record_4__last_write_site, ta_register_address_l_record_4__next_write_site, ta_register_address_l_record_4__wrote_any, ta_register_address_l_record_4__wrote_index0;
{
    ta___ra_val_register_address_l_record_1_read_0 := ta_register_address_l_record_4.read(ta_register_address_l_record_4, ta_hdr.albion.time);
    call ta___ra_val_register_address_l_record_1_read_0, ta___ra_ret_register_address_l_record_1_read_0 := ta_register_address_l_record_1_read_0.apply(ta___ra_val_register_address_l_record_1_read_0, ta___ra_ret_register_address_l_record_1_read_0);
    ta_register_address_l_record_4__next_write_site := 1;
    call ta_register_address_l_record_4.write(ta_hdr.albion.time, ta___ra_val_register_address_l_record_1_read_0);
    ta_hdr.albion.address_l := ta___ra_ret_register_address_l_record_1_read_0;
}

// ta_Action ta_action_register_address_l_record_1_read_timer
procedure {:inline 1} ta_action_register_address_l_record_1_read_timer()
	modifies ta___ra_ret_register_address_l_record_1_read_0, ta___ra_val_register_address_l_record_1_read_0, ta_hdr.albion_timer.address_low_1, ta_register_address_l_record_4, ta_register_address_l_record_4__last0_old_value, ta_register_address_l_record_4__last0_value, ta_register_address_l_record_4__last_index, ta_register_address_l_record_4__last_old_value, ta_register_address_l_record_4__last_value, ta_register_address_l_record_4__last_write_site, ta_register_address_l_record_4__next_write_site, ta_register_address_l_record_4__wrote_any, ta_register_address_l_record_4__wrote_index0;
{
    ta___ra_val_register_address_l_record_1_read_0 := ta_register_address_l_record_4.read(ta_register_address_l_record_4, ta_hdr.albion.time);
    call ta___ra_val_register_address_l_record_1_read_0, ta___ra_ret_register_address_l_record_1_read_0 := ta_register_address_l_record_1_read_0.apply(ta___ra_val_register_address_l_record_1_read_0, ta___ra_ret_register_address_l_record_1_read_0);
    ta_register_address_l_record_4__next_write_site := 2;
    call ta_register_address_l_record_4.write(ta_hdr.albion.time, ta___ra_val_register_address_l_record_1_read_0);
    ta_hdr.albion_timer.address_low_1 := ta___ra_ret_register_address_l_record_1_read_0;
}

// ta_Action ta_action_register_address_l_record_1_write
procedure {:inline 1} ta_action_register_address_l_record_1_write()
	modifies ta___ra_ret_register_address_l_record_1_write_0, ta___ra_val_register_address_l_record_1_write_0, ta_register_address_l_record_4, ta_register_address_l_record_4__last0_old_value, ta_register_address_l_record_4__last0_value, ta_register_address_l_record_4__last_index, ta_register_address_l_record_4__last_old_value, ta_register_address_l_record_4__last_value, ta_register_address_l_record_4__last_write_site, ta_register_address_l_record_4__next_write_site, ta_register_address_l_record_4__wrote_any, ta_register_address_l_record_4__wrote_index0;
{
    ta___ra_val_register_address_l_record_1_write_0 := ta_register_address_l_record_4.read(ta_register_address_l_record_4, ta_hdr.albion.time);
    call ta___ra_val_register_address_l_record_1_write_0 := ta_register_address_l_record_1_write_0.apply(ta___ra_val_register_address_l_record_1_write_0);
    ta___ra_ret_register_address_l_record_1_write_0 := ta___ra_val_register_address_l_record_1_write_0;
    ta_register_address_l_record_4__next_write_site := 3;
    call ta_register_address_l_record_4.write(ta_hdr.albion.time, ta___ra_val_register_address_l_record_1_write_0);
}

// ta_Action ta_action_register_address_l_record_2_read
procedure {:inline 1} ta_action_register_address_l_record_2_read()
	modifies ta___ra_ret_register_address_l_record_2_read_0, ta___ra_val_register_address_l_record_2_read_0, ta_hdr.albion.address_l, ta_register_address_l_record_5, ta_register_address_l_record_5__last0_old_value, ta_register_address_l_record_5__last0_value, ta_register_address_l_record_5__last_index, ta_register_address_l_record_5__last_old_value, ta_register_address_l_record_5__last_value, ta_register_address_l_record_5__last_write_site, ta_register_address_l_record_5__next_write_site, ta_register_address_l_record_5__wrote_any, ta_register_address_l_record_5__wrote_index0;
{
    ta___ra_val_register_address_l_record_2_read_0 := ta_register_address_l_record_5.read(ta_register_address_l_record_5, ta_hdr.albion.time);
    call ta___ra_val_register_address_l_record_2_read_0, ta___ra_ret_register_address_l_record_2_read_0 := ta_register_address_l_record_2_read_0.apply(ta___ra_val_register_address_l_record_2_read_0, ta___ra_ret_register_address_l_record_2_read_0);
    ta_register_address_l_record_5__next_write_site := 1;
    call ta_register_address_l_record_5.write(ta_hdr.albion.time, ta___ra_val_register_address_l_record_2_read_0);
    ta_hdr.albion.address_l := ta___ra_ret_register_address_l_record_2_read_0;
}

// ta_Action ta_action_register_address_l_record_2_read_timer
procedure {:inline 1} ta_action_register_address_l_record_2_read_timer()
	modifies ta___ra_ret_register_address_l_record_2_read_0, ta___ra_val_register_address_l_record_2_read_0, ta_hdr.albion_timer.address_low_2, ta_register_address_l_record_5, ta_register_address_l_record_5__last0_old_value, ta_register_address_l_record_5__last0_value, ta_register_address_l_record_5__last_index, ta_register_address_l_record_5__last_old_value, ta_register_address_l_record_5__last_value, ta_register_address_l_record_5__last_write_site, ta_register_address_l_record_5__next_write_site, ta_register_address_l_record_5__wrote_any, ta_register_address_l_record_5__wrote_index0;
{
    ta___ra_val_register_address_l_record_2_read_0 := ta_register_address_l_record_5.read(ta_register_address_l_record_5, ta_hdr.albion.time);
    call ta___ra_val_register_address_l_record_2_read_0, ta___ra_ret_register_address_l_record_2_read_0 := ta_register_address_l_record_2_read_0.apply(ta___ra_val_register_address_l_record_2_read_0, ta___ra_ret_register_address_l_record_2_read_0);
    ta_register_address_l_record_5__next_write_site := 2;
    call ta_register_address_l_record_5.write(ta_hdr.albion.time, ta___ra_val_register_address_l_record_2_read_0);
    ta_hdr.albion_timer.address_low_2 := ta___ra_ret_register_address_l_record_2_read_0;
}

// ta_Action ta_action_register_address_l_record_2_write
procedure {:inline 1} ta_action_register_address_l_record_2_write()
	modifies ta___ra_ret_register_address_l_record_2_write_0, ta___ra_val_register_address_l_record_2_write_0, ta_register_address_l_record_5, ta_register_address_l_record_5__last0_old_value, ta_register_address_l_record_5__last0_value, ta_register_address_l_record_5__last_index, ta_register_address_l_record_5__last_old_value, ta_register_address_l_record_5__last_value, ta_register_address_l_record_5__last_write_site, ta_register_address_l_record_5__next_write_site, ta_register_address_l_record_5__wrote_any, ta_register_address_l_record_5__wrote_index0;
{
    ta___ra_val_register_address_l_record_2_write_0 := ta_register_address_l_record_5.read(ta_register_address_l_record_5, ta_hdr.albion.time);
    call ta___ra_val_register_address_l_record_2_write_0 := ta_register_address_l_record_2_write_0.apply(ta___ra_val_register_address_l_record_2_write_0);
    ta___ra_ret_register_address_l_record_2_write_0 := ta___ra_val_register_address_l_record_2_write_0;
    ta_register_address_l_record_5__next_write_site := 3;
    call ta_register_address_l_record_5.write(ta_hdr.albion.time, ta___ra_val_register_address_l_record_2_write_0);
}

// ta_Action ta_action_register_address_l_record_3_read
procedure {:inline 1} ta_action_register_address_l_record_3_read()
	modifies ta___ra_ret_register_address_l_record_3_read_0, ta___ra_val_register_address_l_record_3_read_0, ta_hdr.albion.address_l, ta_register_address_l_record_6, ta_register_address_l_record_6__last0_old_value, ta_register_address_l_record_6__last0_value, ta_register_address_l_record_6__last_index, ta_register_address_l_record_6__last_old_value, ta_register_address_l_record_6__last_value, ta_register_address_l_record_6__last_write_site, ta_register_address_l_record_6__next_write_site, ta_register_address_l_record_6__wrote_any, ta_register_address_l_record_6__wrote_index0;
{
    ta___ra_val_register_address_l_record_3_read_0 := ta_register_address_l_record_6.read(ta_register_address_l_record_6, ta_hdr.albion.time);
    call ta___ra_val_register_address_l_record_3_read_0, ta___ra_ret_register_address_l_record_3_read_0 := ta_register_address_l_record_3_read_0.apply(ta___ra_val_register_address_l_record_3_read_0, ta___ra_ret_register_address_l_record_3_read_0);
    ta_register_address_l_record_6__next_write_site := 1;
    call ta_register_address_l_record_6.write(ta_hdr.albion.time, ta___ra_val_register_address_l_record_3_read_0);
    ta_hdr.albion.address_l := ta___ra_ret_register_address_l_record_3_read_0;
}

// ta_Action ta_action_register_address_l_record_3_read_timer
procedure {:inline 1} ta_action_register_address_l_record_3_read_timer()
	modifies ta___ra_ret_register_address_l_record_3_read_0, ta___ra_val_register_address_l_record_3_read_0, ta_hdr.albion_timer.address_low_3, ta_register_address_l_record_6, ta_register_address_l_record_6__last0_old_value, ta_register_address_l_record_6__last0_value, ta_register_address_l_record_6__last_index, ta_register_address_l_record_6__last_old_value, ta_register_address_l_record_6__last_value, ta_register_address_l_record_6__last_write_site, ta_register_address_l_record_6__next_write_site, ta_register_address_l_record_6__wrote_any, ta_register_address_l_record_6__wrote_index0;
{
    ta___ra_val_register_address_l_record_3_read_0 := ta_register_address_l_record_6.read(ta_register_address_l_record_6, ta_hdr.albion.time);
    call ta___ra_val_register_address_l_record_3_read_0, ta___ra_ret_register_address_l_record_3_read_0 := ta_register_address_l_record_3_read_0.apply(ta___ra_val_register_address_l_record_3_read_0, ta___ra_ret_register_address_l_record_3_read_0);
    ta_register_address_l_record_6__next_write_site := 2;
    call ta_register_address_l_record_6.write(ta_hdr.albion.time, ta___ra_val_register_address_l_record_3_read_0);
    ta_hdr.albion_timer.address_low_3 := ta___ra_ret_register_address_l_record_3_read_0;
}

// ta_Action ta_action_register_address_l_record_3_write
procedure {:inline 1} ta_action_register_address_l_record_3_write()
	modifies ta___ra_ret_register_address_l_record_3_write_0, ta___ra_val_register_address_l_record_3_write_0, ta_register_address_l_record_6, ta_register_address_l_record_6__last0_old_value, ta_register_address_l_record_6__last0_value, ta_register_address_l_record_6__last_index, ta_register_address_l_record_6__last_old_value, ta_register_address_l_record_6__last_value, ta_register_address_l_record_6__last_write_site, ta_register_address_l_record_6__next_write_site, ta_register_address_l_record_6__wrote_any, ta_register_address_l_record_6__wrote_index0;
{
    ta___ra_val_register_address_l_record_3_write_0 := ta_register_address_l_record_6.read(ta_register_address_l_record_6, ta_hdr.albion.time);
    call ta___ra_val_register_address_l_record_3_write_0 := ta_register_address_l_record_3_write_0.apply(ta___ra_val_register_address_l_record_3_write_0);
    ta___ra_ret_register_address_l_record_3_write_0 := ta___ra_val_register_address_l_record_3_write_0;
    ta_register_address_l_record_6__next_write_site := 3;
    call ta_register_address_l_record_6.write(ta_hdr.albion.time, ta___ra_val_register_address_l_record_3_write_0);
}

// ta_Action ta_action_register_num_add
procedure {:inline 1} ta_action_register_num_add()
	modifies ta___ra_ret_register_num_add_0, ta___ra_val_register_num_add_0, ta_hdr.albion.num, ta_register_num_0, ta_register_num_0__last0_old_value, ta_register_num_0__last0_value, ta_register_num_0__last_index, ta_register_num_0__last_old_value, ta_register_num_0__last_value, ta_register_num_0__last_write_site, ta_register_num_0__next_write_site, ta_register_num_0__wrote_any, ta_register_num_0__wrote_index0;
{
    ta___ra_val_register_num_add_0 := ta_register_num_0.read(ta_register_num_0, 0bv32);
    call ta___ra_val_register_num_add_0, ta___ra_ret_register_num_add_0 := ta_register_num_add_0.apply(ta___ra_val_register_num_add_0, ta___ra_ret_register_num_add_0);
    ta_register_num_0__next_write_site := 1;
    call ta_register_num_0.write(0bv32, ta___ra_val_register_num_add_0);
    ta_hdr.albion.num := ta___ra_ret_register_num_add_0;
}

// ta_Action ta_action_register_num_zero
procedure {:inline 1} ta_action_register_num_zero()
	modifies ta___ra_ret_register_num_zero_0, ta___ra_val_register_num_zero_0, ta_register_num_0, ta_register_num_0__last0_old_value, ta_register_num_0__last0_value, ta_register_num_0__last_index, ta_register_num_0__last_old_value, ta_register_num_0__last_value, ta_register_num_0__last_write_site, ta_register_num_0__next_write_site, ta_register_num_0__wrote_any, ta_register_num_0__wrote_index0;
{
    ta___ra_val_register_num_zero_0 := ta_register_num_0.read(ta_register_num_0, 0bv32);
    call ta___ra_val_register_num_zero_0, ta___ra_ret_register_num_zero_0 := ta_register_num_zero_0.apply(ta___ra_val_register_num_zero_0, ta___ra_ret_register_num_zero_0);
    ta_register_num_0__next_write_site := 2;
    call ta_register_num_0.write(0bv32, ta___ra_val_register_num_zero_0);
}

// ta_Action ta_action_register_request_id_high_add
procedure {:inline 1} ta_action_register_request_id_high_add()
	modifies ta___ra_ret_register_request_id_high_add_0, ta___ra_val_register_request_id_high_add_0, ta_hdr.albion.request_id_high, ta_register_request_id_high_0, ta_register_request_id_high_0__last0_old_value, ta_register_request_id_high_0__last0_value, ta_register_request_id_high_0__last_index, ta_register_request_id_high_0__last_old_value, ta_register_request_id_high_0__last_value, ta_register_request_id_high_0__last_write_site, ta_register_request_id_high_0__next_write_site, ta_register_request_id_high_0__wrote_any, ta_register_request_id_high_0__wrote_index0;
{
    ta___ra_val_register_request_id_high_add_0 := ta_register_request_id_high_0.read(ta_register_request_id_high_0, 0bv32);
    call ta___ra_val_register_request_id_high_add_0, ta___ra_ret_register_request_id_high_add_0 := ta_register_request_id_high_add_0.apply(ta___ra_val_register_request_id_high_add_0, ta___ra_ret_register_request_id_high_add_0);
    ta_register_request_id_high_0__next_write_site := 1;
    call ta_register_request_id_high_0.write(0bv32, ta___ra_val_register_request_id_high_add_0);
    ta_hdr.albion.request_id_high := ta___ra_ret_register_request_id_high_add_0;
}

// ta_Action ta_action_register_state_0_r
procedure {:inline 1} ta_action_register_state_0_r()
	modifies ta___ra_ret_register_state_0_r_0, ta___ra_val_register_state_0_r_0, ta_meta.state, ta_register_state, ta_register_state__last0_old_value, ta_register_state__last0_value, ta_register_state__last_index, ta_register_state__last_old_value, ta_register_state__last_value, ta_register_state__last_write_site, ta_register_state__next_write_site, ta_register_state__wrote_any, ta_register_state__wrote_index0;
{
    ta___ra_val_register_state_0_r_0 := ta_register_state.read(ta_register_state, ta_hdr.albion.time);
    call ta___ra_val_register_state_0_r_0, ta___ra_ret_register_state_0_r_0 := ta_register_state_0_r_0.apply(ta___ra_val_register_state_0_r_0, ta___ra_ret_register_state_0_r_0);
    ta_register_state__next_write_site := 2;
    call ta_register_state.write(ta_hdr.albion.time, ta___ra_val_register_state_0_r_0);
    ta_meta.state := ta___ra_ret_register_state_0_r_0;
}

// ta_Action ta_action_register_state_0_r_timer
procedure {:inline 1} ta_action_register_state_0_r_timer()
	modifies ta___ra_ret_register_state_0_r_0, ta___ra_val_register_state_0_r_0, ta_hdr.albion_timer.state_0, ta_register_state, ta_register_state__last0_old_value, ta_register_state__last0_value, ta_register_state__last_index, ta_register_state__last_old_value, ta_register_state__last_value, ta_register_state__last_write_site, ta_register_state__next_write_site, ta_register_state__wrote_any, ta_register_state__wrote_index0;
{
    ta___ra_val_register_state_0_r_0 := ta_register_state.read(ta_register_state, ta_hdr.albion.time);
    call ta___ra_val_register_state_0_r_0, ta___ra_ret_register_state_0_r_0 := ta_register_state_0_r_0.apply(ta___ra_val_register_state_0_r_0, ta___ra_ret_register_state_0_r_0);
    ta_register_state__next_write_site := 3;
    call ta_register_state.write(ta_hdr.albion.time, ta___ra_val_register_state_0_r_0);
    ta_hdr.albion_timer.state_0 := ta___ra_ret_register_state_0_r_0;
}

// ta_Action ta_action_register_state_0_sub
procedure {:inline 1} ta_action_register_state_0_sub()
	modifies ta___ra_ret_register_state_0_sub_0, ta___ra_val_register_state_0_sub_0, ta_meta.state, ta_register_state, ta_register_state__last0_old_value, ta_register_state__last0_value, ta_register_state__last_index, ta_register_state__last_old_value, ta_register_state__last_value, ta_register_state__last_write_site, ta_register_state__next_write_site, ta_register_state__wrote_any, ta_register_state__wrote_index0;
{
    ta___ra_val_register_state_0_sub_0 := ta_register_state.read(ta_register_state, ta_hdr.albion.time);
    call ta___ra_val_register_state_0_sub_0, ta___ra_ret_register_state_0_sub_0 := ta_register_state_0_sub_0.apply(ta___ra_val_register_state_0_sub_0, ta___ra_ret_register_state_0_sub_0);
    ta_register_state__next_write_site := 4;
    call ta_register_state.write(ta_hdr.albion.time, ta___ra_val_register_state_0_sub_0);
    ta_meta.state := ta___ra_ret_register_state_0_sub_0;
}

// ta_Action ta_action_register_state_0_w
procedure {:inline 1} ta_action_register_state_0_w()
	modifies ta___ra_ret_register_state_0_w_0, ta___ra_val_register_state_0_w_0, ta_register_state, ta_register_state__last0_old_value, ta_register_state__last0_value, ta_register_state__last_index, ta_register_state__last_old_value, ta_register_state__last_value, ta_register_state__last_write_site, ta_register_state__next_write_site, ta_register_state__wrote_any, ta_register_state__wrote_index0;
{
    ta___ra_val_register_state_0_w_0 := ta_register_state.read(ta_register_state, ta_hdr.albion.time);
    call ta___ra_val_register_state_0_w_0 := ta_register_state_0_w_0.apply(ta___ra_val_register_state_0_w_0);
    ta___ra_ret_register_state_0_w_0 := ta___ra_val_register_state_0_w_0;
    ta_register_state__next_write_site := 1;
    call ta_register_state.write(ta_hdr.albion.time, ta___ra_val_register_state_0_w_0);
}

// ta_Action ta_action_register_state_1_r
procedure {:inline 1} ta_action_register_state_1_r()
	modifies ta___ra_ret_register_state_1_r_0, ta___ra_val_register_state_1_r_0, ta_meta.state, ta_register_state_4, ta_register_state_4__last0_old_value, ta_register_state_4__last0_value, ta_register_state_4__last_index, ta_register_state_4__last_old_value, ta_register_state_4__last_value, ta_register_state_4__last_write_site, ta_register_state_4__next_write_site, ta_register_state_4__wrote_any, ta_register_state_4__wrote_index0;
{
    ta___ra_val_register_state_1_r_0 := ta_register_state_4.read(ta_register_state_4, ta_hdr.albion.time);
    call ta___ra_val_register_state_1_r_0, ta___ra_ret_register_state_1_r_0 := ta_register_state_1_r_0.apply(ta___ra_val_register_state_1_r_0, ta___ra_ret_register_state_1_r_0);
    ta_register_state_4__next_write_site := 2;
    call ta_register_state_4.write(ta_hdr.albion.time, ta___ra_val_register_state_1_r_0);
    ta_meta.state := ta___ra_ret_register_state_1_r_0;
}

// ta_Action ta_action_register_state_1_r_timer
procedure {:inline 1} ta_action_register_state_1_r_timer()
	modifies ta___ra_ret_register_state_1_r_0, ta___ra_val_register_state_1_r_0, ta_hdr.albion_timer.state_1, ta_register_state_4, ta_register_state_4__last0_old_value, ta_register_state_4__last0_value, ta_register_state_4__last_index, ta_register_state_4__last_old_value, ta_register_state_4__last_value, ta_register_state_4__last_write_site, ta_register_state_4__next_write_site, ta_register_state_4__wrote_any, ta_register_state_4__wrote_index0;
{
    ta___ra_val_register_state_1_r_0 := ta_register_state_4.read(ta_register_state_4, ta_hdr.albion.time);
    call ta___ra_val_register_state_1_r_0, ta___ra_ret_register_state_1_r_0 := ta_register_state_1_r_0.apply(ta___ra_val_register_state_1_r_0, ta___ra_ret_register_state_1_r_0);
    ta_register_state_4__next_write_site := 3;
    call ta_register_state_4.write(ta_hdr.albion.time, ta___ra_val_register_state_1_r_0);
    ta_hdr.albion_timer.state_1 := ta___ra_ret_register_state_1_r_0;
}

// ta_Action ta_action_register_state_1_sub
procedure {:inline 1} ta_action_register_state_1_sub()
	modifies ta___ra_ret_register_state_1_sub_0, ta___ra_val_register_state_1_sub_0, ta_meta.state, ta_register_state_4, ta_register_state_4__last0_old_value, ta_register_state_4__last0_value, ta_register_state_4__last_index, ta_register_state_4__last_old_value, ta_register_state_4__last_value, ta_register_state_4__last_write_site, ta_register_state_4__next_write_site, ta_register_state_4__wrote_any, ta_register_state_4__wrote_index0;
{
    ta___ra_val_register_state_1_sub_0 := ta_register_state_4.read(ta_register_state_4, ta_hdr.albion.time);
    call ta___ra_val_register_state_1_sub_0, ta___ra_ret_register_state_1_sub_0 := ta_register_state_1_sub_0.apply(ta___ra_val_register_state_1_sub_0, ta___ra_ret_register_state_1_sub_0);
    ta_register_state_4__next_write_site := 4;
    call ta_register_state_4.write(ta_hdr.albion.time, ta___ra_val_register_state_1_sub_0);
    ta_meta.state := ta___ra_ret_register_state_1_sub_0;
}

// ta_Action ta_action_register_state_1_w
procedure {:inline 1} ta_action_register_state_1_w()
	modifies ta___ra_ret_register_state_1_w_0, ta___ra_val_register_state_1_w_0, ta_register_state_4, ta_register_state_4__last0_old_value, ta_register_state_4__last0_value, ta_register_state_4__last_index, ta_register_state_4__last_old_value, ta_register_state_4__last_value, ta_register_state_4__last_write_site, ta_register_state_4__next_write_site, ta_register_state_4__wrote_any, ta_register_state_4__wrote_index0;
{
    ta___ra_val_register_state_1_w_0 := ta_register_state_4.read(ta_register_state_4, ta_hdr.albion.time);
    call ta___ra_val_register_state_1_w_0 := ta_register_state_1_w_0.apply(ta___ra_val_register_state_1_w_0);
    ta___ra_ret_register_state_1_w_0 := ta___ra_val_register_state_1_w_0;
    ta_register_state_4__next_write_site := 1;
    call ta_register_state_4.write(ta_hdr.albion.time, ta___ra_val_register_state_1_w_0);
}

// ta_Action ta_action_register_state_2_r
procedure {:inline 1} ta_action_register_state_2_r()
	modifies ta___ra_ret_register_state_2_r_0, ta___ra_val_register_state_2_r_0, ta_meta.state, ta_register_state_5, ta_register_state_5__last0_old_value, ta_register_state_5__last0_value, ta_register_state_5__last_index, ta_register_state_5__last_old_value, ta_register_state_5__last_value, ta_register_state_5__last_write_site, ta_register_state_5__next_write_site, ta_register_state_5__wrote_any, ta_register_state_5__wrote_index0;
{
    ta___ra_val_register_state_2_r_0 := ta_register_state_5.read(ta_register_state_5, ta_hdr.albion.time);
    call ta___ra_val_register_state_2_r_0, ta___ra_ret_register_state_2_r_0 := ta_register_state_2_r_0.apply(ta___ra_val_register_state_2_r_0, ta___ra_ret_register_state_2_r_0);
    ta_register_state_5__next_write_site := 2;
    call ta_register_state_5.write(ta_hdr.albion.time, ta___ra_val_register_state_2_r_0);
    ta_meta.state := ta___ra_ret_register_state_2_r_0;
}

// ta_Action ta_action_register_state_2_r_timer
procedure {:inline 1} ta_action_register_state_2_r_timer()
	modifies ta___ra_ret_register_state_2_r_0, ta___ra_val_register_state_2_r_0, ta_hdr.albion_timer.state_2, ta_register_state_5, ta_register_state_5__last0_old_value, ta_register_state_5__last0_value, ta_register_state_5__last_index, ta_register_state_5__last_old_value, ta_register_state_5__last_value, ta_register_state_5__last_write_site, ta_register_state_5__next_write_site, ta_register_state_5__wrote_any, ta_register_state_5__wrote_index0;
{
    ta___ra_val_register_state_2_r_0 := ta_register_state_5.read(ta_register_state_5, ta_hdr.albion.time);
    call ta___ra_val_register_state_2_r_0, ta___ra_ret_register_state_2_r_0 := ta_register_state_2_r_0.apply(ta___ra_val_register_state_2_r_0, ta___ra_ret_register_state_2_r_0);
    ta_register_state_5__next_write_site := 3;
    call ta_register_state_5.write(ta_hdr.albion.time, ta___ra_val_register_state_2_r_0);
    ta_hdr.albion_timer.state_2 := ta___ra_ret_register_state_2_r_0;
}

// ta_Action ta_action_register_state_2_sub
procedure {:inline 1} ta_action_register_state_2_sub()
	modifies ta___ra_ret_register_state_2_sub_0, ta___ra_val_register_state_2_sub_0, ta_meta.state, ta_register_state_5, ta_register_state_5__last0_old_value, ta_register_state_5__last0_value, ta_register_state_5__last_index, ta_register_state_5__last_old_value, ta_register_state_5__last_value, ta_register_state_5__last_write_site, ta_register_state_5__next_write_site, ta_register_state_5__wrote_any, ta_register_state_5__wrote_index0;
{
    ta___ra_val_register_state_2_sub_0 := ta_register_state_5.read(ta_register_state_5, ta_hdr.albion.time);
    call ta___ra_val_register_state_2_sub_0, ta___ra_ret_register_state_2_sub_0 := ta_register_state_2_sub_0.apply(ta___ra_val_register_state_2_sub_0, ta___ra_ret_register_state_2_sub_0);
    ta_register_state_5__next_write_site := 4;
    call ta_register_state_5.write(ta_hdr.albion.time, ta___ra_val_register_state_2_sub_0);
    ta_meta.state := ta___ra_ret_register_state_2_sub_0;
}

// ta_Action ta_action_register_state_2_w
procedure {:inline 1} ta_action_register_state_2_w()
	modifies ta___ra_ret_register_state_2_w_0, ta___ra_val_register_state_2_w_0, ta_register_state_5, ta_register_state_5__last0_old_value, ta_register_state_5__last0_value, ta_register_state_5__last_index, ta_register_state_5__last_old_value, ta_register_state_5__last_value, ta_register_state_5__last_write_site, ta_register_state_5__next_write_site, ta_register_state_5__wrote_any, ta_register_state_5__wrote_index0;
{
    ta___ra_val_register_state_2_w_0 := ta_register_state_5.read(ta_register_state_5, ta_hdr.albion.time);
    call ta___ra_val_register_state_2_w_0 := ta_register_state_2_w_0.apply(ta___ra_val_register_state_2_w_0);
    ta___ra_ret_register_state_2_w_0 := ta___ra_val_register_state_2_w_0;
    ta_register_state_5__next_write_site := 1;
    call ta_register_state_5.write(ta_hdr.albion.time, ta___ra_val_register_state_2_w_0);
}

// ta_Action ta_action_register_state_3_r
procedure {:inline 1} ta_action_register_state_3_r()
	modifies ta___ra_ret_register_state_3_r_0, ta___ra_val_register_state_3_r_0, ta_meta.state, ta_register_state_6, ta_register_state_6__last0_old_value, ta_register_state_6__last0_value, ta_register_state_6__last_index, ta_register_state_6__last_old_value, ta_register_state_6__last_value, ta_register_state_6__last_write_site, ta_register_state_6__next_write_site, ta_register_state_6__wrote_any, ta_register_state_6__wrote_index0;
{
    ta___ra_val_register_state_3_r_0 := ta_register_state_6.read(ta_register_state_6, ta_hdr.albion.time);
    call ta___ra_val_register_state_3_r_0, ta___ra_ret_register_state_3_r_0 := ta_register_state_3_r_0.apply(ta___ra_val_register_state_3_r_0, ta___ra_ret_register_state_3_r_0);
    ta_register_state_6__next_write_site := 2;
    call ta_register_state_6.write(ta_hdr.albion.time, ta___ra_val_register_state_3_r_0);
    ta_meta.state := ta___ra_ret_register_state_3_r_0;
}

// ta_Action ta_action_register_state_3_r_timer
procedure {:inline 1} ta_action_register_state_3_r_timer()
	modifies ta___ra_ret_register_state_3_r_0, ta___ra_val_register_state_3_r_0, ta_hdr.albion_timer.state_3, ta_register_state_6, ta_register_state_6__last0_old_value, ta_register_state_6__last0_value, ta_register_state_6__last_index, ta_register_state_6__last_old_value, ta_register_state_6__last_value, ta_register_state_6__last_write_site, ta_register_state_6__next_write_site, ta_register_state_6__wrote_any, ta_register_state_6__wrote_index0;
{
    ta___ra_val_register_state_3_r_0 := ta_register_state_6.read(ta_register_state_6, ta_hdr.albion.time);
    call ta___ra_val_register_state_3_r_0, ta___ra_ret_register_state_3_r_0 := ta_register_state_3_r_0.apply(ta___ra_val_register_state_3_r_0, ta___ra_ret_register_state_3_r_0);
    ta_register_state_6__next_write_site := 3;
    call ta_register_state_6.write(ta_hdr.albion.time, ta___ra_val_register_state_3_r_0);
    ta_hdr.albion_timer.state_3 := ta___ra_ret_register_state_3_r_0;
}

// ta_Action ta_action_register_state_3_sub
procedure {:inline 1} ta_action_register_state_3_sub()
	modifies ta___ra_ret_register_state_3_sub_0, ta___ra_val_register_state_3_sub_0, ta_meta.state, ta_register_state_6, ta_register_state_6__last0_old_value, ta_register_state_6__last0_value, ta_register_state_6__last_index, ta_register_state_6__last_old_value, ta_register_state_6__last_value, ta_register_state_6__last_write_site, ta_register_state_6__next_write_site, ta_register_state_6__wrote_any, ta_register_state_6__wrote_index0;
{
    ta___ra_val_register_state_3_sub_0 := ta_register_state_6.read(ta_register_state_6, ta_hdr.albion.time);
    call ta___ra_val_register_state_3_sub_0, ta___ra_ret_register_state_3_sub_0 := ta_register_state_3_sub_0.apply(ta___ra_val_register_state_3_sub_0, ta___ra_ret_register_state_3_sub_0);
    ta_register_state_6__next_write_site := 4;
    call ta_register_state_6.write(ta_hdr.albion.time, ta___ra_val_register_state_3_sub_0);
    ta_meta.state := ta___ra_ret_register_state_3_sub_0;
}

// ta_Action ta_action_register_state_3_w
procedure {:inline 1} ta_action_register_state_3_w()
	modifies ta___ra_ret_register_state_3_w_0, ta___ra_val_register_state_3_w_0, ta_register_state_6, ta_register_state_6__last0_old_value, ta_register_state_6__last0_value, ta_register_state_6__last_index, ta_register_state_6__last_old_value, ta_register_state_6__last_value, ta_register_state_6__last_write_site, ta_register_state_6__next_write_site, ta_register_state_6__wrote_any, ta_register_state_6__wrote_index0;
{
    ta___ra_val_register_state_3_w_0 := ta_register_state_6.read(ta_register_state_6, ta_hdr.albion.time);
    call ta___ra_val_register_state_3_w_0 := ta_register_state_3_w_0.apply(ta___ra_val_register_state_3_w_0);
    ta___ra_ret_register_state_3_w_0 := ta___ra_val_register_state_3_w_0;
    ta_register_state_6__next_write_site := 1;
    call ta_register_state_6.write(ta_hdr.albion.time, ta___ra_val_register_state_3_w_0);
}

// ta_Action ta_action_register_timer_add
procedure {:inline 1} ta_action_register_timer_add()
	modifies ta___ra_ret_register_timer_add_0, ta___ra_val_register_timer_add_0, ta_hdr.albion.time, ta_register_timer_0, ta_register_timer_0__last0_old_value, ta_register_timer_0__last0_value, ta_register_timer_0__last_index, ta_register_timer_0__last_old_value, ta_register_timer_0__last_value, ta_register_timer_0__last_write_site, ta_register_timer_0__next_write_site, ta_register_timer_0__wrote_any, ta_register_timer_0__wrote_index0;
{
    ta___ra_val_register_timer_add_0 := ta_register_timer_0.read(ta_register_timer_0, 0bv32);
    call ta___ra_val_register_timer_add_0, ta___ra_ret_register_timer_add_0 := ta_register_timer_add_0.apply(ta___ra_val_register_timer_add_0, ta___ra_ret_register_timer_add_0);
    ta_register_timer_0__next_write_site := 1;
    call ta_register_timer_0.write(0bv32, ta___ra_val_register_timer_add_0);
    ta_hdr.albion.time := ta___ra_ret_register_timer_add_0;
}

// ta_Action ta_action_register_timer_read
procedure {:inline 1} ta_action_register_timer_read()
	modifies ta___ra_ret_register_timer_read_0, ta___ra_val_register_timer_read_0, ta_hdr.albion.time, ta_register_timer_0, ta_register_timer_0__last0_old_value, ta_register_timer_0__last0_value, ta_register_timer_0__last_index, ta_register_timer_0__last_old_value, ta_register_timer_0__last_value, ta_register_timer_0__last_write_site, ta_register_timer_0__next_write_site, ta_register_timer_0__wrote_any, ta_register_timer_0__wrote_index0;
{
    ta___ra_val_register_timer_read_0 := ta_register_timer_0.read(ta_register_timer_0, 0bv32);
    call ta___ra_val_register_timer_read_0, ta___ra_ret_register_timer_read_0 := ta_register_timer_read_0.apply(ta___ra_val_register_timer_read_0, ta___ra_ret_register_timer_read_0);
    ta_register_timer_0__next_write_site := 2;
    call ta_register_timer_0.write(0bv32, ta___ra_val_register_timer_read_0);
    ta_hdr.albion.time := ta___ra_ret_register_timer_read_0;
}

// ta_Action ta_action_send_to_CS
procedure {:inline 1} ta_action_send_to_CS()
	modifies ta_hdr.albion.operation, ta_hdr.albion.port, ta_ig_tm_md.ucast_egress_port;
{
    ta_ig_tm_md.ucast_egress_port := 56bv9;
    ta_hdr.albion.operation := 10bv32;
    ta_hdr.albion.port := 56bv16;
}

// ta_Action ta_action_send_to_CS_1
procedure {:inline 1} ta_action_send_to_CS_1()
	modifies ta_hdr.albion.operation, ta_hdr.albion.port, ta_ig_tm_md.ucast_egress_port;
{
    ta_ig_tm_md.ucast_egress_port := 48bv9;
    ta_hdr.albion.operation := 10bv32;
    ta_hdr.albion.port := 48bv16;
}

// ta_Action ta_action_send_to_CS_2
procedure {:inline 1} ta_action_send_to_CS_2()
	modifies ta_hdr.albion.operation, ta_hdr.albion.port, ta_ig_tm_md.ucast_egress_port;
{
    ta_ig_tm_md.ucast_egress_port := 40bv9;
    ta_hdr.albion.operation := 10bv32;
    ta_hdr.albion.port := 40bv16;
}

// ta_Action ta_action_send_to_CS_3
procedure {:inline 1} ta_action_send_to_CS_3()
	modifies ta_hdr.albion.operation, ta_hdr.albion.port, ta_ig_tm_md.ucast_egress_port;
{
    ta_ig_tm_md.ucast_egress_port := 32bv9;
    ta_hdr.albion.operation := 10bv32;
    ta_hdr.albion.port := 32bv16;
}

// ta_Action ta_action_send_to_CS_4
procedure {:inline 1} ta_action_send_to_CS_4()
	modifies ta_ig_tm_md.ucast_egress_port;
{
    ta_ig_tm_md.ucast_egress_port := 32bv9;
}

// ta_Action ta_action_send_to_client
procedure {:inline 1} ta_action_send_to_client()
	modifies ta_ig_tm_md.ucast_egress_port;
{
    ta_ig_tm_md.ucast_egress_port := 144bv9;
}

// ta_Action ta_action_send_to_master
procedure {:inline 1} ta_action_send_to_master()
	modifies ta_ig_tm_md.ucast_egress_port;
{
    ta_ig_tm_md.ucast_egress_port := 136bv9;
}

// ta_Action ta_action_send_to_master_2
procedure {:inline 1} ta_action_send_to_master_2()
	modifies ta_eg_dprsr_md.mirror_type, ta_meta.no_use, ta_meta.session_id, ta_p4b_clone_e2e;
{
    ta_eg_dprsr_md.mirror_type := 2bv3;
    ta_p4b_clone_e2e := ta_p4b_clone_e2e || (2bv3 != 0bv3);
    ta_meta.session_id := 5bv10;
    ta_meta.no_use := 3bv8;
}

// ta_Action ta_action_send_to_self
procedure {:inline 1} ta_action_send_to_self()
	modifies ta_ig_tm_md.ucast_egress_port;
{
    ta_ig_tm_md.ucast_egress_port := 196bv9;
}

// ta_Action ta_action_state_failed
procedure {:inline 1} ta_action_state_failed()
	modifies ta_hdr.albion.operation;
{
    ta_hdr.albion.operation := 200bv32;
}
procedure {:inline 1} ta_main()
	modifies ta___ra_ret_register_address_h_record_0_read_0, ta___ra_ret_register_address_h_record_0_write_0, ta___ra_ret_register_address_h_record_1_read_0, ta___ra_ret_register_address_h_record_1_write_0, ta___ra_ret_register_address_h_record_2_read_0, ta___ra_ret_register_address_h_record_2_write_0, ta___ra_ret_register_address_h_record_3_read_0, ta___ra_ret_register_address_h_record_3_write_0, ta___ra_ret_register_address_l_record_0_read_0, ta___ra_ret_register_address_l_record_0_write_0, ta___ra_ret_register_address_l_record_1_read_0, ta___ra_ret_register_address_l_record_1_write_0, ta___ra_ret_register_address_l_record_2_read_0, ta___ra_ret_register_address_l_record_2_write_0, ta___ra_ret_register_address_l_record_3_read_0, ta___ra_ret_register_address_l_record_3_write_0, ta___ra_ret_register_num_add_0, ta___ra_ret_register_num_zero_0, ta___ra_ret_register_request_id_high_add_0, ta___ra_ret_register_request_id_low_add_0, ta___ra_ret_register_state_0_r_0, ta___ra_ret_register_state_0_sub_0, ta___ra_ret_register_state_0_w_0, ta___ra_ret_register_state_1_r_0, ta___ra_ret_register_state_1_sub_0, ta___ra_ret_register_state_1_w_0, ta___ra_ret_register_state_2_r_0, ta___ra_ret_register_state_2_sub_0, ta___ra_ret_register_state_2_w_0, ta___ra_ret_register_state_3_r_0, ta___ra_ret_register_state_3_sub_0, ta___ra_ret_register_state_3_w_0, ta___ra_ret_register_timer_add_0, ta___ra_ret_register_timer_read_0, ta___ra_val_register_address_h_record_0_read_0, ta___ra_val_register_address_h_record_0_write_0, ta___ra_val_register_address_h_record_1_read_0, ta___ra_val_register_address_h_record_1_write_0, ta___ra_val_register_address_h_record_2_read_0, ta___ra_val_register_address_h_record_2_write_0, ta___ra_val_register_address_h_record_3_read_0, ta___ra_val_register_address_h_record_3_write_0, ta___ra_val_register_address_l_record_0_read_0, ta___ra_val_register_address_l_record_0_write_0, ta___ra_val_register_address_l_record_1_read_0, ta___ra_val_register_address_l_record_1_write_0, ta___ra_val_register_address_l_record_2_read_0, ta___ra_val_register_address_l_record_2_write_0, ta___ra_val_register_address_l_record_3_read_0, ta___ra_val_register_address_l_record_3_write_0, ta___ra_val_register_num_add_0, ta___ra_val_register_num_zero_0, ta___ra_val_register_request_id_high_add_0, ta___ra_val_register_request_id_low_add_0, ta___ra_val_register_state_0_r_0, ta___ra_val_register_state_0_sub_0, ta___ra_val_register_state_0_w_0, ta___ra_val_register_state_1_r_0, ta___ra_val_register_state_1_sub_0, ta___ra_val_register_state_1_w_0, ta___ra_val_register_state_2_r_0, ta___ra_val_register_state_2_sub_0, ta___ra_val_register_state_2_w_0, ta___ra_val_register_state_3_r_0, ta___ra_val_register_state_3_sub_0, ta___ra_val_register_state_3_w_0, ta___ra_val_register_timer_add_0, ta___ra_val_register_timer_read_0, ta_drop, ta_eg_dprsr_md.mirror_type, ta_hdr.albion.CS_id_1, ta_hdr.albion.index, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion.port, ta_hdr.albion.request_id_high, ta_hdr.albion.request_id_low, ta_hdr.albion.time, ta_hdr.albion_timer.address_high_0, ta_hdr.albion_timer.address_high_1, ta_hdr.albion_timer.address_high_2, ta_hdr.albion_timer.address_high_3, ta_hdr.albion_timer.address_low_0, ta_hdr.albion_timer.address_low_1, ta_hdr.albion_timer.address_low_2, ta_hdr.albion_timer.address_low_3, ta_hdr.albion_timer.state_0, ta_hdr.albion_timer.state_1, ta_hdr.albion_timer.state_2, ta_hdr.albion_timer.state_3, ta_hdr.albion_timer.times, ta_ig_tm_md.ucast_egress_port, ta_isValid, ta_meta.no_use, ta_meta.session_id, ta_meta.state, ta_meta.state_sub, ta_mirror_md_0, ta_p4b_clone_e2e, ta_register_address_h_record, ta_register_address_h_record_4, ta_register_address_h_record_4__last0_old_value, ta_register_address_h_record_4__last0_value, ta_register_address_h_record_4__last_index, ta_register_address_h_record_4__last_old_value, ta_register_address_h_record_4__last_value, ta_register_address_h_record_4__last_write_site, ta_register_address_h_record_4__next_write_site, ta_register_address_h_record_4__wrote_any, ta_register_address_h_record_4__wrote_index0, ta_register_address_h_record_5, ta_register_address_h_record_5__last0_old_value, ta_register_address_h_record_5__last0_value, ta_register_address_h_record_5__last_index, ta_register_address_h_record_5__last_old_value, ta_register_address_h_record_5__last_value, ta_register_address_h_record_5__last_write_site, ta_register_address_h_record_5__next_write_site, ta_register_address_h_record_5__wrote_any, ta_register_address_h_record_5__wrote_index0, ta_register_address_h_record_6, ta_register_address_h_record_6__last0_old_value, ta_register_address_h_record_6__last0_value, ta_register_address_h_record_6__last_index, ta_register_address_h_record_6__last_old_value, ta_register_address_h_record_6__last_value, ta_register_address_h_record_6__last_write_site, ta_register_address_h_record_6__next_write_site, ta_register_address_h_record_6__wrote_any, ta_register_address_h_record_6__wrote_index0, ta_register_address_h_record__last0_old_value, ta_register_address_h_record__last0_value, ta_register_address_h_record__last_index, ta_register_address_h_record__last_old_value, ta_register_address_h_record__last_value, ta_register_address_h_record__last_write_site, ta_register_address_h_record__next_write_site, ta_register_address_h_record__wrote_any, ta_register_address_h_record__wrote_index0, ta_register_address_l_record, ta_register_address_l_record_4, ta_register_address_l_record_4__last0_old_value, ta_register_address_l_record_4__last0_value, ta_register_address_l_record_4__last_index, ta_register_address_l_record_4__last_old_value, ta_register_address_l_record_4__last_value, ta_register_address_l_record_4__last_write_site, ta_register_address_l_record_4__next_write_site, ta_register_address_l_record_4__wrote_any, ta_register_address_l_record_4__wrote_index0, ta_register_address_l_record_5, ta_register_address_l_record_5__last0_old_value, ta_register_address_l_record_5__last0_value, ta_register_address_l_record_5__last_index, ta_register_address_l_record_5__last_old_value, ta_register_address_l_record_5__last_value, ta_register_address_l_record_5__last_write_site, ta_register_address_l_record_5__next_write_site, ta_register_address_l_record_5__wrote_any, ta_register_address_l_record_5__wrote_index0, ta_register_address_l_record_6, ta_register_address_l_record_6__last0_old_value, ta_register_address_l_record_6__last0_value, ta_register_address_l_record_6__last_index, ta_register_address_l_record_6__last_old_value, ta_register_address_l_record_6__last_value, ta_register_address_l_record_6__last_write_site, ta_register_address_l_record_6__next_write_site, ta_register_address_l_record_6__wrote_any, ta_register_address_l_record_6__wrote_index0, ta_register_address_l_record__last0_old_value, ta_register_address_l_record__last0_value, ta_register_address_l_record__last_index, ta_register_address_l_record__last_old_value, ta_register_address_l_record__last_value, ta_register_address_l_record__last_write_site, ta_register_address_l_record__next_write_site, ta_register_address_l_record__wrote_any, ta_register_address_l_record__wrote_index0, ta_register_num_0, ta_register_num_0__last0_old_value, ta_register_num_0__last0_value, ta_register_num_0__last_index, ta_register_num_0__last_old_value, ta_register_num_0__last_value, ta_register_num_0__last_write_site, ta_register_num_0__next_write_site, ta_register_num_0__wrote_any, ta_register_num_0__wrote_index0, ta_register_request_id_high_0, ta_register_request_id_high_0__last0_old_value, ta_register_request_id_high_0__last0_value, ta_register_request_id_high_0__last_index, ta_register_request_id_high_0__last_old_value, ta_register_request_id_high_0__last_value, ta_register_request_id_high_0__last_write_site, ta_register_request_id_high_0__next_write_site, ta_register_request_id_high_0__wrote_any, ta_register_request_id_high_0__wrote_index0, ta_register_request_id_low_0, ta_register_request_id_low_0__last0_old_value, ta_register_request_id_low_0__last0_value, ta_register_request_id_low_0__last_index, ta_register_request_id_low_0__last_old_value, ta_register_request_id_low_0__last_value, ta_register_request_id_low_0__last_write_site, ta_register_request_id_low_0__next_write_site, ta_register_request_id_low_0__wrote_any, ta_register_request_id_low_0__wrote_index0, ta_register_state, ta_register_state_4, ta_register_state_4__last0_old_value, ta_register_state_4__last0_value, ta_register_state_4__last_index, ta_register_state_4__last_old_value, ta_register_state_4__last_value, ta_register_state_4__last_write_site, ta_register_state_4__next_write_site, ta_register_state_4__wrote_any, ta_register_state_4__wrote_index0, ta_register_state_5, ta_register_state_5__last0_old_value, ta_register_state_5__last0_value, ta_register_state_5__last_index, ta_register_state_5__last_old_value, ta_register_state_5__last_value, ta_register_state_5__last_write_site, ta_register_state_5__next_write_site, ta_register_state_5__wrote_any, ta_register_state_5__wrote_index0, ta_register_state_6, ta_register_state_6__last0_old_value, ta_register_state_6__last0_value, ta_register_state_6__last_index, ta_register_state_6__last_old_value, ta_register_state_6__last_value, ta_register_state_6__last_write_site, ta_register_state_6__next_write_site, ta_register_state_6__wrote_any, ta_register_state_6__wrote_index0, ta_register_state__last0_old_value, ta_register_state__last0_value, ta_register_state__last_index, ta_register_state__last_old_value, ta_register_state__last_value, ta_register_state__last_write_site, ta_register_state__next_write_site, ta_register_state__wrote_any, ta_register_state__wrote_index0, ta_register_timer_0, ta_register_timer_0__last0_old_value, ta_register_timer_0__last0_value, ta_register_timer_0__last_index, ta_register_timer_0__last_old_value, ta_register_timer_0__last_value, ta_register_timer_0__last_write_site, ta_register_timer_0__next_write_site, ta_register_timer_0__wrote_any, ta_register_timer_0__wrote_index0, ta_table_check_timer_0.action_run, ta_table_check_timer_0.hit, ta_table_register_address_h_record_0_interaction_0.action_run, ta_table_register_address_h_record_0_interaction_0.hit, ta_table_register_address_h_record_1_interaction_0.action_run, ta_table_register_address_h_record_1_interaction_0.hit, ta_table_register_address_h_record_2_interaction_0.action_run, ta_table_register_address_h_record_2_interaction_0.hit, ta_table_register_address_h_record_3_interaction_0.action_run, ta_table_register_address_h_record_3_interaction_0.hit, ta_table_register_address_l_record_0_interaction_0.action_run, ta_table_register_address_l_record_0_interaction_0.hit, ta_table_register_address_l_record_1_interaction_0.action_run, ta_table_register_address_l_record_1_interaction_0.hit, ta_table_register_address_l_record_2_interaction_0.action_run, ta_table_register_address_l_record_2_interaction_0.hit, ta_table_register_address_l_record_3_interaction_0.action_run, ta_table_register_address_l_record_3_interaction_0.hit, ta_table_register_num_interaction_0.action_run, ta_table_register_num_interaction_0.hit, ta_table_register_request_id_high_interaction_0.action_run, ta_table_register_request_id_high_interaction_0.hit, ta_table_register_state_0_interaction_0.action_run, ta_table_register_state_0_interaction_0.hit, ta_table_register_state_1_interaction_0.action_run, ta_table_register_state_1_interaction_0.hit, ta_table_register_state_2_interaction_0.action_run, ta_table_register_state_2_interaction_0.hit, ta_table_register_state_3_interaction_0.action_run, ta_table_register_state_3_interaction_0.hit, ta_table_register_timer_interaction_0.action_run, ta_table_register_timer_interaction_0.hit, ta_table_send_to_somewhere_0.action_run, ta_table_send_to_somewhere_0.hit, ta_table_state_check_0.action_run, ta_table_state_check_0.hit, ta_table_success_check_0.action_run, ta_table_success_check_0.hit;
{
    call ta_pipe_a();
    if(ta_forward == false){
        ta_drop := true;
    }
}
procedure ta_mainProcedure()
	modifies ta___ra_ret_register_address_h_record_0_read_0, ta___ra_ret_register_address_h_record_0_write_0, ta___ra_ret_register_address_h_record_1_read_0, ta___ra_ret_register_address_h_record_1_write_0, ta___ra_ret_register_address_h_record_2_read_0, ta___ra_ret_register_address_h_record_2_write_0, ta___ra_ret_register_address_h_record_3_read_0, ta___ra_ret_register_address_h_record_3_write_0, ta___ra_ret_register_address_l_record_0_read_0, ta___ra_ret_register_address_l_record_0_write_0, ta___ra_ret_register_address_l_record_1_read_0, ta___ra_ret_register_address_l_record_1_write_0, ta___ra_ret_register_address_l_record_2_read_0, ta___ra_ret_register_address_l_record_2_write_0, ta___ra_ret_register_address_l_record_3_read_0, ta___ra_ret_register_address_l_record_3_write_0, ta___ra_ret_register_num_add_0, ta___ra_ret_register_num_zero_0, ta___ra_ret_register_request_id_high_add_0, ta___ra_ret_register_request_id_low_add_0, ta___ra_ret_register_state_0_r_0, ta___ra_ret_register_state_0_sub_0, ta___ra_ret_register_state_0_w_0, ta___ra_ret_register_state_1_r_0, ta___ra_ret_register_state_1_sub_0, ta___ra_ret_register_state_1_w_0, ta___ra_ret_register_state_2_r_0, ta___ra_ret_register_state_2_sub_0, ta___ra_ret_register_state_2_w_0, ta___ra_ret_register_state_3_r_0, ta___ra_ret_register_state_3_sub_0, ta___ra_ret_register_state_3_w_0, ta___ra_ret_register_timer_add_0, ta___ra_ret_register_timer_read_0, ta___ra_val_register_address_h_record_0_read_0, ta___ra_val_register_address_h_record_0_write_0, ta___ra_val_register_address_h_record_1_read_0, ta___ra_val_register_address_h_record_1_write_0, ta___ra_val_register_address_h_record_2_read_0, ta___ra_val_register_address_h_record_2_write_0, ta___ra_val_register_address_h_record_3_read_0, ta___ra_val_register_address_h_record_3_write_0, ta___ra_val_register_address_l_record_0_read_0, ta___ra_val_register_address_l_record_0_write_0, ta___ra_val_register_address_l_record_1_read_0, ta___ra_val_register_address_l_record_1_write_0, ta___ra_val_register_address_l_record_2_read_0, ta___ra_val_register_address_l_record_2_write_0, ta___ra_val_register_address_l_record_3_read_0, ta___ra_val_register_address_l_record_3_write_0, ta___ra_val_register_num_add_0, ta___ra_val_register_num_zero_0, ta___ra_val_register_request_id_high_add_0, ta___ra_val_register_request_id_low_add_0, ta___ra_val_register_state_0_r_0, ta___ra_val_register_state_0_sub_0, ta___ra_val_register_state_0_w_0, ta___ra_val_register_state_1_r_0, ta___ra_val_register_state_1_sub_0, ta___ra_val_register_state_1_w_0, ta___ra_val_register_state_2_r_0, ta___ra_val_register_state_2_sub_0, ta___ra_val_register_state_2_w_0, ta___ra_val_register_state_3_r_0, ta___ra_val_register_state_3_sub_0, ta___ra_val_register_state_3_w_0, ta___ra_val_register_timer_add_0, ta___ra_val_register_timer_read_0, ta_drop, ta_eg_dprsr_md.mirror_type, ta_hdr.albion.CS_id_1, ta_hdr.albion.index, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion.port, ta_hdr.albion.request_id_high, ta_hdr.albion.request_id_low, ta_hdr.albion.time, ta_hdr.albion_timer.address_high_0, ta_hdr.albion_timer.address_high_1, ta_hdr.albion_timer.address_high_2, ta_hdr.albion_timer.address_high_3, ta_hdr.albion_timer.address_low_0, ta_hdr.albion_timer.address_low_1, ta_hdr.albion_timer.address_low_2, ta_hdr.albion_timer.address_low_3, ta_hdr.albion_timer.state_0, ta_hdr.albion_timer.state_1, ta_hdr.albion_timer.state_2, ta_hdr.albion_timer.state_3, ta_hdr.albion_timer.times, ta_ig_tm_md.ucast_egress_port, ta_isValid, ta_meta.no_use, ta_meta.session_id, ta_meta.state, ta_meta.state_sub, ta_mirror_md_0, ta_p4b_checksum_error, ta_p4b_checksum_updated, ta_p4b_checksum_verified, ta_p4b_clone_e2e, ta_p4b_clone_i2e, ta_p4b_clone_i2i, ta_p4b_digest, ta_p4b_recirculate, ta_register_address_h_record, ta_register_address_h_record_4, ta_register_address_h_record_4__last0_old_value, ta_register_address_h_record_4__last0_value, ta_register_address_h_record_4__last_index, ta_register_address_h_record_4__last_old_value, ta_register_address_h_record_4__last_value, ta_register_address_h_record_4__last_write_site, ta_register_address_h_record_4__next_write_site, ta_register_address_h_record_4__wrote_any, ta_register_address_h_record_4__wrote_index0, ta_register_address_h_record_5, ta_register_address_h_record_5__last0_old_value, ta_register_address_h_record_5__last0_value, ta_register_address_h_record_5__last_index, ta_register_address_h_record_5__last_old_value, ta_register_address_h_record_5__last_value, ta_register_address_h_record_5__last_write_site, ta_register_address_h_record_5__next_write_site, ta_register_address_h_record_5__wrote_any, ta_register_address_h_record_5__wrote_index0, ta_register_address_h_record_6, ta_register_address_h_record_6__last0_old_value, ta_register_address_h_record_6__last0_value, ta_register_address_h_record_6__last_index, ta_register_address_h_record_6__last_old_value, ta_register_address_h_record_6__last_value, ta_register_address_h_record_6__last_write_site, ta_register_address_h_record_6__next_write_site, ta_register_address_h_record_6__wrote_any, ta_register_address_h_record_6__wrote_index0, ta_register_address_h_record__last0_old_value, ta_register_address_h_record__last0_value, ta_register_address_h_record__last_index, ta_register_address_h_record__last_old_value, ta_register_address_h_record__last_value, ta_register_address_h_record__last_write_site, ta_register_address_h_record__next_write_site, ta_register_address_h_record__wrote_any, ta_register_address_h_record__wrote_index0, ta_register_address_l_record, ta_register_address_l_record_4, ta_register_address_l_record_4__last0_old_value, ta_register_address_l_record_4__last0_value, ta_register_address_l_record_4__last_index, ta_register_address_l_record_4__last_old_value, ta_register_address_l_record_4__last_value, ta_register_address_l_record_4__last_write_site, ta_register_address_l_record_4__next_write_site, ta_register_address_l_record_4__wrote_any, ta_register_address_l_record_4__wrote_index0, ta_register_address_l_record_5, ta_register_address_l_record_5__last0_old_value, ta_register_address_l_record_5__last0_value, ta_register_address_l_record_5__last_index, ta_register_address_l_record_5__last_old_value, ta_register_address_l_record_5__last_value, ta_register_address_l_record_5__last_write_site, ta_register_address_l_record_5__next_write_site, ta_register_address_l_record_5__wrote_any, ta_register_address_l_record_5__wrote_index0, ta_register_address_l_record_6, ta_register_address_l_record_6__last0_old_value, ta_register_address_l_record_6__last0_value, ta_register_address_l_record_6__last_index, ta_register_address_l_record_6__last_old_value, ta_register_address_l_record_6__last_value, ta_register_address_l_record_6__last_write_site, ta_register_address_l_record_6__next_write_site, ta_register_address_l_record_6__wrote_any, ta_register_address_l_record_6__wrote_index0, ta_register_address_l_record__last0_old_value, ta_register_address_l_record__last0_value, ta_register_address_l_record__last_index, ta_register_address_l_record__last_old_value, ta_register_address_l_record__last_value, ta_register_address_l_record__last_write_site, ta_register_address_l_record__next_write_site, ta_register_address_l_record__wrote_any, ta_register_address_l_record__wrote_index0, ta_register_num_0, ta_register_num_0__last0_old_value, ta_register_num_0__last0_value, ta_register_num_0__last_index, ta_register_num_0__last_old_value, ta_register_num_0__last_value, ta_register_num_0__last_write_site, ta_register_num_0__next_write_site, ta_register_num_0__wrote_any, ta_register_num_0__wrote_index0, ta_register_request_id_high_0, ta_register_request_id_high_0__last0_old_value, ta_register_request_id_high_0__last0_value, ta_register_request_id_high_0__last_index, ta_register_request_id_high_0__last_old_value, ta_register_request_id_high_0__last_value, ta_register_request_id_high_0__last_write_site, ta_register_request_id_high_0__next_write_site, ta_register_request_id_high_0__wrote_any, ta_register_request_id_high_0__wrote_index0, ta_register_request_id_low_0, ta_register_request_id_low_0__last0_old_value, ta_register_request_id_low_0__last0_value, ta_register_request_id_low_0__last_index, ta_register_request_id_low_0__last_old_value, ta_register_request_id_low_0__last_value, ta_register_request_id_low_0__last_write_site, ta_register_request_id_low_0__next_write_site, ta_register_request_id_low_0__wrote_any, ta_register_request_id_low_0__wrote_index0, ta_register_state, ta_register_state_4, ta_register_state_4__last0_old_value, ta_register_state_4__last0_value, ta_register_state_4__last_index, ta_register_state_4__last_old_value, ta_register_state_4__last_value, ta_register_state_4__last_write_site, ta_register_state_4__next_write_site, ta_register_state_4__wrote_any, ta_register_state_4__wrote_index0, ta_register_state_5, ta_register_state_5__last0_old_value, ta_register_state_5__last0_value, ta_register_state_5__last_index, ta_register_state_5__last_old_value, ta_register_state_5__last_value, ta_register_state_5__last_write_site, ta_register_state_5__next_write_site, ta_register_state_5__wrote_any, ta_register_state_5__wrote_index0, ta_register_state_6, ta_register_state_6__last0_old_value, ta_register_state_6__last0_value, ta_register_state_6__last_index, ta_register_state_6__last_old_value, ta_register_state_6__last_value, ta_register_state_6__last_write_site, ta_register_state_6__next_write_site, ta_register_state_6__wrote_any, ta_register_state_6__wrote_index0, ta_register_state__last0_old_value, ta_register_state__last0_value, ta_register_state__last_index, ta_register_state__last_old_value, ta_register_state__last_value, ta_register_state__last_write_site, ta_register_state__next_write_site, ta_register_state__wrote_any, ta_register_state__wrote_index0, ta_register_timer_0, ta_register_timer_0__last0_old_value, ta_register_timer_0__last0_value, ta_register_timer_0__last_index, ta_register_timer_0__last_old_value, ta_register_timer_0__last_value, ta_register_timer_0__last_write_site, ta_register_timer_0__next_write_site, ta_register_timer_0__wrote_any, ta_register_timer_0__wrote_index0, ta_table_check_timer_0.action_run, ta_table_check_timer_0.hit, ta_table_register_address_h_record_0_interaction_0.action_run, ta_table_register_address_h_record_0_interaction_0.hit, ta_table_register_address_h_record_1_interaction_0.action_run, ta_table_register_address_h_record_1_interaction_0.hit, ta_table_register_address_h_record_2_interaction_0.action_run, ta_table_register_address_h_record_2_interaction_0.hit, ta_table_register_address_h_record_3_interaction_0.action_run, ta_table_register_address_h_record_3_interaction_0.hit, ta_table_register_address_l_record_0_interaction_0.action_run, ta_table_register_address_l_record_0_interaction_0.hit, ta_table_register_address_l_record_1_interaction_0.action_run, ta_table_register_address_l_record_1_interaction_0.hit, ta_table_register_address_l_record_2_interaction_0.action_run, ta_table_register_address_l_record_2_interaction_0.hit, ta_table_register_address_l_record_3_interaction_0.action_run, ta_table_register_address_l_record_3_interaction_0.hit, ta_table_register_num_interaction_0.action_run, ta_table_register_num_interaction_0.hit, ta_table_register_request_id_high_interaction_0.action_run, ta_table_register_request_id_high_interaction_0.hit, ta_table_register_state_0_interaction_0.action_run, ta_table_register_state_0_interaction_0.hit, ta_table_register_state_1_interaction_0.action_run, ta_table_register_state_1_interaction_0.hit, ta_table_register_state_2_interaction_0.action_run, ta_table_register_state_2_interaction_0.hit, ta_table_register_state_3_interaction_0.action_run, ta_table_register_state_3_interaction_0.hit, ta_table_register_timer_interaction_0.action_run, ta_table_register_timer_interaction_0.hit, ta_table_send_to_somewhere_0.action_run, ta_table_send_to_somewhere_0.hit, ta_table_state_check_0.action_run, ta_table_state_check_0.hit, ta_table_success_check_0.action_run, ta_table_success_check_0.hit;
{
    ta_p4b_checksum_error := false;
    ta_p4b_checksum_updated := false;
    ta_p4b_checksum_verified := false;
    ta_p4b_digest := false;
    ta_p4b_recirculate := false;
    ta_p4b_clone_i2i := false;
    ta_p4b_clone_e2e := false;
    ta_p4b_clone_i2e := false;
    call ta_main();
}
procedure ta_mark_to_drop();
    ensures ta_drop==true;
	modifies ta_drop;

// ta_Action ta_no_action
procedure {:inline 1} ta_no_action()
{
}

// ta_Action ta_no_action_1
procedure {:inline 1} ta_no_action_1()
{
}

// ta_Action ta_no_action_10
procedure {:inline 1} ta_no_action_10()
{
}

// ta_Action ta_no_action_11
procedure {:inline 1} ta_no_action_11()
{
}

// ta_Action ta_no_action_12
procedure {:inline 1} ta_no_action_12()
{
}

// ta_Action ta_no_action_13
procedure {:inline 1} ta_no_action_13()
{
}

// ta_Action ta_no_action_14
procedure {:inline 1} ta_no_action_14()
{
}

// ta_Action ta_no_action_15
procedure {:inline 1} ta_no_action_15()
{
}

// ta_Action ta_no_action_16
procedure {:inline 1} ta_no_action_16()
{
}

// ta_Action ta_no_action_2
procedure {:inline 1} ta_no_action_2()
{
}

// ta_Action ta_no_action_3
procedure {:inline 1} ta_no_action_3()
{
}

// ta_Action ta_no_action_4
procedure {:inline 1} ta_no_action_4()
{
}

// ta_Action ta_no_action_5
procedure {:inline 1} ta_no_action_5()
{
}

// ta_Action ta_no_action_6
procedure {:inline 1} ta_no_action_6()
{
}

// ta_Action ta_no_action_7
procedure {:inline 1} ta_no_action_7()
{
}

// ta_Action ta_no_action_8
procedure {:inline 1} ta_no_action_8()
{
}

// ta_Action ta_no_action_9
procedure {:inline 1} ta_no_action_9()
{
}
procedure ta_packet_in.extract(ta_header:ta_Ref);
    ensures (ta_isValid[ta_header] == true);
	modifies ta_isValid;
procedure {:inline 1} ta_pipe_a()
	modifies ta___ra_ret_register_address_h_record_0_read_0, ta___ra_ret_register_address_h_record_0_write_0, ta___ra_ret_register_address_h_record_1_read_0, ta___ra_ret_register_address_h_record_1_write_0, ta___ra_ret_register_address_h_record_2_read_0, ta___ra_ret_register_address_h_record_2_write_0, ta___ra_ret_register_address_h_record_3_read_0, ta___ra_ret_register_address_h_record_3_write_0, ta___ra_ret_register_address_l_record_0_read_0, ta___ra_ret_register_address_l_record_0_write_0, ta___ra_ret_register_address_l_record_1_read_0, ta___ra_ret_register_address_l_record_1_write_0, ta___ra_ret_register_address_l_record_2_read_0, ta___ra_ret_register_address_l_record_2_write_0, ta___ra_ret_register_address_l_record_3_read_0, ta___ra_ret_register_address_l_record_3_write_0, ta___ra_ret_register_num_add_0, ta___ra_ret_register_num_zero_0, ta___ra_ret_register_request_id_high_add_0, ta___ra_ret_register_request_id_low_add_0, ta___ra_ret_register_state_0_r_0, ta___ra_ret_register_state_0_sub_0, ta___ra_ret_register_state_0_w_0, ta___ra_ret_register_state_1_r_0, ta___ra_ret_register_state_1_sub_0, ta___ra_ret_register_state_1_w_0, ta___ra_ret_register_state_2_r_0, ta___ra_ret_register_state_2_sub_0, ta___ra_ret_register_state_2_w_0, ta___ra_ret_register_state_3_r_0, ta___ra_ret_register_state_3_sub_0, ta___ra_ret_register_state_3_w_0, ta___ra_ret_register_timer_add_0, ta___ra_ret_register_timer_read_0, ta___ra_val_register_address_h_record_0_read_0, ta___ra_val_register_address_h_record_0_write_0, ta___ra_val_register_address_h_record_1_read_0, ta___ra_val_register_address_h_record_1_write_0, ta___ra_val_register_address_h_record_2_read_0, ta___ra_val_register_address_h_record_2_write_0, ta___ra_val_register_address_h_record_3_read_0, ta___ra_val_register_address_h_record_3_write_0, ta___ra_val_register_address_l_record_0_read_0, ta___ra_val_register_address_l_record_0_write_0, ta___ra_val_register_address_l_record_1_read_0, ta___ra_val_register_address_l_record_1_write_0, ta___ra_val_register_address_l_record_2_read_0, ta___ra_val_register_address_l_record_2_write_0, ta___ra_val_register_address_l_record_3_read_0, ta___ra_val_register_address_l_record_3_write_0, ta___ra_val_register_num_add_0, ta___ra_val_register_num_zero_0, ta___ra_val_register_request_id_high_add_0, ta___ra_val_register_request_id_low_add_0, ta___ra_val_register_state_0_r_0, ta___ra_val_register_state_0_sub_0, ta___ra_val_register_state_0_w_0, ta___ra_val_register_state_1_r_0, ta___ra_val_register_state_1_sub_0, ta___ra_val_register_state_1_w_0, ta___ra_val_register_state_2_r_0, ta___ra_val_register_state_2_sub_0, ta___ra_val_register_state_2_w_0, ta___ra_val_register_state_3_r_0, ta___ra_val_register_state_3_sub_0, ta___ra_val_register_state_3_w_0, ta___ra_val_register_timer_add_0, ta___ra_val_register_timer_read_0, ta_drop, ta_eg_dprsr_md.mirror_type, ta_hdr.albion.CS_id_1, ta_hdr.albion.index, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion.port, ta_hdr.albion.request_id_high, ta_hdr.albion.request_id_low, ta_hdr.albion.time, ta_hdr.albion_timer.address_high_0, ta_hdr.albion_timer.address_high_1, ta_hdr.albion_timer.address_high_2, ta_hdr.albion_timer.address_high_3, ta_hdr.albion_timer.address_low_0, ta_hdr.albion_timer.address_low_1, ta_hdr.albion_timer.address_low_2, ta_hdr.albion_timer.address_low_3, ta_hdr.albion_timer.state_0, ta_hdr.albion_timer.state_1, ta_hdr.albion_timer.state_2, ta_hdr.albion_timer.state_3, ta_hdr.albion_timer.times, ta_ig_tm_md.ucast_egress_port, ta_isValid, ta_meta.no_use, ta_meta.session_id, ta_meta.state, ta_meta.state_sub, ta_mirror_md_0, ta_p4b_clone_e2e, ta_register_address_h_record, ta_register_address_h_record_4, ta_register_address_h_record_4__last0_old_value, ta_register_address_h_record_4__last0_value, ta_register_address_h_record_4__last_index, ta_register_address_h_record_4__last_old_value, ta_register_address_h_record_4__last_value, ta_register_address_h_record_4__last_write_site, ta_register_address_h_record_4__next_write_site, ta_register_address_h_record_4__wrote_any, ta_register_address_h_record_4__wrote_index0, ta_register_address_h_record_5, ta_register_address_h_record_5__last0_old_value, ta_register_address_h_record_5__last0_value, ta_register_address_h_record_5__last_index, ta_register_address_h_record_5__last_old_value, ta_register_address_h_record_5__last_value, ta_register_address_h_record_5__last_write_site, ta_register_address_h_record_5__next_write_site, ta_register_address_h_record_5__wrote_any, ta_register_address_h_record_5__wrote_index0, ta_register_address_h_record_6, ta_register_address_h_record_6__last0_old_value, ta_register_address_h_record_6__last0_value, ta_register_address_h_record_6__last_index, ta_register_address_h_record_6__last_old_value, ta_register_address_h_record_6__last_value, ta_register_address_h_record_6__last_write_site, ta_register_address_h_record_6__next_write_site, ta_register_address_h_record_6__wrote_any, ta_register_address_h_record_6__wrote_index0, ta_register_address_h_record__last0_old_value, ta_register_address_h_record__last0_value, ta_register_address_h_record__last_index, ta_register_address_h_record__last_old_value, ta_register_address_h_record__last_value, ta_register_address_h_record__last_write_site, ta_register_address_h_record__next_write_site, ta_register_address_h_record__wrote_any, ta_register_address_h_record__wrote_index0, ta_register_address_l_record, ta_register_address_l_record_4, ta_register_address_l_record_4__last0_old_value, ta_register_address_l_record_4__last0_value, ta_register_address_l_record_4__last_index, ta_register_address_l_record_4__last_old_value, ta_register_address_l_record_4__last_value, ta_register_address_l_record_4__last_write_site, ta_register_address_l_record_4__next_write_site, ta_register_address_l_record_4__wrote_any, ta_register_address_l_record_4__wrote_index0, ta_register_address_l_record_5, ta_register_address_l_record_5__last0_old_value, ta_register_address_l_record_5__last0_value, ta_register_address_l_record_5__last_index, ta_register_address_l_record_5__last_old_value, ta_register_address_l_record_5__last_value, ta_register_address_l_record_5__last_write_site, ta_register_address_l_record_5__next_write_site, ta_register_address_l_record_5__wrote_any, ta_register_address_l_record_5__wrote_index0, ta_register_address_l_record_6, ta_register_address_l_record_6__last0_old_value, ta_register_address_l_record_6__last0_value, ta_register_address_l_record_6__last_index, ta_register_address_l_record_6__last_old_value, ta_register_address_l_record_6__last_value, ta_register_address_l_record_6__last_write_site, ta_register_address_l_record_6__next_write_site, ta_register_address_l_record_6__wrote_any, ta_register_address_l_record_6__wrote_index0, ta_register_address_l_record__last0_old_value, ta_register_address_l_record__last0_value, ta_register_address_l_record__last_index, ta_register_address_l_record__last_old_value, ta_register_address_l_record__last_value, ta_register_address_l_record__last_write_site, ta_register_address_l_record__next_write_site, ta_register_address_l_record__wrote_any, ta_register_address_l_record__wrote_index0, ta_register_num_0, ta_register_num_0__last0_old_value, ta_register_num_0__last0_value, ta_register_num_0__last_index, ta_register_num_0__last_old_value, ta_register_num_0__last_value, ta_register_num_0__last_write_site, ta_register_num_0__next_write_site, ta_register_num_0__wrote_any, ta_register_num_0__wrote_index0, ta_register_request_id_high_0, ta_register_request_id_high_0__last0_old_value, ta_register_request_id_high_0__last0_value, ta_register_request_id_high_0__last_index, ta_register_request_id_high_0__last_old_value, ta_register_request_id_high_0__last_value, ta_register_request_id_high_0__last_write_site, ta_register_request_id_high_0__next_write_site, ta_register_request_id_high_0__wrote_any, ta_register_request_id_high_0__wrote_index0, ta_register_request_id_low_0, ta_register_request_id_low_0__last0_old_value, ta_register_request_id_low_0__last0_value, ta_register_request_id_low_0__last_index, ta_register_request_id_low_0__last_old_value, ta_register_request_id_low_0__last_value, ta_register_request_id_low_0__last_write_site, ta_register_request_id_low_0__next_write_site, ta_register_request_id_low_0__wrote_any, ta_register_request_id_low_0__wrote_index0, ta_register_state, ta_register_state_4, ta_register_state_4__last0_old_value, ta_register_state_4__last0_value, ta_register_state_4__last_index, ta_register_state_4__last_old_value, ta_register_state_4__last_value, ta_register_state_4__last_write_site, ta_register_state_4__next_write_site, ta_register_state_4__wrote_any, ta_register_state_4__wrote_index0, ta_register_state_5, ta_register_state_5__last0_old_value, ta_register_state_5__last0_value, ta_register_state_5__last_index, ta_register_state_5__last_old_value, ta_register_state_5__last_value, ta_register_state_5__last_write_site, ta_register_state_5__next_write_site, ta_register_state_5__wrote_any, ta_register_state_5__wrote_index0, ta_register_state_6, ta_register_state_6__last0_old_value, ta_register_state_6__last0_value, ta_register_state_6__last_index, ta_register_state_6__last_old_value, ta_register_state_6__last_value, ta_register_state_6__last_write_site, ta_register_state_6__next_write_site, ta_register_state_6__wrote_any, ta_register_state_6__wrote_index0, ta_register_state__last0_old_value, ta_register_state__last0_value, ta_register_state__last_index, ta_register_state__last_old_value, ta_register_state__last_value, ta_register_state__last_write_site, ta_register_state__next_write_site, ta_register_state__wrote_any, ta_register_state__wrote_index0, ta_register_timer_0, ta_register_timer_0__last0_old_value, ta_register_timer_0__last0_value, ta_register_timer_0__last_index, ta_register_timer_0__last_old_value, ta_register_timer_0__last_value, ta_register_timer_0__last_write_site, ta_register_timer_0__next_write_site, ta_register_timer_0__wrote_any, ta_register_timer_0__wrote_index0, ta_table_check_timer_0.action_run, ta_table_check_timer_0.hit, ta_table_register_address_h_record_0_interaction_0.action_run, ta_table_register_address_h_record_0_interaction_0.hit, ta_table_register_address_h_record_1_interaction_0.action_run, ta_table_register_address_h_record_1_interaction_0.hit, ta_table_register_address_h_record_2_interaction_0.action_run, ta_table_register_address_h_record_2_interaction_0.hit, ta_table_register_address_h_record_3_interaction_0.action_run, ta_table_register_address_h_record_3_interaction_0.hit, ta_table_register_address_l_record_0_interaction_0.action_run, ta_table_register_address_l_record_0_interaction_0.hit, ta_table_register_address_l_record_1_interaction_0.action_run, ta_table_register_address_l_record_1_interaction_0.hit, ta_table_register_address_l_record_2_interaction_0.action_run, ta_table_register_address_l_record_2_interaction_0.hit, ta_table_register_address_l_record_3_interaction_0.action_run, ta_table_register_address_l_record_3_interaction_0.hit, ta_table_register_num_interaction_0.action_run, ta_table_register_num_interaction_0.hit, ta_table_register_request_id_high_interaction_0.action_run, ta_table_register_request_id_high_interaction_0.hit, ta_table_register_state_0_interaction_0.action_run, ta_table_register_state_0_interaction_0.hit, ta_table_register_state_1_interaction_0.action_run, ta_table_register_state_1_interaction_0.hit, ta_table_register_state_2_interaction_0.action_run, ta_table_register_state_2_interaction_0.hit, ta_table_register_state_3_interaction_0.action_run, ta_table_register_state_3_interaction_0.hit, ta_table_register_timer_interaction_0.action_run, ta_table_register_timer_interaction_0.hit, ta_table_send_to_somewhere_0.action_run, ta_table_send_to_somewhere_0.hit, ta_table_state_check_0.action_run, ta_table_state_check_0.hit, ta_table_success_check_0.action_run, ta_table_success_check_0.hit;
{
    call ta_aIngressParser();
    call ta_aIngress();
    call ta_aIngressDeparser();
    call ta_aEgressParser();
    call ta_aEgress();
    call ta_aEgressDeparser();
}
procedure ta_pkt.advance(ta_arg0:bv32);
procedure ta_pkt.emit(ta_arg0:ta_Ref);
function {:inline true}ta_register_address_h_record.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_address_h_record.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_address_h_record, ta_register_address_h_record__last0_old_value, ta_register_address_h_record__last0_value, ta_register_address_h_record__last_index, ta_register_address_h_record__last_old_value, ta_register_address_h_record__last_value, ta_register_address_h_record__last_write_site, ta_register_address_h_record__wrote_any, ta_register_address_h_record__wrote_index0;
{
    ta_register_address_h_record__last_old_value := ta_register_address_h_record[ta_index];
    ta_register_address_h_record[ta_index] := ta_value;
    ta_register_address_h_record__last_index := ta_index;
    ta_register_address_h_record__last_value := ta_value;
    ta_register_address_h_record__last_write_site := ta_register_address_h_record__next_write_site;
    ta_register_address_h_record__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_address_h_record__wrote_index0 := true;
        ta_register_address_h_record__last0_old_value := ta_register_address_h_record__last_old_value;
        ta_register_address_h_record__last0_value := ta_value;
    }
}

// ta_RegisterAction ta_register_address_h_record_0_read_0.apply
procedure {:inline 1} ta_register_address_h_record_0_read_0.apply(ta_value_r_in:bv32, ta_read_value_in:bv32) returns (ta_value_r_out:bv32, ta_read_value_out:bv32)
{
    var ta_value_r:bv32;
    var ta_read_value:bv32;
    ta_value_r := ta_value_r_in;
    ta_read_value := ta_read_value_in;
    ta_read_value := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_read_value_out := ta_read_value;
}

// ta_RegisterAction ta_register_address_h_record_0_write_0.apply
procedure {:inline 1} ta_register_address_h_record_0_write_0.apply(ta_value_r_in:bv32) returns (ta_value_r_out:bv32)
{
    var ta_value_r:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_r := ta_hdr.albion.address_h;
    ta_value_r_out := ta_value_r;
}

// ta_RegisterAction ta_register_address_h_record_1_read_0.apply
procedure {:inline 1} ta_register_address_h_record_1_read_0.apply(ta_value_r_in:bv32, ta_read_value_in:bv32) returns (ta_value_r_out:bv32, ta_read_value_out:bv32)
{
    var ta_value_r:bv32;
    var ta_read_value:bv32;
    ta_value_r := ta_value_r_in;
    ta_read_value := ta_read_value_in;
    ta_read_value := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_read_value_out := ta_read_value;
}

// ta_RegisterAction ta_register_address_h_record_1_write_0.apply
procedure {:inline 1} ta_register_address_h_record_1_write_0.apply(ta_value_r_in:bv32) returns (ta_value_r_out:bv32)
{
    var ta_value_r:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_r := ta_hdr.albion.address_h;
    ta_value_r_out := ta_value_r;
}

// ta_RegisterAction ta_register_address_h_record_2_read_0.apply
procedure {:inline 1} ta_register_address_h_record_2_read_0.apply(ta_value_r_in:bv32, ta_read_value_in:bv32) returns (ta_value_r_out:bv32, ta_read_value_out:bv32)
{
    var ta_value_r:bv32;
    var ta_read_value:bv32;
    ta_value_r := ta_value_r_in;
    ta_read_value := ta_read_value_in;
    ta_read_value := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_read_value_out := ta_read_value;
}

// ta_RegisterAction ta_register_address_h_record_2_write_0.apply
procedure {:inline 1} ta_register_address_h_record_2_write_0.apply(ta_value_r_in:bv32) returns (ta_value_r_out:bv32)
{
    var ta_value_r:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_r := ta_hdr.albion.address_h;
    ta_value_r_out := ta_value_r;
}

// ta_RegisterAction ta_register_address_h_record_3_read_0.apply
procedure {:inline 1} ta_register_address_h_record_3_read_0.apply(ta_value_r_in:bv32, ta_read_value_in:bv32) returns (ta_value_r_out:bv32, ta_read_value_out:bv32)
{
    var ta_value_r:bv32;
    var ta_read_value:bv32;
    ta_value_r := ta_value_r_in;
    ta_read_value := ta_read_value_in;
    ta_read_value := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_read_value_out := ta_read_value;
}

// ta_RegisterAction ta_register_address_h_record_3_write_0.apply
procedure {:inline 1} ta_register_address_h_record_3_write_0.apply(ta_value_r_in:bv32) returns (ta_value_r_out:bv32)
{
    var ta_value_r:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_r := ta_hdr.albion.address_h;
    ta_value_r_out := ta_value_r;
}
function {:inline true}ta_register_address_h_record_4.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_address_h_record_4.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_address_h_record_4, ta_register_address_h_record_4__last0_old_value, ta_register_address_h_record_4__last0_value, ta_register_address_h_record_4__last_index, ta_register_address_h_record_4__last_old_value, ta_register_address_h_record_4__last_value, ta_register_address_h_record_4__last_write_site, ta_register_address_h_record_4__wrote_any, ta_register_address_h_record_4__wrote_index0;
{
    ta_register_address_h_record_4__last_old_value := ta_register_address_h_record_4[ta_index];
    ta_register_address_h_record_4[ta_index] := ta_value;
    ta_register_address_h_record_4__last_index := ta_index;
    ta_register_address_h_record_4__last_value := ta_value;
    ta_register_address_h_record_4__last_write_site := ta_register_address_h_record_4__next_write_site;
    ta_register_address_h_record_4__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_address_h_record_4__wrote_index0 := true;
        ta_register_address_h_record_4__last0_old_value := ta_register_address_h_record_4__last_old_value;
        ta_register_address_h_record_4__last0_value := ta_value;
    }
}
function {:inline true}ta_register_address_h_record_5.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_address_h_record_5.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_address_h_record_5, ta_register_address_h_record_5__last0_old_value, ta_register_address_h_record_5__last0_value, ta_register_address_h_record_5__last_index, ta_register_address_h_record_5__last_old_value, ta_register_address_h_record_5__last_value, ta_register_address_h_record_5__last_write_site, ta_register_address_h_record_5__wrote_any, ta_register_address_h_record_5__wrote_index0;
{
    ta_register_address_h_record_5__last_old_value := ta_register_address_h_record_5[ta_index];
    ta_register_address_h_record_5[ta_index] := ta_value;
    ta_register_address_h_record_5__last_index := ta_index;
    ta_register_address_h_record_5__last_value := ta_value;
    ta_register_address_h_record_5__last_write_site := ta_register_address_h_record_5__next_write_site;
    ta_register_address_h_record_5__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_address_h_record_5__wrote_index0 := true;
        ta_register_address_h_record_5__last0_old_value := ta_register_address_h_record_5__last_old_value;
        ta_register_address_h_record_5__last0_value := ta_value;
    }
}
function {:inline true}ta_register_address_h_record_6.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_address_h_record_6.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_address_h_record_6, ta_register_address_h_record_6__last0_old_value, ta_register_address_h_record_6__last0_value, ta_register_address_h_record_6__last_index, ta_register_address_h_record_6__last_old_value, ta_register_address_h_record_6__last_value, ta_register_address_h_record_6__last_write_site, ta_register_address_h_record_6__wrote_any, ta_register_address_h_record_6__wrote_index0;
{
    ta_register_address_h_record_6__last_old_value := ta_register_address_h_record_6[ta_index];
    ta_register_address_h_record_6[ta_index] := ta_value;
    ta_register_address_h_record_6__last_index := ta_index;
    ta_register_address_h_record_6__last_value := ta_value;
    ta_register_address_h_record_6__last_write_site := ta_register_address_h_record_6__next_write_site;
    ta_register_address_h_record_6__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_address_h_record_6__wrote_index0 := true;
        ta_register_address_h_record_6__last0_old_value := ta_register_address_h_record_6__last_old_value;
        ta_register_address_h_record_6__last0_value := ta_value;
    }
}
function {:inline true}ta_register_address_l_record.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_address_l_record.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_address_l_record, ta_register_address_l_record__last0_old_value, ta_register_address_l_record__last0_value, ta_register_address_l_record__last_index, ta_register_address_l_record__last_old_value, ta_register_address_l_record__last_value, ta_register_address_l_record__last_write_site, ta_register_address_l_record__wrote_any, ta_register_address_l_record__wrote_index0;
{
    ta_register_address_l_record__last_old_value := ta_register_address_l_record[ta_index];
    ta_register_address_l_record[ta_index] := ta_value;
    ta_register_address_l_record__last_index := ta_index;
    ta_register_address_l_record__last_value := ta_value;
    ta_register_address_l_record__last_write_site := ta_register_address_l_record__next_write_site;
    ta_register_address_l_record__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_address_l_record__wrote_index0 := true;
        ta_register_address_l_record__last0_old_value := ta_register_address_l_record__last_old_value;
        ta_register_address_l_record__last0_value := ta_value;
    }
}

// ta_RegisterAction ta_register_address_l_record_0_read_0.apply
procedure {:inline 1} ta_register_address_l_record_0_read_0.apply(ta_value_r_in:bv32, ta_read_value_in:bv32) returns (ta_value_r_out:bv32, ta_read_value_out:bv32)
{
    var ta_value_r:bv32;
    var ta_read_value:bv32;
    ta_value_r := ta_value_r_in;
    ta_read_value := ta_read_value_in;
    ta_read_value := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_read_value_out := ta_read_value;
}

// ta_RegisterAction ta_register_address_l_record_0_write_0.apply
procedure {:inline 1} ta_register_address_l_record_0_write_0.apply(ta_value_r_in:bv32) returns (ta_value_r_out:bv32)
{
    var ta_value_r:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_r := ta_hdr.albion.address_l;
    ta_value_r_out := ta_value_r;
}

// ta_RegisterAction ta_register_address_l_record_1_read_0.apply
procedure {:inline 1} ta_register_address_l_record_1_read_0.apply(ta_value_r_in:bv32, ta_read_value_in:bv32) returns (ta_value_r_out:bv32, ta_read_value_out:bv32)
{
    var ta_value_r:bv32;
    var ta_read_value:bv32;
    ta_value_r := ta_value_r_in;
    ta_read_value := ta_read_value_in;
    ta_read_value := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_read_value_out := ta_read_value;
}

// ta_RegisterAction ta_register_address_l_record_1_write_0.apply
procedure {:inline 1} ta_register_address_l_record_1_write_0.apply(ta_value_r_in:bv32) returns (ta_value_r_out:bv32)
{
    var ta_value_r:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_r := ta_hdr.albion.address_l;
    ta_value_r_out := ta_value_r;
}

// ta_RegisterAction ta_register_address_l_record_2_read_0.apply
procedure {:inline 1} ta_register_address_l_record_2_read_0.apply(ta_value_r_in:bv32, ta_read_value_in:bv32) returns (ta_value_r_out:bv32, ta_read_value_out:bv32)
{
    var ta_value_r:bv32;
    var ta_read_value:bv32;
    ta_value_r := ta_value_r_in;
    ta_read_value := ta_read_value_in;
    ta_read_value := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_read_value_out := ta_read_value;
}

// ta_RegisterAction ta_register_address_l_record_2_write_0.apply
procedure {:inline 1} ta_register_address_l_record_2_write_0.apply(ta_value_r_in:bv32) returns (ta_value_r_out:bv32)
{
    var ta_value_r:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_r := ta_hdr.albion.address_l;
    ta_value_r_out := ta_value_r;
}

// ta_RegisterAction ta_register_address_l_record_3_read_0.apply
procedure {:inline 1} ta_register_address_l_record_3_read_0.apply(ta_value_r_in:bv32, ta_read_value_in:bv32) returns (ta_value_r_out:bv32, ta_read_value_out:bv32)
{
    var ta_value_r:bv32;
    var ta_read_value:bv32;
    ta_value_r := ta_value_r_in;
    ta_read_value := ta_read_value_in;
    ta_read_value := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_read_value_out := ta_read_value;
}

// ta_RegisterAction ta_register_address_l_record_3_write_0.apply
procedure {:inline 1} ta_register_address_l_record_3_write_0.apply(ta_value_r_in:bv32) returns (ta_value_r_out:bv32)
{
    var ta_value_r:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_r := ta_hdr.albion.address_l;
    ta_value_r_out := ta_value_r;
}
function {:inline true}ta_register_address_l_record_4.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_address_l_record_4.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_address_l_record_4, ta_register_address_l_record_4__last0_old_value, ta_register_address_l_record_4__last0_value, ta_register_address_l_record_4__last_index, ta_register_address_l_record_4__last_old_value, ta_register_address_l_record_4__last_value, ta_register_address_l_record_4__last_write_site, ta_register_address_l_record_4__wrote_any, ta_register_address_l_record_4__wrote_index0;
{
    ta_register_address_l_record_4__last_old_value := ta_register_address_l_record_4[ta_index];
    ta_register_address_l_record_4[ta_index] := ta_value;
    ta_register_address_l_record_4__last_index := ta_index;
    ta_register_address_l_record_4__last_value := ta_value;
    ta_register_address_l_record_4__last_write_site := ta_register_address_l_record_4__next_write_site;
    ta_register_address_l_record_4__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_address_l_record_4__wrote_index0 := true;
        ta_register_address_l_record_4__last0_old_value := ta_register_address_l_record_4__last_old_value;
        ta_register_address_l_record_4__last0_value := ta_value;
    }
}
function {:inline true}ta_register_address_l_record_5.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_address_l_record_5.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_address_l_record_5, ta_register_address_l_record_5__last0_old_value, ta_register_address_l_record_5__last0_value, ta_register_address_l_record_5__last_index, ta_register_address_l_record_5__last_old_value, ta_register_address_l_record_5__last_value, ta_register_address_l_record_5__last_write_site, ta_register_address_l_record_5__wrote_any, ta_register_address_l_record_5__wrote_index0;
{
    ta_register_address_l_record_5__last_old_value := ta_register_address_l_record_5[ta_index];
    ta_register_address_l_record_5[ta_index] := ta_value;
    ta_register_address_l_record_5__last_index := ta_index;
    ta_register_address_l_record_5__last_value := ta_value;
    ta_register_address_l_record_5__last_write_site := ta_register_address_l_record_5__next_write_site;
    ta_register_address_l_record_5__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_address_l_record_5__wrote_index0 := true;
        ta_register_address_l_record_5__last0_old_value := ta_register_address_l_record_5__last_old_value;
        ta_register_address_l_record_5__last0_value := ta_value;
    }
}
function {:inline true}ta_register_address_l_record_6.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_address_l_record_6.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_address_l_record_6, ta_register_address_l_record_6__last0_old_value, ta_register_address_l_record_6__last0_value, ta_register_address_l_record_6__last_index, ta_register_address_l_record_6__last_old_value, ta_register_address_l_record_6__last_value, ta_register_address_l_record_6__last_write_site, ta_register_address_l_record_6__wrote_any, ta_register_address_l_record_6__wrote_index0;
{
    ta_register_address_l_record_6__last_old_value := ta_register_address_l_record_6[ta_index];
    ta_register_address_l_record_6[ta_index] := ta_value;
    ta_register_address_l_record_6__last_index := ta_index;
    ta_register_address_l_record_6__last_value := ta_value;
    ta_register_address_l_record_6__last_write_site := ta_register_address_l_record_6__next_write_site;
    ta_register_address_l_record_6__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_address_l_record_6__wrote_index0 := true;
        ta_register_address_l_record_6__last0_old_value := ta_register_address_l_record_6__last_old_value;
        ta_register_address_l_record_6__last0_value := ta_value;
    }
}
function {:inline true}ta_register_num_0.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_num_0.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_num_0, ta_register_num_0__last0_old_value, ta_register_num_0__last0_value, ta_register_num_0__last_index, ta_register_num_0__last_old_value, ta_register_num_0__last_value, ta_register_num_0__last_write_site, ta_register_num_0__wrote_any, ta_register_num_0__wrote_index0;
{
    ta_register_num_0__last_old_value := ta_register_num_0[ta_index];
    ta_register_num_0[ta_index] := ta_value;
    ta_register_num_0__last_index := ta_index;
    ta_register_num_0__last_value := ta_value;
    ta_register_num_0__last_write_site := ta_register_num_0__next_write_site;
    ta_register_num_0__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_num_0__wrote_index0 := true;
        ta_register_num_0__last0_old_value := ta_register_num_0__last_old_value;
        ta_register_num_0__last0_value := ta_value;
    }
}

// ta_RegisterAction ta_register_num_add_0.apply
procedure {:inline 1} ta_register_num_add_0.apply(ta_value_r_in:bv32, ta_value_t_in:bv32) returns (ta_value_r_out:bv32, ta_value_t_out:bv32)
{
    var ta_value_r:bv32;
    var ta_value_t:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_t := ta_value_t_in;
    ta_value_t := ta_value_r;
    ta_value_r := add.bv32(ta_value_r, 1bv32);
    ta_value_r_out := ta_value_r;
    ta_value_t_out := ta_value_t;
}

// ta_RegisterAction ta_register_num_zero_0.apply
procedure {:inline 1} ta_register_num_zero_0.apply(ta_value_r_in:bv32, ta_value_t_in:bv32) returns (ta_value_r_out:bv32, ta_value_t_out:bv32)
{
    var ta_value_r:bv32;
    var ta_value_t:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_t := ta_value_t_in;
    ta_value_r := 0bv32;
    ta_value_r_out := ta_value_r;
    ta_value_t_out := ta_value_t;
}
function {:inline true}ta_register_request_id_high_0.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_request_id_high_0.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_request_id_high_0, ta_register_request_id_high_0__last0_old_value, ta_register_request_id_high_0__last0_value, ta_register_request_id_high_0__last_index, ta_register_request_id_high_0__last_old_value, ta_register_request_id_high_0__last_value, ta_register_request_id_high_0__last_write_site, ta_register_request_id_high_0__wrote_any, ta_register_request_id_high_0__wrote_index0;
{
    ta_register_request_id_high_0__last_old_value := ta_register_request_id_high_0[ta_index];
    ta_register_request_id_high_0[ta_index] := ta_value;
    ta_register_request_id_high_0__last_index := ta_index;
    ta_register_request_id_high_0__last_value := ta_value;
    ta_register_request_id_high_0__last_write_site := ta_register_request_id_high_0__next_write_site;
    ta_register_request_id_high_0__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_request_id_high_0__wrote_index0 := true;
        ta_register_request_id_high_0__last0_old_value := ta_register_request_id_high_0__last_old_value;
        ta_register_request_id_high_0__last0_value := ta_value;
    }
}

// ta_RegisterAction ta_register_request_id_high_add_0.apply
procedure {:inline 1} ta_register_request_id_high_add_0.apply(ta_value_r_in:bv32, ta_value_t_in:bv32) returns (ta_value_r_out:bv32, ta_value_t_out:bv32)
{
    var ta_value_r:bv32;
    var ta_value_t:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_t := ta_value_t_in;
    ta_value_r := add.bv32(ta_value_r, 1bv32);
    ta_value_t := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_value_t_out := ta_value_t;
}
function {:inline true}ta_register_request_id_low_0.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_request_id_low_0.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_request_id_low_0, ta_register_request_id_low_0__last0_old_value, ta_register_request_id_low_0__last0_value, ta_register_request_id_low_0__last_index, ta_register_request_id_low_0__last_old_value, ta_register_request_id_low_0__last_value, ta_register_request_id_low_0__last_write_site, ta_register_request_id_low_0__wrote_any, ta_register_request_id_low_0__wrote_index0;
{
    ta_register_request_id_low_0__last_old_value := ta_register_request_id_low_0[ta_index];
    ta_register_request_id_low_0[ta_index] := ta_value;
    ta_register_request_id_low_0__last_index := ta_index;
    ta_register_request_id_low_0__last_value := ta_value;
    ta_register_request_id_low_0__last_write_site := ta_register_request_id_low_0__next_write_site;
    ta_register_request_id_low_0__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_request_id_low_0__wrote_index0 := true;
        ta_register_request_id_low_0__last0_old_value := ta_register_request_id_low_0__last_old_value;
        ta_register_request_id_low_0__last0_value := ta_value;
    }
}

// ta_RegisterAction ta_register_request_id_low_add_0.apply
procedure {:inline 1} ta_register_request_id_low_add_0.apply(ta_value_r_in:bv32, ta_value_t_in:bv32) returns (ta_value_r_out:bv32, ta_value_t_out:bv32)
{
    var ta_value_r:bv32;
    var ta_value_t:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_t := ta_value_t_in;
    ta_value_r := add.bv32(ta_value_r, 1bv32);
    ta_value_t := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_value_t_out := ta_value_t;
}
function {:inline true}ta_register_state.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_state.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_state, ta_register_state__last0_old_value, ta_register_state__last0_value, ta_register_state__last_index, ta_register_state__last_old_value, ta_register_state__last_value, ta_register_state__last_write_site, ta_register_state__wrote_any, ta_register_state__wrote_index0;
{
    ta_register_state__last_old_value := ta_register_state[ta_index];
    ta_register_state[ta_index] := ta_value;
    ta_register_state__last_index := ta_index;
    ta_register_state__last_value := ta_value;
    ta_register_state__last_write_site := ta_register_state__next_write_site;
    ta_register_state__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_state__wrote_index0 := true;
        ta_register_state__last0_old_value := ta_register_state__last_old_value;
        ta_register_state__last0_value := ta_value;
    }
}

// ta_RegisterAction ta_register_state_0_r_0.apply
procedure {:inline 1} ta_register_state_0_r_0.apply(ta_value_r_in:bv32, ta_value_t_in:bv32) returns (ta_value_r_out:bv32, ta_value_t_out:bv32)
{
    var ta_value_r:bv32;
    var ta_value_t:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_t := ta_value_t_in;
    ta_value_t := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_value_t_out := ta_value_t;
}

// ta_RegisterAction ta_register_state_0_sub_0.apply
procedure {:inline 1} ta_register_state_0_sub_0.apply(ta_value_r_in:bv32, ta_value_t_in:bv32) returns (ta_value_r_out:bv32, ta_value_t_out:bv32)
{
    var ta_value_r:bv32;
    var ta_value_t:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_t := ta_value_t_in;
    ta_value_r := band.bv32(ta_value_r, ta_meta.state_sub);
    ta_value_t := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_value_t_out := ta_value_t;
}

// ta_RegisterAction ta_register_state_0_w_0.apply
procedure {:inline 1} ta_register_state_0_w_0.apply(ta_value_r_in:bv32) returns (ta_value_r_out:bv32)
{
    var ta_value_r:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_r := 7bv32;
    ta_value_r_out := ta_value_r;
}

// ta_RegisterAction ta_register_state_1_r_0.apply
procedure {:inline 1} ta_register_state_1_r_0.apply(ta_value_r_in:bv32, ta_value_t_in:bv32) returns (ta_value_r_out:bv32, ta_value_t_out:bv32)
{
    var ta_value_r:bv32;
    var ta_value_t:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_t := ta_value_t_in;
    ta_value_t := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_value_t_out := ta_value_t;
}

// ta_RegisterAction ta_register_state_1_sub_0.apply
procedure {:inline 1} ta_register_state_1_sub_0.apply(ta_value_r_in:bv32, ta_value_t_in:bv32) returns (ta_value_r_out:bv32, ta_value_t_out:bv32)
{
    var ta_value_r:bv32;
    var ta_value_t:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_t := ta_value_t_in;
    ta_value_r := band.bv32(ta_value_r, ta_meta.state_sub);
    ta_value_t := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_value_t_out := ta_value_t;
}

// ta_RegisterAction ta_register_state_1_w_0.apply
procedure {:inline 1} ta_register_state_1_w_0.apply(ta_value_r_in:bv32) returns (ta_value_r_out:bv32)
{
    var ta_value_r:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_r := 7bv32;
    ta_value_r_out := ta_value_r;
}

// ta_RegisterAction ta_register_state_2_r_0.apply
procedure {:inline 1} ta_register_state_2_r_0.apply(ta_value_r_in:bv32, ta_value_t_in:bv32) returns (ta_value_r_out:bv32, ta_value_t_out:bv32)
{
    var ta_value_r:bv32;
    var ta_value_t:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_t := ta_value_t_in;
    ta_value_t := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_value_t_out := ta_value_t;
}

// ta_RegisterAction ta_register_state_2_sub_0.apply
procedure {:inline 1} ta_register_state_2_sub_0.apply(ta_value_r_in:bv32, ta_value_t_in:bv32) returns (ta_value_r_out:bv32, ta_value_t_out:bv32)
{
    var ta_value_r:bv32;
    var ta_value_t:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_t := ta_value_t_in;
    ta_value_r := band.bv32(ta_value_r, ta_meta.state_sub);
    ta_value_t := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_value_t_out := ta_value_t;
}

// ta_RegisterAction ta_register_state_2_w_0.apply
procedure {:inline 1} ta_register_state_2_w_0.apply(ta_value_r_in:bv32) returns (ta_value_r_out:bv32)
{
    var ta_value_r:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_r := 7bv32;
    ta_value_r_out := ta_value_r;
}

// ta_RegisterAction ta_register_state_3_r_0.apply
procedure {:inline 1} ta_register_state_3_r_0.apply(ta_value_r_in:bv32, ta_value_t_in:bv32) returns (ta_value_r_out:bv32, ta_value_t_out:bv32)
{
    var ta_value_r:bv32;
    var ta_value_t:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_t := ta_value_t_in;
    ta_value_t := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_value_t_out := ta_value_t;
}

// ta_RegisterAction ta_register_state_3_sub_0.apply
procedure {:inline 1} ta_register_state_3_sub_0.apply(ta_value_r_in:bv32, ta_value_t_in:bv32) returns (ta_value_r_out:bv32, ta_value_t_out:bv32)
{
    var ta_value_r:bv32;
    var ta_value_t:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_t := ta_value_t_in;
    ta_value_r := band.bv32(ta_value_r, ta_meta.state_sub);
    ta_value_t := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_value_t_out := ta_value_t;
}

// ta_RegisterAction ta_register_state_3_w_0.apply
procedure {:inline 1} ta_register_state_3_w_0.apply(ta_value_r_in:bv32) returns (ta_value_r_out:bv32)
{
    var ta_value_r:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_r := 7bv32;
    ta_value_r_out := ta_value_r;
}
function {:inline true}ta_register_state_4.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_state_4.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_state_4, ta_register_state_4__last0_old_value, ta_register_state_4__last0_value, ta_register_state_4__last_index, ta_register_state_4__last_old_value, ta_register_state_4__last_value, ta_register_state_4__last_write_site, ta_register_state_4__wrote_any, ta_register_state_4__wrote_index0;
{
    ta_register_state_4__last_old_value := ta_register_state_4[ta_index];
    ta_register_state_4[ta_index] := ta_value;
    ta_register_state_4__last_index := ta_index;
    ta_register_state_4__last_value := ta_value;
    ta_register_state_4__last_write_site := ta_register_state_4__next_write_site;
    ta_register_state_4__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_state_4__wrote_index0 := true;
        ta_register_state_4__last0_old_value := ta_register_state_4__last_old_value;
        ta_register_state_4__last0_value := ta_value;
    }
}
function {:inline true}ta_register_state_5.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_state_5.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_state_5, ta_register_state_5__last0_old_value, ta_register_state_5__last0_value, ta_register_state_5__last_index, ta_register_state_5__last_old_value, ta_register_state_5__last_value, ta_register_state_5__last_write_site, ta_register_state_5__wrote_any, ta_register_state_5__wrote_index0;
{
    ta_register_state_5__last_old_value := ta_register_state_5[ta_index];
    ta_register_state_5[ta_index] := ta_value;
    ta_register_state_5__last_index := ta_index;
    ta_register_state_5__last_value := ta_value;
    ta_register_state_5__last_write_site := ta_register_state_5__next_write_site;
    ta_register_state_5__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_state_5__wrote_index0 := true;
        ta_register_state_5__last0_old_value := ta_register_state_5__last_old_value;
        ta_register_state_5__last0_value := ta_value;
    }
}
function {:inline true}ta_register_state_6.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_state_6.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_state_6, ta_register_state_6__last0_old_value, ta_register_state_6__last0_value, ta_register_state_6__last_index, ta_register_state_6__last_old_value, ta_register_state_6__last_value, ta_register_state_6__last_write_site, ta_register_state_6__wrote_any, ta_register_state_6__wrote_index0;
{
    ta_register_state_6__last_old_value := ta_register_state_6[ta_index];
    ta_register_state_6[ta_index] := ta_value;
    ta_register_state_6__last_index := ta_index;
    ta_register_state_6__last_value := ta_value;
    ta_register_state_6__last_write_site := ta_register_state_6__next_write_site;
    ta_register_state_6__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_state_6__wrote_index0 := true;
        ta_register_state_6__last0_old_value := ta_register_state_6__last_old_value;
        ta_register_state_6__last0_value := ta_value;
    }
}
function {:inline true}ta_register_timer_0.read(ta_reg:[bv32]bv32, ta_index:bv32)returns (bv32) {ta_reg[ta_index]}
procedure {:inline 1} ta_register_timer_0.write(ta_index:bv32, ta_value:bv32)
	modifies ta_register_timer_0, ta_register_timer_0__last0_old_value, ta_register_timer_0__last0_value, ta_register_timer_0__last_index, ta_register_timer_0__last_old_value, ta_register_timer_0__last_value, ta_register_timer_0__last_write_site, ta_register_timer_0__wrote_any, ta_register_timer_0__wrote_index0;
{
    ta_register_timer_0__last_old_value := ta_register_timer_0[ta_index];
    ta_register_timer_0[ta_index] := ta_value;
    ta_register_timer_0__last_index := ta_index;
    ta_register_timer_0__last_value := ta_value;
    ta_register_timer_0__last_write_site := ta_register_timer_0__next_write_site;
    ta_register_timer_0__wrote_any := true;
    if (ta_index == 0bv32) {
        ta_register_timer_0__wrote_index0 := true;
        ta_register_timer_0__last0_old_value := ta_register_timer_0__last_old_value;
        ta_register_timer_0__last0_value := ta_value;
    }
}

// ta_RegisterAction ta_register_timer_add_0.apply
procedure {:inline 1} ta_register_timer_add_0.apply(ta_value_r_in:bv32, ta_value_t_in:bv32) returns (ta_value_r_out:bv32, ta_value_t_out:bv32)
{
    var ta_value_r:bv32;
    var ta_value_t:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_t := ta_value_t_in;
    if((ta_value_r == 666bv32)){
        ta_value_r := 0bv32;
    }
    else{
        ta_value_r := add.bv32(ta_value_r, 1bv32);
    }
    ta_value_t := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_value_t_out := ta_value_t;
}

// ta_RegisterAction ta_register_timer_read_0.apply
procedure {:inline 1} ta_register_timer_read_0.apply(ta_value_r_in:bv32, ta_value_t_in:bv32) returns (ta_value_r_out:bv32, ta_value_t_out:bv32)
{
    var ta_value_r:bv32;
    var ta_value_t:bv32;
    ta_value_r := ta_value_r_in;
    ta_value_t := ta_value_t_in;
    ta_value_t := ta_value_r;
    ta_value_r_out := ta_value_r;
    ta_value_t_out := ta_value_t;
}
procedure ta_reject();
    ensures ta_drop==true;
	modifies ta_drop;
procedure {:inline 1} ta_setInvalid(ta_header:ta_Ref);
    ensures (ta_isValid[ta_header] == false);
	modifies ta_isValid;
procedure {:inline 1} ta_setValid(ta_header:ta_Ref);

// ta_Table ta_table_check_timer_0
procedure {:inline 1} ta_table_check_timer_0.apply()
	modifies ta_eg_dprsr_md.mirror_type, ta_hdr.albion.operation, ta_hdr.albion_timer.state_0, ta_hdr.albion_timer.state_1, ta_hdr.albion_timer.state_2, ta_hdr.albion_timer.state_3, ta_hdr.albion_timer.times, ta_meta.no_use, ta_meta.session_id, ta_p4b_clone_e2e, ta_table_check_timer_0.action_run, ta_table_check_timer_0.hit;
{
    ta_hdr.albion_timer.state_0 := ta_hdr.albion_timer.state_0;
    ta_hdr.albion_timer.state_1 := ta_hdr.albion_timer.state_1;
    ta_hdr.albion_timer.state_2 := ta_hdr.albion_timer.state_2;
    ta_hdr.albion_timer.state_3 := ta_hdr.albion_timer.state_3;
    ta_table_check_timer_0.hit := false;
    if(ta_hdr.albion_timer.state_0 == 0bv32 && ta_hdr.albion_timer.state_1 == 0bv32 && ta_hdr.albion_timer.state_2 == 0bv32 && ta_hdr.albion_timer.state_3 == 0bv32){
        ta_table_check_timer_0.hit := true;
        ta_table_check_timer_0.action_run := ta_table_check_timer_0.action.action_no_action;
        call ta_action_no_action();
        goto ta_Exit;
    }
    if(!ta_table_check_timer_0.hit){
        ta_table_check_timer_0.action_run := ta_table_check_timer_0.action.action_send_to_master_2;
        call ta_action_send_to_master_2();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_register_address_h_record_0_interaction_0
procedure {:inline 1} ta_table_register_address_h_record_0_interaction_0.apply()
	modifies ta___ra_ret_register_address_h_record_0_read_0, ta___ra_ret_register_address_h_record_0_write_0, ta___ra_val_register_address_h_record_0_read_0, ta___ra_val_register_address_h_record_0_write_0, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion_timer.address_high_0, ta_register_address_h_record, ta_register_address_h_record__last0_old_value, ta_register_address_h_record__last0_value, ta_register_address_h_record__last_index, ta_register_address_h_record__last_old_value, ta_register_address_h_record__last_value, ta_register_address_h_record__last_write_site, ta_register_address_h_record__next_write_site, ta_register_address_h_record__wrote_any, ta_register_address_h_record__wrote_index0, ta_table_register_address_h_record_0_interaction_0.action_run, ta_table_register_address_h_record_0_interaction_0.hit;
{
    ta_hdr.albion.operation := ta_hdr.albion.operation;
    ta_hdr.albion.num := ta_hdr.albion.num;
    ta_table_register_address_h_record_0_interaction_0.hit := false;
    if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_address_h_record_0_interaction_0.hit := true;
        ta_table_register_address_h_record_0_interaction_0.action_run := ta_table_register_address_h_record_0_interaction_0.action.action_register_address_h_record_0_write;
        call ta_action_register_address_h_record_0_write();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 100bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_address_h_record_0_interaction_0.hit := true;
        ta_table_register_address_h_record_0_interaction_0.action_run := ta_table_register_address_h_record_0_interaction_0.action.action_register_address_h_record_0_read_timer;
        call ta_action_register_address_h_record_0_read_timer();
        goto ta_Exit;
    }
    if(!ta_table_register_address_h_record_0_interaction_0.hit){
        ta_table_register_address_h_record_0_interaction_0.action_run := ta_table_register_address_h_record_0_interaction_0.action.no_action_6;
        call ta_no_action_6();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_register_address_h_record_1_interaction_0
procedure {:inline 1} ta_table_register_address_h_record_1_interaction_0.apply()
	modifies ta___ra_ret_register_address_h_record_1_read_0, ta___ra_ret_register_address_h_record_1_write_0, ta___ra_val_register_address_h_record_1_read_0, ta___ra_val_register_address_h_record_1_write_0, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion_timer.address_high_1, ta_register_address_h_record_4, ta_register_address_h_record_4__last0_old_value, ta_register_address_h_record_4__last0_value, ta_register_address_h_record_4__last_index, ta_register_address_h_record_4__last_old_value, ta_register_address_h_record_4__last_value, ta_register_address_h_record_4__last_write_site, ta_register_address_h_record_4__next_write_site, ta_register_address_h_record_4__wrote_any, ta_register_address_h_record_4__wrote_index0, ta_table_register_address_h_record_1_interaction_0.action_run, ta_table_register_address_h_record_1_interaction_0.hit;
{
    ta_hdr.albion.operation := ta_hdr.albion.operation;
    ta_hdr.albion.num := ta_hdr.albion.num;
    ta_table_register_address_h_record_1_interaction_0.hit := false;
    if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.num == 1bv32){
        ta_table_register_address_h_record_1_interaction_0.hit := true;
        ta_table_register_address_h_record_1_interaction_0.action_run := ta_table_register_address_h_record_1_interaction_0.action.action_register_address_h_record_1_write;
        call ta_action_register_address_h_record_1_write();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 100bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_address_h_record_1_interaction_0.hit := true;
        ta_table_register_address_h_record_1_interaction_0.action_run := ta_table_register_address_h_record_1_interaction_0.action.action_register_address_h_record_1_read_timer;
        call ta_action_register_address_h_record_1_read_timer();
        goto ta_Exit;
    }
    if(!ta_table_register_address_h_record_1_interaction_0.hit){
        ta_table_register_address_h_record_1_interaction_0.action_run := ta_table_register_address_h_record_1_interaction_0.action.no_action_8;
        call ta_no_action_8();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_register_address_h_record_2_interaction_0
procedure {:inline 1} ta_table_register_address_h_record_2_interaction_0.apply()
	modifies ta___ra_ret_register_address_h_record_2_read_0, ta___ra_ret_register_address_h_record_2_write_0, ta___ra_val_register_address_h_record_2_read_0, ta___ra_val_register_address_h_record_2_write_0, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion_timer.address_high_2, ta_register_address_h_record_5, ta_register_address_h_record_5__last0_old_value, ta_register_address_h_record_5__last0_value, ta_register_address_h_record_5__last_index, ta_register_address_h_record_5__last_old_value, ta_register_address_h_record_5__last_value, ta_register_address_h_record_5__last_write_site, ta_register_address_h_record_5__next_write_site, ta_register_address_h_record_5__wrote_any, ta_register_address_h_record_5__wrote_index0, ta_table_register_address_h_record_2_interaction_0.action_run, ta_table_register_address_h_record_2_interaction_0.hit;
{
    ta_hdr.albion.operation := ta_hdr.albion.operation;
    ta_hdr.albion.num := ta_hdr.albion.num;
    ta_table_register_address_h_record_2_interaction_0.hit := false;
    if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.num == 2bv32){
        ta_table_register_address_h_record_2_interaction_0.hit := true;
        ta_table_register_address_h_record_2_interaction_0.action_run := ta_table_register_address_h_record_2_interaction_0.action.action_register_address_h_record_2_write;
        call ta_action_register_address_h_record_2_write();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 100bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_address_h_record_2_interaction_0.hit := true;
        ta_table_register_address_h_record_2_interaction_0.action_run := ta_table_register_address_h_record_2_interaction_0.action.action_register_address_h_record_2_read_timer;
        call ta_action_register_address_h_record_2_read_timer();
        goto ta_Exit;
    }
    if(!ta_table_register_address_h_record_2_interaction_0.hit){
        ta_table_register_address_h_record_2_interaction_0.action_run := ta_table_register_address_h_record_2_interaction_0.action.no_action_10;
        call ta_no_action_10();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_register_address_h_record_3_interaction_0
procedure {:inline 1} ta_table_register_address_h_record_3_interaction_0.apply()
	modifies ta___ra_ret_register_address_h_record_3_read_0, ta___ra_ret_register_address_h_record_3_write_0, ta___ra_val_register_address_h_record_3_read_0, ta___ra_val_register_address_h_record_3_write_0, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion_timer.address_high_3, ta_register_address_h_record_6, ta_register_address_h_record_6__last0_old_value, ta_register_address_h_record_6__last0_value, ta_register_address_h_record_6__last_index, ta_register_address_h_record_6__last_old_value, ta_register_address_h_record_6__last_value, ta_register_address_h_record_6__last_write_site, ta_register_address_h_record_6__next_write_site, ta_register_address_h_record_6__wrote_any, ta_register_address_h_record_6__wrote_index0, ta_table_register_address_h_record_3_interaction_0.action_run, ta_table_register_address_h_record_3_interaction_0.hit;
{
    ta_hdr.albion.operation := ta_hdr.albion.operation;
    ta_hdr.albion.num := ta_hdr.albion.num;
    ta_table_register_address_h_record_3_interaction_0.hit := false;
    if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.num == 3bv32){
        ta_table_register_address_h_record_3_interaction_0.hit := true;
        ta_table_register_address_h_record_3_interaction_0.action_run := ta_table_register_address_h_record_3_interaction_0.action.action_register_address_h_record_3_write;
        call ta_action_register_address_h_record_3_write();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 100bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_address_h_record_3_interaction_0.hit := true;
        ta_table_register_address_h_record_3_interaction_0.action_run := ta_table_register_address_h_record_3_interaction_0.action.action_register_address_h_record_3_read_timer;
        call ta_action_register_address_h_record_3_read_timer();
        goto ta_Exit;
    }
    if(!ta_table_register_address_h_record_3_interaction_0.hit){
        ta_table_register_address_h_record_3_interaction_0.action_run := ta_table_register_address_h_record_3_interaction_0.action.no_action_12;
        call ta_no_action_12();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_register_address_l_record_0_interaction_0
procedure {:inline 1} ta_table_register_address_l_record_0_interaction_0.apply()
	modifies ta___ra_ret_register_address_l_record_0_read_0, ta___ra_ret_register_address_l_record_0_write_0, ta___ra_val_register_address_l_record_0_read_0, ta___ra_val_register_address_l_record_0_write_0, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion_timer.address_low_0, ta_register_address_l_record, ta_register_address_l_record__last0_old_value, ta_register_address_l_record__last0_value, ta_register_address_l_record__last_index, ta_register_address_l_record__last_old_value, ta_register_address_l_record__last_value, ta_register_address_l_record__last_write_site, ta_register_address_l_record__next_write_site, ta_register_address_l_record__wrote_any, ta_register_address_l_record__wrote_index0, ta_table_register_address_l_record_0_interaction_0.action_run, ta_table_register_address_l_record_0_interaction_0.hit;
{
    ta_hdr.albion.operation := ta_hdr.albion.operation;
    ta_hdr.albion.num := ta_hdr.albion.num;
    ta_table_register_address_l_record_0_interaction_0.hit := false;
    if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_address_l_record_0_interaction_0.hit := true;
        ta_table_register_address_l_record_0_interaction_0.action_run := ta_table_register_address_l_record_0_interaction_0.action.action_register_address_l_record_0_write;
        call ta_action_register_address_l_record_0_write();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 100bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_address_l_record_0_interaction_0.hit := true;
        ta_table_register_address_l_record_0_interaction_0.action_run := ta_table_register_address_l_record_0_interaction_0.action.action_register_address_l_record_0_read_timer;
        call ta_action_register_address_l_record_0_read_timer();
        goto ta_Exit;
    }
    if(!ta_table_register_address_l_record_0_interaction_0.hit){
        ta_table_register_address_l_record_0_interaction_0.action_run := ta_table_register_address_l_record_0_interaction_0.action.no_action_7;
        call ta_no_action_7();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_register_address_l_record_1_interaction_0
procedure {:inline 1} ta_table_register_address_l_record_1_interaction_0.apply()
	modifies ta___ra_ret_register_address_l_record_1_read_0, ta___ra_ret_register_address_l_record_1_write_0, ta___ra_val_register_address_l_record_1_read_0, ta___ra_val_register_address_l_record_1_write_0, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion_timer.address_low_1, ta_register_address_l_record_4, ta_register_address_l_record_4__last0_old_value, ta_register_address_l_record_4__last0_value, ta_register_address_l_record_4__last_index, ta_register_address_l_record_4__last_old_value, ta_register_address_l_record_4__last_value, ta_register_address_l_record_4__last_write_site, ta_register_address_l_record_4__next_write_site, ta_register_address_l_record_4__wrote_any, ta_register_address_l_record_4__wrote_index0, ta_table_register_address_l_record_1_interaction_0.action_run, ta_table_register_address_l_record_1_interaction_0.hit;
{
    ta_hdr.albion.operation := ta_hdr.albion.operation;
    ta_hdr.albion.num := ta_hdr.albion.num;
    ta_table_register_address_l_record_1_interaction_0.hit := false;
    if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.num == 1bv32){
        ta_table_register_address_l_record_1_interaction_0.hit := true;
        ta_table_register_address_l_record_1_interaction_0.action_run := ta_table_register_address_l_record_1_interaction_0.action.action_register_address_l_record_1_write;
        call ta_action_register_address_l_record_1_write();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 100bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_address_l_record_1_interaction_0.hit := true;
        ta_table_register_address_l_record_1_interaction_0.action_run := ta_table_register_address_l_record_1_interaction_0.action.action_register_address_l_record_1_read_timer;
        call ta_action_register_address_l_record_1_read_timer();
        goto ta_Exit;
    }
    if(!ta_table_register_address_l_record_1_interaction_0.hit){
        ta_table_register_address_l_record_1_interaction_0.action_run := ta_table_register_address_l_record_1_interaction_0.action.no_action_9;
        call ta_no_action_9();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_register_address_l_record_2_interaction_0
procedure {:inline 1} ta_table_register_address_l_record_2_interaction_0.apply()
	modifies ta___ra_ret_register_address_l_record_2_read_0, ta___ra_ret_register_address_l_record_2_write_0, ta___ra_val_register_address_l_record_2_read_0, ta___ra_val_register_address_l_record_2_write_0, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion_timer.address_low_2, ta_register_address_l_record_5, ta_register_address_l_record_5__last0_old_value, ta_register_address_l_record_5__last0_value, ta_register_address_l_record_5__last_index, ta_register_address_l_record_5__last_old_value, ta_register_address_l_record_5__last_value, ta_register_address_l_record_5__last_write_site, ta_register_address_l_record_5__next_write_site, ta_register_address_l_record_5__wrote_any, ta_register_address_l_record_5__wrote_index0, ta_table_register_address_l_record_2_interaction_0.action_run, ta_table_register_address_l_record_2_interaction_0.hit;
{
    ta_hdr.albion.operation := ta_hdr.albion.operation;
    ta_hdr.albion.num := ta_hdr.albion.num;
    ta_table_register_address_l_record_2_interaction_0.hit := false;
    if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.num == 2bv32){
        ta_table_register_address_l_record_2_interaction_0.hit := true;
        ta_table_register_address_l_record_2_interaction_0.action_run := ta_table_register_address_l_record_2_interaction_0.action.action_register_address_l_record_2_write;
        call ta_action_register_address_l_record_2_write();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 100bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_address_l_record_2_interaction_0.hit := true;
        ta_table_register_address_l_record_2_interaction_0.action_run := ta_table_register_address_l_record_2_interaction_0.action.action_register_address_l_record_2_read_timer;
        call ta_action_register_address_l_record_2_read_timer();
        goto ta_Exit;
    }
    if(!ta_table_register_address_l_record_2_interaction_0.hit){
        ta_table_register_address_l_record_2_interaction_0.action_run := ta_table_register_address_l_record_2_interaction_0.action.no_action_11;
        call ta_no_action_11();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_register_address_l_record_3_interaction_0
procedure {:inline 1} ta_table_register_address_l_record_3_interaction_0.apply()
	modifies ta___ra_ret_register_address_l_record_3_read_0, ta___ra_ret_register_address_l_record_3_write_0, ta___ra_val_register_address_l_record_3_read_0, ta___ra_val_register_address_l_record_3_write_0, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion_timer.address_low_3, ta_register_address_l_record_6, ta_register_address_l_record_6__last0_old_value, ta_register_address_l_record_6__last0_value, ta_register_address_l_record_6__last_index, ta_register_address_l_record_6__last_old_value, ta_register_address_l_record_6__last_value, ta_register_address_l_record_6__last_write_site, ta_register_address_l_record_6__next_write_site, ta_register_address_l_record_6__wrote_any, ta_register_address_l_record_6__wrote_index0, ta_table_register_address_l_record_3_interaction_0.action_run, ta_table_register_address_l_record_3_interaction_0.hit;
{
    ta_hdr.albion.operation := ta_hdr.albion.operation;
    ta_hdr.albion.num := ta_hdr.albion.num;
    ta_table_register_address_l_record_3_interaction_0.hit := false;
    if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.num == 3bv32){
        ta_table_register_address_l_record_3_interaction_0.hit := true;
        ta_table_register_address_l_record_3_interaction_0.action_run := ta_table_register_address_l_record_3_interaction_0.action.action_register_address_l_record_3_write;
        call ta_action_register_address_l_record_3_write();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 100bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_address_l_record_3_interaction_0.hit := true;
        ta_table_register_address_l_record_3_interaction_0.action_run := ta_table_register_address_l_record_3_interaction_0.action.action_register_address_l_record_3_read_timer;
        call ta_action_register_address_l_record_3_read_timer();
        goto ta_Exit;
    }
    if(!ta_table_register_address_l_record_3_interaction_0.hit){
        ta_table_register_address_l_record_3_interaction_0.action_run := ta_table_register_address_l_record_3_interaction_0.action.no_action_13;
        call ta_no_action_13();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_register_num_interaction_0
procedure {:inline 1} ta_table_register_num_interaction_0.apply()
	modifies ta___ra_ret_register_num_add_0, ta___ra_ret_register_num_zero_0, ta___ra_val_register_num_add_0, ta___ra_val_register_num_zero_0, ta_hdr.albion.num, ta_hdr.albion.operation, ta_register_num_0, ta_register_num_0__last0_old_value, ta_register_num_0__last0_value, ta_register_num_0__last_index, ta_register_num_0__last_old_value, ta_register_num_0__last_value, ta_register_num_0__last_write_site, ta_register_num_0__next_write_site, ta_register_num_0__wrote_any, ta_register_num_0__wrote_index0, ta_table_register_num_interaction_0.action_run, ta_table_register_num_interaction_0.hit;
{
    ta_hdr.albion.operation := ta_hdr.albion.operation;
    ta_table_register_num_interaction_0.hit := false;
    if(ta_hdr.albion.operation == 1bv32){
        ta_table_register_num_interaction_0.hit := true;
        ta_table_register_num_interaction_0.action_run := ta_table_register_num_interaction_0.action.action_register_num_add;
        call ta_action_register_num_add();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 100bv32){
        ta_table_register_num_interaction_0.hit := true;
        ta_table_register_num_interaction_0.action_run := ta_table_register_num_interaction_0.action.action_register_num_zero;
        call ta_action_register_num_zero();
        goto ta_Exit;
    }
    if(!ta_table_register_num_interaction_0.hit){
        ta_table_register_num_interaction_0.action_run := ta_table_register_num_interaction_0.action.action_register_num_add;
        call ta_action_register_num_add();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_register_request_id_high_interaction_0
procedure {:inline 1} ta_table_register_request_id_high_interaction_0.apply()
	modifies ta___ra_ret_register_request_id_high_add_0, ta___ra_val_register_request_id_high_add_0, ta_hdr.albion.request_id_high, ta_hdr.albion.request_id_low, ta_register_request_id_high_0, ta_register_request_id_high_0__last0_old_value, ta_register_request_id_high_0__last0_value, ta_register_request_id_high_0__last_index, ta_register_request_id_high_0__last_old_value, ta_register_request_id_high_0__last_value, ta_register_request_id_high_0__last_write_site, ta_register_request_id_high_0__next_write_site, ta_register_request_id_high_0__wrote_any, ta_register_request_id_high_0__wrote_index0, ta_table_register_request_id_high_interaction_0.action_run, ta_table_register_request_id_high_interaction_0.hit;
{
    ta_hdr.albion.request_id_low := ta_hdr.albion.request_id_low;
    ta_table_register_request_id_high_interaction_0.hit := false;
    if(ta_hdr.albion.request_id_low == 1bv32){
        ta_table_register_request_id_high_interaction_0.hit := true;
        ta_table_register_request_id_high_interaction_0.action_run := ta_table_register_request_id_high_interaction_0.action.action_register_request_id_high_add;
        call ta_action_register_request_id_high_add();
        goto ta_Exit;
    }
    if(!ta_table_register_request_id_high_interaction_0.hit){
        ta_table_register_request_id_high_interaction_0.action_run := ta_table_register_request_id_high_interaction_0.action.no_action_1;
        call ta_no_action_1();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_register_state_0_interaction_0
procedure {:inline 1} ta_table_register_state_0_interaction_0.apply()
	modifies ta___ra_ret_register_state_0_r_0, ta___ra_ret_register_state_0_sub_0, ta___ra_ret_register_state_0_w_0, ta___ra_val_register_state_0_r_0, ta___ra_val_register_state_0_sub_0, ta___ra_val_register_state_0_w_0, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion_timer.state_0, ta_meta.state, ta_register_state, ta_register_state__last0_old_value, ta_register_state__last0_value, ta_register_state__last_index, ta_register_state__last_old_value, ta_register_state__last_value, ta_register_state__last_write_site, ta_register_state__next_write_site, ta_register_state__wrote_any, ta_register_state__wrote_index0, ta_table_register_state_0_interaction_0.action_run, ta_table_register_state_0_interaction_0.hit;
{
    ta_hdr.albion.operation := ta_hdr.albion.operation;
    ta_hdr.albion.num := ta_hdr.albion.num;
    ta_table_register_state_0_interaction_0.hit := false;
    if(ta_hdr.albion.operation == 1bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_state_0_interaction_0.hit := true;
        ta_table_register_state_0_interaction_0.action_run := ta_table_register_state_0_interaction_0.action.action_register_state_0_r;
        call ta_action_register_state_0_r();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_state_0_interaction_0.hit := true;
        ta_table_register_state_0_interaction_0.action_run := ta_table_register_state_0_interaction_0.action.action_register_state_0_w;
        call ta_action_register_state_0_w();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 33bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_state_0_interaction_0.hit := true;
        ta_table_register_state_0_interaction_0.action_run := ta_table_register_state_0_interaction_0.action.action_register_state_0_sub;
        call ta_action_register_state_0_sub();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 100bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_state_0_interaction_0.hit := true;
        ta_table_register_state_0_interaction_0.action_run := ta_table_register_state_0_interaction_0.action.action_register_state_0_r_timer;
        call ta_action_register_state_0_r_timer();
        goto ta_Exit;
    }
    if(!ta_table_register_state_0_interaction_0.hit){
        ta_table_register_state_0_interaction_0.action_run := ta_table_register_state_0_interaction_0.action.no_action_2;
        call ta_no_action_2();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_register_state_1_interaction_0
procedure {:inline 1} ta_table_register_state_1_interaction_0.apply()
	modifies ta___ra_ret_register_state_1_r_0, ta___ra_ret_register_state_1_sub_0, ta___ra_ret_register_state_1_w_0, ta___ra_val_register_state_1_r_0, ta___ra_val_register_state_1_sub_0, ta___ra_val_register_state_1_w_0, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion_timer.state_1, ta_meta.state, ta_register_state_4, ta_register_state_4__last0_old_value, ta_register_state_4__last0_value, ta_register_state_4__last_index, ta_register_state_4__last_old_value, ta_register_state_4__last_value, ta_register_state_4__last_write_site, ta_register_state_4__next_write_site, ta_register_state_4__wrote_any, ta_register_state_4__wrote_index0, ta_table_register_state_1_interaction_0.action_run, ta_table_register_state_1_interaction_0.hit;
{
    ta_hdr.albion.operation := ta_hdr.albion.operation;
    ta_hdr.albion.num := ta_hdr.albion.num;
    ta_table_register_state_1_interaction_0.hit := false;
    if(ta_hdr.albion.operation == 1bv32 && ta_hdr.albion.num == 1bv32){
        ta_table_register_state_1_interaction_0.hit := true;
        ta_table_register_state_1_interaction_0.action_run := ta_table_register_state_1_interaction_0.action.action_register_state_1_r;
        call ta_action_register_state_1_r();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.num == 1bv32){
        ta_table_register_state_1_interaction_0.hit := true;
        ta_table_register_state_1_interaction_0.action_run := ta_table_register_state_1_interaction_0.action.action_register_state_1_w;
        call ta_action_register_state_1_w();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 33bv32 && ta_hdr.albion.num == 1bv32){
        ta_table_register_state_1_interaction_0.hit := true;
        ta_table_register_state_1_interaction_0.action_run := ta_table_register_state_1_interaction_0.action.action_register_state_1_sub;
        call ta_action_register_state_1_sub();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 100bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_state_1_interaction_0.hit := true;
        ta_table_register_state_1_interaction_0.action_run := ta_table_register_state_1_interaction_0.action.action_register_state_1_r_timer;
        call ta_action_register_state_1_r_timer();
        goto ta_Exit;
    }
    if(!ta_table_register_state_1_interaction_0.hit){
        ta_table_register_state_1_interaction_0.action_run := ta_table_register_state_1_interaction_0.action.no_action_3;
        call ta_no_action_3();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_register_state_2_interaction_0
procedure {:inline 1} ta_table_register_state_2_interaction_0.apply()
	modifies ta___ra_ret_register_state_2_r_0, ta___ra_ret_register_state_2_sub_0, ta___ra_ret_register_state_2_w_0, ta___ra_val_register_state_2_r_0, ta___ra_val_register_state_2_sub_0, ta___ra_val_register_state_2_w_0, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion_timer.state_2, ta_meta.state, ta_register_state_5, ta_register_state_5__last0_old_value, ta_register_state_5__last0_value, ta_register_state_5__last_index, ta_register_state_5__last_old_value, ta_register_state_5__last_value, ta_register_state_5__last_write_site, ta_register_state_5__next_write_site, ta_register_state_5__wrote_any, ta_register_state_5__wrote_index0, ta_table_register_state_2_interaction_0.action_run, ta_table_register_state_2_interaction_0.hit;
{
    ta_hdr.albion.operation := ta_hdr.albion.operation;
    ta_hdr.albion.num := ta_hdr.albion.num;
    ta_table_register_state_2_interaction_0.hit := false;
    if(ta_hdr.albion.operation == 1bv32 && ta_hdr.albion.num == 2bv32){
        ta_table_register_state_2_interaction_0.hit := true;
        ta_table_register_state_2_interaction_0.action_run := ta_table_register_state_2_interaction_0.action.action_register_state_2_r;
        call ta_action_register_state_2_r();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.num == 2bv32){
        ta_table_register_state_2_interaction_0.hit := true;
        ta_table_register_state_2_interaction_0.action_run := ta_table_register_state_2_interaction_0.action.action_register_state_2_w;
        call ta_action_register_state_2_w();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 33bv32 && ta_hdr.albion.num == 2bv32){
        ta_table_register_state_2_interaction_0.hit := true;
        ta_table_register_state_2_interaction_0.action_run := ta_table_register_state_2_interaction_0.action.action_register_state_2_sub;
        call ta_action_register_state_2_sub();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 100bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_state_2_interaction_0.hit := true;
        ta_table_register_state_2_interaction_0.action_run := ta_table_register_state_2_interaction_0.action.action_register_state_2_r_timer;
        call ta_action_register_state_2_r_timer();
        goto ta_Exit;
    }
    if(!ta_table_register_state_2_interaction_0.hit){
        ta_table_register_state_2_interaction_0.action_run := ta_table_register_state_2_interaction_0.action.no_action_4;
        call ta_no_action_4();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_register_state_3_interaction_0
procedure {:inline 1} ta_table_register_state_3_interaction_0.apply()
	modifies ta___ra_ret_register_state_3_r_0, ta___ra_ret_register_state_3_sub_0, ta___ra_ret_register_state_3_w_0, ta___ra_val_register_state_3_r_0, ta___ra_val_register_state_3_sub_0, ta___ra_val_register_state_3_w_0, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion_timer.state_3, ta_meta.state, ta_register_state_6, ta_register_state_6__last0_old_value, ta_register_state_6__last0_value, ta_register_state_6__last_index, ta_register_state_6__last_old_value, ta_register_state_6__last_value, ta_register_state_6__last_write_site, ta_register_state_6__next_write_site, ta_register_state_6__wrote_any, ta_register_state_6__wrote_index0, ta_table_register_state_3_interaction_0.action_run, ta_table_register_state_3_interaction_0.hit;
{
    ta_hdr.albion.operation := ta_hdr.albion.operation;
    ta_hdr.albion.num := ta_hdr.albion.num;
    ta_table_register_state_3_interaction_0.hit := false;
    if(ta_hdr.albion.operation == 1bv32 && ta_hdr.albion.num == 3bv32){
        ta_table_register_state_3_interaction_0.hit := true;
        ta_table_register_state_3_interaction_0.action_run := ta_table_register_state_3_interaction_0.action.action_register_state_3_r;
        call ta_action_register_state_3_r();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.num == 3bv32){
        ta_table_register_state_3_interaction_0.hit := true;
        ta_table_register_state_3_interaction_0.action_run := ta_table_register_state_3_interaction_0.action.action_register_state_3_w;
        call ta_action_register_state_3_w();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 33bv32 && ta_hdr.albion.num == 3bv32){
        ta_table_register_state_3_interaction_0.hit := true;
        ta_table_register_state_3_interaction_0.action_run := ta_table_register_state_3_interaction_0.action.action_register_state_3_sub;
        call ta_action_register_state_3_sub();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 100bv32 && ta_hdr.albion.num == 0bv32){
        ta_table_register_state_3_interaction_0.hit := true;
        ta_table_register_state_3_interaction_0.action_run := ta_table_register_state_3_interaction_0.action.action_register_state_3_r_timer;
        call ta_action_register_state_3_r_timer();
        goto ta_Exit;
    }
    if(!ta_table_register_state_3_interaction_0.hit){
        ta_table_register_state_3_interaction_0.action_run := ta_table_register_state_3_interaction_0.action.no_action_5;
        call ta_no_action_5();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_register_timer_interaction_0
procedure {:inline 1} ta_table_register_timer_interaction_0.apply()
	modifies ta___ra_ret_register_timer_add_0, ta___ra_ret_register_timer_read_0, ta___ra_val_register_timer_add_0, ta___ra_val_register_timer_read_0, ta_hdr.albion.operation, ta_hdr.albion.time, ta_register_timer_0, ta_register_timer_0__last0_old_value, ta_register_timer_0__last0_value, ta_register_timer_0__last_index, ta_register_timer_0__last_old_value, ta_register_timer_0__last_value, ta_register_timer_0__last_write_site, ta_register_timer_0__next_write_site, ta_register_timer_0__wrote_any, ta_register_timer_0__wrote_index0, ta_table_register_timer_interaction_0.action_run, ta_table_register_timer_interaction_0.hit;
{
    ta_hdr.albion.operation := ta_hdr.albion.operation;
    ta_table_register_timer_interaction_0.hit := false;
    if(ta_hdr.albion.operation == 100bv32){
        ta_table_register_timer_interaction_0.hit := true;
        ta_table_register_timer_interaction_0.action_run := ta_table_register_timer_interaction_0.action.action_register_timer_add;
        call ta_action_register_timer_add();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 1bv32){
        ta_table_register_timer_interaction_0.hit := true;
        ta_table_register_timer_interaction_0.action_run := ta_table_register_timer_interaction_0.action.action_register_timer_read;
        call ta_action_register_timer_read();
        goto ta_Exit;
    }
    if(!ta_table_register_timer_interaction_0.hit){
        ta_table_register_timer_interaction_0.action_run := ta_table_register_timer_interaction_0.action.no_action;
        call ta_no_action();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_send_to_somewhere_0
procedure {:inline 1} ta_table_send_to_somewhere_0.apply()
	modifies ta_hdr.albion.CS_id_1, ta_hdr.albion.operation, ta_hdr.albion.port, ta_ig_tm_md.ucast_egress_port, ta_table_send_to_somewhere_0.action_run, ta_table_send_to_somewhere_0.hit;
{
    ta_hdr.albion.operation := ta_hdr.albion.operation;
    ta_hdr.albion.CS_id_1 := ta_hdr.albion.CS_id_1;
    ta_table_send_to_somewhere_0.hit := false;
    if(ta_hdr.albion.operation == 1bv32 && ta_hdr.albion.CS_id_1 == 0bv32){
        ta_table_send_to_somewhere_0.hit := true;
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.action_send_to_master;
        call ta_action_send_to_master();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 20bv32 && ta_hdr.albion.CS_id_1 == 0bv32){
        ta_table_send_to_somewhere_0.hit := true;
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.action_send_to_client;
        call ta_action_send_to_client();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 34bv32 && ta_hdr.albion.CS_id_1 == 0bv32){
        ta_table_send_to_somewhere_0.hit := true;
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.action_send_to_client;
        call ta_action_send_to_client();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 35bv32 && ta_hdr.albion.CS_id_1 == 0bv32){
        ta_table_send_to_somewhere_0.hit := true;
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.action_send_to_client;
        call ta_action_send_to_client();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 200bv32 && ta_hdr.albion.CS_id_1 == 0bv32){
        ta_table_send_to_somewhere_0.hit := true;
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.action_send_to_master;
        call ta_action_send_to_master();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 100bv32 && ta_hdr.albion.CS_id_1 == 0bv32){
        ta_table_send_to_somewhere_0.hit := true;
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.action_send_to_self;
        call ta_action_send_to_self();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 101bv32 && ta_hdr.albion.CS_id_1 == 0bv32){
        ta_table_send_to_somewhere_0.hit := true;
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.action_send_to_self;
        call ta_action_send_to_self();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.CS_id_1 == 1bv32){
        ta_table_send_to_somewhere_0.hit := true;
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.action_send_to_CS;
        call ta_action_send_to_CS();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.CS_id_1 == 2bv32){
        ta_table_send_to_somewhere_0.hit := true;
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.action_send_to_CS_1;
        call ta_action_send_to_CS_1();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.CS_id_1 == 3bv32){
        ta_table_send_to_somewhere_0.hit := true;
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.action_send_to_CS_2;
        call ta_action_send_to_CS_2();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 2bv32 && ta_hdr.albion.CS_id_1 == 4bv32){
        ta_table_send_to_somewhere_0.hit := true;
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.action_send_to_CS_3;
        call ta_action_send_to_CS_3();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 70bv32 && ta_hdr.albion.CS_id_1 == 1bv32){
        ta_table_send_to_somewhere_0.hit := true;
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.action_send_to_CS;
        call ta_action_send_to_CS();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 70bv32 && ta_hdr.albion.CS_id_1 == 2bv32){
        ta_table_send_to_somewhere_0.hit := true;
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.action_send_to_CS_1;
        call ta_action_send_to_CS_1();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 70bv32 && ta_hdr.albion.CS_id_1 == 3bv32){
        ta_table_send_to_somewhere_0.hit := true;
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.action_send_to_CS_2;
        call ta_action_send_to_CS_2();
        goto ta_Exit;
    }
    else if(ta_hdr.albion.operation == 70bv32 && ta_hdr.albion.CS_id_1 == 4bv32){
        ta_table_send_to_somewhere_0.hit := true;
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.action_send_to_CS_3;
        call ta_action_send_to_CS_3();
        goto ta_Exit;
    }
    if(!ta_table_send_to_somewhere_0.hit){
        ta_table_send_to_somewhere_0.action_run := ta_table_send_to_somewhere_0.action.no_action_14;
        call ta_no_action_14();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_state_check_0
procedure {:inline 1} ta_table_state_check_0.apply()
	modifies ta_hdr.albion.operation, ta_meta.state, ta_table_state_check_0.action_run, ta_table_state_check_0.hit;
{
    ta_meta.state := ta_meta.state;
    ta_table_state_check_0.hit := false;
    if(ta_meta.state == 0bv32){
        ta_table_state_check_0.hit := true;
        ta_table_state_check_0.action_run := ta_table_state_check_0.action.no_action_15;
        call ta_no_action_15();
        goto ta_Exit;
    }
    if(!ta_table_state_check_0.hit){
        ta_table_state_check_0.action_run := ta_table_state_check_0.action.action_state_failed;
        call ta_action_state_failed();
        goto ta_Exit;
    }

    ta_Exit:
}

// ta_Table ta_table_success_check_0
procedure {:inline 1} ta_table_success_check_0.apply()
	modifies ta_hdr.albion.operation, ta_meta.state, ta_table_success_check_0.action_run, ta_table_success_check_0.hit;
{
    ta_meta.state := ta_meta.state;
    ta_table_success_check_0.hit := false;
    if(ta_meta.state == 1bv32){
        ta_table_success_check_0.hit := true;
        ta_table_success_check_0.action_run := ta_table_success_check_0.action.action_op_change_to_1;
        call ta_action_op_change_to_1();
        goto ta_Exit;
    }
    else if(ta_meta.state == 2bv32){
        ta_table_success_check_0.hit := true;
        ta_table_success_check_0.action_run := ta_table_success_check_0.action.action_op_change_to_1;
        call ta_action_op_change_to_1();
        goto ta_Exit;
    }
    else if(ta_meta.state == 4bv32){
        ta_table_success_check_0.hit := true;
        ta_table_success_check_0.action_run := ta_table_success_check_0.action.action_op_change_to_1;
        call ta_action_op_change_to_1();
        goto ta_Exit;
    }
    else if(ta_meta.state == 0bv32){
        ta_table_success_check_0.hit := true;
        ta_table_success_check_0.action_run := ta_table_success_check_0.action.action_op_change_to_2;
        call ta_action_op_change_to_2();
        goto ta_Exit;
    }
    if(!ta_table_success_check_0.hit){
        ta_table_success_check_0.action_run := ta_table_success_check_0.action.no_action_16;
        call ta_no_action_16();
        goto ta_Exit;
    }

    ta_Exit:
}
// ===== END NODE ta =====

// ===== BEGIN NODE tb (prefixed) =====
type tb_Ref;
type tb_error=bv1;
type tb_HeaderStack = [int]tb_Ref;
var tb_last:[tb_HeaderStack]tb_Ref;
var tb_forward:bool;
var tb_isValid:[tb_Ref]bool;
var tb_emit:[tb_Ref]bool;
var tb_stack.index:[tb_HeaderStack]int;
var tb_size:[tb_HeaderStack]int;
var tb_drop:bool;
var tb_p4b_clone_i2e:bool;
var tb_p4b_clone_e2e:bool;
var tb_p4b_clone_i2i:bool;
var tb_p4b_recirculate:bool;
var tb_p4b_digest:bool;
var tb_p4b_checksum_verified:bool;
var tb_p4b_checksum_updated:bool;
var tb_p4b_checksum_error:bool;
type tb_PortId_t = bv9;
type tb_MulticastGroupId_t = bv16;
type tb_QueueId_t = bv5;
type tb_MirrorType_t = bv3;
type tb_MirrorId_t = bv10;
type tb_ResubmitType_t = bv3;
type tb_DigestType_t = bv3;
type tb_L1ExclusionId_t = bv16;
type tb_L2ExclusionId_t = bv9;
type tb_MeterType_t = int;
type tb_MeterColor_t = bv8;
type tb_CounterType_t = int;
type tb_SelectorMode_t = int;
type tb_HashAlgorithm_t = int;
type tb_ingress_intrinsic_metadata_t;

// tb_Struct tb_ingress_intrinsic_metadata_for_tm_t
type tb_ingress_intrinsic_metadata_for_tm_t;

// tb_Struct tb_ingress_intrinsic_metadata_from_parser_t
type tb_ingress_intrinsic_metadata_from_parser_t;

// tb_Struct tb_ingress_intrinsic_metadata_for_deparser_t
type tb_ingress_intrinsic_metadata_for_deparser_t;
type tb_egress_intrinsic_metadata_t;

// tb_Struct tb_egress_intrinsic_metadata_from_parser_t
type tb_egress_intrinsic_metadata_from_parser_t;

// tb_Struct tb_egress_intrinsic_metadata_for_deparser_t
type tb_egress_intrinsic_metadata_for_deparser_t;

// tb_Struct tb_egress_intrinsic_metadata_for_output_port_t
type tb_egress_intrinsic_metadata_for_output_port_t;
type tb_pktgen_timer_header_t;
type tb_pktgen_port_down_header_t;
type tb_pktgen_recirc_header_t;
type tb_ptp_metadata_t;
type tb_MathOp_t = int;
type tb_ethernet_t;
type tb_mirror_h;
type tb_albion_t;
type tb_albion_data_t;
type tb_albion_timer_t;

// tb_Struct tb_headers
var tb_hdr:tb_Ref;

// tb_Header tb_mirror_h
var tb_hdr.mirror_1:tb_Ref;
var tb_hdr.mirror_1.valid:bool;
var tb_hdr.mirror_1.pkt_type:bv8;

// tb_Header tb_mirror_h
var tb_hdr.mirror_2:tb_Ref;
var tb_hdr.mirror_2.valid:bool;
var tb_hdr.mirror_2.pkt_type:bv8;

// tb_Header tb_ethernet_t
var tb_hdr.ethernet:tb_Ref;
var tb_hdr.ethernet.valid:bool;
var tb_hdr.ethernet.dst_addr:bv48;
var tb_hdr.ethernet.src_addr:bv48;
var tb_hdr.ethernet.ether_type:bv16;

// tb_Header tb_albion_t
var tb_hdr.albion:tb_Ref;
var tb_hdr.albion.valid:bool;
var tb_hdr.albion.request_id_high:bv32;
var tb_hdr.albion.request_id_low:bv32;
var tb_hdr.albion.operation:bv32;
var tb_hdr.albion.address_h:bv32;
var tb_hdr.albion.address_l:bv32;
var tb_hdr.albion.time:bv32;
var tb_hdr.albion.num:bv32;
var tb_hdr.albion.index:bv32;
var tb_hdr.albion.CS_id_1:bv32;
var tb_hdr.albion.CS_offset_1:bv32;
var tb_hdr.albion.CS_id_2:bv32;
var tb_hdr.albion.CS_offset_2:bv32;
var tb_hdr.albion.CS_id_3:bv32;
var tb_hdr.albion.CS_offset_3:bv32;
var tb_hdr.albion.port:bv16;

// tb_Header tb_albion_data_t
var tb_hdr.albion_data:tb_Ref;
var tb_hdr.albion_data.valid:bool;
var tb_hdr.albion_data.data_0:bv32;
var tb_hdr.albion_data.data_1:bv32;
var tb_hdr.albion_data.data_2:bv32;
var tb_hdr.albion_data.data_3:bv32;
var tb_hdr.albion_data.data_4:bv32;
var tb_hdr.albion_data.data_5:bv32;
var tb_hdr.albion_data.data_6:bv32;
var tb_hdr.albion_data.data_7:bv32;
var tb_hdr.albion_data.data_8:bv32;
var tb_hdr.albion_data.data_9:bv32;
var tb_hdr.albion_data.data_10:bv32;
var tb_hdr.albion_data.data_11:bv32;

// tb_Header tb_albion_timer_t
var tb_hdr.albion_timer:tb_Ref;
var tb_hdr.albion_timer.valid:bool;
var tb_hdr.albion_timer.times:bv32;
var tb_hdr.albion_timer.const_time:bv32;
var tb_hdr.albion_timer.now:bv32;
var tb_hdr.albion_timer.address_high_0:bv32;
var tb_hdr.albion_timer.address_low_0:bv32;
var tb_hdr.albion_timer.state_0:bv32;
var tb_hdr.albion_timer.address_high_1:bv32;
var tb_hdr.albion_timer.address_low_1:bv32;
var tb_hdr.albion_timer.state_1:bv32;
var tb_hdr.albion_timer.address_high_2:bv32;
var tb_hdr.albion_timer.address_low_2:bv32;
var tb_hdr.albion_timer.state_2:bv32;
var tb_hdr.albion_timer.address_high_3:bv32;
var tb_hdr.albion_timer.address_low_3:bv32;
var tb_hdr.albion_timer.state_3:bv32;

// tb_Struct tb_my_ingress_metadata_t
type tb_my_ingress_metadata_t;

// tb_Struct tb_my_egress_metadata_t
type tb_my_egress_metadata_t;
var tb_meta:tb_my_ingress_metadata_t;
var tb_meta.time_1:bv32;
var tb_meta.time_2:bv32;
var tb_meta.state:bv32;
var tb_meta.state_sub:bv32;
var tb_meta.no_use_1:bv8;
var tb_meta.no_use_2:bv8;

// tb_Header tb_ingress_intrinsic_metadata_t
var tb_ig_intr_md:tb_Ref;
var tb_ig_intr_md.valid:bool;
var tb_ig_intr_md.resubmit_flag:bv1;
var tb_ig_intr_md._pad1:bv1;
var tb_ig_intr_md.packet_version:bv2;
var tb_ig_intr_md._pad2:bv3;
var tb_ig_intr_md.ingress_port:tb_PortId_t;
var tb_ig_intr_md.ingress_mac_tstamp:bv48;
var tb_pkt:tb_Ref;
var tb_ig_prsr_md:tb_ingress_intrinsic_metadata_from_parser_t;
var tb_ig_prsr_md.global_tstamp:bv48;
var tb_ig_prsr_md.global_ver:bv32;
var tb_ig_prsr_md.parser_err:bv16;
var tb_ig_dprsr_md:tb_ingress_intrinsic_metadata_for_deparser_t;
var tb_ig_dprsr_md.drop_ctl:bv3;
var tb_ig_dprsr_md.digest_type:tb_DigestType_t;
var tb_ig_dprsr_md.resubmit_type:tb_ResubmitType_t;
var tb_ig_dprsr_md.mirror_type:tb_MirrorType_t;
var tb_ig_tm_md:tb_ingress_intrinsic_metadata_for_tm_t;
var tb_ig_tm_md.ucast_egress_port:tb_PortId_t;
var tb_ig_tm_md.bypass_egress:bv1;
var tb_ig_tm_md.deflect_on_drop:bv1;
var tb_ig_tm_md.ingress_cos:bv3;
var tb_ig_tm_md.qid:tb_QueueId_t;
var tb_ig_tm_md.icos_for_copy_to_cpu:bv3;
var tb_ig_tm_md.copy_to_cpu:bv1;
var tb_ig_tm_md.packet_color:bv2;
var tb_ig_tm_md.disable_ucast_cutthru:bv1;
var tb_ig_tm_md.enable_mcast_cutthru:bv1;
var tb_ig_tm_md.mcast_grp_a:tb_MulticastGroupId_t;
var tb_ig_tm_md.mcast_grp_b:tb_MulticastGroupId_t;
var tb_ig_tm_md.level1_mcast_hash:bv13;
var tb_ig_tm_md.level2_mcast_hash:bv13;
var tb_ig_tm_md.level1_exclusion_id:tb_L1ExclusionId_t;
var tb_ig_tm_md.level2_exclusion_id:tb_L2ExclusionId_t;
var tb_ig_tm_md.rid:bv16;
var tb_meta.session_id:tb_MirrorId_t;
var tb_meta.no_use:bv8;
var tb_meta.id_1:bv32;
var tb_meta.offset_1:bv32;
var tb_meta.id_2:bv32;
var tb_meta.offset_2:bv32;
var tb_meta.id_3:bv32;
var tb_meta.offset_3:bv32;

// tb_Header tb_egress_intrinsic_metadata_t
var tb_eg_intr_md:tb_Ref;
var tb_eg_intr_md.valid:bool;
var tb_eg_intr_md._pad0:bv7;
var tb_eg_intr_md.egress_port:tb_PortId_t;
var tb_eg_intr_md._pad1:bv5;
var tb_eg_intr_md.enq_qdepth:bv19;
var tb_eg_intr_md._pad2:bv6;
var tb_eg_intr_md.enq_congest_stat:bv2;
var tb_eg_intr_md._pad3:bv14;
var tb_eg_intr_md.enq_tstamp:bv18;
var tb_eg_intr_md._pad4:bv5;
var tb_eg_intr_md.deq_qdepth:bv19;
var tb_eg_intr_md._pad5:bv6;
var tb_eg_intr_md.deq_congest_stat:bv2;
var tb_eg_intr_md.app_pool_congest_stat:bv8;
var tb_eg_intr_md._pad6:bv14;
var tb_eg_intr_md.deq_timedelta:bv18;
var tb_eg_intr_md.egress_rid:bv16;
var tb_eg_intr_md._pad7:bv7;
var tb_eg_intr_md.egress_rid_first:bv1;
var tb_eg_intr_md._pad8:bv3;
var tb_eg_intr_md.egress_qid:tb_QueueId_t;
var tb_eg_intr_md._pad9:bv5;
var tb_eg_intr_md.egress_cos:bv3;
var tb_eg_intr_md._pad10:bv7;
var tb_eg_intr_md.deflection_flag:bv1;
var tb_eg_intr_md.pkt_length:bv16;

// tb_Header tb_mirror_h
var tb_mirror_md_0:tb_Ref;
var tb_mirror_md_0.valid:bool;
var tb_mirror_md_0.pkt_type:bv8;

// tb_Header tb_mirror_h
var tb_mirror_md_1:tb_Ref;
var tb_mirror_md_1.valid:bool;
var tb_mirror_md_1.pkt_type:bv8;

// tb_Header tb_mirror_h
var tb_mirror_md_2:tb_Ref;
var tb_mirror_md_2.valid:bool;
var tb_mirror_md_2.pkt_type:bv8;
var tb_eg_prsr_md:tb_egress_intrinsic_metadata_from_parser_t;
var tb_eg_prsr_md.global_tstamp:bv48;
var tb_eg_prsr_md.global_ver:bv32;
var tb_eg_prsr_md.parser_err:bv16;
var tb_eg_dprsr_md:tb_egress_intrinsic_metadata_for_deparser_t;
var tb_eg_dprsr_md.drop_ctl:bv3;
var tb_eg_dprsr_md.mirror_type:tb_MirrorType_t;
var tb_eg_dprsr_md.coalesce_flush:bv1;
var tb_eg_dprsr_md.coalesce_length:bv7;
var tb_eg_oport_md:tb_egress_intrinsic_metadata_for_output_port_t;
var tb_eg_oport_md.capture_tstamp_on_tx:bv1;
var tb_eg_oport_md.update_delay_on_tx:bv1;

// tb_Register tb_register_data_record
var tb_register_data_record:[bv32]bv32;
var tb_register_data_record__last_index:bv32;
var tb_register_data_record__last_value:bv32;
var tb_register_data_record__last_old_value:bv32;
var tb_register_data_record__wrote_any:bool;
var tb_register_data_record__wrote_index0:bool;
var tb_register_data_record__last0_old_value:bv32;
var tb_register_data_record__last0_value:bv32;
var tb_register_data_record__next_write_site:int;
var tb_register_data_record__last_write_site:int;
const tb_register_data_record.size:bv32;
axiom tb_register_data_record.size == 140500bv32;

// tb_Register tb_register_data_record_12
var tb_register_data_record_12:[bv32]bv32;
var tb_register_data_record_12__last_index:bv32;
var tb_register_data_record_12__last_value:bv32;
var tb_register_data_record_12__last_old_value:bv32;
var tb_register_data_record_12__wrote_any:bool;
var tb_register_data_record_12__wrote_index0:bool;
var tb_register_data_record_12__last0_old_value:bv32;
var tb_register_data_record_12__last0_value:bv32;
var tb_register_data_record_12__next_write_site:int;
var tb_register_data_record_12__last_write_site:int;
const tb_register_data_record_12.size:bv32;
axiom tb_register_data_record_12.size == 140500bv32;

// tb_Register tb_register_data_record_13
var tb_register_data_record_13:[bv32]bv32;
var tb_register_data_record_13__last_index:bv32;
var tb_register_data_record_13__last_value:bv32;
var tb_register_data_record_13__last_old_value:bv32;
var tb_register_data_record_13__wrote_any:bool;
var tb_register_data_record_13__wrote_index0:bool;
var tb_register_data_record_13__last0_old_value:bv32;
var tb_register_data_record_13__last0_value:bv32;
var tb_register_data_record_13__next_write_site:int;
var tb_register_data_record_13__last_write_site:int;
const tb_register_data_record_13.size:bv32;
axiom tb_register_data_record_13.size == 140500bv32;

// tb_Register tb_register_data_record_14
var tb_register_data_record_14:[bv32]bv32;
var tb_register_data_record_14__last_index:bv32;
var tb_register_data_record_14__last_value:bv32;
var tb_register_data_record_14__last_old_value:bv32;
var tb_register_data_record_14__wrote_any:bool;
var tb_register_data_record_14__wrote_index0:bool;
var tb_register_data_record_14__last0_old_value:bv32;
var tb_register_data_record_14__last0_value:bv32;
var tb_register_data_record_14__next_write_site:int;
var tb_register_data_record_14__last_write_site:int;
const tb_register_data_record_14.size:bv32;
axiom tb_register_data_record_14.size == 140500bv32;

// tb_Register tb_register_data_record_15
var tb_register_data_record_15:[bv32]bv32;
var tb_register_data_record_15__last_index:bv32;
var tb_register_data_record_15__last_value:bv32;
var tb_register_data_record_15__last_old_value:bv32;
var tb_register_data_record_15__wrote_any:bool;
var tb_register_data_record_15__wrote_index0:bool;
var tb_register_data_record_15__last0_old_value:bv32;
var tb_register_data_record_15__last0_value:bv32;
var tb_register_data_record_15__next_write_site:int;
var tb_register_data_record_15__last_write_site:int;
const tb_register_data_record_15.size:bv32;
axiom tb_register_data_record_15.size == 140500bv32;

// tb_Register tb_register_data_record_16
var tb_register_data_record_16:[bv32]bv32;
var tb_register_data_record_16__last_index:bv32;
var tb_register_data_record_16__last_value:bv32;
var tb_register_data_record_16__last_old_value:bv32;
var tb_register_data_record_16__wrote_any:bool;
var tb_register_data_record_16__wrote_index0:bool;
var tb_register_data_record_16__last0_old_value:bv32;
var tb_register_data_record_16__last0_value:bv32;
var tb_register_data_record_16__next_write_site:int;
var tb_register_data_record_16__last_write_site:int;
const tb_register_data_record_16.size:bv32;
axiom tb_register_data_record_16.size == 140500bv32;

// tb_Register tb_register_data_record_17
var tb_register_data_record_17:[bv32]bv32;
var tb_register_data_record_17__last_index:bv32;
var tb_register_data_record_17__last_value:bv32;
var tb_register_data_record_17__last_old_value:bv32;
var tb_register_data_record_17__wrote_any:bool;
var tb_register_data_record_17__wrote_index0:bool;
var tb_register_data_record_17__last0_old_value:bv32;
var tb_register_data_record_17__last0_value:bv32;
var tb_register_data_record_17__next_write_site:int;
var tb_register_data_record_17__last_write_site:int;
const tb_register_data_record_17.size:bv32;
axiom tb_register_data_record_17.size == 140500bv32;

// tb_Register tb_register_data_record_18
var tb_register_data_record_18:[bv32]bv32;
var tb_register_data_record_18__last_index:bv32;
var tb_register_data_record_18__last_value:bv32;
var tb_register_data_record_18__last_old_value:bv32;
var tb_register_data_record_18__wrote_any:bool;
var tb_register_data_record_18__wrote_index0:bool;
var tb_register_data_record_18__last0_old_value:bv32;
var tb_register_data_record_18__last0_value:bv32;
var tb_register_data_record_18__next_write_site:int;
var tb_register_data_record_18__last_write_site:int;
const tb_register_data_record_18.size:bv32;
axiom tb_register_data_record_18.size == 140500bv32;

// tb_Register tb_register_data_record_19
var tb_register_data_record_19:[bv32]bv32;
var tb_register_data_record_19__last_index:bv32;
var tb_register_data_record_19__last_value:bv32;
var tb_register_data_record_19__last_old_value:bv32;
var tb_register_data_record_19__wrote_any:bool;
var tb_register_data_record_19__wrote_index0:bool;
var tb_register_data_record_19__last0_old_value:bv32;
var tb_register_data_record_19__last0_value:bv32;
var tb_register_data_record_19__next_write_site:int;
var tb_register_data_record_19__last_write_site:int;
const tb_register_data_record_19.size:bv32;
axiom tb_register_data_record_19.size == 140500bv32;

// tb_Register tb_register_data_record_20
var tb_register_data_record_20:[bv32]bv32;
var tb_register_data_record_20__last_index:bv32;
var tb_register_data_record_20__last_value:bv32;
var tb_register_data_record_20__last_old_value:bv32;
var tb_register_data_record_20__wrote_any:bool;
var tb_register_data_record_20__wrote_index0:bool;
var tb_register_data_record_20__last0_old_value:bv32;
var tb_register_data_record_20__last0_value:bv32;
var tb_register_data_record_20__next_write_site:int;
var tb_register_data_record_20__last_write_site:int;
const tb_register_data_record_20.size:bv32;
axiom tb_register_data_record_20.size == 140500bv32;

// tb_Register tb_register_data_record_21
var tb_register_data_record_21:[bv32]bv32;
var tb_register_data_record_21__last_index:bv32;
var tb_register_data_record_21__last_value:bv32;
var tb_register_data_record_21__last_old_value:bv32;
var tb_register_data_record_21__wrote_any:bool;
var tb_register_data_record_21__wrote_index0:bool;
var tb_register_data_record_21__last0_old_value:bv32;
var tb_register_data_record_21__last0_value:bv32;
var tb_register_data_record_21__next_write_site:int;
var tb_register_data_record_21__last_write_site:int;
const tb_register_data_record_21.size:bv32;
axiom tb_register_data_record_21.size == 140500bv32;

// tb_Register tb_register_data_record_22
var tb_register_data_record_22:[bv32]bv32;
var tb_register_data_record_22__last_index:bv32;
var tb_register_data_record_22__last_value:bv32;
var tb_register_data_record_22__last_old_value:bv32;
var tb_register_data_record_22__wrote_any:bool;
var tb_register_data_record_22__wrote_index0:bool;
var tb_register_data_record_22__last0_old_value:bv32;
var tb_register_data_record_22__last0_value:bv32;
var tb_register_data_record_22__next_write_site:int;
var tb_register_data_record_22__last_write_site:int;
const tb_register_data_record_22.size:bv32;
axiom tb_register_data_record_22.size == 140500bv32;

// tb_Table tb_table_dst_cs tb_Actionlist tb_Declaration
type tb_table_dst_cs.action;
const unique tb_table_dst_cs.action.action_dst_cs_1 : tb_table_dst_cs.action;
const unique tb_table_dst_cs.action.action_dst_cs_4 : tb_table_dst_cs.action;
const unique tb_table_dst_cs.action.action_dst_cs_9 : tb_table_dst_cs.action;
const unique tb_table_dst_cs.action.action_dst_cs_12 : tb_table_dst_cs.action;
var tb_table_dst_cs.action_run : tb_table_dst_cs.action;
var tb_table_dst_cs.hit : bool;

// tb_Table tb_table_dst_cs_0 tb_Actionlist tb_Declaration
type tb_table_dst_cs_0.action;
const unique tb_table_dst_cs_0.action.action_dst_cs_2 : tb_table_dst_cs_0.action;
const unique tb_table_dst_cs_0.action.action_dst_cs_7 : tb_table_dst_cs_0.action;
const unique tb_table_dst_cs_0.action.action_dst_cs_10 : tb_table_dst_cs_0.action;
const unique tb_table_dst_cs_0.action.action_dst_cs_13 : tb_table_dst_cs_0.action;
var tb_table_dst_cs_0.action_run : tb_table_dst_cs_0.action;
var tb_table_dst_cs_0.hit : bool;

// tb_Table tb_table_dst_cs_3 tb_Actionlist tb_Declaration
type tb_table_dst_cs_3.action;
const unique tb_table_dst_cs_3.action.action_dst_cs_3 : tb_table_dst_cs_3.action;
const unique tb_table_dst_cs_3.action.action_dst_cs_8 : tb_table_dst_cs_3.action;
const unique tb_table_dst_cs_3.action.action_dst_cs_11 : tb_table_dst_cs_3.action;
const unique tb_table_dst_cs_3.action.action_dst_cs_14 : tb_table_dst_cs_3.action;
var tb_table_dst_cs_3.action_run : tb_table_dst_cs_3.action;
var tb_table_dst_cs_3.hit : bool;
var tb___ra_val_register_data_record_0_write_0:bv32;
var tb___ra_ret_register_data_record_0_write_0:bv32;
var tb___ra_val_register_data_record_1_write_0:bv32;
var tb___ra_ret_register_data_record_1_write_0:bv32;
var tb___ra_val_register_data_record_2_write_0:bv32;
var tb___ra_ret_register_data_record_2_write_0:bv32;
var tb___ra_val_register_data_record_3_write_0:bv32;
var tb___ra_ret_register_data_record_3_write_0:bv32;
var tb___ra_val_register_data_record_4_write_0:bv32;
var tb___ra_ret_register_data_record_4_write_0:bv32;
var tb___ra_val_register_data_record_5_write_0:bv32;
var tb___ra_ret_register_data_record_5_write_0:bv32;
var tb___ra_val_register_data_record_6_write_0:bv32;
var tb___ra_ret_register_data_record_6_write_0:bv32;
var tb___ra_val_register_data_record_7_write_0:bv32;
var tb___ra_ret_register_data_record_7_write_0:bv32;
var tb___ra_val_register_data_record_8_write_0:bv32;
var tb___ra_ret_register_data_record_8_write_0:bv32;
var tb___ra_val_register_data_record_9_write_0:bv32;
var tb___ra_ret_register_data_record_9_write_0:bv32;
var tb___ra_val_register_data_record_10_write_0:bv32;
var tb___ra_ret_register_data_record_10_write_0:bv32;
var tb___ra_val_register_data_record_11_write_0:bv32;
var tb___ra_ret_register_data_record_11_write_0:bv32;


procedure {:inline 1} tb_accept()
{
}

// tb_Action tb_action_dst_cs_1
procedure {:inline 1} tb_action_dst_cs_1()
	modifies tb_meta.session_id;
{
    tb_meta.session_id := 1bv10;
}

// tb_Action tb_action_dst_cs_10
procedure {:inline 1} tb_action_dst_cs_10()
	modifies tb_meta.session_id;
{
    tb_meta.session_id := 3bv10;
}

// tb_Action tb_action_dst_cs_11
procedure {:inline 1} tb_action_dst_cs_11()
	modifies tb_meta.session_id;
{
    tb_meta.session_id := 3bv10;
}

// tb_Action tb_action_dst_cs_12
procedure {:inline 1} tb_action_dst_cs_12()
	modifies tb_meta.session_id;
{
    tb_meta.session_id := 4bv10;
}

// tb_Action tb_action_dst_cs_13
procedure {:inline 1} tb_action_dst_cs_13()
	modifies tb_meta.session_id;
{
    tb_meta.session_id := 4bv10;
}

// tb_Action tb_action_dst_cs_14
procedure {:inline 1} tb_action_dst_cs_14()
	modifies tb_meta.session_id;
{
    tb_meta.session_id := 4bv10;
}

// tb_Action tb_action_dst_cs_2
procedure {:inline 1} tb_action_dst_cs_2()
	modifies tb_meta.session_id;
{
    tb_meta.session_id := 1bv10;
}

// tb_Action tb_action_dst_cs_3
procedure {:inline 1} tb_action_dst_cs_3()
	modifies tb_meta.session_id;
{
    tb_meta.session_id := 1bv10;
}

// tb_Action tb_action_dst_cs_4
procedure {:inline 1} tb_action_dst_cs_4()
	modifies tb_meta.session_id;
{
    tb_meta.session_id := 2bv10;
}

// tb_Action tb_action_dst_cs_7
procedure {:inline 1} tb_action_dst_cs_7()
	modifies tb_meta.session_id;
{
    tb_meta.session_id := 2bv10;
}

// tb_Action tb_action_dst_cs_8
procedure {:inline 1} tb_action_dst_cs_8()
	modifies tb_meta.session_id;
{
    tb_meta.session_id := 2bv10;
}

// tb_Action tb_action_dst_cs_9
procedure {:inline 1} tb_action_dst_cs_9()
	modifies tb_meta.session_id;
{
    tb_meta.session_id := 3bv10;
}

// tb_Control tb_bEgress
procedure {:inline 1} tb_bEgress()
	modifies tb___ra_ret_register_data_record_0_write_0, tb___ra_ret_register_data_record_10_write_0, tb___ra_ret_register_data_record_11_write_0, tb___ra_ret_register_data_record_1_write_0, tb___ra_ret_register_data_record_2_write_0, tb___ra_ret_register_data_record_3_write_0, tb___ra_ret_register_data_record_4_write_0, tb___ra_ret_register_data_record_5_write_0, tb___ra_ret_register_data_record_6_write_0, tb___ra_ret_register_data_record_7_write_0, tb___ra_ret_register_data_record_8_write_0, tb___ra_ret_register_data_record_9_write_0, tb___ra_val_register_data_record_0_write_0, tb___ra_val_register_data_record_10_write_0, tb___ra_val_register_data_record_11_write_0, tb___ra_val_register_data_record_1_write_0, tb___ra_val_register_data_record_2_write_0, tb___ra_val_register_data_record_3_write_0, tb___ra_val_register_data_record_4_write_0, tb___ra_val_register_data_record_5_write_0, tb___ra_val_register_data_record_6_write_0, tb___ra_val_register_data_record_7_write_0, tb___ra_val_register_data_record_8_write_0, tb___ra_val_register_data_record_9_write_0, tb_eg_dprsr_md.mirror_type, tb_hdr.albion.CS_id_1, tb_hdr.albion.CS_id_2, tb_hdr.albion.CS_id_3, tb_hdr.albion.operation, tb_isValid, tb_meta.no_use, tb_meta.session_id, tb_p4b_clone_e2e, tb_register_data_record, tb_register_data_record_12, tb_register_data_record_12__last0_old_value, tb_register_data_record_12__last0_value, tb_register_data_record_12__last_index, tb_register_data_record_12__last_old_value, tb_register_data_record_12__last_value, tb_register_data_record_12__last_write_site, tb_register_data_record_12__next_write_site, tb_register_data_record_12__wrote_any, tb_register_data_record_12__wrote_index0, tb_register_data_record_13, tb_register_data_record_13__last0_old_value, tb_register_data_record_13__last0_value, tb_register_data_record_13__last_index, tb_register_data_record_13__last_old_value, tb_register_data_record_13__last_value, tb_register_data_record_13__last_write_site, tb_register_data_record_13__next_write_site, tb_register_data_record_13__wrote_any, tb_register_data_record_13__wrote_index0, tb_register_data_record_14, tb_register_data_record_14__last0_old_value, tb_register_data_record_14__last0_value, tb_register_data_record_14__last_index, tb_register_data_record_14__last_old_value, tb_register_data_record_14__last_value, tb_register_data_record_14__last_write_site, tb_register_data_record_14__next_write_site, tb_register_data_record_14__wrote_any, tb_register_data_record_14__wrote_index0, tb_register_data_record_15, tb_register_data_record_15__last0_old_value, tb_register_data_record_15__last0_value, tb_register_data_record_15__last_index, tb_register_data_record_15__last_old_value, tb_register_data_record_15__last_value, tb_register_data_record_15__last_write_site, tb_register_data_record_15__next_write_site, tb_register_data_record_15__wrote_any, tb_register_data_record_15__wrote_index0, tb_register_data_record_16, tb_register_data_record_16__last0_old_value, tb_register_data_record_16__last0_value, tb_register_data_record_16__last_index, tb_register_data_record_16__last_old_value, tb_register_data_record_16__last_value, tb_register_data_record_16__last_write_site, tb_register_data_record_16__next_write_site, tb_register_data_record_16__wrote_any, tb_register_data_record_16__wrote_index0, tb_register_data_record_17, tb_register_data_record_17__last0_old_value, tb_register_data_record_17__last0_value, tb_register_data_record_17__last_index, tb_register_data_record_17__last_old_value, tb_register_data_record_17__last_value, tb_register_data_record_17__last_write_site, tb_register_data_record_17__next_write_site, tb_register_data_record_17__wrote_any, tb_register_data_record_17__wrote_index0, tb_register_data_record_18, tb_register_data_record_18__last0_old_value, tb_register_data_record_18__last0_value, tb_register_data_record_18__last_index, tb_register_data_record_18__last_old_value, tb_register_data_record_18__last_value, tb_register_data_record_18__last_write_site, tb_register_data_record_18__next_write_site, tb_register_data_record_18__wrote_any, tb_register_data_record_18__wrote_index0, tb_register_data_record_19, tb_register_data_record_19__last0_old_value, tb_register_data_record_19__last0_value, tb_register_data_record_19__last_index, tb_register_data_record_19__last_old_value, tb_register_data_record_19__last_value, tb_register_data_record_19__last_write_site, tb_register_data_record_19__next_write_site, tb_register_data_record_19__wrote_any, tb_register_data_record_19__wrote_index0, tb_register_data_record_20, tb_register_data_record_20__last0_old_value, tb_register_data_record_20__last0_value, tb_register_data_record_20__last_index, tb_register_data_record_20__last_old_value, tb_register_data_record_20__last_value, tb_register_data_record_20__last_write_site, tb_register_data_record_20__next_write_site, tb_register_data_record_20__wrote_any, tb_register_data_record_20__wrote_index0, tb_register_data_record_21, tb_register_data_record_21__last0_old_value, tb_register_data_record_21__last0_value, tb_register_data_record_21__last_index, tb_register_data_record_21__last_old_value, tb_register_data_record_21__last_value, tb_register_data_record_21__last_write_site, tb_register_data_record_21__next_write_site, tb_register_data_record_21__wrote_any, tb_register_data_record_21__wrote_index0, tb_register_data_record_22, tb_register_data_record_22__last0_old_value, tb_register_data_record_22__last0_value, tb_register_data_record_22__last_index, tb_register_data_record_22__last_old_value, tb_register_data_record_22__last_value, tb_register_data_record_22__last_write_site, tb_register_data_record_22__next_write_site, tb_register_data_record_22__wrote_any, tb_register_data_record_22__wrote_index0, tb_register_data_record__last0_old_value, tb_register_data_record__last0_value, tb_register_data_record__last_index, tb_register_data_record__last_old_value, tb_register_data_record__last_value, tb_register_data_record__last_write_site, tb_register_data_record__next_write_site, tb_register_data_record__wrote_any, tb_register_data_record__wrote_index0, tb_table_dst_cs.action_run, tb_table_dst_cs.hit, tb_table_dst_cs_0.action_run, tb_table_dst_cs_0.hit, tb_table_dst_cs_3.action_run, tb_table_dst_cs_3.hit;
{
    if((tb_hdr.ethernet.ether_type == 21845bv16)){
        if(tb_isValid[tb_hdr.mirror_2]){
            call tb_setInvalid(tb_hdr.mirror_1);
            call tb_setInvalid(tb_hdr.mirror_2);
            tb_hdr.albion.operation := 12bv32;
        }
        else{
            if(tb_isValid[tb_hdr.mirror_1]){
                call tb_setInvalid(tb_hdr.mirror_1);
                call tb_table_dst_cs_3.apply();
                tb_meta.no_use := 2bv8;
                tb_eg_dprsr_md.mirror_type := 1bv3;
                tb_p4b_clone_e2e := tb_p4b_clone_e2e || (1bv3 != 0bv3);
                tb_hdr.albion.operation := 11bv32;
            }
            else{
                if((tb_hdr.albion.operation == 70bv32)){
                    call tb_table_dst_cs.apply();
                    tb_meta.no_use := 1bv8;
                    tb_eg_dprsr_md.mirror_type := 1bv3;
                    tb_p4b_clone_e2e := tb_p4b_clone_e2e || (1bv3 != 0bv3);
                }
                else{
                    if((tb_hdr.albion.operation == 10bv32)){
                        call tb_table_dst_cs_0.apply();
                        tb_meta.no_use := 1bv8;
                        tb_eg_dprsr_md.mirror_type := 1bv3;
                        tb_p4b_clone_e2e := tb_p4b_clone_e2e || (1bv3 != 0bv3);
                        tb___ra_val_register_data_record_0_write_0 := tb_register_data_record.read(tb_register_data_record, tb_hdr.albion.index);
                        call tb___ra_val_register_data_record_0_write_0 := tb_register_data_record_0_write_0.apply(tb___ra_val_register_data_record_0_write_0);
                        tb___ra_ret_register_data_record_0_write_0 := tb___ra_val_register_data_record_0_write_0;
                        tb_register_data_record__next_write_site := 1;
                        call tb_register_data_record.write(tb_hdr.albion.index, tb___ra_val_register_data_record_0_write_0);
                    }
                }
            }
        }
        if((tb_hdr.albion.operation == 10bv32)){
            tb___ra_val_register_data_record_1_write_0 := tb_register_data_record_12.read(tb_register_data_record_12, tb_hdr.albion.index);
            call tb___ra_val_register_data_record_1_write_0 := tb_register_data_record_1_write_0.apply(tb___ra_val_register_data_record_1_write_0);
            tb___ra_ret_register_data_record_1_write_0 := tb___ra_val_register_data_record_1_write_0;
            tb_register_data_record_12__next_write_site := 1;
            call tb_register_data_record_12.write(tb_hdr.albion.index, tb___ra_val_register_data_record_1_write_0);
        }
        if((tb_hdr.albion.operation == 10bv32)){
            tb___ra_val_register_data_record_2_write_0 := tb_register_data_record_13.read(tb_register_data_record_13, tb_hdr.albion.index);
            call tb___ra_val_register_data_record_2_write_0 := tb_register_data_record_2_write_0.apply(tb___ra_val_register_data_record_2_write_0);
            tb___ra_ret_register_data_record_2_write_0 := tb___ra_val_register_data_record_2_write_0;
            tb_register_data_record_13__next_write_site := 1;
            call tb_register_data_record_13.write(tb_hdr.albion.index, tb___ra_val_register_data_record_2_write_0);
        }
        if((tb_hdr.albion.operation == 10bv32)){
            tb___ra_val_register_data_record_3_write_0 := tb_register_data_record_14.read(tb_register_data_record_14, tb_hdr.albion.index);
            call tb___ra_val_register_data_record_3_write_0 := tb_register_data_record_3_write_0.apply(tb___ra_val_register_data_record_3_write_0);
            tb___ra_ret_register_data_record_3_write_0 := tb___ra_val_register_data_record_3_write_0;
            tb_register_data_record_14__next_write_site := 1;
            call tb_register_data_record_14.write(tb_hdr.albion.index, tb___ra_val_register_data_record_3_write_0);
        }
        if((tb_hdr.albion.operation == 10bv32)){
            tb___ra_val_register_data_record_4_write_0 := tb_register_data_record_15.read(tb_register_data_record_15, tb_hdr.albion.index);
            call tb___ra_val_register_data_record_4_write_0 := tb_register_data_record_4_write_0.apply(tb___ra_val_register_data_record_4_write_0);
            tb___ra_ret_register_data_record_4_write_0 := tb___ra_val_register_data_record_4_write_0;
            tb_register_data_record_15__next_write_site := 1;
            call tb_register_data_record_15.write(tb_hdr.albion.index, tb___ra_val_register_data_record_4_write_0);
        }
        if((tb_hdr.albion.operation == 10bv32)){
            tb___ra_val_register_data_record_5_write_0 := tb_register_data_record_16.read(tb_register_data_record_16, tb_hdr.albion.index);
            call tb___ra_val_register_data_record_5_write_0 := tb_register_data_record_5_write_0.apply(tb___ra_val_register_data_record_5_write_0);
            tb___ra_ret_register_data_record_5_write_0 := tb___ra_val_register_data_record_5_write_0;
            tb_register_data_record_16__next_write_site := 1;
            call tb_register_data_record_16.write(tb_hdr.albion.index, tb___ra_val_register_data_record_5_write_0);
        }
        if((tb_hdr.albion.operation == 10bv32)){
            tb___ra_val_register_data_record_6_write_0 := tb_register_data_record_17.read(tb_register_data_record_17, tb_hdr.albion.index);
            call tb___ra_val_register_data_record_6_write_0 := tb_register_data_record_6_write_0.apply(tb___ra_val_register_data_record_6_write_0);
            tb___ra_ret_register_data_record_6_write_0 := tb___ra_val_register_data_record_6_write_0;
            tb_register_data_record_17__next_write_site := 1;
            call tb_register_data_record_17.write(tb_hdr.albion.index, tb___ra_val_register_data_record_6_write_0);
        }
        if((tb_hdr.albion.operation == 10bv32)){
            tb___ra_val_register_data_record_7_write_0 := tb_register_data_record_18.read(tb_register_data_record_18, tb_hdr.albion.index);
            call tb___ra_val_register_data_record_7_write_0 := tb_register_data_record_7_write_0.apply(tb___ra_val_register_data_record_7_write_0);
            tb___ra_ret_register_data_record_7_write_0 := tb___ra_val_register_data_record_7_write_0;
            tb_register_data_record_18__next_write_site := 1;
            call tb_register_data_record_18.write(tb_hdr.albion.index, tb___ra_val_register_data_record_7_write_0);
        }
        if((tb_hdr.albion.operation == 10bv32)){
            tb___ra_val_register_data_record_8_write_0 := tb_register_data_record_19.read(tb_register_data_record_19, tb_hdr.albion.index);
            call tb___ra_val_register_data_record_8_write_0 := tb_register_data_record_8_write_0.apply(tb___ra_val_register_data_record_8_write_0);
            tb___ra_ret_register_data_record_8_write_0 := tb___ra_val_register_data_record_8_write_0;
            tb_register_data_record_19__next_write_site := 1;
            call tb_register_data_record_19.write(tb_hdr.albion.index, tb___ra_val_register_data_record_8_write_0);
        }
        if((tb_hdr.albion.operation == 10bv32)){
            tb___ra_val_register_data_record_9_write_0 := tb_register_data_record_20.read(tb_register_data_record_20, tb_hdr.albion.index);
            call tb___ra_val_register_data_record_9_write_0 := tb_register_data_record_9_write_0.apply(tb___ra_val_register_data_record_9_write_0);
            tb___ra_ret_register_data_record_9_write_0 := tb___ra_val_register_data_record_9_write_0;
            tb_register_data_record_20__next_write_site := 1;
            call tb_register_data_record_20.write(tb_hdr.albion.index, tb___ra_val_register_data_record_9_write_0);
        }
        if((tb_hdr.albion.operation == 10bv32)){
            tb___ra_val_register_data_record_10_write_0 := tb_register_data_record_21.read(tb_register_data_record_21, tb_hdr.albion.index);
            call tb___ra_val_register_data_record_10_write_0 := tb_register_data_record_10_write_0.apply(tb___ra_val_register_data_record_10_write_0);
            tb___ra_ret_register_data_record_10_write_0 := tb___ra_val_register_data_record_10_write_0;
            tb_register_data_record_21__next_write_site := 1;
            call tb_register_data_record_21.write(tb_hdr.albion.index, tb___ra_val_register_data_record_10_write_0);
        }
        if((tb_hdr.albion.operation == 10bv32)){
            tb___ra_val_register_data_record_11_write_0 := tb_register_data_record_22.read(tb_register_data_record_22, tb_hdr.albion.index);
            call tb___ra_val_register_data_record_11_write_0 := tb_register_data_record_11_write_0.apply(tb___ra_val_register_data_record_11_write_0);
            tb___ra_ret_register_data_record_11_write_0 := tb___ra_val_register_data_record_11_write_0;
            tb_register_data_record_22__next_write_site := 1;
            call tb_register_data_record_22.write(tb_hdr.albion.index, tb___ra_val_register_data_record_11_write_0);
        }
        else{
            if((tb_hdr.albion.operation == 11bv32)){
                if((tb_hdr.albion.CS_id_2 == 10bv32)){
                    tb_hdr.albion.operation := 70bv32;
                }
            }
            else{
                if((tb_hdr.albion.operation == 12bv32)){
                    if((tb_hdr.albion.CS_id_3 == 10bv32)){
                        tb_hdr.albion.operation := 70bv32;
                    }
                }
            }
        }
    }
}

// tb_Control tb_bEgressDeparser
procedure {:inline 1} tb_bEgressDeparser()
	modifies tb_p4b_clone_i2e;
{
    if((tb_eg_dprsr_md.mirror_type == 1bv3)){
        tb_p4b_clone_i2e := true;
    }
    call tb_pkt.emit(tb_hdr);
}

// tb_Parser tb_bEgressParser
procedure {:inline 1} tb_bEgressParser()
	modifies tb_drop, tb_isValid, tb_mirror_md_0, tb_mirror_md_1, tb_mirror_md_2;
{
    goto tb_State$bEgressParser$start;

        tb_State$bEgressParser$start:
    call tb_packet_in.extract(tb_eg_intr_md);
    havoc tb_mirror_md_0;
    goto tb_State$bEgressParser$start$parse_mirror_1_3, tb_State$bEgressParser$start$parse_mirror_2_2, tb_State$bEgressParser$start$DEFAULT;
    
tb_State$bEgressParser$start$parse_mirror_1_3:
    assume (tb_mirror_md_0.pkt_type == 1bv8);
    goto tb_State$bEgressParser$parse_mirror_1;
    
tb_State$bEgressParser$start$parse_mirror_2_2:
    assume (tb_mirror_md_0.pkt_type == 2bv8);
    goto tb_State$bEgressParser$parse_mirror_2;

    tb_State$bEgressParser$start$DEFAULT:
    assume(!(tb_mirror_md_0.pkt_type == 1bv8)&&!(tb_mirror_md_0.pkt_type == 2bv8));
    goto tb_State$bEgressParser$parse_ethernet;

        tb_State$bEgressParser$parse_mirror_1:
    call tb_packet_in.extract(tb_hdr.mirror_1);
    havoc tb_mirror_md_1;
    goto tb_State$bEgressParser$parse_mirror_1$parse_mirror_1_2_2, tb_State$bEgressParser$parse_mirror_1$DEFAULT;
    
tb_State$bEgressParser$parse_mirror_1$parse_mirror_1_2_2:
    assume (tb_mirror_md_1.pkt_type == 2bv8);
    goto tb_State$bEgressParser$parse_mirror_1_2;

    tb_State$bEgressParser$parse_mirror_1$DEFAULT:
    assume(!(tb_mirror_md_1.pkt_type == 2bv8));
    goto tb_State$bEgressParser$parse_ethernet;

        tb_State$bEgressParser$parse_mirror_2:
    call tb_packet_in.extract(tb_hdr.mirror_2);
    havoc tb_mirror_md_2;
    goto tb_State$bEgressParser$parse_mirror_2$parse_mirror_2_1_2, tb_State$bEgressParser$parse_mirror_2$DEFAULT;
    
tb_State$bEgressParser$parse_mirror_2$parse_mirror_2_1_2:
    assume (tb_mirror_md_2.pkt_type == 1bv8);
    goto tb_State$bEgressParser$parse_mirror_2_1;

    tb_State$bEgressParser$parse_mirror_2$DEFAULT:
    assume(!(tb_mirror_md_2.pkt_type == 1bv8));
    goto tb_State$bEgressParser$parse_ethernet;

        tb_State$bEgressParser$parse_mirror_1_2:
    call tb_packet_in.extract(tb_hdr.mirror_2);
    goto tb_State$bEgressParser$parse_ethernet;

        tb_State$bEgressParser$parse_mirror_2_1:
    call tb_packet_in.extract(tb_hdr.mirror_1);
    goto tb_State$bEgressParser$parse_ethernet;

        tb_State$bEgressParser$parse_ethernet:
    call tb_packet_in.extract(tb_hdr.ethernet);
    goto tb_State$bEgressParser$parse_ethernet$parse_albion_2, tb_State$bEgressParser$parse_ethernet$DEFAULT;
    
tb_State$bEgressParser$parse_ethernet$parse_albion_2:
    assume (tb_hdr.ethernet.ether_type == 21845bv16);
    goto tb_State$bEgressParser$parse_albion;

    tb_State$bEgressParser$parse_ethernet$DEFAULT:
    assume(!(tb_hdr.ethernet.ether_type == 21845bv16));
    goto tb_State$reject;

        tb_State$bEgressParser$parse_albion:
    call tb_packet_in.extract(tb_hdr.albion);
    call tb_packet_in.extract(tb_hdr.albion_data);
    goto tb_State$accept;

    tb_State$accept:
    call tb_accept();
    goto tb_Exit;

    tb_State$reject:
    call tb_reject();
    goto tb_Exit;

    tb_Exit:
}

// tb_Control tb_bIngress
procedure {:inline 1} tb_bIngress()
	modifies tb_ig_tm_md.ucast_egress_port;
{
    if((tb_hdr.ethernet.ether_type == 21845bv16)){
        tb_ig_tm_md.ucast_egress_port := tb_hdr.albion.port[9:0];
    }
}

// tb_Control tb_bIngressDeparser
procedure {:inline 1} tb_bIngressDeparser()
{
    call tb_pkt.emit(tb_hdr);
}

// tb_Parser tb_bIngressParser
procedure {:inline 1} tb_bIngressParser()
	modifies tb_drop, tb_isValid;
{
    goto tb_State$bIngressParser$start;

        tb_State$bIngressParser$start:
    call tb_packet_in.extract(tb_ig_intr_md);
    call tb_pkt.advance(64bv32);
    call tb_packet_in.extract(tb_hdr.ethernet);
    goto tb_State$bIngressParser$start$parse_albion_2, tb_State$bIngressParser$start$DEFAULT;
    
tb_State$bIngressParser$start$parse_albion_2:
    assume (tb_hdr.ethernet.ether_type == 21845bv16);
    goto tb_State$bIngressParser$parse_albion;

    tb_State$bIngressParser$start$DEFAULT:
    assume(!(tb_hdr.ethernet.ether_type == 21845bv16));
    goto tb_State$accept;

        tb_State$bIngressParser$parse_albion:
    call tb_packet_in.extract(tb_hdr.albion);
    goto tb_State$accept;

    tb_State$accept:
    call tb_accept();
    goto tb_Exit;

    tb_State$reject:
    call tb_reject();
    goto tb_Exit;

    tb_Exit:
}
procedure {:inline 1} tb_main()
	modifies tb___ra_ret_register_data_record_0_write_0, tb___ra_ret_register_data_record_10_write_0, tb___ra_ret_register_data_record_11_write_0, tb___ra_ret_register_data_record_1_write_0, tb___ra_ret_register_data_record_2_write_0, tb___ra_ret_register_data_record_3_write_0, tb___ra_ret_register_data_record_4_write_0, tb___ra_ret_register_data_record_5_write_0, tb___ra_ret_register_data_record_6_write_0, tb___ra_ret_register_data_record_7_write_0, tb___ra_ret_register_data_record_8_write_0, tb___ra_ret_register_data_record_9_write_0, tb___ra_val_register_data_record_0_write_0, tb___ra_val_register_data_record_10_write_0, tb___ra_val_register_data_record_11_write_0, tb___ra_val_register_data_record_1_write_0, tb___ra_val_register_data_record_2_write_0, tb___ra_val_register_data_record_3_write_0, tb___ra_val_register_data_record_4_write_0, tb___ra_val_register_data_record_5_write_0, tb___ra_val_register_data_record_6_write_0, tb___ra_val_register_data_record_7_write_0, tb___ra_val_register_data_record_8_write_0, tb___ra_val_register_data_record_9_write_0, tb_drop, tb_eg_dprsr_md.mirror_type, tb_hdr.albion.CS_id_1, tb_hdr.albion.CS_id_2, tb_hdr.albion.CS_id_3, tb_hdr.albion.operation, tb_ig_tm_md.ucast_egress_port, tb_isValid, tb_meta.no_use, tb_meta.session_id, tb_mirror_md_0, tb_mirror_md_1, tb_mirror_md_2, tb_p4b_clone_e2e, tb_p4b_clone_i2e, tb_register_data_record, tb_register_data_record_12, tb_register_data_record_12__last0_old_value, tb_register_data_record_12__last0_value, tb_register_data_record_12__last_index, tb_register_data_record_12__last_old_value, tb_register_data_record_12__last_value, tb_register_data_record_12__last_write_site, tb_register_data_record_12__next_write_site, tb_register_data_record_12__wrote_any, tb_register_data_record_12__wrote_index0, tb_register_data_record_13, tb_register_data_record_13__last0_old_value, tb_register_data_record_13__last0_value, tb_register_data_record_13__last_index, tb_register_data_record_13__last_old_value, tb_register_data_record_13__last_value, tb_register_data_record_13__last_write_site, tb_register_data_record_13__next_write_site, tb_register_data_record_13__wrote_any, tb_register_data_record_13__wrote_index0, tb_register_data_record_14, tb_register_data_record_14__last0_old_value, tb_register_data_record_14__last0_value, tb_register_data_record_14__last_index, tb_register_data_record_14__last_old_value, tb_register_data_record_14__last_value, tb_register_data_record_14__last_write_site, tb_register_data_record_14__next_write_site, tb_register_data_record_14__wrote_any, tb_register_data_record_14__wrote_index0, tb_register_data_record_15, tb_register_data_record_15__last0_old_value, tb_register_data_record_15__last0_value, tb_register_data_record_15__last_index, tb_register_data_record_15__last_old_value, tb_register_data_record_15__last_value, tb_register_data_record_15__last_write_site, tb_register_data_record_15__next_write_site, tb_register_data_record_15__wrote_any, tb_register_data_record_15__wrote_index0, tb_register_data_record_16, tb_register_data_record_16__last0_old_value, tb_register_data_record_16__last0_value, tb_register_data_record_16__last_index, tb_register_data_record_16__last_old_value, tb_register_data_record_16__last_value, tb_register_data_record_16__last_write_site, tb_register_data_record_16__next_write_site, tb_register_data_record_16__wrote_any, tb_register_data_record_16__wrote_index0, tb_register_data_record_17, tb_register_data_record_17__last0_old_value, tb_register_data_record_17__last0_value, tb_register_data_record_17__last_index, tb_register_data_record_17__last_old_value, tb_register_data_record_17__last_value, tb_register_data_record_17__last_write_site, tb_register_data_record_17__next_write_site, tb_register_data_record_17__wrote_any, tb_register_data_record_17__wrote_index0, tb_register_data_record_18, tb_register_data_record_18__last0_old_value, tb_register_data_record_18__last0_value, tb_register_data_record_18__last_index, tb_register_data_record_18__last_old_value, tb_register_data_record_18__last_value, tb_register_data_record_18__last_write_site, tb_register_data_record_18__next_write_site, tb_register_data_record_18__wrote_any, tb_register_data_record_18__wrote_index0, tb_register_data_record_19, tb_register_data_record_19__last0_old_value, tb_register_data_record_19__last0_value, tb_register_data_record_19__last_index, tb_register_data_record_19__last_old_value, tb_register_data_record_19__last_value, tb_register_data_record_19__last_write_site, tb_register_data_record_19__next_write_site, tb_register_data_record_19__wrote_any, tb_register_data_record_19__wrote_index0, tb_register_data_record_20, tb_register_data_record_20__last0_old_value, tb_register_data_record_20__last0_value, tb_register_data_record_20__last_index, tb_register_data_record_20__last_old_value, tb_register_data_record_20__last_value, tb_register_data_record_20__last_write_site, tb_register_data_record_20__next_write_site, tb_register_data_record_20__wrote_any, tb_register_data_record_20__wrote_index0, tb_register_data_record_21, tb_register_data_record_21__last0_old_value, tb_register_data_record_21__last0_value, tb_register_data_record_21__last_index, tb_register_data_record_21__last_old_value, tb_register_data_record_21__last_value, tb_register_data_record_21__last_write_site, tb_register_data_record_21__next_write_site, tb_register_data_record_21__wrote_any, tb_register_data_record_21__wrote_index0, tb_register_data_record_22, tb_register_data_record_22__last0_old_value, tb_register_data_record_22__last0_value, tb_register_data_record_22__last_index, tb_register_data_record_22__last_old_value, tb_register_data_record_22__last_value, tb_register_data_record_22__last_write_site, tb_register_data_record_22__next_write_site, tb_register_data_record_22__wrote_any, tb_register_data_record_22__wrote_index0, tb_register_data_record__last0_old_value, tb_register_data_record__last0_value, tb_register_data_record__last_index, tb_register_data_record__last_old_value, tb_register_data_record__last_value, tb_register_data_record__last_write_site, tb_register_data_record__next_write_site, tb_register_data_record__wrote_any, tb_register_data_record__wrote_index0, tb_table_dst_cs.action_run, tb_table_dst_cs.hit, tb_table_dst_cs_0.action_run, tb_table_dst_cs_0.hit, tb_table_dst_cs_3.action_run, tb_table_dst_cs_3.hit;
{
    call tb_pipe_b();
    if(tb_forward == false){
        tb_drop := true;
    }
}
procedure tb_mainProcedure()
	modifies tb___ra_ret_register_data_record_0_write_0, tb___ra_ret_register_data_record_10_write_0, tb___ra_ret_register_data_record_11_write_0, tb___ra_ret_register_data_record_1_write_0, tb___ra_ret_register_data_record_2_write_0, tb___ra_ret_register_data_record_3_write_0, tb___ra_ret_register_data_record_4_write_0, tb___ra_ret_register_data_record_5_write_0, tb___ra_ret_register_data_record_6_write_0, tb___ra_ret_register_data_record_7_write_0, tb___ra_ret_register_data_record_8_write_0, tb___ra_ret_register_data_record_9_write_0, tb___ra_val_register_data_record_0_write_0, tb___ra_val_register_data_record_10_write_0, tb___ra_val_register_data_record_11_write_0, tb___ra_val_register_data_record_1_write_0, tb___ra_val_register_data_record_2_write_0, tb___ra_val_register_data_record_3_write_0, tb___ra_val_register_data_record_4_write_0, tb___ra_val_register_data_record_5_write_0, tb___ra_val_register_data_record_6_write_0, tb___ra_val_register_data_record_7_write_0, tb___ra_val_register_data_record_8_write_0, tb___ra_val_register_data_record_9_write_0, tb_drop, tb_eg_dprsr_md.mirror_type, tb_hdr.albion.CS_id_1, tb_hdr.albion.CS_id_2, tb_hdr.albion.CS_id_3, tb_hdr.albion.operation, tb_ig_tm_md.ucast_egress_port, tb_isValid, tb_meta.no_use, tb_meta.session_id, tb_mirror_md_0, tb_mirror_md_1, tb_mirror_md_2, tb_p4b_checksum_error, tb_p4b_checksum_updated, tb_p4b_checksum_verified, tb_p4b_clone_e2e, tb_p4b_clone_i2e, tb_p4b_clone_i2i, tb_p4b_digest, tb_p4b_recirculate, tb_register_data_record, tb_register_data_record_12, tb_register_data_record_12__last0_old_value, tb_register_data_record_12__last0_value, tb_register_data_record_12__last_index, tb_register_data_record_12__last_old_value, tb_register_data_record_12__last_value, tb_register_data_record_12__last_write_site, tb_register_data_record_12__next_write_site, tb_register_data_record_12__wrote_any, tb_register_data_record_12__wrote_index0, tb_register_data_record_13, tb_register_data_record_13__last0_old_value, tb_register_data_record_13__last0_value, tb_register_data_record_13__last_index, tb_register_data_record_13__last_old_value, tb_register_data_record_13__last_value, tb_register_data_record_13__last_write_site, tb_register_data_record_13__next_write_site, tb_register_data_record_13__wrote_any, tb_register_data_record_13__wrote_index0, tb_register_data_record_14, tb_register_data_record_14__last0_old_value, tb_register_data_record_14__last0_value, tb_register_data_record_14__last_index, tb_register_data_record_14__last_old_value, tb_register_data_record_14__last_value, tb_register_data_record_14__last_write_site, tb_register_data_record_14__next_write_site, tb_register_data_record_14__wrote_any, tb_register_data_record_14__wrote_index0, tb_register_data_record_15, tb_register_data_record_15__last0_old_value, tb_register_data_record_15__last0_value, tb_register_data_record_15__last_index, tb_register_data_record_15__last_old_value, tb_register_data_record_15__last_value, tb_register_data_record_15__last_write_site, tb_register_data_record_15__next_write_site, tb_register_data_record_15__wrote_any, tb_register_data_record_15__wrote_index0, tb_register_data_record_16, tb_register_data_record_16__last0_old_value, tb_register_data_record_16__last0_value, tb_register_data_record_16__last_index, tb_register_data_record_16__last_old_value, tb_register_data_record_16__last_value, tb_register_data_record_16__last_write_site, tb_register_data_record_16__next_write_site, tb_register_data_record_16__wrote_any, tb_register_data_record_16__wrote_index0, tb_register_data_record_17, tb_register_data_record_17__last0_old_value, tb_register_data_record_17__last0_value, tb_register_data_record_17__last_index, tb_register_data_record_17__last_old_value, tb_register_data_record_17__last_value, tb_register_data_record_17__last_write_site, tb_register_data_record_17__next_write_site, tb_register_data_record_17__wrote_any, tb_register_data_record_17__wrote_index0, tb_register_data_record_18, tb_register_data_record_18__last0_old_value, tb_register_data_record_18__last0_value, tb_register_data_record_18__last_index, tb_register_data_record_18__last_old_value, tb_register_data_record_18__last_value, tb_register_data_record_18__last_write_site, tb_register_data_record_18__next_write_site, tb_register_data_record_18__wrote_any, tb_register_data_record_18__wrote_index0, tb_register_data_record_19, tb_register_data_record_19__last0_old_value, tb_register_data_record_19__last0_value, tb_register_data_record_19__last_index, tb_register_data_record_19__last_old_value, tb_register_data_record_19__last_value, tb_register_data_record_19__last_write_site, tb_register_data_record_19__next_write_site, tb_register_data_record_19__wrote_any, tb_register_data_record_19__wrote_index0, tb_register_data_record_20, tb_register_data_record_20__last0_old_value, tb_register_data_record_20__last0_value, tb_register_data_record_20__last_index, tb_register_data_record_20__last_old_value, tb_register_data_record_20__last_value, tb_register_data_record_20__last_write_site, tb_register_data_record_20__next_write_site, tb_register_data_record_20__wrote_any, tb_register_data_record_20__wrote_index0, tb_register_data_record_21, tb_register_data_record_21__last0_old_value, tb_register_data_record_21__last0_value, tb_register_data_record_21__last_index, tb_register_data_record_21__last_old_value, tb_register_data_record_21__last_value, tb_register_data_record_21__last_write_site, tb_register_data_record_21__next_write_site, tb_register_data_record_21__wrote_any, tb_register_data_record_21__wrote_index0, tb_register_data_record_22, tb_register_data_record_22__last0_old_value, tb_register_data_record_22__last0_value, tb_register_data_record_22__last_index, tb_register_data_record_22__last_old_value, tb_register_data_record_22__last_value, tb_register_data_record_22__last_write_site, tb_register_data_record_22__next_write_site, tb_register_data_record_22__wrote_any, tb_register_data_record_22__wrote_index0, tb_register_data_record__last0_old_value, tb_register_data_record__last0_value, tb_register_data_record__last_index, tb_register_data_record__last_old_value, tb_register_data_record__last_value, tb_register_data_record__last_write_site, tb_register_data_record__next_write_site, tb_register_data_record__wrote_any, tb_register_data_record__wrote_index0, tb_table_dst_cs.action_run, tb_table_dst_cs.hit, tb_table_dst_cs_0.action_run, tb_table_dst_cs_0.hit, tb_table_dst_cs_3.action_run, tb_table_dst_cs_3.hit;
{
    tb_p4b_checksum_error := false;
    tb_p4b_checksum_updated := false;
    tb_p4b_checksum_verified := false;
    tb_p4b_digest := false;
    tb_p4b_recirculate := false;
    tb_p4b_clone_i2i := false;
    tb_p4b_clone_e2e := false;
    tb_p4b_clone_i2e := false;
    call tb_main();
}
procedure tb_mark_to_drop();
    ensures tb_drop==true;
	modifies tb_drop;
procedure tb_packet_in.extract(tb_header:tb_Ref);
    ensures (tb_isValid[tb_header] == true);
	modifies tb_isValid;
procedure {:inline 1} tb_pipe_b()
	modifies tb___ra_ret_register_data_record_0_write_0, tb___ra_ret_register_data_record_10_write_0, tb___ra_ret_register_data_record_11_write_0, tb___ra_ret_register_data_record_1_write_0, tb___ra_ret_register_data_record_2_write_0, tb___ra_ret_register_data_record_3_write_0, tb___ra_ret_register_data_record_4_write_0, tb___ra_ret_register_data_record_5_write_0, tb___ra_ret_register_data_record_6_write_0, tb___ra_ret_register_data_record_7_write_0, tb___ra_ret_register_data_record_8_write_0, tb___ra_ret_register_data_record_9_write_0, tb___ra_val_register_data_record_0_write_0, tb___ra_val_register_data_record_10_write_0, tb___ra_val_register_data_record_11_write_0, tb___ra_val_register_data_record_1_write_0, tb___ra_val_register_data_record_2_write_0, tb___ra_val_register_data_record_3_write_0, tb___ra_val_register_data_record_4_write_0, tb___ra_val_register_data_record_5_write_0, tb___ra_val_register_data_record_6_write_0, tb___ra_val_register_data_record_7_write_0, tb___ra_val_register_data_record_8_write_0, tb___ra_val_register_data_record_9_write_0, tb_drop, tb_eg_dprsr_md.mirror_type, tb_hdr.albion.CS_id_1, tb_hdr.albion.CS_id_2, tb_hdr.albion.CS_id_3, tb_hdr.albion.operation, tb_ig_tm_md.ucast_egress_port, tb_isValid, tb_meta.no_use, tb_meta.session_id, tb_mirror_md_0, tb_mirror_md_1, tb_mirror_md_2, tb_p4b_clone_e2e, tb_p4b_clone_i2e, tb_register_data_record, tb_register_data_record_12, tb_register_data_record_12__last0_old_value, tb_register_data_record_12__last0_value, tb_register_data_record_12__last_index, tb_register_data_record_12__last_old_value, tb_register_data_record_12__last_value, tb_register_data_record_12__last_write_site, tb_register_data_record_12__next_write_site, tb_register_data_record_12__wrote_any, tb_register_data_record_12__wrote_index0, tb_register_data_record_13, tb_register_data_record_13__last0_old_value, tb_register_data_record_13__last0_value, tb_register_data_record_13__last_index, tb_register_data_record_13__last_old_value, tb_register_data_record_13__last_value, tb_register_data_record_13__last_write_site, tb_register_data_record_13__next_write_site, tb_register_data_record_13__wrote_any, tb_register_data_record_13__wrote_index0, tb_register_data_record_14, tb_register_data_record_14__last0_old_value, tb_register_data_record_14__last0_value, tb_register_data_record_14__last_index, tb_register_data_record_14__last_old_value, tb_register_data_record_14__last_value, tb_register_data_record_14__last_write_site, tb_register_data_record_14__next_write_site, tb_register_data_record_14__wrote_any, tb_register_data_record_14__wrote_index0, tb_register_data_record_15, tb_register_data_record_15__last0_old_value, tb_register_data_record_15__last0_value, tb_register_data_record_15__last_index, tb_register_data_record_15__last_old_value, tb_register_data_record_15__last_value, tb_register_data_record_15__last_write_site, tb_register_data_record_15__next_write_site, tb_register_data_record_15__wrote_any, tb_register_data_record_15__wrote_index0, tb_register_data_record_16, tb_register_data_record_16__last0_old_value, tb_register_data_record_16__last0_value, tb_register_data_record_16__last_index, tb_register_data_record_16__last_old_value, tb_register_data_record_16__last_value, tb_register_data_record_16__last_write_site, tb_register_data_record_16__next_write_site, tb_register_data_record_16__wrote_any, tb_register_data_record_16__wrote_index0, tb_register_data_record_17, tb_register_data_record_17__last0_old_value, tb_register_data_record_17__last0_value, tb_register_data_record_17__last_index, tb_register_data_record_17__last_old_value, tb_register_data_record_17__last_value, tb_register_data_record_17__last_write_site, tb_register_data_record_17__next_write_site, tb_register_data_record_17__wrote_any, tb_register_data_record_17__wrote_index0, tb_register_data_record_18, tb_register_data_record_18__last0_old_value, tb_register_data_record_18__last0_value, tb_register_data_record_18__last_index, tb_register_data_record_18__last_old_value, tb_register_data_record_18__last_value, tb_register_data_record_18__last_write_site, tb_register_data_record_18__next_write_site, tb_register_data_record_18__wrote_any, tb_register_data_record_18__wrote_index0, tb_register_data_record_19, tb_register_data_record_19__last0_old_value, tb_register_data_record_19__last0_value, tb_register_data_record_19__last_index, tb_register_data_record_19__last_old_value, tb_register_data_record_19__last_value, tb_register_data_record_19__last_write_site, tb_register_data_record_19__next_write_site, tb_register_data_record_19__wrote_any, tb_register_data_record_19__wrote_index0, tb_register_data_record_20, tb_register_data_record_20__last0_old_value, tb_register_data_record_20__last0_value, tb_register_data_record_20__last_index, tb_register_data_record_20__last_old_value, tb_register_data_record_20__last_value, tb_register_data_record_20__last_write_site, tb_register_data_record_20__next_write_site, tb_register_data_record_20__wrote_any, tb_register_data_record_20__wrote_index0, tb_register_data_record_21, tb_register_data_record_21__last0_old_value, tb_register_data_record_21__last0_value, tb_register_data_record_21__last_index, tb_register_data_record_21__last_old_value, tb_register_data_record_21__last_value, tb_register_data_record_21__last_write_site, tb_register_data_record_21__next_write_site, tb_register_data_record_21__wrote_any, tb_register_data_record_21__wrote_index0, tb_register_data_record_22, tb_register_data_record_22__last0_old_value, tb_register_data_record_22__last0_value, tb_register_data_record_22__last_index, tb_register_data_record_22__last_old_value, tb_register_data_record_22__last_value, tb_register_data_record_22__last_write_site, tb_register_data_record_22__next_write_site, tb_register_data_record_22__wrote_any, tb_register_data_record_22__wrote_index0, tb_register_data_record__last0_old_value, tb_register_data_record__last0_value, tb_register_data_record__last_index, tb_register_data_record__last_old_value, tb_register_data_record__last_value, tb_register_data_record__last_write_site, tb_register_data_record__next_write_site, tb_register_data_record__wrote_any, tb_register_data_record__wrote_index0, tb_table_dst_cs.action_run, tb_table_dst_cs.hit, tb_table_dst_cs_0.action_run, tb_table_dst_cs_0.hit, tb_table_dst_cs_3.action_run, tb_table_dst_cs_3.hit;
{
    call tb_bIngressParser();
    call tb_bIngress();
    call tb_bIngressDeparser();
    call tb_bEgressParser();
    call tb_bEgress();
    call tb_bEgressDeparser();
}
procedure tb_pkt.advance(tb_arg0:bv32);
procedure tb_pkt.emit(tb_arg0:tb_Ref);
function {:inline true}tb_register_data_record.read(tb_reg:[bv32]bv32, tb_index:bv32)returns (bv32) {tb_reg[tb_index]}
procedure {:inline 1} tb_register_data_record.write(tb_index:bv32, tb_value:bv32)
	modifies tb_register_data_record, tb_register_data_record__last0_old_value, tb_register_data_record__last0_value, tb_register_data_record__last_index, tb_register_data_record__last_old_value, tb_register_data_record__last_value, tb_register_data_record__last_write_site, tb_register_data_record__wrote_any, tb_register_data_record__wrote_index0;
{
    tb_register_data_record__last_old_value := tb_register_data_record[tb_index];
    tb_register_data_record[tb_index] := tb_value;
    tb_register_data_record__last_index := tb_index;
    tb_register_data_record__last_value := tb_value;
    tb_register_data_record__last_write_site := tb_register_data_record__next_write_site;
    tb_register_data_record__wrote_any := true;
    if (tb_index == 0bv32) {
        tb_register_data_record__wrote_index0 := true;
        tb_register_data_record__last0_old_value := tb_register_data_record__last_old_value;
        tb_register_data_record__last0_value := tb_value;
    }
}

// tb_RegisterAction tb_register_data_record_0_read_0.apply
procedure {:inline 1} tb_register_data_record_0_read_0.apply(tb_value_r_in:bv32, tb_read_value_in:bv32) returns (tb_value_r_out:bv32, tb_read_value_out:bv32)
{
    var tb_value_r:bv32;
    var tb_read_value:bv32;
    tb_value_r := tb_value_r_in;
    tb_read_value := tb_read_value_in;
    tb_read_value := tb_value_r;
    tb_value_r_out := tb_value_r;
    tb_read_value_out := tb_read_value;
}

// tb_RegisterAction tb_register_data_record_0_write_0.apply
procedure {:inline 1} tb_register_data_record_0_write_0.apply(tb_value_r_in:bv32) returns (tb_value_r_out:bv32)
{
    var tb_value_r:bv32;
    tb_value_r := tb_value_r_in;
    tb_value_r := tb_hdr.albion_data.data_0;
    tb_value_r_out := tb_value_r;
}

// tb_RegisterAction tb_register_data_record_10_read_0.apply
procedure {:inline 1} tb_register_data_record_10_read_0.apply(tb_value_r_in:bv32, tb_read_value_in:bv32) returns (tb_value_r_out:bv32, tb_read_value_out:bv32)
{
    var tb_value_r:bv32;
    var tb_read_value:bv32;
    tb_value_r := tb_value_r_in;
    tb_read_value := tb_read_value_in;
    tb_read_value := tb_value_r;
    tb_value_r_out := tb_value_r;
    tb_read_value_out := tb_read_value;
}

// tb_RegisterAction tb_register_data_record_10_write_0.apply
procedure {:inline 1} tb_register_data_record_10_write_0.apply(tb_value_r_in:bv32) returns (tb_value_r_out:bv32)
{
    var tb_value_r:bv32;
    tb_value_r := tb_value_r_in;
    tb_value_r := tb_hdr.albion_data.data_10;
    tb_value_r_out := tb_value_r;
}

// tb_RegisterAction tb_register_data_record_11_read_0.apply
procedure {:inline 1} tb_register_data_record_11_read_0.apply(tb_value_r_in:bv32, tb_read_value_in:bv32) returns (tb_value_r_out:bv32, tb_read_value_out:bv32)
{
    var tb_value_r:bv32;
    var tb_read_value:bv32;
    tb_value_r := tb_value_r_in;
    tb_read_value := tb_read_value_in;
    tb_read_value := tb_value_r;
    tb_value_r_out := tb_value_r;
    tb_read_value_out := tb_read_value;
}

// tb_RegisterAction tb_register_data_record_11_write_0.apply
procedure {:inline 1} tb_register_data_record_11_write_0.apply(tb_value_r_in:bv32) returns (tb_value_r_out:bv32)
{
    var tb_value_r:bv32;
    tb_value_r := tb_value_r_in;
    tb_value_r := tb_hdr.albion_data.data_11;
    tb_value_r_out := tb_value_r;
}
function {:inline true}tb_register_data_record_12.read(tb_reg:[bv32]bv32, tb_index:bv32)returns (bv32) {tb_reg[tb_index]}
procedure {:inline 1} tb_register_data_record_12.write(tb_index:bv32, tb_value:bv32)
	modifies tb_register_data_record_12, tb_register_data_record_12__last0_old_value, tb_register_data_record_12__last0_value, tb_register_data_record_12__last_index, tb_register_data_record_12__last_old_value, tb_register_data_record_12__last_value, tb_register_data_record_12__last_write_site, tb_register_data_record_12__wrote_any, tb_register_data_record_12__wrote_index0;
{
    tb_register_data_record_12__last_old_value := tb_register_data_record_12[tb_index];
    tb_register_data_record_12[tb_index] := tb_value;
    tb_register_data_record_12__last_index := tb_index;
    tb_register_data_record_12__last_value := tb_value;
    tb_register_data_record_12__last_write_site := tb_register_data_record_12__next_write_site;
    tb_register_data_record_12__wrote_any := true;
    if (tb_index == 0bv32) {
        tb_register_data_record_12__wrote_index0 := true;
        tb_register_data_record_12__last0_old_value := tb_register_data_record_12__last_old_value;
        tb_register_data_record_12__last0_value := tb_value;
    }
}
function {:inline true}tb_register_data_record_13.read(tb_reg:[bv32]bv32, tb_index:bv32)returns (bv32) {tb_reg[tb_index]}
procedure {:inline 1} tb_register_data_record_13.write(tb_index:bv32, tb_value:bv32)
	modifies tb_register_data_record_13, tb_register_data_record_13__last0_old_value, tb_register_data_record_13__last0_value, tb_register_data_record_13__last_index, tb_register_data_record_13__last_old_value, tb_register_data_record_13__last_value, tb_register_data_record_13__last_write_site, tb_register_data_record_13__wrote_any, tb_register_data_record_13__wrote_index0;
{
    tb_register_data_record_13__last_old_value := tb_register_data_record_13[tb_index];
    tb_register_data_record_13[tb_index] := tb_value;
    tb_register_data_record_13__last_index := tb_index;
    tb_register_data_record_13__last_value := tb_value;
    tb_register_data_record_13__last_write_site := tb_register_data_record_13__next_write_site;
    tb_register_data_record_13__wrote_any := true;
    if (tb_index == 0bv32) {
        tb_register_data_record_13__wrote_index0 := true;
        tb_register_data_record_13__last0_old_value := tb_register_data_record_13__last_old_value;
        tb_register_data_record_13__last0_value := tb_value;
    }
}
function {:inline true}tb_register_data_record_14.read(tb_reg:[bv32]bv32, tb_index:bv32)returns (bv32) {tb_reg[tb_index]}
procedure {:inline 1} tb_register_data_record_14.write(tb_index:bv32, tb_value:bv32)
	modifies tb_register_data_record_14, tb_register_data_record_14__last0_old_value, tb_register_data_record_14__last0_value, tb_register_data_record_14__last_index, tb_register_data_record_14__last_old_value, tb_register_data_record_14__last_value, tb_register_data_record_14__last_write_site, tb_register_data_record_14__wrote_any, tb_register_data_record_14__wrote_index0;
{
    tb_register_data_record_14__last_old_value := tb_register_data_record_14[tb_index];
    tb_register_data_record_14[tb_index] := tb_value;
    tb_register_data_record_14__last_index := tb_index;
    tb_register_data_record_14__last_value := tb_value;
    tb_register_data_record_14__last_write_site := tb_register_data_record_14__next_write_site;
    tb_register_data_record_14__wrote_any := true;
    if (tb_index == 0bv32) {
        tb_register_data_record_14__wrote_index0 := true;
        tb_register_data_record_14__last0_old_value := tb_register_data_record_14__last_old_value;
        tb_register_data_record_14__last0_value := tb_value;
    }
}
function {:inline true}tb_register_data_record_15.read(tb_reg:[bv32]bv32, tb_index:bv32)returns (bv32) {tb_reg[tb_index]}
procedure {:inline 1} tb_register_data_record_15.write(tb_index:bv32, tb_value:bv32)
	modifies tb_register_data_record_15, tb_register_data_record_15__last0_old_value, tb_register_data_record_15__last0_value, tb_register_data_record_15__last_index, tb_register_data_record_15__last_old_value, tb_register_data_record_15__last_value, tb_register_data_record_15__last_write_site, tb_register_data_record_15__wrote_any, tb_register_data_record_15__wrote_index0;
{
    tb_register_data_record_15__last_old_value := tb_register_data_record_15[tb_index];
    tb_register_data_record_15[tb_index] := tb_value;
    tb_register_data_record_15__last_index := tb_index;
    tb_register_data_record_15__last_value := tb_value;
    tb_register_data_record_15__last_write_site := tb_register_data_record_15__next_write_site;
    tb_register_data_record_15__wrote_any := true;
    if (tb_index == 0bv32) {
        tb_register_data_record_15__wrote_index0 := true;
        tb_register_data_record_15__last0_old_value := tb_register_data_record_15__last_old_value;
        tb_register_data_record_15__last0_value := tb_value;
    }
}
function {:inline true}tb_register_data_record_16.read(tb_reg:[bv32]bv32, tb_index:bv32)returns (bv32) {tb_reg[tb_index]}
procedure {:inline 1} tb_register_data_record_16.write(tb_index:bv32, tb_value:bv32)
	modifies tb_register_data_record_16, tb_register_data_record_16__last0_old_value, tb_register_data_record_16__last0_value, tb_register_data_record_16__last_index, tb_register_data_record_16__last_old_value, tb_register_data_record_16__last_value, tb_register_data_record_16__last_write_site, tb_register_data_record_16__wrote_any, tb_register_data_record_16__wrote_index0;
{
    tb_register_data_record_16__last_old_value := tb_register_data_record_16[tb_index];
    tb_register_data_record_16[tb_index] := tb_value;
    tb_register_data_record_16__last_index := tb_index;
    tb_register_data_record_16__last_value := tb_value;
    tb_register_data_record_16__last_write_site := tb_register_data_record_16__next_write_site;
    tb_register_data_record_16__wrote_any := true;
    if (tb_index == 0bv32) {
        tb_register_data_record_16__wrote_index0 := true;
        tb_register_data_record_16__last0_old_value := tb_register_data_record_16__last_old_value;
        tb_register_data_record_16__last0_value := tb_value;
    }
}
function {:inline true}tb_register_data_record_17.read(tb_reg:[bv32]bv32, tb_index:bv32)returns (bv32) {tb_reg[tb_index]}
procedure {:inline 1} tb_register_data_record_17.write(tb_index:bv32, tb_value:bv32)
	modifies tb_register_data_record_17, tb_register_data_record_17__last0_old_value, tb_register_data_record_17__last0_value, tb_register_data_record_17__last_index, tb_register_data_record_17__last_old_value, tb_register_data_record_17__last_value, tb_register_data_record_17__last_write_site, tb_register_data_record_17__wrote_any, tb_register_data_record_17__wrote_index0;
{
    tb_register_data_record_17__last_old_value := tb_register_data_record_17[tb_index];
    tb_register_data_record_17[tb_index] := tb_value;
    tb_register_data_record_17__last_index := tb_index;
    tb_register_data_record_17__last_value := tb_value;
    tb_register_data_record_17__last_write_site := tb_register_data_record_17__next_write_site;
    tb_register_data_record_17__wrote_any := true;
    if (tb_index == 0bv32) {
        tb_register_data_record_17__wrote_index0 := true;
        tb_register_data_record_17__last0_old_value := tb_register_data_record_17__last_old_value;
        tb_register_data_record_17__last0_value := tb_value;
    }
}
function {:inline true}tb_register_data_record_18.read(tb_reg:[bv32]bv32, tb_index:bv32)returns (bv32) {tb_reg[tb_index]}
procedure {:inline 1} tb_register_data_record_18.write(tb_index:bv32, tb_value:bv32)
	modifies tb_register_data_record_18, tb_register_data_record_18__last0_old_value, tb_register_data_record_18__last0_value, tb_register_data_record_18__last_index, tb_register_data_record_18__last_old_value, tb_register_data_record_18__last_value, tb_register_data_record_18__last_write_site, tb_register_data_record_18__wrote_any, tb_register_data_record_18__wrote_index0;
{
    tb_register_data_record_18__last_old_value := tb_register_data_record_18[tb_index];
    tb_register_data_record_18[tb_index] := tb_value;
    tb_register_data_record_18__last_index := tb_index;
    tb_register_data_record_18__last_value := tb_value;
    tb_register_data_record_18__last_write_site := tb_register_data_record_18__next_write_site;
    tb_register_data_record_18__wrote_any := true;
    if (tb_index == 0bv32) {
        tb_register_data_record_18__wrote_index0 := true;
        tb_register_data_record_18__last0_old_value := tb_register_data_record_18__last_old_value;
        tb_register_data_record_18__last0_value := tb_value;
    }
}
function {:inline true}tb_register_data_record_19.read(tb_reg:[bv32]bv32, tb_index:bv32)returns (bv32) {tb_reg[tb_index]}
procedure {:inline 1} tb_register_data_record_19.write(tb_index:bv32, tb_value:bv32)
	modifies tb_register_data_record_19, tb_register_data_record_19__last0_old_value, tb_register_data_record_19__last0_value, tb_register_data_record_19__last_index, tb_register_data_record_19__last_old_value, tb_register_data_record_19__last_value, tb_register_data_record_19__last_write_site, tb_register_data_record_19__wrote_any, tb_register_data_record_19__wrote_index0;
{
    tb_register_data_record_19__last_old_value := tb_register_data_record_19[tb_index];
    tb_register_data_record_19[tb_index] := tb_value;
    tb_register_data_record_19__last_index := tb_index;
    tb_register_data_record_19__last_value := tb_value;
    tb_register_data_record_19__last_write_site := tb_register_data_record_19__next_write_site;
    tb_register_data_record_19__wrote_any := true;
    if (tb_index == 0bv32) {
        tb_register_data_record_19__wrote_index0 := true;
        tb_register_data_record_19__last0_old_value := tb_register_data_record_19__last_old_value;
        tb_register_data_record_19__last0_value := tb_value;
    }
}

// tb_RegisterAction tb_register_data_record_1_read_0.apply
procedure {:inline 1} tb_register_data_record_1_read_0.apply(tb_value_r_in:bv32, tb_read_value_in:bv32) returns (tb_value_r_out:bv32, tb_read_value_out:bv32)
{
    var tb_value_r:bv32;
    var tb_read_value:bv32;
    tb_value_r := tb_value_r_in;
    tb_read_value := tb_read_value_in;
    tb_read_value := tb_value_r;
    tb_value_r_out := tb_value_r;
    tb_read_value_out := tb_read_value;
}

// tb_RegisterAction tb_register_data_record_1_write_0.apply
procedure {:inline 1} tb_register_data_record_1_write_0.apply(tb_value_r_in:bv32) returns (tb_value_r_out:bv32)
{
    var tb_value_r:bv32;
    tb_value_r := tb_value_r_in;
    tb_value_r := tb_hdr.albion_data.data_1;
    tb_value_r_out := tb_value_r;
}
function {:inline true}tb_register_data_record_20.read(tb_reg:[bv32]bv32, tb_index:bv32)returns (bv32) {tb_reg[tb_index]}
procedure {:inline 1} tb_register_data_record_20.write(tb_index:bv32, tb_value:bv32)
	modifies tb_register_data_record_20, tb_register_data_record_20__last0_old_value, tb_register_data_record_20__last0_value, tb_register_data_record_20__last_index, tb_register_data_record_20__last_old_value, tb_register_data_record_20__last_value, tb_register_data_record_20__last_write_site, tb_register_data_record_20__wrote_any, tb_register_data_record_20__wrote_index0;
{
    tb_register_data_record_20__last_old_value := tb_register_data_record_20[tb_index];
    tb_register_data_record_20[tb_index] := tb_value;
    tb_register_data_record_20__last_index := tb_index;
    tb_register_data_record_20__last_value := tb_value;
    tb_register_data_record_20__last_write_site := tb_register_data_record_20__next_write_site;
    tb_register_data_record_20__wrote_any := true;
    if (tb_index == 0bv32) {
        tb_register_data_record_20__wrote_index0 := true;
        tb_register_data_record_20__last0_old_value := tb_register_data_record_20__last_old_value;
        tb_register_data_record_20__last0_value := tb_value;
    }
}
function {:inline true}tb_register_data_record_21.read(tb_reg:[bv32]bv32, tb_index:bv32)returns (bv32) {tb_reg[tb_index]}
procedure {:inline 1} tb_register_data_record_21.write(tb_index:bv32, tb_value:bv32)
	modifies tb_register_data_record_21, tb_register_data_record_21__last0_old_value, tb_register_data_record_21__last0_value, tb_register_data_record_21__last_index, tb_register_data_record_21__last_old_value, tb_register_data_record_21__last_value, tb_register_data_record_21__last_write_site, tb_register_data_record_21__wrote_any, tb_register_data_record_21__wrote_index0;
{
    tb_register_data_record_21__last_old_value := tb_register_data_record_21[tb_index];
    tb_register_data_record_21[tb_index] := tb_value;
    tb_register_data_record_21__last_index := tb_index;
    tb_register_data_record_21__last_value := tb_value;
    tb_register_data_record_21__last_write_site := tb_register_data_record_21__next_write_site;
    tb_register_data_record_21__wrote_any := true;
    if (tb_index == 0bv32) {
        tb_register_data_record_21__wrote_index0 := true;
        tb_register_data_record_21__last0_old_value := tb_register_data_record_21__last_old_value;
        tb_register_data_record_21__last0_value := tb_value;
    }
}
function {:inline true}tb_register_data_record_22.read(tb_reg:[bv32]bv32, tb_index:bv32)returns (bv32) {tb_reg[tb_index]}
procedure {:inline 1} tb_register_data_record_22.write(tb_index:bv32, tb_value:bv32)
	modifies tb_register_data_record_22, tb_register_data_record_22__last0_old_value, tb_register_data_record_22__last0_value, tb_register_data_record_22__last_index, tb_register_data_record_22__last_old_value, tb_register_data_record_22__last_value, tb_register_data_record_22__last_write_site, tb_register_data_record_22__wrote_any, tb_register_data_record_22__wrote_index0;
{
    tb_register_data_record_22__last_old_value := tb_register_data_record_22[tb_index];
    tb_register_data_record_22[tb_index] := tb_value;
    tb_register_data_record_22__last_index := tb_index;
    tb_register_data_record_22__last_value := tb_value;
    tb_register_data_record_22__last_write_site := tb_register_data_record_22__next_write_site;
    tb_register_data_record_22__wrote_any := true;
    if (tb_index == 0bv32) {
        tb_register_data_record_22__wrote_index0 := true;
        tb_register_data_record_22__last0_old_value := tb_register_data_record_22__last_old_value;
        tb_register_data_record_22__last0_value := tb_value;
    }
}

// tb_RegisterAction tb_register_data_record_2_read_0.apply
procedure {:inline 1} tb_register_data_record_2_read_0.apply(tb_value_r_in:bv32, tb_read_value_in:bv32) returns (tb_value_r_out:bv32, tb_read_value_out:bv32)
{
    var tb_value_r:bv32;
    var tb_read_value:bv32;
    tb_value_r := tb_value_r_in;
    tb_read_value := tb_read_value_in;
    tb_read_value := tb_value_r;
    tb_value_r_out := tb_value_r;
    tb_read_value_out := tb_read_value;
}

// tb_RegisterAction tb_register_data_record_2_write_0.apply
procedure {:inline 1} tb_register_data_record_2_write_0.apply(tb_value_r_in:bv32) returns (tb_value_r_out:bv32)
{
    var tb_value_r:bv32;
    tb_value_r := tb_value_r_in;
    tb_value_r := tb_hdr.albion_data.data_2;
    tb_value_r_out := tb_value_r;
}

// tb_RegisterAction tb_register_data_record_3_read_0.apply
procedure {:inline 1} tb_register_data_record_3_read_0.apply(tb_value_r_in:bv32, tb_read_value_in:bv32) returns (tb_value_r_out:bv32, tb_read_value_out:bv32)
{
    var tb_value_r:bv32;
    var tb_read_value:bv32;
    tb_value_r := tb_value_r_in;
    tb_read_value := tb_read_value_in;
    tb_read_value := tb_value_r;
    tb_value_r_out := tb_value_r;
    tb_read_value_out := tb_read_value;
}

// tb_RegisterAction tb_register_data_record_3_write_0.apply
procedure {:inline 1} tb_register_data_record_3_write_0.apply(tb_value_r_in:bv32) returns (tb_value_r_out:bv32)
{
    var tb_value_r:bv32;
    tb_value_r := tb_value_r_in;
    tb_value_r := tb_hdr.albion_data.data_3;
    tb_value_r_out := tb_value_r;
}

// tb_RegisterAction tb_register_data_record_4_read_0.apply
procedure {:inline 1} tb_register_data_record_4_read_0.apply(tb_value_r_in:bv32, tb_read_value_in:bv32) returns (tb_value_r_out:bv32, tb_read_value_out:bv32)
{
    var tb_value_r:bv32;
    var tb_read_value:bv32;
    tb_value_r := tb_value_r_in;
    tb_read_value := tb_read_value_in;
    tb_read_value := tb_value_r;
    tb_value_r_out := tb_value_r;
    tb_read_value_out := tb_read_value;
}

// tb_RegisterAction tb_register_data_record_4_write_0.apply
procedure {:inline 1} tb_register_data_record_4_write_0.apply(tb_value_r_in:bv32) returns (tb_value_r_out:bv32)
{
    var tb_value_r:bv32;
    tb_value_r := tb_value_r_in;
    tb_value_r := tb_hdr.albion_data.data_4;
    tb_value_r_out := tb_value_r;
}

// tb_RegisterAction tb_register_data_record_5_read_0.apply
procedure {:inline 1} tb_register_data_record_5_read_0.apply(tb_value_r_in:bv32, tb_read_value_in:bv32) returns (tb_value_r_out:bv32, tb_read_value_out:bv32)
{
    var tb_value_r:bv32;
    var tb_read_value:bv32;
    tb_value_r := tb_value_r_in;
    tb_read_value := tb_read_value_in;
    tb_read_value := tb_value_r;
    tb_value_r_out := tb_value_r;
    tb_read_value_out := tb_read_value;
}

// tb_RegisterAction tb_register_data_record_5_write_0.apply
procedure {:inline 1} tb_register_data_record_5_write_0.apply(tb_value_r_in:bv32) returns (tb_value_r_out:bv32)
{
    var tb_value_r:bv32;
    tb_value_r := tb_value_r_in;
    tb_value_r := tb_hdr.albion_data.data_5;
    tb_value_r_out := tb_value_r;
}

// tb_RegisterAction tb_register_data_record_6_read_0.apply
procedure {:inline 1} tb_register_data_record_6_read_0.apply(tb_value_r_in:bv32, tb_read_value_in:bv32) returns (tb_value_r_out:bv32, tb_read_value_out:bv32)
{
    var tb_value_r:bv32;
    var tb_read_value:bv32;
    tb_value_r := tb_value_r_in;
    tb_read_value := tb_read_value_in;
    tb_read_value := tb_value_r;
    tb_value_r_out := tb_value_r;
    tb_read_value_out := tb_read_value;
}

// tb_RegisterAction tb_register_data_record_6_write_0.apply
procedure {:inline 1} tb_register_data_record_6_write_0.apply(tb_value_r_in:bv32) returns (tb_value_r_out:bv32)
{
    var tb_value_r:bv32;
    tb_value_r := tb_value_r_in;
    tb_value_r := tb_hdr.albion_data.data_6;
    tb_value_r_out := tb_value_r;
}

// tb_RegisterAction tb_register_data_record_7_read_0.apply
procedure {:inline 1} tb_register_data_record_7_read_0.apply(tb_value_r_in:bv32, tb_read_value_in:bv32) returns (tb_value_r_out:bv32, tb_read_value_out:bv32)
{
    var tb_value_r:bv32;
    var tb_read_value:bv32;
    tb_value_r := tb_value_r_in;
    tb_read_value := tb_read_value_in;
    tb_read_value := tb_value_r;
    tb_value_r_out := tb_value_r;
    tb_read_value_out := tb_read_value;
}

// tb_RegisterAction tb_register_data_record_7_write_0.apply
procedure {:inline 1} tb_register_data_record_7_write_0.apply(tb_value_r_in:bv32) returns (tb_value_r_out:bv32)
{
    var tb_value_r:bv32;
    tb_value_r := tb_value_r_in;
    tb_value_r := tb_hdr.albion_data.data_7;
    tb_value_r_out := tb_value_r;
}

// tb_RegisterAction tb_register_data_record_8_read_0.apply
procedure {:inline 1} tb_register_data_record_8_read_0.apply(tb_value_r_in:bv32, tb_read_value_in:bv32) returns (tb_value_r_out:bv32, tb_read_value_out:bv32)
{
    var tb_value_r:bv32;
    var tb_read_value:bv32;
    tb_value_r := tb_value_r_in;
    tb_read_value := tb_read_value_in;
    tb_read_value := tb_value_r;
    tb_value_r_out := tb_value_r;
    tb_read_value_out := tb_read_value;
}

// tb_RegisterAction tb_register_data_record_8_write_0.apply
procedure {:inline 1} tb_register_data_record_8_write_0.apply(tb_value_r_in:bv32) returns (tb_value_r_out:bv32)
{
    var tb_value_r:bv32;
    tb_value_r := tb_value_r_in;
    tb_value_r := tb_hdr.albion_data.data_8;
    tb_value_r_out := tb_value_r;
}

// tb_RegisterAction tb_register_data_record_9_read_0.apply
procedure {:inline 1} tb_register_data_record_9_read_0.apply(tb_value_r_in:bv32, tb_read_value_in:bv32) returns (tb_value_r_out:bv32, tb_read_value_out:bv32)
{
    var tb_value_r:bv32;
    var tb_read_value:bv32;
    tb_value_r := tb_value_r_in;
    tb_read_value := tb_read_value_in;
    tb_read_value := tb_value_r;
    tb_value_r_out := tb_value_r;
    tb_read_value_out := tb_read_value;
}

// tb_RegisterAction tb_register_data_record_9_write_0.apply
procedure {:inline 1} tb_register_data_record_9_write_0.apply(tb_value_r_in:bv32) returns (tb_value_r_out:bv32)
{
    var tb_value_r:bv32;
    tb_value_r := tb_value_r_in;
    tb_value_r := tb_hdr.albion_data.data_9;
    tb_value_r_out := tb_value_r;
}
procedure tb_reject();
    ensures tb_drop==true;
	modifies tb_drop;
procedure {:inline 1} tb_setInvalid(tb_header:tb_Ref);
    ensures (tb_isValid[tb_header] == false);
	modifies tb_isValid;
procedure {:inline 1} tb_setValid(tb_header:tb_Ref);

// tb_Table tb_table_dst_cs
procedure {:inline 1} tb_table_dst_cs.apply()
	modifies tb_hdr.albion.CS_id_1, tb_meta.session_id, tb_table_dst_cs.action_run, tb_table_dst_cs.hit;
{
    tb_hdr.albion.CS_id_1 := tb_hdr.albion.CS_id_1;
    tb_table_dst_cs.hit := false;
    if(tb_hdr.albion.CS_id_1 == 1bv32){
        tb_table_dst_cs.hit := true;
        tb_table_dst_cs.action_run := tb_table_dst_cs.action.action_dst_cs_1;
        call tb_action_dst_cs_1();
        goto tb_Exit;
    }
    else if(tb_hdr.albion.CS_id_1 == 2bv32){
        tb_table_dst_cs.hit := true;
        tb_table_dst_cs.action_run := tb_table_dst_cs.action.action_dst_cs_4;
        call tb_action_dst_cs_4();
        goto tb_Exit;
    }
    else if(tb_hdr.albion.CS_id_1 == 3bv32){
        tb_table_dst_cs.hit := true;
        tb_table_dst_cs.action_run := tb_table_dst_cs.action.action_dst_cs_9;
        call tb_action_dst_cs_9();
        goto tb_Exit;
    }
    else if(tb_hdr.albion.CS_id_1 == 4bv32){
        tb_table_dst_cs.hit := true;
        tb_table_dst_cs.action_run := tb_table_dst_cs.action.action_dst_cs_12;
        call tb_action_dst_cs_12();
        goto tb_Exit;
    }
    else if(tb_hdr.albion.CS_id_1 == 10bv32){
        tb_table_dst_cs.hit := true;
        tb_table_dst_cs.action_run := tb_table_dst_cs.action.action_dst_cs_12;
        call tb_action_dst_cs_12();
        goto tb_Exit;
    }
    if(!tb_table_dst_cs.hit){
        tb_table_dst_cs.action_run := tb_table_dst_cs.action.action_dst_cs_1;
        call tb_action_dst_cs_1();
        goto tb_Exit;
    }

    tb_Exit:
}

// tb_Table tb_table_dst_cs_0
procedure {:inline 1} tb_table_dst_cs_0.apply()
	modifies tb_hdr.albion.CS_id_2, tb_meta.session_id, tb_table_dst_cs_0.action_run, tb_table_dst_cs_0.hit;
{
    tb_hdr.albion.CS_id_2 := tb_hdr.albion.CS_id_2;
    tb_table_dst_cs_0.hit := false;
    if(tb_hdr.albion.CS_id_2 == 1bv32){
        tb_table_dst_cs_0.hit := true;
        tb_table_dst_cs_0.action_run := tb_table_dst_cs_0.action.action_dst_cs_2;
        call tb_action_dst_cs_2();
        goto tb_Exit;
    }
    else if(tb_hdr.albion.CS_id_2 == 2bv32){
        tb_table_dst_cs_0.hit := true;
        tb_table_dst_cs_0.action_run := tb_table_dst_cs_0.action.action_dst_cs_7;
        call tb_action_dst_cs_7();
        goto tb_Exit;
    }
    else if(tb_hdr.albion.CS_id_2 == 3bv32){
        tb_table_dst_cs_0.hit := true;
        tb_table_dst_cs_0.action_run := tb_table_dst_cs_0.action.action_dst_cs_10;
        call tb_action_dst_cs_10();
        goto tb_Exit;
    }
    else if(tb_hdr.albion.CS_id_2 == 4bv32){
        tb_table_dst_cs_0.hit := true;
        tb_table_dst_cs_0.action_run := tb_table_dst_cs_0.action.action_dst_cs_13;
        call tb_action_dst_cs_13();
        goto tb_Exit;
    }
    else if(tb_hdr.albion.CS_id_2 == 10bv32){
        tb_table_dst_cs_0.hit := true;
        tb_table_dst_cs_0.action_run := tb_table_dst_cs_0.action.action_dst_cs_13;
        call tb_action_dst_cs_13();
        goto tb_Exit;
    }
    if(!tb_table_dst_cs_0.hit){
        tb_table_dst_cs_0.action_run := tb_table_dst_cs_0.action.action_dst_cs_2;
        call tb_action_dst_cs_2();
        goto tb_Exit;
    }

    tb_Exit:
}

// tb_Table tb_table_dst_cs_3
procedure {:inline 1} tb_table_dst_cs_3.apply()
	modifies tb_hdr.albion.CS_id_3, tb_meta.session_id, tb_table_dst_cs_3.action_run, tb_table_dst_cs_3.hit;
{
    tb_hdr.albion.CS_id_3 := tb_hdr.albion.CS_id_3;
    tb_table_dst_cs_3.hit := false;
    if(tb_hdr.albion.CS_id_3 == 1bv32){
        tb_table_dst_cs_3.hit := true;
        tb_table_dst_cs_3.action_run := tb_table_dst_cs_3.action.action_dst_cs_3;
        call tb_action_dst_cs_3();
        goto tb_Exit;
    }
    else if(tb_hdr.albion.CS_id_3 == 2bv32){
        tb_table_dst_cs_3.hit := true;
        tb_table_dst_cs_3.action_run := tb_table_dst_cs_3.action.action_dst_cs_8;
        call tb_action_dst_cs_8();
        goto tb_Exit;
    }
    else if(tb_hdr.albion.CS_id_3 == 3bv32){
        tb_table_dst_cs_3.hit := true;
        tb_table_dst_cs_3.action_run := tb_table_dst_cs_3.action.action_dst_cs_11;
        call tb_action_dst_cs_11();
        goto tb_Exit;
    }
    else if(tb_hdr.albion.CS_id_3 == 4bv32){
        tb_table_dst_cs_3.hit := true;
        tb_table_dst_cs_3.action_run := tb_table_dst_cs_3.action.action_dst_cs_14;
        call tb_action_dst_cs_14();
        goto tb_Exit;
    }
    else if(tb_hdr.albion.CS_id_3 == 10bv32){
        tb_table_dst_cs_3.hit := true;
        tb_table_dst_cs_3.action_run := tb_table_dst_cs_3.action.action_dst_cs_14;
        call tb_action_dst_cs_14();
        goto tb_Exit;
    }
    if(!tb_table_dst_cs_3.hit){
        tb_table_dst_cs_3.action_run := tb_table_dst_cs_3.action.action_dst_cs_3;
        call tb_action_dst_cs_3();
        goto tb_Exit;
    }

    tb_Exit:
}
// ===== END NODE tb =====

// ===== BEGIN ENQUEUE PROCEDURES =====
procedure ta__enqueue_tb() returns()
  modifies tb_hdr.albion.CS_id_1, tb_hdr.albion.CS_id_2, tb_hdr.albion.CS_id_3, tb_hdr.albion.CS_offset_1, tb_hdr.albion.CS_offset_2, tb_hdr.albion.CS_offset_3, tb_hdr.albion.address_h, tb_hdr.albion.address_l, tb_hdr.albion.index, tb_hdr.albion.num, tb_hdr.albion.operation, tb_hdr.albion.port, tb_hdr.albion.request_id_high, tb_hdr.albion.request_id_low, tb_hdr.albion.time, tb_hdr.albion.valid, tb_hdr.albion_data.valid, tb_hdr.albion_timer.address_high_0, tb_hdr.albion_timer.address_high_1, tb_hdr.albion_timer.address_high_2, tb_hdr.albion_timer.address_high_3, tb_hdr.albion_timer.address_low_0, tb_hdr.albion_timer.address_low_1, tb_hdr.albion_timer.address_low_2, tb_hdr.albion_timer.address_low_3, tb_hdr.albion_timer.const_time, tb_hdr.albion_timer.state_0, tb_hdr.albion_timer.state_1, tb_hdr.albion_timer.state_2, tb_hdr.albion_timer.state_3, tb_hdr.albion_timer.times, tb_hdr.albion_timer.valid, tb_hdr.ethernet.ether_type, tb_hdr.ethernet.valid, tb_inbox_count, tb_pkt_external;
{
  assume tb_inbox_count < 1;
  tb_hdr.ethernet.valid := ta_hdr.ethernet.valid;
  tb_hdr.ethernet.ether_type := ta_hdr.ethernet.ether_type;
  tb_hdr.albion.valid := ta_hdr.albion.valid;
  tb_hdr.albion.request_id_high := ta_hdr.albion.request_id_high;
  tb_hdr.albion.request_id_low := ta_hdr.albion.request_id_low;
  tb_hdr.albion.operation := ta_hdr.albion.operation;
  tb_hdr.albion.address_h := ta_hdr.albion.address_h;
  tb_hdr.albion.address_l := ta_hdr.albion.address_l;
  tb_hdr.albion.time := ta_hdr.albion.time;
  tb_hdr.albion.num := ta_hdr.albion.num;
  tb_hdr.albion.index := ta_hdr.albion.index;
  tb_hdr.albion.CS_id_1 := ta_hdr.albion.CS_id_1;
  tb_hdr.albion.CS_offset_1 := ta_hdr.albion.CS_offset_1;
  tb_hdr.albion.CS_id_2 := ta_hdr.albion.CS_id_2;
  tb_hdr.albion.CS_offset_2 := ta_hdr.albion.CS_offset_2;
  tb_hdr.albion.CS_id_3 := ta_hdr.albion.CS_id_3;
  tb_hdr.albion.CS_offset_3 := ta_hdr.albion.CS_offset_3;
  tb_hdr.albion.port := ta_hdr.albion.port;
  tb_hdr.albion_data.valid := ta_hdr.albion_data.valid;
  tb_hdr.albion_timer.valid := ta_hdr.albion_timer.valid;
  tb_hdr.albion_timer.times := ta_hdr.albion_timer.times;
  tb_hdr.albion_timer.const_time := ta_hdr.albion_timer.const_time;
  tb_hdr.albion_timer.address_high_0 := ta_hdr.albion_timer.address_high_0;
  tb_hdr.albion_timer.address_low_0 := ta_hdr.albion_timer.address_low_0;
  tb_hdr.albion_timer.state_0 := ta_hdr.albion_timer.state_0;
  tb_hdr.albion_timer.address_high_1 := ta_hdr.albion_timer.address_high_1;
  tb_hdr.albion_timer.address_low_1 := ta_hdr.albion_timer.address_low_1;
  tb_hdr.albion_timer.state_1 := ta_hdr.albion_timer.state_1;
  tb_hdr.albion_timer.address_high_2 := ta_hdr.albion_timer.address_high_2;
  tb_hdr.albion_timer.address_low_2 := ta_hdr.albion_timer.address_low_2;
  tb_hdr.albion_timer.state_2 := ta_hdr.albion_timer.state_2;
  tb_hdr.albion_timer.address_high_3 := ta_hdr.albion_timer.address_high_3;
  tb_hdr.albion_timer.address_low_3 := ta_hdr.albion_timer.address_low_3;
  tb_hdr.albion_timer.state_3 := ta_hdr.albion_timer.state_3;
  tb_pkt_external := false;
  tb_inbox_count := tb_inbox_count + 1;
}

// ===== END ENQUEUE PROCEDURES =====

// ===== BEGIN HARNESS =====
// Auto-generated by Procurator (DSL -> Boogie harness: sequential scheduler)
// Message abstraction: Bag(K=1) using inbox_count per node; single-slot mailbox for packet fields

var procurator_step: int;
var procurator_bad: bool;

// DSL state variables (modeled as Boogie globals)
var dsl_client_seen: int;
var dsl_pending: int;
var dsl_phase: int;
var dsl_steps: int;

var ta_inbox_count: int;
var tb_inbox_count: int;
var io_inbox_count: int;

var ta_pkt_external: bool;
var tb_pkt_external: bool;
var io_pkt_external: bool;

// Host packet fields (mirrors connected node symbols)
var io_hdr.ethernet.valid: bool;
var io_hdr.ethernet.ether_type: bv16;
var io_hdr.albion.valid: bool;
var io_hdr.albion.request_id_high: bv32;
var io_hdr.albion.request_id_low: bv32;
var io_hdr.albion.operation: bv32;
var io_hdr.albion.address_h: bv32;
var io_hdr.albion.address_l: bv32;
var io_hdr.albion.time: bv32;
var io_hdr.albion.num: bv32;
var io_hdr.albion.index: bv32;
var io_hdr.albion.CS_id_1: bv32;
var io_hdr.albion.CS_offset_1: bv32;
var io_hdr.albion.CS_id_2: bv32;
var io_hdr.albion.CS_offset_2: bv32;
var io_hdr.albion.CS_id_3: bv32;
var io_hdr.albion.CS_offset_3: bv32;
var io_hdr.albion.port: bv16;
var io_hdr.albion_data.valid: bool;
var io_hdr.albion_timer.valid: bool;
var io_hdr.albion_timer.times: bv32;
var io_hdr.albion_timer.const_time: bv32;
var io_hdr.albion_timer.address_high_0: bv32;
var io_hdr.albion_timer.address_low_0: bv32;
var io_hdr.albion_timer.state_0: bv32;
var io_hdr.albion_timer.address_high_1: bv32;
var io_hdr.albion_timer.address_low_1: bv32;
var io_hdr.albion_timer.state_1: bv32;
var io_hdr.albion_timer.address_high_2: bv32;
var io_hdr.albion_timer.address_low_2: bv32;
var io_hdr.albion_timer.state_2: bv32;
var io_hdr.albion_timer.address_high_3: bv32;
var io_hdr.albion_timer.address_low_3: bv32;
var io_hdr.albion_timer.state_3: bv32;
var io_meta.state: bv32;
var io_meta.state_sub: bv32;
var io_meta.session_id: ta_MirrorId_t;
var io_meta.no_use: bv8;
var io_eg_dprsr_md.mirror_type: ta_MirrorType_t;

// Forwarding (derived from DSL topology)
procedure ta_Forward() returns()
  modifies ta_inbox_count, ta_pkt_external, tb_hdr.albion.CS_id_1, tb_hdr.albion.CS_id_2, tb_hdr.albion.CS_id_3, tb_hdr.albion.CS_offset_1, tb_hdr.albion.CS_offset_2, tb_hdr.albion.CS_offset_3, tb_hdr.albion.address_h, tb_hdr.albion.address_l, tb_hdr.albion.index, tb_hdr.albion.num, tb_hdr.albion.operation, tb_hdr.albion.port, tb_hdr.albion.request_id_high, tb_hdr.albion.request_id_low, tb_hdr.albion.time, tb_hdr.albion.valid, tb_hdr.albion_data.valid, tb_hdr.albion_timer.address_high_0, tb_hdr.albion_timer.address_high_1, tb_hdr.albion_timer.address_high_2, tb_hdr.albion_timer.address_high_3, tb_hdr.albion_timer.address_low_0, tb_hdr.albion_timer.address_low_1, tb_hdr.albion_timer.address_low_2, tb_hdr.albion_timer.address_low_3, tb_hdr.albion_timer.const_time, tb_hdr.albion_timer.state_0, tb_hdr.albion_timer.state_1, tb_hdr.albion_timer.state_2, tb_hdr.albion_timer.state_3, tb_hdr.albion_timer.times, tb_hdr.albion_timer.valid, tb_hdr.ethernet.ether_type, tb_hdr.ethernet.valid, tb_inbox_count, tb_pkt_external;
{
  // If no forwarding decision was made, do nothing.
  if (ta_ig_tm_md.ucast_egress_port == 0bv9) {
    return;
  }

  // Tofino recirculate: magic egress ports map to self-enqueue.
  if (ta_ig_tm_md.ucast_egress_port == 68bv9) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
    return;
  }
  if (ta_ig_tm_md.ucast_egress_port == 196bv9) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
    return;
  }

  // wildcard forwarding (ALL): broadcast to all configured downstream mailboxes.
  call ta__enqueue_tb();
  return;
}

procedure tb_Forward() returns()
  modifies tb_inbox_count, tb_pkt_external;
{
  // If no forwarding decision was made, do nothing.
  if (tb_ig_tm_md.ucast_egress_port == 0bv9) {
    return;
  }

  // Tofino recirculate: magic egress ports map to self-enqueue.
  if (tb_ig_tm_md.ucast_egress_port == 68bv9) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
    return;
  }
  if (tb_ig_tm_md.ucast_egress_port == 196bv9) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure mainProcedure() returns()
  modifies dsl_client_seen, dsl_pending, dsl_phase, dsl_steps, io_eg_dprsr_md.mirror_type, io_hdr.albion.CS_id_1, io_hdr.albion.CS_id_2, io_hdr.albion.CS_id_3, io_hdr.albion.CS_offset_1, io_hdr.albion.CS_offset_2, io_hdr.albion.CS_offset_3, io_hdr.albion.address_h, io_hdr.albion.address_l, io_hdr.albion.index, io_hdr.albion.num, io_hdr.albion.operation, io_hdr.albion.port, io_hdr.albion.request_id_high, io_hdr.albion.request_id_low, io_hdr.albion.time, io_hdr.albion.valid, io_hdr.albion_data.valid, io_hdr.albion_timer.address_high_0, io_hdr.albion_timer.address_high_1, io_hdr.albion_timer.address_high_2, io_hdr.albion_timer.address_high_3, io_hdr.albion_timer.address_low_0, io_hdr.albion_timer.address_low_1, io_hdr.albion_timer.address_low_2, io_hdr.albion_timer.address_low_3, io_hdr.albion_timer.const_time, io_hdr.albion_timer.state_0, io_hdr.albion_timer.state_1, io_hdr.albion_timer.state_2, io_hdr.albion_timer.state_3, io_hdr.albion_timer.times, io_hdr.albion_timer.valid, io_hdr.ethernet.ether_type, io_hdr.ethernet.valid, io_inbox_count, io_meta.no_use, io_meta.session_id, io_meta.state, io_meta.state_sub, io_pkt_external, procurator_bad, procurator_step, ta___ra_ret_register_address_h_record_0_read_0, ta___ra_ret_register_address_h_record_0_write_0, ta___ra_ret_register_address_h_record_1_read_0, ta___ra_ret_register_address_h_record_1_write_0, ta___ra_ret_register_address_h_record_2_read_0, ta___ra_ret_register_address_h_record_2_write_0, ta___ra_ret_register_address_h_record_3_read_0, ta___ra_ret_register_address_h_record_3_write_0, ta___ra_ret_register_address_l_record_0_read_0, ta___ra_ret_register_address_l_record_0_write_0, ta___ra_ret_register_address_l_record_1_read_0, ta___ra_ret_register_address_l_record_1_write_0, ta___ra_ret_register_address_l_record_2_read_0, ta___ra_ret_register_address_l_record_2_write_0, ta___ra_ret_register_address_l_record_3_read_0, ta___ra_ret_register_address_l_record_3_write_0, ta___ra_ret_register_num_add_0, ta___ra_ret_register_num_zero_0, ta___ra_ret_register_request_id_high_add_0, ta___ra_ret_register_request_id_low_add_0, ta___ra_ret_register_state_0_r_0, ta___ra_ret_register_state_0_sub_0, ta___ra_ret_register_state_0_w_0, ta___ra_ret_register_state_1_r_0, ta___ra_ret_register_state_1_sub_0, ta___ra_ret_register_state_1_w_0, ta___ra_ret_register_state_2_r_0, ta___ra_ret_register_state_2_sub_0, ta___ra_ret_register_state_2_w_0, ta___ra_ret_register_state_3_r_0, ta___ra_ret_register_state_3_sub_0, ta___ra_ret_register_state_3_w_0, ta___ra_ret_register_timer_add_0, ta___ra_ret_register_timer_read_0, ta___ra_val_register_address_h_record_0_read_0, ta___ra_val_register_address_h_record_0_write_0, ta___ra_val_register_address_h_record_1_read_0, ta___ra_val_register_address_h_record_1_write_0, ta___ra_val_register_address_h_record_2_read_0, ta___ra_val_register_address_h_record_2_write_0, ta___ra_val_register_address_h_record_3_read_0, ta___ra_val_register_address_h_record_3_write_0, ta___ra_val_register_address_l_record_0_read_0, ta___ra_val_register_address_l_record_0_write_0, ta___ra_val_register_address_l_record_1_read_0, ta___ra_val_register_address_l_record_1_write_0, ta___ra_val_register_address_l_record_2_read_0, ta___ra_val_register_address_l_record_2_write_0, ta___ra_val_register_address_l_record_3_read_0, ta___ra_val_register_address_l_record_3_write_0, ta___ra_val_register_num_add_0, ta___ra_val_register_num_zero_0, ta___ra_val_register_request_id_high_add_0, ta___ra_val_register_request_id_low_add_0, ta___ra_val_register_state_0_r_0, ta___ra_val_register_state_0_sub_0, ta___ra_val_register_state_0_w_0, ta___ra_val_register_state_1_r_0, ta___ra_val_register_state_1_sub_0, ta___ra_val_register_state_1_w_0, ta___ra_val_register_state_2_r_0, ta___ra_val_register_state_2_sub_0, ta___ra_val_register_state_2_w_0, ta___ra_val_register_state_3_r_0, ta___ra_val_register_state_3_sub_0, ta___ra_val_register_state_3_w_0, ta___ra_val_register_timer_add_0, ta___ra_val_register_timer_read_0, ta_drop, ta_eg_dprsr_md.mirror_type, ta_hdr.albion.CS_id_1, ta_hdr.albion.CS_id_2, ta_hdr.albion.CS_id_3, ta_hdr.albion.CS_offset_1, ta_hdr.albion.CS_offset_2, ta_hdr.albion.CS_offset_3, ta_hdr.albion.address_h, ta_hdr.albion.address_l, ta_hdr.albion.index, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion.port, ta_hdr.albion.request_id_high, ta_hdr.albion.request_id_low, ta_hdr.albion.time, ta_hdr.albion.valid, ta_hdr.albion_data.valid, ta_hdr.albion_timer.address_high_0, ta_hdr.albion_timer.address_high_1, ta_hdr.albion_timer.address_high_2, ta_hdr.albion_timer.address_high_3, ta_hdr.albion_timer.address_low_0, ta_hdr.albion_timer.address_low_1, ta_hdr.albion_timer.address_low_2, ta_hdr.albion_timer.address_low_3, ta_hdr.albion_timer.const_time, ta_hdr.albion_timer.state_0, ta_hdr.albion_timer.state_1, ta_hdr.albion_timer.state_2, ta_hdr.albion_timer.state_3, ta_hdr.albion_timer.times, ta_hdr.albion_timer.valid, ta_hdr.ethernet.ether_type, ta_hdr.ethernet.valid, ta_ig_tm_md.ucast_egress_port, ta_inbox_count, ta_isValid, ta_meta.no_use, ta_meta.session_id, ta_meta.state, ta_meta.state_sub, ta_mirror_md_0, ta_p4b_checksum_error, ta_p4b_checksum_updated, ta_p4b_checksum_verified, ta_p4b_clone_e2e, ta_p4b_clone_i2e, ta_p4b_clone_i2i, ta_p4b_digest, ta_p4b_recirculate, ta_pkt_external, ta_register_address_h_record, ta_register_address_h_record_4, ta_register_address_h_record_4__last0_old_value, ta_register_address_h_record_4__last0_value, ta_register_address_h_record_4__last_index, ta_register_address_h_record_4__last_old_value, ta_register_address_h_record_4__last_value, ta_register_address_h_record_4__last_write_site, ta_register_address_h_record_4__next_write_site, ta_register_address_h_record_4__wrote_any, ta_register_address_h_record_4__wrote_index0, ta_register_address_h_record_5, ta_register_address_h_record_5__last0_old_value, ta_register_address_h_record_5__last0_value, ta_register_address_h_record_5__last_index, ta_register_address_h_record_5__last_old_value, ta_register_address_h_record_5__last_value, ta_register_address_h_record_5__last_write_site, ta_register_address_h_record_5__next_write_site, ta_register_address_h_record_5__wrote_any, ta_register_address_h_record_5__wrote_index0, ta_register_address_h_record_6, ta_register_address_h_record_6__last0_old_value, ta_register_address_h_record_6__last0_value, ta_register_address_h_record_6__last_index, ta_register_address_h_record_6__last_old_value, ta_register_address_h_record_6__last_value, ta_register_address_h_record_6__last_write_site, ta_register_address_h_record_6__next_write_site, ta_register_address_h_record_6__wrote_any, ta_register_address_h_record_6__wrote_index0, ta_register_address_h_record__last0_old_value, ta_register_address_h_record__last0_value, ta_register_address_h_record__last_index, ta_register_address_h_record__last_old_value, ta_register_address_h_record__last_value, ta_register_address_h_record__last_write_site, ta_register_address_h_record__next_write_site, ta_register_address_h_record__wrote_any, ta_register_address_h_record__wrote_index0, ta_register_address_l_record, ta_register_address_l_record_4, ta_register_address_l_record_4__last0_old_value, ta_register_address_l_record_4__last0_value, ta_register_address_l_record_4__last_index, ta_register_address_l_record_4__last_old_value, ta_register_address_l_record_4__last_value, ta_register_address_l_record_4__last_write_site, ta_register_address_l_record_4__next_write_site, ta_register_address_l_record_4__wrote_any, ta_register_address_l_record_4__wrote_index0, ta_register_address_l_record_5, ta_register_address_l_record_5__last0_old_value, ta_register_address_l_record_5__last0_value, ta_register_address_l_record_5__last_index, ta_register_address_l_record_5__last_old_value, ta_register_address_l_record_5__last_value, ta_register_address_l_record_5__last_write_site, ta_register_address_l_record_5__next_write_site, ta_register_address_l_record_5__wrote_any, ta_register_address_l_record_5__wrote_index0, ta_register_address_l_record_6, ta_register_address_l_record_6__last0_old_value, ta_register_address_l_record_6__last0_value, ta_register_address_l_record_6__last_index, ta_register_address_l_record_6__last_old_value, ta_register_address_l_record_6__last_value, ta_register_address_l_record_6__last_write_site, ta_register_address_l_record_6__next_write_site, ta_register_address_l_record_6__wrote_any, ta_register_address_l_record_6__wrote_index0, ta_register_address_l_record__last0_old_value, ta_register_address_l_record__last0_value, ta_register_address_l_record__last_index, ta_register_address_l_record__last_old_value, ta_register_address_l_record__last_value, ta_register_address_l_record__last_write_site, ta_register_address_l_record__next_write_site, ta_register_address_l_record__wrote_any, ta_register_address_l_record__wrote_index0, ta_register_num_0, ta_register_num_0__last0_old_value, ta_register_num_0__last0_value, ta_register_num_0__last_index, ta_register_num_0__last_old_value, ta_register_num_0__last_value, ta_register_num_0__last_write_site, ta_register_num_0__next_write_site, ta_register_num_0__wrote_any, ta_register_num_0__wrote_index0, ta_register_request_id_high_0, ta_register_request_id_high_0__last0_old_value, ta_register_request_id_high_0__last0_value, ta_register_request_id_high_0__last_index, ta_register_request_id_high_0__last_old_value, ta_register_request_id_high_0__last_value, ta_register_request_id_high_0__last_write_site, ta_register_request_id_high_0__next_write_site, ta_register_request_id_high_0__wrote_any, ta_register_request_id_high_0__wrote_index0, ta_register_request_id_low_0, ta_register_request_id_low_0__last0_old_value, ta_register_request_id_low_0__last0_value, ta_register_request_id_low_0__last_index, ta_register_request_id_low_0__last_old_value, ta_register_request_id_low_0__last_value, ta_register_request_id_low_0__last_write_site, ta_register_request_id_low_0__next_write_site, ta_register_request_id_low_0__wrote_any, ta_register_request_id_low_0__wrote_index0, ta_register_state, ta_register_state_4, ta_register_state_4__last0_old_value, ta_register_state_4__last0_value, ta_register_state_4__last_index, ta_register_state_4__last_old_value, ta_register_state_4__last_value, ta_register_state_4__last_write_site, ta_register_state_4__next_write_site, ta_register_state_4__wrote_any, ta_register_state_4__wrote_index0, ta_register_state_5, ta_register_state_5__last0_old_value, ta_register_state_5__last0_value, ta_register_state_5__last_index, ta_register_state_5__last_old_value, ta_register_state_5__last_value, ta_register_state_5__last_write_site, ta_register_state_5__next_write_site, ta_register_state_5__wrote_any, ta_register_state_5__wrote_index0, ta_register_state_6, ta_register_state_6__last0_old_value, ta_register_state_6__last0_value, ta_register_state_6__last_index, ta_register_state_6__last_old_value, ta_register_state_6__last_value, ta_register_state_6__last_write_site, ta_register_state_6__next_write_site, ta_register_state_6__wrote_any, ta_register_state_6__wrote_index0, ta_register_state__last0_old_value, ta_register_state__last0_value, ta_register_state__last_index, ta_register_state__last_old_value, ta_register_state__last_value, ta_register_state__last_write_site, ta_register_state__next_write_site, ta_register_state__wrote_any, ta_register_state__wrote_index0, ta_register_timer_0, ta_register_timer_0__last0_old_value, ta_register_timer_0__last0_value, ta_register_timer_0__last_index, ta_register_timer_0__last_old_value, ta_register_timer_0__last_value, ta_register_timer_0__last_write_site, ta_register_timer_0__next_write_site, ta_register_timer_0__wrote_any, ta_register_timer_0__wrote_index0, ta_table_check_timer_0.action_run, ta_table_check_timer_0.hit, ta_table_register_address_h_record_0_interaction_0.action_run, ta_table_register_address_h_record_0_interaction_0.hit, ta_table_register_address_h_record_1_interaction_0.action_run, ta_table_register_address_h_record_1_interaction_0.hit, ta_table_register_address_h_record_2_interaction_0.action_run, ta_table_register_address_h_record_2_interaction_0.hit, ta_table_register_address_h_record_3_interaction_0.action_run, ta_table_register_address_h_record_3_interaction_0.hit, ta_table_register_address_l_record_0_interaction_0.action_run, ta_table_register_address_l_record_0_interaction_0.hit, ta_table_register_address_l_record_1_interaction_0.action_run, ta_table_register_address_l_record_1_interaction_0.hit, ta_table_register_address_l_record_2_interaction_0.action_run, ta_table_register_address_l_record_2_interaction_0.hit, ta_table_register_address_l_record_3_interaction_0.action_run, ta_table_register_address_l_record_3_interaction_0.hit, ta_table_register_num_interaction_0.action_run, ta_table_register_num_interaction_0.hit, ta_table_register_request_id_high_interaction_0.action_run, ta_table_register_request_id_high_interaction_0.hit, ta_table_register_state_0_interaction_0.action_run, ta_table_register_state_0_interaction_0.hit, ta_table_register_state_1_interaction_0.action_run, ta_table_register_state_1_interaction_0.hit, ta_table_register_state_2_interaction_0.action_run, ta_table_register_state_2_interaction_0.hit, ta_table_register_state_3_interaction_0.action_run, ta_table_register_state_3_interaction_0.hit, ta_table_register_timer_interaction_0.action_run, ta_table_register_timer_interaction_0.hit, ta_table_send_to_somewhere_0.action_run, ta_table_send_to_somewhere_0.hit, ta_table_state_check_0.action_run, ta_table_state_check_0.hit, ta_table_success_check_0.action_run, ta_table_success_check_0.hit, tb___ra_ret_register_data_record_0_write_0, tb___ra_ret_register_data_record_10_write_0, tb___ra_ret_register_data_record_11_write_0, tb___ra_ret_register_data_record_1_write_0, tb___ra_ret_register_data_record_2_write_0, tb___ra_ret_register_data_record_3_write_0, tb___ra_ret_register_data_record_4_write_0, tb___ra_ret_register_data_record_5_write_0, tb___ra_ret_register_data_record_6_write_0, tb___ra_ret_register_data_record_7_write_0, tb___ra_ret_register_data_record_8_write_0, tb___ra_ret_register_data_record_9_write_0, tb___ra_val_register_data_record_0_write_0, tb___ra_val_register_data_record_10_write_0, tb___ra_val_register_data_record_11_write_0, tb___ra_val_register_data_record_1_write_0, tb___ra_val_register_data_record_2_write_0, tb___ra_val_register_data_record_3_write_0, tb___ra_val_register_data_record_4_write_0, tb___ra_val_register_data_record_5_write_0, tb___ra_val_register_data_record_6_write_0, tb___ra_val_register_data_record_7_write_0, tb___ra_val_register_data_record_8_write_0, tb___ra_val_register_data_record_9_write_0, tb_drop, tb_eg_dprsr_md.mirror_type, tb_hdr.albion.CS_id_1, tb_hdr.albion.CS_id_2, tb_hdr.albion.CS_id_3, tb_hdr.albion.CS_offset_1, tb_hdr.albion.CS_offset_2, tb_hdr.albion.CS_offset_3, tb_hdr.albion.address_h, tb_hdr.albion.address_l, tb_hdr.albion.index, tb_hdr.albion.num, tb_hdr.albion.operation, tb_hdr.albion.port, tb_hdr.albion.request_id_high, tb_hdr.albion.request_id_low, tb_hdr.albion.time, tb_hdr.albion.valid, tb_hdr.albion_data.data_0, tb_hdr.albion_data.data_1, tb_hdr.albion_data.data_10, tb_hdr.albion_data.data_11, tb_hdr.albion_data.data_2, tb_hdr.albion_data.data_3, tb_hdr.albion_data.data_4, tb_hdr.albion_data.data_5, tb_hdr.albion_data.data_6, tb_hdr.albion_data.data_7, tb_hdr.albion_data.data_8, tb_hdr.albion_data.data_9, tb_hdr.albion_data.valid, tb_hdr.albion_timer.address_high_0, tb_hdr.albion_timer.address_high_1, tb_hdr.albion_timer.address_high_2, tb_hdr.albion_timer.address_high_3, tb_hdr.albion_timer.address_low_0, tb_hdr.albion_timer.address_low_1, tb_hdr.albion_timer.address_low_2, tb_hdr.albion_timer.address_low_3, tb_hdr.albion_timer.const_time, tb_hdr.albion_timer.state_0, tb_hdr.albion_timer.state_1, tb_hdr.albion_timer.state_2, tb_hdr.albion_timer.state_3, tb_hdr.albion_timer.times, tb_hdr.albion_timer.valid, tb_hdr.ethernet.ether_type, tb_hdr.ethernet.valid, tb_ig_tm_md.ucast_egress_port, tb_inbox_count, tb_isValid, tb_meta.no_use, tb_meta.session_id, tb_meta.state, tb_meta.state_sub, tb_mirror_md_0, tb_mirror_md_1, tb_mirror_md_2, tb_p4b_checksum_error, tb_p4b_checksum_updated, tb_p4b_checksum_verified, tb_p4b_clone_e2e, tb_p4b_clone_i2e, tb_p4b_clone_i2i, tb_p4b_digest, tb_p4b_recirculate, tb_pkt_external, tb_register_data_record, tb_register_data_record_12, tb_register_data_record_12__last0_old_value, tb_register_data_record_12__last0_value, tb_register_data_record_12__last_index, tb_register_data_record_12__last_old_value, tb_register_data_record_12__last_value, tb_register_data_record_12__last_write_site, tb_register_data_record_12__next_write_site, tb_register_data_record_12__wrote_any, tb_register_data_record_12__wrote_index0, tb_register_data_record_13, tb_register_data_record_13__last0_old_value, tb_register_data_record_13__last0_value, tb_register_data_record_13__last_index, tb_register_data_record_13__last_old_value, tb_register_data_record_13__last_value, tb_register_data_record_13__last_write_site, tb_register_data_record_13__next_write_site, tb_register_data_record_13__wrote_any, tb_register_data_record_13__wrote_index0, tb_register_data_record_14, tb_register_data_record_14__last0_old_value, tb_register_data_record_14__last0_value, tb_register_data_record_14__last_index, tb_register_data_record_14__last_old_value, tb_register_data_record_14__last_value, tb_register_data_record_14__last_write_site, tb_register_data_record_14__next_write_site, tb_register_data_record_14__wrote_any, tb_register_data_record_14__wrote_index0, tb_register_data_record_15, tb_register_data_record_15__last0_old_value, tb_register_data_record_15__last0_value, tb_register_data_record_15__last_index, tb_register_data_record_15__last_old_value, tb_register_data_record_15__last_value, tb_register_data_record_15__last_write_site, tb_register_data_record_15__next_write_site, tb_register_data_record_15__wrote_any, tb_register_data_record_15__wrote_index0, tb_register_data_record_16, tb_register_data_record_16__last0_old_value, tb_register_data_record_16__last0_value, tb_register_data_record_16__last_index, tb_register_data_record_16__last_old_value, tb_register_data_record_16__last_value, tb_register_data_record_16__last_write_site, tb_register_data_record_16__next_write_site, tb_register_data_record_16__wrote_any, tb_register_data_record_16__wrote_index0, tb_register_data_record_17, tb_register_data_record_17__last0_old_value, tb_register_data_record_17__last0_value, tb_register_data_record_17__last_index, tb_register_data_record_17__last_old_value, tb_register_data_record_17__last_value, tb_register_data_record_17__last_write_site, tb_register_data_record_17__next_write_site, tb_register_data_record_17__wrote_any, tb_register_data_record_17__wrote_index0, tb_register_data_record_18, tb_register_data_record_18__last0_old_value, tb_register_data_record_18__last0_value, tb_register_data_record_18__last_index, tb_register_data_record_18__last_old_value, tb_register_data_record_18__last_value, tb_register_data_record_18__last_write_site, tb_register_data_record_18__next_write_site, tb_register_data_record_18__wrote_any, tb_register_data_record_18__wrote_index0, tb_register_data_record_19, tb_register_data_record_19__last0_old_value, tb_register_data_record_19__last0_value, tb_register_data_record_19__last_index, tb_register_data_record_19__last_old_value, tb_register_data_record_19__last_value, tb_register_data_record_19__last_write_site, tb_register_data_record_19__next_write_site, tb_register_data_record_19__wrote_any, tb_register_data_record_19__wrote_index0, tb_register_data_record_20, tb_register_data_record_20__last0_old_value, tb_register_data_record_20__last0_value, tb_register_data_record_20__last_index, tb_register_data_record_20__last_old_value, tb_register_data_record_20__last_value, tb_register_data_record_20__last_write_site, tb_register_data_record_20__next_write_site, tb_register_data_record_20__wrote_any, tb_register_data_record_20__wrote_index0, tb_register_data_record_21, tb_register_data_record_21__last0_old_value, tb_register_data_record_21__last0_value, tb_register_data_record_21__last_index, tb_register_data_record_21__last_old_value, tb_register_data_record_21__last_value, tb_register_data_record_21__last_write_site, tb_register_data_record_21__next_write_site, tb_register_data_record_21__wrote_any, tb_register_data_record_21__wrote_index0, tb_register_data_record_22, tb_register_data_record_22__last0_old_value, tb_register_data_record_22__last0_value, tb_register_data_record_22__last_index, tb_register_data_record_22__last_old_value, tb_register_data_record_22__last_value, tb_register_data_record_22__last_write_site, tb_register_data_record_22__next_write_site, tb_register_data_record_22__wrote_any, tb_register_data_record_22__wrote_index0, tb_register_data_record__last0_old_value, tb_register_data_record__last0_value, tb_register_data_record__last_index, tb_register_data_record__last_old_value, tb_register_data_record__last_value, tb_register_data_record__last_write_site, tb_register_data_record__next_write_site, tb_register_data_record__wrote_any, tb_register_data_record__wrote_index0, tb_table_dst_cs.action_run, tb_table_dst_cs.hit, tb_table_dst_cs_0.action_run, tb_table_dst_cs_0.hit, tb_table_dst_cs_3.action_run, tb_table_dst_cs_3.hit;
{
  // initialize inboxes
  ta_inbox_count := 0;
  ta_pkt_external := false;
  tb_inbox_count := 0;
  tb_pkt_external := false;
  io_inbox_count := 0;
  io_pkt_external := false;
  // initialize P4B event flags (clone/recirculate)
  ta_p4b_clone_i2e := false;
  ta_p4b_clone_e2e := false;
  ta_p4b_clone_i2i := false;
  ta_p4b_recirculate := false;
  tb_p4b_clone_i2e := false;
  tb_p4b_clone_e2e := false;
  tb_p4b_clone_i2i := false;
  tb_p4b_recirculate := false;

  // initialize DSL state
  dsl_pending := 0;
  dsl_steps := 0;
  dsl_client_seen := 0;
  dsl_phase := 0;
  // initialize P4 registers (default 0)
  assume (forall i:bv32 :: ta_register_address_h_record[i] == 0bv32);
  assume ta_register_address_h_record[0bv32] == 0bv32;
  assume (forall i:bv32 :: ta_register_address_h_record_4[i] == 0bv32);
  assume ta_register_address_h_record_4[0bv32] == 0bv32;
  assume (forall i:bv32 :: ta_register_address_h_record_5[i] == 0bv32);
  assume ta_register_address_h_record_5[0bv32] == 0bv32;
  assume (forall i:bv32 :: ta_register_address_h_record_6[i] == 0bv32);
  assume ta_register_address_h_record_6[0bv32] == 0bv32;
  assume (forall i:bv32 :: ta_register_address_l_record[i] == 0bv32);
  assume ta_register_address_l_record[0bv32] == 0bv32;
  assume (forall i:bv32 :: ta_register_address_l_record_4[i] == 0bv32);
  assume ta_register_address_l_record_4[0bv32] == 0bv32;
  assume (forall i:bv32 :: ta_register_address_l_record_5[i] == 0bv32);
  assume ta_register_address_l_record_5[0bv32] == 0bv32;
  assume (forall i:bv32 :: ta_register_address_l_record_6[i] == 0bv32);
  assume ta_register_address_l_record_6[0bv32] == 0bv32;
  assume ta_register_num_0[0bv32] == 0bv32;
  assume ta_register_request_id_high_0[0bv32] == 0bv32;
  assume ta_register_request_id_low_0[0bv32] == 0bv32;
  assume (forall i:bv32 :: ta_register_state[i] == 0bv32);
  assume ta_register_state[0bv32] == 0bv32;
  assume (forall i:bv32 :: ta_register_state_4[i] == 0bv32);
  assume ta_register_state_4[0bv32] == 0bv32;
  assume (forall i:bv32 :: ta_register_state_5[i] == 0bv32);
  assume ta_register_state_5[0bv32] == 0bv32;
  assume (forall i:bv32 :: ta_register_state_6[i] == 0bv32);
  assume ta_register_state_6[0bv32] == 0bv32;
  assume ta_register_timer_0[0bv32] == 0bv32;
  assume (forall i:bv32 :: tb_register_data_record[i] == 0bv32);
  assume tb_register_data_record[0bv32] == 0bv32;
  assume (forall i:bv32 :: tb_register_data_record_12[i] == 0bv32);
  assume tb_register_data_record_12[0bv32] == 0bv32;
  assume (forall i:bv32 :: tb_register_data_record_13[i] == 0bv32);
  assume tb_register_data_record_13[0bv32] == 0bv32;
  assume (forall i:bv32 :: tb_register_data_record_14[i] == 0bv32);
  assume tb_register_data_record_14[0bv32] == 0bv32;
  assume (forall i:bv32 :: tb_register_data_record_15[i] == 0bv32);
  assume tb_register_data_record_15[0bv32] == 0bv32;
  assume (forall i:bv32 :: tb_register_data_record_16[i] == 0bv32);
  assume tb_register_data_record_16[0bv32] == 0bv32;
  assume (forall i:bv32 :: tb_register_data_record_17[i] == 0bv32);
  assume tb_register_data_record_17[0bv32] == 0bv32;
  assume (forall i:bv32 :: tb_register_data_record_18[i] == 0bv32);
  assume tb_register_data_record_18[0bv32] == 0bv32;
  assume (forall i:bv32 :: tb_register_data_record_19[i] == 0bv32);
  assume tb_register_data_record_19[0bv32] == 0bv32;
  assume (forall i:bv32 :: tb_register_data_record_20[i] == 0bv32);
  assume tb_register_data_record_20[0bv32] == 0bv32;
  assume (forall i:bv32 :: tb_register_data_record_21[i] == 0bv32);
  assume tb_register_data_record_21[0bv32] == 0bv32;
  assume (forall i:bv32 :: tb_register_data_record_22[i] == 0bv32);
  assume tb_register_data_record_22[0bv32] == 0bv32;
  // initialize register write tracking (debug)
  ta_register_address_h_record__last_index := 0bv32;
  ta_register_address_h_record__last_value := 0bv32;
  ta_register_address_h_record__last_old_value := 0bv32;
  ta_register_address_h_record__wrote_any := false;
  ta_register_address_h_record__wrote_index0 := false;
  ta_register_address_h_record__next_write_site := 0;
  ta_register_address_h_record__last_write_site := 0;
  ta_register_address_h_record__last0_old_value := 0bv32;
  ta_register_address_h_record__last0_value := 0bv32;
  ta_register_address_h_record_4__last_index := 0bv32;
  ta_register_address_h_record_4__last_value := 0bv32;
  ta_register_address_h_record_4__last_old_value := 0bv32;
  ta_register_address_h_record_4__wrote_any := false;
  ta_register_address_h_record_4__wrote_index0 := false;
  ta_register_address_h_record_4__next_write_site := 0;
  ta_register_address_h_record_4__last_write_site := 0;
  ta_register_address_h_record_4__last0_old_value := 0bv32;
  ta_register_address_h_record_4__last0_value := 0bv32;
  ta_register_address_h_record_5__last_index := 0bv32;
  ta_register_address_h_record_5__last_value := 0bv32;
  ta_register_address_h_record_5__last_old_value := 0bv32;
  ta_register_address_h_record_5__wrote_any := false;
  ta_register_address_h_record_5__wrote_index0 := false;
  ta_register_address_h_record_5__next_write_site := 0;
  ta_register_address_h_record_5__last_write_site := 0;
  ta_register_address_h_record_5__last0_old_value := 0bv32;
  ta_register_address_h_record_5__last0_value := 0bv32;
  ta_register_address_h_record_6__last_index := 0bv32;
  ta_register_address_h_record_6__last_value := 0bv32;
  ta_register_address_h_record_6__last_old_value := 0bv32;
  ta_register_address_h_record_6__wrote_any := false;
  ta_register_address_h_record_6__wrote_index0 := false;
  ta_register_address_h_record_6__next_write_site := 0;
  ta_register_address_h_record_6__last_write_site := 0;
  ta_register_address_h_record_6__last0_old_value := 0bv32;
  ta_register_address_h_record_6__last0_value := 0bv32;
  ta_register_address_l_record__last_index := 0bv32;
  ta_register_address_l_record__last_value := 0bv32;
  ta_register_address_l_record__last_old_value := 0bv32;
  ta_register_address_l_record__wrote_any := false;
  ta_register_address_l_record__wrote_index0 := false;
  ta_register_address_l_record__next_write_site := 0;
  ta_register_address_l_record__last_write_site := 0;
  ta_register_address_l_record__last0_old_value := 0bv32;
  ta_register_address_l_record__last0_value := 0bv32;
  ta_register_address_l_record_4__last_index := 0bv32;
  ta_register_address_l_record_4__last_value := 0bv32;
  ta_register_address_l_record_4__last_old_value := 0bv32;
  ta_register_address_l_record_4__wrote_any := false;
  ta_register_address_l_record_4__wrote_index0 := false;
  ta_register_address_l_record_4__next_write_site := 0;
  ta_register_address_l_record_4__last_write_site := 0;
  ta_register_address_l_record_4__last0_old_value := 0bv32;
  ta_register_address_l_record_4__last0_value := 0bv32;
  ta_register_address_l_record_5__last_index := 0bv32;
  ta_register_address_l_record_5__last_value := 0bv32;
  ta_register_address_l_record_5__last_old_value := 0bv32;
  ta_register_address_l_record_5__wrote_any := false;
  ta_register_address_l_record_5__wrote_index0 := false;
  ta_register_address_l_record_5__next_write_site := 0;
  ta_register_address_l_record_5__last_write_site := 0;
  ta_register_address_l_record_5__last0_old_value := 0bv32;
  ta_register_address_l_record_5__last0_value := 0bv32;
  ta_register_address_l_record_6__last_index := 0bv32;
  ta_register_address_l_record_6__last_value := 0bv32;
  ta_register_address_l_record_6__last_old_value := 0bv32;
  ta_register_address_l_record_6__wrote_any := false;
  ta_register_address_l_record_6__wrote_index0 := false;
  ta_register_address_l_record_6__next_write_site := 0;
  ta_register_address_l_record_6__last_write_site := 0;
  ta_register_address_l_record_6__last0_old_value := 0bv32;
  ta_register_address_l_record_6__last0_value := 0bv32;
  ta_register_num_0__last_index := 0bv32;
  ta_register_num_0__last_value := 0bv32;
  ta_register_num_0__last_old_value := 0bv32;
  ta_register_num_0__wrote_any := false;
  ta_register_num_0__wrote_index0 := false;
  ta_register_num_0__next_write_site := 0;
  ta_register_num_0__last_write_site := 0;
  ta_register_num_0__last0_old_value := 0bv32;
  ta_register_num_0__last0_value := 0bv32;
  ta_register_request_id_high_0__last_index := 0bv32;
  ta_register_request_id_high_0__last_value := 0bv32;
  ta_register_request_id_high_0__last_old_value := 0bv32;
  ta_register_request_id_high_0__wrote_any := false;
  ta_register_request_id_high_0__wrote_index0 := false;
  ta_register_request_id_high_0__next_write_site := 0;
  ta_register_request_id_high_0__last_write_site := 0;
  ta_register_request_id_high_0__last0_old_value := 0bv32;
  ta_register_request_id_high_0__last0_value := 0bv32;
  ta_register_request_id_low_0__last_index := 0bv32;
  ta_register_request_id_low_0__last_value := 0bv32;
  ta_register_request_id_low_0__last_old_value := 0bv32;
  ta_register_request_id_low_0__wrote_any := false;
  ta_register_request_id_low_0__wrote_index0 := false;
  ta_register_request_id_low_0__next_write_site := 0;
  ta_register_request_id_low_0__last_write_site := 0;
  ta_register_request_id_low_0__last0_old_value := 0bv32;
  ta_register_request_id_low_0__last0_value := 0bv32;
  ta_register_state__last_index := 0bv32;
  ta_register_state__last_value := 0bv32;
  ta_register_state__last_old_value := 0bv32;
  ta_register_state__wrote_any := false;
  ta_register_state__wrote_index0 := false;
  ta_register_state__next_write_site := 0;
  ta_register_state__last_write_site := 0;
  ta_register_state__last0_old_value := 0bv32;
  ta_register_state__last0_value := 0bv32;
  ta_register_state_4__last_index := 0bv32;
  ta_register_state_4__last_value := 0bv32;
  ta_register_state_4__last_old_value := 0bv32;
  ta_register_state_4__wrote_any := false;
  ta_register_state_4__wrote_index0 := false;
  ta_register_state_4__next_write_site := 0;
  ta_register_state_4__last_write_site := 0;
  ta_register_state_4__last0_old_value := 0bv32;
  ta_register_state_4__last0_value := 0bv32;
  ta_register_state_5__last_index := 0bv32;
  ta_register_state_5__last_value := 0bv32;
  ta_register_state_5__last_old_value := 0bv32;
  ta_register_state_5__wrote_any := false;
  ta_register_state_5__wrote_index0 := false;
  ta_register_state_5__next_write_site := 0;
  ta_register_state_5__last_write_site := 0;
  ta_register_state_5__last0_old_value := 0bv32;
  ta_register_state_5__last0_value := 0bv32;
  ta_register_state_6__last_index := 0bv32;
  ta_register_state_6__last_value := 0bv32;
  ta_register_state_6__last_old_value := 0bv32;
  ta_register_state_6__wrote_any := false;
  ta_register_state_6__wrote_index0 := false;
  ta_register_state_6__next_write_site := 0;
  ta_register_state_6__last_write_site := 0;
  ta_register_state_6__last0_old_value := 0bv32;
  ta_register_state_6__last0_value := 0bv32;
  ta_register_timer_0__last_index := 0bv32;
  ta_register_timer_0__last_value := 0bv32;
  ta_register_timer_0__last_old_value := 0bv32;
  ta_register_timer_0__wrote_any := false;
  ta_register_timer_0__wrote_index0 := false;
  ta_register_timer_0__next_write_site := 0;
  ta_register_timer_0__last_write_site := 0;
  ta_register_timer_0__last0_old_value := 0bv32;
  ta_register_timer_0__last0_value := 0bv32;
  tb_register_data_record__last_index := 0bv32;
  tb_register_data_record__last_value := 0bv32;
  tb_register_data_record__last_old_value := 0bv32;
  tb_register_data_record__wrote_any := false;
  tb_register_data_record__wrote_index0 := false;
  tb_register_data_record__next_write_site := 0;
  tb_register_data_record__last_write_site := 0;
  tb_register_data_record__last0_old_value := 0bv32;
  tb_register_data_record__last0_value := 0bv32;
  tb_register_data_record_12__last_index := 0bv32;
  tb_register_data_record_12__last_value := 0bv32;
  tb_register_data_record_12__last_old_value := 0bv32;
  tb_register_data_record_12__wrote_any := false;
  tb_register_data_record_12__wrote_index0 := false;
  tb_register_data_record_12__next_write_site := 0;
  tb_register_data_record_12__last_write_site := 0;
  tb_register_data_record_12__last0_old_value := 0bv32;
  tb_register_data_record_12__last0_value := 0bv32;
  tb_register_data_record_13__last_index := 0bv32;
  tb_register_data_record_13__last_value := 0bv32;
  tb_register_data_record_13__last_old_value := 0bv32;
  tb_register_data_record_13__wrote_any := false;
  tb_register_data_record_13__wrote_index0 := false;
  tb_register_data_record_13__next_write_site := 0;
  tb_register_data_record_13__last_write_site := 0;
  tb_register_data_record_13__last0_old_value := 0bv32;
  tb_register_data_record_13__last0_value := 0bv32;
  tb_register_data_record_14__last_index := 0bv32;
  tb_register_data_record_14__last_value := 0bv32;
  tb_register_data_record_14__last_old_value := 0bv32;
  tb_register_data_record_14__wrote_any := false;
  tb_register_data_record_14__wrote_index0 := false;
  tb_register_data_record_14__next_write_site := 0;
  tb_register_data_record_14__last_write_site := 0;
  tb_register_data_record_14__last0_old_value := 0bv32;
  tb_register_data_record_14__last0_value := 0bv32;
  tb_register_data_record_15__last_index := 0bv32;
  tb_register_data_record_15__last_value := 0bv32;
  tb_register_data_record_15__last_old_value := 0bv32;
  tb_register_data_record_15__wrote_any := false;
  tb_register_data_record_15__wrote_index0 := false;
  tb_register_data_record_15__next_write_site := 0;
  tb_register_data_record_15__last_write_site := 0;
  tb_register_data_record_15__last0_old_value := 0bv32;
  tb_register_data_record_15__last0_value := 0bv32;
  tb_register_data_record_16__last_index := 0bv32;
  tb_register_data_record_16__last_value := 0bv32;
  tb_register_data_record_16__last_old_value := 0bv32;
  tb_register_data_record_16__wrote_any := false;
  tb_register_data_record_16__wrote_index0 := false;
  tb_register_data_record_16__next_write_site := 0;
  tb_register_data_record_16__last_write_site := 0;
  tb_register_data_record_16__last0_old_value := 0bv32;
  tb_register_data_record_16__last0_value := 0bv32;
  tb_register_data_record_17__last_index := 0bv32;
  tb_register_data_record_17__last_value := 0bv32;
  tb_register_data_record_17__last_old_value := 0bv32;
  tb_register_data_record_17__wrote_any := false;
  tb_register_data_record_17__wrote_index0 := false;
  tb_register_data_record_17__next_write_site := 0;
  tb_register_data_record_17__last_write_site := 0;
  tb_register_data_record_17__last0_old_value := 0bv32;
  tb_register_data_record_17__last0_value := 0bv32;
  tb_register_data_record_18__last_index := 0bv32;
  tb_register_data_record_18__last_value := 0bv32;
  tb_register_data_record_18__last_old_value := 0bv32;
  tb_register_data_record_18__wrote_any := false;
  tb_register_data_record_18__wrote_index0 := false;
  tb_register_data_record_18__next_write_site := 0;
  tb_register_data_record_18__last_write_site := 0;
  tb_register_data_record_18__last0_old_value := 0bv32;
  tb_register_data_record_18__last0_value := 0bv32;
  tb_register_data_record_19__last_index := 0bv32;
  tb_register_data_record_19__last_value := 0bv32;
  tb_register_data_record_19__last_old_value := 0bv32;
  tb_register_data_record_19__wrote_any := false;
  tb_register_data_record_19__wrote_index0 := false;
  tb_register_data_record_19__next_write_site := 0;
  tb_register_data_record_19__last_write_site := 0;
  tb_register_data_record_19__last0_old_value := 0bv32;
  tb_register_data_record_19__last0_value := 0bv32;
  tb_register_data_record_20__last_index := 0bv32;
  tb_register_data_record_20__last_value := 0bv32;
  tb_register_data_record_20__last_old_value := 0bv32;
  tb_register_data_record_20__wrote_any := false;
  tb_register_data_record_20__wrote_index0 := false;
  tb_register_data_record_20__next_write_site := 0;
  tb_register_data_record_20__last_write_site := 0;
  tb_register_data_record_20__last0_old_value := 0bv32;
  tb_register_data_record_20__last0_value := 0bv32;
  tb_register_data_record_21__last_index := 0bv32;
  tb_register_data_record_21__last_value := 0bv32;
  tb_register_data_record_21__last_old_value := 0bv32;
  tb_register_data_record_21__wrote_any := false;
  tb_register_data_record_21__wrote_index0 := false;
  tb_register_data_record_21__next_write_site := 0;
  tb_register_data_record_21__last_write_site := 0;
  tb_register_data_record_21__last0_old_value := 0bv32;
  tb_register_data_record_21__last0_value := 0bv32;
  tb_register_data_record_22__last_index := 0bv32;
  tb_register_data_record_22__last_value := 0bv32;
  tb_register_data_record_22__last_old_value := 0bv32;
  tb_register_data_record_22__wrote_any := false;
  tb_register_data_record_22__wrote_index0 := false;
  tb_register_data_record_22__next_write_site := 0;
  tb_register_data_record_22__last_write_site := 0;
  tb_register_data_record_22__last0_old_value := 0bv32;
  tb_register_data_record_22__last0_value := 0bv32;

  procurator_step := 0;
  procurator_bad := false;
  // step 0: host_send -> io
  // inject packet into connected node (host -> node)
  if (ta_inbox_count < 1) {
    assume ta_inbox_count < 1;
    havoc io_hdr.albion.operation;
    havoc io_hdr.albion_timer.times;
    havoc io_hdr.albion_timer.const_time;
    havoc io_hdr.albion_timer.address_high_0;
    havoc io_hdr.albion_timer.address_low_0;
    havoc io_hdr.albion_timer.state_0;
    havoc io_hdr.albion_timer.address_high_1;
    havoc io_hdr.albion_timer.address_low_1;
    havoc io_hdr.albion_timer.state_1;
    havoc io_hdr.albion_timer.address_high_2;
    havoc io_hdr.albion_timer.address_low_2;
    havoc io_hdr.albion_timer.state_2;
    havoc io_hdr.albion_timer.address_high_3;
    havoc io_hdr.albion_timer.address_low_3;
    havoc io_hdr.albion_timer.state_3;
    havoc io_meta.state;
    havoc io_meta.state_sub;
    havoc io_meta.session_id;
    havoc io_meta.no_use;
    havoc io_eg_dprsr_md.mirror_type;
    io_hdr.ethernet.valid := true;
    io_hdr.ethernet.ether_type := 21845bv16;
    io_hdr.albion.valid := true;
    io_hdr.albion.CS_id_1 := 0bv32;
    io_hdr.albion.CS_id_2 := 0bv32;
    io_hdr.albion.CS_id_3 := 0bv32;
    io_hdr.albion.CS_offset_1 := 0bv32;
    io_hdr.albion.CS_offset_2 := 0bv32;
    io_hdr.albion.CS_offset_3 := 0bv32;
    io_hdr.albion.address_h := 0bv32;
    io_hdr.albion.address_l := 0bv32;
    io_hdr.albion.index := 0bv32;
    io_hdr.albion.num := 0bv32;
    io_hdr.albion.port := 0bv16;
    io_hdr.albion.request_id_high := 0bv32;
    io_hdr.albion.request_id_low := 0bv32;
    io_hdr.albion.time := 0bv32;
    io_hdr.albion_timer.valid := false;
    io_hdr.albion_data.valid := false;
    if ((dsl_phase == 0)) {
      io_hdr.albion.operation := 10bv32;
      dsl_phase := 1;
    } else {
      io_hdr.albion.operation := 0bv32;
    }
    ta_hdr.ethernet.valid := io_hdr.ethernet.valid;
    ta_hdr.ethernet.ether_type := io_hdr.ethernet.ether_type;
    ta_hdr.albion.valid := io_hdr.albion.valid;
    ta_hdr.albion.request_id_high := io_hdr.albion.request_id_high;
    ta_hdr.albion.request_id_low := io_hdr.albion.request_id_low;
    ta_hdr.albion.operation := io_hdr.albion.operation;
    ta_hdr.albion.address_h := io_hdr.albion.address_h;
    ta_hdr.albion.address_l := io_hdr.albion.address_l;
    ta_hdr.albion.time := io_hdr.albion.time;
    ta_hdr.albion.num := io_hdr.albion.num;
    ta_hdr.albion.index := io_hdr.albion.index;
    ta_hdr.albion.CS_id_1 := io_hdr.albion.CS_id_1;
    ta_hdr.albion.CS_offset_1 := io_hdr.albion.CS_offset_1;
    ta_hdr.albion.CS_id_2 := io_hdr.albion.CS_id_2;
    ta_hdr.albion.CS_offset_2 := io_hdr.albion.CS_offset_2;
    ta_hdr.albion.CS_id_3 := io_hdr.albion.CS_id_3;
    ta_hdr.albion.CS_offset_3 := io_hdr.albion.CS_offset_3;
    ta_hdr.albion.port := io_hdr.albion.port;
    ta_hdr.albion_data.valid := io_hdr.albion_data.valid;
    ta_hdr.albion_timer.valid := io_hdr.albion_timer.valid;
    ta_hdr.albion_timer.times := io_hdr.albion_timer.times;
    ta_hdr.albion_timer.const_time := io_hdr.albion_timer.const_time;
    ta_hdr.albion_timer.address_high_0 := io_hdr.albion_timer.address_high_0;
    ta_hdr.albion_timer.address_low_0 := io_hdr.albion_timer.address_low_0;
    ta_hdr.albion_timer.state_0 := io_hdr.albion_timer.state_0;
    ta_hdr.albion_timer.address_high_1 := io_hdr.albion_timer.address_high_1;
    ta_hdr.albion_timer.address_low_1 := io_hdr.albion_timer.address_low_1;
    ta_hdr.albion_timer.state_1 := io_hdr.albion_timer.state_1;
    ta_hdr.albion_timer.address_high_2 := io_hdr.albion_timer.address_high_2;
    ta_hdr.albion_timer.address_low_2 := io_hdr.albion_timer.address_low_2;
    ta_hdr.albion_timer.state_2 := io_hdr.albion_timer.state_2;
    ta_hdr.albion_timer.address_high_3 := io_hdr.albion_timer.address_high_3;
    ta_hdr.albion_timer.address_low_3 := io_hdr.albion_timer.address_low_3;
    ta_hdr.albion_timer.state_3 := io_hdr.albion_timer.state_3;
    ta_meta.state := io_meta.state;
    ta_meta.state_sub := io_meta.state_sub;
    ta_meta.session_id := io_meta.session_id;
    ta_meta.no_use := io_meta.no_use;
    ta_eg_dprsr_md.mirror_type := io_eg_dprsr_md.mirror_type;
    ta_pkt_external := true;
    ta_inbox_count := ta_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 1: host_recv -> io
  procurator_step := procurator_step + 1;
  // step 2: node_pass -> ta
  if (ta_inbox_count > 0) {
  assume ta_inbox_count > 0;
  ta_inbox_count := ta_inbox_count - 1;
  // DSL statements (per-pass instrumentation)
  if ((ta_hdr.albion.operation == 10bv32)) {
    dsl_pending := 1;
    dsl_steps := 0;
  }
  if ((ta_hdr.albion.operation == 100bv32)) {
    dsl_pending := 0;
    dsl_steps := 0;
  }
  if ((dsl_pending == 1)) {
    dsl_steps := dsl_steps + 1;
  }
  if ((ta_ig_tm_md.ucast_egress_port == 144bv9)) {
    dsl_client_seen := 1;
  }
  call ta_mainProcedure();
  if (ta_p4b_clone_i2e) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_clone_i2e := false;
  if (ta_p4b_clone_e2e) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_clone_e2e := false;
  if (ta_p4b_clone_i2i) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_clone_i2i := false;
  if (ta_p4b_recirculate) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_recirculate := false;
  call ta_Forward();
  // Global assertions (accumulated into procurator_bad)
  if (!(!(((dsl_pending == 1) && (dsl_steps > 3))))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  // step 3: node_pass -> tb
  if (tb_inbox_count > 0) {
  assume tb_inbox_count > 0;
  tb_inbox_count := tb_inbox_count - 1;
  call tb_mainProcedure();
  if (tb_p4b_clone_i2e) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_clone_i2e := false;
  if (tb_p4b_clone_e2e) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_clone_e2e := false;
  if (tb_p4b_clone_i2i) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_clone_i2i := false;
  if (tb_p4b_recirculate) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_recirculate := false;
  call tb_Forward();
  // Global assertions (accumulated into procurator_bad)
  if (!(!(((dsl_pending == 1) && (dsl_steps > 3))))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  // step 4: host_send -> io
  // inject packet into connected node (host -> node)
  if (ta_inbox_count < 1) {
    assume ta_inbox_count < 1;
    havoc io_hdr.albion.operation;
    havoc io_hdr.albion_timer.times;
    havoc io_hdr.albion_timer.const_time;
    havoc io_hdr.albion_timer.address_high_0;
    havoc io_hdr.albion_timer.address_low_0;
    havoc io_hdr.albion_timer.state_0;
    havoc io_hdr.albion_timer.address_high_1;
    havoc io_hdr.albion_timer.address_low_1;
    havoc io_hdr.albion_timer.state_1;
    havoc io_hdr.albion_timer.address_high_2;
    havoc io_hdr.albion_timer.address_low_2;
    havoc io_hdr.albion_timer.state_2;
    havoc io_hdr.albion_timer.address_high_3;
    havoc io_hdr.albion_timer.address_low_3;
    havoc io_hdr.albion_timer.state_3;
    havoc io_meta.state;
    havoc io_meta.state_sub;
    havoc io_meta.session_id;
    havoc io_meta.no_use;
    havoc io_eg_dprsr_md.mirror_type;
    io_hdr.ethernet.valid := true;
    io_hdr.ethernet.ether_type := 21845bv16;
    io_hdr.albion.valid := true;
    io_hdr.albion.CS_id_1 := 0bv32;
    io_hdr.albion.CS_id_2 := 0bv32;
    io_hdr.albion.CS_id_3 := 0bv32;
    io_hdr.albion.CS_offset_1 := 0bv32;
    io_hdr.albion.CS_offset_2 := 0bv32;
    io_hdr.albion.CS_offset_3 := 0bv32;
    io_hdr.albion.address_h := 0bv32;
    io_hdr.albion.address_l := 0bv32;
    io_hdr.albion.index := 0bv32;
    io_hdr.albion.num := 0bv32;
    io_hdr.albion.port := 0bv16;
    io_hdr.albion.request_id_high := 0bv32;
    io_hdr.albion.request_id_low := 0bv32;
    io_hdr.albion.time := 0bv32;
    io_hdr.albion_timer.valid := false;
    io_hdr.albion_data.valid := false;
    if ((dsl_phase == 0)) {
      io_hdr.albion.operation := 10bv32;
      dsl_phase := 1;
    } else {
      io_hdr.albion.operation := 0bv32;
    }
    ta_hdr.ethernet.valid := io_hdr.ethernet.valid;
    ta_hdr.ethernet.ether_type := io_hdr.ethernet.ether_type;
    ta_hdr.albion.valid := io_hdr.albion.valid;
    ta_hdr.albion.request_id_high := io_hdr.albion.request_id_high;
    ta_hdr.albion.request_id_low := io_hdr.albion.request_id_low;
    ta_hdr.albion.operation := io_hdr.albion.operation;
    ta_hdr.albion.address_h := io_hdr.albion.address_h;
    ta_hdr.albion.address_l := io_hdr.albion.address_l;
    ta_hdr.albion.time := io_hdr.albion.time;
    ta_hdr.albion.num := io_hdr.albion.num;
    ta_hdr.albion.index := io_hdr.albion.index;
    ta_hdr.albion.CS_id_1 := io_hdr.albion.CS_id_1;
    ta_hdr.albion.CS_offset_1 := io_hdr.albion.CS_offset_1;
    ta_hdr.albion.CS_id_2 := io_hdr.albion.CS_id_2;
    ta_hdr.albion.CS_offset_2 := io_hdr.albion.CS_offset_2;
    ta_hdr.albion.CS_id_3 := io_hdr.albion.CS_id_3;
    ta_hdr.albion.CS_offset_3 := io_hdr.albion.CS_offset_3;
    ta_hdr.albion.port := io_hdr.albion.port;
    ta_hdr.albion_data.valid := io_hdr.albion_data.valid;
    ta_hdr.albion_timer.valid := io_hdr.albion_timer.valid;
    ta_hdr.albion_timer.times := io_hdr.albion_timer.times;
    ta_hdr.albion_timer.const_time := io_hdr.albion_timer.const_time;
    ta_hdr.albion_timer.address_high_0 := io_hdr.albion_timer.address_high_0;
    ta_hdr.albion_timer.address_low_0 := io_hdr.albion_timer.address_low_0;
    ta_hdr.albion_timer.state_0 := io_hdr.albion_timer.state_0;
    ta_hdr.albion_timer.address_high_1 := io_hdr.albion_timer.address_high_1;
    ta_hdr.albion_timer.address_low_1 := io_hdr.albion_timer.address_low_1;
    ta_hdr.albion_timer.state_1 := io_hdr.albion_timer.state_1;
    ta_hdr.albion_timer.address_high_2 := io_hdr.albion_timer.address_high_2;
    ta_hdr.albion_timer.address_low_2 := io_hdr.albion_timer.address_low_2;
    ta_hdr.albion_timer.state_2 := io_hdr.albion_timer.state_2;
    ta_hdr.albion_timer.address_high_3 := io_hdr.albion_timer.address_high_3;
    ta_hdr.albion_timer.address_low_3 := io_hdr.albion_timer.address_low_3;
    ta_hdr.albion_timer.state_3 := io_hdr.albion_timer.state_3;
    ta_meta.state := io_meta.state;
    ta_meta.state_sub := io_meta.state_sub;
    ta_meta.session_id := io_meta.session_id;
    ta_meta.no_use := io_meta.no_use;
    ta_eg_dprsr_md.mirror_type := io_eg_dprsr_md.mirror_type;
    ta_pkt_external := true;
    ta_inbox_count := ta_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 5: host_recv -> io
  procurator_step := procurator_step + 1;
  // step 6: node_pass -> ta
  if (ta_inbox_count > 0) {
  assume ta_inbox_count > 0;
  ta_inbox_count := ta_inbox_count - 1;
  // DSL statements (per-pass instrumentation)
  if ((ta_hdr.albion.operation == 10bv32)) {
    dsl_pending := 1;
    dsl_steps := 0;
  }
  if ((ta_hdr.albion.operation == 100bv32)) {
    dsl_pending := 0;
    dsl_steps := 0;
  }
  if ((dsl_pending == 1)) {
    dsl_steps := dsl_steps + 1;
  }
  if ((ta_ig_tm_md.ucast_egress_port == 144bv9)) {
    dsl_client_seen := 1;
  }
  call ta_mainProcedure();
  if (ta_p4b_clone_i2e) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_clone_i2e := false;
  if (ta_p4b_clone_e2e) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_clone_e2e := false;
  if (ta_p4b_clone_i2i) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_clone_i2i := false;
  if (ta_p4b_recirculate) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_recirculate := false;
  call ta_Forward();
  // Global assertions (accumulated into procurator_bad)
  if (!(!(((dsl_pending == 1) && (dsl_steps > 3))))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  // step 7: node_pass -> tb
  if (tb_inbox_count > 0) {
  assume tb_inbox_count > 0;
  tb_inbox_count := tb_inbox_count - 1;
  call tb_mainProcedure();
  if (tb_p4b_clone_i2e) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_clone_i2e := false;
  if (tb_p4b_clone_e2e) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_clone_e2e := false;
  if (tb_p4b_clone_i2i) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_clone_i2i := false;
  if (tb_p4b_recirculate) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_recirculate := false;
  call tb_Forward();
  // Global assertions (accumulated into procurator_bad)
  if (!(!(((dsl_pending == 1) && (dsl_steps > 3))))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  // step 8: host_send -> io
  // inject packet into connected node (host -> node)
  if (ta_inbox_count < 1) {
    assume ta_inbox_count < 1;
    havoc io_hdr.albion.operation;
    havoc io_hdr.albion_timer.times;
    havoc io_hdr.albion_timer.const_time;
    havoc io_hdr.albion_timer.address_high_0;
    havoc io_hdr.albion_timer.address_low_0;
    havoc io_hdr.albion_timer.state_0;
    havoc io_hdr.albion_timer.address_high_1;
    havoc io_hdr.albion_timer.address_low_1;
    havoc io_hdr.albion_timer.state_1;
    havoc io_hdr.albion_timer.address_high_2;
    havoc io_hdr.albion_timer.address_low_2;
    havoc io_hdr.albion_timer.state_2;
    havoc io_hdr.albion_timer.address_high_3;
    havoc io_hdr.albion_timer.address_low_3;
    havoc io_hdr.albion_timer.state_3;
    havoc io_meta.state;
    havoc io_meta.state_sub;
    havoc io_meta.session_id;
    havoc io_meta.no_use;
    havoc io_eg_dprsr_md.mirror_type;
    io_hdr.ethernet.valid := true;
    io_hdr.ethernet.ether_type := 21845bv16;
    io_hdr.albion.valid := true;
    io_hdr.albion.CS_id_1 := 0bv32;
    io_hdr.albion.CS_id_2 := 0bv32;
    io_hdr.albion.CS_id_3 := 0bv32;
    io_hdr.albion.CS_offset_1 := 0bv32;
    io_hdr.albion.CS_offset_2 := 0bv32;
    io_hdr.albion.CS_offset_3 := 0bv32;
    io_hdr.albion.address_h := 0bv32;
    io_hdr.albion.address_l := 0bv32;
    io_hdr.albion.index := 0bv32;
    io_hdr.albion.num := 0bv32;
    io_hdr.albion.port := 0bv16;
    io_hdr.albion.request_id_high := 0bv32;
    io_hdr.albion.request_id_low := 0bv32;
    io_hdr.albion.time := 0bv32;
    io_hdr.albion_timer.valid := false;
    io_hdr.albion_data.valid := false;
    if ((dsl_phase == 0)) {
      io_hdr.albion.operation := 10bv32;
      dsl_phase := 1;
    } else {
      io_hdr.albion.operation := 0bv32;
    }
    ta_hdr.ethernet.valid := io_hdr.ethernet.valid;
    ta_hdr.ethernet.ether_type := io_hdr.ethernet.ether_type;
    ta_hdr.albion.valid := io_hdr.albion.valid;
    ta_hdr.albion.request_id_high := io_hdr.albion.request_id_high;
    ta_hdr.albion.request_id_low := io_hdr.albion.request_id_low;
    ta_hdr.albion.operation := io_hdr.albion.operation;
    ta_hdr.albion.address_h := io_hdr.albion.address_h;
    ta_hdr.albion.address_l := io_hdr.albion.address_l;
    ta_hdr.albion.time := io_hdr.albion.time;
    ta_hdr.albion.num := io_hdr.albion.num;
    ta_hdr.albion.index := io_hdr.albion.index;
    ta_hdr.albion.CS_id_1 := io_hdr.albion.CS_id_1;
    ta_hdr.albion.CS_offset_1 := io_hdr.albion.CS_offset_1;
    ta_hdr.albion.CS_id_2 := io_hdr.albion.CS_id_2;
    ta_hdr.albion.CS_offset_2 := io_hdr.albion.CS_offset_2;
    ta_hdr.albion.CS_id_3 := io_hdr.albion.CS_id_3;
    ta_hdr.albion.CS_offset_3 := io_hdr.albion.CS_offset_3;
    ta_hdr.albion.port := io_hdr.albion.port;
    ta_hdr.albion_data.valid := io_hdr.albion_data.valid;
    ta_hdr.albion_timer.valid := io_hdr.albion_timer.valid;
    ta_hdr.albion_timer.times := io_hdr.albion_timer.times;
    ta_hdr.albion_timer.const_time := io_hdr.albion_timer.const_time;
    ta_hdr.albion_timer.address_high_0 := io_hdr.albion_timer.address_high_0;
    ta_hdr.albion_timer.address_low_0 := io_hdr.albion_timer.address_low_0;
    ta_hdr.albion_timer.state_0 := io_hdr.albion_timer.state_0;
    ta_hdr.albion_timer.address_high_1 := io_hdr.albion_timer.address_high_1;
    ta_hdr.albion_timer.address_low_1 := io_hdr.albion_timer.address_low_1;
    ta_hdr.albion_timer.state_1 := io_hdr.albion_timer.state_1;
    ta_hdr.albion_timer.address_high_2 := io_hdr.albion_timer.address_high_2;
    ta_hdr.albion_timer.address_low_2 := io_hdr.albion_timer.address_low_2;
    ta_hdr.albion_timer.state_2 := io_hdr.albion_timer.state_2;
    ta_hdr.albion_timer.address_high_3 := io_hdr.albion_timer.address_high_3;
    ta_hdr.albion_timer.address_low_3 := io_hdr.albion_timer.address_low_3;
    ta_hdr.albion_timer.state_3 := io_hdr.albion_timer.state_3;
    ta_meta.state := io_meta.state;
    ta_meta.state_sub := io_meta.state_sub;
    ta_meta.session_id := io_meta.session_id;
    ta_meta.no_use := io_meta.no_use;
    ta_eg_dprsr_md.mirror_type := io_eg_dprsr_md.mirror_type;
    ta_pkt_external := true;
    ta_inbox_count := ta_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 9: host_recv -> io
  procurator_step := procurator_step + 1;
  // step 10: node_pass -> ta
  if (ta_inbox_count > 0) {
  assume ta_inbox_count > 0;
  ta_inbox_count := ta_inbox_count - 1;
  // DSL statements (per-pass instrumentation)
  if ((ta_hdr.albion.operation == 10bv32)) {
    dsl_pending := 1;
    dsl_steps := 0;
  }
  if ((ta_hdr.albion.operation == 100bv32)) {
    dsl_pending := 0;
    dsl_steps := 0;
  }
  if ((dsl_pending == 1)) {
    dsl_steps := dsl_steps + 1;
  }
  if ((ta_ig_tm_md.ucast_egress_port == 144bv9)) {
    dsl_client_seen := 1;
  }
  call ta_mainProcedure();
  if (ta_p4b_clone_i2e) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_clone_i2e := false;
  if (ta_p4b_clone_e2e) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_clone_e2e := false;
  if (ta_p4b_clone_i2i) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_clone_i2i := false;
  if (ta_p4b_recirculate) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_recirculate := false;
  call ta_Forward();
  // Global assertions (accumulated into procurator_bad)
  if (!(!(((dsl_pending == 1) && (dsl_steps > 3))))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  // step 11: node_pass -> tb
  if (tb_inbox_count > 0) {
  assume tb_inbox_count > 0;
  tb_inbox_count := tb_inbox_count - 1;
  call tb_mainProcedure();
  if (tb_p4b_clone_i2e) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_clone_i2e := false;
  if (tb_p4b_clone_e2e) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_clone_e2e := false;
  if (tb_p4b_clone_i2i) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_clone_i2i := false;
  if (tb_p4b_recirculate) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_recirculate := false;
  call tb_Forward();
  // Global assertions (accumulated into procurator_bad)
  if (!(!(((dsl_pending == 1) && (dsl_steps > 3))))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  // step 12: host_send -> io
  // inject packet into connected node (host -> node)
  if (ta_inbox_count < 1) {
    assume ta_inbox_count < 1;
    havoc io_hdr.albion.operation;
    havoc io_hdr.albion_timer.times;
    havoc io_hdr.albion_timer.const_time;
    havoc io_hdr.albion_timer.address_high_0;
    havoc io_hdr.albion_timer.address_low_0;
    havoc io_hdr.albion_timer.state_0;
    havoc io_hdr.albion_timer.address_high_1;
    havoc io_hdr.albion_timer.address_low_1;
    havoc io_hdr.albion_timer.state_1;
    havoc io_hdr.albion_timer.address_high_2;
    havoc io_hdr.albion_timer.address_low_2;
    havoc io_hdr.albion_timer.state_2;
    havoc io_hdr.albion_timer.address_high_3;
    havoc io_hdr.albion_timer.address_low_3;
    havoc io_hdr.albion_timer.state_3;
    havoc io_meta.state;
    havoc io_meta.state_sub;
    havoc io_meta.session_id;
    havoc io_meta.no_use;
    havoc io_eg_dprsr_md.mirror_type;
    io_hdr.ethernet.valid := true;
    io_hdr.ethernet.ether_type := 21845bv16;
    io_hdr.albion.valid := true;
    io_hdr.albion.CS_id_1 := 0bv32;
    io_hdr.albion.CS_id_2 := 0bv32;
    io_hdr.albion.CS_id_3 := 0bv32;
    io_hdr.albion.CS_offset_1 := 0bv32;
    io_hdr.albion.CS_offset_2 := 0bv32;
    io_hdr.albion.CS_offset_3 := 0bv32;
    io_hdr.albion.address_h := 0bv32;
    io_hdr.albion.address_l := 0bv32;
    io_hdr.albion.index := 0bv32;
    io_hdr.albion.num := 0bv32;
    io_hdr.albion.port := 0bv16;
    io_hdr.albion.request_id_high := 0bv32;
    io_hdr.albion.request_id_low := 0bv32;
    io_hdr.albion.time := 0bv32;
    io_hdr.albion_timer.valid := false;
    io_hdr.albion_data.valid := false;
    if ((dsl_phase == 0)) {
      io_hdr.albion.operation := 10bv32;
      dsl_phase := 1;
    } else {
      io_hdr.albion.operation := 0bv32;
    }
    ta_hdr.ethernet.valid := io_hdr.ethernet.valid;
    ta_hdr.ethernet.ether_type := io_hdr.ethernet.ether_type;
    ta_hdr.albion.valid := io_hdr.albion.valid;
    ta_hdr.albion.request_id_high := io_hdr.albion.request_id_high;
    ta_hdr.albion.request_id_low := io_hdr.albion.request_id_low;
    ta_hdr.albion.operation := io_hdr.albion.operation;
    ta_hdr.albion.address_h := io_hdr.albion.address_h;
    ta_hdr.albion.address_l := io_hdr.albion.address_l;
    ta_hdr.albion.time := io_hdr.albion.time;
    ta_hdr.albion.num := io_hdr.albion.num;
    ta_hdr.albion.index := io_hdr.albion.index;
    ta_hdr.albion.CS_id_1 := io_hdr.albion.CS_id_1;
    ta_hdr.albion.CS_offset_1 := io_hdr.albion.CS_offset_1;
    ta_hdr.albion.CS_id_2 := io_hdr.albion.CS_id_2;
    ta_hdr.albion.CS_offset_2 := io_hdr.albion.CS_offset_2;
    ta_hdr.albion.CS_id_3 := io_hdr.albion.CS_id_3;
    ta_hdr.albion.CS_offset_3 := io_hdr.albion.CS_offset_3;
    ta_hdr.albion.port := io_hdr.albion.port;
    ta_hdr.albion_data.valid := io_hdr.albion_data.valid;
    ta_hdr.albion_timer.valid := io_hdr.albion_timer.valid;
    ta_hdr.albion_timer.times := io_hdr.albion_timer.times;
    ta_hdr.albion_timer.const_time := io_hdr.albion_timer.const_time;
    ta_hdr.albion_timer.address_high_0 := io_hdr.albion_timer.address_high_0;
    ta_hdr.albion_timer.address_low_0 := io_hdr.albion_timer.address_low_0;
    ta_hdr.albion_timer.state_0 := io_hdr.albion_timer.state_0;
    ta_hdr.albion_timer.address_high_1 := io_hdr.albion_timer.address_high_1;
    ta_hdr.albion_timer.address_low_1 := io_hdr.albion_timer.address_low_1;
    ta_hdr.albion_timer.state_1 := io_hdr.albion_timer.state_1;
    ta_hdr.albion_timer.address_high_2 := io_hdr.albion_timer.address_high_2;
    ta_hdr.albion_timer.address_low_2 := io_hdr.albion_timer.address_low_2;
    ta_hdr.albion_timer.state_2 := io_hdr.albion_timer.state_2;
    ta_hdr.albion_timer.address_high_3 := io_hdr.albion_timer.address_high_3;
    ta_hdr.albion_timer.address_low_3 := io_hdr.albion_timer.address_low_3;
    ta_hdr.albion_timer.state_3 := io_hdr.albion_timer.state_3;
    ta_meta.state := io_meta.state;
    ta_meta.state_sub := io_meta.state_sub;
    ta_meta.session_id := io_meta.session_id;
    ta_meta.no_use := io_meta.no_use;
    ta_eg_dprsr_md.mirror_type := io_eg_dprsr_md.mirror_type;
    ta_pkt_external := true;
    ta_inbox_count := ta_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 13: host_recv -> io
  procurator_step := procurator_step + 1;
  // step 14: node_pass -> ta
  if (ta_inbox_count > 0) {
  assume ta_inbox_count > 0;
  ta_inbox_count := ta_inbox_count - 1;
  // DSL statements (per-pass instrumentation)
  if ((ta_hdr.albion.operation == 10bv32)) {
    dsl_pending := 1;
    dsl_steps := 0;
  }
  if ((ta_hdr.albion.operation == 100bv32)) {
    dsl_pending := 0;
    dsl_steps := 0;
  }
  if ((dsl_pending == 1)) {
    dsl_steps := dsl_steps + 1;
  }
  if ((ta_ig_tm_md.ucast_egress_port == 144bv9)) {
    dsl_client_seen := 1;
  }
  call ta_mainProcedure();
  if (ta_p4b_clone_i2e) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_clone_i2e := false;
  if (ta_p4b_clone_e2e) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_clone_e2e := false;
  if (ta_p4b_clone_i2i) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_clone_i2i := false;
  if (ta_p4b_recirculate) {
    assume ta_inbox_count < 1;
    ta_pkt_external := false;
    ta_inbox_count := ta_inbox_count + 1;
  }
  ta_p4b_recirculate := false;
  call ta_Forward();
  // Global assertions (accumulated into procurator_bad)
  if (!(!(((dsl_pending == 1) && (dsl_steps > 3))))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  // step 15: node_pass -> tb
  if (tb_inbox_count > 0) {
  assume tb_inbox_count > 0;
  tb_inbox_count := tb_inbox_count - 1;
  call tb_mainProcedure();
  if (tb_p4b_clone_i2e) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_clone_i2e := false;
  if (tb_p4b_clone_e2e) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_clone_e2e := false;
  if (tb_p4b_clone_i2i) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_clone_i2i := false;
  if (tb_p4b_recirculate) {
    assume tb_inbox_count < 1;
    tb_pkt_external := false;
    tb_inbox_count := tb_inbox_count + 1;
  }
  tb_p4b_recirculate := false;
  call tb_Forward();
  // Global assertions (accumulated into procurator_bad)
  if (!(!(((dsl_pending == 1) && (dsl_steps > 3))))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  assert !procurator_bad;
}


procedure ULTIMATE.start() returns()
  modifies dsl_client_seen, dsl_pending, dsl_phase, dsl_steps, io_eg_dprsr_md.mirror_type, io_hdr.albion.CS_id_1, io_hdr.albion.CS_id_2, io_hdr.albion.CS_id_3, io_hdr.albion.CS_offset_1, io_hdr.albion.CS_offset_2, io_hdr.albion.CS_offset_3, io_hdr.albion.address_h, io_hdr.albion.address_l, io_hdr.albion.index, io_hdr.albion.num, io_hdr.albion.operation, io_hdr.albion.port, io_hdr.albion.request_id_high, io_hdr.albion.request_id_low, io_hdr.albion.time, io_hdr.albion.valid, io_hdr.albion_data.valid, io_hdr.albion_timer.address_high_0, io_hdr.albion_timer.address_high_1, io_hdr.albion_timer.address_high_2, io_hdr.albion_timer.address_high_3, io_hdr.albion_timer.address_low_0, io_hdr.albion_timer.address_low_1, io_hdr.albion_timer.address_low_2, io_hdr.albion_timer.address_low_3, io_hdr.albion_timer.const_time, io_hdr.albion_timer.state_0, io_hdr.albion_timer.state_1, io_hdr.albion_timer.state_2, io_hdr.albion_timer.state_3, io_hdr.albion_timer.times, io_hdr.albion_timer.valid, io_hdr.ethernet.ether_type, io_hdr.ethernet.valid, io_inbox_count, io_meta.no_use, io_meta.session_id, io_meta.state, io_meta.state_sub, io_pkt_external, procurator_bad, procurator_step, ta___ra_ret_register_address_h_record_0_read_0, ta___ra_ret_register_address_h_record_0_write_0, ta___ra_ret_register_address_h_record_1_read_0, ta___ra_ret_register_address_h_record_1_write_0, ta___ra_ret_register_address_h_record_2_read_0, ta___ra_ret_register_address_h_record_2_write_0, ta___ra_ret_register_address_h_record_3_read_0, ta___ra_ret_register_address_h_record_3_write_0, ta___ra_ret_register_address_l_record_0_read_0, ta___ra_ret_register_address_l_record_0_write_0, ta___ra_ret_register_address_l_record_1_read_0, ta___ra_ret_register_address_l_record_1_write_0, ta___ra_ret_register_address_l_record_2_read_0, ta___ra_ret_register_address_l_record_2_write_0, ta___ra_ret_register_address_l_record_3_read_0, ta___ra_ret_register_address_l_record_3_write_0, ta___ra_ret_register_num_add_0, ta___ra_ret_register_num_zero_0, ta___ra_ret_register_request_id_high_add_0, ta___ra_ret_register_request_id_low_add_0, ta___ra_ret_register_state_0_r_0, ta___ra_ret_register_state_0_sub_0, ta___ra_ret_register_state_0_w_0, ta___ra_ret_register_state_1_r_0, ta___ra_ret_register_state_1_sub_0, ta___ra_ret_register_state_1_w_0, ta___ra_ret_register_state_2_r_0, ta___ra_ret_register_state_2_sub_0, ta___ra_ret_register_state_2_w_0, ta___ra_ret_register_state_3_r_0, ta___ra_ret_register_state_3_sub_0, ta___ra_ret_register_state_3_w_0, ta___ra_ret_register_timer_add_0, ta___ra_ret_register_timer_read_0, ta___ra_val_register_address_h_record_0_read_0, ta___ra_val_register_address_h_record_0_write_0, ta___ra_val_register_address_h_record_1_read_0, ta___ra_val_register_address_h_record_1_write_0, ta___ra_val_register_address_h_record_2_read_0, ta___ra_val_register_address_h_record_2_write_0, ta___ra_val_register_address_h_record_3_read_0, ta___ra_val_register_address_h_record_3_write_0, ta___ra_val_register_address_l_record_0_read_0, ta___ra_val_register_address_l_record_0_write_0, ta___ra_val_register_address_l_record_1_read_0, ta___ra_val_register_address_l_record_1_write_0, ta___ra_val_register_address_l_record_2_read_0, ta___ra_val_register_address_l_record_2_write_0, ta___ra_val_register_address_l_record_3_read_0, ta___ra_val_register_address_l_record_3_write_0, ta___ra_val_register_num_add_0, ta___ra_val_register_num_zero_0, ta___ra_val_register_request_id_high_add_0, ta___ra_val_register_request_id_low_add_0, ta___ra_val_register_state_0_r_0, ta___ra_val_register_state_0_sub_0, ta___ra_val_register_state_0_w_0, ta___ra_val_register_state_1_r_0, ta___ra_val_register_state_1_sub_0, ta___ra_val_register_state_1_w_0, ta___ra_val_register_state_2_r_0, ta___ra_val_register_state_2_sub_0, ta___ra_val_register_state_2_w_0, ta___ra_val_register_state_3_r_0, ta___ra_val_register_state_3_sub_0, ta___ra_val_register_state_3_w_0, ta___ra_val_register_timer_add_0, ta___ra_val_register_timer_read_0, ta_drop, ta_eg_dprsr_md.mirror_type, ta_hdr.albion.CS_id_1, ta_hdr.albion.CS_id_2, ta_hdr.albion.CS_id_3, ta_hdr.albion.CS_offset_1, ta_hdr.albion.CS_offset_2, ta_hdr.albion.CS_offset_3, ta_hdr.albion.address_h, ta_hdr.albion.address_l, ta_hdr.albion.index, ta_hdr.albion.num, ta_hdr.albion.operation, ta_hdr.albion.port, ta_hdr.albion.request_id_high, ta_hdr.albion.request_id_low, ta_hdr.albion.time, ta_hdr.albion.valid, ta_hdr.albion_data.valid, ta_hdr.albion_timer.address_high_0, ta_hdr.albion_timer.address_high_1, ta_hdr.albion_timer.address_high_2, ta_hdr.albion_timer.address_high_3, ta_hdr.albion_timer.address_low_0, ta_hdr.albion_timer.address_low_1, ta_hdr.albion_timer.address_low_2, ta_hdr.albion_timer.address_low_3, ta_hdr.albion_timer.const_time, ta_hdr.albion_timer.state_0, ta_hdr.albion_timer.state_1, ta_hdr.albion_timer.state_2, ta_hdr.albion_timer.state_3, ta_hdr.albion_timer.times, ta_hdr.albion_timer.valid, ta_hdr.ethernet.ether_type, ta_hdr.ethernet.valid, ta_ig_tm_md.ucast_egress_port, ta_inbox_count, ta_isValid, ta_meta.no_use, ta_meta.session_id, ta_meta.state, ta_meta.state_sub, ta_mirror_md_0, ta_p4b_checksum_error, ta_p4b_checksum_updated, ta_p4b_checksum_verified, ta_p4b_clone_e2e, ta_p4b_clone_i2e, ta_p4b_clone_i2i, ta_p4b_digest, ta_p4b_recirculate, ta_pkt_external, ta_register_address_h_record, ta_register_address_h_record_4, ta_register_address_h_record_4__last0_old_value, ta_register_address_h_record_4__last0_value, ta_register_address_h_record_4__last_index, ta_register_address_h_record_4__last_old_value, ta_register_address_h_record_4__last_value, ta_register_address_h_record_4__last_write_site, ta_register_address_h_record_4__next_write_site, ta_register_address_h_record_4__wrote_any, ta_register_address_h_record_4__wrote_index0, ta_register_address_h_record_5, ta_register_address_h_record_5__last0_old_value, ta_register_address_h_record_5__last0_value, ta_register_address_h_record_5__last_index, ta_register_address_h_record_5__last_old_value, ta_register_address_h_record_5__last_value, ta_register_address_h_record_5__last_write_site, ta_register_address_h_record_5__next_write_site, ta_register_address_h_record_5__wrote_any, ta_register_address_h_record_5__wrote_index0, ta_register_address_h_record_6, ta_register_address_h_record_6__last0_old_value, ta_register_address_h_record_6__last0_value, ta_register_address_h_record_6__last_index, ta_register_address_h_record_6__last_old_value, ta_register_address_h_record_6__last_value, ta_register_address_h_record_6__last_write_site, ta_register_address_h_record_6__next_write_site, ta_register_address_h_record_6__wrote_any, ta_register_address_h_record_6__wrote_index0, ta_register_address_h_record__last0_old_value, ta_register_address_h_record__last0_value, ta_register_address_h_record__last_index, ta_register_address_h_record__last_old_value, ta_register_address_h_record__last_value, ta_register_address_h_record__last_write_site, ta_register_address_h_record__next_write_site, ta_register_address_h_record__wrote_any, ta_register_address_h_record__wrote_index0, ta_register_address_l_record, ta_register_address_l_record_4, ta_register_address_l_record_4__last0_old_value, ta_register_address_l_record_4__last0_value, ta_register_address_l_record_4__last_index, ta_register_address_l_record_4__last_old_value, ta_register_address_l_record_4__last_value, ta_register_address_l_record_4__last_write_site, ta_register_address_l_record_4__next_write_site, ta_register_address_l_record_4__wrote_any, ta_register_address_l_record_4__wrote_index0, ta_register_address_l_record_5, ta_register_address_l_record_5__last0_old_value, ta_register_address_l_record_5__last0_value, ta_register_address_l_record_5__last_index, ta_register_address_l_record_5__last_old_value, ta_register_address_l_record_5__last_value, ta_register_address_l_record_5__last_write_site, ta_register_address_l_record_5__next_write_site, ta_register_address_l_record_5__wrote_any, ta_register_address_l_record_5__wrote_index0, ta_register_address_l_record_6, ta_register_address_l_record_6__last0_old_value, ta_register_address_l_record_6__last0_value, ta_register_address_l_record_6__last_index, ta_register_address_l_record_6__last_old_value, ta_register_address_l_record_6__last_value, ta_register_address_l_record_6__last_write_site, ta_register_address_l_record_6__next_write_site, ta_register_address_l_record_6__wrote_any, ta_register_address_l_record_6__wrote_index0, ta_register_address_l_record__last0_old_value, ta_register_address_l_record__last0_value, ta_register_address_l_record__last_index, ta_register_address_l_record__last_old_value, ta_register_address_l_record__last_value, ta_register_address_l_record__last_write_site, ta_register_address_l_record__next_write_site, ta_register_address_l_record__wrote_any, ta_register_address_l_record__wrote_index0, ta_register_num_0, ta_register_num_0__last0_old_value, ta_register_num_0__last0_value, ta_register_num_0__last_index, ta_register_num_0__last_old_value, ta_register_num_0__last_value, ta_register_num_0__last_write_site, ta_register_num_0__next_write_site, ta_register_num_0__wrote_any, ta_register_num_0__wrote_index0, ta_register_request_id_high_0, ta_register_request_id_high_0__last0_old_value, ta_register_request_id_high_0__last0_value, ta_register_request_id_high_0__last_index, ta_register_request_id_high_0__last_old_value, ta_register_request_id_high_0__last_value, ta_register_request_id_high_0__last_write_site, ta_register_request_id_high_0__next_write_site, ta_register_request_id_high_0__wrote_any, ta_register_request_id_high_0__wrote_index0, ta_register_request_id_low_0, ta_register_request_id_low_0__last0_old_value, ta_register_request_id_low_0__last0_value, ta_register_request_id_low_0__last_index, ta_register_request_id_low_0__last_old_value, ta_register_request_id_low_0__last_value, ta_register_request_id_low_0__last_write_site, ta_register_request_id_low_0__next_write_site, ta_register_request_id_low_0__wrote_any, ta_register_request_id_low_0__wrote_index0, ta_register_state, ta_register_state_4, ta_register_state_4__last0_old_value, ta_register_state_4__last0_value, ta_register_state_4__last_index, ta_register_state_4__last_old_value, ta_register_state_4__last_value, ta_register_state_4__last_write_site, ta_register_state_4__next_write_site, ta_register_state_4__wrote_any, ta_register_state_4__wrote_index0, ta_register_state_5, ta_register_state_5__last0_old_value, ta_register_state_5__last0_value, ta_register_state_5__last_index, ta_register_state_5__last_old_value, ta_register_state_5__last_value, ta_register_state_5__last_write_site, ta_register_state_5__next_write_site, ta_register_state_5__wrote_any, ta_register_state_5__wrote_index0, ta_register_state_6, ta_register_state_6__last0_old_value, ta_register_state_6__last0_value, ta_register_state_6__last_index, ta_register_state_6__last_old_value, ta_register_state_6__last_value, ta_register_state_6__last_write_site, ta_register_state_6__next_write_site, ta_register_state_6__wrote_any, ta_register_state_6__wrote_index0, ta_register_state__last0_old_value, ta_register_state__last0_value, ta_register_state__last_index, ta_register_state__last_old_value, ta_register_state__last_value, ta_register_state__last_write_site, ta_register_state__next_write_site, ta_register_state__wrote_any, ta_register_state__wrote_index0, ta_register_timer_0, ta_register_timer_0__last0_old_value, ta_register_timer_0__last0_value, ta_register_timer_0__last_index, ta_register_timer_0__last_old_value, ta_register_timer_0__last_value, ta_register_timer_0__last_write_site, ta_register_timer_0__next_write_site, ta_register_timer_0__wrote_any, ta_register_timer_0__wrote_index0, ta_table_check_timer_0.action_run, ta_table_check_timer_0.hit, ta_table_register_address_h_record_0_interaction_0.action_run, ta_table_register_address_h_record_0_interaction_0.hit, ta_table_register_address_h_record_1_interaction_0.action_run, ta_table_register_address_h_record_1_interaction_0.hit, ta_table_register_address_h_record_2_interaction_0.action_run, ta_table_register_address_h_record_2_interaction_0.hit, ta_table_register_address_h_record_3_interaction_0.action_run, ta_table_register_address_h_record_3_interaction_0.hit, ta_table_register_address_l_record_0_interaction_0.action_run, ta_table_register_address_l_record_0_interaction_0.hit, ta_table_register_address_l_record_1_interaction_0.action_run, ta_table_register_address_l_record_1_interaction_0.hit, ta_table_register_address_l_record_2_interaction_0.action_run, ta_table_register_address_l_record_2_interaction_0.hit, ta_table_register_address_l_record_3_interaction_0.action_run, ta_table_register_address_l_record_3_interaction_0.hit, ta_table_register_num_interaction_0.action_run, ta_table_register_num_interaction_0.hit, ta_table_register_request_id_high_interaction_0.action_run, ta_table_register_request_id_high_interaction_0.hit, ta_table_register_state_0_interaction_0.action_run, ta_table_register_state_0_interaction_0.hit, ta_table_register_state_1_interaction_0.action_run, ta_table_register_state_1_interaction_0.hit, ta_table_register_state_2_interaction_0.action_run, ta_table_register_state_2_interaction_0.hit, ta_table_register_state_3_interaction_0.action_run, ta_table_register_state_3_interaction_0.hit, ta_table_register_timer_interaction_0.action_run, ta_table_register_timer_interaction_0.hit, ta_table_send_to_somewhere_0.action_run, ta_table_send_to_somewhere_0.hit, ta_table_state_check_0.action_run, ta_table_state_check_0.hit, ta_table_success_check_0.action_run, ta_table_success_check_0.hit, tb___ra_ret_register_data_record_0_write_0, tb___ra_ret_register_data_record_10_write_0, tb___ra_ret_register_data_record_11_write_0, tb___ra_ret_register_data_record_1_write_0, tb___ra_ret_register_data_record_2_write_0, tb___ra_ret_register_data_record_3_write_0, tb___ra_ret_register_data_record_4_write_0, tb___ra_ret_register_data_record_5_write_0, tb___ra_ret_register_data_record_6_write_0, tb___ra_ret_register_data_record_7_write_0, tb___ra_ret_register_data_record_8_write_0, tb___ra_ret_register_data_record_9_write_0, tb___ra_val_register_data_record_0_write_0, tb___ra_val_register_data_record_10_write_0, tb___ra_val_register_data_record_11_write_0, tb___ra_val_register_data_record_1_write_0, tb___ra_val_register_data_record_2_write_0, tb___ra_val_register_data_record_3_write_0, tb___ra_val_register_data_record_4_write_0, tb___ra_val_register_data_record_5_write_0, tb___ra_val_register_data_record_6_write_0, tb___ra_val_register_data_record_7_write_0, tb___ra_val_register_data_record_8_write_0, tb___ra_val_register_data_record_9_write_0, tb_drop, tb_eg_dprsr_md.mirror_type, tb_hdr.albion.CS_id_1, tb_hdr.albion.CS_id_2, tb_hdr.albion.CS_id_3, tb_hdr.albion.CS_offset_1, tb_hdr.albion.CS_offset_2, tb_hdr.albion.CS_offset_3, tb_hdr.albion.address_h, tb_hdr.albion.address_l, tb_hdr.albion.index, tb_hdr.albion.num, tb_hdr.albion.operation, tb_hdr.albion.port, tb_hdr.albion.request_id_high, tb_hdr.albion.request_id_low, tb_hdr.albion.time, tb_hdr.albion.valid, tb_hdr.albion_data.data_0, tb_hdr.albion_data.data_1, tb_hdr.albion_data.data_10, tb_hdr.albion_data.data_11, tb_hdr.albion_data.data_2, tb_hdr.albion_data.data_3, tb_hdr.albion_data.data_4, tb_hdr.albion_data.data_5, tb_hdr.albion_data.data_6, tb_hdr.albion_data.data_7, tb_hdr.albion_data.data_8, tb_hdr.albion_data.data_9, tb_hdr.albion_data.valid, tb_hdr.albion_timer.address_high_0, tb_hdr.albion_timer.address_high_1, tb_hdr.albion_timer.address_high_2, tb_hdr.albion_timer.address_high_3, tb_hdr.albion_timer.address_low_0, tb_hdr.albion_timer.address_low_1, tb_hdr.albion_timer.address_low_2, tb_hdr.albion_timer.address_low_3, tb_hdr.albion_timer.const_time, tb_hdr.albion_timer.state_0, tb_hdr.albion_timer.state_1, tb_hdr.albion_timer.state_2, tb_hdr.albion_timer.state_3, tb_hdr.albion_timer.times, tb_hdr.albion_timer.valid, tb_hdr.ethernet.ether_type, tb_hdr.ethernet.valid, tb_ig_tm_md.ucast_egress_port, tb_inbox_count, tb_isValid, tb_meta.no_use, tb_meta.session_id, tb_meta.state, tb_meta.state_sub, tb_mirror_md_0, tb_mirror_md_1, tb_mirror_md_2, tb_p4b_checksum_error, tb_p4b_checksum_updated, tb_p4b_checksum_verified, tb_p4b_clone_e2e, tb_p4b_clone_i2e, tb_p4b_clone_i2i, tb_p4b_digest, tb_p4b_recirculate, tb_pkt_external, tb_register_data_record, tb_register_data_record_12, tb_register_data_record_12__last0_old_value, tb_register_data_record_12__last0_value, tb_register_data_record_12__last_index, tb_register_data_record_12__last_old_value, tb_register_data_record_12__last_value, tb_register_data_record_12__last_write_site, tb_register_data_record_12__next_write_site, tb_register_data_record_12__wrote_any, tb_register_data_record_12__wrote_index0, tb_register_data_record_13, tb_register_data_record_13__last0_old_value, tb_register_data_record_13__last0_value, tb_register_data_record_13__last_index, tb_register_data_record_13__last_old_value, tb_register_data_record_13__last_value, tb_register_data_record_13__last_write_site, tb_register_data_record_13__next_write_site, tb_register_data_record_13__wrote_any, tb_register_data_record_13__wrote_index0, tb_register_data_record_14, tb_register_data_record_14__last0_old_value, tb_register_data_record_14__last0_value, tb_register_data_record_14__last_index, tb_register_data_record_14__last_old_value, tb_register_data_record_14__last_value, tb_register_data_record_14__last_write_site, tb_register_data_record_14__next_write_site, tb_register_data_record_14__wrote_any, tb_register_data_record_14__wrote_index0, tb_register_data_record_15, tb_register_data_record_15__last0_old_value, tb_register_data_record_15__last0_value, tb_register_data_record_15__last_index, tb_register_data_record_15__last_old_value, tb_register_data_record_15__last_value, tb_register_data_record_15__last_write_site, tb_register_data_record_15__next_write_site, tb_register_data_record_15__wrote_any, tb_register_data_record_15__wrote_index0, tb_register_data_record_16, tb_register_data_record_16__last0_old_value, tb_register_data_record_16__last0_value, tb_register_data_record_16__last_index, tb_register_data_record_16__last_old_value, tb_register_data_record_16__last_value, tb_register_data_record_16__last_write_site, tb_register_data_record_16__next_write_site, tb_register_data_record_16__wrote_any, tb_register_data_record_16__wrote_index0, tb_register_data_record_17, tb_register_data_record_17__last0_old_value, tb_register_data_record_17__last0_value, tb_register_data_record_17__last_index, tb_register_data_record_17__last_old_value, tb_register_data_record_17__last_value, tb_register_data_record_17__last_write_site, tb_register_data_record_17__next_write_site, tb_register_data_record_17__wrote_any, tb_register_data_record_17__wrote_index0, tb_register_data_record_18, tb_register_data_record_18__last0_old_value, tb_register_data_record_18__last0_value, tb_register_data_record_18__last_index, tb_register_data_record_18__last_old_value, tb_register_data_record_18__last_value, tb_register_data_record_18__last_write_site, tb_register_data_record_18__next_write_site, tb_register_data_record_18__wrote_any, tb_register_data_record_18__wrote_index0, tb_register_data_record_19, tb_register_data_record_19__last0_old_value, tb_register_data_record_19__last0_value, tb_register_data_record_19__last_index, tb_register_data_record_19__last_old_value, tb_register_data_record_19__last_value, tb_register_data_record_19__last_write_site, tb_register_data_record_19__next_write_site, tb_register_data_record_19__wrote_any, tb_register_data_record_19__wrote_index0, tb_register_data_record_20, tb_register_data_record_20__last0_old_value, tb_register_data_record_20__last0_value, tb_register_data_record_20__last_index, tb_register_data_record_20__last_old_value, tb_register_data_record_20__last_value, tb_register_data_record_20__last_write_site, tb_register_data_record_20__next_write_site, tb_register_data_record_20__wrote_any, tb_register_data_record_20__wrote_index0, tb_register_data_record_21, tb_register_data_record_21__last0_old_value, tb_register_data_record_21__last0_value, tb_register_data_record_21__last_index, tb_register_data_record_21__last_old_value, tb_register_data_record_21__last_value, tb_register_data_record_21__last_write_site, tb_register_data_record_21__next_write_site, tb_register_data_record_21__wrote_any, tb_register_data_record_21__wrote_index0, tb_register_data_record_22, tb_register_data_record_22__last0_old_value, tb_register_data_record_22__last0_value, tb_register_data_record_22__last_index, tb_register_data_record_22__last_old_value, tb_register_data_record_22__last_value, tb_register_data_record_22__last_write_site, tb_register_data_record_22__next_write_site, tb_register_data_record_22__wrote_any, tb_register_data_record_22__wrote_index0, tb_register_data_record__last0_old_value, tb_register_data_record__last0_value, tb_register_data_record__last_index, tb_register_data_record__last_old_value, tb_register_data_record__last_value, tb_register_data_record__last_write_site, tb_register_data_record__next_write_site, tb_register_data_record__wrote_any, tb_register_data_record__wrote_index0, tb_table_dst_cs.action_run, tb_table_dst_cs.hit, tb_table_dst_cs_0.action_run, tb_table_dst_cs_0.hit, tb_table_dst_cs_3.action_run, tb_table_dst_cs_3.hit;
{
  call mainProcedure();
}

// ===== END HARNESS =====
