

// Headers for Paxos
#define PAXOS_1A 0 
#define PAXOS_1B 1 
#define PAXOS_2A 2
#define PAXOS_2B 3

#define ETHERTYPE_IPV4 2048
#define UDP_PROTOCOL 17
#define PAXOS_PROTOCOL 34952

proctype host1() {
    headers host1_hdr;

    host1_hdr.ethernet.etherType = ETHERTYPE_IPV4;
    host1_hdr.ipv4.protocol = UDP_PROTOCOL;
    host1_hdr.udp.dstPort = PAXOS_PROTOCOL;
    host1_hdr.paxos.msgtype = PAXOS_2A;

    do
    :: atomic {
        host1_hdr.paxos.paxosval = 1;

        printf("send write key=%d, value=%d\n", );
        acceptor0 ! host1_hdr;
    }
    :: atomic {

    }
    od
}