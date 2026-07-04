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
var s1_standard_metadata.egress_port:bv9;
type s1_CounterType = int;
type s1_MeterType = int;
type s1_HashAlgorithm = int;
type s1_CloneType = int;
type s1_mac_addr_t = bv48;
type s1_ipv4_addr_t = bv32;
type s1_data_type_t = bv32;
type s1_ethernet_h;
type s1_ipv4_h;
type s1_udp_h;
type s1_p4ml_h;
type s1_p4ml_agtr_index_h;
type s1_entry_h;

// s1_Struct s1_metadata
type s1_metadata;
var s1_meta.read_reg_appID_and_Seq:bv32;
var s1_meta.read_reg_agtr_time:bv8;
var s1_meta.tmp_reg_agtr_time:bv8;
var s1_meta.isMyAppIDandMyCurrentSeq:bv1;
var s1_meta.bitmap:bv32;
var s1_meta.isAggregate:bv32;
var s1_meta.agtr_time:bv8;
var s1_meta.integrated_bitmap:bv32;
var s1_meta.need_send_out:bv8;

// s1_Struct s1_headers
var s1_hdr:s1_Ref;

// s1_Header s1_ethernet_h
var s1_hdr.ethernet:s1_Ref;
var s1_hdr.ethernet.valid:bool;
var s1_hdr.ethernet.dst_addr:s1_mac_addr_t;
var s1_hdr.ethernet.src_addr:s1_mac_addr_t;
var s1_hdr.ethernet.ether_type:bv16;

// s1_Header s1_ipv4_h
var s1_hdr.ipv4:s1_Ref;
var s1_hdr.ipv4.valid:bool;
var s1_hdr.ipv4.version:bv4;
var s1_hdr.ipv4.ihl:bv4;
var s1_hdr.ipv4.diffserv:bv8;
var s1_hdr.ipv4.total_len:bv16;
var s1_hdr.ipv4.identification:bv16;
var s1_hdr.ipv4.flags:bv3;
var s1_hdr.ipv4.frag_offset:bv13;
var s1_hdr.ipv4.ttl:bv8;
var s1_hdr.ipv4.protocol:bv8;
var s1_hdr.ipv4.hdr_checksum:bv16;
var s1_hdr.ipv4.src_addr:s1_ipv4_addr_t;
var s1_hdr.ipv4.dst_addr:s1_ipv4_addr_t;

// s1_Header s1_udp_h
var s1_hdr.udp:s1_Ref;
var s1_hdr.udp.valid:bool;
var s1_hdr.udp.src_port:bv16;
var s1_hdr.udp.dst_port:bv16;
var s1_hdr.udp.length:bv16;
var s1_hdr.udp.checksum:bv16;

// s1_Header s1_p4ml_h
var s1_hdr.p4ml:s1_Ref;
var s1_hdr.p4ml.valid:bool;
var s1_hdr.p4ml.bitmap:bv32;
var s1_hdr.p4ml.agtr_time:bv8;
var s1_hdr.p4ml.overflow:bv1;
var s1_hdr.p4ml.PSIndex:bv2;
var s1_hdr.p4ml.dataIndex:bv1;
var s1_hdr.p4ml.ECN:bv1;
var s1_hdr.p4ml.isResend:bv1;
var s1_hdr.p4ml.isSWCollision:bv1;
var s1_hdr.p4ml.isACK:bv1;
var s1_hdr.p4ml.appIDandSeqNum:bv32;

// s1_Header s1_p4ml_agtr_index_h
var s1_hdr.p4ml_agtr_index:s1_Ref;
var s1_hdr.p4ml_agtr_index.valid:bool;
var s1_hdr.p4ml_agtr_index.agtr:bv16;

// s1_Header s1_entry_h
var s1_hdr.p4ml_entries:s1_Ref;
var s1_hdr.p4ml_entries.valid:bool;
var s1_hdr.p4ml_entries.data0:s1_data_type_t;
var s1_hdr.p4ml_entries.data1:s1_data_type_t;
var s1_hdr.p4ml_entries.data2:s1_data_type_t;
var s1_hdr.p4ml_entries.data3:s1_data_type_t;
var s1_hdr.p4ml_entries.data4:s1_data_type_t;
var s1_hdr.p4ml_entries.data5:s1_data_type_t;
var s1_hdr.p4ml_entries.data6:s1_data_type_t;
var s1_hdr.p4ml_entries.data7:s1_data_type_t;
var s1_hdr.p4ml_entries.data8:s1_data_type_t;
var s1_hdr.p4ml_entries.data9:s1_data_type_t;
var s1_hdr.p4ml_entries.data10:s1_data_type_t;
var s1_hdr.p4ml_entries.data11:s1_data_type_t;
var s1_hdr.p4ml_entries.data12:s1_data_type_t;
var s1_hdr.p4ml_entries.data13:s1_data_type_t;
var s1_hdr.p4ml_entries.data14:s1_data_type_t;
var s1_hdr.p4ml_entries.data15:s1_data_type_t;
var s1_hdr.p4ml_entries.data16:s1_data_type_t;
var s1_hdr.p4ml_entries.data17:s1_data_type_t;
var s1_hdr.p4ml_entries.data18:s1_data_type_t;
var s1_hdr.p4ml_entries.data19:s1_data_type_t;
var s1_hdr.p4ml_entries.data20:s1_data_type_t;
var s1_hdr.p4ml_entries.data21:s1_data_type_t;
var s1_hdr.p4ml_entries.data22:s1_data_type_t;
var s1_hdr.p4ml_entries.data23:s1_data_type_t;
var s1_hdr.p4ml_entries.data24:s1_data_type_t;
var s1_hdr.p4ml_entries.data25:s1_data_type_t;
var s1_hdr.p4ml_entries.data26:s1_data_type_t;
var s1_hdr.p4ml_entries.data27:s1_data_type_t;
var s1_hdr.p4ml_entries.data28:s1_data_type_t;
var s1_hdr.p4ml_entries.data29:s1_data_type_t;
var s1_hdr.p4ml_entries.data30:s1_data_type_t;
var s1_hdr.p4ml_entries.data31:s1_data_type_t;
var s1_data.read_reg_appID_and_Seq:bv32;
var s1_data.read_reg_agtr_time:bv8;
var s1_data.tmp_reg_agtr_time:bv8;

