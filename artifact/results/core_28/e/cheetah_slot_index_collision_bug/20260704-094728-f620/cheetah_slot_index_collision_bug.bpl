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
type s1_EthernetAddress = bv48;
type s1_ethernet_t;
type s1_ipv4_t;
type s1_tcp_t;
type s1_Tcp_option_end_h;
type s1_Tcp_option_nop_h;
type s1_Tcp_option_sz_h;
type s1_Tcp_option_ss_h;
type s1_Tcp_option_s_h;
type s1_Tcp_option_sack_h;
type s1_Tcp_option_timestamp_h;
type s1_Tcp_option_ss_e;
type s1_Tcp_option_sack_e;
type s1_Tcp_option_timestamp_e;
type s1_Tcp_option_padding_h;

// s1_Struct s1_headers
var s1_hdr:s1_Ref;

// s1_Header s1_ethernet_t
var s1_hdr.ethernet:s1_Ref;
var s1_hdr.ethernet.valid:bool;
var s1_hdr.ethernet.dstAddr:s1_EthernetAddress;
var s1_hdr.ethernet.srcAddr:s1_EthernetAddress;
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
var s1_hdr.tcp.urg:bv1;
var s1_hdr.tcp.ack:bv1;
var s1_hdr.tcp.psh:bv1;
var s1_hdr.tcp.rst:bv1;
var s1_hdr.tcp.syn:bv1;
var s1_hdr.tcp.fin:bv1;
var s1_hdr.tcp.window:bv16;
var s1_hdr.tcp.checksum:bv16;
var s1_hdr.tcp.urgentPtr:bv16;

// s1_Header s1_Tcp_option_nop_h
var s1_hdr.nop1:s1_Ref;
var s1_hdr.nop1.valid:bool;
var s1_hdr.nop1.kind:bv8;

// s1_Header s1_Tcp_option_nop_h
var s1_hdr.nop2:s1_Ref;
var s1_hdr.nop2.valid:bool;
var s1_hdr.nop2.kind:bv8;

// s1_Header s1_Tcp_option_ss_e
var s1_hdr.ss:s1_Ref;
var s1_hdr.ss.valid:bool;
var s1_hdr.ss.length:bv8;
var s1_hdr.ss.maxSegmentSize:bv16;

// s1_Header s1_Tcp_option_nop_h
var s1_hdr.nop3:s1_Ref;
var s1_hdr.nop3.valid:bool;
var s1_hdr.nop3.kind:bv8;

// s1_Header s1_Tcp_option_sz_h
var s1_hdr.sackw:s1_Ref;
var s1_hdr.sackw.valid:bool;
var s1_hdr.sackw.length:bv8;

// s1_Header s1_Tcp_option_sack_e
var s1_hdr.sack:s1_Ref;
var s1_hdr.sack.valid:bool;
var s1_hdr.sack.sack:bv256;

// s1_Header s1_Tcp_option_nop_h
var s1_hdr.nop4:s1_Ref;
var s1_hdr.nop4.valid:bool;
var s1_hdr.nop4.kind:bv8;

// s1_Header s1_Tcp_option_timestamp_e
var s1_hdr.timestamp:s1_Ref;
var s1_hdr.timestamp.valid:bool;
var s1_hdr.timestamp.length:bv8;
var s1_hdr.timestamp.tsval_msb:bv16;
var s1_hdr.timestamp.tsval_lsb:bv16;
var s1_hdr.timestamp.tsecr_msb:bv16;
var s1_hdr.timestamp.tsecr_lsb:bv16;

// s1_Struct s1_fwd_metadata_t
type s1_fwd_metadata_t;

// s1_Struct s1_metadata
type s1_metadata;
var s1_meta.bucket_id:bv16;
var s1_meta.packet_hash:bv16;
var s1_meta.server_id:bv16;

// s1_Struct s1_Tcp_option_sack_top
type s1_Tcp_option_sack_top;
var s1_meta:s1_metadata;
var s1_standard_metadata:s1_standard_metadata_t;
var s1_free_index_value_0:bv16;
var s1_push_index_value_0:bv16;
var s1_pop_index_value_0:bv16;
var s1_server_id_0:bv16;
var s1_stored_hash_0:bv16;
var s1_offset_0:bv16;
var s1_offset_unit_0:bv16;
var s1_ip_addr_one_0:bv32;
var s1_tcp_port_one_0:bv16;
var s1_tcp_port_two_0:bv16;
var s1_ip_protocol_0:bv8;

// s1_Register s1_MyIngress_bucket_counter
var s1_MyIngress_bucket_counter:[bv32]bv16;
var s1_MyIngress_bucket_counter__last_index:bv32;
var s1_MyIngress_bucket_counter__last_value:bv16;
var s1_MyIngress_bucket_counter__last_old_value:bv16;
var s1_MyIngress_bucket_counter__wrote_any:bool;
var s1_MyIngress_bucket_counter__wrote_index0:bool;
var s1_MyIngress_bucket_counter__last0_old_value:bv16;
var s1_MyIngress_bucket_counter__last0_value:bv16;
var s1_MyIngress_bucket_counter__next_write_site:int;
var s1_MyIngress_bucket_counter__last_write_site:int;
const s1_MyIngress_bucket_counter.size:bv32;
axiom s1_MyIngress_bucket_counter.size == 1bv32;

// s1_Register s1_MyIngress_debug_hash
var s1_MyIngress_debug_hash:[bv32]bv16;
var s1_MyIngress_debug_hash__last_index:bv32;
var s1_MyIngress_debug_hash__last_value:bv16;
var s1_MyIngress_debug_hash__last_old_value:bv16;
var s1_MyIngress_debug_hash__wrote_any:bool;
var s1_MyIngress_debug_hash__wrote_index0:bool;
var s1_MyIngress_debug_hash__last0_old_value:bv16;
var s1_MyIngress_debug_hash__last0_value:bv16;
var s1_MyIngress_debug_hash__next_write_site:int;
var s1_MyIngress_debug_hash__last_write_site:int;
const s1_MyIngress_debug_hash.size:bv32;
axiom s1_MyIngress_debug_hash.size == 1bv32;

// s1_Register s1_MyIngress_index_to_hash
var s1_MyIngress_index_to_hash:[bv32]bv16;
var s1_MyIngress_index_to_hash__last_index:bv32;
var s1_MyIngress_index_to_hash__last_value:bv16;
var s1_MyIngress_index_to_hash__last_old_value:bv16;
var s1_MyIngress_index_to_hash__wrote_any:bool;
var s1_MyIngress_index_to_hash__wrote_index0:bool;
var s1_MyIngress_index_to_hash__last0_old_value:bv16;
var s1_MyIngress_index_to_hash__last0_value:bv16;
var s1_MyIngress_index_to_hash__next_write_site:int;
var s1_MyIngress_index_to_hash__last_write_site:int;
const s1_MyIngress_index_to_hash.size:bv32;
axiom s1_MyIngress_index_to_hash.size == 20bv32;

// s1_Register s1_MyIngress_index_to_server_id
var s1_MyIngress_index_to_server_id:[bv32]bv16;
var s1_MyIngress_index_to_server_id__last_index:bv32;
var s1_MyIngress_index_to_server_id__last_value:bv16;
var s1_MyIngress_index_to_server_id__last_old_value:bv16;
var s1_MyIngress_index_to_server_id__wrote_any:bool;
var s1_MyIngress_index_to_server_id__wrote_index0:bool;
var s1_MyIngress_index_to_server_id__last0_old_value:bv16;
var s1_MyIngress_index_to_server_id__last0_value:bv16;
var s1_MyIngress_index_to_server_id__next_write_site:int;
var s1_MyIngress_index_to_server_id__last_write_site:int;
const s1_MyIngress_index_to_server_id.size:bv32;
axiom s1_MyIngress_index_to_server_id.size == 20bv32;

// s1_Register s1_MyIngress_free_indices
var s1_MyIngress_free_indices:[bv32]bv16;
var s1_MyIngress_free_indices__last_index:bv32;
var s1_MyIngress_free_indices__last_value:bv16;
var s1_MyIngress_free_indices__last_old_value:bv16;
var s1_MyIngress_free_indices__wrote_any:bool;
var s1_MyIngress_free_indices__wrote_index0:bool;
var s1_MyIngress_free_indices__last0_old_value:bv16;
var s1_MyIngress_free_indices__last0_value:bv16;
var s1_MyIngress_free_indices__next_write_site:int;
var s1_MyIngress_free_indices__last_write_site:int;
const s1_MyIngress_free_indices.size:bv32;
axiom s1_MyIngress_free_indices.size == 20bv32;

// s1_Register s1_MyIngress_push_index
var s1_MyIngress_push_index:[bv32]bv16;
var s1_MyIngress_push_index__last_index:bv32;
var s1_MyIngress_push_index__last_value:bv16;
var s1_MyIngress_push_index__last_old_value:bv16;
var s1_MyIngress_push_index__wrote_any:bool;
var s1_MyIngress_push_index__wrote_index0:bool;
var s1_MyIngress_push_index__last0_old_value:bv16;
var s1_MyIngress_push_index__last0_value:bv16;
var s1_MyIngress_push_index__next_write_site:int;
var s1_MyIngress_push_index__last_write_site:int;
const s1_MyIngress_push_index.size:bv32;
axiom s1_MyIngress_push_index.size == 2bv32;

// s1_Register s1_MyIngress_pop_index
var s1_MyIngress_pop_index:[bv32]bv16;
var s1_MyIngress_pop_index__last_index:bv32;
var s1_MyIngress_pop_index__last_value:bv16;
var s1_MyIngress_pop_index__last_old_value:bv16;
var s1_MyIngress_pop_index__wrote_any:bool;
var s1_MyIngress_pop_index__wrote_index0:bool;
var s1_MyIngress_pop_index__last0_old_value:bv16;
var s1_MyIngress_pop_index__last0_value:bv16;
var s1_MyIngress_pop_index__next_write_site:int;
var s1_MyIngress_pop_index__last_write_site:int;
const s1_MyIngress_pop_index.size:bv32;
axiom s1_MyIngress_pop_index.size == 2bv32;

function {:builtin "bvlshr"} shr.bv16(s1_left:bv16, s1_right:bv16) returns(bv16);

function {:builtin "bvxor"} bxor.bv16(s1_left:bv16, s1_right:bv16) returns(bv16);
function {:inline true} s1___p4b_crc16_bmv2_bit(s1_crc:bv16) returns(bv16) { (if (s1_crc)[1:0] == 1bv1 then bxor.bv16(shr.bv16(s1_crc, 1bv16), 40961bv16) else shr.bv16(s1_crc, 1bv16)) }
function {:inline true} s1___p4b_crc16_bmv2_byte(s1_crc:bv16, s1_byte:bv8) returns(bv16) { s1___p4b_crc16_bmv2_bit(s1___p4b_crc16_bmv2_bit(s1___p4b_crc16_bmv2_bit(s1___p4b_crc16_bmv2_bit(s1___p4b_crc16_bmv2_bit(s1___p4b_crc16_bmv2_bit(s1___p4b_crc16_bmv2_bit(s1___p4b_crc16_bmv2_bit(bxor.bv16(s1_crc, 0bv8++(s1_byte)))))))))) }

function {:builtin "bvadd"} add.bv16(s1_left:bv16, s1_right:bv16) returns(bv16);

function {:builtin "bvurem"} urem.bv16(s1_left:bv16, s1_right:bv16) returns(bv16);

function {:builtin "bvuge"} buge.bv16(s1_left:bv16, s1_right:bv16) returns(bool);

function {:builtin "bvule"} bule.bv16(s1_left:bv16, s1_right:bv16) returns(bool);

// s1_Table s1_MyIngress_get_server_from_bucket s1_Actionlist s1_Declaration
type s1_MyIngress_get_server_from_bucket.action;
var s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2:bv16;
var s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip:bv32;
var s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server:bv48;
var s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input:bv16;
const unique s1_MyIngress_get_server_from_bucket.action.MyIngress_fwd : s1_MyIngress_get_server_from_bucket.action;
const unique s1_MyIngress_get_server_from_bucket.action.NoAction : s1_MyIngress_get_server_from_bucket.action;
var s1_MyIngress_get_server_from_bucket.action_run : s1_MyIngress_get_server_from_bucket.action;
var s1_MyIngress_get_server_from_bucket.hit : bool;

// s1_Table s1_MyIngress_get_server_from_id s1_Actionlist s1_Declaration
type s1_MyIngress_get_server_from_id.action;
var s1_MyIngress_get_server_from_id.MyIngress_fwd_2.egress_port_3:bv16;
var s1_MyIngress_get_server_from_id.MyIngress_fwd_2.dip_2:bv32;
var s1_MyIngress_get_server_from_id.MyIngress_fwd_2.mac_server_2:bv48;
const unique s1_MyIngress_get_server_from_id.action.MyIngress_fwd_2 : s1_MyIngress_get_server_from_id.action;
const unique s1_MyIngress_get_server_from_id.action.NoAction_2 : s1_MyIngress_get_server_from_id.action;
var s1_MyIngress_get_server_from_id.action_run : s1_MyIngress_get_server_from_id.action;
var s1_MyIngress_get_server_from_id.hit : bool;

