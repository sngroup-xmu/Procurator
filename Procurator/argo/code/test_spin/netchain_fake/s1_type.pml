
// Struct s1_location_t
typedef s1_location_t {
    short index;
};

// Struct s1_my_md_t
typedef s1_my_md_t {
    int ipaddress;
    short role;
    short failed;
};

// Struct s1_reply_addr_t
typedef s1_reply_addr_t {
    int ipv4_srcAddr;
    int ipv4_dstAddr;
};

// Struct s1_sequence_md_t
typedef s1_sequence_md_t {
    short seq;
    short tmp;
};

// Struct s1_metadata
typedef s1_metadata {
    s1_location_t location;
    s1_my_md_t my_md;
    s1_reply_addr_t reply_to_client_md;
    s1_sequence_md_t sequence_md;
};
//s1_metadata s1_meta;


// Header s1_nc_hdr_t
typedef s1_nc_hdr_t {
    bool valid = false;
    byte op;
    byte sc;
    short seq;
    int key;
    int value;
    short vgroup;
};
typedef s1_headers {
    s1_nc_hdr_t nc_hdr;
};
//s1_headers s1_hdr;


//int s1_sequence_reg[200];
//int s1_value_reg[200];