// s1_Register s1_appID_and_Seq
var s1_appID_and_Seq:[bv32]bv32;
var s1_appID_and_Seq__last_index:bv32;
var s1_appID_and_Seq__last_value:bv32;
var s1_appID_and_Seq__last_old_value:bv32;
var s1_appID_and_Seq__wrote_any:bool;
var s1_appID_and_Seq__wrote_index0:bool;
var s1_appID_and_Seq__last0_old_value:bv32;
var s1_appID_and_Seq__last0_value:bv32;
var s1_appID_and_Seq__next_write_site:int;
var s1_appID_and_Seq__last_write_site:int;
const s1_appID_and_Seq.size:bv32;
axiom s1_appID_and_Seq.size == 20479bv32;

// s1_Register s1_agtr_time
var s1_agtr_time:[bv32]bv8;
var s1_agtr_time__last_index:bv32;
var s1_agtr_time__last_value:bv8;
var s1_agtr_time__last_old_value:bv8;
var s1_agtr_time__wrote_any:bool;
var s1_agtr_time__wrote_index0:bool;
var s1_agtr_time__last0_old_value:bv8;
var s1_agtr_time__last0_value:bv8;
var s1_agtr_time__next_write_site:int;
var s1_agtr_time__last_write_site:int;
const s1_agtr_time.size:bv32;
axiom s1_agtr_time.size == 20479bv32;
var s1_meta:s1_metadata;

function {:builtin "bvand"} band.bv32(s1_left:bv32, s1_right:bv32) returns(bv32);

function {:builtin "bvnot"} bnot.bv32(s1_left:bv32) returns(bv32);

function {:builtin "bvor"} bor.bv32(s1_left:bv32, s1_right:bv32) returns(bv32);

function {:builtin "bvadd"} add.bv8(s1_left:bv8, s1_right:bv8) returns(bv8);

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
	modifies s1_agtr_time, s1_agtr_time__last0_old_value, s1_agtr_time__last0_value, s1_agtr_time__last_index, s1_agtr_time__last_old_value, s1_agtr_time__last_value, s1_agtr_time__last_write_site, s1_agtr_time__next_write_site, s1_agtr_time__wrote_any, s1_agtr_time__wrote_index0, s1_appID_and_Seq, s1_appID_and_Seq__last0_old_value, s1_appID_and_Seq__last0_value, s1_appID_and_Seq__last_index, s1_appID_and_Seq__last_old_value, s1_appID_and_Seq__last_value, s1_appID_and_Seq__last_write_site, s1_appID_and_Seq__next_write_site, s1_appID_and_Seq__wrote_any, s1_appID_and_Seq__wrote_index0, s1_meta.agtr_time, s1_meta.integrated_bitmap, s1_meta.isAggregate, s1_meta.isMyAppIDandMyCurrentSeq, s1_meta.need_send_out, s1_meta.read_reg_agtr_time, s1_meta.read_reg_appID_and_Seq, s1_meta.tmp_reg_agtr_time;
{
    if(s1_isValid[s1_hdr.p4ml]){
        if((s1_hdr.p4ml.isACK == 1bv1)){
            if(((s1_hdr.p4ml.overflow == 1bv1)) && ((s1_hdr.p4ml.isResend == 0bv1))){
            }
            else{
                // s1_read
                s1_meta.read_reg_appID_and_Seq := s1_appID_and_Seq.read(s1_appID_and_Seq, 0bv16++s1_hdr.p4ml_agtr_index.agtr);
                if((s1_meta.read_reg_appID_and_Seq == s1_hdr.p4ml.appIDandSeqNum)){
                    // s1_write
                    s1_appID_and_Seq__next_write_site := 1;
                    call s1_appID_and_Seq.write(0bv16++s1_hdr.p4ml_agtr_index.agtr, 0bv32);
                    s1_meta.isMyAppIDandMyCurrentSeq := 1bv1;
                }
                if((s1_meta.isMyAppIDandMyCurrentSeq != 0bv1)){
                    // s1_write
                    s1_agtr_time__next_write_site := 1;
                    call s1_agtr_time.write(0bv16++s1_hdr.p4ml_agtr_index.agtr, 0bv8);
                }
            }
        }
        else{
            if((s1_hdr.p4ml.overflow == 1bv1)){
            }
            else{
                if((s1_hdr.p4ml.isResend == 1bv1)){
                    // s1_read
                    s1_meta.read_reg_appID_and_Seq := s1_appID_and_Seq.read(s1_appID_and_Seq, 0bv16++s1_hdr.p4ml_agtr_index.agtr);
                    if((s1_meta.read_reg_appID_and_Seq == s1_hdr.p4ml.appIDandSeqNum)){
                        // s1_write
                        s1_appID_and_Seq__next_write_site := 2;
                        call s1_appID_and_Seq.write(0bv16++s1_hdr.p4ml_agtr_index.agtr, 0bv32);
                        s1_meta.isMyAppIDandMyCurrentSeq := 1bv1;
                    }
                    else{
                        s1_meta.isMyAppIDandMyCurrentSeq := 0bv1;
                    }
                }
                else{
                    // s1_read
                    s1_meta.read_reg_appID_and_Seq := s1_appID_and_Seq.read(s1_appID_and_Seq, 0bv16++s1_hdr.p4ml_agtr_index.agtr);
                    if(((s1_meta.read_reg_appID_and_Seq == s1_hdr.p4ml.appIDandSeqNum)) || ((s1_meta.read_reg_appID_and_Seq == 0bv32))){
                        // s1_write
                        s1_appID_and_Seq__next_write_site := 3;
                        call s1_appID_and_Seq.write(0bv16++s1_hdr.p4ml_agtr_index.agtr, s1_hdr.p4ml.appIDandSeqNum);
                        s1_meta.isMyAppIDandMyCurrentSeq := 1bv1;
                    }
                    else{
                        s1_meta.isMyAppIDandMyCurrentSeq := 0bv1;
                    }
                }
                if((s1_meta.isMyAppIDandMyCurrentSeq == 1bv1)){
                    call s1_MyIngress_appid_seq_check_aggregate_and_forward();
                    if((s1_hdr.p4ml.isResend == 1bv1)){
                        // s1_write
                        s1_agtr_time__next_write_site := 2;
                        call s1_agtr_time.write(0bv16++s1_hdr.p4ml_agtr_index.agtr, 0bv8);
                        s1_meta.agtr_time := s1_hdr.p4ml.agtr_time;
                    }
                    else{
                        if((s1_meta.isAggregate != 0bv32)){
                            // s1_read
                            s1_meta.read_reg_agtr_time := s1_agtr_time.read(s1_agtr_time, 0bv16++s1_hdr.p4ml_agtr_index.agtr);
                            s1_meta.tmp_reg_agtr_time := add.bv8(s1_meta.read_reg_agtr_time, 1bv8);
                            // s1_write
                            s1_agtr_time__next_write_site := 3;
                            call s1_agtr_time.write(0bv16++s1_hdr.p4ml_agtr_index.agtr, s1_meta.tmp_reg_agtr_time);
                            // s1_read
                            s1_meta.agtr_time := s1_agtr_time.read(s1_agtr_time, 0bv16++s1_hdr.p4ml_agtr_index.agtr);
                        }
                    }
                    if((s1_meta.isAggregate != 0bv32)){
                        if((s1_meta.agtr_time == s1_hdr.p4ml.agtr_time)){
                            s1_meta.need_send_out := 1bv8;
                        }
                        else{
                            s1_meta.need_send_out := 0bv8;
                        }
                    }
                    else{
                        if((s1_meta.agtr_time == s1_hdr.p4ml.agtr_time)){
                            s1_meta.need_send_out := 1bv8;
                        }
                    }
                    if((s1_meta.isAggregate != 0bv32)){
                        if((s1_meta.agtr_time == s1_hdr.p4ml.agtr_time)){
                            s1_meta.need_send_out := 1bv8;
                        }
                        else{
                            s1_meta.need_send_out := 0bv8;
                        }
                    }
                    else{
                        if((s1_meta.agtr_time == s1_hdr.p4ml.agtr_time)){
                            s1_meta.need_send_out := 1bv8;
                        }
                    }
                    if((s1_meta.isAggregate != 0bv32)){
                        if((s1_meta.agtr_time == s1_hdr.p4ml.agtr_time)){
                            s1_meta.need_send_out := 1bv8;
                        }
                        else{
                            s1_meta.need_send_out := 0bv8;
                        }
                    }
                    else{
                        if((s1_meta.agtr_time == s1_hdr.p4ml.agtr_time)){
                            s1_meta.need_send_out := 1bv8;
                        }
                    }
                    if((s1_meta.isAggregate != 0bv32)){
                        if((s1_meta.agtr_time == s1_hdr.p4ml.agtr_time)){
                            s1_meta.need_send_out := 1bv8;
                        }
                        else{
                            s1_meta.need_send_out := 0bv8;
                        }
                    }
                    else{
                        if((s1_meta.agtr_time == s1_hdr.p4ml.agtr_time)){
                            s1_meta.need_send_out := 1bv8;
                        }
                    }
                }
                else{
                }
            }
        }
    }
    else{
    }
}

