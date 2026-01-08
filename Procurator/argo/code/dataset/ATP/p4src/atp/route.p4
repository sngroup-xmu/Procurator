control Route(
        inout headers hdr,
        inout metadata meta,
        inout standard_metadata_t standard_metadata
        ){



    // Register<bit<32>, bit<12>>(4096,0) kk_count;
    // RegisterAction<bit<32>, bit<12>, bit<32>>(kk_count) kk_count_read = {
    //      void apply(inout bit<32> value, out bit<32> read_value) {
    //          value = value + 1;
    //          read_value = value;
    //      }
    // };

    //second
    action dmac_forward(bit<9> port,bit<48> dst_mac) {
        //ig_intr_md_for_tm.ucast_egress_port = port;
        standard_metadata.egress_spec = port;
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        hdr.ethernet.dst_addr = dst_mac;
        //kk_count_read.execute(0);
    }

    //first
    action dmac_forward_and_set_dataIndex(bit<9> port){
        //ig_intr_md_for_tm.ucast_egress_port = port;
        standard_metadata.egress_spec = port;
        //set resubmit flag 1,no use，because aggr once
        hdr.p4ml.dataIndex = 1;
    }

    // bit 1 disables copy-to-cpu 
	//action dmac_miss() {
	//	ig_intr_md_for_dprsr.drop_ctl = 3w1;
	//}

	table dmac {
		key = {
			hdr.p4ml.appIDandSeqNum: exact;

        	// standard_metadata.ingress_port: exact;
            //set resubmit flag 1,no use，because aggr once
        	// hdr.p4ml.dataIndex: exact;
            // only one PS 
            //hdr.p4ml.PSIndex: exact;
		}

		actions = {
			@defaultonly dmac_forward;
            dmac_forward_and_set_dataIndex;
            //dmac_miss;
		}

		//const default_action = dmac_miss();
		size = 64;
	}
    apply{
        dmac.apply();
    }
}

