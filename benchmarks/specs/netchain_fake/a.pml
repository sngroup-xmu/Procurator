s1_standard_metadata_t s1_standard_metadata;
s1_metadata s1_meta;
bool emit_s1_hdr_ethernet = false;
bool emit_s1_hdr_ipv4 = false;
bool emit_s1_hdr_nc_hdr = false;
bool emit_s1_hdr_tcp = false;
bool emit_s1_hdr_udp = false;
bool emit_s1_hdr_overlay = false;
s1_headers s1_hdr;

// Table s1_ethernet_set_mac_0 Actionlist Declaration
int s1_ethernet_set_mac_0_s1_ethernet_set_mac_act_s1_smac;
int s1_ethernet_set_mac_0_s1_ethernet_set_mac_act_s1_dmac;
#define s1_ethernet_set_mac_0_action_s1_ethernet_set_mac_act 1
#define s1_ethernet_set_mac_0_action_s1_NoAction_0 0
int s1_ethernet_set_mac_0_action_run;
bool s1_ethernet_set_mac_0_hit;

// Register s1_sequence_reg_0
short s1_sequence_reg_0[4096];

// Register s1_value_reg_0
int s1_value_reg_0[4096];

// Table s1_assign_value_0 Actionlist Declaration
#define s1_assign_value_0_action_s1_assign_value_act 1
#define s1_assign_value_0_action_s1_NoAction_1 0
int s1_assign_value_0_action_run;
bool s1_assign_value_0_hit;

// Table s1_drop_packet_0 Actionlist Declaration
#define s1_drop_packet_0_action_s1_drop_packet_act 1
#define s1_drop_packet_0_action_s1_NoAction_16 0
int s1_drop_packet_0_action_run;
bool s1_drop_packet_0_hit;

// Table s1_failure_recovery_0 Actionlist Declaration
int s1_failure_recovery_0_s1_failure_recovery_act_s1_nexthop;
#define s1_failure_recovery_0_action_s1_failover_act 5
#define s1_failure_recovery_0_action_s1_failover_write_reply_act 4
#define s1_failure_recovery_0_action_s1_failure_recovery_act 3
#define s1_failure_recovery_0_action_s1_nop 2
#define s1_failure_recovery_0_action_s1_drop_packet_act_2 1
#define s1_failure_recovery_0_action_s1_NoAction_17 0
int s1_failure_recovery_0_action_run;
bool s1_failure_recovery_0_hit;

// Table s1_find_index_0 Actionlist Declaration
short s1_find_index_0_s1_find_index_act_s1_index;
#define s1_find_index_0_action_s1_find_index_act 1
#define s1_find_index_0_action_s1_NoAction_18 0
int s1_find_index_0_action_run;
bool s1_find_index_0_hit;

// Table s1_gen_reply_0 Actionlist Declaration
byte s1_gen_reply_0_s1_gen_reply_act_s1_message_type;
#define s1_gen_reply_0_action_s1_gen_reply_act 1
#define s1_gen_reply_0_action_s1_NoAction_19 0
int s1_gen_reply_0_action_run;
bool s1_gen_reply_0_hit;

// Table s1_get_my_address_0 Actionlist Declaration
int s1_get_my_address_0_s1_get_my_address_act_s1_sw_ip;
short s1_get_my_address_0_s1_get_my_address_act_s1_sw_role;
#define s1_get_my_address_0_action_s1_get_my_address_act 1
#define s1_get_my_address_0_action_s1_NoAction_20 0
int s1_get_my_address_0_action_run;
bool s1_get_my_address_0_hit;

// Table s1_get_next_hop_0 Actionlist Declaration
#define s1_get_next_hop_0_action_s1_get_next_hop_act 1
#define s1_get_next_hop_0_action_s1_NoAction_21 0
int s1_get_next_hop_0_action_run;
bool s1_get_next_hop_0_hit;