// s1_Action s1_MyIngress_appid_seq_check_aggregate_and_forward
procedure {:inline 1} s1_MyIngress_appid_seq_check_aggregate_and_forward()
	modifies s1_meta.integrated_bitmap, s1_meta.isAggregate;
{
    s1_meta.isAggregate := band.bv32(s1_hdr.p4ml.bitmap, bnot.bv32(s1_meta.bitmap));
    s1_meta.integrated_bitmap := bor.bv32(s1_hdr.p4ml.bitmap, s1_meta.bitmap);
}

// s1_Control s1_MyVerifyChecksum
procedure {:inline 1} s1_MyVerifyChecksum()
{
}

// s1_Parser s1_SwitchIngressParser
procedure {:inline 1} s1_SwitchIngressParser()
	modifies s1_drop, s1_isValid;
{
    goto s1_State$SwitchIngressParser$start;

        s1_State$SwitchIngressParser$start:
    call s1_packet_in.extract(s1_hdr.ethernet);
    goto s1_State$SwitchIngressParser$start$parse_p4ml_ipv4_2, s1_State$SwitchIngressParser$start$DEFAULT;
    
s1_State$SwitchIngressParser$start$parse_p4ml_ipv4_2:
    assume (s1_hdr.ethernet.ether_type == 2048bv16);
    goto s1_State$SwitchIngressParser$parse_p4ml_ipv4;

    s1_State$SwitchIngressParser$start$DEFAULT:
    assume(!(s1_hdr.ethernet.ether_type == 2048bv16));
    goto s1_State$accept;

        s1_State$SwitchIngressParser$parse_p4ml_ipv4:
    call s1_packet_in.extract(s1_hdr.ipv4);
    call s1_packet_in.extract(s1_hdr.udp);
    goto s1_State$SwitchIngressParser$parse_p4ml_ipv4$parse_p4ml_2, s1_State$SwitchIngressParser$parse_p4ml_ipv4$DEFAULT;
    
s1_State$SwitchIngressParser$parse_p4ml_ipv4$parse_p4ml_2:
    assume (s1_hdr.udp.dst_port == 6001bv16);
    goto s1_State$SwitchIngressParser$parse_p4ml;

    s1_State$SwitchIngressParser$parse_p4ml_ipv4$DEFAULT:
    assume(!(s1_hdr.udp.dst_port == 6001bv16));
    goto s1_State$accept;

        s1_State$SwitchIngressParser$parse_p4ml:
    call s1_packet_in.extract(s1_hdr.p4ml);
    call s1_packet_in.extract(s1_hdr.p4ml_agtr_index);
    call s1_packet_in.extract(s1_hdr.p4ml_entries);
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
function {:inline true}s1_agtr_time.read(s1_reg:[bv32]bv8, s1_index:bv32)returns (bv8) {s1_reg[s1_index]}
procedure {:inline 1} s1_agtr_time.write(s1_index:bv32, s1_value:bv8)
	modifies s1_agtr_time, s1_agtr_time__last0_old_value, s1_agtr_time__last0_value, s1_agtr_time__last_index, s1_agtr_time__last_old_value, s1_agtr_time__last_value, s1_agtr_time__last_write_site, s1_agtr_time__wrote_any, s1_agtr_time__wrote_index0;
{
    s1_agtr_time__last_old_value := s1_agtr_time[s1_index];
    s1_agtr_time[s1_index] := s1_value;
    s1_agtr_time__last_index := s1_index;
    s1_agtr_time__last_value := s1_value;
    s1_agtr_time__last_write_site := s1_agtr_time__next_write_site;
    s1_agtr_time__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_agtr_time__wrote_index0 := true;
        s1_agtr_time__last0_old_value := s1_agtr_time__last_old_value;
        s1_agtr_time__last0_value := s1_value;
    }
}
function {:inline true}s1_appID_and_Seq.read(s1_reg:[bv32]bv32, s1_index:bv32)returns (bv32) {s1_reg[s1_index]}
procedure {:inline 1} s1_appID_and_Seq.write(s1_index:bv32, s1_value:bv32)
	modifies s1_appID_and_Seq, s1_appID_and_Seq__last0_old_value, s1_appID_and_Seq__last0_value, s1_appID_and_Seq__last_index, s1_appID_and_Seq__last_old_value, s1_appID_and_Seq__last_value, s1_appID_and_Seq__last_write_site, s1_appID_and_Seq__wrote_any, s1_appID_and_Seq__wrote_index0;
{
    s1_appID_and_Seq__last_old_value := s1_appID_and_Seq[s1_index];
    s1_appID_and_Seq[s1_index] := s1_value;
    s1_appID_and_Seq__last_index := s1_index;
    s1_appID_and_Seq__last_value := s1_value;
    s1_appID_and_Seq__last_write_site := s1_appID_and_Seq__next_write_site;
    s1_appID_and_Seq__wrote_any := true;
    if (s1_index == 0bv32) {
        s1_appID_and_Seq__wrote_index0 := true;
        s1_appID_and_Seq__last0_old_value := s1_appID_and_Seq__last_old_value;
        s1_appID_and_Seq__last0_value := s1_value;
    }
}
procedure {:inline 1} s1_main()
	modifies s1_agtr_time, s1_agtr_time__last0_old_value, s1_agtr_time__last0_value, s1_agtr_time__last_index, s1_agtr_time__last_old_value, s1_agtr_time__last_value, s1_agtr_time__last_write_site, s1_agtr_time__next_write_site, s1_agtr_time__wrote_any, s1_agtr_time__wrote_index0, s1_appID_and_Seq, s1_appID_and_Seq__last0_old_value, s1_appID_and_Seq__last0_value, s1_appID_and_Seq__last_index, s1_appID_and_Seq__last_old_value, s1_appID_and_Seq__last_value, s1_appID_and_Seq__last_write_site, s1_appID_and_Seq__next_write_site, s1_appID_and_Seq__wrote_any, s1_appID_and_Seq__wrote_index0, s1_drop, s1_isValid, s1_meta.agtr_time, s1_meta.integrated_bitmap, s1_meta.isAggregate, s1_meta.isMyAppIDandMyCurrentSeq, s1_meta.need_send_out, s1_meta.read_reg_agtr_time, s1_meta.read_reg_appID_and_Seq, s1_meta.tmp_reg_agtr_time;
{
    call s1_SwitchIngressParser();
    call s1_MyVerifyChecksum();
    call s1_MyIngress();
    call s1_MyEgress();
    call s1_MyComputeChecksum();
    if(s1_forward == false){
        s1_drop := true;
    }
}
procedure s1_mainProcedure()
	modifies s1_agtr_time, s1_agtr_time__last0_old_value, s1_agtr_time__last0_value, s1_agtr_time__last_index, s1_agtr_time__last_old_value, s1_agtr_time__last_value, s1_agtr_time__last_write_site, s1_agtr_time__next_write_site, s1_agtr_time__wrote_any, s1_agtr_time__wrote_index0, s1_appID_and_Seq, s1_appID_and_Seq__last0_old_value, s1_appID_and_Seq__last0_value, s1_appID_and_Seq__last_index, s1_appID_and_Seq__last_old_value, s1_appID_and_Seq__last_value, s1_appID_and_Seq__last_write_site, s1_appID_and_Seq__next_write_site, s1_appID_and_Seq__wrote_any, s1_appID_and_Seq__wrote_index0, s1_drop, s1_isValid, s1_meta.agtr_time, s1_meta.integrated_bitmap, s1_meta.isAggregate, s1_meta.isMyAppIDandMyCurrentSeq, s1_meta.need_send_out, s1_meta.read_reg_agtr_time, s1_meta.read_reg_appID_and_Seq, s1_meta.tmp_reg_agtr_time, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate;
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
var procurator_phase: int;

