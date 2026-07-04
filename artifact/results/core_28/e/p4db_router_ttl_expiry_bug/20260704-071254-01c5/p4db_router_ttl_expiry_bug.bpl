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

// sw_Struct sw_standard_metadata_t
type sw_standard_metadata_t;
var sw_standard_metadata.ingress_port:sw_PortId_t;
var sw_standard_metadata.egress_port:sw_PortId_t;
type sw_CounterType = int;
type sw_MeterType = int;
type sw_HashAlgorithm = int;
type sw_CloneType = int;

// sw_Struct sw_odb_metadata_t
type sw_odb_metadata_t;

// sw_Struct sw_p4db_intrinsic_metadata_t
type sw_p4db_intrinsic_metadata_t;

// sw_Struct sw_routing_metadata_t
type sw_routing_metadata_t;
type sw_ethernet_t;
type sw_ipv4_t;

// sw_Struct sw_metadata
type sw_metadata;

// sw_Struct sw_headers
var sw_hdr:sw_Ref;

// sw_Header sw_ethernet_t
var sw_hdr.ethernet:sw_Ref;
var sw_hdr.ethernet.valid:bool;
var sw_hdr.ethernet.dstAddr:bv48;
var sw_hdr.ethernet.srcAddr:bv48;
var sw_hdr.ethernet.etherType:bv16;

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
var sw_hdr.ipv4.protocol:bv8;
var sw_hdr.ipv4.hdrChecksum:bv16;
var sw_hdr.ipv4.srcAddr:bv32;
var sw_hdr.ipv4.dstAddr:bv32;
var sw_standard_metadata:sw_standard_metadata_t;

function {:builtin "bvsub"} sub.bv8(sw_left:bv8, sw_right:bv8) returns(bv8);

// sw_Table sw_ipv4_nhop sw_Actionlist sw_Declaration
type sw_ipv4_nhop.action;
var sw_ipv4_nhop.set_nhop.nhop_ipv4:bv32;

function {:builtin "bvand"} band.bv32(sw_left:bv32, sw_right:bv32) returns(bv32);
const unique sw_ipv4_nhop.action.set_nhop : sw_ipv4_nhop.action;
const unique sw_ipv4_nhop.action._drop : sw_ipv4_nhop.action;
const unique sw_ipv4_nhop.action.NoAction : sw_ipv4_nhop.action;
var sw_ipv4_nhop.action_run : sw_ipv4_nhop.action;
var sw_ipv4_nhop.hit : bool;

function {:builtin "bvugt"} bugt.bv8(sw_left:bv8, sw_right:bv8) returns(bool);

function {:builtin "bvsub"} sub.bv17(sw_left:bv17, sw_right:bv17) returns(bv17);

function {:builtin "bvsub"} sub.bv33(sw_left:bv33, sw_right:bv33) returns(bv33);

// sw_Parser sw_ParserImpl
procedure {:inline 1} sw_ParserImpl()
	modifies sw_drop, sw_isValid;
{
    goto sw_State$ParserImpl$start;

        sw_State$ParserImpl$parse_ethernet:
    call sw_packet_in.extract(sw_hdr.ethernet);
    goto sw_State$ParserImpl$parse_ethernet$parse_ipv4_2, sw_State$ParserImpl$parse_ethernet$DEFAULT;
    
sw_State$ParserImpl$parse_ethernet$parse_ipv4_2:
    assume (sw_hdr.ethernet.etherType == 2048bv16);
    goto sw_State$ParserImpl$parse_ipv4;

    sw_State$ParserImpl$parse_ethernet$DEFAULT:
    assume(!(sw_hdr.ethernet.etherType == 2048bv16));
    goto sw_State$accept;

        sw_State$ParserImpl$parse_ipv4:
    call sw_packet_in.extract(sw_hdr.ipv4);
    goto sw_State$accept;

        sw_State$ParserImpl$start:
    goto sw_State$ParserImpl$parse_ethernet;

    sw_State$accept:
    call sw_accept();
    goto sw_Exit;

    sw_State$reject:
    call sw_reject();
    goto sw_Exit;

    sw_Exit:
}
procedure {:inline 1} sw_accept()
{
}

// sw_Control sw_computeChecksum
procedure {:inline 1} sw_computeChecksum()
{
}

// sw_Control sw_egress
procedure {:inline 1} sw_egress()
{
}

