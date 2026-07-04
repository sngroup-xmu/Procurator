// ===== BEGIN PREAMBLE =====
function bvule.bv16(left:bv16, right:bv16) returns(bool);
function {:builtin "bvule"} bvule.bv16$builtin(left:bv16, right:bv16) returns(bool);
axiom (forall left:bv16, right:bv16 :: bvule.bv16(left, right) <==> bvule.bv16$builtin(left, right));
function bvule.bv32(left:bv32, right:bv32) returns(bool);
function {:builtin "bvule"} bvule.bv32$builtin(left:bv32, right:bv32) returns(bool);
axiom (forall left:bv32, right:bv32 :: bvule.bv32(left, right) <==> bvule.bv32$builtin(left, right));
// ===== END PREAMBLE =====

// ===== BEGIN NODE acceptor0 (prefixed) =====
type acceptor0_Ref;
type acceptor0_error=bv1;
type acceptor0_HeaderStack = [int]acceptor0_Ref;
var acceptor0_last:[acceptor0_HeaderStack]acceptor0_Ref;
var acceptor0_forward:bool;
var acceptor0_isValid:[acceptor0_Ref]bool;
var acceptor0_emit:[acceptor0_Ref]bool;
var acceptor0_stack.index:[acceptor0_HeaderStack]int;
var acceptor0_size:[acceptor0_HeaderStack]int;
var acceptor0_drop:bool;
var acceptor0_p4b_clone_i2e:bool;
var acceptor0_p4b_clone_e2e:bool;
var acceptor0_p4b_clone_i2i:bool;
var acceptor0_p4b_recirculate:bool;
var acceptor0_p4b_digest:bool;
var acceptor0_p4b_checksum_verified:bool;
var acceptor0_p4b_checksum_updated:bool;
var acceptor0_p4b_checksum_error:bool;

// acceptor0_Struct acceptor0_standard_metadata_t
type acceptor0_standard_metadata_t;
var acceptor0_standard_metadata.egress_port:bv9;
type acceptor0_CounterType = int;
type acceptor0_MeterType = int;
type acceptor0_HashAlgorithm = int;
type acceptor0_CloneType = int;
type acceptor0_EthernetAddress = bv48;
type acceptor0_IPv4Address = bv32;
type acceptor0_PortId = bv4;
type acceptor0_ethernet_t;
type acceptor0_arp_t;
type acceptor0_ipv4_t;
type acceptor0_icmp_t;
type acceptor0_udp_t;
type acceptor0_paxos_t;

// acceptor0_Struct acceptor0_headers
var acceptor0_hdr:acceptor0_Ref;

// acceptor0_Header acceptor0_ethernet_t
var acceptor0_hdr.ethernet:acceptor0_Ref;
var acceptor0_hdr.ethernet.valid:bool;
var acceptor0_hdr.ethernet.dstAddr:acceptor0_EthernetAddress;
var acceptor0_hdr.ethernet.srcAddr:acceptor0_EthernetAddress;
var acceptor0_hdr.ethernet.etherType:bv16;

// acceptor0_Header acceptor0_arp_t
var acceptor0_hdr.arp:acceptor0_Ref;
var acceptor0_hdr.arp.valid:bool;
var acceptor0_hdr.arp.hrd:bv16;
var acceptor0_hdr.arp.pro:bv16;
var acceptor0_hdr.arp.hln:bv8;
var acceptor0_hdr.arp.pln:bv8;
var acceptor0_hdr.arp.op:bv16;
var acceptor0_hdr.arp.sha:bv48;
var acceptor0_hdr.arp.spa:bv32;
var acceptor0_hdr.arp.tha:bv48;
var acceptor0_hdr.arp.tpa:bv32;

// acceptor0_Header acceptor0_ipv4_t
var acceptor0_hdr.ipv4:acceptor0_Ref;
var acceptor0_hdr.ipv4.valid:bool;
var acceptor0_hdr.ipv4.version:bv4;
var acceptor0_hdr.ipv4.ihl:bv4;
var acceptor0_hdr.ipv4.diffserv:bv8;
var acceptor0_hdr.ipv4.totalLen:bv16;
var acceptor0_hdr.ipv4.identification:bv16;
var acceptor0_hdr.ipv4.flags:bv3;
var acceptor0_hdr.ipv4.fragOffset:bv13;
var acceptor0_hdr.ipv4.ttl:bv8;
var acceptor0_hdr.ipv4.protocol:bv8;
var acceptor0_hdr.ipv4.hdrChecksum:bv16;
var acceptor0_hdr.ipv4.srcAddr:acceptor0_IPv4Address;
var acceptor0_hdr.ipv4.dstAddr:acceptor0_IPv4Address;

// acceptor0_Header acceptor0_icmp_t
var acceptor0_hdr.icmp:acceptor0_Ref;
var acceptor0_hdr.icmp.valid:bool;
var acceptor0_hdr.icmp.icmpType:bv8;
var acceptor0_hdr.icmp.icmpCode:bv8;
var acceptor0_hdr.icmp.hdrChecksum:bv16;
var acceptor0_hdr.icmp.identifier:bv16;
var acceptor0_hdr.icmp.seqNumber:bv16;
var acceptor0_hdr.icmp.payload:bv256;

// acceptor0_Header acceptor0_udp_t
var acceptor0_hdr.udp:acceptor0_Ref;
var acceptor0_hdr.udp.valid:bool;
var acceptor0_hdr.udp.srcPort:bv16;
var acceptor0_hdr.udp.dstPort:bv16;
var acceptor0_hdr.udp.length_:bv16;
var acceptor0_hdr.udp.checksum:bv16;

// acceptor0_Header acceptor0_paxos_t
var acceptor0_hdr.paxos:acceptor0_Ref;
var acceptor0_hdr.paxos.valid:bool;
var acceptor0_hdr.paxos.msgtype:bv16;
var acceptor0_hdr.paxos.inst:bv32;
var acceptor0_hdr.paxos.rnd:bv16;
var acceptor0_hdr.paxos.vrnd:bv16;
var acceptor0_hdr.paxos.acptid:bv16;
var acceptor0_hdr.paxos.paxoslen:bv32;
var acceptor0_hdr.paxos.paxosval:bv256;

// acceptor0_Struct acceptor0_paxos_metadata_t
type acceptor0_paxos_metadata_t;

// acceptor0_Struct acceptor0_metadata
type acceptor0_metadata;
var acceptor0_meta.paxos_metadata:acceptor0_paxos_metadata_t;
var acceptor0_meta.paxos_metadata.round:bv16;
var acceptor0_meta.paxos_metadata.set_drop:bv1;
var acceptor0_meta.paxos_metadata.ack_count:bv8;
var acceptor0_meta.paxos_metadata.ack_acceptors:bv8;
var acceptor0_meta:acceptor0_metadata;

// acceptor0_Register acceptor0_ingress_registerRound
var acceptor0_ingress_registerRound:[bv32]bv16;
var acceptor0_ingress_registerRound__last_index:bv32;
var acceptor0_ingress_registerRound__last_value:bv16;
var acceptor0_ingress_registerRound__last_old_value:bv16;
var acceptor0_ingress_registerRound__wrote_any:bool;
var acceptor0_ingress_registerRound__wrote_index0:bool;
var acceptor0_ingress_registerRound__last0_old_value:bv16;
var acceptor0_ingress_registerRound__last0_value:bv16;
var acceptor0_ingress_registerRound__next_write_site:int;
var acceptor0_ingress_registerRound__last_write_site:int;
const acceptor0_ingress_registerRound.size:bv32;
axiom acceptor0_ingress_registerRound.size == 65536bv32;

// acceptor0_Register acceptor0_ingress_registerVRound
var acceptor0_ingress_registerVRound:[bv32]bv16;
var acceptor0_ingress_registerVRound__last_index:bv32;
var acceptor0_ingress_registerVRound__last_value:bv16;
var acceptor0_ingress_registerVRound__last_old_value:bv16;
var acceptor0_ingress_registerVRound__wrote_any:bool;
var acceptor0_ingress_registerVRound__wrote_index0:bool;
var acceptor0_ingress_registerVRound__last0_old_value:bv16;
var acceptor0_ingress_registerVRound__last0_value:bv16;
var acceptor0_ingress_registerVRound__next_write_site:int;
var acceptor0_ingress_registerVRound__last_write_site:int;
const acceptor0_ingress_registerVRound.size:bv32;
axiom acceptor0_ingress_registerVRound.size == 65536bv32;

// acceptor0_Table acceptor0_ingress_acceptor_tbl acceptor0_Actionlist acceptor0_Declaration
type acceptor0_ingress_acceptor_tbl.action;
const unique acceptor0_ingress_acceptor_tbl.action.ingress_handle_1a : acceptor0_ingress_acceptor_tbl.action;
const unique acceptor0_ingress_acceptor_tbl.action.ingress_handle_2a : acceptor0_ingress_acceptor_tbl.action;
const unique acceptor0_ingress_acceptor_tbl.action.ingress_drop : acceptor0_ingress_acceptor_tbl.action;
var acceptor0_ingress_acceptor_tbl.action_run : acceptor0_ingress_acceptor_tbl.action;
var acceptor0_ingress_acceptor_tbl.hit : bool;

function {:builtin "bvuge"} buge.bv16(acceptor0_left:bv16, acceptor0_right:bv16) returns(bool);

function {:builtin "bvsub"} sub.bv17(acceptor0_left:bv17, acceptor0_right:bv17) returns(bv17);

function {:builtin "bvsub"} sub.bv33(acceptor0_left:bv33, acceptor0_right:bv33) returns(bv33);

// acceptor0_Parser acceptor0_TopParser
procedure {:inline 1} acceptor0_TopParser()
	modifies acceptor0_drop, acceptor0_isValid;
{
    goto acceptor0_State$TopParser$start;

        acceptor0_State$TopParser$start:
    call acceptor0_packet_in.extract(acceptor0_hdr.ethernet);
    goto acceptor0_State$TopParser$start$parse_arp_2, acceptor0_State$TopParser$start$parse_ipv4_1, acceptor0_State$TopParser$start$DEFAULT;
    
acceptor0_State$TopParser$start$parse_arp_2:
    assume (acceptor0_hdr.ethernet.etherType == 2054bv16);
    goto acceptor0_State$TopParser$parse_arp;
    
acceptor0_State$TopParser$start$parse_ipv4_1:
    assume (acceptor0_hdr.ethernet.etherType == 2048bv16);
    goto acceptor0_State$TopParser$parse_ipv4;

    acceptor0_State$TopParser$start$DEFAULT:
    assume(!(acceptor0_hdr.ethernet.etherType == 2054bv16)&&!(acceptor0_hdr.ethernet.etherType == 2048bv16));
goto acceptor0_State$reject;

        acceptor0_State$TopParser$parse_arp:
    call acceptor0_packet_in.extract(acceptor0_hdr.arp);
    goto acceptor0_State$accept;

        acceptor0_State$TopParser$parse_ipv4:
    call acceptor0_packet_in.extract(acceptor0_hdr.ipv4);
    goto acceptor0_State$TopParser$parse_ipv4$parse_icmp_3, acceptor0_State$TopParser$parse_ipv4$parse_udp_2, acceptor0_State$TopParser$parse_ipv4$DEFAULT;
    
acceptor0_State$TopParser$parse_ipv4$parse_icmp_3:
    assume (acceptor0_hdr.ipv4.protocol == 1bv8);
    goto acceptor0_State$TopParser$parse_icmp;
    
acceptor0_State$TopParser$parse_ipv4$parse_udp_2:
    assume (acceptor0_hdr.ipv4.protocol == 17bv8);
    goto acceptor0_State$TopParser$parse_udp;

    acceptor0_State$TopParser$parse_ipv4$DEFAULT:
    assume(!(acceptor0_hdr.ipv4.protocol == 1bv8)&&!(acceptor0_hdr.ipv4.protocol == 17bv8));
    goto acceptor0_State$accept;

        acceptor0_State$TopParser$parse_icmp:
    call acceptor0_packet_in.extract(acceptor0_hdr.icmp);
    goto acceptor0_State$accept;

        acceptor0_State$TopParser$parse_udp:
    call acceptor0_packet_in.extract(acceptor0_hdr.udp);
    goto acceptor0_State$TopParser$parse_udp$parse_paxos_2, acceptor0_State$TopParser$parse_udp$DEFAULT;
    
acceptor0_State$TopParser$parse_udp$parse_paxos_2:
    assume (acceptor0_hdr.udp.dstPort == 34952bv16);
    goto acceptor0_State$TopParser$parse_paxos;

    acceptor0_State$TopParser$parse_udp$DEFAULT:
    assume(!(acceptor0_hdr.udp.dstPort == 34952bv16));
    goto acceptor0_State$accept;

        acceptor0_State$TopParser$parse_paxos:
    call acceptor0_packet_in.extract(acceptor0_hdr.paxos);
    goto acceptor0_State$accept;

    acceptor0_State$accept:
    call acceptor0_accept();
    goto acceptor0_Exit;

    acceptor0_State$reject:
    call acceptor0_reject();
    goto acceptor0_Exit;

    acceptor0_Exit:
}
procedure {:inline 1} acceptor0_accept()
{
}

// acceptor0_Control acceptor0_computeChecksum
procedure {:inline 1} acceptor0_computeChecksum()
{
}

// acceptor0_Control acceptor0_egress
procedure {:inline 1} acceptor0_egress()
{
}

// acceptor0_Control acceptor0_ingress
procedure {:inline 1} acceptor0_ingress()
	modifies acceptor0_hdr.paxos.msgtype, acceptor0_hdr.paxos.vrnd, acceptor0_ingress_acceptor_tbl.action_run, acceptor0_ingress_acceptor_tbl.hit, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_index0, acceptor0_meta.paxos_metadata.round;
{
    if(acceptor0_isValid[acceptor0_hdr.arp]){
    }
    else{
        if(acceptor0_isValid[acceptor0_hdr.ipv4]){
            if(acceptor0_isValid[acceptor0_hdr.paxos]){
                call acceptor0_ingress_read_round();
                if(buge.bv16(acceptor0_hdr.paxos.rnd, acceptor0_meta.paxos_metadata.round)){
                    // acceptor0_read
                    acceptor0_hdr.paxos.vrnd := acceptor0_ingress_registerVRound.read(acceptor0_ingress_registerVRound, acceptor0_hdr.paxos.inst);
                    call acceptor0_ingress_acceptor_tbl.apply();
                }
            }
            else{
            }
        }
    }
}

// acceptor0_Table acceptor0_ingress_acceptor_tbl
procedure {:inline 1} acceptor0_ingress_acceptor_tbl.apply()
	modifies acceptor0_hdr.paxos.msgtype, acceptor0_ingress_acceptor_tbl.action_run, acceptor0_ingress_acceptor_tbl.hit, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_index0;
{
    acceptor0_hdr.paxos.msgtype := acceptor0_hdr.paxos.msgtype;
    acceptor0_ingress_acceptor_tbl.hit := false;
    goto acceptor0_action_ingress_handle_1a, acceptor0_action_ingress_handle_2a, acceptor0_action_ingress_drop;

    acceptor0_action_ingress_handle_1a:
    assume acceptor0_ingress_acceptor_tbl.action_run == acceptor0_ingress_acceptor_tbl.action.ingress_handle_1a;
    call acceptor0_ingress_handle_1a();
    goto acceptor0_Exit;

    acceptor0_action_ingress_handle_2a:
    assume acceptor0_ingress_acceptor_tbl.action_run == acceptor0_ingress_acceptor_tbl.action.ingress_handle_2a;
    call acceptor0_ingress_handle_2a();
    goto acceptor0_Exit;

    acceptor0_action_ingress_drop:
    assume acceptor0_ingress_acceptor_tbl.action_run == acceptor0_ingress_acceptor_tbl.action.ingress_drop;
    call acceptor0_ingress_drop();
    goto acceptor0_Exit;

    acceptor0_Exit:
}

// acceptor0_Action acceptor0_ingress_drop
procedure {:inline 1} acceptor0_ingress_drop()
{
}

// acceptor0_Action acceptor0_ingress_handle_1a
procedure {:inline 1} acceptor0_ingress_handle_1a()
	modifies acceptor0_hdr.paxos.msgtype, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_index0;
{
    acceptor0_hdr.paxos.msgtype := 1bv16;
    // acceptor0_write
    acceptor0_ingress_registerRound__next_write_site := 1;
    call acceptor0_ingress_registerRound.write(acceptor0_hdr.paxos.inst, acceptor0_hdr.paxos.rnd);
}

// acceptor0_Action acceptor0_ingress_handle_2a
procedure {:inline 1} acceptor0_ingress_handle_2a()
	modifies acceptor0_hdr.paxos.msgtype, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_index0;
{
    acceptor0_hdr.paxos.msgtype := 3bv16;
    // acceptor0_write
    acceptor0_ingress_registerRound__next_write_site := 2;
    call acceptor0_ingress_registerRound.write(acceptor0_hdr.paxos.inst, acceptor0_hdr.paxos.rnd);
}

// acceptor0_Action acceptor0_ingress_read_round
procedure {:inline 1} acceptor0_ingress_read_round()
	modifies acceptor0_meta.paxos_metadata.round;
{
    // acceptor0_read
    acceptor0_meta.paxos_metadata.round := acceptor0_ingress_registerRound.read(acceptor0_ingress_registerRound, acceptor0_hdr.paxos.inst);
}
function {:inline true}acceptor0_ingress_registerRound.read(acceptor0_reg:[bv32]bv16, acceptor0_index:bv32)returns (bv16) {acceptor0_reg[acceptor0_index]}
procedure {:inline 1} acceptor0_ingress_registerRound.write(acceptor0_index:bv32, acceptor0_value:bv16)
	modifies acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_index0;
{
    acceptor0_ingress_registerRound__last_old_value := acceptor0_ingress_registerRound[acceptor0_index];
    acceptor0_ingress_registerRound[acceptor0_index] := acceptor0_value;
    acceptor0_ingress_registerRound__last_index := acceptor0_index;
    acceptor0_ingress_registerRound__last_value := acceptor0_value;
    acceptor0_ingress_registerRound__last_write_site := acceptor0_ingress_registerRound__next_write_site;
    acceptor0_ingress_registerRound__wrote_any := true;
    if (acceptor0_index == 0bv32) {
        acceptor0_ingress_registerRound__wrote_index0 := true;
        acceptor0_ingress_registerRound__last0_old_value := acceptor0_ingress_registerRound__last_old_value;
        acceptor0_ingress_registerRound__last0_value := acceptor0_value;
    }
}
function {:inline true}acceptor0_ingress_registerVRound.read(acceptor0_reg:[bv32]bv16, acceptor0_index:bv32)returns (bv16) {acceptor0_reg[acceptor0_index]}
procedure {:inline 1} acceptor0_ingress_registerVRound.write(acceptor0_index:bv32, acceptor0_value:bv16)
	modifies acceptor0_ingress_registerVRound, acceptor0_ingress_registerVRound__last0_old_value, acceptor0_ingress_registerVRound__last0_value, acceptor0_ingress_registerVRound__last_index, acceptor0_ingress_registerVRound__last_old_value, acceptor0_ingress_registerVRound__last_value, acceptor0_ingress_registerVRound__last_write_site, acceptor0_ingress_registerVRound__wrote_any, acceptor0_ingress_registerVRound__wrote_index0;
{
    acceptor0_ingress_registerVRound__last_old_value := acceptor0_ingress_registerVRound[acceptor0_index];
    acceptor0_ingress_registerVRound[acceptor0_index] := acceptor0_value;
    acceptor0_ingress_registerVRound__last_index := acceptor0_index;
    acceptor0_ingress_registerVRound__last_value := acceptor0_value;
    acceptor0_ingress_registerVRound__last_write_site := acceptor0_ingress_registerVRound__next_write_site;
    acceptor0_ingress_registerVRound__wrote_any := true;
    if (acceptor0_index == 0bv32) {
        acceptor0_ingress_registerVRound__wrote_index0 := true;
        acceptor0_ingress_registerVRound__last0_old_value := acceptor0_ingress_registerVRound__last_old_value;
        acceptor0_ingress_registerVRound__last0_value := acceptor0_value;
    }
}
procedure {:inline 1} acceptor0_main()
	modifies acceptor0_drop, acceptor0_hdr.paxos.msgtype, acceptor0_hdr.paxos.vrnd, acceptor0_ingress_acceptor_tbl.action_run, acceptor0_ingress_acceptor_tbl.hit, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_index0, acceptor0_isValid, acceptor0_meta.paxos_metadata.round;
{
    call acceptor0_TopParser();
    call acceptor0_verifyChecksum();
    call acceptor0_ingress();
    call acceptor0_egress();
    call acceptor0_computeChecksum();
    if(acceptor0_forward == false){
        acceptor0_drop := true;
    }
}
procedure acceptor0_mainProcedure()
	modifies acceptor0_drop, acceptor0_hdr.paxos.msgtype, acceptor0_hdr.paxos.vrnd, acceptor0_ingress_acceptor_tbl.action_run, acceptor0_ingress_acceptor_tbl.hit, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_index0, acceptor0_isValid, acceptor0_meta.paxos_metadata.round, acceptor0_p4b_checksum_error, acceptor0_p4b_checksum_updated, acceptor0_p4b_checksum_verified, acceptor0_p4b_clone_e2e, acceptor0_p4b_clone_i2e, acceptor0_p4b_clone_i2i, acceptor0_p4b_digest, acceptor0_p4b_recirculate;
{
    acceptor0_p4b_checksum_error := false;
    acceptor0_p4b_checksum_updated := false;
    acceptor0_p4b_checksum_verified := false;
    acceptor0_p4b_digest := false;
    acceptor0_p4b_recirculate := false;
    acceptor0_p4b_clone_i2i := false;
    acceptor0_p4b_clone_e2e := false;
    acceptor0_p4b_clone_i2e := false;
    call acceptor0_main();
}
procedure acceptor0_packet_in.extract(acceptor0_header:acceptor0_Ref);
    ensures (acceptor0_isValid[acceptor0_header] == true);
	modifies acceptor0_isValid;