// Table s1_get_sequence_0 Actionlist Declaration
#define s1_get_sequence_0_action_s1_get_sequence_act 1
#define s1_get_sequence_0_action_s1_NoAction_22 0
int s1_get_sequence_0_action_run;
bool s1_get_sequence_0_hit;

// Table s1_ipv4_route_0 Actionlist Declaration
short s1_ipv4_route_0_s1_set_egress_s1_egress_spec;
#define s1_ipv4_route_0_action_s1_set_egress 1
#define s1_ipv4_route_0_action_s1_NoAction_23 0
int s1_ipv4_route_0_action_run;
bool s1_ipv4_route_0_hit;

// Table s1_maintain_sequence_0 Actionlist Declaration
#define s1_maintain_sequence_0_action_s1_maintain_sequence_act 1
#define s1_maintain_sequence_0_action_s1_NoAction_24 0
int s1_maintain_sequence_0_action_run;
bool s1_maintain_sequence_0_hit;

// Table s1_pop_chain_0 Actionlist Declaration
#define s1_pop_chain_0_action_s1_pop_chain_act 1
#define s1_pop_chain_0_action_s1_NoAction_25 0
int s1_pop_chain_0_action_run;
bool s1_pop_chain_0_hit;

// Table s1_pop_chain_again_0 Actionlist Declaration
#define s1_pop_chain_again_0_action_s1_pop_chain_act_2 1
#define s1_pop_chain_again_0_action_s1_NoAction_26 0
int s1_pop_chain_again_0_action_run;
bool s1_pop_chain_again_0_hit;

// Table s1_read_value_0 Actionlist Declaration
#define s1_read_value_0_action_s1_read_value_act 1
#define s1_read_value_0_action_s1_NoAction_27 0
int s1_read_value_0_action_run;
bool s1_read_value_0_hit;
inline s1_accept()
{
    s1_packet_extract_accept = true;
}

//Parser State s1_parse_nc_hdr
inline s1_parse_nc_hdr()
{
    s1_hdr.nc_hdr.valid = true;
    if
    :: s1_hdr.nc_hdr.op == 10 -> 
        s1_accept();
    :: s1_hdr.nc_hdr.op == 12 -> 
        s1_accept();
    :: else ->
        s1_accept();
    fi
}

//Parser State s1_parse_overlay_7
inline s1_parse_overlay_7()
{
    s1_hdr.overlay.last = s1_hdr.overlay.last + 1;
    s1_hdr.overlay.element_7.valid = true;
    if
    :: s1_hdr.overlay.element_7.swip == 0 -> 
        s1_parse_nc_hdr();
    :: else ->
        s1_accept();
    fi
}

//Parser State s1_parse_overlay_6
inline s1_parse_overlay_6()
{
    s1_hdr.overlay.last = s1_hdr.overlay.last + 1;
    s1_hdr.overlay.element_6.valid = true;
    if
    :: s1_hdr.overlay.element_6.swip == 0 -> 
        s1_parse_nc_hdr();
    :: else ->
        s1_parse_overlay_7();
    fi
}

//Parser State s1_parse_overlay_5
inline s1_parse_overlay_5()
{
    s1_hdr.overlay.last = s1_hdr.overlay.last + 1;
    s1_hdr.overlay.element_5.valid = true;
    if
    :: s1_hdr.overlay.element_5.swip == 0 -> 
        s1_parse_nc_hdr();
    :: else ->
        s1_parse_overlay_6();
    fi
}

//Parser State s1_parse_overlay_4
inline s1_parse_overlay_4()
{
    s1_hdr.overlay.last = s1_hdr.overlay.last + 1;
    s1_hdr.overlay.element_4.valid = true;
    if
    :: s1_hdr.overlay.element_4.swip == 0 -> 
        s1_parse_nc_hdr();
    :: else ->
        s1_parse_overlay_5();
    fi
}

