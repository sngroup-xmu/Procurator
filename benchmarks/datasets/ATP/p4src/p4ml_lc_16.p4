#include <core.p4>
#include <v1model.p4>


#include "atp/headers.p4"
#include "atp/struct.p4"
#include "atp/parser.p4"
#include "atp/dcqcn.p4"
#include "atp/atp.p4"
#include "atp/route.p4"
#include "atp/data.p4"
//-----------------------------------------------------------------------------
// Destination MAC lookup
// - Bridge out the packet of the interface in the MAC entry.
// - Flood the packet out of all ports within the ingress BD.
//-----------------------------------------------------------------------------

control MyIngress(
        inout headers hdr,
        inout metadata meta,
        inout standard_metadata_t standard_metadata
    ){

    action dmac_forward(bit<9> port) {
        standard_metadata.egress_spec = port;
    }

	action dmac_miss() {
		//ig_intr_md_for_dprsr.drop_ctl = 3w1;
	}

	table dmac {
		key = {
			hdr.ethernet.dst_addr : exact;
		}

		actions = {
			dmac_forward;
			@defaultonly dmac_miss;
		}

		const default_action = dmac_miss;
		size = 32;
	}

    AppIdSeq() appid_seq;

    apply{
        if(hdr.p4ml.isValid()){
                  //handle normal p4ml packets
                appid_seq.apply(hdr,  meta,standard_metadata);
        
        }else{
            // background traffic forward
            dmac.apply();
        }
	}

}

control MyEgress(
        inout headers hdr,
        inout metadata meta,
        inout standard_metadata_t standard_metadata) {

    Dcqcn() dcqcn;

	apply {
        dcqcn.apply(hdr, meta,standard_metadata);
    }

}


control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {}

}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);  
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.p4ml);
        packet.emit(hdr.p4ml_agtr_index);
        packet.emit(hdr.p4ml_entries);
    }
}

V1Switch(SwitchIngressParser(),
        MyVerifyChecksum(),
        MyIngress(),
        MyEgress(),
        MyComputeChecksum(),
        DeparserImpl()) main;