procedure acceptor0_reject();
    ensures acceptor0_drop==true;
	modifies acceptor0_drop;

// acceptor0_Control acceptor0_verifyChecksum
procedure {:inline 1} acceptor0_verifyChecksum()
{
}
// ===== END NODE acceptor0 =====

// ===== BEGIN NODE acceptor1 (prefixed) =====
type acceptor1_Ref;
type acceptor1_error=bv1;
type acceptor1_HeaderStack = [int]acceptor1_Ref;
var acceptor1_last:[acceptor1_HeaderStack]acceptor1_Ref;
var acceptor1_forward:bool;
var acceptor1_isValid:[acceptor1_Ref]bool;
var acceptor1_emit:[acceptor1_Ref]bool;
var acceptor1_stack.index:[acceptor1_HeaderStack]int;
var acceptor1_size:[acceptor1_HeaderStack]int;
var acceptor1_drop:bool;
var acceptor1_p4b_clone_i2e:bool;
var acceptor1_p4b_clone_e2e:bool;
var acceptor1_p4b_clone_i2i:bool;
var acceptor1_p4b_recirculate:bool;
var acceptor1_p4b_digest:bool;
var acceptor1_p4b_checksum_verified:bool;
var acceptor1_p4b_checksum_updated:bool;
var acceptor1_p4b_checksum_error:bool;

// acceptor1_Struct acceptor1_standard_metadata_t
type acceptor1_standard_metadata_t;
var acceptor1_standard_metadata.egress_port:bv9;
type acceptor1_CounterType = int;
type acceptor1_MeterType = int;
type acceptor1_HashAlgorithm = int;
type acceptor1_CloneType = int;
type acceptor1_EthernetAddress = bv48;
type acceptor1_IPv4Address = bv32;
type acceptor1_PortId = bv4;
type acceptor1_ethernet_t;
type acceptor1_arp_t;
type acceptor1_ipv4_t;
type acceptor1_icmp_t;
type acceptor1_udp_t;
type acceptor1_paxos_t;

// acceptor1_Struct acceptor1_headers
var acceptor1_hdr:acceptor1_Ref;

// acceptor1_Header acceptor1_ethernet_t
var acceptor1_hdr.ethernet:acceptor1_Ref;
var acceptor1_hdr.ethernet.valid:bool;
var acceptor1_hdr.ethernet.dstAddr:acceptor1_EthernetAddress;
var acceptor1_hdr.ethernet.srcAddr:acceptor1_EthernetAddress;
var acceptor1_hdr.ethernet.etherType:bv16;

// acceptor1_Header acceptor1_arp_t
var acceptor1_hdr.arp:acceptor1_Ref;
var acceptor1_hdr.arp.valid:bool;
var acceptor1_hdr.arp.hrd:bv16;
var acceptor1_hdr.arp.pro:bv16;
var acceptor1_hdr.arp.hln:bv8;
var acceptor1_hdr.arp.pln:bv8;
var acceptor1_hdr.arp.op:bv16;
var acceptor1_hdr.arp.sha:bv48;
var acceptor1_hdr.arp.spa:bv32;
var acceptor1_hdr.arp.tha:bv48;
var acceptor1_hdr.arp.tpa:bv32;

// acceptor1_Header acceptor1_ipv4_t
var acceptor1_hdr.ipv4:acceptor1_Ref;
var acceptor1_hdr.ipv4.valid:bool;
var acceptor1_hdr.ipv4.version:bv4;
var acceptor1_hdr.ipv4.ihl:bv4;
var acceptor1_hdr.ipv4.diffserv:bv8;
var acceptor1_hdr.ipv4.totalLen:bv16;
var acceptor1_hdr.ipv4.identification:bv16;
var acceptor1_hdr.ipv4.flags:bv3;
var acceptor1_hdr.ipv4.fragOffset:bv13;
var acceptor1_hdr.ipv4.ttl:bv8;
var acceptor1_hdr.ipv4.protocol:bv8;
var acceptor1_hdr.ipv4.hdrChecksum:bv16;
var acceptor1_hdr.ipv4.srcAddr:acceptor1_IPv4Address;
var acceptor1_hdr.ipv4.dstAddr:acceptor1_IPv4Address;

// acceptor1_Header acceptor1_icmp_t
var acceptor1_hdr.icmp:acceptor1_Ref;
var acceptor1_hdr.icmp.valid:bool;
var acceptor1_hdr.icmp.icmpType:bv8;
var acceptor1_hdr.icmp.icmpCode:bv8;
var acceptor1_hdr.icmp.hdrChecksum:bv16;
var acceptor1_hdr.icmp.identifier:bv16;
var acceptor1_hdr.icmp.seqNumber:bv16;
var acceptor1_hdr.icmp.payload:bv256;

// acceptor1_Header acceptor1_udp_t
var acceptor1_hdr.udp:acceptor1_Ref;
var acceptor1_hdr.udp.valid:bool;
var acceptor1_hdr.udp.srcPort:bv16;
var acceptor1_hdr.udp.dstPort:bv16;
var acceptor1_hdr.udp.length_:bv16;
var acceptor1_hdr.udp.checksum:bv16;

// acceptor1_Header acceptor1_paxos_t
var acceptor1_hdr.paxos:acceptor1_Ref;
var acceptor1_hdr.paxos.valid:bool;
var acceptor1_hdr.paxos.msgtype:bv16;
var acceptor1_hdr.paxos.inst:bv32;
var acceptor1_hdr.paxos.rnd:bv16;
var acceptor1_hdr.paxos.vrnd:bv16;
var acceptor1_hdr.paxos.acptid:bv16;
var acceptor1_hdr.paxos.paxoslen:bv32;
var acceptor1_hdr.paxos.paxosval:bv256;

// acceptor1_Struct acceptor1_paxos_metadata_t
type acceptor1_paxos_metadata_t;

// acceptor1_Struct acceptor1_metadata
type acceptor1_metadata;
var acceptor1_meta.paxos_metadata:acceptor1_paxos_metadata_t;
var acceptor1_meta.paxos_metadata.round:bv16;
var acceptor1_meta.paxos_metadata.set_drop:bv1;
var acceptor1_meta.paxos_metadata.ack_count:bv8;
var acceptor1_meta.paxos_metadata.ack_acceptors:bv8;
var acceptor1_meta:acceptor1_metadata;

// acceptor1_Register acceptor1_ingress_registerRound
var acceptor1_ingress_registerRound:[bv32]bv16;
var acceptor1_ingress_registerRound__last_index:bv32;
var acceptor1_ingress_registerRound__last_value:bv16;
var acceptor1_ingress_registerRound__last_old_value:bv16;
var acceptor1_ingress_registerRound__wrote_any:bool;
var acceptor1_ingress_registerRound__wrote_index0:bool;
var acceptor1_ingress_registerRound__last0_old_value:bv16;
var acceptor1_ingress_registerRound__last0_value:bv16;
var acceptor1_ingress_registerRound__next_write_site:int;
var acceptor1_ingress_registerRound__last_write_site:int;
const acceptor1_ingress_registerRound.size:bv32;
axiom acceptor1_ingress_registerRound.size == 65536bv32;

// acceptor1_Register acceptor1_ingress_registerVRound
var acceptor1_ingress_registerVRound:[bv32]bv16;
var acceptor1_ingress_registerVRound__last_index:bv32;
var acceptor1_ingress_registerVRound__last_value:bv16;
var acceptor1_ingress_registerVRound__last_old_value:bv16;
var acceptor1_ingress_registerVRound__wrote_any:bool;
var acceptor1_ingress_registerVRound__wrote_index0:bool;
var acceptor1_ingress_registerVRound__last0_old_value:bv16;
var acceptor1_ingress_registerVRound__last0_value:bv16;
var acceptor1_ingress_registerVRound__next_write_site:int;
var acceptor1_ingress_registerVRound__last_write_site:int;
const acceptor1_ingress_registerVRound.size:bv32;
axiom acceptor1_ingress_registerVRound.size == 65536bv32;

// acceptor1_Table acceptor1_ingress_acceptor_tbl acceptor1_Actionlist acceptor1_Declaration
type acceptor1_ingress_acceptor_tbl.action;
const unique acceptor1_ingress_acceptor_tbl.action.ingress_handle_1a : acceptor1_ingress_acceptor_tbl.action;
const unique acceptor1_ingress_acceptor_tbl.action.ingress_handle_2a : acceptor1_ingress_acceptor_tbl.action;
const unique acceptor1_ingress_acceptor_tbl.action.ingress_drop : acceptor1_ingress_acceptor_tbl.action;
var acceptor1_ingress_acceptor_tbl.action_run : acceptor1_ingress_acceptor_tbl.action;
var acceptor1_ingress_acceptor_tbl.hit : bool;




// acceptor1_Parser acceptor1_TopParser
procedure {:inline 1} acceptor1_TopParser()
	modifies acceptor1_drop, acceptor1_isValid;
{
    goto acceptor1_State$TopParser$start;

        acceptor1_State$TopParser$start:
    call acceptor1_packet_in.extract(acceptor1_hdr.ethernet);
    goto acceptor1_State$TopParser$start$parse_arp_2, acceptor1_State$TopParser$start$parse_ipv4_1, acceptor1_State$TopParser$start$DEFAULT;
    
acceptor1_State$TopParser$start$parse_arp_2:
    assume (acceptor1_hdr.ethernet.etherType == 2054bv16);
    goto acceptor1_State$TopParser$parse_arp;
    
acceptor1_State$TopParser$start$parse_ipv4_1:
    assume (acceptor1_hdr.ethernet.etherType == 2048bv16);
    goto acceptor1_State$TopParser$parse_ipv4;

    acceptor1_State$TopParser$start$DEFAULT:
    assume(!(acceptor1_hdr.ethernet.etherType == 2054bv16)&&!(acceptor1_hdr.ethernet.etherType == 2048bv16));
goto acceptor1_State$reject;

        acceptor1_State$TopParser$parse_arp:
    call acceptor1_packet_in.extract(acceptor1_hdr.arp);
    goto acceptor1_State$accept;

        acceptor1_State$TopParser$parse_ipv4:
    call acceptor1_packet_in.extract(acceptor1_hdr.ipv4);
    goto acceptor1_State$TopParser$parse_ipv4$parse_icmp_3, acceptor1_State$TopParser$parse_ipv4$parse_udp_2, acceptor1_State$TopParser$parse_ipv4$DEFAULT;
    
acceptor1_State$TopParser$parse_ipv4$parse_icmp_3:
    assume (acceptor1_hdr.ipv4.protocol == 1bv8);
    goto acceptor1_State$TopParser$parse_icmp;
    
acceptor1_State$TopParser$parse_ipv4$parse_udp_2:
    assume (acceptor1_hdr.ipv4.protocol == 17bv8);
    goto acceptor1_State$TopParser$parse_udp;

    acceptor1_State$TopParser$parse_ipv4$DEFAULT:
    assume(!(acceptor1_hdr.ipv4.protocol == 1bv8)&&!(acceptor1_hdr.ipv4.protocol == 17bv8));
    goto acceptor1_State$accept;

        acceptor1_State$TopParser$parse_icmp:
    call acceptor1_packet_in.extract(acceptor1_hdr.icmp);
    goto acceptor1_State$accept;

        acceptor1_State$TopParser$parse_udp:
    call acceptor1_packet_in.extract(acceptor1_hdr.udp);
    goto acceptor1_State$TopParser$parse_udp$parse_paxos_2, acceptor1_State$TopParser$parse_udp$DEFAULT;
    
acceptor1_State$TopParser$parse_udp$parse_paxos_2:
    assume (acceptor1_hdr.udp.dstPort == 34952bv16);
    goto acceptor1_State$TopParser$parse_paxos;

    acceptor1_State$TopParser$parse_udp$DEFAULT:
    assume(!(acceptor1_hdr.udp.dstPort == 34952bv16));
    goto acceptor1_State$accept;

        acceptor1_State$TopParser$parse_paxos:
    call acceptor1_packet_in.extract(acceptor1_hdr.paxos);
    goto acceptor1_State$accept;

    acceptor1_State$accept:
    call acceptor1_accept();
    goto acceptor1_Exit;

    acceptor1_State$reject:
    call acceptor1_reject();
    goto acceptor1_Exit;

    acceptor1_Exit:
}
procedure {:inline 1} acceptor1_accept()
{
}

// acceptor1_Control acceptor1_computeChecksum
procedure {:inline 1} acceptor1_computeChecksum()
{
}

// acceptor1_Control acceptor1_egress
procedure {:inline 1} acceptor1_egress()
{
}

// acceptor1_Control acceptor1_ingress
procedure {:inline 1} acceptor1_ingress()
	modifies acceptor1_hdr.paxos.msgtype, acceptor1_hdr.paxos.vrnd, acceptor1_ingress_acceptor_tbl.action_run, acceptor1_ingress_acceptor_tbl.hit, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_index0, acceptor1_meta.paxos_metadata.round;
{
    if(acceptor1_isValid[acceptor1_hdr.arp]){
    }
    else{
        if(acceptor1_isValid[acceptor1_hdr.ipv4]){
            if(acceptor1_isValid[acceptor1_hdr.paxos]){
                call acceptor1_ingress_read_round();
                if(buge.bv16(acceptor1_hdr.paxos.rnd, acceptor1_meta.paxos_metadata.round)){
                    // acceptor1_read
                    acceptor1_hdr.paxos.vrnd := acceptor1_ingress_registerVRound.read(acceptor1_ingress_registerVRound, acceptor1_hdr.paxos.inst);
                    call acceptor1_ingress_acceptor_tbl.apply();
                }
            }
            else{
            }
        }
    }
}

// acceptor1_Table acceptor1_ingress_acceptor_tbl
procedure {:inline 1} acceptor1_ingress_acceptor_tbl.apply()
	modifies acceptor1_hdr.paxos.msgtype, acceptor1_ingress_acceptor_tbl.action_run, acceptor1_ingress_acceptor_tbl.hit, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_index0;
{
    acceptor1_hdr.paxos.msgtype := acceptor1_hdr.paxos.msgtype;
    acceptor1_ingress_acceptor_tbl.hit := false;
    goto acceptor1_action_ingress_handle_1a, acceptor1_action_ingress_handle_2a, acceptor1_action_ingress_drop;

    acceptor1_action_ingress_handle_1a:
    assume acceptor1_ingress_acceptor_tbl.action_run == acceptor1_ingress_acceptor_tbl.action.ingress_handle_1a;
    call acceptor1_ingress_handle_1a();
    goto acceptor1_Exit;

    acceptor1_action_ingress_handle_2a:
    assume acceptor1_ingress_acceptor_tbl.action_run == acceptor1_ingress_acceptor_tbl.action.ingress_handle_2a;
    call acceptor1_ingress_handle_2a();
    goto acceptor1_Exit;

    acceptor1_action_ingress_drop:
    assume acceptor1_ingress_acceptor_tbl.action_run == acceptor1_ingress_acceptor_tbl.action.ingress_drop;
    call acceptor1_ingress_drop();
    goto acceptor1_Exit;

    acceptor1_Exit:
}

// acceptor1_Action acceptor1_ingress_drop
procedure {:inline 1} acceptor1_ingress_drop()
{
}

// acceptor1_Action acceptor1_ingress_handle_1a
procedure {:inline 1} acceptor1_ingress_handle_1a()
	modifies acceptor1_hdr.paxos.msgtype, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_index0;
{
    acceptor1_hdr.paxos.msgtype := 1bv16;
    // acceptor1_write
    acceptor1_ingress_registerRound__next_write_site := 1;
    call acceptor1_ingress_registerRound.write(acceptor1_hdr.paxos.inst, acceptor1_hdr.paxos.rnd);
}

// acceptor1_Action acceptor1_ingress_handle_2a
procedure {:inline 1} acceptor1_ingress_handle_2a()
	modifies acceptor1_hdr.paxos.msgtype, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_index0;
{
    acceptor1_hdr.paxos.msgtype := 3bv16;
    // acceptor1_write
    acceptor1_ingress_registerRound__next_write_site := 2;
    call acceptor1_ingress_registerRound.write(acceptor1_hdr.paxos.inst, acceptor1_hdr.paxos.rnd);
}