// Register debug snapshots (for trace inspection)
var s1_agtr_time__dbg0: bv8;
var s1_agtr_time__last_index__dbg: bv32;
var s1_agtr_time__last_value__dbg: bv8;
var s1_agtr_time__last_old_value__dbg: bv8;
var s1_agtr_time__wrote_any__dbg: bool;
var s1_agtr_time__wrote_index0__dbg: bool;
var s1_agtr_time__last0_old_value__dbg: bv8;
var s1_agtr_time__last0_value__dbg: bv8;
var s1_appID_and_Seq__dbg0: bv32;
var s1_appID_and_Seq__last_index__dbg: bv32;
var s1_appID_and_Seq__last_value__dbg: bv32;
var s1_appID_and_Seq__last_old_value__dbg: bv32;
var s1_appID_and_Seq__wrote_any__dbg: bool;
var s1_appID_and_Seq__wrote_index0__dbg: bool;
var s1_appID_and_Seq__last0_old_value__dbg: bv32;
var s1_appID_and_Seq__last0_value__dbg: bv32;

var s1_inbox_count: int;
var io_inbox_count: int;

var s1_pkt_external: bool;
var io_pkt_external: bool;

// Host packet fields (mirrors connected node symbols)
var io_meta.read_reg_appID_and_Seq: bv32;
var io_meta.read_reg_agtr_time: bv8;
var io_meta.tmp_reg_agtr_time: bv8;
var io_meta.isMyAppIDandMyCurrentSeq: bv1;
var io_meta.bitmap: bv32;
var io_meta.isAggregate: bv32;
var io_meta.agtr_time: bv8;
var io_meta.integrated_bitmap: bv32;
var io_meta.need_send_out: bv8;
var io_hdr.ethernet.valid: bool;
var io_hdr.ethernet.ether_type: bv16;
var io_hdr.ipv4.valid: bool;
var io_hdr.udp.valid: bool;
var io_hdr.udp.dst_port: bv16;
var io_hdr.p4ml.valid: bool;
var io_hdr.p4ml.bitmap: bv32;
var io_hdr.p4ml.agtr_time: bv8;
var io_hdr.p4ml.overflow: bv1;
var io_hdr.p4ml.PSIndex: bv2;
var io_hdr.p4ml.dataIndex: bv1;
var io_hdr.p4ml.ECN: bv1;
var io_hdr.p4ml.isResend: bv1;
var io_hdr.p4ml.isSWCollision: bv1;
var io_hdr.p4ml.isACK: bv1;
var io_hdr.p4ml.appIDandSeqNum: bv32;
var io_hdr.p4ml_agtr_index.valid: bool;
var io_hdr.p4ml_agtr_index.agtr: bv16;
var io_hdr.p4ml_entries.valid: bool;
var io_hdr.p4ml_entries.data0: s1_data_type_t;
var io_hdr.p4ml_entries.data1: s1_data_type_t;
var io_hdr.p4ml_entries.data2: s1_data_type_t;
var io_hdr.p4ml_entries.data3: s1_data_type_t;

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

