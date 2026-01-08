s2_standard_metadata_t s2_standard_metadata;
s2_headers s2_hdr;

// Table s2_ipv4_lpm_0 Actionlist Declaration
s2_macAddr_t s2_ipv4_lpm_0_s2_ipv4_forward_s2_dstAddr;
s2_egressSpec_t s2_ipv4_lpm_0_s2_ipv4_forward_s2_port;
#define s2_ipv4_lpm_0_action_s2_ipv4_forward 2
#define s2_ipv4_lpm_0_action_s2_drop 1
#define s2_ipv4_lpm_0_action_s2_NoAction_0 0
int s2_ipv4_lpm_0_action_run;
bool s2_ipv4_lpm_0_hit;
inline s2_mark_to_drop (){
    s2__drop = true;
}
inline s2_accept()
{
    s2_packet_extract_accept = true;
}

// Action s2_drop
inline s2_drop()
{
    s2_mark_to_drop();
}

// Action s2_ipv4_forward
inline s2_ipv4_forward(s2_dstAddr, s2_port)
{
    s2_standard_metadata.egress_spec = s2_port;
    s2_standard_metadata.egress_port = s2_port;
    s2__forward = true;
    s2_hdr.ethernet.srcAddr = s2_hdr.ethernet.dstAddr;
    s2_hdr.ethernet.dstAddr = s2_dstAddr;
    s2_hdr.ipv4.ttl = (s2_hdr.ipv4.ttl + 255);
}

//Parser State s2_parse_ipv4
inline s2_parse_ipv4()
{
    s2_hdr.ipv4.valid = true;
    s2_accept();
}

// Table s2_ipv4_lpm_0
inline s2_ipv4_lpm_0_apply()
{
    s2_hdr.ipv4.dstAddr = s2_hdr.ipv4.dstAddr;
    if
    :: (s2_hdr.ipv4.dstAddr == 167772417) ->
        s2_ipv4_forward(8796093022976, 4);
    :: (s2_hdr.ipv4.dstAddr == 167772674) ->
        s2_ipv4_forward(8796093023232, 3);
    :: (s2_hdr.ipv4.dstAddr == 167772931) ->
        s2_ipv4_forward(8796093023027, 1);
    :: (s2_hdr.ipv4.dstAddr == 167773188) ->
        s2_ipv4_forward(8796093023300, 2);
    :: else -> 
        s2_drop();
    fi
}

//Parser State s2_start
inline s2_start()
{
    s2_hdr.ethernet.valid = true;
    if
    :: s2_hdr.ethernet.etherType == 2048 -> 
        s2_parse_ipv4();
    :: else ->
        s2_accept();
    fi
}
inline s2_pml_send_packet() {
    if
    :: s2_standard_metadata.egress_port == 1 ->
        h3 ! s2_hdr;
    :: s2_standard_metadata.egress_port == 2 ->
        h4 ! s2_hdr;
    :: s2_standard_metadata.egress_port == 3 ->
        s4 ! s2_hdr; 
    :: s2_standard_metadata.egress_port == 4 ->
        s3 ! s2_hdr;
    :: else -> skip;
    fi
}

// Control s2_MyComputeChecksum
inline s2_MyComputeChecksum()
{
    skip;
}

// Control s2_MyEgress
inline s2_MyEgress()
{
    skip;
}

// Control s2_MyIngress
inline s2_MyIngress()
{
    if
    :: s2_hdr.ipv4.valid -> 
        s2_ipv4_lpm_0_apply();
    :: else -> skip;
    fi
}

// Control s2_MyVerifyChecksum
inline s2_MyVerifyChecksum()
{
    skip;
}

// Parser s2_MyParser
inline s2_MyParser()
{
    s2_start();
}
inline s2_main()
{
    do
    :: s2 ? s2_hdr -> atomic {
        s2_MyParser();
        if
        :: s2_packet_extract_accept == true ->
            s2_MyVerifyChecksum();
            s2_MyIngress();
            s2_MyEgress();
            s2_MyComputeChecksum();
            if
            :: (s2__forward == true) -> 
                s2_pml_send_packet();
            :: else -> skip;
            fi
        :: else -> skip;
        fi
    }
    /*:: h4 ? s2_hdr -> atomic {
        s2_MyParser();
        if
        :: s2_packet_extract_accept == true ->
            s2_MyVerifyChecksum();
            s2_MyIngress();
            s2_MyEgress();
            s2_MyComputeChecksum();
            if
            :: (s2__forward == true) -> 
                s2_pml_send_packet();
            :: else -> skip;
            fi
        :: else -> skip;
        fi
    }*/
    od
}
inline s2_reject() {
    s2__drop = true;
}
proctype s2_mainProcedure()
{
    s2_main();
}

// Action s2_NoAction_0
inline s2_NoAction_0()
{
    skip;
}
