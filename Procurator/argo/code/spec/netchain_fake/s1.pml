
//#include "chan.pml"
//#include "s1_type.pml"


s1_metadata s1_meta;
s1_headers s1_hdr;


//int s1_sequence_reg[200];
//int s1_value_reg[200];
int s1_sequence_reg[20];
int s1_value_reg[20];


// s1
inline s1_get_my_address_act(sw_ip, sw_role) {
  s1_meta.my_md.ipaddress = sw_ip;
  s1_meta.my_md.role = sw_role;
}

inline s1_find_index() {
  s1_meta.location.index = s1_hdr.nc_hdr.key % 2024;
  printf("s1 key=%d, index=%d\n", s1_hdr.nc_hdr.key, s1_meta.location.index);
}

inline s1_get_sequence_act() {
  s1_meta.sequence_md.seq = s1_sequence_reg[s1_meta.location.index];
}

inline s1_maintain_sequence() {
  s1_meta.sequence_md.seq = s1_meta.sequence_md.seq + 1;
  s1_sequence_reg[s1_meta.location.index] = s1_meta.sequence_md.seq; 
  s1_hdr.nc_hdr.seq = s1_sequence_reg[s1_meta.location.index];
}

inline s1_assign_value() {
  s1_sequence_reg[s1_meta.location.index] = s1_hdr.nc_hdr.seq;
  s1_value_reg[s1_meta.location.index] = s1_hdr.nc_hdr.value;
}


proctype s1() {
  byte sw_ip = 1, sw_role = HEAD_NODE;

  do
  :: client_s1 ? s1_hdr -> atomic {
    s1_get_my_address_act(sw_ip, sw_role);
    s1_find_index();
    s1_get_sequence_act();
    // write
    if
    :: s1_hdr.nc_hdr.op == NC_READ_REQUEST ->
      skip;
    :: s1_hdr.nc_hdr.op == NC_WRITE_REQUEST ->
      printf("s1 NC_WRITE_REQUEST\n");
      if  
      :: s1_meta.my_md.role == HEAD_NODE -> 
        printf("s1 HEAD_NODE\n");
        s1_maintain_sequence();
      :: else -> skip;
      fi
      if
      :: s1_meta.my_md.role == HEAD_NODE || s1_hdr.nc_hdr.seq > s1_meta.sequence_md.seq ->
        printf("s1_assign_value\n");
        s1_assign_value();
      :: else ->
        skip;
      fi
    :: else ->
      skip;
    fi

    if
    :: s1_meta.my_md.role == TAIL_NODE ->
      printf("s1 TAIL_NODE reply\n");
    :: else ->
      printf("s1 forward\n");
      s1_s2 ! s1_hdr;
    fi

  }
  od

}
