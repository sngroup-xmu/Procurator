#include <core.p4>
#if __TARGET_TOFINO__ == 2 
    #include <t2na.p4>     // Tofino 2
#else
    #include <tna.p4>      // Tofino 1
#endif

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
*************************************************************************/

const bit<16> ETHERTYPE_P4_MUC = 0x7777;
const bit<16> ETHERTYPE_ALBION = 0x5555;

#if __TARGET_TOFINO__ == 1
typedef bit<3> mirror_type_t;
#else
typedef bit<4> mirror_type_t;
#endif
const mirror_type_t MIRROR_TYPE_CS = 1;
const mirror_type_t MIRROR_TYPE_MS = 2;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
header ethernet_t {
    bit<48>  dst_addr;
    bit<48>  src_addr;
    bit<16>  ether_type;
}

header mirror_h {
  bit<8>  pkt_type;
}

header albion_t {
    bit<32>  request_id_high;
    bit<32>  request_id_low;
    bit<32>  operation;
    bit<32>  address_h;
    bit<32>  address_l;    //这个是对用户而言的实际地址
    bit<32>  time;         //这个是当前时间地址
    bit<32>  num;          //这个是当前时间地址下的第几个槽
    bit<32>  index;        //根据time和num计算出来的实际下标索引
    bit<32>  CS_id_1;
    bit<32>  CS_offset_1;
    bit<32>  CS_id_2;
    bit<32>  CS_offset_2;
    bit<32>  CS_id_3;
    bit<32>  CS_offset_3;
}

header albion_data_t {
    bit<32> data_0;
    bit<32> data_1;
}

header albion_timer_t {
    bit<32> times;
    bit<32> const_time;
    bit<32> now;
    bit<32> address_high_0;
    bit<32> address_low_0;
    bit<8>  state_0;
    bit<32> address_high_1;
    bit<32> address_low_1;
    bit<8>  state_1;
    bit<32> address_high_2;
    bit<32> address_low_2;
    bit<8>  state_2;
    bit<32> address_high_3;
    bit<32> address_low_3;
    bit<8>  state_3;
    bit<32> address_high_4;
    bit<32> address_low_4;
    bit<8>  state_4;
    bit<32> address_high_5;
    bit<32> address_low_5;
    bit<8>  state_5;
    bit<32> address_high_6;
    bit<32> address_low_6;
    bit<8>  state_6;
    bit<32> address_high_7;
    bit<32> address_low_7;
    bit<8>  state_7;
    bit<32> address_high_8;
    bit<32> address_low_8;
    bit<8>  state_8;
    bit<32> address_high_9;
    bit<32> address_low_9;
    bit<8>  state_9;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
 
 
 
/***********************  H E A D E R S  ************************/


struct headers {
    mirror_h       mirror_1;
    mirror_h       mirror_2;
    ethernet_t     ethernet;
    albion_t       albion;
    albion_data_t  albion_data;
    albion_timer_t albion_timer;
}

/******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
	bit<32>  time_1;
    bit<32>  time_2;
    bit<8>   state;
    bit<8>   state_sub;
    bit<8>   no_use_1;
    bit<8>   no_use_2;
}

/********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
    MirrorId_t session_id;
    bit<8> no_use;
    bit<32> id_1;
    bit<32> offset_1;
    bit<32> id_2;
    bit<32> offset_2;
    bit<32> id_3;
    bit<32> offset_3;
}

#include "timer_a_ingress.p4"
#include "timer_a_egress.p4"
#include "timer_b_ingress.p4"
#include "timer_b_egress.p4"


/************ F I N A L   P A C K A G E ******************************/
Pipeline(
    aIngressParser(),
    aIngress(),
    aIngressDeparser(),
    aEgressParser(),
    aEgress(),
    aEgressDeparser()
) pipe_a;

Pipeline(
    bIngressParser(),
    bIngress(),
    bIngressDeparser(),
    bEgressParser(),
    bEgress(),
    bEgressDeparser()
) pipe_b;

Switch(pipe_a,pipe_b) main;
