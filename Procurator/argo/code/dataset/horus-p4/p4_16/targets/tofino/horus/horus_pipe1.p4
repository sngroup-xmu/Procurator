#include "../parser.p4"
#include "leaf.p4"

Pipeline(HorusIngressParser(),
         LeafIngress(),
         LeafIngressDeparser(),
         HorusEgressParser(),
         HorusEgress(),
         HorusEgressDeparser()
         ) pipe_leaf;

Switch(pipe_leaf) main;