// acceptor1_Action acceptor1_ingress_read_round
procedure {:inline 1} acceptor1_ingress_read_round()
	modifies acceptor1_meta.paxos_metadata.round;
{
    // acceptor1_read
    acceptor1_meta.paxos_metadata.round := acceptor1_ingress_registerRound.read(acceptor1_ingress_registerRound, acceptor1_hdr.paxos.inst);
}
function {:inline true}acceptor1_ingress_registerRound.read(acceptor1_reg:[bv32]bv16, acceptor1_index:bv32)returns (bv16) {acceptor1_reg[acceptor1_index]}
procedure {:inline 1} acceptor1_ingress_registerRound.write(acceptor1_index:bv32, acceptor1_value:bv16)
	modifies acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_index0;
{
    acceptor1_ingress_registerRound__last_old_value := acceptor1_ingress_registerRound[acceptor1_index];
    acceptor1_ingress_registerRound[acceptor1_index] := acceptor1_value;
    acceptor1_ingress_registerRound__last_index := acceptor1_index;
    acceptor1_ingress_registerRound__last_value := acceptor1_value;
    acceptor1_ingress_registerRound__last_write_site := acceptor1_ingress_registerRound__next_write_site;
    acceptor1_ingress_registerRound__wrote_any := true;
    if (acceptor1_index == 0bv32) {
        acceptor1_ingress_registerRound__wrote_index0 := true;
        acceptor1_ingress_registerRound__last0_old_value := acceptor1_ingress_registerRound__last_old_value;
        acceptor1_ingress_registerRound__last0_value := acceptor1_value;
    }
}
function {:inline true}acceptor1_ingress_registerVRound.read(acceptor1_reg:[bv32]bv16, acceptor1_index:bv32)returns (bv16) {acceptor1_reg[acceptor1_index]}
procedure {:inline 1} acceptor1_ingress_registerVRound.write(acceptor1_index:bv32, acceptor1_value:bv16)
	modifies acceptor1_ingress_registerVRound, acceptor1_ingress_registerVRound__last0_old_value, acceptor1_ingress_registerVRound__last0_value, acceptor1_ingress_registerVRound__last_index, acceptor1_ingress_registerVRound__last_old_value, acceptor1_ingress_registerVRound__last_value, acceptor1_ingress_registerVRound__last_write_site, acceptor1_ingress_registerVRound__wrote_any, acceptor1_ingress_registerVRound__wrote_index0;
{
    acceptor1_ingress_registerVRound__last_old_value := acceptor1_ingress_registerVRound[acceptor1_index];
    acceptor1_ingress_registerVRound[acceptor1_index] := acceptor1_value;
    acceptor1_ingress_registerVRound__last_index := acceptor1_index;
    acceptor1_ingress_registerVRound__last_value := acceptor1_value;
    acceptor1_ingress_registerVRound__last_write_site := acceptor1_ingress_registerVRound__next_write_site;
    acceptor1_ingress_registerVRound__wrote_any := true;
    if (acceptor1_index == 0bv32) {
        acceptor1_ingress_registerVRound__wrote_index0 := true;
        acceptor1_ingress_registerVRound__last0_old_value := acceptor1_ingress_registerVRound__last_old_value;
        acceptor1_ingress_registerVRound__last0_value := acceptor1_value;
    }
}
procedure {:inline 1} acceptor1_main()
	modifies acceptor1_drop, acceptor1_hdr.paxos.msgtype, acceptor1_hdr.paxos.vrnd, acceptor1_ingress_acceptor_tbl.action_run, acceptor1_ingress_acceptor_tbl.hit, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_index0, acceptor1_isValid, acceptor1_meta.paxos_metadata.round;
{
    call acceptor1_TopParser();
    call acceptor1_verifyChecksum();
    call acceptor1_ingress();
    call acceptor1_egress();
    call acceptor1_computeChecksum();
    if(acceptor1_forward == false){
        acceptor1_drop := true;
    }
}
procedure acceptor1_mainProcedure()
	modifies acceptor1_drop, acceptor1_hdr.paxos.msgtype, acceptor1_hdr.paxos.vrnd, acceptor1_ingress_acceptor_tbl.action_run, acceptor1_ingress_acceptor_tbl.hit, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_index0, acceptor1_isValid, acceptor1_meta.paxos_metadata.round, acceptor1_p4b_checksum_error, acceptor1_p4b_checksum_updated, acceptor1_p4b_checksum_verified, acceptor1_p4b_clone_e2e, acceptor1_p4b_clone_i2e, acceptor1_p4b_clone_i2i, acceptor1_p4b_digest, acceptor1_p4b_recirculate;
{
    acceptor1_p4b_checksum_error := false;
    acceptor1_p4b_checksum_updated := false;
    acceptor1_p4b_checksum_verified := false;
    acceptor1_p4b_digest := false;
    acceptor1_p4b_recirculate := false;
    acceptor1_p4b_clone_i2i := false;
    acceptor1_p4b_clone_e2e := false;
    acceptor1_p4b_clone_i2e := false;
    call acceptor1_main();
}
procedure acceptor1_packet_in.extract(acceptor1_header:acceptor1_Ref);
    ensures (acceptor1_isValid[acceptor1_header] == true);
	modifies acceptor1_isValid;
procedure acceptor1_reject();
    ensures acceptor1_drop==true;
	modifies acceptor1_drop;

// acceptor1_Control acceptor1_verifyChecksum
procedure {:inline 1} acceptor1_verifyChecksum()
{
}
// ===== END NODE acceptor1 =====

// ===== BEGIN NODE acceptor2 (prefixed) =====
type acceptor2_Ref;
type acceptor2_error=bv1;
type acceptor2_HeaderStack = [int]acceptor2_Ref;
var acceptor2_last:[acceptor2_HeaderStack]acceptor2_Ref;
var acceptor2_forward:bool;
var acceptor2_isValid:[acceptor2_Ref]bool;
var acceptor2_emit:[acceptor2_Ref]bool;
var acceptor2_stack.index:[acceptor2_HeaderStack]int;
var acceptor2_size:[acceptor2_HeaderStack]int;
var acceptor2_drop:bool;
var acceptor2_p4b_clone_i2e:bool;
var acceptor2_p4b_clone_e2e:bool;
var acceptor2_p4b_clone_i2i:bool;
var acceptor2_p4b_recirculate:bool;
var acceptor2_p4b_digest:bool;
var acceptor2_p4b_checksum_verified:bool;
var acceptor2_p4b_checksum_updated:bool;
var acceptor2_p4b_checksum_error:bool;

// acceptor2_Struct acceptor2_standard_metadata_t
type acceptor2_standard_metadata_t;
var acceptor2_standard_metadata.egress_port:bv9;
type acceptor2_CounterType = int;
type acceptor2_MeterType = int;
type acceptor2_HashAlgorithm = int;
type acceptor2_CloneType = int;
type acceptor2_EthernetAddress = bv48;
type acceptor2_IPv4Address = bv32;
type acceptor2_PortId = bv4;
type acceptor2_ethernet_t;
type acceptor2_arp_t;
type acceptor2_ipv4_t;
type acceptor2_icmp_t;
type acceptor2_udp_t;
type acceptor2_paxos_t;

// acceptor2_Struct acceptor2_headers
var acceptor2_hdr:acceptor2_Ref;

// acceptor2_Header acceptor2_ethernet_t
var acceptor2_hdr.ethernet:acceptor2_Ref;
var acceptor2_hdr.ethernet.valid:bool;
var acceptor2_hdr.ethernet.dstAddr:acceptor2_EthernetAddress;
var acceptor2_hdr.ethernet.srcAddr:acceptor2_EthernetAddress;
var acceptor2_hdr.ethernet.etherType:bv16;

// acceptor2_Header acceptor2_arp_t
var acceptor2_hdr.arp:acceptor2_Ref;
var acceptor2_hdr.arp.valid:bool;
var acceptor2_hdr.arp.hrd:bv16;
var acceptor2_hdr.arp.pro:bv16;
var acceptor2_hdr.arp.hln:bv8;
var acceptor2_hdr.arp.pln:bv8;
var acceptor2_hdr.arp.op:bv16;
var acceptor2_hdr.arp.sha:bv48;
var acceptor2_hdr.arp.spa:bv32;
var acceptor2_hdr.arp.tha:bv48;
var acceptor2_hdr.arp.tpa:bv32;

// acceptor2_Header acceptor2_ipv4_t
var acceptor2_hdr.ipv4:acceptor2_Ref;
var acceptor2_hdr.ipv4.valid:bool;
var acceptor2_hdr.ipv4.version:bv4;
var acceptor2_hdr.ipv4.ihl:bv4;
var acceptor2_hdr.ipv4.diffserv:bv8;
var acceptor2_hdr.ipv4.totalLen:bv16;
var acceptor2_hdr.ipv4.identification:bv16;
var acceptor2_hdr.ipv4.flags:bv3;
var acceptor2_hdr.ipv4.fragOffset:bv13;
var acceptor2_hdr.ipv4.ttl:bv8;
var acceptor2_hdr.ipv4.protocol:bv8;
var acceptor2_hdr.ipv4.hdrChecksum:bv16;
var acceptor2_hdr.ipv4.srcAddr:acceptor2_IPv4Address;
var acceptor2_hdr.ipv4.dstAddr:acceptor2_IPv4Address;

// acceptor2_Header acceptor2_icmp_t
var acceptor2_hdr.icmp:acceptor2_Ref;
var acceptor2_hdr.icmp.valid:bool;
var acceptor2_hdr.icmp.icmpType:bv8;
var acceptor2_hdr.icmp.icmpCode:bv8;
var acceptor2_hdr.icmp.hdrChecksum:bv16;
var acceptor2_hdr.icmp.identifier:bv16;
var acceptor2_hdr.icmp.seqNumber:bv16;
var acceptor2_hdr.icmp.payload:bv256;

// acceptor2_Header acceptor2_udp_t
var acceptor2_hdr.udp:acceptor2_Ref;
var acceptor2_hdr.udp.valid:bool;
var acceptor2_hdr.udp.srcPort:bv16;
var acceptor2_hdr.udp.dstPort:bv16;
var acceptor2_hdr.udp.length_:bv16;
var acceptor2_hdr.udp.checksum:bv16;

// acceptor2_Header acceptor2_paxos_t
var acceptor2_hdr.paxos:acceptor2_Ref;
var acceptor2_hdr.paxos.valid:bool;
var acceptor2_hdr.paxos.msgtype:bv16;
var acceptor2_hdr.paxos.inst:bv32;
var acceptor2_hdr.paxos.rnd:bv16;
var acceptor2_hdr.paxos.vrnd:bv16;
var acceptor2_hdr.paxos.acptid:bv16;
var acceptor2_hdr.paxos.paxoslen:bv32;
var acceptor2_hdr.paxos.paxosval:bv256;

// acceptor2_Struct acceptor2_paxos_metadata_t
type acceptor2_paxos_metadata_t;

// acceptor2_Struct acceptor2_metadata
type acceptor2_metadata;
var acceptor2_meta.paxos_metadata:acceptor2_paxos_metadata_t;
var acceptor2_meta.paxos_metadata.round:bv16;
var acceptor2_meta.paxos_metadata.set_drop:bv1;
var acceptor2_meta.paxos_metadata.ack_count:bv8;
var acceptor2_meta.paxos_metadata.ack_acceptors:bv8;
var acceptor2_meta:acceptor2_metadata;

// acceptor2_Register acceptor2_ingress_registerRound
var acceptor2_ingress_registerRound:[bv32]bv16;
var acceptor2_ingress_registerRound__last_index:bv32;
var acceptor2_ingress_registerRound__last_value:bv16;
var acceptor2_ingress_registerRound__last_old_value:bv16;
var acceptor2_ingress_registerRound__wrote_any:bool;
var acceptor2_ingress_registerRound__wrote_index0:bool;
var acceptor2_ingress_registerRound__last0_old_value:bv16;
var acceptor2_ingress_registerRound__last0_value:bv16;
var acceptor2_ingress_registerRound__next_write_site:int;
var acceptor2_ingress_registerRound__last_write_site:int;
const acceptor2_ingress_registerRound.size:bv32;
axiom acceptor2_ingress_registerRound.size == 65536bv32;

// acceptor2_Register acceptor2_ingress_registerVRound
var acceptor2_ingress_registerVRound:[bv32]bv16;
var acceptor2_ingress_registerVRound__last_index:bv32;
var acceptor2_ingress_registerVRound__last_value:bv16;
var acceptor2_ingress_registerVRound__last_old_value:bv16;
var acceptor2_ingress_registerVRound__wrote_any:bool;
var acceptor2_ingress_registerVRound__wrote_index0:bool;
var acceptor2_ingress_registerVRound__last0_old_value:bv16;
var acceptor2_ingress_registerVRound__last0_value:bv16;
var acceptor2_ingress_registerVRound__next_write_site:int;
var acceptor2_ingress_registerVRound__last_write_site:int;
const acceptor2_ingress_registerVRound.size:bv32;
axiom acceptor2_ingress_registerVRound.size == 65536bv32;

// acceptor2_Table acceptor2_ingress_acceptor_tbl acceptor2_Actionlist acceptor2_Declaration
type acceptor2_ingress_acceptor_tbl.action;
const unique acceptor2_ingress_acceptor_tbl.action.ingress_handle_1a : acceptor2_ingress_acceptor_tbl.action;
const unique acceptor2_ingress_acceptor_tbl.action.ingress_handle_2a : acceptor2_ingress_acceptor_tbl.action;
const unique acceptor2_ingress_acceptor_tbl.action.ingress_drop : acceptor2_ingress_acceptor_tbl.action;
var acceptor2_ingress_acceptor_tbl.action_run : acceptor2_ingress_acceptor_tbl.action;
var acceptor2_ingress_acceptor_tbl.hit : bool;




// acceptor2_Parser acceptor2_TopParser
procedure {:inline 1} acceptor2_TopParser()
	modifies acceptor2_drop, acceptor2_isValid;
{
    goto acceptor2_State$TopParser$start;

        acceptor2_State$TopParser$start:
    call acceptor2_packet_in.extract(acceptor2_hdr.ethernet);
    goto acceptor2_State$TopParser$start$parse_arp_2, acceptor2_State$TopParser$start$parse_ipv4_1, acceptor2_State$TopParser$start$DEFAULT;
    
acceptor2_State$TopParser$start$parse_arp_2:
    assume (acceptor2_hdr.ethernet.etherType == 2054bv16);
    goto acceptor2_State$TopParser$parse_arp;
    
acceptor2_State$TopParser$start$parse_ipv4_1:
    assume (acceptor2_hdr.ethernet.etherType == 2048bv16);
    goto acceptor2_State$TopParser$parse_ipv4;

    acceptor2_State$TopParser$start$DEFAULT:
    assume(!(acceptor2_hdr.ethernet.etherType == 2054bv16)&&!(acceptor2_hdr.ethernet.etherType == 2048bv16));
goto acceptor2_State$reject;

        acceptor2_State$TopParser$parse_arp:
    call acceptor2_packet_in.extract(acceptor2_hdr.arp);
    goto acceptor2_State$accept;

        acceptor2_State$TopParser$parse_ipv4:
    call acceptor2_packet_in.extract(acceptor2_hdr.ipv4);
    goto acceptor2_State$TopParser$parse_ipv4$parse_icmp_3, acceptor2_State$TopParser$parse_ipv4$parse_udp_2, acceptor2_State$TopParser$parse_ipv4$DEFAULT;
    
acceptor2_State$TopParser$parse_ipv4$parse_icmp_3:
    assume (acceptor2_hdr.ipv4.protocol == 1bv8);
    goto acceptor2_State$TopParser$parse_icmp;
    
acceptor2_State$TopParser$parse_ipv4$parse_udp_2:
    assume (acceptor2_hdr.ipv4.protocol == 17bv8);
    goto acceptor2_State$TopParser$parse_udp;

    acceptor2_State$TopParser$parse_ipv4$DEFAULT:
    assume(!(acceptor2_hdr.ipv4.protocol == 1bv8)&&!(acceptor2_hdr.ipv4.protocol == 17bv8));
    goto acceptor2_State$accept;

        acceptor2_State$TopParser$parse_icmp:
    call acceptor2_packet_in.extract(acceptor2_hdr.icmp);
    goto acceptor2_State$accept;

        acceptor2_State$TopParser$parse_udp:
    call acceptor2_packet_in.extract(acceptor2_hdr.udp);
    goto acceptor2_State$TopParser$parse_udp$parse_paxos_2, acceptor2_State$TopParser$parse_udp$DEFAULT;
    
acceptor2_State$TopParser$parse_udp$parse_paxos_2:
    assume (acceptor2_hdr.udp.dstPort == 34952bv16);
    goto acceptor2_State$TopParser$parse_paxos;

    acceptor2_State$TopParser$parse_udp$DEFAULT:
    assume(!(acceptor2_hdr.udp.dstPort == 34952bv16));
    goto acceptor2_State$accept;

        acceptor2_State$TopParser$parse_paxos:
    call acceptor2_packet_in.extract(acceptor2_hdr.paxos);
    goto acceptor2_State$accept;

    acceptor2_State$accept:
    call acceptor2_accept();
    goto acceptor2_Exit;

    acceptor2_State$reject:
    call acceptor2_reject();
    goto acceptor2_Exit;

    acceptor2_Exit:
}
procedure {:inline 1} acceptor2_accept()
{
}

// acceptor2_Control acceptor2_computeChecksum
procedure {:inline 1} acceptor2_computeChecksum()
{
}

// acceptor2_Control acceptor2_egress
procedure {:inline 1} acceptor2_egress()
{
}

// acceptor2_Control acceptor2_ingress
procedure {:inline 1} acceptor2_ingress()
	modifies acceptor2_hdr.paxos.msgtype, acceptor2_hdr.paxos.vrnd, acceptor2_ingress_acceptor_tbl.action_run, acceptor2_ingress_acceptor_tbl.hit, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_index0, acceptor2_meta.paxos_metadata.round;
{
    if(acceptor2_isValid[acceptor2_hdr.arp]){
    }
    else{
        if(acceptor2_isValid[acceptor2_hdr.ipv4]){
            if(acceptor2_isValid[acceptor2_hdr.paxos]){
                call acceptor2_ingress_read_round();
                if(buge.bv16(acceptor2_hdr.paxos.rnd, acceptor2_meta.paxos_metadata.round)){
                    // acceptor2_read
                    acceptor2_hdr.paxos.vrnd := acceptor2_ingress_registerVRound.read(acceptor2_ingress_registerVRound, acceptor2_hdr.paxos.inst);
                    call acceptor2_ingress_acceptor_tbl.apply();
                }
            }
            else{
            }
        }
    }
}

// acceptor2_Table acceptor2_ingress_acceptor_tbl
procedure {:inline 1} acceptor2_ingress_acceptor_tbl.apply()
	modifies acceptor2_hdr.paxos.msgtype, acceptor2_ingress_acceptor_tbl.action_run, acceptor2_ingress_acceptor_tbl.hit, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_index0;
{
    acceptor2_hdr.paxos.msgtype := acceptor2_hdr.paxos.msgtype;
    acceptor2_ingress_acceptor_tbl.hit := false;
    goto acceptor2_action_ingress_handle_1a, acceptor2_action_ingress_handle_2a, acceptor2_action_ingress_drop;

    acceptor2_action_ingress_handle_1a:
    assume acceptor2_ingress_acceptor_tbl.action_run == acceptor2_ingress_acceptor_tbl.action.ingress_handle_1a;
    call acceptor2_ingress_handle_1a();
    goto acceptor2_Exit;

    acceptor2_action_ingress_handle_2a:
    assume acceptor2_ingress_acceptor_tbl.action_run == acceptor2_ingress_acceptor_tbl.action.ingress_handle_2a;
    call acceptor2_ingress_handle_2a();
    goto acceptor2_Exit;

    acceptor2_action_ingress_drop:
    assume acceptor2_ingress_acceptor_tbl.action_run == acceptor2_ingress_acceptor_tbl.action.ingress_drop;
    call acceptor2_ingress_drop();
    goto acceptor2_Exit;

    acceptor2_Exit:
}

// acceptor2_Action acceptor2_ingress_drop
procedure {:inline 1} acceptor2_ingress_drop()
{
}

// acceptor2_Action acceptor2_ingress_handle_1a
procedure {:inline 1} acceptor2_ingress_handle_1a()
	modifies acceptor2_hdr.paxos.msgtype, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_index0;
{
    acceptor2_hdr.paxos.msgtype := 1bv16;
    // acceptor2_write
    acceptor2_ingress_registerRound__next_write_site := 1;
    call acceptor2_ingress_registerRound.write(acceptor2_hdr.paxos.inst, acceptor2_hdr.paxos.rnd);
}