// sw_Control sw_ingress
procedure {:inline 1} sw_ingress()
	modifies sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.ttl, sw_ipv4_nhop.action_run, sw_ipv4_nhop.hit, sw_ipv4_nhop.set_nhop.nhop_ipv4;
{
    if((sw_isValid[sw_hdr.ipv4]) && (bugt.bv8(sw_hdr.ipv4.ttl, 0bv8))){
        call sw_ipv4_nhop.apply();
    }
}

// sw_Table sw_ipv4_nhop
procedure {:inline 1} sw_ipv4_nhop.apply()
	modifies sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.ttl, sw_ipv4_nhop.action_run, sw_ipv4_nhop.hit, sw_ipv4_nhop.set_nhop.nhop_ipv4;
{
    sw_hdr.ipv4.dstAddr := sw_hdr.ipv4.dstAddr;
    sw_ipv4_nhop.hit := false;
    if(band.bv32(sw_hdr.ipv4.dstAddr, 4294967295bv32) == 167772161bv32){
        sw_ipv4_nhop.hit := true;
        sw_ipv4_nhop.action_run := sw_ipv4_nhop.action.set_nhop;
        sw_ipv4_nhop.set_nhop.nhop_ipv4 := 167772161bv32;
        call sw_set_nhop(sw_ipv4_nhop.set_nhop.nhop_ipv4);
        goto sw_Exit;
    }
    else if(band.bv32(sw_hdr.ipv4.dstAddr, 4294967295bv32) == 167772162bv32){
        sw_ipv4_nhop.hit := true;
        sw_ipv4_nhop.action_run := sw_ipv4_nhop.action.set_nhop;
        sw_ipv4_nhop.set_nhop.nhop_ipv4 := 167772162bv32;
        call sw_set_nhop(sw_ipv4_nhop.set_nhop.nhop_ipv4);
        goto sw_Exit;
    }

    sw_Exit:
}
procedure {:inline 1} sw_main()
	modifies sw_drop, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.ttl, sw_ipv4_nhop.action_run, sw_ipv4_nhop.hit, sw_ipv4_nhop.set_nhop.nhop_ipv4, sw_isValid, sw_p4b_checksum_error, sw_p4b_checksum_verified;
{
    call sw_ParserImpl();
    call sw_verifyChecksum();
    call sw_ingress();
    call sw_egress();
    call sw_computeChecksum();
    if(sw_forward == false){
        sw_drop := true;
    }
}
procedure sw_mainProcedure()
	modifies sw_drop, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.ttl, sw_ipv4_nhop.action_run, sw_ipv4_nhop.hit, sw_ipv4_nhop.set_nhop.nhop_ipv4, sw_isValid, sw_p4b_checksum_error, sw_p4b_checksum_updated, sw_p4b_checksum_verified, sw_p4b_clone_e2e, sw_p4b_clone_i2e, sw_p4b_clone_i2i, sw_p4b_digest, sw_p4b_recirculate;
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
procedure sw_reject();
    ensures sw_drop==true;
	modifies sw_drop;

// sw_Action sw_set_nhop
procedure {:inline 1} sw_set_nhop(sw_nhop_ipv4:bv32)
	modifies sw_hdr.ipv4.ttl;
{
    sw_hdr.ipv4.ttl := sub.bv8(sw_hdr.ipv4.ttl, 1bv8);
}

