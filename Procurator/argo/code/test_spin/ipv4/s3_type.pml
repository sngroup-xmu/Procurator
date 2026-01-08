#define s3_error bit
bool s3__forward;
bool s3__drop;
bool s3_packet_extract_accept = false;

// Struct s3_standard_metadata_t
typedef s3_standard_metadata_t {
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
    s3_error parser_error;
    byte _priority;
};
#define s3_egressSpec_t short
#define s3_macAddr_t int
#define s3_ip4Addr_t int

// Struct s3_metadata

// Struct s3_headers

// Header s3_ethernet_t
typedef s3_ethernet_t {
    bool valid = false;
    s3_macAddr_t dstAddr;
    s3_macAddr_t srcAddr;
    short etherType;
};

// Header s3_ipv4_t
typedef s3_ipv4_t {
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
    s3_ip4Addr_t srcAddr;
    s3_ip4Addr_t dstAddr;
};

typedef s3_headers {
    s3_ethernet_t ethernet;
    s3_ipv4_t ipv4;
};
