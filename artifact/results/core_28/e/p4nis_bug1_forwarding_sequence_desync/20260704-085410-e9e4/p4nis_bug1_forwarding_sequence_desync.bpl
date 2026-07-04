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
var s1_standard_metadata:s1_standard_metadata_t;
var s1_temp_0:bv32;

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
	modifies s1_count, s1_count__last0_old_value, s1_count__last0_value, s1_count__last_index, s1_count__last_old_value, s1_count__last_value, s1_count__last_write_site, s1_count__next_write_site, s1_count__wrote_any, s1_count__wrote_index0, s1_forward, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_temp_0;
{
havoc s1_temp_0;
    if((s1_standard_metadata.ingress_port == 0bv9)){
        if((s1_hdr.ipv4.dstAddr == 2071690107bv32)){
            s1_standard_metadata.egress_spec := 1bv9;
            s1_standard_metadata.egress_port := 1bv9;
            s1_forward := true;
        }
        else{
            if(((s1_hdr.ethernet.dstAddr != 281474976710655bv48)) && ((s1_hdr.ethernet.srcAddr != 0bv48))){
                call s1_MyIngress_do_read_count();
                if((s1_temp_0 == 0bv32)){
                    // s1_write
                    s1_count__next_write_site := 1;
                    assume (0bv32 == 0bv32);
                    call s1_count.write(0bv32, 1bv32);
                    s1_standard_metadata.egress_spec := 1bv9;
                    s1_standard_metadata.egress_port := 1bv9;
                    s1_forward := true;
                }
                if((s1_temp_0 == 1bv32)){
                    // s1_write
                    s1_count__next_write_site := 2;
                    assume (0bv32 == 0bv32);
                    call s1_count.write(0bv32, 2bv32);
                    s1_standard_metadata.egress_spec := 2bv9;
                    s1_standard_metadata.egress_port := 2bv9;
                    s1_forward := true;
                }
                if((s1_temp_0 == 2bv32)){
                    // s1_write
                    s1_count__next_write_site := 3;
                    assume (0bv32 == 0bv32);
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
        s1_standard_metadata.egress_spec := 0bv9;
        s1_standard_metadata.egress_port := 0bv9;
        s1_forward := true;
    }
}

// s1_Action s1_MyIngress_do_read_count
procedure {:inline 1} s1_MyIngress_do_read_count()
	modifies s1_temp_0;
{
    // s1_read
        assume (0bv32 == 0bv32);
s1_temp_0 := s1_count.read(s1_count, 0bv32);
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
procedure {:inline 1} s1_main()
	modifies s1_count, s1_count__last0_old_value, s1_count__last0_value, s1_count__last_index, s1_count__last_old_value, s1_count__last_value, s1_count__last_write_site, s1_count__next_write_site, s1_count__wrote_any, s1_count__wrote_index0, s1_drop, s1_forward, s1_isValid, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_temp_0;
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
	modifies s1_count, s1_count__last0_old_value, s1_count__last0_value, s1_count__last_index, s1_count__last_old_value, s1_count__last_value, s1_count__last_write_site, s1_count__next_write_site, s1_count__wrote_any, s1_count__wrote_index0, s1_drop, s1_forward, s1_isValid, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_temp_0;
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
procedure s1_packet_in.extract(s1_header:s1_Ref);
    ensures (s1_isValid[s1_header] == true);
	modifies s1_isValid;
procedure s1_reject();
    ensures s1_drop==true;
	modifies s1_drop;
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
  modifies procurator_bad, procurator_step, s1_count, s1_count__dbg0, s1_count__last0_old_value, s1_count__last0_old_value__dbg, s1_count__last0_value, s1_count__last0_value__dbg, s1_count__last_index, s1_count__last_index__dbg, s1_count__last_old_value, s1_count__last_old_value__dbg, s1_count__last_value, s1_count__last_value__dbg, s1_count__last_write_site, s1_count__next_write_site, s1_count__wrote_any, s1_count__wrote_any__dbg, s1_count__wrote_index0, s1_count__wrote_index0__dbg, s1_drop, s1_forward, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.etherType, s1_hdr.ethernet.srcAddr, s1_hdr.ethernet.valid, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.protocol, s1_hdr.ipv4.valid, s1_hdr.ipv4_tunnel.protocol, s1_hdr.ipv6.nextheader, s1_hdr.tcp.valid, s1_inbox_count, s1_isValid, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_external, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_standard_metadata.ingress_port, s1_temp_0;
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

  procurator_step := 0;
  procurator_bad := false;
  // step 0: env_inject -> s1
  if (s1_inbox_count < 1) {
  assume s1_inbox_count < 1;
  s1_pkt_external := true;
  havoc s1_standard_metadata.ingress_port;
  havoc s1_hdr.ethernet.valid;
  havoc s1_hdr.ethernet.dstAddr;
  havoc s1_hdr.ethernet.srcAddr;
  havoc s1_hdr.ethernet.etherType;
  havoc s1_hdr.ipv6.nextheader;
  havoc s1_hdr.ipv4_tunnel.protocol;
  havoc s1_hdr.ipv4.valid;
  havoc s1_hdr.ipv4.protocol;
  havoc s1_hdr.ipv4.dstAddr;
  havoc s1_hdr.tcp.valid;
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
  // Global assertions (accumulated into procurator_bad)
  if (!(((s1_standard_metadata.ingress_port != 0bv9) || (s1_standard_metadata.egress_spec == 1bv9) || (s1_standard_metadata.egress_spec == 2bv9) || (s1_standard_metadata.egress_spec == 3bv9)))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  assert !procurator_bad;
}


procedure ULTIMATE.start() returns()
  modifies procurator_bad, procurator_step, s1_count, s1_count__dbg0, s1_count__last0_old_value, s1_count__last0_old_value__dbg, s1_count__last0_value, s1_count__last0_value__dbg, s1_count__last_index, s1_count__last_index__dbg, s1_count__last_old_value, s1_count__last_old_value__dbg, s1_count__last_value, s1_count__last_value__dbg, s1_count__last_write_site, s1_count__next_write_site, s1_count__wrote_any, s1_count__wrote_any__dbg, s1_count__wrote_index0, s1_count__wrote_index0__dbg, s1_drop, s1_forward, s1_hdr.ethernet.dstAddr, s1_hdr.ethernet.etherType, s1_hdr.ethernet.srcAddr, s1_hdr.ethernet.valid, s1_hdr.ipv4.dstAddr, s1_hdr.ipv4.protocol, s1_hdr.ipv4.valid, s1_hdr.ipv4_tunnel.protocol, s1_hdr.ipv6.nextheader, s1_hdr.tcp.valid, s1_inbox_count, s1_isValid, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_external, s1_standard_metadata.egress_port, s1_standard_metadata.egress_spec, s1_standard_metadata.ingress_port, s1_temp_0;
{
  call mainProcedure();
}

// ===== END HARNESS =====
