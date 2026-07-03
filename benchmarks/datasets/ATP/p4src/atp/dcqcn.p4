/*  Egress -------------------------------*/
control Dcqcn(
        inout headers hdr2,
        inout metadata meta,
        inout standard_metadata_t standard_metadata){

    const bit<32> ecn_index =0;
    register<bit<32>>(1) ecn;
    bit<32> read_reg_ecn;

    //dqueue_threshold = 1000

    apply{
        ecn.read(read_reg_ecn,ecn_index);
        if(standard_metadata.deq_qdepth>1000){
            read_reg_ecn =6;
        }else{
            read_reg_ecn =0;
        }
        if(read_reg_ecn== 6){
            if(hdr2.ethernet.ether_type == 0x0800){
                hdr2.ipv4.diffserv =0b11;
            }
            if(hdr2.ethernet.ether_type == 0x0700){
                hdr2.p4ml.ECN = 1;
            }
        }
    }

}