//Parser State s1_parse_overlay_3
inline s1_parse_overlay_3()
{
    s1_hdr.overlay.last = s1_hdr.overlay.last + 1;
    s1_hdr.overlay.element_3.valid = true;
    if
    :: s1_hdr.overlay.element_3.swip == 0 -> 
        s1_parse_nc_hdr();
    :: else ->
        s1_parse_overlay_4();
    fi
}

//Parser State s1_parse_overlay_2
inline s1_parse_overlay_2()
{
    s1_hdr.overlay.last = s1_hdr.overlay.last + 1;
    s1_hdr.overlay.element_2.valid = true;
    if
    :: s1_hdr.overlay.element_2.swip == 0 -> 
        s1_parse_nc_hdr();
    :: else ->
        s1_parse_overlay_3();
    fi
}

//Parser State s1_parse_overlay_1
inline s1_parse_overlay_1()
{
    s1_hdr.overlay.last = s1_hdr.overlay.last + 1;
    s1_hdr.overlay.element_1.valid = true;
    if
    :: s1_hdr.overlay.element_1.swip == 0 -> 
        s1_parse_nc_hdr();
    :: else ->
        s1_parse_overlay_2();
    fi
}

//Parser State s1_parse_overlay
inline s1_parse_overlay()
{
    s1_hdr.overlay.last = s1_hdr.overlay.last + 1;
    s1_hdr.overlay.element_0.valid = true;
    if
    :: s1_hdr.overlay.element_0.swip == 0 -> 
        s1_parse_nc_hdr();
    :: else ->
        s1_parse_overlay_1();
    fi
}

//Parser State s1_parse_udp
inline s1_parse_udp()
{
    s1_hdr.udp.valid = true;
    s1_hdr.udp.dstPort = 8888;
    if
    :: s1_hdr.udp.dstPort == 8888 -> 
        s1_parse_overlay();
    :: s1_hdr.udp.dstPort == 8889 -> 
        s1_parse_overlay();
    :: else ->
        s1_accept();
    fi
}

//Parser State s1_parse_tcp
inline s1_parse_tcp()
{
    s1_hdr.tcp.valid = true;
    s1_accept();
}

//Parser State s1_parse_ipv4
inline s1_parse_ipv4()
{
    s1_hdr.ipv4.valid = true;
    s1_hdr.ipv4.protocol = 17;
    if
    :: s1_hdr.ipv4.protocol == 6 -> 
        s1_parse_tcp();
    :: s1_hdr.ipv4.protocol == 17 -> 
        s1_parse_udp();
    :: else ->
        s1_accept();
    fi
}
inline reset_struct_s1_overlay_t(s1)
{
    s1.valid = 0;
    s1.swip = 0;
}

// Action s1_NoAction_0
inline s1_NoAction_0()
{
    skip;
}

// Action s1_ethernet_set_mac_act
inline s1_ethernet_set_mac_act(s1_smac, s1_dmac)
{
    s1_hdr.ethernet.srcAddr = s1_smac;
    s1_hdr.ethernet.dstAddr = s1_dmac;
}

// Action s1_NoAction_23
inline s1_NoAction_23()
{
    skip;
}

// Action s1_set_egress
inline s1_set_egress(s1_egress_spec)
{
    s1_standard_metadata.egress_spec = s1_egress_spec;
    s1_standard_metadata.egress_port = s1_egress_spec;
    s1__forward = true;
    s1_hdr.ipv4.ttl = (s1_hdr.ipv4.ttl + 255);
}

// Action s1_get_next_hop_act
inline s1_get_next_hop_act()
{
    s1_hdr.ipv4.dstAddr = s1_hdr.overlay.element_0.swip;
}

// Action s1_NoAction_19
inline s1_NoAction_19()
{
    skip;
}