function {:builtin "bvsub"} sub.bv17(s1_left:bv17, s1_right:bv17) returns(bv17);

function {:builtin "bvsub"} sub.bv33(s1_left:bv33, s1_right:bv33) returns(bv33);

// s1_Control s1_MyComputeChecksum
procedure {:inline 1} s1_MyComputeChecksum()
{
}

// s1_Control s1_MyEgress
procedure {:inline 1} s1_MyEgress()
{
}

// s1_Control s1_MyIngress
procedure {:inline 1} s1_MyIngress()
	modifies s1_MyIngress_bucket_counter, s1_MyIngress_bucket_counter__last0_old_value, s1_MyIngress_bucket_counter__last0_value, s1_MyIngress_bucket_counter__last_index, s1_MyIngress_bucket_counter__last_old_value, s1_MyIngress_bucket_counter__last_value, s1_MyIngress_bucket_counter__last_write_site, s1_MyIngress_bucket_counter__next_write_site, s1_MyIngress_bucket_counter__wrote_any, s1_MyIngress_bucket_counter__wrote_index0, s1_MyIngress_debug_hash, s1_MyIngress_debug_hash__last0_old_value, s1_MyIngress_debug_hash__last0_value, s1_MyIngress_debug_hash__last_index, s1_MyIngress_debug_hash__last_old_value, s1_MyIngress_debug_hash__last_value, s1_MyIngress_debug_hash__last_write_site, s1_MyIngress_debug_hash__next_write_site, s1_MyIngress_debug_hash__wrote_any, s1_MyIngress_debug_hash__wrote_index0, s1_MyIngress_free_indices, s1_MyIngress_free_indices__last0_old_value, s1_MyIngress_free_indices__last0_value, s1_MyIngress_free_indices__last_index, s1_MyIngress_free_indices__last_old_value, s1_MyIngress_free_indices__last_value, s1_MyIngress_free_indices__last_write_site, s1_MyIngress_free_indices__next_write_site, s1_MyIngress_free_indices__wrote_any, s1_MyIngress_free_indices__wrote_index0, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input, s1_MyIngress_get_server_from_bucket.action_run, s1_MyIngress_get_server_from_bucket.hit, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.dip_2, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.egress_port_3, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.mac_server_2, s1_MyIngress_get_server_from_id.action_run, s1_MyIngress_get_server_from_id.hit, s1_MyIngress_index_to_hash, s1_MyIngress_index_to_hash__last0_old_value, s1_MyIngress_index_to_hash__last0_value, s1_MyIngress_index_to_hash__last_index, s1_MyIngress_index_to_hash__last_old_value, s1_MyIngress_index_to_hash__last_value, s1_MyIngress_index_to_hash__last_write_site, s1_MyIngress_index_to_hash__next_write_site, s1_MyIngress_index_to_hash__wrote_any, s1_MyIngress_index_to_hash__wrote_index0, s1_MyIngress_index_to_server_id, s1_MyIngress_index_to_server_id__last0_old_value, s1_MyIngress_index_to_server_id__last0_value, s1_MyIngress_index_to_server_id__last_index, s1_MyIngress_index_to_server_id__last_old_value, s1_MyIngress_index_to_server_id__last_value, s1_MyIngress_index_to_server_id__last_write_site, s1_MyIngress_index_to_server_id__next_write_site, s1_MyIngress_index_to_server_id__wrote_any, s1_MyIngress_index_to_server_id__wrote_index0, s1_MyIngress_pop_index, s1_MyIngress_pop_index__last0_old_value, s1_MyIngress_pop_index__last0_value, s1_MyIngress_pop_index__last_index, s1_MyIngress_pop_index__last_old_value, s1_MyIngress_pop_index__last_value, s1_MyIngress_pop_index__last_write_site, s1_MyIngress_pop_index__next_write_site, s1_MyIngress_pop_index__wrote_any, s1_MyIngress_pop_index__wrote_index0, s1_MyIngress_push_index, s1_MyIngress_push_index__last0_old_value, s1_MyIngress_push_index__last0_value, s1_MyIngress_push_index__last_index, s1_MyIngress_push_index__last_old_value, s1_MyIngress_push_index__last_value, s1_MyIngress_push_index__last_write_site, s1_MyIngress_push_index__next_write_site, s1_MyIngress_push_index__wrote_any, s1_MyIngress_push_index__wrote_index0, s1_drop, s1_forward, s1_free_index_value_0, s1_hdr.ethernet.dstAddr, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.srcAddr, s1_hdr.timestamp.tsecr_lsb, s1_ip_addr_one_0, s1_ip_protocol_0, s1_meta.bucket_id, s1_meta.packet_hash, s1_meta.server_id, s1_offset_0, s1_offset_unit_0, s1_pop_index_value_0, s1_push_index_value_0, s1_server_id_0, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_stored_hash_0, s1_tcp_port_one_0, s1_tcp_port_two_0;
{
havoc s1_free_index_value_0;
havoc s1_push_index_value_0;
havoc s1_pop_index_value_0;
havoc s1_server_id_0;
havoc s1_stored_hash_0;
havoc s1_offset_0;
havoc s1_offset_unit_0;
havoc s1_ip_addr_one_0;
havoc s1_tcp_port_one_0;
havoc s1_tcp_port_two_0;
havoc s1_ip_protocol_0;
    s1_offset_0 := 0bv16;
    s1_offset_unit_0 := 0bv16;
    s1_server_id_0 := 0bv16;
    if(s1_isValid[s1_hdr.ipv4]){
        if((s1_hdr.ipv4.dstAddr == 167772414bv32)){
            if(s1_isValid[s1_hdr.tcp]){
                call s1_MyIngress_compute_packet_hash();
                if((s1_meta.packet_hash[1:0] == 1bv1)){
                    s1_offset_0 := 10bv16;
                    s1_offset_unit_0 := 1bv16;
                }
                if((s1_hdr.tcp.syn == 0bv1)){
                    // s1_read
                    s1_stored_hash_0 := s1_MyIngress_index_to_hash.read(s1_MyIngress_index_to_hash, 0bv16++add.bv16(s1_hdr.timestamp.tsecr_lsb, s1_offset_0));
                    if((s1_meta.packet_hash != s1_stored_hash_0)){
                        call s1_mark_to_drop();
                    }
                    else{
                        // s1_read
                        s1_meta.server_id := s1_MyIngress_index_to_server_id.read(s1_MyIngress_index_to_server_id, 0bv16++add.bv16(s1_hdr.timestamp.tsecr_lsb, s1_offset_0));
                        call s1_MyIngress_get_server_from_id.apply();
                        if((s1_hdr.tcp.fin == 1bv1)){
                            // s1_read
                            s1_push_index_value_0 := s1_MyIngress_push_index.read(s1_MyIngress_push_index, 0bv16++s1_offset_unit_0);
                            // s1_write
                            s1_MyIngress_free_indices__next_write_site := 1;
                            call s1_MyIngress_free_indices.write(0bv16++add.bv16(s1_push_index_value_0, s1_offset_0), s1_hdr.timestamp.tsecr_lsb);
                            s1_push_index_value_0 := add.bv16(s1_push_index_value_0, 1bv16);
                            if((s1_push_index_value_0 == add.bv16(s1_offset_0, 10bv16))){
                                s1_push_index_value_0 := s1_offset_0;
                            }
                            // s1_write
                            s1_MyIngress_push_index__next_write_site := 1;
                            call s1_MyIngress_push_index.write(0bv16++s1_offset_unit_0, s1_push_index_value_0);
                            // s1_write
                            s1_MyIngress_index_to_hash__next_write_site := 1;
                            call s1_MyIngress_index_to_hash.write(0bv16++add.bv16(s1_hdr.timestamp.tsecr_lsb, s1_offset_0), 65535bv16);
                            // s1_write
                            s1_MyIngress_index_to_server_id__next_write_site := 1;
                            call s1_MyIngress_index_to_server_id.write(0bv16++add.bv16(s1_hdr.timestamp.tsecr_lsb, s1_offset_0), 65535bv16);
                        }
                    }
                }
                else{
                    // s1_read
                    s1_meta.bucket_id := s1_MyIngress_bucket_counter.read(s1_MyIngress_bucket_counter, 0bv32);
                    call s1_MyIngress_get_server_from_bucket.apply();
                    s1_meta.bucket_id := add.bv16(s1_meta.bucket_id, 1bv16);
                    if((s1_meta.bucket_id == 6bv16)){
                        s1_meta.bucket_id := 0bv16;
                    }
                    // s1_write
                    s1_MyIngress_bucket_counter__next_write_site := 1;
                    call s1_MyIngress_bucket_counter.write(0bv32, s1_meta.bucket_id);
                    // s1_read
                    s1_pop_index_value_0 := s1_MyIngress_pop_index.read(s1_MyIngress_pop_index, 0bv16++s1_offset_unit_0);
                    // s1_read
                    s1_free_index_value_0 := s1_MyIngress_free_indices.read(s1_MyIngress_free_indices, 0bv16++add.bv16(s1_pop_index_value_0, s1_offset_0));
                    // s1_write
                    s1_MyIngress_free_indices__next_write_site := 2;
                    call s1_MyIngress_free_indices.write(0bv16++add.bv16(s1_pop_index_value_0, s1_offset_0), 65535bv16);
                    s1_pop_index_value_0 := add.bv16(s1_pop_index_value_0, 1bv16);
                    if((s1_pop_index_value_0 == add.bv16(s1_offset_0, 10bv16))){
                        s1_pop_index_value_0 := s1_offset_0;
                    }
                    // s1_write
                    s1_MyIngress_pop_index__next_write_site := 1;
                    call s1_MyIngress_pop_index.write(0bv16++s1_offset_unit_0, s1_pop_index_value_0);
                    // s1_write
                    s1_MyIngress_index_to_hash__next_write_site := 2;
                    call s1_MyIngress_index_to_hash.write(0bv16++add.bv16(s1_free_index_value_0, s1_offset_0), s1_meta.packet_hash);
                    // s1_write
                    s1_MyIngress_index_to_server_id__next_write_site := 2;
                    call s1_MyIngress_index_to_server_id.write(0bv16++add.bv16(s1_free_index_value_0, s1_offset_0), s1_server_id_0);
                    s1_hdr.timestamp.tsecr_lsb := s1_free_index_value_0;
                }
            }
        }
        else{
            if(s1_isValid[s1_hdr.tcp]){
                s1_standard_metadata.egress_spec := 1bv9;
                s1_standard_metadata.egress_port := 1bv9;
                s1_forward := true;
                s1_hdr.ethernet.dstAddr := 167772161bv48;
                s1_hdr.ipv4.srcAddr := 167772414bv32;
            }
        }
    }
}
function {:inline true}s1_MyIngress_bucket_counter.read(s1_reg:[bv32]bv16, s1_index:bv32)returns (bv16) {s1_reg[s1_index]}
procedure {:inline 1} s1_MyIngress_bucket_counter.write(s1_index:bv32, s1_value:bv16)
	modifies s1_MyIngress_bucket_counter, s1_MyIngress_bucket_counter__last0_old_value, s1_MyIngress_bucket_counter__last0_value, s1_MyIngress_bucket_counter__last_index, s1_MyIngress_bucket_counter__last_old_value, s1_MyIngress_bucket_counter__last_value, s1_MyIngress_bucket_counter__last_write_site, s1_MyIngress_bucket_counter__wrote_any, s1_MyIngress_bucket_counter__wrote_index0;
{
    s1_MyIngress_bucket_counter__last_old_value := s1_MyIngress_bucket_counter[s1_index];
    s1_MyIngress_bucket_counter[s1_index] := s1_value;
    s1_MyIngress_bucket_counter__last_index := s1_index;
    s1_MyIngress_bucket_counter__last_value := s1_value;
    s1_MyIngress_bucket_counter__last_write_site := s1_MyIngress_bucket_counter__next_write_site;
    s1_MyIngress_bucket_counter__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_MyIngress_bucket_counter__wrote_index0 := true;
        s1_MyIngress_bucket_counter__last0_old_value := s1_MyIngress_bucket_counter__last_old_value;
        s1_MyIngress_bucket_counter__last0_value := s1_value;
    }
}

