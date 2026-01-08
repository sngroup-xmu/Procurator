s1_standard_metadata_t s1_standard_metadata;
s1_headers s1_hdr;

// Table s1_ipv4_lpm_0 Actionlist Declaration
s1_macAddr_t s1_ipv4_lpm_0_s1_ipv4_forward_s1_dstAddr;
s1_egressSpec_t s1_ipv4_lpm_0_s1_ipv4_forward_s1_port;
#define s1_ipv4_lpm_0_action_s1_ipv4_forward 2
#define s1_ipv4_lpm_0_action_s1_drop 1
#define s1_ipv4_lpm_0_action_s1_NoAction_0 0
int s1_ipv4_lpm_0_action_run;
bool s1_ipv4_lpm_0_hit;
inline s1_mark_to_drop (){
    s1__drop = true;
}
inline s1_accept()
{
    s1_packet_extract_accept = true;
}

// Action s1_drop
inline s1_drop()
{
    s1_mark_to_drop();
}

// Action s1_ipv4_forward
inline s1_ipv4_forward(s1_dstAddr, s1_port)
{
    s1_standard_metadata.egress_spec = s1_port;
    s1_standard_metadata.egress_port = s1_port;
    s1__forward = true;
    s1_hdr.ethernet.srcAddr = s1_hdr.ethernet.dstAddr;
    s1_hdr.ethernet.dstAddr = s1_dstAddr;
    s1_hdr.ipv4.ttl = (s1_hdr.ipv4.ttl + 255);
}

//Parser State s1_parse_ipv4
inline s1_parse_ipv4()
{
    s1_hdr.ipv4.valid = true;
    s1_accept();
}

// Table s1_ipv4_lpm_0
inline s1_ipv4_lpm_0_apply()
{
    s1_hdr.ipv4.dstAddr = s1_hdr.ipv4.dstAddr;
    if
    :: (s1_hdr.ipv4.dstAddr == 167772417) ->
        s1_ipv4_forward(8796093022481, 1);
    :: (s1_hdr.ipv4.dstAddr == 167772674) ->
        s1_ipv4_forward(8796093022754, 2);
    :: (s1_hdr.ipv4.dstAddr == 167772931) ->
        s1_ipv4_forward(8796093022976, 3);
    :: (s1_hdr.ipv4.dstAddr == 167773188) ->
        s1_ipv4_forward(8796093023232, 4);
    :: else -> 
        s1_drop();
    fi
}

//Parser State s1_start
inline s1_start()
{
    s1_hdr.ethernet.valid = true;
    if
    :: s1_hdr.ethernet.etherType == 2048 -> 
        s1_parse_ipv4();
    :: else ->
        s1_accept();
    fi
}
inline s1_pml_send_packet() {
    if
    :: s1_standard_metadata.egress_port == 1 ->
        s1_1 ! s1_hdr;
    :: s1_standard_metadata.egress_port == 2 ->
        s1_2 ! s1_hdr;
    :: s1_standard_metadata.egress_port == 3 ->
        s1_3 ! s1_hdr; 
    :: s1_standard_metadata.egress_port == 4 ->
        s1_4 ! s1_hdr;
    :: else -> skip;
    fi
}

// Control s1_MyComputeChecksum
inline s1_MyComputeChecksum()
{
    skip;
}

// Control s1_MyEgress
inline s1_MyEgress()
{
    skip;
}

// Control s1_MyIngress
inline s1_MyIngress()
{
    if
    :: s1_hdr.ipv4.valid -> 
        s1_ipv4_lpm_0_apply();
    :: else -> skip;
    fi
}

// Control s1_MyVerifyChecksum
inline s1_MyVerifyChecksum()
{
    skip;
}

// Parser s1_MyParser
inline s1_MyParser()
{
    s1_start();
}
inline s1_main()
{
    do
    :: h1 ? s1_hdr -> s1_recv_label_1: atomic {
        s1_MyParser();
        if
        :: s1_packet_extract_accept == true ->
            s1_MyVerifyChecksum();
            s1_MyIngress();
            s1_MyEgress();
            s1_MyComputeChecksum();
            if
            :: (s1__forward == true) -> 
                s1_pml_send_packet();
            :: else -> skip;
            fi
        :: else -> skip;
        fi
    }
    :: s4_2 ? s1_hdr -> s1_recv_label_2: atomic {
        s1_MyParser();
        if
        :: s1_packet_extract_accept == true ->
            s1_MyVerifyChecksum();
            s1_MyIngress();
            s1_MyEgress();
            s1_MyComputeChecksum();
            if
            :: (s1__forward == true) -> 
                s1_pml_send_packet();
            :: else -> skip;
            fi
        :: else -> skip;
        fi
    }
    // :: h2 ? s1_hdr
    od
}
inline s1_reject() {
    s1__drop = true;
}
proctype s1_mainProcedure()
{
    s1_main();
}

// Action s1_NoAction_0
inline s1_NoAction_0()
{
    skip;
}
