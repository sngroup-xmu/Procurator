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

// s1_Register s1_count
var s1_count:[bv32]bv32;
var s1_count__last_index:bv32;
var s1_count__last_value:bv32;
var s1_count__last_old_value:bv32;
var s1_count__wrote_any:bool;
var s1_count__wrote_index0:bool;
var s1_count__last0_old_value:bv32;
var s1_count__last0_value:bv32;
var s1_count__next_write_site:int;
var s1_count__last_write_site:int;
const s1_count.size:bv32;
axiom s1_count.size == 1bv32;

// s1_Register s1_es_box
var s1_es_box:[bv32]bv8;
var s1_es_box__last_index:bv32;
var s1_es_box__last_value:bv8;
var s1_es_box__last_old_value:bv8;
var s1_es_box__wrote_any:bool;
var s1_es_box__wrote_index0:bool;
var s1_es_box__last0_old_value:bv8;
var s1_es_box__last0_value:bv8;
var s1_es_box__next_write_site:int;
var s1_es_box__last_write_site:int;
const s1_es_box.size:bv32;
axiom s1_es_box.size == 256bv32;

// s1_Register s1_ds_box
var s1_ds_box:[bv32]bv8;
var s1_ds_box__last_index:bv32;
var s1_ds_box__last_value:bv8;
var s1_ds_box__last_old_value:bv8;
var s1_ds_box__wrote_any:bool;
var s1_ds_box__wrote_index0:bool;
var s1_ds_box__last0_old_value:bv8;
var s1_ds_box__last0_value:bv8;
var s1_ds_box__next_write_site:int;
var s1_ds_box__last_write_site:int;
const s1_ds_box.size:bv32;
axiom s1_ds_box.size == 256bv32;

// s1_Register s1_user_mac
var s1_user_mac:[bv32]bv48;
var s1_user_mac__last_index:bv32;
var s1_user_mac__last_value:bv48;
var s1_user_mac__last_old_value:bv48;
var s1_user_mac__wrote_any:bool;
var s1_user_mac__wrote_index0:bool;
var s1_user_mac__last0_old_value:bv48;
var s1_user_mac__last0_value:bv48;
var s1_user_mac__next_write_site:int;
var s1_user_mac__last_write_site:int;
const s1_user_mac.size:bv32;
axiom s1_user_mac.size == 1bv32;
type s1_macAddr_t = bv48;
type s1_ip4Addr_t = bv32;
type s1_ip6Addr_t = bv128;
type s1_ethernet_t;
type s1_ipv6_t;
type s1_ipv4_t;
type s1_tcp_t;
type s1_udp_t;

// s1_Struct s1_metadata
type s1_metadata;

// s1_Struct s1_headers
var s1_hdr:s1_Ref;

// s1_Header s1_ethernet_t
var s1_hdr.ethernet:s1_Ref;
var s1_hdr.ethernet.valid:bool;
var s1_hdr.ethernet.dstAddr:s1_macAddr_t;
var s1_hdr.ethernet.srcAddr:s1_macAddr_t;
var s1_hdr.ethernet.etherType:bv16;

// s1_Header s1_ipv6_t
var s1_hdr.ipv6:s1_Ref;
var s1_hdr.ipv6.valid:bool;
var s1_hdr.ipv6.version:bv4;
var s1_hdr.ipv6.trafclass:bv8;
var s1_hdr.ipv6.flowlabel:bv20;
var s1_hdr.ipv6.payloadlen:bv16;
var s1_hdr.ipv6.nextheader:bv8;
var s1_hdr.ipv6.hoplimit:bv8;
var s1_hdr.ipv6.srcAddr:s1_ip6Addr_t;
var s1_hdr.ipv6.dstAddr:s1_ip6Addr_t;

// s1_Header s1_ipv4_t
var s1_hdr.ipv4_tunnel:s1_Ref;
var s1_hdr.ipv4_tunnel.valid:bool;
var s1_hdr.ipv4_tunnel.version:bv4;
var s1_hdr.ipv4_tunnel.ihl:bv4;
var s1_hdr.ipv4_tunnel.diffserv:bv8;
var s1_hdr.ipv4_tunnel.totalLen:bv16;
var s1_hdr.ipv4_tunnel.identification:bv16;
var s1_hdr.ipv4_tunnel.flags:bv3;
var s1_hdr.ipv4_tunnel.fragOffset:bv13;
var s1_hdr.ipv4_tunnel.ttl:bv8;
var s1_hdr.ipv4_tunnel.protocol:bv8;
var s1_hdr.ipv4_tunnel.hdrChecksum:bv16;
var s1_hdr.ipv4_tunnel.srcAddr:s1_ip4Addr_t;
var s1_hdr.ipv4_tunnel.dstAddr:s1_ip4Addr_t;

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
var s1_hdr.ipv4.srcAddr:s1_ip4Addr_t;
var s1_hdr.ipv4.dstAddr:s1_ip4Addr_t;

// s1_Header s1_tcp_t
var s1_hdr.tcp:s1_Ref;
var s1_hdr.tcp.valid:bool;
var s1_hdr.tcp.srcport:bv16;
var s1_hdr.tcp.dstport:bv16;
var s1_hdr.tcp.sequence:bv32;
var s1_hdr.tcp.ackseq:bv32;
var s1_hdr.tcp.headerlength:bv4;
var s1_hdr.tcp.reservation:bv6;
var s1_hdr.tcp.URG:bv1;
var s1_hdr.tcp.ACK:bv1;
var s1_hdr.tcp.PSH:bv1;
var s1_hdr.tcp.RST:bv1;
var s1_hdr.tcp.SYN:bv1;
var s1_hdr.tcp.FIN:bv1;
var s1_hdr.tcp.windowsize:bv16;
var s1_hdr.tcp.checksum:bv16;
var s1_hdr.tcp.pointer:bv16;

// s1_Header s1_udp_t
var s1_hdr.udp_tunnel:s1_Ref;
var s1_hdr.udp_tunnel.valid:bool;
var s1_hdr.udp_tunnel.srcport:bv16;
var s1_hdr.udp_tunnel.dstport:bv16;
var s1_hdr.udp_tunnel.userlength:bv16;
var s1_hdr.udp_tunnel.checksum:bv16;
var s1_meta:s1_metadata;
var s1_standard_metadata:s1_standard_metadata_t;
var s1_temp_0:bv32;

function {:builtin "bvadd"} add.bv16(s1_left:bv16, s1_right:bv16) returns(bv16);

function {:builtin "bvsub"} sub.bv17(s1_left:bv17, s1_right:bv17) returns(bv17);

function {:builtin "bvsub"} sub.bv33(s1_left:bv33, s1_right:bv33) returns(bv33);

