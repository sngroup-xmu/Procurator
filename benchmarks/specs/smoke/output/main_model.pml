// Auto-generated Spin model

#define MAX_BUF_SIZE 5

#include "global_type.pml"

chan s1 = [MAX_BUF_SIZE] of { header };
chan s2 = [MAX_BUF_SIZE] of { header };
chan s3 = [MAX_BUF_SIZE] of { header };

chan h1 = [MAX_BUF_SIZE] of { header };  // h1 <-> s1 
chan h2 = [MAX_BUF_SIZE] of { header };  // h2 <-> s2 
chan h3 = [MAX_BUF_SIZE] of { header };  // h3 <-> s3 

// Include node processes
#include "/mnt/d/work/P4-verification/code/run_9/s1/s1.pml"
#include "/mnt/d/work/P4-verification/code/run_9/s2/s2.pml"
#include "/mnt/d/work/P4-verification/code/run_9/s3/s3.pml"

// Global variable for reachability check
bool s2_received_from_s1 = false;

// Global properties
bool NetworkResilient = (n_BufferUsage < 80);
bool NetworkResponsive = (n_PacketCounter > 0);
assert(NetworkResilient);
ltl: (false || (true && [](NetworkResilient)));

headers h1_hdr_send;
headers h1_hdr_recv;
int h1_srcAddr = 167772417;
proctype h1() {
  do
  :: atomic {
      h1_hdr_send.ipv4.srcAddr = h1_srcAddr;
      // TODO: Set other packet fields and send packet
      s1 ! h1_hdr_send;
  }
  :: h1 ? h1_hdr_recv -> atomic {
      // Handle received packet
      printf("Host received a packet\n");
    }
  od
}

headers h2_hdr_send;
headers h2_hdr_recv;
int h2_srcAddr = 167772674;
proctype h2() {
  do
  :: atomic {
      h2_hdr_send.ipv4.srcAddr = h2_srcAddr;
      // TODO: Set other packet fields and send packet
      s2 ! h2_hdr_send;
  }
  :: h2 ? h2_hdr_recv -> atomic {
      // Handle received packet
      printf("Host received a packet\n");
    }
  od
}

headers h3_hdr_send;
headers h3_hdr_recv;
int h3_srcAddr = 167772931;
proctype h3() {
  do
  :: atomic {
      h3_hdr_send.ipv4.srcAddr = h3_srcAddr;
      // TODO: Set other packet fields and send packet
      s3 ! h3_hdr_send;
  }
  :: h3 ? h3_hdr_recv -> atomic {
      // Handle received packet
      printf("Host received a packet\n");
      if (h3_hdr_recv.ipv4.srcAddr == h1_srcAddr) {
          s2_received_from_s1 = true;
      }
    }
  od
}

// LTL property for reachability
ltl unreached_s1_to_s2 { [] (s2_received_from_s1 == false) }
// The property asserts that s2 never receives packets from s1.
// If Spin finds a counterexample, it means s2 can receive packets from s1, i.e., reachability exists.

init {
  atomic {
    run h1();
    run h2();
    run h3();

    run s1_mainProcedure();
    run s2_mainProcedure();
    run s3_mainProcedure();
  }
}
