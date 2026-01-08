#define s2_error bit
bool s2__forward;
bool s2__drop;
bool s2_packet_extract_accept = false;

// Struct s2_standard_metadata_t
typedef s2_standard_metadata_t {
    short ingress_port;
    short egress_spec;
    short egress_port;
    int instance_type;
    int packet_length;
    int enq_timestamp;
    int enq_qdepth;
    int deq_timedelta;
    int deq_qdepth;
    int ingress_global_timestamp;
    int egress_global_timestamp;
    short mcast_grp;
    short egress_rid;
    bit checksum_error;
    s2_error parser_error;
    byte _priority;
};
#define s2_egressSpec_t short
#define s2_macAddr_t int
#define s2_ip4Addr_t int

// Struct s2_metadata

// Struct s2_headers

// Header s2_ethernet_t
typedef s2_ethernet_t {
    bool valid = false;
    s2_macAddr_t dstAddr;
    s2_macAddr_t srcAddr;
    short etherType;
};

// Header s2_ipv4_t
typedef s2_ipv4_t {
    bool valid = false;
    byte version;
    byte ihl;
    byte diffserv;
    short totalLen;
    short identification;
    byte flags;
    short fragOffset;
    byte ttl;
    byte protocol;
    short hdrChecksum;
    s2_ip4Addr_t srcAddr;
    s2_ip4Addr_t dstAddr;
};

typedef s2_headers {
    s2_ethernet_t ethernet;
    s2_ipv4_t ipv4;
};
