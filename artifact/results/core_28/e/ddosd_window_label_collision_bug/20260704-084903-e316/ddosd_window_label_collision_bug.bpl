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
type s1_ethernet_t;
type s1_ddosd_t;
type s1_ipv4_t;

// s1_Struct s1_headers
var s1_hdr:s1_Ref;

// s1_Header s1_ethernet_t
var s1_hdr.ethernet:s1_Ref;
var s1_hdr.ethernet.valid:bool;
var s1_hdr.ethernet.dst_addr:bv48;
var s1_hdr.ethernet.src_addr:bv48;
var s1_hdr.ethernet.ether_type:bv16;

// s1_Header s1_ddosd_t
var s1_hdr.ddosd:s1_Ref;
var s1_hdr.ddosd.valid:bool;
var s1_hdr.ddosd.pkt_num:bv32;
var s1_hdr.ddosd.src_entropy:bv32;
var s1_hdr.ddosd.src_ewma:bv32;
var s1_hdr.ddosd.src_ewmmd:bv32;
var s1_hdr.ddosd.dst_entropy:bv32;
var s1_hdr.ddosd.dst_ewma:bv32;
var s1_hdr.ddosd.dst_ewmmd:bv32;
var s1_hdr.ddosd.alarm:bv8;
var s1_hdr.ddosd.ether_type:bv16;

// s1_Header s1_ipv4_t
var s1_hdr.ipv4:s1_Ref;
var s1_hdr.ipv4.valid:bool;
var s1_hdr.ipv4.version:bv4;
var s1_hdr.ipv4.ihl:bv4;
var s1_hdr.ipv4.dscp:bv6;
var s1_hdr.ipv4.ecn:bv2;
var s1_hdr.ipv4.total_len:bv16;
var s1_hdr.ipv4.identification:bv16;
var s1_hdr.ipv4.flags:bv3;
var s1_hdr.ipv4.frag_offset:bv13;
var s1_hdr.ipv4.ttl:bv8;
var s1_hdr.ipv4.protocol:bv8;
var s1_hdr.ipv4.hdr_checksum:bv16;
var s1_hdr.ipv4.src_addr:bv32;
var s1_hdr.ipv4.dst_addr:bv32;

// s1_Struct s1_metadata
type s1_metadata;
var s1_meta.ip_count:bv32;
var s1_meta.entropy_term:bv32;
var s1_meta.pkt_num:bv32;
var s1_meta.src_entropy:bv32;
var s1_meta.src_ewma:bv32;
var s1_meta.src_ewmmd:bv32;
var s1_meta.dst_entropy:bv32;
var s1_meta.dst_ewma:bv32;
var s1_meta.dst_ewmmd:bv32;
var s1_meta.alarm:bv8;
var s1_meta:s1_metadata;
var s1_standard_metadata:s1_standard_metadata_t;
var s1_idx_0:bv32;
var s1_current_ow_0:bv32;
var s1_src_h1_0:bv32;
var s1_src_h2_0:bv32;
var s1_src_h3_0:bv32;
var s1_src_h4_0:bv32;
var s1_src_g1_0:bv32;
var s1_src_g2_0:bv32;
var s1_src_g3_0:bv32;
var s1_src_g4_0:bv32;
var s1_src_cs1_ow_aux_0:bv8;
var s1_src_c1_0:bv32;
var s1_src_cs2_ow_aux_0:bv8;
var s1_src_c2_0:bv32;
var s1_src_cs3_ow_aux_0:bv8;
var s1_src_c3_0:bv32;
var s1_src_cs4_ow_aux_0:bv8;
var s1_src_c4_0:bv32;
var s1_src_S_aux_0:bv32;
var s1_dst_h1_0:bv32;
var s1_dst_h2_0:bv32;
var s1_dst_h3_0:bv32;
var s1_dst_h4_0:bv32;
var s1_dst_g1_0:bv32;
var s1_dst_g2_0:bv32;
var s1_dst_g3_0:bv32;
var s1_dst_g4_0:bv32;
var s1_dst_cs1_ow_aux_0:bv8;
var s1_dst_c1_0:bv32;
var s1_dst_cs2_ow_aux_0:bv8;
var s1_dst_c2_0:bv32;
var s1_dst_cs3_ow_aux_0:bv8;
var s1_dst_c3_0:bv32;
var s1_dst_cs4_ow_aux_0:bv8;
var s1_dst_c4_0:bv32;
var s1_dst_S_aux_0:bv32;
var s1_m_0:bv32;
var s1_log2_m_aux_0:bv5;
var s1_training_len_aux_0:bv32;
var s1_k_aux_0:bv8;
var s1_src_thresh_0:bv32;
var s1_dst_thresh_0:bv32;
var s1_alpha_aux_0:bv8;
var s1_ipv4_addr_0:bv32;
var s1_h1_0:bv32;
var s1_h2_0:bv32;
var s1_h3_0:bv32;
var s1_h4_0:bv32;
var s1_ipv4_addr_1:bv32;
var s1_h1_2:bv32;
var s1_h2_2:bv32;
var s1_h3_2:bv32;
var s1_h4_2:bv32;
var s1_g1_0:bv32;
var s1_g2_0:bv32;
var s1_g3_0:bv32;
var s1_g4_0:bv32;
var s1_g1_2:bv32;
var s1_g2_2:bv32;
var s1_g3_2:bv32;
var s1_g4_2:bv32;
var s1_x1_0:bv32;
var s1_x2_0:bv32;
var s1_x3_0:bv32;
var s1_x4_0:bv32;
var s1_y_0:bv32;
var s1_x1_2:bv32;
var s1_x2_2:bv32;
var s1_x3_2:bv32;
var s1_x4_2:bv32;
var s1_y_2:bv32;

// s1_Register s1_ingress_log2_m
var s1_ingress_log2_m:[bv32]bv5;
var s1_ingress_log2_m__last_index:bv32;
var s1_ingress_log2_m__last_value:bv5;
var s1_ingress_log2_m__last_old_value:bv5;
var s1_ingress_log2_m__wrote_any:bool;
var s1_ingress_log2_m__wrote_index0:bool;
var s1_ingress_log2_m__last0_old_value:bv5;
var s1_ingress_log2_m__last0_value:bv5;
var s1_ingress_log2_m__next_write_site:int;
var s1_ingress_log2_m__last_write_site:int;
const s1_ingress_log2_m.size:bv32;
axiom s1_ingress_log2_m.size == 1bv32;

// s1_Register s1_ingress_training_len
var s1_ingress_training_len:[bv32]bv32;
var s1_ingress_training_len__last_index:bv32;
var s1_ingress_training_len__last_value:bv32;
var s1_ingress_training_len__last_old_value:bv32;
var s1_ingress_training_len__wrote_any:bool;
var s1_ingress_training_len__wrote_index0:bool;
var s1_ingress_training_len__last0_old_value:bv32;
var s1_ingress_training_len__last0_value:bv32;
var s1_ingress_training_len__next_write_site:int;
var s1_ingress_training_len__last_write_site:int;
const s1_ingress_training_len.size:bv32;
axiom s1_ingress_training_len.size == 1bv32;

// s1_Register s1_ingress_ow_counter
var s1_ingress_ow_counter:[bv32]bv32;
var s1_ingress_ow_counter__last_index:bv32;
var s1_ingress_ow_counter__last_value:bv32;
var s1_ingress_ow_counter__last_old_value:bv32;
var s1_ingress_ow_counter__wrote_any:bool;
var s1_ingress_ow_counter__wrote_index0:bool;
var s1_ingress_ow_counter__last0_old_value:bv32;
var s1_ingress_ow_counter__last0_value:bv32;
var s1_ingress_ow_counter__next_write_site:int;
var s1_ingress_ow_counter__last_write_site:int;
const s1_ingress_ow_counter.size:bv32;
axiom s1_ingress_ow_counter.size == 1bv32;

// s1_Register s1_ingress_pkt_counter
var s1_ingress_pkt_counter:[bv32]bv32;
var s1_ingress_pkt_counter__last_index:bv32;
var s1_ingress_pkt_counter__last_value:bv32;
var s1_ingress_pkt_counter__last_old_value:bv32;
var s1_ingress_pkt_counter__wrote_any:bool;
var s1_ingress_pkt_counter__wrote_index0:bool;
var s1_ingress_pkt_counter__last0_old_value:bv32;
var s1_ingress_pkt_counter__last0_value:bv32;
var s1_ingress_pkt_counter__next_write_site:int;
var s1_ingress_pkt_counter__last_write_site:int;
const s1_ingress_pkt_counter.size:bv32;
axiom s1_ingress_pkt_counter.size == 1bv32;

// s1_Register s1_ingress_src_cs1
var s1_ingress_src_cs1:[bv32]bv32;
var s1_ingress_src_cs1__last_index:bv32;
var s1_ingress_src_cs1__last_value:bv32;
var s1_ingress_src_cs1__last_old_value:bv32;
var s1_ingress_src_cs1__wrote_any:bool;
var s1_ingress_src_cs1__wrote_index0:bool;
var s1_ingress_src_cs1__last0_old_value:bv32;
var s1_ingress_src_cs1__last0_value:bv32;
var s1_ingress_src_cs1__next_write_site:int;
var s1_ingress_src_cs1__last_write_site:int;
const s1_ingress_src_cs1.size:bv32;
axiom s1_ingress_src_cs1.size == 976bv32;

// s1_Register s1_ingress_src_cs2
var s1_ingress_src_cs2:[bv32]bv32;
var s1_ingress_src_cs2__last_index:bv32;
var s1_ingress_src_cs2__last_value:bv32;
var s1_ingress_src_cs2__last_old_value:bv32;
var s1_ingress_src_cs2__wrote_any:bool;
var s1_ingress_src_cs2__wrote_index0:bool;
var s1_ingress_src_cs2__last0_old_value:bv32;
var s1_ingress_src_cs2__last0_value:bv32;
var s1_ingress_src_cs2__next_write_site:int;
var s1_ingress_src_cs2__last_write_site:int;
const s1_ingress_src_cs2.size:bv32;
axiom s1_ingress_src_cs2.size == 976bv32;

// s1_Register s1_ingress_src_cs3
var s1_ingress_src_cs3:[bv32]bv32;
var s1_ingress_src_cs3__last_index:bv32;
var s1_ingress_src_cs3__last_value:bv32;
var s1_ingress_src_cs3__last_old_value:bv32;
var s1_ingress_src_cs3__wrote_any:bool;
var s1_ingress_src_cs3__wrote_index0:bool;
var s1_ingress_src_cs3__last0_old_value:bv32;
var s1_ingress_src_cs3__last0_value:bv32;
var s1_ingress_src_cs3__next_write_site:int;
var s1_ingress_src_cs3__last_write_site:int;
const s1_ingress_src_cs3.size:bv32;
axiom s1_ingress_src_cs3.size == 976bv32;

// s1_Register s1_ingress_src_cs4
var s1_ingress_src_cs4:[bv32]bv32;
var s1_ingress_src_cs4__last_index:bv32;
var s1_ingress_src_cs4__last_value:bv32;
var s1_ingress_src_cs4__last_old_value:bv32;
var s1_ingress_src_cs4__wrote_any:bool;
var s1_ingress_src_cs4__wrote_index0:bool;
var s1_ingress_src_cs4__last0_old_value:bv32;
var s1_ingress_src_cs4__last0_value:bv32;
var s1_ingress_src_cs4__next_write_site:int;
var s1_ingress_src_cs4__last_write_site:int;
const s1_ingress_src_cs4.size:bv32;
axiom s1_ingress_src_cs4.size == 976bv32;

// s1_Register s1_ingress_dst_cs1
var s1_ingress_dst_cs1:[bv32]bv32;
var s1_ingress_dst_cs1__last_index:bv32;
var s1_ingress_dst_cs1__last_value:bv32;
var s1_ingress_dst_cs1__last_old_value:bv32;
var s1_ingress_dst_cs1__wrote_any:bool;
var s1_ingress_dst_cs1__wrote_index0:bool;
var s1_ingress_dst_cs1__last0_old_value:bv32;
var s1_ingress_dst_cs1__last0_value:bv32;
var s1_ingress_dst_cs1__next_write_site:int;
var s1_ingress_dst_cs1__last_write_site:int;
const s1_ingress_dst_cs1.size:bv32;
axiom s1_ingress_dst_cs1.size == 976bv32;

// s1_Register s1_ingress_dst_cs2
var s1_ingress_dst_cs2:[bv32]bv32;
var s1_ingress_dst_cs2__last_index:bv32;
var s1_ingress_dst_cs2__last_value:bv32;
var s1_ingress_dst_cs2__last_old_value:bv32;
var s1_ingress_dst_cs2__wrote_any:bool;
var s1_ingress_dst_cs2__wrote_index0:bool;
var s1_ingress_dst_cs2__last0_old_value:bv32;
var s1_ingress_dst_cs2__last0_value:bv32;
var s1_ingress_dst_cs2__next_write_site:int;
var s1_ingress_dst_cs2__last_write_site:int;
const s1_ingress_dst_cs2.size:bv32;
axiom s1_ingress_dst_cs2.size == 976bv32;

// s1_Register s1_ingress_dst_cs3
var s1_ingress_dst_cs3:[bv32]bv32;
var s1_ingress_dst_cs3__last_index:bv32;
var s1_ingress_dst_cs3__last_value:bv32;
var s1_ingress_dst_cs3__last_old_value:bv32;
var s1_ingress_dst_cs3__wrote_any:bool;
var s1_ingress_dst_cs3__wrote_index0:bool;
var s1_ingress_dst_cs3__last0_old_value:bv32;
var s1_ingress_dst_cs3__last0_value:bv32;
var s1_ingress_dst_cs3__next_write_site:int;
var s1_ingress_dst_cs3__last_write_site:int;
const s1_ingress_dst_cs3.size:bv32;
axiom s1_ingress_dst_cs3.size == 976bv32;

// s1_Register s1_ingress_dst_cs4
var s1_ingress_dst_cs4:[bv32]bv32;
var s1_ingress_dst_cs4__last_index:bv32;
var s1_ingress_dst_cs4__last_value:bv32;
var s1_ingress_dst_cs4__last_old_value:bv32;
var s1_ingress_dst_cs4__wrote_any:bool;
var s1_ingress_dst_cs4__wrote_index0:bool;
var s1_ingress_dst_cs4__last0_old_value:bv32;
var s1_ingress_dst_cs4__last0_value:bv32;
var s1_ingress_dst_cs4__next_write_site:int;
var s1_ingress_dst_cs4__last_write_site:int;
const s1_ingress_dst_cs4.size:bv32;
axiom s1_ingress_dst_cs4.size == 976bv32;

// s1_Register s1_ingress_src_cs1_ow
var s1_ingress_src_cs1_ow:[bv32]bv8;
var s1_ingress_src_cs1_ow__last_index:bv32;
var s1_ingress_src_cs1_ow__last_value:bv8;
var s1_ingress_src_cs1_ow__last_old_value:bv8;
var s1_ingress_src_cs1_ow__wrote_any:bool;
var s1_ingress_src_cs1_ow__wrote_index0:bool;
var s1_ingress_src_cs1_ow__last0_old_value:bv8;
var s1_ingress_src_cs1_ow__last0_value:bv8;
var s1_ingress_src_cs1_ow__next_write_site:int;
var s1_ingress_src_cs1_ow__last_write_site:int;
const s1_ingress_src_cs1_ow.size:bv32;
axiom s1_ingress_src_cs1_ow.size == 976bv32;

// s1_Register s1_ingress_src_cs2_ow
var s1_ingress_src_cs2_ow:[bv32]bv8;
var s1_ingress_src_cs2_ow__last_index:bv32;
var s1_ingress_src_cs2_ow__last_value:bv8;
var s1_ingress_src_cs2_ow__last_old_value:bv8;
var s1_ingress_src_cs2_ow__wrote_any:bool;
var s1_ingress_src_cs2_ow__wrote_index0:bool;
var s1_ingress_src_cs2_ow__last0_old_value:bv8;
var s1_ingress_src_cs2_ow__last0_value:bv8;
var s1_ingress_src_cs2_ow__next_write_site:int;
var s1_ingress_src_cs2_ow__last_write_site:int;
const s1_ingress_src_cs2_ow.size:bv32;
axiom s1_ingress_src_cs2_ow.size == 976bv32;

// s1_Register s1_ingress_src_cs3_ow
var s1_ingress_src_cs3_ow:[bv32]bv8;
var s1_ingress_src_cs3_ow__last_index:bv32;
var s1_ingress_src_cs3_ow__last_value:bv8;
var s1_ingress_src_cs3_ow__last_old_value:bv8;
var s1_ingress_src_cs3_ow__wrote_any:bool;
var s1_ingress_src_cs3_ow__wrote_index0:bool;
var s1_ingress_src_cs3_ow__last0_old_value:bv8;
var s1_ingress_src_cs3_ow__last0_value:bv8;
var s1_ingress_src_cs3_ow__next_write_site:int;
var s1_ingress_src_cs3_ow__last_write_site:int;
const s1_ingress_src_cs3_ow.size:bv32;
axiom s1_ingress_src_cs3_ow.size == 976bv32;

// s1_Register s1_ingress_src_cs4_ow
var s1_ingress_src_cs4_ow:[bv32]bv8;
var s1_ingress_src_cs4_ow__last_index:bv32;
var s1_ingress_src_cs4_ow__last_value:bv8;
var s1_ingress_src_cs4_ow__last_old_value:bv8;
var s1_ingress_src_cs4_ow__wrote_any:bool;
var s1_ingress_src_cs4_ow__wrote_index0:bool;
var s1_ingress_src_cs4_ow__last0_old_value:bv8;
var s1_ingress_src_cs4_ow__last0_value:bv8;
var s1_ingress_src_cs4_ow__next_write_site:int;
var s1_ingress_src_cs4_ow__last_write_site:int;
const s1_ingress_src_cs4_ow.size:bv32;
axiom s1_ingress_src_cs4_ow.size == 976bv32;

// s1_Register s1_ingress_dst_cs1_ow
var s1_ingress_dst_cs1_ow:[bv32]bv8;
var s1_ingress_dst_cs1_ow__last_index:bv32;
var s1_ingress_dst_cs1_ow__last_value:bv8;
var s1_ingress_dst_cs1_ow__last_old_value:bv8;
var s1_ingress_dst_cs1_ow__wrote_any:bool;
var s1_ingress_dst_cs1_ow__wrote_index0:bool;
var s1_ingress_dst_cs1_ow__last0_old_value:bv8;
var s1_ingress_dst_cs1_ow__last0_value:bv8;
var s1_ingress_dst_cs1_ow__next_write_site:int;
var s1_ingress_dst_cs1_ow__last_write_site:int;
const s1_ingress_dst_cs1_ow.size:bv32;
axiom s1_ingress_dst_cs1_ow.size == 976bv32;

// s1_Register s1_ingress_dst_cs2_ow
var s1_ingress_dst_cs2_ow:[bv32]bv8;
var s1_ingress_dst_cs2_ow__last_index:bv32;
var s1_ingress_dst_cs2_ow__last_value:bv8;
var s1_ingress_dst_cs2_ow__last_old_value:bv8;
var s1_ingress_dst_cs2_ow__wrote_any:bool;
var s1_ingress_dst_cs2_ow__wrote_index0:bool;
var s1_ingress_dst_cs2_ow__last0_old_value:bv8;
var s1_ingress_dst_cs2_ow__last0_value:bv8;
var s1_ingress_dst_cs2_ow__next_write_site:int;
var s1_ingress_dst_cs2_ow__last_write_site:int;
const s1_ingress_dst_cs2_ow.size:bv32;
axiom s1_ingress_dst_cs2_ow.size == 976bv32;

// s1_Register s1_ingress_dst_cs3_ow
var s1_ingress_dst_cs3_ow:[bv32]bv8;
var s1_ingress_dst_cs3_ow__last_index:bv32;
var s1_ingress_dst_cs3_ow__last_value:bv8;
var s1_ingress_dst_cs3_ow__last_old_value:bv8;
var s1_ingress_dst_cs3_ow__wrote_any:bool;
var s1_ingress_dst_cs3_ow__wrote_index0:bool;
var s1_ingress_dst_cs3_ow__last0_old_value:bv8;
var s1_ingress_dst_cs3_ow__last0_value:bv8;
var s1_ingress_dst_cs3_ow__next_write_site:int;
var s1_ingress_dst_cs3_ow__last_write_site:int;
const s1_ingress_dst_cs3_ow.size:bv32;
axiom s1_ingress_dst_cs3_ow.size == 976bv32;

// s1_Register s1_ingress_dst_cs4_ow
var s1_ingress_dst_cs4_ow:[bv32]bv8;
var s1_ingress_dst_cs4_ow__last_index:bv32;
var s1_ingress_dst_cs4_ow__last_value:bv8;
var s1_ingress_dst_cs4_ow__last_old_value:bv8;
var s1_ingress_dst_cs4_ow__wrote_any:bool;
var s1_ingress_dst_cs4_ow__wrote_index0:bool;
var s1_ingress_dst_cs4_ow__last0_old_value:bv8;
var s1_ingress_dst_cs4_ow__last0_value:bv8;
var s1_ingress_dst_cs4_ow__next_write_site:int;
var s1_ingress_dst_cs4_ow__last_write_site:int;
const s1_ingress_dst_cs4_ow.size:bv32;
axiom s1_ingress_dst_cs4_ow.size == 976bv32;

// s1_Register s1_ingress_src_S
var s1_ingress_src_S:[bv32]bv32;
var s1_ingress_src_S__last_index:bv32;
var s1_ingress_src_S__last_value:bv32;
var s1_ingress_src_S__last_old_value:bv32;
var s1_ingress_src_S__wrote_any:bool;
var s1_ingress_src_S__wrote_index0:bool;
var s1_ingress_src_S__last0_old_value:bv32;
var s1_ingress_src_S__last0_value:bv32;
var s1_ingress_src_S__next_write_site:int;
var s1_ingress_src_S__last_write_site:int;
const s1_ingress_src_S.size:bv32;
axiom s1_ingress_src_S.size == 1bv32;

// s1_Register s1_ingress_dst_S
var s1_ingress_dst_S:[bv32]bv32;
var s1_ingress_dst_S__last_index:bv32;
var s1_ingress_dst_S__last_value:bv32;
var s1_ingress_dst_S__last_old_value:bv32;
var s1_ingress_dst_S__wrote_any:bool;
var s1_ingress_dst_S__wrote_index0:bool;
var s1_ingress_dst_S__last0_old_value:bv32;
var s1_ingress_dst_S__last0_value:bv32;
var s1_ingress_dst_S__next_write_site:int;
var s1_ingress_dst_S__last_write_site:int;
const s1_ingress_dst_S.size:bv32;
axiom s1_ingress_dst_S.size == 1bv32;

// s1_Register s1_ingress_src_ewma
var s1_ingress_src_ewma:[bv32]bv32;
var s1_ingress_src_ewma__last_index:bv32;
var s1_ingress_src_ewma__last_value:bv32;
var s1_ingress_src_ewma__last_old_value:bv32;
var s1_ingress_src_ewma__wrote_any:bool;
var s1_ingress_src_ewma__wrote_index0:bool;
var s1_ingress_src_ewma__last0_old_value:bv32;
var s1_ingress_src_ewma__last0_value:bv32;
var s1_ingress_src_ewma__next_write_site:int;
var s1_ingress_src_ewma__last_write_site:int;
const s1_ingress_src_ewma.size:bv32;
axiom s1_ingress_src_ewma.size == 1bv32;

// s1_Register s1_ingress_src_ewmmd
var s1_ingress_src_ewmmd:[bv32]bv32;
var s1_ingress_src_ewmmd__last_index:bv32;
var s1_ingress_src_ewmmd__last_value:bv32;
var s1_ingress_src_ewmmd__last_old_value:bv32;
var s1_ingress_src_ewmmd__wrote_any:bool;
var s1_ingress_src_ewmmd__wrote_index0:bool;
var s1_ingress_src_ewmmd__last0_old_value:bv32;
var s1_ingress_src_ewmmd__last0_value:bv32;
var s1_ingress_src_ewmmd__next_write_site:int;
var s1_ingress_src_ewmmd__last_write_site:int;
const s1_ingress_src_ewmmd.size:bv32;
axiom s1_ingress_src_ewmmd.size == 1bv32;

// s1_Register s1_ingress_dst_ewma
var s1_ingress_dst_ewma:[bv32]bv32;
var s1_ingress_dst_ewma__last_index:bv32;
var s1_ingress_dst_ewma__last_value:bv32;
var s1_ingress_dst_ewma__last_old_value:bv32;
var s1_ingress_dst_ewma__wrote_any:bool;
var s1_ingress_dst_ewma__wrote_index0:bool;
var s1_ingress_dst_ewma__last0_old_value:bv32;
var s1_ingress_dst_ewma__last0_value:bv32;
var s1_ingress_dst_ewma__next_write_site:int;
var s1_ingress_dst_ewma__last_write_site:int;
const s1_ingress_dst_ewma.size:bv32;
axiom s1_ingress_dst_ewma.size == 1bv32;

// s1_Register s1_ingress_dst_ewmmd
var s1_ingress_dst_ewmmd:[bv32]bv32;
var s1_ingress_dst_ewmmd__last_index:bv32;
var s1_ingress_dst_ewmmd__last_value:bv32;
var s1_ingress_dst_ewmmd__last_old_value:bv32;
var s1_ingress_dst_ewmmd__wrote_any:bool;
var s1_ingress_dst_ewmmd__wrote_index0:bool;
var s1_ingress_dst_ewmmd__last0_old_value:bv32;
var s1_ingress_dst_ewmmd__last0_value:bv32;
var s1_ingress_dst_ewmmd__next_write_site:int;
var s1_ingress_dst_ewmmd__last_write_site:int;
const s1_ingress_dst_ewmmd.size:bv32;
axiom s1_ingress_dst_ewmmd.size == 1bv32;

// s1_Register s1_ingress_alpha
var s1_ingress_alpha:[bv32]bv8;
var s1_ingress_alpha__last_index:bv32;
var s1_ingress_alpha__last_value:bv8;
var s1_ingress_alpha__last_old_value:bv8;
var s1_ingress_alpha__wrote_any:bool;
var s1_ingress_alpha__wrote_index0:bool;
var s1_ingress_alpha__last0_old_value:bv8;
var s1_ingress_alpha__last0_value:bv8;
var s1_ingress_alpha__next_write_site:int;
var s1_ingress_alpha__last_write_site:int;
const s1_ingress_alpha.size:bv32;
axiom s1_ingress_alpha.size == 1bv32;

