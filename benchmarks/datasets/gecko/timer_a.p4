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

parser aIngressParser(packet_in      pkt,
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
            default          :  reject;
        }
    }

    state parse_albion {
        pkt.extract(hdr.albion);
		transition select(hdr.albion.operation) {
            100              :  parse_albion_timer;
            101              :  parse_albion_timer;
            default          :  parse_albion_data;
        }
    }

    state parse_albion_data {
        pkt.extract(hdr.albion_data);
		transition accept;
    }

    state parse_albion_timer {
        pkt.extract(hdr.albion_timer);
		transition accept;
    }
}


/***************** M A T C H - A C T I O N  *********************/

control aIngress(
    /* User */
    inout headers                       hdr,
    inout my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    action no_action(){
        ;
    }

    Register<bit<32>,bit<32>>(1,0) register_request_id_low; 		
	RegisterAction<bit<32>, bit<32>, bit<32>>(register_request_id_low) register_request_id_low_add = { 
        void apply(inout bit<32> value_r, out bit<32> value_t){ 
            value_r = value_r + 1;
            value_t = value_r;
        } 
    }; 

    Register<bit<32>,bit<32>>(1,0) register_num; 		
	RegisterAction<bit<32>, bit<32>, bit<32>>(register_num) register_num_add = { 
        void apply(inout bit<32> value_r, out bit<32> value_t){ 
            value_t = value_r;
            value_r = value_r + 1;
        } 
    }; 
    RegisterAction<bit<32>, bit<32>, bit<32>>(register_num) register_num_zero = { 
        void apply(inout bit<32> value_r, out bit<32> value_t){ 
            value_r = 0;
        } 
    };

    Register<bit<32>,bit<32>>(1,0) register_timer; 		
	RegisterAction<bit<32>, bit<32>, bit<32>>(register_timer) register_timer_add = { 
        void apply(inout bit<32> value_r, out bit<32> value_t){ 
            if(value_r == 666)  //满载是17500
            {
                value_r = 0;
            }
            else
            {
                value_r = value_r + 1;
            }
            value_t = value_r;
        } 
    }; 
    RegisterAction<bit<32>, bit<32>, bit<32>>(register_timer) register_timer_read = { 
        void apply(inout bit<32> value_r, out bit<32> value_t){ 
            value_t = value_r;
        } 
    }; 

    action action_register_timer_add(){
        hdr.albion.time = register_timer_add.execute(0);
    }
    action action_register_timer_read(){
        hdr.albion.time = register_timer_read.execute(0);
    }
    table table_register_timer_interaction {
        key = { hdr.albion.operation: exact; }
        actions = { no_action;
                    action_register_timer_add;
                    action_register_timer_read; }
        const entries = {
            100:  action_register_timer_add();
              1:  action_register_timer_read();
        }
        const default_action = no_action();
        size = 10;
    }

    action action_register_num_add(){
        hdr.albion.num = register_num_add.execute(0);
    }
    action action_register_num_zero(){
        register_num_zero.execute(0);
    }
    table table_register_num_interaction{
        key = { hdr.albion.operation: exact; }
        actions = { action_register_num_add;
                    action_register_num_zero; }
        const entries = {
            1  :  action_register_num_add();
            100:  action_register_num_zero();
        }
        const default_action = action_register_num_add();
        size = 2;
    }

    Register<bit<32>,bit<32>>(1,0) register_request_id_high; 		
	RegisterAction<bit<32>, bit<32>, bit<32>>(register_request_id_high) register_request_id_high_add = { 
        void apply(inout bit<32> value_r, out bit<32> value_t){ 
            value_r = value_r + 1;
            value_t = value_r;
        } 
    }; 
    action action_register_request_id_high_add(){
        hdr.albion.request_id_high = register_request_id_high_add.execute(0);
    }
    table table_register_request_id_high_interaction{
        key = { hdr.albion.request_id_low: exact; }
        actions = { action_register_request_id_high_add;
                    no_action; }
        const entries = {
            1  :  action_register_request_id_high_add();
        }
        const default_action = no_action();
        size = 2;
    }

    #define register_state(number) \
    Register<bit<32>,bit<32>>(20000,0) register_state_##number##; 	\	
	RegisterAction<bit<32>, bit<32>, bit<32>>(register_state_##number##) register_state_##number##_w = { \
        void apply(inout bit<32> value_r){ \
            value_r = 7;\
        } \
    };\
    RegisterAction<bit<32>, bit<32>, bit<32>>(register_state_##number##) register_state_##number##_r = { \
        void apply(inout bit<32> value_r, out bit<32> value_t){ \
            value_t = value_r;\
        } \
    };\
    RegisterAction<bit<32>, bit<32>, bit<32>>(register_state_##number##) register_state_##number##_sub = { \
        void apply(inout bit<32> value_r, out bit<32> value_t){ \
            value_r = value_r & meta.state_sub;\
            value_t = value_r;\
        } \
    };

    #define table_register_state_interaction(number) \
    action action_register_state_##number##_w(){ \
        register_state_##number##_w.execute(hdr.albion.time);\
    }\
    action action_register_state_##number##_r(){\
        meta.state = register_state_##number##_r.execute(hdr.albion.time);\
    }\
    action action_register_state_##number##_r_timer(){\
        hdr.albion_timer.state_##number## = register_state_##number##_r.execute(hdr.albion.time);\
    }\
    action action_register_state_##number##_sub(){\
        meta.state = register_state_##number##_sub.execute(hdr.albion.time);\
    }\
    table table_register_state_##number##_interaction{\
        key = { hdr.albion.operation: exact;\
                hdr.albion.num      : exact; }\
        actions = { action_register_state_##number##_w;\
                    action_register_state_##number##_r;\
                    action_register_state_##number##_r_timer;\
                    action_register_state_##number##_sub;\
                    no_action; }\
        const entries = {\
            (  1, ##number##):  action_register_state_##number##_r();\
            (  2, ##number##):  action_register_state_##number##_w();\
            ( 33, ##number##):  action_register_state_##number##_sub();\
            (100,          0):  action_register_state_##number##_r_timer();\
        }\
        const default_action = no_action();\
        size = 10;\
    }

    register_state(0)
    register_state(1)
    register_state(2)
    register_state(3)
    table_register_state_interaction(0)
    table_register_state_interaction(1)
    table_register_state_interaction(2)
    table_register_state_interaction(3)

    #define register_address_record(number) \
    Register<bit<32>,bit<32>>(14000,0) register_address_h_record_##number##; 	\	
	RegisterAction<bit<32>, bit<32>, bit<32>>(register_address_h_record_##number##) register_address_h_record_##number##_read = { \
        void apply(inout bit<32> value_r, out bit<32> read_value){ \
            read_value = value_r;\
        } \
    }; \
	RegisterAction<bit<32>, bit<32>, bit<32>>(register_address_h_record_##number##) register_address_h_record_##number##_write = { \
        void apply(inout bit<32> value_r){ \
            value_r = hdr.albion.address_h;\
        } \
    };\
    Register<bit<32>,bit<32>>(14000,##number##) register_address_l_record_##number##; 		\
	RegisterAction<bit<32>, bit<32>, bit<32>>(register_address_l_record_##number##) register_address_l_record_##number##_read = { \
        void apply(inout bit<32> value_r, out bit<32> read_value){ \
            read_value = value_r;\
        } \
    }; \
	RegisterAction<bit<32>, bit<32>, bit<32>>(register_address_l_record_##number##) register_address_l_record_##number##_write = { \
        void apply(inout bit<32> value_r){ \
            value_r = hdr.albion.address_l;\
        } \
    };

    #define table_register_address_record_interaction(number) \
    action action_register_address_h_record_##number##_read(){\
        hdr.albion.address_h = register_address_h_record_##number##_read.execute(hdr.albion.time);\
    }\
    action action_register_address_h_record_##number##_read_timer(){\
        hdr.albion_timer.address_high_##number## = register_address_h_record_##number##_read.execute(hdr.albion.time);\
    }\
    action action_register_address_h_record_##number##_write(){\
        register_address_h_record_##number##_write.execute(hdr.albion.time);\
    }\
    table table_register_address_h_record_##number##_interaction {\
        key = {\
            hdr.albion.operation: exact;\
            hdr.albion.num      : exact;\
        }\
        actions = {\
            no_action;\
            action_register_address_h_record_##number##_read;\
            action_register_address_h_record_##number##_write;\
            action_register_address_h_record_##number##_read_timer;\
        }\
        const entries = {\
            (  2,  ##number##): action_register_address_h_record_##number##_write();\
            (100,           0): action_register_address_h_record_##number##_read_timer();\
        }\
        const default_action = no_action();\
        size = 10;\
    }\
    action action_register_address_l_record_##number##_read(){\
        hdr.albion.address_l = register_address_l_record_##number##_read.execute(hdr.albion.time);\
    }\
    action action_register_address_l_record_##number##_read_timer(){\
        hdr.albion_timer.address_low_##number## = register_address_l_record_##number##_read.execute(hdr.albion.time);\
    }\
    action action_register_address_l_record_##number##_write(){\
        register_address_l_record_##number##_write.execute(hdr.albion.time);\
    }\
    table table_register_address_l_record_##number##_interaction {\
        key = {\
            hdr.albion.operation: exact;\
            hdr.albion.num      : exact;\
        }\
        actions = {\
            no_action;\
            action_register_address_l_record_##number##_read;\
            action_register_address_l_record_##number##_write;\
            action_register_address_l_record_##number##_read_timer;\
        }\
        const entries = {\
            (  2,  ##number##): action_register_address_l_record_##number##_write();\
            (100,           0): action_register_address_l_record_##number##_read_timer();\
        }\
        const default_action = no_action();\
        size = 10;\
    }

    register_address_record(0)
    register_address_record(1)
    register_address_record(2)
    register_address_record(3)
    table_register_address_record_interaction(0)
    table_register_address_record_interaction(1)
    table_register_address_record_interaction(2)
    table_register_address_record_interaction(3)

    action action_send_to_master(){
        ig_tm_md.ucast_egress_port = 136;
    }
    action action_send_to_client(){
        ig_tm_md.ucast_egress_port = 144;
    }
    action action_send_to_self(){
        ig_tm_md.ucast_egress_port = 196;
    }
    action action_send_to_CS_1(){
        ig_tm_md.ucast_egress_port = 56;
        hdr.albion.operation = 10;
        hdr.albion.port = 56;
    }
    action action_send_to_CS_2(){
        ig_tm_md.ucast_egress_port = 48;
        hdr.albion.operation = 10;
        hdr.albion.port = 48;
    }
    action action_send_to_CS_3(){
        ig_tm_md.ucast_egress_port = 40;
        hdr.albion.operation = 10;
        hdr.albion.port = 40;
    }
    action action_send_to_CS_4(){
        ig_tm_md.ucast_egress_port = 32;
        hdr.albion.operation = 10;
        hdr.albion.port = 32; 
    }
    action action_send_to_CS(){
        ig_tm_md.ucast_egress_port = 32;
    }
    table table_send_to_somewhere{
        key = { hdr.albion.operation: exact;
                hdr.albion.CS_id_1: exact; }
        actions = { action_send_to_master;
                    action_send_to_client;
                    action_send_to_self;
                    action_send_to_CS_1;
                    action_send_to_CS_2;
                    action_send_to_CS_3;
                    action_send_to_CS_4;
                    action_send_to_CS;
                    no_action; }
        const entries = {
            (  1,0)  :  action_send_to_master();//client过来的，需要发给master
            ( 20,0)  :  action_send_to_client();//未知
            ( 34,0)  :  action_send_to_client();//双成功
            ( 35,0)  :  action_send_to_client();//三成功
            (200,0)  :  action_send_to_master();//200就是退化了，实际上没处理
            (100,0)  :  action_send_to_self();//这是timer
            (101,0)  :  action_send_to_self();//这是timer，控制速度的
            (  2,1)  :  action_send_to_CS_1();//master过来的，发给cs1，op会被改成10
            (  2,2)  :  action_send_to_CS_2();//master过来的，发给cs2，op会被改成10
            (  2,3)  :  action_send_to_CS_3();//master过来的，发给cs3，op会被改成10
            (  2,4)  :  action_send_to_CS_4();//master过来的，发给cs4，op会被改成10
            ( 70,1)  :  action_send_to_CS_1();//master过来的，在retry
            ( 70,2)  :  action_send_to_CS_2();//master过来的，在retry
            ( 70,3)  :  action_send_to_CS_3();//master过来的，在retry
            ( 70,4)  :  action_send_to_CS_4();//master过来的，在retry
        }
        const default_action = no_action();
        size = 30;
    }

    action action_state_failed(){
        hdr.albion.operation = 200;
    }
    table table_state_check{
        key = { meta.state: exact; }
        actions = { action_state_failed;
                    no_action;}
        const entries = {
            0:no_action();
        }
        const default_action = action_state_failed();
        size = 10;
    }

    action action_op_change_to_34(){
        hdr.albion.operation = 34;
    }
    action action_op_change_to_35(){
        hdr.albion.operation = 35;
    }
    table table_success_check{
        key = { meta.state: exact; }
        actions = { action_op_change_to_34;
                    action_op_change_to_35;
                    no_action;}
        const entries = {
            1:action_op_change_to_34();
            2:action_op_change_to_34();
            4:action_op_change_to_34();
            0:action_op_change_to_35();
        }
        const default_action = no_action();
        size = 10;
    }

    apply {
        if(hdr.albion.isValid())
        {
            if(hdr.albion.operation == 1)
            {
                hdr.albion.request_id_low = register_request_id_low_add.execute(0);
                table_register_num_interaction.apply();
                table_register_timer_interaction.apply();
            }
            else if(hdr.albion.operation == 100)
            {
                table_register_num_interaction.apply();
                table_register_timer_interaction.apply();
            }
            else if(hdr.albion.operation == 30)
            {
                meta.state_sub = -2;
                hdr.albion.operation = 33;
                hdr.albion.CS_id_1 = 0;
            }
            else if(hdr.albion.operation == 31)
            {
                meta.state_sub = -3;
                hdr.albion.operation = 33;
                hdr.albion.CS_id_1 = 0;
            }
            else if(hdr.albion.operation == 32)
            {
                meta.state_sub = -5;
                hdr.albion.operation = 33;
                hdr.albion.CS_id_1 = 0;
            }

            table_register_state_0_interaction.apply();
            table_register_address_h_record_0_interaction.apply();
            table_register_address_l_record_0_interaction.apply();
            if(hdr.albion.operation == 1)
            {
                table_register_request_id_high_interaction.apply();
                hdr.albion.index = hdr.albion.time << 3;
                if(hdr.albion.num >= 8)
                {
                    hdr.albion.operation = 200;
                }
            }

            table_register_state_1_interaction.apply();
            table_register_address_h_record_1_interaction.apply();
            table_register_address_l_record_1_interaction.apply();
            if(hdr.albion.operation == 1)
            {
                hdr.albion.index = hdr.albion.index + hdr.albion.num;
            }
            

            table_register_state_2_interaction.apply();
            table_register_address_h_record_2_interaction.apply();
            table_register_address_l_record_2_interaction.apply();

            table_register_state_3_interaction.apply();
            table_register_address_h_record_3_interaction.apply();
            table_register_address_l_record_3_interaction.apply();


            if(hdr.albion.operation == 1)
            {
                table_state_check.apply();
            }
            if(hdr.albion.operation == 33)
            {
                table_success_check.apply();
            }

            table_send_to_somewhere.apply();
        }
    }
}

