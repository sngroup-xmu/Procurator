s4_standard_metadata_t s4_standard_metadata;
s4_headers s4_hdr;

// Table s4_ipv4_lpm_0 Actionlist Declaration
s4_macAddr_t s4_ipv4_lpm_0_s4_ipv4_forward_s4_dstAddr;
s4_egressSpec_t s4_ipv4_lpm_0_s4_ipv4_forward_s4_port;
#define s4_ipv4_lpm_0_action_s4_ipv4_forward 2
#define s4_ipv4_lpm_0_action_s4_drop 1
#define s4_ipv4_lpm_0_action_s4_NoAction_0 0
int s4_ipv4_lpm_0_action_run;
bool s4_ipv4_lpm_0_hit;
inline s4_mark_to_drop (){
    s4__drop = true;
}
inline s4_accept()
{
    s4_packet_extract_accept = true;
}

// Action s4_drop
inline s4_drop()
{
    s4_mark_to_drop();
}

// Action s4_ipv4_forward
inline s4_ipv4_forward(s4_dstAddr, s4_port)
{
    s4_standard_metadata.egress_spec = s4_port;
    s4_standard_metadata.egress_port = s4_port;
    s4__forward = true;
    s4_hdr.ethernet.srcAddr = s4_hdr.ethernet.dstAddr;
    s4_hdr.ethernet.dstAddr = s4_dstAddr;
    s4_hdr.ipv4.ttl = (s4_hdr.ipv4.ttl + 255);
}

//Parser State s4_parse_ipv4
inline s4_parse_ipv4()
{
    s4_hdr.ipv4.valid = true;
    s4_accept();
}

// Table s4_ipv4_lpm_0
inline s4_ipv4_lpm_0_apply()
{
    s4_hdr.ipv4.dstAddr = s4_hdr.ipv4.dstAddr;
    if
    :: (s4_hdr.ipv4.dstAddr == 167772417) ->
        s4_ipv4_forward(8796093022464, 2);
    :: (s4_hdr.ipv4.dstAddr == 167772674) ->
        s4_ipv4_forward(8796093022464, 2);
    :: (s4_hdr.ipv4.dstAddr == 167772931) ->
        s4_ipv4_forward(8796093022720, 1);
    :: (s4_hdr.ipv4.dstAddr == 167773188) ->
        s4_ipv4_forward(8796093022720, 1);
    :: else -> 
        s4_drop();
    fi
}

//Parser State s4_start
inline s4_start()
{
    s4_hdr.ethernet.valid = true;
    if
    :: s4_hdr.ethernet.etherType == 2048 -> 
        s4_parse_ipv4();
    :: else ->
        s4_accept();
    fi
}
inline s4_pml_send_packet() {
    if
    :: s4_standard_metadata.egress_port == 1 ->
        s4_1 ! s4_hdr;
    :: s4_standard_metadata.egress_port == 2 ->
        s4_2 ! s4_hdr;
    :: else -> skip;
    fi
}

// Control s4_MyComputeChecksum
inline s4_MyComputeChecksum()
{
    skip;
}

// Control s4_MyEgress
inline s4_MyEgress()
{
    skip;
}

// Control s4_MyIngress
inline s4_MyIngress()
{
    if
    :: s4_hdr.ipv4.valid -> 
        s4_ipv4_lpm_0_apply();
    :: else -> skip;
    fi
}

// Control s4_MyVerifyChecksum
inline s4_MyVerifyChecksum()
{
    skip;
}

// Parser s4_MyParser
inline s4_MyParser()
{
    s4_start();
}
inline s4_main()
{
    
    do
    :: s1_4 ? s4_hdr -> atomic {
        s4_MyParser();
        if
        :: s4_packet_extract_accept == true ->
            s4_MyVerifyChecksum();
            s4_MyIngress();
            s4_MyEgress();
            s4_MyComputeChecksum();
            if
            :: (s4__forward == true) -> 
                s4_pml_send_packet();
            :: else -> skip;
            fi
        :: else -> skip;
        fi
    }
    :: s2_3 ? s4_hdr -> atomic {
        s4_MyParser();
        if
        :: s4_packet_extract_accept == true ->
            s4_MyVerifyChecksum();
            s4_MyIngress();
            s4_MyEgress();
            s4_MyComputeChecksum();
            if
            :: (s4__forward == true) -> 
                s4_pml_send_packet();
            :: else -> skip;
            fi
        :: else -> skip;
        fi
    }
    od
}
inline s4_reject() {
    s4__drop = true;
}
proctype s4_mainProcedure()
{
    s4_main();
}

// Action s4_NoAction_0
inline s4_NoAction_0()
{
    skip;
}