// Action s1_gen_reply_act
inline s1_gen_reply_act(s1_message_type)
{
    s1_meta.reply_to_client_md.ipv4_srcAddr = s1_hdr.ipv4.dstAddr;
    s1_meta.reply_to_client_md.ipv4_dstAddr = s1_hdr.ipv4.srcAddr;
    s1_hdr.ipv4.srcAddr = s1_meta.reply_to_client_md.ipv4_srcAddr;
    s1_hdr.ipv4.dstAddr = s1_meta.reply_to_client_md.ipv4_dstAddr;
    s1_hdr.nc_hdr.op = s1_message_type;
    s1_hdr.udp.dstPort = 8889;
}

// Action s1_NoAction_26
inline s1_NoAction_26()
{
    skip;
}

// Action s1_NoAction_18
inline s1_NoAction_18()
{
    skip;
}

// Action s1_find_index_act
inline s1_find_index_act(s1_index)
{
    s1_meta.location.index = s1_index;
}

// Action s1_get_my_address_act
inline s1_get_my_address_act(s1_sw_ip, s1_sw_role)
{
    s1_meta.my_md.ipaddress = s1_sw_ip;
    s1_meta.my_md.role = s1_sw_role;
}

//Parser State s1_parse_ethernet
inline s1_parse_ethernet()
{
    s1_hdr.ethernet.valid = true;
    if
    :: s1_hdr.ethernet.etherType == 2048 -> 
        s1_parse_ipv4();
    :: else ->
        s1_accept();
    fi
}
inline reset_struct_s1_overlay_t_hs(s1){
    reset_struct_s1_overlay_t(s1.element_0);
    reset_struct_s1_overlay_t(s1.element_1);
    reset_struct_s1_overlay_t(s1.element_2);
    reset_struct_s1_overlay_t(s1.element_3);
    reset_struct_s1_overlay_t(s1.element_4);
    reset_struct_s1_overlay_t(s1.element_5);
    reset_struct_s1_overlay_t(s1.element_6);
    reset_struct_s1_overlay_t(s1.element_7);
}
inline reset_struct_s1_udp_t(s1)
{
    s1.valid = 0;
    s1.srcPort = 0;
    s1.dstPort = 0;
    s1._len = 0;
    s1.checksum = 0;
}
inline reset_struct_s1_tcp_t(s1)
{
    s1.valid = 0;
    s1.srcPort = 0;
    s1.dstPort = 0;
    s1.seqNo = 0;
    s1.ackNo = 0;
    s1.dataOffset = 0;
    s1.res = 0;
    s1.ecn = 0;
    s1.ctrl = 0;
    s1.window = 0;
    s1.checksum = 0;
    s1.urgentPtr = 0;
}
inline reset_struct_s1_nc_hdr_t(s1)
{
    s1.valid = 0;
    s1.op = 0;
    s1.sc = 0;
    s1.seq = 0;
    s1.key = 0;
    s1.value = 0;
    s1.vgroup = 0;
}
inline reset_struct_s1_ipv4_t(s1)
{
    s1.valid = 0;
    s1.version = 0;
    s1.ihl = 0;
    s1.diffserv = 0;
    s1.totalLen = 0;
    s1.identification = 0;
    s1.flags = 0;
    s1.fragOffset = 0;
    s1.ttl = 0;
    s1.protocol = 0;
    s1.hdrChecksum = 0;
    s1.srcAddr = 0;
    s1.dstAddr = 0;
}
inline reset_struct_s1_ethernet_t(s1)
{
    s1.valid = 0;
    s1.dstAddr = 0;
    s1.srcAddr = 0;
    s1.etherType = 0;
}

// Table s1_ethernet_set_mac_0
inline s1_ethernet_set_mac_0_apply()
{
    s1_standard_metadata.egress_port = s1_standard_metadata.egress_port;
    if
    :: (s1_standard_metadata.egress_port == 1) ->
        s1_ethernet_set_mac_act(187723572702737, 187723572702787);
    :: (s1_standard_metadata.egress_port == 2) ->
        s1_ethernet_set_mac_act(187723572702738, 187723572702754);
    :: else -> 
        s1_NoAction_0();
    fi
}

