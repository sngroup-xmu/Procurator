#include "data.p4"
#include "route.p4"


//use rv=1 replace source ATP : bit<16> meta.isMyAppIDandMyCurrentSeq = p4ml.
register<bit<32>>(total_aggregator_cnt) appID_and_Seq;
register<bit<32>>(total_aggregator_cnt) bitmap;
register<bit<8>>(total_aggregator_cnt) agtr_time;
//register index must be bit<32>
register<bit<32>>(total_aggregator_cnt) ecn_register;



control AtpAck(
        inout headers hdr,
        inout metadata meta,
        inout standard_metadata_t standard_metadata
        ){

	action multicast(bit<16> mgid ){
		standard_metadata.mcast_grp = mgid;
	}

	table multicast_table {
	    key ={
	        hdr.p4ml.isACK: exact;
			hdr.p4ml.appIDandSeqNum : ternary;
	    }
	    actions = {
	        multicast; 
	    }
		size=10;
	}

    apply{
        //overflow nop-op
        if(hdr.p4ml.overflow == 1 && hdr.p4ml.isResend == 0){
        
        }else{
            //compare:p4ml.appIDandSeqNum == appID_and_Seq(register) ,if equal,then agtr finish,and set all register=0
            //meta.isMyAppIDandMyCurrentSeq = clean_app_id_and_seq.execute(p4ml_agtr_index.agtr);
            appID_and_Seq.read(meta.read_reg_appID_and_Seq,(bit<32>)hdr.p4ml_agtr_index.agtr);
            if(meta.read_reg_appID_and_Seq == hdr.p4ml.appIDandSeqNum){
                appID_and_Seq.write((bit<32>)hdr.p4ml_agtr_index.agtr,0);
                meta.isMyAppIDandMyCurrentSeq = 1;
            }
            
            //set bitmap register =0,ecn register = 0,agtr_time register = 0;
            if (meta.isMyAppIDandMyCurrentSeq != 0) {
                /* Clean */
                bitmap.write((bit<32>)hdr.p4ml_agtr_index.agtr,0);
                ecn_register.write((bit<32>)hdr.p4ml_agtr_index.agtr,0);
                agtr_time.write((bit<32>)hdr.p4ml_agtr_index.agtr,0);
            }
        }
        //multicast ack pkt
        //if(ig_intr_md.resubmit_flag == 1){
		multicast_table.apply();
        //}else {
            // not realize
        //    p4ml_resubmit_table.apply();
        //}
    }
}