// sw_Control sw_verifyChecksum
procedure {:inline 1} sw_verifyChecksum()
	modifies sw_p4b_checksum_error, sw_p4b_checksum_verified;
{
    if (true) {
        sw_p4b_checksum_verified := true;
        havoc sw_p4b_checksum_error;
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

var sw_inbox_count: int;
var io_inbox_count: int;

var sw_pkt_external: bool;
var io_pkt_external: bool;

// Host packet fields (mirrors connected node symbols)
var io_standard_metadata.ingress_port: sw_PortId_t;
var io_hdr.ethernet.valid: bool;
var io_hdr.ethernet.etherType: bv16;
var io_hdr.ipv4.valid: bool;
var io_hdr.ipv4.ttl: bv8;
var io_hdr.ipv4.srcAddr: bv32;
var io_hdr.ipv4.dstAddr: bv32;

// Forwarding (derived from DSL topology)
procedure sw_Forward() returns()
{
  // If no forwarding decision was made, do nothing.
  if (sw_standard_metadata.egress_port == 0bv9) {
    return;
  }

  // port-specific forwarding
  // unknown port -> drop
  return;
}

procedure mainProcedure() returns()
  modifies io_hdr.ethernet.etherType, io_hdr.ethernet.valid, io_hdr.ipv4.dstAddr, io_hdr.ipv4.srcAddr, io_hdr.ipv4.ttl, io_hdr.ipv4.valid, io_inbox_count, io_pkt_external, io_standard_metadata.ingress_port, procurator_bad, procurator_step, sw_drop, sw_hdr.ethernet.etherType, sw_hdr.ethernet.valid, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.srcAddr, sw_hdr.ipv4.ttl, sw_hdr.ipv4.valid, sw_inbox_count, sw_ipv4_nhop.action_run, sw_ipv4_nhop.hit, sw_ipv4_nhop.set_nhop.nhop_ipv4, sw_isValid, sw_p4b_checksum_error, sw_p4b_checksum_updated, sw_p4b_checksum_verified, sw_p4b_clone_e2e, sw_p4b_clone_i2e, sw_p4b_clone_i2i, sw_p4b_digest, sw_p4b_recirculate, sw_pkt_external, sw_standard_metadata.ingress_port;
{
  // initialize inboxes
  sw_inbox_count := 0;
  sw_pkt_external := false;
  io_inbox_count := 0;
  io_pkt_external := false;
  // initialize P4B event flags (clone/recirculate)
  sw_p4b_clone_i2e := false;
  sw_p4b_clone_e2e := false;
  sw_p4b_clone_i2i := false;
  sw_p4b_recirculate := false;


  procurator_step := 0;
  procurator_bad := false;
  // step 0: host_send -> io
  // inject packet into connected node (host -> node)
  if (sw_inbox_count < 1) {
    assume sw_inbox_count < 1;
    io_hdr.ethernet.valid := true;
    io_hdr.ipv4.valid := true;
    io_hdr.ethernet.etherType := 2048bv16;
    io_hdr.ipv4.ttl := 1bv8;
    io_hdr.ipv4.dstAddr := 167772161bv32;
    io_hdr.ipv4.srcAddr := 167772162bv32;
    io_standard_metadata.ingress_port := 1bv9;
    sw_standard_metadata.ingress_port := io_standard_metadata.ingress_port;
    sw_hdr.ethernet.valid := io_hdr.ethernet.valid;
    sw_hdr.ethernet.etherType := io_hdr.ethernet.etherType;
    sw_hdr.ipv4.valid := io_hdr.ipv4.valid;
    sw_hdr.ipv4.ttl := io_hdr.ipv4.ttl;
    sw_hdr.ipv4.srcAddr := io_hdr.ipv4.srcAddr;
    sw_hdr.ipv4.dstAddr := io_hdr.ipv4.dstAddr;
    sw_pkt_external := true;
    sw_inbox_count := sw_inbox_count + 1;
  }
  procurator_step := procurator_step + 1;
  // step 1: host_recv -> io
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
  // Global assertions (accumulated into procurator_bad)
  if (!((sw_hdr.ipv4.ttl != 0bv8))) { procurator_bad := true; }
  }
  procurator_step := procurator_step + 1;
  assert !procurator_bad;
}


procedure ULTIMATE.start() returns()
  modifies io_hdr.ethernet.etherType, io_hdr.ethernet.valid, io_hdr.ipv4.dstAddr, io_hdr.ipv4.srcAddr, io_hdr.ipv4.ttl, io_hdr.ipv4.valid, io_inbox_count, io_pkt_external, io_standard_metadata.ingress_port, procurator_bad, procurator_step, sw_drop, sw_hdr.ethernet.etherType, sw_hdr.ethernet.valid, sw_hdr.ipv4.dstAddr, sw_hdr.ipv4.srcAddr, sw_hdr.ipv4.ttl, sw_hdr.ipv4.valid, sw_inbox_count, sw_ipv4_nhop.action_run, sw_ipv4_nhop.hit, sw_ipv4_nhop.set_nhop.nhop_ipv4, sw_isValid, sw_p4b_checksum_error, sw_p4b_checksum_updated, sw_p4b_checksum_verified, sw_p4b_clone_e2e, sw_p4b_clone_i2e, sw_p4b_clone_i2i, sw_p4b_digest, sw_p4b_recirculate, sw_pkt_external, sw_standard_metadata.ingress_port;
{
  call mainProcedure();
}

// ===== END HARNESS =====