// s1_Control s1_MyComputeChecksum
procedure {:inline 1} s1_MyComputeChecksum()
	modifies s1_hdr.ipv4.hdrChecksum, s1_hdr.ipv4_tunnel.hdrChecksum, s1_p4b_checksum_updated;
{
    if (s1_isValid[s1_hdr.ipv4]) {
        s1_p4b_checksum_updated := true;
        havoc s1_hdr.ipv4.hdrChecksum;
    }
    if (s1_isValid[s1_hdr.ipv4_tunnel]) {
        s1_p4b_checksum_updated := true;
        havoc s1_hdr.ipv4_tunnel.hdrChecksum;
    }
}

// s1_Control s1_MyEgress
procedure {:inline 1} s1_MyEgress()
	modifies s1_hdr.tcp.ackseq, s1_hdr.tcp.sequence;
{
    if(((s1_standard_metadata.egress_port == 0bv9)) && (s1_isValid[s1_hdr.tcp])){
        call s1_MyEgress_read_dsbox();
    }
}

// s1_Action s1_MyEgress_read_dsbox
procedure {:inline 1} s1_MyEgress_read_dsbox()
	modifies s1_hdr.tcp.ackseq, s1_hdr.tcp.sequence;
{
    // s1_read
    s1_hdr.tcp.sequence := s1_hdr.tcp.sequence[32:8]++s1_ds_box.read(s1_ds_box, 0bv24++s1_hdr.tcp.sequence[8:0]);
    // s1_read
    s1_hdr.tcp.sequence := s1_hdr.tcp.sequence[32:16]++s1_ds_box.read(s1_ds_box, 0bv24++s1_hdr.tcp.sequence[16:8])++s1_hdr.tcp.sequence[8:0];
    // s1_read
    s1_hdr.tcp.sequence := s1_hdr.tcp.sequence[32:24]++s1_ds_box.read(s1_ds_box, 0bv24++s1_hdr.tcp.sequence[24:16])++s1_hdr.tcp.sequence[16:0];
    // s1_read
    s1_hdr.tcp.sequence := s1_ds_box.read(s1_ds_box, 0bv24++s1_hdr.tcp.sequence[32:24])++s1_hdr.tcp.sequence[24:0];
    // s1_read
    s1_hdr.tcp.ackseq := s1_hdr.tcp.ackseq[32:8]++s1_ds_box.read(s1_ds_box, 0bv24++s1_hdr.tcp.ackseq[8:0]);
    // s1_read
    s1_hdr.tcp.ackseq := s1_hdr.tcp.ackseq[32:16]++s1_ds_box.read(s1_ds_box, 0bv24++s1_hdr.tcp.ackseq[16:8])++s1_hdr.tcp.ackseq[8:0];
    // s1_read
    s1_hdr.tcp.ackseq := s1_hdr.tcp.ackseq[32:24]++s1_ds_box.read(s1_ds_box, 0bv24++s1_hdr.tcp.ackseq[24:16])++s1_hdr.tcp.ackseq[16:0];
    // s1_read
    s1_hdr.tcp.ackseq := s1_ds_box.read(s1_ds_box, 0bv24++s1_hdr.tcp.ackseq[32:24])++s1_hdr.tcp.ackseq[24:0];
}

// s1_Control s1_MyIngress
procedure {:inline 1} s1_MyIngress()
	modifies s1_count, s1_count__last0_old_value, s1_count__last0_value, s1_count__last_index, s1_count__last_old_value, s1_count__last_value, s1_count__last_write_site, s1_count__next_write_site, s1_count__wrote_any, s1_count__wrote_index0, s1_forward, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.etherType, s1_hdr.ethernet.srcAddr, s1_hdr.ipv4_tunnel.diffserv, s1_hdr.ipv4_tunnel.dstAddr, s1_hdr.ipv4_tunnel.flags, s1_hdr.ipv4_tunnel.fragOffset, s1_hdr.ipv4_tunnel.identification, s1_hdr.ipv4_tunnel.ihl, s1_hdr.ipv4_tunnel.protocol, s1_hdr.ipv4_tunnel.srcAddr, s1_hdr.ipv4_tunnel.totalLen, s1_hdr.ipv4_tunnel.ttl, s1_hdr.ipv4_tunnel.version, s1_hdr.ipv6.dstAddr, s1_hdr.ipv6.hoplimit, s1_hdr.ipv6.nextheader, s1_hdr.ipv6.payloadlen, s1_hdr.ipv6.srcAddr, s1_hdr.ipv6.version, s1_hdr.tcp.ackseq, s1_hdr.tcp.sequence, s1_hdr.udp_tunnel.checksum, s1_hdr.udp_tunnel.dstport, s1_hdr.udp_tunnel.srcport, s1_hdr.udp_tunnel.userlength, s1_isValid, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_temp_0, s1_user_mac, s1_user_mac__last0_old_value, s1_user_mac__last0_value, s1_user_mac__last_index, s1_user_mac__last_old_value, s1_user_mac__last_value, s1_user_mac__last_write_site, s1_user_mac__next_write_site, s1_user_mac__wrote_any, s1_user_mac__wrote_index0;
{
havoc s1_temp_0;
    if((s1_standard_metadata.ingress_port == 0bv9)){
        if((s1_hdr.ipv4.dstAddr == 2071690107bv32)){
            s1_hdr.ethernet.dstAddr := 174219185552744bv48;
            s1_standard_metadata.egress_spec := 1bv9;
            s1_standard_metadata.egress_port := 1bv9;
            s1_forward := true;
        }
        else{
            if(((s1_hdr.ethernet.dstAddr != 281474976710655bv48)) && ((s1_hdr.ethernet.srcAddr != 0bv48))){
                call s1_MyIngress_store_user_mac();
                call s1_MyIngress_read_esbox();
                call s1_MyIngress_do_read_count();
                if((s1_temp_0 == 0bv32)){
                    call s1_MyIngress_creatipv6_1();
                    // s1_write
                    s1_count__next_write_site := 1;
                    call s1_count.write(0bv32, 1bv32);
                    s1_standard_metadata.egress_spec := 1bv9;
                    s1_standard_metadata.egress_port := 1bv9;
                    s1_forward := true;
                }
                if((s1_temp_0 == 1bv32)){
                    call s1_MyIngress_creatmytunnel();
                    // s1_write
                    s1_count__next_write_site := 2;
                    call s1_count.write(0bv32, 2bv32);
                    s1_standard_metadata.egress_spec := 2bv9;
                    s1_standard_metadata.egress_port := 2bv9;
                    s1_forward := true;
                }
                if((s1_temp_0 == 2bv32)){
                    call s1_MyIngress_creatipv6_2();
                    // s1_write
                    s1_count__next_write_site := 3;
                    call s1_count.write(0bv32, 0bv32);
                    s1_standard_metadata.egress_spec := 3bv9;
                    s1_standard_metadata.egress_port := 3bv9;
                    s1_forward := true;
                }
                assert (((s1_standard_metadata.egress_spec == 1bv9)) || ((s1_standard_metadata.egress_spec == 2bv9))) || ((s1_standard_metadata.egress_spec == 3bv9));
            }
        }
    }
    else{
        s1_hdr.ethernet.etherType := 2048bv16;
        // s1_read
        s1_hdr.ethernet.dstAddr := s1_user_mac.read(s1_user_mac, 0bv32);
        if(s1_isValid[s1_hdr.ipv4_tunnel]){
            call s1_setInvalid(s1_hdr.ipv4_tunnel);
            call s1_setInvalid(s1_hdr.udp_tunnel);
        }
        else{
            if(s1_isValid[s1_hdr.ipv6]){
                call s1_setInvalid(s1_hdr.ipv6);
            }
        }
        s1_standard_metadata.egress_spec := 0bv9;
        s1_standard_metadata.egress_port := 0bv9;
        s1_forward := true;
    }
}

