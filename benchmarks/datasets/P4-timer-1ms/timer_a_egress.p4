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
                hdr.albion_timer.state_3: exact;
                hdr.albion_timer.state_4: exact;
                hdr.albion_timer.state_5: exact;
                hdr.albion_timer.state_6: exact;
                hdr.albion_timer.state_7: exact;
                hdr.albion_timer.state_8: exact;
                hdr.albion_timer.state_9: exact;}
        actions = {  
            action_send_to_master; 
            action_no_action; 
        } 
        const entries = {  
            (0,0,0,0,0,0,0,0,0,0):    action_no_action(); 
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
    Mirror() mirror_1;
    
    apply {
        if(eg_dprsr_md.mirror_type == MIRROR_TYPE_MS){
            mirror_1.emit<mirror_h>(meta.session_id, {meta.no_use});
        }
        pkt.emit(hdr);
    }
}