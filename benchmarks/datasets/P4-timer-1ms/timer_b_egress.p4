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
    Register<bit<32>,bit<32>>(1000,0) register_data_record_##number##; \
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
		}
        const default_action = action_dst_cs_1();
        size = 4;
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
		}
        const default_action = action_dst_cs_1();
        size = 4;
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
                table_dst_cs_2.apply();
                meta.no_use = 2;
                eg_dprsr_md.mirror_type = MIRROR_TYPE_CS;
                hdr.albion.operation = 11;
            }
            else if(hdr.albion.operation == 10)
            {
                table_dst_cs_1.apply();
                meta.no_use = 1;
                eg_dprsr_md.mirror_type = MIRROR_TYPE_CS;
            }
            
            if(hdr.albion.operation == 10)
            {
                register_data_record_0_write.execute(hdr.albion.index);
            }
            else if(hdr.mirror_1.isValid())
            {
                hdr.mirror_1.setInvalid();
            }

            if(hdr.albion.operation == 10)
            {
                register_data_record_1_write.execute(hdr.albion.index);
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