// s1_Action s1_MyIngress_creatipv6_1
procedure {:inline 1} s1_MyIngress_creatipv6_1()
	modifies s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.etherType, s1_hdr.ethernet.srcAddr, s1_hdr.ipv6.dstAddr, s1_hdr.ipv6.hoplimit, s1_hdr.ipv6.nextheader, s1_hdr.ipv6.payloadlen, s1_hdr.ipv6.srcAddr, s1_hdr.ipv6.version, s1_isValid;
{
    call s1_setValid(s1_hdr.ipv6);
    s1_hdr.ipv6.version := 6bv4;
    s1_hdr.ipv6.payloadlen := s1_hdr.ipv4.totalLen;
    s1_hdr.ipv6.nextheader := 65bv8;
    s1_hdr.ipv6.hoplimit := 64bv8;
    s1_hdr.ethernet.etherType := 34525bv16;
    s1_hdr.ipv6.srcAddr := 42545680458834377588178886921629466626bv128;
    s1_hdr.ipv6.dstAddr := 42540765144257160172006968799218772356bv128;
    s1_hdr.ethernet.srcAddr := 19799850608873bv48;
    s1_hdr.ethernet.dstAddr := 174219185552744bv48;
}

// s1_Action s1_MyIngress_creatipv6_2
procedure {:inline 1} s1_MyIngress_creatipv6_2()
	modifies s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.etherType, s1_hdr.ethernet.srcAddr, s1_hdr.ipv6.dstAddr, s1_hdr.ipv6.hoplimit, s1_hdr.ipv6.nextheader, s1_hdr.ipv6.payloadlen, s1_hdr.ipv6.srcAddr, s1_hdr.ipv6.version, s1_isValid;
{
    call s1_setValid(s1_hdr.ipv6);
    s1_hdr.ipv6.version := 6bv4;
    s1_hdr.ipv6.payloadlen := s1_hdr.ipv4.totalLen;
    s1_hdr.ipv6.nextheader := 65bv8;
    s1_hdr.ipv6.hoplimit := 64bv8;
    s1_hdr.ethernet.etherType := 34525bv16;
    s1_hdr.ipv6.srcAddr := 42556065052551447243435947914287906818bv128;
    s1_hdr.ipv6.dstAddr := 42540765144257160172006968799218772358bv128;
    s1_hdr.ethernet.srcAddr := 33595163910409bv48;
    s1_hdr.ethernet.dstAddr := 20159709288469bv48;
}

// s1_Action s1_MyIngress_creatmytunnel
procedure {:inline 1} s1_MyIngress_creatmytunnel()
	modifies s1_hdr.ethernet.dstAddr, s1_hdr.ipv4_tunnel.diffserv, s1_hdr.ipv4_tunnel.dstAddr, s1_hdr.ipv4_tunnel.flags, s1_hdr.ipv4_tunnel.fragOffset, s1_hdr.ipv4_tunnel.identification, s1_hdr.ipv4_tunnel.ihl, s1_hdr.ipv4_tunnel.protocol, s1_hdr.ipv4_tunnel.srcAddr, s1_hdr.ipv4_tunnel.totalLen, s1_hdr.ipv4_tunnel.ttl, s1_hdr.ipv4_tunnel.version, s1_hdr.udp_tunnel.checksum, s1_hdr.udp_tunnel.dstport, s1_hdr.udp_tunnel.srcport, s1_hdr.udp_tunnel.userlength, s1_isValid;
{
    call s1_setValid(s1_hdr.ipv4_tunnel);
    s1_hdr.ipv4_tunnel.version := s1_hdr.ipv4.version;
    s1_hdr.ipv4_tunnel.ihl := 5bv4;
    s1_hdr.ipv4_tunnel.diffserv := s1_hdr.ipv4.diffserv;
    s1_hdr.ipv4_tunnel.totalLen := add.bv16(s1_hdr.ipv4.totalLen, 28bv16);
    s1_hdr.ipv4_tunnel.identification := s1_hdr.ipv4.identification;
    s1_hdr.ipv4_tunnel.flags := s1_hdr.ipv4.flags;
    s1_hdr.ipv4_tunnel.fragOffset := s1_hdr.ipv4.fragOffset;
    s1_hdr.ipv4_tunnel.ttl := s1_hdr.ipv4.ttl;
    s1_hdr.ipv4_tunnel.protocol := 17bv8;
    s1_hdr.ipv4_tunnel.srcAddr := s1_hdr.ipv4.srcAddr;
    s1_hdr.ipv4_tunnel.dstAddr := 3690098939bv32;
    s1_hdr.ethernet.dstAddr := 204790950826065bv48;
    call s1_setValid(s1_hdr.udp_tunnel);
    s1_hdr.udp_tunnel.srcport := 52910bv16;
    s1_hdr.udp_tunnel.dstport := 80bv16;
    s1_hdr.udp_tunnel.userlength := s1_hdr.ipv4.totalLen;
    s1_hdr.udp_tunnel.checksum := 0bv16;
}

// s1_Action s1_MyIngress_do_read_count
procedure {:inline 1} s1_MyIngress_do_read_count()
	modifies s1_temp_0;
{
    // s1_read
    s1_temp_0 := s1_count.read(s1_count, 0bv32);
}

// s1_Action s1_MyIngress_read_esbox
procedure {:inline 1} s1_MyIngress_read_esbox()
	modifies s1_hdr.tcp.ackseq, s1_hdr.tcp.sequence;
{
    // s1_read
    s1_hdr.tcp.sequence := s1_hdr.tcp.sequence[32:8]++s1_es_box.read(s1_es_box, 0bv24++s1_hdr.tcp.sequence[8:0]);
    // s1_read
    s1_hdr.tcp.sequence := s1_hdr.tcp.sequence[32:16]++s1_es_box.read(s1_es_box, 0bv24++s1_hdr.tcp.sequence[16:8])++s1_hdr.tcp.sequence[8:0];
    // s1_read
    s1_hdr.tcp.sequence := s1_hdr.tcp.sequence[32:24]++s1_es_box.read(s1_es_box, 0bv24++s1_hdr.tcp.sequence[24:16])++s1_hdr.tcp.sequence[16:0];
    // s1_read
    s1_hdr.tcp.sequence := s1_es_box.read(s1_es_box, 0bv24++s1_hdr.tcp.sequence[32:24])++s1_hdr.tcp.sequence[24:0];
    // s1_read
    s1_hdr.tcp.ackseq := s1_hdr.tcp.ackseq[32:8]++s1_es_box.read(s1_es_box, 0bv24++s1_hdr.tcp.ackseq[8:0]);
    // s1_read
    s1_hdr.tcp.ackseq := s1_hdr.tcp.ackseq[32:16]++s1_es_box.read(s1_es_box, 0bv24++s1_hdr.tcp.ackseq[16:8])++s1_hdr.tcp.ackseq[8:0];
    // s1_read
    s1_hdr.tcp.ackseq := s1_hdr.tcp.ackseq[32:24]++s1_es_box.read(s1_es_box, 0bv24++s1_hdr.tcp.ackseq[24:16])++s1_hdr.tcp.ackseq[16:0];
    // s1_read
    s1_hdr.tcp.ackseq := s1_es_box.read(s1_es_box, 0bv24++s1_hdr.tcp.ackseq[32:24])++s1_hdr.tcp.ackseq[24:0];
}