// s1_Register s1_ingress_k
var s1_ingress_k:[bv32]bv8;
var s1_ingress_k__last_index:bv32;
var s1_ingress_k__last_value:bv8;
var s1_ingress_k__last_old_value:bv8;
var s1_ingress_k__wrote_any:bool;
var s1_ingress_k__wrote_index0:bool;
var s1_ingress_k__last0_old_value:bv8;
var s1_ingress_k__last0_value:bv8;
var s1_ingress_k__next_write_site:int;
var s1_ingress_k__last_write_site:int;
const s1_ingress_k.size:bv32;
axiom s1_ingress_k.size == 1bv32;

// s1_Table s1_ingress_ipv4_fib s1_Actionlist s1_Declaration
type s1_ingress_ipv4_fib.action;
var s1_ingress_ipv4_fib.ingress_forward.egress_port_1:bv9;

function {:builtin "bvand"} band.bv32(s1_left:bv32, s1_right:bv32) returns(bv32);
const unique s1_ingress_ipv4_fib.action.ingress_forward : s1_ingress_ipv4_fib.action;
const unique s1_ingress_ipv4_fib.action.ingress_drop : s1_ingress_ipv4_fib.action;
var s1_ingress_ipv4_fib.action_run : s1_ingress_ipv4_fib.action;
var s1_ingress_ipv4_fib.hit : bool;

// s1_Table s1_ingress_src_entropy_term s1_Actionlist s1_Declaration
type s1_ingress_src_entropy_term.action;
var s1_ingress_src_entropy_term.ingress_get_entropy_term.entropy_term_1:bv32;
const unique s1_ingress_src_entropy_term.action.ingress_get_entropy_term : s1_ingress_src_entropy_term.action;
var s1_ingress_src_entropy_term.action_run : s1_ingress_src_entropy_term.action;
var s1_ingress_src_entropy_term.hit : bool;

// s1_Table s1_ingress_dst_entropy_term s1_Actionlist s1_Declaration
type s1_ingress_dst_entropy_term.action;
var s1_ingress_dst_entropy_term.get_entropy_term_1.entropy_term_2:bv32;
const unique s1_ingress_dst_entropy_term.action.get_entropy_term_1 : s1_ingress_dst_entropy_term.action;
var s1_ingress_dst_entropy_term.action_run : s1_ingress_dst_entropy_term.action;
var s1_ingress_dst_entropy_term.hit : bool;

function {:builtin "bvadd"} add.bv32(s1_left:bv32, s1_right:bv32) returns(bv32);

function {:builtin "bvshl"} shl.bv32(s1_left:bv32, s1_right:bv32) returns(bv32);

function {:builtin "bvule"} bule.bv32(s1_left:bv32, s1_right:bv32) returns(bool);

function {:builtin "bvuge"} buge.bv32(s1_left:bv32, s1_right:bv32) returns(bool);

function {:builtin "bvlshr"} shr.bv32(s1_left:bv32, s1_right:bv32) returns(bv32);

function {:builtin "bvmul"} mul.bv32(s1_left:bv32, s1_right:bv32) returns(bv32);

function {:builtin "bvugt"} bugt.bv32(s1_left:bv32, s1_right:bv32) returns(bool);

function {:builtin "bvsub"} sub.bv32(s1_left:bv32, s1_right:bv32) returns(bv32);

function {:builtin "bvult"} bult.bv32(s1_left:bv32, s1_right:bv32) returns(bool);

function {:builtin "bvsub"} sub.bv17(s1_left:bv17, s1_right:bv17) returns(bv17);

function {:builtin "bvsub"} sub.bv33(s1_left:bv33, s1_right:bv33) returns(bv33);

// s1_Parser s1_ParserImpl
procedure {:inline 1} s1_ParserImpl()
	modifies s1_drop, s1_isValid;
{
    goto s1_State$ParserImpl$start;

        s1_State$ParserImpl$start:
    call s1_packet_in.extract(s1_hdr.ethernet);
    goto s1_State$ParserImpl$start$parse_ddosd_3, s1_State$ParserImpl$start$parse_ipv4_2, s1_State$ParserImpl$start$DEFAULT;
    
s1_State$ParserImpl$start$parse_ddosd_3:
    assume (s1_hdr.ethernet.ether_type == 26117bv16);
    goto s1_State$ParserImpl$parse_ddosd;
    
s1_State$ParserImpl$start$parse_ipv4_2:
    assume (s1_hdr.ethernet.ether_type == 2048bv16);
    goto s1_State$ParserImpl$parse_ipv4;

    s1_State$ParserImpl$start$DEFAULT:
    assume(!(s1_hdr.ethernet.ether_type == 26117bv16)&&!(s1_hdr.ethernet.ether_type == 2048bv16));
    goto s1_State$accept;

        s1_State$ParserImpl$parse_ddosd:
    call s1_packet_in.extract(s1_hdr.ddosd);
    goto s1_State$ParserImpl$parse_ddosd$parse_ipv4_2, s1_State$ParserImpl$parse_ddosd$DEFAULT;
    
s1_State$ParserImpl$parse_ddosd$parse_ipv4_2:
    assume (s1_hdr.ddosd.ether_type == 2048bv16);
    goto s1_State$ParserImpl$parse_ipv4;

    s1_State$ParserImpl$parse_ddosd$DEFAULT:
    assume(!(s1_hdr.ddosd.ether_type == 2048bv16));
    goto s1_State$accept;

        s1_State$ParserImpl$parse_ipv4:
    call s1_packet_in.extract(s1_hdr.ipv4);
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

// s1_Control s1_computeChecksum
procedure {:inline 1} s1_computeChecksum()
	modifies s1_hdr.ipv4.hdr_checksum, s1_p4b_checksum_updated;
{
    if (true) {
        s1_p4b_checksum_updated := true;
        havoc s1_hdr.ipv4.hdr_checksum;
    }
}

// s1_Action s1_cs_ghash_1
procedure {:inline 1} s1_cs_ghash_1()
	modifies s1_dst_g1_0, s1_dst_g2_0, s1_dst_g3_0, s1_dst_g4_0, s1_g1_2, s1_g2_2, s1_g3_2, s1_g4_2;
{
    s1_g1_2 := 1bv32;
    s1_g2_2 := 1bv32;
    s1_g3_2 := 1bv32;
    s1_g4_2 := 1bv32;
    s1_g1_2 := add.bv32(shl.bv32(s1_g1_2, 1bv32), 4294967295bv32);
    s1_g2_2 := add.bv32(shl.bv32(s1_g2_2, 1bv32), 4294967295bv32);
    s1_g3_2 := add.bv32(shl.bv32(s1_g3_2, 1bv32), 4294967295bv32);
    s1_g4_2 := add.bv32(shl.bv32(s1_g4_2, 1bv32), 4294967295bv32);
    s1_dst_g1_0 := s1_g1_2;
    s1_dst_g2_0 := s1_g2_2;
    s1_dst_g3_0 := s1_g3_2;
    s1_dst_g4_0 := s1_g4_2;
}

// s1_Action s1_cs_hash_1
procedure {:inline 1} s1_cs_hash_1()
	modifies s1_dst_h1_0, s1_dst_h2_0, s1_dst_h3_0, s1_dst_h4_0, s1_h1_2, s1_h2_2, s1_h3_2, s1_h4_2, s1_idx_0, s1_ipv4_addr_1;
{
    s1_ipv4_addr_1 := s1_hdr.ipv4.dst_addr;
    s1_idx_0 := band.bv32(s1_ipv4_addr_1, 1bv32);
    s1_h1_2 := s1_idx_0;
    s1_h2_2 := s1_idx_0;
    s1_h3_2 := s1_idx_0;
    s1_h4_2 := s1_idx_0;
    s1_dst_h1_0 := s1_h1_2;
    s1_dst_h2_0 := s1_h2_2;
    s1_dst_h3_0 := s1_h3_2;
    s1_dst_h4_0 := s1_h4_2;
}

// s1_Control s1_egress
procedure {:inline 1} s1_egress()
	modifies s1_hdr.ddosd.alarm, s1_hdr.ddosd.dst_entropy, s1_hdr.ddosd.dst_ewma, s1_hdr.ddosd.dst_ewmmd, s1_hdr.ddosd.ether_type, s1_hdr.ddosd.pkt_num, s1_hdr.ddosd.src_entropy, s1_hdr.ddosd.src_ewma, s1_hdr.ddosd.src_ewmmd, s1_hdr.ethernet.ether_type, s1_isValid;
{
    if((s1_standard_metadata.instance_type == 1bv32)){
        call s1_setValid(s1_hdr.ddosd);
        s1_hdr.ddosd.pkt_num := s1_meta.pkt_num;
        s1_hdr.ddosd.src_entropy := s1_meta.src_entropy;
        s1_hdr.ddosd.src_ewma := s1_meta.src_ewma;
        s1_hdr.ddosd.src_ewmmd := s1_meta.src_ewmmd;
        s1_hdr.ddosd.dst_entropy := s1_meta.dst_entropy;
        s1_hdr.ddosd.dst_ewma := s1_meta.dst_ewma;
        s1_hdr.ddosd.dst_ewmmd := s1_meta.dst_ewmmd;
        s1_hdr.ddosd.alarm := s1_meta.alarm;
        s1_hdr.ddosd.ether_type := s1_hdr.ethernet.ether_type;
        s1_hdr.ethernet.ether_type := 26117bv16;
    }
}

// s1_Action s1_get_entropy_term_1
procedure {:inline 1} s1_get_entropy_term_1(s1_entropy_term_2:bv32)
	modifies s1_meta.entropy_term;
{
    s1_meta.entropy_term := s1_entropy_term_2;
}

// s1_Control s1_ingress
procedure {:inline 1} s1_ingress()
	modifies s1_alpha_aux_0, s1_current_ow_0, s1_drop, s1_dst_S_aux_0, s1_dst_c1_0, s1_dst_c2_0, s1_dst_c3_0, s1_dst_c4_0, s1_dst_cs1_ow_aux_0, s1_dst_cs2_ow_aux_0, s1_dst_cs3_ow_aux_0, s1_dst_cs4_ow_aux_0, s1_dst_g1_0, s1_dst_g2_0, s1_dst_g3_0, s1_dst_g4_0, s1_dst_h1_0, s1_dst_h2_0, s1_dst_h3_0, s1_dst_h4_0, s1_dst_thresh_0, s1_forward, s1_g1_0, s1_g1_2, s1_g2_0, s1_g2_2, s1_g3_0, s1_g3_2, s1_g4_0, s1_g4_2, s1_h1_0, s1_h1_2, s1_h2_0, s1_h2_2, s1_h3_0, s1_h3_2, s1_h4_0, s1_h4_2, s1_hdr.ipv4.dst_addr, s1_idx_0, s1_ingress_dst_S, s1_ingress_dst_S__last0_old_value, s1_ingress_dst_S__last0_value, s1_ingress_dst_S__last_index, s1_ingress_dst_S__last_old_value, s1_ingress_dst_S__last_value, s1_ingress_dst_S__last_write_site, s1_ingress_dst_S__next_write_site, s1_ingress_dst_S__wrote_any, s1_ingress_dst_S__wrote_index0, s1_ingress_dst_cs1, s1_ingress_dst_cs1__last0_old_value, s1_ingress_dst_cs1__last0_value, s1_ingress_dst_cs1__last_index, s1_ingress_dst_cs1__last_old_value, s1_ingress_dst_cs1__last_value, s1_ingress_dst_cs1__last_write_site, s1_ingress_dst_cs1__next_write_site, s1_ingress_dst_cs1__wrote_any, s1_ingress_dst_cs1__wrote_index0, s1_ingress_dst_cs1_ow, s1_ingress_dst_cs1_ow__last0_old_value, s1_ingress_dst_cs1_ow__last0_value, s1_ingress_dst_cs1_ow__last_index, s1_ingress_dst_cs1_ow__last_old_value, s1_ingress_dst_cs1_ow__last_value, s1_ingress_dst_cs1_ow__last_write_site, s1_ingress_dst_cs1_ow__next_write_site, s1_ingress_dst_cs1_ow__wrote_any, s1_ingress_dst_cs1_ow__wrote_index0, s1_ingress_dst_cs2, s1_ingress_dst_cs2__last0_old_value, s1_ingress_dst_cs2__last0_value, s1_ingress_dst_cs2__last_index, s1_ingress_dst_cs2__last_old_value, s1_ingress_dst_cs2__last_value, s1_ingress_dst_cs2__last_write_site, s1_ingress_dst_cs2__next_write_site, s1_ingress_dst_cs2__wrote_any, s1_ingress_dst_cs2__wrote_index0, s1_ingress_dst_cs2_ow, s1_ingress_dst_cs2_ow__last0_old_value, s1_ingress_dst_cs2_ow__last0_value, s1_ingress_dst_cs2_ow__last_index, s1_ingress_dst_cs2_ow__last_old_value, s1_ingress_dst_cs2_ow__last_value, s1_ingress_dst_cs2_ow__last_write_site, s1_ingress_dst_cs2_ow__next_write_site, s1_ingress_dst_cs2_ow__wrote_any, s1_ingress_dst_cs2_ow__wrote_index0, s1_ingress_dst_cs3, s1_ingress_dst_cs3__last0_old_value, s1_ingress_dst_cs3__last0_value, s1_ingress_dst_cs3__last_index, s1_ingress_dst_cs3__last_old_value, s1_ingress_dst_cs3__last_value, s1_ingress_dst_cs3__last_write_site, s1_ingress_dst_cs3__next_write_site, s1_ingress_dst_cs3__wrote_any, s1_ingress_dst_cs3__wrote_index0, s1_ingress_dst_cs3_ow, s1_ingress_dst_cs3_ow__last0_old_value, s1_ingress_dst_cs3_ow__last0_value, s1_ingress_dst_cs3_ow__last_index, s1_ingress_dst_cs3_ow__last_old_value, s1_ingress_dst_cs3_ow__last_value, s1_ingress_dst_cs3_ow__last_write_site, s1_ingress_dst_cs3_ow__next_write_site, s1_ingress_dst_cs3_ow__wrote_any, s1_ingress_dst_cs3_ow__wrote_index0, s1_ingress_dst_cs4, s1_ingress_dst_cs4__last0_old_value, s1_ingress_dst_cs4__last0_value, s1_ingress_dst_cs4__last_index, s1_ingress_dst_cs4__last_old_value, s1_ingress_dst_cs4__last_value, s1_ingress_dst_cs4__last_write_site, s1_ingress_dst_cs4__next_write_site, s1_ingress_dst_cs4__wrote_any, s1_ingress_dst_cs4__wrote_index0, s1_ingress_dst_cs4_ow, s1_ingress_dst_cs4_ow__last0_old_value, s1_ingress_dst_cs4_ow__last0_value, s1_ingress_dst_cs4_ow__last_index, s1_ingress_dst_cs4_ow__last_old_value, s1_ingress_dst_cs4_ow__last_value, s1_ingress_dst_cs4_ow__last_write_site, s1_ingress_dst_cs4_ow__next_write_site, s1_ingress_dst_cs4_ow__wrote_any, s1_ingress_dst_cs4_ow__wrote_index0, s1_ingress_dst_entropy_term.action_run, s1_ingress_dst_entropy_term.hit, s1_ingress_dst_ewma, s1_ingress_dst_ewma__last0_old_value, s1_ingress_dst_ewma__last0_value, s1_ingress_dst_ewma__last_index, s1_ingress_dst_ewma__last_old_value, s1_ingress_dst_ewma__last_value, s1_ingress_dst_ewma__last_write_site, s1_ingress_dst_ewma__next_write_site, s1_ingress_dst_ewma__wrote_any, s1_ingress_dst_ewma__wrote_index0, s1_ingress_dst_ewmmd, s1_ingress_dst_ewmmd__last0_old_value, s1_ingress_dst_ewmmd__last0_value, s1_ingress_dst_ewmmd__last_index, s1_ingress_dst_ewmmd__last_old_value, s1_ingress_dst_ewmmd__last_value, s1_ingress_dst_ewmmd__last_write_site, s1_ingress_dst_ewmmd__next_write_site, s1_ingress_dst_ewmmd__wrote_any, s1_ingress_dst_ewmmd__wrote_index0, s1_ingress_ipv4_fib.action_run, s1_ingress_ipv4_fib.hit, s1_ingress_ipv4_fib.ingress_forward.egress_port_1, s1_ingress_ow_counter, s1_ingress_ow_counter__last0_old_value, s1_ingress_ow_counter__last0_value, s1_ingress_ow_counter__last_index, s1_ingress_ow_counter__last_old_value, s1_ingress_ow_counter__last_value, s1_ingress_ow_counter__last_write_site, s1_ingress_ow_counter__next_write_site, s1_ingress_ow_counter__wrote_any, s1_ingress_ow_counter__wrote_index0, s1_ingress_pkt_counter, s1_ingress_pkt_counter__last0_old_value, s1_ingress_pkt_counter__last0_value, s1_ingress_pkt_counter__last_index, s1_ingress_pkt_counter__last_old_value, s1_ingress_pkt_counter__last_value, s1_ingress_pkt_counter__last_write_site, s1_ingress_pkt_counter__next_write_site, s1_ingress_pkt_counter__wrote_any, s1_ingress_pkt_counter__wrote_index0, s1_ingress_src_S, s1_ingress_src_S__last0_old_value, s1_ingress_src_S__last0_value, s1_ingress_src_S__last_index, s1_ingress_src_S__last_old_value, s1_ingress_src_S__last_value, s1_ingress_src_S__last_write_site, s1_ingress_src_S__next_write_site, s1_ingress_src_S__wrote_any, s1_ingress_src_S__wrote_index0, s1_ingress_src_cs1, s1_ingress_src_cs1__last0_old_value, s1_ingress_src_cs1__last0_value, s1_ingress_src_cs1__last_index, s1_ingress_src_cs1__last_old_value, s1_ingress_src_cs1__last_value, s1_ingress_src_cs1__last_write_site, s1_ingress_src_cs1__next_write_site, s1_ingress_src_cs1__wrote_any, s1_ingress_src_cs1__wrote_index0, s1_ingress_src_cs1_ow, s1_ingress_src_cs1_ow__last0_old_value, s1_ingress_src_cs1_ow__last0_value, s1_ingress_src_cs1_ow__last_index, s1_ingress_src_cs1_ow__last_old_value, s1_ingress_src_cs1_ow__last_value, s1_ingress_src_cs1_ow__last_write_site, s1_ingress_src_cs1_ow__next_write_site, s1_ingress_src_cs1_ow__wrote_any, s1_ingress_src_cs1_ow__wrote_index0, s1_ingress_src_cs2, s1_ingress_src_cs2__last0_old_value, s1_ingress_src_cs2__last0_value, s1_ingress_src_cs2__last_index, s1_ingress_src_cs2__last_old_value, s1_ingress_src_cs2__last_value, s1_ingress_src_cs2__last_write_site, s1_ingress_src_cs2__next_write_site, s1_ingress_src_cs2__wrote_any, s1_ingress_src_cs2__wrote_index0, s1_ingress_src_cs2_ow, s1_ingress_src_cs2_ow__last0_old_value, s1_ingress_src_cs2_ow__last0_value, s1_ingress_src_cs2_ow__last_index, s1_ingress_src_cs2_ow__last_old_value, s1_ingress_src_cs2_ow__last_value, s1_ingress_src_cs2_ow__last_write_site, s1_ingress_src_cs2_ow__next_write_site, s1_ingress_src_cs2_ow__wrote_any, s1_ingress_src_cs2_ow__wrote_index0, s1_ingress_src_cs3, s1_ingress_src_cs3__last0_old_value, s1_ingress_src_cs3__last0_value, s1_ingress_src_cs3__last_index, s1_ingress_src_cs3__last_old_value, s1_ingress_src_cs3__last_value, s1_ingress_src_cs3__last_write_site, s1_ingress_src_cs3__next_write_site, s1_ingress_src_cs3__wrote_any, s1_ingress_src_cs3__wrote_index0, s1_ingress_src_cs3_ow, s1_ingress_src_cs3_ow__last0_old_value, s1_ingress_src_cs3_ow__last0_value, s1_ingress_src_cs3_ow__last_index, s1_ingress_src_cs3_ow__last_old_value, s1_ingress_src_cs3_ow__last_value, s1_ingress_src_cs3_ow__last_write_site, s1_ingress_src_cs3_ow__next_write_site, s1_ingress_src_cs3_ow__wrote_any, s1_ingress_src_cs3_ow__wrote_index0, s1_ingress_src_cs4, s1_ingress_src_cs4__last0_old_value, s1_ingress_src_cs4__last0_value, s1_ingress_src_cs4__last_index, s1_ingress_src_cs4__last_old_value, s1_ingress_src_cs4__last_value, s1_ingress_src_cs4__last_write_site, s1_ingress_src_cs4__next_write_site, s1_ingress_src_cs4__wrote_any, s1_ingress_src_cs4__wrote_index0, s1_ingress_src_cs4_ow, s1_ingress_src_cs4_ow__last0_old_value, s1_ingress_src_cs4_ow__last0_value, s1_ingress_src_cs4_ow__last_index, s1_ingress_src_cs4_ow__last_old_value, s1_ingress_src_cs4_ow__last_value, s1_ingress_src_cs4_ow__last_write_site, s1_ingress_src_cs4_ow__next_write_site, s1_ingress_src_cs4_ow__wrote_any, s1_ingress_src_cs4_ow__wrote_index0, s1_ingress_src_entropy_term.action_run, s1_ingress_src_entropy_term.hit, s1_ingress_src_ewma, s1_ingress_src_ewma__last0_old_value, s1_ingress_src_ewma__last0_value, s1_ingress_src_ewma__last_index, s1_ingress_src_ewma__last_old_value, s1_ingress_src_ewma__last_value, s1_ingress_src_ewma__last_write_site, s1_ingress_src_ewma__next_write_site, s1_ingress_src_ewma__wrote_any, s1_ingress_src_ewma__wrote_index0, s1_ingress_src_ewmmd, s1_ingress_src_ewmmd__last0_old_value, s1_ingress_src_ewmmd__last0_value, s1_ingress_src_ewmmd__last_index, s1_ingress_src_ewmmd__last_old_value, s1_ingress_src_ewmmd__last_value, s1_ingress_src_ewmmd__last_write_site, s1_ingress_src_ewmmd__next_write_site, s1_ingress_src_ewmmd__wrote_any, s1_ingress_src_ewmmd__wrote_index0, s1_ipv4_addr_0, s1_ipv4_addr_1, s1_k_aux_0, s1_log2_m_aux_0, s1_m_0, s1_meta.alarm, s1_meta.dst_entropy, s1_meta.dst_ewma, s1_meta.dst_ewmmd, s1_meta.entropy_term, s1_meta.ip_count, s1_meta.pkt_num, s1_meta.src_entropy, s1_meta.src_ewma, s1_meta.src_ewmmd, s1_p4b_clone_i2e, s1_src_S_aux_0, s1_src_c1_0, s1_src_c2_0, s1_src_c3_0, s1_src_c4_0, s1_src_cs1_ow_aux_0, s1_src_cs2_ow_aux_0, s1_src_cs3_ow_aux_0, s1_src_cs4_ow_aux_0, s1_src_g1_0, s1_src_g2_0, s1_src_g3_0, s1_src_g4_0, s1_src_h1_0, s1_src_h2_0, s1_src_h3_0, s1_src_h4_0, s1_src_thresh_0, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_training_len_aux_0, s1_x1_0, s1_x1_2, s1_x2_0, s1_x2_2, s1_x3_0, s1_x3_2, s1_x4_0, s1_x4_2, s1_y_0, s1_y_2;
{
havoc s1_idx_0;
havoc s1_current_ow_0;
havoc s1_src_h1_0;
havoc s1_src_h2_0;
havoc s1_src_h3_0;
havoc s1_src_h4_0;
havoc s1_src_g1_0;
havoc s1_src_g2_0;
havoc s1_src_g3_0;
havoc s1_src_g4_0;
havoc s1_src_cs1_ow_aux_0;
havoc s1_src_c1_0;
havoc s1_src_cs2_ow_aux_0;
havoc s1_src_c2_0;
havoc s1_src_cs3_ow_aux_0;
havoc s1_src_c3_0;
havoc s1_src_cs4_ow_aux_0;
havoc s1_src_c4_0;
havoc s1_src_S_aux_0;
havoc s1_dst_h1_0;
havoc s1_dst_h2_0;
havoc s1_dst_h3_0;
havoc s1_dst_h4_0;
havoc s1_dst_g1_0;
havoc s1_dst_g2_0;
havoc s1_dst_g3_0;
havoc s1_dst_g4_0;
havoc s1_dst_cs1_ow_aux_0;
havoc s1_dst_c1_0;
havoc s1_dst_cs2_ow_aux_0;
havoc s1_dst_c2_0;
havoc s1_dst_cs3_ow_aux_0;
havoc s1_dst_c3_0;
havoc s1_dst_cs4_ow_aux_0;
havoc s1_dst_c4_0;
havoc s1_dst_S_aux_0;
havoc s1_m_0;
havoc s1_log2_m_aux_0;
havoc s1_training_len_aux_0;
havoc s1_k_aux_0;
havoc s1_src_thresh_0;
havoc s1_dst_thresh_0;
havoc s1_alpha_aux_0;
havoc s1_ipv4_addr_0;
havoc s1_h1_0;
havoc s1_h2_0;
havoc s1_h3_0;
havoc s1_h4_0;
havoc s1_ipv4_addr_1;
havoc s1_h1_2;
havoc s1_h2_2;
havoc s1_h3_2;
havoc s1_h4_2;
havoc s1_g1_0;
havoc s1_g2_0;
havoc s1_g3_0;
havoc s1_g4_0;
havoc s1_g1_2;
havoc s1_g2_2;
havoc s1_g3_2;
havoc s1_g4_2;
havoc s1_x1_0;
havoc s1_x2_0;
havoc s1_x3_0;
havoc s1_x4_0;
havoc s1_y_0;
havoc s1_x1_2;
havoc s1_x2_2;
havoc s1_x3_2;
havoc s1_x4_2;
havoc s1_y_2;
    if(s1_isValid[s1_hdr.ipv4]){
        // s1_read
        s1_current_ow_0 := s1_ingress_ow_counter.read(s1_ingress_ow_counter, 0bv32);
        call s1_ingress_cs_hash();
        call s1_ingress_cs_ghash();
        // s1_read
        s1_src_cs1_ow_aux_0 := s1_ingress_src_cs1_ow.read(s1_ingress_src_cs1_ow, s1_src_h1_0);
        if((s1_src_cs1_ow_aux_0 != s1_current_ow_0[8:0])){
            s1_src_c1_0 := 0bv32;
            // s1_write
            s1_ingress_src_cs1_ow__next_write_site := 1;
            call s1_ingress_src_cs1_ow.write(s1_src_h1_0, s1_current_ow_0[8:0]);
        }
        else{
            // s1_read
            s1_src_c1_0 := s1_ingress_src_cs1.read(s1_ingress_src_cs1, s1_src_h1_0);
        }
        s1_src_c1_0 := add.bv32(s1_src_c1_0, s1_src_g1_0);
        // s1_write
        s1_ingress_src_cs1__next_write_site := 1;
        call s1_ingress_src_cs1.write(s1_src_h1_0, s1_src_c1_0);
        s1_src_c1_0 := mul.bv32(s1_src_g1_0, s1_src_c1_0);
        // s1_read
        s1_src_cs2_ow_aux_0 := s1_ingress_src_cs2_ow.read(s1_ingress_src_cs2_ow, s1_src_h2_0);
        if((s1_src_cs2_ow_aux_0 != s1_current_ow_0[8:0])){
            s1_src_c2_0 := 0bv32;
            // s1_write
            s1_ingress_src_cs2_ow__next_write_site := 1;
            call s1_ingress_src_cs2_ow.write(s1_src_h2_0, s1_current_ow_0[8:0]);
        }
        else{
            // s1_read
            s1_src_c2_0 := s1_ingress_src_cs2.read(s1_ingress_src_cs2, s1_src_h2_0);
        }
        s1_src_c2_0 := add.bv32(s1_src_c2_0, s1_src_g2_0);
        // s1_write
        s1_ingress_src_cs2__next_write_site := 1;
        call s1_ingress_src_cs2.write(s1_src_h2_0, s1_src_c2_0);
        s1_src_c2_0 := mul.bv32(s1_src_g2_0, s1_src_c2_0);
        // s1_read
        s1_src_cs3_ow_aux_0 := s1_ingress_src_cs3_ow.read(s1_ingress_src_cs3_ow, s1_src_h3_0);
        if((s1_src_cs3_ow_aux_0 != s1_current_ow_0[8:0])){
            s1_src_c3_0 := 0bv32;
            // s1_write
            s1_ingress_src_cs3_ow__next_write_site := 1;
            call s1_ingress_src_cs3_ow.write(s1_src_h3_0, s1_current_ow_0[8:0]);
        }
        else{
            // s1_read
            s1_src_c3_0 := s1_ingress_src_cs3.read(s1_ingress_src_cs3, s1_src_h3_0);
        }
        s1_src_c3_0 := add.bv32(s1_src_c3_0, s1_src_g3_0);
        // s1_write
        s1_ingress_src_cs3__next_write_site := 1;
        call s1_ingress_src_cs3.write(s1_src_h3_0, s1_src_c3_0);
        s1_src_c3_0 := mul.bv32(s1_src_g3_0, s1_src_c3_0);
        // s1_read
        s1_src_cs4_ow_aux_0 := s1_ingress_src_cs4_ow.read(s1_ingress_src_cs4_ow, s1_src_h4_0);
        if((s1_src_cs4_ow_aux_0 != s1_current_ow_0[8:0])){
            s1_src_c4_0 := 0bv32;
            // s1_write
            s1_ingress_src_cs4_ow__next_write_site := 1;
            call s1_ingress_src_cs4_ow.write(s1_src_h4_0, s1_current_ow_0[8:0]);
        }
        else{
            // s1_read
            s1_src_c4_0 := s1_ingress_src_cs4.read(s1_ingress_src_cs4, s1_src_h4_0);
        }
        s1_src_c4_0 := add.bv32(s1_src_c4_0, s1_src_g4_0);
        // s1_write
        s1_ingress_src_cs4__next_write_site := 1;
        call s1_ingress_src_cs4.write(s1_src_h4_0, s1_src_c4_0);
        s1_src_c4_0 := mul.bv32(s1_src_g4_0, s1_src_c4_0);
        call s1_ingress_median();
        if(bugt.bv32(s1_meta.ip_count, 0bv32)){
            call s1_ingress_src_entropy_term.apply();
        }
        else{
            s1_meta.entropy_term := 0bv32;
        }
        // s1_read
        s1_src_S_aux_0 := s1_ingress_src_S.read(s1_ingress_src_S, 0bv32);
        s1_src_S_aux_0 := add.bv32(s1_src_S_aux_0, s1_meta.entropy_term);
        // s1_write
        s1_ingress_src_S__next_write_site := 1;
        call s1_ingress_src_S.write(0bv32, s1_src_S_aux_0);
        call s1_cs_hash_1();
        call s1_cs_ghash_1();
        // s1_read
        s1_dst_cs1_ow_aux_0 := s1_ingress_dst_cs1_ow.read(s1_ingress_dst_cs1_ow, s1_dst_h1_0);
        if((s1_dst_cs1_ow_aux_0 != s1_current_ow_0[8:0])){
            s1_dst_c1_0 := 0bv32;
            // s1_write
            s1_ingress_dst_cs1_ow__next_write_site := 1;
            call s1_ingress_dst_cs1_ow.write(s1_dst_h1_0, s1_current_ow_0[8:0]);
        }
        else{
            // s1_read
            s1_dst_c1_0 := s1_ingress_dst_cs1.read(s1_ingress_dst_cs1, s1_dst_h1_0);
        }
        s1_dst_c1_0 := add.bv32(s1_dst_c1_0, s1_dst_g1_0);
        // s1_write
        s1_ingress_dst_cs1__next_write_site := 1;
        call s1_ingress_dst_cs1.write(s1_dst_h1_0, s1_dst_c1_0);
        s1_dst_c1_0 := mul.bv32(s1_dst_g1_0, s1_dst_c1_0);
        // s1_read
        s1_dst_cs2_ow_aux_0 := s1_ingress_dst_cs2_ow.read(s1_ingress_dst_cs2_ow, s1_dst_h2_0);
        if((s1_dst_cs2_ow_aux_0 != s1_current_ow_0[8:0])){
            s1_dst_c2_0 := 0bv32;
            // s1_write
            s1_ingress_dst_cs2_ow__next_write_site := 1;
            call s1_ingress_dst_cs2_ow.write(s1_dst_h2_0, s1_current_ow_0[8:0]);
        }
        else{
            // s1_read
            s1_dst_c2_0 := s1_ingress_dst_cs2.read(s1_ingress_dst_cs2, s1_dst_h2_0);
        }
        s1_dst_c2_0 := add.bv32(s1_dst_c2_0, s1_dst_g2_0);
        // s1_write
        s1_ingress_dst_cs2__next_write_site := 1;
        call s1_ingress_dst_cs2.write(s1_dst_h2_0, s1_dst_c2_0);
        s1_dst_c2_0 := mul.bv32(s1_dst_g2_0, s1_dst_c2_0);
        // s1_read
        s1_dst_cs3_ow_aux_0 := s1_ingress_dst_cs3_ow.read(s1_ingress_dst_cs3_ow, s1_dst_h3_0);
        if((s1_dst_cs3_ow_aux_0 != s1_current_ow_0[8:0])){
            s1_dst_c3_0 := 0bv32;
            // s1_write
            s1_ingress_dst_cs3_ow__next_write_site := 1;
            call s1_ingress_dst_cs3_ow.write(s1_dst_h3_0, s1_current_ow_0[8:0]);
        }
        else{
            // s1_read
            s1_dst_c3_0 := s1_ingress_dst_cs3.read(s1_ingress_dst_cs3, s1_dst_h3_0);
        }
        s1_dst_c3_0 := add.bv32(s1_dst_c3_0, s1_dst_g3_0);
        // s1_write
        s1_ingress_dst_cs3__next_write_site := 1;
        call s1_ingress_dst_cs3.write(s1_dst_h3_0, s1_dst_c3_0);
        s1_dst_c3_0 := mul.bv32(s1_dst_g3_0, s1_dst_c3_0);
        // s1_read
        s1_dst_cs4_ow_aux_0 := s1_ingress_dst_cs4_ow.read(s1_ingress_dst_cs4_ow, s1_dst_h4_0);
        if((s1_dst_cs4_ow_aux_0 != s1_current_ow_0[8:0])){
            s1_dst_c4_0 := 0bv32;
            // s1_write
            s1_ingress_dst_cs4_ow__next_write_site := 1;
            call s1_ingress_dst_cs4_ow.write(s1_dst_h4_0, s1_current_ow_0[8:0]);
        }
        else{
            // s1_read
            s1_dst_c4_0 := s1_ingress_dst_cs4.read(s1_ingress_dst_cs4, s1_dst_h4_0);
        }
        s1_dst_c4_0 := add.bv32(s1_dst_c4_0, s1_dst_g4_0);
        // s1_write
        s1_ingress_dst_cs4__next_write_site := 1;
        call s1_ingress_dst_cs4.write(s1_dst_h4_0, s1_dst_c4_0);
        s1_dst_c4_0 := mul.bv32(s1_dst_g4_0, s1_dst_c4_0);
        call s1_median_1();
        if(bugt.bv32(s1_meta.ip_count, 0bv32)){
            call s1_ingress_dst_entropy_term.apply();
        }
        else{
            s1_meta.entropy_term := 0bv32;
        }
        // s1_read
        s1_dst_S_aux_0 := s1_ingress_dst_S.read(s1_ingress_dst_S, 0bv32);
        s1_dst_S_aux_0 := add.bv32(s1_dst_S_aux_0, s1_meta.entropy_term);
        // s1_write
        s1_ingress_dst_S__next_write_site := 1;
        call s1_ingress_dst_S.write(0bv32, s1_dst_S_aux_0);
        // s1_read
        s1_log2_m_aux_0 := s1_ingress_log2_m.read(s1_ingress_log2_m, 0bv32);
        s1_m_0 := shl.bv32(1bv32, 0bv27++s1_log2_m_aux_0);
        // s1_read
        s1_meta.pkt_num := s1_ingress_pkt_counter.read(s1_ingress_pkt_counter, 0bv32);
        s1_meta.pkt_num := add.bv32(s1_meta.pkt_num, 1bv32);
        if((s1_meta.pkt_num != s1_m_0)){
            // s1_write
            s1_ingress_pkt_counter__next_write_site := 1;
            call s1_ingress_pkt_counter.write(0bv32, s1_meta.pkt_num);
        }
        else{
            s1_current_ow_0 := add.bv32(s1_current_ow_0, 1bv32);
            // s1_write
            s1_ingress_ow_counter__next_write_site := 1;
            call s1_ingress_ow_counter.write(0bv32, s1_current_ow_0);
            s1_meta.src_entropy := sub.bv32(shl.bv32(0bv27++s1_log2_m_aux_0, 4bv32), shr.bv32(s1_src_S_aux_0, 0bv27++s1_log2_m_aux_0));
            s1_meta.dst_entropy := sub.bv32(shl.bv32(0bv27++s1_log2_m_aux_0, 4bv32), shr.bv32(s1_dst_S_aux_0, 0bv27++s1_log2_m_aux_0));
            // s1_read
            s1_meta.src_ewma := s1_ingress_src_ewma.read(s1_ingress_src_ewma, 0bv32);
            // s1_read
            s1_meta.src_ewmmd := s1_ingress_src_ewmmd.read(s1_ingress_src_ewmmd, 0bv32);
            // s1_read
            s1_meta.dst_ewma := s1_ingress_dst_ewma.read(s1_ingress_dst_ewma, 0bv32);
            // s1_read
            s1_meta.dst_ewmmd := s1_ingress_dst_ewmmd.read(s1_ingress_dst_ewmmd, 0bv32);
            if((s1_current_ow_0 == 1bv32)){
                s1_meta.src_ewma := shl.bv32(s1_meta.src_entropy, 14bv32);
                s1_meta.src_ewmmd := 0bv32;
                s1_meta.dst_ewma := shl.bv32(s1_meta.dst_entropy, 14bv32);
                s1_meta.dst_ewmmd := 0bv32;
            }
            else{
                s1_meta.alarm := 0bv8;
                // s1_read
                s1_training_len_aux_0 := s1_ingress_training_len.read(s1_ingress_training_len, 0bv32);
                if(bugt.bv32(s1_current_ow_0, s1_training_len_aux_0)){
                    // s1_read
                    s1_k_aux_0 := s1_ingress_k.read(s1_ingress_k, 0bv32);
                    s1_src_thresh_0 := add.bv32(s1_meta.src_ewma, shr.bv32(mul.bv32(0bv24++s1_k_aux_0, s1_meta.src_ewmmd), 3bv32));
                    s1_dst_thresh_0 := sub.bv32(s1_meta.dst_ewma, shr.bv32(mul.bv32(0bv24++s1_k_aux_0, s1_meta.dst_ewmmd), 3bv32));
                    if((bugt.bv32(shl.bv32(s1_meta.src_entropy, 14bv32), s1_src_thresh_0)) || (bult.bv32(shl.bv32(s1_meta.dst_entropy, 14bv32), s1_dst_thresh_0))){
                        s1_meta.alarm := 1bv8;
                    }
                }
                if((s1_meta.alarm == 0bv8)){
                    // s1_read
                    s1_alpha_aux_0 := s1_ingress_alpha.read(s1_ingress_alpha, 0bv32);
                    s1_meta.src_ewma := add.bv32(shl.bv32(mul.bv32(0bv24++s1_alpha_aux_0, s1_meta.src_entropy), 6bv32), shr.bv32(mul.bv32(sub.bv32(256bv32, 0bv24++s1_alpha_aux_0), s1_meta.src_ewma), 8bv32));
                    if(buge.bv32(shl.bv32(s1_meta.src_entropy, 14bv32), s1_meta.src_ewma)){
                        s1_meta.src_ewmmd := add.bv32(shr.bv32(mul.bv32(0bv24++s1_alpha_aux_0, sub.bv32(shl.bv32(s1_meta.src_entropy, 14bv32), s1_meta.src_ewma)), 8bv32), shr.bv32(mul.bv32(sub.bv32(256bv32, 0bv24++s1_alpha_aux_0), s1_meta.src_ewmmd), 8bv32));
                    }
                    else{
                        s1_meta.src_ewmmd := add.bv32(shr.bv32(mul.bv32(0bv24++s1_alpha_aux_0, sub.bv32(s1_meta.src_ewma, shl.bv32(s1_meta.src_entropy, 14bv32))), 8bv32), shr.bv32(mul.bv32(sub.bv32(256bv32, 0bv24++s1_alpha_aux_0), s1_meta.src_ewmmd), 8bv32));
                    }
                    s1_meta.dst_ewma := add.bv32(shl.bv32(mul.bv32(0bv24++s1_alpha_aux_0, s1_meta.dst_entropy), 6bv32), shr.bv32(mul.bv32(sub.bv32(256bv32, 0bv24++s1_alpha_aux_0), s1_meta.dst_ewma), 8bv32));
                    if(buge.bv32(shl.bv32(s1_meta.dst_entropy, 14bv32), s1_meta.dst_ewma)){
                        s1_meta.dst_ewmmd := add.bv32(shr.bv32(mul.bv32(0bv24++s1_alpha_aux_0, sub.bv32(shl.bv32(s1_meta.dst_entropy, 14bv32), s1_meta.dst_ewma)), 8bv32), shr.bv32(mul.bv32(sub.bv32(256bv32, 0bv24++s1_alpha_aux_0), s1_meta.dst_ewmmd), 8bv32));
                    }
                    else{
                        s1_meta.dst_ewmmd := add.bv32(shr.bv32(mul.bv32(0bv24++s1_alpha_aux_0, sub.bv32(s1_meta.dst_ewma, shl.bv32(s1_meta.dst_entropy, 14bv32))), 8bv32), shr.bv32(mul.bv32(sub.bv32(256bv32, 0bv24++s1_alpha_aux_0), s1_meta.dst_ewmmd), 8bv32));
                    }
                }
            }
            // s1_write
            s1_ingress_src_ewma__next_write_site := 1;
            call s1_ingress_src_ewma.write(0bv32, s1_meta.src_ewma);
            // s1_write
            s1_ingress_src_ewmmd__next_write_site := 1;
            call s1_ingress_src_ewmmd.write(0bv32, s1_meta.src_ewmmd);
            // s1_write
            s1_ingress_dst_ewma__next_write_site := 1;
            call s1_ingress_dst_ewma.write(0bv32, s1_meta.dst_ewma);
            // s1_write
            s1_ingress_dst_ewmmd__next_write_site := 1;
            call s1_ingress_dst_ewmmd.write(0bv32, s1_meta.dst_ewmmd);
            s1_p4b_clone_i2e := true;
            // s1_write
            s1_ingress_pkt_counter__next_write_site := 2;
            call s1_ingress_pkt_counter.write(0bv32, 0bv32);
            // s1_write
            s1_ingress_src_S__next_write_site := 2;
            call s1_ingress_src_S.write(0bv32, 0bv32);
            // s1_write
            s1_ingress_dst_S__next_write_site := 2;
            call s1_ingress_dst_S.write(0bv32, 0bv32);
        }
        call s1_ingress_ipv4_fib.apply();
    }
}
function {:inline true}s1_ingress_alpha.read(s1_reg:[bv32]bv8, s1_index:bv32)returns (bv8) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_alpha.write(s1_index:bv32, s1_value:bv8)
	modifies s1_ingress_alpha, s1_ingress_alpha__last0_old_value, s1_ingress_alpha__last0_value, s1_ingress_alpha__last_index, s1_ingress_alpha__last_old_value, s1_ingress_alpha__last_value, s1_ingress_alpha__last_write_site, s1_ingress_alpha__wrote_any, s1_ingress_alpha__wrote_index0;
{
    s1_ingress_alpha__last_old_value := s1_ingress_alpha[s1_index];
    s1_ingress_alpha[s1_index] := s1_value;
    s1_ingress_alpha__last_index := s1_index;
    s1_ingress_alpha__last_value := s1_value;
    s1_ingress_alpha__last_write_site := s1_ingress_alpha__next_write_site;
    s1_ingress_alpha__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_alpha__wrote_index0 := true;
        s1_ingress_alpha__last0_old_value := s1_ingress_alpha__last_old_value;
        s1_ingress_alpha__last0_value := s1_value;
    }
}

