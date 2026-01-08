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
            //ig_tm_md.ucast_egress_port = 144;
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