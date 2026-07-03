#define SWITCH_ID byte
#define HEAD_NODE 100
#define REPLICA_NODE 101
#define TAIL_NODE 102

#define NC_READ_REQUEST 10
#define NC_READ_REPLY 11
#define NC_WRITE_REQUEST 12
#define NC_WRITE_REPLY 13


#include "s1_type.pml"
#include "s2_type.pml"
#include "s3_type.pml"
#include "chan.pml"
#include "s1.pml"
#include "s2.pml"
#include "s3.pml"

int keys[200];
inline init_tets_data() {
  byte i;
  for (i : 0..120) {
    keys[i] = i + 2024;
  }
}


proctype write_client() {
  s1_headers write_client_hdr;

  do
  :: atomic {
    byte i = 0;
    write_client_hdr.nc_hdr.key = keys[i];
    write_client_hdr.nc_hdr.value = keys[i];
    write_client_hdr.nc_hdr.op = NC_WRITE_REQUEST;

    write_client_hdr.ipv4.srcAddr = 1;
    write_client_hdr.ipv4.dstAddr = 167797761; // s1
    write_client_hdr.ethernet.etherType = 2048;

    write_client_hdr.overlay.element_0.swip = 167797761; // s1
    write_client_hdr.overlay.element_1.swip = 167797762; // s2
    write_client_hdr.overlay.element_2.swip = 167797763; // s3
    write_client_hdr.overlay.element_3.swip = 0; // host

    printf("send write key=%d, value=%d\n", write_client_hdr.nc_hdr.key, write_client_hdr.nc_hdr.value);
    s1 ! write_client_hdr;
  }
  :: atomic {
    byte i = 1;
    write_client_hdr.nc_hdr.key = keys[i];
    write_client_hdr.nc_hdr.value = keys[i];
    write_client_hdr.nc_hdr.op = NC_WRITE_REQUEST;
    
    write_client_hdr.ipv4.srcAddr = 1;
    write_client_hdr.ipv4.dstAddr = 167797761;
    write_client_hdr.ethernet.etherType = 2048;

    write_client_hdr.overlay.element_0.swip = 167797761; // s1
    write_client_hdr.overlay.element_1.swip = 167797762; // s2
    write_client_hdr.overlay.element_2.swip = 167797763; // s3
    write_client_hdr.overlay.element_3.swip = 0; // host

    printf("send write key=%d, value=%d\n", write_client_hdr.nc_hdr.key, write_client_hdr.nc_hdr.value);
    s1 ! write_client_hdr;
  }
  :: atomic {
    byte i = 3;
    write_client_hdr.nc_hdr.key = keys[i];
    write_client_hdr.nc_hdr.value = keys[i];
    write_client_hdr.nc_hdr.op = NC_WRITE_REQUEST;

    write_client_hdr.ipv4.srcAddr = 1;
    write_client_hdr.ipv4.dstAddr = 167797761;
    write_client_hdr.ethernet.etherType = 2048;

    write_client_hdr.overlay.element_0.swip = 167797761; // s1
    write_client_hdr.overlay.element_1.swip = 167797762; // s2
    write_client_hdr.overlay.element_2.swip = 167797763; // s3
    write_client_hdr.overlay.element_3.swip = 0; // host

    printf("send write key=%d, value=%d\n", write_client_hdr.nc_hdr.key, write_client_hdr.nc_hdr.value);
    s1 ! write_client_hdr;
  }
  :: atomic {
    byte i = 4;
    write_client_hdr.nc_hdr.key = keys[i];
    write_client_hdr.nc_hdr.value = keys[i];
    write_client_hdr.nc_hdr.op = NC_WRITE_REQUEST;

    write_client_hdr.ipv4.srcAddr = 1;
    write_client_hdr.ipv4.dstAddr = 167797761;
    write_client_hdr.ethernet.etherType = 2048;

    write_client_hdr.overlay.element_0.swip = 167797761; // s1
    write_client_hdr.overlay.element_1.swip = 167797762; // s2
    write_client_hdr.overlay.element_2.swip = 167797763; // s3
    write_client_hdr.overlay.element_3.swip = 0; // host


    printf("send write key=%d, value=%d\n", write_client_hdr.nc_hdr.key, write_client_hdr.nc_hdr.value);
    s1 ! write_client_hdr;
  }
  :: printf("write_client nothing 1\n");
  :: printf("write_client nothing 2\n");
  od
}


init {
  atomic {
    init_tets_data();
    run write_client();
    run s1_mainProcedure();
    run s2_mainProcedure();
    run s3_mainProcedure();
  }
}

ltl consistency {[](s1_sequence_reg_0[0] >= s2_sequence_reg_0[0] && s2_sequence_reg_0[0] >= s3_sequence_reg_0[0])} // out of bound