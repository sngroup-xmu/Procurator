action _drop() {
    drop();
}

action set_nhop(nhop_ipv4) {
    modify_field(routing_metadata.nhop_ipv4, nhop_ipv4);
    add_to_field(ipv4.ttl, -1);
}

action set_dmac(dmac, port) {
    modify_field(ethernet.dstAddr, dmac);
    modify_field(standard_metadata.egress_spec, port);
}

action set_smac(smac) {
    modify_field(ethernet.srcAddr, smac);
}