control AppIdSeq(
        inout headers hdr,
        // inout p4ml_h p4ml,
        // inout entry_h p4ml_entries,
        // in p4ml_agtr_index_h p4ml_agtr_index,
        inout metadata meta,
        inout standard_metadata_t standard_metadata
    ){
    action setup_ecn_action(){
        meta.is_ecn = 1;
    }
    action check_aggregate_and_forward() {
        // this is is for aggregation needed checking
        //bit_andcb(meta.isAggregate, p4ml.bitmap, meta.bitmap);
        // meta.isAggregate=0 mean has already aggregated
        meta.isAggregate = hdr.p4ml.bitmap & ~meta.bitmap;         
        meta.integrated_bitmap = hdr.p4ml.bitmap | meta.bitmap;                                                   
    }

    action tag_collision_incoming() {
        hdr.p4ml.isSWCollision = 1; 
    }

	action drop_pkt(){
		//ig_intr_md_for_dprsr.drop_ctl = 3w1;
        mark_to_drop(standard_metadata);
	}



    ProcessData0() process_data0;
    ProcessData1() process_data1;
    ProcessData2() process_data2;
    ProcessData3() process_data3;
    //ProcessData4() process_data4;
    //ProcessData5() process_data5;
    //ProcessData6() process_data6;
    //ProcessData7() process_data7;
    //ProcessData8() process_data8;
    //ProcessData9() process_data9;
    //ProcessData10() process_data10;
    //ProcessData11() process_data11;
    //ProcessData12() process_data12;
    //ProcessData13() process_data13;
    //ProcessData14() process_data14;
    //ProcessData15() process_data15;
    //ProcessData16() process_data16;
    //ProcessData17() process_data17;
    //ProcessData18() process_data18;
    //ProcessData19() process_data19;
    //ProcessData20() process_data20;
    //ProcessData21() process_data21;
    //ProcessData22() process_data22;
    //ProcessData23() process_data23;
    //ProcessData24() process_data24;
    //ProcessData25() process_data25;
    //ProcessData26() process_data26; 
    //ProcessData27() process_data27;
    //ProcessData28() process_data28;
    //ProcessData29() process_data29;
    //ProcessData30() process_data30;

    AtpAck() atp_ack;
    Route() route;
    

    apply{
        /*****Ecn doesn't pay attention for the time being************/
        if (hdr.ipv4.diffserv == 0b11 || hdr.p4ml.ECN == 1) {
           setup_ecn_action();
        }
        //agg.app_seq_id == pkt.app_seq_id->deallocate allocator
        if(hdr.p4ml.isACK == 1){
            atp_ack.apply(hdr,meta,standard_metadata);
        }else{
            if(hdr.p4ml.overflow == 1){
                route.apply(hdr,meta,standard_metadata);
            }else{
                //if resend pkt,then take register info to ps,set reg =0
                if(hdr.p4ml.isResend == 1){
                    appID_and_Seq.read(meta.read_reg_appID_and_Seq,(bit<32>)hdr.p4ml_agtr_index.agtr);
                    if(meta.read_reg_appID_and_Seq == hdr.p4ml.appIDandSeqNum){
                        appID_and_Seq.write((bit<32>)hdr.p4ml_agtr_index.agtr,0);
                        meta.isMyAppIDandMyCurrentSeq = 1;

                    }else{
                        meta.isMyAppIDandMyCurrentSeq = 0;
                    }
                    //meta.isMyAppIDandMyCurrentSeq = resend_check_app_id_and_seq.execute(p4ml_agtr_index.agtr);
                }else{
                    appID_and_Seq.read(meta.read_reg_appID_and_Seq,(bit<32>)hdr.p4ml_agtr_index.agtr);
                    if(meta.read_reg_appID_and_Seq == hdr.p4ml.appIDandSeqNum || meta.read_reg_appID_and_Seq == 0){
                        appID_and_Seq.write((bit<32>)hdr.p4ml_agtr_index.agtr,hdr.p4ml.appIDandSeqNum);
                        meta.isMyAppIDandMyCurrentSeq = 1;
                    }else{
                        meta.isMyAppIDandMyCurrentSeq = 0;
                    }
                    //meta.isMyAppIDandMyCurrentSeq = normal_check_app_id_and_seq.execute(p4ml_agtr_index.agtr);
                }
                //agg.app_seq_id == pkt.app_seq_id || agg is empty
                if(meta.isMyAppIDandMyCurrentSeq == 1){
                    bitmap.read(meta.read_reg_bitmap,(bit<32>)hdr.p4ml_agtr_index.agtr);

                    //determine whether worker has been aggregated;
                    // meta.isAggregate = p4ml.bitmap & ~meta.bitmap;         
                    //meta.integrated_bitmap =  p4ml.bitmap | meta.bitmap; 
                    check_aggregate_and_forward();
                    if(hdr.p4ml.isResend == 1){
                        //if resend pkt,then take register info to ps,set reg =0
                        //meta.bitmap = resend_read_write_bitmap.execute(p4ml_agtr_index.agtr); 
                        bitmap.write((bit<32>)hdr.p4ml_agtr_index.agtr,0);
                        bitmap.read(meta.bitmap,(bit<32>)hdr.p4ml_agtr_index.agtr);
                    }else{
                        //store aggregated worker to register
                        //meta.bitmap = normal_read_write_bitmap.execute(p4ml_agtr_index.agtr);
                        meta.tmp_reg_bitmap = meta.read_reg_bitmap | hdr.p4ml.bitmap;
                        bitmap.write((bit<32>)hdr.p4ml_agtr_index.agtr,meta.tmp_reg_bitmap);
                        bitmap.read(meta.bitmap,(bit<32>)hdr.p4ml_agtr_index.agtr);
                        
                    }
                    /*****暂时不考虑ECN 的逻辑************/
                    //p4ml.ECN = update_ecn_bit.execute(p4ml_agtr_index.agtr);

                    if(hdr.p4ml.isResend == 1){

                        //clean the agrt_time
                        //meta.agtr_time = resend_check_agtr_time.execute(p4ml_agtr_index.agtr);
                        agtr_time.write((bit<32>)hdr.p4ml_agtr_index.agtr,0);
                        meta.agtr_time = hdr.p4ml.agtr_time;
                    }else{
                        //meta.agtr_time = normal_check_agtr_time.execute(p4ml_agtr_index.agtr);
                        if(meta.isAggregate != 0){
                            agtr_time.read(meta.read_reg_agtr_time,(bit<32>)hdr.p4ml_agtr_index.agtr);
                            meta.tmp_reg_agtr_time = meta.read_reg_agtr_time + 1;
                            agtr_time.write((bit<32>)hdr.p4ml_agtr_index.agtr,meta.tmp_reg_agtr_time);
                            agtr_time.read(meta.agtr_time,(bit<32>)hdr.p4ml_agtr_index.agtr);
                        }
                    }
                    PROCESS_ENTRY
                    if(meta.isAggregate != 0){
                        if (meta.need_send_out == 1){                                                                          
                            route.apply(hdr,meta,standard_metadata);                                                  
                        } else{                                                                                                 
                            drop_pkt();                                                                                         
                        }
                    }                                                                                                       
                }else{
                    /* tag collision bit in incoming one */
                    // if not empty   
                    if (hdr.p4ml.isResend == 0) {
                        tag_collision_incoming();
                    }
                    route.apply(hdr,meta,standard_metadata);
                }
            }
        }
    }
}