procedure main() returns()
  modifies io_hdr.ethernet.ether_type, io_hdr.ethernet.valid, io_hdr.ipv4.valid, io_hdr.p4ml.ECN, io_hdr.p4ml.PSIndex, io_hdr.p4ml.agtr_time, io_hdr.p4ml.appIDandSeqNum, io_hdr.p4ml.bitmap, io_hdr.p4ml.dataIndex, io_hdr.p4ml.isACK, io_hdr.p4ml.isResend, io_hdr.p4ml.isSWCollision, io_hdr.p4ml.overflow, io_hdr.p4ml.valid, io_hdr.p4ml_agtr_index.agtr, io_hdr.p4ml_agtr_index.valid, io_hdr.p4ml_entries.data0, io_hdr.p4ml_entries.data1, io_hdr.p4ml_entries.data2, io_hdr.p4ml_entries.data3, io_hdr.p4ml_entries.valid, io_hdr.udp.dst_port, io_hdr.udp.valid, io_inbox_count, io_meta.agtr_time, io_meta.bitmap, io_meta.integrated_bitmap, io_meta.isAggregate, io_meta.isMyAppIDandMyCurrentSeq, io_meta.need_send_out, io_meta.read_reg_agtr_time, io_meta.read_reg_appID_and_Seq, io_meta.tmp_reg_agtr_time, io_pkt_external, procurator_phase, procurator_step, s1_agtr_time, s1_agtr_time__dbg0, s1_agtr_time__last0_old_value, s1_agtr_time__last0_old_value__dbg, s1_agtr_time__last0_value, s1_agtr_time__last0_value__dbg, s1_agtr_time__last_index, s1_agtr_time__last_index__dbg, s1_agtr_time__last_old_value, s1_agtr_time__last_old_value__dbg, s1_agtr_time__last_value, s1_agtr_time__last_value__dbg, s1_agtr_time__last_write_site, s1_agtr_time__next_write_site, s1_agtr_time__wrote_any, s1_agtr_time__wrote_any__dbg, s1_agtr_time__wrote_index0, s1_agtr_time__wrote_index0__dbg, s1_appID_and_Seq, s1_appID_and_Seq__dbg0, s1_appID_and_Seq__last0_old_value, s1_appID_and_Seq__last0_old_value__dbg, s1_appID_and_Seq__last0_value, s1_appID_and_Seq__last0_value__dbg, s1_appID_and_Seq__last_index, s1_appID_and_Seq__last_index__dbg, s1_appID_and_Seq__last_old_value, s1_appID_and_Seq__last_old_value__dbg, s1_appID_and_Seq__last_value, s1_appID_and_Seq__last_value__dbg, s1_appID_and_Seq__last_write_site, s1_appID_and_Seq__next_write_site, s1_appID_and_Seq__wrote_any, s1_appID_and_Seq__wrote_any__dbg, s1_appID_and_Seq__wrote_index0, s1_appID_and_Seq__wrote_index0__dbg, s1_drop, s1_hdr.ethernet.ether_type, s1_hdr.ethernet.valid, s1_hdr.ipv4.valid, s1_hdr.p4ml.ECN, s1_hdr.p4ml.PSIndex, s1_hdr.p4ml.agtr_time, s1_hdr.p4ml.appIDandSeqNum, s1_hdr.p4ml.bitmap, s1_hdr.p4ml.dataIndex, s1_hdr.p4ml.isACK, s1_hdr.p4ml.isResend, s1_hdr.p4ml.isSWCollision, s1_hdr.p4ml.overflow, s1_hdr.p4ml.valid, s1_hdr.p4ml_agtr_index.agtr, s1_hdr.p4ml_agtr_index.valid, s1_hdr.p4ml_entries.data0, s1_hdr.p4ml_entries.data1, s1_hdr.p4ml_entries.data2, s1_hdr.p4ml_entries.data3, s1_hdr.p4ml_entries.valid, s1_hdr.udp.dst_port, s1_hdr.udp.valid, s1_inbox_count, s1_isValid, s1_meta.agtr_time, s1_meta.bitmap, s1_meta.integrated_bitmap, s1_meta.isAggregate, s1_meta.isMyAppIDandMyCurrentSeq, s1_meta.need_send_out, s1_meta.read_reg_agtr_time, s1_meta.read_reg_appID_and_Seq, s1_meta.tmp_reg_agtr_time, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_external;
{
  // One scheduler step: pick exactly one action.
  // Scheduler: deterministic round-robin over the action list.
  if (procurator_phase == 0) {
    // host send -> io
    // inject packet into connected node (host -> node)
    if (s1_inbox_count < 1) {
      assume s1_inbox_count < 1;
      havoc io_meta.read_reg_appID_and_Seq;
      havoc io_meta.read_reg_agtr_time;
      havoc io_meta.tmp_reg_agtr_time;
      havoc io_meta.isMyAppIDandMyCurrentSeq;
      havoc io_meta.bitmap;
      havoc io_meta.isAggregate;
      havoc io_meta.agtr_time;
      havoc io_meta.integrated_bitmap;
      havoc io_meta.need_send_out;
      havoc io_hdr.p4ml.overflow;
      io_hdr.ethernet.valid := true;
      io_hdr.ipv4.valid := true;
      io_hdr.udp.valid := true;
      io_hdr.p4ml.valid := true;
      io_hdr.p4ml_agtr_index.valid := true;
      io_hdr.p4ml_entries.valid := true;
      io_hdr.ethernet.ether_type := 2048bv16;
      io_hdr.udp.dst_port := 6001bv16;
      io_hdr.p4ml.bitmap := 1bv32;
      io_hdr.p4ml.appIDandSeqNum := 1bv32;
      io_hdr.p4ml.isResend := 0bv1;
      io_hdr.p4ml.isACK := 0bv1;
      io_hdr.p4ml.isSWCollision := 0bv1;
      io_hdr.p4ml.ECN := 0bv1;
      io_hdr.p4ml.dataIndex := 0bv1;
      io_hdr.p4ml.PSIndex := 0bv2;
      io_hdr.p4ml.agtr_time := 200bv8;
      io_hdr.p4ml_agtr_index.agtr := 0bv16;
      io_hdr.p4ml_entries.data0 := 0bv32;
      io_hdr.p4ml_entries.data1 := 0bv32;
      io_hdr.p4ml_entries.data2 := 0bv32;
      io_hdr.p4ml_entries.data3 := 0bv32;
      s1_meta.read_reg_appID_and_Seq := io_meta.read_reg_appID_and_Seq;
      s1_meta.read_reg_agtr_time := io_meta.read_reg_agtr_time;
      s1_meta.tmp_reg_agtr_time := io_meta.tmp_reg_agtr_time;
      s1_meta.isMyAppIDandMyCurrentSeq := io_meta.isMyAppIDandMyCurrentSeq;
      s1_meta.bitmap := io_meta.bitmap;
      s1_meta.isAggregate := io_meta.isAggregate;
      s1_meta.agtr_time := io_meta.agtr_time;
      s1_meta.integrated_bitmap := io_meta.integrated_bitmap;
      s1_meta.need_send_out := io_meta.need_send_out;
      s1_hdr.ethernet.valid := io_hdr.ethernet.valid;
      s1_hdr.ethernet.ether_type := io_hdr.ethernet.ether_type;
      s1_hdr.ipv4.valid := io_hdr.ipv4.valid;
      s1_hdr.udp.valid := io_hdr.udp.valid;
      s1_hdr.udp.dst_port := io_hdr.udp.dst_port;
      s1_hdr.p4ml.valid := io_hdr.p4ml.valid;
      s1_hdr.p4ml.bitmap := io_hdr.p4ml.bitmap;
      s1_hdr.p4ml.agtr_time := io_hdr.p4ml.agtr_time;
      s1_hdr.p4ml.overflow := io_hdr.p4ml.overflow;
      s1_hdr.p4ml.PSIndex := io_hdr.p4ml.PSIndex;
      s1_hdr.p4ml.dataIndex := io_hdr.p4ml.dataIndex;
      s1_hdr.p4ml.ECN := io_hdr.p4ml.ECN;
      s1_hdr.p4ml.isResend := io_hdr.p4ml.isResend;
      s1_hdr.p4ml.isSWCollision := io_hdr.p4ml.isSWCollision;
      s1_hdr.p4ml.isACK := io_hdr.p4ml.isACK;
      s1_hdr.p4ml.appIDandSeqNum := io_hdr.p4ml.appIDandSeqNum;
      s1_hdr.p4ml_agtr_index.valid := io_hdr.p4ml_agtr_index.valid;
      s1_hdr.p4ml_agtr_index.agtr := io_hdr.p4ml_agtr_index.agtr;
      s1_hdr.p4ml_entries.valid := io_hdr.p4ml_entries.valid;
      s1_hdr.p4ml_entries.data0 := io_hdr.p4ml_entries.data0;
      s1_hdr.p4ml_entries.data1 := io_hdr.p4ml_entries.data1;
      s1_hdr.p4ml_entries.data2 := io_hdr.p4ml_entries.data2;
      s1_hdr.p4ml_entries.data3 := io_hdr.p4ml_entries.data3;
      s1_pkt_external := true;
      s1_inbox_count := s1_inbox_count + 1;
    }
  } else if (procurator_phase == 1) {
    // host recv -> io
  } else if (procurator_phase == 2) {
    // node pass -> s1
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
    s1_agtr_time__dbg0 := s1_agtr_time[0bv32];
    s1_agtr_time__last_index__dbg := s1_agtr_time__last_index;
    s1_agtr_time__last_value__dbg := s1_agtr_time__last_value;
    s1_agtr_time__last_old_value__dbg := s1_agtr_time__last_old_value;
    s1_agtr_time__wrote_any__dbg := s1_agtr_time__wrote_any;
    s1_agtr_time__wrote_index0__dbg := s1_agtr_time__wrote_index0;
    s1_agtr_time__last0_old_value__dbg := s1_agtr_time__last0_old_value;
    s1_agtr_time__last0_value__dbg := s1_agtr_time__last0_value;
    s1_appID_and_Seq__dbg0 := s1_appID_and_Seq[0bv32];
    s1_appID_and_Seq__last_index__dbg := s1_appID_and_Seq__last_index;
    s1_appID_and_Seq__last_value__dbg := s1_appID_and_Seq__last_value;
    s1_appID_and_Seq__last_old_value__dbg := s1_appID_and_Seq__last_old_value;
    s1_appID_and_Seq__wrote_any__dbg := s1_appID_and_Seq__wrote_any;
    s1_appID_and_Seq__wrote_index0__dbg := s1_appID_and_Seq__wrote_index0;
    s1_appID_and_Seq__last0_old_value__dbg := s1_appID_and_Seq__last0_old_value;
    s1_appID_and_Seq__last0_value__dbg := s1_appID_and_Seq__last0_value;
    // Global assertions
    assert ((s1_meta.isMyAppIDandMyCurrentSeq != 1bv1) || (s1_meta.isAggregate == 0bv32) || (s1_meta.need_send_out != 0bv8));
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
  modifies io_hdr.ethernet.ether_type, io_hdr.ethernet.valid, io_hdr.ipv4.valid, io_hdr.p4ml.ECN, io_hdr.p4ml.PSIndex, io_hdr.p4ml.agtr_time, io_hdr.p4ml.appIDandSeqNum, io_hdr.p4ml.bitmap, io_hdr.p4ml.dataIndex, io_hdr.p4ml.isACK, io_hdr.p4ml.isResend, io_hdr.p4ml.isSWCollision, io_hdr.p4ml.overflow, io_hdr.p4ml.valid, io_hdr.p4ml_agtr_index.agtr, io_hdr.p4ml_agtr_index.valid, io_hdr.p4ml_entries.data0, io_hdr.p4ml_entries.data1, io_hdr.p4ml_entries.data2, io_hdr.p4ml_entries.data3, io_hdr.p4ml_entries.valid, io_hdr.udp.dst_port, io_hdr.udp.valid, io_inbox_count, io_meta.agtr_time, io_meta.bitmap, io_meta.integrated_bitmap, io_meta.isAggregate, io_meta.isMyAppIDandMyCurrentSeq, io_meta.need_send_out, io_meta.read_reg_agtr_time, io_meta.read_reg_appID_and_Seq, io_meta.tmp_reg_agtr_time, io_pkt_external, procurator_phase, procurator_step, s1_agtr_time, s1_agtr_time__dbg0, s1_agtr_time__last0_old_value, s1_agtr_time__last0_old_value__dbg, s1_agtr_time__last0_value, s1_agtr_time__last0_value__dbg, s1_agtr_time__last_index, s1_agtr_time__last_index__dbg, s1_agtr_time__last_old_value, s1_agtr_time__last_old_value__dbg, s1_agtr_time__last_value, s1_agtr_time__last_value__dbg, s1_agtr_time__last_write_site, s1_agtr_time__next_write_site, s1_agtr_time__wrote_any, s1_agtr_time__wrote_any__dbg, s1_agtr_time__wrote_index0, s1_agtr_time__wrote_index0__dbg, s1_appID_and_Seq, s1_appID_and_Seq__dbg0, s1_appID_and_Seq__last0_old_value, s1_appID_and_Seq__last0_old_value__dbg, s1_appID_and_Seq__last0_value, s1_appID_and_Seq__last0_value__dbg, s1_appID_and_Seq__last_index, s1_appID_and_Seq__last_index__dbg, s1_appID_and_Seq__last_old_value, s1_appID_and_Seq__last_old_value__dbg, s1_appID_and_Seq__last_value, s1_appID_and_Seq__last_value__dbg, s1_appID_and_Seq__last_write_site, s1_appID_and_Seq__next_write_site, s1_appID_and_Seq__wrote_any, s1_appID_and_Seq__wrote_any__dbg, s1_appID_and_Seq__wrote_index0, s1_appID_and_Seq__wrote_index0__dbg, s1_drop, s1_hdr.ethernet.ether_type, s1_hdr.ethernet.valid, s1_hdr.ipv4.valid, s1_hdr.p4ml.ECN, s1_hdr.p4ml.PSIndex, s1_hdr.p4ml.agtr_time, s1_hdr.p4ml.appIDandSeqNum, s1_hdr.p4ml.bitmap, s1_hdr.p4ml.dataIndex, s1_hdr.p4ml.isACK, s1_hdr.p4ml.isResend, s1_hdr.p4ml.isSWCollision, s1_hdr.p4ml.overflow, s1_hdr.p4ml.valid, s1_hdr.p4ml_agtr_index.agtr, s1_hdr.p4ml_agtr_index.valid, s1_hdr.p4ml_entries.data0, s1_hdr.p4ml_entries.data1, s1_hdr.p4ml_entries.data2, s1_hdr.p4ml_entries.data3, s1_hdr.p4ml_entries.valid, s1_hdr.udp.dst_port, s1_hdr.udp.valid, s1_inbox_count, s1_isValid, s1_meta.agtr_time, s1_meta.bitmap, s1_meta.integrated_bitmap, s1_meta.isAggregate, s1_meta.isMyAppIDandMyCurrentSeq, s1_meta.need_send_out, s1_meta.read_reg_agtr_time, s1_meta.read_reg_appID_and_Seq, s1_meta.tmp_reg_agtr_time, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_external;
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
  assume (forall i:bv32 :: s1_agtr_time[i] == 0bv8);
  assume s1_agtr_time[0bv32] == 0bv8;
  assume (forall i:bv32 :: s1_appID_and_Seq[i] == 0bv32);
  assume s1_appID_and_Seq[0bv32] == 0bv32;
  // initialize register write tracking (debug)
  s1_agtr_time__last_index := 0bv32;
  s1_agtr_time__last_value := 0bv8;
  s1_agtr_time__last_old_value := 0bv8;
  s1_agtr_time__wrote_any := false;
  s1_agtr_time__wrote_index0 := false;
  s1_agtr_time__next_write_site := 0;
  s1_agtr_time__last_write_site := 0;
  s1_agtr_time__last0_old_value := 0bv8;
  s1_agtr_time__last0_value := 0bv8;
  s1_appID_and_Seq__last_index := 0bv32;
  s1_appID_and_Seq__last_value := 0bv32;
  s1_appID_and_Seq__last_old_value := 0bv32;
  s1_appID_and_Seq__wrote_any := false;
  s1_appID_and_Seq__wrote_index0 := false;
  s1_appID_and_Seq__next_write_site := 0;
  s1_appID_and_Seq__last_write_site := 0;
  s1_appID_and_Seq__last0_old_value := 0bv32;
  s1_appID_and_Seq__last0_value := 0bv32;

  procurator_step := 0;
  procurator_phase := 0;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}


procedure ULTIMATE.start() returns()
  modifies io_hdr.ethernet.ether_type, io_hdr.ethernet.valid, io_hdr.ipv4.valid, io_hdr.p4ml.ECN, io_hdr.p4ml.PSIndex, io_hdr.p4ml.agtr_time, io_hdr.p4ml.appIDandSeqNum, io_hdr.p4ml.bitmap, io_hdr.p4ml.dataIndex, io_hdr.p4ml.isACK, io_hdr.p4ml.isResend, io_hdr.p4ml.isSWCollision, io_hdr.p4ml.overflow, io_hdr.p4ml.valid, io_hdr.p4ml_agtr_index.agtr, io_hdr.p4ml_agtr_index.valid, io_hdr.p4ml_entries.data0, io_hdr.p4ml_entries.data1, io_hdr.p4ml_entries.data2, io_hdr.p4ml_entries.data3, io_hdr.p4ml_entries.valid, io_hdr.udp.dst_port, io_hdr.udp.valid, io_inbox_count, io_meta.agtr_time, io_meta.bitmap, io_meta.integrated_bitmap, io_meta.isAggregate, io_meta.isMyAppIDandMyCurrentSeq, io_meta.need_send_out, io_meta.read_reg_agtr_time, io_meta.read_reg_appID_and_Seq, io_meta.tmp_reg_agtr_time, io_pkt_external, procurator_phase, procurator_step, s1_agtr_time, s1_agtr_time__dbg0, s1_agtr_time__last0_old_value, s1_agtr_time__last0_old_value__dbg, s1_agtr_time__last0_value, s1_agtr_time__last0_value__dbg, s1_agtr_time__last_index, s1_agtr_time__last_index__dbg, s1_agtr_time__last_old_value, s1_agtr_time__last_old_value__dbg, s1_agtr_time__last_value, s1_agtr_time__last_value__dbg, s1_agtr_time__last_write_site, s1_agtr_time__next_write_site, s1_agtr_time__wrote_any, s1_agtr_time__wrote_any__dbg, s1_agtr_time__wrote_index0, s1_agtr_time__wrote_index0__dbg, s1_appID_and_Seq, s1_appID_and_Seq__dbg0, s1_appID_and_Seq__last0_old_value, s1_appID_and_Seq__last0_old_value__dbg, s1_appID_and_Seq__last0_value, s1_appID_and_Seq__last0_value__dbg, s1_appID_and_Seq__last_index, s1_appID_and_Seq__last_index__dbg, s1_appID_and_Seq__last_old_value, s1_appID_and_Seq__last_old_value__dbg, s1_appID_and_Seq__last_value, s1_appID_and_Seq__last_value__dbg, s1_appID_and_Seq__last_write_site, s1_appID_and_Seq__next_write_site, s1_appID_and_Seq__wrote_any, s1_appID_and_Seq__wrote_any__dbg, s1_appID_and_Seq__wrote_index0, s1_appID_and_Seq__wrote_index0__dbg, s1_drop, s1_hdr.ethernet.ether_type, s1_hdr.ethernet.valid, s1_hdr.ipv4.valid, s1_hdr.p4ml.ECN, s1_hdr.p4ml.PSIndex, s1_hdr.p4ml.agtr_time, s1_hdr.p4ml.appIDandSeqNum, s1_hdr.p4ml.bitmap, s1_hdr.p4ml.dataIndex, s1_hdr.p4ml.isACK, s1_hdr.p4ml.isResend, s1_hdr.p4ml.isSWCollision, s1_hdr.p4ml.overflow, s1_hdr.p4ml.valid, s1_hdr.p4ml_agtr_index.agtr, s1_hdr.p4ml_agtr_index.valid, s1_hdr.p4ml_entries.data0, s1_hdr.p4ml_entries.data1, s1_hdr.p4ml_entries.data2, s1_hdr.p4ml_entries.data3, s1_hdr.p4ml_entries.valid, s1_hdr.udp.dst_port, s1_hdr.udp.valid, s1_inbox_count, s1_isValid, s1_meta.agtr_time, s1_meta.bitmap, s1_meta.integrated_bitmap, s1_meta.isAggregate, s1_meta.isMyAppIDandMyCurrentSeq, s1_meta.need_send_out, s1_meta.read_reg_agtr_time, s1_meta.read_reg_appID_and_Seq, s1_meta.tmp_reg_agtr_time, s1_p4b_checksum_error, s1_p4b_checksum_updated, s1_p4b_checksum_verified, s1_p4b_clone_e2e, s1_p4b_clone_i2e, s1_p4b_clone_i2i, s1_p4b_digest, s1_p4b_recirculate, s1_pkt_external;
{
  call mainProcedure();
}

// ===== END HARNESS =====
