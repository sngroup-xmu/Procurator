
#include "s1_type.pml"
#include "s2_type.pml"
#include "s3_type.pml"
#include "s4_type.pml"
#include "chan.pml"
#include "s1.pml"
#include "s2.pml"
#include "s3.pml"
#include "s4.pml"


s1_headers host1_hdr_send;
s1_headers host1_hdr_recv;
proctype host1() {
  do
  :: atomic {
    host1_hdr_send.ipv4.srcAddr = 167772417; // h1
    host1_hdr_send.ipv4.dstAddr = 167772674; // h2
    host1_hdr_send.ethernet.etherType = 2048;

label_send_1:
    s1 ! host1_hdr_send;
  }
  :: atomic {
    host1_hdr_send.ipv4.srcAddr = 167772417; // h1
    host1_hdr_send.ipv4.dstAddr = 167772931; // h3
    host1_hdr_send.ethernet.etherType = 2048;
    s1 ! host1_hdr_send;
  }

  :: h1 ? host1_hdr_recv -> atomic {
    printf("got a packet");
  }
  od
}

s1_headers host2_hdr_send;
s1_headers host2_hdr_recv;

#define p (host2_hdr_recv.ipv4.srcAddr == 167772417)

proctype host2() {
  do
  :: h2 ? host2_hdr_recv -> atomic {
    skip;
label_recv:
    printf("got a packet, %d, %d\n", host2_hdr_recv.ipv4.srcAddr, host2_hdr_recv.ipv4.dstAddr);
  }
  od
}



s1_headers host3_hdr_send;
s1_headers host3_hdr_recv;
proctype host3() {
  do
  :: atomic {
    host3_hdr_send.ipv4.srcAddr = 167772931; // h3
    host3_hdr_send.ipv4.dstAddr = 167772674; // h2
    host3_hdr_send.ethernet.etherType = 2048;
    s2 ! host3_hdr_send;
  }
  :: h3 ? host3_hdr_recv -> atomic {
    printf("got a packet");
  }
  od
}



init {
  atomic {
    run host1();
    run host2();
    run host3();

    run s1_mainProcedure();
    run s2_mainProcedure();
    run s3_mainProcedure();
    run s4_mainProcedure();
  }
}



//ltl reachability { [](!p)} // the property is negated. so the failure of verification means the original property holds!


//#define fair_2 ((<>s1_mainProcedure@s1_recv_label_1) <-> (<>s1_mainProcedure@s1_recv_label_2))  
//ltl reachability { []fair_2 } // fairness can satisfy
//ltl reachability { <>p} // wrong
//ltl reachability { <>p && []fair_2 } // wrong, user-defined fairness seems can not affect the search

//ltl reachability { []( (host1_hdr_send.ipv4.dstAddr == 167772674) -> (<>p) )} // still wrong ... due to weak fairness ("s1 ! host1_hdr_send;" not continuously executable)


