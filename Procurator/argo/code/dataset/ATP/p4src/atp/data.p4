#include "headers.p4"



#define REG_TABLES(n)                                                                                           \
control ProcessData##n(                                                                                         \
        inout headers hdr,                                                                              \
        inout metadata meta,                                                                                    \
        inout standard_metadata_t standard_metadata                                                             \
  ){                                                                                                            \
        action nop(){ }                                                                                             \
	action modify_packet_bitmap() {                                                                             \
    	hdr.p4ml.bitmap = meta.integrated_bitmap;                                                               \
	}                                                                                                           \
        table modify_packet_bitmap_table {                                                                          \
	    key = {                                                                                                 \
	        hdr.p4ml.dataIndex: exact;                                                                          \
	    }                                                                                                       \
	    actions = {                                                                                             \
	        modify_packet_bitmap; nop;                                                                          \
	    }                                                                                                       \
	    const default_action = nop;                                                                             \
            size = 2;                                                                                               \
	}                                                                                                           \
    register<bit<32>>(total_aggregator_cnt) register##n;                                                        \
    bit<32> read_register##n;                                                                                   \
    apply{                                                                                                      \
        if(meta.isAggregate != 0){                                                                              \
            if (meta.agtr_time == hdr.p4ml.agtr_time){                                                          \
                register##n.read(read_register##n,(bit<32>)hdr.p4ml_agtr_index.agtr);                           \
                if(read_register##n  != 0x7fffffff) {                                                           \
                    meta.tmp_register = read_register##n |+| hdr.p4ml_entries.data##n;                            \
                    register##n.write((bit<32>)hdr.p4ml_agtr_index.agtr,meta.tmp_register);                       \
                }                                                                                               \
                hdr.p4ml_entries.data##n = meta.tmp_register;                                                   \
                modify_packet_bitmap_table.apply();                                                             \
                meta.need_send_out = 1;                                                                         \
            }else{                                                                                              \
                meta.need_send_out = 0;                                                                         \
                    if(read_register##n  != 0x7fffffff) {                                                       \
                    register##n.read(read_register##n,(bit<32>)hdr.p4ml_agtr_index.agtr);                       \
                    meta.tmp_register = read_register##n |+| hdr.p4ml_entries.data##n;                            \
                    register##n.write((bit<32>)hdr.p4ml_agtr_index.agtr,meta.tmp_register);                       \
                }                                                                                               \
            }                                                                                                   \
        }else{                                                                                                  \
            if(meta.agtr_time == hdr.p4ml.agtr_time){                                                           \
                register##n.read(read_register##n,(bit<32>)hdr.p4ml_agtr_index.agtr);                           \
                modify_packet_bitmap_table.apply();                                                             \
                meta.need_send_out = 1;                                                                         \
            }                                                                                                   \
        }                                                                                                       \
    }                                                                                                           \
}                                                                                                               \




