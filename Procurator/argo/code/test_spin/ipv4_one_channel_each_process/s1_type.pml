#define s1_error bit
bool s1__forward;
bool s1__drop;
bool s1_packet_extract_accept = false;

// Struct s1_standard_metadata_t
typedef s1_standard_metadata_t {
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
    s1_error parser_error;
    byte _priority;
};
#define s1_egressSpec_t short
#define s1_macAddr_t int
#define s1_ip4Addr_t int

// Struct s1_metadata

// Struct s1_headers

// Header s1_ethernet_t
typedef s1_ethernet_t {
    bool valid = false;
    s1_macAddr_t dstAddr;
    s1_macAddr_t srcAddr;
    short etherType;
};

// Header s1_ipv4_t
typedef s1_ipv4_t {
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
    s1_ip4Addr_t srcAddr;
    s1_ip4Addr_t dstAddr;
};

typedef s1_headers {
    s1_ethernet_t ethernet;
    s1_ipv4_t ipv4;
};
