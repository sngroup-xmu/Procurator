#ifndef _HEADERS_
#define _HEADERS_

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
//user define field
const ether_type_t ETHERTYPE_ATP = 16w0x0800;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_IPV4 = 4;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;

typedef bit<16> udp_port_t;

typedef bit<32> const_t;
const bit<32> total_aggregator_cnt = 32w0x4fff;
typedef bit<16> total_aggregator_idx_t;



typedef bit<32> data_type_t;
//struct pair_t {
//        data_type_t first;
//        data_type_t second;
//}


header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

header p4ml_h{
    //one switch
    bit<32> bitmap;  
    //aggregation count,for compare the number of worker
    bit<8> agtr_time; 
    // overflow flag
    bit<1> overflow;
     /* For multiple PS */
    bit<2> PSIndex;
    /* For signle PS */
    // reserved       :  2;
    // isForceFoward  :  1;

    //resubmit flag
    bit<1> dataIndex;
    bit<1> ECN;
    bit<1> isResend;
    bit<1> isSWCollision;
    bit<1> isACK;
    //in switchml.p4: this is used to find the bit location
    bit<32> appIDandSeqNum;  

}
header p4ml_agtr_index_h{
    //aggregatorIndex
    bit<16> agtr;
}

header entry_h{
data_type_t        data0 ; 
data_type_t        data1 ;
data_type_t        data2 ;
data_type_t        data3 ;
data_type_t        data4 ;
data_type_t        data5 ;
data_type_t        data6 ;
data_type_t        data7 ;
data_type_t        data8 ;
data_type_t        data9 ;
data_type_t        data10;
data_type_t        data11;
data_type_t        data12;
data_type_t        data13;
data_type_t        data14;
data_type_t        data15;
data_type_t        data16;
data_type_t        data17;
data_type_t        data18;
data_type_t        data19;
data_type_t        data20;
data_type_t        data21;
data_type_t        data22;
data_type_t        data23;
data_type_t        data24;
data_type_t        data25;
data_type_t        data26;
data_type_t        data27;
data_type_t        data28;
data_type_t        data29;
data_type_t        data30;
data_type_t        data31;

}





#endif /* _HEADERS_ */