// s1_Action s1_ingress_cs_ghash
procedure {:inline 1} s1_ingress_cs_ghash()
	modifies s1_g1_0, s1_g2_0, s1_g3_0, s1_g4_0, s1_src_g1_0, s1_src_g2_0, s1_src_g3_0, s1_src_g4_0;
{
    s1_g1_0 := 1bv32;
    s1_g2_0 := 1bv32;
    s1_g3_0 := 1bv32;
    s1_g4_0 := 1bv32;
    s1_g1_0 := add.bv32(shl.bv32(s1_g1_0, 1bv32), 4294967295bv32);
    s1_g2_0 := add.bv32(shl.bv32(s1_g2_0, 1bv32), 4294967295bv32);
    s1_g3_0 := add.bv32(shl.bv32(s1_g3_0, 1bv32), 4294967295bv32);
    s1_g4_0 := add.bv32(shl.bv32(s1_g4_0, 1bv32), 4294967295bv32);
    s1_src_g1_0 := s1_g1_0;
    s1_src_g2_0 := s1_g2_0;
    s1_src_g3_0 := s1_g3_0;
    s1_src_g4_0 := s1_g4_0;
}

// s1_Action s1_ingress_cs_hash
procedure {:inline 1} s1_ingress_cs_hash()
	modifies s1_h1_0, s1_h2_0, s1_h3_0, s1_h4_0, s1_idx_0, s1_ipv4_addr_0, s1_src_h1_0, s1_src_h2_0, s1_src_h3_0, s1_src_h4_0;
{
    s1_ipv4_addr_0 := s1_hdr.ipv4.src_addr;
    s1_idx_0 := band.bv32(s1_ipv4_addr_0, 1bv32);
    s1_h1_0 := s1_idx_0;
    s1_h2_0 := s1_idx_0;
    s1_h3_0 := s1_idx_0;
    s1_h4_0 := s1_idx_0;
    s1_src_h1_0 := s1_h1_0;
    s1_src_h2_0 := s1_h2_0;
    s1_src_h3_0 := s1_h3_0;
    s1_src_h4_0 := s1_h4_0;
}

