#define s4_error bit
bool s4__forward;
bool s4__drop;
bool s4_packet_extract_accept = false;

// Struct s4_standard_metadata_t
typedef s4_standard_metadata_t {
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
    s4_error parser_error;
    byte _priority;
};
#define s4_egressSpec_t short
#define s4_macAddr_t int
#define s4_ip4Addr_t int

// Struct s4_metadata

// Struct s4_headers

// Header s4_ethernet_t
typedef s4_ethernet_t {
    bool valid = false;
    s4_macAddr_t dstAddr;
    s4_macAddr_t srcAddr;
    short etherType;
};

// Header s4_ipv4_t
typedef s4_ipv4_t {
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
    s4_ip4Addr_t srcAddr;
    s4_ip4Addr_t dstAddr;
};

typedef s4_headers {
    s4_ethernet_t ethernet;
    s4_ipv4_t ipv4;
};
