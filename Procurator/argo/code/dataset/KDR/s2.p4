#include <core.p4>
#include <v1model.p4>

header ethernet_h {
    bit<48> dst_addr;
    bit<48> src_addr;
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
    bit<32> src_addr;
    bit<32> dst_addr;
}
header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}
header p4ml_h {
    bit<32> bitmap;
    bit<8> agtr_time;
    bit<1> overflow;
    bit<2> PSIndex;
    bit<1> dataIndex;
    bit<1> ECN;
    bit<1> isResend;
    bit<1> isSWCollision;
    bit<1> isACK;
    bit<32> appIDandSeqNum;
}
header p4ml_agtr_index_h {
    bit<16> agtr;
}
header entry_h {
    bit<32> data0;
    bit<32> data1;
    bit<32> data2;
    bit<32> data3;
    bit<32> data4;
    bit<32> data5;
    bit<32> data6;
    bit<32> data7;
    bit<32> data8;
    bit<32> data9;
    bit<32> data10;
    bit<32> data11;
    bit<32> data12;
    bit<32> data13;
    bit<32> data14;
    bit<32> data15;
    bit<32> data16;
    bit<32> data17;
    bit<32> data18;
    bit<32> data19;
    bit<32> data20;
    bit<32> data21;
    bit<32> data22;
    bit<32> data23;
    bit<32> data24;
    bit<32> data25;
    bit<32> data26;
    bit<32> data27;
    bit<32> data28;
    bit<32> data29;
    bit<32> data30;
    bit<32> data31;
}

struct global_metadata_t {
    bit<32> read_reg_appID_and_Seq;
    bit<32> read_reg_bitmap;
    bit<32> tmp_reg_bitmap;
    bit<32> tmp_register;
    bit<8> read_reg_agtr_time;
    bit<8> tmp_reg_agtr_time;
    bit<1> isMyAppIDandMyCurrentSeq;
    bit<7> pad;
    bit<32> bitmap;
    bit<32> isAggregate;
    bit<8> agtr_time;
    bit<32> integrated_bitmap;
    bit<32> agtr_index;
    bit<16> qdepth;
    bit<8> is_ecn;
    bit<8> need_send_out;
}
struct header_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    udp_h udp;
    p4ml_h p4ml;
    p4ml_agtr_index_h p4ml_agtr_index;
    entry_h p4ml_entries;
}

parser LynetteParser(packet_in pkt, out header_t hdr, inout global_metadata_t gmeta, inout standard_metadata_t im){
    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            16w0x0800: parse_p4ml_ipv4;
            default: accept;
        }
    }
    state parse_p4ml_ipv4 {
        pkt.extract(hdr.ipv4);
        transition parse_udp;
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            6001: parse_p4ml;
            default: accept;
        }
    }
    state parse_p4ml {
        pkt.extract(hdr.p4ml);
        transition parse_agtr_index;
    }
    state parse_agtr_index {
        pkt.extract(hdr.p4ml_agtr_index);
        transition parse_entry;
    }
    state parse_entry {
        pkt.extract(hdr.p4ml_entries);
        transition accept;
    }
}

control LynetteVerifyChecksum(inout header_t hdr, inout global_metadata_t gmeta) {
    apply {  }
}

