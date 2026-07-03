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
            if(value_r == 17500)
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
    Register<bit<8>,bit<32>>(20000,0) register_state_##number##; 	\	
	RegisterAction<bit<8>, bit<32>, bit<8>>(register_state_##number##) register_state_##number##_w = { \
        void apply(inout bit<8> value_r){ \
            value_r = 7;\
        } \
    };\
    RegisterAction<bit<8>, bit<32>, bit<8>>(register_state_##number##) register_state_##number##_r = { \
        void apply(inout bit<8> value_r, out bit<8> value_t){ \
            value_t = value_r;\
        } \
    };\
    RegisterAction<bit<8>, bit<32>, bit<8>>(register_state_##number##) register_state_##number##_sub = { \
        void apply(inout bit<8> value_r, out bit<8> value_t){ \
            value_r = value_r - meta.state_sub;\
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
    register_state(4)
    register_state(5)
    register_state(6)
    register_state(7)
    table_register_state_interaction(0)
    table_register_state_interaction(1)
    table_register_state_interaction(2)
    table_register_state_interaction(3)
    table_register_state_interaction(4)
    table_register_state_interaction(5)
    table_register_state_interaction(6)
    table_register_state_interaction(7)

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
    register_address_record(4)
    register_address_record(5)
    register_address_record(6)
    register_address_record(7)
    table_register_address_record_interaction(0)
    table_register_address_record_interaction(1)
    table_register_address_record_interaction(2)
    table_register_address_record_interaction(3)
    table_register_address_record_interaction(4)
    table_register_address_record_interaction(5)
    table_register_address_record_interaction(6)
    table_register_address_record_interaction(7)

    action action_send_to_master(){
        ig_tm_md.ucast_egress_port = 136;
    }
    action action_send_to_user(){ 
        ig_tm_md.ucast_egress_port = 144;
    }
    action action_send_to_self(){
        ig_tm_md.ucast_egress_port = 196;
    }
    action action_send_to_CS_1(){
        ig_tm_md.ucast_egress_port = 56;
        hdr.albion.operation = 10;
    }
    action action_send_to_CS_2(){
        ig_tm_md.ucast_egress_port = 48;
        hdr.albion.operation = 10;
    }
    action action_send_to_CS_3(){
        ig_tm_md.ucast_egress_port = 40;
        hdr.albion.operation = 10;
    }
    action action_send_to_CS_4(){
        ig_tm_md.ucast_egress_port = 32;
        hdr.albion.operation = 10;
    }
    table table_send_to_somewhere{
        key = { hdr.albion.operation: exact;
                hdr.albion.CS_id_1: exact; }
        actions = { action_send_to_master;
                    action_send_to_user;
                    action_send_to_self;
                    action_send_to_CS_1;
                    action_send_to_CS_2;
                    action_send_to_CS_3;
                    action_send_to_CS_4;
                    no_action; }
        const entries = {
            (  1,0)  :  action_send_to_master();
            ( 20,0)  :  action_send_to_user();
            (200,0)  :  action_send_to_master();
            (100,0)  :  action_send_to_self();
            (101,0)  :  action_send_to_self();
            (  2,1)  :  action_send_to_CS_1();
            (  2,2)  :  action_send_to_CS_2();
            (  2,3)  :  action_send_to_CS_3();
            (  2,4)  :  action_send_to_CS_4();
        }
        const default_action = no_action();
        size = 10;
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
            else if(hdr.albion.operation == 20)
            {
                meta.state_sub = 7;
            }
            else if(hdr.albion.operation == 30)
            {
                meta.state_sub = 1;
                hdr.albion.operation = 33;
            }
            else if(hdr.albion.operation == 31)
            {
                meta.state_sub = 2;
                hdr.albion.operation = 33;
            }
            else if(hdr.albion.operation == 32)
            {
                meta.state_sub = 4;
                hdr.albion.operation = 33;
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

            table_register_state_4_interaction.apply();
            table_register_address_h_record_4_interaction.apply();
            table_register_address_l_record_4_interaction.apply();

            table_register_state_5_interaction.apply();
            table_register_address_h_record_5_interaction.apply();
            table_register_address_l_record_5_interaction.apply();

            table_register_state_6_interaction.apply();
            table_register_address_h_record_6_interaction.apply();
            table_register_address_l_record_6_interaction.apply();

            table_register_state_7_interaction.apply();
            table_register_address_h_record_7_interaction.apply();
            table_register_address_l_record_7_interaction.apply();


            if(hdr.albion.operation == 1)
            {
                table_state_check.apply();
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