// s1_Action s1_MyIngress_compute_packet_hash
procedure {:inline 1} s1_MyIngress_compute_packet_hash()
	modifies s1_MyIngress_debug_hash, s1_MyIngress_debug_hash__last0_old_value, s1_MyIngress_debug_hash__last0_value, s1_MyIngress_debug_hash__last_index, s1_MyIngress_debug_hash__last_old_value, s1_MyIngress_debug_hash__last_value, s1_MyIngress_debug_hash__last_write_site, s1_MyIngress_debug_hash__next_write_site, s1_MyIngress_debug_hash__wrote_any, s1_MyIngress_debug_hash__wrote_index0, s1_ip_addr_one_0, s1_ip_protocol_0, s1_meta.packet_hash, s1_tcp_port_one_0, s1_tcp_port_two_0;
{
    s1_ip_addr_one_0 := s1_hdr.ipv4.srcAddr;
    s1_tcp_port_one_0 := s1_hdr.tcp.dstPort;
    s1_tcp_port_two_0 := s1_hdr.tcp.srcPort;
    s1_ip_protocol_0 := s1_hdr.ipv4.protocol;
    // s1_p4b_hash_model: s1_builtin s1_algorithm=s1_HashAlgorithm.crc16 s1_model=s1_crc16_bmv2 s1_precision=s1_precise
    s1_meta.packet_hash := (if 65535bv16 == 0bv16 then 0bv16 else add.bv16(0bv16, urem.bv16(s1___p4b_crc16_bmv2_byte(s1___p4b_crc16_bmv2_byte(s1___p4b_crc16_bmv2_byte(s1___p4b_crc16_bmv2_byte(s1___p4b_crc16_bmv2_byte(s1___p4b_crc16_bmv2_byte(s1___p4b_crc16_bmv2_byte(s1___p4b_crc16_bmv2_byte(s1___p4b_crc16_bmv2_byte(0bv16, (s1_ip_addr_one_0++s1_tcp_port_one_0++s1_tcp_port_two_0++s1_ip_protocol_0)[72:64]), (s1_ip_addr_one_0++s1_tcp_port_one_0++s1_tcp_port_two_0++s1_ip_protocol_0)[64:56]), (s1_ip_addr_one_0++s1_tcp_port_one_0++s1_tcp_port_two_0++s1_ip_protocol_0)[56:48]), (s1_ip_addr_one_0++s1_tcp_port_one_0++s1_tcp_port_two_0++s1_ip_protocol_0)[48:40]), (s1_ip_addr_one_0++s1_tcp_port_one_0++s1_tcp_port_two_0++s1_ip_protocol_0)[40:32]), (s1_ip_addr_one_0++s1_tcp_port_one_0++s1_tcp_port_two_0++s1_ip_protocol_0)[32:24]), (s1_ip_addr_one_0++s1_tcp_port_one_0++s1_tcp_port_two_0++s1_ip_protocol_0)[24:16]), (s1_ip_addr_one_0++s1_tcp_port_one_0++s1_tcp_port_two_0++s1_ip_protocol_0)[16:8]), (s1_ip_addr_one_0++s1_tcp_port_one_0++s1_tcp_port_two_0++s1_ip_protocol_0)[8:0]), 65535bv16)));
    assume(buge.bv16(s1_meta.packet_hash, 0bv16) && bule.bv16(s1_meta.packet_hash, 65534bv16));
    // s1_write
    s1_MyIngress_debug_hash__next_write_site := 1;
    call s1_MyIngress_debug_hash.write(0bv32, s1_meta.packet_hash);
}
function {:inline true}s1_MyIngress_debug_hash.read(s1_reg:[bv32]bv16, s1_index:bv32)returns (bv16) {s1_reg[s1_index]}
procedure {:inline 1} s1_MyIngress_debug_hash.write(s1_index:bv32, s1_value:bv16)
	modifies s1_MyIngress_debug_hash, s1_MyIngress_debug_hash__last0_old_value, s1_MyIngress_debug_hash__last0_value, s1_MyIngress_debug_hash__last_index, s1_MyIngress_debug_hash__last_old_value, s1_MyIngress_debug_hash__last_value, s1_MyIngress_debug_hash__last_write_site, s1_MyIngress_debug_hash__wrote_any, s1_MyIngress_debug_hash__wrote_index0;
{
    s1_MyIngress_debug_hash__last_old_value := s1_MyIngress_debug_hash[s1_index];
    s1_MyIngress_debug_hash[s1_index] := s1_value;
    s1_MyIngress_debug_hash__last_index := s1_index;
    s1_MyIngress_debug_hash__last_value := s1_value;
    s1_MyIngress_debug_hash__last_write_site := s1_MyIngress_debug_hash__next_write_site;
    s1_MyIngress_debug_hash__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_MyIngress_debug_hash__wrote_index0 := true;
        s1_MyIngress_debug_hash__last0_old_value := s1_MyIngress_debug_hash__last_old_value;
        s1_MyIngress_debug_hash__last0_value := s1_value;
    }
}
function {:inline true}s1_MyIngress_free_indices.read(s1_reg:[bv32]bv16, s1_index:bv32)returns (bv16) {s1_reg[s1_index]}
procedure {:inline 1} s1_MyIngress_free_indices.write(s1_index:bv32, s1_value:bv16)
	modifies s1_MyIngress_free_indices, s1_MyIngress_free_indices__last0_old_value, s1_MyIngress_free_indices__last0_value, s1_MyIngress_free_indices__last_index, s1_MyIngress_free_indices__last_old_value, s1_MyIngress_free_indices__last_value, s1_MyIngress_free_indices__last_write_site, s1_MyIngress_free_indices__wrote_any, s1_MyIngress_free_indices__wrote_index0;
{
    s1_MyIngress_free_indices__last_old_value := s1_MyIngress_free_indices[s1_index];
    s1_MyIngress_free_indices[s1_index] := s1_value;
    s1_MyIngress_free_indices__last_index := s1_index;
    s1_MyIngress_free_indices__last_value := s1_value;
    s1_MyIngress_free_indices__last_write_site := s1_MyIngress_free_indices__next_write_site;
    s1_MyIngress_free_indices__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_MyIngress_free_indices__wrote_index0 := true;
        s1_MyIngress_free_indices__last0_old_value := s1_MyIngress_free_indices__last_old_value;
        s1_MyIngress_free_indices__last0_value := s1_value;
    }
}

// s1_Action s1_MyIngress_fwd
procedure {:inline 1} s1_MyIngress_fwd(s1_egress_port_2:bv16, s1_dip:bv32, s1_mac_server:bv48, s1_server_id_input:bv16)
	modifies s1_forward, s1_hdr.ethernet.dstAddr, s1_hdr.ipv4.dstAddr, s1_server_id_0, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    s1_hdr.ipv4.dstAddr := s1_dip;
    s1_hdr.ethernet.dstAddr := s1_mac_server;
    s1_standard_metadata.egress_spec := s1_egress_port_2[9:0];
    s1_standard_metadata.egress_port := s1_egress_port_2[9:0];
    s1_forward := true;
    s1_server_id_0 := s1_server_id_input;
}

// s1_Action s1_MyIngress_fwd_2
procedure {:inline 1} s1_MyIngress_fwd_2(s1_egress_port_3:bv16, s1_dip_2:bv32, s1_mac_server_2:bv48)
	modifies s1_forward, s1_hdr.ethernet.dstAddr, s1_hdr.ipv4.dstAddr, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    s1_hdr.ipv4.dstAddr := s1_dip_2;
    s1_hdr.ethernet.dstAddr := s1_mac_server_2;
    s1_standard_metadata.egress_spec := s1_egress_port_3[9:0];
    s1_standard_metadata.egress_port := s1_egress_port_3[9:0];
    s1_forward := true;
}

// s1_Table s1_MyIngress_get_server_from_bucket
procedure {:inline 1} s1_MyIngress_get_server_from_bucket.apply()
	modifies s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input, s1_MyIngress_get_server_from_bucket.action_run, s1_MyIngress_get_server_from_bucket.hit, s1_forward, s1_hdr.ethernet.dstAddr, s1_hdr.ipv4.dstAddr, s1_meta.bucket_id, s1_server_id_0, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    s1_meta.bucket_id := s1_meta.bucket_id;
    s1_MyIngress_get_server_from_bucket.hit := false;
    if(s1_meta.bucket_id == 0bv16){
        s1_MyIngress_get_server_from_bucket.hit := true;
        s1_MyIngress_get_server_from_bucket.action_run := s1_MyIngress_get_server_from_bucket.action.MyIngress_fwd;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2 := 2bv16;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip := 167772162bv32;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server := 167772162bv48;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input := 0bv16;
        call s1_MyIngress_fwd(s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input);
        goto s1_Exit;
    }
    else if(s1_meta.bucket_id == 1bv16){
        s1_MyIngress_get_server_from_bucket.hit := true;
        s1_MyIngress_get_server_from_bucket.action_run := s1_MyIngress_get_server_from_bucket.action.MyIngress_fwd;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2 := 2bv16;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip := 167772162bv32;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server := 167772162bv48;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input := 0bv16;
        call s1_MyIngress_fwd(s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input);
        goto s1_Exit;
    }
    else if(s1_meta.bucket_id == 2bv16){
        s1_MyIngress_get_server_from_bucket.hit := true;
        s1_MyIngress_get_server_from_bucket.action_run := s1_MyIngress_get_server_from_bucket.action.MyIngress_fwd;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2 := 2bv16;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip := 167772162bv32;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server := 167772162bv48;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input := 0bv16;
        call s1_MyIngress_fwd(s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input);
        goto s1_Exit;
    }
    else if(s1_meta.bucket_id == 3bv16){
        s1_MyIngress_get_server_from_bucket.hit := true;
        s1_MyIngress_get_server_from_bucket.action_run := s1_MyIngress_get_server_from_bucket.action.MyIngress_fwd;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2 := 2bv16;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip := 167772162bv32;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server := 167772162bv48;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input := 0bv16;
        call s1_MyIngress_fwd(s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input);
        goto s1_Exit;
    }
    else if(s1_meta.bucket_id == 4bv16){
        s1_MyIngress_get_server_from_bucket.hit := true;
        s1_MyIngress_get_server_from_bucket.action_run := s1_MyIngress_get_server_from_bucket.action.MyIngress_fwd;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2 := 3bv16;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip := 167772163bv32;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server := 167772163bv48;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input := 1bv16;
        call s1_MyIngress_fwd(s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input);
        goto s1_Exit;
    }
    else if(s1_meta.bucket_id == 5bv16){
        s1_MyIngress_get_server_from_bucket.hit := true;
        s1_MyIngress_get_server_from_bucket.action_run := s1_MyIngress_get_server_from_bucket.action.MyIngress_fwd;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2 := 3bv16;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip := 167772163bv32;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server := 167772163bv48;
        s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input := 1bv16;
        call s1_MyIngress_fwd(s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input);
        goto s1_Exit;
    }
    if(!s1_MyIngress_get_server_from_bucket.hit){
        s1_MyIngress_get_server_from_bucket.action_run := s1_MyIngress_get_server_from_bucket.action.NoAction;
        call s1_NoAction();
        goto s1_Exit;
    }

    s1_Exit:
}