// acceptor2_Action acceptor2_ingress_handle_2a
procedure {:inline 1} acceptor2_ingress_handle_2a()
	modifies acceptor2_hdr.paxos.msgtype, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_index0;
{
    acceptor2_hdr.paxos.msgtype := 3bv16;
    // acceptor2_write
    acceptor2_ingress_registerRound__next_write_site := 2;
    call acceptor2_ingress_registerRound.write(acceptor2_hdr.paxos.inst, acceptor2_hdr.paxos.rnd);
}

// acceptor2_Action acceptor2_ingress_read_round
procedure {:inline 1} acceptor2_ingress_read_round()
	modifies acceptor2_meta.paxos_metadata.round;
{
    // acceptor2_read
    acceptor2_meta.paxos_metadata.round := acceptor2_ingress_registerRound.read(acceptor2_ingress_registerRound, acceptor2_hdr.paxos.inst);
}
function {:inline true}acceptor2_ingress_registerRound.read(acceptor2_reg:[bv32]bv16, acceptor2_index:bv32)returns (bv16) {acceptor2_reg[acceptor2_index]}
procedure {:inline 1} acceptor2_ingress_registerRound.write(acceptor2_index:bv32, acceptor2_value:bv16)
	modifies acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_index0;
{
    acceptor2_ingress_registerRound__last_old_value := acceptor2_ingress_registerRound[acceptor2_index];
    acceptor2_ingress_registerRound[acceptor2_index] := acceptor2_value;
    acceptor2_ingress_registerRound__last_index := acceptor2_index;
    acceptor2_ingress_registerRound__last_value := acceptor2_value;
    acceptor2_ingress_registerRound__last_write_site := acceptor2_ingress_registerRound__next_write_site;
    acceptor2_ingress_registerRound__wrote_any := true;
    if (acceptor2_index == 0bv32) {
        acceptor2_ingress_registerRound__wrote_index0 := true;
        acceptor2_ingress_registerRound__last0_old_value := acceptor2_ingress_registerRound__last_old_value;
        acceptor2_ingress_registerRound__last0_value := acceptor2_value;
    }
}
function {:inline true}acceptor2_ingress_registerVRound.read(acceptor2_reg:[bv32]bv16, acceptor2_index:bv32)returns (bv16) {acceptor2_reg[acceptor2_index]}
procedure {:inline 1} acceptor2_ingress_registerVRound.write(acceptor2_index:bv32, acceptor2_value:bv16)
	modifies acceptor2_ingress_registerVRound, acceptor2_ingress_registerVRound__last0_old_value, acceptor2_ingress_registerVRound__last0_value, acceptor2_ingress_registerVRound__last_index, acceptor2_ingress_registerVRound__last_old_value, acceptor2_ingress_registerVRound__last_value, acceptor2_ingress_registerVRound__last_write_site, acceptor2_ingress_registerVRound__wrote_any, acceptor2_ingress_registerVRound__wrote_index0;
{
    acceptor2_ingress_registerVRound__last_old_value := acceptor2_ingress_registerVRound[acceptor2_index];
    acceptor2_ingress_registerVRound[acceptor2_index] := acceptor2_value;
    acceptor2_ingress_registerVRound__last_index := acceptor2_index;
    acceptor2_ingress_registerVRound__last_value := acceptor2_value;
    acceptor2_ingress_registerVRound__last_write_site := acceptor2_ingress_registerVRound__next_write_site;
    acceptor2_ingress_registerVRound__wrote_any := true;
    if (acceptor2_index == 0bv32) {
        acceptor2_ingress_registerVRound__wrote_index0 := true;
        acceptor2_ingress_registerVRound__last0_old_value := acceptor2_ingress_registerVRound__last_old_value;
        acceptor2_ingress_registerVRound__last0_value := acceptor2_value;
    }
}
procedure {:inline 1} acceptor2_main()
	modifies acceptor2_drop, acceptor2_hdr.paxos.msgtype, acceptor2_hdr.paxos.vrnd, acceptor2_ingress_acceptor_tbl.action_run, acceptor2_ingress_acceptor_tbl.hit, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_index0, acceptor2_isValid, acceptor2_meta.paxos_metadata.round;
{
    call acceptor2_TopParser();
    call acceptor2_verifyChecksum();
    call acceptor2_ingress();
    call acceptor2_egress();
    call acceptor2_computeChecksum();
    if(acceptor2_forward == false){
        acceptor2_drop := true;
    }
}
procedure acceptor2_mainProcedure()
	modifies acceptor2_drop, acceptor2_hdr.paxos.msgtype, acceptor2_hdr.paxos.vrnd, acceptor2_ingress_acceptor_tbl.action_run, acceptor2_ingress_acceptor_tbl.hit, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_index0, acceptor2_isValid, acceptor2_meta.paxos_metadata.round, acceptor2_p4b_checksum_error, acceptor2_p4b_checksum_updated, acceptor2_p4b_checksum_verified, acceptor2_p4b_clone_e2e, acceptor2_p4b_clone_i2e, acceptor2_p4b_clone_i2i, acceptor2_p4b_digest, acceptor2_p4b_recirculate;
{
    acceptor2_p4b_checksum_error := false;
    acceptor2_p4b_checksum_updated := false;
    acceptor2_p4b_checksum_verified := false;
    acceptor2_p4b_digest := false;
    acceptor2_p4b_recirculate := false;
    acceptor2_p4b_clone_i2i := false;
    acceptor2_p4b_clone_e2e := false;
    acceptor2_p4b_clone_i2e := false;
    call acceptor2_main();
}
procedure acceptor2_packet_in.extract(acceptor2_header:acceptor2_Ref);
    ensures (acceptor2_isValid[acceptor2_header] == true);
	modifies acceptor2_isValid;
procedure acceptor2_reject();
    ensures acceptor2_drop==true;
	modifies acceptor2_drop;

// acceptor2_Control acceptor2_verifyChecksum
procedure {:inline 1} acceptor2_verifyChecksum()
{
}
// ===== END NODE acceptor2 =====

// ===== BEGIN NODE leader (prefixed) =====
type leader_Ref;
type leader_error=bv1;
type leader_HeaderStack = [int]leader_Ref;
var leader_last:[leader_HeaderStack]leader_Ref;
var leader_forward:bool;
var leader_isValid:[leader_Ref]bool;
var leader_emit:[leader_Ref]bool;
var leader_stack.index:[leader_HeaderStack]int;
var leader_size:[leader_HeaderStack]int;
var leader_drop:bool;
var leader_p4b_clone_i2e:bool;
var leader_p4b_clone_e2e:bool;
var leader_p4b_clone_i2i:bool;
var leader_p4b_recirculate:bool;
var leader_p4b_digest:bool;
var leader_p4b_checksum_verified:bool;
var leader_p4b_checksum_updated:bool;
var leader_p4b_checksum_error:bool;

// leader_Struct leader_standard_metadata_t
type leader_standard_metadata_t;
var leader_standard_metadata.egress_port:bv9;
type leader_CounterType = int;
type leader_MeterType = int;
type leader_HashAlgorithm = int;
type leader_CloneType = int;
type leader_EthernetAddress = bv48;
type leader_IPv4Address = bv32;
type leader_PortId = bv4;
type leader_ethernet_t;
type leader_arp_t;
type leader_ipv4_t;
type leader_icmp_t;
type leader_udp_t;
type leader_paxos_t;

// leader_Struct leader_headers
var leader_hdr:leader_Ref;

// leader_Header leader_ethernet_t
var leader_hdr.ethernet:leader_Ref;
var leader_hdr.ethernet.valid:bool;
var leader_hdr.ethernet.dstAddr:leader_EthernetAddress;
var leader_hdr.ethernet.srcAddr:leader_EthernetAddress;
var leader_hdr.ethernet.etherType:bv16;

// leader_Header leader_arp_t
var leader_hdr.arp:leader_Ref;
var leader_hdr.arp.valid:bool;
var leader_hdr.arp.hrd:bv16;
var leader_hdr.arp.pro:bv16;
var leader_hdr.arp.hln:bv8;
var leader_hdr.arp.pln:bv8;
var leader_hdr.arp.op:bv16;
var leader_hdr.arp.sha:bv48;
var leader_hdr.arp.spa:bv32;
var leader_hdr.arp.tha:bv48;
var leader_hdr.arp.tpa:bv32;

// leader_Header leader_ipv4_t
var leader_hdr.ipv4:leader_Ref;
var leader_hdr.ipv4.valid:bool;
var leader_hdr.ipv4.version:bv4;
var leader_hdr.ipv4.ihl:bv4;
var leader_hdr.ipv4.diffserv:bv8;
var leader_hdr.ipv4.totalLen:bv16;
var leader_hdr.ipv4.identification:bv16;
var leader_hdr.ipv4.flags:bv3;
var leader_hdr.ipv4.fragOffset:bv13;
var leader_hdr.ipv4.ttl:bv8;
var leader_hdr.ipv4.protocol:bv8;
var leader_hdr.ipv4.hdrChecksum:bv16;
var leader_hdr.ipv4.srcAddr:leader_IPv4Address;
var leader_hdr.ipv4.dstAddr:leader_IPv4Address;

// leader_Header leader_icmp_t
var leader_hdr.icmp:leader_Ref;
var leader_hdr.icmp.valid:bool;
var leader_hdr.icmp.icmpType:bv8;
var leader_hdr.icmp.icmpCode:bv8;
var leader_hdr.icmp.hdrChecksum:bv16;
var leader_hdr.icmp.identifier:bv16;
var leader_hdr.icmp.seqNumber:bv16;
var leader_hdr.icmp.payload:bv256;

// leader_Header leader_udp_t
var leader_hdr.udp:leader_Ref;
var leader_hdr.udp.valid:bool;
var leader_hdr.udp.srcPort:bv16;
var leader_hdr.udp.dstPort:bv16;
var leader_hdr.udp.length_:bv16;
var leader_hdr.udp.checksum:bv16;

// leader_Header leader_paxos_t
var leader_hdr.paxos:leader_Ref;
var leader_hdr.paxos.valid:bool;
var leader_hdr.paxos.msgtype:bv16;
var leader_hdr.paxos.inst:bv32;
var leader_hdr.paxos.rnd:bv16;
var leader_hdr.paxos.vrnd:bv16;
var leader_hdr.paxos.acptid:bv16;
var leader_hdr.paxos.paxoslen:bv32;
var leader_hdr.paxos.paxosval:bv256;

// leader_Struct leader_paxos_metadata_t
type leader_paxos_metadata_t;

// leader_Struct leader_metadata
type leader_metadata;



// leader_Parser leader_TopParser
procedure {:inline 1} leader_TopParser()
	modifies leader_drop, leader_isValid;
{
    goto leader_State$TopParser$start;

        leader_State$TopParser$start:
    call leader_packet_in.extract(leader_hdr.ethernet);
    goto leader_State$TopParser$start$parse_arp_2, leader_State$TopParser$start$parse_ipv4_1, leader_State$TopParser$start$DEFAULT;
    
leader_State$TopParser$start$parse_arp_2:
    assume (leader_hdr.ethernet.etherType == 2054bv16);
    goto leader_State$TopParser$parse_arp;
    
leader_State$TopParser$start$parse_ipv4_1:
    assume (leader_hdr.ethernet.etherType == 2048bv16);
    goto leader_State$TopParser$parse_ipv4;

    leader_State$TopParser$start$DEFAULT:
    assume(!(leader_hdr.ethernet.etherType == 2054bv16)&&!(leader_hdr.ethernet.etherType == 2048bv16));
goto leader_State$reject;

        leader_State$TopParser$parse_arp:
    call leader_packet_in.extract(leader_hdr.arp);
    goto leader_State$accept;

        leader_State$TopParser$parse_ipv4:
    call leader_packet_in.extract(leader_hdr.ipv4);
    goto leader_State$TopParser$parse_ipv4$parse_icmp_3, leader_State$TopParser$parse_ipv4$parse_udp_2, leader_State$TopParser$parse_ipv4$DEFAULT;
    
leader_State$TopParser$parse_ipv4$parse_icmp_3:
    assume (leader_hdr.ipv4.protocol == 1bv8);
    goto leader_State$TopParser$parse_icmp;
    
leader_State$TopParser$parse_ipv4$parse_udp_2:
    assume (leader_hdr.ipv4.protocol == 17bv8);
    goto leader_State$TopParser$parse_udp;

    leader_State$TopParser$parse_ipv4$DEFAULT:
    assume(!(leader_hdr.ipv4.protocol == 1bv8)&&!(leader_hdr.ipv4.protocol == 17bv8));
    goto leader_State$accept;

        leader_State$TopParser$parse_icmp:
    call leader_packet_in.extract(leader_hdr.icmp);
    goto leader_State$accept;

        leader_State$TopParser$parse_udp:
    call leader_packet_in.extract(leader_hdr.udp);
    goto leader_State$TopParser$parse_udp$parse_paxos_2, leader_State$TopParser$parse_udp$DEFAULT;
    
leader_State$TopParser$parse_udp$parse_paxos_2:
    assume (leader_hdr.udp.dstPort == 34952bv16);
    goto leader_State$TopParser$parse_paxos;

    leader_State$TopParser$parse_udp$DEFAULT:
    assume(!(leader_hdr.udp.dstPort == 34952bv16));
    goto leader_State$accept;

        leader_State$TopParser$parse_paxos:
    call leader_packet_in.extract(leader_hdr.paxos);
    goto leader_State$accept;

    leader_State$accept:
    call leader_accept();
    goto leader_Exit;

    leader_State$reject:
    call leader_reject();
    goto leader_Exit;

    leader_Exit:
}
procedure {:inline 1} leader_accept()
{
}

// leader_Control leader_computeChecksum
procedure {:inline 1} leader_computeChecksum()
{
}

// leader_Control leader_egress
procedure {:inline 1} leader_egress()
{
}

// leader_Control leader_ingress
procedure {:inline 1} leader_ingress()
{
}
procedure {:inline 1} leader_main()
	modifies leader_drop, leader_isValid;
{
    call leader_TopParser();
    call leader_verifyChecksum();
    call leader_ingress();
    call leader_egress();
    call leader_computeChecksum();
    if(leader_forward == false){
        leader_drop := true;
    }
}
procedure leader_mainProcedure()
	modifies leader_drop, leader_isValid, leader_p4b_checksum_error, leader_p4b_checksum_updated, leader_p4b_checksum_verified, leader_p4b_clone_e2e, leader_p4b_clone_i2e, leader_p4b_clone_i2i, leader_p4b_digest, leader_p4b_recirculate;
{
    leader_p4b_checksum_error := false;
    leader_p4b_checksum_updated := false;
    leader_p4b_checksum_verified := false;
    leader_p4b_digest := false;
    leader_p4b_recirculate := false;
    leader_p4b_clone_i2i := false;
    leader_p4b_clone_e2e := false;
    leader_p4b_clone_i2e := false;
    call leader_main();
}
procedure leader_packet_in.extract(leader_header:leader_Ref);
    ensures (leader_isValid[leader_header] == true);
	modifies leader_isValid;
procedure leader_reject();
    ensures leader_drop==true;
	modifies leader_drop;

// leader_Control leader_verifyChecksum
procedure {:inline 1} leader_verifyChecksum()
{
}
// ===== END NODE leader =====

// ===== BEGIN NODE learner (prefixed) =====
type learner_Ref;
type learner_error=bv1;
type learner_HeaderStack = [int]learner_Ref;
var learner_last:[learner_HeaderStack]learner_Ref;
var learner_forward:bool;
var learner_isValid:[learner_Ref]bool;
var learner_emit:[learner_Ref]bool;
var learner_stack.index:[learner_HeaderStack]int;
var learner_size:[learner_HeaderStack]int;
var learner_drop:bool;
var learner_p4b_clone_i2e:bool;
var learner_p4b_clone_e2e:bool;
var learner_p4b_clone_i2i:bool;
var learner_p4b_recirculate:bool;
var learner_p4b_digest:bool;
var learner_p4b_checksum_verified:bool;
var learner_p4b_checksum_updated:bool;
var learner_p4b_checksum_error:bool;

// learner_Struct learner_standard_metadata_t
type learner_standard_metadata_t;
var learner_standard_metadata.egress_port:bv9;
type learner_CounterType = int;
type learner_MeterType = int;
type learner_HashAlgorithm = int;
type learner_CloneType = int;
type learner_EthernetAddress = bv48;
type learner_IPv4Address = bv32;
type learner_PortId = bv4;
type learner_ethernet_t;
type learner_arp_t;
type learner_ipv4_t;
type learner_icmp_t;
type learner_udp_t;
type learner_paxos_t;

// learner_Struct learner_headers
var learner_hdr:learner_Ref;

// learner_Header learner_ethernet_t
var learner_hdr.ethernet:learner_Ref;
var learner_hdr.ethernet.valid:bool;
var learner_hdr.ethernet.dstAddr:learner_EthernetAddress;
var learner_hdr.ethernet.srcAddr:learner_EthernetAddress;
var learner_hdr.ethernet.etherType:bv16;

// learner_Header learner_arp_t
var learner_hdr.arp:learner_Ref;
var learner_hdr.arp.valid:bool;
var learner_hdr.arp.hrd:bv16;
var learner_hdr.arp.pro:bv16;
var learner_hdr.arp.hln:bv8;
var learner_hdr.arp.pln:bv8;
var learner_hdr.arp.op:bv16;
var learner_hdr.arp.sha:bv48;
var learner_hdr.arp.spa:bv32;
var learner_hdr.arp.tha:bv48;
var learner_hdr.arp.tpa:bv32;

// learner_Header learner_ipv4_t
var learner_hdr.ipv4:learner_Ref;
var learner_hdr.ipv4.valid:bool;
var learner_hdr.ipv4.version:bv4;
var learner_hdr.ipv4.ihl:bv4;
var learner_hdr.ipv4.diffserv:bv8;
var learner_hdr.ipv4.totalLen:bv16;
var learner_hdr.ipv4.identification:bv16;
var learner_hdr.ipv4.flags:bv3;
var learner_hdr.ipv4.fragOffset:bv13;
var learner_hdr.ipv4.ttl:bv8;
var learner_hdr.ipv4.protocol:bv8;
var learner_hdr.ipv4.hdrChecksum:bv16;
var learner_hdr.ipv4.srcAddr:learner_IPv4Address;
var learner_hdr.ipv4.dstAddr:learner_IPv4Address;

// learner_Header learner_icmp_t
var learner_hdr.icmp:learner_Ref;
var learner_hdr.icmp.valid:bool;
var learner_hdr.icmp.icmpType:bv8;
var learner_hdr.icmp.icmpCode:bv8;
var learner_hdr.icmp.hdrChecksum:bv16;
var learner_hdr.icmp.identifier:bv16;
var learner_hdr.icmp.seqNumber:bv16;
var learner_hdr.icmp.payload:bv256;

// learner_Header learner_udp_t
var learner_hdr.udp:learner_Ref;
var learner_hdr.udp.valid:bool;
var learner_hdr.udp.srcPort:bv16;
var learner_hdr.udp.dstPort:bv16;
var learner_hdr.udp.length_:bv16;
var learner_hdr.udp.checksum:bv16;

// learner_Header learner_paxos_t
var learner_hdr.paxos:learner_Ref;
var learner_hdr.paxos.valid:bool;
var learner_hdr.paxos.msgtype:bv16;
var learner_hdr.paxos.inst:bv32;
var learner_hdr.paxos.rnd:bv16;
var learner_hdr.paxos.vrnd:bv16;
var learner_hdr.paxos.acptid:bv16;
var learner_hdr.paxos.paxoslen:bv32;
var learner_hdr.paxos.paxosval:bv256;