// Table s1_ipv4_route_0
inline s1_ipv4_route_0_apply()
{
    s1_hdr.ipv4.dstAddr = s1_hdr.ipv4.dstAddr;
    if
    :: (s1_hdr.ipv4.dstAddr == 167772161) ->
        s1_set_egress(1);
    :: (s1_hdr.ipv4.dstAddr == 167772162) ->
        s1_set_egress(1);
    :: (s1_hdr.ipv4.dstAddr == 167797762) ->
        s1_set_egress(2);
    :: (s1_hdr.ipv4.dstAddr == 167797763) ->
        s1_set_egress(1);
    :: (s1_hdr.ipv4.dstAddr == 167797764) ->
        s1_set_egress(1);
    :: else -> 
        s1_NoAction_23();
    fi
}

// Table s1_failure_recovery_0
inline s1_failure_recovery_0_apply()
{
    s1_hdr.ipv4.dstAddr = s1_hdr.ipv4.dstAddr;
    s1_hdr.overlay.element_1.swip = s1_hdr.overlay.element_1.swip;
    s1_hdr.nc_hdr.vgroup = s1_hdr.nc_hdr.vgroup;
    if
    :: else -> 
        s1_nop();
    fi
}

// Table s1_get_next_hop_0
inline s1_get_next_hop_0_apply()
{
    if
    :: else -> 
        s1_get_next_hop_act();
    fi
}

// Table s1_gen_reply_0
inline s1_gen_reply_0_apply()
{
    s1_hdr.nc_hdr.op = s1_hdr.nc_hdr.op;
    if
    :: (s1_hdr.nc_hdr.op == 10) ->
        s1_gen_reply_act(11);
    :: (s1_hdr.nc_hdr.op == 12) ->
        s1_gen_reply_act(13);
    :: else -> 
        s1_NoAction_19();
    fi
}

// Table s1_pop_chain_again_0
inline s1_pop_chain_again_0_apply()
{
    if
    :: else -> 
        s1_NoAction_26();
    fi
}

// Table s1_drop_packet_0
inline s1_drop_packet_0_apply()
{
    if
    :: else -> 
        s1_drop_packet_act();
    fi
}

// Table s1_pop_chain_0
inline s1_pop_chain_0_apply()
{
    if
    :: else -> 
        s1_pop_chain_act();
    fi
}

// Table s1_assign_value_0
inline s1_assign_value_0_apply()
{
    if
    :: else -> 
        s1_assign_value_act();
    fi
}

// Table s1_maintain_sequence_0
inline s1_maintain_sequence_0_apply()
{
    if
    :: else -> 
        s1_maintain_sequence_act();
    fi
}

// Table s1_read_value_0
inline s1_read_value_0_apply()
{
    if
    :: else -> 
        s1_read_value_act();
    fi
}

// Table s1_get_sequence_0
inline s1_get_sequence_0_apply()
{
    if
    :: else -> 
        s1_get_sequence_act();
    fi
}

// Table s1_find_index_0
inline s1_find_index_0_apply()
{
    s1_hdr.nc_hdr.key = s1_hdr.nc_hdr.key;
    if
    :: (s1_hdr.nc_hdr.key == 2024) ->
        s1_find_index_act(0);
    :: (s1_hdr.nc_hdr.key == 2025) ->
        s1_find_index_act(1);
    :: (s1_hdr.nc_hdr.key == 2026) ->
        s1_find_index_act(2);
    :: (s1_hdr.nc_hdr.key == 2027) ->
        s1_find_index_act(3);
    :: (s1_hdr.nc_hdr.key == 2028) ->
        s1_find_index_act(4);
    :: else -> 
        s1_NoAction_18();
    fi
}

// Table s1_get_my_address_0
inline s1_get_my_address_0_apply()
{
    s1_hdr.nc_hdr.key = s1_hdr.nc_hdr.key;
    if
    :: else -> 
        s1_get_my_address_act(167797761, 100);
    fi
}

