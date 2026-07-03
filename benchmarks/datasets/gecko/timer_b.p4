#include <core.p4>
#include <tna.p4>

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
    bit<32>  address_l;   
    bit<32>  time;       
    bit<32>  num;         
    bit<32>  index;       
    bit<32>  CS_id_1;
    bit<32>  CS_offset_1;
    bit<32>  CS_id_2;
    bit<32>  CS_offset_2;
    bit<32>  CS_id_3;
    bit<32>  CS_offset_3;
    bit<16>  port;
}

header albion_data_t {
    bit<32> data_0;
    bit<32> data_1;
    bit<32> data_2;
    bit<32> data_3;
    bit<32> data_4;
    bit<32> data_5;
    bit<32> data_6;
    bit<32> data_7;
    bit<32> data_8;
    bit<32> data_9;
    bit<32> data_10;
    bit<32> data_11;
}

header albion_timer_t {
    bit<32> times;
    bit<32> const_time;
    bit<32> now;
    bit<32> address_high_0;
    bit<32> address_low_0;
    bit<32>  state_0;
    bit<32> address_high_1;
    bit<32> address_low_1;
    bit<32>  state_1;
    bit<32> address_high_2;
    bit<32> address_low_2;
    bit<32>  state_2;
    bit<32> address_high_3;
    bit<32> address_low_3;
    bit<32>  state_3;
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
    bit<32>   state;
    bit<32>   state_sub;
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
/***********************  P A R S E R  **************************/

parser bIngressParser(packet_in      pkt,
    out headers          hdr,
    out my_ingress_metadata_t         meta,
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }
    
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
			ETHERTYPE_ALBION :  parse_albion;
            default          :  accept;
        }
    }

    state parse_albion {
        pkt.extract(hdr.albion);
		transition accept;
    }
}


/***************** M A T C H - A C T I O N  *********************/

control bIngress(
    /* User */
    inout headers                       hdr,
    inout my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
	apply {
        if(hdr.ethernet.ether_type == 0x5555)
        {
            ig_tm_md.ucast_egress_port = (bit<9>)hdr.albion.port;
        }
	}
}

/*********************  D E P A R S E R  ************************/