/*********************  D E P A R S E R  ************************/

control aIngressDeparser(packet_out pkt,
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

parser aEgressParser(packet_in      pkt,
    /* User */
    out headers          hdr,
    out my_egress_metadata_t         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    state start {
        pkt.extract(eg_intr_md);
        transition parse_pre;
    }
    
    state parse_pre {
        mirror_h mirror_md = pkt.lookahead<mirror_h>();
        transition select(mirror_md.pkt_type) {
			3          :  parse_mirror;
            default    :  parse_ethernet;
        }
    }
    
    state parse_mirror {
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
            100              :  parse_albion_timer;
            101              :  parse_albion_timer;
            default          :  parse_albion_data;
        }
    }

    state parse_albion_data {
        pkt.extract(hdr.albion_data);
		transition accept;
    }

    state parse_albion_timer {
        pkt.extract(hdr.albion_timer);
		transition accept;
    }
} 

    /***************** M A T C H - A C T I O N  *********************/

control aEgress(
    /* User */
    inout headers                          hdr,
    inout my_egress_metadata_t                         meta,
    /* Intrinsic */    
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{
    action action_send_to_master(){
        eg_dprsr_md.mirror_type = MIRROR_TYPE_MS;
        meta.session_id = 5;
        meta.no_use = 3;
    }
    action action_no_action(){
        hdr.albion_timer.times = hdr.albion_timer.const_time;
        hdr.albion.operation = 101;
    }
    table table_check_timer{
        key = { hdr.albion_timer.state_0: exact;
                hdr.albion_timer.state_1: exact;
                hdr.albion_timer.state_2: exact;
                hdr.albion_timer.state_3: exact;}
        actions = {  
            action_send_to_master; 
            action_no_action; 
        } 
        const entries = {  
            (0,0,0,0):    action_no_action(); 
		} 
        const default_action = action_send_to_master();
    }
    apply {
        if(hdr.mirror_1.isValid()){
            hdr.mirror_1.setInvalid();
        }
        else{
            if(hdr.albion.operation == 100)
            {
                table_check_timer.apply();
            }
            if(hdr.albion.operation == 101)
            {
                if(hdr.albion_timer.times == 0)
                {
                    hdr.albion.operation = 100;
                }
                else
                {
                    hdr.albion_timer.times = hdr.albion_timer.times - 1;
                }
            }
        }
    }
}

/*********************  D E P A R S E R  ************************/

control aEgressDeparser(packet_out pkt,
    /* User */
    inout headers                       hdr,
    in    my_egress_metadata_t                      meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

/************ F I N A L   P A C K A G E ******************************/
Pipeline(
    aIngressParser(),
    aIngress(),
    aIngressDeparser(),
    aEgressParser(),
    aEgress(),
    aEgressDeparser()
) pipe_a;

Switch(pipe_a) main;
