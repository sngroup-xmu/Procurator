



// Struct s3_location_t
typedef s3_location_t {
    short index;
};

// Struct s3_my_md_t
typedef s3_my_md_t {
    int ipaddress;
    short role;
    short failed;
};

// Struct s3_reply_addr_t
typedef s3_reply_addr_t {
    int ipv4_srcAddr;
    int ipv4_dstAddr;
};

// Struct s3_sequence_md_t
typedef s3_sequence_md_t {
    short seq;
    short tmp;
};

// Struct s3_metadata
typedef s3_metadata {
    s3_location_t location;
    s3_my_md_t my_md;
    s3_reply_addr_t reply_to_client_md;
    s3_sequence_md_t sequence_md;
};
//s3_metadata s3_meta;


// Header s3_nc_hdr_t
typedef s3_nc_hdr_t {
    bool valid = false;
    byte op;
    byte sc;
    short seq;
    int key;
    int value;
    short vgroup;
};
typedef s3_headers {
    s3_nc_hdr_t nc_hdr;
};
//s3_headers s3_hdr;


//int s3_sequence_reg[200];
//int s3_value_reg[200];