// learner_Struct learner_paxos_metadata_t
type learner_paxos_metadata_t;

// learner_Struct learner_metadata
type learner_metadata;



// learner_Parser learner_TopParser
procedure {:inline 1} learner_TopParser()
	modifies learner_drop, learner_isValid;
{
    goto learner_State$TopParser$start;

        learner_State$TopParser$start:
    call learner_packet_in.extract(learner_hdr.ethernet);
    goto learner_State$TopParser$start$parse_arp_2, learner_State$TopParser$start$parse_ipv4_1, learner_State$TopParser$start$DEFAULT;
    
learner_State$TopParser$start$parse_arp_2:
    assume (learner_hdr.ethernet.etherType == 2054bv16);
    goto learner_State$TopParser$parse_arp;
    
learner_State$TopParser$start$parse_ipv4_1:
    assume (learner_hdr.ethernet.etherType == 2048bv16);
    goto learner_State$TopParser$parse_ipv4;

    learner_State$TopParser$start$DEFAULT:
    assume(!(learner_hdr.ethernet.etherType == 2054bv16)&&!(learner_hdr.ethernet.etherType == 2048bv16));
goto learner_State$reject;

        learner_State$TopParser$parse_arp:
    call learner_packet_in.extract(learner_hdr.arp);
    goto learner_State$accept;

        learner_State$TopParser$parse_ipv4:
    call learner_packet_in.extract(learner_hdr.ipv4);
    goto learner_State$TopParser$parse_ipv4$parse_icmp_3, learner_State$TopParser$parse_ipv4$parse_udp_2, learner_State$TopParser$parse_ipv4$DEFAULT;
    
learner_State$TopParser$parse_ipv4$parse_icmp_3:
    assume (learner_hdr.ipv4.protocol == 1bv8);
    goto learner_State$TopParser$parse_icmp;
    
learner_State$TopParser$parse_ipv4$parse_udp_2:
    assume (learner_hdr.ipv4.protocol == 17bv8);
    goto learner_State$TopParser$parse_udp;

    learner_State$TopParser$parse_ipv4$DEFAULT:
    assume(!(learner_hdr.ipv4.protocol == 1bv8)&&!(learner_hdr.ipv4.protocol == 17bv8));
    goto learner_State$accept;

        learner_State$TopParser$parse_icmp:
    call learner_packet_in.extract(learner_hdr.icmp);
    goto learner_State$accept;

        learner_State$TopParser$parse_udp:
    call learner_packet_in.extract(learner_hdr.udp);
    goto learner_State$TopParser$parse_udp$parse_paxos_2, learner_State$TopParser$parse_udp$DEFAULT;
    
learner_State$TopParser$parse_udp$parse_paxos_2:
    assume (learner_hdr.udp.dstPort == 34952bv16);
    goto learner_State$TopParser$parse_paxos;

    learner_State$TopParser$parse_udp$DEFAULT:
    assume(!(learner_hdr.udp.dstPort == 34952bv16));
    goto learner_State$accept;

        learner_State$TopParser$parse_paxos:
    call learner_packet_in.extract(learner_hdr.paxos);
    goto learner_State$accept;

    learner_State$accept:
    call learner_accept();
    goto learner_Exit;

    learner_State$reject:
    call learner_reject();
    goto learner_Exit;

    learner_Exit:
}
procedure {:inline 1} learner_accept()
{
}

// learner_Control learner_computeChecksum
procedure {:inline 1} learner_computeChecksum()
{
}

// learner_Control learner_egress
procedure {:inline 1} learner_egress()
{
}

// learner_Control learner_ingress
procedure {:inline 1} learner_ingress()
{
}
procedure {:inline 1} learner_main()
	modifies learner_drop, learner_isValid;
{
    call learner_TopParser();
    call learner_verifyChecksum();
    call learner_ingress();
    call learner_egress();
    call learner_computeChecksum();
    if(learner_forward == false){
        learner_drop := true;
    }
}
procedure learner_mainProcedure()
	modifies learner_drop, learner_isValid, learner_p4b_checksum_error, learner_p4b_checksum_updated, learner_p4b_checksum_verified, learner_p4b_clone_e2e, learner_p4b_clone_i2e, learner_p4b_clone_i2i, learner_p4b_digest, learner_p4b_recirculate;
{
    learner_p4b_checksum_error := false;
    learner_p4b_checksum_updated := false;
    learner_p4b_checksum_verified := false;
    learner_p4b_digest := false;
    learner_p4b_recirculate := false;
    learner_p4b_clone_i2i := false;
    learner_p4b_clone_e2e := false;
    learner_p4b_clone_i2e := false;
    call learner_main();
}
procedure learner_packet_in.extract(learner_header:learner_Ref);
    ensures (learner_isValid[learner_header] == true);
	modifies learner_isValid;
procedure learner_reject();
    ensures learner_drop==true;
	modifies learner_drop;

// learner_Control learner_verifyChecksum
procedure {:inline 1} learner_verifyChecksum()
{
}
// ===== END NODE learner =====

// ===== BEGIN ENQUEUE PROCEDURES =====
// ===== END ENQUEUE PROCEDURES =====

// ===== BEGIN HARNESS =====
// Auto-generated by Procurator (DSL -> Boogie harness: sequential scheduler)
// Message abstraction: Bag(K=3) using inbox_count per node; single-slot mailbox for packet fields

var procurator_step: int;

// Register debug snapshots (for trace inspection)
var acceptor0_ingress_registerRound__dbg0: bv16;
var acceptor0_ingress_registerRound__last_index__dbg: bv32;
var acceptor0_ingress_registerRound__last_value__dbg: bv16;
var acceptor0_ingress_registerRound__last_old_value__dbg: bv16;
var acceptor0_ingress_registerRound__wrote_any__dbg: bool;
var acceptor0_ingress_registerRound__wrote_index0__dbg: bool;
var acceptor0_ingress_registerRound__last0_old_value__dbg: bv16;
var acceptor0_ingress_registerRound__last0_value__dbg: bv16;
var acceptor0_ingress_registerVRound__dbg0: bv16;
var acceptor0_ingress_registerVRound__last_index__dbg: bv32;
var acceptor0_ingress_registerVRound__last_value__dbg: bv16;
var acceptor0_ingress_registerVRound__last_old_value__dbg: bv16;
var acceptor0_ingress_registerVRound__wrote_any__dbg: bool;
var acceptor0_ingress_registerVRound__wrote_index0__dbg: bool;
var acceptor0_ingress_registerVRound__last0_old_value__dbg: bv16;
var acceptor0_ingress_registerVRound__last0_value__dbg: bv16;
var acceptor1_ingress_registerRound__dbg0: bv16;
var acceptor1_ingress_registerRound__last_index__dbg: bv32;
var acceptor1_ingress_registerRound__last_value__dbg: bv16;
var acceptor1_ingress_registerRound__last_old_value__dbg: bv16;
var acceptor1_ingress_registerRound__wrote_any__dbg: bool;
var acceptor1_ingress_registerRound__wrote_index0__dbg: bool;
var acceptor1_ingress_registerRound__last0_old_value__dbg: bv16;
var acceptor1_ingress_registerRound__last0_value__dbg: bv16;
var acceptor1_ingress_registerVRound__dbg0: bv16;
var acceptor1_ingress_registerVRound__last_index__dbg: bv32;
var acceptor1_ingress_registerVRound__last_value__dbg: bv16;
var acceptor1_ingress_registerVRound__last_old_value__dbg: bv16;
var acceptor1_ingress_registerVRound__wrote_any__dbg: bool;
var acceptor1_ingress_registerVRound__wrote_index0__dbg: bool;
var acceptor1_ingress_registerVRound__last0_old_value__dbg: bv16;
var acceptor1_ingress_registerVRound__last0_value__dbg: bv16;
var acceptor2_ingress_registerRound__dbg0: bv16;
var acceptor2_ingress_registerRound__last_index__dbg: bv32;
var acceptor2_ingress_registerRound__last_value__dbg: bv16;
var acceptor2_ingress_registerRound__last_old_value__dbg: bv16;
var acceptor2_ingress_registerRound__wrote_any__dbg: bool;
var acceptor2_ingress_registerRound__wrote_index0__dbg: bool;
var acceptor2_ingress_registerRound__last0_old_value__dbg: bv16;
var acceptor2_ingress_registerRound__last0_value__dbg: bv16;
var acceptor2_ingress_registerVRound__dbg0: bv16;
var acceptor2_ingress_registerVRound__last_index__dbg: bv32;
var acceptor2_ingress_registerVRound__last_value__dbg: bv16;
var acceptor2_ingress_registerVRound__last_old_value__dbg: bv16;
var acceptor2_ingress_registerVRound__wrote_any__dbg: bool;
var acceptor2_ingress_registerVRound__wrote_index0__dbg: bool;
var acceptor2_ingress_registerVRound__last0_old_value__dbg: bv16;
var acceptor2_ingress_registerVRound__last0_value__dbg: bv16;

var leader_inbox_count: int;
var acceptor0_inbox_count: int;
var acceptor1_inbox_count: int;
var acceptor2_inbox_count: int;
var learner_inbox_count: int;

var leader_pkt_external: bool;
var acceptor0_pkt_external: bool;
var acceptor1_pkt_external: bool;
var acceptor2_pkt_external: bool;
var learner_pkt_external: bool;

