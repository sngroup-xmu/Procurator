s3_standard_metadata_t s3_standard_metadata;
s3_headers s3_hdr;

// Table s3_ipv4_lpm_0 Actionlist Declaration
s3_macAddr_t s3_ipv4_lpm_0_s3_ipv4_forward_s3_dstAddr;
s3_egressSpec_t s3_ipv4_lpm_0_s3_ipv4_forward_s3_port;
#define s3_ipv4_lpm_0_action_s3_ipv4_forward 2
#define s3_ipv4_lpm_0_action_s3_drop 1
#define s3_ipv4_lpm_0_action_s3_NoAction_0 0
int s3_ipv4_lpm_0_action_run;
bool s3_ipv4_lpm_0_hit;
inline s3_mark_to_drop (){
    s3__drop = true;
}
inline s3_accept()
{
    s3_packet_extract_accept = true;
}

// Action s3_drop
inline s3_drop()
{
    s3_mark_to_drop();
}

// Action s3_ipv4_forward
inline s3_ipv4_forward(s3_dstAddr, s3_port)
{
    s3_standard_metadata.egress_spec = s3_port;
    s3_standard_metadata.egress_port = s3_port;
    s3__forward = true;
    s3_hdr.ethernet.srcAddr = s3_hdr.ethernet.dstAddr;
    s3_hdr.ethernet.dstAddr = s3_dstAddr;
    s3_hdr.ipv4.ttl = (s3_hdr.ipv4.ttl + 255);
}

//Parser State s3_parse_ipv4
inline s3_parse_ipv4()
{
    s3_hdr.ipv4.valid = true;
    s3_accept();
}

// Table s3_ipv4_lpm_0
inline s3_ipv4_lpm_0_apply()
{
    s3_hdr.ipv4.dstAddr = s3_hdr.ipv4.dstAddr;
    if
    :: (s3_hdr.ipv4.dstAddr == 167772417) ->
        s3_ipv4_forward(8796093022464, 1);
    :: (s3_hdr.ipv4.dstAddr == 167772674) ->
        s3_ipv4_forward(8796093022464, 1);
    :: (s3_hdr.ipv4.dstAddr == 167772931) ->
        s3_ipv4_forward(8796093022720, 2);
    :: (s3_hdr.ipv4.dstAddr == 167773188) ->
        s3_ipv4_forward(8796093022720, 2);
    :: else -> 
        s3_drop();
    fi
}

//Parser State s3_start
inline s3_start()
{
    s3_hdr.ethernet.valid = true;
    if
    :: s3_hdr.ethernet.etherType == 2048 -> 
        s3_parse_ipv4();
    :: else ->
        s3_accept();
    fi
}
inline s3_pml_send_packet() {
skip;
}

// Control s3_MyComputeChecksum
inline s3_MyComputeChecksum()
{
    skip;
}

// Control s3_MyEgress
inline s3_MyEgress()
{
    skip;
}

// Control s3_MyIngress
inline s3_MyIngress()
{
    if
    :: s3_hdr.ipv4.valid -> 
        s3_ipv4_lpm_0_apply();
    :: else -> skip;
    fi
}

// Control s3_MyVerifyChecksum
inline s3_MyVerifyChecksum()
{
    skip;
}

// Parser s3_MyParser
inline s3_MyParser()
{
    s3_start();
}
inline s3_main()
{
    
    do
    :: s3 ? s3_hdr -> atomic {
        s3_MyParser();
        if
        :: s3_packet_extract_accept == true ->
            s3_MyVerifyChecksum();
            s3_MyIngress();
            s3_MyEgress();
            s3_MyComputeChecksum();
            if
            :: (s3__forward == true) -> 
                s3_pml_send_packet();
            :: else -> skip;
            fi
        :: else -> skip;
        fi
    }
    od
}
inline s3_reject() {
    s3__drop = true;
}
proctype s3_mainProcedure()
{
    s3_main();
}

// Action s3_NoAction_0
inline s3_NoAction_0()
{
    skip;
}
