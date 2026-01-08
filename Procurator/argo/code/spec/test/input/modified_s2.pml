//#include "chan.pml"

s2_metadata s2_meta;
s2_headers s2_hdr;


//int s2_sequence_reg[200];
//int s2_value_reg[200];
int s2_sequence_reg[20];
int s2_value_reg[20];


// s2
inline s2_get_my_address_act(sw_ip, sw_role) {
  s2_meta.my_md.ipaddress = sw_ip;
  s2_meta.my_md.role = sw_role;
}

inline s2_find_index() {
  s2_meta.location.index = s2_hdr.nc_hdr.key % 2024;
  printf("s2 key=%d, index=%d\n", s2_hdr.nc_hdr.key, s2_meta.location.index);
}

inline s2_get_sequence_act() {
  s2_meta.sequence_md.seq = s2_sequence_reg[s2_meta.location.index];
}

inline s2_maintain_sequence() {
  s2_meta.sequence_md.seq = s2_meta.sequence_md.seq + 1;
  s2_sequence_reg[s2_meta.location.index] = s2_meta.sequence_md.seq; 
  s2_hdr.nc_hdr.seq = s2_sequence_reg[s2_meta.location.index];
}

inline s2_assign_value() {
  s2_sequence_reg[s2_meta.location.index] = s2_hdr.nc_hdr.seq;
  s2_value_reg[s2_meta.location.index] = s2_hdr.nc_hdr.value;
}

proctype s2() {
  byte sw_ip = 2, sw_role = REPLICA_NODE;

  do
  :: s1_s2 ? s2_hdr -> atomic {
    s2_get_my_address_act(sw_ip, sw_role);
    s2_find_index();
    s2_get_sequence_act();
    // write
    if
    :: s2_hdr.nc_hdr.op == NC_READ_REQUEST ->
      skip;
    :: s2_hdr.nc_hdr.op == NC_WRITE_REQUEST ->
      printf("s2 NC_WRITE_REQUEST\n");
      if  
      :: s2_meta.my_md.role == HEAD_NODE -> 
        printf("s2 HEAD_NODE\n");
        s2_maintain_sequence();
      :: else -> skip;
      fi
      if
      :: s2_meta.my_md.role == HEAD_NODE || s2_hdr.nc_hdr.seq > s2_meta.sequence_md.seq ->
        printf("s2_assign_value\n");
        s2_assign_value();
      :: else ->
        skip;
      fi
    :: else ->
      skip;
    fi

    if
    :: s2_meta.my_md.role == TAIL_NODE ->
      printf("s2 TAIL_NODE reply\n");
    :: else ->
      printf("s2 forward\n");
      s2_s3 ! s2_hdr;
    fi

  }
  
    // Message passing logic
          s3_in!packet;
od

}