//Parser State s1_start
inline s1_start()
{
    s1_parse_ethernet();
}
inline assign_struct_s1_overlay_t(s1, s2)
{
    s1.valid = s2.valid;
    s1.swip = s2.swip;
}
inline s1_pml_send_packet()
{
    if
    :: s1_standard_metadata.egress_port == 1 ->
        s2 ! s1_hdr
    :: else -> skip;
    fi
}
inline s1_handle_header_emit(){
    if
    :: !emit_s1_hdr_ethernet ->
        reset_struct_s1_ethernet_t(s1_hdr.ethernet);
    :: else -> skip;
    fi
    if
    :: !emit_s1_hdr_ipv4 ->
        reset_struct_s1_ipv4_t(s1_hdr.ipv4);
    :: else -> skip;
    fi
    if
    :: !emit_s1_hdr_nc_hdr ->
        reset_struct_s1_nc_hdr_t(s1_hdr.nc_hdr);
    :: else -> skip;
    fi
    if
    :: !emit_s1_hdr_tcp ->
        reset_struct_s1_tcp_t(s1_hdr.tcp);
    :: else -> skip;
    fi
    if
    :: !emit_s1_hdr_udp ->
        reset_struct_s1_udp_t(s1_hdr.udp);
    :: else -> skip;
    fi
    if
    :: !emit_s1_hdr_overlay ->
        reset_struct_s1_overlay_t_hs(s1_hdr.overlay);
    :: else -> skip;
    fi
}

// Control s1_DeparserImpl
inline s1_DeparserImpl()
{
    emit_s1_hdr_ethernet = true;
    emit_s1_hdr_ipv4 = true;
    emit_s1_hdr_udp = true;
    emit_s1_hdr_overlay = true;
    emit_s1_hdr_nc_hdr = true;
    emit_s1_hdr_tcp = true;
}
inline s1_reset_emit_flag(){
    emit_s1_hdr_ethernet = false;
    emit_s1_hdr_ipv4 = false;
    emit_s1_hdr_nc_hdr = false;
    emit_s1_hdr_tcp = false;
    emit_s1_hdr_udp = false;
    emit_s1_hdr_overlay = false;
}

// Control s1_computeChecksum
inline s1_computeChecksum()
{
    skip;
}

// Control s1_egress
inline s1_egress()
{
    s1_ethernet_set_mac_0_apply();
}

// Control s1_ingress
inline s1_ingress()
{
    if
    :: s1_hdr.nc_hdr.valid -> 
        s1_get_my_address_0_apply();
        if
        :: (s1_hdr.ipv4.dstAddr == s1_meta.my_md.ipaddress) -> 
            s1_find_index_0_apply();
            s1_get_sequence_0_apply();
            if
            :: (s1_hdr.nc_hdr.op == 10) -> 
                s1_read_value_0_apply();
            :: (s1_hdr.nc_hdr.op == 12) -> 
                if
                :: (s1_meta.my_md.role == 100) -> 
                    s1_maintain_sequence_0_apply();
                :: else -> skip;
                fi
                if
                :: ((s1_meta.my_md.role == 100)) || ((s1_hdr.nc_hdr.seq > s1_meta.sequence_md.seq)) -> 
                    s1_assign_value_0_apply();
                    s1_pop_chain_0_apply();
                :: else -> 
                    s1_drop_packet_0_apply();
                fi
            :: else -> skip;
            fi
            if
            :: (s1_meta.my_md.role == 102) -> 
                s1_pop_chain_again_0_apply();
                s1_gen_reply_0_apply();
            :: else -> 
                s1_get_next_hop_0_apply();
            fi
        :: else -> skip;
        fi
    :: else -> skip;
    fi
    if
    :: s1_hdr.nc_hdr.valid -> 
        s1_failure_recovery_0_apply();
    :: else -> skip;
    fi
    if
    :: (s1_hdr.tcp.valid) || (s1_hdr.udp.valid) -> 
        s1_ipv4_route_0_apply();
    :: else -> skip;
    fi
}