control bIngressDeparser(packet_out pkt,
    /* User */
    inout headers                       hdr,
    in    my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
{
	apply{
		pkt.emit(hdr);
	}
}
/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

/***********************  P A R S E R  **************************/

parser bEgressParser(packet_in      pkt,
    /* User */
    out headers          hdr,
    out my_egress_metadata_t         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        transition parse_pre;
    }
    
    state parse_pre {
        mirror_h mirror_md = pkt.lookahead<mirror_h>();
        transition select(mirror_md.pkt_type) {
			1          :  parse_mirror_1;
            2          :  parse_mirror_2;
            default    :  parse_ethernet;
        }
    }

    state parse_mirror_1 {
        pkt.extract(hdr.mirror_1);
        mirror_h mirror_md = pkt.lookahead<mirror_h>();
        transition select(mirror_md.pkt_type) {
			2          :  parse_mirror_1_2;
            default    :  parse_ethernet;
        }
    }

    state parse_mirror_2 {
        pkt.extract(hdr.mirror_2);
        mirror_h mirror_md = pkt.lookahead<mirror_h>();
        transition select(mirror_md.pkt_type) {
			1          :  parse_mirror_2_1;
            default    :  parse_ethernet;
        }
    }

    state parse_mirror_1_2 {
        pkt.extract(hdr.mirror_2);
        transition parse_ethernet;
    }

    state parse_mirror_2_1 {
        pkt.extract(hdr.mirror_1);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
			ETHERTYPE_ALBION :  parse_albion;
            default          :  reject;
        }
    }

    state parse_albion {
        pkt.extract(hdr.albion);
		transition select(hdr.albion.operation) {
            default          :  parse_albion_data;
        }
    }

    state parse_albion_data {
        pkt.extract(hdr.albion_data);
		transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control bEgress(
    /* User */
    inout headers                          hdr,
    inout my_egress_metadata_t                         meta,
    /* Intrinsic */    
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{
    #define register_data_record(number) \
    Register<bit<32>,bit<32>>(140500,0) register_data_record_##number##; \
	RegisterAction<bit<32>, bit<32>, bit<32>>(register_data_record_##number##) register_data_record_##number##_read = { \
        void apply(inout bit<32> value_r, out bit<32> read_value){ \
            read_value = value_r;\
        } \
    }; \
	RegisterAction<bit<32>, bit<32>, bit<32>>(register_data_record_##number##) register_data_record_##number##_write = { \
        void apply(inout bit<32> value_r){ \
            value_r = hdr.albion_data.data_##number##;\
        } \
    };

    register_data_record(0)
    register_data_record(1)
    register_data_record(2)
    register_data_record(3)
    register_data_record(4)
    register_data_record(5)
    register_data_record(6)
    register_data_record(7)
    register_data_record(8)
    register_data_record(9)
    register_data_record(10)
    register_data_record(11)


    action action_dst_cs_1(){
		meta.session_id = 1;
	}

    action action_dst_cs_2(){
		meta.session_id = 2;
	}

    action action_dst_cs_3(){
		meta.session_id = 3;
	}

    action action_dst_cs_4(){
		meta.session_id = 4;
	}

    table table_dst_cs_70{
        key = { hdr.albion.CS_id_1: 	exact;}
        actions = {
			action_dst_cs_1;
            action_dst_cs_2;
            action_dst_cs_3;
            action_dst_cs_4;
        }
		const entries = {
            1:   action_dst_cs_1();
            2:   action_dst_cs_2();
            3:   action_dst_cs_3();
            4:   action_dst_cs_4();
            10:  action_dst_cs_4();
		}
        const default_action = action_dst_cs_1();
        size = 5;
    }

    table table_dst_cs_1{
        key = { hdr.albion.CS_id_2: 	exact;}
        actions = {
			action_dst_cs_1;
            action_dst_cs_2;
            action_dst_cs_3;
            action_dst_cs_4;
        }
		const entries = {
            1:   action_dst_cs_1();
            2:   action_dst_cs_2();
            3:   action_dst_cs_3();
            4:   action_dst_cs_4();
            10:  action_dst_cs_4();
		}
        const default_action = action_dst_cs_1();
        size = 5;
    }

    table table_dst_cs_2{
        key = { hdr.albion.CS_id_3: 	exact;}
        actions = {
			action_dst_cs_1;
            action_dst_cs_2;
            action_dst_cs_3;
            action_dst_cs_4;
        }
		const entries = {
            1:   action_dst_cs_1();
            2:   action_dst_cs_2();
            3:   action_dst_cs_3();
            4:   action_dst_cs_4();
            10:  action_dst_cs_4();
		}
        const default_action = action_dst_cs_1();
        size = 5;
    }

    apply {
        if(hdr.ethernet.ether_type == 0x5555)
        {
            if(hdr.mirror_2.isValid())
            {
                hdr.mirror_1.setInvalid();
                hdr.mirror_2.setInvalid();
                hdr.albion.operation = 12;
            }
            else if(hdr.mirror_1.isValid())
            {
                hdr.mirror_1.setInvalid();
                table_dst_cs_2.apply();
                meta.no_use = 2;
                eg_dprsr_md.mirror_type = MIRROR_TYPE_CS;
                hdr.albion.operation = 11;
            }
            else if(hdr.albion.operation == 70)
            {
                table_dst_cs_70.apply();
                meta.no_use = 1;
                eg_dprsr_md.mirror_type = MIRROR_TYPE_CS;
            }
            else if(hdr.albion.operation == 10)
            {
                table_dst_cs_1.apply();
                meta.no_use = 1;
                eg_dprsr_md.mirror_type = MIRROR_TYPE_CS;
                register_data_record_0_write.execute(hdr.albion.index);
            }
            
            if(hdr.albion.operation == 10)
            {
                register_data_record_1_write.execute(hdr.albion.index);
            }

            if(hdr.albion.operation == 10)
            {
                register_data_record_2_write.execute(hdr.albion.index);
            }

            if(hdr.albion.operation == 10)
            {
                register_data_record_3_write.execute(hdr.albion.index);
            }

            if(hdr.albion.operation == 10)
            {
                register_data_record_4_write.execute(hdr.albion.index);
            }

            if(hdr.albion.operation == 10)
            {
                register_data_record_5_write.execute(hdr.albion.index);
            }

            if(hdr.albion.operation == 10)
            {
                register_data_record_6_write.execute(hdr.albion.index);
            }

            if(hdr.albion.operation == 10)
            {
                register_data_record_7_write.execute(hdr.albion.index);
            }

            if(hdr.albion.operation == 10)
            {
                register_data_record_8_write.execute(hdr.albion.index);
            }

            if(hdr.albion.operation == 10)
            {
                register_data_record_9_write.execute(hdr.albion.index);
            }

            if(hdr.albion.operation == 10)
            {
                register_data_record_10_write.execute(hdr.albion.index);
            }

            if(hdr.albion.operation == 10)
            {
                register_data_record_11_write.execute(hdr.albion.index);
            }
            else if(hdr.albion.operation == 11)
            {
                if(hdr.albion.CS_id_2 == 10)
                {
                    hdr.albion.operation = 70;
                }
            }
            else if(hdr.albion.operation == 12)
            {
                if(hdr.albion.CS_id_3 == 10)
                {
                    hdr.albion.operation = 70;
                }
            }
        }
    }
}

/*********************  D E P A R S E R  ************************/

control bEgressDeparser(packet_out pkt,
    /* User */
    inout headers                       hdr,
    in    my_egress_metadata_t                      meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    Mirror() mirror_1;
    
    apply {
        if(eg_dprsr_md.mirror_type == MIRROR_TYPE_CS){
            mirror_1.emit<mirror_h>(meta.session_id, {meta.no_use});
        }
        pkt.emit(hdr);
    }
}

Pipeline(
    bIngressParser(),
    bIngress(),
    bIngressDeparser(),
    bEgressParser(),
    bEgress(),
    bEgressDeparser()
) pipe_b;

Switch(pipe_b) main;