// s1_Table s1_MyIngress_get_server_from_id
procedure {:inline 1} s1_MyIngress_get_server_from_id.apply()
	modifies s1_MyIngress_get_server_from_id.MyIngress_fwd_2.dip_2, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.egress_port_3, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.mac_server_2, s1_MyIngress_get_server_from_id.action_run, s1_MyIngress_get_server_from_id.hit, s1_forward, s1_hdr.ethernet.dstAddr, s1_hdr.ipv4.dstAddr, s1_meta.server_id, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec;
{
    s1_meta.server_id := s1_meta.server_id;
    s1_MyIngress_get_server_from_id.hit := false;
    if(s1_meta.server_id == 0bv16){
        s1_MyIngress_get_server_from_id.hit := true;
        s1_MyIngress_get_server_from_id.action_run := s1_MyIngress_get_server_from_id.action.MyIngress_fwd_2;
        s1_MyIngress_get_server_from_id.MyIngress_fwd_2.egress_port_3 := 2bv16;
        s1_MyIngress_get_server_from_id.MyIngress_fwd_2.dip_2 := 167772162bv32;
        s1_MyIngress_get_server_from_id.MyIngress_fwd_2.mac_server_2 := 167772162bv48;
        call s1_MyIngress_fwd_2(s1_MyIngress_get_server_from_id.MyIngress_fwd_2.egress_port_3, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.dip_2, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.mac_server_2);
        goto s1_Exit;
    }
    else if(s1_meta.server_id == 1bv16){
        s1_MyIngress_get_server_from_id.hit := true;
        s1_MyIngress_get_server_from_id.action_run := s1_MyIngress_get_server_from_id.action.MyIngress_fwd_2;
        s1_MyIngress_get_server_from_id.MyIngress_fwd_2.egress_port_3 := 3bv16;
        s1_MyIngress_get_server_from_id.MyIngress_fwd_2.dip_2 := 167772163bv32;
        s1_MyIngress_get_server_from_id.MyIngress_fwd_2.mac_server_2 := 167772163bv48;
        call s1_MyIngress_fwd_2(s1_MyIngress_get_server_from_id.MyIngress_fwd_2.egress_port_3, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.dip_2, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.mac_server_2);
        goto s1_Exit;
    }
    if(!s1_MyIngress_get_server_from_id.hit){
        s1_MyIngress_get_server_from_id.action_run := s1_MyIngress_get_server_from_id.action.NoAction_2;
        call s1_NoAction_2();
        goto s1_Exit;
    }

    s1_Exit:
}
function {:inline true}s1_MyIngress_index_to_hash.read(s1_reg:[bv32]bv16, s1_index:bv32)returns (bv16) {s1_reg[s1_index]}
procedure {:inline 1} s1_MyIngress_index_to_hash.write(s1_index:bv32, s1_value:bv16)
	modifies s1_MyIngress_index_to_hash, s1_MyIngress_index_to_hash__last0_old_value, s1_MyIngress_index_to_hash__last0_value, s1_MyIngress_index_to_hash__last_index, s1_MyIngress_index_to_hash__last_old_value, s1_MyIngress_index_to_hash__last_value, s1_MyIngress_index_to_hash__last_write_site, s1_MyIngress_index_to_hash__wrote_any, s1_MyIngress_index_to_hash__wrote_index0;
{
    s1_MyIngress_index_to_hash__last_old_value := s1_MyIngress_index_to_hash[s1_index];
    s1_MyIngress_index_to_hash[s1_index] := s1_value;
    s1_MyIngress_index_to_hash__last_index := s1_index;
    s1_MyIngress_index_to_hash__last_value := s1_value;
    s1_MyIngress_index_to_hash__last_write_site := s1_MyIngress_index_to_hash__next_write_site;
    s1_MyIngress_index_to_hash__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_MyIngress_index_to_hash__wrote_index0 := true;
        s1_MyIngress_index_to_hash__last0_old_value := s1_MyIngress_index_to_hash__last_old_value;
        s1_MyIngress_index_to_hash__last0_value := s1_value;
    }
}
function {:inline true}s1_MyIngress_index_to_server_id.read(s1_reg:[bv32]bv16, s1_index:bv32)returns (bv16) {s1_reg[s1_index]}
procedure {:inline 1} s1_MyIngress_index_to_server_id.write(s1_index:bv32, s1_value:bv16)
	modifies s1_MyIngress_index_to_server_id, s1_MyIngress_index_to_server_id__last0_old_value, s1_MyIngress_index_to_server_id__last0_value, s1_MyIngress_index_to_server_id__last_index, s1_MyIngress_index_to_server_id__last_old_value, s1_MyIngress_index_to_server_id__last_value, s1_MyIngress_index_to_server_id__last_write_site, s1_MyIngress_index_to_server_id__wrote_any, s1_MyIngress_index_to_server_id__wrote_index0;
{
    s1_MyIngress_index_to_server_id__last_old_value := s1_MyIngress_index_to_server_id[s1_index];
    s1_MyIngress_index_to_server_id[s1_index] := s1_value;
    s1_MyIngress_index_to_server_id__last_index := s1_index;
    s1_MyIngress_index_to_server_id__last_value := s1_value;
    s1_MyIngress_index_to_server_id__last_write_site := s1_MyIngress_index_to_server_id__next_write_site;
    s1_MyIngress_index_to_server_id__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_MyIngress_index_to_server_id__wrote_index0 := true;
        s1_MyIngress_index_to_server_id__last0_old_value := s1_MyIngress_index_to_server_id__last_old_value;
        s1_MyIngress_index_to_server_id__last0_value := s1_value;
    }
}
function {:inline true}s1_MyIngress_pop_index.read(s1_reg:[bv32]bv16, s1_index:bv32)returns (bv16) {s1_reg[s1_index]}
procedure {:inline 1} s1_MyIngress_pop_index.write(s1_index:bv32, s1_value:bv16)
	modifies s1_MyIngress_pop_index, s1_MyIngress_pop_index__last0_old_value, s1_MyIngress_pop_index__last0_value, s1_MyIngress_pop_index__last_index, s1_MyIngress_pop_index__last_old_value, s1_MyIngress_pop_index__last_value, s1_MyIngress_pop_index__last_write_site, s1_MyIngress_pop_index__wrote_any, s1_MyIngress_pop_index__wrote_index0;
{
    s1_MyIngress_pop_index__last_old_value := s1_MyIngress_pop_index[s1_index];
    s1_MyIngress_pop_index[s1_index] := s1_value;
    s1_MyIngress_pop_index__last_index := s1_index;
    s1_MyIngress_pop_index__last_value := s1_value;
    s1_MyIngress_pop_index__last_write_site := s1_MyIngress_pop_index__next_write_site;
    s1_MyIngress_pop_index__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_MyIngress_pop_index__wrote_index0 := true;
        s1_MyIngress_pop_index__last0_old_value := s1_MyIngress_pop_index__last_old_value;
        s1_MyIngress_pop_index__last0_value := s1_value;
    }
}
function {:inline true}s1_MyIngress_push_index.read(s1_reg:[bv32]bv16, s1_index:bv32)returns (bv16) {s1_reg[s1_index]}
procedure {:inline 1} s1_MyIngress_push_index.write(s1_index:bv32, s1_value:bv16)
	modifies s1_MyIngress_push_index, s1_MyIngress_push_index__last0_old_value, s1_MyIngress_push_index__last0_value, s1_MyIngress_push_index__last_index, s1_MyIngress_push_index__last_old_value, s1_MyIngress_push_index__last_value, s1_MyIngress_push_index__last_write_site, s1_MyIngress_push_index__wrote_any, s1_MyIngress_push_index__wrote_index0;
{
    s1_MyIngress_push_index__last_old_value := s1_MyIngress_push_index[s1_index];
    s1_MyIngress_push_index[s1_index] := s1_value;
    s1_MyIngress_push_index__last_index := s1_index;
    s1_MyIngress_push_index__last_value := s1_value;
    s1_MyIngress_push_index__last_write_site := s1_MyIngress_push_index__next_write_site;
    s1_MyIngress_push_index__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_MyIngress_push_index__wrote_index0 := true;
        s1_MyIngress_push_index__last0_old_value := s1_MyIngress_push_index__last_old_value;
        s1_MyIngress_push_index__last0_value := s1_value;
    }
}

// s1_Parser s1_MyParser
procedure {:inline 1} s1_MyParser()
	modifies s1_drop, s1_isValid;
{
    goto s1_State$MyParser$start;

        s1_State$MyParser$start:
    call s1_packet_in.extract(s1_hdr.ethernet);
    goto s1_State$MyParser$start$parse_ipv4_2, s1_State$MyParser$start$DEFAULT;
    
s1_State$MyParser$start$parse_ipv4_2:
    assume (s1_hdr.ethernet.etherType == 2048bv16);
    goto s1_State$MyParser$parse_ipv4;

    s1_State$MyParser$start$DEFAULT:
    assume(!(s1_hdr.ethernet.etherType == 2048bv16));
    goto s1_State$accept;

        s1_State$MyParser$parse_ipv4:
    call s1_packet_in.extract(s1_hdr.ipv4);
    goto s1_State$MyParser$parse_ipv4$parse_tcp_2, s1_State$MyParser$parse_ipv4$DEFAULT;
    
s1_State$MyParser$parse_ipv4$parse_tcp_2:
    assume (s1_hdr.ipv4.protocol == 6bv8);
    goto s1_State$MyParser$parse_tcp;

    s1_State$MyParser$parse_ipv4$DEFAULT:
    assume(!(s1_hdr.ipv4.protocol == 6bv8));
    goto s1_State$accept;

        s1_State$MyParser$parse_tcp:
    call s1_packet_in.extract(s1_hdr.tcp);
    call s1_packet_in.extract(s1_hdr.nop1);
    goto s1_State$MyParser$parse_tcp$parse_nop_5, s1_State$MyParser$parse_tcp$parse_ss_4, s1_State$MyParser$parse_tcp$parse_sack_3, s1_State$MyParser$parse_tcp$parse_ts_2, s1_State$MyParser$parse_tcp$DEFAULT;
    
s1_State$MyParser$parse_tcp$parse_nop_5:
    assume (s1_hdr.nop1.kind == 1bv8);
    goto s1_State$MyParser$parse_nop;
    
s1_State$MyParser$parse_tcp$parse_ss_4:
    assume (s1_hdr.nop1.kind == 2bv8);
    goto s1_State$MyParser$parse_ss;
    
s1_State$MyParser$parse_tcp$parse_sack_3:
    assume (s1_hdr.nop1.kind == 4bv8);
    goto s1_State$MyParser$parse_sack;
    
s1_State$MyParser$parse_tcp$parse_ts_2:
    assume (s1_hdr.nop1.kind == 8bv8);
    goto s1_State$MyParser$parse_ts;

    s1_State$MyParser$parse_tcp$DEFAULT:
    assume(!(s1_hdr.nop1.kind == 1bv8)&&!(s1_hdr.nop1.kind == 2bv8)&&!(s1_hdr.nop1.kind == 4bv8)&&!(s1_hdr.nop1.kind == 8bv8));
    goto s1_State$accept;

        s1_State$MyParser$parse_nop:
    call s1_packet_in.extract(s1_hdr.nop2);
    goto s1_State$MyParser$parse_nop$parse_nop2_3, s1_State$MyParser$parse_nop$parse_ts_2, s1_State$MyParser$parse_nop$DEFAULT;
    
s1_State$MyParser$parse_nop$parse_nop2_3:
    assume (s1_hdr.nop2.kind == 1bv8);
    goto s1_State$MyParser$parse_nop2;
    
s1_State$MyParser$parse_nop$parse_ts_2:
    assume (s1_hdr.nop2.kind == 8bv8);
    goto s1_State$MyParser$parse_ts;

    s1_State$MyParser$parse_nop$DEFAULT:
    assume(!(s1_hdr.nop2.kind == 1bv8)&&!(s1_hdr.nop2.kind == 8bv8));
    goto s1_State$accept;

        s1_State$MyParser$parse_nop2:
    call s1_packet_in.extract(s1_hdr.nop3);
    goto s1_State$MyParser$parse_nop2$parse_ts_2, s1_State$MyParser$parse_nop2$DEFAULT;
    
s1_State$MyParser$parse_nop2$parse_ts_2:
    assume (s1_hdr.nop3.kind == 8bv8);
    goto s1_State$MyParser$parse_ts;

    s1_State$MyParser$parse_nop2$DEFAULT:
    assume(!(s1_hdr.nop3.kind == 8bv8));
    goto s1_State$accept;

        s1_State$MyParser$parse_ss:
    call s1_packet_in.extract(s1_hdr.ss);
    call s1_packet_in.extract(s1_hdr.nop3);
    goto s1_State$MyParser$parse_ss$parse_sack_3, s1_State$MyParser$parse_ss$parse_ts_2, s1_State$MyParser$parse_ss$DEFAULT;
    
s1_State$MyParser$parse_ss$parse_sack_3:
    assume (s1_hdr.nop3.kind == 4bv8);
    goto s1_State$MyParser$parse_sack;
    
s1_State$MyParser$parse_ss$parse_ts_2:
    assume (s1_hdr.nop3.kind == 8bv8);
    goto s1_State$MyParser$parse_ts;

    s1_State$MyParser$parse_ss$DEFAULT:
    assume(!(s1_hdr.nop3.kind == 4bv8)&&!(s1_hdr.nop3.kind == 8bv8));
    goto s1_State$accept;

        s1_State$MyParser$parse_sack:
    call s1_packet_in.extract(s1_hdr.sackw);
    call s1_packet_in.extract(s1_hdr.sack);
    call s1_packet_in.extract(s1_hdr.nop4);
    goto s1_State$MyParser$parse_sack$parse_ts_2, s1_State$MyParser$parse_sack$DEFAULT;
    
s1_State$MyParser$parse_sack$parse_ts_2:
    assume (s1_hdr.nop4.kind == 8bv8);
    goto s1_State$MyParser$parse_ts;

    s1_State$MyParser$parse_sack$DEFAULT:
    assume(!(s1_hdr.nop4.kind == 8bv8));
    goto s1_State$accept;

        s1_State$MyParser$parse_ts:
    call s1_packet_in.extract(s1_hdr.timestamp);
    goto s1_State$accept;

    s1_State$accept:
    call s1_accept();
    goto s1_Exit;

    s1_State$reject:
    call s1_reject();
    goto s1_Exit;

    s1_Exit:
}

// s1_Control s1_MyVerifyChecksum
procedure {:inline 1} s1_MyVerifyChecksum()
{
}