// Control s1_verifyChecksum
inline s1_verifyChecksum()
{
    skip;
}

// Parser s1_ParserImpl
inline s1_ParserImpl()
{
    s1_start();
}
inline s1_value_reg_0_read(idx, var) {
    var = s1_value_reg_0[idx];
}
inline pop_front_s1_hdr_overlay()
{
    assign_struct_s1_overlay_t(s1_hdr.overlay.element_0, s1_hdr.overlay.element_1);
    assign_struct_s1_overlay_t(s1_hdr.overlay.element_1, s1_hdr.overlay.element_2);
    assign_struct_s1_overlay_t(s1_hdr.overlay.element_2, s1_hdr.overlay.element_3);
    assign_struct_s1_overlay_t(s1_hdr.overlay.element_3, s1_hdr.overlay.element_4);
    assign_struct_s1_overlay_t(s1_hdr.overlay.element_4, s1_hdr.overlay.element_5);
    assign_struct_s1_overlay_t(s1_hdr.overlay.element_5, s1_hdr.overlay.element_6);
    assign_struct_s1_overlay_t(s1_hdr.overlay.element_6, s1_hdr.overlay.element_7);
    s1_hdr.overlay.element_7.valid = false;
}
inline s1_sequence_reg_0_read(idx, var) {
    var = s1_sequence_reg_0[idx];
}
inline s1_main()
{
    do
    :: s1 ? s1_hdr -> atomic {
        s1_ParserImpl();
        if
        :: s1_packet_extract_accept == true ->
            s1_verifyChecksum();
            s1_ingress();
            s1_egress();
            s1_computeChecksum();
            s1_reset_emit_flag();
            s1_DeparserImpl();
            s1_handle_header_emit();
            if
            :: (s1__forward == true) -> 
                s1_pml_send_packet();
            :: else -> skip;
            fi
        :: else -> skip;
        fi
    }
    od
}
inline s1_mark_to_drop (){
    s1__drop = true;
}
inline s1_value_reg_0_write(idx, a_val){
    s1_value_reg_0[idx] = a_val;
}
inline s1_sequence_reg_0_write(idx, a_val){
    s1_sequence_reg_0[idx] = a_val;
}
inline s1_reject() {
    s1__drop = true;
}

// Action s1_read_value_act
inline s1_read_value_act()
{
    // read
    s1_value_reg_0_read(s1_meta.location.index,s1_hdr.nc_hdr.value);
}

// Action s1_pop_chain_act_2
inline s1_pop_chain_act_2()
{
    s1_hdr.nc_hdr.sc = (s1_hdr.nc_hdr.sc + 255);
    pop_front_s1_hdr_overlay();
    s1_hdr.overlay.last = s1_hdr.overlay.last - 1;
    s1_hdr.udp._len = (s1_hdr.udp._len + 65532);
    s1_hdr.ipv4.totalLen = (s1_hdr.ipv4.totalLen + 65532);
}

// Action s1_pop_chain_act
inline s1_pop_chain_act()
{
    s1_hdr.nc_hdr.sc = (s1_hdr.nc_hdr.sc + 255);
    pop_front_s1_hdr_overlay();
    s1_hdr.overlay.last = s1_hdr.overlay.last - 1;
    s1_hdr.udp._len = (s1_hdr.udp._len + 65532);
    s1_hdr.ipv4.totalLen = (s1_hdr.ipv4.totalLen + 65532);
}

// Action s1_nop
inline s1_nop()
{
    skip;
}

// Action s1_maintain_sequence_act
inline s1_maintain_sequence_act()
{
    s1_meta.sequence_md.seq = (s1_meta.sequence_md.seq + 1);
    // write
    s1_sequence_reg_0_write(s1_meta.location.index, s1_meta.sequence_md.seq);
    // read
    s1_sequence_reg_0_read(s1_meta.location.index,s1_hdr.nc_hdr.seq);
}
proctype s1_mainProcedure()
{
    s1_main();
}