// s1_Action s1_ingress_drop
procedure {:inline 1} s1_ingress_drop()
	modifies s1_drop;
{
    call s1_mark_to_drop();
}
function {:inline true}s1_ingress_dst_S.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_dst_S.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_dst_S, s1_ingress_dst_S__last0_old_value, s1_ingress_dst_S__last0_value, s1_ingress_dst_S__last_index, s1_ingress_dst_S__last_old_value, s1_ingress_dst_S__last_value, s1_ingress_dst_S__last_write_site, s1_ingress_dst_S__wrote_any, s1_ingress_dst_S__wrote_index0;
{
    s1_ingress_dst_S__last_old_value := s1_ingress_dst_S[s1_index];
    s1_ingress_dst_S[s1_index] := s1_value;
    s1_ingress_dst_S__last_index := s1_index;
    s1_ingress_dst_S__last_value := s1_value;
    s1_ingress_dst_S__last_write_site := s1_ingress_dst_S__next_write_site;
    s1_ingress_dst_S__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_dst_S__wrote_index0 := true;
        s1_ingress_dst_S__last0_old_value := s1_ingress_dst_S__last_old_value;
        s1_ingress_dst_S__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_dst_cs1.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_dst_cs1.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_dst_cs1, s1_ingress_dst_cs1__last0_old_value, s1_ingress_dst_cs1__last0_value, s1_ingress_dst_cs1__last_index, s1_ingress_dst_cs1__last_old_value, s1_ingress_dst_cs1__last_value, s1_ingress_dst_cs1__last_write_site, s1_ingress_dst_cs1__wrote_any, s1_ingress_dst_cs1__wrote_index0;
{
    s1_ingress_dst_cs1__last_old_value := s1_ingress_dst_cs1[s1_index];
    s1_ingress_dst_cs1[s1_index] := s1_value;
    s1_ingress_dst_cs1__last_index := s1_index;
    s1_ingress_dst_cs1__last_value := s1_value;
    s1_ingress_dst_cs1__last_write_site := s1_ingress_dst_cs1__next_write_site;
    s1_ingress_dst_cs1__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_dst_cs1__wrote_index0 := true;
        s1_ingress_dst_cs1__last0_old_value := s1_ingress_dst_cs1__last_old_value;
        s1_ingress_dst_cs1__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_dst_cs1_ow.read(s1_reg:[bv32]bv8, s1_index:bv32)returns (bv8) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_dst_cs1_ow.write(s1_index:bv32, s1_value:bv8)
	modifies s1_ingress_dst_cs1_ow, s1_ingress_dst_cs1_ow__last0_old_value, s1_ingress_dst_cs1_ow__last0_value, s1_ingress_dst_cs1_ow__last_index, s1_ingress_dst_cs1_ow__last_old_value, s1_ingress_dst_cs1_ow__last_value, s1_ingress_dst_cs1_ow__last_write_site, s1_ingress_dst_cs1_ow__wrote_any, s1_ingress_dst_cs1_ow__wrote_index0;
{
    s1_ingress_dst_cs1_ow__last_old_value := s1_ingress_dst_cs1_ow[s1_index];
    s1_ingress_dst_cs1_ow[s1_index] := s1_value;
    s1_ingress_dst_cs1_ow__last_index := s1_index;
    s1_ingress_dst_cs1_ow__last_value := s1_value;
    s1_ingress_dst_cs1_ow__last_write_site := s1_ingress_dst_cs1_ow__next_write_site;
    s1_ingress_dst_cs1_ow__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_dst_cs1_ow__wrote_index0 := true;
        s1_ingress_dst_cs1_ow__last0_old_value := s1_ingress_dst_cs1_ow__last_old_value;
        s1_ingress_dst_cs1_ow__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_dst_cs2.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_dst_cs2.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_dst_cs2, s1_ingress_dst_cs2__last0_old_value, s1_ingress_dst_cs2__last0_value, s1_ingress_dst_cs2__last_index, s1_ingress_dst_cs2__last_old_value, s1_ingress_dst_cs2__last_value, s1_ingress_dst_cs2__last_write_site, s1_ingress_dst_cs2__wrote_any, s1_ingress_dst_cs2__wrote_index0;
{
    s1_ingress_dst_cs2__last_old_value := s1_ingress_dst_cs2[s1_index];
    s1_ingress_dst_cs2[s1_index] := s1_value;
    s1_ingress_dst_cs2__last_index := s1_index;
    s1_ingress_dst_cs2__last_value := s1_value;
    s1_ingress_dst_cs2__last_write_site := s1_ingress_dst_cs2__next_write_site;
    s1_ingress_dst_cs2__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_dst_cs2__wrote_index0 := true;
        s1_ingress_dst_cs2__last0_old_value := s1_ingress_dst_cs2__last_old_value;
        s1_ingress_dst_cs2__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_dst_cs2_ow.read(s1_reg:[bv32]bv8, s1_index:bv32)returns (bv8) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_dst_cs2_ow.write(s1_index:bv32, s1_value:bv8)
	modifies s1_ingress_dst_cs2_ow, s1_ingress_dst_cs2_ow__last0_old_value, s1_ingress_dst_cs2_ow__last0_value, s1_ingress_dst_cs2_ow__last_index, s1_ingress_dst_cs2_ow__last_old_value, s1_ingress_dst_cs2_ow__last_value, s1_ingress_dst_cs2_ow__last_write_site, s1_ingress_dst_cs2_ow__wrote_any, s1_ingress_dst_cs2_ow__wrote_index0;
{
    s1_ingress_dst_cs2_ow__last_old_value := s1_ingress_dst_cs2_ow[s1_index];
    s1_ingress_dst_cs2_ow[s1_index] := s1_value;
    s1_ingress_dst_cs2_ow__last_index := s1_index;
    s1_ingress_dst_cs2_ow__last_value := s1_value;
    s1_ingress_dst_cs2_ow__last_write_site := s1_ingress_dst_cs2_ow__next_write_site;
    s1_ingress_dst_cs2_ow__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_dst_cs2_ow__wrote_index0 := true;
        s1_ingress_dst_cs2_ow__last0_old_value := s1_ingress_dst_cs2_ow__last_old_value;
        s1_ingress_dst_cs2_ow__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_dst_cs3.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_dst_cs3.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_dst_cs3, s1_ingress_dst_cs3__last0_old_value, s1_ingress_dst_cs3__last0_value, s1_ingress_dst_cs3__last_index, s1_ingress_dst_cs3__last_old_value, s1_ingress_dst_cs3__last_value, s1_ingress_dst_cs3__last_write_site, s1_ingress_dst_cs3__wrote_any, s1_ingress_dst_cs3__wrote_index0;
{
    s1_ingress_dst_cs3__last_old_value := s1_ingress_dst_cs3[s1_index];
    s1_ingress_dst_cs3[s1_index] := s1_value;
    s1_ingress_dst_cs3__last_index := s1_index;
    s1_ingress_dst_cs3__last_value := s1_value;
    s1_ingress_dst_cs3__last_write_site := s1_ingress_dst_cs3__next_write_site;
    s1_ingress_dst_cs3__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_dst_cs3__wrote_index0 := true;
        s1_ingress_dst_cs3__last0_old_value := s1_ingress_dst_cs3__last_old_value;
        s1_ingress_dst_cs3__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_dst_cs3_ow.read(s1_reg:[bv32]bv8, s1_index:bv32)returns (bv8) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_dst_cs3_ow.write(s1_index:bv32, s1_value:bv8)
	modifies s1_ingress_dst_cs3_ow, s1_ingress_dst_cs3_ow__last0_old_value, s1_ingress_dst_cs3_ow__last0_value, s1_ingress_dst_cs3_ow__last_index, s1_ingress_dst_cs3_ow__last_old_value, s1_ingress_dst_cs3_ow__last_value, s1_ingress_dst_cs3_ow__last_write_site, s1_ingress_dst_cs3_ow__wrote_any, s1_ingress_dst_cs3_ow__wrote_index0;
{
    s1_ingress_dst_cs3_ow__last_old_value := s1_ingress_dst_cs3_ow[s1_index];
    s1_ingress_dst_cs3_ow[s1_index] := s1_value;
    s1_ingress_dst_cs3_ow__last_index := s1_index;
    s1_ingress_dst_cs3_ow__last_value := s1_value;
    s1_ingress_dst_cs3_ow__last_write_site := s1_ingress_dst_cs3_ow__next_write_site;
    s1_ingress_dst_cs3_ow__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_dst_cs3_ow__wrote_index0 := true;
        s1_ingress_dst_cs3_ow__last0_old_value := s1_ingress_dst_cs3_ow__last_old_value;
        s1_ingress_dst_cs3_ow__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_dst_cs4.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_dst_cs4.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_dst_cs4, s1_ingress_dst_cs4__last0_old_value, s1_ingress_dst_cs4__last0_value, s1_ingress_dst_cs4__last_index, s1_ingress_dst_cs4__last_old_value, s1_ingress_dst_cs4__last_value, s1_ingress_dst_cs4__last_write_site, s1_ingress_dst_cs4__wrote_any, s1_ingress_dst_cs4__wrote_index0;
{
    s1_ingress_dst_cs4__last_old_value := s1_ingress_dst_cs4[s1_index];
    s1_ingress_dst_cs4[s1_index] := s1_value;
    s1_ingress_dst_cs4__last_index := s1_index;
    s1_ingress_dst_cs4__last_value := s1_value;
    s1_ingress_dst_cs4__last_write_site := s1_ingress_dst_cs4__next_write_site;
    s1_ingress_dst_cs4__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_dst_cs4__wrote_index0 := true;
        s1_ingress_dst_cs4__last0_old_value := s1_ingress_dst_cs4__last_old_value;
        s1_ingress_dst_cs4__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_dst_cs4_ow.read(s1_reg:[bv32]bv8, s1_index:bv32)returns (bv8) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_dst_cs4_ow.write(s1_index:bv32, s1_value:bv8)
	modifies s1_ingress_dst_cs4_ow, s1_ingress_dst_cs4_ow__last0_old_value, s1_ingress_dst_cs4_ow__last0_value, s1_ingress_dst_cs4_ow__last_index, s1_ingress_dst_cs4_ow__last_old_value, s1_ingress_dst_cs4_ow__last_value, s1_ingress_dst_cs4_ow__last_write_site, s1_ingress_dst_cs4_ow__wrote_any, s1_ingress_dst_cs4_ow__wrote_index0;
{
    s1_ingress_dst_cs4_ow__last_old_value := s1_ingress_dst_cs4_ow[s1_index];
    s1_ingress_dst_cs4_ow[s1_index] := s1_value;
    s1_ingress_dst_cs4_ow__last_index := s1_index;
    s1_ingress_dst_cs4_ow__last_value := s1_value;
    s1_ingress_dst_cs4_ow__last_write_site := s1_ingress_dst_cs4_ow__next_write_site;
    s1_ingress_dst_cs4_ow__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_dst_cs4_ow__wrote_index0 := true;
        s1_ingress_dst_cs4_ow__last0_old_value := s1_ingress_dst_cs4_ow__last_old_value;
        s1_ingress_dst_cs4_ow__last0_value := s1_value;
    }
}

// s1_Table s1_ingress_dst_entropy_term
procedure {:inline 1} s1_ingress_dst_entropy_term.apply()
	modifies s1_ingress_dst_entropy_term.action_run, s1_ingress_dst_entropy_term.hit, s1_meta.entropy_term, s1_meta.ip_count;
{
    s1_meta.ip_count := s1_meta.ip_count;
    s1_ingress_dst_entropy_term.hit := false;
    goto s1_action_get_entropy_term_1;

    s1_action_get_entropy_term_1:
    assume s1_ingress_dst_entropy_term.action_run == s1_ingress_dst_entropy_term.action.get_entropy_term_1;
    call s1_get_entropy_term_1(s1_ingress_dst_entropy_term.get_entropy_term_1.entropy_term_2);
    goto s1_Exit;

    s1_Exit:
}
function {:inline true}s1_ingress_dst_ewma.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_dst_ewma.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_dst_ewma, s1_ingress_dst_ewma__last0_old_value, s1_ingress_dst_ewma__last0_value, s1_ingress_dst_ewma__last_index, s1_ingress_dst_ewma__last_old_value, s1_ingress_dst_ewma__last_value, s1_ingress_dst_ewma__last_write_site, s1_ingress_dst_ewma__wrote_any, s1_ingress_dst_ewma__wrote_index0;
{
    s1_ingress_dst_ewma__last_old_value := s1_ingress_dst_ewma[s1_index];
    s1_ingress_dst_ewma[s1_index] := s1_value;
    s1_ingress_dst_ewma__last_index := s1_index;
    s1_ingress_dst_ewma__last_value := s1_value;
    s1_ingress_dst_ewma__last_write_site := s1_ingress_dst_ewma__next_write_site;
    s1_ingress_dst_ewma__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_dst_ewma__wrote_index0 := true;
        s1_ingress_dst_ewma__last0_old_value := s1_ingress_dst_ewma__last_old_value;
        s1_ingress_dst_ewma__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_dst_ewmmd.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_dst_ewmmd.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_dst_ewmmd, s1_ingress_dst_ewmmd__last0_old_value, s1_ingress_dst_ewmmd__last0_value, s1_ingress_dst_ewmmd__last_index, s1_ingress_dst_ewmmd__last_old_value, s1_ingress_dst_ewmmd__last_value, s1_ingress_dst_ewmmd__last_write_site, s1_ingress_dst_ewmmd__wrote_any, s1_ingress_dst_ewmmd__wrote_index0;
{
    s1_ingress_dst_ewmmd__last_old_value := s1_ingress_dst_ewmmd[s1_index];
    s1_ingress_dst_ewmmd[s1_index] := s1_value;
    s1_ingress_dst_ewmmd__last_index := s1_index;
    s1_ingress_dst_ewmmd__last_value := s1_value;
    s1_ingress_dst_ewmmd__last_write_site := s1_ingress_dst_ewmmd__next_write_site;
    s1_ingress_dst_ewmmd__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_dst_ewmmd__wrote_index0 := true;
        s1_ingress_dst_ewmmd__last0_old_value := s1_ingress_dst_ewmmd__last_old_value;
        s1_ingress_dst_ewmmd__last0_value := s1_value;
    }
}

// s1_Action s1_ingress_forward
procedure {:inline 1} s1_ingress_forward(s1_egress_port_1:bv9)
	modifies s1_forward, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    s1_standard_metadata.egress_spec := s1_egress_port_1;
    s1_standard_metadata.egress_port := s1_egress_port_1;
    s1_forward := true;
}

// s1_Action s1_ingress_get_entropy_term
procedure {:inline 1} s1_ingress_get_entropy_term(s1_entropy_term_1:bv32)
	modifies s1_meta.entropy_term;
{
    s1_meta.entropy_term := s1_entropy_term_1;
}

// s1_Table s1_ingress_ipv4_fib
procedure {:inline 1} s1_ingress_ipv4_fib.apply()
	modifies s1_drop, s1_forward, s1_hdr.ipv4.dst_addr, s1_ingress_ipv4_fib.action_run, s1_ingress_ipv4_fib.hit, s1_ingress_ipv4_fib.ingress_forward.egress_port_1, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    s1_hdr.ipv4.dst_addr := s1_hdr.ipv4.dst_addr;
    s1_ingress_ipv4_fib.hit := false;
    if(band.bv32(s1_hdr.ipv4.dst_addr, 0bv32) == 0bv32){
        s1_ingress_ipv4_fib.hit := true;
        s1_ingress_ipv4_fib.action_run := s1_ingress_ipv4_fib.action.ingress_forward;
        s1_ingress_ipv4_fib.ingress_forward.egress_port_1 := 1bv9;
        call s1_ingress_forward(s1_ingress_ipv4_fib.ingress_forward.egress_port_1);
        goto s1_Exit;
    }
    if(!s1_ingress_ipv4_fib.hit){
        s1_ingress_ipv4_fib.action_run := s1_ingress_ipv4_fib.action.ingress_drop;
        call s1_ingress_drop();
        goto s1_Exit;
    }

    s1_Exit:
}
function {:inline true}s1_ingress_k.read(s1_reg:[bv32]bv8, s1_index:bv32)returns (bv8) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_k.write(s1_index:bv32, s1_value:bv8)
	modifies s1_ingress_k, s1_ingress_k__last0_old_value, s1_ingress_k__last0_value, s1_ingress_k__last_index, s1_ingress_k__last_old_value, s1_ingress_k__last_value, s1_ingress_k__last_write_site, s1_ingress_k__wrote_any, s1_ingress_k__wrote_index0;
{
    s1_ingress_k__last_old_value := s1_ingress_k[s1_index];
    s1_ingress_k[s1_index] := s1_value;
    s1_ingress_k__last_index := s1_index;
    s1_ingress_k__last_value := s1_value;
    s1_ingress_k__last_write_site := s1_ingress_k__next_write_site;
    s1_ingress_k__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_k__wrote_index0 := true;
        s1_ingress_k__last0_old_value := s1_ingress_k__last_old_value;
        s1_ingress_k__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_log2_m.read(s1_reg:[bv32]bv5, s1_index:bv32)returns (bv5) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_log2_m.write(s1_index:bv32, s1_value:bv5)
	modifies s1_ingress_log2_m, s1_ingress_log2_m__last0_old_value, s1_ingress_log2_m__last0_value, s1_ingress_log2_m__last_index, s1_ingress_log2_m__last_old_value, s1_ingress_log2_m__last_value, s1_ingress_log2_m__last_write_site, s1_ingress_log2_m__wrote_any, s1_ingress_log2_m__wrote_index0;
{
    s1_ingress_log2_m__last_old_value := s1_ingress_log2_m[s1_index];
    s1_ingress_log2_m[s1_index] := s1_value;
    s1_ingress_log2_m__last_index := s1_index;
    s1_ingress_log2_m__last_value := s1_value;
    s1_ingress_log2_m__last_write_site := s1_ingress_log2_m__next_write_site;
    s1_ingress_log2_m__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_log2_m__wrote_index0 := true;
        s1_ingress_log2_m__last0_old_value := s1_ingress_log2_m__last_old_value;
        s1_ingress_log2_m__last0_value := s1_value;
    }
}

// s1_Action s1_ingress_median
procedure {:inline 1} s1_ingress_median()
	modifies s1_meta.ip_count, s1_x1_0, s1_x2_0, s1_x3_0, s1_x4_0, s1_y_0;
{
    s1_x1_0 := s1_src_c1_0;
    s1_x2_0 := s1_src_c2_0;
    s1_x3_0 := s1_src_c3_0;
    s1_x4_0 := s1_src_c4_0;
    if((((((bule.bv32(s1_x1_0, s1_x2_0)) && (bule.bv32(s1_x1_0, s1_x3_0))) && (bule.bv32(s1_x1_0, s1_x4_0))) && (buge.bv32(s1_x2_0, s1_x3_0))) && (buge.bv32(s1_x2_0, s1_x4_0))) || (((((bule.bv32(s1_x2_0, s1_x1_0)) && (bule.bv32(s1_x2_0, s1_x3_0))) && (bule.bv32(s1_x2_0, s1_x4_0))) && (buge.bv32(s1_x1_0, s1_x3_0))) && (buge.bv32(s1_x1_0, s1_x4_0)))){
        s1_y_0 := shr.bv32(add.bv32(s1_x3_0, s1_x4_0), 1bv32);
    }
    else{
        if((((((bule.bv32(s1_x1_0, s1_x2_0)) && (bule.bv32(s1_x1_0, s1_x3_0))) && (bule.bv32(s1_x1_0, s1_x4_0))) && (buge.bv32(s1_x3_0, s1_x2_0))) && (buge.bv32(s1_x3_0, s1_x4_0))) || (((((bule.bv32(s1_x3_0, s1_x1_0)) && (bule.bv32(s1_x3_0, s1_x2_0))) && (bule.bv32(s1_x3_0, s1_x4_0))) && (buge.bv32(s1_x1_0, s1_x2_0))) && (buge.bv32(s1_x1_0, s1_x4_0)))){
            s1_y_0 := shr.bv32(add.bv32(s1_x2_0, s1_x4_0), 1bv32);
        }
        else{
            if((((((bule.bv32(s1_x1_0, s1_x2_0)) && (bule.bv32(s1_x1_0, s1_x3_0))) && (bule.bv32(s1_x1_0, s1_x4_0))) && (buge.bv32(s1_x4_0, s1_x2_0))) && (buge.bv32(s1_x4_0, s1_x3_0))) || (((((bule.bv32(s1_x4_0, s1_x1_0)) && (bule.bv32(s1_x4_0, s1_x2_0))) && (bule.bv32(s1_x4_0, s1_x3_0))) && (buge.bv32(s1_x1_0, s1_x2_0))) && (buge.bv32(s1_x1_0, s1_x3_0)))){
                s1_y_0 := shr.bv32(add.bv32(s1_x2_0, s1_x3_0), 1bv32);
            }
            else{
                if((((((bule.bv32(s1_x2_0, s1_x1_0)) && (bule.bv32(s1_x2_0, s1_x3_0))) && (bule.bv32(s1_x2_0, s1_x4_0))) && (buge.bv32(s1_x3_0, s1_x1_0))) && (buge.bv32(s1_x3_0, s1_x4_0))) || (((((bule.bv32(s1_x3_0, s1_x1_0)) && (bule.bv32(s1_x3_0, s1_x2_0))) && (bule.bv32(s1_x3_0, s1_x4_0))) && (buge.bv32(s1_x2_0, s1_x1_0))) && (buge.bv32(s1_x2_0, s1_x4_0)))){
                    s1_y_0 := shr.bv32(add.bv32(s1_x1_0, s1_x4_0), 1bv32);
                }
                else{
                    if((((((bule.bv32(s1_x2_0, s1_x1_0)) && (bule.bv32(s1_x2_0, s1_x3_0))) && (bule.bv32(s1_x2_0, s1_x4_0))) && (buge.bv32(s1_x4_0, s1_x1_0))) && (buge.bv32(s1_x4_0, s1_x3_0))) || (((((bule.bv32(s1_x4_0, s1_x1_0)) && (bule.bv32(s1_x4_0, s1_x2_0))) && (bule.bv32(s1_x4_0, s1_x3_0))) && (buge.bv32(s1_x2_0, s1_x1_0))) && (buge.bv32(s1_x2_0, s1_x3_0)))){
                        s1_y_0 := shr.bv32(add.bv32(s1_x1_0, s1_x3_0), 1bv32);
                    }
                    else{
                        s1_y_0 := shr.bv32(add.bv32(s1_x1_0, s1_x2_0), 1bv32);
                    }
                }
            }
        }
    }
    s1_meta.ip_count := s1_y_0;
}
function {:inline true}s1_ingress_ow_counter.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_ow_counter.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_ow_counter, s1_ingress_ow_counter__last0_old_value, s1_ingress_ow_counter__last0_value, s1_ingress_ow_counter__last_index, s1_ingress_ow_counter__last_old_value, s1_ingress_ow_counter__last_value, s1_ingress_ow_counter__last_write_site, s1_ingress_ow_counter__wrote_any, s1_ingress_ow_counter__wrote_index0;
{
    s1_ingress_ow_counter__last_old_value := s1_ingress_ow_counter[s1_index];
    s1_ingress_ow_counter[s1_index] := s1_value;
    s1_ingress_ow_counter__last_index := s1_index;
    s1_ingress_ow_counter__last_value := s1_value;
    s1_ingress_ow_counter__last_write_site := s1_ingress_ow_counter__next_write_site;
    s1_ingress_ow_counter__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_ow_counter__wrote_index0 := true;
        s1_ingress_ow_counter__last0_old_value := s1_ingress_ow_counter__last_old_value;
        s1_ingress_ow_counter__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_pkt_counter.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_pkt_counter.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_pkt_counter, s1_ingress_pkt_counter__last0_old_value, s1_ingress_pkt_counter__last0_value, s1_ingress_pkt_counter__last_index, s1_ingress_pkt_counter__last_old_value, s1_ingress_pkt_counter__last_value, s1_ingress_pkt_counter__last_write_site, s1_ingress_pkt_counter__wrote_any, s1_ingress_pkt_counter__wrote_index0;
{
    s1_ingress_pkt_counter__last_old_value := s1_ingress_pkt_counter[s1_index];
    s1_ingress_pkt_counter[s1_index] := s1_value;
    s1_ingress_pkt_counter__last_index := s1_index;
    s1_ingress_pkt_counter__last_value := s1_value;
    s1_ingress_pkt_counter__last_write_site := s1_ingress_pkt_counter__next_write_site;
    s1_ingress_pkt_counter__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_pkt_counter__wrote_index0 := true;
        s1_ingress_pkt_counter__last0_old_value := s1_ingress_pkt_counter__last_old_value;
        s1_ingress_pkt_counter__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_src_S.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_src_S.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_src_S, s1_ingress_src_S__last0_old_value, s1_ingress_src_S__last0_value, s1_ingress_src_S__last_index, s1_ingress_src_S__last_old_value, s1_ingress_src_S__last_value, s1_ingress_src_S__last_write_site, s1_ingress_src_S__wrote_any, s1_ingress_src_S__wrote_index0;
{
    s1_ingress_src_S__last_old_value := s1_ingress_src_S[s1_index];
    s1_ingress_src_S[s1_index] := s1_value;
    s1_ingress_src_S__last_index := s1_index;
    s1_ingress_src_S__last_value := s1_value;
    s1_ingress_src_S__last_write_site := s1_ingress_src_S__next_write_site;
    s1_ingress_src_S__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_src_S__wrote_index0 := true;
        s1_ingress_src_S__last0_old_value := s1_ingress_src_S__last_old_value;
        s1_ingress_src_S__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_src_cs1.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_src_cs1.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_src_cs1, s1_ingress_src_cs1__last0_old_value, s1_ingress_src_cs1__last0_value, s1_ingress_src_cs1__last_index, s1_ingress_src_cs1__last_old_value, s1_ingress_src_cs1__last_value, s1_ingress_src_cs1__last_write_site, s1_ingress_src_cs1__wrote_any, s1_ingress_src_cs1__wrote_index0;
{
    s1_ingress_src_cs1__last_old_value := s1_ingress_src_cs1[s1_index];
    s1_ingress_src_cs1[s1_index] := s1_value;
    s1_ingress_src_cs1__last_index := s1_index;
    s1_ingress_src_cs1__last_value := s1_value;
    s1_ingress_src_cs1__last_write_site := s1_ingress_src_cs1__next_write_site;
    s1_ingress_src_cs1__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_src_cs1__wrote_index0 := true;
        s1_ingress_src_cs1__last0_old_value := s1_ingress_src_cs1__last_old_value;
        s1_ingress_src_cs1__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_src_cs1_ow.read(s1_reg:[bv32]bv8, s1_index:bv32)returns (bv8) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_src_cs1_ow.write(s1_index:bv32, s1_value:bv8)
	modifies s1_ingress_src_cs1_ow, s1_ingress_src_cs1_ow__last0_old_value, s1_ingress_src_cs1_ow__last0_value, s1_ingress_src_cs1_ow__last_index, s1_ingress_src_cs1_ow__last_old_value, s1_ingress_src_cs1_ow__last_value, s1_ingress_src_cs1_ow__last_write_site, s1_ingress_src_cs1_ow__wrote_any, s1_ingress_src_cs1_ow__wrote_index0;
{
    s1_ingress_src_cs1_ow__last_old_value := s1_ingress_src_cs1_ow[s1_index];
    s1_ingress_src_cs1_ow[s1_index] := s1_value;
    s1_ingress_src_cs1_ow__last_index := s1_index;
    s1_ingress_src_cs1_ow__last_value := s1_value;
    s1_ingress_src_cs1_ow__last_write_site := s1_ingress_src_cs1_ow__next_write_site;
    s1_ingress_src_cs1_ow__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_src_cs1_ow__wrote_index0 := true;
        s1_ingress_src_cs1_ow__last0_old_value := s1_ingress_src_cs1_ow__last_old_value;
        s1_ingress_src_cs1_ow__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_src_cs2.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_src_cs2.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_src_cs2, s1_ingress_src_cs2__last0_old_value, s1_ingress_src_cs2__last0_value, s1_ingress_src_cs2__last_index, s1_ingress_src_cs2__last_old_value, s1_ingress_src_cs2__last_value, s1_ingress_src_cs2__last_write_site, s1_ingress_src_cs2__wrote_any, s1_ingress_src_cs2__wrote_index0;
{
    s1_ingress_src_cs2__last_old_value := s1_ingress_src_cs2[s1_index];
    s1_ingress_src_cs2[s1_index] := s1_value;
    s1_ingress_src_cs2__last_index := s1_index;
    s1_ingress_src_cs2__last_value := s1_value;
    s1_ingress_src_cs2__last_write_site := s1_ingress_src_cs2__next_write_site;
    s1_ingress_src_cs2__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_src_cs2__wrote_index0 := true;
        s1_ingress_src_cs2__last0_old_value := s1_ingress_src_cs2__last_old_value;
        s1_ingress_src_cs2__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_src_cs2_ow.read(s1_reg:[bv32]bv8, s1_index:bv32)returns (bv8) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_src_cs2_ow.write(s1_index:bv32, s1_value:bv8)
	modifies s1_ingress_src_cs2_ow, s1_ingress_src_cs2_ow__last0_old_value, s1_ingress_src_cs2_ow__last0_value, s1_ingress_src_cs2_ow__last_index, s1_ingress_src_cs2_ow__last_old_value, s1_ingress_src_cs2_ow__last_value, s1_ingress_src_cs2_ow__last_write_site, s1_ingress_src_cs2_ow__wrote_any, s1_ingress_src_cs2_ow__wrote_index0;
{
    s1_ingress_src_cs2_ow__last_old_value := s1_ingress_src_cs2_ow[s1_index];
    s1_ingress_src_cs2_ow[s1_index] := s1_value;
    s1_ingress_src_cs2_ow__last_index := s1_index;
    s1_ingress_src_cs2_ow__last_value := s1_value;
    s1_ingress_src_cs2_ow__last_write_site := s1_ingress_src_cs2_ow__next_write_site;
    s1_ingress_src_cs2_ow__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_src_cs2_ow__wrote_index0 := true;
        s1_ingress_src_cs2_ow__last0_old_value := s1_ingress_src_cs2_ow__last_old_value;
        s1_ingress_src_cs2_ow__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_src_cs3.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_src_cs3.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_src_cs3, s1_ingress_src_cs3__last0_old_value, s1_ingress_src_cs3__last0_value, s1_ingress_src_cs3__last_index, s1_ingress_src_cs3__last_old_value, s1_ingress_src_cs3__last_value, s1_ingress_src_cs3__last_write_site, s1_ingress_src_cs3__wrote_any, s1_ingress_src_cs3__wrote_index0;
{
    s1_ingress_src_cs3__last_old_value := s1_ingress_src_cs3[s1_index];
    s1_ingress_src_cs3[s1_index] := s1_value;
    s1_ingress_src_cs3__last_index := s1_index;
    s1_ingress_src_cs3__last_value := s1_value;
    s1_ingress_src_cs3__last_write_site := s1_ingress_src_cs3__next_write_site;
    s1_ingress_src_cs3__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_src_cs3__wrote_index0 := true;
        s1_ingress_src_cs3__last0_old_value := s1_ingress_src_cs3__last_old_value;
        s1_ingress_src_cs3__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_src_cs3_ow.read(s1_reg:[bv32]bv8, s1_index:bv32)returns (bv8) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_src_cs3_ow.write(s1_index:bv32, s1_value:bv8)
	modifies s1_ingress_src_cs3_ow, s1_ingress_src_cs3_ow__last0_old_value, s1_ingress_src_cs3_ow__last0_value, s1_ingress_src_cs3_ow__last_index, s1_ingress_src_cs3_ow__last_old_value, s1_ingress_src_cs3_ow__last_value, s1_ingress_src_cs3_ow__last_write_site, s1_ingress_src_cs3_ow__wrote_any, s1_ingress_src_cs3_ow__wrote_index0;
{
    s1_ingress_src_cs3_ow__last_old_value := s1_ingress_src_cs3_ow[s1_index];
    s1_ingress_src_cs3_ow[s1_index] := s1_value;
    s1_ingress_src_cs3_ow__last_index := s1_index;
    s1_ingress_src_cs3_ow__last_value := s1_value;
    s1_ingress_src_cs3_ow__last_write_site := s1_ingress_src_cs3_ow__next_write_site;
    s1_ingress_src_cs3_ow__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_src_cs3_ow__wrote_index0 := true;
        s1_ingress_src_cs3_ow__last0_old_value := s1_ingress_src_cs3_ow__last_old_value;
        s1_ingress_src_cs3_ow__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_src_cs4.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_src_cs4.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_src_cs4, s1_ingress_src_cs4__last0_old_value, s1_ingress_src_cs4__last0_value, s1_ingress_src_cs4__last_index, s1_ingress_src_cs4__last_old_value, s1_ingress_src_cs4__last_value, s1_ingress_src_cs4__last_write_site, s1_ingress_src_cs4__wrote_any, s1_ingress_src_cs4__wrote_index0;
{
    s1_ingress_src_cs4__last_old_value := s1_ingress_src_cs4[s1_index];
    s1_ingress_src_cs4[s1_index] := s1_value;
    s1_ingress_src_cs4__last_index := s1_index;
    s1_ingress_src_cs4__last_value := s1_value;
    s1_ingress_src_cs4__last_write_site := s1_ingress_src_cs4__next_write_site;
    s1_ingress_src_cs4__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_src_cs4__wrote_index0 := true;
        s1_ingress_src_cs4__last0_old_value := s1_ingress_src_cs4__last_old_value;
        s1_ingress_src_cs4__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_src_cs4_ow.read(s1_reg:[bv32]bv8, s1_index:bv32)returns (bv8) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_src_cs4_ow.write(s1_index:bv32, s1_value:bv8)
	modifies s1_ingress_src_cs4_ow, s1_ingress_src_cs4_ow__last0_old_value, s1_ingress_src_cs4_ow__last0_value, s1_ingress_src_cs4_ow__last_index, s1_ingress_src_cs4_ow__last_old_value, s1_ingress_src_cs4_ow__last_value, s1_ingress_src_cs4_ow__last_write_site, s1_ingress_src_cs4_ow__wrote_any, s1_ingress_src_cs4_ow__wrote_index0;
{
    s1_ingress_src_cs4_ow__last_old_value := s1_ingress_src_cs4_ow[s1_index];
    s1_ingress_src_cs4_ow[s1_index] := s1_value;
    s1_ingress_src_cs4_ow__last_index := s1_index;
    s1_ingress_src_cs4_ow__last_value := s1_value;
    s1_ingress_src_cs4_ow__last_write_site := s1_ingress_src_cs4_ow__next_write_site;
    s1_ingress_src_cs4_ow__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_src_cs4_ow__wrote_index0 := true;
        s1_ingress_src_cs4_ow__last0_old_value := s1_ingress_src_cs4_ow__last_old_value;
        s1_ingress_src_cs4_ow__last0_value := s1_value;
    }
}

// s1_Table s1_ingress_src_entropy_term
procedure {:inline 1} s1_ingress_src_entropy_term.apply()
	modifies s1_ingress_src_entropy_term.action_run, s1_ingress_src_entropy_term.hit, s1_meta.entropy_term, s1_meta.ip_count;
{
    s1_meta.ip_count := s1_meta.ip_count;
    s1_ingress_src_entropy_term.hit := false;
    goto s1_action_ingress_get_entropy_term;

    s1_action_ingress_get_entropy_term:
    assume s1_ingress_src_entropy_term.action_run == s1_ingress_src_entropy_term.action.ingress_get_entropy_term;
    call s1_ingress_get_entropy_term(s1_ingress_src_entropy_term.ingress_get_entropy_term.entropy_term_1);
    goto s1_Exit;

    s1_Exit:
}
function {:inline true}s1_ingress_src_ewma.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_src_ewma.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_src_ewma, s1_ingress_src_ewma__last0_old_value, s1_ingress_src_ewma__last0_value, s1_ingress_src_ewma__last_index, s1_ingress_src_ewma__last_old_value, s1_ingress_src_ewma__last_value, s1_ingress_src_ewma__last_write_site, s1_ingress_src_ewma__wrote_any, s1_ingress_src_ewma__wrote_index0;
{
    s1_ingress_src_ewma__last_old_value := s1_ingress_src_ewma[s1_index];
    s1_ingress_src_ewma[s1_index] := s1_value;
    s1_ingress_src_ewma__last_index := s1_index;
    s1_ingress_src_ewma__last_value := s1_value;
    s1_ingress_src_ewma__last_write_site := s1_ingress_src_ewma__next_write_site;
    s1_ingress_src_ewma__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_src_ewma__wrote_index0 := true;
        s1_ingress_src_ewma__last0_old_value := s1_ingress_src_ewma__last_old_value;
        s1_ingress_src_ewma__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_src_ewmmd.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_src_ewmmd.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_src_ewmmd, s1_ingress_src_ewmmd__last0_old_value, s1_ingress_src_ewmmd__last0_value, s1_ingress_src_ewmmd__last_index, s1_ingress_src_ewmmd__last_old_value, s1_ingress_src_ewmmd__last_value, s1_ingress_src_ewmmd__last_write_site, s1_ingress_src_ewmmd__wrote_any, s1_ingress_src_ewmmd__wrote_index0;
{
    s1_ingress_src_ewmmd__last_old_value := s1_ingress_src_ewmmd[s1_index];
    s1_ingress_src_ewmmd[s1_index] := s1_value;
    s1_ingress_src_ewmmd__last_index := s1_index;
    s1_ingress_src_ewmmd__last_value := s1_value;
    s1_ingress_src_ewmmd__last_write_site := s1_ingress_src_ewmmd__next_write_site;
    s1_ingress_src_ewmmd__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_src_ewmmd__wrote_index0 := true;
        s1_ingress_src_ewmmd__last0_old_value := s1_ingress_src_ewmmd__last_old_value;
        s1_ingress_src_ewmmd__last0_value := s1_value;
    }
}
function {:inline true}s1_ingress_training_len.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_ingress_training_len.write(s1_index:bv32, s1_value:bv32)
	modifies s1_ingress_training_len, s1_ingress_training_len__last0_old_value, s1_ingress_training_len__last0_value, s1_ingress_training_len__last_index, s1_ingress_training_len__last_old_value, s1_ingress_training_len__last_value, s1_ingress_training_len__last_write_site, s1_ingress_training_len__wrote_any, s1_ingress_training_len__wrote_index0;
{
    s1_ingress_training_len__last_old_value := s1_ingress_training_len[s1_index];
    s1_ingress_training_len[s1_index] := s1_value;
    s1_ingress_training_len__last_index := s1_index;
    s1_ingress_training_len__last_value := s1_value;
    s1_ingress_training_len__last_write_site := s1_ingress_training_len__next_write_site;
    s1_ingress_training_len__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ingress_training_len__wrote_index0 := true;
        s1_ingress_training_len__last0_old_value := s1_ingress_training_len__last_old_value;
        s1_ingress_training_len__last0_value := s1_value;
    }
}
procedure {:inline 1} s1_main()
	modifies s1_alpha_aux_0, s1_current_ow_0, s1_drop, s1_dst_S_aux_0, s1_dst_c1_0, s1_dst_c2_0, s1_dst_c3_0, s1_dst_c4_0, s1_dst_cs1_ow_aux_0, s1_dst_cs2_ow_aux_0, s1_dst_cs3_ow_aux_0, s1_dst_cs4_ow_aux_0, s1_dst_g1_0, s1_dst_g2_0, s1_dst_g3_0, s1_dst_g4_0, s1_dst_h1_0, s1_dst_h2_0, s1_dst_h3_0, s1_dst_h4_0, s1_dst_thresh_0, s1_forward, s1_g1_0, s1_g1_2, s1_g2_0, s1_g2_2, s1_g3_0, s1_g3_2, s1_g4_0, s1_g4_2, s1_h1_0, s1_h1_2, s1_h2_0, s1_h2_2, s1_h3_0, s1_h3_2, s1_h4_0, s1_h4_2, s1_hdr.ddosd.alarm, s1_hdr.ddosd.dst_entropy, s1_hdr.ddosd.dst_ewma, s1_hdr.ddosd.dst_ewmmd, s1_hdr.ddosd.ether_type, s1_hdr.ddosd.pkt_num, s1_hdr.ddosd.src_entropy, s1_hdr.ddosd.src_ewma, s1_hdr.ddosd.src_ewmmd, s1_hdr.ethernet.ether_type, s1_hdr.ipv4.dst_addr, s1_hdr.ipv4.hdr_checksum, s1_idx_0, s1_ingress_dst_S, s1_ingress_dst_S__last0_old_value, s1_ingress_dst_S__last0_value, s1_ingress_dst_S__last_index, s1_ingress_dst_S__last_old_value, s1_ingress_dst_S__last_value, s1_ingress_dst_S__last_write_site, s1_ingress_dst_S__next_write_site, s1_ingress_dst_S__wrote_any, s1_ingress_dst_S__wrote_index0, s1_ingress_dst_cs1, s1_ingress_dst_cs1__last0_old_value, s1_ingress_dst_cs1__last0_value, s1_ingress_dst_cs1__last_index, s1_ingress_dst_cs1__last_old_value, s1_ingress_dst_cs1__last_value, s1_ingress_dst_cs1__last_write_site, s1_ingress_dst_cs1__next_write_site, s1_ingress_dst_cs1__wrote_any, s1_ingress_dst_cs1__wrote_index0, s1_ingress_dst_cs1_ow, s1_ingress_dst_cs1_ow__last0_old_value, s1_ingress_dst_cs1_ow__last0_value, s1_ingress_dst_cs1_ow__last_index, s1_ingress_dst_cs1_ow__last_old_value, s1_ingress_dst_cs1_ow__last_value, s1_ingress_dst_cs1_ow__last_write_site, s1_ingress_dst_cs1_ow__next_write_site, s1_ingress_dst_cs1_ow__wrote_any, s1_ingress_dst_cs1_ow__wrote_index0, s1_ingress_dst_cs2, s1_ingress_dst_cs2__last0_old_value, s1_ingress_dst_cs2__last0_value, s1_ingress_dst_cs2__last_index, s1_ingress_dst_cs2__last_old_value, s1_ingress_dst_cs2__last_value, s1_ingress_dst_cs2__last_write_site, s1_ingress_dst_cs2__next_write_site, s1_ingress_dst_cs2__wrote_any, s1_ingress_dst_cs2__wrote_index0, s1_ingress_dst_cs2_ow, s1_ingress_dst_cs2_ow__last0_old_value, s1_ingress_dst_cs2_ow__last0_value, s1_ingress_dst_cs2_ow__last_index, s1_ingress_dst_cs2_ow__last_old_value, s1_ingress_dst_cs2_ow__last_value, s1_ingress_dst_cs2_ow__last_write_site, s1_ingress_dst_cs2_ow__next_write_site, s1_ingress_dst_cs2_ow__wrote_any, s1_ingress_dst_cs2_ow__wrote_index0, s1_ingress_dst_cs3, s1_ingress_dst_cs3__last0_old_value, s1_ingress_dst_cs3__last0_value, s1_ingress_dst_cs3__last_index, s1_ingress_dst_cs3__last_old_value, s1_ingress_dst_cs3__last_value, s1_ingress_dst_cs3__last_write_site, s1_ingress_dst_cs3__next_write_site, s1_ingress_dst_cs3__wrote_any, s1_ingress_dst_cs3__wrote_index0, s1_ingress_dst_cs3_ow, s1_ingress_dst_cs3_ow__last0_old_value, s1_ingress_dst_cs3_ow__last0_value, s1_ingress_dst_cs3_ow__last_index, s1_ingress_dst_cs3_ow__last_old_value, s1_ingress_dst_cs3_ow__last_value, s1_ingress_dst_cs3_ow__last_write_site, s1_ingress_dst_cs3_ow__next_write_site, s1_ingress_dst_cs3_ow__wrote_any, s1_ingress_dst_cs3_ow__wrote_index0, s1_ingress_dst_cs4, s1_ingress_dst_cs4__last0_old_value, s1_ingress_dst_cs4__last0_value, s1_ingress_dst_cs4__last_index, s1_ingress_dst_cs4__last_old_value, s1_ingress_dst_cs4__last_value, s1_ingress_dst_cs4__last_write_site, s1_ingress_dst_cs4__next_write_site, s1_ingress_dst_cs4__wrote_any, s1_ingress_dst_cs4__wrote_index0, s1_ingress_dst_cs4_ow, s1_ingress_dst_cs4_ow__last0_old_value, s1_ingress_dst_cs4_ow__last0_value, s1_ingress_dst_cs4_ow__last_index, s1_ingress_dst_cs4_ow__last_old_value, s1_ingress_dst_cs4_ow__last_value, s1_ingress_dst_cs4_ow__last_write_site, s1_ingress_dst_cs4_ow__next_write_site, s1_ingress_dst_cs4_ow__wrote_any, s1_ingress_dst_cs4_ow__wrote_index0, s1_ingress_dst_entropy_term.action_run, s1_ingress_dst_entropy_term.hit, s1_ingress_dst_ewma, s1_ingress_dst_ewma__last0_old_value, s1_ingress_dst_ewma__last0_value, s1_ingress_dst_ewma__last_index, s1_ingress_dst_ewma__last_old_value, s1_ingress_dst_ewma__last_value, s1_ingress_dst_ewma__last_write_site, s1_ingress_dst_ewma__next_write_site, s1_ingress_dst_ewma__wrote_any, s1_ingress_dst_ewma__wrote_index0, s1_ingress_dst_ewmmd, s1_ingress_dst_ewmmd__last0_old_value, s1_ingress_dst_ewmmd__last0_value, s1_ingress_dst_ewmmd__last_index, s1_ingress_dst_ewmmd__last_old_value, s1_ingress_dst_ewmmd__last_value, s1_ingress_dst_ewmmd__last_write_site, s1_ingress_dst_ewmmd__next_write_site, s1_ingress_dst_ewmmd__wrote_any, s1_ingress_dst_ewmmd__wrote_index0, s1_ingress_ipv4_fib.action_run, s1_ingress_ipv4_fib.hit, s1_ingress_ipv4_fib.ingress_forward.egress_port_1, s1_ingress_ow_counter, s1_ingress_ow_counter__last0_old_value, s1_ingress_ow_counter__last0_value, s1_ingress_ow_counter__last_index, s1_ingress_ow_counter__last_old_value, s1_ingress_ow_counter__last_value, s1_ingress_ow_counter__last_write_site, s1_ingress_ow_counter__next_write_site, s1_ingress_ow_counter__wrote_any, s1_ingress_ow_counter__wrote_index0, s1_ingress_pkt_counter, s1_ingress_pkt_counter__last0_old_value, s1_ingress_pkt_counter__last0_value, s1_ingress_pkt_counter__last_index, s1_ingress_pkt_counter__last_old_value, s1_ingress_pkt_counter__last_value, s1_ingress_pkt_counter__last_write_site, s1_ingress_pkt_counter__next_write_site, s1_ingress_pkt_counter__wrote_any, s1_ingress_pkt_counter__wrote_index0, s1_ingress_src_S, s1_ingress_src_S__last0_old_value, s1_ingress_src_S__last0_value, s1_ingress_src_S__last_index, s1_ingress_src_S__last_old_value, s1_ingress_src_S__last_value, s1_ingress_src_S__last_write_site, s1_ingress_src_S__next_write_site, s1_ingress_src_S__wrote_any, s1_ingress_src_S__wrote_index0, s1_ingress_src_cs1, s1_ingress_src_cs1__last0_old_value, s1_ingress_src_cs1__last0_value, s1_ingress_src_cs1__last_index, s1_ingress_src_cs1__last_old_value, s1_ingress_src_cs1__last_value, s1_ingress_src_cs1__last_write_site, s1_ingress_src_cs1__next_write_site, s1_ingress_src_cs1__wrote_any, s1_ingress_src_cs1__wrote_index0, s1_ingress_src_cs1_ow, s1_ingress_src_cs1_ow__last0_old_value, s1_ingress_src_cs1_ow__last0_value, s1_ingress_src_cs1_ow__last_index, s1_ingress_src_cs1_ow__last_old_value, s1_ingress_src_cs1_ow__last_value, s1_ingress_src_cs1_ow__last_write_site, s1_ingress_src_cs1_ow__next_write_site, s1_ingress_src_cs1_ow__wrote_any, s1_ingress_src_cs1_ow__wrote_index0, s1_ingress_src_cs2, s1_ingress_src_cs2__last0_old_value, s1_ingress_src_cs2__last0_value, s1_ingress_src_cs2__last_index, s1_ingress_src_cs2__last_old_value, s1_ingress_src_cs2__last_value, s1_ingress_src_cs2__last_write_site, s1_ingress_src_cs2__next_write_site, s1_ingress_src_cs2__wrote_any, s1_ingress_src_cs2__wrote_index0, s1_ingress_src_cs2_ow, s1_ingress_src_cs2_ow__last0_old_value, s1_ingress_src_cs2_ow__last0_value, s1_ingress_src_cs2_ow__last_index, s1_ingress_src_cs2_ow__last_old_value, s1_ingress_src_cs2_ow__last_value, s1_ingress_src_cs2_ow__last_write_site, s1_ingress_src_cs2_ow__next_write_site, s1_ingress_src_cs2_ow__wrote_any, s1_ingress_src_cs2_ow__wrote_index0, s1_ingress_src_cs3, s1_ingress_src_cs3__last0_old_value, s1_ingress_src_cs3__last0_value, s1_ingress_src_cs3__last_index, s1_ingress_src_cs3__last_old_value, s1_ingress_src_cs3__last_value, s1_ingress_src_cs3__last_write_site, s1_ingress_src_cs3__next_write_site, s1_ingress_src_cs3__wrote_any, s1_ingress_src_cs3__wrote_index0, s1_ingress_src_cs3_ow, s1_ingress_src_cs3_ow__last0_old_value, s1_ingress_src_cs3_ow__last0_value, s1_ingress_src_cs3_ow__last_index, s1_ingress_src_cs3_ow__last_old_value, s1_ingress_src_cs3_ow__last_value, s1_ingress_src_cs3_ow__last_write_site, s1_ingress_src_cs3_ow__next_write_site, s1_ingress_src_cs3_ow__wrote_any, s1_ingress_src_cs3_ow__wrote_index0, s1_ingress_src_cs4, s1_ingress_src_cs4__last0_old_value, s1_ingress_src_cs4__last0_value, s1_ingress_src_cs4__last_index, s1_ingress_src_cs4__last_old_value, s1_ingress_src_cs4__last_value, s1_ingress_src_cs4__last_write_site, s1_ingress_src_cs4__next_write_site, s1_ingress_src_cs4__wrote_any, s1_ingress_src_cs4__wrote_index0, s1_ingress_src_cs4_ow, s1_ingress_src_cs4_ow__last0_old_value, s1_ingress_src_cs4_ow__last0_value, s1_ingress_src_cs4_ow__last_index, s1_ingress_src_cs4_ow__last_old_value, s1_ingress_src_cs4_ow__last_value, s1_ingress_src_cs4_ow__last_write_site, s1_ingress_src_cs4_ow__next_write_site, s1_ingress_src_cs4_ow__wrote_any, s1_ingress_src_cs4_ow__wrote_index0, s1_ingress_src_entropy_term.action_run, s1_ingress_src_entropy_term.hit, s1_ingress_src_ewma, s1_ingress_src_ewma__last0_old_value, s1_ingress_src_ewma__last0_value, s1_ingress_src_ewma__last_index, s1_ingress_src_ewma__last_old_value, s1_ingress_src_ewma__last_value, s1_ingress_src_ewma__last_write_site, s1_ingress_src_ewma__next_write_site, s1_ingress_src_ewma__wrote_any, s1_ingress_src_ewma__wrote_index0, s1_ingress_src_ewmmd, s1_ingress_src_ewmmd__last0_old_value, s1_ingress_src_ewmmd__last0_value, s1_ingress_src_ewmmd__last_index, s1_ingress_src_ewmmd__last_old_value, s1_ingress_src_ewmmd__last_value, s1_ingress_src_ewmmd__last_write_site, s1_ingress_src_ewmmd__next_write_site, s1_ingress_src_ewmmd__wrote_any, s1_ingress_src_ewmmd__wrote_index0, s1_ipv4_addr_0, s1_ipv4_addr_1, s1_isValid, s1_k_aux_0, s1_log2_m_aux_0, s1_m_0, s1_meta.alarm, s1_meta.dst_entropy, s1_meta.dst_ewma, s1_meta.dst_ewmmd, s1_meta.entropy_term, s1_meta.ip_count, s1_meta.pkt_num, s1_meta.src_entropy, s1_meta.src_ewma, s1_meta.src_ewmmd, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_i2e, s1_src_S_aux_0, s1_src_c1_0, s1_src_c2_0, s1_src_c3_0, s1_src_c4_0, s1_src_cs1_ow_aux_0, s1_src_cs2_ow_aux_0, s1_src_cs3_ow_aux_0, s1_src_cs4_ow_aux_0, s1_src_g1_0, s1_src_g2_0, s1_src_g3_0, s1_src_g4_0, s1_src_h1_0, s1_src_h2_0, s1_src_h3_0, s1_src_h4_0, s1_src_thresh_0, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_training_len_aux_0, s1_x1_0, s1_x1_2, s1_x2_0, s1_x2_2, s1_x3_0, s1_x3_2, s1_x4_0, s1_x4_2, s1_y_0, s1_y_2;
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
	modifies s1_alpha_aux_0, s1_current_ow_0, s1_drop, s1_dst_S_aux_0, s1_dst_c1_0, s1_dst_c2_0, s1_dst_c3_0, s1_dst_c4_0, s1_dst_cs1_ow_aux_0, s1_dst_cs2_ow_aux_0, s1_dst_cs3_ow_aux_0, s1_dst_cs4_ow_aux_0, s1_dst_g1_0, s1_dst_g2_0, s1_dst_g3_0, s1_dst_g4_0, s1_dst_h1_0, s1_dst_h2_0, s1_dst_h3_0, s1_dst_h4_0, s1_dst_thresh_0, s1_forward, s1_g1_0, s1_g1_2, s1_g2_0, s1_g2_2, s1_g3_0, s1_g3_2, s1_g4_0, s1_g4_2, s1_h1_0, s1_h1_2, s1_h2_0, s1_h2_2, s1_h3_0, s1_h3_2, s1_h4_0, s1_h4_2, s1_hdr.ddosd.alarm, s1_hdr.ddosd.dst_entropy, s1_hdr.ddosd.dst_ewma, s1_hdr.ddosd.dst_ewmmd, s1_hdr.ddosd.ether_type, s1_hdr.ddosd.pkt_num, s1_hdr.ddosd.src_entropy, s1_hdr.ddosd.src_ewma, s1_hdr.ddosd.src_ewmmd, s1_hdr.ethernet.ether_type, s1_hdr.ipv4.dst_addr, s1_hdr.ipv4.hdr_checksum, s1_idx_0, s1_ingress_dst_S, s1_ingress_dst_S__last0_old_value, s1_ingress_dst_S__last0_value, s1_ingress_dst_S__last_index, s1_ingress_dst_S__last_old_value, s1_ingress_dst_S__last_value, s1_ingress_dst_S__last_write_site, s1_ingress_dst_S__next_write_site, s1_ingress_dst_S__wrote_any, s1_ingress_dst_S__wrote_index0, s1_ingress_dst_cs1, s1_ingress_dst_cs1__last0_old_value, s1_ingress_dst_cs1__last0_value, s1_ingress_dst_cs1__last_index, s1_ingress_dst_cs1__last_old_value, s1_ingress_dst_cs1__last_value, s1_ingress_dst_cs1__last_write_site, s1_ingress_dst_cs1__next_write_site, s1_ingress_dst_cs1__wrote_any, s1_ingress_dst_cs1__wrote_index0, s1_ingress_dst_cs1_ow, s1_ingress_dst_cs1_ow__last0_old_value, s1_ingress_dst_cs1_ow__last0_value, s1_ingress_dst_cs1_ow__last_index, s1_ingress_dst_cs1_ow__last_old_value, s1_ingress_dst_cs1_ow__last_value, s1_ingress_dst_cs1_ow__last_write_site, s1_ingress_dst_cs1_ow__next_write_site, s1_ingress_dst_cs1_ow__wrote_any, s1_ingress_dst_cs1_ow__wrote_index0, s1_ingress_dst_cs2, s1_ingress_dst_cs2__last0_old_value, s1_ingress_dst_cs2__last0_value, s1_ingress_dst_cs2__last_index, s1_ingress_dst_cs2__last_old_value, s1_ingress_dst_cs2__last_value, s1_ingress_dst_cs2__last_write_site, s1_ingress_dst_cs2__next_write_site, s1_ingress_dst_cs2__wrote_any, s1_ingress_dst_cs2__wrote_index0, s1_ingress_dst_cs2_ow, s1_ingress_dst_cs2_ow__last0_old_value, s1_ingress_dst_cs2_ow__last0_value, s1_ingress_dst_cs2_ow__last_index, s1_ingress_dst_cs2_ow__last_old_value, s1_ingress_dst_cs2_ow__last_value, s1_ingress_dst_cs2_ow__last_write_site, s1_ingress_dst_cs2_ow__next_write_site, s1_ingress_dst_cs2_ow__wrote_any, s1_ingress_dst_cs2_ow__wrote_index0, s1_ingress_dst_cs3, s1_ingress_dst_cs3__last0_old_value, s1_ingress_dst_cs3__last0_value, s1_ingress_dst_cs3__last_index, s1_ingress_dst_cs3__last_old_value, s1_ingress_dst_cs3__last_value, s1_ingress_dst_cs3__last_write_site, s1_ingress_dst_cs3__next_write_site, s1_ingress_dst_cs3__wrote_any, s1_ingress_dst_cs3__wrote_index0, s1_ingress_dst_cs3_ow, s1_ingress_dst_cs3_ow__last0_old_value, s1_ingress_dst_cs3_ow__last0_value, s1_ingress_dst_cs3_ow__last_index, s1_ingress_dst_cs3_ow__last_old_value, s1_ingress_dst_cs3_ow__last_value, s1_ingress_dst_cs3_ow__last_write_site, s1_ingress_dst_cs3_ow__next_write_site, s1_ingress_dst_cs3_ow__wrote_any, s1_ingress_dst_cs3_ow__wrote_index0, s1_ingress_dst_cs4, s1_ingress_dst_cs4__last0_old_value, s1_ingress_dst_cs4__last0_value, s1_ingress_dst_cs4__last_index, s1_ingress_dst_cs4__last_old_value, s1_ingress_dst_cs4__last_value, s1_ingress_dst_cs4__last_write_site, s1_ingress_dst_cs4__next_write_site, s1_ingress_dst_cs4__wrote_any, s1_ingress_dst_cs4__wrote_index0, s1_ingress_dst_cs4_ow, s1_ingress_dst_cs4_ow__last0_old_value, s1_ingress_dst_cs4_ow__last0_value, s1_ingress_dst_cs4_ow__last_index, s1_ingress_dst_cs4_ow__last_old_value, s1_ingress_dst_cs4_ow__last_value, s1_ingress_dst_cs4_ow__last_write_site, s1_ingress_dst_cs4_ow__next_write_site, s1_ingress_dst_cs4_ow__wrote_any, s1_ingress_dst_cs4_ow__wrote_index0, s1_ingress_dst_entropy_term.action_run, s1_ingress_dst_entropy_term.hit, s1_ingress_dst_ewma, s1_ingress_dst_ewma__last0_old_value, s1_ingress_dst_ewma__last0_value, s1_ingress_dst_ewma__last_index, s1_ingress_dst_ewma__last_old_value, s1_ingress_dst_ewma__last_value, s1_ingress_dst_ewma__last_write_site, s1_ingress_dst_ewma__next_write_site, s1_ingress_dst_ewma__wrote_any, s1_ingress_dst_ewma__wrote_index0, s1_ingress_dst_ewmmd, s1_ingress_dst_ewmmd__last0_old_value, s1_ingress_dst_ewmmd__last0_value, s1_ingress_dst_ewmmd__last_index, s1_ingress_dst_ewmmd__last_old_value, s1_ingress_dst_ewmmd__last_value, s1_ingress_dst_ewmmd__last_write_site, s1_ingress_dst_ewmmd__next_write_site, s1_ingress_dst_ewmmd__wrote_any, s1_ingress_dst_ewmmd__wrote_index0, s1_ingress_ipv4_fib.action_run, s1_ingress_ipv4_fib.hit, s1_ingress_ipv4_fib.ingress_forward.egress_port_1, s1_ingress_ow_counter, s1_ingress_ow_counter__last0_old_value, s1_ingress_ow_counter__last0_value, s1_ingress_ow_counter__last_index, s1_ingress_ow_counter__last_old_value, s1_ingress_ow_counter__last_value, s1_ingress_ow_counter__last_write_site, s1_ingress_ow_counter__next_write_site, s1_ingress_ow_counter__wrote_any, s1_ingress_ow_counter__wrote_index0, s1_ingress_pkt_counter, s1_ingress_pkt_counter__last0_old_value, s1_ingress_pkt_counter__last0_value, s1_ingress_pkt_counter__last_index, s1_ingress_pkt_counter__last_old_value, s1_ingress_pkt_counter__last_value, s1_ingress_pkt_counter__last_write_site, s1_ingress_pkt_counter__next_write_site, s1_ingress_pkt_counter__wrote_any, s1_ingress_pkt_counter__wrote_index0, s1_ingress_src_S, s1_ingress_src_S__last0_old_value, s1_ingress_src_S__last0_value, s1_ingress_src_S__last_index, s1_ingress_src_S__last_old_value, s1_ingress_src_S__last_value, s1_ingress_src_S__last_write_site, s1_ingress_src_S__next_write_site, s1_ingress_src_S__wrote_any, s1_ingress_src_S__wrote_index0, s1_ingress_src_cs1, s1_ingress_src_cs1__last0_old_value, s1_ingress_src_cs1__last0_value, s1_ingress_src_cs1__last_index, s1_ingress_src_cs1__last_old_value, s1_ingress_src_cs1__last_value, s1_ingress_src_cs1__last_write_site, s1_ingress_src_cs1__next_write_site, s1_ingress_src_cs1__wrote_any, s1_ingress_src_cs1__wrote_index0, s1_ingress_src_cs1_ow, s1_ingress_src_cs1_ow__last0_old_value, s1_ingress_src_cs1_ow__last0_value, s1_ingress_src_cs1_ow__last_index, s1_ingress_src_cs1_ow__last_old_value, s1_ingress_src_cs1_ow__last_value, s1_ingress_src_cs1_ow__last_write_site, s1_ingress_src_cs1_ow__next_write_site, s1_ingress_src_cs1_ow__wrote_any, s1_ingress_src_cs1_ow__wrote_index0, s1_ingress_src_cs2, s1_ingress_src_cs2__last0_old_value, s1_ingress_src_cs2__last0_value, s1_ingress_src_cs2__last_index, s1_ingress_src_cs2__last_old_value, s1_ingress_src_cs2__last_value, s1_ingress_src_cs2__last_write_site, s1_ingress_src_cs2__next_write_site, s1_ingress_src_cs2__wrote_any, s1_ingress_src_cs2__wrote_index0, s1_ingress_src_cs2_ow, s1_ingress_src_cs2_ow__last0_old_value, s1_ingress_src_cs2_ow__last0_value, s1_ingress_src_cs2_ow__last_index, s1_ingress_src_cs2_ow__last_old_value, s1_ingress_src_cs2_ow__last_value, s1_ingress_src_cs2_ow__last_write_site, s1_ingress_src_cs2_ow__next_write_site, s1_ingress_src_cs2_ow__wrote_any, s1_ingress_src_cs2_ow__wrote_index0, s1_ingress_src_cs3, s1_ingress_src_cs3__last0_old_value, s1_ingress_src_cs3__last0_value, s1_ingress_src_cs3__last_index, s1_ingress_src_cs3__last_old_value, s1_ingress_src_cs3__last_value, s1_ingress_src_cs3__last_write_site, s1_ingress_src_cs3__next_write_site, s1_ingress_src_cs3__wrote_any, s1_ingress_src_cs3__wrote_index0, s1_ingress_src_cs3_ow, s1_ingress_src_cs3_ow__last0_old_value, s1_ingress_src_cs3_ow__last0_value, s1_ingress_src_cs3_ow__last_index, s1_ingress_src_cs3_ow__last_old_value, s1_ingress_src_cs3_ow__last_value, s1_ingress_src_cs3_ow__last_write_site, s1_ingress_src_cs3_ow__next_write_site, s1_ingress_src_cs3_ow__wrote_any, s1_ingress_src_cs3_ow__wrote_index0, s1_ingress_src_cs4, s1_ingress_src_cs4__last0_old_value, s1_ingress_src_cs4__last0_value, s1_ingress_src_cs4__last_index, s1_ingress_src_cs4__last_old_value, s1_ingress_src_cs4__last_value, s1_ingress_src_cs4__last_write_site, s1_ingress_src_cs4__next_write_site, s1_ingress_src_cs4__wrote_any, s1_ingress_src_cs4__wrote_index0, s1_ingress_src_cs4_ow, s1_ingress_src_cs4_ow__last0_old_value, s1_ingress_src_cs4_ow__last0_value, s1_ingress_src_cs4_ow__last_index, s1_ingress_src_cs4_ow__last_old_value, s1_ingress_src_cs4_ow__last_value, s1_ingress_src_cs4_ow__last_write_site, s1_ingress_src_cs4_ow__next_write_site, s1_ingress_src_cs4_ow__wrote_any, s1_ingress_src_cs4_ow__wrote_index0, s1_ingress_src_entropy_term.action_run, s1_ingress_src_entropy_term.hit, s1_ingress_src_ewma, s1_ingress_src_ewma__last0_old_value, s1_ingress_src_ewma__last0_value, s1_ingress_src_ewma__last_index, s1_ingress_src_ewma__last_old_value, s1_ingress_src_ewma__last_value, s1_ingress_src_ewma__last_write_site, s1_ingress_src_ewma__next_write_site, s1_ingress_src_ewma__wrote_any, s1_ingress_src_ewma__wrote_index0, s1_ingress_src_ewmmd, s1_ingress_src_ewmmd__last0_old_value, s1_ingress_src_ewmmd__last0_value, s1_ingress_src_ewmmd__last_index, s1_ingress_src_ewmmd__last_old_value, s1_ingress_src_ewmmd__last_value, s1_ingress_src_ewmmd__last_write_site, s1_ingress_src_ewmmd__next_write_site, s1_ingress_src_ewmmd__wrote_any, s1_ingress_src_ewmmd__wrote_index0, s1_ipv4_addr_0, s1_ipv4_addr_1, s1_isValid, s1_k_aux_0, s1_log2_m_aux_0, s1_m_0, s1_meta.alarm, s1_meta.dst_entropy, s1_meta.dst_ewma, s1_meta.dst_ewmmd, s1_meta.entropy_term, s1_meta.ip_count, s1_meta.pkt_num, s1_meta.src_entropy, s1_meta.src_ewma, s1_meta.src_ewmmd, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_src_S_aux_0, s1_src_c1_0, s1_src_c2_0, s1_src_c3_0, s1_src_c4_0, s1_src_cs1_ow_aux_0, s1_src_cs2_ow_aux_0, s1_src_cs3_ow_aux_0, s1_src_cs4_ow_aux_0, s1_src_g1_0, s1_src_g2_0, s1_src_g3_0, s1_src_g4_0, s1_src_h1_0, s1_src_h2_0, s1_src_h3_0, s1_src_h4_0, s1_src_thresh_0, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_training_len_aux_0, s1_x1_0, s1_x1_2, s1_x2_0, s1_x2_2, s1_x3_0, s1_x3_2, s1_x4_0, s1_x4_2, s1_y_0, s1_y_2;
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

// s1_Action s1_median_1
procedure {:inline 1} s1_median_1()
	modifies s1_meta.ip_count, s1_x1_2, s1_x2_2, s1_x3_2, s1_x4_2, s1_y_2;
{
    s1_x1_2 := s1_dst_c1_0;
    s1_x2_2 := s1_dst_c2_0;
    s1_x3_2 := s1_dst_c3_0;
    s1_x4_2 := s1_dst_c4_0;
    if((((((bule.bv32(s1_x1_2, s1_x2_2)) && (bule.bv32(s1_x1_2, s1_x3_2))) && (bule.bv32(s1_x1_2, s1_x4_2))) && (buge.bv32(s1_x2_2, s1_x3_2))) && (buge.bv32(s1_x2_2, s1_x4_2))) || (((((bule.bv32(s1_x2_2, s1_x1_2)) && (bule.bv32(s1_x2_2, s1_x3_2))) && (bule.bv32(s1_x2_2, s1_x4_2))) && (buge.bv32(s1_x1_2, s1_x3_2))) && (buge.bv32(s1_x1_2, s1_x4_2)))){
        s1_y_2 := shr.bv32(add.bv32(s1_x3_2, s1_x4_2), 1bv32);
    }
    else{
        if((((((bule.bv32(s1_x1_2, s1_x2_2)) && (bule.bv32(s1_x1_2, s1_x3_2))) && (bule.bv32(s1_x1_2, s1_x4_2))) && (buge.bv32(s1_x3_2, s1_x2_2))) && (buge.bv32(s1_x3_2, s1_x4_2))) || (((((bule.bv32(s1_x3_2, s1_x1_2)) && (bule.bv32(s1_x3_2, s1_x2_2))) && (bule.bv32(s1_x3_2, s1_x4_2))) && (buge.bv32(s1_x1_2, s1_x2_2))) && (buge.bv32(s1_x1_2, s1_x4_2)))){
            s1_y_2 := shr.bv32(add.bv32(s1_x2_2, s1_x4_2), 1bv32);
        }
        else{
            if((((((bule.bv32(s1_x1_2, s1_x2_2)) && (bule.bv32(s1_x1_2, s1_x3_2))) && (bule.bv32(s1_x1_2, s1_x4_2))) && (buge.bv32(s1_x4_2, s1_x2_2))) && (buge.bv32(s1_x4_2, s1_x3_2))) || (((((bule.bv32(s1_x4_2, s1_x1_2)) && (bule.bv32(s1_x4_2, s1_x2_2))) && (bule.bv32(s1_x4_2, s1_x3_2))) && (buge.bv32(s1_x1_2, s1_x2_2))) && (buge.bv32(s1_x1_2, s1_x3_2)))){
                s1_y_2 := shr.bv32(add.bv32(s1_x2_2, s1_x3_2), 1bv32);
            }
            else{
                if((((((bule.bv32(s1_x2_2, s1_x1_2)) && (bule.bv32(s1_x2_2, s1_x3_2))) && (bule.bv32(s1_x2_2, s1_x4_2))) && (buge.bv32(s1_x3_2, s1_x1_2))) && (buge.bv32(s1_x3_2, s1_x4_2))) || (((((bule.bv32(s1_x3_2, s1_x1_2)) && (bule.bv32(s1_x3_2, s1_x2_2))) && (bule.bv32(s1_x3_2, s1_x4_2))) && (buge.bv32(s1_x2_2, s1_x1_2))) && (buge.bv32(s1_x2_2, s1_x4_2)))){
                    s1_y_2 := shr.bv32(add.bv32(s1_x1_2, s1_x4_2), 1bv32);
                }
                else{
                    if((((((bule.bv32(s1_x2_2, s1_x1_2)) && (bule.bv32(s1_x2_2, s1_x3_2))) && (bule.bv32(s1_x2_2, s1_x4_2))) && (buge.bv32(s1_x4_2, s1_x1_2))) && (buge.bv32(s1_x4_2, s1_x3_2))) || (((((bule.bv32(s1_x4_2, s1_x1_2)) && (bule.bv32(s1_x4_2, s1_x2_2))) && (bule.bv32(s1_x4_2, s1_x3_2))) && (buge.bv32(s1_x2_2, s1_x1_2))) && (buge.bv32(s1_x2_2, s1_x3_2)))){
                        s1_y_2 := shr.bv32(add.bv32(s1_x1_2, s1_x3_2), 1bv32);
                    }
                    else{
                        s1_y_2 := shr.bv32(add.bv32(s1_x1_2, s1_x2_2), 1bv32);
                    }
                }
            }
        }
    }
    s1_meta.ip_count := s1_y_2;
}
procedure s1_packet_in.extract(s1_header:s1_Ref);
    ensures (s1_isValid[s1_header] == true);
	modifies s1_isValid;
procedure s1_pkt.emit(s1_arg0:s1_Ref);
procedure s1_reject();
    ensures s1_drop==true;
	modifies s1_drop;
procedure {:inline 1} s1_setInvalid(s1_header:s1_Ref);
    ensures (s1_isValid[s1_header] == false);
	modifies s1_isValid;
procedure {:inline 1} s1_setValid(s1_header:s1_Ref);

// s1_Control s1_verifyChecksum
procedure {:inline 1} s1_verifyChecksum()
	modifies s1_p4b_checksum_error, s1_p4b_checksum_verified;
{
    if (true) {
        s1_p4b_checksum_verified := true;
        havoc s1_p4b_checksum_error;
    }
}
// ===== END NODE s1 =====

// ===== BEGIN ENQUEUE PROCEDURES =====
// ===== END ENQUEUE PROCEDURES =====

// ===== BEGIN HARNESS =====
// Auto-generated by Procurator (DSL -> Boogie harness: sequential scheduler)
// Message abstraction: Bag(K=1) using inbox_count per node; single-slot mailbox for packet fields

var procurator_step: int;
var procurator_bad: bool;

var s1_inbox_count: int;
var io_inbox_count: int;

var s1_pkt_external: bool;
var io_pkt_external: bool;

// Host packet fields (mirrors connected node symbols)
var io_standard_metadata.ingress_port: bv9;
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
var io_standard_metadata.parser_error: s1_error;
var io_standard_metadata.priority: bv3;
var io_hdr.ethernet.valid: bool;
var io_hdr.ethernet.dst_addr: bv48;
var io_hdr.ethernet.src_addr: bv48;
var io_hdr.ethernet.ether_type: bv16;
var io_hdr.ddosd.valid: bool;
var io_hdr.ddosd.pkt_num: bv32;
var io_hdr.ddosd.src_entropy: bv32;
var io_hdr.ddosd.src_ewma: bv32;
var io_hdr.ddosd.src_ewmmd: bv32;
var io_hdr.ddosd.dst_entropy: bv32;
var io_hdr.ddosd.dst_ewma: bv32;
var io_hdr.ddosd.dst_ewmmd: bv32;
var io_hdr.ddosd.alarm: bv8;
var io_hdr.ddosd.ether_type: bv16;
var io_hdr.ipv4.valid: bool;
var io_hdr.ipv4.version: bv4;
var io_hdr.ipv4.ihl: bv4;
var io_hdr.ipv4.dscp: bv6;
var io_hdr.ipv4.ecn: bv2;
var io_hdr.ipv4.total_len: bv16;
var io_hdr.ipv4.identification: bv16;
var io_hdr.ipv4.flags: bv3;
var io_hdr.ipv4.frag_offset: bv13;
var io_hdr.ipv4.ttl: bv8;
var io_hdr.ipv4.protocol: bv8;
var io_hdr.ipv4.hdr_checksum: bv16;
var io_hdr.ipv4.src_addr: bv32;
var io_hdr.ipv4.dst_addr: bv32;
var io_meta.ip_count: bv32;
var io_meta.entropy_term: bv32;
var io_meta.pkt_num: bv32;
var io_meta.src_entropy: bv32;
var io_meta.src_ewma: bv32;
var io_meta.src_ewmmd: bv32;
var io_meta.dst_entropy: bv32;
var io_meta.dst_ewma: bv32;
var io_meta.dst_ewmmd: bv32;
var io_meta.alarm: bv8;

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
  modifies io_hdr.ddosd.alarm, io_hdr.ddosd.dst_entropy, io_hdr.ddosd.dst_ewma, io_hdr.ddosd.dst_ewmmd, io_hdr.ddosd.ether_type, io_hdr.ddosd.pkt_num, io_hdr.ddosd.src_entropy, io_hdr.ddosd.src_ewma, io_hdr.ddosd.src_ewmmd, io_hdr.ddosd.valid, io_hdr.ethernet.dst_addr, io_hdr.ethernet.ether_type, io_hdr.ethernet.src_addr, io_hdr.ethernet.valid, io_hdr.ipv4.dscp, io_hdr.ipv4.dst_addr, io_hdr.ipv4.ecn, io_hdr.ipv4.flags, io_hdr.ipv4.frag_offset, io_hdr.ipv4.hdr_checksum, io_hdr.ipv4.identification, io_hdr.ipv4.ihl, io_hdr.ipv4.protocol, io_hdr.ipv4.src_addr, io_hdr.ipv4.total_len, io_hdr.ipv4.ttl, io_hdr.ipv4.valid, io_hdr.ipv4.version, io_inbox_count, io_meta.alarm, io_meta.dst_entropy, io_meta.dst_ewma, io_meta.dst_ewmmd, io_meta.entropy_term, io_meta.ip_count, io_meta.pkt_num, io_meta.src_entropy, io_meta.src_ewma, io_meta.src_ewmmd, io_pkt_external, io_standard_metadata.checksum_error, io_standard_metadata.deq_qdepth, io_standard_metadata.deq_timedelta, io_standard_metadata.egress_global_timestamp, io_standard_metadata.egress_rid, io_standard_metadata.enq_qdepth, io_standard_metadata.enq_timestamp, io_standard_metadata.ingress_global_timestamp, io_standard_metadata.ingress_port, io_standard_metadata.instance_type, io_standard_metadata.mcast_grp, io_standard_metadata.packet_length, io_standard_metadata.parser_error, io_standard_metadata.priority, procurator_bad, procurator_step, s1_alpha_aux_0, s1_current_ow_0, s1_drop, s1_dst_S_aux_0, s1_dst_c1_0, s1_dst_c2_0, s1_dst_c3_0, s1_dst_c4_0, s1_dst_cs1_ow_aux_0, s1_dst_cs2_ow_aux_0, s1_dst_cs3_ow_aux_0, s1_dst_cs4_ow_aux_0, s1_dst_g1_0, s1_dst_g2_0, s1_dst_g3_0, s1_dst_g4_0, s1_dst_h1_0, s1_dst_h2_0, s1_dst_h3_0, s1_dst_h4_0, s1_dst_thresh_0, s1_forward, s1_g1_0, s1_g1_2, s1_g2_0, s1_g2_2, s1_g3_0, s1_g3_2, s1_g4_0, s1_g4_2, s1_h1_0, s1_h1_2, s1_h2_0, s1_h2_2, s1_h3_0, s1_h3_2, s1_h4_0, s1_h4_2, s1_hdr.ddosd.alarm, s1_hdr.ddosd.dst_entropy, s1_hdr.ddosd.dst_ewma, s1_hdr.ddosd.dst_ewmmd, s1_hdr.ddosd.ether_type, s1_hdr.ddosd.pkt_num, s1_hdr.ddosd.src_entropy, s1_hdr.ddosd.src_ewma, s1_hdr.ddosd.src_ewmmd, s1_hdr.ddosd.valid, s1_hdr.ethernet.dst_addr, s1_hdr.ethernet.ether_type, s1_hdr.ethernet.src_addr, s1_hdr.ethernet.valid, s1_hdr.ipv4.dscp, s1_hdr.ipv4.dst_addr, s1_hdr.ipv4.ecn, s1_hdr.ipv4.flags, s1_hdr.ipv4.frag_offset, s1_hdr.ipv4.hdr_checksum, s1_hdr.ipv4.identification, s1_hdr.ipv4.ihl, s1_hdr.ipv4.protocol, s1_hdr.ipv4.src_addr, s1_hdr.ipv4.total_len, s1_hdr.ipv4.ttl, s1_hdr.ipv4.valid, s1_hdr.ipv4.version, s1_idx_0, s1_inbox_count, s1_ingress_alpha__last0_old_value, s1_ingress_alpha__last0_value, s1_ingress_alpha__last_index, s1_ingress_alpha__last_old_value, s1_ingress_alpha__last_value, s1_ingress_alpha__last_write_site, s1_ingress_alpha__next_write_site, s1_ingress_alpha__wrote_any, s1_ingress_alpha__wrote_index0, s1_ingress_dst_S, s1_ingress_dst_S__last0_old_value, s1_ingress_dst_S__last0_value, s1_ingress_dst_S__last_index, s1_ingress_dst_S__last_old_value, s1_ingress_dst_S__last_value, s1_ingress_dst_S__last_write_site, s1_ingress_dst_S__next_write_site, s1_ingress_dst_S__wrote_any, s1_ingress_dst_S__wrote_index0, s1_ingress_dst_cs1, s1_ingress_dst_cs1__last0_old_value, s1_ingress_dst_cs1__last0_value, s1_ingress_dst_cs1__last_index, s1_ingress_dst_cs1__last_old_value, s1_ingress_dst_cs1__last_value, s1_ingress_dst_cs1__last_write_site, s1_ingress_dst_cs1__next_write_site, s1_ingress_dst_cs1__wrote_any, s1_ingress_dst_cs1__wrote_index0, s1_ingress_dst_cs1_ow, s1_ingress_dst_cs1_ow__last0_old_value, s1_ingress_dst_cs1_ow__last0_value, s1_ingress_dst_cs1_ow__last_index, s1_ingress_dst_cs1_ow__last_old_value, s1_ingress_dst_cs1_ow__last_value, s1_ingress_dst_cs1_ow__last_write_site, s1_ingress_dst_cs1_ow__next_write_site, s1_ingress_dst_cs1_ow__wrote_any, s1_ingress_dst_cs1_ow__wrote_index0, s1_ingress_dst_cs2, s1_ingress_dst_cs2__last0_old_value, s1_ingress_dst_cs2__last0_value, s1_ingress_dst_cs2__last_index, s1_ingress_dst_cs2__last_old_value, s1_ingress_dst_cs2__last_value, s1_ingress_dst_cs2__last_write_site, s1_ingress_dst_cs2__next_write_site, s1_ingress_dst_cs2__wrote_any, s1_ingress_dst_cs2__wrote_index0, s1_ingress_dst_cs2_ow, s1_ingress_dst_cs2_ow__last0_old_value, s1_ingress_dst_cs2_ow__last0_value, s1_ingress_dst_cs2_ow__last_index, s1_ingress_dst_cs2_ow__last_old_value, s1_ingress_dst_cs2_ow__last_value, s1_ingress_dst_cs2_ow__last_write_site, s1_ingress_dst_cs2_ow__next_write_site, s1_ingress_dst_cs2_ow__wrote_any, s1_ingress_dst_cs2_ow__wrote_index0, s1_ingress_dst_cs3, s1_ingress_dst_cs3__last0_old_value, s1_ingress_dst_cs3__last0_value, s1_ingress_dst_cs3__last_index, s1_ingress_dst_cs3__last_old_value, s1_ingress_dst_cs3__last_value, s1_ingress_dst_cs3__last_write_site, s1_ingress_dst_cs3__next_write_site, s1_ingress_dst_cs3__wrote_any, s1_ingress_dst_cs3__wrote_index0, s1_ingress_dst_cs3_ow, s1_ingress_dst_cs3_ow__last0_old_value, s1_ingress_dst_cs3_ow__last0_value, s1_ingress_dst_cs3_ow__last_index, s1_ingress_dst_cs3_ow__last_old_value, s1_ingress_dst_cs3_ow__last_value, s1_ingress_dst_cs3_ow__last_write_site, s1_ingress_dst_cs3_ow__next_write_site, s1_ingress_dst_cs3_ow__wrote_any, s1_ingress_dst_cs3_ow__wrote_index0, s1_ingress_dst_cs4, s1_ingress_dst_cs4__last0_old_value, s1_ingress_dst_cs4__last0_value, s1_ingress_dst_cs4__last_index, s1_ingress_dst_cs4__last_old_value, s1_ingress_dst_cs4__last_value, s1_ingress_dst_cs4__last_write_site, s1_ingress_dst_cs4__next_write_site, s1_ingress_dst_cs4__wrote_any, s1_ingress_dst_cs4__wrote_index0, s1_ingress_dst_cs4_ow, s1_ingress_dst_cs4_ow__last0_old_value, s1_ingress_dst_cs4_ow__last0_value, s1_ingress_dst_cs4_ow__last_index, s1_ingress_dst_cs4_ow__last_old_value, s1_ingress_dst_cs4_ow__last_value, s1_ingress_dst_cs4_ow__last_write_site, s1_ingress_dst_cs4_ow__next_write_site, s1_ingress_dst_cs4_ow__wrote_any, s1_ingress_dst_cs4_ow__wrote_index0, s1_ingress_dst_entropy_term.action_run, s1_ingress_dst_entropy_term.hit, s1_ingress_dst_ewma, s1_ingress_dst_ewma__last0_old_value, s1_ingress_dst_ewma__last0_value, s1_ingress_dst_ewma__last_index, s1_ingress_dst_ewma__last_old_value, s1_ingress_dst_ewma__last_value, s1_ingress_dst_ewma__last_write_site, s1_ingress_dst_ewma__next_write_site, s1_ingress_dst_ewma__wrote_any, s1_ingress_dst_ewma__wrote_index0, s1_ingress_dst_ewmmd, s1_ingress_dst_ewmmd__last0_old_value, s1_ingress_dst_ewmmd__last0_value, s1_ingress_dst_ewmmd__last_index, s1_ingress_dst_ewmmd__last_old_value, s1_ingress_dst_ewmmd__last_value, s1_ingress_dst_ewmmd__last_write_site, s1_ingress_dst_ewmmd__next_write_site, s1_ingress_dst_ewmmd__wrote_any, s1_ingress_dst_ewmmd__wrote_index0, s1_ingress_ipv4_fib.action_run, s1_ingress_ipv4_fib.hit, s1_ingress_ipv4_fib.ingress_forward.egress_port_1, s1_ingress_k__last0_old_value, s1_ingress_k__last0_value, s1_ingress_k__last_index, s1_ingress_k__last_old_value, s1_ingress_k__last_value, s1_ingress_k__last_write_site, s1_ingress_k__next_write_site, s1_ingress_k__wrote_any, s1_ingress_k__wrote_index0, s1_ingress_log2_m__last0_old_value, s1_ingress_log2_m__last0_value, s1_ingress_log2_m__last_index, s1_ingress_log2_m__last_old_value, s1_ingress_log2_m__last_value, s1_ingress_log2_m__last_write_site, s1_ingress_log2_m__next_write_site, s1_ingress_log2_m__wrote_any, s1_ingress_log2_m__wrote_index0, s1_ingress_ow_counter, s1_ingress_ow_counter__last0_old_value, s1_ingress_ow_counter__last0_value, s1_ingress_ow_counter__last_index, s1_ingress_ow_counter__last_old_value, s1_ingress_ow_counter__last_value, s1_ingress_ow_counter__last_write_site, s1_ingress_ow_counter__next_write_site, s1_ingress_ow_counter__wrote_any, s1_ingress_ow_counter__wrote_index0, s1_ingress_pkt_counter, s1_ingress_pkt_counter__last0_old_value, s1_ingress_pkt_counter__last0_value, s1_ingress_pkt_counter__last_index, s1_ingress_pkt_counter__last_old_value, s1_ingress_pkt_counter__last_value, s1_ingress_pkt_counter__last_write_site, s1_ingress_pkt_counter__next_write_site, s1_ingress_pkt_counter__wrote_any, s1_ingress_pkt_counter__wrote_index0, s1_ingress_src_S, s1_ingress_src_S__last0_old_value, s1_ingress_src_S__last0_value, s1_ingress_src_S__last_index, s1_ingress_src_S__last_old_value, s1_ingress_src_S__last_value, s1_ingress_src_S__last_write_site, s1_ingress_src_S__next_write_site, s1_ingress_src_S__wrote_any, s1_ingress_src_S__wrote_index0, s1_ingress_src_cs1, s1_ingress_src_cs1__last0_old_value, s1_ingress_src_cs1__last0_value, s1_ingress_src_cs1__last_index, s1_ingress_src_cs1__last_old_value, s1_ingress_src_cs1__last_value, s1_ingress_src_cs1__last_write_site, s1_ingress_src_cs1__next_write_site, s1_ingress_src_cs1__wrote_any, s1_ingress_src_cs1__wrote_index0, s1_ingress_src_cs1_ow, s1_ingress_src_cs1_ow__last0_old_value, s1_ingress_src_cs1_ow__last0_value, s1_ingress_src_cs1_ow__last_index, s1_ingress_src_cs1_ow__last_old_value, s1_ingress_src_cs1_ow__last_value, s1_ingress_src_cs1_ow__last_write_site, s1_ingress_src_cs1_ow__next_write_site, s1_ingress_src_cs1_ow__wrote_any, s1_ingress_src_cs1_ow__wrote_index0, s1_ingress_src_cs2, s1_ingress_src_cs2__last0_old_value, s1_ingress_src_cs2__last0_value, s1_ingress_src_cs2__last_index, s1_ingress_src_cs2__last_old_value, s1_ingress_src_cs2__last_value, s1_ingress_src_cs2__last_write_site, s1_ingress_src_cs2__next_write_site, s1_ingress_src_cs2__wrote_any, s1_ingress_src_cs2__wrote_index0, s1_ingress_src_cs2_ow, s1_ingress_src_cs2_ow__last0_old_value, s1_ingress_src_cs2_ow__last0_value, s1_ingress_src_cs2_ow__last_index, s1_ingress_src_cs2_ow__last_old_value, s1_ingress_src_cs2_ow__last_value, s1_ingress_src_cs2_ow__last_write_site, s1_ingress_src_cs2_ow__next_write_site, s1_ingress_src_cs2_ow__wrote_any, s1_ingress_src_cs2_ow__wrote_index0, s1_ingress_src_cs3, s1_ingress_src_cs3__last0_old_value, s1_ingress_src_cs3__last0_value, s1_ingress_src_cs3__last_index, s1_ingress_src_cs3__last_old_value, s1_ingress_src_cs3__last_value, s1_ingress_src_cs3__last_write_site, s1_ingress_src_cs3__next_write_site, s1_ingress_src_cs3__wrote_any, s1_ingress_src_cs3__wrote_index0, s1_ingress_src_cs3_ow, s1_ingress_src_cs3_ow__last0_old_value, s1_ingress_src_cs3_ow__last0_value, s1_ingress_src_cs3_ow__last_index, s1_ingress_src_cs3_ow__last_old_value, s1_ingress_src_cs3_ow__last_value, s1_ingress_src_cs3_ow__last_write_site, s1_ingress_src_cs3_ow__next_write_site, s1_ingress_src_cs3_ow__wrote_any, s1_ingress_src_cs3_ow__wrote_index0, s1_ingress_src_cs4, s1_ingress_src_cs4__last0_old_value, s1_ingress_src_cs4__last0_value, s1_ingress_src_cs4__last_index, s1_ingress_src_cs4__last_old_value, s1_ingress_src_cs4__last_value, s1_ingress_src_cs4__last_write_site, s1_ingress_src_cs4__next_write_site, s1_ingress_src_cs4__wrote_any, s1_ingress_src_cs4__wrote_index0, s1_ingress_src_cs4_ow, s1_ingress_src_cs4_ow__last0_old_value, s1_ingress_src_cs4_ow__last0_value, s1_ingress_src_cs4_ow__last_index, s1_ingress_src_cs4_ow__last_old_value, s1_ingress_src_cs4_ow__last_value, s1_ingress_src_cs4_ow__last_write_site, s1_ingress_src_cs4_ow__next_write_site, s1_ingress_src_cs4_ow__wrote_any, s1_ingress_src_cs4_ow__wrote_index0, s1_ingress_src_entropy_term.action_run, s1_ingress_src_entropy_term.hit, s1_ingress_src_ewma, s1_ingress_src_ewma__last0_old_value, s1_ingress_src_ewma__last0_value, s1_ingress_src_ewma__last_index, s1_ingress_src_ewma__last_old_value, s1_ingress_src_ewma__last_value, s1_ingress_src_ewma__last_write_site, s1_ingress_src_ewma__next_write_site, s1_ingress_src_ewma__wrote_any, s1_ingress_src_ewma__wrote_index0, s1_ingress_src_ewmmd, s1_ingress_src_ewmmd__last0_old_value, s1_ingress_src_ewmmd__last0_value, s1_ingress_src_ewmmd__last_index, s1_ingress_src_ewmmd__last_old_value, s1_ingress_src_ewmmd__last_value, s1_ingress_src_ewmmd__last_write_site, s1_ingress_src_ewmmd__next_write_site, s1_ingress_src_ewmmd__wrote_any, s1_ingress_src_ewmmd__wrote_index0, s1_ingress_training_len__last0_old_value, s1_ingress_training_len__last0_value, s1_ingress_training_len__last_index, s1_ingress_training_len__last_old_value, s1_ingress_training_len__last_value, s1_ingress_training_len__last_write_site, s1_ingress_training_len__next_write_site, s1_ingress_training_len__wrote_any, s1_ingress_training_len__wrote_index0, s1_ipv4_addr_0, s1_ipv4_addr_1, s1_isValid, s1_k_aux_0, s1_log2_m_aux_0, s1_m_0, s1_meta.alarm, s1_meta.dst_entropy, s1_meta.dst_ewma, s1_meta.dst_ewmmd, s1_meta.entropy_term, s1_meta.ip_count, s1_meta.pkt_num, s1_meta.src_entropy, s1_meta.src_ewma, s1_meta.src_ewmmd, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_external, s1_src_S_aux_0, s1_src_c1_0, s1_src_c2_0, s1_src_c3_0, s1_src_c4_0, s1_src_cs1_ow_aux_0, s1_src_cs2_ow_aux_0, s1_src_cs3_ow_aux_0, s1_src_cs4_ow_aux_0, s1_src_g1_0, s1_src_g2_0, s1_src_g3_0, s1_src_g4_0, s1_src_h1_0, s1_src_h2_0, s1_src_h3_0, s1_src_h4_0, s1_src_thresh_0, s1_standard_metadata.checksum_error, s1_standard_metadata.deq_qdepth, s1_standard_metadata.deq_timedelta, s1_standard_metadata.egress_global_timestamp, s1_standard_metadata.egress_port, s1_standard_metadata.egress_rid, s1_standard_metadata.egress_spec, s1_standard_metadata.enq_qdepth, s1_standard_metadata.enq_timestamp, s1_standard_metadata.ingress_global_timestamp, s1_standard_metadata.ingress_port, s1_standard_metadata.instance_type, s1_standard_metadata.mcast_grp, s1_standard_metadata.packet_length, s1_standard_metadata.parser_error, s1_standard_metadata.priority, s1_training_len_aux_0, s1_x1_0, s1_x1_2, s1_x2_0, s1_x2_2, s1_x3_0, s1_x3_2, s1_x4_0, s1_x4_2, s1_y_0, s1_y_2;
{
  // initialize inboxes
  s1_inbox_count := 0;
  s1_pkt_external := false;
  io_inbox_count := 0;
  io_pkt_external := false;
  // initialize P4B event flags (clone/recirculate)
  s1_p4b_clone_i2e := false;
  s1_p4b_clone_e2e := false;
  s1_p4b_clone_i2i := false;
  s1_p4b_recirculate := false;

  // initialize P4 registers (default 0)
  assume s1_ingress_alpha[0bv32] == 0bv8;
  assume s1_ingress_dst_S[0bv32] == 0bv32;
  assume (forall i:bv32 :: s1_ingress_dst_cs1[i] == 0bv32);
  assume s1_ingress_dst_cs1[0bv32] == 0bv32;
  assume (forall i:bv32 :: s1_ingress_dst_cs1_ow[i] == 0bv8);
  assume s1_ingress_dst_cs1_ow[0bv32] == 0bv8;
  assume (forall i:bv32 :: s1_ingress_dst_cs2[i] == 0bv32);
  assume s1_ingress_dst_cs2[0bv32] == 0bv32;
  assume (forall i:bv32 :: s1_ingress_dst_cs2_ow[i] == 0bv8);
  assume s1_ingress_dst_cs2_ow[0bv32] == 0bv8;
  assume (forall i:bv32 :: s1_ingress_dst_cs3[i] == 0bv32);
  assume s1_ingress_dst_cs3[0bv32] == 0bv32;
  assume (forall i:bv32 :: s1_ingress_dst_cs3_ow[i] == 0bv8);
  assume s1_ingress_dst_cs3_ow[0bv32] == 0bv8;
  assume (forall i:bv32 :: s1_ingress_dst_cs4[i] == 0bv32);
  assume s1_ingress_dst_cs4[0bv32] == 0bv32;
  assume (forall i:bv32 :: s1_ingress_dst_cs4_ow[i] == 0bv8);
  assume s1_ingress_dst_cs4_ow[0bv32] == 0bv8;
  assume s1_ingress_dst_ewma[0bv32] == 0bv32;
  assume s1_ingress_dst_ewmmd[0bv32] == 0bv32;
  assume s1_ingress_k[0bv32] == 0bv8;
  assume s1_ingress_log2_m[0bv32] == 0bv5;
  assume s1_ingress_ow_counter[0bv32] == 256bv32;
  assume s1_ingress_pkt_counter[0bv32] == 0bv32;
  assume s1_ingress_src_S[0bv32] == 0bv32;
  assume (forall i:bv32 :: ((i != 0bv32)) ==> s1_ingress_src_cs1[i] == 0bv32);
  assume s1_ingress_src_cs1[0bv32] == 1bv32;
  assume s1_ingress_src_cs1[0bv32] == 1bv32;
  assume (forall i:bv32 :: ((i != 0bv32)) ==> s1_ingress_src_cs1_ow[i] == 0bv8);
  assume s1_ingress_src_cs1_ow[0bv32] == 0bv8;
  assume s1_ingress_src_cs1_ow[0bv32] == 0bv8;
  assume (forall i:bv32 :: s1_ingress_src_cs2[i] == 0bv32);
  assume s1_ingress_src_cs2[0bv32] == 0bv32;
  assume (forall i:bv32 :: s1_ingress_src_cs2_ow[i] == 0bv8);
  assume s1_ingress_src_cs2_ow[0bv32] == 0bv8;
  assume (forall i:bv32 :: s1_ingress_src_cs3[i] == 0bv32);
  assume s1_ingress_src_cs3[0bv32] == 0bv32;
  assume (forall i:bv32 :: s1_ingress_src_cs3_ow[i] == 0bv8);
  assume s1_ingress_src_cs3_ow[0bv32] == 0bv8;
  assume (forall i:bv32 :: s1_ingress_src_cs4[i] == 0bv32);
  assume s1_ingress_src_cs4[0bv32] == 0bv32;
  assume (forall i:bv32 :: s1_ingress_src_cs4_ow[i] == 0bv8);
  assume s1_ingress_src_cs4_ow[0bv32] == 0bv8;
  assume s1_ingress_src_ewma[0bv32] == 0bv32;
  assume s1_ingress_src_ewmmd[0bv32] == 0bv32;
  assume s1_ingress_training_len[0bv32] == 0bv32;
  // initialize register write tracking (debug)
  s1_ingress_alpha__last_index := 0bv32;
  s1_ingress_alpha__last_value := 0bv8;
  s1_ingress_alpha__last_old_value := 0bv8;
  s1_ingress_alpha__wrote_any := false;
  s1_ingress_alpha__wrote_index0 := false;
  s1_ingress_alpha__next_write_site := 0;
  s1_ingress_alpha__last_write_site := 0;
  s1_ingress_alpha__last0_old_value := 0bv8;
  s1_ingress_alpha__last0_value := 0bv8;
  s1_ingress_dst_S__last_index := 0bv32;
  s1_ingress_dst_S__last_value := 0bv32;
  s1_ingress_dst_S__last_old_value := 0bv32;
  s1_ingress_dst_S__wrote_any := false;
  s1_ingress_dst_S__wrote_index0 := false;
  s1_ingress_dst_S__next_write_site := 0;
  s1_ingress_dst_S__last_write_site := 0;
  s1_ingress_dst_S__last0_old_value := 0bv32;
  s1_ingress_dst_S__last0_value := 0bv32;
  s1_ingress_dst_cs1__last_index := 0bv32;
  s1_ingress_dst_cs1__last_value := 0bv32;
  s1_ingress_dst_cs1__last_old_value := 0bv32;
  s1_ingress_dst_cs1__wrote_any := false;
  s1_ingress_dst_cs1__wrote_index0 := false;
  s1_ingress_dst_cs1__next_write_site := 0;
  s1_ingress_dst_cs1__last_write_site := 0;
  s1_ingress_dst_cs1__last0_old_value := 0bv32;
  s1_ingress_dst_cs1__last0_value := 0bv32;
  s1_ingress_dst_cs1_ow__last_index := 0bv32;
  s1_ingress_dst_cs1_ow__last_value := 0bv8;
  s1_ingress_dst_cs1_ow__last_old_value := 0bv8;
  s1_ingress_dst_cs1_ow__wrote_any := false;
  s1_ingress_dst_cs1_ow__wrote_index0 := false;
  s1_ingress_dst_cs1_ow__next_write_site := 0;
  s1_ingress_dst_cs1_ow__last_write_site := 0;
  s1_ingress_dst_cs1_ow__last0_old_value := 0bv8;
  s1_ingress_dst_cs1_ow__last0_value := 0bv8;
  s1_ingress_dst_cs2__last_index := 0bv32;
  s1_ingress_dst_cs2__last_value := 0bv32;
  s1_ingress_dst_cs2__last_old_value := 0bv32;
  s1_ingress_dst_cs2__wrote_any := false;
  s1_ingress_dst_cs2__wrote_index0 := false;
  s1_ingress_dst_cs2__next_write_site := 0;
  s1_ingress_dst_cs2__last_write_site := 0;
  s1_ingress_dst_cs2__last0_old_value := 0bv32;
  s1_ingress_dst_cs2__last0_value := 0bv32;
  s1_ingress_dst_cs2_ow__last_index := 0bv32;
  s1_ingress_dst_cs2_ow__last_value := 0bv8;
  s1_ingress_dst_cs2_ow__last_old_value := 0bv8;
  s1_ingress_dst_cs2_ow__wrote_any := false;
  s1_ingress_dst_cs2_ow__wrote_index0 := false;
  s1_ingress_dst_cs2_ow__next_write_site := 0;
  s1_ingress_dst_cs2_ow__last_write_site := 0;
  s1_ingress_dst_cs2_ow__last0_old_value := 0bv8;
  s1_ingress_dst_cs2_ow__last0_value := 0bv8;
  s1_ingress_dst_cs3__last_index := 0bv32;
  s1_ingress_dst_cs3__last_value := 0bv32;
  s1_ingress_dst_cs3__last_old_value := 0bv32;
  s1_ingress_dst_cs3__wrote_any := false;
  s1_ingress_dst_cs3__wrote_index0 := false;
  s1_ingress_dst_cs3__next_write_site := 0;
  s1_ingress_dst_cs3__last_write_site := 0;
  s1_ingress_dst_cs3__last0_old_value := 0bv32;
  s1_ingress_dst_cs3__last0_value := 0bv32;
  s1_ingress_dst_cs3_ow__last_index := 0bv32;
  s1_ingress_dst_cs3_ow__last_value := 0bv8;
  s1_ingress_dst_cs3_ow__last_old_value := 0bv8;
  s1_ingress_dst_cs3_ow__wrote_any := false;
  s1_ingress_dst_cs3_ow__wrote_index0 := false;
  s1_ingress_dst_cs3_ow__next_write_site := 0;
  s1_ingress_dst_cs3_ow__last_write_site := 0;
  s1_ingress_dst_cs3_ow__last0_old_value := 0bv8;
  s1_ingress_dst_cs3_ow__last0_value := 0bv8;
  s1_ingress_dst_cs4__last_index := 0bv32;
  s1_ingress_dst_cs4__last_value := 0bv32;
  s1_ingress_dst_cs4__last_old_value := 0bv32;
  s1_ingress_dst_cs4__wrote_any := false;
  s1_ingress_dst_cs4__wrote_index0 := false;
  s1_ingress_dst_cs4__next_write_site := 0;
  s1_ingress_dst_cs4__last_write_site := 0;
  s1_ingress_dst_cs4__last0_old_value := 0bv32;
  s1_ingress_dst_cs4__last0_value := 0bv32;
  s1_ingress_dst_cs4_ow__last_index := 0bv32;
  s1_ingress_dst_cs4_ow__last_value := 0bv8;
  s1_ingress_dst_cs4_ow__last_old_value := 0bv8;
  s1_ingress_dst_cs4_ow__wrote_any := false;
  s1_ingress_dst_cs4_ow__wrote_index0 := false;
  s1_ingress_dst_cs4_ow__next_write_site := 0;
  s1_ingress_dst_cs4_ow__last_write_site := 0;
  s1_ingress_dst_cs4_ow__last0_old_value := 0bv8;
  s1_ingress_dst_cs4_ow__last0_value := 0bv8;
  s1_ingress_dst_ewma__last_index := 0bv32;
  s1_ingress_dst_ewma__last_value := 0bv32;
  s1_ingress_dst_ewma__last_old_value := 0bv32;
  s1_ingress_dst_ewma__wrote_any := false;
  s1_ingress_dst_ewma__wrote_index0 := false;
  s1_ingress_dst_ewma__next_write_site := 0;
  s1_ingress_dst_ewma__last_write_site := 0;
  s1_ingress_dst_ewma__last0_old_value := 0bv32;
  s1_ingress_dst_ewma__last0_value := 0bv32;
  s1_ingress_dst_ewmmd__last_index := 0bv32;
  s1_ingress_dst_ewmmd__last_value := 0bv32;
  s1_ingress_dst_ewmmd__last_old_value := 0bv32;
  s1_ingress_dst_ewmmd__wrote_any := false;
  s1_ingress_dst_ewmmd__wrote_index0 := false;
  s1_ingress_dst_ewmmd__next_write_site := 0;
  s1_ingress_dst_ewmmd__last_write_site := 0;
  s1_ingress_dst_ewmmd__last0_old_value := 0bv32;
  s1_ingress_dst_ewmmd__last0_value := 0bv32;
  s1_ingress_k__last_index := 0bv32;
  s1_ingress_k__last_value := 0bv8;
  s1_ingress_k__last_old_value := 0bv8;
  s1_ingress_k__wrote_any := false;
  s1_ingress_k__wrote_index0 := false;
  s1_ingress_k__next_write_site := 0;
  s1_ingress_k__last_write_site := 0;
  s1_ingress_k__last0_old_value := 0bv8;
  s1_ingress_k__last0_value := 0bv8;
  s1_ingress_log2_m__last_index := 0bv32;
  s1_ingress_log2_m__last_value := 0bv5;
  s1_ingress_log2_m__last_old_value := 0bv5;
  s1_ingress_log2_m__wrote_any := false;
  s1_ingress_log2_m__wrote_index0 := false;
  s1_ingress_log2_m__next_write_site := 0;
  s1_ingress_log2_m__last_write_site := 0;
  s1_ingress_log2_m__last0_old_value := 0bv5;
  s1_ingress_log2_m__last0_value := 0bv5;
  s1_ingress_ow_counter__last_index := 0bv32;
  s1_ingress_ow_counter__last_value := 0bv32;
  s1_ingress_ow_counter__last_old_value := 0bv32;
  s1_ingress_ow_counter__wrote_any := false;
  s1_ingress_ow_counter__wrote_index0 := false;
  s1_ingress_ow_counter__next_write_site := 0;
  s1_ingress_ow_counter__last_write_site := 0;
  s1_ingress_ow_counter__last0_old_value := 0bv32;
  s1_ingress_ow_counter__last0_value := 0bv32;
  s1_ingress_pkt_counter__last_index := 0bv32;
  s1_ingress_pkt_counter__last_value := 0bv32;
  s1_ingress_pkt_counter__last_old_value := 0bv32;
  s1_ingress_pkt_counter__wrote_any := false;
  s1_ingress_pkt_counter__wrote_index0 := false;
  s1_ingress_pkt_counter__next_write_site := 0;
  s1_ingress_pkt_counter__last_write_site := 0;
  s1_ingress_pkt_counter__last0_old_value := 0bv32;
  s1_ingress_pkt_counter__last0_value := 0bv32;
  s1_ingress_src_S__last_index := 0bv32;
  s1_ingress_src_S__last_value := 0bv32;
  s1_ingress_src_S__last_old_value := 0bv32;
  s1_ingress_src_S__wrote_any := false;
  s1_ingress_src_S__wrote_index0 := false;
  s1_ingress_src_S__next_write_site := 0;
  s1_ingress_src_S__last_write_site := 0;
  s1_ingress_src_S__last0_old_value := 0bv32;
  s1_ingress_src_S__last0_value := 0bv32;
  s1_ingress_src_cs1__last_index := 0bv32;
  s1_ingress_src_cs1__last_value := 0bv32;
  s1_ingress_src_cs1__last_old_value := 0bv32;
  s1_ingress_src_cs1__wrote_any := false;
  s1_ingress_src_cs1__wrote_index0 := false;
  s1_ingress_src_cs1__next_write_site := 0;
  s1_ingress_src_cs1__last_write_site := 0;
  s1_ingress_src_cs1__last0_old_value := 0bv32;
  s1_ingress_src_cs1__last0_value := 0bv32;
  s1_ingress_src_cs1_ow__last_index := 0bv32;
  s1_ingress_src_cs1_ow__last_value := 0bv8;
  s1_ingress_src_cs1_ow__last_old_value := 0bv8;
  s1_ingress_src_cs1_ow__wrote_any := false;
  s1_ingress_src_cs1_ow__wrote_index0 := false;
  s1_ingress_src_cs1_ow__next_write_site := 0;
  s1_ingress_src_cs1_ow__last_write_site := 0;
  s1_ingress_src_cs1_ow__last0_old_value := 0bv8;
  s1_ingress_src_cs1_ow__last0_value := 0bv8;
  s1_ingress_src_cs2__last_index := 0bv32;
  s1_ingress_src_cs2__last_value := 0bv32;
  s1_ingress_src_cs2__last_old_value := 0bv32;
  s1_ingress_src_cs2__wrote_any := false;
  s1_ingress_src_cs2__wrote_index0 := false;
  s1_ingress_src_cs2__next_write_site := 0;
  s1_ingress_src_cs2__last_write_site := 0;
  s1_ingress_src_cs2__last0_old_value := 0bv32;
  s1_ingress_src_cs2__last0_value := 0bv32;
  s1_ingress_src_cs2_ow__last_index := 0bv32;
  s1_ingress_src_cs2_ow__last_value := 0bv8;
  s1_ingress_src_cs2_ow__last_old_value := 0bv8;
  s1_ingress_src_cs2_ow__wrote_any := false;
  s1_ingress_src_cs2_ow__wrote_index0 := false;
  s1_ingress_src_cs2_ow__next_write_site := 0;
  s1_ingress_src_cs2_ow__last_write_site := 0;
  s1_ingress_src_cs2_ow__last0_old_value := 0bv8;
  s1_ingress_src_cs2_ow__last0_value := 0bv8;
  s1_ingress_src_cs3__last_index := 0bv32;
  s1_ingress_src_cs3__last_value := 0bv32;
  s1_ingress_src_cs3__last_old_value := 0bv32;
  s1_ingress_src_cs3__wrote_any := false;
  s1_ingress_src_cs3__wrote_index0 := false;
  s1_ingress_src_cs3__next_write_site := 0;
  s1_ingress_src_cs3__last_write_site := 0;
  s1_ingress_src_cs3__last0_old_value := 0bv32;
  s1_ingress_src_cs3__last0_value := 0bv32;
  s1_ingress_src_cs3_ow__last_index := 0bv32;
  s1_ingress_src_cs3_ow__last_value := 0bv8;
  s1_ingress_src_cs3_ow__last_old_value := 0bv8;
  s1_ingress_src_cs3_ow__wrote_any := false;
  s1_ingress_src_cs3_ow__wrote_index0 := false;
  s1_ingress_src_cs3_ow__next_write_site := 0;
  s1_ingress_src_cs3_ow__last_write_site := 0;
  s1_ingress_src_cs3_ow__last0_old_value := 0bv8;
  s1_ingress_src_cs3_ow__last0_value := 0bv8;
  s1_ingress_src_cs4__last_index := 0bv32;
  s1_ingress_src_cs4__last_value := 0bv32;
  s1_ingress_src_cs4__last_old_value := 0bv32;
  s1_ingress_src_cs4__wrote_any := false;
  s1_ingress_src_cs4__wrote_index0 := false;
  s1_ingress_src_cs4__next_write_site := 0;
  s1_ingress_src_cs4__last_write_site := 0;
  s1_ingress_src_cs4__last0_old_value := 0bv32;
  s1_ingress_src_cs4__last0_value := 0bv32;
  s1_ingress_src_cs4_ow__last_index := 0bv32;
  s1_ingress_src_cs4_ow__last_value := 0bv8;
  s1_ingress_src_cs4_ow__last_old_value := 0bv8;
  s1_ingress_src_cs4_ow__wrote_any := false;
  s1_ingress_src_cs4_ow__wrote_index0 := false;
  s1_ingress_src_cs4_ow__next_write_site := 0;
  s1_ingress_src_cs4_ow__last_write_site := 0;
  s1_ingress_src_cs4_ow__last0_old_value := 0bv8;
  s1_ingress_src_cs4_ow__last0_value := 0bv8;
  s1_ingress_src_ewma__last_index := 0bv32;
  s1_ingress_src_ewma__last_value := 0bv32;
  s1_ingress_src_ewma__last_old_value := 0bv32;
  s1_ingress_src_ewma__wrote_any := false;
  s1_ingress_src_ewma__wrote_index0 := false;
  s1_ingress_src_ewma__next_write_site := 0;
  s1_ingress_src_ewma__last_write_site := 0;
  s1_ingress_src_ewma__last0_old_value := 0bv32;
  s1_ingress_src_ewma__last0_value := 0bv32;
  s1_ingress_src_ewmmd__last_index := 0bv32;
  s1_ingress_src_ewmmd__last_value := 0bv32;
  s1_ingress_src_ewmmd__last_old_value := 0bv32;
  s1_ingress_src_ewmmd__wrote_any := false;
  s1_ingress_src_ewmmd__wrote_index0 := false;
  s1_ingress_src_ewmmd__next_write_site := 0;
  s1_ingress_src_ewmmd__last_write_site := 0;
  s1_ingress_src_ewmmd__last0_old_value := 0bv32;
  s1_ingress_src_ewmmd__last0_value := 0bv32;
  s1_ingress_training_len__last_index := 0bv32;
  s1_ingress_training_len__last_value := 0bv32;
  s1_ingress_training_len__last_old_value := 0bv32;
  s1_ingress_training_len__wrote_any := false;
  s1_ingress_training_len__wrote_index0 := false;
  s1_ingress_training_len__next_write_site := 0;
  s1_ingress_training_len__last_write_site := 0;
  s1_ingress_training_len__last0_old_value := 0bv32;
  s1_ingress_training_len__last0_value := 0bv32;

  procurator_step := 0;
  procurator_bad := false;
  // step 0: host_send -> io
  // inject packet into connected node (host -> node)
  if (s1_inbox_count < 1) {
    assume s1_inbox_count < 1;
    havoc io_standard_metadata.ingress_port;
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
    havoc io_hdr.ethernet.dst_addr;
    havoc io_hdr.ethernet.src_addr;
    havoc io_hdr.ddosd.valid;
    havoc io_hdr.ddosd.pkt_num;
    havoc io_hdr.ddosd.src_entropy;
    havoc io_hdr.ddosd.src_ewma;
    havoc io_hdr.ddosd.src_ewmmd;
    havoc io_hdr.ddosd.dst_entropy;
    havoc io_hdr.ddosd.dst_ewma;
    havoc io_hdr.ddosd.dst_ewmmd;
    havoc io_hdr.ddosd.alarm;
    havoc io_hdr.ddosd.ether_type;
    havoc io_hdr.ipv4.version;
    havoc io_hdr.ipv4.ihl;
    havoc io_hdr.ipv4.dscp;
    havoc io_hdr.ipv4.ecn;
    havoc io_hdr.ipv4.total_len;
    havoc io_hdr.ipv4.identification;
    havoc io_hdr.ipv4.flags;
    havoc io_hdr.ipv4.frag_offset;
    havoc io_hdr.ipv4.ttl;
    havoc io_hdr.ipv4.protocol;
    havoc io_hdr.ipv4.hdr_checksum;
    havoc io_meta.ip_count;
    havoc io_meta.entropy_term;
    havoc io_meta.pkt_num;
    havoc io_meta.src_entropy;
    havoc io_meta.src_ewma;
    havoc io_meta.src_ewmmd;
    havoc io_meta.dst_entropy;
    havoc io_meta.dst_ewma;
    havoc io_meta.dst_ewmmd;
    havoc io_meta.alarm;
    io_hdr.ethernet.valid := true;
    io_hdr.ipv4.valid := true;
    io_hdr.ethernet.ether_type := 2048bv16;
    io_hdr.ipv4.src_addr := 2bv32;
    io_hdr.ipv4.dst_addr := 1bv32;
    s1_standard_metadata.ingress_port := io_standard_metadata.ingress_port;
    s1_standard_metadata.instance_type := io_standard_metadata.instance_type;
    s1_standard_metadata.packet_length := io_standard_metadata.packet_length;
    s1_standard_metadata.enq_timestamp := io_standard_metadata.enq_timestamp;
    s1_standard_metadata.enq_qdepth := io_standard_metadata.enq_qdepth;
    s1_standard_metadata.deq_timedelta := io_standard_metadata.deq_timedelta;
    s1_standard_metadata.deq_qdepth := io_standard_metadata.deq_qdepth;
    s1_standard_metadata.ingress_global_timestamp := io_standard_metadata.ingress_global_timestamp;
    s1_standard_metadata.egress_global_timestamp := io_standard_metadata.egress_global_timestamp;
    s1_standard_metadata.mcast_grp := io_standard_metadata.mcast_grp;
    s1_standard_metadata.egress_rid := io_standard_metadata.egress_rid;
    s1_standard_metadata.checksum_error := io_standard_metadata.checksum_error;
    s1_standard_metadata.parser_error := io_standard_metadata.parser_error;
    s1_standard_metadata.priority := io_standard_metadata.priority;
    s1_hdr.ethernet.valid := io_hdr.ethernet.valid;
    s1_hdr.ethernet.dst_addr := io_hdr.ethernet.dst_addr;
    s1_hdr.ethernet.src_addr := io_hdr.ethernet.src_addr;
    s1_hdr.ethernet.ether_type := io_hdr.ethernet.ether_type;
    s1_hdr.ddosd.valid := io_hdr.ddosd.valid;
    s1_hdr.ddosd.pkt_num := io_hdr.ddosd.pkt_num;
    s1_hdr.ddosd.src_entropy := io_hdr.ddosd.src_entropy;
    s1_hdr.ddosd.src_ewma := io_hdr.ddosd.src_ewma;
    s1_hdr.ddosd.src_ewmmd := io_hdr.ddosd.src_ewmmd;
    s1_hdr.ddosd.dst_entropy := io_hdr.ddosd.dst_entropy;
    s1_hdr.ddosd.dst_ewma := io_hdr.ddosd.dst_ewma;
    s1_hdr.ddosd.dst_ewmmd := io_hdr.ddosd.dst_ewmmd;
    s1_hdr.ddosd.alarm := io_hdr.ddosd.alarm;
    s1_hdr.ddosd.ether_type := io_hdr.ddosd.ether_type;
    s1_hdr.ipv4.valid := io_hdr.ipv4.valid;
    s1_hdr.ipv4.version := io_hdr.ipv4.version;
    s1_hdr.ipv4.ihl := io_hdr.ipv4.ihl;
    s1_hdr.ipv4.dscp := io_hdr.ipv4.dscp;
    s1_hdr.ipv4.ecn := io_hdr.ipv4.ecn;
    s1_hdr.ipv4.total_len := io_hdr.ipv4.total_len;
    s1_hdr.ipv4.identification := io_hdr.ipv4.identification;
    s1_hdr.ipv4.flags := io_hdr.ipv4.flags;
    s1_hdr.ipv4.frag_offset := io_hdr.ipv4.frag_offset;
    s1_hdr.ipv4.ttl := io_hdr.ipv4.ttl;
    s1_hdr.ipv4.protocol := io_hdr.ipv4.protocol;
    s1_hdr.ipv4.hdr_checksum := io_hdr.ipv4.hdr_checksum;
    s1_hdr.ipv4.src_addr := io_hdr.ipv4.src_addr;
    s1_hdr.ipv4.dst_addr := io_hdr.ipv4.dst_addr;
    s1_meta.ip_count := io_meta.ip_count;
    s1_meta.entropy_term := io_meta.entropy_term;
    s1_meta.pkt_num := io_meta.pkt_num;
    s1_meta.src_entropy := io_meta.src_entropy;
    s1_meta.src_ewma := io_meta.src_ewma;
    s1_meta.src_ewmmd := io_meta.src_ewmmd;
    s1_meta.dst_entropy := io_meta.dst_entropy;
    s1_meta.dst_ewma := io_meta.dst_ewma;
    s1_meta.dst_ewmmd := io_meta.dst_ewmmd;
    s1_meta.alarm := io_meta.alarm;
    s1_pkt_external := true;
    s1_inbox_count := s1_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 1: host_recv -> io
  procurator_step := procurator_step + 1;
  // step 2: node_pass -> s1
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
  // Global assertions (accumulated into procurator_bad)
  if (!(bvule.bv32$builtin(s1_ingress_src_cs1__last0_value, 1bv32))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  assert !procurator_bad;
}


procedure ULTIMATE.start() returns()
  modifies io_hdr.ddosd.alarm, io_hdr.ddosd.dst_entropy, io_hdr.ddosd.dst_ewma, io_hdr.ddosd.dst_ewmmd, io_hdr.ddosd.ether_type, io_hdr.ddosd.pkt_num, io_hdr.ddosd.src_entropy, io_hdr.ddosd.src_ewma, io_hdr.ddosd.src_ewmmd, io_hdr.ddosd.valid, io_hdr.ethernet.dst_addr, io_hdr.ethernet.ether_type, io_hdr.ethernet.src_addr, io_hdr.ethernet.valid, io_hdr.ipv4.dscp, io_hdr.ipv4.dst_addr, io_hdr.ipv4.ecn, io_hdr.ipv4.flags, io_hdr.ipv4.frag_offset, io_hdr.ipv4.hdr_checksum, io_hdr.ipv4.identification, io_hdr.ipv4.ihl, io_hdr.ipv4.protocol, io_hdr.ipv4.src_addr, io_hdr.ipv4.total_len, io_hdr.ipv4.ttl, io_hdr.ipv4.valid, io_hdr.ipv4.version, io_inbox_count, io_meta.alarm, io_meta.dst_entropy, io_meta.dst_ewma, io_meta.dst_ewmmd, io_meta.entropy_term, io_meta.ip_count, io_meta.pkt_num, io_meta.src_entropy, io_meta.src_ewma, io_meta.src_ewmmd, io_pkt_external, io_standard_metadata.checksum_error, io_standard_metadata.deq_qdepth, io_standard_metadata.deq_timedelta, io_standard_metadata.egress_global_timestamp, io_standard_metadata.egress_rid, io_standard_metadata.enq_qdepth, io_standard_metadata.enq_timestamp, io_standard_metadata.ingress_global_timestamp, io_standard_metadata.ingress_port, io_standard_metadata.instance_type, io_standard_metadata.mcast_grp, io_standard_metadata.packet_length, io_standard_metadata.parser_error, io_standard_metadata.priority, procurator_bad, procurator_step, s1_alpha_aux_0, s1_current_ow_0, s1_drop, s1_dst_S_aux_0, s1_dst_c1_0, s1_dst_c2_0, s1_dst_c3_0, s1_dst_c4_0, s1_dst_cs1_ow_aux_0, s1_dst_cs2_ow_aux_0, s1_dst_cs3_ow_aux_0, s1_dst_cs4_ow_aux_0, s1_dst_g1_0, s1_dst_g2_0, s1_dst_g3_0, s1_dst_g4_0, s1_dst_h1_0, s1_dst_h2_0, s1_dst_h3_0, s1_dst_h4_0, s1_dst_thresh_0, s1_forward, s1_g1_0, s1_g1_2, s1_g2_0, s1_g2_2, s1_g3_0, s1_g3_2, s1_g4_0, s1_g4_2, s1_h1_0, s1_h1_2, s1_h2_0, s1_h2_2, s1_h3_0, s1_h3_2, s1_h4_0, s1_h4_2, s1_hdr.ddosd.alarm, s1_hdr.ddosd.dst_entropy, s1_hdr.ddosd.dst_ewma, s1_hdr.ddosd.dst_ewmmd, s1_hdr.ddosd.ether_type, s1_hdr.ddosd.pkt_num, s1_hdr.ddosd.src_entropy, s1_hdr.ddosd.src_ewma, s1_hdr.ddosd.src_ewmmd, s1_hdr.ddosd.valid, s1_hdr.ethernet.dst_addr, s1_hdr.ethernet.ether_type, s1_hdr.ethernet.src_addr, s1_hdr.ethernet.valid, s1_hdr.ipv4.dscp, s1_hdr.ipv4.dst_addr, s1_hdr.ipv4.ecn, s1_hdr.ipv4.flags, s1_hdr.ipv4.frag_offset, s1_hdr.ipv4.hdr_checksum, s1_hdr.ipv4.identification, s1_hdr.ipv4.ihl, s1_hdr.ipv4.protocol, s1_hdr.ipv4.src_addr, s1_hdr.ipv4.total_len, s1_hdr.ipv4.ttl, s1_hdr.ipv4.valid, s1_hdr.ipv4.version, s1_idx_0, s1_inbox_count, s1_ingress_alpha__last0_old_value, s1_ingress_alpha__last0_value, s1_ingress_alpha__last_index, s1_ingress_alpha__last_old_value, s1_ingress_alpha__last_value, s1_ingress_alpha__last_write_site, s1_ingress_alpha__next_write_site, s1_ingress_alpha__wrote_any, s1_ingress_alpha__wrote_index0, s1_ingress_dst_S, s1_ingress_dst_S__last0_old_value, s1_ingress_dst_S__last0_value, s1_ingress_dst_S__last_index, s1_ingress_dst_S__last_old_value, s1_ingress_dst_S__last_value, s1_ingress_dst_S__last_write_site, s1_ingress_dst_S__next_write_site, s1_ingress_dst_S__wrote_any, s1_ingress_dst_S__wrote_index0, s1_ingress_dst_cs1, s1_ingress_dst_cs1__last0_old_value, s1_ingress_dst_cs1__last0_value, s1_ingress_dst_cs1__last_index, s1_ingress_dst_cs1__last_old_value, s1_ingress_dst_cs1__last_value, s1_ingress_dst_cs1__last_write_site, s1_ingress_dst_cs1__next_write_site, s1_ingress_dst_cs1__wrote_any, s1_ingress_dst_cs1__wrote_index0, s1_ingress_dst_cs1_ow, s1_ingress_dst_cs1_ow__last0_old_value, s1_ingress_dst_cs1_ow__last0_value, s1_ingress_dst_cs1_ow__last_index, s1_ingress_dst_cs1_ow__last_old_value, s1_ingress_dst_cs1_ow__last_value, s1_ingress_dst_cs1_ow__last_write_site, s1_ingress_dst_cs1_ow__next_write_site, s1_ingress_dst_cs1_ow__wrote_any, s1_ingress_dst_cs1_ow__wrote_index0, s1_ingress_dst_cs2, s1_ingress_dst_cs2__last0_old_value, s1_ingress_dst_cs2__last0_value, s1_ingress_dst_cs2__last_index, s1_ingress_dst_cs2__last_old_value, s1_ingress_dst_cs2__last_value, s1_ingress_dst_cs2__last_write_site, s1_ingress_dst_cs2__next_write_site, s1_ingress_dst_cs2__wrote_any, s1_ingress_dst_cs2__wrote_index0, s1_ingress_dst_cs2_ow, s1_ingress_dst_cs2_ow__last0_old_value, s1_ingress_dst_cs2_ow__last0_value, s1_ingress_dst_cs2_ow__last_index, s1_ingress_dst_cs2_ow__last_old_value, s1_ingress_dst_cs2_ow__last_value, s1_ingress_dst_cs2_ow__last_write_site, s1_ingress_dst_cs2_ow__next_write_site, s1_ingress_dst_cs2_ow__wrote_any, s1_ingress_dst_cs2_ow__wrote_index0, s1_ingress_dst_cs3, s1_ingress_dst_cs3__last0_old_value, s1_ingress_dst_cs3__last0_value, s1_ingress_dst_cs3__last_index, s1_ingress_dst_cs3__last_old_value, s1_ingress_dst_cs3__last_value, s1_ingress_dst_cs3__last_write_site, s1_ingress_dst_cs3__next_write_site, s1_ingress_dst_cs3__wrote_any, s1_ingress_dst_cs3__wrote_index0, s1_ingress_dst_cs3_ow, s1_ingress_dst_cs3_ow__last0_old_value, s1_ingress_dst_cs3_ow__last0_value, s1_ingress_dst_cs3_ow__last_index, s1_ingress_dst_cs3_ow__last_old_value, s1_ingress_dst_cs3_ow__last_value, s1_ingress_dst_cs3_ow__last_write_site, s1_ingress_dst_cs3_ow__next_write_site, s1_ingress_dst_cs3_ow__wrote_any, s1_ingress_dst_cs3_ow__wrote_index0, s1_ingress_dst_cs4, s1_ingress_dst_cs4__last0_old_value, s1_ingress_dst_cs4__last0_value, s1_ingress_dst_cs4__last_index, s1_ingress_dst_cs4__last_old_value, s1_ingress_dst_cs4__last_value, s1_ingress_dst_cs4__last_write_site, s1_ingress_dst_cs4__next_write_site, s1_ingress_dst_cs4__wrote_any, s1_ingress_dst_cs4__wrote_index0, s1_ingress_dst_cs4_ow, s1_ingress_dst_cs4_ow__last0_old_value, s1_ingress_dst_cs4_ow__last0_value, s1_ingress_dst_cs4_ow__last_index, s1_ingress_dst_cs4_ow__last_old_value, s1_ingress_dst_cs4_ow__last_value, s1_ingress_dst_cs4_ow__last_write_site, s1_ingress_dst_cs4_ow__next_write_site, s1_ingress_dst_cs4_ow__wrote_any, s1_ingress_dst_cs4_ow__wrote_index0, s1_ingress_dst_entropy_term.action_run, s1_ingress_dst_entropy_term.hit, s1_ingress_dst_ewma, s1_ingress_dst_ewma__last0_old_value, s1_ingress_dst_ewma__last0_value, s1_ingress_dst_ewma__last_index, s1_ingress_dst_ewma__last_old_value, s1_ingress_dst_ewma__last_value, s1_ingress_dst_ewma__last_write_site, s1_ingress_dst_ewma__next_write_site, s1_ingress_dst_ewma__wrote_any, s1_ingress_dst_ewma__wrote_index0, s1_ingress_dst_ewmmd, s1_ingress_dst_ewmmd__last0_old_value, s1_ingress_dst_ewmmd__last0_value, s1_ingress_dst_ewmmd__last_index, s1_ingress_dst_ewmmd__last_old_value, s1_ingress_dst_ewmmd__last_value, s1_ingress_dst_ewmmd__last_write_site, s1_ingress_dst_ewmmd__next_write_site, s1_ingress_dst_ewmmd__wrote_any, s1_ingress_dst_ewmmd__wrote_index0, s1_ingress_ipv4_fib.action_run, s1_ingress_ipv4_fib.hit, s1_ingress_ipv4_fib.ingress_forward.egress_port_1, s1_ingress_k__last0_old_value, s1_ingress_k__last0_value, s1_ingress_k__last_index, s1_ingress_k__last_old_value, s1_ingress_k__last_value, s1_ingress_k__last_write_site, s1_ingress_k__next_write_site, s1_ingress_k__wrote_any, s1_ingress_k__wrote_index0, s1_ingress_log2_m__last0_old_value, s1_ingress_log2_m__last0_value, s1_ingress_log2_m__last_index, s1_ingress_log2_m__last_old_value, s1_ingress_log2_m__last_value, s1_ingress_log2_m__last_write_site, s1_ingress_log2_m__next_write_site, s1_ingress_log2_m__wrote_any, s1_ingress_log2_m__wrote_index0, s1_ingress_ow_counter, s1_ingress_ow_counter__last0_old_value, s1_ingress_ow_counter__last0_value, s1_ingress_ow_counter__last_index, s1_ingress_ow_counter__last_old_value, s1_ingress_ow_counter__last_value, s1_ingress_ow_counter__last_write_site, s1_ingress_ow_counter__next_write_site, s1_ingress_ow_counter__wrote_any, s1_ingress_ow_counter__wrote_index0, s1_ingress_pkt_counter, s1_ingress_pkt_counter__last0_old_value, s1_ingress_pkt_counter__last0_value, s1_ingress_pkt_counter__last_index, s1_ingress_pkt_counter__last_old_value, s1_ingress_pkt_counter__last_value, s1_ingress_pkt_counter__last_write_site, s1_ingress_pkt_counter__next_write_site, s1_ingress_pkt_counter__wrote_any, s1_ingress_pkt_counter__wrote_index0, s1_ingress_src_S, s1_ingress_src_S__last0_old_value, s1_ingress_src_S__last0_value, s1_ingress_src_S__last_index, s1_ingress_src_S__last_old_value, s1_ingress_src_S__last_value, s1_ingress_src_S__last_write_site, s1_ingress_src_S__next_write_site, s1_ingress_src_S__wrote_any, s1_ingress_src_S__wrote_index0, s1_ingress_src_cs1, s1_ingress_src_cs1__last0_old_value, s1_ingress_src_cs1__last0_value, s1_ingress_src_cs1__last_index, s1_ingress_src_cs1__last_old_value, s1_ingress_src_cs1__last_value, s1_ingress_src_cs1__last_write_site, s1_ingress_src_cs1__next_write_site, s1_ingress_src_cs1__wrote_any, s1_ingress_src_cs1__wrote_index0, s1_ingress_src_cs1_ow, s1_ingress_src_cs1_ow__last0_old_value, s1_ingress_src_cs1_ow__last0_value, s1_ingress_src_cs1_ow__last_index, s1_ingress_src_cs1_ow__last_old_value, s1_ingress_src_cs1_ow__last_value, s1_ingress_src_cs1_ow__last_write_site, s1_ingress_src_cs1_ow__next_write_site, s1_ingress_src_cs1_ow__wrote_any, s1_ingress_src_cs1_ow__wrote_index0, s1_ingress_src_cs2, s1_ingress_src_cs2__last0_old_value, s1_ingress_src_cs2__last0_value, s1_ingress_src_cs2__last_index, s1_ingress_src_cs2__last_old_value, s1_ingress_src_cs2__last_value, s1_ingress_src_cs2__last_write_site, s1_ingress_src_cs2__next_write_site, s1_ingress_src_cs2__wrote_any, s1_ingress_src_cs2__wrote_index0, s1_ingress_src_cs2_ow, s1_ingress_src_cs2_ow__last0_old_value, s1_ingress_src_cs2_ow__last0_value, s1_ingress_src_cs2_ow__last_index, s1_ingress_src_cs2_ow__last_old_value, s1_ingress_src_cs2_ow__last_value, s1_ingress_src_cs2_ow__last_write_site, s1_ingress_src_cs2_ow__next_write_site, s1_ingress_src_cs2_ow__wrote_any, s1_ingress_src_cs2_ow__wrote_index0, s1_ingress_src_cs3, s1_ingress_src_cs3__last0_old_value, s1_ingress_src_cs3__last0_value, s1_ingress_src_cs3__last_index, s1_ingress_src_cs3__last_old_value, s1_ingress_src_cs3__last_value, s1_ingress_src_cs3__last_write_site, s1_ingress_src_cs3__next_write_site, s1_ingress_src_cs3__wrote_any, s1_ingress_src_cs3__wrote_index0, s1_ingress_src_cs3_ow, s1_ingress_src_cs3_ow__last0_old_value, s1_ingress_src_cs3_ow__last0_value, s1_ingress_src_cs3_ow__last_index, s1_ingress_src_cs3_ow__last_old_value, s1_ingress_src_cs3_ow__last_value, s1_ingress_src_cs3_ow__last_write_site, s1_ingress_src_cs3_ow__next_write_site, s1_ingress_src_cs3_ow__wrote_any, s1_ingress_src_cs3_ow__wrote_index0, s1_ingress_src_cs4, s1_ingress_src_cs4__last0_old_value, s1_ingress_src_cs4__last0_value, s1_ingress_src_cs4__last_index, s1_ingress_src_cs4__last_old_value, s1_ingress_src_cs4__last_value, s1_ingress_src_cs4__last_write_site, s1_ingress_src_cs4__next_write_site, s1_ingress_src_cs4__wrote_any, s1_ingress_src_cs4__wrote_index0, s1_ingress_src_cs4_ow, s1_ingress_src_cs4_ow__last0_old_value, s1_ingress_src_cs4_ow__last0_value, s1_ingress_src_cs4_ow__last_index, s1_ingress_src_cs4_ow__last_old_value, s1_ingress_src_cs4_ow__last_value, s1_ingress_src_cs4_ow__last_write_site, s1_ingress_src_cs4_ow__next_write_site, s1_ingress_src_cs4_ow__wrote_any, s1_ingress_src_cs4_ow__wrote_index0, s1_ingress_src_entropy_term.action_run, s1_ingress_src_entropy_term.hit, s1_ingress_src_ewma, s1_ingress_src_ewma__last0_old_value, s1_ingress_src_ewma__last0_value, s1_ingress_src_ewma__last_index, s1_ingress_src_ewma__last_old_value, s1_ingress_src_ewma__last_value, s1_ingress_src_ewma__last_write_site, s1_ingress_src_ewma__next_write_site, s1_ingress_src_ewma__wrote_any, s1_ingress_src_ewma__wrote_index0, s1_ingress_src_ewmmd, s1_ingress_src_ewmmd__last0_old_value, s1_ingress_src_ewmmd__last0_value, s1_ingress_src_ewmmd__last_index, s1_ingress_src_ewmmd__last_old_value, s1_ingress_src_ewmmd__last_value, s1_ingress_src_ewmmd__last_write_site, s1_ingress_src_ewmmd__next_write_site, s1_ingress_src_ewmmd__wrote_any, s1_ingress_src_ewmmd__wrote_index0, s1_ingress_training_len__last0_old_value, s1_ingress_training_len__last0_value, s1_ingress_training_len__last_index, s1_ingress_training_len__last_old_value, s1_ingress_training_len__last_value, s1_ingress_training_len__last_write_site, s1_ingress_training_len__next_write_site, s1_ingress_training_len__wrote_any, s1_ingress_training_len__wrote_index0, s1_ipv4_addr_0, s1_ipv4_addr_1, s1_isValid, s1_k_aux_0, s1_log2_m_aux_0, s1_m_0, s1_meta.alarm, s1_meta.dst_entropy, s1_meta.dst_ewma, s1_meta.dst_ewmmd, s1_meta.entropy_term, s1_meta.ip_count, s1_meta.pkt_num, s1_meta.src_entropy, s1_meta.src_ewma, s1_meta.src_ewmmd, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_external, s1_src_S_aux_0, s1_src_c1_0, s1_src_c2_0, s1_src_c3_0, s1_src_c4_0, s1_src_cs1_ow_aux_0, s1_src_cs2_ow_aux_0, s1_src_cs3_ow_aux_0, s1_src_cs4_ow_aux_0, s1_src_g1_0, s1_src_g2_0, s1_src_g3_0, s1_src_g4_0, s1_src_h1_0, s1_src_h2_0, s1_src_h3_0, s1_src_h4_0, s1_src_thresh_0, s1_standard_metadata.checksum_error, s1_standard_metadata.deq_qdepth, s1_standard_metadata.deq_timedelta, s1_standard_metadata.egress_global_timestamp, s1_standard_metadata.egress_port, s1_standard_metadata.egress_rid, s1_standard_metadata.egress_spec, s1_standard_metadata.enq_qdepth, s1_standard_metadata.enq_timestamp, s1_standard_metadata.ingress_global_timestamp, s1_standard_metadata.ingress_port, s1_standard_metadata.instance_type, s1_standard_metadata.mcast_grp, s1_standard_metadata.packet_length, s1_standard_metadata.parser_error, s1_standard_metadata.priority, s1_training_len_aux_0, s1_x1_0, s1_x1_2, s1_x2_0, s1_x2_2, s1_x3_0, s1_x3_2, s1_x4_0, s1_x4_2, s1_y_0, s1_y_2;
{
  call mainProcedure();
}

// ===== END HARNESS =====