// s1_Action s1_NoAction
procedure {:inline 1} s1_NoAction()
{
}

// s1_Action s1_NoAction_2
procedure {:inline 1} s1_NoAction_2()
{
}
procedure {:inline 1} s1_accept()
{
}
procedure {:inline 1} s1_main()
	modifies s1_MyIngress_bucket_counter, s1_MyIngress_bucket_counter__last0_old_value, s1_MyIngress_bucket_counter__last0_value, s1_MyIngress_bucket_counter__last_index, s1_MyIngress_bucket_counter__last_old_value, s1_MyIngress_bucket_counter__last_value, s1_MyIngress_bucket_counter__last_write_site, s1_MyIngress_bucket_counter__next_write_site, s1_MyIngress_bucket_counter__wrote_any, s1_MyIngress_bucket_counter__wrote_index0, s1_MyIngress_debug_hash, s1_MyIngress_debug_hash__last0_old_value, s1_MyIngress_debug_hash__last0_value, s1_MyIngress_debug_hash__last_index, s1_MyIngress_debug_hash__last_old_value, s1_MyIngress_debug_hash__last_value, s1_MyIngress_debug_hash__last_write_site, s1_MyIngress_debug_hash__next_write_site, s1_MyIngress_debug_hash__wrote_any, s1_MyIngress_debug_hash__wrote_index0, s1_MyIngress_free_indices, s1_MyIngress_free_indices__last0_old_value, s1_MyIngress_free_indices__last0_value, s1_MyIngress_free_indices__last_index, s1_MyIngress_free_indices__last_old_value, s1_MyIngress_free_indices__last_value, s1_MyIngress_free_indices__last_write_site, s1_MyIngress_free_indices__next_write_site, s1_MyIngress_free_indices__wrote_any, s1_MyIngress_free_indices__wrote_index0, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input, s1_MyIngress_get_server_from_bucket.action_run, s1_MyIngress_get_server_from_bucket.hit, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.dip_2, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.egress_port_3, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.mac_server_2, s1_MyIngress_get_server_from_id.action_run, s1_MyIngress_get_server_from_id.hit, s1_MyIngress_index_to_hash, s1_MyIngress_index_to_hash__last0_old_value, s1_MyIngress_index_to_hash__last0_value, s1_MyIngress_index_to_hash__last_index, s1_MyIngress_index_to_hash__last_old_value, s1_MyIngress_index_to_hash__last_value, s1_MyIngress_index_to_hash__last_write_site, s1_MyIngress_index_to_hash__next_write_site, s1_MyIngress_index_to_hash__wrote_any, s1_MyIngress_index_to_hash__wrote_index0, s1_MyIngress_index_to_server_id, s1_MyIngress_index_to_server_id__last0_old_value, s1_MyIngress_index_to_server_id__last0_value, s1_MyIngress_index_to_server_id__last_index, s1_MyIngress_index_to_server_id__last_old_value, s1_MyIngress_index_to_server_id__last_value, s1_MyIngress_index_to_server_id__last_write_site, s1_MyIngress_index_to_server_id__next_write_site, s1_MyIngress_index_to_server_id__wrote_any, s1_MyIngress_index_to_server_id__wrote_index0, s1_MyIngress_pop_index, s1_MyIngress_pop_index__last0_old_value, s1_MyIngress_pop_index__last0_value, s1_MyIngress_pop_index__last_index, s1_MyIngress_pop_index__last_old_value, s1_MyIngress_pop_index__last_value, s1_MyIngress_pop_index__last_write_site, s1_MyIngress_pop_index__next_write_site, s1_MyIngress_pop_index__wrote_any, s1_MyIngress_pop_index__wrote_index0, s1_MyIngress_push_index, s1_MyIngress_push_index__last0_old_value, s1_MyIngress_push_index__last0_value, s1_MyIngress_push_index__last_index, s1_MyIngress_push_index__last_old_value, s1_MyIngress_push_index__last_value, s1_MyIngress_push_index__last_write_site, s1_MyIngress_push_index__next_write_site, s1_MyIngress_push_index__wrote_any, s1_MyIngress_push_index__wrote_index0, s1_drop, s1_forward, s1_free_index_value_0, s1_hdr.ethernet.dstAddr, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.srcAddr, s1_hdr.timestamp.tsecr_lsb, s1_ip_addr_one_0, s1_ip_protocol_0, s1_isValid, s1_meta.bucket_id, s1_meta.packet_hash, s1_meta.server_id, s1_offset_0, s1_offset_unit_0, s1_pop_index_value_0, s1_push_index_value_0, s1_server_id_0, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_stored_hash_0, s1_tcp_port_one_0, s1_tcp_port_two_0;
{
    call s1_MyParser();
    call s1_MyVerifyChecksum();
    call s1_MyIngress();
    call s1_MyEgress();
    call s1_MyComputeChecksum();
    if(s1_forward == false){
        s1_drop := true;
    }
}
procedure s1_mainProcedure()
	modifies s1_MyIngress_bucket_counter, s1_MyIngress_bucket_counter__last0_old_value, s1_MyIngress_bucket_counter__last0_value, s1_MyIngress_bucket_counter__last_index, s1_MyIngress_bucket_counter__last_old_value, s1_MyIngress_bucket_counter__last_value, s1_MyIngress_bucket_counter__last_write_site, s1_MyIngress_bucket_counter__next_write_site, s1_MyIngress_bucket_counter__wrote_any, s1_MyIngress_bucket_counter__wrote_index0, s1_MyIngress_debug_hash, s1_MyIngress_debug_hash__last0_old_value, s1_MyIngress_debug_hash__last0_value, s1_MyIngress_debug_hash__last_index, s1_MyIngress_debug_hash__last_old_value, s1_MyIngress_debug_hash__last_value, s1_MyIngress_debug_hash__last_write_site, s1_MyIngress_debug_hash__next_write_site, s1_MyIngress_debug_hash__wrote_any, s1_MyIngress_debug_hash__wrote_index0, s1_MyIngress_free_indices, s1_MyIngress_free_indices__last0_old_value, s1_MyIngress_free_indices__last0_value, s1_MyIngress_free_indices__last_index, s1_MyIngress_free_indices__last_old_value, s1_MyIngress_free_indices__last_value, s1_MyIngress_free_indices__last_write_site, s1_MyIngress_free_indices__next_write_site, s1_MyIngress_free_indices__wrote_any, s1_MyIngress_free_indices__wrote_index0, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input, s1_MyIngress_get_server_from_bucket.action_run, s1_MyIngress_get_server_from_bucket.hit, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.dip_2, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.egress_port_3, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.mac_server_2, s1_MyIngress_get_server_from_id.action_run, s1_MyIngress_get_server_from_id.hit, s1_MyIngress_index_to_hash, s1_MyIngress_index_to_hash__last0_old_value, s1_MyIngress_index_to_hash__last0_value, s1_MyIngress_index_to_hash__last_index, s1_MyIngress_index_to_hash__last_old_value, s1_MyIngress_index_to_hash__last_value, s1_MyIngress_index_to_hash__last_write_site, s1_MyIngress_index_to_hash__next_write_site, s1_MyIngress_index_to_hash__wrote_any, s1_MyIngress_index_to_hash__wrote_index0, s1_MyIngress_index_to_server_id, s1_MyIngress_index_to_server_id__last0_old_value, s1_MyIngress_index_to_server_id__last0_value, s1_MyIngress_index_to_server_id__last_index, s1_MyIngress_index_to_server_id__last_old_value, s1_MyIngress_index_to_server_id__last_value, s1_MyIngress_index_to_server_id__last_write_site, s1_MyIngress_index_to_server_id__next_write_site, s1_MyIngress_index_to_server_id__wrote_any, s1_MyIngress_index_to_server_id__wrote_index0, s1_MyIngress_pop_index, s1_MyIngress_pop_index__last0_old_value, s1_MyIngress_pop_index__last0_value, s1_MyIngress_pop_index__last_index, s1_MyIngress_pop_index__last_old_value, s1_MyIngress_pop_index__last_value, s1_MyIngress_pop_index__last_write_site, s1_MyIngress_pop_index__next_write_site, s1_MyIngress_pop_index__wrote_any, s1_MyIngress_pop_index__wrote_index0, s1_MyIngress_push_index, s1_MyIngress_push_index__last0_old_value, s1_MyIngress_push_index__last0_value, s1_MyIngress_push_index__last_index, s1_MyIngress_push_index__last_old_value, s1_MyIngress_push_index__last_value, s1_MyIngress_push_index__last_write_site, s1_MyIngress_push_index__next_write_site, s1_MyIngress_push_index__wrote_any, s1_MyIngress_push_index__wrote_index0, s1_drop, s1_forward, s1_free_index_value_0, s1_hdr.ethernet.dstAddr, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.srcAddr, s1_hdr.timestamp.tsecr_lsb, s1_ip_addr_one_0, s1_ip_protocol_0, s1_isValid, s1_meta.bucket_id, s1_meta.packet_hash, s1_meta.server_id, s1_offset_0, s1_offset_unit_0, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pop_index_value_0, s1_push_index_value_0, s1_server_id_0, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_stored_hash_0, s1_tcp_port_one_0, s1_tcp_port_two_0;
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
procedure s1_packet.emit(s1_arg0:s1_Ref);
procedure s1_packet_in.extract(s1_header:s1_Ref);
    ensures (s1_isValid[s1_header] == true);
	modifies s1_isValid;
procedure s1_reject();
    ensures s1_drop==true;
	modifies s1_drop;
procedure {:inline 1} s1_setInvalid(s1_header:s1_Ref);
    ensures (s1_isValid[s1_header] == false);
	modifies s1_isValid;
procedure {:inline 1} s1_setValid(s1_header:s1_Ref);
// ===== END NODE s1 =====

// ===== BEGIN ENQUEUE PROCEDURES =====
// ===== END ENQUEUE PROCEDURES =====

// ===== BEGIN HARNESS =====
// Auto-generated by Procurator (DSL -> Boogie harness: sequential scheduler)
// Message abstraction: Bag(K=1) using inbox_count per node; single-slot mailbox for packet fields

var procurator_step: int;
var procurator_bad: bool;