// Forwarding (derived from DSL topology)
procedure leader_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (leader_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure acceptor0_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (acceptor0_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure acceptor1_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (acceptor1_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure acceptor2_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (acceptor2_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure learner_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (learner_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure main() returns()
  modifies acceptor0_drop, acceptor0_hdr.ethernet.etherType, acceptor0_hdr.ipv4.protocol, acceptor0_hdr.paxos.inst, acceptor0_hdr.paxos.msgtype, acceptor0_hdr.paxos.rnd, acceptor0_hdr.paxos.vrnd, acceptor0_hdr.udp.dstPort, acceptor0_inbox_count, acceptor0_ingress_acceptor_tbl.action_run, acceptor0_ingress_acceptor_tbl.hit, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__dbg0, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_old_value__dbg, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last0_value__dbg, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_index__dbg, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_old_value__dbg, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_value__dbg, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_any__dbg, acceptor0_ingress_registerRound__wrote_index0, acceptor0_ingress_registerRound__wrote_index0__dbg, acceptor0_ingress_registerVRound__dbg0, acceptor0_ingress_registerVRound__last0_old_value, acceptor0_ingress_registerVRound__last0_old_value__dbg, acceptor0_ingress_registerVRound__last0_value, acceptor0_ingress_registerVRound__last0_value__dbg, acceptor0_ingress_registerVRound__last_index, acceptor0_ingress_registerVRound__last_index__dbg, acceptor0_ingress_registerVRound__last_old_value, acceptor0_ingress_registerVRound__last_old_value__dbg, acceptor0_ingress_registerVRound__last_value, acceptor0_ingress_registerVRound__last_value__dbg, acceptor0_ingress_registerVRound__last_write_site, acceptor0_ingress_registerVRound__next_write_site, acceptor0_ingress_registerVRound__wrote_any, acceptor0_ingress_registerVRound__wrote_any__dbg, acceptor0_ingress_registerVRound__wrote_index0, acceptor0_ingress_registerVRound__wrote_index0__dbg, acceptor0_isValid, acceptor0_meta.paxos_metadata, acceptor0_meta.paxos_metadata.round, acceptor0_p4b_checksum_error, acceptor0_p4b_checksum_updated, acceptor0_p4b_checksum_verified, acceptor0_p4b_clone_e2e, acceptor0_p4b_clone_i2e, acceptor0_p4b_clone_i2i, acceptor0_p4b_digest, acceptor0_p4b_recirculate, acceptor0_pkt_external, acceptor1_drop, acceptor1_hdr.ethernet.etherType, acceptor1_hdr.ipv4.protocol, acceptor1_hdr.paxos.inst, acceptor1_hdr.paxos.msgtype, acceptor1_hdr.paxos.rnd, acceptor1_hdr.paxos.vrnd, acceptor1_hdr.udp.dstPort, acceptor1_inbox_count, acceptor1_ingress_acceptor_tbl.action_run, acceptor1_ingress_acceptor_tbl.hit, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__dbg0, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_old_value__dbg, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last0_value__dbg, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_index__dbg, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_old_value__dbg, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_value__dbg, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_any__dbg, acceptor1_ingress_registerRound__wrote_index0, acceptor1_ingress_registerRound__wrote_index0__dbg, acceptor1_ingress_registerVRound__dbg0, acceptor1_ingress_registerVRound__last0_old_value, acceptor1_ingress_registerVRound__last0_old_value__dbg, acceptor1_ingress_registerVRound__last0_value, acceptor1_ingress_registerVRound__last0_value__dbg, acceptor1_ingress_registerVRound__last_index, acceptor1_ingress_registerVRound__last_index__dbg, acceptor1_ingress_registerVRound__last_old_value, acceptor1_ingress_registerVRound__last_old_value__dbg, acceptor1_ingress_registerVRound__last_value, acceptor1_ingress_registerVRound__last_value__dbg, acceptor1_ingress_registerVRound__last_write_site, acceptor1_ingress_registerVRound__next_write_site, acceptor1_ingress_registerVRound__wrote_any, acceptor1_ingress_registerVRound__wrote_any__dbg, acceptor1_ingress_registerVRound__wrote_index0, acceptor1_ingress_registerVRound__wrote_index0__dbg, acceptor1_isValid, acceptor1_meta.paxos_metadata, acceptor1_meta.paxos_metadata.round, acceptor1_p4b_checksum_error, acceptor1_p4b_checksum_updated, acceptor1_p4b_checksum_verified, acceptor1_p4b_clone_e2e, acceptor1_p4b_clone_i2e, acceptor1_p4b_clone_i2i, acceptor1_p4b_digest, acceptor1_p4b_recirculate, acceptor1_pkt_external, acceptor2_drop, acceptor2_hdr.ethernet.etherType, acceptor2_hdr.ipv4.protocol, acceptor2_hdr.paxos.inst, acceptor2_hdr.paxos.msgtype, acceptor2_hdr.paxos.rnd, acceptor2_hdr.paxos.vrnd, acceptor2_hdr.udp.dstPort, acceptor2_inbox_count, acceptor2_ingress_acceptor_tbl.action_run, acceptor2_ingress_acceptor_tbl.hit, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__dbg0, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_old_value__dbg, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last0_value__dbg, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_index__dbg, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_old_value__dbg, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_value__dbg, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_any__dbg, acceptor2_ingress_registerRound__wrote_index0, acceptor2_ingress_registerRound__wrote_index0__dbg, acceptor2_ingress_registerVRound__dbg0, acceptor2_ingress_registerVRound__last0_old_value, acceptor2_ingress_registerVRound__last0_old_value__dbg, acceptor2_ingress_registerVRound__last0_value, acceptor2_ingress_registerVRound__last0_value__dbg, acceptor2_ingress_registerVRound__last_index, acceptor2_ingress_registerVRound__last_index__dbg, acceptor2_ingress_registerVRound__last_old_value, acceptor2_ingress_registerVRound__last_old_value__dbg, acceptor2_ingress_registerVRound__last_value, acceptor2_ingress_registerVRound__last_value__dbg, acceptor2_ingress_registerVRound__last_write_site, acceptor2_ingress_registerVRound__next_write_site, acceptor2_ingress_registerVRound__wrote_any, acceptor2_ingress_registerVRound__wrote_any__dbg, acceptor2_ingress_registerVRound__wrote_index0, acceptor2_ingress_registerVRound__wrote_index0__dbg, acceptor2_isValid, acceptor2_meta.paxos_metadata, acceptor2_meta.paxos_metadata.round, acceptor2_p4b_checksum_error, acceptor2_p4b_checksum_updated, acceptor2_p4b_checksum_verified, acceptor2_p4b_clone_e2e, acceptor2_p4b_clone_i2e, acceptor2_p4b_clone_i2i, acceptor2_p4b_digest, acceptor2_p4b_recirculate, acceptor2_pkt_external, leader_drop, leader_hdr.ethernet.etherType, leader_hdr.ipv4.protocol, leader_hdr.udp.dstPort, leader_inbox_count, leader_isValid, leader_p4b_checksum_error, leader_p4b_checksum_updated, leader_p4b_checksum_verified, leader_p4b_clone_e2e, leader_p4b_clone_i2e, leader_p4b_clone_i2i, leader_p4b_digest, leader_p4b_recirculate, leader_pkt_external, learner_drop, learner_hdr.ethernet.etherType, learner_hdr.ipv4.protocol, learner_hdr.udp.dstPort, learner_inbox_count, learner_isValid, learner_p4b_checksum_error, learner_p4b_checksum_updated, learner_p4b_checksum_verified, learner_p4b_clone_e2e, learner_p4b_clone_i2e, learner_p4b_clone_i2i, learner_p4b_digest, learner_p4b_recirculate, learner_pkt_external, procurator_step;
{
  // One scheduler step: pick exactly one action.
  if (*) {
    // env inject -> leader
    assume leader_inbox_count < 3;
    leader_pkt_external := true;
    havoc leader_hdr.ethernet.etherType;
    havoc leader_hdr.ipv4.protocol;
    havoc leader_hdr.udp.dstPort;
    leader_inbox_count := leader_inbox_count + 1;
  } else if (*) {
    // env inject -> acceptor0
    assume acceptor0_inbox_count < 3;
    acceptor0_pkt_external := true;
    havoc acceptor0_hdr.ethernet.etherType;
    havoc acceptor0_hdr.ipv4.protocol;
    havoc acceptor0_hdr.udp.dstPort;
    havoc acceptor0_hdr.paxos.msgtype;
    havoc acceptor0_hdr.paxos.inst;
    havoc acceptor0_hdr.paxos.rnd;
    havoc acceptor0_hdr.paxos.vrnd;
    havoc acceptor0_meta.paxos_metadata;
    havoc acceptor0_meta.paxos_metadata.round;
    acceptor0_inbox_count := acceptor0_inbox_count + 1;
  } else if (*) {
    // env inject -> acceptor1
    assume acceptor1_inbox_count < 3;
    acceptor1_pkt_external := true;
    havoc acceptor1_hdr.ethernet.etherType;
    havoc acceptor1_hdr.ipv4.protocol;
    havoc acceptor1_hdr.udp.dstPort;
    havoc acceptor1_hdr.paxos.msgtype;
    havoc acceptor1_hdr.paxos.inst;
    havoc acceptor1_hdr.paxos.rnd;
    havoc acceptor1_hdr.paxos.vrnd;
    havoc acceptor1_meta.paxos_metadata;
    havoc acceptor1_meta.paxos_metadata.round;
    acceptor1_inbox_count := acceptor1_inbox_count + 1;
  } else if (*) {
    // env inject -> acceptor2
    assume acceptor2_inbox_count < 3;
    acceptor2_pkt_external := true;
    havoc acceptor2_hdr.ethernet.etherType;
    havoc acceptor2_hdr.ipv4.protocol;
    havoc acceptor2_hdr.udp.dstPort;
    havoc acceptor2_hdr.paxos.msgtype;
    havoc acceptor2_hdr.paxos.inst;
    havoc acceptor2_hdr.paxos.rnd;
    havoc acceptor2_hdr.paxos.vrnd;
    havoc acceptor2_meta.paxos_metadata;
    havoc acceptor2_meta.paxos_metadata.round;
    acceptor2_inbox_count := acceptor2_inbox_count + 1;
  } else if (*) {
    // node pass -> leader
    assume leader_inbox_count > 0;
    leader_inbox_count := leader_inbox_count - 1;
    call leader_mainProcedure();
    if (leader_p4b_clone_i2e) {
      assume leader_inbox_count < 3;
      leader_pkt_external := false;
      leader_inbox_count := leader_inbox_count + 1;
    }
    leader_p4b_clone_i2e := false;
    if (leader_p4b_clone_e2e) {
      assume leader_inbox_count < 3;
      leader_pkt_external := false;
      leader_inbox_count := leader_inbox_count + 1;
    }
    leader_p4b_clone_e2e := false;
    if (leader_p4b_clone_i2i) {
      assume leader_inbox_count < 3;
      leader_pkt_external := false;
      leader_inbox_count := leader_inbox_count + 1;
    }
    leader_p4b_clone_i2i := false;
    if (leader_p4b_recirculate) {
      assume leader_inbox_count < 3;
      leader_pkt_external := false;
      leader_inbox_count := leader_inbox_count + 1;
    }
    leader_p4b_recirculate := false;
    call leader_Forward();
    // Register debug snapshot
    acceptor0_ingress_registerRound__dbg0 := acceptor0_ingress_registerRound[0bv32];
    acceptor0_ingress_registerRound__last_index__dbg := acceptor0_ingress_registerRound__last_index;
    acceptor0_ingress_registerRound__last_value__dbg := acceptor0_ingress_registerRound__last_value;
    acceptor0_ingress_registerRound__last_old_value__dbg := acceptor0_ingress_registerRound__last_old_value;
    acceptor0_ingress_registerRound__wrote_any__dbg := acceptor0_ingress_registerRound__wrote_any;
    acceptor0_ingress_registerRound__wrote_index0__dbg := acceptor0_ingress_registerRound__wrote_index0;
    acceptor0_ingress_registerRound__last0_old_value__dbg := acceptor0_ingress_registerRound__last0_old_value;
    acceptor0_ingress_registerRound__last0_value__dbg := acceptor0_ingress_registerRound__last0_value;
    acceptor0_ingress_registerVRound__dbg0 := acceptor0_ingress_registerVRound[0bv32];
    acceptor0_ingress_registerVRound__last_index__dbg := acceptor0_ingress_registerVRound__last_index;
    acceptor0_ingress_registerVRound__last_value__dbg := acceptor0_ingress_registerVRound__last_value;
    acceptor0_ingress_registerVRound__last_old_value__dbg := acceptor0_ingress_registerVRound__last_old_value;
    acceptor0_ingress_registerVRound__wrote_any__dbg := acceptor0_ingress_registerVRound__wrote_any;
    acceptor0_ingress_registerVRound__wrote_index0__dbg := acceptor0_ingress_registerVRound__wrote_index0;
    acceptor0_ingress_registerVRound__last0_old_value__dbg := acceptor0_ingress_registerVRound__last0_old_value;
    acceptor0_ingress_registerVRound__last0_value__dbg := acceptor0_ingress_registerVRound__last0_value;
    acceptor1_ingress_registerRound__dbg0 := acceptor1_ingress_registerRound[0bv32];
    acceptor1_ingress_registerRound__last_index__dbg := acceptor1_ingress_registerRound__last_index;
    acceptor1_ingress_registerRound__last_value__dbg := acceptor1_ingress_registerRound__last_value;
    acceptor1_ingress_registerRound__last_old_value__dbg := acceptor1_ingress_registerRound__last_old_value;
    acceptor1_ingress_registerRound__wrote_any__dbg := acceptor1_ingress_registerRound__wrote_any;
    acceptor1_ingress_registerRound__wrote_index0__dbg := acceptor1_ingress_registerRound__wrote_index0;
    acceptor1_ingress_registerRound__last0_old_value__dbg := acceptor1_ingress_registerRound__last0_old_value;
    acceptor1_ingress_registerRound__last0_value__dbg := acceptor1_ingress_registerRound__last0_value;
    acceptor1_ingress_registerVRound__dbg0 := acceptor1_ingress_registerVRound[0bv32];
    acceptor1_ingress_registerVRound__last_index__dbg := acceptor1_ingress_registerVRound__last_index;
    acceptor1_ingress_registerVRound__last_value__dbg := acceptor1_ingress_registerVRound__last_value;
    acceptor1_ingress_registerVRound__last_old_value__dbg := acceptor1_ingress_registerVRound__last_old_value;
    acceptor1_ingress_registerVRound__wrote_any__dbg := acceptor1_ingress_registerVRound__wrote_any;
    acceptor1_ingress_registerVRound__wrote_index0__dbg := acceptor1_ingress_registerVRound__wrote_index0;
    acceptor1_ingress_registerVRound__last0_old_value__dbg := acceptor1_ingress_registerVRound__last0_old_value;
    acceptor1_ingress_registerVRound__last0_value__dbg := acceptor1_ingress_registerVRound__last0_value;
    acceptor2_ingress_registerRound__dbg0 := acceptor2_ingress_registerRound[0bv32];
    acceptor2_ingress_registerRound__last_index__dbg := acceptor2_ingress_registerRound__last_index;
    acceptor2_ingress_registerRound__last_value__dbg := acceptor2_ingress_registerRound__last_value;
    acceptor2_ingress_registerRound__last_old_value__dbg := acceptor2_ingress_registerRound__last_old_value;
    acceptor2_ingress_registerRound__wrote_any__dbg := acceptor2_ingress_registerRound__wrote_any;
    acceptor2_ingress_registerRound__wrote_index0__dbg := acceptor2_ingress_registerRound__wrote_index0;
    acceptor2_ingress_registerRound__last0_old_value__dbg := acceptor2_ingress_registerRound__last0_old_value;
    acceptor2_ingress_registerRound__last0_value__dbg := acceptor2_ingress_registerRound__last0_value;
    acceptor2_ingress_registerVRound__dbg0 := acceptor2_ingress_registerVRound[0bv32];
    acceptor2_ingress_registerVRound__last_index__dbg := acceptor2_ingress_registerVRound__last_index;
    acceptor2_ingress_registerVRound__last_value__dbg := acceptor2_ingress_registerVRound__last_value;
    acceptor2_ingress_registerVRound__last_old_value__dbg := acceptor2_ingress_registerVRound__last_old_value;
    acceptor2_ingress_registerVRound__wrote_any__dbg := acceptor2_ingress_registerVRound__wrote_any;
    acceptor2_ingress_registerVRound__wrote_index0__dbg := acceptor2_ingress_registerVRound__wrote_index0;
    acceptor2_ingress_registerVRound__last0_old_value__dbg := acceptor2_ingress_registerVRound__last0_old_value;
    acceptor2_ingress_registerVRound__last0_value__dbg := acceptor2_ingress_registerVRound__last0_value;
    // Global assertions
    assert (bvule.bv32$builtin(acceptor0_hdr.paxos.inst, 300bv32) && (acceptor0_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor1_hdr.paxos.inst, 300bv32) && (acceptor1_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor2_hdr.paxos.inst, 300bv32) && (acceptor2_hdr.paxos.inst != 300bv32));
  } else if (*) {
    // node pass -> acceptor0
    assume acceptor0_inbox_count > 0;
    acceptor0_inbox_count := acceptor0_inbox_count - 1;
    call acceptor0_mainProcedure();
    if (acceptor0_p4b_clone_i2e) {
      assume acceptor0_inbox_count < 3;
      acceptor0_pkt_external := false;
      acceptor0_inbox_count := acceptor0_inbox_count + 1;
    }
    acceptor0_p4b_clone_i2e := false;
    if (acceptor0_p4b_clone_e2e) {
      assume acceptor0_inbox_count < 3;
      acceptor0_pkt_external := false;
      acceptor0_inbox_count := acceptor0_inbox_count + 1;
    }
    acceptor0_p4b_clone_e2e := false;
    if (acceptor0_p4b_clone_i2i) {
      assume acceptor0_inbox_count < 3;
      acceptor0_pkt_external := false;
      acceptor0_inbox_count := acceptor0_inbox_count + 1;
    }
    acceptor0_p4b_clone_i2i := false;
    if (acceptor0_p4b_recirculate) {
      assume acceptor0_inbox_count < 3;
      acceptor0_pkt_external := false;
      acceptor0_inbox_count := acceptor0_inbox_count + 1;
    }
    acceptor0_p4b_recirculate := false;
    call acceptor0_Forward();
    // Register debug snapshot
    acceptor0_ingress_registerRound__dbg0 := acceptor0_ingress_registerRound[0bv32];
    acceptor0_ingress_registerRound__last_index__dbg := acceptor0_ingress_registerRound__last_index;
    acceptor0_ingress_registerRound__last_value__dbg := acceptor0_ingress_registerRound__last_value;
    acceptor0_ingress_registerRound__last_old_value__dbg := acceptor0_ingress_registerRound__last_old_value;
    acceptor0_ingress_registerRound__wrote_any__dbg := acceptor0_ingress_registerRound__wrote_any;
    acceptor0_ingress_registerRound__wrote_index0__dbg := acceptor0_ingress_registerRound__wrote_index0;
    acceptor0_ingress_registerRound__last0_old_value__dbg := acceptor0_ingress_registerRound__last0_old_value;
    acceptor0_ingress_registerRound__last0_value__dbg := acceptor0_ingress_registerRound__last0_value;
    acceptor0_ingress_registerVRound__dbg0 := acceptor0_ingress_registerVRound[0bv32];
    acceptor0_ingress_registerVRound__last_index__dbg := acceptor0_ingress_registerVRound__last_index;
    acceptor0_ingress_registerVRound__last_value__dbg := acceptor0_ingress_registerVRound__last_value;
    acceptor0_ingress_registerVRound__last_old_value__dbg := acceptor0_ingress_registerVRound__last_old_value;
    acceptor0_ingress_registerVRound__wrote_any__dbg := acceptor0_ingress_registerVRound__wrote_any;
    acceptor0_ingress_registerVRound__wrote_index0__dbg := acceptor0_ingress_registerVRound__wrote_index0;
    acceptor0_ingress_registerVRound__last0_old_value__dbg := acceptor0_ingress_registerVRound__last0_old_value;
    acceptor0_ingress_registerVRound__last0_value__dbg := acceptor0_ingress_registerVRound__last0_value;
    acceptor1_ingress_registerRound__dbg0 := acceptor1_ingress_registerRound[0bv32];
    acceptor1_ingress_registerRound__last_index__dbg := acceptor1_ingress_registerRound__last_index;
    acceptor1_ingress_registerRound__last_value__dbg := acceptor1_ingress_registerRound__last_value;
    acceptor1_ingress_registerRound__last_old_value__dbg := acceptor1_ingress_registerRound__last_old_value;
    acceptor1_ingress_registerRound__wrote_any__dbg := acceptor1_ingress_registerRound__wrote_any;
    acceptor1_ingress_registerRound__wrote_index0__dbg := acceptor1_ingress_registerRound__wrote_index0;
    acceptor1_ingress_registerRound__last0_old_value__dbg := acceptor1_ingress_registerRound__last0_old_value;
    acceptor1_ingress_registerRound__last0_value__dbg := acceptor1_ingress_registerRound__last0_value;
    acceptor1_ingress_registerVRound__dbg0 := acceptor1_ingress_registerVRound[0bv32];
    acceptor1_ingress_registerVRound__last_index__dbg := acceptor1_ingress_registerVRound__last_index;
    acceptor1_ingress_registerVRound__last_value__dbg := acceptor1_ingress_registerVRound__last_value;
    acceptor1_ingress_registerVRound__last_old_value__dbg := acceptor1_ingress_registerVRound__last_old_value;
    acceptor1_ingress_registerVRound__wrote_any__dbg := acceptor1_ingress_registerVRound__wrote_any;
    acceptor1_ingress_registerVRound__wrote_index0__dbg := acceptor1_ingress_registerVRound__wrote_index0;
    acceptor1_ingress_registerVRound__last0_old_value__dbg := acceptor1_ingress_registerVRound__last0_old_value;
    acceptor1_ingress_registerVRound__last0_value__dbg := acceptor1_ingress_registerVRound__last0_value;
    acceptor2_ingress_registerRound__dbg0 := acceptor2_ingress_registerRound[0bv32];
    acceptor2_ingress_registerRound__last_index__dbg := acceptor2_ingress_registerRound__last_index;
    acceptor2_ingress_registerRound__last_value__dbg := acceptor2_ingress_registerRound__last_value;
    acceptor2_ingress_registerRound__last_old_value__dbg := acceptor2_ingress_registerRound__last_old_value;
    acceptor2_ingress_registerRound__wrote_any__dbg := acceptor2_ingress_registerRound__wrote_any;
    acceptor2_ingress_registerRound__wrote_index0__dbg := acceptor2_ingress_registerRound__wrote_index0;
    acceptor2_ingress_registerRound__last0_old_value__dbg := acceptor2_ingress_registerRound__last0_old_value;
    acceptor2_ingress_registerRound__last0_value__dbg := acceptor2_ingress_registerRound__last0_value;
    acceptor2_ingress_registerVRound__dbg0 := acceptor2_ingress_registerVRound[0bv32];
    acceptor2_ingress_registerVRound__last_index__dbg := acceptor2_ingress_registerVRound__last_index;
    acceptor2_ingress_registerVRound__last_value__dbg := acceptor2_ingress_registerVRound__last_value;
    acceptor2_ingress_registerVRound__last_old_value__dbg := acceptor2_ingress_registerVRound__last_old_value;
    acceptor2_ingress_registerVRound__wrote_any__dbg := acceptor2_ingress_registerVRound__wrote_any;
    acceptor2_ingress_registerVRound__wrote_index0__dbg := acceptor2_ingress_registerVRound__wrote_index0;
    acceptor2_ingress_registerVRound__last0_old_value__dbg := acceptor2_ingress_registerVRound__last0_old_value;
    acceptor2_ingress_registerVRound__last0_value__dbg := acceptor2_ingress_registerVRound__last0_value;
    // Global assertions
    assert (bvule.bv32$builtin(acceptor0_hdr.paxos.inst, 300bv32) && (acceptor0_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor1_hdr.paxos.inst, 300bv32) && (acceptor1_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor2_hdr.paxos.inst, 300bv32) && (acceptor2_hdr.paxos.inst != 300bv32));
  } else if (*) {
    // node pass -> acceptor1
    assume acceptor1_inbox_count > 0;
    acceptor1_inbox_count := acceptor1_inbox_count - 1;
    call acceptor1_mainProcedure();
    if (acceptor1_p4b_clone_i2e) {
      assume acceptor1_inbox_count < 3;
      acceptor1_pkt_external := false;
      acceptor1_inbox_count := acceptor1_inbox_count + 1;
    }
    acceptor1_p4b_clone_i2e := false;
    if (acceptor1_p4b_clone_e2e) {
      assume acceptor1_inbox_count < 3;
      acceptor1_pkt_external := false;
      acceptor1_inbox_count := acceptor1_inbox_count + 1;
    }
    acceptor1_p4b_clone_e2e := false;
    if (acceptor1_p4b_clone_i2i) {
      assume acceptor1_inbox_count < 3;
      acceptor1_pkt_external := false;
      acceptor1_inbox_count := acceptor1_inbox_count + 1;
    }
    acceptor1_p4b_clone_i2i := false;
    if (acceptor1_p4b_recirculate) {
      assume acceptor1_inbox_count < 3;
      acceptor1_pkt_external := false;
      acceptor1_inbox_count := acceptor1_inbox_count + 1;
    }
    acceptor1_p4b_recirculate := false;
    call acceptor1_Forward();
    // Register debug snapshot
    acceptor0_ingress_registerRound__dbg0 := acceptor0_ingress_registerRound[0bv32];
    acceptor0_ingress_registerRound__last_index__dbg := acceptor0_ingress_registerRound__last_index;
    acceptor0_ingress_registerRound__last_value__dbg := acceptor0_ingress_registerRound__last_value;
    acceptor0_ingress_registerRound__last_old_value__dbg := acceptor0_ingress_registerRound__last_old_value;
    acceptor0_ingress_registerRound__wrote_any__dbg := acceptor0_ingress_registerRound__wrote_any;
    acceptor0_ingress_registerRound__wrote_index0__dbg := acceptor0_ingress_registerRound__wrote_index0;
    acceptor0_ingress_registerRound__last0_old_value__dbg := acceptor0_ingress_registerRound__last0_old_value;
    acceptor0_ingress_registerRound__last0_value__dbg := acceptor0_ingress_registerRound__last0_value;
    acceptor0_ingress_registerVRound__dbg0 := acceptor0_ingress_registerVRound[0bv32];
    acceptor0_ingress_registerVRound__last_index__dbg := acceptor0_ingress_registerVRound__last_index;
    acceptor0_ingress_registerVRound__last_value__dbg := acceptor0_ingress_registerVRound__last_value;
    acceptor0_ingress_registerVRound__last_old_value__dbg := acceptor0_ingress_registerVRound__last_old_value;
    acceptor0_ingress_registerVRound__wrote_any__dbg := acceptor0_ingress_registerVRound__wrote_any;
    acceptor0_ingress_registerVRound__wrote_index0__dbg := acceptor0_ingress_registerVRound__wrote_index0;
    acceptor0_ingress_registerVRound__last0_old_value__dbg := acceptor0_ingress_registerVRound__last0_old_value;
    acceptor0_ingress_registerVRound__last0_value__dbg := acceptor0_ingress_registerVRound__last0_value;
    acceptor1_ingress_registerRound__dbg0 := acceptor1_ingress_registerRound[0bv32];
    acceptor1_ingress_registerRound__last_index__dbg := acceptor1_ingress_registerRound__last_index;
    acceptor1_ingress_registerRound__last_value__dbg := acceptor1_ingress_registerRound__last_value;
    acceptor1_ingress_registerRound__last_old_value__dbg := acceptor1_ingress_registerRound__last_old_value;
    acceptor1_ingress_registerRound__wrote_any__dbg := acceptor1_ingress_registerRound__wrote_any;
    acceptor1_ingress_registerRound__wrote_index0__dbg := acceptor1_ingress_registerRound__wrote_index0;
    acceptor1_ingress_registerRound__last0_old_value__dbg := acceptor1_ingress_registerRound__last0_old_value;
    acceptor1_ingress_registerRound__last0_value__dbg := acceptor1_ingress_registerRound__last0_value;
    acceptor1_ingress_registerVRound__dbg0 := acceptor1_ingress_registerVRound[0bv32];
    acceptor1_ingress_registerVRound__last_index__dbg := acceptor1_ingress_registerVRound__last_index;
    acceptor1_ingress_registerVRound__last_value__dbg := acceptor1_ingress_registerVRound__last_value;
    acceptor1_ingress_registerVRound__last_old_value__dbg := acceptor1_ingress_registerVRound__last_old_value;
    acceptor1_ingress_registerVRound__wrote_any__dbg := acceptor1_ingress_registerVRound__wrote_any;
    acceptor1_ingress_registerVRound__wrote_index0__dbg := acceptor1_ingress_registerVRound__wrote_index0;
    acceptor1_ingress_registerVRound__last0_old_value__dbg := acceptor1_ingress_registerVRound__last0_old_value;
    acceptor1_ingress_registerVRound__last0_value__dbg := acceptor1_ingress_registerVRound__last0_value;
    acceptor2_ingress_registerRound__dbg0 := acceptor2_ingress_registerRound[0bv32];
    acceptor2_ingress_registerRound__last_index__dbg := acceptor2_ingress_registerRound__last_index;
    acceptor2_ingress_registerRound__last_value__dbg := acceptor2_ingress_registerRound__last_value;
    acceptor2_ingress_registerRound__last_old_value__dbg := acceptor2_ingress_registerRound__last_old_value;
    acceptor2_ingress_registerRound__wrote_any__dbg := acceptor2_ingress_registerRound__wrote_any;
    acceptor2_ingress_registerRound__wrote_index0__dbg := acceptor2_ingress_registerRound__wrote_index0;
    acceptor2_ingress_registerRound__last0_old_value__dbg := acceptor2_ingress_registerRound__last0_old_value;
    acceptor2_ingress_registerRound__last0_value__dbg := acceptor2_ingress_registerRound__last0_value;
    acceptor2_ingress_registerVRound__dbg0 := acceptor2_ingress_registerVRound[0bv32];
    acceptor2_ingress_registerVRound__last_index__dbg := acceptor2_ingress_registerVRound__last_index;
    acceptor2_ingress_registerVRound__last_value__dbg := acceptor2_ingress_registerVRound__last_value;
    acceptor2_ingress_registerVRound__last_old_value__dbg := acceptor2_ingress_registerVRound__last_old_value;
    acceptor2_ingress_registerVRound__wrote_any__dbg := acceptor2_ingress_registerVRound__wrote_any;
    acceptor2_ingress_registerVRound__wrote_index0__dbg := acceptor2_ingress_registerVRound__wrote_index0;
    acceptor2_ingress_registerVRound__last0_old_value__dbg := acceptor2_ingress_registerVRound__last0_old_value;
    acceptor2_ingress_registerVRound__last0_value__dbg := acceptor2_ingress_registerVRound__last0_value;
    // Global assertions
    assert (bvule.bv32$builtin(acceptor0_hdr.paxos.inst, 300bv32) && (acceptor0_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor1_hdr.paxos.inst, 300bv32) && (acceptor1_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor2_hdr.paxos.inst, 300bv32) && (acceptor2_hdr.paxos.inst != 300bv32));
  } else if (*) {
    // node pass -> acceptor2
    assume acceptor2_inbox_count > 0;
    acceptor2_inbox_count := acceptor2_inbox_count - 1;
    call acceptor2_mainProcedure();
    if (acceptor2_p4b_clone_i2e) {
      assume acceptor2_inbox_count < 3;
      acceptor2_pkt_external := false;
      acceptor2_inbox_count := acceptor2_inbox_count + 1;
    }
    acceptor2_p4b_clone_i2e := false;
    if (acceptor2_p4b_clone_e2e) {
      assume acceptor2_inbox_count < 3;
      acceptor2_pkt_external := false;
      acceptor2_inbox_count := acceptor2_inbox_count + 1;
    }
    acceptor2_p4b_clone_e2e := false;
    if (acceptor2_p4b_clone_i2i) {
      assume acceptor2_inbox_count < 3;
      acceptor2_pkt_external := false;
      acceptor2_inbox_count := acceptor2_inbox_count + 1;
    }
    acceptor2_p4b_clone_i2i := false;
    if (acceptor2_p4b_recirculate) {
      assume acceptor2_inbox_count < 3;
      acceptor2_pkt_external := false;
      acceptor2_inbox_count := acceptor2_inbox_count + 1;
    }
    acceptor2_p4b_recirculate := false;
    call acceptor2_Forward();
    // Register debug snapshot
    acceptor0_ingress_registerRound__dbg0 := acceptor0_ingress_registerRound[0bv32];
    acceptor0_ingress_registerRound__last_index__dbg := acceptor0_ingress_registerRound__last_index;
    acceptor0_ingress_registerRound__last_value__dbg := acceptor0_ingress_registerRound__last_value;
    acceptor0_ingress_registerRound__last_old_value__dbg := acceptor0_ingress_registerRound__last_old_value;
    acceptor0_ingress_registerRound__wrote_any__dbg := acceptor0_ingress_registerRound__wrote_any;
    acceptor0_ingress_registerRound__wrote_index0__dbg := acceptor0_ingress_registerRound__wrote_index0;
    acceptor0_ingress_registerRound__last0_old_value__dbg := acceptor0_ingress_registerRound__last0_old_value;
    acceptor0_ingress_registerRound__last0_value__dbg := acceptor0_ingress_registerRound__last0_value;
    acceptor0_ingress_registerVRound__dbg0 := acceptor0_ingress_registerVRound[0bv32];
    acceptor0_ingress_registerVRound__last_index__dbg := acceptor0_ingress_registerVRound__last_index;
    acceptor0_ingress_registerVRound__last_value__dbg := acceptor0_ingress_registerVRound__last_value;
    acceptor0_ingress_registerVRound__last_old_value__dbg := acceptor0_ingress_registerVRound__last_old_value;
    acceptor0_ingress_registerVRound__wrote_any__dbg := acceptor0_ingress_registerVRound__wrote_any;
    acceptor0_ingress_registerVRound__wrote_index0__dbg := acceptor0_ingress_registerVRound__wrote_index0;
    acceptor0_ingress_registerVRound__last0_old_value__dbg := acceptor0_ingress_registerVRound__last0_old_value;
    acceptor0_ingress_registerVRound__last0_value__dbg := acceptor0_ingress_registerVRound__last0_value;
    acceptor1_ingress_registerRound__dbg0 := acceptor1_ingress_registerRound[0bv32];
    acceptor1_ingress_registerRound__last_index__dbg := acceptor1_ingress_registerRound__last_index;
    acceptor1_ingress_registerRound__last_value__dbg := acceptor1_ingress_registerRound__last_value;
    acceptor1_ingress_registerRound__last_old_value__dbg := acceptor1_ingress_registerRound__last_old_value;
    acceptor1_ingress_registerRound__wrote_any__dbg := acceptor1_ingress_registerRound__wrote_any;
    acceptor1_ingress_registerRound__wrote_index0__dbg := acceptor1_ingress_registerRound__wrote_index0;
    acceptor1_ingress_registerRound__last0_old_value__dbg := acceptor1_ingress_registerRound__last0_old_value;
    acceptor1_ingress_registerRound__last0_value__dbg := acceptor1_ingress_registerRound__last0_value;
    acceptor1_ingress_registerVRound__dbg0 := acceptor1_ingress_registerVRound[0bv32];
    acceptor1_ingress_registerVRound__last_index__dbg := acceptor1_ingress_registerVRound__last_index;
    acceptor1_ingress_registerVRound__last_value__dbg := acceptor1_ingress_registerVRound__last_value;
    acceptor1_ingress_registerVRound__last_old_value__dbg := acceptor1_ingress_registerVRound__last_old_value;
    acceptor1_ingress_registerVRound__wrote_any__dbg := acceptor1_ingress_registerVRound__wrote_any;
    acceptor1_ingress_registerVRound__wrote_index0__dbg := acceptor1_ingress_registerVRound__wrote_index0;
    acceptor1_ingress_registerVRound__last0_old_value__dbg := acceptor1_ingress_registerVRound__last0_old_value;
    acceptor1_ingress_registerVRound__last0_value__dbg := acceptor1_ingress_registerVRound__last0_value;
    acceptor2_ingress_registerRound__dbg0 := acceptor2_ingress_registerRound[0bv32];
    acceptor2_ingress_registerRound__last_index__dbg := acceptor2_ingress_registerRound__last_index;
    acceptor2_ingress_registerRound__last_value__dbg := acceptor2_ingress_registerRound__last_value;
    acceptor2_ingress_registerRound__last_old_value__dbg := acceptor2_ingress_registerRound__last_old_value;
    acceptor2_ingress_registerRound__wrote_any__dbg := acceptor2_ingress_registerRound__wrote_any;
    acceptor2_ingress_registerRound__wrote_index0__dbg := acceptor2_ingress_registerRound__wrote_index0;
    acceptor2_ingress_registerRound__last0_old_value__dbg := acceptor2_ingress_registerRound__last0_old_value;
    acceptor2_ingress_registerRound__last0_value__dbg := acceptor2_ingress_registerRound__last0_value;
    acceptor2_ingress_registerVRound__dbg0 := acceptor2_ingress_registerVRound[0bv32];
    acceptor2_ingress_registerVRound__last_index__dbg := acceptor2_ingress_registerVRound__last_index;
    acceptor2_ingress_registerVRound__last_value__dbg := acceptor2_ingress_registerVRound__last_value;
    acceptor2_ingress_registerVRound__last_old_value__dbg := acceptor2_ingress_registerVRound__last_old_value;
    acceptor2_ingress_registerVRound__wrote_any__dbg := acceptor2_ingress_registerVRound__wrote_any;
    acceptor2_ingress_registerVRound__wrote_index0__dbg := acceptor2_ingress_registerVRound__wrote_index0;
    acceptor2_ingress_registerVRound__last0_old_value__dbg := acceptor2_ingress_registerVRound__last0_old_value;
    acceptor2_ingress_registerVRound__last0_value__dbg := acceptor2_ingress_registerVRound__last0_value;
    // Global assertions
    assert (bvule.bv32$builtin(acceptor0_hdr.paxos.inst, 300bv32) && (acceptor0_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor1_hdr.paxos.inst, 300bv32) && (acceptor1_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor2_hdr.paxos.inst, 300bv32) && (acceptor2_hdr.paxos.inst != 300bv32));
  } else if (*) {
    // node pass -> learner
    assume learner_inbox_count > 0;
    learner_inbox_count := learner_inbox_count - 1;
    call learner_mainProcedure();
    if (learner_p4b_clone_i2e) {
      assume learner_inbox_count < 3;
      learner_pkt_external := false;
      learner_inbox_count := learner_inbox_count + 1;
    }
    learner_p4b_clone_i2e := false;
    if (learner_p4b_clone_e2e) {
      assume learner_inbox_count < 3;
      learner_pkt_external := false;
      learner_inbox_count := learner_inbox_count + 1;
    }
    learner_p4b_clone_e2e := false;
    if (learner_p4b_clone_i2i) {
      assume learner_inbox_count < 3;
      learner_pkt_external := false;
      learner_inbox_count := learner_inbox_count + 1;
    }
    learner_p4b_clone_i2i := false;
    if (learner_p4b_recirculate) {
      assume learner_inbox_count < 3;
      learner_pkt_external := false;
      learner_inbox_count := learner_inbox_count + 1;
    }
    learner_p4b_recirculate := false;
    call learner_Forward();
    // Register debug snapshot
    acceptor0_ingress_registerRound__dbg0 := acceptor0_ingress_registerRound[0bv32];
    acceptor0_ingress_registerRound__last_index__dbg := acceptor0_ingress_registerRound__last_index;
    acceptor0_ingress_registerRound__last_value__dbg := acceptor0_ingress_registerRound__last_value;
    acceptor0_ingress_registerRound__last_old_value__dbg := acceptor0_ingress_registerRound__last_old_value;
    acceptor0_ingress_registerRound__wrote_any__dbg := acceptor0_ingress_registerRound__wrote_any;
    acceptor0_ingress_registerRound__wrote_index0__dbg := acceptor0_ingress_registerRound__wrote_index0;
    acceptor0_ingress_registerRound__last0_old_value__dbg := acceptor0_ingress_registerRound__last0_old_value;
    acceptor0_ingress_registerRound__last0_value__dbg := acceptor0_ingress_registerRound__last0_value;
    acceptor0_ingress_registerVRound__dbg0 := acceptor0_ingress_registerVRound[0bv32];
    acceptor0_ingress_registerVRound__last_index__dbg := acceptor0_ingress_registerVRound__last_index;
    acceptor0_ingress_registerVRound__last_value__dbg := acceptor0_ingress_registerVRound__last_value;
    acceptor0_ingress_registerVRound__last_old_value__dbg := acceptor0_ingress_registerVRound__last_old_value;
    acceptor0_ingress_registerVRound__wrote_any__dbg := acceptor0_ingress_registerVRound__wrote_any;
    acceptor0_ingress_registerVRound__wrote_index0__dbg := acceptor0_ingress_registerVRound__wrote_index0;
    acceptor0_ingress_registerVRound__last0_old_value__dbg := acceptor0_ingress_registerVRound__last0_old_value;
    acceptor0_ingress_registerVRound__last0_value__dbg := acceptor0_ingress_registerVRound__last0_value;
    acceptor1_ingress_registerRound__dbg0 := acceptor1_ingress_registerRound[0bv32];
    acceptor1_ingress_registerRound__last_index__dbg := acceptor1_ingress_registerRound__last_index;
    acceptor1_ingress_registerRound__last_value__dbg := acceptor1_ingress_registerRound__last_value;
    acceptor1_ingress_registerRound__last_old_value__dbg := acceptor1_ingress_registerRound__last_old_value;
    acceptor1_ingress_registerRound__wrote_any__dbg := acceptor1_ingress_registerRound__wrote_any;
    acceptor1_ingress_registerRound__wrote_index0__dbg := acceptor1_ingress_registerRound__wrote_index0;
    acceptor1_ingress_registerRound__last0_old_value__dbg := acceptor1_ingress_registerRound__last0_old_value;
    acceptor1_ingress_registerRound__last0_value__dbg := acceptor1_ingress_registerRound__last0_value;
    acceptor1_ingress_registerVRound__dbg0 := acceptor1_ingress_registerVRound[0bv32];
    acceptor1_ingress_registerVRound__last_index__dbg := acceptor1_ingress_registerVRound__last_index;
    acceptor1_ingress_registerVRound__last_value__dbg := acceptor1_ingress_registerVRound__last_value;
    acceptor1_ingress_registerVRound__last_old_value__dbg := acceptor1_ingress_registerVRound__last_old_value;
    acceptor1_ingress_registerVRound__wrote_any__dbg := acceptor1_ingress_registerVRound__wrote_any;
    acceptor1_ingress_registerVRound__wrote_index0__dbg := acceptor1_ingress_registerVRound__wrote_index0;
    acceptor1_ingress_registerVRound__last0_old_value__dbg := acceptor1_ingress_registerVRound__last0_old_value;
    acceptor1_ingress_registerVRound__last0_value__dbg := acceptor1_ingress_registerVRound__last0_value;
    acceptor2_ingress_registerRound__dbg0 := acceptor2_ingress_registerRound[0bv32];
    acceptor2_ingress_registerRound__last_index__dbg := acceptor2_ingress_registerRound__last_index;
    acceptor2_ingress_registerRound__last_value__dbg := acceptor2_ingress_registerRound__last_value;
    acceptor2_ingress_registerRound__last_old_value__dbg := acceptor2_ingress_registerRound__last_old_value;
    acceptor2_ingress_registerRound__wrote_any__dbg := acceptor2_ingress_registerRound__wrote_any;
    acceptor2_ingress_registerRound__wrote_index0__dbg := acceptor2_ingress_registerRound__wrote_index0;
    acceptor2_ingress_registerRound__last0_old_value__dbg := acceptor2_ingress_registerRound__last0_old_value;
    acceptor2_ingress_registerRound__last0_value__dbg := acceptor2_ingress_registerRound__last0_value;
    acceptor2_ingress_registerVRound__dbg0 := acceptor2_ingress_registerVRound[0bv32];
    acceptor2_ingress_registerVRound__last_index__dbg := acceptor2_ingress_registerVRound__last_index;
    acceptor2_ingress_registerVRound__last_value__dbg := acceptor2_ingress_registerVRound__last_value;
    acceptor2_ingress_registerVRound__last_old_value__dbg := acceptor2_ingress_registerVRound__last_old_value;
    acceptor2_ingress_registerVRound__wrote_any__dbg := acceptor2_ingress_registerVRound__wrote_any;
    acceptor2_ingress_registerVRound__wrote_index0__dbg := acceptor2_ingress_registerVRound__wrote_index0;
    acceptor2_ingress_registerVRound__last0_old_value__dbg := acceptor2_ingress_registerVRound__last0_old_value;
    acceptor2_ingress_registerVRound__last0_value__dbg := acceptor2_ingress_registerVRound__last0_value;
    // Global assertions
    assert (bvule.bv32$builtin(acceptor0_hdr.paxos.inst, 300bv32) && (acceptor0_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor1_hdr.paxos.inst, 300bv32) && (acceptor1_hdr.paxos.inst != 300bv32));
    assert (bvule.bv32$builtin(acceptor2_hdr.paxos.inst, 300bv32) && (acceptor2_hdr.paxos.inst != 300bv32));
  } else {
    // idle
  }
}

procedure mainProcedure() returns()
  modifies acceptor0_drop, acceptor0_hdr.ethernet.etherType, acceptor0_hdr.ipv4.protocol, acceptor0_hdr.paxos.inst, acceptor0_hdr.paxos.msgtype, acceptor0_hdr.paxos.rnd, acceptor0_hdr.paxos.vrnd, acceptor0_hdr.udp.dstPort, acceptor0_inbox_count, acceptor0_ingress_acceptor_tbl.action_run, acceptor0_ingress_acceptor_tbl.hit, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__dbg0, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_old_value__dbg, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last0_value__dbg, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_index__dbg, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_old_value__dbg, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_value__dbg, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_any__dbg, acceptor0_ingress_registerRound__wrote_index0, acceptor0_ingress_registerRound__wrote_index0__dbg, acceptor0_ingress_registerVRound__dbg0, acceptor0_ingress_registerVRound__last0_old_value, acceptor0_ingress_registerVRound__last0_old_value__dbg, acceptor0_ingress_registerVRound__last0_value, acceptor0_ingress_registerVRound__last0_value__dbg, acceptor0_ingress_registerVRound__last_index, acceptor0_ingress_registerVRound__last_index__dbg, acceptor0_ingress_registerVRound__last_old_value, acceptor0_ingress_registerVRound__last_old_value__dbg, acceptor0_ingress_registerVRound__last_value, acceptor0_ingress_registerVRound__last_value__dbg, acceptor0_ingress_registerVRound__last_write_site, acceptor0_ingress_registerVRound__next_write_site, acceptor0_ingress_registerVRound__wrote_any, acceptor0_ingress_registerVRound__wrote_any__dbg, acceptor0_ingress_registerVRound__wrote_index0, acceptor0_ingress_registerVRound__wrote_index0__dbg, acceptor0_isValid, acceptor0_meta.paxos_metadata, acceptor0_meta.paxos_metadata.round, acceptor0_p4b_checksum_error, acceptor0_p4b_checksum_updated, acceptor0_p4b_checksum_verified, acceptor0_p4b_clone_e2e, acceptor0_p4b_clone_i2e, acceptor0_p4b_clone_i2i, acceptor0_p4b_digest, acceptor0_p4b_recirculate, acceptor0_pkt_external, acceptor1_drop, acceptor1_hdr.ethernet.etherType, acceptor1_hdr.ipv4.protocol, acceptor1_hdr.paxos.inst, acceptor1_hdr.paxos.msgtype, acceptor1_hdr.paxos.rnd, acceptor1_hdr.paxos.vrnd, acceptor1_hdr.udp.dstPort, acceptor1_inbox_count, acceptor1_ingress_acceptor_tbl.action_run, acceptor1_ingress_acceptor_tbl.hit, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__dbg0, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_old_value__dbg, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last0_value__dbg, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_index__dbg, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_old_value__dbg, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_value__dbg, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_any__dbg, acceptor1_ingress_registerRound__wrote_index0, acceptor1_ingress_registerRound__wrote_index0__dbg, acceptor1_ingress_registerVRound__dbg0, acceptor1_ingress_registerVRound__last0_old_value, acceptor1_ingress_registerVRound__last0_old_value__dbg, acceptor1_ingress_registerVRound__last0_value, acceptor1_ingress_registerVRound__last0_value__dbg, acceptor1_ingress_registerVRound__last_index, acceptor1_ingress_registerVRound__last_index__dbg, acceptor1_ingress_registerVRound__last_old_value, acceptor1_ingress_registerVRound__last_old_value__dbg, acceptor1_ingress_registerVRound__last_value, acceptor1_ingress_registerVRound__last_value__dbg, acceptor1_ingress_registerVRound__last_write_site, acceptor1_ingress_registerVRound__next_write_site, acceptor1_ingress_registerVRound__wrote_any, acceptor1_ingress_registerVRound__wrote_any__dbg, acceptor1_ingress_registerVRound__wrote_index0, acceptor1_ingress_registerVRound__wrote_index0__dbg, acceptor1_isValid, acceptor1_meta.paxos_metadata, acceptor1_meta.paxos_metadata.round, acceptor1_p4b_checksum_error, acceptor1_p4b_checksum_updated, acceptor1_p4b_checksum_verified, acceptor1_p4b_clone_e2e, acceptor1_p4b_clone_i2e, acceptor1_p4b_clone_i2i, acceptor1_p4b_digest, acceptor1_p4b_recirculate, acceptor1_pkt_external, acceptor2_drop, acceptor2_hdr.ethernet.etherType, acceptor2_hdr.ipv4.protocol, acceptor2_hdr.paxos.inst, acceptor2_hdr.paxos.msgtype, acceptor2_hdr.paxos.rnd, acceptor2_hdr.paxos.vrnd, acceptor2_hdr.udp.dstPort, acceptor2_inbox_count, acceptor2_ingress_acceptor_tbl.action_run, acceptor2_ingress_acceptor_tbl.hit, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__dbg0, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_old_value__dbg, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last0_value__dbg, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_index__dbg, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_old_value__dbg, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_value__dbg, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_any__dbg, acceptor2_ingress_registerRound__wrote_index0, acceptor2_ingress_registerRound__wrote_index0__dbg, acceptor2_ingress_registerVRound__dbg0, acceptor2_ingress_registerVRound__last0_old_value, acceptor2_ingress_registerVRound__last0_old_value__dbg, acceptor2_ingress_registerVRound__last0_value, acceptor2_ingress_registerVRound__last0_value__dbg, acceptor2_ingress_registerVRound__last_index, acceptor2_ingress_registerVRound__last_index__dbg, acceptor2_ingress_registerVRound__last_old_value, acceptor2_ingress_registerVRound__last_old_value__dbg, acceptor2_ingress_registerVRound__last_value, acceptor2_ingress_registerVRound__last_value__dbg, acceptor2_ingress_registerVRound__last_write_site, acceptor2_ingress_registerVRound__next_write_site, acceptor2_ingress_registerVRound__wrote_any, acceptor2_ingress_registerVRound__wrote_any__dbg, acceptor2_ingress_registerVRound__wrote_index0, acceptor2_ingress_registerVRound__wrote_index0__dbg, acceptor2_isValid, acceptor2_meta.paxos_metadata, acceptor2_meta.paxos_metadata.round, acceptor2_p4b_checksum_error, acceptor2_p4b_checksum_updated, acceptor2_p4b_checksum_verified, acceptor2_p4b_clone_e2e, acceptor2_p4b_clone_i2e, acceptor2_p4b_clone_i2i, acceptor2_p4b_digest, acceptor2_p4b_recirculate, acceptor2_pkt_external, leader_drop, leader_hdr.ethernet.etherType, leader_hdr.ipv4.protocol, leader_hdr.udp.dstPort, leader_inbox_count, leader_isValid, leader_p4b_checksum_error, leader_p4b_checksum_updated, leader_p4b_checksum_verified, leader_p4b_clone_e2e, leader_p4b_clone_i2e, leader_p4b_clone_i2i, leader_p4b_digest, leader_p4b_recirculate, leader_pkt_external, learner_drop, learner_hdr.ethernet.etherType, learner_hdr.ipv4.protocol, learner_hdr.udp.dstPort, learner_inbox_count, learner_isValid, learner_p4b_checksum_error, learner_p4b_checksum_updated, learner_p4b_checksum_verified, learner_p4b_clone_e2e, learner_p4b_clone_i2e, learner_p4b_clone_i2i, learner_p4b_digest, learner_p4b_recirculate, learner_pkt_external, procurator_step;
{
  // initialize inboxes
  leader_inbox_count := 0;
  leader_pkt_external := false;
  acceptor0_inbox_count := 0;
  acceptor0_pkt_external := false;
  acceptor1_inbox_count := 0;
  acceptor1_pkt_external := false;
  acceptor2_inbox_count := 0;
  acceptor2_pkt_external := false;
  learner_inbox_count := 0;
  learner_pkt_external := false;
  // initialize P4B event flags (clone/recirculate)
  leader_p4b_clone_i2e := false;
  leader_p4b_clone_e2e := false;
  leader_p4b_clone_i2i := false;
  leader_p4b_recirculate := false;
  acceptor0_p4b_clone_i2e := false;
  acceptor0_p4b_clone_e2e := false;
  acceptor0_p4b_clone_i2i := false;
  acceptor0_p4b_recirculate := false;
  acceptor1_p4b_clone_i2e := false;
  acceptor1_p4b_clone_e2e := false;
  acceptor1_p4b_clone_i2i := false;
  acceptor1_p4b_recirculate := false;
  acceptor2_p4b_clone_i2e := false;
  acceptor2_p4b_clone_e2e := false;
  acceptor2_p4b_clone_i2i := false;
  acceptor2_p4b_recirculate := false;
  learner_p4b_clone_i2e := false;
  learner_p4b_clone_e2e := false;
  learner_p4b_clone_i2i := false;
  learner_p4b_recirculate := false;

  // initialize P4 registers (default 0)
  assume (forall i:bv32 :: acceptor0_ingress_registerRound[i] == 0bv16);
  assume acceptor0_ingress_registerRound[0bv32] == 0bv16;
  assume (forall i:bv32 :: acceptor0_ingress_registerVRound[i] == 0bv16);
  assume acceptor0_ingress_registerVRound[0bv32] == 0bv16;
  assume (forall i:bv32 :: acceptor1_ingress_registerRound[i] == 0bv16);
  assume acceptor1_ingress_registerRound[0bv32] == 0bv16;
  assume (forall i:bv32 :: acceptor1_ingress_registerVRound[i] == 0bv16);
  assume acceptor1_ingress_registerVRound[0bv32] == 0bv16;
  assume (forall i:bv32 :: acceptor2_ingress_registerRound[i] == 0bv16);
  assume acceptor2_ingress_registerRound[0bv32] == 0bv16;
  assume (forall i:bv32 :: acceptor2_ingress_registerVRound[i] == 0bv16);
  assume acceptor2_ingress_registerVRound[0bv32] == 0bv16;
  // initialize register write tracking (debug)
  acceptor0_ingress_registerRound__last_index := 0bv32;
  acceptor0_ingress_registerRound__last_value := 0bv16;
  acceptor0_ingress_registerRound__last_old_value := 0bv16;
  acceptor0_ingress_registerRound__wrote_any := false;
  acceptor0_ingress_registerRound__wrote_index0 := false;
  acceptor0_ingress_registerRound__next_write_site := 0;
  acceptor0_ingress_registerRound__last_write_site := 0;
  acceptor0_ingress_registerRound__last0_old_value := 0bv16;
  acceptor0_ingress_registerRound__last0_value := 0bv16;
  acceptor0_ingress_registerVRound__last_index := 0bv32;
  acceptor0_ingress_registerVRound__last_value := 0bv16;
  acceptor0_ingress_registerVRound__last_old_value := 0bv16;
  acceptor0_ingress_registerVRound__wrote_any := false;
  acceptor0_ingress_registerVRound__wrote_index0 := false;
  acceptor0_ingress_registerVRound__next_write_site := 0;
  acceptor0_ingress_registerVRound__last_write_site := 0;
  acceptor0_ingress_registerVRound__last0_old_value := 0bv16;
  acceptor0_ingress_registerVRound__last0_value := 0bv16;
  acceptor1_ingress_registerRound__last_index := 0bv32;
  acceptor1_ingress_registerRound__last_value := 0bv16;
  acceptor1_ingress_registerRound__last_old_value := 0bv16;
  acceptor1_ingress_registerRound__wrote_any := false;
  acceptor1_ingress_registerRound__wrote_index0 := false;
  acceptor1_ingress_registerRound__next_write_site := 0;
  acceptor1_ingress_registerRound__last_write_site := 0;
  acceptor1_ingress_registerRound__last0_old_value := 0bv16;
  acceptor1_ingress_registerRound__last0_value := 0bv16;
  acceptor1_ingress_registerVRound__last_index := 0bv32;
  acceptor1_ingress_registerVRound__last_value := 0bv16;
  acceptor1_ingress_registerVRound__last_old_value := 0bv16;
  acceptor1_ingress_registerVRound__wrote_any := false;
  acceptor1_ingress_registerVRound__wrote_index0 := false;
  acceptor1_ingress_registerVRound__next_write_site := 0;
  acceptor1_ingress_registerVRound__last_write_site := 0;
  acceptor1_ingress_registerVRound__last0_old_value := 0bv16;
  acceptor1_ingress_registerVRound__last0_value := 0bv16;
  acceptor2_ingress_registerRound__last_index := 0bv32;
  acceptor2_ingress_registerRound__last_value := 0bv16;
  acceptor2_ingress_registerRound__last_old_value := 0bv16;
  acceptor2_ingress_registerRound__wrote_any := false;
  acceptor2_ingress_registerRound__wrote_index0 := false;
  acceptor2_ingress_registerRound__next_write_site := 0;
  acceptor2_ingress_registerRound__last_write_site := 0;
  acceptor2_ingress_registerRound__last0_old_value := 0bv16;
  acceptor2_ingress_registerRound__last0_value := 0bv16;
  acceptor2_ingress_registerVRound__last_index := 0bv32;
  acceptor2_ingress_registerVRound__last_value := 0bv16;
  acceptor2_ingress_registerVRound__last_old_value := 0bv16;
  acceptor2_ingress_registerVRound__wrote_any := false;
  acceptor2_ingress_registerVRound__wrote_index0 := false;
  acceptor2_ingress_registerVRound__next_write_site := 0;
  acceptor2_ingress_registerVRound__last_write_site := 0;
  acceptor2_ingress_registerVRound__last0_old_value := 0bv16;
  acceptor2_ingress_registerVRound__last0_value := 0bv16;

  procurator_step := 0;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}


procedure ULTIMATE.start() returns()
  modifies acceptor0_drop, acceptor0_hdr.ethernet.etherType, acceptor0_hdr.ipv4.protocol, acceptor0_hdr.paxos.inst, acceptor0_hdr.paxos.msgtype, acceptor0_hdr.paxos.rnd, acceptor0_hdr.paxos.vrnd, acceptor0_hdr.udp.dstPort, acceptor0_inbox_count, acceptor0_ingress_acceptor_tbl.action_run, acceptor0_ingress_acceptor_tbl.hit, acceptor0_ingress_registerRound, acceptor0_ingress_registerRound__dbg0, acceptor0_ingress_registerRound__last0_old_value, acceptor0_ingress_registerRound__last0_old_value__dbg, acceptor0_ingress_registerRound__last0_value, acceptor0_ingress_registerRound__last0_value__dbg, acceptor0_ingress_registerRound__last_index, acceptor0_ingress_registerRound__last_index__dbg, acceptor0_ingress_registerRound__last_old_value, acceptor0_ingress_registerRound__last_old_value__dbg, acceptor0_ingress_registerRound__last_value, acceptor0_ingress_registerRound__last_value__dbg, acceptor0_ingress_registerRound__last_write_site, acceptor0_ingress_registerRound__next_write_site, acceptor0_ingress_registerRound__wrote_any, acceptor0_ingress_registerRound__wrote_any__dbg, acceptor0_ingress_registerRound__wrote_index0, acceptor0_ingress_registerRound__wrote_index0__dbg, acceptor0_ingress_registerVRound__dbg0, acceptor0_ingress_registerVRound__last0_old_value, acceptor0_ingress_registerVRound__last0_old_value__dbg, acceptor0_ingress_registerVRound__last0_value, acceptor0_ingress_registerVRound__last0_value__dbg, acceptor0_ingress_registerVRound__last_index, acceptor0_ingress_registerVRound__last_index__dbg, acceptor0_ingress_registerVRound__last_old_value, acceptor0_ingress_registerVRound__last_old_value__dbg, acceptor0_ingress_registerVRound__last_value, acceptor0_ingress_registerVRound__last_value__dbg, acceptor0_ingress_registerVRound__last_write_site, acceptor0_ingress_registerVRound__next_write_site, acceptor0_ingress_registerVRound__wrote_any, acceptor0_ingress_registerVRound__wrote_any__dbg, acceptor0_ingress_registerVRound__wrote_index0, acceptor0_ingress_registerVRound__wrote_index0__dbg, acceptor0_isValid, acceptor0_meta.paxos_metadata, acceptor0_meta.paxos_metadata.round, acceptor0_p4b_checksum_error, acceptor0_p4b_checksum_updated, acceptor0_p4b_checksum_verified, acceptor0_p4b_clone_e2e, acceptor0_p4b_clone_i2e, acceptor0_p4b_clone_i2i, acceptor0_p4b_digest, acceptor0_p4b_recirculate, acceptor0_pkt_external, acceptor1_drop, acceptor1_hdr.ethernet.etherType, acceptor1_hdr.ipv4.protocol, acceptor1_hdr.paxos.inst, acceptor1_hdr.paxos.msgtype, acceptor1_hdr.paxos.rnd, acceptor1_hdr.paxos.vrnd, acceptor1_hdr.udp.dstPort, acceptor1_inbox_count, acceptor1_ingress_acceptor_tbl.action_run, acceptor1_ingress_acceptor_tbl.hit, acceptor1_ingress_registerRound, acceptor1_ingress_registerRound__dbg0, acceptor1_ingress_registerRound__last0_old_value, acceptor1_ingress_registerRound__last0_old_value__dbg, acceptor1_ingress_registerRound__last0_value, acceptor1_ingress_registerRound__last0_value__dbg, acceptor1_ingress_registerRound__last_index, acceptor1_ingress_registerRound__last_index__dbg, acceptor1_ingress_registerRound__last_old_value, acceptor1_ingress_registerRound__last_old_value__dbg, acceptor1_ingress_registerRound__last_value, acceptor1_ingress_registerRound__last_value__dbg, acceptor1_ingress_registerRound__last_write_site, acceptor1_ingress_registerRound__next_write_site, acceptor1_ingress_registerRound__wrote_any, acceptor1_ingress_registerRound__wrote_any__dbg, acceptor1_ingress_registerRound__wrote_index0, acceptor1_ingress_registerRound__wrote_index0__dbg, acceptor1_ingress_registerVRound__dbg0, acceptor1_ingress_registerVRound__last0_old_value, acceptor1_ingress_registerVRound__last0_old_value__dbg, acceptor1_ingress_registerVRound__last0_value, acceptor1_ingress_registerVRound__last0_value__dbg, acceptor1_ingress_registerVRound__last_index, acceptor1_ingress_registerVRound__last_index__dbg, acceptor1_ingress_registerVRound__last_old_value, acceptor1_ingress_registerVRound__last_old_value__dbg, acceptor1_ingress_registerVRound__last_value, acceptor1_ingress_registerVRound__last_value__dbg, acceptor1_ingress_registerVRound__last_write_site, acceptor1_ingress_registerVRound__next_write_site, acceptor1_ingress_registerVRound__wrote_any, acceptor1_ingress_registerVRound__wrote_any__dbg, acceptor1_ingress_registerVRound__wrote_index0, acceptor1_ingress_registerVRound__wrote_index0__dbg, acceptor1_isValid, acceptor1_meta.paxos_metadata, acceptor1_meta.paxos_metadata.round, acceptor1_p4b_checksum_error, acceptor1_p4b_checksum_updated, acceptor1_p4b_checksum_verified, acceptor1_p4b_clone_e2e, acceptor1_p4b_clone_i2e, acceptor1_p4b_clone_i2i, acceptor1_p4b_digest, acceptor1_p4b_recirculate, acceptor1_pkt_external, acceptor2_drop, acceptor2_hdr.ethernet.etherType, acceptor2_hdr.ipv4.protocol, acceptor2_hdr.paxos.inst, acceptor2_hdr.paxos.msgtype, acceptor2_hdr.paxos.rnd, acceptor2_hdr.paxos.vrnd, acceptor2_hdr.udp.dstPort, acceptor2_inbox_count, acceptor2_ingress_acceptor_tbl.action_run, acceptor2_ingress_acceptor_tbl.hit, acceptor2_ingress_registerRound, acceptor2_ingress_registerRound__dbg0, acceptor2_ingress_registerRound__last0_old_value, acceptor2_ingress_registerRound__last0_old_value__dbg, acceptor2_ingress_registerRound__last0_value, acceptor2_ingress_registerRound__last0_value__dbg, acceptor2_ingress_registerRound__last_index, acceptor2_ingress_registerRound__last_index__dbg, acceptor2_ingress_registerRound__last_old_value, acceptor2_ingress_registerRound__last_old_value__dbg, acceptor2_ingress_registerRound__last_value, acceptor2_ingress_registerRound__last_value__dbg, acceptor2_ingress_registerRound__last_write_site, acceptor2_ingress_registerRound__next_write_site, acceptor2_ingress_registerRound__wrote_any, acceptor2_ingress_registerRound__wrote_any__dbg, acceptor2_ingress_registerRound__wrote_index0, acceptor2_ingress_registerRound__wrote_index0__dbg, acceptor2_ingress_registerVRound__dbg0, acceptor2_ingress_registerVRound__last0_old_value, acceptor2_ingress_registerVRound__last0_old_value__dbg, acceptor2_ingress_registerVRound__last0_value, acceptor2_ingress_registerVRound__last0_value__dbg, acceptor2_ingress_registerVRound__last_index, acceptor2_ingress_registerVRound__last_index__dbg, acceptor2_ingress_registerVRound__last_old_value, acceptor2_ingress_registerVRound__last_old_value__dbg, acceptor2_ingress_registerVRound__last_value, acceptor2_ingress_registerVRound__last_value__dbg, acceptor2_ingress_registerVRound__last_write_site, acceptor2_ingress_registerVRound__next_write_site, acceptor2_ingress_registerVRound__wrote_any, acceptor2_ingress_registerVRound__wrote_any__dbg, acceptor2_ingress_registerVRound__wrote_index0, acceptor2_ingress_registerVRound__wrote_index0__dbg, acceptor2_isValid, acceptor2_meta.paxos_metadata, acceptor2_meta.paxos_metadata.round, acceptor2_p4b_checksum_error, acceptor2_p4b_checksum_updated, acceptor2_p4b_checksum_verified, acceptor2_p4b_clone_e2e, acceptor2_p4b_clone_i2e, acceptor2_p4b_clone_i2i, acceptor2_p4b_digest, acceptor2_p4b_recirculate, acceptor2_pkt_external, leader_drop, leader_hdr.ethernet.etherType, leader_hdr.ipv4.protocol, leader_hdr.udp.dstPort, leader_inbox_count, leader_isValid, leader_p4b_checksum_error, leader_p4b_checksum_updated, leader_p4b_checksum_verified, leader_p4b_clone_e2e, leader_p4b_clone_i2e, leader_p4b_clone_i2i, leader_p4b_digest, leader_p4b_recirculate, leader_pkt_external, learner_drop, learner_hdr.ethernet.etherType, learner_hdr.ipv4.protocol, learner_hdr.udp.dstPort, learner_inbox_count, learner_isValid, learner_p4b_checksum_error, learner_p4b_checksum_updated, learner_p4b_checksum_verified, learner_p4b_clone_e2e, learner_p4b_clone_i2e, learner_p4b_clone_i2i, learner_p4b_digest, learner_p4b_recirculate, learner_pkt_external, procurator_step;
{
  call mainProcedure();
}

// ===== END HARNESS =====