control LynetteIngress(
    inout header_t hdr,
    inout global_metadata_t gmeta,
    inout standard_metadata_t im)
{
    bit<32> Alice_ipv4_Switch_main_read_register0;
    bit<32> Alice_ipv4_Switch_main_read_register1;
    bit<32> Alice_ipv4_Switch_main_read_register2;
    bit<32> Alice_ipv4_Switch_main_read_register3;
    bit<32> Alice_ipv4_Switch_main_ecn_index;
    bit<32> Alice_ipv4_Switch_main_read_reg_ecn;
    
    action Alice_ipv4_Switch_main_appid_seq_AtpAck_multicast_action(bit<16> value_0)
    {
        im.mcast_grp = value_0;
    }
    action Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_action(bit<9> value_0, bit<48> value_1)
    {
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        im.egress_spec = value_0;
        hdr.ethernet.dst_addr = value_1;
    }
    action Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_action_1(bit<9> value_0)
    {
        im.egress_spec = value_0;
        hdr.p4ml.dataIndex = 1;
    }
    action Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data0_modify_packet_bitmap_table_action()
    {
        hdr.p4ml.bitmap = gmeta.integrated_bitmap;
    }
    action Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data0_modify_packet_bitmap_table_1_action()
    {
        hdr.p4ml.bitmap = gmeta.integrated_bitmap;
    }
    action Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data1_modify_packet_bitmap_table_action()
    {
        hdr.p4ml.bitmap = gmeta.integrated_bitmap;
    }
    action Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data1_modify_packet_bitmap_table_1_action()
    {
        hdr.p4ml.bitmap = gmeta.integrated_bitmap;
    }
    action Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data2_modify_packet_bitmap_table_action()
    {
        hdr.p4ml.bitmap = gmeta.integrated_bitmap;
    }
    action Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data2_modify_packet_bitmap_table_1_action()
    {
        hdr.p4ml.bitmap = gmeta.integrated_bitmap;
    }
    action Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data3_modify_packet_bitmap_table_action()
    {
        hdr.p4ml.bitmap = gmeta.integrated_bitmap;
    }
    action Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data3_modify_packet_bitmap_table_1_action()
    {
        hdr.p4ml.bitmap = gmeta.integrated_bitmap;
    }
    action Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_1_action(bit<9> value_0, bit<48> value_1)
    {
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        im.egress_spec = value_0;
        hdr.ethernet.dst_addr = value_1;
    }
    action Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_1_action_1(bit<9> value_0)
    {
        im.egress_spec = value_0;
        hdr.p4ml.dataIndex = 1;
    }
    action Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_2_action(bit<9> value_0, bit<48> value_1)
    {
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        im.egress_spec = value_0;
        hdr.ethernet.dst_addr = value_1;
    }
    action Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_2_action_1(bit<9> value_0)
    {
        im.egress_spec = value_0;
        hdr.p4ml.dataIndex = 1;
    }
    action Alice_ipv4_Switch_main_dmac_action(bit<9> value_0)
    {
        im.egress_spec = value_0;
    }
    action Alice_ipv4_Switch_main_dmac_action_1()
    {
        ;
    }
    
    table Alice_ipv4_Switch_main_appid_seq_AtpAck_multicast{
        key = {
            hdr.p4ml.isACK : exact;
            hdr.p4ml.appIDandSeqNum : exact;
        }
        actions = {
            Alice_ipv4_Switch_main_appid_seq_AtpAck_multicast_action;
        }
    }
    table Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward{
        key = {
            hdr.p4ml.appIDandSeqNum : exact;
        }
        actions = {
            Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_action;
            Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_action_1;
        }
    }
    table Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data0_modify_packet_bitmap_table{
        key = {
            hdr.p4ml.dataIndex : exact;
        }
        actions = {
            Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data0_modify_packet_bitmap_table_action;
        }
    }
    table Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data0_modify_packet_bitmap_table_1{
        key = {
            hdr.p4ml.dataIndex : exact;
        }
        actions = {
            Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data0_modify_packet_bitmap_table_1_action;
        }
    }
    table Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data1_modify_packet_bitmap_table{
        key = {
            hdr.p4ml.dataIndex : exact;
        }
        actions = {
            Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data1_modify_packet_bitmap_table_action;
        }
    }
    table Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data1_modify_packet_bitmap_table_1{
        key = {
            hdr.p4ml.dataIndex : exact;
        }
        actions = {
            Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data1_modify_packet_bitmap_table_1_action;
        }
    }
    table Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data2_modify_packet_bitmap_table{
        key = {
            hdr.p4ml.dataIndex : exact;
        }
        actions = {
            Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data2_modify_packet_bitmap_table_action;
        }
    }
    table Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data2_modify_packet_bitmap_table_1{
        key = {
            hdr.p4ml.dataIndex : exact;
        }
        actions = {
            Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data2_modify_packet_bitmap_table_1_action;
        }
    }
    table Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data3_modify_packet_bitmap_table{
        key = {
            hdr.p4ml.dataIndex : exact;
        }
        actions = {
            Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data3_modify_packet_bitmap_table_action;
        }
    }
    table Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data3_modify_packet_bitmap_table_1{
        key = {
            hdr.p4ml.dataIndex : exact;
        }
        actions = {
            Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data3_modify_packet_bitmap_table_1_action;
        }
    }
    table Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_1{
        key = {
            hdr.p4ml.appIDandSeqNum : exact;
        }
        actions = {
            Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_1_action;
            Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_1_action_1;
        }
    }
    table Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_2{
        key = {
            hdr.p4ml.appIDandSeqNum : exact;
        }
        actions = {
            Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_2_action;
            Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_2_action_1;
        }
    }
    table Alice_ipv4_Switch_main_dmac{
        key = {
            hdr.ethernet.dst_addr : exact;
        }
        actions = {
            Alice_ipv4_Switch_main_dmac_action;
            Alice_ipv4_Switch_main_dmac_action_1;
        }
        default_action = Alice_ipv4_Switch_main_dmac_action_1();
    }
    
    register<bit<32>>(20479) appID_and_Seq;
    register<bit<32>>(20479) bitmap;
    register<bit<8>>(20479) agtr_time;
    register<bit<32>>(20479) ecn_register;
    register<bit<32>>(20479) register0;
    register<bit<32>>(20479) register1;
    register<bit<32>>(20479) register2;
    register<bit<32>>(20479) register3;
    register<bit<32>>(1) ecn;
    
    apply {
    
        /*******************************************/
    
    
        /*******************************************/
    
        if(hdr.p4ml.isValid())
        {
            if(hdr.ipv4.diffserv == 0x11)
            {
                gmeta.is_ecn = 1;
            }
            if(hdr.p4ml.ECN == 1)
            {
                gmeta.is_ecn = 1;
            }
            if(hdr.p4ml.isACK == 1)
            {
                if(hdr.p4ml.overflow != 1)
                {
                    if(hdr.p4ml.isResend != 0)
                    {
                        appID_and_Seq.read(gmeta.read_reg_appID_and_Seq, (bit<32>)hdr.p4ml_agtr_index.agtr);
                        if(gmeta.read_reg_appID_and_Seq == hdr.p4ml.appIDandSeqNum)
                        {
                            appID_and_Seq.write((bit<32>)hdr.p4ml_agtr_index.agtr, 0);
                            gmeta.isMyAppIDandMyCurrentSeq = 1;
                        }
                        if(gmeta.isMyAppIDandMyCurrentSeq != 0)
                        {
                            bitmap.write((bit<32>)hdr.p4ml_agtr_index.agtr, 0);
                            ecn_register.write((bit<32>)hdr.p4ml_agtr_index.agtr, 0);
                            agtr_time.write((bit<32>)hdr.p4ml_agtr_index.agtr, 0);
                        }
                    }
                }
                Alice_ipv4_Switch_main_appid_seq_AtpAck_multicast.apply();
            }
            else
            {
                if(hdr.p4ml.overflow == 1)
                {
                    Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward.apply();
                }
                else
                {
                    if(hdr.p4ml.isResend == 1)
                    {
                        appID_and_Seq.read(gmeta.read_reg_appID_and_Seq, (bit<32>)hdr.p4ml_agtr_index.agtr);
                        if(gmeta.read_reg_appID_and_Seq == hdr.p4ml.appIDandSeqNum)
                        {
                            appID_and_Seq.write((bit<32>)hdr.p4ml_agtr_index.agtr, 0);
                            gmeta.isMyAppIDandMyCurrentSeq = 1;
                        }
                        else
                        {
                            gmeta.isMyAppIDandMyCurrentSeq = 0;
                        }
                    }
                    else
                    {
                        appID_and_Seq.read(gmeta.read_reg_appID_and_Seq, (bit<32>)hdr.p4ml_agtr_index.agtr);
                        if(gmeta.read_reg_appID_and_Seq == hdr.p4ml.appIDandSeqNum)
                        {
                            appID_and_Seq.write((bit<32>)hdr.p4ml_agtr_index.agtr, hdr.p4ml.appIDandSeqNum);
                            gmeta.isMyAppIDandMyCurrentSeq = 1;
                        }
                        else
                        {
                            if(gmeta.read_reg_appID_and_Seq == 0)
                            {
                                appID_and_Seq.write((bit<32>)hdr.p4ml_agtr_index.agtr, hdr.p4ml.appIDandSeqNum);
                                gmeta.isMyAppIDandMyCurrentSeq = 1;
                            }
                            else
                            {
                                gmeta.isMyAppIDandMyCurrentSeq = 0;
                            }
                        }
                    }
                    if(gmeta.isMyAppIDandMyCurrentSeq == 1)
                    {
                        bitmap.read(gmeta.read_reg_bitmap, (bit<32>)hdr.p4ml_agtr_index.agtr);
                        gmeta.isAggregate = hdr.p4ml.bitmap & ~gmeta.bitmap;
                        gmeta.integrated_bitmap = hdr.p4ml.bitmap | gmeta.bitmap;
                        if(hdr.p4ml.isResend == 1)
                        {
                            bitmap.write((bit<32>)hdr.p4ml_agtr_index.agtr, 0);
                            bitmap.read(gmeta.bitmap, (bit<32>)hdr.p4ml_agtr_index.agtr);
                        }
                        else
                        {
                            gmeta.tmp_reg_bitmap = gmeta.read_reg_bitmap | hdr.p4ml.bitmap;
                            bitmap.write((bit<32>)hdr.p4ml_agtr_index.agtr, gmeta.tmp_reg_bitmap);
                            bitmap.read(gmeta.bitmap, (bit<32>)hdr.p4ml_agtr_index.agtr);
                        }
                        if(hdr.p4ml.isResend == 1)
                        {
                            agtr_time.write((bit<32>)hdr.p4ml_agtr_index.agtr, 0);
                            gmeta.agtr_time = hdr.p4ml.agtr_time;
                        }
                        else
                        {
                            if(gmeta.isAggregate != 0)
                            {
                                agtr_time.read(gmeta.read_reg_agtr_time, (bit<32>)hdr.p4ml_agtr_index.agtr);
                                gmeta.tmp_reg_agtr_time = gmeta.read_reg_agtr_time + 1;
                                agtr_time.write((bit<32>)hdr.p4ml_agtr_index.agtr, gmeta.tmp_reg_agtr_time);
                                agtr_time.read(gmeta.agtr_time, (bit<32>)hdr.p4ml_agtr_index.agtr);
                            }
                        }
                        if(gmeta.isAggregate != 0)
                        {
                            if(gmeta.agtr_time == hdr.p4ml.agtr_time)
                            {
                                register0.read(Alice_ipv4_Switch_main_read_register0, (bit<32>)hdr.p4ml_agtr_index.agtr);
                                if(Alice_ipv4_Switch_main_read_register0 != 0x7fffffff)
                                {
                                    gmeta.tmp_register = Alice_ipv4_Switch_main_read_register0 |+| hdr.p4ml_entries.data0;
                                    register0.write((bit<32>)hdr.p4ml_agtr_index.agtr, gmeta.tmp_register);
                                }
                                hdr.p4ml_entries.data0 = gmeta.tmp_register;
                                Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data0_modify_packet_bitmap_table.apply();
                                gmeta.need_send_out = 1;
                            }
                            else
                            {
                                gmeta.need_send_out = 0;
                                if(Alice_ipv4_Switch_main_read_register0 != 0x7fffffff)
                                {
                                    register0.read(Alice_ipv4_Switch_main_read_register0, (bit<32>)hdr.p4ml_agtr_index.agtr);
                                    gmeta.tmp_register = Alice_ipv4_Switch_main_read_register0 |+| hdr.p4ml_entries.data0;
                                    register0.write((bit<32>)hdr.p4ml_agtr_index.agtr, gmeta.tmp_register);
                                }
                            }
                        }
                        else
                        {
                            if(gmeta.agtr_time == hdr.p4ml.agtr_time)
                            {
                                register0.read(Alice_ipv4_Switch_main_read_register0, (bit<32>)hdr.p4ml_agtr_index.agtr);
                                Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data0_modify_packet_bitmap_table_1.apply();
                                gmeta.need_send_out = 1;
                            }
                        }
                        if(gmeta.isAggregate != 0)
                        {
                            if(gmeta.agtr_time == hdr.p4ml.agtr_time)
                            {
                                register1.read(Alice_ipv4_Switch_main_read_register1, (bit<32>)hdr.p4ml_agtr_index.agtr);
                                if(Alice_ipv4_Switch_main_read_register1 != 0x7fffffff)
                                {
                                    gmeta.tmp_register = Alice_ipv4_Switch_main_read_register1 |+| hdr.p4ml_entries.data1;
                                    register1.write((bit<32>)hdr.p4ml_agtr_index.agtr, gmeta.tmp_register);
                                }
                                hdr.p4ml_entries.data1 = gmeta.tmp_register;
                                Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data1_modify_packet_bitmap_table.apply();
                                gmeta.need_send_out = 1;
                            }
                            else
                            {
                                gmeta.need_send_out = 0;
                                if(Alice_ipv4_Switch_main_read_register1 != 0x7fffffff)
                                {
                                    register1.read(Alice_ipv4_Switch_main_read_register1, (bit<32>)hdr.p4ml_agtr_index.agtr);
                                    gmeta.tmp_register = Alice_ipv4_Switch_main_read_register1 |+| hdr.p4ml_entries.data1;
                                    register1.write((bit<32>)hdr.p4ml_agtr_index.agtr, gmeta.tmp_register);
                                }
                            }
                        }
                        else
                        {
                            if(gmeta.agtr_time == hdr.p4ml.agtr_time)
                            {
                                register1.read(Alice_ipv4_Switch_main_read_register1, (bit<32>)hdr.p4ml_agtr_index.agtr);
                                Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data1_modify_packet_bitmap_table_1.apply();
                                gmeta.need_send_out = 1;
                            }
                        }
                        if(gmeta.isAggregate != 0)
                        {
                            if(gmeta.agtr_time == hdr.p4ml.agtr_time)
                            {
                                register2.read(Alice_ipv4_Switch_main_read_register2, (bit<32>)hdr.p4ml_agtr_index.agtr);
                                if(Alice_ipv4_Switch_main_read_register2 != 0x7fffffff)
                                {
                                    gmeta.tmp_register = Alice_ipv4_Switch_main_read_register2 |+| hdr.p4ml_entries.data2;
                                    register2.write((bit<32>)hdr.p4ml_agtr_index.agtr, gmeta.tmp_register);
                                }
                                hdr.p4ml_entries.data2 = gmeta.tmp_register;
                                Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data2_modify_packet_bitmap_table.apply();
                                gmeta.need_send_out = 1;
                            }
                            else
                            {
                                gmeta.need_send_out = 0;
                                if(Alice_ipv4_Switch_main_read_register2 != 0x7fffffff)
                                {
                                    register2.read(Alice_ipv4_Switch_main_read_register2, (bit<32>)hdr.p4ml_agtr_index.agtr);
                                    gmeta.tmp_register = Alice_ipv4_Switch_main_read_register2 |+| hdr.p4ml_entries.data2;
                                    register2.write((bit<32>)hdr.p4ml_agtr_index.agtr, gmeta.tmp_register);
                                }
                            }
                        }
                        else
                        {
                            if(gmeta.agtr_time == hdr.p4ml.agtr_time)
                            {
                                register2.read(Alice_ipv4_Switch_main_read_register2, (bit<32>)hdr.p4ml_agtr_index.agtr);
                                Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data2_modify_packet_bitmap_table_1.apply();
                                gmeta.need_send_out = 1;
                            }
                        }
                        if(gmeta.isAggregate != 0)
                        {
                            if(gmeta.agtr_time == hdr.p4ml.agtr_time)
                            {
                                register3.read(Alice_ipv4_Switch_main_read_register3, (bit<32>)hdr.p4ml_agtr_index.agtr);
                                if(Alice_ipv4_Switch_main_read_register3 != 0x7fffffff)
                                {
                                    gmeta.tmp_register = Alice_ipv4_Switch_main_read_register3 |+| hdr.p4ml_entries.data3;
                                    register3.write((bit<32>)hdr.p4ml_agtr_index.agtr, gmeta.tmp_register);
                                }
                                hdr.p4ml_entries.data3 = gmeta.tmp_register;
                                Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data3_modify_packet_bitmap_table.apply();
                                gmeta.need_send_out = 1;
                            }
                            else
                            {
                                gmeta.need_send_out = 0;
                                if(Alice_ipv4_Switch_main_read_register3 != 0x7fffffff)
                                {
                                    register3.read(Alice_ipv4_Switch_main_read_register3, (bit<32>)hdr.p4ml_agtr_index.agtr);
                                    gmeta.tmp_register = Alice_ipv4_Switch_main_read_register3 |+| hdr.p4ml_entries.data3;
                                    register3.write((bit<32>)hdr.p4ml_agtr_index.agtr, gmeta.tmp_register);
                                }
                            }
                        }
                        else
                        {
                            if(gmeta.agtr_time == hdr.p4ml.agtr_time)
                            {
                                register3.read(Alice_ipv4_Switch_main_read_register3, (bit<32>)hdr.p4ml_agtr_index.agtr);
                                Alice_ipv4_Switch_main_appid_seq_PROCESS_ENTRY_process_data3_modify_packet_bitmap_table_1.apply();
                                gmeta.need_send_out = 1;
                            }
                        }
                        if(gmeta.isAggregate != 0)
                        {
                            if(gmeta.need_send_out == 1)
                            {
                                Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_1.apply();
                            }
                            else
                            {
                                mark_to_drop(im);
                            }
                        }
                    }
                    else
                    {
                        if(hdr.p4ml.isResend == 0)
                        {
                            hdr.p4ml.isSWCollision = 1;
                        }
                        Alice_ipv4_Switch_main_appid_seq_Route_multicast_dmac_forward_2.apply();
                    }
                }
            }
        }
        else
        {
            Alice_ipv4_Switch_main_dmac.apply();
        }
        Alice_ipv4_Switch_main_ecn_index = 0;
        ecn.read(Alice_ipv4_Switch_main_read_reg_ecn, (bit<32>)Alice_ipv4_Switch_main_ecn_index);
        if(im.deq_qdepth > 1000)
        {
            Alice_ipv4_Switch_main_read_reg_ecn = 6;
        }
        else
        {
            Alice_ipv4_Switch_main_read_reg_ecn = 0;
        }
        if(Alice_ipv4_Switch_main_read_reg_ecn == 6)
        {
            if(hdr.ethernet.ether_type == 0x0800)
            {
                hdr.ipv4.diffserv = 0b11;
            }
            if(hdr.ethernet.ether_type == 0x0700)
            {
                hdr.p4ml.ECN = 1;
            }
        }
    
        /*******************************************/
    
    
        /*******************************************/
    
    }
}

control LynetteDeparser(packet_out pkt, in header_t hdr) {
    apply{ 
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.p4ml);
        pkt.emit(hdr.p4ml_agtr_index);
        pkt.emit(hdr.p4ml_entries);
    } 
}

control LynetteEgress(
    inout header_t                          hdr,
    inout global_metadata_t                         gmeta,
    inout standard_metadata_t standard_metadata)
{
    apply {
    }
}

control LynetteComputeChecksum(inout header_t  hdr, inout global_metadata_t gmeta) {
        apply {
    }
}

V1Switch(
    LynetteParser(),
    LynetteVerifyChecksum(),
    LynetteIngress(),
    LynetteEgress(),
    LynetteComputeChecksum(),
    LynetteDeparser()
)main;