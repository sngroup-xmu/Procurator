



// Struct s2_location_t
typedef s2_location_t {
    short index;
};

// Struct s2_my_md_t
typedef s2_my_md_t {
    int ipaddress;
    short role;
    short failed;
};

// Struct s2_reply_addr_t
typedef s2_reply_addr_t {
    int ipv4_srcAddr;
    int ipv4_dstAddr;
};

// Struct s2_sequence_md_t
typedef s2_sequence_md_t {
    short seq;
    short tmp;
};

// Struct s2_metadata
typedef s2_metadata {
    s2_location_t location;
    s2_my_md_t my_md;
    s2_reply_addr_t reply_to_client_md;
    s2_sequence_md_t sequence_md;
};
//s2_metadata s2_meta;


// Header s2_nc_hdr_t
typedef s2_nc_hdr_t {
    bool valid = false;
    byte op;
    byte sc;
    short seq;
    int key;
    int value;
    short vgroup;
};
typedef s2_headers {
    s2_nc_hdr_t nc_hdr;
};
//s2_headers s2_hdr;


//int s2_sequence_reg[200];
//int s2_value_reg[200];

