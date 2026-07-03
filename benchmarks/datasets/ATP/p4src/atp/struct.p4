#include "headers.p4"



struct metadata {
    bit<32> read_reg_appID_and_Seq ;
    bit<32> read_reg_bitmap;
    bit<32> tmp_reg_bitmap;
    bit<32> tmp_register;
    //bit<32> read_reg_agtr_time;
    //bit<32> tmp_reg_agtr_time;
    bit<8> read_reg_agtr_time;
    bit<8> tmp_reg_agtr_time;
    //bit<16>--->bit<1> just for flag,so 1bit enough
 	bit<1>          isMyAppIDandMyCurrentSeq;  
    bit<7>          pad                     ;
    bit<32>         bitmap                  ;
    bit<32>         isAggregate             ;
    bit<8>          agtr_time               ;
    //bit<32>          agtr_time               ;
    bit<32>         integrated_bitmap       ;
    bit<32>         agtr_index              ;
    bit<16>         qdepth                  ;
    bit<8>          is_ecn                  ; 
    bit<8>		    need_send_out           ;
}

struct headers {
    ethernet_h ethernet;
    ipv4_h ipv4;
    udp_h udp;
    p4ml_h p4ml;
    p4ml_agtr_index_h p4ml_agtr_index;
    entry_h p4ml_entries;

}