#define PROCESS_ENTRY                                          \
process_data0.apply(hdr,  meta,   standard_metadata);          \
process_data1.apply(hdr,  meta, standard_metadata);            \
process_data2.apply(hdr, meta, standard_metadata);             \
process_data3.apply(hdr,  meta, standard_metadata);            \
//process_data4.apply( p4ml, p4ml_entries.data4,  meta, p4ml_entries.data4,   p4ml_agtr_index);          \
//process_data5.apply( p4ml, p4ml_entries.data5,  meta, p4ml_entries.data5,   p4ml_agtr_index);          \
//process_data6.apply( p4ml, p4ml_entries.data6,  meta, p4ml_entries.data6,   p4ml_agtr_index);          \
//process_data7.apply( p4ml, p4ml_entries.data7,  meta, p4ml_entries.data7,   p4ml_agtr_index);          \
//process_data8.apply( p4ml, p4ml_entries.data8,  meta, p4ml_entries.data8,   p4ml_agtr_index);          \
//process_data9.apply( p4ml, p4ml_entries.data9,  meta, p4ml_entries.data9,   p4ml_agtr_index);          \
//process_data10.apply(p4ml, p4ml_entries.data10, meta, p4ml_entries.data10,  p4ml_agtr_index);          \
//process_data11.apply(p4ml, p4ml_entries.data11, meta, p4ml_entries.data11,  p4ml_agtr_index);          \
//process_data12.apply(p4ml, p4ml_entries.data12, meta, p4ml_entries.data12,  p4ml_agtr_index);          \
//process_data13.apply(p4ml, p4ml_entries.data13, meta, p4ml_entries.data13,  p4ml_agtr_index);          \
//process_data14.apply(p4ml, p4ml_entries.data14, meta, p4ml_entries.data14,  p4ml_agtr_index);          \
//process_data15.apply(p4ml, p4ml_entries.data15, meta, p4ml_entries.data15,  p4ml_agtr_index);          \
//process_data16.apply(p4ml, p4ml_entries.data16, meta, p4ml_entries.data16,  p4ml_agtr_index);          \
//process_data17.apply(p4ml, p4ml_entries.data17, meta, p4ml_entries.data17,  p4ml_agtr_index);          \
//process_data18.apply(p4ml, p4ml_entries.data18, meta, p4ml_entries.data18,  p4ml_agtr_index);          \
//process_data19.apply(p4ml, p4ml_entries.data19, meta, p4ml_entries.data19,  p4ml_agtr_index);          \
//process_data20.apply(p4ml, p4ml_entries.data20, meta, p4ml_entries.data20,  p4ml_agtr_index);          \
//process_data21.apply(p4ml, p4ml_entries.data21, meta, p4ml_entries.data21,  p4ml_agtr_index);          \
//process_data22.apply(p4ml, p4ml_entries.data22, meta, p4ml_entries.data22,  p4ml_agtr_index);          \
//process_data23.apply(p4ml, p4ml_entries.data23, meta, p4ml_entries.data23,  p4ml_agtr_index);          \
//process_data24.apply(p4ml, p4ml_entries.data24, meta, p4ml_entries.data24,  p4ml_agtr_index);          \
//process_data25.apply(p4ml, p4ml_entries.data25, meta, p4ml_entries.data25,  p4ml_agtr_index);          \
//process_data26.apply(p4ml, p4ml_entries.data26, meta, p4ml_entries.data26,  p4ml_agtr_index);          \
//process_data27.apply(p4ml, p4ml_entries.data27, meta, p4ml_entries.data27,  p4ml_agtr_index);          \
//process_data28.apply(p4ml, p4ml_entries.data28, meta, p4ml_entries.data28,  p4ml_agtr_index);          \
//process_data29.apply(p4ml, p4ml_entries.data29, meta, p4ml_entries.data29,  p4ml_agtr_index);          \
//process_data30.apply(p4ml, p4ml_entries.data30, meta, p4ml_entries.data30,  p4ml_agtr_index);          \

       
REG_TABLES(0) 
REG_TABLES(1) 
REG_TABLES(2)
REG_TABLES(3) 
//REG_TABLES(4) 
//REG_TABLES(5) 
//REG_TABLES(6) 
//REG_TABLES(7) 
//REG_TABLES(8) 
//REG_TABLES(9) 
//REG_TABLES(10) 
//REG_TABLES(11) 
//REG_TABLES(12) 
//REG_TABLES(13) 
//REG_TABLES(14) 
//REG_TABLES(15) 
//REG_TABLES(16) 
//REG_TABLES(17) 
//REG_TABLES(18) 
//REG_TABLES(19) 
//REG_TABLES(20) 
//REG_TABLES(21) 
//REG_TABLES(22) 
//REG_TABLES(23) 
//REG_TABLES(24) 
//REG_TABLES(25) 
//REG_TABLES(26) 
//REG_TABLES(27) 
//REG_TABLES(28) 
//REG_TABLES(29) 
//REG_TABLES(30)