// Action s1_get_sequence_act
inline s1_get_sequence_act()
{
    // read
    s1_sequence_reg_0_read(s1_meta.location.index,s1_meta.sequence_md.seq);
}

// Action s1_failure_recovery_act
inline s1_failure_recovery_act(s1_nexthop)
{
    s1_hdr.overlay.element_0.swip = s1_nexthop;
    s1_hdr.ipv4.dstAddr = s1_nexthop;
}

// Action s1_failover_write_reply_act
inline s1_failover_write_reply_act()
{
    s1_meta.reply_to_client_md.ipv4_srcAddr = s1_hdr.ipv4.dstAddr;
    s1_meta.reply_to_client_md.ipv4_dstAddr = s1_hdr.ipv4.srcAddr;
    s1_hdr.ipv4.srcAddr = s1_meta.reply_to_client_md.ipv4_srcAddr;
    s1_hdr.ipv4.dstAddr = s1_meta.reply_to_client_md.ipv4_dstAddr;
    s1_hdr.nc_hdr.op = 13;
    s1_hdr.udp.dstPort = 8889;
}

// Action s1_failover_act
inline s1_failover_act()
{
    s1_hdr.ipv4.dstAddr = s1_hdr.overlay.element_1.swip;
    s1_hdr.nc_hdr.sc = (s1_hdr.nc_hdr.sc + 255);
    pop_front_s1_hdr_overlay();
    s1_hdr.overlay.last = s1_hdr.overlay.last - 1;
    s1_hdr.udp._len = (s1_hdr.udp._len + 65532);
    s1_hdr.ipv4.totalLen = (s1_hdr.ipv4.totalLen + 65532);
}

// Action s1_drop_packet_act_2
inline s1_drop_packet_act_2()
{
    s1_mark_to_drop();
}

// Action s1_drop_packet_act
inline s1_drop_packet_act()
{
    s1_mark_to_drop();
}

// Action s1_assign_value_act
inline s1_assign_value_act()
{
    // write
    s1_sequence_reg_0_write(s1_meta.location.index, s1_hdr.nc_hdr.seq);
    // write
    s1_value_reg_0_write(s1_meta.location.index, s1_hdr.nc_hdr.value);
}

// Action s1_NoAction_27
inline s1_NoAction_27()
{
    skip;
}

// Action s1_NoAction_25
inline s1_NoAction_25()
{
    skip;
}

// Action s1_NoAction_24
inline s1_NoAction_24()
{
    skip;
}

// Action s1_NoAction_22
inline s1_NoAction_22()
{
    skip;
}

// Action s1_NoAction_21
inline s1_NoAction_21()
{
    skip;
}

// Action s1_NoAction_20
inline s1_NoAction_20()
{
    skip;
}

// Action s1_NoAction_17
inline s1_NoAction_17()
{
    skip;
}

// Action s1_NoAction_16
inline s1_NoAction_16()
{
    skip;
}

// Action s1_NoAction_1
inline s1_NoAction_1()
{
    skip;
}
inline push_front_s1_hdr_overlay()
{
    assign_struct_s1_overlay_t(s1_hdr.overlay.element_7, s1_hdr.overlay.element_6);
    assign_struct_s1_overlay_t(s1_hdr.overlay.element_6, s1_hdr.overlay.element_5);
    assign_struct_s1_overlay_t(s1_hdr.overlay.element_5, s1_hdr.overlay.element_4);
    assign_struct_s1_overlay_t(s1_hdr.overlay.element_4, s1_hdr.overlay.element_3);
    assign_struct_s1_overlay_t(s1_hdr.overlay.element_3, s1_hdr.overlay.element_2);
    assign_struct_s1_overlay_t(s1_hdr.overlay.element_2, s1_hdr.overlay.element_1);
    assign_struct_s1_overlay_t(s1_hdr.overlay.element_1, s1_hdr.overlay.element_0);
    s1_hdr.overlay.element_0.valid = false;
}