// Register debug snapshots (for trace inspection)
var s1_MyIngress_bucket_counter__dbg0: bv16;
var s1_MyIngress_bucket_counter__last_index__dbg: bv32;
var s1_MyIngress_bucket_counter__last_value__dbg: bv16;
var s1_MyIngress_bucket_counter__last_old_value__dbg: bv16;
var s1_MyIngress_bucket_counter__wrote_any__dbg: bool;
var s1_MyIngress_bucket_counter__wrote_index0__dbg: bool;
var s1_MyIngress_bucket_counter__last0_old_value__dbg: bv16;
var s1_MyIngress_bucket_counter__last0_value__dbg: bv16;
var s1_MyIngress_debug_hash__dbg0: bv16;
var s1_MyIngress_debug_hash__last_index__dbg: bv32;
var s1_MyIngress_debug_hash__last_value__dbg: bv16;
var s1_MyIngress_debug_hash__last_old_value__dbg: bv16;
var s1_MyIngress_debug_hash__wrote_any__dbg: bool;
var s1_MyIngress_debug_hash__wrote_index0__dbg: bool;
var s1_MyIngress_debug_hash__last0_old_value__dbg: bv16;
var s1_MyIngress_debug_hash__last0_value__dbg: bv16;
var s1_MyIngress_free_indices__dbg0: bv16;
var s1_MyIngress_free_indices__last_index__dbg: bv32;
var s1_MyIngress_free_indices__last_value__dbg: bv16;
var s1_MyIngress_free_indices__last_old_value__dbg: bv16;
var s1_MyIngress_free_indices__wrote_any__dbg: bool;
var s1_MyIngress_free_indices__wrote_index0__dbg: bool;
var s1_MyIngress_free_indices__last0_old_value__dbg: bv16;
var s1_MyIngress_free_indices__last0_value__dbg: bv16;
var s1_MyIngress_index_to_hash__dbg0: bv16;
var s1_MyIngress_index_to_hash__last_index__dbg: bv32;
var s1_MyIngress_index_to_hash__last_value__dbg: bv16;
var s1_MyIngress_index_to_hash__last_old_value__dbg: bv16;
var s1_MyIngress_index_to_hash__wrote_any__dbg: bool;
var s1_MyIngress_index_to_hash__wrote_index0__dbg: bool;
var s1_MyIngress_index_to_hash__last0_old_value__dbg: bv16;
var s1_MyIngress_index_to_hash__last0_value__dbg: bv16;
var s1_MyIngress_index_to_server_id__dbg0: bv16;
var s1_MyIngress_index_to_server_id__last_index__dbg: bv32;
var s1_MyIngress_index_to_server_id__last_value__dbg: bv16;
var s1_MyIngress_index_to_server_id__last_old_value__dbg: bv16;
var s1_MyIngress_index_to_server_id__wrote_any__dbg: bool;
var s1_MyIngress_index_to_server_id__wrote_index0__dbg: bool;
var s1_MyIngress_index_to_server_id__last0_old_value__dbg: bv16;
var s1_MyIngress_index_to_server_id__last0_value__dbg: bv16;
var s1_MyIngress_pop_index__dbg0: bv16;
var s1_MyIngress_pop_index__last_index__dbg: bv32;
var s1_MyIngress_pop_index__last_value__dbg: bv16;
var s1_MyIngress_pop_index__last_old_value__dbg: bv16;
var s1_MyIngress_pop_index__wrote_any__dbg: bool;
var s1_MyIngress_pop_index__wrote_index0__dbg: bool;
var s1_MyIngress_pop_index__last0_old_value__dbg: bv16;
var s1_MyIngress_pop_index__last0_value__dbg: bv16;
var s1_MyIngress_push_index__dbg0: bv16;
var s1_MyIngress_push_index__last_index__dbg: bv32;
var s1_MyIngress_push_index__last_value__dbg: bv16;
var s1_MyIngress_push_index__last_old_value__dbg: bv16;
var s1_MyIngress_push_index__wrote_any__dbg: bool;
var s1_MyIngress_push_index__wrote_index0__dbg: bool;
var s1_MyIngress_push_index__last0_old_value__dbg: bv16;
var s1_MyIngress_push_index__last0_value__dbg: bv16;

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
  modifies procurator_bad, procurator_step, s1_MyIngress_bucket_counter, s1_MyIngress_bucket_counter__dbg0, s1_MyIngress_bucket_counter__last0_old_value, s1_MyIngress_bucket_counter__last0_old_value__dbg, s1_MyIngress_bucket_counter__last0_value, s1_MyIngress_bucket_counter__last0_value__dbg, s1_MyIngress_bucket_counter__last_index, s1_MyIngress_bucket_counter__last_index__dbg, s1_MyIngress_bucket_counter__last_old_value, s1_MyIngress_bucket_counter__last_old_value__dbg, s1_MyIngress_bucket_counter__last_value, s1_MyIngress_bucket_counter__last_value__dbg, s1_MyIngress_bucket_counter__last_write_site, s1_MyIngress_bucket_counter__next_write_site, s1_MyIngress_bucket_counter__wrote_any, s1_MyIngress_bucket_counter__wrote_any__dbg, s1_MyIngress_bucket_counter__wrote_index0, s1_MyIngress_bucket_counter__wrote_index0__dbg, s1_MyIngress_debug_hash, s1_MyIngress_debug_hash__dbg0, s1_MyIngress_debug_hash__last0_old_value, s1_MyIngress_debug_hash__last0_old_value__dbg, s1_MyIngress_debug_hash__last0_value, s1_MyIngress_debug_hash__last0_value__dbg, s1_MyIngress_debug_hash__last_index, s1_MyIngress_debug_hash__last_index__dbg, s1_MyIngress_debug_hash__last_old_value, s1_MyIngress_debug_hash__last_old_value__dbg, s1_MyIngress_debug_hash__last_value, s1_MyIngress_debug_hash__last_value__dbg, s1_MyIngress_debug_hash__last_write_site, s1_MyIngress_debug_hash__next_write_site, s1_MyIngress_debug_hash__wrote_any, s1_MyIngress_debug_hash__wrote_any__dbg, s1_MyIngress_debug_hash__wrote_index0, s1_MyIngress_debug_hash__wrote_index0__dbg, s1_MyIngress_free_indices, s1_MyIngress_free_indices__dbg0, s1_MyIngress_free_indices__last0_old_value, s1_MyIngress_free_indices__last0_old_value__dbg, s1_MyIngress_free_indices__last0_value, s1_MyIngress_free_indices__last0_value__dbg, s1_MyIngress_free_indices__last_index, s1_MyIngress_free_indices__last_index__dbg, s1_MyIngress_free_indices__last_old_value, s1_MyIngress_free_indices__last_old_value__dbg, s1_MyIngress_free_indices__last_value, s1_MyIngress_free_indices__last_value__dbg, s1_MyIngress_free_indices__last_write_site, s1_MyIngress_free_indices__next_write_site, s1_MyIngress_free_indices__wrote_any, s1_MyIngress_free_indices__wrote_any__dbg, s1_MyIngress_free_indices__wrote_index0, s1_MyIngress_free_indices__wrote_index0__dbg, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input, s1_MyIngress_get_server_from_bucket.action_run, s1_MyIngress_get_server_from_bucket.hit, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.dip_2, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.egress_port_3, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.mac_server_2, s1_MyIngress_get_server_from_id.action_run, s1_MyIngress_get_server_from_id.hit, s1_MyIngress_index_to_hash, s1_MyIngress_index_to_hash__dbg0, s1_MyIngress_index_to_hash__last0_old_value, s1_MyIngress_index_to_hash__last0_old_value__dbg, s1_MyIngress_index_to_hash__last0_value, s1_MyIngress_index_to_hash__last0_value__dbg, s1_MyIngress_index_to_hash__last_index, s1_MyIngress_index_to_hash__last_index__dbg, s1_MyIngress_index_to_hash__last_old_value, s1_MyIngress_index_to_hash__last_old_value__dbg, s1_MyIngress_index_to_hash__last_value, s1_MyIngress_index_to_hash__last_value__dbg, s1_MyIngress_index_to_hash__last_write_site, s1_MyIngress_index_to_hash__next_write_site, s1_MyIngress_index_to_hash__wrote_any, s1_MyIngress_index_to_hash__wrote_any__dbg, s1_MyIngress_index_to_hash__wrote_index0, s1_MyIngress_index_to_hash__wrote_index0__dbg, s1_MyIngress_index_to_server_id, s1_MyIngress_index_to_server_id__dbg0, s1_MyIngress_index_to_server_id__last0_old_value, s1_MyIngress_index_to_server_id__last0_old_value__dbg, s1_MyIngress_index_to_server_id__last0_value, s1_MyIngress_index_to_server_id__last0_value__dbg, s1_MyIngress_index_to_server_id__last_index, s1_MyIngress_index_to_server_id__last_index__dbg, s1_MyIngress_index_to_server_id__last_old_value, s1_MyIngress_index_to_server_id__last_old_value__dbg, s1_MyIngress_index_to_server_id__last_value, s1_MyIngress_index_to_server_id__last_value__dbg, s1_MyIngress_index_to_server_id__last_write_site, s1_MyIngress_index_to_server_id__next_write_site, s1_MyIngress_index_to_server_id__wrote_any, s1_MyIngress_index_to_server_id__wrote_any__dbg, s1_MyIngress_index_to_server_id__wrote_index0, s1_MyIngress_index_to_server_id__wrote_index0__dbg, s1_MyIngress_pop_index, s1_MyIngress_pop_index__dbg0, s1_MyIngress_pop_index__last0_old_value, s1_MyIngress_pop_index__last0_old_value__dbg, s1_MyIngress_pop_index__last0_value, s1_MyIngress_pop_index__last0_value__dbg, s1_MyIngress_pop_index__last_index, s1_MyIngress_pop_index__last_index__dbg, s1_MyIngress_pop_index__last_old_value, s1_MyIngress_pop_index__last_old_value__dbg, s1_MyIngress_pop_index__last_value, s1_MyIngress_pop_index__last_value__dbg, s1_MyIngress_pop_index__last_write_site, s1_MyIngress_pop_index__next_write_site, s1_MyIngress_pop_index__wrote_any, s1_MyIngress_pop_index__wrote_any__dbg, s1_MyIngress_pop_index__wrote_index0, s1_MyIngress_pop_index__wrote_index0__dbg, s1_MyIngress_push_index, s1_MyIngress_push_index__dbg0, s1_MyIngress_push_index__last0_old_value, s1_MyIngress_push_index__last0_old_value__dbg, s1_MyIngress_push_index__last0_value, s1_MyIngress_push_index__last0_value__dbg, s1_MyIngress_push_index__last_index, s1_MyIngress_push_index__last_index__dbg, s1_MyIngress_push_index__last_old_value, s1_MyIngress_push_index__last_old_value__dbg, s1_MyIngress_push_index__last_value, s1_MyIngress_push_index__last_value__dbg, s1_MyIngress_push_index__last_write_site, s1_MyIngress_push_index__next_write_site, s1_MyIngress_push_index__wrote_any, s1_MyIngress_push_index__wrote_any__dbg, s1_MyIngress_push_index__wrote_index0, s1_MyIngress_push_index__wrote_index0__dbg, s1_drop, s1_forward, s1_free_index_value_0, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.etherType, s1_hdr.ethernet.srcAddr, s1_hdr.ethernet.valid, s1_hdr.ipv4.diffserv, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.flags, s1_hdr.ipv4.fragOffset, s1_hdr.ipv4.hdrChecksum, s1_hdr.ipv4.identification, s1_hdr.ipv4.ihl, s1_hdr.ipv4.protocol, s1_hdr.ipv4.srcAddr, s1_hdr.ipv4.totalLen, s1_hdr.ipv4.ttl, s1_hdr.ipv4.valid, s1_hdr.ipv4.version, s1_hdr.nop1.kind, s1_hdr.nop1.valid, s1_hdr.nop2.kind, s1_hdr.nop2.valid, s1_hdr.nop3.kind, s1_hdr.nop3.valid, s1_hdr.nop4.kind, s1_hdr.nop4.valid, s1_hdr.sack.sack, s1_hdr.sack.valid, s1_hdr.sackw.length, s1_hdr.sackw.valid, s1_hdr.ss.length, s1_hdr.ss.maxSegmentSize, s1_hdr.ss.valid, s1_hdr.tcp.ack, s1_hdr.tcp.ackNo, s1_hdr.tcp.checksum, s1_hdr.tcp.dataOffset, s1_hdr.tcp.dstPort, s1_hdr.tcp.ecn, s1_hdr.tcp.fin, s1_hdr.tcp.psh, s1_hdr.tcp.res, s1_hdr.tcp.rst, s1_hdr.tcp.seqNo, s1_hdr.tcp.srcPort, s1_hdr.tcp.syn, s1_hdr.tcp.urg, s1_hdr.tcp.urgentPtr, s1_hdr.tcp.valid, s1_hdr.tcp.window, s1_hdr.timestamp.length, s1_hdr.timestamp.tsecr_lsb, s1_hdr.timestamp.tsecr_msb, s1_hdr.timestamp.tsval_lsb, s1_hdr.timestamp.tsval_msb, s1_hdr.timestamp.valid, s1_inbox_count, s1_ip_addr_one_0, s1_ip_protocol_0, s1_isValid, s1_meta.bucket_id, s1_meta.packet_hash, s1_meta.server_id, s1_offset_0, s1_offset_unit_0, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_external, s1_pop_index_value_0, s1_push_index_value_0, s1_server_id_0, s1_standard_metadata.checksum_error, s1_standard_metadata.deq_qdepth, s1_standard_metadata.deq_timedelta, s1_standard_metadata.egress_global_timestamp, s1_standard_metadata.egress_port, s1_standard_metadata.egress_rid, s1_standard_metadata.egress_spec, s1_standard_metadata.enq_qdepth, s1_standard_metadata.enq_timestamp, s1_standard_metadata.ingress_global_timestamp, s1_standard_metadata.ingress_port, s1_standard_metadata.instance_type, s1_standard_metadata.mcast_grp, s1_standard_metadata.packet_length, s1_standard_metadata.parser_error, s1_standard_metadata.priority, s1_stored_hash_0, s1_tcp_port_one_0, s1_tcp_port_two_0;
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
  assume s1_MyIngress_bucket_counter[0bv32] == 0bv16;
  assume s1_MyIngress_debug_hash[0bv32] == 0bv16;
  assume (forall i:bv32 :: ((i != 0bv32) && (i != 1bv32) && (i != 2bv32) && (i != 3bv32) && (i != 4bv32) && (i != 5bv32) && (i != 6bv32) && (i != 7bv32) && (i != 8bv32) && (i != 9bv32) && (i != 10bv32) && (i != 11bv32) && (i != 12bv32) && (i != 13bv32) && (i != 14bv32) && (i != 15bv32) && (i != 16bv32) && (i != 17bv32) && (i != 18bv32) && (i != 19bv32)) ==> s1_MyIngress_free_indices[i] == 0bv16);
  assume s1_MyIngress_free_indices[0bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[0bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[1bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[2bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[3bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[4bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[5bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[6bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[7bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[8bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[9bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[10bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[11bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[12bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[13bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[14bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[15bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[16bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[17bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[18bv32] == 65535bv16;
  assume s1_MyIngress_free_indices[19bv32] == 65535bv16;
  assume (forall i:bv32 :: s1_MyIngress_index_to_hash[i] == 0bv16);
  assume s1_MyIngress_index_to_hash[0bv32] == 0bv16;
  assume (forall i:bv32 :: s1_MyIngress_index_to_server_id[i] == 0bv16);
  assume s1_MyIngress_index_to_server_id[0bv32] == 0bv16;
  assume (forall i:bv32 :: ((i != 0bv32) && (i != 1bv32)) ==> s1_MyIngress_pop_index[i] == 0bv16);
  assume s1_MyIngress_pop_index[0bv32] == 0bv16;
  assume s1_MyIngress_pop_index[0bv32] == 0bv16;
  assume s1_MyIngress_pop_index[1bv32] == 0bv16;
  assume (forall i:bv32 :: s1_MyIngress_push_index[i] == 0bv16);
  assume s1_MyIngress_push_index[0bv32] == 0bv16;
  // initialize register write tracking (debug)
  s1_MyIngress_bucket_counter__last_index := 0bv32;
  s1_MyIngress_bucket_counter__last_value := 0bv16;
  s1_MyIngress_bucket_counter__last_old_value := 0bv16;
  s1_MyIngress_bucket_counter__wrote_any := false;
  s1_MyIngress_bucket_counter__wrote_index0 := false;
  s1_MyIngress_bucket_counter__next_write_site := 0;
  s1_MyIngress_bucket_counter__last_write_site := 0;
  s1_MyIngress_bucket_counter__last0_old_value := 0bv16;
  s1_MyIngress_bucket_counter__last0_value := 0bv16;
  s1_MyIngress_debug_hash__last_index := 0bv32;
  s1_MyIngress_debug_hash__last_value := 0bv16;
  s1_MyIngress_debug_hash__last_old_value := 0bv16;
  s1_MyIngress_debug_hash__wrote_any := false;
  s1_MyIngress_debug_hash__wrote_index0 := false;
  s1_MyIngress_debug_hash__next_write_site := 0;
  s1_MyIngress_debug_hash__last_write_site := 0;
  s1_MyIngress_debug_hash__last0_old_value := 0bv16;
  s1_MyIngress_debug_hash__last0_value := 0bv16;
  s1_MyIngress_free_indices__last_index := 0bv32;
  s1_MyIngress_free_indices__last_value := 0bv16;
  s1_MyIngress_free_indices__last_old_value := 0bv16;
  s1_MyIngress_free_indices__wrote_any := false;
  s1_MyIngress_free_indices__wrote_index0 := false;
  s1_MyIngress_free_indices__next_write_site := 0;
  s1_MyIngress_free_indices__last_write_site := 0;
  s1_MyIngress_free_indices__last0_old_value := 0bv16;
  s1_MyIngress_free_indices__last0_value := 0bv16;
  s1_MyIngress_index_to_hash__last_index := 0bv32;
  s1_MyIngress_index_to_hash__last_value := 0bv16;
  s1_MyIngress_index_to_hash__last_old_value := 0bv16;
  s1_MyIngress_index_to_hash__wrote_any := false;
  s1_MyIngress_index_to_hash__wrote_index0 := false;
  s1_MyIngress_index_to_hash__next_write_site := 0;
  s1_MyIngress_index_to_hash__last_write_site := 0;
  s1_MyIngress_index_to_hash__last0_old_value := 0bv16;
  s1_MyIngress_index_to_hash__last0_value := 0bv16;
  s1_MyIngress_index_to_server_id__last_index := 0bv32;
  s1_MyIngress_index_to_server_id__last_value := 0bv16;
  s1_MyIngress_index_to_server_id__last_old_value := 0bv16;
  s1_MyIngress_index_to_server_id__wrote_any := false;
  s1_MyIngress_index_to_server_id__wrote_index0 := false;
  s1_MyIngress_index_to_server_id__next_write_site := 0;
  s1_MyIngress_index_to_server_id__last_write_site := 0;
  s1_MyIngress_index_to_server_id__last0_old_value := 0bv16;
  s1_MyIngress_index_to_server_id__last0_value := 0bv16;
  s1_MyIngress_pop_index__last_index := 0bv32;
  s1_MyIngress_pop_index__last_value := 0bv16;
  s1_MyIngress_pop_index__last_old_value := 0bv16;
  s1_MyIngress_pop_index__wrote_any := false;
  s1_MyIngress_pop_index__wrote_index0 := false;
  s1_MyIngress_pop_index__next_write_site := 0;
  s1_MyIngress_pop_index__last_write_site := 0;
  s1_MyIngress_pop_index__last0_old_value := 0bv16;
  s1_MyIngress_pop_index__last0_value := 0bv16;
  s1_MyIngress_push_index__last_index := 0bv32;
  s1_MyIngress_push_index__last_value := 0bv16;
  s1_MyIngress_push_index__last_old_value := 0bv16;
  s1_MyIngress_push_index__wrote_any := false;
  s1_MyIngress_push_index__wrote_index0 := false;
  s1_MyIngress_push_index__next_write_site := 0;
  s1_MyIngress_push_index__last_write_site := 0;
  s1_MyIngress_push_index__last0_old_value := 0bv16;
  s1_MyIngress_push_index__last0_value := 0bv16;

  procurator_step := 0;
  procurator_bad := false;
  // step 0: env_inject -> s1
  if (s1_inbox_count < 1) {
  assume s1_inbox_count < 1;
  s1_pkt_external := true;
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
  havoc s1_hdr.ethernet.dstAddr;
  havoc s1_hdr.ethernet.srcAddr;
  havoc s1_hdr.ethernet.etherType;
  havoc s1_hdr.ipv4.version;
  havoc s1_hdr.ipv4.ihl;
  havoc s1_hdr.ipv4.diffserv;
  havoc s1_hdr.ipv4.totalLen;
  havoc s1_hdr.ipv4.identification;
  havoc s1_hdr.ipv4.flags;
  havoc s1_hdr.ipv4.fragOffset;
  havoc s1_hdr.ipv4.ttl;
  havoc s1_hdr.ipv4.hdrChecksum;
  havoc s1_hdr.tcp.seqNo;
  havoc s1_hdr.tcp.ackNo;
  havoc s1_hdr.tcp.dataOffset;
  havoc s1_hdr.tcp.res;
  havoc s1_hdr.tcp.ecn;
  havoc s1_hdr.tcp.urg;
  havoc s1_hdr.tcp.ack;
  havoc s1_hdr.tcp.psh;
  havoc s1_hdr.tcp.rst;
  havoc s1_hdr.tcp.window;
  havoc s1_hdr.tcp.checksum;
  havoc s1_hdr.tcp.urgentPtr;
  havoc s1_hdr.nop1.valid;
  havoc s1_hdr.nop1.kind;
  havoc s1_hdr.nop2.valid;
  havoc s1_hdr.nop2.kind;
  havoc s1_hdr.ss.valid;
  havoc s1_hdr.ss.length;
  havoc s1_hdr.ss.maxSegmentSize;
  havoc s1_hdr.nop3.valid;
  havoc s1_hdr.nop3.kind;
  havoc s1_hdr.sackw.valid;
  havoc s1_hdr.sackw.length;
  havoc s1_hdr.sack.valid;
  havoc s1_hdr.sack.sack;
  havoc s1_hdr.nop4.valid;
  havoc s1_hdr.nop4.kind;
  havoc s1_hdr.timestamp.length;
  havoc s1_hdr.timestamp.tsval_msb;
  havoc s1_hdr.timestamp.tsval_lsb;
  havoc s1_hdr.timestamp.tsecr_msb;
  havoc s1_meta.bucket_id;
  havoc s1_meta.packet_hash;
  havoc s1_meta.server_id;
  s1_hdr.ethernet.valid := true;
  s1_hdr.ipv4.valid := true;
  s1_hdr.tcp.valid := true;
  s1_hdr.timestamp.valid := true;
  s1_hdr.ipv4.srcAddr := 167772161bv32;
  s1_hdr.ipv4.dstAddr := 167772414bv32;
  s1_hdr.ipv4.protocol := 6bv8;
  s1_hdr.tcp.srcPort := 10bv16;
  s1_hdr.tcp.dstPort := 80bv16;
  s1_hdr.tcp.syn := 1bv1;
  s1_hdr.tcp.fin := 0bv1;
  s1_hdr.timestamp.tsecr_lsb := 0bv16;
  s1_standard_metadata.ingress_port := 0bv9;
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
  s1_MyIngress_bucket_counter__dbg0 := s1_MyIngress_bucket_counter[0bv32];
  s1_MyIngress_bucket_counter__last_index__dbg := s1_MyIngress_bucket_counter__last_index;
  s1_MyIngress_bucket_counter__last_value__dbg := s1_MyIngress_bucket_counter__last_value;
  s1_MyIngress_bucket_counter__last_old_value__dbg := s1_MyIngress_bucket_counter__last_old_value;
  s1_MyIngress_bucket_counter__wrote_any__dbg := s1_MyIngress_bucket_counter__wrote_any;
  s1_MyIngress_bucket_counter__wrote_index0__dbg := s1_MyIngress_bucket_counter__wrote_index0;
  s1_MyIngress_bucket_counter__last0_old_value__dbg := s1_MyIngress_bucket_counter__last0_old_value;
  s1_MyIngress_bucket_counter__last0_value__dbg := s1_MyIngress_bucket_counter__last0_value;
  s1_MyIngress_debug_hash__dbg0 := s1_MyIngress_debug_hash[0bv32];
  s1_MyIngress_debug_hash__last_index__dbg := s1_MyIngress_debug_hash__last_index;
  s1_MyIngress_debug_hash__last_value__dbg := s1_MyIngress_debug_hash__last_value;
  s1_MyIngress_debug_hash__last_old_value__dbg := s1_MyIngress_debug_hash__last_old_value;
  s1_MyIngress_debug_hash__wrote_any__dbg := s1_MyIngress_debug_hash__wrote_any;
  s1_MyIngress_debug_hash__wrote_index0__dbg := s1_MyIngress_debug_hash__wrote_index0;
  s1_MyIngress_debug_hash__last0_old_value__dbg := s1_MyIngress_debug_hash__last0_old_value;
  s1_MyIngress_debug_hash__last0_value__dbg := s1_MyIngress_debug_hash__last0_value;
  s1_MyIngress_free_indices__dbg0 := s1_MyIngress_free_indices[0bv32];
  s1_MyIngress_free_indices__last_index__dbg := s1_MyIngress_free_indices__last_index;
  s1_MyIngress_free_indices__last_value__dbg := s1_MyIngress_free_indices__last_value;
  s1_MyIngress_free_indices__last_old_value__dbg := s1_MyIngress_free_indices__last_old_value;
  s1_MyIngress_free_indices__wrote_any__dbg := s1_MyIngress_free_indices__wrote_any;
  s1_MyIngress_free_indices__wrote_index0__dbg := s1_MyIngress_free_indices__wrote_index0;
  s1_MyIngress_free_indices__last0_old_value__dbg := s1_MyIngress_free_indices__last0_old_value;
  s1_MyIngress_free_indices__last0_value__dbg := s1_MyIngress_free_indices__last0_value;
  s1_MyIngress_index_to_hash__dbg0 := s1_MyIngress_index_to_hash[0bv32];
  s1_MyIngress_index_to_hash__last_index__dbg := s1_MyIngress_index_to_hash__last_index;
  s1_MyIngress_index_to_hash__last_value__dbg := s1_MyIngress_index_to_hash__last_value;
  s1_MyIngress_index_to_hash__last_old_value__dbg := s1_MyIngress_index_to_hash__last_old_value;
  s1_MyIngress_index_to_hash__wrote_any__dbg := s1_MyIngress_index_to_hash__wrote_any;
  s1_MyIngress_index_to_hash__wrote_index0__dbg := s1_MyIngress_index_to_hash__wrote_index0;
  s1_MyIngress_index_to_hash__last0_old_value__dbg := s1_MyIngress_index_to_hash__last0_old_value;
  s1_MyIngress_index_to_hash__last0_value__dbg := s1_MyIngress_index_to_hash__last0_value;
  s1_MyIngress_index_to_server_id__dbg0 := s1_MyIngress_index_to_server_id[0bv32];
  s1_MyIngress_index_to_server_id__last_index__dbg := s1_MyIngress_index_to_server_id__last_index;
  s1_MyIngress_index_to_server_id__last_value__dbg := s1_MyIngress_index_to_server_id__last_value;
  s1_MyIngress_index_to_server_id__last_old_value__dbg := s1_MyIngress_index_to_server_id__last_old_value;
  s1_MyIngress_index_to_server_id__wrote_any__dbg := s1_MyIngress_index_to_server_id__wrote_any;
  s1_MyIngress_index_to_server_id__wrote_index0__dbg := s1_MyIngress_index_to_server_id__wrote_index0;
  s1_MyIngress_index_to_server_id__last0_old_value__dbg := s1_MyIngress_index_to_server_id__last0_old_value;
  s1_MyIngress_index_to_server_id__last0_value__dbg := s1_MyIngress_index_to_server_id__last0_value;
  s1_MyIngress_pop_index__dbg0 := s1_MyIngress_pop_index[0bv32];
  s1_MyIngress_pop_index__last_index__dbg := s1_MyIngress_pop_index__last_index;
  s1_MyIngress_pop_index__last_value__dbg := s1_MyIngress_pop_index__last_value;
  s1_MyIngress_pop_index__last_old_value__dbg := s1_MyIngress_pop_index__last_old_value;
  s1_MyIngress_pop_index__wrote_any__dbg := s1_MyIngress_pop_index__wrote_any;
  s1_MyIngress_pop_index__wrote_index0__dbg := s1_MyIngress_pop_index__wrote_index0;
  s1_MyIngress_pop_index__last0_old_value__dbg := s1_MyIngress_pop_index__last0_old_value;
  s1_MyIngress_pop_index__last0_value__dbg := s1_MyIngress_pop_index__last0_value;
  s1_MyIngress_push_index__dbg0 := s1_MyIngress_push_index[0bv32];
  s1_MyIngress_push_index__last_index__dbg := s1_MyIngress_push_index__last_index;
  s1_MyIngress_push_index__last_value__dbg := s1_MyIngress_push_index__last_value;
  s1_MyIngress_push_index__last_old_value__dbg := s1_MyIngress_push_index__last_old_value;
  s1_MyIngress_push_index__wrote_any__dbg := s1_MyIngress_push_index__wrote_any;
  s1_MyIngress_push_index__wrote_index0__dbg := s1_MyIngress_push_index__wrote_index0;
  s1_MyIngress_push_index__last0_old_value__dbg := s1_MyIngress_push_index__last0_old_value;
  s1_MyIngress_push_index__last0_value__dbg := s1_MyIngress_push_index__last0_value;
  // Global assertions (accumulated into procurator_bad)
  if (!((!(s1_hdr.ipv4.valid) || (s1_hdr.ipv4.srcAddr != 167772161bv32) || !(s1_hdr.tcp.valid) || (s1_hdr.tcp.syn == 0bv1) || (bvule.bv16$builtin(s1_hdr.timestamp.tsecr_lsb, 10bv16) && (s1_hdr.timestamp.tsecr_lsb != 10bv16))))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  assert !procurator_bad;
}


procedure ULTIMATE.start() returns()
  modifies procurator_bad, procurator_step, s1_MyIngress_bucket_counter, s1_MyIngress_bucket_counter__dbg0, s1_MyIngress_bucket_counter__last0_old_value, s1_MyIngress_bucket_counter__last0_old_value__dbg, s1_MyIngress_bucket_counter__last0_value, s1_MyIngress_bucket_counter__last0_value__dbg, s1_MyIngress_bucket_counter__last_index, s1_MyIngress_bucket_counter__last_index__dbg, s1_MyIngress_bucket_counter__last_old_value, s1_MyIngress_bucket_counter__last_old_value__dbg, s1_MyIngress_bucket_counter__last_value, s1_MyIngress_bucket_counter__last_value__dbg, s1_MyIngress_bucket_counter__last_write_site, s1_MyIngress_bucket_counter__next_write_site, s1_MyIngress_bucket_counter__wrote_any, s1_MyIngress_bucket_counter__wrote_any__dbg, s1_MyIngress_bucket_counter__wrote_index0, s1_MyIngress_bucket_counter__wrote_index0__dbg, s1_MyIngress_debug_hash, s1_MyIngress_debug_hash__dbg0, s1_MyIngress_debug_hash__last0_old_value, s1_MyIngress_debug_hash__last0_old_value__dbg, s1_MyIngress_debug_hash__last0_value, s1_MyIngress_debug_hash__last0_value__dbg, s1_MyIngress_debug_hash__last_index, s1_MyIngress_debug_hash__last_index__dbg, s1_MyIngress_debug_hash__last_old_value, s1_MyIngress_debug_hash__last_old_value__dbg, s1_MyIngress_debug_hash__last_value, s1_MyIngress_debug_hash__last_value__dbg, s1_MyIngress_debug_hash__last_write_site, s1_MyIngress_debug_hash__next_write_site, s1_MyIngress_debug_hash__wrote_any, s1_MyIngress_debug_hash__wrote_any__dbg, s1_MyIngress_debug_hash__wrote_index0, s1_MyIngress_debug_hash__wrote_index0__dbg, s1_MyIngress_free_indices, s1_MyIngress_free_indices__dbg0, s1_MyIngress_free_indices__last0_old_value, s1_MyIngress_free_indices__last0_old_value__dbg, s1_MyIngress_free_indices__last0_value, s1_MyIngress_free_indices__last0_value__dbg, s1_MyIngress_free_indices__last_index, s1_MyIngress_free_indices__last_index__dbg, s1_MyIngress_free_indices__last_old_value, s1_MyIngress_free_indices__last_old_value__dbg, s1_MyIngress_free_indices__last_value, s1_MyIngress_free_indices__last_value__dbg, s1_MyIngress_free_indices__last_write_site, s1_MyIngress_free_indices__next_write_site, s1_MyIngress_free_indices__wrote_any, s1_MyIngress_free_indices__wrote_any__dbg, s1_MyIngress_free_indices__wrote_index0, s1_MyIngress_free_indices__wrote_index0__dbg, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.dip, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.egress_port_2, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.mac_server, s1_MyIngress_get_server_from_bucket.MyIngress_fwd.server_id_input, s1_MyIngress_get_server_from_bucket.action_run, s1_MyIngress_get_server_from_bucket.hit, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.dip_2, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.egress_port_3, s1_MyIngress_get_server_from_id.MyIngress_fwd_2.mac_server_2, s1_MyIngress_get_server_from_id.action_run, s1_MyIngress_get_server_from_id.hit, s1_MyIngress_index_to_hash, s1_MyIngress_index_to_hash__dbg0, s1_MyIngress_index_to_hash__last0_old_value, s1_MyIngress_index_to_hash__last0_old_value__dbg, s1_MyIngress_index_to_hash__last0_value, s1_MyIngress_index_to_hash__last0_value__dbg, s1_MyIngress_index_to_hash__last_index, s1_MyIngress_index_to_hash__last_index__dbg, s1_MyIngress_index_to_hash__last_old_value, s1_MyIngress_index_to_hash__last_old_value__dbg, s1_MyIngress_index_to_hash__last_value, s1_MyIngress_index_to_hash__last_value__dbg, s1_MyIngress_index_to_hash__last_write_site, s1_MyIngress_index_to_hash__next_write_site, s1_MyIngress_index_to_hash__wrote_any, s1_MyIngress_index_to_hash__wrote_any__dbg, s1_MyIngress_index_to_hash__wrote_index0, s1_MyIngress_index_to_hash__wrote_index0__dbg, s1_MyIngress_index_to_server_id, s1_MyIngress_index_to_server_id__dbg0, s1_MyIngress_index_to_server_id__last0_old_value, s1_MyIngress_index_to_server_id__last0_old_value__dbg, s1_MyIngress_index_to_server_id__last0_value, s1_MyIngress_index_to_server_id__last0_value__dbg, s1_MyIngress_index_to_server_id__last_index, s1_MyIngress_index_to_server_id__last_index__dbg, s1_MyIngress_index_to_server_id__last_old_value, s1_MyIngress_index_to_server_id__last_old_value__dbg, s1_MyIngress_index_to_server_id__last_value, s1_MyIngress_index_to_server_id__last_value__dbg, s1_MyIngress_index_to_server_id__last_write_site, s1_MyIngress_index_to_server_id__next_write_site, s1_MyIngress_index_to_server_id__wrote_any, s1_MyIngress_index_to_server_id__wrote_any__dbg, s1_MyIngress_index_to_server_id__wrote_index0, s1_MyIngress_index_to_server_id__wrote_index0__dbg, s1_MyIngress_pop_index, s1_MyIngress_pop_index__dbg0, s1_MyIngress_pop_index__last0_old_value, s1_MyIngress_pop_index__last0_old_value__dbg, s1_MyIngress_pop_index__last0_value, s1_MyIngress_pop_index__last0_value__dbg, s1_MyIngress_pop_index__last_index, s1_MyIngress_pop_index__last_index__dbg, s1_MyIngress_pop_index__last_old_value, s1_MyIngress_pop_index__last_old_value__dbg, s1_MyIngress_pop_index__last_value, s1_MyIngress_pop_index__last_value__dbg, s1_MyIngress_pop_index__last_write_site, s1_MyIngress_pop_index__next_write_site, s1_MyIngress_pop_index__wrote_any, s1_MyIngress_pop_index__wrote_any__dbg, s1_MyIngress_pop_index__wrote_index0, s1_MyIngress_pop_index__wrote_index0__dbg, s1_MyIngress_push_index, s1_MyIngress_push_index__dbg0, s1_MyIngress_push_index__last0_old_value, s1_MyIngress_push_index__last0_old_value__dbg, s1_MyIngress_push_index__last0_value, s1_MyIngress_push_index__last0_value__dbg, s1_MyIngress_push_index__last_index, s1_MyIngress_push_index__last_index__dbg, s1_MyIngress_push_index__last_old_value, s1_MyIngress_push_index__last_old_value__dbg, s1_MyIngress_push_index__last_value, s1_MyIngress_push_index__last_value__dbg, s1_MyIngress_push_index__last_write_site, s1_MyIngress_push_index__next_write_site, s1_MyIngress_push_index__wrote_any, s1_MyIngress_push_index__wrote_any__dbg, s1_MyIngress_push_index__wrote_index0, s1_MyIngress_push_index__wrote_index0__dbg, s1_drop, s1_forward, s1_free_index_value_0, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.etherType, s1_hdr.ethernet.srcAddr, s1_hdr.ethernet.valid, s1_hdr.ipv4.diffserv, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.flags, s1_hdr.ipv4.fragOffset, s1_hdr.ipv4.hdrChecksum, s1_hdr.ipv4.identification, s1_hdr.ipv4.ihl, s1_hdr.ipv4.protocol, s1_hdr.ipv4.srcAddr, s1_hdr.ipv4.totalLen, s1_hdr.ipv4.ttl, s1_hdr.ipv4.valid, s1_hdr.ipv4.version, s1_hdr.nop1.kind, s1_hdr.nop1.valid, s1_hdr.nop2.kind, s1_hdr.nop2.valid, s1_hdr.nop3.kind, s1_hdr.nop3.valid, s1_hdr.nop4.kind, s1_hdr.nop4.valid, s1_hdr.sack.sack, s1_hdr.sack.valid, s1_hdr.sackw.length, s1_hdr.sackw.valid, s1_hdr.ss.length, s1_hdr.ss.maxSegmentSize, s1_hdr.ss.valid, s1_hdr.tcp.ack, s1_hdr.tcp.ackNo, s1_hdr.tcp.checksum, s1_hdr.tcp.dataOffset, s1_hdr.tcp.dstPort, s1_hdr.tcp.ecn, s1_hdr.tcp.fin, s1_hdr.tcp.psh, s1_hdr.tcp.res, s1_hdr.tcp.rst, s1_hdr.tcp.seqNo, s1_hdr.tcp.srcPort, s1_hdr.tcp.syn, s1_hdr.tcp.urg, s1_hdr.tcp.urgentPtr, s1_hdr.tcp.valid, s1_hdr.tcp.window, s1_hdr.timestamp.length, s1_hdr.timestamp.tsecr_lsb, s1_hdr.timestamp.tsecr_msb, s1_hdr.timestamp.tsval_lsb, s1_hdr.timestamp.tsval_msb, s1_hdr.timestamp.valid, s1_inbox_count, s1_ip_addr_one_0, s1_ip_protocol_0, s1_isValid, s1_meta.bucket_id, s1_meta.packet_hash, s1_meta.server_id, s1_offset_0, s1_offset_unit_0, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_external, s1_pop_index_value_0, s1_push_index_value_0, s1_server_id_0, s1_standard_metadata.checksum_error, s1_standard_metadata.deq_qdepth, s1_standard_metadata.deq_timedelta, s1_standard_metadata.egress_global_timestamp, s1_standard_metadata.egress_port, s1_standard_metadata.egress_rid, s1_standard_metadata.egress_spec, s1_standard_metadata.enq_qdepth, s1_standard_metadata.enq_timestamp, s1_standard_metadata.ingress_global_timestamp, s1_standard_metadata.ingress_port, s1_standard_metadata.instance_type, s1_standard_metadata.mcast_grp, s1_standard_metadata.packet_length, s1_standard_metadata.parser_error, s1_standard_metadata.priority, s1_stored_hash_0, s1_tcp_port_one_0, s1_tcp_port_two_0;
{
  call mainProcedure();
}

// ===== END HARNESS =====