// s1_Action s1_MyIngress_store_user_mac
procedure {:inline 1} s1_MyIngress_store_user_mac()
	modifies s1_user_mac, s1_user_mac__last0_old_value, s1_user_mac__last0_value, s1_user_mac__last_index, s1_user_mac__last_old_value, s1_user_mac__last_value, s1_user_mac__last_write_site, s1_user_mac__next_write_site, s1_user_mac__wrote_any, s1_user_mac__wrote_index0;
{
    // s1_write
    s1_user_mac__next_write_site := 1;
    call s1_user_mac.write(0bv32, s1_hdr.ethernet.srcAddr);
}

// s1_Parser s1_MyParser
procedure {:inline 1} s1_MyParser()
	modifies s1_drop, s1_isValid;
{
    goto s1_State$MyParser$start;

        s1_State$MyParser$start:
    call s1_packet_in.extract(s1_hdr.ethernet);
    goto s1_State$MyParser$start$parse_ipv6_3, s1_State$MyParser$start$parse_select_2, s1_State$MyParser$start$DEFAULT;
    
s1_State$MyParser$start$parse_ipv6_3:
    assume (s1_hdr.ethernet.etherType == 34525bv16);
    goto s1_State$MyParser$parse_ipv6;
    
s1_State$MyParser$start$parse_select_2:
    assume (s1_hdr.ethernet.etherType == 2048bv16);
    goto s1_State$MyParser$parse_select;

    s1_State$MyParser$start$DEFAULT:
    assume(!(s1_hdr.ethernet.etherType == 34525bv16)&&!(s1_hdr.ethernet.etherType == 2048bv16));
    goto s1_State$accept;

        s1_State$MyParser$parse_ipv6:
    call s1_packet_in.extract(s1_hdr.ipv6);
    goto s1_State$MyParser$parse_ipv6$parse_ipv4_2, s1_State$MyParser$parse_ipv6$DEFAULT;
    
s1_State$MyParser$parse_ipv6$parse_ipv4_2:
    assume (s1_hdr.ipv6.nextheader == 65bv8);
    goto s1_State$MyParser$parse_ipv4;

    s1_State$MyParser$parse_ipv6$DEFAULT:
    assume(!(s1_hdr.ipv6.nextheader == 65bv8));
    goto s1_State$accept;

        s1_State$MyParser$parse_select:
    goto s1_State$MyParser$parse_select$parse_myTunnel_2, s1_State$MyParser$parse_select$DEFAULT;
    
s1_State$MyParser$parse_select$parse_myTunnel_2:
    assume (s1_standard_metadata.ingress_port == 2bv9);
    goto s1_State$MyParser$parse_myTunnel;

    s1_State$MyParser$parse_select$DEFAULT:
    assume(!(s1_standard_metadata.ingress_port == 2bv9));
    goto s1_State$MyParser$parse_ipv4;

        s1_State$MyParser$parse_myTunnel:
    call s1_packet_in.extract(s1_hdr.ipv4_tunnel);
    goto s1_State$MyParser$parse_myTunnel$parse_udp_2, s1_State$MyParser$parse_myTunnel$DEFAULT;
    
s1_State$MyParser$parse_myTunnel$parse_udp_2:
    assume (s1_hdr.ipv4_tunnel.protocol == 17bv8);
    goto s1_State$MyParser$parse_udp;

    s1_State$MyParser$parse_myTunnel$DEFAULT:
    assume(!(s1_hdr.ipv4_tunnel.protocol == 17bv8));
    goto s1_State$accept;

        s1_State$MyParser$parse_udp:
    call s1_packet_in.extract(s1_hdr.udp_tunnel);
    goto s1_State$MyParser$parse_ipv4;

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
procedure {:inline 1} s1_accept()
{
}
function {:inline true}s1_count.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_count.write(s1_index:bv32, s1_value:bv32)
	modifies s1_count, s1_count__last0_old_value, s1_count__last0_value, s1_count__last_index, s1_count__last_old_value, s1_count__last_value, s1_count__last_write_site, s1_count__wrote_any, s1_count__wrote_index0;
{
    s1_count__last_old_value := s1_count[s1_index];
    s1_count[s1_index] := s1_value;
    s1_count__last_index := s1_index;
    s1_count__last_value := s1_value;
    s1_count__last_write_site := s1_count__next_write_site;
    s1_count__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_count__wrote_index0 := true;
        s1_count__last0_old_value := s1_count__last_old_value;
        s1_count__last0_value := s1_value;
    }
}
function {:inline true}s1_ds_box.read(s1_reg:[bv32]bv8, s1_index:bv32)returns (bv8) {s1_reg[s1_index]}
procedure {:inline 1} s1_ds_box.write(s1_index:bv32, s1_value:bv8)
	modifies s1_ds_box, s1_ds_box__last0_old_value, s1_ds_box__last0_value, s1_ds_box__last_index, s1_ds_box__last_old_value, s1_ds_box__last_value, s1_ds_box__last_write_site, s1_ds_box__wrote_any, s1_ds_box__wrote_index0;
{
    s1_ds_box__last_old_value := s1_ds_box[s1_index];
    s1_ds_box[s1_index] := s1_value;
    s1_ds_box__last_index := s1_index;
    s1_ds_box__last_value := s1_value;
    s1_ds_box__last_write_site := s1_ds_box__next_write_site;
    s1_ds_box__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_ds_box__wrote_index0 := true;
        s1_ds_box__last0_old_value := s1_ds_box__last_old_value;
        s1_ds_box__last0_value := s1_value;
    }
}
function {:inline true}s1_es_box.read(s1_reg:[bv32]bv8, s1_index:bv32)returns (bv8) {s1_reg[s1_index]}
procedure {:inline 1} s1_es_box.write(s1_index:bv32, s1_value:bv8)
	modifies s1_es_box, s1_es_box__last0_old_value, s1_es_box__last0_value, s1_es_box__last_index, s1_es_box__last_old_value, s1_es_box__last_value, s1_es_box__last_write_site, s1_es_box__wrote_any, s1_es_box__wrote_index0;
{
    s1_es_box__last_old_value := s1_es_box[s1_index];
    s1_es_box[s1_index] := s1_value;
    s1_es_box__last_index := s1_index;
    s1_es_box__last_value := s1_value;
    s1_es_box__last_write_site := s1_es_box__next_write_site;
    s1_es_box__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_es_box__wrote_index0 := true;
        s1_es_box__last0_old_value := s1_es_box__last_old_value;
        s1_es_box__last0_value := s1_value;
    }
}
procedure {:inline 1} s1_main()
	modifies s1_count, s1_count__last0_old_value, s1_count__last0_value, s1_count__last_index, s1_count__last_old_value, s1_count__last_value, s1_count__last_write_site, s1_count__next_write_site, s1_count__wrote_any, s1_count__wrote_index0, s1_drop, s1_forward, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.etherType, s1_hdr.ethernet.srcAddr, s1_hdr.ipv4.hdrChecksum, s1_hdr.ipv4_tunnel.diffserv, s1_hdr.ipv4_tunnel.dstAddr, s1_hdr.ipv4_tunnel.flags, s1_hdr.ipv4_tunnel.fragOffset, s1_hdr.ipv4_tunnel.hdrChecksum, s1_hdr.ipv4_tunnel.identification, s1_hdr.ipv4_tunnel.ihl, s1_hdr.ipv4_tunnel.protocol, s1_hdr.ipv4_tunnel.srcAddr, s1_hdr.ipv4_tunnel.totalLen, s1_hdr.ipv4_tunnel.ttl, s1_hdr.ipv4_tunnel.version, s1_hdr.ipv6.dstAddr, s1_hdr.ipv6.hoplimit, s1_hdr.ipv6.nextheader, s1_hdr.ipv6.payloadlen, s1_hdr.ipv6.srcAddr, s1_hdr.ipv6.version, s1_hdr.tcp.ackseq, s1_hdr.tcp.sequence, s1_hdr.udp_tunnel.checksum, s1_hdr.udp_tunnel.dstport, s1_hdr.udp_tunnel.srcport, s1_hdr.udp_tunnel.userlength, s1_isValid, s1_p4b_checksum_updated, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_temp_0, s1_user_mac, s1_user_mac__last0_old_value, s1_user_mac__last0_value, s1_user_mac__last_index, s1_user_mac__last_old_value, s1_user_mac__last_value, s1_user_mac__last_write_site, s1_user_mac__next_write_site, s1_user_mac__wrote_any, s1_user_mac__wrote_index0;
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
	modifies s1_count, s1_count__last0_old_value, s1_count__last0_value, s1_count__last_index, s1_count__last_old_value, s1_count__last_value, s1_count__last_write_site, s1_count__next_write_site, s1_count__wrote_any, s1_count__wrote_index0, s1_drop, s1_forward, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.etherType, s1_hdr.ethernet.srcAddr, s1_hdr.ipv4.hdrChecksum, s1_hdr.ipv4_tunnel.diffserv, s1_hdr.ipv4_tunnel.dstAddr, s1_hdr.ipv4_tunnel.flags, s1_hdr.ipv4_tunnel.fragOffset, s1_hdr.ipv4_tunnel.hdrChecksum, s1_hdr.ipv4_tunnel.identification, s1_hdr.ipv4_tunnel.ihl, s1_hdr.ipv4_tunnel.protocol, s1_hdr.ipv4_tunnel.srcAddr, s1_hdr.ipv4_tunnel.totalLen, s1_hdr.ipv4_tunnel.ttl, s1_hdr.ipv4_tunnel.version, s1_hdr.ipv6.dstAddr, s1_hdr.ipv6.hoplimit, s1_hdr.ipv6.nextheader, s1_hdr.ipv6.payloadlen, s1_hdr.ipv6.srcAddr, s1_hdr.ipv6.version, s1_hdr.tcp.ackseq, s1_hdr.tcp.sequence, s1_hdr.udp_tunnel.checksum, s1_hdr.udp_tunnel.dstport, s1_hdr.udp_tunnel.srcport, s1_hdr.udp_tunnel.userlength, s1_isValid, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_temp_0, s1_user_mac, s1_user_mac__last0_old_value, s1_user_mac__last0_value, s1_user_mac__last_index, s1_user_mac__last_old_value, s1_user_mac__last_value, s1_user_mac__last_write_site, s1_user_mac__next_write_site, s1_user_mac__wrote_any, s1_user_mac__wrote_index0;
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
function {:inline true}s1_user_mac.read(s1_reg:[bv32]bv48, s1_index:bv32)returns (bv48) {s1_reg[s1_index]}
procedure {:inline 1} s1_user_mac.write(s1_index:bv32, s1_value:bv48)
	modifies s1_user_mac, s1_user_mac__last0_old_value, s1_user_mac__last0_value, s1_user_mac__last_index, s1_user_mac__last_old_value, s1_user_mac__last_value, s1_user_mac__last_write_site, s1_user_mac__wrote_any, s1_user_mac__wrote_index0;
{
    s1_user_mac__last_old_value := s1_user_mac[s1_index];
    s1_user_mac[s1_index] := s1_value;
    s1_user_mac__last_index := s1_index;
    s1_user_mac__last_value := s1_value;
    s1_user_mac__last_write_site := s1_user_mac__next_write_site;
    s1_user_mac__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_user_mac__wrote_index0 := true;
        s1_user_mac__last0_old_value := s1_user_mac__last_old_value;
        s1_user_mac__last0_value := s1_value;
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

// Register debug snapshots (for trace inspection)
var s1_count__dbg0: bv32;
var s1_count__last_index__dbg: bv32;
var s1_count__last_value__dbg: bv32;
var s1_count__last_old_value__dbg: bv32;
var s1_count__wrote_any__dbg: bool;
var s1_count__wrote_index0__dbg: bool;
var s1_count__last0_old_value__dbg: bv32;
var s1_count__last0_value__dbg: bv32;
var s1_ds_box__dbg0: bv8;
var s1_ds_box__last_index__dbg: bv32;
var s1_ds_box__last_value__dbg: bv8;
var s1_ds_box__last_old_value__dbg: bv8;
var s1_ds_box__wrote_any__dbg: bool;
var s1_ds_box__wrote_index0__dbg: bool;
var s1_ds_box__last0_old_value__dbg: bv8;
var s1_ds_box__last0_value__dbg: bv8;
var s1_es_box__dbg0: bv8;
var s1_es_box__last_index__dbg: bv32;
var s1_es_box__last_value__dbg: bv8;
var s1_es_box__last_old_value__dbg: bv8;
var s1_es_box__wrote_any__dbg: bool;
var s1_es_box__wrote_index0__dbg: bool;
var s1_es_box__last0_old_value__dbg: bv8;
var s1_es_box__last0_value__dbg: bv8;
var s1_user_mac__dbg0: bv48;
var s1_user_mac__last_index__dbg: bv32;
var s1_user_mac__last_value__dbg: bv48;
var s1_user_mac__last_old_value__dbg: bv48;
var s1_user_mac__wrote_any__dbg: bool;
var s1_user_mac__wrote_index0__dbg: bool;
var s1_user_mac__last0_old_value__dbg: bv48;
var s1_user_mac__last0_value__dbg: bv48;

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
  modifies procurator_bad, procurator_step, s1_count, s1_count__dbg0, s1_count__last0_old_value, s1_count__last0_old_value__dbg, s1_count__last0_value, s1_count__last0_value__dbg, s1_count__last_index, s1_count__last_index__dbg, s1_count__last_old_value, s1_count__last_old_value__dbg, s1_count__last_value, s1_count__last_value__dbg, s1_count__last_write_site, s1_count__next_write_site, s1_count__wrote_any, s1_count__wrote_any__dbg, s1_count__wrote_index0, s1_count__wrote_index0__dbg, s1_drop, s1_ds_box__dbg0, s1_ds_box__last0_old_value, s1_ds_box__last0_old_value__dbg, s1_ds_box__last0_value, s1_ds_box__last0_value__dbg, s1_ds_box__last_index, s1_ds_box__last_index__dbg, s1_ds_box__last_old_value, s1_ds_box__last_old_value__dbg, s1_ds_box__last_value, s1_ds_box__last_value__dbg, s1_ds_box__last_write_site, s1_ds_box__next_write_site, s1_ds_box__wrote_any, s1_ds_box__wrote_any__dbg, s1_ds_box__wrote_index0, s1_ds_box__wrote_index0__dbg, s1_es_box__dbg0, s1_es_box__last0_old_value, s1_es_box__last0_old_value__dbg, s1_es_box__last0_value, s1_es_box__last0_value__dbg, s1_es_box__last_index, s1_es_box__last_index__dbg, s1_es_box__last_old_value, s1_es_box__last_old_value__dbg, s1_es_box__last_value, s1_es_box__last_value__dbg, s1_es_box__last_write_site, s1_es_box__next_write_site, s1_es_box__wrote_any, s1_es_box__wrote_any__dbg, s1_es_box__wrote_index0, s1_es_box__wrote_index0__dbg, s1_forward, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.etherType, s1_hdr.ethernet.srcAddr, s1_hdr.ethernet.valid, s1_hdr.ipv4.diffserv, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.flags, s1_hdr.ipv4.fragOffset, s1_hdr.ipv4.hdrChecksum, s1_hdr.ipv4.identification, s1_hdr.ipv4.ihl, s1_hdr.ipv4.protocol, s1_hdr.ipv4.srcAddr, s1_hdr.ipv4.totalLen, s1_hdr.ipv4.ttl, s1_hdr.ipv4.valid, s1_hdr.ipv4.version, s1_hdr.ipv4_tunnel.diffserv, s1_hdr.ipv4_tunnel.dstAddr, s1_hdr.ipv4_tunnel.flags, s1_hdr.ipv4_tunnel.fragOffset, s1_hdr.ipv4_tunnel.hdrChecksum, s1_hdr.ipv4_tunnel.identification, s1_hdr.ipv4_tunnel.ihl, s1_hdr.ipv4_tunnel.protocol, s1_hdr.ipv4_tunnel.srcAddr, s1_hdr.ipv4_tunnel.totalLen, s1_hdr.ipv4_tunnel.ttl, s1_hdr.ipv4_tunnel.valid, s1_hdr.ipv4_tunnel.version, s1_hdr.ipv6.dstAddr, s1_hdr.ipv6.flowlabel, s1_hdr.ipv6.hoplimit, s1_hdr.ipv6.nextheader, s1_hdr.ipv6.payloadlen, s1_hdr.ipv6.srcAddr, s1_hdr.ipv6.trafclass, s1_hdr.ipv6.valid, s1_hdr.ipv6.version, s1_hdr.tcp.ACK, s1_hdr.tcp.FIN, s1_hdr.tcp.PSH, s1_hdr.tcp.RST, s1_hdr.tcp.SYN, s1_hdr.tcp.URG, s1_hdr.tcp.ackseq, s1_hdr.tcp.checksum, s1_hdr.tcp.dstport, s1_hdr.tcp.headerlength, s1_hdr.tcp.pointer, s1_hdr.tcp.reservation, s1_hdr.tcp.sequence, s1_hdr.tcp.srcport, s1_hdr.tcp.valid, s1_hdr.tcp.windowsize, s1_hdr.udp_tunnel.checksum, s1_hdr.udp_tunnel.dstport, s1_hdr.udp_tunnel.srcport, s1_hdr.udp_tunnel.userlength, s1_hdr.udp_tunnel.valid, s1_inbox_count, s1_isValid, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_external, s1_standard_metadata.checksum_error, s1_standard_metadata.deq_qdepth, s1_standard_metadata.deq_timedelta, s1_standard_metadata.egress_global_timestamp, s1_standard_metadata.egress_port, s1_standard_metadata.egress_rid, s1_standard_metadata.egress_spec, s1_standard_metadata.enq_qdepth, s1_standard_metadata.enq_timestamp, s1_standard_metadata.ingress_global_timestamp, s1_standard_metadata.ingress_port, s1_standard_metadata.instance_type, s1_standard_metadata.mcast_grp, s1_standard_metadata.packet_length, s1_standard_metadata.parser_error, s1_standard_metadata.priority, s1_temp_0, s1_user_mac, s1_user_mac__dbg0, s1_user_mac__last0_old_value, s1_user_mac__last0_old_value__dbg, s1_user_mac__last0_value, s1_user_mac__last0_value__dbg, s1_user_mac__last_index, s1_user_mac__last_index__dbg, s1_user_mac__last_old_value, s1_user_mac__last_old_value__dbg, s1_user_mac__last_value, s1_user_mac__last_value__dbg, s1_user_mac__last_write_site, s1_user_mac__next_write_site, s1_user_mac__wrote_any, s1_user_mac__wrote_any__dbg, s1_user_mac__wrote_index0, s1_user_mac__wrote_index0__dbg;
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
  assume s1_count[0bv32] == 3bv32;
  assume (forall i:bv32 :: s1_ds_box[i] == 0bv8);
  assume s1_ds_box[0bv32] == 0bv8;
  assume (forall i:bv32 :: s1_es_box[i] == 0bv8);
  assume s1_es_box[0bv32] == 0bv8;
  assume s1_user_mac[0bv32] == 0bv48;
  // initialize register write tracking (debug)
  s1_count__last_index := 0bv32;
  s1_count__last_value := 0bv32;
  s1_count__last_old_value := 0bv32;
  s1_count__wrote_any := false;
  s1_count__wrote_index0 := false;
  s1_count__next_write_site := 0;
  s1_count__last_write_site := 0;
  s1_count__last0_old_value := 0bv32;
  s1_count__last0_value := 0bv32;
  s1_ds_box__last_index := 0bv32;
  s1_ds_box__last_value := 0bv8;
  s1_ds_box__last_old_value := 0bv8;
  s1_ds_box__wrote_any := false;
  s1_ds_box__wrote_index0 := false;
  s1_ds_box__next_write_site := 0;
  s1_ds_box__last_write_site := 0;
  s1_ds_box__last0_old_value := 0bv8;
  s1_ds_box__last0_value := 0bv8;
  s1_es_box__last_index := 0bv32;
  s1_es_box__last_value := 0bv8;
  s1_es_box__last_old_value := 0bv8;
  s1_es_box__wrote_any := false;
  s1_es_box__wrote_index0 := false;
  s1_es_box__next_write_site := 0;
  s1_es_box__last_write_site := 0;
  s1_es_box__last0_old_value := 0bv8;
  s1_es_box__last0_value := 0bv8;
  s1_user_mac__last_index := 0bv32;
  s1_user_mac__last_value := 0bv48;
  s1_user_mac__last_old_value := 0bv48;
  s1_user_mac__wrote_any := false;
  s1_user_mac__wrote_index0 := false;
  s1_user_mac__next_write_site := 0;
  s1_user_mac__last_write_site := 0;
  s1_user_mac__last0_old_value := 0bv48;
  s1_user_mac__last0_value := 0bv48;

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
  havoc s1_hdr.ethernet.valid;
  havoc s1_hdr.ethernet.dstAddr;
  havoc s1_hdr.ethernet.srcAddr;
  havoc s1_hdr.ethernet.etherType;
  havoc s1_hdr.ipv6.valid;
  havoc s1_hdr.ipv6.version;
  havoc s1_hdr.ipv6.trafclass;
  havoc s1_hdr.ipv6.flowlabel;
  havoc s1_hdr.ipv6.payloadlen;
  havoc s1_hdr.ipv6.nextheader;
  havoc s1_hdr.ipv6.hoplimit;
  havoc s1_hdr.ipv6.srcAddr;
  havoc s1_hdr.ipv6.dstAddr;
  havoc s1_hdr.ipv4_tunnel.valid;
  havoc s1_hdr.ipv4_tunnel.version;
  havoc s1_hdr.ipv4_tunnel.ihl;
  havoc s1_hdr.ipv4_tunnel.diffserv;
  havoc s1_hdr.ipv4_tunnel.totalLen;
  havoc s1_hdr.ipv4_tunnel.identification;
  havoc s1_hdr.ipv4_tunnel.flags;
  havoc s1_hdr.ipv4_tunnel.fragOffset;
  havoc s1_hdr.ipv4_tunnel.ttl;
  havoc s1_hdr.ipv4_tunnel.protocol;
  havoc s1_hdr.ipv4_tunnel.hdrChecksum;
  havoc s1_hdr.ipv4_tunnel.srcAddr;
  havoc s1_hdr.ipv4_tunnel.dstAddr;
  havoc s1_hdr.ipv4.valid;
  havoc s1_hdr.ipv4.version;
  havoc s1_hdr.ipv4.ihl;
  havoc s1_hdr.ipv4.diffserv;
  havoc s1_hdr.ipv4.totalLen;
  havoc s1_hdr.ipv4.identification;
  havoc s1_hdr.ipv4.flags;
  havoc s1_hdr.ipv4.fragOffset;
  havoc s1_hdr.ipv4.ttl;
  havoc s1_hdr.ipv4.protocol;
  havoc s1_hdr.ipv4.hdrChecksum;
  havoc s1_hdr.ipv4.srcAddr;
  havoc s1_hdr.ipv4.dstAddr;
  havoc s1_hdr.tcp.valid;
  havoc s1_hdr.tcp.srcport;
  havoc s1_hdr.tcp.dstport;
  havoc s1_hdr.tcp.sequence;
  havoc s1_hdr.tcp.ackseq;
  havoc s1_hdr.tcp.headerlength;
  havoc s1_hdr.tcp.reservation;
  havoc s1_hdr.tcp.URG;
  havoc s1_hdr.tcp.ACK;
  havoc s1_hdr.tcp.PSH;
  havoc s1_hdr.tcp.RST;
  havoc s1_hdr.tcp.SYN;
  havoc s1_hdr.tcp.FIN;
  havoc s1_hdr.tcp.windowsize;
  havoc s1_hdr.tcp.checksum;
  havoc s1_hdr.tcp.pointer;
  havoc s1_hdr.udp_tunnel.valid;
  havoc s1_hdr.udp_tunnel.srcport;
  havoc s1_hdr.udp_tunnel.dstport;
  havoc s1_hdr.udp_tunnel.userlength;
  havoc s1_hdr.udp_tunnel.checksum;
  assume (s1_standard_metadata.ingress_port == 0bv9);
  assume (s1_standard_metadata.egress_spec == 0bv9);
  assume (s1_standard_metadata.egress_port == 0bv9);
  assume (s1_hdr.ethernet.valid == true);
  assume (s1_hdr.ipv4.valid == true);
  assume (s1_hdr.tcp.valid == true);
  assume (s1_hdr.ipv4.dstAddr != 2071690107bv32);
  assume (s1_hdr.ethernet.dstAddr != 281474976710655bv48);
  assume (s1_hdr.ethernet.srcAddr != 0bv48);
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
  s1_count__dbg0 := s1_count[0bv32];
  s1_count__last_index__dbg := s1_count__last_index;
  s1_count__last_value__dbg := s1_count__last_value;
  s1_count__last_old_value__dbg := s1_count__last_old_value;
  s1_count__wrote_any__dbg := s1_count__wrote_any;
  s1_count__wrote_index0__dbg := s1_count__wrote_index0;
  s1_count__last0_old_value__dbg := s1_count__last0_old_value;
  s1_count__last0_value__dbg := s1_count__last0_value;
  s1_ds_box__dbg0 := s1_ds_box[0bv32];
  s1_ds_box__last_index__dbg := s1_ds_box__last_index;
  s1_ds_box__last_value__dbg := s1_ds_box__last_value;
  s1_ds_box__last_old_value__dbg := s1_ds_box__last_old_value;
  s1_ds_box__wrote_any__dbg := s1_ds_box__wrote_any;
  s1_ds_box__wrote_index0__dbg := s1_ds_box__wrote_index0;
  s1_ds_box__last0_old_value__dbg := s1_ds_box__last0_old_value;
  s1_ds_box__last0_value__dbg := s1_ds_box__last0_value;
  s1_es_box__dbg0 := s1_es_box[0bv32];
  s1_es_box__last_index__dbg := s1_es_box__last_index;
  s1_es_box__last_value__dbg := s1_es_box__last_value;
  s1_es_box__last_old_value__dbg := s1_es_box__last_old_value;
  s1_es_box__wrote_any__dbg := s1_es_box__wrote_any;
  s1_es_box__wrote_index0__dbg := s1_es_box__wrote_index0;
  s1_es_box__last0_old_value__dbg := s1_es_box__last0_old_value;
  s1_es_box__last0_value__dbg := s1_es_box__last0_value;
  s1_user_mac__dbg0 := s1_user_mac[0bv32];
  s1_user_mac__last_index__dbg := s1_user_mac__last_index;
  s1_user_mac__last_value__dbg := s1_user_mac__last_value;
  s1_user_mac__last_old_value__dbg := s1_user_mac__last_old_value;
  s1_user_mac__wrote_any__dbg := s1_user_mac__wrote_any;
  s1_user_mac__wrote_index0__dbg := s1_user_mac__wrote_index0;
  s1_user_mac__last0_old_value__dbg := s1_user_mac__last0_old_value;
  s1_user_mac__last0_value__dbg := s1_user_mac__last0_value;
  // Global assertions (accumulated into procurator_bad)
  if (!(((s1_standard_metadata.ingress_port != 0bv9) || (s1_standard_metadata.egress_spec == 1bv9) || (s1_standard_metadata.egress_spec == 2bv9) || (s1_standard_metadata.egress_spec == 3bv9)))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  assert !procurator_bad;
}


procedure ULTIMATE.start() returns()
  modifies procurator_bad, procurator_step, s1_count, s1_count__dbg0, s1_count__last0_old_value, s1_count__last0_old_value__dbg, s1_count__last0_value, s1_count__last0_value__dbg, s1_count__last_index, s1_count__last_index__dbg, s1_count__last_old_value, s1_count__last_old_value__dbg, s1_count__last_value, s1_count__last_value__dbg, s1_count__last_write_site, s1_count__next_write_site, s1_count__wrote_any, s1_count__wrote_any__dbg, s1_count__wrote_index0, s1_count__wrote_index0__dbg, s1_drop, s1_ds_box__dbg0, s1_ds_box__last0_old_value, s1_ds_box__last0_old_value__dbg, s1_ds_box__last0_value, s1_ds_box__last0_value__dbg, s1_ds_box__last_index, s1_ds_box__last_index__dbg, s1_ds_box__last_old_value, s1_ds_box__last_old_value__dbg, s1_ds_box__last_value, s1_ds_box__last_value__dbg, s1_ds_box__last_write_site, s1_ds_box__next_write_site, s1_ds_box__wrote_any, s1_ds_box__wrote_any__dbg, s1_ds_box__wrote_index0, s1_ds_box__wrote_index0__dbg, s1_es_box__dbg0, s1_es_box__last0_old_value, s1_es_box__last0_old_value__dbg, s1_es_box__last0_value, s1_es_box__last0_value__dbg, s1_es_box__last_index, s1_es_box__last_index__dbg, s1_es_box__last_old_value, s1_es_box__last_old_value__dbg, s1_es_box__last_value, s1_es_box__last_value__dbg, s1_es_box__last_write_site, s1_es_box__next_write_site, s1_es_box__wrote_any, s1_es_box__wrote_any__dbg, s1_es_box__wrote_index0, s1_es_box__wrote_index0__dbg, s1_forward, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.etherType, s1_hdr.ethernet.srcAddr, s1_hdr.ethernet.valid, s1_hdr.ipv4.diffserv, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.flags, s1_hdr.ipv4.fragOffset, s1_hdr.ipv4.hdrChecksum, s1_hdr.ipv4.identification, s1_hdr.ipv4.ihl, s1_hdr.ipv4.protocol, s1_hdr.ipv4.srcAddr, s1_hdr.ipv4.totalLen, s1_hdr.ipv4.ttl, s1_hdr.ipv4.valid, s1_hdr.ipv4.version, s1_hdr.ipv4_tunnel.diffserv, s1_hdr.ipv4_tunnel.dstAddr, s1_hdr.ipv4_tunnel.flags, s1_hdr.ipv4_tunnel.fragOffset, s1_hdr.ipv4_tunnel.hdrChecksum, s1_hdr.ipv4_tunnel.identification, s1_hdr.ipv4_tunnel.ihl, s1_hdr.ipv4_tunnel.protocol, s1_hdr.ipv4_tunnel.srcAddr, s1_hdr.ipv4_tunnel.totalLen, s1_hdr.ipv4_tunnel.ttl, s1_hdr.ipv4_tunnel.valid, s1_hdr.ipv4_tunnel.version, s1_hdr.ipv6.dstAddr, s1_hdr.ipv6.flowlabel, s1_hdr.ipv6.hoplimit, s1_hdr.ipv6.nextheader, s1_hdr.ipv6.payloadlen, s1_hdr.ipv6.srcAddr, s1_hdr.ipv6.trafclass, s1_hdr.ipv6.valid, s1_hdr.ipv6.version, s1_hdr.tcp.ACK, s1_hdr.tcp.FIN, s1_hdr.tcp.PSH, s1_hdr.tcp.RST, s1_hdr.tcp.SYN, s1_hdr.tcp.URG, s1_hdr.tcp.ackseq, s1_hdr.tcp.checksum, s1_hdr.tcp.dstport, s1_hdr.tcp.headerlength, s1_hdr.tcp.pointer, s1_hdr.tcp.reservation, s1_hdr.tcp.sequence, s1_hdr.tcp.srcport, s1_hdr.tcp.valid, s1_hdr.tcp.windowsize, s1_hdr.udp_tunnel.checksum, s1_hdr.udp_tunnel.dstport, s1_hdr.udp_tunnel.srcport, s1_hdr.udp_tunnel.userlength, s1_hdr.udp_tunnel.valid, s1_inbox_count, s1_isValid, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_external, s1_standard_metadata.checksum_error, s1_standard_metadata.deq_qdepth, s1_standard_metadata.deq_timedelta, s1_standard_metadata.egress_global_timestamp, s1_standard_metadata.egress_port, s1_standard_metadata.egress_rid, s1_standard_metadata.egress_spec, s1_standard_metadata.enq_qdepth, s1_standard_metadata.enq_timestamp, s1_standard_metadata.ingress_global_timestamp, s1_standard_metadata.ingress_port, s1_standard_metadata.instance_type, s1_standard_metadata.mcast_grp, s1_standard_metadata.packet_length, s1_standard_metadata.parser_error, s1_standard_metadata.priority, s1_temp_0, s1_user_mac, s1_user_mac__dbg0, s1_user_mac__last0_old_value, s1_user_mac__last0_old_value__dbg, s1_user_mac__last0_value, s1_user_mac__last0_value__dbg, s1_user_mac__last_index, s1_user_mac__last_index__dbg, s1_user_mac__last_old_value, s1_user_mac__last_old_value__dbg, s1_user_mac__last_value, s1_user_mac__last_value__dbg, s1_user_mac__last_write_site, s1_user_mac__next_write_site, s1_user_mac__wrote_any, s1_user_mac__wrote_any__dbg, s1_user_mac__wrote_index0, s1_user_mac__wrote_index0__dbg;
{
  call mainProcedure();
}

// ===== END HARNESS =====
