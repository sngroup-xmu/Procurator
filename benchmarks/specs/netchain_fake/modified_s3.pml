//#include "chan.pml"


s3_metadata s3_meta;
s3_headers s3_hdr;


//int s3_sequence_reg[200];
//int s3_value_reg[200];
int s3_sequence_reg[20];
int s3_value_reg[20];


// s3
inline s3_get_my_address_act(sw_ip, sw_role) {
  s3_meta.my_md.ipaddress = sw_ip;
  s3_meta.my_md.role = sw_role;
}

inline s3_find_index() {
  s3_meta.location.index = s3_hdr.nc_hdr.key % 2024;
  printf("s3 key=%d, index=%d\n", s3_hdr.nc_hdr.key, s3_meta.location.index);
}

inline s3_get_sequence_act() {
  s3_meta.sequence_md.seq = s3_sequence_reg[s3_meta.location.index];
}

inline s3_maintain_sequence() {
  s3_meta.sequence_md.seq = s3_meta.sequence_md.seq + 1;
  s3_sequence_reg[s3_meta.location.index] = s3_meta.sequence_md.seq; 
  s3_hdr.nc_hdr.seq = s3_sequence_reg[s3_meta.location.index];
}

inline s3_assign_value() {
  s3_sequence_reg[s3_meta.location.index] = s3_hdr.nc_hdr.seq;
  s3_value_reg[s3_meta.location.index] = s3_hdr.nc_hdr.value;
}


proctype s3() {
  byte sw_ip = 3, sw_role = TAIL_NODE;

  do
  :: s2_s3 ? s3_hdr -> atomic {
    s3_get_my_address_act(sw_ip, sw_role);
    s3_find_index();
    s3_get_sequence_act();
    // write
    if
    :: s3_hdr.nc_hdr.op == NC_READ_REQUEST ->
      skip;
    :: s3_hdr.nc_hdr.op == NC_WRITE_REQUEST ->
      printf("s3 NC_WRITE_REQUEST\n");
      if  
      :: s3_meta.my_md.role == HEAD_NODE -> 
        printf("s3 HEAD_NODE\n");
        s3_maintain_sequence();
      :: else -> skip;
      fi
      if
      :: s3_meta.my_md.role == HEAD_NODE || s3_hdr.nc_hdr.seq > s3_meta.sequence_md.seq ->
        printf("s3_assign_value\n");
        s3_assign_value();
      :: else ->
        skip;
      fi
    :: else ->
      skip;
    fi

    if
    :: s3_meta.my_md.role == TAIL_NODE ->
      printf("s3 TAIL_NODE reply\n");
    :: else ->
      printf("s3 forward\n");
    fi
    //assert(s1_sequence_reg[0] >= s2_sequence_reg[0] && s2_sequence_reg[0] >= s3_sequence_reg[0]);
  }
  
    // Message passing logic
    if
      :: egress_port == s3 ->
          -1_in!packet;
      :: else ->
          printf("Unknown egress_port %d in ///mnt/d/work/P4-verification/code/spec/netchain_fake/modified_s3.pml\n", egress_port);
    fi;
od

}